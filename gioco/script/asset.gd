class_name Asset
extends RefCounted
## Funzioni comuni per gli asset 3D importati da Blender.

const SHADER_FOGLIE := preload("res://shader/foglie.gdshader")


## Carica un asset .glb e lo prepara per il gioco. Restituisce null se il file manca.
static func istanzia(percorso: String) -> Node3D:
	var scena := load(percorso) as PackedScene
	if scena == null:
		return null
	var nodo: Node3D = scena.instantiate()
	prepara(nodo)
	return nodo


## L'occlusione ambientale è cotta nei colori dei vertici: l'importatore glTF non sempre
## la attiva, quindi la si abilita su tutti i materiali dell'asset. Le foglie delle chiome
## (materiali "foglie_*" con ritaglio dell'alfa) passano allo shader foglie.gdshader, che fa
## svanire le carte viste di taglio.
static func prepara(nodo: Node) -> void:
	for m in nodo.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		if mi.mesh == null:
			continue
		for i in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(i) as BaseMaterial3D
			if mat == null:
				continue
			mat.vertex_color_use_as_albedo = true
			if mat.resource_name.begins_with("foglie") and mat.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR:
				mi.mesh.surface_set_material(i, materiale_foglie(mat))


## Materiale delle foglie con le carte di taglio che svaniscono, dallo stesso aspetto di `mat`.
static func materiale_foglie(mat: BaseMaterial3D) -> ShaderMaterial:
	var sm := ShaderMaterial.new()
	sm.resource_name = mat.resource_name
	sm.shader = SHADER_FOGLIE
	sm.set_shader_parameter("tessitura", mat.albedo_texture)
	sm.set_shader_parameter("ruvidita", mat.roughness)
	return sm
