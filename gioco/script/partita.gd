class_name Partita
extends Node
## La partita della prima epoca (il villaggio) dentro la scena principale: collega la
## simulazione (SimVillaggio), il suo disegno (VistaVillaggio), l'uso del suolo e l'HUD.
## Tempo continuo con pausa e tre velocità; si ferma da solo nei momenti decisivi
## (decisione di Fede del 23/11/2026).

const STRUMENTI := ["fonda", "zona", "campi", "pascolo", "sentiero", "granaio", "legnaia", "capanno", "posta", "luogo_sacro", "bosco_sacro", "demolisci"]
const VELOCITA := [0.0, 1.0, 6.0, 15.0]  # anni al secondo (velocità 1 più calma: decisione di Fede del 25/11/2026)
const NOMI_VELOCITA := ["Pausa", "1 anno al secondo", "6 anni al secondo", "15 anni al secondo"]

var sim: SimVillaggio
var vista: VistaVillaggio
var scena: Node  # la scena principale (hud, uso, camera, dati)
var velocita := 0
## Sentieri come in Cities: Skylines (decisione di Fede): inizio libero, oppure dal punto più vicino
## della rete se è acceso "Collega alla rete".
var inizio_sentiero := Vector2i(-1, -1)
var collega_rete := false
## Opzione "Togli" delle zone (decisione di Fede del 25/11/2026 sera): il pennello toglie la zona e
## lascia campi e animali dove sono.
var togli_zona := false
var togli_pascolo := false
## Ettari aggiunti alla zona agricola nella pennellata in corso (il messaggio dice il totale).
var _pennellata := 0
var _ultima_velocita := 1
var _accumulo := 0.0
## Lo specchietto "Conseguenze" si ricalcola qualche volta al secondo, solo se è cambiato
## qualcosa (strumento, punto, anno, opzioni).
var _attesa_conseguenze := 0.0
var _chiave_conseguenze := []


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
	# Tutorial alle tappe (decisione di Fede del 26/11/2026): accesi in ogni partita nuova; la
	# casella "Salta i tutorial" li spegne fino alla fine della partita.
	# Le foto di controllo (test/foto_*.gd) partono senza tutorial, che coprirebbero la scena.
	var ml := Engine.get_main_loop()
	var script_avvio: String = (ml.get_script() as Script).resource_path if ml.get_script() != null else ""
	if not script_avvio.contains("/test/foto"):
		sim.tutorial_attivi = true
		sim.tutorial(["fondare"], "Inizio della partita")
	vista = VistaVillaggio.new()
	vista.name = "Villaggio"
	vista.prepara(sim, uso, s.terreno)
	vista.cam = s.cam
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
		 "descrizione": "Tieni premuto e trascina, come un pennello: la terra sotto il cerchio è destinata alla coltivazione. Dentro la zona le famiglie dissodano da sole i campi quando servono, dalla terra migliore e più vicina. Per toglierla senza toccare i campi: opzione Togli."},
		# Pascolo (decisioni di Fede del 25/11/2026); tasto N, proposta di Claude.
		{"id": "pascolo", "icona": "pascolo", "testo": "Pascolo", "breve": "Pascolo", "tasto": "N",
		 "descrizione": "Tieni premuto e trascina, come un pennello, su prati, radure e margini del bosco: le famiglie ci portano gli animali, e lì il bosco non ricresce. Sui campi coltivati gli animali pascolano solo le stoppie dopo il raccolto; i campi stanchi diventano maggese e si riposano più in fretta. Per toglierlo: opzione Togli."},
		{"id": "campi", "icona": "campi", "testo": "Campo", "breve": "Campo", "tasto": "C",
		 "descrizione": "Un clic dissoda subito la terra libera nel cerchio, a mano; i campi che ci sono già restano. Gli alberi sui nuovi campi si tagliano. Per abbandonare un campo: Demolisci."},
		# Bosco sacro (decisione di Fede: tappa dei 150, la riserva); tasto B, proposta di Claude
		# approvata da Fede il 25/11/2026 sera.
		{"id": "bosco_sacro", "icona": "bosco_sacro", "testo": "Bosco sacro", "breve": "B. sacro", "tasto": "B",
		 "descrizione": "Tieni premuto e trascina sul bosco, come un pennello: diventa bosco sacro. Le legnaie non lo tagliano e nessuno lo dissoda; il sacerdote lo vuole grande. Tagliarlo con Demolisci lo offende."},
	])
	hud.aggiungi_menu("vie", "Vie", "Come ci si muove.", [
		{"id": "sentiero", "icona": "sentiero", "testo": "Tracciare un sentiero", "breve": "Sentiero", "tasto": "V",
		 "descrizione": "Un clic dove comincia, un clic dove finisce, poi si continua da lì; Esc chiude. I campi serviti da un sentiero collegato al villaggio rendono di più."},
	])
	hud.aggiungi_menu("edifici", "Edifici", "Costruzioni comuni. Le case nascono da sole.", [
		{"id": "granaio", "icona": "granaio", "testo": "Granaio (30 di legna)", "breve": "Granaio", "tasto": "H",
		 "descrizione": "Costa 30 di legna e qualche anno di lavoro, e va vicino al centro: le scorte si conservano meglio."},
		{"id": "legnaia", "icona": "legnaia", "testo": "Legnaia", "breve": "Legnaia", "tasto": "L",
		 "descrizione": "Senza legnaia non si raccoglie legna. I boscaioli abbattono gli alberi più vicini: più il bosco è vicino, più in fretta si raccoglie; la zona di taglio resta aperta finché la legnaia lavora. Clic su una legnaia: lasciar ricrescere il bosco o rimetterla al lavoro."},
		# Capanno da pesca e Posta di caccia (decisioni di Fede del 25/11/2026): senza, caccia e pesca
		# rendono un terzo. Tasti K e T: proposta di Claude.
		{"id": "luogo_sacro", "icona": "luogo_sacro", "testo": "Luogo sacro (20 di legna)", "breve": "L. sacro", "tasto": "O",
		 "descrizione": "Un cerchio di pali attorno a una pietra, vicino al villaggio. Costa 20 di legna e tre anni di lavoro. Il sacerdote è contrariato finché non c'è; contento, i presagi sono più chiari, scontento, ambigui. Le case gli crescono attorno."},
		{"id": "capanno", "icona": "capanno_pesca", "testo": "Capanno da pesca", "breve": "Capanno", "tasto": "K",
		 "descrizione": "Senza capanno le famiglie pescano come capita e rendono un terzo. Va sulla riva di un fiume o di un torrente: si aggancia da solo alla riva più vicina. Il fiume dà più pesce dei torrenti; più capanni vicini si dividono il pesce di quel tratto, e troppi lo fanno calare."},
		{"id": "posta", "icona": "posta_caccia", "testo": "Posta di caccia", "breve": "Posta", "tasto": "T",
		 "descrizione": "Senza posta le famiglie cacciano attorno al villaggio e rendono un terzo. Va al margine del bosco: si aggancia da sola al margine più vicino. Rende di più dove il bosco è fitto e la selvaggina abbondante; se lì si caccia troppo, la selvaggina cala."},
	])
	# Opzione dello strumento Sentiero (Fede: un'opzione, non un tasto accanto): Collega alla rete.
	hud.aggiungi_opzioni("zona", [
		{"id": "togli_zona", "testo": "Togli", "suggerimento": "Acceso: il pennello toglie la zona agricola e lascia i campi dove sono."},
	])
	hud.aggiungi_opzioni("pascolo", [
		{"id": "togli_pascolo", "testo": "Togli", "suggerimento": "Acceso: il pennello toglie il pascolo e lascia campi e animali dove sono."},
	])
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
		{"id": "affollati", "titolo": "Villaggio affollato",
		 "descrizione": "Quando mancano case per molte famiglie.",
		 "opzioni": [
			{"id": "allargare", "testo": "Allargare l'abitato", "nota": "Le case si stringono e l'abitato cresce verso i campi; per qualche anno la salute ne risente."},
			{"id": "emigrare", "testo": "Emigrare", "nota": "Chi non trova posto parte in cerca di terra altrove: meno bocche e meno braccia."}]},
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
		{"id": "v1", "testo": NOMI_VELOCITA[1], "breve": "1"},
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
		"togli_zona":
			togli_zona = not togli_zona
			scena.hud.seleziona_comando("zona")
			scena.hud.imposta_messaggio("Togli acceso: il pennello toglie la zona agricola; i campi restano." if togli_zona else "Togli spento: il pennello stende la zona agricola.")
		"togli_pascolo":
			togli_pascolo = not togli_pascolo
			scena.hud.seleziona_comando("pascolo")
			scena.hud.imposta_messaggio("Togli acceso: il pennello toglie il pascolo; campi e animali restano." if togli_pascolo else "Togli spento: il pennello stende il pascolo.")
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
	# Le barre dei cantieri scorrono con la parte dell'anno già passata.
	if velocita > 0:
		vista.aggiorna_barre(_accumulo)
	# Notifiche discrete: non fermano il gioco (decisione di Fede, ritmo meditativo).
	while not sim.avvisi.is_empty():
		var a: Dictionary = sim.avvisi.pop_front()
		hud.notifica(a["testo"], a["pericolo"], a["punto"])
	if famiglia != NESSUNA_CASA and hud.focus_aperto() != _titolo_famiglia:
		_evidenzia_famiglia(NESSUNA_CASA)
	_attesa_conseguenze -= delta
	if _attesa_conseguenze <= 0.0:
		_attesa_conseguenze = 0.2
		aggiorna_conseguenze()
	if sim.in_attesa() and not hud.modale_aperta():
		_accumulo = 0.0
		var d: Dictionary = sim.decisioni[0]
		var tipi := {"sorgenti": "Presagio", "cometa": "Presagio", "primo_cattivo": "Momento decisivo", "affollamento": "Momento decisivo", "stranieri": "Evento", "piena": "Evento", "abbandono": "Fallimento", "fine": "Fine del prototipo"}
		if d["tipo"] == "tutorial":
			hud.mostra_tutorial(d, _scelto.bind(d["id"], d["tipo"]))
			return
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
			if togli_zona:
				_pennellata += sim.togli_zona(celle_z)
				hud.imposta_messaggio("Zona agricola: tolti %s ha (ne restano %s ha). I campi restano." % [_ettari(_pennellata), _ettari(sim.zona.size())])
				return
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
		"pascolo":
			if not sim.fondato:
				return
			var celle_pa := _celle_cerchio(p, Vector2(punto.x, punto.z), raggio)
			if togli_pascolo:
				_pennellata += sim.togli_pascolo(celle_pa)
				hud.imposta_messaggio("Pascolo: tolti %s ha (ne restano %s ha). Campi e animali restano." % [_ettari(_pennellata), _ettari(sim.pascolo.size())])
				return
			_pennellata += sim.aggiungi_pascolo(celle_pa)
			if _pennellata > 0:
				hud.imposta_messaggio("Pascolo: %s ha in più (in tutto %s ha, per %d capi). Tieni premuto e trascina per stenderlo." % [_ettari(_pennellata), _ettari(sim.pascolo.size()), roundi(sim.portata_capi)])
			else:
				var m_pa := sim.motivo_pascolo(p)
				hud.imposta_messaggio(m_pa if m_pa != "" else "Qui c'è già il pascolo.")
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
			if esito.get("luogo_sacro", false):
				parti.append("il luogo sacro")
			if esito.get("bosco_sacro", 0) > 0:
				parti.append("%d alberi del bosco sacro" % esito["bosco_sacro"])
			if esito.get("poste", 0) > 0:
				parti.append("la posta di caccia")
			if esito.get("capanni", 0) > 0:
				parti.append("il capanno da pesca")
			if esito.get("zona", 0) > 0:
				parti.append("%s ha di zona agricola" % _ettari(esito["zona"]))
			hud.imposta_messaggio(("Demoliti: " + ", ".join(parti) + ".") if not parti.is_empty() else "Qui non c'è niente da demolire.")
		"legnaia":
			# Clic su una legnaia che c'è già: "Lasciar ricrescere" o rimetterla al lavoro.
			var k := sim.legnaia_vicina(Vector2(punto.x, punto.z))
			if k >= 0:
				var a_riposo := not bool(sim.legnaie[k]["riposo"])
				sim.metti_a_riposo(k, a_riposo)
				hud.imposta_messaggio("Legnaia a riposo: i boscaioli non tagliano e il bosco ricresce dalle ceppaie." if a_riposo else "La legnaia torna al lavoro.")
				aggiorna_hud()
				return
			var m := sim.costruisci_legnaia(Vector2(punto.x, punto.z))
			if m == "":
				hud.imposta_messaggio("Legnaia in costruzione: tra %d anni i boscaioli cominciano a tagliare il bosco vicino." % SimVillaggio.ANNI_CANTIERE_LEGNAIA)
			else:
				hud.imposta_messaggio(m)
		"luogo_sacro":
			var m := sim.costruisci_luogo_sacro(Vector2(punto.x, punto.z))
			hud.imposta_messaggio(("Il luogo sacro si comincia a erigere: tra %d anni il sacerdote sarà soddisfatto." % SimVillaggio.ANNI_CANTIERE_LUOGO_SACRO) if m == "" else m)
		"bosco_sacro":
			if not sim.fondato:
				return
			var celle_s := _celle_cerchio(p, Vector2(punto.x, punto.z), raggio)
			var nuovi_s := sim.aggiungi_bosco_sacro(celle_s)
			_pennellata += nuovi_s
			if _pennellata > 0:
				hud.imposta_messaggio("Bosco sacro: %s ha in più (in tutto %s ha in piedi). Tieni premuto e trascina sul bosco." % [_ettari(_pennellata), String.num(sim.ettari_bosco_sacro(), 1).replace(".", ",")])
			else:
				hud.imposta_messaggio(sim.motivo_bosco_sacro(p) if sim.motivo_bosco_sacro(p) != "" else "Qui il bosco è già sacro.")
		"capanno":
			var m := sim.costruisci_capanno(Vector2(punto.x, punto.z))
			hud.imposta_messaggio(("Capanno da pesca in costruzione: tra %d anni si comincia a pescare in questo tratto." % SimVillaggio.ANNI_CANTIERE_RISORSE) if m == "" else m)
		"posta":
			var m := sim.costruisci_posta(Vector2(punto.x, punto.z))
			hud.imposta_messaggio(("Posta di caccia in costruzione: tra %d anni i cacciatori battono il bosco attorno." % SimVillaggio.ANNI_CANTIERE_RISORSE) if m == "" else m)
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
		"zona", "campi", "demolisci", "bosco_sacro", "pascolo":
			return raggio
		"granaio", "legnaia", "capanno", "posta":
			return 8.0
		"luogo_sacro":
			return 6.0
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
		# Animali (decisione di Fede del 25/11/2026): capi / quanti ne nutre il pascolo.
		["Animali", ("%d / %d" % [roundi(sim.capi), roundi(sim.portata_capi)]) if on and sim.sbloccato("pascolo") else trattino,
			on and sim.sbloccato("pascolo") and sim.pascolo_eccessivo > 0.3,
			"Capi della mandria / quanti ne nutre il pascolo. Un solo numero, con pecore e capre soprattutto, maiali vicino al bosco, qualche bue. Nelle annate cattive se ne macella quanto serve. Si apre a %d abitanti." % SimVillaggio.TAPPE[SimVillaggio.tappa_di("pascolo")]["abitanti"]],
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
			 "suggerimento": "Cibo da caccia e raccolta quest'anno / quanto offrono i boschi (senza posta di caccia un terzo). Selvaggina al %d%%%s. Rosso: si caccia troppo; un clic apre le politiche per sospendere la caccia." % [roundi(sim.selvaggina * 100.0),
				" (in calo)" if sim.andamento_selvaggina < -0.03 else (" (in crescita)" if sim.andamento_selvaggina > 0.03 else "")]},
			{"id": "pesca", "nome": "Pesca", "preso": sim.ultima_pesca, "offerta": sim.offerta_pesca, "accesa": sim.fonti["pesca"],
			 "suggerimento": "Cibo dalla pesca quest'anno / quanto offrono fiume, torrenti e paludi vicini (senza capanno da pesca un terzo)."},
		])
	else:
		hud.imposta_fonti([])
	var accese: Array[String] = []
	for f in SimVillaggio.FONTI:
		if sim.fonti[f]:
			accese.append({"agricoltura": "campi", "caccia": "caccia e raccolta", "pesca": "pesca"}[f])
	hud.imposta_interruttori("fonti", sim.fonti, "Il cibo viene da: %s." % ", ".join(accese))
	scena.aggiorna_zone_taglio()
	aggiorna_mappe_tematiche()
	if famiglia != NESSUNA_CASA:
		if on:
			_aggiorna_famiglia()
		else:
			hud.chiudi_focus()
			_evidenzia_famiglia(NESSUNA_CASA)
	elif hud.focus_aperto() != "":
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
	hud.segna("togli_zona", togli_zona)
	hud.segna("togli_pascolo", togli_pascolo)
	hud.abilita("pascolo", on and not sim.finito and sim.sbloccato("pascolo"))
	hud.cambia_testo("pascolo", "Pascolo" if sim.sbloccato("pascolo") else "Pascolo (si apre a %d abitanti)" % SimVillaggio.TAPPE[SimVillaggio.tappa_di("pascolo")]["abitanti"], "Pascolo")
	for id in ["zona", "campi", "sentiero", "legnaia", "capanno", "posta"]:
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
	# Luogo sacro e bosco sacro seguono le loro tappe (100 e 150 abitanti).
	hud.abilita("luogo_sacro", on and sim.luogo_sacro.x < 0 and not sim.finito and sim.sbloccato("luogo_sacro"))
	var testo_sacro := "Luogo sacro (%d di legna, %d anni di lavoro)" % [roundi(SimVillaggio.COSTO_LUOGO_SACRO), SimVillaggio.ANNI_CANTIERE_LUOGO_SACRO]
	if sim.luogo_sacro.x >= 0:
		testo_sacro = ("Luogo sacro (in costruzione: ancora %d anni)" % sim.cantiere_luogo_sacro) if sim.cantiere_luogo_sacro > 0 else "Luogo sacro (già eretto)"
	elif not sim.sbloccato("luogo_sacro"):
		testo_sacro = "Luogo sacro (si apre a %d abitanti)" % SimVillaggio.TAPPE[SimVillaggio.tappa_di("luogo_sacro")]["abitanti"]
	hud.cambia_testo("luogo_sacro", testo_sacro, "L. sacro")
	hud.abilita("bosco_sacro", on and not sim.finito and sim.sbloccato("bosco_sacro"))
	hud.cambia_testo("bosco_sacro", "Bosco sacro" if sim.sbloccato("bosco_sacro") else "Bosco sacro (si apre a %d abitanti)" % SimVillaggio.TAPPE[SimVillaggio.tappa_di("bosco_sacro")]["abitanti"], "B. sacro")
	# Le tappe aprono le politiche (decisione di Fede del 25/11/2026).
	for id in ["raccolto", "stranieri", "affollati"]:
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


## Mappe tematiche della partita (voce 8 del todo, 25/11/2026 sera): i dati vanno allo shader del
## terreno. 5 Caccia e pesca: scorte per riquadro e cerchi di poste e capanni; 6 Abitato e contado:
## centro, raggi e casali; 7 Memoria del suolo: le rovine (la memoria del bosco viene dall'uso del
## suolo).
var _immagine_scorte: Image
var _texture_scorte: ImageTexture


func aggiorna_mappe_tematiche() -> void:
	var t: ShaderMaterial = scena.terreno.materiale
	var nb := ceili(float(sim.n) / SimVillaggio.BLOCCO_RISORSE)
	if _immagine_scorte == null:
		_immagine_scorte = Image.create(nb, nb, false, Image.FORMAT_RG8)
		_texture_scorte = ImageTexture.create_from_image(_immagine_scorte)
		t.set_shader_parameter("scorte", _texture_scorte)
		t.set_shader_parameter("lato_scorte", nb * SimVillaggio.BLOCCO_RISORSE * sim.dati.metri_per_px)
		t.set_shader_parameter("mezzo_pixel", sim.dati.metri_per_px * 0.5)
	# Solo con la mappa aperta: le scorte cambiano ogni anno.
	if scena.modo == 5:
		_immagine_scorte.fill(Color(1, 1, 0))
		for c in sim.scorta_selvaggina:
			_immagine_scorte.set_pixel(c.x, c.y, Color(float(sim.scorta_selvaggina[c]), 1, 0))
		for c in sim.scorta_pesce:
			var v := _immagine_scorte.get_pixel(c.x, c.y)
			_immagine_scorte.set_pixel(c.x, c.y, Color(v.r, float(sim.scorta_pesce[c]), 0))
		_texture_scorte.update(_immagine_scorte)
	var cerchi: Array[Vector4] = []
	for e in sim.poste:
		cerchi.append(Vector4(e["punto"].x, e["punto"].y, SimVillaggio.RAGGIO_POSTA, 0.0))
	for e in sim.capanni:
		cerchi.append(Vector4(e["punto"].x, e["punto"].y, SimVillaggio.RAGGIO_CAPANNO, 1.0))
	t.set_shader_parameter("cerchi_risorse", _sedici(cerchi))
	var casali: Array[Vector4] = []
	if sim.fondato:
		var c := sim.mondo_di_px(sim.centro)
		t.set_shader_parameter("abitato", Vector4(c.x, c.y, sim.raggio_case(), sim.raggio_contado()))
		for l in sim.casali:
			var p := sim.centro_lotto(l)
			casali.append(Vector4(p.x, p.y, 45.0, 0.0))
	else:
		t.set_shader_parameter("abitato", Vector4(0, 0, -1, -1))
	t.set_shader_parameter("casali", _sedici(casali))
	var rovine: Array[Vector4] = []
	for p in sim.rovine:
		rovine.append(Vector4(p.x, p.y, 14.0, 0.0))
	t.set_shader_parameter("rovine", _sedici(rovine))


## Sedici voci per gli array dello shader: le prime sedici, il resto spento (raggio negativo).
func _sedici(voci: Array[Vector4]) -> Array[Vector4]:
	var out: Array[Vector4] = []
	for k in 16:
		out.append(voci[k] if k < voci.size() else Vector4(0, 0, -1, 0))
	return out


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
			d["mappa"] = 6
			d["testo_mappa"] = "Mostra abitato e contado"
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
			# Specchietto dei rapporti di forza (decisione di Fede del 26/11/2026).
			d.merge(rapporti_di_forza(), true)
			d["serie"] = serie_di.call("legittimita", 1.0)
		"Legna":
			d["valore"] = str(floori(sim.legna))
			d["allarme"] = sim.legna < SimVillaggio.COSTO_CASA and sim.ultima_legna < sim.consumo_legna
			d["descrizione"] = "Si raccoglie nei boschi vicini e si ricava dissodando. Ogni casa nuova ne chiede %d, il granaio %d." % [roundi(SimVillaggio.COSTO_CASA), roundi(SimVillaggio.COSTO_GRANAIO)]
			d["parti"] = [["Raccolta / ciò che offrono i boschi", sim.ultima_legna / maxf(1.0, sim.offerta_legna), "%d / %d" % [roundi(sim.ultima_legna), roundi(sim.offerta_legna)]],
				["Bosco rimasto attorno", 1.0 - sim.disboscamento, "%d%%" % roundi((1.0 - sim.disboscamento) * 100.0)]]
			d["serie"] = serie_di.call("legna", 1.0)
			d["mappa"] = 5
			d["testo_mappa"] = "Mostra boschi, selvaggina e zone di taglio"
		"Animali":
			d["valore"] = str(roundi(sim.capi))
			d["allarme"] = sim.pascolo_eccessivo > 0.3
			d["descrizione"] = "Un solo numero di capi: pecore e capre soprattutto, maiali vicino al bosco, qualche bue. Crescono finché c'è erba nel pascolo."
			d["parti"] = [["Capi / portata del pascolo", sim.capi / maxf(1.0, sim.portata_capi), "%d / %d" % [roundi(sim.capi), roundi(sim.portata_capi)]],
				["Erba libera", sim.erba, "%d%%" % roundi(sim.erba * 100.0)]]
			d["serie"] = serie_di.call("capi", 1.0)
	return d


## Specchietto dei rapporti di forza (decisione di Fede del 26/11/2026): chi conta e di che umore è.
## Nel villaggio governano gli anziani, senza un nome di governo (quello arriva all'evento soglia 1).
const GRUPPI := {
	"anziani": {"nome": "Anziani", "parole": ["contenti", "tranquilli", "inquieti", "scontenti"], "vuole": "Gli anziani vogliono cibo da parte e il rispetto delle usanze."},
	"famiglie": {"nome": "Famiglie", "parole": ["contente", "tranquille", "inquiete", "scontente"], "vuole": "Le famiglie vogliono il raccolto, case per tutti e i loro animali."},
	"sacerdote": {"nome": "Sacerdote", "parole": ["contento", "tranquillo", "inquieto", "scontento"], "vuole": "Il sacerdote vuole il luogo sacro, un bosco sacro grande e i presagi ascoltati."},
}
## Come si dice a parole dove spinge ogni asse dell'identità: [verso −1, verso +1].
const PAROLE_IDENTITA := {
	"terra": ["terra in comune", "terra alle famiglie"],
	"apertura": ["più chiusa", "più aperta"],
	"decide": ["decidono in pochi", "decidono in molti"],
	"governo": ["ognuno per sé", "regole comuni"],
}


func rapporti_di_forza() -> Dictionary:
	var pesi := sim.pesi_consenso()
	var gruppi: Array = []
	for g in ["anziani", "famiglie", "sacerdote"]:
		if pesi[g] <= 0.0:
			continue
		var c: float = sim.consenso[g]
		var parole: Array = GRUPPI[g]["parole"]
		var a := sim.andamento_consenso(g)
		gruppi.append({"nome": GRUPPI[g]["nome"], "peso": pesi[g] / 0.5, "umore": c,
			"parola": parole[0 if c >= 70.0 else (1 if c >= 55.0 else (2 if c >= 40.0 else 3))],
			"freccia": "▲" if a > 3.0 else ("▼" if a < -3.0 else ""), "vuole": GRUPPI[g]["vuole"]})
	# Il perché di ogni gruppo al passaggio del puntatore: ciò che vuole e le cause di oggi.
	var cause := sim.cause_di("Consenso")
	for r in gruppi:
		var chiave := String(r["nome"]).to_lower()
		var sue: Array[String] = []
		for c in cause:
			if String(c).to_lower().contains(chiave) or (chiave == "famiglie" and String(c).to_lower().contains("famiglia")):
				sue.append("· " + String(c))
		r["vuole"] = String(r["vuole"]) + ("\n" + "\n".join(sue) if not sue.is_empty() else "")
	var te := sim.tensione()
	return {"valore": str(roundi(sim.legittimita)), "allarme": sim.legittimita < 30.0,
		"descrizione": "Governano gli anziani.", "gruppi": gruppi,
		"tensione": [te, "bassa" if te < 0.34 else ("media" if te < 0.67 else "alta")], "verso": verso_identita()}


## Dove spingono le usanze di oggi, a parole (al massimo due assi, i più netti).
func verso_identita() -> String:
	var assi: Array = []
	for k in sim.identita_verso:
		if absf(float(sim.identita_verso[k])) > 0.15:
			assi.append(k)
	assi.sort_custom(func(a: String, b: String) -> bool: return absf(float(sim.identita_verso[a])) > absf(float(sim.identita_verso[b])))
	var parole: Array[String] = []
	for k in assi.slice(0, 2):
		parole.append(PAROLE_IDENTITA[k][1 if float(sim.identita_verso[k]) > 0.0 else 0])
	return " · ".join(parole) if not parole.is_empty() else "nessuna direzione netta"


## Apre o chiude lo specchietto dei rapporti di forza (tasto R).
func apri_rapporti() -> void:
	var hud: Hud = scena.hud
	if hud.focus_aperto() == "Consenso":
		hud.chiudi_focus()
	elif sim.fondato:
		hud.mostra_focus(dati_focus("Consenso"))


## Specchietto "Conseguenze" (decisione di Fede del 26/11/2026): per lo strumento scelto e il
## punto sotto il puntatore, chi ci guadagna, chi ci perde, cosa cambia sulla terra, quanto costa e
## cosa resta. Le stime vengono dalle stesse regole della simulazione; una riga per voce.
func aggiorna_conseguenze() -> void:
	var hud: Hud = scena.hud
	var cmd := hud.comando()
	var punto = scena.get("punto_corrente")
	if punto == null or not sim.fondato or sim.finito or cmd == "" or cmd == "fonda":
		_chiave_conseguenze = []
		hud.imposta_conseguenze({})
		return
	var q: Vector3 = punto
	var raggio := raggio_strumento(cmd, float(scena.get("raggio_pennello")))
	var chiave := [cmd, Vector2i(roundi(q.x / 10.0), roundi(q.z / 10.0)), raggio, sim.anno, togli_zona, togli_pascolo,
		hud.focus_aperto(), hud.politiche_aperte(), hud.modale_aperta(), roundi(sim.legna)]
	if chiave == _chiave_conseguenze:
		return
	_chiave_conseguenze = chiave
	hud.imposta_conseguenze(conseguenze(cmd, Vector2(q.x, q.z), raggio))


func _ettari_testo(ha: float) -> String:
	return "%s ha" % String.num(ha, 1).replace(".", ",")


func conseguenze(cmd: String, punto: Vector2, raggio: float) -> Dictionary:
	var p := sim.px_da_mondo(punto.x, punto.y)
	var i := sim.px(p)
	var bosco := sim.bosco_presente.call(i) as bool
	var fl := sim.piena(i)
	var ha := PI * raggio * raggio / 10000.0
	var nessuno := "nessuno"
	var poca_legna := func(costo: float) -> bool: return sim.legna - costo < SimVillaggio.COSTO_CASA * 3.0
	match cmd:
		"zona", "campi":
			var nome := "Zona agricola" if cmd == "zona" else "Campo"
			if cmd == "zona" and togli_zona:
				return {"titolo": "Togli zona agricola · " + _ettari_testo(ha), "guadagna": nessuno, "perde": nessuno,
					"territorio": "la terra torna prato; i campi restano", "costo": "nessuno", "resta": "i campi già dissodati"}
			if not sim.edificabile(i):
				return {"titolo": nome, "guadagna": nessuno, "perde": nessuno, "territorio": "acqua o palude: qui non si coltiva"}
			var terra := "si taglia il bosco: legna, meno selvaggina" if bosco else ("nuovi campi quando servono" if cmd == "zona" else "campi nuovi subito")
			if fl > 0.25:
				terra += " · il fiume può allagarli"
			return {"titolo": "%s · %s" % [nome, _ettari_testo(ha)], "guadagna": "Famiglie ▲ · Anziani ▲  (più raccolto)", "perde": nessuno,
				"territorio": terra, "costo": "gratis; dissodare chiede braccia" if cmd == "zona" else "braccia, subito",
				"resta": "campi che, lasciati, tornano bosco"}
		"pascolo":
			if togli_pascolo:
				return {"titolo": "Togli pascolo · " + _ettari_testo(ha), "guadagna": nessuno, "perde": nessuno,
					"territorio": "il bosco potrà ricrescere; gli animali restano", "costo": "nessuno", "resta": "radure ancora aperte"}
			var alle_famiglie := sim.politica("raccolto") == "famiglie"
			var terra_pa := "il bosco qui non ricresce" if bosco else "erba per gli animali"
			if sim._pendio(i):
				terra_pa += " · pendio: troppi animali erodono"
			return {"titolo": "Pascolo · " + _ettari_testo(ha),
				"guadagna": "Famiglie ▲▲  (animali loro: più disuguaglianza)" if alle_famiglie else "Famiglie ▲  (animali, scorta per gli anni cattivi)",
				"perde": nessuno, "territorio": terra_pa, "costo": "gratis", "resta": "radure aperte, terra concimata"}
		"sentiero":
			return {"titolo": "Sentiero", "guadagna": "Famiglie ▲  (i campi lungo la via rendono di più)", "perde": nessuno,
				"territorio": "una via battuta nel contado", "costo": "braccia", "resta": "i più battuti diventeranno strade"}
		"granaio":
			var c := SimVillaggio.COSTO_GRANAIO
			return {"titolo": "Granaio", "guadagna": "Anziani ▲  (le scorte non si guastano)",
				"perde": "Famiglie ▼  (meno legna per le case)" if poca_legna.call(c) else nessuno,
				"territorio": "vicino al centro, dove arriva il raccolto" if fl <= 0.25 else "attento: qui il fiume può arrivare",
				"costo": "%d di legna · %d anni di lavoro%s" % [roundi(c), SimVillaggio.ANNI_CANTIERE_GRANAIO, "" if sim.legna >= c else " (ne hai %d)" % floori(sim.legna)],
				"resta": "il primo edificio comune"}
		"legnaia":
			var k := sim.legnaia_vicina(punto)
			if k >= 0:
				if bool(sim.legnaie[k]["riposo"]):
					return {"titolo": "Rimetti al lavoro la legnaia", "guadagna": "Famiglie ▲  (di nuovo legna)", "perde": nessuno,
						"territorio": "si torna a tagliare il bosco attorno", "costo": "braccia", "resta": "la radura si riapre"}
				return {"titolo": "Lascia ricrescere il bosco", "guadagna": nessuno, "perde": "Famiglie ▼  (meno legna)",
					"territorio": "il bosco ricaccia dalle ceppaie", "costo": "nessuno", "resta": "un ceduo, di nuovo utile tra decenni"}
			return {"titolo": "Legnaia", "guadagna": "Famiglie ▲  (legna per case e focolari)", "perde": nessuno,
				"territorio": "il bosco arretra: meno selvaggina, piene più rapide", "costo": "braccia · %d anni di lavoro" % SimVillaggio.ANNI_CANTIERE_LEGNAIA,
				"resta": "una radura, poi un ceduo"}
		"capanno", "posta":
			var caccia := cmd == "posta"
			var elenco: Array = sim.poste if caccia else sim.capanni
			var raggio_r := SimVillaggio.RAGGIO_POSTA if caccia else SimVillaggio.RAGGIO_CAPANNO
			var vicini := 0
			for e in elenco:
				if (e["punto"] as Vector2).distance_to(punto) < raggio_r:
					vicini += 1
			var perde_r := nessuno
			if vicini > 0:
				perde_r = ("%d %s ▼  (stessa selvaggina)" % [vicini, "posta vicina" if vicini == 1 else "poste vicine"]) if caccia else ("%d %s ▼  (stesso pesce)" % [vicini, "capanno vicino" if vicini == 1 else "capanni vicini"])
			return {"titolo": "Posta di caccia" if caccia else "Capanno da pesca",
				"guadagna": "Famiglie ▲  (più selvaggina)" if caccia else "Famiglie ▲  (più pesce)", "perde": perde_r,
				"territorio": "la selvaggina di questo bosco" if caccia else "il pesce di questo tratto di fiume",
				"costo": "braccia · %d anni di lavoro" % SimVillaggio.ANNI_CANTIERE_RISORSE,
				"resta": "un posto di caccia al margine del bosco" if caccia else "il primo approdo sul fiume"}
		"luogo_sacro":
			var c_s := SimVillaggio.COSTO_LUOGO_SACRO
			return {"titolo": "Luogo sacro", "guadagna": "Sacerdote ▲▲  (lo chiede)",
				"perde": "Famiglie ▼  (meno legna per le case)" if poca_legna.call(c_s) else nessuno,
				"territorio": "le case gli crescono attorno",
				"costo": "%d di legna · %d anni di lavoro%s" % [roundi(c_s), SimVillaggio.ANNI_CANTIERE_LUOGO_SACRO, "" if sim.legna >= c_s else " (ne hai %d)" % floori(sim.legna)],
				"resta": "il centro sacro: poi tempio e piazza"}
		"bosco_sacro":
			if not bosco:
				return {"titolo": "Bosco sacro", "guadagna": nessuno, "perde": nessuno, "territorio": "qui non c'è bosco da proteggere"}
			var vicino_legnaie := false
			for l in sim.legnaie:
				if (l["punto"] as Vector2).distance_to(punto) < SimVillaggio.RAGGIO_LEGNAIA:
					vicino_legnaie = true
			var pieno := sim.ettari_bosco_sacro() >= SimVillaggio.ETTARI_BOSCO_SACRO
			return {"titolo": "Bosco sacro · " + _ettari_testo(ha), "guadagna": "Sacerdote ▲" if pieno else "Sacerdote ▲▲  (lo vuole grande)",
				"perde": "Famiglie ▼  (legna più lontana)" if vicino_legnaie else nessuno,
				"territorio": "bosco protetto · legnaie più lontane", "costo": "nessuno", "resta": "nessuno potrà tagliarlo"}
		"demolisci":
			return _conseguenze_demolizione(punto, raggio)
	return {}


func _conseguenze_demolizione(punto: Vector2, raggio: float) -> Dictionary:
	var n_case := 0
	for c in sim.case:
		if sim.centro_lotto(c).distance_to(punto) <= raggio:
			n_case += 1
	var n_campi := 0
	for i in sim.campi:
		if sim.mondo_di_px(sim.px_di(i)).distance_to(punto) <= raggio:
			n_campi += 1
	var n_sacri := 0
	for i in sim.bosco_sacro:
		if sim.mondo_di_px(sim.px_di(i)).distance_to(punto) <= raggio and sim.bosco_in_piedi(i):
			n_sacri += 1
	var luogo := sim.luogo_sacro.x >= 0 and sim.luogo_sacro.distance_to(punto) <= raggio
	var granaio := sim.granaio.x >= 0 and sim.granaio.distance_to(punto) <= raggio
	var perde: Array[String] = []
	var cose: Array[String] = []
	if n_case > 0 or n_campi > 0:
		perde.append("Famiglie %s" % ("▼▼" if n_case > 0 else "▼"))
	if n_case > 0:
		cose.append("%d %s" % [n_case, "casa" if n_case == 1 else "case"])
	if n_campi > 0:
		cose.append("%d %s" % [n_campi, "campo" if n_campi == 1 else "campi"])
	if luogo or n_sacri > 0:
		perde.append("Sacerdote %s" % ("▼▼▼" if luogo else "▼▼"))
		cose.append("il luogo sacro" if luogo else "bosco sacro")
	if granaio:
		perde.append("Anziani ▼")
		cose.append("il granaio")
	if cose.is_empty():
		return {"titolo": "Demolisci", "guadagna": "nessuno", "perde": "nessuno", "territorio": "alberi e sentieri nel cerchio, se ci sono",
			"costo": "irreversibile", "irreversibile": true, "resta": "terra libera: il bosco può ricrescere"}
	return {"titolo": "Demolisci", "guadagna": "nessuno", "perde": " · ".join(perde),
		"territorio": "si toglie: " + ", ".join(cose), "costo": "irreversibile", "irreversibile": true,
		"resta": ("macerie: niente case per %d anni" % SimVillaggio.ANNI_MACERIE) if n_case > 0 else "terra libera: il bosco può ricrescere"}


## Lettura del terreno per gli strumenti della partita (decisione di Fede del 25/11/2026): le voci
## che contano per ognuno, come in fondazione.
func leggi_per_strumento(punto: Vector3) -> void:
	var hud: Hud = scena.hud
	var cmd := hud.comando()
	if not sim.fondato or not cmd in ["zona", "campi", "granaio", "legnaia", "sentiero", "capanno", "posta", "luogo_sacro", "bosco_sacro", "pascolo"]:
		hud.imposta_lettura_strumento([])
		return
	if cmd in ["capanno", "posta"]:
		hud.imposta_lettura_strumento(_lettura_edificio_risorse(cmd, Vector2(punto.x, punto.z)))
		return
	if cmd == "pascolo":
		var q := sim.px_da_mondo(punto.x, punto.z)
		var iq := sim.px(q)
		var terra := "campo a maggese" if sim.maggese.has(iq) else ("campo (stoppie)" if sim.campi.has(iq) else ("bosco" if sim.bosco_in_piedi(iq) else "prato"))
		var capi_ha: float = {"campo a maggese": SimVillaggio.CAPI_HA_MAGGESE, "campo (stoppie)": SimVillaggio.CAPI_HA_STOPPIE, "bosco": SimVillaggio.CAPI_HA_BOSCO, "prato": SimVillaggio.CAPI_HA_PRATO}[terra]
		var motivo_pa := sim.motivo_pascolo(q)
		var voci_pa: Array = [["Terra", terra if motivo_pa == "" else motivo_pa, capi_ha / SimVillaggio.CAPI_HA_MAGGESE, motivo_pa != ""],
			["Erba", "%s capi per ettaro" % String.num(capi_ha, 1).replace(".", ","), capi_ha / SimVillaggio.CAPI_HA_MAGGESE, false],
			["Mandria", "%d capi su %d" % [roundi(sim.capi), roundi(sim.portata_capi)], sim.erba, sim.erba < 0.05]]
		if sim._pendio(iq):
			voci_pa.append(["Pendio", "sì: troppi animali erodono", 0.3, true])
		hud.imposta_lettura_strumento(voci_pa)
		return
	if cmd == "bosco_sacro":
		var q := sim.px_da_mondo(punto.x, punto.z)
		var bosco := sim.bosco_in_piedi(sim.px(q))
		var ha := sim.ettari_bosco_sacro()
		var dist := Vector2(punto.x, punto.z).distance_to(sim.mondo_di_px(sim.centro))
		hud.imposta_lettura_strumento([["Bosco", "sacro" if sim.bosco_sacro.has(sim.px(q)) else ("sì" if bosco else "nessuno"), 1.0 if bosco else 0.0, not bosco],
			["Bosco sacro", "%s ha su %d" % [String.num(ha, 1).replace(".", ","), roundi(SimVillaggio.ETTARI_BOSCO_SACRO)], clampf(ha / SimVillaggio.ETTARI_BOSCO_SACRO, 0.0, 1.0), ha < SimVillaggio.ETTARI_BOSCO_SACRO * 0.5],
			["Distanza dal centro", "%d m" % roundi(dist), 1.0 - clampf(dist / SimVillaggio.DISTANZA_BOSCO_SACRO, 0.0, 1.0), dist > SimVillaggio.DISTANZA_BOSCO_SACRO]])
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
			var k := sim.legnaia_vicina(Vector2(punto.x, punto.z))
			if k >= 0:
				var l: Dictionary = sim.legnaie[k]
				hud.imposta_lettura_strumento([["Legnaia", sim.stato_legnaia(l), 1.0 if sim.legnaia_attiva(l) else 0.3, false],
					["Raccolta", "%.0f l'anno" % sim.capacita_legnaia(l), sim.capacita_legnaia(l) / SimVillaggio.CAPACITA_LEGNAIA, sim.capacita_legnaia(l) < SimVillaggio.CAPACITA_LEGNAIA * 0.3],
					["Clic", "rimetti al lavoro" if bool(l["riposo"]) else "lascia ricrescere", 0.0, false]])
				return
			var b := sim.bosco_per_legnaia(Vector2(punto.x, punto.z))
			var vicino: float = b["vicino"]
			var eff := clampf(1.0 - vicino / SimVillaggio.RAGGIO_LEGNAIA, 0.0, 1.0) if vicino >= 0.0 else 0.0
			voci.append(["Bosco vicino", ("a %d m" % roundi(vicino)) if vicino >= 0.0 else "nessuno", eff, eff < 0.4])
			voci.append(["Bosco attorno", "%d%%" % roundi(float(b["quota"]) * 100.0), float(b["quota"]), float(b["quota"]) < 0.15])
			voci.append(["Distanza dal centro", "%d m" % roundi(d), 1.0 - clampf(d / SimVillaggio.DISTANZA_MASSIMA_LEGNAIA, 0.0, 1.0), d > SimVillaggio.DISTANZA_MASSIMA_LEGNAIA])
			voci.append(piena_voce)
		"luogo_sacro":
			voci.append(["Distanza dal centro", "%d m" % roundi(d), 1.0 - clampf(d / SimVillaggio.DISTANZA_LUOGO_SACRO, 0.0, 1.0), d > SimVillaggio.DISTANZA_LUOGO_SACRO])
			voci.append(["Legna", "%d / %d" % [floori(sim.legna), roundi(SimVillaggio.COSTO_LUOGO_SACRO)], sim.legna / SimVillaggio.COSTO_LUOGO_SACRO, sim.legna < SimVillaggio.COSTO_LUOGO_SACRO])
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


## Dove andrebbe un capanno o una posta con il puntatore qui (l'ultimo calcolo si ricorda: lo
## chiedono sia il cerchio dello strumento sia la lettura).
var _ultima_posa := {}

func posa_edificio(cmd: String, punto: Vector2) -> Dictionary:
	var chiave := [cmd, Vector2i(punto.round()), sim.anno, sim.poste.size(), sim.capanni.size()]
	if _ultima_posa.get("chiave", []) == chiave:
		return _ultima_posa["posa"]
	var posa := sim.posa_capanno(punto) if cmd == "capanno" else sim.posa_posta(punto)
	_ultima_posa = {"chiave": chiave, "posa": posa}
	return posa


## Lettura sotto il puntatore per Capanno e Posta: sopra un edificio che c'è già, il suo stato;
## altrimenti cosa troverebbe nel punto dove si aggancerebbe.
func _lettura_edificio_risorse(cmd: String, punto: Vector2) -> Array:
	var caccia := cmd == "posta"
	var elenco: Array = sim.poste if caccia else sim.capanni
	var capacita := SimVillaggio.CAPACITA_POSTA if caccia else SimVillaggio.CAPACITA_CAPANNO
	var k := sim.edificio_vicino(elenco, punto, 20.0)
	if k >= 0:
		var e: Dictionary = elenco[k]
		var scorta := sim.scorta_attorno(e)
		return [[("Posta di caccia" if caccia else "Capanno da pesca"), sim.stato_edificio(e), 1.0 if int(e["cantiere"]) <= 0 else 0.3, false],
			["Selvaggina attorno" if caccia else "Pesce del tratto", "%d%%" % roundi(scorta * 100.0), scorta, scorta < 0.4],
			["Resa", "%d / %d l'anno" % [roundi(float(e["preso"])), roundi(float(e["offerta"]))], float(e["offerta"]) / capacita, false]]
	var posa := posa_edificio(cmd, punto)
	if posa["motivo"] != "":
		return [["Riva" if not caccia else "Margine del bosco", posa["motivo"], 0.0, true]]
	var prova := {"punto": posa["punto"], "cantiere": 0}
	if not caccia:
		prova["acqua"] = posa["acqua"]
	var stima := sim.stima_edificio(prova)
	var voci: Array = []
	if caccia:
		voci.append(["Bosco attorno", "fitto" if stima["risorsa"] > 0.6 else ("rado" if stima["risorsa"] > 0.3 else "poco"), stima["risorsa"], stima["risorsa"] <= 0.3])
		voci.append(["Selvaggina", "%d%%" % roundi(stima["scorta"] * 100.0), stima["scorta"], stima["scorta"] < 0.4])
	else:
		voci.append(["Acqua", "fiume" if posa["acqua"] == "fiume" else "torrente", 1.0 if posa["acqua"] == "fiume" else 0.4, false])
		voci.append(["Pesce del tratto", "%d%%" % roundi(stima["scorta"] * 100.0), stima["scorta"], stima["scorta"] < 0.4])
	voci.append(["Resa stimata", "%d l'anno" % roundi(stima["resa"]), stima["resa"] / capacita, stima["resa"] < capacita * 0.3])
	if stima["vicini"] > 0:
		voci.append(["Vicini", ("%d poste" if caccia else "%d capanni") % stima["vicini"] if stima["vicini"] > 1 else ("una posta" if caccia else "un capanno"), 0.5, false])
	var d := (posa["punto"] as Vector2).distance_to(sim.mondo_di_px(sim.centro))
	voci.append(["Distanza dal centro", "%d m" % roundi(d), 1.0 - clampf(d / SimVillaggio.DISTANZA_MASSIMA_RISORSE, 0.0, 1.0), d > SimVillaggio.DISTANZA_MASSIMA_RISORSE])
	return voci


## Gli alberi abbattuti dalle legnaie spariscono dalla mappa (decisione di Fede del 25/11/2026: il
## taglio si deve vedere) e ricacciano dalle ceppaie; finché la legnaia lavora, la sua zona di taglio
## non ricresce. Quando va a riposo, la ricrescita riparte.
var _zona_bloccata := {}


func _celle_del_pixel(i: int) -> Array[Vector2i]:
	var uso: UsoSuolo = scena.uso
	var celle: Array[Vector2i] = []
	var mezzo := sim.dati.metri_per_px * 0.5
	var w := sim.mondo_di_px(sim.px_di(i))
	var a := uso.cella(w.x - mezzo + 1.0, w.y - mezzo + 1.0)
	var b := uso.cella(w.x + mezzo - 1.0, w.y + mezzo - 1.0)
	for y in range(a.y, b.y + 1):
		for x in range(a.x, b.x + 1):
			celle.append(Vector2i(x, y))
	return celle


func _abbatti_tagli() -> void:
	var uso: UsoSuolo = scena.uso
	if not sim.tagli_anno.is_empty():
		var celle: Array[Vector2i] = []
		for i in sim.tagli_anno:
			celle.append_array(_celle_del_pixel(i))
		uso.abbatti_ceduo(celle)
		sim.tagli_anno = []
	# Zone di taglio: si bloccano le celle entrate, si sbloccano quelle uscite.
	var entrate: Array[Vector2i] = []
	var uscite: Array[Vector2i] = []
	# Anche il pascolo tiene aperte le radure (decisione di Fede del 25/11/2026).
	var bloccate := sim.zona_attiva.duplicate()
	bloccate.merge(sim.pascolo)
	for i in bloccate:
		if not _zona_bloccata.has(i):
			entrate.append_array(_celle_del_pixel(i))
	for i in _zona_bloccata.keys():
		if not bloccate.has(i):
			uscite.append_array(_celle_del_pixel(i))
	if not entrate.is_empty():
		uso.blocca_ricrescita(entrate, true)
	if not uscite.is_empty():
		uso.blocca_ricrescita(uscite, false)
	_zona_bloccata = bloccate


# ---------- scheda della famiglia (decisione di Fede del 26/11/2026) ----------
# Una casa è una famiglia. Un clic su una persona o su una casa apre la scheda nel pannello di
# focus: dove abita e da quando, il lavoro dei suoi membri, cosa ha, l'umore delle famiglie e cosa
# vorrebbe, che dipende da dove sta la casa. Legge solo dati che la simulazione ha già: non cambia
# le dinamiche. Il nome viene dal luogo, come per le genti (Fede: "accordato").

const NESSUNA_CASA := Vector2i(-99999, -99999)
## Righe della scheda: al massimo questi caratteri (come le Conseguenze: niente muri di testo).
const MASSIMO_RIGA_FAMIGLIA := 52
const LAVORI_FAMIGLIA := {
	"contadino": "zappa", "raccoglitrice": "raccoglie nei campi", "boscaiolo": "taglia legna",
	"pescatore": "pesca", "cacciatore": "caccia nel bosco", "pastore": "porta il gregge",
	"costruttore": "lavora al cantiere", "sacro": "al luogo sacro", "casa": "a casa",
}
## Nomi comuni delle famiglie, da ciò che c'è attorno a una casa del Neolitico (proposta di Claude).
const NOMI_COMUNI := ["dell'aia", "dell'orto", "del noce", "del corniolo", "della siepe", "del sambuco",
	"del masso", "del recinto", "del prugnolo", "della quercia grande", "del biancospino", "del melo selvatico"]
var famiglia := NESSUNA_CASA
var _titolo_famiglia := ""
var _nomi_famiglie := {}
var _chiave_nomi := ""


## Clic sulla mappa senza strumenti: una persona (la più vicina sotto il puntatore) o una casa
## aprono la scheda della famiglia; un clic altrove la chiude.
func clic_sulla_mappa(pos_schermo: Vector2, lotto: Vector2i) -> void:
	if not sim.fondato:
		return
	var l := NESSUNA_CASA
	var f: Dictionary = vista.persone.figura_sotto(scena.cam.camera, pos_schermo)
	if not f.is_empty() and sim.case.has(f["lotto"]):
		l = f["lotto"]
	elif sim.case.has(lotto):
		l = lotto
	if l == NESSUNA_CASA:
		if famiglia != NESSUNA_CASA:
			scena.hud.chiudi_focus()
			_evidenzia_famiglia(NESSUNA_CASA)
		return
	apri_famiglia(l)


func apri_famiglia(l: Vector2i) -> void:
	var d := dati_famiglia(l)
	_titolo_famiglia = String(d["titolo"])
	scena.hud.mostra_focus(d)
	_evidenzia_famiglia(l)


func _evidenzia_famiglia(l: Vector2i) -> void:
	famiglia = l
	vista.persone.evidenziata = l
	scena.terreno.materiale.set_shader_parameter("lotto_famiglia", Vector2(l))


## Tiene la scheda aggiornata mentre il tempo scorre; la chiude se la casa non c'è più.
func _aggiorna_famiglia() -> void:
	var hud: Hud = scena.hud
	if famiglia == NESSUNA_CASA:
		return
	if hud.focus_aperto() != _titolo_famiglia or not sim.case.has(famiglia):
		if hud.focus_aperto() == _titolo_famiglia:
			hud.chiudi_focus()
		_evidenzia_famiglia(NESSUNA_CASA)
		return
	var d := dati_famiglia(famiglia)
	if String(d["titolo"]) != _titolo_famiglia:
		_titolo_famiglia = String(d["titolo"])
		hud.mostra_focus(d)
	else:
		hud.aggiorna_focus(d)


static func _direzione(v: Vector2) -> String:
	if v.length() < 1.0:
		return ""
	# x verso est, z verso sud.
	var k := wrapi(roundi(atan2(v.x, -v.y) / (PI / 4.0)), 0, 8)
	return ["a nord", "a nord-est", "a est", "a sud-est", "a sud", "a sud-ovest", "a ovest", "a nord-ovest"][k]


## Dove sta una casa: "nel paese" o "nel casale a nord".
func _dove_casa(l: Vector2i) -> String:
	if sim.case_casale.has(l):
		var c: Vector2i = sim.casali[int(sim.case_casale[l])] if int(sim.case_casale[l]) < sim.casali.size() else l
		return "nel casale " + _direzione(sim.centro_lotto(c) - sim.mondo_di_px(sim.centro))
	return "nel paese"


## L'acqua più vicina attorno al punto (entro tre pixel della mappa): il suo tipo, o -1.
func _acqua_vicina(w: Vector2) -> int:
	var p := sim.px_da_mondo(w.x, w.y)
	var meglio := 1e9
	var tipo := -1
	for dy in range(-3, 4):
		for dx in range(-3, 4):
			var q := p + Vector2i(dx, dy)
			if q.x < 0 or q.y < 0 or q.x >= sim.n or q.y >= sim.n:
				continue
			var t: int = sim.dati.tipo[sim.px(q)]
			if t in [MappaDati.FIUME, MappaDati.TORRENTE, MappaDati.TORRENTE_EST, MappaDati.PALUDE]:
				var d := Vector2(dx, dy).length()
				if d < meglio:
					meglio = d
					tipo = t
	return tipo


## I nomi possibili di una famiglia, dal luogo della sua casa, dal più caratteristico.
func _nomi_possibili(l: Vector2i) -> Array:
	var w := sim.centro_lotto(l)
	var c := sim.mondo_di_px(sim.centro)
	var out: Array = []
	if sim.luogo_sacro.x >= 0 and w.distance_to(sim.luogo_sacro) < 60.0:
		out.append("della pietra")
	if w.distance_to(c) < 45.0:
		out.append("del focolare")
	if sim.granaio.x >= 0 and w.distance_to(sim.granaio) < 50.0:
		out.append("del granaio")
	var riva := sim.dati.distanza_riva(w.x, w.y)
	var acqua := _acqua_vicina(w)
	if acqua == MappaDati.PALUDE:
		out.append_array(["della palude", "delle canne"])
	elif riva < 90.0 and acqua == MappaDati.FIUME:
		out.append_array(["del fiume", "della riva", "del guado"])
	elif riva < 90.0 and acqua >= 0:
		out.append_array(["del torrente", "del guado", "della riva"])
	var bosco := 0.0
	for k in 8:
		var q := w + Vector2.from_angle(k * TAU / 8.0) * 60.0
		bosco = maxf(bosco, sim.dati.bosco_in(q.x, q.y))
	if bosco > 0.45:
		out.append_array(["dei pioppi", "dei salici"] if riva < 150.0 else ["del bosco", "delle querce"])
	if sim.dati.quota(w.x, w.y) - sim.dati.quota(c.x, c.y) > 12.0:
		out.append_array(["del colle", "del poggio"])
	if sim.dati.tipo[sim.px(sim.px_da_mondo(w.x, w.y))] == MappaDati.GESSI:
		out.append("dei gessi")
	if sim.case_casale.has(l):
		out.append("del casale " + _direzione(w - c))
	var p := sim.px_da_mondo(w.x, w.y)
	for s in sim.sentieri:
		if Vector2(sim.px_di(s) - p).length() <= 1.0:
			out.append("del sentiero")
			break
	# Nomi comuni da un campo di casa (un albero, l'aia, un masso), diversi da casa a casa.
	var comuni: Array = NOMI_COMUNI.duplicate()
	var k := int(VistaVillaggio._caso(l, 7) * comuni.size())
	for j in comuni.size():
		out.append(comuni[(k + j) % comuni.size()])
	var dir := _direzione(w - c)
	for j in comuni.size():
		out.append(String(comuni[(k + j) % comuni.size()]) + " " + dir)
	return out


## Un nome per ogni casa, senza doppioni: le case più vecchie scelgono per prime.
func nomi_famiglie() -> Dictionary:
	var chiave := str(sim.case.size()) + ":" + str(sim.case.hash())
	if chiave == _chiave_nomi:
		return _nomi_famiglie
	var ordine: Array = sim.case.duplicate()
	ordine.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var na := int(sim.nascita_case.get(a, sim.anno))
		var nb := int(sim.nascita_case.get(b, sim.anno))
		return na < nb if na != nb else (a.x < b.x if a.x != b.x else a.y < b.y))
	var usati := {}
	var nomi := {}
	for l in ordine:
		var possibili := _nomi_possibili(l)
		var scelto := ""
		for nome in possibili:
			if not usati.has(nome):
				scelto = nome
				break
		if scelto == "":
			var base: String = possibili[0]
			var dir := _direzione(sim.centro_lotto(l) - sim.mondo_di_px(sim.centro))
			scelto = base + " " + dir if not base.contains(dir) else base
			var k := 2
			while usati.has(scelto):
				scelto = "%s, %s" % [base, ["seconda", "terza", "quarta", "quinta"][mini(k - 2, 3)] if k <= 5 else str(k)]
				k += 1
		usati[scelto] = true
		nomi[l] = scelto
	_nomi_famiglie = nomi
	_chiave_nomi = chiave
	return nomi


## Cosa vorrebbe la famiglia, dal luogo della casa e dallo stato del villaggio: [testo, perché].
func _desiderio(l: Vector2i) -> Array:
	var w := sim.centro_lotto(l)
	var i := sim.px(sim.px_da_mondo(w.x, w.y))
	if sim.piena(i) > 0.5:
		return ["stare al riparo dalle piene", "La casa sta dove il fiume arriva nelle piene grandi."]
	if sim.abbondanza < SimVillaggio.SOGLIA_CRESCITA:
		return ["più cibo da parte", "Il villaggio ha poco da parte: si mangia, ma non avanza."]
	var vicina := INF
	for g in sim.legnaie:
		if sim.legnaia_attiva(g):
			vicina = minf(vicina, w.distance_to(g["punto"]))
	if vicina == INF:
		return ["una legnaia che lavori", "Nessuna legnaia lavora: la legna si raccoglie dove capita."]
	if vicina > 500.0:
		return ["legna più vicina", "La legnaia più vicina è a %d m dalla casa." % roundi(vicina)]
	if sim.affollamento > 0.15:
		return ["più spazio: si sta stretti", "Manca una casa per il %d%% delle famiglie." % roundi(sim.affollamento * 100.0)]
	var vicini := 0
	var stanchi := 0
	for c in sim.campi:
		if sim.mondo_di_px(sim.px_di(c)).distance_to(w) < 300.0:
			vicini += 1
			if sim.fattore_stanchezza(c) < 0.9:
				stanchi += 1
	if vicini > 0 and stanchi > vicini * 0.4:
		return ["terra nuova da coltivare", "%d dei %d campi vicini alla casa sono stanchi." % [stanchi, vicini]]
	if sim.case_casale.has(l):
		var sentiero := false
		var p := sim.px_da_mondo(w.x, w.y)
		for s in sim.sentieri:
			if Vector2(sim.px_di(s) - p).length() <= 3.0:
				sentiero = true
				break
		if not sentiero:
			return ["un sentiero verso il paese", "Dal casale al paese non c'è un sentiero."]
	if sim.sacerdote_attivo and not sim.luogo_sacro_pronto():
		return ["un luogo sacro", "Il sacerdote chiede un luogo sacro, e le famiglie lo ascoltano."]
	return ["un buon raccolto", "Per ora non manca niente di importante."]


func dati_famiglia(l: Vector2i) -> Dictionary:
	var nome: String = nomi_famiglie().get(l, "del prato")
	var w := sim.centro_lotto(l)
	var modello := VistaVillaggio.modello_casa(l)
	var dove := ("Casa lunga " if modello.begins_with("casa") else "Capanna tonda ") + _dove_casa(l)
	var nata := int(sim.nascita_case.get(l, sim.anno))
	var da := ("arrivati da fuori nel " + SimVillaggio.anno_testo(int(sim.case_straniere[l]))) if sim.case_straniere.has(l) else "dal " + SimVillaggio.anno_testo(nata)
	var righe: Array = []
	var descrizione := dove + " · " + da
	if descrizione.length() > MASSIMO_RIGA_FAMIGLIA:
		descrizione = dove
		righe.append(["Origine", da, "Accolti dal villaggio: costruirono questa casa." if sim.case_straniere.has(l) else "L'anno in cui la famiglia ha costruito la casa."])
	# Il lavoro: dai membri visibili della famiglia.
	var membri: Array = vista.persone.membri(l)
	var lavori: Array[String] = []
	var campi_dir: Array[String] = []
	for f in membri:
		var cosa: String = LAVORI_FAMIGLIA.get(f["mestiere"], "a casa")
		if f["mestiere"] == "contadino" and f["luogo"] != Vector2.INF:
			var dir := _direzione((f["luogo"] as Vector2) - w)
			if not campi_dir.has(dir):
				campi_dir.append(dir)
			continue
		elif f["mestiere"] == "pescatore":
			cosa = "pesca al fiume" if _acqua_vicina(f["luogo"]) == MappaDati.FIUME else "pesca al torrente"
		if not lavori.has(cosa):
			lavori.append(cosa)
	if not campi_dir.is_empty():
		lavori.push_front("zappa " + " e ".join(campi_dir.slice(0, 2)))
	var lavoro := ""
	for cosa in lavori:
		var prova := cosa if lavoro == "" else lavoro + " · " + cosa
		if prova.length() <= MASSIMO_RIGA_FAMIGLIA - 12:
			lavoro = prova
	if lavoro == "":
		lavoro = "nei campi e attorno alle case"
	var quanti := maxi(1, roundi(sim.pop / maxf(1.0, sim.case.size())))
	var spiega_lavoro := "Si vedono %d membri della famiglia." % membri.size() if not membri.is_empty() else "Oggi nessuno della famiglia è in vista."
	if vista.persone.quota > 1:
		spiega_lavoro += " Ogni figura vale %d persone." % vista.persone.quota
	righe.append(["Lavoro", lavoro, spiega_lavoro])
	# Cosa ha: gli animali (se sono delle famiglie) e il raccolto.
	var ha: Array[String] = []
	var alle_famiglie := sim.politica("raccolto") == "famiglie"
	if sim.sbloccato("pascolo") and sim.capi >= 1.0:
		ha.append("%d capi" % maxi(1, roundi(sim.capi / maxf(1.0, sim.case.size()))) if alle_famiglie else "animali in comune")
	ha.append("il suo raccolto" if alle_famiglie else "raccolto in comune")
	righe.append(["Ha", " · ".join(ha), "Con il raccolto alle famiglie ognuna tiene il suo, e gli animali sono suoi." if alle_famiglie else "Il raccolto e gli animali sono di tutto il villaggio."])
	var desiderio := _desiderio(l)
	righe.append(["Vorrebbe", desiderio[0], desiderio[1]])
	# L'umore della famiglia (decisione di Fede del 26/11/2026): il consenso delle famiglie più ciò che
	# vive questa casa; i motivi a parole al passaggio del puntatore.
	var umore: Array = sim.umore_famiglie().get(l, [float(sim.consenso["famiglie"]), []])
	var c: float = umore[0]
	var parole: Array = GRUPPI["famiglie"]["parole"]
	var parola: String = parole[0 if c >= 70.0 else (1 if c >= 55.0 else (2 if c >= 40.0 else 3))]
	var motivi: Array = umore[1]
	var perche := "Come tutte le famiglie del villaggio." if motivi.is_empty() else "Come le altre famiglie, e in più:\n· " + "\n· ".join(motivi)
	return {"titolo": "Famiglia " + nome, "valore": "%d persone" % quanti if quanti != 1 else "1 persona",
		"descrizione": descrizione, "famiglia": righe, "umore": [c, parola.trim_suffix("e") + "a" if parola.ends_with("e") else parola, perche],
		"punto": w}
