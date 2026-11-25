shader_type spatial;
// Barra discreta sopra un edificio in costruzione (decisione di Fede del 25/11/2026 sera): sempre
// girata verso la camera e della stessa misura sullo schermo a ogni zoom; fondo scuro trasparente,
// riempimento bianco che avanza con il cantiere (colori dell'HUD, docs/hud.md).
render_mode unshaded, cull_disabled, depth_test_disabled, shadows_disabled, blend_mix;

uniform float progresso : hint_range(0.0, 1.0) = 0.0;
uniform vec2 dimensione_px = vec2(44.0, 6.0);
uniform vec3 colore_pieno : source_color = vec3(0.96, 0.96, 0.94);
uniform vec3 colore_fondo : source_color = vec3(0.07, 0.07, 0.07);

void vertex() {
	// La QuadMesh è 1 x 1: i vertici vanno da -0,5 a 0,5. Si sposta il centro proiettato di un
	// numero fisso di pixel.
	vec4 centro = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0));
	vec2 spostamento = VERTEX.xy * 2.0 * dimensione_px / VIEWPORT_SIZE * centro.w;
	POSITION = centro + vec4(spostamento, 0.0, 0.0);
}

void fragment() {
	vec2 px = UV * dimensione_px;
	// Un pixel di bordo scuro attorno, poi il riempimento.
	bool bordo = px.x < 1.0 || px.y < 1.0 || px.x > dimensione_px.x - 1.0 || px.y > dimensione_px.y - 1.0;
	bool pieno = !bordo && (px.x - 1.0) / (dimensione_px.x - 2.0) <= progresso;
	ALBEDO = pieno ? colore_pieno : colore_fondo;
	ALPHA = pieno ? 0.95 : (bordo ? 0.8 : 0.45);
}
