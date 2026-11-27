class_name Registro
extends Node
## Registro tecnico in gioco (voce B del todo, richiesta di Fede del 26/11/2026).
## Mentre Fede gioca, il gioco scrive da solo le questioni tecniche (fotogrammi al secondo, tempi
## di caricamento, fotogrammi lenti, errori di Godot), così nelle prove lui guarda la direzione
## artistica e Claude legge il registro.
## - Cartella: D:\Godot\Strati\Registro sui PC di Fede (decisione di Fede); se il disco D: non c'è o
##   non si può scrivere, user://registro/, e la prima riga lo dice.
## - Un file di testo per sessione di gioco; si tengono gli ultimi SESSIONI_TENUTE.
## - Ogni INTERVALLO secondi una riga di numeri; in mezzo gli eventi.
## - F3: finestra Debug con i numeri dal vivo e le prove da verificare (le spunte finiscono nel registro).
## - F9: segnalibro con l'ora, la posizione della camera e una foto dello schermo.

const CARTELLA_PC := "D:/Godot/Strati/Registro"
const CARTELLA_RISERVA := "user://registro"
const SESSIONI_TENUTE := 10
const INTERVALLO := 10.0
## Un fotogramma che dura più di così si scrive come evento, con cosa stava succedendo.
const SOGLIA_LENTO_MS := 100.0
## Al massimo tanti eventi di fotogrammi lenti per riga di numeri: un caricamento lungo non deve
## riempire il registro di righe uguali (le altre si contano e basta).
const LENTI_PER_INTERVALLO := 5

## Prove aperte del todo (26/11/2026 sera) da spuntare nella finestra Debug. Quando una prova si chiude
## o se ne apre una nuova, si cambia questo elenco.
const PROVE := [
	# Tutte le prove aperte per la prova al PC di Fede (aggiornate il 26/11/2026 notte, todo).
	"Legna: alberi tagliati uno alla volta dalla legnaia",
	"Scheda della legnaia (al lavoro, a riposo)",
	"Cursori, cornice di selezione, puntatore rosso",
	"HUD fermo; strumenti che compaiono con la tappa",
	"Edifici delle risorse alla misura delle case",
	"Specchietti: Conseguenze e Rapporti di forza (R)",
	"Scorrerie: segni, scelta, torre (Prova: Scorreria)",
	"Strade: traffico con Sentiero, strade, passerelle",
	"Figure che camminano lungo sentieri e strade",
	"Case: varianti con orto, cataste, tettoia",
	"Piena: l'acqua sale e si ritira",
	"Salvare (F5) e riprendere (F8) una partita",
	"Salvataggi automatici (tappe, ogni 50 anni)",
	"Tempo a decenni dopo il 5600 a.C.: fluido?",
	"Metallo: presagi, scelta, riepilogo (Prova: Metallo)",
	"Fotogrammi al secondo a decenni e da vicino",
	"Impostazioni (F10): qualità, scala, schermo intero",
	# Epoca 2 (27/11/2026): dopo Prova › Metallo, l'officina del fabbro.
	"Fabbro (M): officina, fumo, scheda attrezzi/armi",
	"Epoca 2: vesti nuove delle persone",
	"Recinto (J): tracciare, chiudere, cantiere, porte",
	"Zona dell'abitato: case dentro, sulla via, su impalcato",
]

var cartella := ""
var percorso := ""
## Vero se si è dovuto ripiegare su user://registro.
var di_riserva := false
var attivo := false
var scena: Node  # la scena principale (camera, partita, alberi); può mancare nelle verifiche
var spunte := {}  # prova -> vero

var _file: FileAccess
var _nome := ""
var _segnalibri := 0
var _tempo := 0.0
var _fotogrammi := 0
var _piu_lento := 0.0
var _min_fps := 1.0e9
var _secondo := 0.0
var _fotogrammi_secondo := 0
var _lenti := 0
var _lenti_taciuti := 0
var _anno_prima := 0
var _yaw_prima := NAN
var _contesto: Array[String] = []
var _logger: _Ascolto
var _finestra: PanelContainer
var _numeri: Label
var _caselle := {}  # prova -> Button (interruttore)
var _tempo_finestra := 0.0
var _ultimi := {}  # ultimi numeri misurati, per la finestra


## Il registro parte solo nel gioco vero: le verifiche e le foto di controllo (test/*.gd) girano
## senza, altrimenti riempirebbero la cartella di sessioni finte.
static func per_questo_avvio() -> bool:
	var ml := Engine.get_main_loop()
	return ml == null or ml.get_script() == null


## Apre il file della sessione e scrive l'intestazione. cartella_voluta vuota: D:\Godot\Strati\Registro
## su Windows, altrimenti la cartella di riserva.
func avvia(s: Node = null, cartella_voluta := "") -> bool:
	scena = s
	var candidate: Array[String] = []
	if cartella_voluta != "":
		candidate.append(cartella_voluta)
	else:
		# Solo su Windows: altrove "D:/…" sarebbe una cartella relativa.
		if OS.get_name() == "Windows":
			candidate.append(CARTELLA_PC)
		candidate.append(CARTELLA_RISERVA)
	var ora := Time.get_datetime_dict_from_system()
	_nome = "sessione-%04d-%02d-%02d-%02d%02d%02d" % [ora["year"], ora["month"], ora["day"], ora["hour"], ora["minute"], ora["second"]]
	for c in candidate:
		if DirAccess.make_dir_recursive_absolute(c) != OK and not DirAccess.dir_exists_absolute(c):
			continue
		var p := c.path_join(_nome + ".txt")
		# Due avvii nello stesso secondo (Nuova partita): un suffisso.
		var n := 2
		while FileAccess.file_exists(p):
			p = c.path_join("%s-%d.txt" % [_nome, n])
			n += 1
		var f := FileAccess.open(p, FileAccess.WRITE)
		if f == null:
			continue
		_file = f
		cartella = c
		percorso = p
		_nome = p.get_file().get_basename()
		di_riserva = cartella_voluta == "" and c == CARTELLA_RISERVA and OS.get_name() == "Windows"
		break
	if _file == null:
		return false
	attivo = true
	_intestazione()
	_pulisci_vecchie()
	_logger = _Ascolto.new()
	OS.add_logger(_logger)
	_anno_prima = _anno()
	return true


func _exit_tree() -> void:
	chiudi()


func chiudi() -> void:
	if not attivo:
		return
	_svuota_errori()
	if _fotogrammi > 0:
		scrivi_riga()
	evento("fine", "fine della sessione")
	if _logger:
		OS.remove_logger(_logger)
		_logger = null
	_file.close()
	_file = null
	attivo = false


# ---------- intestazione ----------

func _intestazione() -> void:
	if di_riserva:
		_scrivi("ATTENZIONE: %s non si può usare, il registro è in %s" % [CARTELLA_PC.replace("/", "\\"), ProjectSettings.globalize_path(cartella)])
	_scrivi("REGISTRO TECNICO DI STRATI · %s" % Time.get_datetime_string_from_system(false, true))
	var info := Engine.get_version_info()
	_scrivi("Gioco: commit %s · Godot %s" % [commit(), info.get("string", "")])
	_scrivi("Sistema: %s %s · %s (%d processori) · memoria %s" % [OS.get_name(), OS.get_version(), OS.get_processor_name(), OS.get_processor_count(), _mb(int(OS.get_memory_info().get("physical", 0)))])
	var driver := OS.get_video_adapter_driver_info()
	var scheda := [RenderingServer.get_video_adapter_name(), RenderingServer.get_video_adapter_vendor(),
		"driver " + " ".join(driver) if not driver.is_empty() else "", RenderingServer.get_video_adapter_api_version()]
	scheda = scheda.filter(func(v: String) -> bool: return v.strip_edges() != "")
	_scrivi("Scheda video: " + (" · ".join(scheda) if not scheda.is_empty() else "non disponibile (senza grafica)"))
	var metodo := str(ProjectSettings.get_setting("rendering/renderer/rendering_method", ""))
	var dim := DisplayServer.window_get_size() if DisplayServer.get_name() != "headless" else Vector2i.ZERO
	var schermo := DisplayServer.screen_get_size() if DisplayServer.get_name() != "headless" else Vector2i.ZERO
	_scrivi("Renderer: %s · finestra %d×%d · schermo %d×%d · sincronia verticale %s" % [metodo, dim.x, dim.y, schermo.x, schermo.y,
		"sì" if DisplayServer.get_name() != "headless" and DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED else "no"])
	# Mappa e seme arrivano con l'evento PARTITA, quando la partita è pronta.
	_scrivi("Ogni %d s una riga: ora · fps medi (minimo) · fotogramma più lento · disegni · memoria · video · zoom · anno · alberi · animali · figure" % int(INTERVALLO))
	_scrivi("-".repeat(60))


## Il commit del gioco, letto dalla cartella .git accanto al progetto (sui PC di Fede il progetto
## sta dentro il repository). "sconosciuto" se non c'è.
static func commit() -> String:
	var git := ProjectSettings.globalize_path("res://").path_join("../.git")
	var head := FileAccess.get_file_as_string(git.path_join("HEAD")).strip_edges()
	if head == "":
		return "sconosciuto"
	if not head.begins_with("ref:"):
		return head.substr(0, 7)
	var ref := head.substr(4).strip_edges()
	var h := FileAccess.get_file_as_string(git.path_join(ref)).strip_edges()
	if h == "":
		for riga in FileAccess.get_file_as_string(git.path_join("packed-refs")).split("\n"):
			if riga.ends_with(" " + ref):
				h = riga.get_slice(" ", 0)
	return (h.substr(0, 7) if h != "" else "sconosciuto") + " (" + ref.get_file() + ")"


## Tiene solo le ultime SESSIONI_TENUTE sessioni (con le loro foto dei segnalibri).
func _pulisci_vecchie() -> void:
	var d := DirAccess.open(cartella)
	if d == null:
		return
	var sessioni: Array[String] = []
	for f in d.get_files():
		if f.begins_with("sessione-") and f.ends_with(".txt"):
			sessioni.append(f.get_basename())
	sessioni.sort()
	while sessioni.size() > SESSIONI_TENUTE:
		var vecchia: String = sessioni.pop_front()
		for f in d.get_files():
			if f.get_basename() == vecchia or f.begins_with(vecchia + "-segnalibro"):
				d.remove(f)


# ---------- scrittura ----------

func _ora() -> String:
	return Time.get_time_string_from_system()


func _scrivi(testo: String) -> void:
	if _file == null:
		return
	_file.store_line(testo)
	# Subito su disco: se il gioco si blocca, il registro resta.
	_file.flush()


## Un evento con l'ora: tipo in maiuscolo (CARICAMENTO, LENTO, ERRORE, AVVISO, SPUNTA, SEGNALIBRO…).
func evento(tipo: String, testo: String) -> void:
	if attivo:
		_scrivi("%s  %s  %s" % [_ora(), tipo.to_upper(), testo])


## La riga dei numeri, ogni INTERVALLO secondi (o subito, per esempio alla chiusura).
func scrivi_riga() -> void:
	if not attivo:
		return
	var n := misura()
	_scrivi("%s  fps %d (min %d) · più lento %d ms · disegni %d · memoria %s · video %s · zoom %s · anno %s%s · alberi %d · animali %d · figure %d%s" % [
		_ora(), n["fps"], n["fps_min"], n["lento_ms"], n["disegni"], _mb(n["memoria"]), _mb(n["video"]), n["zoom"], n["anno"], n["velocita"],
		n["alberi"], n["animali"], n["figure"], (" · altri %d fotogrammi lenti" % _lenti_taciuti) if _lenti_taciuti > 0 else ""])
	_ultimi = n
	_tempo = 0.0
	_fotogrammi = 0
	_piu_lento = 0.0
	_min_fps = 1.0e9
	_lenti = 0
	_lenti_taciuti = 0


## I numeri del momento (anche per la finestra Debug e le verifiche).
func misura() -> Dictionary:
	var fps := float(_fotogrammi) / _tempo if _tempo > 0.0 else Engine.get_frames_per_second()
	var n := {
		"fps": roundi(fps),
		"fps_min": roundi(minf(_min_fps, fps)),
		"lento_ms": roundi(_piu_lento * 1000.0),
		"disegni": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		"memoria": int(Performance.get_monitor(Performance.MEMORY_STATIC)),
		"video": int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)),
		"zoom": "-", "anno": "-", "velocita": "", "alberi": 0, "animali": 0, "figure": 0,
	}
	if scena == null:
		return n
	if "cam" in scena and scena.cam:
		n["zoom"] = "%d m" % roundi(scena.cam.dimensione)
	if "vista_alberi" in scena and scena.vista_alberi:
		n["alberi"] = scena.vista_alberi.alberi_visibili
	var p = scena.get("partita")
	if p and p.sim:
		n["anno"] = SimVillaggio.anno_testo(p.sim.anno) if p.sim.fondato else "prima della fondazione"
		if p.sim.fondato:
			n["velocita"] = " in pausa" if p.velocita == 0 else " ×%d" % p.velocita
		if p.vista:
			n["animali"] = p.vista.animali_disegnati()
			if p.vista.persone and p.vista.persone._visibili:
				n["figure"] = p.vista.persone.figure().size()
	return n


static func _mb(byte: int) -> String:
	return "%d MB" % roundi(byte / 1048576.0)


func _anno() -> int:
	var p = scena.get("partita") if scena else null
	return p.sim.anno if p and p.sim else 0


# ---------- ogni fotogramma ----------

func _process(delta: float) -> void:
	if not attivo:
		return
	campiona(delta)
	if _finestra and _finestra.visible:
		_tempo_finestra -= delta
		if _tempo_finestra <= 0.0:
			_tempo_finestra = 0.5
			_aggiorna_finestra()


## Conta un fotogramma: medie, minimo al secondo, fotogrammi lenti con cosa stava succedendo
## (il contesto è quello del fotogramma prima, che è il lavoro che delta misura).
func campiona(delta: float) -> void:
	_svuota_errori()
	_tempo += delta
	_fotogrammi += 1
	_piu_lento = maxf(_piu_lento, delta)
	_secondo += delta
	_fotogrammi_secondo += 1
	if _secondo >= 1.0:
		_min_fps = minf(_min_fps, _fotogrammi_secondo / _secondo)
		_secondo = 0.0
		_fotogrammi_secondo = 0
	if delta * 1000.0 > SOGLIA_LENTO_MS:
		if _lenti < LENTI_PER_INTERVALLO:
			_lenti += 1
			evento("lento", "%d ms%s" % [roundi(delta * 1000.0), (" · " + ", ".join(_contesto)) if not _contesto.is_empty() else ""])
		else:
			_lenti_taciuti += 1
	_contesto = _cosa_succede()
	if _tempo >= INTERVALLO:
		scrivi_riga()


func _cosa_succede() -> Array[String]:
	var c: Array[String] = []
	if scena == null:
		return c
	var cam = scena.get("cam")
	if cam:
		if absf(cam.dimensione - cam.dimensione_obiettivo) > 1.0:
			c.append("zoom (%d m)" % roundi(cam.dimensione))
		if not is_nan(_yaw_prima) and absf(cam.yaw - _yaw_prima) > 0.01:
			c.append("rotazione")
		_yaw_prima = cam.yaw
	var a := _anno()
	if a != _anno_prima:
		c.append("anno che passa (%s)" % SimVillaggio.anno_testo(a))
		_anno_prima = a
	var hud = scena.get("hud")
	if hud:
		if hud.comando() != "":
			c.append("strumento " + hud.comando())
		if hud.modale_aperta():
			c.append("finestra di scelta")
	if scena.get("_inizio_calcolo_alberi") != null and int(scena.get("_inizio_calcolo_alberi")) >= 0:
		c.append("alberi in calcolo")
	return c


func _svuota_errori() -> void:
	if _logger == null:
		return
	for r in _logger.prendi():
		evento(r[0], r[1])


# ---------- spunte e segnalibri ----------

## Spunta (o toglie la spunta a) una prova della finestra Debug: finisce nel registro con l'ora.
func spunta(prova: String, fatta: bool) -> void:
	if fatta:
		spunte[prova] = true
	else:
		spunte.erase(prova)
	evento("spunta" if fatta else "spunta tolta", prova)
	if _caselle.has(prova) and (_caselle[prova] as Button).button_pressed != fatta:
		var c := _caselle[prova] as Button
		c.set_pressed_no_signal(fatta)
		c.text = ("■  " if fatta else "□  ") + prova


## F9: "qui c'è qualcosa". Ora, camera e una foto dello schermo accanto al registro.
func segnalibro() -> String:
	if not attivo:
		return ""
	_segnalibri += 1
	var dove := ""
	var cam = scena.get("cam") if scena else null
	if cam:
		dove = " · camera x %d z %d · zoom %d m · rotazione %d°" % [roundi(cam.bersaglio.x), roundi(cam.bersaglio.z), roundi(cam.dimensione), posmod(roundi(cam.yaw), 360)]
	var foto := ""
	var vp := get_viewport()
	if vp and DisplayServer.get_name() != "headless":
		var img := vp.get_texture().get_image()
		if img:
			var p := cartella.path_join("%s-segnalibro-%d.png" % [_nome, _segnalibri])
			if img.save_png(p) == OK:
				foto = p.get_file()
	evento("segnalibro", "n. %d%s · %s" % [_segnalibri, dove, ("foto " + foto) if foto != "" else "foto non disponibile"])
	if scena and scena.get("hud"):
		scena.hud.imposta_messaggio("Segnalibro %d nel registro tecnico." % _segnalibri)
	scrivi_riga()
	return foto


# ---------- finestra Debug (F3) ----------

func apri_finestra(aperta: bool) -> void:
	if aperta and _finestra == null:
		_crea_finestra()
	if _finestra:
		_finestra.visible = aperta
		if aperta:
			_tempo_finestra = 0.0
	evento("debug", "finestra aperta" if aperta else "finestra chiusa")


func finestra_aperta() -> bool:
	return _finestra != null and _finestra.visible


## Piccola finestra in alto a destra, nello stile dell'HUD (fascia scura, testo bianco).
func _crea_finestra() -> void:
	var strato := CanvasLayer.new()
	strato.layer = 20
	add_child(strato)
	_finestra = PanelContainer.new()
	_finestra.name = "Debug"
	var hud = scena.get("hud") if scena else null
	if hud and hud.tema:
		_finestra.theme = hud.tema
	else:
		var sfondo := StyleBoxFlat.new()
		sfondo.bg_color = Color(0.1, 0.1, 0.1, 0.93)
		sfondo.set_content_margin_all(14)
		_finestra.add_theme_stylebox_override("panel", sfondo)
	# In alto a destra, sotto la striscia dell'anno, lontano da cronaca e minimappa.
	_finestra.anchor_left = 1.0
	_finestra.anchor_right = 1.0
	_finestra.offset_left = -356.0
	_finestra.offset_right = -16.0
	_finestra.offset_top = 52.0
	_finestra.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	strato.add_child(_finestra)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	_finestra.add_child(col)
	col.add_child(_etichetta("DEBUG · F3 chiude · F9 segnalibro", 12, true))
	_numeri = _etichetta("", 13, false)
	col.add_child(_numeri)
	col.add_child(_etichetta("Registro: " + ProjectSettings.globalize_path(percorso), 11, false, true))
	col.add_child(_etichetta("PROVE DA VERIFICARE", 12, true))
	# Caselle come gli interruttori dell'HUD: un quadratino vuoto o pieno davanti al nome.
	var vuoto := StyleBoxFlat.new()
	vuoto.bg_color = Color(0, 0, 0, 0)
	vuoto.set_content_margin_all(3)
	var sopra := vuoto.duplicate() as StyleBoxFlat
	sopra.bg_color = Color(1, 1, 1, 0.08)
	for prova in PROVE:
		var c := Button.new()
		c.toggle_mode = true
		c.focus_mode = Control.FOCUS_NONE  # lo Spazio resta alla pausa
		c.alignment = HORIZONTAL_ALIGNMENT_LEFT
		c.button_pressed = spunte.has(prova)
		c.text = ("■  " if c.button_pressed else "□  ") + prova
		c.add_theme_font_size_override("font_size", 13)
		for st in ["normal", "pressed", "focus"]:
			c.add_theme_stylebox_override(st, vuoto)
		for st in ["hover", "hover_pressed"]:
			c.add_theme_stylebox_override(st, sopra)
		for k in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
			c.add_theme_color_override(k, Color("f4f4f0"))
		c.toggled.connect(func(on: bool) -> void:
			c.text = ("■  " if on else "□  ") + prova
			spunta(prova, on))
		col.add_child(c)
		_caselle[prova] = c


func _etichetta(testo: String, corpo: int, titolo: bool, a_capo := false) -> Label:
	var l := Label.new()
	l.text = testo
	l.add_theme_font_size_override("font_size", corpo)
	l.add_theme_color_override("font_color", Color("9b9b96") if titolo else Color("f4f4f0"))
	if a_capo:
		l.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
		l.custom_minimum_size.x = 312
	return l


func _aggiorna_finestra() -> void:
	var n := misura()
	_numeri.text = "%d fps (minimo %d) · più lento %d ms\ndisegni %d · memoria %s · video %s\nalberi %d · animali %d · figure %d\nzoom %s · %s%s" % [
		Engine.get_frames_per_second(), n["fps_min"], n["lento_ms"], n["disegni"], _mb(n["memoria"]), _mb(n["video"]),
		n["alberi"], n["animali"], n["figure"], n["zoom"], n["anno"], n["velocita"]]


## Raccoglie errori e avvisi di Godot. Può essere chiamato da altri thread: le righe aspettano qui
## e il registro le scrive nel fotogramma dopo.
class _Ascolto extends Logger:
	var _righe: Array = []
	var _lucchetto := Mutex.new()

	func _log_error(_function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, script_backtraces: Array[ScriptBacktrace]) -> void:
		var testo := rationale if rationale != "" else code
		var dove := "%s:%d" % [file, line]
		if not script_backtraces.is_empty() and script_backtraces[0].get_frame_count() > 0:
			dove = "%s:%d" % [script_backtraces[0].get_frame_file(0), script_backtraces[0].get_frame_line(0)]
		var tipo := "avviso" if error_type == ERROR_TYPE_WARNING else "errore"
		_lucchetto.lock()
		if _righe.size() < 200:
			_righe.append([tipo, "%s (%s)" % [testo, dove]])
		_lucchetto.unlock()

	func prendi() -> Array:
		_lucchetto.lock()
		var r := _righe
		_righe = []
		_lucchetto.unlock()
		return r
