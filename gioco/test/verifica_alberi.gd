extends SceneTree
## Verifiche sugli alberi della mappa (dati e vista), senza grafica.
## Uso: godot --headless --path gioco -s res://test/verifica_alberi.gd

var _errori := 0
var _s: Node
var _f := 0


func controlla(cond: bool, testo: String) -> void:
	print(("OK  " if cond else "ERRORE  ") + testo)
	if not cond:
		_errori += 1


func _initialize() -> void:
	_s = load("res://scene/principale.tscn").instantiate()
	root.add_child(_s)


func _process(_d: float) -> bool:
	_f += 1
	if _f < 3:
		return false
	var a: Alberi = _s.alberi
	var v: VistaAlberi = _s.vista_alberi
	controlla(a != null and v != null, "alberi e vista creati")
	for liv in [VistaAlberi.LEGGERI, VistaAlberi.COMPLETI]:
		var tutti := true
		for m in v._mesh[liv]:
			tutti = tutti and m != null
		controlla(tutti, "modelli del livello %d caricati (%d)" % [liv, v._mesh[liv].size()])
	# Blocchi su tutta la mappa: conta, tempo, niente alberi nell'acqua.
	var d: MappaDati = _s.dati
	var nb := int(ceil(d.lato_metri() / Alberi.LATO_BLOCCO))
	var t0 := Time.get_ticks_usec()
	var totale := 0
	var in_acqua := 0
	var per_specie := [0, 0, 0, 0]
	var colline := [0, 0, 0, 0]
	for bz in nb:
		for bx in nb:
			var arr := a.alberi_nel_blocco(Vector2i(bx, bz))
			var k := Alberi.CAMPI
			for i in arr.size() / k:
				var x := arr[i * k]
				var z := arr[i * k + 1]
				var m := int(arr[i * k + 4])
				var sp := 0 if m < 3 else (1 if m < 5 else (2 if m < 7 else 3))
				per_specie[sp] += 1
				var p := d.pixel_da_mondo(x, z)
				if d.zona[d.indice(p.x, p.y)] == 3:
					colline[sp] += 1
				if a.distanza_acqua(x, z) < 2.0:
					in_acqua += 1
			totale += arr.size() / k
	var ms := (Time.get_ticks_usec() - t0) / 1000.0
	print("   alberi su tutta la mappa: %d (querce %d, carpini %d, pioppi %d, arbusti %d), %.0f ms per %d blocchi (%.1f ms a blocco)" % [totale, per_specie[0], per_specie[1], per_specie[2], per_specie[3], ms, nb * nb, ms / (nb * nb)])
	controlla(totale > 300000, "il bosco è fitto (più di 300 000 alberi)")
	controlla(in_acqua == 0, "nessun albero nell'acqua (%d)" % in_acqua)
	controlla(colline[2] < (colline[0] + colline[1]) * 0.15, "sulle colline pochi pioppi, solo lungo i torrenti (%d su %d)" % [colline[2], colline[0] + colline[1] + colline[2] + colline[3]])
	controlla(per_specie[2] > 0, "ci sono pioppi (luoghi umidi)")
	var prima := a.alberi_nel_blocco(Vector2i(10, 10))
	a.aspetta()
	a._cache.clear()
	controlla(prima == a.alberi_nel_blocco(Vector2i(10, 10)), "la posa è deterministica")
	# Vista: livelli di dettaglio secondo lo zoom.
	var cam: CameraIsometrica = _s.cam
	for prova in [[12000.0, VistaAlberi.RADE], [3000.0, VistaAlberi.RADE], [1800.0, VistaAlberi.SAGOME], [600.0, VistaAlberi.LEGGERI], [180.0, VistaAlberi.COMPLETI]]:
		cam.dimensione = prova[0]
		cam.dimensione_obiettivo = prova[0]
		cam.aggiorna()
		var t1 := Time.get_ticks_usec()
		v.aggiorna(-1)
		var ms2 := (Time.get_ticks_usec() - t1) / 1000.0
		controlla(v.livello == prova[1] and v.alberi_visibili > 0, "vista di %d m: livello %d, %d alberi disegnati, %d blocchi (%.0f ms)" % [prova[0], v.livello, v.alberi_visibili, v._blocchi.size(), ms2])
	print("Verifica completata: " + ("nessun errore" if _errori == 0 else "%d errori" % _errori))
	quit(1 if _errori > 0 else 0)
	return true
