class_name Salvataggio
extends RefCounted
## Salvataggio della partita (todo voce 9, 26/11/2026; proposte di Claude in attesa dello sguardo
## di Fede: cartella, tasti, salvataggi automatici).
##
## Un file per salvataggio, compresso, con due parti lette una dopo l'altra: l'intestazione
## (versione, mappa, sito, anno, abitanti, data: basta questa per l'elenco) e il corpo, con tutto
## lo stato della simulazione, l'uso del suolo e ciò che la partita tiene fra un anno e l'altro.
## Lo stato della simulazione si prende in modo generico, variabile per variabile dello script
## (così una variabile nuova si salva da sola); restano fuori i riferimenti agli oggetti della
## scena (mappa, alberi, funzioni), che al caricamento sono già quelli della partita in corso.
## Figure, animali e disegni non si salvano: si ridispongono da soli dalla simulazione.

## Si cambia quando un salvataggio vecchio non si può più leggere bene (allora il gioco lo dice).
const VERSIONE := 1
const ESTENSIONE := "strati"
const CARTELLA_PC := "D:/Godot/Strati/Salvataggi"
const CARTELLA_RISERVA := "user://salvataggi"
## Salvataggi automatici tenuti (i più vecchi si cancellano).
const AUTOMATICI := 3
## Variabili della simulazione che non si salvano: riferimenti alla scena.
const ESCLUSE_SIM := ["dati", "alberi", "albero_presente", "bosco_presente"]

## Cartella usata (vuota finché non si è salvato o letto). Nelle verifiche si può cambiare.
static var cartella_voluta := ""


## La cartella dei salvataggi: D:\Godot\Strati\Salvataggi su Windows (accanto al Registro), altrove
## o se D: non c'è la cartella dei dati di Godot.
static func cartella() -> String:
	var candidate: Array[String] = []
	if cartella_voluta != "":
		candidate.append(cartella_voluta)
	else:
		if OS.get_name() == "Windows":
			candidate.append(CARTELLA_PC)
		candidate.append(CARTELLA_RISERVA)
	for c in candidate:
		if DirAccess.dir_exists_absolute(c) or DirAccess.make_dir_recursive_absolute(c) == OK:
			return c
	return CARTELLA_RISERVA


## Le variabili di uno script come dizionario (nome -> valore). I generatori di numeri casuali si
## salvano come seme e stato; gli altri oggetti e le funzioni restano fuori.
static func stato_di(o: Object, escluse: Array = []) -> Dictionary:
	var out := {}
	for p in o.get_property_list():
		if not (int(p["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		var nome: String = p["name"]
		if nome in escluse:
			continue
		var v: Variant = o.get(nome)
		match typeof(v):
			TYPE_OBJECT:
				if v is RandomNumberGenerator:
					out[nome] = {"__casuale": [(v as RandomNumberGenerator).seed, (v as RandomNumberGenerator).state]}
			TYPE_CALLABLE, TYPE_SIGNAL, TYPE_RID:
				pass
			_:
				out[nome] = v
	return out


## Rimette le variabili salvate in un oggetto. Le liste e i dizionari tipizzati tornano del loro
## tipo; le variabili che non ci sono più si ignorano, quelle nuove restano come sono.
static func applica_stato(o: Object, stato: Dictionary) -> void:
	var tipi := {}
	for p in o.get_property_list():
		if int(p["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			tipi[p["name"]] = true
	for nome in stato:
		if not tipi.has(nome):
			continue
		var v: Variant = stato[nome]
		var ora: Variant = o.get(nome)
		if v is Dictionary and (v as Dictionary).has("__casuale") and ora is RandomNumberGenerator:
			(ora as RandomNumberGenerator).seed = v["__casuale"][0]
			(ora as RandomNumberGenerator).state = v["__casuale"][1]
		elif ora is Array and (ora as Array).is_typed() and v is Array:
			var a := ora as Array
			var nuovo := Array([], a.get_typed_builtin(), a.get_typed_class_name(), a.get_typed_script())
			nuovo.assign(v)
			o.set(nome, nuovo)
		elif ora is Dictionary and (ora as Dictionary).is_typed() and v is Dictionary:
			var d := ora as Dictionary
			var nuovo_d := Dictionary({}, d.get_typed_key_builtin(), d.get_typed_key_class_name(), d.get_typed_key_script(),
				d.get_typed_value_builtin(), d.get_typed_value_class_name(), d.get_typed_value_script())
			nuovo_d.assign(v)
			o.set(nome, nuovo_d)
		else:
			o.set(nome, v)


## Intestazione di un salvataggio della partita in corso.
static func intestazione(p: Partita, automatico: bool) -> Dictionary:
	var sim := p.sim
	var sito := ""
	if sim.fondato:
		sito = p.nome_luogo() if p.has_method("nome_luogo") else ""
	return {"versione": VERSIONE, "mappa": sim.dati.nome, "anno": sim.anno, "abitanti": roundi(sim.pop),
		"fondato": sim.fondato, "sito": sito, "tappa": String(SimVillaggio.TAPPE[sim.tappa]["nome"]) if sim.fondato else "",
		"data": Time.get_datetime_string_from_system(false, true), "automatico": automatico,
		"gioco": ProjectSettings.get_setting("application/config/version", "")}


## Salva la partita. `nome` vuoto: un nome dalla data. Restituisce il percorso, vuoto se non riesce.
static func salva(p: Partita, nome := "", automatico := false) -> String:
	p.prepara_salvataggio()
	var c := cartella()
	if nome == "":
		var ora := Time.get_datetime_dict_from_system()
		nome = "%s-%04d-%02d-%02d-%02d%02d%02d" % ["automatico" if automatico else "partita", ora["year"], ora["month"], ora["day"], ora["hour"], ora["minute"], ora["second"]]
	var percorso := c.path_join("%s.%s" % [nome, ESTENSIONE])
	var f := FileAccess.open_compressed(percorso, FileAccess.WRITE, FileAccess.COMPRESSION_ZSTD)
	if f == null:
		return ""
	f.store_var(intestazione(p, automatico))
	var uso: UsoSuolo = p.scena.uso
	f.store_var({"sim": stato_di(p.sim, ESCLUSE_SIM), "uso": uso.stato_salvato(), "partita": p.stato_salvato()})
	f.close()
	if automatico:
		_pulisci_automatici(c)
	return percorso


## Tiene solo gli ultimi AUTOMATICI salvataggi automatici.
static func _pulisci_automatici(c: String) -> void:
	var auto: Array[String] = []
	for nome in DirAccess.get_files_at(c):
		if nome.begins_with("automatico-") and nome.ends_with("." + ESTENSIONE):
			auto.append(nome)
	auto.sort()
	while auto.size() > AUTOMATICI:
		DirAccess.remove_absolute(c.path_join(auto.pop_front()))


## Legge solo l'intestazione (per l'elenco). Vuota se il file non si legge.
static func leggi_intestazione(percorso: String) -> Dictionary:
	var f := FileAccess.open_compressed(percorso, FileAccess.READ, FileAccess.COMPRESSION_ZSTD)
	if f == null:
		return {}
	var v: Variant = f.get_var()
	f.close()
	return v if v is Dictionary else {}


## I salvataggi della cartella, dal più recente: intestazione più "percorso".
static func elenco() -> Array:
	var out: Array = []
	var c := cartella()
	for nome in DirAccess.get_files_at(c):
		if not nome.ends_with("." + ESTENSIONE):
			continue
		var t := leggi_intestazione(c.path_join(nome))
		if t.is_empty():
			continue
		t["percorso"] = c.path_join(nome)
		out.append(t)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["data"]) > String(b["data"]))
	return out


## Perché un salvataggio non si può caricare in questa partita (vuoto se si può).
static func motivo_carica(p: Partita, t: Dictionary) -> String:
	if t.is_empty():
		return "Il file non si legge."
	if int(t.get("versione", 0)) != VERSIONE:
		return "Salvataggio di una versione diversa del gioco: non si può caricare."
	if String(t.get("mappa", "")) != p.sim.dati.nome:
		return "Salvataggio di un'altra mappa (%s)." % t.get("mappa", "")
	return ""


## Carica un salvataggio nella partita in corso. Restituisce il motivo se non riesce, vuoto se sì.
static func carica(p: Partita, percorso: String) -> String:
	var f := FileAccess.open_compressed(percorso, FileAccess.READ, FileAccess.COMPRESSION_ZSTD)
	if f == null:
		return "Il file non si apre."
	var t: Variant = f.get_var()
	var m := motivo_carica(p, t if t is Dictionary else {})
	if m != "":
		f.close()
		return m
	var corpo: Variant = f.get_var()
	f.close()
	if not (corpo is Dictionary and (corpo as Dictionary).has("sim") and (corpo as Dictionary).has("uso")):
		return "Il salvataggio è rovinato."
	applica_stato(p.sim, corpo["sim"])
	(p.scena.uso as UsoSuolo).ripristina(corpo["uso"])
	p.ripristina(corpo.get("partita", {}))
	return ""
