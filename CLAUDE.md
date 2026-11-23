# Istruzioni per Claude

**Strati** è il progetto di Fede: un gestionale urbanistico-politico in cui il giocatore governa una città europea verosimile attraverso i secoli. Ispirazione centrale: lo sventramento di Parigi di Haussmann, riletto in chiave contemporanea. Lo costruiscono Fede e Claude, da soli, a costo zero.

## All'inizio di ogni sessione
1. Leggi `docs/diario.md` (ultime voci in cima): cosa è stato fatto, cosa è deciso, qual è il prossimo passo.
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
- **Asset:** solo con licenza libera (CC0) o creati da noi. Niente marchi, personaggi o opere protette.

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
- `godot --headless --path gioco -s res://test/verifica_base.gd` esegue le verifiche della base. Devono passare tutte prima di ogni push.
- `python3 strumenti/mappe/genera_pedecollinare.py gioco/mappe/pedecollinare` rigenera i dati della mappa; poi `godot --headless --path gioco -s res://strumenti/importa_mappa.gd -- pedecollinare` li converte in `mappa.res`.
- `xvfb-run -a -s "-screen 0 1600x900x24" godot --path gioco --rendering-driver opengl3 --resolution 1600x900 -s res://test/foto.gd -- /tmp/foto.png [modo] [dimensione_vista] [rotazioni]` salva un'immagine reale della scena (schermo virtuale, rendering software). Serve a controllare shader e aspetto; non sostituisce le prove di Fede.
- `python3 strumenti/blender/texture_procedurali.py gioco/asset/texture` rigenera le texture; `blender-py strumenti/blender/prova_stile_verosimile.py gioco/asset/prove_stile /tmp/tavola.png vicino` rigenera gli asset della prova di stile con un'anteprima; poi `godot --headless --path gioco --import` e `godot --headless --path gioco -s res://test/verifica_asset.gd`. Per vederli nel gioco: `test/foto_asset.gd` (stessa riga di comando di `foto.gd`, argomenti: uscita, cartella degli asset, dimensione della vista). Regole e stile: `docs/asset.md`.

## Base del gioco (stato)
- Scena principale: `gioco/scene/principale.tscn` con `script/principale.gd`, che costruisce tutto da codice.
- Mappa: `gioco/mappe/pedecollinare/` (dati grezzi generati in Python, convertiti in `mappa.res`, classe `MappaDati`). Griglia di 256 x 256 punti da 40 m; acque disegnate da un campo di distanza a 1024 x 1024.
- Coordinate: 1 unità = 1 metro; x verso est, z verso sud; quote con esagerazione verticale 1,5.
- Asset: caricarli sempre con `Asset.istanzia(percorso)` (`script/asset.gd`), che attiva l'occlusione cotta nei colori dei vertici.
- Resa grafica (terreno, prato, acqua, luce e ombre, alberi): sistemi comuni a tutte le mappe, descritti in `docs/resa-grafica.md`. Foto di controllo: `test/foto.gd`, `test/foto_asset.gd`, `test/foto_luogo.gd -- dimensione bosco|acqua`.
- Lotti: griglia di 20 m disegnata dallo shader del terreno; il lotto sotto il puntatore si calcola intersecando il raggio della camera con il terreno (niente fisica).
