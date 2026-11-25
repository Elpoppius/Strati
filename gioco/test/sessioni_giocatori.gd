extends SceneTree
## Sessioni di gioco automatiche con dieci giocatori di bravura diversa (1 = alle prime armi,
## 10 = esperto), su tutti i siti di fondazione e con più semi. Serve a vedere come crescono gli
## abitanti a seconda di quanto si gioca bene (richiesta di Fede del 24/11/2026: lo scopo è far
## crescere la città, più abitanti è più successo).
## Uso: godot --headless --path gioco -s res://test/sessioni_giocatori.gd -- uscita.csv [semi] [livelli] [siti]
##   semi: quanti semi per sito (predefinito 3); livelli: per esempio "1,5,10" (predefinito tutti);
##   siti: numeri dei siti, per esempio "4" (predefinito tutti). 10 livelli × 6 siti × 3 semi: circa
##   25 minuti nell'ambiente di Claude.
##
## Cosa cambia con la bravura (k da 1 a 10):
## - attenzione: ogni quanti anni il giocatore guarda la mappa (da 50 a 5);
## - zona agricola: quanta parte del contado copre (dal 46% al 100%); sotto il livello 3 la si
##   allarga solo quando, guardando la mappa, la si vede piena; dal 6 si evitano le terre a rischio di
##   piena alto, dall'8 anche quelle a rischio medio, a meno che la terra sicura sia troppo poca;
## - granaio dal livello 3; sentieri radiali collegati dal 5 (uno in più per livello, fino a 6);
## - scelte: la risposta giusta con probabilità (k - 1) / 9, altrimenti a caso;
## - divisione del raccolto gestita dal 6 (alle famiglie se il consenso regge); caccia sospesa
##   quando la selvaggina crolla, dal 7.

const ANNI_CAMPIONE := 50
const SOGLIE := [100, 300, 1000]

var _righe: Array[String] = []


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var uscita := args[0] if args.size() > 0 else "/tmp/sessioni.csv"
	var semi := int(args[1]) if args.size() > 1 else 3
	var livelli: Array[int] = []
	if args.size() > 2:
		for t in args[2].split(","):
			livelli.append(int(t))
	else:
		for k in range(1, 11):
			livelli.append(k)
	var solo_siti: Array[int] = []
	if args.size() > 3:
		for t in args[3].split(","):
			solo_siti.append(int(t))
	var d: MappaDati = load("res://mappe/pedecollinare/mappa.res")
	var intestazione := "livello,sito,nome_sito,seme,pop_finale,pop_massima,case,campi,carestie,abbandoni,emigrazioni,salute,legittimita"
	for s in SOGLIE:
		intestazione += ",anno_%d" % s
	for a in range(0, 501, ANNI_CAMPIONE):
		intestazione += ",pop_%d" % a
	_righe.append(intestazione)
	var t0 := Time.get_ticks_msec()
	for k in livelli:
		var finali: Array[float] = []
		for sito in d.siti:
			if not solo_siti.is_empty() and not solo_siti.has(int(sito["n"])):
				continue
			for seme in range(1, semi + 1):
				var r := _gioca(d, Vector2i(sito["px"]), k, seme * 101 + int(sito["n"]))
				finali.append(r["pop"])
				var riga := "%d,%d,%s,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d" % [k, sito["n"], String(sito["nome"]).replace(",", " "), seme,
					roundi(r["pop"]), roundi(r["massima"]), r["case"], r["campi"], r["carestie"], r["abbandoni"], r["emigrazioni"], roundi(r["salute"]), roundi(r["legittimita"])]
				for s in SOGLIE:
					riga += ",%d" % r["soglie"].get(s, -1)
				for p in r["campioni"]:
					riga += ",%d" % roundi(p)
				_righe.append(riga)
		finali.sort()
		print("livello %2d: mediana %4d abitanti (min %d, max %d)  [%.0f s]" % [k, roundi(finali[finali.size() / 2]), roundi(finali[0]), roundi(finali[-1]), (Time.get_ticks_msec() - t0) / 1000.0])
	var f := FileAccess.open(uscita, FileAccess.WRITE)
	f.store_string("\n".join(_righe) + "\n")
	f.close()
	print("Scritto " + uscita)
	quit()


func _gioca(d: MappaDati, sito: Vector2i, k: int, seme: int) -> Dictionary:
	var sim := SimVillaggio.new(d, seme)
	var caso := RandomNumberGenerator.new()
	caso.seed = seme * 7919 + k
	sim.fonda(sito)
	var anno0 := sim.anno
	var attenzione: int = [50, 40, 30, 25, 20, 15, 10, 10, 5, 5][k - 1]
	var copertura := 0.4 + 0.06 * k
	var limite_piena := 0.25 if k >= 8 else (0.5 if k >= 6 else 2.0)
	var p_giusta := (k - 1) / 9.0
	var massima := sim.pop
	var soglie := {}
	var campioni: Array[float] = [sim.pop]
	var sentieri_fatti := false
	_stendi_zona(sim, copertura, limite_piena)
	# La legnaia: i più bravi la mettono vicino al bosco e ne fanno un'altra quando rende poco.
	AiutiGiocatori.costruisci_legnaia(sim, caso, (k - 1) / 9.0)
	# Posta di caccia e capanno da pesca: chi gioca meglio li fa subito e nel punto giusto, e ne
	# aggiunge quando non bastano; chi gioca peggio li fa tardi, dove capita.
	_edifici_risorse(sim, caso, k, 0)
	while not sim.finito:
		while sim.in_attesa():
			var dec: Dictionary = sim.decisioni[0]
			sim.scegli(dec["id"], _risposta(dec, caso, p_giusta, sim))
		if not sim.fondato:
			sim.fonda(sito)
			_stendi_zona(sim, copertura, limite_piena)
			AiutiGiocatori.costruisci_legnaia(sim, caso, (k - 1) / 9.0)
			_edifici_risorse(sim, caso, k, 0)
		var eta := sim.anno - anno0
		# Chi gioca poco allarga la zona solo quando, guardando la mappa, la vede piena (dal 25/11/2026
		# non c'è più la notifica: lo dice la mappa).
		sim.avvisi.clear()
		if k < 3 and eta % attenzione == 0 and sim.zona_piena:
			_stendi_zona(sim, copertura, limite_piena)
		if eta % attenzione == 0 and sim.fondato:
			if k >= 3:
				_stendi_zona(sim, copertura, limite_piena)
				if sim.granaio.x < 0 and sim.sbloccato("granaio") and sim.legna >= SimVillaggio.COSTO_GRANAIO:
					var c := sim.mondo_di_px(sim.centro)
					for prova in [Vector2(60, 0), Vector2(-60, 0), Vector2(0, 60), Vector2(0, -60), Vector2(100, 100)]:
						if sim.costruisci_granaio(c + prova) == "":
							break
			if sim.legnaie.is_empty() or (k >= 4 and AiutiGiocatori.legna_scarsa(sim) and sim.legnaie.size() < 1 + k / 3):
				AiutiGiocatori.costruisci_legnaia(sim, caso, (k - 1) / 9.0)
			_edifici_risorse(sim, caso, k, eta)
			# Luogo sacro dal livello 3, bosco sacro dal livello 5 (i più bravi più grande).
			if k >= 3 and sim.luogo_sacro.x < 0 and sim.sbloccato("luogo_sacro") and sim.legna >= SimVillaggio.COSTO_LUOGO_SACRO:
				AiutiGiocatori.costruisci_luogo_sacro(sim)
			if k >= 5 and sim.bosco_sacro.is_empty() and sim.sbloccato("bosco_sacro"):
				AiutiGiocatori.stendi_bosco_sacro(sim, caso, (k - 1) / 9.0, 4.0 + k)
			if k >= 5 and not sentieri_fatti and eta >= 20:
				sentieri_fatti = true
				for j in mini(k - 4, 6):
					var ang := j * TAU / mini(k - 4, 6) + 0.4
					sim.traccia_sentiero_da(sim.centro, sim.centro + Vector2i(roundi(cos(ang) * 9.0), roundi(sin(ang) * 9.0)))
			if k >= 6:
				var voluto := "famiglie" if sim.legittimita > 55.0 else "comune"
				if sim.politica("raccolto") != voluto:
					sim.imposta_politica("raccolto", voluto)
			if k >= 7:
				if sim.fonti["caccia"] and sim.selvaggina < 0.35:
					sim.imposta_fonte("caccia", false)
				elif not sim.fonti["caccia"] and sim.selvaggina > 0.6:
					sim.imposta_fonte("caccia", true)
		sim.passo()
		massima = maxf(massima, sim.pop)
		for s in SOGLIE:
			if not soglie.has(s) and sim.pop >= s:
				soglie[s] = sim.anno - anno0
		if (sim.anno - anno0) % ANNI_CAMPIONE == 0 and campioni.size() <= 500 / ANNI_CAMPIONE:
			campioni.append(sim.pop)
	while campioni.size() <= 500 / ANNI_CAMPIONE:
		campioni.append(sim.pop)
	return {"pop": sim.pop, "massima": massima, "case": sim.case.size(), "campi": sim.campi.size(),
		"carestie": sim.stat["carestie"], "abbandoni": sim.stat["abbandoni"], "emigrazioni": sim.stat.get("emigrazioni", 0),
		"salute": sim.salute, "legittimita": sim.legittimita, "soglie": soglie, "campioni": campioni}


## Zona agricola su una parte del contado attorno al centro, saltando le terre a rischio di piena
## sopra il limite.
## Se la terra sicura è meno del 40% di quella a portata (per esempio sul dosso tra le paludi), il
## giocatore accetta un rischio più alto: chi gioca bene non lascia il villaggio senza campi.
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


## La scelta giusta per la crescita (con probabilità p), altrimenti una a caso.
func _risposta(dec: Dictionary, caso: RandomNumberGenerator, p: float, sim: SimVillaggio) -> String:
	var opzioni: Array = dec["opzioni"]
	if opzioni.size() == 1:
		return opzioni[0]["id"]
	if caso.randf() < p:
		match dec["tipo"]:
			"sorgenti":
				return "razionare"  # presagio vero
			"cometa":
				return "ignorare"  # presagio falso
			"stranieri":
				return "accogliere"
			"affollamento":
				return "restare"
			"primo_cattivo":
				return "caccia" if sim.selvaggina > 0.5 else "razionare"
	return opzioni[caso.randi() % opzioni.size()]["id"]


## Poste e capanni secondo il livello: dal livello 4 subito, prima dopo 60 anni; dal livello 6 un
## altro quando non bastano (fino a 1 + k / 4).
func _edifici_risorse(sim: SimVillaggio, caso: RandomNumberGenerator, k: int, eta: int) -> void:
	if k < 4 and eta < 60:
		return
	for caccia in [true, false]:
		var quanti: int = (sim.poste if caccia else sim.capanni).size()
		if quanti == 0 or (k >= 6 and quanti < 1 + k / 4 and AiutiGiocatori.risorsa_scarsa(sim, caccia)):
			AiutiGiocatori.costruisci_edificio_risorse(sim, caso, (k - 1) / 9.0, caccia)
