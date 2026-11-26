extends SceneTree
## Foto di controllo di una partita: fondazione sul sito 1, campi attorno, un secolo e mezzo di
## tempo con un giocatore automatico semplice, poi la foto.
## Con famiglia, la scheda della famiglia di una casa vicino al focolare. Con persone:mestiere la camera va su una figura di quel mestiere (contadino, boscaiolo, pescatore, cacciatore, pastore, costruttore, sacro, casa), o persone:centro per il focolare.
## Uso: xvfb-run -a -s "-screen 0 1600x900x24" godot --path gioco --rendering-driver opengl3 --resolution 1600x900 -s res://test/foto_partita.gd -- uscita.png [dimensione_vista] [anni] [mappa] [strumento | politiche | tecniche | anteprima | fondazione | focus:Indicatore | capanno | posta | cantiere | pascolo]
## Con capanno o posta la vista va sul primo capanno da pesca o sulla prima posta di caccia, con lo
## strumento scelto e il puntatore sopra (lettura dell'edificio).

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
				if sim.legnaie.is_empty() or (AiutiGiocatori.legna_scarsa(sim) and sim.legnaie.size() < 3):
					var cg := RandomNumberGenerator.new()
					cg.seed = k
					AiutiGiocatori.costruisci_legnaia(sim, cg, 1.0)
				if sim.sbloccato("pascolo") and sim.pascolo.is_empty():
					var cp := RandomNumberGenerator.new()
					cp.seed = k + 5
					AiutiGiocatori.stendi_pascolo(sim, cp, 1.0, 15.0)
				for caccia in [true, false]:
					if (sim.poste if caccia else sim.capanni).is_empty():
						var ce := RandomNumberGenerator.new()
						ce.seed = k + 1
						AiutiGiocatori.costruisci_edificio_risorse(sim, ce, 1.0, caccia)
				if sim.granaio.x < 0 and sim.sbloccato("granaio") and sim.legna >= SimVillaggio.COSTO_GRANAIO:
					var c := sim.mondo_di_px(sim.centro)
					sim.costruisci_granaio(c + Vector2(70, -30))
				if k == 20:
					sim.traccia_sentiero(sim.centro + Vector2i(-18, -14))
			while sim.in_attesa():
				sim.scegli(sim.decisioni[0]["id"], sim.decisioni[0]["opzioni"][0]["id"])
			sim.passo()
			p._abbatti_tagli()
			_s.uso.avanza_anni(1)
		p.vista.sincronizza()
		p.aggiorna_hud()
		print("   campi %d, stanchi %d, a maggese %d" % [sim.campi.size(), sim.campi_stanchi(), sim.maggese.size()])
		var c := sim.mondo_di_px(sim.centro)
		# Vista sulla prima legnaia (per vedere la radura dei boscaioli).
		if args.size() > 4 and args[4] == "legnaia" and not sim.legnaie.is_empty():
			c = sim.legnaie[0]["punto"]
		var su_edificio := false
		# Cantiere in corso (decisione di Fede del 25/11/2026 sera): una posta nuova a metà lavoro.
		if args.size() > 4 and args[4] == "cantiere":
			var ce := RandomNumberGenerator.new()
			ce.seed = 3
			sim.poste = []
			AiutiGiocatori.costruisci_edificio_risorse(sim, ce, 1.0, true)
			p.vista.sincronizza()
			p.vista.aggiorna_barre(0.6)
			if not sim.poste.is_empty():
				c = sim.poste[0]["punto"]
				su_edificio = true
		# Pascolo: la vista va sul primo stabbio, con lo strumento Pascolo scelto.
		if args.size() > 4 and args[4] == "pascolo" and not p.vista._stabbi.is_empty():
			c = p.vista._greggi[0]["centro"] if not p.vista._greggi.is_empty() else p.vista._stabbi.keys()[0]
			su_edificio = true
			print("   animali disegnati: %d, capi %d, stabbi %d" % [p.vista.animali_disegnati(), roundi(sim.capi), p.vista._stabbi.size()])
		# Campi stanchi (26/11/2026): la vista su un campo molto stanco; con "senza" come sesto
		# argomento si spegne la resa della stanchezza, per il confronto.
		if args.size() > 4 and args[4] == "stanchi":
			for i in sim.campi:
				if sim.fattore_stanchezza(i) < 0.75:
					c = sim.mondo_di_px(sim.px_di(i))
					su_edificio = true
					break
			if args.size() > 5 and args[5] == "senza":
				var nero := Image.create(4, 4, false, Image.FORMAT_RG8)
				_s.terreno.materiale.set_shader_parameter("stanchezza_campi", ImageTexture.create_from_image(nero))
		if args.size() > 4 and args[4] in ["capanno", "posta"]:
			var elenco: Array = sim.capanni if args[4] == "capanno" else sim.poste
			if not elenco.is_empty():
				c = elenco[0]["punto"]
				su_edificio = true
		if su_edificio:
			_s.cam.vai_a(c.x, c.y, float(args[1]) if args.size() > 1 else 600.0)
		else:
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
		elif args.size() > 4 and args[4].begins_with("persone"):
			# Popolazione visibile (voce 7): la camera su una figura del mestiere indicato (per
			# esempio persone:contadino), dopo qualche secondo di movimento.
			var vp: VistaPersone = p.vista.persone
			print("   figure %d (una ogni %d persone): %s" % [vp.figure().size(), vp.quota, vp.mestieri_contati()])
			var voluto := args[4].get_slice(":", 1) if args[4].contains(":") else "contadino"
			if voluto == "centro":
				_s.cam.vai_a(c.x, c.y + 8.0, float(args[1]) if args.size() > 1 else 40.0)
			for f in vp.figure():
				if f["mestiere"] == voluto:
					var q: Vector2 = f["pos"]
					_s.cam.vai_a(q.x, q.y, float(args[1]) if args.size() > 1 else 40.0)
					break
		elif args.size() > 4 and args[4] == "famiglia":
			# Scheda della famiglia (26/11/2026): la casa del paese più vicina al focolare che ha
			# membri visibili, con la scheda aperta.
			var vp: VistaPersone = p.vista.persone
			var scelta: Vector2i = sim.case[0]
			var meglio := INF
			for l in sim.case:
				var d := sim.centro_lotto(l).distance_to(c)
				if not sim.case_casale.has(l) and vp.membri(l).size() >= 2 and d < meglio:
					meglio = d
					scelta = l
			var w := sim.centro_lotto(scelta)
			_s.cam.vai_a(w.x, w.y, float(args[1]) if args.size() > 1 else 60.0)
			_s.partita.apri_famiglia(scelta)
			print("   famiglia: %s" % _s.partita.dati_famiglia(scelta))
		elif args.size() > 4 and args[4] == "legnaia":
			_s.hud.seleziona_comando("legnaia")
			_s.aggiorna_zone_taglio()
		elif su_edificio and args[4] == "cantiere":
			pass
		elif su_edificio:
			_s.hud.seleziona_comando(args[4])
			_s.punto_corrente = Vector3(c.x, 0.0, c.y)
			_s.partita.leggi_sito(_s.punto_corrente)
			_s._aggiorna_pennello()
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
