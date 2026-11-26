extends SceneTree
## Foto di controllo del pascolo (decisioni di Fede del 25/11/2026): lo stabbio con l'abbeveratoio e
## gli animali (pecore, capre, maiali, un bue) su un prato sgombro accanto al sito iniziale.
## Uso: xvfb-run -a -s "-screen 0 1600x900x24" godot --path gioco --rendering-driver opengl3 --resolution 1600x900 -s res://test/foto_animali.gd -- uscita.png [dimensione_vista] [rotazioni]

const CARTELLA := "res://asset/villaggio"

var _s: Node
var _f := 0


func _initialize() -> void:
	_s = load("res://scene/principale.tscn").instantiate()
	root.add_child(_s)


func _posa(nome: String, x: float, z: float, gradi: float) -> void:
	var nodo := Asset.istanzia("%s/%s.glb" % [CARTELLA, nome])
	if nodo == null:
		push_error("Modello mancante: " + nome)
		return
	nodo.position = Vector3(x, _s.terreno.quota_mondo(x, z), z)
	nodo.rotation_degrees.y = gradi
	_s.add_child(nodo)


func _process(_d: float) -> bool:
	_f += 1
	var args := OS.get_cmdline_user_args()
	if _f == 3:
		var cam: CameraIsometrica = _s.cam
		var c := cam.bersaglio
		var u: UsoSuolo = _s.uso
		u.costruisci(u.celle_nel_cerchio(c.x, c.z, 25.0), "capanna", false)
		_posa("stabbio", c.x - 6.0, c.z - 4.0, 0.0)
		var caso := RandomNumberGenerator.new()
		caso.seed = 7
		var elenco := ["pecora", "pecora", "pecora", "pecora", "capra", "capra", "capra", "maiale", "maiale", "bue"]
		for k in elenco.size():
			_posa("animale_" + elenco[k], c.x + caso.randf_range(-4.0, 10.0), c.z + caso.randf_range(-2.0, 9.0), caso.randf_range(0.0, 360.0))
		_s.griglia_attiva = false
		var dim := float(args[1]) if args.size() > 1 else 24.0
		cam.dimensione = dim
		cam.dimensione_obiettivo = dim
		if args.size() > 2:
			for _i in int(args[2]):
				cam.ruota(1)
			cam.yaw = cam.yaw_obiettivo
		cam.aggiorna()
	if _f == 60:
		root.get_texture().get_image().save_png(args[0] if args.size() > 0 else "user://animali.png")
		print("Foto salvata")
		quit(0)
	return false
