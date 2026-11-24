class_name UsoSuolo
extends RefCounted
## Uso del suolo modificabile durante il gioco, sulla griglia fine della mappa (10 m, la stessa
## di bosco_fine). Dice dove gli alberi della mappa (classe Alberi) restano, spariscono o
## ricrescono, e cosa dipinge lo shader del terreno al loro posto.
##
## Regole di Fede (24/11/2026):
## - un'area disboscata resta nella memoria come ex area boschiva;
## - se attorno ci sono ancora alberi (è stata tagliata una parte del bosco) e il terreno resta
##   libero, nel tempo nascono nuovi alberi;
## - se il terreno viene edificato con materiali non invasivi (capanna d'argilla, legno), quando
##   l'edificio viene tolto e il terreno lasciato libero si torna alla condizione di prima: gli
##   alberi possono rinascere;
## - se viene edificato con materiali invasivi (cemento, asfalto, fondamenta, fognature) l'area
##   non accoglie più alberi, ma resta in memoria che era un bosco;
## - gli effetti del taglio sono quelli naturali, come i vantaggi (legname, terreno libero).
##   Gli effetti sulla simulazione (erosione, piene, frane, selvaggina) arriveranno con il gioco.
##
## Tempi della ricrescita (proposta di Claude, da tarare): ceppi e terra nuda che si coprono
## d'erba in pochi anni; arbusti dopo 2–3 anni; alberi giovani dopo circa 8; il bosco torna
## maturo dopo 60 anni. Un'area in ricrescita fa da sorgente di semi dopo 15 anni, quindi il
## bosco si richiude dai margini verso l'interno.

const NATURALE := 0  ## come dice la mappa
const LIBERO := 1  ## alberi tolti, terreno libero
const COLTIVATO := 2  ## campi: terreno tenuto libero, non invasivo
const COSTRUITO := 3  ## edificato con materiali non invasivi (argilla, legno, paglia)
const SIGILLATO := 4  ## edificato con materiali invasivi: non accoglie più alberi
const NOMI_STATO := ["naturale", "libero", "coltivato", "costruito (non invasivo)", "sigillato (invasivo)"]
## Bit di memoria: la cella era un bosco (resta anche quando il bosco ricresce o è sigillato).
const MEMORIA_BOSCO := 0x80
const MASCHERA_STATO := 0x0f

const ANNI_ERBA := 6
const ANNI_SEME := 15
const ANNI_MATURO := 60
## Distanza massima (in celle da 10 m) da cui arrivano i semi.
const RAGGIO_SEMI := 6

var alberi: Alberi
var n := 0
var passo := 10.0
## Per cella: stato (bit bassi) + MEMORIA_BOSCO.
var celle := PackedByteArray()
## Per cella: anni da quando il terreno è libero (fino a 255).
var anni := PackedByteArray()
## Immagine per lo shader del terreno: R bosco presente (1 = come la mappa), G terra nuda o
## battuta, B campo, A superficie sigillata.
var immagine: Image
var texture: ImageTexture
## Celle libere con memoria di bosco ancora in ricrescita.
var _in_ricrescita := {}
## Blocchi di alberi (Alberi.LATO_BLOCCO) toccati da modifiche, uno per byte: si leggono anche
## dai thread della vista, quindi niente dizionari (scriverci mentre un altro thread legge non
## è sicuro).
var _toccati := PackedByteArray()
var _nb := 0
var _cambiati: Array[Vector2i] = []


func _init(a: Alberi) -> void:
	alberi = a
	n = a.dati.lato_acqua
	passo = a.dati.metri_per_px * a.dati.lato / float(n)
	celle.resize(n * n)
	anni.resize(n * n)
	immagine = Image.create(n, n, false, Image.FORMAT_RGBA8)
	immagine.fill(Color(1, 0, 0, 0))
	texture = ImageTexture.create_from_image(immagine)
	_nb = int(ceil(a.dati.lato_metri() / Alberi.LATO_BLOCCO))
	_toccati.resize(_nb * _nb)


# ---------- coordinate ----------

## Cella della griglia fine che contiene il punto (il texel k ha il centro in 10 k - 15 m).
func cella(x: float, z: float) -> Vector2i:
	return Vector2i(clampi(roundi((x + 1.5 * passo) / passo), 0, n - 1), clampi(roundi((z + 1.5 * passo) / passo), 0, n - 1))


func centro(c: Vector2i) -> Vector2:
	return Vector2(c.x * passo - 1.5 * passo, c.y * passo - 1.5 * passo)


func stato(x: float, z: float) -> int:
	var c := cella(x, z)
	return celle[c.y * n + c.x] & MASCHERA_STATO


func memoria_bosco(x: float, z: float) -> bool:
	var c := cella(x, z)
	return celle[c.y * n + c.x] & MEMORIA_BOSCO != 0


func anni_libero(x: float, z: float) -> int:
	var c := cella(x, z)
	return anni[c.y * n + c.x]


## Celle il cui centro sta nel cerchio.
func celle_nel_cerchio(cx: float, cz: float, raggio: float) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var a := cella(cx - raggio, cz - raggio)
	var b := cella(cx + raggio, cz + raggio)
	for j in range(a.y, b.y + 1):
		for i in range(a.x, b.x + 1):
			if centro(Vector2i(i, j)).distance_to(Vector2(cx, cz)) <= raggio:
				out.append(Vector2i(i, j))
	return out


# ---------- azioni ----------

## Abbatte gli alberi nelle celle. Restituisce quanti alberi e arbusti sono stati tagliati
## (il legname), contando solo quelli che erano in piedi.
func abbatti(lista: Array[Vector2i]) -> int:
	var tagliati := _conta_alberi_in_piedi(lista)
	for c in lista:
		var i := c.y * n + c.x
		var s := celle[i] & MASCHERA_STATO
		if s == NATURALE or s == LIBERO:
			_imposta(c, LIBERO, true)
	_aggiorna_immagine(lista)
	return tagliati


## Edifica: con materiali invasivi la cella è sigillata per sempre; altrimenti è costruita ma
## può tornare libera. In entrambi i casi gli alberi spariscono e la memoria del bosco resta.
func edifica(lista: Array[Vector2i], invasivo: bool) -> int:
	var tagliati := _conta_alberi_in_piedi(lista)
	for c in lista:
		var i := c.y * n + c.x
		if celle[i] & MASCHERA_STATO == SIGILLATO:
			continue
		_imposta(c, SIGILLATO if invasivo else COSTRUITO, true)
	_aggiorna_immagine(lista)
	return tagliati


## Campi: terreno tenuto libero dagli alberi finché è coltivato.
func coltiva(lista: Array[Vector2i]) -> int:
	var tagliati := _conta_alberi_in_piedi(lista)
	for c in lista:
		var s := celle[c.y * n + c.x] & MASCHERA_STATO
		if s == NATURALE or s == LIBERO:
			_imposta(c, COLTIVATO, true)
	_aggiorna_immagine(lista)
	return tagliati


## Toglie un edificio non invasivo o abbandona un campo: il terreno torna libero e, se era un
## bosco, può ricrescere. Le celle sigillate restano sigillate.
func libera(lista: Array[Vector2i]) -> void:
	for c in lista:
		var s := celle[c.y * n + c.x] & MASCHERA_STATO
		if s == COSTRUITO or s == COLTIVATO:
			_imposta(c, LIBERO, false)
	_aggiorna_immagine(lista)


## Fa passare il tempo: le celle libere con memoria di bosco ricrescono se attorno ci sono
## alberi che portano semi. Le celle senza semi vicini aspettano.
func avanza_anni(quanti: int) -> void:
	var toccate: Array[Vector2i] = []
	for _a in quanti:
		var crescono: Array[Vector2i] = []
		for c in _in_ricrescita.keys():
			if _semi_vicini(c):
				crescono.append(c)
		for c in crescono:
			var i: int = c.y * n + c.x
			var eta := mini(int(anni[i]) + 1, 255)
			anni[i] = eta
			if eta >= ANNI_MATURO:
				# Il bosco è tornato: la cella torna naturale, con la memoria del taglio.
				celle[i] = NATURALE | MEMORIA_BOSCO
				anni[i] = 0
				_in_ricrescita.erase(c)
			toccate.append(c)
	if toccate.is_empty():
		return
	var uniche := {}
	for c in toccate:
		uniche[c] = true
	var lista: Array[Vector2i] = []
	lista.assign(uniche.keys())
	for c in lista:
		_tocca_blocco(c)
	_aggiorna_immagine(lista)


## Blocchi di alberi cambiati dall'ultima chiamata (per la vista).
func prendi_cambiati() -> Array[Vector2i]:
	var out := _cambiati
	_cambiati = []
	return out


func blocco_toccato(b: Vector2i) -> bool:
	return b.x >= 0 and b.y >= 0 and b.x < _nb and b.y < _nb and _toccati[b.y * _nb + b.x] != 0


# ---------- alberi ----------

## Fattore di grandezza con cui disegnare un albero della mappa in (x, z): 1 come da mappa,
## 0 se non c'è (tagliato o non ancora cresciuto), in mezzo se sta ricrescendo.
## `caso` è un numero in [0, 1) proprio dell'albero, `modello` l'indice in Alberi.MODELLI.
func fattore_albero(x: float, z: float, modello: int, caso: float) -> float:
	var c := cella(x, z)
	var v := celle[c.y * n + c.x]
	var s := v & MASCHERA_STATO
	if s == NATURALE:
		return 1.0
	if s != LIBERO or v & MEMORIA_BOSCO == 0:
		return 0.0
	# Ricrescita: ogni pianta parte con un ritardo suo, così non spuntano tutte insieme.
	var eta := float(anni[c.y * n + c.x]) - caso * 6.0
	var f := 0.0
	if modello >= Alberi.VARIANTI[Alberi.CANNA][0]:
		f = (eta - 1.0) / 3.0
	elif modello >= Alberi.VARIANTI[Alberi.CESPUGLIO][0]:
		f = (eta - 2.0) / 10.0
	else:
		f = (eta - 8.0) / float(ANNI_MATURO - 15)
	if f < 0.12:
		return 0.0
	return clampf(f, 0.12, 1.0)


func _conta_alberi_in_piedi(lista: Array[Vector2i]) -> int:
	var dentro := {}
	var blocchi := {}
	for c in lista:
		dentro[c] = true
		var p := centro(c)
		blocchi[Vector2i(floori(p.x / Alberi.LATO_BLOCCO), floori(p.y / Alberi.LATO_BLOCCO))] = true
	var k := Alberi.CAMPI
	var conta := 0
	for b in blocchi:
		var arr := alberi.alberi_nel_blocco(b)
		for t in arr.size() / k:
			var x := arr[t * k]
			var z := arr[t * k + 1]
			if dentro.has(cella(x, z)) and fattore_albero(x, z, int(arr[t * k + 4]), (arr[t * k + 5] - 0.84) / 0.24) > 0.0:
				conta += 1
	return conta


func _imposta(c: Vector2i, nuovo: int, taglio: bool) -> void:
	var i := c.y * n + c.x
	var memoria := celle[i] & MEMORIA_BOSCO
	if taglio and celle[i] & MASCHERA_STATO == NATURALE:
		var p := centro(c)
		if alberi.valore_bosco(p.x, p.y) >= 0.5:
			memoria = MEMORIA_BOSCO
	# Un bosco in ricrescita tagliato di nuovo ha già la memoria: riparte da zero anni.
	celle[i] = nuovo | memoria
	anni[i] = 0
	if nuovo == LIBERO and memoria != 0:
		_in_ricrescita[c] = true
	else:
		_in_ricrescita.erase(c)
	_tocca_blocco(c)


func _tocca_blocco(c: Vector2i) -> void:
	var p := centro(c)
	# Un albero può stare fino a mezza cella fuori dal centro: si toccano anche i blocchi vicini.
	for o in [Vector2(-passo, -passo), Vector2(passo, -passo), Vector2(-passo, passo), Vector2(passo, passo)]:
		var b := Vector2i(floori((p.x + o.x) / Alberi.LATO_BLOCCO), floori((p.y + o.y) / Alberi.LATO_BLOCCO))
		if b.x < 0 or b.y < 0 or b.x >= _nb or b.y >= _nb:
			continue
		_toccati[b.y * _nb + b.x] = 1
		if not _cambiati.has(b):
			_cambiati.append(b)


## Semi: entro RAGGIO_SEMI celle c'è un bosco naturale in piedi o un'area in ricrescita che
## ha già almeno ANNI_SEME anni. Si controllano 16 punti su due cerchi.
func _semi_vicini(c: Vector2i) -> bool:
	for r in [RAGGIO_SEMI * 0.5, RAGGIO_SEMI]:
		for k in 8:
			var a := k * TAU / 8.0 + (0.4 if r < RAGGIO_SEMI else 0.0)
			var q := Vector2i(clampi(c.x + roundi(cos(a) * r), 0, n - 1), clampi(c.y + roundi(sin(a) * r), 0, n - 1))
			var v := celle[q.y * n + q.x]
			var s := v & MASCHERA_STATO
			if s == NATURALE:
				var p := centro(q)
				if alberi.valore_bosco(p.x, p.y) >= 0.5:
					return true
			elif s == LIBERO and v & MEMORIA_BOSCO != 0 and anni[q.y * n + q.x] >= ANNI_SEME:
				return true
	return false


func _aggiorna_immagine(lista: Array[Vector2i]) -> void:
	if lista.is_empty():
		return
	for c in lista:
		var i := c.y * n + c.x
		var v := celle[i]
		var s := v & MASCHERA_STATO
		var eta := float(anni[i])
		var bosco := 1.0
		var nuda := 0.0
		var campo := 0.0
		var sigillo := 0.0
		match s:
			LIBERO:
				bosco = clampf((eta - ANNI_SEME) / float(ANNI_MATURO - ANNI_SEME), 0.0, 1.0) if v & MEMORIA_BOSCO else 0.0
				nuda = 1.0 - clampf(eta / ANNI_ERBA, 0.0, 1.0)
			COLTIVATO:
				bosco = 0.0
				campo = 1.0
			COSTRUITO:
				bosco = 0.0
				nuda = 1.0
			SIGILLATO:
				bosco = 0.0
				sigillo = 1.0
		immagine.set_pixel(c.x, c.y, Color(bosco, nuda, campo, sigillo))
	texture.update(immagine)
