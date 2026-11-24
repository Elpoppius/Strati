class_name SimVillaggio
extends RefCounted
## Simulazione della prima epoca (il villaggio), separata dalla grafica: si verifica senza
## schermo (test/verifica_villaggio.gd). È il Prototipo 0 (prototipi/prototipo0/index.html)
## portato sulla mappa vera (proposta di Claude accolta da Fede il 24/11/2026).
##
## Scale: le regole del prototipo ragionavano a celle da 160 m. Qui i campi stanno sulla
## griglia della mappa (pixel da 40 m: 16 pixel = una cella del prototipo, quindi un pixel rende
## 1/16 di una cella) e le case sui lotti da 20 m. Distanze e raggi sono convertiti di
## conseguenza; i numeri dell'economia (cibo, braccia, consumo) restano quelli del prototipo.
##
## Decisioni di Fede che valgono qui: niente recinto per ora, l'abitato cresce spontaneo;
## il tempo scorre continuo e si ferma da solo nei momenti decisivi; presagi veri e falsi.
## La grafica legge lo stato (case, campi, sentieri, granaio) e lo disegna (VistaVillaggio).

const ANNO_INIZIO := -6000
const ANNO_FINE := -5500
## Pixel della mappa per cella del prototipo (lato): 160 m / 40 m.
const PX_CELLA := 4
const AREA_CELLA := 16
const LOTTO := 20.0
const MAX_SENTIERO := 160  # pixel (6,4 km, come i 40 tratti da 160 m del prototipo)

var dati: MappaDati
var n := 0
var rng := RandomNumberGenerator.new()
## Vero se nel pixel c'è bosco in piedi (lo fornisce chi usa la simulazione, che conosce i tagli).
var bosco_presente: Callable

# ---------- stato ----------
var anno := ANNO_INIZIO
var fondato := false
var finito := false
var centro := Vector2i(-1, -1)  # pixel
var pop := 0.0
var cibo := 0.0
var salute := 70.0
var legittimita := 60.0
var bonus := 0.0
## Politiche del villaggio (non costruzioni: regole che valgono finché non si cambiano; decisione
## di Fede del 24/11/2026). Cambiarne una costa un po' di consenso: le abitudini pesano.
## raccolto: "comune" (più consenso) o "famiglie" (più raccolto).
## stranieri (proposta di Claude): "aperta" (si accolgono sempre), "chiusa" (si respingono sempre),
## "caso" (ogni arrivo ferma il tempo e si decide).
var politiche := {"raccolto": "comune", "stranieri": "caso"}
const POLITICHE := {
	"raccolto": ["comune", "famiglie"],
	"stranieri": ["aperta", "caso", "chiusa"],
}
## Ammodernamento tecnologico (decisione di Fede del 24/11/2026), nel blocco Gestione allo stesso
## livello delle politiche, diviso per settore: agricolo ora; viario, abitativo… più avanti. Attivo,
## ogni anno una parte di ciò che è fatto con una tecnica vecchia passa alla tecnica dell'epoca,
## pagando cibo (le braccia che ci lavorano); non si costruisce niente da zero, si sovrascrive il
## tipo vecchio.
var ammodernamenti := {"agricolo": false}

# ---------- tecniche dei campi ----------
## Il campo cambia con l'epoca (decisione di Fede del 24/11/2026): ogni campo ricorda la tecnica
## con cui è stato fatto; i campi nuovi nascono con la tecnica dell'epoca e rendono di più (progresso
## tecnico); i vecchi restano finché non si ammodernano. Rese: proposta di Claude, da tarare.
const TECNICHE := ["zappa", "aratro in croce", "centuriazione", "strisce medievali", "meccanica"]
const RESA_TECNICA := [1.0, 1.3, 1.55, 1.8, 3.0]
## Cibo speso per ammodernare un pixel di campo (0,16 ha) e quota dei campi lavorabili che si
## possono ammodernare in un anno (proposta di Claude).
const COSTO_AMMODERNAMENTO := 0.8
const QUOTA_AMMODERNAMENTO := 0.1
var tecnica_corrente := 0

# ---------- contado ed economia mista ----------
## Contado (decisione di Fede del 24/11/2026): la terra che il villaggio coltiva. Il raggio cresce
## con gli abitanti, da 400 m alla fondazione fino a 800 m, il limite di cammino (verosimile: oltre
## circa 1 km la cura dei campi cala molto). I sentieri non lo allargano.
const CONTADO_MIN := 400.0
const CONTADO_MAX := 800.0
const CONTADO_PER_ABITANTE := 4.0
var _contado_annunciato := 0.0
## Sentieri (decisione di Fede): velocizzano l'accumulo di cibo. I campi serviti da un sentiero
## collegato al villaggio (entro 120 m) o vicini al centro (entro 200 m) rendono di più.
const BONUS_SENTIERO := 0.1
## Economia mista (decisione di Fede): caccia, raccolta e pesca accanto ai campi. Boschi e acque
## vicini danno cibo; ma l'acqua porta le piene e il bosco la selvaggina che rovina i campi al suo
## margine (proposta di Claude). Numeri da tarare.
const RAGGIO_RISORSE := 40  # pixel (1,6 km)
const QUOTA_CACCIA := 0.4  # cibo per abitante che caccia e raccolta possono dare al massimo
const QUOTA_PESCA := 0.2
const RESA_BOSCO := 0.04
const RESA_ACQUA := 0.15
var selvaggina := 1.0
var ultima_caccia := 0.0
var ultima_pesca := 0.0
var _risorse := {"bosco": 0.0, "acqua": 0.0}
var _anni_risorse := 0
var _campi_serviti := {}
var _campi_al_bosco := {}
var _firma_serviti := 0
var _tecnica_campi := {}  # indice del pixel -> tecnica (assente = 0)
## Gli stranieri arrivano con un generatore a parte, così le altre vicende della partita restano
## quelle di prima a parità di seme.
var rng_stranieri := RandomNumberGenerator.new()
## Anni in cui le tecniche portate dagli stranieri accolti rendono di più i campi.
var anni_sapere := 0
var stranieri_accolti := 0
var _gruppo_stranieri := 0
var granaio := Vector2(-1, -1)  # punto nel mondo (metri)
var campi: Array[int] = []  # indici dei pixel
var sentieri: Array[int] = []
## Tratti di sentiero come segmenti dritti tra due pixel (per disegnarli lungo la linea vera,
## non a scalini): [Vector2i da, Vector2i a]. Un pixel di sentiero demolito toglie il pezzo.
var tratti_sentiero: Array = []
var case: Array[Vector2i] = []  # lotti da 20 m
var rovine: Array[Vector2] = []  # punti nel mondo
## Lotti delle case demolite: per qualche anno non vi rinasce una casa (lotto -> anni rimasti).
var macerie := {}
const ANNI_MACERIE := 20
var figli: Array[int] = []
var memoria := 40.0
var razionamento := 0
var siccita := 0
var siccita_tra := -1
var sorgenti_basse := false
var presagio_vero := {}
var cometa := {}
var affollamento := 0.0
var raggio_extra := 0
var gia_primo_cattivo := false
var gia_affollato := false
var anni_legittimita_bassa := 0
var clima := 1.0
var ultimo_raccolto := 0.0
var ultimi_lavorati := 0
var allagati := {}
var stat := {"carestie": 0, "piene": 0, "siccita": 0, "fondazioni": 0, "presagi_letti": 0, "presagi_totali": 0, "abbandoni": 0}
var storia := {"pop": [], "cibo": [], "salute": [], "legittimita": []}
## Cronaca: [{anno, testo, tipo ("", "buono", "allarme")}], la più recente in testa.
var cronaca: Array = []
## Decisioni che aspettano il giocatore: il tempo si ferma finché non sono risolte.
## Ognuna: {id, tipo, titolo, testo, opzioni: [{id, testo, nota}]}.
var decisioni: Array = []
## Notifiche discrete (decisione di Fede del 24/11/2026: ritmo meditativo; piene e carestie non
## fermano il gioco): {testo, pericolo (bool), punto (Vector2 nel mondo, x < 0 se nessuno)}.
var avvisi: Array = []
## Probabilità all'anno (decisione di Fede: le piene di stagione sono frequenti e toccano solo i
## campi più bassi; le piene disastrose sono rare; contano solo se toccano il villaggio).
const PROB_PIENA_STAGIONALE := 0.3
const PROB_PIENA_DISASTROSA := 0.011
## Distanza in celle del prototipo dalla palude più vicina, per pixel.
var _d_palude := PackedFloat32Array()
var _prossimo_id := 1


func _init(d: MappaDati, seme: int = 1) -> void:
	dati = d
	n = d.lato
	rng.seed = seme
	rng_stranieri.seed = seme + 7919
	bosco_presente = func(i: int) -> bool: return dati.copertura[i] > 127
	_calcola_distanza_palude()


# ---------- dati della mappa ----------

func edificabile(i: int) -> bool:
	var t := dati.tipo[i]
	return t == MappaDati.TERRA or t == MappaDati.GESSI


func fert(i: int) -> float:
	return dati.fertilita[i] / 255.0 * 1.2


func piena(i: int) -> float:
	return dati.piena[i] / 255.0


func acqua_affidabile(i: int) -> float:
	return dati.acqua[i] / 255.0


func acqua_qualsiasi(i: int) -> float:
	return dati.acqua_stagionale[i] / 255.0


func px(p: Vector2i) -> int:
	return p.y * n + p.x


func px_di(i: int) -> Vector2i:
	return Vector2i(i % n, i / n)


func px_da_mondo(x: float, z: float) -> Vector2i:
	return dati.pixel_da_mondo(x, z)


func mondo_di_px(p: Vector2i) -> Vector2:
	return Vector2(p) * dati.metri_per_px


func lotto_da_mondo(x: float, z: float) -> Vector2i:
	return Vector2i(floori(x / LOTTO), floori(z / LOTTO))


func centro_lotto(l: Vector2i) -> Vector2:
	return (Vector2(l) + Vector2(0.5, 0.5)) * LOTTO


## Distanza a scacchiera in pixel.
static func cheb(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


func _calcola_distanza_palude() -> void:
	_d_palude.resize(n * n)
	var coda: Array[int] = []
	for i in n * n:
		if dati.tipo[i] == MappaDati.PALUDE:
			_d_palude[i] = 0.0
			coda.append(i)
		else:
			_d_palude[i] = 1e9
	var testa := 0
	while testa < coda.size():
		var c := coda[testa]
		testa += 1
		var p := px_di(c)
		for dy in [-1, 0, 1]:
			for dx in [-1, 0, 1]:
				var q := p + Vector2i(dx, dy)
				if q.x < 0 or q.y < 0 or q.x >= n or q.y >= n:
					continue
				var j := px(q)
				if _d_palude[j] > _d_palude[c] + 1.0:
					_d_palude[j] = _d_palude[c] + 1.0
					coda.append(j)
	for i in n * n:
		_d_palude[i] /= PX_CELLA


# ---------- cronaca e decisioni ----------

func _scrivi(testo: String, tipo := "") -> void:
	cronaca.push_front({"anno": anno, "testo": testo, "tipo": tipo})
	if cronaca.size() > 80:
		cronaca.pop_back()


func _notifica(testo: String, pericolo := false, punto := Vector2(-1, -1)) -> void:
	avvisi.append({"testo": testo, "pericolo": pericolo, "punto": punto})


func _decidi(tipo: String, titolo: String, testo: String, opzioni: Array) -> void:
	decisioni.append({"id": _prossimo_id, "tipo": tipo, "titolo": titolo, "testo": testo, "opzioni": opzioni})
	_prossimo_id += 1


func in_attesa() -> bool:
	return not decisioni.is_empty()


static func anno_testo(a: int) -> String:
	return "%d a.C." % -a if a < 0 else "%d d.C." % a


# ---------- valutazione del sito ----------

## Come il prototipo: acqua, fertilità attorno, rischio di piena, difesa, aria.
## Ogni voce: [testo, sfavorevole (bool)].
func valuta_sito(p: Vector2i) -> Dictionary:
	var i := px(p)
	var out := {}
	var a := acqua_affidabile(i)
	var s := acqua_qualsiasi(i)
	out["acqua"] = ["abbondante e affidabile", false] if a >= 0.77 else (["affidabile ma a distanza", false] if a >= 0.44 else (["solo stagionale (torrente)", true] if s >= 0.77 else ["scarsa", true]))
	var fs := 0.0
	var fc := 0
	var fl := piena(i)
	var es := 0.0
	var ec := 0
	var palude_vicina := 0
	for dy in range(-20, 21, 2):
		for dx in range(-20, 21, 2):
			var q := p + Vector2i(dx, dy)
			if q.x < 0 or q.y < 0 or q.x >= n or q.y >= n:
				continue
			var j := px(q)
			if edificabile(j):
				fs += fert(j)
				fc += 1
			var d := maxi(absi(dx), absi(dy))
			if d <= 8:
				var t := dati.tipo[j]
				fl = maxf(fl, piena(j) if edificabile(j) else (0.6 if t == MappaDati.FIUME else (0.3 if t == MappaDati.PALUDE else 0.35)))
			if d <= 16:
				es += dati.altezze[j]
				ec += 1
				if dati.tipo[j] == MappaDati.PALUDE:
					palude_vicina += 1
	var fm := fs / maxf(fc, 1)
	out["fertilita"] = ["alta", false] if fm > 0.85 else (["buona", false] if fm > 0.65 else (["media", false] if fm > 0.45 else ["scarsa", true]))
	out["piena"] = ["alto", true] if fl > 0.5 else (["medio", true] if fl > 0.25 else (["basso", false] if fl > 0.0 else ["nullo", false]))
	# Campioni ogni 2 pixel: ognuno vale 4 pixel, cioè 1/4 di cella del prototipo.
	var relativa := dati.altezze[i] - es / maxf(ec, 1)
	var difesa := relativa / 12.0 + palude_vicina / 4.0 / 25.0
	out["difesa"] = ["buona", false] if difesa > 0.8 else (["discreta", false] if difesa > 0.3 else ["scarsa", true])
	var dm := _d_palude[i]
	out["aria"] = ["malsana, paludi vicine", true] if dm <= 3.0 else (["paludi non lontane", true] if dm <= 6.0 else ["salubre", false])
	var r := risorse_attorno(p)
	out["bosco"] = ["ricchi, molta selvaggina", false] if r["bosco"] > 550.0 else (["presenti", false] if r["bosco"] > 300.0 else ["pochi", true])
	out["pesca"] = ["fiume vicino, buona pesca", false] if r["acqua"] > 150.0 else (["torrenti o fiume a distanza", false] if r["acqua"] > 40.0 else ["scarsa", true])
	out["sito"] = null
	for sito in dati.siti:
		if cheb(Vector2i(sito["px"]), p) <= 8:
			out["sito"] = sito
	return out


# ---------- azioni del giocatore ----------

func puo_fondare(p: Vector2i) -> bool:
	return not fondato and not finito and p.x >= 0 and edificabile(px(p))


func fonda(p: Vector2i) -> void:
	if not puo_fondare(p):
		return
	fondato = true
	centro = p
	pop = 30.0
	cibo = 45.0
	salute = 70.0
	legittimita = 60.0
	selvaggina = 1.0
	_anni_risorse = 0
	_contado_annunciato = CONTADO_MIN
	stat["fondazioni"] += 1
	var v := valuta_sito(p)
	var nome := (" presso il " + String(v["sito"]["nome"]).to_lower()) if v["sito"] != null else ""
	_scrivi("Fondazione%s. Acqua %s, rischio di piena %s." % [nome, v["acqua"][0], v["piena"][0]], "buono")
	disponi_case()


## Raggio del contado in metri: cresce con gli abitanti (decisione di Fede).
func raggio_contado() -> float:
	return clampf(CONTADO_MIN + (pop - 30.0) * CONTADO_PER_ABITANTE, CONTADO_MIN, CONTADO_MAX)


## Lo stesso raggio in pixel della mappa (arrotondato per eccesso), per scorrere i dintorni.
func raggio_campi() -> int:
	return ceili(raggio_contado() / dati.metri_per_px)


func a_portata(p: Vector2i) -> bool:
	if not fondato:
		return false
	return mondo_di_px(p).distance_to(mondo_di_px(centro)) <= raggio_contado() + 0.5


## Sentieri collegati al centro del villaggio (punti contigui, anche in diagonale). I sentieri
## sono liberi come in Cities: Skylines (decisione di Fede del 24/11/2026): un tratto isolato si
## può costruire, ma porta i campi più lontano solo quando è collegato.
var _collegati := {}
var _firma_collegati := 0

func sentieri_collegati() -> Dictionary:
	var firma := hash([sentieri.hash(), centro])
	if firma == _firma_collegati:
		return _collegati
	_firma_collegati = firma
	_collegati = {}
	if not fondato:
		return _collegati
	var presenti := {}
	for s in sentieri:
		presenti[s] = true
	var coda: Array[Vector2i] = []
	for s in sentieri:
		if cheb(px_di(s), centro) <= 1:
			_collegati[s] = true
			coda.append(px_di(s))
	while not coda.is_empty():
		var q: Vector2i = coda.pop_back()
		for oy in [-1, 0, 1]:
			for ox in [-1, 0, 1]:
				var v := q + Vector2i(ox, oy)
				if v.x < 0 or v.y < 0 or v.x >= n or v.y >= n:
					continue
				var i := px(v)
				if presenti.has(i) and not _collegati.has(i):
					_collegati[i] = true
					coda.append(v)
	return _collegati


func collegato(p: Vector2i) -> bool:
	return fondato and (cheb(p, centro) <= 1 or sentieri_collegati().has(px(p)))


func _lotti_del_px(p: Vector2i) -> Rect2i:
	var a := lotto_da_mondo(p.x * dati.metri_per_px - dati.metri_per_px * 0.5, p.y * dati.metri_per_px - dati.metri_per_px * 0.5)
	return Rect2i(a, Vector2i(2, 2))


func _occupato_da_case(p: Vector2i) -> bool:
	var r := _lotti_del_px(p)
	for c in case:
		if r.has_point(c):
			return true
	return false


## Perché un campo non va: "" se va bene.
func motivo_campo(p: Vector2i) -> String:
	var i := px(p)
	if not edificabile(i):
		return "I campi vanno su terra asciutta, non su acqua o palude."
	if _occupato_da_case(p) or (granaio.x >= 0 and px_da_mondo(granaio.x, granaio.y) == p):
		return "Il terreno è occupato da case o dal granaio."
	if not a_portata(p):
		return "Fuori dal contado: oggi la gente va a lavorare fino a %d m dal villaggio. Il contado cresce con gli abitanti." % roundi(raggio_contado())
	return ""


## Dissoda i pixel indicati (che vanno bene) e restituisce quanti sono stati aggiunti.
func aggiungi_campi(lista: Array[Vector2i]) -> int:
	var aggiunti := 0
	for p in lista:
		var i := px(p)
		if not campi.has(i) and motivo_campo(p) == "":
			campi.append(i)
			_tecnica_campi[i] = tecnica_corrente
			aggiunti += 1
	return aggiunti


func togli_campi(lista: Array[Vector2i]) -> int:
	var tolti := 0
	for p in lista:
		var k := campi.find(px(p))
		if k >= 0:
			campi.remove_at(k)
			_tecnica_campi.erase(px(p))
			tolti += 1
	return tolti


## Il punto della rete (centro o sentieri) più vicino a `p`: da qui parte un sentiero quando è
## acceso "Collega alla rete".
func punto_rete_vicino(p: Vector2i) -> Vector2i:
	var migliore := centro
	var d := cheb(p, centro)
	for s in sentieri:
		var q := px_di(s)
		if cheb(p, q) < d:
			d = cheb(p, q)
			migliore = q
	return migliore


## Punti della mappa toccati da un tratto dritto da `a` a `b` (compresi gli estremi).
func punti_tratto(a: Vector2i, b: Vector2i) -> Array[Vector2i]:
	var passi := maxi(cheb(a, b), 1)
	var out: Array[Vector2i] = []
	for k in range(0, passi + 1):
		var q := Vector2i(roundi(lerpf(a.x, b.x, float(k) / passi)), roundi(lerpf(a.y, b.y, float(k) / passi)))
		if out.is_empty() or out[-1] != q:
			out.append(q)
	return out


## Perché un sentiero da `a` a `b` non si può tracciare: "" se va bene.
func motivo_sentiero(a: Vector2i, b: Vector2i) -> String:
	if not fondato:
		return "Prima bisogna fondare il villaggio."
	if a == b:
		return "Scegli dove finisce il sentiero."
	var nuovi := 0
	for q in punti_tratto(a, b):
		if q.x < 0 or q.y < 0 or q.x >= n or q.y >= n:
			return "Fuori dalla mappa."
		var t := dati.tipo[px(q)]
		if t == MappaDati.FIUME or t == MappaDati.PALUDE:
			return "Non attraversa il fiume né la palude."
		if q != centro and not sentieri.has(px(q)):
			nuovi += 1
	if nuovi == 0:
		return "Il sentiero passa già da qui."
	if sentieri.size() + nuovi > MAX_SENTIERO:
		return "Sentieri lunghi al massimo %d km in tutto." % roundi(MAX_SENTIERO * dati.metri_per_px / 1000.0)
	return ""


## Traccia un sentiero dritto da `a` a `b` (come in Cities: Skylines, l'inizio è libero).
## Restituisce "" se fatto, altrimenti il motivo.
func traccia_sentiero_da(a: Vector2i, b: Vector2i) -> String:
	var m := motivo_sentiero(a, b)
	if m != "":
		return m
	var tratto: Array[int] = []
	for q in punti_tratto(a, b):
		if q != centro and not sentieri.has(px(q)) and not tratto.has(px(q)):
			tratto.append(px(q))
	sentieri.append_array(tratto)
	tratti_sentiero.append([a, b])
	# Le case sul nuovo sentiero si spostano.
	var prima := case.size()
	case = case.filter(func(c: Vector2i) -> bool: return not tratto.has(px(px_da_mondo(centro_lotto(c).x, centro_lotto(c).y))))
	if case.size() != prima:
		disponi_case()
	return ""


## Prolunga la rete dal suo punto più vicino fino a `p` (come "Collega alla rete").
func traccia_sentiero(p: Vector2i) -> String:
	if not fondato:
		return "Prima bisogna fondare il villaggio."
	return traccia_sentiero_da(punto_rete_vicino(p), p)


func motivo_granaio(punto: Vector2) -> String:
	if not fondato:
		return "Prima bisogna fondare il villaggio."
	if granaio.x >= 0:
		return "Il granaio c'è già."
	if cibo < 30.0:
		return "Servono 30 unità di cibo in scorta per costruire il granaio."
	var p := px_da_mondo(punto.x, punto.y)
	var i := px(p)
	if not edificabile(i) or campi.has(i) or sentieri.has(i) or cheb(p, centro) > 2 * PX_CELLA or p == centro:
		return "Il granaio va costruito su terra libera, vicino al centro del villaggio (entro 320 m)."
	return ""


func costruisci_granaio(punto: Vector2) -> String:
	var m := motivo_granaio(punto)
	if m != "":
		return m
	var l := lotto_da_mondo(punto.x, punto.y)
	case = case.filter(func(c: Vector2i) -> bool: return cheb(c, l) > 1)
	granaio = centro_lotto(l)
	cibo -= 30.0
	_scrivi("Costruito il granaio: le scorte si conservano meglio.", "buono")
	disponi_case()
	return ""


## Demolisce ciò che è demolibile dentro il cerchio (strumento Demolisci, decisione di Fede del
## 24/11/2026, come in Cities: Skylines): case, campi, sentieri, granaio. Il centro del villaggio
## (il focolare) non si demolisce. Fiumi e paludi non sono affare di questo strumento: si
## gestiranno con dighe, canali, deviazioni e bonifiche, quando l'epoca lo permetterà.
## Restituisce quanto è stato demolito.
func demolisci(punto: Vector2, raggio: float) -> Dictionary:
	var esito := {"case": 0, "campi": 0, "sentieri": 0, "granaio": false}
	if not fondato:
		return esito
	var rimaste: Array[Vector2i] = []
	for c in case:
		if centro_lotto(c).distance_to(punto) <= raggio:
			esito["case"] += 1
			macerie[c] = ANNI_MACERIE
		else:
			rimaste.append(c)
	case = rimaste
	var dentro := func(i: int) -> bool: return mondo_di_px(px_di(i)).distance_to(punto) <= raggio
	var n_campi := campi.size()
	campi = campi.filter(func(i: int) -> bool: return not dentro.call(i))
	esito["campi"] = n_campi - campi.size()
	var n_sentieri := sentieri.size()
	sentieri = sentieri.filter(func(i: int) -> bool: return not dentro.call(i))
	esito["sentieri"] = n_sentieri - sentieri.size()
	if granaio.x >= 0 and granaio.distance_to(punto) <= raggio:
		granaio = Vector2(-1, -1)
		esito["granaio"] = true
		_scrivi("Il granaio è stato demolito.")
	if esito["case"] > 0:
		_scrivi("Demolite %d case: le famiglie cercano posto altrove." % esito["case"])
	disponi_case()
	return esito


## Boschi e acque attorno a un punto, pesati con la vicinanza (1 al centro, 0 a 1,6 km): da qui
## vengono caccia, raccolta e pesca.
func risorse_attorno(p: Vector2i) -> Dictionary:
	var bosco := 0.0
	var acqua := 0.0
	for dy in range(-RAGGIO_RISORSE, RAGGIO_RISORSE + 1):
		for dx in range(-RAGGIO_RISORSE, RAGGIO_RISORSE + 1):
			var d := sqrt(float(dx * dx + dy * dy)) / RAGGIO_RISORSE
			if d > 1.0:
				continue
			var q := p + Vector2i(dx, dy)
			if q.x < 0 or q.y < 0 or q.x >= n or q.y >= n:
				continue
			var j := px(q)
			var w := 1.0 - d
			var t := dati.tipo[j]
			if t == MappaDati.FIUME:
				acqua += w
			elif t == MappaDati.TORRENTE or t == MappaDati.TORRENTE_EST:
				acqua += w * 0.6
			elif t == MappaDati.PALUDE:
				acqua += w * 0.5
				bosco += w * 0.3
			elif bosco_presente.call(j):
				bosco += w
	return {"bosco": bosco, "acqua": acqua}


## Campi serviti (sentiero collegato entro 120 m o centro entro 200 m) e campi al margine del bosco.
func _aggiorna_campi_serviti() -> void:
	var firma := hash([campi.hash(), sentieri.hash(), centro, _anni_risorse])
	if firma == _firma_serviti:
		return
	_firma_serviti = firma
	_campi_serviti = {}
	var collegati := sentieri_collegati()
	for i in campi:
		var p := px_di(i)
		if mondo_di_px(p).distance_to(mondo_di_px(centro)) <= 200.0:
			_campi_serviti[i] = true
			continue
		for dy in range(-3, 4):
			for dx in range(-3, 4):
				if dx * dx + dy * dy <= 9 and collegati.has(px(p + Vector2i(dx, dy))):
					_campi_serviti[i] = true
	_campi_al_bosco = {}
	for i in campi:
		var p := px_di(i)
		for dy in range(-2, 3):
			for dx in range(-2, 3):
				var q := p + Vector2i(dx, dy)
				if q.x >= 0 and q.y >= 0 and q.x < n and q.y < n and bosco_presente.call(px(q)):
					_campi_al_bosco[i] = true


func servito(i: int) -> bool:
	_aggiorna_campi_serviti()
	return _campi_serviti.has(i)


## Abitanti per ettaro nell'abitato (il cerchio che contiene le case).
func densita() -> float:
	if case.is_empty():
		return 0.0
	var c := mondo_di_px(centro)
	var r := 10.0
	for l in case:
		r = maxf(r, centro_lotto(l).distance_to(c) + LOTTO * 0.5)
	return pop / (PI * r * r / 10000.0)


func tecnica_campo(i: int) -> int:
	return _tecnica_campi.get(i, 0)


## Campi fatti con una tecnica più vecchia di quella dell'epoca.
func campi_da_ammodernare() -> int:
	var k := 0
	for i in campi:
		if tecnica_campo(i) < tecnica_corrente:
			k += 1
	return k


## Un anno di ammodernamento: i campi vecchi più vicini al centro passano alla tecnica nuova,
## finché basta il cibo. Restituisce quanti campi sono stati ammodernati.
func _ammoderna() -> int:
	var vecchi: Array[int] = []
	for i in campi:
		if tecnica_campo(i) < tecnica_corrente:
			vecchi.append(i)
	if vecchi.is_empty():
		return 0
	vecchi.sort_custom(func(a: int, b: int) -> bool: return cheb(px_di(a), centro) < cheb(px_di(b), centro))
	var quanti := mini(vecchi.size(), maxi(1, int(pop * 0.55 / 3.0 * AREA_CELLA * QUOTA_AMMODERNAMENTO)))
	quanti = mini(quanti, int(cibo / COSTO_AMMODERNAMENTO))
	for k in quanti:
		_tecnica_campi[vecchi[k]] = tecnica_corrente
	cibo -= quanti * COSTO_AMMODERNAMENTO
	if quanti > 0 and quanti == vecchi.size():
		_scrivi("Tutti i campi sono lavorati con la tecnica nuova (%s)." % TECNICHE[tecnica_corrente], "buono")
	elif quanti == 0:
		_scrivi("Ammodernamento fermo: manca il cibo per pagare il lavoro.")
	return quanti


## Avvia o sospende l'ammodernamento di un settore. Non costa consenso: il costo è il cibo speso
## ogni anno per il lavoro.
func imposta_ammodernamento(settore: String, attivo: bool) -> bool:
	if not ammodernamenti.has(settore) or ammodernamenti[settore] == attivo:
		return false
	ammodernamenti[settore] = attivo
	if fondato and settore == "agricolo":
		_scrivi("Si comincia a rifare i campi con la tecnica nuova." if attivo else "L'ammodernamento dei campi è sospeso.")
	return true


func politica(id: String) -> String:
	return politiche.get(id, "")


## Cambia una politica. Prima della fondazione si sceglie gratis (non c'è ancora un'abitudine).
func imposta_politica(id: String, valore: String) -> bool:
	if not POLITICHE.has(id) or not valore in POLITICHE[id] or politiche[id] == valore:
		return false
	politiche[id] = valore
	if not fondato:
		return true
	# Le abitudini pesano: cambiare una regola costa consenso.
	bonus -= 4.0
	match id + ":" + valore:
		"raccolto:comune":
			_scrivi("Il raccolto torna a essere diviso in comune.")
		"raccolto:famiglie":
			_scrivi("Ogni famiglia tiene il proprio raccolto.")
		"stranieri:aperta":
			_scrivi("Gli anziani decidono: chi arriva in pace è accolto.")
		"stranieri:chiusa":
			_scrivi("Gli anziani decidono: gli stranieri non restano.")
		"stranieri:caso":
			_scrivi("Gli anziani decideranno ogni volta chi accogliere.")
	return true


## Un gruppo di stranieri chiede di fermarsi (proposta di Claude, numeri da tarare).
## Accolti: più braccia e tecniche nuove (campi più fertili per 15 anni), ma malattie nuove e
## un po' di attrito. Respinti: nulla cambia, il villaggio resta unito.
func _arrivo_stranieri() -> void:
	var n_persone := 6 + rng_stranieri.randi() % 13
	match politica("stranieri"):
		"aperta":
			_accogli(n_persone)
		"chiusa":
			bonus += 1.0
			_scrivi("Un gruppo di %d stranieri chiede di fermarsi: viene mandato via." % n_persone)
		_:
			_gruppo_stranieri = n_persone
			_decidi("stranieri", "Arrivano degli stranieri",
				"Un gruppo di %d persone arriva dalla valle con i suoi animali e chiede di fermarsi. Coltivano in un modo che qui non si conosce." % n_persone,
				[{"id": "accogliere", "testo": "Accoglierli", "nota": "Più braccia e tecniche nuove per i campi; qualche malattia nuova e un po' di attrito."},
				 {"id": "respingere", "testo": "Mandarli via", "nota": "Nulla cambia. Il villaggio resta unito."}])


func _accogli(n_persone: int) -> void:
	pop += n_persone
	salute -= 3.0
	bonus -= 1.5
	anni_sapere = 15
	stranieri_accolti += n_persone
	_scrivi("%d stranieri si fermano al villaggio e portano nuovi modi di coltivare." % n_persone, "buono")


## Risolve una decisione in attesa con l'opzione scelta.
func scegli(id_decisione: int, opzione: String) -> void:
	for k in decisioni.size():
		var d: Dictionary = decisioni[k]
		if d["id"] != id_decisione:
			continue
		decisioni.remove_at(k)
		_applica_scelta(d["tipo"], opzione)
		return


func _applica_scelta(tipo: String, o: String) -> void:
	match tipo:
		"sorgenti":
			presagio_vero["scelta"] = o
			if o == "razionare":
				razionamento = 3
				bonus -= 3.0
				_scrivi("Gli anziani ordinano di razionare il cibo.")
			else:
				_scrivi("Il villaggio non dà peso alle sorgenti basse.")
		"cometa":
			cometa["scelta"] = o
			if o == "offerte":
				cibo *= 0.8
				razionamento = maxi(razionamento, 2)
				bonus += 4.0
				_scrivi("Il villaggio offre parte del raccolto e digiuna.")
			else:
				bonus -= 5.0
				_scrivi("Gli anziani non danno ascolto al sacerdote.")
		"primo_cattivo":
			if o == "razionare":
				razionamento = 3
				bonus -= 2.0
			elif o == "caccia":
				var bosco := 0
				for dy in range(-8 * PX_CELLA, 8 * PX_CELLA + 1):
					for dx in range(-8 * PX_CELLA, 8 * PX_CELLA + 1):
						var q := centro + Vector2i(dx, dy)
						if q.x >= 0 and q.y >= 0 and q.x < n and q.y < n and bosco_presente.call(px(q)):
							bosco += 1
				var guadagno := minf(pop * 0.6, bosco / float(AREA_CELLA) * 1.2)
				cibo += guadagno
				salute -= 3.0
				_scrivi("La caccia porta %d unità di cibo." % roundi(guadagno))
		"stranieri":
			if o == "accogliere":
				_accogli(_gruppo_stranieri)
			else:
				bonus += 1.0
				_scrivi("Gli stranieri vengono mandati via.")
			_gruppo_stranieri = 0
		"affollamento":
			if o == "restare":
				raggio_extra += 1
				salute -= 5.0
				_scrivi("Le famiglie restano: l'abitato si stringe e si allarga un poco.")
			else:
				_fonda_figlio()


# ---------- un anno ----------

func passo() -> void:
	if not fondato or finito or in_attesa():
		return
	allagati = {}
	clima = 0.75 + rng.randf() * 0.4
	if rng.randf() < PROB_PIENA_DISASTROSA:
		_piena(true)
	elif rng.randf() < PROB_PIENA_STAGIONALE:
		_piena(false)
	# Siccità.
	if siccita > 0:
		siccita -= 1
		if siccita == 0:
			sorgenti_basse = false
			_scrivi("Tornano le piogge. Le sorgenti si riempiono.", "buono")
	if siccita_tra > 0:
		siccita_tra -= 1
		if siccita_tra == 0:
			_inizia_siccita()
			siccita_tra = -1
	elif siccita == 0 and siccita_tra < 0 and presagio_vero.is_empty() and rng.randf() < 0.007:
		_inizia_siccita()
	# Presagi.
	if siccita == 0 and siccita_tra < 0 and cometa.is_empty() and rng.randf() < 0.006:
		siccita_tra = 2 + rng.randi() % 2
		sorgenti_basse = true
		presagio_vero = {"scelta": ""}
		stat["presagi_totali"] += 1
		_decidi("sorgenti", "Le sorgenti calano",
			"Le sorgenti danno meno acqua del solito e l'erba ingiallisce presto. Gli anziani chiedono di mettere da parte il raccolto.\nControlla la mappa dell'acqua.",
			[{"id": "razionare", "testo": "Razionare e accumulare", "nota": "Per tre anni si mangia meno: salute e consenso calano un poco."},
			 {"id": "ignorare", "testo": "Ignorare", "nota": "Nessun costo oggi."}])
	if siccita == 0 and siccita_tra < 0 and cometa.is_empty() and presagio_vero.is_empty() and rng.randf() < 0.008:
		cometa = {"scelta": "", "anni": 3}
		stat["presagi_totali"] += 1
		_decidi("cometa", "Una cometa nel cielo",
			"Una cometa attraversa il cielo per molte notti. Il sacerdote annuncia una carestia e chiede offerte e digiuno.",
			[{"id": "offerte", "testo": "Offerte e digiuno", "nota": "Si sacrifica parte delle scorte e si raziona per due anni. Il sacerdote è soddisfatto."},
			 {"id": "ignorare", "testo": "Ignorare il presagio", "nota": "Il sacerdote protesta e il consenso cala, almeno per ora."}])
	elif not cometa.is_empty():
		cometa["anni"] -= 1
		if cometa["anni"] <= 0:
			if cometa["scelta"] == "ignorare":
				bonus += 9.0
				stat["presagi_letti"] += 1
				_scrivi("Nessuna carestia dopo la cometa: gli anziani avevano visto giusto.", "buono")
			elif cometa["scelta"] == "offerte":
				bonus -= 3.0
				_scrivi("Nessuna carestia dopo la cometa: il digiuno è stato inutile.")
			cometa = {}
	# Stranieri: in media un gruppo ogni 70 anni, dopo i primi anni del villaggio.
	if anno > ANNO_INIZIO + 10 and not in_attesa() and rng_stranieri.randf() < 0.014:
		_arrivo_stranieri()
	if anni_sapere > 0:
		anni_sapere -= 1
	if ammodernamenti["agricolo"]:
		_ammoderna()
	# Raccolto: le braccia lavorano prima i campi più fertili.
	var braccia := pop * 0.55
	var lavorabili := int(braccia / 3.0 * AREA_CELLA)
	var ordinati := campi.duplicate()
	ordinati.sort_custom(func(a: int, b: int) -> bool: return fert(a) > fert(b))
	var raccolto := 0.0
	for k in mini(lavorabili, ordinati.size()):
		raccolto += _resa(ordinati[k])
	ultimo_raccolto = raccolto
	ultimi_lavorati = mini(lavorabili, ordinati.size())
	# Caccia, raccolta e pesca (economia mista): la selvaggina cala se si caccia troppo e ricresce
	# lentamente; boschi e acque si ricontano ogni 5 anni (tagli e campi tolgono bosco).
	if _anni_risorse <= 0:
		_risorse = risorse_attorno(centro)
		_anni_risorse = 5
	_anni_risorse -= 1
	var portata_bosco: float = _risorse["bosco"] * RESA_BOSCO
	ultima_caccia = minf(pop * QUOTA_CACCIA, portata_bosco * selvaggina)
	selvaggina = clampf(selvaggina - ultima_caccia / maxf(portata_bosco * 8.0, 1.0) + (1.0 - selvaggina) * 0.1, 0.05, 1.0)
	ultima_pesca = minf(pop * QUOTA_PESCA, float(_risorse["acqua"]) * RESA_ACQUA)
	var consumo := pop * (0.8 if razionamento > 0 else 1.0)
	cibo += raccolto + ultima_caccia + ultima_pesca - consumo
	if razionamento > 0:
		razionamento -= 1
	var carestia := 0.0
	if cibo < 0.0:
		carestia = minf(1.0, -cibo / maxf(1.0, consumo))
		pop -= pop * carestia * 0.35
		salute -= carestia * 25.0
		legittimita -= carestia * 30.0
		cibo = 0.0
		stat["carestie"] += 1
		_scrivi("Carestia: manca il %d%% del cibo necessario." % roundi(carestia * 100.0), "allarme")
		if carestia > 0.25:
			_notifica("Carestia: manca il %d%% del cibo necessario." % roundi(carestia * 100.0), true, mondo_di_px(centro))
	else:
		cibo *= 0.9 if granaio.x >= 0 else 0.75
	if not gia_primo_cattivo and raccolto < consumo and anno > ANNO_INIZIO + 2:
		gia_primo_cattivo = true
		_decidi("primo_cattivo", "Il primo cattivo raccolto",
			"Il raccolto non basta a sfamare tutti: %d contro un bisogno di %d." % [roundi(raccolto), roundi(consumo)],
			[{"id": "razionare", "testo": "Razionare per tre anni", "nota": "Si consuma meno; salute e consenso calano un poco."},
			 {"id": "caccia", "testo": "Cacciare di più nei boschi", "nota": "Più cibo subito, ma i cacciatori rischiano e la selvaggina cala."},
			 {"id": "campi", "testo": "Dissodare nuovi campi", "nota": "Torni alla mappa e aggiungi campi con il comando Campi."}])
	# Salute.
	var dm := _d_palude[px(centro)]
	var obiettivo := 72.0 + 15.0 * acqua_qualsiasi(px(centro)) - (25.0 if dm <= 3.0 else (10.0 if dm <= 6.0 else 0.0)) \
		- affollamento * 25.0 - (5.0 if razionamento > 0 else 0.0) - (8.0 if cibo < pop * 0.3 else 0.0)
	salute += (clampf(obiettivo, 5.0, 95.0) - salute) * 0.15
	salute = clampf(salute, 0.0, 100.0)
	# Popolazione.
	if carestia == 0.0 and cibo > pop * 0.3:
		pop *= 1.0 + 0.007 + 0.008 * (salute - 50.0) / 50.0
	elif carestia == 0.0:
		pop *= 0.997
	if salute < 35.0:
		pop *= 0.97
	# Legittimità degli anziani.
	var lt := 55.0 + (10.0 if cibo > pop * 0.5 else -6.0) + (8.0 if politica("raccolto") == "comune" else -4.0)
	legittimita += (clampf(lt, 0.0, 100.0) - legittimita) * 0.1 + bonus * 0.4
	bonus *= 0.6
	if absf(bonus) < 0.2:
		bonus = 0.0
	legittimita = clampf(legittimita, 0.0, 100.0)
	# Il contado cresce con gli abitanti: lo si annuncia ogni 100 m.
	var passo_contado := floorf(raggio_contado() / 100.0) * 100.0
	if passo_contado > _contado_annunciato and passo_contado > CONTADO_MIN:
		_scrivi("Il villaggio cresce: ora si coltiva fino a %d m dal centro." % roundi(passo_contado), "buono")
	_contado_annunciato = maxf(_contado_annunciato, passo_contado)
	memoria = maxf(0.0, memoria - 1.5)
	for l in macerie.keys():
		macerie[l] -= 1
		if macerie[l] <= 0:
			macerie.erase(l)
	disponi_case()
	if not gia_affollato and pop >= 150.0:
		gia_affollato = true
		_decidi("affollamento", "Il villaggio è affollato",
			"Le famiglie sono ormai %d. Le case si stringono e i campi più lontani sono faticosi da raggiungere." % roundi(pop / 6.0),
			[{"id": "restare", "testo": "Restare tutti", "nota": "Le case si stringono e l'abitato si allarga un poco: la salute ne risente. Il contado resta quello che il cammino permette."},
			 {"id": "figlio", "testo": "Fondare un villaggio figlio", "nota": "Un terzo delle famiglie parte per fondare un nuovo villaggio. Il consenso cresce."}])
	if legittimita <= 5.0:
		anni_legittimita_bassa += 1
	else:
		anni_legittimita_bassa = 0
	if anni_legittimita_bassa >= 4:
		pop *= 0.6
		legittimita = 35.0
		anni_legittimita_bassa = 0
		_scrivi("Il villaggio si divide: molte famiglie se ne vanno.", "allarme")
		_notifica("Il villaggio si divide: gli anziani hanno perso ogni autorità e molte famiglie se ne vanno.", true, mondo_di_px(centro))
	if pop < 6.0:
		_abbandona()
	for k in ["pop", "cibo", "salute", "legittimita"]:
		var arr: Array = storia[k]
		arr.append(get(k))
		if arr.size() > 200:
			arr.pop_front()
	anno += 1
	if anno >= ANNO_FINE:
		_fine()


func _resa(i: int) -> float:
	if allagati.has(i):
		return 0.0
	var fattore := 0.0
	if siccita > 0:
		fattore = 0.35 + 0.6 * acqua_affidabile(i)
	else:
		fattore = clima * (0.85 + 0.15 * acqua_qualsiasi(i))
	_aggiorna_campi_serviti()
	# Sentiero: si va e si torna più in fretta. Bosco: la selvaggina rovina i campi al suo margine
	# (meno, se la caccia la tiene bassa).
	var vie := 1.0 + BONUS_SENTIERO if _campi_serviti.has(i) else 1.0
	var danni := 1.0 - 0.25 * selvaggina if _campi_al_bosco.has(i) else 1.0
	return 12.0 * fert(i) * fattore * (1.12 if politica("raccolto") == "famiglie" else 1.0) \
		* (1.08 if anni_sapere > 0 else 1.0) * RESA_TECNICA[tecnica_campo(i)] * vie * danni / AREA_CELLA


## Piene (decisione di Fede del 24/11/2026). Di stagione (disastrosa = false): frequenti, arrivano
## solo dove il rischio di piena è alto e tolgono il raccolto dei campi più bassi, senza toccare
## le case. Disastrose: rare, l'acqua arriva ovunque con la probabilità del rischio della mappa e
## travolge anche le case. Nessuna delle due ferma il gioco; una piena che non tocca il villaggio
## (campi, case, granaio) non si nota nemmeno nella cronaca.
func _piena(disastrosa: bool) -> void:
	var case_perse := 0
	var campi_persi := 0
	var colpiti := {}
	var vicino := Rect2i(centro - Vector2i(40, 40), Vector2i(81, 81))
	for y in range(maxi(vicino.position.y, 0), mini(vicino.end.y, n)):
		for x in range(maxi(vicino.position.x, 0), mini(vicino.end.x, n)):
			var i := y * n + x
			if not edificabile(i) or piena(i) <= 0.0:
				continue
			var prob := piena(i) if disastrosa else clampf((piena(i) - 0.55) / 0.45, 0.0, 1.0) * 0.6
			if rng.randf() < prob:
				colpiti[i] = true
	if disastrosa:
		var rimaste: Array[Vector2i] = []
		for c in case:
			var p := centro_lotto(c)
			if colpiti.has(px(px_da_mondo(p.x, p.y))):
				case_perse += 1
			else:
				rimaste.append(c)
		case = rimaste
	var dove := Vector2.ZERO
	for f in campi:
		if colpiti.has(f):
			campi_persi += 1
			allagati[f] = true
			dove += mondo_di_px(px_di(f))
	var granaio_colpito := disastrosa and granaio.x >= 0 and colpiti.has(px(px_da_mondo(granaio.x, granaio.y)))
	if granaio_colpito:
		cibo *= 0.6
	if case_perse == 0 and campi_persi == 0 and not granaio_colpito:
		return
	dove = dove / campi_persi if campi_persi > 0 else mondo_di_px(centro)
	pop -= minf(pop, case_perse * 2.5)
	if not disastrosa:
		_scrivi("Piena di stagione: %d campi allagati, il loro raccolto è perso." % campi_persi)
		_notifica("Piena di stagione: %d campi allagati." % campi_persi, false, dove)
		return
	memoria = 100.0
	stat["piene"] += 1
	if case_perse > 0:
		bonus -= minf(8.0, case_perse)
		_scrivi("Il fiume esce dal letto: %d case distrutte, %d campi allagati. Il ricordo del pericolo torna vivo." % [case_perse, campi_persi], "allarme")
		_notifica("Piena disastrosa: %d case distrutte, %d campi allagati." % [case_perse, campi_persi], true, dove)
	else:
		_scrivi("Il fiume esce dal letto: %d campi allagati, raccolto perso." % campi_persi, "allarme")
		_notifica("Piena disastrosa: %d campi allagati." % campi_persi, true, dove)


func _inizia_siccita() -> void:
	siccita = 1 + rng.randi() % 2
	sorgenti_basse = true
	stat["siccita"] += 1
	if not presagio_vero.is_empty():
		if presagio_vero["scelta"] == "razionare":
			bonus += 6.0
			stat["presagi_letti"] += 1
			_scrivi("Arriva la siccità: le scorte accumulate ascoltando il presagio aiutano il villaggio.", "buono")
		else:
			bonus -= 8.0
			_scrivi("Arriva la siccità annunciata dalle sorgenti: averla ignorata costa caro agli anziani.", "allarme")
		presagio_vero = {}
	else:
		_scrivi("Siccità improvvisa.", "allarme")
	_notifica("Siccità per %s: rendono solo i campi vicini al fiume e alle sorgenti." % ("un anno" if siccita == 1 else "due anni"), true, mondo_di_px(centro))


## Abitato spontaneo (decisione di Fede): le case nascono da sole vicino al centro, all'acqua e
## lontano dal pericolo di piena finché la memoria del rischio è viva; il giocatore orienta la
## crescita con campi, sentieri e granaio.
func disponi_case() -> void:
	if not fondato:
		return
	var servono := ceili(pop / 8.0)
	while case.size() > servono:
		case.pop_back()
	var lc := lotto_da_mondo(mondo_di_px(centro).x, mondo_di_px(centro).y)
	var r := 3 + ceili(1.4 * sqrt(servono)) + raggio_extra * 3
	var paura := memoria / 100.0
	var occupati := {}
	for c in case:
		occupati[c] = true
	var granaio_l := lotto_da_mondo(granaio.x, granaio.y) if granaio.x >= 0 else Vector2i(-99999, -99999)
	var tentativi := 0
	while case.size() < servono and tentativi < 200:
		tentativi += 1
		var migliore := Vector2i(-1, -1)
		var punteggio := -1e9
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var l := lc + Vector2i(dx, dy)
				if l == lc or cheb(l, granaio_l) <= 1 or macerie.has(l):
					continue
				var w := centro_lotto(l)
				var p := px_da_mondo(w.x, w.y)
				if w.x < 0 or w.y < 0 or w.x > dati.lato_metri() or w.y > dati.lato_metri():
					continue
				var i := px(p)
				if not edificabile(i) or campi.has(i) or sentieri.has(i):
					continue
				var vicina := false
				for oy in [-1, 0, 1]:
					for ox in [-1, 0, 1]:
						if occupati.has(l + Vector2i(ox, oy)):
							vicina = true
				if vicina:
					continue
				var d := Vector2(dx, dy).length() * LOTTO / 40.0
				var caso := float((l.x * 73856093 ^ l.y * 19349663) & 0xffff) / 65536.0
				var sc := -d * 1.2 - piena(i) * paura * 8.0 + acqua_qualsiasi(i) - (1.0 if dati.tipo[i] == MappaDati.GESSI else 0.0) + caso * 0.25
				if sc > punteggio:
					punteggio = sc
					migliore = l
		if migliore.x == -1 and migliore.y == -1:
			break
		case.append(migliore)
		occupati[migliore] = true
	affollamento = clampf(float(servono - case.size()) / servono, 0.0, 1.0) if servono > 0 else 0.0


func _fonda_figlio() -> void:
	var migliore := -1
	var punteggio := -1e9
	for y in range(0, n, 2):
		for x in range(0, n, 2):
			var p := Vector2i(x, y)
			var i := px(p)
			var d := cheb(p, centro)
			if not edificabile(i) or d < 9 * PX_CELLA or d > 16 * PX_CELLA:
				continue
			var sc := fert(i) + acqua_qualsiasi(i) - piena(i) + float((i * 40503) % 97) / 200.0
			if sc > punteggio:
				punteggio = sc
				migliore = i
	pop *= 0.67
	bonus += 6.0
	if migliore >= 0:
		figli.append(migliore)
	_scrivi("Un terzo delle famiglie parte e fonda un villaggio figlio.", "buono")
	disponi_case()


func _abbandona() -> void:
	stat["abbandoni"] += 1
	rovine.append(mondo_di_px(centro))
	for c in case:
		rovine.append(centro_lotto(c))
	_scrivi("Il villaggio è abbandonato. Le rovine restano nel terreno.", "allarme")
	fondato = false
	centro = Vector2i(-1, -1)
	case = []
	campi = []
	_tecnica_campi = {}
	sentieri = []
	tratti_sentiero = []
	granaio = Vector2(-1, -1)
	pop = 0.0
	cibo = 0.0
	raggio_extra = 0
	_decidi("abbandono", "Il villaggio è abbandonato",
		"Le ultime famiglie se ne vanno. Le case crollano e diventano uno strato nel terreno: un giorno qualcuno ci scaverà sopra.\nPuoi fondare di nuovo, qui o altrove sulla mappa.", [{"id": "ok", "testo": "Scegli un nuovo sito", "nota": ""}])


func _fine() -> void:
	finito = true
	var testo := "Il villaggio conta %d abitanti%s.\nAnni di carestia: %d · Piene: %d · Siccità: %d\nPresagi letti correttamente: %d su %d · Fondazioni: %d%s\nLa domanda del prototipo: la scelta del sito ha pesato? Prova un'altra partita da un sito diverso e confronta." % [
		roundi(pop), (" e ha fondato %d villaggi figli" % figli.size()) if not figli.is_empty() else "",
		stat["carestie"], stat["piene"], stat["siccita"], stat["presagi_letti"], stat["presagi_totali"], stat["fondazioni"],
		(" (abbandoni: %d)" % stat["abbandoni"]) if stat["abbandoni"] > 0 else ""]
	_decidi("fine", "%s: cinque secoli dopo" % anno_testo(anno), testo, [{"id": "ok", "testo": "Resta a guardare la mappa", "nota": ""}])
