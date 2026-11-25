# Todo — Villaggio completo (prima epoca)

*Aperto il 24/11/2026 su richiesta di Fede: chiudere la prima epoca prima di passare all'abitato protourbano (principio: prima la profondità, poi l'ampiezza). Ordine e contenuti sono **proposte di Claude**: diventano decisioni quando Fede le conferma. Riferimento di design: `pilastri-e-decisioni.md`, sezione "Il villaggio (prima epoca)".*

Legenda: `[x]` fatto · `[~]` in parte · `[ ]` da fare · **(?)** serve una decisione di Fede prima di cominciare.

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
- [x] **Registro degli avvisi di cinque partite** (richiesta di Fede del 25/11/2026): 14 pause, 12 notifiche rosse e una ventina di piccole carestie per partita. Script `gioco/test/registro_avvisi.gd`, risultati in `docs/sessioni-giocatori.md`. Da rifare dopo ogni modifica al ritmo.
- [ ] **Come gestire la crescita degli abitanti.** Decisioni di Fede del 25/11/2026: Abbondanza (cibo che avanza, salute, spazio) e tappe permanenti, vedi la sezione 2. La scelta tra le idee 1 e 2 di `docs/sessioni-giocatori.md` resta rimandata alla prima epoca completa (decisione del 24/11/2026).
- [ ] Prove di Fede sul villaggio e taratura: carestie, quantità di campi, peso di caccia e pesca, area dei gessi poverissima. Gli orti si calibrano sulla frustrazione e sulla crescita (decisione di Fede del 25/11/2026).

## 2. Sistemi della prima epoca
*Decisioni di Fede del 25/11/2026, dettagli in `era-origini.md` e in `pilastri-e-decisioni.md`, sezione "La prima epoca: dinamiche". Regola: ogni sistema prende o dà qualcosa a un altro, muove un gruppo di consenso e lascia una traccia sulla mappa. L'ordine è una proposta di Claude.*
1. [x] **Ritmo meditativo** (fatto il 25/11/2026: 4,8 pause e 2 notifiche rosse per partita): annate magre senza avvisi; carestie solo da cause in gioco; siccità sempre annunciate; pause solo la prima volta di ogni evento, per i presagi e per l'evento soglia; stranieri attirati dall'abbondanza e governati dalla politica; niente avviso "zona agricola piena" (basta la mappa). Viene prima perché tocca tutto il resto e si misura subito con `registro_avvisi.gd`.
2. [x] **Abbondanza e tappe** (fatto il 25/11/2026, con il pannello di focus e la tappa accanto all'anno): indicatore unico con tre parti al passaggio; nascite legate all'abbondanza; tappe permanenti (soglie di partenza in `pilastri-e-decisioni.md`).
3. [~] **Gruppi di consenso: anziani, famiglie, sacerdote** (anziani e famiglie fatti il 25/11/2026; il sacerdote arriva con il luogo sacro), un solo indicatore con il dettaglio al passaggio (decisione del 24/11/2026), con gli effetti graduali per gruppo (regole, lavoro, presagi).
4. [~] **Risorse: legna e braccia** (legna, costi, cantiere del granaio e case che chiedono legna fatti il 25/11/2026; resta il cantiere per il luogo sacro e l'erosione dei pendii). Costi in legna e braccia per granaio e luogo sacro, cantieri di qualche anno, dissodamento che dà legna, case spontanee solo con la legna. Con gli **effetti del disboscamento** (erosione, piene, selvaggina).
5. [x] **Piene che distruggono e fertilizzano** (fatto il 25/11/2026, nella simulazione; l'acqua che sale nella grafica resta nella base tecnica): limo sui campi allagati; disastrose rare, legate a sito e azioni (bosco tagliato a monte), annunciate e visibili sulla mappa. Con le **febbri** (paludi, affollamento).
6. [x] **Lettura sotto il puntatore per ogni strumento** (fatto il 25/11/2026: zona, campo, granaio, sentiero), come in fondazione.
6b. [x] **Legnaia** (decisione di Fede del 25/11/2026, fatta lo stesso giorno): obbligatoria per raccogliere legna, taglio visibile sulla mappa, raccolta che rallenta man mano che la radura si allarga.
6c. [ ] **Capanno da pesca e Posta di caccia** (approvati da Fede il 25/11/2026): stessa dinamica della legnaia, vicinanza all'acqua e al bosco fitto con selvaggina; senza edificio caccia e pesca rendono circa un terzo.
6d. [x] **Carestie B + C e casali** (decisioni di Fede del 25/11/2026, fatti lo stesso giorno).
7. [ ] **Pascolo e animali:** campo che si stanca, maggese a pascolo, concime, scorta viva, radure aperte, erosione sui pendii.
8. [ ] **Luogo sacro e bosco sacro** (cerchio di pali attorno a una pietra, forma confermata il 24/11/2026): peso al sacerdote, lettura dei presagi; la riserva diventa il bosco sacro.
9. [ ] **Scorrerie** attirate dalla ricchezza e dai margini poco usati; segni prima; abitato compatto e sito come difesa.
10. [ ] **I sentieri più usati diventano strade** (traffico di campi, pascoli, legna, luogo sacro). Con i **casali** nel contado.
11. [ ] **Evento soglia "il metallo e lo scambio"**, che chiude l'epoca.

- [ ] **Passo elastico** (deciso il 25/11/2026): un anno per passo nei primi quattro secoli, poi un decennio; da fare insieme all'evento soglia.
- [ ] **Popolazione visibile** (decisa il 25/11/2026): 3 modelli di uomini e 3 di donne, bestiame, scala da misurare; prima il bestiame con il pascolo.

## 3. Leggere la mappa (ok di Fede del 25/11/2026)
- [ ] Mappa tematica **boschi e selvaggina** (prevista dal design del villaggio).
- [ ] Mappe distinte di **abitato** e **contado** (decisione di Fede del 24/11/2026).
- [ ] Mappa della **memoria del suolo** (ex boschi, aree sigillate).

## 4. Base tecnica
- [ ] **Salvataggio della partita**, con l'uso del suolo.
- [ ] Livelli dell'acqua che salgono con le piene, nella grafica.
- [ ] Varianti dei modelli del villaggio.
- [ ] Prove sui PC di Fede (in coda): tempi degli alberi e fotogrammi al secondo.

## Per l'abitato protourbano (dopo il villaggio)
- Recinto o palizzata, con terrapieno e fossato: appartiene alla pianificazione urbana; nella prima epoca gli insediamenti sono spontanei, nella seconda cominciano a darsi delle regole (decisioni di Fede del 24 e 25/11/2026).

## Da decidere
- Nomenclatura delle popolazioni: **decisa** il 25/11/2026 ("genti" più il luogo; vedi `era-origini.md`).
- Inizio della partita: **resta il 6000 a.C.** (Fede, 25/11/2026: i primi quattro secoli servono a mettere le pedine).
- Come scorre il tempo nell'epoca 1: **deciso** il 25/11/2026 il passo elastico (un anno per passo nei primi quattro secoli, poi un decennio; `era-origini.md`, § 2).
- **(?)** Politica "Caccia regolata", solo se le fonti di cibo non bastano come leva.
- **(?)** Orti disegnati più piccoli dentro il quadrato da 40 m.
- Prologo nomade: **bocciato** da Fede il 25/11/2026 (il gioco è prima di tutto urbanistico).
