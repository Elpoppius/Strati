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
- `godot --headless --path gioco --import` importa le risorse del progetto.
- `godot --headless --path gioco -s percorso/script.gd` esegue uno script di prova.
- `blender-py strumenti/blender/casa_lunga.py uscita.glb anteprima.png` modella, esporta e crea un'anteprima.
