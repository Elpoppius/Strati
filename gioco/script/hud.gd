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
## Il giocatore ha cambiato una politica nel pannello delle politiche.
signal politica_scelta(id: String, valore: String)
## Clic su una notifica con un luogo: (x, z) nel mondo.
signal notifica_scelta(punto: Vector2)

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
## Blocco Info: larghezza fissa e colonna dei nomi (misurate su "POPOLAZIONE" e "8888 / 8888 l'anno").
const LARGHEZZA_INFO := 300
const COLONNA_NOMI_INFO := 92
const LARGHEZZA_MAPPE := 232
const LATO_MINIMAPPA := 150
const LATO_TASTO := 58
const LATO_ICONA := 28
const ICONE := "res://asset/icone/%s.svg"
const NOMI_BREVI_MAPPE := ["Terreno", "Acqua", "Fertilità", "Piena", "Energia", "Caccia e pesca", "Abitato", "Memoria"]

## Colori delle mappe tematiche, ognuno con il suo significato (come le linee della metro).
## Dal 25/11/2026 sera (voce 8 del todo): verde bosco per caccia e pesca, ocra per abitato e contado,
## viola per la memoria del suolo.
const COLORI_MAPPE := [Color("dcdcd6"), Color("2a6db5"), Color("3e8e3a"), Color("c8102e"), Color("f0a91c"),
	Color("1f613a"), Color("c98a2b"), Color("7a4a9e")]
## Testo nel bollino: scuro sui colori chiari, bianco sugli altri.
const TESTO_SCURO_SU := [0, 4]
## Legende delle mappe: [testo a sinistra, testo a destra, colori del gradiente, nota].
const LEGENDE := [
	["", "", [], "Il rilievo si legge da luce e ombre. Boschi, paludi e gessi come sono in natura."],
	["lontana", "vicina e affidabile", [Color("e9eef4"), Color("2a6db5")], "Acqua affidabile: fiume e sorgenti."],
	["bassa", "alta", [Color("b08a3a"), Color("3e8e3a")], "Per i campi."],
	["nullo", "alto", [Color("f4f4f0"), Color("c8102e")], "Acqua fuori dagli argini."],
	["1 kW", "1000 kW", [Color("2a6db5"), Color("f0a91c"), Color("c8102e")], "Potenza ogni 100 m di corso. Etichette: siti per le dighe."],
	["scarsa", "abbondante", [Color("b8a37a"), Color("1f613a")], "Selvaggina nei boschi; pesce lungo fiumi e torrenti (blu se abbonda, grigio se scarso). Cerchi verdi e blu: dove cacciano le poste e pescano i capanni; bianchi: zone di taglio."],
	["contado", "abitato", [Color("ebc781"), Color("b87321")], "Pieno: l'abitato, il cerchio delle case. Chiaro: il contado, fin dove arrivano i campi. Macchie piene: i casali."],
	["bosco di oggi", "bosco perso", [Color("a3ac96"), Color("7a4a9e")], "Viola: dove c'era il bosco (più chiaro dove ricresce). Grigio scuro: suolo sigillato per sempre. Anelli: le rovine."],
]

var tema: Theme
var _righe_mappe: Array[Button] = []
var _righe_comandi := {}
var _righe_azioni := {}
var _cronaca: Label
var _valori_indicatori := {}
var _notifiche: VBoxContainer
var _pannello_descrizione: Control
## Lettura del sito (Fede: al momento della fondazione gli indicatori del terreno devono essere
## visibili e chiari; in quella modalità occupano lo spazio della descrizione e dei menù).
var _pannello_sito: PanelContainer
var _titolo_sito: Label
var _nota_sito: Label
var _voci_sito := {}  # id -> {valore: Label, riempimento: ColorRect}
const VOCI_SITO := [["acqua", "Acqua"], ["fertilita", "Fertilità intorno"], ["bosco", "Boschi: caccia e raccolta"], ["pesca", "Pesca"],
	["piena", "Rischio di piena"], ["difesa", "Difesa"], ["aria", "Aria"]]
var _sezione_fonti: VBoxContainer
var _fonti_info := {}  # id -> {valore: Label, riempimento: ColorRect, riga: Control}
## Clic su una fonte di cibo nel blocco Info.
signal fonte_scelta(id: String)
## Interruttore di una politica (per esempio una fonte di cibo) acceso o spento.
signal interruttore_scelto(politica: String, voce: String, acceso: bool)
## Clic su un indicatore del blocco Info: si apre il suo pannello di focus (decisione di Fede del
## 25/11/2026: gli indicatori restano, e un pannello spiega cosa succede, perché e dove).
signal indicatore_scelto(nome: String)
## Dal pannello di focus: mostrare la mappa tematica indicata.
signal mappa_richiesta(modo: int)
## Una scelta nella scheda di un edificio nel pannello di focus (per esempio la legnaia: al lavoro o a riposo).
signal scelta_focus(id: String)
var _opzioni: HBoxContainer
var _opzioni_di := {}  # strumento -> [Button]
var _colonna_mappe: Control
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
## Blocchi dei comandi nella fascia in basso (decisione di Fede del 24/11/2026): Costruzione,
## Gestione, Strumenti, tutti con le schede, così il layout è pronto per le voci future.
## id -> {"schede": HBoxContainer (HFlowContainer negli Strumenti), "pagine": Control, "descrizione": Label, "colonne": int}
var _blocchi := {}
var _fascia: Control
const BLOCCHI := [["costruzione", "Costruzione", 4], ["gestione", "Gestione", 2], ["strumenti", "Strumenti", 2]]
## Menù logici: id -> {"scheda": Button, "pagina": Control, "descrizione": String}.
var _menu := {}
var _menu_scelto := ""
## Comando -> menù a cui appartiene (per aprire il menù giusto quando si usa il tasto).
var _menu_di := {}
var _descrizioni := {}
var _nome_mappa_scelta: Label
var _nomi_mappe: Array = []
var _testi := {}
var minimappa: Minimappa
var _pannello_legenda: PanelContainer
var _pannello_politiche: PanelContainer
var _lettura_strumento: GridContainer
var _voci_strumento: Array = []
var _pannello_focus: PanelContainer
var _colonna_focus: VBoxContainer
var _focus := ""
## Specchietto "Conseguenze" (decisione di Fede del 26/11/2026): sopra la scheda dello
## strumento, prima del clic, chi ci guadagna, chi ci perde, cosa cambia sulla terra, il costo e
## cosa resta. Poche parole: una riga per voce, il resto al passaggio del puntatore.
var _pannello_conseguenze: PanelContainer
var _titolo_conseguenze: Label
var _righe_conseguenze := {}  # voce -> Label del valore
var _dati_conseguenze := {}
const VOCI_CONSEGUENZE := [["guadagna", "Chi guadagna"], ["perde", "Chi perde"], ["territorio", "Sul territorio"], ["costo", "Costo"], ["resta", "Resta"]]
## Larghezza massima di una riga dello specchietto (in caratteri): niente muri di testo.
const MASSIMO_RIGA_CONSEGUENZE := 52
## Indicatori che aprono un pannello di focus con un clic.
const INDICATORI_CON_FOCUS := ["Popolazione", "Cibo", "Salute", "Abbondanza", "Consenso", "Legna", "Animali"]
var _colonna_politiche: VBoxContainer
var _scorri_politiche: ScrollContainer
## id politica -> {"opzioni": {valore: Button}, "nota": Label, "note": {valore: testo}}
var _politiche := {}
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
	_crea_notifiche(radice)
	_crea_politiche(radice)
	seleziona_modo(0)


# ---------- parti ----------
# Disposizione (esempi di Age of Empires IV mandati da Fede, 24/11/2026): il campo di gioco resta
# libero; in alto al centro solo l'anno e il tempo; in alto a sinistra la cronaca, come gli
# obiettivi; in basso a sinistra gli indicatori (come le risorse) e la scheda dello strumento
# scelto; in basso al centro la griglia dei comandi; in basso a destra la minimappa con i
# controlli delle mappe; le notifiche sopra la minimappa.

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
	# Larghezza fissa (Fede, 26/11/2026: l'HUD balla): anno e tappa cambiano, i tasti del tempo no.
	_anno.custom_minimum_size.x = 330
	_anno.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_anno.add_theme_font_override("font", _carattere(true, 0.0, true))
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
	_fascia = fascia
	# Indicatori (come le risorse).
	var pi := PanelContainer.new()
	# Larghezza fissa (Fede: le colonne ballavano quando i numeri crescevano): colonna dei nomi
	# fissa, valori allineati a destra nello spazio che resta, mai più larghi del blocco.
	pi.custom_minimum_size = Vector2(LARGHEZZA_INFO, ALTEZZA_FASCIA)
	pi.size_flags_vertical = Control.SIZE_FILL
	fascia.add_child(pi)
	var colonna_info := VBoxContainer.new()
	colonna_info.add_theme_constant_override("separation", 6)
	pi.add_child(colonna_info)
	indicatori = VBoxContainer.new()
	indicatori.add_theme_constant_override("separation", 3)
	colonna_info.add_child(indicatori)
	# Fonti di cibo (richiesta di Fede): da dove si attinge e quanto si usa di ciò che è disponibile.
	_sezione_fonti = VBoxContainer.new()
	_sezione_fonti.add_theme_constant_override("separation", 2)
	_sezione_fonti.visible = false
	colonna_info.add_child(_sezione_fonti)
	var tf := Label.new()
	tf.text = "FONTI DI CIBO"
	tf.add_theme_font_override("font", _carattere(true, 1.6))
	tf.add_theme_font_size_override("font_size", 10)
	tf.add_theme_color_override("font_color", GRIGIO)
	_sezione_fonti.add_child(tf)
	# Scheda dello strumento scelto: nome, messaggio, lettura del lotto.
	var ps := PanelContainer.new()
	ps.custom_minimum_size = Vector2(330, ALTEZZA_FASCIA)
	ps.size_flags_vertical = Control.SIZE_FILL
	fascia.add_child(ps)
	_pannello_descrizione = ps
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
	_messaggio.max_lines_visible = 4
	_messaggio.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	cs.add_child(_messaggio)
	# Opzioni dello strumento scelto (come in Cities: Skylines), per esempio Collega alla rete per
	# il Sentiero. Compaiono solo con il loro strumento.
	_opzioni = HBoxContainer.new()
	_opzioni.add_theme_constant_override("separation", 4)
	_opzioni.visible = false
	cs.add_child(_opzioni)
	var titolo_opzioni := Label.new()
	titolo_opzioni.text = "OPZIONI"
	titolo_opzioni.add_theme_font_override("font", _carattere(true, 1.6))
	titolo_opzioni.add_theme_font_size_override("font_size", 11)
	titolo_opzioni.add_theme_color_override("font_color", GRIGIO)
	titolo_opzioni.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_opzioni.add_child(titolo_opzioni)
	# Lettura del terreno per lo strumento scelto (decisione di Fede del 25/11/2026: come in
	# fondazione, ogni strumento mostra le voci che contano per lui, con barra e rosso se sfavorevole).
	_lettura_strumento = GridContainer.new()
	_lettura_strumento.columns = 2
	_lettura_strumento.add_theme_constant_override("h_separation", 18)
	_lettura_strumento.add_theme_constant_override("v_separation", 6)
	_lettura_strumento.visible = false
	cs.add_child(_lettura_strumento)
	for k in 4:
		var c := VBoxContainer.new()
		c.add_theme_constant_override("separation", 2)
		c.custom_minimum_size.x = 140
		_lettura_strumento.add_child(c)
		var e := Label.new()
		e.add_theme_font_override("font", _carattere(true, 1.6))
		e.add_theme_font_size_override("font_size", 10)
		e.add_theme_color_override("font_color", GRIGIO)
		e.clip_text = true
		e.custom_minimum_size.x = 140
		c.add_child(e)
		var l := Label.new()
		l.add_theme_font_override("font", _carattere(true))
		l.add_theme_font_size_override("font_size", 13)
		l.clip_text = true
		l.custom_minimum_size.x = 140
		c.add_child(l)
		var fondo := ColorRect.new()
		fondo.color = RIGA
		fondo.custom_minimum_size = Vector2(140, 4)
		c.add_child(fondo)
		var pieno := ColorRect.new()
		pieno.anchor_bottom = 1.0
		fondo.add_child(pieno)
		_voci_strumento.append({"box": c, "nome": e, "valore": l, "riempimento": pieno})
	_lettura = Label.new()
	_lettura.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lettura.custom_minimum_size.x = 298
	_lettura.size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_SHRINK_END
	_lettura.add_theme_font_size_override("font_size", 12)
	_lettura.add_theme_color_override("font_color", GRIGIO)
	# Righe fisse (Fede, 26/11/2026: l'HUD balla): il testo che cambia sotto il puntatore non deve
	# cambiare l'altezza della fascia.
	_lettura.max_lines_visible = 2
	_lettura.custom_minimum_size.y = 32
	_lettura.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_lettura.text = "Passa sul terreno per leggere il lotto."
	cs.add_child(_lettura)
	# Blocchi dei comandi (decisione di Fede): Costruzione (Insediamento, Territorio, Vie,
	# Edifici…), Gestione (Politiche…), Strumenti (Demolizione, Prova…). Ognuno ha in alto le sue
	# schede, come i menù di Cities: Skylines e Age of Empires, e sotto i tasti della scheda aperta.
	for b in BLOCCHI:
		_crea_blocco(fascia, b[0], b[1], b[2])
	_crea_lettura_sito(fascia)
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
	_colonna_mappe = colonna
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


func _crea_blocco(fascia: Control, id: String, titolo: String, colonne: int) -> void:
	var pc := PanelContainer.new()
	pc.custom_minimum_size.y = ALTEZZA_FASCIA
	pc.size_flags_vertical = Control.SIZE_FILL
	fascia.add_child(pc)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	pc.add_child(col)
	var t := Label.new()
	t.text = titolo.to_upper()
	t.add_theme_font_override("font", _carattere(true, 1.6))
	t.add_theme_font_size_override("font_size", 11)
	t.add_theme_color_override("font_color", GRIGIO)
	col.add_child(t)
	# Negli Strumenti le schede vanno a capo se non ci stanno (26/11/2026: con la scheda Partita il
	# blocco si allargava e copriva le notifiche); negli altri blocchi restano su una riga.
	var schede: Container = HFlowContainer.new() if id == "strumenti" else HBoxContainer.new()
	schede.add_theme_constant_override("h_separation" if id == "strumenti" else "separation", 2)
	schede.add_theme_constant_override("v_separation", 2)
	col.add_child(schede)
	var larghezza := colonne * LATO_TASTO + (colonne - 1) * 4
	var pagine := Control.new()
	pagine.custom_minimum_size = Vector2(larghezza, 2 * LATO_TASTO + 4)
	col.add_child(pagine)
	var d := Label.new()
	d.add_theme_font_size_override("font_size", 11)
	d.add_theme_color_override("font_color", GRIGIO)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size.x = larghezza
	d.max_lines_visible = 2
	d.size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_SHRINK_END
	col.add_child(d)
	_blocchi[id] = {"schede": schede, "pagine": pagine, "descrizione": d, "colonne": colonne, "pannello": pc}


func _crea_lettura_sito(fascia: Control) -> void:
	_pannello_sito = PanelContainer.new()
	_pannello_sito.custom_minimum_size.y = ALTEZZA_FASCIA
	_pannello_sito.size_flags_vertical = Control.SIZE_FILL
	_pannello_sito.visible = false
	fascia.add_child(_pannello_sito)
	fascia.move_child(_pannello_sito, _pannello_descrizione.get_index() + 1)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	_pannello_sito.add_child(col)
	var k := Label.new()
	k.text = "FONDAZIONE · IL TERRENO SOTTO IL PUNTATORE"
	k.add_theme_font_override("font", _carattere(true, 1.6))
	k.add_theme_font_size_override("font_size", 11)
	k.add_theme_color_override("font_color", GRIGIO)
	col.add_child(k)
	_titolo_sito = Label.new()
	_titolo_sito.add_theme_font_override("font", _carattere(true))
	_titolo_sito.add_theme_font_size_override("font_size", 20)
	col.add_child(_titolo_sito)
	var griglia := GridContainer.new()
	griglia.columns = 4
	griglia.add_theme_constant_override("h_separation", 24)
	griglia.add_theme_constant_override("v_separation", 10)
	col.add_child(griglia)
	for v in VOCI_SITO:
		var c := VBoxContainer.new()
		c.add_theme_constant_override("separation", 3)
		c.custom_minimum_size.x = 200
		griglia.add_child(c)
		var e := Label.new()
		e.text = String(v[1]).to_upper()
		e.add_theme_font_override("font", _carattere(true, 1.6))
		e.add_theme_font_size_override("font_size", 11)
		e.add_theme_color_override("font_color", GRIGIO)
		c.add_child(e)
		var l := Label.new()
		l.add_theme_font_override("font", _carattere(true))
		l.add_theme_font_size_override("font_size", 15)
		l.clip_text = true
		l.custom_minimum_size.x = 200
		c.add_child(l)
		var fondo := ColorRect.new()
		fondo.color = RIGA
		fondo.custom_minimum_size = Vector2(200, 5)
		c.add_child(fondo)
		var pieno := ColorRect.new()
		pieno.anchor_bottom = 1.0
		fondo.add_child(pieno)
		_voci_sito[v[0]] = {"valore": l, "riempimento": pieno}
	_nota_sito = Label.new()
	_nota_sito.add_theme_font_size_override("font_size", 12)
	_nota_sito.add_theme_color_override("font_color", GRIGIO)
	_nota_sito.size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_SHRINK_END
	col.add_child(_nota_sito)


## Modalità fondazione: la lettura del sito prende il posto della descrizione e dei menù.
func mostra_lettura_sito(attiva: bool) -> void:
	_pannello_sito.visible = attiva
	_pannello_descrizione.visible = not attiva
	for b in _blocchi.values():
		(b["pannello"] as Control).visible = not attiva


func lettura_sito_visibile() -> bool:
	return _pannello_sito.visible


## Valori del sito: titolo, nota in fondo e per ogni voce [testo, quanto (0–1), sfavorevole].
func imposta_lettura_sito(titolo: String, voci: Dictionary, nota: String) -> void:
	_titolo_sito.text = titolo
	_nota_sito.text = nota
	for id in _voci_sito:
		var f: Dictionary = _voci_sito[id]
		var v: Array = voci.get(id, ["—", 0.0, false])
		(f["valore"] as Label).text = String(v[0])
		var colore := PERICOLO if v[2] else BIANCO
		(f["valore"] as Label).add_theme_color_override("font_color", colore)
		var pieno: ColorRect = f["riempimento"]
		pieno.color = colore
		pieno.anchor_right = clampf(float(v[1]), 0.0, 1.0)
		pieno.offset_right = 0.0


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

## Aggiunge un menù (una scheda) a un blocco dei comandi: costruzione, gestione o strumenti.
## voci: dizionari con id, testo, breve (etichetta sotto il tasto), tasto, icona (nome in
## asset/icone), descrizione (cosa fa, mostrata nella scheda dello strumento), pericolo (bool:
## azione irreversibile, segno rosso), strumento (bool: resta selezionato e si usa cliccando sulla
## mappa; altrimenti è un'azione immediata). in_testa: la scheda va per prima nel suo blocco.
func aggiungi_menu(id_menu: String, titolo: String, descrizione: String, voci: Array, blocco := "costruzione", in_testa := false) -> void:
	var bl: Dictionary = _blocchi[blocco]
	var scheda := Button.new()
	scheda.text = titolo
	scheda.toggle_mode = true
	scheda.focus_mode = Control.FOCUS_NONE
	scheda.tooltip_text = descrizione
	scheda.add_theme_font_size_override("font_size", 12)
	(bl["schede"] as Control).add_child(scheda)
	if in_testa:
		(bl["schede"] as Control).move_child(scheda, 0)
	var griglia := GridContainer.new()
	griglia.columns = bl["colonne"]
	griglia.add_theme_constant_override("h_separation", 4)
	griglia.add_theme_constant_override("v_separation", 4)
	griglia.visible = false
	(bl["pagine"] as Control).add_child(griglia)
	_menu[id_menu] = {"scheda": scheda, "pagina": griglia, "descrizione": descrizione, "blocco": blocco}
	scheda.pressed.connect(func() -> void: apri_menu(id_menu))
	for v in voci:
		_aggiungi_voce(griglia, v)
		_menu_di[v["id"]] = id_menu
	if in_testa or String(bl.get("aperto", "")) == "":
		apri_menu(id_menu)


## Apre una scheda nel suo blocco (le schede degli altri blocchi restano come sono).
func apri_menu(id_menu: String) -> void:
	if not _menu.has(id_menu):
		return
	_menu_scelto = id_menu
	var blocco: String = _menu[id_menu]["blocco"]
	_blocchi[blocco]["aperto"] = id_menu
	for k in _menu:
		if _menu[k]["blocco"] != blocco:
			continue
		(_menu[k]["scheda"] as Button).set_pressed_no_signal(k == id_menu)
		(_menu[k]["pagina"] as Control).visible = k == id_menu
	(_blocchi[blocco]["descrizione"] as Label).text = _menu[id_menu]["descrizione"]


## L'ultima scheda aperta, oppure quella aperta in un blocco.
func menu_aperto(blocco := "") -> String:
	if blocco != "":
		return _blocchi[blocco].get("aperto", "")
	return _menu_scelto


func _aggiungi_voce(griglia: Control, v: Dictionary) -> void:
	var b := _tasto(griglia, v)
	var id: String = v["id"]
	_testi[id] = v["testo"]
	_descrizioni[id] = v.get("descrizione", "")
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
	# Pittogramma (gioco/asset/icone, bianco su trasparente): al centro, con la lettera del tasto
	# piccola nell'angolo. Si tinge di nero quando il tasto è scelto, come i testi.
	var icona: TextureRect = null
	if String(v.get("icona", "")) != "":
		var tex := load(ICONE % v["icona"]) as Texture2D
		if tex:
			icona = TextureRect.new()
			icona.texture = tex
			icona.name = "Icona"
			icona.position = Vector2((LATO_TASTO - LATO_ICONA) / 2.0, 6)
			icona.size = Vector2(LATO_ICONA, LATO_ICONA)
			icona.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icona.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icona.modulate = BIANCO
			icona.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(icona)
			tasto.position = Vector2(4, 1)
			tasto.add_theme_font_size_override("font_size", 10)
			tasto.add_theme_color_override("font_color", GRIGIO)
			nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			nome.position = Vector2(2, LATO_TASTO - 19)
			nome.size = Vector2(LATO_TASTO - 4, 16)
	if v.get("pericolo", false):
		var segno := ColorRect.new()
		segno.color = PERICOLO
		segno.position = Vector2(LATO_TASTO - 12, 4)
		segno.size = Vector2(8, 8)
		segno.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(segno)
	# Testi e icona neri quando il tasto è scelto (inversione).
	b.toggled.connect(func(on: bool) -> void: _inverti(b, on))
	return b


## Opzioni di uno strumento: voci {id, testo, suggerimento}. Interruttori che emettono azione(id);
## il loro stato si segna con segna(id, acceso).
func aggiungi_opzioni(strumento: String, voci: Array) -> void:
	var tasti: Array = []
	for v in voci:
		var b := Button.new()
		b.text = v["testo"]
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.tooltip_text = v.get("suggerimento", "")
		b.add_theme_font_size_override("font_size", 12)
		b.visible = false
		# Interruttore: un quadratino vuoto o pieno davanti al nome, bordo sottile; acceso, invertito.
		var st := StyleBoxFlat.new()
		st.bg_color = Color(0, 0, 0, 0)
		st.set_border_width_all(1)
		st.border_color = RIGA
		st.set_content_margin_all(6)
		b.add_theme_stylebox_override("normal", st)
		var nome: String = v["testo"]
		b.text = "□  " + nome
		b.toggled.connect(func(on: bool) -> void: b.text = ("■  " if on else "□  ") + nome)
		var id: String = v["id"]
		b.pressed.connect(func() -> void: azione.emit(id))
		_opzioni.add_child(b)
		_righe_azioni[id] = b
		tasti.append(b)
	_opzioni_di[strumento] = tasti


## Mostra o nasconde un comando; una scheda senza comandi visibili sparisce.
func mostra(id: String, visibile: bool) -> void:
	var b: Button = _righe_azioni.get(id, _righe_comandi.get(id))
	if b == null or b.visible == visibile:
		return
	b.visible = visibile
	for k in _menu:
		var pagina: Control = _menu[k]["pagina"]
		var piena := pagina.get_children().any(func(c: Node) -> bool: return (c as Control).visible)
		(_menu[k]["scheda"] as Control).visible = piena
		var blocco: String = _menu[k]["blocco"]
		if not piena and _blocchi[blocco].get("aperto", "") == k:
			for k2 in _menu:
				if _menu[k2]["blocco"] == blocco and (_menu[k2]["scheda"] as Control).visible:
					apri_menu(k2)
					break


func seleziona_comando(id: String) -> void:
	_comando = id
	var ha_opzioni := false
	for k in _opzioni_di:
		for b in _opzioni_di[k]:
			(b as Control).visible = k == id
			ha_opzioni = ha_opzioni or k == id
	_opzioni.visible = ha_opzioni
	for k in _righe_comandi:
		_premi(_righe_comandi[k], k == id)
	_nome_strumento.text = _testi.get(id, "Nessuno strumento").get_slice(" (", 0)
	if _menu_di.has(id):
		apri_menu(_menu_di[id])
	if String(_descrizioni.get(id, "")) != "":
		_messaggio.text = _descrizioni[id]


## Stato di un tasto senza emettere il segnale, con i testi interni in nero se scelto.
func _premi(b: Button, on: bool) -> void:
	b.set_pressed_no_signal(on)
	_inverti(b, on)


## Inversione di un tasto scelto: testi e icona neri sul fondo bianco. La lettera del tasto,
## quando c'è l'icona, resta grigia (è un'indicazione secondaria).
func _inverti(b: Button, on: bool) -> void:
	on = on and not b.disabled  # un tasto spento non si inverte (testi neri sul fondo scuro)
	var con_icona := b.has_node("Icona")
	for c in b.get_children():
		if c is TextureRect:
			(c as TextureRect).modulate = NERO if on else BIANCO
		elif c is Label:
			var secondaria := con_icona and (c as Label).position.y < 10
			(c as Label).add_theme_color_override("font_color", (NERO if on else GRIGIO) if secondaria else (NERO if on else BIANCO))


func comando() -> String:
	return _comando


## Segna come scelta (per inversione) una riga di azione, per esempio la velocità del tempo.
func segna(id: String, premuto: bool) -> void:
	var r: Button = _righe_azioni.get(id, _righe_comandi.get(id))
	if r:
		r.toggle_mode = true
		_premi(r, premuto)
		if r.text.begins_with("□") or r.text.begins_with("■"):
			r.text = ("■" if premuto else "□") + r.text.substr(1)


func abilita(id: String, attivo: bool) -> void:
	var r: Button = _righe_azioni.get(id, _righe_comandi.get(id))
	if r:
		r.disabled = not attivo
		r.modulate.a = 1.0 if attivo else 0.4
		_inverti(r, r.button_pressed)


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
			e.custom_minimum_size.x = COLONNA_NOMI_INFO
			e.add_theme_font_override("font", _carattere(true, 1.6))
			e.add_theme_font_size_override("font_size", 11)
			e.add_theme_color_override("font_color", GRIGIO)
			box.add_child(e)
			var l := _valore_info(16)
			box.add_child(l)
			box.mouse_filter = Control.MOUSE_FILTER_STOP
			if nome in INDICATORI_CON_FOCUS:
				box.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
				box.gui_input.connect(func(ev: InputEvent) -> void:
					if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
						indicatore_scelto.emit(nome))
			indicatori.add_child(box)
			_valori_indicatori[nome] = l
		var lab: Label = _valori_indicatori[nome]
		lab.text = str(v[1])
		lab.add_theme_color_override("font_color", PERICOLO if v[2] else BIANCO)
		# Quarto elemento facoltativo: cosa vuol dire l'indicatore (suggerimento al passaggio).
		if v.size() > 3:
			(lab.get_parent() as Control).tooltip_text = String(v[3])


## Valore del blocco Info: cifre tabellari, allineato a destra nello spazio dopo la colonna dei
## nomi; se un numero non ci sta si tronca con i puntini invece di allargare il blocco.
func _valore_info(corpo: int) -> Label:
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.clip_text = true
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.add_theme_font_override("font", _carattere(true, 0.0, true))
	l.add_theme_font_size_override("font_size", corpo)
	return l


## Fonti di cibo nel blocco Info. voci: {id, nome, preso, offerta, accesa, allarme, freccia,
## suggerimento}. Per ognuna: quanto se ne prende quest'anno / quanto è disponibile, e una barra
## sottile con la quota usata (bianca; rossa se la risorsa si sta esaurendo; grigia se la fonte è
## spenta). Un clic apre le politiche.
func imposta_fonti(voci: Array) -> void:
	_sezione_fonti.visible = not voci.is_empty()
	for v in voci:
		var id: String = v["id"]
		if not _fonti_info.has(id):
			var riga := VBoxContainer.new()
			riga.add_theme_constant_override("separation", 1)
			riga.mouse_filter = Control.MOUSE_FILTER_STOP
			riga.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			riga.gui_input.connect(func(ev: InputEvent) -> void:
				if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
					fonte_scelta.emit(id))
			_sezione_fonti.add_child(riga)
			var box := HBoxContainer.new()
			box.mouse_filter = Control.MOUSE_FILTER_IGNORE
			riga.add_child(box)
			var e := Label.new()
			e.text = String(v["nome"]).to_upper()
			e.custom_minimum_size.x = COLONNA_NOMI_INFO
			e.add_theme_font_override("font", _carattere(true, 1.6))
			e.add_theme_font_size_override("font_size", 11)
			e.add_theme_color_override("font_color", GRIGIO)
			box.add_child(e)
			var l := _valore_info(14)
			box.add_child(l)
			var fondo := ColorRect.new()
			fondo.color = RIGA
			fondo.custom_minimum_size.y = 3
			fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
			riga.add_child(fondo)
			var pieno := ColorRect.new()
			pieno.anchor_bottom = 1.0
			pieno.mouse_filter = Control.MOUSE_FILTER_IGNORE
			fondo.add_child(pieno)
			_fonti_info[id] = {"valore": l, "riempimento": pieno, "riga": riga}
		var f: Dictionary = _fonti_info[id]
		var accesa: bool = v["accesa"]
		var preso: float = v["preso"]
		var offerta: float = v["offerta"]
		var lab: Label = f["valore"]
		if accesa:
			lab.text = ("%d / %d %s" % [roundi(preso), roundi(offerta), v.get("freccia", "")]).strip_edges()
		else:
			lab.text = "spenta"
		var colore := GRIGIO if not accesa else (PERICOLO if v.get("allarme", false) else BIANCO)
		lab.add_theme_color_override("font_color", colore)
		var pieno: ColorRect = f["riempimento"]
		pieno.color = colore
		pieno.anchor_right = clampf(preso / offerta, 0.0, 1.0) if accesa and offerta > 0.0 else 0.0
		pieno.offset_right = 0.0
		(f["riga"] as Control).tooltip_text = String(v.get("suggerimento", ""))


func imposta_cronaca(righe: Array) -> void:
	_cronaca.text = "\n".join(righe.slice(0, 4)) if not righe.is_empty() else "—"


# ---------- notifiche ----------
# Notifiche discrete (decisione di Fede del 24/11/2026: il ritmo è meditativo, non incalzante):
# per ciò che non chiede un intervento (carestia, piena, siccità). Una colonna di righe sopra la
# minimappa, le più nuove in basso; si spengono da sole; un clic porta la camera sul luogo.
# Segno rosso solo per i pericoli, grigio per il resto. Non fermano mai il tempo.
const MAX_NOTIFICHE := 4
const DURATA_NOTIFICA := 9.0

func notifica(testo: String, pericolo := false, punto := Vector2(-1, -1)) -> void:
	if _colonna_mappe:
		_notifiche.offset_bottom = -maxf(_colonna_mappe.size.y, LATO_MINIMAPPA) - 6
	var p := PanelContainer.new()
	p.custom_minimum_size.x = 300
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	if punto.x >= 0.0:
		p.tooltip_text = "Clic per andare sul luogo"
		p.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var riga := HBoxContainer.new()
	riga.add_theme_constant_override("separation", 10)
	riga.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(riga)
	var segno := ColorRect.new()
	segno.color = PERICOLO if pericolo else GRIGIO
	segno.custom_minimum_size = Vector2(4, 0)
	segno.mouse_filter = Control.MOUSE_FILTER_IGNORE
	riga.add_child(segno)
	var l := Label.new()
	l.text = testo
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 266
	l.add_theme_font_size_override("font_size", 12)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	riga.add_child(l)
	p.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			if punto.x >= 0.0:
				notifica_scelta.emit(punto)
			p.queue_free())
	_notifiche.add_child(p)
	while _notifiche.get_child_count() > MAX_NOTIFICHE:
		var vecchia := _notifiche.get_child(0)
		_notifiche.remove_child(vecchia)
		vecchia.queue_free()
	if is_inside_tree():
		var tw := p.create_tween()
		tw.tween_interval(DURATA_NOTIFICA)
		tw.tween_property(p, "modulate:a", 0.0, 0.8)
		tw.tween_callback(p.queue_free)


## Notifiche visibili ora (per le verifiche).
func notifiche() -> Array[String]:
	var out: Array[String] = []
	for c in _notifiche.get_children():
		if not c.is_queued_for_deletion():
			out.append(((c as Control).get_child(0).get_child(1) as Label).text)
	return out


func avviso(testo: String) -> void:
	notifica(testo, true)


func _crea_notifiche(radice: Control) -> void:
	_notifiche = VBoxContainer.new()
	_notifiche.anchor_left = 1.0
	_notifiche.anchor_right = 1.0
	_notifiche.anchor_top = 1.0
	_notifiche.anchor_bottom = 1.0
	_notifiche.offset_bottom = -LATO_MINIMAPPA - 30
	_notifiche.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_notifiche.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_notifiche.add_theme_constant_override("separation", 2)
	_notifiche.mouse_filter = Control.MOUSE_FILTER_IGNORE
	radice.add_child(_notifiche)


# ---------- politiche ----------
# Le politiche non sono costruzioni (decisione di Fede del 24/11/2026): sono regole che valgono
# finché non si cambiano. Stanno in un pannello a parte, sopra la fascia dei comandi, che si
# apre con il tasto Politiche (P) e non ferma il tempo.

func _crea_politiche(radice: Control) -> void:
	_pannello_politiche = PanelContainer.new()
	_pannello_politiche.anchor_top = 1.0
	_pannello_politiche.anchor_bottom = 1.0
	_pannello_politiche.offset_left = 190 + 2
	_pannello_politiche.offset_bottom = -ALTEZZA_FASCIA - 2
	_pannello_politiche.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_pannello_politiche.custom_minimum_size.x = 520
	_pannello_politiche.visible = false
	radice.add_child(_pannello_politiche)
	# Le politiche cresceranno: il pannello scorre se non c'è spazio fino alla cronaca.
	_scorri_politiche = ScrollContainer.new()
	_scorri_politiche.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_pannello_politiche.add_child(_scorri_politiche)
	_colonna_politiche = VBoxContainer.new()
	_colonna_politiche.add_theme_constant_override("separation", 8)
	_colonna_politiche.custom_minimum_size.x = 504
	_scorri_politiche.add_child(_colonna_politiche)
	var testa := HBoxContainer.new()
	_colonna_politiche.add_child(testa)
	var k := Label.new()
	k.text = "POLITICHE"
	k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	k.add_theme_font_override("font", _carattere(true, 1.6))
	k.add_theme_font_size_override("font_size", 11)
	k.add_theme_color_override("font_color", GRIGIO)
	testa.add_child(k)
	var chiudi := Button.new()
	chiudi.text = "Chiudi (P)"
	chiudi.focus_mode = Control.FOCUS_NONE
	chiudi.add_theme_font_size_override("font_size", 11)
	chiudi.pressed.connect(func() -> void: apri_politiche(false))
	testa.add_child(chiudi)
	var t := Label.new()
	t.text = "Le regole del villaggio"
	t.add_theme_font_override("font", _carattere(true))
	t.add_theme_font_size_override("font_size", 18)
	_colonna_politiche.add_child(t)
	var nota := Label.new()
	nota.text = "Valgono finché non si cambiano. Cambiarle costa un po' di consenso: le abitudini pesano."
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nota.custom_minimum_size.x = 488
	nota.add_theme_font_size_override("font_size", 12)
	nota.add_theme_color_override("font_color", GRIGIO)
	_colonna_politiche.add_child(nota)


## Aggiunge le politiche al pannello. voci: {id, titolo, descrizione, opzioni: [{id, testo, nota}]}.
func aggiungi_politiche(voci: Array) -> void:
	for v in voci:
		var riga := ColorRect.new()
		riga.color = RIGA
		riga.custom_minimum_size.y = 1
		_colonna_politiche.add_child(riga)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 6)
		_colonna_politiche.add_child(col)
		var t := Label.new()
		t.text = v["titolo"]
		t.add_theme_font_override("font", _carattere(true))
		t.add_theme_font_size_override("font_size", 14)
		col.add_child(t)
		if String(v.get("descrizione", "")) != "":
			var d := Label.new()
			d.text = v["descrizione"]
			d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			d.custom_minimum_size.x = 488
			d.add_theme_font_size_override("font_size", 12)
			d.add_theme_color_override("font_color", GRIGIO)
			col.add_child(d)
		var scelte := HBoxContainer.new()
		scelte.add_theme_constant_override("separation", 4)
		col.add_child(scelte)
		var id: String = v["id"]
		var voce := {"opzioni": {}, "note": {}, "interruttori": {}, "colonna": col}
		# Interruttori (più voci accese insieme, per esempio le fonti di cibo) invece di opzioni
		# alternative: quadratino vuoto o pieno davanti al nome.
		for o in v.get("interruttori", []):
			var b := Button.new()
			var nome: String = o["testo"]
			b.text = "□  " + nome
			b.toggle_mode = true
			b.focus_mode = Control.FOCUS_NONE
			b.custom_minimum_size = Vector2(0, 30)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var vid: String = o["id"]
			b.toggled.connect(func(on: bool) -> void: b.text = ("■  " if on else "□  ") + nome)
			b.pressed.connect(func() -> void: interruttore_scelto.emit(id, vid, b.button_pressed))
			scelte.add_child(b)
			voce["interruttori"][vid] = b
		for o in v.get("opzioni", []):
			var b := Button.new()
			b.text = o["testo"]
			b.toggle_mode = true
			b.focus_mode = Control.FOCUS_NONE
			b.custom_minimum_size = Vector2(0, 30)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var valore: String = o["id"]
			b.pressed.connect(func() -> void:
				imposta_politica(id, valore)
				politica_scelta.emit(id, valore))
			scelte.add_child(b)
			voce["opzioni"][valore] = b
			voce["note"][valore] = String(o.get("nota", ""))
		var effetto := Label.new()
		effetto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		effetto.custom_minimum_size.x = 488
		effetto.add_theme_font_size_override("font_size", 12)
		col.add_child(effetto)
		voce["nota"] = effetto
		var stato := Label.new()
		stato.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		stato.custom_minimum_size.x = 488
		stato.add_theme_font_size_override("font_size", 11)
		stato.add_theme_color_override("font_color", GRIGIO)
		stato.visible = false
		col.add_child(stato)
		voce["stato"] = stato
		_politiche[id] = voce


## Mostra quale valore di una politica è in vigore (inversione) e cosa comporta.
func imposta_politica(id: String, valore: String) -> void:
	if not _politiche.has(id):
		return
	var voce: Dictionary = _politiche[id]
	for k in voce["opzioni"]:
		(voce["opzioni"][k] as Button).set_pressed_no_signal(k == valore)
	(voce["nota"] as Label).text = voce["note"].get(valore, "")


## Accende o spegne le opzioni di una politica (spenta: si vede ma non si può cambiare), con una
## riga grigia che dice perché o a che punto è.
func abilita_politica(id: String, attiva: bool, stato := "") -> void:
	if not _politiche.has(id):
		return
	var voce: Dictionary = _politiche[id]
	for k in voce["opzioni"]:
		var b: Button = voce["opzioni"][k]
		b.disabled = not attiva
		b.modulate.a = 1.0 if attiva else 0.4
	var l: Label = voce["stato"]
	l.text = stato
	l.visible = stato != ""
	# Una politica non ancora aperta non si vede: compare con la sua tappa (Fede, 26/11/2026).
	(voce["colonna"] as Control).visible = attiva


func politica_attiva(id: String) -> bool:
	if not _politiche.has(id):
		return false
	for k in _politiche[id]["opzioni"]:
		return not (_politiche[id]["opzioni"][k] as Button).disabled
	return false


## Stato degli interruttori di una politica ({voce: acceso}) e riga che dice cosa comporta.
func imposta_interruttori(id: String, stati: Dictionary, nota := "") -> void:
	if not _politiche.has(id):
		return
	var voce: Dictionary = _politiche[id]
	for k in stati:
		var b: Button = voce["interruttori"].get(k)
		if b:
			b.set_pressed_no_signal(stati[k])
			b.text = ("■" if stati[k] else "□") + b.text.substr(1)
	(voce["nota"] as Label).text = nota


func interruttore(id: String, voce: String) -> bool:
	return _politiche.has(id) and (_politiche[id]["interruttori"].get(voce) as Button).button_pressed


func politica(id: String) -> String:
	if not _politiche.has(id):
		return ""
	for k in _politiche[id]["opzioni"]:
		if (_politiche[id]["opzioni"][k] as Button).button_pressed:
			return k
	return ""


func apri_politiche(aperto: bool) -> void:
	if aperto:
		chiudi_focus()
		if _pannello_conseguenze:
			_pannello_conseguenze.visible = false
	# Appena sopra la fascia in basso, qualunque sia la sua altezza.
	var sotto := maxf(_fascia.size.y, ALTEZZA_FASCIA) + 2
	_pannello_politiche.offset_bottom = -sotto
	# Altezza: quella del contenuto, ma senza coprire la cronaca in alto a sinistra.
	var schermo := get_viewport().get_visible_rect().size.y if is_inside_tree() else 900.0
	var spazio := schermo - sotto - 190.0
	var alto := clampf(_colonna_politiche.get_combined_minimum_size().y, 120.0, maxf(spazio, 120.0))
	_scorri_politiche.custom_minimum_size.y = alto
	var bordi := _pannello_politiche.get_theme_stylebox("panel").get_minimum_size().y
	_pannello_politiche.offset_top = -sotto - alto - bordi
	_pannello_politiche.visible = aperto
	segna("politiche", aperto)


func politiche_aperte() -> bool:
	return _pannello_politiche.visible


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


## Riquadro del tutorial (decisione di Fede del 26/11/2026): la novità in due o tre righe, un tasto
## che apre la spiegazione completa, Continua e la casella "Salta i tutorial" (vale per il resto
## della partita). `al_termine` riceve "continua" o "salta".
func mostra_tutorial(d: Dictionary, al_termine: Callable) -> void:
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
	p.name = "Tutorial"
	p.custom_minimum_size.x = 560
	centro.add_child(p)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	p.add_child(col)
	var k := Label.new()
	var pagine := int(d.get("pagine", 1))
	var testa := "Tutorial · " + String(d.get("tappa", ""))
	if pagine > 1:
		testa += " · %d di %d" % [int(d.get("pagina", 1)), pagine]
	k.text = testa.to_upper()
	k.add_theme_font_override("font", _carattere(true, 1.6))
	k.add_theme_font_size_override("font_size", 11)
	k.add_theme_color_override("font_color", GRIGIO)
	col.add_child(k)
	var t := Label.new()
	t.text = d["titolo"]
	t.add_theme_font_override("font", _carattere(true))
	t.add_theme_font_size_override("font_size", 24)
	col.add_child(t)
	var riga := ColorRect.new()
	riga.color = RIGA
	riga.custom_minimum_size.y = 1
	col.add_child(riga)
	var corpo := Label.new()
	corpo.text = d["testo"]
	corpo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	corpo.custom_minimum_size.x = 528
	col.add_child(corpo)
	# "Cosa fa…?": apre e chiude la spiegazione completa.
	var domanda := Button.new()
	domanda.name = "Domanda"
	domanda.text = "%s  +" % d.get("domanda", "Cosa fa?")
	domanda.alignment = HORIZONTAL_ALIGNMENT_LEFT
	domanda.focus_mode = Control.FOCUS_NONE
	domanda.flat = true
	domanda.add_theme_color_override("font_color", Color.WHITE)
	col.add_child(domanda)
	var dettaglio := Label.new()
	dettaglio.name = "Dettaglio"
	dettaglio.text = d.get("dettaglio", "")
	dettaglio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dettaglio.custom_minimum_size.x = 528
	dettaglio.add_theme_font_size_override("font_size", 13)
	dettaglio.add_theme_color_override("font_color", GRIGIO.lerp(Color.WHITE, 0.5))
	dettaglio.visible = false
	col.add_child(dettaglio)
	domanda.pressed.connect(func() -> void:
		dettaglio.visible = not dettaglio.visible
		domanda.text = "%s  %s" % [d.get("domanda", "Cosa fa?"), "−" if dettaglio.visible else "+"])
	var riga2 := ColorRect.new()
	riga2.color = RIGA
	riga2.custom_minimum_size.y = 1
	col.add_child(riga2)
	var piede := HBoxContainer.new()
	piede.add_theme_constant_override("separation", 12)
	col.add_child(piede)
	# Casella come gli interruttori delle opzioni: quadratino vuoto o pieno, bordo sottile.
	var salta := Button.new()
	salta.name = "Salta"
	salta.toggle_mode = true
	salta.text = "□  Salta i tutorial"
	salta.focus_mode = Control.FOCUS_NONE
	salta.add_theme_font_size_override("font_size", 12)
	var st_s := StyleBoxFlat.new()
	st_s.bg_color = Color(0, 0, 0, 0)
	st_s.set_border_width_all(1)
	st_s.border_color = RIGA
	st_s.set_content_margin_all(8)
	salta.add_theme_stylebox_override("normal", st_s)
	salta.add_theme_stylebox_override("pressed", st_s)
	salta.add_theme_stylebox_override("hover", st_s)
	salta.toggled.connect(func(on: bool) -> void: salta.text = ("■  " if on else "□  ") + "Salta i tutorial")
	salta.tooltip_text = "Per il resto di questa partita le novità arrivano come notifiche, senza fermare il gioco."
	piede.add_child(salta)
	var spazio := Control.new()
	spazio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	piede.add_child(spazio)
	var continua := Button.new()
	continua.name = "Continua"
	continua.text = "Continua" if int(d.get("pagina", 1)) >= pagine else "Avanti"
	continua.focus_mode = Control.FOCUS_NONE
	continua.custom_minimum_size = Vector2(120, 34)
	var st := StyleBoxFlat.new()
	st.bg_color = Color.WHITE
	st.set_content_margin_all(8)
	continua.add_theme_stylebox_override("normal", st)
	continua.add_theme_color_override("font_color", Color.BLACK)
	piede.add_child(continua)
	continua.pressed.connect(func() -> void:
		var scelta := "salta" if salta.button_pressed else "continua"
		chiudi_scelta()
		al_termine.call(scelta))


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


## Carattere dell'HUD: Inter (licenza SIL Open Font License, vedi
## asset/caratteri/inter/LEGGIMI.md), il più vicino all'Helvetica della grafica svizzera.
const INTER := "res://asset/caratteri/inter/Inter-%s.woff2"


func _carattere(grassetto: bool, spaziatura := 0.0, cifre_fisse := false) -> Font:
	var f := FontVariation.new()
	f.base_font = load(INTER % ("Bold" if grassetto else "Regular"))
	if spaziatura > 0.0:
		f.spacing_glyph = int(spaziatura)
	# Cifre tabellari (tnum): tutte le cifre larghe uguali, così i numeri che cambiano non ballano.
	if cifre_fisse:
		f.opentype_features = {TextServerManager.get_primary_interface().name_to_tag("tnum"): 1}
	return f


func _crea_tema() -> Theme:
	var t := Theme.new()
	t.default_font = load(INTER % "Medium")
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


# ---------- pannelli di focus (decisione di Fede del 25/11/2026) ----------
# Un clic su un indicatore apre, sopra il blocco Info, un pannello che dice di cosa è fatto, perché
# sale o scende (le cause scritte in chiaro), come è andato negli ultimi decenni e dove succede.
# Non ferma il gioco e si aggiorna mentre il tempo scorre; Esc o un clic destro lo chiudono.

## dati: {titolo, valore, allarme, descrizione, parti: [[nome, quota 0–1, testo]], cause: [String],
## serie: Array (ultimi anni), mappa: indice della mappa tematica o -1, testo_mappa}.
func mostra_focus(dati: Dictionary) -> void:
	if _pannello_focus == null:
		_crea_focus()
	if politiche_aperte():
		apri_politiche(false)
	_focus = String(dati.get("titolo", ""))
	if _pannello_conseguenze:
		_pannello_conseguenze.visible = false
	_riempi_focus(dati)
	_posiziona_focus()
	_pannello_focus.visible = true
	# La fascia può cambiare altezza nello stesso fotogramma: si ricontrolla dopo l'impaginazione.
	call_deferred("_posiziona_focus")


func aggiorna_focus(dati: Dictionary) -> void:
	if focus_aperto() == String(dati.get("titolo", "")):
		_riempi_focus(dati)
		_posiziona_focus()


## Appena sopra la fascia in basso, qualunque sia la sua altezza (come le politiche).
func _posiziona_focus() -> void:
	var sotto := maxf(_fascia.size.y, ALTEZZA_FASCIA) + 2
	_pannello_focus.offset_bottom = -sotto
	_pannello_focus.offset_top = -sotto - _pannello_focus.get_combined_minimum_size().y


func chiudi_focus() -> void:
	if _pannello_focus:
		_pannello_focus.visible = false
	_focus = ""


func focus_aperto() -> String:
	return _focus if _pannello_focus != null and _pannello_focus.visible else ""


func _crea_focus() -> void:
	_pannello_focus = PanelContainer.new()
	_pannello_focus.anchor_top = 1.0
	_pannello_focus.anchor_bottom = 1.0
	_pannello_focus.offset_left = 2
	_pannello_focus.offset_bottom = -ALTEZZA_FASCIA - 2
	_pannello_focus.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_pannello_focus.custom_minimum_size.x = 380
	_pannello_focus.mouse_filter = Control.MOUSE_FILTER_STOP
	_pannello_focus.visible = false
	_radice.add_child(_pannello_focus)
	_colonna_focus = VBoxContainer.new()
	_colonna_focus.add_theme_constant_override("separation", 8)
	_colonna_focus.custom_minimum_size.x = 364
	_pannello_focus.add_child(_colonna_focus)


func _riempi_focus(dati: Dictionary) -> void:
	for c in _colonna_focus.get_children():
		_colonna_focus.remove_child(c)
		c.queue_free()
	var testa := HBoxContainer.new()
	_colonna_focus.add_child(testa)
	var k := Label.new()
	k.text = String(dati["scheda"]) if dati.has("scheda") else ("RAPPORTI DI FORZA" if dati.has("gruppi") else ("FAMIGLIA" if dati.has("famiglia") else "FOCUS"))
	k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	k.add_theme_font_override("font", _carattere(true, 1.6))
	k.add_theme_font_size_override("font_size", 11)
	k.add_theme_color_override("font_color", GRIGIO)
	testa.add_child(k)
	var chiudi := Button.new()
	chiudi.text = "Chiudi (Esc)"
	chiudi.focus_mode = Control.FOCUS_NONE
	chiudi.add_theme_font_size_override("font_size", 11)
	chiudi.pressed.connect(chiudi_focus)
	testa.add_child(chiudi)
	var riga_titolo := HBoxContainer.new()
	_colonna_focus.add_child(riga_titolo)
	var t := Label.new()
	t.text = String(dati.get("titolo", ""))
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.add_theme_font_override("font", _carattere(true))
	t.add_theme_font_size_override("font_size", 18)
	riga_titolo.add_child(t)
	var v := Label.new()
	v.text = String(dati.get("valore", ""))
	v.add_theme_font_override("font", _carattere(true, 0.0, true))
	v.add_theme_font_size_override("font_size", 18)
	v.add_theme_color_override("font_color", PERICOLO if dati.get("allarme", false) else BIANCO)
	riga_titolo.add_child(v)
	if String(dati.get("descrizione", "")) != "":
		_colonna_focus.add_child(_testo_focus(String(dati["descrizione"]), GRIGIO, 12))
	if dati.has("gruppi"):
		_riempi_rapporti(dati)
	if dati.has("famiglia"):
		_riempi_famiglia(dati)
	if dati.has("righe"):
		_riempi_righe(dati["righe"])
	if dati.has("scelte"):
		_riempi_scelte(dati["scelte"])
	var parti: Array = dati.get("parti", []) if not dati.has("gruppi") and not dati.has("famiglia") and not dati.has("righe") else []
	if not parti.is_empty():
		_colonna_focus.add_child(_titoletto_focus("DI COSA È FATTO"))
		for p in parti:
			var box := VBoxContainer.new()
			box.add_theme_constant_override("separation", 2)
			_colonna_focus.add_child(box)
			var r := HBoxContainer.new()
			box.add_child(r)
			var n := Label.new()
			n.text = String(p[0])
			n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			n.add_theme_font_size_override("font_size", 12)
			r.add_child(n)
			var q := Label.new()
			q.text = String(p[2])
			q.add_theme_font_override("font", _carattere(false, 0.0, true))
			q.add_theme_font_size_override("font_size", 12)
			r.add_child(q)
			var fondo := ColorRect.new()
			fondo.color = RIGA
			fondo.custom_minimum_size = Vector2(364, 4)
			box.add_child(fondo)
			var barra := ColorRect.new()
			var quota := clampf(float(p[1]), 0.0, 1.0)
			barra.color = PERICOLO if quota < 0.35 else BIANCO
			barra.size = Vector2(364.0 * quota, 4)
			fondo.add_child(barra)
	var cause: Array = dati.get("cause", [])
	# Nei rapporti di forza il perché sta al passaggio sopra ogni gruppo (Fede: niente muri di testo).
	if not dati.has("gruppi") and not dati.has("famiglia"):
		_colonna_focus.add_child(_titoletto_focus("PERCHÉ"))
		if cause.is_empty():
			_colonna_focus.add_child(_testo_focus("Niente di particolare: va tutto come al solito.", BIANCO, 12))
		for c in cause:
			_colonna_focus.add_child(_testo_focus("· " + String(c), BIANCO, 12))
	var serie: Array = dati.get("serie", [])
	if serie.size() >= 2:
		_colonna_focus.add_child(_titoletto_focus("ULTIMI %d ANNI" % serie.size()))
		var g := _GraficoFocus.new()
		g.valori = serie
		g.colore = BIANCO
		g.custom_minimum_size = Vector2(364, 44)
		_colonna_focus.add_child(g)
	var mappa: int = int(dati.get("mappa", -1))
	if mappa >= 0:
		var b := Button.new()
		b.text = String(dati.get("testo_mappa", "Mostra sulla mappa"))
		b.focus_mode = Control.FOCUS_NONE
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 12)
		b.pressed.connect(func() -> void: mappa_richiesta.emit(mappa))
		_colonna_focus.add_child(b)


## Specchietto dei rapporti di forza (decisione di Fede del 26/11/2026): per ogni gruppo il peso
## (quanto conta con il governo di oggi) e l'umore (il suo consenso), con la parola e la freccia;
## poi la tensione e verso dove si muove la città. dati["gruppi"]: [{nome, peso 0–1, umore 0–100,
## parola, freccia, vuole}]; dati["tensione"]: [0–1, parola]; dati["verso"]: testo.
func _riempi_rapporti(dati: Dictionary) -> void:
	var intestazione := HBoxContainer.new()
	_colonna_focus.add_child(intestazione)
	for c in [["GRUPPO", 92], ["PESO", 64], ["UMORE", 124], ["", 84]]:
		var l := _titoletto_focus(c[0])
		l.custom_minimum_size.x = c[1]
		intestazione.add_child(l)
	for g in dati["gruppi"]:
		var riga := HBoxContainer.new()
		riga.mouse_filter = Control.MOUSE_FILTER_PASS
		riga.tooltip_text = String(g.get("vuole", ""))
		_colonna_focus.add_child(riga)
		var n := Label.new()
		n.text = String(g["nome"])
		n.custom_minimum_size.x = 92
		n.mouse_filter = Control.MOUSE_FILTER_PASS
		n.add_theme_font_override("font", _carattere(true))
		n.add_theme_font_size_override("font_size", 13)
		riga.add_child(n)
		riga.add_child(_barra_rapporti(float(g["peso"]), 56, false))
		var umore := float(g["umore"]) / 100.0
		riga.add_child(_barra_rapporti(umore, 116, umore < 0.4))
		var p := Label.new()
		p.text = String(g["parola"]) + ("  " + String(g["freccia"]) if String(g.get("freccia", "")) != "" else "")
		p.custom_minimum_size.x = 84
		p.mouse_filter = Control.MOUSE_FILTER_PASS
		p.add_theme_font_size_override("font_size", 12)
		p.add_theme_color_override("font_color", PERICOLO if umore < 0.4 else BIANCO)
		riga.add_child(p)
	var tens: Array = dati.get("tensione", [])
	if not tens.is_empty():
		var rt := HBoxContainer.new()
		_colonna_focus.add_child(rt)
		var lt := _titoletto_focus("TENSIONE")
		lt.custom_minimum_size.x = 112
		lt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		rt.add_child(lt)
		rt.add_child(_barra_rapporti(float(tens[0]), 160, float(tens[0]) > 0.66))
		var pt := Label.new()
		pt.text = String(tens[1])
		pt.add_theme_font_size_override("font_size", 12)
		pt.add_theme_color_override("font_color", PERICOLO if float(tens[0]) > 0.66 else BIANCO)
		rt.add_child(pt)
	if String(dati.get("verso", "")) != "":
		var rv := HBoxContainer.new()
		_colonna_focus.add_child(rv)
		var lv := _titoletto_focus("SI MUOVE VERSO")
		lv.custom_minimum_size.x = 112
		lv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		rv.add_child(lv)
		var tv := Label.new()
		tv.text = String(dati["verso"])
		tv.clip_text = true
		tv.custom_minimum_size.x = 252
		tv.add_theme_font_size_override("font_size", 12)
		rv.add_child(tv)


## Scheda della famiglia (decisione di Fede del 26/11/2026): righe brevi [etichetta, testo, perché]
## con il perché al passaggio del puntatore, poi l'umore con la barra. dati["famiglia"]: righe;
## dati["umore"]: [consenso 0–100, parola].
func _riempi_famiglia(dati: Dictionary) -> void:
	var umore: Array = dati.get("umore", [])
	var righe: Array = dati["famiglia"].duplicate()
	if not umore.is_empty():
		righe.insert(righe.size() - 1, ["Umore", "", String(umore[2]) if umore.size() > 2 else "L'umore delle famiglie del villaggio."])
	for r in righe:
		var riga := HBoxContainer.new()
		riga.mouse_filter = Control.MOUSE_FILTER_PASS
		riga.tooltip_text = String(r[2])
		_colonna_focus.add_child(riga)
		var e := _titoletto_focus(String(r[0]).to_upper())
		e.custom_minimum_size.x = 96
		e.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		e.mouse_filter = Control.MOUSE_FILTER_PASS
		riga.add_child(e)
		if String(r[0]) == "Umore":
			var q := float(umore[0]) / 100.0
			riga.add_child(_barra_rapporti(q, 140, q < 0.4))
			var p := Label.new()
			p.text = String(umore[1])
			p.mouse_filter = Control.MOUSE_FILTER_PASS
			p.add_theme_font_size_override("font_size", 12)
			p.add_theme_color_override("font_color", PERICOLO if q < 0.4 else BIANCO)
			riga.add_child(p)
			continue
		var l := Label.new()
		l.text = String(r[1])
		l.clip_text = true
		l.custom_minimum_size.x = 268
		l.mouse_filter = Control.MOUSE_FILTER_PASS
		l.add_theme_font_size_override("font_size", 12)
		riga.add_child(l)


## Righe della scheda di un edificio: etichetta a sinistra, valore, il perché al passaggio.
func _riempi_righe(righe: Array) -> void:
	for r in righe:
		var riga := HBoxContainer.new()
		riga.mouse_filter = Control.MOUSE_FILTER_PASS
		riga.tooltip_text = String(r[2]) if r.size() > 2 else ""
		_colonna_focus.add_child(riga)
		var e := _titoletto_focus(String(r[0]).to_upper())
		e.custom_minimum_size.x = 96
		e.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		e.mouse_filter = Control.MOUSE_FILTER_PASS
		riga.add_child(e)
		var l := Label.new()
		l.text = String(r[1])
		l.clip_text = true
		l.custom_minimum_size.x = 268
		l.mouse_filter = Control.MOUSE_FILTER_PASS
		l.add_theme_font_size_override("font_size", 12)
		riga.add_child(l)


## Scelte della scheda di un edificio: tasti come le opzioni delle politiche (quella in vigore è
## invertita). scelte: [{id, testo, attiva}].
func _riempi_scelte(scelte: Array) -> void:
	var riga := HBoxContainer.new()
	riga.add_theme_constant_override("separation", 6)
	_colonna_focus.add_child(riga)
	for v in scelte:
		var b := Button.new()
		b.text = String(v["testo"])
		b.toggle_mode = true
		b.button_pressed = bool(v.get("attiva", false))
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 12)
		var st := StyleBoxFlat.new()
		st.bg_color = Color(0, 0, 0, 0)
		st.set_border_width_all(1)
		st.border_color = RIGA
		st.set_content_margin_all(6)
		b.add_theme_stylebox_override("normal", st)
		var id := String(v["id"])
		b.pressed.connect(func() -> void: scelta_focus.emit(id))
		riga.add_child(b)


## Barra sottile dello specchietto: fondo grigio, pieno bianco (rosso se è un allarme).
func _barra_rapporti(quota: float, larghezza: float, allarme: bool) -> Control:
	var box := CenterContainer.new()
	box.custom_minimum_size = Vector2(larghezza + 8, 16)
	box.mouse_filter = Control.MOUSE_FILTER_PASS
	var fondo := ColorRect.new()
	fondo.color = RIGA
	fondo.custom_minimum_size = Vector2(larghezza, 4)
	fondo.mouse_filter = Control.MOUSE_FILTER_PASS
	box.add_child(fondo)
	var pieno := ColorRect.new()
	pieno.color = PERICOLO if allarme else BIANCO
	pieno.size = Vector2(larghezza * clampf(quota, 0.0, 1.0), 4)
	pieno.mouse_filter = Control.MOUSE_FILTER_PASS
	fondo.add_child(pieno)
	return box


## Specchietto "Conseguenze": d = {titolo, guadagna, perde, territorio, costo, resta,
## irreversibile}. Vuoto: lo specchietto sparisce. Si nasconde da solo se sono aperti il focus o le
## politiche, che occupano lo stesso spazio.
func imposta_conseguenze(d: Dictionary) -> void:
	_dati_conseguenze = d
	if _pannello_conseguenze == null:
		if d.is_empty():
			return
		_crea_conseguenze()
	if d.is_empty():
		_pannello_conseguenze.visible = false
		return
	_titolo_conseguenze.text = "CONSEGUENZE · " + String(d.get("titolo", "")).to_upper()
	for v in VOCI_CONSEGUENZE:
		var l: Label = _righe_conseguenze[v[0]]
		var testo := String(d.get(v[0], ""))
		(l.get_parent() as Control).visible = testo != ""
		l.text = testo
		l.tooltip_text = testo
		l.add_theme_color_override("font_color", PERICOLO if v[0] == "costo" and d.get("irreversibile", false) else BIANCO)
	_pannello_conseguenze.visible = focus_aperto() == "" and not politiche_aperte() and not modale_aperta()
	_posiziona_conseguenze()


func conseguenze() -> Dictionary:
	return _dati_conseguenze if _pannello_conseguenze != null and _pannello_conseguenze.visible else {}


func _crea_conseguenze() -> void:
	_pannello_conseguenze = PanelContainer.new()
	_pannello_conseguenze.anchor_top = 1.0
	_pannello_conseguenze.anchor_bottom = 1.0
	_pannello_conseguenze.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_pannello_conseguenze.custom_minimum_size.x = 330
	_pannello_conseguenze.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pannello_conseguenze.visible = false
	_radice.add_child(_pannello_conseguenze)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	_pannello_conseguenze.add_child(col)
	_titolo_conseguenze = _titoletto_focus("CONSEGUENZE")
	_titolo_conseguenze.clip_text = true
	_titolo_conseguenze.custom_minimum_size.x = 298
	col.add_child(_titolo_conseguenze)
	for v in VOCI_CONSEGUENZE:
		var riga := HBoxContainer.new()
		riga.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(riga)
		var n := Label.new()
		n.text = v[1]
		n.custom_minimum_size.x = 92
		n.add_theme_font_size_override("font_size", 11)
		n.add_theme_color_override("font_color", GRIGIO)
		riga.add_child(n)
		var l := Label.new()
		l.clip_text = true
		l.custom_minimum_size.x = 206
		l.mouse_filter = Control.MOUSE_FILTER_PASS
		l.add_theme_font_size_override("font_size", 12)
		riga.add_child(l)
		_righe_conseguenze[v[0]] = l


## Appena sopra la scheda dello strumento, qualunque sia l'altezza della fascia.
func _posiziona_conseguenze() -> void:
	var sotto := maxf(_fascia.size.y, ALTEZZA_FASCIA) + 2
	_pannello_conseguenze.offset_left = _pannello_descrizione.position.x
	_pannello_conseguenze.offset_right = _pannello_descrizione.position.x + 330
	_pannello_conseguenze.offset_bottom = -sotto
	_pannello_conseguenze.offset_top = -sotto - _pannello_conseguenze.get_combined_minimum_size().y


func _titoletto_focus(testo: String) -> Label:
	var l := Label.new()
	l.text = testo
	l.add_theme_font_override("font", _carattere(true, 1.6))
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", GRIGIO)
	return l


func _testo_focus(testo: String, colore: Color, corpo: int) -> Label:
	var l := Label.new()
	l.text = testo
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 364
	l.add_theme_font_size_override("font_size", corpo)
	l.add_theme_color_override("font_color", colore)
	return l


## Piccolo grafico a linea dell'andamento (stile svizzero: una linea bianca, una base sottile).
class _GraficoFocus extends Control:
	var valori: Array = []
	var colore := Color.WHITE

	func _draw() -> void:
		var w := size.x
		var h := size.y
		draw_line(Vector2(0, h - 0.5), Vector2(w, h - 0.5), Color(1, 1, 1, 0.22), 1.0)
		if valori.size() < 2:
			return
		var lo := INF
		var hi := -INF
		for x in valori:
			lo = minf(lo, float(x))
			hi = maxf(hi, float(x))
		if hi - lo < 1e-6:
			hi = lo + 1.0
		var punti := PackedVector2Array()
		for k in valori.size():
			punti.append(Vector2(w * k / float(valori.size() - 1), h - 2.0 - (h - 6.0) * (float(valori[k]) - lo) / (hi - lo)))
		draw_polyline(punti, colore, 1.5, true)


## Lettura del terreno per lo strumento scelto: voci [nome, testo, quanto (0–1), sfavorevole]
## (al massimo 4). Vuota: la lettura sparisce.
func imposta_lettura_strumento(voci: Array) -> void:
	_lettura_strumento.visible = not voci.is_empty()
	# Con la lettura la descrizione dello strumento si accorcia, così la fascia non cambia altezza
	# (il testo intero resta nel suggerimento del tasto).
	_messaggio.max_lines_visible = 3 if _lettura_strumento.visible else -1
	for k in _voci_strumento.size():
		var f: Dictionary = _voci_strumento[k]
		(f["box"] as Control).visible = k < voci.size()
		if k >= voci.size():
			continue
		var v: Array = voci[k]
		(f["nome"] as Label).text = String(v[0]).to_upper()
		(f["valore"] as Label).text = String(v[1])
		(f["valore"] as Label).add_theme_color_override("font_color", PERICOLO if v[3] else BIANCO)
		var pieno: ColorRect = f["riempimento"]
		pieno.color = PERICOLO if v[3] else BIANCO
		pieno.size = Vector2(140.0 * clampf(float(v[2]), 0.0, 1.0), 4)


func lettura_strumento_visibile() -> bool:
	return _lettura_strumento.visible
