# Strati — Pilastri e decisioni di base

*Aggiornato al 25/11/2026*

## Concept
Gestionale urbanistico-politico. Il giocatore governa una città europea verosimile (un archetipo, non una città reale) attraverso i secoli, dai primi insediamenti all'epoca contemporanea e oltre. Ispirazione centrale: lo sventramento di Parigi di Haussmann, riletto in chiave contemporanea (rigenerazione urbana, gentrificazione, turistificazione, grandi eventi, finanza immobiliare).

## Pilastri di design
1. **La città si stratifica.** Nessuna epoca parte da zero: ognuna lavora sulla città lasciata dalla precedente. Ciò che costruisci diventa il vincolo di chi viene dopo, cioè di te stesso più avanti (es. griglia antica → tessuto medievale → viale ottocentesco tagliato attraverso → viale "storico" oggi intoccabile; resti archeologici nel sottosuolo).
2. **Le necessità spingono la trasformazione.** Bisogni come fogna, traffico, ferrovia o igiene creano pressione. Il giocatore sceglie la risposta: sventrare, adattare, andare sotto, spostare altrove. Lo sventramento è possibile, non obbligato: è la risposta più drastica.
3. **Il potere vive di consenso, e cambia chi lo concede.** Il giocatore è "il governo della città", la cui forma cambia per epoca (anziani, capi guerrieri, magistrature, vescovo/signore, consoli/podestà, principe, prefetto, sindaco… e in futuro forse consorzi privati). In ogni epoca cambiano la fonte di legittimità, gli strumenti e i vincoli. I gruppi di consenso cambiano con le epoche: notabili, Chiesa, corporazioni, Stato, operai, elettori, investitori, comitati, famiglie storiche.
4. **Ogni epoca ha la sua sensibilità, e i posteri rigiudicano.** La sensibilità è il sistema di valori con cui un'epoca giudica la città. Funziona così:
   - c'è una sensibilità dominante e ci sono sensibilità emergenti, che possono diventare dominanti;
   - la sensibilità modula il costo politico delle azioni (demolire nel 1860 costa poco, oggi molto);
   - quando cambia, il passato viene rigiudicato (il boulevard di ieri diventa il patrimonio di oggi).
5. **Il tempo urbano supera il tempo del potere.** I cantieri durano più dei mandati; le scelte pesano per secoli.
6. **Leggere la città è giocare.** Le mappe tematiche sono lo strumento principale (densità, rendita, consenso, salute, memoria, stratificazione archeologica, altimetria, rischio idraulico).
7. **Nessuna soluzione giusta, solo conseguenze.** Simulazione seria ma non moralista.

**Principio di produzione:** prima la profondità, poi l'ampiezza. Un'epoca giocabile bene vale più di sei abbozzate.

**Ritmo (decisione di Fede del 24/11/2026):** il ritmo del gioco non è incalzante ma meditativo, strategico. Fermano il gioco solo le scelte vere; ciò che non chiede un intervento (piene, carestie) arriva come notifica discreta, sulla mappa e negli indicatori.

## Decisioni prese
- **Visuale:** isometrico 3D con camera fissa ruotabile (scatti di 90°), con mappe tematiche.
- **Gameplay di riferimento:** Cities: Skylines / SimCity; visuale vicina a Caesar III.
- **Tono:** simulazione seria, non vincolante.
- **Ambientazione:** archetipi di città europee verosimili (es. "città lagunare", non Venezia). Le città reali entrano solo negli scenari.
- **Struttura:** sandbox con indicatori. Si può scegliere l'epoca iniziale (come in Civilization o Age of Empires), ma il gioco è pensato per la progressione dall'inizio.
- **Tempo:** cronologia scandita da eventi storici reali (vedi Eventi). Tempo continuo con pausa e velocità regolabili (impostazione di partenza, modificabile); la simulazione avanza per anni e si ferma da sola nei momenti decisivi.
- **Le epoche fanno da tutorial:** i sistemi si sbloccano progressivamente.
- **Strumenti (24/11/2026):** uno strumento **Demolisci**, come in Cities: Skylines, vale per tutti gli elementi demolibili (alberi, case, strade, campi…). Non si applica agli elementi naturali non demolibili: un fiume o una palude non si demoliscono, si governano con altri strumenti (dighe, canali, deviazioni, bonifiche). Ogni lavorazione dev'essere coerente con l'epoca in corso: deviare un fiume o bonificare una palude si potrà fare con i mezzi e nei modi della propria epoca.
- **Tecniche ed epoche (24/11/2026):** le opere hanno la tecnica della loro epoca, a cominciare dai campi (zappa, aratro in croce, centuriazione, strisce medievali, meccanica). Al cambio d'epoca ciò che c'è resta com'era; le opere nuove nascono con la tecnica nuova, che rende di più (progresso tecnologico). L'**ammodernamento tecnologico** (nel blocco Gestione, allo stesso livello delle politiche, diviso per settori: agricolo, viario, abitativo…) non costruisce niente da zero: sovrascrive il tipo vecchio con il nuovo, un po' ogni anno, con un costo in risorse proporzionale a quanto c'è da rifare.
- **Materiali (24/11/2026):** edifici e strade hanno le qualità dei loro materiali, nascoste al giocatore. Una casa lunga (legno e argilla) tolta lascia ricrescere il bosco nelle condizioni giuste; un'autostrada (asfalto) sigilla il suolo per sempre, ma resta la memoria di ciò che c'era.
- **Produzione:** Fede + Claude, budget zero. Godot 4.7.2 (renderer Compatibilità), Blender 5.3, asset creati da script o con licenza CC0 (stile verosimile: vedi `asset.md`), Git/GitHub.

## Epoche
Struttura simmetrica: **6 macro-ere × 2 epoche**. Il passaggio di macro-era sblocca nuovi sistemi; il passaggio di epoca cambia la sensibilità dominante. Le epoche prendono il nome dal tipo di città che producono, non da un popolo.

| Macro-era | Epoca | Periodo indicativo | Si apre con | Chi governa | Sensibilità dominante |
|---|---|---|---|---|---|
| Origini | Villaggio | Neolitico | Agricoltura, primi insediamenti stabili | Anziani, capi famiglia | Sopravvivenza, sacro naturale |
| | Abitato protourbano | Età del Bronzo e del Ferro | Metalli, scambi a lunga distanza | Capi guerrieri, aristocrazie | Difesa, lignaggio |
| Antichità | Città-stato | VIII–I sec. a.C. circa | Scrittura, contatti mediterranei | Magistrature civiche | Ordine civico e sacro, cittadinanza |
| | Città imperiale | I sec. a.C. – V sec. d.C. | Integrazione in un impero | Amministrazione municipale, notabili | Monumentalità, ordine, utilità pubblica |
| Medioevo | Città in contrazione | V–X sec. | Crisi dell'impero, invasioni, epidemie | Vescovo, signore locale | Sicurezza, sacralità |
| | Città comunale e mercantile | XI–XV sec. | Ripresa dei commerci e della popolazione | Consoli, podestà, corporazioni | Autonomia, mercato, onore, devozione |
| Età moderna | Città del principe | XV–XVII sec. | Stampa, esplorazioni, artiglieria, Riforma | Signore, principe, governatore | Magnificenza, armonia, potere visibile |
| | Città della ragione | XVIII sec. | Illuminismo, rivoluzioni | Sovrano riformatore, amministrazione statale | Razionalità, salute pubblica |
| Età industriale | Città industriale | XIX sec. | Industria, ferrovia, colera | Prefetto, sindaco notabile | Progresso, igiene, circolazione (Haussmann) |
| | Città di massa | XX sec. | Guerre mondiali, motorizzazione, ricostruzione | Sindaco di partito | Modernità, casa per tutti |
| Età globale | Città globale | Dagli anni '80 a oggi | Deindustrializzazione, turismo, crisi climatica | Sindaco eletto | Sostenibilità, patrimonio, inclusione |
| | Città futura | Facoltativa, speculativa | Emerge dalle tendenze della partita | Da definire | Plurale (vedi Futuro) |

**Sensibilità emergenti, esempi:** nella città industriale, tutela del patrimonio e questione sociale; nella città di massa, ecologia e tutela dei centri storici; nella città globale, diritto alla città e città digitale.

**Schema comune a ogni epoca (modulo):** sensibilità dominante, sensibilità emergenti, forma di governo, strumenti sbloccati, crisi che la chiude.

**"Città in contrazione"** è un'epoca giocabile: gestire il declino, riusare le rovine, ritirarsi in mura più piccole.

**Peso delle epoche (proposta).** La simmetria vale per la struttura, non per il tempo di gioco. Le sfide urbanistiche più ricche arrivano dalla città del principe in poi (Ferrara e l'Addizione Erculea, Haussmann, piani regolatori), quindi:
- le prime epoche scorrono veloci e si giocano "a decisioni chiave" (fondazione, primo asse, mura…), mentre la città cresce in buona parte da sola;
- dalla città del principe in poi la gestione diventa continua, con un tempo più lento e una quota maggiore del tempo di gioco;
- la scelta dell'epoca iniziale nel sandbox permette di saltare direttamente alle epoche più complesse.

| Macro-era | Velocità del tempo (ipotesi) | Quota del tempo di gioco (ipotesi) |
|---|---|---|
| Origini | secoli o decenni | ~5% |
| Antichità | decenni | ~10% |
| Medioevo | decenni o anni | ~15% |
| Età moderna | anni | ~20% |
| Età industriale | un anno o una stagione | ~25% |
| Età globale | una stagione o un mese | ~25% |

## Ciclo di gioco
**Due cicli, uno dentro l'altro:**
- **Ciclo dell'epoca (lento):** presagi → evento → transizione.
- **Ciclo di gestione (veloce), uguale in tutte le epoche:** Leggere → Decidere → Simulare → Conseguenze. Con le epoche cambiano i contenuti di ogni fase (mappe, azioni, risorse), non la struttura.

### Il villaggio (prima epoca)
- **Leggere:** poche mappe tematiche (altimetria e rischio di piena; acqua: sorgenti, torrenti, falda; fertilità del suolo; boschi e selvaggina).
- **Decidere:**
  - *Fondare:* scegliere il sito, la decisione più importante della partita.
  - *Destinare il territorio:* campi, pascolo, bosco, riserva (dentro il contado, che cresce con gli abitanti).
  - *Costruire:* granaio, luogo sacro, sentiero. Il recinto non c'è: appartiene all'abitato protourbano (decisione di Fede del 24–25/11/2026, vedi sotto). Le capanne non si piazzano: crescono da sole vicino a campi, acqua e sentieri. Il giocatore orienta la crescita.
  - *Politiche (le usanze):* divisione del raccolto (in comune: più coesione; per famiglia: più prosperità e più disuguaglianza), accoglienza degli stranieri. **Decisione di Fede (24/11/2026):** le usanze non sono oggetti da costruire ma politiche, regole che valgono finché non si cambiano; stanno in un pannello a parte, non tra i menù delle costruzioni, e da qui si comincia a introdurre questo genere di scelte.
- **Simulare (ogni anno):** raccolto = suolo × campi × clima dell'anno × braccia; consumo e scorte; crescita o calo della popolazione; salute legata ad acqua e affollamento; legittimità degli anziani legata al cibo e al rispetto delle usanze.
- **Conseguenze:** eventi locali (siccità, piena, scorrerie), presagi veri o falsi, variazione degli indicatori.
- **Risorse:** cibo (scorte), legna, braccia, legittimità. Niente denaro: arriva in epoche successive.
- **Gruppi di consenso:** anziani, famiglie, sacerdote.
- **Momenti decisivi (pausa automatica):** fondazione; primo cattivo raccolto; arrivo di stranieri; soglia di popolazione (restare, con l'abitato che si allarga, oppure emigrare); presagi; evento soglia "il metallo e lo scambio".
- **La stratificazione comincia qui:** i sentieri più usati diventano strade e poi assi; il luogo sacro diventa tempio, chiesa, piazza; gli appezzamenti delle famiglie sono i primi lotti.

### Il fallimento come strato
Un insediamento abbandonato resta come rovina nel sottosuolo; si può rifondare altrove sulla stessa mappa. In modalità tutorial il fallimento è raro, in modalità normale è possibile.

### Prototipo 0
- Mappa pedecollinare semplificata.
- 3 mappe tematiche: acqua, suolo, rischio di piena.
- 5 azioni: fondare, campi, granaio, sentiero, usanza sul raccolto.
- 4 indicatori: popolazione, cibo, salute, legittimità.
- 1 evento (siccità) e 1 presagio falso.
- Domanda da verificare: scegliere dove fondare e gestire la scarsità è già una decisione che pesa?

## Eventi
**Principio:** gli eventi epocali arrivano dall'esterno, sono inevitabili e cadono **in un arco temporale storico definito** (finestra). Il momento esatto all'interno della finestra lo decide il mondo, non la città. La città può gestirli meglio o peggio: le sue condizioni determinano quanto e come li subisce (es. "i barbari arrivano alle porte: quanto resiste la città, e perché?").

**Impatto (modello di rischio):** impatto = pericolosità dell'evento (esterna) × esposizione × vulnerabilità della città, ridotto dalla preparazione.
- *Esposizione:* posizione e topografia (sulle vie di passaggio o protetta, su un colle, in laguna, in pianura aperta).
- *Vulnerabilità:* difese, scorte, coesione, legittimità, salute, cultura della città.
- *Preparazione:* ciò che il giocatore ha fatto ascoltando i presagi.

**Esiti graduati (esempio: invasione):** la città resiste; patteggia (tributo); subisce un saccheggio; viene distrutta in parte; viene abbandonata e rifondata. Gli eventi possono avere effetti indiretti (es. profughi da città vicine cadute).

**Tre fasi di ogni grande evento:**
1. **Presagi:** prima della finestra, una sensibilità emergente cresce e compaiono segnali. Se il giocatore li ignora, il contraccolpo è maggiore.
2. **Evento:** lo shock esterno, inevitabile, dentro la sua finestra.
3. **Transizione:** cambiano sensibilità e governo, si sbloccano strumenti; della città precedente qualcosa resta e qualcosa si perde.

**Classi di eventi:**
- **Eventi soglia (11):** fanno scattare il cambio di epoca.
- **Eventi d'epoca:** grandi, storici, con una finestra temporale, interni a un'epoca. Alcuni possono ripetersi a ondate (pesti, colera).
- **Eventi locali:** casuali (alluvioni, incendi, carestie, crolli).

**Presagi:**
- **Veri epocali:** annunciano un evento soglia.
- **Veri minori:** annunciano un evento d'epoca o locale.
- **Falsi:** si confondono con i veri (es. la fine del mondo attesa per l'anno Mille). Ignorarli **premia** il giocatore (risparmio di risorse, stabilità); reagire in modo eccessivo costa.
- **Con spiegazione sbagliata:** il pericolo è reale ma la causa indicata è errata (es. la teoria dei miasmi): si può reagire bene per motivi sbagliati.
- I presagi veri tendono a essere confermati da più fonti e dai dati (mappe tematiche, indicatori); quelli falsi da una sola fonte o da voci. La distinzione non è mai garantita.
- I presagi sono anche politici: ogni gruppo di consenso spinge la propria interpretazione, e assecondarla può far guadagnare consenso anche quando il presagio è falso.

**Gli 11 eventi soglia (alternanza minore / maggiore):**
| # | Tipo | Passaggio | Evento soglia | Finestra indicativa | Cosa porta | Dilemma chiave |
|---|---|---|---|---|---|---|
| 1 | minore | Villaggio → Abitato protourbano | Il metallo e lo scambio | ~3000–1800 a.C. | Élite, prime difese, scambi | Aprirsi alle vie di passaggio o restare isolati? |
| 2 | maggiore | → Città-stato | La città si dà leggi | ~900–600 a.C. | Leggi, tasse, spazio pubblico, templi | A chi dare la cittadinanza? |
| 3 | minore | → Città imperiale | L'impero arriva | ~300 a.C. – 50 d.C. | Grandi infrastrutture, reticolo regolare, potere esterno | Resistere o allearsi? |
| 4 | maggiore | → Città in contrazione | Il crollo (impero in crisi, invasioni, epidemia) | ~250–550 d.C. | Riuso delle rovine, mura più strette, potere del vescovo | Arroccarsi in città o disperdersi nelle campagne? |
| 5 | minore | → Città comunale e mercantile | La rinascita dei commerci | ~950–1100 | Mercati, corporazioni, regole edilizie, nuove mura | Città dei mercanti o città delle famiglie? |
| 6 | maggiore | → Città del principe | L'età delle scoperte (artiglieria, stampa, nuove rotte) | ~1450–1520 | Mura bastionate, piazze, rettifili, pianificazione | Accettare un signore o difendere il comune? |
| 7 | minore | → Città della ragione | I Lumi e la rivoluzione | ~1750–1815 | Catasto, cimiteri fuori città, riuso dei conventi soppressi | Riformare dall'alto o con la popolazione? |
| 8 | maggiore | → Città industriale | Il vapore e il colera | ~1820–1860 | Fabbriche, ferrovia, fogne, espropri su larga scala | Sventrare o risanare? |
| 9 | minore | → Città di massa | La guerra totale | ~1914–1945 | Ricostruzione, auto, edilizia pubblica, piano regolatore | Ricostruire com'era o costruire il nuovo? |
| 10 | maggiore | → Città globale | La fine della fabbrica | ~1973–1995 | Aree dismesse, turismo, finanza, rigenerazione | A chi vanno le aree dismesse? |
| 11 | minore | → Città futura | La soglia | Dalle tendenze della partita | Speculativa | Dipende dalla città |

**Eventi d'epoca e presagi (prima proposta):**
| Epoca | Eventi d'epoca | Presagi veri | Presagi falsi o ingannevoli |
|---|---|---|---|
| Villaggio | Siccità, carestia, piena, scorrerie | Annate secche, selvaggina in calo | Eclissi e comete come segni divini |
| Abitato protourbano | Razzie, guerre tra clan, morie del bestiame | Mercanti stranieri, armi nuove nei villaggi vicini | Profezie dei sacerdoti |
| Città-stato | Guerre con città vicine, colpi di stato, carestie, partenza di coloni | Sovrappopolazione, disuguaglianza crescente | Oracoli e prodigi |
| Città imperiale | Guerre civili, grandi incendi, terremoti, epidemie | Tasse imperiali in aumento, truppe ai confini, moneta svalutata | Prodigi e profezie di sventura |
| Città in contrazione | Pestilenze, incursioni, fiumi che straripano senza manutenzione | Villaggi vicini abbandonati, monete che scarseggiano | La fine del mondo dell'anno Mille |
| Città comunale | Peste nera, grandi carestie, lotte tra fazioni, incendi | Navi e mercanti da terre colpite, sovraffollamento, annate fredde | Movimenti penitenziali che annunciano castighi |
| Città del principe | Assedi con artiglieria, guerre di religione, rotte commerciali che si spostano, ritorni di peste | Fortezze nuove nei territori vicini, inflazione, commerci in calo | Astrologi, comete |
| Città della ragione | Grandi terremoti, carestie, soppressioni religiose, occupazioni militari | Pane caro, idee nuove in circolazione | Voci di complotti |
| Città industriale | Ondate di colera, rivolte, unificazioni nazionali, crisi finanziarie | Sovraffollamento, mortalità in crescita, allarmi degli igienisti | La teoria dei miasmi (causa sbagliata, pericolo reale) |
| Città di massa | Pandemia influenzale, crisi economica, bombardamenti, boom economico, grandi alluvioni | Traffico, inurbamento, periferie senza servizi | Paure belliche infondate |
| Città globale | Crisi finanziarie, pandemia, ondate di calore, alluvioni, turismo di massa | Affitti in salita, botteghe storiche che chiudono, temperature in aumento | Allarmi mediatici infondati |
| Città futura | Emergono dalle tendenze della partita | — | — |

## Difficoltà
- **Complessità e margine crescono insieme:** con le epoche aumentano sistemi, gruppi di consenso e strumenti, ma anche risorse e riserve.
- **Il villaggio è semplice da capire, non facile da far sopravvivere:** pochi sistemi, alta precarietà.
- **Cambia il tipo di sfida:** nelle origini la sopravvivenza; nelle epoche centrali l'equilibrio tra i gruppi; nelle contemporanee complessità e consenso.
- **Le prime scelte hanno la posta più alta:** sito di fondazione e primo asse condizionano tutti i secoli successivi.
- **Opzione di difficoltà sulla precarietà:** in modalità "tutorial" le prime epoche perdonano gli errori, in "normale" no.

## Culture
- **Emergono, non si scelgono:** la cultura della città (marinara, agricola, mercantile, industriale, religiosa…) si forma da ciò che la città fa. Una città può avere più tratti; quelli più forti ne definiscono il profilo.
- **Plastiche all'inizio, inerti col tempo:** nelle prime epoche la cultura si forma e cambia facilmente; una volta consolidata è difficile da smontare (costa tempo e consenso). Le crisi possono romperla (es. la deindustrializzazione trasforma la cultura industriale in memoria e patrimonio).
- **Effetti dentro la città:** gruppi di consenso, forma di crescita spontanea (griglia, organica, concentrica), sensibilità locale, tipologie edilizie e aspetto, tracce persistenti (luoghi sacri, toponimi).
- **Sensibilità = epocale + locale:** la sensibilità dell'epoca vale per tutti; la cultura aggiunge uno strato locale (una città marinara tiene al porto anche nell'età globale).
- **Mondo esterno astratto:** niente diplomazia con altre città simulate. Commercio, potere sovraordinato (impero, regno, Stato, Unione Europea) e migrazioni sono indicatori ed eventi. Migrazioni e conquiste possono aggiungere tratti culturali.
- **Semplicità:** la cultura è un insieme di parametri; si può introdurre gradualmente.

## Futuro
- È dichiaratamente una proiezione, non una previsione.
- Nasce dalle tendenze della partita: sensibilità e problemi futuri emergono da come è stata governata la città.
- Futuri plurali, compresi quelli oscuri: sprawl e consumo di suolo, città governata da corporazioni, città-fortezza, collasso climatico, sorveglianza, spopolamento; ma anche adattamento climatico, città digitale, decrescita.
- Il pilastro 3 vale anche qui: se la dipendenza finanziaria cresce, il potere può passare a soggetti privati.

## Scenari (rimandati)
Città reali gestite "in medias res". Da sviluppare dopo le basi del gioco. Idee: Parigi 1853 (Haussmann), Barcellona 1859 (Cerdà), Vienna 1857 (il Ring), Napoli 1884 (Risanamento), Roma 1871 (capitale).

## Abitato, contado ed espansione (decisione di Fede del 24/11/2026, proposta di Claude accolta)
- **Due confini diversi.** L'**abitato** è dove si vive e si costruisce: cresce per densità (abitanti per ettaro), e quando è troppo pieno nascono le pressioni, prima numeriche (affollamento), poi igieniche (salute), poi di spazi. Il **contado** è la terra che la città usa e governa (campi, boschi, pascoli, acque): cresce per competenza territoriale, cioè per quanta gente c'è e quanta terra serve a sfamarla. Si leggono su mappe tematiche distinte.
- **Lo sprawl è la crescita di base**, quella che succede se non si pianifica: borghi fuori porta lungo le strade, appena oltre il confine, con un confine sfumato. Il piano (recinto, addizione, piano regolatore) è lo strumento per incanalarlo. Ignorare la pressione costa dopo (disordine, salute, consenso); pianificare costa subito (risorse, consenso).
- **Il contado si consolida con l'uso:** la terra usata davvero rafforza la competenza; quella rivendicata e non usata si perde o diventa contesa con i vicini (astratti). Ai margini del contado nascono le scorrerie.
- **Strumenti di espansione per epoca:** villaggio: abitato spontaneo, emigrazione, contado che cresce con gli abitanti fino al limite di cammino; protourbano: recinto o palizzata, alleanze o razzie; città-stato: confine sacro rituale, colonie, assegnazione delle terre; impero: reticolo pianificato, centuriazione e catasto; medioevo: borghi fuori porta e nuovo giro di mura, contado conquistato o comprato dai signori; principe: addizione pianificata; ragione e industria: abbattimento delle mura, piano di ampliamento, esproprio; massa e globale: piano regolatore, annessione dei comuni vicini, limiti al consumo di suolo.
- **La tecnica riduce il bisogno di terra:** con l'ammodernamento ogni campo rende di più, quindi intensificare è un'alternativa a espandersi.
- **Nel villaggio:** contado da 400 a 800 m con gli abitanti; abitato spontaneo (più gente, più case) con la densità come indicatore; **zona agricola** in cui le famiglie dissodano da sole i campi che servono (nelle epoche successive i campi andranno gestiti uno per uno; resta anche il campo messo a mano); a 150 abitanti la scelta tra restare (l'abitato si allarga) ed emigrare (un terzo delle famiglie parte). Il villaggio figlio è tolto (decisione di Fede del 24/11/2026).

## Economia mista (decisione di Fede del 24/11/2026)
Il gioco si basa molto sull'agricoltura, ma prima dell'agricoltura vengono caccia, pesca e raccolta, e i primi agricoltori continuarono a praticarle a lungo. Nel villaggio il cibo viene da campi, caccia e raccolta (boschi) e pesca (acque). La vicinanza a boschi e fiumi dà vantaggi ma espone ai rischi: le piene per l'acqua, la selvaggina che rovina i campi per il bosco. Storicamente la vicinanza ai fiumi è sempre stata premiata, ma pericolosa.
- **Prologo nomade bocciato** (decisione di Fede del 25/11/2026): Strati è prima di tutto un gioco urbanistico, un city builder con vocazione storica e stratificata; si comincia dalla fondazione.

## La prima epoca: dinamiche (decisioni di Fede del 25/11/2026)
Dopo le sessioni automatiche e il registro degli avvisi di cinque partite (`sessioni-giocatori.md`), Fede ha approvato le proposte di Claude qui sotto, con le correzioni indicate. **Il ritmo è l'ansia:** in una partita di 500 anni c'erano 14 pause, 12 notifiche rosse e una ventina di "carestie" da pochi punti; il gioco deve restare meditativo come un city builder (riferimento: Cities: Skylines).

**Crescita**
- **Abbondanza:** un solo indicatore con tre parti al passaggio (come il consenso): cibo che avanza (scorte), salute, spazio (case). Le nascite seguono l'abbondanza; vicino al limite calano da sole, senza passare per le carestie. Più risorse, più crescita.
- **Tappe:** soglie di abitanti che aprono gli strumenti dell'epoca; una volta raggiunte restano (permanenti), anche se gli abitanti calano. Cambia solo l'effetto (per esempio il luogo sacro rende quanto è contento il sacerdote). Soglie di partenza, da tarare: 30 fondazione (zona agricola, campo, sentiero, fonti di cibo); 60 granaio e divisione del raccolto; 100 luogo sacro e pascolo; 150 restare o emigrare, bosco sacro, politica sugli stranieri; 250 casali nel contado e sentieri che diventano strade; territorio pieno: presagi del metallo ed evento soglia.
- **Popolazioni verosimili:** obiettivo indicativo un nucleo di 100–300 abitanti e il territorio, con i casali, fino a 600–800 per chi gioca molto bene. La scelta tra le idee 1 e 2 di `sessioni-giocatori.md` resta rimandata a epoca completa (decisione del 24/11).
- **Orti:** si calibrano sul livello di frustrazione e di crescita; se la crescita è troppo ripida o il gioco troppo "da fattoria", si cercano espedienti. La pianificazione dei cicli della terra e l'uso delle risorse rallentano la crescita in modo naturale.

**Eventi: nascono dallo stato della partita, non dal caso**
- **Annate magre:** fanno parte del ciclo normale; si contano solo nell'accumulo del cibo, **senza avvisi** (né notifiche né righe di cronaca).
- **Carestia:** solo con scorte finite più un'annata cattiva più segnali ignorati; granaio, animali e presagi ascoltati la evitano. Obiettivo: poche per partita.
- **Siccità:** sempre annunciata dalle sorgenti (niente più siccità improvvise).
- **Piene:** distruggono ma fertilizzano. Le piene di stagione portano limo: il raccolto dell'anno si perde, i campi allagati rendono di più dopo. Le disastrose diventano rare e **coerenti con il sito e con le azioni del giocatore** (rischio della mappa, bosco tagliato a monte, costruzioni nelle terre a rischio), annunciate da segni; quando arrivano si devono vedere sulla mappa.
- **Febbri:** da paludi e affollamento.
- **Stranieri:** attirati dall'abbondanza; si governano con la politica (accogliere o respingere senza pausa; si ferma il gioco solo con "caso per caso").
- **Scorrerie:** attirate dalla ricchezza visibile (animali, scorte) e dai margini del contado poco usati; difendono il sito e un abitato compatto, i casali sparsi sono più esposti; prima arrivano segni. Sono il ponte verso il protourbano, dove nascono il bisogno di regole e il recinto.
- **Recinto:** appartiene alla logica della pianificazione urbana. Nella prima epoca gli insediamenti sono spontanei; nella seconda cominciano a darsi delle regole, e il recinto (con terrapieno e fossato) traccia la linea delle future mura.
- **Pause:** si ferma solo la prima volta di ogni tipo di evento (fa da tutorial), per i presagi e per l'evento soglia.
- **Zona agricola piena:** niente avviso. Basta la resa sulla mappa (eventualmente un indicatore che si accende e si spegne, da pensare: se il giocatore è soddisfatto delle sue zone lo ignorerebbe).

**Leggere la terra**
- **Lettura sotto il puntatore per ogni strumento**, come in fondazione: ogni strumento mostra le voci che contano per lui (zona agricola: fertilità, rischio di piena, distanza, bosco che si perde; granaio: rischio di piena, distanza; pascolo: erba, pendenza; sentiero: pendenza, guadi). Si vedono attivamente le qualità della terra e i suoi rischi.

**Risorse e sistemi sinergici**
- **Regola:** ogni sistema nuovo prende o dà qualcosa a un altro sistema, muove almeno un gruppo di consenso e lascia una traccia sulla mappa.
- **Risorse della prima epoca:** cibo, legna, braccia, animali; niente denaro. Granaio e luogo sacro costano legna e braccia e si costruiscono in qualche anno; il sentiero solo braccia; la zona agricola è gratis da disegnare, ma dissodare consuma braccia e dà legna. **Le case spontanee crescono solo se c'è legna.**
- **Ciclo della terra:** bosco → legna e radura → campo o pascolo → campo stanco → maggese a pascolo, concimato dagli animali → di nuovo campo, oppure bosco che ricresce. Il disboscamento dei pendii dà erosione, piene più rapide, meno selvaggina.
- **Ciclo del rischio:** più ricchezza (animali, scorte) attira più scorrerie; disperdersi nei casali espone di più.
- **Pascolo:** concime ai campi vicini, scorta viva per le annate cattive, tiene aperte le radure, troppo pascolo sui pendii dà erosione; ricchezza delle famiglie (e disuguaglianza); le vie degli animali fanno traffico sui sentieri.
- **Luogo sacro e bosco sacro:** la riserva diventa il bosco sacro; tagliarlo offende il sacerdote.
- **Consenso, effetti graduali per gruppo:** anziani → le regole (contenti: le politiche si cambiano a poco prezzo; scontenti: valgono a metà); famiglie → il lavoro (contente: braccia in più, cantieri più rapidi; scontente: qualche famiglia se ne va, poche alla volta); sacerdote → i presagi (contento: più chiari; scontento: ambigui, più voci false). Resta il caso estremo della scissione.

## Scala della città
Struttura scalare a quattro livelli. I dati vivono sempre sul lotto; i livelli superiori sono aggregazioni.

| Livello | Che cos'è | Contiene | Azioni tipiche |
|---|---|---|---|
| Lotto | Particella di proprietà | Proprietario, edificio, abitanti, strati del sottosuolo | Esproprio, demolizione, restauro, cambio d'uso |
| Comparto (gruppo di lotti) | Lotti trattati insieme | Stesso proprietario, stesso fronte stradale, o scelti dal giocatore | Interventi coordinati, accordi con un proprietario o investitore |
| Isolato | Blocco tra le strade | Forma urbana, densità, tipologia | Risanamento, diradamento, regole edilizie |
| Quartiere | Entità politica | Consenso locale, comitati, carattere del quartiere | Piani, vincoli, politiche |

- **Selezione:** 4 menu di selezione, uno per livello, con selezione multipla.
- **Il comando scende verso i lotti:** un'azione di alto livello è un piano che la simulazione traduce nel tempo in modifiche ai lotti, incontrando resistenze (proprietari, ricorsi, comitati).
- **Interventi capillari:** per reti e infrastrutture (es. rifare la fognatura) si seleziona l'area a livello alto (isolati, quartieri) e la simulazione traccia l'intervento lungo le strade, invece di agire lotto per lotto.
- **Il compromesso è una scelta di gioco:** governare per quartieri è veloce ma meno preciso e più conflittuale; per lotti è preciso ma lento.
- **La gerarchia cambia nel tempo:** un boulevard divide un isolato; i quartieri possono essere ridisegnati.
- **La scala predefinita segue la crescita della città:** soprattutto lotto nelle epoche antiche, isolato o quartiere nella metropoli.
- **Quartieri:** entità politica gestita dal giocatore, che ne disegna e ridisegna i confini.

## Topografia
Lo strato più antico della città.
- **Solo natura all'inizio:** la mappa di partenza contiene esclusivamente topografia naturale. Tutto ciò che è artificiale (porti, canali, mura, bonifiche, ponti, strade) nasce in gioco dalle scelte del giocatore.
- **Suggerisce le divisioni:** fiumi e rilievi propongono confini naturali per i quartieri, ma la decisione resta al giocatore.
- **Orienta la fondazione:** guadi, colli difendibili, insenature riparate.
- **Effetti di gioco:** pendenze (fogne a gravità, costi di costruzione), rischio idraulico, geografia sociale (alto/basso, asciutto/umido), conservazione dei resti archeologici, esposizione agli eventi.
- **Il fiume come leva:** confine e risorsa; può essere deviato, canalizzato, coperto per necessità d'igiene o traffico e riaperto quando arriva la sensibilità green.

### Ogni vantaggio naturale ha il suo rischio
Il sito si sceglie bilanciando vantaggi e rischi accoppiati (es. le pendici del vulcano premiano con la fertilità ma espongono all'eruzione).
| Sito | Vantaggio | Rischio |
|---|---|---|
| Pendici di un vulcano | Suolo fertilissimo | Eruzione, terremoti |
| Riva del fiume | Acqua, trasporto, suolo alluvionale | Piene |
| Piede della montagna | Difesa, legna, pietra | Frane, valanghe |
| Costa | Pesca, commercio | Mareggiate, incursioni dal mare |
| Palude | Caccia, difesa naturale | Malattie |
| Colle | Difesa, aria salubre | Acqua scarsa, campi lontani |

**Memoria del rischio:** i rischi più gravi sono rari. Dopo generazioni senza disastri la memoria del pericolo si affievolisce e la crescita spontanea si avvicina al pericolo (le capanne risalgono il vulcano, le case scendono verso il fiume). Un disastro riporta la memoria al massimo. La memoria del rischio è visibile su una mappa tematica.

### Vocabolario della topografia naturale
Ogni mappa si descrive con gli stessi sei strati:
1. **Rilievo:** altimetria, pendenze, colline, crinali, valli.
2. **Idrografia:** fiumi, torrenti, sorgenti, risorgive, falda, paludi, laghi.
3. **Costa:** insenature, golfi, spiagge, scogliere, lagune, isole.
4. **Suolo e geologia:** ghiaie, argille, tufo, calcare, terreno alluvionale; sismicità e vulcanismo.
5. **Clima:** piovosità, venti, escursione termica.
6. **Copertura naturale:** boschi, prati, macchia, zone umide.

## Mappe
**Decisione:** mappe disegnate a mano (il procedurale si valuterà più avanti). Ogni mappa ricrea una topografia naturale verosimile ispirata a una città reale, senza riprodurla e senza elementi artificiali. Dettaglio della prima mappa in `mappa-pedecollinare.md`.

**Metodo (proposta):**
1. Base altimetrica da dati gratuiti (es. SRTM, Copernicus DEM).
2. Semplificare e deformare il terreno (ruotare, specchiare, cambiare scala) in modo che sia verosimile ma non riconoscibile.
3. Ricostruire l'idrografia naturale precedente all'intervento umano: fiumi, torrenti, paludi, costa.
4. Aggiungere suolo, geologia e copertura naturale.
5. Esportare una heightmap per Godot.

**Archetipi di topografia naturale:**
| Archetipo | Ispirazione | Elementi naturali | Sfida |
|---|---|---|---|
| Pedecollinare | Bologna | Colline a sud, alta pianura in leggera pendenza, torrenti con portate irregolari, falda | Acqua scarsa e irregolare, collina contro pianura |
| Pianura delle risorgive | Milano | Pianura piatta, nessun grande fiume, risorgive, piccoli fiumi, falda alta | Nessun limite naturale, acqua sparsa |
| Valle fluviale con isole | Parigi | Fiume largo con meandri e isole, paludi sulle sponde, colline gessose | Guadi e isole come nuclei, sponde umide |
| Colli e ansa fluviale | Roma | Colli tufacei separati da valli, fiume con ansa e isola, paludi, sorgenti | Rilievi frammentati, piene, malaria |
| Golfo vulcanico | Napoli | Golfo ad anfiteatro, colline ripide, vulcano attivo, tufo, fenomeni vulcanici | Pendenze, rischio vulcanico e sismico |
| Anfiteatro calcareo sul mare | Marsiglia | Insenatura profonda e riparata, colline calcaree aride, poca acqua dolce | Mare favorevole, terra arida |
| Altopiano interno | Madrid | Altopiano, fiume modesto, valli secondarie, clima continentale secco | Acqua scarsa, estremi climatici |
| Piana costiera tra due fiumi | Barcellona | Piana tra mare e catena collinare, due fiumi ai lati, colle isolato sulla costa | Spazio delimitato su quattro lati |
| Costa bassa e isole piatte | Copenaghen | Costa piatta, isolotti, stretto di mare, paludi, terreno basso | Acqua ovunque, terreno instabile |
| Penisola tra due mari | Istanbul | Penisola collinare, stretto, estuario profondo, sismicità | Sponde contrapposte, terremoti |
| Fondovalle alpino | Innsbruck, Bolzano | Valle stretta, fiume impetuoso, conoidi, versanti ripidi | Spazio limitato, frane, valanghe, piene |
| Conca montana sismica | L'Aquila | Conca tra montagne, sorgenti, alta sismicità | Terremoto e ricostruzione |
| Crinali senza fiume | Siena | Tre crinali, valli strette, nessun fiume, falde | Acqua da cercare sottoterra |
| Laguna | Venezia | Laguna, isolotti fangosi, barene, maree | Terreno instabile, acqua alta |
| Penisola rocciosa | La Valletta | Penisola calcarea tra due insenature profonde, poca acqua | Spazio finito, roccia |
| Isola costiera | Ortigia (Siracusa) | Isolotto vicinissimo alla costa, sorgenti d'acqua dolce, porti naturali | Nucleo isolato, terraferma vicina |
| Arcipelago | Stoccolma | Isole rocciose tra lago e mare, canali naturali | Città frammentata |

**Prima mappa:** l'archetipo pedecollinare (Bologna).

## Indicatori
**Primo livello: cosa la città È** (costanti in ogni epoca)
- Popolazione
- Accesso ai beni primari (acqua, cibo, riparo)
- Salute
- Prosperità
- Sicurezza
- Coesione / disuguaglianza
- Legittimità (dove il secondo livello si scarica sul primo)

**Secondo livello: come la città viene GIUDICATA** (secondo la sensibilità del periodo, più lo strato locale della cultura). Esempi:
| Epoca | Indicatori di sensibilità |
|---|---|
| Città imperiale | Decoro e monumentalità, Ordine |
| Città in contrazione / comunale | Sacralità, Difesa, Onore delle famiglie, Autonomia comunale |
| Città del principe | Magnificenza, Armonia e prospettiva |
| Città della ragione / industriale | Igiene, Circolazione, Progresso, Ordine pubblico |
| Città di massa | Modernità, Motorizzazione, Casa per tutti |
| Città globale | Città green, Patrimonio e memoria, Inclusione, Mobilità sostenibile |

Gli indicatori di un'epoca passata restano come residuo con peso decrescente.

## Questioni aperte
- Effetti dettagliati di ciascun evento e presagio.
- Durata e scala temporale di ogni epoca (da verificare giocando).
- Elenco dei tratti culturali e loro effetti.
- Mappe di partenza per le epoche successive: preparate a mano all'inizio, generatore procedurale più avanti.
