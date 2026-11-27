class_name VistaFumo
extends MultiMeshInstance3D
## Fumo dei camini (27/11/2026; decisioni di Fede: non legato alla simulazione, per ora solo le
## officine e gli edifici comunitari). Una sola MultiMesh per tutti i camini della mappa: ogni camino
## ha SBUFFI quadrati con le fasi sfalsate; il movimento sta tutto in `shader/fumo.gdshader`.
##
## Dove nasce il fumo di ogni modello lo scrivono gli script di Blender in `camini.json`, accanto ai
## modelli (coordinate del modello in Godot). Un edificio con il camino si aggiunge con
## `aggiungi_edificio(chiave, modello, nodo)` quando è finito e si toglie con `togli(chiave)`.

const SBUFFI := 12
const FILE_CAMINI := ["res://asset/protourbano/camini.json", "res://asset/villaggio/camini.json"]

## Modello -> punto del camino (coordinate del modello). Si legge una volta sola.
static var _camini := {}
static var _camini_letti := false

## Per le foto: se è zero o più, il tempo resta fermo lì invece di scorrere.
var tempo_fisso := -1.0
var tempo := 0.0
var _bocche := {}  # chiave -> [posizione nel mondo, densità, scala]
var _materiale: ShaderMaterial


func _init() -> void:
	name = "Fumo"
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_custom_data = true
	multimesh.mesh = quad
	_materiale = ShaderMaterial.new()
	_materiale.shader = load("res://shader/fumo.gdshader")
	_materiale.render_priority = 2
	material_override = _materiale
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# I vertici si spostano nello shader: il riquadro di prova non deve tagliare fuori gli sbuffi.
	custom_aabb = AABB(Vector3(-20000, -500, -20000), Vector3(40000, 2000, 40000))


static func camini() -> Dictionary:
	if not _camini_letti:
		_camini_letti = true
		for percorso in FILE_CAMINI:
			if not FileAccess.file_exists(percorso):
				continue
			var dati = JSON.parse_string(FileAccess.get_file_as_string(percorso))
			if dati is Dictionary:
				for nome in dati:
					var v: Array = dati[nome]
					_camini[nome] = Vector3(float(v[0]), float(v[1]), float(v[2]))
	return _camini


static func ha_camino(modello: String) -> bool:
	return camini().has(modello)


## Aggiunge il fumo di un edificio già posato (posizione, rotazione e scala dal nodo). Restituisce
## false se il modello non ha un camino.
func aggiungi_edificio(chiave, modello: String, nodo: Node3D, densita := 1.0) -> bool:
	if not ha_camino(modello):
		return false
	var t := nodo.transform
	if nodo.is_inside_tree():
		t = nodo.global_transform
	aggiungi(chiave, t * (camini()[modello] as Vector3), densita, t.basis.get_scale().x)
	return true


func aggiungi(chiave, punto: Vector3, densita := 1.0, scala := 1.0) -> void:
	_bocche[chiave] = [punto, densita, scala]
	_ricostruisci()


func togli(chiave) -> void:
	if _bocche.erase(chiave):
		_ricostruisci()


## Dove nasce il fumo di un camino (nel mondo).
func bocca(chiave) -> Vector3:
	return _bocche[chiave][0] if _bocche.has(chiave) else Vector3.ZERO


func quanti() -> int:
	return _bocche.size()


func _ricostruisci() -> void:
	multimesh.instance_count = _bocche.size() * SBUFFI
	var i := 0
	for chiave in _bocche:
		var b: Array = _bocche[chiave]
		# Seme fisso per camino: due camini vicini non fumano all'unisono.
		var rnd := RandomNumberGenerator.new()
		rnd.seed = hash(b[0])
		var sfasa := rnd.randf()
		for k in SBUFFI:
			multimesh.set_instance_transform(i, Transform3D(Basis(), b[0]))
			var fase := fmod(sfasa + (float(k) + rnd.randf_range(-0.3, 0.3)) / SBUFFI, 1.0)
			multimesh.set_instance_custom_data(i, Color(fase, rnd.randf(), float(b[1]) * rnd.randf_range(0.8, 1.0), float(b[2]) * rnd.randf_range(0.85, 1.15)))
			i += 1


func _process(delta: float) -> void:
	tempo = tempo_fisso if tempo_fisso >= 0.0 else tempo + delta
	_materiale.set_shader_parameter("tempo", tempo)
