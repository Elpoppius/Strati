# Produzione e collaborazione

*Fattibilità, ruoli, strumenti e metodo di lavoro.*

## Ruoli
- **Claude:** codice (GDScript), simulazione, strumenti (es. conversione dei dati altimetrici), edifici procedurali, documentazione e design; test automatici dove possibile.
- **Fede:** installazione e avvio del gioco, prove di gioco e valutazione di cosa funziona, direzione artistica, segnalazione di errori, decisioni.
- **Limiti di Claude:** non ricorda il codice tra una sessione e l'altra (il repository è la memoria comune); il codice avrà bug, quindi il ciclo è: Claude scrive → Fede prova → Fede riporta → Claude corregge.

## Collaborazione su due account Claude
Il Progetto Claude e la memoria sono legati al singolo account. La fonte unica di verità è il **repository GitHub** `Elpoppius/Strati` (pubblico):
- `docs/`: documenti di design;
- `docs/diario.md`: diario di bordo, aggiornato a fine sessione (fatto, deciso, prossimo passo);
- `CLAUDE.md`: istruzioni per qualunque sessione di Claude;
- codice e prototipi.

Metodo: a inizio sessione "leggi CLAUDE.md e il diario"; a fine sessione "aggiorna il diario".

## GitHub
Claude non ha bisogno di un proprio account. Per ogni account Claude serve:
1. GitHub collegato da claude.ai (Impostazioni → Connettori);
2. l'app di Claude installata sull'account GitHub con accesso al repository Strati.

## Strumenti (tutti gratuiti)
| Cosa | Strumento |
|---|---|
| Motore | Godot 4.7.2 standard, renderer Compatibilità |
| Terreno | Mesh generata da codice (`gioco/script/terreno.gd`); Terrain3D (componente aggiuntivo, licenza libera) resta un'alternativa da valutare se servirà |
| Modelli 3D | Blender 5.3 |
| Dati altimetrici | QGIS |
| Grafica 2D e interfaccia | Krita o GIMP |
| Versioni | Git e GitHub (GitHub Desktop sui PC di Fede) |
| Riferimenti open source | Micropolis (codice del primo SimCity), Julius e Augustus (rifacimenti di Caesar III) |

Guida all'installazione sui PC di Fede: `setup-pc.md`.

**Renderer Compatibilità:** Fede lavora da tre PC con configurazioni diverse; il renderer Compatibilità funziona anche con schede video integrate e permette di pubblicare il gioco nel browser. Si potrà cambiare più avanti.

## Strumenti nell'ambiente di lavoro di Claude (verificato il 23/11/2026)
- **Godot 4.7.2** senza grafica: creazione e controllo di progetti e scene, script, test automatici, importazione di risorse. Non può mostrare né giocare il gioco.
- **Blender 5.3** come modulo Python (`bpy`): modellazione da script, esportazione glTF, rendering di anteprime (Cycles su CPU). Il sito di download di Blender non è raggiungibile dall'ambiente; si installa da PyPI.
- **Catena provata:** casa lunga neolitica modellata in Blender da script (`strumenti/blender/casa_lunga.py`) → esportata in glTF → importata e caricata in un progetto Godot.
- **Attenzione:** l'ambiente di lavoro non è condiviso tra sessioni o account. Gli strumenti si reinstallano con `sh scripts/setup_strumenti.sh` (circa 2–3 minuti).
- Nessun connettore Blender o Godot nel catalogo dei connettori.

## Mod di giochi esistenti
Valutato e scartato. Cities: Skylines è a pagamento, centrato sul traffico moderno, senza epoche, stratificazione o lotti di proprietà; un mod si distribuisce solo a chi possiede il gioco. Caesar III (via Augustus) è limitato all'epoca romana. I sistemi distintivi del progetto sono proprio quelli che un mod non può aggiungere.

## Asset
- **Stile verosimile, anche nei colori** (decisione di Fede, 23/11/2026); riferimento per l'aspetto: Age of Empires IV. Lo stile "plastico architettonico" e gli alberi con pochi poligoni sono scartati. Guida completa: `asset.md`.
- **Edifici procedurali** generati dalla forma del lotto (pianta, piani, tetto, materiali secondo l'epoca), soprattutto dalle epoche urbane in poi.
- **Pochi pezzi fatti a mano**: monumenti e tipologie riconoscibili di ogni epoca (casa lunga, granaio, tempio, cattedrale, palazzo, stazione…).
- **Modelli e texture creati da script** (Blender e texture procedurali): alberi, canne, case, materiali. Pacchetti con licenza CC0 solo dove servono e se coerenti con lo stile: quelli a pochi poligoni (Kenney, Quaternius, KayKit) non lo sono; per le texture si può attingere a Poly Haven.

## Stima
| Fase | Contenuto | Tempo indicativo |
|---|---|---|
| 0 | Prototipo web dei sistemi del villaggio | 2–4 settimane |
| 1 | Base in Godot: terreno, camera, lotti, edifici procedurali, mappe tematiche | 2–4 mesi |
| 2 | Prima Era giocabile (Origini) | 3–6 mesi |
| 3 | Un'epoca per volta fino all'età industriale | anni |

Fede può lavorarci ogni giorno. Il gioco completo è un progetto di più anni; ogni fase produce qualcosa di giocabile, pubblicabile gratuitamente man mano (es. itch.io).

## Percorso
1. Mappa pedecollinare (fatto: vedi `mappa-pedecollinare.md`).
2. Prototipo 0 come pagina web giocabile (`prototipi/prototipo0/index.html`; versione pubblicata: https://claude.ai/artifact/CkFtLeu96dPjqCL5vGJYSo). In prova da parte di Fede.
3. Repository GitHub creato e collegato a entrambi gli account Claude (fatto). Fede prepara un PC dedicato con Godot 4.7.2, Blender 5.3 e GitHub Desktop.
4. Base del progetto Godot (fatto, 23/11/2026): terreno della mappa pedecollinare, camera isometrica ruotabile, mappe tematiche, griglia dei lotti. Provata da Fede sui suoi PC.
5. Resa grafica comune a tutte le mappe (in corso): prova di stile verosimile, prato, acqua, paludi con canneti, alberi veri sulla mappa con livelli di dettaglio. Vedi `asset.md` e `resa-grafica.md`.
6. Prossimo: completare il lotto del villaggio nello stile scelto e portare in Godot il ciclo del Prototipo 0 sulla mappa vera (proposta di Claude, da confermare con Fede).

## Prototipo 0 — stato
**Contenuto:** mappa pedecollinare generata da codice (64 × 64 celle da circa 160 m), mappe tematiche Terreno, Acqua, Fertilità, Rischio piena; zoom (1–6×) e spostamento della mappa; azioni Fondare, Campi, Sentiero, Granaio (da posizionare), usanza sul raccolto; indicatori popolazione, cibo, salute, legittimità; tempo continuo (2, 6 o 15 anni al secondo) con pausa automatica nei momenti decisivi; siccità con presagio vero (sorgenti che calano), cometa come presagio falso, piene di fiume e torrenti; memoria del rischio; affollamento (allargarsi o villaggio figlio); fallimento come strato (rovine e rifondazione); partita di 500 anni (6000–5500 a.C.) con riepilogo finale.

**Modifiche dopo le prove di Fede:**
- altezze stabili sotto la mappa e nella colonna destra (niente scatti quando il testo va a capo);
- cronaca spostata sotto la mappa;
- conferme visive sulla mappa (celle valide in verde, non valide in rosso, puntini per proseguire il sentiero, cerchio che si espande dove si costruisce);
- zoom e spostamento, case disegnate come case lunghe viste dall'alto;
- case che non sorgono sui sentieri; sentieri a struttura ad albero (incroci a +);
- granaio da posizionare scegliendo la cella;
- avvisi a schermo solo per eventi rilevanti (siccità, carestie gravi); finestre bloccanti solo per scelte e fatti gravi.

**Aggiunte rispetto al piano:** le piene, per dare un senso alla mappa del rischio e alla memoria del rischio.

**Note di bilanciamento (test automatici, 500 anni per sito):** tutti i siti sono sopravvivibili; dosso nelle paludi con salute più bassa; area dei gessi e pianura aperta più fragili alle carestie. Le popolazioni finali (alcune centinaia, a volte vicino al migliaio) sono alte per un villaggio neolitico: da ricalibrare dopo le prove di Fede.

**Proposta in sospeso:** recinto come primo strumento di regolazione (vedi `regolazione-dello-spazio.md`).
