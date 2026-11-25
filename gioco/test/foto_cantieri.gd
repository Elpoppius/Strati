extends SceneTree
## Foto di controllo dei cantieri (decisione di Fede del 25/11/2026 sera): in alto i quattro
## edifici finiti (granaio, legnaia, capanno da pesca, posta di caccia), sotto i loro scheletri in
## costruzione, su un prato sgombro accanto al sito iniziale.
## Uso: xvfb-run -a -s "-screen 0 1600x900x24" godot --path gioco --rendering-driver opengl3 --resolution 1600x900 -s res://test/foto_cantieri.gd -- uscita.png [dimensione_vista] [rotazioni]

const CARTELLA := "res://asset/villaggio"
const EDIFICI := ["granaio_su_pali", "legnaia", "capanno_pesca", "posta_caccia"]

var _s: Node
var _f := 0


func _initialize() -> void:
	_s = load("res://scene/principale.tscn").instantiate()
	root.add_child(_s)


func _posa(nome: String, x: float, z: float) -> void:
	var nodo := Asset.istanzia("%s/%s.glb" % [CARTELLA, nome])
	if nodo == null:
		push_error("Modello mancante: " + nome)
		return
	nodo.position = Vector3(x, _s.terreno.quota_mondo(x, z), z)
	_s.add_child(nodo)


func _process(_d: float) -> bool:
	_f += 1
	var args := OS.get_cmdline_user_args()
	if _f == 3:
		var cam: CameraIsometrica = _s.cam
		var c := cam.bersaglio
		var u: UsoSuolo = _s.uso
		u.costruisci(u.celle_nel_cerchio(c.x, c.z, 30.0), "capanna", false)
		for k in EDIFICI.size():
			var x := c.x + (k - 1.5) * 10.0
			_posa(EDIFICI[k], x, c.z - 6.0)
			_posa("cantiere_" + EDIFICI[k].replace("_su_pali", ""), x, c.z + 6.0)
		_s.griglia_attiva = false
		var dim := float(args[1]) if args.size() > 1 else 30.0
		cam.dimensione = dim
		cam.dimensione_obiettivo = dim
		if args.size() > 2:
			for _i in int(args[2]):
				cam.ruota(1)
			cam.yaw = cam.yaw_obiettivo
		cam.aggiorna()
	if _f == 60:
		root.get_texture().get_image().save_png(args[0] if args.size() > 0 else "user://cantieri.png")
		print("Foto salvata")
		quit(0)
	return false
