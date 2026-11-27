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
## La partita non finisce più a cinque secoli (Fede, 26/11/2026: "aumenta il periodo della demo"):
## arriva fino all'evento soglia 1, nella finestra 3000–1800 a.C. ANNO_FINE resta come riparo.
const ANNO_FINE := -1700
## Le prove automatiche giocano i primi cinque secoli, come prima (si confrontano con le misure
## vecchie); le partite lunghe si chiedono a parte.
const ANNO_PROVE := -5500
## Passo elastico (todo voce 6; proposta di Claude approvata da Fede il 26/11/2026): un anno per
## passo nei primi quattro secoli (le pedine), poi un decennio. Le regole restano per anno: la partita
## calcola i dieci anni uno per uno (`anni_per_passo`). Il decennio comincia dal 5600 a.C. se il
## villaggio è arrivato alla tappa Territorio, altrimenti quando ci arriva, e comunque dal 5200.
const ANNO_DECENNI := -5600
const ANNO_DECENNI_COMUNQUE := -5200
const ANNI_DECENNIO := 10
## Evento soglia 1, "il metallo e lo scambio" (era-origini.md § 5; regole proposte da Claude e
## approvate da Fede il 26/11/2026): presagi dal 3300 a.C., evento dal 3000 quando il territorio è
## pieno (e ci sono stati almeno due presagi), al 1800 comunque.
const ANNO_PRESAGI_SOGLIA := -3300
const ANNO_SOGLIA := -3000
const ANNO_SOGLIA_COMUNQUE := -1800
const QUOTA_TERRITORIO_PIENO := 0.7
const ABITANTI_TERRITORIO_PIENO := 600.0
const PRESAGI_SOGLIA := [
	"Stranieri di passaggio mostrano un oggetto mai visto: una lama di rame, lucida come l'acqua al sole.",
	"Mercanti risalgono la valle con sale, conchiglie e piccole asce di metallo da scambiare.",
	"Si racconta che nei villaggi oltre il fiume abbiano armi nuove, che non si spezzano.",
]
var decenni := false
var presagi_soglia := 0
var _prossimo_presagio_soglia := ANNO_PRESAGI_SOGLIA
var soglia_scelta := ""  # "aprirsi" o "isolarsi" dopo l'evento
var primo_governo := ""
var rng_soglia := RandomNumberGenerator.new()
var _terra_contado := -1
var _firma_terra_contado := -1
## Pixel della mappa per cella del prototipo (lato): 160 m / 40 m.
const PX_CELLA := 4
const AREA_CELLA := 16
const LOTTO := 20.0
## Ettari di un pixel della mappa (40 × 40 m).
const AREA_PIXEL_HA := 0.16
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
## pericolo (scorrerie, decisione di Fede del 26/11/2026): cosa si fa ai segni di pericolo; si apre con
## i primi segni, che fermano il gioco una volta: la scelta di allora diventa la regola.
var politiche := {"raccolto": "comune", "stranieri": "aperta", "affollati": "allargare", "pericolo": "avanti"}
const POLITICHE := {
	"raccolto": ["comune", "famiglie"],
	"stranieri": ["aperta", "caso", "chiusa"],
	"affollati": ["allargare", "emigrare"],
	"pericolo": ["avanti", "raccogliere", "vegliare"],
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
var _campi_strada := {}
var _fascia_strade := {}
var _fascia_sentieri := {}
var _firma_fascia_sentieri := 0
var _firma_fascia := 0
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
## Sentieri che diventano strade (voce 5 del todo; principi decisi in era-origini.md, numeri proposti
## da Claude e approvati da Fede il 26/11/2026): ogni anno chi lavora va dal centro al suo posto di
## lavoro lungo la rete dei sentieri; un tratto battuto da almeno SOGLIA_STRADA persone per ANNI_STRADA
## anni di fila diventa strada (dalla tappa dei 250 abitanti) e resta, anche se il traffico cala.
## Le strade sono il primo "campo di accesso": campi più vicini rendono di più, le case crescono anche
## lungo le strade (il primo borgo lungo la via), casali e legnaie collegati ne guadagnano.
const SOGLIA_STRADA := 40.0  # persone l'anno su un tratto
const ANNI_STRADA := 20
const BONUS_STRADA := 0.15  # campi entro DISTANZA_CAMPI_STRADA da una strada
const DISTANZA_CAMPI_STRADA := 4  # pixel (160 m)
const STRADA_ATTRAE_CASE := 500.0  # metri dal centro: fin dove le case nascono lungo le strade
var traffico := {}  # pixel di sentiero -> persone l'anno
var strade := {}  # tratto (Vector4i: a.x, a.y, b.x, b.y) -> anno in cui è diventato strada
var anni_battuto := {}  # tratto -> anni di fila sopra la soglia
var pixel_strada := {}  # pixel delle strade
var gia_strada := false
var _rete := {}  # pixel -> pixel vicini della rete
var _firma_rete := -1
var _padri := {}  # albero dei cammini dal centro: pixel -> pixel prima
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
## L'ultima piena che ha toccato il villaggio: {"anno", "disastrosa"} (la vista fa salire l'acqua).
var ultima_piena := {}

# ---------- dinamiche della prima epoca (decisioni di Fede del 25/11/2026, docs/era-origini.md) ----------
## Abbondanza: un solo indicatore con tre parti (cibo che avanza, salute, spazio). Le nascite la
## seguono: con scorte, salute e case il villaggio cresce già nei primi decenni; vicino al limite
## della terra le scorte calano e le nascite rallentano da sole, senza passare per le carestie.
## Pesi e soglia: proposta di Claude, da tarare con le partite automatiche.
const PESI_ABBONDANZA := {"cibo": 0.45, "salute": 0.3, "spazio": 0.25}
## Mesi di scorte che valgono "cibo che avanza" pieno.
const MESI_PIENI := 18.0
## Sotto questa abbondanza (0–1) la popolazione non cresce; sopra cresce fino a CRESCITA_MASSIMA.
const SOGLIA_CRESCITA := 0.6
const CRESCITA_MASSIMA := 0.014
var abbondanza := 0.0
## Le nascite reagiscono in ritardo (decisione di Fede del 25/11/2026, carestie B + C): seguono
## l'abbondanza degli ultimi ANNI_NASCITE anni circa. Negli anni buoni il villaggio cresce oltre ciò
## che la terra regge, e un'annata cattiva può portare la fame.
const ANNI_NASCITE := 15.0
var abbondanza_lenta := 0.0
## Anni di fila in cui il cibo dell'anno non basta: lo dice il pannello di focus.
var anni_deficit := 0
var parti_abbondanza := {"cibo": 0.0, "salute": 0.0, "spazio": 0.0}
## Tappe (decisione di Fede del 25/11/2026): soglie di abitanti che aprono gli strumenti; una volta
## raggiunte restano anche se gli abitanti calano. Soglie di partenza, da tarare.
const TAPPE := [
	{"nome": "Fondazione", "abitanti": 0, "apre": ["zona", "campi", "sentiero", "fonti", "legnaia"]},
	{"nome": "Gruppo di famiglie", "abitanti": 60, "apre": ["granaio", "raccolto"]},
	{"nome": "Villaggio", "abitanti": 100, "apre": ["luogo_sacro", "pascolo"]},
	{"nome": "Grande villaggio", "abitanti": 150, "apre": ["stranieri", "affollati", "bosco_sacro"]},
	{"nome": "Territorio", "abitanti": 250, "apre": ["casali", "strade"]},
]
var tappa := 0
## Legna (decisione di Fede del 25/11/2026: risorse cibo, legna, braccia, animali), rifatta il
## 26/11/2026 sera dopo la prova di Fede ("un albero deve avere un suo valore e deve essere verosimile
## col periodo"; la legnaia parte dai 3–4 alberi attorno e passa ai successivi, come in Age of Empires).
## Unità: metri cubi di legna. Due usi del bosco, come nel Neolitico (proposta di Claude approvata):
## - legna da ardere senza abbattere: rami caduti, legna morta e potature, raccolte nel bosco attorno
##   alle legnaie (RESA_RACCOLTA per ettaro l'anno); i focolari ne bruciano CONSUMO_PERSONA a testa;
## - tronchi abbattendo: i boscaioli tagliano gli alberi uno alla volta (celle di 10 m con i loro
##   alberi, ognuno col suo valore), dal più vicino alla legnaia verso fuori, quanto serve per rifare
##   le case (durano ANNI_VITA_CASA) e tenere da parte legname per costruire.
## Senza legnaia non si raccoglie legna (decisione di Fede del 25/11/2026).
var legna := 0.0
const LEGNA_INIZIALE := 60.0
const CONSUMO_PERSONA := 0.5  # m³ l'anno a testa nei focolari (circa 2,5 per famiglia)
const RESA_RACCOLTA := 3.0  # m³ l'anno per ettaro di bosco in piedi (rami, legna morta, potature)
const ANNI_VITA_CASA := 30  # una casa si rifà dopo tanti anni: COSTO_CASA / ANNI_VITA_CASA l'anno
const BRACCIA_LEGNA := 1.5  # m³ l'anno che un abitante può raccogliere e tagliare al massimo
const RISERVA_LEGNAME := 40.0  # legname da tenere da parte per costruire
const COSTO_CASA := 20.0
const LEGNA_DISSODAMENTO := 10.0  # da un pixel di bosco dissodato (il resto si brucia sul posto)
const COSTO_GRANAIO := 15.0
const COSTO_EDIFICIO_RISORSE := 5.0  # capanno da pesca, posta di caccia (la legnaia è gratis: solo braccia)
## Valore di un albero (m³) per specie, per un albero di grandezza media (scala 1,15); cresce con il
## quadrato della scala. Quercia, carpino, pioppo, arbusto, canna (le canne non si tagliano).
const VALORE_SPECIE := [2.0, 1.0, 1.5, 0.2, 0.0]
const LATO_CELLA_TAGLIO := 10.0  # come la griglia dell'uso del suolo
## Legnaie: i boscaioli tagliano fino a CAPACITA_TAGLIO l'anno con il bosco a ridosso, meno man mano
## che il fronte del taglio si allontana; oltre RAGGIO_LEGNAIA non vanno. Conviene allora una legnaia
## nuova più vicina al bosco.
const CAPACITA_TAGLIO := 30.0
const RAGGIO_LEGNAIA := 600.0  # metri: oltre, i boscaioli non vanno
## Il bosco tagliato ricresce in questi anni (come UsoSuolo.ANNI_CEDUO), ma solo quando la zona di
## taglio non è più di passaggio, cioè quando la legnaia smette di lavorare (Fede, 26/11/2026).
const ANNI_RICRESCITA := 25
## Zona di taglio: finché la legnaia lavora resta aperta; se per questi anni non taglia nulla
## (demolita, a riposo, bosco finito) va a riposo e il bosco ricresce.
const ANNI_SENZA_TAGLIO := 10
const ANNI_CANTIERE_LEGNAIA := 2
const DISTANZA_MASSIMA_LEGNAIA := 1000.0  # dal centro del villaggio
## Legnaie: {punto, cantiere, bosco (pixel di bosco attorno, dal più vicino: per la raccolta),
## celle ([distanza, cella da 10 m, valore], dalla più vicina: per il taglio), debito (m³ da tagliare),
## raggio (fino a dove ha tagliato), ultimo (anno dell'ultimo taglio), riposo, pixel (pixel abbattuti
## per metà o più), fatte (celle tagliate), attiva}.
var legnaie: Array = []
## Gli alberi della mappa (li dà la partita; nelle prove senza grafica la simulazione li calcola da sé).
var alberi: Alberi
## Se gli alberi in un punto ci sono ancora per l'uso del suolo (demolizioni del giocatore): x, z -> bool.
var albero_presente: Callable = func(_x: float, _z: float) -> bool: return true
## Celle da 10 m tagliate dalle legnaie: cella -> anno del taglio.
var celle_tagliate := {}
## Celle delle zone di taglio attive: lì non ricresce nulla (luogo di passaggio).
var celle_zona_attiva := {}
## Pixel di bosco abbattuti per metà o più: indice -> anno (per caccia, raccolta, mappe).
var tagliati := {}
var _celle_px := {}  # pixel -> celle con alberi
var _tagli_px := {}  # pixel -> celle tagliate
## Celle tagliate nell'ultimo anno: la partita le toglie dalla mappa, una alla volta.
var tagli_anno: Array[Vector2i] = []
## Pixel abbattuti nelle zone di taglio attive: lì il bosco non ricresce.
var zona_attiva := {}
var raccolta_legna := 0.0  # m³ raccolti l'ultimo anno senza abbattere
var tronchi_legna := 0.0  # m³ di tronchi abbattuti l'ultimo anno
var offerta_raccolta := 0.0
var capacita_taglio := 0.0
const ANNI_CANTIERE_GRANAIO := 3
var ultima_legna := 0.0
var offerta_legna := 0.0
var consumo_legna := 0.0
var consumo_focolari := 0.0
## Anni che mancano perché il granaio sia finito (0: pronto).
var cantiere_granaio := 0
## Bosco attorno al centro alla fondazione: il disboscamento si misura rispetto a questo.
var bosco_iniziale := 0.0
## Quota di bosco perso attorno al villaggio (0–1): erosione, piene più rapide, meno selvaggina.
var disboscamento := 0.0
## Capanno da pesca e Posta di caccia (decisioni di Fede del 25/11/2026): stessa dinamica della
## legnaia. Senza questi edifici caccia e pesca non spariscono, ma rendono circa un terzo: le
## famiglie cacciano e pescano attorno al villaggio. Il capanno va solo sulla riva di un fiume o di
## un torrente (si aggancia al punto di riva più vicino, girato verso l'acqua, fuori dalla palude);
## la posta al margine del bosco, con la schiena al bosco. Nessuna distanza minima tra edifici: chi
## li ammassa esaurisce il pesce o la selvaggina di quel tratto, ed è una scelta sua.
## Pesce e selvaggina sono locali (Fede, 25/11/2026): ogni riquadro di BLOCCO_RISORSE pixel ha la sua
## scorta; gli edifici vicini se la dividono, troppi la fanno calare, e lasciata stare si riprende in
## qualche anno. Il capanno rende di più sul fiume che sui torrenti, poco sulle paludi.
## Numeri: proposta di Claude, da tarare con le partite automatiche.
const RESA_SENZA_EDIFICIO := 0.33
const BLOCCO_RISORSE := 5  # pixel (200 m)
const RAGGIO_POSTA := 1000.0  # metri: fin dove vanno i cacciatori di una posta
const RAGGIO_CAPANNO := 600.0  # metri di fiume e di riva attorno al capanno
const CAPACITA_POSTA := 35.0  # cibo l'anno al massimo, con il bosco ricco attorno
const CAPACITA_CAPANNO := 35.0
const ANNI_CANTIERE_RISORSE := 2
const DISTANZA_MASSIMA_RISORSE := 1000.0  # dal centro del villaggio
## Aggancio (metri dal puntatore): il capanno alla riva più vicina, la posta al margine più vicino.
const AGGANCIO_RIVA := 30.0
const AGGANCIO_MARGINE := 60.0
## Quanto si riprendono ogni anno le scorte lasciate stare (quota di ciò che manca).
const RIPRESA_SELVAGGINA := 0.15
const RIPRESA_PESCE := 0.2
## Edifici: {punto (metri), verso (Vector2 verso l'acqua o il bosco), cantiere (anni), preso (cibo
## dell'ultimo anno), offerta (cibo che potrebbe dare)}; il capanno anche acqua ("fiume", "torrente").
var poste: Array = []
var capanni: Array = []
## Riquadri attorno al villaggio e agli edifici: bosco in piedi (pixel, la palude conta 0,3) e acqua
## (pixel pesati per tipo), ricontati con le risorse.
var celle_bosco := {}
var celle_acqua := {}
## Scorte per riquadro (0–1; assente = piena).
var scorta_selvaggina := {}
var scorta_pesce := {}
## Consenso per gruppo (decisione di Fede del 24–25/11/2026): anziani, famiglie, sacerdote; un solo
## indicatore (legittimita) con il dettaglio al passaggio. Il sacerdote diventa un gruppo con il
## luogo sacro; fino ad allora i presagi li leggono gli anziani.
var consenso := {"anziani": 60.0, "famiglie": 60.0, "sacerdote": 60.0}
var sacerdote_attivo := false
## Consenso di ogni gruppo negli ultimi anni (per la freccia dello specchietto dei rapporti di forza).
var storia_consenso := {"anziani": [], "famiglie": [], "sacerdote": []}
## Identità della città (decisione di Fede del 26/11/2026, `docs/epoche-future.md` § 2): quattro
## assi nascosti, da −1 a 1, mossi piano dalle politiche. Nel villaggio non cambiano nessuna regola:
## li legge lo specchietto dei rapporti di forza ("Si muove verso") e, all'evento soglia 1, servono a
## dare il nome al primo governo. terra: in comune (−1) o alle famiglie (+1); apertura: chiusa (−1) o
## aperta (+1); decide: pochi (−1) o molti (+1); governo: lascia fare (−1) o regola insieme (+1).
## identita_verso: dove le politiche di oggi spingono ciascun asse. Numeri: proposta di Claude.
var identita := {"terra": 0.0, "apertura": 0.0, "decide": 0.0, "governo": 0.0}
var identita_verso := {"terra": 0.0, "apertura": 0.0, "decide": 0.0, "governo": 0.0}
## Quanto in fretta l'identità segue le politiche: plastica all'inizio (circa 70 anni per fare metà
## della strada); nelle epoche dopo diventerà più lenta.
const PLASTICITA_IDENTITA := 0.01
## Luogo sacro (decisioni di Fede del 24–25/11/2026): cerchio di pali attorno a una pietra; si apre
## a 100 abitanti, costa legna e braccia con un cantiere, attira le case (germe della piazza). Il
## sacerdote diventa il terzo gruppo di consenso con la tappa dei 100 abitanti ed è contrariato finché
## il luogo sacro non è eretto (decisione di Fede del 25/11/2026 sera: così si è spinti a farlo);
## contento, presagi più chiari; scontento, presagi ambigui e più voci false. Numeri: proposta di Claude approvata da Fede il 25/11/2026 sera.
const COSTO_LUOGO_SACRO := 10.0
const ANNI_CANTIERE_LUOGO_SACRO := 3
const DISTANZA_LUOGO_SACRO := 400.0
var luogo_sacro := Vector2(-1, -1)
var cantiere_luogo_sacro := 0
## Scorrerie (voce 4 del todo; principi in era-origini.md, numeri: proposta di Claude approvata da Fede
## il 26/11/2026). Il primo "campo di sicurezza": le attira la ricchezza che si vede (animali, scorte),
## i casali, i pascoli lontani e i margini del contado poco usati; le frenano un sito alto e un abitato
## raccolto. Prima arrivano i segni (1–2 anni prima, 2–3 con la torre di avvistamento). Si aprono con
## la tappa dei 100 abitanti (quella del pascolo): furti di bestiame e bande di passaggio, più rari prima
## del 4300 a.C. (Neolitico recente) e il doppio dopo. Le perdite dipendono dalla politica "pericolo" e
## dalla torre; dopo una scorreria le case nuove nascono più strette (memoria della paura).
const PROB_SCORRERIA := 0.016  # all'anno con ricchezza ed esposizione piene, senza difesa
const ANNO_SCORRERIE_FREQUENTI := -4300
const CAPI_RICCHEZZA := 80.0  # tanti capi fanno una ricchezza "piena"
const MESI_RICCHEZZA := 18.0
const PASCOLO_LONTANO := 300.0  # metri dal centro: oltre, gli animali sono esposti
const MARGINE_ABITATO := 150.0  # case del nucleo più lontane di così dal centro: ai margini
const ANNI_MEMORIA_RAZZIA := 15
## Torre di avvistamento (catalogo degli edifici, epoca 1; Fede: "perfetto tutto" del 26/11/2026).
const COSTO_TORRE := 8.0
const ANNI_CANTIERE_TORRE := 2
const DISTANZA_TORRE := 1200.0
const RILIEVO_TORRE := 2.0  # metri sopra la media dei dintorni: un dosso o un colle
const PERDITE_TORRE := 0.7
var torre := Vector2(-1, -1)
var cantiere_torre := 0
var gia_segni := false
var segni_tra := -1  # anni alla scorreria annunciata dai segni (-1: nessuna)
var segni_punto := Vector2(-1, -1)  # dove colpirà (nel mondo)
var segni_da := ""  # da dove: "nord", "sud-est"…
var memoria_scorrerie := 0.0
var case_razziate := {}  # lotto -> anno della scorreria vicina
var ultima_scorreria := {}  # {anno, capi, cibo, case, da}
var rischio_scorrerie := {}  # ultimo calcolo: {p, ricchezza, esposizione, difesa, …}
var rng_scorrerie := RandomNumberGenerator.new()
var _difesa_sito := 0.0
var _pericolo_prima := false
## Bosco sacro (tappa dei 150): la riserva, stesa a pennello sul bosco entro 1 km dal centro. Le
## legnaie non lo tagliano e le famiglie non vi dissodano; tagliarlo (Demolisci) offende il sacerdote,
## che lo vuole grande (pieno da circa 10 ettari).
const ETTARI_BOSCO_SACRO := 10.0
const DISTANZA_BOSCO_SACRO := 1000.0
var bosco_sacro := {}  # indice del pixel -> true
## Quota di presagi falsi: 25% di solito; con il sacerdote contento (60 o più) 15%, scontento
## (sotto 40) 40%.
const PRESAGI_FALSI := 0.25
## Piene che fertilizzano (decisione di Fede del 25/11/2026): i campi allagati da una piena di
## stagione ricevono limo e rendono di più per qualche anno.
const BONUS_LIMO := 1.25
const ANNI_LIMO := 3
var limo := {}  # indice del pixel -> anni rimasti
## Campi che si stancano (decisione di Fede del 25/11/2026): dopo molti anni di coltura di fila un
## campo rende meno; lasciato incolto si riposa, e il limo di una piena lo rinnova. La rotazione
## delle colture arriverà con le tecniche delle epoche dopo. Numeri: proposta di Claude, da tarare.
const ANNI_PRIMA_STANCHEZZA := 40.0
const ANNI_STANCHEZZA := 60.0
const PERDITA_STANCHEZZA := 0.35
const RIPOSO_PER_ANNO := 4.0
var stanchezza := {}  # indice del pixel -> anni di coltura di fila
## Pascolo e animali (decisioni di Fede del 25/11/2026): dalla tappa dei 100 abitanti. Zona di
## pascolo a pennello (come la zona agricola, le famiglie portano gli animali da sole) su prati,
## radure e margini del bosco, che lì non ricresce. Le due zone si parlano senza entrare in
## conflitto: su un campo coltivato gli animali pascolano solo le stoppie dopo il raccolto (poca
## erba, un po' di concime per l'anno dopo); un campo stanco o incolto diventa maggese (molta erba,
## riposo più rapido) e torna coltivato quando è buono. Un solo numero di capi: una decina alla
## tappa, +10% l'anno finché c'è erba (portata della zona), di più se il raccolto va alle famiglie
## (e cresce la disuguaglianza); oltre la portata smette di crescere e sui pendii dà erosione. Gli
## stranieri portano i loro animali; nelle annate cattive se ne macella quanto serve (scorta viva).
## Numeri: proposta di Claude approvata da Fede il 25/11/2026 sera.
const CAPI_INIZIALI := 10.0
const CAPI_ATTORNO_CASE := 12.0  # portata senza zona di pascolo: gli animali attorno alle case
const CRESCITA_CAPI := 0.10
const CRESCITA_CAPI_FAMIGLIE := 0.13
const CAPI_HA_PRATO := 2.0
const CAPI_HA_BOSCO := 0.7
const CAPI_HA_MAGGESE := 3.0
const CAPI_HA_STOPPIE := 0.5
const BONUS_STOPPIE := 1.05
const CIBO_PER_CAPO := 4.0  # cibo da un capo macellato
const CAPI_PER_STRANIERO := 0.5
const PENDIO := 0.08  # pendenza oltre cui il troppo pascolo erode (8%)
var pascolo := {}  # indice del pixel -> true
var capi := 0.0
var portata_capi := 0.0
var erba := 0.0  # quanto della portata è libera (0–1)
var maggese := {}  # campi a maggese quest'anno
var concimati := {}  # stoppie pascolate l'anno scorso: rendono un po' di più
var ultimi_macellati := 0
var pascolo_eccessivo := 0.0  # 0–1: troppi capi sui pendii (erosione, piene)
var disuguaglianza := 0.0  # 0–1: la mandria delle famiglie (prepara le famiglie eminenti)
var _pendii := {}  # cache: pixel -> vero se in pendio
var _anno_macellazione := -999999  # per non ripetere la riga di cronaca anno dopo anno
## Piena disastrosa annunciata: anni che mancano (-1: nessuna in arrivo).
var piena_tra := -1
## Siccità dopo un presagio ignorato: dura di più e i campi rendono meno (carestie B).
var siccita_grave := false
## Casali (decisione di Fede del 25/11/2026): dalla tappa "Territorio" il nucleo tiene fino a
## NUCLEO_MASSIMO abitanti; la crescita in più va in casali di 2–4 case nel contado.
const NUCLEO_MASSIMO := 280.0
const CASE_PER_CASALE := 4
const CASALE_DISTANZA_MIN := 300.0
const CASALE_DISTANZA_MAX := 800.0
const CASALE_SPAZIO := 200.0
var casali: Array[Vector2i] = []  # lotto al centro di ogni casale
var case_casale := {}  # lotto di una casa -> indice del casale
## Scheda della famiglia (decisione di Fede del 26/11/2026: una casa è una famiglia). Solo memoria,
## non cambia le dinamiche: l'anno in cui è nata ogni casa e, per le case delle famiglie accolte da
## fuori, l'anno del loro arrivo.
var nascita_case := {}  # lotto -> anno
var case_straniere := {}  # lotto -> anno dell'arrivo
var _case_stranieri_da_fare := 0
var _anno_stranieri := 0
## Umore di ogni famiglia (decisione di Fede del 26/11/2026): nel villaggio è solo lettura, e la media
## delle famiglie resta il consenso del gruppo. Dall'epoca 2 le famiglie si divideranno in eminenti e
## comuni secondo la posizione di prestigio che hanno ottenuto, e il loro umore comporrà il consenso
## (più peso alle eminenti). Il prestigio si registra già qui, nascosto: cresce ogni anno con la
## vicinanza al focolare e al luogo sacro e, con il raccolto alle famiglie, con gli animali (proposta
## di Claude accolta da Fede). Le case ricostruite dopo una piena disastrosa la ricordano.
var prestigio_case := {}  # lotto -> prestigio accumulato
var case_dopo_piena := {}  # lotto -> anno della piena che ha distrutto la casa di prima
var _case_piena_da_fare := 0
var _anno_piena := 0
var gia_piena_disastrosa := false
## Presagi: al massimo uno ogni secolo circa (proposta approvata da Fede il 25/11/2026).
const ANNI_TRA_PRESAGI := 100
## Ritmo dei presagi (Fede, 26/11/2026: "allenta i presagi, aumentali col sacerdote scontento";
## numeri proposti da Claude): a decenni almeno 400 anni fra l'uno e l'altro e meno probabili (uno
## ogni 6–7 secoli in media, prima erano uno ogni 2); con il sacerdote scontento (sotto 40) l'attesa
## si dimezza e la probabilità raddoppia, anche nei primi secoli.
const ANNI_TRA_PRESAGI_DECENNI := 400
const PROB_PRESAGIO_DECENNI := 0.004
const SACERDOTE_SCONTENTO := 40.0
var _ultimo_presagio := -99999
var gia_stranieri := false
var _stranieri_prima := false
var gia_carestia := false
## La zona agricola è piena (niente avviso: lo dice la mappa; decisione di Fede del 25/11/2026).
var zona_piena := false
var stat := {"carestie": 0, "piene": 0, "siccita": 0, "fondazioni": 0, "presagi_letti": 0, "presagi_totali": 0, "abbandoni": 0, "febbri": 0, "segni": 0, "scorrerie": 0, "case_bruciate": 0}
var storia := {"pop": [], "cibo": [], "salute": [], "legittimita": [], "abbondanza": [], "legna": [], "capi": []}
## Cronaca: [{anno, testo, tipo ("", "buono", "allarme")}], la più recente in testa.
var cronaca: Array = []
## Tutorial alle tappe (decisione di Fede del 26/11/2026, vedi Tutorial): spenti nelle prove senza
## partita; la partita li accende. Ogni scheda si mostra al massimo una volta per partita.
var tutorial_attivi := false
var _tutorial_visti := {}
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
	# Anche le scorrerie hanno il loro generatore: le altre vicende restano quelle di prima.
	rng_scorrerie.seed = seme + 104729
	# Presagi dell'evento soglia: generatore a parte, come per scorrerie e stranieri.
	rng_soglia.seed = seme + 15485863
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


## Mostra le schede del tutorial di una novità (o di più novità insieme, come pagine dello stesso
## riquadro). Con i tutorial saltati, una notifica grigia per scheda: il gioco non si ferma.
## `tappa` è il nome che compare in testa al riquadro (per esempio "Villaggio (100 abitanti)").
func tutorial(chiavi: Array, tappa: String) -> void:
	var nuove: Array = []
	for c in chiavi:
		if Tutorial.ha(c) and not _tutorial_visti.has(c):
			_tutorial_visti[c] = true
			nuove.append(c)
	for k in nuove.size():
		var sc := Tutorial.scheda(nuove[k])
		if not tutorial_attivi:
			_notifica(sc["avviso"], false, mondo_di_px(centro) if fondato else Vector2(-1, -1))
			continue
		_decidi("tutorial", sc["titolo"], sc["testo"], [{"id": "continua", "testo": "Continua", "nota": ""}, {"id": "salta", "testo": "Salta i tutorial", "nota": ""}])
		var d: Dictionary = decisioni[-1]
		d["chiave"] = nuove[k]
		d["domanda"] = sc["domanda"]
		d["dettaglio"] = sc["dettaglio"]
		d["tappa"] = tappa
		d["pagina"] = k + 1
		d["pagine"] = nuove.size()


## "Salta i tutorial" (Fede, 26/11/2026): vale per tutti i riquadri della partita in corso. Quelli
## già in coda diventano notifiche grigie.
func salta_tutorial() -> void:
	tutorial_attivi = false
	var resto: Array = []
	for d in decisioni:
		if d["tipo"] == "tutorial":
			_notifica(Tutorial.scheda(d["chiave"])["avviso"], false, mondo_di_px(centro) if fondato else Vector2(-1, -1))
		else:
			resto.append(d)
	decisioni = resto


## Quante decisioni in attesa sono tutorial (le prove le contano a parte dalle pause vere).
func tutorial_in_attesa() -> bool:
	return not decisioni.is_empty() and decisioni[0]["tipo"] == "tutorial"


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
	legnaie = []
	celle_tagliate = {}
	celle_zona_attiva = {}
	_tagli_px = {}
	poste = []
	capanni = []
	tagli_anno = []
	zona_attiva = {}
	stanchezza = {}
	pascolo = {}
	capi = 0.0
	portata_capi = 0.0
	maggese = {}
	concimati = {}
	pascolo_eccessivo = 0.0
	consenso = {"anziani": 60.0, "famiglie": 60.0, "sacerdote": 60.0}
	# Le tappe raggiunte restano anche dopo una rifondazione: il sacerdote che ha già voce la tiene.
	sacerdote_attivo = sbloccato("luogo_sacro")
	luogo_sacro = Vector2(-1, -1)
	cantiere_luogo_sacro = 0
	bosco_sacro = {}
	cantiere_granaio = 0
	_azzera_scorrerie()
	_difesa_sito = float(valuta_sito(p)["valori"]["difesa"])
	limo = {}
	piena_tra = -1
	zona_piena = false
	_conta_riquadri()
	_risorse = _risorse_dai_riquadri()
	_anni_risorse = 5
	bosco_iniziale = _risorse["bosco"]
	disboscamento = 0.0
	_aggiorna_abbondanza()
	abbondanza_lenta = abbondanza
	casali = []
	case_casale = {}
	anni_deficit = 0
	traffico = {}
	strade = {}
	anni_battuto = {}
	pixel_strada = {}
	gia_strada = false
	_contado_annunciato = CONTADO_MIN
	stat["fondazioni"] += 1
	var v := valuta_sito(p)
	var nome := (" presso il " + String(v["sito"]["nome"]).to_lower()) if v["sito"] != null else ""
	_scrivi("Fondazione%s. Acqua %s, rischio di piena %s." % [nome, v["acqua"][0], v["piena"][0]], "buono")
	disponi_case()
	# Tutorial della fondazione (Fede, 26/11/2026): gli strumenti del villaggio appena nato.
	tutorial(Tutorial.DOPO_FONDAZIONE, "Fondazione")


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


## Mentre si scorrono molti punti senza cambiare le case (dissodamento): i punti con una casa,
## calcolati una volta (prima si guardavano tutte le case per ogni punto della zona agricola).
var _px_case := {}
var _px_case_fermi := false

func _segna_px_case() -> void:
	_px_case = {}
	for c in case:
		var w := centro_lotto(c)
		var q := px_da_mondo(w.x, w.y)
		for oy in [-1, 0, 1]:
			for ox in [-1, 0, 1]:
				var p := q + Vector2i(ox, oy)
				if _lotti_del_px(p).has_point(c):
					_px_case[p] = true
	_px_case_fermi = true


func _occupato_da_case(p: Vector2i) -> bool:
	if _px_case_fermi:
		return _px_case.has(p)
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
	if bosco_sacro.has(i):
		return "È bosco sacro: nessuno lo dissoda."
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
	var servono := ceili(abitanti_nucleo() / ABITANTI_PER_CASA)
	return (3 + ceili(1.4 * sqrt(servono)) + raggio_extra * 3) * LOTTO


## Resa attesa di un campo in un anno normale (per decidere quanti campi dissodare).
func _resa_attesa(i: int) -> float:
	# Le famiglie sanno quanto rende un campo al margine del bosco (la selvaggina lo rovina).
	_aggiorna_campi_serviti()
	var danni := 1.0 - 0.25 * selvaggina if _campi_al_bosco.has(i) else 1.0
	return RESA_CAMPO * fert(i) * 0.95 * (0.85 + 0.15 * acqua_qualsiasi(i)) * RESA_TECNICA[tecnica_corrente] * danni * fattore_stanchezza(i) / AREA_CELLA


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
	_aggiorna_campi_serviti()
	_serviti_fermi = true
	for i in campi:
		attesa += _resa_attesa(i)
	_serviti_fermi = false
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
	var gia := {}
	for i in campi:
		gia[i] = true
	_segna_px_case()
	for i in zona:
		if gia.has(i):
			continue
		var p := px_di(i)
		if mondo_di_px(p).distance_to(c) < libero or motivo_campo(p) != "":
			continue
		candidati.append(i)
	_px_case_fermi = false
	# Zona piena: niente avviso (decisione di Fede del 25/11/2026), lo dice la mappa.
	zona_piena = candidati.is_empty()
	if candidati.is_empty():
		return 0
	var pregio := {}
	for i in candidati:
		pregio[i] = fert(i) - mondo_di_px(px_di(i)).distance_to(c) / 1500.0
	candidati.sort_custom(func(a: int, b: int) -> bool: return pregio[a] > pregio[b])
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


# ---------- pascolo e animali ----------

## Perché qui non si può stendere il pascolo ("" se si può): terra asciutta o bosco, dentro il contado.
func motivo_pascolo(p: Vector2i) -> String:
	if not fondato:
		return "Prima bisogna fondare il villaggio."
	if not sbloccato("pascolo"):
		return "Il pascolo si apre con la tappa \"%s\" (%d abitanti)." % [TAPPE[tappa_di("pascolo")]["nome"], TAPPE[tappa_di("pascolo")]["abitanti"]]
	if p.x < 0 or p.y < 0 or p.x >= n or p.y >= n:
		return "Fuori dalla mappa."
	var i := px(p)
	if not edificabile(i):
		return "Il pascolo va su prati, radure e boschi, non sull'acqua o nella palude."
	if not a_portata(p):
		return "Fuori dal contado: oggi le famiglie portano gli animali fino a %d m dal villaggio." % roundi(raggio_contado())
	if bosco_sacro.has(i):
		return "È bosco sacro: lì non si pascola."
	return ""


func aggiungi_pascolo(lista: Array[Vector2i]) -> int:
	var aggiunti := 0
	for p in lista:
		if motivo_pascolo(p) == "" and not pascolo.has(px(p)):
			pascolo[px(p)] = true
			aggiunti += 1
	return aggiunti


## Opzione "Togli" (decisione di Fede del 25/11/2026 sera): toglie il pascolo e lascia campi e animali.
func togli_pascolo(lista: Array[Vector2i]) -> int:
	var tolti := 0
	for p in lista:
		if p.x >= 0 and p.y >= 0 and p.x < n and p.y < n and pascolo.erase(px(p)):
			tolti += 1
	return tolti


func _pendio(i: int) -> bool:
	if not _pendii.has(i):
		var p := px_di(i)
		var w := mondo_di_px(p)
		var d := dati.metri_per_px
		var pend := (absf(dati.quota(w.x + d, w.y) - dati.quota(w.x - d, w.y)) + absf(dati.quota(w.x, w.y + d) - dati.quota(w.x, w.y - d))) / (2.0 * d)
		_pendii[i] = pend > PENDIO
	return _pendii[i]


## Ettari di pascolo per tipo di terra: prato, bosco, maggese, stoppie (dopo l'ultimo anno).
func ettari_pascolo() -> Dictionary:
	var e := {"prato": 0.0, "bosco": 0.0, "maggese": 0.0, "stoppie": 0.0}
	for i in pascolo:
		var k := "prato"
		if campi.has(i):
			k = "maggese" if maggese.has(i) else "stoppie"
		elif bosco_in_piedi(i):
			k = "bosco"
		e[k] += AREA_PIXEL_HA
	return e


## Un anno di pascolo, dopo il raccolto: portata della zona, maggese e stoppie, crescita della
## mandria, erosione sui pendii, disuguaglianza se gli animali sono delle famiglie.
func _pascola(lavorati: Dictionary) -> void:
	maggese = {}
	if not sbloccato("pascolo"):
		return
	if capi <= 0.0 and portata_capi <= 0.0:
		capi = CAPI_INIZIALI
		_scrivi("Le famiglie tengono una decina di animali attorno alle case.")
	portata_capi = CAPI_ATTORNO_CASE
	var nuovi_concimati := {}
	var in_pendio := 0
	for i in pascolo:
		if campi.has(i):
			if lavorati.has(i):
				# Stoppie: dopo il raccolto, poca erba e un po' di concime per l'anno dopo.
				portata_capi += CAPI_HA_STOPPIE * AREA_PIXEL_HA
				nuovi_concimati[i] = true
			else:
				# Maggese: gli animali ci stanno tutto l'anno e il campo si riposa più in fretta.
				portata_capi += CAPI_HA_MAGGESE * AREA_PIXEL_HA
				maggese[i] = true
				if stanchezza.has(i):
					stanchezza[i] = float(stanchezza[i]) - RIPOSO_PER_ANNO
					if stanchezza[i] <= 0.0:
						stanchezza.erase(i)
		elif bosco_in_piedi(i):
			portata_capi += CAPI_HA_BOSCO * AREA_PIXEL_HA
		else:
			portata_capi += CAPI_HA_PRATO * AREA_PIXEL_HA
		if _pendio(i):
			in_pendio += 1
	concimati = nuovi_concimati
	var famiglie := politica("raccolto") == "famiglie"
	# Ai segni di pericolo, con animali raccolti vicino alle case, la mandria non cresce.
	var raccolti := in_allerta() and politica("pericolo") == "raccogliere"
	if capi < portata_capi and not raccolti:
		capi = minf(portata_capi, capi * (1.0 + (CRESCITA_CAPI_FAMIGLIE if famiglie else CRESCITA_CAPI)))
	else:
		# Più capi che erba (la zona si è ristretta): una parte si vende o si macella.
		capi -= (capi - portata_capi) * 0.3
	erba = clampf(1.0 - capi / maxf(portata_capi, 1.0), 0.0, 1.0)
	# Erosione: la mandria piena sui pendii della zona di pascolo.
	var quota_pendii := float(in_pendio) / maxf(1.0, pascolo.size())
	var prima := pascolo_eccessivo
	pascolo_eccessivo = clampf((capi / maxf(portata_capi, 1.0) - 0.9) / 0.1, 0.0, 1.0) * quota_pendii
	if pascolo_eccessivo > 0.3 and prima <= 0.3:
		_scrivi("Troppi animali sui pendii: l'erba non ricresce e la terra comincia a scendere.", "allarme")
	# Gli animali delle famiglie arricchiscono chi ne ha di più (decisione di Fede del 25/11/2026).
	var meta := clampf(capi / 300.0, 0.0, 1.0) if famiglie else 0.0
	disuguaglianza += (meta - disuguaglianza) * 0.05


# ---------- luogo sacro, sacerdote, bosco sacro ----------

func motivo_luogo_sacro(punto: Vector2) -> String:
	if not fondato:
		return "Prima bisogna fondare il villaggio."
	if luogo_sacro.x >= 0:
		return "Il luogo sacro c'è già."
	if not sbloccato("luogo_sacro"):
		return "Il luogo sacro si apre con la tappa \"%s\" (%d abitanti)." % [TAPPE[tappa_di("luogo_sacro")]["nome"], TAPPE[tappa_di("luogo_sacro")]["abitanti"]]
	if legna < COSTO_LUOGO_SACRO:
		return "Servono %d di legna per il luogo sacro (ora %d)." % [roundi(COSTO_LUOGO_SACRO), floori(legna)]
	var p := px_da_mondo(punto.x, punto.y)
	var i := px(p)
	if not edificabile(i) or campi.has(i) or sentieri.has(i) or p == centro:
		return "Il luogo sacro va su terra asciutta e libera, non su campi o sentieri."
	if punto.distance_to(mondo_di_px(centro)) > DISTANZA_LUOGO_SACRO:
		return "Il luogo sacro va vicino al villaggio, entro %d m dal centro." % roundi(DISTANZA_LUOGO_SACRO)
	return ""


func costruisci_luogo_sacro(punto: Vector2) -> String:
	var m := motivo_luogo_sacro(punto)
	if m != "":
		return m
	var l := lotto_da_mondo(punto.x, punto.y)
	case = case.filter(func(c: Vector2i) -> bool: return cheb(c, l) > 1)
	luogo_sacro = centro_lotto(l)
	legna -= COSTO_LUOGO_SACRO
	cantiere_luogo_sacro = ANNI_CANTIERE_LUOGO_SACRO
	_scrivi("Si comincia a erigere il luogo sacro: servono %d anni di lavoro." % ANNI_CANTIERE_LUOGO_SACRO)
	disponi_case()
	return ""


func luogo_sacro_pronto() -> bool:
	return luogo_sacro.x >= 0 and cantiere_luogo_sacro <= 0


# ---------- scorrerie e torre di avvistamento (decisioni di Fede del 26/11/2026) ----------

func _azzera_scorrerie() -> void:
	torre = Vector2(-1, -1)
	cantiere_torre = 0
	segni_tra = -1
	segni_punto = Vector2(-1, -1)
	segni_da = ""
	memoria_scorrerie = 0.0
	case_razziate = {}
	rischio_scorrerie = {}


## Le scorrerie sono possibili dalla tappa del pascolo (100 abitanti).
func scorrerie_aperte() -> bool:
	return fondato and tappa >= tappa_di("pascolo")


## Vero tra i segni e la scorreria annunciata.
func in_allerta() -> bool:
	return segni_tra > 0


func torre_pronta() -> bool:
	return torre.x >= 0 and cantiere_torre <= 0


## Da dove, a parole, guardando dal centro (x verso est, z verso sud).
static func direzione(v: Vector2) -> String:
	var a := rad_to_deg(atan2(v.x, -v.y))
	return ["nord", "nord-est", "est", "sud-est", "sud", "sud-ovest", "ovest", "nord-ovest"][posmod(roundi(a / 45.0), 8)]


## Quanto un punto sta sopra i dintorni (metri): un dosso o un colle si vede da lontano.
func rilievo(p: Vector2i) -> float:
	var somma := 0.0
	var conta := 0
	for dy in range(-8, 9, 2):
		for dx in range(-8, 9, 2):
			var q := p + Vector2i(dx, dy)
			if q.x < 0 or q.y < 0 or q.x >= n or q.y >= n:
				continue
			somma += dati.altezze[px(q)]
			conta += 1
	return dati.altezze[px(p)] - somma / maxf(conta, 1)


## Il rischio di una scorreria quest'anno, con le sue parti (per i pannelli e le prove):
## ricchezza visibile × esposizione × (1 − difesa), più alto dal Neolitico recente.
func calcola_rischio_scorrerie() -> Dictionary:
	var c := mondo_di_px(centro)
	var ricchezza := clampf(capi / CAPI_RICCHEZZA, 0.0, 1.0) * 0.6 + clampf(mesi_di_scorta() / MESI_RICCHEZZA, 0.0, 1.0) * 0.4
	var lontani := 0
	for i in pascolo:
		if mondo_di_px(px_di(i)).distance_to(c) > PASCOLO_LONTANO:
			lontani += 1
	var pascolo_lontano := float(lontani) / maxf(pascolo.size(), 1.0) if capi >= 1.0 else 0.0
	var r_px := raggio_campi()
	var usati := float(campi.size() + pascolo.size())
	var margini_vuoti := 1.0 - clampf(usati / maxf(PI * r_px * r_px * 0.35, 1.0), 0.0, 1.0)
	var esposizione := 0.3 + 0.25 * clampf(casali.size() / 3.0, 0.0, 1.0) + 0.25 * pascolo_lontano + 0.2 * margini_vuoti
	var nucleo := case_nel_nucleo()
	var distanza := 0.0
	for l in nucleo:
		distanza += centro_lotto(l).distance_to(c)
	distanza /= maxf(nucleo.size(), 1.0)
	var compatto := clampf(1.0 - (distanza - 60.0) / 140.0, 0.0, 1.0)
	var difesa := clampf(0.55 * _difesa_sito + 0.45 * compatto, 0.0, 1.0)
	var tempo := 2.0 if anno >= ANNO_SCORRERIE_FREQUENTI else 1.0
	return {"p": PROB_SCORRERIA * ricchezza * esposizione * (1.0 - 0.7 * difesa) * tempo,
		"ricchezza": ricchezza, "esposizione": esposizione, "difesa": difesa, "pascolo_lontano": pascolo_lontano,
		"margini_vuoti": margini_vuoti, "compatto": compatto, "sito": _difesa_sito}


## Ogni anno: la scorreria annunciata arriva, oppure (se non c'è) forse arrivano i segni.
## Solo per le prove: senza scorrerie (per misurare quanto pesano sulla crescita).
var scorrerie_spente := false

func _scorrerie() -> void:
	if not scorrerie_aperte() or scorrerie_spente:
		return
	memoria_scorrerie = maxf(0.0, memoria_scorrerie - 100.0 / ANNI_MEMORIA_RAZZIA / 2.0)
	if segni_tra > 0:
		segni_tra -= 1
		if segni_tra == 0:
			segni_tra = -1
			_scorreria()
		return
	rischio_scorrerie = calcola_rischio_scorrerie()
	if not in_attesa() and rng_scorrerie.randf() < float(rischio_scorrerie["p"]):
		_segni()


## Dove colpirà: un casale, un pascolo lontano o il margine del contado.
func _bersaglio_scorreria() -> Vector2:
	var c := mondo_di_px(centro)
	if not casali.is_empty() and rng_scorrerie.randf() < 0.5:
		return centro_lotto(casali[rng_scorrerie.randi() % casali.size()])
	var lontani: Array = []
	for i in pascolo:
		if mondo_di_px(px_di(i)).distance_to(c) > PASCOLO_LONTANO:
			lontani.append(i)
	if not lontani.is_empty() and capi >= 1.0:
		return mondo_di_px(px_di(lontani[rng_scorrerie.randi() % lontani.size()]))
	var a := rng_scorrerie.randf() * TAU
	return c + Vector2(cos(a), sin(a)) * raggio_contado() * 0.8


func _segni() -> void:
	segni_punto = _bersaglio_scorreria()
	segni_da = direzione(segni_punto - mondo_di_px(centro))
	segni_tra = (2 + rng_scorrerie.randi() % 2) if torre_pronta() else (1 + rng_scorrerie.randi() % 2)
	stat["segni"] += 1
	var testi := [
		"Fuochi sulle colline a %s: qualcuno si muove ai margini del contado.",
		"Tracce di sconosciuti nel bosco a %s: impronte, un bivacco spento.",
		"Dei fuggiaschi arrivano da %s: un villaggio vicino è stato razziato.",
	]
	var testo: String = testi[rng_scorrerie.randi() % testi.size()] % segni_da
	if torre_pronta():
		testo = "Dalla torre: " + testo.substr(0, 1).to_lower() + testo.substr(1)
	_scrivi(testo, "allarme")
	_notifica(testo, false, segni_punto)
	# I primi segni fermano il gioco una volta: tutorial e scelta, che diventa la regola.
	if not gia_segni:
		gia_segni = true
		_pericolo_prima = true
		tutorial(["scorrerie", "torre"], "Primi segni di pericolo")
		_decidi("pericolo", "Segni di pericolo",
			testo + "\nGli anziani si riuniscono: cosa si fa ai segni di pericolo? La scelta di oggi diventa l'usanza del villaggio: potrai cambiarla dalle politiche.",
			[{"id": "avanti", "testo": "Andare avanti", "nota": "Nessun costo oggi; se arrivano, prendono quello che trovano."},
			 {"id": "raccogliere", "testo": "Raccogliere animali e scorte", "nota": "Perdite dimezzate; finché dura il pericolo meno caccia e la mandria non cresce."},
			 {"id": "vegliare", "testo": "Vegliare ai margini", "nota": "Perdite minori e case più sicure; gli anziani sono contenti, ma qualche braccio lascia i campi."}])
		return
	_reagisci_ai_segni()


func _reagisci_ai_segni() -> void:
	match politica("pericolo"):
		"vegliare":
			_cambia_consenso("anziani", 2.0)
			_scrivi("Gli uomini vegliano ai margini del contado.")
		"raccogliere":
			_scrivi("Animali e scorte si raccolgono vicino alle case.")


## La scorreria: animali e scorte persi, a volte case bruciate ai margini; gli anziani perdono
## credito; la paura stringe l'abitato.
func _scorreria() -> void:
	var r := calcola_rischio_scorrerie()
	var f_politica: float = {"avanti": 1.0, "raccogliere": 0.5, "vegliare": 0.6}.get(politica("pericolo"), 1.0)
	var f := lerpf(1.0, f_politica, efficacia_usanze()) * (PERDITE_TORRE if torre_pronta() else 1.0)
	var quota_capi := clampf((0.1 + 0.3 * float(r["pascolo_lontano"]) * rng_scorrerie.randf_range(0.5, 1.0)) * f, 0.0, 0.4)
	var capi_persi := floori(capi * quota_capi)
	var cibo_perso := cibo * rng_scorrerie.randf_range(0.1, 0.25) * f * (0.7 if granaio_pronto() else 1.0)
	capi -= capi_persi
	cibo -= cibo_perso
	# Case: i casali e le case del nucleo ai margini, le più vicine a dove colpiscono.
	var c := mondo_di_px(centro)
	var esposte: Array = case.filter(func(l: Vector2i) -> bool: return case_casale.has(l) or centro_lotto(l).distance_to(c) > MARGINE_ABITATO)
	esposte.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return centro_lotto(a).distance_to(segni_punto) < centro_lotto(b).distance_to(segni_punto))
	var bruciate := 0
	var p_case := 0.35 * (1.0 - float(r["difesa"])) * (0.5 if politica("pericolo") == "vegliare" else 1.0) * (PERDITE_TORRE if torre_pronta() else 1.0)
	if not esposte.is_empty() and rng_scorrerie.randf() < p_case:
		bruciate = mini(esposte.size(), 2 if rng_scorrerie.randf() < 0.3 else 1)
		for k in bruciate:
			var l: Vector2i = esposte[k]
			case.erase(l)
			case_casale.erase(l)
			macerie[l] = ANNI_MACERIE
			rovine.append(centro_lotto(l))
		pop -= minf(pop, bruciate * 2.5)
	for l in case:
		if centro_lotto(l).distance_to(segni_punto) < 300.0:
			case_razziate[l] = anno
	_cambia_consenso("anziani", -8.0 * f)
	_cambia_consenso("famiglie", -3.0 - 3.0 * bruciate)
	memoria_scorrerie = 100.0
	stat["scorrerie"] += 1
	stat["case_bruciate"] += bruciate
	ultima_scorreria = {"anno": anno, "capi": capi_persi, "cibo": roundi(cibo_perso), "case": bruciate, "da": segni_da}
	if stat["scorrerie"] == 1:
		_scrivi("Le scorrerie le attirano gli animali e le scorte che si vedono, i casali e i pascoli lontani, i margini del contado lasciati vuoti; le frenano un villaggio in alto e le case raccolte. Finché il ricordo resta vivo, le famiglie costruiranno più vicine al centro.")
	var cosa: Array[String] = []
	if capi_persi > 0:
		cosa.append("%d capi" % capi_persi)
	if roundi(cibo_perso) > 0:
		cosa.append("%d di cibo" % roundi(cibo_perso))
	var testo := "Scorreria da %s: portati via %s" % [segni_da, " e ".join(cosa) if not cosa.is_empty() else "poco o niente"]
	if bruciate > 0:
		testo += "; %s ai margini" % ("bruciata una casa" if bruciate == 1 else "bruciate %d case" % bruciate)
	_scrivi(testo + ".", "allarme")
	_notifica(testo + ".", true, segni_punto)
	segni_punto = Vector2(-1, -1)
	disponi_case()


## Solo per le prove (menù Prova): fa arrivare subito i segni di una scorreria, o anticipa quella
## già annunciata all'anno prossimo.
func prova_scorreria() -> String:
	if not fondato:
		return "Prima bisogna fondare il villaggio."
	if in_allerta():
		segni_tra = 1
		return "La scorreria annunciata arriverà l'anno prossimo."
	_segni()
	return "Segni di scorreria (prova): la scorreria arriverà tra %d anni." % segni_tra


## Prova dell'evento soglia (menù Prova): il tempo salta al 3000 a.C. (se è prima), a decenni, con
## i presagi già arrivati, e l'evento arriva subito anche se il territorio non è pieno.
func prova_soglia() -> String:
	if not fondato:
		return "Prima bisogna fondare il villaggio."
	if soglia_scelta != "":
		return "L'evento del metallo c'è già stato."
	anno = maxi(anno, ANNO_SOGLIA)
	decenni = true
	presagi_soglia = maxi(presagi_soglia, 2)
	var prima := anno
	anno = maxi(anno, ANNO_SOGLIA_COMUNQUE)
	_soglia()
	anno = prima
	return "Evento del metallo (prova): il tempo è saltato al %s." % anno_testo(anno)


func motivo_torre(punto: Vector2) -> String:
	if not fondato:
		return "Prima bisogna fondare il villaggio."
	if torre.x >= 0:
		return "La torre di avvistamento c'è già."
	if not sbloccato("torre"):
		return "La torre di avvistamento si apre con i primi segni di pericolo."
	if legna < COSTO_TORRE:
		return "Servono %d di legna per la torre (ora %d)." % [roundi(COSTO_TORRE), floori(legna)]
	var p := px_da_mondo(punto.x, punto.y)
	var i := px(p)
	if not edificabile(i) or campi.has(i) or sentieri.has(i) or p == centro:
		return "La torre va su terra asciutta e libera, non su campi o sentieri."
	if punto.distance_to(mondo_di_px(centro)) > DISTANZA_TORRE:
		return "La torre va entro %d m dal centro del villaggio." % roundi(DISTANZA_TORRE)
	if rilievo(p) < RILIEVO_TORRE:
		return "Da qui non si vede lontano: la torre va su un dosso o un colle."
	return ""


func costruisci_torre(punto: Vector2) -> String:
	var m := motivo_torre(punto)
	if m != "":
		return m
	var l := lotto_da_mondo(punto.x, punto.y)
	case = case.filter(func(c: Vector2i) -> bool: return cheb(c, l) > 1)
	torre = centro_lotto(l)
	legna -= COSTO_TORRE
	cantiere_torre = ANNI_CANTIERE_TORRE
	_scrivi("Si comincia a costruire la torre di avvistamento: servono %d anni di lavoro." % ANNI_CANTIERE_TORRE)
	disponi_case()
	return ""


# ---------- sentieri che diventano strade (voce 5, 26/11/2026) ----------

static func chiave_tratto(t: Array) -> Vector4i:
	var a: Vector2i = t[0]
	var b: Vector2i = t[1]
	return Vector4i(a.x, a.y, b.x, b.y)


## La rete dei sentieri come grafo: pixel -> vicini (anche in diagonale), con il centro.
func rete() -> Dictionary:
	var firma := hash([sentieri.hash(), centro])
	if firma == _firma_rete:
		return _rete
	_firma_rete = firma
	_rete = {}
	var nodi := {}
	for i in sentieri:
		nodi[i] = true
	if fondato:
		nodi[px(centro)] = true
	for i in nodi:
		var p := px_di(i)
		var vicini: Array[int] = []
		for oy in [-1, 0, 1]:
			for ox in [-1, 0, 1]:
				if ox == 0 and oy == 0:
					continue
				var q := p + Vector2i(ox, oy)
				if q.x >= 0 and q.y >= 0 and q.x < n and q.y < n and nodi.has(px(q)):
					vicini.append(px(q))
		_rete[i] = vicini
	# Cammini più brevi dal centro (in passi della rete).
	_padri = {}
	if fondato and _rete.has(px(centro)):
		var coda: Array[int] = [px(centro)]
		_padri[px(centro)] = -1
		var testa := 0
		while testa < coda.size():
			var i: int = coda[testa]
			testa += 1
			for j in _rete[i]:
				if not _padri.has(j):
					_padri[j] = i
					coda.append(j)
	return _rete


## Il punto della rete collegato al centro più vicino a `w` (metri), entro `entro`; -1 se nessuno.
func nodo_vicino(w: Vector2, entro: float) -> int:
	rete()
	var migliore := -1
	var dm := entro
	for i in _padri:
		var d := mondo_di_px(px_di(i)).distance_to(w)
		if d < dm:
			dm = d
			migliore = i
	return migliore


## Cammino sulla rete tra due punti della rete (pixel, dal primo all'ultimo); vuoto se non collegati.
func cammino_rete(da: int, a: int) -> Array[int]:
	var r := rete()
	if not r.has(da) or not r.has(a):
		return []
	var padri := {da: -1}
	var coda: Array[int] = [da]
	var testa := 0
	while testa < coda.size():
		var i: int = coda[testa]
		testa += 1
		if i == a:
			break
		for j in r[i]:
			if not padri.has(j):
				padri[j] = i
				coda.append(j)
	if not padri.has(a):
		return []
	var out: Array[int] = []
	var k := a
	while k != -1:
		out.push_front(k)
		k = padri[k]
	return out


## Per le figure: i punti (metri) da seguire lungo sentieri e strade per andare da `da` ad `a`; vuoto
## se conviene andare dritti (vicini, rete lontana o giro troppo lungo).
func percorso_rete(da: Vector2, a: Vector2) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var diretto := da.distance_to(a)
	if diretto < 150.0 or sentieri.is_empty():
		return out
	var n1 := nodo_vicino(da, 200.0)
	var n2 := nodo_vicino(a, 200.0)
	if n1 < 0 or n2 < 0 or n1 == n2:
		return out
	var c := cammino_rete(n1, n2)
	if c.size() < 2:
		return out
	var lungo := da.distance_to(mondo_di_px(px_di(c[0]))) + mondo_di_px(px_di(c[-1])).distance_to(a) + (c.size() - 1) * dati.metri_per_px
	if lungo > diretto * 1.5:
		return out
	for k in c.size():
		if k == 0 or k == c.size() - 1 or k % 2 == 0:
			out.append(mondo_di_px(px_di(c[k])))
	return out


## Vero se c'è una strada entro `entro` metri dal punto.
func _vicino_a_strada(w: Vector2, entro: float) -> bool:
	if pixel_strada.is_empty():
		return false
	var p := px_da_mondo(w.x, w.y)
	var r := ceili(entro / dati.metri_per_px)
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			if pixel_strada.has(px(p + Vector2i(dx, dy))) and mondo_di_px(p + Vector2i(dx, dy)).distance_to(w) <= entro:
				return true
	return false


## Chi va a lavorare lontano dal centro passa sulla rete: ogni anno si conta quante persone passano
## su ogni pixel di sentiero; i tratti battuti abbastanza a lungo diventano strade.
func _aggiorna_traffico() -> void:
	traffico = {}
	if not fondato or sentieri.is_empty():
		_aggiorna_strade()
		return
	rete()
	var c := mondo_di_px(centro)
	# Mete raggruppate in riquadri di 160 m: posizione media e persone.
	var gruppi := {}
	var aggiungi := func(w: Vector2, persone: float) -> void:
		if persone <= 0.0:
			return
		var k := Vector2i(floori(w.x / 160.0), floori(w.y / 160.0))
		var g: Array = gruppi.get(k, [Vector2.ZERO, 0.0])
		gruppi[k] = [g[0] + w * persone, float(g[1]) + persone]
	if not campi.is_empty() and fonti["agricoltura"]:
		var a_testa := pop * 0.45 / campi.size()
		for i in campi:
			aggiungi.call(mondo_di_px(px_di(i)), a_testa)
	if capi >= 1.0 and not pascolo.is_empty():
		var a_testa_p := capi / 15.0 / pascolo.size()
		for i in pascolo:
			aggiungi.call(mondo_di_px(px_di(i)), a_testa_p)
	var attive := legnaie.filter(func(l: Dictionary) -> bool: return legnaia_attiva(l))
	for l in attive:
		aggiungi.call(l["punto"], ultima_legna / 3.0 / attive.size())
	for e in poste + capanni:
		if int(e["cantiere"]) <= 0:
			aggiungi.call(e["punto"], 3.0)
	if luogo_sacro_pronto():
		aggiungi.call(luogo_sacro, pop * 0.1)
	for k in casali.size():
		var nel := case_casale.values().count(k)
		aggiungi.call(centro_lotto(casali[k]), nel * ABITANTI_PER_CASA * 0.5)
	for k in gruppi:
		var g: Array = gruppi[k]
		var w: Vector2 = g[0] / float(g[1])
		if w.distance_to(c) < 150.0:
			continue
		var nodo := nodo_vicino(w, 250.0)
		if nodo < 0:
			continue
		var i := nodo
		while i != -1 and i != px(centro):
			traffico[i] = float(traffico.get(i, 0.0)) + float(g[1])
			i = _padri.get(i, -1)
	_aggiorna_strade()


func _aggiorna_strade() -> void:
	var presenti := {}
	for i in sentieri:
		presenti[i] = true
	pixel_strada = {}
	var aperte := sbloccato("strade")
	for t in tratti_sentiero:
		var k := chiave_tratto(t)
		var somma := 0.0
		var conta := 0
		var pixel: Array[int] = []
		for q in punti_tratto(t[0], t[1]):
			var i := px(q)
			if presenti.has(i):
				pixel.append(i)
				somma += float(traffico.get(i, 0.0))
				conta += 1
		if conta == 0:
			strade.erase(k)
			anni_battuto.erase(k)
			continue
		var media := somma / conta
		anni_battuto[k] = int(anni_battuto.get(k, 0)) + 1 if media >= SOGLIA_STRADA else 0
		if aperte and not strade.has(k) and int(anni_battuto[k]) >= ANNI_STRADA:
			strade[k] = anno
			var m := mondo_di_px((Vector2(t[0]) + Vector2(t[1])) * 0.5)
			if not gia_strada:
				gia_strada = true
				_scrivi("Il sentiero più battuto è diventato una strada: chi ci passa ogni giorno l'ha allargato e consumato. Le strade restano: i campi vicini rendono di più e le case cominciano a crescere lungo la via.", "buono")
			else:
				_scrivi("Un altro sentiero è diventato una strada.", "buono")
			_notifica("Un sentiero è diventato una strada.", false, m)
		if strade.has(k):
			for i in pixel:
				pixel_strada[i] = true


## Dopo una demolizione: le strade restano solo dove resta il sentiero (una strada si toglie solo
## demolendola).
func _togli_strade_demolite() -> void:
	var presenti := {}
	for i in sentieri:
		presenti[i] = true
	for i in pixel_strada.keys():
		if not presenti.has(i):
			pixel_strada.erase(i)
	for t in tratti_sentiero:
		if not punti_tratto(t[0], t[1]).any(func(q: Vector2i) -> bool: return presenti.has(px(q))):
			strade.erase(chiave_tratto(t))
			anni_battuto.erase(chiave_tratto(t))


## Traffico di un tratto (persone l'anno, media dei suoi pixel) e anni di fila sopra la soglia.
func traffico_tratto(t: Array) -> Array:
	var somma := 0.0
	var conta := 0
	for q in punti_tratto(t[0], t[1]):
		if sentieri.has(px(q)):
			somma += float(traffico.get(px(q), 0.0))
			conta += 1
	return [somma / maxf(conta, 1), int(anni_battuto.get(chiave_tratto(t), 0))]


## Il tratto di sentiero più vicino a un punto (metri), entro `entro`; vuoto se nessuno.
func tratto_vicino(w: Vector2, entro := 30.0) -> Array:
	var migliore: Array = []
	var dm := entro
	for t in tratti_sentiero:
		var a := mondo_di_px(t[0])
		var b := mondo_di_px(t[1])
		var ab := b - a
		var f := clampf((w - a).dot(ab) / maxf(ab.length_squared(), 1.0), 0.0, 1.0)
		var d := w.distance_to(a + ab * f)
		if d < dm:
			dm = d
			migliore = t
	return migliore


## Ettari di bosco sacro ancora in piedi.
func ettari_bosco_sacro() -> float:
	var n_px := 0
	for i in bosco_sacro:
		if bosco_in_piedi(i):
			n_px += 1
	return n_px * AREA_PIXEL_HA


## Perché il bosco sacro non si può stendere qui ("" se si può).
func motivo_bosco_sacro(p: Vector2i) -> String:
	if not fondato:
		return "Prima bisogna fondare il villaggio."
	if not sbloccato("bosco_sacro"):
		return "Il bosco sacro si apre con la tappa \"%s\" (%d abitanti)." % [TAPPE[tappa_di("bosco_sacro")]["nome"], TAPPE[tappa_di("bosco_sacro")]["abitanti"]]
	if p.x < 0 or p.y < 0 or p.x >= n or p.y >= n:
		return "Fuori dalla mappa."
	var i := px(p)
	if not bosco_in_piedi(i) or campi.has(i):
		return "Il bosco sacro va dove c'è il bosco."
	if mondo_di_px(p).distance_to(mondo_di_px(centro)) > DISTANZA_BOSCO_SACRO:
		return "Il bosco sacro va entro %d m dal villaggio." % roundi(DISTANZA_BOSCO_SACRO)
	return ""


## Stende il bosco sacro sui pixel di bosco indicati; restituisce quanti sono stati aggiunti.
func aggiungi_bosco_sacro(lista: Array[Vector2i]) -> int:
	var aggiunti := 0
	for p in lista:
		if motivo_bosco_sacro(p) == "" and not bosco_sacro.has(px(p)):
			bosco_sacro[px(p)] = true
			aggiunti += 1
	return aggiunti


## Cosa vuole il sacerdote: il luogo sacro, un bosco sacro grande (dalla sua tappa) e i presagi
## ascoltati (questi passano dai bonus delle scelte).
func obiettivo_sacerdote() -> float:
	var o := 48.0
	# Senza luogo sacro il sacerdote è contrariato (sotto 40): presagi ambigui, consenso più basso.
	o += 10.0 if luogo_sacro_pronto() else -18.0
	if sbloccato("bosco_sacro"):
		o += 14.0 * clampf(ettari_bosco_sacro() / ETTARI_BOSCO_SACRO, 0.0, 1.0)
	else:
		o += 7.0
	return o


## [anni minimi fra due presagi, probabilità all'anno dopo l'attesa].
func ritmo_presagi() -> Array:
	var attesa := float(ANNI_TRA_PRESAGI_DECENNI if decenni else ANNI_TRA_PRESAGI)
	var prob := PROB_PRESAGIO_DECENNI if decenni else PROB_PRESAGIO
	if sacerdote_attivo and consenso["sacerdote"] < SACERDOTE_SCONTENTO:
		attesa *= 0.5
		prob *= 2.0
	return [roundi(attesa), prob]


func quota_presagi_falsi() -> float:
	if not sacerdote_attivo:
		return PRESAGI_FALSI
	if consenso["sacerdote"] >= 60.0:
		return 0.15
	if consenso["sacerdote"] < 40.0:
		return 0.4
	return PRESAGI_FALSI


## Il presagio delle sorgenti: più chiaro con il sacerdote contento, ambiguo se è scontento.
func _testo_sorgenti() -> String:
	if sacerdote_attivo and consenso["sacerdote"] < 40.0:
		return "Le sorgenti danno un po' meno acqua. Il sacerdote, scontento, non dice cosa significhi; c'è chi parla di un'annata qualunque.\nControlla la mappa dell'acqua."
	var t := "Le sorgenti danno meno acqua del solito e l'erba ingiallisce presto. Gli anziani chiedono di mettere da parte il raccolto."
	if sacerdote_attivo and consenso["sacerdote"] >= 60.0:
		t += " Il sacerdote conferma: l'acqua nei pozzi scende da settimane, e le rondini sono partite presto."
	return t + "\nControlla la mappa dell'acqua."


## Bosco in piedi: c'è nella mappa (e nel gioco non è stato tagliato) e le legnaie non l'hanno
## abbattuto da meno di ANNI_RICRESCITA anni.
func bosco_in_piedi(i: int) -> bool:
	if tagliati.has(i):
		# Il pascolo tiene aperte le radure: lì il bosco non ricresce.
		if zona_attiva.has(i) or pascolo.has(i) or anno - int(tagliati[i]) < ANNI_RICRESCITA:
			return false
		tagliati.erase(i)
		_tagli_px.erase(i)
	return bosco_presente.call(i)


## Legno da tagliare per le legnaie: bosco in piedi, oppure palude non tagliata di recente.
func legno_in_piedi(i: int) -> bool:
	if bosco_sacro.has(i):
		return false
	if dati.tipo[i] == MappaDati.PALUDE:
		return not (tagliati.has(i) and (zona_attiva.has(i) or anno - int(tagliati[i]) < ANNI_RICRESCITA))
	return bosco_in_piedi(i) and not campi.has(i)


func motivo_legnaia(punto: Vector2) -> String:
	if not fondato:
		return "Prima bisogna fondare il villaggio."
	var p := px_da_mondo(punto.x, punto.y)
	var i := px(p)
	if not edificabile(i) or campi.has(i) or sentieri.has(i) or p == centro:
		return "La legnaia va su terra asciutta e libera, non su campi o sentieri."
	if punto.distance_to(mondo_di_px(centro)) > DISTANZA_MASSIMA_LEGNAIA:
		return "Troppo lontano dal villaggio: la legnaia va entro %d m dal centro." % roundi(DISTANZA_MASSIMA_LEGNAIA)
	# Nessuna distanza minima tra legnaie (Fede, 25/11/2026): chi ne mette tante nello stesso
	# bosco lo esaurisce prima, ed è una scelta sua. Solo non due sullo stesso lotto.
	for l in legnaie:
		if px_da_mondo((l["punto"] as Vector2).x, (l["punto"] as Vector2).y) == p:
			return "C'è già una legnaia qui."
	# La legnaia non costa legna, solo braccia: senza legna si deve poterne fare una (altrimenti un
	# villaggio rimasto senza legna non ne uscirebbe più).
	return ""


## Bosco attorno a un punto, entro RAGGIO_LEGNAIA (per la lettura sotto il puntatore): quota da 0
## a 1 dei pixel di bosco in piedi e distanza dal più vicino (metri, -1 se nessuno).
func bosco_per_legnaia(punto: Vector2) -> Dictionary:
	var p := px_da_mondo(punto.x, punto.y)
	var r := ceili(RAGGIO_LEGNAIA / dati.metri_per_px)
	var tot := 0
	var bosco := 0
	var vicino := -1.0
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var q := p + Vector2i(dx, dy)
			if q.x < 0 or q.y < 0 or q.x >= n or q.y >= n:
				continue
			var d := mondo_di_px(q).distance_to(punto)
			if d > RAGGIO_LEGNAIA:
				continue
			tot += 1
			if legno_in_piedi(px(q)):
				bosco += 1
				if vicino < 0.0 or d < vicino:
					vicino = d
	return {"quota": float(bosco) / maxf(1.0, tot), "vicino": vicino}


func costruisci_legnaia(punto: Vector2) -> String:
	var m := motivo_legnaia(punto)
	if m != "":
		return m
	var p := px_da_mondo(punto.x, punto.y)
	var r := ceili(RAGGIO_LEGNAIA / dati.metri_per_px)
	var lista: Array = []
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var q := p + Vector2i(dx, dy)
			if q.x < 0 or q.y < 0 or q.x >= n or q.y >= n:
				continue
			var d := mondo_di_px(q).distance_to(punto)
			# Anche le paludi danno legna (ontani, salici, canne), meno del bosco.
			if d <= RAGGIO_LEGNAIA and (dati.copertura[px(q)] > 127 or dati.tipo[px(q)] == MappaDati.PALUDE):
				lista.append([d, px(q)])
	lista.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var l := lotto_da_mondo(punto.x, punto.y)
	var centro_l := centro_lotto(l)
	case = case.filter(func(c: Vector2i) -> bool: return cheb(c, l) > 1)
	legnaie.append({"punto": centro_l, "cantiere": ANNI_CANTIERE_LEGNAIA, "bosco": lista, "celle": _celle_di_alberi(centro_l),
		"debito": 0.0, "raggio": 0.0, "ultimo": anno, "riposo": false, "pixel": {}, "fatte": {}, "attiva": true})
	_scrivi("Si comincia a costruire una legnaia: tra %d anni i boscaioli taglieranno gli alberi attorno." % ANNI_CANTIERE_LEGNAIA)
	disponi_case()
	return ""


func _alberi() -> Alberi:
	if alberi == null:
		alberi = Alberi.new(dati)
	return alberi


## Valore in legna (m³) di un albero della mappa, dal modello e dalla scala.
static func valore_albero(modello: int, scala: float) -> float:
	var specie := 0
	for k in Alberi.VARIANTI.size():
		if modello >= int(Alberi.VARIANTI[k][0]):
			specie = k
	return float(VALORE_SPECIE[specie]) * pow(scala / 1.15, 2.0)


## Le celle da 10 m con alberi entro RAGGIO_LEGNAIA da un punto, dalla più vicina: [distanza, cella,
## valore (somma degli alberi della cella)]. Le celle di campi e del bosco sacro restano fuori.
func _celle_di_alberi(punto: Vector2) -> Array:
	var a := _alberi()
	var k := Alberi.CAMPI
	var valori := {}
	var b0 := Vector2i(floori((punto.x - RAGGIO_LEGNAIA) / Alberi.LATO_BLOCCO), floori((punto.y - RAGGIO_LEGNAIA) / Alberi.LATO_BLOCCO))
	var b1 := Vector2i(floori((punto.x + RAGGIO_LEGNAIA) / Alberi.LATO_BLOCCO), floori((punto.y + RAGGIO_LEGNAIA) / Alberi.LATO_BLOCCO))
	var nb := ceili(dati.lato_metri() / Alberi.LATO_BLOCCO)
	for by in range(maxi(b0.y, 0), mini(b1.y, nb - 1) + 1):
		for bx in range(maxi(b0.x, 0), mini(b1.x, nb - 1) + 1):
			var arr := a.alberi_nel_blocco(Vector2i(bx, by))
			for t in arr.size() / k:
				var x := arr[t * k]
				var z := arr[t * k + 1]
				if Vector2(x, z).distance_to(punto) > RAGGIO_LEGNAIA:
					continue
				var v := valore_albero(int(arr[t * k + 4]), arr[t * k + 3])
				if v <= 0.0:
					continue
				var c := Vector2i(floori(x / LATO_CELLA_TAGLIO), floori(z / LATO_CELLA_TAGLIO))
				valori[c] = float(valori.get(c, 0.0)) + v
	var lista: Array = []
	for c in valori:
		var w := (Vector2(c) + Vector2(0.5, 0.5)) * LATO_CELLA_TAGLIO
		var i := px(px_da_mondo(w.x, w.y))
		if campi.has(i) or bosco_sacro.has(i):
			continue
		lista.append([w.distance_to(punto), c, valori[c]])
		if not _celle_px.has(i) or int(_celle_px[i]) < 1:
			_celle_px[i] = 0
	lista.sort_custom(func(x: Array, y: Array) -> bool: return x[0] < y[0])
	# Quante celle con alberi ha ogni pixel (per dire quando un pixel di bosco è abbattuto).
	var conta := {}
	for voce in lista:
		var w2 := (Vector2(voce[1]) + Vector2(0.5, 0.5)) * LATO_CELLA_TAGLIO
		var i2 := px(px_da_mondo(w2.x, w2.y))
		conta[i2] = int(conta.get(i2, 0)) + 1
	for i3 in conta:
		_celle_px[i3] = maxi(int(_celle_px.get(i3, 0)), int(conta[i3]))
	return lista


## Una cella ha ancora alberi da tagliare: non tagliata, o ricresciuta fuori dalle zone di passaggio.
func cella_in_piedi(c: Vector2i) -> bool:
	if celle_tagliate.has(c):
		if celle_zona_attiva.has(c) or anno - int(celle_tagliate[c]) < ANNI_RICRESCITA:
			return false
		celle_tagliate.erase(c)
	var w := (Vector2(c) + Vector2(0.5, 0.5)) * LATO_CELLA_TAGLIO
	var i := px(px_da_mondo(w.x, w.y))
	if (_insieme_campi.has(i) if _campi_fermi else campi.has(i)) or bosco_sacro.has(i) or pascolo.has(i):
		return false
	return albero_presente.call(w.x, w.y)


## Mentre le legnaie lavorano i campi non cambiano: si guardano in un insieme invece che nella lista
## (cercare in una lista di mille campi per ogni cella era il punto più lento delle legnaie).
var _insieme_campi := {}
var _campi_fermi := false


## Distanza dalla legnaia agli alberi in piedi più vicini (metri; -1 se non ce ne sono più).
func _bosco_vicino_legnaia(l: Dictionary) -> float:
	var celle: Array = l["celle"]
	for k in range(_primo_in_piedi(l), celle.size()):
		if cella_in_piedi(celle[k][1]):
			return float(celle[k][0])
	return -1.0


## Le celle di una legnaia sono in ordine di distanza e quelle vicine, tagliate, restano giù finché
## la legnaia lavora: si ricorda da dove ricominciare a cercare (prima si ripartiva ogni anno dalla
## prima cella, scorrendo migliaia di celle già tagliate). Si riparte da capo quando qualcosa può
## far tornare in piedi una cella: una legnaia che si ferma o riparte, campi o pascoli tolti, e
## comunque ogni 25 anni (`_controlla_puntatori`).
func _primo_in_piedi(l: Dictionary) -> int:
	var celle: Array = l["celle"]
	# Una cella saltata perché tagliata (fuori da una zona di taglio attiva) può ricrescere: quando
	# arriva l'anno della prima ricrescita possibile si ricomincia da capo.
	if anno >= int(l.get("rinascita", 1 << 30)):
		l["primo"] = 0
		l["rinascita"] = 1 << 30
	var k := int(l.get("primo", 0))
	while k < celle.size() and not cella_in_piedi(celle[k][1]):
		var c: Vector2i = celle[k][1]
		if celle_tagliate.has(c) and not celle_zona_attiva.has(c):
			l["rinascita"] = mini(int(l.get("rinascita", 1 << 30)), int(celle_tagliate[c]) + ANNI_RICRESCITA)
		k += 1
	l["primo"] = k
	return k


var _misure_puntatori := []

func _controlla_puntatori() -> void:
	var attive := legnaie.map(func(l: Dictionary) -> bool: return legnaia_attiva(l))
	var ora := [campi.size(), pascolo.size(), bosco_sacro.size(), attive, anno / 25]
	var prima := _misure_puntatori
	_misure_puntatori = ora
	# Più campi, più pascolo o più bosco sacro tolgono celle, non ne fanno tornare: si continua.
	if prima.size() == ora.size() and int(ora[0]) >= int(prima[0]) and int(ora[1]) >= int(prima[1]) \
			and int(ora[2]) >= int(prima[2]) and ora[3] == prima[3] and ora[4] == prima[4]:
		return
	for l in legnaie:
		l["primo"] = 0
		l["rinascita"] = 1 << 30


## Quanti tronchi l'anno può tagliare una legnaia: pieni con gli alberi a ridosso, poi meno man mano
## che il fronte del taglio si allontana (i boscaioli camminano di più).
func capacita_legnaia(l: Dictionary) -> float:
	if int(l["cantiere"]) > 0 or bool(l["riposo"]):
		return 0.0
	var d := _bosco_vicino_legnaia(l)
	if d < 0.0:
		return 0.0
	# Una legnaia su una strada porta i tronchi in fretta (accesso).
	var strada := 1.1 if _vicino_a_strada(l["punto"], 80.0) else 1.0
	return CAPACITA_TAGLIO * strada * clampf(1.0 - d / RAGGIO_LEGNAIA, 0.0, 1.0)


## Legna da ardere che offre il bosco attorno alle legnaie al lavoro (m³ l'anno): ogni pixel di bosco
## in piedi conta una volta sola, di più se è vicino a una legnaia.
func _offerta_raccolta() -> float:
	var pesi := {}
	for l in legnaie:
		if int(l["cantiere"]) > 0 or bool(l["riposo"]):
			continue
		for voce in l["bosco"]:
			var i: int = voce[1]
			var w := 1.0 - 0.5 * float(voce[0]) / RAGGIO_LEGNAIA
			if w > float(pesi.get(i, 0.0)):
				pesi[i] = w
	var tot := 0.0
	for i in pesi:
		if bosco_sacro.has(i):
			continue
		if dati.tipo[i] == MappaDati.PALUDE:
			if not tagliati.has(i):
				tot += 0.5 * float(pesi[i])
		elif bosco_in_piedi(i) and not campi.has(i):
			tot += float(pesi[i])
	return tot * AREA_PIXEL_HA * RESA_RACCOLTA


## Una legnaia lavora: finita, non a riposo, e ha abbattuto qualcosa negli ultimi ANNI_SENZA_TAGLIO anni.
func legnaia_attiva(l: Dictionary) -> bool:
	return int(l["cantiere"]) <= 0 and not bool(l["riposo"]) and anno - int(l["ultimo"]) < ANNI_SENZA_TAGLIO


## Stato delle zone di taglio: quella di una legnaia che smette di lavorare va a riposo e il bosco
## comincia a ricrescere dalle ceppaie da quest'anno; quella di una legnaia che lavora resta tagliata.
func _aggiorna_zone_taglio() -> void:
	zona_attiva = {}
	celle_zona_attiva = {}
	for l in legnaie:
		var ora := legnaia_attiva(l)
		if bool(l["attiva"]) and not ora and int(l["cantiere"]) <= 0:
			# Non più di passaggio: il bosco comincia a ricrescere da quest'anno.
			for i in l["pixel"]:
				tagliati[i] = anno
			for c in l["fatte"]:
				celle_tagliate[c] = anno
		# Niente righe di cronaca: lo stato si vede dal cerchio e nel pannello della legna (una
		# legnaia si ferma da sola quando la catasta è piena, e la cronaca si riempirebbe).
		l["attiva"] = ora
		if ora:
			for i in l["pixel"]:
				zona_attiva[i] = true
			for c in l["fatte"]:
				celle_zona_attiva[c] = true
		else:
			# A riposo, la zona si ricostruisce da ciò che è ancora abbattuto.
			for i in (l["pixel"] as Dictionary).keys():
				if not tagliati.has(i) or anno - int(tagliati[i]) >= ANNI_RICRESCITA:
					(l["pixel"] as Dictionary).erase(i)
			for c in (l["fatte"] as Dictionary).keys():
				if not celle_tagliate.has(c) or anno - int(celle_tagliate[c]) >= ANNI_RICRESCITA:
					(l["fatte"] as Dictionary).erase(c)
			if (l["fatte"] as Dictionary).is_empty():
				l["raggio"] = 0.0


## La legnaia più vicina al punto, entro `entro` metri (-1 se nessuna).
func legnaia_vicina(punto: Vector2, entro := 40.0) -> int:
	for k in legnaie.size():
		if (legnaie[k]["punto"] as Vector2).distance_to(punto) <= entro:
			return k
	return -1


## Mette una legnaia a riposo ("Lasciar ricrescere", decisione di Fede del 25/11/2026) o la rimette
## al lavoro.
func metti_a_riposo(k: int, riposo: bool) -> void:
	if k < 0 or k >= legnaie.size():
		return
	var l: Dictionary = legnaie[k]
	l["riposo"] = riposo
	if not riposo:
		l["ultimo"] = anno
	_aggiorna_zone_taglio()


## Stato di una legnaia per il giocatore.
func stato_legnaia(l: Dictionary) -> String:
	if int(l["cantiere"]) > 0:
		return "in costruzione (ancora %d anni)" % int(l["cantiere"])
	if bool(l["riposo"]):
		return "a riposo: il bosco ricresce"
	if _bosco_vicino_legnaia(l) < 0.0:
		return "esaurita: entro %d m non ci sono più alberi" % roundi(RAGGIO_LEGNAIA)
	if not legnaia_attiva(l):
		return "ferma da %d anni: la zona di taglio ricresce" % (anno - int(l["ultimo"]))
	return "al lavoro, zona di taglio di %d m" % roundi(float(l["raggio"]))


## Un anno di lavoro delle legnaie (26/11/2026 sera): la legna da ardere si raccoglie senza abbattere;
## poi i boscaioli tagliano gli alberi uno alla volta, dal più vicino, per rifare le case e tenere da
## parte il legname per costruire, fino alle braccia e a quanto riescono a portare.
func _lavora_legnaie() -> void:
	_insieme_campi = {}
	for i in campi:
		_insieme_campi[i] = true
	_campi_fermi = true
	_lavora_legnaie_dentro()
	_campi_fermi = false


func _lavora_legnaie_dentro() -> void:
	_controlla_puntatori()
	tagli_anno = []
	raccolta_legna = 0.0
	tronchi_legna = 0.0
	capacita_taglio = 0.0
	var capacita: Array[float] = []
	for l in legnaie:
		if int(l["cantiere"]) > 0:
			l["cantiere"] = int(l["cantiere"]) - 1
			if int(l["cantiere"]) == 0:
				_scrivi("La legnaia è pronta: i boscaioli raccolgono legna e cominciano a tagliare gli alberi vicini.", "buono")
		var c := capacita_legnaia(l)
		capacita.append(c)
		capacita_taglio += c
	offerta_raccolta = _offerta_raccolta()
	offerta_legna = offerta_raccolta + capacita_taglio
	var braccia := pop * BRACCIA_LEGNA
	var spazio := maxf(0.0, massimo_legna() - legna)
	# Prima i tronchi per rifare le case e tenere da parte il legname; poi la legna da ardere.
	var manutenzione := case.size() * COSTO_CASA / float(ANNI_VITA_CASA)
	var voluti := manutenzione + maxf(0.0, RISERVA_LEGNAME - legna) * 0.3
	voluti = clampf(voluti, 0.0, minf(capacita_taglio, braccia * 0.5))
	raccolta_legna = clampf(minf(offerta_raccolta, consumo_focolari + spazio), 0.0, braccia - voluti)
	if voluti > 0.0:
		for k in legnaie.size():
			var l: Dictionary = legnaie[k]
			if capacita[k] <= 0.0:
				continue
			l["debito"] = float(l["debito"]) + voluti * capacita[k] / capacita_taglio
			var celle: Array = l["celle"]
			for j in range(_primo_in_piedi(l), celle.size()):
				var voce: Array = celle[j]
				if float(l["debito"]) <= 0.0:
					break
				var c: Vector2i = voce[1]
				if not cella_in_piedi(c):
					continue
				_taglia_cella(l, c, float(voce[0]))
				l["debito"] = float(l["debito"]) - float(voce[2])
				tronchi_legna += float(voce[2])
			# Il debito non si porta avanti oltre una cella: se il bosco è finito, si azzera.
			l["debito"] = clampf(float(l["debito"]), -5.0, 5.0)
	ultima_legna = raccolta_legna + tronchi_legna
	_aggiorna_zone_taglio()
	if not tagli_anno.is_empty():
		_anni_risorse = mini(_anni_risorse, 1)


## Taglia gli alberi di una cella: la cella resta aperta finché la legnaia lavora; quando metà delle
## celle di un pixel sono tagliate, il pixel conta come abbattuto (caccia, mappe, raccolta).
func _taglia_cella(l: Dictionary, c: Vector2i, d: float) -> void:
	celle_tagliate[c] = anno
	(l["fatte"] as Dictionary)[c] = true
	tagli_anno.append(c)
	l["raggio"] = maxf(float(l["raggio"]), d)
	l["ultimo"] = anno
	var w := (Vector2(c) + Vector2(0.5, 0.5)) * LATO_CELLA_TAGLIO
	var i := px(px_da_mondo(w.x, w.y))
	_tagli_px[i] = int(_tagli_px.get(i, 0)) + 1
	if int(_tagli_px[i]) * 2 >= maxi(int(_celle_px.get(i, 1)), 1) and not tagliati.has(i):
		tagliati[i] = anno
		(l["pixel"] as Dictionary)[i] = true


# ---------- capanni da pesca e poste di caccia ----------

## Pendenza attorno a un punto (metri di dislivello su 12 m, nelle due direzioni).
func _pendenza(p: Vector2) -> float:
	return absf(dati.quota(p.x + 6.0, p.y) - dati.quota(p.x - 6.0, p.y)) + absf(dati.quota(p.x, p.y + 6.0) - dati.quota(p.x, p.y - 6.0))


## Dove andrebbe un capanno con il puntatore in `puntatore` (decisione di Fede del 25/11/2026): la
## terra asciutta a circa 2 m dall'acqua più vicina, entro AGGANCIO_RIVA metri, fuori dalla palude e
## poco inclinata, girata verso l'acqua. Restituisce {punto, verso, acqua, motivo}; motivo vuoto se
## si può costruire (il punto c'è anche quando c'è un motivo, se la riva è stata trovata).
func posa_capanno(puntatore: Vector2) -> Dictionary:
	if not fondato:
		return {"motivo": "Prima bisogna fondare il villaggio."}
	var migliore := Vector2.INF
	var costo := INF
	var r := int(AGGANCIO_RIVA / 2.0) + 2
	for gz in range(-r, r + 1):
		for gx in range(-r, r + 1):
			var p := puntatore + Vector2(gx, gz) * 2.0
			var d := p.distance_to(puntatore)
			if d > AGGANCIO_RIVA + 2.0:
				continue
			if absf(dati.distanza_riva(p.x, p.y) - 2.0) > 1.5 or dati.palude_in(p.x, p.y) > 0.4:
				continue
			var c := d + _pendenza(p) * 40.0
			if c < costo:
				costo = c
				migliore = p
	if migliore == Vector2.INF:
		return {"motivo": "Serve la riva di un fiume o di un torrente."}
	var h := 4.0
	var verso := -Vector2(dati.distanza_riva(migliore.x + h, migliore.y) - dati.distanza_riva(migliore.x - h, migliore.y),
		dati.distanza_riva(migliore.x, migliore.y + h) - dati.distanza_riva(migliore.x, migliore.y - h)).normalized()
	# Il tipo d'acqua: il fiume se c'è, altrimenti il torrente, nei punti della mappa attorno alla riva.
	var acqua := ""
	var q := px_da_mondo(migliore.x, migliore.y)
	for raggio in [1, 2]:
		for dy in range(-raggio, raggio + 1):
			for dx in range(-raggio, raggio + 1):
				var k := q + Vector2i(dx, dy)
				if k.x < 0 or k.y < 0 or k.x >= n or k.y >= n:
					continue
				var t := dati.tipo[px(k)]
				if t == MappaDati.FIUME:
					acqua = "fiume"
				elif acqua == "" and (t == MappaDati.TORRENTE or t == MappaDati.TORRENTE_EST):
					acqua = "torrente"
		if acqua != "":
			break
	var esito := {"punto": migliore, "verso": verso, "acqua": acqua if acqua != "" else "torrente", "motivo": ""}
	esito["motivo"] = _motivo_edificio(migliore, capanni, "C'è già un capanno qui.")
	return esito


## Dove andrebbe una posta con il puntatore in `puntatore`: appena fuori dal bosco (il margine è
## 0,5), entro AGGANCIO_MARGINE metri, asciutta, poco inclinata, con il bosco ancora in piedi alle
## spalle; girata con la schiena al bosco. Stesso formato di posa_capanno.
func posa_posta(puntatore: Vector2) -> Dictionary:
	if not fondato:
		return {"motivo": "Prima bisogna fondare il villaggio."}
	var migliore := Vector2.INF
	var verso_migliore := Vector2.ZERO
	var costo := INF
	var r := int(AGGANCIO_MARGINE / 3.0) + 1
	var h := 8.0
	for gz in range(-r, r + 1):
		for gx in range(-r, r + 1):
			var p := puntatore + Vector2(gx, gz) * 3.0
			var d := p.distance_to(puntatore)
			if d > AGGANCIO_MARGINE + 3.0:
				continue
			if absf(dati.bosco_in(p.x, p.y) - 0.4) > 0.04 or dati.palude_in(p.x, p.y) > 0.4 or dati.distanza_riva(p.x, p.y) < 20.0:
				continue
			var i := px(px_da_mondo(p.x, p.y))
			if not edificabile(i) or campi.has(i) or sentieri.has(i):
				continue
			var v := Vector2(dati.bosco_in(p.x + h, p.y) - dati.bosco_in(p.x - h, p.y), dati.bosco_in(p.x, p.y + h) - dati.bosco_in(p.x, p.y - h)).normalized()
			# Alle spalle il bosco deve essere ancora in piedi (le legnaie e i campi lo tolgono).
			var dietro := v * 40.0 + p
			if not bosco_in_piedi(px(px_da_mondo(dietro.x, dietro.y))):
				continue
			var c := d + _pendenza(p) * 40.0
			if c < costo:
				costo = c
				migliore = p
				verso_migliore = v
	if migliore == Vector2.INF:
		return {"motivo": "Serve il margine di un bosco, entro %d m." % roundi(AGGANCIO_MARGINE)}
	return {"punto": migliore, "verso": verso_migliore, "motivo": _motivo_edificio(migliore, poste, "C'è già una posta qui.")}


func _motivo_edificio(punto: Vector2, elenco: Array, gia: String) -> String:
	if punto.distance_to(mondo_di_px(centro)) > DISTANZA_MASSIMA_RISORSE:
		return "Troppo lontano dal villaggio: va entro %d m dal centro." % roundi(DISTANZA_MASSIMA_RISORSE)
	for e in elenco:
		if (e["punto"] as Vector2).distance_to(punto) < 8.0:
			return gia
	return ""


func costruisci_capanno(puntatore: Vector2) -> String:
	var posa := posa_capanno(puntatore)
	if posa["motivo"] != "":
		return posa["motivo"]
	if legna < COSTO_EDIFICIO_RISORSE:
		return "Servono %d di legna per il capanno (ora %d)." % [roundi(COSTO_EDIFICIO_RISORSE), floori(legna)]
	legna -= COSTO_EDIFICIO_RISORSE
	capanni.append({"punto": posa["punto"], "verso": posa["verso"], "acqua": posa["acqua"], "cantiere": ANNI_CANTIERE_RISORSE, "preso": 0.0, "offerta": 0.0})
	_scrivi("Si comincia a costruire un capanno da pesca sulla riva del %s." % posa["acqua"])
	_dopo_edificio_risorse(posa["punto"])
	return ""


func costruisci_posta(puntatore: Vector2) -> String:
	var posa := posa_posta(puntatore)
	if posa["motivo"] != "":
		return posa["motivo"]
	if legna < COSTO_EDIFICIO_RISORSE:
		return "Servono %d di legna per la posta (ora %d)." % [roundi(COSTO_EDIFICIO_RISORSE), floori(legna)]
	legna -= COSTO_EDIFICIO_RISORSE
	poste.append({"punto": posa["punto"], "verso": posa["verso"], "cantiere": ANNI_CANTIERE_RISORSE, "preso": 0.0, "offerta": 0.0})
	_scrivi("Si comincia a costruire una posta di caccia al margine del bosco.")
	_dopo_edificio_risorse(posa["punto"])
	return ""


## Un edificio nuovo: le case non gli nascono sopra e i riquadri attorno si contano subito.
func _dopo_edificio_risorse(punto: Vector2) -> void:
	var l := lotto_da_mondo(punto.x, punto.y)
	case = case.filter(func(c: Vector2i) -> bool: return cheb(c, l) > 0)
	_conta_riquadri()
	disponi_case()


func _avanza_cantieri_risorse() -> void:
	for e in poste + capanni:
		if int(e["cantiere"]) > 0:
			e["cantiere"] = int(e["cantiere"]) - 1
			if int(e["cantiere"]) == 0:
				_scrivi("Il capanno da pesca è pronto." if e.has("acqua") else "La posta di caccia è pronta.", "buono")


## L'edificio (posta o capanno) più vicino al punto, entro `entro` metri (-1 se nessuno).
func edificio_vicino(elenco: Array, punto: Vector2, entro := 30.0) -> int:
	var k_migliore := -1
	var d_migliore := entro
	for k in elenco.size():
		var d := (elenco[k]["punto"] as Vector2).distance_to(punto)
		if d <= d_migliore:
			d_migliore = d
			k_migliore = k
	return k_migliore


## Stato di una posta o di un capanno per il giocatore.
func stato_edificio(e: Dictionary) -> String:
	if int(e["cantiere"]) > 0:
		return "in costruzione (ancora %d anni)" % int(e["cantiere"])
	if scorta_attorno(e) < 0.4:
		return "pesce scarso in questo tratto" if e.has("acqua") else "selvaggina scarsa qui"
	return "al lavoro" if not e.has("acqua") else "al lavoro sul " + String(e["acqua"])


## Scorta media (0–1) attorno a un edificio, pesata con la vicinanza.
func scorta_attorno(e: Dictionary) -> float:
	var caccia := not e.has("acqua")
	var celle: Dictionary = celle_bosco if caccia else celle_acqua
	var scorta: Dictionary = scorta_selvaggina if caccia else scorta_pesce
	var raggio := RAGGIO_POSTA if caccia else RAGGIO_CAPANNO
	var somma := 0.0
	var pesi := 0.0
	for c in celle:
		var w := 1.0 - centro_riquadro(c).distance_to(e["punto"]) / raggio
		if w > 0.0 and float(celle[c]) > 0.0:
			somma += w * float(celle[c]) * float(scorta.get(c, 1.0))
			pesi += w * float(celle[c])
	return somma / pesi if pesi > 0.0 else 0.0


func riquadro_di(p: Vector2i) -> Vector2i:
	return Vector2i(p.x / BLOCCO_RISORSE, p.y / BLOCCO_RISORSE)


func centro_riquadro(c: Vector2i) -> Vector2:
	return (Vector2(c * BLOCCO_RISORSE) + Vector2.ONE * (BLOCCO_RISORSE - 1) * 0.5) * dati.metri_per_px


## Raggio in metri entro cui le famiglie cacciano e pescano attorno al villaggio.
func raggio_famiglie() -> float:
	return RAGGIO_RISORSE * dati.metri_per_px


## Conta bosco in piedi e acqua nei riquadri che servono: attorno al villaggio e agli edifici.
func _conta_riquadri() -> void:
	celle_bosco = {}
	celle_acqua = {}
	if not fondato:
		return
	var coltivati := {}
	for c in campi:
		coltivati[c] = true
	var fonti_risorse: Array = [[mondo_di_px(centro), raggio_famiglie()]]
	for e in poste:
		fonti_risorse.append([e["punto"], RAGGIO_POSTA])
	for e in capanni:
		fonti_risorse.append([e["punto"], RAGGIO_CAPANNO])
	var lato := BLOCCO_RISORSE * dati.metri_per_px
	var nb := ceili(float(n) / BLOCCO_RISORSE)
	for f in fonti_risorse:
		var pr: Vector2 = f[0]
		var r: float = f[1]
		var a := Vector2i(clampi(floori((pr.x - r) / lato), 0, nb - 1), clampi(floori((pr.y - r) / lato), 0, nb - 1))
		var b := Vector2i(clampi(floori((pr.x + r) / lato) + 1, 0, nb - 1), clampi(floori((pr.y + r) / lato) + 1, 0, nb - 1))
		for cy in range(a.y, b.y + 1):
			for cx in range(a.x, b.x + 1):
				var c := Vector2i(cx, cy)
				if celle_bosco.has(c) or centro_riquadro(c).distance_to(pr) > r:
					continue
				var conta := _conta_riquadro(c, coltivati)
				celle_bosco[c] = conta.x
				celle_acqua[c] = conta.y


## Bosco in piedi (x) e acqua pesata per tipo (y) in un riquadro.
func _conta_riquadro(c: Vector2i, coltivati: Dictionary) -> Vector2:
	var bosco := 0.0
	var acqua := 0.0
	for y in range(c.y * BLOCCO_RISORSE, mini((c.y + 1) * BLOCCO_RISORSE, n)):
		for x in range(c.x * BLOCCO_RISORSE, mini((c.x + 1) * BLOCCO_RISORSE, n)):
			var j := y * n + x
			var t := dati.tipo[j]
			if t == MappaDati.FIUME:
				acqua += 1.0
			elif t == MappaDati.TORRENTE or t == MappaDati.TORRENTE_EST:
				acqua += 0.6
			elif t == MappaDati.PALUDE:
				acqua += 0.5
				bosco += 0.3
			elif not coltivati.has(j) and bosco_in_piedi(j):
				bosco += 1.0
	return Vector2(bosco, acqua)


## Stima per un edificio che si potrebbe costruire (lettura sotto il puntatore): resa possibile
## l'anno, già divisa con gli edifici vicini; scorta attorno (0–1); quanto è ricca la risorsa
## attorno (0–1, per il bosco la quota di terra boscosa); quanti edifici uguali sono vicini.
func stima_edificio(e: Dictionary) -> Dictionary:
	var caccia := not e.has("acqua")
	var scorta: Dictionary = scorta_selvaggina if caccia else scorta_pesce
	var resa := RESA_BOSCO if caccia else RESA_ACQUA
	var raggio := RAGGIO_POSTA if caccia else RAGGIO_CAPANNO
	var elenco: Array = poste if caccia else capanni
	var punto: Vector2 = e["punto"]
	var coltivati := {}
	for c in campi:
		coltivati[c] = true
	var lato := BLOCCO_RISORSE * dati.metri_per_px
	var nb := ceili(float(n) / BLOCCO_RISORSE)
	var a := Vector2i(clampi(floori((punto.x - raggio) / lato), 0, nb - 1), clampi(floori((punto.y - raggio) / lato), 0, nb - 1))
	var b := Vector2i(clampi(floori((punto.x + raggio) / lato) + 1, 0, nb - 1), clampi(floori((punto.y + raggio) / lato) + 1, 0, nb - 1))
	var disponibile := 0.0
	var somma_scorta := 0.0
	var pesi := 0.0
	var ricchezza := 0.0
	var pesi_tutti := 0.0
	for cy in range(a.y, b.y + 1):
		for cx in range(a.x, b.x + 1):
			var c := Vector2i(cx, cy)
			var cc := centro_riquadro(c)
			var w := 1.0 - cc.distance_to(punto) / raggio
			if w <= 0.0:
				continue
			var quanto: float
			if celle_bosco.has(c):
				quanto = float(celle_bosco[c] if caccia else celle_acqua[c])
			else:
				var conta := _conta_riquadro(c, coltivati)
				quanto = conta.x if caccia else conta.y
			ricchezza += w * quanto / float(BLOCCO_RISORSE * BLOCCO_RISORSE)
			pesi_tutti += w
			if quanto <= 0.0:
				continue
			var pressione := w
			for altro in elenco:
				if int(altro["cantiere"]) <= 0:
					pressione += maxf(0.0, 1.0 - cc.distance_to(altro["punto"]) / raggio)
			var s := float(scorta.get(c, 1.0))
			disponibile += quanto * resa * s * w / maxf(1.0, pressione)
			somma_scorta += w * quanto * s
			pesi += w * quanto
	var vicini := 0
	for altro in elenco:
		if (altro["punto"] as Vector2).distance_to(punto) < raggio:
			vicini += 1
	return {"resa": minf(disponibile, CAPACITA_POSTA if caccia else CAPACITA_CAPANNO),
		"scorta": somma_scorta / pesi if pesi > 0.0 else 0.0,
		"risorsa": clampf(ricchezza / maxf(pesi_tutti, 0.001), 0.0, 1.0), "vicini": vicini}


## Boschi e acque attorno al villaggio, pesati con la vicinanza (1 al centro, 0 a 1,6 km), dai
## riquadri: servono al disboscamento.
func _risorse_dai_riquadri() -> Dictionary:
	var c0 := mondo_di_px(centro)
	var rc := raggio_famiglie()
	var bosco := 0.0
	var acqua := 0.0
	for c in celle_bosco:
		var w := 1.0 - centro_riquadro(c).distance_to(c0) / rc
		if w > 0.0:
			bosco += w * float(celle_bosco[c])
			acqua += w * float(celle_acqua[c])
	return {"bosco": bosco, "acqua": acqua}


func _riprendi_scorte(scorta: Dictionary, ripresa: float) -> void:
	for c in scorta.keys():
		var s: float = scorta[c] + (1.0 - scorta[c]) * ripresa
		if s >= 0.995:
			scorta.erase(c)
		else:
			scorta[c] = s


## Un anno di caccia (o di pesca). Prima lavorano poste e capanni finiti, che rendono pieno: ognuno
## prende dai riquadri attorno, pesati con la vicinanza, fino alla sua capacità; dove gli edifici si
## sovrappongono la scorta si divide. Poi le famiglie cacciano o pescano attorno al villaggio con
## ciò che resta, rendendo un terzo. Il preso fa calare le scorte dei riquadri. Restituisce
## [preso, offerta].
func _caccia_o_pesca(caccia: bool, domanda: float) -> Array:
	var celle: Dictionary = celle_bosco if caccia else celle_acqua
	var scorta: Dictionary = scorta_selvaggina if caccia else scorta_pesce
	var resa := RESA_BOSCO if caccia else RESA_ACQUA
	var raggio := RAGGIO_POSTA if caccia else RAGGIO_CAPANNO
	var capacita := CAPACITA_POSTA if caccia else CAPACITA_CAPANNO
	var edifici: Array = poste if caccia else capanni
	var offerta := {}
	for c in celle:
		offerta[c] = float(celle[c]) * resa * float(scorta.get(c, 1.0))
	# Pesi degli edifici sui riquadri e pressione (somma dei pesi) per dividere la scorta.
	var pesi: Array = []
	var pressione := {}
	for e in edifici:
		var pw := {}
		if int(e["cantiere"]) <= 0:
			for c in celle:
				var w := 1.0 - centro_riquadro(c).distance_to(e["punto"]) / raggio
				if w > 0.0 and float(celle[c]) > 0.0:
					pw[c] = w
					pressione[c] = float(pressione.get(c, 0.0)) + w
		pesi.append(pw)
	var disponibile: Array[float] = []
	var dagli_edifici := 0.0
	for k in edifici.size():
		var a := 0.0
		for c in pesi[k]:
			a += float(offerta[c]) * float(pesi[k][c]) / maxf(1.0, float(pressione[c]))
		disponibile.append(a)
		edifici[k]["offerta"] = minf(a, capacita)
		dagli_edifici += minf(a, capacita)
	var quota := minf(1.0, domanda / dagli_edifici) if dagli_edifici > 0.0 else 0.0
	var presi := {}
	var preso := 0.0
	for k in edifici.size():
		edifici[k]["preso"] = float(edifici[k]["offerta"]) * quota
		preso += float(edifici[k]["preso"])
		if disponibile[k] <= 0.0:
			continue
		var f := float(edifici[k]["preso"]) / disponibile[k]
		for c in pesi[k]:
			presi[c] = float(presi.get(c, 0.0)) + float(offerta[c]) * float(pesi[k][c]) / maxf(1.0, float(pressione[c])) * f
	# Le famiglie attorno al villaggio, con ciò che resta.
	var c0 := mondo_di_px(centro)
	var rc := raggio_famiglie()
	var dalle_famiglie := {}
	var disp_famiglie := 0.0
	for c in celle:
		var w := 1.0 - centro_riquadro(c).distance_to(c0) / rc
		if w <= 0.0:
			continue
		var v := maxf(0.0, float(offerta[c]) - float(presi.get(c, 0.0))) * w * RESA_SENZA_EDIFICIO
		if v > 0.0:
			dalle_famiglie[c] = v
			disp_famiglie += v
	var resto := clampf(domanda - preso, 0.0, disp_famiglie)
	if resto > 0.0:
		for c in dalle_famiglie:
			presi[c] = float(presi.get(c, 0.0)) + float(dalle_famiglie[c]) * resto / disp_famiglie
		preso += resto
	# Le scorte calano con ciò che si prende (come prima per la selvaggina del villaggio).
	for c in presi:
		var portata := float(celle[c]) * resa
		scorta[c] = clampf(float(scorta.get(c, 1.0)) - float(presi[c]) / maxf(portata * 8.0, 0.5), 0.05, 1.0)
	return [preso, dagli_edifici + disp_famiglie]


## Selvaggina del villaggio (0–1): la scorta media dei boschi dove si caccia, pesata con il bosco e
## con quanto ci si caccia (attorno al villaggio e alle poste). La selvaggina vicina rovina i campi.
func _selvaggina_media() -> float:
	var c0 := mondo_di_px(centro)
	var rc := raggio_famiglie()
	var somma := 0.0
	var pesi := 0.0
	for c in celle_bosco:
		var cc := centro_riquadro(c)
		var w := maxf(0.0, 1.0 - cc.distance_to(c0) / rc)
		for e in poste:
			w += maxf(0.0, 1.0 - cc.distance_to(e["punto"]) / RAGGIO_POSTA)
		var b := float(celle_bosco[c]) * w
		somma += b * float(scorta_selvaggina.get(c, 1.0))
		pesi += b
	return somma / pesi if pesi > 0.0 else 1.0


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
	if esito["sentieri"] > 0:
		_togli_strade_demolite()
	var n_legnaie := legnaie.size()
	for l in legnaie:
		if (l["punto"] as Vector2).distance_to(punto) <= raggio:
			for i in l["pixel"]:
				tagliati[i] = anno
			for c in l["fatte"]:
				celle_tagliate[c] = anno
	legnaie = legnaie.filter(func(l: Dictionary) -> bool: return (l["punto"] as Vector2).distance_to(punto) > raggio)
	_aggiorna_zone_taglio()
	esito["legnaie"] = n_legnaie - legnaie.size()
	if esito["legnaie"] > 0:
		_scrivi("Demolita la legnaia.")
	var fuori := func(e: Dictionary) -> bool: return (e["punto"] as Vector2).distance_to(punto) > raggio
	var n_poste := poste.size()
	poste = poste.filter(fuori)
	esito["poste"] = n_poste - poste.size()
	var n_capanni := capanni.size()
	capanni = capanni.filter(fuori)
	esito["capanni"] = n_capanni - capanni.size()
	if esito["poste"] > 0:
		_scrivi("Demolita la posta di caccia.")
	if esito["capanni"] > 0:
		_scrivi("Demolito il capanno da pesca.")
	if torre.x >= 0 and torre.distance_to(punto) <= raggio:
		torre = Vector2(-1, -1)
		cantiere_torre = 0
		esito["torre"] = true
		_scrivi("Demolita la torre di avvistamento.")
	if luogo_sacro.x >= 0 and luogo_sacro.distance_to(punto) <= raggio:
		luogo_sacro = Vector2(-1, -1)
		cantiere_luogo_sacro = 0
		esito["luogo_sacro"] = true
		_cambia_consenso("sacerdote", -30.0)
		_scrivi("Il luogo sacro è stato abbattuto: il sacerdote è furioso.", "allarme")
	var sacri_tagliati := 0
	for i in bosco_sacro.keys():
		if dentro.call(i):
			if bosco_in_piedi(i):
				sacri_tagliati += 1
			bosco_sacro.erase(i)
	esito["bosco_sacro"] = sacri_tagliati
	if sacri_tagliati > 0:
		_cambia_consenso("sacerdote", -minf(25.0, 3.0 * sacri_tagliati))
		_scrivi("Si è tagliato il bosco sacro: il sacerdote è offeso.", "allarme")
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
			elif bosco_in_piedi(j) and not coltivati.has(j):
				bosco += w
	return {"bosco": bosco, "acqua": acqua}


## Campi serviti (sentiero collegato entro 120 m o centro entro 200 m) e campi al margine del bosco.
## Vero mentre si scorrono tutti i campi senza cambiarli (resa, resa attesa): la firma dei campi
## serviti non si ricalcola a ogni campo (era il punto più lento della simulazione: un hash di tutti
## i campi per ogni campo, ogni anno).
var _serviti_fermi := false

func _aggiorna_campi_serviti() -> void:
	if _serviti_fermi:
		return
	var firma := hash([campi.hash(), sentieri.hash(), centro, _anni_risorse, pixel_strada.size()])
	if firma == _firma_serviti:
		return
	_firma_serviti = firma
	_campi_serviti = {}
	_campi_strada = {}
	if not pixel_strada.is_empty():
		# La fascia attorno alle strade si ricalcola solo quando cambiano le strade.
		var firma_s := pixel_strada.hash()
		if firma_s != _firma_fascia:
			_firma_fascia = firma_s
			_fascia_strade = {}
			var r := DISTANZA_CAMPI_STRADA
			for ip in pixel_strada:
				var ps := px_di(ip)
				for dy in range(-r, r + 1):
					for dx in range(-r, r + 1):
						var q := ps + Vector2i(dx, dy)
						if dx * dx + dy * dy <= r * r and q.x >= 0 and q.y >= 0 and q.x < n and q.y < n:
							_fascia_strade[px(q)] = true
		for i in campi:
			if _fascia_strade.has(i):
				_campi_strada[i] = true
	var collegati := sentieri_collegati()
	# La fascia di 120 m attorno ai sentieri collegati si ricalcola solo quando cambiano i sentieri
	# (prima si guardavano 49 punti per ogni campo ogni anno: troppo lento con mille campi).
	var firma_c := hash([sentieri.hash(), centro])
	if firma_c != _firma_fascia_sentieri:
		_firma_fascia_sentieri = firma_c
		_fascia_sentieri = {}
		for ic in collegati:
			var pc := px_di(ic)
			for dy in range(-3, 4):
				for dx in range(-3, 4):
					if dx * dx + dy * dy <= 9:
						_fascia_sentieri[px(pc + Vector2i(dx, dy))] = true
	for i in campi:
		var p := px_di(i)
		if mondo_di_px(p).distance_to(mondo_di_px(centro)) <= 200.0 or _fascia_sentieri.has(i):
			_campi_serviti[i] = true
	_campi_al_bosco = {}
	# Campi al margine del bosco (bosco entro 2 punti): il bosco del riquadro che contiene i campi si
	# legge una volta sola e si somma in una tabella cumulata, così ogni campo chiede la sua finestra
	# 5 × 5 con quattro letture (stesso risultato di prima; prima erano 25 letture del bosco per campo).
	if not campi.is_empty():
		var a := Vector2i(n, n)
		var b := Vector2i(-1, -1)
		for i in campi:
			var p := px_di(i)
			a = Vector2i(mini(a.x, p.x), mini(a.y, p.y))
			b = Vector2i(maxi(b.x, p.x), maxi(b.y, p.y))
		a = Vector2i(maxi(a.x - 2, 0), maxi(a.y - 2, 0))
		b = Vector2i(mini(b.x + 2, n - 1), mini(b.y + 2, n - 1))
		var w := b.x - a.x + 1
		var h := b.y - a.y + 1
		var somme := PackedInt32Array()
		somme.resize((w + 1) * (h + 1))
		for y in h:
			var riga := 0
			for x in w:
				if bosco_presente.call((a.y + y) * n + a.x + x):
					riga += 1
				somme[(y + 1) * (w + 1) + x + 1] = somme[y * (w + 1) + x + 1] + riga
		for i in campi:
			var p := px_di(i) - a
			var x0 := maxi(p.x - 2, 0)
			var y0 := maxi(p.y - 2, 0)
			var x1 := mini(p.x + 2, w - 1) + 1
			var y1 := mini(p.y + 2, h - 1) + 1
			if somme[y1 * (w + 1) + x1] - somme[y0 * (w + 1) + x1] - somme[y1 * (w + 1) + x0] + somme[y0 * (w + 1) + x0] > 0:
				_campi_al_bosco[i] = true


func servito(i: int) -> bool:
	_aggiorna_campi_serviti()
	return _campi_serviti.has(i)


## Abitanti per ettaro nell'abitato (il cerchio che contiene le case).
func densita() -> float:
	if case_nel_nucleo().is_empty():
		return 0.0
	var r := raggio_case()
	return abitanti_nucleo() / (PI * r * r / 10000.0)


## Raggio in metri del cerchio che contiene le case del nucleo (l'abitato).
func raggio_case() -> float:
	var c := mondo_di_px(centro)
	var r := 10.0
	for l in case_nel_nucleo():
		r = maxf(r, centro_lotto(l).distance_to(c) + LOTTO * 0.5)
	return r


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
	# La politica sul pericolo e la torre si aprono con i primi segni di una scorreria.
	if cosa in ["pericolo", "torre"]:
		return gia_segni
	return tappa >= tappa_di(cosa)


## Il granaio funziona (costruito e finito).
func granaio_pronto() -> bool:
	return granaio.x >= 0 and cantiere_granaio <= 0


func _aggiorna_tappa() -> void:
	while tappa + 1 < TAPPE.size() and pop >= TAPPE[tappa + 1]["abitanti"]:
		tappa += 1
		var t: Dictionary = TAPPE[tappa]
		var nomi := {"granaio": "il granaio", "raccolto": "la divisione del raccolto", "luogo_sacro": "il luogo sacro",
			"pascolo": "il pascolo", "stranieri": "la regola sugli stranieri", "affollati": "la regola per il villaggio affollato", "bosco_sacro": "il bosco sacro",
			"casali": "i casali nel contado", "strade": "le strade"}
		var aperti: Array[String] = []
		for a in t["apre"]:
			aperti.append(nomi.get(a, a))
		# Elenco in italiano: "a, b e c".
		var elenco := aperti[-1] if aperti.size() < 2 else ", ".join(aperti.slice(0, -1)) + " e " + aperti[-1]
		_scrivi("Nuova tappa: %s. Compaiono %s." % [String(t["nome"]).to_lower(), elenco], "buono")
		# Il sacerdote ha voce dalla tappa del luogo sacro, ed è contrariato finché non c'è; lo
		# chiede quando se ne sblocca la costruzione (Fede, 26/11/2026: nel tutorial della tappa).
		if "luogo_sacro" in t["apre"] and not sacerdote_attivo:
			sacerdote_attivo = true
			consenso["sacerdote"] = 45.0
			_scrivi("Il sacerdote chiede un luogo sacro: finché non sarà eretto, è contrariato.")
		_notifica("Nuova tappa: %s. Compaiono %s." % [t["nome"], elenco], false, mondo_di_px(centro))
		# Tutorial della tappa (Fede, 26/11/2026): il gioco si ferma e spiega le novità.
		# Alla tappa dei 60 abitanti anche lo specchietto dei rapporti di forza (Fede, 26/11/2026):
		# da qui le famiglie cominciano a contare.
		var schede: Array = t["apre"].duplicate()
		if "raccolto" in t["apre"]:
			schede.append("rapporti")
		tutorial(schede, "%s (%d abitanti)" % [t["nome"], t["abitanti"]])


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
		"pericolo:avanti":
			_scrivi("Gli anziani decidono: ai segni di pericolo si va avanti come sempre.")
		"pericolo:raccogliere":
			_scrivi("Gli anziani decidono: ai segni di pericolo animali e scorte si raccolgono vicino alle case.")
		"pericolo:vegliare":
			_scrivi("Gli anziani decidono: ai segni di pericolo gli uomini vegliano ai margini.")
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
	_case_stranieri_da_fare = ceili(n_persone / ABITANTI_PER_CASA)
	_anno_stranieri = anno
	if sbloccato("pascolo"):
		capi += n_persone * CAPI_PER_STRANIERO
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
		"tutorial":
			if o == "salta":
				salta_tutorial()
		"soglia":
			_transizione(o)
		"sorgenti":
			presagio_vero["scelta"] = o
			if o == "razionare":
				razionamento = 3
				_cambia_consenso("famiglie", -3.0)
				_cambia_consenso("sacerdote", 3.0)
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
		"pericolo":
			if _pericolo_prima:
				_pericolo_prima = false
				politiche["pericolo"] = o
			_reagisci_ai_segni()
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
	elif rng.randf() < PROB_PIENA_DISASTROSA * (1.0 + 3.0 * maxf(disboscamento, 0.5 * pascolo_eccessivo)):
		piena_tra = 1 + rng.randi() % 2
		if _esposto_alle_piene():
			_scrivi("Piove da settimane sui colli: i corsi d'acqua sono torbidi e gonfi.")
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
			siccita_grave = false
			_scrivi("Tornano le piogge. Le sorgenti si riempiono.", "buono")
	if siccita_tra > 0:
		siccita_tra -= 1
		if siccita_tra == 0:
			_inizia_siccita()
			siccita_tra = -1
	# Presagi: al massimo uno ogni secolo circa; sono le sole scelte che fermano il gioco ogni volta.
	# A decenni più radi, con il sacerdote scontento più fitti (Fede, 26/11/2026; `ritmo_presagi`).
	var ritmo := ritmo_presagi()
	var presagio_possibile := anno - _ultimo_presagio >= int(ritmo[0]) and anno > ANNO_INIZIO + 20 \
		and siccita == 0 and siccita_tra < 0 and cometa.is_empty() and presagio_vero.is_empty()
	if presagio_possibile and rng.randf() < float(ritmo[1]):
		_ultimo_presagio = anno
		stat["presagi_totali"] += 1
		if rng.randf() >= quota_presagi_falsi():
			siccita_tra = 2 + rng.randi() % 2
			sorgenti_basse = true
			presagio_vero = {"scelta": ""}
			_decidi("sorgenti", "Le sorgenti calano", _testo_sorgenti(),
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
	# Gli stranieri arrivano dalla tappa che apre la loro politica (Fede, 26/11/2026: il primo arrivo
	# era venuto prima della politica).
	if anno > ANNO_INIZIO + 10 and sbloccato("stranieri") and not in_attesa() and rng_stranieri.randf() < PROB_STRANIERI * abbondanza:
		_arrivo_stranieri()
	_scorrerie()
	_soglia()
	if anni_sapere > 0:
		anni_sapere -= 1
	if ammodernamenti["agricolo"]:
		_ammoderna()
	_dissoda_zona()
	if cantiere_granaio > 0:
		cantiere_granaio -= 1
		if cantiere_granaio == 0:
			_scrivi("Il granaio è finito: le scorte si conservano meglio.", "buono")
	if cantiere_luogo_sacro > 0:
		cantiere_luogo_sacro -= 1
		if cantiere_luogo_sacro == 0:
			_scrivi("Il luogo sacro è finito: il sacerdote è soddisfatto.", "buono")
	if cantiere_torre > 0:
		cantiere_torre -= 1
		if cantiere_torre == 0:
			_scrivi("La torre di avvistamento è finita: dall'alto si vedono i margini del contado.", "buono")
	# Raccolto: le braccia lavorano prima i campi più fertili. Famiglie contente lavorano di più
	# (decisione di Fede del 25/11/2026); un cantiere aperto toglie un po' di braccia.
	var in_cantiere := func(e: Dictionary) -> bool: return int(e["cantiere"]) > 0
	var cantieri := (1 if cantiere_granaio > 0 else 0) + (1 if cantiere_luogo_sacro > 0 else 0) + (1 if cantiere_torre > 0 else 0) + legnaie.filter(in_cantiere).size() + poste.filter(in_cantiere).size() + capanni.filter(in_cantiere).size()
	var lavoro: float = (0.9 + 0.2 * consenso["famiglie"] / 100.0) * (1.0 - 0.05 * mini(cantieri, 3))
	# Ai segni di pericolo, con la veglia ai margini, un po' di braccia lascia i campi.
	if in_allerta() and politica("pericolo") == "vegliare":
		lavoro *= 1.0 - 0.08 * efficacia_usanze()
	var braccia: float = pop * 0.55 * lavoro * (1.0 + (0.0 if fonti["caccia"] else 0.2) + (0.0 if fonti["pesca"] else 0.1))
	var lavorabili := int(braccia / 3.0 * AREA_CELLA) if fonti["agricoltura"] else 0
	var ordinati := campi.duplicate()
	# Si lavorano prima i campi che rendono di più: quelli stanchi restano incolti e si riposano.
	# (Il valore di ogni campo si calcola una volta sola prima di ordinare: stesso ordine di prima.)
	var valore := {}
	for i in ordinati:
		valore[i] = fert(i) * fattore_stanchezza(i)
	ordinati.sort_custom(func(a: int, b: int) -> bool: return valore[a] > valore[b])
	var raccolto := 0.0
	raccolto_potenziale = 0.0
	var lavorati := {}
	_aggiorna_campi_serviti()
	_serviti_fermi = true
	for k in ordinati.size():
		var i: int = ordinati[k]
		var r := _resa(i)
		raccolto_potenziale += r
		if k < lavorabili:
			raccolto += r
			lavorati[i] = true
			stanchezza[i] = float(stanchezza.get(i, 0.0)) + 1.0
		elif stanchezza.has(i):
			stanchezza[i] = float(stanchezza[i]) - RIPOSO_PER_ANNO
			if stanchezza[i] <= 0.0:
				stanchezza.erase(i)
	_serviti_fermi = false
	ultimo_raccolto = raccolto
	ultimi_lavorati = mini(lavorabili, ordinati.size())
	_pascola(lavorati)
	var piu_braccia := 1.0 if fonti["agricoltura"] else 1.5
	# Caccia, raccolta e pesca (economia mista): la selvaggina cala se si caccia troppo e ricresce
	# lentamente; boschi e acque si ricontano ogni 5 anni (tagli e campi tolgono bosco).
	if _anni_risorse <= 0:
		_conta_riquadri()
		_risorse = _risorse_dai_riquadri()
		_anni_risorse = 5
		if bosco_iniziale > 0.0:
			disboscamento = clampf(1.0 - _risorse["bosco"] / bosco_iniziale, 0.0, 1.0)
	_anni_risorse -= 1
	# Le scorte lasciate stare si riprendono; poi lavorano poste e capanni (pieni), e le famiglie
	# cacciano e pescano attorno al villaggio con ciò che resta (un terzo).
	_avanza_cantieri_risorse()
	_riprendi_scorte(scorta_selvaggina, RIPRESA_SELVAGGINA)
	_riprendi_scorte(scorta_pesce, RIPRESA_PESCE)
	var esito_caccia := _caccia_o_pesca(true, pop * QUOTA_CACCIA * piu_braccia if fonti["caccia"] else 0.0)
	ultima_caccia = esito_caccia[0]
	# Animali e scorte raccolti vicino alle case: si caccia meno lontano finché dura il pericolo.
	if in_allerta() and politica("pericolo") == "raccogliere":
		ultima_caccia *= 1.0 - 0.3 * efficacia_usanze()
	offerta_caccia = esito_caccia[1]
	var esito_pesca := _caccia_o_pesca(false, pop * QUOTA_PESCA * piu_braccia if fonti["pesca"] else 0.0)
	ultima_pesca = esito_pesca[0]
	offerta_pesca = esito_pesca[1]
	selvaggina = _selvaggina_media()
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
	# Legna (decisione di Fede del 25/11/2026): la raccolgono le legnaie, abbattendo il bosco vicino;
	# serve ai focolari e a tenere in piedi le case.
	consumo_focolari = pop * CONSUMO_PERSONA
	consumo_legna = consumo_focolari + case.size() * COSTO_CASA / float(ANNI_VITA_CASA)
	_lavora_legnaie()
	legna = clampf(legna + ultima_legna - consumo_legna, 0.0, massimo_legna())
	_aggiorna_traffico()
	# Cibo. Le annate magre fanno parte del ciclo normale: si vedono solo nelle scorte, senza avvisi
	# (decisione di Fede del 25/11/2026). La carestia arriva quando le scorte finiscono.
	var consumo := pop * (0.8 if razionamento > 0 else 1.0)
	cibo += raccolto + ultima_caccia + ultima_pesca - consumo
	# Scorta viva: nelle annate cattive le famiglie macellano quanto serve, fino a metà della mandria.
	ultimi_macellati = 0
	if cibo < 0.0 and capi >= 1.0:
		ultimi_macellati = mini(floori(capi * 0.5), ceili(-cibo / CIBO_PER_CAPO))
		if ultimi_macellati > 0:
			capi -= ultimi_macellati
			cibo += ultimi_macellati * CIBO_PER_CAPO
			# Una riga ogni 5 anni al massimo (ritmo meditativo, decisione di Fede del 24/11/2026).
			if anno - _anno_macellazione >= 5:
				_scrivi("Annate cattive: si macellano gli animali per passare l'inverno (%d capi quest'anno)." % ultimi_macellati)
			_anno_macellazione = anno
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
		cibo *= 0.9 if granaio_pronto() else 0.7
	# Il primo cattivo raccolto: una notifica una volta, quando la fame è davvero vicina (dal
	# 25/11/2026 non ferma più il gioco; il pannello del cibo spiega cosa fare).
	if not gia_primo_cattivo and anno > ANNO_INIZIO + 2 and raccolto + ultima_caccia + ultima_pesca < consumo and cibo < consumo * 0.25:
		gia_primo_cattivo = true
		_scrivi("Il raccolto non basta e le scorte sono quasi finite: %d di cibo contro un bisogno di %d." % [roundi(raccolto + ultima_caccia + ultima_pesca), roundi(consumo)], "allarme")
		_notifica("Le scorte sono quasi finite: allarga la zona agricola o raziona (clic sul Cibo per capire).", true, mondo_di_px(centro))
	# Salute: acqua, paludi, affollamento, fame, focolari senza legna.
	var dm := _d_palude[px(centro)]
	var obiettivo := 72.0 + 15.0 * acqua_qualsiasi(px(centro)) - (25.0 if dm <= 3.0 else (10.0 if dm <= 6.0 else 0.0)) \
		- affollamento * 25.0 - (5.0 if razionamento > 0 else 0.0) - (8.0 if cibo < pop * 0.1 else 0.0) - (6.0 if legna <= 0.0 else 0.0)
	salute += (clampf(obiettivo, 5.0, 95.0) - salute) * 0.15
	# Febbri (decisione di Fede del 25/11/2026): estati di febbri vicino alle paludi e nelle case affollate.
	# In una città sana una febbre è solo una flessione; si scrive in cronaca solo se è grave.
	if rng.randf() < (0.05 if dm <= 3.0 else (0.025 if dm <= 6.0 else 0.0)) + affollamento * 0.05:
		var danno := 1.0 + 11.0 * (1.0 - salute / 100.0)
		salute -= danno
		stat["febbri"] += 1
		if danno >= 8.0:
			_scrivi("Un'estate di febbri gravi: molti si ammalano.", "allarme")
	salute = clampf(salute, 0.0, 100.0)
	# Popolazione: le nascite seguono l'abbondanza (decisione di Fede del 25/11/2026).
	_aggiorna_abbondanza()
	abbondanza_lenta += (abbondanza - abbondanza_lenta) / ANNI_NASCITE
	anni_deficit = anni_deficit + 1 if raccolto + ultima_caccia + ultima_pesca < consumo else 0
	if carestia == 0.0:
		pop *= 1.0 + CRESCITA_MASSIMA * (abbondanza_lenta - SOGLIA_CRESCITA) / (1.0 - SOGLIA_CRESCITA)
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
	_aggiorna_prestigio()
	# Villaggio affollato (dal 25/11/2026 una politica, non una pausa): quando mancano case per più
	# di un sesto delle famiglie, ogni dieci anni l'abitato si allarga oppure qualcuno emigra.
	if sbloccato("affollati") and affollamento > 0.15 and (anno - ANNO_INIZIO) % 10 == 0:
		if politica("affollati") == "allargare":
			if raggio_extra < 4 and legna >= COSTO_CASA:
				raggio_extra += 1
				_scrivi("Le case si stringono: l'abitato si allarga verso i campi.")
		else:
			var via := roundi(pop * affollamento * 0.8)
			if via >= 3:
				pop -= via
				_scrivi("%d persone partono in cerca di terra: al villaggio non c'è posto per tutti." % via)
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
	if pop < 6.0:
		_abbandona()
	for k in ["pop", "cibo", "salute", "legittimita", "abbondanza", "legna", "capi"]:
		var arr: Array = storia[k]
		arr.append(get(k))
		if arr.size() > 200:
			arr.pop_front()
	for g in storia_consenso:
		var arr_g: Array = storia_consenso[g]
		arr_g.append(consenso[g])
		if arr_g.size() > 30:
			arr_g.pop_front()
	anno += 1
	_aggiorna_decenni()
	if anno >= ANNO_FINE and not finito:
		_fine()


## Abbondanza (decisione di Fede del 25/11/2026): cibo che avanza (scorte in mesi), salute, spazio.
func _aggiorna_abbondanza() -> void:
	var mesi := cibo / maxf(pop, 1.0) * 12.0
	parti_abbondanza = {"cibo": clampf(mesi / MESI_PIENI, 0.0, 1.0), "salute": salute / 100.0, "spazio": 1.0 - affollamento}
	abbondanza = 0.0
	for k in PESI_ABBONDANZA:
		abbondanza += PESI_ABBONDANZA[k] * parti_abbondanza[k]


## Quanta legna si può tenere da parte (le cataste marciscono): due anni di consumo più il legname per
## costruire (26/11/2026 sera: prima la catasta era enorme e le legnaie tagliavano per riempirla).
func massimo_legna() -> float:
	return 2.0 * maxf(consumo_legna, pop * CONSUMO_PERSONA) + RISERVA_LEGNAME + COSTO_CASA


## Mesi di cibo in scorta.
func fattore_stanchezza(i: int) -> float:
	var a := float(stanchezza.get(i, 0.0))
	if a <= ANNI_PRIMA_STANCHEZZA:
		return 1.0
	return 1.0 - PERDITA_STANCHEZZA * clampf((a - ANNI_PRIMA_STANCHEZZA) / ANNI_STANCHEZZA, 0.0, 1.0)


## Campi stanchi: quanti rendono almeno il 10% in meno.
func campi_stanchi() -> int:
	var n_stanchi := 0
	for i in campi:
		if fattore_stanchezza(i) < 0.9:
			n_stanchi += 1
	return n_stanchi


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
		"sacerdote": obiettivo_sacerdote(),
	}
	for g in consenso:
		consenso[g] = clampf(consenso[g] + (clampf(obiettivi[g], 0.0, 100.0) - consenso[g]) * 0.1 + bonus[g] * 0.4, 0.0, 100.0)
		bonus[g] *= 0.6
		if absf(bonus[g]) < 0.2:
			bonus[g] = 0.0
	var pesi := pesi_consenso()
	legittimita = 0.0
	for g in pesi:
		legittimita += pesi[g] * consenso[g]
	_aggiorna_identita()


## Quanto conta ogni gruppo con il governo di oggi (nel villaggio: gli anziani; il sacerdote dal
## luogo sacro).
func pesi_consenso() -> Dictionary:
	return {"anziani": 0.4, "famiglie": 0.4, "sacerdote": 0.2} if sacerdote_attivo else {"anziani": 0.5, "famiglie": 0.5, "sacerdote": 0.0}


## Gli assi dell'identità seguono piano le politiche (non toccano nessuna regola del villaggio).
func _aggiorna_identita() -> void:
	var comune := politica("raccolto") == "comune"
	var apertura: float = {"aperta": 0.6, "caso": 0.1, "chiusa": -0.6}.get(politica("stranieri"), 0.0)
	identita_verso = {
		"terra": clampf((-0.5 if comune else 0.5) + 0.5 * disuguaglianza, -1.0, 1.0),
		"apertura": clampf(apertura + clampf(stranieri_accolti / 200.0, 0.0, 0.3), -1.0, 1.0),
		"decide": clampf((0.3 if comune else -0.1) - 0.8 * disuguaglianza, -1.0, 1.0),
		"governo": clampf((0.3 if comune else -0.3) + (0.2 if granaio_pronto() else 0.0), -1.0, 1.0),
	}
	for k in identita:
		identita[k] = clampf(identita[k] + (float(identita_verso[k]) - identita[k]) * PLASTICITA_IDENTITA, -1.0, 1.0)


## Tensione tra i gruppi (0–1): quanto sono lontani tra loro i gruppi che contano e quanto è basso
## il consenso. Nel villaggio si legge soltanto; nelle epoche dopo prepara le crisi.
func tensione() -> float:
	var pesi := pesi_consenso()
	var lo := 100.0
	var hi := 0.0
	for g in pesi:
		if pesi[g] > 0.0:
			lo = minf(lo, consenso[g])
			hi = maxf(hi, consenso[g])
	return clampf(0.5 * (hi - lo) / 50.0 + 0.5 * maxf(0.0, 55.0 - legittimita) / 40.0, 0.0, 1.0)


## Come è cambiato il consenso di un gruppo negli ultimi dieci anni.
func andamento_consenso(gruppo: String) -> float:
	var s: Array = storia_consenso[gruppo]
	if s.size() < 2:
		return 0.0
	return float(consenso[gruppo]) - float(s[maxi(0, s.size() - 10)])


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
		fattore = (0.25 + 0.5 * acqua_affidabile(i)) if siccita_grave else (0.35 + 0.6 * acqua_affidabile(i))
	else:
		fattore = clima * (0.85 + 0.15 * acqua_qualsiasi(i))
	_aggiorna_campi_serviti()
	# Sentiero: si va e si torna più in fretta. Bosco: la selvaggina rovina i campi al suo margine
	# (meno, se la caccia la tiene bassa).
	var vie := 1.0 + (BONUS_STRADA if _campi_strada.has(i) else (BONUS_SENTIERO if _campi_serviti.has(i) else 0.0))
	var danni := 1.0 - 0.25 * selvaggina if _campi_al_bosco.has(i) else 1.0
	var famiglie := 1.0 + 0.12 * efficacia_usanze() if politica("raccolto") == "famiglie" else 1.0
	return RESA_CAMPO * fert(i) * fattore * famiglie * (BONUS_LIMO if limo.has(i) else 1.0) * fattore_stanchezza(i) * (BONUS_STOPPIE if concimati.has(i) else 1.0) \
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
	# Per la grafica: l'acqua che sale (VistaVillaggio._anima_piena).
	if not colpiti.is_empty():
		ultima_piena = {"anno": anno, "disastrosa": disastrosa}
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
			stanchezza.erase(f)
		if campi_persi >= maxi(3, int(campi.size() * 0.1)):
			_scrivi("Piena di stagione: %d campi allagati. Il raccolto è perso, ma il limo li renderà più fertili." % campi_persi)
		return
	memoria = 100.0
	stat["piene"] += 1
	for f in allagati:
		limo[f] = ANNI_LIMO
		stanchezza.erase(f)
	# La prima piena grande si spiega in cronaca (dal 25/11/2026 fermano il gioco solo le scelte).
	if not gia_piena_disastrosa:
		gia_piena_disastrosa = true
		_scrivi("Le piene grandi sono rare, ma arrivano dove la mappa del rischio di piena è rossa, e più spesso se si taglia il bosco attorno al villaggio. Le famiglie ricostruiranno lontano dall'acqua finché il ricordo resta vivo.")
	if case_perse > 0:
		_case_piena_da_fare = case_perse
		_anno_piena = anno
		_cambia_consenso("famiglie", -minf(8.0, case_perse))
		_scrivi("Il fiume esce dal letto: %d case distrutte, %d campi allagati. Il ricordo del pericolo torna vivo." % [case_perse, campi_persi], "allarme")
	else:
		_scrivi("Il fiume esce dal letto: %d campi allagati, raccolto perso." % campi_persi, "allarme")


func _inizia_siccita() -> void:
	siccita = 1 + rng.randi() % 2
	siccita_grave = false
	sorgenti_basse = true
	stat["siccita"] += 1
	if not presagio_vero.is_empty():
		if presagio_vero["scelta"] != "razionare":
			# Presagio ignorato: la siccità dura di più e morde di più (carestie B).
			siccita = 2 + rng.randi() % 2
			siccita_grave = true
		if presagio_vero["scelta"] == "razionare":
			_cambia_consenso("anziani", 6.0)
			stat["presagi_letti"] += 1
			_scrivi("Arriva la siccità: le scorte accumulate ascoltando il presagio aiutano il villaggio.", "buono")
		else:
			_cambia_consenso("anziani", -8.0)
			_scrivi("Arriva la siccità annunciata dalle sorgenti: averla ignorata costa caro agli anziani.", "allarme")
		presagio_vero = {}
	_scrivi("Siccità per %s: rendono solo i campi vicini al fiume e alle sorgenti." % ("un anno" if siccita == 1 else "%d anni" % siccita), "allarme")


## Abitato spontaneo (decisione di Fede): le case nascono da sole vicino al centro, all'acqua e
## lontano dal pericolo di piena finché la memoria del rischio è viva; il giocatore orienta la
## crescita con campi, sentieri e granaio.
## Con `paga` le case nuove costano legna (decisione di Fede del 25/11/2026: le case spontanee
## crescono solo se c'è legna); senza, si ridispongono gratis (fondazione, case spostate).
## Dalla tappa "Territorio" il nucleo tiene fino a NUCLEO_MASSIMO abitanti e le famiglie in più
## vanno nei casali del contado (decisione di Fede del 25/11/2026).
func disponi_case(paga := false) -> void:
	if not fondato:
		return
	# Case tolte da altre parti (piene, demolizioni, sentieri): via anche dai casali.
	var presenti := {}
	for c in case:
		presenti[c] = true
	for l in case_casale.keys():
		if not presenti.has(l):
			case_casale.erase(l)
	var servono_n := ceili(abitanti_nucleo() / ABITANTI_PER_CASA)
	var servono_c := ceili(abitanti_casali() / ABITANTI_PER_CASA)
	# Troppe case: si tolgono prima quelle dei casali, poi quelle del nucleo (le più recenti).
	var nel_casale := case.filter(func(c: Vector2i) -> bool: return case_casale.has(c))
	while nel_casale.size() > servono_c:
		var via: Vector2i = nel_casale.pop_back()
		case.erase(via)
		case_casale.erase(via)
	var nel_nucleo := case.filter(func(c: Vector2i) -> bool: return not case_casale.has(c))
	while nel_nucleo.size() > servono_n:
		var via: Vector2i = nel_nucleo.pop_back()
		case.erase(via)
	_disponi_nucleo(servono_n, nel_nucleo.size(), paga)
	_disponi_casali(servono_c, paga)
	var servono := servono_n + servono_c
	affollamento = clampf(float(servono - case.size()) / servono, 0.0, 1.0) if servono > 0 else 0.0


## Abitanti del nucleo e dei casali.
func abitanti_nucleo() -> float:
	return minf(pop, NUCLEO_MASSIMO) if sbloccato("casali") else pop


func abitanti_casali() -> float:
	return pop - abitanti_nucleo()


func case_nel_nucleo() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for c in case:
		if not case_casale.has(c):
			out.append(c)
	return out


func _disponi_nucleo(servono: int, ci_sono: int, paga: bool) -> void:
	var lc := lotto_da_mondo(mondo_di_px(centro).x, mondo_di_px(centro).y)
	var r := 3 + ceili(1.4 * sqrt(servono)) + raggio_extra * 3
	var paura := memoria / 100.0
	var occupati := {}
	for c in case:
		occupati[c] = true
	var granaio_l := lotto_da_mondo(granaio.x, granaio.y) if granaio.x >= 0 else Vector2i(-99999, -99999)
	var sacro_l := lotto_da_mondo(luogo_sacro.x, luogo_sacro.y) if luogo_sacro.x >= 0 else Vector2i(-99999, -99999)
	# Candidati: i lotti attorno al centro e, dalle strade, i lotti lungo le strade (il borgo
	# lungo la via: chi abita sulla strada è vicino a tutto anche se è lontano dal focolare).
	var candidati: Array[Vector2i] = []
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			candidati.append(lc + Vector2i(dx, dy))
	var lungo_strada := {}
	for ip in pixel_strada:
		var wp := mondo_di_px(px_di(ip))
		if wp.distance_to(mondo_di_px(centro)) > STRADA_ATTRAE_CASE:
			continue
		var lp := lotto_da_mondo(wp.x, wp.y)
		for oy in range(-2, 3):
			for ox in range(-2, 3):
				var lq := lp + Vector2i(ox, oy)
				if not lungo_strada.has(lq):
					lungo_strada[lq] = true
					if cheb(lq, lc) > r:
						candidati.append(lq)
	var tentativi := 0
	while ci_sono < servono and tentativi < 200 and (not paga or legna >= COSTO_CASA):
		tentativi += 1
		var migliore := Vector2i(-1, -1)
		var punteggio := -1e9
		for l in candidati:
			if true:
				var dx := l.x - lc.x
				var dy := l.y - lc.y
				if l == lc or cheb(l, granaio_l) <= 1 or cheb(l, sacro_l) <= 1 or macerie.has(l) or _vicino_a_legnaia(l):
					continue
				var w := centro_lotto(l)
				var p := px_da_mondo(w.x, w.y)
				if w.x < 0 or w.y < 0 or w.x > dati.lato_metri() or w.y > dati.lato_metri():
					continue
				var i := px(p)
				if not edificabile(i) or campi.has(i) or sentieri.has(i):
					continue
				# Le case lasciano un lotto libero attorno; dopo una scorreria (memoria della paura) si
				# stringono e basta un lotto libero di lato: in diagonale possono toccarsi.
				var stretti := memoria_scorrerie > 50.0
				var vicina := false
				for oy in [-1, 0, 1]:
					for ox in [-1, 0, 1]:
						if stretti and ox != 0 and oy != 0:
							continue
						if occupati.has(l + Vector2i(ox, oy)):
							vicina = true
				if vicina:
					continue
				var d := Vector2(dx, dy).length() * LOTTO / 40.0
				# Lungo la strada la distanza pesa meno: si cammina in fretta.
				if lungo_strada.has(l):
					d = minf(d, 2.0 + d * 0.25)
				var caso := float((l.x * 73856093 ^ l.y * 19349663) & 0xffff) / 65536.0
				var sc := -d * (1.2 + 1.5 * memoria_scorrerie / 100.0) - piena(i) * paura * 8.0 + acqua_qualsiasi(i) - (1.0 if dati.tipo[i] == MappaDati.GESSI else 0.0) + caso * 0.25
				# Il luogo sacro attira le case (decisione di Fede del 24/11/2026: il germe della piazza).
				if luogo_sacro.x >= 0:
					sc += 2.5 * clampf(1.0 - w.distance_to(luogo_sacro) / 400.0, 0.0, 1.0)
				if sc > punteggio:
					punteggio = sc
					migliore = l
		if migliore.x == -1 and migliore.y == -1:
			break
		case.append(migliore)
		_segna_casa(migliore)
		occupati[migliore] = true
		ci_sono += 1
		if paga:
			legna -= COSTO_CASA


## Memoria della scheda della famiglia: quando nasce una casa e se è di chi è arrivato da fuori.
func _segna_casa(l: Vector2i) -> void:
	nascita_case[l] = anno
	prestigio_case.erase(l)
	if _case_stranieri_da_fare > 0 and anno - _anno_stranieri <= 10:
		case_straniere[l] = _anno_stranieri
		_case_stranieri_da_fare -= 1
	else:
		case_straniere.erase(l)
	if _case_piena_da_fare > 0 and anno - _anno_piena <= 10:
		case_dopo_piena[l] = _anno_piena
		_case_piena_da_fare -= 1
	else:
		case_dopo_piena.erase(l)


## Prestigio delle famiglie (nascosto, per l'epoca 2): ogni anno un po' di più a chi abita vicino al
## focolare e al luogo sacro; con il raccolto alle famiglie anche gli animali, che vanno di più a chi
## ha già più prestigio. Cresce con gli anni, quindi le famiglie dei fondatori partono avanti.
func _aggiorna_prestigio() -> void:
	var c := mondo_di_px(centro)
	var sacro := luogo_sacro_pronto()
	var alle_famiglie := politica("raccolto") == "famiglie" and capi >= 1.0
	var massimo := 0.0
	for l in case:
		massimo = maxf(massimo, float(prestigio_case.get(l, 0.0)))
	var nuovo := {}
	for l in case:
		var w := centro_lotto(l)
		var p := float(prestigio_case.get(l, 0.0))
		var d := clampf(1.0 - w.distance_to(c) / 250.0, 0.0, 1.0)
		if sacro:
			d += 0.8 * clampf(1.0 - w.distance_to(luogo_sacro) / 150.0, 0.0, 1.0)
		if alle_famiglie:
			d += 0.5 * (p / massimo if massimo > 0.0 else 0.5)
		nuovo[l] = p + 0.02 * d
	prestigio_case = nuovo


## Umore di ogni famiglia: il consenso delle famiglie più uno scarto dalla sua situazione; gli
## scarti si bilanciano, così la media resta il consenso del gruppo. lotto -> [umore 0–100, motivi].
func umore_famiglie() -> Dictionary:
	var c := mondo_di_px(centro)
	var legnaie_attive: Array = legnaie.filter(func(g: Dictionary) -> bool: return legnaia_attiva(g))
	var sacro := luogo_sacro_pronto()
	var scarti := {}
	var somma := 0.0
	for l in case:
		var w := centro_lotto(l)
		var i := px(px_da_mondo(w.x, w.y))
		var s := 0.0
		var motivi: Array[String] = []
		if case_dopo_piena.has(l) and anno - int(case_dopo_piena[l]) < 20:
			s -= 12.0 * (1.0 - (anno - int(case_dopo_piena[l])) / 20.0)
			motivi.append("pesa: ha perso la casa nella piena del " + anno_testo(int(case_dopo_piena[l])))
		if piena(i) > 0.5:
			s -= 8.0
			motivi.append("pesa: la casa è dove arrivano le piene")
		if case_razziate.has(l) and anno - int(case_razziate[l]) < ANNI_MEMORIA_RAZZIA:
			s -= 10.0 * (1.0 - (anno - int(case_razziate[l])) / float(ANNI_MEMORIA_RAZZIA))
			motivi.append("pesa: la scorreria del " + anno_testo(int(case_razziate[l])))
		if not legnaie_attive.is_empty():
			var vicina := INF
			for g in legnaie_attive:
				vicina = minf(vicina, w.distance_to(g["punto"]))
			if vicina > 500.0:
				s -= 6.0
				motivi.append("pesa: la legna è lontana")
		var vicini := 0
		var stanchi := 0
		for f in campi:
			if mondo_di_px(px_di(f)).distance_to(w) < 300.0:
				vicini += 1
				if fattore_stanchezza(f) < 0.9:
					stanchi += 1
		if vicini > 0 and stanchi > vicini * 0.4:
			s -= 5.0
			motivi.append("pesa: i campi vicini sono stanchi")
		if case_casale.has(l):
			var sentiero := false
			var p := px_da_mondo(w.x, w.y)
			for q in sentieri:
				if Vector2(px_di(q) - p).length() <= 3.0:
					sentiero = true
					break
			if not sentiero:
				s -= 5.0
				motivi.append("pesa: nessun sentiero verso il paese")
			elif _vicino_a_strada(w, 120.0):
				s += 3.0
				motivi.append("aiuta: una strada verso il paese")
		if w.distance_to(c) < 80.0:
			s += 3.0
			motivi.append("aiuta: vive vicino al focolare")
		if sacro and w.distance_to(luogo_sacro) < 120.0:
			s += 3.0
			motivi.append("aiuta: il luogo sacro è vicino")
		scarti[l] = [s, motivi]
		somma += s
	var media := somma / maxf(1.0, case.size())
	var out := {}
	for l in scarti:
		out[l] = [clampf(float(consenso["famiglie"]) + float(scarti[l][0]) - media, 0.0, 100.0), scarti[l][1]]
	return out


func _vicino_a_legnaia(l: Vector2i) -> bool:
	for g in legnaie + poste + capanni:
		var p: Vector2 = g["punto"]
		if cheb(lotto_da_mondo(p.x, p.y), l) <= 1:
			return true
	return false


## Casali: le famiglie in più si stabiliscono nel contado, vicino ai campi, lontano dal pericolo
## di piena finché il ricordo è vivo, in gruppi di 2–4 case distanti tra loro.
func _disponi_casali(servono: int, paga: bool) -> void:
	var ci_sono := case_casale.size()
	var occupati := {}
	for c in case:
		occupati[c] = true
	var tentativi := 0
	while ci_sono < servono and tentativi < 60 and (not paga or legna >= COSTO_CASA):
		tentativi += 1
		# Un casale con posto, altrimenti uno nuovo.
		var k := -1
		var conta := {}
		for l in case_casale:
			conta[case_casale[l]] = int(conta.get(case_casale[l], 0)) + 1
		for j in casali.size():
			if int(conta.get(j, 0)) < CASE_PER_CASALE:
				k = j
				break
		if k < 0:
			var nuovo := _sito_casale()
			if nuovo.x == -99999:
				break
			casali.append(nuovo)
			k = casali.size() - 1
		var lotto := _lotto_nel_casale(casali[k], occupati)
		if lotto.x == -99999:
			# Il casale è chiuso (niente terra libera attorno): si segna come pieno.
			for t in CASE_PER_CASALE:
				case_casale[Vector2i(-100000 - k * 10 - t, 0)] = k
			continue
		case.append(lotto)
		_segna_casa(lotto)
		case_casale[lotto] = k
		occupati[lotto] = true
		ci_sono += 1
		if paga:
			legna -= COSTO_CASA
	# Le chiavi fittizie dei casali pieni non contano come case.
	for l in case_casale.keys():
		if l.x <= -100000:
			case_casale.erase(l)


func _sito_casale() -> Vector2i:
	var c := mondo_di_px(centro)
	var migliore := Vector2i(-99999, 0)
	var punteggio := -1e9
	var paura := memoria / 100.0
	var passo := 2
	var r := ceili(CASALE_DISTANZA_MAX / dati.metri_per_px)
	var coltivati := {}
	for i in campi:
		coltivati[i] = true
	for dy in range(-r, r + 1, passo):
		for dx in range(-r, r + 1, passo):
			var q := centro + Vector2i(dx, dy)
			if q.x < 1 or q.y < 1 or q.x >= n - 1 or q.y >= n - 1:
				continue
			var w := mondo_di_px(q)
			var d := w.distance_to(c)
			if d < CASALE_DISTANZA_MIN or d > CASALE_DISTANZA_MAX:
				continue
			var i := px(q)
			if not edificabile(i) or coltivati.has(i) or sentieri.has(i):
				continue
			var lontano := true
			for s in casali:
				if centro_lotto(s).distance_to(w) < CASALE_SPAZIO:
					lontano = false
			if not lontano:
				continue
			var vicini := 0
			for oy in range(-3, 4):
				for ox in range(-3, 4):
					var v := q + Vector2i(ox, oy)
					if v.x >= 0 and v.y >= 0 and v.x < n and v.y < n and coltivati.has(px(v)):
						vicini += 1
			# Dopo una scorreria i casali nuovi nascono più vicini al villaggio (memoria della paura).
			var sc := vicini * 0.2 - piena(i) * (0.5 + paura) * 8.0 + acqua_qualsiasi(i) - d / 1000.0 * (1.0 + 3.0 * memoria_scorrerie / 100.0)
			if sc > punteggio:
				punteggio = sc
				migliore = lotto_da_mondo(w.x, w.y)
	return migliore


func _lotto_nel_casale(centro_casale: Vector2i, occupati: Dictionary) -> Vector2i:
	for raggio in [0, 2, 3]:
		for dy in range(-raggio, raggio + 1):
			for dx in range(-raggio, raggio + 1):
				var l := centro_casale + Vector2i(dx, dy)
				if occupati.has(l):
					continue
				# Le case lasciano un lotto libero attorno; dopo una scorreria (memoria della paura) si
				# stringono e basta un lotto libero di lato: in diagonale possono toccarsi.
				var stretti := memoria_scorrerie > 50.0
				var vicina := false
				for oy in [-1, 0, 1]:
					for ox in [-1, 0, 1]:
						if stretti and ox != 0 and oy != 0:
							continue
						if occupati.has(l + Vector2i(ox, oy)):
							vicina = true
				if vicina:
					continue
				var w := centro_lotto(l)
				var i := px(px_da_mondo(w.x, w.y))
				if edificabile(i) and not campi.has(i) and not sentieri.has(i):
					return l
	return Vector2i(-99999, 0)


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
	casali = []
	case_casale = {}
	nascita_case = {}
	case_straniere = {}
	prestigio_case = {}
	case_dopo_piena = {}
	legnaie = []
	poste = []
	capanni = []
	luogo_sacro = Vector2(-1, -1)
	cantiere_luogo_sacro = 0
	bosco_sacro = {}
	_azzera_scorrerie()
	campi = []
	_tecnica_campi = {}
	zona = {}
	sentieri = []
	tratti_sentiero = []
	traffico = {}
	strade = {}
	anni_battuto = {}
	pixel_strada = {}
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
	_decidi("fine", "%s: la fine dei tempi del villaggio" % anno_testo(anno), testo, [{"id": "ok", "testo": "Resta a guardare la mappa", "nota": ""}])


# ---------- passo elastico ed evento soglia 1 (todo voce 6, 26/11/2026) ----------

## Quanti anni fa un passo della partita: uno nei primi secoli, dieci dopo (ANNI_DECENNIO).
func anni_per_passo() -> int:
	return ANNI_DECENNIO if decenni else 1


func _aggiorna_decenni() -> void:
	if decenni or not fondato or anno < ANNO_DECENNI:
		return
	if tappa < tappa_di("casali") and anno < ANNO_DECENNI_COMUNQUE:
		return
	decenni = true
	_scrivi("Il villaggio ha messo radici. Da qui il tempo scorre a decenni: le generazioni passano, e conta ciò che resta.", "buono")
	tutorial(["decenni"], "Il tempo a decenni")


## La terra coltivabile del contado al raggio massimo (pixel), ricalcolata se il centro cambia.
func terra_contado() -> int:
	if _firma_terra_contado == px(centro):
		return _terra_contado
	_firma_terra_contado = px(centro)
	_terra_contado = 0
	var r := ceili(CONTADO_MAX / dati.metri_per_px)
	var c := mondo_di_px(centro)
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var q := centro + Vector2i(dx, dy)
			if q.x < 0 or q.y < 0 or q.x >= n or q.y >= n:
				continue
			if mondo_di_px(q).distance_to(c) <= CONTADO_MAX and edificabile(px(q)):
				_terra_contado += 1
	return _terra_contado


## Il territorio è pieno: contado al raggio massimo e quasi tutta la sua terra in campi o pascolo,
## oppure un villaggio grande.
func territorio_pieno() -> bool:
	if pop >= ABITANTI_TERRITORIO_PIENO:
		return true
	if raggio_contado() < CONTADO_MAX:
		return false
	return campi.size() + pascolo.size() >= QUOTA_TERRITORIO_PIENO * maxi(terra_contado(), 1)


## Quanto manca all'evento soglia, per lo specchietto (vuoto se non è ancora tempo di parlarne).
func attesa_soglia() -> String:
	if soglia_scelta != "" or anno < ANNO_PRESAGI_SOGLIA:
		return ""
	if anno < ANNO_SOGLIA:
		return "le voci del metallo arrivano dalla valle"
	return "il villaggio è pronto" if territorio_pieno() else "serve un territorio pieno"


func _soglia() -> void:
	if not fondato or soglia_scelta != "" or finito:
		return
	if anno >= ANNO_PRESAGI_SOGLIA and presagi_soglia < PRESAGI_SOGLIA.size() and anno >= _prossimo_presagio_soglia:
		var testo: String = PRESAGI_SOGLIA[presagi_soglia]
		presagi_soglia += 1
		_prossimo_presagio_soglia = anno + rng_soglia.randi_range(60, 140)
		_scrivi(testo)
		_notifica(testo, false, mondo_di_px(centro))
	if in_attesa() or anno < ANNO_SOGLIA:
		return
	if not (anno >= ANNO_SOGLIA_COMUNQUE or (territorio_pieno() and presagi_soglia >= 2)):
		return
	soglia_scelta = "attesa"
	_decidi("soglia", "Il metallo e lo scambio",
		"Lungo la valle passano mercanti con oggetti di rame, e i villaggi che commerciano crescono e si armano. Il villaggio ha riempito la sua terra: deve scegliere se aprirsi alle vie di passaggio o restare com'è sempre stato. La scelta resterà nella città che verrà.",
		[{"id": "aprirsi", "testo": "Aprirsi alle vie di passaggio", "nota": "Arrivano il metallo, la ricchezza e gente nuova; ma anche più razzie, più malattie, e più potere a chi commercia."},
		 {"id": "isolarsi", "testo": "Restare isolati", "nota": "Più sicuro, con le usanze di sempre; ma senza metallo il villaggio resterà indietro."}])


## Il primo governo con un nome (era-origini.md § 5), dalla tabella delle condizioni: raccolto in
## comune, poca disuguaglianza e anziani contenti danno la Comunità; raccolto alle famiglie e
## disuguaglianza alta (mandrie delle famiglie) la Casa dominante; il resto, alcune famiglie più forti,
## il Consiglio dei clan. Il raccolto si legge dall'asse "terra" dell'identità (lento: conta come si è
## vissuto, non l'ultima scelta); la disuguaglianza viene dagli animali delle famiglie (una mandria
## di 300 capi la porta a 1). Soglie rifatte il 27/11/2026 (Fede: "ok da fare"; prima la Casa
## dominante usciva con ogni raccolto alle famiglie e il Consiglio dei clan mai). Numeri: proposta di
## Claude, tarati sulle partite lunghe (a fine partita la disuguaglianza sta fra 0 e 0,2).
const SOGLIA_TERRA_COMUNE := 0.0
const SOGLIA_TERRA_FAMIGLIE := 0.25
const DISUGUAGLIANZA_COMUNITA := 0.3
const DISUGUAGLIANZA_CASA := 0.12  # mandrie delle famiglie di una quarantina di capi
const ANZIANI_COMUNITA := 45.0

func governo_da_identita() -> String:
	var terra := float(identita["terra"])
	if terra < SOGLIA_TERRA_COMUNE and disuguaglianza < DISUGUAGLIANZA_COMUNITA and consenso["anziani"] >= ANZIANI_COMUNITA:
		return "Comunità"
	if terra > SOGLIA_TERRA_FAMIGLIE and disuguaglianza >= DISUGUAGLIANZA_CASA:
		return "Casa dominante"
	return "Consiglio dei clan"


const DESCRIZIONE_GOVERNI := {
	"Comunità": "Le famiglie riunite decidono insieme: lavori comuni rapidi e consenso largo, ma scelte lente e poca difesa.",
	"Consiglio dei clan": "I capi dei clan decidono insieme: concessioni di terra e alleanze, ma i clan si contendono il potere.",
	"Casa dominante": "Un clan sta sopra gli altri: prestigio, scambi e opere in fretta, ma i comuni sono scontenti.",
}


## Dopo la scelta dell'evento soglia: l'identità prende il segno della scelta, nasce il primo governo,
## arriva l'aratro, e il prototipo finisce con il riepilogo del villaggio (l'epoca 2 è sulla carta).
func _transizione(o: String) -> void:
	soglia_scelta = o
	identita["apertura"] = clampf(float(identita["apertura"]) + (0.5 if o == "aprirsi" else -0.5), -1.0, 1.0)
	primo_governo = governo_da_identita()
	tecnica_corrente = maxi(tecnica_corrente, 1)
	_scrivi("Il villaggio sceglie di %s. Nasce il primo governo: %s." % ["aprirsi alle vie di passaggio" if o == "aprirsi" else "restare isolato", primo_governo.to_lower()], "buono")
	_scrivi("Arriva l'aratro: i campi nuovi rendono di più, e quelli vecchi si possono rifare (Ammodernamento).")
	finito = true
	var anni := anno - ANNO_INIZIO
	var chi := consenso.keys().filter(func(g: String) -> bool: return g != "sacerdote" or sacerdote_attivo)
	chi.sort_custom(func(a: String, b: String) -> bool: return consenso[a] > consenso[b])
	var testo := "%d anni dalla fondazione. Il villaggio conta %d abitanti in %d case, %d nei casali; %d ettari di campi, %d strade.\nCarestie: %d · Piene grandi: %d · Scorrerie: %d · Abbandoni: %d\nConta di più: %s.\n\nIl primo governo: %s. %s\n%s\n\nArriva l'aratro. L'epoca dell'abitato protourbano è ancora sulla carta: il prototipo finisce qui." % [
		anni, roundi(pop), case.size(), case_casale.size(), roundi(campi.size() * 0.16), strade.size(),
		stat["carestie"], stat["piene"], stat["scorrerie"], stat["abbandoni"], ", ".join(chi.map(func(g: String) -> String: return {"anziani": "gli anziani", "famiglie": "le famiglie", "sacerdote": "il sacerdote"}[g])),
		primo_governo, DESCRIZIONE_GOVERNI[primo_governo],
		"La città nascerà aperta alle vie del commercio." if o == "aprirsi" else "La città nascerà chiusa e agricola, fedele alle usanze."]
	_decidi("fine", "%s: il metallo e lo scambio" % anno_testo(anno), testo, [{"id": "ok", "testo": "Continua a guardare il villaggio", "nota": ""}])


# ---------- cause, per i pannelli di focus (decisione di Fede del 25/11/2026) ----------

## Le 2–4 cause che oggi spingono un indicatore, scritte in chiaro per il giocatore.
func cause_di(nome: String) -> Array[String]:
	var out: Array[String] = []
	if not fondato:
		return out
	var cibo_anno := ultimo_raccolto + ultima_caccia + ultima_pesca
	match nome:
		"Abbondanza", "Popolazione":
			if not casali.is_empty():
				out.append("%d abitanti nel villaggio e %d nei %d casali del contado: il villaggio tiene fino a %d abitanti, le famiglie in più vanno a vivere vicino ai loro campi." % [roundi(abitanti_nucleo()), roundi(abitanti_casali()), casali.size(), roundi(NUCLEO_MASSIMO)])
			if abbondanza >= SOGLIA_CRESCITA + 0.02:
				out.append("La popolazione cresce: c'è cibo da parte, salute e spazio.")
			elif abbondanza <= SOGLIA_CRESCITA - 0.02:
				out.append("La popolazione cala piano: l'abbondanza è sotto %d." % roundi(SOGLIA_CRESCITA * 100.0))
			else:
				out.append("La popolazione è ferma: il villaggio ha quasi raggiunto ciò che la terra può dare.")
			if anni_deficit >= 3 and abbondanza_lenta > abbondanza:
				out.append("Siete più di quanti la terra possa sfamare: le nascite vengono dagli anni buoni, ma da %d anni il cibo non basta. Servono più campi, o meno bocche." % anni_deficit)
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
			# Senza edifici caccia e pesca rendono un terzo (decisione di Fede del 25/11/2026).
			if fonti["caccia"] and poste.is_empty():
				out.append("Senza posta di caccia le famiglie cacciano attorno al villaggio e rendono un terzo: costruiscine una al margine del bosco (Edifici).")
			if fonti["pesca"] and capanni.is_empty() and float(_risorse["acqua"]) > 5.0:
				out.append("Senza capanno da pesca le famiglie pescano come capita e rendono un terzo: costruiscine uno sulla riva (Edifici).")
			for e in poste:
				if int(e["cantiere"]) <= 0 and scorta_attorno(e) < 0.4:
					out.append("Attorno a una posta la selvaggina è scarsa (%d%%)." % roundi(scorta_attorno(e) * 100.0))
					break
			for e in capanni:
				if int(e["cantiere"]) <= 0 and scorta_attorno(e) < 0.4:
					out.append("In un tratto di riva il pesce è scarso (%d%%)." % roundi(scorta_attorno(e) * 100.0))
					break
			var stanchi := campi_stanchi()
			if stanchi > 0:
				out.append("%d campi sono stanchi dopo tanti anni di coltura: rendono meno. Lasciati incolti si riposano; il limo di una piena li rinnova." % stanchi)
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
			if not ultima_scorreria.is_empty() and anno - int(ultima_scorreria["anno"]) < 10:
				out.append("Gli anziani hanno perso credito con la scorreria del %s." % anno_testo(int(ultima_scorreria["anno"])))
			if in_allerta() and politica("pericolo") == "vegliare":
				out.append("Gli uomini vegliano ai margini: gli anziani sono contenti, ma lavorano meno nei campi.")
			# Il sacerdote (decisioni di Fede del 24–25/11/2026).
			if sbloccato("luogo_sacro") and luogo_sacro.x < 0:
				out.append("Il sacerdote è contrariato finché non si erige il luogo sacro (Edifici): i presagi si fanno ambigui e più frequenti.")
			elif cantiere_luogo_sacro > 0:
				out.append("Il luogo sacro è in costruzione: ancora %d anni." % cantiere_luogo_sacro)
			if sacerdote_attivo:
				if consenso["sacerdote"] >= 60.0:
					out.append("Il sacerdote è contento: i presagi sono chiari e le voci false poche.")
				elif consenso["sacerdote"] < 40.0:
					out.append("Il sacerdote è scontento: i presagi si fanno ambigui e più frequenti, e girano più voci false.")
				if sbloccato("bosco_sacro") and ettari_bosco_sacro() < ETTARI_BOSCO_SACRO:
					out.append("Il sacerdote vuole un bosco sacro più grande (ora %s ha su %d)." % [String.num(ettari_bosco_sacro(), 1).replace(".", ","), roundi(ETTARI_BOSCO_SACRO)])
		"Legna":
			if legnaie.is_empty():
				out.append("Senza legnaia non si raccoglie legna: costruiscine una vicino al bosco (Edifici). Ora arriva solo quella del dissodamento.")
			else:
				out.append("Il bosco attorno alle legnaie dà %d di legna da ardere l'anno; se ne raccolgono %d. I focolari ne bruciano %d." % [roundi(offerta_raccolta), roundi(raccolta_legna), roundi(consumo_focolari)])
				out.append("I boscaioli abbattono %d di tronchi l'anno (fino a %d), per rifare le case e costruire." % [roundi(tronchi_legna), roundi(capacita_taglio)])
				if offerta_raccolta < consumo_focolari:
					out.append("Il bosco vicino non basta per i focolari: una legnaia nuova più vicina al bosco ne raccoglierebbe di più.")
				for k in legnaie.size():
					var l: Dictionary = legnaie[k]
					var d := _bosco_vicino_legnaia(l)
					var stato := stato_legnaia(l)
					if int(l["cantiere"]) <= 0 and not bool(l["riposo"]) and d > RAGGIO_LEGNAIA * 0.5:
						stato += "; gli alberi sono ormai a %d m: i boscaioli camminano di più e tagliano meno, conviene una legnaia più vicina al bosco" % roundi(d)
					out.append("Legnaia %d: %s." % [k + 1, stato])
			if disboscamento > 0.1:
				out.append("Attorno al villaggio è sparito il %d%% del bosco: meno legna e selvaggina, piene più frequenti." % roundi(disboscamento * 100.0))
			if legna < COSTO_CASA:
				out.append("Senza legna non nascono case nuove.")
			if legna >= massimo_legna() - 1.0:
				out.append("La catasta è piena: la legna in più marcisce.")
		"Animali":
			if not sbloccato("pascolo"):
				out.append("Il villaggio non ha ancora animali da pascolo.")
				return out
			if pascolo.is_empty():
				out.append("Senza zona di pascolo gli animali stanno attorno alle case: non più di %d capi. Stendi il pascolo (Territorio) su prati, radure e margini del bosco." % roundi(CAPI_ATTORNO_CASE))
			else:
				var e := ettari_pascolo()
				out.append("Il pascolo nutre fino a %d capi: %s ha di prato, %s di bosco, %s di maggese, %s di stoppie." % [roundi(portata_capi), _ha(e["prato"]), _ha(e["bosco"]), _ha(e["maggese"]), _ha(e["stoppie"])])
			if erba < 0.05:
				out.append("L'erba è finita: la mandria non cresce più. Serve più pascolo.")
			if maggese.size() > 0:
				out.append("%d campi stanchi sono a maggese: gli animali li concimano e si riposano più in fretta." % maggese.size())
			if pascolo_eccessivo > 0.3:
				out.append("Troppi animali sui pendii: la terra scende e le piene arrivano più spesso.")
			if ultimi_macellati > 0:
				out.append("Quest'anno si sono macellati %d capi per l'annata cattiva." % ultimi_macellati)
			if politica("raccolto") == "famiglie":
				out.append("Gli animali sono delle famiglie: la mandria cresce più in fretta, ma chi ne ha di più si arricchisce (disuguaglianza %d%%)." % roundi(disuguaglianza * 100.0))
			out.append_array(cause_scorrerie())
	return out


## Le scorrerie a parole (pannelli degli Animali e del Consenso): il rischio, i segni, l'ultima.
func cause_scorrerie() -> Array[String]:
	var out: Array[String] = []
	if not gia_segni:
		return out
	if in_allerta():
		var pol: String = {"avanti": "si va avanti come sempre", "raccogliere": "animali e scorte sono raccolti vicino alle case: la mandria non cresce", "vegliare": "gli uomini vegliano ai margini"}.get(politica("pericolo"), "")
		out.append("Segni di pericolo da %s: %s." % [segni_da, pol])
	if not rischio_scorrerie.is_empty():
		var p := float(rischio_scorrerie["p"])
		var livello := "alto" if p > 0.008 else ("medio" if p > 0.003 else "basso")
		var attira: Array[String] = []
		if float(rischio_scorrerie["ricchezza"]) > 0.4:
			attira.append("gli animali e le scorte che si vedono")
		if not casali.is_empty():
			attira.append("i casali")
		if float(rischio_scorrerie["pascolo_lontano"]) > 0.4:
			attira.append("i pascoli lontani")
		if float(rischio_scorrerie["margini_vuoti"]) > 0.6:
			attira.append("i margini del contado vuoti")
		var testo := "Rischio di scorrerie %s" % livello
		if not attira.is_empty():
			testo += ": attirano " + ", ".join(attira)
		if float(rischio_scorrerie["difesa"]) > 0.5:
			testo += "; il sito e le case raccolte aiutano a difendersi"
		out.append(testo + ".")
	if not ultima_scorreria.is_empty() and anno - int(ultima_scorreria["anno"]) < 15:
		out.append("Scorreria del %s da %s: %d capi, %d di cibo, %d case perse." % [anno_testo(int(ultima_scorreria["anno"])), ultima_scorreria["da"], ultima_scorreria["capi"], ultima_scorreria["cibo"], ultima_scorreria["case"]])
	if torre.x >= 0:
		out.append(("La torre di avvistamento è in costruzione: ancora %d anni." % cantiere_torre) if cantiere_torre > 0 else "La torre di avvistamento dà i segni prima e le perdite sono minori.")
	return out


func _ha(v: float) -> String:
	return String.num(v, 1).replace(".", ",")
