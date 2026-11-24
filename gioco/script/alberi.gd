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
## Velocità (24/11/2026): il calcolo salta in blocco le zone dove di sicuro non cresce nulla
## (riquadri di candidati controllati sui valori grezzi dei campi) e gira su tutti i processori.
## Il risultato è identico, albero per albero, a quello del calcolo completo. Finito il primo
## calcolo, gli alberi si salvano nella cartella dei dati dell'utente (user://cache/): dagli avvii
## successivi si caricano in una frazione di secondo. La cache si scarta da sola se cambiano la
## mappa o questo script (impronta nell'intestazione, più alcuni blocchi ricalcolati e confrontati).
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
## Formato del file di cache (da aumentare se cambia il modo di scriverlo).
const VERSIONE_CACHE := 1
## Blocchi ricalcolati a ogni caricamento della cache per controllarla.
const BLOCCHI_CONTROLLO := [Vector2i(16, 16), Vector2i(6, 26), Vector2i(26, 6), Vector2i(10, 28), Vector2i(3, 3)]
## Lato (in candidati) dei riquadri controllati in blocco prima di provare i singoli candidati.
const RIQUADRO := 8

var dati: MappaDati
var _cache := {}
var _mutex := Mutex.new()
var _compito := -1
var _ordine: Array = []
var _prossimo := 0
var _ferma := false
# Costanti della mappa lette una volta (i calcoli girano su più thread, solo in lettura).
var _n_fine := 0
var _passo_fine := 10.0
var _lato_px := 0
var _mpp := 40.0


func _init(d: MappaDati) -> void:
	dati = d
	_n_fine = d.lato_acqua
	_passo_fine = d.metri_per_px * d.lato / float(d.lato_acqua)
	_lato_px = d.lato
	_mpp = d.metri_per_px


## Calcola in sottofondo (su tutti i processori) gli alberi di tutti i blocchi, dal più vicino
## al punto indicato: quando la vista li chiede sono già pronti.
func calcola_in_sottofondo(x: float, z: float) -> void:
	var nb := int(ceil(dati.lato_metri() / LATO_BLOCCO))
	_ordine = []
	for bz in nb:
		for bx in nb:
			_ordine.append(Vector2i(bx, bz))
	var c := Vector2(x, z) / LATO_BLOCCO
	_ordine.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return (Vector2(a) + Vector2(0.5, 0.5)).distance_squared_to(c) < (Vector2(b) + Vector2(0.5, 0.5)).distance_squared_to(c))
	aspetta()
	_prossimo = 0
	_ferma = false
	# Un compito per processore meno uno, che resta libero per i blocchi chiesti dalla vista.
	var fette := maxi(1, OS.get_processor_count() - 1)
	_compito = WorkerThreadPool.add_group_task(_calcola_fetta, fette, fette, true, "Alberi della mappa")


## Un compito in sottofondo: prende il prossimo blocco della coda finché la coda non finisce.
## Lavora su una copia propria dei dati della mappa: i thread che leggono gli stessi array si
## rallentano a vicenda (ogni lettura aggiorna un contatore condiviso).
func _calcola_fetta(_k: int) -> void:
	var calcolatore := Alberi.new(_copia_dati())
	while true:
		_mutex.lock()
		var i := _prossimo
		_prossimo += 1
		var fine := _ferma or i >= _ordine.size()
		var b := Vector2i.ZERO if fine else (_ordine[i] as Vector2i)
		var gia := not fine and _cache.has(b)
		_mutex.unlock()
		if fine:
			return
		if gia:
			continue
		var out := calcolatore._calcola_blocco(b)
		_mutex.lock()
		if not _cache.has(b):
			_cache[b] = out
		_mutex.unlock()


## Copia dei dati della mappa usati dagli alberi, con array propri (non condivisi).
func _copia_dati() -> MappaDati:
	var c := MappaDati.new()
	c.nome = dati.nome
	c.lato = dati.lato
	c.metri_per_px = dati.metri_per_px
	c.quota_min = dati.quota_min
	c.quota_max = dati.quota_max
	c.lato_acqua = dati.lato_acqua
	for campo in ["altezze", "tipo", "zona", "acqua_stagionale", "distanza_acqua", "bosco_fine", "palude_fine", "pozze_fine"]:
		var a: Variant = dati.get(campo).duplicate()
		# Scrivere un elemento obbliga Godot a fare una copia vera, non condivisa.
		a.set(0, a[0])
		c.set(campo, a)
	return c


# ---------- cache su disco ----------

func _percorso_cache() -> String:
	return "user://cache/alberi_%s.bin" % dati.nome.to_lower().validate_filename()


## Impronta di ciò da cui dipendono gli alberi: questo script e il file della mappa.
func _impronta() -> String:
	var h := HashingContext.new()
	h.start(HashingContext.HASH_MD5)
	var codice := (get_script() as GDScript).source_code
	h.update(("v%d|%s|" % [VERSIONE_CACHE, codice]).to_utf8_buffer())
	if dati.resource_path != "":
		h.update(FileAccess.get_md5(dati.resource_path).to_utf8_buffer())
	return h.finish().hex_encode()


## Carica gli alberi di tutta la mappa dalla cache. Falso se manca o non è più valida.
func carica_cache() -> bool:
	var percorso := _percorso_cache()
	if not FileAccess.file_exists(percorso):
		return false
	var f := FileAccess.open_compressed(percorso, FileAccess.READ, FileAccess.COMPRESSION_ZSTD)
	if f == null:
		return false
	var nb := int(ceil(dati.lato_metri() / LATO_BLOCCO))
	if f.get_pascal_string() != _impronta() or f.get_32() != nb:
		return false
	var letti := {}
	for bz in nb:
		for bx in nb:
			var n := f.get_32()
			if f.eof_reached() and n > 0:
				return false
			letti[Vector2i(bx, bz)] = f.get_buffer(n * 4).to_float32_array() if n > 0 else PackedFloat32Array()
	if f.get_error() != OK and f.get_error() != ERR_FILE_EOF:
		return false
	for b in BLOCCHI_CONTROLLO:
		if letti.has(b) and letti[b] != _calcola_blocco(b):
			return false
	_mutex.lock()
	_cache = letti
	_mutex.unlock()
	return true


## Salva gli alberi di tutta la mappa nella cache (solo se sono tutti calcolati). Da chiamare
## su un altro thread: comprime circa 25 MB.
func salva_cache() -> bool:
	var nb := int(ceil(dati.lato_metri() / LATO_BLOCCO))
	_mutex.lock()
	var copia := _cache.duplicate()
	_mutex.unlock()
	if copia.size() < nb * nb:
		return false
	DirAccess.make_dir_recursive_absolute("user://cache")
	var temporaneo := _percorso_cache() + ".tmp"
	var f := FileAccess.open_compressed(temporaneo, FileAccess.WRITE, FileAccess.COMPRESSION_ZSTD)
	if f == null:
		return false
	f.store_pascal_string(_impronta())
	f.store_32(nb)
	for bz in nb:
		for bx in nb:
			var arr: PackedFloat32Array = copia[Vector2i(bx, bz)]
			f.store_32(arr.size())
			if not arr.is_empty():
				f.store_buffer(arr.to_byte_array())
	f.close()
	DirAccess.remove_absolute(_percorso_cache())
	return DirAccess.rename_absolute(temporaneo, _percorso_cache()) == OK


## Cancella la cache (per le prove).
func cancella_cache() -> void:
	DirAccess.remove_absolute(_percorso_cache())


## Interrompe il calcolo in sottofondo (per chiudere il gioco senza aspettare tutta la mappa).
func interrompi() -> void:
	_mutex.lock()
	_ferma = true
	_mutex.unlock()
	aspetta()


## Attende la fine del calcolo in sottofondo.
func aspetta() -> void:
	if _compito >= 0:
		WorkerThreadPool.wait_for_group_task_completion(_compito)
		_compito = -1


## Vero se il calcolo in sottofondo di tutta la mappa è finito.
func tutto_pronto() -> bool:
	return _compito < 0 or WorkerThreadPool.is_group_task_completed(_compito)


## Dimentica gli alberi calcolati (per le misure dei tempi).
func svuota() -> void:
	aspetta()
	_mutex.lock()
	_cache.clear()
	_mutex.unlock()


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
	# Riquadri dove nessun candidato può cadere nel bosco (valore 0,5 = 127,5 sui dati grezzi).
	var nr := ceili(n / float(RIQUADRO))
	var bosco_r := PackedByteArray()
	bosco_r.resize(nr * nr)
	for tj in nr:
		for ti in nr:
			var xa := (gx0 + ti * RIQUADRO) * PASSO_BOSCO
			var za := (gz0 + tj * RIQUADRO) * PASSO_BOSCO
			var xb := (gx0 + mini((ti + 1) * RIQUADRO, n)) * PASSO_BOSCO
			var zb := (gz0 + mini((tj + 1) * RIQUADRO, n)) * PASSO_BOSCO
			bosco_r[tj * nr + ti] = 1 if _massimo_fine(dati.bosco_fine, xa, za, xb, zb) >= 128 else 0
	for j in n:
		var rj := floori(j / float(RIQUADRO)) * nr
		for ti in nr:
			if bosco_r[rj + ti] == 0:
				continue
			for i in range(ti * RIQUADRO, mini((ti + 1) * RIQUADRO, n)):
				_candidato_bosco(out, gx0 + i, gz0 + j, lato_m)
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


func _candidato_bosco(out: PackedFloat32Array, gx: int, gz: int, lato_m: float) -> void:
	var x := (gx + 0.5 + (_caso(gx, gz, 1) - 0.5) * 0.8) * PASSO_BOSCO
	var z := (gz + 0.5 + (_caso(gx, gz, 2) - 0.5) * 0.8) * PASSO_BOSCO
	if x < 0.0 or z < 0.0 or x > lato_m or z > lato_m:
		return
	var v := valore_bosco(x, z)
	if v < 0.5 or distanza_acqua(x, z) < 4.0 or _in_palude(x, z):
		return
	# Al margine il bosco si dirada e crescono più arbusti; dentro, qualche radura.
	var interno := clampf((v - 0.5) / 0.12, 0.0, 1.0)
	if _caso(gx, gz, 3) < 0.05 + 0.3 * (1.0 - interno):
		return
	var specie := _specie_bosco(x, z, interno, _caso(gx, gz, 4), _caso(gx, gz, 9), _caso(gx, gz, 10))
	_aggiungi(out, x, z, specie, gx, gz)


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
	# Riquadri dove nessun candidato può avere canne: né palude (valore > 127,5 sui dati grezzi)
	# né riva bassa (distanza tra -3 e 5 m, cioè tra 126,5 e 130,5 sui dati grezzi).
	var nr := ceili(n / float(RIQUADRO))
	var canne_r := PackedByteArray()
	canne_r.resize(nr * nr)
	for tj in nr:
		for ti in nr:
			var xa := (gx0 + ti * RIQUADRO) * PASSO_CANNE
			var za := (gz0 + tj * RIQUADRO) * PASSO_CANNE
			var xb := (gx0 + mini((ti + 1) * RIQUADRO, n)) * PASSO_CANNE
			var zb := (gz0 + mini((tj + 1) * RIQUADRO, n)) * PASSO_CANNE
			var puo := _massimo_fine(dati.palude_fine, xa, za, xb, zb) > 127
			if not puo:
				var dmin := _minimo_fine(dati.distanza_acqua, xa, za, xb, zb)
				var dmax := _massimo_fine(dati.distanza_acqua, xa, za, xb, zb)
				puo = dmax > 126 and dmin < 131
			canne_r[tj * nr + ti] = 1 if puo else 0
	for j in n:
		var rj := floori(j / float(RIQUADRO)) * nr
		for ti in nr:
			if canne_r[rj + ti] == 0:
				continue
			for i in range(ti * RIQUADRO, mini((ti + 1) * RIQUADRO, n)):
				_candidato_canna(out, gx0 + i + 300000, gz0 + j, lato_m)


func _candidato_canna(out: PackedFloat32Array, gx: int, gz: int, lato_m: float) -> void:
	var x := (gx - 300000 + 0.5 + (_caso(gx, gz, 21) - 0.5) * 0.9) * PASSO_CANNE
	var z := (gz + 0.5 + (_caso(gx, gz, 22) - 0.5) * 0.9) * PASSO_CANNE
	if x < 0.0 or z < 0.0 or x > lato_m or z > lato_m:
		return
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
	# Pesi di quercia, carpino, pioppo, cespuglio.
	var pq := 0.45
	var pc := 0.43
	var pp := 0.02
	var pa := 0.1
	if umido and dati.zona[i] == 3:
		# Valli dei torrenti in collina: qualche pioppo lungo l'acqua, ma restano querce e carpini.
		pq = 0.4; pc = 0.25; pp = 0.15; pa = 0.2
	elif umido:
		pq = 0.22; pc = 0.06; pp = 0.52; pa = 0.2
	elif dati.zona[i] == 3:
		pq = 0.58; pc = 0.3; pp = 0.0; pa = 0.12
	pa += 0.6 * (1.0 - interno)
	return _pesca4(pq, pc, pp, pa, r)


## Pesi delle specie fuori dal bosco (quercia, carpino, pioppo, cespuglio): campagna aperta,
## riva vicina, riva lontana, margine del bosco, gessi, terreno umido.
const PESI_SPARSI := [[0.7, 0.15, 0.0, 0.15], [0.05, 0.0, 0.6, 0.35], [0.2, 0.0, 0.5, 0.3], [0.35, 0.1, 0.0, 0.55], [0.1, 0.0, 0.0, 0.9], [0.4, 0.1, 0.35, 0.15]]


## Fuori dal bosco: filari lungo l'acqua, arbusti ai margini dei boschi, querce isolate.
## Restituisce -1 se nel punto non cresce nulla.
func _specie_sparsa(x: float, z: float, r_c: float, r_s: float) -> int:
	var d := distanza_acqua(x, z)
	if d < 3.0:
		return -1
	var i := _indice(x, z)
	var v := valore_bosco(x, z)
	var p := 0.012
	var pesi: Array = PESI_SPARSI[0]
	if d < 25.0:
		p = 0.45
		pesi = PESI_SPARSI[1]
	elif d < 45.0:
		p = 0.1
		pesi = PESI_SPARSI[2]
	elif v > 0.38:
		p = 0.22
		pesi = PESI_SPARSI[3]
	elif _in_palude(x, z):
		# Niente alberi nelle paludi (richiesta di Fede).
		return -1
	elif dati.tipo[i] == MappaDati.GESSI:
		p = 0.03
		pesi = PESI_SPARSI[4]
	elif dati.acqua_stagionale[i] > 191:
		pesi = PESI_SPARSI[5]
	if r_c >= p:
		return -1
	return _pesca(pesi, r_s)


## Palude: il punto o un vicino entro 30 m sta in una cella di palude (lo shader ne allarga
## il bordo con il rumore, quindi si tiene un margine).
func _in_palude(x: float, z: float) -> bool:
	var t := dati.tipo
	return t[_indice(x, z)] == MappaDati.PALUDE or t[_indice(x + 30.0, z)] == MappaDati.PALUDE \
		or t[_indice(x - 30.0, z)] == MappaDati.PALUDE or t[_indice(x, z + 30.0)] == MappaDati.PALUDE \
		or t[_indice(x, z - 30.0)] == MappaDati.PALUDE


## Come MappaDati.pixel_da_mondo + indice, senza oggetti intermedi.
func _indice(x: float, z: float) -> int:
	return clampi(roundi(z / _mpp), 0, _lato_px - 1) * _lato_px + clampi(roundi(x / _mpp), 0, _lato_px - 1)


## Come _pesca con quattro pesi, senza creare array (stessi conti nello stesso ordine).
func _pesca4(a: float, b: float, c: float, d: float, r: float) -> int:
	var t := r * (a + b + c + d)
	t -= a
	if t < 0.0:
		return 0
	t -= b
	if t < 0.0:
		return 1
	t -= c
	if t < 0.0:
		return 2
	return 3


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
	var n := _n_fine
	var passo := _passo_fine
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


## Valore grezzo massimo (o minimo) dei texel della griglia fine che _campiona_fine può usare per
## un punto qualunque del rettangolo (xa, za)–(xb, zb): la bilineare non esce da questo intervallo.
func _massimo_fine(strato: PackedByteArray, xa: float, za: float, xb: float, zb: float) -> int:
	var r := _texel_rettangolo(xa, za, xb, zb)
	var m := 0
	for iz in range(r.y, r.w + 1):
		var riga := iz * _n_fine
		for ix in range(r.x, r.z + 1):
			m = maxi(m, strato[riga + ix])
	return m


func _minimo_fine(strato: PackedByteArray, xa: float, za: float, xb: float, zb: float) -> int:
	var r := _texel_rettangolo(xa, za, xb, zb)
	var m := 255
	for iz in range(r.y, r.w + 1):
		var riga := iz * _n_fine
		for ix in range(r.x, r.z + 1):
			m = mini(m, strato[riga + ix])
	return m


func _texel_rettangolo(xa: float, za: float, xb: float, zb: float) -> Vector4i:
	var lim := _n_fine - 1.001
	var ia := int(clampf((xa + 1.5 * _passo_fine) / _passo_fine, 0.0, lim))
	var ib := int(clampf((xb + 1.5 * _passo_fine) / _passo_fine, 0.0, lim)) + 1
	var ja := int(clampf((za + 1.5 * _passo_fine) / _passo_fine, 0.0, lim))
	var jb := int(clampf((zb + 1.5 * _passo_fine) / _passo_fine, 0.0, lim)) + 1
	return Vector4i(ia, ja, ib, jb)


## Numero pseudo-casuale in [0, 1) legato a un punto della griglia e a un uso (sale).
static func _caso(a: int, b: int, sale: int) -> float:
	var h := (a * 73856093) ^ (b * 19349663) ^ (sale * 83492791)
	h &= 0x7fffffff
	h = ((h >> 13) ^ h) * 1274126177 & 0x7fffffff
	h = ((h >> 16) ^ h) * 45679 & 0x7fffffff
	return float(h & 0xffffff) / 16777216.0
