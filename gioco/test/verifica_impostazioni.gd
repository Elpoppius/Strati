extends SceneTree
## Verifiche delle impostazioni (todo voce 10, 26/11/2026): il file (predefiniti, salvare e rileggere,
## valori sbagliati), i tre livelli della qualità nelle viste, la finestra (F10, scelte, scala
## dell'interfaccia, Chiudi), i tutorial spenti e il tempo che parte dopo la fondazione.
## Uso: godot --headless --path gioco -s res://test/verifica_impostazioni.gd

var _errori := 0
var _s: Node
var _f := 0
const FILE := "user://prova_impostazioni.cfg"


func controlla(cond: bool, testo: String) -> void:
	print(("OK  " if cond else "ERRORE  ") + testo)
	if not cond:
		_errori += 1


func _initialize() -> void:
	_s = load("res://scene/principale.tscn").instantiate()
	root.add_child(_s)


func _premi(h: Hud, nome: String) -> bool:
	if not h.modale_aperta():
		return false
	var b := h._modale.find_child(nome, true, false) as Button
	if b == null:
		return false
	if b.toggle_mode:
		b.button_pressed = true
	b.emit_signal("pressed")
	return true


func _process(_d: float) -> bool:
	_f += 1
	if _f < 3:
		return false
	# Il file.
	Impostazioni.percorso_voluto = FILE
	DirAccess.remove_absolute(FILE)
	Impostazioni.carica()
	controlla(Impostazioni.valore("qualita") == "alta" and Impostazioni.valore("tutorial") == true and Impostazioni.valore("automatici") == "tappe_50" and Impostazioni.valore("velocita_partenza") == 0,
		"senza file valgono i predefiniti (qualità alta, tutorial accesi, automatici a tappe e 50 anni, tempo fermo)")
	Impostazioni.imposta("qualita", "bassa")
	Impostazioni.imposta("scala", 1.25)
	Impostazioni.valori = {}
	Impostazioni.carica()
	controlla(Impostazioni.valore("qualita") == "bassa" and is_equal_approx(float(Impostazioni.valore("scala")), 1.25), "le scelte si salvano nel file e si rileggono")
	var cf := ConfigFile.new()
	cf.load(FILE)
	cf.set_value("impostazioni", "qualita", "altissima")
	cf.set_value("impostazioni", "fps", 144)
	cf.save(FILE)
	Impostazioni.carica()
	controlla(Impostazioni.valore("qualita") == "alta" and Impostazioni.valore("fps") == 0, "un valore sconosciuto nel file torna al predefinito")
	# Qualità nelle viste.
	for q in ["bassa", "media", "alta"]:
		Impostazioni.valori["qualita"] = q
		Impostazioni.applica_qualita()
		var l: Dictionary = Impostazioni.LIVELLI[q]
		controlla(is_equal_approx(VistaAlberi.DIM_COMPLETI, l["alberi_completi"]) and VistaPersone.TETTO == l["figure"] and VistaVillaggio.MASSIMO_ANIMALI == l["animali"],
			"qualità %s: alberi completi fino a %d m, %d figure, %d animali" % [q, VistaAlberi.DIM_COMPLETI, VistaPersone.TETTO, VistaVillaggio.MASSIMO_ANIMALI])
	controlla(Impostazioni.LIVELLI["bassa"]["alberi_completi"] < Impostazioni.LIVELLI["media"]["alberi_completi"] and Impostazioni.LIVELLI["media"]["figure"] < Impostazioni.LIVELLI["alta"]["figure"], "i livelli vanno dal più leggero al più ricco")
	# La finestra.
	Impostazioni.valori = {}
	Impostazioni.applica_qualita()
	var h: Hud = _s.hud
	var p: Partita = _s.partita
	while h.modale_aperta():
		var avanti := h._modale.find_child("Continua", true, false) as Button
		if avanti == null:
			break
		avanti.emit_signal("pressed")
	var ev := InputEventKey.new()
	ev.keycode = KEY_F10
	ev.pressed = true
	_s._unhandled_input(ev)
	controlla(h.impostazioni_aperte(), "F10 apre le impostazioni")
	controlla(h._righe_azioni.has("impostazioni"), "in Strumenti › Partita c'è Impostazioni")
	var bottoni := h._modale.find_children("*", "Button", true, false)
	var scelte := 0
	for v in Impostazioni.VOCI:
		scelte += (v["scelte"] as Array).size()
	controlla(bottoni.size() == scelte + 1, "una scelta per ogni valore di ogni voce, più Chiudi (%d)" % bottoni.size())
	var alta := h._modale.find_child("qualita_alta", true, false) as Button
	controlla(alta != null and alta.button_pressed, "la scelta attiva è segnata (qualità alta)")
	_premi(h, "qualita_media")
	controlla(Impostazioni.valore("qualita") == "media" and is_equal_approx(VistaAlberi.DIM_COMPLETI, 160.0), "scegliere Media cambia subito gli alberi completi (%d m)" % VistaAlberi.DIM_COMPLETI)
	_premi(h, ("scala_" + str(1.5)).replace(".", "_"))
	var schermo := _s.get_viewport().get_visible_rect().size
	controlla(is_equal_approx(h.scale.x, 1.5) and h._radice.size.is_equal_approx(schermo / 1.5), "la scala dell'interfaccia ingrandisce l'HUD restando nello schermo")
	_premi(h, ("scala_" + str(1.0)).replace(".", "_"))
	controlla(is_equal_approx(h.scale.x, 1.0) and h._radice.size.is_equal_approx(schermo), "e torna al 100%")
	_premi(h, "tutorial_false")
	_premi(h, "velocita_partenza_2")
	controlla(Impostazioni.valore("tutorial") == false and Impostazioni.valore("velocita_partenza") == 2, "tutorial spenti e tempo medio dopo la fondazione")
	cf = ConfigFile.new()
	cf.load(FILE)
	controlla(cf.get_value("impostazioni", "velocita_partenza", -1) == 2, "ogni scelta si salva subito nel file")
	_premi(h, "Chiudi")
	controlla(not h.modale_aperta(), "Chiudi chiude la finestra")
	_s._unhandled_input(ev)
	_s._unhandled_input(ev)
	controlla(not h.modale_aperta(), "F10 chiude anche la finestra aperta")
	# La fondazione con il tempo che parte e senza tutorial.
	var sito: Vector2 = _s.dati.mondo_da_pixel(_s.dati.siti[0]["px"])
	p.sim.decisioni.clear()
	p.sim.tutorial_attivi = false
	h.seleziona_comando("fonda")
	_s.punto_corrente = Vector3(sito.x, 0, sito.y)
	_s.applica_strumento()
	for b in h._modale.find_children("*", "Button", true, false):
		if (b as Button).text == "Fonda qui":
			(b as Button).emit_signal("pressed")
	controlla(p.sim.fondato and p.velocita == 2, "fondato il villaggio, il tempo parte alla velocità scelta (%d)" % p.velocita)
	controlla(not p.sim.decisioni.any(func(x: Dictionary) -> bool: return x["tipo"] == "tutorial"), "con i tutorial spenti non compaiono schede")
	# Si rimette tutto come prima.
	DirAccess.remove_absolute(FILE)
	Impostazioni.valori = {}
	Impostazioni.applica_qualita()
	print("Verifica completata: " + ("nessun errore" if _errori == 0 else "%d errori" % _errori))
	quit(1 if _errori > 0 else 0)
	return true
