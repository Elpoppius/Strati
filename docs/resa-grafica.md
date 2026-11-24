# Resa grafica

*I sistemi che danno l'aspetto al gioco. Valgono per tutte le mappe.*

**Decisione di Fede (23/11/2026):** il lavoro su alberi, terreni, ombre, asset e acqua non riguarda una mappa sola. Ogni sistema deve funzionare con qualsiasi mappa a partire dai suoi dati, senza ritocchi a mano per la singola mappa.

## Cosa deve fornire una mappa
Ogni mappa è una risorsa `MappaDati` (`gioco/script/mappa_dati.gd`), generata da uno script in `strumenti/mappe/` e convertita con `strumenti/importa_mappa.gd`. I sistemi qui sotto leggono questi strati:

| Strato | Risoluzione | Usato da |
|---|---|---|
| quote | griglia della mappa (oggi 256 × 256, 40 m) | forma del terreno, tinte per quota, pendii ripidi |
| tipo (terra, fiume, torrente, palude, gessi) | griglia | colori delle zone speciali |
| zona | griglia | tinta del suolo |
| fertilità, acqua affidabile, acqua stagionale | griglia | mappe tematiche; distribuzione di verde e secco nel prato |
| copertura (bosco) | griglia | base per il campo fine del bosco |
| bosco fine | 4 volte la griglia (10 m) | margine del bosco dipinto, sottobosco, posa degli alberi (0,5 = margine) |
| palude fine, pozze fine | 10 m | paludi: erba umida, fango, pozze d'acqua ferma; posa dei canneti |
| distanza dall'acqua | 4 volte la griglia (oggi 1024 × 1024, 2 m per unità) | fiumi, torrenti, rive |
| velocità della corrente, potenza idraulica | griglia | rapide e schiuma, mappa tematica dell'energia dell'acqua, lettura del lotto |
| corsi d'acqua, siti per le dighe | elenco in `meta.json` | portate e regime, siti per le dighe nella mappa dell'energia |

Una mappa nuova eredita tutto il resto: basta che fornisca questi strati.

## Terreno e prato
Codice: `gioco/shader/terreno.gdshader`, `gioco/script/terreno.gd`.
- **Erba:** texture a fili sottili (`erba.png`), letta due volte con orientamenti diversi per spezzarne la ripetizione; variazione minuta di tono da vicino.
- **Verde, ingiallito, secco:** distribuiti da due rumori unici per tutta la mappa, generati all'avvio con `FastNoiseLite`, e dai dati del luogo: più secco lontano dall'acqua e sui terreni poco fertili. Nessuna ripetizione a nessuno zoom; i dati a celle sono ammorbiditi, così i bordi non fanno scalini. Richiesta di Fede: niente texture ripetute nelle parti aride; la priorità è la resa del prato.
- **Meno pennellate (23/11 sera, parere di Fede):** la variazione larga di verde è più tenue; le chiazze secche hanno bordi spezzati a più scale (30 m senza ripetizioni, 13 e 5 m) e sono color paglia, con ciuffi verdi che restano dentro; da vicino il prato ha ciuffi più scuri e più chiari da 3 a 30 m.
- **Pendii ripidi:** l'erba si dirada e affiora la terra.
- **Rilievo (decisione di Fede, 23/11/2026):** niente isoipse nella vista normale; il rilievo si legge da luce e ombre. Lo shader schiarisce i pendii rivolti al sole e scurisce quelli in ombra, in proporzione alla luce di un terreno piano (`forza_rilievo`; la direzione del sole arriva da `principale.gd` in `verso_sole`). Le isoipse ogni 25 m si accendono con il tasto **I** o con la casella nel pannello.
- **Niente puntinato da lontano:** tutte le texture in `asset/texture/` sono importate con le mipmap (versioni ridotte per la distanza); senza, da lontano l'erba e le foglie si riducevano a puntini. Lo shader calcola anche quanti metri copre un pixel (`mpx`) e da lontano attenua i dettagli minuti.
- **Boschi:** bordi irregolari e una volta di chiome dipinta, dalla copertura. Il margine legge la copertura in otto punti attorno e la muove con rumori a più scale, così non segue i gradini da 40 m. Da lontano le foglie si fondono in un tono medio con gruppi di alberi più chiari e più scuri presi da un rumore unico per la mappa (`rumore_bosco`): una texture ripetuta formava una trama regolare. È un segnaposto: **andranno posati alberi veri** (decisione di Fede).
- **Texture:** generate da `strumenti/blender/texture_procedurali.py`.

## Acqua
Codice: in fondo a `gioco/shader/terreno.gdshader`. Dati: la distanza dalla riva, che `terreno.gd` converte in virgola mobile (in 8 bit faceva fasce a gradini).
- **Rifinita il 23/11 sera** (parere di Fede: l'acqua stonava con gli alberi): colore di fiume di pianura, torbido verde-grigio, più scuro dove è fondo, fondale bruno vicino alla riva (prima era un azzurro saturo); riflesso del cielo più chiaro dove l'acqua è liscia; la riva lontana dalla camera, con i suoi alberi, si specchia scura nei metri d'acqua vicino a lei; increspature allungate che scorrono nel verso della corrente e scie chiare sottili; qualche scintillio del sole sulle creste. Nelle pozze l'acqua è ferma.
- Profondità che sfuma dalla riva al centro.
- Increspature che scorrono nel tempo: tre strati a scale e orientamenti diversi, su coordinate deformate da un rumore più ampio, più un'ondulazione lenta unica per tutta la mappa. Così non si vede un motivo ripetuto (segnalato da Fede); riflessi del cielo sulle creste e un poco di luce propria, così l'acqua non diventa scura in ombra.
- Superficie liscia e riflettente (il terreno no).
- Schiuma sottile lungo la riva, sponda bagnata più scura e un velo di limo.
- **L'acqua segue i rilievi:** prende la stessa ombreggiatura del versante su cui scorre (richiesta di Fede), così un fiume in una valle non sembra incollato sopra.
- **Sponde in rilievo** (dopo la prova di Fede, "acqua piatta"): dal campo di distanza lo shader ricava il verso della riva e inclina la normale del terreno negli ultimi metri, così la luce modella l'argine; dalla parte del sole l'argine fa ombra sull'acqua. Tre toni di profondità (bassa, media, fonda), fondale chiaro che traspare dove l'acqua è bassa, chiazze larghe di vento e cielo riflesso visibili anche da lontano.
- **Corrente vera (24/11/2026, richiesta di Fede: la corrente come meccanica per mulini, turbine e dighe):** l'acqua scorre alla velocità calcolata per quel tratto (dati `velocita`) e sopra circa 1,5 m/s si rompe in **rapide**, chiazze d'acqua bianca che scorrono. Il calcolo idraulico è descritto in `docs/mappa-pedecollinare.md` (sezione Idraulica).
- Da fare: cascate (servono salti nel letto dei torrenti, che la mappa oggi non ha); livelli che cambiano con le stagioni e le piene, insieme alla simulazione delle piene nel Prototipo 0 in Godot.

## Paludi e gessi
Non stanno più nei colori dei vertici, che facevano quadretti da 40 m (segnalato da Fede).
- **Paludi (rifinite il 23/11 sera, dopo il parere di Fede: "stonano col dettaglio degli alberi"):** sono dati della mappa, come il bosco: `palude_fine` e `pozze_fine` a 10 m, generati in Python con un rumore senza periodo (campo casuale filtrato a 20–120 m). Lo shader dipinge erba umida, una fascia di canne secche, fango attorno alle pozze e le pozze d'acqua ferma, scura, con veli di lenticchie d'acqua. **Canneti in 3D** (`canna_1`, `canna_2`, completi e leggeri, più le sagome) posati da `Alberi` con gli stessi campi: fitti nella fascia attorno alle pozze, qualche ciuffo nell'acqua bassa del bordo, radi nel resto della palude, a tratti lungo le rive basse dei fiumi in pianura. Circa 330 000 ciuffi. Niente alberi nelle paludi.
- **Gessi:** texture `zone_speciali` (verde), letta in otto punti e frastagliata come i boschi.
- **Gessi:** roccia chiara grigio-calda che affiora a chiazze tra l'erba rada; da lontano le chiazze si fondono in un tono unico.
- Da fare: canne vere (oggetti) ai margini delle pozze, livelli che cambiano con le stagioni e le piene.

## Mappe tematiche
I dati tematici non hanno più gradini: le fasce di fertilità e di rischio di piena passano gradualmente da una all'altra (circa 160 m) e la vicinanza all'acqua si misura in linea d'aria, non più a scacchiera (attorno alle sorgenti venivano quadrati). Lo shader le legge ammorbidite. Codice: `strumenti/mappe/genera_pedecollinare.py`.

**Energia dell'acqua (24/11/2026, tasto 5):** potenza idraulica media lungo fiumi e torrenti, dal blu (poca) al giallo e al rosso (molta), in una fascia che segue la riva; il resto della mappa si schiarisce. Compaiono le etichette dei siti adatti alle dighe (altezza, lunghezza della diga, invaso, potenza media). Immagine: `docs/immagini/energia-acqua-24-11.jpg`. La lettura del lotto sull'acqua dice corrente, potenza ogni 100 m e regime del corso.

## Luce e ombre
Codice: `gioco/script/principale.gd` (sole e ambiente), `gioco/script/camera_isometrica.gd` (distanza e piani di taglio).
- **Sole da sinistra, ombre lunghe verso destra** sullo schermo (decisione di Fede). Il sole gira con la camera, quindi vale a ogni rotazione. Altezza 42°: costanti `ALTEZZA_SOLE` e `AZIMUT_SOLE`.
- La camera sta appena fuori dalla fetta di terreno visibile e la mappa d'ombra copre solo quella: ombre nitide anche a 35 m. Con la camera lontana le ombre sparivano.
- Sole caldo, luce del cielo un po' fredda: ombre leggibili e non nere.

## Alberi
Modelli: `strumenti/blender/prova_stile_verosimile.py` (funzione `albero`) e `strumenti/blender/alberi_mappa.py` (varianti per la mappa). Regole e catalogo: `docs/asset.md`.

**Alberi veri sulla mappa (23/11/2026, richiesta di Fede):**
- **Dati** (`gioco/script/alberi.gd`, classe `Alberi`): gli alberi si calcolano per blocchi di 320 m, in modo deterministico, dal campo `bosco_fine` della mappa (lo stesso che usa lo shader, così bordo dipinto e alberi coincidono). Nel bosco un albero ogni 7 m circa, su una griglia mossa a caso, con radure e più arbusti al margine; fuori dal bosco filari lungo l'acqua, arbusti ai margini, querce isolate, pochi arbusti sui gessi. Niente alberi a meno di 4 m dalla riva e nelle paludi (richiesta di Fede). I confini tra le fasce della mappa si leggono in un punto spostato a caso fino a 80 m, così i boschi di pioppi non hanno bordi dritti. Il calcolo gira in sottofondo su tutti i processori meno uno (che resta libero per i blocchi chiesti dalla vista), dal punto di partenza verso l'esterno; ogni compito lavora su una copia propria dei dati della mappa, perché i thread che leggono gli stessi array si rallentano a vicenda. Sulla mappa pedecollinare sono circa 930 000 piante (600 000 alberi e arbusti, 330 000 ciuffi di canne).
- **Specie secondo il luogo (proposta di Claude, da confermare):** querce e carpini in pianura (querco-carpineto); querce e carpini sulle colline; pioppi dove è umido (vicino all'acqua, bassa pianura), qualche pioppo lungo i torrenti delle colline; arbusti al margine. L'acero autunnale è escluso finché le stagioni non sono decise.
- **Vista** (`gioco/script/vista_alberi.gd`, classe `VistaAlberi`): `MultiMesh` per blocco, solo nei blocchi inquadrati (il centro di ogni blocco si proietta sullo schermo alla sua quota, altrimenti sui rilievi mancavano blocchi ai bordi). I buffer si preparano su altri thread; il thread principale crea solo le MultiMesh, entro 6 ms per fotogramma. Un blocco di un altro livello resta visibile finché non è pronto quello nuovo. Livelli secondo lo zoom:
  - vista più stretta di 220 m: alberi completi (360–530 facce);
  - fino a 700 m: versione leggera (55–80 facce, poche carte grandi, senza rami);
  - fino a 2600 m: **sagome** (dopo il parere di Fede: la volta dipinta stonava con gli alberi). Ogni albero è un rettangolo sempre parallelo allo schermo con l'immagine del suo modello, fotografata in Godot con la stessa camera e lo stesso sole da sinistra del gioco (`strumenti/genera_sagome.gd` → `asset/alberi/sagome.png` e `sagome_dati.gd`; shader `shader/sagome_alberi.gdshader`). La luce è già nell'immagine; metà delle sagome è specchiata;
  - oltre: **sagome rade** (gli alberi si vedono a ogni zoom: decisione di Claude, su mandato di Fede, perché la volta dipinta da sola stonava con gli alberi): un albero su due o tre (niente arbusti), ingrandito di 1,45 volte, in blocchi di 1280 m, senza ombre. Sotto resta la volta dipinta come fondo.
  Le soglie (`DIM_COMPLETI`, `DIM_LEGGERI`, `DIM_SAGOME`) vanno tarate con le prove sui PC di Fede.
- **Sottobosco:** con alberi completi o leggeri lo shader dipinge sotto il bosco terra con foglie secche ed erba rada (parametro `sottobosco`); con le sagome resta sotto la volta dipinta, così tra una sagoma e l'altra e nei blocchi non ancora pronti si vede bosco. La volta dipinta ha il colore medio degli alberi veri e delle sagome, misurato sulle foto: al cambio di zoom il bosco non cambia colore.
- **Prestazioni:** il pannello mostra fotogrammi al secondo, alberi disegnati, livello e da dove vengono gli alberi (cache o calcolo, con il tempo impiegato).
  - **Calcolo più veloce (24/11/2026):** prima di provare i singoli candidati, il calcolo controlla riquadri di 8 × 8 candidati sui valori grezzi dei campi e salta quelli dove di sicuro non cresce nulla (niente bosco; né palude né riva bassa per le canne). Il risultato è identico albero per albero (impronta dei dati controllata con `test/misura_alberi.gd`); il calcolo su un processore è circa due volte più veloce.
  - **Cache su disco (24/11/2026):** dopo il primo calcolo gli alberi di tutta la mappa si salvano compressi in `user://cache/alberi_<mappa>.bin` (circa 20 MB, nella cartella dei dati dell'utente, non nel repository). Dagli avvii successivi si caricano in circa 0,1 s. La cache si scarta da sola se cambiano la mappa o `alberi.gd` (impronta nell'intestazione) o se cinque blocchi di controllo ricalcolati non coincidono. Verifiche: `test/verifica_cache_alberi.gd`.
  - Quando gli alberi diventeranno modificabili (disboscamento), la cache resterà lo strato di partenza e le modifiche della partita si terranno a parte.
- Chiome a lobi fatte di carte di foglie singole; normali sferiche per la luce sul volume; ombra interna calcolata.
- Specie definite da pochi parametri (tabella `SPECIE`): quercia, carpino, pioppo, acero, arbusto. Una mappa con altro clima avrà altre specie con lo stesso generatore.
- Da fare: aree disboscate modificabili durante il gioco (tolgono gli alberi e cambiano il suolo) e ricrescita per stadi; altre specie (salici, ontani) per i luoghi umidi; tarare i livelli di dettaglio sulle prestazioni dei PC di Fede.
- **Gli alberi sono dati di gioco (decisione di Fede, 23/11/2026).** Ogni albero o bosco sta nei dati, così si può abbattere, far ricrescere, ricordare. Un'area disboscata resta segnata come tale e il suo destino dipende da cosa la sostituisce: se è costruita il bosco è perso ma ne resta memoria; se è solo abbattuta può ricrescere. La cosa più importante è l'interazione con il gameplay. Il terreno sotto segue l'uso del suolo (sentiero, terra nuda, erba rada), con una mappa aggiornabile durante il gioco.
- **Uso del suolo e disboscamento (regole di Fede, 24/11/2026; fatto il 24/11):** `gioco/script/uso_suolo.gd`, classe `UsoSuolo`, sulla griglia fine da 10 m (la stessa di `bosco_fine`). Ogni cella ha uno stato (naturale, libero, coltivato, costruito con materiali non invasivi, sigillato con materiali invasivi), gli anni da quando è libera e un bit di **memoria del bosco**, che non si perde mai.
  - **Taglio:** un'area disboscata resta in memoria come ex area boschiva. `abbatti()` restituisce quanti alberi sono stati tagliati (il legname).
  - **Ricrescita:** solo se il terreno resta libero e se entro 60 m ci sono alberi che portano semi (bosco in piedi, o un'area in ricrescita da almeno 15 anni): il bosco si richiude dai margini verso l'interno; un'area senza alberi attorno non ricresce. Tempi (proposta di Claude, da tarare): terra nuda che torna prato in circa 6 anni, arbusti da 2–3 anni, alberi giovani da circa 8, bosco maturo dopo 60 (la cella torna naturale, con la memoria del taglio). Ogni pianta riparte con un ritardo suo, così non spuntano tutte insieme.
  - **Costruzioni non invasive** (capanna d'argilla, legno): finché ci sono, niente alberi; tolte (`libera()`), si torna alla condizione di prima e il bosco può ricrescere. **Campi:** come le costruzioni non invasive, liberi dagli alberi finché coltivati.
  - **Costruzioni invasive** (cemento, asfalto, fondamenta, fognature): l'area non accoglie più alberi, nemmeno liberandola, ma la memoria del bosco resta.
  - **Effetti:** quelli naturali, come i vantaggi (legname, terreno libero). Entreranno nella simulazione con il gioco (proposte di Claude da discutere: erosione e frane sui pendii, piene più rapide, meno selvaggina).
  - **Disegno:** la vista toglie o rimpicciolisce gli alberi dei blocchi toccati (filtro sui dati in cache, che restano lo strato di partenza) e li ridisegna senza buchi; lo shader del terreno legge una texture dell'uso del suolo (bosco presente, terra nuda o battuta, campo con i solchi, superficie sigillata). Immagine: `docs/immagini/uso-suolo-24-11.jpg` (taglio, campo, capanna, superficie sigillata, area in ricrescita da 25 anni). Verifiche: `test/verifica_uso_suolo.gd`; foto: `test/foto_uso_suolo.gd`.
  - Da fare: salvare l'uso del suolo con la partita; una mappa tematica della memoria del suolo; comandi nel gioco per tagliare e costruire (con l'HUD).

## Asset
Regole, stile e catalogo: `docs/asset.md`. Ogni asset nasce da uno script, così si può rigenerare quando cambiano lo stile o le regole.

## Come controllare
- `test/foto.gd`: territorio attorno al sito iniziale, a qualsiasi zoom.
- `test/foto_asset.gd`: asset posati vicino al sito iniziale.
- `test/foto_luogo.gd`: margine di bosco o riva del fiume più vicini al sito (`-- dimensione bosco|acqua`).
- Le righe di comando complete sono in `CLAUDE.md`.
