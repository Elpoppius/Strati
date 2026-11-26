# Todo — Villaggio completo (prima epoca)

*Aperto il 24/11/2026 su richiesta di Fede: chiudere la prima epoca prima di passare all'abitato protourbano (principio: prima la profondità, poi l'ampiezza). Riorganizzato il 25/11/2026 (richiesta di Fede) perché **chi riprende, con l'altro account, sappia cosa fare senza la conversazione**. Riferimenti di design: `era-origini.md` (l'Era delle Origini, con tutte le decisioni e i traguardi) e `pilastri-e-decisioni.md`.*

Legenda: `[x]` fatto · `[~]` in parte · `[ ]` da fare · **(?)** serve una decisione di Fede prima di cominciare.

## Come si lavora (vale per ogni voce)
1. **Prima di toccare il codice:** riepilogo a Fede di cosa si farà e attesa del suo ok (è una sua regola). Le proposte non confermate si segnano come tali.
2. **Dopo:** tutte le 9 verifiche (`CLAUDE.md`, "Comandi utili"); poi, se la voce tocca le dinamiche, le prove con i **giocatori "umani"** (`test/giocatore_umano.gd`, quattro profili: è la base dei test, decisione di Fede del 25/11/2026) e il **registro degli avvisi** (`test/registro_avvisi.gd`) per il ritmo. I giocatori automatici devono imparare a usare ogni strumento nuovo: i gesti comuni stanno in `test/aiuti_giocatori.gd`.
3. **Traguardi** da rispettare (`era-origini.md`, § 9): circa 2–3 pause a partita (si ferma solo per le scelte), poche notifiche, carestie rare e leggibili, nessun abbandono al livello medio, nucleo 100–300 abitanti, territorio fino a 600–800 per chi gioca molto bene.
4. **Alla fine:** voce in cima al diario, todo aggiornato, commit e push.

## A che punto siamo (26/11/2026, mattina)
Fatte e collaudate le basi della prima epoca e le voci 0 (cantieri visibili), 1 (capanno e posta), 3 (luogo sacro, sacerdote, bosco sacro) e 8 (mappe tematiche). Restano le voci 2, 4, 5, 6, 7, 9.

**Stime riviste** (richiesta di Fede del 25/11/2026). Tempi veri del 25/11, dall'ok di Fede al push, presi dai commit:

| Lavoro | Stima di prima | Tempo vero |
|---|---|---|
| 1. Capanno e posta (con 72 partite umane e registro) | 1,5–2 ore | 1 ora e 13 minuti (di cui circa 25 di partite) |
| 0. Cantieri visibili (cinque scheletri, barra, prove) | 30–60 minuti | 13 minuti |
| 8. Mappe tematiche (tre mappe, shader, legende, prove) | 2–3 ore | 17 minuti |
| 3. Luogo sacro, sacerdote, bosco sacro (con partite umane e registro) | 2–3 ore | 41 minuti (di cui circa 25 di partite) |
| Sacerdote contrariato senza luogo sacro | — | 12 minuti (partite interrotte) |

Le stime di prima erano da 2 a 8 volte troppo alte: erano pensate come ore di lavoro di una persona. Il costo fisso vero è quello delle prove, circa **25 minuti di partite umane e registro** per ogni voce che tocca le dinamiche; le foto di controllo prendono 2–3 minuti l'una. Il resto del tempo lo prendono le conferme e le prove di Fede.

| Voce | Stima rivista (prove comprese) |
|---|---|
| 0, 1, 3, 8 | **fatte** (25/11/2026) |
| 2. Pascolo e bestiame visibile | 1,5–2 ore (simulazione 30–45 min, modelli e animali sulla mappa 30–45 min, prove 25 min) |
| 4. Scorrerie | 40–60 minuti |
| 5. Sentieri che diventano strade | 40–60 minuti |
| 6. Evento soglia e passo elastico | 1,5–2,5 ore (la più delicata: il passo a decenni tocca tutte le regole "per anno") |
| 7. Popolazione visibile | 1,5–2 ore (serve una prova di Fede per i fotogrammi al secondo) |
| 9. Base tecnica | 1–1,5 ore (salvataggio, acqua che sale, varianti; più le prove sui PC di Fede) |

In tutto **7–10 ore di lavoro di Claude**, cioè 2–3 giornate, più le conferme e le prove di Fede (che oggi sono la parte più lunga), poi la prova fisica e le correzioni.

## Per chi riprende: il lavoro in ordine

### 0. [x] Cantieri visibili (richiesta di Fede del 25/11/2026 sera)
**Fatto** il 25/11/2026 sera. Deciso da Fede: sopra ogni edificio in costruzione una **barra discreta** che avanza anno dopo anno, e al posto dell'edificio finito il suo **scheletro** (stessa struttura, solo pali e travi, con materiali e attrezzi accanto; scelto da Fede tra cantiere unico e scheletro di ogni edificio). Modelli `cantiere_granaio`, `cantiere_legnaia`, `cantiere_capanno_pesca`, `cantiere_posta_caccia` (`villaggio.py`, foto `docs/immagini/cantieri-25-11.jpg`); barra `shader/barra_cantiere.gdshader` (foto `docs/immagini/barra-cantiere-25-11.jpg`). **Il luogo sacro (voce 3) avrà il suo scheletro** in `VistaVillaggio.CANTIERI`. Le case nascono da sole, senza cantiere.
*Ordine proposto da Claude il 25/11/2026; le voci sono già approvate da Fede nei contenuti, salvo dove c'è (?).*

### 1. [x] Capanno da pesca e Posta di caccia
**Fatto il 25/11/2026 sera** (regole e numeri in `prototipo0-godot.md`, prove in `sessioni-giocatori.md`): senza edifici un terzo, con l'edificio pieno (35 di cibo l'anno al massimo); aggancio alla riva (capanno) e al margine del bosco (posta) anche nella simulazione senza grafica; pesce e selvaggina in riquadri di 200 m; strumenti con anteprima agganciata e lettura; cause nel pannello del Cibo; i giocatori automatici li costruiscono. Restano le due domande in "Da decidere con Fede" (carestie nei siti di caccia, aggancio e tasti della posta). Sotto, le note di lavoro di prima.
**Deciso** (Fede, 25/11/2026): stessa dinamica della legnaia; senza questi edifici caccia e pesca non spariscono ma rendono circa un terzo.
- **Capanno da pesca** (germe dell'approdo e del porto): **solo sulla riva** (Fede, 25/11/2026, come i moli: aggancio automatico al punto di riva più vicino entro circa 30 m, girato verso l'acqua; fuori dalla palude; anteprima già agganciata, rossa con "Serve la riva di un fiume o di un torrente" se non c'è riva); **nessuna distanza minima tra capanni** (Fede: chi ne ammassa tanti esaurisce il pesce di quel tratto, è una scelta sua). **Deciso** (Fede, 25/11/2026, su proposta di Claude): il pesce diventa locale per tratto di riva, come la selvaggina attorno alla posta: più capanni vicini se lo dividono, troppi lo fanno calare, e si riprende in qualche anno se lasciato stare; rende di più vicino all'acqua e secondo il tipo d'acqua (fiume più dei torrenti, poco le paludi).
- **Posta di caccia**: al margine del bosco; rende di più dove il bosco è fitto e la selvaggina abbondante. **La selvaggina diventa locale** attorno alla posta: se si caccia troppo lì cala, e conviene spostarsi (oggi `selvaggina` è un numero unico per il villaggio).
- **Come farlo:** copiare l'impianto della legnaia in `script/sim_villaggio.gd` (`motivo_legnaia`, `costruisci_legnaia`, `capacita_legnaia`, `_lavora_legnaie`, `stato_legnaia`); oggi caccia e pesca sono calcolate in `passo()` da `_risorse` (bosco e acqua attorno al centro) con `QUOTA_CACCIA`, `QUOTA_PESCA`, `RESA_BOSCO`, `RESA_ACQUA`. In `script/partita.gd`: `STRUMENTI`, menu Edifici, `_applica`, `leggi_per_strumento` (lettura sotto il puntatore), `_raggio_strumento`; tasti liberi in `script/principale.gd` (oggi usati: Z, C, V, H, L, X, P, G, I, F, Y). Icone SVG in `gioco/asset/icone/` (stile di `legnaia.svg`). Disegno in `script/vista_villaggio.gd` (come `_sincronizza_legnaie`, modelli da `asset/villaggio/`). Cause nel pannello di focus del Cibo (`cause_di("Cibo")`). Le fonti di cibo nelle politiche restano.
- **Icone già pronte** (25/11/2026): `asset/icone/capanno_pesca.svg` (pesce sopra un'onda) e `posta_caccia.svg` (palco di corna); anteprima `docs/immagini/icone-risorse-25-11.png`.
- **Modelli fatti** (25/11/2026, `strumenti/blender/villaggio.py`, descrizioni di Claude accettate da Fede):
  - **Capanno da pesca** (`capanno_pesca()`, `asset/villaggio/capanno_pesca.glb`, foto `docs/immagini/modello-capanno-pesca-25-11.jpg`): canne, tetto a due falde, rastrelliera con rete e pesci, piroga, nasse. L'acqua è verso +y del modello.
  - **Posta di caccia** (`posta_caccia()`, `asset/villaggio/posta_caccia.glb`, foto `docs/immagini/posta-caccia-margine-25-11.jpg`): riparo basso a una falda coperto di frasche fresche e secche, giaciglio, rastrelliera con una pelle tesa, pelle a terra coi picchetti, piccolo focolare, palo con il palco di corna, due lance. La schiena del riparo è verso +y del modello, da girare verso il bosco.
- **Posa provata** con `test/foto_posa.gd -- uscita capanno|posta dimensione rotazioni` (da riusare nello strumento e in `vista_villaggio.gd`):
  - capanno: terra asciutta a circa 2 m dall'acqua (`alberi.distanza_acqua(x, z)`), fuori dalla palude, poco inclinata; verso l'acqua contro il gradiente della distanza dalla riva (foto `docs/immagini/capanno-riva-25-11.jpg`);
  - posta: appena fuori dal bosco (`alberi.valore_bosco` circa 0,4), asciutta, poco inclinata; verso il bosco lungo il gradiente del valore del bosco;
  - rotazione del modello `atan2(-v.x, -v.y)`, con `v` la direzione verso l'acqua o il bosco; togliere gli alberi attorno in un cerchio un po' largo (un pioppo della riva nascondeva il capanno).
- **Note sui modelli:** dopo l'importazione, nei `.import` delle texture tenere `detect_3d/compress_to=0`; `villaggio.py` riesporta tutti i modelli e `fossa_silo.glb` cambia senza motivo: rimetterlo com'era con `git checkout`. Le falde dei tetti si creano nell'origine, si inclinano e poi si spostano. A ogni modello nuovo, mostrare la foto a Fede (la direzione artistica è sua).
- **Prove:** verifiche nuove in `test/verifica_villaggio.gd` (senza edificio un terzo, con l'edificio pieno, vicinanza); i giocatori automatici costruiscono gli edifici (aggiungere a `aiuti_giocatori.gd` e ai profili: chi conosce il genere subito e nel punto giusto, il casual dove capita); poi giocatori "umani" e registro. Attenzione: togliere due terzi di caccia e pesca a chi non costruisce cambia la crescita dei primi decenni.

**Da fare all'inizio della prossima sessione:** rifare `test/giocatore_umano.gd` dopo il sacerdote contrariato senza luogo sacro (25/11/2026 notte, partite interrotte per il limite di utilizzo; registro e verifiche del villaggio superati) e aggiornare `sessioni-giocatori.md`.

### 2. [~] Pascolo e animali (con il bestiame visibile)
**Fatto il 26/11/2026 mattina** (regole e numeri in `prototipo0-godot.md`): zona di pascolo a pennello con l'opzione Togli (anche per la zona agricola), capi con portata e crescita, stoppie e maggese, radure aperte, scorta viva, stranieri con animali, erosione sui pendii, disuguaglianza, indicatore e pannello Animali, stabbio e animali (pecora, capra, maiale, bue) in greggi sulla mappa, giocatori automatici, prove. **Resta:** il campo stanco visibile (proposta sotto, da confermare con Fede) e la prova di Fede dei fotogrammi al secondo con le greggi. Le vie degli animali arrivano con la voce 5, le scorrerie attirate dagli animali con la voce 4.
**Deciso** (Fede, 25/11/2026, `era-origini.md` § 4 "I cicli"): si apre a 100 abitanti. Concime ai campi vicini, scorta viva per le annate cattive, radure che restano aperte, erosione e piene se troppo pascolo sui pendii, ricchezza delle famiglie, vie degli animali come traffico sui sentieri, animali che attirano le scorrerie.
**Deciso** (Fede, 25/11/2026 sera, sulle domande di Claude):
1. **Zona di pascolo a pennello**, come la zona agricola: le famiglie portano gli animali da sole.
2. **Dove:** prati e radure, margini del bosco (il pascolo impedisce la ricrescita), e i **campi stanchi dentro la zona di pascolo diventano maggese da soli** (concimati, si riposano più in fretta); zona di pascolo e zona agricola possono sovrapporsi. **Requisito di Fede: si deve vedere sulla mappa quando un campo è stanco.**
3. **Un solo numero di "capi"**, con un misto di specie che si vede (pecore e capre soprattutto, maiali vicino al bosco, qualche bue). **Requisito di Fede: va gestito come cresce il numero dei capi.**
4. **Scorta viva:** nelle annate cattive gli animali si macellano da soli (niente pausa, una riga in cronaca); la mandria si ricostituisce negli anni buoni.
5. **Gli animali seguono la politica del raccolto** (in comune o alle famiglie): alle famiglie la mandria cresce di più, ma cresce la disuguaglianza (prepara le famiglie eminenti dell'epoca 2).
- **Deciso** (Fede, 25/11/2026 sera: "le due zone si parlano, ma non entrano in conflitto"):
  - **Campi nella zona di pascolo:** su un campo coltivato gli animali non entrano finché il grano è in piedi; dopo il raccolto pascolano le **stoppie** (poca erba e un po' di concime, che l'anno dopo migliora un poco la resa). Un campo stanco o incolto diventa **maggese**: gli animali ci stanno tutto l'anno (molta erba, concime, riposo più rapido); quando torna buono le famiglie lo riprendono a coltivare da sole. Il campo resta sempre un campo.
  - **Opzione "Togli"** negli strumenti Zona agricola e Pascolo (come "Collega alla rete" per i sentieri): con l'opzione accesa il pennello toglie la zona e lascia campi e animali dove sono. Oggi la zona si toglie solo con Demolisci, che toglie anche i campi.
- **Deciso** (Fede, 25/11/2026 sera, proposta di Claude) **Crescita dei capi:** alla tappa dei 100 abitanti il villaggio ha una decina di capi (gli animali che i fondatori tengono attorno alle case); la mandria cresce di circa il 10% l'anno finché c'è erba, cioè fino alla portata della zona di pascolo (circa 2 capi per ettaro di prato, meno nel bosco, di più sui campi a maggese); oltre la portata smette di crescere, e sui pendii il troppo pascolo dà erosione; gli stranieri accolti portano i loro animali; nelle annate cattive se ne macella quanto serve. Pannello di focus "Animali" con capi, portata ed erba.
- **[Proposta di Claude, da confermare] Campo stanco sulla mappa:** il campo si schiarisce e si riempie di erbacce man mano che si stanca (un valore per cella passato allo shader del terreno, come le tecniche dei campi in `UsoSuolo.tecniche`); nella mappa della Fertilità i campi stanchi si vedono più poveri; un campo a maggese ha l'erba e gli animali.
- **Icona già pronta:** `asset/icone/pascolo.svg` (graticcio con un ciuffo d'erba). **Modello da fare:** uno **stabbio**, recinto basso di graticcio per la notte, con un abbeveratoio di tronco scavato; qualche stabbio sparso nella zona la rende riconoscibile (è diverso dal recinto urbano dell'epoca 2). In `villaggio.py` c'è già `recinto_animali()` da cui partire.
- **Come farlo:** zona di pascolo come `zona` in `sim_villaggio.gd` (`aggiungi_zona`, `zona_piena`) e nel pennello di `principale.gd`; `stanchezza` e `fattore_stanchezza` ci sono già. Modelli degli animali con Blender (`strumenti/blender/`, stile in `docs/asset.md`), disegno con MultiMesh e animazione dallo shader (come gli alberi). Prove: verifiche, giocatori "umani" (devono imparare a stendere il pascolo), registro.

### 3. [x] Luogo sacro, sacerdote e bosco sacro
**Fatto il 25/11/2026 sera** (regole e numeri in `prototipo0-godot.md`; numeri proposti da Claude e approvati da Fede): luogo sacro in Edifici (tasto O, 20 di legna, 3 anni, entro 400 m, uno solo, con il suo scheletro), sacerdote come terzo gruppo dalla tappa dei 100 abitanti, contrariato finché il luogo sacro non è eretto (Fede, 25/11/2026 sera), presagi più chiari o ambigui, bosco sacro a pennello in Territorio (tasto B, pieno da 10 ha), legnaie e famiglie che non lo toccano, offesa se si taglia, case attirate. Sotto, le decisioni di partenza.
**Deciso:** cerchio di pali attorno a una pietra (forma confermata il 24/11/2026); si apre a 100 abitanti; costa legna e braccia con un cantiere. Il sacerdote diventa il terzo gruppo di consenso (`sacerdote_attivo` in `sim_villaggio.gd`, pesi 0,4/0,4/0,2 già pronti): contento, presagi più chiari; scontento, ambigui e con più voci false. Il **bosco sacro** (tappa dei 150) è la riserva: le legnaie non lo tagliano, tagliarlo offende il sacerdote. Il luogo sacro attira le case (germe della piazza).

### 4. [ ] Scorrerie
**Deciso:** attirate dalla ricchezza visibile (animali, scorte) e dai margini del contado poco usati; prima arrivano segni (fuochi sulle colline, tracce, villaggi vicini razziati); difendono il sito (colle, dosso) e un abitato compatto; i casali sparsi sono più esposti; si perdono animali e scorte, a volte case ai margini; cala il consenso degli anziani. Solo in cronaca, salvo le scelte che chiedono un intervento. Sono il ponte verso il recinto dell'epoca 2.

### 5. [ ] Sentieri che diventano strade
**Deciso:** il traffico (campi, pascoli, legnaie, luogo sacro, casali) fa dei sentieri più battuti le prime strade, che restano come assi nelle epoche dopo. Si apre a 250 abitanti con i casali.

### 6. [ ] Evento soglia "il metallo e lo scambio" e passo elastico
**Deciso** (`era-origini.md` § 2 e § 5): si apre quando il territorio è pieno e si è dentro la finestra (~3000–1800 a.C.); presagi (oggetti di rame, mercanti), dilemma aprirsi o restare isolati, transizione con riepilogo. **Passo elastico:** un anno per passo nei primi quattro secoli, poi un decennio (le regole vanno scritte per anno e moltiplicate per il passo). Oggi la partita finisce a 5500 a.C. (`ANNO_FINE`).

### 7. [ ] Popolazione visibile
**Deciso** (25/11/2026): ogni figura fa un lavoro vero della simulazione (campi, bosco, fiume, pascolo, cantieri, sentieri, luogo sacro); **3 modelli di uomini e 3 di donne** che si ripetono, con capelli, incarnato e vesti che variano; animazioni dallo shader; MultiMesh; si vedono solo da vicino; **scala da verificare con la simulazione** (800 persone a schermo sono troppe: tetto di figure visibili, una figura per 1, 2 o 5 persone). Clic su una persona: la scheda della sua famiglia. Prima il bestiame (voce 2), poi i lavoratori, poi chi cammina, poi la scheda.

### 8. [x] Mappe tematiche (ok di Fede del 25/11/2026)
**Fatto il 25/11/2026 sera** (descrizione in `prototipo0-godot.md` e `hud.md`), tasti 6, 7, 8:
- **6 · Caccia e pesca** (Fede: il pesce nella stessa mappa, come cibo): bosco colorato dalla selvaggina, acque dal pesce, cerchi di poste e capanni, zone di taglio marcate.
- **7 · Abitato e contado**, distinti (decisione del 24/11/2026), con i casali.
- **8 · Memoria del suolo**: dove c'era il bosco, suolo sigillato, rovine.

### 9. [ ] Base tecnica
- Salvataggio della partita, con l'uso del suolo.
- Livelli dell'acqua che salgono con le piene, nella grafica.
- Varianti dei modelli del villaggio.
- Prove sui PC di Fede: tempi degli alberi e fotogrammi al secondo.

## Da decidere con Fede
- Carestie nei siti di caccia (25/11/2026 sera): chi legge passa da 1,3 a 2,4 carestie a partita, quasi tutte all'Area dei gessi e allo Sperone collinare. **Si lascia così** (Fede, 25/11/2026): nei siti che vivono di caccia le carestie sono normali.
- **Confermate da Fede** (25/11/2026): la posta si aggancia al margine del bosco entro 60 m; tasti K (capanno) e T (posta); 35 di cibo l'anno al massimo per edificio, posta fino a 1000 m, capanno fino a 600 m.
- **(?)** Popolazioni: con i campi che si stancano le mediane sono rientrate (chi conosce il genere 763), i massimi restano a 1000–1080; il casual resta piccolo (mediana 103): **si lascia così per ora** (Fede, 25/11/2026).
- Carestie per chi impara sbagliando: 2,6 a partita, dentro l'obiettivo 1–3 (25/11/2026 sera); chi legge 1,3 (poco sopra 0–1).
- Politica "Caccia regolata": **non si fa per ora** (Fede, 25/11/2026): con la Posta di caccia e la selvaggina locale il giocatore regola già la caccia; si riprende solo se le prove mostrano ancora troppa caccia.
- **Orti più piccoli:** decisi (Fede, 25/11/2026) **solo come aspetto, nella fase grafica**: il quadrato da 40 m resta l'unità della simulazione, ma si disegna diviso in 2–4 appezzamenti con colture e colori diversi.
- **(?)** Come contare gli abitanti sul territorio (idee 1 e 2 di `sessioni-giocatori.md`): con i casali la scelta è in parte fatta; il resto a epoca completa.
- **(?)** Dimensioni degli edifici delle risorse: legnaia, capanno e posta sono piccoli accanto alle case lunghe (6–8 m); se Fede li vuole più grandi si ingrandiscono tutti insieme.
- Prova fisica di Fede: al termine del villaggio (decisione del 25/11/2026), quando le voci sopra sono fatte e validate dalle prove di Claude.

## Fatto
- **24/11/2026 e prima:** fondazione con lettura del sito, rovine e rifondazione; zona agricola e campo a mano; contado che cresce; sentieri con anteprima; granaio; politiche (raccolto, stranieri, fonti di cibo); ammodernamento (spento nel villaggio); economia mista; piene, siccità, presagi; abitato spontaneo, demolizione; notifiche discrete; sessioni automatiche a dieci livelli.
- **25/11/2026** (dettagli in `diario.md`, `era-origini.md`, `prototipo0-godot.md`, `sessioni-giocatori.md`):
  - Era delle Origini definita (cronologia, nomenclatura "genti" più il luogo, modulo delle due epoche, eventi soglia).
  - Ritmo: si ferma solo per le scelte che chiedono un intervento, il resto in cronaca; velocità 1 a un anno al secondo; affollamento come politica.
  - Abbondanza (cibo che avanza, salute, spazio) con nascite in ritardo; tappe permanenti (60, 100, 150, 250).
  - Consenso di anziani e famiglie con effetti graduali.
  - Legna: legnaia obbligatoria, taglio visibile, **zona di taglio** che resta aperta finché la legnaia lavora, ceduo, "Lasciar ricrescere".
  - Carestie B + C; piene che fertilizzano (limo); febbri; **campi che si stancano**; casali dalla tappa dei 250.
  - HUD: indicatori Abbondanza, Consenso, Legna; tappa accanto all'anno; pannelli di focus; lettura del terreno per ogni strumento.
  - Giocatori automatici "umani" a quattro profili; registro degli avvisi.
  - Icone di legnaia, capanno da pesca, posta di caccia e pascolo; modelli di legnaia, capanno da pesca e posta di caccia, posati nel gioco dove starebbero (riva e margine del bosco).
  - Decisioni sugli edifici delle risorse: capanno solo sulla riva con aggancio automatico, nessuna distanza minima tra capanni né tra legnaie (tolta dal codice quella di 150 m tra legnaie), pesce locale per tratto di riva.
  - Sera tardi: **capanno da pesca e posta di caccia** nel gioco (simulazione, strumenti, modelli, lettura, prove).

## Per l'abitato protourbano (dopo il villaggio)
- Recinto o palizzata, con terrapieno e fossato: la regolazione dello spazio della seconda epoca (decisioni di Fede del 24 e 25/11/2026).
- Gruppi capi, lignaggi, sacerdote; famiglie eminenti e comuni che nascono dalla disuguaglianza creata dal giocatore, con attenzione agli equilibri di potere (`era-origini.md` § 6).
- Decisi e scartati: prologo nomade **bocciato** (25/11/2026); inizio al 6000 a.C. (i primi quattro secoli per mettere le pedine).
