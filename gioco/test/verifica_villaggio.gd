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
			var voluti := int(sim.pop * 0.55 / 3.0 * SimVillaggio.AREA_CELLA * 1.1)
			if sim.campi.size() < voluti:
				var candidati: Array[Vector2i] = []
				var r := sim.raggio_campi()
				for dy in range(-r, r + 1):
					for dx in range(-r, r + 1):
						var p := sim.centro + Vector2i(dx, dy)
						if p.x >= 0 and p.y >= 0 and p.x < sim.n and p.y < sim.n and not sim.campi.has(sim.px(p)) and sim.motivo_campo(p) == "":
							candidati.append(p)
				candidati.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
					return sim.fert(sim.px(a)) - SimVillaggio.cheb(a, sim.centro) * 0.01 > sim.fert(sim.px(b)) - SimVillaggio.cheb(b, sim.centro) * 0.01)
				sim.aggiungi_campi(candidati.slice(0, voluti - sim.campi.size()))
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
	controlla(t.fondato and t.pop == 30.0 and t.case.size() == 4, "fondazione: 30 abitanti, 4 case (%d)" % t.case.size())
	controlla(t.motivo_campo(c + Vector2i(60, 0)) != "", "un campo troppo lontano non si può fare")
	var lista: Array[Vector2i] = [c + Vector2i(3, 0), c + Vector2i(4, 0)]
	controlla(t.aggiungi_campi(lista) == 2 and t.campi.size() == 2, "due campi vicini al villaggio")
	var sentiero := t.traccia_sentiero(c + Vector2i(0, -30))
	controlla(sentiero == "" and t.sentieri.size() == 30, "un sentiero di 1,2 km verso nord (%s)" % sentiero)
	controlla(t.motivo_campo(c + Vector2i(5, -28)) == "", "il sentiero allunga il raggio dei campi")
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
