// Parte comune degli shader degli animali (26/11/2026): uniformi e animazioni. La usano
// animali.gdshader (il corpo) e animali_ciocche.gdshader (le carte di pelo con il ritaglio).
//
// Parti (seconda UV, scritte da strumenti/blender/animali.py): u = parte, v = peso lungo la parte.
//   0 corpo · 1 collo e testa · 2–5 zampe (ant. sx, ant. dx, post. sx, post. dx) · 6 orecchie · 7 coda.
// Stato di ogni animale (dati personalizzati della MultiMesh, VistaVillaggio._muovi_animali):
//   x = fase del passo (radianti, avanza con la strada fatta), y = andatura (0 fermo, 1 passo, fino
//   a 1,9 passo lungo), z = brucare (0 testa alta, 1 testa nell'erba), w = seme (0–1, tempi propri).
// Il muso guarda verso -z.

uniform sampler2D grana : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float media_grana = 0.5; // luminosità media (lineare) della grana: il manto resta quello dei vertici
uniform float ruvidita = 0.92;
uniform vec3 perno_collo = vec3(0.0, 0.66, -0.34);
uniform float lunghezza_collo = 0.4;
uniform float passo = 0.6; // metri per ciclo completo del passo
uniform float spalla = 0.52; // altezza della spalla (lunghezza delle zampe)
uniform float angolo_bruca = 1.0; // radianti: quanto si piega la testa per brucare (poco per il maiale)
uniform float abbassa_bruca = 0.0; // metri: quanto scende ancora il collo perché il muso tocchi l'erba
uniform vec4 posa = vec4(0.0); // per le foto di prova, si somma ai dati della MultiMesh

vec3 ruota_x(vec3 p, float a) {
	return vec3(p.x, p.y * cos(a) - p.z * sin(a), p.y * sin(a) + p.z * cos(a));
}

vec3 ruota_y(vec3 p, float a) {
	return vec3(p.x * cos(a) + p.z * sin(a), p.y, -p.x * sin(a) + p.z * cos(a));
}

void vertex() {
	vec4 c = INSTANCE_CUSTOM + posa;
	float fase = c.x;
	float anda = c.y;
	float bruca = clamp(c.z, 0.0, 1.0);
	float seme = c.w * 37.0;
	int parte = int(UV2.x + 0.5);
	float w = UV2.y;
	vec3 v = VERTEX;
	vec3 n = NORMAL;

	// Zampe a coppie diagonali (anteriore sinistra con posteriore destra): avanti e indietro, e
	// lo zoccolo si alza quando la zampa torna in avanti.
	float a_terra = 1.0;
	if (parte >= 2 && parte <= 5) {
		float off = (parte == 2 || parte == 5) ? 0.0 : PI;
		float s = sin(fase + off);
		v.z -= s * passo * 0.16 * anda * w; // 0,16 ≈ 1/(2π): lo zoccolo a terra arretra quanto avanza il corpo
		v.y += max(0.0, cos(fase + off)) * spalla * 0.14 * min(anda, 1.2) * w * w;
		a_terra = 1.0 - w;
	}
	// Il corpo sale e scende appena, due volte per passo (gli zoccoli restano a terra).
	v.y += cos(2.0 * fase) * spalla * 0.018 * min(anda, 1.4) * a_terra;

	// Orecchie: uno scatto ogni tanto. Coda: si muove piano, di più camminando.
	if (parte == 6) {
		float scatto = pow(max(0.0, sin(TIME * 1.3 + seme * 3.1)), 40.0);
		v.y += scatto * spalla * 0.08 * w;
	}
	if (parte == 7) {
		v.x += sin(TIME * 2.1 + seme) * spalla * (0.12 + 0.12 * min(anda, 1.0)) * w * w;
	}

	// Collo e testa: giù nell'erba per brucare (masticando), su e un poco ondeggiante camminando,
	// e da fermi con la testa alta ogni tanto si guardano attorno.
	if (parte == 1 || parte == 6) {
		float piega = min(1.0, w * 1.6);
		float giu = -bruca * angolo_bruca + sin(TIME * 5.0 + seme) * 0.035 * bruca;
		float cenno = sin(2.0 * fase) * 0.05 * min(anda, 1.0);
		float guarda = sin(TIME * 0.31 + seme) * 0.45 * (1.0 - bruca) * max(0.0, 1.0 - anda * 2.0);
		vec3 q = v - perno_collo;
		q = ruota_x(q, (giu + cenno) * piega);
		q = ruota_y(q, guarda * piega);
		v = perno_collo + q;
		// Il collo si allunga verso il basso fino all'erba (la testa scende intera).
		v.y -= bruca * abbassa_bruca * smoothstep(0.0, 0.7, w);
		n = ruota_y(ruota_x(n, (giu + cenno) * piega), guarda * piega);
	}
	VERTEX = v;
	NORMAL = n;
}

