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
## Altezza della fascia in basso (indicatori, scheda, comandi, minimappa).
const ALTEZZA_FASCIA := 196
const LARGHEZZA_MAPPE := 232
const LATO_MINIMAPPA := 150
const LATO_TASTO := 58
const NOMI_BREVI_MAPPE := ["Terreno", "Acqua", "Fertilità", "Piena", "Energia"]

## Colori delle mappe tematiche, ognuno con il suo significato (come le linee della metro).
const COLORI_MAPPE := [Color("dcdcd6"), Color("2a6db5"), Color("3e8e3a"), Color("c8102e"), Color("f0a91c")]
## Testo nel bollino: scuro sui colori chiari, bianco sugli altri.
const TESTO_SCURO_SU := [0, 4]
## Legende delle mappe: [testo a sinistra, testo a destra, colori del gradiente, nota].
const LEGENDE := [
	["", "", [], "Il rilievo si legge da luce e ombre. Boschi, paludi e gessi come sono in natura."],
	["lontana", "vicina e affidabile", [Color("e9eef4"), Color("2a6db5")], "Acqua affidabile: fiume e sorgenti."],
	["bassa", "alta", [Color("b08a3a"), Color("3e8e3a")], "Per i campi."],
	["nullo", "alto", [Color("f4f4f0"), Color("c8102e")], "Acqua fuori dagli argini."],
	["1 kW", "1000 kW", [Color("2a6db5"), Color("f0a91c"), Color("c8102e")], "Potenza ogni 100 m di corso. Etichette: siti per le dighe."],
]

var tema: Theme
var _righe_mappe: Array[Button] = []
var _righe_comandi := {}
var _righe_azioni := {}
var _cronaca: Label
var _valori_indicatori := {}
var _avviso: PanelContainer
var _testo_avviso: Label
var _modale: Control
var _radice: Control
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
var _nome_mappa := ""
var _anno: Label
var _tempo: HBoxContainer
var _nome_strumento: Label
var _gruppi: HBoxContainer
var _nome_mappa_scelta: Label
var _nomi_mappe: Array = []
var _testi := {}
var minimappa: Minimappa
var _pannello_legenda: PanelContainer
## Spazio al centro della barra in alto, per gli indicatori del gioco.
var indicatori: VBoxContainer


func _init() -> void:
	layer = 10
	tema = _crea_tema()


func costruisci(nome_mappa: String, nomi_mappe: Array) -> void:
	var radice := Control.new()
	radice.set_anchors_preset(Control.PRESET_FULL_RECT)
	radice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	radice.theme = tema
	add_child(radice)
	_radice = radice
	_nome_mappa = nome_mappa
	_striscia_alta(radice)
	_cronaca_alta(radice)
	_fascia_bassa(radice, nomi_mappe)
	_crea_avviso(radice)
	seleziona_modo(0)


# ---------- parti ----------
# Disposizione (esempi di Age of Empires IV mandati da Fede, 24/11/2026): il campo di gioco resta
# libero; in alto al centro solo l'anno e il tempo; in alto a sinistra la cronaca, come gli
# obiettivi; in basso a sinistra gli indicatori (come le risorse) e la scheda dello strumento
# scelto; in basso al centro la griglia dei comandi; in basso a destra la minimappa con i
# controlli delle mappe; gli avvisi sopra la minimappa.

func _striscia_alta(radice: Control) -> void:
	var p := PanelContainer.new()
	p.anchor_left = 0.5
	p.anchor_right = 0.5
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	radice.add_child(p)
	var riga := HBoxContainer.new()
	riga.add_theme_constant_override("separation", 14)
	p.add_child(riga)
	_anno = Label.new()
	_anno.add_theme_font_override("font", _carattere(true))
	_anno.add_theme_font_size_override("font_size", 18)
	_anno.text = "—"
	riga.add_child(_anno)
	_tempo = HBoxContainer.new()
	_tempo.add_theme_constant_override("separation", 2)
	riga.add_child(_tempo)
	# Prestazioni in alto a destra, piccole e grigie, senza fondo.
	_prestazioni = Label.new()
	_prestazioni.anchor_left = 1.0
	_prestazioni.anchor_right = 1.0
	_prestazioni.offset_left = -600
	_prestazioni.offset_right = -MARGINE
	_prestazioni.offset_top = 6
	_prestazioni.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_prestazioni.add_theme_color_override("font_color", BIANCO)
	_prestazioni.add_theme_color_override("font_outline_color", Color(NERO, 0.8))
	_prestazioni.add_theme_constant_override("outline_size", 4)
	_prestazioni.add_theme_font_size_override("font_size", 11)
	radice.add_child(_prestazioni)


func _cronaca_alta(radice: Control) -> void:
	var p := PanelContainer.new()
	p.custom_minimum_size.x = 360
	radice.add_child(p)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	p.add_child(col)
	var titolo := Label.new()
	titolo.text = "STRATI · " + _nome_mappa.to_upper()
	titolo.add_theme_font_override("font", _carattere(true, 1.6))
	titolo.add_theme_font_size_override("font_size", 11)
	titolo.add_theme_color_override("font_color", GRIGIO)
	col.add_child(titolo)
	_cronaca = Label.new()
	_cronaca.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cronaca.custom_minimum_size.x = 328
	_cronaca.add_theme_font_size_override("font_size", 12)
	_cronaca.text = "—"
	col.add_child(_cronaca)


func _fascia_bassa(radice: Control, nomi_mappe: Array) -> void:
	var fascia := HBoxContainer.new()
	fascia.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	fascia.grow_vertical = Control.GROW_DIRECTION_BEGIN
	fascia.add_theme_constant_override("separation", 2)
	fascia.alignment = BoxContainer.ALIGNMENT_BEGIN
	fascia.mouse_filter = Control.MOUSE_FILTER_IGNORE
	radice.add_child(fascia)
	# Indicatori (come le risorse).
	var pi := PanelContainer.new()
	pi.custom_minimum_size = Vector2(190, ALTEZZA_FASCIA)
	pi.size_flags_vertical = Control.SIZE_SHRINK_END
	fascia.add_child(pi)
	indicatori = VBoxContainer.new()
	indicatori.add_theme_constant_override("separation", 6)
	pi.add_child(indicatori)
	# Scheda dello strumento scelto: nome, messaggio, lettura del lotto.
	var ps := PanelContainer.new()
	ps.custom_minimum_size = Vector2(330, ALTEZZA_FASCIA)
	ps.size_flags_vertical = Control.SIZE_SHRINK_END
	fascia.add_child(ps)
	var cs := VBoxContainer.new()
	cs.add_theme_constant_override("separation", 6)
	ps.add_child(cs)
	_nome_strumento = Label.new()
	_nome_strumento.add_theme_font_override("font", _carattere(true))
	_nome_strumento.add_theme_font_size_override("font_size", 18)
	_nome_strumento.text = "Nessuno strumento"
	cs.add_child(_nome_strumento)
	var r := ColorRect.new()
	r.color = RIGA
	r.custom_minimum_size.y = 1
	cs.add_child(r)
	_messaggio = Label.new()
	_messaggio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_messaggio.custom_minimum_size.x = 298
	_messaggio.add_theme_font_size_override("font_size", 13)
	cs.add_child(_messaggio)
	_lettura = Label.new()
	_lettura.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lettura.custom_minimum_size.x = 298
	_lettura.size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_SHRINK_END
	_lettura.add_theme_font_size_override("font_size", 12)
	_lettura.add_theme_color_override("font_color", GRIGIO)
	_lettura.text = "Passa sul terreno per leggere il lotto."
	cs.add_child(_lettura)
	# Griglia dei comandi.
	var pc := PanelContainer.new()
	pc.custom_minimum_size.y = ALTEZZA_FASCIA
	pc.size_flags_vertical = Control.SIZE_SHRINK_END
	fascia.add_child(pc)
	_gruppi = HBoxContainer.new()
	_gruppi.add_theme_constant_override("separation", 18)
	pc.add_child(_gruppi)
	var spazio := Control.new()
	spazio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spazio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fascia.add_child(spazio)
	# Mappe in basso a destra, piccole come i tasti attorno alla minimappa di Age of Empires IV
	# (Fede: cliccabili ma non importanti): minimappa, bollini delle mappe tematiche e delle
	# sovrapposizioni; sopra, solo quando serve, una legenda sottile.
	var colonna := VBoxContainer.new()
	colonna.add_theme_constant_override("separation", 2)
	colonna.size_flags_vertical = Control.SIZE_SHRINK_END
	fascia.add_child(colonna)
	_pannello_legenda = PanelContainer.new()
	colonna.add_child(_pannello_legenda)
	var cl := VBoxContainer.new()
	cl.add_theme_constant_override("separation", 2)
	_pannello_legenda.add_child(cl)
	_nome_mappa_scelta = Label.new()
	_nome_mappa_scelta.add_theme_font_override("font", _carattere(true))
	_nome_mappa_scelta.add_theme_font_size_override("font_size", 12)
	cl.add_child(_nome_mappa_scelta)
	_legenda_riga = VBoxContainer.new()
	(_legenda_riga as VBoxContainer).add_theme_constant_override("separation", 0)
	cl.add_child(_legenda_riga)
	_legenda_barra = TextureRect.new()
	_legenda_barra.custom_minimum_size = Vector2(LARGHEZZA_MAPPE - 2 * MARGINE, 6)
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
	_legenda_nota.custom_minimum_size.x = LARGHEZZA_MAPPE - 2 * MARGINE
	_legenda_nota.add_theme_font_size_override("font_size", 11)
	_legenda_nota.add_theme_color_override("font_color", GRIGIO)
	cl.add_child(_legenda_nota)
	var pm := PanelContainer.new()
	colonna.add_child(pm)
	var rm := HBoxContainer.new()
	rm.add_theme_constant_override("separation", 10)
	pm.add_child(rm)
	var tasti := GridContainer.new()
	tasti.columns = 2
	tasti.add_theme_constant_override("h_separation", 4)
	tasti.add_theme_constant_override("v_separation", 4)
	tasti.size_flags_vertical = Control.SIZE_SHRINK_END
	rm.add_child(tasti)
	for i in nomi_mappe.size():
		var b := _bollino(tasti, str(i + 1), COLORI_MAPPE[i] if i < COLORI_MAPPE.size() else BIANCO, i in TESTO_SCURO_SU, false)
		b.tooltip_text = "%s (%d)" % [nomi_mappe[i], i + 1]
		b.pressed.connect(func() -> void: seleziona_modo(i); modo_scelto.emit(i))
		_righe_mappe.append(b)
	_nomi_mappe = nomi_mappe
	if nomi_mappe.size() % 2 == 1:
		tasti.add_child(Control.new())
	_griglia = _bollino(tasti, "G", Color(0, 0, 0, 0), false, true)
	_griglia.tooltip_text = "Griglia dei lotti da 20 m (G)"
	_griglia.toggled.connect(func(v: bool) -> void: griglia_cambiata.emit(v))
	_isoipse = _bollino(tasti, "I", Color(0, 0, 0, 0), false, true)
	_isoipse.tooltip_text = "Isoipse ogni 25 m (I)"
	_isoipse.toggled.connect(func(v: bool) -> void: isoipse_cambiate.emit(v))
	minimappa = Minimappa.new()
	minimappa.custom_minimum_size = Vector2(LATO_MINIMAPPA, LATO_MINIMAPPA)
	rm.add_child(minimappa)


## Tasto piccolo e tondo (mappe, con il loro colore) o quadrato (sovrapposizioni). Scelto: anello
## bianco attorno al bollino; per i quadrati, inversione.
func _bollino(padre: Control, sigla: String, colore: Color, sigla_scura: bool, quadrato: bool) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(28, 28)
	b.focus_mode = Control.FOCUS_NONE
	b.toggle_mode = true
	b.text = sigla
	b.add_theme_font_override("font", _carattere(true))
	b.add_theme_font_size_override("font_size", 12)
	var vuoto := colore.a == 0.0
	var normale := StyleBoxFlat.new()
	normale.bg_color = colore if not vuoto else Color(0, 0, 0, 0)
	normale.set_corner_radius_all(0 if quadrato else 14)
	if vuoto:
		normale.set_border_width_all(1)
		normale.border_color = GRIGIO
	var scelto := normale.duplicate() as StyleBoxFlat
	if vuoto:
		scelto.bg_color = BIANCO
		scelto.border_color = BIANCO
	else:
		scelto.set_border_width_all(3)
		scelto.border_color = BIANCO
	var sopra := normale.duplicate() as StyleBoxFlat
	sopra.set_border_width_all(1)
	sopra.border_color = BIANCO
	for stato in ["normal", "focus", "disabled"]:
		b.add_theme_stylebox_override(stato, normale)
	b.add_theme_stylebox_override("hover", sopra)
	b.add_theme_stylebox_override("pressed", scelto)
	b.add_theme_stylebox_override("hover_pressed", scelto)
	var testo := NERO if sigla_scura else (BIANCO if not vuoto else GRIGIO)
	for k in ["font_color", "font_hover_color", "font_focus_color"]:
		b.add_theme_color_override(k, testo)
	for k in ["font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(k, NERO if (vuoto or sigla_scura) else BIANCO)
	padre.add_child(b)
	return b


# ---------- comandi ----------

## Aggiunge un gruppo di comandi alla griglia in basso.
## voci: dizionari con id, testo, breve (etichetta sotto il tasto, facoltativa), tasto,
## pericolo (bool: azione irreversibile, segno rosso), strumento (bool: resta selezionato e si
## usa cliccando sulla mappa; altrimenti è un'azione immediata).
func aggiungi_comandi(titolo: String, voci: Array, in_testa := false) -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	_gruppi.add_child(col)
	if in_testa:
		_gruppi.move_child(col, 0)
	var l := Label.new()
	l.text = titolo.to_upper()
	l.add_theme_font_override("font", _carattere(true, 1.6))
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", GRIGIO)
	col.add_child(l)
	var griglia := GridContainer.new()
	griglia.columns = 3 if voci.size() > 4 else 2
	griglia.add_theme_constant_override("h_separation", 4)
	griglia.add_theme_constant_override("v_separation", 4)
	col.add_child(griglia)
	for v in voci:
		var b := _tasto(griglia, v)
		var id: String = v["id"]
		_testi[id] = v["testo"]
		if v.get("strumento", true):
			b.toggle_mode = true
			b.pressed.connect(func() -> void: seleziona_comando("" if _comando == id else id); comando_scelto.emit(_comando))
			_righe_comandi[id] = b
		else:
			b.pressed.connect(func() -> void: azione.emit(id))
			_righe_azioni[id] = b


## Comandi del tempo, piccoli, nella striscia in alto accanto all'anno.
func aggiungi_tempo(voci: Array) -> void:
	for v in voci:
		var b := Button.new()
		b.text = v.get("breve", v["testo"])
		b.tooltip_text = v["testo"]
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(34, 26)
		b.toggle_mode = true
		_tempo.add_child(b)
		var id: String = v["id"]
		b.pressed.connect(func() -> void: azione.emit(id))
		_righe_azioni[id] = b


func _tasto(padre: Control, v: Dictionary) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(LATO_TASTO, LATO_TASTO)
	b.focus_mode = Control.FOCUS_NONE
	b.tooltip_text = v["testo"] + ((" (" + v["tasto"] + ")") if String(v.get("tasto", "")) != "" else "")
	var st := StyleBoxFlat.new()
	st.bg_color = Color(1, 1, 1, 0.04)
	st.set_border_width_all(1)
	st.border_color = RIGA
	b.add_theme_stylebox_override("normal", st)
	b.add_theme_stylebox_override("disabled", st)
	padre.add_child(b)
	var nome := Label.new()
	nome.text = v.get("breve", v["testo"])
	nome.position = Vector2(5, LATO_TASTO - 20)
	nome.size = Vector2(LATO_TASTO - 8, 16)
	nome.clip_text = true
	nome.add_theme_font_size_override("font_size", 11)
	nome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(nome)
	var tasto := Label.new()
	tasto.text = v.get("tasto", "")
	tasto.position = Vector2(6, 2)
	tasto.add_theme_font_override("font", _carattere(true))
	tasto.add_theme_font_size_override("font_size", 20)
	tasto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(tasto)
	if v.get("pericolo", false):
		var segno := ColorRect.new()
		segno.color = PERICOLO
		segno.position = Vector2(LATO_TASTO - 12, 4)
		segno.size = Vector2(8, 8)
		segno.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(segno)
	# Testi neri quando il tasto è scelto (inversione).
	b.toggled.connect(func(on: bool) -> void:
		for c in [nome, tasto]:
			c.add_theme_color_override("font_color", NERO if on else BIANCO))
	return b


func seleziona_comando(id: String) -> void:
	_comando = id
	for k in _righe_comandi:
		_premi(_righe_comandi[k], k == id)
	_nome_strumento.text = _testi.get(id, "Nessuno strumento")


## Stato di un tasto senza emettere il segnale, con i testi interni in nero se scelto.
func _premi(b: Button, on: bool) -> void:
	b.set_pressed_no_signal(on)
	for c in b.get_children():
		if c is Label:
			(c as Label).add_theme_color_override("font_color", NERO if on else BIANCO)


func comando() -> String:
	return _comando


## Segna come scelta (per inversione) una riga di azione, per esempio la velocità del tempo.
func segna(id: String, premuto: bool) -> void:
	var r: Button = _righe_azioni.get(id, _righe_comandi.get(id))
	if r:
		r.toggle_mode = true
		_premi(r, premuto)


func abilita(id: String, attivo: bool) -> void:
	var r: Button = _righe_azioni.get(id, _righe_comandi.get(id))
	if r:
		r.disabled = not attivo
		r.modulate.a = 1.0 if attivo else 0.4


func cambia_testo(id: String, testo: String, breve := "") -> void:
	var r: Button = _righe_azioni.get(id, _righe_comandi.get(id))
	if r:
		_testi[id] = testo
		r.tooltip_text = testo
		var etichette := r.get_children().filter(func(c: Node) -> bool: return c is Label)
		if etichette.is_empty():
			r.text = testo
		else:
			(etichette[0] as Label).text = breve if breve != "" else testo.get_slice(" · ", 0)


## Indicatori nella barra in alto: voci [etichetta, valore, allarme]. In allarme il valore è
## rosso (pericolo), altrimenti bianco.
func imposta_indicatori(voci: Array) -> void:
	for v in voci:
		var nome: String = v[0]
		if nome == "Anno":
			_anno.text = str(v[1])
			continue
		if not _valori_indicatori.has(nome):
			var box := HBoxContainer.new()
			var e := Label.new()
			e.text = nome.to_upper()
			e.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			e.add_theme_font_override("font", _carattere(true, 1.6))
			e.add_theme_font_size_override("font_size", 11)
			e.add_theme_color_override("font_color", GRIGIO)
			box.add_child(e)
			var l := Label.new()
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			l.add_theme_font_override("font", _carattere(true))
			l.add_theme_font_size_override("font_size", 16)
			box.add_child(l)
			indicatori.add_child(box)
			_valori_indicatori[nome] = l
		var lab: Label = _valori_indicatori[nome]
		lab.text = str(v[1])
		lab.add_theme_color_override("font_color", PERICOLO if v[2] else BIANCO)


func imposta_cronaca(righe: Array) -> void:
	_cronaca.text = "\n".join(righe.slice(0, 4)) if not righe.is_empty() else "—"


## Avviso breve sotto la barra in alto, per gli eventi rilevanti (siccità, carestie gravi).
func avviso(testo: String) -> void:
	_testo_avviso.text = testo
	_avviso.visible = true
	var t := get_tree().create_timer(4.0) if is_inside_tree() else null
	if t:
		t.timeout.connect(func() -> void: if _testo_avviso.text == testo: _avviso.visible = false)


func _crea_avviso(radice: Control) -> void:
	_avviso = PanelContainer.new()
	_avviso.anchor_left = 1.0
	_avviso.anchor_right = 1.0
	_avviso.anchor_top = 1.0
	_avviso.anchor_bottom = 1.0
	_avviso.offset_right = 0
	_avviso.offset_bottom = -ALTEZZA_FASCIA - 150
	_avviso.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_avviso.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_avviso.visible = false
	radice.add_child(_avviso)
	var riga := HBoxContainer.new()
	riga.add_theme_constant_override("separation", 12)
	_avviso.add_child(riga)
	var segno := ColorRect.new()
	segno.color = PERICOLO
	segno.custom_minimum_size = Vector2(4, 0)
	riga.add_child(segno)
	_testo_avviso = Label.new()
	riga.add_child(_testo_avviso)


func modale_aperta() -> bool:
	return _modale != null


## Finestra di scelta al centro (momenti decisivi, presagi, eventi). `al_termine` riceve l'id
## dell'opzione scelta.
func mostra_scelta(tipo: String, titolo: String, testo: String, opzioni: Array, al_termine: Callable) -> void:
	chiudi_scelta()
	var velo := ColorRect.new()
	velo.color = Color(0, 0, 0, 0.35)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	velo.mouse_filter = Control.MOUSE_FILTER_STOP
	_radice.add_child(velo)
	_modale = velo
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	velo.add_child(centro)
	var p := PanelContainer.new()
	p.custom_minimum_size.x = 560
	centro.add_child(p)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	p.add_child(col)
	var k := Label.new()
	k.text = tipo.to_upper()
	k.add_theme_font_override("font", _carattere(true, 1.6))
	k.add_theme_font_size_override("font_size", 11)
	k.add_theme_color_override("font_color", GRIGIO)
	col.add_child(k)
	var t := Label.new()
	t.text = titolo
	t.add_theme_font_override("font", _carattere(true))
	t.add_theme_font_size_override("font_size", 24)
	col.add_child(t)
	var riga := ColorRect.new()
	riga.color = RIGA
	riga.custom_minimum_size.y = 1
	col.add_child(riga)
	var corpo := Label.new()
	corpo.text = testo
	corpo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	corpo.custom_minimum_size.x = 528
	col.add_child(corpo)
	for o in opzioni:
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 0)
		col.add_child(box)
		var b := Button.new()
		b.text = String(o["testo"])
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size.y = 34
		var st := StyleBoxFlat.new()
		st.bg_color = Color(0, 0, 0, 0)
		st.set_border_width_all(1)
		st.border_color = RIGA
		st.set_content_margin_all(8)
		b.add_theme_stylebox_override("normal", st)
		box.add_child(b)
		var id: String = o["id"]
		b.pressed.connect(func() -> void: chiudi_scelta(); al_termine.call(id))
		if String(o.get("nota", "")) != "":
			var nota := Label.new()
			nota.text = o["nota"]
			nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			nota.custom_minimum_size.x = 528
			nota.add_theme_font_size_override("font_size", 12)
			nota.add_theme_color_override("font_color", GRIGIO)
			box.add_child(nota)


func chiudi_scelta() -> void:
	if _modale:
		_modale.queue_free()
		_modale = null


func seleziona_modo(i: int) -> void:
	for k in _righe_mappe.size():
		_righe_mappe[k].set_pressed_no_signal(k == i)
	if _nome_mappa_scelta and i < _nomi_mappe.size():
		_nome_mappa_scelta.text = _nomi_mappe[i]
	if _pannello_legenda:
		_pannello_legenda.visible = i != 0
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
func _riga(col: VBoxContainer, testo: String, sigla: String, colore: Color, sigla_scura: bool, quadrato := false, larghezza := LARGHEZZA_PANNELLO - 2 * MARGINE) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(larghezza, 28)
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
		bollino.position = Vector2(4, 3)
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
	t.set_color("font_disabled_color", "Button", GRIGIO)
	return t
