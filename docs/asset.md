# Asset

*Guida di stile, regole tecniche e catalogo degli asset 3D. Le scelte di stile sono proposte di Claude in attesa della direzione artistica di Fede.*

## Approccio (deciso)
- **Edifici procedurali** generati dalla forma del lotto (pianta, piani, tetto, materiali secondo l'epoca), soprattutto dalle epoche urbane in poi.
- **Pochi pezzi fatti a mano**: monumenti e tipologie riconoscibili di ogni epoca (casa lunga, granaio, tempio, cattedrale, palazzo, stazione…).
- **Elementi minori** (alberi, rocce, canne): modellati da script o presi da pacchetti con licenza CC0.

## Stile (proposta, da confermare)
**"Plastico architettonico":** l'aspetto di un modello in scala da studio di urbanistica.
- Forme semplici, poche facce, spigoli netti.
- Colori pieni per materiale, nessuna texture; tinte tenui e naturali, mai sature.
- Una tavolozza di materiali condivisa da tutti gli asset (vedi sotto), così città di epoche diverse restano coerenti.
- La leggibilità dall'alto conta più del dettaglio: tetti e piante devono distinguersi a colpo d'occhio nella vista isometrica.

### Tavolozza dei materiali (prima versione)
| Materiale | Uso | Colore (RGB lineare) |
|---|---|---|
| terra_cruda | Muri in argilla e graticcio | 0,62 · 0,52 · 0,40 |
| paglia / paglia_scura | Tetti | 0,74 · 0,62 · 0,38 / 0,60 · 0,49 · 0,29 |
| legno / legno_scuro | Pali, palizzate, strutture | 0,47 · 0,35 · 0,23 / 0,30 · 0,22 · 0,15 |
| pietra | Pietre, stele | 0,64 · 0,63 · 0,59 |
| fogliame / fogliame_scuro | Alberi | 0,36 · 0,47 · 0,27 / 0,27 · 0,38 · 0,21 |
| canna | Canneti | 0,60 · 0,62 · 0,38 |
| vano | Porte e aperture | 0,16 · 0,12 · 0,09 |

## Regole tecniche
- **Unità:** 1 unità = 1 metro, misure reali.
- **Origine:** al centro della base, a quota 0 (l'asset poggia sul terreno nel punto in cui lo si piazza).
- **Orientamento:** lato lungo sull'asse X; ingresso verso +X.
- **Formato:** un file `.glb` per asset, in `gioco/asset/<epoca>/`, con nome italiano in minuscolo e trattini bassi (es. `casa_lunga_media.glb`).
- **Sorgente:** ogni asset nasce da uno script in `strumenti/blender/`, così si può rigenerare e modificare. Niente file `.blend` modificati a mano senza script.
- **Verifica:** `godot --headless --path gioco -s res://test/verifica_asset.gd` controlla che ogni asset si carichi, poggi a quota 0 e abbia misure plausibili.
- **Licenze:** solo asset creati da noi o CC0, con la fonte annotata in questo documento.

## Catalogo

### Epoca del villaggio (primo lotto, 23/11/2026)
Generati da `strumenti/blender/asset_villaggio.py`. Anteprima: `docs/immagini/asset-villaggio.png`.

| Asset | Misure (m) | Uso nel gioco |
|---|---|---|
| casa_lunga_piccola | 8,9 × 5,9 × 4,9 | Abitazione di una famiglia |
| casa_lunga_media | 12,9 × 6,9 × 5,5 | Abitazione di una famiglia estesa |
| casa_lunga_grande | 18,9 × 7,9 × 6,1 | Casa di un lignaggio o degli anziani |
| capanna_tonda | 6,8 × 6,8 × 5,2 | Variante di abitazione e ricovero |
| granaio_su_pali | 3,3 × 3,3 × 4,1 | Granaio (azione Granaio) |
| palizzata_tratto | 4,0 × 0,3 × 3,0 | Recinto, modulo da 4 m |
| palizzata_porta | 3,4 × 0,3 × 3,2 | Varco nel recinto |
| luogo_sacro | 8,8 × 8,9 × 2,9 | Circolo di pietre con stele (azione Luogo sacro) |
| quercia_1, quercia_2 | fino a 10,8 × 9,7 × 13,2 | Boschi e alberi isolati |
| canneto | 2,4 × 2,9 × 2,5 | Paludi e rive |

**Note storiche:** forme plausibili per l'Europa neolitica senza riferirsi a una cultura precisa. Le case lunghe a pianta rettangolare sono tipiche del Neolitico europeo; capanne tonde e ovali sono diffuse nell'area mediterranea. Il granaio su pali è una scelta di leggibilità: nel Neolitico erano comuni anche i silos scavati nel terreno, che si potrebbero rappresentare più avanti come fosse.

### Da fare (proposte)
- **Villaggio:** fosse-silos, focolare all'aperto, recinto per animali, varianti di tetto e di colore per evitare ripetizioni, rocce, prato e arbusti.
- **Abitato protourbano:** case su un terrapieno, terrapieno e fossato modulari, villaggio arginato (ispirato alle terramare dell'età del Bronzo, tipiche proprio della pianura emiliana).
- **Città-stato e oltre:** primi edifici procedurali per lotto.
