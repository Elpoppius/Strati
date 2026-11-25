# Istruzioni per Claude

**Strati** è il progetto di Fede: un gestionale urbanistico-politico in cui il giocatore governa una città europea verosimile attraverso i secoli. Ispirazione centrale: lo sventramento di Parigi di Haussmann, riletto in chiave contemporanea. Lo costruiscono Fede e Claude, da soli, a costo zero.

## All'inizio di ogni sessione
1. Leggi `docs/diario.md` (ultime voci in cima): cosa è stato fatto, cosa è deciso, qual è il prossimo passo. Poi `docs/todo.md`: il lavoro in corso e il suo ordine; aggiornalo quando una voce è fatta o cambia.
2. Leggi i documenti di design in `docs/` che riguardano il lavoro del giorno.
3. Se servono Godot o Blender, esegui `sh scripts/setup_strumenti.sh` (2–3 minuti). L'ambiente di lavoro non si conserva tra sessioni.

## Alla fine di ogni sessione
Aggiungi in cima a `docs/diario.md` una voce con data, cosa è stato fatto, decisioni prese (con chi le ha prese), prossimo passo. Poi fai commit e push.

## Regole
- **Lingua:** italiano, per documenti, commenti nel codice, testi del gioco e messaggi di commit.
- **Le decisioni di design sono di Fede.** Claude propone; una proposta entra nei documenti come decisione solo quando Fede la conferma. Le proposte non ancora confermate si segnano come tali.
- **Principio di produzione:** prima la profondità, poi l'ampiezza. Un'epoca giocabile bene vale più di sei abbozzate.
- **Due account Claude** lavorano sullo stesso repository: tutto ciò che serve a riprendere il lavoro deve stare qui, non nella memoria di una conversazione.
- **Versioni:** Godot 4.7.2 (la stessa sui PC di Fede e nell'ambiente di Claude), Blender 5.3 (come modulo Python `bpy` nell'ambiente di Claude). Guida per i PC: `docs/setup-pc.md`.
- **Renderer:** Compatibilità. Fede lavora da tre PC con schede video diverse, alcune forse integrate; il renderer Compatibilità funziona ovunque e permette di pubblicare il gioco nel browser.
- **Verifica:** Claude non vede il gioco in movimento. Prima di consegnare, esegui i test senza grafica; poi Fede prova e riporta.
- **Prove con i giocatori "umani"** (decisione di Fede del 25/11/2026): sono la base dei test futuri. Ogni modifica che tocca le dinamiche si prova con `test/giocatore_umano.gd` e i suoi profili: chi impara sbagliando, chi si ferma a leggere, chi conosce il genere ma non legge e va a tentativi, il giocatore casual che ripete gli errori e continua solo per il gusto di giocare.
- **Testi del gioco:** il gioco è a sé stante: nei testi che vede il giocatore (comandi, descrizioni, suggerimenti, cronaca, scelte) non si citano altri giochi usati come riferimento (decisione di Fede del 24/11/2026). Nei documenti e nei commenti del codice si possono citare.
- **Asset:** solo con licenza libera (CC0) o creati da noi. Per i caratteri è ammessa la SIL Open Font License 1.1, rispettandone le regole (decisione di Fede del 24/11/2026): testo della licenza accanto ai file, elenco in `docs/licenze.md`. Niente marchi, personaggi o opere protette.

## Struttura
| Cartella | Contenuto |
|---|---|
| `docs/` | Documenti di design e diario di bordo |
| `gioco/` | Progetto Godot |
| `prototipi/` | Prototipi web (Prototipo 0: il villaggio) |
| `strumenti/` | Script di supporto (Blender, conversione mappe) |
| `scripts/` | Installazione degli strumenti nell'ambiente di Claude |

## Comandi utili (ambiente di Claude)
Dopo `sh scripts/setup_strumenti.sh`, aggiungi i comandi al percorso: `export PATH=$HOME/bin:$PATH`.
- `godot --headless --path gioco --import` importa le risorse del progetto (da rifare dopo ogni modifica a script o risorse).
- `godot --headless --path gioco -s res://test/verifica_base.gd` esegue le verifiche della base. Devono passare tutte prima di ogni push, insieme a `verifica_asset.gd`, `verifica_alberi.gd`, `verifica_cache_alberi.gd`, `verifica_uso_suolo.gd`, `verifica_acqua.gd`, `verifica_hud.gd`, `verifica_villaggio.gd` e `verifica_partita.gd`.
- `godot --headless --path gioco -s res://test/sessioni_giocatori.gd -- /tmp/sessioni.csv [semi] [livelli] [siti]` gioca partite automatiche a dieci livelli di bravura e scrive gli abitanti nel tempo (circa 25 minuti per tutto; risultati e metodo in `docs/sessioni-giocatori.md`).
- `godot --headless --path gioco -s res://test/registro_avvisi.gd -- /tmp/avvisi.txt [livello]` gioca cinque partite e scrive tutto ciò che il giocatore vede (pause, notifiche, cronaca), con i conti per partita: serve a controllare il ritmo.
- `godot --headless --path gioco -s res://test/giocatore_umano.gd -- /tmp/umano.txt [semi]` gioca 72 partite con quattro giocatori "umani" (impara sbagliando, legge, conosce il genere, casual) che vedono solo ciò che vede il giocatore (circa 15 minuti). I gesti comuni dei giocatori automatici (per esempio dove mettere una legnaia) stanno in `test/aiuti_giocatori.gd`.
- `godot --headless --path gioco -s res://test/misura_alberi.gd` misura i tempi degli alberi e stampa l'impronta dei dati di tutta la mappa: se si cambia solo la velocità del calcolo, l'impronta deve restare uguale.
- `python3 strumenti/mappe/genera_pedecollinare.py gioco/mappe/pedecollinare` rigenera i dati della mappa; poi `godot --headless --path gioco -s res://strumenti/importa_mappa.gd -- pedecollinare` li converte in `mappa.res`.
- `xvfb-run -a -s "-screen 0 1600x900x24" godot --path gioco --rendering-driver opengl3 --resolution 1600x900 -s res://test/foto.gd -- /tmp/foto.png [modo] [dimensione_vista] [rotazioni]` salva un'immagine reale della scena (schermo virtuale, rendering software). Serve a controllare shader e aspetto; non sostituisce le prove di Fede.
- `python3 strumenti/blender/texture_procedurali.py gioco/asset/texture` rigenera le texture; `blender-py strumenti/blender/prova_stile_verosimile.py gioco/asset/prove_stile /tmp/tavola.png vicino` rigenera gli asset della prova di stile con un'anteprima; poi `godot --headless --path gioco --import` e `godot --headless --path gioco -s res://test/verifica_asset.gd`. Il lotto del villaggio: `blender-py strumenti/blender/villaggio.py gioco/asset/villaggio` (foto di controllo: `test/foto_villaggio.gd`; edifici finiti e cantieri a confronto: `test/foto_cantieri.gd -- uscita [dimensione] [rotazioni]`; capanno da pesca sulla riva e posta di caccia al margine del bosco: `test/foto_posa.gd -- uscita capanno|posta dimensione rotazioni`). Per vederli nel gioco: `test/foto_asset.gd` (stessa riga di comando di `foto.gd`, argomenti: uscita, cartella degli asset, dimensione della vista). Regole e stile: `docs/asset.md`.

## Base del gioco (stato)
- Scena principale: `gioco/scene/principale.tscn` con `script/principale.gd`, che costruisce tutto da codice.
- Mappa: `gioco/mappe/pedecollinare/` (dati grezzi generati in Python, convertiti in `mappa.res`, classe `MappaDati`). Griglia di 256 x 256 punti da 40 m; acque disegnate da un campo di distanza a 1024 x 1024.
- Coordinate: 1 unità = 1 metro; x verso est, z verso sud; quote con esagerazione verticale 1,5.
- Alberi: dati in `script/alberi.gd` (posa deterministica per blocchi dal campo `bosco_fine` della mappa), disegno in `script/vista_alberi.gd` (MultiMesh per blocco preparate su altri thread, livelli completo/leggero/sagome/volta dipinta secondo lo zoom). Modelli da `blender-py strumenti/blender/alberi_mappa.py gioco/asset/alberi`; dopo averli cambiati vanno rifatte le sagome per la vista lontana: `xvfb-run -a -s "-screen 0 1600x900x24" godot --path gioco --rendering-driver opengl3 -s res://strumenti/genera_sagome.gd`. Gli alberi di tutta la mappa si salvano dopo il primo calcolo in `user://cache/` e si ricaricano agli avvii successivi; la cache si scarta da sola se cambiano la mappa o `alberi.gd`. Dopo una nuova importazione, nei file `.import` delle texture tenere `detect_3d/compress_to=0` e le mipmap attive, altrimenti Godot riscrive i file sui PC di Fede.
- Uso del suolo: `script/uso_suolo.gd` (classe `UsoSuolo`, griglia da 10 m): taglio, ricrescita, campi, costruzioni, memoria del bosco (regole di Fede in testa al file). L'invasività è una qualità nascosta dei materiali di ogni costruzione: usare `uso.costruisci(celle, tipo)` con un tipo di `UsoSuolo.COSTRUZIONI`. La vista filtra gli alberi dei blocchi toccati; lo shader del terreno legge `uso.texture`.
- HUD: `script/hud.gd` (classe `Hud`): stile svizzero e regole dei colori in `docs/hud.md`; i comandi si aggiungono con `hud.aggiungi_menu(id, titolo, descrizione, voci, blocco)` nei blocchi costruzione, gestione, strumenti; le politiche con `hud.aggiungi_politiche()`. Foto di controllo: `test/foto_hud.gd`.
- Partita (Prototipo 0 in Godot): simulazione `script/sim_villaggio.gd` (senza grafica), disegno `script/vista_villaggio.gd`, collegamento `script/partita.gd`. Descrizione, regole e numeri in `docs/prototipo0-godot.md` (contado che cresce con gli abitanti, zona agricola in cui le famiglie dissodano da sole, economia mista con fonti di cibo, tecniche dei campi e ammodernamento, piene di stagione e disastrose, notifiche che non fermano il gioco, sentieri liberi con anteprima). Capanno da pesca e posta di caccia: `sim.posa_capanno` e `sim.posa_posta` agganciano alla riva e al margine con i campi fini della mappa (`MappaDati.valore_fine`), pesce e selvaggina stanno in riquadri di 200 m (`celle_acqua`, `celle_bosco`, `scorta_pesce`, `scorta_selvaggina`). Foto di controllo: `test/foto_partita.gd -- uscita dimensione anni [mappa] [strumento|politiche|tecniche|anteprima|fondazione|capanno|posta|cantiere]`. Gli edifici costruiti dal giocatore si disegnano in `VistaVillaggio._sincronizza_edifici`: scheletro e barra finché c'è il cantiere (`CANTIERI`), poi il modello finito.
- Era delle Origini (Villaggio e Abitato protourbano): cronologia, nomenclatura, meccaniche decise e traguardi della taratura in `docs/era-origini.md`.
- Testi del gioco e ritmo: i principi decisi da Fede stanno in testa a `docs/pilastri-e-decisioni.md` (ritmo meditativo) e nelle Regole qui sopra (niente riferimenti ad altri giochi nei testi).
- Asset: caricarli sempre con `Asset.istanzia(percorso)` (`script/asset.gd`), che attiva l'occlusione cotta nei colori dei vertici.
- Resa grafica (terreno, prato, acqua, luce e ombre, alberi): sistemi comuni a tutte le mappe, descritti in `docs/resa-grafica.md`. Foto di controllo: `test/foto.gd`, `test/foto_asset.gd`, `test/foto_luogo.gd -- dimensione bosco|acqua|palude|gessi`.
- Lotti: griglia di 20 m disegnata dallo shader del terreno; il lotto sotto il puntatore si calcola intersecando il raggio della camera con il terreno (niente fisica).
