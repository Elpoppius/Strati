class_name VistaPersone
extends Node3D
## Popolazione visibile (decisioni di Fede del 25–26/11/2026, voce 7 del todo): ogni figura fa un
## lavoro vero della simulazione. Contadini nei campi, boscaioli alle legnaie, pescatori ai capanni,
## cacciatori nel bosco dietro le poste, pastori con le greggi, costruttori ai cantieri, gente al
## luogo sacro e tra le case. Le figure camminano a velocità normale; ogni anno cambia quante sono e
## dove vanno. Si vedono solo da vicino.
##
## Modelli: 3 uomini e 3 donne (Asset.PERSONE), completi da vicino e leggeri più in là, con
## l'attrezzo nella mano destra (Asset.ATTREZZI); colori e animazioni in persone.gdshader. Lo stato
## di ogni figura va allo shader nei dati personalizzati della MultiMesh (vedi lo shader).
##
## Numeri (proposta di Claude, da misurare con Fede sui suoi PC): al massimo TETTO figure; una figura
## vale 1, 2 o 5 persone secondo gli abitanti.

const TETTO := 150
const DIM_VISIBILI := 450.0  # oltre questa vista (metri) le persone non si disegnano
const DIM_COMPLETE := 140.0  # sotto, i modelli completi
const VELOCITA := 1.1  # metri al secondo, il passo di chi va al lavoro
const ACCELERAZIONE := 1.2
const GIRATA := 160.0  # gradi al secondo
## Mestieri: lavoro dello shader (0 zappare, 1 tagliare, 2 lancia, 3 raccogliere, 4 costruire,
## 5 bastone) e attrezzo in mano (indice in Asset.ATTREZZI, -1 nessuno).
const MESTIERI := {
	"contadino": {"lavoro": 0, "attrezzo": "zappa"},
	"raccoglitrice": {"lavoro": 3, "attrezzo": "cesto"},
	"boscaiolo": {"lavoro": 1, "attrezzo": "ascia"},
	"pescatore": {"lavoro": 2, "attrezzo": "lancia"},
	"cacciatore": {"lavoro": 2, "attrezzo": "lancia"},
	"pastore": {"lavoro": 5, "attrezzo": "bastone"},
	"costruttore": {"lavoro": 4, "attrezzo": "ascia"},
	"sacro": {"lavoro": -1, "attrezzo": ""},
	"casa": {"lavoro": -1, "attrezzo": ""},
}

var sim: SimVillaggio
var terreno: Terreno
var vista: VistaVillaggio
var _figure: Array = []
var _corpi := {}  # "modello:livello" -> MultiMeshInstance3D
var _attrezzi := {}  # "attrezzo:sesso" -> MultiMeshInstance3D
var _caso := RandomNumberGenerator.new()
var _visibili := true
var _complete := true
## Quante persone vale una figura (1, 2 o 5), per le verifiche e la scheda.
var quota := 1
## Scheda della famiglia (26/11/2026): ogni figura abita in una casa vera (il suo lotto); i membri
## della famiglia aperta si illuminano (l'alfa del colore dell'istanza lo dice allo shader).
const NESSUNA := Vector2i(-99999, -99999)
var evidenziata := NESSUNA


func prepara(s: SimVillaggio, t: Terreno, v: VistaVillaggio) -> void:
	sim = s
	terreno = t
	vista = v
	_caso.seed = 11
	for k in Asset.PERSONE.size():
		for livello in ["completo", "leggero"]:
			_corpi["%d:%s" % [k, livello]] = _nuova_mm(Asset.mesh_persona(Asset.PERSONE[k], livello == "leggero"))
	for a in Asset.ATTREZZI:
		for sesso in ["uomo", "donna"]:
			_attrezzi["%s:%s" % [a, sesso]] = _nuova_mm(Asset.mesh_attrezzo(a, sesso == "donna"))
	for k in _corpi:
		(_corpi[k] as Node3D).visible = k.ends_with("completo")


func _nuova_mm(mesh: Mesh) -> MultiMeshInstance3D:
	var mmi := MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.use_colors = true  # come per gli animali: con i soli dati personalizzati il renderer Compatibilità li disegnava neri
	mm.mesh = mesh
	mmi.multimesh = mm
	add_child(mmi)
	return mmi


## Quante figure servono e che mestieri fanno: si rifà ogni anno, dalla simulazione.
func sincronizza() -> void:
	if not sim.fondato:
		_figure = []
		_aggiorna_conti()
		return
	var pop := sim.pop
	quota = 1 if pop <= TETTO else (2 if pop <= TETTO * 2 else 5)
	var voluti := mini(TETTO, ceili(pop / quota))
	var mestieri := _mestieri(voluti)
	# Chi c'è già tiene il suo mestiere finché serve: si tolgono o si aggiungono le differenze.
	var conti := {}
	for m in mestieri:
		conti[m] = int(conti.get(m, 0)) + 1
	var tenute: Array = []
	for f in _figure:
		var m: String = f["mestiere"]
		if int(conti.get(m, 0)) > 0 and _luogo_valido(f):
			conti[m] = int(conti[m]) - 1
			tenute.append(f)
	_figure = tenute
	# Chi ha perso la casa (piena, demolizione) va ad abitare in un'altra.
	var ci_sono := {}
	for l in sim.case:
		ci_sono[l] = true
	for f in _figure:
		if not ci_sono.has(f["lotto"]):
			_dai_casa(f)
	_bilancia_case()
	for m in conti:
		for _k in int(conti[m]):
			if _figure.size() < voluti:
				_figure.append(_nuova_figura(m))
	_aggiorna_conti()


## Mestieri per `n` figure, nella proporzione del lavoro vero di quest'anno.
func _mestieri(n: int) -> Array:
	var fuori: Array = []
	var cantieri := _cantieri()
	for _c in cantieri:
		for _k in 3:
			fuori.append("costruttore")
	if sim.luogo_sacro_pronto():
		for _k in 3:
			fuori.append("sacro")
	for _g in vista._greggi.size():
		fuori.append("pastore")
	fuori = fuori.slice(0, int(n * 0.3))
	# Circa un terzo resta in paese (vecchi, bambini, chi è di turno a casa): attorno al focolare
	# e alle case, così il villaggio non sembra vuoto mentre gli altri sono nei campi.
	var lavoratori := maxi(0, int(n * 0.64) - fuori.size())
	var pesi := {
		"contadino": sim.ultimo_raccolto if sim.fonti["agricoltura"] and not sim.campi.is_empty() else 0.0,
		"boscaiolo": sim.ultima_legna * 3.0 if _legnaie_attive().size() > 0 else 0.0,
		"pescatore": sim.ultima_pesca if not sim.capanni.is_empty() else 0.0,
		"cacciatore": sim.ultima_caccia if not sim.poste.is_empty() else 0.0,
	}
	var totale := 0.0
	for k in pesi:
		totale += float(pesi[k])
	var out: Array = fuori.duplicate()
	if totale > 0.0:
		for k in pesi:
			var q := roundi(lavoratori * float(pesi[k]) / totale)
			for _i in q:
				out.append("raccoglitrice" if k == "contadino" and _caso.randf() < 0.25 else k)
	while out.size() < n:
		out.append("casa")
	return out.slice(0, n)


func _cantieri() -> Array:
	var out: Array = []
	if sim.granaio.x >= 0 and sim.cantiere_granaio > 0:
		out.append(sim.granaio)
	if sim.luogo_sacro.x >= 0 and sim.cantiere_luogo_sacro > 0:
		out.append(sim.luogo_sacro)
	for l in sim.legnaie + sim.capanni + sim.poste:
		if int(l["cantiere"]) > 0:
			out.append(l["punto"])
	return out


func _legnaie_attive() -> Array:
	return sim.legnaie.filter(func(l: Dictionary) -> bool: return sim.legnaia_attiva(l))


func _nuova_figura(mestiere: String) -> Dictionary:
	var k := _caso.randi() % Asset.PERSONE.size()
	var donna := String(Asset.PERSONE[k]).begins_with("donna")
	if mestiere == "raccoglitrice":
		# Le raccoglitrici sono donne o uomini, ma nel modello si vede il cesto.
		pass
	var f := {"modello": k, "donna": donna, "mestiere": mestiere, "casa": Vector2.ZERO, "lotto": NESSUNA,
		"verso": _caso.randf() * 360.0, "vel": 0.0, "fase": _caso.randf() * TAU, "stato": "fermo",
		"tempo": _caso.randf_range(0.0, 6.0), "seme": _caso.randf(), "luogo": Vector2.INF, "guarda": Vector2.INF}
	_dai_casa(f)
	f["pos"] = f["casa"]
	f["meta"] = f["casa"]
	_nuovo_luogo(f)
	# Al primo anno chi lavora è già al lavoro, chi sta a casa è tra le case.
	f["pos"] = f["meta"]
	f["stato"] = "lavora" if f["mestiere"] != "casa" else "fermo"
	return f


## Una casa per la figura: quella con meno figure, così ogni famiglia ha i suoi membri visibili.
func _dai_casa(f: Dictionary) -> void:
	if sim.case.is_empty():
		f["lotto"] = NESSUNA
		f["casa"] = sim.mondo_di_px(sim.centro) + Vector2.from_angle(_caso.randf() * TAU) * _caso.randf_range(4.0, 15.0)
		return
	var conta := {}
	for g in _figure:
		conta[g["lotto"]] = int(conta.get(g["lotto"], 0)) + 1
	var scelta: Vector2i = sim.case[0]
	var meno := 1 << 30
	var inizio := _caso.randi() % sim.case.size()
	for k in sim.case.size():
		var l: Vector2i = sim.case[(inizio + k) % sim.case.size()]
		var c := int(conta.get(l, 0))
		if c < meno:
			meno = c
			scelta = l
	f["lotto"] = scelta
	f["casa"] = sim.centro_lotto(scelta) + Vector2.from_angle(_caso.randf() * TAU) * _caso.randf_range(5.0, 9.0)


## Le case nuove prendono qualche figura da quelle che ne hanno di più: ogni famiglia ha i suoi
## membri visibili (finché le figure bastano).
func _bilancia_case() -> void:
	if sim.case.is_empty() or _figure.is_empty():
		return
	for _giro in 400:
		var conta := {}
		for l in sim.case:
			conta[l] = []
		for f in _figure:
			if conta.has(f["lotto"]):
				(conta[f["lotto"]] as Array).append(f)
		var piena: Vector2i = sim.case[0]
		var vuota: Vector2i = sim.case[0]
		for l in sim.case:
			if (conta[l] as Array).size() > (conta[piena] as Array).size():
				piena = l
			if (conta[l] as Array).size() < (conta[vuota] as Array).size():
				vuota = l
		if (conta[piena] as Array).size() - (conta[vuota] as Array).size() <= 1:
			return
		var f: Dictionary = (conta[piena] as Array).back()
		f["lotto"] = vuota
		f["casa"] = sim.centro_lotto(vuota) + Vector2.from_angle(_caso.randf() * TAU) * _caso.randf_range(5.0, 9.0)


## Le figure che abitano in una casa.
func membri(l: Vector2i) -> Array:
	return _figure.filter(func(f: Dictionary) -> bool: return f["lotto"] == l)


## La figura più vicina al punto dello schermo, entro il suo ingombro; vuoto se non ce n'è.
func figura_sotto(camera: Camera3D, pos_schermo: Vector2) -> Dictionary:
	if not _visibili or camera == null:
		return {}
	var migliore := {}
	var meglio := INF
	for f in _figure:
		var p: Vector2 = f["pos"]
		var piedi := Vector3(p.x, terreno.quota_mondo(p.x, p.y), p.y)
		if camera.is_position_behind(piedi):
			continue
		var a := camera.unproject_position(piedi)
		var b := camera.unproject_position(piedi + Vector3.UP * 1.7)
		var alto := maxf(a.distance_to(b), 6.0)
		var centro := (a + b) * 0.5
		var d := pos_schermo.distance_to(centro)
		if d < maxf(alto * 0.6, 10.0) and d < meglio:
			meglio = d
			migliore = f
	return migliore


func _punto_casa() -> Vector2:
	if sim.case.is_empty():
		return sim.mondo_di_px(sim.centro) + Vector2.from_angle(_caso.randf() * TAU) * _caso.randf_range(4.0, 15.0)
	var l: Vector2i = sim.case[_caso.randi() % sim.case.size()]
	return sim.centro_lotto(l) + Vector2.from_angle(_caso.randf() * TAU) * _caso.randf_range(5.0, 9.0)


## Il luogo di lavoro c'è ancora? (una legnaia demolita, un capanno tolto…)
func _luogo_valido(f: Dictionary) -> bool:
	match String(f["mestiere"]):
		"contadino", "raccoglitrice":
			return not sim.campi.is_empty()
		"boscaiolo":
			return _legnaie_attive().any(func(l: Dictionary) -> bool: return (l["punto"] as Vector2) == f["luogo"])
		"pescatore":
			return sim.capanni.any(func(e: Dictionary) -> bool: return (e["punto"] as Vector2) == f["luogo"])
		"cacciatore":
			return sim.poste.any(func(e: Dictionary) -> bool: return (e["punto"] as Vector2) == f["luogo"])
		"costruttore":
			return _cantieri().has(f["luogo"])
		"sacro":
			return sim.luogo_sacro_pronto()
		"pastore":
			return not vista._greggi.is_empty()
	return true


## Dove va a lavorare (o a stare) una figura: un punto vicino al suo luogo, e da che parte guarda.
func _nuovo_luogo(f: Dictionary) -> void:
	var m: String = f["mestiere"]
	var meta: Vector2 = f["pos"]
	var guarda := Vector2.INF
	match m:
		"contadino", "raccoglitrice":
			if f["luogo"] == Vector2.INF or _caso.randf() < 0.15:
				var i: int = sim.campi[_caso.randi() % sim.campi.size()]
				f["luogo"] = sim.mondo_di_px(sim.px_di(i))
			meta = (f["luogo"] as Vector2) + Vector2(_caso.randf_range(-16.0, 16.0), _caso.randf_range(-16.0, 16.0))
		"boscaiolo":
			var legnaie := _legnaie_attive()
			if f["luogo"] == Vector2.INF or not legnaie.any(func(l: Dictionary) -> bool: return (l["punto"] as Vector2) == f["luogo"]):
				f["luogo"] = (legnaie[_caso.randi() % legnaie.size()] as Dictionary)["punto"]
			var dir := Vector2.from_angle(_caso.randf() * TAU)
			meta = (f["luogo"] as Vector2) + dir * _caso.randf_range(12.0, 35.0)
			guarda = meta + dir * 3.0
		"pescatore", "cacciatore":
			var elenco: Array = sim.capanni if m == "pescatore" else sim.poste
			var scelto: Dictionary = {}
			for e in elenco:
				if (e["punto"] as Vector2) == f["luogo"]:
					scelto = e
			if scelto.is_empty():
				scelto = elenco[_caso.randi() % elenco.size()]
				f["luogo"] = scelto["punto"]
			var verso: Vector2 = (scelto["verso"] as Vector2).normalized()
			var lato := Vector2(-verso.y, verso.x)
			if m == "pescatore":  # sulla riva accanto al capanno, rivolto all'acqua
				meta = (scelto["punto"] as Vector2) + verso * 1.2 + lato * _caso.randf_range(-5.0, 5.0)
			else:  # nel bosco dietro la posta
				meta = (scelto["punto"] as Vector2) + verso * _caso.randf_range(15.0, 50.0) + lato * _caso.randf_range(-20.0, 20.0)
			guarda = meta + verso * 5.0
		"pastore":
			var g := int(f["seme"] * 1000.0) % vista._greggi.size()
			var c: Vector2 = vista._greggi[g]["centro"]
			f["luogo"] = c
			meta = c + Vector2.from_angle(_caso.randf() * TAU) * _caso.randf_range(6.0, 14.0)
			guarda = c
		"costruttore":
			var cantieri := _cantieri()
			if not cantieri.has(f["luogo"]):
				f["luogo"] = cantieri[_caso.randi() % cantieri.size()]
			var a := _caso.randf() * TAU
			meta = (f["luogo"] as Vector2) + Vector2.from_angle(a) * _caso.randf_range(2.5, 4.5)
			guarda = f["luogo"]
		"sacro":
			f["luogo"] = sim.luogo_sacro
			meta = sim.luogo_sacro + Vector2.from_angle(_caso.randf() * TAU) * _caso.randf_range(4.5, 7.0)
			guarda = sim.luogo_sacro
		_:
			var r := _caso.randf()
			if r < 0.45:  # attorno al focolare, in centro
				meta = sim.mondo_di_px(sim.centro) + Vector2.from_angle(_caso.randf() * TAU) * _caso.randf_range(3.0, 12.0)
				guarda = sim.mondo_di_px(sim.centro)
			elif r < 0.8:
				meta = (f["casa"] as Vector2) + Vector2.from_angle(_caso.randf() * TAU) * 2.0
			else:
				meta = _punto_casa()
	f["meta"] = meta
	f["guarda"] = guarda


func _aggiorna_conti() -> void:
	var conti := {}
	for k in _corpi:
		conti[k] = 0
	for k in _attrezzi:
		conti[k] = 0
	var liv := "completo" if _complete else "leggero"
	for f in _figure:
		conti["%d:%s" % [f["modello"], liv]] += 1
		var a := String(MESTIERI[f["mestiere"]]["attrezzo"])
		if a != "":
			conti["%s:%s" % [a, "donna" if f["donna"] else "uomo"]] += 1
	for k in _corpi:
		(_corpi[k] as MultiMeshInstance3D).multimesh.instance_count = conti[k]
	for k in _attrezzi:
		(_attrezzi[k] as MultiMeshInstance3D).multimesh.instance_count = conti[k]
	_muovi(0.0)


func _process(delta: float) -> void:
	var cam: CameraIsometrica = vista.cam
	var visibili := cam == null or cam.dimensione < DIM_VISIBILI
	var complete := cam == null or cam.dimensione < DIM_COMPLETE
	if visibili != _visibili:
		_visibili = visibili
		for k in _corpi:
			(_corpi[k] as Node3D).visible = visibili and k.ends_with("completo") == _complete
		for k in _attrezzi:
			(_attrezzi[k] as Node3D).visible = visibili
	if complete != _complete:
		_complete = complete
		for k in _corpi:
			(_corpi[k] as Node3D).visible = _visibili and k.ends_with("completo") == complete
		_aggiorna_conti()
	if _visibili and not _figure.is_empty():
		_muovi(minf(delta, 0.1))


## Un passo di tempo per ogni figura e lo stato allo shader.
func _muovi(dt: float) -> void:
	var liv := "completo" if _complete else "leggero"
	var indici := {}
	for f in _figure:
		if dt > 0.0:
			_passo(f, dt)
		var pos: Vector2 = f["pos"]
		var t := Transform3D(Basis(Vector3.UP, deg_to_rad(float(f["verso"]))).scaled(Vector3.ONE * (0.96 + 0.08 * float(f["seme"]))),
			Vector3(pos.x, terreno.quota_mondo(pos.x, pos.y), pos.y))
		var mes: Dictionary = MESTIERI[f["mestiere"]]
		var att := String(mes["attrezzo"])
		var stato: String = f["stato"]
		var modo := 1 if stato == "va" else (2 if stato == "lavora" and int(mes["lavoro"]) >= 0 else (3 if stato == "parla" else 0))
		var anda := clampf(float(f["vel"]) / VELOCITA, 0.0, 1.9)
		var lavoro := maxi(int(mes["lavoro"]), 0)
		var dati := Color(float(f["fase"]), modo + anda * 0.5 if modo == 1 else float(modo), lavoro + (Asset.ATTREZZI.find(att) + 1) / 10.0 if att != "" else float(lavoro), float(f["seme"]))
		var colore := Color(1, 1, 1, 0.5) if f["lotto"] == evidenziata else Color.WHITE
		var chiave := "%d:%s" % [f["modello"], liv]
		var i: int = indici.get(chiave, 0)
		var mm := (_corpi[chiave] as MultiMeshInstance3D).multimesh
		if i < mm.instance_count:
			mm.set_instance_transform(i, t)
			mm.set_instance_color(i, colore)
			mm.set_instance_custom_data(i, dati)
		indici[chiave] = i + 1
		if att != "":
			var ca := "%s:%s" % [att, "donna" if f["donna"] else "uomo"]
			var j: int = indici.get(ca, 0)
			var ma := (_attrezzi[ca] as MultiMeshInstance3D).multimesh
			if j < ma.instance_count:
				ma.set_instance_transform(j, t)
				ma.set_instance_color(j, colore)
				ma.set_instance_custom_data(j, dati)
			indici[ca] = j + 1


## Una figura cammina verso la meta, poi lavora o sta; finito, sceglie un altro punto (ogni tanto
## torna a casa e chiacchiera).
func _passo(f: Dictionary, dt: float) -> void:
	var pos: Vector2 = f["pos"]
	var meta: Vector2 = f["meta"]
	var stato: String = f["stato"]
	var voluta := 0.0
	if stato == "va":
		var dist := pos.distance_to(meta)
		if dist < 0.3:
			var a_casa: bool = f["mestiere"] == "casa" or meta.distance_to(f["casa"]) < 3.0
			f["stato"] = ("parla" if _caso.randf() < 0.55 else "fermo") if a_casa or f["mestiere"] == "sacro" else "lavora"
			if f["mestiere"] == "sacro":
				f["stato"] = "parla" if _caso.randf() < 0.6 else "fermo"
			f["tempo"] = _caso.randf_range(15.0, 45.0) if f["stato"] == "lavora" else _caso.randf_range(8.0, 25.0)
		else:
			voluta = minf(VELOCITA, sqrt(2.0 * ACCELERAZIONE * maxf(dist - 0.2, 0.0)))
			var dir := (meta - pos) / dist
			_gira_verso(f, rad_to_deg(atan2(-dir.x, -dir.y)), dt)
			var diff := wrapf(rad_to_deg(atan2(-dir.x, -dir.y)) - float(f["verso"]), -180.0, 180.0)
			voluta *= clampf(cos(deg_to_rad(diff)), 0.15, 1.0)
	else:
		f["tempo"] = float(f["tempo"]) - dt
		var g: Vector2 = f["guarda"]
		if g != Vector2.INF and g.distance_to(pos) > 0.5:
			var d := g - pos
			_gira_verso(f, rad_to_deg(atan2(-d.x, -d.y)), dt)
		if float(f["tempo"]) <= 0.0:
			# Ogni tanto chi lavora torna a casa; poi riparte.
			if f["mestiere"] != "casa" and stato == "lavora" and _caso.randf() < 0.1:
				f["meta"] = f["casa"]
				f["guarda"] = Vector2.INF
			else:
				_nuovo_luogo(f)
			f["stato"] = "va"
	var vel := move_toward(float(f["vel"]), voluta, ACCELERAZIONE * dt)
	f["vel"] = vel
	if vel > 0.0:
		var r := deg_to_rad(float(f["verso"]))
		f["pos"] = pos + Vector2(-sin(r), -cos(r)) * vel * dt
		f["fase"] = fmod(float(f["fase"]) + vel * dt / Asset.passo_persona(f["donna"]) * TAU, TAU)


func _gira_verso(f: Dictionary, voluto: float, dt: float) -> void:
	var diff := wrapf(voluto - float(f["verso"]), -180.0, 180.0)
	f["verso"] = float(f["verso"]) + clampf(diff, -GIRATA * dt, GIRATA * dt)


## Per le verifiche e le foto.
func figure() -> Array:
	return _figure


func mestieri_contati() -> Dictionary:
	var c := {}
	for f in _figure:
		c[f["mestiere"]] = int(c.get(f["mestiere"], 0)) + 1
	return c
