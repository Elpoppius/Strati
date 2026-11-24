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
- **In basso al centro, la griglia dei comandi:** tasti quadrati con la lettera del tasto in grande e il nome sotto, raggruppati (Villaggio, con Demolisci; Prove: +10 anni, per vedere la ricrescita del bosco). Un comando può essere uno strumento (resta scelto, si usa cliccando sulla mappa) o un'azione immediata. Il segno rosso nell'angolo vuol dire azione irreversibile.
- **In basso a destra, piccoli** (Fede: cliccabili ma non importanti, come i tasti attorno alla minimappa di Age of Empires IV): la minimappa (150 px) ruotata come la vista, con il riquadro di ciò che inquadra la camera e il centro del villaggio (un clic o un trascinamento spostano la camera); accanto, i bollini tondi delle cinque mappe tematiche (numero e colore, nome nel suggerimento) e i quadratini delle sovrapposizioni (G lotti, I isoipse). La mappa scelta ha un anello bianco. Sopra, solo quando è attiva una mappa tematica, una legenda sottile.
- **Avvisi** (siccità, carestie gravi) sopra la minimappa, a destra, con un segno rosso.
- **Scelte** (presagi, momenti decisivi, eventi): finestra al centro; il tempo si ferma finché non si sceglie.
- **Strumento sulla mappa:** un cerchio sottile bianco (rosso se l'azione è irreversibile) segue il puntatore; per Fondare mostra fin dove arriveranno i campi.

## Tasti
1–5 mappe · G griglia · I isoipse · F fondare · C campi · V sentiero · H granaio · Spazio pausa o riprendi · + e − velocità del tempo · X demolisci · Y +10 anni · [ e ] raggio dello strumento · Esc nessuno strumento · Q E ruota · rotella zoom · tasto destro o WASD sposta · Home torna al sito.

## Partita (Prototipo 0 in Godot)
- **Indicatori:** popolazione, cibo (scorta / consumo dell'anno), salute, legittimità. Rossi quando sono in pericolo (pochi abitanti, scorte sotto il 30% del consumo, salute sotto 45, legittimità sotto 30).
- **Comandi del gruppo Villaggio:** Fondare, Campi, Sentiero, Granaio, usanza sul raccolto (in comune o per famiglia).
- **Scelte:** finestra al centro, con tipo (presagio, momento decisivo, evento, crisi…), titolo, testo e opzioni con la loro conseguenza in grigio. Il tempo si ferma finché non si sceglie.
- **Avvisi:** sopra la minimappa con un segno rosso, solo per gli eventi rilevanti (siccità, carestie gravi).
