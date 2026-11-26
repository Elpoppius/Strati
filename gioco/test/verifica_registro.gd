extends SceneTree
## Verifiche del registro tecnico (voce B del todo): il file si scrive, le righe hanno i campi
## giusti, le spunte della finestra Debug e i segnalibri finiscono nel registro, gli errori di
## Godot vengono raccolti, si tengono solo le ultime sessioni. Senza grafica.
## Uso: godot --headless --path gioco -s res://test/verifica_registro.gd

const CARTELLA := "user://verifica_registro"

var _errori := 0
var _s: Node
var _r: Registro
var _f := 0


func controlla(cond: bool, testo: String) -> void:
	print(("OK  " if cond else "ERRORE  ") + testo)
	if not cond:
		_errori += 1


func _initialize() -> void:
	# Cartella pulita, con 12 sessioni vecchie finte (una con la foto di un segnalibro).
	_svuota()
	DirAccess.make_dir_recursive_absolute(CARTELLA)
	for i in 12:
		var nome := "sessione-2026-01-%02d-120000" % (i + 1)
		FileAccess.open(CARTELLA.path_join(nome + ".txt"), FileAccess.WRITE).store_line("vecchia")
		if i == 0:
			FileAccess.open(CARTELLA.path_join(nome + "-segnalibro-1.png"), FileAccess.WRITE).store_line("foto")
	_s = load("res://scene/principale.tscn").instantiate()
	root.add_child(_s)


func _svuota() -> void:
	var d := DirAccess.open(CARTELLA)
	if d:
		for f in d.get_files():
			d.remove(f)


func _process(_d: float) -> bool:
	_f += 1
	if _f < 3:
		return false
	controlla(not Registro.per_questo_avvio() and _s.registro == null, "nelle verifiche e nelle foto il gioco non apre il registro da solo")
	_r = Registro.new()
	_s.add_child(_r)
	controlla(_r.avvia(_s, CARTELLA), "il registro si apre nella cartella voluta")
	controlla(_r.percorso.get_file().begins_with("sessione-") and _r.percorso.ends_with(".txt"), "un file di testo per sessione: " + _r.percorso.get_file())
	var d := DirAccess.open(CARTELLA)
	var sessioni := Array(d.get_files()).filter(func(f: String) -> bool: return f.ends_with(".txt"))
	controlla(sessioni.size() == Registro.SESSIONI_TENUTE, "si tengono le ultime %d sessioni (%d)" % [Registro.SESSIONI_TENUTE, sessioni.size()])
	controlla(not FileAccess.file_exists(CARTELLA.path_join("sessione-2026-01-01-120000-segnalibro-1.png")), "con una sessione vecchia se ne vanno anche le foto dei suoi segnalibri")
	controlla(FileAccess.file_exists(_r.percorso), "la sessione nuova resta")
	# Fotogrammi finti: 10 s a 50 fps con uno da 250 ms durante una rotazione.
	_r.campiona(0.02)
	_s.cam.yaw += 10.0  # la camera sta ruotando
	_r.campiona(0.02)
	_r.campiona(0.25)
	for i in 600:
		_r.campiona(1.0 / 60.0)
	# Uno strumento scelto e un errore di Godot.
	_s.hud.seleziona_comando("campi")
	_r.campiona(0.02)
	_r.campiona(0.18)
	push_error("errore di prova della verifica del registro")
	_r.campiona(0.016)
	_s.hud.seleziona_comando("")
	_r.spunta(Registro.PROVE[0], true)
	_r.spunta(Registro.PROVE[1], true)
	_r.spunta(Registro.PROVE[1], false)
	_r.apri_finestra(true)
	controlla(_r.finestra_aperta() and _r._caselle.size() == Registro.PROVE.size(), "la finestra Debug si apre con una casella per prova")
	controlla((_r._caselle[Registro.PROVE[0]] as Button).button_pressed and not (_r._caselle[Registro.PROVE[1]] as Button).button_pressed, "le caselle mostrano le spunte già date")
	(_r._caselle[Registro.PROVE[2]] as Button).button_pressed = true
	controlla(_r.spunte.has(Registro.PROVE[2]) and (_r._caselle[Registro.PROVE[2]] as Button).text.begins_with("■"), "spuntare una casella registra la spunta e riempie il quadratino")
	controlla((_r._caselle[Registro.PROVE[2]] as Button).focus_mode == Control.FOCUS_NONE, "le caselle non prendono lo Spazio della pausa")
	_r._aggiorna_finestra()
	controlla(_r._numeri.text.contains("fps") and _r._numeri.text.contains("figure"), "la finestra mostra i numeri dal vivo")
	_r.apri_finestra(false)
	_r.segnalibro()
	_r.chiudi()
	var testo := FileAccess.get_file_as_string(_r.percorso)
	var righe := testo.split("\n", false)
	print("--- registro ---\n" + testo + "--- fine ---")
	controlla(righe[0].begins_with("REGISTRO TECNICO DI STRATI"), "prima riga: il titolo (nessun ripiego)")
	controlla(testo.contains("Gioco: commit ") and testo.contains("Godot 4.7"), "intestazione: commit e versione di Godot")
	controlla(testo.contains("Sistema: ") and testo.contains("Scheda video: ") and testo.contains("Renderer: "), "intestazione: sistema, scheda video, renderer")
	var numeri := Array(righe).filter(func(r: String) -> bool: return r.contains("  fps "))
	controlla(numeri.size() >= 2, "righe dei numeri: ogni 10 s e alla chiusura (%d)" % numeri.size())
	var campi_ok := true
	for r in numeri:
		for campo in ["fps", "(min ", "più lento", "disegni", "memoria", "video", "zoom", "anno", "alberi", "animali", "figure"]:
			if not (r as String).contains(campo):
				campi_ok = false
				print("  manca «%s» in: %s" % [campo, r])
	controlla(campi_ok, "ogni riga dei numeri ha tutti i campi")
	controlla(numeri.size() > 0 and (numeri[0] as String).contains("più lento 250 ms"), "la prima riga dice il fotogramma più lento (250 ms)")
	controlla(testo.contains("LENTO  250 ms · rotazione"), "un fotogramma lento si scrive con cosa stava succedendo (rotazione)")
	controlla(testo.contains("LENTO  180 ms") and testo.contains("strumento campi"), "…e con lo strumento scelto")
	controlla(testo.contains("ERRORE  errore di prova della verifica del registro"), "gli errori di Godot finiscono nel registro")
	controlla(testo.contains("SPUNTA  " + Registro.PROVE[0]) and testo.contains("SPUNTA TOLTA  " + Registro.PROVE[1]) and testo.contains("SPUNTA  " + Registro.PROVE[2]), "le spunte (anche tolte) finiscono nel registro con l'ora")
	controlla(testo.contains("SEGNALIBRO  n. 1 · camera x ") and testo.contains("zoom "), "il segnalibro scrive ora e posizione della camera")
	controlla(testo.contains("DEBUG  finestra aperta") and testo.contains("DEBUG  finestra chiusa"), "aprire e chiudere la finestra Debug si registra")
	controlla(righe[righe.size() - 1].contains("FINE  fine della sessione"), "l'ultima riga chiude la sessione")
	var ora_ok := true
	for r in righe:
		if (r as String).contains("  ") and not (r as String).begins_with("Ogni") and not RegEx.create_from_string("^\\d\\d:\\d\\d:\\d\\d  ").search(r):
			ora_ok = false
			print("  riga senza ora: " + r)
	controlla(ora_ok, "eventi e numeri cominciano con l'ora")
	_r.evento("prova", "dopo la chiusura")
	controlla(not FileAccess.get_file_as_string(_r.percorso).contains("dopo la chiusura"), "dopo la chiusura non si scrive più")
	controlla(Registro.commit() != "", "il commit si legge (o «sconosciuto»): " + Registro.commit())
	_svuota()
	print("\n%s: %d errori" % ["VERIFICA REGISTRO SUPERATA" if _errori == 0 else "VERIFICA REGISTRO FALLITA", _errori])
	quit(1 if _errori > 0 else 0)
	return true
