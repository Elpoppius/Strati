# Asset

*Guida di stile, regole tecniche e catalogo degli asset 3D. I sistemi comuni a tutte le mappe (terreno, prato, acqua, luce, alberi) sono descritti in `docs/resa-grafica.md`.*

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

**Parere di Fede sulla seconda versione (23/11/2026):** "un ottimo passo avanti", direzione giusta. Da sistemare: il prato è grossolano; il livello di dettaglio va verificato con uno zoom molto più vicino, come in AoE IV, dove da vicino gli alberi restano verosimili; la texture delle foglie va bene, vanno curati forma e riempimento delle chiome. Reference inviate: boschetti di AoE IV (chiome piene e tondeggianti fatte di molte foglie distinte, specie e colori diversi tra verde, verde acqua, verde chiaro e autunnali, tronchi e rami visibili, sottobosco di erba secca rossiccia) e una foresta realistica vista dall'alto.

**Terza versione (proposta di Claude, da valutare con Fede):**
- **Zoom più vicino:** la vista minima scende da 120 a 40 m (`DIM_MIN` in `camera_isometrica.gd`). Prove fatte a 35, 70 e 160 m.
- **Foglie singole e leggibili:** ogni texture è un ciuffo di 40–60 foglie a mandorla su rametti, con bordo scuro, metà in luce e nervatura. Le foglie sono volutamente grandi (circa 1/20 della chioma), come nelle reference. Una texture per specie.
- **Chiome a lobi:** ogni chioma è fatta di 5–8 sfere minori ("lobi") che danno il contorno a nuvola; su ogni lobo, carte rivolte verso l'esterno, più alcune carte interne che chiudono i buchi.
- **Luce sul volume:** le carte hanno normali sferiche (rivolte dal centro della chioma), quindi la luce scorre sulla chioma intera: chiara in alto e verso il sole, scura sotto. Ogni carta ha fronte e retro come facce distinte, così il retro non si illumina al contrario.
- **Ombra interna calcolata:** per le chiome l'occlusione non si cuoce (con le carte così fitte verrebbe nera ovunque) ma si calcola dalla profondità nella chioma: scuro al centro e sotto, pieno sul guscio e in cima.
- **Cinque specie:** quercia (larga, verde oliva), carpino (tondo, verde freddo), pioppo (colonnare, verde chiaro), acero in autunno (giallo e arancio), arbusto di nocciolo (senza tronco, con fusti dal suolo). L'acero autunnale serve a provare la varietà di colore: le stagioni nel gioco non sono ancora decise.
- **Prato:** texture fatta di migliaia di fili sottili invece che di macchie, con una seconda lettura ruotata che ne spezza la ripetizione; chiazze di erba secca rossiccia (distribuzione: vedi più sotto).
- **Ombre (corrette dopo la segnalazione di Fede, 23/11/2026):** mancavano per due motivi. (1) Il sole stava alle spalle della camera: ogni ombra cadeva dietro l'oggetto che la proiettava e restava nascosta, e tutto era illuminato di fronte, quindi piatto. Ora il sole gira con la camera. **Decisione di Fede (23/11/2026): sole da sinistra, ombre lunghe verso destra sullo schermo**, a ogni rotazione (altezza 42°, 270° rispetto alla direzione dello sguardo: costanti `ALTEZZA_SOLE` e `AZIMUT_SOLE` in `principale.gd`). È una scelta di leggibilità: in un mondo realistico il sole non seguirebbe la camera. (2) La camera stava a 20 km dal punto guardato e le ombre del sole, che coprono lo spazio dalla camera alla distanza massima, sfumavano fino a sparire. Ora la distanza della camera segue lo zoom e la mappa d'ombra copre solo la fetta di terreno visibile: ombre nitide anche a 35 m. Sole un po' caldo, luce del cielo un po' fredda, così le ombre non vengono nere.
- **Terreno (stessa sessione):** i boschi non stanno più nei colori dei vertici, che davano bordi a gradini da 40 m. Li disegna lo shader dalla copertura della mappa, con bordi irregolari e una volta di chiome fatta di due texture di foglie a strati, con macchie di luce e d'ombra grandi come alberi. Segnaposto finché non ci saranno alberi veri posati sulla mappa. Sui pendii ripidi l'erba si dirada e affiora la terra. Immagine del margine di un bosco: `docs/immagini/terreno-margine-bosco.jpg` (con `test/foto_luogo.gd`).
- **Prato senza ripetizioni (richiesta di Fede, 23/11/2026: evitare la texture ripetuta nelle parti aride, concentrarsi sulla resa del prato):** la distribuzione di verde e secco non viene più da maschere piccole ripetute ma da due rumori unici per tutta la mappa (1024 × 1024, circa 10 m per pixel, generati in `terreno.gd` con `FastNoiseLite`) e dai dati del luogo: più secco lontano dall'acqua e sui terreni poco fertili, più verde vicino ai fiumi. Tre stadi: erba verde, ingiallita, secca rossiccia. I dati a celle da 40 m sono ammorbiditi da quattro letture sfalsate, così i bordi non fanno scalini; le maschere piccole servono solo a frastagliare i bordi e a variare il tono dei ciuffi da vicino. Immagini: `docs/immagini/prato-160m.jpg`, `prato-5000m.jpg`.
- Immagini: `docs/immagini/prova-stile-v3-vicino.jpg` (vista di 35 m), `-medio.jpg` (70 m), `-territorio.jpg` (1500 m), `-foglie.jpg` (le quattro texture delle foglie).

## Regole tecniche
- **Unità:** 1 unità = 1 metro, misure reali.
- **Origine:** al centro della base, a quota 0. Tronchi e pali possono affondare fino a 30 cm, per non restare sospesi sui pendii.
- **Orientamento:** lato lungo sull'asse X; ingresso verso +X.
- **Formato:** un file `.glb` per asset, in `gioco/asset/<epoca>/`, con nome italiano in minuscolo e trattini bassi (es. `casa_lunga_media.glb`). Le texture sono incorporate nel `.glb`; le stesse immagini stanno in `gioco/asset/texture/` per lo shader del terreno.
- **Trasparenze:** foglie e simili con ritaglio netto (alpha clip), non con trasparenza graduale, per resa e prestazioni.
- **Alberi:** carte di foglie in due facce (fronte e retro) con materiale a faccia singola; normali sferiche impostate nello script; occlusione delle chiome calcolata (`occlusione_chioma`), quella di tronchi ed edifici cotta.
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
| quercia_1 | 9,9 × 9,2 × 12,0 | 475 |
| quercia_2 | 13,0 × 12,6 × 15,4 | 417 |
| carpino_1 | 6,8 × 6,8 × 10,0 | 359 |
| pioppo_1 | 6,3 × 6,2 × 16,8 | 417 |
| acero_autunno | 8,5 × 8,9 × 11,4 | 475 |
| cespuglio_1 | 4,0 × 3,8 × 3,2 | 195 |
| cespuglio_2 | 4,5 × 4,4 × 3,8 | 229 |

Gli alberi sono della terza versione; le facce delle chiome contano fronte e retro delle carte.

**Note storiche:** forme plausibili per l'Europa neolitica senza riferirsi a una cultura precisa. Le case lunghe a pianta rettangolare sono tipiche del Neolitico europeo; capanne tonde e ovali sono diffuse nell'area mediterranea. Il granaio su pali è una scelta di leggibilità: nel Neolitico erano comuni anche i silos scavati nel terreno.

### Alberi della mappa (23/11/2026)
Generati da `strumenti/blender/alberi_mappa.py` in `gioco/asset/alberi/`, ognuno in versione completa e leggera (`_leggero`, per la media distanza: poche carte grandi, nessun ramo).

| Modello | Altezza (m) | Facce (completo / leggero) |
|---|---|---|
| quercia_1, _2, _3 | 12,3 · 14,7 · 10,9 | 475–533 / 71–79 |
| carpino_1, _2 | 10,3 · 12,1 | 359 / 55 |
| pioppo_1, _2 | 16,8 · 19,4 | 417–475 / 63–71 |
| cespuglio_1, _2 | 3,3 · 3,9 | 185–263 / 54 |
| canna_1, _2 (ciuffi di cannuccia di palude) | 3,2 · 3,7 | 420 / 68 |

Nel gioco ogni albero è scalato tra 0,95 e 1,35 (bosco maturo) e ruotato a caso; gli arbusti tra 0,75 e 1,25, le canne tra 0,9 e 1,5. Le canne non hanno texture: il colore (verde alla base, paglia in cima, pennacchi bruni) sta nei vertici, in valori lineari.

**Attenzione all'importazione:** nei file `.glb.import` di `asset/alberi/` va tenuto `meshes/generate_lods=false`. Le versioni semplificate che Godot genera da solo facevano sparire le lame sottili delle canne; i livelli di dettaglio li gestisce già `VistaAlberi`.

### Da fare
- **Da verificare nella terza versione:** ombre e prestazioni sui PC di Fede; carte viste di taglio che a volte si vedono come strisce ai bordi delle chiome; la casa lunga e le capanne viste a 35 m (le texture di paglia e argilla sono nate per viste più lontane).
- **Villaggio:** lotto completato il 24/11/2026 (vedi sotto). Restano le varianti per evitare ripetizioni quando il villaggio crescerà da solo.
- **Terreno:** texture distinte per campo coltivato, bosco, palude, roccia; alberi veri al posto della volta di chiome dipinta sul terreno, che da circa 150 m mostra ancora una trama ripetuta.
- **Abitato protourbano:** terrapieno e fossato modulari, villaggio arginato ispirato alle terramare dell'età del Bronzo, tipiche della pianura emiliana.

## Paglia e argilla da vicino (24/11/2026, richiesta di Fede)
Le texture di paglia e argilla erano rumori sfumati: da vicino la paglia sembrava una superficie liscia e chiara, l'argilla una tinta uniforme. Rifatte in `strumenti/blender/texture_procedurali.py`:
- **Paglia:** sei corsi di steli sovrapposti per ripetizione (circa 40 cm l'uno sul tetto), ogni stelo disegnato, più scuro in alto dove il corso sopra fa ombra; teste tagliate chiare lungo il bordo di ogni corso, ondulato; toni dal dorato al grigio della paglia vecchia, qualche velo di muschio. Un po' più scura e calda di prima, perché al sole del gioco si sbiancava.
- **Argilla:** impasto con chiazze più chiare dove è asciutto, stesure a mano a pennellate curve, paglia tritata nell'impasto, crepe da ritiro sottili e solo a tratti, tracce dell'incannicciato sotto.
- **Tetti conici:** nuove coordinate di texture (`proiezione_conica` in `prova_stile_verosimile.py`): i corsi sono anelli concentrici attorno all'apice. Con la proiezione per facce facevano zig-zag da una faccia all'altra.
Immagine a 18 m di vista: `docs/immagini/paglia-argilla-24-11.jpg`.

## Animali del pascolo (26/11/2026, terza versione)
Richiesta di Fede: i modelli di prima erano "grossolani e molto poligonali"; definizione simile agli alberi, con i riferimenti di Age of Empires IV (scene di gioco: cervi, cinghiale, vacche delle Highlands; non le icone dorate). Cosa rende definiti quegli animali: il pelo che si vede (ciocche dal dorso verso la pancia, punte chiare e radici scure), la sagoma sfrangiata (ciocche su ventre, collo e zampe) e pochi segni forti sul manto.

Script `strumenti/blender/animali.py` → `gioco/asset/villaggio/animale_<specie>_<manto>[_leggero].glb` e `animali.json`. Comandi: `python3 strumenti/blender/texture_procedurali.py gioco/asset/texture animali` (pelo, lana, ciocche, ciocche_lana), poi `blender-py strumenti/blender/animali.py gioco/asset/villaggio` (serve scikit-image nell'ambiente di Blender, lo installa `setup_strumenti.sh`), poi l'importazione e, nei nuovi `.import` delle texture, `detect_3d/compress_to=0` e le mipmap.
- **Corpo unico:** un campo di distanza fatto di ellissoidi e coni arrotondati (tronco, collo, testa, zampe in tre tratti con ginocchio e garretto, corna, orecchie, coda) che si fondono morbidamente; la superficie si estrae con marching cubes e si semplifica. Niente giunture né facce piatte.
- **Pelo:** grana `pelo.png` (ciocche fitte) o `lana.png` (riccioli) con UV che fanno scorrere il pelo dal dorso alla pancia e lungo le zampe; **carte di pelo** con il ritaglio, come le foglie delle chiome (`ciocche.png`, quattro ciocche affiancate; per la pecora `ciocche_lana.png`, bioccoli arricciati), piantate sul corpo nel verso del pelo, più lunghe sotto la pancia (frangia), corte su collo e fronte, cresta dritta sul dorso del maiale; muso, zoccoli e corna restano nudi. Le carte hanno le normali del corpo e il suo colore.
- **Manti** nei colori dei vertici (per l'occlusione cotta), tre per specie: pecora bianca a muso scuro, bianca, bruna; capra fulva, nera, pezzata; maiale bruno scuro, fulvo, cinghiato; bue fromentino, grigio con spalle scure, bruno. Nel gioco il primo manto è il più comune (50%, 30%, 20%).
- **Parti per l'animazione** nella seconda UV (corpo, collo e testa, quattro zampe, orecchie, coda, con il peso lungo la parte); in `animali.json` perno del collo, passo, spalla e quanto si abbassa la testa per brucare (poco il maiale, che ha la testa già bassa: prima sembrava una proboscide).
- **Shader:** `animali.gdshader` (corpo) e `animali_ciocche.gdshader` (carte, con il ritaglio e le normali tenute verso l'esterno anche dal retro), con le animazioni in comune in `animali_comune.gdshaderinc`. Materiali da `Asset.materiale_animale`, mesh da `Asset.mesh_animale`.
- **Prestazioni:** con la MultiMesh nel renderer Compatibilità servono anche i colori per istanza (bianchi): con i soli dati personalizzati gli animali uscivano neri. Da misurare sui PC di Fede con 400 animali vicini.

| Modello | Misure (m) | Facce del corpo (completo / leggero) | Carte di pelo (completo / leggero) |
|---|---|---|---|
| pecora | 0,8 × 1,45 × 1,0 | 3200 / 260 | 700 / 70 |
| capra | 0,4 × 1,15 × 1,25 | 3000 / 260 | 700 / 70 |
| maiale | 0,5 × 1,35 × 0,8 | 2600 / 260 | 520 / 50 |
| bue | 0,85 × 2,6 × 1,5 | 3600 / 260 | 1000 / 90 |

Foto: `test/foto_animali.gd -- uscita [dimensione] [rotazioni] [leggero]` (per ogni specie i tre manti: fermo, che bruca, a metà passo). Immagini `docs/immagini/animali-pelo-26-11.jpg`, `docs/immagini/animali-pelo-vicino-26-11.jpg`.

## Lotto del villaggio (24/11/2026, Fede: procedi)
Script `strumenti/blender/villaggio.py` → `gioco/asset/villaggio/`, nello stile verosimile della prova (stessi materiali e forme, occlusione cotta). Comando: `blender-py strumenti/blender/villaggio.py gioco/asset/villaggio`, poi `godot --headless --path gioco --import` e, nei nuovi `.import` delle texture, `detect_3d/compress_to=0`.

| Modello | Misure (m) | Facce | Note |
|---|---|---|---|
| casa_lunga_piccola, _media, _grande | 10,8 / 13,8 / 19,9 di lunghezza | | tetto a padiglione di paglia, muri d'argilla, pali a vista |
| capanna_tonda, capanna_tonda_piccola | 7,5 / 6,2 di diametro | | tetto conico a corsi concentrici |
| granaio_su_pali | 3,9 × 3,8 × 5,5 | | cappelli contro i roditori |
| palizzata_tratto | 4,0 × 0,5 × 3,0 | | pali appuntiti con due traverse; si posa in fila |
| palizzata_varco | 5,1 × 0,4 × 3,4 | | stipiti e architrave, mezzo tratto per parte |
| luogo_sacro | 8,7 × 8,6 × 3,0 | | cerchio di nove pali attorno a una pietra eretta (proposta di Claude) |
| focolare | 2,0 × 1,9 × 0,4 | | anello di sassi, cenere, ciocchi |
| fossa_silo | 2,4 × 2,0 × 0,4 | | cupola d'argilla chiusa da una lastra |
| recinto_animali | 9,7 × 10,2 × 1,6 | 844 | graticcio di vimini intrecciati, con un'apertura |
| catasta_legna | 2,4 × 1,3 × 0,9 | 81 | |
| roccia_1, _2, _3 | da 1,0 a 2,4 | 80 | |

Foto di controllo: `gioco/test/foto_villaggio.gd` compone a mano un villaggio sul terrazzo centrale (palizzata, case, luogo sacro, recinto, campi e terra battuta con l'uso del suolo). Immagine: `docs/immagini/villaggio-24-11.jpg`. È solo una prova degli asset: nel gioco il villaggio crescerà da sé (abitato spontaneo, decisione di Fede del 24/11).

