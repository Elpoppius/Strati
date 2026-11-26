class_name Tutorial
extends RefCounted
## Tutorial alle tappe (decisione di Fede del 26/11/2026): quando la partita sblocca qualcosa
## (la fondazione, una tappa, una costruzione, una regola) il gioco si ferma e un riquadro spiega
## la novità in due o tre righe; un tasto apre la spiegazione completa ("Cosa fa…?"). La casella
## "Salta i tutorial" vale per tutti i riquadri della partita in corso (serve al giocatore esperto):
## da lì le novità arrivano come notifica grigia, con la loro riga di cronaca.
## Proposte di Claude confermate da Fede il 26/11/2026: anche la fondazione e la tappa dei 60
## abitanti; più novità della stessa tappa come pagine dello stesso riquadro; nelle prove con i
## giocatori "umani" le pause dei tutorial si contano a parte. Il menù delle impostazioni, con
## l'opzione dei tutorial, è nel todo.
##
## Ogni scheda: titolo, testo (le due o tre righe del riquadro), domanda (il tasto che apre la
## spiegazione), dettaglio (la spiegazione), avviso (la notifica grigia se i tutorial sono saltati).
## Testi del gioco: nessun riferimento ad altri giochi (decisione di Fede del 24/11/2026). Il tutorial
## parla con la voce del mondo del gioco, non dei suoi meccanismi (Fede, 26/11/2026: "meno annunci
## falsi" è tecnico): si dicono il comando e il costo, niente percentuali né gergo.

## Le schede che apre la fondazione, nell'ordine in cui si mostrano.
const DOPO_FONDAZIONE := ["zona", "campi", "sentiero", "legnaia", "capanno", "posta", "fonti"]

const SCHEDE := {
	"fondare": {
		"titolo": "Fondare il villaggio",
		"testo": "Un gruppo di famiglie cerca una terra dove fermarsi. Scegli tu il luogo: le generazioni che verranno vivranno di questa scelta.",
		"domanda": "Come si sceglie un buon luogo?",
		"dettaglio": "Guarda la terra prima di fermarti. Passando con il puntatore, gli anziani ti dicono com'è il luogo: se c'è acqua, se la terra è grassa, se i boschi danno selvaggina e il fiume pesce, se le piene arrivano fin lì, se ci si può difendere, se l'aria è buona. Le voci in rosso sono i loro timori. Il cerchio mostra fin dove le famiglie andranno a coltivare, e si allargherà con il villaggio. Vicino al fiume si mangia meglio, ma il fiume a volte si riprende la sua terra. Quando hai deciso, fai clic.",
		"avviso": "Scegli il luogo del villaggio: gli anziani ti dicono com'è la terra.",
	},
	"zona": {
		"titolo": "Zona agricola",
		"testo": "Le famiglie vivono di campi, di caccia e di pesca. Mostra loro dove possono dissodare la terra: coltiveranno da sole quello che serve.",
		"domanda": "Come lavorano le famiglie la terra?",
		"dettaglio": "In Territorio, con il tasto Z, stendi la zona come con un pennello, dentro il cerchio del contado. Le famiglie non dissodano più del necessario: prima guardano quanto danno la caccia e la pesca, poi aprono nuovi campi un po' ogni anno, lontano dalle case. Con Togli restituisci la terra al prato senza toccare i campi già fatti. Un campo coltivato troppo a lungo si stanca: la terra si fa chiara, crescono le erbacce e il grano rende meno, finché non riposa.",
		"avviso": "Zona agricola (Z): mostra alle famiglie dove possono coltivare.",
	},
	"campi": {
		"titolo": "Campo",
		"testo": "A volte conviene dire alle famiglie proprio dove dissodare.",
		"domanda": "Quando conviene scegliere i campi a mano?",
		"dettaglio": "In Territorio, con il tasto C, un clic apre i campi nel cerchio. Serve a guidare il villaggio: per tenere i campi lontano dalle terre che il fiume allaga, o vicini a un sentiero. La terra grassa e l'acqua vicina danno più grano. Per abbandonare un campo si usa Demolisci.",
		"avviso": "Campo (C): scegli tu dove dissodare.",
	},
	"sentiero": {
		"titolo": "Sentiero",
		"testo": "Un sentiero battuto accorcia la fatica: il raccolto arriva prima a casa e i campi lungo la via rendono di più.",
		"domanda": "Come si tracciano i sentieri?",
		"dettaglio": "In Vie, con il tasto V: un clic dove comincia il sentiero, uno dove finisce, e si continua da lì; Esc chiude il tracciato. Con Collega alla rete ogni sentiero parte dal punto più vicino di quelli che ci sono già. Contano i sentieri che arrivano al villaggio: un tratto isolato in mezzo ai campi non porta nessun vantaggio.",
		"avviso": "Sentiero (V): i campi lungo le vie del villaggio rendono di più.",
	},
	"legnaia": {
		"titolo": "Legnaia",
		"testo": "Senza legna i focolari si spengono e non si costruiscono case nuove. Manda i boscaioli nel bosco.",
		"domanda": "Cosa fa una legnaia?",
		"dettaglio": "In Edifici, con il tasto L, vicino al bosco. I boscaioli abbattono gli alberi più vicini e la radura si allarga: più si allontanano, più la legna arriva piano. Con un clic sulla legnaia puoi lasciar riposare il bosco, che pian piano ricresce. Attento ai boschi lungo il fiume: senza alberi, le piene corrono più forti.",
		"avviso": "Legnaia (L): senza boscaioli non arriva legna.",
	},
	"capanno": {
		"titolo": "Capanno da pesca",
		"testo": "Le famiglie pescano anche dalla riva, ma con un capanno, le reti e la piroga il fiume dà molto di più.",
		"domanda": "Cosa fa un capanno da pesca?",
		"dettaglio": "In Edifici, con il tasto K: il capanno si posa sulla riva più vicina, rivolto all'acqua. Il fiume grande è più generoso dei torrenti, la palude dà poco. Se troppi capanni pescano nello stesso tratto il pesce si fa raro; lasciato in pace, torna. Servono due anni per costruirlo.",
		"avviso": "Capanno da pesca (K): con il capanno il fiume dà più pesce.",
	},
	"posta": {
		"titolo": "Posta di caccia",
		"testo": "Le famiglie cacciano anche attorno alle case, ma con una posta al margine del bosco tornano con molta più selvaggina.",
		"domanda": "Cosa fa una posta di caccia?",
		"dettaglio": "In Edifici, con il tasto T: la posta si mette appena fuori dal bosco, con gli alberi alle spalle. Dove il bosco è fitto la caccia è più ricca. Se si caccia troppo nello stesso bosco gli animali spariscono e conviene spostarsi; lasciati in pace, tornano. Servono due anni per costruirla.",
		"avviso": "Posta di caccia (T): al margine del bosco si torna con più selvaggina.",
	},
	"fonti": {
		"titolo": "Fonti di cibo",
		"testo": "Il villaggio mangia ciò che dà la terra, il bosco e il fiume. Puoi decidere dove mandare le braccia.",
		"domanda": "Come si sceglie dove lavorare?",
		"dettaglio": "In Gestione, tra le Politiche (tasto P). Se le famiglie smettono di cacciare, o di pescare, o di coltivare, le loro braccia vanno nelle altre fatiche; almeno una resta sempre. Cambiare le abitudini scontenta un po' il villaggio. A sinistra, sotto Fonti di cibo, vedi quanto si prende da ciascuna e quanto potrebbe dare.",
		"avviso": "Fonti di cibo: nelle Politiche (P) decidi dove lavorano le famiglie.",
	},
	# Specchietto dei rapporti di forza (Fede, 26/11/2026): alla tappa dei 60 abitanti.
	"rapporti": {
		"titolo": "Chi conta nel villaggio",
		"testo": "Gli anziani, le famiglie e, più avanti, il sacerdote non vogliono le stesse cose. Ogni tua scelta piace a qualcuno e scontenta qualcun altro.",
		"domanda": "Come vedo chi è contento e chi conta?",
		"dettaglio": "Con il tasto R, o con un clic su Consenso, si apre lo specchietto dei rapporti di forza: per ogni gruppo, quanto conta e di che umore è, e se sta cambiando. Sotto, quanta tensione c'è nel villaggio e verso dove lo stanno portando le sue usanze. Prima di usare uno strumento, sopra la sua scheda le Conseguenze dicono chi ci guadagna, chi ci perde, cosa cambia sulla terra e cosa ne resterà. Un clic su una persona o su una casa apre la scheda della sua famiglia: dove abita, che lavoro fa, di che umore è e cosa vorrebbe.",
		"avviso": "Rapporti di forza (R): chi conta nel villaggio e di che umore è.",
	},
	"granaio": {
		"titolo": "Granaio",
		"testo": "Le famiglie sono abbastanza da mettere da parte il raccolto. Senza un granaio le scorte marciscono e gli anni magri fanno paura.",
		"domanda": "Cosa fa il granaio?",
		"dettaglio": "In Edifici, con il tasto H, non lontano dal centro. Servono 30 di legna e tre anni di lavoro. Sopra i pali, al riparo dai topi e dall'umido, il grano si conserva a lungo: è la prima difesa contro la fame, insieme agli animali e ai segni ascoltati.",
		"avviso": "Granaio (H): conserva il grano per gli anni magri.",
	},
	"raccolto": {
		"titolo": "Divisione del raccolto",
		"testo": "Ora che il grano avanza, bisogna decidere di chi è: di tutto il villaggio o di ogni famiglia.",
		"domanda": "Cosa cambia tra le due usanze?",
		"dettaglio": "In Gestione, tra le Politiche (tasto P). In comune, il raccolto si divide tra tutti e gli anziani ne sono contenti. Alle famiglie, ognuna tiene il suo: si lavora con più impegno e le mandrie crescono, le famiglie sono contente, ma gli anziani mormorano e qualcuno comincia ad avere più degli altri.",
		"avviso": "Divisione del raccolto: nelle Politiche (P), in comune o alle famiglie.",
	},
	"luogo_sacro": {
		"titolo": "Luogo sacro",
		"testo": "La popolazione ha bisogno di fede e il sacerdote chiede un luogo sacro. Lì saprà leggere meglio i segni del cielo e delle acque; senza, potrebbe adirarsi.",
		"domanda": "Cosa fa un luogo sacro?",
		"dettaglio": "In Edifici, con il tasto O: un cerchio di pali attorno a una pietra eretta, uno solo, non lontano dalle case. Servono 20 di legna e tre anni di lavoro. Da oggi il sacerdote ha voce nel villaggio e non avrà pace finché il luogo sacro non sarà eretto. Contento, i suoi segni saranno chiari e affidabili; scontento, parlerà per enigmi e più spesso si sbaglierà. Le famiglie amano costruire le case vicino al luogo sacro.",
		"avviso": "Luogo sacro (O): il sacerdote lo chiede; senza, si adira.",
	},
	"pascolo": {
		"titolo": "Pascolo",
		"testo": "Le famiglie tengono qualche animale attorno alle case. Dagli un pascolo e la mandria crescerà: è una scorta viva per gli anni magri.",
		"domanda": "Come funziona il pascolo?",
		"dettaglio": "In Territorio, con il tasto N, si stende come la zona agricola. Il prato nutre molti animali, il bosco pochi, il campo a riposo moltissimi; la mandria cresce finché c'è erba, e dove pascola il bosco non ricresce. Gli animali non entrano nel grano in piedi: dopo la mietitura mangiano le stoppie e lasciano il concime, e un campo stanco diventa maggese e si riposa prima. Negli anni magri qualche bestia si macella. Troppi animali sui pendii smuovono la terra, e le piene peggiorano.",
		"avviso": "Pascolo (N): la mandria cresce ed è una scorta per gli anni magri.",
	},
	"stranieri": {
		"titolo": "Accoglienza degli stranieri",
		"testo": "L'abbondanza del villaggio si vede dalla valle: qualcuno arriverà a chiedere di fermarsi. Quello che deciderai la prima volta diventerà l'usanza.",
		"domanda": "Cosa portano gli stranieri?",
		"dettaglio": "In Gestione, tra le Politiche (tasto P). Se il villaggio è aperto, chi arriva resta: porta braccia, animali e nuovi modi di coltivare, ma anche qualche malattia e un po' di attrito. Caso per caso: a ogni arrivo ci si ferma e gli anziani decidono. Se è chiuso, gli stranieri vengono mandati via e il villaggio resta com'è.",
		"avviso": "Stranieri: nelle Politiche (P) decidi l'usanza dell'accoglienza.",
	},
	"affollati": {
		"titolo": "Villaggio affollato",
		"testo": "Quando le case non bastano per tutte le famiglie, il villaggio deve scegliere: stringersi o lasciar partire qualcuno.",
		"domanda": "Cosa cambia tra le due scelte?",
		"dettaglio": "In Gestione, tra le Politiche (tasto P). Allargare l'abitato: le case si stringono e crescono verso i campi, e per qualche anno ci si ammala di più. Emigrare: chi non trova posto parte in cerca di terra altrove; ci sono meno bocche da sfamare, ma anche meno braccia.",
		"avviso": "Villaggio affollato: nelle Politiche (P), allargare o emigrare.",
	},
	"bosco_sacro": {
		"titolo": "Bosco sacro",
		"testo": "Il sacerdote vuole un bosco che nessuno tocchi. Sarà anche una riserva: lì nessuno taglia la legna.",
		"domanda": "Cosa fa un bosco sacro?",
		"dettaglio": "In Territorio, con il tasto B, si stende come un pennello sul bosco vicino al villaggio. I boscaioli lo rispettano e le famiglie non vi aprono campi. Più è grande, più il sacerdote è contento. Abbatterlo lo offende profondamente.",
		"avviso": "Bosco sacro (B): un bosco che il sacerdote vuole intatto.",
	},
	"casali": {
		"titolo": "Casali nel contado",
		"testo": "Il villaggio è pieno: le famiglie nuove vanno a vivere nel contado, in piccoli casali vicino ai loro campi.",
		"domanda": "Come nascono i casali?",
		"dettaglio": "Nascono da soli, quando nel villaggio non c'è più posto: poche case insieme, non troppo lontane, vicino ai campi e lontano dalle terre che il fiume allaga. Si costruiscono con la legna come le altre case. Li vedi bene nella mappa Abitato e contado.",
		"avviso": "Casali: le famiglie nuove vanno a vivere nel contado.",
	},
}


static func ha(chiave: String) -> bool:
	return SCHEDE.has(chiave)


static func scheda(chiave: String) -> Dictionary:
	return SCHEDE.get(chiave, {})
