extends SceneTree
## Verifiche sull'uso del suolo (disboscamento, ricrescita, costruzioni), senza grafica.
## Controlla le regole di Fede del 24/11/2026 (vedi UsoSuolo).
## Uso: godot --headless --path gioco -s res://test/verifica_uso_suolo.gd

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


## Un punto in mezzo a un bosco fitto, lontano dall'acqua, a partire da `da`.
func _bosco_fitto(a: Alberi, da: Vector2, evita: Array = []) -> Vector2:
	var lato := a.dati.lato_metri()
	for z in range(int(da.y), int(lato) - 400, 97):
		for x in range(int(da.x), int(lato) - 400, 97):
			if x < 400 or z < 400:
				continue
			var lontano := true
			for e in evita:
				lontano = lontano and Vector2(x, z).distance_to(e) > 700.0
			if not lontano:
				continue
			var ok := true
			for r in [0.0, 120.0, 240.0, 320.0]:
				for k in 8:
					var p: Vector2 = Vector2(x, z) + Vector2(cos(k * TAU / 8.0), sin(k * TAU / 8.0)) * r
					if a.valore_bosco(p.x, p.y) < 0.6 or a.distanza_acqua(p.x, p.y) < 60.0:
						ok = false
			if ok:
				return Vector2(x, z)
	return Vector2(-1, -1)


## Alberi visibili (fattore > 0) con il centro di cella dentro il cerchio.
func _alberi_nel_cerchio(a: Alberi, u: UsoSuolo, c: Vector2, r: float) -> int:
	var conta := 0
	var k := Alberi.CAMPI
	var b0 := Vector2i(floori((c.x - r - 20.0) / Alberi.LATO_BLOCCO), floori((c.y - r - 20.0) / Alberi.LATO_BLOCCO))
	var b1 := Vector2i(floori((c.x + r + 20.0) / Alberi.LATO_BLOCCO), floori((c.y + r + 20.0) / Alberi.LATO_BLOCCO))
	for bz in range(b0.y, b1.y + 1):
		for bx in range(b0.x, b1.x + 1):
			var arr := a.alberi_nel_blocco(Vector2i(bx, bz))
			for t in arr.size() / k:
				var x := arr[t * k]
				var z := arr[t * k + 1]
				if u.centro(u.cella(x, z)).distance_to(c) <= r and u.fattore_albero(x, z, int(arr[t * k + 4]), (arr[t * k + 5] - 0.84) / 0.24) > 0.0:
					conta += 1
	return conta


func _process(_d: float) -> bool:
	_f += 1
	if _f < 3:
		return false
	var a: Alberi = _s.alberi
	var u: UsoSuolo = _s.uso
	var v: VistaAlberi = _s.vista_alberi
	controlla(u != null and v.uso == u, "uso del suolo creato e collegato alla vista")
	controlla(not UsoSuolo.invasiva("casa_lunga") and not UsoSuolo.invasiva("sentiero") and UsoSuolo.invasiva("strada_asfaltata"), "l'invasività viene dai materiali: casa lunga e sentiero no, strada asfaltata sì")
	var p := _bosco_fitto(a, Vector2.ZERO)
	controlla(p.x > 0.0, "trovato un bosco fitto per le prove (%d, %d)" % [p.x, p.y])
	if p.x < 0.0:
		quit(1)
		return true
	# Vista centrata sul bosco, alberi completi.
	var cam: CameraIsometrica = _s.cam
	cam.vai_a(p.x, p.y, 180.0)
	v.aggiorna(-1)
	var prima_vista := v.alberi_visibili
	# 1. Taglio di una parte del bosco.
	var dentro := _alberi_nel_cerchio(a, u, p, 150.0)
	var tagliati := u.abbatti(u.celle_nel_cerchio(p.x, p.y, 150.0))
	controlla(tagliati == dentro and tagliati > 100, "abbattere restituisce il legname: %d alberi tagliati" % tagliati)
	controlla(_alberi_nel_cerchio(a, u, p, 150.0) == 0, "nell'area tagliata non resta nessun albero")
	controlla(u.stato(p.x, p.y) == UsoSuolo.LIBERO and u.memoria_bosco(p.x, p.y), "l'area è libera e ricorda di essere stata un bosco")
	v.aggiorna(-1)
	controlla(v.alberi_visibili < prima_vista, "la vista disegna meno alberi (%d → %d)" % [prima_vista, v.alberi_visibili])
	var px := u.immagine.get_pixel(u.cella(p.x, p.y).x, u.cella(p.x, p.y).y)
	controlla(px.r < 0.01 and px.g > 0.99, "il terreno mostra terra nuda e niente bosco dipinto")
	# 2. Ricrescita dai margini: dopo 20 anni il bordo cresce, il centro aspetta ancora i semi.
	u.avanza_anni(20)
	var bordo := p + Vector2(140.0, 0.0)
	controlla(u.anni_libero(bordo.x, bordo.y) >= 19, "al margine il bosco ricresce (%d anni)" % u.anni_libero(bordo.x, bordo.y))
	controlla(u.anni_libero(p.x, p.y) == 0, "al centro, lontano dai semi, non ancora")
	px = u.immagine.get_pixel(u.cella(bordo.x, bordo.y).x, u.cella(bordo.x, bordo.y).y)
	controlla(px.g < 0.01, "dopo qualche anno la terra nuda è tornata prato")
	var giovani := _alberi_nel_cerchio(a, u, p, 150.0)
	controlla(giovani > 0 and giovani < dentro, "dopo 20 anni ci sono alberi giovani (%d su %d)" % [giovani, dentro])
	u.avanza_anni(130)
	controlla(u.stato(p.x, p.y) == UsoSuolo.NATURALE and u.memoria_bosco(p.x, p.y), "dopo 150 anni il bosco è tornato, con la memoria del taglio")
	controlla(_alberi_nel_cerchio(a, u, p, 150.0) == dentro, "tornano tutti gli alberi (%d)" % dentro)
	# 3. Nessun albero attorno: niente ricrescita. Attorno all'area si sigilla una fascia.
	var q := _bosco_fitto(a, p + Vector2(800.0, 800.0))
	controlla(q.x > 0.0, "trovato un secondo bosco (%d, %d)" % [q.x, q.y])
	var fascia: Array[Vector2i] = []
	for c in u.celle_nel_cerchio(q.x, q.y, 240.0):
		if u.centro(c).distance_to(q) > 120.0:
			fascia.append(c)
	u.costruisci(fascia, "strada_asfaltata")
	u.abbatti(u.celle_nel_cerchio(q.x, q.y, 120.0))
	u.avanza_anni(100)
	controlla(u.stato(q.x, q.y) == UsoSuolo.LIBERO and u.anni_libero(q.x, q.y) == 0, "senza alberi attorno l'area non ricresce")
	var f2 := u.centro(fascia[0])
	controlla(u.stato(f2.x, f2.y) == UsoSuolo.SIGILLATO and u.memoria_bosco(f2.x, f2.y), "la fascia sigillata ricorda di essere stata un bosco")
	u.libera(fascia)
	u.avanza_anni(100)
	controlla(u.stato(f2.x, f2.y) == UsoSuolo.SIGILLATO and _alberi_nel_cerchio(a, u, q, 240.0) == 0, "una strada asfaltata (materiali invasivi) sigilla il suolo: niente più alberi, nemmeno togliendola")
	# 4. Costruzione non invasiva tolta: si torna alla condizione di prima.
	var r := _bosco_fitto(a, Vector2(400.0, p.y + 1200.0), [p, q])
	controlla(r.x > 0.0, "trovato un terzo bosco (%d, %d)" % [r.x, r.y])
	var capanna := u.celle_nel_cerchio(r.x, r.y, 30.0)
	var prima := _alberi_nel_cerchio(a, u, r, 30.0)
	u.costruisci(capanna, "casa_lunga")
	controlla(u.stato(r.x, r.y) == UsoSuolo.COSTRUITO and _alberi_nel_cerchio(a, u, r, 30.0) == 0, "una casa lunga (legno e argilla) toglie gli alberi")
	u.avanza_anni(40)
	controlla(u.stato(r.x, r.y) == UsoSuolo.COSTRUITO, "finché la casa c'è, non ricresce nulla")
	u.libera(capanna)
	u.avanza_anni(80)
	controlla(u.stato(r.x, r.y) == UsoSuolo.NATURALE and _alberi_nel_cerchio(a, u, r, 30.0) == prima, "tolta la casa, il bosco torna com'era (%d alberi)" % prima)
	# 5. Campi su un ex bosco: liberi finché coltivati; abbandonati ricrescono.
	u.coltiva(capanna)
	u.avanza_anni(30)
	controlla(u.stato(r.x, r.y) == UsoSuolo.COLTIVATO and _alberi_nel_cerchio(a, u, r, 30.0) == 0, "i campi restano liberi dagli alberi")
	controlla(u.tecnica(r.x, r.y) == 0, "un campo del villaggio è lavorato a zappa (tecnica 0)")
	u.coltiva(capanna, 3)
	controlla(u.tecnica(r.x, r.y) == 3 and u.stato(r.x, r.y) == UsoSuolo.COLTIVATO, "ammodernare un campo ne cambia solo la tecnica")
	u.coltiva(capanna, 0)
	# 6. Prato senza bosco: gli alberi sparsi tagliati non tornano da soli.
	var prato := Vector2(-1, -1)
	for z in range(1000, 9000, 53):
		for x in range(1000, 9000, 53):
			if prato.x < 0.0 and a.valore_bosco(x, z) < 0.1 and a.distanza_acqua(x, z) > 200.0 and u.stato(x, z) == UsoSuolo.NATURALE:
				prato = Vector2(x, z)
	u.abbatti(u.celle_nel_cerchio(prato.x, prato.y, 60.0))
	u.avanza_anni(100)
	controlla(not u.memoria_bosco(prato.x, prato.y) and u.stato(prato.x, prato.y) == UsoSuolo.LIBERO, "su un prato il taglio non lascia memoria di bosco e non ricresce")
	print("Verifica completata: " + ("nessun errore" if _errori == 0 else "%d errori" % _errori))
	quit(1 if _errori > 0 else 0)
	return true
