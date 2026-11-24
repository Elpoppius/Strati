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
## Sentieri come in Cities: Skylines (decisione di Fede): inizio libero, oppure dal punto più vicino
## della rete se è acceso "Collega alla rete".
var inizio_sentiero := Vector2i(-1, -1)
var collega_rete := false
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
	# Menù logici (decisione di Fede, come in Cities: Skylines e Age of Empires). Per ora le voci
	# della prima epoca; le altre arriveranno con le epoche (pascolo, luogo sacro, recinti…).
	hud.aggiungi_menu("insediamento", "Insediamento", "Dove nasce il villaggio.", [
		{"id": "fonda", "icona": "fonda", "testo": "Fondare il villaggio", "breve": "Fonda", "tasto": "F",
		 "descrizione": "Clicca dove fondare. Il cerchio mostra fin dove arriveranno i campi. È la scelta più importante della partita."},
	])
	hud.aggiungi_menu("territorio", "Territorio", "A cosa si destina la terra attorno al villaggio.", [
		{"id": "campi", "icona": "campi", "testo": "Dissodare campi", "breve": "Campi", "tasto": "C",
		 "descrizione": "Un clic dissoda la terra libera nel cerchio; i campi che ci sono già restano. Gli alberi sui nuovi campi si tagliano. Per abbandonare un campo: Demolisci."},
	])
	hud.aggiungi_menu("vie", "Vie", "Come ci si muove.", [
		{"id": "sentiero", "icona": "sentiero", "testo": "Tracciare un sentiero", "breve": "Sentiero", "tasto": "V",
		 "descrizione": "Un clic dove comincia, un clic dove finisce, poi si continua da lì; Esc chiude. I campi serviti da un sentiero collegato al villaggio rendono di più."},
	])
	hud.aggiungi_menu("edifici", "Edifici", "Costruzioni comuni. Le case nascono da sole.", [
		{"id": "granaio", "icona": "granaio", "testo": "Granaio (30 di cibo)", "breve": "Granaio", "tasto": "H",
		 "descrizione": "Costa 30 di cibo e va vicino al centro: le scorte si conservano meglio."},
	])
	# Opzione dello strumento Sentiero (Fede: un'opzione, non un tasto accanto): Collega alla rete.
	hud.aggiungi_opzioni("sentiero", [
		{"id": "collega_rete", "testo": "Collega alla rete", "suggerimento": "Acceso: ogni sentiero parte dal punto più vicino del villaggio o dei sentieri. Spento: il sentiero comincia dove vuoi."},
	])
	# Strumenti: l'ultimo menù a destra, che funziona come gli altri (decisione di Fede). Demolisci
	# resta trasversale: vale su tutto ciò che si può demolire e non è una costruzione.
	hud.aggiungi_menu("demolizione", "Demolizione", "Vale su tutto: non è una costruzione.", [
		{"id": "demolisci", "icona": "demolisci", "testo": "Demolisci (irreversibile)", "breve": "Demolisci", "tasto": "X", "pericolo": true,
		 "descrizione": "Toglie nel cerchio alberi, case, campi, sentieri e granaio. Non agisce su fiumi e paludi."},
	], "strumenti", true)
	# Le politiche non sono costruzioni (decisione di Fede): un pannello a parte, aperto da qui.
	hud.aggiungi_menu("politiche_menu", "Politiche", "Le regole del villaggio.", [
		{"id": "politiche", "icona": "politiche", "testo": "Politiche del villaggio", "breve": "Politiche", "tasto": "P", "strumento": false},
	], "gestione")
	# Ammodernamento (decisione di Fede): stesso livello delle politiche, un tasto per settore.
	# Ora l'agricolo; poi viario (strade), abitativo… Il tasto c'è già, spento finché non c'è niente
	# da ammodernare.
	hud.aggiungi_menu("ammodernamento", "Ammodernamento", "Rifà con la tecnica nuova ciò che è vecchio.", [
		{"id": "amm_agricolo", "icona": "ammodernamento_agricolo", "testo": "Ammodernamento agricolo: rifà i campi vecchi con la tecnica dell'epoca, un po' ogni anno, pagando cibo",
		 "breve": "Agricolo", "tasto": "", "strumento": false},
	], "gestione")
	hud.aggiungi_politiche([
		{"id": "fonti", "titolo": "Fonti di cibo",
		 "descrizione": "Da dove il villaggio prende il cibo. Una fonte spenta non si lavora: le sue braccia passano alle altre. Almeno una resta accesa.",
		 "interruttori": [
			{"id": "agricoltura", "testo": "Agricoltura"},
			{"id": "caccia", "testo": "Caccia e raccolta"},
			{"id": "pesca", "testo": "Pesca"}]},
		{"id": "raccolto", "titolo": "Divisione del raccolto",
		 "descrizione": "Chi tiene il frutto dei campi.",
		 "opzioni": [
			{"id": "comune", "testo": "In comune", "nota": "Il raccolto si divide tra tutti: il consenso degli anziani cresce."},
			{"id": "famiglie", "testo": "Alle famiglie", "nota": "Ogni famiglia tiene il suo: si raccoglie di più, ma il consenso cala."}]},
		{"id": "stranieri", "titolo": "Accoglienza degli stranieri",
		 "descrizione": "Ogni tanto qualcuno arriva dalla valle e chiede di fermarsi.",
		 "opzioni": [
			{"id": "aperta", "testo": "Aperta", "nota": "Chi arriva in pace resta: più braccia e tecniche nuove, qualche malattia e un po' di attrito."},
			{"id": "caso", "testo": "Caso per caso", "nota": "A ogni arrivo il tempo si ferma e gli anziani decidono."},
			{"id": "chiusa", "testo": "Chiusa", "nota": "Gli stranieri vengono mandati via: nulla cambia, il villaggio resta unito."}]},
	])
	hud.interruttore_scelto.connect(func(_politica: String, fonte: String, accesa: bool) -> void:
		if not sim.imposta_fonte(fonte, accesa):
			hud.imposta_messaggio("Almeno una fonte di cibo resta accesa.")
		aggiorna_hud())
	# Un clic su una fonte nel blocco Info apre le politiche (lì si accende e si spegne).
	hud.fonte_scelta.connect(func(_id: String) -> void: hud.apri_politiche(true))
	hud.politica_scelta.connect(func(id: String, valore: String) -> void:
		sim.imposta_politica(id, valore)
		aggiorna_hud())
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
		"politiche":
			scena.hud.apri_politiche(not scena.hud.politiche_aperte())
		"collega_rete":
			collega_rete = not collega_rete
			annulla_sentiero()
			scena.hud.seleziona_comando("sentiero")
			scena.hud.imposta_messaggio("Collega alla rete acceso: ogni sentiero parte dal punto più vicino del villaggio o dei sentieri; un clic dove finisce." if collega_rete
				else "Collega alla rete spento: un clic dove comincia il sentiero, un clic dove finisce.")
		"amm_agricolo":
			var attivo: bool = not sim.ammodernamenti["agricolo"]
			sim.imposta_ammodernamento("agricolo", attivo)
			scena.hud.imposta_messaggio(("Ammodernamento agricolo attivo: ogni anno una parte dei campi vecchi passa alla tecnica nuova, pagando cibo per il lavoro. %d campi da rifare." % sim.campi_da_ammodernare()) if attivo
				else "Ammodernamento agricolo sospeso: i campi vecchi restano come sono e rendono meno.")
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
	# Notifiche discrete: non fermano il gioco (decisione di Fede, ritmo meditativo).
	while not sim.avvisi.is_empty():
		var a: Dictionary = sim.avvisi.pop_front()
		hud.notifica(a["testo"], a["pericolo"], a["punto"])
	if sim.in_attesa() and not hud.modale_aperta():
		_accumulo = 0.0
		var d: Dictionary = sim.decisioni[0]
		var tipi := {"sorgenti": "Presagio", "cometa": "Presagio", "primo_cattivo": "Momento decisivo", "affollamento": "Momento decisivo", "stranieri": "Evento", "abbandono": "Fallimento", "fine": "Fine del prototipo"}
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
			for voce in [["Acqua", "acqua"], ["Fertilità intorno", "fertilita"], ["Boschi (caccia e raccolta)", "bosco"], ["Pesca", "pesca"], ["Rischio di piena", "piena"], ["Difesa", "difesa"], ["Aria", "aria"]]:
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
			# Solo aggiungere: i campi che ci sono già restano (Fede: sovrapporre il cerchio ai campi
			# esistenti li abbandonava). Per abbandonare un campo si usa Demolisci.
			var fuori := 0
			for q in celle:
				if not sim.a_portata(q) and not sim.campi.has(sim.px(q)):
					fuori += 1
			var aggiunti := sim.aggiungi_campi(celle)
			var nota_fuori := (" %d fuori dal contado (fino a %d m dal villaggio)." % [fuori, roundi(sim.raggio_contado())]) if fuori > 0 else ""
			if aggiunti == 0:
				hud.imposta_messaggio((sim.motivo_campo(p) if sim.motivo_campo(p) != "" else "Qui i campi ci sono già.") + (nota_fuori if sim.a_portata(p) else ""))
			else:
				hud.imposta_messaggio("Dissodati %d campi (%s ha).%s" % [aggiunti, String.num(aggiunti * 0.16, 1).replace(".", ","), nota_fuori])
		"sentiero":
			if not sim.fondato:
				hud.imposta_messaggio("Prima bisogna fondare il villaggio.")
				return
			var a := inizio_sentiero
			if collega_rete:
				a = sim.punto_rete_vicino(p)
			elif a.x < 0:
				inizio_sentiero = p
				hud.imposta_messaggio("Inizio del sentiero fissato. Clicca dove finisce (Esc per annullare).")
				anteprima_sentiero(punto)
				return
			var m := sim.traccia_sentiero_da(a, p)
			if m != "":
				hud.imposta_messaggio(m)
				return
			hud.imposta_messaggio("Sentiero tracciato (%d m)%s Continua da qui o premi Esc." % [roundi(_lunghezza(a, p)),
				": i campi che serve rendono di più." if sim.collegato(p) else ", non collegato al villaggio."])
			if not collega_rete:
				inizio_sentiero = p
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


func _lunghezza(a: Vector2i, b: Vector2i) -> float:
	return sim.mondo_di_px(a).distance_to(sim.mondo_di_px(b))


## Anteprima del sentiero sotto il puntatore, come in Cities: nastro trasparente bianco se si può
## tracciare, rosso se no, con la lunghezza o il motivo accanto.
func anteprima_sentiero(punto: Vector3) -> void:
	if not sim.fondato:
		vista.nascondi_anteprima()
		return
	var b := sim.px_da_mondo(punto.x, punto.z)
	var a := sim.punto_rete_vicino(b) if collega_rete else inizio_sentiero
	if a.x < 0:
		# Prima del primo clic: solo il punto agganciato dove comincerà.
		vista.mostra_anteprima(sim.mondo_di_px(b), sim.mondo_di_px(b), true, "Inizio")
		return
	var m := sim.motivo_sentiero(a, b)
	var testo := m
	if m == "":
		testo = "%d m" % roundi(_lunghezza(a, b))
		if not (sim.collegato(a) or sim.collegato(b)):
			testo += " · non collegato al villaggio"
	vista.mostra_anteprima(sim.mondo_di_px(a), sim.mondo_di_px(b), m == "", testo)


func annulla_sentiero() -> void:
	inizio_sentiero = Vector2i(-1, -1)
	if vista:
		vista.nascondi_anteprima()


## Raggio del cerchio dello strumento sulla mappa (metri): per Fondare la portata dei campi.
func raggio_strumento(comando: String, raggio: float) -> float:
	match comando:
		"fonda":
			return SimVillaggio.CONTADO_MIN
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
		["Densità", ("%d ab/ha" % roundi(sim.densita())) if on else trattino, on and sim.affollamento > 0.3],
	])
	# Fonti di cibo (Fede: deve essere ben leggibile da dove si attinge e quanto si usa la risorsa).
	if on:
		var freccia := "↓" if sim.andamento_selvaggina < -0.03 else ("↑" if sim.andamento_selvaggina > 0.03 else "")
		hud.imposta_fonti([
			{"id": "agricoltura", "nome": "Campi", "preso": sim.ultimo_raccolto, "offerta": sim.raccolto_potenziale, "accesa": sim.fonti["agricoltura"],
			 "suggerimento": "Raccolto di quest'anno / raccolto se si lavorassero tutti i campi (%d campi, %d lavorati)." % [sim.campi.size(), sim.ultimi_lavorati]},
			{"id": "caccia", "nome": "Caccia", "preso": sim.ultima_caccia, "offerta": sim.offerta_caccia, "accesa": sim.fonti["caccia"],
			 "allarme": sim.selvaggina < SimVillaggio.SOGLIA_SELVAGGINA, "freccia": freccia,
			 "suggerimento": "Cibo da caccia e raccolta quest'anno / quanto offrono i boschi. Selvaggina al %d%%%s. Rosso: si caccia troppo; un clic apre le politiche per sospendere la caccia." % [roundi(sim.selvaggina * 100.0),
				" (in calo)" if sim.andamento_selvaggina < -0.03 else (" (in crescita)" if sim.andamento_selvaggina > 0.03 else "")]},
			{"id": "pesca", "nome": "Pesca", "preso": sim.ultima_pesca, "offerta": sim.offerta_pesca, "accesa": sim.fonti["pesca"],
			 "suggerimento": "Cibo dalla pesca quest'anno / quanto offrono fiume, torrenti e paludi vicini."},
		])
	else:
		hud.imposta_fonti([])
	var accese: Array[String] = []
	for f in SimVillaggio.FONTI:
		if sim.fonti[f]:
			accese.append({"agricoltura": "campi", "caccia": "caccia e raccolta", "pesca": "pesca"}[f])
	hud.imposta_interruttori("fonti", sim.fonti, "Il cibo viene da: %s." % ", ".join(accese))
	var righe: Array = []
	for e in sim.cronaca.slice(0, 6):
		righe.append("%s · %s" % [SimVillaggio.anno_testo(e["anno"]), e["testo"]])
	hud.imposta_cronaca(righe)
	hud.abilita("fonda", not on and not sim.finito)
	# Dopo la fondazione il tasto non serve più (Fede): torna solo se il villaggio è abbandonato.
	hud.mostra("fonda", not on)
	hud.segna("collega_rete", collega_rete)
	for id in ["campi", "sentiero", "comune", "famiglie"]:
		hud.abilita(id, on and not sim.finito)
	hud.abilita("granaio", on and sim.granaio.x < 0 and not sim.finito)
	hud.cambia_testo("granaio", "Granaio (già costruito)" if sim.granaio.x >= 0 else "Granaio (30 di cibo)", "Granaio")
	for id in SimVillaggio.POLITICHE:
		hud.imposta_politica(id, sim.politica(id))
	# Ammodernamento agricolo: il tasto c'è già (decisione di Fede), spento finché non ci sono campi
	# vecchi; scelto (invertito) quando è attivo.
	var vecchi := sim.campi_da_ammodernare()
	hud.abilita("amm_agricolo", vecchi > 0)
	hud.segna("amm_agricolo", sim.ammodernamenti["agricolo"] and vecchi > 0)
	hud.cambia_testo("amm_agricolo",
		("Ammodernamento agricolo: %d campi da rifare con la tecnica nuova (%s)" % [vecchi, SimVillaggio.TECNICHE[sim.tecnica_corrente]]) if vecchi > 0
		else "Ammodernamento agricolo: nessun campo da rifare; servirà dal primo cambio d'epoca", "Agricolo")
	for k in 4:
		hud.segna("v%d" % k, velocita == k)
		hud.abilita("v%d" % k, k == 0 or (on and not sim.finito))
