extends SceneTree
## Verifiche sulla simulazione del villaggio (SimVillaggio), senza grafica: una partita di
## 500 anni per ogni sito di fondazione, giocata da un giocatore automatico semplice.
## Uso: godot --headless --path gioco -s res://test/verifica_villaggio.gd

var _errori := 0


func controlla(cond: bool, testo: String) -> void:
	print(("OK  " if cond else "ERRORE  ") + testo)
	if not cond:
		_errori += 1


## Giocatore automatico: tiene i campi un po' sopra le braccia disponibili (i più fertili a
## portata), risponde alle decisioni con la prima opzione, costruisce il granaio quando può.
func _gioca(sim: SimVillaggio, sito: Vector2i, scelta_presagi := "") -> Dictionary:
	sim.fonda(sito)
	var minimo_pop := sim.pop
	var massimo_case := 0
	var case_sbagliate := 0
	while not sim.finito:
		while sim.in_attesa():
			var d: Dictionary = sim.decisioni[0]
			var o: String = d["opzioni"][0]["id"]
			if scelta_presagi != "" and d["tipo"] in ["sorgenti", "cometa"]:
				o = scelta_presagi
			sim.scegli(d["id"], o)
		if not sim.fondato:
			sim.fonda(sito)
		if sim.anno % 5 == 0:
			# Giocatore automatico: la zona agricola copre tutto il contado (che cresce con gli
			# abitanti); i campi li dissodano le famiglie.
			if sim.anno % 25 == 0 or sim.zona.is_empty():
				var tutta: Array[Vector2i] = []
				var r := sim.raggio_campi()
				for dy in range(-r, r + 1):
					for dx in range(-r, r + 1):
						tutta.append(sim.centro + Vector2i(dx, dy))
				sim.aggiungi_zona(tutta)
			if sim.granaio.x < 0 and sim.cibo > 40.0:
				var c := sim.mondo_di_px(sim.centro)
				for prova in [Vector2(60, 0), Vector2(-60, 0), Vector2(0, 60), Vector2(0, -60), Vector2(100, 100)]:
					if sim.costruisci_granaio(c + prova) == "":
						break
		sim.passo()
		if sim.fondato:
			minimo_pop = minf(minimo_pop, sim.pop)
			massimo_case = maxi(massimo_case, sim.case.size())
			for l in sim.case:
				var w := sim.centro_lotto(l)
				if not sim.edificabile(sim.px(sim.px_da_mondo(w.x, w.y))):
					case_sbagliate += 1
	return {"pop": sim.pop, "minimo": minimo_pop, "case": massimo_case, "sbagliate": case_sbagliate, "abbandoni": sim.stat["abbandoni"], "carestie": sim.stat["carestie"], "piene": sim.stat["piene"]}


func _initialize() -> void:
	var d: MappaDati = load("res://mappe/pedecollinare/mappa.res")
	var sim := SimVillaggio.new(d, 7)
	# Valutazione dei siti.
	for s in d.siti:
		var v := sim.valuta_sito(Vector2i(s["px"]))
		print("   sito %d %s: acqua %s, fertilità %s, piena %s, difesa %s, aria %s" % [s["n"], s["nome"], v["acqua"][0], v["fertilita"][0], v["piena"][0], v["difesa"][0], v["aria"][0]])
	controlla(sim.valuta_sito(Vector2i(d.siti[0]["px"]))["sito"] != null, "la valutazione riconosce i siti della mappa")
	controlla(not sim.puo_fondare(Vector2i(45, 100)) or sim.edificabile(sim.px(Vector2i(45, 100))), "non si fonda sull'acqua")
	# Azioni.
	var t := SimVillaggio.new(d, 3)
	var c := Vector2i(d.siti[0]["px"])
	t.fonda(c)
	controlla(t.fondato and t.pop == 30.0 and t.case.size() == 6, "fondazione: 30 abitanti, 6 case (una ogni 5 abitanti) (%d)" % t.case.size())
	controlla(t.motivo_campo(c + Vector2i(60, 0)) != "", "un campo troppo lontano non si può fare")
	var lista: Array[Vector2i] = [c + Vector2i(3, 0), c + Vector2i(4, 0)]
	controlla(t.aggiungi_campi(lista) == 2 and t.campi.size() == 2, "due campi vicini al villaggio")
	var sentiero := t.traccia_sentiero(c + Vector2i(0, -30))
	controlla(sentiero == "" and t.sentieri.size() == 30, "un sentiero di 1,2 km verso nord (%s)" % sentiero)
	# Contado (decisione di Fede): 400 m alla fondazione, cresce con gli abitanti fino a 800 m; i
	# sentieri non lo allargano ma rendono di più i campi che servono.
	controlla(is_equal_approx(t.raggio_contado(), 400.0) and t.motivo_campo(c + Vector2i(0, -10)) == "" and t.motivo_campo(c + Vector2i(0, -11)) != "", "contado di 400 m alla fondazione")
	controlla(t.motivo_campo(c + Vector2i(5, -28)) != "", "il sentiero non allarga il contado")
	var pop0 := t.pop
	t.pop = 130.0
	controlla(is_equal_approx(t.raggio_contado(), 800.0) and t.motivo_campo(c + Vector2i(0, -19)) == "", "con 130 abitanti il contado arriva a 800 m")
	t.pop = 1000.0
	controlla(is_equal_approx(t.raggio_contado(), 800.0), "il contado non supera 800 m (limite di cammino)")
	t.pop = pop0
	var lungo := c + Vector2i(1, -9)
	var lontano_dal_sentiero := c + Vector2i(9, -2)
	t.aggiungi_campi([lungo, lontano_dal_sentiero])
	controlla(t.servito(t.px(lungo)) and not t.servito(t.px(lontano_dal_sentiero)), "i campi lungo un sentiero collegato sono serviti, gli altri no")
	# Economia mista: caccia e pesca danno cibo; cacciando, la selvaggina cala.
	var r0 := t.risorse_attorno(c)
	controlla(r0["bosco"] > 0.0 and r0["acqua"] > 0.0, "attorno al sito ci sono boschi e acque (%d, %d)" % [roundi(r0["bosco"]), roundi(r0["acqua"])])
	var v := t.valuta_sito(c)
	controlla(v.has("bosco") and v.has("pesca"), "la valutazione del sito dice boschi e pesca: %s, %s" % [v["bosco"][0], v["pesca"][0]])
	# Indicatori di caccia e pesca (richiesta di Fede): offerta dell'anno e caccia eccessiva.
	t.decisioni.clear()
	t.avvisi.clear()
	t.selvaggina = 0.3
	t.passo()
	var avvisato := t.avvisi.any(func(x: Dictionary) -> bool: return String(x["testo"]).begins_with("Si caccia troppo"))
	controlla(t.offerta_caccia > 0.0 and avvisato and not t.in_attesa(), "con poca selvaggina arriva la notifica \"si caccia troppo\", senza fermare il gioco")
	t.avvisi.clear()
	# Fonti di cibo: spenta la caccia non dà cibo e la selvaggina si riprende; almeno una resta.
	controlla(t.imposta_fonte("caccia", false) and not t.imposta_fonte("caccia", false), "la caccia si spegne (una volta sola)")
	var s0 := t.selvaggina
	t.decisioni.clear()
	t.passo()
	controlla(t.ultima_caccia == 0.0 and t.selvaggina > s0, "con la caccia spenta non si caccia e la selvaggina cresce")
	t.imposta_fonte("pesca", false)
	controlla(not t.imposta_fonte("agricoltura", false) and t.fonti["agricoltura"], "l'ultima fonte accesa non si spegne")
	t.imposta_fonte("caccia", true)
	t.imposta_fonte("pesca", true)
	t.avvisi.clear()
	t.cibo = 45.0
	controlla(t.motivo_granaio(t.mondo_di_px(c) + Vector2(60, 0)) == "" and t.motivo_granaio(t.mondo_di_px(c) + Vector2(900, 0)) != "", "il granaio va vicino al centro (con %d di cibo si può)" % roundi(t.cibo))
	# Politiche: cambiarle costa consenso, gli stranieri seguono la regola in vigore.
	controlla(t.politica("raccolto") == "comune" and t.politica("stranieri") == "caso", "politiche iniziali: raccolto in comune, stranieri caso per caso")
	var b0 := t.bonus
	controlla(t.imposta_politica("raccolto", "famiglie") and t.bonus < b0, "cambiare una politica costa un po' di consenso")
	controlla(not t.imposta_politica("raccolto", "famiglie") and not t.imposta_politica("stranieri", "boh"), "valori uguali o sconosciuti non cambiano nulla")
	var p0 := t.pop
	t.imposta_politica("stranieri", "aperta")
	t._arrivo_stranieri()
	controlla(t.pop > p0 and t.anni_sapere > 0 and not t.in_attesa(), "accoglienza aperta: gli stranieri restano senza fermare il tempo")
	p0 = t.pop
	t.imposta_politica("stranieri", "chiusa")
	t._arrivo_stranieri()
	controlla(t.pop == p0 and not t.in_attesa(), "accoglienza chiusa: vengono mandati via")
	t.imposta_politica("stranieri", "caso")
	t._arrivo_stranieri()
	controlla(t.in_attesa() and t.decisioni[0]["tipo"] == "stranieri", "caso per caso: il tempo si ferma e si decide")
	t.scegli(t.decisioni[0]["id"], "accogliere")
	controlla(t.pop > p0 and not t.in_attesa(), "accolti dopo la decisione")
	# Tecniche dei campi e ammodernamento (decisione di Fede): i campi vecchi restano, quelli nuovi
	# nascono con la tecnica dell'epoca e rendono di più; l'ammodernamento sovrascrive il tipo.
	controlla(t.campi_da_ammodernare() == 0, "nel villaggio non c'è niente da ammodernare")
	var vecchio: int = t.campi[0]
	var resa_zappa := t._resa(vecchio)
	t.tecnica_corrente = 1
	controlla(t.campi_da_ammodernare() == t.campi.size() and t.tecnica_campo(vecchio) == 0, "al cambio di tecnica i campi vecchi restano com'erano")
	var nuovo_px := c + Vector2i(0, 4)
	t.aggiungi_campi([nuovo_px])
	controlla(t.tecnica_campo(t.px(nuovo_px)) == 1, "un campo nuovo nasce con la tecnica dell'epoca")
	t.cibo = 1000.0
	var n_campi := t.campi.size()
	t.imposta_ammodernamento("agricolo", true)
	t._ammoderna()
	controlla(t.campi.size() == n_campi and t.campi_da_ammodernare() < n_campi - 1 and t.cibo < 1000.0, "l'ammodernamento rifà i campi vecchi pagando cibo, senza aggiungerne")
	controlla(t.tecnica_campo(vecchio) == 0 or t._resa(vecchio) > resa_zappa, "un campo ammodernato rende di più")
	for k in 50:
		t._ammoderna()
	controlla(t.campi_da_ammodernare() == 0 and t._resa(vecchio) > resa_zappa, "alla fine tutti i campi sono rifatti e rendono di più")
	t.tecnica_corrente = 0
	t.imposta_ammodernamento("agricolo", false)
	# Piene (decisione di Fede): non fermano mai il gioco; quelle di stagione non toccano le case.
	var case_prima := t.case.size()
	for k in 30:
		t._piena(false)
	controlla(t.case.size() == case_prima and not t.in_attesa(), "le piene di stagione non distruggono case e non fermano il gioco")
	t._piena(true)
	controlla(not t.in_attesa(), "nemmeno una piena disastrosa ferma il gioco")
	t.avvisi.clear()
	# Partite intere.
	var sopravvissuti := 0
	for s in d.siti:
		var sim2 := SimVillaggio.new(d, 100 + int(s["n"]))
		var r := _gioca(sim2, Vector2i(s["px"]))
		print("   sito %d %s: %d abitanti dopo 500 anni (minimo %d), fino a %d case, carestie %d, piene %d, abbandoni %d" % [s["n"], s["nome"], roundi(r["pop"]), roundi(r["minimo"]), r["case"], r["carestie"], r["piene"], r["abbandoni"]])
		if r["abbandoni"] == 0:
			sopravvissuti += 1
		controlla(r["sbagliate"] == 0, "sito %d: nessuna casa sull'acqua o nella palude" % s["n"])
	controlla(sopravvissuti >= 4, "quasi tutti i siti si possono abitare per cinque secoli (%d su 6)" % sopravvissuti)
	# Stessa partita con lo stesso seme: stesso risultato.
	var a1 := _gioca(SimVillaggio.new(d, 42), c)
	var a2 := _gioca(SimVillaggio.new(d, 42), c)
	controlla(a1["pop"] == a2["pop"] and a1["carestie"] == a2["carestie"], "la simulazione è deterministica con lo stesso seme")
	print("Verifica completata: " + ("nessun errore" if _errori == 0 else "%d errori" % _errori))
	quit(1 if _errori > 0 else 0)
