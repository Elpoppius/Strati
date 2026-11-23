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
- Seconda versione della prova di stile: direzione giusta. Da migliorare il prato (grossolano), il dettaglio a zoom ravvicinato e la forma e il riempimento delle chiome.

**Prossimo passo**
- Fede: preparare il PC dedicato (Godot 4.7.2, Blender 5.3, GitHub Desktop: vedi `docs/setup-pc.md`); continuare a provare il Prototipo 0.
- Fede: aprire `gioco/project.godot` con Godot 4.7.2 sul PC dedicato, premere F5 e riportare cosa si vede e come risponde (vedi `docs/setup-pc.md`).
- Fede: dare un parere sulla terza versione di alberi e prato (`docs/immagini/prova-stile-v3-*.jpg`); sul PC, avvicinare lo zoom al massimo vicino al terrazzo centrale, ruotare con Q/E e dire come appaiono ombre e luce (gli alberi si vedono nel gioco solo con `test/foto_asset.gd`, per ora non sono posati sulla mappa).
- Claude: dopo il parere di Fede, completare il lotto del villaggio nello stile scelto, oppure portare in Godot il ciclo del villaggio.
- In sospeso: recinto come primo strumento di regolazione nel Prototipo 0.
