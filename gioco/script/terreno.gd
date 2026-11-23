class_name Terreno
extends MeshInstance3D
## Superficie del terreno costruita da una MappaDati: una maglia regolare con colori
## ipsometrici, più uno shader per mappe tematiche, isoipse e griglia dei lotti.

const SHADER := preload("res://shader/terreno.gdshader")

## Tinte ipsometriche: [quota in metri, colore].
const TINTE := [
	[15.0, Color8(199, 212, 182)], [35.0, Color8(206, 214, 178)], [60.0, Color8(216, 213, 170)],
	[100.0, Color8(214, 196, 150)], [200.0, Color8(196, 172, 128)], [350.0, Color8(174, 150, 112)],
	[500.0, Color8(156, 134, 102)],
]

var dati: MappaDati
var esagerazione := 1.5
var materiale: ShaderMaterial


func costruisci(d: MappaDati, esag: float = 1.5) -> void:
	dati = d
	esagerazione = esag
	var n := d.lato
	var passo := d.metri_per_px
	var vertici := PackedVector3Array()
	var normali := PackedVector3Array()
	var colori := PackedColorArray()
	var uv := PackedVector2Array()
	vertici.resize(n * n)
	normali.resize(n * n)
	colori.resize(n * n)
	uv.resize(n * n)
	for z in n:
		for x in n:
			var i := d.indice(x, z)
			vertici[i] = Vector3(x * passo, d.altezze[i] * esag, z * passo)
			uv[i] = Vector2((x + 0.5) / n, (z + 0.5) / n)
			colori[i] = _colore(i)
			var hl := d.altezze[d.indice(maxi(x - 1, 0), z)]
			var hr := d.altezze[d.indice(mini(x + 1, n - 1), z)]
			var hu := d.altezze[d.indice(x, maxi(z - 1, 0))]
			var hd := d.altezze[d.indice(x, mini(z + 1, n - 1))]
			normali[i] = Vector3((hl - hr) * esag, 2.0 * passo, (hu - hd) * esag).normalized()
	var indici := PackedInt32Array()
	indici.resize((n - 1) * (n - 1) * 6)
	var k := 0
	for z in n - 1:
		for x in n - 1:
			var a := z * n + x
			var b := a + 1
			var c := a + n
			var e := c + 1
			indici[k] = a; indici[k + 1] = b; indici[k + 2] = c
			indici[k + 3] = b; indici[k + 4] = e; indici[k + 5] = c
			k += 6
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertici
	arrays[Mesh.ARRAY_NORMAL] = normali
	arrays[Mesh.ARRAY_COLOR] = colori
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_INDEX] = indici
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh = m
	materiale = ShaderMaterial.new()
	materiale.shader = SHADER
	materiale.set_shader_parameter("tematici", _texture_tematica())
	var img_acque := Image.create_from_data(d.lato_acqua, d.lato_acqua, false, Image.FORMAT_L8, d.distanza_acqua)
	# In virgola mobile (16 bit): interpolata in 8 bit, la distanza dalla riva faceva fasce a gradini.
	img_acque.convert(Image.FORMAT_RH)
	materiale.set_shader_parameter("acque", ImageTexture.create_from_image(img_acque))
	materiale.set_shader_parameter("esagerazione", esag)
	materiale.set_shader_parameter("suolo", load("res://asset/texture/erba.png"))
	materiale.set_shader_parameter("suolo_secco", load("res://asset/texture/erba_secca.png"))
	materiale.set_shader_parameter("macchie", load("res://asset/texture/macchie.png"))
	materiale.set_shader_parameter("rumore_secco", _rumore_mappa(1847, 1.0 / 90.0))
	materiale.set_shader_parameter("rumore_verde", _rumore_mappa(1848, 1.0 / 60.0))
	materiale.set_shader_parameter("rumore_bosco", _rumore_mappa(1849, 1.0 / 6.0))
	materiale.set_shader_parameter("rumore_palude", _rumore_mappa(1850, 1.0 / 3.0))
	var img_coperture := Image.create_from_data(d.lato, d.lato, false, Image.FORMAT_L8, d.copertura)
	materiale.set_shader_parameter("coperture", ImageTexture.create_from_image(img_coperture))
	materiale.set_shader_parameter("zone_speciali", _texture_zone_speciali())
	materiale.set_shader_parameter("chioma_a", load("res://asset/texture/foglie_quercia.png"))
	materiale.set_shader_parameter("chioma_b", load("res://asset/texture/foglie_carpino.png"))
	material_override = materiale


func _colore(i: int) -> Color:
	var t := dati.tipo[i]
	# Il canale alfa dice allo shader quanto usare la texture d'erba (1) o il colore della zona (0).
	# Paludi e gessi non stanno più nei colori dei vertici (facevano quadretti da 40 m):
	# li disegna lo shader dalla texture delle zone speciali, con bordi irregolari.
	var q := dati.altezze[i]
	var c: Color = TINTE[-1][1]
	for j in TINTE.size() - 1:
		if q <= TINTE[j + 1][0]:
			var f := clampf((q - TINTE[j][0]) / (TINTE[j + 1][0] - TINTE[j][0]), 0.0, 1.0)
			c = TINTE[j][1].lerp(TINTE[j + 1][1], f)
			break
	# Sotto fiumi e torrenti resta la tinta del terreno: l'acqua la disegna lo shader.
	var peso := 1.0 if dati.zona[i] != 3 else 0.65
	# I boschi non stanno più nei colori dei vertici (davano bordi a gradini da 40 m):
	# li disegna lo shader dalla texture delle coperture, con bordi irregolari.
	return Color(c, peso)


## Rumore frattale unico per tutta la mappa (1024 x 1024, circa 10 m per pixel):
## distribuisce verde e secco senza ripetizioni. La frequenza è in cicli per pixel.
func _rumore_mappa(seme: int, frequenza: float) -> ImageTexture:
	var r := FastNoiseLite.new()
	r.seed = seme
	r.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	r.fractal_type = FastNoiseLite.FRACTAL_FBM
	r.fractal_octaves = 6
	r.frequency = frequenza
	return ImageTexture.create_from_image(r.get_image(1024, 1024, false, false, true))


## Zone speciali per lo shader: rosso = palude, verde = gessi (255 dentro, 0 fuori).
func _texture_zone_speciali() -> ImageTexture:
	var n := dati.lato
	var byte := PackedByteArray()
	byte.resize(n * n * 2)
	for i in n * n:
		byte[i * 2] = 255 if dati.tipo[i] == MappaDati.PALUDE else 0
		byte[i * 2 + 1] = 255 if dati.tipo[i] == MappaDati.GESSI else 0
	return ImageTexture.create_from_image(Image.create_from_data(n, n, false, Image.FORMAT_RG8, byte))


func _texture_tematica() -> ImageTexture:
	var n := dati.lato
	var byte := PackedByteArray()
	byte.resize(n * n * 4)
	for i in n * n:
		byte[i * 4] = dati.fertilita[i]
		byte[i * 4 + 1] = dati.piena[i]
		byte[i * 4 + 2] = dati.acqua[i]
		byte[i * 4 + 3] = dati.acqua_stagionale[i]
	var img := Image.create_from_data(n, n, false, Image.FORMAT_RGBA8, byte)
	return ImageTexture.create_from_image(img)


## Quota nel mondo 3D (con esagerazione verticale).
func quota_mondo(x: float, z: float) -> float:
	return dati.quota(x, z) * esagerazione


## Punto in cui un raggio colpisce il terreno, oppure null.
func interseca_raggio(origine: Vector3, direzione: Vector3) -> Variant:
	if absf(direzione.y) < 1e-5:
		return null
	var y_alto := dati.quota_max * esagerazione + 5.0
	var y_basso := dati.quota_min * esagerazione - 5.0
	var t0 := (y_alto - origine.y) / direzione.y
	var t1 := (y_basso - origine.y) / direzione.y
	if t1 < 0.0:
		return null
	t0 = maxf(t0, 0.0)
	var passo := dati.metri_per_px * 0.25
	var t := t0
	var precedente := t0
	while t <= t1:
		var p := origine + direzione * t
		if p.y <= quota_mondo(p.x, p.z):
			var a := precedente
			var b := t
			for _r in 12:
				var m := (a + b) * 0.5
				var q := origine + direzione * m
				if q.y <= quota_mondo(q.x, q.z):
					b = m
				else:
					a = m
			var punto := origine + direzione * b
			if punto.x < 0.0 or punto.z < 0.0 or punto.x > dati.lato_metri() or punto.z > dati.lato_metri():
				return null
			return punto
		precedente = t
		t += passo
	return null
