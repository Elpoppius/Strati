extends SceneTree
## Converte i dati grezzi di una mappa (generati da strumenti/mappe/*.py) in una risorsa Godot.
## Uso: godot --headless --path gioco -s res://strumenti/importa_mappa.gd -- pedecollinare

const MappaDatiScript := preload("res://script/mappa_dati.gd")


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var nome := args[0] if args.size() > 0 else "pedecollinare"
	var base := "res://mappe/%s" % nome
	var meta_testo := FileAccess.get_file_as_string(base + "/meta.json")
	var meta = JSON.parse_string(meta_testo)
	if meta == null:
		push_error("meta.json mancante o non valido in " + base)
		quit(1)
		return
	var d = MappaDatiScript.new()
	d.nome = meta["nome"]
	d.lato = int(meta["lato_px"])
	d.metri_per_px = float(meta["metri_per_px"])
	d.quota_min = float(meta["quota_min"])
	d.quota_max = float(meta["quota_max"])
	d.altezze = FileAccess.get_file_as_bytes(base + "/grezzi/altezze.f32").to_float32_array()
	d.tipo = FileAccess.get_file_as_bytes(base + "/grezzi/tipo.u8")
	d.zona = FileAccess.get_file_as_bytes(base + "/grezzi/zona.u8")
	d.fertilita = FileAccess.get_file_as_bytes(base + "/grezzi/fertilita.u8")
	d.piena = FileAccess.get_file_as_bytes(base + "/grezzi/piena.u8")
	d.acqua = FileAccess.get_file_as_bytes(base + "/grezzi/acqua.u8")
	d.acqua_stagionale = FileAccess.get_file_as_bytes(base + "/grezzi/acqua_stagionale.u8")
	d.copertura = FileAccess.get_file_as_bytes(base + "/grezzi/copertura.u8")
	d.distanza_acqua = FileAccess.get_file_as_bytes(base + "/grezzi/distanza_acqua.u8")
	d.bosco_fine = FileAccess.get_file_as_bytes(base + "/grezzi/bosco_fine.u8")
	d.palude_fine = FileAccess.get_file_as_bytes(base + "/grezzi/palude_fine.u8")
	d.pozze_fine = FileAccess.get_file_as_bytes(base + "/grezzi/pozze_fine.u8")
	d.lato_acqua = int(meta.get("lato_acqua_px", d.lato))
	# Idraulica (24/11/2026): corrente, potenza, corsi d'acqua e siti per le dighe.
	if FileAccess.file_exists(base + "/grezzi/velocita.u8"):
		d.velocita = FileAccess.get_file_as_bytes(base + "/grezzi/velocita.u8")
		d.potenza = FileAccess.get_file_as_bytes(base + "/grezzi/potenza.u8")
	d.corsi_acqua = meta.get("corsi_acqua", [])
	var siti_diga := []
	for s in meta.get("siti_diga", []):
		var c: Dictionary = s.duplicate()
		c["px"] = Vector2(s["px"][0], s["px"][1])
		siti_diga.append(c)
	d.siti_diga = siti_diga
	var sorgenti := PackedVector2Array()
	for s in meta["sorgenti_px"]:
		sorgenti.append(Vector2(s[0], s[1]))
	d.sorgenti = sorgenti
	var siti := []
	for s in meta["siti"]:
		siti.append({"n": int(s["n"]), "nome": s["nome"], "px": Vector2(s["px"][0], s["px"][1])})
	d.siti = siti
	var n: int = d.lato * d.lato
	for campo in ["altezze", "tipo", "zona", "fertilita", "piena", "acqua", "acqua_stagionale", "copertura"]:
		if d.get(campo).size() != n:
			push_error("Lo strato %s ha %d valori invece di %d" % [campo, d.get(campo).size(), n])
			quit(1)
			return
	if d.distanza_acqua.size() != d.lato_acqua * d.lato_acqua or d.bosco_fine.size() != d.lato_acqua * d.lato_acqua or d.palude_fine.size() != d.lato_acqua * d.lato_acqua or d.pozze_fine.size() != d.lato_acqua * d.lato_acqua:
		push_error("Gli strati distanza_acqua o bosco_fine hanno una dimensione inattesa")
		quit(1)
		return
	var esito := ResourceSaver.save(d, base + "/mappa.res")
	if esito != OK:
		push_error("Salvataggio fallito: %d" % esito)
		quit(1)
		return
	print("Mappa %s salvata in %s/mappa.res (%dx%d px)" % [d.nome, base, d.lato, d.lato])
	quit(0)
