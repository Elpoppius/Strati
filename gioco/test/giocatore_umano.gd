extends SceneTree
## Giocatori automatici "umani" (richiesta di Fede del 25/11/2026): non conoscono le dinamiche
## interne della simulazione, vedono solo ciò che vede il giocatore (indicatori rossi, cause scritte
## nei pannelli di focus, tappe, scelte che fermano il gioco) e imparano sbagliando.
## Due profili:
## - "sbaglia": impara per tentativi, apre poco i pannelli di focus (3 volte su 10);
## - "legge": si ferma a leggere le spiegazioni (8 volte su 10).
## Cosa fa un giocatore "umano":
## - stende all'inizio una zona agricola a metà del contado, senza guardare il rischio di piena;
##   impara a evitarlo solo dopo la prima piena grande (la finestra lo spiega);
## - guarda la partita ogni 10–30 anni; se un indicatore è rosso apre il suo pannello (secondo il
##   profilo) e prova il rimedio che la causa suggerisce; se vede la zona piena sulla mappa, a volte
##   la allarga;
## - costruisce il granaio quando la tappa lo apre e c'è la legna, ma non sempre subito;
## - prova il raccolto alle famiglie quando si apre, e torna indietro se il pannello dice che gli
##   anziani lo vedono male;
## - risponde alle scelte d'istinto (presagi: metà e metà; chi legge ascolta più spesso le sorgenti).
## Uso: godot --headless --path gioco -s res://test/giocatore_umano.gd -- uscita.txt [semi]

var _righe: Array[String] = []


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var file := args[0] if args.size() > 0 else "/tmp/umano.txt"
	var semi := int(args[1]) if args.size() > 1 else 3
	var d: MappaDati = load("res://mappe/pedecollinare/mappa.res")
	_righe.append("profilo,sito,seme,pop_finale,pop_minima,carestie,carestie_gravi,abbandoni,scissioni,pause,piene_grandi,granaio_anno,cosa_ha_imparato")
	for profilo in ["sbaglia", "legge"]:
		for sito in d.siti:
			for seme in range(1, semi + 1):
				var r := _gioca(d, sito, profilo, seme * 31 + int(sito["n"]))
				_righe.append("%s,%s,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%s" % [profilo, String(sito["nome"]).replace(",", " "), seme, r["pop"], r["minima"], r["carestie"], r["gravi"], r["abbandoni"], r["scissioni"], r["pause"], r["piene"], r["granaio"], r["imparato"]])
	var f := FileAccess.open(file, FileAccess.WRITE)
	f.store_string("\n".join(_righe) + "\n")
	f.close()
	print("Scritto " + file)
	quit()


func _gioca(d: MappaDati, sito: Dictionary, profilo: String, seme: int) -> Dictionary:
	var sim := SimVillaggio.new(d, seme)
	var caso := RandomNumberGenerator.new()
	caso.seed = seme * 104729 + (1 if profilo == "legge" else 0)
	var legge := 0.8 if profilo == "legge" else 0.3
	var p_sito := Vector2i(sito["px"])
	sim.fonda(p_sito)
	var anno0 := sim.anno
	var imparato := {}
	var copertura := 0.5
	_zona(sim, copertura, imparato.has("piena"))
	var prossimo := 10 + caso.randi() % 21
	var gravi := 0
	var scissioni := 0
	var pause := 0
	var minima := sim.pop
	var granaio_anno := -1
	var granaio_voluto := false
	var caccia_spenta_anno := -1
	var raccolto_provato := false
	while not sim.finito:
		while sim.in_attesa():
			var dec: Dictionary = sim.decisioni[0]
			if dec["tipo"] != "fine":
				pause += 1
			if dec["tipo"] == "piena" and caso.randf() < 0.5 + 0.4 * legge:
				# La finestra spiega dove arrivano le piene: si impara a evitare le terre rosse.
				imparato["piena"] = true
			sim.scegli(dec["id"], _istinto(dec, caso, legge))
		if not sim.fondato:
			# Dopo un abbandono si rifonda nello stesso sito (il giocatore ci riprova).
			sim.fonda(p_sito)
			_zona(sim, copertura, imparato.has("piena"))
		var eta := sim.anno - anno0
		# Le notifiche delle tappe: un tasto nuovo invoglia a provarlo.
		while not sim.avvisi.is_empty():
			var a: Dictionary = sim.avvisi.pop_front()
			var t := String(a["testo"])
			if t.contains("granaio"):
				granaio_voluto = caso.randf() < 0.6
			if t.contains("si divide"):
				scissioni += 1
		if eta >= prossimo and sim.fondato:
			prossimo = eta + 10 + caso.randi() % 21
			# Indicatori rossi: si apre il pannello (secondo il profilo) e si prova il rimedio.
			var rossi: Array[String] = []
			if sim.abbondanza < SimVillaggio.SOGLIA_CRESCITA:
				rossi.append("Abbondanza")
			if sim.cibo < sim.pop * 0.3:
				rossi.append("Cibo")
			if sim.legittimita < 30.0:
				rossi.append("Consenso")
			if sim.legna < SimVillaggio.COSTO_CASA and sim.ultima_legna < sim.consumo_legna:
				rossi.append("Legna")
			for nome in rossi:
				if caso.randf() >= legge:
					continue
				for c in sim.cause_di(nome):
					if c.contains("zona agricola è piena") or c.contains("servono più campi"):
						copertura = minf(1.0, copertura + 0.15)
						_zona(sim, copertura, imparato.has("piena"))
						imparato["zona"] = true
					elif c.contains("Senza granaio"):
						granaio_voluto = true
						imparato["granaio"] = true
					elif c.contains("Si caccia troppo") and sim.fonti["caccia"]:
						sim.imposta_fonte("caccia", false)
						caccia_spenta_anno = eta
						imparato["caccia"] = true
					elif c.contains("gli anziani lo vedono male") and sim.politica("raccolto") == "famiglie":
						sim.imposta_politica("raccolto", "comune")
						imparato["usanze"] = true
			# Senza leggere: guardando la mappa a volte si vede la zona piena e la si allarga.
			if sim.zona_piena and caso.randf() < 0.5:
				copertura = minf(1.0, copertura + 0.1)
				_zona(sim, copertura, imparato.has("piena"))
			# La caccia spenta si dimentica: dopo un po' la si riaccende.
			if caccia_spenta_anno >= 0 and eta - caccia_spenta_anno > 50 and not sim.fonti["caccia"]:
				sim.imposta_fonte("caccia", true)
				caccia_spenta_anno = -1
			if granaio_voluto and sim.granaio.x < 0 and sim.sbloccato("granaio") and sim.legna >= SimVillaggio.COSTO_GRANAIO:
				var c0 := sim.mondo_di_px(sim.centro)
				for prova in [Vector2(60, 0), Vector2(-60, 0), Vector2(0, 60), Vector2(0, -60), Vector2(100, 100)]:
					if sim.costruisci_granaio(c0 + prova) == "":
						granaio_anno = eta
						break
			# Il raccolto alle famiglie, appena si apre: si prova una volta, metà dei giocatori.
			if not raccolto_provato and sim.sbloccato("raccolto"):
				raccolto_provato = true
				if caso.randf() < 0.5:
					sim.imposta_politica("raccolto", "famiglie")
		var prima: int = sim.stat["carestie"]
		var pop_prima := sim.pop
		sim.passo()
		if sim.stat["carestie"] > prima and sim.pop < pop_prima * 0.9:
			gravi += 1
		if sim.fondato:
			minima = minf(minima, sim.pop)
	return {"pop": roundi(sim.pop), "minima": roundi(minima), "carestie": sim.stat["carestie"], "gravi": gravi,
		"abbandoni": sim.stat["abbandoni"], "scissioni": scissioni, "pause": pause, "piene": sim.stat["piene"],
		"granaio": granaio_anno, "imparato": " ".join(imparato.keys())}


## Zona agricola su una parte del contado; evita le terre a rischio solo se l'ha imparato.
func _zona(sim: SimVillaggio, copertura: float, evita_piena: bool) -> void:
	var r := sim.raggio_campi()
	var rr := r * copertura
	var lista: Array[Vector2i] = []
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			if Vector2(dx, dy).length() > rr:
				continue
			var q := sim.centro + Vector2i(dx, dy)
			if q.x < 0 or q.y < 0 or q.x >= sim.n or q.y >= sim.n or not sim.edificabile(sim.px(q)):
				continue
			if evita_piena and sim.piena(sim.px(q)) > 0.5:
				continue
			lista.append(q)
	sim.aggiungi_zona(lista)


## Risposte d'istinto alle scelte.
func _istinto(dec: Dictionary, caso: RandomNumberGenerator, legge: float) -> String:
	var opzioni: Array = dec["opzioni"]
	if opzioni.size() == 1:
		return opzioni[0]["id"]
	match dec["tipo"]:
		"sorgenti":
			return "razionare" if caso.randf() < 0.4 + 0.4 * legge else "ignorare"
		"cometa":
			return "offerte" if caso.randf() < 0.5 else "ignorare"
		"stranieri":
			return "accogliere" if caso.randf() < 0.6 else "respingere"
		"affollamento":
			return "restare" if caso.randf() < 0.7 else "emigrare"
	return opzioni[caso.randi() % opzioni.size()]["id"]
