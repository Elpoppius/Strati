# HUD

*Interfaccia a schermo. Codice: `gioco/script/hud.gd` (classe `Hud`), collegata in `gioco/script/principale.gd`. Immagine: `docs/immagini/hud-24-11.jpg`.*

## Decisioni di Fede (24/11/2026)
- **Disposizione** come in Age of Empires: **controlli delle mappe a destra, comandi a sinistra**.
- **Stile svizzero**, quello della segnaletica della metropolitana di Milano (Noorda) e di New York (Vignelli): deve dialogare con l'urbanistica, presente ma non invasivo né protagonista, con carattere.
- **Colori solo con un significato**, senza esagerare.

## Regole dello stile (proposta di Claude, da confermare con Fede)
- **Riquadri scuri a filo dei bordi** dello schermo, testo bianco, niente angoli arrotondati né ombre. Righe sottili per separare le sezioni.
- **Gerarchia con grandezza e peso del testo**, non con il colore. Intestazioni di sezione in maiuscolo, piccole, spaziate, grigie, sopra una riga sottile.
- **Scelta corrente per inversione:** fondo bianco e testo nero, come un cartello.
- **Colori con significato:**
  | Colore | Significato |
  |---|---|
  | grigio chiaro | Terreno (mappa neutra) |
  | blu | Acqua |
  | verde | Fertilità |
  | rosso | Rischio di piena; in generale **pericolo o azione irreversibile** |
  | giallo | Energia dell'acqua |

  Ogni mappa tematica ha il suo bollino tondo con il numero del tasto, come una linea della metropolitana. I comandi hanno un quadratino con la lettera del tasto, senza colore, tranne quelli irreversibili (bollino rosso). Le legende delle mappe usano gli stessi colori del bollino.
- **Carattere: Inter** (decisione di Fede del 24/11/2026: un carattere con licenza SIL Open Font License, rispettandone le regole), il più vicino all'Helvetica della grafica svizzera. Regular per i testi, Medium di base, Bold per titoli, valori e lettere dei tasti. File e licenza in `gioco/asset/caratteri/inter/`, elenco delle licenze in `docs/licenze.md`.

## Disposizione (esempi di Age of Empires IV mandati da Fede, 24/11/2026)
Il campo di gioco resta libero: l'interfaccia sta in una fascia in basso e in due piccoli riquadri in alto.
- **In alto al centro:** l'anno e i comandi del tempo (pausa, 2, 6 e 15 anni al secondo), come l'indicatore dell'età.
- **In alto a sinistra:** la cronaca, gli ultimi quattro fatti, come gli obiettivi.
- **In alto a destra:** le prestazioni (fotogrammi al secondo, alberi, cache), piccole, senza fondo.
- **In basso a sinistra:** gli indicatori (popolazione, cibo, salute, legittimità), come le risorse; il valore diventa rosso quando è in pericolo.
- **Accanto, la scheda dello strumento scelto** (come la scheda dell'unità selezionata): nome, messaggio dell'ultima azione, lettura del lotto sotto il puntatore.
- **In basso al centro, i comandi su due livelli** (decisione di Fede: menù logici come in Cities: Skylines e Age of Empires): in alto le **schede dei menù** (Insediamento, Territorio, Vie, Edifici e, ultima a destra e un po' staccata, **Strumenti**: decisione di Fede, funziona come gli altri menù), sotto i **tasti** della scheda aperta (quadrati: pittogramma al centro, nome sotto, lettera del tasto piccola e grigia nell'angolo) e una riga che dice a cosa serve il menù. Scegliere uno strumento, anche da tastiera, apre la sua scheda. Demolisci sta nel menù Strumenti: vale su tutto e non è una costruzione. A destra, separati da una riga, il **Governo** (Politiche) e la **Prova** (+10 anni, solo per vedere la ricrescita del bosco). Un comando può essere uno strumento (resta scelto, si usa cliccando sulla mappa) o un'azione immediata. Il segno rosso nell'angolo vuol dire azione irreversibile. Scelto uno strumento, la scheda a sinistra ne mostra il nome e cosa fa.
- **In basso a destra, piccoli** (Fede: cliccabili ma non importanti, come i tasti attorno alla minimappa di Age of Empires IV): la minimappa (150 px) ruotata come la vista, con il riquadro di ciò che inquadra la camera e il centro del villaggio (un clic o un trascinamento spostano la camera); accanto, i bollini tondi delle cinque mappe tematiche (numero e colore, nome nel suggerimento) e i quadratini delle sovrapposizioni (G lotti, I isoipse). La mappa scelta ha un anello bianco. Sopra, solo quando è attiva una mappa tematica, una legenda sottile.
- **Politiche** (decisione di Fede del 24/11/2026: le usanze non sono oggetti da costruire, sono politiche): pannello a parte, sopra la fascia, che si apre e si chiude con il tasto Politiche (P) e non ferma il tempo. Ogni politica ha un titolo, una riga che dice di cosa si tratta, le opzioni come tasti (quella in vigore è invertita) e sotto cosa comporta quella in vigore. Cambiarne una costa un po' di consenso.
- **Avvisi** (siccità, carestie gravi) sopra la minimappa, a destra, con un segno rosso.
- **Scelte** (presagi, momenti decisivi, eventi): finestra al centro; il tempo si ferma finché non si sceglie.
- **Strumento sulla mappa:** un cerchio sottile bianco (rosso se l'azione è irreversibile) segue il puntatore; per Fondare mostra fin dove arriveranno i campi. 
- **Griglia magnetica** (idea di Fede, come in Cities: Skylines): mentre si pone qualcosa, attorno al puntatore compaiono i quadrati a cui lo strumento si aggancia, e si schiariscono quelli che verranno presi. Campi: celle da 40 m della simulazione, prese se il loro centro sta nel cerchio. Granaio: lotti da 20 m, l'edificio si aggancia al centro del lotto. Fondare: il cerchio si aggancia al punto della mappa più vicino (niente griglia, il cerchio è di 800 m). Fuori da questi momenti la griglia non si vede.

## Pittogrammi
In `gioco/asset/icone/`, SVG fatti da noi: bianchi su trasparente, 28 px su una griglia di 32, tratti pieni e squadrati, nessun colore (il colore resta per i significati: il segno rosso dell'irreversibile sta sul tasto, non nell'icona). Nell'HUD si tingono di nero quando il tasto è scelto. Si aggiungono a una voce con `"icona": "nome"`.

| Icona | Comando | Figura |
|---|---|---|
| `fonda` | Fondare | palo piantato con la bandiera |
| `campi` | Campi | due appezzamenti con i solchi in versi diversi |
| `sentiero` | Sentiero | traccia a tratti che serpeggia tra due punti |
| `granaio` | Granaio | casa delle scorte su pali |
| `demolisci` | Demolisci | costruzione cancellata da una croce |
| `politiche` | Politiche | anziani seduti in cerchio attorno al fuoco |
| `anni` | +10 anni | clessidra |

Sono una prima serie (proposta di Claude), da confermare con Fede.

## Diciture
| Dicitura | Dove | Significato |
|---|---|---|
| Popolazione | indicatori | abitanti del villaggio |
| Cibo 543 / 121 l'anno | indicatori | scorte di cibo / quanto ne consuma il villaggio in un anno (rosso se le scorte sono sotto il 30% del consumo) |
| Salute | indicatori | da 0 a 100: acqua, aria (paludi), affollamento, fame |
| Legittimità | indicatori | da 0 a 100: quanto il villaggio riconosce l'autorità di chi governa (nella prima epoca gli anziani); sotto 5 per quattro anni il villaggio si divide |
| ‖ 2 6 15 | in alto, accanto all'anno | pausa, oppure 2, 6, 15 anni al secondo |
| Insediamento, Territorio, Vie, Edifici | schede dei comandi | menù logici: dove nasce il villaggio; a cosa si destina la terra; come ci si muove; costruzioni comuni |
| Politiche | Governo | apre il pannello delle regole del villaggio (P) |
| In comune / Alle famiglie | Politiche: divisione del raccolto | il raccolto si divide tra tutti (più legittimità) o ogni famiglia tiene il suo (più raccolto, meno legittimità) |
| Aperta / Caso per caso / Chiusa | Politiche: accoglienza degli stranieri | chi arriva resta sempre; a ogni arrivo si decide; viene sempre mandato via |
| Strumenti | schede dei comandi | ultimo menù: comandi che valgono su tutto e non sono costruzioni |
| Demolisci | Strumenti | toglie ciò che si può demolire nel cerchio; non agisce su fiumi e paludi |
| +10 anni | Prova | fa passare dieci anni subito, solo per provare la ricrescita del bosco |
| 1–5 | bollini accanto alla minimappa | mappe tematiche: terreno, acqua, fertilità, rischio di piena, energia dell'acqua |
| G, I | quadratini accanto alla minimappa | griglia dei lotti da 20 m, isoipse ogni 25 m |
| fps, alberi (livello), cache | in alto a destra | prestazioni, per le prove sui PC |

## Tasti
1–5 mappe · G griglia · I isoipse · F fondare · C campi · V sentiero · H granaio · Spazio pausa o riprendi · + e − velocità del tempo · X demolisci · P politiche · Y +10 anni · [ e ] raggio dello strumento · Esc chiude le politiche o toglie lo strumento · Q E ruota · rotella zoom · tasto destro o WASD sposta · Home torna al sito.

## Partita (Prototipo 0 in Godot)
- **Indicatori:** popolazione, cibo (scorta / consumo dell'anno), salute, legittimità. Rossi quando sono in pericolo (pochi abitanti, scorte sotto il 30% del consumo, salute sotto 45, legittimità sotto 30).
- **Comandi:** Fondare, Campi, Sentiero, Granaio; politiche a parte (divisione del raccolto, accoglienza degli stranieri).
- **Scelte:** finestra al centro, con tipo (presagio, momento decisivo, evento, crisi…), titolo, testo e opzioni con la loro conseguenza in grigio. Il tempo si ferma finché non si sceglie.
- **Avvisi:** sopra la minimappa con un segno rosso, solo per gli eventi rilevanti (siccità, carestie gravi).
