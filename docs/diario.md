# Diario di bordo

Voci più recenti in cima.

## 24/11/2026
**Fatto**
- **Verifica del lavoro del 23/11** (fatto con l'altro account): l'importazione in Godot è pulita e non modifica i file `.import`; verifiche base, asset e alberi superate; la mappa rigenerata dagli script è identica byte per byte (dati grezzi e `mappa.res`); foto della scena a 600 m e a 4 km senza errori (a parte l'audio, che manca nell'ambiente di Claude); il Prototipo 0 non ha errori di sintassi. I quattro errori `file_access.cpp:967` visti nell'editor di Fede non si riproducono aprendo il progetto da zero senza grafica: da ricontrollare se compaiono ancora.
- **Documenti allineati:** `produzione-e-collaborazione.md` (asset nello stile verosimile al posto del "plastico", terreno generato da codice, percorso aggiornato), `pilastri-e-decisioni.md` (riga sugli asset), `resa-grafica.md` (alberi: numeri e prestazioni), `CLAUDE.md` (nuove verifiche e cache). Allineati al repository anche i documenti del Progetto Claude dell'account usato oggi, che erano fermi a prima del repository (Godot 4.3, nome del repository sbagliato).
- **Regola comune ai due account** (data da Fede): all'inizio di ogni conversazione aprire il repository `Elpoppius/Strati`, leggere `CLAUDE.md` e `docs/diario.md` e seguire `CLAUDE.md`; alla fine aggiornare il diario e caricare le modifiche.
- **Alberi più rapidi da caricare.** Segnalazione di Fede: sul PC di casa (GTX 1050 mobile) la mappa impiegava 5–6 s a riempirsi di alberi.
  - Calcolo più veloce con risultato identico albero per albero (impronta dei dati di tutta la mappa uguale prima e dopo): si saltano in blocco i riquadri dove di sicuro non cresce nulla e si evitano oggetti temporanei nei calcoli ripetuti. Su un processore: da 19 a 10 s nell'ambiente di Claude (che è lento e ha in pratica un solo processore).
  - Calcolo in sottofondo su tutti i processori meno uno, ciascuno con una copia propria dei dati della mappa. Prima girava su un solo thread a bassa priorità. Il guadagno vero si vedrà sui PC di Fede.
  - **Cache su disco:** finito il primo calcolo, gli alberi si salvano in `user://cache/` (circa 20 MB nella cartella dei dati dell'utente, fuori dal repository). Dagli avvii successivi si caricano in circa 0,13 s, prima che la mappa compaia. La cache si scarta da sola se cambiano la mappa o `alberi.gd`.
  - Il pannello ora dice da dove vengono gli alberi e quanto ci hanno messo ("alberi calcolati in … s" oppure "alberi dalla cache in … ms").
  - Nuovi test: `test/verifica_cache_alberi.gd` (salvataggio, caricamento, scarto di una cache non valida o rovinata) e `test/misura_alberi.gd` (tempi e impronta dei dati). Tutte le verifiche superate.
- **Disboscamento e uso del suolo** (regole di Fede, vedi Decisioni): nuova classe `UsoSuolo` (`gioco/script/uso_suolo.gd`) sulla griglia da 10 m, con memoria del bosco, taglio con conteggio del legname, ricrescita dai margini solo con semi vicini e terreno libero, campi, costruzioni non invasive (tolte, si torna come prima) e sigillate (mai più alberi, memoria che resta). La vista toglie o rimpicciolisce gli alberi toccati senza ricalcolare la cache; il terreno mostra terra nuda, campi con i solchi, superfici sigillate. Dettagli in `docs/resa-grafica.md`, immagine `docs/immagini/uso-suolo-24-11.jpg`, verifiche `test/verifica_uso_suolo.gd` (tutte superate). Non ci sono ancora comandi nel gioco per tagliare o costruire: arriveranno con l'HUD.
- **Acqua: corrente e dislivelli** (richiesta di Fede). Il generatore della mappa calcola per ogni corso d'acqua portate (proposta di Claude: fiume 15 m³/s di media, torrenti 0,4 e 1,5), profilo del letto, pendenza, velocità (Manning) e potenza idraulica ogni 100 m, più i siti adatti alle dighe (valli che si chiudono a 10 o 20 m sopra il letto, con lunghezza della diga, area e volume dell'invaso e potenza di una centrale). Gli strati che c'erano prima non cambiano (controllato byte per byte). Nel gioco: nuova mappa tematica **Energia dell'acqua** (tasto 5) con i siti per le dighe, lettura del lotto con corrente, potenza e regime, rapide nell'acqua dove la corrente supera circa 1,5 m/s. Dettagli in `docs/mappa-pedecollinare.md` (Idraulica); immagine `docs/immagini/energia-acqua-24-11.jpg`; verifiche `test/verifica_acqua.gd`. Rimandati: cascate (servono salti nel letto) e livelli che cambiano con le piene (con la simulazione del Prototipo 0). La mappa è cambiata: al primo avvio gli alberi si ricalcolano una volta.
- **Carte delle chiome viste di taglio** (spiegate a Fede, che ha chiesto di sistemarle): nuovo shader delle foglie `gioco/shader/foglie.gdshader`, che fa svanire le carte quasi di profilo rispetto alla camera invece di mostrarle come linee o schegge. Applicato in `Asset.prepara` a tutti i materiali delle foglie. Controllato con una foto ravvicinata del bosco; verifica aggiunta a `test/verifica_alberi.gd`.
- **Texture di paglia e argilla per lo zoom ravvicinato** (Fede: procedi): paglia a corsi di steli disegnati uno per uno con le teste tagliate e l'ombra del corso sopra; argilla con stesure a mano, paglia tritata e crepe sottili; tetti conici con i corsi ad anelli concentrici invece che a zig-zag. Rigenerati con Blender casa lunga, capanna tonda e granaio. Dettagli in `docs/asset.md`, immagine `docs/immagini/paglia-argilla-24-11.jpg`.
- **Lotto del villaggio** (Fede: procedi): nuovo script `strumenti/blender/villaggio.py` con 16 modelli nello stile verosimile in `gioco/asset/villaggio/`: case lunghe piccola, media e grande, capanne tonde in due misure, granaio su pali, palizzata (tratto e varco), luogo sacro (cerchio di pali attorno a una pietra eretta: proposta di Claude), focolare, fossa-silo, recinto per gli animali in graticcio, catasta di legna, tre rocce. Foto di controllo `test/foto_villaggio.gd` (villaggio composto a mano con palizzata, terra battuta e campi dall'uso del suolo), immagine `docs/immagini/villaggio-24-11.jpg`. Lo shader del terreno ora dà bordi netti e irregolari a campi e terra battuta (prima erano aloni sfumati). Verifica degli asset estesa alla nuova cartella.

**Decisioni**
- Fede: il caricamento degli alberi va reso più rapido, ottimizzando o precaricando. Scelta di Claude: entrambe le cose, cioè calcolo ottimizzato e parallelo la prima volta, cache su disco precaricata all'avvio dalle volte successive.
- Fede: le prove sui PC (tempi degli alberi, fotogrammi al secondo) vanno in coda; il PC dedicato è pronto.
- Fede: rimandati la taratura di dettaglio e densità degli alberi e il prato da vicino in 3D.
- Fede, **disboscamento:** un'area disboscata resta in memoria come ex area boschiva. Se attorno ci sono altri alberi (è stata tagliata una parte del bosco), nel tempo nascono nuovi alberi, purché il terreno resti libero. Se il terreno viene edificato: con materiali non invasivi, tolto l'edificio e lasciato libero il terreno si torna alla condizione di prima (possono nascere nuovi alberi); con materiali invasivi (cemento, asfalto, fondamenta, fognature) l'area non accoglie più alberi, ma resta la memoria dell'origine boschiva. Gli effetti della rimozione degli alberi sono quelli naturali, come i vantaggi.
- Fede, **acqua:** inserire la meccanica della corrente (per mulini, turbine…) e i dislivelli per le dighe, oltre a rapide, cascate e livelli che cambiano con le piene.
- Fede: sistemare le carte delle chiome viste di taglio (dopo l'acqua, prima delle texture delle case).
- Fede: procedere con le texture di paglia e argilla e con il lotto del villaggio.
- Fede: **Prototipo 0 in Godot accolto**, giocabile (non solo resa grafica).
- Fede: niente recinto per ora; nelle epoche in cui è coerente **l'abitato cresce spontaneo**.
- Fede, **HUD:** disposizione come in Age of Empires, con i controlli delle mappe a destra e i comandi a sinistra. Lo stile è da definire.
- Fede: ordine di lavoro 3 (disboscamento), 4 (acqua), 5 (carte di taglio), 6 (texture), 7 (villaggio), a (HUD), 8 (Prototipo 0 in Godot).

**Prossimo passo**
- Fede, sul PC di casa: fare Pull, aprire il gioco due volte e riportare i tempi del pannello. La prima volta "alberi calcolati in … s", la seconda "alberi dalla cache in … ms". Dire anche se all'avvio ci sono scatti.
- Fede: dire i fotogrammi al secondo mostrati nel pannello a circa 150, 600, 2000 e 6000 m di vista, se ci sono scatti scorrendo la mappa, come appaiono specie, densità, canneti, acqua e passaggio tra i livelli di dettaglio.
- Fede: preparare il PC dedicato (Godot 4.7.2, Blender 5.3, GitHub Desktop: vedi `docs/setup-pc.md`); continuare a provare il Prototipo 0.
- Claude, prossime sessioni:
  - alberi sulla mappa: tarare livelli di dettaglio e densità sulle prestazioni dei PC di Fede; confermare con Fede la scelta delle specie (proposta di Claude);
  - prato da vicino: valutare ciuffi d'erba, fiori e sassi in 3D posati come gli alberi (proposta di Claude), se a zoom stretto il terreno sembra ancora piatto;
  - alberi come dati modificabili: abbattere o costruire su un'area boscata la segna come "area disboscata" (costruita: bosco perso ma ricordato; solo abbattuta: può ricrescere); il terreno sotto cambia (terra battuta, terra nuda, erba rada) con una mappa dell'uso del suolo aggiornabile durante il gioco; progettare l'interazione con il gameplay (proposte di Claude da discutere: legname, rischio di frane e piene più rapide, ricrescita per stadi da arbusti ad alberi). La cache degli alberi resta lo strato di partenza, le modifiche della partita si terranno a parte;
  - acqua: rapide e cascate sui torrenti, livelli che cambiano con le piene;
  - alberi: carte viste di taglio ai bordi delle chiome;
  - texture di paglia e argilla delle case da rivedere per lo zoom ravvicinato;
  - poi completare il lotto del villaggio nello stile scelto;
  - portare in Godot il Prototipo 0 (ciclo del villaggio: fondazione, campi, case, sentieri, granaio, stagioni) sulla mappa vera, con la simulazione separata dalla grafica e verificabile senza grafica (proposta di Claude, da confermare con Fede).
- In sospeso: recinto come primo strumento di regolazione nel Prototipo 0.

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
- Paludi: Fede ha notato la ripetizione della texture in pozze e canneti. Ora sono disegnati da un rumore unico per la mappa (`rumore_palude`, circa 30 m) insieme a `rumore_bosco`: nessun motivo ripetuto. Immagine: `docs/immagini/paludi-senza-ripetizioni-23-11.jpg`.
- **Alberi veri sulla mappa** (richiesta di Fede, sera): immagine `docs/immagini/alberi-in-mappa-23-11.jpg`.
  - Modelli: 9 varianti (3 querce, 2 carpini, 2 pioppi, 2 arbusti) in versione completa e leggera, da `strumenti/blender/alberi_mappa.py`.
  - Dati: `script/alberi.gd`, circa 600 000 alberi calcolati per blocchi di 320 m dal nuovo campo `bosco_fine` (10 m) generato con la mappa; lo stesso campo disegna il bordo del bosco nello shader, quindi alberi e volta dipinta coincidono. Specie secondo il luogo e alberi sparsi fuori dal bosco (proposte di Claude, da confermare).
  - Vista: `script/vista_alberi.gd`, MultiMesh per blocco; alberi completi sotto 220 m di vista, leggeri fino a 700 m, oltre la volta dipinta, ritarata sul colore medio degli alberi. Sottobosco dipinto sotto gli alberi. Il pannello mostra fotogrammi al secondo e alberi disegnati.
  - Corretto anche: sulle colline la volta dipinta prendeva la tinta gialla della quota.
  - Verifiche senza grafica superate (base, asset, alberi: niente alberi nell'acqua, posa deterministica, livelli di dettaglio). Le prestazioni vere vanno provate sui PC di Fede.
- **Parere di Fede sugli alberi:** "molto carini", ma la volta dipinta stona totalmente con gli alberi e ce n'erano in mezzo alla palude. Fatto:
  - nuovo livello **sagome** tra 700 e 2600 m di vista: un'immagine per modello fotografata in Godot con camera e sole del gioco, disegnata su un rettangolo rivolto allo schermo; la volta dipinta resta solo oltre i 2600 m ed è ritarata sul colore delle sagome;
  - niente alberi nelle paludi;
  - calcolo degli alberi e dei buffer su altri thread, così la mappa si riempie senza scatti;
  - corretto il calcolo dei blocchi inquadrati: sui rilievi scartava blocchi visibili (forse il motivo per cui Fede non vedeva alberi);
  - confini sfrangiati tra boschi di specie diverse.
  Immagine: `docs/immagini/sagome-alberi-23-11.jpg`. Verifiche senza grafica superate.
- **Rifinitura chiesta da Fede** ("le pennellate stonano col dettaglio degli alberi; palude e acqua stonano"; la scelta tra alberi a vista e pennellate lasciata a Claude):
  - **decisione di Claude:** alberi visibili a ogni zoom; oltre 2,6 km sagome rade (un albero su due o tre, ingrandito, in blocchi da 1280 m, senza ombre); la volta dipinta resta solo come fondo;
  - **paludi** come dati della mappa (`palude_fine`, `pozze_fine` a 10 m) e **canneti in 3D** (circa 330 000 ciuffi) attorno alle pozze e lungo le rive basse;
  - **acqua** rifatta: colore di fiume di pianura, riflessi del cielo e della riva, corrente, scie, scintillii;
  - corretto un difetto che poteva tenere in coda per secondi i blocchi di alberi della vista (il calcolo in sottofondo occupava l'unico posto a bassa priorità): ora i blocchi della vista hanno la precedenza;
  - le versioni semplificate generate da Godot all'importazione facevano sparire le canne: disattivate per i modelli degli alberi.
  Immagine: `docs/immagini/paludi-canneti-acqua-23-11.jpg`. Verifiche senza grafica superate.
  - **prato:** meno "pennellate": variazione larga più tenue, chiazze secche color paglia e frastagliate, ciuffi da 3 a 30 m visibili da vicino. Immagine: `docs/immagini/prato-rifinito-23-11.jpg`.
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
- Superato dalla voce del 24/11/2026, che contiene la lista aggiornata.
