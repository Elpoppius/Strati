extends SceneTree
## Foto di controllo del tutorial alle tappe (decisione di Fede del 26/11/2026): il riquadro del
## luogo sacro, prima pagina della tappa dei 100 abitanti (con il pascolo come seconda pagina).
## Uso: xvfb-run -a -s "-screen 0 1600x900x24" godot --path gioco --rendering-driver opengl3 --resolution 1600x900 -s res://test/foto_tutorial.gd -- uscita.png [aperta]
## Con "aperta" la spiegazione completa ("Cosa fa un luogo sacro?") è aperta.

var _s: Node
var _f := 0


func _initialize() -> void:
	_s = load("res://scene/principale.tscn").instantiate()
	root.add_child(_s)


func _process(_d: float) -> bool:
	_f += 1
	var args := OS.get_cmdline_user_args()
	if _f == 3:
		var p: Partita = _s.partita
		var h: Hud = _s.hud
		h.chiudi_scelta()
		p.sim.decisioni = []
		var sito: Vector2i = _s.dati.siti[0]["px"]
		p.sim.fonda(p.sim.px_da_mondo(_s.dati.mondo_da_pixel(sito).x, _s.dati.mondo_da_pixel(sito).y))
		p.sim.decisioni = []
		p.vista.sincronizza()
		var c := p.sim.mondo_di_px(p.sim.centro)
		_s.cam.vai_a(c.x, c.y, 600.0)
		_s.griglia_attiva = false
		p.sim.tutorial_attivi = true
		p.sim.tutorial(["luogo_sacro", "pascolo"], "Villaggio (100 abitanti)")
		p._process(0.0)
		if args.size() > 1 and args[1] == "aperta":
			(h._modale.find_child("Domanda", true, false) as Button).emit_signal("pressed")
	if _f == 40:
		root.get_texture().get_image().save_png(args[0] if args.size() > 0 else "user://tutorial.png")
		print("Foto salvata")
		quit(0)
	return false
