extends SceneTree
## Verifiche sull'idraulica della mappa (corrente, potenza, siti per le dighe), senza grafica.
## Uso: godot --headless --path gioco -s res://test/verifica_acqua.gd

var _errori := 0
var _s: Node
var _f := 0


func controlla(cond: bool, testo: String) -> void:
	print(("OK  " if cond else "ERRORE  ") + testo)
	if not cond:
		_errori += 1


func _initialize() -> void:
	_s = load("res://scene/principale.tscn").instantiate()
	root.add_child(_s)


func _process(_d: float) -> bool:
	_f += 1
	if _f < 3:
		return false
	var d: MappaDati = _s.dati
	var n := d.lato * d.lato
	controlla(d.velocita.size() == n and d.potenza.size() == n, "strati di velocità e potenza presenti")
	controlla(d.corsi_acqua.size() == 3, "tre corsi d'acqua descritti")
	for c in d.corsi_acqua:
		print("   %s (%s): portata media %s m³/s, da %d a %d m, pendenza max %s‰, corrente max %s m/s, %s kW max ogni 100 m" % [
			c["nome"], c["regime"], c["portata_media_m3s"], c["quota_monte_m"], c["quota_valle_m"],
			c["pendenza_max_per_mille"], c["velocita_max_ms"], c["potenza_max_kw_100m"]])
		controlla(c["quota_monte_m"] > c["quota_valle_m"] and c["velocita_max_ms"] > 0.3 and c["velocita_max_ms"] <= 4.0, "%s: scende verso valle con una corrente verosimile" % c["nome"])
	# Corrente sull'acqua, niente lontano dall'acqua.
	var sull_acqua := 0
	var fuori := 0
	var max_colline := 0.0
	var max_pianura := 0.0
	for i in n:
		var t := d.tipo[i]
		if t >= MappaDati.FIUME and t <= MappaDati.TORRENTE_EST:
			if d.velocita[i] > 0:
				sull_acqua += 1
			var kw := MappaDati.kw_da_byte(d.potenza[i])
			if t == MappaDati.FIUME:
				if d.zona[i] == 3:
					max_colline = maxf(max_colline, kw)
				elif d.zona[i] == 0:
					max_pianura = maxf(max_pianura, kw)
		elif d.acqua_stagionale[i] == 0 and d.velocita[i] > 0:
			fuori += 1
	controlla(sull_acqua > 500, "c'è corrente su fiumi e torrenti (%d pixel)" % sull_acqua)
	controlla(fuori == 0, "nessuna corrente lontano dall'acqua")
	controlla(max_colline > max_pianura * 2.0, "il fiume ha più potenza in collina (%.0f kW) che in bassa pianura (%.0f kW)" % [max_colline, max_pianura])
	# Dighe: solo dove la valle si chiude, in collina o al suo piede.
	controlla(d.siti_diga.size() >= 3, "ci sono siti per le dighe (%d)" % d.siti_diga.size())
	var buoni := true
	for s in d.siti_diga:
		var p: Vector2 = s["px"]
		var z := d.zona[d.indice(int(p.x), int(p.y))]
		if z < 1 or int(s["lunghezza_m"]) > 1500 or float(s["volume_milioni_m3"]) <= 0.0:
			buoni = false
	controlla(buoni, "i siti per le dighe stanno dove la valle si chiude, con un invaso")
	# Lettura del lotto sul fiume e mappa tematica.
	var fiume := Vector2(-1, -1)
	for i in n:
		if d.tipo[i] == MappaDati.FIUME and d.zona[i] == 3:
			fiume = d.mondo_da_pixel(Vector2(i % d.lato, i / d.lato))
			break
	var testo: String = _s.testo_lettura(fiume.x, fiume.y)
	controlla(testo.contains("corrente") and testo.contains("kW") and testo.contains("perenne"), "la lettura del fiume dice corrente, potenza e regime: " + testo)
	_s.imposta_modo(4)
	controlla(_s.modo == 4 and _s._segni_dighe.size() > 0 and _s._segni_dighe[0].visible, "mappa dell'energia dell'acqua con i siti per le dighe (%d)" % _s._segni_dighe.size())
	_s.imposta_modo(0)
	controlla(not _s._segni_dighe[0].visible, "fuori da quella mappa i siti per le dighe non si vedono")
	print("Verifica completata: " + ("nessun errore" if _errori == 0 else "%d errori" % _errori))
	quit(1 if _errori > 0 else 0)
	return true
