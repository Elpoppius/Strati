extends SceneTree
## Verifica senza grafica della base del gioco.
## Uso: godot --headless --path gioco -s res://test/verifica_base.gd

var _scena: Node
var _fotogrammi := 0
var _errori := 0
var _yaw_iniziale := 0.0


func _initialize() -> void:
	var d := load("res://mappe/pedecollinare/mappa.res") as MappaDati
	controlla(d != null, "la mappa si carica")
	if d == null:
		_fine()
		return
	var n := d.lato * d.lato
	controlla(d.lato == 256, "la mappa è 256 x 256 pixel")
	controlla(d.altezze.size() == n and d.tipo.size() == n and d.fertilita.size() == n, "tutti gli strati hanno la dimensione giusta")
	controlla(d.distanza_acqua.size() == d.lato_acqua * d.lato_acqua and d.lato_acqua == 1024, "il campo di distanza delle acque è 1024 x 1024")
	controlla(d.siti.size() == 6, "ci sono i sei siti di fondazione")
	var q := {}
	for s in d.siti:
		var p: Vector2 = d.mondo_da_pixel(s["px"])
		q[s["n"]] = d.quota(p.x, p.y)
		controlla(d.edificabile_px(Vector2i(s["px"])), "il sito %d è su terra edificabile" % s["n"])
	controlla(q[3] > q[1] and q[1] > q[6] and q[6] > q[4], "le quote dei siti seguono la mappa (sperone > terrazzo > pianura > dosso)")
	_scena = load("res://scene/principale.tscn").instantiate()
	root.add_child(_scena)


func _process(_delta: float) -> bool:
	_fotogrammi += 1
	if _fotogrammi == 2:
		var t: Terreno = _scena.terreno
		controlla(t != null and t.mesh != null, "il terreno è stato costruito")
		if t and t.mesh:
			var arr := t.mesh.surface_get_arrays(0)
			controlla((arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() == 256 * 256, "il terreno ha 65.536 vertici")
		var cam: CameraIsometrica = _scena.cam
		var centro := Vector2(root.get_visible_rect().size) * 0.5
		var punto = t.interseca_raggio(cam.camera.project_ray_origin(centro), cam.camera.project_ray_normal(centro))
		controlla(punto != null, "il puntatore al centro dello schermo colpisce il terreno")
		if punto != null:
			var dist := Vector2(punto.x - cam.bersaglio.x, punto.z - cam.bersaglio.z).length()
			controlla(dist < 30.0, "il centro dello schermo corrisponde al punto guardato (scarto %.1f m)" % dist)
			_scena.aggiorna_lettura(centro)
			controlla(_scena.lotto_corrente.x >= 0, "il lotto sotto il puntatore viene individuato")
			print("   lettura: ", _scena.testo_lettura(punto.x, punto.z))
		_yaw_iniziale = cam.yaw
		cam.ruota(1)
		cam.zoom(0.5)
		# Avanza l'animazione della camera con un passo fisso, indipendente dalla velocità della macchina.
		for _i in 90:
			cam._process(1.0 / 30.0)
		controlla(absf(cam.yaw - (_yaw_iniziale + 90.0)) < 0.1, "la camera ruota di 90° (yaw %.1f)" % cam.yaw)
		controlla(cam.dimensione < 1000.0, "lo zoom avvicina la vista (%.0f m)" % cam.dimensione)
		_scena.imposta_modo(3)
		controlla(_scena.modo == 3, "si passa alla mappa del rischio di piena")
		_fine()
	return false


func controlla(condizione: bool, descrizione: String) -> void:
	if condizione:
		print("OK  ", descrizione)
	else:
		print("NO  ", descrizione)
		_errori += 1


func _fine() -> void:
	print("Verifica completata: %s" % ("nessun errore" if _errori == 0 else "%d errori" % _errori))
	quit(1 if _errori > 0 else 0)
