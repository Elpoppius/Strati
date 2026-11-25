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
var _caso_giocatore := RandomNumberGenerator.new()


## Capanno da pesca e Posta di caccia (decisioni di Fede del 25/11/2026): senza edificio un terzo,
## con l'edificio pieno; il capanno solo sulla riva, la posta al margine del bosco; pesce e
## selvaggina locali, divisi tra edifici vicini, che calano se se ne prende troppo e si riprendono.
func _verifica_capanno_e_posta(d: MappaDati) -> void:
	# Sbocco del fiume: fiume e bosco vicini.
	var s := SimVillaggio.new(d, 7)
	var c := Vector2i(d.siti[1]["px"])
	s.fonda(c)
	var cm := s.mondo_di_px(c)
	# Il punto di riva e il punto di margine più vicini al centro (griglia di 40 m).
	var riva := {}
	var margine := {}
	for r in range(0, 1000, 40):
		for k in 24:
			var q := cm + Vector2.from_angle(TAU * k / 24.0) * r
			if riva.is_empty():
				var a := s.posa_capanno(q)
				if a["motivo"] == "":
					riva = a
			if margine.is_empty():
				var b := s.posa_posta(q)
				if b["motivo"] == "":
					margine = b
	controlla(not riva.is_empty(), "allo sbocco del fiume c'è una riva per il capanno")
	controlla(not margine.is_empty(), "allo sbocco del fiume c'è un margine del bosco per la posta")
	if riva.is_empty() or margine.is_empty():
		return
	var pr: Vector2 = riva["punto"]
	controlla(absf(d.distanza_riva(pr.x, pr.y) - 2.0) <= 1.5 and d.palude_in(pr.x, pr.y) <= 0.4, "il capanno si aggancia alla riva, a circa 2 m dall'acqua e fuori dalla palude (%.1f m, %s)" % [d.distanza_riva(pr.x, pr.y), riva["acqua"]])
	var verso: Vector2 = riva["verso"]
	controlla(d.distanza_riva(pr.x + verso.x * 6.0, pr.y + verso.y * 6.0) < d.distanza_riva(pr.x, pr.y), "il capanno guarda l'acqua")
	var lontano := pr + verso * -200.0
	controlla(s.posa_capanno(lontano)["motivo"] != "", "lontano dalla riva il capanno non si posa: «%s»" % s.posa_capanno(lontano)["motivo"])
	var pm: Vector2 = margine["punto"]
	var vb: Vector2 = margine["verso"]
	controlla(d.bosco_in(pm.x + vb.x * 20.0, pm.y + vb.y * 20.0) > d.bosco_in(pm.x, pm.y), "la posta ha il bosco alle spalle")
	# Senza edifici: un terzo. Si confronta con l'offerta piena di tutti i riquadri attorno.
	var piena_caccia := 0.0
	for cb in s.celle_bosco:
		var w := 1.0 - s.centro_riquadro(cb).distance_to(cm) / s.raggio_famiglie()
		if w > 0.0:
			piena_caccia += w * float(s.celle_bosco[cb]) * SimVillaggio.RESA_BOSCO
	s.decisioni.clear()
	s.passo()
	controlla(absf(s.offerta_caccia - piena_caccia * SimVillaggio.RESA_SENZA_EDIFICIO) < piena_caccia * 0.05, "senza posta la caccia offre un terzo (%.1f di %.1f)" % [s.offerta_caccia, piena_caccia])
	var caccia_senza := s.offerta_caccia
	var pesca_senza := s.offerta_pesca
	# Con gli edifici: in costruzione non rendono, finiti sì.
	controlla(s.costruisci_capanno(pr) == "" and s.costruisci_posta(pm) == "", "capanno e posta si costruiscono")
	controlla(s.costruisci_capanno(pr) != "", "due capanni non vanno nello stesso punto")
	controlla(float(s.capanni[0]["offerta"]) == 0.0 and s.stato_edificio(s.capanni[0]).begins_with("in costruzione"), "il capanno in costruzione non pesca")
	for k in SimVillaggio.ANNI_CANTIERE_RISORSE + 1:
		s.decisioni.clear()
		s.passo()
	controlla(s.offerta_pesca > pesca_senza * 1.3 and float(s.capanni[0]["offerta"]) > 0.0, "con il capanno si pesca di più (%.1f → %.1f)" % [pesca_senza, s.offerta_pesca])
	controlla(s.offerta_caccia > caccia_senza * 1.3 and float(s.poste[0]["offerta"]) > 0.0, "con la posta si caccia di più (%.1f → %.1f)" % [caccia_senza, s.offerta_caccia])
	# Pesce locale: un capanno solo lo fa calare poco, sei ammassati nello stesso tratto di più; poi
	# lasciato stare si riprende.
	var prova_pesce := func(quanti: int) -> float:
		var u := SimVillaggio.new(d, 7)
		u.fonda(c)
		for k in quanti:
			u.capanni.append({"punto": pr + Vector2(k * 3.0, 0), "verso": verso, "acqua": riva["acqua"], "cantiere": 0, "preso": 0.0, "offerta": 0.0})
		u._conta_riquadri()
		# Ogni anno: ripresa, poi i capanni pescano fino alla loro capacità.
		for k in 30:
			u._riprendi_scorte(u.scorta_pesce, SimVillaggio.RIPRESA_PESCE)
			u._caccia_o_pesca(false, SimVillaggio.CAPACITA_CAPANNO * quanti)
		return u.scorta_attorno(u.capanni[0])
	var uno: float = prova_pesce.call(1)
	var sei: float = prova_pesce.call(6)
	controlla(sei < uno - 0.1, "troppi capanni nello stesso tratto fanno calare il pesce (uno: %d%%, sei: %d%%)" % [roundi(uno * 100.0), roundi(sei * 100.0)])
	var v := SimVillaggio.new(d, 7)
	v.fonda(c)
	v.capanni.append({"punto": pr, "verso": verso, "acqua": riva["acqua"], "cantiere": 0, "preso": 0.0, "offerta": 0.0})
	v._conta_riquadri()
	for cq in v.celle_acqua:
		v.scorta_pesce[cq] = 0.2
	var prima: float = v.scorta_attorno(v.capanni[0])
	for k in 10:
		v._riprendi_scorte(v.scorta_pesce, SimVillaggio.RIPRESA_PESCE)
	controlla(v.scorta_attorno(v.capanni[0]) > prima + 0.4, "lasciato stare, il pesce si riprende in qualche anno (%d%% → %d%%)" % [roundi(prima * 100.0), roundi(v.scorta_attorno(v.capanni[0]) * 100.0)])
	# Due poste vicine si dividono la selvaggina: ognuna rende meno di una posta sola.
	var a1 := s.stima_edificio({"punto": pm + Vector2(30, 0), "cantiere": 0})
	controlla(int(a1["vicini"]) == 1 and float(a1["resa"]) <= float(s.poste[0]["offerta"]) + 0.01, "una posta accanto a un'altra si divide la selvaggina (%.1f)" % a1["resa"])
	# Demolire toglie gli edifici.
	var esito := s.demolisci(pr, 10.0)
	controlla(esito.get("capanni", 0) == 1 and s.capanni.is_empty(), "il capanno si demolisce")


func _gioca(sim: SimVillaggio, sito: Vector2i, scelta_presagi := "") -> Dictionary:
	_caso_giocatore.seed = 12345
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
			if sim.legnaie.is_empty() or (AiutiGiocatori.legna_scarsa(sim) and sim.legnaie.size() < 3):
				AiutiGiocatori.costruisci_legnaia(sim, _caso_giocatore, 0.8)
			if sim.granaio.x < 0 and sim.sbloccato("granaio") and sim.legna >= SimVillaggio.COSTO_GRANAIO:
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
	# Selvaggina locale (decisione di Fede del 25/11/2026): si svuotano le scorte dei boschi attorno.
	for cb in t.celle_bosco:
		t.scorta_selvaggina[cb] = 0.2
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
	# Tappe (decisione di Fede del 25/11/2026): il granaio e la divisione del raccolto si aprono a 60
	# abitanti, e restano aperti anche se gli abitanti calano.
	controlla(t.tappa == 0 and not t.sbloccato("granaio") and t.motivo_granaio(t.mondo_di_px(c) + Vector2(60, 0)) != "" and not t.imposta_politica("raccolto", "famiglie"), "alla fondazione granaio e divisione del raccolto sono ancora chiusi")
	var pop_t := t.pop
	t.pop = 160.0
	t._aggiorna_tappa()
	t.pop = pop_t
	t._aggiorna_tappa()
	controlla(t.tappa == 3 and t.sbloccato("granaio") and t.sbloccato("stranieri") and not t.sbloccato("casali"), "le tappe raggiunte restano anche se gli abitanti calano")
	# Il granaio costa legna e si costruisce in qualche anno (decisione di Fede del 25/11/2026).
	t.legna = 0.0
	controlla(t.motivo_granaio(t.mondo_di_px(c) + Vector2(60, 0)) != "", "senza legna il granaio non si costruisce")
	t.legna = 45.0
	controlla(t.motivo_granaio(t.mondo_di_px(c) + Vector2(60, 0)) == "" and t.motivo_granaio(t.mondo_di_px(c) + Vector2(900, 0)) != "", "il granaio va vicino al centro (con %d di legna si può)" % roundi(t.legna))
	# Legnaia (decisione di Fede del 25/11/2026): senza legnaia non si raccoglie legna; i boscaioli
	# abbattono gli alberi più vicini e la raccolta rallenta man mano che la radura si allarga.
	var tl := SimVillaggio.new(d, 3)
	tl.fonda(Vector2i(d.siti[2]["px"]))
	tl.decisioni.clear()
	tl.passo()
	controlla(tl.legnaie.is_empty() and tl.ultima_legna == 0.0, "senza legnaia non si raccoglie legna")
	var cg := RandomNumberGenerator.new()
	cg.seed = 5
	controlla(AiutiGiocatori.costruisci_legnaia(tl, cg, 1.0) and tl.legnaie.size() == 1, "si costruisce una legnaia vicino al bosco")
	var l0: Dictionary = tl.legnaie[0]
	controlla(tl.capacita_legnaia(l0) == 0.0, "la legnaia in costruzione non raccoglie")
	for k in 3:
		tl.decisioni.clear()
		tl.passo()
	var cap0 := tl.capacita_legnaia(l0)
	controlla(cap0 > 0.0 and tl.ultima_legna > 0.0, "finita la legnaia, si raccoglie legna (%.1f l'anno, fino a %.1f)" % [tl.ultima_legna, cap0])
	var abbattuti := tl.tagliati.size()
	for k in 40:
		tl.decisioni.clear()
		tl.legna = 0.0
		# Il villaggio di prova non ha campi: senza poste e capanni (un terzo di caccia e pesca)
		# morirebbe di fame, e qui si prova solo la legnaia.
		tl.cibo = maxf(tl.cibo, tl.pop)
		tl.passo()
	controlla(tl.tagliati.size() > abbattuti and tl.capacita_legnaia(l0) < cap0, "il taglio allarga la radura e la raccolta rallenta (%.1f → %.1f l'anno)" % [cap0, tl.capacita_legnaia(l0)])
	var uno: int = -1
	for i in tl.tagliati:
		if tl.dati.tipo[i] != MappaDati.PALUDE:
			uno = i
			break
	controlla(not tl.bosco_in_piedi(uno) or tl.anno - int(tl.tagliati.get(uno, tl.anno)) >= SimVillaggio.ANNI_RICRESCITA, "un pixel abbattuto non è bosco finché non ricresce")
	# Zona di taglio (decisione di Fede del 25/11/2026): finché la legnaia lavora non ricresce nulla;
	# a riposo il bosco ricaccia dalle ceppaie (ceduo) in ANNI_RICRESCITA anni.
	controlla(tl.legnaia_attiva(l0) and tl.zona_attiva.has(uno), "la zona di taglio della legnaia al lavoro resta tagliata (%s)" % tl.stato_legnaia(l0))
	tl.anno += SimVillaggio.ANNI_RICRESCITA + 5
	controlla(not tl.bosco_in_piedi(uno), "finché la zona è attiva il bosco non ricresce")
	tl.metti_a_riposo(0, true)
	controlla(not tl.legnaia_attiva(l0) and not tl.zona_attiva.has(uno) and tl.capacita_legnaia(l0) == 0.0, "lasciar ricrescere: la legnaia si ferma e la zona va a riposo")
	controlla(not tl.bosco_in_piedi(uno), "appena messa a riposo la zona è ancora tagliata")
	tl.anno += SimVillaggio.ANNI_RICRESCITA
	controlla(tl.bosco_in_piedi(uno), "dopo %d anni a riposo il bosco abbattuto ricresce (ceduo)" % SimVillaggio.ANNI_RICRESCITA)
	tl.metti_a_riposo(0, false)
	controlla(tl.legnaia_attiva(l0), "la legnaia torna al lavoro")
	# Campi che si stancano (decisione di Fede del 25/11/2026).
	if not tl.campi.is_empty():
		var cs: int = tl.campi[0]
		var resa0 := tl._resa(cs)
		tl.stanchezza[cs] = SimVillaggio.ANNI_PRIMA_STANCHEZZA + SimVillaggio.ANNI_STANCHEZZA
		controlla(tl._resa(cs) < resa0 * 0.7 and tl.campi_stanchi() >= 1, "un campo coltivato per cento anni di fila rende meno (%.2f → %.2f)" % [resa0, tl._resa(cs)])
		tl.stanchezza.erase(cs)
	# Politiche: cambiarle costa consenso, gli stranieri seguono la regola in vigore.
	controlla(t.politica("raccolto") == "comune" and t.politica("stranieri") == "aperta", "politiche iniziali: raccolto in comune, stranieri accolti")
	var b0: float = t.bonus["anziani"]
	controlla(t.imposta_politica("raccolto", "famiglie") and t.bonus["anziani"] < b0, "cambiare una politica costa un po' di consenso agli anziani")
	controlla(not t.imposta_politica("raccolto", "famiglie") and not t.imposta_politica("stranieri", "boh"), "valori uguali o sconosciuti non cambiano nulla")
	# Il primo arrivo di stranieri ferma il gioco una volta e la scelta diventa la regola.
	var p0 := t.pop
	t.imposta_politica("stranieri", "aperta")
	t._arrivo_stranieri()
	controlla(t.in_attesa() and t.decisioni[0]["tipo"] == "stranieri", "il primo arrivo di stranieri ferma il gioco")
	t.scegli(t.decisioni[0]["id"], "respingere")
	controlla(t.pop == p0 and t.politica("stranieri") == "chiusa" and not t.in_attesa(), "la prima scelta diventa la regola")
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
	# Il limo: i campi allagati da una piena di stagione rendono di più per qualche anno.
	controlla(t.limo.is_empty() or t._resa(t.limo.keys()[0]) > 0.0, "i campi con il limo tornano a rendere")
	# La prima piena disastrosa che tocca il villaggio ferma il gioco una volta (decisione di Fede
	# del 25/11/2026); le altre no.
	for k in 20:
		t._piena(true)
	var fermate := 0
	while t.in_attesa():
		fermate += 1
		t.scegli(t.decisioni[0]["id"], t.decisioni[0]["opzioni"][0]["id"])
	controlla(fermate <= 1, "solo la prima piena disastrosa ferma il gioco (%d)" % fermate)
	t.avvisi.clear()
	_verifica_capanno_e_posta(d)
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
