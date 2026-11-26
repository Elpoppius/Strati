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


## Animali del pascolo (26/11/2026): un corpo unico per specie con le carte di pelo attorno (come
## le chiome degli alberi), tre manti, due livelli di dettaglio (strumenti/blender/animali.py). Il
## corpo usa animali.gdshader, le carte animali_ciocche.gdshader: grana, ritaglio e animazioni di
## zampe, testa, orecchie e coda.
const SHADER_ANIMALI := preload("res://shader/animali.gdshader")
const SHADER_CIOCCHE := preload("res://shader/animali_ciocche.gdshader")
const MANTI_ANIMALI := 3
static var _materiali_animali := {}
static var _dati_animali := {}


## La mesh di un animale: `manto` da 1 a MANTI_ANIMALI, `leggero` per la media distanza. Le
## superfici hanno già i materiali degli animali (corpo e carte di pelo).
static func mesh_animale(specie: String, manto: int, leggero: bool = false) -> Mesh:
	var percorso := "res://asset/villaggio/animale_%s_%d%s.glb" % [specie, manto, "_leggero" if leggero else ""]
	var scena := load(percorso) as PackedScene
	if scena == null:
		push_error("Modello mancante: " + percorso)
		return null
	var nodo := scena.instantiate()
	var mesh := (nodo.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).mesh
	nodo.free()
	for i in mesh.get_surface_count():
		var m := mesh.surface_get_material(i)
		var carte := m != null and m.resource_name.begins_with("ciocche")
		mesh.surface_set_material(i, materiale_animale(specie, carte))
	return mesh


## Il materiale di una specie, del corpo o delle carte di pelo (condiviso da manti e livelli).
static func materiale_animale(specie: String, carte: bool = false) -> ShaderMaterial:
	var chiave := specie + (":carte" if carte else "")
	if _materiali_animali.has(chiave):
		return _materiali_animali[chiave]
	if _dati_animali.is_empty():
		var f := FileAccess.open("res://asset/villaggio/animali.json", FileAccess.READ)
		if f != null:
			_dati_animali = JSON.parse_string(f.get_as_text())
	var d: Dictionary = _dati_animali.get(specie, {})
	var m := ShaderMaterial.new()
	m.shader = SHADER_CIOCCHE if carte else SHADER_ANIMALI
	var lana := specie == "pecora"
	m.set_shader_parameter("grana", load("res://asset/texture/lana.png" if lana else "res://asset/texture/pelo.png"))
	# Medie lineari delle texture, misurate il 26/11/2026: il manto resta quello dei vertici.
	m.set_shader_parameter("media_grana", 0.471 if lana else 0.357)
	if carte:
		m.set_shader_parameter("ciocche", load("res://asset/texture/ciocche_lana.png" if lana else "res://asset/texture/ciocche.png"))
		m.set_shader_parameter("media_ciocche", 0.475 if lana else 0.474)
	if d.has("perno_collo"):
		var p: Array = d["perno_collo"]
		var g: Array = d["giunto_testa"]
		m.set_shader_parameter("perno_collo", Vector3(p[0], p[1], p[2]))
		m.set_shader_parameter("giunto_testa", Vector3(g[0], g[1], g[2]))
		m.set_shader_parameter("peso_testa", float(d["peso_testa"]))
		m.set_shader_parameter("angolo_collo", float(d["angolo_collo"]))
		m.set_shader_parameter("angolo_testa", float(d["angolo_testa"]))
		m.set_shader_parameter("abbassa_bruca", float(d["abbassa_bruca"]))
		m.set_shader_parameter("passo", float(d["passo"]))
		m.set_shader_parameter("spalla", float(d["spalla"]))
	_materiali_animali[chiave] = m
	return m


## Il passo di una specie (metri per ciclo), per legare le zampe alla strada fatta.
static func passo_animale(specie: String) -> float:
	materiale_animale(specie)
	return float((_dati_animali.get(specie, {}) as Dictionary).get("passo", 0.6))


## Popolazione visibile (26/11/2026, voce 7 del todo): 3 uomini e 3 donne, due livelli di dettaglio,
## e gli attrezzi nella mano destra (strumenti/blender/persone.py). Colori e animazioni stanno in
## persone.gdshader; i perni del corpo in asset/persone/persone.json.
const SHADER_PERSONE := preload("res://shader/persone.gdshader")
const PERSONE := ["uomo_1", "uomo_2", "uomo_3", "donna_1", "donna_2", "donna_3"]
const ATTREZZI := ["zappa", "ascia", "lancia", "bastone", "cesto"]
static var _materiali_persone := {}
static var _dati_persone := {}


static func _mesh_da(percorso: String) -> Mesh:
	var scena := load(percorso) as PackedScene
	if scena == null:
		push_error("Modello mancante: " + percorso)
		return null
	var nodo := scena.instantiate()
	var mesh := (nodo.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).mesh
	nodo.free()
	return mesh


## La mesh di una persona (`nome` in PERSONE), completa o leggera, con il suo materiale.
static func mesh_persona(nome: String, leggero: bool = false) -> Mesh:
	var mesh := _mesh_da("res://asset/persone/persona_%s%s.glb" % [nome, "_leggero" if leggero else ""])
	if mesh != null:
		for i in mesh.get_surface_count():
			mesh.surface_set_material(i, materiale_persona(nome.begins_with("donna"), PERSONE.find(nome) * 0.137))
	return mesh


## La mesh di un attrezzo (`nome` in ATTREZZI) per un uomo o una donna.
static func mesh_attrezzo(nome: String, donna: bool) -> Mesh:
	var mesh := _mesh_da("res://asset/persone/attrezzo_%s_%s.glb" % [nome, "donna" if donna else "uomo"])
	if mesh != null:
		for i in mesh.get_surface_count():
			mesh.surface_set_material(i, materiale_persona(donna, 0.0))
	return mesh


static func materiale_persona(donna: bool, variante: float) -> ShaderMaterial:
	var chiave := "%s:%.3f" % ["donna" if donna else "uomo", variante]
	if _materiali_persone.has(chiave):
		return _materiali_persone[chiave]
	if _dati_persone.is_empty():
		var f := FileAccess.open("res://asset/persone/persone.json", FileAccess.READ)
		if f != null:
			_dati_persone = JSON.parse_string(f.get_as_text())
	var d: Dictionary = _dati_persone.get("donna" if donna else "uomo", {})
	var m := ShaderMaterial.new()
	m.shader = SHADER_PERSONE
	m.set_shader_parameter("grana_veste", load("res://asset/texture/lana.png"))
	m.set_shader_parameter("grana_capelli", load("res://asset/texture/pelo.png"))
	m.set_shader_parameter("variante", variante)
	for k in ["anca", "x_anca", "ginocchio", "collo", "peso_gomito", "peso_ginocchio"]:
		if d.has(k):
			m.set_shader_parameter(k, float(d[k]))
	for k in ["spalla", "gomito"]:
		if d.has(k):
			var v: Array = d[k]
			m.set_shader_parameter(k, Vector3(v[0], v[1], v[2]))
	_materiali_persone[chiave] = m
	return m


## Metri per ciclo del passo (due passi), per legare le gambe alla strada fatta.
static func passo_persona(donna: bool) -> float:
	materiale_persona(donna, 0.0)
	return float((_dati_persone.get("donna" if donna else "uomo", {}) as Dictionary).get("passo", 1.35))
