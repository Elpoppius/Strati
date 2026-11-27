extends SceneTree
## Con "varianti" come quarto argomento: in alto le cinque case di base, sotto le loro varianti
## (todo voce 9, 26/11/2026).
## Foto di controllo dei cantieri (decisione di Fede del 25/11/2026 sera): in alto i sei
## edifici finiti (granaio, legnaia, capanno da pesca, posta di caccia, luogo sacro, torre di avvistamento), sotto i loro scheletri in
## costruzione, su un prato sgombro accanto al sito iniziale.
## Uso: xvfb-run -a -s "-screen 0 1600x900x24" godot --path gioco --rendering-driver opengl3 --resolution 1600x900 -s res://test/foto_cantieri.gd -- uscita.png [dimensione_vista] [rotazioni]

const CARTELLA := "res://asset/villaggio"
const EDIFICI := ["granaio_su_pali", "legnaia", "capanno_pesca", "posta_caccia", "luogo_sacro", "torre_avvistamento"]

var _s: Node
var _f := 0


func _initialize() -> void:
	_s = load("res://scene/principale.tscn").instantiate()
	root.add_child(_s)


func _posa(nome: String, x: float, z: float, cartella := CARTELLA, gradi := 0.0) -> void:
	var nodo := Asset.istanzia("%s/%s.glb" % [cartella, nome])
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
		u.costruisci(u.celle_nel_cerchio(c.x, c.z, 30.0), "capanna", false)
		if args.size() > 3 and args[3] == "protourbano":
			# Epoca 2 (27/11/2026): le case su impalcato, la casa del capo, il recinto con la porta, il
			# fabbro; accanto, per confronto, una casa lunga del villaggio.
			var p := "res://asset/protourbano"
			u.costruisci(u.celle_nel_cerchio(c.x, c.z, 80.0), "capanna", false)
			_posa("recinto_tratto", c.x - 20.0, c.z - 22.0, p)
			_posa("recinto_porta", c.x - 10.0, c.z - 22.0, p)
			_posa("recinto_tratto", c.x, c.z - 22.0, p)
			_posa("recinto_tratto", c.x + 10.0, c.z - 22.0, p)
			_posa("casa_impalcato_piccola", c.x - 22.0, c.z - 4.0, p, 90.0)
			_posa("casa_impalcato_media", c.x - 8.0, c.z - 4.0, p, 90.0)
			_posa("officina_fabbro", c.x + 8.0, c.z - 6.0, p)
			_posa("casa_del_capo", c.x - 6.0, c.z + 18.0, p)
			_posa("casa_lunga_media", c.x + 18.0, c.z + 16.0)
		elif args.size() > 3 and args[3] == "fabbro":
			# Officina del fabbro finita e in cantiere, una accanto all'altra.
			var p := "res://asset/protourbano"
			u.costruisci(u.celle_nel_cerchio(c.x, c.z, 50.0), "capanna", false)
			_posa("officina_fabbro", c.x - 6.0, c.z, p)
			_posa("cantiere_officina_fabbro", c.x + 6.0, c.z, p)
		elif args.size() > 3 and args[3] == "varianti":
			u.costruisci(u.celle_nel_cerchio(c.x, c.z, 70.0), "capanna", false)
			var case := ["capanna_tonda_piccola", "capanna_tonda", "casa_lunga_piccola", "casa_lunga_media", "casa_lunga_grande"]
			for k in case.size():
				var x := c.x + (k - 2.0) * 22.0
				_posa(case[k], x, c.z - 9.0)
				_posa(case[k] + "_b", x, c.z + 9.0)
		else:
			for k in EDIFICI.size():
				var x := c.x + (k - 2.5) * 11.0
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
