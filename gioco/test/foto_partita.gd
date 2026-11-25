extends SceneTree
## Foto di controllo di una partita: fondazione sul sito 1, campi attorno, un secolo e mezzo di
## tempo con un giocatore automatico semplice, poi la foto.
## Uso: xvfb-run -a -s "-screen 0 1600x900x24" godot --path gioco --rendering-driver opengl3 --resolution 1600x900 -s res://test/foto_partita.gd -- uscita.png [dimensione_vista] [anni] [mappa] [strumento | politiche | tecniche | anteprima | fondazione | focus:Indicatore]

var _s: Node
var _f := 0


func _initialize() -> void:
	_s = load("res://scene/principale.tscn").instantiate()
	root.add_child(_s)


func _process(_d: float) -> bool:
	_f += 1
	var args := OS.get_cmdline_user_args()
	if _f == 3:
		var p: Partita = _s.partita
		var sim := p.sim
		sim.rng.seed = 11
		var sito: Vector2 = _s.dati.mondo_da_pixel(_s.dati.siti[0]["px"])
		sim.fonda(sim.px_da_mondo(sito.x, sito.y))
		var anni := int(args[2]) if args.size() > 2 else 150
		for k in anni:
			if k % 25 == 0 and sim.fondato:
				# Zona agricola su tutto il contado; i campi li dissodano le famiglie.
				var tutta: Array[Vector2i] = []
				var r := sim.raggio_campi()
				for dy in range(-r, r + 1):
					for dx in range(-r, r + 1):
						tutta.append(sim.centro + Vector2i(dx, dy))
				sim.aggiungi_zona(tutta)
			if k % 5 == 0 and sim.fondato:
				if sim.granaio.x < 0 and sim.cibo > 40.0:
					var c := sim.mondo_di_px(sim.centro)
					sim.costruisci_granaio(c + Vector2(70, -30))
				if k == 20:
					sim.traccia_sentiero(sim.centro + Vector2i(-18, -14))
			while sim.in_attesa():
				sim.scegli(sim.decisioni[0]["id"], sim.decisioni[0]["opzioni"][0]["id"])
			sim.passo()
			_s.uso.avanza_anni(1)
		p.vista.sincronizza()
		p.aggiorna_hud()
		var c := sim.mondo_di_px(sim.centro)
		_s.cam.vai_a(c.x + 60.0, c.y + 40.0, float(args[1]) if args.size() > 1 else 600.0)
		_s.griglia_attiva = false
		if args.size() > 3:
			_s.imposta_modo(int(args[3]))
		if args.size() > 4 and args[4] == "fondazione":
			# Lettura del sito prima della fondazione: si riparte da zero, puntatore sul sito 2.
			sim.fondato = false
			_s.hud.seleziona_comando("fonda")
			var s2: Vector2 = _s.dati.mondo_da_pixel(_s.dati.siti[1]["px"])
			_s.punto_corrente = Vector3(s2.x, 0.0, s2.y)
			p.leggi_sito(_s.punto_corrente)
			p.aggiorna_modalita()
			_s.cam.vai_a(s2.x, s2.y, float(args[1]) if args.size() > 1 else 600.0)
		elif args.size() > 4 and args[4] == "anteprima":
			# Anteprima di un sentiero come in Cities: inizio al centro, puntatore a nord-est; più
			# alcune notifiche di prova.
			_s.hud.seleziona_comando("sentiero")
			p.inizio_sentiero = sim.centro
			_s.punto_corrente = Vector3(c.x + 160.0, 0.0, c.y - 80.0)
			_s._aggiorna_pennello()
			_s.hud.notifica("Piena di stagione: 6 campi allagati.", false, c)
			_s.hud.notifica("Carestia: manca il 30% del cibo necessario.", true, c)
		elif args.size() > 4 and args[4] == "tecniche":
			# Prova del cambio d'epoca: tecnica nuova (strisce) e qualche anno di ammodernamento,
			# così si vedono insieme campi vecchi e campi rifatti.
			sim.tecnica_corrente = 3
			sim.cibo = 100000.0
			sim.imposta_ammodernamento("agricolo", true)
			for k in 4:
				sim._ammoderna()
			p.vista.sincronizza()
			p.aggiorna_hud()
			_s.hud.apri_menu("ammodernamento")
		elif args.size() > 4 and args[4] == "politiche":
			_s.hud.apri_politiche(true)
		elif args.size() > 4 and args[4].begins_with("focus"):
			# Pannello di focus di un indicatore (per esempio focus:Abbondanza).
			var nome := args[4].get_slice(":", 1) if args[4].contains(":") else "Abbondanza"
			_s.partita.aggiorna_hud()
			_s.hud.mostra_focus(_s.partita.dati_focus(nome))
		elif args.size() > 4:
			# Strumento attivo con il cerchio al centro della vista (per vedere la guida dei campi).
			_s.hud.seleziona_comando(args[4])
			_s.punto_corrente = Vector3(c.x + 60.0, 0.0, c.y + 40.0)
			_s.partita.leggi_sito(_s.punto_corrente)
			_s._aggiorna_pennello()
		print("   %s: %d abitanti, %d case, %d campi" % [SimVillaggio.anno_testo(sim.anno), roundi(sim.pop), sim.case.size(), sim.campi.size()])
	if _f == 60:
		root.get_texture().get_image().save_png(args[0] if args.size() > 0 else "user://partita.png")
		print("Foto salvata")
		quit(0)
	return false
