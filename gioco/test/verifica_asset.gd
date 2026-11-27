extends SceneTree
## Verifica gli asset 3D: si caricano, poggiano sul suolo (base a quota 0) e hanno misure plausibili.
## Uso: godot --headless --path gioco -s res://test/verifica_asset.gd

const CARTELLE := ["res://asset/prove_stile", "res://asset/villaggio", "res://asset/persone", "res://asset/protourbano"]
const ALTEZZA_MAX := 20.0
const LATO_MAX := 30.0  # la casa del capo con il cortile arriva a 27 m

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
			var ok := box.position.y > -0.3 and box.position.y < 0.05 and box.size.y < ALTEZZA_MAX and box.size.x < LATO_MAX and box.size.z < LATO_MAX and box.size.y > 0.3
			# Gli attrezzi delle persone stanno già nella mano: la loro base è a mezz'aria.
			if file.begins_with("attrezzo_"):
				ok = box.position.y > -0.3 and box.position.y < 1.5 and box.size.y < 2.5 and box.size.y > 0.1
			controlla(ok, "%s: %.1f x %.1f x %.1f m, base a quota %.2f" % [file.get_basename(), box.size.x, box.size.z, box.size.y, box.position.y])
	controlla(totale > 0, "trovati %d asset" % totale)
	_verifica_fumo()
	print("Verifica completata: %s" % ("nessun errore" if _errori == 0 else "%d errori" % _errori))
	quit(1 if _errori > 0 else 0)


## Fumo dei camini (27/11/2026): ogni camino di `camini.json` ha il suo modello e sta sopra di esso,
## entro la sua pianta; la MultiMesh ha SBUFFI sbuffi per camino e li toglie con l'edificio.
func _verifica_fumo() -> void:
	var camini := VistaFumo.camini()
	controlla(camini.has("officina_fabbro"), "l'officina del fabbro ha il camino")
	for nome in camini:
		var percorso := ""
		for cartella in CARTELLE:
			if ResourceLoader.exists("%s/%s.glb" % [cartella, nome]):
				percorso = "%s/%s.glb" % [cartella, nome]
		if percorso == "":
			controlla(false, "il camino di %s ha il suo modello" % nome)
			continue
		var nodo: Node3D = (load(percorso) as PackedScene).instantiate()
		var box := _aabb(nodo)
		nodo.free()
		var p: Vector3 = camini[nome]
		var dentro := p.x >= box.position.x and p.x <= box.end.x and p.z >= box.position.z and p.z <= box.end.z
		controlla(dentro and p.y > 1.0 and p.y <= box.end.y, "il fumo di %s nasce dal camino (%.1f, %.1f, %.1f)" % [nome, p.x, p.y, p.z])
	var fumo := VistaFumo.new()
	var nodo := Node3D.new()
	nodo.position = Vector3(100, 5, 200)
	nodo.rotation_degrees.y = 90.0
	controlla(fumo.aggiungi_edificio("a", "officina_fabbro", nodo), "il fumo si aggiunge all'officina")
	controlla(not fumo.aggiungi_edificio("b", "casa_impalcato_piccola", nodo), "le case non fumano (Fede, 27/11/2026)")
	# (Senza grafica la MultiMesh non tiene le trasformazioni: si legge il punto di partenza.)
	controlla(fumo.multimesh.instance_count == VistaFumo.SBUFFI, "%d sbuffi per camino" % VistaFumo.SBUFFI)
	var atteso: Vector3 = nodo.transform * (camini["officina_fabbro"] as Vector3)
	controlla(fumo.bocca("a").distance_to(atteso) < 0.01, "il fumo segue posizione e rotazione dell'edificio")
	fumo.togli("a")
	controlla(fumo.multimesh.instance_count == 0, "il fumo si toglie con l'edificio")
	nodo.free()
	fumo.free()


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
