shader_type spatial;
// Sagome degli alberi per la vista lontana (VistaAlberi): un rettangolo per albero, sempre
// parallelo allo schermo, con l'immagine dell'albero fotografata in Godot con la stessa camera
// e lo stesso sole del gioco (strumenti/genera_sagome.gd). La luce è già nell'immagine, quindi
// il materiale non è illuminato; le ombre sul terreno invece le proietta.
render_mode unshaded, cull_disabled, skip_vertex_transform, depth_draw_opaque;

uniform sampler2D tavola : filter_linear_mipmap, repeat_disable;
// Per modello: rettangolo in metri rispetto alla base (sinistra, destra, basso, alto) e nella tavola.
// Spazio per 16 modelli (oggi 11: alberi, arbusti, canne).
uniform vec4 quad[16];
uniform vec4 uv_tavola[16];
// Correzione di tono, per accordare le sagome agli alberi in 3D.
uniform vec3 tono = vec3(1.0);

void vertex() {
	// Dati per istanza: INSTANCE_CUSTOM.x = modello, .y = specchiata (0 o 1); COLOR = tinta.
	int m = int(INSTANCE_CUSTOM.x + 0.5);
	float specchio = INSTANCE_CUSTOM.y > 0.5 ? -1.0 : 1.0;
	vec4 q = quad[m];
	vec4 r = uv_tavola[m];
	float s = length(MODEL_MATRIX[0].xyz);
	vec2 k = VERTEX.xy;  // angolo del rettangolo, da (0, 0) a (1, 1)
	float u = mix(q.x, q.y, k.x) * s * specchio;
	float v = mix(q.z, q.w, k.y) * s;
	vec3 base = MODEL_MATRIX[3].xyz;
	vec3 destra = INV_VIEW_MATRIX[0].xyz;
	vec3 su = INV_VIEW_MATRIX[1].xyz;
	VERTEX = (VIEW_MATRIX * vec4(base + destra * u + su * v, 1.0)).xyz;
	UV = vec2(mix(r.x, r.z, k.x), mix(r.w, r.y, k.y));
}

void fragment() {
	vec4 c = texture(tavola, UV);
	ALBEDO = c.rgb * COLOR.rgb * tono;
	ALPHA = c.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
