extends SceneTree
## Foto di controllo del pascolo (decisioni di Fede del 25/11/2026): lo stabbio con l'abbeveratoio e
## gli animali su un prato sgombro accanto al sito iniziale. Dal 26/11/2026 (terza versione): per
## ogni specie i tre manti in fila, il primo fermo a testa alta, il secondo che bruca, il terzo a
## metà passo; dietro qualcuno sparso. Con "leggero" come quarto argomento, il livello leggero.
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


func _animale(specie: String, manto: int, leggero: bool, posa: Vector4, x: float, z: float, gradi: float) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = Asset.mesh_animale(specie, manto, leggero)
	for i in mi.mesh.get_surface_count():
		var mat := mi.mesh.surface_get_material(i).duplicate() as ShaderMaterial
		mat.set_shader_parameter("posa", posa)
		mi.set_surface_override_material(i, mat)
	mi.position = Vector3(x, _s.terreno.quota_mondo(x, z), z)
	mi.rotation_degrees.y = gradi
	_s.add_child(mi)


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
		var leggero := args.size() > 3 and args[3] == "leggero"
		# Una specie sola, da vicino (quarto argomento: il nome della specie): i tre manti in posa
		# ferma, che bruca e a metà passo, e una pecora accanto per le proporzioni.
		if args.size() > 3 and args[3] in ["pecora", "capra", "maiale", "bue"]:
			var sp: String = args[3]
			for m in 3:
				var posa: Vector4 = [Vector4(0, 0, 0, 0.3), Vector4(0, 0, 1, 0.3), Vector4(1.2, 1, 0, 0.3)][m]
				var passo := 2.6 if sp == "bue" else 1.8
				_animale(sp, m + 1, false, posa, c.x - 2.0 + m * passo, c.z + m * passo, [45.0, 135.0, 90.0][m])
			_animale("pecora", 1, false, Vector4(0, 0, 0, 0.3), c.x - 3.5, c.z + 2.0, 45.0)
			_s.griglia_attiva = false
			var dim0 := float(args[1]) if args.size() > 1 else 6.0
			cam.vai_a(c.x - 0.5, c.z + 1.8)
			cam.dimensione = dim0
			cam.dimensione_obiettivo = dim0
			if args.size() > 2:
				for _i in int(args[2]):
					cam.ruota(1)
				cam.yaw = cam.yaw_obiettivo
			cam.aggiorna()
			return false
		# Una fila per specie, i tre manti di fianco: fermo, che bruca, a metà passo.
		var fila := ["pecora", "capra", "maiale", "bue"]
		var pose := [Vector4(0, 0, 0, 0.3), Vector4(0, 0, 1, 0.5), Vector4(1.2, 1, 0, 0.7)]
		for k in fila.size():
			for m in 3:
				var passo := 2.6 if fila[k] == "bue" else 1.6
				_animale(fila[k], m + 1, leggero, pose[m], c.x - 4.0 + m * passo * 1.3 + k * 1.2, c.z + 4.0 - k * 2.4 + m * 0.4, 100.0)
		var elenco := ["pecora", "pecora", "capra", "maiale"]
		for k in elenco.size():
			_animale(elenco[k], 1 + k % 3, leggero, Vector4(caso.randf() * TAU, caso.randf(), caso.randf(), caso.randf()), c.x + caso.randf_range(3.0, 9.0), c.z + caso.randf_range(-8.0, -3.0), caso.randf_range(0.0, 360.0))
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
