extends SceneTree
## Fotogrammi del fumo dei camini (27/11/2026): l'officina del fabbro al centro, con il suo fumo; il
## tempo dello shader avanza di `passo` secondi per fotogramma, così la sequenza è regolare anche con
## il rendering software lento. Dai fotogrammi si fa una GIF per Fede.
## Uso: xvfb-run -a -s "-screen 0 1600x900x24" godot --path gioco --rendering-driver opengl3 --resolution 1600x900 -s res://test/foto_fumo.gd -- cartella [fotogrammi] [dimensione_vista] [rotazioni] [passo]

var _s: Node
var _fumo: VistaFumo
var _f := 0
var _k := 0


func _initialize() -> void:
	_s = load("res://scene/principale.tscn").instantiate()
	root.add_child(_s)


func _process(_d: float) -> bool:
	_f += 1
	var args := OS.get_cmdline_user_args()
	var cartella: String = args[0] if args.size() > 0 else "user://fumo"
	var fotogrammi := int(args[1]) if args.size() > 1 else 24
	var passo := float(args[4]) if args.size() > 4 else 0.25
	if _f == 3:
		var cam: CameraIsometrica = _s.cam
		var c := cam.bersaglio
		var u: UsoSuolo = _s.uso
		u.costruisci(u.celle_nel_cerchio(c.x, c.z, 30.0), "capanna", false)
		var nodo := Asset.istanzia("res://asset/protourbano/officina_fabbro.glb")
		nodo.position = Vector3(c.x + 1.0, _s.terreno.quota_mondo(c.x + 1.0, c.z), c.z)
		_s.add_child(nodo)
		_fumo = VistaFumo.new()
		_s.add_child(_fumo)
		if not _fumo.aggiungi_edificio("officina", "officina_fabbro", nodo):
			push_error("L'officina non ha il camino in camini.json")
		_fumo.tempo_fisso = 0.0
		_s.griglia_attiva = false
		var dim := float(args[2]) if args.size() > 2 else 14.0
		cam.dimensione = dim
		cam.dimensione_obiettivo = dim
		if args.size() > 3:
			for _i in int(args[3]):
				cam.ruota(1)
			cam.yaw = cam.yaw_obiettivo
		# Il fumo sale: la camera guarda un po' più in alto dell'officina.
		cam.bersaglio = c + Vector3(-2.0, 3.0, 0.0)
		cam.aggiorna()
		DirAccess.make_dir_recursive_absolute(cartella)
	# Dal 60° fotogramma (scena pronta): uno scatto ogni due fotogrammi, il tempo avanza di `passo`.
	if _f >= 60 and _f % 2 == 0:
		if _k > 0:
			root.get_texture().get_image().save_png("%s/f%03d.png" % [cartella, _k - 1])
		if _k >= fotogrammi:
			print("Fotogrammi salvati: ", fotogrammi)
			quit(0)
			return false
		# Si parte a metà del ciclo, quando la colonna è già piena.
		_fumo.tempo_fisso = 40.0 + _k * passo
		_k += 1
	return false
