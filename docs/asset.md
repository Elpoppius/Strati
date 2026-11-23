# Asset

*Guida di stile, regole tecniche e catalogo degli asset 3D.*

## Approccio (deciso)
- **Edifici procedurali** generati dalla forma del lotto (pianta, piani, tetto, materiali secondo l'epoca), soprattutto dalle epoche urbane in poi.
- **Pochi pezzi fatti a mano**: monumenti e tipologie riconoscibili di ogni epoca (casa lunga, granaio, tempio, cattedrale, palazzo, stazione…).
- **Elementi minori** (alberi, rocce, canne): modellati da script o presi da pacchetti con licenza CC0.

## Stile
**Decisione di Fede (23/11/2026):** lo stile "plastico architettonico" (forme semplici, colori pieni e tenui, nessuna texture) è scartato. Si va verso uno stile **verosimile**, anche nei colori. Alberi con pochi poligoni non vanno bene.

**Riferimento (Fede, 23/11/2026): Age of Empires IV.** Fede approva la direzione verosimile e indica AoE IV come riferimento per l'aspetto. Ne ricaviamo queste linee guida (proposta di Claude), senza copiarne modelli, texture o elementi:
- **Semi-realismo "dipinto":** materiali verosimili ma con texture dalla variazione di colore accentuata, come pennellate; niente fotorealismo.
- **Leggibilità prima di tutto**, sia da lontano sia da vicino: sagome nette, contrasto tra materiali (paglia dorata, legno scuro, intonaco caldo, verde vivo).
- **Proporzioni appena esagerate**, da "plastico da tavolo": tetti più alti e sporgenti, porte e pali più grossi del vero.
- **Colori caldi e saturi ma naturali**, luce di sole calda e ombre nette.
- **Volumi dipinti:** occlusione ambientale cotta nei colori dei vertici, che scurisce basi, incavi e interno delle chiome.
- **Alberi pieni e tondeggianti**, con la parte alta più chiara e quella in ombra più scura.

**Prova di stile verosimile (seconda versione, secondo le linee guida qui sopra):**
- **Texture procedurali** generate da script (`strumenti/blender/texture_procedurali.py`), senza scaricare nulla: paglia, argilla, legno, corteccia, pietra, erba, foglie con trasparenza.
- **Geometria più ricca:** tetti di paglia spessi e irregolari a padiglione o conici, pali a vista lungo i muri, porte incassate, cappelli contro i roditori sui pali del granaio.
- **Alberi:** tronco, rami principali e chioma tondeggiante fatta di carte di foglie con ritaglio, in tre toni (circa 320 facce per albero).
- **Occlusione ambientale** cotta in Blender nei colori dei vertici. In Godot si attiva caricando gli asset con `Asset.istanzia()` (`gioco/script/asset.gd`), perché l'importatore glTF non la abilita sempre su tutti i materiali.
- **Terreno coerente:** nel gioco il suolo usa una texture d'erba, tinta dalla zona; boschi, paludi, gessi e colline restano riconoscibili. Il vecchio aspetto si ottiene con il parametro `realismo = 0` dello shader del terreno.
- Immagini: `docs/immagini/prova-stile-verosimile-blender.png` (anteprima di Blender) e `docs/immagini/prova-stile-verosimile-gioco.png` (come appare davvero in Godot, renderer Compatibilità).

## Regole tecniche
- **Unità:** 1 unità = 1 metro, misure reali.
- **Origine:** al centro della base, a quota 0. Tronchi e pali possono affondare fino a 30 cm, per non restare sospesi sui pendii.
- **Orientamento:** lato lungo sull'asse X; ingresso verso +X.
- **Formato:** un file `.glb` per asset, in `gioco/asset/<epoca>/`, con nome italiano in minuscolo e trattini bassi (es. `casa_lunga_media.glb`). Le texture sono incorporate nel `.glb`; le stesse immagini stanno in `gioco/asset/texture/` per lo shader del terreno.
- **Trasparenze:** foglie e simili con ritaglio netto (alpha clip), non con trasparenza graduale, per resa e prestazioni.
- **Sorgente:** ogni asset nasce da uno script in `strumenti/blender/`, così si può rigenerare e modificare.
- **Verifica:** `godot --headless --path gioco -s res://test/verifica_asset.gd` controlla che ogni asset si carichi, poggi a terra e abbia misure plausibili. `test/foto_asset.gd` mostra gli asset posati sul terreno del gioco.
- **Licenze:** solo asset creati da noi o CC0, con la fonte annotata in questo documento.

## Catalogo

### Prova di stile verosimile (23/11/2026)
Generati da `strumenti/blender/prova_stile_verosimile.py` in `gioco/asset/prove_stile/`.

| Asset | Misure (m) | Facce |
|---|---|---|
| casa_lunga_media | 13,8 × 7,9 × 7,2 | 580 |
| capanna_tonda | 7,5 × 7,6 × 5,6 | 272 |
| granaio_su_pali | 3,9 × 3,8 × 5,5 | 496 |
| quercia_1 | 12,3 × 12,3 × 13,0 | 321 |
| quercia_2 | 15,9 × 16,6 × 16,7 | 334 |

**Note storiche:** forme plausibili per l'Europa neolitica senza riferirsi a una cultura precisa. Le case lunghe a pianta rettangolare sono tipiche del Neolitico europeo; capanne tonde e ovali sono diffuse nell'area mediterranea. Il granaio su pali è una scelta di leggibilità: nel Neolitico erano comuni anche i silos scavati nel terreno.

### Da fare
- **Da migliorare nella prova:** la texture del prato si ripete in modo visibile; le chiome, da vicino, mostrano ancora i singoli ciuffi.
- **Villaggio:** completare il lotto nello stile scelto (case lunghe piccola e grande, palizzata e varco, luogo sacro, canneto, rocce, arbusti, fosse-silos, focolare, recinto per animali) e varianti per evitare ripetizioni.
- **Terreno:** texture distinte per prato, campo coltivato, bosco, palude, roccia; alberi veri al posto delle macchie scure dei boschi.
- **Abitato protourbano:** terrapieno e fossato modulari, villaggio arginato ispirato alle terramare dell'età del Bronzo, tipiche della pianura emiliana.
