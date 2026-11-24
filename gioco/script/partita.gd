class_name Partita
extends Node
## La partita della prima epoca (il villaggio) dentro la scena principale: collega la
## simulazione (SimVillaggio), il suo disegno (VistaVillaggio), l'uso del suolo e l'HUD.
## Tempo continuo con pausa e tre velocità; si ferma da solo nei momenti decisivi
## (decisione di Fede del 23/11/2026).

const STRUMENTI := ["fonda", "campi", "sentiero", "granaio", "demolisci"]
const VELOCITA := [0.0, 2.0, 6.0, 15.0]  # anni al secondo, come nel Prototipo 0
const NOMI_VELOCITA := ["Pausa", "2 anni al secondo", "6 anni al secondo", "15 anni al secondo"]

var sim: SimVillaggio
var vista: VistaVillaggio
var scena: Node  # la scena principale (hud, uso, camera, dati)
var velocita := 0
var _ultima_velocita := 1
var _accumulo := 0.0


func avvia(s: Node, seme: int = -1) -> void:
	scena = s
	sim = SimVillaggio.new(s.dati, seme if seme >= 0 else int(Time.get_unix_time_from_system()) % 100000)
	var uso: UsoSuolo = s.uso
	var dati: MappaDati = s.dati
	# La caccia conta solo il bosco ancora in piedi (tagli e campi lo tolgono).
	sim.bosco_presente = func(i: int) -> bool:
		if dati.copertura[i] <= 127:
			return false
		var w := sim.mondo_di_px(sim.px_di(i))
		return uso.stato(w.x, w.y) == UsoSuolo.NATURALE
	vista = VistaVillaggio.new()
	vista.name = "Villaggio"
	vista.prepara(sim, uso, s.terreno)
	s.add_child(vista)
	var hud: Hud = s.hud
	hud.aggiungi_comandi("Villaggio", [
		{"id": "fonda", "testo": "Fondare", "breve": "Fonda", "tasto": "F"},
		{"id": "campi", "testo": "Campi", "breve": "Campi", "tasto": "C"},
		{"id": "sentiero", "testo": "Sentiero", "breve": "Sentiero", "tasto": "V"},
		{"id": "granaio", "testo": "Granaio · 30 cibo", "breve": "Granaio", "tasto": "H"},
		{"id": "comune", "testo": "Raccolto diviso in comune", "breve": "Comune", "tasto": "", "strumento": false},
		{"id": "famiglie", "testo": "Raccolto per famiglia", "breve": "Famiglie", "tasto": "", "strumento": false},
		{"id": "demolisci", "testo": "Demolisci: alberi, case, campi, sentieri, granaio (irreversibile)", "breve": "Demolisci", "tasto": "X", "pericolo": true},
	], true)
	hud.aggiungi_tempo([
		{"id": "v0", "testo": "Pausa (Spazio)", "breve": "‖"},
		{"id": "v1", "testo": NOMI_VELOCITA[1], "breve": "2"},
		{"id": "v2", "testo": NOMI_VELOCITA[2], "breve": "6"},
		{"id": "v3", "testo": NOMI_VELOCITA[3], "breve": "15"},
	])
	hud.minimappa.segni = func() -> Array:
		var punti := []
		if sim.fondato:
			punti.append(sim.mondo_di_px(sim.centro))
		for f in sim.figli:
			punti.append(sim.mondo_di_px(sim.px_di(f)))
		return punti
	hud.azione.connect(_azione)
	hud.seleziona_comando("fonda")
	hud.imposta_messaggio("Leggi la mappa, poi clicca dove fondare il villaggio. Il cerchio mostra fin dove arriveranno i campi. È la decisione più importante della partita.")
	aggiorna_hud()


func _azione(id: String) -> void:
	match id:
		"comune", "famiglie":
			sim.imposta_usanza(id)
		"v0", "v1", "v2", "v3":
			imposta_velocita(int(id.substr(1)))
	aggiorna_hud()


func imposta_velocita(v: int) -> void:
	if not sim.fondato and v > 0:
		scena.hud.imposta_messaggio("Il tempo parte dopo la fondazione.")
		v = 0
	velocita = v
	if v > 0:
		_ultima_velocita = v
	aggiorna_hud()


func pausa_o_riprendi() -> void:
	imposta_velocita(0 if velocita > 0 else _ultima_velocita)


func _process(delta: float) -> void:
	if sim == null:
		return
	var hud: Hud = scena.hud
	if velocita > 0 and sim.fondato and not sim.finito and not sim.in_attesa() and not hud.modale_aperta():
		_accumulo += delta * VELOCITA[velocita]
		var passi := 0
		while _accumulo >= 1.0 and passi < 15 and not sim.in_attesa() and sim.fondato and not sim.finito:
			sim.passo()
			scena.uso.avanza_anni(1)
			_accumulo -= 1.0
			passi += 1
		if passi > 0:
			vista.sincronizza()
			aggiorna_hud()
	while not sim.avvisi.is_empty():
		hud.avviso(sim.avvisi.pop_front())
	if sim.in_attesa() and not hud.modale_aperta():
		_accumulo = 0.0
		var d: Dictionary = sim.decisioni[0]
		var tipi := {"sorgenti": "Presagio", "cometa": "Presagio", "primo_cattivo": "Momento decisivo", "affollamento": "Momento decisivo", "piena": "Evento", "crisi": "Crisi", "abbandono": "Fallimento", "fine": "Fine del prototipo"}
		var opzioni: Array = d["opzioni"]
		if d["tipo"] == "fine":
			opzioni = [{"id": "nuova", "testo": "Nuova partita", "nota": ""}] + opzioni
		hud.mostra_scelta(tipi.get(d["tipo"], ""), d["titolo"], d["testo"], opzioni, _scelto.bind(d["id"], d["tipo"]))


func _scelto(opzione: String, id: int, tipo: String) -> void:
	if opzione == "nuova":
		scena.get_tree().reload_current_scene()
		return
	sim.scegli(id, opzione)
	var hud: Hud = scena.hud
	if tipo == "primo_cattivo" and opzione == "campi":
		hud.seleziona_comando("campi")
		imposta_velocita(0)
	if tipo == "abbandono":
		hud.seleziona_comando("fonda")
		imposta_velocita(0)
	if tipo == "fine":
		imposta_velocita(0)
	vista.sincronizza()
	aggiorna_hud()
	scena._aggiorna_pennello()


## Usa lo strumento del villaggio nel punto della mappa (raggio in metri per i campi).
func applica(comando: String, punto: Vector3, raggio: float) -> void:
	var hud: Hud = scena.hud
	var p := sim.px_da_mondo(punto.x, punto.z)
	match comando:
		"fonda":
			if sim.fondato:
				hud.imposta_messaggio("Il villaggio è già fondato.")
				return
			if not sim.puo_fondare(p):
				hud.imposta_messaggio("Qui non si può fondare: è acqua o palude.")
				return
			var v := sim.valuta_sito(p)
			var testo := ""
			if v["sito"] != null:
				testo += "Sito %d · %s\n\n" % [v["sito"]["n"], v["sito"]["nome"]]
			for voce in [["Acqua", "acqua"], ["Fertilità intorno", "fertilita"], ["Rischio di piena", "piena"], ["Difesa", "difesa"], ["Aria", "aria"]]:
				testo += "%s: %s%s\n" % [voce[0], v[voce[1]][0], "  (sfavorevole)" if v[voce[1]][1] else ""]
			testo += "\nÈ la decisione più importante della partita: il sito condiziona tutti i secoli successivi."
			hud.mostra_scelta("Fondazione", "Fondare qui?", testo,
				[{"id": "fonda", "testo": "Fonda qui", "nota": ""}, {"id": "annulla", "testo": "Annulla", "nota": ""}],
				func(o: String) -> void:
					if o == "fonda":
						sim.fonda(p)
						vista.sincronizza()
						var c := sim.mondo_di_px(p)
						scena.cam.vai_a(c.x, c.y, 600.0)
						hud.seleziona_comando("campi")
						hud.imposta_messaggio("Villaggio fondato. Ora dissoda i campi (cerchio: un clic dissoda la terra libera dentro il cerchio; un clic su un campo lo abbandona). Poi fai scorrere il tempo con Spazio.")
						aggiorna_hud()
						scena._aggiorna_pennello())
		"campi":
			if not sim.fondato:
				return
			var celle: Array[Vector2i] = []
			var c := Vector2(punto.x, punto.z)
			var r := int(ceil(raggio / sim.dati.metri_per_px))
			for dy in range(-r, r + 1):
				for dx in range(-r, r + 1):
					var q := p + Vector2i(dx, dy)
					if q.x >= 0 and q.y >= 0 and q.x < sim.n and q.y < sim.n and sim.mondo_di_px(q).distance_to(c) <= raggio:
						celle.append(q)
			if sim.campi.has(sim.px(p)):
				hud.imposta_messaggio("Abbandonati %d campi." % sim.togli_campi(celle))
			else:
				var aggiunti := sim.aggiungi_campi(celle)
				if aggiunti == 0:
					hud.imposta_messaggio(sim.motivo_campo(p) if sim.motivo_campo(p) != "" else "Qui i campi ci sono già.")
				else:
					hud.imposta_messaggio("Dissodati %d campi (%s ha)." % [aggiunti, String.num(aggiunti * 0.16, 1).replace(".", ",")])
		"sentiero":
			var m := sim.traccia_sentiero(p)
			hud.imposta_messaggio(m if m != "" else "Sentiero tracciato: allunga il raggio dei campi di 320 m.")
		"demolisci":
			var w := Vector2(punto.x, punto.z)
			var uso: UsoSuolo = scena.uso
			var c0 := uso.cella(w.x, w.y)
			if not uso.demolibile(c0):
				hud.imposta_messaggio("Fiumi e paludi non si demoliscono: si governeranno con dighe, canali, deviazioni e bonifiche, quando l'epoca lo permetterà.")
				return
			var esito := sim.demolisci(w, raggio)
			vista.sincronizza()
			var tagliati := uso.abbatti(uso.celle_nel_cerchio(w.x, w.y, raggio))
			var parti: Array[String] = []
			if tagliati > 0:
				parti.append("%d alberi (legname)" % tagliati)
			if esito["case"] > 0:
				parti.append("%d case" % esito["case"])
			if esito["campi"] > 0:
				parti.append("%d campi" % esito["campi"])
			if esito["sentieri"] > 0:
				parti.append("%d tratti di sentiero" % esito["sentieri"])
			if esito["granaio"]:
				parti.append("il granaio")
			hud.imposta_messaggio(("Demoliti: " + ", ".join(parti) + ".") if not parti.is_empty() else "Qui non c'è niente da demolire.")
		"granaio":
			var m := sim.costruisci_granaio(Vector2(punto.x, punto.z))
			if m == "":
				hud.imposta_messaggio("Granaio costruito: le scorte si conserveranno meglio.")
				hud.seleziona_comando("campi")
			else:
				hud.imposta_messaggio(m)
	vista.sincronizza()
	aggiorna_hud()


## Raggio del cerchio dello strumento sulla mappa (metri): per Fondare la portata dei campi.
func raggio_strumento(comando: String, raggio: float) -> float:
	match comando:
		"fonda":
			return (5 + sim.raggio_extra) * SimVillaggio.PX_CELLA * sim.dati.metri_per_px
		"campi", "demolisci":
			return raggio
		"granaio":
			return 8.0
	return -1.0


func aggiorna_hud() -> void:
	var hud: Hud = scena.hud
	var on := sim.fondato
	var trattino := "—"
	hud.imposta_indicatori([
		["Anno", SimVillaggio.anno_testo(sim.anno), false],
		["Popolazione", str(roundi(sim.pop)) if on else trattino, on and sim.pop < 20.0],
		["Cibo", ("%d / %d l'anno" % [roundi(sim.cibo), roundi(sim.pop)]) if on else trattino, on and sim.cibo < sim.pop * 0.3],
		["Salute", str(roundi(sim.salute)) if on else trattino, on and sim.salute < 45.0],
		["Legittimità", str(roundi(sim.legittimita)) if on else trattino, on and sim.legittimita < 30.0],
	])
	var righe: Array = []
	for e in sim.cronaca.slice(0, 6):
		righe.append("%s · %s" % [SimVillaggio.anno_testo(e["anno"]), e["testo"]])
	hud.imposta_cronaca(righe)
	hud.abilita("fonda", not on and not sim.finito)
	for id in ["campi", "sentiero", "comune", "famiglie"]:
		hud.abilita(id, on and not sim.finito)
	hud.abilita("granaio", on and sim.granaio.x < 0 and not sim.finito)
	hud.cambia_testo("granaio", "Granaio costruito" if sim.granaio.x >= 0 else "Granaio · 30 cibo", "Costruito" if sim.granaio.x >= 0 else "Granaio")
	hud.segna("comune", sim.usanza == "comune")
	hud.segna("famiglie", sim.usanza == "famiglie")
	for k in 4:
		hud.segna("v%d" % k, velocita == k)
		hud.abilita("v%d" % k, k == 0 or (on and not sim.finito))
