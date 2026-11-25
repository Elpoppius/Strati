# Todo — Villaggio completo (prima epoca)

*Aperto il 24/11/2026 su richiesta di Fede: chiudere la prima epoca prima di passare all'abitato protourbano (principio: prima la profondità, poi l'ampiezza). Riorganizzato il 25/11/2026 (richiesta di Fede) perché **chi riprende, con l'altro account, sappia cosa fare senza la conversazione**. Riferimenti di design: `era-origini.md` (l'Era delle Origini, con tutte le decisioni e i traguardi) e `pilastri-e-decisioni.md`.*

Legenda: `[x]` fatto · `[~]` in parte · `[ ]` da fare · **(?)** serve una decisione di Fede prima di cominciare.

## Come si lavora (vale per ogni voce)
1. **Prima di toccare il codice:** riepilogo a Fede di cosa si farà e attesa del suo ok (è una sua regola). Le proposte non confermate si segnano come tali.
2. **Dopo:** tutte le 9 verifiche (`CLAUDE.md`, "Comandi utili"); poi, se la voce tocca le dinamiche, le prove con i **giocatori "umani"** (`test/giocatore_umano.gd`, quattro profili: è la base dei test, decisione di Fede del 25/11/2026) e il **registro degli avvisi** (`test/registro_avvisi.gd`) per il ritmo. I giocatori automatici devono imparare a usare ogni strumento nuovo: i gesti comuni stanno in `test/aiuti_giocatori.gd`.
3. **Traguardi** da rispettare (`era-origini.md`, § 9): circa 2–3 pause a partita (si ferma solo per le scelte), poche notifiche, carestie rare e leggibili, nessun abbandono al livello medio, nucleo 100–300 abitanti, territorio fino a 600–800 per chi gioca molto bene.
4. **Alla fine:** voce in cima al diario, todo aggiornato, commit e push.

## A che punto siamo (25/11/2026 sera)
Fatte e collaudate le basi della prima epoca (ritmo, crescita, risorse e rischi, consenso di anziani e famiglie, HUD, strumenti di prova). Per chiudere il villaggio restano circa **27–40 ore di lavoro di Claude** (stima del 25/11/2026, prove comprese; non contano le conferme e le prove di Fede), cioè **7–9 giornate** alternando i due account, poi la prova fisica di Fede e 1–2 giornate di correzioni.

| Voce | Stima |
|---|---|
| 1. Capanno da pesca e Posta di caccia | 2 ore circa |
| 2. Pascolo e bestiame visibile | 4–6 ore |
| 3. Luogo sacro, sacerdote, bosco sacro | 2–3 ore |
| 4. Scorrerie | 2–3 ore |
| 5. Sentieri che diventano strade | 2–3 ore |
| 6. Evento soglia e passo elastico | 4–6 ore (la più delicata: il passo a decenni tocca tutte le regole "per anno") |
| 7. Popolazione visibile | 5–8 ore (serve una prova di Fede per i fotogrammi al secondo) |
| 8. Mappe tematiche | 2–3 ore |
| 9. Base tecnica | 4–6 ore |

Raggruppamento proposto: giornata 1 caccia e pesca con la mappa boschi e selvaggina; 2–3 pascolo, bestiame e luogo sacro; 4 scorrerie e strade; 5–6 evento soglia e passo elastico; 7–8 popolazione visibile; 9 salvataggio, acqua, rifinitura, poi la prova di Fede. Rischi: domande aperte, correzioni dopo la prova fisica, passo elastico e popolazione visibile meno prevedibili.

## Per chi riprende: il lavoro in ordine
*Ordine proposto da Claude il 25/11/2026; le voci sono già approvate da Fede nei contenuti, salvo dove c'è (?).*

### 1. [ ] Capanno da pesca e Posta di caccia
**Deciso** (Fede, 25/11/2026): stessa dinamica della legnaia; senza questi edifici caccia e pesca non spariscono ma rendono circa un terzo.
- **Capanno da pesca** (germe dell'approdo e del porto): **solo sulla riva** (Fede, 25/11/2026, come i moli: aggancio automatico al punto di riva più vicino entro circa 30 m, girato verso l'acqua; fuori dalla palude; anteprima già agganciata, rossa con "Serve la riva di un fiume o di un torrente" se non c'è riva); **nessuna distanza minima tra capanni** (Fede: chi ne ammassa tanti esaurisce il pesce di quel tratto, è una scelta sua). **[Proposta di Claude, da confermare con Fede]** il pesce diventa locale per tratto di riva, come la selvaggina attorno alla posta: più capanni vicini se lo dividono, troppi lo fanno calare, e si riprende in qualche anno se lasciato stare; rende di più vicino all'acqua e secondo il tipo d'acqua (fiume più dei torrenti, poco le paludi).
- **Posta di caccia**: al margine del bosco; rende di più dove il bosco è fitto e la selvaggina abbondante. **La selvaggina diventa locale** attorno alla posta: se si caccia troppo lì cala, e conviene spostarsi (oggi `selvaggina` è un numero unico per il villaggio).
- **Come farlo:** copiare l'impianto della legnaia in `script/sim_villaggio.gd` (`motivo_legnaia`, `costruisci_legnaia`, `capacita_legnaia`, `_lavora_legnaie`, `stato_legnaia`); oggi caccia e pesca sono calcolate in `passo()` da `_risorse` (bosco e acqua attorno al centro) con `QUOTA_CACCIA`, `QUOTA_PESCA`, `RESA_BOSCO`, `RESA_ACQUA`. In `script/partita.gd`: `STRUMENTI`, menu Edifici, `_applica`, `leggi_per_strumento` (lettura sotto il puntatore), `_raggio_strumento`; tasti liberi in `script/principale.gd` (oggi usati: Z, C, V, H, L, X, P, G, I, F, Y). Icone SVG in `gioco/asset/icone/` (stile di `legnaia.svg`). Disegno in `script/vista_villaggio.gd` (come `_sincronizza_legnaie`, modelli da `asset/villaggio/`). Cause nel pannello di focus del Cibo (`cause_di("Cibo")`). Le fonti di cibo nelle politiche restano.
- **Icone già pronte** (25/11/2026): `asset/icone/capanno_pesca.svg` (pesce sopra un'onda) e `posta_caccia.svg` (palco di corna); anteprima `docs/immagini/icone-risorse-25-11.png`.
- **Modelli da fare** in `strumenti/blender/villaggio.py`, nello stile della legnaia (`legnaia()`, fatta il 25/11/2026, foto `docs/immagini/modello-legnaia-25-11.jpg`): **capanno da pesca** fatto il 25/11/2026 (`capanno_pesca()`, `asset/villaggio/capanno_pesca.glb`, foto `docs/immagini/modello-capanno-pesca-25-11.jpg`: capanno di canne con tetto a due falde, rastrelliera con rete e pesci, piroga scavata in un tronco, nasse; l'acqua è verso +y del modello, da orientare verso la riva; posa sulla riva provata in `test/foto_capanno.gd`, foto `docs/immagini/capanno-riva-25-11.jpg`: punto di terra asciutta a circa 2 m dall'acqua con `alberi.distanza_acqua(x, z)`, fuori dalla palude, poco inclinato; rotazione `atan2(-v.x, -v.y)` con `v` = verso l'acqua, contro il gradiente della distanza; da riusare nello strumento e in `vista_villaggio.gd`); **posta di caccia**, un riparo basso di frasche al margine del bosco, una rastrelliera con le pelli a seccare, un piccolo focolare. Descrizioni proposte da Claude e accettate da Fede il 25/11/2026; a ogni giro mostrare la foto a Fede (direzione artistica sua). Dopo l'importazione, nei `.import` delle texture tenere `detect_3d/compress_to=0`; `villaggio.py` riesporta anche gli altri modelli: rimettere com'erano quelli che cambiano senza motivo (`git checkout`). Le falde dei tetti si creano nell'origine, si inclinano e poi si spostano (la rotazione è attorno all'origine dell'oggetto).
- **Prove:** verifiche nuove in `test/verifica_villaggio.gd` (senza edificio un terzo, con l'edificio pieno, vicinanza); i giocatori automatici costruiscono gli edifici (aggiungere a `aiuti_giocatori.gd` e ai profili: chi conosce il genere subito e nel punto giusto, il casual dove capita); poi giocatori "umani" e registro. Attenzione: togliere due terzi di caccia e pesca a chi non costruisce cambia la crescita dei primi decenni.

### 2. [ ] Pascolo e animali (con il bestiame visibile)
**Deciso** (Fede, 25/11/2026, `era-origini.md` § 4 "I cicli"): si apre a 100 abitanti. Concime ai campi vicini, scorta viva per le annate cattive, radure che restano aperte, erosione e piene se troppo pascolo sui pendii, ricchezza delle famiglie, vie degli animali come traffico sui sentieri, animali che attirano le scorrerie.
**Deciso** (Fede, 25/11/2026 sera, sulle domande di Claude):
1. **Zona di pascolo a pennello**, come la zona agricola: le famiglie portano gli animali da sole.
2. **Dove:** prati e radure, margini del bosco (il pascolo impedisce la ricrescita), e i **campi stanchi dentro la zona di pascolo diventano maggese da soli** (concimati, si riposano più in fretta); zona di pascolo e zona agricola possono sovrapporsi. **Requisito di Fede: si deve vedere sulla mappa quando un campo è stanco.**
3. **Un solo numero di "capi"**, con un misto di specie che si vede (pecore e capre soprattutto, maiali vicino al bosco, qualche bue). **Requisito di Fede: va gestito come cresce il numero dei capi.**
4. **Scorta viva:** nelle annate cattive gli animali si macellano da soli (niente pausa, una riga in cronaca); la mandria si ricostituisce negli anni buoni.
5. **Gli animali seguono la politica del raccolto** (in comune o alle famiglie): alle famiglie la mandria cresce di più, ma cresce la disuguaglianza (prepara le famiglie eminenti dell'epoca 2).
- **[Proposta di Claude, da confermare con Fede] Crescita dei capi:** alla tappa dei 100 abitanti il villaggio ha una decina di capi (gli animali che i fondatori tengono attorno alle case); la mandria cresce di circa il 10% l'anno finché c'è erba, cioè fino alla portata della zona di pascolo (circa 2 capi per ettaro di prato, meno nel bosco, di più sui campi a maggese); oltre la portata smette di crescere, e sui pendii il troppo pascolo dà erosione; gli stranieri accolti portano i loro animali; nelle annate cattive se ne macella quanto serve. Pannello di focus "Animali" con capi, portata ed erba.
- **[Proposta di Claude] Campo stanco sulla mappa:** il campo si schiarisce e si riempie di erbacce man mano che si stanca (un valore per cella passato allo shader del terreno, come le tecniche dei campi in `UsoSuolo.tecniche`); nella mappa della Fertilità i campi stanchi si vedono più poveri; un campo a maggese ha l'erba e gli animali.
- **Icona già pronta:** `asset/icone/pascolo.svg` (graticcio con un ciuffo d'erba). **Modello:** uno **stabbio**, recinto basso di graticcio per la notte, con un abbeveratoio di tronco scavato; qualche stabbio sparso nella zona la rende riconoscibile (è diverso dal recinto urbano dell'epoca 2). In `villaggio.py` c'è già `recinto_animali()` da cui partire.
- **Come farlo:** zona di pascolo come `zona` in `sim_villaggio.gd` (`aggiungi_zona`, `zona_piena`) e nel pennello di `principale.gd`; `stanchezza` e `fattore_stanchezza` ci sono già. Modelli degli animali con Blender (`strumenti/blender/`, stile in `docs/asset.md`), disegno con MultiMesh e animazione dallo shader (come gli alberi). Prove: verifiche, giocatori "umani" (devono imparare a stendere il pascolo), registro.

### 3. [ ] Luogo sacro, sacerdote e bosco sacro
**Deciso:** cerchio di pali attorno a una pietra (forma confermata il 24/11/2026); si apre a 100 abitanti; costa legna e braccia con un cantiere. Il sacerdote diventa il terzo gruppo di consenso (`sacerdote_attivo` in `sim_villaggio.gd`, pesi 0,4/0,4/0,2 già pronti): contento, presagi più chiari; scontento, ambigui e con più voci false. Il **bosco sacro** (tappa dei 150) è la riserva: le legnaie non lo tagliano, tagliarlo offende il sacerdote. Il luogo sacro attira le case (germe della piazza).

### 4. [ ] Scorrerie
**Deciso:** attirate dalla ricchezza visibile (animali, scorte) e dai margini del contado poco usati; prima arrivano segni (fuochi sulle colline, tracce, villaggi vicini razziati); difendono il sito (colle, dosso) e un abitato compatto; i casali sparsi sono più esposti; si perdono animali e scorte, a volte case ai margini; cala il consenso degli anziani. Solo in cronaca, salvo le scelte che chiedono un intervento. Sono il ponte verso il recinto dell'epoca 2.

### 5. [ ] Sentieri che diventano strade
**Deciso:** il traffico (campi, pascoli, legnaie, luogo sacro, casali) fa dei sentieri più battuti le prime strade, che restano come assi nelle epoche dopo. Si apre a 250 abitanti con i casali.

### 6. [ ] Evento soglia "il metallo e lo scambio" e passo elastico
**Deciso** (`era-origini.md` § 2 e § 5): si apre quando il territorio è pieno e si è dentro la finestra (~3000–1800 a.C.); presagi (oggetti di rame, mercanti), dilemma aprirsi o restare isolati, transizione con riepilogo. **Passo elastico:** un anno per passo nei primi quattro secoli, poi un decennio (le regole vanno scritte per anno e moltiplicate per il passo). Oggi la partita finisce a 5500 a.C. (`ANNO_FINE`).

### 7. [ ] Popolazione visibile
**Deciso** (25/11/2026): ogni figura fa un lavoro vero della simulazione (campi, bosco, fiume, pascolo, cantieri, sentieri, luogo sacro); **3 modelli di uomini e 3 di donne** che si ripetono, con capelli, incarnato e vesti che variano; animazioni dallo shader; MultiMesh; si vedono solo da vicino; **scala da verificare con la simulazione** (800 persone a schermo sono troppe: tetto di figure visibili, una figura per 1, 2 o 5 persone). Clic su una persona: la scheda della sua famiglia. Prima il bestiame (voce 2), poi i lavoratori, poi chi cammina, poi la scheda.

### 8. [ ] Mappe tematiche (ok di Fede del 25/11/2026)
- Boschi e selvaggina (con la selvaggina locale della voce 1 e le zone di taglio).
- Abitato e contado, distinte (decisione del 24/11/2026), con i casali.
- Memoria del suolo (ex boschi, aree sigillate).

### 9. [ ] Base tecnica
- Salvataggio della partita, con l'uso del suolo.
- Livelli dell'acqua che salgono con le piene, nella grafica.
- Varianti dei modelli del villaggio.
- Prove sui PC di Fede: tempi degli alberi e fotogrammi al secondo.

## Da decidere con Fede
- **(?)** Popolazioni: con i campi che si stancano le mediane sono rientrate (chi conosce il genere 763), i massimi restano a 1000–1080; il casual resta piccolo (mediana 103): **si lascia così per ora** (Fede, 25/11/2026).
- Carestie per chi impara sbagliando: 2,6 a partita, dentro l'obiettivo 1–3 (25/11/2026 sera); chi legge 1,3 (poco sopra 0–1).
- Politica "Caccia regolata": **non si fa per ora** (Fede, 25/11/2026): con la Posta di caccia e la selvaggina locale il giocatore regola già la caccia; si riprende solo se le prove mostrano ancora troppa caccia.
- **Orti più piccoli:** decisi (Fede, 25/11/2026) **solo come aspetto, nella fase grafica**: il quadrato da 40 m resta l'unità della simulazione, ma si disegna diviso in 2–4 appezzamenti con colture e colori diversi.
- **(?)** Come contare gli abitanti sul territorio (idee 1 e 2 di `sessioni-giocatori.md`): con i casali la scelta è in parte fatta; il resto a epoca completa.
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

## Per l'abitato protourbano (dopo il villaggio)
- Recinto o palizzata, con terrapieno e fossato: la regolazione dello spazio della seconda epoca (decisioni di Fede del 24 e 25/11/2026).
- Gruppi capi, lignaggi, sacerdote; famiglie eminenti e comuni che nascono dalla disuguaglianza creata dal giocatore, con attenzione agli equilibri di potere (`era-origini.md` § 6).
- Decisi e scartati: prologo nomade **bocciato** (25/11/2026); inizio al 6000 a.C. (i primi quattro secoli per mettere le pedine).
