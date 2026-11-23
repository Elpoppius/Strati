class_name Asset
extends RefCounted
## Funzioni comuni per gli asset 3D importati da Blender.


## Carica un asset .glb e lo prepara per il gioco. Restituisce null se il file manca.
static func istanzia(percorso: String) -> Node3D:
	var scena := load(percorso) as PackedScene
	if scena == null:
		return null
	var nodo: Node3D = scena.instantiate()
	prepara(nodo)
	return nodo


## L'occlusione ambientale è cotta nei colori dei vertici: l'importatore glTF non sempre
## la attiva, quindi la si abilita su tutti i materiali dell'asset.
static func prepara(nodo: Node) -> void:
	for m in nodo.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		if mi.mesh == null:
			continue
		for i in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(i) as BaseMaterial3D
			if mat:
				mat.vertex_color_use_as_albedo = true
