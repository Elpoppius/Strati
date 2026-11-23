extends SceneTree
## Verifica gli asset 3D: si caricano, poggiano sul suolo (base a quota 0) e hanno misure plausibili.
## Uso: godot --headless --path gioco -s res://test/verifica_asset.gd

const CARTELLE := ["res://asset/prove_stile"]
const ALTEZZA_MAX := 20.0
const LATO_MAX := 25.0

var _errori := 0


func _initialize() -> void:
	var totale := 0
	for cartella in CARTELLE:
		var dir := DirAccess.open(cartella)
		if dir == null:
			controlla(false, "la cartella %s esiste" % cartella)
			continue
		for file in dir.get_files():
			if not file.ends_with(".glb"):
				continue
			totale += 1
			var percorso: String = cartella + "/" + file
			var scena := load(percorso) as PackedScene
			if scena == null:
				controlla(false, "%s si carica" % file)
				continue
			var nodo: Node3D = scena.instantiate()
			var box := _aabb(nodo)
			nodo.free()
			# La base sta a quota 0; alberi e pali possono affondare fino a 30 cm, per non restare sospesi sui pendii.
			var ok := box.position.y > -0.3 and box.position.y < 0.05 and box.size.y < ALTEZZA_MAX and box.size.x < LATO_MAX and box.size.z < LATO_MAX and box.size.y > 0.5
			controlla(ok, "%s: %.1f x %.1f x %.1f m, base a quota %.2f" % [file.get_basename(), box.size.x, box.size.z, box.size.y, box.position.y])
	controlla(totale > 0, "trovati %d asset" % totale)
	print("Verifica completata: %s" % ("nessun errore" if _errori == 0 else "%d errori" % _errori))
	quit(1 if _errori > 0 else 0)


func _aabb(nodo: Node) -> AABB:
	var risultato := AABB()
	var primo := true
	for m in nodo.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		var b := _trasformazione(mi, nodo) * mi.get_aabb()
		if primo:
			risultato = b
			primo = false
		else:
			risultato = risultato.merge(b)
	return risultato


## Trasformazione di un nodo rispetto alla radice dell'asset (senza bisogno dell'albero della scena).
func _trasformazione(n: Node3D, radice: Node) -> Transform3D:
	var t := Transform3D.IDENTITY
	var corrente: Node = n
	while corrente != null and corrente != radice:
		if corrente is Node3D:
			t = (corrente as Node3D).transform * t
		corrente = corrente.get_parent()
	return t


func controlla(condizione: bool, descrizione: String) -> void:
	print(("OK  " if condizione else "NO  ") + descrizione)
	if not condizione:
		_errori += 1
