extends SceneTree
## Verifiche sull'HUD (mappe a destra, comandi a sinistra) e sugli strumenti di prova
## dell'uso del suolo, senza grafica.
## Uso: godot --headless --path gioco -s res://test/verifica_hud.gd

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
	var h: Hud = _s.hud
	controlla(h != null and h._righe_mappe.size() == _s.NOMI_MODI.size(), "HUD con una riga per ogni mappa (%d)" % h._righe_mappe.size())
	h._righe_mappe[3].emit_signal("pressed")
	controlla(_s.modo == 3 and h._righe_mappe[3].button_pressed and not h._righe_mappe[0].button_pressed, "scegliere una mappa nell'HUD la attiva e la evidenzia")
	_s.imposta_modo(1)
	controlla(h._righe_mappe[1].button_pressed and not h._righe_mappe[3].button_pressed, "cambiare mappa da tastiera aggiorna l'HUD")
	controlla(h._legenda_barra.visible and h._legenda_dx.text != "", "la legenda segue la mappa")
	# Strumenti di prova: abbattere al centro dello schermo, sopra un bosco.
	var a: Alberi = _s.alberi
	var punto := Vector3.ZERO
	for z in range(1000, 9000, 97):
		for x in range(1000, 9000, 97):
			if punto == Vector3.ZERO and a.valore_bosco(x, z) > 0.8:
				punto = Vector3(x, 0, z)
	_s.punto_corrente = punto
	h.seleziona_comando("demolisci")
	_s.applica_strumento()
	controlla(_s.uso.stato(punto.x, punto.z) == UsoSuolo.LIBERO and _s.uso.memoria_bosco(punto.x, punto.z), "lo strumento Demolisci taglia il bosco sotto il puntatore")
	controlla(h._messaggio.text.contains("legname"), "il messaggio dice quanto legname: " + h._messaggio.text)
	# Sul fiume Demolisci non agisce.
	var fiume := Vector3.ZERO
	for i in _s.dati.lato * _s.dati.lato:
		if fiume == Vector3.ZERO and _s.dati.tipo[i] == MappaDati.FIUME:
			var w: Vector2 = _s.dati.mondo_da_pixel(Vector2(i % _s.dati.lato, i / _s.dati.lato))
			if a.distanza_acqua(w.x, w.y) < -10.0:
				fiume = Vector3(w.x, 0, w.y)
	_s.punto_corrente = fiume
	_s.applica_strumento()
	controlla(h._messaggio.text.contains("non si demoliscono"), "fiumi e paludi non si demoliscono: " + h._messaggio.text)
	_s.punto_corrente = punto
	# Menù logici e strumenti trasversali.
	controlla(h._menu.has("insediamento") and h._menu.has("territorio") and h._menu.has("vie") and h._menu.has("edifici") and h._menu.has("usanze"), "menù logici: Insediamento, Territorio, Vie, Edifici, Usanze")
	controlla(not h._menu_di.has("demolisci") and h._righe_comandi.has("demolisci"), "Demolisci è uno strumento trasversale, fuori dai menù delle costruzioni")
	h.seleziona_comando("sentiero")
	controlla(h.menu_aperto() == "vie" and (h._menu["vie"]["pagina"] as Control).visible and not (h._menu["territorio"]["pagina"] as Control).visible, "scegliere uno strumento (anche da tastiera) apre il suo menù")
	controlla(h._messaggio.text.contains("sentieri"), "la scheda spiega cosa fa lo strumento scelto")
	controlla(not h._righe_comandi.has("sigilla") and not h._righe_comandi.has("costruisci"), "nessuno strumento per scegliere il materiale: è una qualità nascosta delle costruzioni")
	_s._azione("anni")
	controlla(h._messaggio.text.contains("10 anni"), "l'azione Fai passare 10 anni funziona")
	controlla(_s.testo_lettura(punto.x, punto.z).contains("ex area boschiva"), "la lettura del lotto dice l'uso del suolo e la memoria del bosco")
	print("Verifica completata: " + ("nessun errore" if _errori == 0 else "%d errori" % _errori))
	quit(1 if _errori > 0 else 0)
	return true
