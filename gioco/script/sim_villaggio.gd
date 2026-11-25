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
## Spinte al consenso dei gruppi, che si smorzano negli anni (eventi e scelte).
var bonus := {"anziani": 0.0, "famiglie": 0.0, "sacerdote": 0.0}
## Politiche del villaggio (non costruzioni: regole che valgono finché non si cambiano; decisione
## di Fede del 24/11/2026). Cambiarne una costa un po' di consenso: le abitudini pesano.
## raccolto: "comune" (più consenso) o "famiglie" (più raccolto).
## stranieri (proposta di Claude): "aperta" (si accolgono sempre), "chiusa" (si respingono sempre),
## "caso" (ogni arrivo ferma il tempo e si decide). Dal 25/11/2026 (Fede: ritmo meditativo) si parte
## con "aperta": il primo arrivo ferma il gioco una volta e la scelta diventa la regola.
var politiche := {"raccolto": "comune", "stranieri": "aperta"}
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
## margine (proposta di Claude). Numeri da tarare; caccia e pesca pesano di più dal 24/11/2026
## (Fede).
const RAGGIO_RISORSE := 40  # pixel (1,6 km)
const QUOTA_CACCIA := 0.6  # cibo per abitante che caccia e raccolta possono dare al massimo
const QUOTA_PESCA := 0.35
const RESA_BOSCO := 0.12
const RESA_ACQUA := 0.4
var selvaggina := 1.0
var ultima_caccia := 0.0
var ultima_pesca := 0.0
## Offerta dell'anno (quanto caccia e pesca potrebbero dare) e andamento della selvaggina, per gli
## indicatori (richiesta di Fede: si vede se si caccia troppo e quanto offrono bosco e acque).
var offerta_caccia := 0.0
var offerta_pesca := 0.0
var andamento_selvaggina := 0.0  # variazione negli ultimi 5 anni
var _storia_selvaggina: Array[float] = []
var _caccia_eccessiva := false
## Fonti di cibo (politica approvata da Fede il 24/11/2026): agricoltura, caccia e pesca si
## accendono e si spengono; almeno una resta accesa. Spegnerne una non cancella niente: si smette
## di lavorarla e le braccia passano alle altre (caccia spenta: +20% di campi lavorati; pesca
## spenta: +10%; agricoltura spenta: caccia e pesca possono dare il 50% in più). Cambiare costa un
## poco di consenso (−2).
var fonti := {"agricoltura": true, "caccia": true, "pesca": true}
const FONTI := ["agricoltura", "caccia", "pesca"]
## Raccolto che darebbero tutti i campi se fossero lavorati: l'offerta dell'agricoltura.
var raccolto_potenziale := 0.0
## Sotto questa soglia di selvaggina si caccia troppo (indicatore rosso e notifica).
const SOGLIA_SELVAGGINA := 0.4
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
## Zona agricola (decisione di Fede del 24/11/2026): i pixel dove la comunità può coltivare. Dentro
## la zona le famiglie dissodano da sole i campi quando servono, come fanno con le case; il
## giocatore può anche porre i campi a mano (strumento Campo).
var zona := {}
## Quota massima di nuovi campi all'anno per abitante (dissodare richiede tempo e braccia).
const DISSODAMENTO_PER_ABITANTE := 0.05
## Quanto in più del bisogno le famiglie cercano di raccogliere (proposta di Claude, da tarare).
const MARGINE_RACCOLTO := 1.4
## Resa di un pixel di campo (0,16 ha) su terra di fertilità 1, prima di clima e tecnica: circa
## una persona e mezza sfamata all'anno su terra media (Fede: i campi erano troppi per la gente;
## prima 12, poi 24, ora 36).
const RESA_CAMPO := 36.0
## Abitanti per casa (prima 8, poi 6: case troppo poche rispetto ai campi).
const ABITANTI_PER_CASA := 5.0
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

# ---------- dinamiche della prima epoca (decisioni di Fede del 25/11/2026, docs/era-origini.md) ----------
## Abbondanza: un solo indicatore con tre parti (cibo che avanza, salute, spazio). Le nascite la
## seguono: con scorte, salute e case il villaggio cresce già nei primi decenni; vicino al limite
## della terra le scorte calano e le nascite rallentano da sole, senza passare per le carestie.
## Pesi e soglia: proposta di Claude, da tarare con le partite automatiche.
const PESI_ABBONDANZA := {"cibo": 0.45, "salute": 0.3, "spazio": 0.25}
## Mesi di scorte che valgono "cibo che avanza" pieno.
const MESI_PIENI := 24.0
## Sotto questa abbondanza (0–1) la popolazione non cresce; sopra cresce fino a CRESCITA_MASSIMA.
const SOGLIA_CRESCITA := 0.62
const CRESCITA_MASSIMA := 0.014
var abbondanza := 0.0
var parti_abbondanza := {"cibo": 0.0, "salute": 0.0, "spazio": 0.0}
## Tappe (decisione di Fede del 25/11/2026): soglie di abitanti che aprono gli strumenti; una volta
## raggiunte restano anche se gli abitanti calano. Soglie di partenza, da tarare.
const TAPPE := [
	{"nome": "Fondazione", "abitanti": 0, "apre": ["zona", "campi", "sentiero", "fonti"]},
	{"nome": "Gruppo di famiglie", "abitanti": 60, "apre": ["granaio", "raccolto"]},
	{"nome": "Villaggio", "abitanti": 100, "apre": ["luogo_sacro", "pascolo"]},
	{"nome": "Grande villaggio", "abitanti": 150, "apre": ["stranieri", "bosco_sacro"]},
	{"nome": "Territorio", "abitanti": 250, "apre": ["casali", "strade"]},
]
var tappa := 0
## Legna (decisione di Fede del 25/11/2026: risorse cibo, legna, braccia, animali). Si raccoglie nei
## boschi vicini e si ricava dissodando; serve per case, granaio e focolari. Le case spontanee
## crescono solo se c'è legna. Numeri: proposta di Claude, da tarare.
var legna := 0.0
const LEGNA_INIZIALE := 40.0
const LEGNA_PER_ABITANTE := 0.3  # quanta legna l'anno può raccogliere un abitante, se il bosco la offre
const RESA_LEGNA := 0.08  # legna l'anno che un pixel di bosco vicino può dare senza consumarsi
const CONSUMO_FOCOLARI := 0.08  # legna l'anno per abitante
const MANUTENZIONE_CASA := 0.25  # legna l'anno per casa
const COSTO_CASA := 12.0
const LEGNA_DISSODAMENTO := 3.0  # legna da un pixel di bosco dissodato
const COSTO_GRANAIO := 30.0
const ANNI_CANTIERE_GRANAIO := 3
var ultima_legna := 0.0
var offerta_legna := 0.0
var consumo_legna := 0.0
## Anni che mancano perché il granaio sia finito (0: pronto).
var cantiere_granaio := 0
## Bosco attorno al centro alla fondazione: il disboscamento si misura rispetto a questo.
var bosco_iniziale := 0.0
## Quota di bosco perso attorno al villaggio (0–1): erosione, piene più rapide, meno selvaggina.
var disboscamento := 0.0
## Consenso per gruppo (decisione di Fede del 24–25/11/2026): anziani, famiglie, sacerdote; un solo
## indicatore (legittimita) con il dettaglio al passaggio. Il sacerdote diventa un gruppo con il
## luogo sacro; fino ad allora i presagi li leggono gli anziani.
var consenso := {"anziani": 60.0, "famiglie": 60.0, "sacerdote": 60.0}
var sacerdote_attivo := false
## Piene che fertilizzano (decisione di Fede del 25/11/2026): i campi allagati da una piena di
## stagione ricevono limo e rendono di più per qualche anno.
const BONUS_LIMO := 1.25
const ANNI_LIMO := 3
var limo := {}  # indice del pixel -> anni rimasti
## Piena disastrosa annunciata: anni che mancano (-1: nessuna in arrivo).
var piena_tra := -1
var gia_piena_disastrosa := false
## Presagi: al massimo uno ogni secolo circa (proposta approvata da Fede il 25/11/2026).
const ANNI_TRA_PRESAGI := 100
var _ultimo_presagio := -99999
var gia_stranieri := false
var _stranieri_prima := false
var gia_carestia := false
## La zona agricola è piena (niente avviso: lo dice la mappa; decisione di Fede del 25/11/2026).
var zona_piena := false
var stat := {"carestie": 0, "piene": 0, "siccita": 0, "fondazioni": 0, "presagi_letti": 0, "presagi_totali": 0, "abbandoni": 0, "febbri": 0}
var storia := {"pop": [], "cibo": [], "salute": [], "legittimita": [], "abbondanza": [], "legna": []}
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
const PROB_PIENA_DISASTROSA := 0.0025
## Presagi, stranieri, carestie (decisioni di Fede del 25/11/2026; numeri da tarare).
const PROB_PRESAGIO := 0.012  # all'anno, quando un presagio può arrivare
const PROB_STRANIERI := 0.016  # all'anno con abbondanza piena
## Sotto questa quota di cibo mancante è un'annata magra: le scorte finiscono, ma non è carestia.
const SOGLIA_CARESTIA := 0.05
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
	out["pesca"] = ["buona, fiume vicino", false] if r["acqua"] > 150.0 else (["torrenti o fiume a distanza", false] if r["acqua"] > 40.0 else ["scarsa", true])
	# Quanto, da 0 a 1, per le barre della lettura del sito (per la piena: quanto è alto il rischio).
	out["valori"] = {
		"acqua": clampf(maxf(a, s * 0.6), 0.0, 1.0),
		"fertilita": clampf(fm / 1.2, 0.0, 1.0),
		"bosco": clampf(r["bosco"] / 900.0, 0.0, 1.0),
		"pesca": clampf(r["acqua"] / 300.0, 0.0, 1.0),
		"piena": clampf(fl, 0.0, 1.0),
		"difesa": clampf(difesa / 1.2, 0.0, 1.0),
		"aria": clampf(dm / 8.0, 0.0, 1.0),
	}
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
	_storia_selvaggina = []
	fonti = {"agricoltura": true, "caccia": true, "pesca": true}
	_caccia_eccessiva = false
	_anni_risorse = 0
	legna = LEGNA_INIZIALE
	consenso = {"anziani": 60.0, "famiglie": 60.0, "sacerdote": 60.0}
	cantiere_granaio = 0
	limo = {}
	piena_tra = -1
	zona_piena = false
	_risorse = risorse_attorno(p)
	bosco_iniziale = _risorse["bosco"]
	disboscamento = 0.0
	_aggiorna_abbondanza()
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
			_legna_dal_dissodamento(i)
			campi.append(i)
			_tecnica_campi[i] = tecnica_corrente
			aggiunti += 1
	return aggiunti


## Aggiunge pixel alla zona agricola (solo terra asciutta dentro il contado). Restituisce quanti.
func aggiungi_zona(lista: Array[Vector2i]) -> int:
	var aggiunti := 0
	for p in lista:
		if p.x < 0 or p.y < 0 or p.x >= n or p.y >= n:
			continue
		var i := px(p)
		if not zona.has(i) and edificabile(i) and a_portata(p):
			zona[i] = true
			aggiunti += 1
	return aggiunti


func togli_zona(lista: Array[Vector2i]) -> int:
	var tolti := 0
	for p in lista:
		if zona.erase(px(p)):
			tolti += 1
	return tolti


## Raggio dell'abitato in metri (dove nascono le case): i campi della zona agricola lo lasciano libero.
func raggio_abitato() -> float:
	var servono := ceili(pop / ABITANTI_PER_CASA)
	return (3 + ceili(1.4 * sqrt(servono)) + raggio_extra * 3) * LOTTO


## Resa attesa di un campo in un anno normale (per decidere quanti campi dissodare).
func _resa_attesa(i: int) -> float:
	return RESA_CAMPO * fert(i) * 0.95 * (0.85 + 0.15 * acqua_qualsiasi(i)) * RESA_TECNICA[tecnica_corrente] / AREA_CELLA


## Le famiglie dissodano nella zona agricola i campi che mancano per sfamarsi: tanti quanti ne
## servono (più un piccolo margine), un po' ogni anno, dalla terra migliore e più vicina, lasciando
## libero l'abitato. Restituisce quanti campi sono stati dissodati.
func _dissoda_zona() -> int:
	if zona.is_empty() or not fonti["agricoltura"]:
		return 0
	# Le famiglie coltivano per mettere da parte, non solo per mangiare: è il margine che riempie le
	# scorte e fa crescere l'abbondanza (25/11/2026; prima +15%).
	var fabbisogno := pop * MARGINE_RACCOLTO - ultima_caccia - ultima_pesca
	var attesa := 0.0
	for i in campi:
		attesa += _resa_attesa(i)
	var mancante := fabbisogno - attesa
	if mancante <= 0.0:
		zona_piena = false
		return 0
	var braccia := int(pop * 0.55 / 3.0 * AREA_CELLA)
	var massimo := mini(maxi(2, int(pop * DISSODAMENTO_PER_ABITANTE)), braccia - campi.size())
	if massimo <= 0:
		return 0
	var c := mondo_di_px(centro)
	var libero := raggio_abitato() + 20.0
	var candidati: Array[int] = []
	for i in zona:
		if campi.has(i):
			continue
		var p := px_di(i)
		if mondo_di_px(p).distance_to(c) < libero or motivo_campo(p) != "":
			continue
		candidati.append(i)
	# Zona piena: niente avviso (decisione di Fede del 25/11/2026), lo dice la mappa.
	zona_piena = candidati.is_empty()
	if candidati.is_empty():
		return 0
	candidati.sort_custom(func(a: int, b: int) -> bool:
		return fert(a) - mondo_di_px(px_di(a)).distance_to(c) / 1500.0 > fert(b) - mondo_di_px(px_di(b)).distance_to(c) / 1500.0)
	var nuovi := 0
	for i in candidati:
		if mancante <= 0.0 or nuovi >= massimo:
			break
		_legna_dal_dissodamento(i)
		campi.append(i)
		_tecnica_campi[i] = tecnica_corrente
		mancante -= _resa_attesa(i)
		nuovi += 1
	return nuovi


## Dissodare un pixel di bosco dà legna (si abbatte il bosco).
func _legna_dal_dissodamento(i: int) -> void:
	if fondato and bosco_presente.call(i):
		legna += LEGNA_DISSODAMENTO


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
	if not sbloccato("granaio"):
		return "Il granaio si apre con la tappa \"%s\" (%d abitanti)." % [TAPPE[tappa_di("granaio")]["nome"], TAPPE[tappa_di("granaio")]["abitanti"]]
	if legna < COSTO_GRANAIO:
		return "Servono %d di legna per costruire il granaio (ora %d)." % [roundi(COSTO_GRANAIO), floori(legna)]
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
	legna -= COSTO_GRANAIO
	cantiere_granaio = ANNI_CANTIERE_GRANAIO
	_scrivi("Si comincia a costruire il granaio: servono %d anni di lavoro." % ANNI_CANTIERE_GRANAIO)
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
	esito["zona"] = 0
	for i in zona.keys():
		if dentro.call(i):
			zona.erase(i)
			esito["zona"] += 1
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
	# I campi tolgono il bosco anche senza la grafica (nel gioco lo sa già l'uso del suolo).
	var coltivati := {}
	for c in campi:
		coltivati[c] = true
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
			elif bosco_presente.call(j) and not coltivati.has(j):
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


## Accende o spegne una fonte di cibo. Almeno una resta accesa. Restituisce vero se è cambiata.
func imposta_fonte(fonte: String, accesa: bool) -> bool:
	if not fonti.has(fonte) or fonti[fonte] == accesa:
		return false
	if not accesa and fonti.values().count(true) <= 1:
		return false
	fonti[fonte] = accesa
	if fondato:
		_cambia_consenso("anziani", -2.0)
		var nomi := {"agricoltura": "i campi", "caccia": "la caccia", "pesca": "la pesca"}
		_scrivi(("Si riprende %s." if accesa else "Gli anziani sospendono %s: le braccia vanno alle altre fonti di cibo.") % nomi[fonte])
	return true


## La tappa (indice in TAPPE) che apre uno strumento o una politica; 0 se non è nell'elenco.
static func tappa_di(cosa: String) -> int:
	for k in TAPPE.size():
		if cosa in TAPPE[k]["apre"]:
			return k
	return 0


## Vero se lo strumento o la politica è già aperto (le tappe raggiunte restano).
func sbloccato(cosa: String) -> bool:
	return tappa >= tappa_di(cosa)


## Il granaio funziona (costruito e finito).
func granaio_pronto() -> bool:
	return granaio.x >= 0 and cantiere_granaio <= 0


func _aggiorna_tappa() -> void:
	while tappa + 1 < TAPPE.size() and pop >= TAPPE[tappa + 1]["abitanti"]:
		tappa += 1
		var t: Dictionary = TAPPE[tappa]
		var nomi := {"granaio": "il granaio", "raccolto": "la divisione del raccolto", "luogo_sacro": "il luogo sacro",
			"pascolo": "il pascolo", "stranieri": "la regola sugli stranieri", "bosco_sacro": "il bosco sacro",
			"casali": "i casali nel contado", "strade": "le strade"}
		var aperti: Array[String] = []
		for a in t["apre"]:
			aperti.append(nomi.get(a, a))
		_scrivi("Nuova tappa: %s. Si aprono %s." % [String(t["nome"]).to_lower(), " e ".join(aperti)], "buono")
		_notifica("Nuova tappa: %s (%d abitanti). Si aprono %s." % [t["nome"], t["abitanti"], " e ".join(aperti)], false, mondo_di_px(centro))


func politica(id: String) -> String:
	return politiche.get(id, "")


## Cambia una politica. Prima della fondazione si sceglie gratis (non c'è ancora un'abitudine).
func imposta_politica(id: String, valore: String) -> bool:
	if not POLITICHE.has(id) or not valore in POLITICHE[id] or politiche[id] == valore:
		return false
	if fondato and not sbloccato(id):
		return false
	politiche[id] = valore
	if not fondato:
		return true
	# Le abitudini pesano: cambiare una regola costa consenso, meno se gli anziani sono contenti
	# (decisione di Fede del 25/11/2026).
	_cambia_consenso("anziani", -4.0 * (1.5 - consenso["anziani"] / 100.0))
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
	# Il primo arrivo ferma il gioco una volta e la scelta diventa la regola (decisione di Fede del
	# 25/11/2026); poi decide la politica, e il gioco si ferma solo con "caso per caso".
	if not gia_stranieri:
		gia_stranieri = true
		_stranieri_prima = true
		_gruppo_stranieri = n_persone
		_decidi("stranieri", "Arrivano degli stranieri",
			"Un gruppo di %d persone arriva dalla valle con i suoi animali e chiede di fermarsi. Coltivano in un modo che qui non si conosce.\nLa scelta di oggi diventa l'usanza del villaggio: potrai cambiarla dalle politiche." % n_persone,
			[{"id": "accogliere", "testo": "Accoglierli", "nota": "Più braccia e tecniche nuove per i campi; qualche malattia nuova e un po' di attrito."},
			 {"id": "respingere", "testo": "Mandarli via", "nota": "Nulla cambia. Il villaggio resta unito."}])
		return
	match politica("stranieri"):
		"aperta":
			_accogli(n_persone)
		"chiusa":
			_cambia_consenso("anziani", 1.0)
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
	_cambia_consenso("famiglie", -1.5)
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
				_cambia_consenso("famiglie", -3.0)
				_scrivi("Gli anziani ordinano di razionare il cibo.")
			else:
				_scrivi("Il villaggio non dà peso alle sorgenti basse.")
		"cometa":
			cometa["scelta"] = o
			if o == "offerte":
				cibo *= 0.8
				razionamento = maxi(razionamento, 2)
				_cambia_consenso("sacerdote", 4.0)
				_scrivi("Il villaggio offre parte del raccolto e digiuna.")
			else:
				_cambia_consenso("sacerdote", -5.0)
				_scrivi("Gli anziani non danno ascolto al sacerdote.")
		"primo_cattivo":
			if o == "razionare":
				razionamento = 3
				_cambia_consenso("famiglie", -2.0)
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
			if _stranieri_prima:
				_stranieri_prima = false
				politiche["stranieri"] = "aperta" if o == "accogliere" else "chiusa"
			if o == "accogliere":
				_accogli(_gruppo_stranieri)
			else:
				_cambia_consenso("anziani", 1.0)
				_scrivi("Gli stranieri vengono mandati via.")
			_gruppo_stranieri = 0
		"affollamento":
			if o == "restare":
				raggio_extra += 1
				salute -= 3.0
				_scrivi("Le famiglie restano: l'abitato si allarga.")
			else:
				_emigra()


# ---------- un anno ----------

func passo() -> void:
	if not fondato or finito or in_attesa():
		return
	allagati = {}
	clima = 0.75 + rng.randf() * 0.4
	# Piene (decisioni di Fede del 24–25/11/2026). Le disastrose sono rare, coerenti con il sito (il
	# danno lo decide il rischio della mappa) e con le azioni (il bosco tagliato attorno al villaggio
	# le rende più probabili), e arrivano dopo un segno. Quelle di stagione portano limo.
	var disastrosa_ora := false
	if piena_tra > 0:
		piena_tra -= 1
		if piena_tra == 0:
			piena_tra = -1
			disastrosa_ora = true
			_piena(true)
	elif rng.randf() < PROB_PIENA_DISASTROSA * (1.0 + 3.0 * disboscamento):
		piena_tra = 1 + rng.randi() % 2
		if _esposto_alle_piene():
			_scrivi("Piove da settimane sui colli: i corsi d'acqua sono torbidi e gonfi.")
			_notifica("Piove da settimane sui colli: i corsi d'acqua sono gonfi e le terre basse sono a rischio.", false, mondo_di_px(centro))
	if not disastrosa_ora and rng.randf() < PROB_PIENA_STAGIONALE:
		_piena(false)
	for k in limo.keys():
		limo[k] -= 1
		if limo[k] <= 0:
			limo.erase(k)
	# Siccità: arriva sempre dopo il presagio delle sorgenti (decisione di Fede del 25/11/2026).
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
	# Presagi: al massimo uno ogni secolo circa; sono le sole scelte che fermano il gioco ogni volta.
	var presagio_possibile := anno - _ultimo_presagio >= ANNI_TRA_PRESAGI and anno > ANNO_INIZIO + 20 \
		and siccita == 0 and siccita_tra < 0 and cometa.is_empty() and presagio_vero.is_empty()
	if presagio_possibile and rng.randf() < PROB_PRESAGIO:
		_ultimo_presagio = anno
		stat["presagi_totali"] += 1
		if rng.randf() < 0.6:
			siccita_tra = 2 + rng.randi() % 2
			sorgenti_basse = true
			presagio_vero = {"scelta": ""}
			_decidi("sorgenti", "Le sorgenti calano",
				"Le sorgenti danno meno acqua del solito e l'erba ingiallisce presto. Gli anziani chiedono di mettere da parte il raccolto.\nControlla la mappa dell'acqua.",
				[{"id": "razionare", "testo": "Razionare e accumulare", "nota": "Per tre anni si mangia meno: salute e consenso calano un poco."},
				 {"id": "ignorare", "testo": "Ignorare", "nota": "Nessun costo oggi."}])
		else:
			cometa = {"scelta": "", "anni": 3}
			_decidi("cometa", "Una cometa nel cielo",
				"Una cometa attraversa il cielo per molte notti. Il sacerdote annuncia una carestia e chiede offerte e digiuno.",
				[{"id": "offerte", "testo": "Offerte e digiuno", "nota": "Si sacrifica parte delle scorte e si raziona per due anni. Il sacerdote è soddisfatto."},
				 {"id": "ignorare", "testo": "Ignorare il presagio", "nota": "Il sacerdote protesta e il consenso cala, almeno per ora."}])
	elif not cometa.is_empty() and cometa["scelta"] != "":
		cometa["anni"] -= 1
		if cometa["anni"] <= 0:
			if cometa["scelta"] == "ignorare":
				_cambia_consenso("anziani", 9.0)
				stat["presagi_letti"] += 1
				_scrivi("Nessuna carestia dopo la cometa: gli anziani avevano visto giusto.", "buono")
			elif cometa["scelta"] == "offerte":
				_cambia_consenso("famiglie", -3.0)
				_scrivi("Nessuna carestia dopo la cometa: il digiuno è stato inutile.")
			cometa = {}
	# Stranieri: li attira l'abbondanza (decisione di Fede del 25/11/2026); in un villaggio prospero
	# arriva un gruppo ogni 60 anni circa.
	if anno > ANNO_INIZIO + 10 and not in_attesa() and rng_stranieri.randf() < PROB_STRANIERI * abbondanza:
		_arrivo_stranieri()
	if anni_sapere > 0:
		anni_sapere -= 1
	if ammodernamenti["agricolo"]:
		_ammoderna()
	_dissoda_zona()
	if cantiere_granaio > 0:
		cantiere_granaio -= 1
		if cantiere_granaio == 0:
			_scrivi("Il granaio è finito: le scorte si conservano meglio.", "buono")
	# Raccolto: le braccia lavorano prima i campi più fertili. Famiglie contente lavorano di più
	# (decisione di Fede del 25/11/2026); un cantiere aperto toglie un po' di braccia.
	var lavoro: float = (0.9 + 0.2 * consenso["famiglie"] / 100.0) * (0.95 if cantiere_granaio > 0 else 1.0)
	var braccia: float = pop * 0.55 * lavoro * (1.0 + (0.0 if fonti["caccia"] else 0.2) + (0.0 if fonti["pesca"] else 0.1))
	var lavorabili := int(braccia / 3.0 * AREA_CELLA) if fonti["agricoltura"] else 0
	var ordinati := campi.duplicate()
	ordinati.sort_custom(func(a: int, b: int) -> bool: return fert(a) > fert(b))
	var raccolto := 0.0
	raccolto_potenziale = 0.0
	for k in ordinati.size():
		var r := _resa(ordinati[k])
		raccolto_potenziale += r
		if k < lavorabili:
			raccolto += r
	ultimo_raccolto = raccolto
	ultimi_lavorati = mini(lavorabili, ordinati.size())
	var piu_braccia := 1.0 if fonti["agricoltura"] else 1.5
	# Caccia, raccolta e pesca (economia mista): la selvaggina cala se si caccia troppo e ricresce
	# lentamente; boschi e acque si ricontano ogni 5 anni (tagli e campi tolgono bosco).
	if _anni_risorse <= 0:
		_risorse = risorse_attorno(centro)
		_anni_risorse = 5
		if bosco_iniziale > 0.0:
			disboscamento = clampf(1.0 - _risorse["bosco"] / bosco_iniziale, 0.0, 1.0)
	_anni_risorse -= 1
	var portata_bosco: float = _risorse["bosco"] * RESA_BOSCO
	offerta_caccia = portata_bosco * selvaggina
	ultima_caccia = minf(pop * QUOTA_CACCIA * piu_braccia, offerta_caccia) if fonti["caccia"] else 0.0
	selvaggina = clampf(selvaggina - ultima_caccia / maxf(portata_bosco * 8.0, 1.0) + (1.0 - selvaggina) * 0.15, 0.05, 1.0)
	offerta_pesca = float(_risorse["acqua"]) * RESA_ACQUA
	ultima_pesca = minf(pop * QUOTA_PESCA * piu_braccia, offerta_pesca) if fonti["pesca"] else 0.0
	_storia_selvaggina.append(selvaggina)
	if _storia_selvaggina.size() > 6:
		_storia_selvaggina.pop_front()
	andamento_selvaggina = selvaggina - _storia_selvaggina[0]
	# Si caccia troppo: notifica discreta quando la selvaggina scende sotto la soglia, e quando torna.
	if not _caccia_eccessiva and selvaggina < SOGLIA_SELVAGGINA:
		_caccia_eccessiva = true
		_scrivi("Si caccia troppo: nei boschi attorno al villaggio la selvaggina si fa rara.")
		_notifica("Si caccia troppo: la selvaggina cala (%d%%)." % roundi(selvaggina * 100.0), false, mondo_di_px(centro))
	elif _caccia_eccessiva and selvaggina > SOGLIA_SELVAGGINA + 0.2:
		_caccia_eccessiva = false
		_scrivi("La selvaggina torna nei boschi.", "buono")
	# Legna (decisione di Fede del 25/11/2026): si raccoglie nei boschi vicini quanto ne offrono senza
	# consumarsi; serve ai focolari e a tenere in piedi le case.
	offerta_legna = float(_risorse["bosco"]) * RESA_LEGNA
	ultima_legna = minf(pop * LEGNA_PER_ABITANTE, offerta_legna)
	consumo_legna = pop * CONSUMO_FOCOLARI + case.size() * MANUTENZIONE_CASA
	legna = clampf(legna + ultima_legna - consumo_legna, 0.0, massimo_legna())
	# Cibo. Le annate magre fanno parte del ciclo normale: si vedono solo nelle scorte, senza avvisi
	# (decisione di Fede del 25/11/2026). La carestia arriva quando le scorte finiscono.
	var consumo := pop * (0.8 if razionamento > 0 else 1.0)
	cibo += raccolto + ultima_caccia + ultima_pesca - consumo
	if razionamento > 0:
		razionamento -= 1
	var carestia := 0.0
	if cibo < 0.0:
		carestia = minf(1.0, -cibo / maxf(1.0, consumo))
		cibo = 0.0
		if carestia >= SOGLIA_CARESTIA:
			pop -= pop * carestia * 0.3
			salute -= carestia * 25.0
			_cambia_consenso("anziani", -carestia * 30.0)
			_cambia_consenso("famiglie", -carestia * 20.0)
			stat["carestie"] += 1
			_scrivi("Carestia: manca il %d%% del cibo necessario." % roundi(carestia * 100.0), "allarme")
			if carestia > 0.25:
				_notifica("Carestia: manca il %d%% del cibo necessario." % roundi(carestia * 100.0), true, mondo_di_px(centro))
		else:
			carestia = 0.0
	else:
		cibo *= 0.9 if granaio_pronto() else 0.75
	# Il primo cattivo raccolto ferma il gioco una volta, quando la fame è davvero vicina.
	if not gia_primo_cattivo and anno > ANNO_INIZIO + 2 and raccolto + ultima_caccia + ultima_pesca < consumo and cibo < consumo * 0.25:
		gia_primo_cattivo = true
		_decidi("primo_cattivo", "Il primo cattivo raccolto",
			"Il raccolto non basta a sfamare tutti e le scorte sono quasi finite: %d di cibo contro un bisogno di %d." % [roundi(raccolto + ultima_caccia + ultima_pesca), roundi(consumo)],
			[{"id": "razionare", "testo": "Razionare per tre anni", "nota": "Si consuma meno; salute e consenso calano un poco."},
			 {"id": "caccia", "testo": "Cacciare di più nei boschi", "nota": "Più cibo subito, ma i cacciatori rischiano e la selvaggina cala."},
			 {"id": "campi", "testo": "Allargare la zona agricola", "nota": "Torni alla mappa e allarghi la zona dove le famiglie dissodano i campi."}])
	# Salute: acqua, paludi, affollamento, fame, focolari senza legna.
	var dm := _d_palude[px(centro)]
	var obiettivo := 72.0 + 15.0 * acqua_qualsiasi(px(centro)) - (25.0 if dm <= 3.0 else (10.0 if dm <= 6.0 else 0.0)) \
		- affollamento * 25.0 - (5.0 if razionamento > 0 else 0.0) - (8.0 if cibo < pop * 0.1 else 0.0) - (6.0 if legna <= 0.0 else 0.0)
	salute += (clampf(obiettivo, 5.0, 95.0) - salute) * 0.15
	# Febbri (decisione di Fede del 25/11/2026): estati di febbri vicino alle paludi e nelle case affollate.
	if rng.randf() < (0.05 if dm <= 3.0 else (0.025 if dm <= 6.0 else 0.0)) + affollamento * 0.05:
		salute -= 8.0
		stat["febbri"] += 1
		_scrivi("Un'estate di febbri: molti si ammalano.")
	salute = clampf(salute, 0.0, 100.0)
	# Popolazione: le nascite seguono l'abbondanza (decisione di Fede del 25/11/2026).
	_aggiorna_abbondanza()
	if carestia == 0.0:
		pop *= 1.0 + CRESCITA_MASSIMA * (abbondanza - SOGLIA_CRESCITA) / (1.0 - SOGLIA_CRESCITA)
	if salute < 35.0:
		pop *= 0.98
	_aggiorna_consenso()
	# Famiglie molto scontente: qualcuna se ne va da sola, poche alla volta.
	if consenso["famiglie"] < 30.0 and pop > 20.0 and rng.randf() < 0.1:
		pop -= ABITANTI_PER_CASA
		_scrivi("Una famiglia scontenta lascia il villaggio.")
	# Il contado cresce con gli abitanti: lo si annuncia ogni 100 m.
	var passo_contado := floorf(raggio_contado() / 100.0) * 100.0
	if passo_contado > _contado_annunciato and passo_contado > CONTADO_MIN:
		_scrivi("Il villaggio cresce: ora si coltiva fino a %d m dal centro." % roundi(passo_contado), "buono")
	_contado_annunciato = maxf(_contado_annunciato, passo_contado)
	_aggiorna_tappa()
	memoria = maxf(0.0, memoria - 1.5)
	for l in macerie.keys():
		macerie[l] -= 1
		if macerie[l] <= 0:
			macerie.erase(l)
	disponi_case(true)
	if not gia_affollato and pop >= 150.0:
		gia_affollato = true
		_decidi("affollamento", "Il villaggio è affollato",
			"Le famiglie sono ormai %d. Le case si stringono e i campi più lontani sono faticosi da raggiungere." % roundi(pop / ABITANTI_PER_CASA),
			[{"id": "restare", "testo": "Restare", "nota": "Più gente, più case: l'abitato si allarga verso i campi. Per qualche anno la salute ne risente."},
			 {"id": "emigrare", "testo": "Emigrare", "nota": "Un terzo delle famiglie parte in cerca di terra altrove: meno bocche da sfamare e meno braccia."}])
	if legittimita <= 5.0:
		anni_legittimita_bassa += 1
	else:
		anni_legittimita_bassa = 0
	if anni_legittimita_bassa >= 4:
		pop *= 0.6
		for g in consenso:
			consenso[g] = 35.0
		legittimita = 35.0
		anni_legittimita_bassa = 0
		_scrivi("Il villaggio si divide: molte famiglie se ne vanno.", "allarme")
		_notifica("Il villaggio si divide: gli anziani hanno perso ogni autorità e molte famiglie se ne vanno.", true, mondo_di_px(centro))
	if pop < 6.0:
		_abbandona()
	for k in ["pop", "cibo", "salute", "legittimita", "abbondanza", "legna"]:
		var arr: Array = storia[k]
		arr.append(get(k))
		if arr.size() > 200:
			arr.pop_front()
	anno += 1
	if anno >= ANNO_FINE:
		_fine()


## Abbondanza (decisione di Fede del 25/11/2026): cibo che avanza (scorte in mesi), salute, spazio.
func _aggiorna_abbondanza() -> void:
	var mesi := cibo / maxf(pop, 1.0) * 12.0
	parti_abbondanza = {"cibo": clampf(mesi / MESI_PIENI, 0.0, 1.0), "salute": salute / 100.0, "spazio": 1.0 - affollamento}
	abbondanza = 0.0
	for k in PESI_ABBONDANZA:
		abbondanza += PESI_ABBONDANZA[k] * parti_abbondanza[k]


## Quanta legna si può tenere da parte (le cataste marciscono): proposta di Claude.
func massimo_legna() -> float:
	return 100.0 + 3.0 * pop


## Mesi di cibo in scorta.
func mesi_di_scorta() -> float:
	return cibo / maxf(pop, 1.0) * 12.0


func _cambia_consenso(gruppo: String, d: float) -> void:
	bonus[gruppo] += d


## Gli anziani scontenti fanno rispettare meno le usanze: sotto 40 le politiche valgono meno, fino
## a metà (decisione di Fede del 25/11/2026).
func efficacia_usanze() -> float:
	return 1.0 if consenso["anziani"] >= 40.0 else 0.5 + 0.5 * consenso["anziani"] / 40.0


## Consenso per gruppo e indicatore unico (media pesata; il sacerdote conta dal luogo sacro).
func _aggiorna_consenso() -> void:
	var comune := politica("raccolto") == "comune"
	var obiettivi := {
		"anziani": 55.0 + (10.0 if cibo > pop * 0.5 else -6.0) + (8.0 if comune else -4.0),
		"famiglie": 52.0 + (8.0 if affollamento < 0.15 else -8.0) + (-2.0 if comune else 8.0 * efficacia_usanze()) + (6.0 if abbondanza > 0.75 else 0.0),
		"sacerdote": 55.0,
	}
	for g in consenso:
		consenso[g] = clampf(consenso[g] + (clampf(obiettivi[g], 0.0, 100.0) - consenso[g]) * 0.1 + bonus[g] * 0.4, 0.0, 100.0)
		bonus[g] *= 0.6
		if absf(bonus[g]) < 0.2:
			bonus[g] = 0.0
	var pesi := {"anziani": 0.4, "famiglie": 0.4, "sacerdote": 0.2} if sacerdote_attivo else {"anziani": 0.5, "famiglie": 0.5, "sacerdote": 0.0}
	legittimita = 0.0
	for g in pesi:
		legittimita += pesi[g] * consenso[g]


## Ci sono campi o case dove una piena può arrivare (per dare il segno solo se serve).
func _esposto_alle_piene() -> bool:
	for i in campi:
		if piena(i) > 0.25:
			return true
	for c in case:
		var w := centro_lotto(c)
		if piena(px(px_da_mondo(w.x, w.y))) > 0.25:
			return true
	return false


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
	var famiglie := 1.0 + 0.12 * efficacia_usanze() if politica("raccolto") == "famiglie" else 1.0
	return RESA_CAMPO * fert(i) * fattore * famiglie * (BONUS_LIMO if limo.has(i) else 1.0) \
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
		# Il limo rende più fertili i campi allagati (decisione di Fede del 25/11/2026). Niente
		# notifica: i campi allagati si vedono sulla mappa; la cronaca la ricorda solo se è grande.
		for f in allagati:
			limo[f] = ANNI_LIMO
		if campi_persi >= maxi(3, int(campi.size() * 0.1)):
			_scrivi("Piena di stagione: %d campi allagati. Il raccolto è perso, ma il limo li renderà più fertili." % campi_persi)
		return
	memoria = 100.0
	stat["piene"] += 1
	for f in allagati:
		limo[f] = ANNI_LIMO
	# La prima piena disastrosa ferma il gioco una volta (fa da tutorial).
	if not gia_piena_disastrosa:
		gia_piena_disastrosa = true
		_decidi("piena", "Il fiume esce dal letto",
			"L'acqua ha invaso le terre basse: %d case distrutte, %d campi allagati. Le piene grandi sono rare, ma arrivano dove la mappa del rischio di piena è rossa, e più spesso se si taglia il bosco attorno al villaggio. Il limo lascerà i campi più fertili.\nLe famiglie ricostruiranno lontano dall'acqua finché il ricordo resta vivo." % [case_perse, campi_persi],
			[{"id": "ok", "testo": "Guardare la mappa del rischio", "nota": ""}])
	if case_perse > 0:
		_cambia_consenso("famiglie", -minf(8.0, case_perse))
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
			_cambia_consenso("anziani", 6.0)
			stat["presagi_letti"] += 1
			_scrivi("Arriva la siccità: le scorte accumulate ascoltando il presagio aiutano il villaggio.", "buono")
		else:
			_cambia_consenso("anziani", -8.0)
			_scrivi("Arriva la siccità annunciata dalle sorgenti: averla ignorata costa caro agli anziani.", "allarme")
		presagio_vero = {}
	_notifica("Siccità per %s: rendono solo i campi vicini al fiume e alle sorgenti." % ("un anno" if siccita == 1 else "due anni"), true, mondo_di_px(centro))


## Abitato spontaneo (decisione di Fede): le case nascono da sole vicino al centro, all'acqua e
## lontano dal pericolo di piena finché la memoria del rischio è viva; il giocatore orienta la
## crescita con campi, sentieri e granaio.
## Con `paga` le case nuove costano legna (decisione di Fede del 25/11/2026: le case spontanee
## crescono solo se c'è legna); senza, si ridispongono gratis (fondazione, case spostate).
func disponi_case(paga := false) -> void:
	if not fondato:
		return
	var servono := ceili(pop / ABITANTI_PER_CASA)
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
	while case.size() < servono and tentativi < 200 and (not paga or legna >= COSTO_CASA):
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
		if paga:
			legna -= COSTO_CASA
	affollamento = clampf(float(servono - case.size()) / servono, 0.0, 1.0) if servono > 0 else 0.0


## Emigrazione (decisione di Fede: al posto del villaggio figlio): un terzo delle famiglie parte.
func _emigra() -> void:
	pop *= 0.67
	stat["emigrazioni"] = stat.get("emigrazioni", 0) + 1
	_scrivi("Un terzo delle famiglie emigra in cerca di terra altrove.")
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
	zona = {}
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
		roundi(pop), (" (emigrazioni: %d)" % stat["emigrazioni"]) if stat.get("emigrazioni", 0) > 0 else "",
		stat["carestie"], stat["piene"], stat["siccita"], stat["presagi_letti"], stat["presagi_totali"], stat["fondazioni"],
		(" (abbandoni: %d)" % stat["abbandoni"]) if stat["abbandoni"] > 0 else ""]
	_decidi("fine", "%s: cinque secoli dopo" % anno_testo(anno), testo, [{"id": "ok", "testo": "Resta a guardare la mappa", "nota": ""}])


# ---------- cause, per i pannelli di focus (decisione di Fede del 25/11/2026) ----------

## Le 2–4 cause che oggi spingono un indicatore, scritte in chiaro per il giocatore.
func cause_di(nome: String) -> Array[String]:
	var out: Array[String] = []
	if not fondato:
		return out
	var cibo_anno := ultimo_raccolto + ultima_caccia + ultima_pesca
	match nome:
		"Abbondanza", "Popolazione":
			if abbondanza >= SOGLIA_CRESCITA + 0.02:
				out.append("La popolazione cresce: c'è cibo da parte, salute e spazio.")
			elif abbondanza <= SOGLIA_CRESCITA - 0.02:
				out.append("La popolazione cala piano: l'abbondanza è sotto %d." % roundi(SOGLIA_CRESCITA * 100.0))
			else:
				out.append("La popolazione è ferma: il villaggio ha quasi raggiunto ciò che la terra può dare.")
			if parti_abbondanza["cibo"] < 0.4:
				out.append("Le scorte bastano per %.0f mesi: servono più campi, o più caccia e pesca." % mesi_di_scorta())
			if zona_piena:
				out.append("La zona agricola è piena: le famiglie non trovano altra terra da dissodare.")
			if not granaio_pronto() and sbloccato("granaio"):
				out.append("Senza granaio un quarto delle scorte si guasta ogni anno.")
			if affollamento > 0.05:
				out.append("Mancano case per %d%% delle famiglie%s." % [roundi(affollamento * 100.0), ": serve legna" if legna < COSTO_CASA else ""])
			if salute < 55.0:
				out.append("La salute è bassa (%d): pesa sulle nascite." % roundi(salute))
		"Cibo":
			out.append("Quest'anno: %d dai campi, %d da caccia e raccolta, %d dalla pesca; se ne mangiano %d." % [roundi(ultimo_raccolto), roundi(ultima_caccia), roundi(ultima_pesca), roundi(pop)])
			if cibo_anno < pop:
				out.append("Annata magra: si attinge alle scorte.")
			if siccita > 0:
				out.append("Siccità: rendono solo i campi vicini al fiume e alle sorgenti.")
			if not limo.is_empty():
				out.append("%d campi hanno il limo di una piena: rendono di più per qualche anno." % limo.size())
			if _caccia_eccessiva:
				out.append("Si caccia troppo: la selvaggina è al %d%%." % roundi(selvaggina * 100.0))
			if ultimi_lavorati < campi.size():
				out.append("Mancano braccia: %d campi su %d restano incolti." % [campi.size() - ultimi_lavorati, campi.size()])
		"Salute":
			var dm := _d_palude[px(centro)]
			if dm <= 6.0:
				out.append("La palude è vicina: aria cattiva e febbri d'estate.")
			if affollamento > 0.05:
				out.append("Le case sono affollate.")
			if legna <= 0.0:
				out.append("Manca la legna per i focolari.")
			if razionamento > 0:
				out.append("Si raziona il cibo.")
			if acqua_qualsiasi(px(centro)) > 0.6:
				out.append("L'acqua è vicina e buona.")
		"Consenso":
			if politica("raccolto") == "comune":
				out.append("Il raccolto in comune piace agli anziani; le famiglie vorrebbero tenerne di più.")
			else:
				out.append("Il raccolto alle famiglie piace alle famiglie; gli anziani lo vedono male.")
			if cibo <= pop * 0.5:
				out.append("Gli anziani si preoccupano: le scorte sono poche.")
			if affollamento >= 0.15:
				out.append("Le famiglie sono scontente: mancano case.")
			if efficacia_usanze() < 1.0:
				out.append("Gli anziani sono scontenti: le usanze si rispettano meno.")
			if consenso["famiglie"] < 30.0:
				out.append("Le famiglie molto scontente cominciano ad andarsene.")
		"Legna":
			out.append("I boschi vicini ne danno fino a %d l'anno; se ne raccolgono %d e se ne consumano %d." % [roundi(offerta_legna), roundi(ultima_legna), roundi(consumo_legna)])
			if disboscamento > 0.1:
				out.append("Attorno al villaggio è sparito il %d%% del bosco: meno legna e selvaggina, piene più frequenti." % roundi(disboscamento * 100.0))
			if legna < COSTO_CASA:
				out.append("Senza legna non nascono case nuove.")
			if legna >= massimo_legna() - 1.0:
				out.append("La catasta è piena: la legna in più marcisce.")
	return out
