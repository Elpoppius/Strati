# Todo — Villaggio completo (prima epoca)

*Aperto il 24/11/2026 su richiesta di Fede: chiudere la prima epoca prima di passare all'abitato protourbano (principio: prima la profondità, poi l'ampiezza). Riorganizzato il 25/11/2026 (richiesta di Fede) perché **chi riprende, con l'altro account, sappia cosa fare senza la conversazione**. Riferimenti di design: `era-origini.md` (l'Era delle Origini, con tutte le decisioni e i traguardi) e `pilastri-e-decisioni.md`.*

Legenda: `[x]` fatto · `[~]` in parte · `[ ]` da fare · **(?)** serve una decisione di Fede prima di cominciare.

## Come si lavora (vale per ogni voce)
1. **Prima di toccare il codice:** riepilogo a Fede di cosa si farà e attesa del suo ok (è una sua regola). Le proposte non confermate si segnano come tali.
2. **Dopo:** tutte le 9 verifiche (`CLAUDE.md`, "Comandi utili"); poi, se la voce tocca le dinamiche, le prove con i **giocatori "umani"** (`test/giocatore_umano.gd`, quattro profili: è la base dei test, decisione di Fede del 25/11/2026) e il **registro degli avvisi** (`test/registro_avvisi.gd`) per il ritmo. I giocatori automatici devono imparare a usare ogni strumento nuovo: i gesti comuni stanno in `test/aiuti_giocatori.gd`.
3. **Traguardi** da rispettare (`era-origini.md`, § 9): circa 2–3 pause a partita (si ferma solo per le scelte), poche notifiche, carestie rare e leggibili, nessun abbandono al livello medio, nucleo 100–300 abitanti, territorio fino a 600–800 per chi gioca molto bene.
4. **Alla fine:** voce in cima al diario, todo aggiornato, commit e push.

## Per chi riprende: il lavoro in ordine
*Ordine proposto da Claude il 25/11/2026; le voci sono già approvate da Fede nei contenuti, salvo dove c'è (?).*

### 1. [ ] Capanno da pesca e Posta di caccia
**Deciso** (Fede, 25/11/2026): stessa dinamica della legnaia; senza questi edifici caccia e pesca non spariscono ma rendono circa un terzo.
- **Capanno da pesca** (germe dell'approdo e del porto): sulla riva; rende di più vicino all'acqua e secondo il tipo d'acqua (fiume più dei torrenti, poco le paludi).
- **Posta di caccia**: al margine del bosco; rende di più dove il bosco è fitto e la selvaggina abbondante. **La selvaggina diventa locale** attorno alla posta: se si caccia troppo lì cala, e conviene spostarsi (oggi `selvaggina` è un numero unico per il villaggio).
- **Come farlo:** copiare l'impianto della legnaia in `script/sim_villaggio.gd` (`motivo_legnaia`, `costruisci_legnaia`, `capacita_legnaia`, `_lavora_legnaie`, `stato_legnaia`); oggi caccia e pesca sono calcolate in `passo()` da `_risorse` (bosco e acqua attorno al centro) con `QUOTA_CACCIA`, `QUOTA_PESCA`, `RESA_BOSCO`, `RESA_ACQUA`. In `script/partita.gd`: `STRUMENTI`, menu Edifici, `_applica`, `leggi_per_strumento` (lettura sotto il puntatore), `_raggio_strumento`; tasti liberi in `script/principale.gd` (oggi usati: Z, C, V, H, L, X, P, G, I, F, Y). Icone SVG in `gioco/asset/icone/` (stile di `legnaia.svg`). Disegno in `script/vista_villaggio.gd` (come `_sincronizza_legnaie`, modelli da `asset/villaggio/`). Cause nel pannello di focus del Cibo (`cause_di("Cibo")`). Le fonti di cibo nelle politiche restano.
- **Prove:** verifiche nuove in `test/verifica_villaggio.gd` (senza edificio un terzo, con l'edificio pieno, vicinanza); i giocatori automatici costruiscono gli edifici (aggiungere a `aiuti_giocatori.gd` e ai profili: chi conosce il genere subito e nel punto giusto, il casual dove capita); poi giocatori "umani" e registro. Attenzione: togliere due terzi di caccia e pesca a chi non costruisce cambia la crescita dei primi decenni.

### 2. [ ] Pascolo e animali (con il bestiame visibile)
**Deciso** (Fede, 25/11/2026, `era-origini.md` § 4 "I cicli"): si apre a 100 abitanti. Concime ai campi vicini, **maggese a pascolo** (un campo stanco messo a pascolo si riposa più in fretta: si lega ai campi che si stancano, già fatti), scorta viva per le annate cattive (gli animali si macellano invece di patire la fame), radure che restano aperte (il bosco non ricresce sotto il pascolo), erosione e piene se troppo pascolo sui pendii, ricchezza delle famiglie (e disuguaglianza), vie degli animali come traffico sui sentieri, animali che attirano le scorrerie.
- **(?) Da proporre a Fede prima di cominciare:** come si disegna il pascolo (pennello come la zona agricola?), quanti animali per ettaro, come si vedono (un modello per specie: pecora, capra, maiale, bue, con varianti di mantello; disegno con MultiMesh, animazione dallo shader).

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
- **(?)** Popolazioni: con i campi che si stancano le mediane sono rientrate (chi conosce il genere 763), i massimi restano a 1000–1080; il **casual resta piccolo** (mediana 103): va bene così o va aiutato? (`sessioni-giocatori.md`, ultima sezione).
- Carestie per chi impara sbagliando: 2,6 a partita, dentro l'obiettivo 1–3 (25/11/2026 sera); chi legge 1,3 (poco sopra 0–1).
- **(?)** Politica "Caccia regolata", solo se le fonti di cibo non bastano come leva.
- **(?)** Orti disegnati più piccoli dentro il quadrato da 40 m (si calibrano sulla frustrazione e sulla crescita: decisione del 25/11/2026).
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
