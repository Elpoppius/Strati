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
- **Parti per l'animazione** nella seconda UV (attenzione: l'esportazione glTF capovolge la v, lo shader usa `1 − v`) (corpo, collo e testa, quattro zampe, orecchie, coda, con il peso lungo la parte); in `animali.json` perno del collo, passo, spalla e quanto si abbassa la testa per brucare (poco il maiale, che ha la testa già bassa: prima sembrava una proboscide).
- **Shader:** `animali.gdshader` (corpo) e `animali_ciocche.gdshader` (carte, con il ritaglio e le normali tenute verso l'esterno anche dal retro), con le animazioni in comune in `animali_comune.gdshaderinc`. Materiali da `Asset.materiale_animale`, mesh da `Asset.mesh_animale`.
- **Prestazioni:** con la MultiMesh nel renderer Compatibilità servono anche i colori per istanza (bianchi): con i soli dati personalizzati gli animali uscivano neri. Da misurare sui PC di Fede con 400 animali vicini.

| Modello | Misure (m) | Facce del corpo (completo / leggero) | Carte di pelo (completo / leggero) |
|---|---|---|---|
| pecora | 0,8 × 1,45 × 1,0 | 3200 / 260 | 700 / 70 |
| capra | 0,4 × 1,15 × 1,25 | 3000 / 260 | 700 / 70 |
| maiale | 0,5 × 1,35 × 0,8 | 2600 / 260 | 520 / 50 |
| bue | 0,85 × 2,6 × 1,5 | 3600 / 260 | 1000 / 90 |

Foto: `test/foto_animali.gd -- uscita [dimensione] [rotazioni] [leggero]` (per ogni specie i tre manti: fermo, che bruca, a metà passo). Immagini `docs/immagini/animali-pelo-26-11.jpg`, `docs/immagini/animali-pelo-vicino-26-11.jpg`.

## Persone del villaggio (26/11/2026, voce 7 del todo)
Script `strumenti/blender/persone.py`, cartella `gioco/asset/persone/` (proposta di Claude, da guardare con Fede).
- **Come gli animali:** ogni persona è un corpo unico da un campo di distanza (ellissoidi e coni arrotondati per gambe, bacino, busto, braccia, mani con il pollice, collo, testa, capelli, vesti, cintura, calzari), estratto con marching cubes e semplificato in due livelli: **completo** (circa 3000 facce) e **leggero** (320 facce).
- **Viso e spalle (26/11/2026, rifiniti su richiesta di Fede: da vicino le spalle erano gonfie e il viso senza lineamenti):** il campo accetta anche volumi che **scavano** (`Scava`), applicati nell'ordine in cui si aggiungono: le orbite si scavano e poi ci si mettono gli occhi scuri (classe "occhi"); la bocca è incisa sotto le labbra. Il viso ha mascella e mento (più delicati nelle donne), zigomi, arcate, naso con il dorso e le ali, sopracciglia, orecchie; la calotta dei capelli lascia libere fronte e tempie. Le spalle scendono dal collo con il trapezio, il deltoide è piccolo, braccia e maniche più asciutte; il petto degli uomini è un po' più marcato. Nel modello completo la testa si semplifica a parte e tiene il 40% delle facce (`QUOTA_TESTA`); la griglia è di 5,5 mm. La cucitura della grana della veste sta dietro, non sulla spalla.
- **Sei persone:** uomo 1 capelli lunghi e barba corta; uomo 2 capelli corti e una pelle sulle spalle; uomo 3 crocchia, barba lunga e mantello lungo; donna 1 treccia; donna 2 crocchia e mantello lungo; donna 3 capelli sciolti fino a metà schiena. Uomini 1,74 m, donne 1,62 m (lo stesso scheletro a 0,93); ogni figura nel gioco varia ancora del ±4%.
- **Vesti del Neolitico:** tunica di lana o di lino con le maniche corte, stretta da una cintura di cuoio, al ginocchio per gli uomini e al polpaccio per le donne; mantelli e pelli; calzari di pelle.
- **Colori nello shader**, non nel modello (`shader/persone.gdshader`): la seconda UV porta la parte (busto, testa, braccia, gambe, attrezzo) e la classe (pelle, capelli, veste, mantello, calzari, cintura, legno, selce, vimini); ogni figura sceglie dal suo seme una tinta per ciascuna: quattro incarnati, cinque colori di capelli (il grigio raro), sette vesti di colori naturali (lana grezza, lino, bruno, ocra, verde muschio, rosso mattone spento, grigio), quattro mantelli. I colori dei vertici portano solo l'occlusione cotta. La grana della lana sulle vesti, quella del pelo su capelli e mantelli.
- **Animazioni nello shader** (dati personalizzati della MultiMesh: fase, modo e andatura, lavoro e attrezzo, seme): camminare (gambe dall'anca con il ginocchio, braccia in opposizione, la veste che segue le gambe), stare fermi (la testa che si guarda attorno), parlare (cenni del capo e gesti), lavorare: zappare, tagliare con l'ascia, la lancia in attesa con il colpo ogni tanto, raccogliere chini, costruire, il pastore appoggiato al bastone. Il busto si piega dall'anca; attorno all'attaccatura delle braccia il busto segue un po' il braccio, così alzandolo non si tende una membrana.
- **Attrezzi** (`attrezzo_<nome>_<uomo|donna>.glb`): zappa, ascia, lancia, bastone, cesto, già nella mano destra e girati per stare giusti nella posa "tenere" dello shader; la loro base è a mezz'aria (eccezione in `verifica_asset.gd`).
- Perni del corpo per lo shader in `persone.json`. Foto di controllo: `test/foto_persone.gd -- uscita [dimensione] [rotazioni] [leggero]` (le sei persone nelle pose principali), immagine `docs/immagini/persone-26-11.jpg`; nel gioco `test/foto_partita.gd -- uscita 35 200 0 persone:contadino`. Ritratti ravvicinati (tre figure ferme verso la camera): `test/foto_ritratto.gd -- uscita [uomini|donne] [dimensione] [gradi] [leggero]`, immagine `docs/immagini/ritratti-prima-dopo-26-11.jpg`.

### Vesti dell'epoca 2 (27/11/2026, su richiesta di Fede; proposta di Claude in `epoca2-proposte.md` § 3)
Le stesse sei persone in `PERSONE_2`, esportate come `persona_<nome>_e2[_leggero].glb`. Comando solo per loro: `blender-py strumenti/blender/persone.py gioco/asset/persone e2` (circa 2 minuti; senza `e2` rifà tutte le persone e gli attrezzi).
- **Uomini:** tunica appena sotto il ginocchio, cintura con la placca di bronzo, mantello fermato sulla spalla da una fibula (uomo 1 e 3), fasce alle gambe (uomo 1 e 2), berretto di feltro (uomo 2).
- **Donne:** veste lunga alla caviglia, cintura con tre placchette, bracciali di bronzo sugli avambracci (donna 1 e 3), collana (donna 1 e 2), mantello con la fibula (donna 2).
- **Bronzo:** sul corpo ha la classe 7 (negli attrezzi la stessa classe è la selce). Lo shader, con `epoca = 2`, lo colora di bronzo, lucido e un po' metallico, e sceglie le vesti dalla tavolozza dell'epoca: robbia, reseda, guado, con i colori naturali (`VESTI_2`, `MANTELLI_2`). `Asset.mesh_persona("<nome>_e2")` tiene il seme dei colori della persona da cui viene.
- Foto: `test/foto_persone.gd -- uscita [dimensione] [rotazioni] e2` (davanti l'epoca 2, dietro l'epoca 1 per confronto); immagini `docs/immagini/vesti-epoca2-27-11.jpg`, `vesti-epoca2-vicino-27-11.jpg`.
- Nel gioco non si vedono ancora: la vista le userà quando la simulazione arriverà all'epoca 2.

## Lotto dell'abitato protourbano (27/11/2026, su richiesta di Fede; proposta di Claude)
Script `strumenti/blender/protourbano.py` → `gioco/asset/protourbano/`, con i materiali del villaggio più intonaco, terra, pelle, carbone, minerale e bocca accesa (texture nuove `intonaco.png` e `terra.png`: `python3 strumenti/blender/texture_procedurali.py gioco/asset/texture protourbano`). Comando: `blender-py strumenti/blender/protourbano.py gioco/asset/protourbano [nomi,separati,da,virgola]`. Riferimenti: terramare dell'età del Bronzo e urne a capanna villanoviane.

| Modello | Misure (m) | Facce | Note |
|---|---|---|---|
| casa_impalcato_piccola, _media | 11,4 × 5,9 / 14,4 × 6,9 | 885 / 1005 | capanna rettangolare su impalcato di pali, pareti intonacate, tetto a due falde con le corna incrociate, scaletta |
| casa_del_capo | 26,7 × 15,7 × 8,6 | 3478 | grande, con il portico di pali e il cortile recintato |
| recinto_tratto | 10,1 × 6,0 × 4,3 | 904 | tratto di 10 m: terrapieno, palizzata e camminamento |
| recinto_porta | 11,0 × 6,0 × 8,2 | 1426 | due torri, camminamento coperto, battenti aperti |
| officina_fabbro | 9,1 × 7,6 × 3,1 | 5079 | primo edificio dell'epoca 2 (Fede, 27/11). **Rifatta il 27/11** (Fede: "più personalizzazione, legno e roccia; la fornace non si distingue, l'incudine non si vede"): tettoia a una falda aperta davanti (il lato della via), pali grossi su zoccoli di sassi, dietro metà muretto a secco e metà graticcio; fornace a cupola sul piede di pietre, argilla annerita in alto, camino con le colature di fuliggine, bocca accesa rientrata nella cornice annerita con le braci davanti, mantici di fianco; incudine di pietra chiara fuori dalla tettoia, nello spiazzo di terra battuta; banco di tavole con stampi, crogioli e panelle; rastrelliera con asce, punte di lancia e una spada; sgabello, cassa, cesti di carbone, catasta, minerale, vasca in un tronco scavato. Materiali nuovi: `bronzo` (poco metallico, perché il renderer Compatibilità non ha riflessi e il metallo pieno viene scuro), `brace` (luce propria contenuta: con 4 la bocca era un riquadro bianco), argilla bruciata, fuliggine, pietra chiara, vimini |
| cantiere_officina_fabbro | 8,8 × 6,9 × 2,9 | 3714 | zoccoli e pali, la trave davanti, metà dei correnti, il muretto già su, la fornace col piede di pietre e il corpo a metà; pali, paglia, argilla e sassi a terra |
| casa_impalcato_piccola_b, _media_b | 15,8 × 5,9 / 16,3 × 6,9 | 1248 / 1202 | varianti per la fila sulla via (decisione di Fede del 27/11: le case si sviluppano sulla strada): davanti, sulla via, il banco con vasi, cesto e dolio (piccola) o il telaio a pesi sul ballatoio e un dolio (media); dietro l'orto (piccola) o cataste e pagliaio (media); sui fianchi niente |
| santuario | 10,2 × 10,2 × 4,1 | 3675 | approvato da Fede ("altare e santuario perfetto"): recinto sacro di pali e graticcio con l'ingresso verso la via; edicola a due falde con le corna su un basamento di pietre; altare di pietre e argilla con il fuoco, che fuma; pali votivi con le corna, vasi delle offerte, fossa |
| tumulo | 11,9 × 11,8 × 3,6 | 2366 | monte di terra erbosa con il cerchio di pietre alla base e una stele in cima |
| granaio_comune | 8,8 × 5,2 × 6,7 | 1140 | su pali alti 1,6 m con i dischi di pietra contro i topi, pareti di assi, tetto con le corna, scala a pioli, sacchi e giare |
| pozzo | 4,9 × 5,6 × 3,5 | 1705 | vera di tavole incastrate, bilanciere con contrappeso e secchio, selciato di sassi, abbeveratoio in un tronco |
| recinto_bestiame | 18,3 × 10,4 × 3,1 | 1632 | 16 × 10 m di pali e graticcio, cancello aperto, tettoia sul fondo, terra calpestata, abbeveratoio, fieno, letame |
| ponte | 16,0 × 4,2 × 2,7 | 527 | per i torrenti larghi (Fede, 26/11): impalcato di tavole a 1,4 m su coppie di pali ogni 3 m con traversi e sbadacchi, parapetto, rampe di terra; si posa alla quota delle sponde |
| cantiere_casa_impalcato_piccola, _media, cantiere_casa_del_capo | 12,1 × 8,4 / 15,1 × 9,5 / 21,2 × 11,4 | 751 / 885 / 1171 | impalcato finito, pali delle pareti, travi, puntoni e metà dei correnti, mezzo lato di graticcio; pali, paglia e argilla a terra |
| cantiere_recinto_tratto | 10,1 × 6,9 × 3,6 | 570 | terrapieno a metà, i primi pali della palizzata, gli altri a terra, ceste della terra |
| cantiere_santuario, _granaio_comune, _pozzo, _ponte | — | — | rispettivamente: pali d'angolo, basamento e pali dell'edicola; pilastri coi dischi e il tavolato; selciato e prime file di tavole; pali, traversi e longheroni senza tavole |

Il tumulo e il recinto del bestiame non hanno cantiere (proposta di Claude: il tumulo si alza in un anno, il recinto si tira su come lo stabbio).

Foto: `test/foto_cantieri.gd -- uscita dimensione rotazioni` con i modi `protourbano` (il primo lotto, con una casa lunga del villaggio per confronto), `fabbro` (officina finita e in cantiere), `officina` (solo l'officina, da vicino), `lotto2` (secondo lotto, sotto i cantieri) e `via` (case in fila sui due lati di una via, porta sulla strada, base e varianti alternate; la via è un nastro di terra provvisorio, solo della foto); immagini `docs/immagini/protourbano-27-11.jpg`, `fabbro-27-11.jpg`, `fabbro-rifatto-27-11.jpg`, `fabbro-rifatto-retro-27-11.jpg`, `fabbro-cantiere-27-11.jpg`, `protourbano-lotto2-27-11.jpg`, `case-sulla-via-27-11.jpg`.

### Fumo dei camini (27/11/2026)
Richiesta di Fede ("quanto comporta il fumo che esce dalla fornace, animato?"); decisioni di Fede: **non è legato alla simulazione** (c'è finché c'è l'edificio finito) e **per ora fumano solo le officine e gli edifici comunitari**, "altrimenti diventa una coltre di fumo, ben prima dell'epoca industriale". Le case non fumano.
- **Come è fatto:** `script/vista_fumo.gd` (classe `VistaFumo`, creata da `VistaVillaggio`, `vista.fumo`): una sola MultiMesh di quadrati per tutti i camini, 12 sbuffi per camino con le fasi sfalsate. Il movimento sta in `shader/fumo.gdshader`: ogni sbuffo è rivolto alla camera, nasce alla bocca, sale rallentando (8 m in 10 s), si allarga (da 0,36 a 2,6 m di raggio), piega col vento, schiarisce e sfuma; il contorno è un rumore che scorre nel tempo, così le forme non si ripetono. Funziona con il renderer Compatibilità; le particelle di Godot (un nodo per camino) e il fumo volumetrico (assente in Compatibilità) sono state scartate.
- **Dove nasce:** gli script di Blender scrivono `camini.json` accanto ai modelli (`CAMINI` in `protourbano.py`, coordinate di Godot), poco sotto l'orlo del camino; due valori in più, facoltativi, danno densità e scala. **Fumano** (decisioni di Fede del 27/11/2026): `officina_fabbro`, `santuario` (il fuoco dell'altare) e `casa_del_capo` (il focolare: senza camino, il fumo esce dalla paglia sotto il colmo, più rado e piccolo, densità 0,55 e scala 0,8; foto `docs/immagini/fumo-casa-del-capo-27-11.jpg`). Il granaio comune non fuma (non ha fuoco). La GIF della fornace è approvata da Fede ("perfetto così"). Un edificio nuovo con il fuoco si aggiunge lì; la vista lo trova da sola (`VistaVillaggio._sincronizza_edifici` aggiunge il fumo all'edificio finito e lo toglie al cantiere e alla demolizione).
- **Verifica:** `verifica_asset.gd` (camino dentro la pianta del modello, case senza fumo, fumo che segue posizione e rotazione, tolto con l'edificio); ora la verifica legge anche `asset/protourbano` (lato massimo 30 m per la casa del capo con il cortile).
- **Foto:** `test/foto_fumo.gd -- cartella [fotogrammi] [dimensione] [rotazioni] [passo] [modello]` salva i fotogrammi con il tempo dello shader fisso a ogni scatto; la GIF si fa con Python (Pillow, tavolozza comune di 96 colori): `docs/immagini/fumo-fabbro-27-11.gif`.

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
| torre_avvistamento | 7,0 × 4,2 × 7,2 | 1055 | scorrerie, 26/11/2026 (proposta di Claude): quattro pali con controventi, piano di assi a 4,5 m con parapetto di graticcio, tettuccio di paglia a una falda, scala a pioli, pira per il fuoco di segnalazione e frasche verdi; scala e pira guardano verso il villaggio |
| cantiere_torre_avvistamento | 6,3 × 5,7 × 6,0 | 330 | pali e un lato di controventi, telaio del piano, scala, assi e pali a terra |
| casa_lunga_piccola_b | 16,6 × 8,2 × 6,5 | 905 | variante (todo voce 9, 26/11/2026, proposta di Claude): catasta lungo il fianco, orto recintato di graticcio davanti alla porta |
| casa_lunga_media_b | 17,9 × 10,4 × 7,2 | 1096 | variante: tettoia a una falda staccata dal fianco (ceppo, attrezzo, catasta), recintino per gli animali piccoli |
| casa_lunga_grande_b | 24,6 × 13,1 × 7,9 | 1130 | variante: tettoia, catasta e orto dietro la casa |
| capanna_tonda_b | 8,8 × 9,1 × 5,7 | 344 | variante: telaio con una pelle tesa a seccare, catasta |
| capanna_tonda_piccola_b | 9,6 × 6,2 × 4,7 | 649 | variante: recintino di graticcio |
| passerella | 5,6 × 6,0 × 1,0 | 242 | strade, 26/11/2026 (proposta di Claude approvata da Fede): tronchi di traverso su due correnti, paletti ai lati; pezzo da 6 m che il gioco mette in fila e allunga su torrenti e terreni fradici |

Varianti delle case (26/11/2026): metà dei lotti ha la versione `_b` (`VistaVillaggio.QUOTA_VARIANTI`), con gli annessi fuori dalla gronda perché si vedano. Foto a confronto: `test/foto_cantieri.gd -- uscita 60 2 varianti` (`docs/immagini/varianti-case-26-11.jpg`).

Dal 26/11/2026 `villaggio.py` accetta i nomi dei modelli da esportare (`… gioco/asset/villaggio torre_avvistamento,cantiere_torre_avvistamento`): così gli altri file non si riscrivono.

Foto di controllo: `gioco/test/foto_villaggio.gd` compone a mano un villaggio sul terrazzo centrale (palizzata, case, luogo sacro, recinto, campi e terra battuta con l'uso del suolo). Immagine: `docs/immagini/villaggio-24-11.jpg`. È solo una prova degli asset: nel gioco il villaggio crescerà da sé (abitato spontaneo, decisione di Fede del 24/11).

## Cursori (26/11/2026 sera, richiesta di Fede)
Tre SVG da 32 × 32 px in `gioco/asset/cursori/`, fatti da noi: `freccia.svg` (punta in 3, 2), `scegli.svg` (la freccia con un quadratino, quando sotto il puntatore c'è qualcosa da scegliere), `strumento.svg` (mirino squadrato, punta al centro). Bianco #f4f4f0 con il bordo #1b1b1b, come l'HUD. Si impostano con `Cursori.imposta()`.

## Grandezza degli edifici delle risorse (26/11/2026 sera)
Fede: capanno, legnaia e gli altri vanno ingranditi alla misura delle case. I modelli restano quelli di `villaggio.py`; nel gioco si disegnano 1,8 volte più grandi legnaia, capanno da pesca e posta di caccia (e i loro cantieri), 1,4 il granaio (`VistaVillaggio.SCALA_EDIFICI`).

