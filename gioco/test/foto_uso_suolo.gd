extends SceneTree
## Foto di controllo dell'uso del suolo: taglio, campo, capanna, superficie sigillata e un'area
## in ricrescita da 25 anni, in un bosco della mappa pedecollinare.
## Uso: xvfb-run -a -s "-screen 0 1600x900x24" godot --path gioco --rendering-driver opengl3 --resolution 1600x900 -s res://test/foto_uso_suolo.gd -- /tmp/foto.png 450 60
## (argomenti: uscita, dimensione della vista, fotogrammi da attendere)
var _s: Node
var _f := 0
func _initialize() -> void:
	_s = load("res://scene/principale.tscn").instantiate()
	root.add_child(_s)
func _process(_d: float) -> bool:
	_f += 1
	var u: UsoSuolo = _s.uso
	var p := Vector2(3880, 3298)
	if _f == 3:
		_s.griglia_attiva = false
		u.abbatti(u.celle_nel_cerchio(p.x, p.y, 120.0))
		u.coltiva(u.celle_nel_cerchio(p.x + 60, p.y - 60, 45.0))
		u.costruisci(u.celle_nel_cerchio(p.x - 70, p.y + 40, 25.0), "casa_lunga")
		u.costruisci(u.celle_nel_cerchio(p.x + 160, p.y + 100, 40.0), "strada_asfaltata")
		u.abbatti(u.celle_nel_cerchio(p.x - 200, p.y - 150, 70.0))
		u.avanza_anni(25)
		u.abbatti(u.celle_nel_cerchio(p.x, p.y, 120.0))
		u.coltiva(u.celle_nel_cerchio(p.x + 60, p.y - 60, 45.0))
		u.costruisci(u.celle_nel_cerchio(p.x - 70, p.y + 40, 25.0), "casa_lunga")
		var cam: CameraIsometrica = _s.cam
		cam.vai_a(p.x - 40, p.y - 20, float(OS.get_cmdline_user_args()[1]))
	if _f == 3 + int(OS.get_cmdline_user_args()[2]):
		root.get_texture().get_image().save_png(OS.get_cmdline_user_args()[0])
		quit(0)
	return false
