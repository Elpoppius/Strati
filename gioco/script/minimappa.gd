class_name Minimappa
extends Control
## Minimappa in basso a destra (disposizione di Age of Empires IV, esempi di Fede del 24/11/2026):
## la mappa intera ruotata come la vista, con il riquadro di ciò che inquadra la camera. Un clic
## sposta la camera. Colori sobri: terra in grigi caldi secondo la quota, boschi più scuri,
## acqua in blu (il blu vuol dire acqua anche nell'HUD).

var dati: MappaDati
var cam: CameraIsometrica
## Punti da segnare (nel mondo, metri): per esempio il centro del villaggio.
var segni: Callable
var _immagine: ImageTexture


func collega(d: MappaDati, c: CameraIsometrica) -> void:
	dati = d
	cam = c
	_immagine = ImageTexture.create_from_image(_disegna_mappa())
	mouse_filter = Control.MOUSE_FILTER_STOP


func _disegna_mappa() -> Image:
	var n := dati.lato
	var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	for z in n:
		for x in n:
			var i := dati.indice(x, z)
			var q := clampf((dati.altezze[i] - dati.quota_min) / maxf(dati.quota_max - dati.quota_min, 1.0), 0.0, 1.0)
			var c := Color(0.62, 0.6, 0.55).lerp(Color(0.46, 0.42, 0.36), q)
			var t := dati.tipo[i]
			if dati.copertura[i] > 127:
				c = c.lerp(Color(0.27, 0.32, 0.25), 0.75)
			if t == MappaDati.PALUDE:
				c = Color(0.36, 0.45, 0.44)
			elif t == MappaDati.GESSI:
				c = Color(0.7, 0.68, 0.63)
			elif t >= MappaDati.FIUME and t <= MappaDati.TORRENTE_EST:
				c = Color("2a6db5")
			img.set_pixel(x, z, c)
	return img


## Da punto del mondo (x, z) a punto della minimappa: ruotata come la vista, centrata.
func _a_schermo(w: Vector2) -> Vector2:
	var l := dati.lato_metri()
	var k := size.x / (l * 1.414)
	var a := deg_to_rad(cam.yaw)
	var d := w - Vector2(l, l) * 0.5
	return size * 0.5 + Vector2(d.x * cos(a) - d.y * sin(a), d.x * sin(a) + d.y * cos(a)) * k


func _a_mondo(s: Vector2) -> Vector2:
	var l := dati.lato_metri()
	var k := size.x / (l * 1.414)
	var a := -deg_to_rad(cam.yaw)
	var d := (s - size * 0.5) / k
	return Vector2(l, l) * 0.5 + Vector2(d.x * cos(a) - d.y * sin(a), d.x * sin(a) + d.y * cos(a))


func _process(_d: float) -> void:
	if dati:
		queue_redraw()


func _draw() -> void:
	if dati == null:
		return
	var l := dati.lato_metri()
	var k := size.x / (l * 1.414)
	var a := deg_to_rad(cam.yaw)
	var origine := _a_schermo(Vector2.ZERO)
	var scala := l / dati.lato * k
	draw_set_transform(origine, a, Vector2(scala, scala))
	draw_texture(_immagine, Vector2.ZERO)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Riquadro della camera: la fetta di terreno inquadrata (profondità allungata dall'inclinazione).
	var c := Vector2(cam.bersaglio.x, cam.bersaglio.z)
	var assi := cam.assi_suolo()
	var destra := Vector2(assi[0].x, assi[0].z)
	var avanti := Vector2(assi[1].x, assi[1].z)
	var vp := get_viewport_rect().size
	var mezza_l := cam.dimensione * vp.x / maxf(vp.y, 1.0) * 0.5
	var mezza_p := cam.dimensione * 0.5 / 0.5
	var angoli := PackedVector2Array()
	for v in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1), Vector2(-1, -1)]:
		angoli.append(_a_schermo(c + destra * v.x * mezza_l + avanti * v.y * mezza_p))
	draw_polyline(angoli, Hud.BIANCO, 1.5)
	if segni.is_valid():
		for p in segni.call():
			var s := _a_schermo(p)
			draw_rect(Rect2(s - Vector2(3, 3), Vector2(6, 6)), Hud.BIANCO)
			draw_rect(Rect2(s - Vector2(3, 3), Vector2(6, 6)), Hud.NERO, false, 1.0)


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		_vai((ev as InputEventMouseButton).position)
		accept_event()
	elif ev is InputEventMouseMotion and (ev as InputEventMouseMotion).button_mask & MOUSE_BUTTON_MASK_LEFT:
		_vai((ev as InputEventMouseMotion).position)
		accept_event()


func _vai(s: Vector2) -> void:
	var w := _a_mondo(s)
	var l := dati.lato_metri()
	cam.vai_a(clampf(w.x, 0.0, l), clampf(w.y, 0.0, l))
