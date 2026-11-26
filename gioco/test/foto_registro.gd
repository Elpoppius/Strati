extends SceneTree
## Foto di controllo della finestra Debug del registro tecnico (F3), con un segnalibro (F9).
## Il registro va in user://registro (nelle foto il gioco non lo apre da solo: qui si apre a mano).
## Uso: xvfb-run -a -s "-screen 0 1600x900x24" godot --path gioco --rendering-driver opengl3 --resolution 1600x900 -s res://test/foto_registro.gd -- uscita.png

var _s: Node
var _r: Registro
var _f := 0


func _initialize() -> void:
	_s = load("res://scene/principale.tscn").instantiate()
	root.add_child(_s)


func _process(_d: float) -> bool:
	_f += 1
	var args := OS.get_cmdline_user_args()
	if _f == 3:
		_r = Registro.new()
		_s.add_child(_r)
		_r.avvia(_s)
		_r.spunta(Registro.PROVE[0], true)
		_r.spunta(Registro.PROVE[4], true)
		_r.apri_finestra(true)
	if _f == 30:
		var foto := _r.segnalibro()
		print("Segnalibro: ", foto)
	if _f == 40:
		root.get_texture().get_image().save_png(args[0] if args.size() > 0 else "user://registro.png")
		_r.chiudi()
		print(FileAccess.get_file_as_string(_r.percorso))
		print("Foto salvata")
		quit(0)
	return false
