extends SceneTree
## Foto del margine di bosco o della riva del fiume più vicini al sito iniziale.
## Uso: xvfb-run -a -s "-screen 0 1600x900x24" godot --path gioco --rendering-driver opengl3 --resolution 1600x900 -s res://test/foto_luogo.gd -- dimensione_vista [bosco|acqua]
## Salva /tmp/<luogo>_<dimensione>.png
var _s: Node
var _f := 0
var _dim := 150.0
var _luogo := "bosco"
func _initialize() -> void:
	_dim = float(OS.get_cmdline_user_args()[0])
	if OS.get_cmdline_user_args().size() > 1:
		_luogo = OS.get_cmdline_user_args()[1]
	_s = load("res://scene/principale.tscn").instantiate()
	root.add_child(_s)
func _process(_d: float) -> bool:
	_f += 1
	if _f == 3:
		var d: MappaDati = _s.dati
		var c: Vector3 = _s.cam.bersaglio
		var pc: Vector2i = d.pixel_da_mondo(c.x, c.z)
		var migliore := Vector2i(-1, -1)
		var dist := 1e9
		for z in d.lato:
			for x in d.lato:
				var i := d.indice(x, z)
				var preso := d.copertura[i] > 127 if _luogo == "bosco" else d.tipo[i] == MappaDati.FIUME
				if preso:
					var dd := Vector2(x - pc.x, z - pc.y).length()
					if dd < dist:
						dist = dd; migliore = Vector2i(x, z)
		var p: Vector2 = d.mondo_da_pixel(migliore)
		_s.cam.vai_a(p.x, p.y, _dim)
		_s.cam.dimensione = _dim
		_s.cam.bersaglio = Vector3(p.x, 0, p.y)
		_s.griglia_attiva = false
		_s.cam.aggiorna()
	if _f == 40:
		root.get_texture().get_image().save_png("/tmp/%s_%d.png" % [_luogo, int(_dim)])
		quit(0)
	return false
