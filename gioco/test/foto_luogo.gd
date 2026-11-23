extends SceneTree
## Foto del margine di bosco, della riva del fiume, della palude o dei gessi più vicini al sito iniziale.
## Uso: xvfb-run -a -s "-screen 0 1600x900x24" godot --path gioco --rendering-driver opengl3 --resolution 1600x900 -s res://test/foto_luogo.gd -- dimensione_vista [bosco|acqua|palude|gessi|canne]
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
				var preso := false
				match _luogo:
					"bosco": preso = d.copertura[i] > 127
					"palude", "canne": preso = d.tipo[i] == MappaDati.PALUDE
					"gessi": preso = d.tipo[i] == MappaDati.GESSI
					_: preso = d.tipo[i] == MappaDati.FIUME
				if preso:
					var dd := Vector2(x - pc.x, z - pc.y).length()
					if dd < dist:
						dist = dd; migliore = Vector2i(x, z)
		var p: Vector2 = d.mondo_da_pixel(migliore)
		if _luogo == "canne":
			# Il ciuffo di canne più vicino alla palude trovata: si cerca nei blocchi attorno.
			var a: Alberi = _s.alberi
			var bc := Vector2i(int(p.x / Alberi.LATO_BLOCCO), int(p.y / Alberi.LATO_BLOCCO))
			var trovato := false
			for r in 4:
				for bz in range(bc.y - r, bc.y + r + 1):
					for bx in range(bc.x - r, bc.x + r + 1):
						if trovato or bx < 0 or bz < 0:
							continue
						var arr := a.alberi_nel_blocco(Vector2i(bx, bz))
						for i in arr.size() / Alberi.CAMPI:
							if int(arr[i * Alberi.CAMPI + 4]) >= Alberi.VARIANTI[Alberi.CANNA][0]:
								p = Vector2(arr[i * Alberi.CAMPI], arr[i * Alberi.CAMPI + 1])
								trovato = true
								break
		_s.cam.vai_a(p.x, p.y, _dim)
		_s.cam.dimensione = _dim
		_s.cam.bersaglio = Vector3(p.x, 0, p.y)
		_s.griglia_attiva = false
		_s.cam.aggiorna()
	if _f == 40:
		root.get_texture().get_image().save_png("/tmp/%s_%d.png" % [_luogo, int(_dim)])
		quit(0)
	return false
