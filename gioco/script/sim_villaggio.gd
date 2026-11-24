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
## ammodernamento (decisione di Fede del 24/11/2026): "sospeso" o "attivo". Attivo, ogni anno una
## parte dei campi fatti con una tecnica vecchia passa alla tecnica dell'epoca, pagando cibo (le
## braccia che ci lavorano); non si costruisce niente da zero, si sovrascrive il tipo vecchio.
var politiche := {"raccolto": "comune", "stranieri": "caso", "ammodernamento": "sospeso"}
const POLITICHE := {
	"raccolto": ["comune", "famiglie"],
	"stranieri": ["aperta", "caso", "chiusa"],
	"ammodernamento": ["sospeso", "attivo"],
}

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
## Avvisi brevi a schermo (eventi rilevanti).
var avvisi: Array[String] = []
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
	stat["fondazioni"] += 1
	var v := valuta_sito(p)
	var nome := (" presso il " + String(v["sito"]["nome"]).to_lower()) if v["sito"] != null else ""
	_scrivi("Fondazione%s. Acqua %s, rischio di piena %s." % [nome, v["acqua"][0], v["piena"][0]], "buono")
	disponi_case()


func raggio_campi() -> int:
	return (5 + raggio_extra) * PX_CELLA


func a_portata(p: Vector2i) -> bool:
	if not fondato:
		return false
	if cheb(p, centro) <= raggio_campi():
		return true
	for s in sentieri:
		if cheb(p, px_di(s)) <= 2 * PX_CELLA:
			return true
	return false


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
		return "Troppo lontano dal villaggio. Un sentiero allunga il raggio dei campi."
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


## Prolunga i sentieri dal punto più vicino della rete (centro o sentieri) fino a `p`, in linea
## retta. Restituisce "" se fatto, altrimenti il motivo.
func traccia_sentiero(p: Vector2i) -> String:
	if not fondato:
		return "Prima bisogna fondare il villaggio."
	var partenza := centro
	var migliore := cheb(p, centro)
	for s in sentieri:
		var q := px_di(s)
		if cheb(p, q) < migliore:
			migliore = cheb(p, q)
			partenza = q
	if migliore == 0:
		return "Il sentiero passa già da qui."
	var tratto: Array[int] = []
	var passi := migliore
	for k in range(1, passi + 1):
		var q := Vector2i(roundi(lerpf(partenza.x, p.x, float(k) / passi)), roundi(lerpf(partenza.y, p.y, float(k) / passi)))
		var t := dati.tipo[px(q)]
		if t == MappaDati.FIUME or t == MappaDati.PALUDE:
			return "Il sentiero non attraversa il fiume né la palude."
		if not sentieri.has(px(q)) and not tratto.has(px(q)):
			tratto.append(px(q))
	if sentieri.size() + tratto.size() > MAX_SENTIERO:
		return "Per ora i sentieri sono lunghi al massimo %d km." % (MAX_SENTIERO * dati.metri_per_px / 1000.0)
	sentieri.append_array(tratto)
	tratti_sentiero.append([partenza, p])
	# Le case sul nuovo sentiero si spostano.
	var prima := case.size()
	case = case.filter(func(c: Vector2i) -> bool: return not tratto.has(px(px_da_mondo(centro_lotto(c).x, centro_lotto(c).y))))
	if case.size() != prima:
		disponi_case()
	return ""


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


func politica(id: String) -> String:
	return politiche.get(id, "")


## Cambia una politica. Prima della fondazione si sceglie gratis (non c'è ancora un'abitudine).
func imposta_politica(id: String, valore: String) -> bool:
	if not POLITICHE.has(id) or not valore in POLITICHE[id] or politiche[id] == valore:
		return false
	politiche[id] = valore
	if not fondato:
		return true
	# Le abitudini pesano: cambiare una regola costa consenso. L'ammodernamento no, perché il suo
	# costo è il cibo speso ogni anno per rifare i campi.
	if id != "ammodernamento":
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
		"ammodernamento:attivo":
			_scrivi("Si comincia a rifare i campi con la tecnica nuova.")
		"ammodernamento:sospeso":
			_scrivi("L'ammodernamento dei campi è sospeso.")
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
			if o == "allargarsi":
				raggio_extra += 2
				salute -= 5.0
				_scrivi("Il villaggio si allarga.")
			else:
				_fonda_figlio()


# ---------- un anno ----------

func passo() -> void:
	if not fondato or finito or in_attesa():
		return
	allagati = {}
	clima = 0.75 + rng.randf() * 0.4
	if rng.randf() < 0.045:
		_piena()
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
	if siccita == 0 and siccita_tra < 0 and cometa.is_empty() and rng.randf() < 0.012:
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
	# Stranieri: in media un gruppo ogni 40 anni, dopo i primi anni del villaggio.
	if anno > ANNO_INIZIO + 10 and not in_attesa() and rng_stranieri.randf() < 0.025:
		_arrivo_stranieri()
	if anni_sapere > 0:
		anni_sapere -= 1
	if politica("ammodernamento") == "attivo":
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
	var consumo := pop * (0.8 if razionamento > 0 else 1.0)
	cibo += raccolto - consumo
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
			avvisi.append("Carestia: manca il %d%% del cibo necessario." % roundi(carestia * 100.0))
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
			[{"id": "allargarsi", "testo": "Allargarsi", "nota": "Il villaggio può crescere più lontano dal centro. Per qualche anno la salute ne risente."},
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
		_decidi("crisi", "Il villaggio si divide", "Gli anziani hanno perso ogni autorità. Molte famiglie lasciano il villaggio.", [{"id": "ok", "testo": "Continua", "nota": ""}])
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
	return 12.0 * fert(i) * fattore * (1.12 if politica("raccolto") == "famiglie" else 1.0) \
		* (1.08 if anni_sapere > 0 else 1.0) * RESA_TECNICA[tecnica_campo(i)] / AREA_CELLA


func _piena() -> void:
	# Dove arriva l'acqua: ogni pixel con la sua probabilità (rischio di piena della mappa).
	var case_perse := 0
	var campi_persi := 0
	var colpiti := {}
	var vicino := Rect2i(centro - Vector2i(40, 40), Vector2i(81, 81))
	for y in range(maxi(vicino.position.y, 0), mini(vicino.end.y, n)):
		for x in range(maxi(vicino.position.x, 0), mini(vicino.end.x, n)):
			var i := y * n + x
			if edificabile(i) and piena(i) > 0.0 and rng.randf() < piena(i):
				colpiti[i] = true
	var rimaste: Array[Vector2i] = []
	for c in case:
		var p := centro_lotto(c)
		if colpiti.has(px(px_da_mondo(p.x, p.y))):
			case_perse += 1
		else:
			rimaste.append(c)
	case = rimaste
	for f in campi:
		if colpiti.has(f):
			campi_persi += 1
			allagati[f] = true
	if granaio.x >= 0 and colpiti.has(px(px_da_mondo(granaio.x, granaio.y))):
		cibo *= 0.6
	pop -= minf(pop, case_perse * 2.5)
	memoria = 100.0
	stat["piene"] += 1
	var nome := "Il fiume esce dal letto"
	if case_perse > 0:
		_scrivi("%s: %d case distrutte, %d campi allagati." % [nome, case_perse, campi_persi], "allarme")
		bonus -= minf(8.0, case_perse)
		_decidi("piena", nome, "L'acqua ha travolto %d case e allagato %d campi: il loro raccolto di quest'anno è perso.\nIl ricordo del pericolo torna vivo: per qualche generazione le nuove case si terranno lontane dall'acqua. Poi il ricordo sbiadirà." % [case_perse, campi_persi], [{"id": "ok", "testo": "Continua", "nota": ""}])
	elif campi_persi > 0:
		_scrivi("%s: %d campi allagati, raccolto perso." % [nome, campi_persi], "allarme")
	else:
		_scrivi("%s, ma il villaggio non è toccato." % nome)


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
	avvisi.append("Siccità per %s: rendono solo i campi vicini al fiume e alle sorgenti." % ("un anno" if siccita == 1 else "due anni"))


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
