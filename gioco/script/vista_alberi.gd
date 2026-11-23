class_name VistaAlberi
extends Node3D
## Disegna gli alberi di Alberi con istanze multiple (MultiMesh per blocco), solo nei blocchi
## inquadrati e con un livello di dettaglio che segue lo zoom. Gli alberi si vedono a ogni zoom
## (decisione di Claude su richiesta di Fede: la volta dipinta da sola stonava con gli alberi).
## - vista più stretta di DIM_COMPLETI: alberi completi (360–530 facce);
## - fino a DIM_LEGGERI: versione leggera (55–80 facce, poche carte grandi);
## - fino a DIM_SAGOME: sagome, un rettangolo per albero con l'immagine del modello
##   (strumenti/genera_sagome.gd), sempre rivolto verso la camera;
## - oltre: sagome rade, una ogni due o tre alberi e più grandi, in blocchi quattro volte più
##   larghi (meno oggetti da disegnare), senza ombre.
## Con alberi completi o leggeri lo shader del terreno dipinge il sottobosco; con le sagome resta
## sotto la volta dipinta, così tra una sagoma e l'altra (e nei blocchi non ancora pronti) si vede
## bosco e non terra.

const DIM_COMPLETI := 220.0
const DIM_LEGGERI := 700.0
const DIM_SAGOME := 2600.0
## Sagome rade: quota di alberi tenuti, ingrandimento, blocchi per lato di un blocco grande.
const RADE_QUOTA := 0.4
const RADE_SCALA := 1.45
const RADE_BLOCCO := 4
## Tempo massimo per fotogramma dedicato a costruire blocchi (microsecondi).
const BUDGET_US := 6000
const NOMI_LIVELLI := ["sagome rade", "sagome", "alberi leggeri", "alberi completi"]
const RADE := 0
const SAGOME := 1
const LEGGERI := 2
const COMPLETI := 3

var alberi: Alberi
var terreno: Terreno
var cam: CameraIsometrica
## 0 sagome rade, 1 sagome, 2 leggeri, 3 completi.
var livello := 0
## Alberi attualmente disegnati (per la lettura delle prestazioni).
var alberi_visibili := 0

var _mesh: Array = [[], [], [], []]  # per livello: una Mesh per modello (le sagome usano _quad)
var _quad: ArrayMesh
var _materiale_sagome: ShaderMaterial
## Blocchi disegnati: Vector3i(bx, bz, lato in blocchi) -> { "livello", "nodi", "n" }.
var _blocchi := {}
## I buffer delle MultiMesh si preparano su altri thread; qui arrivano pronti.
## Chiave: Vector4i(bx, bz, lato in blocchi, livello).
var _mutex := Mutex.new()
var _in_corso := {}
var _pronti := {}
## Compiti in sottofondo al massimo insieme.
const COMPITI_MAX := 6


func prepara(a: Alberi, t: Terreno, c: CameraIsometrica) -> void:
	alberi = a
	terreno = t
	cam = c
	for nome in Alberi.MODELLI:
		_mesh[COMPLETI].append(_carica_mesh("res://asset/alberi/%s.glb" % nome))
		_mesh[LEGGERI].append(_carica_mesh("res://asset/alberi/%s_leggero.glb" % nome))
	# Sagome: un rettangolo da (0, 0) a (1, 1); lo shader lo allarga e lo gira verso la camera.
	var v := PackedVector3Array([Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(1, 1, 0), Vector3(0, 1, 0)])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 0, 2, 3])
	_quad = ArrayMesh.new()
	_quad.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	_materiale_sagome = ShaderMaterial.new()
	_materiale_sagome.shader = load("res://shader/sagome_alberi.gdshader")
	_materiale_sagome.set_shader_parameter("tavola", load("res://asset/alberi/sagome.png"))
	var q := PackedVector4Array()
	var u := PackedVector4Array()
	for i in Alberi.MODELLI.size():
		var a4: Array = SagomeDati.QUAD[i]
		var b4: Array = SagomeDati.UV[i]
		q.append(Vector4(a4[0], a4[1], a4[2], a4[3]))
		u.append(Vector4(b4[0], b4[1], b4[2], b4[3]))
	_materiale_sagome.set_shader_parameter("quad", q)
	_materiale_sagome.set_shader_parameter("uv_tavola", u)
	_quad.surface_set_material(0, _materiale_sagome)


func _carica_mesh(percorso: String) -> Mesh:
	var nodo := Asset.istanzia(percorso)
	if nodo == null:
		push_error("Modello mancante: " + percorso)
		return null
	var mi := nodo.find_children("*", "MeshInstance3D", true, false)
	var mesh: Mesh = (mi[0] as MeshInstance3D).mesh if mi.size() > 0 else null
	nodo.free()
	return mesh


func _process(_delta: float) -> void:
	if alberi == null:
		return
	aggiorna(BUDGET_US)


## Aggiorna i blocchi visibili; costruisce blocchi finché non supera `budget_us` microsecondi
## (almeno uno per chiamata; -1 = tutti subito, per le verifiche).
func aggiorna(budget_us: int) -> void:
	var d := cam.dimensione
	if d < DIM_COMPLETI:
		livello = COMPLETI
	elif d < DIM_LEGGERI:
		livello = LEGGERI
	elif d < DIM_SAGOME:
		livello = SAGOME
	else:
		livello = RADE
	terreno.materiale.set_shader_parameter("sottobosco", 1.0 if livello >= LEGGERI else 0.0)
	var lato := RADE_BLOCCO if livello == RADE else 1
	var servono := _blocchi_inquadrati(lato)
	var tenere := {}
	for u in servono:
		tenere[u] = true
	var t0 := Time.get_ticks_usec()
	var mancano := 0
	for u in servono:
		if _blocchi.has(u) and _blocchi[u]["livello"] == livello:
			continue
		var chiave := Vector4i(u.x, u.y, u.z, livello)
		if budget_us < 0:
			_prepara(chiave)
		_mutex.lock()
		var parti: Variant = _pronti.get(chiave)
		_pronti.erase(chiave)
		_mutex.unlock()
		if parti == null:
			mancano += 1
			if not _in_corso.has(chiave) and _in_corso.size() < COMPITI_MAX:
				_in_corso[chiave] = WorkerThreadPool.add_task(_prepara.bind(chiave), false, "Blocco di alberi")
			continue
		if _in_corso.has(chiave):
			WorkerThreadPool.wait_for_task_completion(_in_corso[chiave])
			_in_corso.erase(chiave)
		var vecchio: Variant = _blocchi.get(u)
		_costruisci(u, parti)
		if vecchio != null:
			for nodo in vecchio["nodi"]:
				(nodo as Node).queue_free()
		if budget_us >= 0 and Time.get_ticks_usec() - t0 > budget_us:
			mancano += 1
			break
	# I blocchi non più inquadrati (o dell'altra grandezza) si tolgono solo quando quelli nuovi
	# sono tutti pronti: cambiando zoom non si vedono buchi.
	if mancano == 0:
		for u in _blocchi.keys():
			if not tenere.has(u):
				_togli(u)
	# Compiti finiti: si liberano i posti.
	for chiave in _in_corso.keys():
		if WorkerThreadPool.is_task_completed(_in_corso[chiave]):
			WorkerThreadPool.wait_for_task_completion(_in_corso[chiave])
			_in_corso.erase(chiave)
	# Risultati non più utili (blocchi usciti dalla vista o livello cambiato).
	_mutex.lock()
	for chiave in _pronti.keys():
		if chiave.w != livello or not tenere.has(Vector3i(chiave.x, chiave.y, chiave.z)):
			_pronti.erase(chiave)
	_mutex.unlock()
	alberi_visibili = 0
	for u in _blocchi:
		if _blocchi[u]["livello"] == livello:
			alberi_visibili += _blocchi[u]["n"]


## Blocchi inquadrati (di `lato` x `lato` blocchi): il centro di ognuno, alla sua quota, si
## proietta sugli assi dello schermo (destra e alto della camera). Tenere conto della quota conta:
## con la camera inclinata un rilievo sposta il terreno in alto sullo schermo, e i blocchi ai bordi
## altrimenti mancavano. Ordinati dal più vicino al centro.
func _blocchi_inquadrati(lato: int) -> Array:
	var base := cam.camera.global_transform.basis
	var destra := base.x
	var alto := base.y
	var d := cam.dimensione
	var aspetto := 16.0 / 9.0
	var vp := get_viewport()
	if vp:
		var r := vp.get_visible_rect().size
		aspetto = r.x / maxf(r.y, 1.0)
	var mezza_l := d * aspetto * 0.5
	var mezza_a := d * 0.5
	var lb := Alberi.LATO_BLOCCO * lato
	# Mezzo blocco in diagonale, alberi alti e dislivelli dentro il blocco.
	var margine := lb * 0.71 + 60.0
	var c := cam.bersaglio
	var esag := terreno.esagerazione
	var dati := alberi.dati
	# Sul terreno la vista si allunga in profondità (camera a 30°) e i rilievi la allungano ancora.
	var raggio := sqrt(mezza_l * mezza_l + 4.0 * mezza_a * mezza_a) + (dati.quota_max - dati.quota_min) * esag * 1.8 + margine
	var nb := int(ceil(dati.lato_metri() / lb))
	var out := []
	for bz in range(maxi(floori((c.z - raggio) / lb), 0), mini(floori((c.z + raggio) / lb), nb - 1) + 1):
		for bx in range(maxi(floori((c.x - raggio) / lb), 0), mini(floori((c.x + raggio) / lb), nb - 1) + 1):
			var cx := (bx + 0.5) * lb
			var cz := (bz + 0.5) * lb
			var p := Vector3(cx, dati.quota(cx, cz) * esag, cz) - c
			if absf(p.dot(destra)) > mezza_l + margine or absf(p.dot(alto)) > mezza_a + margine:
				continue
			out.append(Vector3i(bx, bz, lato))
	out.sort_custom(func(a: Vector3i, b: Vector3i) -> bool:
		return _dist_blocco(a, c) < _dist_blocco(b, c))
	return out


func _dist_blocco(u: Vector3i, c: Vector3) -> float:
	var lb := Alberi.LATO_BLOCCO * u.z
	return Vector2((u.x + 0.5) * lb - c.x, (u.y + 0.5) * lb - c.z).length()


## Su un altro thread: dati del blocco e buffer delle MultiMesh, una parte per modello
## (per le sagome una parte sola). Ogni parte: [modello o -1, buffer, istanze, y_min, y_max].
func _prepara(chiave: Vector4i) -> void:
	var liv := chiave.w
	var lato := chiave.z
	var k := Alberi.CAMPI
	var dati := PackedFloat32Array()
	for j in lato:
		for i in lato:
			dati.append_array(alberi.alberi_nel_blocco(Vector2i(chiave.x * lato + i, chiave.y * lato + j)))
	var n := dati.size() / k
	var parti := []
	if liv == RADE or liv == SAGOME:
		var elenco := PackedInt32Array()
		for i in n:
			# Sagome rade: si tengono solo alcuni alberi (la tinta è un numero casuale per albero),
			# niente arbusti.
			if liv == RADE and ((dati[i * k + 5] - 0.84) / 0.24 >= RADE_QUOTA or int(dati[i * k + 4]) >= 7):
				continue
			elenco.append(i)
		if not elenco.is_empty():
			parti.append(_buffer(dati, elenco, true, -1, RADE_SCALA if liv == RADE else 1.0))
	else:
		var per_modello := []
		for _m in Alberi.MODELLI.size():
			per_modello.append(PackedInt32Array())
		for i in n:
			per_modello[int(dati[i * k + 4])].append(i)
		for m in per_modello.size():
			if not (per_modello[m] as PackedInt32Array).is_empty():
				parti.append(_buffer(dati, per_modello[m], false, m, 1.0))
	_mutex.lock()
	_pronti[chiave] = parti
	_mutex.unlock()


## Buffer di una MultiMesh: per ogni istanza trasformazione 3 x 4 per righe, colore e, per le
## sagome, dati personalizzati (modello, specchiata). Riempire il buffer in un colpo solo è molto
## più veloce che impostare le istanze una per una.
func _buffer(dati: PackedFloat32Array, elenco: PackedInt32Array, sagome: bool, modello: int, ingrandimento: float) -> Array:
	var k := Alberi.CAMPI
	var passo := 20 if sagome else 16
	var esag := terreno.esagerazione
	var buf := PackedFloat32Array()
	buf.resize(elenco.size() * passo)
	var y_min := 1e9
	var y_max := -1e9
	for j in elenco.size():
		var i := elenco[j] * k
		var x := dati[i]
		var z := dati[i + 1]
		var rot := dati[i + 2]
		var s := dati[i + 3] * ingrandimento
		var y := dati[i + 6] * esag - 0.1
		y_min = minf(y_min, y)
		y_max = maxf(y_max, y)
		var c := s
		var sn := 0.0
		if not sagome:
			c = cos(rot) * s
			sn = sin(rot) * s
		var o := j * passo
		buf[o] = c; buf[o + 2] = sn; buf[o + 3] = x
		buf[o + 5] = s; buf[o + 7] = y
		buf[o + 8] = -sn; buf[o + 10] = c; buf[o + 11] = z
		var t := dati[i + 5]
		buf[o + 12] = t; buf[o + 13] = t * 1.02; buf[o + 14] = t * 0.97; buf[o + 15] = 1.0
		if sagome:
			buf[o + 16] = dati[i + 4]
			buf[o + 17] = 1.0 if rot > PI else 0.0
	return [modello, buf, elenco.size(), y_min, y_max]


## Sul thread principale: crea le MultiMesh dai buffer già pronti (operazione veloce).
func _costruisci(u: Vector3i, parti: Array) -> void:
	var nodi := []
	var n := 0
	for p in parti:
		var modello: int = p[0]
		var sagome := modello < 0
		var mesh: Mesh = _quad if sagome else _mesh[livello][modello]
		if mesh == null:
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.use_custom_data = sagome
		mm.mesh = mesh
		mm.instance_count = p[2]
		mm.buffer = p[1]
		n += int(p[2])
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		if livello == RADE:
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if sagome:
			# Il rettangolo vero lo calcola lo shader: l'ingombro va dato a mano, altrimenti
			# Godot scarterebbe i blocchi ai bordi dello schermo.
			var lb := Alberi.LATO_BLOCCO * u.z
			mmi.custom_aabb = AABB(Vector3(u.x * lb - 40.0, p[3] - 20.0, u.y * lb - 40.0), Vector3(lb + 80.0, p[4] - p[3] + 80.0, lb + 80.0))
		add_child(mmi)
		nodi.append(mmi)
	_blocchi[u] = {"livello": livello, "nodi": nodi, "n": n}


## Attende i compiti in sottofondo (da chiamare prima di chiudere).
func aspetta() -> void:
	for chiave in _in_corso:
		WorkerThreadPool.wait_for_task_completion(_in_corso[chiave])
	_in_corso.clear()


func _togli(u: Vector3i) -> void:
	for nodo in _blocchi[u]["nodi"]:
		(nodo as Node).queue_free()
	_blocchi.erase(u)
