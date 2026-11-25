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


## Vero se le legnaie raccolgono meno della metà di ciò che servirebbe.
static func legna_scarsa(sim: SimVillaggio) -> bool:
	return sim.offerta_legna < sim.consumo_legna * 1.2
