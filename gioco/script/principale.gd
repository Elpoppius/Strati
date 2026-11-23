extends Node3D
## Scena principale della base: terreno della mappa pedecollinare, camera isometrica,
## mappe tematiche, griglia dei lotti e lettura del lotto sotto il puntatore.

const PERCORSO_MAPPA := "res://mappe/pedecollinare/mappa.res"
const ESAGERAZIONE := 1.5
const LATO_LOTTO := 20.0
const NOMI_MODI := ["Terreno", "Acqua", "Fertilità", "Rischio piena"]
const SITO_INIZIALE := 1

## Sole: altezza sull'orizzonte e angolo rispetto alla direzione in cui guarda la camera (gradi).
## 270 = sole da sinistra, ombre verso destra sullo schermo (scelta di Fede); l'altezza bassa le tiene lunghe.
const ALTEZZA_SOLE := 42.0
const AZIMUT_SOLE := 270.0

var dati: MappaDati
var terreno: Terreno
var cam: CameraIsometrica
var sole: DirectionalLight3D
var modo := 0
var griglia_attiva := true
var lotto_corrente := Vector2i(-1, -1)
var punto_corrente: Variant = null

var _lettura: Label
var _pulsanti_modo: Array[Button] = []
var _casella_griglia: CheckBox
var _trascinando := false


func _ready() -> void:
	dati = load(PERCORSO_MAPPA) as MappaDati
	if dati == null:
		push_error("Mappa non trovata: " + PERCORSO_MAPPA)
		return
	_crea_ambiente()
	terreno = Terreno.new()
	terreno.name = "Terreno"
	add_child(terreno)
	terreno.costruisci(dati, ESAGERAZIONE)
	terreno.materiale.set_shader_parameter("lato_lotto", LATO_LOTTO)
	_crea_segni_siti()
	cam = CameraIsometrica.new()
	cam.name = "Camera"
	add_child(cam)
	cam.limiti = Rect2(0.0, 0.0, dati.lato_metri(), dati.lato_metri())
	cam.funzione_quota = terreno.quota_mondo
	torna_al_sito()
	_crea_interfaccia()
	imposta_modo(0)


func _crea_ambiente() -> void:
	sole = DirectionalLight3D.new()
	sole.name = "Sole"
	sole.rotation_degrees = Vector3(-ALTEZZA_SOLE, 45.0 + AZIMUT_SOLE, 0.0)
	sole.light_energy = 0.95
	sole.light_color = Color(1.0, 0.95, 0.86)  # sole caldo
	sole.shadow_enabled = true
	# Una sola mappa d'ombra sulla fetta visibile (vedi CameraIsometrica.aggiorna).
	sole.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sole.directional_shadow_max_distance = 12000.0
	sole.directional_shadow_fade_start = 1.0
	add_child(sole)
	var amb := Environment.new()
	amb.background_mode = Environment.BG_COLOR
	amb.background_color = Color8(231, 234, 226)
	amb.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	# Luce del cielo un po' fredda: le ombre restano leggibili ma non nere, e contrastano col sole caldo.
	amb.ambient_light_color = Color(0.82, 0.88, 1.0)
	amb.ambient_light_energy = 0.45
	var mondo := WorldEnvironment.new()
	mondo.environment = amb
	add_child(mondo)


func _crea_segni_siti() -> void:
	for s in dati.siti:
		var p: Vector2 = dati.mondo_da_pixel(s["px"])
		var etichetta := Label3D.new()
		etichetta.text = "%d · %s" % [s["n"], s["nome"]]
		etichetta.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		etichetta.fixed_size = true
		etichetta.pixel_size = 0.0012
		etichetta.font_size = 22
		etichetta.outline_size = 8
		etichetta.modulate = Color8(30, 41, 39)
		etichetta.outline_modulate = Color8(243, 244, 239)
		etichetta.no_depth_test = true
		etichetta.position = Vector3(p.x, dati.quota(p.x, p.y) * ESAGERAZIONE + 30.0, p.y)
		add_child(etichetta)


func _crea_interfaccia() -> void:
	var livello := CanvasLayer.new()
	add_child(livello)
	var pannello := PanelContainer.new()
	pannello.position = Vector2(16, 16)
	livello.add_child(pannello)
	var colonna := VBoxContainer.new()
	colonna.add_theme_constant_override("separation", 8)
	pannello.add_child(colonna)
	var titolo := Label.new()
	titolo.text = "Strati · mappa %s" % dati.nome.to_lower()
	titolo.add_theme_font_size_override("font_size", 20)
	colonna.add_child(titolo)
	var riga := HBoxContainer.new()
	colonna.add_child(riga)
	for i in NOMI_MODI.size():
		var b := Button.new()
		b.text = NOMI_MODI[i]
		b.toggle_mode = true
		b.pressed.connect(imposta_modo.bind(i))
		riga.add_child(b)
		_pulsanti_modo.append(b)
	_casella_griglia = CheckBox.new()
	_casella_griglia.text = "Griglia dei lotti (20 m)"
	_casella_griglia.button_pressed = griglia_attiva
	_casella_griglia.toggled.connect(func(v: bool) -> void: griglia_attiva = v)
	colonna.add_child(_casella_griglia)
	var aiuto := Label.new()
	aiuto.text = "Tasto destro o WASD: sposta · Rotella: zoom · Q / E: ruota di 90°\nG: griglia · 1–4: mappe · Home: torna al terrazzo centrale"
	aiuto.add_theme_font_size_override("font_size", 13)
	colonna.add_child(aiuto)
	_lettura = Label.new()
	_lettura.add_theme_font_size_override("font_size", 15)
	_lettura.anchor_top = 1.0
	_lettura.anchor_bottom = 1.0
	_lettura.offset_left = 16
	_lettura.offset_top = -40
	_lettura.offset_bottom = -12
	_lettura.add_theme_color_override("font_color", Color8(30, 41, 39))
	_lettura.add_theme_color_override("font_outline_color", Color8(243, 244, 239))
	_lettura.add_theme_constant_override("outline_size", 6)
	_lettura.text = "Passa sul terreno per leggere il lotto."
	livello.add_child(_lettura)


func imposta_modo(i: int) -> void:
	modo = i
	terreno.materiale.set_shader_parameter("modo", i)
	for k in _pulsanti_modo.size():
		_pulsanti_modo[k].button_pressed = (k == i)


func torna_al_sito() -> void:
	for s in dati.siti:
		if s["n"] == SITO_INIZIALE:
			var p: Vector2 = dati.mondo_da_pixel(s["px"])
			cam.vai_a(p.x, p.y, 1500.0)


func _process(_delta: float) -> void:
	if terreno == null:
		return
	# La griglia compare quando la vista è abbastanza vicina da distinguere i lotti.
	var alfa := 0.0
	if griglia_attiva:
		alfa = clampf(remap(cam.dimensione, 900.0, 400.0, 0.0, 0.45), 0.0, 0.45)
	terreno.materiale.set_shader_parameter("alfa_griglia", alfa)
	if sole and cam.camera:
		sole.directional_shadow_max_distance = cam.camera.far
		# Il sole gira con la camera: illumina gli oggetti di lato e da dietro, così le ombre
		# cadono verso chi guarda e si vedono a ogni rotazione (con il sole alle spalle
		# della camera restavano nascoste dietro gli oggetti e tutto sembrava piatto).
		sole.rotation_degrees = Vector3(-ALTEZZA_SOLE, cam.yaw + AZIMUT_SOLE, 0.0)


func _unhandled_input(ev: InputEvent) -> void:
	if terreno == null:
		return
	if ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			cam.zoom(1.0 / 1.18)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			cam.zoom(1.18)
		elif mb.button_index == MOUSE_BUTTON_RIGHT or mb.button_index == MOUSE_BUTTON_MIDDLE:
			_trascinando = mb.pressed
	elif ev is InputEventMouseMotion:
		var mm := ev as InputEventMouseMotion
		if _trascinando:
			cam.trascina(mm.relative, get_viewport().get_visible_rect().size.y)
		aggiorna_lettura(mm.position)
	elif ev is InputEventKey and ev.pressed and not ev.echo:
		match (ev as InputEventKey).keycode:
			KEY_Q:
				cam.ruota(-1)
			KEY_E:
				cam.ruota(1)
			KEY_G:
				griglia_attiva = not griglia_attiva
				_casella_griglia.button_pressed = griglia_attiva
			KEY_1, KEY_2, KEY_3, KEY_4:
				imposta_modo((ev as InputEventKey).keycode - KEY_1)
			KEY_HOME:
				torna_al_sito()


## Legge il terreno sotto un punto dello schermo e aggiorna l'evidenziazione del lotto.
func aggiorna_lettura(pos_schermo: Vector2) -> void:
	var origine := cam.camera.project_ray_origin(pos_schermo)
	var direzione := cam.camera.project_ray_normal(pos_schermo)
	punto_corrente = terreno.interseca_raggio(origine, direzione)
	if punto_corrente == null:
		lotto_corrente = Vector2i(-1, -1)
		terreno.materiale.set_shader_parameter("lotto_evidenziato", Vector2(-1, -1))
		_lettura.text = "Fuori dalla mappa."
		return
	var p: Vector3 = punto_corrente
	lotto_corrente = Vector2i(floori(p.x / LATO_LOTTO), floori(p.z / LATO_LOTTO))
	terreno.materiale.set_shader_parameter("lotto_evidenziato", Vector2(lotto_corrente))
	_lettura.text = testo_lettura(p.x, p.z)


func testo_lettura(x: float, z: float) -> String:
	var c := dati.campione(x, z)
	var lotto := Vector2i(floori(x / LATO_LOTTO), floori(z / LATO_LOTTO))
	var parti := ["Lotto %d·%d" % [lotto.x, lotto.y]]
	if c["edificabile"]:
		parti.append(c["zona"] if c["tipo"] != MappaDati.GESSI else "Gessi")
	else:
		parti.append(c["nome_tipo"])
	parti.append("quota %d m" % roundi(c["quota"]))
	if c["edificabile"]:
		parti.append("fertilità %s" % String.num(c["fertilita"], 2).replace(".", ","))
		var r: float = c["piena"]
		parti.append("rischio piena %s" % ("alto" if r > 0.5 else "medio" if r > 0.25 else "basso" if r > 0.0 else "nullo"))
		var a: float = c["acqua"]
		var s: float = c["acqua_stagionale"]
		parti.append("acqua affidabile vicina" if a > 0.6 else "acqua affidabile a distanza" if a > 0.2 else "solo acqua stagionale" if s > 0.6 else "acqua lontana")
		if c["bosco"]:
			parti.append("bosco")
	return " · ".join(parti)
