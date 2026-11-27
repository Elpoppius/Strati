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


## Luogo sacro, sacerdote e bosco sacro (decisioni di Fede del 24–25/11/2026).
func _verifica_sacro(d: MappaDati) -> void:
	var s := SimVillaggio.new(d, 11)
	var c := Vector2i(d.siti[0]["px"])
	s.fonda(c)
	var cm := s.mondo_di_px(c)
	controlla(s.motivo_luogo_sacro(cm + Vector2(80, 0)).contains("si apre"), "il luogo sacro si apre con la tappa dei 100 abitanti")
	s.pop = 110.0
	s._aggiorna_tappa()
	s.legna = 50.0
	# Il sacerdote ha voce dalla tappa ed è contrariato finché non c'è il luogo sacro (Fede, 25/11/2026 sera).
	controlla(s.sacerdote_attivo and s.obiettivo_sacerdote() < 40.0 and s.cause_di("Consenso").any(func(x: String) -> bool: return x.contains("finché non si erige")), "dalla tappa dei 100 il sacerdote ha voce ed è contrariato senza luogo sacro (%.0f)" % s.obiettivo_sacerdote())
	controlla(s.motivo_luogo_sacro(cm + Vector2(900, 0)) != "", "il luogo sacro va vicino al villaggio")
	# A 300 m dal centro, per vedere le case che gli crescono attorno.
	var fatto := false
	for k in 16:
		if not fatto and s.costruisci_luogo_sacro(cm + Vector2.from_angle(TAU * k / 16.0) * 300.0) == "":
			fatto = true
	controlla(fatto and s.cantiere_luogo_sacro == SimVillaggio.ANNI_CANTIERE_LUOGO_SACRO and is_equal_approx(s.legna, 40.0), "il luogo sacro costa 10 di legna e tre anni di cantiere")
	controlla(not s.luogo_sacro_pronto() and s.obiettivo_sacerdote() < 40.0 and s.motivo_luogo_sacro(cm + Vector2(-80, 0)) != "", "uno solo, e il sacerdote resta contrariato finché si costruisce")
	for k in SimVillaggio.ANNI_CANTIERE_LUOGO_SACRO:
		s.decisioni.clear()
		s.passo()
	controlla(s.luogo_sacro_pronto() and s.obiettivo_sacerdote() >= 60.0, "finito il luogo sacro, il sacerdote è soddisfatto (%.0f)" % s.obiettivo_sacerdote())
	# Le case nuove crescono attorno al luogo sacro.
	var senza := SimVillaggio.new(d, 11)
	senza.fonda(c)
	senza.pop = 200.0
	senza.disponi_case()
	s.pop = 200.0
	s.legna = 1000.0
	s.disponi_case()
	var media := func(t: SimVillaggio) -> float:
		var somma := 0.0
		for l in t.case:
			somma += t.centro_lotto(l).distance_to(s.luogo_sacro)
		return somma / maxf(1.0, t.case.size())
	controlla(media.call(s) < media.call(senza), "il luogo sacro attira le case (distanza media %.0f m, senza %.0f m)" % [media.call(s), media.call(senza)])
	# Presagi: chiari con il sacerdote contento, ambigui e più spesso falsi se è scontento.
	s.consenso["sacerdote"] = 70.0
	var chiaro := s._testo_sorgenti()
	var falsi_contento := s.quota_presagi_falsi()
	s.consenso["sacerdote"] = 30.0
	controlla(falsi_contento < SimVillaggio.PRESAGI_FALSI and s.quota_presagi_falsi() > SimVillaggio.PRESAGI_FALSI and chiaro.contains("conferma") and s._testo_sorgenti().contains("non dice"), "sacerdote contento: presagi chiari (%d%% falsi); scontento: ambigui (%d%% falsi)" % [roundi(falsi_contento * 100.0), roundi(s.quota_presagi_falsi() * 100.0)])
	s.consenso["sacerdote"] = 60.0
	# Bosco sacro.
	var bosco := Vector2i(-1, -1)
	for r in range(1, 25):
		for k in 32:
			var q := c + Vector2i(roundi(cos(TAU * k / 32.0) * r), roundi(sin(TAU * k / 32.0) * r))
			if bosco.x < 0 and s.bosco_in_piedi(s.px(q)) and not s.campi.has(s.px(q)):
				bosco = q
	controlla(bosco.x >= 0 and s.motivo_bosco_sacro(bosco).contains("si apre"), "il bosco sacro si apre con la tappa dei 150 abitanti")
	var obiettivo_prima := s.obiettivo_sacerdote()
	s.pop = 160.0
	s._aggiorna_tappa()
	var cg := RandomNumberGenerator.new()
	cg.seed = 4
	var ha := AiutiGiocatori.stendi_bosco_sacro(s, cg, 1.0, 10.0)
	controlla(ha >= 5.0 and s.obiettivo_sacerdote() > obiettivo_prima - 7.0 + 7.0 * 0.5, "si stende il bosco sacro (%.1f ha) e il sacerdote lo apprezza (%.0f → %.0f)" % [ha, obiettivo_prima, s.obiettivo_sacerdote()])
	var sacro: int = s.bosco_sacro.keys()[0]
	controlla(not s.legno_in_piedi(sacro) and s.motivo_campo(s.px_di(sacro)) != "", "le legnaie non tagliano il bosco sacro e nessuno lo dissoda")
	var prima: float = s.bonus["sacerdote"]
	var esito := s.demolisci(s.mondo_di_px(s.px_di(sacro)), 60.0)
	controlla(int(esito.get("bosco_sacro", 0)) > 0 and s.bonus["sacerdote"] < prima and s.cronaca[0]["testo"].contains("bosco sacro") or s.cronaca.any(func(e: Dictionary) -> bool: return String(e["testo"]).contains("bosco sacro")), "tagliare il bosco sacro offende il sacerdote")


## Pascolo e animali (decisioni di Fede del 25/11/2026).
func _verifica_pascolo(d: MappaDati) -> void:
	var s := SimVillaggio.new(d, 13)
	var c := Vector2i(d.siti[0]["px"])
	s.fonda(c)
	var vicini: Array[Vector2i] = []
	for dy in range(-6, 7):
		for dx in range(-6, 7):
			vicini.append(c + Vector2i(dx, dy))
	controlla(s.motivo_pascolo(c + Vector2i(3, 0)).contains("si apre") and s.aggiungi_pascolo(vicini) == 0, "il pascolo si apre con la tappa dei 100 abitanti")
	s.pop = 110.0
	s._aggiorna_tappa()
	s._pascola({})
	controlla(s.capi >= SimVillaggio.CAPI_INIZIALI and s.capi <= SimVillaggio.CAPI_ATTORNO_CASE and is_equal_approx(s.portata_capi, SimVillaggio.CAPI_ATTORNO_CASE), "alla tappa una decina di capi attorno alle case (%d, portata %d)" % [roundi(s.capi), roundi(s.portata_capi)])
	var messi := s.aggiungi_pascolo(vicini)
	var prima_capi := s.capi
	s._pascola({})
	var portata := s.portata_capi
	controlla(messi > 50 and portata > SimVillaggio.CAPI_ATTORNO_CASE + 10.0, "il pascolo a pennello nutre più capi (%d pixel, portata %d)" % [messi, roundi(portata)])
	controlla(is_equal_approx(s.capi, prima_capi * 1.1), "la mandria cresce del 10%% l'anno (%.1f → %.1f)" % [prima_capi, s.capi])
	for k in 40:
		s._pascola({})
	controlla(s.capi <= s.portata_capi + 0.01 and s.capi > s.portata_capi * 0.95, "finita l'erba la mandria smette di crescere (%d su %d)" % [roundi(s.capi), roundi(s.portata_capi)])
	var f := SimVillaggio.new(d, 13)
	f.fonda(c)
	f.pop = 110.0
	f._aggiorna_tappa()
	f.politiche["raccolto"] = "famiglie"
	f.aggiungi_pascolo(vicini)
	f._pascola({})
	f._pascola({})
	controlla(f.capi > SimVillaggio.CAPI_INIZIALI * 1.1 * 1.1 + 0.1, "con il raccolto alle famiglie la mandria cresce di più (%.1f in due anni)" % f.capi)
	for k in 30:
		f._pascola({})
	controlla(f.disuguaglianza > 0.0 and s.disuguaglianza == 0.0, "gli animali delle famiglie fanno crescere la disuguaglianza (%.3f)" % f.disuguaglianza)
	# Campi nella zona di pascolo: stoppie se lavorati, maggese se stanchi o incolti.
	var campo := -1
	for i in s.pascolo:
		if campo < 0 and s.edificabile(i) and not s.campi.has(i):
			campo = i
	s.campi.append(campo)
	s.stanchezza[campo] = 80.0
	s._pascola({})
	controlla(s.maggese.has(campo) and is_equal_approx(float(s.stanchezza[campo]), 80.0 - SimVillaggio.RIPOSO_PER_ANNO), "un campo stanco nel pascolo diventa maggese e si riposa più in fretta")
	var resa_prima := s._resa(campo)
	s._pascola({campo: true})
	controlla(not s.maggese.has(campo) and s.concimati.has(campo) and s._resa(campo) > resa_prima * 1.04, "su un campo coltivato gli animali pascolano le stoppie: l'anno dopo rende un po' di più")
	# Togli: via il pascolo, i campi restano.
	s.togli_pascolo([s.px_di(campo)])
	controlla(not s.pascolo.has(campo) and s.campi.has(campo), "l'opzione Togli toglie il pascolo e lascia il campo")
	# Il pascolo tiene aperte le radure.
	var radura := -1
	for i in s.pascolo:
		if radura < 0 and s.bosco_in_piedi(i):
			radura = i
	if radura >= 0:
		s.tagliati[radura] = s.anno - SimVillaggio.ANNI_RICRESCITA - 5
		controlla(not s.bosco_in_piedi(radura), "dove si pascola il bosco tagliato non ricresce")
	# Stranieri e scorta viva.
	var capi_prima := s.capi
	s._accogli(4)
	controlla(is_equal_approx(s.capi, capi_prima + 4 * SimVillaggio.CAPI_PER_STRANIERO), "gli stranieri accolti portano i loro animali")
	s.capi = 40.0
	s.cibo = -1000.0
	s.campi = []
	s.fonti = {"agricoltura": false, "caccia": false, "pesca": false}
	s.decisioni.clear()
	s.passo()
	controlla(s.ultimi_macellati > 0 and s.capi >= s.ultimi_macellati - 0.5 and s.cronaca.any(func(e: Dictionary) -> bool: return String(e["testo"]).contains("macellano")), "nell'annata cattiva si macellano gli animali (%d), fino a metà della mandria" % s.ultimi_macellati)
	# Troppi animali sui pendii: erosione.
	var e := SimVillaggio.new(d, 13)
	var sito_pendii := Vector2i(d.siti[2]["px"])
	e.fonda(sito_pendii)
	e.pop = 300.0
	e._aggiorna_tappa()
	var tutto: Array[Vector2i] = []
	for dy in range(-12, 13):
		for dx in range(-12, 13):
			tutto.append(sito_pendii + Vector2i(dx, dy))
	e.aggiungi_pascolo(tutto)
	e.capi = 5000.0
	e._pascola({})
	var pendii := 0
	for i in e.pascolo:
		if e._pendio(i):
			pendii += 1
	controlla(pendii == 0 or e.pascolo_eccessivo > 0.0, "la mandria piena sui pendii dà erosione (%d pixel in pendio, %.2f)" % [pendii, e.pascolo_eccessivo])


## Scorrerie e torre di avvistamento (decisioni di Fede del 26/11/2026).
func _verifica_scorrerie(d: MappaDati) -> void:
	var s := SimVillaggio.new(d, 17)
	var c := Vector2i(d.siti[0]["px"])
	s.fonda(c)
	var cm := s.mondo_di_px(c)
	s.capi = 60.0
	s.cibo = 400.0
	controlla(not s.scorrerie_aperte() and s.calcola_rischio_scorrerie()["p"] > 0.0, "prima della tappa dei 100 abitanti niente scorrerie")
	s.pop = 110.0
	s._aggiorna_tappa()
	s.decisioni.clear()
	controlla(s.scorrerie_aperte() and not s.sbloccato("pericolo") and not s.sbloccato("torre"), "dalla tappa del pascolo le scorrerie sono possibili; politica e torre aspettano i primi segni")
	# Rischio: più ricchezza ed esposizione, più rischio; più difesa, meno.
	var base := float(s.calcola_rischio_scorrerie()["p"])
	s.capi = 5.0
	s.cibo = 10.0
	var povero := float(s.calcola_rischio_scorrerie()["p"])
	controlla(povero < base * 0.6, "un villaggio povero attira meno scorrerie (%.4f contro %.4f)" % [povero, base])
	s.capi = 60.0
	s.cibo = 400.0
	s.casali = [s.lotto_da_mondo(cm.x + 600.0, cm.y), s.lotto_da_mondo(cm.x - 600.0, cm.y), s.lotto_da_mondo(cm.x, cm.y + 600.0)]
	var sparso := float(s.calcola_rischio_scorrerie()["p"])
	controlla(sparso > base * 1.2, "i casali espongono di più (%.4f contro %.4f)" % [sparso, base])
	s.casali = []
	var dopo := s.anno
	s.anno = SimVillaggio.ANNO_SCORRERIE_FREQUENTI
	controlla(is_equal_approx(float(s.calcola_rischio_scorrerie()["p"]), base * 2.0), "dal 4300 a.C. le scorrerie sono il doppio")
	s.anno = dopo
	controlla(base > 0.0005 and base < SimVillaggio.PROB_SCORRERIA, "rischio di un villaggio medio, ricco: %.4f l'anno (una ogni %d anni)" % [base, roundi(1.0 / base)])
	# Primi segni: ferma il gioco una volta (tutorial e scelta) e apre politica e torre.
	s._segni()
	var tipi: Array = s.decisioni.map(func(x: Dictionary) -> String: return x["tipo"])
	controlla(s.gia_segni and s.in_allerta() and "pericolo" in tipi and s.sbloccato("pericolo") and s.sbloccato("torre"), "i primi segni fermano il gioco e aprono politica e torre (%s)" % ", ".join(tipi))
	controlla(s.segni_punto.x >= 0 and s.segni_da != "" and s.avvisi.any(func(a: Dictionary) -> bool: return String(a["testo"]).contains(s.segni_da)), "i segni dicono da dove arriveranno, con un punto sulla mappa")
	for dec in s.decisioni.duplicate():
		s.scegli(dec["id"], "raccogliere" if dec["tipo"] == "pericolo" else "continua")
	controlla(s.politica("pericolo") == "raccogliere", "la scelta dei primi segni diventa la regola")
	# La scorreria arriva dopo 1–2 anni.
	var capi0 := s.capi
	var cibo0 := s.cibo
	var anni := 0
	while s.in_allerta() and anni < 5:
		s.decisioni.clear()
		s._scorrerie()
		anni += 1
	controlla(not s.in_allerta() and anni >= 1 and anni <= 2 and s.stat["scorrerie"] == 1, "la scorreria arriva 1–2 anni dopo i segni (%d)" % anni)
	controlla(s.capi < capi0 and s.cibo < cibo0, "si perdono animali e scorte (%d → %d capi, %d → %d cibo)" % [roundi(capi0), roundi(s.capi), roundi(cibo0), roundi(s.cibo)])
	controlla(s.memoria_scorrerie >= 99.0 and s.cause_di("Animali").any(func(x: String) -> bool: return x.contains("Scorreria del")), "la scorreria resta nella memoria e nei pannelli")
	# Le perdite: raccogliere dimezza, vegliare riduce, la torre riduce ancora.
	var perdite := {}
	for pol in ["avanti", "raccogliere", "vegliare"]:
		var somma := 0.0
		for k in 40:
			var t := SimVillaggio.new(d, 200 + k)
			t.fonda(c)
			t.pop = 110.0
			t._aggiorna_tappa()
			t.decisioni.clear()
			t.capi = 60.0
			t.cibo = 400.0
			t.gia_segni = true
			t.politiche["pericolo"] = pol
			t.segni_punto = cm + Vector2(300, 0)
			t.segni_da = "est"
			t._scorreria()
			somma += 400.0 - t.cibo
		perdite[pol] = somma / 40.0
	controlla(perdite["raccogliere"] < perdite["avanti"] * 0.65 and perdite["vegliare"] < perdite["avanti"] * 0.75, "raccogliere e vegliare riducono le perdite (cibo perso: %d, %d, %d)" % [roundi(perdite["avanti"]), roundi(perdite["raccogliere"]), roundi(perdite["vegliare"])])
	# Torre: solo su un'altura, entro 1200 m, una sola; segni prima.
	var u := SimVillaggio.new(d, 19)
	u.fonda(c)
	u.legna = 40.0
	controlla(u.motivo_torre(cm + Vector2(200, 0)).contains("primi segni"), "la torre si apre con i primi segni di pericolo")
	u.gia_segni = true
	var alto := Vector2(-1, -1)
	var basso := Vector2(-1, -1)
	for r in [200.0, 400.0, 600.0, 800.0, 1000.0]:
		for k in 24:
			var w: Vector2 = cm + Vector2.from_angle(TAU * k / 24.0) * r
			var q := u.px_da_mondo(w.x, w.y)
			var m := u.motivo_torre(w)
			if alto.x < 0 and m == "":
				alto = w
			if basso.x < 0 and m.contains("dosso"):
				basso = w
	controlla(alto.x >= 0, "attorno al sito 1 c'è un'altura per la torre")
	controlla(basso.x >= 0, "in pianura la torre non si può fare: «%s»" % (u.motivo_torre(basso) if basso.x >= 0 else ""))
	controlla(u.motivo_torre(cm + Vector2(1500, 0)) != "", "la torre va vicino al villaggio")
	controlla(u.costruisci_torre(alto) == "" and u.cantiere_torre == SimVillaggio.ANNI_CANTIERE_TORRE and is_equal_approx(u.legna, 32.0), "la torre costa 8 di legna e due anni di cantiere")
	controlla(u.motivo_torre(alto + Vector2(40, 0)).contains("c'è già"), "una torre sola")
	u.cantiere_torre = 0
	u.pop = 110.0
	u._aggiorna_tappa()
	var anni_torre := []
	for k in 20:
		u.decisioni.clear()
		u.segni_tra = -1
		u._segni()
		anni_torre.append(u.segni_tra)
	controlla(anni_torre.min() >= 2 and anni_torre.max() <= 3, "con la torre i segni arrivano 2–3 anni prima")
	controlla(u.demolisci(alto, 20.0)["torre"] and u.torre.x < 0, "la torre si demolisce")
	# Memoria della paura: dopo una scorreria le case nuove nascono più vicine al centro.
	var media := func(sim: SimVillaggio) -> float:
		var tot := 0.0
		for l in sim.case:
			tot += sim.centro_lotto(l).distance_to(sim.mondo_di_px(sim.centro))
		return tot / maxf(sim.case.size(), 1.0)
	var calmo := SimVillaggio.new(d, 23)
	calmo.fonda(c)
	calmo.pop = 200.0
	calmo.legna = 500.0
	calmo.disponi_case(false)
	var impaurito := SimVillaggio.new(d, 23)
	impaurito.fonda(c)
	impaurito.memoria_scorrerie = 100.0
	impaurito.pop = 200.0
	impaurito.legna = 500.0
	impaurito.disponi_case(false)
	controlla(media.call(impaurito) < media.call(calmo), "dopo una scorreria l'abitato si stringe (%d m contro %d m dal centro)" % [roundi(media.call(impaurito)), roundi(media.call(calmo))])


## Sentieri che diventano strade (voce 5, decisioni di Fede del 26/11/2026).
func _verifica_strade(d: MappaDati) -> void:
	var s := SimVillaggio.new(d, 29)
	var c := Vector2i(d.siti[0]["px"])
	s.fonda(c)
	s.decisioni.clear()
	var cm := s.mondo_di_px(c)
	# Un sentiero di 800 m verso est e una legnaia in fondo (o i campi in fondo).
	var fine := c
	for k in range(20, 0, -1):
		var q := c + Vector2i(k, 0)
		if s.motivo_sentiero(c, q) == "":
			fine = q
			break
	controlla(fine != c and s.traccia_sentiero_da(c, fine) == "", "un sentiero dal centro verso est (%d m)" % roundi(s.mondo_di_px(fine).distance_to(cm)))
	var lontani: Array[Vector2i] = []
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			lontani.append(fine + Vector2i(dx, dy))
	# Campi lontani messi a mano (oltre il contado di un villaggio appena fondato).
	for q in lontani:
		s.campi.append(s.px(q))
	s.pop = 200.0
	s._aggiorna_traffico()
	var t: Array = s.tratti_sentiero[0]
	var tr: Array = s.traffico_tratto(t)
	controlla(float(tr[0]) > 0.0, "chi lavora lontano passa sul sentiero (%d persone l'anno)" % roundi(float(tr[0])))
	controlla(s.strade.is_empty(), "prima della tappa dei 250 abitanti nessuna strada")
	s.tappa = SimVillaggio.tappa_di("strade")
	s.decisioni.clear()
	s.anni_battuto.clear()
	var anni := 0
	while s.strade.is_empty() and anni < 40:
		s.pop = 300.0
		s._aggiorna_traffico()
		anni += 1
	controlla(not s.strade.is_empty() and anni == SimVillaggio.ANNI_STRADA, "un tratto battuto per %d anni diventa strada (%d)" % [SimVillaggio.ANNI_STRADA, anni])
	controlla(s.avvisi.any(func(a: Dictionary) -> bool: return String(a["testo"]).contains("strada")), "una notifica dice che un sentiero è diventato strada")
	controlla(not s.pixel_strada.is_empty(), "la strada ha i suoi punti sulla mappa")
	# Resta, anche se il traffico cala.
	s.pop = 5.0
	s.campi.clear()
	for k in 5:
		s._aggiorna_traffico()
	controlla(not s.strade.is_empty(), "la strada resta anche se il traffico cala")
	for q in lontani:
		s.campi.append(s.px(q))
	# Accesso: i campi vicini alla strada rendono di più.
	var vicino: int = s.campi[0]
	s._firma_serviti = -1
	s._aggiorna_campi_serviti()
	controlla(s._campi_strada.has(vicino), "i campi vicini alla strada sono serviti dalla strada")
	# Le case crescono anche lungo la strada.
	var u := SimVillaggio.new(d, 29)
	u.fonda(c)
	u.traccia_sentiero_da(c, fine)
	u.strade[SimVillaggio.chiave_tratto(u.tratti_sentiero[0])] = u.anno
	u.tappa = SimVillaggio.tappa_di("strade")
	u._aggiorna_strade()
	u.pop = 300.0
	u.legna = 2000.0
	u.disponi_case(false)
	var lontane := u.case.filter(func(l: Vector2i) -> bool: return u.centro_lotto(l).distance_to(cm) > 250.0)
	controlla(not lontane.is_empty(), "le case crescono anche lungo la strada (%d oltre 250 m)" % lontane.size())
	# Le figure seguono la rete.
	var giro := u.percorso_rete(cm + Vector2(0, 20), u.mondo_di_px(fine) + Vector2(0, 30))
	controlla(giro.size() >= 2, "chi va lontano cammina lungo il sentiero (%d tappe)" % giro.size())
	controlla(u.percorso_rete(cm, cm + Vector2(60, 0)).is_empty(), "chi va vicino va dritto")
	# Una strada si toglie solo demolendola.
	var m := u.mondo_di_px(fine)
	u.demolisci(m, 60.0)
	controlla(not u.pixel_strada.has(u.px(fine)) and not u.pixel_strada.is_empty(), "demolendo si toglie il pezzo di strada")


## Passo elastico ed evento soglia 1 (voce 6, regole approvate da Fede il 26/11/2026).
func _verifica_soglia(d: MappaDati) -> void:
	var s := SimVillaggio.new(d, 41)
	var c := Vector2i(d.siti[0]["px"])
	s.fonda(c)
	s.decisioni.clear()
	controlla(s.anni_per_passo() == 1, "nei primi secoli un anno per passo")
	s.anno = SimVillaggio.ANNO_DECENNI - 1
	s.tappa = SimVillaggio.tappa_di("casali")
	s.passo()
	while s.in_attesa():
		s.scegli(s.decisioni[0]["id"], s.decisioni[0]["opzioni"][0]["id"])
	controlla(s.anni_per_passo() == SimVillaggio.ANNI_DECENNIO and s.decenni, "dal %s, con il territorio, un decennio per passo" % SimVillaggio.anno_testo(SimVillaggio.ANNO_DECENNI))
	var t := SimVillaggio.new(d, 41)
	t.fonda(c)
	t.decisioni.clear()
	t.anno = SimVillaggio.ANNO_DECENNI
	t._aggiorna_decenni()
	controlla(not t.decenni, "un villaggio senza la tappa Territorio resta ad anni")
	t.anno = SimVillaggio.ANNO_DECENNI_COMUNQUE
	t._aggiorna_decenni()
	controlla(t.decenni, "dal %s comunque a decenni" % SimVillaggio.anno_testo(SimVillaggio.ANNO_DECENNI_COMUNQUE))
	# Presagi del metallo e scelta.
	s.anno = SimVillaggio.ANNO_PRESAGI_SOGLIA
	s.pop = 700.0
	var anni := 0
	while not s.decisioni.any(func(x: Dictionary) -> bool: return x["tipo"] == "soglia") and anni < 1000:
		s.pop = 700.0
		s.cibo = 5000.0
		s.passo()
		while s.in_attesa() and s.decisioni[0]["tipo"] != "soglia":
			s.scegli(s.decisioni[0]["id"], s.decisioni[0]["opzioni"][0]["id"])
		anni += 1
	controlla(s.presagi_soglia >= 2, "prima dell'evento arrivano i presagi del metallo (%d)" % s.presagi_soglia)
	var dec: Array = s.decisioni.filter(func(x: Dictionary) -> bool: return x["tipo"] == "soglia")
	controlla(not dec.is_empty() and s.anno >= SimVillaggio.ANNO_SOGLIA, "con il territorio pieno, dal 3000 a.C. arriva l'evento soglia (%s)" % SimVillaggio.anno_testo(s.anno))
	if not dec.is_empty():
		s.identita["terra"] = 0.8
		s.identita["decide"] = -0.4
		s.disuguaglianza = 0.6
		s.scegli(dec[0]["id"], "aprirsi")
	controlla(s.epoca == 2 and not s.finito and s.soglia_scelta == "aprirsi" and s.primo_governo == "Casa dominante", "raccolto alle famiglie e disuguaglianza alta: Casa dominante (%s), e comincia l'epoca 2" % s.primo_governo)
	controlla(s.tecnica_corrente >= 1 and float(s.identita["apertura"]) > 0.3, "arriva l'aratro e la città nasce aperta")
	var fine: Array = s.decisioni.filter(func(x: Dictionary) -> bool: return x["tipo"] == "epoca")
	controlla(not fine.is_empty() and String(fine[0]["testo"]).contains("Casa dominante") and String(fine[0]["testo"]).contains("abitanti"), "il riepilogo del villaggio dice il primo governo")
	_verifica_fabbro(s, d)
	_verifica_recinto(d, c)
	s.identita["terra"] = -0.6
	s.disuguaglianza = 0.1
	s.consenso["anziani"] = 70.0
	controlla(s.governo_da_identita() == "Comunità", "raccolto in comune, poca disuguaglianza, anziani contenti: Comunità")
	s.consenso["anziani"] = 30.0
	controlla(s.governo_da_identita() == "Consiglio dei clan", "raccolto in comune ma anziani scontenti: Consiglio dei clan")
	s.identita["terra"] = 0.5
	s.disuguaglianza = 0.05
	controlla(s.governo_da_identita() == "Consiglio dei clan", "raccolto alle famiglie con poca disuguaglianza: Consiglio dei clan")
	# Ritmo dei presagi (Fede, 26/11/2026): a decenni più radi, con il sacerdote scontento più fitti.
	var r1 := SimVillaggio.new(d, 41)
	r1.fonda(c)
	var anni_prima: Array = r1.ritmo_presagi()
	r1.decenni = true
	var anni_dopo: Array = r1.ritmo_presagi()
	controlla(int(anni_dopo[0]) >= 4 * int(anni_prima[0]) and float(anni_dopo[1]) < float(anni_prima[1]), "a decenni i presagi si allentano (almeno %d anni fra uno e l'altro)" % int(anni_dopo[0]))
	r1.sacerdote_attivo = true
	r1.consenso["sacerdote"] = 30.0
	var scontento: Array = r1.ritmo_presagi()
	controlla(int(scontento[0]) < int(anni_dopo[0]) and float(scontento[1]) > float(anni_dopo[1]), "con il sacerdote scontento i presagi tornano più fitti (%d anni)" % int(scontento[0]))
	# Al 1800 a.C. l'evento arriva comunque.
	var u := SimVillaggio.new(d, 41)
	u.fonda(c)
	u.decisioni.clear()
	u.presagi_soglia = 3
	u.anno = SimVillaggio.ANNO_SOGLIA_COMUNQUE
	u.pop = 80.0
	u._soglia()
	controlla(u.decisioni.any(func(x: Dictionary) -> bool: return x["tipo"] == "soglia"), "al 1800 a.C. l'evento arriva anche a un villaggio piccolo")
	var v := SimVillaggio.new(d, 41)
	v.fonda(c)
	v.decisioni.clear()
	var msg := v.prova_soglia()
	controlla(v.decisioni.any(func(x: Dictionary) -> bool: return x["tipo"] == "soglia") and v.anno == SimVillaggio.ANNO_SOGLIA and v.decenni, "Prova: Metallo porta subito all'evento (%s)" % msg)


## Epoca 2, l'officina del fabbro (decisioni di Fede del 27/11/2026; scheda in epoca2-proposte § 2b).
func _verifica_fabbro(s: SimVillaggio, d: MappaDati) -> void:
	while s.in_attesa():
		s.scegli(s.decisioni[0]["id"], s.decisioni[0]["opzioni"][0]["id"])
	controlla(s.sbloccato("officina") and s._tutorial_visti.has("fabbro"), "con l'epoca 2 si sblocca l'officina del fabbro, con la sua scheda di tutorial")
	var c := s.mondo_di_px(s.centro)
	s.legna = 0.0
	var punto := Vector2.ZERO
	for k in 40:
		var a := k * 0.7
		var w := c + Vector2(cos(a), sin(a)) * (60.0 + k * 6.0)
		s.legna = 100.0
		if s.motivo_officina(w) == "":
			punto = w
			break
	controlla(punto != Vector2.ZERO, "c'è un posto per l'officina vicino al villaggio")
	s.legna = 5.0
	s.ultima_legna = 3.0
	controlla(s.motivo_officina(punto).contains("legna"), "senza legna l'officina non si costruisce")
	s.ultima_legna = 40.0
	s.legna = 0.0
	controlla(s.motivo_officina(punto) == "", "con la scorta vuota l'officina si paga con il taglio dell'anno")
	s.legna = 200.0
	controlla(s.costruisci_officina(punto) == "" and int(s.officine[0]["cantiere"]) == SimVillaggio.ANNI_CANTIERE_OFFICINA, "l'officina si costruisce in %d anni" % SimVillaggio.ANNI_CANTIERE_OFFICINA)
	controlla(s.motivo_officina(c + Vector2(30, 0)).contains("c'è già"), "ne basta una")
	s.case = s.case.filter(func(l: Vector2i) -> bool: return s.centro_lotto(l).distance_to(s.officine[0]["punto"]) >= SimVillaggio.DISTANZA_FUOCO)
	# Il carbone viene dagli scarti delle legnaie: ne serve una al lavoro.
	var caso_l := RandomNumberGenerator.new()
	caso_l.seed = 5
	s.legnaie = []
	AiutiGiocatori.costruisci_legnaia(s, caso_l, 1.0)
	controlla(not s.legnaie.is_empty(), "c'è una legnaia per gli scarti del carbone")
	var prima_att := s.attrezzi
	var g := 0
	while g < 40 and not s.finito:
		s.legna = 200.0
		s.cibo = 5000.0
		s.pop = 600.0
		s.passo()
		while s.in_attesa():
			s.scegli(s.decisioni[0]["id"], s.decisioni[0]["opzioni"][0]["id"])
		g += 1
	controlla(s.officina_pronta(s.officine[0]) and s.attrezzi > prima_att + 0.3 and s.armi < 0.01, "il fabbro forgia attrezzi: salgono (%d%%), le armi no" % roundi(s.attrezzi * 100.0))
	controlla(s.carbone_anno > 0.0 and s.lavoro_fabbro > 0.5, "la fornace brucia gli scarti del taglio (%.1f l'anno), il fabbro lavora (%d%%)" % [s.carbone_anno, roundi(s.lavoro_fabbro * 100.0)])
	var cause := " ".join(s.cause_di("Cibo"))
	controlla(cause.contains("attrezzi"), "il pannello del Cibo dice degli attrezzi del fabbro")
	s.scegli_lavoro_officina(0, "armi")
	var att := s.attrezzi
	g = 0
	while g < 40 and not s.finito:
		s.legna = 200.0
		s.cibo = 5000.0
		s.pop = 600.0
		s.passo()
		while s.in_attesa():
			s.scegli(s.decisioni[0]["id"], s.decisioni[0]["opzioni"][0]["id"])
		g += 1
	controlla(s.armi > 0.3 and s.attrezzi < att, "con le armi salgono le armi (%d%%) e gli attrezzi si consumano (%d%%)" % [roundi(s.armi * 100.0), roundi(s.attrezzi * 100.0)])
	# Isolati: poco metallo, il fabbro lavora a metà.
	var iso := SimVillaggio.new(d, 41)
	iso.epoca = 2
	iso.soglia_scelta = "isolarsi"
	iso.fondato = true
	iso.officine = [{"punto": c, "cantiere": 0, "lavoro": "attrezzi"}]
	iso.legna = 200.0
	iso.ultima_legna = 100.0
	iso.metallo = 0.0
	for k in 30:
		iso._lavora_officine()
	controlla(iso.lavoro_fabbro < 0.5, "isolati, il metallo è poco e il fabbro lavora a metà (%d%%)" % roundi(iso.lavoro_fabbro * 100.0))
	# Il forno vicino alle case.
	controlla(iso.case_vicine_al_forno(c).size() == iso.case.filter(func(l: Vector2i) -> bool: return iso.centro_lotto(l).distance_to(c) < SimVillaggio.DISTANZA_FUOCO).size(), "le case a meno di %d m dal forno sono a rischio" % roundi(SimVillaggio.DISTANZA_FUOCO))
	# Fine del prototipo dell'epoca 2.
	s.anno = SimVillaggio.ANNO_FINE_EPOCA2
	s.passo()
	controlla(s.finito and s.decisioni.any(func(x: Dictionary) -> bool: return x["tipo"] == "fine"), "verso il 700 a.C. il prototipo dell'epoca 2 finisce")


## Epoca 2, il recinto e le zone dell'abitato (decisioni di Fede del 27/11/2026).
func _verifica_recinto(d: MappaDati, sito: Vector2i) -> void:
	var r := SimVillaggio.new(d, 41)
	r.fonda(sito)
	r.decisioni.clear()
	r.epoca = 2
	r.anno_epoca2 = r.anno
	r.pop = 400.0
	controlla(not r.sbloccato("recinto"), "all'inizio dell'epoca 2 il recinto non c'è ancora")
	r.anno += SimVillaggio.ANNI_SBLOCCO_RECINTO
	controlla(r.sbloccato("recinto") and not r.sbloccato("abitato"), "cento anni dopo il fabbro il recinto si sblocca (le zone ancora no)")
	var c := r.mondo_di_px(r.centro)
	var quadrato: Array = [c + Vector2(-200, -200), c + Vector2(200, -200), c + Vector2(200, 200), c + Vector2(-200, 200)]
	controlla(r.motivo_recinto([c + Vector2(-200, -200), c + Vector2(200, 200), c + Vector2(200, -200), c + Vector2(-200, 200)], true).contains("incrociarsi"), "il recinto non può incrociarsi")
	controlla(r.motivo_recinto([c, c + Vector2(40, 0), c + Vector2(0, 40)], true).contains("ettaro"), "dentro ci vuole almeno un ettaro")
	var m := r.motivo_recinto(quadrato, true)
	if m != "":
		print("   (recinto di prova: %s)" % m)
	controlla(r.traccia_recinto(quadrato) == "" and r.recinto_tratti == 160 and r.sbloccato("abitato"), "un recinto di 1600 m: 160 tratti, e si aprono le zone")
	controlla(r.porte.size() >= 1, "almeno una porta (%d)" % r.porte.size())
	r.legna = 1000.0
	r.ultima_legna = 0.0
	r._lavora_recinto()
	controlla(r.recinto_fatti == SimVillaggio.TRATTI_ANNO and is_equal_approx(r.legna, 1000.0 - SimVillaggio.TRATTI_ANNO * SimVillaggio.COSTO_TRATTO), "10 tratti l'anno, 3 di legna l'uno")
	controlla(not r.dentro_recinto(c), "finché non è finito il recinto non protegge")
	r.primo_governo = "Comunità"
	r._lavora_recinto()
	controlla(r.recinto_fatti == SimVillaggio.TRATTI_ANNO + SimVillaggio.TRATTI_ANNO_COMUNITA, "con la Comunità 15 tratti l'anno")
	r.legna = 0.0
	r.ultima_legna = 0.0
	var prima := r.recinto_fatti
	r._lavora_recinto()
	controlla(r.recinto_fatti == prima, "senza legna il cantiere si ferma")
	r.recinto_fatti = r.recinto_tratti
	controlla(r.recinto_pronto() and r.dentro_recinto(c) and not r.dentro_recinto(c + Vector2(400, 0)), "finito, il centro è dentro e fuori resta fuori")
	# Le case dentro non bruciano: case solo dentro il recinto, oltre i margini dell'abitato.
	r.case = []
	for k in 8:
		r.case.append(r.lotto_da_mondo(c.x + 170.0, c.y - 160.0 + k * 40.0))
	r.segni_punto = c + Vector2(170, 0)
	var bruciate := int(r.stat["case_bruciate"])
	for k in 40:
		r.cibo = 500.0
		r._scorreria()
	controlla(int(r.stat["case_bruciate"]) == bruciate, "le scorrerie non bruciano le case dentro il recinto")
	controlla(r.scorrerie_epoca2 >= 40, "le scorrerie dell'epoca 2 si contano (sbloccano il recinto)")
	# Il granaio dentro: le scorte rubate scendono.
	r.granaio = c + Vector2(60, 0)
	r.cantiere_granaio = 0
	var rubato_dentro := 0.0
	for k in 40:
		r.cibo = 1000.0
		r._scorreria()
		rubato_dentro += 1000.0 - r.cibo
	r.recinto_fatti = 0
	var rubato_fuori := 0.0
	for k in 40:
		r.cibo = 1000.0
		r._scorreria()
		rubato_fuori += 1000.0 - r.cibo
	controlla(rubato_dentro < rubato_fuori * 0.5, "con il granaio dentro il recinto le razzie rubano meno scorte (%d contro %d)" % [roundi(rubato_dentro), roundi(rubato_fuori)])
	r.recinto_fatti = r.recinto_tratti
	# Zone dell'abitato: le case nuove nascono nella zona, prima dentro; lungo le vie.
	r.case = []
	r.case_casale = {}
	r.tappa = 0
	var lotti: Array = []
	for y in range(-12, 13):
		for x in range(-12, 13):
			lotti.append(r.lotto_da_mondo(c.x, c.y) + Vector2i(x, y))
	for y in range(-4, 5):
		for x in range(14, 23):
			lotti.append(r.lotto_da_mondo(c.x, c.y) + Vector2i(x, y))
	var messi := r.aggiungi_zona_abitato(lotti)
	controlla(messi > 200, "la zona dell'abitato si dipinge a lotti (%d)" % messi)
	r.pop = 300.0
	r.disponi_case()
	var dentro := r.case.filter(func(l: Vector2i) -> bool: return r.dentro_recinto(r.centro_lotto(l))).size()
	var in_zona := r.case.filter(func(l: Vector2i) -> bool: return r.zona_abitato.has(l)).size()
	controlla(in_zona == r.case.size() and dentro == r.case.size(), "le case nuove nascono nella zona, dentro il recinto (%d su %d)" % [dentro, r.case.size()])
	var nuova: Vector2i = r.case[0]
	controlla(r.casa_su_impalcato(nuova), "le case nuove dell'epoca 2 sono su impalcato")
	r.sentieri.append(r.px(r.px_da_mondo(c.x + 120.0, c.y + 120.0)))
	controlla(r.lotti_lungo_le_vie().size() > 0, "i lotti lungo le vie si riconoscono")
	controlla(r.togli_zona_abitato(lotti) == messi and r.zona_abitato.is_empty(), "la zona si toglie con Togli")
	# Demolire il recinto.
	var esito := r.demolisci(c + Vector2(200, 0), 10.0)
	controlla(esito.get("recinto", false) and not r.recinto_tracciato(), "Demolisci toglie il recinto")


func _gioca(sim: SimVillaggio, sito: Vector2i, scelta_presagi := "") -> Dictionary:
	_caso_giocatore.seed = 12345
	sim.fonda(sito)
	var minimo_pop := sim.pop
	var massimo_case := 0
	var case_sbagliate := 0
	while not sim.finito and sim.anno < SimVillaggio.ANNO_PROVE:
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
	return {"pop": sim.pop, "minimo": minimo_pop, "case": massimo_case, "sbagliate": case_sbagliate, "abbandoni": sim.stat["abbandoni"], "carestie": sim.stat["carestie"], "piene": sim.stat["piene"], "scorrerie": sim.stat["scorrerie"]}


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
	# Legnaia (decisione di Fede del 25/11/2026; legna rifatta il 26/11/2026 sera): senza legnaia non si
	# raccoglie legna; la legna da ardere si raccoglie senza abbattere; i tronchi vengono dagli alberi
	# abbattuti uno alla volta, dal più vicino, e il fronte del taglio avanza piano.
	controlla(is_equal_approx(SimVillaggio.valore_albero(0, 1.15), 4.0) and SimVillaggio.valore_albero(7, 1.15) < 0.5 and SimVillaggio.valore_albero(9, 1.15) == 0.0, "ogni albero ha il suo valore: quercia media 4 m³, arbusto poco, canne niente")
	var tl := SimVillaggio.new(d, 3)
	tl.fonda(Vector2i(d.siti[2]["px"]))
	tl.decisioni.clear()
	tl.passo()
	controlla(tl.legnaie.is_empty() and tl.ultima_legna == 0.0, "appena fondato, con la legna portata da casa, nessuno va ancora a far legna")
	var cg := RandomNumberGenerator.new()
	cg.seed = 5
	var legna_prima := tl.legna
	tl.legna = 0.0
	controlla(AiutiGiocatori.costruisci_legnaia(tl, cg, 1.0) and tl.legnaie.size() == 1, "si costruisce una legnaia vicino al bosco, anche senza legna (solo braccia)")
	tl.legna = legna_prima
	var l0: Dictionary = tl.legnaie[0]
	controlla((l0["celle"] as Array).size() > 100 and float(l0["celle"][0][0]) <= float(l0["celle"][-1][0]), "la legnaia conosce gli alberi attorno, dal più vicino (%d celle)" % (l0["celle"] as Array).size())
	controlla(tl.capacita_legnaia(l0) == 0.0, "la legnaia in costruzione non raccoglie")
	for k in 3:
		tl.decisioni.clear()
		tl.passo()
	var cap0 := tl.capacita_legnaia(l0)
	controlla(cap0 > 0.0 and tl.raccolta_legna > 0.0 and tl.offerta_raccolta > 0.0, "finita la legnaia, si raccoglie legna da ardere (%.1f l'anno su %.1f) e si possono tagliare tronchi (fino a %.1f)" % [tl.raccolta_legna, tl.offerta_raccolta, cap0])
	var tagli_max := 0
	var primo_taglio := -1.0
	for k in 40:
		tl.decisioni.clear()
		tl.legna = 0.0
		# Il villaggio di prova non ha campi: senza poste e capanni (un terzo di caccia e pesca)
		# morirebbe di fame, e qui si prova solo la legnaia.
		tl.cibo = maxf(tl.cibo, tl.pop)
		tl.passo()
		tagli_max = maxi(tagli_max, tl.tagli_anno.size())
		if primo_taglio < 0.0 and not tl.celle_tagliate.is_empty():
			primo_taglio = float(l0["raggio"])
		tl.tagli_anno.clear()
	controlla(tl.tronchi_legna <= cap0 + 10.0 and tagli_max <= 40, "il taglio è progressivo: al massimo %d celle di alberi l'anno (tronchi %.1f)" % [tagli_max, tl.tronchi_legna])
	# Il limite della legnaia si conta in alberi (Fede, 27/11/2026): la capacità è ALBERI_TAGLIO alberi
	# del valore medio del bosco attorno.
	var vm := tl.valore_medio_legnaia(l0)
	controlla(vm > 0.5 and cap0 > 0.0 and cap0 <= SimVillaggio.ALBERI_TAGLIO * vm * 1.1 + 0.01, "una legnaia abbatte fino a %d alberi l'anno da %.1f m³ in media (%.0f m³)" % [roundi(SimVillaggio.ALBERI_TAGLIO), vm, cap0])
	controlla(SimVillaggio.valore_albero(0, 1.15) == 4.0 and SimVillaggio.valore_albero(0, 2.3) == 16.0, "una quercia media vale 4 m³, una grande il quadruplo")
	controlla(primo_taglio >= 0.0 and primo_taglio < 60.0, "si comincia dagli alberi attorno alla legnaia (primo taglio a %d m)" % roundi(primo_taglio))
	controlla(not tl.celle_tagliate.is_empty() and tl.capacita_legnaia(l0) < cap0 and float(l0["raggio"]) < 400.0, "il fronte avanza piano e i tronchi calano (%.1f → %.1f l'anno, fronte a %d m)" % [cap0, tl.capacita_legnaia(l0), roundi(float(l0["raggio"]))])
	var vicine_in_piedi := 0
	for voce in l0["celle"]:
		if float(voce[0]) < float(l0["raggio"]) * 0.5 and tl.cella_in_piedi(voce[1]):
			vicine_in_piedi += 1
	controlla(vicine_in_piedi == 0, "dietro il fronte non restano alberi da tagliare (gli abbattuti non ricrescono)")
	var una: Vector2i = (l0["fatte"] as Dictionary).keys()[0]
	# Zona di taglio: finché la legnaia lavora è un luogo di passaggio e non ricresce nulla (Fede,
	# 26/11/2026); a riposo il bosco ricaccia dalle ceppaie in ANNI_RICRESCITA anni.
	controlla(tl.legnaia_attiva(l0) and tl.celle_zona_attiva.has(una), "la zona di taglio della legnaia al lavoro resta aperta (%s)" % tl.stato_legnaia(l0))
	tl.anno += SimVillaggio.ANNI_RICRESCITA + 5
	l0["ultimo"] = tl.anno
	controlla(not tl.cella_in_piedi(una), "finché la zona è di passaggio il bosco non ricresce")
	tl.metti_a_riposo(0, true)
	controlla(not tl.legnaia_attiva(l0) and not tl.celle_zona_attiva.has(una) and tl.capacita_legnaia(l0) == 0.0, "lasciar ricrescere: la legnaia si ferma e la zona va a riposo")
	controlla(not tl.cella_in_piedi(una), "appena messa a riposo la zona è ancora tagliata")
	tl.anno += SimVillaggio.ANNI_RICRESCITA
	controlla(tl.cella_in_piedi(una), "dopo %d anni a riposo il bosco abbattuto ricresce" % SimVillaggio.ANNI_RICRESCITA)
	tl.metti_a_riposo(0, false)
	controlla(tl.legnaia_attiva(l0), "la legnaia torna al lavoro")
	# La catasta: due anni di consumo più il legname per costruire, e quanto accatasta ogni legnaia
	# (Fede, 27/11/2026: la legnaia serve il taglio e l'accumulo).
	controlla(tl.massimo_legna() < 2.5 * tl.consumo_legna + SimVillaggio.RISERVA_LEGNAME + SimVillaggio.COSTO_CASA + SimVillaggio.MAGAZZINO_LEGNAIA * tl.legnaie.size() + 1.0, "la catasta tiene due anni di consumo, il legname per costruire e quanto accatastano le legnaie (%d)" % roundi(tl.massimo_legna()))
	# Senza legnaie le famiglie vanno a far legna da sole, con il doppio della fatica (Fede, 27/11/2026).
	var sf := SimVillaggio.new(d, 3)
	sf.fonda(Vector2i(d.siti[2]["px"]))
	sf.decisioni.clear()
	sf.legna = 0.0
	sf.passo()
	controlla(sf.legnaie.is_empty() and sf.legna_famiglie > 0.0 and sf.fatica_legna > 0.0 and sf.legna > 0.0, "senza legnaie e senza legna le famiglie se la prendono da sole (%.0f, %.1f persone tolte ai campi)" % [sf.legna_famiglie, sf.fatica_legna])
	controlla(sf.fatica_legna <= sf.pop * SimVillaggio.QUOTA_FAMIGLIE_LEGNA + 0.01 and absf(sf.fatica_legna * SimVillaggio.RESA_FAMIGLIE - sf.legna_famiglie) < 0.01, "a far legna da sole vanno al più 3 persone su 10 (%.1f su %.0f)" % [sf.fatica_legna, sf.pop])
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
	_verifica_sacro(d)
	_verifica_pascolo(d)
	_verifica_scorrerie(d)
	_verifica_strade(d)
	_verifica_soglia(d)
	# Partite intere.
	var sopravvissuti := 0
	for s in d.siti:
		var sim2 := SimVillaggio.new(d, 100 + int(s["n"]))
		var r := _gioca(sim2, Vector2i(s["px"]))
		print("   sito %d %s: %d abitanti dopo 500 anni (minimo %d), fino a %d case, carestie %d, piene %d, scorrerie %d, abbandoni %d" % [s["n"], s["nome"], roundi(r["pop"]), roundi(r["minimo"]), r["case"], r["carestie"], r["piene"], r["scorrerie"], r["abbandoni"]])
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
