extends SceneTree
## Verifiche sulla partita nella scena principale (simulazione + disegno + HUD), senza grafica:
## fondare dal comando, dissodare campi, far scorrere il tempo, rispondere alle scelte.
## Uso: godot --headless --path gioco -s res://test/verifica_partita.gd

var _errori := 0
var _s: Node
var _f := 0


func controlla(cond: bool, testo: String) -> void:
	print(("OK  " if cond else "ERRORE  ") + testo)
	if not cond:
		_errori += 1


func _initialize() -> void:
	_s = load("res://scene/principale.tscn").instantiate()
	root.add_child(_s)


## Animali del pascolo (26/11/2026, richieste di Fede): corpo e carte di pelo con i loro shader,
## livelli di dettaglio con lo zoom, movimento con accelerazione, soste a brucare e gregge che si
## sposta avviandosi uno dopo l'altro.
func _verifica_animali(p: Partita, sim: SimVillaggio) -> void:
	var vv: VistaVillaggio = p.vista
	if sim.capi < 40.0:
		sim.capi = 40.0
	vv.sincronizza()
	controlla(vv.animali_disegnati() > 0 and not vv._greggi.is_empty(), "animali e greggi sulla mappa (%d animali, %d greggi)" % [vv.animali_disegnati(), vv._greggi.size()])
	var buone := true
	for chiave in vv._mandria:
		for livello in ["completo", "leggero"]:
			var mesh: Mesh = (vv._mandria[chiave][livello] as MultiMeshInstance3D).multimesh.mesh
			if mesh == null or mesh.get_surface_count() != 2:
				buone = false
				continue
			var m0 := mesh.surface_get_material(0) as ShaderMaterial
			var m1 := mesh.surface_get_material(1) as ShaderMaterial
			if m0 == null or m1 == null or m0.shader != Asset.SHADER_ANIMALI or m1.shader != Asset.SHADER_CIOCCHE:
				buone = false
	controlla(buone, "ogni animale ha il corpo e le carte di pelo con i loro shader, in due livelli e tre manti")
	var manti := {}
	for a in vv._animali:
		manti[a["manto"]] = true
	controlla(manti.size() >= 2, "nel gregge si vedono manti diversi (%d)" % manti.size())
	# Livelli di dettaglio con lo zoom.
	var cam: CameraIsometrica = vv.cam
	controlla(cam != null, "la vista del villaggio conosce la camera (per i livelli di dettaglio)")
	if cam != null:
		var dim := cam.dimensione
		cam.dimensione = 100.0
		vv._aggiorna_livello_animali()
		var vicino: bool = (vv._mandria.values()[0]["completo"] as MultiMeshInstance3D).visible
		cam.dimensione = 600.0
		vv._aggiorna_livello_animali()
		var lontano: bool = (vv._mandria.values()[0]["leggero"] as MultiMeshInstance3D).visible
		cam.dimensione = dim
		vv._aggiorna_livello_animali()
		controlla(vicino and lontano, "da vicino i modelli completi, da lontano quelli leggeri")
	# Due minuti di pascolo: velocità entro il passo lungo, soste a brucare, zampe che seguono la strada.
	var vel_max := 0.0
	var camminano := 0
	var brucano := 0
	var numeri_ok := true
	var a0: Dictionary = vv._animali[0]
	# Si conta chi ha brucato e chi ha camminato in tutti i due minuti, non in un istante solo: la
	# partita della verifica parte ogni volta con un seme diverso (26/11/2026).
	var ha_brucato := {}
	for _k in 1200:
		vv._muovi_animali(0.1)
		for j in vv._animali.size():
			var a: Dictionary = vv._animali[j]
			var v := float(a["vel"])
			vel_max = maxf(vel_max, v)
			if is_nan(v) or is_nan((a["pos"] as Vector2).x) or is_nan(float(a["fase"])):
				numeri_ok = false
			if float(a["bruca"]) > 0.9:
				ha_brucato[j] = true
	brucano = ha_brucato.size()
	for a in vv._animali:
		if float(a["fase"]) != 0.0:
			camminano += 1
	controlla(numeri_ok and vel_max <= VistaVillaggio.VELOCITA_LUNGA + 0.001 and vel_max > 0.2, "gli animali camminano senza scatti (velocità massima %.2f m/s)" % vel_max)
	controlla(brucano > 0 and camminano > 0, "c'è chi bruca a testa bassa (%d) e chi cammina (%d)" % [brucano, camminano])
	# Un passo: la fase avanza di 2π ogni `passo` metri.
	var prima_pos: Vector2 = a0["pos"]
	var prima_fase := float(a0["fase"])
	a0["sosta"] = 0.0
	a0["ritardo"] = 0.0
	a0["lungo"] = false
	a0["vel"] = VistaVillaggio.VELOCITA_ANIMALI
	a0["meta"] = prima_pos + Vector2(-sin(deg_to_rad(float(a0["verso"]))), -cos(deg_to_rad(float(a0["verso"])))) * 20.0
	vv._passo_animale(a0, 0.1)
	var fatta := (a0["pos"] as Vector2).distance_to(prima_pos)
	var attesa := fatta / Asset.passo_animale(a0["specie"]) * TAU
	controlla(absf(wrapf(float(a0["fase"]) - prima_fase, 0.0, TAU) - attesa) < 0.01, "le zampe seguono la strada fatta (%.3f m, fase %.3f)" % [fatta, attesa])
	# Il gregge cambia posto: si avviano uno dopo l'altro, a passo lungo chi è lontano.
	vv._greggi[0]["cambio"] = 0.0
	vv._muovi_animali(0.01)
	var ritardi := []
	for a in vv._animali:
		if int(a["gregge"]) == 0:
			ritardi.append(float(a["ritardo"]))
	ritardi.sort()
	var in_fila: bool = ritardi.size() < 2 or ritardi[-1] - ritardi[0] > 0.5 * (ritardi.size() - 1)
	controlla(in_fila, "il gregge si sposta in fila sciolta (%d animali, partenze in %.1f s)" % [ritardi.size(), ritardi[-1] - ritardi[0] if not ritardi.is_empty() else 0.0])


## Specchietti in gioco (decisione di Fede del 26/11/2026): "Conseguenze" per ogni strumento
## del villaggio, con poche parole, e "Rapporti di forza" dal pannello del Consenso o con il tasto R.
func _verifica_specchietti(p: Partita, sim: SimVillaggio, h: Hud) -> void:
	var c := sim.mondo_di_px(sim.centro)
	var corte := true
	var complete := true
	var senza_numeri_strani := true
	for cmd in Partita.STRUMENTI:
		if cmd == "fonda":
			continue
		var d := p.conseguenze(cmd, c + Vector2(60, 40), p.raggio_strumento(cmd, 40.0))
		if d.is_empty() or not d.has("guadagna") or not d.has("perde"):
			complete = false
			print("   manca: ", cmd)
			continue
		for v in Hud.VOCI_CONSEGUENZE:
			var testo := String(d.get(v[0], ""))
			if testo.length() > Hud.MASSIMO_RIGA_CONSEGUENZE:
				corte = false
				print("   troppo lunga (%s, %s): %s" % [cmd, v[0], testo])
			if testo.contains("%"):
				senza_numeri_strani = false
	controlla(complete, "ogni strumento del villaggio dice chi ci guadagna e chi ci perde")
	controlla(corte, "nello specchietto una riga per voce, al massimo %d caratteri" % Hud.MASSIMO_RIGA_CONSEGUENZE)
	controlla(senza_numeri_strani, "niente percentuali nello specchietto")
	var dem := p.conseguenze("demolisci", sim.centro_lotto(sim.case[0]), 30.0) if not sim.case.is_empty() else {}
	controlla(String(dem.get("perde", "")).contains("Famiglie") and bool(dem.get("irreversibile", false)), "demolire le case: perdono le famiglie, ed è irreversibile (%s)" % dem.get("perde", ""))
	_s.punto_corrente = Vector3(c.x + 60, 0, c.y + 40)
	h.seleziona_comando("legnaia")
	p._chiave_conseguenze = []
	p.aggiorna_conseguenze()
	controlla(not h.conseguenze().is_empty() and h._pannello_conseguenze.visible, "scelto uno strumento, compare lo specchietto Conseguenze")
	p.apri_rapporti()
	controlla(h.focus_aperto() == "Consenso" and not h._pannello_conseguenze.visible, "il tasto R apre i rapporti di forza; lo specchietto dello strumento si fa da parte")
	var testi := ""
	for l in h._colonna_focus.find_children("*", "Label", true, false):
		testi += (l as Label).text + "\n"
	controlla(testi.contains("RAPPORTI DI FORZA") and testi.contains("Anziani") and testi.contains("TENSIONE") and testi.contains("SI MUOVE VERSO"), "i rapporti di forza dicono peso e umore dei gruppi, tensione e verso dove si va")
	var r := p.rapporti_di_forza()
	controlla((r["gruppi"] as Array).size() == (3 if sim.sacerdote_attivo else 2) and float(r["tensione"][0]) >= 0.0 and float(r["tensione"][0]) <= 1.0, "un gruppo per riga, il sacerdote solo quando ha voce")
	p.apri_rapporti()
	controlla(h.focus_aperto() == "", "di nuovo R e lo specchietto si chiude")
	h.seleziona_comando("")
	p.aggiorna_conseguenze()
	controlla(h.conseguenze().is_empty(), "senza strumento lo specchietto sparisce")
	controlla(Tutorial.ha("rapporti"), "c'è la scheda del tutorial per i rapporti di forza")
	# Gli assi dell'identità seguono le politiche, senza toccare le regole.
	var prima: float = sim.identita["terra"]
	var pol: String = sim.politica("raccolto")
	sim.politiche["raccolto"] = "famiglie"
	for k in 30:
		sim._aggiorna_identita()
	controlla(sim.identita["terra"] > prima and p.verso_identita().contains("terra alle famiglie"), "con il raccolto alle famiglie la città si muove verso la terra alle famiglie (%s)" % p.verso_identita())
	sim.politiche["raccolto"] = pol


## Popolazione visibile (voce 7 del todo, 26/11/2026): figure per i lavori veri, al massimo TETTO,
## che camminano senza scatti, con i modelli e lo shader delle persone; da lontano non si disegnano.
func _verifica_persone(p: Partita, sim: SimVillaggio) -> void:
	var vp: VistaPersone = p.vista.persone
	vp.sincronizza()
	var figure := vp.figure()
	var attese := mini(VistaPersone.TETTO, ceili(sim.pop / vp.quota))
	controlla(not figure.is_empty() and figure.size() == attese and figure.size() <= VistaPersone.TETTO, "una figura ogni %d persone (%d figure per %d abitanti)" % [vp.quota, figure.size(), roundi(sim.pop)])
	var buone := true
	for k in vp._corpi:
		var mesh: Mesh = (vp._corpi[k] as MultiMeshInstance3D).multimesh.mesh
		if mesh == null or (mesh.surface_get_material(0) as ShaderMaterial) == null or (mesh.surface_get_material(0) as ShaderMaterial).shader != Asset.SHADER_PERSONE:
			buone = false
	for k in vp._attrezzi:
		if (vp._attrezzi[k] as MultiMeshInstance3D).multimesh.mesh == null:
			buone = false
	controlla(buone, "sei persone in due livelli e cinque attrezzi, con lo shader delle persone")
	var conti := vp.mestieri_contati()
	var luoghi_ok := (int(conti.get("boscaiolo", 0)) == 0 or not vp._legnaie_attive().is_empty()) \
		and (int(conti.get("pescatore", 0)) == 0 or not sim.capanni.is_empty()) \
		and (int(conti.get("cacciatore", 0)) == 0 or not sim.poste.is_empty()) \
		and (int(conti.get("contadino", 0)) == 0 or not sim.campi.is_empty())
	controlla(luoghi_ok and int(conti.get("contadino", 0)) + int(conti.get("raccoglitrice", 0)) > 0, "ogni figura fa un lavoro che c'è davvero: %s" % conti)
	var vel_max := 0.0
	var numeri_ok := true
	var hanno_camminato := {}
	for _k in 600:
		vp._muovi(0.1)
		for j in figure.size():
			var f: Dictionary = figure[j]
			vel_max = maxf(vel_max, float(f["vel"]))
			if is_nan((f["pos"] as Vector2).x) or is_nan(float(f["fase"])):
				numeri_ok = false
			if f["stato"] == "va" and float(f["vel"]) > 0.3:
				hanno_camminato[j] = true
	controlla(numeri_ok and vel_max <= VistaPersone.VELOCITA + 0.001 and hanno_camminato.size() > 0, "un minuto di vita: le figure camminano a passo d'uomo (%d hanno camminato, velocità massima %.2f m/s)" % [hanno_camminato.size(), vel_max])
	var cam: CameraIsometrica = p.vista.cam
	var dim := cam.dimensione
	cam.dimensione = VistaPersone.DIM_VISIBILI + 100.0
	vp._process(0.016)
	var nascoste := true
	for k in vp._corpi:
		if (vp._corpi[k] as Node3D).visible:
			nascoste = false
	cam.dimensione = dim
	vp._process(0.016)
	controlla(nascoste, "da lontano le persone non si disegnano")


## Scheda della famiglia (decisione di Fede del 26/11/2026): ogni figura abita in una casa vera;
## un clic su una persona o su una casa apre la scheda giusta, con righe brevi e nomi dal luogo.
func _verifica_famiglia(p: Partita, sim: SimVillaggio) -> void:
	var vp: VistaPersone = p.vista.persone
	var tutte := true
	for f in vp.figure():
		if not sim.case.has(f["lotto"]):
			tutte = false
	controlla(tutte, "ogni figura abita in una casa vera")
	var nomi := p.nomi_famiglie()
	var diversi := {}
	for l in nomi:
		diversi[nomi[l]] = true
	controlla(nomi.size() == sim.case.size() and diversi.size() == nomi.size(), "un nome per ogni casa, senza doppioni (%d case, per esempio \"%s\")" % [sim.case.size(), nomi.values()[0] if not nomi.is_empty() else ""])
	controlla(not sim.nascita_case.is_empty() and sim.case.all(func(l: Vector2i) -> bool: return sim.nascita_case.has(l)), "ogni casa ricorda l'anno in cui è nata")
	# Clic su una persona: si apre la sua famiglia, e lei si illumina. La vista va sul villaggio.
	var ci := sim.mondo_di_px(sim.centro)
	_s.cam.vai_a(ci.x, ci.y)
	_s.cam.dimensione = 80.0
	_s.cam.dimensione_obiettivo = 80.0
	_s.cam.aggiorna()
	vp._process(0.016)
	var cam: Camera3D = _s.cam.camera
	var f: Dictionary = {}
	for g in vp.figure():
		var q: Vector2 = g["pos"]
		var a := cam.unproject_position(Vector3(q.x, _s.terreno.quota_mondo(q.x, q.y) + 0.85, q.y))
		if _s.get_viewport().get_visible_rect().has_point(a) and not cam.is_position_behind(Vector3(q.x, 0, q.y)):
			if vp.figura_sotto(cam, a) == g:
				f = g
				break
	if f.is_empty():
		controlla(false, "serve una persona sullo schermo per provare il clic")
	else:
		var q: Vector2 = f["pos"]
		var a := cam.unproject_position(Vector3(q.x, _s.terreno.quota_mondo(q.x, q.y) + 0.85, q.y))
		p.clic_sulla_mappa(a, Vector2i(-1, -1))
		controlla(p.famiglia == f["lotto"] and _s.hud.focus_aperto().begins_with("Famiglia ") and vp.evidenziata == f["lotto"], "un clic su una persona apre la scheda della sua famiglia (%s)" % _s.hud.focus_aperto())
	# Clic su una casa.
	var l: Vector2i = sim.case[sim.case.size() / 2]
	p.clic_sulla_mappa(Vector2(-1000, -1000), l)
	var d := p.dati_famiglia(l)
	controlla(p.famiglia == l and _s.hud.focus_aperto() == String(d["titolo"]), "un clic su una casa apre la sua famiglia")
	var corte := String(d["descrizione"]).length() <= Partita.MASSIMO_RIGA_FAMIGLIA
	var etichette: Array = []
	for r in d["famiglia"]:
		etichette.append(r[0])
		if String(r[1]).length() > Partita.MASSIMO_RIGA_FAMIGLIA - 12 or String(r[2]) == "":
			corte = false
	controlla(corte and etichette.has("Lavoro") and etichette.has("Ha") and etichette.has("Vorrebbe") and (d["umore"] as Array).size() == 2, "la scheda ha righe brevi, ognuna con il suo perché: %s" % [d["famiglia"]])
	var stampa := "%s · %s · %s" % [d["titolo"], d["valore"], d["descrizione"]]
	for r in d["famiglia"]:
		stampa += "\n      %s: %s" % [r[0], r[1]]
	print("      " + stampa)
	# Un clic sul prato chiude la scheda.
	p.clic_sulla_mappa(Vector2(-1000, -1000), Vector2i(-5, -5))
	controlla(p.famiglia == Partita.NESSUNA_CASA and _s.hud.focus_aperto() == "" and vp.evidenziata == VistaPersone.NESSUNA, "un clic altrove chiude la scheda")


## Campo stanco visibile (proposta confermata da Fede il 26/11/2026): la stanchezza e il maggese
## arrivano allo shader del terreno.
func _verifica_campo_stanco(p: Partita, sim: SimVillaggio) -> void:
	if sim.campi.is_empty():
		controlla(false, "servono campi per provare il campo stanco")
		return
	var i: int = sim.campi[0]
	var prima = sim.stanchezza.get(i)
	sim.stanchezza[i] = SimVillaggio.ANNI_PRIMA_STANCHEZZA + SimVillaggio.ANNI_STANCHEZZA
	p.vista.sincronizza()
	var mt: ShaderMaterial = _s.terreno.materiale
	controlla(mt.get_shader_parameter("stanchezza_campi") != null and p.vista.stanchezza_disegnata(i) > 0.95, "un campo stanchissimo si vede stanco sulla mappa (%.2f)" % p.vista.stanchezza_disegnata(i))
	sim.stanchezza.erase(i)
	p.vista.sincronizza()
	controlla(p.vista.stanchezza_disegnata(i) == 0.0, "riposato, il campo torna come prima")
	if prima != null:
		sim.stanchezza[i] = prima
		p.vista.sincronizza()


func _destro(premuto: bool, pos: Vector2) -> InputEventMouseButton:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_RIGHT
	ev.pressed = premuto
	ev.position = pos
	return ev


## Clicca la prima opzione della finestra di scelta aperta (o quella col testo indicato).
func _rispondi(h: Hud, testo := "") -> bool:
	if not h.modale_aperta():
		return false
	# Riquadro del tutorial: si va avanti con Continua.
	var avanti := h._modale.find_child("Continua", true, false) as Button
	if avanti != null and testo == "":
		avanti.emit_signal("pressed")
		return true
	for b in h._modale.find_children("*", "Button", true, false):
		if (testo == "" and (b as Button).text != "Nuova partita") or (b as Button).text == testo:
			(b as Button).emit_signal("pressed")
			return true
	return false


func _process(_d: float) -> bool:
	_f += 1
	if _f < 3:
		return false
	var p: Partita = _s.partita
	var h: Hud = _s.hud
	var sim := p.sim
	controlla(p != null and h.comando() == "fonda", "la partita comincia con lo strumento Fondare")
	# Tutorial (decisione di Fede del 26/11/2026): la partita comincia con il riquadro della
	# fondazione e il tempo fermo; "Cosa fa…?" apre la spiegazione; Continua va avanti.
	controlla(h.modale_aperta() and h._modale.find_child("Tutorial", true, false) != null and sim.tutorial_in_attesa(), "la partita comincia con il tutorial della fondazione, a tempo fermo")
	var dom := h._modale.find_child("Domanda", true, false) as Button
	var det := h._modale.find_child("Dettaglio", true, false) as Label
	controlla(dom != null and det != null and not det.visible, "la spiegazione completa è chiusa all'inizio")
	if dom != null:
		dom.emit_signal("pressed")
		controlla(det.visible and det.text.length() > 80, "\"%s\" apre la spiegazione" % dom.text.strip_edges())
	(h._modale.find_child("Continua", true, false) as Button).emit_signal("pressed")
	controlla(not sim.in_attesa() and sim.tutorial_attivi and not h.modale_aperta(), "Continua chiude il riquadro e i tutorial restano accesi")
	# Modalità fondazione (Fede): la lettura del sito prende il posto della descrizione e dei menù.
	p.aggiorna_modalita()
	var sito0: Vector2 = _s.dati.mondo_da_pixel(_s.dati.siti[0]["px"])
	p.leggi_sito(Vector3(sito0.x, 0, sito0.y))
	controlla(h.lettura_sito_visibile() and not (h._blocchi["costruzione"]["pannello"] as Control).visible and h._titolo_sito.text.contains("Sito 1"), "in fondazione la fascia legge il sito: " + h._titolo_sito.text)
	controlla((h._voci_sito["acqua"]["valore"] as Label).text != "" and (h._voci_sito["bosco"]["valore"] as Label).text != "", "gli indicatori del sito hanno un valore")
	var sito: Vector2 = _s.dati.mondo_da_pixel(_s.dati.siti[0]["px"])
	_s.punto_corrente = Vector3(sito.x, 0, sito.y)
	_s.applica_strumento()
	controlla(h.modale_aperta(), "fondare chiede conferma mostrando la valutazione del sito")
	_rispondi(h, "Fonda qui")
	controlla(sim.fondato and h.comando() == "zona", "fondato; si passa alla zona agricola")
	# Tutorial della fondazione: gli strumenti nuovi, come pagine dello stesso riquadro.
	var pagine := sim.decisioni.filter(func(d: Dictionary) -> bool: return d["tipo"] == "tutorial")
	controlla(pagine.size() == Tutorial.DOPO_FONDAZIONE.size() and int(pagine[0]["pagine"]) == pagine.size(), "dopo la fondazione i tutorial degli strumenti (%d pagine)" % pagine.size())
	p._process(0.0)
	controlla(h.modale_aperta() and h._modale.find_child("Tutorial", true, false) != null, "il primo riquadro si apre: %s" % (pagine[0]["titolo"] if not pagine.is_empty() else ""))
	(h._modale.find_child("Salta", true, false) as Button).button_pressed = true
	var avvisi_prima := sim.avvisi.size()
	(h._modale.find_child("Continua", true, false) as Button).emit_signal("pressed")
	controlla(not sim.tutorial_attivi and not sim.in_attesa() and sim.avvisi.size() == avvisi_prima + pagine.size() - 1, "\"Salta i tutorial\": i riquadri rimasti diventano notifiche grigie (%d)" % (sim.avvisi.size() - avvisi_prima))
	sim.tutorial(["granaio"], "prova")
	controlla(not sim.in_attesa(), "saltati, per il resto della partita le novità non fermano il gioco")
	controlla(not h.lettura_sito_visibile() and (h._blocchi["costruzione"]["pannello"] as Control).visible, "dopo la fondazione tornano descrizione e menù")
	controlla(p.vista.numero_case() == sim.case.size() and sim.case.size() == 6, "le case della simulazione sono disegnate (%d)" % p.vista.numero_case())
	controlla(_s.uso.stato(sito.x, sito.y) == UsoSuolo.COSTRUITO, "terra battuta al centro del villaggio")
	# Zona agricola a ovest: dentro, le famiglie dissodano da sole i campi che servono.
	_s.raggio_pennello = 150.0
	_s.punto_corrente = Vector3(sito.x - 250.0, 0, sito.y)
	_s.applica_strumento()
	controlla(sim.zona.size() > 20 and h._messaggio.text.contains("Zona agricola"), "la zona agricola si disegna (%d punti): %s" % [sim.zona.size(), h._messaggio.text])
	# Pennello: tenendo premuto e trascinando si continua a stendere la zona.
	var prima_z := sim.zona.size()
	var ev_giu := InputEventMouseButton.new()
	ev_giu.button_index = MOUSE_BUTTON_LEFT
	ev_giu.pressed = true
	_s._pennellando = true
	p.inizia_pennellata()
	for k in 4:
		_s.punto_corrente = Vector3(sito.x - 250.0, 0, sito.y + 60.0 + k * 80.0)
		_s.applica_strumento()
	_s._pennellando = false
	controlla(sim.zona.size() > prima_z and h._messaggio.text.contains("Tieni premuto"), "trascinando, la zona si stende come un pennello (%d → %d)" % [prima_z, sim.zona.size()])
	# La zona si vede solo con Zona agricola o Campo (segnalato da Fede: restava accesa togliendo
	# lo strumento, o col puntatore fuori dal terreno).
	var mat: ShaderMaterial = _s.terreno.materiale
	_s._aggiorna_pennello()
	controlla(float(mat.get_shader_parameter("mostra_zona")) > 0.5, "con Zona agricola la zona si vede")
	h.seleziona_comando("")
	_s._aggiorna_pennello()
	controlla(float(mat.get_shader_parameter("mostra_zona")) < 0.5, "senza strumento la zona non si vede più")
	h.seleziona_comando("zona")
	_s.punto_corrente = null
	_s._aggiorna_pennello()
	controlla(float(mat.get_shader_parameter("mostra_zona")) > 0.5, "con Zona agricola la zona resta visibile col puntatore fuori dal terreno")
	h.seleziona_comando("sentiero")
	_s._aggiorna_pennello()
	controlla(float(mat.get_shader_parameter("mostra_zona")) < 0.5, "col puntatore fuori dal terreno e un altro strumento la zona si spegne")
	# Tasto destro (Fede): un clic secco deseleziona come Esc; trascinato sposta la vista e basta.
	h.seleziona_comando("zona")
	_s._unhandled_input(_destro(true, Vector2(400, 300)))
	_s._unhandled_input(_destro(false, Vector2(460, 330)))
	controlla(h.comando() == "zona", "trascinare col tasto destro non toglie lo strumento")
	_s._unhandled_input(_destro(true, Vector2(400, 300)))
	_s._unhandled_input(_destro(false, Vector2(401, 301)))
	controlla(h.comando() == "" and float(mat.get_shader_parameter("mostra_zona")) < 0.5, "un clic destro toglie lo strumento come Esc, e la zona si spegne")
	_s.punto_corrente = Vector3(sito.x, 0, sito.y)
	h.seleziona_comando("campi")
	# Campi a est del centro, entro il raggio.
	_s.raggio_pennello = 120.0
	_s.punto_corrente = Vector3(sito.x + 300.0, 0, sito.y)
	_s.applica_strumento()
	controlla(sim.campi.size() > 10, "un clic dissoda i campi nel cerchio (%d)" % sim.campi.size())
	var f := sim.mondo_di_px(sim.px_di(sim.campi[0]))
	controlla(_s.uso.stato(f.x, f.y) == UsoSuolo.COLTIVATO, "i campi sono suolo coltivato")
	# Sovrapporre il cerchio a campi che ci sono già ne aggiunge, non li abbandona (bug segnalato da Fede).
	var n_campi := sim.campi.size()
	_s.punto_corrente = Vector3(sito.x + 380.0, 0, sito.y)
	_s.applica_strumento()
	controlla(sim.campi.size() >= n_campi and not h._messaggio.text.contains("bbandon"), "un clic sopra campi esistenti non li abbandona (%d → %d)" % [n_campi, sim.campi.size()])
	# Sentiero verso nord, poi campi attorno: niente corridoio d'erba a scalini lungo il sentiero
	# (segnalato da Fede): accanto alla linea del sentiero il campo arriva fino al nastro.
	var c0 := sim.mondo_di_px(sim.centro)
	# Sentieri come in Cities (decisione di Fede): un clic dove comincia, uno dove finisce.
	h.seleziona_comando("sentiero")
	_s.punto_corrente = Vector3(c0.x, 0, c0.y)
	_s.applica_strumento()
	controlla(p.inizio_sentiero == sim.centro and sim.sentieri.is_empty(), "il primo clic fissa l'inizio del sentiero")
	_s.punto_corrente = Vector3(c0.x, 0, c0.y - 480.0)
	_s._aggiorna_pennello()
	controlla(p.vista._anteprima != null and p.vista._anteprima.visible and p.vista._etichetta.text.contains("480 m"), "anteprima del sentiero con la lunghezza: " + (p.vista._etichetta.text if p.vista._etichetta else ""))
	_s.applica_strumento()
	controlla(sim.sentieri.size() == 12 and p.inizio_sentiero == sim.px_da_mondo(c0.x, c0.y - 480.0), "il secondo clic traccia il sentiero e si continua da lì")
	var ev_esc := InputEventKey.new()
	ev_esc.keycode = KEY_ESCAPE
	ev_esc.pressed = true
	_s._unhandled_input(ev_esc)
	controlla(p.inizio_sentiero.x < 0 and h.comando() == "sentiero", "Esc chiude la catena e lo strumento resta")
	# Un tratto libero, lontano e staccato dalla rete, si costruisce ma non porta i campi lontano.
	var lontano := sim.centro + Vector2i(34, 0)
	var n_s := sim.sentieri.size()
	controlla(sim.traccia_sentiero_da(lontano, lontano + Vector2i(0, 6)) == "" and sim.sentieri.size() > n_s and not sim.collegato(lontano), "un sentiero libero si costruisce anche staccato dalla rete")
	controlla(not sim.servito(sim.px(lontano + Vector2i(1, 1))), "un campo lungo un sentiero staccato non è servito")
	controlla(not (h._righe_comandi["fonda"] as Control).visible and not (h._menu["insediamento"]["scheda"] as Control).visible, "dopo la fondazione il tasto Fondare sparisce")
	h.seleziona_comando("sentiero")
	controlla(h._opzioni.visible and (h._righe_azioni["collega_rete"] as Control).visible and not h._menu_di.has("collega_rete"), "Collega alla rete è un'opzione dello strumento Sentiero")
	h.seleziona_comando("campi")
	controlla(not h._opzioni.visible, "le opzioni del sentiero spariscono con un altro strumento")
	# Collega alla rete: il sentiero parte dal punto più vicino della rete.
	h.seleziona_comando("sentiero")
	p._azione("collega_rete")
	_s.punto_corrente = Vector3(c0.x + 400.0, 0, c0.y - 120.0)
	_s.applica_strumento()
	controlla(p.collega_rete and sim.collegato(sim.px_da_mondo(c0.x + 400.0, c0.y - 120.0)), "con Collega alla rete un clic traccia un sentiero collegato")
	p._azione("collega_rete")
	h.seleziona_comando("campi")
	_s.punto_corrente = Vector3(c0.x, 0, c0.y - 300.0)
	_s.applica_strumento()
	var lungo_sentiero := 0
	var coltivate := 0
	for dz in range(-60, 61, 20):
		for dx in [-13.0, 13.0]:
			lungo_sentiero += 1
			if _s.uso.stato(c0.x + dx, c0.y - 300.0 + dz) == UsoSuolo.COLTIVATO:
				coltivate += 1
	controlla(sim.sentieri.size() > 0 and coltivate == lungo_sentiero, "i campi arrivano fino al sentiero, senza corridoio d'erba (%d su %d)" % [coltivate, lungo_sentiero])
	# Legnaia (decisione di Fede del 25/11/2026): si costruisce dallo strumento; gli alberi che i
	# boscaioli abbattono spariscono dalla mappa.
	var cg := RandomNumberGenerator.new()
	cg.seed = 9
	AiutiGiocatori.costruisci_legnaia(sim, cg, 1.0)
	controlla(sim.legnaie.size() == 1, "si costruisce la legnaia")
	# Capanno da pesca e Posta di caccia (decisioni di Fede del 25/11/2026): dallo strumento, con
	# l'aggancio alla riva e al margine; il modello si disegna e gli alberi attorno spariscono.
	var cc := sim.mondo_di_px(sim.centro)
	for voce in [["capanno", sim.capanni], ["posta", sim.poste]]:
		var cmd: String = voce[0]
		var punto := Vector2.INF
		for r in range(0, 1000, 40):
			for k in 24:
				var q := cc + Vector2.from_angle(TAU * k / 24.0) * r
				if punto == Vector2.INF and p.posa_edificio(cmd, q)["motivo"] == "":
					punto = q
		if punto == Vector2.INF:
			print("   (%s: nessun punto adatto entro 1 km da questo sito)" % cmd)
			continue
		h.seleziona_comando(cmd)
		_s.punto_corrente = Vector3(punto.x, 0, punto.y)
		_s._aggiorna_pennello()
		controlla(p.vista._etichetta.visible == false or p.vista._etichetta.text == "", "%s: l'anteprima agganciata è valida (niente motivo)" % cmd)
		_s.applica_strumento()
		var elenco: Array = voce[1]
		controlla(elenco.size() == 1, "%s: si costruisce dallo strumento" % cmd)
		if elenco.is_empty():
			continue
		var e: Dictionary = elenco[0]
		var pe: Vector2 = e["punto"]
		controlla(p.vista._edifici.has(pe) and _s.uso.stato(pe.x, pe.y) != UsoSuolo.NATURALE, "%s: il modello è sulla mappa e attorno non ci sono alberi" % cmd)
		# Cantiere (decisione di Fede del 25/11/2026 sera): scheletro e barra finché si costruisce.
		controlla(String(p.vista._edifici[pe]["modello"]).begins_with("cantiere_") and p.vista._edifici[pe]["barra"] != null, "%s: in costruzione si vede lo scheletro con la barra" % cmd)
	# Lontano dall'acqua l'anteprima del capanno è rossa e dice perché.
	h.seleziona_comando("capanno")
	var asciutto := Vector2.INF
	for k in 24:
		var q := cc + Vector2.from_angle(TAU * k / 24.0) * 300.0
		if asciutto == Vector2.INF and sim.dati.distanza_riva(q.x, q.y) > 100.0:
			asciutto = q
	if asciutto != Vector2.INF:
		_s.punto_corrente = Vector3(asciutto.x, 0, asciutto.y)
		_s._aggiorna_pennello()
		controlla(p.vista._etichetta.visible and p.vista._etichetta.text.begins_with("Serve la riva"), "lontano dall'acqua l'anteprima del capanno dice perché: «%s»" % p.vista._etichetta.text)
	h.seleziona_comando("")
	# Tempo: 15 anni al secondo per qualche secondo simulato, rispondendo alle scelte.
	p.imposta_velocita(3)
	var anno0 := sim.anno
	for k in 40:
		p._process(0.5)
		_rispondi(h)
		# Alcune scelte portano alla mappa e mettono in pausa (la prima piena grande): si riparte.
		if p.velocita == 0:
			p.imposta_velocita(3)
		# Come farebbe un giocatore: ogni tanto nuovi campi attorno al villaggio.
		if k % 10 == 0 and sim.fondato:
			var c := sim.mondo_di_px(sim.centro)
			for a in 8:
				_s.punto_corrente = Vector3(c.x + cos(a * 0.8) * 350.0, 0, c.y + sin(a * 0.8) * 350.0)
				_s.applica_strumento()
	controlla(sim.anno > anno0 + 150, "il tempo scorre (%s)" % SimVillaggio.anno_testo(sim.anno))
	var finiti := true
	for e in sim.poste + sim.capanni:
		var m: String = p.vista._edifici[e["punto"]]["modello"]
		if int(e["cantiere"]) <= 0 and m.begins_with("cantiere_"):
			finiti = false
	var in_cantiere := (sim.poste + sim.capanni + sim.legnaie).filter(func(e: Dictionary) -> bool: return int(e["cantiere"]) > 0).size() + (1 if sim.cantiere_granaio > 0 else 0)
	controlla(finiti and p.vista.barre_aperte() == in_cantiere, "finito il cantiere compare l'edificio e la barra sparisce (%d barre, %d cantieri)" % [p.vista.barre_aperte(), in_cantiere])
	# Luogo sacro e bosco sacro dagli strumenti (decisioni di Fede del 24–25/11/2026).
	if sim.fondato:
		sim.pop = maxf(sim.pop, 160.0)
		sim._aggiorna_tappa()
		sim.legna = maxf(sim.legna, 60.0)
		var cs := sim.mondo_di_px(sim.centro)
		h.seleziona_comando("luogo_sacro")
		for k in 16:
			if sim.luogo_sacro.x < 0:
				_s.punto_corrente = Vector3(cs.x + cos(TAU * k / 16.0) * 150.0, 0, cs.y + sin(TAU * k / 16.0) * 150.0)
				_s.applica_strumento()
		controlla(sim.luogo_sacro.x >= 0 and String(p.vista._edifici[sim.luogo_sacro]["modello"]) == "cantiere_luogo_sacro", "luogo sacro dallo strumento, con il suo scheletro")
		h.seleziona_comando("bosco_sacro")
		for r in range(100, 1000, 40):
			for k in 16:
				if sim.bosco_sacro.is_empty():
					var q := Vector2(cs.x + cos(TAU * k / 16.0) * r, cs.y + sin(TAU * k / 16.0) * r)
					if sim.motivo_bosco_sacro(sim.px_da_mondo(q.x, q.y)) == "":
						_s.punto_corrente = Vector3(q.x, 0, q.y)
						p.inizia_pennellata()
						_s.applica_strumento()
		controlla(not sim.bosco_sacro.is_empty() and p.vista._immagine_sacro != null, "bosco sacro a pennello (%s ha)" % String.num(sim.ettari_bosco_sacro(), 1))
		# Pascolo a pennello e opzione Togli (decisioni di Fede del 25/11/2026).
		h.seleziona_comando("pascolo")
		var punto_pa := Vector2.INF
		for r in range(60, 800, 40):
			for k in 16:
				var q := Vector2(cs.x + cos(TAU * k / 16.0) * r, cs.y + sin(TAU * k / 16.0) * r)
				if punto_pa == Vector2.INF and sim.motivo_pascolo(sim.px_da_mondo(q.x, q.y)) == "":
					punto_pa = q
		_s.punto_corrente = Vector3(punto_pa.x, 0, punto_pa.y)
		p.inizia_pennellata()
		_s.applica_strumento()
		var campi_prima := sim.campi.size()
		controlla(not sim.pascolo.is_empty() and p.vista._immagine_pascolo != null, "pascolo a pennello (%d pixel)" % sim.pascolo.size())
		_verifica_animali(p, sim)
		_verifica_campo_stanco(p, sim)
		_verifica_persone(p, sim)
		_verifica_famiglia(p, sim)
		p._azione("togli_pascolo")
		p.inizia_pennellata()
		_s.applica_strumento()
		controlla(sim.pascolo.is_empty() and sim.campi.size() == campi_prima, "con Togli il pennello toglie il pascolo e lascia i campi")
		p._azione("togli_pascolo")
		h.seleziona_comando("")
	var tagliati_visibili := 0
	for i in sim.tagliati:
		if sim.dati.tipo[i] == MappaDati.PALUDE:
			continue
		var w := sim.mondo_di_px(sim.px_di(i))
		if _s.uso.stato(w.x, w.y) != UsoSuolo.NATURALE:
			tagliati_visibili += 1
	controlla(sim.tagliati.is_empty() or tagliati_visibili > 0, "gli alberi abbattuti dalla legnaia spariscono dalla mappa (%d su %d)" % [tagliati_visibili, sim.tagliati.size()])
	controlla(p.vista.numero_case() == sim.case.size(), "case disegnate allineate alla simulazione (%d)" % sim.case.size())
	# Mappe tematiche della partita (voce 8 del todo, 25/11/2026 sera): 6 Caccia e pesca, 7 Abitato e
	# contado, 8 Memoria del suolo (indici 5, 6, 7).
	var mt: ShaderMaterial = _s.terreno.materiale
	controlla(h._righe_mappe.size() == 8 and Hud.LEGENDE.size() == 8 and Hud.COLORI_MAPPE.size() == 8, "otto mappe tematiche con bollino e legenda")
	_s.imposta_modo(5)
	var scorte: ImageTexture = mt.get_shader_parameter("scorte")
	var cerchi: Array = mt.get_shader_parameter("cerchi_risorse")
	controlla(scorte != null and cerchi.size() == 16 and (cerchi[0] as Vector4).z > 0.0 == not (sim.poste + sim.capanni).is_empty(), "caccia e pesca: scorte per riquadro e cerchi di poste e capanni")
	var scarsa := false
	for cs in sim.scorta_selvaggina:
		if p._immagine_scorte.get_pixel(cs.x, cs.y).r < 0.99:
			scarsa = true
	controlla(sim.scorta_selvaggina.is_empty() or scarsa, "caccia e pesca: la selvaggina cacciata si vede più scarsa")
	_s.imposta_modo(6)
	var ab: Vector4 = mt.get_shader_parameter("abitato")
	controlla(ab.z > 0.0 and ab.w >= ab.z and is_equal_approx(ab.w, sim.raggio_contado()), "abitato e contado: abitato (%d m) dentro il contado (%d m)" % [roundi(ab.z), roundi(ab.w)])
	_s.imposta_modo(7)
	var ex_bosco := 0
	for i in sim.tagliati:
		var w := sim.mondo_di_px(sim.px_di(i))
		var cu: Vector2i = _s.uso.cella(w.x, w.y)
		if _s.uso.immagine_memoria.get_pixel(cu.x, cu.y).r > 0.5:
			ex_bosco += 1
	controlla(mt.get_shader_parameter("memoria_suolo") != null and (sim.tagliati.is_empty() or ex_bosco > 0), "memoria del suolo: il bosco tagliato resta nella memoria (%d)" % ex_bosco)
	_s.imposta_modo(0)
	print("   %d abitanti, %d campi, %d case, abbandoni %d" % [roundi(sim.pop), sim.campi.size(), sim.case.size(), sim.stat["abbandoni"]])
	controlla(sim.fondato and sim.stat["abbandoni"] == 0, "con i campi il villaggio vive")
	controlla((h._valori_indicatori["Densità"] as Label).get_parent().tooltip_text.contains("ettaro"), "la densità spiega al passaggio cosa vuol dire ab/ha")
	# Fonti di cibo nel blocco Info (Fede): da dove si attinge e quanto si usa di ciò che c'è.
	controlla(h._sezione_fonti.visible and h._fonti_info.has("agricoltura") and h._fonti_info.has("caccia") and h._fonti_info.has("pesca")
		and (h._fonti_info["caccia"]["valore"] as Label).text.contains("/"), "le fonti di cibo si leggono nel blocco Info: caccia " + (h._fonti_info["caccia"]["valore"] as Label).text)
	# Spegnere la caccia dalle politiche: la caccia non dà più cibo, almeno una fonte resta accesa.
	h.interruttore_scelto.emit("fonti", "caccia", false)
	controlla(not sim.fonti["caccia"] and not h.interruttore("fonti", "caccia") and (h._fonti_info["caccia"]["valore"] as Label).text == "spenta", "la caccia si spegne dalle politiche e il blocco Info lo mostra")
	h.interruttore_scelto.emit("fonti", "pesca", false)
	h.interruttore_scelto.emit("fonti", "agricoltura", false)
	controlla(sim.fonti["agricoltura"], "almeno una fonte di cibo resta accesa")
	h.interruttore_scelto.emit("fonti", "caccia", true)
	h.interruttore_scelto.emit("fonti", "pesca", true)
	h.fonte_scelta.emit("caccia")
	controlla(h.politiche_aperte(), "un clic su una fonte apre le politiche")
	h.apri_politiche(false)
	controlla(h._valori_indicatori.has("Popolazione") and h._valori_indicatori["Popolazione"].text == str(roundi(sim.pop)), "gli indicatori seguono la simulazione")
	controlla(h._cronaca.text != "—", "la cronaca si riempie")
	# Blocco Info a larghezza fissa (segnalato da Fede: le colonne ballavano quando crescevano i
	# numeri): anche con valori lunghi non si allarga, e le cifre hanno tutte la stessa larghezza.
	var info := h._fascia.get_child(0) as Control
	h.imposta_indicatori([["Cibo", "88888 / 88888 l'anno", false], ["Popolazione", "88888", false]])
	controlla(is_equal_approx(info.get_combined_minimum_size().x, Hud.LARGHEZZA_INFO), "il blocco Info non si allarga con valori lunghi (%d px)" % roundi(info.get_combined_minimum_size().x))
	var font_val := (h._valori_indicatori["Cibo"] as Label).get_theme_font("font") as FontVariation
	controlla(font_val != null and font_val.opentype_features.size() == 1, "i valori del blocco Info hanno le cifre a larghezza fissa")
	p.aggiorna_hud()
	# Demolisci: le case nel cerchio spariscono e per un po' non rinascono lì.
	var prima := sim.case.size()
	if prima > 0:
		var w := sim.centro_lotto(sim.case[0])
		h.seleziona_comando("demolisci")
		_s.raggio_pennello = 15.0
		_s.punto_corrente = Vector3(w.x, 0, w.y)
		_s.applica_strumento()
		var l := sim.lotto_da_mondo(w.x, w.y)
		controlla(not sim.case.has(l) and sim.macerie.has(l) and h._messaggio.text.contains("case"), "Demolisci toglie la casa e il lotto resta libero per un po': " + h._messaggio.text)
		controlla(p.vista.numero_case() == sim.case.size(), "la casa demolita sparisce anche dalla mappa")
	p.imposta_velocita(0)
	var anno1 := sim.anno
	p._process(1.0)
	controlla(sim.anno == anno1, "in pausa il tempo è fermo")
	# Notifiche discrete: non fermano il tempo.
	var d_prima := sim.decisioni.size()
	sim._notifica("Prova di notifica", false, c0)
	p._process(0.01)
	controlla(h.notifiche().has("Prova di notifica") and sim.decisioni.size() == d_prima and not h.modale_aperta(), "le notifiche compaiono senza fermare il gioco")
	# Pannelli di focus (decisione di Fede del 25/11/2026): un clic su un indicatore apre il suo
	# pannello, con le parti, il perché e l'andamento; si aggiorna con il tempo; Esc lo chiude.
	p.aggiorna_hud()
	h.indicatore_scelto.emit("Abbondanza")
	controlla(h.focus_aperto() == "Abbondanza" and not h.modale_aperta(), "un clic su Abbondanza apre il suo pannello di focus senza fermare il gioco")
	var testi := ""
	for l in h._colonna_focus.find_children("*", "Label", true, false):
		testi += (l as Label).text + "\n"
	controlla(testi.contains("Cibo che avanza") and testi.contains("PERCHÉ"), "il pannello dice di cosa è fatta l'abbondanza e perché")
	for nome in ["Cibo", "Salute", "Consenso", "Legna", "Popolazione"]:
		h.indicatore_scelto.emit(nome)
		controlla(h.focus_aperto() == nome and p.dati_focus(nome).has("valore"), "pannello di focus per %s" % nome)
	_s.annulla()
	controlla(h.focus_aperto() == "", "Esc chiude il pannello di focus")
	_verifica_specchietti(p, sim, h)
	# Tappe: il granaio è chiuso finché non si raggiunge la sua tappa.
	controlla(sim.sbloccato("granaio") or p.scena.hud.find_children("*", "Button", true, false).size() > 0, "il granaio segue le tappe")
	print("Verifica completata: " + ("nessun errore" if _errori == 0 else "%d errori" % _errori))
	quit(1 if _errori > 0 else 0)
	return true
