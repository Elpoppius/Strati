# Preparare un PC per il progetto

Guida per i PC di Fede (tre configurazioni diverse). Tutto gratuito. Da ripetere su ogni PC.

## 1. Godot 4.7.2
Usare **esattamente la 4.7.2** su tutti i PC (e nell'ambiente di Claude): versioni diverse possono modificare i file del progetto in modo incompatibile.

1. Vai su godotengine.org → Download → Archive → **4.7.2**.
2. Scarica la versione **standard** (non ".NET") per il tuo sistema: Windows 64 bit, macOS o Linux.
3. Godot non si installa: è un unico programma. Su Windows estrai lo zip in una cartella fissa, per esempio `C:\Strumenti\Godot\`, e crea un collegamento sul desktop. Su macOS trascina l'app in Applicazioni.
4. Facoltativo, comodo con più PC: nella stessa cartella dell'eseguibile crea un file vuoto chiamato `._sc_`. Godot terrà impostazioni ed editor in quella cartella (modalità "autonoma").

**Grafica:** il progetto usa il renderer **Compatibilità**, che funziona anche con schede video integrate e permette di pubblicare il gioco giocabile nel browser. Non serve fare nulla: è impostato nel progetto.

## 2. Blender 5.3
Serve meno di Godot (pochi modelli fatti a mano), ma conviene averlo uguale ovunque.

1. Vai su blender.org → Download. Se la versione proposta non è la 5.3, scegli "Previous versions" e prendi la **5.3**.
2. Su Windows puoi scegliere tra l'installer e la versione **portatile** (zip): la portatile si comporta come Godot, basta estrarla in una cartella.
3. Al primo avvio lascia le impostazioni predefinite.

## 3. GitHub Desktop
Per scaricare il progetto e tenerlo allineato tra i PC.

1. Scarica GitHub Desktop da desktop.github.com e accedi con l'account GitHub.
2. File → Clone repository → scegli il repository del progetto → indica una cartella, per esempio `Documenti\Progetti\`.
3. Ogni volta che inizi a lavorare: **Fetch origin**, poi **Pull**. Così hai l'ultima versione scritta da Claude.

## 4. Aprire il gioco
1. Apri Godot → **Importa** → seleziona il file `gioco/project.godot` dentro la cartella del repository.
2. Premi **F5** per avviare.
3. Se qualcosa non va, copia il testo del pannello "Output" in basso e incollalo a Claude.

## Riepilogo delle versioni
| Strumento | Versione |
|---|---|
| Godot | 4.7.2 standard |
| Blender | 5.3 |
| Renderer del progetto | Compatibilità |
