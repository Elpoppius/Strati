extends SceneTree
## Misura i tempi degli alberi (calcolo dei dati e preparazione dei buffer), senza grafica.
## Serve a confrontare le ottimizzazioni: stampa anche un'impronta dei dati di tutta la mappa,
## che deve restare uguale se si cambia solo la velocità del calcolo e non la posa.
## Uso: godot --headless --path gioco -s res://test/misura_alberi.gd

var _s: Node
var _f := 0


func _initialize() -> void:
	_s = load("res://scene/principale.tscn").instantiate()
	root.add_child(_s)


func _process(_d: float) -> bool:
	_f += 1
	if _f < 3:
		return false
	var a: Alberi = _s.alberi
	var v: VistaAlberi = _s.vista_alberi
	a.aspetta()
	var nb := int(ceil(a.dati.lato_metri() / Alberi.LATO_BLOCCO))
	# 1. Calcolo su un solo thread, senza cache.
	a.svuota()
	var t0 := Time.get_ticks_usec()
	var impronta := HashingContext.new()
	impronta.start(HashingContext.HASH_MD5)
	var totale := 0
	for bz in nb:
		for bx in nb:
			var arr := a.alberi_nel_blocco(Vector2i(bx, bz))
			totale += arr.size() / Alberi.CAMPI
			if not arr.is_empty():
				impronta.update(arr.to_byte_array())
	var ms_uno := (Time.get_ticks_usec() - t0) / 1000.0
	print("calcolo su un thread: %d piante, %.0f ms (%.1f ms a blocco)" % [totale, ms_uno, ms_uno / (nb * nb)])
	print("impronta dei dati: ", impronta.finish().hex_encode())
	# 2. Calcolo di tutta la mappa su tutti i thread.
	a.svuota()
	t0 = Time.get_ticks_usec()
	a.calcola_in_sottofondo(5000.0, 5000.0)
	a.aspetta()
	print("calcolo su tutti i thread (%d processori): %.0f ms" % [OS.get_processor_count(), (Time.get_ticks_usec() - t0) / 1000.0])
	var impronta2 := HashingContext.new()
	impronta2.start(HashingContext.HASH_MD5)
	for bz in nb:
		for bx in nb:
			var arr2 := a.alberi_nel_blocco(Vector2i(bx, bz))
			if not arr2.is_empty():
				impronta2.update(arr2.to_byte_array())
	print("impronta dei dati (calcolo in sottofondo): ", impronta2.finish().hex_encode())
	# 3. Preparazione dei buffer per vista, con i dati già pronti.
	var cam: CameraIsometrica = _s.cam
	for dim in [12000.0, 3000.0, 1800.0, 600.0, 180.0]:
		cam.dimensione = dim
		cam.dimensione_obiettivo = dim
		cam.aggiorna()
		var t1 := Time.get_ticks_usec()
		v.aggiorna(-1)
		print("vista di %d m: %d alberi, %d blocchi, %.0f ms (buffer e MultiMesh)" % [dim, v.alberi_visibili, v._blocchi.size(), (Time.get_ticks_usec() - t1) / 1000.0])
	quit(0)
	return true
