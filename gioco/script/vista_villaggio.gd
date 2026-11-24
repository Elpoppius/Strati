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
var _sentieri := {}
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
		uso.edifica(uso.celle_nel_cerchio(c.x, c.y, 14.0), false)


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


func _sincronizza_sentieri() -> void:
	var nuovi: Array[Vector2i] = []
	var ora := {}
	for k in sim.sentieri.size():
		var i: int = sim.sentieri[k]
		ora[i] = true
		if _sentieri.has(i):
			continue
		# Striscia di terra battuta dal centro del pixel verso il vicino precedente.
		var p := sim.px_di(i)
		var da := p
		for j in range(k - 1, -1, -1):
			if SimVillaggio.cheb(sim.px_di(sim.sentieri[j]), p) == 1:
				da = sim.px_di(sim.sentieri[j])
				break
		if da == p and SimVillaggio.cheb(p, sim.centro) <= 1:
			da = sim.centro
		var a := sim.mondo_di_px(da)
		var b := sim.mondo_di_px(p)
		# Celle contigue anche in diagonale: senza le vicine il sentiero sembrava tratteggiato.
		for t in 17:
			var q := a.lerp(b, t / 16.0)
			nuovi.append(uso.cella(q.x, q.y))
			nuovi.append(uso.cella(q.x + 4.0, q.y))
			nuovi.append(uso.cella(q.x, q.y + 4.0))
	if not nuovi.is_empty():
		uso.edifica(nuovi, false)
	var tolte: Array[Vector2i] = []
	for i in _sentieri.keys():
		if not ora.has(i):
			var c := sim.mondo_di_px(sim.px_di(i))
			tolte.append(uso.cella(c.x, c.y))
	if not tolte.is_empty():
		uso.libera(tolte)
	_sentieri = ora


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
		uso.edifica(uso.celle_nel_cerchio(w.x, w.y, RAGGIO_CORTILE), false)
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
		uso.edifica(uso.celle_nel_cerchio(sim.granaio.x, sim.granaio.y, 6.0), false)


## Rovine: qualche sasso dove c'erano il centro e le case (il fallimento come strato).
func _sincronizza_rovine() -> void:
	while _rovine < sim.rovine.size():
		var p: Vector2 = sim.rovine[_rovine]
		var sasso := _istanza("roccia_3")
		sasso.scale = Vector3.ONE * 0.7
		_posa(sasso, p, _rovine * 37.0)
		_rovine += 1
