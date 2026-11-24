shader_type spatial;
// Sentiero: nastro di terra battuta largo 3,5 m posato sul terreno (VistaVillaggio). Bordi
// sfrangiati che sfumano nell'erba, due solchi più scuri lasciati dal passaggio, grana di terra.
render_mode blend_mix, cull_disabled, depth_draw_never, shadows_disabled;

uniform sampler2D macchie : filter_linear_mipmap, repeat_enable;

varying vec3 pos_mondo;

void vertex() {
	pos_mondo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float m1 = texture(macchie, pos_mondo.xz / 5.0).r;
	float m2 = texture(macchie, pos_mondo.xz / 1.7 + vec2(0.3, 0.7)).r;
	// Distanza dal centro del nastro (0 al centro, 1 ai bordi), con un bordo irregolare.
	float dal_centro = abs(UV.x - 0.5) * 2.0;
	float bordo = 1.0 - smoothstep(0.55 + (m1 - 0.5) * 0.5, 1.0, dal_centro);
	float solchi = smoothstep(0.08, 0.0, abs(dal_centro - 0.45)) * 0.35;
	vec3 terra = mix(vec3(0.34, 0.28, 0.20), vec3(0.46, 0.38, 0.27), m2);
	terra *= 1.0 - solchi;
	ALBEDO = terra;
	// Normale verso l'alto qualunque sia il verso dei triangoli (con le facce rovesciate il
	// nastro veniva illuminato da sotto e sembrava una riga scura).
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	ROUGHNESS = 1.0;
	ALPHA = bordo * 0.92;
}
