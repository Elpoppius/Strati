# Sessioni di gioco automatiche: dieci livelli di bravura

*24/11/2026. Richiesta di Fede: preparare sessioni di gioco a livelli di competenza diversi e vedere come procedono gli abitanti, perché lo scopo del gioco è creare una città e più abitanti è più successo (come in Cities: Skylines). Le proposte in fondo sono di Claude, da discutere.*

## Come sono fatte
- Script: `gioco/test/sessioni_giocatori.gd` (uso nella testa del file). Gioca soltanto la simulazione (`SimVillaggio`), senza grafica.
- **180 partite:** 10 livelli × 6 siti di fondazione × 3 semi, 500 anni ciascuna (6000–5500 a.C.). Nell'ambiente di Claude ci vogliono circa 25 minuti.
- **Cosa cambia con la bravura** (livello k da 1 a 10):
  - attenzione: ogni quanti anni il giocatore guarda la mappa (da 50 a 5);
  - zona agricola: quanta parte del contado copre (dal 46% al 100%); ai livelli 1–2 la si allarga solo quando arriva la notifica "zona piena"; dal 6 si evitano le terre a rischio di piena alto, dall'8 anche quelle a rischio medio, a meno che la terra sicura sia meno del 40%;
  - granaio dal livello 3; sentieri radiali collegati dal 5 (uno per livello oltre il 4, fino a 6);
  - scelte: la risposta giusta per la crescita con probabilità (k − 1) / 9, altrimenti una a caso (giuste: razionare con le sorgenti basse, ignorare la cometa, accogliere gli stranieri, restare quando c'è affollamento, cacciare o razionare al primo cattivo raccolto);
  - dal 6 la divisione del raccolto (alle famiglie se il consenso regge, altrimenti in comune); dal 7 la caccia sospesa quando la selvaggina crolla.
- Un difetto del giocatore automatico trovato strada facendo: sul Dosso nelle paludi i livelli 8–10, evitando tutta la terra a rischio di piena, restavano senza campi e morivano di fame. Corretto (accettano il rischio se la terra sicura è troppo poca) e rigiocato quel sito; gli altri risultati non cambiano.

## Risultati
![Abitanti per livello di bravura](immagini/sessioni-giocatori-24-11.png)

| Livello | Abitanti a 500 anni (mediana) | Minimo – massimo | Massimo raggiunto (mediana) | Anni per arrivare a 300 | Partite oltre 1000 | Carestie per partita |
|---|---|---|---|---|---|---|
| 1 | 229 | 127 – 414 | 271 | 269 (6 partite su 18) | 0 | 8 |
| 2 | 310 | 146 – 451 | 360 | 236 (12/18) | 0 | 8 |
| 3 | 415 | 178 – 586 | 493 | 235 (15/18) | 0 | 24 |
| 4 | 512 | 207 – 628 | 608 | 237 (15/18) | 0 | 24 |
| 5 | 576 | 246 – 749 | 708 | 218 (16/18) | 0 | 23 |
| 6 | 592 | 260 – 798 | 824 | 192 | 0 | 29 |
| 7 | 690 | 319 – 871 | 924 | 200 | 6 | 24 |
| 8 | 783 | 323 – 1072 | 989 | 193 | 9 | 26 |
| 9 | 882 | 345 – 1034 | 1109 | 191 | 15 | 26 |
| 10 | 997 | 391 – 1212 | 1238 | 191 | 15 | 24 |

Nessun abbandono in nessuna partita.

**Per sito** (mediana a 500 anni, livello 1 → 10): Terrazzo centrale 246 → 1055; Sbocco del fiume 343 → 918; Sperone collinare 179 → 1081; Dosso nelle paludi 300 → 1042; Area dei gessi 127 → 396; Pianura aperta 211 → 988.

## Cosa si vede
1. **La bravura conta, e in modo regolare:** dal livello 1 al 10 gli abitanti finali crescono di oltre quattro volte, senza salti né inversioni. Il gioco premia chi gioca meglio.
2. **I primi 150 anni sono uguali per tutti:** a 100 anni ogni livello è tra 90 e 106 abitanti. Le scelte del giocatore cominciano a pesare solo dopo: nella prima parte della partita la bravura non si vede.
3. **Tetto verso i 300 anni:** tutte le curve si appiattiscono, e negli ultimi 100 anni calano un po' (il massimo raggiunto è sopra il valore finale a ogni livello). Il limite è la terra: il contado arriva al massimo a 800 m, e chi gioca bene lo riempie prima. Gli ultimi due secoli del villaggio scorrono senza crescita.
4. **Il sito pesa quanto la bravura:** nell'area dei gessi il giocatore migliore arriva a 396, meno di un giocatore di livello 3 sul Terrazzo centrale. La fondazione è davvero la decisione più importante.
5. **Carestie frequenti** dal livello 3 in su, circa una ogni 20 anni: chi spinge la crescita vive al limite. Non fanno abbandonare il villaggio, ma pesano sul ritmo meditativo.
6. **Confronto con la realtà:** per Çatalhöyük, il villaggio neolitico più grande conosciuto, le stime recenti (Kuijt e Marciniak, 2024) sono di 600–800 abitanti al massimo, contro i 3.500–10.000 delle stime precedenti. I nostri villaggi dal livello 7 in su lo superano. Quanto fossero grandi i villaggi neolitici comuni dell'Europa non l'ho verificato.

## Idee per gestire la crescita (proposte di Claude, da discutere)
L'obiettivo di Fede: più abitanti è più successo. Le idee cercano di tenerlo insieme alla verosimiglianza, senza togliere al giocatore il gusto di crescere.

1. **Il tetto apre l'epoca successiva.** Il tetto di terra che si vede a 300 anni diventa il motore: quando il villaggio riempie il contado, la pressione porta all'evento soglia "il metallo e lo scambio". Il giocatore bravo ci arriva prima e più grande; quello alle prime armi resta più a lungo nel villaggio. La durata dell'epoca diventa variabile, e gli ultimi due secoli senza crescita spariscono.
2. **Gli abitanti si contano sul territorio, non solo nel villaggio.** Oltre una certa densità le famiglie fondano casali nel contado: è lo sprawl che Fede ha già deciso come crescita di base. Il villaggio resta verosimile (qualche centinaio), il territorio ospita il resto, e nel protourbano i casali si uniscono nel centro (il sinecismo, il modo in cui sono nate molte città antiche). Il successo è la somma. A differenza del villaggio figlio tolto, i casali devono vedersi sulla mappa.
3. **Rendere la bravura visibile fin dall'inizio.** Oggi i primi 150 anni sono uguali per tutti: le prime scelte (sito, zona, caccia e pesca) dovrebbero già cambiare la velocità di crescita, così il giocatore vede subito l'effetto di ciò che fa.

## Registro degli avvisi di cinque partite (25/11/2026)
*Richiesta di Fede: vedere quali avvisi escono a schermo e nella cronaca, quanti sono e quanto pesano le piene.* Script `gioco/test/registro_avvisi.gd` (5 siti, giocatore di livello 5, 500 anni ciascuna).

| Per partita (media) | Quanti | Da cosa |
|---|---|---|
| Pause | 14 | stranieri 6, sorgenti 3, cometa 3, primo cattivo raccolto 1, affollamento 1 |
| Notifiche rosse | 12 | siccità 7, piene disastrose 4–5 |
| Notifiche grigie | 34 | "zona agricola piena" circa 10 (ogni 25 anni dopo il trecentesimo); piene di stagione solo sullo Sbocco del fiume (121 in quella partita) |
| Righe di cronaca | 86 | 29 rosse, quasi tutte "Carestia" |

- A 2 anni al secondo una partita dura circa 4 minuti: una pausa ogni 17 secondi circa.
- Le carestie sono 10–28 per partita, ma quasi tutte di pochi punti (manca l'1–20% del cibo): annate magre più che carestie.
- Le piene disastrose, pensate rare, sono circa 5 per partita su 4 siti su 5, ma pesano poco (34 case perse: circa 85 abitanti e −3 di consenso, recuperati in pochi anni).
- Le piene di stagione allagano in media l'8,6% dei campi una volta ogni 4 anni (circa il 2% del raccolto): oggi sono solo narrazione.
- Il consenso ha un solo effetto, la scissione sotto 5 per 4 anni; nelle cinque partite è sempre finito tra 56 e 63.

Le decisioni che ne sono venute (Fede, 25/11/2026) stanno in `pilastri-e-decisioni.md`, sezione "La prima epoca: dinamiche".
