// Fumo dei camini (27/11/2026). Richiesta di Fede: il fumo animato che esce dalla fornace del fabbro.
// Decisioni di Fede: non è legato alla simulazione (c'è finché c'è l'edificio finito); per ora solo
// le officine e gli edifici comunitari, "altrimenti diventa una coltre di fumo".
//
// Ogni sbuffo è un quadrato rivolto alla camera; tutti gli sbuffi di tutti i camini stanno in una
// sola MultiMesh (VistaFumo). Uno sbuffo nasce alla bocca del camino, sale rallentando, si allarga,
// piega col vento e sfuma; il contorno è un rumore che scorre nel tempo, così le forme non si
// ripetono. Gli sbuffi di un camino hanno fasi sfalsate: la colonna è continua.
//
// Dati personalizzati della MultiMesh: x = fase (0–1), y = seme (0–1), z = densità (0–1), w = scala.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform float tempo = 0.0;          // secondi; lo fa avanzare VistaFumo (le foto lo fissano)
uniform float durata = 10.0;        // secondi di vita di uno sbuffo
uniform float altezza = 8.0;        // metri di salita, a fine vita
uniform vec3 vento = vec3(0.55, 0.0, 0.25); // metri al secondo, già con la direzione
uniform float raggio_bocca = 0.36;  // metri, alla nascita
uniform float raggio_fine = 2.6;    // metri, a fine vita
uniform vec3 colore_scuro : source_color = vec3(0.26, 0.245, 0.23);
uniform vec3 colore_chiaro : source_color = vec3(0.74, 0.73, 0.71);
uniform float opacita = 0.7;

varying float v_eta;
varying float v_seme;
varying float v_alfa;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float rumore(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int k = 0; k < 4; k++) {
		v += a * rumore(p);
		p = p * 2.03 + vec2(17.1, 9.2);
		a *= 0.5;
	}
	return v;
}

void vertex() {
	float fase = INSTANCE_CUSTOM.x;
	float seme = INSTANCE_CUSTOM.y;
	float t = fract(tempo / durata + fase);
	vec3 bocca = MODEL_MATRIX[3].xyz;
	// Sale in fretta all'uscita e poi rallenta; il vento lo porta via sempre di più.
	float sale = altezza * (1.0 - pow(1.0 - t, 1.7));
	vec3 deriva = vento * durata * t * t * 0.55;
	float ondeggia = 0.45 * t;
	vec3 mosso = vec3(sin(tempo * 0.6 + seme * 37.0 + t * 4.0), 0.0, cos(tempo * 0.5 + seme * 23.0 + t * 3.0)) * ondeggia;
	vec3 centro = bocca + vec3(0.0, sale, 0.0) + deriva + mosso;
	float r = mix(raggio_bocca, raggio_fine, pow(t, 0.6)) * INSTANCE_CUSTOM.w;
	// Lo sbuffo gira piano su sé stesso sul piano della camera.
	float ang = seme * 6.2832 + tempo * 0.12 * (seme - 0.5);
	vec2 q = mat2(vec2(cos(ang), sin(ang)), vec2(-sin(ang), cos(ang))) * VERTEX.xy;
	vec3 destra = INV_VIEW_MATRIX[0].xyz;
	vec3 su = INV_VIEW_MATRIX[1].xyz;
	vec3 mondo = centro + (q.x * destra + q.y * su) * r * 2.0;
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(mondo, 1.0);
	v_eta = t;
	v_seme = seme;
	// Compare in fretta, sfuma lentamente; più trasparente man mano che si allarga.
	v_alfa = smoothstep(0.0, 0.01, t) * pow(1.0 - t, 1.4) * INSTANCE_CUSTOM.z;
}

void fragment() {
	vec2 c = UV - 0.5;
	float d = length(c) * 2.0;
	vec2 p = UV * 2.2 + vec2(v_seme * 13.7, v_seme * 5.3) + vec2(0.0, -tempo * 0.07) + v_eta * 1.3;
	float n = fbm(p);
	// Contorno sfrangiato dal rumore; dentro, piccole chiazze più dense.
	float forma = smoothstep(0.92, 0.45, d + (n - 0.5) * 1.25);
	float dentro = 0.55 + 0.8 * fbm(p * 1.7 + 3.1);
	// Luce finta: più chiaro in alto e verso il sole, più scuro in basso; schiarisce salendo.
	float luce = 0.78 + 0.32 * (0.5 - c.y) + 0.12 * (0.5 - c.x);
	vec3 col = mix(colore_scuro, colore_chiaro, smoothstep(0.0, 0.55, v_eta)) * luce;
	ALBEDO = col;
	ALPHA = clamp(forma * dentro * v_alfa * opacita, 0.0, 1.0);
}
