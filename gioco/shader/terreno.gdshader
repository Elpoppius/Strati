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
// Uso del suolo (classe UsoSuolo, griglia da 10 m come bosco_fine): R bosco presente (1 = come la
// mappa), G terra nuda o battuta, B campo, A superficie sigillata.
uniform sampler2D uso_suolo : filter_linear, repeat_disable;
uniform float uso_attivo = 0.0;
// Da punto del mondo (x, z) a coordinate della texture del terreno: UV = mondo * x + y.
uniform vec2 uv_da_mondo = vec2(0.00009765625, 0.001953125);
// Zone speciali a celle da 40 m: R palude, G gessi. Lo shader ne ammorbidisce e frastaglia i bordi.
uniform sampler2D zone_speciali : filter_linear, repeat_disable;
// Idraulica a 40 m: R velocità della corrente (0–1 = 0–4 m/s), G potenza ogni 100 m (logaritmica,
// 1 = 1000 kW). Rapide e schiuma nell'acqua, mappa tematica dell'energia dell'acqua (modo 4).
uniform sampler2D idraulica : filter_linear, repeat_disable;
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
// Strumento dell'HUD: cerchio (x, z, raggio; raggio negativo = spento) e suo colore.
uniform vec3 pennello = vec3(0.0, 0.0, -1.0);
uniform vec3 colore_pennello : source_color = vec3(1.0);
// Griglia magnetica (idea di Fede, come in Cities: Skylines): mentre si pone qualcosa compaiono,
// attorno al puntatore, i quadrati a cui lo strumento si aggancia e si riempiono quelli che verranno
// presi. x = lato in metri (0 = spenta), y = scarto dell'origine (20 per le celle da 40 m centrate
// sui punti della mappa, 0 per i lotti da 20 m), z = raggio in cui si vede la griglia.
uniform vec3 griglia_magnetica = vec3(0.0);
// Contado del villaggio (x, z, raggio in metri; raggio negativo = spento): con lo strumento Campi
// si vede il confine della terra coltivabile, con la zona fuori appena velata (decisione di Fede:
// il limite c'è ma non si percepiva).
uniform vec3 contado = vec3(0.0, 0.0, -1.0);
// Zone di taglio delle legnaie (decisione di Fede del 25/11/2026): centro, raggio, 1 se la legnaia
// lavora (0 a riposo); forza: tenue sempre, marcata con gli strumenti Legnaia e Demolisci.
uniform vec4 zone_taglio[8];
uniform float forza_zone = 0.45;
// Zona agricola (un valore per punto della mappa, 1 = nella zona) e se mostrarla: si vede solo
// mentre si destina la terra, come velo chiaro con un bordo sottile.
uniform sampler2D zona_agricola : filter_linear, repeat_disable;
uniform float mostra_zona = 0.0;
// Bosco sacro (25/11/2026 sera): un byte per punto della mappa; velo dorato e bordo con lo strumento
// Bosco sacro e nelle mappe Caccia e pesca e Memoria del suolo.
uniform sampler2D bosco_sacro_mappa : filter_linear, repeat_disable;
uniform float mostra_bosco_sacro = 0.0;
// Zona di pascolo (25/11/2026 sera): velo verde chiaro e bordo con gli strumenti Pascolo, Zona
// agricola e Campo.
uniform sampler2D pascolo_mappa : filter_linear, repeat_disable;
uniform float mostra_pascolo = 0.0;

// Tecnica di ogni campo (UsoSuolo.tecniche, un byte per cella da 10 m, senza filtro): 0 zappa
// (villaggio), 1 aratro in croce, 2 centuriazione, 3 strisce medievali, 4 meccanica.
uniform sampler2D tecniche_campi : filter_nearest, repeat_disable;
// Mappe tematiche della partita (voce 8 del todo, 25/11/2026 sera).
// 5 Caccia e pesca: scorte per riquadro di 200 m (R selvaggina, G pesce), cerchi delle poste di
// caccia (w = 0) e dei capanni da pesca (w = 1): x, z, raggio, tipo.
uniform sampler2D scorte : filter_linear, repeat_disable;
uniform float lato_scorte = 10400.0;
uniform float mezzo_pixel = 20.0;
uniform vec4 cerchi_risorse[16];
// 6 Abitato e contado: centro, raggio dell'abitato (le case del nucleo), raggio del contado; i
// casali come cerchi (x, z, raggio).
uniform vec4 abitato = vec4(0.0, 0.0, -1.0, -1.0);
uniform vec4 casali[16];
// 7 Memoria del suolo: dove c'era il bosco (R, sulla griglia dell'uso del suolo) e le rovine.
uniform sampler2D memoria_suolo : filter_linear, repeat_disable;
uniform vec4 rovine[16];

varying vec3 pos_mondo;

float caso(vec2 c) {
	return fract(sin(dot(c, vec2(127.1, 311.7))) * 43758.5453);
}

vec2 caso2(vec2 c) {
	return fract(sin(vec2(dot(c, vec2(127.1, 311.7)), dot(c, vec2(269.5, 183.3)))) * 43758.5453);
}
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
	vec4 uso = uso_attivo > 0.5 ? texture(uso_suolo, UV) : vec4(1.0, 0.0, 0.0, 0.0);
	float bosco = smoothstep(0.47, 0.53, texture(bosco_fine, UV).r * uso.r + (texture(macchie, pos_mondo.xz / 19.0).r - 0.5) * 0.04 * (1.0 - lontano));
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
	// Uso del suolo: terra nuda dopo il taglio (si ricopre d'erba in pochi anni) o battuta attorno
	// alle costruzioni, campi con i solchi, superfici sigillate (cemento, asfalto, fondamenta).
	if (uso.g + uso.b + uso.a > 0.002) {
		float grana = mix(m_fine, 0.5, lontano);
		// Bordi netti ma irregolari: la texture è a 10 m e, filtrata, faceva aloni sfumati.
		float frangia = (m_fine - 0.5) * 0.25 + (m_vicina - 0.5) * 0.15;
		uso.gba = smoothstep(vec3(0.35), vec3(0.65), uso.gba + frangia) * step(vec3(0.002), uso.gba);
		// Terra battuta o appena scoperta: più chiara e polverosa dei campi arati.
		vec3 terra_nuda = mix(vec3(0.2, 0.165, 0.12), vec3(0.29, 0.24, 0.18), smoothstep(0.3, 0.7, grana));
		verosimile = mix(verosimile, terra_nuda, uso.g * 0.9);
		vec3 sigillo = vec3(0.3, 0.29, 0.27) * (0.9 + 0.2 * grana);
		verosimile = mix(verosimile, sigillo, uso.a);
	}
	// Campi. Dove non c'è un campo il terreno è normale; dove il giocatore lo pone, il campo occupa
	// le celle prese con la griglia magnetica (contorno appena sfrangiato, nessun bordo tra cella e
	// cella). L'aspetto dipende dalla tecnica del campo, che cambia con l'epoca (decisione di Fede
	// del 24/11/2026): i campi vecchi restano finché non si ammodernano.
	if (uso.b > 0.0) {
		float tec = floor(texture(tecniche_campi, UV).r * 255.0 + 0.5);
		float grana_c = mix(m_fine, 0.5, lontano);
		vec3 campo;
		if (tec < 0.5) {
			// Zappa (villaggio). Niente aratro nel 6000 a.C.: orti lavorati a mano in appezzamenti
			// di famiglia di 20–40 m, con bordi d'erbacce appena visibili e toni vicini tra loro.
			vec2 q = pos_mondo.xz / 30.0;
			vec2 cq = floor(q);
			float d1 = 1e9;
			float d2 = 1e9;
			vec2 cella = vec2(0.0);
			for (int j = -1; j <= 1; j++) {
				for (int i = -1; i <= 1; i++) {
					vec2 c = cq + vec2(float(i), float(j));
					vec2 pc = c + 0.5 + (caso2(c) - 0.5) * 0.8;
					float d = length(pc - q) * 30.0;
					if (d < d1) {
						d2 = d1;
						d1 = d;
						cella = c;
					} else if (d < d2) {
						d2 = d;
					}
				}
			}
			float h1 = caso(cella + 0.31);
			float h2 = caso(cella + 7.7);
			float h3 = caso(cella + 3.1);
			// File corte e ondulate lungo le curve di livello (in piano, un verso per appezzamento).
			vec2 discesa = normale_mondo.xz;
			float ripidezza = length(discesa);
			vec2 verso_caso = vec2(cos(h1 * 6.283), sin(h1 * 6.283));
			vec2 lungo = ripidezza > 1e-4 ? normalize(vec2(-discesa.y, discesa.x)) : verso_caso;
			lungo = normalize(mix(verso_caso, lungo, smoothstep(0.02, 0.08, ripidezza)) + vec2(1e-4));
			vec2 trav = vec2(-lungo.y, lungo.x);
			float onda = (texture(macchie, pos_mondo.xz / 9.0).r - 0.5) * 2.5;
			float file = 0.5 + 0.5 * sin((dot(pos_mondo.xz, trav) + onda) * 6.283 / 1.5);
			// Segni di zappa: tratti brevi, non solchi continui.
			float tratti = smoothstep(0.38, 0.62, texture(macchie, vec2(dot(pos_mondo.xz, lungo) / 3.5, dot(pos_mondo.xz, trav) / 4.1)).r);
			file = mix(file * tratti, 0.5, lontano);
			// Zolle: terra smossa a grana grossa.
			float zolle = mix(texture(macchie, pos_mondo.xz / 1.3 + h2 * 5.0).r, 0.5, lontano);
			vec3 terra = mix(vec3(0.19, 0.145, 0.095), vec3(0.27, 0.21, 0.14), zolle * 0.6 + grana_c * 0.4);
			terra *= 0.96 + 0.08 * h2;
			vec3 germogli = vec3(0.16, 0.21, 0.085);
			if (h3 < 0.55) {
				// Seminato: ciuffi di farro e orzo lungo le file.
				campo = mix(terra, germogli, file * 0.55 * (0.6 + 0.4 * zolle));
			} else if (h3 < 0.85) {
				// Appena zappato.
				campo = terra * (0.9 + 0.2 * file);
			} else {
				// A riposo: erbacce sulla terra.
				campo = mix(terra, verosimile * 0.85, 0.25 + 0.2 * zolle);
			}
			// Chiazze bruciate: il bosco si apriva col fuoco.
			if (h1 > 0.9) {
				float bruciato = smoothstep(0.45, 0.75, texture(macchie, pos_mondo.xz / 31.0 + h2 * 3.0).r);
				campo = mix(campo, vec3(0.09, 0.08, 0.07), bruciato * 0.3);
			}
			// Ceppi e sassi lasciati nel campo, uno ogni tanto (solo da vicino).
			vec2 g = floor(pos_mondo.xz / 7.0);
			float hp = caso(g + 0.57);
			if (hp > 0.93) {
				vec2 pp = (g + 0.2 + 0.6 * caso2(g + 1.3)) * 7.0;
				float punto = 1.0 - smoothstep(0.3, 0.55, distance(pos_mondo.xz, pp));
				vec3 colore_punto = hp > 0.965 ? vec3(0.11, 0.08, 0.055) : vec3(0.3, 0.29, 0.27);
				campo = mix(campo, colore_punto, punto * (1.0 - lontano));
			}
			// Bordi tra gli appezzamenti: una fascia d'erbacce sottile, appena più verde.
			float bordo = 1.0 - smoothstep(0.6, 1.6 + 2.5 * lontano, d2 - d1);
			campo = mix(campo, verosimile * vec3(0.85, 0.95, 0.75), bordo * 0.35 * (1.0 - lontano * 0.6));
		} else {
			// Strisce lunghe e strette nello stesso verso (circa 110 × 18 m): campi aperti a solchi,
			// per ora usati da tutte le tecniche successive (le altre si disegneranno con le loro epoche).
			const float ANGOLO = 0.35;
			vec2 lungo = vec2(cos(ANGOLO), sin(ANGOLO));
			vec2 traverso = vec2(-lungo.y, lungo.x);
			float s_lungo = dot(pos_mondo.xz, lungo);
			float s_trav = dot(pos_mondo.xz, traverso);
			float striscia = floor(s_trav / 18.0);
			float tratto = floor(s_lungo / 110.0 + fract(sin(striscia * 91.7) * 437.5));
			float h = fract(sin(striscia * 12.9898 + tratto * 78.233) * 43758.5453);
			float solchi = 0.5 + 0.5 * sin(s_trav * 3.1 + (m_fine - 0.5) * 1.5);
			solchi = mix(solchi, 0.5, lontano);
			vec3 arato = mix(vec3(0.17, 0.13, 0.085), vec3(0.25, 0.19, 0.12), solchi * 0.6 + grana_c * 0.4);
			vec3 germogli = vec3(0.16, 0.21, 0.08);
			vec3 seminato = mix(arato, germogli, smoothstep(0.35, 0.75, solchi) * 0.75);
			campo = mix(arato, seminato, step(0.6, h));
			campo *= 0.93 + 0.14 * h;
			float confine = 1.0 - smoothstep(0.0, 0.9 + 2.0 * lontano, abs(fract(s_trav / 18.0 + 0.5) - 0.5) * 18.0);
			campo *= 1.0 - confine * 0.18 * (1.0 - lontano);
		}
		verosimile = mix(verosimile, campo, uso.b * (1.0 - uso.g) * (1.0 - uso.a));
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
		} else if (modo == 4) {
			// Energia dell'acqua: dal blu (poca potenza) al giallo e al rosso (molta), lungo i corsi;
			// il resto della mappa si schiarisce.
			float p = texture(idraulica, UV).g;
			vec3 rampa = p < 0.5 ? mix(vec3(0.16, 0.38, 0.62), vec3(0.95, 0.78, 0.2), p / 0.5) : mix(vec3(0.95, 0.78, 0.2), vec3(0.78, 0.18, 0.1), (p - 0.5) / 0.5);
			// La forma della fascia viene dalla distanza fine dall'acqua (niente quadretti da 40 m).
			float vicino = (1.0 - smoothstep(12.0, 140.0, d_acqua)) * step(0.004, p);
			col = mix(mix(base, vec3(1.0), 0.35), pow(rampa, vec3(2.2)), 0.85 * vicino);
		} else if (modo == 5) {
			// Caccia e pesca: il bosco di oggi colorato dalla selvaggina (verde pieno dove abbonda,
			// bruno pallido dove è stata cacciata), le acque dal pesce (blu pieno, grigio dove
			// manca). Sotto, la mappa schiarita.
			vec2 sc = texture(scorte, (pos_mondo.xz + mezzo_pixel) / lato_scorte).rg;
			vec3 c_selv = mix(vec3(0.72, 0.64, 0.48), vec3(0.12, 0.38, 0.22), sc.r);
			col = mix(mix(base, vec3(1.0), 0.5), pow(c_selv, vec3(2.2)), 0.85 * bosco);
			float pal = smoothstep(0.47, 0.53, texture(palude_fine, UV).r);
			// Fiumi e torrenti si colorano più sotto, dove si disegna l'acqua; qui le paludi.
			vec3 c_pesce = mix(vec3(0.72, 0.74, 0.76), vec3(0.16, 0.43, 0.71), sc.g);
			col = mix(col, pow(c_pesce, vec3(2.2)), 0.6 * pal);
			for (int k = 0; k < 16; k++) {
				vec4 e = cerchi_risorse[k];
				if (e.z <= 0.0) {
					continue;
				}
				float de = distance(pos_mondo.xz, e.xy);
				float fe = max(fwidth(de), 1e-3);
				float anello = 1.0 - smoothstep(fe * 0.6, fe * 2.0, abs(de - e.z));
				float segno = 1.0 - smoothstep(10.0, 10.0 + fe * 2.0, de);
				vec3 c_anello = e.w > 0.5 ? vec3(0.1, 0.36, 0.64) : vec3(0.12, 0.38, 0.22);
				col = mix(col, pow(c_anello, vec3(2.2)), max(anello * 0.7, segno * 0.9));
			}
		} else if (modo == 6) {
			// Abitato e contado, distinti (decisione di Fede del 24/11/2026): abitato pieno, contado
			// chiaro con i campi più marcati, casali come macchie piene.
			col = mix(base, vec3(1.0), 0.45);
			vec3 c_contado = pow(vec3(0.92, 0.78, 0.5), vec3(2.2));
			vec3 c_abitato = pow(vec3(0.72, 0.45, 0.13), vec3(2.2));
			if (abitato.w > 0.0) {
				float da = distance(pos_mondo.xz, abitato.xy);
				float fa = max(fwidth(da), 1e-3);
				float nel_contado = 1.0 - smoothstep(abitato.w - fa, abitato.w + fa, da);
				col = mix(col, c_contado, 0.45 * nel_contado + 0.35 * uso.b * nel_contado);
				col = mix(col, c_abitato, 0.85 * (1.0 - smoothstep(abitato.z - fa, abitato.z + fa, da)));
				col = mix(col, c_abitato, 0.8 * (1.0 - smoothstep(fa * 0.6, fa * 2.0, abs(da - abitato.w))));
			}
			for (int k = 0; k < 16; k++) {
				vec4 e = casali[k];
				if (e.z <= 0.0) {
					continue;
				}
				float de = distance(pos_mondo.xz, e.xy);
				float fe = max(fwidth(de), 1e-3);
				col = mix(col, c_abitato, 0.85 * (1.0 - smoothstep(e.z - fe, e.z + fe, de)));
			}
		} else if (modo == 7) {
			// Memoria del suolo: viola dove c'era il bosco (più chiaro dove ricresce), grigio scuro
			// dove il suolo è sigillato per sempre, anelli sulle rovine; il bosco intatto tenue.
			float mem = texture(memoria_suolo, UV).r;
			col = mix(base, vec3(1.0), 0.5);
			col = mix(col, pow(vec3(0.6, 0.66, 0.56), vec3(2.2)), 0.5 * bosco * (1.0 - mem));
			col = mix(col, pow(vec3(0.48, 0.29, 0.62), vec3(2.2)), 0.8 * mem * (1.0 - 0.6 * bosco));
			col = mix(col, pow(vec3(0.2, 0.2, 0.22), vec3(2.2)), 0.9 * uso.a);
			for (int k = 0; k < 16; k++) {
				vec4 e = rovine[k];
				if (e.z <= 0.0) {
					continue;
				}
				float de = distance(pos_mondo.xz, e.xy);
				float fe = max(fwidth(de), 1e-3);
				col = mix(col, pow(vec3(0.32, 0.16, 0.42), vec3(2.2)), 0.9 * (1.0 - smoothstep(fe * 0.8, fe * 2.5, abs(de - e.z))));
			}
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
	if (mostra_zona > 0.5) {
		float z = texture(zona_agricola, UV).r;
		float fz = max(fwidth(z), 1e-3);
		float bordo_z = 1.0 - smoothstep(fz * 0.5, fz * 2.0, abs(z - 0.5));
		col = mix(col, vec3(1.0), smoothstep(0.45, 0.55, z) * 0.1 + bordo_z * 0.6);
	}
	if (mostra_pascolo > 0.5) {
		float zp = texture(pascolo_mappa, UV).r;
		float fp = max(fwidth(zp), 1e-3);
		float bordo_p = 1.0 - smoothstep(fp * 0.5, fp * 2.0, abs(zp - 0.5));
		vec3 verde = pow(vec3(0.72, 0.9, 0.5), vec3(2.2));
		col = mix(col, verde, smoothstep(0.45, 0.55, zp) * 0.25 + bordo_p * 0.75);
	}
	if (mostra_bosco_sacro > 0.5) {
		float zs = texture(bosco_sacro_mappa, UV).r;
		float fs = max(fwidth(zs), 1e-3);
		float bordo_s = 1.0 - smoothstep(fs * 0.5, fs * 2.0, abs(zs - 0.5));
		vec3 oro = pow(vec3(0.98, 0.86, 0.5), vec3(2.2));
		col = mix(col, oro, smoothstep(0.45, 0.55, zs) * 0.22 + bordo_s * 0.8);
	}
	if (contado.z > 0.0) {
		float dc = distance(pos_mondo.xz, contado.xy);
		float fwc2 = max(fwidth(dc), 1e-3);
		float linea_c = 1.0 - smoothstep(fwc2 * 0.8, fwc2 * 2.2, abs(dc - contado.z));
		// Tratteggio lungo il confine, per distinguerlo dal cerchio dello strumento.
		float ang = atan(pos_mondo.z - contado.y, pos_mondo.x - contado.x) * contado.z / 12.0;
		linea_c *= step(0.4, fract(ang));
		col = mix(col, vec3(1.0), linea_c * 0.75);
		col *= 1.0 - 0.18 * smoothstep(contado.z, contado.z + fwc2 * 3.0, dc);
	}
	for (int k = 0; k < 8; k++) {
		vec4 z = zone_taglio[k];
		if (z.z <= 0.0) {
			continue;
		}
		float dz = distance(pos_mondo.xz, z.xy);
		float fz = max(fwidth(dz), 1e-3);
		float bordo = 1.0 - smoothstep(fz * 0.8, fz * 2.2, abs(dz - z.z));
		float dentro = 1.0 - smoothstep(z.z - fz, z.z + fz, dz);
		float a_lavoro = mix(0.45, 1.0, z.w);
		col = mix(col, vec3(1.0), (bordo * 0.55 + dentro * 0.05) * forza_zone * a_lavoro);
	}
	// Strumento dell'HUD: anello sottile e area appena schiarita.
	if (pennello.z > 0.0) {
		float dp = distance(pos_mondo.xz, pennello.xy);
		float fw = max(fwidth(dp), 1e-3);
		float anello = 1.0 - smoothstep(fw * 0.5, fw * 2.0, abs(dp - pennello.z));
		col = mix(col, colore_pennello, anello * 0.9);
		col = mix(col, colore_pennello, (1.0 - step(pennello.z, dp)) * 0.08);
		if (griglia_magnetica.x > 0.0) {
			float lato = griglia_magnetica.x;
			vec2 gc = (pos_mondo.xz + griglia_magnetica.y) / lato;
			vec2 fwc = max(fwidth(gc), vec2(1e-4));
			vec2 lc = 1.0 - smoothstep(vec2(0.0), fwc * 1.5, min(fract(gc), 1.0 - fract(gc)));
			float rg = griglia_magnetica.z;
			float dentro = 1.0 - smoothstep(rg * 0.85, rg * 1.1, dp);
			col = mix(col, colore_pennello, max(lc.x, lc.y) * dentro * 0.55);
			// Celle che verranno prese: quelle con il centro dentro il cerchio.
			vec2 centro_cella = (floor(gc) + 0.5) * lato - griglia_magnetica.y;
			float presa = step(distance(centro_cella, pennello.xy), pennello.z);
			col = mix(col, colore_pennello, presa * 0.16);
		}
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
	// Velocità vera della corrente (dati della mappa): l'acqua scorre più in fretta dove il corso
	// è ripido e si rompe in rapide e schiuma bianca sopra circa 1,5 m/s.
	float vel = texture(idraulica, UV).r * 4.0;
	float rapide = smoothstep(1.3, 2.3, vel) * corrente;
	vec2 pc_ = mix(pa, vec2(pf.x / 3.0, pf.y), corrente * 0.8) + vec2(TIME * (0.25 + 0.3 * vel) * corrente, 0.0);
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
	// Rapide: acqua bianca a chiazze che scorrono, più fitta dove la corrente è più forte.
	float bianca = smoothstep(0.55 - 0.15 * rapide, 0.7, o1 * 0.45 + o2 * 0.35 + o4 * 0.2) * rapide;
	acqua = mix(acqua, vec3(0.78, 0.8, 0.76), bianca * mix(0.75, 0.35, lontano));
	// Ombra della sponda sull'acqua: lungo la riva dalla parte del sole l'argine fa ombra.
	vec2 sole_o = length(ls.xz) > 1e-4 ? normalize(ls.xz) : vec2(0.0);
	float ombra_sponda = smoothstep(0.1, 0.7, dot(verso_riva, sole_o)) * (1.0 - smoothstep(0.0, 7.0, -d_acqua));
	acqua *= 1.0 - 0.35 * ombra_sponda * corrente;
	acqua *= mix(1.0, rilievo_acqua, forza_rilievo);
	if (modo == 5) {
		// Caccia e pesca: l'acqua prende il colore del pesce del suo tratto (blu pieno, grigio scarso).
		float pesce = texture(scorte, (pos_mondo.xz + mezzo_pixel) / lato_scorte).g;
		acqua = mix(acqua, pow(mix(vec3(0.72, 0.74, 0.76), vec3(0.16, 0.43, 0.71), pesce), vec3(2.2)), 0.85);
	}
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
