extends SceneTree
## Salva un'immagine della scena principale (serve uno schermo, anche virtuale).
## Uso: xvfb-run -s "-screen 0 1600x900x24" godot --path gioco --rendering-driver opengl3 -s res://test/foto.gd -- uscita.png [modo] [dimensione_vista] [rotazioni]

var _scena: Node
var _f := 0
var _uscita := "user://foto.png"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_uscita = args[0]
	_scena = load("res://scene/principale.tscn").instantiate()
	root.add_child(_scena)


func _process(_delta: float) -> bool:
	_f += 1
	if _f == 3:
		var args := OS.get_cmdline_user_args()
		if args.size() > 1:
			_scena.imposta_modo(int(args[1]))
		var cam: CameraIsometrica = _scena.cam
		if args.size() > 2:
			cam.dimensione_obiettivo = float(args[2])
			cam.dimensione = float(args[2])
		if args.size() > 3:
			for _i in int(args[3]):
				cam.ruota(1)
			cam.yaw = cam.yaw_obiettivo
		cam.aggiorna()
		var centro := Vector2(root.get_visible_rect().size) * 0.5
		_scena.aggiorna_lettura(centro + Vector2(40, 30))
	if _f == 40:
		var img := root.get_texture().get_image()
		img.save_png(_uscita)
		print("Foto salvata: ", _uscita)
		quit(0)
	return false
