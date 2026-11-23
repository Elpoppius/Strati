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
// Gruppi di alberi visti da lontano: rumore unico per la mappa (nessun motivo ripetuto), macchie di decine di metri.
uniform sampler2D rumore_bosco : filter_linear, repeat_disable;
// Pozze e canneti delle paludi: rumore unico per la mappa più fine (circa 30 m), al posto di una texture ripetuta.
uniform sampler2D rumore_palude : filter_linear, repeat_disable;
// Boschi: campo a 10 m generato con la mappa (0,5 = margine) e due texture di foglie per la volta.
// È lo stesso campo da cui Alberi posa gli alberi veri: bordo dipinto e alberi coincidono.
uniform sampler2D bosco_fine : filter_linear, repeat_disable;
// Paludi a 10 m generate con la mappa: palude_fine (0,5 = margine) e pozze_fine (sopra 0,5 c'è
// acqua ferma). Gli stessi campi guidano la posa dei canneti (Alberi), che così stanno attorno
// alle pozze e non dentro.
uniform sampler2D palude_fine : filter_linear, repeat_disable;
uniform sampler2D pozze_fine : filter_linear, repeat_disable;
// 1 quando gli alberi veri sono visibili (vista vicina): sotto il bosco si dipinge il sottobosco.
uniform float sottobosco = 0.0;
// Zone speciali a celle da 40 m: R palude, G gessi. Lo shader ne ammorbidisce e frastaglia i bordi.
uniform sampler2D zone_speciali : filter_linear, repeat_disable;
uniform sampler2D chioma_a : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D chioma_b : source_color, filter_linear_mipmap, repeat_enable;
uniform float lato_suolo = 9.0;
uniform float realismo = 1.0;
uniform float esagerazione = 1.5;
uniform float passo_isoipse = 25.0;
// Isoipse spente di serie (scelta di Fede): si accendono con il tasto I.
uniform float alfa_isoipse = 0.0;
// Rilievo: direzione verso il sole (aggiornata da principale.gd) e quanto accentuare luci e ombre dei pendii.
uniform vec3 verso_sole = vec3(-0.53, 0.67, 0.53);
uniform float forza_rilievo = 0.6;
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
	// Metri coperti da un pixel: da lontano i dettagli minuti si attenuano invece di sfarfallare
	// in puntini (resa "puntinata" segnalata da Fede).
	float mpx = length(fwidth(pos_mondo.xz)) * 0.7;
	float lontano = smoothstep(1.0, 4.0, mpx);
	// Acqua: distanza dalla riva in metri (negativa dentro l'acqua) e verso in cui cresce,
	// cioè dall'acqua verso terra. Serve a disegnare le sponde in rilievo.
	float d_acqua = (texture(acque, UV).r * 255.0 - 128.0) * 2.0;
	vec2 pa_ = 1.5 / vec2(textureSize(acque, 0));
	float dx_a = (texture(acque, UV + vec2(pa_.x, 0.0)).r - texture(acque, UV - vec2(pa_.x, 0.0)).r);
	float dz_a = (texture(acque, UV + vec2(0.0, pa_.y)).r - texture(acque, UV - vec2(0.0, pa_.y)).r);
	vec2 verso_riva = length(vec2(dx_a, dz_a)) > 1e-6 ? normalize(vec2(dx_a, dz_a)) : vec2(0.0);
	// Sponda: il terreno scende verso l'acqua negli ultimi metri, così la luce la modella.
	float pendenza_sponda = 0.75 * exp(-pow(d_acqua - 2.0, 2.0) / 40.0);
	vec3 n_terra = normalize(normale_mondo + vec3(-verso_riva.x, 0.0, -verso_riva.y) * pendenza_sponda);
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
	vec4 t = (texture(tematici, UV + px * vec2(0.8, 0.3)) + texture(tematici, UV + px * vec2(-0.3, 0.8))
			+ texture(tematici, UV + px * vec2(-0.8, -0.3)) + texture(tematici, UV + px * vec2(0.3, -0.8))) * 0.25;
	vec2 pr = 1.0 / vec2(textureSize(rumore_secco, 0));
	float n_secco = (texture(rumore_secco, UV + pr * vec2(0.8, 0.3)) + texture(rumore_secco, UV + pr * vec2(-0.3, 0.8))
			+ texture(rumore_secco, UV + pr * vec2(-0.8, -0.3)) + texture(rumore_secco, UV + pr * vec2(0.3, -0.8))).r * 0.25;
	float n_verde = texture(rumore_verde, UV).r;
	// Dove la zona è già gialla (colline asciutte) il secco si allarga; vicino all'acqua si ritira.
	float aridita = clamp((tinta.r - tinta.g) * 0.8, 0.0, 0.05);
	float umido = max(t.b, t.a * 0.6);
	float secchezza = n_secco * 0.8 + (1.0 - t.r) * 0.18 + aridita - umido * 0.22;
	// Bordi delle chiazze secche spezzati a più scale (30 m senza ripetizioni, 13 e 5 m): niente
	// macchie morbide "a pennellata" (parere di Fede), ma chiazze frastagliate come in un prato vero.
	float n_30 = texture(rumore_palude, UV.yx + vec2(0.13, 0.07)).r;
	float m_5 = texture(macchie, ruota * pos_mondo.xz / 5.3 + vec2(0.71, 0.29)).r;
	float frastaglio = (m_vicina - 0.5) * 0.1 + (n_30 - 0.5) * 0.22 + (m_fine - 0.5) * 0.1 + (m_5 - 0.5) * 0.08 * (1.0 - lontano);
	// Tre stadi: erba verde, erba ingiallita, erba secca rossiccia.
	float ingiallito = smoothstep(soglia_secco - 0.22, soglia_secco - 0.02, secchezza + frastaglio * 0.5);
	float quanto_secco = smoothstep(soglia_secco - 0.04, soglia_secco + 0.05, secchezza + frastaglio);
	erba *= mix(vec3(1.0), vec3(1.16, 1.04, 0.7), ingiallito * 0.55);
	// Variazione di verde su scala di centinaia di metri, tenue: prati più grassi e più magri.
	erba *= mix(vec3(0.94, 0.98, 0.95), vec3(1.04, 1.02, 0.96), n_verde);
	// Variazione di tono a più scale, più forte da vicino: ciuffi scuri e verdi (trifoglio,
	// erba alta) e chiari e giallastri (erba bassa, fiori secchi), da 3 a 30 m.
	float m_3 = texture(macchie, ruota * ruota * pos_mondo.xz / 3.1 + vec2(0.17, 0.83)).r;
	float ciuffi = (m_3 - 0.5) * 0.6 * (1.0 - lontano) + (m_5 - 0.5) * 0.5 * (1.0 - lontano * 0.6) + (m_fine - 0.5) * 0.4 + (n_30 - 0.5) * 0.5;
	erba *= mix(vec3(0.82, 0.9, 0.8), vec3(1.12, 1.08, 0.94), smoothstep(-0.35, 0.35, ciuffi));
	// Erba secca color paglia (meno rossa), con ciuffi verdi che restano dentro la chiazza.
	vec3 paglia = mix(secca, vec3(dot(secca, vec3(0.333))) * vec3(1.12, 1.0, 0.72), 0.45) * (0.86 + 0.28 * m_5);
	float secco_vero = quanto_secco * mix(0.45, 1.0, smoothstep(0.3, 0.7, m_3 * 0.4 + m_5 * 0.3 + n_30 * 0.3 + quanto_secco * 0.3));
	vec3 verosimile = mix(erba, paglia, secco_vero) * (0.95 + 0.1 * n_verde);
	verosimile *= mix(vec3(1.0), tinta, 0.25) * 0.74;
	verosimile = mix(vec3(dot(verosimile, vec3(0.299, 0.587, 0.114))), verosimile, 0.8);
	// Pendii ripidi: l'erba si dirada e affiora la terra.
	float ripido = smoothstep(0.12, 0.3, 1.0 - n_terra.y) * smoothstep(0.35, 0.65, m_vicina + 0.25);
	vec3 terra = secca * vec3(0.78, 0.7, 0.62) * 0.62;
	verosimile = mix(verosimile, terra, ripido * 0.8);
	// Boschi: bordo irregolare (la copertura a celle viene mossa dalla maschera) e una volta
	// di chiome fatta da due strati di foglie, con macchie di luce e d'ombra grandi come alberi.
	float lobi = texture(macchie, ruota * pos_mondo.xz / 157.0 + vec2(0.21, 0.67)).r;
	float bosco = smoothstep(0.47, 0.53, texture(bosco_fine, UV).r + (texture(macchie, pos_mondo.xz / 19.0).r - 0.5) * 0.04 * (1.0 - lontano));
	if (bosco > 0.0 && sottobosco > 0.5) {
		// Sottobosco: terra con foglie secche ed erba rada, in ombra sotto le chiome.
		vec3 lettiera = mix(vec3(0.13, 0.12, 0.06), vec3(0.19, 0.17, 0.09), smoothstep(0.3, 0.7, m_fine));
		vec3 rada = verosimile * vec3(0.7, 0.75, 0.6);
		vec3 suolo_bosco = mix(lettiera, rada, smoothstep(0.35, 0.75, m_vicina * 0.7 + m_fine * 0.3) * 0.6);
		verosimile = mix(verosimile, suolo_bosco * 0.7, bosco);
	} else if (bosco > 0.0) {
		// Volta delle chiome dipinta: si vede solo quando gli alberi veri non sono disegnati
		// (vista più larga di VistaAlberi.DIM_LEGGERI). Il tono è tarato sul colore medio degli
		// alberi veri, così al cambio di zoom il bosco non cambia colore.
		vec3 volta = vec3(0.36, 0.48, 0.24);
		// Chiome di circa 10 m, appena accennate (una texture ripetuta, quindi a basso contrasto),
		// e gruppi di alberi di decine di metri da un rumore unico per la mappa.
		float chiome = texture(macchie, pos_mondo.xz / 11.0).r * 0.5 + texture(macchie, ruota * pos_mondo.xz / 17.0 + 0.3).r * 0.5;
		// Da lontano più scura: si accorda alle sagome degli alberi (misurato sulle foto).
		volta *= mix(mix(0.86, 1.1, smoothstep(0.3, 0.7, chiome)), 0.72, lontano);
		float gruppi = texture(rumore_bosco, UV).r;
		volta *= mix(0.88, 1.08, smoothstep(0.3, 0.7, gruppi));
		// Al margine il bosco si dirada.
		volta *= mix(0.8, 1.0, smoothstep(0.0, 0.6, bosco));
		verosimile = mix(verosimile, volta * 0.6, bosco);
	}
	// Zone speciali lette in otto punti attorno, come la copertura dei boschi: bordi senza gradini.
	vec2 pz = 1.2 / vec2(textureSize(zone_speciali, 0));
	vec2 zs = vec2(0.0);
	for (int i = 0; i < 8; i++) {
		float a = float(i) * 0.785398 + 0.1;
		zs += texture(zone_speciali, UV + pz * vec2(cos(a), sin(a))).rg;
	}
	zs = zs / 8.0 * 0.7 + texture(zone_speciali, UV).rg * 0.3;
	// Stesso rumore dei boschi letto con gli assi scambiati: altro disegno, nessuna ripetizione.
	float n_zona = texture(rumore_bosco, UV.yx).r;
	// Gessi: roccia chiara grigio-calda che affiora a chiazze tra l'erba rada, più fitta al centro.
	float gessi = smoothstep(0.42, 0.58, zs.g + (lobi - 0.5) * 0.35 + (m_vicina - 0.5) * 0.25);
	if (gessi > 0.0) {
		float affiora = smoothstep(0.5, 0.66, n_zona * 0.6 + m_vicina * 0.25 + zs.g * 0.22);
		// Da lontano le chiazze si fondono, altrimenti tornano i puntini.
		affiora = mix(affiora, smoothstep(0.3, 0.9, zs.g) * 0.55, lontano * 0.8);
		vec3 gesso = vec3(0.43, 0.42, 0.39) * (0.86 + 0.24 * mix(m_fine, 0.5, lontano));
		vec3 rada = verosimile * vec3(1.05, 1.0, 0.86);
		verosimile = mix(verosimile, mix(rada, gesso, affiora), gessi);
	}
	// Paludi: erba umida e scura, fango attorno alle pozze, fascia di canne secche (da vicino ci
	// sono i canneti veri). Le pozze si disegnano più sotto, con l'acqua.
	float palude = smoothstep(0.47, 0.53, texture(palude_fine, UV).r);
	float v_pozze = texture(pozze_fine, UV).r;
	float pozze = smoothstep(0.495, 0.505 + fwidth(v_pozze), v_pozze) * palude;
	if (palude > 0.0) {
		float fango = smoothstep(0.44, 0.5, v_pozze) * (1.0 - pozze);
		float canneto = smoothstep(0.28, 0.38, v_pozze) * (1.0 - fango);
		vec3 umida = verosimile * vec3(0.55, 0.66, 0.48);
		vec3 canne_secche = vec3(0.42, 0.38, 0.2) * (0.85 + 0.3 * mix(m_fine, 0.5, lontano));
		vec3 terra_bagnata = vec3(0.17, 0.15, 0.1) * (0.85 + 0.3 * m_fine);
		vec3 suolo_palude = mix(umida, canne_secche, canneto * 0.55);
		suolo_palude = mix(suolo_palude, terra_bagnata, fango * 0.85);
		verosimile = mix(verosimile, suolo_palude, palude);
	}
	base = mix(base, verosimile, realismo * max(COLOR.a, bosco));
	// Rilievo: i pendii rivolti al sole si schiariscono, quelli in ombra si scuriscono, in proporzione
	// alla luce che riceverebbe un terreno piano. Sostituisce le isoipse nella vista normale.
	vec3 ls = normalize(verso_sole);
	float rilievo = clamp(dot(n_terra, ls) / max(ls.y, 0.25), 0.3, 1.6);
	base *= mix(1.0, rilievo, forza_rilievo);
	// Anche l'acqua segue i rilievi: prende l'ombreggiatura del versante su cui scorre.
	float rilievo_acqua = clamp(dot(normale_mondo, ls) / max(ls.y, 0.25), 0.3, 1.6);
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
	// Acqua disegnata dal campo di distanza (d_acqua, calcolato all'inizio): bordi morbidi a qualunque zoom.
	float bordo = max(fwidth(d_acqua), 0.5);
	float in_acqua = 1.0 - smoothstep(-bordo, bordo, d_acqua);
	// Le pozze delle paludi sono acqua bassa e ferma.
	in_acqua = max(in_acqua, pozze);
	// Riva: terra bagnata e scura per qualche metro, poi un velo più chiaro di sabbia e limo.
	float bagnato = (1.0 - smoothstep(0.0, 3.0 + bordo, d_acqua)) * (1.0 - in_acqua);
	float limo = (1.0 - smoothstep(2.0, 7.0 + bordo, d_acqua)) * (1.0 - in_acqua) * (1.0 - bagnato);
	col = mix(col, pow(vec3(0.46, 0.42, 0.32), vec3(2.2)), limo * 0.35);
	col = mix(col, col * vec3(0.5, 0.48, 0.44), bagnato * 0.85);
	// Increspature. Le coordinate sono deformate da un rumore più ampio e gli strati hanno scale
	// e orientamenti non multipli tra loro: così la piccola texture non forma un motivo regolare.
	// Nei fiumi le increspature si allungano e scorrono nel verso della corrente (lungo la riva);
	// nelle pozze l'acqua è ferma.
	vec2 pa = pos_mondo.xz;
	vec2 lungo = length(verso_riva) > 0.0 ? vec2(-verso_riva.y, verso_riva.x) : vec2(1.0, 0.0);
	vec2 pf = vec2(dot(pa, lungo), dot(pa, verso_riva));
	float corrente = 1.0 - pozze;
	vec2 pc_ = mix(pa, vec2(pf.x / 3.0, pf.y), corrente * 0.8) + vec2(TIME * 0.6 * corrente, 0.0);
	vec2 deforma = vec2(texture(macchie, pa / 23.0 + vec2(TIME * 0.003, 0.0)).r, texture(macchie, ruota * pa / 19.0 + vec2(0.3, TIME * 0.002)).r) - 0.5;
	vec2 pd = pc_ + deforma * 9.0;
	float o1 = texture(macchie, pd / 4.3 + vec2(TIME * 0.03, TIME * 0.017)).r;
	float o2 = texture(macchie, ruota * pd / 2.9 - vec2(TIME * 0.022, -TIME * 0.031)).r;
	float o4 = texture(macchie, ruota * ruota * pd / 6.7 + vec2(0.17, 0.61) + vec2(-TIME * 0.012, TIME * 0.02)).r;
	float o3 = texture(rumore_verde, UV + vec2(TIME * 0.00002, 0.0)).r;
	float onde = ((o1 + o2 + o4) / 1.5 - 1.0) * (0.35 + o3) * mix(0.5, 1.0, corrente);
	// Variazione larga, visibile anche da lontano: chiazze di vento e di cielo riflesso.
	float vento = texture(macchie, ruota * pa / 97.0 + vec2(TIME * 0.0015, TIME * 0.0009)).r * 0.6
			+ texture(macchie, pa / 211.0 - vec2(TIME * 0.0007, 0.0)).r * 0.4;
	// Colore di un fiume di pianura: acqua torbida verde-grigia, più scura dove è fonda, con il
	// fondale bruno che traspare vicino alla riva (prima era un azzurro saturo, poco verosimile).
	float prof = smoothstep(0.0, 18.0, -d_acqua + onde * 3.0);
	vec3 bassa = vec3(0.26, 0.25, 0.16);
	vec3 media = vec3(0.13, 0.17, 0.12);
	vec3 fonda = vec3(0.06, 0.1, 0.08);
	vec3 acqua = mix(bassa, media, smoothstep(0.0, 0.4, prof));
	acqua = mix(acqua, fonda, smoothstep(0.35, 1.0, prof));
	// Pozze delle paludi: acqua ferma e scura, qualche velo di lenticchie d'acqua verdi.
	float lenticchie = smoothstep(0.62, 0.7, texture(rumore_palude, UV).r * 0.6 + m_vicina * 0.4) * smoothstep(0.5, 0.56, v_pozze);
	vec3 pozza = mix(vec3(0.09, 0.11, 0.09), vec3(0.2, 0.3, 0.1), lenticchie * 0.8);
	acqua = mix(acqua, pozza, pozze);
	// Riflessi: il cielo, più chiaro dove l'acqua è liscia, e la riva lontana (con i suoi alberi)
	// che si specchia scura nei metri d'acqua vicino a lei. "Lontana" vuol dire dalla parte
	// opposta alla camera.
	vec2 avanti_cam = normalize(-INV_VIEW_MATRIX[2].xz);
	float riva_lontana = smoothstep(0.0, 0.7, dot(verso_riva, avanti_cam)) * (1.0 - smoothstep(1.0, 14.0, -d_acqua)) * corrente;
	float bosco_riva = texture(bosco_fine, UV + verso_riva * 2.0 / vec2(textureSize(bosco_fine, 0))).r;
	vec3 riflesso_riva = mix(vec3(0.16, 0.17, 0.11), vec3(0.06, 0.09, 0.05), smoothstep(0.4, 0.6, bosco_riva));
	vec3 cielo = vec3(0.42, 0.5, 0.54);
	float liscio = smoothstep(0.25, 0.75, vento) * (1.0 - smoothstep(0.0, 0.5, abs(onde)));
	acqua = mix(acqua, cielo, 0.08 + 0.12 * liscio);
	acqua = mix(acqua, riflesso_riva, riva_lontana * 0.7);
	// Scie della corrente: righe chiare sottili e allungate lungo il fiume.
	float scie = smoothstep(0.62, 0.72, texture(macchie, vec2(pf.x / 41.0 - TIME * 0.02, pf.y / 2.3)).r) * corrente * smoothstep(2.0, 6.0, -d_acqua);
	acqua = mix(acqua, cielo * 1.1, scie * 0.25 * (1.0 - lontano));
	acqua *= 0.94 + 0.12 * smoothstep(-0.4, 0.4, onde);
	// Scintillii del sole sulle creste: pochi punti chiari che si accendono e spengono.
	float scintille = smoothstep(0.86, 0.93, o1 * 0.55 + o2 * 0.45) * smoothstep(0.4, 0.8, vento) * (1.0 - lontano) * corrente;
	acqua = mix(acqua, vec3(0.95, 0.93, 0.85), scintille * 0.6);
	// Schiuma sottile lungo la riva dei fiumi, spezzata dalle increspature.
	float schiuma = (1.0 - smoothstep(0.3, 1.6 + bordo, abs(d_acqua + 1.0 + deforma.x * 1.5))) * smoothstep(0.45, 0.6, o1 * 0.5 + o4 * 0.5) * corrente;
	acqua = mix(acqua, vec3(0.7, 0.7, 0.64), schiuma * 0.35);
	// Ombra della sponda sull'acqua: lungo la riva dalla parte del sole l'argine fa ombra.
	vec2 sole_o = length(ls.xz) > 1e-4 ? normalize(ls.xz) : vec2(0.0);
	float ombra_sponda = smoothstep(0.1, 0.7, dot(verso_riva, sole_o)) * (1.0 - smoothstep(0.0, 7.0, -d_acqua));
	acqua *= 1.0 - 0.35 * ombra_sponda * corrente;
	acqua *= mix(1.0, rilievo_acqua, forza_rilievo);
	col = mix(col, acqua, in_acqua);
	// Luce: l'acqua è liscia e riflette, il terreno no. Le increspature inclinano la normale.
	vec3 n_acqua = normalize(vec3((o1 - o4) * 0.25, 1.0, (o2 - 0.5) * 0.25));
	NORMAL = normalize(mix((VIEW_MATRIX * vec4(n_terra, 0.0)).xyz, (VIEW_MATRIX * vec4(n_acqua, 0.0)).xyz, in_acqua));
	SPECULAR = 0.5 * in_acqua;
	// Il cielo riflesso è già nel colore: l'acqua resta poco illuminata dal sole (come una
	// superficie scura e lucida) e un poco luminosa di suo, così non diventa nera in ombra.
	EMISSION = acqua * 0.15 * in_acqua;
	ROUGHNESS = mix(1.0, 0.12, in_acqua);
	ALBEDO = col;
}
