# Prototipo 0 in Godot

*Il villaggio (prima epoca) giocabile sulla mappa vera. Proposta di Claude accolta da Fede il 24/11/2026: il prototipo è giocabile, non solo resa grafica. Immagine: `docs/immagini/prototipo0-godot-24-11.jpg`.*

## Com'è fatto
- **Simulazione** (`gioco/script/sim_villaggio.gd`, classe `SimVillaggio`): le regole del Prototipo 0 web (`prototipi/prototipo0/index.html`), separate dalla grafica e verificabili senza schermo (`test/verifica_villaggio.gd`). Non sa nulla di modelli o shader: tiene lo stato (centro, case, campi, sentieri, granaio, rovine, indicatori, cronaca) e le **decisioni in attesa**, che fermano il tempo.
- **Campi** (24/11/2026, dopo i pareri di Fede): dove non c'è un campo il terreno è normale; dove il giocatore pone un campo, il campo occupa esattamente le celle da 40 m prese con la griglia magnetica, con il contorno appena sfrangiato e senza bordi tra una cella e l'altra. Scartate la scacchiera (ogni cella con tono e bordi propri), le parcelle irregolari a toni casuali (macchie di leopardo) e le strisce lunghe e dritte (Fede: sembravano fatte da un aratro meccanico, che nel 6000 a.C. non c'era).
- **Il campo cambia con l'epoca** (decisione di Fede del 24/11/2026): ogni campo ricorda la tecnica con cui è stato fatto (`SimVillaggio.TECNICHE`: zappa, aratro in croce, centuriazione, strisce medievali, meccanica). Al cambio d'epoca i campi vecchi restano com'erano; quelli nuovi nascono con la tecnica dell'epoca e rendono più cibo (progresso tecnico; rese `RESA_TECNICA` 1; 1,3; 1,55; 1,8; 3: proposta di Claude, da tarare). Nel villaggio c'è solo la zappa: **orti lavorati a mano** in **appezzamenti di famiglia** di 20–40 m, con file corte e ondulate lungo le curve di livello, zolle, ciuffi di farro e orzo, qualche ceppo e sasso, chiazze bruciate (il bosco si apriva col fuoco), bordi d'erbacce appena visibili e toni vicini tra un appezzamento e l'altro. Le strisce di prima restano per le tecniche successive finché non si disegneranno le loro (immagini `docs/immagini/campi-zappa-24-11.jpg`, `docs/immagini/campi-ammodernamento-24-11.jpg`).
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
- **Campi:** un clic dissoda la terra libera dentro il cerchio; i campi che ci sono già restano (prima un clic su un campo abbandonava tutti i campi nel cerchio: Fede l'ha segnalato come un errore). Per abbandonare un campo si usa Demolisci. Mentre lo strumento è attivo, dentro il cerchio si vedono i quadrati da 40 m della simulazione.
- **Sentiero** (come in Cities: Skylines, decisione di Fede): un clic dove comincia, un clic dove finisce, poi si continua da lì; Esc chiude la catena. L'inizio è libero, così si possono fare reti complesse; con **Collega alla rete** acceso ogni sentiero parte invece dal punto più vicino del villaggio o dei sentieri. Inizio e fine si agganciano ai punti da 40 m. Un sentiero porta i campi 320 m più in là **solo se è collegato** al villaggio (proposta di Claude). Non attraversa il fiume né la palude; anteprima come in Cities (`docs/hud.md`). Si disegna come un nastro di terra battuta largo 3,5 m posato sul terreno, che serpeggia di qualche metro, con due solchi e bordi sfrangiati; si interrompe dove guada i torrenti (prima era fatto di celle di terra battuta e sembrava una fascia scura a gradini).
- **Granaio:** 30 di cibo, vicino al centro; le scorte si conservano meglio.
- **Politiche** (decisione di Fede del 24/11: le usanze sono politiche, non costruzioni; pannello a parte, tasto P). Cambiarne una dopo la fondazione costa un po' di consenso.
  - *Divisione del raccolto:* in comune (più legittimità) o alle famiglie (più raccolto).
  - *Accoglienza degli stranieri* (proposta di Claude, numeri da tarare): in media ogni 40 anni arriva un gruppo di 6–18 persone. Aperta: restano sempre; chiusa: vengono mandati via (il villaggio resta unito, un po' di consenso in più); caso per caso (all'inizio): il tempo si ferma e si decide. Accolti: più braccia, tecniche nuove (campi più fertili dell'8% per 15 anni), qualche malattia (salute −3) e un po' di attrito. Gli arrivi usano un generatore a parte, così le altre vicende restano le stesse a parità di seme.
- **Ammodernamento tecnologico** (decisione di Fede): nel blocco Gestione, scheda Ammodernamento allo stesso livello delle politiche, un tasto per settore (oggi Agricolo; poi viario, abitativo…). Non costruisce niente da zero, sovrascrive il tipo vecchio dei campi (e in futuro di strade, case e simili) con quello dell'epoca. Attivo, ogni anno si rifà fino al 10% dei campi lavorabili, i più vicini al centro, pagando 0,8 di cibo per campo da 0,16 ha (proposta di Claude, approvata da Fede: un po' ogni anno, perché servono braccia; numeri da tarare). Non costa consenso. Nel villaggio non c'è niente da ammodernare: il tasto c'è già, spento, fino al primo cambio d'epoca.
- **Demolisci** (X, decisione di Fede): toglie nel cerchio alberi (legname), case, campi, sentieri e granaio; il focolare al centro resta. Sul lotto di una casa demolita non rinasce una casa per 20 anni (macerie): Fede ha approvato la regola e ha precisato che vale **solo per l'abitato spontaneo**; per gli edifici voluti dal giocatore (come il granaio) non c'è attesa. Fiumi e paludi non si demoliscono.
- **Ritmo meditativo** (decisione di Fede del 24/11/2026, dopo una partita che metteva angoscia): fermano il gioco solo le scelte vere; piene, carestie, siccità e crisi sono notifiche discrete. Prima, in 500 anni, le finestre che fermavano il gioco erano 45–50.
- **Piene** (decisione di Fede): di stagione, frequenti (30% all'anno), toccano solo i campi nelle zone a rischio alto e ne tolgono il raccolto; disastrose, rare (1,1% all'anno), arrivano dove dice il rischio della mappa e travolgono anche le case. Contano solo se toccano il villaggio: una piena lontana non si nota nemmeno nella cronaca. Il ricordo del pericolo torna vivo solo con le piene disastrose che toccano il villaggio.
- **Frequenze** (proposta di Claude accolta da Fede): presagio delle sorgenti circa uno ogni 100 anni (0,6% all'anno quando può capitare), stranieri circa uno ogni 70 anni (1,4%).
- **Eventi e presagi:** piene, siccità con presagio vero (le sorgenti calano), cometa come presagio falso, primo cattivo raccolto, affollamento (allargarsi o villaggio figlio), crisi di legittimità, abbandono (le rovine restano e si può rifondare), fine dopo 500 anni con il riepilogo.

## Verifiche
- `test/verifica_villaggio.gd`: valutazione dei siti, azioni, una partita di 500 anni per ogni sito con un giocatore automatico, nessuna casa sull'acqua, simulazione deterministica con lo stesso seme.
- `test/verifica_partita.gd`: la partita nella scena principale (fondare dal comando, campi, tempo, scelte, indicatori).
- Foto: `test/foto_partita.gd`.

## Note di bilanciamento
Con il giocatore automatico tutti e sei i siti reggono 500 anni; le popolazioni finali superano spesso il migliaio, come già nel prototipo web: alte per un villaggio neolitico, da ricalibrare dopo le prove di Fede. Il dosso nelle paludi resta piccolo (poche case trovano posto), l'area dei gessi soffre più carestie.

## Da fare
- Prove di Fede e taratura.
- Livelli dell'acqua che salgono con le piene, nella grafica.
- Salvataggio della partita (con l'uso del suolo).
