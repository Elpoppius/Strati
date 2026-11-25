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
##
## Chiarimento di Fede (24/11/2026): invasivo o no non è una scelta del giocatore né una
## dinamica in più. È una qualità nascosta dei materiali di cui sono fatti edifici e strade:
## una casa lunga (legno e argilla) tolta lascia ricrescere il bosco, nelle condizioni giuste;
## un'autostrada (asfalto) no. Il catalogo è in COSTRUZIONI e MATERIALI, qui sotto.
##   Gli effetti sulla simulazione (erosione, piene, frane, selvaggina) arriveranno con il gioco.
##
## Tempi della ricrescita (proposta di Claude, da tarare): ceppi e terra nuda che si coprono
## d'erba in pochi anni; arbusti dopo 2–3 anni; alberi giovani dopo circa 8; il bosco torna
## maturo dopo 60 anni. Un'area in ricrescita fa da sorgente di semi dopo 15 anni, quindi il
## bosco si richiude dai margini verso l'interno.

## Materiali: invasivo = sigilla il suolo per sempre (proposta di Claude per l'elenco).
const MATERIALI := {
	"legno": false, "argilla": false, "paglia": false, "pietra a secco": false, "terra battuta": false,
	"ghiaia": false, "mattoni": false, "calce": false,
	"cemento": true, "asfalto": true, "fondamenta": true, "fognature": true,
}
## Costruzioni e loro materiali. Una costruzione è invasiva se lo è almeno uno dei materiali.
## Per ora quelle del villaggio; le altre si aggiungono con le epoche.
const COSTRUZIONI := {
	"casa_lunga": ["legno", "argilla", "paglia"],
	"capanna": ["legno", "argilla", "paglia"],
	"granaio": ["legno", "argilla", "paglia"],
	"legnaia": ["legno", "paglia"],
	"focolare": ["pietra a secco"],
	"sentiero": ["terra battuta"],
	"palizzata": ["legno"],
	"strada_asfaltata": ["asfalto", "fondamenta"],
	"palazzo_in_cemento": ["cemento", "fondamenta", "fognature"],
}

const NATURALE := 0  ## come dice la mappa
const LIBERO := 1  ## alberi tolti, terreno libero
const COLTIVATO := 2  ## campi: terreno tenuto libero, non invasivo
const COSTRUITO := 3  ## edificato con materiali non invasivi (argilla, legno, paglia)
const SIGILLATO := 4  ## edificato con materiali invasivi: non accoglie più alberi
## Nomi mostrati al giocatore: la differenza tra costruito e sigillato è nascosta (si vede solo
## da ciò che succede dopo).
const NOMI_STATO := ["naturale", "libero", "coltivato", "costruito", "costruito"]
## Bit di memoria: la cella era un bosco (resta anche quando il bosco ricresce o è sigillato).
const MEMORIA_BOSCO := 0x80
const MASCHERA_STATO := 0x0f
## Bit: costruzione che non si dipinge sul terreno (la disegna un oggetto a parte, come i
## sentieri): conta per gli alberi e per la ricrescita, ma lo shader non mette terra battuta.
const NON_DIPINTA := 0x40

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
## Tecnica di ogni campo (indice in SimVillaggio.TECNICHE: 0 zappa, 1 aratro in croce, 2
## centuriazione, 3 strisce medievali, 4 meccanica). Decisione di Fede del 24/11/2026: il campo
## cambia con l'epoca e i campi vecchi restano finché non si ammodernano. Lo shader del terreno
## la legge da una texture a parte (un byte per cella, senza filtro) e disegna il campo di quel tipo.
var tecniche := PackedByteArray()
var immagine_tecniche: Image
var texture_tecniche: ImageTexture
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
	tecniche.resize(n * n)
	immagine_tecniche = Image.create(n, n, false, Image.FORMAT_R8)
	texture_tecniche = ImageTexture.create_from_image(immagine_tecniche)
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

## Vero se nella cella si può demolire (non è acqua né palude).
func demolibile(c: Vector2i) -> bool:
	var p := centro(c)
	return alberi.distanza_acqua(p.x, p.y) > 0.0 and alberi._campiona_fine(alberi.dati.palude_fine, p.x, p.y) < 128.0


## Abbatte gli alberi nelle celle (strumento Demolisci). Restituisce quanti alberi e arbusti sono
## stati tagliati (il legname), contando solo quelli che erano in piedi. Acqua e paludi non si
## toccano: sono elementi naturali che si gestiscono con altri strumenti, secondo l'epoca.
func abbatti(lista: Array[Vector2i]) -> int:
	lista = lista.filter(func(c: Vector2i) -> bool: return demolibile(c))
	var tagliati := _conta_alberi_in_piedi(lista)
	for c in lista:
		var i := c.y * n + c.x
		var s := celle[i] & MASCHERA_STATO
		if s == NATURALE or s == LIBERO:
			_imposta(c, LIBERO, true)
	_aggiorna_immagine(lista)
	return tagliati


## Vero se la costruzione (chiave di COSTRUZIONI) contiene almeno un materiale invasivo.
static func invasiva(costruzione: String) -> bool:
	for m in COSTRUZIONI.get(costruzione, []):
		if MATERIALI.get(m, false):
			return true
	return false


## Costruisce sulle celle: se la costruzione è invasiva (per i suoi materiali) il suolo resta
## sigillato per sempre, altrimenti tornerà libero quando la costruzione sarà tolta.
func costruisci(lista: Array[Vector2i], costruzione: String, dipinta := true) -> int:
	return edifica(lista, invasiva(costruzione), dipinta)


## Edifica: con materiali invasivi la cella è sigillata per sempre; altrimenti è costruita ma
## può tornare libera. In entrambi i casi gli alberi spariscono e la memoria del bosco resta.
## Da fuori si usa costruisci(), che ricava l'invasività dai materiali.
func edifica(lista: Array[Vector2i], invasivo: bool, dipinta := true) -> int:
	var tagliati := _conta_alberi_in_piedi(lista)
	for c in lista:
		var i := c.y * n + c.x
		if celle[i] & MASCHERA_STATO == SIGILLATO:
			continue
		var era_dipinta := celle[i] & MASCHERA_STATO == COSTRUITO and celle[i] & NON_DIPINTA == 0
		_imposta(c, SIGILLATO if invasivo else COSTRUITO, true)
		if not dipinta and not era_dipinta:
			celle[i] |= NON_DIPINTA
	_aggiorna_immagine(lista)
	return tagliati


## Campi: terreno tenuto libero dagli alberi finché è coltivato. `tecnica` dice come è lavorato;
## su un campo che c'è già la cambia soltanto (ammodernamento: niente si costruisce da zero).
func coltiva(lista: Array[Vector2i], tecnica := 0) -> int:
	var tagliati := _conta_alberi_in_piedi(lista)
	var cambiate := false
	for c in lista:
		var i := c.y * n + c.x
		var s := celle[i] & MASCHERA_STATO
		if s == NATURALE or s == LIBERO:
			_imposta(c, COLTIVATO, true)
		if (celle[i] & MASCHERA_STATO) == COLTIVATO and tecniche[i] != tecnica:
			tecniche[i] = tecnica
			immagine_tecniche.set_pixel(c.x, c.y, Color(tecnica / 255.0, 0, 0))
			cambiate = true
	if cambiate:
		texture_tecniche.update(immagine_tecniche)
	_aggiorna_immagine(lista)
	return tagliati


func tecnica(x: float, z: float) -> int:
	var c := cella(x, z)
	return tecniche[c.y * n + c.x]


## Toglie una costruzione o abbandona un campo: il terreno torna libero e, se era un bosco,
## può ricrescere. Le celle sigillate (materiali invasivi) restano sigillate.
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
	# (NON_DIPINTA si azzera qui: lo rimette edifica() quando serve.)
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
				nuda = 0.0 if v & NON_DIPINTA else 1.0
			SIGILLATO:
				bosco = 0.0
				sigillo = 1.0
		immagine.set_pixel(c.x, c.y, Color(bosco, nuda, campo, sigillo))
	texture.update(immagine)
