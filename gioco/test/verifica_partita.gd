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
	controlla(sim.fondato and h.comando() == "campi", "fondato; si passa ai campi")
	controlla(p.vista.numero_case() == sim.case.size() and sim.case.size() == 4, "le case della simulazione sono disegnate (%d)" % p.vista.numero_case())
	controlla(_s.uso.stato(sito.x, sito.y) == UsoSuolo.COSTRUITO, "terra battuta al centro del villaggio")
	# Campi a est del centro, entro il raggio.
	_s.raggio_pennello = 120.0
	_s.punto_corrente = Vector3(sito.x + 300.0, 0, sito.y)
	_s.applica_strumento()
	controlla(sim.campi.size() > 10, "un clic dissoda i campi nel cerchio (%d)" % sim.campi.size())
	var f := sim.mondo_di_px(sim.px_di(sim.campi[0]))
	controlla(_s.uso.stato(f.x, f.y) == UsoSuolo.COLTIVATO, "i campi sono suolo coltivato")
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
	controlla(h._valori_indicatori.has("Popolazione") and h._valori_indicatori["Popolazione"].text == str(roundi(sim.pop)), "gli indicatori seguono la simulazione")
	controlla(h._cronaca.text != "—", "la cronaca si riempie")
	p.imposta_velocita(0)
	var anno1 := sim.anno
	p._process(1.0)
	controlla(sim.anno == anno1, "in pausa il tempo è fermo")
	print("Verifica completata: " + ("nessun errore" if _errori == 0 else "%d errori" % _errori))
	quit(1 if _errori > 0 else 0)
	return true
