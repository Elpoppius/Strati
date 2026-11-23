class_name VistaAlberi
extends Node3D
## Disegna gli alberi di Alberi con istanze multiple (una MultiMesh per modello e per blocco),
## solo nei blocchi inquadrati e con un livello di dettaglio che segue lo zoom:
## - vista più stretta di DIM_COMPLETI: alberi completi;
## - fino a DIM_LEGGERI: versione leggera (poche carte grandi, senza rami);
## - oltre: nessun albero, il terreno dipinge la volta delle chiome.
## Quando gli alberi sono visibili lo shader del terreno dipinge il sottobosco al posto della volta.

const DIM_COMPLETI := 220.0
const DIM_LEGGERI := 700.0
## Blocchi costruiti al massimo per fotogramma (evita scatti mentre si scorre la mappa).
const BLOCCHI_PER_FOTOGRAMMA := 2

var alberi: Alberi
var terreno: Terreno
var cam: CameraIsometrica
## 0 nessun albero, 1 leggeri, 2 completi.
var livello := 0
## Alberi attualmente disegnati (per la lettura delle prestazioni).
var alberi_visibili := 0

var _mesh: Array = [[], [], []]  # per livello: una Mesh per modello
var _blocchi := {}  # Vector2i -> { "livello": int, "nodi": Array, "n": int }


func prepara(a: Alberi, t: Terreno, c: CameraIsometrica) -> void:
	alberi = a
	terreno = t
	cam = c
	for nome in Alberi.MODELLI:
		_mesh[2].append(_carica_mesh("res://asset/alberi/%s.glb" % nome))
		_mesh[1].append(_carica_mesh("res://asset/alberi/%s_leggero.glb" % nome))


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
	aggiorna(BLOCCHI_PER_FOTOGRAMMA)


## Aggiorna i blocchi visibili; costruisce al massimo `massimo` blocchi nuovi (-1 = tutti).
func aggiorna(massimo: int) -> void:
	var d := cam.dimensione
	livello = 2 if d < DIM_COMPLETI else (1 if d < DIM_LEGGERI else 0)
	terreno.materiale.set_shader_parameter("sottobosco", 1.0 if livello > 0 else 0.0)
	var servono := _blocchi_inquadrati() if livello > 0 else []
	var tenere := {}
	for b in servono:
		tenere[b] = true
	for b in _blocchi.keys():
		if not tenere.has(b) or _blocchi[b]["livello"] != livello:
			_togli(b)
	var costruiti := 0
	for b in servono:
		if _blocchi.has(b):
			continue
		if massimo >= 0 and costruiti >= massimo:
			break
		_costruisci(b)
		costruiti += 1
	alberi_visibili = 0
	for b in _blocchi:
		alberi_visibili += _blocchi[b]["n"]


## Blocchi che toccano il rettangolo di terreno inquadrato (la vista è ruotata, quindi si
## proietta il centro di ogni blocco sugli assi della vista), dal più vicino al centro.
func _blocchi_inquadrati() -> Array:
	var assi := cam.assi_suolo()
	var destra: Vector3 = assi[0]
	var avanti: Vector3 = assi[1]
	var d := cam.dimensione
	var aspetto := 16.0 / 9.0
	var vp := get_viewport()
	if vp:
		var r := vp.get_visible_rect().size
		aspetto = r.x / maxf(r.y, 1.0)
	var mezza_l := d * aspetto * 0.5
	# La profondità del terreno inquadrato è circa il doppio dell'altezza della vista (camera a 30°).
	var mezza_p := d * 1.05
	var margine := Alberi.LATO_BLOCCO * 0.71 + 30.0
	var raggio := sqrt(mezza_l * mezza_l + mezza_p * mezza_p) + margine
	var c := cam.bersaglio
	var lb := Alberi.LATO_BLOCCO
	var out := []
	for bz in range(floori((c.z - raggio) / lb), floori((c.z + raggio) / lb) + 1):
		for bx in range(floori((c.x - raggio) / lb), floori((c.x + raggio) / lb) + 1):
			var centro := Vector3((bx + 0.5) * lb, 0.0, (bz + 0.5) * lb) - Vector3(c.x, 0.0, c.z)
			if absf(centro.dot(destra)) > mezza_l + margine or absf(centro.dot(avanti)) > mezza_p + margine:
				continue
			out.append(Vector2i(bx, bz))
	out.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return _dist_blocco(a, c) < _dist_blocco(b, c))
	return out


func _dist_blocco(b: Vector2i, c: Vector3) -> float:
	var lb := Alberi.LATO_BLOCCO
	return Vector2((b.x + 0.5) * lb - c.x, (b.y + 0.5) * lb - c.z).length()


func _costruisci(b: Vector2i) -> void:
	var dati := alberi.alberi_nel_blocco(b)
	var k := Alberi.CAMPI
	var n := dati.size() / k
	# Raggruppa gli alberi per modello.
	var per_modello := []
	for _m in Alberi.MODELLI.size():
		per_modello.append(PackedInt32Array())
	for i in n:
		per_modello[int(dati[i * k + 4])].append(i)
	var nodi := []
	for m in per_modello.size():
		var elenco: PackedInt32Array = per_modello[m]
		var mesh: Mesh = _mesh[livello][m]
		if elenco.is_empty() or mesh == null:
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = mesh
		mm.instance_count = elenco.size()
		for j in elenco.size():
			var i := elenco[j]
			var x := dati[i * k]
			var z := dati[i * k + 1]
			var s := dati[i * k + 3]
			var base := Basis(Vector3.UP, dati[i * k + 2]).scaled(Vector3(s, s, s))
			mm.set_instance_transform(j, Transform3D(base, Vector3(x, terreno.quota_mondo(x, z) - 0.1, z)))
			var t := dati[i * k + 5]
			mm.set_instance_color(j, Color(t, t * 1.02, t * 0.97))
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		add_child(mmi)
		nodi.append(mmi)
	_blocchi[b] = {"livello": livello, "nodi": nodi, "n": n}


func _togli(b: Vector2i) -> void:
	for nodo in _blocchi[b]["nodi"]:
		(nodo as Node).queue_free()
	_blocchi.erase(b)
