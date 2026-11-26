// Animali del pascolo, il corpo (26/11/2026): grana del pelo o della lana moltiplicata per il
// manto, che sta nei colori dei vertici insieme all'occlusione cotta. Uniformi e animazioni in
// animali_comune.gdshaderinc.
shader_type spatial;
render_mode cull_back, diffuse_burley;

#include "res://shader/animali_comune.gdshaderinc"

void fragment() {
	ALBEDO = COLOR.rgb * texture(grana, UV).rgb / media_grana;
	ROUGHNESS = ruvidita;
	SPECULAR = 0.25;
}
