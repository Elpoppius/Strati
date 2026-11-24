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
	controlla(h._menu.has("insediamento") and h._menu.has("territorio") and h._menu.has("vie") and h._menu.has("edifici"), "menù logici: Insediamento, Territorio, Vie, Edifici")
	# Le politiche non sono costruzioni: nessun menù Usanze, un pannello a parte.
	controlla((h._righe_comandi["campi"] as Button).has_node("Icona") and (h._righe_azioni["politiche"] as Button).has_node("Icona"), "i tasti dei comandi hanno il loro pittogramma")
	controlla(not h._menu.has("usanze") and not h._menu_di.has("comune"), "le politiche non stanno tra i menù delle costruzioni")
	var sim: SimVillaggio = _s.partita.sim
	controlla(not h.politiche_aperte(), "il pannello delle politiche parte chiuso")
	controlla(h._politiche.has("ammodernamento") and not h.politica_attiva("ammodernamento"), "l'ammodernamento c'è già, spento finché non ci sono campi vecchi")
	(h._righe_azioni["politiche"] as Button).emit_signal("pressed")
	controlla(h.politiche_aperte(), "il tasto Politiche apre il pannello")
	controlla(h.politica("raccolto") == sim.politica("raccolto") and h.politica("stranieri") == sim.politica("stranieri"), "il pannello mostra le politiche in vigore")
	(h._politiche["raccolto"]["opzioni"]["famiglie"] as Button).emit_signal("pressed")
	controlla(sim.politica("raccolto") == "famiglie" and h.politica("raccolto") == "famiglie", "scegliere un'opzione nel pannello cambia la politica")
	controlla(String((h._politiche["raccolto"]["nota"] as Label).text).contains("di più"), "sotto le opzioni c'è cosa comporta quella in vigore")
	var ev := InputEventKey.new()
	ev.keycode = KEY_P
	ev.pressed = true
	_s._unhandled_input(ev)
	controlla(not h.politiche_aperte(), "il tasto P chiude il pannello")
	# Cinque blocchi in basso (decisione di Fede): info, descrizione, costruzione, gestione,
	# strumenti; gli ultimi tre con le schede.
	controlla(h._blocchi.has("costruzione") and h._blocchi.has("gestione") and h._blocchi.has("strumenti"), "blocchi dei comandi: Costruzione, Gestione, Strumenti")
	var ordine: Array = []
	for b in ["costruzione", "gestione", "strumenti"]:
		ordine.append((h._blocchi[b]["pannello"] as Control).get_index())
	controlla(ordine[0] < ordine[1] and ordine[1] < ordine[2], "i blocchi sono in ordine da sinistra: Costruzione, Gestione, Strumenti")
	controlla(h._menu["demolizione"]["blocco"] == "strumenti" and h._menu_di.get("demolisci", "") == "demolizione", "Demolisci sta nel blocco Strumenti")
	controlla(h._menu["prova"]["blocco"] == "strumenti" and h._menu["politiche_menu"]["blocco"] == "gestione", "Prova dentro Strumenti, Politiche dentro Gestione")
	var schede_str: Control = h._blocchi["strumenti"]["schede"]
	controlla(schede_str.get_child(0) == h._menu["demolizione"]["scheda"], "Demolizione è la prima scheda degli Strumenti")
	h.seleziona_comando("sentiero")
	h.seleziona_comando("demolisci")
	controlla(h.menu_aperto("strumenti") == "demolizione" and h.menu_aperto("costruzione") == "vie", "scegliere Demolisci (X) apre la sua scheda senza chiudere quelle degli altri blocchi")
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
