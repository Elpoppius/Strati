// Popolazione visibile (26/11/2026, voce 7 del todo): corpi e attrezzi delle persone del villaggio
// (strumenti/blender/persone.py). Colori e animazioni stanno qui.
//
// Seconda UV (UV2): u = parte + classe / 10, v = peso lungo la parte (la v arriva capovolta
// dall'esportazione glTF: si raddrizza con 1 − v, come per gli animali).
//   Parti: 0 busto e veste · 1 collo e testa · 2 braccio sinistro · 3 braccio destro ·
//   4 gamba sinistra · 5 gamba destra · 6 attrezzo (nella mano destra).
//   Classi: 0 pelle · 1 capelli · 2 veste · 3 mantello o pelle · 4 calzari · 5 cintura ·
//   6 legno · 7 selce · 8 vimini.
// I colori dei vertici portano solo l'occlusione cotta. La persona guarda verso -z.
//
// Stato di ogni persona (dati personalizzati della MultiMesh, VistaVillaggio._muovi_persone):
//   x = fase (radianti: il passo segue la strada fatta),
//   y = modo + andatura / 2 (modo 0 fermo, 1 cammina, 2 lavora, 3 parla; andatura 0–1,9),
//   z = lavoro + (attrezzo + 1) / 10 (lavoro 0 zappare, 1 tagliare, 2 lancia, 3 raccogliere,
//       4 costruire, 5 bastone del pastore; attrezzo −1 nessuno, 0 zappa, 1 ascia, 2 lancia,
//       3 bastone, 4 cesto),
//   w = seme (0–1: colori e tempi propri).
shader_type spatial;
render_mode cull_back, diffuse_burley;

uniform sampler2D grana_veste : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grana_capelli : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float media_veste = 0.471; // luminosità media (lineare) delle grane: il colore resta quello scelto
uniform float media_capelli = 0.357;
uniform float anca = 0.9;
uniform float x_anca = 0.095;
uniform float ginocchio = 0.48;
uniform vec3 spalla = vec3(0.185, 1.41, 0.0); // destra (la sinistra è a specchio)
uniform vec3 gomito = vec3(0.215, 1.12, 0.015);
uniform float collo = 1.47;
uniform float peso_gomito = 0.45;
uniform float peso_ginocchio = 0.47;
// Radianti di spalla e gomito per tenere ciascun attrezzo (come TENERE in persone.py).
const float TENERE[5] = float[](1.2, 1.2, 1.2, 0.5, 0.15);
uniform float variante = 0.0; // per modello: i colori di due modelli diversi non coincidono
uniform vec4 posa = vec4(0.0); // per le foto di prova, si somma ai dati della MultiMesh

// Colore e grana per vertice, sfumati tra un vertice e l'altro: con un colore per triangolo i
// confini tra pelle, veste e capelli venivano a zig-zag sui triangoli grandi del livello semplificato.
varying vec3 v_colore;
varying vec3 v_grane; // quanto pesano la grana della lana (x), del pelo (y), del legno e del vimini (z)
varying float v_pelle;

// Colori lineari (proposta di Claude, da guardare con Fede): tinte naturali del Neolitico.
const vec3 PELLE[4] = vec3[](vec3(0.40, 0.24, 0.16), vec3(0.33, 0.19, 0.12), vec3(0.27, 0.15, 0.09), vec3(0.46, 0.29, 0.20));
const vec3 CAPELLI[5] = vec3[](vec3(0.018, 0.014, 0.012), vec3(0.045, 0.028, 0.018), vec3(0.09, 0.055, 0.032), vec3(0.15, 0.065, 0.03), vec3(0.30, 0.28, 0.25));
const vec3 VESTI[7] = vec3[](vec3(0.38, 0.33, 0.26), vec3(0.47, 0.43, 0.35), vec3(0.17, 0.11, 0.065), vec3(0.33, 0.21, 0.09),
	vec3(0.16, 0.17, 0.10), vec3(0.24, 0.11, 0.07), vec3(0.23, 0.22, 0.20));
const vec3 MANTELLI[4] = vec3[](vec3(0.22, 0.13, 0.07), vec3(0.12, 0.08, 0.05), vec3(0.10, 0.09, 0.08), vec3(0.30, 0.24, 0.17));

float caso(float s, float k) {
	return fract(sin(s * 12.9898 + k * 78.233) * 43758.5453);
}

vec3 ruota_x(vec3 p, float a) {
	return vec3(p.x, p.y * cos(a) - p.z * sin(a), p.y * sin(a) + p.z * cos(a));
}

vec3 ruota_y(vec3 p, float a) {
	return vec3(p.x * cos(a) + p.z * sin(a), p.y, -p.x * sin(a) + p.z * cos(a));
}

// Gira p attorno al perno c (asse x: un arto che pende va avanti con un angolo positivo).
vec3 giro(vec3 p, vec3 c, float a) {
	return c + ruota_x(p - c, a);
}

void vertex() {
	vec4 c = INSTANCE_CUSTOM + posa;
	float fase = c.x;
	int modo = int(floor(c.y + 0.001));
	float anda = clamp(fract(c.y + 0.001) * 2.0, 0.0, 1.9);
	int lavoro = int(floor(c.z + 0.001));
	int quale = int(floor(fract(c.z + 0.001) * 10.0 + 0.5)) - 1;
	bool attrezzo = quale >= 0;
	float tenere = attrezzo ? TENERE[min(quale, 4)] : 0.0;
	float seme = c.w;
	float t = TIME + seme * 37.0;
	int parte = int(floor(UV2.x + 0.001));
	int classe = int(floor(fract(UV2.x + 0.001) * 10.0));
	float w = 1.0 - UV2.y;

	// Colori di questa persona.
	float s2 = seme + variante;
	float hc = caso(s2, 2.0);
	vec3 tinte[9] = vec3[](PELLE[int(caso(s2, 1.0) * 4.0) % 4], CAPELLI[hc > 0.92 ? 4 : int(hc / 0.92 * 4.0) % 4],
		VESTI[int(caso(s2, 3.0) * 7.0) % 7], MANTELLI[int(caso(s2, 4.0) * 4.0) % 4],
		vec3(0.085, 0.055, 0.035), vec3(0.07, 0.045, 0.028), vec3(0.20, 0.13, 0.07), vec3(0.16, 0.15, 0.14), vec3(0.36, 0.28, 0.15));
	v_colore = tinte[clamp(classe, 0, 8)];
	v_grane = vec3(classe == 2 ? 1.0 : 0.0, (classe == 1 || classe == 3) ? 1.0 : 0.0, (classe == 6 || classe == 8) ? 1.0 : 0.0);
	v_pelle = classe == 0 ? 1.0 : 0.0;

	// Angoli degli arti. sp: spalla (avanti positivo), go: gomito in più; an: anca, gi: ginocchio
	// (negativo = indietro); busto: piegato in avanti.
	float sp_s = 0.03 * sin(t * 0.7), sp_d = 0.03 * sin(t * 0.7 + 1.3);
	float go_s = 0.12, go_d = 0.12;
	float an_s = 0.0, an_d = 0.0, gi_s = 0.0, gi_d = 0.0;
	float busto = 0.0, gira = 0.0, annuisci = 0.0, su_giu = 0.0;
	// Tenere l'attrezzo: la spalla porta un terzo del giro, il gomito il resto.
	float tieni_s = tenere * 0.3, tieni_g = tenere * 0.7;

	if (modo == 1) {
		float s = sin(fase);
		an_s = 0.34 * s * anda;
		an_d = -an_s;
		gi_s = -max(0.0, cos(fase)) * 0.6 * min(anda, 1.2);
		gi_d = -max(0.0, -cos(fase)) * 0.6 * min(anda, 1.2);
		sp_s = -0.26 * s * anda;
		sp_d = 0.26 * s * anda;
		go_s = 0.18 + 0.12 * max(0.0, -s) * anda;
		go_d = 0.18 + 0.12 * max(0.0, s) * anda;
		su_giu = cos(2.0 * fase) * 0.014 * min(anda, 1.4);
		busto = 0.04 * anda;
	} else if (modo == 0) {
		gira = sin(t * 0.23) * 0.45 * smoothstep(0.2, 0.8, sin(t * 0.11) * 0.5 + 0.5);
	} else if (modo == 3) {
		annuisci = 0.07 * sin(t * 2.3) * smoothstep(0.0, 0.5, sin(t * 0.37));
		gira = sin(t * 0.3) * 0.25;
		float gesto = smoothstep(0.35, 1.0, sin(t * 0.9));
		sp_d = 0.15 + 0.55 * gesto;
		go_d = 0.25 + 0.75 * gesto;
		float gesto2 = smoothstep(0.6, 1.0, sin(t * 0.63 + 2.0));
		sp_s = 0.05 + 0.4 * gesto2;
		go_s = 0.2 + 0.6 * gesto2;
	}
	if (attrezzo && modo != 2) {
		sp_d = tieni_s + (modo == 1 ? 0.05 * sin(fase) * anda : 0.0);
		go_d = tieni_g;
	}
	if (modo == 2) {
		float k = pow(0.5 + 0.5 * sin(t * 1.7), 1.6);
		if (lavoro == 0) { // zappare
			busto = 0.32 + 0.1 * (1.0 - k);
			sp_s = mix(0.45, 1.95, k); go_s = mix(0.15, 0.5, k);
			sp_d = sp_s; go_d = go_s;
			gi_s = -0.12; gi_d = -0.12; an_s = 0.1; an_d = -0.05;
		} else if (lavoro == 1) { // tagliare con l'ascia
			k = pow(0.5 + 0.5 * sin(t * 2.1), 1.8);
			busto = 0.14;
			sp_d = mix(0.55, 2.5, k); go_d = mix(0.25, 0.6, k);
			sp_s = mix(0.45, 1.9, k); go_s = mix(0.3, 0.5, k);
			an_s = 0.18; an_d = -0.1;
		} else if (lavoro == 2) { // lancia: in attesa, ogni tanto un colpo
			float ph = fract(t * 0.21);
			float colpo = smoothstep(0.0, 0.06, ph) * (1.0 - smoothstep(0.12, 0.3, ph));
			sp_d = tieni_s + 0.25 * colpo;
			go_d = tieni_g * (1.0 - colpo);
			sp_s = 0.35 + 0.2 * colpo; go_s = 0.4;
			busto = 0.08 + 0.25 * colpo;
			annuisci = -0.15;
			an_s = 0.15; an_d = -0.08;
		} else if (lavoro == 3) { // raccogliere, chini
			busto = 0.75 + 0.08 * sin(t * 0.8);
			sp_s = 0.45 + 0.25 * sin(t * 1.5); go_s = 0.3;
			sp_d = 0.45 + 0.25 * sin(t * 1.5 + 1.7); go_d = 0.3;
			gi_s = -0.25; gi_d = -0.25; an_s = 0.15; an_d = 0.15;
		} else if (lavoro == 4) { // costruire: si lega, si batte
			k = pow(0.5 + 0.5 * sin(t * 3.2), 2.0);
			busto = 0.22;
			sp_d = mix(0.8, 1.6, k); go_d = mix(0.9, 0.4, k);
			sp_s = 0.75; go_s = 0.6;
		} else { // il pastore appoggiato al bastone
			sp_d = tieni_s; go_d = tieni_g;
			gira = sin(t * 0.2) * 0.4;
		}
	}

	vec3 v = VERTEX;
	vec3 n = NORMAL;
	// Gambe: dall'anca, poi il ginocchio.
	if (parte == 4 || parte == 5) {
		float lato = parte == 4 ? -1.0 : 1.0;
		float a = parte == 4 ? an_s : an_d;
		float b = parte == 4 ? gi_s : gi_d;
		vec3 h = vec3(x_anca * lato, anca, 0.0);
		vec3 kn = giro(vec3(x_anca * lato, ginocchio, -0.01), h, a);
		v = giro(v, h, a);
		n = ruota_x(n, a);
		float sotto = smoothstep(peso_ginocchio - 0.04, peso_ginocchio + 0.04, w);
		v = mix(v, giro(v, kn, b), sotto);
		n = ruota_x(n, b * sotto);
	}
	// La veste sotto la cintura (e il mantello lungo) seguono le gambe.
	if (parte == 0 && v.y < anca) {
		float m = clamp(v.x / (x_anca * 1.6), -1.0, 1.0);
		float a = mix(an_s, an_d, 0.5 + 0.5 * m) * 0.6 * smoothstep(0.0, 0.3, anca - v.y);
		v = giro(v, vec3(0.0, anca, 0.0), a);
	}
	// Spalle: il busto attorno all'attaccatura segue un po' il braccio, così alzandolo non si tende
	// una membrana tra l'ascella e il fianco.
	if (parte == 0 && abs(v.x) > 0.06) {
		float lato = v.x < 0.0 ? -1.0 : 1.0;
		vec3 s = vec3(spalla.x * lato, spalla.y, spalla.z);
		float f = (1.0 - smoothstep(0.05, 0.17, distance(v, s))) * smoothstep(0.06, 0.15, abs(v.x));
		float a = (lato < 0.0 ? sp_s : sp_d) * 0.55 * f;
		v = giro(v, s, a);
		n = ruota_x(n, a);
	}
	// Braccia (e l'attrezzo nella mano destra): dalla spalla, poi il gomito.
	if (parte == 2 || parte == 3 || parte == 6) {
		float lato = parte == 2 ? -1.0 : 1.0;
		float a = parte == 2 ? sp_s : sp_d;
		float b = parte == 2 ? go_s : go_d;
		vec3 s = vec3(spalla.x * lato, spalla.y, spalla.z);
		vec3 e = giro(vec3(gomito.x * lato, gomito.y, gomito.z), s, a);
		float oltre = parte == 6 ? 1.0 : smoothstep(peso_gomito - 0.05, peso_gomito + 0.05, w);
		v = giro(v, s, a);
		v = mix(v, giro(v, e, b), oltre);
		n = ruota_x(n, a + b * oltre);
	}
	// Testa: si gira e annuisce dal collo.
	if (parte == 1) {
		float h = smoothstep(collo - 0.05, collo + 0.06, v.y);
		vec3 cn = vec3(0.0, collo, 0.0);
		v = cn + ruota_y(v - cn, gira * h);
		v = mix(v, giro(v, cn, -annuisci), h);
		n = ruota_y(n, gira * h);
	}
	// Il busto si piega in avanti dall'anca (tutto ciò che sta sopra, braccia e attrezzo compresi).
	if (parte != 4 && parte != 5) {
		float sopra = parte == 0 ? smoothstep(anca - 0.06, anca + 0.12, VERTEX.y) : 1.0;
		vec3 ca = vec3(0.0, anca, 0.0);
		v = mix(v, giro(v, ca, -busto), sopra);
		n = ruota_x(n, -busto * sopra);
	}
	v.y += su_giu;
	VERTEX = v;
	NORMAL = n;
}

void fragment() {
	float lana = texture(grana_veste, UV).r / media_veste;
	float pelo = texture(grana_capelli, UV * 2.0).r / media_capelli;
	float legno = texture(grana_veste, UV * 3.5).r / media_veste;
	float grana = 1.0 + v_grane.x * (lana - 1.0) + v_grane.y * (pelo - 1.0) + v_grane.z * (legno - 1.0);
	ALBEDO = v_colore * COLOR.r * mix(1.0, grana, 0.6);
	ROUGHNESS = mix(0.92, 0.7, v_pelle);
	SPECULAR = mix(0.2, 0.35, v_pelle);
}
