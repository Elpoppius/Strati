extends SceneTree
## Foto di controllo del capanno da pesca dove starebbe nel gioco: sulla riva del fiume più
## vicina al sito iniziale, a pochi metri dall'acqua, con il lato della rastrelliera e della
## piroga (asse +y del modello in Blender, -z in Godot) rivolto verso l'acqua.
## Uso: xvfb-run -a -s "-screen 0 1600x900x24" godot --path gioco --rendering-driver opengl3 --resolution 1600x900 -s res://test/foto_capanno.gd -- uscita.png [dimensione_vista] [rotazioni] [distanza_dalla_riva_m]

const MODELLO := "res://asset/villaggio/capanno_pesca.glb"

var _s: Node
var _f := 0


func _initialize() -> void:
	_s = load("res://scene/principale.tscn").instantiate()
	root.add_child(_s)


## Punto di terra asciutta, a `riva` metri dall'acqua, più vicino a `da`, su un terreno poco
## inclinato e fuori dalla palude.
func _punto_di_riva(da: Vector2, riva: float) -> Vector2:
	var a: Alberi = _s.alberi
	var d: MappaDati = _s.dati
	var migliore := Vector2.INF
	var costo := INF
	for gz in range(-150, 151):
		for gx in range(-150, 151):
			var p := da + Vector2(gx, gz) * 2.0
			var w := a.distanza_acqua(p.x, p.y)
			if absf(w - riva) > 1.5:
				continue
			var i := d.indice(d.pixel_da_mondo(p.x, p.y).x, d.pixel_da_mondo(p.x, p.y).y)
			if d.tipo[i] == MappaDati.PALUDE:
				continue
			var pend: float = absf(_s.terreno.quota_mondo(p.x + 6.0, p.y) - _s.terreno.quota_mondo(p.x - 6.0, p.y)) \
				+ absf(_s.terreno.quota_mondo(p.x, p.y + 6.0) - _s.terreno.quota_mondo(p.x, p.y - 6.0))
			var c := p.distance_to(da) + pend * 40.0
			if c < costo:
				costo = c
				migliore = p
	return migliore


## Direzione verso l'acqua: contro il gradiente della distanza dalla riva.
func _verso_acqua(p: Vector2) -> Vector2:
	var a: Alberi = _s.alberi
	var h := 4.0
	var g := Vector2(a.distanza_acqua(p.x + h, p.y) - a.distanza_acqua(p.x - h, p.y),
		a.distanza_acqua(p.x, p.y + h) - a.distanza_acqua(p.x, p.y - h))
	return -g.normalized()


func _process(_d: float) -> bool:
	_f += 1
	var args := OS.get_cmdline_user_args()
	if _f == 3:
		var d: MappaDati = _s.dati
		var cam: CameraIsometrica = _s.cam
		var c := cam.bersaglio
		# Il pixel di fiume più vicino al sito iniziale.
		var pc: Vector2i = d.pixel_da_mondo(c.x, c.z)
		var fiume := Vector2i(-1, -1)
		var dist := 1e9
		for z in d.lato:
			for x in d.lato:
				if d.tipo[d.indice(x, z)] == MappaDati.FIUME:
					var dd := Vector2(x - pc.x, z - pc.y).length()
					if dd < dist:
						dist = dd
						fiume = Vector2i(x, z)
		var riva := float(args[3]) if args.size() > 3 else 4.0
		var p := _punto_di_riva(d.mondo_da_pixel(fiume), riva)
		if p == Vector2.INF:
			push_error("Nessun punto di riva trovato")
			quit(1)
			return false
		var v := _verso_acqua(p)
		# Il lato -z del modello guarda l'acqua: rotazione attorno a y di atan2(-v.x, -v.y).
		var gradi := rad_to_deg(atan2(-v.x, -v.y))
		var u: UsoSuolo = _s.uso
		u.costruisci(u.celle_nel_cerchio(p.x, p.y, 14.0), "capanna")
		var nodo := Asset.istanzia(MODELLO)
		nodo.position = Vector3(p.x, _s.terreno.quota_mondo(p.x, p.y), p.y)
		nodo.rotation_degrees.y = gradi
		_s.add_child(nodo)
		print("Capanno a (%.0f, %.0f), %.1f m dalla riva, verso l'acqua (%.2f, %.2f), %.0f gradi" \
			% [p.x, p.y, _s.alberi.distanza_acqua(p.x, p.y), v.x, v.y, gradi])
		_s.griglia_attiva = false
		var dim := float(args[1]) if args.size() > 1 else 40.0
		cam.vai_a(p.x, p.y, dim)
		cam.bersaglio = Vector3(p.x, 0, p.y)
		cam.dimensione = dim
		cam.dimensione_obiettivo = dim
		if args.size() > 2:
			for _i in int(args[2]):
				cam.ruota(1)
			cam.yaw = cam.yaw_obiettivo
		cam.aggiorna()
	if _f == 60:
		root.get_texture().get_image().save_png(args[0] if args.size() > 0 else "user://capanno.png")
		print("Foto salvata")
		quit(0)
	return false
