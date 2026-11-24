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
	var sito: Vector2 = _s.dati.mondo_da_pixel(_s.dati.siti[0]["px"])
	_s.punto_corrente = Vector3(sito.x, 0, sito.y)
	_s.applica_strumento()
	controlla(h.modale_aperta(), "fondare chiede conferma mostrando la valutazione del sito")
	_rispondi(h, "Fonda qui")
	controlla(sim.fondato and h.comando() == "zona", "fondato; si passa alla zona agricola")
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
	# Tempo: 15 anni al secondo per qualche secondo simulato, rispondendo alle scelte.
	p.imposta_velocita(3)
	var anno0 := sim.anno
	for k in 40:
		p._process(0.5)
		_rispondi(h)
		# Come farebbe un giocatore: ogni tanto nuovi campi attorno al villaggio.
		if k % 10 == 0 and sim.fondato:
			var c := sim.mondo_di_px(sim.centro)
			for a in 8:
				_s.punto_corrente = Vector3(c.x + cos(a * 0.8) * 350.0, 0, c.y + sin(a * 0.8) * 350.0)
				_s.applica_strumento()
	controlla(sim.anno > anno0 + 150, "il tempo scorre (%s)" % SimVillaggio.anno_testo(sim.anno))
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
	print("Verifica completata: " + ("nessun errore" if _errori == 0 else "%d errori" % _errori))
	quit(1 if _errori > 0 else 0)
	return true
