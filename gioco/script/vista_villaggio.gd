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
var _celle_campi := {}  # cella da 10 m -> tecnica del campo disegnato
var _celle_sentieri := {}  # celle sotto i nastri segnate come costruite (fuori dai campi)
var _celle_nastro := {}  # tutte le celle sotto i nastri
var _firma_sentieri := ""
var _firma_campi := 0
var _nastri: MeshInstance3D
var _focolare: Node3D
var _centro := Vector2i(-1, -1)
var _rovine := 0
var _scene := {}


func prepara(s: SimVillaggio, u: UsoSuolo, t: Terreno) -> void:
	sim = s
	uso = u
	terreno = t
	# Zona agricola: un byte per punto della mappa, letto dallo shader del terreno (si vede mentre
	# si destina la terra).
	_immagine_zona = Image.create(sim.n, sim.n, false, Image.FORMAT_L8)
	_texture_zona = ImageTexture.create_from_image(_immagine_zona)
	terreno.materiale.set_shader_parameter("zona_agricola", _texture_zona)


func numero_case() -> int:
	return _case.size()


var _immagine_zona: Image
var _texture_zona: ImageTexture
var _firma_zona := 0


func _sincronizza_zona() -> void:
	var firma := sim.zona.hash()
	if firma == _firma_zona:
		return
	_firma_zona = firma
	_immagine_zona.fill(Color(0, 0, 0))
	for i in sim.zona:
		var p := sim.px_di(i)
		_immagine_zona.set_pixel(p.x, p.y, Color(1, 1, 1))
	_texture_zona.update(_immagine_zona)


## Bosco sacro: un byte per punto della mappa, letto dallo shader del terreno.
var _immagine_sacro: Image
var _texture_sacro: ImageTexture
var _firma_sacro := -1


func _sincronizza_bosco_sacro() -> void:
	if _immagine_sacro == null:
		_immagine_sacro = Image.create(sim.n, sim.n, false, Image.FORMAT_L8)
		_texture_sacro = ImageTexture.create_from_image(_immagine_sacro)
		terreno.materiale.set_shader_parameter("bosco_sacro_mappa", _texture_sacro)
	var firma := sim.bosco_sacro.hash()
	if firma == _firma_sacro:
		return
	_firma_sacro = firma
	_immagine_sacro.fill(Color(0, 0, 0))
	for i in sim.bosco_sacro:
		var p := sim.px_di(i)
		_immagine_sacro.set_pixel(p.x, p.y, Color(1, 1, 1))
	_texture_sacro.update(_immagine_sacro)


func sincronizza() -> void:
	_sincronizza_zona()
	_sincronizza_bosco_sacro()
	_sincronizza_centro()
	_sincronizza_campi_e_sentieri()
	_sincronizza_case()
	_sincronizza_edifici()
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


## Campi e sentieri insieme, cella per cella (10 m). Un sentiero che passa tra i campi non deve
## lasciare un corridoio d'erba a scalini largo un punto della mappa (40 m): Fede l'ha segnalato
## il 24/11/2026. Per questo le celle di un punto di sentiero confinante con dei campi si
## coltivano dalla parte dei campi rispetto alla linea vera del sentiero, e sotto il nastro dentro
## i campi non si segna niente come costruito (il campo tiene già lontani gli alberi; il nastro è
## disegnato sopra).
func _sincronizza_campi_e_sentieri() -> void:
	var nastri_cambiati := _aggiorna_nastri()
	var firma := hash([sim.campi.hash(), sim._tecnica_campi.hash(), sim.sentieri.hash()])
	if firma == _firma_campi and not nastri_cambiati:
		return
	_firma_campi = firma
	var campi_ora := _calcola_celle_campi()
	# Sotto i nastri: costruito solo fuori dai campi.
	var nastro_ora := {}
	for c in _celle_nastro:
		if not campi_ora.has(c):
			nastro_ora[c] = true
	var nuove: Array[Vector2i] = []
	for c in nastro_ora:
		if not _celle_sentieri.has(c):
			nuove.append(c)
	var tolte: Array[Vector2i] = []
	for c in _celle_sentieri:
		if not nastro_ora.has(c):
			tolte.append(c)
	if not tolte.is_empty():
		uso.libera(tolte)
	if not nuove.is_empty():
		uso.costruisci(nuove, "sentiero", false)
	_celle_sentieri = nastro_ora
	# Campi: nuovi o con una tecnica diversa (ammodernati), raggruppati per tecnica.
	var per_tecnica := {}
	for c in campi_ora:
		if not _celle_campi.has(c) or _celle_campi[c] != campi_ora[c]:
			if not per_tecnica.has(campi_ora[c]):
				per_tecnica[campi_ora[c]] = [] as Array[Vector2i]
			(per_tecnica[campi_ora[c]] as Array[Vector2i]).append(c)
	for t in per_tecnica:
		uso.coltiva(per_tecnica[t], t)
	# Campi tolti: tornano liberi, tranne le celle ora sotto un nastro o non coltivate (cortili).
	var via: Array[Vector2i] = []
	for c in _celle_campi:
		if not campi_ora.has(c) and not nastro_ora.has(c) and (uso.celle[c.y * uso.n + c.x] & UsoSuolo.MASCHERA_STATO) == UsoSuolo.COLTIVATO:
			via.append(c)
	if not via.is_empty():
		uso.libera(via)
	_celle_campi = campi_ora


func _calcola_celle_campi() -> Dictionary:
	var out := {}
	var campi := {}
	for i in sim.campi:
		campi[i] = true
		var t := sim.tecnica_campo(i)
		for c in _celle_px(i):
			out[c] = t
	for s in sim.sentieri:
		if campi.has(s):
			continue
		var p := sim.px_di(s)
		var vicini: Array[Vector2i] = []
		for oy in [-1, 0, 1]:
			for ox in [-1, 0, 1]:
				var q := p + Vector2i(ox, oy)
				if q.x >= 0 and q.y >= 0 and q.x < sim.n and q.y < sim.n and campi.has(sim.px(q)):
					vicini.append(q)
		if vicini.is_empty():
			continue
		var tratto := _tratto_vicino(sim.mondo_di_px(p))
		var t := sim.tecnica_campo(sim.px(vicini[0]))
		for c in _celle_px(s):
			var lato := _lato(tratto, uso.centro(c))
			for f in vicini:
				var lf := _lato(tratto, sim.mondo_di_px(f))
				if lato == 0 or lf == 0 or lf == lato:
					out[c] = t
					break
	return out


## Il tratto di sentiero (linea vera, in metri) più vicino a un punto.
func _tratto_vicino(w: Vector2) -> Array:
	var migliore := [w, w + Vector2(1, 0)]
	var d_min := INF
	for t in sim.tratti_sentiero:
		var a := sim.mondo_di_px(t[0])
		var b := sim.mondo_di_px(t[1])
		var d := w.distance_to(Geometry2D.get_closest_point_to_segment(w, a, b))
		if d < d_min:
			d_min = d
			migliore = [a, b]
	return migliore


## Da che parte della linea del tratto sta un punto: 1, -1, oppure 0 se ci sta quasi sopra.
func _lato(tratto: Array, w: Vector2) -> int:
	var a: Vector2 = tratto[0]
	var b: Vector2 = tratto[1]
	var d := (b - a).normalized()
	var x := d.cross(w - a)
	return 0 if absf(x) < 3.0 else (1 if x > 0.0 else -1)


## Sentieri (rifatti il 24/11/2026: prima erano celle di terra battuta da 10 m, una fascia scura
## e frastagliata che Fede ha bocciato). Ora ogni tratto è un nastro di terra largo 3 m posato
## sul terreno lungo la sua linea vera; dove attraversa un torrente il nastro si interrompe (guado).
## Sotto il nastro le celle contano come costruite (niente alberi), ma non si dipingono.
const LARGHEZZA_SENTIERO := 3.5
const PASSO_SENTIERO := 4.0

## Ricalcola i nastri quando cambiano i sentieri; restituisce vero se sono cambiati.
func _aggiorna_nastri() -> bool:
	var firma := "%d|%d|%d" % [sim.sentieri.hash(), sim.tratti_sentiero.size(), sim.centro.x]
	if firma == _firma_sentieri:
		return false
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
	_celle_nastro = celle_ora
	_disegna_nastri(pezzi)
	return true


func _disegna_nastri(pezzi: Array) -> void:
	if _nastri:
		_nastri.queue_free()
		_nastri = null
	if pezzi.is_empty():
		return
	_nastri = MeshInstance3D.new()
	_nastri.mesh = _mesh_nastro(pezzi, LARGHEZZA_SENTIERO, 0.35)
	_nastri.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m := ShaderMaterial.new()
	m.shader = load("res://shader/sentiero.gdshader")
	m.set_shader_parameter("macchie", load("res://asset/texture/macchie.png"))
	m.set_shader_parameter("evidenzia", 1.0 if _evidenzia else 0.0)
	_nastri.material_override = m
	add_child(_nastri)


## Nastro che segue il terreno lungo liste di punti (metri), largo `larghezza`, alzato di `alzo`.
func _mesh_nastro(pezzi: Array, larghezza: float, alzo: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for pezzo in pezzi:
		var lungo := 0.0
		for k in pezzo.size() - 1:
			var a: Vector2 = pezzo[k]
			var b: Vector2 = pezzo[k + 1]
			var d := (b - a).normalized()
			var lato := Vector2(-d.y, d.x) * larghezza * 0.5
			var l2 := lungo + a.distance_to(b)
			var punti := [a - lato, a + lato, b + lato, b - lato]
			var uv := [Vector2(0, lungo / 3.0), Vector2(1, lungo / 3.0), Vector2(1, l2 / 3.0), Vector2(0, l2 / 3.0)]
			var v3 := []
			for p in punti:
				v3.append(Vector3(p.x, terreno.quota_mondo(p.x, p.y) + alzo, p.y))
			for idx in [0, 1, 2, 0, 2, 3]:
				st.set_normal(Vector3.UP)
				st.set_uv(uv[idx])
				st.add_vertex(v3[idx])
			lungo = l2
	return st.commit()


# ---------- anteprima dei sentieri (come in Cities: Skylines) ----------
var _anteprima: MeshInstance3D
var _etichetta: Label3D
var _segno_inizio: MeshInstance3D
var _evidenzia := false

## Nastro trasparente da `a` a `b` (metri) che segue il terreno: bianco se si può tracciare,
## rosso se no; accanto alla fine la lunghezza o il motivo. Con a == b solo il punto d'inizio.
func mostra_anteprima(a: Vector2, b: Vector2, valido: bool, testo: String) -> void:
	if _anteprima == null:
		_anteprima = MeshInstance3D.new()
		_anteprima.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.no_depth_test = false
		m.render_priority = 2
		_anteprima.material_override = m
		add_child(_anteprima)
		_segno_inizio = MeshInstance3D.new()
		_segno_inizio.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_segno_inizio.material_override = m
		add_child(_segno_inizio)
		_etichetta = Label3D.new()
		_etichetta.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_etichetta.fixed_size = true
		_etichetta.pixel_size = 0.0012
		_etichetta.font_size = 28
		_etichetta.outline_size = 10
		_etichetta.no_depth_test = true
		_etichetta.render_priority = 3
		_etichetta.font = load(Hud.INTER % "Medium")
		add_child(_etichetta)
	var colore := Hud.BIANCO if valido else Hud.PERICOLO
	(_anteprima.material_override as StandardMaterial3D).albedo_color = Color(colore, 0.6)
	_etichetta.modulate = Color.WHITE if valido else Hud.PERICOLO
	_etichetta.outline_modulate = Color(Hud.NERO, 0.85)
	# Punto d'inizio: un quadratino agganciato al punto della mappa.
	_segno_inizio.mesh = _mesh_nastro([[a - Vector2(3, 0), a + Vector2(3, 0)]], 6.0, 0.7)
	_segno_inizio.visible = true
	if a.distance_to(b) > 1.0:
		var punti: Array[Vector2] = []
		var passi := maxi(1, ceili(a.distance_to(b) / PASSO_SENTIERO))
		for k in passi + 1:
			punti.append(a.lerp(b, float(k) / passi))
		_anteprima.mesh = _mesh_nastro([punti], LARGHEZZA_SENTIERO + 1.5, 0.6)
		_anteprima.visible = true
	else:
		_anteprima.visible = false
	_etichetta.text = testo
	_etichetta.position = Vector3(b.x, terreno.quota_mondo(b.x, b.y) + 8.0, b.y)
	_etichetta.visible = testo != ""


func nascondi_anteprima() -> void:
	for nodo in [_anteprima, _etichetta, _segno_inizio]:
		if nodo:
			nodo.visible = false


## Mentre lo strumento Sentiero è attivo la rete si schiarisce, per vedere a cosa agganciarsi.
func evidenzia_sentieri(si: bool) -> void:
	if si == _evidenzia:
		return
	_evidenzia = si
	if _nastri:
		(_nastri.material_override as ShaderMaterial).set_shader_parameter("evidenzia", 1.0 if si else 0.0)


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


## Edifici costruiti dal giocatore: granaio, legnaie (tettoia con le cataste, il ceppo e l'ascia),
## capanni da pesca (sulla riva, rastrelliera e piroga verso l'acqua) e poste di caccia (schiena al
## bosco); decisioni di Fede del 25/11/2026. Il lato +y del modello in Blender (-z in Godot) guarda
## verso l'acqua o il bosco: rotazione atan2(-v.x, -v.y). Attorno si tolgono gli alberi, in un
## cerchio largo per il capanno (i pioppi della riva lo nascondevano).
## Cantieri (decisione di Fede del 25/11/2026 sera): finché un edificio si costruisce si vede il suo
## scheletro, con sopra una barra discreta che avanza anno dopo anno; poi il modello finito.
const CANTIERI := {"granaio_su_pali": "cantiere_granaio", "legnaia": "cantiere_legnaia",
	"capanno_pesca": "cantiere_capanno_pesca", "posta_caccia": "cantiere_posta_caccia", "luogo_sacro": "cantiere_luogo_sacro"}
const ALTEZZA_BARRA := 6.5
var _edifici := {}  # punto -> {nodo, modello, raggio, barra}
## Cantieri aperti per le barre: punto -> [anni fatti, anni totali].
var _cantieri := {}
var _frazione_anno := 0.0


func _sincronizza_edifici() -> void:
	# punto -> [modello, gradi, raggio senza alberi, costruzione per l'uso del suolo, anni che mancano, anni totali]
	var ora := {}
	if sim.granaio.x >= 0:
		ora[sim.granaio] = ["granaio_su_pali", 0.0, 6.0, "granaio", sim.cantiere_granaio, SimVillaggio.ANNI_CANTIERE_GRANAIO]
	if sim.luogo_sacro.x >= 0:
		ora[sim.luogo_sacro] = ["luogo_sacro", 0.0, 7.0, "luogo_sacro", sim.cantiere_luogo_sacro, SimVillaggio.ANNI_CANTIERE_LUOGO_SACRO]
	for l in sim.legnaie:
		var p: Vector2 = l["punto"]
		ora[p] = ["legnaia", float(int(p.x * 7.0 + p.y * 13.0) % 360), 7.0, "legnaia", int(l["cantiere"]), SimVillaggio.ANNI_CANTIERE_LEGNAIA]
	for e in sim.capanni:
		var v: Vector2 = e["verso"]
		ora[e["punto"]] = ["capanno_pesca", rad_to_deg(atan2(-v.x, -v.y)), 14.0, "capanno_pesca", int(e["cantiere"]), SimVillaggio.ANNI_CANTIERE_RISORSE]
	for e in sim.poste:
		var v: Vector2 = e["verso"]
		ora[e["punto"]] = ["posta_caccia", rad_to_deg(atan2(-v.x, -v.y)), 8.0, "posta_caccia", int(e["cantiere"]), SimVillaggio.ANNI_CANTIERE_RISORSE]
	for p in _edifici.keys():
		if not ora.has(p):
			var e: Dictionary = _edifici[p]
			(e["nodo"] as Node3D).queue_free()
			if e["barra"] != null:
				(e["barra"] as Node3D).queue_free()
			uso.libera(uso.celle_nel_cerchio(p.x, p.y, float(e["raggio"])))
			_edifici.erase(p)
	_cantieri = {}
	for p in ora:
		var v: Array = ora[p]
		var in_cantiere := int(v[4]) > 0
		var modello: String = CANTIERI[v[0]] if in_cantiere else v[0]
		if not _edifici.has(p):
			_edifici[p] = {"nodo": null, "modello": "", "raggio": v[2], "barra": null}
			uso.costruisci(uso.celle_nel_cerchio(p.x, p.y, v[2]), v[3])
		var e: Dictionary = _edifici[p]
		if e["modello"] != modello:
			if e["nodo"] != null:
				(e["nodo"] as Node3D).queue_free()
			var nodo := _istanza(modello)
			_posa(nodo, p, v[1])
			e["nodo"] = nodo
			e["modello"] = modello
		if in_cantiere:
			if e["barra"] == null:
				e["barra"] = _nuova_barra(p)
			_cantieri[p] = [float(int(v[5]) - int(v[4])), float(v[5])]
		elif e["barra"] != null:
			(e["barra"] as Node3D).queue_free()
			e["barra"] = null
	aggiorna_barre(_frazione_anno)


func _nuova_barra(p: Vector2) -> MeshInstance3D:
	var barra := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	barra.mesh = quad
	var m := ShaderMaterial.new()
	m.shader = load("res://shader/barra_cantiere.gdshader")
	m.render_priority = 4
	barra.material_override = m
	barra.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# I vertici si spostano nello shader: il riquadro di prova non deve tagliarla fuori.
	barra.custom_aabb = AABB(Vector3(-20, -20, -20), Vector3(40, 40, 40))
	barra.position = Vector3(p.x, terreno.quota_mondo(p.x, p.y) + ALTEZZA_BARRA, p.y)
	add_child(barra)
	return barra


## Avanzamento delle barre: anni fatti più la parte dell'anno in corso (la partita la passa a ogni
## fotogramma, così la barra scorre invece di andare a scatti).
func aggiorna_barre(frazione: float) -> void:
	_frazione_anno = clampf(frazione, 0.0, 1.0)
	for p in _cantieri:
		var e: Dictionary = _edifici[p]
		if e["barra"] == null:
			continue
		var c: Array = _cantieri[p]
		var progresso := clampf((float(c[0]) + _frazione_anno) / maxf(float(c[1]), 1.0), 0.0, 1.0)
		((e["barra"] as MeshInstance3D).material_override as ShaderMaterial).set_shader_parameter("progresso", progresso)


## Quanti cantieri hanno la barra (per le verifiche).
func barre_aperte() -> int:
	var n := 0
	for p in _edifici:
		if _edifici[p]["barra"] != null:
			n += 1
	return n


## Rovine: qualche sasso dove c'erano il centro e le case (il fallimento come strato).
func _sincronizza_rovine() -> void:
	while _rovine < sim.rovine.size():
		var p: Vector2 = sim.rovine[_rovine]
		var sasso := _istanza("roccia_3")
		sasso.scale = Vector3.ONE * 0.7
		_posa(sasso, p, _rovine * 37.0)
		_rovine += 1
