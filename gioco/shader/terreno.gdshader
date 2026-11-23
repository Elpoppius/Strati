shader_type spatial;
render_mode cull_back, diffuse_lambert, specular_schlick_ggx;

// Strati tematici: R fertilità, G rischio di piena, B acqua affidabile, A acqua stagionale.
uniform sampler2D tematici : filter_linear, repeat_disable;
// Distanza dal bordo dell'acqua: 0,5 = riva, ogni unità di 1/255 vale 2 m.
uniform sampler2D acque : filter_linear, repeat_disable;
// 0 terreno, 1 acqua, 2 fertilità, 3 rischio di piena.
uniform int modo = 0;
// Texture del suolo, ripetuta ogni lato_suolo metri; realismo 0 = colori da plastico, 1 = suolo verosimile.
uniform sampler2D suolo : source_color, filter_linear_mipmap, repeat_enable;
// Erba secca delle chiazze incolte e maschera a bassa frequenza che le distribuisce.
uniform sampler2D suolo_secco : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D macchie : filter_linear_mipmap, repeat_enable;
uniform float soglia_secco = 0.62;
// Rumori unici per tutta la mappa (coordinate UV del terreno): secchezza e variazione del verde.
uniform sampler2D rumore_secco : filter_linear, repeat_disable;
uniform sampler2D rumore_verde : filter_linear, repeat_disable;
// Boschi: copertura (0 o 1 per cella da 40 m) e due texture di foglie per la volta degli alberi.
uniform sampler2D coperture : filter_linear, repeat_disable;
uniform sampler2D chioma_a : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D chioma_b : source_color, filter_linear_mipmap, repeat_enable;
uniform float lato_suolo = 9.0;
uniform float realismo = 1.0;
uniform float esagerazione = 1.5;
uniform float passo_isoipse = 25.0;
uniform float alfa_isoipse = 0.35;
uniform float lato_lotto = 20.0;
uniform float alfa_griglia = 0.0;
uniform vec2 lotto_evidenziato = vec2(-1.0, -1.0);

varying vec3 pos_mondo;
varying vec3 normale_mondo;
varying float quota;

void vertex() {
	pos_mondo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	normale_mondo = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	quota = VERTEX.y / esagerazione;
}

void fragment() {
	// I colori dei vertici sono in sRGB: si convertono in lineare per l'illuminazione.
	vec3 base = pow(COLOR.rgb, vec3(2.2));
	// Suolo verosimile. La distribuzione di verde e secco viene da rumori unici per tutta la
	// mappa (nessuna ripetizione a nessuno zoom) e dai dati del luogo: più secco lontano
	// dall'acqua e sui terreni poco fertili. Le maschere piccole servono solo a frastagliare
	// i bordi da vicino e a spezzare la ripetizione della texture dell'erba.
	vec4 t = texture(tematici, UV);
	vec2 uv = pos_mondo.xz / lato_suolo;
	mat2 ruota = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));
	float m_vicina = texture(macchie, ruota * pos_mondo.xz / 71.0).r;
	float m_fine = texture(macchie, pos_mondo.xz / 13.0 + vec2(0.37, 0.11)).r;
	vec3 erba = mix(texture(suolo, uv).rgb, texture(suolo, ruota * uv * 0.83 + vec2(0.31, 0.57)).rgb, smoothstep(0.38, 0.62, m_vicina));
	vec3 secca = texture(suolo_secco, ruota * uv * 1.07).rgb;
	float lum = max(dot(base, vec3(0.333)), 1e-3);
	vec3 tinta = base / lum;
	// Dati del luogo ammorbiditi con quattro letture sfalsate: le celle da 40 m non fanno più scalini.
	vec2 px = 1.0 / vec2(textureSize(tematici, 0));
	vec4 tm = (texture(tematici, UV + px * vec2(0.8, 0.3)) + texture(tematici, UV + px * vec2(-0.3, 0.8))
			+ texture(tematici, UV + px * vec2(-0.8, -0.3)) + texture(tematici, UV + px * vec2(0.3, -0.8))) * 0.25;
	vec2 pr = 1.0 / vec2(textureSize(rumore_secco, 0));
	float n_secco = (texture(rumore_secco, UV + pr * vec2(0.8, 0.3)) + texture(rumore_secco, UV + pr * vec2(-0.3, 0.8))
			+ texture(rumore_secco, UV + pr * vec2(-0.8, -0.3)) + texture(rumore_secco, UV + pr * vec2(0.3, -0.8))).r * 0.25;
	float n_verde = texture(rumore_verde, UV).r;
	// Dove la zona è già gialla (colline asciutte) il secco si allarga; vicino all'acqua si ritira.
	float aridita = clamp((tinta.r - tinta.g) * 0.8, 0.0, 0.05);
	float umido = max(tm.b, tm.a * 0.6);
	float secchezza = n_secco * 0.8 + (1.0 - tm.r) * 0.18 + aridita - umido * 0.22;
	float frastaglio = (m_vicina - 0.5) * 0.18 + (m_fine - 0.5) * 0.06;
	// Tre stadi: erba verde, erba ingiallita, erba secca rossiccia.
	float ingiallito = smoothstep(soglia_secco - 0.22, soglia_secco - 0.02, secchezza + frastaglio * 0.5);
	float quanto_secco = smoothstep(soglia_secco - 0.04, soglia_secco + 0.05, secchezza + frastaglio);
	erba *= mix(vec3(1.0), vec3(1.16, 1.04, 0.7), ingiallito * 0.55);
	// Variazione di verde su scala di centinaia di metri: prati più grassi e più magri.
	erba *= mix(vec3(0.9, 0.97, 0.92), vec3(1.06, 1.03, 0.94), n_verde);
	// Variazione minuta di tono, visibile solo da vicino: ciuffi più chiari e più scuri.
	erba *= 0.93 + 0.14 * smoothstep(0.25, 0.75, m_fine * 0.6 + m_vicina * 0.4);
	vec3 verosimile = mix(erba, secca * vec3(0.96, 0.92, 0.9), quanto_secco) * (0.9 + 0.2 * n_verde);
	verosimile *= mix(vec3(1.0), tinta, 0.25) * 0.74;
	verosimile = mix(vec3(dot(verosimile, vec3(0.299, 0.587, 0.114))), verosimile, 0.8);
	// Pendii ripidi: l'erba si dirada e affiora la terra.
	float ripido = smoothstep(0.12, 0.3, 1.0 - normale_mondo.y) * smoothstep(0.35, 0.65, m_vicina + 0.25);
	vec3 terra = secca * vec3(0.78, 0.7, 0.62) * 0.62;
	verosimile = mix(verosimile, terra, ripido * 0.8);
	// Boschi: bordo irregolare (la copertura a celle viene mossa dalla maschera) e una volta
	// di chiome fatta da due strati di foglie, con macchie di luce e d'ombra grandi come alberi.
	float cop = texture(coperture, UV).r;
	float bosco = smoothstep(0.47, 0.53, cop + (m_vicina - 0.5) * 0.55 + (texture(macchie, pos_mondo.xz / 19.0).r - 0.5) * 0.3);
	if (bosco > 0.0) {
		// Coordinate deformate dalla maschera: rompono la griglia regolare delle ripetizioni.
		vec2 storta = pos_mondo.xz + vec2(texture(macchie, pos_mondo.xz / 31.0).r, texture(macchie, pos_mondo.xz / 29.0 + 0.5).r) * 9.0;
		vec4 fa = texture(chioma_a, storta / 6.1);
		vec4 fb = texture(chioma_b, ruota * storta / 4.7 + vec2(0.4, 0.2));
		vec4 fc = texture(chioma_a, ruota * ruota * storta / 5.3 + vec2(0.7, 0.9));
		vec3 volta = vec3(0.10, 0.13, 0.07);
		volta = mix(volta, fb.rgb * 0.75, step(0.5, fb.a));
		volta = mix(volta, fa.rgb, step(0.5, fa.a));
		volta = mix(volta, fc.rgb * 1.05, step(0.5, fc.a) * 0.8);
		// Chiome: macchie di circa 8 m, chiare in cima e scure negli interstizi.
		float chiome = texture(macchie, pos_mondo.xz / 9.0).r * 0.6 + texture(macchie, ruota * pos_mondo.xz / 23.0).r * 0.4;
		volta *= mix(0.3, 1.1, smoothstep(0.32, 0.68, chiome));
		// Al margine il bosco si dirada.
		volta *= mix(0.8, 1.0, smoothstep(0.0, 0.6, bosco));
		verosimile = mix(verosimile, volta * 0.6, bosco);
	}
	base = mix(base, verosimile, realismo * COLOR.a);
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
	// d_acqua è la distanza dalla riva in metri: negativa dentro l'acqua, positiva fuori.
	float d_acqua = (texture(acque, UV).r * 255.0 - 128.0) * 2.0;
	float bordo = max(fwidth(d_acqua), 0.5);
	float in_acqua = 1.0 - smoothstep(-bordo, bordo, d_acqua);
	// Riva: terra bagnata e scura per qualche metro, poi un velo più chiaro di sabbia e limo.
	float bagnato = (1.0 - smoothstep(0.0, 3.0 + bordo, d_acqua)) * (1.0 - in_acqua);
	float limo = (1.0 - smoothstep(2.0, 7.0 + bordo, d_acqua)) * (1.0 - in_acqua) * (1.0 - bagnato);
	col = mix(col, pow(vec3(0.46, 0.42, 0.32), vec3(2.2)), limo * 0.35);
	col = mix(col, col * vec3(0.5, 0.48, 0.44), bagnato * 0.85);
	// Increspature. Le coordinate sono deformate da un rumore più ampio e gli strati hanno scale
	// e orientamenti non multipli tra loro: così la piccola texture non forma un motivo regolare.
	vec2 pa = pos_mondo.xz;
	vec2 deforma = vec2(texture(macchie, pa / 23.0 + vec2(TIME * 0.003, 0.0)).r, texture(macchie, ruota * pa / 19.0 + vec2(0.3, TIME * 0.002)).r) - 0.5;
	vec2 pd = pa + deforma * 9.0;
	float o1 = texture(macchie, pd / 4.3 + vec2(TIME * 0.03, TIME * 0.017)).r;
	float o2 = texture(macchie, ruota * pd / 2.9 - vec2(TIME * 0.022, -TIME * 0.031)).r;
	float o4 = texture(macchie, ruota * ruota * pd / 6.7 + vec2(0.17, 0.61) + vec2(-TIME * 0.012, TIME * 0.02)).r;
	// Ondulazione lenta e larga, unica per tutta la mappa: alterna tratti più lisci e più mossi.
	float o3 = texture(rumore_verde, UV + vec2(TIME * 0.00002, 0.0)).r;
	float onde = ((o1 + o2 + o4) / 1.5 - 1.0) * (0.35 + o3);
	// Profondità: bassa e verdastra vicino alla riva, scura al centro dei fiumi.
	float prof = smoothstep(0.0, 14.0, -d_acqua + onde * 3.0);
	vec3 bassa = pow(vec3(0.48, 0.56, 0.44), vec3(2.2));
	vec3 fonda = pow(vec3(0.27, 0.46, 0.49), vec3(2.2));
	vec3 acqua = mix(bassa, fonda, prof);
	// Riflessi del cielo sulle creste delle increspature.
	float cresta = smoothstep(0.2, 0.55, onde);
	acqua = mix(acqua, pow(vec3(0.66, 0.78, 0.82), vec3(2.2)), cresta * 0.12);
	acqua *= 0.93 + 0.14 * smoothstep(-0.4, 0.4, onde) + 0.06 * (o3 - 0.5);
	// Schiuma sottile lungo la riva, spezzata dalle increspature.
	float schiuma = (1.0 - smoothstep(0.3, 1.6 + bordo, abs(d_acqua + 1.0 + deforma.x * 1.5))) * smoothstep(0.45, 0.6, o1 * 0.5 + o4 * 0.5);
	acqua = mix(acqua, pow(vec3(0.85, 0.86, 0.82), vec3(2.2)), schiuma * 0.45);
	col = mix(col, acqua, in_acqua);
	// Luce: l'acqua è liscia e riflette, il terreno no. Le increspature inclinano la normale.
	vec3 n_acqua = normalize(vec3((o1 - o4) * 0.25, 1.0, (o2 - 0.5) * 0.25));
	NORMAL = normalize(mix(NORMAL, (VIEW_MATRIX * vec4(n_acqua, 0.0)).xyz, in_acqua));
	SPECULAR = 0.5 * in_acqua;
	// Il cielo riflesso: un poco di luce propria, così l'acqua non diventa scura in ombra.
	EMISSION = pow(vec3(0.55, 0.68, 0.78), vec3(2.2)) * (0.12 + 0.12 * cresta) * in_acqua;
	ROUGHNESS = mix(1.0, 0.12, in_acqua);
	ALBEDO = col;
}
