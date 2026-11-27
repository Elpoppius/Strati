class_name VistaRecinto
extends Node3D
## Il recinto dell'abitato (epoca 2; decisioni di Fede del 27/11/2026): terrapieno, palizzata e
## fossato generati lungo la linea tracciata dal giocatore, così vanno bene a qualsiasi forma e non
## servono modelli degli angoli. Alle porte il modello `recinto_porta` (asset/protourbano). I tratti
## non ancora fatti si vedono come un cordolo di terra smossa; la bozza mentre si traccia è un nastro
## chiaro. La zona dell'abitato si vede (quadrati chiari sui lotti) solo con gli strumenti che la
## riguardano.

const ALTO := 1.6          # terrapieno, in cima
const BASE := 3.0          # mezza larghezza alla base
const CIMA := 1.2          # mezza larghezza in cima
const PASSO := 2.0         # metri fra un campione e l'altro della linea
const PASSO_PALI := 0.27
const FOSSATO := [4.0, 8.0]  # distanza dal centro della linea, verso fuori
const LARGO_PORTA := 5.5     # mezzo varco della porta, dove il terrapieno si interrompe

var sim: SimVillaggio
var terreno: Terreno
var _chiave := ""
var _terrapieno: MeshInstance3D
var _fossato: MeshInstance3D
var _pali: MultiMeshInstance3D
var _punte: MultiMeshInstance3D
var _porte: Array = []
var _bozza: MeshInstance3D
var _zona: MultiMeshInstance3D
var _chiave_zona := ""
var _mat_terra: StandardMaterial3D
var _mat_legno: StandardMaterial3D


func prepara(s: SimVillaggio, t: Terreno) -> void:
	sim = s
	terreno = t
	name = "Recinto"
	_mat_terra = StandardMaterial3D.new()
	_mat_terra.albedo_texture = load("res://asset/texture/terra.png")
	_mat_terra.albedo_color = Color(0.82, 0.76, 0.64)
	_mat_terra.uv1_triplanar = true
	_mat_terra.uv1_world_triplanar = true
	_mat_terra.uv1_scale = Vector3.ONE * 0.25
	_mat_terra.roughness = 1.0
	_mat_legno = StandardMaterial3D.new()
	_mat_legno.albedo_texture = load("res://asset/texture/corteccia.png")
	_mat_legno.albedo_color = Color(0.8, 0.72, 0.62)
	_mat_legno.roughness = 1.0
	_terrapieno = MeshInstance3D.new()
	_terrapieno.material_override = _mat_terra
	add_child(_terrapieno)
	_fossato = MeshInstance3D.new()
	var mf := StandardMaterial3D.new()
	mf.albedo_color = Color(0.2, 0.22, 0.18)
	mf.roughness = 0.35
	_fossato.material_override = mf
	_fossato.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_fossato)
	_pali = _nuova_mm(_mesh_palo(false))
	_punte = _nuova_mm(_mesh_palo(true))
	_bozza = MeshInstance3D.new()
	var mb := StandardMaterial3D.new()
	mb.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mb.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mb.albedo_color = Color(1, 1, 1, 0.55)
	mb.cull_mode = BaseMaterial3D.CULL_DISABLED
	mb.render_priority = 2
	_bozza.material_override = mb
	_bozza.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_bozza)
	_zona = MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var quad := PlaneMesh.new()
	quad.size = Vector2(17.0, 17.0)
	mm.mesh = quad
	_zona.multimesh = mm
	var mz := StandardMaterial3D.new()
	mz.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mz.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mz.vertex_color_use_as_albedo = true
	mz.render_priority = 1
	_zona.material_override = mz
	_zona.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_zona.visible = false
	add_child(_zona)


func _nuova_mm(mesh: Mesh) -> MultiMeshInstance3D:
	var mmi := MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mmi.multimesh = mm
	mmi.material_override = _mat_legno
	add_child(mmi)
	return mmi


func _mesh_palo(punta: bool) -> Mesh:
	var c := CylinderMesh.new()
	c.radial_segments = 6
	c.rings = 1
	if punta:
		c.top_radius = 0.0
		c.bottom_radius = 0.12
		c.height = 0.4
	else:
		c.top_radius = 0.12
		c.bottom_radius = 0.13
		c.height = 1.0
	return c


func _quota(w: Vector2) -> float:
	return terreno.quota_mondo(w.x, w.y)


## Rifà il recinto se è cambiato (punti, tratti fatti, porte).
func sincronizza() -> void:
	var chiave := "%s|%d|%d" % [str(sim.recinto_punti), sim.recinto_fatti, sim.porte.size()]
	if chiave == _chiave:
		return
	_chiave = chiave
	for p in _porte:
		(p as Node3D).queue_free()
	_porte = []
	if not sim.recinto_tracciato():
		_terrapieno.mesh = null
		_fossato.mesh = null
		_pali.multimesh.instance_count = 0
		_punte.multimesh.instance_count = 0
		return
	var punti: Array = sim.recinto_punti
	var area := SimVillaggio._area(punti)
	var fatto_fino := float(sim.recinto_fatti) * SimVillaggio.LATO_TRATTO
	var finito := sim.recinto_pronto()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sf := SurfaceTool.new()
	sf.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pali: Array[Transform3D] = []
	var punte: Array[Transform3D] = []
	var caso := RandomNumberGenerator.new()
	caso.seed = 7
	var lungo := 0.0
	for k in punti.size():
		var a: Vector2 = punti[k]
		var b: Vector2 = punti[(k + 1) % punti.size()]
		var d := (b - a).normalized()
		# Verso fuori: a destra del lato se l'anello gira in senso antiorario (area positiva).
		var fuori := Vector2(d.y, -d.x) if area > 0.0 else Vector2(-d.y, d.x)
		var tratto := a.distance_to(b)
		var passi := maxi(1, ceili(tratto / PASSO))
		for j in passi:
			var p0 := a.lerp(b, float(j) / passi)
			var p1 := a.lerp(b, float(j + 1) / passi)
			var s0 := lungo + tratto * float(j) / passi
			var mezzo := (p0 + p1) * 0.5
			if _in_porta(mezzo):
				continue
			var costruito := s0 < fatto_fino or finito
			var alto := ALTO if costruito else 0.35
			var base := BASE if costruito else 1.6
			var cima := CIMA if costruito else 1.0
			# Sezione: base dentro, cima dentro, cima fuori, base fuori.
			var sezione := [[-base, 0.0], [-cima, alto], [cima, alto], [base, 0.0]]
			for f in 3:
				var q := [p0 + fuori * float(sezione[f][0]), p0 + fuori * float(sezione[f + 1][0]),
					p1 + fuori * float(sezione[f + 1][0]), p1 + fuori * float(sezione[f][0])]
				var h := [float(sezione[f][1]), float(sezione[f + 1][1]), float(sezione[f + 1][1]), float(sezione[f][1])]
				var v: Array[Vector3] = []
				for i in 4:
					v.append(Vector3(q[i].x, _quota(q[i]) + h[i] - 0.05, q[i].y))
				var nrm := (v[1] - v[0]).cross(v[3] - v[0]).normalized()
				if nrm.y < 0.0:
					nrm = -nrm
				for idx in [0, 1, 2, 0, 2, 3]:
					st.set_normal(nrm)
					st.add_vertex(v[idx])
			# Il fossato, fuori, solo dove il terrapieno è fatto.
			if costruito:
				var fq := [p0 + fuori * FOSSATO[0], p0 + fuori * FOSSATO[1], p1 + fuori * FOSSATO[1], p1 + fuori * FOSSATO[0]]
				for idx in [0, 1, 2, 0, 2, 3]:
					sf.set_normal(Vector3.UP)
					sf.add_vertex(Vector3(fq[idx].x, _quota(fq[idx]) + 0.06, fq[idx].y))
				# Palizzata sul ciglio esterno.
				var n_pali := maxi(1, int(p0.distance_to(p1) / PASSO_PALI))
				for i in n_pali:
					var pp := p0.lerp(p1, (float(i) + 0.5) / n_pali) + fuori * (CIMA - 0.25)
					var h_palo := 2.0 + caso.randf() * 0.4
					var y0 := _quota(pp) + ALTO - 0.5
					var base_t := Basis().scaled(Vector3(1.0, h_palo, 1.0))
					pali.append(Transform3D(base_t, Vector3(pp.x, y0 + h_palo * 0.5, pp.y)))
					punte.append(Transform3D(Basis(), Vector3(pp.x, y0 + h_palo + 0.2, pp.y)))
		lungo += tratto
	_terrapieno.mesh = st.commit()
	_fossato.mesh = sf.commit()
	_imposta(_pali.multimesh, pali)
	_imposta(_punte.multimesh, punte)
	# Le porte (solo nei tratti fatti: prima resta il varco).
	for p in sim.porte:
		var w: Vector2 = p["punto"]
		var v: Vector2 = p["verso"]
		var nodo := Asset.istanzia("res://asset/protourbano/recinto_porta.glb")
		if nodo == null:
			continue
		nodo.position = Vector3(w.x, _quota(w), w.y)
		nodo.rotation.y = atan2(-v.y, v.x)
		nodo.visible = finito or _distanza_lungo(w) < fatto_fino
		add_child(nodo)
		_porte.append(nodo)


func _in_porta(w: Vector2) -> bool:
	for p in sim.porte:
		if (p["punto"] as Vector2).distance_to(w) < LARGO_PORTA:
			return true
	return false


## Distanza lungo il recinto, dal primo punto, del punto della linea più vicino a `w`.
func _distanza_lungo(w: Vector2) -> float:
	var punti: Array = sim.recinto_punti
	var lungo := 0.0
	var meglio := INF
	var risultato := 0.0
	for k in punti.size():
		var a: Vector2 = punti[k]
		var b: Vector2 = punti[(k + 1) % punti.size()]
		var q := Geometry2D.get_closest_point_to_segment(w, a, b)
		if q.distance_to(w) < meglio:
			meglio = q.distance_to(w)
			risultato = lungo + a.distance_to(q)
		lungo += a.distance_to(b)
	return risultato


func _imposta(mm: MultiMesh, t: Array[Transform3D]) -> void:
	mm.instance_count = t.size()
	for i in t.size():
		mm.set_instance_transform(i, t[i])


## La bozza del recinto mentre si traccia: un nastro chiaro sui punti messi.
func mostra_bozza(punti: Array) -> void:
	if punti.size() < 2:
		_bozza.mesh = null
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in punti.size() - 1:
		var a: Vector2 = punti[k]
		var b: Vector2 = punti[k + 1]
		var d := (b - a).normalized()
		var lato := Vector2(-d.y, d.x) * 2.0
		var q := [a - lato, a + lato, b + lato, b - lato]
		for idx in [0, 1, 2, 0, 2, 3]:
			st.set_normal(Vector3.UP)
			st.add_vertex(Vector3(q[idx].x, _quota(q[idx]) + 0.6, q[idx].y))
	_bozza.mesh = st.commit()


## La zona dell'abitato: un quadrato chiaro per lotto, più chiaro dentro il recinto.
func sincronizza_zona() -> void:
	var chiave := "%d|%s" % [sim.zona_abitato.size(), _chiave]
	if chiave == _chiave_zona:
		return
	_chiave_zona = chiave
	var mm := _zona.multimesh
	mm.instance_count = sim.zona_abitato.size()
	var i := 0
	for l in sim.zona_abitato:
		var w := sim.centro_lotto(l)
		mm.set_instance_transform(i, Transform3D(Basis(), Vector3(w.x, _quota(w) + 0.35, w.y)))
		mm.set_instance_color(i, Color(1, 1, 1, 0.3 if sim.dentro_recinto(w, true) else 0.16))
		i += 1


func mostra_zona(si: bool) -> void:
	if si:
		sincronizza_zona()
	_zona.visible = si
