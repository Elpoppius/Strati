class_name AiutiGiocatori
extends RefCounted
## Gesti comuni dei giocatori automatici (sessioni, registro, giocatori "umani").


## Costruisce una legnaia. qualita da 0 (dove capita, vicino al villaggio) a 1 (il punto con il
## bosco più vicino e più fitto entro 800 m). Restituisce vero se l'ha costruita.
static func costruisci_legnaia(sim: SimVillaggio, caso: RandomNumberGenerator, qualita: float) -> bool:
	var c := sim.mondo_di_px(sim.centro)
	var candidati: Array[Vector2] = []
	for r: float in [120.0, 250.0, 400.0, 550.0, 700.0, 850.0, 950.0]:
		for k in 16:
			var a := k * TAU / 16.0 + r * 0.01
			var p := c + Vector2(cos(a), sin(a)) * r
			if sim.motivo_legnaia(p) == "" and not _vicino_a_legnaia(sim, p):
				candidati.append(p)
	if candidati.is_empty():
		return false
	# Dove capita: tra i punti vicini al villaggio.
	var scelto: Vector2 = candidati[caso.randi() % mini(candidati.size(), 16)]
	if caso.randf() < qualita:
		# Dove si vedono gli alberi: il punto con il bosco più vicino, poi il più fitto.
		var meglio := -1e9
		for p in candidati:
			var b := sim.bosco_per_legnaia(p)
			var vicino: float = b["vicino"]
			if vicino < 0.0:
				continue
			var v := -vicino / 100.0 + float(b["quota"]) - p.distance_to(c) / 2000.0
			if v > meglio:
				meglio = v
				scelto = p
	return sim.costruisci_legnaia(scelto) == ""


## I giocatori automatici non ammassano le legnaie nello stesso bosco (il gioco lo permette).
static func _vicino_a_legnaia(sim: SimVillaggio, p: Vector2) -> bool:
	for l in sim.legnaie:
		if (l["punto"] as Vector2).distance_to(p) < 150.0:
			return true
	return false


## Costruisce una posta di caccia (caccia vero) o un capanno da pesca. qualita da 0 (dove capita:
## uno dei punti buoni più vicini al villaggio) a 1 (dove la resa stimata è più alta). Il gioco
## aggancia l'edificio alla riva o al margine del bosco. Restituisce vero se l'ha costruito.
static func costruisci_edificio_risorse(sim: SimVillaggio, caso: RandomNumberGenerator, qualita: float, caccia: bool) -> bool:
	var c := sim.mondo_di_px(sim.centro)
	var candidati: Array[Vector2] = []
	for r: float in [80.0, 200.0, 350.0, 500.0, 650.0, 800.0, 950.0]:
		for k in 16:
			var a := k * TAU / 16.0 + r * 0.01
			var posa := sim.posa_posta(c + Vector2(cos(a), sin(a)) * r) if caccia else sim.posa_capanno(c + Vector2(cos(a), sin(a)) * r)
			if posa["motivo"] != "":
				continue
			var p: Vector2 = posa["punto"]
			if candidati.any(func(q: Vector2) -> bool: return q.distance_to(p) < 60.0):
				continue
			candidati.append(p)
	if candidati.is_empty():
		return false
	var scelto: Vector2 = candidati[caso.randi() % mini(candidati.size(), 4)]
	if caso.randf() < qualita:
		var meglio := -1e9
		for p in candidati:
			var prova := {"punto": p, "cantiere": 0}
			if not caccia:
				prova["acqua"] = sim.posa_capanno(p)["acqua"]
			var v := float(sim.stima_edificio(prova)["resa"]) - p.distance_to(c) / 100.0
			if v > meglio:
				meglio = v
				scelto = p
	return (sim.costruisci_posta(scelto) if caccia else sim.costruisci_capanno(scelto)) == ""


## Vero se poste (caccia) o capanni (pesca) danno meno di quanto il villaggio vorrebbe prendere.
static func risorsa_scarsa(sim: SimVillaggio, caccia: bool) -> bool:
	var dagli_edifici := 0.0
	for e in (sim.poste if caccia else sim.capanni):
		dagli_edifici += float(e["offerta"]) if int(e["cantiere"]) <= 0 else (SimVillaggio.CAPACITA_POSTA if caccia else SimVillaggio.CAPACITA_CAPANNO)
	return dagli_edifici < sim.pop * (SimVillaggio.QUOTA_CACCIA if caccia else SimVillaggio.QUOTA_PESCA) * 0.8


## Erige il luogo sacro vicino al centro, sul primo lotto libero di un giro di prove. Vero se fatto.
static func costruisci_luogo_sacro(sim: SimVillaggio) -> bool:
	var c := sim.mondo_di_px(sim.centro)
	for r: float in [60.0, 120.0, 200.0, 300.0]:
		for k in 12:
			var a := k * TAU / 12.0
			if sim.costruisci_luogo_sacro(c + Vector2(cos(a), sin(a)) * r) == "":
				return true
	return false


## Officina del fabbro (epoca 2, 27/11/2026): qualita alta cerca il posto che rende di più (acqua e
## legnaia vicine) e lontano dalle case; qualita bassa prende il primo che va bene, anche fra le case.
static func costruisci_officina(sim: SimVillaggio, caso: RandomNumberGenerator, qualita: float) -> bool:
	var c := sim.mondo_di_px(sim.centro)
	var migliore := Vector2(-1, -1)
	var meglio := -INF
	var giro := caso.randf() * TAU
	for r: float in [60.0, 120.0, 200.0, 300.0, 450.0]:
		for k in 12:
			var w := c + Vector2.from_angle(giro + k * TAU / 12.0) * r
			if sim.motivo_officina(w) != "":
				continue
			if caso.randf() > qualita:
				return sim.costruisci_officina(w) == ""
			var valore := sim.rendimento_officina({"punto": w}) - (1.0 if not sim.case_vicine_al_forno(w).is_empty() else 0.0) - r / 2000.0
			if valore > meglio:
				meglio = valore
				migliore = w
	return migliore.x >= 0 and sim.costruisci_officina(migliore) == ""


## Recinto (epoca 2, 27/11/2026): un anello di otto punti attorno all'abitato, largo quanto le case
## del nucleo più un margine (con qualita alta anche il granaio dentro); se non si può, più stretto.
static func traccia_recinto(sim: SimVillaggio, caso: RandomNumberGenerator, qualita: float) -> bool:
	var c := sim.mondo_di_px(sim.centro)
	var raggio := 80.0
	for l in sim.case_nel_nucleo():
		raggio = maxf(raggio, sim.centro_lotto(l).distance_to(c) + 30.0)
	if qualita >= 0.6 and sim.granaio.x >= 0:
		raggio = maxf(raggio, sim.granaio.distance_to(c) + 40.0)
	raggio *= lerpf(0.75, 1.1, qualita) + caso.randf_range(-0.05, 0.05)
	var giro := caso.randf() * TAU
	for k in 8:
		var anello: Array = []
		for j in 8:
			var w := c + Vector2.from_angle(giro + j * TAU / 8.0) * raggio
			anello.append(sim.centro_lotto(sim.lotto_da_mondo(w.x, w.y)))
		if sim.traccia_recinto(anello) == "":
			return true
		raggio *= 0.85
	return false


## Zona dell'abitato (epoca 2): i lotti dentro il recinto; chi conosce il genere anche una fascia fuori.
static func stendi_abitato(sim: SimVillaggio, caso: RandomNumberGenerator, qualita: float) -> int:
	var c := sim.mondo_di_px(sim.centro)
	var raggio := 120.0
	if sim.recinto_tracciato():
		raggio = 0.0
		for p in sim.recinto_punti:
			raggio = maxf(raggio, (p as Vector2).distance_to(c))
	raggio *= lerpf(0.7, 1.15, qualita) + caso.randf_range(-0.05, 0.05)
	var lotti: Array = []
	var l0 := sim.lotto_da_mondo(c.x - raggio, c.y - raggio)
	var l1 := sim.lotto_da_mondo(c.x + raggio, c.y + raggio)
	for y in range(l0.y, l1.y + 1):
		for x in range(l0.x, l1.x + 1):
			var l := Vector2i(x, y)
			if sim.centro_lotto(l).distance_to(c) <= raggio:
				lotti.append(l)
	return sim.aggiungi_zona_abitato(lotti)


## Torre di avvistamento (scorrerie, 26/11/2026): qualita 1 cerca l'altura più alta vicino al
## villaggio; qualita bassa prende la prima che va bene, girando a caso.
static func costruisci_torre(sim: SimVillaggio, caso: RandomNumberGenerator, qualita: float) -> bool:
	var c := sim.mondo_di_px(sim.centro)
	var migliore := Vector2(-1, -1)
	var piu_alto := -INF
	var giro := caso.randf() * TAU
	for r: float in [200.0, 350.0, 500.0, 700.0, 900.0, 1100.0]:
		for k in 16:
			var w := c + Vector2.from_angle(giro + k * TAU / 16.0) * r
			if sim.motivo_torre(w) != "":
				continue
			if qualita < 0.6:
				return sim.costruisci_torre(w) == ""
			var ril := sim.rilievo(sim.px_da_mondo(w.x, w.y)) - r / 1000.0
			if ril > piu_alto:
				piu_alto = ril
				migliore = w
	return migliore.x >= 0 and sim.costruisci_torre(migliore) == ""


## Stende il bosco sacro: qualita 1 sceglie il bosco più vicino al villaggio e ne stende circa
## `ettari`; qualita bassa ne stende meno, dove capita. Restituisce gli ettari stesi.
static func stendi_bosco_sacro(sim: SimVillaggio, caso: RandomNumberGenerator, qualita: float, ettari: float) -> float:
	var c := sim.centro
	var candidati: Array[Vector2i] = []
	var r := ceili(SimVillaggio.DISTANZA_BOSCO_SACRO / sim.dati.metri_per_px)
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var p := c + Vector2i(dx, dy)
			if sim.motivo_bosco_sacro(p) == "":
				candidati.append(p)
	if candidati.is_empty():
		return 0.0
	# Un punto di partenza (il bosco più vicino, o uno a caso) e i pixel di bosco attorno a lui.
	var inizio: Vector2i = candidati[caso.randi() % candidati.size()]
	if caso.randf() < qualita:
		candidati.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return (a - c).length_squared() < (b - c).length_squared())
		inizio = candidati[0]
	candidati.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return (a - inizio).length_squared() < (b - inizio).length_squared())
	var quanti := int(ettari * (0.4 + 0.6 * qualita) / SimVillaggio.AREA_PIXEL_HA)
	sim.aggiungi_bosco_sacro(candidati.slice(0, quanti))
	return sim.ettari_bosco_sacro()


## Stende circa `ettari` di pascolo. qualita 1: dal prato più vicino al villaggio, evitando i
## pendii e prendendo i campi stanchi (che diventano maggese); qualita bassa: da un punto a caso.
## Restituisce gli ettari di pascolo.
static func stendi_pascolo(sim: SimVillaggio, caso: RandomNumberGenerator, qualita: float, ettari: float) -> float:
	var c := sim.centro
	var r := ceili(sim.raggio_contado() / sim.dati.metri_per_px)
	var candidati: Array[Vector2i] = []
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var p := c + Vector2i(dx, dy)
			if sim.motivo_pascolo(p) == "" and not sim.pascolo.has(sim.px(p)):
				candidati.append(p)
	if candidati.is_empty():
		return 0.0
	var bravo := caso.randf() < qualita
	var peso := func(p: Vector2i) -> float:
		var i := sim.px(p)
		var v := (p - c).length()
		if bravo:
			v += (6.0 if sim._pendio(i) else 0.0) - (4.0 if sim.campi.has(i) and sim.fattore_stanchezza(i) < 0.9 else 0.0) + (2.0 if sim.campi.has(i) else 0.0)
		return v
	var inizio: Vector2i = candidati[caso.randi() % candidati.size()]
	if bravo:
		var meglio := INF
		for p in candidati:
			var v: float = peso.call(p)
			if v < meglio:
				meglio = v
				inizio = p
	candidati.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return (a - inizio).length_squared() + (peso.call(a) if bravo else 0.0) < (b - inizio).length_squared() + (peso.call(b) if bravo else 0.0))
	var quanti := int(ettari * (0.4 + 0.6 * qualita) / SimVillaggio.AREA_PIXEL_HA)
	sim.aggiungi_pascolo(candidati.slice(0, quanti))
	return sim.pascolo.size() * SimVillaggio.AREA_PIXEL_HA


## Vero se la legna non basta: poca in catasta mentre mancano case, o legnaie che portano meno di
## ciò che si consuma (legna alla maniera dei giochi di strategia, 27/11/2026 sera).
static func legna_scarsa(sim: SimVillaggio) -> bool:
	if sim.legna >= SimVillaggio.COSTO_CASA * 2.0:
		return false
	return sim.affollamento > 0.05 or sim.offerta_legna < sim.consumo_legna * 1.2


## Sentieri verso i luoghi di lavoro lontani (voce 5, 26/11/2026): dalla rete (o dal centro) fino a
## legnaie, casali, luogo sacro e campi più lontani. qualita: quanti ne traccia (da 0 a 1).
static func traccia_sentieri_lavoro(sim: SimVillaggio, caso: RandomNumberGenerator, qualita: float) -> int:
	var mete: Array[Vector2] = []
	for l in sim.legnaie:
		mete.append(l["punto"])
	for c in sim.casali:
		mete.append(sim.centro_lotto(c))
	if sim.luogo_sacro.x >= 0:
		mete.append(sim.luogo_sacro)
	if not sim.campi.is_empty():
		var lontano: int = sim.campi[0]
		for i in sim.campi:
			if sim.mondo_di_px(sim.px_di(i)).distance_to(sim.mondo_di_px(sim.centro)) > sim.mondo_di_px(sim.px_di(lontano)).distance_to(sim.mondo_di_px(sim.centro)):
				lontano = i
		mete.append(sim.mondo_di_px(sim.px_di(lontano)))
	var fatti := 0
	for w in mete:
		if w.distance_to(sim.mondo_di_px(sim.centro)) < 200.0 or caso.randf() > qualita:
			continue
		if sim.nodo_vicino(w, 120.0) >= 0:
			continue
		if sim.traccia_sentiero(sim.px_da_mondo(w.x, w.y)) == "":
			fatti += 1
	return fatti

