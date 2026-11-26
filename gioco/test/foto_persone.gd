extends SceneTree
## Foto di controllo della popolazione visibile (26/11/2026, voce 7 del todo): le sei persone in fila
## nelle pose principali (cammina con la zappa, zappa, taglia con l'ascia, porta il cesto, parla,
## raccoglie) e dietro un cacciatore con la lancia e un pastore con il bastone.
## Uso: xvfb-run -a -s "-screen 0 1600x900x24" godot --path gioco --rendering-driver opengl3 --resolution 1600x900 -s res://test/foto_persone.gd -- uscita.png [dimensione_vista] [rotazioni] [leggero]

var _s: Node
var _f := 0


func _initialize() -> void:
	_s = load("res://scene/principale.tscn").instantiate()
	root.add_child(_s)


## Una persona in posa: stato come nei dati della MultiMesh (fase, modo + andatura / 2,
## lavoro + (attrezzo + 1) / 10, seme).
func _persona(nome: String, attrezzo: String, posa: Vector4, leggero: bool, x: float, z: float, gradi: float) -> void:
	var donna := nome.begins_with("donna")
	var mesh := Asset.mesh_persona(nome, leggero)
	var pezzi: Array[Mesh] = [mesh]
	if attrezzo != "":
		pezzi.append(Asset.mesh_attrezzo(attrezzo, donna))
	for m in pezzi:
		var mi := MeshInstance3D.new()
		mi.mesh = m
		for i in m.get_surface_count():
			var mat := m.surface_get_material(i).duplicate() as ShaderMaterial
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
		var leggero := args.size() > 3 and args[3] == "leggero"
		var t := func(lavoro: int, att: String) -> float: return lavoro + (Asset.ATTREZZI.find(att) + 1) / 10.0 if att != "" else float(lavoro)
		var fila := [
			["uomo_1", "zappa", Vector4(1.2, 1.5, t.call(0, "zappa"), 0.11)],
			["uomo_2", "zappa", Vector4(0.0, 2.0, t.call(0, "zappa"), 0.37)],
			["uomo_3", "ascia", Vector4(0.0, 2.0, t.call(1, "ascia"), 0.62)],
			["donna_1", "cesto", Vector4(0.0, 0.0, t.call(3, "cesto"), 0.21)],
			["donna_2", "", Vector4(0.0, 3.0, 0.0, 0.83)],
			["donna_3", "", Vector4(0.0, 2.0, 3.0, 0.48)],
		]
		for k in fila.size():
			_persona(fila[k][0], fila[k][1], fila[k][2], leggero, c.x - 4.5 + k * 1.8, c.z + 1.0 - k * 0.3, 160.0)
		_persona("uomo_2", "lancia", Vector4(0.0, 2.0, t.call(2, "lancia"), 0.55), leggero, c.x - 2.0, c.z - 2.5, 200.0)
		_persona("donna_1", "bastone", Vector4(0.0, 2.0, t.call(5, "bastone"), 0.74), leggero, c.x + 2.0, c.z - 2.8, 140.0)
		_persona("uomo_1", "", Vector4(2.8, 1.5, 0.0, 0.93), leggero, c.x + 4.5, c.z - 2.0, 250.0)
		_s.griglia_attiva = false
		var dim := float(args[1]) if args.size() > 1 else 9.0
		cam.dimensione = dim
		cam.dimensione_obiettivo = dim
		if args.size() > 2:
			for _i in int(args[2]):
				cam.ruota(1)
			cam.yaw = cam.yaw_obiettivo
		cam.aggiorna()
	if _f == 60:
		root.get_texture().get_image().save_png(args[0] if args.size() > 0 else "user://persone.png")
		print("Foto salvata")
		quit(0)
	return false
