# HUD

*Interfaccia a schermo. Codice: `gioco/script/hud.gd` (classe `Hud`), collegata in `gioco/script/principale.gd`. Immagine: `docs/immagini/hud-24-11.jpg`.*

## Decisioni di Fede (24/11/2026)
- **Disposizione** come in Age of Empires: **controlli delle mappe a destra, comandi a sinistra**.
- **Stile svizzero**, quello della segnaletica della metropolitana di Milano (Noorda) e di New York (Vignelli): deve dialogare con l'urbanistica, presente ma non invasivo né protagonista, con carattere.
- **Colori solo con un significato**, senza esagerare.

## Regole dello stile (proposta di Claude, da confermare con Fede)
- **Riquadri scuri a filo dei bordi** dello schermo, testo bianco, niente angoli arrotondati né ombre. Righe sottili per separare le sezioni.
- **Gerarchia con grandezza e peso del testo**, non con il colore. Intestazioni di sezione in maiuscolo, piccole, spaziate, grigie, sopra una riga sottile.
- **Scelta corrente per inversione:** fondo bianco e testo nero, come un cartello.
- **Colori con significato:**
  | Colore | Significato |
  |---|---|
  | grigio chiaro | Terreno (mappa neutra) |
  | blu | Acqua |
  | verde | Fertilità |
  | rosso | Rischio di piena; in generale **pericolo o azione irreversibile** |
  | giallo | Energia dell'acqua |
  | verde bosco | Caccia e pesca (25/11/2026) |
  | ocra | Abitato e contado (25/11/2026) |
  | viola | Memoria del suolo (25/11/2026) |

  Ogni mappa tematica ha il suo bollino tondo con il numero del tasto, come una linea della metropolitana. I comandi hanno un quadratino con la lettera del tasto, senza colore, tranne quelli irreversibili (bollino rosso). Le legende delle mappe usano gli stessi colori del bollino.
- **Carattere: Inter** (decisione di Fede del 24/11/2026: un carattere con licenza SIL Open Font License, rispettandone le regole), il più vicino all'Helvetica della grafica svizzera. Regular per i testi, Medium di base, Bold per titoli, valori e lettere dei tasti. File e licenza in `gioco/asset/caratteri/inter/`, elenco delle licenze in `docs/licenze.md`.

## Disposizione (esempi di Age of Empires IV mandati da Fede, 24/11/2026)
Il campo di gioco resta libero: l'interfaccia sta in una fascia in basso e in due piccoli riquadri in alto.
- **In alto al centro:** l'anno e i comandi del tempo (pausa, 2, 6 e 15 anni al secondo), come l'indicatore dell'età.
- **In alto a sinistra:** la cronaca, gli ultimi quattro fatti, come gli obiettivi.
- **In alto a destra:** le prestazioni (fotogrammi al secondo, alberi, cache), piccole, senza fondo.
- **Fascia in basso a cinque blocchi** (decisione di Fede del 24/11/2026), da sinistra:
  1. **Info:** gli indicatori (popolazione, cibo, salute, legittimità), come le risorse; il valore diventa rosso quando è in pericolo. Larghezza fissa di 300 px con la colonna dei nomi fissa e i valori allineati a destra; le cifre dei valori (e dell'anno in alto) sono tabellari, tutte larghe uguali, così i numeri che crescono non spostano le colonne né i blocchi accanto (segnalato da Fede il 24/11). Un valore che non ci sta si tronca con i puntini.
  2. **Descrizione:** la scheda dello strumento scelto (come la scheda dell'unità selezionata): nome, cosa fa o messaggio dell'ultima azione, lettura del lotto sotto il puntatore.
  3. **Costruzione:** schede Insediamento, Territorio (Zona agricola, Z; Campo, C), Vie, Edifici. Dopo la fondazione il tasto Fondare sparisce, e con lui la scheda Insediamento finché resta vuota (torna se il villaggio è abbandonato).
  4. **Gestione:** scheda Politiche (tasto P, apre il pannello delle politiche) e, allo stesso livello, scheda **Ammodernamento** (decisione di Fede) con un tasto per settore: oggi Agricolo; poi Viario (strade), Abitativo e gli altri. Il tasto di un settore è spento finché non c'è niente da ammodernare e diventa invertito quando l'ammodernamento è attivo; un clic lo avvia o lo sospende.
  5. **Strumenti:** schede Demolizione (Demolisci, X: vale su tutto e non è una costruzione) e Prova (+10 anni, Y, solo per le prove).

  I blocchi 3, 4 e 5 funzionano allo stesso modo, così il layout è pronto per le voci future: titolo piccolo in maiuscolo, in alto le schede, sotto i **tasti** della scheda aperta (quadrati: pittogramma al centro, nome sotto, lettera del tasto piccola e grigia nell'angolo), in fondo una riga che dice a cosa serve la scheda. Scegliere un comando, anche da tastiera, apre la sua scheda nel suo blocco senza toccare le schede degli altri blocchi. Un comando può essere uno strumento (resta scelto, si usa cliccando sulla mappa) o un'azione immediata. Il segno rosso nell'angolo vuol dire azione irreversibile. I blocchi hanno tutti la stessa altezza.
- **In basso a destra, piccoli** (Fede: cliccabili ma non importanti, come i tasti attorno alla minimappa di Age of Empires IV): la minimappa (150 px) ruotata come la vista, con il riquadro di ciò che inquadra la camera e il centro del villaggio (un clic o un trascinamento spostano la camera); accanto, i bollini tondi delle cinque mappe tematiche (numero e colore, nome nel suggerimento) e i quadratini delle sovrapposizioni (G lotti, I isoipse). La mappa scelta ha un anello bianco. Sopra, solo quando è attiva una mappa tematica, una legenda sottile.
- **Politiche** (decisione di Fede del 24/11/2026: le usanze non sono oggetti da costruire, sono politiche): pannello a parte, sopra la fascia, che si apre e si chiude con il tasto Politiche (P) nel blocco Gestione e non ferma il tempo; se le politiche non ci stanno, il pannello scorre (non copre la cronaca). Ogni politica ha un titolo, una riga che dice di cosa si tratta, le opzioni come tasti (quella in vigore è invertita) e sotto cosa comporta quella in vigore. Cambiarne una costa un po' di consenso. Una politica che per ora non ha effetto si vede ma è spenta, con una riga grigia che dice perché (decisione di Fede: il tasto c'è già, disattivato).
- **Fondazione** (richiesta di Fede del 24/11/2026: al momento di fondare gli indicatori del terreno devono essere visibili e chiari): con lo strumento Fondare, prima della fondazione, la lettura del sito prende il posto della descrizione e dei tre blocchi dei comandi, che lì non servono. Titolo (il sito o "Terreno aperto"), sette voci in griglia (acqua, fertilità intorno, boschi per caccia e raccolta, pesca, rischio di piena, difesa, aria) con il valore a parole e una barra; rosso se la voce è sfavorevole; in fondo quante voci sono sfavorevoli e cosa fa il clic. Si aggiorna muovendo il puntatore (quando cambia il punto della mappa). Dopo la fondazione tornano descrizione e comandi.
- **Notifiche** (decisione di Fede del 24/11/2026: il ritmo è meditativo, non incalzante): per ciò che non chiede un intervento (piene, carestie, siccità, crisi). Una colonna di righe sopra la minimappa, le più nuove in basso, al massimo quattro; si spengono da sole dopo circa 9 secondi; un clic porta la camera sul luogo. Segno rosso per i pericoli, grigio per il resto. Non fermano mai il tempo.
- **Scelte** (solo le scelte vere: presagi, primo cattivo raccolto, affollamento, stranieri se la politica è "caso per caso"): finestra al centro; il tempo si ferma finché non si sceglie. Niente finestre con il solo tasto "Continua" (tranne abbandono e fine della partita).
- **Anteprima dei sentieri** (come in Cities: Skylines): nastro trasparente dall'inizio al puntatore, bianco se si può tracciare, rosso se no, con accanto la lunghezza o il motivo ("non collegato al villaggio" se il tratto è staccato); un quadratino segna l'inizio; mentre lo strumento è attivo i sentieri esistenti si schiariscono.
- **Strumento sulla mappa:** un cerchio sottile bianco (rosso se l'azione è irreversibile) segue il puntatore; per Fondare mostra fin dove arriveranno i campi. 
- **Zona agricola:** si stende come un pennello (tenendo premuto il tasto sinistro e trascinando); con Zona agricola o Campo la zona si vede come un velo chiaro con un bordo sottile.
- **Contado:** con lo strumento Zona agricola o Campo una linea tratteggiata segna il confine della terra coltivabile, che cresce con gli abitanti; fuori, il terreno è appena velato. Un clic che esce dal confine dice quanti campi restano fuori e perché.
- **Griglia magnetica** (idea di Fede, come in Cities: Skylines): mentre si pone qualcosa, attorno al puntatore compaiono i quadrati a cui lo strumento si aggancia, e si schiariscono quelli che verranno presi. Campi: celle da 40 m della simulazione, prese se il loro centro sta nel cerchio. Granaio: lotti da 20 m, l'edificio si aggancia al centro del lotto. Fondare: il cerchio si aggancia al punto della mappa più vicino (niente griglia; il cerchio mostra il contado iniziale di 400 m). Fuori da questi momenti la griglia non si vede.

## Pittogrammi
In `gioco/asset/icone/`, SVG fatti da noi: bianchi su trasparente, 28 px su una griglia di 32, tratti pieni e squadrati, nessun colore (il colore resta per i significati: il segno rosso dell'irreversibile sta sul tasto, non nell'icona). Nell'HUD si tingono di nero quando il tasto è scelto. Si aggiungono a una voce con `"icona": "nome"`.

| Icona | Comando | Figura |
|---|---|---|
| `fonda` | Fondare | palo piantato con la bandiera |
| `zona_agricola` | Zona agricola | area tratteggiata con dentro un campo |
| `campi` | Campo | due appezzamenti con i solchi in versi diversi |
| `sentiero` | Sentiero | traccia a tratti che serpeggia tra due punti |
| `granaio` | Granaio | casa delle scorte su pali |
| `demolisci` | Demolisci | costruzione cancellata da una croce |
| `politiche` | Politiche | anziani seduti in cerchio attorno al fuoco |
| `ammodernamento_agricolo` | Ammodernamento · Agricolo | solchi di un campo e una freccia che sale |
| `collega` | Collega alla rete | un tratto che si aggancia a un nodo della rete |
| `anni` | +10 anni | clessidra |
| `legnaia` | Legnaia | tronchi accatastati e l'ascia |
| `capanno_pesca` | Capanno da pesca | un pesce sopra un'onda |
| `posta_caccia` | Posta di caccia | un palco di corna |
| `pascolo` | Pascolo | graticcio con un ciuffo d'erba |
| `luogo_sacro` | Luogo sacro | la pietra eretta tra i pali del cerchio (25/11/2026) |
| `bosco_sacro` | Bosco sacro | un albero dentro un cerchio (25/11/2026) |

Sono una prima serie (proposta di Claude), da confermare con Fede.

## Diciture
| Dicitura | Dove | Significato |
|---|---|---|
| Popolazione | indicatori | abitanti del villaggio |
| Cibo 543 / 121 l'anno | indicatori | scorte di cibo / quanto ne consuma il villaggio in un anno (rosso se le scorte sono sotto il 30% del consumo) |
| Abbondanza | indicatori (dal 25/11/2026) | da 0 a 100: cibo che avanza (mesi di scorte), salute, spazio (case per tutti); le nascite la seguono: sopra 62 la popolazione cresce, sotto cala piano; rossa sotto 62. La salute non ha più una riga: è una parte dell'abbondanza |
| Consenso | indicatori (al posto di Legittimità, dal 25/11/2026) | da 0 a 100: media del consenso degli anziani (le usanze) e delle famiglie (il lavoro), e del sacerdote dal luogo sacro; sotto 5 per quattro anni il villaggio si divide |
| Legna 246  +16 −19 | indicatori (dal 25/11/2026) | legna in catasta, raccolta e consumata nell'anno; rossa se non basta per una casa e se ne consuma più di quanta se ne raccoglie |
| 5850 a.C. · Villaggio | in alto | l'anno e la tappa raggiunta (la progressione si vede sempre) |
| Focus | sopra il blocco Info, con un clic su un indicatore | pannello di focus (decisione di Fede del 25/11/2026): di cosa è fatto l'indicatore, perché sale o scende (cause in chiaro), gli ultimi 100 anni, un tasto per la mappa tematica giusta; non ferma il gioco; Esc o clic destro lo chiude. Immagine `immagini/focus-consenso-25-11.jpg` |
| Fertilità, Rischio di piena, Distanza, Bosco | Descrizione, con Zona agricola o Campo | lettura del terreno sotto il puntatore per lo strumento scelto (decisione di Fede del 25/11/2026), come in fondazione: barra, rosso se sfavorevole. Granaio: rischio di piena, distanza dal centro, legna; Sentiero: pendenza, guado, rischio di piena. Immagine `immagini/lettura-zona-25-11.jpg` |
| ‖ 2 6 15 | in alto, accanto all'anno | pausa, oppure 2, 6, 15 anni al secondo |
| Insediamento, Territorio, Vie, Edifici | schede dei comandi | menù logici: dove nasce il villaggio; a cosa si destina la terra; come ci si muove; costruzioni comuni |
| Costruzione, Gestione, Strumenti | blocchi in basso | cosa si costruisce; come si governa; comandi che valgono su tutto |
| Politiche | Gestione | apre il pannello delle regole del villaggio (P) |
| In comune / Alle famiglie | Politiche: divisione del raccolto | il raccolto si divide tra tutti (piace agli anziani) o ogni famiglia tiene il suo (più raccolto, piace alle famiglie); si apre a 60 abitanti |
| Allargare l'abitato / Emigrare | Politiche: villaggio affollato (dal 25/11/2026, al posto della scelta che fermava il gioco) | quando mancano case per molte famiglie: l'abitato cresce verso i campi, oppure chi non trova posto parte; si apre a 150 abitanti |
| Aperta / Caso per caso / Chiusa | Politiche: accoglienza degli stranieri | chi arriva resta sempre; a ogni arrivo si decide; viene sempre mandato via. All'inizio vale la scelta fatta al primo arrivo; il pannello si apre a 150 abitanti |
| Ammodernamento · Agricolo | Gestione | avvia o sospende il rifacimento dei campi vecchi con la tecnica nuova, un po' ogni anno pagando cibo (spento finché non c'è una tecnica nuova) |
| Opzioni · Collega alla rete | Descrizione, con lo strumento Sentiero | acceso: ogni sentiero parte dal punto più vicino della rete (un clic dove finisce); spento: il sentiero comincia dove vuoi |
| Fonti di cibo: Campi, Caccia, Pesca | blocco Info, sotto gli indicatori (richiesta di Fede: deve essere ben leggibile da dove si attinge e quanto si usa la risorsa) | per ogni fonte "preso / disponibile" dell'anno e una barra sottile con la quota usata: bianca; rossa se la risorsa si esaurisce (si caccia troppo); grigia con la scritta "spenta" se la fonte è spenta. Campi: raccolto / raccolto se si lavorassero tutti i campi. Un clic su una fonte apre le politiche |
| Caccia 10 / 18 ↓ | Fonti di cibo | freccia: la selvaggina cala o cresce; rosso: si caccia troppo (selvaggina sotto il 40%); il suggerimento dice la selvaggina in percentuale |
| Agricoltura, Caccia e raccolta, Pesca | Politiche: fonti di cibo | interruttori (più accesi insieme): una fonte spenta non si lavora e le sue braccia passano alle altre; almeno una resta accesa; cambiare costa −2 di consenso |
| Densità 38 ab/ha | indicatori | abitanti per ettaro (100 × 100 m) nell'abitato, il cerchio che contiene le case; rossa quando le case non bastano (affollamento). Spiegato nel suggerimento al passaggio |
| Demolizione, Prova | Strumenti | schede degli strumenti |
| Demolisci | Strumenti | toglie ciò che si può demolire nel cerchio; non agisce su fiumi e paludi |
| +10 anni | Prova | fa passare dieci anni subito, solo per provare la ricrescita del bosco |
| 1–8 | bollini accanto alla minimappa | mappe tematiche: terreno, acqua, fertilità, rischio di piena, energia dell'acqua, caccia e pesca, abitato e contado, memoria del suolo |
| G, I | quadratini accanto alla minimappa | griglia dei lotti da 20 m, isoipse ogni 25 m |
| fps, alberi (livello), cache | in alto a destra | prestazioni, per le prove sui PC |

## Tasti
1–8 mappe · G griglia · I isoipse · F fondare · Z zona agricola · C campo · N pascolo · B bosco sacro · V sentiero · H granaio · L legnaia · K capanno da pesca · T posta di caccia · O luogo sacro · Spazio pausa o riprendi · + e − velocità del tempo · X demolisci · P politiche · R rapporti di forza · Y +10 anni · [ e ] raggio dello strumento · Esc o clic destro chiude il pannello di focus o le politiche, chiude la catena dei sentieri o toglie lo strumento · Q E ruota · rotella zoom · tasto destro trascinato, tasto centrale o WASD sposta · Home torna al sito.

## Specchietti in gioco (decisione di Fede del 26/11/2026)
Poche parole e barre; il perché esteso al passaggio del puntatore. Il gioco non si ferma.
- **Conseguenze** (`Hud.imposta_conseguenze`, contenuti da `Partita.conseguenze`): un pannello sopra la scheda dello strumento, largo come la scheda, con in testa "CONSEGUENZE · strumento" e cinque righe: Chi guadagna, Chi perde (gruppi con ▲ ▼ e il motivo breve), Sul territorio, Costo (rosso se è irreversibile), Resta. Una riga per voce, al massimo 52 caratteri. Si ricalcola cinque volte al secondo, solo se cambia qualcosa; si fa da parte quando si aprono il focus o le politiche. Immagine `docs/immagini/conseguenze-26-11.jpg`.
- **Rapporti di forza** (il pannello del Consenso, con un clic sull'indicatore o il tasto R; contenuti da `Partita.rapporti_di_forza`): in testa "RAPPORTI DI FORZA", il consenso e chi governa; poi una riga per gruppo con la barra del **peso** (quanto conta) e quella dell'**umore** (rossa sotto 40), la parola e la freccia di tendenza; sotto, la **tensione** e **si muove verso** (gli assi dell'identità detti a parole); in fondo l'andamento. Il perché di ogni gruppo (cosa vuole e le cause di oggi) sta al passaggio sopra la sua riga. Immagine `docs/immagini/rapporti-di-forza-26-11.jpg`.
- **Scheda della famiglia** (26/11/2026, nel pannello di focus; un clic su una persona o su una casa): in testa "FAMIGLIA", il nome e quante persone; sotto, casa e da quando; poi righe con l'etichetta a sinistra (Lavoro, Ha, Umore con la barra, Vorrebbe), al massimo 52 caratteri, con il perché al passaggio del puntatore. Contenuti da `Partita.dati_famiglia`. Immagine `docs/immagini/famiglia-26-11.jpg`.

## Tutorial (decisione di Fede del 26/11/2026)
Riquadro al centro come le scelte, con il velo scuro e il tempo fermo (`Hud.mostra_tutorial`): in testa "TUTORIAL · tappa · pagina di pagine", il titolo, le due o tre righe; sotto, la domanda ("Cosa fa un luogo sacro?  +") che apre e chiude la spiegazione completa; in fondo la casella "Salta i tutorial" (quadratino come gli interruttori delle opzioni) e il tasto bianco Avanti, o Continua all'ultima pagina. I testi stanno in `script/tutorial.gd`. Foto di controllo: `test/foto_tutorial.gd -- uscita [aperta]`, immagine `docs/immagini/tutorial-26-11.jpg`.

## Partita (Prototipo 0 in Godot)
- **Indicatori** (dal 25/11/2026): popolazione, abbondanza, consenso, cibo (scorta / consumo dell'anno), legna, densità, più le fonti di cibo. Rossi quando sono in pericolo. Un clic apre il pannello di focus.
- **Comandi:** Fondare, Campi, Sentiero, Granaio; politiche a parte (divisione del raccolto, accoglienza degli stranieri).
- **Scelte:** finestra al centro, con tipo (presagio, momento decisivo, evento, crisi…), titolo, testo e opzioni con la loro conseguenza in grigio. Il tempo si ferma finché non si sceglie.
- **Notifiche:** vedi sopra.
