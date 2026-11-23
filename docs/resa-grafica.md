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
- Da fare: corrente nel verso del fiume, cascate e rapide sui torrenti, paludi con acqua bassa e canne, livelli che cambiano con le piene.

## Paludi e gessi
Non stanno più nei colori dei vertici, che facevano quadretti da 40 m (segnalato da Fede).
- **Paludi (rifinite il 23/11 sera, dopo il parere di Fede: "stonano col dettaglio degli alberi"):** sono dati della mappa, come il bosco: `palude_fine` e `pozze_fine` a 10 m, generati in Python con un rumore senza periodo (campo casuale filtrato a 20–120 m). Lo shader dipinge erba umida, una fascia di canne secche, fango attorno alle pozze e le pozze d'acqua ferma, scura, con veli di lenticchie d'acqua. **Canneti in 3D** (`canna_1`, `canna_2`, completi e leggeri, più le sagome) posati da `Alberi` con gli stessi campi: fitti nella fascia attorno alle pozze, qualche ciuffo nell'acqua bassa del bordo, radi nel resto della palude, a tratti lungo le rive basse dei fiumi in pianura. Circa 330 000 ciuffi. Niente alberi nelle paludi.
- **Gessi:** texture `zone_speciali` (verde), letta in otto punti e frastagliata come i boschi.
- **Gessi:** roccia chiara grigio-calda che affiora a chiazze tra l'erba rada; da lontano le chiazze si fondono in un tono unico.
- Da fare: canne vere (oggetti) ai margini delle pozze, livelli che cambiano con le stagioni e le piene.

## Mappe tematiche
I dati tematici non hanno più gradini: le fasce di fertilità e di rischio di piena passano gradualmente da una all'altra (circa 160 m) e la vicinanza all'acqua si misura in linea d'aria, non più a scacchiera (attorno alle sorgenti venivano quadrati). Lo shader le legge ammorbidite. Codice: `strumenti/mappe/genera_pedecollinare.py`.

## Luce e ombre
Codice: `gioco/script/principale.gd` (sole e ambiente), `gioco/script/camera_isometrica.gd` (distanza e piani di taglio).
- **Sole da sinistra, ombre lunghe verso destra** sullo schermo (decisione di Fede). Il sole gira con la camera, quindi vale a ogni rotazione. Altezza 42°: costanti `ALTEZZA_SOLE` e `AZIMUT_SOLE`.
- La camera sta appena fuori dalla fetta di terreno visibile e la mappa d'ombra copre solo quella: ombre nitide anche a 35 m. Con la camera lontana le ombre sparivano.
- Sole caldo, luce del cielo un po' fredda: ombre leggibili e non nere.

## Alberi
Modelli: `strumenti/blender/prova_stile_verosimile.py` (funzione `albero`) e `strumenti/blender/alberi_mappa.py` (varianti per la mappa). Regole e catalogo: `docs/asset.md`.

**Alberi veri sulla mappa (23/11/2026, richiesta di Fede):**
- **Dati** (`gioco/script/alberi.gd`, classe `Alberi`): gli alberi si calcolano per blocchi di 320 m, in modo deterministico, dal campo `bosco_fine` della mappa (lo stesso che usa lo shader, così bordo dipinto e alberi coincidono). Nel bosco un albero ogni 7 m circa, su una griglia mossa a caso, con radure e più arbusti al margine; fuori dal bosco filari lungo l'acqua, arbusti ai margini, querce isolate, pochi arbusti sui gessi. Niente alberi a meno di 4 m dalla riva e nelle paludi (richiesta di Fede). I confini tra le fasce della mappa si leggono in un punto spostato a caso fino a 80 m, così i boschi di pioppi non hanno bordi dritti. Il calcolo gira in sottofondo su un altro thread, dal punto di partenza verso l'esterno. Sulla mappa pedecollinare sono circa 600 000.
- **Specie secondo il luogo (proposta di Claude, da confermare):** querce e carpini in pianura (querco-carpineto); querce e carpini sulle colline; pioppi dove è umido (vicino all'acqua, bassa pianura), qualche pioppo lungo i torrenti delle colline; arbusti al margine. L'acero autunnale è escluso finché le stagioni non sono decise.
- **Vista** (`gioco/script/vista_alberi.gd`, classe `VistaAlberi`): `MultiMesh` per blocco, solo nei blocchi inquadrati (il centro di ogni blocco si proietta sullo schermo alla sua quota, altrimenti sui rilievi mancavano blocchi ai bordi). I buffer si preparano su altri thread; il thread principale crea solo le MultiMesh, entro 6 ms per fotogramma. Un blocco di un altro livello resta visibile finché non è pronto quello nuovo. Livelli secondo lo zoom:
  - vista più stretta di 220 m: alberi completi (360–530 facce);
  - fino a 700 m: versione leggera (55–80 facce, poche carte grandi, senza rami);
  - fino a 2600 m: **sagome** (dopo il parere di Fede: la volta dipinta stonava con gli alberi). Ogni albero è un rettangolo sempre parallelo allo schermo con l'immagine del suo modello, fotografata in Godot con la stessa camera e lo stesso sole da sinistra del gioco (`strumenti/genera_sagome.gd` → `asset/alberi/sagome.png` e `sagome_dati.gd`; shader `shader/sagome_alberi.gdshader`). La luce è già nell'immagine; metà delle sagome è specchiata;
  - oltre: **sagome rade** (gli alberi si vedono a ogni zoom: decisione di Claude, su mandato di Fede, perché la volta dipinta da sola stonava con gli alberi): un albero su due o tre (niente arbusti), ingrandito di 1,45 volte, in blocchi di 1280 m, senza ombre. Sotto resta la volta dipinta come fondo.
  Le soglie (`DIM_COMPLETI`, `DIM_LEGGERI`, `DIM_SAGOME`) vanno tarate con le prove sui PC di Fede.
- **Sottobosco:** con alberi completi o leggeri lo shader dipinge sotto il bosco terra con foglie secche ed erba rada (parametro `sottobosco`); con le sagome resta sotto la volta dipinta, così tra una sagoma e l'altra e nei blocchi non ancora pronti si vede bosco. La volta dipinta ha il colore medio degli alberi veri e delle sagome, misurato sulle foto: al cambio di zoom il bosco non cambia colore.
- **Prestazioni:** il pannello mostra fotogrammi al secondo, alberi disegnati e livello. Calcolare un blocco pieno di bosco costa circa 9 ms (una volta sola, poi resta in memoria).
- Chiome a lobi fatte di carte di foglie singole; normali sferiche per la luce sul volume; ombra interna calcolata.
- Specie definite da pochi parametri (tabella `SPECIE`): quercia, carpino, pioppo, acero, arbusto. Una mappa con altro clima avrà altre specie con lo stesso generatore.
- Da fare: aree disboscate modificabili durante il gioco (tolgono gli alberi e cambiano il suolo) e ricrescita per stadi; altre specie (salici, ontani) per i luoghi umidi; tarare i livelli di dettaglio sulle prestazioni dei PC di Fede.
- **Gli alberi sono dati di gioco (decisione di Fede, 23/11/2026).** Ogni albero o bosco sta nei dati, così si può abbattere, far ricrescere, ricordare. Un'area disboscata resta segnata come tale e il suo destino dipende da cosa la sostituisce: se è costruita il bosco è perso ma ne resta memoria; se è solo abbattuta può ricrescere. La cosa più importante è l'interazione con il gameplay. Il terreno sotto segue l'uso del suolo (sentiero, terra nuda, erba rada), con una mappa aggiornabile durante il gioco.

## Asset
Regole, stile e catalogo: `docs/asset.md`. Ogni asset nasce da uno script, così si può rigenerare quando cambiano lo stile o le regole.

## Come controllare
- `test/foto.gd`: territorio attorno al sito iniziale, a qualsiasi zoom.
- `test/foto_asset.gd`: asset posati vicino al sito iniziale.
- `test/foto_luogo.gd`: margine di bosco o riva del fiume più vicini al sito (`-- dimensione bosco|acqua`).
- Le righe di comando complete sono in `CLAUDE.md`.
