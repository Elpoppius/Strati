# Resa grafica

*I sistemi che danno l'aspetto al gioco. Valgono per tutte le mappe.*

**Decisione di Fede (23/11/2026):** il lavoro su alberi, terreni, ombre, asset e acqua non riguarda una mappa sola. Ogni sistema deve funzionare con qualsiasi mappa a partire dai suoi dati, senza ritocchi a mano per la singola mappa.

## Cosa deve fornire una mappa
Ogni mappa è una risorsa `MappaDati` (`gioco/script/mappa_dati.gd`), generata da uno script in `strumenti/mappe/` e convertita con `strumenti/importa_mappa.gd`. I sistemi qui sotto leggono questi strati:

| Strato | Risoluzione | Usato da |
|---|---|---|
| quote | griglia della mappa (oggi 256 × 256, 40 m) | forma del terreno, tinte per quota, pendii ripidi |
| tipo (terra, fiume, torrente, palude, gessi) | griglia | colori delle zone speciali |
| zona | griglia | tinta del suolo |
| fertilità, acqua affidabile, acqua stagionale | griglia | mappe tematiche; distribuzione di verde e secco nel prato |
| copertura (bosco) | griglia | boschi del terreno; in futuro posa degli alberi |
| distanza dall'acqua | 4 volte la griglia (oggi 1024 × 1024, 2 m per unità) | fiumi, torrenti, rive |

Una mappa nuova eredita tutto il resto: basta che fornisca questi strati.

## Terreno e prato
Codice: `gioco/shader/terreno.gdshader`, `gioco/script/terreno.gd`.
- **Erba:** texture a fili sottili (`erba.png`), letta due volte con orientamenti diversi per spezzarne la ripetizione; variazione minuta di tono da vicino.
- **Verde, ingiallito, secco:** distribuiti da due rumori unici per tutta la mappa, generati all'avvio con `FastNoiseLite`, e dai dati del luogo: più secco lontano dall'acqua e sui terreni poco fertili. Nessuna ripetizione a nessuno zoom; i dati a celle sono ammorbiditi, così i bordi non fanno scalini. Richiesta di Fede: niente texture ripetute nelle parti aride; la priorità è la resa del prato.
- **Pendii ripidi:** l'erba si dirada e affiora la terra.
- **Boschi:** bordi irregolari e una volta di chiome dipinta, dalla copertura. È un segnaposto: **andranno posati alberi veri** (decisione di Fede).
- **Texture:** generate da `strumenti/blender/texture_procedurali.py`.

## Acqua
Codice: in fondo a `gioco/shader/terreno.gdshader`. Dati: la distanza dalla riva, che `terreno.gd` converte in virgola mobile (in 8 bit faceva fasce a gradini).
- Profondità che sfuma dalla riva (bassa e verdastra) al centro (verde-azzurro più scuro).
- Increspature che scorrono nel tempo, in due strati più un'ondulazione lenta; riflessi del cielo sulle creste e un poco di luce propria, così l'acqua non diventa scura in ombra.
- Superficie liscia e riflettente (il terreno no).
- Schiuma sottile lungo la riva, sponda bagnata più scura e un velo di limo.
- Da fare: corrente nel verso del fiume, cascate e rapide sui torrenti, paludi con acqua bassa e canne, livelli che cambiano con le piene.

## Luce e ombre
Codice: `gioco/script/principale.gd` (sole e ambiente), `gioco/script/camera_isometrica.gd` (distanza e piani di taglio).
- **Sole da sinistra, ombre lunghe verso destra** sullo schermo (decisione di Fede). Il sole gira con la camera, quindi vale a ogni rotazione. Altezza 42°: costanti `ALTEZZA_SOLE` e `AZIMUT_SOLE`.
- La camera sta appena fuori dalla fetta di terreno visibile e la mappa d'ombra copre solo quella: ombre nitide anche a 35 m. Con la camera lontana le ombre sparivano.
- Sole caldo, luce del cielo un po' fredda: ombre leggibili e non nere.

## Alberi
Codice: `strumenti/blender/prova_stile_verosimile.py` (funzione `albero`). Regole e catalogo: `docs/asset.md`.
- Chiome a lobi fatte di carte di foglie singole; normali sferiche per la luce sul volume; ombra interna calcolata.
- Specie definite da pochi parametri (tabella `SPECIE`): quercia, carpino, pioppo, acero, arbusto. Una mappa con altro clima avrà altre specie con lo stesso generatore.
- Da fare: posa sulla mappa con istanze multiple, una versione leggera per la distanza, scelta della specie in base al luogo (umidità, quota).

## Asset
Regole, stile e catalogo: `docs/asset.md`. Ogni asset nasce da uno script, così si può rigenerare quando cambiano lo stile o le regole.

## Come controllare
- `test/foto.gd`: territorio attorno al sito iniziale, a qualsiasi zoom.
- `test/foto_asset.gd`: asset posati vicino al sito iniziale.
- `test/foto_luogo.gd`: margine di bosco o riva del fiume più vicini al sito (`-- dimensione bosco|acqua`).
- Le righe di comando complete sono in `CLAUDE.md`.
