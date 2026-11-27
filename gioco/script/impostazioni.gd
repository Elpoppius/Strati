class_name Impostazioni
extends RefCounted
## Impostazioni del gioco (todo voce 10; contenuto proposto da Claude e approvato da Fede il
## 26/11/2026: "tutto ok"). Valgono per tutte le partite e stanno in un file solo:
## D:\Godot\Strati\impostazioni.cfg su Windows, accanto a Registro e Salvataggi; altrove, o se D:
## non c'è, nella cartella dei dati di Godot. Si cambiano dalla finestra Impostazioni (F10, o
## Strumenti › Partita › Impostazioni), che le salva subito.

const CARTELLA_PC := "D:/Godot/Strati"
const FILE := "impostazioni.cfg"

## Le voci, nell'ordine della finestra: chiave -> sezione, nome, scelte [valore, testo], predefinito,
## spiegazione breve.
const VOCI := [
	{"chiave": "tutorial", "sezione": "Partita", "nome": "Tutorial", "scelte": [[true, "Accesi"], [false, "Spenti"]], "predefinito": true,
		"nota": "Le schede che spiegano le novità, nelle partite nuove."},
	{"chiave": "automatici", "sezione": "Partita", "nome": "Salvataggi automatici", "scelte": [["tappe_50", "Tappe e 50 anni"], ["tappe", "Solo tappe"], ["no", "Spenti"]], "predefinito": "tappe_50",
		"nota": "Se ne tengono gli ultimi tre."},
	{"chiave": "velocita_partenza", "sezione": "Partita", "nome": "Tempo dopo la fondazione", "scelte": [[0, "Fermo"], [1, "Lento"], [2, "Medio"], [3, "Veloce"]], "predefinito": 0,
		"nota": "Come parte il tempo appena fondato il villaggio."},
	{"chiave": "qualita", "sezione": "Grafica", "nome": "Qualità", "scelte": [["bassa", "Bassa"], ["media", "Media"], ["alta", "Alta"]], "predefinito": "alta",
		"nota": "Alberi completi, ombre, persone e animali visibili. Bassa per le schede video integrate."},
	{"chiave": "fps", "sezione": "Grafica", "nome": "Fotogrammi al secondo", "scelte": [[30, "30"], [60, "60"], [0, "Senza limite"]], "predefinito": 0,
		"nota": "30 scalda meno i portatili."},
	{"chiave": "schermo_intero", "sezione": "Grafica", "nome": "Schermo", "scelte": [[false, "Finestra"], [true, "Intero"]], "predefinito": false,
		"nota": ""},
	{"chiave": "scala", "sezione": "Grafica", "nome": "Scala dell'interfaccia", "scelte": [[1.0, "100%"], [1.25, "125%"], [1.5, "150%"]], "predefinito": 1.0,
		"nota": "Per gli schermi grandi o lontani."},
	{"chiave": "registro", "sezione": "Registro tecnico", "nome": "Registro", "scelte": [[true, "Acceso"], [false, "Spento"]], "predefinito": true,
		"nota": "Un file per sessione con i tempi e gli errori, per le prove. Vale dal prossimo avvio."},
]

## I tre livelli della qualità: distanze dei livelli degli alberi, persone e animali, ombre, bordi.
const LIVELLI := {
	"bassa": {"alberi_completi": 110.0, "alberi_leggeri": 400.0, "figure": 60, "figure_visibili": 300.0, "animali": 150, "ombre": 1024, "msaa": Viewport.MSAA_DISABLED},
	"media": {"alberi_completi": 160.0, "alberi_leggeri": 550.0, "figure": 100, "figure_visibili": 380.0, "animali": 250, "ombre": 2048, "msaa": Viewport.MSAA_2X},
	"alta": {"alberi_completi": 220.0, "alberi_leggeri": 700.0, "figure": 150, "figure_visibili": 450.0, "animali": 400, "ombre": 4096, "msaa": Viewport.MSAA_2X},
}

## I tasti, per la finestra (sola lettura).
const COMANDI := [
	["Spazio", "ferma e fa ripartire il tempo"],
	["+ · −", "più veloce · più lento"],
	["Rotella · tasto destro", "zoom · spostare la vista"],
	["Q · E", "ruotare la vista"],
	["Inizio", "tornare al villaggio"],
	["1–8", "mappe: normale e tematiche"],
	["G · I", "griglia dei lotti · isoipse"],
	["F · Z · C · N · B", "fondare, zona, campo, pascolo, bosco sacro"],
	["L · K · T · H · O · U", "legnaia, capanno, posta, granaio, luogo sacro, torre"],
	["V · X", "sentiero · demolisci"],
	["[ · ]", "raggio dello strumento"],
	["P · R · Y", "politiche · rapporti di forza · anni"],
	["Esc", "annullare lo strumento o chiudere"],
	["F5 · F8", "salvare · riprendere una partita"],
	["F10", "impostazioni"],
	["F3 · F9", "finestra Debug · segnalibro nel registro"],
]

static var valori := {}
## Percorso scelto (vuoto: quello normale). Le verifiche usano un file loro.
static var percorso_voluto := ""
## Dove si è letto o scritto l'ultima volta.
static var percorso_usato := ""


static func percorso() -> String:
	if percorso_voluto != "":
		return percorso_voluto
	if OS.get_name() == "Windows" and (DirAccess.dir_exists_absolute(CARTELLA_PC) or DirAccess.make_dir_recursive_absolute(CARTELLA_PC) == OK):
		return CARTELLA_PC.path_join(FILE)
	return "user://".path_join(FILE)


static func voce(chiave: String) -> Dictionary:
	for v in VOCI:
		if v["chiave"] == chiave:
			return v
	return {}


## Il valore di una voce (il predefinito se non è stata ancora scelta).
static func valore(chiave: String) -> Variant:
	if valori.has(chiave):
		return valori[chiave]
	return voce(chiave).get("predefinito")


## I valori della qualità scelta.
static func livello() -> Dictionary:
	return LIVELLI.get(String(valore("qualita")), LIVELLI["alta"])


## Legge il file; le voci mancanti o con valori sconosciuti prendono il predefinito.
static func carica() -> void:
	valori = {}
	percorso_usato = percorso()
	var f := ConfigFile.new()
	if f.load(percorso_usato) != OK:
		return
	for v in VOCI:
		var x: Variant = f.get_value("impostazioni", v["chiave"], v["predefinito"])
		var ammesso := false
		for s in v["scelte"]:
			if typeof(s[0]) == typeof(x) and s[0] == x or (typeof(s[0]) == TYPE_FLOAT and (typeof(x) == TYPE_INT or typeof(x) == TYPE_FLOAT) and is_equal_approx(float(s[0]), float(x))):
				ammesso = true
				x = s[0]
		if ammesso:
			valori[v["chiave"]] = x


static func salva() -> bool:
	percorso_usato = percorso()
	var f := ConfigFile.new()
	for v in VOCI:
		f.set_value("impostazioni", v["chiave"], valore(v["chiave"]))
	return f.save(percorso_usato) == OK


## Cambia una voce e la salva subito.
static func imposta(chiave: String, x: Variant) -> void:
	valori[chiave] = x
	salva()


## Le misure della qualità nelle viste (si possono cambiare a partita in corso).
static func applica_qualita() -> void:
	var l := livello()
	VistaAlberi.DIM_COMPLETI = float(l["alberi_completi"])
	VistaAlberi.DIM_LEGGERI = float(l["alberi_leggeri"])
	VistaPersone.TETTO = int(l["figure"])
	VistaPersone.DIM_VISIBILI = float(l["figure_visibili"])
	VistaVillaggio.MASSIMO_ANIMALI = int(l["animali"])


## Le voci della grafica che toccano la finestra e il motore (non nelle verifiche senza schermo).
static func applica_finestra(albero: SceneTree) -> void:
	var l := livello()
	Engine.max_fps = int(valore("fps"))
	if DisplayServer.get_name() == "headless":
		return
	albero.root.msaa_3d = int(l["msaa"])
	RenderingServer.directional_shadow_atlas_set_size(int(l["ombre"]), true)
	var intero: bool = valore("schermo_intero")
	var ora := DisplayServer.window_get_mode()
	var e_intero := ora == DisplayServer.WINDOW_MODE_FULLSCREEN or ora == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	if intero != e_intero:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if intero else DisplayServer.WINDOW_MODE_WINDOWED)
