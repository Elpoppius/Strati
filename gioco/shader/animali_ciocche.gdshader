// Animali del pascolo, le carte di pelo (26/11/2026, sui riferimenti di Fede): come le foglie
// degli alberi, ciocche con il ritaglio che seguono il verso del pelo e rompono la sagoma. Hanno le
// normali del corpo e si muovono con la loro parte (animali_comune.gdshaderinc).
shader_type spatial;
render_mode cull_disabled, diffuse_burley;

#include "res://shader/animali_comune.gdshaderinc"

uniform sampler2D ciocche : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform float media_ciocche = 0.47;

void fragment() {
	// Le carte hanno le normali del corpo: viste dal retro Godot le capovolgerebbe e la ciocca
	// diventerebbe nera; si tengono rivolte verso l'esterno come la pelle sotto.
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
	vec4 t = texture(ciocche, UV);
	ALBEDO = COLOR.rgb * t.rgb / media_ciocche;
	ALPHA = t.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ROUGHNESS = ruvidita;
	SPECULAR = 0.2;
}
