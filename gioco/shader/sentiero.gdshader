shader_type spatial;
// Sentiero: nastro di terra battuta largo 3,5 m posato sul terreno (VistaVillaggio). Bordi
// sfrangiati che sfumano nell'erba, due solchi più scuri lasciati dal passaggio, grana di terra.
render_mode blend_mix, cull_disabled, depth_draw_never, shadows_disabled;

uniform sampler2D macchie : filter_linear_mipmap, repeat_enable;
// 1 mentre lo strumento Sentiero è attivo: la rete si schiarisce per vedere a cosa agganciarsi.
uniform float evidenzia = 0.0;
// 1 per le strade (voce 5, 26/11/2026): più larghe, terra compatta più chiara e grigia, solchi
// più marcati delle ruote dei carri e il bordo d'erba consumata.
uniform float strada = 0.0;

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
	float solchi_carri = smoothstep(0.07, 0.0, abs(dal_centro - 0.5)) * 0.3 + smoothstep(0.12, 0.0, dal_centro) * 0.08;
	solchi = mix(solchi, solchi_carri, strada);
	vec3 terra = mix(vec3(0.34, 0.28, 0.20), vec3(0.46, 0.38, 0.27), m2);
	vec3 compatta = mix(vec3(0.37, 0.32, 0.25), vec3(0.47, 0.41, 0.32), m2);
	terra = mix(terra, compatta, strada);
	terra *= 1.0 - solchi;
	ALBEDO = mix(terra, vec3(0.92, 0.9, 0.84), evidenzia * 0.22);
	// Normale verso l'alto qualunque sia il verso dei triangoli (con le facce rovesciate il
	// nastro veniva illuminato da sotto e sembrava una riga scura).
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	ROUGHNESS = 1.0;
	ALPHA = bordo * 0.92;
}
