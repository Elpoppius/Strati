# Todo — Villaggio completo (prima epoca)

*Aperto il 24/11/2026 su richiesta di Fede: chiudere la prima epoca prima di passare all'abitato protourbano (principio: prima la profondità, poi l'ampiezza). Riorganizzato il 25/11/2026 (richiesta di Fede) perché **chi riprende, con l'altro account, sappia cosa fare senza la conversazione**. Riferimenti di design: `era-origini.md` (l'Era delle Origini, con tutte le decisioni e i traguardi) e `pilastri-e-decisioni.md`.*

Legenda: `[x]` fatto · `[~]` in parte · `[ ]` da fare · **(?)** serve una decisione di Fede prima di cominciare.

## Come si lavora (vale per ogni voce)
1. **Prima di toccare il codice:** riepilogo a Fede di cosa si farà e attesa del suo ok (è una sua regola). Le proposte non confermate si segnano come tali.
2. **Dopo:** tutte le 10 verifiche (`CLAUDE.md`, "Comandi utili"); poi, se la voce tocca le dinamiche, le prove con i **giocatori "umani"** (`test/giocatore_umano.gd`, quattro profili: è la base dei test, decisione di Fede del 25/11/2026) e il **registro degli avvisi** (`test/registro_avvisi.gd`) per il ritmo. I giocatori automatici devono imparare a usare ogni strumento nuovo: i gesti comuni stanno in `test/aiuti_giocatori.gd`.
3. **Traguardi** da rispettare (`era-origini.md`, § 9): circa 2–3 pause a partita (si ferma solo per le scelte), poche notifiche, carestie rare e leggibili, nessun abbandono al livello medio, nucleo 100–300 abitanti, territorio fino a 600–800 per chi gioca molto bene.
4. **Alla fine:** voce in cima al diario, todo aggiornato, commit e push.

## A che punto siamo (27/11/2026, mattina)
**Il villaggio (epoca 1) è finito dalla parte di Claude:** tutte le voci della lista sono fatte (0–10, A, B, C). Restano solo cose che passano da Fede:
- la **prova al PC** con la finestra F3 (17 caselle) e il Registro acceso; poi Claude legge il Registro e corregge;
- la **direzione artistica** da guardare in prova (torre, passerella, varianti delle case, acqua della piena, maiale);
- il **bilanciamento delle scorrerie** (Fede: "proverò in gioco"; misure in `sessioni-giocatori.md`);
- ~~la scelta della prossima Era sulla carta~~: per ora nessuna (Fede, 27/11: ci si concentra sull'epoca 2).

Dopo la prova fisica e le correzioni: l'abitato protourbano (epoca 2), da progettare con Fede.

**Ordine seguito (proposto da Claude e accolto da Fede il 26/11/2026 sera):** B → 4 → 5 → 9 → 6 → 10, tutte fatte fra il 26/11 sera e il 27/11 mattina.

**Divisione del lavoro (Fede, 26/11/2026):** Fede nelle prove si sofferma sulla **direzione artistica**; le questioni tecniche (fotogrammi al secondo, tempi, errori) le raccoglie il registro tecnico della voce B, che Claude legge.

Fatte: le basi della prima epoca e le voci 0 (cantieri visibili), 1 (capanno e posta), 2 (pascolo e animali), 2b (tutorial alle tappe), 3 (luogo sacro, sacerdote, bosco sacro), 7 (popolazione visibile, con viso e spalle rifiniti, scheda della famiglia, umore e prestigio delle famiglie), 8 (mappe tematiche), A (specchietti in gioco), B (registro tecnico, 26/11/2026 sera), 4 (scorrerie e torre di avvistamento, 26/11/2026 sera). Forme di governo delle epoche 2–4 decise. Restano 5, 6, 9, 10, la prima lettura del registro e le prove di Fede.

**Stime riviste** (richiesta di Fede del 25/11/2026). Tempi veri del 25/11, dall'ok di Fede al push, presi dai commit:

| Lavoro | Stima di prima | Tempo vero |
|---|---|---|
| 1. Capanno e posta (con 72 partite umane e registro) | 1,5–2 ore | 1 ora e 13 minuti (di cui circa 25 di partite) |
| 0. Cantieri visibili (cinque scheletri, barra, prove) | 30–60 minuti | 13 minuti |
| 8. Mappe tematiche (tre mappe, shader, legende, prove) | 2–3 ore | 17 minuti |
| 3. Luogo sacro, sacerdote, bosco sacro (con partite umane e registro) | 2–3 ore | 41 minuti (di cui circa 25 di partite) |
| Sacerdote contrariato senza luogo sacro | — | 12 minuti (partite interrotte) |

Le stime di prima erano da 2 a 8 volte troppo alte: erano pensate come ore di lavoro di una persona. Il costo fisso vero è quello delle prove, circa **25 minuti di partite umane e registro** per ogni voce che tocca le dinamiche; le foto di controllo prendono 2–3 minuti l'una. Il resto del tempo lo prendono le conferme e le prove di Fede.

| Voce | Stima rivista (prove comprese) |
|---|---|
| 0, 1, 3, 8 | **fatte** (25/11/2026) |
| 2. Pascolo e bestiame visibile | 1,5–2 ore (simulazione 30–45 min, modelli e animali sulla mappa 30–45 min, prove 25 min) |
| 4. Scorrerie | 40–60 minuti |
| 5. Sentieri che diventano strade | 40–60 minuti |
| 6. Evento soglia e passo elastico | 1,5–2,5 ore (la più delicata: il passo a decenni tocca tutte le regole "per anno") |
| 7. Popolazione visibile | 1,5–2 ore (serve una prova di Fede per i fotogrammi al secondo) |
| 9. Base tecnica | 1–1,5 ore (salvataggio, acqua che sale, varianti; più le prove sui PC di Fede) |

In tutto **7–10 ore di lavoro di Claude**, cioè 2–3 giornate, più le conferme e le prove di Fede (che oggi sono la parte più lunga), poi la prova fisica e le correzioni.

## Piano per il 27/11/2026 (deciso con Fede la sera del 26/11)
**Decisioni di Fede (26/11/2026, 23:24):**
1. Menù delle impostazioni: **tutto ok** come proposto (qualità a tre livelli, F10, Strumenti › Partita, `impostazioni.cfg`).
2. Presagi: **allentarli** a decenni, e **più frequenti con il sacerdote scontento**.
3. Soglie del primo governo: **da rifare** (devono uscire tutte e tre le forme).
4. Strade: **niente passerella sui torrenti larghi** (servirà il ponte nell'epoca dopo: lì la strada si ferma al guado); le passerelle restano sui corsi stretti e sul fradicio. Case lungo la via: **si lascia così** (Fede, 23:28: "è più organico"; il borgo lungo la via compare solo quando il centro è pieno). **I sentieri li costruisce solo il giocatore** (niente sentieri battuti da soli).
5. Scorrerie: la mezza pausa in più **va bene**, con attenzione al bilanciamento.
6. Direzione artistica: **da verificare** nella prova al PC.
7. Numeri, testi e tasti proposti da Claude: **tutto ok**.
8. Fede chiede perché l'Età industriale prima delle Ere che vengono prima: Claude spiega (viene da `epoche-future.md`, progettare all'indietro da Haussmann). Fede: **domani si vede**; le epoche si stanno già ragionando in prospettiva futura.

**Fede decideva** (nell'ordine):
1. Menù delle impostazioni (voce 10): il contenuto proposto da Claude (Partita: tutorial, salvataggi automatici, velocità di partenza; Grafica: qualità a tre livelli, fotogrammi massimi, schermo intero, scala dell'interfaccia; Comandi in sola lettura; Registro acceso o spento; file `D:\Godot\Strati\impostazioni.cfg`; tasto F10 e voce in Strumenti › Partita). Qualità a tre livelli o voce per voce?
2. Presagi a decenni: più rari (ogni 5–8 secoli) o notifiche grigie senza pausa?
3. Soglie del primo governo (il Consiglio dei clan non esce mai).
4. Strade: passerelle sui torrenti larghi; case lungo la via più evidenti?; sentieri battuti da soli dalle famiglie?
5. Scorrerie: la mezza pausa in più a partita per la prima scelta sui segni.
6. Direzione artistica: torre, passerella, varianti delle case, acqua della piena, maiale.
7. Numeri e testi proposti da Claude: rischio e perdite delle scorrerie, strade, umore delle famiglie, popolazione visibile, nomi delle famiglie, tasti (U, F5, F8, F10).

**Fede verifica** al PC: le 16 caselle della finestra Debug (F3), con il Registro acceso (Claude poi lo legge da `D:\Godot\Strati\Registro`).

**Claude lavora:**
1. [x] Voce 10, menù delle impostazioni (27/11 mattina).
2. [x] Le decisioni 2–5 di Fede (27/11 mattina): presagi più radi a decenni e più fitti con il sacerdote scontento; soglie del primo governo rifatte sulla tabella; niente passerella sui torrenti larghi; prove dei giocatori "umani" (anche lunghe) e registro degli avvisi. Da guardare con Fede: le scorrerie nelle partite lunghe (6–16 in 3000 anni, una ogni 200–500 anni).
3. Lettura del Registro dopo la prova di Fede e correzioni (come la voce C del 26/11).
4. Ritocchi di direzione artistica che Fede chiede.
5. Sulla carta: per ora nessuna Era nuova (Fede, 27/11).
6. Dopo: l'abitato protourbano (epoca 2), da progettare con Fede.

## Per chi riprende: il lavoro in ordine

### D. [~] Correzioni dalla prova di Fede del 27/11/2026 sera
**Fatto la sera stessa** (decisioni di Fede, regole in `prototipo0-godot.md`): **legna alla maniera dei giochi di strategia** (serve solo a costruire, il fuoco fuori dal conto; legnaia con due famiglie di boscaioli fisse che si fermano a catasta piena; risemina nella scheda; niente famiglie che fanno legna da sole; legno di palude); **torre ovunque**; **registro del gioco** (Fede: "fai in modo che il log registri anche come gioco io": gesti, politiche, scelte, velocità, notifiche, pause, riga STATO, impostazioni in testa). **Restano, proposte di Claude senza risposta:** piena più leggibile come acqua; figure che usano i sentieri già da 60 m; la domanda sulle case dell'epoca 2 nell'epoca 1 (F9 quando la rivede).
**Cosa ha visto Fede** (registro `sessione-2026-11-27-184449`, commit 3590122, GTX 1050; salvataggi in `D:\Godot\Strati\Salvataggi`): una macchia scura che si muove dalla foresta; la gente non usa i sentieri; case dell'epoca 2 nell'epoca 1; impostazioni attive?; torre non costruibile; cliccando "Al lavoro" la legnaia si rompe di nuovo; legna sempre a 0. Il cibo funziona bene. Nessun errore nel registro; 60 fps nei primi secoli, 41–50 a decenni.
**Diagnosi di Claude:**
- **Legna:** al 4975 a.C. (340 abitanti) i focolari bruciano 170 m³ l'anno; le due legnaie hanno tagliato tutto entro 600 m e sono ferme ad aspettare la ricrescita; anche le famiglie trovano zero, perché cercano entro 600 m dal centro. Al 2989 a.C. (574 abitanti) 290 m³ di focolari, legna 0, affollamento 43–52% (niente legna per le case). Rimessa "Al lavoro", una legnaia taglia 342 m³ il primo anno e in 5 anni la zona passa da 0 a 559 m: è la "rottura" (tutto il bosco nel raggio sparisce). Causa: la zona tagliata non ricresce finché la legnaia lavora (decisione del 25/11), quindi non c'è resa sostenibile; il fuoco chiede più di quanto il bosco dia.
- **Macchia scura:** quasi certamente l'acqua della piena di stagione (torbida e bruna, sale in 3 s dal fiume attraverso il bosco di riva): si legge come terra, non come acqua.
- **Sentieri:** le figure li usano solo oltre 150 m, se partenza e arrivo sono entro 200 m da un sentiero e la strada non è più lunga di una volta e mezza.
- **Torre:** nel sito di Fede non c'è nessun dosso o colle entro 1200 m (0 punti buoni), come in Pianura aperta; e con la legna a 0 non si potrebbe comunque.
- **Impostazioni:** attive (il file c'è, letto all'avvio: qualità alta, registro acceso).
- **Case dell'epoca 2 nell'epoca 1:** nelle foto ci sono solo case dell'epoca 1; l'edificio su pali con la scaletta è il granaio. Da chiedere a Fede.
**Proposte:** vedi la conversazione del 27/11 sera (ceduo a rotazione, famiglie che vanno più lontano, piena più leggibile, sentieri usati anche vicino, torre che dice subito se il sito non ha alture, impostazioni scritte nel registro).

### C. [x] Correzioni dalla prova di Fede (26/11/2026 sera) — fatte la sera stessa
**Fatto** (descrizione in `prototipo0-godot.md`, `hud.md`, `asset.md`): legna rifatta con gli alberi e il loro valore (legna da ardere senza abbattere, tronchi abbattuti uno alla volta dalla legnaia, zona di passaggio che non ricresce finché la legnaia lavora, catasta piccola), alberi che spariscono uno alla volta durante l'anno, cerchio della legnaia solo quando serve, scheda della legnaia con Al lavoro e A riposo, strumenti e politiche che compaiono con la tappa, tasti tra parentesi, lotto bianco e rosso solo dove non si può, HUD fermo, cursori veri (freccia, selezione, mirino) e cornice di selezione, stranieri dalla tappa dei 150, edifici delle risorse più grandi, scorreria di prova nel menù Prova, modelli caricati all'avvio. La legnaia resta gratis (solo braccia): se costasse legna, un villaggio rimasto senza non ne uscirebbe più. **Resta:** la prova di Fede (le prove nella finestra Debug, F3).
**Cosa ha visto Fede** (prova al PC, commit 52e92ec, registro `sessione-2026-11-26-184529`): la legnaia si allarga in fretta e abbatte subito tutto nel raggio (deve essere progressiva e lenta); il suo cerchio è sempre visibile, in continua espansione e più grande del villaggio, finché non restano alberi (legna a 0, −27 l'anno, quindi niente granaio né luogo sacro); "a riposo o al lavoro" va in una finestra con l'opzione, non nella riga dei messaggi; manca un cursore di selezione; l'HUD balla; i tasti vanno solo tra parentesi, non spiegati a parole; "si apre a…" no: le cose semplicemente compaiono; il puntatore è sempre rosso (rosso solo dove non si può costruire); il primo arrivo degli stranieri è venuto prima della sua politica; capanno, legnaia e gli altri edifici delle risorse vanno ingranditi alla misura delle case; le scorrerie non si sono potute provare (la partita è finita appena aperte).
**Dal registro** (GTX 1050, 1600×900): 60 fps quasi sempre, minimo 33 con 149 figure a 40 m; fotogrammi da 130–150 ms quando si sceglie uno strumento la prima volta; scena pronta in 6,5 s; nessun errore.
**Diagnosi di Claude:** la legnaia vuole riempire una catasta enorme (100 + 3 per abitante: 720 con 200 abitanti), quindi taglia fino a 24 di legna l'anno anche se se ne consumano 27; un pixel (0,16 ha) dà solo 4 di legna; la zona di una legnaia al lavoro non ricresce mai. Il bosco entro 600 m sparisce in pochi secoli e la legna crolla.
**Proposta di Claude (da confermare):** vedi il riepilogo in conversazione del 26/11/2026 sera (ceduo a rotazione, catasta piccola, più legna per pixel, cerchio solo con gli strumenti che lo riguardano, finestra della legnaia, strumenti nascosti finché non compaiono, tasti tra parentesi, puntatore bianco, HUD fermo, stranieri dalla loro tappa, edifici più grandi, cursore di selezione, scorreria di prova).

### B. [x] Registro tecnico in gioco (richiesta di Fede del 26/11/2026; fatto il 26/11/2026 sera)
**Fatto** (riepilogo di Claude approvato da Fede: "Scrivi il registro ora"): `script/registro.gd`, descritto in `CLAUDE.md` ("Base del gioco") e in `hud.md`; verifica `test/verifica_registro.gd` (la decima), foto `test/foto_registro.gd`.
- **Cartella (Fede): `D:\Godot\Strati\Registro`**, creata dal gioco al primo avvio; un file per sessione (`sessione-AAAA-MM-GG-hhmmss.txt`), si tengono gli ultimi 10 con le foto dei loro segnalibri. Se il disco D: non c'è o non si può scrivere, `user://registro/` e la prima riga lo dice. La cartella `Registro/` è nel `.gitignore` (sui PC di Fede sta dentro il repository).
- **In testa:** commit del gioco (letto da `.git`), versione di Godot, sistema, processore e memoria, scheda video con driver e API, renderer, finestra e schermo, sincronia verticale; poi l'evento PARTITA con mappa e seme.
- **Ogni 10 secondi, una riga:** ora, fotogrammi al secondo medi e minimo, fotogramma più lento, chiamate di disegno, memoria, memoria video, zoom, anno e velocità, alberi, animali e figure disegnati.
- **Eventi:** CARICAMENTO (mappa, alberi dalla cache o calcolati, scena pronta), LENTO (fotogrammi sopra 100 ms con il contesto: zoom, rotazione, anno che passa, strumento, finestra di scelta, alberi in calcolo; al massimo 5 per riga, gli altri contati), ERRORE e AVVISO (da Godot, con file e riga), SPUNTA e SPUNTA TOLTA, DEBUG (finestra aperta o chiusa), SEGNALIBRO, FINE.
- **F3, finestra Debug:** numeri dal vivo e prove da verificare (`Registro.PROVE`, da aggiornare quando cambiano le prove aperte qui sotto). **F9, segnalibro:** ora, camera e foto dello schermo.
- **Resta:** la prima prova di Fede al PC e la prima lettura: Claude chiede l'accesso alla cartella `D:\Godot\Strati\Registro` con l'app desktop collegata (`device_request_folder_access`) quando Fede dice che è al PC (Fede, 26/11/2026: "appena ti segnalo che sono da PC lo riprendiamo").

### A. [x] Specchietti in gioco: "Conseguenze" e "Rapporti di forza" — PRIORITÀ 1
**Fatto il 26/11/2026 pomeriggio** (descrizione in `hud.md` e `prototipo0-godot.md`; foto `docs/immagini/conseguenze-26-11.jpg` e `rapporti-di-forza-26-11.jpg`). Resta la prova di Fede nel gioco. Sotto, il disegno di partenza.
**Deciso** (Fede, 26/11/2026: "al primo posto metti questo già per il villaggio"; proposta di Claude in conversazione). Due specchietti che leggono ciò che la simulazione sa già, senza regole nuove; poche parole e barre, il perché esteso al passaggio del puntatore. Il gioco non si ferma.
1. **Conseguenze**, nel blocco Descrizione della scheda dello strumento (`hud.gd`), prima del clic: **Chi guadagna** e **Chi perde** (gruppi con frecce ▲ ▼, e il motivo breve tra parentesi), **Sul territorio** (cosa cambia: bosco protetto, legnaie più lontane, campi più vicini…), **Costo** (legna, braccia, anni di cantiere), **Resta** (la traccia). Esempio del villaggio:
```
BOSCO SACRO · 4 ettari
Chi guadagna    Sacerdote ▲▲
Chi perde       Famiglie ▼        (legna più lontana)
Sul territorio  bosco protetto · legnaie più lontane
Resta           nessuno potrà tagliarlo
```
2. **Rapporti di forza**, evoluzione del pannello di focus del Consenso (clic sull'indicatore; più un tasto che lo apre e lo chiude): per ogni gruppo il **peso** (quanto conta: nel villaggio i pesi di `sim_villaggio.gd`, anziani e famiglie 0,4, sacerdote 0,2) e l'**umore** (consenso, con la parola e la freccia di tendenza); sotto, **Tensione** e **Si muove verso** (gli assi dell'identità di `epoche-future.md` § 2 detti a parole, senza nominarli: "terra alle famiglie · più aperta", mossi dalle politiche del raccolto, degli stranieri e dai consensi). Nel villaggio: "Governano gli anziani", nessun nome di regime, niente peso latente.
```
RAPPORTI DI FORZA                       5420 a.C.
Governano gli anziani
──────────────────────────────────────────────────
                  peso      umore
Anziani           ████      ███████░░░  contenti
Famiglie          ████      ████░░░░░░  scontente ▼
Sacerdote         ██        ██████░░░░  tranquillo
──────────────────────────────────────────────────
Tensione          ██░░░░░░░░  bassa
Si muove verso    terra alle famiglie · più aperta
```
- **Più avanti** (dall'epoca 2): nome della città, regime e vocazione in testa; peso latente tratteggiato; deriva al posto di "si muove verso" (`epoche-future.md` § 2).
- **Come farlo:** per ogni strumento di `partita.gd` una funzione che stima gli effetti sui gruppi e sul territorio dalle stesse regole della simulazione (consenso, legna, bosco, cibo), da mostrare con `leggi_per_strumento`; gli assi dell'identità come valori nascosti in `SimVillaggio`, mossi dalle politiche esistenti; tensione dalla distanza tra i consensi dei gruppi pesati. Foto di controllo con `test/foto_hud.gd` e `foto_partita.gd`; verifiche in `verifica_partita.gd` e `verifica_hud.gd` (nessun muro di testo: righe e lunghezze massime); niente partite "umane" se le dinamiche non cambiano.
- **Stima:** 45–75 minuti. Prima di toccare il codice, riepilogo a Fede.

### 0. [x] Cantieri visibili (richiesta di Fede del 25/11/2026 sera)
**Fatto** il 25/11/2026 sera. Deciso da Fede: sopra ogni edificio in costruzione una **barra discreta** che avanza anno dopo anno, e al posto dell'edificio finito il suo **scheletro** (stessa struttura, solo pali e travi, con materiali e attrezzi accanto; scelto da Fede tra cantiere unico e scheletro di ogni edificio). Modelli `cantiere_granaio`, `cantiere_legnaia`, `cantiere_capanno_pesca`, `cantiere_posta_caccia` (`villaggio.py`, foto `docs/immagini/cantieri-25-11.jpg`); barra `shader/barra_cantiere.gdshader` (foto `docs/immagini/barra-cantiere-25-11.jpg`). **Il luogo sacro (voce 3) avrà il suo scheletro** in `VistaVillaggio.CANTIERI`. Le case nascono da sole, senza cantiere.
*Ordine proposto da Claude il 25/11/2026; le voci sono già approvate da Fede nei contenuti, salvo dove c'è (?).*

### 1. [x] Capanno da pesca e Posta di caccia
**Fatto il 25/11/2026 sera** (regole e numeri in `prototipo0-godot.md`, prove in `sessioni-giocatori.md`): senza edifici un terzo, con l'edificio pieno (35 di cibo l'anno al massimo); aggancio alla riva (capanno) e al margine del bosco (posta) anche nella simulazione senza grafica; pesce e selvaggina in riquadri di 200 m; strumenti con anteprima agganciata e lettura; cause nel pannello del Cibo; i giocatori automatici li costruiscono. Restano le due domande in "Da decidere con Fede" (carestie nei siti di caccia, aggancio e tasti della posta). Sotto, le note di lavoro di prima.
**Deciso** (Fede, 25/11/2026): stessa dinamica della legnaia; senza questi edifici caccia e pesca non spariscono ma rendono circa un terzo.
- **Capanno da pesca** (germe dell'approdo e del porto): **solo sulla riva** (Fede, 25/11/2026, come i moli: aggancio automatico al punto di riva più vicino entro circa 30 m, girato verso l'acqua; fuori dalla palude; anteprima già agganciata, rossa con "Serve la riva di un fiume o di un torrente" se non c'è riva); **nessuna distanza minima tra capanni** (Fede: chi ne ammassa tanti esaurisce il pesce di quel tratto, è una scelta sua). **Deciso** (Fede, 25/11/2026, su proposta di Claude): il pesce diventa locale per tratto di riva, come la selvaggina attorno alla posta: più capanni vicini se lo dividono, troppi lo fanno calare, e si riprende in qualche anno se lasciato stare; rende di più vicino all'acqua e secondo il tipo d'acqua (fiume più dei torrenti, poco le paludi).
- **Posta di caccia**: al margine del bosco; rende di più dove il bosco è fitto e la selvaggina abbondante. **La selvaggina diventa locale** attorno alla posta: se si caccia troppo lì cala, e conviene spostarsi (oggi `selvaggina` è un numero unico per il villaggio).
- **Come farlo:** copiare l'impianto della legnaia in `script/sim_villaggio.gd` (`motivo_legnaia`, `costruisci_legnaia`, `capacita_legnaia`, `_lavora_legnaie`, `stato_legnaia`); oggi caccia e pesca sono calcolate in `passo()` da `_risorse` (bosco e acqua attorno al centro) con `QUOTA_CACCIA`, `QUOTA_PESCA`, `RESA_BOSCO`, `RESA_ACQUA`. In `script/partita.gd`: `STRUMENTI`, menu Edifici, `_applica`, `leggi_per_strumento` (lettura sotto il puntatore), `_raggio_strumento`; tasti liberi in `script/principale.gd` (oggi usati: Z, C, V, H, L, X, P, G, I, F, Y). Icone SVG in `gioco/asset/icone/` (stile di `legnaia.svg`). Disegno in `script/vista_villaggio.gd` (come `_sincronizza_legnaie`, modelli da `asset/villaggio/`). Cause nel pannello di focus del Cibo (`cause_di("Cibo")`). Le fonti di cibo nelle politiche restano.
- **Icone già pronte** (25/11/2026): `asset/icone/capanno_pesca.svg` (pesce sopra un'onda) e `posta_caccia.svg` (palco di corna); anteprima `docs/immagini/icone-risorse-25-11.png`.
- **Modelli fatti** (25/11/2026, `strumenti/blender/villaggio.py`, descrizioni di Claude accettate da Fede):
  - **Capanno da pesca** (`capanno_pesca()`, `asset/villaggio/capanno_pesca.glb`, foto `docs/immagini/modello-capanno-pesca-25-11.jpg`): canne, tetto a due falde, rastrelliera con rete e pesci, piroga, nasse. L'acqua è verso +y del modello.
  - **Posta di caccia** (`posta_caccia()`, `asset/villaggio/posta_caccia.glb`, foto `docs/immagini/posta-caccia-margine-25-11.jpg`): riparo basso a una falda coperto di frasche fresche e secche, giaciglio, rastrelliera con una pelle tesa, pelle a terra coi picchetti, piccolo focolare, palo con il palco di corna, due lance. La schiena del riparo è verso +y del modello, da girare verso il bosco.
- **Posa provata** con `test/foto_posa.gd -- uscita capanno|posta dimensione rotazioni` (da riusare nello strumento e in `vista_villaggio.gd`):
  - capanno: terra asciutta a circa 2 m dall'acqua (`alberi.distanza_acqua(x, z)`), fuori dalla palude, poco inclinata; verso l'acqua contro il gradiente della distanza dalla riva (foto `docs/immagini/capanno-riva-25-11.jpg`);
  - posta: appena fuori dal bosco (`alberi.valore_bosco` circa 0,4), asciutta, poco inclinata; verso il bosco lungo il gradiente del valore del bosco;
  - rotazione del modello `atan2(-v.x, -v.y)`, con `v` la direzione verso l'acqua o il bosco; togliere gli alberi attorno in un cerchio un po' largo (un pioppo della riva nascondeva il capanno).
- **Note sui modelli:** dopo l'importazione, nei `.import` delle texture tenere `detect_3d/compress_to=0`; `villaggio.py` riesporta tutti i modelli e `fossa_silo.glb` cambia senza motivo: rimetterlo com'era con `git checkout`. Le falde dei tetti si creano nell'origine, si inclinano e poi si spostano. A ogni modello nuovo, mostrare la foto a Fede (la direzione artistica è sua).
- **Prove:** verifiche nuove in `test/verifica_villaggio.gd` (senza edificio un terzo, con l'edificio pieno, vicinanza); i giocatori automatici costruiscono gli edifici (aggiungere a `aiuti_giocatori.gd` e ai profili: chi conosce il genere subito e nel punto giusto, il casual dove capita); poi giocatori "umani" e registro. Attenzione: togliere due terzi di caccia e pesca a chi non costruisce cambia la crescita dei primi decenni.

### 2. [x] Pascolo e animali (con il bestiame visibile)
**26/11/2026, mattina tardi** (richieste di Fede): animali rifatti una terza volta, con corpo unico, pelo e carte di pelo sui riferimenti di Age of Empires IV, tre manti per specie e due livelli di dettaglio (`asset.md`); animazioni (passo, brucare, orecchie, coda) e movimento da un punto all'altro (accelerazione, curve, passo lungo, gregge in fila sciolta); **campo stanco visibile** fatto (proposta confermata). Confermate anche le proposte del tasto N, dei greggi uno per stabbio e della riga "si macellano" al massimo ogni 5 anni. **Resta per Fede:** provare i fotogrammi al secondo con 400 animali vicini. Decise da Fede (26/11/2026): il sacerdote chiede il luogo sacro quando se ne sblocca la costruzione (dentro il tutorial della tappa, voce 2b); i greggi restano come sono. Maiale rimodellato il 26/11 (sembrava un tapiro). Fede (26/11/2026, dopo la correzione della brucatura): "ora ci siamo"; l'ultima verifica la fa nella prova in gioco. **Secondario, da rivedere più avanti:** il maiale sembra un po' un facocero (meno testa a cuneo esagerata, criniera più bassa, corpo meno sbilanciato sul davanti).

**Fatto il 26/11/2026 mattina** (regole e numeri in `prototipo0-godot.md`): zona di pascolo a pennello con l'opzione Togli (anche per la zona agricola), capi con portata e crescita, stoppie e maggese, radure aperte, scorta viva, stranieri con animali, erosione sui pendii, disuguaglianza, indicatore e pannello Animali, stabbio e animali (pecora, capra, maiale, bue) in greggi sulla mappa, giocatori automatici, prove. Animali rifatti il 26/11 con una sagoma propria per specie (Fede li trovava abbozzati). **Resta:** il campo stanco visibile (proposta sotto, da confermare con Fede), la prova di Fede dei fotogrammi al secondo con le greggi e due domande per Fede: il sacerdote chiede il luogo sacro con una notifica grigia? Greggi più grandi (oggi 12 capi senza pascolo, 50–70 con 44 ettari)? Le vie degli animali arrivano con la voce 5, le scorrerie attirate dagli animali con la voce 4.
**Deciso** (Fede, 25/11/2026, `era-origini.md` § 4 "I cicli"): si apre a 100 abitanti. Concime ai campi vicini, scorta viva per le annate cattive, radure che restano aperte, erosione e piene se troppo pascolo sui pendii, ricchezza delle famiglie, vie degli animali come traffico sui sentieri, animali che attirano le scorrerie.
**Deciso** (Fede, 25/11/2026 sera, sulle domande di Claude):
1. **Zona di pascolo a pennello**, come la zona agricola: le famiglie portano gli animali da sole.
2. **Dove:** prati e radure, margini del bosco (il pascolo impedisce la ricrescita), e i **campi stanchi dentro la zona di pascolo diventano maggese da soli** (concimati, si riposano più in fretta); zona di pascolo e zona agricola possono sovrapporsi. **Requisito di Fede: si deve vedere sulla mappa quando un campo è stanco.**
3. **Un solo numero di "capi"**, con un misto di specie che si vede (pecore e capre soprattutto, maiali vicino al bosco, qualche bue). **Requisito di Fede: va gestito come cresce il numero dei capi.**
4. **Scorta viva:** nelle annate cattive gli animali si macellano da soli (niente pausa, una riga in cronaca); la mandria si ricostituisce negli anni buoni.
5. **Gli animali seguono la politica del raccolto** (in comune o alle famiglie): alle famiglie la mandria cresce di più, ma cresce la disuguaglianza (prepara le famiglie eminenti dell'epoca 2).
- **Deciso** (Fede, 25/11/2026 sera: "le due zone si parlano, ma non entrano in conflitto"):
  - **Campi nella zona di pascolo:** su un campo coltivato gli animali non entrano finché il grano è in piedi; dopo il raccolto pascolano le **stoppie** (poca erba e un po' di concime, che l'anno dopo migliora un poco la resa). Un campo stanco o incolto diventa **maggese**: gli animali ci stanno tutto l'anno (molta erba, concime, riposo più rapido); quando torna buono le famiglie lo riprendono a coltivare da sole. Il campo resta sempre un campo.
  - **Opzione "Togli"** negli strumenti Zona agricola e Pascolo (come "Collega alla rete" per i sentieri): con l'opzione accesa il pennello toglie la zona e lascia campi e animali dove sono. Oggi la zona si toglie solo con Demolisci, che toglie anche i campi.
- **Deciso** (Fede, 25/11/2026 sera, proposta di Claude) **Crescita dei capi:** alla tappa dei 100 abitanti il villaggio ha una decina di capi (gli animali che i fondatori tengono attorno alle case); la mandria cresce di circa il 10% l'anno finché c'è erba, cioè fino alla portata della zona di pascolo (circa 2 capi per ettaro di prato, meno nel bosco, di più sui campi a maggese); oltre la portata smette di crescere, e sui pendii il troppo pascolo dà erosione; gli stranieri accolti portano i loro animali; nelle annate cattive se ne macella quanto serve. Pannello di focus "Animali" con capi, portata ed erba.
- **Campo stanco sulla mappa** (proposta di Claude, confermata da Fede il 26/11/2026, fatto): il campo si schiarisce e si riempie di erbacce man mano che si stanca (un valore per cella passato allo shader del terreno, come le tecniche dei campi in `UsoSuolo.tecniche`); nella mappa della Fertilità i campi stanchi si vedono più poveri; un campo a maggese ha l'erba e gli animali.
- **Icona già pronta:** `asset/icone/pascolo.svg` (graticcio con un ciuffo d'erba). **Modello da fare:** uno **stabbio**, recinto basso di graticcio per la notte, con un abbeveratoio di tronco scavato; qualche stabbio sparso nella zona la rende riconoscibile (è diverso dal recinto urbano dell'epoca 2). In `villaggio.py` c'è già `recinto_animali()` da cui partire.
- **Come farlo:** zona di pascolo come `zona` in `sim_villaggio.gd` (`aggiungi_zona`, `zona_piena`) e nel pennello di `principale.gd`; `stanchezza` e `fattore_stanchezza` ci sono già. Modelli degli animali con Blender (`strumenti/blender/`, stile in `docs/asset.md`), disegno con MultiMesh e animazione dallo shader (come gli alberi). Prove: verifiche, giocatori "umani" (devono imparare a stendere il pascolo), registro.

### 2b. [x] Tutorial alle tappe (decisione di Fede del 26/11/2026)
**Fatto il 26/11/2026** (`script/tutorial.gd`, `Hud.mostra_tutorial`, descrizione in `prototipo0-godot.md`): a ogni sblocco il gioco si ferma con il riquadro (titolo, due o tre righe, "Cosa fa…?" che apre la spiegazione, Avanti/Continua, "Salta i tutorial" per il resto della partita); con i tutorial saltati una notifica grigia. Anche la fondazione e la tappa dei 60 (confermato da Fede). Pause dei tutorial contate a parte nelle prove "umane" e nel registro. **Resta:** l'opzione dei tutorial nel menù delle impostazioni (voce 10).

### 3. [x] Luogo sacro, sacerdote e bosco sacro
**Fatto il 25/11/2026 sera** (regole e numeri in `prototipo0-godot.md`; numeri proposti da Claude e approvati da Fede): luogo sacro in Edifici (tasto O, 20 di legna, 3 anni, entro 400 m, uno solo, con il suo scheletro), sacerdote come terzo gruppo dalla tappa dei 100 abitanti, contrariato finché il luogo sacro non è eretto (Fede, 25/11/2026 sera), presagi più chiari o ambigui, bosco sacro a pennello in Territorio (tasto B, pieno da 10 ha), legnaie e famiglie che non lo toccano, offesa se si taglia, case attirate. Sotto, le decisioni di partenza.
**Deciso:** cerchio di pali attorno a una pietra (forma confermata il 24/11/2026); si apre a 100 abitanti; costa legna e braccia con un cantiere. Il sacerdote diventa il terzo gruppo di consenso (`sacerdote_attivo` in `sim_villaggio.gd`, pesi 0,4/0,4/0,2 già pronti): contento, presagi più chiari; scontento, ambigui e con più voci false. Il **bosco sacro** (tappa dei 150) è la riserva: le legnaie non lo tagliano, tagliarlo offende il sacerdote. Il luogo sacro attira le case (germe della piazza).

### 4. [x] Scorrerie (fatte il 26/11/2026 sera)
**Fatto** (riepilogo di Claude approvato da Fede: "perfetto tutto"; regole e numeri in `prototipo0-godot.md`, prove in `sessioni-giocatori.md`): dalla tappa dei 100 abitanti, più rare prima del 4300 a.C.; rischio da ricchezza × esposizione × (1 − difesa); segni 1–2 anni prima con la direzione; i primi segni fermano il gioco una volta (tutorial e scelta) e aprono la politica **Ai segni di pericolo** (andare avanti, raccogliere, vegliare) e la **torre di avvistamento** (Edifici, tasto U, su un'altura; segni prima e perdite al 70%); perdite di animali e scorte, a volte case bruciate ai margini (macerie e rovine); memoria della paura che stringe l'abitato. **Resta:** la prova di Fede (modello della torre: `docs/immagini/torre-avvistamento-26-11.jpg`) e due domande sotto, in "Da decidere con Fede".
**Deciso:** attirate dalla ricchezza visibile (animali, scorte) e dai margini del contado poco usati; prima arrivano segni (fuochi sulle colline, tracce, villaggi vicini razziati); difendono il sito (colle, dosso) e un abitato compatto; i casali sparsi sono più esposti; si perdono animali e scorte, a volte case ai margini; cala il consenso degli anziani. Solo in cronaca, salvo le scelte che chiedono un intervento. Sono il ponte verso il recinto dell'epoca 2.

### 5. [x] Sentieri che diventano strade (fatte il 26/11/2026 sera)
**Fatto** (proposta di Claude approvata da Fede: "mi convincono le proposte"; regole e numeri in `prototipo0-godot.md`, foto `docs/immagini/strade-26-11.jpg` e `passerella-26-11.jpg`): ogni anno chi lavora lontano va dal centro al suo posto lungo la rete; un tratto con almeno 40 persone l'anno per 20 anni di fila diventa strada dalla tappa dei 250 e resta (si toglie solo con Demolisci). Nastro largo 5 m di terra compatta; passerelle di tronchi sui torrenti e sul fradicio. Campi entro 160 m +15%; case nuove anche lungo le strade entro 500 m dal centro; casale collegato +3 di umore; legnaia su una strada taglia il 10% in più. Le figure che vanno lontano camminano sulla rete. Con Sentiero la lettura dice il traffico ("Traffico: 35 persone l'anno · strada tra 8 anni"). Scheda di tutorial "Strade". **Resta:** la prova di Fede e le domande in "Da decidere con Fede".
**Deciso:** il traffico (campi, pascoli, legnaie, luogo sacro, casali) fa dei sentieri più battuti le prime strade, che restano come assi nelle epoche dopo. Si apre a 250 abitanti con i casali.

### 6. [x] Evento soglia "il metallo e lo scambio" e passo elastico (fatti il 26/11/2026 notte)
**Fatto** (proposta di Claude approvata da Fede: "ok vai procedi"; regole in `prototipo0-godot.md`): la partita arriva fino all'evento soglia (3000–1800 a.C.); a decenni dal 5600 a.C.; presagi del metallo, scelta, primo governo, aratro e riepilogo; menù Prova › Metallo; simulazione alleggerita (da 60 a 22 ms per anno, stessi risultati). **Resta:** la prova di Fede (fluidità a decenni sui suoi PC, testi, numeri del territorio pieno e del governo).
**Deciso** (`era-origini.md` § 2 e § 5): si apre quando il territorio è pieno e si è dentro la finestra (~3000–1800 a.C.); presagi (oggetti di rame, mercanti), dilemma aprirsi o restare isolati, transizione con riepilogo. **Passo elastico:** un anno per passo nei primi quattro secoli, poi un decennio (le regole vanno scritte per anno e moltiplicate per il passo). Oggi la partita finisce a 5500 a.C. (`ANNO_FINE`).
**Proposta di Claude (26/11/2026 notte, approvata da Fede):**
- **Passo elastico senza riscrivere le regole:** dopo i primi quattro secoli (dal 5600 a.C., o dalla tappa Territorio se arriva dopo) ogni passo mostrato vale 10 anni, ma dentro si calcolano i 10 anni uno per uno. Così le regole restano per anno e i numeri tarati non cambiano. Il costo è circa 0,4 s di calcolo per decennio. Una scelta che arriva a metà decennio ferma il passo in quell'anno. Le notifiche del decennio si raccolgono. I tasti del tempo diventano decenni al secondo.
- **Territorio pieno:** contado al raggio massimo e almeno il 70% della terra coltivabile del contado in campi o pascolo, oppure 600 abitanti. La finestra va dal 3000 al 1800 a.C.; al 1800 l'evento arriva comunque.
- **Presagi** dal 3300 a.C. (Età del Rame): due o tre, in cronaca e come notifica grigia (oggetti di rame portati da stranieri, mercanti di passaggio, armi nuove nei villaggi vicini).
- **Dilemma**, una pausa: aprirsi alle vie di passaggio o restare isolati. La scelta sposta l'asse dell'apertura e lascia il tratto della città.
- **Transizione:** riepilogo del villaggio (anni, abitanti, case, campi, strade, carestie, scorrerie, piene, chi conta) e il primo governo con un nome (Comunità, Consiglio dei clan, Casa dominante) dagli assi dell'identità. Arriva l'aratro: la tecnica nuova dei campi, con l'ammodernamento acceso. Poiché l'epoca 2 è ancora sulla carta, il prototipo finisce qui, con "Continua a guardare il villaggio".

### 7. [x] Popolazione visibile (resta la prova di Fede)
**Fatto il 26/11/2026 pomeriggio** (descrizione in `prototipo0-godot.md` e `asset.md`; foto `docs/immagini/persone-26-11.jpg`, `persone-nel-gioco-26-11.jpg`): sei persone in due livelli con le vesti del Neolitico, cinque attrezzi, colori per figura e animazioni nello shader, figure legate ai lavori della simulazione, tetto di 150 figure. **Rifiniti in serata** viso e spalle su richiesta di Fede (`docs/immagini/ritratti-prima-dopo-26-11.jpg`). **Fatta in serata** la scheda della famiglia (clic su persone e case, nome dal luogo: `prototipo0-godot.md`, `docs/immagini/famiglia-26-11.jpg`). **Fatti anche** l'umore di ogni famiglia in sola lettura e il prestigio nascosto (decisione di Fede del 26/11/2026, `era-origini.md` § 6). **Resta:** la prova di Fede (aspetto delle persone, scheda e fotogrammi al secondo, anche insieme agli animali). Le figure che camminano lungo sentieri e strade sono fatte con la voce 5.
**Deciso** (25/11/2026): ogni figura fa un lavoro vero della simulazione (campi, bosco, fiume, pascolo, cantieri, sentieri, luogo sacro); **3 modelli di uomini e 3 di donne** che si ripetono, con capelli, incarnato e vesti che variano; animazioni dallo shader; MultiMesh; si vedono solo da vicino; **scala da verificare con la simulazione** (800 persone a schermo sono troppe: tetto di figure visibili, una figura per 1, 2 o 5 persone). Clic su una persona: la scheda della sua famiglia. Prima il bestiame (voce 2), poi i lavoratori, poi chi cammina, poi la scheda.
**Deciso** (Fede, 26/11/2026): viene subito dopo la voce A; **servono anche le animazioni** (camminare, lavorare secondo il mestiere, stare fermi, parlare in gruppo) e **attenzione al livello di dettaglio**, con la stessa cura degli animali (corpo unico, vesti e capelli verosimili, due livelli di dettaglio secondo lo zoom, riferimento Age of Empires IV). A ogni modello, foto a Fede.

### 8. [x] Mappe tematiche (ok di Fede del 25/11/2026)
**Fatto il 25/11/2026 sera** (descrizione in `prototipo0-godot.md` e `hud.md`), tasti 6, 7, 8:
- **6 · Caccia e pesca** (Fede: il pesce nella stessa mappa, come cibo): bosco colorato dalla selvaggina, acque dal pesce, cerchi di poste e capanni, zone di taglio marcate.
- **7 · Abitato e contado**, distinti (decisione del 24/11/2026), con i casali.
- **8 · Memoria del suolo**: dove c'era il bosco, suolo sigillato, rovine.

### 9. [ ] Base tecnica
- [x] Salvataggio della partita, con l'uso del suolo (26/11/2026 notte; regole in `prototipo0-godot.md`). Proposte di Claude in attesa dello sguardo di Fede: cartella `D:\Godot\Strati\Salvataggi`, F5 e F8, Strumenti › Partita, automatici a ogni tappa e ogni 50 anni (ultimi 3).
- [x] Livelli dell'acqua che salgono con le piene, nella grafica (26/11/2026 notte; foto in `docs/immagini/piena-*-26-11.jpg`). Da guardare con Fede: colore dell'acqua torbida, tempi (3 s su, 5 fermi, 7 giù), quanto copre.
- [x] Varianti dei modelli del villaggio (26/11/2026 notte, proposta di Claude: una seconda versione per ogni tipo di casa, con cataste, orto, tettoia, recintino o telaio per le pelli; metà dei lotti; foto `docs/immagini/varianti-case-26-11.jpg`). Da guardare con Fede.
- Prove sui PC di Fede: tempi degli alberi e fotogrammi al secondo (con il Registro, F3; anche il salvataggio).

### 10. [x] Menù delle impostazioni (fatto il 27/11/2026 mattina)
**Fatto** (proposta di Claude approvata da Fede il 26/11: "tutto ok"; regole in `prototipo0-godot.md`, foto `docs/immagini/impostazioni-27-11.jpg`): F10 o Strumenti › Partita › Impostazioni; Partita (tutorial, salvataggi automatici, tempo dopo la fondazione), Grafica (qualità a tre livelli, fotogrammi, schermo, scala dell'interfaccia), Registro, Comandi; file `D:\Godot\Strati\impostazioni.cfg`. **Resta:** la prova di Fede (casella in F3).

Un menù delle impostazioni del gioco, con dentro anche l'opzione dei tutorial (accesi o spenti per le partite nuove). Da progettare con Fede: cosa contiene oltre ai tutorial (per esempio velocità di partenza, qualità grafica, lingua), dove si apre (tasto, voce dell'HUD), dove si salva sul PC.

## Da decidere con Fede
- **Scorrerie (26/11/2026 sera):** in Pianura aperta e nel Dosso nelle paludi non c'è nessuna altura entro 1200 m, quindi niente torre: **va bene così** (Fede, 26/11/2026: è una conseguenza del sito). Resta aperta: le pause vere salgono di circa mezza a partita per la prima scelta sui segni (4,2–4,6 contro 3,7–3,9; il traguardo è 2–3).
- **Proposte di Claude da guardare (scorrerie):** i numeri del rischio e delle perdite (`prototipo0-godot.md`), il tasto U, i testi dei segni, il modello della torre.
- **Prove di Fede, aperte (aggiornate il 26/11/2026 notte):** tutte nella finestra Debug (F3) del gioco, come caselle da spuntare: anche strade, figure sulla rete, varianti delle case, piena, salvataggio (F5, F8, automatici), tempo a decenni, evento del metallo (Prova › Metallo), fotogrammi al secondo a decenni.
- **Prove di Fede, aperte (26/11/2026 sera):** legna (alberi tagliati uno alla volta), scheda della legnaia, cursori e cornice di selezione, puntatore rosso, HUD fermo e cose che compaiono, edifici più grandi, specchietti, scorrerie (Prova: Scorreria). Sono le caselle della finestra Debug (F3). Spuntate da Fede il 26/11 sera: persone (aspetto e animazioni), scheda della famiglia, maiale, fluidità con animali e figure (60 fps, minimo 33 a 40 m con 149 figure sulla GTX 1050), tutorial.
- **Proposte di Claude in attesa di uno sguardo (26/11/2026):** i dodici nomi comuni delle famiglie, l'ordine dei desideri ("Vorrebbe"), la cornice bianca della casa; i numeri dell'umore delle famiglie (−12 piena ricordata, −8 zona delle piene, −6 legna lontana, −5 campi stanchi e casale senza sentiero, +3 focolare e luogo sacro); i numeri della popolazione visibile (150 figure, 1/2/5 persone per figura, visibili sotto i 450 m).
- **Menù delle impostazioni (voce 10):** cosa contiene oltre ai tutorial.
- **Partite lunghe (voce 6):** presagi e soglie del governo **fatti** il 27/11. **Scorrerie diradate a decenni** (Fede, 27/11: "diradale a decenni"): almeno 250 anni fra una e l'altra, probabilità al 40%; nelle partite lunghe da 2–20 a 1–7 (media da 9 a 4,3).
- **Salvataggio e piene (voce 9, 26/11/2026 notte), proposte di Claude:** cartella `D:\Godot\Strati\Salvataggi`, F5 salva e F8 riprende, Strumenti › Partita, automatici a ogni tappa e ogni 50 anni (ultimi 3); acqua della piena torbida e bruna, 3 s su, 5 fermi, 7 giù.
- **Strade (voce 5, 26/11/2026 sera), domande di Claude:**
  - Le **passerelle sui torrenti**: **niente passerella sui torrenti larghi** (Fede, 26/11/2026: servirà il ponte nell'epoca dopo); restano sui corsi stretti e sul fradicio. Da fare il 27/11.
  - Le **case lungo le strade** compaiono solo quando il centro è già pieno: **si lascia così** (Fede, 26/11/2026: "è più organico").
  - I numeri (40 persone, 20 anni, +15%, 500 m, +3 di umore, +10% di taglio) e l'aspetto (5 m, terra più chiara con i solchi dei carri) sono proposte da guardare in prova.
  - **I sentieri li costruisce solo il giocatore** (Fede, 26/11/2026): niente sentieri spontanei.
- **Secondario, direzione artistica:** il maiale che sembra un facocero.
- **Famiglie "eminenti e comuni":** nome confermato da Fede il 26/11/2026.
- Carestie nei siti di caccia (25/11/2026 sera): chi legge passa da 1,3 a 2,4 carestie a partita, quasi tutte all'Area dei gessi e allo Sperone collinare. **Si lascia così** (Fede, 25/11/2026): nei siti che vivono di caccia le carestie sono normali.
- **Confermate da Fede** (25/11/2026): la posta si aggancia al margine del bosco entro 60 m; tasti K (capanno) e T (posta); 35 di cibo l'anno al massimo per edificio, posta fino a 1000 m, capanno fino a 600 m.
- **(?)** Popolazioni: con i campi che si stancano le mediane sono rientrate (chi conosce il genere 763), i massimi restano a 1000–1080; il casual resta piccolo (mediana 103): **si lascia così per ora** (Fede, 25/11/2026).
- Carestie per chi impara sbagliando: 2,6 a partita, dentro l'obiettivo 1–3 (25/11/2026 sera); chi legge 1,3 (poco sopra 0–1).
- Politica "Caccia regolata": **non si fa per ora** (Fede, 25/11/2026): con la Posta di caccia e la selvaggina locale il giocatore regola già la caccia; si riprende solo se le prove mostrano ancora troppa caccia.
- **Orti più piccoli:** decisi (Fede, 25/11/2026) **solo come aspetto, nella fase grafica**: il quadrato da 40 m resta l'unità della simulazione, ma si disegna diviso in 2–4 appezzamenti con colture e colori diversi.
- Come contare gli abitanti sul territorio (idee 1 e 2 di `sessioni-giocatori.md`): **per ora va bene così** (Fede, 26/11/2026); seguiranno verifiche e conferme.
- Dimensioni degli edifici delle risorse (legnaia, capanno e posta piccoli accanto alle case lunghe): **vanno bene così** (Fede, 26/11/2026).
- Prova fisica di Fede: al termine del villaggio (decisione del 25/11/2026), quando le voci sopra sono fatte e validate dalle prove di Claude.

## Fatto
- **24/11/2026 e prima:** fondazione con lettura del sito, rovine e rifondazione; zona agricola e campo a mano; contado che cresce; sentieri con anteprima; granaio; politiche (raccolto, stranieri, fonti di cibo); ammodernamento (spento nel villaggio); economia mista; piene, siccità, presagi; abitato spontaneo, demolizione; notifiche discrete; sessioni automatiche a dieci livelli.
- **25/11/2026** (dettagli in `diario.md`, `era-origini.md`, `prototipo0-godot.md`, `sessioni-giocatori.md`):
  - Era delle Origini definita (cronologia, nomenclatura "genti" più il luogo, modulo delle due epoche, eventi soglia).
  - Ritmo: si ferma solo per le scelte che chiedono un intervento, il resto in cronaca; velocità 1 a un anno al secondo; affollamento come politica.
  - Abbondanza (cibo che avanza, salute, spazio) con nascite in ritardo; tappe permanenti (60, 100, 150, 250).
  - Consenso di anziani e famiglie con effetti graduali.
  - Legna: legnaia obbligatoria, taglio visibile, **zona di taglio** che resta aperta finché la legnaia lavora, ceduo, "Lasciar ricrescere".
  - Carestie B + C; piene che fertilizzano (limo); febbri; **campi che si stancano**; casali dalla tappa dei 250.
  - HUD: indicatori Abbondanza, Consenso, Legna; tappa accanto all'anno; pannelli di focus; lettura del terreno per ogni strumento.
  - Giocatori automatici "umani" a quattro profili; registro degli avvisi.
  - Icone di legnaia, capanno da pesca, posta di caccia e pascolo; modelli di legnaia, capanno da pesca e posta di caccia, posati nel gioco dove starebbero (riva e margine del bosco).
  - Decisioni sugli edifici delle risorse: capanno solo sulla riva con aggancio automatico, nessuna distanza minima tra capanni né tra legnaie (tolta dal codice quella di 150 m tra legnaie), pesce locale per tratto di riva.
  - Sera tardi: **capanno da pesca e posta di caccia** nel gioco (simulazione, strumenti, modelli, lettura, prove).

## Epoche future, sulla carta (in parallelo, 26/11/2026)
Solo documenti, senza toccare codice o modelli (richiesta di Fede).
- [x] Sistemi che attraversano le epoche, identità e regime, proprietà, vita delle costruzioni, dinamica calda, sottosuolo: `epoche-future.md` (approvato da Fede il 26/11/2026).
- [x] Catalogo degli edifici per categoria di gioco, con scopo, epoche e cosa muove: `edifici-per-epoca.md` (**per ora va bene**, Fede 26/11/2026; la realizzazione dei modelli si decide dopo).
- [ ] Età industriale sulla carta, con la profondità di `era-origini.md`.
- [x] Prime due Ere riviste con lo schema (26/11/2026, ok di Fede): `era-origini.md` (§ 4 "Lo schema nel villaggio", § 5 primo governo, § 6 zone e concessione) e nuovo `era-antichita.md`.
- [x] Specchietto riassuntivo: `specchietto.md`.
- [x] Nomi delle forme di governo (epoche 2–4): **decisi** da Fede il 26/11/2026, con Consiglio dei clan (al posto di "lignaggi") e Consiglio delle grandi famiglie (al posto di "maggiorenti"), termini cambiati in tutti i documenti.
- [ ] Da raffinare: salute e scarti, bilancio della città. Da ragionare: stratificazione in altezza.

## Per l'abitato protourbano (dopo il villaggio)
**Avviato il 27/11/2026** (Fede: "prossima è abitato protourbano"). Proposte in `epoca2-proposte.md`; indicazioni di Fede: zoning per l'abitato, recinto contro le scorrerie, fabbro per cibo e difesa, **il fabbro è il primo edificio che si sblocca con la nuova epoca**.
- [x] Proposte: evoluzioni del gioco, sinergie, funzioni degli edifici, scheda del fabbro (§ 1, 1b, 2, 2b).
- [x] Modelli, primo lotto: case su impalcato (piccola, media), casa del capo, tratto di recinto, porta, officina del fabbro con il cantiere; vesti dell'epoca 2 con i bronzi.
- [x] Fede conferma le proposte del § 1, § 2 e § 2b: **approvate tutte** (27/11, 11:15; correzioni quando ci si arriva).
- [x] Fabbro rifatto (27/11, richiesta di Fede: legno, pietra, fornace riconoscibile, incudine visibile) e **fumo animato** dei camini (decisioni di Fede: non legato alla simulazione, solo officine ed edifici comunitari). Da guardare con Fede: le foto e la GIF.
- [x] Modelli, secondo lotto (27/11): santuario, tumulo, granaio comune, pozzo, recinto del bestiame, ponte, varianti `_b` delle case pensate per la fila sulla via, cantieri di case, casa del capo, recinto, santuario, granaio comune, pozzo e ponte. Da guardare con Fede.
- **Deciso** (Fede, 27/11): con l'abitato le strade contano di più e **le case si sviluppano sulla via** (`epoca2-proposte.md` § 1, voce 12): da fare nella simulazione con recinto e zone.
- **Deciso** (Fede, 27/11): fumano l'officina, il santuario (fuoco dell'altare) e la casa del capo (dal colmo, più rado). Il granaio comune no. GIF del fumo approvata.
- [x] Simulazione dell'epoca 2, **il fabbro** (27/11): l'epoca 2 comincia dopo l'evento del metallo e dura fino al 700 a.C.; officina (M), metallo, carbone, scheda attrezzi/armi/metà, effetti su cibo, legna e scorrerie, incendio vicino alle case, prestigio della famiglia del fabbro, tutorial, conseguenze, lettura, vesti dell'epoca 2, giocatori automatici, verifiche. Regole in `prototipo0-godot.md`. Da provare con Fede (finestra F3).
- [x] **Recinto e porte, zone dell'abitato con le case sulla via** (27/11, pomeriggio; proposta approvata da Fede: "ok, perfetto", fatti i passi A e B di fila). Regole in `prototipo0-godot.md`. Da provare con Fede (finestra F3).
- [x] **La legnaia non tappa la legna** (27/11, pomeriggio tardi; Fede: "non posso stare solo a costruire legnaie", poi "vai"): legnaia fonte professionale (80 alberi l'anno, +150 di catasta); quando non basta le famiglie si prendono la legna da sole con il doppio della fatica, tolta ai campi. 72 partite brevi fatte. **Fatte la sera** le 12 partite fino al 700 a.C. (circa 32 minuti): carestie da 21 a 32,5 (`sessioni-giocatori.md`). Resta la prova di Fede.
- [x] **Famiglie eminenti e comuni** (27/11, sera; proposta di Claude approvata da Fede: "ok"): divisione dal prestigio concentrato, eminenti al più 1 su 6, umore che pesa 3 volte (2 Comunità, 4 Casa dominante), cosa vogliono i due gruppi, comuni scontente al recinto a metà; rango e clan nella scheda della famiglia, casa eminente più grande. Nomi decisi da Fede: eminenti, comuni, sacerdote; clan = casata futura, per ora solo racconto. Regole in `prototipo0-godot.md`. Da provare con Fede (finestra F3). **Resta (?):** la divisione scatta quasi sempre all'inizio dell'epoca 2 (prestigio dei fondatori accumulato in 3000 anni): Fede sceglie la correzione (memoria corta del prestigio, prestigio dall'epoca 2, soglia più alta), poi si rifanno le 12 partite lunghe.
- [~] **Carestie nelle partite lunghe**: con la legna nuova e la soglia della carestia al 15% (27/11 sera) le brevi sono scese a 1,4–2,4 a partita; **rifare le 12 partite lunghe** (`giocatore_umano.gd -- /tmp/umano_e2.txt 1 epoca2 legge,genere`, circa 30 minuti) per vedere le lunghe (con la soglia vecchia erano 35).
- [ ] Simulazione dell'epoca 2, il resto, voce per voce: concessione dei lotti (casa del capo, tumulo), governo che conta e pannello dell'identità, capo di guerra, scambio al guado, campi a strisce dell'aratro, crollo, suolo che sale, ponte e approdo, eventi d'epoca, funzioni nuove degli edifici del villaggio.
- Recinto o palizzata, con terrapieno e fossato: la regolazione dello spazio della seconda epoca (decisioni di Fede del 24 e 25/11/2026).
- Gruppi eminenti, comuni, sacerdote (27/11); famiglie eminenti e comuni che nascono dalla disuguaglianza creata dal giocatore, con attenzione agli equilibri di potere (`era-origini.md` § 6).
- Decisi e scartati: prologo nomade **bocciato** (25/11/2026); inizio al 6000 a.C. (i primi quattro secoli per mettere le pedine).
