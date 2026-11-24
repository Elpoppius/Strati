extends SceneTree
## Foto di controllo del lotto del villaggio (gioco/asset/villaggio): un piccolo villaggio
## composto a mano sul terrazzo centrale, con la palizzata, le case, il luogo sacro e i campi.
## Serve a vedere gli asset nel gioco, non è la crescita spontanea del villaggio (che verrà con
## il Prototipo 0 in Godot).
## Uso: xvfb-run -a -s "-screen 0 1600x900x24" godot --path gioco --rendering-driver opengl3 --resolution 1600x900 -s res://test/foto_villaggio.gd -- uscita.png [dimensione_vista] [rotazioni]

const CARTELLA := "res://asset/villaggio"
const RAGGIO_PALIZZATA := 42.0

## [modello, x, z (metri dal centro), rotazione in gradi]
const POSE := [
	["casa_lunga_grande", -14.0, -8.0, 20.0], ["casa_lunga_media", 10.0, -18.0, -10.0],
	["casa_lunga_piccola", 18.0, 6.0, 75.0], ["casa_lunga_media", -22.0, 16.0, 100.0],
	["capanna_tonda", 2.0, 18.0, 0.0], ["capanna_tonda_piccola", -4.0, 30.0, 40.0],
	["granaio_su_pali", 6.0, -2.0, 0.0], ["granaio_su_pali", -4.0, 6.0, 15.0],
	["fossa_silo", 12.0, -4.0, 0.0], ["fossa_silo", 0.0, 2.0, 0.0],
	["focolare", -2.0, -2.0, 0.0], ["catasta_legna", 24.0, -6.0, 60.0],
	["luogo_sacro", 26.0, 22.0, 0.0], ["recinto_animali", -28.0, -24.0, 30.0],
	["roccia_1", 34.0, -16.0, 0.0], ["roccia_3", 31.0, -18.0, 50.0], ["roccia_2", -58.0, 30.0, 10.0],
]

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
		# Terra battuta dentro la palizzata, campi fuori: gli alberi spariscono da soli.
		u.edifica(u.celle_nel_cerchio(c.x, c.z, RAGGIO_PALIZZATA + 4.0), false)
		for k in 4:
			var a := 0.4 + k * 0.5
			u.coltiva(u.celle_nel_cerchio(c.x + cos(a) * 80.0, c.z + sin(a) * 80.0, 24.0))
		for p in POSE:
			_posa(p[0], c.x + p[1], c.z + p[2], p[3])
		# Palizzata: tratti da 4 m tangenti al cerchio, con il varco verso sud.
		var n := int(TAU * RAGGIO_PALIZZATA / 4.0)
		for k in n:
			var a := TAU * k / n
			var x := c.x + cos(a) * RAGGIO_PALIZZATA
			var z := c.z + sin(a) * RAGGIO_PALIZZATA
			var nome := "palizzata_varco" if k == n / 4 else "palizzata_tratto"
			if k == n / 4 - 1 or k == n / 4 + 1:
				continue
			_posa(nome, x, z, -rad_to_deg(a) + 90.0)
		_s.griglia_attiva = false
		var dim := float(args[1]) if args.size() > 1 else 110.0
		cam.dimensione = dim
		cam.dimensione_obiettivo = dim
		if args.size() > 2:
			for _i in int(args[2]):
				cam.ruota(1)
			cam.yaw = cam.yaw_obiettivo
		cam.aggiorna()
	if _f == 60:
		root.get_texture().get_image().save_png(args[0] if args.size() > 0 else "user://villaggio.png")
		print("Foto salvata")
		quit(0)
	return false
