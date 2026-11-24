shader_type spatial;
// Carte di foglie delle chiome (al posto del materiale importato da Blender, vedi Asset.prepara).
// Come il materiale di prima (texture per vertici colorati, ritaglio dell'alfa), più una cosa:
// una carta vista di taglio, cioè di profilo rispetto alla camera, svanisce invece di apparire
// come una linea o una scheggia storta (punto segnalato nel diario del 23/11, deciso da Fede il 24/11).
render_mode cull_back, depth_draw_opaque;

uniform sampler2D tessitura : source_color, filter_linear_mipmap, repeat_enable;
uniform float ruvidita = 0.8;
// Sotto questo valore di |coseno| tra la carta e lo sguardo la carta sparisce del tutto,
// sopra il secondo è piena.
uniform float taglio_inizio = 0.12;
uniform float taglio_fine = 0.35;

void fragment() {
	vec4 c = texture(tessitura, UV);
	ALBEDO = c.rgb * COLOR.rgb;
	// Normale vera della carta (le normali dei vertici sono sferiche, rivolte dal centro della
	// chioma, e non dicono come è girata la carta).
	vec3 n_carta = normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
	// Direzione dello sguardo: costante con la camera ortografica del gioco.
	vec3 sguardo = PROJECTION_MATRIX[3][3] > 0.5 ? vec3(0.0, 0.0, 1.0) : normalize(-VERTEX);
	float di_fronte = abs(dot(n_carta, sguardo));
	ALPHA = c.a * smoothstep(taglio_inizio, taglio_fine, di_fronte);
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ROUGHNESS = ruvidita;
}
