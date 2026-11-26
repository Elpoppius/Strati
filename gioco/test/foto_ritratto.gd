extends SceneTree
## Ritratti ravvicinati delle persone (26/11/2026, per rifinire spalle e viso su richiesta di Fede):
## tre figure ferme in fila, girate verso la camera, nella vista più vicina.
## Uso: xvfb-run -a -s "-screen 0 1600x900x24" godot --path gioco --rendering-driver opengl3 --resolution 1600x900 -s res://test/foto_ritratto.gd -- uscita.png [uomini|donne] [dimensione_vista] [gradi_in_più] [leggero]

var _s: Node
var _f := 0


func _initialize() -> void:
	_s = load("res://scene/principale.tscn").instantiate()
	root.add_child(_s)


func _process(_d: float) -> bool:
	_f += 1
	var args := OS.get_cmdline_user_args()
	if _f == 3:
		var cam: CameraIsometrica = _s.cam
		var c := cam.bersaglio
		var gruppo := args[1] if args.size() > 1 else "uomini"
		var dim := float(args[2]) if args.size() > 2 else 2.2
		var gradi := float(args[3]) if args.size() > 3 else 0.0
		var leggero := args.size() > 4 and args[4] == "leggero"
		var destra := Vector3(cos(deg_to_rad(cam.yaw)), 0.0, -sin(deg_to_rad(cam.yaw)))
		var verso_camera := Vector3(sin(deg_to_rad(cam.yaw)), 0.0, cos(deg_to_rad(cam.yaw)))
		# Il bersaglio della camera è a terra: le figure si spostano verso la camera di quanto
		# serve perché le spalle (circa 1,4 m) cadano al centro della foto.
		c += verso_camera * 1.4 / tan(deg_to_rad(-CameraIsometrica.INCLINAZIONE))
		var nomi := ["uomo_1", "uomo_2", "uomo_3"] if gruppo == "uomini" else ["donna_1", "donna_2", "donna_3"]
		for k in nomi.size():
			var mesh := Asset.mesh_persona(nomi[k], leggero)
			var mi := MeshInstance3D.new()
			mi.mesh = mesh
			for i in mesh.get_surface_count():
				var mat := mesh.surface_get_material(i).duplicate() as ShaderMaterial
				mat.set_shader_parameter("posa", Vector4(0.0, 0.0, 0.0, 0.2 + k * 0.3))
				mi.set_surface_override_material(i, mat)
			var p := c + destra * (k - 1) * 0.62
			mi.position = Vector3(p.x, _s.terreno.quota_mondo(p.x, p.z), p.z)
			# La figura guarda verso -z: con 180 + yaw guarda la camera.
			mi.rotation_degrees.y = 180.0 + cam.yaw + gradi
			_s.add_child(mi)
		_s.griglia_attiva = false
		if _s.get("hud") != null:
			_s.hud.visible = false
		cam.dimensione = dim
		cam.dimensione_obiettivo = dim
		cam.aggiorna()
	if _f == 40:
		root.get_texture().get_image().save_png(args[0] if args.size() > 0 else "user://ritratto.png")
		print("Foto salvata")
		quit(0)
	return false
