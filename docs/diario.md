# Diario di bordo

Voci più recenti in cima.

## 23/11/2026
**Fatto**
- Definite le basi di design: concept, sette pilastri, epoche (6 macro-ere × 2 epoche), eventi soglia con presagi, indicatori a due livelli, culture emergenti, futuro, scala della città (lotto, comparto, isolato, quartiere), topografia e archetipi, ciclo di gioco del villaggio. Vedi i documenti in `docs/`.
- Disegnata la prima mappa: archetipo pedecollinare (ispirazione bolognese), solo elementi naturali, sei siti di fondazione.
- Prototipo 0 (pagina web giocabile, `prototipi/prototipo0/index.html`): villaggio sulla mappa pedecollinare, sei versioni pubblicate dopo le prove di Fede (stabilità dell'impaginazione, cronaca sotto la mappa, zoom, conferme visive, case lunghe, sentieri ad albero, granaio da posizionare, avvisi solo per eventi rilevanti).
- Creato il repository `Elpoppius/Strati` con documenti di design, diario, istruzioni per Claude, guida di installazione e prototipo. GitHub collegato a entrambi gli account Claude di Fede.
- Collegato il repository al secondo account Claude e verificato da smartphone: lettura e scrittura funzionano. Nota: all'inizio della sessione la richiesta di scrittura può essere bloccata da un controllo automatico dei permessi; basta che Fede la autorizzi esplicitamente e si riprova.
- **Base del progetto Godot** (`gioco/`): terreno 3D della mappa pedecollinare (10 × 10 km, griglia da 40 m, esagerazione verticale 1,5) con tinte ipsometriche, boschi, paludi, isoipse ogni 25 m e acque dai bordi morbidi; camera isometrica ortografica che ruota a scatti di 90° (Q/E), zoom con la rotella, spostamento con WASD o tasto destro; mappe tematiche Terreno, Acqua, Fertilità, Rischio piena (tasti 1–4); griglia dei lotti da 20 m visibile da vicino (G); lettura del lotto sotto il puntatore; etichette dei sei siti. Verifiche senza grafica tutte superate; immagini reali in `docs/immagini/`.
- Primo lotto di asset in stile "plastico architettonico" (11 modelli): **scartato da Fede**, che vuole uno stile verosimile anche nei colori e alberi meno poligonali. Rimossi dal repository (restano nella cronologia di Git).
- **Prova di stile verosimile** (`gioco/asset/prove_stile/`, 5 modelli: casa lunga, capanna tonda, granaio, due querce): texture procedurali generate da script (paglia, argilla, legno, corteccia, pietra, erba, foglie), tetti spessi e irregolari, pali a vista, querce con rami e chioma di foglie. Il terreno del gioco ora usa una texture d'erba tinta dalla zona. Seconda versione ispirata ad Age of Empires IV: texture più "dipinte", tetti più alti e sporgenti, occlusione ambientale cotta nei vertici, alberi più pieni in tre toni, prato più vivo. Guida in `docs/asset.md`, immagini in `docs/immagini/prova-stile-verosimile-*.png`.
- **Terza versione di alberi e prato**, dopo il parere di Fede sulla seconda e le sue reference di AoE IV: zoom fino a 40 m; foglie singole e grandi, una texture per specie; chiome a lobi con normali sferiche e ombra interna calcolata; cinque specie (quercia, carpino, pioppo, acero autunnale, arbusto); prato a fili sottili con chiazze di erba secca e meno ripetizione; piani di taglio della camera stretti per ombre nitide da vicino. Dettagli in `docs/asset.md`, immagini in `docs/immagini/prova-stile-v3-*.jpg`. Ombre: Fede ha notato che mancavano del tutto. Non era un limite dell'ambiente di Claude ma due errori del progetto: il sole stava alle spalle della camera (ombre nascoste dietro gli oggetti) e la camera era a 20 km (ombre sfumate fino a sparire). Ora il sole gira con la camera (da sinistra, ombre lunghe verso destra, come chiesto da Fede) e la distanza della camera segue lo zoom: le ombre si vedono e sono nitide da vicino.
- **Terreno migliorato:** boschi con bordi irregolari (non più a gradini da 40 m) e una volta di chiome dipinta, in attesa degli alberi veri; terra che affiora sui pendii ripidi.
- **Prato senza ripetizioni:** verde, ingiallito e secco distribuiti da rumori unici per tutta la mappa e dai dati del luogo (acqua, fertilità), bordi morbidi senza scalini, variazione di tono minuta da vicino.
- **Acqua:** profondità che sfuma dalla riva al centro, increspature animate senza motivo ripetuto, riflessi del cielo, schiuma lungo la riva, sponda bagnata; risolte le fasce a gradini (distanza dalla riva ora in virgola mobile). Nuovo documento `docs/resa-grafica.md` sui sistemi grafici comuni a tutte le mappe.
- **Prima prova di Fede sul portatile** (sera): Godot 4.7.2 confermato, il progetto si apre e funziona senza errori. Pareri di Fede: non gli piace la resa puntinata del terreno; non vuole le isoipse sulla mappa; l'acqua è ancora un po' piatta; l'area dei gessi è quadrata; le mappe tematiche sono squadrettate. L'area dei gessi è quadrata perché il generatore della mappa la definisce come un rettangolo (`strumenti/mappe/genera_pedecollinare.py`): è un segnaposto.
- **Correzioni dopo la prova sul portatile** (sera), immagine in `docs/immagini/correzioni-portatile-23-11.jpg`:
  - isoipse spente di serie, attivabili con il tasto I o con la casella nel pannello; il rilievo ora si legge dall'ombreggiatura dei pendii rispetto al sole;
  - resa puntinata: la causa era che le texture erano importate senza mipmap; ora le hanno tutte, e lo shader attenua i dettagli minuti da lontano; boschi con margini senza gradini e, da lontano, gruppi di alberi senza trama ripetuta;
  - area dei gessi: macchia irregolare al posto del rettangolo, colore meno bianco;
  - mappe tematiche: passaggi graduali tra le fasce di fertilità e di rischio di piena, vicinanza all'acqua in linea d'aria (portata 9 celle, stessa area di prima);
  - acqua: sponde modellate dalla luce, ombra dell'argine sull'acqua, tre toni di profondità, fondale che traspare, chiazze di vento visibili anche da lontano.
  Verifiche senza grafica superate (base e asset). Godot sul portatile reimporterà le texture alla prima apertura.
- **Seconda prova di Fede** (dopo il Pull): meglio. Chiesti l'ombreggiatura dei rilievi anche sull'acqua e paludi senza quadretti. Fatto: l'acqua prende l'ombreggiatura del versante; paludi e gessi disegnati dallo shader (texture `zone_speciali`) con bordi irregolari; paludi con erba umida, canneti e pozze d'acqua ferma; gessi a chiazze che da lontano si fondono. Immagine: `docs/immagini/paludi-gessi-acqua-23-11.jpg`.
- Conflitto in GitHub Desktop sul portatile: Godot riscriveva da solo i file `.import` delle texture quando le rilevava in 3D. Disattivato (`detect_3d/compress_to=0` in tutti i file `.import`).
- Nel pannello Output di Fede, all'apertura dell'editor: quattro errori `core/io/file_access.cpp:967`. Probabilmente file di cache dell'editor mancanti alla prima apertura (non verificato): da ricontrollare se si ripetono.
- Strumenti nell'ambiente di Claude: Godot 4.7.2 senza grafica e Blender 5.3 come modulo Python; catena Blender → glTF → Godot provata con una casa lunga neolitica.

**Decisioni (Fede)**
- Visuale isometrica 3D con camera fissa ruotabile e mappe tematiche; tempo continuo con pausa.
- Archetipi di città verosimili; città reali solo negli scenari (rimandati).
- Eventi epocali esterni e inevitabili, in una finestra temporale; presagi veri, minori e falsi.
- Abusivismo trattato come fenomeno urbanistico (crescita fuori regola), non come gestione politica di condoni e repressione.
- Lavoro su due account Claude con il repository `Elpoppius/Strati` come fonte unica. Nome del progetto: Strati.
- Godot 4.7.2 con renderer Compatibilità (tre PC con schede video diverse).
- Base Godot: partire dal terreno, dalla camera isometrica e dalla griglia dei lotti.
- Stile degli asset: verosimile, anche nei colori; no allo stile "plastico" e agli alberi con pochi poligoni. Riferimento per l'aspetto: Age of Empires IV.
- Luce: sole da sinistra, ombre lunghe proiettate verso destra sullo schermo.
- Alberi, terreni, ombre, asset e acqua sono sistemi comuni a tutte le mappe, non lavoro sulla singola mappa.
- Alberi e disboscamento: gli alberi sono dati di gioco, non decorazione. Un'area disboscata resta nei dati come "area disboscata" e il suo destino dipende da cosa la sostituisce: se è costruita il bosco è perso ma ne resta memoria; se è solo abbattuta può ricrescere. Conta soprattutto l'interazione con il gameplay.
- Terreno: priorità alla resa del prato; niente texture ripetute nelle parti aride. Gli alberi veri andranno posati sulla mappa al posto della volta di chiome dipinta.
- Isoipse: tolte dalla vista normale; il rilievo si legge con luce e ombre; isoipse attivabili con un tasto.
- Seconda versione della prova di stile: direzione giusta. Da migliorare il prato (grossolano), il dettaglio a zoom ravvicinato e la forma e il riempimento delle chiome.

**Prossimo passo**
- Fede: preparare il PC dedicato (Godot 4.7.2, Blender 5.3, GitHub Desktop: vedi `docs/setup-pc.md`); continuare a provare il Prototipo 0.
- Fede: aprire `gioco/project.godot` con Godot 4.7.2 sul PC dedicato, premere F5 e riportare cosa si vede e come risponde (vedi `docs/setup-pc.md`).
- Fede: dare un parere sulla terza versione di alberi e prato (`docs/immagini/prova-stile-v3-*.jpg`); sul PC, avvicinare lo zoom al massimo vicino al terrazzo centrale, ruotare con Q/E e dire come appaiono ombre e luce (gli alberi si vedono nel gioco solo con `test/foto_asset.gd`, per ora non sono posati sulla mappa).
- Claude, prossima sessione (rimandato da Fede alla prossima):
  - posare gli alberi veri sulla mappa al posto della volta di chiome dipinta: boschi e alberi sparsi, istanze multiple, versione leggera per la distanza, specie scelta in base al luogo;
  - alberi come dati modificabili: abbattere o costruire su un'area boscata la segna come "area disboscata" (costruita: bosco perso ma ricordato; solo abbattuta: può ricrescere); il terreno sotto cambia (terra battuta, terra nuda, erba rada) con una mappa dell'uso del suolo aggiornabile durante il gioco; progettare l'interazione con il gameplay (proposte di Claude da discutere: legname, rischio di frane e piene più rapide, ricrescita per stadi da arbusti ad alberi);
  - acqua: corrente nel verso del fiume, rapide e cascate sui torrenti, paludi con acqua bassa e canne, livelli che cambiano con le piene;
  - alberi: carte viste di taglio ai bordi delle chiome;
  - texture di paglia e argilla delle case da rivedere per lo zoom ravvicinato;
  - poi completare il lotto del villaggio nello stile scelto;
  - portare in Godot il Prototipo 0 (ciclo del villaggio: fondazione, campi, case, sentieri, granaio, stagioni) sulla mappa vera, con la simulazione separata dalla grafica e verificabile senza grafica (proposta di Claude, da confermare con Fede).
- Fede: Fetch e Pull in GitHub Desktop, riaprire il gioco sul portatile e dire se puntinato, isoipse, gessi, mappe tematiche e acqua ora vanno bene.
- In sospeso: recinto come primo strumento di regolazione nel Prototipo 0.
