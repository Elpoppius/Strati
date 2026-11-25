class_name Partita
extends Node
## La partita della prima epoca (il villaggio) dentro la scena principale: collega la
## simulazione (SimVillaggio), il suo disegno (VistaVillaggio), l'uso del suolo e l'HUD.
## Tempo continuo con pausa e tre velocità; si ferma da solo nei momenti decisivi
## (decisione di Fede del 23/11/2026).

const STRUMENTI := ["fonda", "zona", "campi", "sentiero", "granaio", "legnaia", "demolisci"]
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
## Ettari aggiunti alla zona agricola nella pennellata in corso (il messaggio dice il totale).
var _pennellata := 0
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
		{"id": "zona", "icona": "zona_agricola", "testo": "Zona agricola", "breve": "Zona", "tasto": "Z",
		 "descrizione": "Tieni premuto e trascina, come un pennello: la terra sotto il cerchio è destinata alla coltivazione. Dentro la zona le famiglie dissodano da sole i campi quando servono, dalla terra migliore e più vicina. Per toglierla: Demolisci."},
		{"id": "campi", "icona": "campi", "testo": "Campo", "breve": "Campo", "tasto": "C",
		 "descrizione": "Un clic dissoda subito la terra libera nel cerchio, a mano; i campi che ci sono già restano. Gli alberi sui nuovi campi si tagliano. Per abbandonare un campo: Demolisci."},
	])
	hud.aggiungi_menu("vie", "Vie", "Come ci si muove.", [
		{"id": "sentiero", "icona": "sentiero", "testo": "Tracciare un sentiero", "breve": "Sentiero", "tasto": "V",
		 "descrizione": "Un clic dove comincia, un clic dove finisce, poi si continua da lì; Esc chiude. I campi serviti da un sentiero collegato al villaggio rendono di più."},
	])
	hud.aggiungi_menu("edifici", "Edifici", "Costruzioni comuni. Le case nascono da sole.", [
		{"id": "granaio", "icona": "granaio", "testo": "Granaio (30 di legna)", "breve": "Granaio", "tasto": "H",
		 "descrizione": "Costa 30 di legna e qualche anno di lavoro, e va vicino al centro: le scorte si conservano meglio."},
		{"id": "legnaia", "icona": "legnaia", "testo": "Legnaia", "breve": "Legnaia", "tasto": "L",
		 "descrizione": "Senza legnaia non si raccoglie legna. I boscaioli abbattono gli alberi più vicini: più il bosco è vicino, più in fretta si raccoglie. Man mano che la radura si allarga la raccolta rallenta."},
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
	# Pannelli di focus (decisione di Fede del 25/11/2026): un clic su un indicatore.
	hud.indicatore_scelto.connect(func(nome: String) -> void:
		if hud.focus_aperto() == nome:
			hud.chiudi_focus()
		elif sim.fondato:
			hud.mostra_focus(dati_focus(nome)))
	hud.mappa_richiesta.connect(func(m: int) -> void: scena.imposta_modo(m))
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
			_abbatti_tagli()
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
		var tipi := {"sorgenti": "Presagio", "cometa": "Presagio", "primo_cattivo": "Momento decisivo", "affollamento": "Momento decisivo", "stranieri": "Evento", "piena": "Evento", "abbandono": "Fallimento", "fine": "Fine del prototipo"}
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
		hud.seleziona_comando("zona")
		imposta_velocita(0)
	if tipo == "piena":
		# La prima piena grande porta alla mappa del rischio di piena (decisione di Fede del 25/11/2026).
		scena.imposta_modo(3)
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
						hud.seleziona_comando("zona")
						hud.imposta_messaggio("Villaggio fondato. Ora disegna la zona agricola: dentro, le famiglie dissoderanno i campi quando serviranno. Poi fai scorrere il tempo con Spazio.")
						aggiorna_hud()
						scena._aggiorna_pennello())
		"zona":
			if not sim.fondato:
				return
			var celle_z := _celle_cerchio(p, Vector2(punto.x, punto.z), raggio)
			var fuori_z := 0
			for q in celle_z:
				if not sim.a_portata(q) and not sim.zona.has(sim.px(q)):
					fuori_z += 1
			var nuove := sim.aggiungi_zona(celle_z)
			_pennellata += nuove
			var testo_z := ("Zona agricola: %s ha in più (in tutto %s ha). Tieni premuto e trascina per stenderla. Le famiglie dissoderanno qui i campi quando serviranno." % [_ettari(_pennellata), _ettari(sim.zona.size())]) if _pennellata > 0 else "Qui la terra è già nella zona agricola, oppure non si può coltivare."
			if fuori_z > 0:
				testo_z += " %d celle fuori dal contado (fino a %d m dal villaggio)." % [fuori_z, roundi(sim.raggio_contado())]
			hud.imposta_messaggio(testo_z)
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
			if esito.get("legnaie", 0) > 0:
				parti.append("la legnaia")
			if esito.get("zona", 0) > 0:
				parti.append("%s ha di zona agricola" % _ettari(esito["zona"]))
			hud.imposta_messaggio(("Demoliti: " + ", ".join(parti) + ".") if not parti.is_empty() else "Qui non c'è niente da demolire.")
		"legnaia":
			var m := sim.costruisci_legnaia(Vector2(punto.x, punto.z))
			if m == "":
				hud.imposta_messaggio("Legnaia in costruzione: tra %d anni i boscaioli cominciano a tagliare il bosco vicino." % SimVillaggio.ANNI_CANTIERE_LEGNAIA)
			else:
				hud.imposta_messaggio(m)
		"granaio":
			var m := sim.costruisci_granaio(Vector2(punto.x, punto.z))
			if m == "":
				hud.imposta_messaggio("Granaio costruito: le scorte si conserveranno meglio.")
				hud.seleziona_comando("campi")
			else:
				hud.imposta_messaggio(m)
	vista.sincronizza()
	aggiorna_hud()


## Modalità fondazione (Fede): con lo strumento Fondare, prima della fondazione, la fascia in basso
## legge il terreno sotto il puntatore con indicatori grandi e chiari.
var _px_letto := Vector2i(-1, -1)

func in_fondazione() -> bool:
	return scena.hud.comando() == "fonda" and not sim.fondato and not sim.finito


func aggiorna_modalita() -> void:
	scena.hud.mostra_lettura_sito(in_fondazione())


func leggi_sito(punto: Vector3) -> void:
	if not in_fondazione():
		leggi_per_strumento(punto)
		return
	scena.hud.imposta_lettura_strumento([])
	var p := sim.px_da_mondo(punto.x, punto.z)
	if p == _px_letto:
		return
	_px_letto = p
	var hud: Hud = scena.hud
	if not sim.puo_fondare(p):
		hud.imposta_lettura_sito("Qui non si può fondare", {}, "È acqua o palude. Muovi il puntatore sulla terra asciutta.")
		return
	var v := sim.valuta_sito(p)
	var valori: Dictionary = v["valori"]
	var voci := {}
	for id in valori:
		var testo: String = v[id][0]
		voci[id] = [testo.substr(0, 1).to_upper() + testo.substr(1), valori[id], v[id][1]]
	var titolo := ("Sito %d · %s" % [v["sito"]["n"], v["sito"]["nome"]]) if v["sito"] != null else "Terreno aperto"
	var sfavorevoli := 0
	for id in valori:
		if v[id][1]:
			sfavorevoli += 1
	var nota := "Nessuna voce sfavorevole." if sfavorevoli == 0 else ("%d voci sfavorevoli (in rosso)." % sfavorevoli)
	nota += " Clic per fondare qui: il cerchio mostra il contado iniziale (400 m). È la decisione più importante della partita."
	hud.imposta_lettura_sito(titolo, voci, nota)


func inizia_pennellata() -> void:
	_pennellata = 0


func _ettari(px_n: int) -> String:
	return String.num(px_n * sim.dati.metri_per_px * sim.dati.metri_per_px / 10000.0, 1).replace(".", ",")


func _celle_cerchio(p: Vector2i, c: Vector2, raggio: float) -> Array[Vector2i]:
	var celle: Array[Vector2i] = []
	var r := int(ceil(raggio / sim.dati.metri_per_px))
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var q := p + Vector2i(dx, dy)
			if q.x >= 0 and q.y >= 0 and q.x < sim.n and q.y < sim.n and sim.mondo_di_px(q).distance_to(c) <= raggio:
				celle.append(q)
	return celle


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
		"zona", "campi", "demolisci":
			return raggio
		"granaio", "legnaia":
			return 8.0
	return -1.0


func aggiorna_hud() -> void:
	var hud: Hud = scena.hud
	aggiorna_modalita()
	var on := sim.fondato
	var trattino := "—"
	hud.imposta_indicatori([
		# La tappa accanto all'anno: la progressione si vede sempre (richiesta di Fede del 25/11/2026).
		["Anno", (SimVillaggio.anno_testo(sim.anno) + "  ·  " + String(SimVillaggio.TAPPE[sim.tappa]["nome"])) if on else SimVillaggio.anno_testo(sim.anno), false],
		["Popolazione", str(roundi(sim.pop)) if on else trattino, on and sim.pop < 20.0],
		# Abbondanza e Consenso: un indicatore ciascuno, con le parti al passaggio (decisioni di Fede
		# del 24–25/11/2026).
		["Abbondanza", str(roundi(sim.abbondanza * 100.0)) if on else trattino, on and sim.abbondanza < SimVillaggio.SOGLIA_CRESCITA,
			_testo_abbondanza() if on else "Cibo che avanza, salute e spazio: le nascite la seguono."],
		["Consenso", str(roundi(sim.legittimita)) if on else trattino, on and sim.legittimita < 30.0,
			_testo_consenso() if on else "Il consenso degli anziani e delle famiglie (e del sacerdote, dal luogo sacro)."],
		["Cibo", ("%d / %d l'anno" % [roundi(sim.cibo), roundi(sim.pop)]) if on else trattino, on and sim.cibo < sim.pop * 0.3],
		["Legna", ("%d  +%d −%d" % [floori(sim.legna), roundi(sim.ultima_legna), roundi(sim.consumo_legna)]) if on else trattino,
			on and sim.legna < SimVillaggio.COSTO_CASA and sim.ultima_legna < sim.consumo_legna,
			"Legna in catasta, poi quanta se ne raccoglie e quanta se ne consuma ogni anno (focolari e manutenzione delle case). Si raccoglie nei boschi vicini e si ricava dissodando; ogni casa nuova ne chiede %d, il granaio %d. Senza legna non nascono case." % [roundi(SimVillaggio.COSTO_CASA), roundi(SimVillaggio.COSTO_GRANAIO)]],
		["Densità", ("%d ab/ha" % roundi(sim.densita())) if on else trattino, on and sim.affollamento > 0.3,
			"Abitanti per ettaro (un ettaro è 100 × 100 m): la popolazione divisa per l'area dell'abitato, cioè il cerchio che contiene le case. Rossa quando le case non bastano per tutti (affollamento): la salute ne risente."],
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
	if hud.focus_aperto() != "":
		if on:
			hud.aggiorna_focus(dati_focus(hud.focus_aperto()))
		else:
			hud.chiudi_focus()
	var righe: Array = []
	for e in sim.cronaca.slice(0, 6):
		righe.append("%s · %s" % [SimVillaggio.anno_testo(e["anno"]), e["testo"]])
	hud.imposta_cronaca(righe)
	hud.abilita("fonda", not on and not sim.finito)
	# Dopo la fondazione il tasto non serve più (Fede): torna solo se il villaggio è abbandonato.
	hud.mostra("fonda", not on)
	hud.segna("collega_rete", collega_rete)
	for id in ["zona", "campi", "sentiero", "legnaia"]:
		hud.abilita(id, on and not sim.finito)
	for id in ["comune", "famiglie"]:
		hud.abilita(id, on and not sim.finito and sim.sbloccato("raccolto"))
	hud.abilita("granaio", on and sim.granaio.x < 0 and not sim.finito and sim.sbloccato("granaio"))
	var testo_granaio := "Granaio (%d di legna, %d anni di lavoro)" % [roundi(SimVillaggio.COSTO_GRANAIO), SimVillaggio.ANNI_CANTIERE_GRANAIO]
	if sim.granaio.x >= 0:
		testo_granaio = ("Granaio (in costruzione: ancora %d anni)" % sim.cantiere_granaio) if sim.cantiere_granaio > 0 else "Granaio (già costruito)"
	elif not sim.sbloccato("granaio"):
		testo_granaio = "Granaio (si apre a %d abitanti)" % SimVillaggio.TAPPE[SimVillaggio.tappa_di("granaio")]["abitanti"]
	hud.cambia_testo("granaio", testo_granaio, "Granaio")
	# Le tappe aprono le politiche (decisione di Fede del 25/11/2026).
	for id in ["raccolto", "stranieri"]:
		var aperta := not on or sim.sbloccato(id)
		hud.abilita_politica(id, aperta, "" if aperta else "Si apre con la tappa «%s» (%d abitanti)." % [SimVillaggio.TAPPE[SimVillaggio.tappa_di(id)]["nome"], SimVillaggio.TAPPE[SimVillaggio.tappa_di(id)]["abitanti"]])
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


## Suggerimenti degli indicatori composti: le parti e cosa vogliono dire.
func _testo_abbondanza() -> String:
	var p: Dictionary = sim.parti_abbondanza
	var crescita := "cresce" if sim.abbondanza > SimVillaggio.SOGLIA_CRESCITA + 0.02 else ("cala" if sim.abbondanza < SimVillaggio.SOGLIA_CRESCITA - 0.02 else "è ferma")
	return "Abbondanza: le nascite la seguono. Sopra %d la popolazione cresce, sotto cala; ora %s.\nCibo che avanza: %d%% (%.1f mesi di scorte)\nSalute: %d%%\nSpazio: %d%% (case per tutti; servono legna e terra per costruirne)" % [
		roundi(SimVillaggio.SOGLIA_CRESCITA * 100.0), crescita, roundi(p["cibo"] * 100.0), sim.mesi_di_scorta(), roundi(p["salute"] * 100.0), roundi(p["spazio"] * 100.0)]


func _testo_consenso() -> String:
	var c: Dictionary = sim.consenso
	var t := "Consenso del villaggio.\nAnziani: %d (le usanze%s)\nFamiglie: %d (il lavoro)" % [roundi(c["anziani"]),
		"" if sim.efficacia_usanze() >= 1.0 else ": scontenti, le politiche valgono meno", roundi(c["famiglie"])]
	if sim.sacerdote_attivo:
		t += "\nSacerdote: %d (i presagi)" % roundi(c["sacerdote"])
	return t


func _testo_tappa() -> String:
	var k := sim.tappa
	if k + 1 >= SimVillaggio.TAPPE.size():
		return "Tutte le tappe del villaggio sono raggiunte."
	var dopo: Dictionary = SimVillaggio.TAPPE[k + 1]
	return "Tappa raggiunta: %s. La prossima, «%s», arriva a %d abitanti. Le tappe raggiunte restano." % [SimVillaggio.TAPPE[k]["nome"], dopo["nome"], dopo["abitanti"]]


## Contenuto del pannello di focus di un indicatore: parti, cause, andamento, mappa.
func dati_focus(nome: String) -> Dictionary:
	var d := {"titolo": nome, "cause": sim.cause_di(nome), "mappa": -1}
	var serie_di := func(k: String, scala: float) -> Array:
		var out: Array = []
		for x in (sim.storia[k] as Array).slice(-100):
			out.append(float(x) * scala)
		return out
	match nome:
		"Abbondanza":
			var p: Dictionary = sim.parti_abbondanza
			d["valore"] = str(roundi(sim.abbondanza * 100.0))
			d["allarme"] = sim.abbondanza < SimVillaggio.SOGLIA_CRESCITA
			d["descrizione"] = "Le nascite seguono l'abbondanza: sopra %d la popolazione cresce, sotto cala piano." % roundi(SimVillaggio.SOGLIA_CRESCITA * 100.0)
			d["parti"] = [["Cibo che avanza", p["cibo"], "%.1f mesi" % sim.mesi_di_scorta()],
				["Salute", p["salute"], str(roundi(sim.salute))],
				["Spazio (case per tutti)", p["spazio"], "%d%%" % roundi(p["spazio"] * 100.0)]]
			d["serie"] = serie_di.call("abbondanza", 100.0)
			d["mappa"] = 2
			d["testo_mappa"] = "Mostra la fertilità del suolo"
		"Popolazione":
			d["valore"] = str(roundi(sim.pop))
			d["allarme"] = sim.pop < 20.0
			var dopo: String = ("La prossima tappa, «%s», arriva a %d abitanti." % [SimVillaggio.TAPPE[sim.tappa + 1]["nome"], SimVillaggio.TAPPE[sim.tappa + 1]["abitanti"]]) if sim.tappa + 1 < SimVillaggio.TAPPE.size() else "Tutte le tappe del villaggio sono raggiunte."
			d["descrizione"] = "%d case, %d campi. Tappa: %s. %s" % [sim.case.size(), sim.campi.size(), SimVillaggio.TAPPE[sim.tappa]["nome"], dopo]
			d["serie"] = serie_di.call("pop", 1.0)
		"Cibo":
			d["valore"] = "%d" % roundi(sim.cibo)
			d["allarme"] = sim.cibo < sim.pop * 0.3
			d["descrizione"] = "Scorte per %.1f mesi. Il granaio %s." % [sim.mesi_di_scorta(), "le conserva" if sim.granaio_pronto() else ("è in costruzione" if sim.granaio.x >= 0 else "manca: un quarto delle scorte si guasta ogni anno")]
			d["parti"] = [["Campi", sim.ultimo_raccolto / maxf(1.0, sim.raccolto_potenziale), "%d / %d" % [roundi(sim.ultimo_raccolto), roundi(sim.raccolto_potenziale)]],
				["Caccia e raccolta", sim.ultima_caccia / maxf(1.0, sim.offerta_caccia), "%d / %d" % [roundi(sim.ultima_caccia), roundi(sim.offerta_caccia)]],
				["Pesca", sim.ultima_pesca / maxf(1.0, sim.offerta_pesca), "%d / %d" % [roundi(sim.ultima_pesca), roundi(sim.offerta_pesca)]]]
			d["serie"] = serie_di.call("cibo", 1.0)
			d["mappa"] = 2
			d["testo_mappa"] = "Mostra la fertilità del suolo"
		"Salute":
			d["valore"] = str(roundi(sim.salute))
			d["allarme"] = sim.salute < 45.0
			d["descrizione"] = "Acqua, paludi, affollamento, fame e focolari decidono la salute; la salute pesa sulle nascite."
			d["serie"] = serie_di.call("salute", 1.0)
			d["mappa"] = 1
			d["testo_mappa"] = "Mostra l'acqua"
		"Consenso":
			var c: Dictionary = sim.consenso
			d["valore"] = str(roundi(sim.legittimita))
			d["allarme"] = sim.legittimita < 30.0
			d["descrizione"] = "Ogni gruppo vuole qualcosa: gli anziani il cibo e le usanze, le famiglie il raccolto e le case%s." % (", il sacerdote i presagi e il luogo sacro" if sim.sacerdote_attivo else "")
			d["parti"] = [["Anziani: le usanze", c["anziani"] / 100.0, str(roundi(c["anziani"]))],
				["Famiglie: il lavoro", c["famiglie"] / 100.0, str(roundi(c["famiglie"]))]]
			if sim.sacerdote_attivo:
				d["parti"].append(["Sacerdote: i presagi", c["sacerdote"] / 100.0, str(roundi(c["sacerdote"]))])
			d["serie"] = serie_di.call("legittimita", 1.0)
		"Legna":
			d["valore"] = str(floori(sim.legna))
			d["allarme"] = sim.legna < SimVillaggio.COSTO_CASA and sim.ultima_legna < sim.consumo_legna
			d["descrizione"] = "Si raccoglie nei boschi vicini e si ricava dissodando. Ogni casa nuova ne chiede %d, il granaio %d." % [roundi(SimVillaggio.COSTO_CASA), roundi(SimVillaggio.COSTO_GRANAIO)]
			d["parti"] = [["Raccolta / ciò che offrono i boschi", sim.ultima_legna / maxf(1.0, sim.offerta_legna), "%d / %d" % [roundi(sim.ultima_legna), roundi(sim.offerta_legna)]],
				["Bosco rimasto attorno", 1.0 - sim.disboscamento, "%d%%" % roundi((1.0 - sim.disboscamento) * 100.0)]]
			d["serie"] = serie_di.call("legna", 1.0)
	return d


## Lettura del terreno per gli strumenti della partita (decisione di Fede del 25/11/2026): le voci
## che contano per ognuno, come in fondazione.
func leggi_per_strumento(punto: Vector3) -> void:
	var hud: Hud = scena.hud
	var cmd := hud.comando()
	if not sim.fondato or not cmd in ["zona", "campi", "granaio", "legnaia", "sentiero"]:
		hud.imposta_lettura_strumento([])
		return
	var p := sim.px_da_mondo(punto.x, punto.z)
	var i := sim.px(p)
	if not sim.edificabile(i):
		hud.imposta_lettura_strumento([["Terreno", "Acqua o palude", 0.0, true]])
		return
	var c := sim.mondo_di_px(sim.centro)
	var d := Vector2(punto.x, punto.z).distance_to(c)
	var fl := sim.piena(i)
	var piena_voce := ["Rischio di piena", "alto" if fl > 0.5 else ("medio" if fl > 0.25 else ("basso" if fl > 0.0 else "nullo")), fl, fl > 0.25]
	var voci: Array = []
	match cmd:
		"zona", "campi":
			var f := sim.fert(i) / 1.2
			voci.append(["Fertilità", "alta" if f > 0.7 else ("buona" if f > 0.55 else ("media" if f > 0.38 else "scarsa")), f, f <= 0.38])
			voci.append(piena_voce)
			var r := sim.raggio_contado()
			voci.append(["Distanza", "%d m" % roundi(d), 1.0 - clampf(d / maxf(r, 1.0), 0.0, 1.0), d > r])
			var bosco := sim.bosco_presente.call(i) as bool
			voci.append(["Bosco", "si perde (dà legna)" if bosco else "nessuno", 1.0 if bosco else 0.0, false])
		"legnaia":
			var b := sim.bosco_per_legnaia(Vector2(punto.x, punto.z))
			var vicino: float = b["vicino"]
			var eff := clampf(1.0 - vicino / SimVillaggio.RAGGIO_LEGNAIA, 0.0, 1.0) if vicino >= 0.0 else 0.0
			voci.append(["Bosco vicino", ("a %d m" % roundi(vicino)) if vicino >= 0.0 else "nessuno", eff, eff < 0.4])
			voci.append(["Bosco attorno", "%d%%" % roundi(float(b["quota"]) * 100.0), float(b["quota"]), float(b["quota"]) < 0.15])
			voci.append(["Distanza dal centro", "%d m" % roundi(d), 1.0 - clampf(d / SimVillaggio.DISTANZA_MASSIMA_LEGNAIA, 0.0, 1.0), d > SimVillaggio.DISTANZA_MASSIMA_LEGNAIA])
			voci.append(piena_voce)
		"granaio":
			voci.append(piena_voce)
			voci.append(["Distanza dal centro", "%d m" % roundi(d), 1.0 - clampf(d / 320.0, 0.0, 1.0), d > 320.0])
			voci.append(["Legna", "%d / %d" % [floori(sim.legna), roundi(SimVillaggio.COSTO_GRANAIO)], sim.legna / SimVillaggio.COSTO_GRANAIO, sim.legna < SimVillaggio.COSTO_GRANAIO])
		"sentiero":
			var q0 := sim.dati.quota(punto.x - 20.0, punto.z)
			var q1 := sim.dati.quota(punto.x + 20.0, punto.z)
			var q2 := sim.dati.quota(punto.x, punto.z - 20.0)
			var q3 := sim.dati.quota(punto.x, punto.z + 20.0)
			var pend := Vector2(q1 - q0, q3 - q2).length() / 40.0 * 100.0
			voci.append(["Pendenza", "%d%%" % roundi(pend), clampf(pend / 30.0, 0.0, 1.0), pend > 20.0])
			var vicino_acqua := false
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var q := p + Vector2i(dx, dy)
					if q.x >= 0 and q.y >= 0 and q.x < sim.n and q.y < sim.n:
						var t := sim.dati.tipo[sim.px(q)]
						if t == MappaDati.FIUME or t == MappaDati.TORRENTE or t == MappaDati.TORRENTE_EST:
							vicino_acqua = true
			voci.append(["Acqua", "guado vicino" if vicino_acqua else "asciutto", 1.0 if vicino_acqua else 0.0, false])
			voci.append(piena_voce)
	hud.imposta_lettura_strumento(voci)


## Gli alberi abbattuti dalle legnaie spariscono dalla mappa (decisione di Fede del 25/11/2026: il
## taglio si deve vedere); l'uso del suolo li fa ricrescere dai margini.
func _abbatti_tagli() -> void:
	if sim.tagli_anno.is_empty():
		return
	var uso: UsoSuolo = scena.uso
	var celle: Array[Vector2i] = []
	var mezzo := sim.dati.metri_per_px * 0.5
	for i in sim.tagli_anno:
		var w := sim.mondo_di_px(sim.px_di(i))
		var a := uso.cella(w.x - mezzo + 1.0, w.y - mezzo + 1.0)
		var b := uso.cella(w.x + mezzo - 1.0, w.y + mezzo - 1.0)
		for y in range(a.y, b.y + 1):
			for x in range(a.x, b.x + 1):
				celle.append(Vector2i(x, y))
	uso.abbatti(celle)
	sim.tagli_anno = []
