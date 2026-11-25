extends SceneTree
## Cinque partite automatiche (giocatore di livello medio) con il registro di tutto ciò che il
## giocatore vede: scelte che fermano il gioco, notifiche (rosse e grigie), righe della cronaca.
## Serve a misurare quanti avvisi arrivano e quanto pesano le piene (richiesta di Fede del
## 25/11/2026). Il giocatore automatico è lo stesso di sessioni_giocatori.gd, in versione ridotta.
## Uso: godot --headless --path gioco -s res://test/registro_avvisi.gd -- uscita.txt [livello]

var _uscita: Array[String] = []


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var file := args[0] if args.size() > 0 else "/tmp/avvisi.txt"
	var k := int(args[1]) if args.size() > 1 else 5
	var d: MappaDati = load("res://mappe/pedecollinare/mappa.res")
	var totale := {}
	for n in 5:
		var sito: Dictionary = d.siti[n]
		var r := _gioca(d, Vector2i(sito["px"]), k, 300 + n, String(sito["nome"]))
		for c in r.keys():
			totale[c] = totale.get(c, 0) + r[c]
	_uscita.append("\n=== TOTALE 5 PARTITE ===")
	for c in totale.keys():
		_uscita.append("%s: %s" % [c, str(totale[c])])
	var f := FileAccess.open(file, FileAccess.WRITE)
	f.store_string("\n".join(_uscita) + "\n")
	f.close()
	print("Scritto " + file)
	quit()


func _gioca(d: MappaDati, sito: Vector2i, k: int, seme: int, nome: String) -> Dictionary:
	var sim := SimVillaggio.new(d, seme)
	var caso := RandomNumberGenerator.new()
	caso.seed = seme * 7919 + k
	sim.fonda(sito)
	var anno0 := sim.anno
	var attenzione: int = [50, 40, 30, 25, 20, 15, 10, 10, 5, 5][k - 1]
	var copertura := 0.4 + 0.06 * k
	var limite_piena := 0.25 if k >= 8 else (0.5 if k >= 6 else 2.0)
	var p_giusta := (k - 1) / 9.0
	var conti := {"pause": 0, "notifiche_rosse": 0, "notifiche_grigie": 0, "cronaca": 0, "cronaca_allarme": 0,
		"piene_stagione": 0, "piene_disastrose": 0, "carestie": 0}
	var perdita_piene := 0.0  # quota di campi allagati, sommata sulle piene di stagione
	var ultimo: Variant = sim.cronaca[0] if not sim.cronaca.is_empty() else null
	var sentieri_fatti := false
	_uscita.append("\n=== %s (seme %d, livello %d) ===" % [nome, seme, k])
	_stendi_zona(sim, copertura, limite_piena)
	while not sim.finito:
		while sim.in_attesa():
			var dec: Dictionary = sim.decisioni[0]
			if dec["tipo"] != "fine":
				conti["pause"] += 1
				_uscita.append("%5d  PAUSA     %s" % [sim.anno - anno0, dec["titolo"]])
			sim.scegli(dec["id"], _risposta(dec, caso, p_giusta, sim))
		if not sim.fondato:
			sim.fonda(sito)
			_stendi_zona(sim, copertura, limite_piena)
		var eta := sim.anno - anno0
		if eta % attenzione == 0 and sim.fondato:
			_stendi_zona(sim, copertura, limite_piena)
			if k >= 3 and sim.granaio.x < 0 and sim.cibo > 40.0:
				var c := sim.mondo_di_px(sim.centro)
				for prova in [Vector2(60, 0), Vector2(-60, 0), Vector2(0, 60), Vector2(0, -60)]:
					if sim.costruisci_granaio(c + prova) == "":
						break
			if k >= 5 and not sentieri_fatti and eta >= 20:
				sentieri_fatti = true
				for j in mini(k - 4, 6):
					var ang := j * TAU / mini(k - 4, 6) + 0.4
					sim.traccia_sentiero_da(sim.centro, sim.centro + Vector2i(roundi(cos(ang) * 9.0), roundi(sin(ang) * 9.0)))
		var campi_prima := sim.campi.size()
		sim.passo()
		eta = sim.anno - anno0
		while not sim.avvisi.is_empty():
			var a: Dictionary = sim.avvisi.pop_front()
			var testo := String(a["testo"])
			conti["notifiche_rosse" if a["pericolo"] else "notifiche_grigie"] += 1
			_uscita.append("%5d  %s  %s" % [eta, "ROSSA  " if a["pericolo"] else "grigia ", testo])
			if testo.begins_with("Piena di stagione"):
				conti["piene_stagione"] += 1
				perdita_piene += float(sim.allagati.size()) / maxf(1.0, campi_prima)
			elif testo.begins_with("Piena disastrosa"):
				conti["piene_disastrose"] += 1
			elif testo.begins_with("Carestia"):
				conti["carestie"] += 1
		# Righe nuove della cronaca.
		var nuove: Array[String] = []
		for voce in sim.cronaca:
			if ultimo != null and is_same(voce, ultimo):
				break
			nuove.push_front(String(voce["testo"]))
			conti["cronaca"] += 1
			if voce["tipo"] == "allarme":
				conti["cronaca_allarme"] += 1
		if not sim.cronaca.is_empty():
			ultimo = sim.cronaca[0]
		for t in nuove:
			_uscita.append("%5d  cronaca   %s" % [eta, t])
	_uscita.append("Fine: %d abitanti, carestie %d, salute %d, consenso %d" % [roundi(sim.pop), sim.stat["carestie"], roundi(sim.salute), roundi(sim.legittimita)])
	_uscita.append("Piene di stagione: in media %.1f%% dei campi allagati ogni volta" % (100.0 * perdita_piene / maxf(1.0, conti["piene_stagione"])))
	return conti


func _stendi_zona(sim: SimVillaggio, copertura: float, limite_piena: float) -> void:
	var r := sim.raggio_campi()
	var rr := r * copertura
	for limite in [limite_piena, 0.5, 2.0]:
		if limite < limite_piena:
			continue
		var lista: Array[Vector2i] = []
		var tutte := 0
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if Vector2(dx, dy).length() > rr:
					continue
				var q := sim.centro + Vector2i(dx, dy)
				if q.x < 0 or q.y < 0 or q.x >= sim.n or q.y >= sim.n or not sim.edificabile(sim.px(q)):
					continue
				tutte += 1
				if sim.piena(sim.px(q)) <= limite:
					lista.append(q)
		if lista.size() >= tutte * 0.4 or limite >= 2.0:
			sim.aggiungi_zona(lista)
			return


func _risposta(dec: Dictionary, caso: RandomNumberGenerator, p: float, sim: SimVillaggio) -> String:
	var opzioni: Array = dec["opzioni"]
	if opzioni.size() == 1:
		return opzioni[0]["id"]
	if caso.randf() < p:
		match dec["tipo"]:
			"sorgenti":
				return "razionare"
			"cometa":
				return "ignorare"
			"stranieri":
				return "accogliere"
			"affollamento":
				return "restare"
			"primo_cattivo":
				return "caccia" if sim.selvaggina > 0.5 else "razionare"
	return opzioni[caso.randi() % opzioni.size()]["id"]
