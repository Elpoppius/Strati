extends SceneTree
## Foto di controllo dell'HUD: mappa tematica scelta, uno strumento attivo con il suo cerchio.
## Uso: xvfb-run -a -s "-screen 0 1600x900x24" godot --path gioco --rendering-driver opengl3 --resolution 1600x900 -s res://test/foto_hud.gd -- uscita.png [modo] [dimensione_vista] [strumento]

var _s: Node
var _f := 0


func _initialize() -> void:
	_s = load("res://scene/principale.tscn").instantiate()
	root.add_child(_s)


func _process(_d: float) -> bool:
	_f += 1
	var args := OS.get_cmdline_user_args()
	if _f == 3:
		_s.imposta_modo(int(args[1]) if args.size() > 1 else 0)
		var cam: CameraIsometrica = _s.cam
		var dim := float(args[2]) if args.size() > 2 else 1500.0
		cam.dimensione = dim
		cam.dimensione_obiettivo = dim
		cam.aggiorna()
		if args.size() > 3:
			_s.hud.seleziona_comando(args[3])
		var centro := Vector2(root.get_visible_rect().size) * 0.5
		_s.aggiorna_lettura(centro + Vector2(60, 40))
	if _f == 40:
		root.get_texture().get_image().save_png(args[0] if args.size() > 0 else "user://hud.png")
		print("Foto salvata")
		quit(0)
	return false
