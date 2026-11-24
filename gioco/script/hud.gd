class_name Hud
extends CanvasLayer
## Interfaccia a schermo (24/11/2026).
##
## Disposizione (Fede): come in Age of Empires, comandi a sinistra e controlli delle mappe a
## destra. Stile (Fede): grafica svizzera, quella della segnaletica della metropolitana di
## Milano (Noorda) e di New York (Vignelli); presente ma non protagonista, con carattere;
## i colori solo dove hanno un significato.
##
## Traduzione in regole (proposta di Claude):
## - fasce scure a filo dei bordi dello schermo, testo bianco, niente angoli arrotondati né
##   ombre; righe sottili per separare; tutto allineato a sinistra su una griglia di 8 px;
## - gerarchia data da grandezza e peso del testo, non dal colore; intestazioni in maiuscolo,
##   piccole e spaziate;
## - colori solo con un significato: ogni mappa tematica ha il suo colore, come le linee della
##   metropolitana (bollino tondo con il numero del tasto); il rosso vuol dire pericolo o azione
##   che non si può annullare; tutto il resto è bianco, nero e grigio;
## - la scelta corrente si mostra per inversione (fondo bianco, testo nero), come i cartelli.

signal modo_scelto(i: int)
signal griglia_cambiata(attiva: bool)
signal isoipse_cambiate(attive: bool)
## Strumento scelto ("" = nessuno).
signal comando_scelto(id: String)
## Azione immediata (un pulsante che non resta selezionato).
signal azione(id: String)

const NERO := Color("1b1b1b")
const BIANCO := Color("f4f4f0")
const GRIGIO := Color("9b9b96")
const RIGA := Color(1, 1, 1, 0.22)
## Rosso: pericolo, azione irreversibile (lo stesso del rischio di piena).
const PERICOLO := Color("c8102e")
const ALTEZZA_BARRA := 40
const LARGHEZZA_PANNELLO := 248
const MARGINE := 16

## Colori delle mappe tematiche, ognuno con il suo significato (come le linee della metro).
const COLORI_MAPPE := [Color("dcdcd6"), Color("2a6db5"), Color("3e8e3a"), Color("c8102e"), Color("f0a91c")]
## Testo nel bollino: scuro sui colori chiari, bianco sugli altri.
const TESTO_SCURO_SU := [0, 4]
## Legende delle mappe: [testo a sinistra, testo a destra, colori del gradiente, nota].
const LEGENDE := [
	["", "", [], "Il rilievo si legge da luce e ombre. Boschi, paludi e gessi come sono in natura."],
	["lontana", "vicina e affidabile", [Color("e9eef4"), Color("2a6db5")], "Acqua affidabile: fiume e sorgenti. Tratteggio chiaro: solo stagionale."],
	["bassa", "alta", [Color("b08a3a"), Color("3e8e3a")], "Fertilità del suolo per i campi."],
	["nullo", "alto", [Color("f4f4f0"), Color("c8102e")], "Rischio che l'acqua esca dagli argini."],
	["1 kW", "1000 kW", [Color("2a6db5"), Color("f0a91c"), Color("c8102e")], "Potenza dell'acqua ogni 100 m di corso. Le etichette indicano i siti adatti alle dighe."],
]

var tema: Theme
var _righe_mappe: Array[Button] = []
var _righe_comandi := {}
var _comando := ""
var _griglia: Button
var _isoipse: Button
var _lettura: Label
var _prestazioni: Label
var _messaggio: Label
var _legenda_barra: TextureRect
var _legenda_sx: Label
var _legenda_dx: Label
var _legenda_nota: Label
var _legenda_riga: Control
var _colonna_comandi: VBoxContainer
var _titolo_luogo: Label
## Spazio al centro della barra in alto, per gli indicatori del gioco.
var indicatori: HBoxContainer


func _init() -> void:
	layer = 10
	tema = _crea_tema()


func costruisci(nome_mappa: String, nomi_mappe: Array) -> void:
	var radice := Control.new()
	radice.set_anchors_preset(Control.PRESET_FULL_RECT)
	radice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	radice.theme = tema
	add_child(radice)
	_barra_alta(radice, nome_mappa)
	_pannello_comandi(radice)
	_pannello_mappe(radice, nomi_mappe)
	_barra_bassa(radice)
	seleziona_modo(0)


# ---------- parti ----------

func _barra_alta(radice: Control, nome_mappa: String) -> void:
	var barra := PanelContainer.new()
	barra.set_anchors_preset(Control.PRESET_TOP_WIDE)
	barra.custom_minimum_size.y = ALTEZZA_BARRA
	radice.add_child(barra)
	var riga := HBoxContainer.new()
	riga.add_theme_constant_override("separation", 24)
	barra.add_child(riga)
	var marchio := Label.new()
	marchio.text = "Strati"
	marchio.add_theme_font_override("font", _carattere(true))
	marchio.add_theme_font_size_override("font_size", 19)
	riga.add_child(marchio)
	_titolo_luogo = Label.new()
	_titolo_luogo.text = nome_mappa
	_titolo_luogo.add_theme_color_override("font_color", GRIGIO)
	riga.add_child(_titolo_luogo)
	indicatori = HBoxContainer.new()
	indicatori.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	indicatori.alignment = BoxContainer.ALIGNMENT_CENTER
	indicatori.add_theme_constant_override("separation", 28)
	riga.add_child(indicatori)
	_prestazioni = Label.new()
	_prestazioni.add_theme_color_override("font_color", GRIGIO)
	_prestazioni.add_theme_font_size_override("font_size", 12)
	_prestazioni.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	riga.add_child(_prestazioni)


func _pannello_comandi(radice: Control) -> void:
	var p := PanelContainer.new()
	p.anchor_left = 0.0
	p.anchor_top = 0.0
	p.offset_top = ALTEZZA_BARRA + 1
	p.custom_minimum_size.x = LARGHEZZA_PANNELLO
	radice.add_child(p)
	_colonna_comandi = VBoxContainer.new()
	_colonna_comandi.add_theme_constant_override("separation", 2)
	p.add_child(_colonna_comandi)
	_messaggio = Label.new()
	_messaggio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_messaggio.custom_minimum_size.x = LARGHEZZA_PANNELLO - 2 * MARGINE
	_messaggio.add_theme_color_override("font_color", GRIGIO)
	_messaggio.add_theme_font_size_override("font_size", 13)
	_colonna_comandi.add_child(_messaggio)


func _pannello_mappe(radice: Control, nomi: Array) -> void:
	var p := PanelContainer.new()
	p.anchor_left = 1.0
	p.anchor_right = 1.0
	p.offset_left = -LARGHEZZA_PANNELLO
	p.offset_top = ALTEZZA_BARRA + 1
	p.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	p.custom_minimum_size.x = LARGHEZZA_PANNELLO
	radice.add_child(p)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	p.add_child(col)
	_intestazione(col, "Mappe")
	for i in nomi.size():
		var r := _riga(col, nomi[i], str(i + 1), COLORI_MAPPE[i] if i < COLORI_MAPPE.size() else BIANCO, i in TESTO_SCURO_SU)
		r.toggle_mode = true
		r.pressed.connect(func() -> void: seleziona_modo(i); modo_scelto.emit(i))
		_righe_mappe.append(r)
	_intestazione(col, "Sovrapposizioni")
	_griglia = _riga(col, "Griglia dei lotti · 20 m", "G", Color(0, 0, 0, 0), false, true)
	_griglia.toggle_mode = true
	_griglia.toggled.connect(func(v: bool) -> void: griglia_cambiata.emit(v))
	_isoipse = _riga(col, "Isoipse · 25 m", "I", Color(0, 0, 0, 0), false, true)
	_isoipse.toggle_mode = true
	_isoipse.toggled.connect(func(v: bool) -> void: isoipse_cambiate.emit(v))
	_intestazione(col, "Legenda")
	_legenda_riga = VBoxContainer.new()
	(_legenda_riga as VBoxContainer).add_theme_constant_override("separation", 4)
	col.add_child(_legenda_riga)
	_legenda_barra = TextureRect.new()
	_legenda_barra.custom_minimum_size = Vector2(LARGHEZZA_PANNELLO - 2 * MARGINE, 8)
	_legenda_barra.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_legenda_barra.stretch_mode = TextureRect.STRETCH_SCALE
	_legenda_riga.add_child(_legenda_barra)
	var estremi := HBoxContainer.new()
	_legenda_riga.add_child(estremi)
	_legenda_sx = _etichetta_piccola(estremi)
	_legenda_sx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_legenda_dx = _etichetta_piccola(estremi)
	_legenda_dx.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_legenda_nota = Label.new()
	_legenda_nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_legenda_nota.custom_minimum_size.x = LARGHEZZA_PANNELLO - 2 * MARGINE
	_legenda_nota.add_theme_font_size_override("font_size", 13)
	_legenda_nota.add_theme_color_override("font_color", GRIGIO)
	col.add_child(_legenda_nota)


func _barra_bassa(radice: Control) -> void:
	var barra := PanelContainer.new()
	barra.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	barra.grow_vertical = Control.GROW_DIRECTION_BEGIN
	barra.custom_minimum_size.y = 34
	radice.add_child(barra)
	var riga := HBoxContainer.new()
	barra.add_child(riga)
	_lettura = Label.new()
	_lettura.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lettura.text = "Passa sul terreno per leggere il lotto."
	_lettura.clip_text = true
	_lettura.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	riga.add_child(_lettura)
	var aiuto := Label.new()
	aiuto.text = "Tasto destro o WASD sposta · rotella zoom · Q E ruota · Home torna al sito"
	aiuto.add_theme_color_override("font_color", GRIGIO)
	aiuto.add_theme_font_size_override("font_size", 12)
	riga.add_child(aiuto)


# ---------- comandi ----------

## Aggiunge un gruppo di comandi al pannello di sinistra.
## voci: dizionari con id, testo, tasto (facoltativo), pericolo (bool: azione irreversibile),
## strumento (bool: resta selezionato e si usa cliccando sulla mappa; altrimenti è un'azione).
func aggiungi_comandi(titolo: String, voci: Array) -> void:
	var prima := _messaggio.get_index()
	var intest := _intestazione(_colonna_comandi, titolo)
	_colonna_comandi.move_child(intest, prima)
	prima += 1
	for v in voci:
		var colore: Color = PERICOLO if v.get("pericolo", false) else Color(0, 0, 0, 0)
		var r := _riga(_colonna_comandi, v["testo"], v.get("tasto", ""), colore, false, not v.get("pericolo", false))
		_colonna_comandi.move_child(r, prima)
		prima += 1
		var id: String = v["id"]
		if v.get("strumento", true):
			r.toggle_mode = true
			r.pressed.connect(func() -> void: seleziona_comando("" if _comando == id else id); comando_scelto.emit(_comando))
			_righe_comandi[id] = r
		else:
			r.pressed.connect(func() -> void: azione.emit(id))


func seleziona_comando(id: String) -> void:
	_comando = id
	for k in _righe_comandi:
		(_righe_comandi[k] as Button).set_pressed_no_signal(k == id)


func comando() -> String:
	return _comando


func seleziona_modo(i: int) -> void:
	for k in _righe_mappe.size():
		_righe_mappe[k].set_pressed_no_signal(k == i)
	var l: Array = LEGENDE[i] if i < LEGENDE.size() else ["", "", [], ""]
	var colori: Array = l[2]
	_legenda_barra.visible = not colori.is_empty()
	_legenda_sx.get_parent().visible = not colori.is_empty()
	if not colori.is_empty():
		var g := Gradient.new()
		var offs := PackedFloat32Array()
		for k in colori.size():
			offs.append(float(k) / maxf(colori.size() - 1, 1))
		g.offsets = offs
		g.colors = PackedColorArray(colori)
		var t := GradientTexture2D.new()
		t.gradient = g
		t.width = 256
		t.height = 4
		_legenda_barra.texture = t
	_legenda_sx.text = l[0]
	_legenda_dx.text = l[1]
	_legenda_nota.text = l[3]


func imposta_sovrapposizioni(griglia: bool, isoipse: bool) -> void:
	_griglia.set_pressed_no_signal(griglia)
	_isoipse.set_pressed_no_signal(isoipse)


func imposta_lettura(testo: String) -> void:
	_lettura.text = testo


func lettura() -> String:
	return _lettura.text


func imposta_prestazioni(testo: String) -> void:
	_prestazioni.text = testo


func imposta_messaggio(testo: String) -> void:
	_messaggio.text = testo


# ---------- elementi ----------

func _intestazione(col: VBoxContainer, testo: String) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	var spazio := Control.new()
	spazio.custom_minimum_size.y = 6 if col.get_child_count() > 0 else 0
	box.add_child(spazio)
	var l := Label.new()
	l.text = testo.to_upper()
	l.add_theme_font_override("font", _carattere(true, 1.6))
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", GRIGIO)
	box.add_child(l)
	var r := ColorRect.new()
	r.color = RIGA
	r.custom_minimum_size.y = 1
	box.add_child(r)
	col.add_child(box)
	return box


## Riga cliccabile: bollino (colore e sigla) e testo. Selezionata: fondo bianco, testo nero.
func _riga(col: VBoxContainer, testo: String, sigla: String, colore: Color, sigla_scura: bool, quadrato := false) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(LARGHEZZA_PANNELLO - 2 * MARGINE, 30)
	b.focus_mode = Control.FOCUS_NONE
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.text = "        " + testo
	col.add_child(b)
	if sigla != "":
		var bollino := Panel.new()
		bollino.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var st := StyleBoxFlat.new()
		var vuoto := colore.a == 0.0
		st.bg_color = colore if not vuoto else Color(0, 0, 0, 0)
		st.set_corner_radius_all(0 if quadrato else 11)
		if vuoto:
			st.set_border_width_all(1)
			st.border_color = GRIGIO
		bollino.add_theme_stylebox_override("panel", st)
		bollino.position = Vector2(4, 4)
		bollino.size = Vector2(22, 22)
		b.add_child(bollino)
		var l := Label.new()
		l.text = sigla
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.size = Vector2(22, 22)
		l.add_theme_font_override("font", _carattere(true))
		l.add_theme_font_size_override("font_size", 12)
		l.add_theme_color_override("font_color", NERO if sigla_scura else (BIANCO if not vuoto else GRIGIO))
		bollino.add_child(l)
	return b


func _etichetta_piccola(padre: Control) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", GRIGIO)
	padre.add_child(l)
	return l


func _carattere(grassetto: bool, spaziatura := 0.0) -> Font:
	var f := FontVariation.new()
	f.base_font = ThemeDB.fallback_font
	if grassetto:
		f.variation_embolden = 0.55
	if spaziatura > 0.0:
		f.spacing_glyph = int(spaziatura)
	return f


func _crea_tema() -> Theme:
	var t := Theme.new()
	t.default_font_size = 14
	var pannello := StyleBoxFlat.new()
	pannello.bg_color = Color(NERO, 0.93)
	pannello.set_content_margin_all(MARGINE)
	pannello.content_margin_top = 10
	pannello.content_margin_bottom = 14
	t.set_stylebox("panel", "PanelContainer", pannello)
	t.set_color("font_color", "Label", BIANCO)
	var vuoto := StyleBoxFlat.new()
	vuoto.bg_color = Color(0, 0, 0, 0)
	vuoto.set_content_margin_all(4)
	var sopra := vuoto.duplicate() as StyleBoxFlat
	sopra.bg_color = Color(1, 1, 1, 0.08)
	var scelto := vuoto.duplicate() as StyleBoxFlat
	scelto.bg_color = BIANCO
	for stato in ["normal", "focus", "disabled"]:
		t.set_stylebox(stato, "Button", vuoto)
	t.set_stylebox("hover", "Button", sopra)
	t.set_stylebox("pressed", "Button", scelto)
	t.set_stylebox("hover_pressed", "Button", scelto)
	t.set_color("font_color", "Button", BIANCO)
	t.set_color("font_hover_color", "Button", BIANCO)
	t.set_color("font_pressed_color", "Button", NERO)
	t.set_color("font_hover_pressed_color", "Button", NERO)
	t.set_color("font_focus_color", "Button", BIANCO)
	return t
