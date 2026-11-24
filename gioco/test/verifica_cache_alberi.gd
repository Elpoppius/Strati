extends SceneTree
## Verifiche sulla cache degli alberi (salvataggio, caricamento, scarto se non valida), senza grafica.
## Uso: godot --headless --path gioco -s res://test/verifica_cache_alberi.gd

var _errori := 0


func controlla(cond: bool, testo: String) -> void:
	print(("OK  " if cond else "ERRORE  ") + testo)
	if not cond:
		_errori += 1


func _initialize() -> void:
	var d: MappaDati = load("res://mappe/pedecollinare/mappa.res")
	var a := Alberi.new(d)
	a.cancella_cache()
	controlla(not a.carica_cache(), "senza cache il caricamento non riesce")
	var t0 := Time.get_ticks_msec()
	a.calcola_in_sottofondo(5000.0, 5000.0)
	a.aspetta()
	print("   calcolo di tutta la mappa: %d ms" % (Time.get_ticks_msec() - t0))
	t0 = Time.get_ticks_msec()
	controlla(a.salva_cache(), "la cache si salva (%d ms)" % (Time.get_ticks_msec() - t0))
	var dim := FileAccess.get_file_as_bytes(a._percorso_cache()).size()
	print("   dimensione della cache: %.1f MB" % (dim / 1048576.0))
	var b := Alberi.new(d)
	t0 = Time.get_ticks_msec()
	controlla(b.carica_cache(), "la cache si carica (%d ms)" % (Time.get_ticks_msec() - t0))
	var uguali := true
	for k in a._cache:
		if a._cache[k] != b._cache[k]:
			uguali = false
	controlla(uguali and a._cache.size() == b._cache.size(), "gli alberi caricati sono identici a quelli calcolati (%d blocchi)" % b._cache.size())
	# Cache rovinata: un blocco di controllo diverso deve farla scartare.
	a._cache[Alberi.BLOCCHI_CONTROLLO[0]] = PackedFloat32Array([1.0, 2.0, 3.0, 4.0, 0.0, 1.0, 50.0])
	a.salva_cache()
	controlla(not Alberi.new(d).carica_cache(), "una cache che non corrisponde al calcolo viene scartata")
	# File troncato.
	var f := FileAccess.open(a._percorso_cache(), FileAccess.WRITE)
	f.store_buffer(PackedByteArray([1, 2, 3]))
	f.close()
	controlla(not Alberi.new(d).carica_cache(), "un file rovinato viene scartato")
	a.cancella_cache()
	print("Verifica completata: " + ("nessun errore" if _errori == 0 else "%d errori" % _errori))
	quit(1 if _errori > 0 else 0)
