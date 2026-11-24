# HUD

*Interfaccia a schermo. Codice: `gioco/script/hud.gd` (classe `Hud`), collegata in `gioco/script/principale.gd`. Immagine: `docs/immagini/hud-24-11.jpg`.*

## Decisioni di Fede (24/11/2026)
- **Disposizione** come in Age of Empires: **controlli delle mappe a destra, comandi a sinistra**.
- **Stile svizzero**, quello della segnaletica della metropolitana di Milano (Noorda) e di New York (Vignelli): deve dialogare con l'urbanistica, presente ma non invasivo né protagonista, con carattere.
- **Colori solo con un significato**, senza esagerare.

## Regole dello stile (proposta di Claude, da confermare con Fede)
- **Fasce scure a filo dei bordi** dello schermo (barra in alto, pannelli a sinistra e a destra, barra in basso), testo bianco, niente angoli arrotondati né ombre. Righe sottili per separare le sezioni.
- **Gerarchia con grandezza e peso del testo**, non con il colore. Intestazioni di sezione in maiuscolo, piccole, spaziate, grigie, sopra una riga sottile.
- **Scelta corrente per inversione:** fondo bianco e testo nero, come un cartello.
- **Colori con significato:**
  | Colore | Significato |
  |---|---|
  | grigio chiaro | Terreno (mappa neutra) |
  | blu | Acqua |
  | verde | Fertilità |
  | rosso | Rischio di piena; in generale **pericolo o azione irreversibile** (per esempio costruire con cemento e asfalto, che sigilla il suolo per sempre) |
  | giallo | Energia dell'acqua |

  Ogni mappa tematica ha il suo bollino tondo con il numero del tasto, come una linea della metropolitana. I comandi hanno un quadratino con la lettera del tasto, senza colore, tranne quelli irreversibili (bollino rosso). Le legende delle mappe usano gli stessi colori del bollino.
- **Carattere:** per ora quello di Godot, con un grassetto simulato. Il carattere svizzero gratuito più vicino è Inter, con licenza OFL (libera ma non CC0): **da decidere con Fede** se si può usare.

## Parti
- **Barra in alto:** nome del gioco, nome della mappa; al centro lo spazio per gli indicatori del gioco (popolazione, cibo… con il Prototipo 0); a destra le prestazioni (fotogrammi al secondo, alberi, tempo della cache), in piccolo e in grigio.
- **Pannello a sinistra (comandi):** gruppi di comandi con intestazione. Un comando può essere uno **strumento** (resta selezionato e si usa cliccando sulla mappa) o un'**azione** (si esegue subito). Sotto, il messaggio dell'ultima azione. Oggi contiene gli strumenti di prova dell'uso del suolo: abbattere, campi, costruire con argilla e legno, costruire con cemento e asfalto, liberare il terreno, far passare 10 anni.
- **Pannello a destra (mappe):** le cinque mappe tematiche, le sovrapposizioni (griglia dei lotti, isoipse) e la legenda della mappa scelta.
- **Barra in basso:** la lettura del lotto sotto il puntatore; a destra, in grigio, i comandi della camera.
- **Strumento sulla mappa:** un cerchio sottile bianco (rosso se l'azione è irreversibile) segue il puntatore.

## Tasti
1–5 mappe · G griglia · I isoipse · F fondare · C campi · V sentiero · H granaio · Spazio pausa o riprendi · + e − velocità del tempo · T abbatti · B costruisci (argilla e legno) · L libera · Y +10 anni · [ e ] raggio dello strumento · Esc nessuno strumento · Q E ruota · rotella zoom · tasto destro o WASD sposta · Home torna al sito.

## Partita (Prototipo 0 in Godot)
- **Barra in alto:** anno, popolazione, cibo (scorta / consumo dell'anno), salute, legittimità. Il valore diventa rosso quando è in pericolo (pochi abitanti, scorte sotto il 30% del consumo, salute sotto 45, legittimità sotto 30).
- **Pannello a sinistra:** gruppo *Villaggio* (Fondare, Campi, Sentiero, Granaio, usanza sul raccolto), gruppo *Tempo* (pausa e tre velocità), messaggio dell'ultima azione e *Cronaca* con gli ultimi fatti.
- **Scelte:** finestra al centro, con tipo (presagio, momento decisivo, evento, crisi…), titolo, testo e opzioni con la loro conseguenza in grigio. Il tempo si ferma finché non si sceglie.
- **Avvisi:** fascia breve sotto la barra in alto con un segno rosso, solo per gli eventi rilevanti (siccità, carestie gravi).
