# Sessioni di gioco automatiche: dieci livelli di bravura

*24/11/2026. Richiesta di Fede: preparare sessioni di gioco a livelli di competenza diversi e vedere come procedono gli abitanti, perché lo scopo del gioco è creare una città e più abitanti è più successo (come in Cities: Skylines). Le proposte in fondo sono di Claude, da discutere.*

## Come sono fatte
- Script: `gioco/test/sessioni_giocatori.gd` (uso nella testa del file). Gioca soltanto la simulazione (`SimVillaggio`), senza grafica.
- **180 partite:** 10 livelli × 6 siti di fondazione × 3 semi, 500 anni ciascuna (6000–5500 a.C.). Nell'ambiente di Claude ci vogliono circa 25 minuti.
- **Cosa cambia con la bravura** (livello k da 1 a 10):
  - attenzione: ogni quanti anni il giocatore guarda la mappa (da 50 a 5);
  - zona agricola: quanta parte del contado copre (dal 46% al 100%); ai livelli 1–2 la si allarga solo quando arriva la notifica "zona piena"; dal 6 si evitano le terre a rischio di piena alto, dall'8 anche quelle a rischio medio, a meno che la terra sicura sia meno del 40%;
  - granaio dal livello 3; sentieri radiali collegati dal 5 (uno per livello oltre il 4, fino a 6);
  - scelte: la risposta giusta per la crescita con probabilità (k − 1) / 9, altrimenti una a caso (giuste: razionare con le sorgenti basse, ignorare la cometa, accogliere gli stranieri, restare quando c'è affollamento, cacciare o razionare al primo cattivo raccolto);
  - dal 6 la divisione del raccolto (alle famiglie se il consenso regge, altrimenti in comune); dal 7 la caccia sospesa quando la selvaggina crolla.
- Un difetto del giocatore automatico trovato strada facendo: sul Dosso nelle paludi i livelli 8–10, evitando tutta la terra a rischio di piena, restavano senza campi e morivano di fame. Corretto (accettano il rischio se la terra sicura è troppo poca) e rigiocato quel sito; gli altri risultati non cambiano.

## Risultati
![Abitanti per livello di bravura](immagini/sessioni-giocatori-24-11.png)

| Livello | Abitanti a 500 anni (mediana) | Minimo – massimo | Massimo raggiunto (mediana) | Anni per arrivare a 300 | Partite oltre 1000 | Carestie per partita |
|---|---|---|---|---|---|---|
| 1 | 229 | 127 – 414 | 271 | 269 (6 partite su 18) | 0 | 8 |
| 2 | 310 | 146 – 451 | 360 | 236 (12/18) | 0 | 8 |
| 3 | 415 | 178 – 586 | 493 | 235 (15/18) | 0 | 24 |
| 4 | 512 | 207 – 628 | 608 | 237 (15/18) | 0 | 24 |
| 5 | 576 | 246 – 749 | 708 | 218 (16/18) | 0 | 23 |
| 6 | 592 | 260 – 798 | 824 | 192 | 0 | 29 |
| 7 | 690 | 319 – 871 | 924 | 200 | 6 | 24 |
| 8 | 783 | 323 – 1072 | 989 | 193 | 9 | 26 |
| 9 | 882 | 345 – 1034 | 1109 | 191 | 15 | 26 |
| 10 | 997 | 391 – 1212 | 1238 | 191 | 15 | 24 |

Nessun abbandono in nessuna partita.

**Per sito** (mediana a 500 anni, livello 1 → 10): Terrazzo centrale 246 → 1055; Sbocco del fiume 343 → 918; Sperone collinare 179 → 1081; Dosso nelle paludi 300 → 1042; Area dei gessi 127 → 396; Pianura aperta 211 → 988.

## Cosa si vede
1. **La bravura conta, e in modo regolare:** dal livello 1 al 10 gli abitanti finali crescono di oltre quattro volte, senza salti né inversioni. Il gioco premia chi gioca meglio.
2. **I primi 150 anni sono uguali per tutti:** a 100 anni ogni livello è tra 90 e 106 abitanti. Le scelte del giocatore cominciano a pesare solo dopo: nella prima parte della partita la bravura non si vede.
3. **Tetto verso i 300 anni:** tutte le curve si appiattiscono, e negli ultimi 100 anni calano un po' (il massimo raggiunto è sopra il valore finale a ogni livello). Il limite è la terra: il contado arriva al massimo a 800 m, e chi gioca bene lo riempie prima. Gli ultimi due secoli del villaggio scorrono senza crescita.
4. **Il sito pesa quanto la bravura:** nell'area dei gessi il giocatore migliore arriva a 396, meno di un giocatore di livello 3 sul Terrazzo centrale. La fondazione è davvero la decisione più importante.
5. **Carestie frequenti** dal livello 3 in su, circa una ogni 20 anni: chi spinge la crescita vive al limite. Non fanno abbandonare il villaggio, ma pesano sul ritmo meditativo.
6. **Confronto con la realtà:** per Çatalhöyük, il villaggio neolitico più grande conosciuto, le stime recenti (Kuijt e Marciniak, 2024) sono di 600–800 abitanti al massimo, contro i 3.500–10.000 delle stime precedenti. I nostri villaggi dal livello 7 in su lo superano. Quanto fossero grandi i villaggi neolitici comuni dell'Europa non l'ho verificato.

## Idee per gestire la crescita (proposte di Claude, da discutere)
L'obiettivo di Fede: più abitanti è più successo. Le idee cercano di tenerlo insieme alla verosimiglianza, senza togliere al giocatore il gusto di crescere.

1. **Il tetto apre l'epoca successiva.** Il tetto di terra che si vede a 300 anni diventa il motore: quando il villaggio riempie il contado, la pressione porta all'evento soglia "il metallo e lo scambio". Il giocatore bravo ci arriva prima e più grande; quello alle prime armi resta più a lungo nel villaggio. La durata dell'epoca diventa variabile, e gli ultimi due secoli senza crescita spariscono.
2. **Gli abitanti si contano sul territorio, non solo nel villaggio.** Oltre una certa densità le famiglie fondano casali nel contado: è lo sprawl che Fede ha già deciso come crescita di base. Il villaggio resta verosimile (qualche centinaio), il territorio ospita il resto, e nel protourbano i casali si uniscono nel centro (il sinecismo, il modo in cui sono nate molte città antiche). Il successo è la somma. A differenza del villaggio figlio tolto, i casali devono vedersi sulla mappa.
3. **Rendere la bravura visibile fin dall'inizio.** Oggi i primi 150 anni sono uguali per tutti: le prime scelte (sito, zona, caccia e pesca) dovrebbero già cambiare la velocità di crescita, così il giocatore vede subito l'effetto di ciò che fa.

## Registro degli avvisi di cinque partite (25/11/2026)
*Richiesta di Fede: vedere quali avvisi escono a schermo e nella cronaca, quanti sono e quanto pesano le piene.* Script `gioco/test/registro_avvisi.gd` (5 siti, giocatore di livello 5, 500 anni ciascuna).

| Per partita (media) | Quanti | Da cosa |
|---|---|---|
| Pause | 14 | stranieri 6, sorgenti 3, cometa 3, primo cattivo raccolto 1, affollamento 1 |
| Notifiche rosse | 12 | siccità 7, piene disastrose 4–5 |
| Notifiche grigie | 34 | "zona agricola piena" circa 10 (ogni 25 anni dopo il trecentesimo); piene di stagione solo sullo Sbocco del fiume (121 in quella partita) |
| Righe di cronaca | 86 | 29 rosse, quasi tutte "Carestia" |

- A 2 anni al secondo una partita dura circa 4 minuti: una pausa ogni 17 secondi circa.
- Le carestie sono 10–28 per partita, ma quasi tutte di pochi punti (manca l'1–20% del cibo): annate magre più che carestie.
- Le piene disastrose, pensate rare, sono circa 5 per partita su 4 siti su 5, ma pesano poco (34 case perse: circa 85 abitanti e −3 di consenso, recuperati in pochi anni).
- Le piene di stagione allagano in media l'8,6% dei campi una volta ogni 4 anni (circa il 2% del raccolto): oggi sono solo narrazione.
- Il consenso ha un solo effetto, la scissione sotto 5 per 4 anni; nelle cinque partite è sempre finito tra 56 e 63.

Le decisioni che ne sono venute (Fede, 25/11/2026) stanno in `pilastri-e-decisioni.md`, sezione "La prima epoca: dinamiche".

## Dopo le regole del 25/11/2026
*Le dinamiche decise da Fede il 25/11 (`era-origini.md`): abbondanza, tappe, legna, consenso per gruppi, eventi dallo stato della partita.* I giocatori automatici sono gli stessi; ai livelli 1–2 la zona si allarga quando la si vede piena sulla mappa (non c'è più la notifica).

**Registro degli avvisi** (5 partite, livello 5), per partita:
| | 24/11 | 25/11 | Obiettivo |
|---|---|---|---|
| Pause | 14 | 4,8 | 4–5 |
| Notifiche rosse | 12 | 2 | 3–4 |
| Carestie | 10–28 | 0 | 0–3 |
| Righe di cronaca | 86 | 37 | – |

**Sessioni a dieci livelli** (180 partite):
![Abitanti per livello di bravura, 25/11](immagini/sessioni-giocatori-25-11.png)

| Livello | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|
| Abitanti a 500 anni (mediana) | 222 | 278 | 419 | 459 | 540 | 591 | 695 | 722 | 811 | 873 |

- **La bravura conta ancora, in modo regolare**, e senza schiacciare chi gioca poco (livello 1: 222, prima 229).
- **Non c'è più il muro a 300 anni:** la crescita rallenta piano fino ai 450 anni, perché le nascite seguono l'abbondanza e la legna comincia a mancare sui siti con poco bosco.
- **Nessuna carestia** a nessun livello, nessun abbandono: il villaggio non è più punitivo. Forse troppo facile: da guardare nelle prove di Fede (traguardo: 0–3 carestie, solo per cause leggibili).
- **I primi 100 anni sono ancora uguali per tutti** (circa 60 abitanti): è la fase in cui "si mettono le pedine" (Fede, 25/11/2026). Il giocatore automatico non usa le leve dei primi anni (campi a mano, scelta delle fonti); da controllare con le prove vere.
- **Il sito pesa:** al livello 10 Pianura aperta 1168, Sperone 1098, Sbocco 914, Terrazzo 855; Dosso nelle paludi 481 (febbri, salute), Area dei gessi 452.
- **Abitanti ancora sopra l'obiettivo** del nucleo (100–300): servono i casali (tappa dei 250), cioè la scelta su come contare gli abitanti sul territorio, rimandata a epoca completa.

## Giocatori "umani" (25/11/2026)
*Richiesta di Fede: verificare le carestie con un giocatore che non conosce le dinamiche interne, ma impara sbagliando o fermandosi a leggere.* Script `gioco/test/giocatore_umano.gd`: vede solo ciò che vede il giocatore (indicatori rossi, cause dei pannelli di focus, tappe, scelte), stende all'inizio una zona a metà del contado senza guardare il rischio di piena, guarda la partita ogni 10–30 anni, prova i rimedi che le cause suggeriscono, risponde d'istinto alle scelte. Due profili: "sbaglia" (apre i pannelli 3 volte su 10) e "legge" (8 su 10). 36 partite (6 siti × 3 semi × 2 profili).

| Profilo | Abitanti a 500 anni (mediana) | Minimo | Carestie in tutto (18 partite) | Abbandoni | Senza granaio |
|---|---|---|---|---|---|
| Sbaglia | 516 | 216 | 2 | 0 | 9 |
| Legge | 704 | 200 | 0 | 0 | 6 |

- **Il risultato non cambia: le carestie restano quasi assenti** anche per chi sbaglia. Il motivo: quando la terra non basta, l'abbondanza ferma le nascite prima che arrivi la fame (il villaggio ristagna invece di morire), e le scorte coprono una siccità o una piena.
- **Leggere conta:** chi legge i pannelli arriva a circa il 40% di abitanti in più.
- **Un buco trovato:** la causa "mancano case: serve legna" non dice come procurarsela, e non c'è uno strumento per farlo (la legna viene da sola dai boschi vicini e dal dissodamento).

## Quattro giocatori "umani", con legnaia, carestie B + C e casali (25/11/2026, pomeriggio)
*Decisioni di Fede del 25/11/2026: legnaia obbligatoria per raccogliere legna, presagi ignorati che pesano di più e nascite in ritardo (carestie B + C), casali dalla tappa dei 250 abitanti; due profili nuovi: chi conosce il genere ma non legge e va a tentativi, e il casual che ripete gli errori e continua per il gusto di giocare. Le prove con i giocatori "umani" sono la base dei test futuri.* 72 partite (4 profili × 6 siti × 3 semi, 500 anni).

| Profilo | Abitanti a 500 anni (mediana) | Minimo | Carestie per partita | Carestie gravi (in tutto) | Abbandoni | Nucleo (mediana) | Casali (mediana) |
|---|---|---|---|---|---|---|---|
| Impara sbagliando | 743 | 251 | 0.7 | 2 | 0 | 280 | 4.5 |
| Legge le spiegazioni | 707 | 406 | 0.8 | 0 | 0 | 280 | 5 |
| Conosce il genere | 1172 | 502 | 1.3 | 3 | 0 | 280 | 13.5 |
| Casual | 162 | 83 | 2.7 | 0 | 0 | 162 | 0 |

- **Le carestie ci sono, quasi sempre leggere e con una causa leggibile.** Chi conosce il genere ne ha di più perché spinge la crescita (le nascite in ritardo lo portano oltre ciò che la terra regge); il casual ne ha di più perché non allarga la zona e non costruisce il granaio, ma il villaggio non muore: cresce lento fino a circa 160 abitanti e si continua a giocare.
- **Il nucleo resta entro i 280 abitanti**, il resto nei casali.
- **La legna è un limite vero:** una legnaia lontana dal bosco tiene il villaggio affollato; chi conosce il genere ne costruisce subito una vicino al bosco e un'altra quando rende poco.
- **Correzioni fatte durante la prova:** senza granaio le scorte si guastavano del 35% l'anno e le nascite in ritardo tenevano i villaggi sotto i 60 abitanti, la tappa del granaio (una trappola): ora il 30%; cibo che avanza pieno a 18 mesi (prima 24) e soglia della crescita a 60 (prima 62); le famiglie mettono nel conto il danno della selvaggina ai campi al margine del bosco; anche le paludi danno un po' di legna (metà del bosco).
- **Da guardare:** chi conosce il genere arriva a 1172 abitanti in tutto, sopra l'obiettivo di 600–800; chi impara sbagliando ha 0,7 carestie a partita (obiettivo 1–3).

## Dopo zona di taglio, campi che si stancano e ritmo calmo (25/11/2026, sera)
*Decisioni di Fede del 25/11/2026 pomeriggio: si ferma solo per le scelte che chiedono un intervento, il resto in cronaca; velocità 1 a un anno al secondo; zona di taglio con ceduo; campi che si stancano per limare le popolazioni dei siti migliori.* 72 partite con i quattro giocatori "umani" (500 anni).

| Profilo | Abitanti (mediana) | Massimo | Minimo | Carestie per partita | Abbandoni | Pause (mediana) |
|---|---|---|---|---|---|---|
| Impara sbagliando | 432 | 952 | 132 | 2.6 | 0 | 4 |
| Legge le spiegazioni | 545 | 1019 | 203 | 1.3 | 0 | 4 |
| Conosce il genere | 763 | 1081 | 227 | 2.1 | 0 | 4 |
| Casual | 102 | 451 | 47 | 1.7 | 0 | 4 |

**Registro degli avvisi** (5 partite, livello 5), per partita: **3,4 pause** (sorgenti 1,8, primo arrivo degli stranieri 1, cometa 0,6), 0,6 notifiche rosse (scorte quasi finite), 3,8 grigie (quasi tutte tappe), **42 righe di cronaca** (dopo aver tolto le righe delle legnaie che si fermano e ripartono da sole, 43 a partita, e alzato la soglia delle febbri gravi). A un anno al secondo una partita dura circa 8 minuti e mezzo: una pausa ogni due minuti e mezzo circa.

- **Popolazioni rientrate:** la mediana di chi conosce il genere passa da 1172 a 763 (dentro l'obiettivo di 600–800); i massimi restano sopra (circa 1000–1080).
- **Carestie:** chi impara sbagliando 2,6 a partita (obiettivo 1–3), chi legge 1,3 (obiettivo 0–1, poco sopra), nessun abbandono.
- **Il casual** resta piccolo (mediana 103, minimo 47): la legna e i campi stanchi pesano su chi non costruisce e non allarga. Da guardare con Fede: il casual deve potersi divertire.

## Con capanno da pesca e posta di caccia (25/11/2026, sera tardi)
*Decisioni di Fede del 25/11/2026: senza edifici caccia e pesca rendono un terzo; capanno solo sulla riva, posta al margine del bosco; pesce e selvaggina locali.* I giocatori automatici imparano i due edifici (`test/aiuti_giocatori.gd`, `costruisci_edificio_risorse`): chi conosce il genere li fa subito nel punto con la resa stimata più alta e ne aggiunge quando non bastano (fino a 3); chi legge li costruisce dopo aver letto la causa nel pannello del Cibo ("Senza posta di caccia…", "Senza capanno da pesca…"); chi sbaglia e il casual provano il tasto nuovo all'inizio, 4–5 volte su 10, il casual dove capita. 72 partite (500 anni).

| Profilo | Abitanti (mediana) | Massimo | Minimo | Carestie per partita | Carestie gravi | Abbandoni | Poste / capanni (mediana) |
|---|---|---|---|---|---|---|---|
| Impara sbagliando | 433 (prima 432) | 967 | 109 (132) | 2.5 (2.6) | 0 | 0 | 1 / 0 |
| Legge le spiegazioni | 555 (545) | 909 | 130 (203) | 2.4 (1.3) | 2 | 0 | 1 / 0 |
| Conosce il genere | 748 (763) | 1081 | 271 (227) | 2.3 (2.1) | 2 | 0 | 3 / 3 |
| Casual | 110 (102) | 453 | 43 (47) | 2.7 (1.7) | 1 | 0 | 0 / 0 |

**Registro degli avvisi** (5 partite, livello 5), per partita: 3,6 pause (prima 3,4), 0,8 notifiche rosse (0,6), 4 grigie (3,8), 47 righe di cronaca (42; le righe in più sono "si comincia a costruire" e "è pronta" dei due edifici).

- **Le popolazioni non cambiano:** chi costruisce gli edifici recupera ciò che perde chi non li costruisce.
- **Le carestie salgono dove si vive di caccia:** quasi tutte all'Area dei gessi (fertilità scarsa) e allo Sperone collinare (bosco ricco, nessun fiume per il capanno): per chi legge 8 a partita ai gessi e 6 allo Sperone, quasi nessuna altrove. Chi legge costruisce la posta solo dopo aver visto il Cibo rosso, cioè dopo la prima fame. Anche chi conosce il genere, con tre poste, ai gessi ha circa 8 carestie a partita: la selvaggina attorno alle poste cala.
- **Da decidere con Fede:** lasciare così (sono siti di caccia, sfavorevoli per scelta), oppure alzare la resa delle poste (oggi 35 di cibo l'anno al massimo) o la ripresa della selvaggina, oppure far dire alla fondazione che caccia e pesca chiedono gli edifici.
- Foto nel gioco: `docs/immagini/capanno-nel-gioco-25-11.jpg` (capanno sulla riva del torrente al Terrazzo centrale, con la lettura dell'edificio) e `docs/immagini/posta-nel-gioco-25-11.jpg` (posta al margine del bosco).

## Con luogo sacro, sacerdote e bosco sacro (25/11/2026, notte)
*Decisioni di Fede del 24–25/11/2026, numeri proposti da Claude e approvati da Fede.* I giocatori automatici imparano i due strumenti:
- chi conosce il genere erige il luogo sacro appena la tappa lo apre e c'è la legna, e stende circa 10 ettari di bosco sacro nel bosco più vicino;
- gli altri lo fanno dopo la notifica della tappa (6 volte su 10, il casual 3) o dopo aver letto le cause del Consenso;
- nelle sessioni a dieci livelli il luogo sacro arriva dal livello 3 e il bosco sacro dal 5.

72 partite (500 anni).

| Profilo | Abitanti (mediana) | Massimo | Minimo | Carestie per partita | Carestie gravi | Abbandoni | Luogo sacro eretto | Bosco sacro (mediana) | Sacerdote (mediana) |
|---|---|---|---|---|---|---|---|---|---|
| Impara sbagliando | 458 (prima 433) | 887 | 120 | 2.6 (2.5) | 3 | 0 | 6 su 18 | 0 ha | 58 |
| Legge le spiegazioni | 599 (555) | 1112 | 112 | 2.3 (2.4) | 0 | 0 | 7 su 18 | 2,6 ha | 60 |
| Conosce il genere | 729 (748) | 1006 | 252 | 2.7 (2.3) | 6 | 0 | 18 su 18 | 9,3 ha | 71 |
| Casual | 117 (110) | 614 | 43 | 2.0 (2.7) | 0 | 0 | 2 su 18 | 0 ha | 63 |

**Registro degli avvisi** (5 partite, livello 5), per partita: 3,6 pause (come prima), 1 notifica rossa (0,8), 4 grigie, 48 righe di cronaca (47).

- **Le dinamiche reggono:** popolazioni, carestie e pause restano dove erano, con le differenze dovute al caso.
- **Il sacerdote è contento quando lo si cura:** chi conosce il genere, con luogo sacro e bosco sacro di quasi 10 ettari, lo tiene a 71, quindi ha meno presagi falsi. Chi non lo cura lo lascia intorno a 58–60.
- **Chi legge erige il luogo sacro poco** (7 su 18), perché la causa "si può erigere il luogo sacro" sta nel pannello del Consenso, che si apre solo quando il consenso è rosso. Va guardato con Fede se serve un richiamo in più, per esempio nella notifica della tappa, che oggi lo nomina già.

## Sacerdote contrariato senza luogo sacro, poi pascolo e animali (26/11/2026, mattina)
**Sacerdote** (decisione di Fede del 25/11/2026 sera: contrariato finché il luogo sacro non è eretto), 72 partite: mediane 503, 599, 729, 121 abitanti; carestie 2,8, 2,3, 2,7, 2,0 a partita; nessun abbandono. Chi non erige il luogo sacro lascia il sacerdote a 35–37, quindi con presagi ambigui; chi conosce il genere lo tiene a 71. **Chi legge erige ancora il luogo sacro solo 7 volte su 18:** il consenso complessivo non diventa rosso, perché il sacerdote pesa 0,2, e quindi il pannello con la causa non si apre. Se Fede vuole spingere di più, il "Il sacerdote chiede un luogo sacro" può diventare una notifica grigia invece di una riga di cronaca.

**Pascolo e animali** (decisioni di Fede del 25/11/2026), 72 partite. I giocatori automatici stendono il pascolo dopo la notifica della tappa (chi conosce il genere sempre, 15 ettari, e lo allarga quando l'erba finisce; gli altri 6 volte su 10, il casual 4) o dopo le cause degli Animali.

| Profilo | Abitanti (mediana) | Massimo | Minimo | Carestie per partita | Carestie gravi | Abbandoni | Capi (mediana / massimo) | Pascolo (mediana) | Partite con pascolo |
|---|---|---|---|---|---|---|---|---|---|
| Impara sbagliando | 616 | 912 | 103 | 2.7 | 3 | 0 | 17 / 23 | 5,6 ha | 12 su 18 |
| Legge le spiegazioni | 454 | 1127 | 110 | 2.5 | 0 | 0 | 13 / 23 | 0 ha | 8 su 18 |
| Conosce il genere | 742 | 999 | 211 | **1.6** (prima 2,7) | 3 | 0 | 49 / 72 | 44 ha | 18 su 18 |
| Casual | 116 | 646 | 43 | 2.2 | 0 | 0 | 12 / 20 | 0 ha | 4 su 18 |

**Registro** (5 partite): 4,2 pause per partita (presagi e stranieri, dovute al caso), 0,8 notifiche rosse, 4 grigie; le righe "si macellano" erano 5–6 a partita, anni di fila: ora al massimo una ogni 5 anni.

- **La scorta viva funziona:** chi tiene una mandria grande passa da 2,7 a 1,6 carestie a partita.
- **Mandrie piccole:** chi non stende il pascolo resta sui 12 capi attorno alle case; con 44 ettari si arriva a 50–70. La portata (2 capi per ettaro di prato) si può alzare se Fede vuole mandrie più grandi.
- La mediana di chi legge (454 contro 599) oscilla molto da una prova all'altra: il massimo e il minimo restano gli stessi.

## Con i tutorial alle tappe (26/11/2026, tarda mattinata)
**Tutorial** (decisione di Fede del 26/11/2026), 72 partite: i giocatori "umani" accendono i tutorial come la partita e li contano a parte dalle pause. Chi impara sbagliando e chi legge li leggono tutti (15–16 riquadri a partita: fondazione, i sette strumenti di partenza, granaio e raccolto, luogo sacro e pascolo, stranieri, affollamento e bosco sacro, casali); chi conosce il genere li salta al primo; il casual ne legge un paio e poi salta.

Le dinamiche non cambiano: mediane 616, 454, 742, 116 abitanti; carestie 2,7, 2,5, 1,6, 2,2 a partita; pause vere 3,7–3,9 a partita, come stamattina. **Registro** (5 partite, livello 5): 4,2 pause vere a partita e 15 riquadri di tutorial, tutti in cinque momenti (inizio, fondazione e le quattro tappe).

- I tutorial si concentrano all'inizio: 8 riquadri prima che il tempo cominci a scorrere, poi 2–3 a ogni tappa.
- I giocatori automatici non imparano ancora dai tutorial (chi legge erige il luogo sacro 7 volte su 18, come prima): si potrà far leggere loro il riquadro del luogo sacro come si fa con le cause dei pannelli.

## Con le scorrerie e la torre di avvistamento (26/11/2026, sera)
**Giocatori "umani"** (72 partite, 3 semi): i giocatori rispondono alla prima scelta sui segni d'istinto (chi legge protegge di più), provano la torre quando vedono i segni o quando il pannello degli Animali dice che il rischio è alto.
| Profilo | Mediana abitanti | Carestie | Pause vere | Scorrerie a partita | Case bruciate (in tutto) | Torri |
|---|---|---|---|---|---|---|
| impara sbagliando | 599 (prima 616) | 2,8 (2,7) | 4,3 | 0,94 | 3 | 0 |
| legge | 561 (454) | 3,0 (2,5) | 4,2 | 0,94 | 3 | 0 |
| conosce il genere | 778 (742) | 2,2 (1,6) | 4,6 | 1,22 | 6 | 1 |
| casual | 116 (116) | 2,2 (2,2) | 3,9 | 0,39 | 0 | 0 |

Per sito, scorrerie a partita: Sbocco del fiume 1,67, Pianura aperta 1,17, Terrazzo centrale 0,92, Sperone collinare 0,83, Dosso nelle paludi 0,42, Area dei gessi 0,25. **Cosa si vede:** circa una scorreria ogni 500 anni nei villaggi avviati, di più nei siti bassi e aperti, quasi mai per chi resta piccolo; le carestie salgono un poco per chi legge e chi conosce il genere (le scorte rubate); le pause vere salgono di circa mezza a partita (la prima scelta sui segni). La torre si fa di rado: solo quattro siti hanno un'altura entro 1200 m (Sperone collinare 25 punti adatti su 96, Area dei gessi 34, Sbocco del fiume 6, Terrazzo centrale 3; Dosso nelle paludi e Pianura aperta nessuno).

**Registro degli avvisi** (5 partite, livello 5): nessuna scorreria (il giocatore automatico del registro non stende il pascolo, quindi la ricchezza resta bassa); 4,2 pause vere e 16 riquadri di tutorial a partita, come prima.

