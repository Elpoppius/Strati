# Mappa 1 — Archetipo pedecollinare

*Prima mappa del gioco e terreno di prova del Prototipo 0. Ispirata alla topografia naturale del bolognese prima dell'intervento umano, ma deformata e non riconoscibile. Solo elementi naturali.*

## Dimensioni (proposta)
Circa 10 × 10 km, abbastanza per una metropoli nelle epoche tarde. Nord in alto.

## Fasce (da sud a nord)
| Fascia | Quota indicativa | Caratteri |
|---|---|---|
| Colline (sud) | 100–450 m | Crinali e valli trasversali; boschi; argille instabili con calanchi e frane; un affioramento di gessi a est con grotte |
| Fascia pedecollinare | 60–100 m | Terrazzi asciutti, pendenza lieve, linea di sorgenti alla base delle colline |
| Alta pianura | 30–60 m | Conoidi ghiaiosi dei torrenti, pendenza leggera verso nord, suolo drenante, falda profonda |
| Bassa pianura (nord) | 15–30 m | Argille e limi, falda affiorante, paludi e zone umide, suolo fertile ma malsano |

## Idrografia naturale
- **Fiume maggiore (ovest):** esce dalla valle collinare, greto ampio, portata più costante, piene violente; in pianura divaga e può cambiare corso. Punti di guado.
- **Torrente stagionale (centro):** piccolo, quasi secco d'estate, piene improvvise in autunno e primavera; attraversa il terrazzo centrale.
- **Torrente orientale:** medio, regime irregolare.
- **Sorgenti:** allineate lungo la fascia pedecollinare.
- **Paludi:** nella bassa pianura, dove la falda affiora.

## Suolo e geologia
- Ghiaie nei conoidi (buone fondazioni, poca acqua in superficie).
- Argille e limi in bassa pianura (fertili, umidi, cedevoli).
- Argille collinari instabili (frane, calanchi).
- Gessi a est (grotte, pietra, suolo carsico con rischio di sprofondamenti).
- Sismicità moderata.

## Clima
Continentale: estati calde e afose, inverni freddi con nebbie, piogge concentrate in autunno e primavera. I torrenti seguono un regime torrentizio (secchi d'estate, in piena dopo le piogge).

## Copertura naturale
Querceti e boschi di pianura, boschi collinari, prati lungo i greti, canneti e zone umide a nord.

## Corridoi naturali
Elementi naturali, non strade:
- **Corridoio est–ovest** lungo il margine delle colline, asciutto e sopra le paludi.
- **Corridoio nord–sud** lungo la valle del fiume maggiore, unico passaggio verso le montagne.
Il loro incrocio è un nodo naturale di passaggio.

## Siti di fondazione
| # | Sito | Vantaggi | Rischi |
|---|---|---|---|
| 1 | Terrazzo centrale tra i torrenti | Sorgenti, suolo asciutto, vicinanza al corridoio est–ovest, campi in pianura | Piene improvvise del torrente, acqua scarsa d'estate, spazio limitato a sud |
| 2 | Sbocco del fiume dalla valle | Acqua abbondante, guado, controllo del passaggio verso le montagne, suolo alluvionale | Piene e cambi di corso del fiume |
| 3 | Sperone collinare | Difesa, aria salubre, vista sulla pianura | Frane, acqua lontana, campi lontani |
| 4 | Dosso nelle paludi | Difesa naturale dell'acqua, caccia e pesca, suolo fertile | Malattie, piene, isolamento |
| 5 | Area dei gessi | Ripari nelle grotte, pietra | Sprofondamenti, poca terra fertile |
| 6 | Pianura aperta | Spazio ampio e piano, ottimo per campi e crescita | Nessuna difesa, acqua solo da pozzi, esposizione alle scorrerie |

## Mappe tematiche derivate
Altimetria, pendenze, acqua (fiumi, sorgenti, profondità della falda), fertilità del suolo, stabilità del terreno, rischio di piena, copertura naturale, memoria del rischio.

## Produzione
Per il Prototipo 0 la mappa delle altezze è generata da codice a partire da questa descrizione, senza scaricare dati. I dati altimetrici reali (SRTM, Copernicus DEM) servono per la versione in Godot.

## Idraulica (24/11/2026)
Richiesta di Fede: la corrente come meccanica di gioco (mulini, turbine…) e i dislivelli per le dighe. Calcolata da `strumenti/mappe/genera_pedecollinare.py` (funzione `idraulica`); verifiche in `gioco/test/verifica_acqua.gd`.

**Portate (proposta di Claude, verosimili per l'appennino bolognese):**
| Corso | Regime | Media | Magra | Piena |
|---|---|---|---|---|
| Fiume maggiore | perenne | 15 m³/s | 2 m³/s | 600 m³/s |
| Torrente stagionale | secco d'estate | 0,4 m³/s | 0 | 60 m³/s |
| Torrente orientale | irregolare | 1,5 m³/s | 0,1 m³/s | 150 m³/s |

La portata cresce verso valle con il bacino (dal 60% al 100% della media).

**Profilo di ogni corso**, ogni 10 m di mezzeria: quota del letto (che scende sempre verso valle), pendenza su circa 200 m, larghezza dell'alveo (3,5 √Q), profondità e velocità con la formula di Manning (alveo naturale con ghiaie, n = 0,035), **potenza idraulica ogni 100 m** di corso (ρ g Q × pendenza × 100 m). È la potenza lorda disponibile: un mulino ne usa una parte, deviando l'acqua in una gora.
- Risultati: fiume da 114 a 14 m, pendenza massima 43‰ in collina, corrente fino a 2,7 m/s, fino a 380 kW ogni 100 m; torrente stagionale fino a 16 kW, ma nullo d'estate; torrente orientale fino a 54 kW.
- In pianura il fiume rallenta e perde potenza: i mulini rendono di più al piede delle colline, dove c'è ancora pendenza e la valle si apre.

**Siti per le dighe:** ogni 100 m lungo i corsi si misura quanto è larga la valle a 10 e a 20 m sopra il letto (lunghezza della diga, al massimo 1,5 km) e quanta acqua tratterrebbe (area e volume dell'invaso a monte, collegato all'alveo); si tengono i tre migliori per corso, a più di 1 km l'uno dall'altro, misurati come acqua trattenuta per metro cubo di diga. Ogni sito riporta anche la potenza media di una centrale con quel salto (rendimento 80%). Sulla mappa pedecollinare stanno tutti nelle valli delle colline e al loro sbocco.

**Dati per il gioco:** `velocita.u8` e `potenza.u8` a 40 m (fascia attorno all'alveo) e, in `meta.json`, l'elenco dei corsi e dei siti per le dighe. Lo shader li usa per le rapide e per la mappa tematica dell'energia dell'acqua.

## Note sui dati del gioco (23/11/2026)
- L'area dei gessi è una macchia irregolare attorno al sito 5 (prima era un rettangolo segnaposto); la fertilità scende gradualmente verso il suo interno.
- Vicinanza all'acqua misurata in linea d'aria, con portata di 9 celle invece di 8: il cerchio copre la stessa area del vecchio quadrato, quindi i siti restano vicini o lontani dall'acqua come nel Prototipo 0.
- Fasce di fertilità e di rischio di piena con passaggi graduali ai confini.
