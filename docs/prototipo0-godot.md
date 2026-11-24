# Prototipo 0 in Godot

*Il villaggio (prima epoca) giocabile sulla mappa vera. Proposta di Claude accolta da Fede il 24/11/2026: il prototipo è giocabile, non solo resa grafica. Immagine: `docs/immagini/prototipo0-godot-24-11.jpg`.*

## Com'è fatto
- **Simulazione** (`gioco/script/sim_villaggio.gd`, classe `SimVillaggio`): le regole del Prototipo 0 web (`prototipi/prototipo0/index.html`), separate dalla grafica e verificabili senza schermo (`test/verifica_villaggio.gd`). Non sa nulla di modelli o shader: tiene lo stato (centro, case, campi, sentieri, granaio, rovine, indicatori, cronaca) e le **decisioni in attesa**, che fermano il tempo.
- **Disegno** (`gioco/script/vista_villaggio.gd`, classe `VistaVillaggio`): confronta lo stato con ciò che ha già disegnato e aggiorna solo le differenze. Case e granaio con i modelli del lotto del villaggio (tipi misti: case lunghe di tre misure e capanne tonde, scelti e ruotati in modo fisso per lotto); campi e sentieri attraverso l'**uso del suolo** (campi = suolo coltivato, che toglie gli alberi; sentieri e cortili = terra battuta); rovine con qualche sasso.
- **Partita** (`gioco/script/partita.gd`, classe `Partita`): collega simulazione, disegno, uso del suolo e HUD; tempo continuo con pausa e tre velocità (2, 6, 15 anni al secondo); ogni anno della simulazione fa passare anche un anno all'uso del suolo, quindi un campo abbandonato su un ex bosco ricresce mentre si gioca.

## Scale (dal prototipo web alla mappa vera)
Il prototipo ragionava a celle da 160 m. Qui:
- **campi** sulla griglia della mappa, a pixel da 40 m (0,16 ha): 16 pixel valgono una cella, quindi un pixel rende 1/16 di una cella e le braccia lavorano 16 pixel dove prima lavoravano una cella;
- **case** sui lotti da 20 m, una ogni 8 abitanti, distanziate di almeno un lotto;
- **raggi**: i campi arrivano a 800 m dal centro (5 celle), un sentiero li porta 320 m più in là; il granaio va entro 320 m dal centro;
- i numeri dell'economia (cibo, braccia, consumo, salute, legittimità, eventi, presagi) sono quelli del prototipo.

## Regole (come nel prototipo, con le decisioni di Fede)
- **Fondare:** si clicca dove fondare; la finestra mostra la valutazione del sito (acqua, fertilità attorno, rischio di piena, difesa, aria). Il cerchio dello strumento mostra fin dove arriveranno i campi.
- **Abitato spontaneo** (decisione di Fede del 24/11: niente recinto per ora): le case nascono da sole vicino al centro e all'acqua, lontano dalle zone di piena finché la memoria del rischio è viva, mai su campi o sentieri. Il giocatore orienta la crescita con campi, sentieri e granaio.
- **Campi:** un clic dissoda la terra libera dentro il cerchio; un clic su un campo abbandona i campi nel cerchio.
- **Sentiero:** un clic prolunga la rete in linea retta dal punto più vicino (centro o sentiero); non attraversa il fiume né la palude.
- **Granaio:** 30 di cibo, vicino al centro; le scorte si conservano meglio.
- **Usanza sul raccolto:** in comune (più legittimità) o per famiglia (più raccolto).
- **Demolisci** (X, decisione di Fede): toglie nel cerchio alberi (legname), case, campi, sentieri e granaio; il focolare al centro resta. Sul lotto di una casa demolita non rinasce una casa per 20 anni (macerie). Fiumi e paludi non si demoliscono.
- **Eventi e presagi:** piene dal rischio della mappa, siccità con presagio vero (le sorgenti calano), cometa come presagio falso, primo cattivo raccolto, affollamento (allargarsi o villaggio figlio), crisi di legittimità, abbandono (le rovine restano e si può rifondare), fine dopo 500 anni con il riepilogo.

## Verifiche
- `test/verifica_villaggio.gd`: valutazione dei siti, azioni, una partita di 500 anni per ogni sito con un giocatore automatico, nessuna casa sull'acqua, simulazione deterministica con lo stesso seme.
- `test/verifica_partita.gd`: la partita nella scena principale (fondare dal comando, campi, tempo, scelte, indicatori).
- Foto: `test/foto_partita.gd`.

## Note di bilanciamento
Con il giocatore automatico tutti e sei i siti reggono 500 anni; le popolazioni finali superano spesso il migliaio, come già nel prototipo web: alte per un villaggio neolitico, da ricalibrare dopo le prove di Fede. Il dosso nelle paludi resta piccolo (poche case trovano posto), l'area dei gessi soffre più carestie.

## Da fare
- Prove di Fede e taratura.
- Campi meno regolari (oggi sono quadrati da 40 m, ognuno con il suo verso dei solchi e il suo tono).
- Livelli dell'acqua che salgono con le piene, nella grafica.
- Salvataggio della partita (con l'uso del suolo).
