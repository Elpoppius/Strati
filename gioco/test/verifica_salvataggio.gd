extends SceneTree
## Verifiche del salvataggio (todo voce 9, 26/11/2026): si gioca una partita, si salva, si gioca
## ancora; caricando si torna esattamente allo stato salvato e, rigiocando gli stessi anni, si arriva
## esattamente allo stesso punto (anche il caso è salvato). Poi l'elenco, i salvataggi automatici e
## i file che non si possono caricare.
## Uso: godot --headless --path gioco -s res://test/verifica_salvataggio.gd

var _errori := 0
var _s: Node
var _f := 0


func controlla(cond: bool, testo: String) -> void:
	print(("OK  " if cond else "ERRORE  ") + testo)
	if not cond:
		_errori += 1


func _initialize() -> void:
	_s = load("res://scene/principale.tscn").instantiate()
	root.add_child(_s)


## Gioca `anni` anni come un giocatore attento (zona, legnaie, sentieri, pascolo, edifici).
func _gioca(p: Partita, anni: int) -> void:
	var sim := p.sim
	var uso: UsoSuolo = _s.uso
	for k in anni:
		var cg := RandomNumberGenerator.new()
		cg.seed = sim.anno * 31 + 7
		if sim.anno % 10 == 0:
			var tutta: Array[Vector2i] = []
			var r := sim.raggio_campi()
			for dy in range(-r, r + 1):
				for dx in range(-r, r + 1):
					tutta.append(sim.centro + Vector2i(dx, dy))
			sim.aggiungi_zona(tutta)
			if sim.legnaie.is_empty() or (AiutiGiocatori.legna_scarsa(sim) and sim.legnaie.size() < 3):
				AiutiGiocatori.costruisci_legnaia(sim, cg, 1.0)
			if sim.sbloccato("pascolo") and sim.pascolo.is_empty():
				AiutiGiocatori.stendi_pascolo(sim, cg, 1.0, 15.0)
			AiutiGiocatori.traccia_sentieri_lavoro(sim, cg, 1.0)
		while sim.in_attesa():
			sim.scegli(sim.decisioni[0]["id"], sim.decisioni[0]["opzioni"][0]["id"])
		sim.passo()
		p._abbatti_tagli()
		uso.avanza_anni(1)


## Impronta dello stato: tutto ciò che conta, in un numero (più alcune voci da leggere se diverge).
func _impronta(p: Partita) -> Dictionary:
	var sim := p.sim
	var uso: UsoSuolo = _s.uso
	return {"anno": sim.anno, "pop": snappedf(sim.pop, 0.001), "cibo": snappedf(sim.cibo, 0.001), "legna": snappedf(sim.legna, 0.001),
		"case": sim.case.hash(), "campi": sim.campi.hash(), "sentieri": sim.sentieri.hash(), "strade": sim.strade.size(),
		"capi": snappedf(sim.capi, 0.001), "caso": sim.rng.state, "uso": hash(uso.celle), "anni_uso": hash(uso.anni),
		"consenso": str(sim.consenso), "cronaca": sim.cronaca.size()}


func _process(_d: float) -> bool:
	_f += 1
	if _f < 3:
		return false
	var p: Partita = _s.partita
	var sim := p.sim
	Salvataggio.cartella_voluta = "user://prova_salvataggi"
	DirAccess.make_dir_recursive_absolute(Salvataggio.cartella_voluta)
	for f in DirAccess.get_files_at(Salvataggio.cartella_voluta):
		DirAccess.remove_absolute(Salvataggio.cartella_voluta.path_join(f))
	sim.decisioni.clear()
	sim.tutorial_attivi = false
	var sito: Vector2 = _s.dati.mondo_da_pixel(_s.dati.siti[0]["px"])
	sim.fonda(sim.px_da_mondo(sito.x, sito.y))
	sim.decisioni.clear()
	_gioca(p, 180)
	p.vista.sincronizza()
	var case_disegnate: int = p.vista.numero_case()
	var t0 := Time.get_ticks_msec()
	var percorso := Salvataggio.salva(p, "prova")
	var ms_salva := Time.get_ticks_msec() - t0
	# (Salvando, gli alberi tagliati in coda spariscono subito dalla mappa: l'impronta si prende dopo.)
	var prima := _impronta(p)
	controlla(percorso != "" and FileAccess.file_exists(percorso), "la partita si salva (%s, %d ms, %d kB)" % [percorso, ms_salva, FileAccess.get_file_as_bytes(percorso).size() / 1024 if percorso != "" else 0])
	var t := Salvataggio.leggi_intestazione(percorso)
	controlla(int(t.get("anno", 0)) == sim.anno and int(t.get("abitanti", -1)) == roundi(sim.pop) and String(t.get("sito", "")) != "", "l'intestazione dice anno, abitanti e luogo (%s)" % [t])
	# Si gioca ancora, poi si torna indietro.
	_gioca(p, 30)
	var dopo := _impronta(p)
	controlla(dopo != prima, "trent'anni dopo la partita è cambiata")
	t0 = Time.get_ticks_msec()
	var m := Salvataggio.carica(p, percorso)
	var ms_carica := Time.get_ticks_msec() - t0
	controlla(m == "", "il salvataggio si carica (%s, %d ms)" % [m, ms_carica])
	sim = p.sim
	var caricata := _impronta(p)
	for k in prima:
		if prima[k] != caricata[k]:
			print("   diverso: %s %s -> %s" % [k, prima[k], caricata[k]])
	controlla(caricata == prima, "caricando si torna esattamente allo stato salvato")
	controlla(p.velocita == 0, "dopo il caricamento il gioco è in pausa")
	controlla(p.vista.numero_case() == case_disegnate, "le case si ridisegnano (%d)" % p.vista.numero_case())
	_gioca(p, 30)
	var rigiocata := _impronta(p)
	for k in dopo:
		if dopo[k] != rigiocata[k]:
			print("   diverso: %s %s -> %s" % [k, dopo[k], rigiocata[k]])
	controlla(rigiocata == dopo, "rigiocando gli stessi anni si arriva allo stesso punto (anche il caso è salvato)")
	# Salvataggi automatici: se ne tengono gli ultimi tre.
	for k in 5:
		Salvataggio.salva(p, "automatico-%d" % k, true)
	var auto := DirAccess.get_files_at(Salvataggio.cartella_voluta)
	var n_auto := 0
	for f in auto:
		if f.begins_with("automatico-"):
			n_auto += 1
	controlla(n_auto == Salvataggio.AUTOMATICI, "dei salvataggi automatici restano gli ultimi %d (%d)" % [Salvataggio.AUTOMATICI, n_auto])
	var el := Salvataggio.elenco()
	controlla(el.size() == Salvataggio.AUTOMATICI + 1 and el[0].has("percorso"), "l'elenco dei salvataggi (%d)" % el.size())
	# Dall'interfaccia: F8 apre l'elenco; un clic su una partita la riprende.
	var h: Hud = _s.hud
	controlla(h._righe_azioni.has("salva") and h._righe_azioni.has("carica"), "in Strumenti ci sono Salva e Carica")
	_gioca(p, 5)
	var anno_ora := sim.anno
	p.mostra_caricamento()
	var bottoni := h._modale.find_children("*", "Button", true, false) if h.modale_aperta() else []
	var scelto: Button = null
	for b in bottoni:
		if (b as Button).text.contains("Terrazzo") and (b as Button).text.contains(SimVillaggio.anno_testo(rigiocata["anno"])):
			scelto = b
	controlla(h.modale_aperta() and bottoni.size() == Salvataggio.AUTOMATICI + 2, "F8 apre l'elenco delle partite salvate (%d voci)" % bottoni.size())
	if scelto:
		scelto.emit_signal("pressed")
	controlla(not h.modale_aperta() and p.sim.anno == rigiocata["anno"] and anno_ora != rigiocata["anno"], "un clic sull'elenco riprende la partita")
	sim = p.sim
	# File che non si possono caricare.
	var rotto := Salvataggio.cartella_voluta.path_join("rotto." + Salvataggio.ESTENSIONE)
	var f := FileAccess.open(rotto, FileAccess.WRITE)
	f.store_string("non è un salvataggio")
	f.close()
	controlla(Salvataggio.carica(p, rotto) != "", "un file rovinato non si carica e il gioco lo dice")
	var vecchio := Salvataggio.cartella_voluta.path_join("vecchio." + Salvataggio.ESTENSIONE)
	var fv := FileAccess.open_compressed(vecchio, FileAccess.WRITE, FileAccess.COMPRESSION_ZSTD)
	fv.store_var({"versione": 0, "mappa": sim.dati.nome, "anno": 0, "data": ""})
	fv.close()
	controlla(Salvataggio.carica(p, vecchio).contains("versione"), "un salvataggio di un'altra versione non si carica")
	var anno_prima := sim.anno
	Salvataggio.carica(p, rotto)
	controlla(sim.anno == anno_prima, "un caricamento fallito non tocca la partita")
	print("Verifica completata: " + ("nessun errore" if _errori == 0 else "%d errori" % _errori))
	quit(1 if _errori > 0 else 0)
	return true
