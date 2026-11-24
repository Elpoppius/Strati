extends Node3D
## Scena principale della base: terreno della mappa pedecollinare, camera isometrica,
## mappe tematiche, griglia dei lotti e lettura del lotto sotto il puntatore.

const PERCORSO_MAPPA := "res://mappe/pedecollinare/mappa.res"
const ESAGERAZIONE := 1.5
const LATO_LOTTO := 20.0
const NOMI_MODI := ["Terreno", "Acqua", "Fertilità", "Rischio piena", "Energia dell'acqua"]
const SITO_INIZIALE := 1

## Sole: altezza sull'orizzonte e angolo rispetto alla direzione in cui guarda la camera (gradi).
## 270 = sole da sinistra, ombre verso destra sullo schermo (scelta di Fede); l'altezza bassa le tiene lunghe.
const ALTEZZA_SOLE := 42.0
const AZIMUT_SOLE := 270.0

var dati: MappaDati
var terreno: Terreno
var cam: CameraIsometrica
var sole: DirectionalLight3D
var alberi: Alberi
var vista_alberi: VistaAlberi
var uso: UsoSuolo
## La partita della prima epoca (il villaggio): simulazione, disegno e comandi.
var partita: Partita
var modo := 0
var griglia_attiva := true
## Isoipse spente di serie (scelta di Fede): il rilievo si legge da luce e ombre; tasto I.
var isoipse_attive := false
var lotto_corrente := Vector2i(-1, -1)
var punto_corrente: Variant = null

var hud: Hud
## Raggio dello strumento di prova dell'uso del suolo, in metri.
var raggio_pennello := 40.0
var _tempo_prestazioni := 0.0
var _trascinando := false
## Etichette dei siti adatti alle dighe: visibili solo nella mappa dell'energia dell'acqua.
var _segni_dighe: Array[Label3D] = []
## Stato degli alberi mostrato nel pannello: da dove vengono e quanto ci hanno messo.
var _stato_alberi := ""
var _inizio_calcolo_alberi := -1
var _salvataggio_alberi := -1


func _ready() -> void:
	dati = load(PERCORSO_MAPPA) as MappaDati
	if dati == null:
		push_error("Mappa non trovata: " + PERCORSO_MAPPA)
		return
	_crea_ambiente()
	terreno = Terreno.new()
	terreno.name = "Terreno"
	add_child(terreno)
	terreno.costruisci(dati, ESAGERAZIONE)
	terreno.materiale.set_shader_parameter("lato_lotto", LATO_LOTTO)
	_crea_segni_siti()
	_crea_segni_dighe()
	cam = CameraIsometrica.new()
	cam.name = "Camera"
	add_child(cam)
	cam.limiti = Rect2(0.0, 0.0, dati.lato_metri(), dati.lato_metri())
	cam.funzione_quota = terreno.quota_mondo
	torna_al_sito()
	# Alberi veri sulla mappa (dati in Alberi, disegno in VistaAlberi).
	alberi = Alberi.new(dati)
	vista_alberi = VistaAlberi.new()
	vista_alberi.name = "Alberi"
	add_child(vista_alberi)
	vista_alberi.prepara(alberi, terreno, cam)
	# Uso del suolo: alberi tagliati, in ricrescita, campi, costruzioni (regole di Fede in UsoSuolo).
	uso = UsoSuolo.new(alberi)
	vista_alberi.uso = uso
	terreno.materiale.set_shader_parameter("uso_suolo", uso.texture)
	terreno.materiale.set_shader_parameter("uso_attivo", 1.0)
	terreno.materiale.set_shader_parameter("tecniche_campi", uso.texture_tecniche)
	# Dal secondo avvio gli alberi si caricano dalla cache; la prima volta si calcolano in
	# sottofondo su tutti i processori e poi si salvano (vedi Alberi).
	var t0 := Time.get_ticks_msec()
	if alberi.carica_cache():
		_stato_alberi = "alberi dalla cache in %d ms" % (Time.get_ticks_msec() - t0)
	else:
		_inizio_calcolo_alberi = t0
		_stato_alberi = "calcolo degli alberi in corso"
		alberi.calcola_in_sottofondo(cam.bersaglio.x, cam.bersaglio.z)
	_crea_interfaccia()
	partita = Partita.new()
	partita.name = "Partita"
	add_child(partita)
	partita.avvia(self)
	imposta_modo(0)


func _crea_ambiente() -> void:
	sole = DirectionalLight3D.new()
	sole.name = "Sole"
	sole.rotation_degrees = Vector3(-ALTEZZA_SOLE, 45.0 + AZIMUT_SOLE, 0.0)
	sole.light_energy = 0.95
	sole.light_color = Color(1.0, 0.95, 0.86)  # sole caldo
	sole.shadow_enabled = true
	# Una sola mappa d'ombra sulla fetta visibile (vedi CameraIsometrica.aggiorna).
	sole.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sole.directional_shadow_max_distance = 12000.0
	sole.directional_shadow_fade_start = 1.0
	add_child(sole)
	var amb := Environment.new()
	amb.background_mode = Environment.BG_COLOR
	amb.background_color = Color8(231, 234, 226)
	amb.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	# Luce del cielo un po' fredda: le ombre restano leggibili ma non nere, e contrastano col sole caldo.
	amb.ambient_light_color = Color(0.82, 0.88, 1.0)
	amb.ambient_light_energy = 0.45
	var mondo := WorldEnvironment.new()
	mondo.environment = amb
	add_child(mondo)


func _crea_segni_siti() -> void:
	for s in dati.siti:
		var p: Vector2 = dati.mondo_da_pixel(s["px"])
		var etichetta := Label3D.new()
		etichetta.text = "%d · %s" % [s["n"], s["nome"]]
		etichetta.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		etichetta.fixed_size = true
		etichetta.pixel_size = 0.0012
		etichetta.font_size = 22
		etichetta.outline_size = 8
		etichetta.modulate = Color8(30, 41, 39)
		etichetta.outline_modulate = Color8(243, 244, 239)
		etichetta.no_depth_test = true
		etichetta.position = Vector3(p.x, dati.quota(p.x, p.y) * ESAGERAZIONE + 30.0, p.y)
		add_child(etichetta)


## Siti per le dighe (dai dati della mappa): per ogni luogo l'altezza con l'invaso più grande.
func _crea_segni_dighe() -> void:
	var migliori := {}
	for s in dati.siti_diga:
		var k: Vector2 = s["px"]
		if not migliori.has(k) or float(s["volume_milioni_m3"]) > float(migliori[k]["volume_milioni_m3"]):
			migliori[k] = s
	for s in migliori.values():
		var p: Vector2 = dati.mondo_da_pixel(s["px"])
		var etichetta := Label3D.new()
		etichetta.text = "Diga %d m · lunga %d m\ninvaso %s milioni di m³ · %s ha\n%s kW medi" % [
			int(s["altezza_m"]), int(s["lunghezza_m"]), String.num(s["volume_milioni_m3"], 2).replace(".", ","),
			String.num(s["area_ha"], 1).replace(".", ","), String.num(s["potenza_media_kw"], 0)]
		etichetta.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		etichetta.fixed_size = true
		etichetta.pixel_size = 0.001
		etichetta.font_size = 20
		etichetta.outline_size = 8
		etichetta.modulate = Color8(18, 52, 86)
		etichetta.outline_modulate = Color8(243, 244, 239)
		etichetta.no_depth_test = true
		etichetta.visible = false
		etichetta.position = Vector3(p.x, dati.quota(p.x, p.y) * ESAGERAZIONE + 25.0, p.y)
		add_child(etichetta)
		_segni_dighe.append(etichetta)


func _crea_interfaccia() -> void:
	hud = Hud.new()
	add_child(hud)
	hud.costruisci(dati.nome, NOMI_MODI)
	hud.minimappa.collega(dati, cam)
	hud.imposta_sovrapposizioni(griglia_attiva, isoipse_attive)
	hud.modo_scelto.connect(imposta_modo)
	hud.griglia_cambiata.connect(func(v: bool) -> void: griglia_attiva = v)
	hud.isoipse_cambiate.connect(func(v: bool) -> void: isoipse_attive = v)
	# Strumento di prova: far passare il tempo, per vedere la ricrescita del bosco anche senza
	# villaggio. Tagliare si fa con Demolisci (nella partita). L'invasività delle costruzioni non
	# è uno strumento: è una qualità nascosta dei loro materiali (chiarimento di Fede, vedi UsoSuolo).
	hud.aggiungi_menu("prova", "Prova", "Solo per le prove.", [
		{"id": "anni", "icona": "anni", "testo": "Avanti di 10 anni (solo per prova: fa ricrescere il bosco anche senza villaggio)", "breve": "+10 anni", "tasto": "Y", "strumento": false},
	], "strumenti")
	hud.comando_scelto.connect(func(_id: String) -> void: _aggiorna_pennello())
	hud.azione.connect(_azione)
	# Un clic su una notifica porta la camera sul luogo.
	hud.notifica_scelta.connect(func(punto: Vector2) -> void: cam.vai_a(punto.x, punto.y))
	hud.imposta_messaggio("Scegli uno strumento e clicca sulla mappa. Raggio %d m ( [ e ] per cambiarlo)." % roundi(raggio_pennello))


func imposta_modo(i: int) -> void:
	modo = i
	terreno.materiale.set_shader_parameter("modo", i)
	for e in _segni_dighe:
		e.visible = (i == 4)
	if hud:
		hud.seleziona_modo(i)


func torna_al_sito() -> void:
	for s in dati.siti:
		if s["n"] == SITO_INIZIALE:
			var p: Vector2 = dati.mondo_da_pixel(s["px"])
			cam.vai_a(p.x, p.y, 1500.0)


func _process(delta: float) -> void:
	if terreno == null:
		return
	if _inizio_calcolo_alberi >= 0 and alberi.tutto_pronto():
		alberi.aspetta()
		_stato_alberi = "alberi calcolati in %.1f s" % ((Time.get_ticks_msec() - _inizio_calcolo_alberi) / 1000.0)
		_inizio_calcolo_alberi = -1
		_salvataggio_alberi = WorkerThreadPool.add_task(alberi.salva_cache, false, "Cache degli alberi")
	_tempo_prestazioni += delta
	if hud and _tempo_prestazioni > 0.5:
		_tempo_prestazioni = 0.0
		var liv: String = VistaAlberi.NOMI_LIVELLI[vista_alberi.livello] if vista_alberi else ""
		hud.imposta_prestazioni("%d fps · %d alberi (%s) · %s" % [Engine.get_frames_per_second(), vista_alberi.alberi_visibili if vista_alberi else 0, liv, _stato_alberi])
	# La griglia compare quando la vista è abbastanza vicina da distinguere i lotti.
	var alfa := 0.0
	if griglia_attiva:
		alfa = clampf(remap(cam.dimensione, 900.0, 400.0, 0.0, 0.45), 0.0, 0.45)
	terreno.materiale.set_shader_parameter("alfa_griglia", alfa)
	terreno.materiale.set_shader_parameter("alfa_isoipse", 0.35 if isoipse_attive else 0.0)
	if sole and cam.camera:
		sole.directional_shadow_max_distance = cam.camera.far
		# Il sole gira con la camera: illumina gli oggetti di lato e da dietro, così le ombre
		# cadono verso chi guarda e si vedono a ogni rotazione (con il sole alle spalle
		# della camera restavano nascoste dietro gli oggetti e tutto sembrava piatto).
		sole.rotation_degrees = Vector3(-ALTEZZA_SOLE, cam.yaw + AZIMUT_SOLE, 0.0)
		# Direzione verso il sole, per l'ombreggiatura del rilievo nello shader del terreno.
		terreno.materiale.set_shader_parameter("verso_sole", sole.global_transform.basis.z)


func _unhandled_input(ev: InputEvent) -> void:
	if terreno == null:
		return
	if ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			cam.zoom(1.0 / 1.18)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			cam.zoom(1.18)
		elif mb.button_index == MOUSE_BUTTON_RIGHT or mb.button_index == MOUSE_BUTTON_MIDDLE:
			_trascinando = mb.pressed
		elif mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed and hud.comando() != "":
			aggiorna_lettura(mb.position)
			applica_strumento()
	elif ev is InputEventMouseMotion:
		var mm := ev as InputEventMouseMotion
		if _trascinando:
			cam.trascina(mm.relative, get_viewport().get_visible_rect().size.y)
		aggiorna_lettura(mm.position)
	elif ev is InputEventKey and ev.pressed and not ev.echo:
		match (ev as InputEventKey).keycode:
			KEY_Q:
				cam.ruota(-1)
			KEY_E:
				cam.ruota(1)
			KEY_G:
				griglia_attiva = not griglia_attiva
				hud.imposta_sovrapposizioni(griglia_attiva, isoipse_attive)
			KEY_I:
				isoipse_attive = not isoipse_attive
				hud.imposta_sovrapposizioni(griglia_attiva, isoipse_attive)
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5:
				imposta_modo((ev as InputEventKey).keycode - KEY_1)
			KEY_HOME:
				torna_al_sito()
			KEY_X, KEY_F, KEY_C, KEY_V, KEY_H:
				var id: String = {KEY_X: "demolisci", KEY_F: "fonda", KEY_C: "campi", KEY_V: "sentiero", KEY_H: "granaio"}[(ev as InputEventKey).keycode]
				hud.seleziona_comando("" if hud.comando() == id else id)
				_aggiorna_pennello()
			KEY_P:
				hud.apri_politiche(not hud.politiche_aperte())
			KEY_ESCAPE:
				if hud.politiche_aperte():
					hud.apri_politiche(false)
				elif partita and partita.inizio_sentiero.x >= 0:
					partita.annulla_sentiero()
					hud.imposta_messaggio("Sentiero chiuso. Un clic dove comincia il prossimo.")
					_aggiorna_pennello()
				else:
					hud.seleziona_comando("")
					_aggiorna_pennello()
			KEY_Y:
				_azione("anni")
			KEY_SPACE:
				partita.pausa_o_riprendi()
			KEY_EQUAL, KEY_KP_ADD:
				partita.imposta_velocita(mini(partita.velocita + 1, 3))
			KEY_MINUS, KEY_KP_SUBTRACT:
				partita.imposta_velocita(maxi(partita.velocita - 1, 0))
			KEY_BRACKETLEFT, KEY_BRACKETRIGHT:
				var f := 1.25 if (ev as InputEventKey).keycode == KEY_BRACKETRIGHT else 0.8
				raggio_pennello = clampf(raggio_pennello * f, 10.0, 400.0)
				hud.imposta_messaggio("Raggio dello strumento: %d m." % roundi(raggio_pennello))
				_aggiorna_pennello()


## Applica lo strumento di prova scelto nell'HUD al cerchio attorno al punto sotto il puntatore.
func applica_strumento() -> void:
	if punto_corrente == null or uso == null:
		return
	var p: Vector3 = punto_corrente
	if hud.comando() in Partita.STRUMENTI:
		partita.applica(hud.comando(), p, raggio_pennello)
		hud.imposta_lettura(testo_lettura(p.x, p.z))
		return


func _azione(id: String) -> void:
	if id == "anni" and uso:
		uso.avanza_anni(10)
		hud.imposta_messaggio("Sono passati 10 anni.")
		if punto_corrente != null:
			var p: Vector3 = punto_corrente
			hud.imposta_lettura(testo_lettura(p.x, p.z))


## Cerchio dello strumento sul terreno: bianco, rosso se l'azione è irreversibile.
func _aggiorna_pennello() -> void:
	if terreno == null or hud == null:
		return
	if hud.comando() == "" or punto_corrente == null:
		terreno.materiale.set_shader_parameter("pennello", Vector3(0, 0, -1))
		terreno.materiale.set_shader_parameter("griglia_magnetica", Vector3.ZERO)
		if hud.comando() != "campi":
			terreno.materiale.set_shader_parameter("contado", Vector3(0, 0, -1))
		if partita:
			if hud.comando() == "sentiero":
				partita.vista.nascondi_anteprima()
			else:
				partita.annulla_sentiero()
		return
	var p: Vector3 = punto_corrente
	var r := raggio_pennello
	if partita and hud.comando() in Partita.STRUMENTI:
		r = partita.raggio_strumento(hud.comando(), raggio_pennello)
		if hud.comando() == "fonda" and partita.sim.fondato:
			r = -1.0
	# Griglia magnetica (idea di Fede, come in Cities: Skylines): lo strumento si aggancia ai
	# quadrati su cui ragiona la simulazione, che compaiono attorno al puntatore.
	var griglia := Vector3.ZERO
	var centro := Vector2(p.x, p.z)
	match hud.comando():
		"campi":
			# Celle da 40 m centrate sui punti della mappa: si prendono quelle col centro nel cerchio.
			griglia = Vector3(dati.metri_per_px, dati.metri_per_px * 0.5, r * 1.15)
		"granaio":
			# Lotti da 20 m: l'edificio si aggancia al centro del lotto sotto il puntatore.
			centro = (Vector2(floorf(p.x / LATO_LOTTO), floorf(p.z / LATO_LOTTO)) + Vector2(0.5, 0.5)) * LATO_LOTTO
			griglia = Vector3(LATO_LOTTO, 0.0, 70.0)
		"fonda":
			# Il villaggio nasce al centro di un punto della mappa: il cerchio vi si aggancia.
			centro = Vector2(roundf(p.x / dati.metri_per_px), roundf(p.z / dati.metri_per_px)) * dati.metri_per_px
	terreno.materiale.set_shader_parameter("pennello", Vector3(centro.x, centro.y, r))
	terreno.materiale.set_shader_parameter("griglia_magnetica", griglia)
	# Confine del contado con lo strumento Campi.
	var contado := Vector3(0, 0, -1)
	if partita and partita.sim and partita.sim.fondato and hud.comando() == "campi":
		var cc := partita.sim.mondo_di_px(partita.sim.centro)
		contado = Vector3(cc.x, cc.y, partita.sim.raggio_contado())
	terreno.materiale.set_shader_parameter("contado", contado)
	# Sentieri: anteprima come in Cities.
	if partita:
		if hud.comando() == "sentiero":
			partita.anteprima_sentiero(p)
		else:
			partita.annulla_sentiero()
		partita.vista.evidenzia_sentieri(hud.comando() == "sentiero")
	terreno.materiale.set_shader_parameter("colore_pennello", Hud.PERICOLO if hud.comando() == "demolisci" else Hud.BIANCO)


## Legge il terreno sotto un punto dello schermo e aggiorna l'evidenziazione del lotto.
func aggiorna_lettura(pos_schermo: Vector2) -> void:
	var origine := cam.camera.project_ray_origin(pos_schermo)
	var direzione := cam.camera.project_ray_normal(pos_schermo)
	punto_corrente = terreno.interseca_raggio(origine, direzione)
	if punto_corrente == null:
		lotto_corrente = Vector2i(-1, -1)
		terreno.materiale.set_shader_parameter("lotto_evidenziato", Vector2(-1, -1))
		hud.imposta_lettura("Fuori dalla mappa.")
		return
	var p: Vector3 = punto_corrente
	lotto_corrente = Vector2i(floori(p.x / LATO_LOTTO), floori(p.z / LATO_LOTTO))
	terreno.materiale.set_shader_parameter("lotto_evidenziato", Vector2(lotto_corrente))
	hud.imposta_lettura(testo_lettura(p.x, p.z))
	_aggiorna_pennello()


func testo_lettura(x: float, z: float) -> String:
	var c := dati.campione(x, z)
	var lotto := Vector2i(floori(x / LATO_LOTTO), floori(z / LATO_LOTTO))
	var parti := ["Lotto %d·%d" % [lotto.x, lotto.y]]
	if c["edificabile"]:
		parti.append(c["zona"] if c["tipo"] != MappaDati.GESSI else "Gessi")
	else:
		parti.append(c["nome_tipo"])
	parti.append("quota %d m" % roundi(c["quota"]))
	if c["edificabile"]:
		parti.append("fertilità %s" % String.num(c["fertilita"], 2).replace(".", ","))
		var r: float = c["piena"]
		parti.append("rischio piena %s" % ("alto" if r > 0.5 else "medio" if r > 0.25 else "basso" if r > 0.0 else "nullo"))
		var a: float = c["acqua"]
		var s: float = c["acqua_stagionale"]
		parti.append("acqua affidabile vicina" if a > 0.6 else "acqua affidabile a distanza" if a > 0.2 else "solo acqua stagionale" if s > 0.6 else "acqua lontana")
		if c["bosco"]:
			parti.append("bosco")
	var v: float = c["velocita"]
	if v > 0.0 and (not c["edificabile"] or modo == 4):
		parti.append("corrente %s m/s" % String.num(v, 1).replace(".", ","))
		parti.append("%s kW ogni 100 m" % String.num(c["potenza_kw"], 0 if c["potenza_kw"] >= 10.0 else 1).replace(".", ","))
		var k: int = c["tipo"] - MappaDati.FIUME
		if not c["edificabile"] and k >= 0 and k < dati.corsi_acqua.size():
			parti.append(dati.corsi_acqua[k]["regime"])
	if uso:
		var s_uso := uso.stato(x, z)
		if s_uso != UsoSuolo.NATURALE:
			parti.append(UsoSuolo.NOMI_STATO[s_uso] + (" da %d anni" % uso.anni_libero(x, z) if s_uso == UsoSuolo.LIBERO else ""))
		if uso.memoria_bosco(x, z):
			parti.append("ex area boschiva")
	return " · ".join(parti)


func _exit_tree() -> void:
	if vista_alberi:
		vista_alberi.aspetta()
	if alberi:
		alberi.interrompi()
	if _salvataggio_alberi >= 0:
		WorkerThreadPool.wait_for_task_completion(_salvataggio_alberi)
