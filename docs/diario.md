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
- **Primo lotto di asset dell'epoca del villaggio** (`gioco/asset/villaggio/`, 11 modelli): tre case lunghe, capanna tonda, granaio su pali, palizzata e varco, luogo sacro, due querce, canneto. Generati da script Blender, stile "plastico architettonico" (proposta). Guida e catalogo in `docs/asset.md`, anteprima in `docs/immagini/asset-villaggio.png`, verifica in `gioco/test/verifica_asset.gd` (superata).
- Strumenti nell'ambiente di Claude: Godot 4.7.2 senza grafica e Blender 5.3 come modulo Python; catena Blender → glTF → Godot provata con una casa lunga neolitica.

**Decisioni (Fede)**
- Visuale isometrica 3D con camera fissa ruotabile e mappe tematiche; tempo continuo con pausa.
- Archetipi di città verosimili; città reali solo negli scenari (rimandati).
- Eventi epocali esterni e inevitabili, in una finestra temporale; presagi veri, minori e falsi.
- Abusivismo trattato come fenomeno urbanistico (crescita fuori regola), non come gestione politica di condoni e repressione.
- Lavoro su due account Claude con il repository `Elpoppius/Strati` come fonte unica. Nome del progetto: Strati.
- Godot 4.7.2 con renderer Compatibilità (tre PC con schede video diverse).
- Base Godot: partire dal terreno, dalla camera isometrica e dalla griglia dei lotti.

**Prossimo passo**
- Fede: preparare il PC dedicato (Godot 4.7.2, Blender 5.3, GitHub Desktop: vedi `docs/setup-pc.md`); continuare a provare il Prototipo 0.
- Fede: aprire `gioco/project.godot` con Godot 4.7.2 sul PC dedicato, premere F5 e riportare cosa si vede e come risponde (vedi `docs/setup-pc.md`).
- Fede: dare la direzione artistica sugli asset (stile, colori, proporzioni) guardando `docs/immagini/asset-villaggio.png`.
- Claude: in attesa delle prove di Fede. Proposte per il passo successivo: portare in Godot il ciclo del villaggio (fondazione, campi, case) oppure ritoccare l'aspetto del terreno secondo le indicazioni di Fede.
- In sospeso: recinto come primo strumento di regolazione nel Prototipo 0.
