# Diario di bordo

Voci più recenti in cima.

## 27/11/2026 (pomeriggio) — la legna rifatta
**Fatto** (decisioni di Fede, 12:28–12:49)
- **Alberi che valgono il doppio:** quercia 4 m³, pioppo 3, carpino 2, arbusto 0,3.
- **Limite della legnaia in alberi:** fino a 20 alberi l'anno del valore medio del bosco attorno (circa 56 m³ in un bosco medio, prima 30).
- **Carbone dagli scarti:** il fabbro usa il 5% della legna tagliata (2 a pieno lavoro); non pesa sulla scorta né sul consumo; senza legnaie al lavoro si ferma.
- **Il fuoco:** quando la legna morta non basta ai focolari, i boscaioli abbattono alberi anche per ardere (prima i tronchi servivano solo alle case: era la causa della scorta sempre a zero).
- **Prove:** 72 partite dei primi cinque secoli quasi come prima (carestie un poco più alte); 12 partite fino al 700 a.C.: l'officina la fanno tutti (prima 1 su 12). Numeri in `sessioni-giocatori.md`. 12 verifiche superate.

**Decisioni** (Fede)
- "Diamo più valore al singolo albero tagliato"; limite in alberi "ok"; carbone "legato al legno, dagli scarti"; abbattere per il fuoco "accordato". La legnaia "pare buggata": i problemi erano quelli del bilancio della legna.

**Prossimo passo**
- Fede prova al PC: la legna nei villaggi grandi, Prova › Metallo, l'officina (M).
- Da guardare: carestie un poco più alte nelle partite lunghe; i giocatori automatici fermi a 4 legnaie.
- Poi il resto dell'epoca 2: recinto e porta, zone con le case sulla via.

## 27/11/2026 (mezzogiorno) — fabbro giocabile, scorrerie più rade, il tema della legna
**Fatto**
- **Scorrerie diradate a decenni:** almeno 250 anni fra una e l'altra, probabilità al 40%. Nelle 12 partite lunghe da 2–20 a 1–7 in 3000 anni (media da 9 a 4,3); registro degli avvisi 3,4 pause.
- **Epoca 2 giocabile in parte, con l'officina del fabbro:**
  - dopo l'evento del metallo la partita continua a decenni fino al 700 a.C.;
  - officina (Edifici, M): metallo (0,4 l'anno da isolati, 1,2 da aperti), carbone, una famiglia tolta ai campi, scheda Attrezzi / Armi / Metà e metà; effetti su campi, caccia, pesca, legnaie e scorrerie; incendio vicino alle case; prestigio della famiglia del fabbro;
  - tutorial, conseguenze, lettura del terreno, modello con il fumo, vesti dell'epoca 2;
  - giocatori automatici che la usano (`giocatore_umano.gd ... epoca2`); verifiche nuove in `verifica_villaggio.gd`; due caselle nuove nella finestra F3. Foto `docs/immagini/fabbro-nel-gioco-27-11.jpg`.
- **Dalle prove automatiche:** nell'epoca 2 la scorta di legna dei villaggi grandi resta a zero (i focolari bruciano più del taglio), e quasi nessuno riusciva a costruire l'officina. Correzione: il carbone viene dal taglio dell'anno, l'officina si paga anche con la legna tagliata nell'anno. La rifatta delle 12 partite è stata fermata per la domanda di Fede sulla legna (sotto).
- 12 verifiche superate.

**Decisioni** (Fede, 27/11, 11:15)
- Scheda del fabbro (§ 2b), evoluzioni (§ 1) e funzioni degli edifici (§ 2) di `epoca2-proposte.md`: **approvate tutte**.
- Scorrerie: **diradate a decenni**.
- Prossima Era sulla carta: **per ora nessuna**.
- 12:28: "il tema del legno rimane importante"; **dare più valore al singolo albero tagliato**. Claude ha spiegato come si calcola oggi e ha proposto come cambiarlo: in attesa dell'ok.

**Prossimo passo**
- Il valore dell'albero (proposta in conversazione), poi di nuovo le 12 partite fino al 700 a.C.
- Prova di Fede al PC: Prova › Metallo, poi l'officina (M), la sua scheda e il fumo.

## 27/11/2026 (mattina, 5) — fumo della casa del capo, foto della via
**Fatto**
- **Fumo della casa del capo:** nasce sotto il colmo, tra le corna (le capanne non avevano camino), più rado e piccolo di quello della fornace. `camini.json` accetta densità e scala; `VistaFumo` le applica. Foto `docs/immagini/fumo-casa-del-capo-27-11.jpg`.
- **Foto della via rifatta** con un nastro di terra continuo. Le "traversine" viste da Fede erano gli scalini fra i pezzi della via provvisoria della foto; nel gioco le strade non le hanno.
- `verifica_asset.gd`: fumano officina, santuario e casa del capo, e la casa del capo fuma meno della fornace. 12 verifiche superate.

**Decisioni** (Fede, 27/11, 11:06–11:07)
- Altare e santuario: **perfetti**. GIF del fumo: **perfetta così**.
- Fuma anche la **casa del capo**, come proposto (dal colmo, più rado). Il granaio comune no.

**Prossimo passo**
- Fede conferma le proposte dell'epoca 2 (§ 1, § 2, § 2b di `epoca2-proposte.md`).
- Poi la simulazione dell'epoca 2, cominciando dal fabbro.
- In attesa: la prova al PC (F3) e la lettura del Registro; il bilanciamento delle scorrerie; la prossima Era sulla carta.

## 27/11/2026 (mattina, 4) — fabbro rifatto, fumo dei camini, secondo lotto dell'epoca 2
**Fatto**
- **Officina del fabbro rifatta** (Fede: "così è un po' anonimo"; legno e pietra; la fornace non si distingue, l'incudine non si vede):
  - fonditore dell'età del Bronzo: banco di tavole con stampi di pietra, crogioli e panelle; rastrelliera con asce, punte di lancia e una spada di bronzo;
  - pali grossi su zoccoli di sassi, metà muretto a secco sul retro;
  - fornace a cupola sul piede di pietre, annerita in alto, camino con la fuliggine, bocca accesa rientrata con le braci;
  - incudine di pietra chiara fuori dalla tettoia, nello spiazzo di terra battuta;
  - fronte sulla via; cantiere rifatto. Foto `fabbro-rifatto-27-11.jpg`, `fabbro-rifatto-retro-27-11.jpg`, `fabbro-cantiere-27-11.jpg`.
- **Fumo animato dei camini:**
  - `VistaFumo` (una MultiMesh per tutti i camini, 12 sbuffi l'uno) e `shader/fumo.gdshader` (sbuffi rivolti alla camera che salgono, si allargano, piegano col vento e sfumano, contorno di rumore);
  - i punti dei camini in `camini.json`, scritti da `protourbano.py`; la vista lo aggiunge agli edifici finiti;
  - GIF di 9 secondi: `docs/immagini/fumo-fabbro-27-11.gif` (fotogrammi da `test/foto_fumo.gd`).
- **Secondo lotto di modelli:** santuario (con il fuoco dell'altare che fuma), tumulo, granaio comune, pozzo, recinto del bestiame, ponte; varianti `_b` delle case su impalcato pensate per la fila sulla via; cantieri di case, casa del capo, recinto, santuario, granaio comune, pozzo e ponte. Foto `protourbano-lotto2-27-11.jpg` e `case-sulla-via-27-11.jpg` (modi `lotto2` e `via` di `foto_cantieri.gd`).
- `verifica_asset.gd` legge anche i modelli dell'epoca 2 e controlla il fumo; 12 verifiche superate. Niente partite "umane": le dinamiche non cambiano.

**Decisioni** (Fede, 27/11)
- Con il protourbano le strade diventano più importanti e **le case si sviluppano sulla via** (`epoca2-proposte.md` § 1, voce 12; la parte di simulazione arriva con recinto e zone).
- **Fumo:** non legato alla simulazione; per ora solo le officine e gli edifici comunitari, non le case ("altrimenti diventa una coltre di fumo, ben prima dell'epoca industriale").
- "Procedi come suggerisci": prima il fabbro, poi il fumo, poi il secondo lotto.
- Da decidere: quali altri edifici comunitari fumano (proposta di Claude: il santuario sì; la casa del capo, il luogo sacro del villaggio e il granaio comune da vedere).

**Prossimo passo**
- Fede guarda le foto, la GIF e le proposte dell'epoca 2 (§ 1, § 2, § 2b).
- Poi la simulazione dell'epoca 2, cominciando dal fabbro.
- Resta in attesa: la prova di Fede al PC (F3) e le scorrerie da provare in gioco.

## 27/11/2026 (mattina, 3) — si comincia l'abitato protourbano
**Fatto**
- **Proposte per l'epoca 2** in `docs/epoca2-proposte.md`:
  - 14 evoluzioni del gioco dal villaggio all'abitato (§ 1);
  - le sinergie fra zoning, recinto, fabbro e scambio, con cinque cerchi che si chiudono (§ 1b);
  - cosa cambia per ogni edificio del villaggio (§ 2);
  - la scheda dell'officina del fabbro come edificio (§ 2b);
  - modelli e ordine di lavoro (§ 3–4).
- **Modelli** (`strumenti/blender/protourbano.py`, `gioco/asset/protourbano/`):
  - case su impalcato piccola e media, casa del capo, tratto di recinto, porta;
  - officina del fabbro e il suo cantiere. L'officina è stata rifatta a una falda, aperta davanti e con il forno fuori dalla paglia, perché dall'alto si leggessero forno e incudine.
  - Texture nuove: intonaco e terra.
- **Vesti dell'epoca 2** (`persone.py`, `PERSONE_2`, `persona_*_e2`):
  - tunica al ginocchio, veste alla caviglia, fasce, berretto;
  - bronzi: placche, fibule, bracciali, collane.
  - Lo shader delle persone ha `epoca`, con la tavolozza di robbia, reseda e guado e il bronzo lucido.
- **Foto:** `test/foto_cantieri.gd` (modi `protourbano` e `fabbro`), `test/foto_persone.gd` (modo `e2`); immagini in `docs/immagini/*-27-11.jpg`.
- 12 verifiche superate.

**Decisioni** (Fede, 27/11)
- L'abitato si gestisce con lo zoning; il recinto protegge dalle scorrerie; il fabbro rende più efficienti la raccolta del cibo e la difesa; controllare che tutto sia sinergico.
- Il fabbro va inserito come edificio ed è il **primo edificio che si sblocca con la nuova epoca**.
- Il resto delle proposte (§ 1, § 2, § 2b) aspetta la conferma di Fede.

**Prossimo passo**
- Fede guarda le proposte e le foto.
- Poi il secondo lotto di modelli e la simulazione dell'epoca 2, cominciando dal fabbro.
- Resta in attesa: la prova di Fede al PC (F3, 17 caselle) e le scorrerie da provare in gioco.

## 27/11/2026 (mattina, 2) — presagi, primo governo, passerelle
**Fatto** (decisioni di Fede del 26/11 sera)
- **Presagi** ("allenta i presagi, aumentali col sacerdote scontento"):
  - nei primi secoli come prima;
  - a decenni almeno 400 anni fra l'uno e l'altro (uno ogni 6–7 secoli);
  - con il sacerdote scontento l'attesa si dimezza e la probabilità raddoppia, sempre. I testi del sacerdote lo dicono.
  - Nelle partite lunghe le pause scendono da circa 20 a 11.
- **Primo governo** ("ok da fare"): soglie rifatte sulla tabella di `era-origini.md`:
  - raccolto in comune, poca disuguaglianza, anziani contenti → Comunità;
  - raccolto alle famiglie e mandrie grandi delle famiglie → Casa dominante;
  - il resto → Consiglio dei clan.
  - Nelle partite di prova escono tutte e tre (6, 4, 2).
- **Passerelle:** niente sui torrenti larghi (oltre 14 m d'acqua). Lì la strada si ferma al guado; servirà il ponte nell'epoca dopo.
- **Prove:**
  - 12 verifiche superate;
  - 72 partite "umane" sui primi cinque secoli (come prima);
  - 24 + 12 partite lunghe;
  - registro degli avvisi: 3,6 pause.
  - Risultati in `sessioni-giocatori.md`.

**Decisioni**
- Fede: "passa al prossimo". Le case lungo la via restano come sono; i sentieri li fa solo il giocatore.
- Da guardare con Fede: le scorrerie nelle partite lunghe (in media 9 in 3000 anni, fino a 20).

**Prossimo passo**
- La prova di Fede al PC (finestra F3, 17 caselle), poi la lettura del Registro.
- La prossima Era sulla carta: si sceglie con Fede.

## 27/11/2026 (mattina) — menù delle impostazioni (voce 10)
**Fatto**
- **Impostazioni** (proposta di Claude approvata da Fede il 26/11): F10 o Strumenti › Partita › Impostazioni.
  - Partita: tutorial, salvataggi automatici, tempo dopo la fondazione.
  - Grafica: qualità bassa, media o alta (alberi completi, figure, animali, ombre, bordi lisci), fotogrammi massimi, schermo intero, scala dell'interfaccia.
  - Registro tecnico acceso o spento; elenco dei comandi.
  - Ogni scelta si applica e si salva subito in `D:\Godot\Strati\impostazioni.cfg`. Foto: `docs/immagini/impostazioni-27-11.jpg`.
- Verifica nuova `verifica_impostazioni.gd` (la dodicesima); tutte superate. Nuova casella nella finestra F3.

**Decisioni**
- Fede: "vai procedi col primo punto della lista".

**Prossimo passo** (piano in testa al todo)
- Presagi più radi a decenni e più fitti con il sacerdote scontento.
- Soglie del primo governo.
- Passerelle solo sui corsi stretti.
- Prove con i giocatori "umani".

## 26/11/2026 (chiusura della sessione) — decisioni di Fede e piano per il 27/11
**Decisioni di Fede**
- **Menù delle impostazioni (voce 10):** proposta di Claude approvata così com'è:
  - Partita: tutorial, salvataggi automatici, velocità di partenza.
  - Grafica: qualità a tre livelli, fotogrammi massimi, schermo intero, scala dell'interfaccia.
  - Comandi da leggere e Registro acceso o spento.
  - Si apre con F10 o da Strumenti › Partita; le scelte vanno in `D:\Godot\Strati\impostazioni.cfg`.
- **Presagi:** più radi a decenni, più fitti con il sacerdote scontento.
- **Primo governo:** soglie da rifare, devono uscire tutte e tre le forme.
- **Strade:**
  - niente passerella sui torrenti larghi (servirà il ponte nell'epoca dopo);
  - le case lungo la via restano come sono ("è più organico");
  - i sentieri li costruisce solo il giocatore.
- **Scorrerie:** la mezza pausa in più va bene, con attenzione al bilanciamento.
- **Direzione artistica:** da verificare nella prova al PC.
- **Proposte di Claude:** numeri, testi e tasti tutti approvati.
- **Prossima Era sulla carta:** si decide domani. L'Età industriale era la prossima in `epoche-future.md` (progettare all'indietro da Haussmann); Fede nota che le epoche si stanno già ragionando in prospettiva futura.

**Prossimo passo (27/11, il piano è in testa al todo)**
- Claude:
  - menù delle impostazioni;
  - presagi più radi a decenni e più fitti con il sacerdote scontento;
  - soglie del governo;
  - passerelle solo sui corsi stretti;
  - prove con i giocatori "umani";
  - poi la lettura del Registro dopo la prova di Fede.
- Fede: prova al PC con le 16 caselle della finestra F3.

## 26/11/2026 (notte fonda) — evento soglia e passo elastico (voce 6), partita più lunga, prove in gioco
**Fatto**
- **La partita è più lunga** (Fede: "aumenta il periodo di tempo della demo"): non finisce più al 5500 a.C. ma con l'evento del metallo, tra il 3000 e il 1800 a.C.
- **Passo elastico:** dal 5600 a.C. (con la tappa Territorio, comunque dal 5200) ogni passo è un decennio, calcolato anno per anno e spalmato sui fotogrammi (al massimo 12 ms per fotogramma). Una scelta ferma il passo; notifiche uguali raccolte; scheda di tutorial "Il tempo a decenni".
- **Evento soglia 1:** tre presagi del metallo dal 3300 a.C.; dal 3000, con il territorio pieno, la scelta aprirsi o restare isolati (al 1800 comunque); primo governo dall'identità (Comunità, Consiglio dei clan, Casa dominante); arriva l'aratro; riepilogo del villaggio e fine del prototipo. Menù Prova › Metallo per vederlo subito.
- **Simulazione più veloce, stessi risultati:** da circa 60 a 22 ms per anno con mille campi (le partite delle verifiche danno gli stessi numeri di prima).
- **Finestra Debug (F3):** tutte le prove da fare alla prima prova al PC, 16 caselle (le vecchie più strade, figure sulla rete, varianti delle case, piena, salvataggio, automatici, decenni, metallo, fotogrammi a decenni).
- **Prove:** 11 verifiche superate (nuove su passo, presagi, evento, governi, Prova › Metallo, decenni nella partita). 18 partite lunghe di giocatori "umani": tutti arrivano al metallo, nessun abbandono (`sessioni-giocatori.md`).

**Decisioni**
- Fede: proposta della voce 6 approvata ("ok vai procedi"); prove in gioco aggiornate; demo più lunga.
- Da decidere con Fede (todo): presagi troppo fitti a decenni; soglie del primo governo (nessun Consiglio dei clan nelle prove).

**Prossimo passo**
- Prova di Fede al PC con la finestra F3 e il Registro (poi Claude legge il registro).
- Voce 10 (menù delle impostazioni), da progettare con Fede.

## 26/11/2026 (notte) — strade (voce 5), salvataggio, piene visibili e varianti delle case (voce 9)
**Fatto**
- **Sentieri che diventano strade** (voce 5; proposta di Claude approvata da Fede: "mi convincono le proposte"):
  - Ogni anno chi lavora lontano va dal centro al suo posto lungo la rete dei sentieri. Il traffico viene da campi, pascolo, legnaie, poste e capanni, luogo sacro e casali.
  - Un tratto con almeno 40 persone l'anno per 20 anni di fila diventa strada, dalla tappa dei 250. La strada resta; si toglie solo con Demolisci.
  - Aspetto: nastro di 5 m di terra compatta con i solchi dei carri; passerelle di tronchi (modello nuovo `passerella`) sui torrenti e sul fradicio.
  - Effetti: campi vicini +15%; case nuove anche lungo la via; casale collegato +3 di umore; legnaia su una strada +10% di taglio.
  - Le figure che vanno lontano camminano su sentieri e strade.
  - Con Sentiero, la lettura del tratto dice "Traffico: N persone l'anno · strada tra K anni". C'è la scheda di tutorial "Strade".
  - Foto: `docs/immagini/strade-26-11.jpg`, `passerella-26-11.jpg`.
- **Più veloce:** la fascia dei campi serviti da sentieri e strade si ricalcola solo quando cambiano. Prima una partita con le strade richiedeva 33 s invece di 18.
- **Salvataggio** (voce 9; Fede: "passa subito al punto successivo", proposte di Claude inviate e segnate come tali):
  - F5 salva; F8 apre l'elenco delle partite salvate. Gli stessi comandi stanno in Strumenti › Partita; le schede degli Strumenti vanno a capo.
  - Salvataggi automatici a ogni tappa e ogni 50 anni, ultimi 3.
  - File in `D:\Godot\Strati\Salvataggi`.
  - Si salvano tutta la simulazione (anche il caso), l'uso del suolo e le zone bloccate. Caricando si torna esattamente allo stato salvato, e rigiocando si arriva allo stesso punto (`test/verifica_salvataggio.gd`, l'undicesima verifica).
- **Varianti delle case** (voce 9): una seconda versione per ogni tipo di casa, con gli annessi:
  - cataste e orto recintato;
  - tettoia staccata dal fianco;
  - recintino per gli animali piccoli;
  - telaio con una pelle tesa.
  Metà dei lotti ha la variante. Foto: `docs/immagini/varianti-case-26-11.jpg`.
- **Acqua che sale con le piene:** l'acqua torbida copre le terre basse in 3 s, resta 5 s e si ritira in 7 s. Una piena di stagione copre i bordi dei corsi, una disastrosa quasi tutta la piana. Foto: `docs/immagini/piena-*-26-11.jpg`.
- **Prove:** tutte le 11 verifiche superate.
  - Giocatori "umani": mediane 744, 799, 853 e 136 abitanti; pause invariate.
  - Registro degli avvisi: 3,6 pause vere a partita.
  - Tutto in `sessioni-giocatori.md`.

**Decisioni**
- Fede: proposte della voce 5 approvate. Domande annotate nel todo, poi si passa subito al punto successivo (voce 9).
- Proposte di Claude in attesa (todo, "Da decidere con Fede"):
  - passerelle sui torrenti larghi (sembrano ponti);
  - case lungo le strade poco evidenti;
  - sentieri battuti spontaneamente;
  - numeri e aspetto delle strade;
  - cartella, tasti e automatici del salvataggio;
  - colore e tempi della piena;
  - varianti delle case.

**Prossimo passo**
- Voce 9: restano solo le prove sui PC di Fede con il Registro (F3, nuove caselle per strade, salvataggio e piena).
- Poi voce 6 (evento soglia e passo elastico) e voce 10 (menù delle impostazioni).

## 26/11/2026 (sera tardi) — prova di Fede, registro letto, legna rifatta e correzioni (voce C)
**Fatto**
- **Prima lettura del registro tecnico**, dalla cartella del PC di Fede (`sessione-2026-11-26-184529`, GTX 1050, 1600×900):
  - quasi sempre 60 fps, minimo 33 a 40 m con 149 figure;
  - scena pronta in 6,5 s, nessun errore;
  - scatti di 130–150 ms alla prima scelta di uno strumento.
  Le annotazioni di Fede e la diagnosi stanno nel todo, voce C.
- **Legna rifatta** sul concetto di Fede:
  - ogni albero ha un valore (quercia 2 m³, pioppo 1,5, carpino 1, arbusto 0,2, con la grandezza);
  - la legnaia parte dagli alberi attorno e li abbatte uno alla volta, poi passa ai successivi; la zona tagliata non ricresce finché è di passaggio;
  - la legna da ardere si raccoglie senza abbattere (3 m³ per ettaro l'anno; i focolari ne bruciano 0,5 a testa);
  - i tronchi servono a rifare le case (20 m³, durano 30 anni) e a costruire: granaio 15, luogo sacro 10, torre 8, capanno e posta 5, la legnaia gratis;
  - la catasta è piccola, due anni di consumo più 60;
  - gli alberi spariscono dalla mappa uno alla volta durante l'anno.
  Nelle partite automatiche il fronte del taglio avanza di qualche decina di metri ogni decennio, invece di spazzare tutto entro 600 m.
- **Interfaccia:**
  - il cerchio della legnaia si vede solo con Legnaia, Demolisci, la mappa 6 o la scheda aperta;
  - la scheda della legnaia ha i tasti Al lavoro e A riposo;
  - strumenti e politiche compaiono con la loro tappa (niente più "si apre a…");
  - i tasti stanno tra parentesi nei testi;
  - il lotto sotto il puntatore è bianco, rosso solo dove lo strumento non può costruire;
  - la striscia dell'anno ha la larghezza fissa e le righe della fascia sono fisse;
  - cursori veri: freccia, selezione con il quadratino, mirino; cornice di selezione su case, persone e legnaie.
- **Gioco:** gli stranieri arrivano dalla tappa dei 150. Legnaia, capanno e posta si disegnano 1,8 volte più grandi, il granaio 1,4. Nel menù Prova c'è il tasto "Segni di scorreria". I modelli si caricano all'avvio.
- Prove: verifiche nuove in `verifica_villaggio.gd` (alberi, taglio progressivo, fronte, zona di passaggio, catasta) e in `verifica_partita.gd` (cose che compaiono, scheda della legnaia, cerchio, selezione, cursori, puntatore, edifici, scorreria di prova); tutte le 10 verifiche superate. Partite "umane" e registro degli avvisi in `sessioni-giocatori.md`. Prove della finestra Debug aggiornate.

**Decisioni** (Fede)
- Il concetto della legna: un albero ha un suo valore, verosimile col periodo. Si parte dai 3–4 alberi attorno alla legnaia e poi si passa ai successivi. Il primo non ricresce finché la zona è di passaggio. La velocità di taglio è quella di Age of Empires.
- "Il resto va bene": cerchio, scheda della legnaia, cose che compaiono, tasti tra parentesi, puntatore, HUD fermo, cursore di selezione, stranieri dalla loro tappa, edifici più grandi (1,8 e 1,4), scorreria di prova. In più "un cursore vero e proprio per il puntatore".
- La divisione della legna (da ardere senza abbattere, tronchi abbattendo) e i suoi numeri: confermati da Fede la sera stessa ("se in prova non convincono, si cambiano").

**Prossimo passo**
- Fede: Pull e prova al PC, con le caselle della finestra Debug (F3) e i segnalibri (F9). Poi dire a Claude di leggere il registro.
- Claude: voce 5, sentieri che diventano strade (prima il riepilogo).
- Nota per la prova: a un anno al secondo un villaggio di 200 abitanti taglia una decina di celle di alberi l'anno; si vedono sparire una alla volta, ma sono comunque una decina al secondo.

## 26/11/2026 (sera) — scorrerie e torre di avvistamento (voce 4)
**Fatto**
- **Scorrerie** nella simulazione (`sim_villaggio.gd`, generatore a parte `rng_scorrerie`). Partono dalla tappa dei 100 abitanti e sono più rare prima del 4300 a.C. Il rischio è ricchezza visibile × esposizione × (1 − difesa): la ricchezza sono animali e scorte; l'esposizione sono casali, pascoli oltre 300 m e margini del contado vuoti; la difesa sono il sito e l'abitato raccolto. Prima arrivano i segni (fuochi, tracce, fuggiaschi), con la direzione e un punto sulla mappa, e la scorreria arriva 1–2 anni dopo. Si perdono animali e scorte e a volte bruciano 1–2 case ai margini, che lasciano macerie e rovine. Gli anziani perdono consenso, l'umore delle famiglie vicine cala per 15 anni e la memoria della paura stringe l'abitato: le case nuove nascono più vicine e possono toccarsi in diagonale.
- **Politica "Ai segni di pericolo"** (andare avanti, raccogliere, vegliare): si apre ai primi segni, che fermano il gioco una volta con le schede di tutorial "Scorrerie" e "Torre di avvistamento" e con la scelta, che diventa la regola.
- **Torre di avvistamento** (Edifici, tasto U): 15 di legna e 2 anni di cantiere, una sola, su un'altura entro 1200 m. Dà i segni un anno prima e le perdite scendono al 70%. Ci sono il modello e il suo scheletro in `villaggio.py` (che ora esporta anche solo i modelli indicati), l'icona, le Conseguenze, la lettura sotto il puntatore e la demolizione. Foto `docs/immagini/torre-avvistamento-26-11.jpg`.
- Il rischio, i segni e l'ultima scorreria compaiono nei pannelli degli Animali e del Consenso. I giocatori automatici rispondono alla scelta e provano la torre. C'è una nuova prova nella finestra Debug.
- Prove: 24 verifiche nuove in `verifica_villaggio.gd` e 2 in `verifica_hud.gd`; tutte le 10 verifiche superate. Con le 72 partite "umane" si ha circa una scorreria per partita nei villaggi avviati e 0,4 per il casual. Le carestie salgono un poco e le pause di circa mezza a partita (`sessioni-giocatori.md`). Il registro degli avvisi è invariato.
- Documenti: `prototipo0-godot.md`, `era-origini.md`, `edifici-per-epoca.md`, `hud.md`, `asset.md`, `specchietto.md`, `CLAUDE.md`, `todo.md`.

**Decisioni** (Fede)
- Riepilogo della voce 4 approvato ("perfetto tutto"): scorrerie dalla tappa dei 100 abitanti, più rare prima del 4300 a.C.; torre di avvistamento subito; politica "Ai segni di pericolo" con tre opzioni.
- Niente torre dove non c'è un'altura (Pianura aperta, Dosso nelle paludi): va bene così.

**Prossimo passo**
- Fede: prova in gioco al PC (Pull, F3 e F9 per il registro); dire se la mezza pausa in più per i segni va bene.
- Claude: voce 5, sentieri che diventano strade (prima il riepilogo).

## 26/11/2026 (sera, ripresa) — registro tecnico in gioco (voce B)
**Fatto**
- **Registro tecnico** (`gioco/script/registro.gd`, classe `Registro`): il gioco scrive da solo un file di testo per sessione in `D:\Godot\Strati\Registro`, con ripiego su `user://registro/` dichiarato nella prima riga. Si tengono le ultime 10 sessioni. In testa ci sono commit, Godot, sistema, scheda video e driver, renderer e risoluzione. Ogni 10 s una riga di numeri: fotogrammi al secondo medi e minimo, fotogramma più lento, disegni, memoria, zoom, anno, alberi, animali, figure. In mezzo gli eventi: caricamenti, fotogrammi sopra 100 ms con cosa stava succedendo, errori e avvisi di Godot, spunte, segnalibri. Parte solo nel gioco vero, non nelle verifiche e nelle foto. La cartella `Registro/` è nel `.gitignore`.
- **F3, finestra Debug** in alto a destra, nello stile dell'HUD: numeri dal vivo e le otto prove aperte come interruttori a quadratino; ogni spunta va nel registro con l'ora. **F9, segnalibro:** ora, camera e foto dello schermo accanto al registro. Foto `docs/immagini/registro-debug-26-11.jpg`, script `test/foto_registro.gd`.
- `Partita.seme` ricorda il seme della partita, per poterla rifare.
- Nuova verifica `test/verifica_registro.gd`, la decima (l'elenco in `CLAUDE.md`). Corretto un controllo instabile di `verifica_partita.gd`, il prestigio delle famiglie: chiedeva che almeno metà delle case avesse il prestigio e falliva in circa una partita su tre, a seconda del seme, anche senza le modifiche di oggi. Ora controlla che ce l'abbiano tutte le case nate prima dell'ultimo anno. Tutte le 10 verifiche superate. Le dinamiche non cambiano, quindi niente partite "umane".
- Documenti: `CLAUDE.md` (base del gioco, verifiche), `hud.md` (tasti F3 e F9, finestra Debug), `todo.md` (voce B fatta).

**Decisioni** (Fede)
- Registro scritto ora con il riepilogo così com'era ("Scrivi il registro ora"). La lettura dal PC si fa quando Fede è al PC e lo segnala (oggi era da app, con il PC spento).

**Prossimo passo**
- Fede, al PC: Pull, avviare il gioco (la cartella si crea da sola), giocare con F3 aperta quando serve, F9 dove c'è qualcosa; poi dire a Claude che è al PC.
- Claude: allora chiedere l'accesso a `D:\Godot\Strati\Registro` con l'app desktop e leggere il registro. Intanto voce 4, scorrerie (prima il riepilogo).

## 26/11/2026 (chiusura della giornata) — todo riordinato, registro tecnico sulla carta
**Fatto**
- Todo aggiornato: ordine delle voci (B, 4, 5, 9, 6, 10, prova fisica), prove aperte di Fede, proposte di Claude in attesa di uno sguardo, voce 7 chiusa.
- Voce B, **registro tecnico in gioco**, descritta nel todo (nessun codice).

**Decisioni** (Fede)
- Nelle prove Fede si sofferma sulla **direzione artistica**; le questioni tecniche le raccoglie un registro interno che il gioco salva da solo e che legge Claude.
- Il registro si salva in **`D:\Godot\Strati\Registro`**; Claude chiede l'accesso a quella cartella con l'app desktop collegata per leggerlo.
- Nel registro anche una **piccola finestra Debug in gioco** con le prove da verificare (le spunte finiscono nel registro).
- Il registro **si tiene per dopo** (stima: 40–60 minuti con la finestra Debug).
- Le famiglie dell'epoca 2 si chiamano **eminenti e comuni** ("comuni va benissimo").

**Prossimo passo**
- Fede: prove in gioco sulla direzione artistica (persone, animazioni, scheda della famiglia, maiale).
- Claude: alla ripresa, chiedere a Fede se fare prima il registro tecnico (B) o le scorrerie (4); prima del codice, il riepilogo.

## 26/11/2026 (sera, chiusura) — umore e prestigio delle famiglie
**Fatto**
- **Umore di ogni famiglia** in sola lettura (`SimVillaggio.umore_famiglie`): il consenso delle famiglie più uno scarto dalla situazione della casa (piena disastrosa ricordata per 20 anni, zona delle piene, legna lontana, campi stanchi vicini, casale senza sentiero; vicinanza al focolare e al luogo sacro). Gli scarti si bilanciano: la media resta il consenso del gruppo, l'equilibrio del villaggio non cambia. Nella scheda della famiglia la barra e la parola sono quelle della famiglia, con i motivi a parole al passaggio del puntatore.
- **Prestigio nascosto** di ogni famiglia (`SimVillaggio.prestigio_case`), che cresce ogni anno con la vicinanza al focolare e al luogo sacro e, con il raccolto alle famiglie, con gli animali: per dividere le famiglie nell'epoca 2.
- Decisione scritta in `era-origini.md` § 6 e nello specchietto. Verifiche nuove in `verifica_partita.gd` (la media degli umori è il consenso, il prestigio si registra e non è uguale per tutte). Tutte le 9 verifiche superate; dinamiche invariate (stessi numeri della verifica di prima), quindi niente partite "umane".

**Decisioni** (Fede)
- Umore per famiglia: solo lettura nel villaggio ("in epoca 1 è ancora tutto in fase di definizione"). Dall'epoca 2 le famiglie si dividono col tempo in **eminenti e comuni** secondo la **posizione di prestigio** ottenuta; l'umore di tutte le famiglie compone il consenso generale, con più peso per le eminenti: il consenso dopo sarà caratterizzato da questa differenza.
- Registrare il prestigio già nel villaggio, nascosto: sì.
- Fine sessione dopo le famiglie: diario, verifica dei file e del repository.

**Prossimo passo**
- Fede: provare nel gioco persone, animazioni, specchietti, scheda della famiglia; dire se "comuni" va bene o preferisce "normali".
- Claude: voce 4, scorrerie (prima il riepilogo); poi 9 (base tecnica, con il salvataggio), 6 (evento soglia), 10.

## 26/11/2026 (sera, tardi) — scheda della famiglia
**Fatto**
- **Scheda della famiglia** (resto della voce 7): un clic senza strumenti su una persona o su una casa apre nel pannello di focus "FAMIGLIA" il nome dal luogo, quante persone, casa e da quando (o "arrivati da fuori"), e le righe Lavoro, Ha, Umore e Vorrebbe, con il perché al passaggio del puntatore. La casa si incornicia sul terreno e i suoi membri si schiariscono; un clic altrove o Esc la chiudono. Descrizione in `prototipo0-godot.md` e `hud.md`, foto `docs/immagini/famiglia-26-11.jpg`.
- Ogni figura abita in una casa vera, e le figure si dividono tra le case in parti uguali. La simulazione ricorda l'anno di nascita di ogni casa e le case delle famiglie accolte da fuori (solo memoria: le dinamiche non cambiano, quindi niente partite "umane").
- Nuove verifiche in `verifica_partita.gd` (case vere, nomi senza doppioni, clic su persona e su casa, righe brevi con il perché, chiusura); modo `famiglia` in `foto_partita.gd`; una riga nel tutorial dei rapporti di forza. Tutte le 9 verifiche superate.

**Decisioni** (Fede)
- Riepilogo accolto; nome della famiglia dal luogo; clic su persone e case.
- Proposte di Claude da guardare: i dodici nomi comuni (dell'aia, dell'orto, del noce…), i desideri e il loro ordine, la cornice bianca della casa.

**Prossimo passo**
- Fede: provare la scheda nel gioco, insieme a persone e specchietti.
- Claude: voce 4, scorrerie (prima il riepilogo).

## 26/11/2026 (sera) — forme di governo decise
**Fatto**
- Forme di governo delle epoche 2–4 segnate come decise in `era-origini.md` § 5, `era-antichita.md` e `specchietto.md`. "Lignaggi" diventa **clan** e "maggiorenti" diventa **grandi famiglie** in tutti i documenti (forme di governo, gruppi, edifici, proprietà, sensibilità dell'epoca 2).

**Decisioni** (Fede)
- Forme di governo: tutto bene. "Maggiorenti" e "lignaggi" sono desueti: scelti **Consiglio dei clan** e **Consiglio delle grandi famiglie** (le preferite di Claude); il resto si cambia di conseguenza. I gruppi "grandi famiglie" e "sacerdoti" dell'epoca 3 restano proposte.

**Prossimo passo**
- Fede: la prova in gioco di persone, animazioni e specchietti.
- Claude: le voci aperte del todo, nell'ordine che sceglie Fede.

## 26/11/2026 (sera, più tardi) — persone: viso e spalle
**Fatto**
- **Viso** (`strumenti/blender/persone.py`, funzione `viso`): orbite scavate con gli occhi scuri dentro (nuovo volume `Scava` e nuova classe "occhi" nello shader), naso con il dorso e le ali, bocca incisa e labbra, zigomi, mascella e mento (più delicati nelle donne), sopracciglia; barba con le basette; la calotta dei capelli non copre più la fronte.
- **Spalle**: niente più sfere sulle spalle; il trapezio scende dal collo, deltoide piccolo, braccia e maniche più asciutte, busto un po' più stretto, petto più marcato negli uomini. La pelle a tracolla dell'uomo 2 al posto del disco sul petto.
- Il modello completo ha circa 3000 facce (prima 2200) e la testa ne tiene il 40%; il leggero resta a 320. La cucitura della grana è dietro.
- Nuovo `test/foto_ritratto.gd` (ritratti ravvicinati); immagine `docs/immagini/ritratti-prima-dopo-26-11.jpg`. Tutte le 9 verifiche superate.

**Decisioni**
- Fede: il modello va rifinito, spalle e viso in particolare, nella vista ravvicinata; da lontano va bene. L'ok sulle animazioni arriva dopo la sua prova.

**Prossimo passo**
- Fede: provare nel gioco persone, animazioni e specchietti; i nomi delle forme di governo.
- Claude: la scheda della famiglia con un clic su una persona; poi le voci 4 e 5.

## 26/11/2026 (pomeriggio, sera) — popolazione visibile (voce 7)
**Fatto**
- **Persone** (`strumenti/blender/persone.py`, `gioco/asset/persone/`): 3 uomini (1,74 m) e 3 donne (1,62 m), corpo unico da volumi come gli animali, completo (2200 facce) e leggero (320). Vesti del Neolitico (tunica con la cintura, al ginocchio o al polpaccio, maniche corte; mantelli e pelli; calzari), capelli lunghi, corti, a crocchia, treccia o sciolti, barba per due uomini. Cinque attrezzi nella mano destra: zappa, ascia, lancia, bastone, cesto. Le braccia sono scostate dal corpo, così alzandole non si tende una membrana tra mano e fianco.
- **Shader** (`shader/persone.gdshader`): colori per figura (quattro incarnati, cinque colori di capelli, sette vesti di colori naturali, quattro mantelli), sfumati tra i vertici; animazioni: camminare con la veste che segue le gambe, stare fermi, parlare, zappare, tagliare, la lancia con il colpo ogni tanto, raccogliere chini, costruire, il pastore al bastone.
- **Nel gioco** (`script/vista_persone.gd`): al massimo 150 figure, una ogni 1, 2 o 5 persone; i mestieri seguono il lavoro vero dell'anno (contadini e raccoglitrici nei campi, boscaioli alle legnaie attive, pescatori ai capanni, cacciatori nel bosco dietro le poste, un pastore per gregge, costruttori ai cantieri, gente al luogo sacro); un terzo resta in paese, attorno al focolare e alle case. Camminano a 1,1 m/s senza scatti; si disegnano sotto i 450 m di vista.
- Verifiche nuove in `verifica_partita.gd` (figure e quota, modelli e shader, ogni figura ha un luogo di lavoro vero, un minuto di movimento, nascoste da lontano) e la cartella delle persone in `verifica_asset.gd`. Tutte le 9 verifiche superate; le dinamiche non cambiano, quindi niente partite "umane". Foto: `docs/immagini/persone-26-11.jpg`, `persone-nel-gioco-26-11.jpg`, `contadino-26-11.jpg`; nuovo `test/foto_persone.gd`, modo `persone:mestiere` in `foto_partita.gd`.

**Decisioni**
- Fede: "vai procedi" (riepilogo della voce 7 lasciato in conversazione).
- Proposte di Claude da guardare con Fede: le sei persone e i loro colori, i numeri (150 figure, 1/2/5 persone per figura, visibili sotto i 450 m), un terzo delle figure in paese.

**Prossimo passo**
- Fede: provare nel gioco specchietti e persone (aspetto e fotogrammi al secondo, anche con gli animali); i nomi delle forme di governo.
- Claude: la scheda della famiglia con un clic su una persona; poi le voci 4 (scorrerie) e 5 (strade, con le figure che camminano sui sentieri).

## 26/11/2026 (pomeriggio, più tardi) — "Conseguenze"
**Fatto**
- Lo specchietto sopra la scheda dello strumento si chiama **Conseguenze** (prima "Cosa sto facendo"): titolo nel gioco, scheda del tutorial, documenti, foto rinominata in `docs/immagini/conseguenze-26-11.jpg`. Tutte le 9 verifiche superate.

**Decisioni** (Fede)
- Togliere "Cosa sto facendo": un nome come "Conseguenze" o "Effetti". Claude ha scelto **Conseguenze** (in linea con il pilastro "nessuna soluzione giusta, solo conseguenze").

**Prossimo passo**
- Fede: provare gli specchietti nel gioco; dire se i nomi delle forme di governo vanno bene.
- Claude: voce 7, popolazione visibile; prima il riepilogo.

## 26/11/2026 (pomeriggio) — specchietti in gioco (voce A)
**Fatto**
- **Cosa sto facendo:** sopra la scheda dello strumento, per ogni strumento del villaggio e per il punto sotto il puntatore: Chi guadagna, Chi perde (gruppi con ▲ ▼ e il motivo), Sul territorio, Costo (rosso se irreversibile), Resta. Le stime vengono dalle regole della simulazione (per esempio Demolisci sulle case: "Famiglie ▼▼", "macerie: niente case per 20 anni"). Si fa da parte quando si aprono focus o politiche.
- **Rapporti di forza:** il pannello del Consenso, anche con il tasto R: peso e umore di ogni gruppo con parola e freccia, tensione, "si muove verso"; il perché di ogni gruppo al passaggio del puntatore (tolto il muro di cause che c'era prima).
- **Assi dell'identità nascosti** nella simulazione, mossi dalle politiche; pesi dei gruppi, tensione, andamento. Nessuna regola del villaggio cambia, quindi niente partite "umane".
- Scheda di tutorial "Chi conta nel villaggio" alla tappa dei 60 abitanti.
- 12 verifiche nuove in `verifica_partita.gd` (anche: righe al massimo di 52 caratteri, niente percentuali). Reso stabile il controllo degli animali che brucano: contava un solo istante e falliva circa una volta su due, perché la partita della verifica parte ogni volta con un seme diverso. Tutte le 9 verifiche superate. Foto `docs/immagini/cosa-sto-facendo-26-11.jpg`, `rapporti-di-forza-26-11.jpg`.

**Decisioni** (Fede)
- Riepilogo della voce A approvato ("perfetto"): tasto R, scheda di tutorial alla tappa dei 60.

**Prossimo passo**
- Fede: provare gli specchietti nel gioco; dire se i nomi delle forme di governo vanno bene.
- Claude: voce 7, popolazione visibile, con animazioni e grande cura del dettaglio; prima il riepilogo.

## 26/11/2026 (pomeriggio, ordine del lavoro)
**Decisioni** (Fede)
- Ordine: voce A (specchietti in gioco), poi la 7 (popolazione visibile) con le **animazioni** e grande cura del **livello di dettaglio**; poi le altre.
- Dimensioni degli edifici delle risorse: vanno bene. Numero di abitanti: va bene per ora, seguiranno verifiche. Catalogo degli edifici: va bene per ora.
- Nomi delle forme di governo: Fede non li aveva visti; ripresentati in conversazione, in attesa di risposta.

**Prossimo passo**
- Claude: riepilogo della voce A a Fede, poi il codice.

## 26/11/2026 (pomeriggio, più tardi) — specchietti in gioco
**Fatto** (solo documenti)
- Proposti a Fede due specchietti **in gioco** (Fede intendeva questo, non un documento; `docs/specchietto.md` resta per chi lavora al progetto): **Cosa sto facendo**, nella scheda dello strumento, e **Rapporti di forza**, dal pannello del Consenso. Messi nel todo come **voce A, priorità 1**, con disegno, modo di farli e stima; una riga nello specchietto.

**Decisioni** (Fede)
- Gli specchietti si fanno già nel villaggio, al primo posto.

**Prossimo passo**
- Claude: riepilogo della voce A a Fede prima del codice; poi le voci rimaste del todo.

## 26/11/2026 (pomeriggio) — prime due Ere riviste, specchietto
**Fatto** (solo documenti)
- **Prime due Ere riviste con lo schema** (ok di Fede: "mi pare tutto ottimo"): le Origini e l'Antichità sono il tutorial dello schema, ogni epoca accende pochi pezzi nuovi. In `era-origini.md`: "Lo schema nel villaggio" (§ 4), il primo governo con un nome all'evento soglia 1 (§ 5), prime zone dentro e fuori il recinto e concessione dei lotti ai lignaggi nell'epoca 2 (§ 6). Nuovo `era-antichita.md`: cronologia emiliana, nomenclatura, Città-stato (cittadinanza, reticolo e città vecchia, primo bilancio, colonie, tempio sul luogo sacro), evento soglia 3 con quattro esiti, Città imperiale (potere esterno, manutenzione annua, notabili che pagano le opere, centuriazione e coloni, reticolo sulla città vecchia, curatore), evento soglia 4.
- **Specchietto** (richiesta di Fede): nuovo `docs/specchietto.md` con le epoche in una tabella, lo schema in una riga, tutte le liste di riferimento e le regole; `CLAUDE.md` dice di leggerlo per orientarsi e di tenerlo aggiornato.

**Decisioni** (Fede)
- Revisione delle prime due Ere approvata.
- Parlare di monarchia o tirannide per il primo governo è prematuro: Claude propone nomi per ogni fase (Comunità, Consiglio dei lignaggi, Casa dominante e Capo di guerra; Assemblea dei cittadini, Consiglio dei maggiorenti, Capo sacro e Signore della città; Città alleata, Municipio, Colonia e Curatore inviato), da confermare.

**Prossimo passo**
- Fede: dire se i nomi delle forme di governo vanno bene.
- Claude: poi, se Fede vuole, l'Età industriale sulla carta.

## 26/11/2026 (primo pomeriggio) — schema delle dinamiche
**Fatto** (solo documenti)
- In `epoche-future.md` nuovo § 9: schema delle dinamiche (territorio e sensibilità → opere e zone → campi del lotto → edifici e gruppi sociali → consenso per quartiere → regime e bilancio), zone dal protourbano, concessione dei lotti alle famiglie, sette menù con sottomenù, campi del lotto, quattro tipi di sinergia (raggio, catene, complessi, conflitti), Haussmann come esempio. Mostrato a Fede con uno schema disegnato.
- Nel catalogo, la regola su chi fa gli edifici aggiornata.

**Decisioni** (Fede)
- Spontaneo solo l'abitato del villaggio; dal protourbano le zone, con il gesto di Cities: Skylines ma uno strumento più preciso. Famiglie e prestigio e Abitare come sottomenù.
- Schema, campi e sinergie: "mi torna"; è intricato, serviranno prove in gioco.

**Prossimo passo**
- Claude: rivedere le prime due Ere (Origini e Antichità) alla luce dello schema; prima la proposta in conversazione.

## 26/11/2026 (mezzogiorno passato) — catalogo degli edifici
**Fatto** (solo documenti)
- `docs/edifici-per-epoca.md` rifatto come **catalogo per categoria di gioco** (richiesta di Fede: tanti edifici per epoca, ma con un lavoro certosino su come si usano nelle dinamiche). Quattordici categorie (abitare, famiglie e prestigio, terra e cibo, lavoro, scambio e denaro, acqua ed energia, vie, trasporti, difesa e confine, sacro, governo e ordine, vita pubblica, sapere e informazione, salute), circa 170 edifici, ognuno con le epoche in cui si costruisce, **perché lo si sceglie** e cosa muove. Aggiunti castelli e rocche, borghi murati, cassero, torre civica e torre dell'orologio (con scopi diversi), contado (casa colonica, corte agricola, macero, mulino), casello del dazio, tipografia e altri. Regole: ogni edificio ha uno scopo suo; quelli spontanei li orienta il giocatore, non li sceglie.
- Tolta la colonna su come si realizza ogni modello (Fede: secondario, si vede dopo); la versione precedente resta nella storia del repository.

**Decisioni** (Fede)
- Varianti di degrado, inclinazione e crepe con lo shader: confermato.
- Prima si decide a cosa serve ogni edificio, poi come si realizza.

**Prossimo passo**
- Fede: rivedere il catalogo (togliere, aggiungere, spostare di categoria; dire se le categorie sono anche i menù del gioco).

## 26/11/2026 (pomeriggio)
**Decisioni** (Fede)
- Animali e brucatura approvati ("ora ci siamo"); l'ultima verifica nella prova in gioco.
- Il maiale sembra un po' un facocero: secondario, da rivedere più avanti (segnato nel todo, voce 2). Per ora bene così.

**Prossimo passo**
- Fede: prova in gioco di animali, brucatura, tutorial e fotogrammi al secondo.
- Claude: voci 4 (scorrerie) e 5 (strade), con riepilogo prima.

## 26/11/2026 (primo pomeriggio)
**Fatto**
- **La "proboscide" era un errore dello shader** (Fede: "il bue ha ancora la proboscide"): l'esportazione glTF capovolge la v delle UV, e il peso delle parti (scritto nella seconda UV) arrivava rovesciato. Così la testa si piegava dal muso invece che dalla nuca (il muso restava fermo e la testa si stirava) e le zampe si muovevano dall'anca invece che dallo zoccolo. Corretto in `animali_comune.gdshaderinc` (`w = 1 − UV2.y`). Ora pecora, capra, maiale e bue brucano con la testa giù vicino alle zampe davanti.
- Brucatura ritarata: collo piegato fino a 66° circa, testa a 85° sotto l'orizzonte. Foto `docs/immagini/bue-26-11.jpg` e `animali-pelo-26-11.jpg` rifatte. Verifiche degli asset e della partita superate.

**Prossimo passo**
- Fede: riguardare animali e brucatura nel gioco; provare i tutorial.
- Claude: voci 4 e 5, con riepilogo prima.

## 26/11/2026 (mezzogiorno)
**Fatto**
- **Tutorial alle tappe** (decisione di Fede): nuovo `script/tutorial.gd` con sedici schede (fondare; zona agricola, campo, sentiero, legnaia, capanno, posta, fonti di cibo dopo la fondazione; granaio e raccolto a 60; luogo sacro e pascolo a 100; stranieri, villaggio affollato e bosco sacro a 150; casali a 250). Decisioni di tipo "tutorial" in `SimVillaggio` (`tutorial()`, `salta_tutorial()`, `tutorial_attivi`), riquadro `Hud.mostra_tutorial`: testa con la tappa e la pagina, titolo, due o tre righe, "Cosa fa…?" che apre la spiegazione, "Salta i tutorial" e Avanti/Continua. Saltati, diventano notifiche grigie per il resto della partita. Le foto di controllo partono senza tutorial. Foto `docs/immagini/tutorial-26-11.jpg`; nuovo `test/foto_tutorial.gd`.
- **Testi nella voce del mondo** (Fede: "meno annunci falsi è tecnico"): tutte le schede riscritte senza percentuali né gergo; restano comandi e costi.
- **Bue rifatto** (Fede: "l'animale grigio cosa sarebbe?"): pelo corto e liscio (carte da 3,5 cm, frangia solo sotto), testa da bovino (fronte larga, muso largo e scuro, orecchie orizzontali più piccole, corna a lira alte con la sola punta scura), manto grigio più scuro con spalle scure. Foto `docs/immagini/bue-26-11.jpg`.
- **Brucare senza proboscide:** il collo si piega dall'attaccatura sulle spalle (al massimo 50° circa) e la testa dalla nuca, finché scende quasi verticale; il poco che manca all'erba lo fa un piccolo abbassamento. Angoli calcolati in `animali.py` (`postura_bruca`) e passati allo shader (`perno_collo`, `giunto_testa`, `peso_testa`, `angolo_collo`, `angolo_testa`).
- Verifiche nuove in `verifica_partita.gd` (riquadro all'inizio, spiegazione, Continua, pagine della fondazione, Salta e notifiche); tutte le 9 superate. Giocatori "umani" e registro con i tutorial contati a parte: dinamiche identiche a stamattina (`sessioni-giocatori.md`).

**Decisioni** (Fede)
- "Salta i tutorial" vale per tutti i riquadri della partita in corso, non per le partite dopo; notifica grigia per i tutorial saltati.
- Tutorial anche per la fondazione e la tappa dei 60; pause dei tutorial contate a parte nelle prove; **menù delle impostazioni** nel todo (voce 10), con dentro l'opzione dei tutorial.
- Il tutorial parla con la voce del mondo del gioco, non dei meccanismi.

**Prossimo passo**
- Fede: provare i tutorial e rileggere i testi (`script/tutorial.gd`); guardare bue e brucatura; fotogrammi al secondo con gli animali.
- Claude: voci 4 (scorrerie) e 5 (strade, con la scheda del tutorial), con riepilogo prima.

## 26/11/2026 (tarda mattina) — epoche future sulla carta
**Fatto** (solo documenti, nessun codice né modello; richiesta di Fede: definire in parallelo dinamiche, strutture ed edifici delle prossime epoche)
- Nuovo `docs/epoche-future.md`: metodo (un'epoca alla volta sapendo dove si va, progettare all'indietro da Haussmann); nove sistemi che attraversano le epoche (Vie e Trasporti separati); identità della città con quattro assi, regime, vocazione, deriva, rivoluzioni dalla tensione e peso latente, pannello dell'identità; regime fondiario a quattro leve e cinque modelli; gruppi sociali e politica; vita delle costruzioni (struttura separata dalla funzione, tipi di struttura, cambio d'uso spontaneo, vincoli e zone, abbandono e rovina, varianti dei modelli derivate in automatico); dinamica calda (bilancia pressione–valore, rarità, otto esiti, pausa per l'ultimo esemplare); sottosuolo e tracciato (tre modi di restare, leggibilità, forza del tracciato, cinque risposte alle scoperte); costruzione a rischio.
- Nuovo `docs/edifici-per-epoca.md`: lista completa di edifici e modelli per epoca, con il genere (fatto a mano, generatore, rete, pezzo, shader), ciò che esiste già e una stima del conto.
- Rimandi in `pilastri-e-decisioni.md`, `todo.md`, `CLAUDE.md`.

**Decisioni** (Fede)
- Tutto `epoche-future.md` approvato ("tutto approvato"), con le sue aggiunte: identità organica dalle politiche, opzioni che si spengono secondo il regime, rivoluzioni; regime e vocazione in testa al pannello, niente muri di testo; Vie e Trasporti separati; il ciclo delle fabbriche non è inevitabile; Restaurare e Rifunzionalizzare tra gli esiti; pausa "stai per demolire l'ultimo esemplare" con bonus e malus; vincoli e zone; nessuna domanda sugli edifici comuni; tracciato manipolabile (rettifili); ogni struttura abbandonata non protetta diventa strato, che si percepisce e poi resta nella memoria; recupero in loco (Sala Borsa); peso latente che cresce con la repressione; attenzione al numero dei modelli. Da raffinare: salute e scarti, bilancio. Da ragionare: stratificazione in altezza.
- `edifici-per-epoca.md` è una proposta di Claude, da confermare.

**Prossimo passo**
- Fede: rivedere `edifici-per-epoca.md` (cosa togliere, cosa aggiungere, le quattro voci nuove del villaggio: aia, fornace, sepolture, passerella).
- Claude: in parallelo al villaggio (todo, voci 2, 4, 5), quando Fede lo chiede, l'Età industriale sulla carta, poi l'Antichità.
## 26/11/2026 (tarda mattinata)
**Fatto**
- **Maiale rimodellato** (Fede: "sembra un tapiro"): corpo più corto (1,15 m) e alto davanti, spalle robuste e prosciutti pieni, testa a cuneo con guance e mascella, grugno a disco tagliato netto (nuovo volume `Disco` in `animali.py`), orecchie grandi e dritte, zampe corte, coda con il ciuffo, cresta di setole. Foto `docs/immagini/maiale-26-11.jpg`; `animali-pelo-26-11.jpg` rifatta. `test/foto_animali.gd` ha un modo per una specie sola da vicino (quarto argomento: il nome della specie). Verifiche degli asset e della partita superate.

**Decisioni** (Fede)
- Il sacerdote chiede il luogo sacro quando se ne sblocca la costruzione.
- Greggi: per ora restano come sono.
- **Tutorial alle tappe:** a ogni sblocco (tappa, costruzione…) il gioco si ferma e mostra un avviso a schermo con la spiegazione, che si può saltare; un tasto apre il dettaglio ("Cosa fa un luogo sacro?"); "Salta i tutorial" si salva. Riepilogo e tre proposte di Claude inviati a Fede, in attesa di conferma: tutorial anche per la tappa dei 60 abitanti e per la fondazione; casella riattivabile dal pannello delle politiche finché non c'è un menù delle impostazioni; pause dei tutorial contate a parte nelle prove "umane".

**Prossimo passo**
- Fede: guardare il maiale; confermare il riepilogo dei tutorial.
- Claude: i tutorial (con la richiesta del sacerdote dentro quello del luogo sacro), poi le voci 4 e 5.

## 26/11/2026 (mattina tardi)
**Fatto**
- **Animali rifatti, terza versione** (Fede: "grossolani e molto poligonali", definizione simile agli alberi; riferimenti di Age of Empires IV dalla pagina del wiki indicata da Fede, studiando le scene di gioco e non le icone dorate):
  - nuovo `strumenti/blender/animali.py`: corpo unico da un campo di distanza (volumi che si fondono, superficie con marching cubes; scikit-image aggiunto a `setup_strumenti.sh`), tre manti per specie, livello completo (2600–3600 facce) e leggero (260);
  - pelo: grane nuove `pelo.png` e `lana.png` che scorrono dal dorso alla pancia, e **carte di pelo** con il ritaglio come le foglie (`ciocche.png`, `ciocche_lana.png`): frangia sotto la pancia, cresta del maiale;
  - testa del maiale corta (brucando sembrava una proboscide, segnalato da Fede) e brucatura diversa per specie: il collo scende fino a mettere il muso nell'erba;
  - tolti i vecchi `animale_*.glb` e gli animali da `villaggio.py`. Foto: `docs/immagini/animali-pelo-26-11.jpg`, `animali-pelo-vicino-26-11.jpg`.
- **Animazioni e movimento** (Fede: animazioni ok come proposte, più il movimento da un punto all'altro): shader `animali.gdshader` e `animali_ciocche.gdshader` con `animali_comune.gdshaderinc` (zampe a coppie diagonali, corpo che sale e scende, testa che bruca e si guarda attorno, orecchie, coda); in `VistaVillaggio` accelerazione, curve, passo lungo oltre 25 m, zampe legate alla strada fatta, gregge che parte in fila sciolta; modelli completi sotto i 220 m di vista e leggeri sopra. Con la MultiMesh nel renderer Compatibilità servono anche i colori per istanza, altrimenti gli animali uscivano neri.
- **Campo stanco visibile:** si schiarisce, terra polverosa, erbacce a chiazze; maggese quasi tutto erba; più povero nella mappa della Fertilità. Foto `docs/immagini/campo-stanco-26-11.jpg`.
- Verifiche nuove in `verifica_partita.gd` (materiali e livelli degli animali, manti, movimento, fase del passo, gregge in fila, campo stanco); tutte le 9 verifiche superate. Le dinamiche non cambiano, quindi niente nuove partite "umane".

**Decisioni** (Fede)
- Confermate le proposte del campo stanco visibile, del tasto N, dei greggi uno per stabbio e della riga "si macellano" al massimo ogni 5 anni.
- Tre manti per specie subito; animazioni come proposte da Claude, più il movimento tra i punti.
- Riferimento per gli animali: Age of Empires IV (scene di gioco).

**Prossimo passo**
- Fede: guardare le foto e provare nel gioco gli animali (fotogrammi al secondo con molti animali vicini, sui tre PC) e il campo stanco; rispondere sulle due domande del pascolo (notifica del sacerdote, greggi più grandi).
- Claude: voci 4 (scorrerie) e 5 (strade), con riepilogo prima di cominciare.

## 26/11/2026 (mattina)
**Fatto**
- **Stime riviste** (richiesta di Fede): tempi veri dai commit del 25/11, nel todo. Erano da 2 a 8 volte troppo alte; il costo fisso vero sono le prove, circa 25 minuti per voce. Restano 7–10 ore di lavoro di Claude.
- **Partite "umane" sul sacerdote contrariato** (`sessioni-giocatori.md`): dinamiche come prima. Chi legge erige ancora poco il luogo sacro (7 su 18).
- **Pascolo e animali** (voce 2, quasi tutta):
  - zona di pascolo a pennello (Territorio, tasto N) con l'opzione **Togli**, aggiunta anche alla zona agricola;
  - capi con portata e crescita, stoppie e maggese, radure che restano aperte, scorta viva, stranieri con animali, erosione sui pendii, disuguaglianza se gli animali sono delle famiglie;
  - indicatore e pannello "Animali";
  - **stabbio** e **animali** (pecora, capra, maiale, bue) in Blender, sulla mappa in **greggi**, uno per stabbio, che si spostano piano nel pascolo. Foto: `docs/immagini/animali-26-11.jpg` e `greggi-nel-gioco-26-11.jpg`;
  - giocatori automatici, 15 verifiche nuove sulla simulazione e 2 sugli strumenti, tutte le 9 superate. Partite "umane": chi conosce il genere passa da 2,7 a 1,6 carestie a partita grazie alla scorta viva.
- **Animali rifatti** (Fede: i primi erano "un po' abbozzati"): una sagoma propria per specie. Pecora a bioccoli bianchi con testa e zampe scure, capra slanciata con barba e corna all'indietro, maiale basso con grugno e criniera, bue con gobba, giogaia, corna a lira e ciuffo sulla coda; zampe in due pezzi con lo zoccolo (300–600 facce l'uno). Foto in fila e di profilo: `docs/immagini/animali-26-11.jpg`. Verifiche degli asset e della partita superate.

**Decisioni**
- Fede (25/11 sera): capi confermati; opzione "Togli"; le due zone si parlano senza entrare in conflitto (stoppie e maggese).
- Proposte di Claude da confermare: tasto N; animali in greggi, uno per stabbio; righe "si macellano" al massimo ogni 5 anni.

**Prossimo passo**
- Fede:
  - guardare animali e greggi (foto) e provarli, con i fotogrammi al secondo;
  - confermare il **campo stanco visibile**: il campo si schiarisce e si riempie di erbacce, ed è più povero nella mappa della fertilità;
  - dire se il sacerdote deve chiedere il luogo sacro con una notifica.
  - dire se le greggi vanno ingrandite (oggi 12 capi senza pascolo, 50–70 con 44 ettari).
- Claude: campo stanco visibile appena confermato; poi le voci 4 (scorrerie) e 5 (strade).

## 25/11/2026 (notte, ancora più tardi)
**Fatto**
- **Luogo sacro, sacerdote, bosco sacro** (voce 3 del todo):
  - **luogo sacro** in Edifici (tasto O): 20 di legna, 3 anni di cantiere, entro 400 m dal centro, uno solo, con il suo scheletro; le case gli crescono attorno;
  - **sacerdote:** diventa il terzo gruppo di consenso quando il luogo sacro è finito. Vuole il luogo sacro, un bosco sacro grande e i presagi ascoltati. Se è contento i presagi falsi sono il 15% e il presagio delle sorgenti ha un indizio in più; se è scontento i falsi sono il 40% e il testo diventa vago;
  - **bosco sacro** a pennello in Territorio (tasto B), pieno da 10 ettari: le legnaie e le famiglie non lo toccano, tagliarlo con Demolisci offende il sacerdote. Ha un velo dorato con il bordo;
  - icone nuove `luogo_sacro.svg` e `bosco_sacro.svg`, cause del sacerdote nel pannello del Consenso;
  - i giocatori automatici imparano i due strumenti; 11 verifiche nuove nella simulazione e 2 negli strumenti, tutte le 9 superate.
- Giocatori "umani" e registro (`sessioni-giocatori.md`): mediane e carestie come prima, 3,6 pause per partita. Chi conosce il genere tiene il sacerdote a 71.
- Le notifiche delle tappe ora elencano con le virgole ("la regola sugli stranieri, la regola per il villaggio affollato e il bosco sacro").

**Decisioni** (Fede)
- Ok al piano della voce 3, con le proposte di Claude: numeri, tasti O e B, presagi falsi al 15% e al 40%, bosco sacro pieno da 10 ettari.
- Più tardi, **necessità invertita:** il sacerdote ha voce dalla tappa dei 100 abitanti ed è contrariato finché il luogo sacro non è eretto, così il giocatore è spinto a costruirlo. Fatto e riprovato; le notifiche delle tappe lo annunciano in cronaca.
- Domanda di Fede sul maggese: il campo resta un campo anche a maggese e torna coltivato da solo quando si è riposato. Per togliere il pascolo senza toccare i campi Claude propone un'opzione "Togli" nello strumento delle zone (da confermare).

**Prossimo passo**
- Fede: provare luogo sacro e bosco sacro; confermare la crescita dei capi, il campo stanco visibile e l'opzione "Togli" per le zone.
- Claude, alla prossima sessione: **rifare le partite "umane"** dopo il sacerdote contrariato. Sono state interrotte per il limite di utilizzo; registro e verifiche del villaggio sono già passati. Poi la voce 2, pascolo e bestiame: confermati da Fede i capi, l'opzione "Togli" e la convivenza tra zone (stoppie e maggese); resta da confermare il campo stanco visibile. Poi le voci 4 e 5.

## 25/11/2026 (notte, più tardi)
**Fatto**
- **Mappe tematiche** (voce 8 del todo), tasti 6–8 con bollino e legenda:
  - **Caccia e pesca:** selvaggina e pesce per riquadro, cerchi di poste e capanni, zone di taglio;
  - **Abitato e contado:** abitato, contado con i campi, casali;
  - **Memoria del suolo:** dove c'era il bosco, suolo sigillato, rovine.
- Nuova texture della memoria del bosco nell'uso del suolo e nuovo `SimVillaggio.raggio_case`. I pannelli Legna e Popolazione portano alle mappe nuove. 5 verifiche nuove in `verifica_partita.gd`, tutte le 9 superate. Foto in `docs/immagini/mappa-*-25-11.jpg`.

**Decisioni** (Fede)
- Si comincia dalla voce 8. Tre mappe: il pesce sta nella 6 "come cibo", quindi si chiama Caccia e pesca; abitato e contado distinti; memoria del suolo.

**Prossimo passo**
- Fede: provare le mappe nel gioco.
- Claude: secondo l'ordine per durata, voce 3 (luogo sacro, sacerdote, bosco sacro, con il suo scheletro di cantiere), poi la 2 (pascolo; servono prima le conferme sulla crescita dei capi e sul campo stanco visibile).

## 25/11/2026 (notte)
**Fatto**
- **Cantieri visibili:**
  - quattro **scheletri** in `strumenti/blender/villaggio.py`, che nascono dal modello finito: solo pali e travi, con materiali e attrezzi accanto. Il granaio ha il telaio del piano, i montanti, una scala e l'argilla; la legnaia pali e travi senza falda, con il ceppo e l'ascia; il capanno capriate e un tratto di canne; la posta forcelle, colmo e rami a terra. Foto: `docs/immagini/cantieri-25-11.jpg`;
  - nel gioco, finché c'è il cantiere si vede lo scheletro con una **barra discreta** sopra, che scorre con l'anno in corso; poi compare il modello finito. Granaio, legnaie, capanni e poste si disegnano ora in un'unica funzione, `VistaVillaggio._sincronizza_edifici`. Foto: `docs/immagini/barra-cantiere-25-11.jpg`;
  - 3 verifiche nuove in `verifica_partita.gd`, nuovo script `test/foto_cantieri.gd`. Tutte le 9 verifiche superate. Le dinamiche non cambiano, quindi niente nuove partite "umane".

**Decisioni** (Fede)
- Cantieri: barra più lo scheletro di ogni edificio (scartato il cantiere unico per tutti). Approvati gli scheletri della foto.

**Prossimo passo**
- Fede: guardare la barra nel gioco (misura e posizione). Le altre domande sono nella voce qui sotto.
- Claude: voce 2, pascolo e bestiame. Il luogo sacro (voce 3) avrà anche il suo scheletro.

## 25/11/2026 (sera tardi)
**Fatto**
- **Capanno da pesca e Posta di caccia** (voce 1 del todo):
  - **Simulazione** (`sim_villaggio.gd`): senza edifici le famiglie cacciano e pescano attorno al villaggio e rendono un terzo; ogni edificio finito rende pieno, fino a 35 di cibo l'anno. Pesce e selvaggina sono contati in riquadri di 200 m: gli edifici vicini se li dividono, troppi li fanno calare, lasciati stare si riprendono. 2 anni di cantiere, entro 1 km dal centro, nessuna distanza minima.
  - **Aggancio:** la simulazione aggancia da sola, con i campi fini della mappa (`MappaDati.valore_fine`, `distanza_riva`, `bosco_in`, `palude_in`). Il capanno va a circa 2 m dall'acqua, fuori dalla palude e girato verso l'acqua; la posta appena fuori dal bosco, con la schiena al bosco.
  - **Nel gioco:**
    - voci in Edifici (tasti K e T) con l'anteprima già agganciata, rossa con il motivo se non si può;
    - lettura sotto il puntatore: acqua o bosco, scorta, resa stimata, edifici vicini, stato dell'edificio;
    - cause nel pannello del Cibo;
    - modelli posati sulla mappa con gli alberi tolti attorno;
    - Demolisci li toglie.
  - **Prove:** 16 verifiche nuove in `verifica_villaggio.gd` e 8 in `verifica_partita.gd`. I giocatori automatici costruiscono i due edifici (`aiuti_giocatori.gd`). Tutte le 9 verifiche superate. Foto in `docs/immagini/capanno-nel-gioco-25-11.jpg` e `posta-nel-gioco-25-11.jpg`.
- **Giocatori "umani" e registro** (`sessioni-giocatori.md`):
  - le mediane non cambiano (433, 555, 748, 110 abitanti);
  - le carestie salgono per chi legge (2,4 a partita, prima 1,3) e per il casual (2,7, prima 1,7), quasi tutte all'Area dei gessi e allo Sperone collinare, i siti che vivono di caccia;
  - per partita 3,6 pause e 47 righe di cronaca.

**Decisioni**
- Fede: si comincia dalla voce 1 come riepilogata da Claude.
- Proposte di Claude, da confermare con Fede:
  - posta agganciata al margine entro 60 m;
  - tasti K e T;
  - 35 di cibo l'anno per edificio; posta fino a 1000 m, capanno fino a 600 m;
  - stato "pesce scarso" o "selvaggina scarsa" sotto il 40% della scorta.

- Più tardi (Fede): le carestie nei siti di caccia sono normali, si lascia così; confermate le proposte qui sopra; **cantieri visibili**: barra discreta sopra l'edificio in costruzione e un modello del cantiere da creare (voce 0 del todo).

**Prossimo passo**
- Fede:
  - guardare le foto;
  - confermare la proposta sulla crescita dei capi e sul campo stanco visibile prima del pascolo.
- Claude: voce 2, pascolo e bestiame.
- Nota per chi riprende: a inizio sessione l'accesso in scrittura al repository può essere bloccato da un controllo automatico. Basta che Fede lo autorizzi in modo esplicito, poi si riprova.

## 25/11/2026 (sera)
**Fatto**
- **Ritmo:** il gioco si ferma solo per le scelte che chiedono un intervento (sorgenti, cometa, primo arrivo degli stranieri); primo cattivo raccolto come notifica; piene grandi, siccità, segni di piena e divisione del villaggio solo in cronaca; febbri lievi se la città è sana, in cronaca solo se gravi; niente righe per i casali (spiegazione nel pannello della Popolazione); affollamento come politica "Villaggio affollato" (allargare o emigrare); velocità 1 a un anno al secondo. Risultato: 3,4 pause per partita, una ogni due minuti e mezzo circa.
- **Zona di taglio** della legnaia: cerchio trasparente che cresce con il taglio (shader del terreno), niente ricrescita dentro finché la legnaia lavora (`UsoSuolo.blocca_ricrescita`), riposo dopo 10 anni senza taglio, ceduo che torna bosco in 25 anni (`UsoSuolo.abbatti_ceduo`), clic sulla legnaia per "Lasciar ricrescere" o rimetterla al lavoro, stato di ogni legnaia nel pannello della legna (senza suggerimenti). Foto `docs/immagini/zona-taglio-25-11.jpg`.
- **Campi che si stancano** dopo 40 anni di coltura di fila (fino a −35%), si riposano incolti, il limo li rinnova.
- **Todo riorganizzato** per chi riprende con l'altro account: sezione "Per chi riprende" con le voci in ordine, decisioni, file e prove.
- Prove con i quattro giocatori "umani" e registro degli avvisi: risultati in `docs/sessioni-giocatori.md`. Tutte le 9 verifiche superate.

**Decisioni** (Fede)
- Fermare il gioco solo per le scelte che chiedono un intervento; il resto in cronaca, che spiega i problemi senza chiedere decisioni. Una febbre in una città sana è solo una flessione. I casali si vedono sulla mappa; al massimo una voce sulla demografia.
- Zona di taglio come zona di lavoro: resta tagliata finché la legnaia lavora, poi ricresce; riposo voluto, ceduo, peso su piene e selvaggina; all'esaurimento la scelta è del giocatore (nessun suggerimento).
- Limare un po' le popolazioni con i campi che si stancano (la rotazione delle colture arriverà con le epoche dopo). Velocità più calma.

- Più tardi (Fede): il casual si lascia così per ora; pascolo deciso nelle sue cinque parti (zona a pennello, maggese spontaneo con il campo stanco visibile, capi con crescita da gestire, scorta viva, politica del raccolto); niente "Caccia regolata" per ora; orti più piccoli solo come aspetto nella fase grafica. Stime dei tempi nel todo.

- Ultima ora: **icone** di Capanno da pesca, Posta di caccia e Pascolo (pronte per quando ci saranno gli strumenti) e **modello della Legnaia** (tettoia a una falda su pali, cataste sotto e di fianco, ceppo con l'ascia, tronchi e trucioli), ora usato nel gioco al posto della catasta provvisoria. Foto `docs/immagini/modello-legnaia-25-11.jpg`. Poi il **modello del capanno da pesca** (canne, tetto a due falde, rastrelliera con rete e pesci, piroga, nasse; foto `docs/immagini/modello-capanno-pesca-25-11.jpg`), con la falda della legnaia corretta. Poi il capanno **posato sulla riva** del fiume più vicina al sito iniziale, a 2 m dall'acqua, con rastrelliera e piroga rivolte verso il fiume (`gioco/test/foto_posa.gd`, foto `docs/immagini/capanno-riva-25-11.jpg`): è la regola di posa da usare per lo strumento (punto di terra asciutta vicino alla riva, fuori dalla palude, poco inclinato; verso = contro il gradiente della distanza dalla riva). Descrizioni della posta e dello stabbio del pascolo nel todo.
- Decisioni di Fede sul capanno: si posa **solo sulla riva** (aggancio automatico al punto di riva più vicino, girato verso l'acqua, fuori dalla palude, entro circa 30 m dal puntatore); **nessuna distanza minima** tra capanni né tra legnaie, sta al giocatore se vuole esaurire le risorse di una zona. Tolta dal codice la distanza di 150 m tra legnaie (resta solo il divieto di due sullo stesso lotto); i giocatori automatici continuano a non ammassarle (`aiuti_giocatori.gd`). Confermato da Fede anche il pesce locale per tratto di riva.
- **Modello della posta di caccia:** riparo basso a una falda coperto di frasche fresche e secche (ciuffi di foglie come le chiome degli alberi), rastrelliera con una pelle tesa, pelle a terra con i picchetti, piccolo focolare, palo con il palco di corna, due lance. Posata sul margine del bosco più vicino al sito, con la schiena al bosco (`test/foto_posa.gd`, che sostituisce `foto_capanno.gd`; foto `docs/immagini/posta-caccia-margine-25-11.jpg`).

**Prossimo passo**
- Chi riprende: `docs/todo.md`, sezioni "A che punto siamo" e "Per chi riprende" (prima voce: Capanno da pesca e Posta di caccia). Prima di cominciare il pascolo, confermare con Fede la proposta sulla crescita dei capi e sul campo stanco visibile.

## 25/11/2026 (pomeriggio)
**Fatto**
- **Giocatori "umani"** (`gioco/test/giocatore_umano.gd`): vedono solo ciò che vede il giocatore. Quattro profili: impara sbagliando, legge, conosce il genere ma non legge e va a tentativi, casual. Con le regole del mattino le carestie erano quasi assenti anche per chi sbaglia.
- **Carestie B + C:** presagi ignorati che pesano di più (siccità più lunga e più dura), scorte che senza granaio si guastano di più, nascite che seguono l'abbondanza degli ultimi 15 anni circa (il villaggio può crescere oltre ciò che la terra regge).
- **Legnaia:** senza legnaia non si raccoglie legna; i boscaioli abbattono gli alberi più vicini e il taglio si vede sulla mappa (il bosco ricresce dai margini); la raccolta rallenta con la radura. Strumento, icona, tasto L, lettura del bosco vicino, cause nel pannello della legna ("costruisci una legnaia vicino al bosco"). Anche le paludi danno un po' di legna.
- **Casali** dalla tappa dei 250 abitanti: il nucleo tiene fino a 280 abitanti, le famiglie in più vanno in casali di 4 case nel contado.
- **Taratura dopo le prove:** tolta una trappola (senza granaio i villaggi restavano sotto i 60 abitanti); cibo che avanza pieno a 18 mesi, soglia della crescita 60, danni della selvaggina messi nel conto dei campi. Risultati delle 72 partite in `docs/sessioni-giocatori.md`.
- Gesti comuni dei giocatori automatici in `gioco/test/aiuti_giocatori.gd`; tutti i giocatori automatici costruiscono la legnaia, ognuno a modo suo. Verifiche nuove su legnaia e taglio visibile. Regola nuova in `CLAUDE.md`: le prove con i giocatori "umani" sono la base dei test futuri.

**Decisioni** (Fede)
- Carestie B + C; casali; nome Legnaia, con il taglio visibile; Capanno da pesca e Posta di caccia con la stessa dinamica (senza edificio un terzo); le prove "umane" come base dei test, con i due profili nuovi.

**Prossimo passo**
- Fede: guardare i risultati (chi conosce il genere supera l'obiettivo di 600–800 abitanti; chi impara sbagliando ha poche carestie).
- Claude: Capanno da pesca e Posta di caccia; poi pascolo e bestiame, luogo sacro con il sacerdote, scorrerie, strade, popolazione visibile; passo elastico ed evento soglia. Da guardare con Fede la resa del taglio sulla mappa (nelle foto la radura si vede poco, perché ricresce presto di arbusti).

## 25/11/2026 (tarda mattina)
**Fatto**
- **Era delle Origini** definita in `docs/era-origini.md` (cronologia, nomenclatura, meccaniche, traguardi) e approvata da Fede; "macro-era" diventa "Era" in tutti i documenti.
- **Meccaniche dell'epoca 1 nella simulazione** (`sim_villaggio.gd`): Abbondanza (cibo che avanza, salute, spazio) che guida le nascite; tappe permanenti (60, 100, 150, 250 abitanti); legna (raccolta, focolari, manutenzione, case che costano legna, dissodamento che dà legna, catasta limitata); granaio a legna con 3 anni di cantiere; consenso di anziani e famiglie con effetti graduali (usanze, braccia, famiglie che se ne vanno); annate magre senza avvisi; siccità solo annunciate; presagi al massimo uno ogni secolo; stranieri attirati dall'abbondanza (il primo arrivo decide la regola); piene disastrose rare, annunciate e legate al bosco tagliato, la prima ferma il gioco una volta; piene di stagione col limo e senza notifica; febbri; niente avviso "zona agricola piena".
- **HUD:** indicatori Abbondanza, Consenso, Legna (Salute dentro Abbondanza); la tappa accanto all'anno; **pannelli di focus** con un clic su un indicatore (parti, perché, ultimi 100 anni, mappa); **lettura del terreno sotto il puntatore** per Zona, Campo, Granaio, Sentiero; granaio e politiche chiusi fino alla loro tappa. Immagini `docs/immagini/focus-consenso-25-11.jpg`, `docs/immagini/lettura-zona-25-11.jpg`.
- **Misure:** per partita 4,8 pause (prima 14), 2 notifiche rosse (prima 12), 0 carestie; dieci livelli da 222 a 873 abitanti, senza il muro dei 300 anni. `docs/sessioni-giocatori.md`, grafico `docs/immagini/sessioni-giocatori-25-11.png`.
- Verifiche aggiornate alle regole nuove (tappe, legna, stranieri, prima piena, pannelli di focus); tutte le 9 superate.

**Decisioni** (Fede)
- Approvato `era-origini.md` con le proposte: passo elastico, evento soglia a territorio pieno e dentro la finestra, dilemma e transizione, famiglie eminenti e comuni che nascono dalla disuguaglianza, crollo come evento dell'epoca 2.
- Nomenclatura "genti" + luogo; inizio al 6000 a.C. (i primi quattro secoli per mettere le pedine); recinto nell'epoca 2 come regolazione dello spazio; gruppi dell'epoca 2 capi, lignaggi, sacerdote, con attenzione agli equilibri di potere.
- Popolazione visibile come in Cities: Skylines, 3 modelli di uomini e 3 di donne con varianti, scala da verificare (800 persone a schermo sono troppe); pannelli di focus perché gli indicatori restano e servono a capire.

**Prossimo passo**
- Fede: guardare i risultati (carestie a zero: forse troppo facile; primi 100 anni uguali per tutti; abitanti sopra l'obiettivo del nucleo finché non ci sono i casali) e decidere se provare ora o dopo il pascolo.
- Claude: pascolo e bestiame (meccanica e primi modelli), poi luogo sacro con il sacerdote, scorrerie, sentieri che diventano strade, popolazione visibile; passo elastico con l'evento soglia.

## 25/11/2026
**Fatto**
- **Lettura degli ultimi aggiornamenti** e analisi con Fede dei risultati delle sessioni a dieci livelli: perché i primi 150 anni sono uguali per tutti (la crescita dipende solo dalla salute finché la terra basta) e perché c'è il tetto a 300 anni (contado al massimo dopo circa 100 abitanti, poi carestie a ripetizione).
- **Registro degli avvisi di cinque partite** (richiesta di Fede): nuovo `gioco/test/registro_avvisi.gd`. Per partita: 14 pause (6 per gli stranieri), 12 notifiche rosse, 34 grigie, una ventina di "carestie" da pochi punti; piene disastrose circa 5 per partita ma leggere; piene di stagione circa il 2% del raccolto; il consenso non ha effetti tranne la scissione. Risultati in `docs/sessioni-giocatori.md`.
- **Cronologia delle prime due epoche** per l'area emiliana, spiegata a Fede (Fiorano, vasi a bocca quadrata, Chassey, età del Rame; Polada, terramare e il loro crollo verso il 1150 a.C., Villanoviano e nascita di Felsina dall'unione di più villaggi). Da riportare nei documenti quando Fede avrà scelto la nomenclatura.
- **Documenti:** nuova sezione "La prima epoca: dinamiche" in `pilastri-e-decisioni.md`; todo riscritto con il nuovo ordine dei sistemi; recinto tolto dal villaggio anche in `regolazione-dello-spazio.md`; prologo nomade segnato come bocciato; comando del registro in `CLAUDE.md`.
- Tutte le 9 verifiche superate (nessun cambiamento al codice del gioco).

**Decisioni** (tutte di Fede, su proposte di Claude dove non detto)
- Il ritmo è l'ansia: il gioco deve restare meditativo, con Cities: Skylines come riferimento per il modo di gioco.
- Abbondanza come indicatore unico (cibo che avanza, salute, spazio); tappe di abitanti permanenti.
- Eventi che nascono dallo stato della partita: annate magre solo nell'accumulo del cibo, senza avvisi; carestie solo da cause in gioco; siccità sempre annunciate; piene che distruggono ma fertilizzano, disastrose rare e coerenti con sito e azioni; febbri; stranieri attirati dall'abbondanza; scorrerie. Niente avviso "zona agricola piena": basta la mappa (forse un indicatore, da pensare).
- Lettura sotto il puntatore per ogni strumento, come in fondazione.
- Risorse (cibo, legna, braccia, animali), case che crescono solo con la legna, cicli della terra e del rischio, pascolo, bosco sacro, effetti graduali del consenso per gruppo: approvati.
- Prologo nomade bocciato (il gioco è prima di tutto urbanistico). Orti calibrati sulla frustrazione e sulla crescita. Recinto legato alla pianificazione: prima epoca spontanea, seconda con regole.
- Mappe tematiche del todo: ok.

**Prossimo passo**
- Fede: scegliere la nomenclatura delle popolazioni nei testi del gioco (proposte di Claude in conversazione) e rispondere su inizio della partita e durata dell'epoca.
- Claude: cominciare dal punto 2.1 del todo (ritmo meditativo), misurando con `registro_avvisi.gd` prima e dopo; poi Abbondanza e tappe. Prima di toccare il codice, riepilogo a Fede e attesa del suo ok.

## 24/11/2026 (sera)
**Fatto**
- **Zona agricola che restava accesa** (segnalato da Fede): togliendo lo strumento (clic sul tasto o Esc) o con il puntatore fuori dal terreno, la funzione del pennello usciva prima di spegnere la zona. Ora la zona si vede solo con Zona agricola o Campo, in ogni caso. Quattro verifiche nuove in `test/verifica_partita.gd`.
- **Colonne del blocco Info che ballavano** (segnalato da Fede): il blocco si allargava quando i numeri crescevano (per esempio "2147 / 833 l'anno") e spingeva gli altri blocchi; in più le cifre di Inter hanno larghezze diverse. Ora il blocco ha larghezza fissa (300 px), la colonna dei nomi è fissa, i valori sono allineati a destra con cifre tabellari (`tnum`), e un valore troppo lungo si tronca con i puntini invece di allargare il blocco. Cifre tabellari anche per l'anno in alto. Regola in `docs/hud.md`; due verifiche nuove in `test/verifica_partita.gd`.
- **Zona agricola, di nuovo** (Fede: restava accesa passando a un altro strumento, per esempio Sentiero): con il codice di stasera la zona si spegne sia dal tasto sia con V; probabilmente la prova era sulla versione di prima del Pull. Aggiunte comunque le verifiche.
- **Tasto destro come Esc** (richiesta di Fede): un clic secco chiude le politiche, chiude la catena dei sentieri o toglie lo strumento; trascinato sposta la vista come prima (soglia di 5 px). Esc e clic destro usano la stessa funzione `annulla()` in `principale.gd`. Tasti aggiornati in `docs/hud.md`; due verifiche nuove in `test/verifica_partita.gd`.
- **Todo del villaggio completo** (richiesta di Fede: imbastire la fase successiva partendo da un todo; scelta di Fede: chiudere la prima epoca prima del protourbano): nuovo `docs/todo.md` con ciò che c'è, la taratura, gli otto sistemi mancanti in ordine proposto (gruppi di consenso, luogo sacro, legna e disboscamento, pascolo e riserva, scorrerie, sentieri che diventano strade, recinto da decidere, evento soglia "il metallo e lo scambio"), mappe, base tecnica e proposte aperte. `CLAUDE.md` ora dice di leggerlo a inizio sessione.
- **Sessioni di gioco a dieci livelli di bravura** (richiesta di Fede: lo scopo è creare una città, più abitanti è più successo; vedere come procedono gli abitanti a competenze diverse): nuovo `gioco/test/sessioni_giocatori.gd`, 180 partite (10 livelli × 6 siti × 3 semi). Livello 1: 229 abitanti di mediana a 500 anni; livello 10: 997. Crescita regolare con la bravura; primi 150 anni uguali per tutti; tetto verso i 300 anni (il contado di 800 m); il sito pesa quanto la bravura (gessi: 396 al massimo); una carestia ogni 20 anni circa dal livello 3. Corretto un difetto del giocatore automatico sul Dosso nelle paludi. Risultati, grafico e tre idee per gestire la crescita in `docs/sessioni-giocatori.md`.
- **Todo aggiornato** con le risposte di Fede: luogo sacro come cerchio di pali confermato; recinto spostato al protourbano; gruppi di consenso ok.
- Tutte le 9 verifiche superate. Il messaggio "3 resources still in use at exit" alla fine di `verifica_villaggio.gd` c'era già prima: da guardare quando capita.

**Decisioni**
- Fede: il clic destro deseleziona come Esc.
- Fede: la fase successiva è completare il villaggio (prima epoca) prima dell'abitato protourbano; si parte da un todo. L'ordine in `docs/todo.md` è una proposta di Claude.
- Fede: il luogo sacro è il cerchio di pali attorno a una pietra; il recinto appartiene al protourbano; ok ai tre gruppi di consenso nel blocco Info un solo indicatore, con il dettaglio dei tre gruppi al passaggio.
- Fede: lo scopo del gioco è creare una città; più abitanti è più successo, come in Cities: Skylines. Va trovata un'idea per gestirlo (proposte di Claude in `docs/sessioni-giocatori.md`); la scelta tra l'idea 1 (il tetto apre l'epoca) e la 2 (abitanti sul territorio) si fa dopo aver completato tutte le dinamiche della prima epoca.

**Prossimo passo**
- Fede: fare Pull e controllare zona agricola, blocco Info fermo e clic destro; rivedere `docs/todo.md` (ordine, e le voci con (?): come mostrare i tre gruppi di consenso, forma del luogo sacro, recinto nel villaggio o no).
- Fede: la scelta sulla crescita degli abitanti aspetta la prima epoca completa.
- Claude: completare le dinamiche della prima epoca nell'ordine di `docs/todo.md`, a partire dai gruppi di consenso; rifare le sessioni dopo ogni modifica che tocca la crescita.

## 24/11/2026
**Per riprendere (riepilogo di fine sessione, account di oggi)**
- Stato: Prototipo 0 giocabile in Godot con HUD a cinque blocchi (Info con fonti di cibo, Descrizione con opzioni dello strumento, Costruzione, Gestione con Politiche e Ammodernamento, Strumenti con Demolizione e Prova), lettura del sito in fondazione, zona agricola a pennello e campo a mano, sentieri liberi con anteprima, politiche (fonti di cibo, raccolto, stranieri), notifiche discrete. Tutte le 9 verifiche passano; ultimo lavoro caricato.
- Decisioni di fondo di oggi (tutte di Fede): ritmo meditativo, non incalzante; il gioco non cita altri giochi nei suoi testi; abitato e contado separati, sprawl come crescita di base; economia mista con rischi della vicinanza a fiumi e boschi; il campo cambia con l'epoca e l'ammodernamento sovrascrive il tipo vecchio; zona agricola automatica in quest'epoca; villaggio figlio tolto (al suo posto Emigrare).
- Da fare per primo: aspettare le prove di Fede sul villaggio e tarare (popolazioni, carestie, quantità di campi, peso di caccia e pesca). Proposte aperte: prologo nomade, orti disegnati più piccoli dentro il quadrato da 40 m, "Caccia regolata".
- Lavorando: Fede vuole conferma della ricezione delle modifiche prima di partire quando le richieste sono di design; sempre in italiano.

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
- **HUD** (decisioni di Fede: disposizione di Age of Empires, stile svizzero alla Noorda e Vignelli, colori solo con significato): nuova classe `Hud` (`gioco/script/hud.gd`). Fasce scure a filo dei bordi, testo bianco, scelta per inversione; mappe a destra con i bollini colorati come le linee della metro (blu acqua, verde fertilità, rosso piena e pericolo, giallo energia), sovrapposizioni e legenda; comandi a sinistra, oggi gli strumenti di prova dell'uso del suolo (abbattere, campi, costruire non invasivo e sigillato, liberare, +10 anni) con cerchio sulla mappa e raggio regolabile; lettura del lotto nella barra in basso. Regole e tasti in `docs/hud.md` (nuovo), immagine `docs/immagini/hud-24-11.jpg`, verifiche `test/verifica_hud.gd`.
- **Correzione sul disboscamento** (chiarimento di Fede): avevo aggiunto una dinamica in più, cioè strumenti per scegliere se costruire in modo invasivo o no. Fede intendeva invece che l'invasività è una **qualità nascosta del materiale** di edifici e strade: casa lunga (legno e argilla) tolta → il bosco ricresce nelle condizioni giuste; autostrada (asfalto) → no. Ora ogni costruzione ha i suoi materiali (`UsoSuolo.COSTRUZIONI`, `MATERIALI`), `uso.costruisci(celle, tipo)` ne ricava l'effetto, la lettura del lotto mostra solo "costruito". Tolti dall'HUD gli strumenti argilla/cemento/coltiva/libera; restano per prova Abbatti e +10 anni.
- **Menù logici** (decisione di Fede: come in Cities: Skylines e Age of Empires; Demolisci è trasversale, non una costruzione): i comandi ora stanno in schede (Insediamento: Fondare; Territorio: Campi; Vie: Sentiero; Edifici: Granaio; Usanze: raccolto in comune o alle famiglie) con i tasti della scheda aperta sotto; Demolisci a destra tra gli strumenti trasversali, +10 anni come Prova. Scegliere uno strumento ne apre la scheda e la scheda dello strumento spiega cosa fa. Nomi più chiari; tabella delle diciture in `docs/hud.md`.
- **Macerie solo per l'abitato spontaneo** (Fede: ottima idea, ma solo per le case che nascono da sole).
- **Niente più scacchiera di campi** (Fede: "cos'è tutto quello squadrettamento?"): erano i campi da 40 m della foto, tutti allineati alla griglia. Ora lo shader li disegna come parcelle irregolari allungate (circa 80 × 24 m) con prode erbose, e il contorno dei campi segue le parcelle.
- **Demolisci** (decisione di Fede, come in Cities: Skylines): al posto di "Abbatti", uno strumento unico (X, segno rosso perché irreversibile) che toglie nel cerchio alberi, case, campi, sentieri e granaio; non agisce su fiumi e paludi, che si governeranno con dighe, canali, deviazioni e bonifiche coerenti con l'epoca. Sul lotto di una casa demolita non ne rinasce una per 20 anni. Decisione scritta anche in `docs/pilastri-e-decisioni.md`, insieme a quella sui materiali.
- **Carattere Inter** nell'HUD (decisione di Fede: carattere con licenza SIL Open Font License, rispettandone le regole): file e licenza in `gioco/asset/caratteri/inter/` (con `LEGGIMI.md` su cosa chiede la licenza), nuovo `docs/licenze.md` con tutte le licenze di terze parti, regola aggiornata in `CLAUDE.md`. Verificato che il carattere di base di Godot 4.7.2 è Open Sans SemiBold, con la stessa licenza.
- **Minimappa e mappe tematiche più piccole** (Fede: cliccabili ma non importanti, come i tasti attorno alla minimappa di Age of Empires IV): minimappa di 150 px, bollini tondi delle mappe e quadratini delle sovrapposizioni accanto, legenda sottile solo quando serve.
- **HUD ridisposto come negli esempi di Age of Empires IV mandati da Fede** (conta la disposizione, non lo stile grafico): campo di gioco libero; in alto al centro anno e tempo, in alto a sinistra la cronaca; in basso a sinistra gli indicatori e la scheda dello strumento scelto; in basso al centro la griglia dei comandi a tasti quadrati; in basso a destra la nuova minimappa (`gioco/script/minimappa.gd`: ruotata come la vista, riquadro della camera, clic per spostarsi) con le mappe tematiche e la legenda; avvisi sopra la minimappa. Stile svizzero invariato. Dettagli in `docs/hud.md`.
- **Lettura del sito in fondazione** (Fede: indicatori del terreno più visibili e chiari, usando lo spazio di descrizione e menù): con Fondare la fascia in basso mostra il sito sotto il puntatore con sette voci, valore a parole e barra, rosso se sfavorevole. Immagine `docs/immagini/fondazione-24-11.jpg`.
- **Zona agricola a pennello** (Fede): tenendo premuto e trascinando si stende la zona; il messaggio dice gli ettari della pennellata. **Ancora meno campi** (Fede: ancora troppo simulatore di fattoria) e **più caccia e pesca** (Fede): resa dei campi 36, una casa ogni 5 abitanti, caccia fino a 0,6 e pesca fino a 0,35 di cibo per abitante con boschi e acque che offrono di più e selvaggina che si riprende prima. Dopo 150 anni: 224 abitanti, 45 case, 134 campi (3 per casa). Immagine `docs/immagini/zona-agricola-24-11.jpg` aggiornata.
- **Zona agricola e Campo** (decisione di Fede: automatismo come per le case in quest'epoca, doppia opzione sotto Territorio): la zona si disegna dentro il contado e le famiglie vi dissodano solo i campi che servono (fabbisogno meno caccia e pesca), un po' ogni anno, lasciando libero l'abitato; il Campo resta per metterli a mano. Nuova icona `zona_agricola`, tasto Z.
- **Meno "azienda agricola"** (Fede, con sarcasmo: sembrava un simulatore di fattoria): resa dei campi raddoppiata, una casa ogni 6 abitanti, campi secondo il bisogno e non secondo le braccia. A 123 abitanti: 21 case e 111 campi (prima 15 case e 390 campi). Immagine `docs/immagini/zona-agricola-24-11.jpg`.
- **Villaggio figlio tolto** (Fede: non esisteva a schermo): a 150 abitanti si sceglie tra Restare (più gente, più case) ed Emigrare (un terzo delle famiglie parte).
- **Suggerimento sulla Densità** (richiesta di Fede: la sigla ab/ha resta, ma al passaggio si spiega): abitanti per ettaro, come si calcola, quando diventa rossa.
- **Fonti di cibo** (proposta di Claude approvata da Fede): nuova politica con tre interruttori (Agricoltura, Caccia e raccolta, Pesca), almeno una accesa, braccia che passano alle fonti accese, −2 di consenso per cambio. Nel blocco Info la sezione "Fonti di cibo" (richiesta di Fede: leggibile da dove si attinge e quanto si usa la risorsa): "preso / disponibile" e barra della quota usata per Campi, Caccia, Pesca; un clic apre le politiche. Immagine `docs/immagini/fonti-cibo-24-11.jpg`.
- **Indicatori di caccia e pesca** (richiesta di Fede: se si caccia troppo, offerta di caccia e pesca): Caccia "preso / offerta" con la freccia della selvaggina e rosso quando si caccia troppo, Pesca "preso / offerta"; suggerimenti al passaggio sugli indicatori; notifica discreta "Si caccia troppo" sotto il 40% di selvaggina. Fede ha approvato il rischio del bosco (selvaggina che rovina i campi al margine).
- **Contado che cresce con gli abitanti** (decisione di Fede: il limite resta, è verosimile, ma non si percepiva): 400 m alla fondazione, fino a 800 m; con lo strumento Campi il confine si vede (linea tratteggiata) e un clic oltre il confine lo spiega. I sentieri non lo allargano più: **velocizzano l'accumulo di cibo** (+10% ai campi entro 120 m da un sentiero collegato o entro 200 m dal centro). Immagine `docs/immagini/contado-24-11.jpg`.
- **Economia mista** (decisione di Fede): caccia e raccolta dai boschi vicini, pesca dalle acque; la selvaggina cala se si caccia troppo; vicinanza premiata ma rischiosa (piene; selvaggina che rovina i campi al margine del bosco). Valutazione del sito con boschi e pesca, indicatori "Caccia e pesca" e "Densità". Popolazioni finali scese a 450–570 (prima oltre il migliaio); l'area dei gessi resta poverissima (da controllare).
- **Collega alla rete come opzione** dello strumento Sentiero (riga "Opzioni" nel blocco Descrizione, interruttore con quadratino); **Fondare** sparisce dopo la fondazione. Scelta a 150 abitanti: villaggio figlio o restare tutti (salute).
- **Niente riferimenti ad altri giochi nei testi del gioco** (Fede: il gioco è a sé stante): tolto "come in Cities" da descrizione e suggerimento del Sentiero; nuova regola in `CLAUDE.md` e verifica in `test/verifica_hud.gd`.
- **Documenti:** abitato e contado, sprawl, strumenti di espansione per epoca, economia mista in `docs/pilastri-e-decisioni.md`; prologo nomade annotato come proposta.
- **Ritmo meditativo** (Fede: in 500 anni troppi avvisi, esperienza ansiosa e frammentata): contate su tre partite 45–50 finestre che fermavano il gioco. Ora fermano il gioco solo le scelte vere (presagi, primo cattivo raccolto, affollamento, stranieri se "caso per caso"); piene, carestie, siccità e crisi sono **notifiche discrete** sopra la minimappa (rosse se pericolo, grigie se no, si spengono da sole, un clic porta la camera sul luogo). **Piene** di stagione (frequenti, solo campi bassi) e disastrose (rare, anche case); una piena che non tocca il villaggio non si nota. Presagi delle sorgenti e stranieri più rari. Immagine `docs/immagini/sentiero-anteprima-24-11.jpg`.
- **Sentieri come in Cities** (decisione di Fede): un clic dove comincia, uno dove finisce, poi si continua; Esc chiude. Inizio libero; tasto **Collega** (scheda Vie) per far partire ogni sentiero dal punto più vicino della rete. Anteprima: nastro trasparente bianco o rosso con la lunghezza o il motivo, quadratino d'inizio, rete schiarita. Solo i sentieri collegati al villaggio portano i campi più lontano.
- **Bug dei campi** (segnalato da Fede): un clic su un campo esistente abbandonava tutti i campi nel cerchio. Ora Campi aggiunge soltanto; si abbandona con Demolisci.
- **Ammodernamento come scheda di Gestione** (decisione di Fede: stesso livello delle politiche, poi settori agricolo, viario, abitativo…): tolto dal pannello delle politiche; ora la scheda Ammodernamento ha il tasto Agricolo (icona nuova `ammodernamento_agricolo`), spento finché non ci sono campi vecchi, invertito quando è attivo. Nella simulazione `ammodernamenti` per settore e `imposta_ammodernamento()`.
- **Niente squadrettamento tra sentiero e campi** (segnalato da Fede): i punti di sentiero da 40 m lasciavano un corridoio d'erba a scalini tra i campi. Ora campi e sentieri si disegnano insieme cella per cella: dalla parte dei campi rispetto alla linea vera del sentiero il campo arriva fino al nastro. Verifica in `test/verifica_partita.gd`. Immagine `docs/immagini/sentiero-campi-24-11.jpg`.
- **Fascia in basso a cinque blocchi** (decisione di Fede): Info, Descrizione, Costruzione (Insediamento, Territorio, Vie, Edifici), Gestione (Politiche), Strumenti (Demolizione, Prova). Costruzione, Gestione e Strumenti hanno tutti le schede, così il layout è pronto per le voci future; i blocchi hanno la stessa altezza. Il pannello delle politiche scorre se non c'è spazio. Immagine `docs/immagini/hud-cinque-blocchi-24-11.jpg`.
- **Campi del villaggio lavorati a mano** (Fede: le strisce sembravano fatte da un aratro meccanico; scelte A + B): orti a zappa in appezzamenti di famiglia di 20–40 m, file corte e ondulate lungo le curve di livello, zolle, ceppi, sassi, chiazze bruciate, bordi d'erbacce appena visibili. Immagine `docs/immagini/campi-zappa-24-11.jpg`.
- **Il campo cambia con l'epoca** (decisione di Fede, punto C): ogni campo ricorda la sua tecnica (dati in `SimVillaggio` e `UsoSuolo.tecniche`, disegno nello shader del terreno); i campi nuovi rendono di più, i vecchi restano. Nuova politica **Ammodernamento tecnologico** (sospeso/attivo): rifà un po' ogni anno i campi vecchi con la tecnica nuova pagando cibo, senza costruire niente da zero; nel villaggio è già nel pannello ma spenta. Prova con una tecnica nuova finta: `test/foto_partita.gd -- … tecniche`, immagine `docs/immagini/campi-ammodernamento-24-11.jpg` (al centro i campi rifatti, attorno quelli a zappa). Verifiche in `verifica_villaggio.gd`, `verifica_uso_suolo.gd`, `verifica_hud.gd`.
- **Campi rifatti** (Fede: le parcelle a macchia di leopardo non si capivano; dove non c'è un campo dev'esserci terreno normale, dove lo si pone si vede il campo): ora il campo occupa esattamente le celle poste, senza bordi interni, a strisce lunghe nello stesso verso, arate o seminate. Nelle foto i campi sono tanti perché il giocatore automatico ne pone quanti ne servono (circa 15 ha per 30 abitanti, con le regole del prototipo).
- **Griglia magnetica** (idea di Fede, come in Cities: Skylines): mentre si pone qualcosa compaiono attorno al puntatore i quadrati a cui lo strumento si aggancia, con quelli che verranno presi schiariti: celle da 40 m per i campi, lotti da 20 m per il granaio (l'edificio si aggancia al centro del lotto); il cerchio di Fondare si aggancia al punto della mappa. Immagini `docs/immagini/campi-griglia-24-11.jpg` e `docs/immagini/granaio-griglia-24-11.jpg`.
- **Strumenti come ultimo menù a destra** (decisione di Fede): Demolisci sta nella scheda Strumenti, che funziona come le altre; a destra restano Governo (Politiche) e Prova.
- **Quadrati dei campi come guida** (Fede: lo squadrettamento va bene nel momento in cui si pone una risorsa, pensava fosse un errore): con lo strumento Campi, dentro il cerchio compaiono le linee dei quadrati da 40 m su cui ragiona la simulazione; per il resto i campi restano parcelle irregolari. Immagine `docs/immagini/guida-campi-icone-24-11.jpg`.
- **Sentieri rifatti** (Fede: la fascia scura che attraversava campi e torrente non convinceva): ora sono un nastro di terra battuta largo 3,5 m lungo la linea vera del tracciato, che serpeggia di qualche metro, con due solchi e bordi sfrangiati; si interrompe ai guadi dei torrenti. Sotto, l'uso del suolo impedisce agli alberi di crescere ma non dipinge più le celle a gradini. Dettagli in `docs/resa-grafica.md`.
- **Politiche al posto del menù Usanze** (decisione di Fede: le usanze non sono oggetti da costruire, sono politiche; cominciare a introdurre questo genere di scelte): pannello a parte sopra la fascia, aperto dal tasto Politiche (P) nel nuovo gruppo Governo, che non ferma il tempo. Due politiche: **divisione del raccolto** (in comune / alle famiglie, come prima) e **accoglienza degli stranieri** (aperta / caso per caso / chiusa; proposta di Claude, vedi `docs/prototipo0-godot.md`): in media ogni 40 anni arriva un gruppo di stranieri; accolti portano braccia e tecniche nuove, qualche malattia e un po' di attrito. Cambiare una politica costa un po' di consenso. Immagine `docs/immagini/politiche-24-11.jpg`; verifiche in `test/verifica_villaggio.gd` e `test/verifica_hud.gd`.
- **Prime icone** (Fede: iniziamo a creare qualche icona): sette pittogrammi SVG fatti da noi in `gioco/asset/icone/` (fondare, campi, sentiero, granaio, demolisci, politiche, +10 anni), bianchi, tratti pieni e squadrati, senza colori; sui tasti stanno al centro con il nome sotto e la lettera del tasto piccola nell'angolo, e diventano neri quando il tasto è scelto. Regole e tabella in `docs/hud.md`.
- **Prototipo 0 in Godot, giocabile** (proposta accolta da Fede): simulazione del villaggio separata dalla grafica (`gioco/script/sim_villaggio.gd`), con le regole del prototipo web portate sulla mappa vera (campi a pixel da 40 m, case a lotti da 20 m, raggi convertiti; stessa economia, eventi e presagi); disegno con i modelli del villaggio e l'uso del suolo (`vista_villaggio.gd`: campi coltivati che tolgono gli alberi, sentieri e cortili di terra battuta, rovine); partita con tempo continuo, pausa e tre velocità, scelte che fermano il tempo, indicatori, cronaca (`partita.gd`). Ogni anno di gioco fa passare un anno anche all'uso del suolo (un campo abbandonato su un ex bosco ricresce). Campi disegnati come appezzamenti da 40 m con solchi e toni propri e prode erbose. Abitato spontaneo, niente recinto (decisione di Fede). Documento `docs/prototipo0-godot.md`, immagine `docs/immagini/prototipo0-godot-24-11.jpg`, verifiche `test/verifica_villaggio.gd` (500 anni per ogni sito: tutti abitabili) e `test/verifica_partita.gd`.

**Decisioni**
- Fede: il caricamento degli alberi va reso più rapido, ottimizzando o precaricando. Scelta di Claude: entrambe le cose, cioè calcolo ottimizzato e parallelo la prima volta, cache su disco precaricata all'avvio dalle volte successive.
- Fede: le prove sui PC (tempi degli alberi, fotogrammi al secondo) vanno in coda; il PC dedicato è pronto.
- Fede: le case demolite lasciano macerie solo nell'abitato spontaneo. Comandi in menù logici come in Cities: Skylines e Age of Empires; Demolisci è uno strumento trasversale, non una costruzione.
- Fede: strumento Demolisci come in Cities: Skylines per tutti gli elementi demolibili; fiumi e paludi si governano con altri strumenti (dighe, canali, deviazioni, bonifiche), ogni lavorazione coerente con l'epoca.
- Fede: usare il carattere Inter (licenza SIL Open Font License) rispettandone le regole.
- Fede: rimandati la taratura di dettaglio e densità degli alberi e il prato da vicino in 3D.
- Fede, **disboscamento** (chiarito poi: invasivo o no è una qualità nascosta dei materiali delle costruzioni, non una scelta): un'area disboscata resta in memoria come ex area boschiva. Se attorno ci sono altri alberi (è stata tagliata una parte del bosco), nel tempo nascono nuovi alberi, purché il terreno resti libero. Se il terreno viene edificato: con materiali non invasivi, tolto l'edificio e lasciato libero il terreno si torna alla condizione di prima (possono nascere nuovi alberi); con materiali invasivi (cemento, asfalto, fondamenta, fognature) l'area non accoglie più alberi, ma resta la memoria dell'origine boschiva. Gli effetti della rimozione degli alberi sono quelli naturali, come i vantaggi.
- Fede, **acqua:** inserire la meccanica della corrente (per mulini, turbine…) e i dislivelli per le dighe, oltre a rapide, cascate e livelli che cambiano con le piene.
- Fede: sistemare le carte delle chiome viste di taglio (dopo l'acqua, prima delle texture delle case).
- Fede: procedere con le texture di paglia e argilla e con il lotto del villaggio.
- Fede: **Prototipo 0 in Godot accolto**, giocabile (non solo resa grafica).
- Fede: niente recinto per ora; nelle epoche in cui è coerente **l'abitato cresce spontaneo**.
- Fede, **HUD:** disposizione come in Age of Empires, con i controlli delle mappe a destra e i comandi a sinistra. Lo stile è da definire.
- Fede, **stile dell'HUD:** design svizzero (segnaletica della metro di Milano di Noorda, di New York di Vignelli), che dialoghi con l'urbanistica, non invasivo né protagonista ma di carattere; colori con parsimonia e solo con un significato.
- Fede: in fondazione gli indicatori del terreno devono essere visibili e chiari; in quella modalità possono occupare lo spazio di descrizione e menù.
- Fede: zona agricola trascinabile come un pennello; ridurre ancora i campi rispetto alle case; caccia e pesca devono pesare di più.
- Fede: zona agricola automatica nel villaggio (poi i campi si gestiranno), doppia opzione Zona agricola / Campo; più gente più case; al posto del villaggio figlio, Emigra.
- Fede: approvata la politica a interruttori sulle fonti di cibo (agricoltura, caccia, pesca), con −2 di consenso e clic sull'indicatore che apre le politiche; nel blocco Info deve leggersi bene da quali fonti si attinge e quanto si usa la risorsa rispetto all'offerta.
- Fede: limite di 800 m mantenuto (verosimile, da verificare); il sentiero velocizza l'accumulo di cibo; l'espansione territoriale segue il numero di abitanti. Accettati: abitato e contado separati, sprawl come crescita di base che il piano incanala, strumenti di espansione per epoca, tecnica come alternativa all'espansione. Economia mista: la vicinanza a boschi e fiumi dà bonus ma espone ai rischi. Collega alla rete è un'opzione del Sentiero. Dopo la fondazione il tasto Fondare non serve. Nei testi del gioco niente riferimenti ad altri giochi.
- Fede: il ritmo del gioco non è incalzante ma meditativo, strategico. Piene e carestie non bloccano (A), bloccano solo le scelte vere (B), piene di stagione frequenti e disastrose rare, contano solo se toccano il villaggio (C), niente tregua tra le decisioni per ora (D), notifiche discrete per ciò che non chiede intervento (E). Sentieri esattamente come Cities, con "Collega alla rete" facoltativo: chi vuole reti complesse non deve essere vincolato. Campi: il clic aggiunge soltanto.
- Fede: l'ammodernamento va sotto Gestione, allo stesso livello delle politiche; dentro andranno i settori agricolo, viario (strade), abitativo e gli altri. Attenzione allo squadrettamento tra sentiero e campi.
- Fede: fascia in basso a cinque blocchi (info, descrizione, costruzione, gestione, strumenti), con le schede in costruzione, gestione e strumenti; Prova dentro Strumenti. Campi del villaggio a mano (A + B). Il campo cambia con l'epoca: i vecchi restano, i nuovi rendono di più; politica di ammodernamento tecnologico che sovrascrive il tipo vecchio, già presente e spenta nel villaggio; ammodernamento un po' ogni anno (proposta di Claude approvata).
- Fede: dove non c'è un campo il terreno è normale; i quadrati sono una griglia magnetica per porre edifici e campi, come in Cities: Skylines; Strumenti diventa l'ultimo menù a destra e funziona come gli altri. Icone, sentiero e politiche approvati.
- Fede: lo squadrettamento dei campi va bene come guida mentre si pongono; le usanze sono **politiche**, non costruzioni, e si comincia a introdurre questo genere di scelte; iniziare a creare le icone.
- Fede: ordine di lavoro 3 (disboscamento), 4 (acqua), 5 (carte di taglio), 6 (texture), 7 (villaggio), a (HUD), 8 (Prototipo 0 in Godot).

**Prossimo passo**
- Fede: fare Pull e **provare il Prototipo 0 in Godot** (F fondare con la lettura del sito, Z zona agricola a pennello, C campo, V sentiero con anteprima e opzione Collega alla rete, H granaio, P politiche e fonti di cibo, X demolisci, Spazio per il tempo) e l'HUD a cinque blocchi; dire cosa funziona, cosa no, come si legge l'interfaccia e se il villaggio sembra ancora troppo agricolo.
- Fede, da confermare: i numeri dell'economia mista e del contado (proposte di Claude); il prologo nomade; i numeri della politica sugli stranieri (proposta di Claude); le rese delle tecniche e i costi dell'ammodernamento (proposte di Claude); le regole dello stile dell'HUD (`docs/hud.md`); l'elenco dei materiali invasivi; il luogo sacro come cerchio di pali attorno a una pietra; le portate dei corsi d'acqua; i tempi della ricrescita del bosco; le specie degli alberi.
- In coda (Fede): prove sui PC dei tempi degli alberi ("alberi calcolati in … s" al primo avvio, "alberi dalla cache in … ms" al secondo) e dei fotogrammi al secondo a 150, 600, 2000 e 6000 m di vista.
- Rimandati da Fede: taratura di dettaglio e densità degli alberi; prato da vicino in 3D.
- Claude, prossime sessioni (proposte):
  - bilanciamento del villaggio dopo le prove di Fede: popolazioni finali di nuovo alte (1000–1400); carestie ancora numerose nelle partite automatiche;
  - abitato e sprawl nel villaggio (case che crescono anche oltre il bordo, densità come pressione) e mappe tematiche distinte di abitato e contado;
  - politica "Caccia regolata" o simili, solo se le fonti di cibo non bastano come leva;
  - effetti del disboscamento nella simulazione (erosione e frane sui pendii, piene più rapide, meno selvaggina; legname come risorsa);
  - mulini e dighe come costruzioni che usano la corrente e i dislivelli calcolati (dall'epoca in cui sono coerenti);
  - livelli dell'acqua che salgono con le piene nella grafica; cascate (servono salti nel letto dei torrenti);
  - varianti dei modelli del villaggio;
  - salvataggio della partita, con l'uso del suolo;
  - mappa tematica della memoria del suolo (ex boschi, aree sigillate).

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
