# Todo — Villaggio completo (prima epoca)

*Aperto il 24/11/2026 su richiesta di Fede: chiudere la prima epoca prima di passare all'abitato protourbano (principio: prima la profondità, poi l'ampiezza). Ordine e contenuti sono **proposte di Claude**: diventano decisioni quando Fede le conferma. Riferimento di design: `pilastri-e-decisioni.md`, sezione "Il villaggio (prima epoca)".*

Legenda: `[x]` fatto · `[ ]` da fare · **(?)** serve una decisione di Fede prima di cominciare.

## Già nel gioco
- [x] Fondare con la lettura del sito; rovine e rifondazione (il fallimento come strato)
- [x] Zona agricola a pennello, campo a mano, contado che cresce con gli abitanti
- [x] Sentieri con anteprima e Collega alla rete; granaio
- [x] Politiche: divisione del raccolto, stranieri, fonti di cibo; ammodernamento (spento nel villaggio)
- [x] Economia mista: campi, caccia e raccolta, pesca, selvaggina
- [x] Eventi: piene di stagione e disastrose, siccità con presagio vero, cometa come presagio falso, primo cattivo raccolto, affollamento (restare o emigrare)
- [x] Abitato spontaneo, demolizione con macerie, notifiche discrete

## 1. Prima di tutto
- [x] **Sessioni di gioco automatiche a dieci livelli di bravura** (richiesta di Fede del 24/11/2026): 180 partite, dal livello 1 (229 abitanti di mediana a 500 anni) al 10 (997); tetto verso i 300 anni; primi 150 anni uguali per tutti. Script `gioco/test/sessioni_giocatori.gd`; risultati e idee in `docs/sessioni-giocatori.md`. Da rifare dopo ogni modifica che tocca la crescita.
- [ ] **Come gestire la crescita degli abitanti** (Fede, 24/11/2026: lo scopo del gioco è creare una città; più abitanti è più successo, come in Cities: Skylines). Va trovata un'idea che tenga insieme il successo misurato in abitanti e la verosimiglianza di un villaggio neolitico (Çatalhöyük, il più grande, oggi è stimato a 600–800 abitanti; i nostri livelli 7–10 lo superano). Tre proposte di Claude in `docs/sessioni-giocatori.md`: il tetto di terra apre l'epoca successiva; abitanti contati sul territorio con i casali dello sprawl; bravura visibile fin dai primi anni. **Decisione di Fede (24/11/2026): la scelta tra 1 e 2 si fa dopo, con la prima epoca completa di tutte le dinamiche.** Fino ad allora la crescita non si ritocca.
- [ ] Prove di Fede sul villaggio e taratura: carestie, quantità di campi, peso di caccia e pesca, area dei gessi poverissima.

## 2. Sistemi mancanti dal design della prima epoca
1. [ ] **Gruppi di consenso: anziani, famiglie, sacerdote** (Fede: ok). La legittimità unica si divide in tre, ognuno con le sue attese (anziani: cibo e usanze; famiglie: raccolto e case; sacerdote: presagi e luogo sacro). Viene prima perché luogo sacro, scorrerie e politiche ci si appoggiano. Nel blocco Info **un solo indicatore**, con il dettaglio dei tre gruppi al passaggio (decisione di Fede del 24/11/2026).
2. [ ] **Luogo sacro** (il modello c'è già: cerchio di pali attorno a una pietra; forma confermata da Fede il 24/11/2026). Costruzione unica che dà peso al sacerdote e cambia come si accolgono i presagi; è il germe di tempio, chiesa e piazza nelle epoche successive.
3. [ ] **Legna come risorsa.** Il legname di Demolisci diventa una scorta: serve per case, granaio e focolari; si prende dai boschi vicini. Con gli **effetti del disboscamento** nella simulazione: erosione sui pendii, piene più rapide, meno selvaggina.
4. [ ] **Pascolo e animali** (il modello del recinto per gli animali c'è già). Nuova destinazione del territorio accanto alla zona agricola: rende meno dei campi ma regge le annate cattive. Più la **riserva**: un bosco da non toccare per la caccia e la legna.
5. [ ] **Scorrerie** ai margini del contado, più probabili dove il contado è rivendicato e poco usato; la difesa del sito (già nella valutazione) conta davvero.
6. [ ] **I sentieri più usati diventano strade:** traccia d'uso dei sentieri (case e campi serviti); i più battuti si allargano e restano come assi nelle epoche dopo. Primo segno visibile della stratificazione.
7. [ ] **Evento soglia "il metallo e lo scambio"**, che chiude l'epoca: presagi (mercanti, oggetti di rame), la scelta di aprirsi agli scambi, il passaggio all'epoca successiva con il riepilogo del villaggio. Viene per ultimo perché riassume tutto il resto.

## 3. Leggere la mappa
- [ ] Mappa tematica **boschi e selvaggina** (prevista dal design del villaggio).
- [ ] Mappe distinte di **abitato** e **contado** (decisione di Fede del 24/11/2026).
- [ ] Mappa della **memoria del suolo** (ex boschi, aree sigillate).

## 4. Base tecnica
- [ ] **Salvataggio della partita**, con l'uso del suolo.
- [ ] Livelli dell'acqua che salgono con le piene, nella grafica.
- [ ] Varianti dei modelli del villaggio.
- [ ] Prove sui PC di Fede (in coda): tempi degli alberi e fotogrammi al secondo.

## Per l'abitato protourbano (dopo il villaggio)
- Recinto o palizzata: appartiene al protourbano, non al villaggio (decisione di Fede del 24/11/2026).

## Proposte aperte (da decidere, fuori dall'ordine)
- **(?)** Prologo nomade prima della fondazione (cacciatori-raccoglitori, accampamenti stagionali).
- **(?)** Politica "Caccia regolata", solo se le fonti di cibo non bastano come leva.
- **(?)** Orti disegnati più piccoli dentro il quadrato da 40 m.
