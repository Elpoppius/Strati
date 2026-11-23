shader_type spatial;
render_mode cull_back, diffuse_lambert, specular_disabled;

// Strati tematici: R fertilità, G rischio di piena, B acqua affidabile, A acqua stagionale.
uniform sampler2D tematici : filter_linear, repeat_disable;
// Distanza dal bordo dell'acqua: 0,5 = riva, ogni unità di 1/255 vale 2 m.
uniform sampler2D acque : filter_linear, repeat_disable;
// 0 terreno, 1 acqua, 2 fertilità, 3 rischio di piena.
uniform int modo = 0;
uniform float esagerazione = 1.5;
uniform float passo_isoipse = 25.0;
uniform float alfa_isoipse = 0.35;
uniform float lato_lotto = 20.0;
uniform float alfa_griglia = 0.0;
uniform vec2 lotto_evidenziato = vec2(-1.0, -1.0);

varying vec3 pos_mondo;
varying float quota;

void vertex() {
	pos_mondo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	quota = VERTEX.y / esagerazione;
}

void fragment() {
	// I colori dei vertici sono in sRGB: si convertono in lineare per l'illuminazione.
	vec3 base = pow(COLOR.rgb, vec3(2.2));
	vec4 t = texture(tematici, UV);
	vec3 col = base;
	{
		if (modo == 1) {
			float a = t.b;
			float s = max(t.a - t.b, 0.0);
			col = mix(base, pow(vec3(0.16, 0.43, 0.67), vec3(2.2)), clamp(0.08 + 0.55 * a + 0.25 * s, 0.0, 0.85));
		} else if (modo == 2) {
			float f = t.r;
			col = mix(base, pow(mix(vec3(0.58, 0.45, 0.16), vec3(0.16, 0.55, 0.18), f), vec3(2.2)), 0.25 + 0.5 * f);
		} else if (modo == 3) {
			float r = t.g;
			col = r > 0.01 ? mix(base, pow(vec3(0.71, 0.24, 0.16), vec3(2.2)), 0.15 + 0.6 * r) : mix(base, vec3(1.0), 0.3);
		}
	}
	// Isoipse ogni passo_isoipse metri di quota.
	float q = quota / passo_isoipse;
	float w = max(fwidth(q), 1e-4);
	float linea = 1.0 - smoothstep(0.0, w * 1.2, abs(fract(q + 0.5) - 0.5));
	col = mix(col, pow(vec3(0.35, 0.27, 0.18), vec3(2.2)), linea * alfa_isoipse);
	// Griglia dei lotti, visibile solo da vicino.
	if (alfa_griglia > 0.0) {
		vec2 g = pos_mondo.xz / lato_lotto;
		vec2 fw = max(fwidth(g), vec2(1e-4));
		vec2 l = 1.0 - smoothstep(vec2(0.0), fw, abs(fract(g + 0.5) - 0.5));
		col = mix(col, pow(vec3(0.12, 0.16, 0.15), vec3(2.2)), max(l.x, l.y) * alfa_griglia);
	}
	// Lotto sotto il puntatore.
	if (lotto_evidenziato.x >= 0.0 && floor(pos_mondo.xz / lato_lotto) == lotto_evidenziato) {
		col = mix(col, pow(vec3(0.71, 0.26, 0.18), vec3(2.2)), 0.55);
	}
	// Acqua disegnata dal campo di distanza: bordi morbidi a qualunque zoom.
	float d_acqua = (texture(acque, UV).r * 255.0 - 128.0) * 2.0;
	float bordo = max(fwidth(d_acqua), 0.5);
	float in_acqua = 1.0 - smoothstep(-bordo, bordo, d_acqua);
	float riva = (1.0 - smoothstep(0.0, 6.0 + bordo, d_acqua)) * (1.0 - in_acqua);
	col = mix(col, pow(vec3(0.42, 0.38, 0.28), vec3(2.2)), riva * 0.35);
	col = mix(col, pow(vec3(0.30, 0.51, 0.64), vec3(2.2)), in_acqua);
	ALBEDO = col;
}
