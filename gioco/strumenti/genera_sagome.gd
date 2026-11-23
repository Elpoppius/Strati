extends SceneTree
## Genera le sagome degli alberi per la vista lontana: ogni modello completo viene fotografato
## in Godot con la stessa inclinazione della camera del gioco (30°) e lo stesso sole da sinistra,
## su sfondo trasparente. Le immagini finiscono in un'unica tavola (asset/alberi/sagome.png) e le
## misure in asset/alberi/sagome_dati.gd, letti da VistaAlberi e dallo shader sagome_alberi.
## Serve uno schermo (anche virtuale):
## xvfb-run -a -s "-screen 0 1600x900x24" godot --path gioco --rendering-driver opengl3 -s res://strumenti/genera_sagome.gd

const LATO_X := 192
const LATO_Y := 256
## Si fotografa al doppio della risoluzione e poi si riduce: bordi più morbidi.
const SOVRA := 2
const INCLINAZIONE := -30.0
const YAW := 45.0

var _vp: SubViewport
var _cam: Camera3D
var _nodo: Node3D
var _i := -1
var _f := 0
var _atlante: Image
var _quad := []
var _uv := []


func _initialize() -> void:
	_vp = SubViewport.new()
	_vp.size = Vector2i(LATO_X * SOVRA, LATO_Y * SOVRA)
	_vp.transparent_bg = true
	_vp.own_world_3d = true
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_vp)
	# Luce e ambiente come in principale.gd: sole caldo da sinistra a 42°, cielo un po' freddo.
	var sole := DirectionalLight3D.new()
	sole.rotation_degrees = Vector3(-42.0, YAW + 270.0, 0.0)
	sole.light_energy = 0.95
	sole.light_color = Color(1.0, 0.95, 0.86)
	_vp.add_child(sole)
	var amb := Environment.new()
	amb.background_mode = Environment.BG_CLEAR_COLOR
	amb.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	amb.ambient_light_color = Color(0.82, 0.88, 1.0)
	amb.ambient_light_energy = 0.45
	var mondo := WorldEnvironment.new()
	mondo.environment = amb
	_vp.add_child(mondo)
	_cam = Camera3D.new()
	_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	_cam.near = 1.0
	_cam.far = 400.0
	_vp.add_child(_cam)
	_cam.make_current()
	_atlante = Image.create(LATO_X * Alberi.MODELLI.size(), LATO_Y, false, Image.FORMAT_RGBA8)
	_prossimo()


func _prossimo() -> void:
	if _nodo:
		_nodo.queue_free()
	_i += 1
	_f = 0
	if _i >= Alberi.MODELLI.size():
		return
	_nodo = Asset.istanzia("res://asset/alberi/%s.glb" % Alberi.MODELLI[_i])
	_vp.add_child(_nodo)
	# Inquadratura: proietta gli angoli dell'ingombro sugli assi della camera.
	var b := Basis.from_euler(Vector3(deg_to_rad(INCLINAZIONE), deg_to_rad(YAW), 0.0))
	var aabb := AABB()
	var prima := true
	for m in _nodo.find_children("*", "MeshInstance3D", true, false):
		var a: AABB = (m as MeshInstance3D).get_aabb()
		aabb = a if prima else aabb.merge(a)
		prima = false
	var u0 := 1e9
	var u1 := -1e9
	var v0 := 1e9
	var v1 := -1e9
	for k in 8:
		var p := aabb.get_endpoint(k)
		u0 = minf(u0, p.dot(b.x))
		u1 = maxf(u1, p.dot(b.x))
		v0 = minf(v0, p.dot(b.y))
		v1 = maxf(v1, p.dot(b.y))
	var aspetto := float(LATO_X) / LATO_Y
	var alto := maxf(v1 - v0, (u1 - u0) / aspetto) * 1.04
	var uc := (u0 + u1) * 0.5
	var vc := (v0 + v1) * 0.5
	_cam.size = alto
	_cam.transform = Transform3D(b, b.x * uc + b.y * vc + b.z * 150.0)
	var largo := alto * aspetto
	# Rettangolo della sagoma in metri, rispetto alla base dell'albero, sugli assi della camera.
	_quad.append([uc - largo * 0.5, uc + largo * 0.5, vc - alto * 0.5, vc + alto * 0.5])
	var n := float(Alberi.MODELLI.size())
	_uv.append([_i / n, 0.0, (_i + 1) / n, 1.0])


func _process(_d: float) -> bool:
	if _i >= Alberi.MODELLI.size():
		_salva()
		return true
	_f += 1
	if _f == 6:
		var img := _vp.get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)
		img.resize(LATO_X, LATO_Y, Image.INTERPOLATE_LANCZOS)
		_atlante.blit_rect(img, Rect2i(0, 0, LATO_X, LATO_Y), Vector2i(_i * LATO_X, 0))
		print("sagoma: ", Alberi.MODELLI[_i])
		_prossimo()
	return false


func _salva() -> void:
	_atlante.save_png("res://asset/alberi/sagome.png")
	var testo := "class_name SagomeDati\n## Generato da strumenti/genera_sagome.gd: non modificare a mano.\n"
	testo += "## Per ogni modello di Alberi.MODELLI: rettangolo della sagoma in metri rispetto alla base\n"
	testo += "## (sinistra, destra, basso, alto sugli assi della camera) e rettangolo nella tavola (u0, v0, u1, v1).\n\n"
	testo += "const QUAD := %s\nconst UV := %s\n" % [str(_quad), str(_uv)]
	var f := FileAccess.open("res://asset/alberi/sagome_dati.gd", FileAccess.WRITE)
	f.store_string(testo)
	f.close()
	print("Sagome salvate: asset/alberi/sagome.png, asset/alberi/sagome_dati.gd")
	quit(0)
