class_name Alberi
extends RefCounted
## Alberi della mappa come dati di gioco (decisione di Fede, 23/11/2026: gli alberi non sono decorazione).
##
## Dove stanno i boschi lo dice il campo bosco_fine della mappa (10 m, 0,5 = margine), lo stesso
## che usa lo shader del terreno: il bordo dipinto da lontano e gli alberi veri da vicino coincidono.
## Gli alberi si calcolano per blocchi quadrati, in modo deterministico (stesso luogo, stessi alberi),
## e restano in memoria una volta calcolati. Fuori dal bosco: alberi sparsi, lungo i corsi d'acqua,
## ai margini dei boschi, qualche arbusto sui gessi. Nelle paludi nessun albero (richiesta di Fede).
##
## Da fare (in coda nel diario): aree disboscate modificabili durante il gioco, che tolgono gli
## alberi e cambiano il suolo; ricrescita per stadi.

const LATO_BLOCCO := 320.0
## Distanza media tra gli alberi nel bosco chiuso (le chiome sono larghe 7–13 m).
const PASSO_BOSCO := 7.0
## Griglia dei candidati per gli alberi sparsi fuori dal bosco.
const PASSO_SPARSI := 20.0
## Modelli in gioco/asset/alberi/ (ognuno ha anche la versione _leggero).
const MODELLI := ["quercia_1", "quercia_2", "quercia_3", "carpino_1", "carpino_2", "pioppo_1", "pioppo_2", "cespuglio_1", "cespuglio_2", "canna_1", "canna_2"]
const QUERCIA := 0
const CARPINO := 1
const PIOPPO := 2
const CESPUGLIO := 3
const CANNA := 4
const NOMI_SPECIE := ["quercia", "carpino", "pioppo", "cespuglio", "canna"]
## Primo modello e numero di varianti di ogni specie dentro MODELLI.
const VARIANTI := [[0, 3], [3, 2], [5, 2], [7, 2], [9, 2]]
## Primo modello che non è un albero (arbusti e canne): escluso dalle sagome rade.
const PRIMO_MINORE := 7
## Canneti: distanza media tra un ciuffo e l'altro.
const PASSO_CANNE := 3.5
## Valori per albero nell'array restituito da alberi_nel_blocco.
const CAMPI := 7  # x, z, rotazione, scala, modello, tinta, quota del suolo (m, senza esagerazione)

var dati: MappaDati
var _cache := {}
var _mutex := Mutex.new()
var _compito := -1
var _ordine: Array = []


func _init(d: MappaDati) -> void:
	dati = d


## Calcola in sottofondo (su un altro thread) gli alberi di tutti i blocchi, dal più vicino al
## punto indicato: quando la vista li chiede sono già pronti.
func calcola_in_sottofondo(x: float, z: float) -> void:
	var nb := int(ceil(dati.lato_metri() / LATO_BLOCCO))
	_ordine = []
	for bz in nb:
		for bx in nb:
			_ordine.append(Vector2i(bx, bz))
	var c := Vector2(x, z) / LATO_BLOCCO
	_ordine.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return (Vector2(a) + Vector2(0.5, 0.5)).distance_squared_to(c) < (Vector2(b) + Vector2(0.5, 0.5)).distance_squared_to(c))
	_compito = WorkerThreadPool.add_task(_calcola_tutti, false, "Alberi della mappa")


func _calcola_tutti() -> void:
	for b in _ordine:
		alberi_nel_blocco(b)


## Attende la fine del calcolo in sottofondo (da chiamare prima di chiudere).
func aspetta() -> void:
	if _compito >= 0:
		WorkerThreadPool.wait_for_task_completion(_compito)
		_compito = -1


func pronto(b: Vector2i) -> bool:
	_mutex.lock()
	var esito := _cache.has(b)
	_mutex.unlock()
	return esito


## Alberi del blocco (bx, bz): array piatto di CAMPI valori per albero.
## Si può chiamare da più thread: il risultato si calcola una volta e resta in memoria.
func alberi_nel_blocco(b: Vector2i) -> PackedFloat32Array:
	_mutex.lock()
	if _cache.has(b):
		var pronto_ora: PackedFloat32Array = _cache[b]
		_mutex.unlock()
		return pronto_ora
	_mutex.unlock()
	var out := _calcola_blocco(b)
	_mutex.lock()
	_cache[b] = out
	_mutex.unlock()
	return out


func _calcola_blocco(b: Vector2i) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var x0 := b.x * LATO_BLOCCO
	var z0 := b.y * LATO_BLOCCO
	var lato_m := dati.lato_metri()
	# Bosco: griglia mossa a caso, così gli alberi non stanno in file.
	var n := int(LATO_BLOCCO / PASSO_BOSCO)
	var gx0 := int(round(x0 / PASSO_BOSCO))
	var gz0 := int(round(z0 / PASSO_BOSCO))
	for j in n:
		for i in n:
			var gx := gx0 + i
			var gz := gz0 + j
			var x := (gx + 0.5 + (_caso(gx, gz, 1) - 0.5) * 0.8) * PASSO_BOSCO
			var z := (gz + 0.5 + (_caso(gx, gz, 2) - 0.5) * 0.8) * PASSO_BOSCO
			if x < 0.0 or z < 0.0 or x > lato_m or z > lato_m:
				continue
			var v := valore_bosco(x, z)
			if v < 0.5 or distanza_acqua(x, z) < 4.0 or _in_palude(x, z):
				continue
			# Al margine il bosco si dirada e crescono più arbusti; dentro, qualche radura.
			var interno := clampf((v - 0.5) / 0.12, 0.0, 1.0)
			if _caso(gx, gz, 3) < 0.05 + 0.3 * (1.0 - interno):
				continue
			var specie := _specie_bosco(x, z, interno, _caso(gx, gz, 4), _caso(gx, gz, 9), _caso(gx, gz, 10))
			_aggiungi(out, x, z, specie, gx, gz)
	# Fuori dal bosco: alberi sparsi.
	var m := int(LATO_BLOCCO / PASSO_SPARSI)
	var sx0 := int(round(x0 / PASSO_SPARSI))
	var sz0 := int(round(z0 / PASSO_SPARSI))
	for j in m:
		for i in m:
			var gx := sx0 + i
			var gz := sz0 + j
			var x := (gx + 0.5 + (_caso(gx, gz, 11) - 0.5) * 0.9) * PASSO_SPARSI
			var z := (gz + 0.5 + (_caso(gx, gz, 12) - 0.5) * 0.9) * PASSO_SPARSI
			if x < 0.0 or z < 0.0 or x > lato_m or z > lato_m:
				continue
			if valore_bosco(x, z) >= 0.5:
				continue
			var specie := _specie_sparsa(x, z, _caso(gx, gz, 13), _caso(gx, gz, 14))
			if specie >= 0:
				_aggiungi(out, x, z, specie, gx + 100000, gz)
	_canneti(out, x0, z0)
	return out


## Canneti: fitti nella fascia attorno alle pozze delle paludi (anche con i piedi nell'acqua al
## bordo), radi nel resto della palude, a tratti lungo le rive basse dei fiumi in pianura.
func _canneti(out: PackedFloat32Array, x0: float, z0: float) -> void:
	# Prima un controllo rapido: niente palude e niente acqua nel blocco, niente canne.
	var c_e := false
	for j in 9:
		for i in 9:
			var x := x0 + i * LATO_BLOCCO / 8.0
			var z := z0 + j * LATO_BLOCCO / 8.0
			if _campiona_fine(dati.palude_fine, x, z) > 100.0 or absf(distanza_acqua(x, z)) < 60.0:
				c_e = true
	if not c_e:
		return
	var lato_m := dati.lato_metri()
	var n := int(LATO_BLOCCO / PASSO_CANNE)
	var gx0 := int(round(x0 / PASSO_CANNE))
	var gz0 := int(round(z0 / PASSO_CANNE))
	for j in n:
		for i in n:
			var gx := gx0 + i + 300000
			var gz := gz0 + j
			var x := (gx - 300000 + 0.5 + (_caso(gx, gz, 21) - 0.5) * 0.9) * PASSO_CANNE
			var z := (gz + 0.5 + (_caso(gx, gz, 22) - 0.5) * 0.9) * PASSO_CANNE
			if x < 0.0 or z < 0.0 or x > lato_m or z > lato_m:
				continue
			var p := 0.0
			var v_pal := _campiona_fine(dati.palude_fine, x, z) / 255.0
			if v_pal > 0.5:
				var v_poz := _campiona_fine(dati.pozze_fine, x, z) / 255.0
				if v_poz > 0.55:
					p = 0.0
				elif v_poz > 0.5:
					p = 0.65
				elif v_poz > 0.3:
					p = 0.9
				else:
					p = 0.15
			else:
				var d := distanza_acqua(x, z)
				if d > -3.0 and d < 5.0 and dati.zona[_indice(x, z)] < 3 and valore_bosco(x, z) < 0.5:
					# A tratti: un rumore lento decide dove la riva ha il canneto.
					p = 0.6 * smoothstep(0.45, 0.6, _campiona_fine(dati.pozze_fine, x * 0.37 + 900.0, z * 0.37 + 700.0) / 255.0 + 0.2)
			if p > 0.0 and _caso(gx, gz, 23) < p:
				_aggiungi(out, x, z, CANNA, gx, gz)


## Quanto il punto è dentro il bosco (0,5 = margine): bilineare su bosco_fine, come lo shader.
func valore_bosco(x: float, z: float) -> float:
	return _campiona_fine(dati.bosco_fine, x, z) / 255.0


## Distanza dalla riva in metri (negativa dentro l'acqua), come la legge lo shader.
func distanza_acqua(x: float, z: float) -> float:
	return (_campiona_fine(dati.distanza_acqua, x, z) - 128.0) * 2.0


func numero_alberi(b: Vector2i) -> int:
	return alberi_nel_blocco(b).size() / CAMPI


# ---------- scelta della specie (proposta di Claude, da confermare con Fede) ----------

## Bosco: querco-carpineto in pianura, querce e carpini sulle colline, pioppi dove è umido,
## arbusti al margine.
func _specie_bosco(x: float, z: float, interno: float, r: float, r1: float, r2: float) -> int:
	# Le fasce della mappa hanno confini netti: si leggono in un punto spostato a caso fino a
	# 80 m, così i passaggi tra un bosco e l'altro sono sfrangiati e non seguono linee dritte.
	var i := _indice(x + (r1 - 0.5) * 160.0, z + (r2 - 0.5) * 160.0)
	var umido := distanza_acqua(x, z) < 40.0 + 50.0 * r1 or dati.acqua_stagionale[i] > 191 or dati.zona[i] == 0
	var pesi: Array
	if umido and dati.zona[i] == 3:
		# Valli dei torrenti in collina: qualche pioppo lungo l'acqua, ma restano querce e carpini.
		pesi = [0.4, 0.25, 0.15, 0.2]
	elif umido:
		pesi = [0.22, 0.06, 0.52, 0.2]
	elif dati.zona[i] == 3:
		pesi = [0.58, 0.3, 0.0, 0.12]
	else:
		pesi = [0.45, 0.43, 0.02, 0.1]
	pesi[CESPUGLIO] += 0.6 * (1.0 - interno)
	return _pesca(pesi, r)


## Fuori dal bosco: filari lungo l'acqua, arbusti ai margini dei boschi, querce isolate.
## Restituisce -1 se nel punto non cresce nulla.
func _specie_sparsa(x: float, z: float, r_c: float, r_s: float) -> int:
	var d := distanza_acqua(x, z)
	if d < 3.0:
		return -1
	var i := _indice(x, z)
	var v := valore_bosco(x, z)
	var p := 0.012
	var pesi := [0.7, 0.15, 0.0, 0.15]
	if d < 25.0:
		p = 0.45
		pesi = [0.05, 0.0, 0.6, 0.35]
	elif d < 45.0:
		p = 0.1
		pesi = [0.2, 0.0, 0.5, 0.3]
	elif v > 0.38:
		p = 0.22
		pesi = [0.35, 0.1, 0.0, 0.55]
	elif _in_palude(x, z):
		# Niente alberi nelle paludi (richiesta di Fede).
		return -1
	elif dati.tipo[i] == MappaDati.GESSI:
		p = 0.03
		pesi = [0.1, 0.0, 0.0, 0.9]
	elif dati.acqua_stagionale[i] > 191:
		pesi = [0.4, 0.1, 0.35, 0.15]
	if r_c >= p:
		return -1
	return _pesca(pesi, r_s)


## Palude: il punto o un vicino entro 30 m sta in una cella di palude (lo shader ne allarga
## il bordo con il rumore, quindi si tiene un margine).
func _in_palude(x: float, z: float) -> bool:
	for o in [Vector2.ZERO, Vector2(30, 0), Vector2(-30, 0), Vector2(0, 30), Vector2(0, -30)]:
		if dati.tipo[_indice(x + o.x, z + o.y)] == MappaDati.PALUDE:
			return true
	return false


func _indice(x: float, z: float) -> int:
	var p := dati.pixel_da_mondo(x, z)
	return dati.indice(p.x, p.y)


func _pesca(pesi: Array, r: float) -> int:
	var tot := 0.0
	for w in pesi:
		tot += w
	var t := r * tot
	for k in pesi.size():
		t -= pesi[k]
		if t < 0.0:
			return k
	return pesi.size() - 1


func _aggiungi(out: PackedFloat32Array, x: float, z: float, specie: int, gx: int, gz: int) -> void:
	var v: Array = VARIANTI[specie]
	var modello: int = v[0] + mini(int(_caso(gx, gz, 5) * v[1]), v[1] - 1)
	# Alberi da bosco maturo: i modelli sono alti 10–18 m, qui diventano 10–24 m.
	var scala := 0.95 + 0.4 * _caso(gx, gz, 6)
	if specie == CESPUGLIO:
		scala = 0.75 + 0.5 * _caso(gx, gz, 6)
	elif specie == CANNA:
		scala = 0.9 + 0.6 * _caso(gx, gz, 6)
	out.append(x)
	out.append(z)
	out.append(_caso(gx, gz, 7) * TAU)
	out.append(scala)
	out.append(modello)
	out.append(0.84 + 0.24 * _caso(gx, gz, 8))
	out.append(dati.quota(x, z))


## Bilineare su una griglia fine (lato_acqua x lato_acqua) con la stessa corrispondenza dello
## shader: il texel k ha il centro nel punto 10 k - 15 m.
func _campiona_fine(strato: PackedByteArray, x: float, z: float) -> float:
	var n := dati.lato_acqua
	var passo := dati.metri_per_px * dati.lato / float(n)
	var fx := clampf((x + 1.5 * passo) / passo, 0.0, n - 1.001)
	var fz := clampf((z + 1.5 * passo) / passo, 0.0, n - 1.001)
	var ix := int(fx)
	var iz := int(fz)
	var tx := fx - ix
	var tz := fz - iz
	var i := iz * n + ix
	var a := lerpf(strato[i], strato[i + 1], tx)
	var b := lerpf(strato[i + n], strato[i + n + 1], tx)
	return lerpf(a, b, tz)


## Numero pseudo-casuale in [0, 1) legato a un punto della griglia e a un uso (sale).
static func _caso(a: int, b: int, sale: int) -> float:
	var h := (a * 73856093) ^ (b * 19349663) ^ (sale * 83492791)
	h &= 0x7fffffff
	h = ((h >> 13) ^ h) * 1274126177 & 0x7fffffff
	h = ((h >> 16) ^ h) * 45679 & 0x7fffffff
	return float(h & 0xffffff) / 16777216.0
