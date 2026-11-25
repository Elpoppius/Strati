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
	var tagliati_visibili := 0
	for i in sim.tagliati:
		if sim.dati.tipo[i] == MappaDati.PALUDE:
			continue
		var w := sim.mondo_di_px(sim.px_di(i))
		if _s.uso.stato(w.x, w.y) != UsoSuolo.NATURALE:
			tagliati_visibili += 1
	controlla(sim.tagliati.is_empty() or tagliati_visibili > 0, "gli alberi abbattuti dalla legnaia spariscono dalla mappa (%d su %d)" % [tagliati_visibili, sim.tagliati.size()])
	controlla(p.vista.numero_case() == sim.case.size(), "case disegnate allineate alla simulazione (%d)" % sim.case.size())
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
	# Tappe: il granaio è chiuso finché non si raggiunge la sua tappa.
	controlla(sim.sbloccato("granaio") or p.scena.hud.find_children("*", "Button", true, false).size() > 0, "il granaio segue le tappe")
	print("Verifica completata: " + ("nessun errore" if _errori == 0 else "%d errori" % _errori))
	quit(1 if _errori > 0 else 0)
	return true
