class_name VistaVillaggio
extends Node3D
## Disegna lo stato di SimVillaggio sulla mappa: case e granaio con i modelli del villaggio,
## campi e sentieri attraverso l'uso del suolo (campi = suolo coltivato, sentieri e attorno alle
## case = terra battuta), rovine dei villaggi abbandonati. La simulazione non sa nulla di tutto
## questo: la vista confronta lo stato con quello che ha già disegnato e aggiorna solo le
## differenze (sincronizza()).

const CARTELLA := "res://asset/villaggio/"
## Modelli delle case con il loro peso (abitato spontaneo: tipi misti).
const CASE := [["casa_lunga_piccola", 35], ["casa_lunga_media", 30], ["capanna_tonda", 18], ["capanna_tonda_piccola", 12], ["casa_lunga_grande", 5]]
const RAGGIO_CORTILE := 9.0

var sim: SimVillaggio
var uso: UsoSuolo
var terreno: Terreno
var _case := {}  # lotto -> nodo
var _campi := {}  # indice del pixel -> true
var _celle_sentieri := {}
var _firma_sentieri := ""
var _nastri: MeshInstance3D
var _granaio: Node3D
var _granaio_pos := Vector2(-1, -1)
var _focolare: Node3D
var _centro := Vector2i(-1, -1)
var _rovine := 0
var _scene := {}


func prepara(s: SimVillaggio, u: UsoSuolo, t: Terreno) -> void:
	sim = s
	uso = u
	terreno = t


func numero_case() -> int:
	return _case.size()


func sincronizza() -> void:
	_sincronizza_centro()
	_sincronizza_campi()
	_sincronizza_sentieri()
	_sincronizza_case()
	_sincronizza_granaio()
	_sincronizza_rovine()


func _istanza(nome: String) -> Node3D:
	if not _scene.has(nome):
		_scene[nome] = load(CARTELLA + nome + ".glb")
	var nodo: Node3D = (_scene[nome] as PackedScene).instantiate()
	Asset.prepara(nodo)
	return nodo


func _posa(nodo: Node3D, punto: Vector2, gradi: float) -> void:
	nodo.position = Vector3(punto.x, terreno.quota_mondo(punto.x, punto.y), punto.y)
	nodo.rotation_degrees.y = gradi
	add_child(nodo)


## Numero tra 0 e 1 legato a un lotto (stesso lotto, stessa casa e stessa rotazione).
static func _caso(l: Vector2i, sale: int) -> float:
	var h := (l.x * 73856093) ^ (l.y * 19349663) ^ (sale * 83492791)
	h &= 0x7fffffff
	h = ((h >> 13) ^ h) * 1274126177 & 0x7fffffff
	return float(h & 0xffff) / 65536.0


func _sincronizza_centro() -> void:
	if sim.centro == _centro:
		return
	if _focolare:
		_focolare.queue_free()
		_focolare = null
		uso.libera(uso.celle_nel_cerchio(sim.mondo_di_px(_centro).x, sim.mondo_di_px(_centro).y, 14.0))
	_centro = sim.centro
	if sim.fondato:
		var c := sim.mondo_di_px(sim.centro)
		_focolare = _istanza("focolare")
		_posa(_focolare, c, 0.0)
		uso.costruisci(uso.celle_nel_cerchio(c.x, c.y, 14.0), "focolare")


func _celle_px(i: int) -> Array[Vector2i]:
	var p := sim.px_di(i)
	var c := sim.mondo_di_px(p)
	var m := sim.dati.metri_per_px * 0.5
	var a := uso.cella(c.x - m + 1.0, c.y - m + 1.0)
	var b := uso.cella(c.x + m - 1.0, c.y + m - 1.0)
	var out: Array[Vector2i] = []
	for y in range(a.y, b.y + 1):
		for x in range(a.x, b.x + 1):
			out.append(Vector2i(x, y))
	return out


func _sincronizza_campi() -> void:
	var ora := {}
	for i in sim.campi:
		ora[i] = true
	for i in ora:
		if not _campi.has(i):
			uso.coltiva(_celle_px(i))
	for i in _campi.keys():
		if not ora.has(i):
			uso.libera(_celle_px(i))
	_campi = ora


## Sentieri (rifatti il 24/11/2026: prima erano celle di terra battuta da 10 m, una fascia scura
## e frastagliata che Fede ha bocciato). Ora ogni tratto è un nastro di terra largo 3 m posato
## sul terreno lungo la sua linea vera; dove attraversa un torrente il nastro si interrompe (guado).
## Sotto il nastro le celle contano come costruite (niente alberi), ma non si dipingono.
const LARGHEZZA_SENTIERO := 3.5
const PASSO_SENTIERO := 4.0

func _sincronizza_sentieri() -> void:
	var firma := "%d|%d" % [sim.sentieri.size(), sim.tratti_sentiero.size()]
	if firma == _firma_sentieri:
		return
	_firma_sentieri = firma
	var presenti := {}
	for i in sim.sentieri:
		presenti[i] = true
	var celle_ora := {}
	var pezzi: Array = []  # liste di punti (Vector2) consecutivi da disegnare
	for t in sim.tratti_sentiero:
		var a := sim.mondo_di_px(t[0])
		var b := sim.mondo_di_px(t[1])
		var passi := maxi(1, ceili(a.distance_to(b) / PASSO_SENTIERO))
		var pezzo: Array[Vector2] = []
		# Un sentiero battuto a piedi non è mai dritto: lo si fa serpeggiare di qualche metro con
		# un'onda fissa per ogni tratto (stesso disegno a ogni avvio), nulla agli estremi.
		var normale := (b - a).normalized().orthogonal()
		var fase := float(hash(t) % 1000) * 0.0063
		for k in passi + 1:
			var f := float(k) / passi
			var s_m := f * a.distance_to(b)
			var onda := sin(PI * f) * (4.0 * sin(s_m / 41.0 + fase) + 1.5 * sin(s_m / 13.0 + fase * 2.7))
			var q := a.lerp(b, f) + normale * onda
			var pxq := sim.px_da_mondo(q.x, q.y)
			# Il pixel del punto o uno vicino è sentiero: la linea dritta e i pixel a scalini non
			# coincidono sempre, e senza questa tolleranza il nastro veniva tratteggiato.
			var su_sentiero := SimVillaggio.cheb(pxq, sim.centro) <= 1
			for oy in [-1, 0, 1]:
				for ox in [-1, 0, 1]:
					if presenti.has(sim.px(pxq + Vector2i(ox, oy))):
						su_sentiero = true
			var buono := su_sentiero and uso.alberi.distanza_acqua(q.x, q.y) > 1.0
			if buono:
				pezzo.append(q)
				celle_ora[uso.cella(q.x, q.y)] = true
			elif pezzo.size() > 1:
				pezzi.append(pezzo)
				pezzo = []
			else:
				pezzo = []
		if pezzo.size() > 1:
			pezzi.append(pezzo)
	var nuove: Array[Vector2i] = []
	for c in celle_ora:
		if not _celle_sentieri.has(c):
			nuove.append(c)
	if not nuove.is_empty():
		uso.costruisci(nuove, "sentiero", false)
	var tolte: Array[Vector2i] = []
	for c in _celle_sentieri:
		if not celle_ora.has(c):
			tolte.append(c)
	if not tolte.is_empty():
		uso.libera(tolte)
	_celle_sentieri = celle_ora
	_disegna_nastri(pezzi)


func _disegna_nastri(pezzi: Array) -> void:
	if _nastri:
		_nastri.queue_free()
		_nastri = null
	if pezzi.is_empty():
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for pezzo in pezzi:
		var lungo := 0.0
		for k in pezzo.size() - 1:
			var a: Vector2 = pezzo[k]
			var b: Vector2 = pezzo[k + 1]
			var d := (b - a).normalized()
			var lato := Vector2(-d.y, d.x) * LARGHEZZA_SENTIERO * 0.5
			var l2 := lungo + a.distance_to(b)
			var punti := [a - lato, a + lato, b + lato, b - lato]
			var uv := [Vector2(0, lungo / 3.0), Vector2(1, lungo / 3.0), Vector2(1, l2 / 3.0), Vector2(0, l2 / 3.0)]
			var v3 := []
			for p in punti:
				v3.append(Vector3(p.x, terreno.quota_mondo(p.x, p.y) + 0.35, p.y))
			for idx in [0, 1, 2, 0, 2, 3]:
				st.set_normal(Vector3.UP)
				st.set_uv(uv[idx])
				st.add_vertex(v3[idx])
			lungo = l2
	_nastri = MeshInstance3D.new()
	_nastri.mesh = st.commit()
	_nastri.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m := ShaderMaterial.new()
	m.shader = load("res://shader/sentiero.gdshader")
	m.set_shader_parameter("macchie", load("res://asset/texture/macchie.png"))
	_nastri.material_override = m
	add_child(_nastri)


func _sincronizza_case() -> void:
	var ora := {}
	for l in sim.case:
		ora[l] = true
	for l in sim.case:
		if _case.has(l):
			continue
		var r := _caso(l, 1) * 100.0
		var nome: String = CASE[0][0]
		for voce in CASE:
			r -= voce[1]
			if r < 0.0:
				nome = voce[0]
				break
		var nodo := _istanza(nome)
		var w := sim.centro_lotto(l)
		_posa(nodo, w, roundf(_caso(l, 2) * 24.0) * 15.0)
		_case[l] = nodo
		uso.costruisci(uso.celle_nel_cerchio(w.x, w.y, RAGGIO_CORTILE), "casa_lunga" if nome.begins_with("casa") else "capanna")
	for l in _case.keys():
		if not ora.has(l):
			(_case[l] as Node3D).queue_free()
			_case.erase(l)
			var w := sim.centro_lotto(l)
			uso.libera(uso.celle_nel_cerchio(w.x, w.y, RAGGIO_CORTILE))


func _sincronizza_granaio() -> void:
	if sim.granaio == _granaio_pos:
		return
	if _granaio:
		_granaio.queue_free()
		_granaio = null
		uso.libera(uso.celle_nel_cerchio(_granaio_pos.x, _granaio_pos.y, 6.0))
	_granaio_pos = sim.granaio
	if sim.granaio.x >= 0:
		_granaio = _istanza("granaio_su_pali")
		_posa(_granaio, sim.granaio, 0.0)
		uso.costruisci(uso.celle_nel_cerchio(sim.granaio.x, sim.granaio.y, 6.0), "granaio")


## Rovine: qualche sasso dove c'erano il centro e le case (il fallimento come strato).
func _sincronizza_rovine() -> void:
	while _rovine < sim.rovine.size():
		var p: Vector2 = sim.rovine[_rovine]
		var sasso := _istanza("roccia_3")
		sasso.scale = Vector3.ONE * 0.7
		_posa(sasso, p, _rovine * 37.0)
		_rovine += 1
