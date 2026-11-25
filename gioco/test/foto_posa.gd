extends SceneTree
## Foto di controllo degli edifici delle risorse dove starebbero nel gioco.
## - capanno: il capanno da pesca sulla riva del fiume più vicina al sito iniziale, a 2 m
##   dall'acqua, con rastrelliera e piroga (asse +y del modello in Blender, -z in Godot) verso
##   l'acqua.
## - posta: la posta di caccia sul margine del bosco più vicino al sito iniziale, con la schiena
##   del riparo (+y del modello) verso il bosco e l'apertura verso la radura.
## Uso: xvfb-run -a -s "-screen 0 1600x900x24" godot --path gioco --rendering-driver opengl3 --resolution 1600x900 -s res://test/foto_posa.gd -- uscita.png [capanno|posta] [dimensione_vista] [rotazioni]

const MODELLI := {
	"capanno": "res://asset/villaggio/capanno_pesca.glb",
	"posta": "res://asset/villaggio/posta_caccia.glb",
}

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


## Punto appena fuori dal bosco (valore 0,4 circa, il margine è 0,5) più vicino a `da`, asciutto,
## fuori dalla palude e poco inclinato.
func _punto_di_margine(da: Vector2) -> Vector2:
	var a: Alberi = _s.alberi
	var d: MappaDati = _s.dati
	var migliore := Vector2.INF
	var costo := INF
	for gz in range(-200, 201):
		for gx in range(-200, 201):
			var p := da + Vector2(gx, gz) * 3.0
			if absf(a.valore_bosco(p.x, p.y) - 0.4) > 0.03 or a.distanza_acqua(p.x, p.y) < 30.0:
				continue
			var q := d.pixel_da_mondo(p.x, p.y)
			if d.tipo[d.indice(q.x, q.y)] == MappaDati.PALUDE:
				continue
			var pend: float = absf(_s.terreno.quota_mondo(p.x + 6.0, p.y) - _s.terreno.quota_mondo(p.x - 6.0, p.y)) \
				+ absf(_s.terreno.quota_mondo(p.x, p.y + 6.0) - _s.terreno.quota_mondo(p.x, p.y - 6.0))
			var c := p.distance_to(da) + pend * 40.0
			if c < costo:
				costo = c
				migliore = p
	return migliore


## Direzione verso il bosco: lungo il gradiente del valore del bosco.
func _verso_bosco(p: Vector2) -> Vector2:
	var a: Alberi = _s.alberi
	var h := 8.0
	return Vector2(a.valore_bosco(p.x + h, p.y) - a.valore_bosco(p.x - h, p.y),
		a.valore_bosco(p.x, p.y + h) - a.valore_bosco(p.x, p.y - h)).normalized()


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
		var modo := args[1] if args.size() > 1 else "capanno"
		var p := Vector2.INF
		var v := Vector2.ZERO
		if modo == "posta":
			p = _punto_di_margine(Vector2(c.x, c.z))
			if p != Vector2.INF:
				v = _verso_bosco(p)
		else:
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
			p = _punto_di_riva(d.mondo_da_pixel(fiume), 2.0)
			if p != Vector2.INF:
				v = _verso_acqua(p)
		if p == Vector2.INF:
			push_error("Nessun punto adatto trovato")
			quit(1)
			return false
		# Il lato -z del modello guarda l'acqua o il bosco: rotazione attorno a y di atan2(-v.x, -v.y).
		var gradi := rad_to_deg(atan2(-v.x, -v.y))
		var u: UsoSuolo = _s.uso
		u.costruisci(u.celle_nel_cerchio(p.x, p.y, 14.0 if modo == "capanno" else 8.0), "capanna")
		var nodo := Asset.istanzia(MODELLI[modo])
		nodo.position = Vector3(p.x, _s.terreno.quota_mondo(p.x, p.y), p.y)
		nodo.rotation_degrees.y = gradi
		_s.add_child(nodo)
		print("%s a (%.0f, %.0f), %.1f m dalla riva, bosco %.2f, verso (%.2f, %.2f), %.0f gradi" \
			% [modo, p.x, p.y, _s.alberi.distanza_acqua(p.x, p.y), _s.alberi.valore_bosco(p.x, p.y), v.x, v.y, gradi])
		_s.griglia_attiva = false
		var dim := float(args[2]) if args.size() > 2 else 40.0
		cam.vai_a(p.x, p.y, dim)
		cam.bersaglio = Vector3(p.x, 0, p.y)
		cam.dimensione = dim
		cam.dimensione_obiettivo = dim
		if args.size() > 3:
			for _i in int(args[3]):
				cam.ruota(1)
			cam.yaw = cam.yaw_obiettivo
		cam.aggiorna()
	if _f == 60:
		root.get_texture().get_image().save_png(args[0] if args.size() > 0 else "user://posa.png")
		print("Foto salvata")
		quit(0)
	return false
