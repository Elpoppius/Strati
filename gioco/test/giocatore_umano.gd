extends SceneTree
## Giocatori automatici "umani" (richiesta di Fede del 25/11/2026): non conoscono le dinamiche
## interne della simulazione, vedono solo ciò che vede il giocatore (indicatori rossi, cause scritte
## nei pannelli di focus, tappe, scelte che fermano il gioco) e imparano sbagliando.
## Quattro profili (decisione di Fede del 25/11/2026: sono la base dei test futuri):
## - "sbaglia": impara per tentativi, apre poco i pannelli di focus (3 volte su 10);
## - "legge": si ferma a leggere le spiegazioni (8 volte su 10);
## - "genere": conosce i giochi di questo tipo ma non legge e va a tentativi: allarga la zona appena
##   la vede piena, costruisce subito granaio e legnaia (la legnaia vicino al bosco, un'altra quando
##   rende poco; così anche posta di caccia e capanno da pesca), guarda le mappe tematiche e così metà delle volte evita le terre a rischio;
## - "casual": guarda di rado (ogni 20–50 anni), non legge mai, risponde a caso, non impara dalle
##   piene, mette legnaia, posta e capanno dove capita e non rivede mai le politiche; continua a
##   giocare comunque.
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
## Uso: godot --headless --path gioco -s res://test/giocatore_umano.gd -- uscita.txt [semi] (72 partite
## con 3 semi: 4 profili × 6 siti × 3) [lunghe] [profili]. Di norma si giocano i primi cinque secoli
## (fino a SimVillaggio.ANNO_PROVE, come le misure di prima); con "lunghe" fino all'evento soglia
## (voce 6, 26/11/2026); profili: per esempio "legge,casual".

var _righe: Array[String] = []
var _anno_limite := SimVillaggio.ANNO_PROVE
var _senza_scorrerie := false


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var file := args[0] if args.size() > 0 else "/tmp/umano.txt"
	var semi := int(args[1]) if args.size() > 1 else 3
	if args.size() > 2 and args[2] == "lunghe":
		_anno_limite = SimVillaggio.ANNO_FINE
	# "epoca2": fino alla fine del prototipo dell'epoca 2 (il fabbro, 27/11/2026).
	if args.size() > 2 and args[2] == "epoca2":
		_anno_limite = SimVillaggio.ANNO_FINE_EPOCA2 + 1
	var profili: Array = args[3].split(",") if args.size() > 3 else ["sbaglia", "legge", "genere", "casual"]
	# "senza_scorrerie" come quinto argomento: le stesse partite senza scorrerie (per misurarne il peso).
	_senza_scorrerie = args.size() > 4 and args[4] == "senza_scorrerie"
	var d: MappaDati = load("res://mappe/pedecollinare/mappa.res")
	_righe.append("profilo,sito,seme,pop_finale,pop_minima,carestie,carestie_gravi,abbandoni,scissioni,pause,tutorial,piene_grandi,granaio_anno,cosa_ha_imparato,legnaie,casali,nucleo,poste,capanni,luogo_sacro,bosco_sacro_ha,sacerdote,capi,pascolo_ha,segni,scorrerie,case_bruciate,torre,pericolo,sentieri_km,strade,anno_fine,soglia,governo,id_terra,id_decide,anziani,disuguaglianza,officina,lavoro_fabbro,attrezzi,armi,recinto,case_dentro,zona_abitato,case_impalcato,divisione,eminenti,case,comuni,quota_prestigio,legittimita")
	for profilo in profili:
		for sito in d.siti:
			for seme in range(1, semi + 1):
				var r := _gioca(d, sito, profilo, seme * 31 + int(sito["n"]))
				_righe.append("%s,%s,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%s,%d,%d,%d,%d,%d,%d,%.1f,%d,%d,%.1f,%d,%d,%d,%d,%s,%.1f,%d,%d,%s,%s,%.2f,%.2f,%d,%.2f,%d,%s,%.2f,%.2f,%.1f,%d,%d,%d,%d,%d,%d,%d,%.2f,%d" % [profilo, String(sito["nome"]).replace(",", " "), seme, r["pop"], r["minima"], r["carestie"], r["gravi"], r["abbandoni"], r["scissioni"], r["pause"], r["tutorial"], r["piene"], r["granaio"], r["imparato"], r["legnaie"], r["casali"], r["nucleo"], r["poste"], r["capanni"], r["sacro"], r["bosco_sacro"], r["sacerdote"], r["capi"], r["pascolo_ha"], r["segni"], r["scorrerie"], r["case_bruciate"], r["torre"], r["pericolo"], r["sentieri_km"], r["strade"], r["anno_fine"], r["soglia"], r["governo"], r["id_terra"], r["id_decide"], r["anziani"], r["disuguaglianza"], r["officina"], r["lavoro_fabbro"], r["attrezzi"], r["armi"], r["recinto"], r["case_dentro"], r["zona_abitato"], r["case_impalcato"], r["divisione"], r["eminenti"], r["case"], r["comuni"], r["quota_prestigio"], r["legittimita"]])
	var f := FileAccess.open(file, FileAccess.WRITE)
	f.store_string("\n".join(_righe) + "\n")
	f.close()
	print("Scritto " + file)
	quit()


func _gioca(d: MappaDati, sito: Dictionary, profilo: String, seme: int) -> Dictionary:
	var sim := SimVillaggio.new(d, seme)
	sim.scorrerie_spente = _senza_scorrerie
	var caso := RandomNumberGenerator.new()
	caso.seed = seme * 104729 + (1 if profilo == "legge" else 0)
	var legge: float = {"sbaglia": 0.3, "legge": 0.8, "genere": 0.0, "casual": 0.0}[profilo]
	var genere := profilo == "genere"
	var casual := profilo == "casual"
	var p_sito := Vector2i(sito["px"])
	# Tutorial alle tappe (decisione di Fede del 26/11/2026): accesi come nella partita; le loro
	# pause si contano a parte. Chi legge e chi impara sbagliando li leggono; chi conosce il genere
	# li salta al primo; il casual ne legge un paio e poi salta.
	sim.tutorial_attivi = true
	sim.tutorial(["fondare"], "Inizio della partita")
	var tutorial := 0
	while sim.tutorial_in_attesa():
		tutorial += 1
		sim.scegli(sim.decisioni[0]["id"], "salta" if genere else "continua")
	sim.fonda(p_sito)
	var anno0 := sim.anno
	var imparato := {}
	if genere and caso.randf() < 0.5:
		imparato["piena"] = true  # ha guardato la mappa del rischio di piena
	var copertura := 0.5
	_zona(sim, copertura, imparato.has("piena"))
	var attesa_min := 20 if casual else 10
	var attesa_var := 31 if casual else 21
	var prossimo := attesa_min + caso.randi() % attesa_var
	# La legnaia: chi conosce il genere la fa subito vicino al bosco; gli altri provano il tasto
	# nuovo, chi più chi meno (il casual dove capita).
	if genere:
		AiutiGiocatori.costruisci_legnaia(sim, caso, 0.9)
	elif caso.randf() < (0.7 if casual else 0.5):
		AiutiGiocatori.costruisci_legnaia(sim, caso, 0.4 if casual else 0.5)
	_edifici_iniziali(sim, caso, genere, casual)
	var gravi := 0
	var scissioni := 0
	var pause := 0
	var minima := sim.pop
	var granaio_anno := -1
	var granaio_voluto := false
	# Luogo sacro e bosco sacro: le tappe li annunciano; chi conosce il genere li fa subito.
	var sacro_voluto := false
	var bosco_voluto := false
	var pascolo_voluto := false
	var torre_voluta := false
	var officina_voluta := false
	var recinto_voluto := false
	var abitato_voluto := false
	var lavoro_scelto := ""
	var caccia_spenta_anno := -1
	var raccolto_provato := false
	while not sim.finito and sim.anno < _anno_limite:
		while sim.in_attesa():
			var dec: Dictionary = sim.decisioni[0]
			if dec["tipo"] == "tutorial":
				tutorial += 1
				# La scheda del metallo invoglia a provare l'officina (chi legge quasi sempre).
				if String(dec.get("chiave", "")) == "fabbro" and caso.randf() < (0.4 if casual else 0.5 + 0.5 * legge):
					officina_voluta = true
				if String(dec.get("chiave", "")) == "recinto" and caso.randf() < (0.3 if casual else 0.5 + 0.5 * legge):
					recinto_voluto = true
				if String(dec.get("chiave", "")) == "abitato" and caso.randf() < (0.3 if casual else 0.5 + 0.5 * legge):
					abitato_voluto = true
				sim.scegli(dec["id"], "salta" if genere or (casual and tutorial >= 3) else "continua")
				continue
			# Il riepilogo dell'evento soglia (prima "fine", ora "epoca") non si conta, come prima.
			if dec["tipo"] != "fine" and dec["tipo"] != "epoca":
				pause += 1
			if dec["tipo"] == "piena" and not casual and caso.randf() < 0.5 + 0.4 * legge:
				# La finestra spiega dove arrivano le piene: si impara a evitare le terre rosse.
				imparato["piena"] = true
			sim.scegli(dec["id"], _a_caso(dec, caso) if casual else _istinto(dec, caso, legge))
		if not sim.fondato:
			# Dopo un abbandono si rifonda nello stesso sito (il giocatore ci riprova).
			sim.fonda(p_sito)
			_zona(sim, copertura, imparato.has("piena"))
			AiutiGiocatori.costruisci_legnaia(sim, caso, 0.9 if genere else 0.5)
			_edifici_iniziali(sim, caso, genere, casual)
		var eta := sim.anno - anno0
		# Le notifiche delle tappe: un tasto nuovo invoglia a provarlo.
		while not sim.avvisi.is_empty():
			var a: Dictionary = sim.avvisi.pop_front()
			var t := String(a["testo"])
			if t.contains("granaio"):
				granaio_voluto = genere or caso.randf() < (0.3 if casual else 0.6)
			if t.contains("luogo sacro"):
				sacro_voluto = genere or caso.randf() < (0.3 if casual else 0.6)
			if t.contains("officina del fabbro") or t.contains("Officina del fabbro"):
				officina_voluta = officina_voluta or genere or caso.randf() < (0.4 if casual else (0.8 if legge > 0.5 else 0.6))
			if t.contains("il pascolo"):
				pascolo_voluto = genere or caso.randf() < (0.4 if casual else 0.6)
			if t.contains("bosco sacro"):
				bosco_voluto = genere or caso.randf() < (0.2 if casual else 0.5)
			# Scorrerie: i segni (o la scheda saltata della torre) invogliano a provare la torre.
			if t.contains("Torre di avvistamento") or t.contains("Fuochi") or t.contains("Tracce") or t.contains("fuggiaschi"):
				torre_voluta = torre_voluta or genere or caso.randf() < (0.15 if casual else 0.35)
			if t.contains("si divide"):
				scissioni += 1
		if eta >= prossimo and sim.fondato:
			prossimo = eta + attesa_min + caso.randi() % attesa_var
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
					elif (c.contains("Senza legnaia") or c.contains("il bosco è finito") or c.contains("vanno lontano") or c.contains("legnaia nuova") or c.contains("legnaia più vicina") or c.contains("non ci sono più alberi") or c.contains("non restano alberi")) and sim.legnaie.size() < 4:
						AiutiGiocatori.costruisci_legnaia(sim, caso, 0.7)
						imparato["legnaia"] = true
					elif c.contains("finché non si erige il luogo sacro"):
						sacro_voluto = true
						imparato["luogo_sacro"] = true
					elif c.contains("Serve più pascolo") or c.contains("Stendi il pascolo"):
						AiutiGiocatori.stendi_pascolo(sim, caso, 0.7, 8.0)
						imparato["pascolo"] = true
					elif c.contains("Rischio di scorrerie alto") or c.contains("Scorreria del"):
						torre_voluta = true
						imparato["torre"] = true
					elif c.contains("bosco sacro più grande"):
						AiutiGiocatori.stendi_bosco_sacro(sim, caso, 0.7, 6.0)
						imparato["bosco_sacro"] = true
					elif (c.contains("Senza posta di caccia") or c.contains("Attorno a una posta")) and sim.poste.size() < 4:
						AiutiGiocatori.costruisci_edificio_risorse(sim, caso, 0.7, true)
						imparato["posta"] = true
					elif (c.contains("Senza capanno da pesca") or c.contains("il pesce è scarso")) and sim.capanni.size() < 4:
						AiutiGiocatori.costruisci_edificio_risorse(sim, caso, 0.7, false)
						imparato["capanno"] = true
			# Chi conosce il genere: legnaia in più quando la legna scarseggia, granaio appena si può.
			if genere and (sim.legnaie.is_empty() or AiutiGiocatori.legna_scarsa(sim)) and sim.legnaie.size() < 4:
				AiutiGiocatori.costruisci_legnaia(sim, caso, 0.9)
			# Chi conosce il genere: un'altra posta o un altro capanno quando quelli che ha non bastano.
			if genere:
				for caccia in [true, false]:
					if AiutiGiocatori.risorsa_scarsa(sim, caccia) and (sim.poste if caccia else sim.capanni).size() < 3:
						AiutiGiocatori.costruisci_edificio_risorse(sim, caso, 0.9, caccia)
			# Senza leggere, ma provando: legna rossa e nessuna legnaia, si prova il tasto.
			if not genere and sim.legnaie.is_empty() and sim.legna < SimVillaggio.COSTO_CASA and caso.randf() < (0.3 if casual else 0.4):
				AiutiGiocatori.costruisci_legnaia(sim, caso, 0.4 if casual else 0.5)
			# Senza leggere: guardando la mappa a volte si vede la zona piena e la si allarga.
			if sim.zona_piena and caso.randf() < (0.95 if genere else (0.3 if casual else 0.5)):
				copertura = minf(1.0, copertura + 0.1)
				_zona(sim, copertura, imparato.has("piena"))
			# La caccia spenta si dimentica: dopo un po' la si riaccende.
			if caccia_spenta_anno >= 0 and eta - caccia_spenta_anno > 50 and not sim.fonti["caccia"]:
				sim.imposta_fonte("caccia", true)
				caccia_spenta_anno = -1
			if sacro_voluto and sim.luogo_sacro.x < 0 and sim.sbloccato("luogo_sacro") and sim.legna >= SimVillaggio.COSTO_LUOGO_SACRO:
				AiutiGiocatori.costruisci_luogo_sacro(sim)
			# Recinto e zona dell'abitato (epoca 2): chi conosce il genere appena si può; gli altri dopo
			# una scorreria o leggendo le schede.
			if sim.sbloccato("recinto") and not recinto_voluto and caso.randf() < (1.0 if genere else (0.3 if sim.scorrerie_epoca2 > 0 else 0.03)):
				recinto_voluto = true
			if recinto_voluto and not sim.recinto_tracciato() and sim.sbloccato("recinto") and sim.legna + sim.ultima_legna >= 30.0:
				AiutiGiocatori.traccia_recinto(sim, caso, 0.9 if genere else (0.3 if casual else (0.7 if legge > 0.5 else 0.5)))
			if sim.sbloccato("abitato") and not abitato_voluto and caso.randf() < (1.0 if genere else 0.1):
				abitato_voluto = true
			if abitato_voluto and sim.zona_abitato.is_empty() and sim.sbloccato("abitato"):
				AiutiGiocatori.stendi_abitato(sim, caso, 0.9 if genere else (0.3 if casual else 0.6))
			# Officina del fabbro (epoca 2): chi conosce il genere subito e nel posto giusto.
			if sim.sbloccato("officina") and not officina_voluta and caso.randf() < (1.0 if genere else 0.05):
				officina_voluta = true
			if officina_voluta and sim.officine.is_empty() and sim.sbloccato("officina") and sim.legna + sim.ultima_legna >= SimVillaggio.COSTO_OFFICINA:
				AiutiGiocatori.costruisci_officina(sim, caso, 0.9 if genere else (0.2 if casual else (0.6 if legge > 0.5 else 0.4)))
			# Cosa forgia: chi legge sceglie attrezzi e passa alle armi dopo una scorreria; chi conosce
			# il genere fa metà e metà se le scorrerie arrivano; il casual prova un tasto a caso.
			if not sim.officine.is_empty() and sim.officina_pronta(sim.officine[0]):
				var voluto := lavoro_scelto
				if lavoro_scelto == "":
					voluto = ["attrezzi", "armi", "meta"][caso.randi() % 3] if casual else "attrezzi"
				elif sim.stat["scorrerie"] > 0 and lavoro_scelto == "attrezzi" and not casual and caso.randf() < (0.05 if genere else 0.02 * (1.0 + legge)):
					voluto = "meta" if genere else "armi"
				if voluto != lavoro_scelto:
					lavoro_scelto = voluto
					sim.scegli_lavoro_officina(0, voluto)
			if torre_voluta and sim.torre.x < 0 and sim.sbloccato("torre") and sim.legna >= SimVillaggio.COSTO_TORRE + SimVillaggio.COSTO_CASA:
				AiutiGiocatori.costruisci_torre(sim, caso, 0.9 if genere else (0.3 if casual else 0.6))
			if pascolo_voluto and sim.pascolo.is_empty() and sim.sbloccato("pascolo"):
				AiutiGiocatori.stendi_pascolo(sim, caso, 0.9 if genere else (0.2 if casual else 0.5), 15.0 if genere else 8.0)
			# Chi conosce il genere allarga il pascolo quando l'erba finisce.
			if genere and not sim.pascolo.is_empty() and sim.erba < 0.05 and sim.pascolo.size() * SimVillaggio.AREA_PIXEL_HA < 40.0:
				AiutiGiocatori.stendi_pascolo(sim, caso, 0.9, 8.0)
			if bosco_voluto and sim.bosco_sacro.is_empty() and sim.sbloccato("bosco_sacro"):
				AiutiGiocatori.stendi_bosco_sacro(sim, caso, 0.9 if genere else (0.3 if casual else 0.5), 10.0 if genere else 6.0)
			if granaio_voluto and sim.granaio.x < 0 and sim.sbloccato("granaio") and sim.legna >= SimVillaggio.COSTO_GRANAIO:
				var c0 := sim.mondo_di_px(sim.centro)
				for prova in [Vector2(60, 0), Vector2(-60, 0), Vector2(0, 60), Vector2(0, -60), Vector2(100, 100)]:
					if sim.costruisci_granaio(c0 + prova) == "":
						granaio_anno = eta
						break
			# Sentieri verso i posti di lavoro lontani (chi conosce il genere sempre, gli altri meno).
			AiutiGiocatori.traccia_sentieri_lavoro(sim, caso, 0.9 if genere else (0.15 if casual else 0.4))
			# Il raccolto alle famiglie, appena si apre: si prova una volta, metà dei giocatori.
			if not raccolto_provato and sim.sbloccato("raccolto"):
				raccolto_provato = true
				if caso.randf() < (0.3 if casual else 0.5):
					sim.imposta_politica("raccolto", "famiglie")
		var prima: int = sim.stat["carestie"] + int(sim.stat.get("flessioni", 0))
		var pop_prima := sim.pop
		sim.passo()
		if sim.stat["carestie"] + int(sim.stat.get("flessioni", 0)) > prima and sim.pop < pop_prima * 0.9:
			gravi += 1
		if sim.fondato:
			minima = minf(minima, sim.pop)
	return {"pop": roundi(sim.pop), "minima": roundi(minima), "carestie": sim.stat["carestie"] + int(sim.stat.get("flessioni", 0)), "gravi": gravi,
		"abbandoni": sim.stat["abbandoni"], "scissioni": scissioni, "pause": pause, "tutorial": tutorial, "piene": sim.stat["piene"],
		"granaio": granaio_anno, "imparato": " ".join(imparato.keys()), "legnaie": sim.legnaie.size(), "casali": sim.casali.size(), "nucleo": roundi(sim.abitanti_nucleo()),
		"poste": sim.poste.size(), "capanni": sim.capanni.size(),
		"sacro": 1 if sim.luogo_sacro_pronto() else 0, "bosco_sacro": snappedf(sim.ettari_bosco_sacro(), 0.1), "sacerdote": roundi(sim.consenso["sacerdote"]) if sim.sacerdote_attivo else -1,
		"capi": roundi(sim.capi), "pascolo_ha": snappedf(sim.pascolo.size() * SimVillaggio.AREA_PIXEL_HA, 0.1),
		"segni": sim.stat["segni"], "scorrerie": sim.stat["scorrerie"], "case_bruciate": sim.stat["case_bruciate"], "torre": 1 if sim.torre_pronta() else 0, "pericolo": sim.politica("pericolo"),
		"sentieri_km": sim.sentieri.size() * sim.dati.metri_per_px / 1000.0, "strade": sim.strade.size(),
		"anno_fine": sim.anno, "soglia": sim.soglia_scelta, "governo": sim.primo_governo.replace(" ", "_"),
		"id_terra": float(sim.identita["terra"]), "id_decide": float(sim.identita["decide"]), "anziani": roundi(sim.consenso["anziani"]), "disuguaglianza": sim.disuguaglianza,
		"officina": 1 if not sim.officine.is_empty() else 0, "lavoro_fabbro": lavoro_scelto if lavoro_scelto != "" else "-", "attrezzi": sim.attrezzi, "armi": sim.armi,
		"recinto": 1.0 if sim.recinto_pronto() else (0.5 if sim.recinto_tracciato() else 0.0), "case_dentro": sim.case_dentro(), "zona_abitato": sim.zona_abitato.size(),
		"case_impalcato": sim.case.filter(func(l: Vector2i) -> bool: return sim.casa_su_impalcato(l)).size(),
		# Eminenti e comuni (epoca 2, 27/11/2026): anno della divisione (0 se non c'è stata).
		"divisione": sim.anno_divisione if sim.famiglie_divise else 0, "eminenti": sim.eminenti.size(), "case": sim.case.size(),
		"comuni": roundi(sim.consenso["famiglie"]), "quota_prestigio": sim.quota_prestigio, "legittimita": roundi(sim.legittimita)}


## Posta di caccia e capanno da pesca all'inizio (decisioni di Fede del 25/11/2026): chi conosce il
## genere li fa subito, nel punto giusto; gli altri provano i tasti nuovi, chi più chi meno (il
## casual dove capita).
func _edifici_iniziali(sim: SimVillaggio, caso: RandomNumberGenerator, genere: bool, casual: bool) -> void:
	for caccia in [true, false]:
		if genere:
			AiutiGiocatori.costruisci_edificio_risorse(sim, caso, 0.9, caccia)
		elif caso.randf() < (0.5 if casual else 0.4):
			AiutiGiocatori.costruisci_edificio_risorse(sim, caso, 0.2 if casual else 0.5, caccia)


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


func _a_caso(dec: Dictionary, caso: RandomNumberGenerator) -> String:
	var opzioni: Array = dec["opzioni"]
	return opzioni[caso.randi() % opzioni.size()]["id"]


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
		"pericolo":
			# Chi legge protegge di più; d'istinto si raccolgono gli animali o si veglia.
			var x := caso.randf()
			return "avanti" if x < 0.35 - 0.2 * legge else ("raccogliere" if x < 0.7 else "vegliare")
	return opzioni[caso.randi() % opzioni.size()]["id"]
