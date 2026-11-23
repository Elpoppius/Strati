class_name VistaAlberi
extends Node3D
## Disegna gli alberi di Alberi con istanze multiple (MultiMesh per blocco), solo nei blocchi
## inquadrati e con un livello di dettaglio che segue lo zoom:
## - vista più stretta di DIM_COMPLETI: alberi completi (360–530 facce);
## - fino a DIM_LEGGERI: versione leggera (55–80 facce, poche carte grandi);
## - fino a DIM_SAGOME: sagome, un rettangolo per albero con l'immagine del modello
##   (strumenti/genera_sagome.gd), sempre rivolto verso la camera;
## - oltre: nessun albero, il terreno dipinge la volta delle chiome.
## Con alberi completi o leggeri lo shader del terreno dipinge il sottobosco; con le sagome resta
## la volta dipinta sotto, così tra una sagoma e l'altra (e nei blocchi non ancora pronti) si vede
## bosco e non terra.

const DIM_COMPLETI := 220.0
const DIM_LEGGERI := 700.0
const DIM_SAGOME := 2600.0
## Tempo massimo per fotogramma dedicato a costruire blocchi (microsecondi).
const BUDGET_US := 6000
const NOMI_LIVELLI := ["volta dipinta", "sagome", "alberi leggeri", "alberi completi"]
const SAGOME := 1
const LEGGERI := 2
const COMPLETI := 3

var alberi: Alberi
var terreno: Terreno
var cam: CameraIsometrica
## 0 volta dipinta, 1 sagome, 2 leggeri, 3 completi.
var livello := 0
## Alberi attualmente disegnati (per la lettura delle prestazioni).
var alberi_visibili := 0

var _mesh: Array = [[], [], [], []]  # per livello: una Mesh per modello (le sagome usano _quad)
var _quad: ArrayMesh
var _materiale_sagome: ShaderMaterial
var _blocchi := {}  # Vector2i -> { "livello": int, "nodi": Array, "n": int }
## I buffer delle MultiMesh si preparano su altri thread; qui arrivano pronti.
var _mutex := Mutex.new()
var _in_corso := {}  # Vector3i(bx, bz, livello) -> id del compito
var _pronti := {}  # Vector3i(bx, bz, livello) -> parti (vedi _prepara)
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
## (almeno uno per chiamata; -1 = tutti).
func aggiorna(budget_us: int) -> void:
	var d := cam.dimensione
	if d < DIM_COMPLETI:
		livello = COMPLETI
	elif d < DIM_LEGGERI:
		livello = LEGGERI
	elif d < DIM_SAGOME:
		livello = SAGOME
	else:
		livello = 0
	terreno.materiale.set_shader_parameter("sottobosco", 1.0 if livello >= LEGGERI else 0.0)
	var servono := _blocchi_inquadrati() if livello > 0 else []
	var tenere := {}
	for b in servono:
		tenere[b] = true
	for b in _blocchi.keys():
		if not tenere.has(b):
			_togli(b)
	# I blocchi di un altro livello restano visibili finché non c'è quello nuovo: niente buchi.
	# I dati e i buffer si preparano su altri thread (budget_us = -1: tutto subito, per le verifiche).
	var t0 := Time.get_ticks_usec()
	for b in servono:
		if _blocchi.has(b) and _blocchi[b]["livello"] == livello:
			continue
		var chiave := Vector3i(b.x, b.y, livello)
		if budget_us < 0:
			_prepara(chiave)
		_mutex.lock()
		var parti: Variant = _pronti.get(chiave)
		_pronti.erase(chiave)
		_mutex.unlock()
		if parti == null:
			if not _in_corso.has(chiave) and _in_corso.size() < COMPITI_MAX:
				_in_corso[chiave] = WorkerThreadPool.add_task(_prepara.bind(chiave), false, "Blocco di alberi")
			continue
		if _in_corso.has(chiave):
			WorkerThreadPool.wait_for_task_completion(_in_corso[chiave])
			_in_corso.erase(chiave)
		var vecchio: Variant = _blocchi.get(b)
		_costruisci(b, parti)
		if vecchio != null:
			for nodo in vecchio["nodi"]:
				(nodo as Node).queue_free()
		if budget_us >= 0 and Time.get_ticks_usec() - t0 > budget_us:
			break
	# Compiti finiti: si liberano i posti.
	for chiave in _in_corso.keys():
		if WorkerThreadPool.is_task_completed(_in_corso[chiave]):
			WorkerThreadPool.wait_for_task_completion(_in_corso[chiave])
			_in_corso.erase(chiave)
	# Risultati non più utili (blocchi usciti dalla vista o livello cambiato).
	_mutex.lock()
	for chiave in _pronti.keys():
		if chiave.z != livello or not tenere.has(Vector2i(chiave.x, chiave.y)):
			_pronti.erase(chiave)
	_mutex.unlock()
	alberi_visibili = 0
	for b in _blocchi:
		alberi_visibili += _blocchi[b]["n"]


## Blocchi inquadrati: il centro di ogni blocco, alla sua quota, si proietta sugli assi dello
## schermo (destra e alto della camera). Tenere conto della quota conta: con la camera inclinata
## un rilievo sposta il terreno in alto sullo schermo, e i blocchi ai bordi altrimenti mancavano.
## Ordinati dal più vicino al centro.
func _blocchi_inquadrati() -> Array:
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
	var lb := Alberi.LATO_BLOCCO
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
			out.append(Vector2i(bx, bz))
	out.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return _dist_blocco(a, c) < _dist_blocco(b, c))
	return out


func _dist_blocco(b: Vector2i, c: Vector3) -> float:
	var lb := Alberi.LATO_BLOCCO
	return Vector2((b.x + 0.5) * lb - c.x, (b.y + 0.5) * lb - c.z).length()


## Su un altro thread: dati del blocco e buffer delle MultiMesh, una parte per modello
## (per le sagome una parte sola). Ogni parte: [modello o -1, buffer, istanze, y_min, y_max].
func _prepara(chiave: Vector3i) -> void:
	var b := Vector2i(chiave.x, chiave.y)
	var liv := chiave.z
	var dati := alberi.alberi_nel_blocco(b)
	var k := Alberi.CAMPI
	var n := dati.size() / k
	var parti := []
	if liv == SAGOME:
		if n > 0:
			parti.append(_buffer(dati, PackedInt32Array(range(n)), true, -1))
	else:
		var per_modello := []
		for _m in Alberi.MODELLI.size():
			per_modello.append(PackedInt32Array())
		for i in n:
			per_modello[int(dati[i * k + 4])].append(i)
		for m in per_modello.size():
			if not (per_modello[m] as PackedInt32Array).is_empty():
				parti.append(_buffer(dati, per_modello[m], false, m))
	_mutex.lock()
	_pronti[chiave] = parti
	_mutex.unlock()


## Buffer di una MultiMesh: per ogni istanza trasformazione 3 x 4 per righe, colore e, per le
## sagome, dati personalizzati (modello, specchiata). Riempire il buffer in un colpo solo è molto
## più veloce che impostare le istanze una per una.
func _buffer(dati: PackedFloat32Array, elenco: PackedInt32Array, sagome: bool, modello: int) -> Array:
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
		var s := dati[i + 3]
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
func _costruisci(b: Vector2i, parti: Array) -> void:
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
		if sagome:
			# Il rettangolo vero lo calcola lo shader: l'ingombro va dato a mano, altrimenti
			# Godot scarterebbe i blocchi ai bordi dello schermo.
			var lb := Alberi.LATO_BLOCCO
			mmi.custom_aabb = AABB(Vector3(b.x * lb - 30.0, p[3] - 20.0, b.y * lb - 30.0), Vector3(lb + 60.0, p[4] - p[3] + 60.0, lb + 60.0))
		add_child(mmi)
		nodi.append(mmi)
	_blocchi[b] = {"livello": livello, "nodi": nodi, "n": n}


## Attende i compiti in sottofondo (da chiamare prima di chiudere).
func aspetta() -> void:
	for chiave in _in_corso:
		WorkerThreadPool.wait_for_task_completion(_in_corso[chiave])
	_in_corso.clear()


func _togli(b: Vector2i) -> void:
	for nodo in _blocchi[b]["nodi"]:
		(nodo as Node).queue_free()
	_blocchi.erase(b)
