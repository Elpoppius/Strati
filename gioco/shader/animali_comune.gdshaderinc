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
uniform vec3 perno_collo = vec3(0.0, 0.66, -0.34); // garrese: da qui si piega il collo
uniform vec3 giunto_testa = vec3(0.0, 0.84, -0.5); // nuca: da qui si piega la testa
uniform float peso_testa = 0.4; // peso (lungo collo e testa) della nuca
uniform float passo = 0.6; // metri per ciclo completo del passo
uniform float spalla = 0.52; // altezza della spalla (lunghezza delle zampe)
uniform float angolo_collo = 0.6; // radianti: quanto si piega il collo per brucare
uniform float angolo_testa = 0.8; // radianti: quanto si piega ancora la testa sulla nuca
uniform float abbassa_bruca = 0.0; // metri: quanto scende ancora il muso, se il collo non basta
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

	// Collo e testa: per brucare il collo si piega dal garrese e la testa dalla nuca, finché il muso
	// arriva all'erba con la testa quasi verticale (masticando); camminando la testa è alta e
	// ondeggia appena; da fermi con la testa alta ogni tanto si guardano attorno.
	if (parte == 1 || parte == 6) {
		float cenno = sin(2.0 * fase) * 0.05 * min(anda, 1.0);
		float a1 = -bruca * angolo_collo + cenno * 0.5;
		float a2 = -bruca * angolo_testa + sin(TIME * 5.0 + seme) * 0.05 * bruca + cenno * 0.5;
		float guarda = sin(TIME * 0.31 + seme) * 0.45 * (1.0 - bruca) * max(0.0, 1.0 - anda * 2.0);
		float pc = clamp(w / max(peso_testa, 0.02), 0.0, 1.0);
		float h = smoothstep(peso_testa - 0.06, peso_testa + 0.06, w);
		vec3 q = perno_collo + ruota_x(v - perno_collo, a1 * pc);
		vec3 j = perno_collo + ruota_x(giunto_testa - perno_collo, a1);
		q = mix(q, j + ruota_x(q - j, a2), h);
		q = perno_collo + ruota_y(q - perno_collo, guarda * min(1.0, w * 1.6));
		q.y -= bruca * abbassa_bruca * smoothstep(0.0, 0.7, w);
		v = q;
		n = ruota_y(ruota_x(n, a1 * pc + a2 * h), guarda * min(1.0, w * 1.6));
	}
	VERTEX = v;
	NORMAL = n;
}

