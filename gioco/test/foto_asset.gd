extends SceneTree
## Posa alcuni asset sul terreno vicino al terrazzo centrale e salva un'immagine reale del gioco.
## Uso: xvfb-run -a -s "-screen 0 1600x900x24" godot --path gioco --rendering-driver opengl3 --resolution 1600x900 -s res://test/foto_asset.gd -- uscita.png cartella_asset [dimensione_vista]

var _scena: Node
var _f := 0
var _uscita := "user://foto_asset.png"
var _cartella := "res://asset/prove_stile"
var _dim := 80.0

## Posizioni relative al sito (metri, x verso est, z verso sud).
const DISPOSIZIONE := {
	"casa_lunga_media": Vector3(-14, 0, 4),
	"capanna_tonda": Vector3(6, 0, 12),
	"granaio_su_pali": Vector3(4, 0, -2),
	"quercia_1": Vector3(-6, 0, -20),
	"quercia_2": Vector3(20, 0, -10),
}


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_uscita = args[0]
	if args.size() > 1:
		_cartella = args[1]
	if args.size() > 2:
		_dim = float(args[2])
	_scena = load("res://scene/principale.tscn").instantiate()
	root.add_child(_scena)


func _process(_delta: float) -> bool:
	_f += 1
	if _f == 3:
		var cam: CameraIsometrica = _scena.cam
		var centro := cam.bersaglio
		for nome in DISPOSIZIONE:
			var percorso := "%s/%s.glb" % [_cartella, nome]
			var scena := load(percorso) as PackedScene
			if scena == null:
				continue
			var nodo: Node3D = scena.instantiate()
			var p: Vector3 = centro + DISPOSIZIONE[nome]
			p.y = _scena.terreno.quota_mondo(p.x, p.z)
			nodo.position = p
			_scena.add_child(nodo)
		cam.dimensione = _dim
		cam.dimensione_obiettivo = _dim
		_scena.griglia_attiva = false
		cam.aggiorna()
	if _f == 40:
		root.get_texture().get_image().save_png(_uscita)
		print("Foto salvata: ", _uscita)
		quit(0)
	return false
