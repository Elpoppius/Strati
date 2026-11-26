# Edifici e modelli per epoca

*Scritto il 26/11/2026 su richiesta di Fede: la lista completa degli edifici (e quindi dei modelli) previsti per ogni epoca. **Tutta la lista è una [Proposta] di Claude, da confermare con Fede.** Principi e sistemi in `epoche-future.md`; stile e regole tecniche in `asset.md`.*

## Come leggere la lista
**Genere** (dall'approccio deciso in `asset.md`: edifici procedurali per il tessuto, pochi pezzi fatti a mano):
- **M** modello fatto a mano (script di Blender): monumenti e tipi riconoscibili.
- **G** generatore: una famiglia di edifici costruita dal lotto (pianta, piani, tetto, materiali dell'epoca). Un solo script, infinite case.
- **R** rete: moduli che si ripetono lungo una linea (tratto, varco, angolo, nodo), come `palizzata_tratto` e `palizzata_varco`.
- **P** pezzo minore o arredo (pozzi, banchi, lampioni, cippi).
- **S** solo shader o terreno, nessun modello (campi, orti, selciati, centuriazione).
- **✓** esiste già in `gioco/asset/villaggio/`.

**Regole che valgono per tutti** (decise in `epoche-future.md` § 5): un modello per struttura; cantiere, degrado, inclinazione, rovina e rifunzionalizzazione si ricavano in automatico. Il **tipo di struttura** (casa piccola, schiera, corte, blocco, aula, torre, recinto, capannone, tettoia, infrastruttura) è indicato tra parentesi quando serve al cambio d'uso.

**Ciò che resta:** un edificio di un'epoca non sparisce al cambio d'epoca. Le liste dicono solo cosa **si aggiunge**.

---

## Era delle Origini

### Epoca 1 — Villaggio
| Edificio | Genere | Note |
|---|---|---|
| Casa lunga piccola, media, grande | M ✓ | (casa piccola) case spontanee |
| Capanna tonda, piccola e grande | M ✓ | |
| Granaio su pali | M ✓ | con cantiere ✓ |
| Fossa-silo | P ✓ | |
| Focolare | P ✓ | |
| Legnaia | M ✓ | (tettoia) con cantiere ✓ |
| Catasta di legna | P ✓ | |
| Capanno da pesca | M ✓ | con cantiere ✓; germe dell'approdo |
| Posta di caccia | M ✓ | con cantiere ✓ |
| Luogo sacro (cerchio di pali e pietra) | M ✓ | con cantiere ✓; germe del tempio e della piazza |
| Stabbio | M ✓ | |
| Recinto per gli animali | P ✓ | |
| Rocce | P ✓ | tre varianti |
| Animali: pecora, capra, maiale, bue | M ✓ | |
| Aia (battitura del grano) | P | **nuovo**: spiazzo di terra battuta accanto ai campi |
| Fornace del vasaio | P | **nuovo**: forno a cupola d'argilla, germe del quartiere artigiano |
| Sepolture | P | **nuovo**: piccoli tumuli o fosse segnate vicino al villaggio; prima traccia per il sottosuolo |
| Passerella o guado | R | **nuovo**: tronchi e pietre sul torrente, germe del ponte |
| Orti | S | deciso: disegnati più piccoli dentro il quadrato da 40 m |
| Sentieri | S | ci sono già nello shader |
| Figure: 3 uomini e 3 donne | M | deciso (`era-origini.md`), vesti dell'epoca |

### Epoca 2 — Abitato protourbano
| Edificio | Genere | Note |
|---|---|---|
| Capanna rettangolare su impalcato | G | (casa piccola) le case del villaggio arginato |
| Casa del capo | M | grande casa con recinto proprio: il prestigio dei lignaggi |
| Terrapieno con fossato | R | **il recinto**: tratto, angolo, varco; la linea delle future mura |
| Palizzata sul terrapieno | R ✓ | `palizzata_tratto` e `palizzata_varco` ci sono già |
| Porta con torre di legno | M | sul varco del terrapieno |
| Ponte sul fossato | R | |
| Pozzo con vasca | P | |
| Canale che riempie il fossato | R | il primo lavoro sull'acqua |
| Officina del fabbro | M | forgia, crogioli: il bronzo |
| Magazzino comune | M | (casa piccola) |
| Area di scambio al guado | P | banchi, merci a terra: il germe del mercato |
| Approdo sul fiume | M | evoluzione del capanno: piroghe e merci |
| Necropoli a urne | P | fuori dall'abitato; strato per il sottosuolo |
| Tumulo del capo | M | prestigio, segno nel paesaggio |
| Santuario con deposito votivo | M | evoluzione del luogo sacro |
| Torre di guardia sul colle | M | fuochi: i segni delle scorrerie |
| Recinto grande per il bestiame | P | |
| Mezzi: carro a ruote piene, piroga | M | |

## Antichità

### Epoca 3 — Città-stato
| Edificio | Genere | Note |
|---|---|---|
| Casa a corte su zoccolo di ciottoli, alzato in mattoni crudi | G | (corte) il tessuto della città |
| Botteghe | G | (schiera) |
| Tempio su podio | M | (aula) evoluzione del santuario |
| Altare e recinto sacro | P | |
| Area pubblica (piazza delle assemblee) | S + P | spazio riservato: il primo vuoto voluto |
| Mura con porte | R + M | tratto, torre, porta |
| Cippi del confine sacro | P | il confine rituale |
| Strade a reticolo con canalette di scolo | S + R | riferimento: Marzabotto |
| Pozzo, cisterna | P | |
| Quartiere dei vasai: fornaci | P | |
| Officine del metallo | G | |
| Magazzini | G | (casa piccola) |
| Porto fluviale | M | evoluzione dell'approdo |
| Necropoli con stele | P | lungo le strade, fuori dalle mura |
| Mezzi: carro, barca da fiume | M | |

### Epoca 4 — Città imperiale
| Edificio | Genere | Note |
|---|---|---|
| Domus | G | (corte) |
| Insula | G | (blocco) le case a più piani |
| Tabernae | G | (schiera) |
| Foro con portici | M | piazza porticata, il centro pianificato |
| Basilica | M | (aula) |
| Tempio maggiore | M | (aula) |
| Terme | M | |
| Teatro | M | (recinto) |
| Anfiteatro | M | (recinto) il caso del riuso in case |
| Mercato (macellum) | M | |
| Magazzini (horrea) | G | (capannone antico) |
| Arco onorario | M | |
| Via consolare lastricata con pietre miliari | R + P | la via Emilia: forza del tracciato |
| Reticolo di cardi e decumani | S | |
| Cloache | R | sotterranee |
| Acquedotto | R | in cunicolo (riferimento: Bologna) o su arcate |
| Fontane pubbliche | P | |
| Ponte in pietra | R + M | |
| Mura con porte | R + M | |
| Necropoli con mausolei lungo le strade | M + P | |
| Villa rustica | M | in campagna |
| Centuriazione | S | campi, fossi e strade a griglia: strato nel tracciato |
| Fornaci per laterizi | P | |
| Mezzi: carro, carrozza, chiatta | M | |

## Medioevo

### Epoca 5 — Città in contrazione
| Edificio | Genere | Note |
|---|---|---|
| Case di legno tra le rovine | G | (casa piccola) |
| Case dentro i monumenti | variante | riuso dell'anfiteatro e del teatro, ricavato dai modelli antichi |
| Mura ristrette | R + M | riferimento: la cerchia di selenite |
| Cattedrale paleocristiana | M | (aula) sulla rovina del tempio |
| Battistero | M | |
| Monastero: chiesa, chiostro, orti | M | (recinto) bonifica e tiene i campi |
| Pieve rurale | M | |
| Castello o rocca | M | |
| Torre di guardia | M | (torre) |
| Ospizio per i viandanti | M | |
| Fornace della calce | P | dove si brucia il marmo dei monumenti |
| Cumulo di spoglie | P | pietre tolte alle rovine, il materiale da riuso |
| Mulino ad acqua | M | |
| Orti dentro le mura | S | |
| Mezzi: carro, barca | M | |

### Epoca 6 — Città comunale e mercantile
| Edificio | Genere | Note |
|---|---|---|
| Casa a schiera con portico | G | (schiera) il portico come regola edilizia |
| Casa-torre | G | (torre bassa) |
| Torre gentilizia | M | (torre) varianti di altezza; il caso delle Due Torri |
| Palazzo del comune | M | |
| Palazzo del podestà | M | |
| Piazza maggiore | S + P | |
| Cattedrale romanica o gotica | M | (aula) |
| Basiliche degli ordini mendicanti | M | (aula) ai margini, con convento |
| Campanile | M | (torre) |
| Loggia dei mercanti | M | (tettoia nobile) |
| Mercato con banchi | P | |
| Seconda e terza cerchia con porte | R + M | tratto, torresotto, porta |
| Borghi fuori porta | G | case lungo le strade, oltre le mura |
| Canale con chiusa | R + M | riferimento: canale di Reno, chiusa di Casalecchio |
| Mulino da seta | M | (capannone antico) i filatoi idraulici |
| Porto sul canale con sostegni | M | riferimento: Navile |
| Ospedale | M | |
| Studio (università) e collegi | M | (corte) |
| Case delle corporazioni | G | (palazzetto) |
| Botteghe artigiane | G | (schiera) |
| Lavatoio, pozzo, fontana | P | |
| Ponti | R | |
| Mezzi: carro, barca da canale | M | |

## Età moderna

### Epoca 7 — Città del principe
| Edificio | Genere | Note |
|---|---|---|
| Mura bastionate con spianata | R + M | tratto, bastione, porta; la spianata demolisce i borghi |
| Fortezza (cittadella) | M | |
| Palazzo del principe | M | (corte) |
| Palazzo nobiliare | G | (corte) facciata regolare |
| Piazza regolare | S + P | progetto dall'alto |
| Rettifilo | R | taglia il tracciato: cicatrici |
| Chiese rinascimentali e barocche | M | (aula) |
| Fontana monumentale | M | |
| Teatro di corte | M | |
| Palazzo delle scuole | M | (corte) |
| Giardini e villa suburbana | M | |
| Lazzaretto | M | (recinto) |
| Portico devozionale verso il santuario | R | riferimento: il portico di San Luca |
| Santuario sul colle | M | |
| Granai pubblici | M | |
| Zecca | M | |
| Mezzi: carrozza, carro, barca | M | |

### Epoca 8 — Città della ragione
| Edificio | Genere | Note |
|---|---|---|
| Cimitero fuori città | M | (recinto) riferimento: la Certosa, sul riuso di un convento |
| Ospedale generale | M | |
| Caserma nel convento soppresso | variante | rifunzionalizzazione |
| Passeggio pubblico, giardino | S + P | riferimento: la Montagnola |
| Teatro pubblico | M | (aula) |
| Albergo dei poveri | M | (corte) |
| Carcere | M | |
| Dogana | M | |
| Borsa, camera di commercio | M | |
| Biblioteca, accademia | M | |
| Lampioni a olio | P | |
| Strade carrozzabili e ponti | R | |
| Mezzi: carrozza, diligenza | M | |

## Età industriale

### Epoca 9 — Città industriale
| Edificio | Genere | Note |
|---|---|---|
| Stazione | M | (aula) il nodo tra Vie e Trasporti |
| Fascio di binari, scalo merci | R | |
| Fabbrica | G | (capannone) |
| Ciminiera | P | (torre) |
| Gasometro | M | |
| Centrale elettrica | M | |
| Fogna | R | sotterranea |
| Acquedotto moderno e serbatoio | R + M | |
| Macello pubblico | M | |
| Mercato coperto in ferro e vetro | M | (aula) |
| Case operaie | G | (blocco) |
| Palazzi borghesi lungo i viali | G | (blocco) |
| Villini | G | (casa piccola) |
| Viali di circonvallazione alberati | R | sulle mura abbattute |
| Boulevard | R | lo sventramento |
| Linee del tram e rimessa | R + M | |
| Banca | M | |
| Scuole pubbliche | G | |
| Ospedale a padiglioni | M | |
| Bagni e lavatoi pubblici | M | |
| Giardini pubblici | S + P | |
| Magazzini generali | G | (capannone) |
| Ponti in ferro | R | |
| Lampioni a gas | P | |
| Mezzi: tram a cavalli ed elettrico, treno, carro, carrozza | M | |

### Epoca 10 — Città di massa
| Edificio | Genere | Note |
|---|---|---|
| Quartiere di edilizia pubblica: case in linea e torri | G | (blocco) |
| Palazzina, condominio | G | (blocco) |
| Villette | G | (casa piccola) |
| Tangenziale e svincoli | R | |
| Distributore di benzina | P | |
| Parcheggio multipiano | G | |
| Zona industriale | G | (capannone) |
| Fiera | M | |
| Stadio | M | |
| Scuole, centri civici, ospedali di quartiere | G | |
| Supermercato | G | (capannone) |
| Cinema | M | |
| Casa del popolo, sede di partito | G | |
| Chiesa moderna | M | |
| Depuratore | M | |
| Discarica | S + P | |
| Macerie e ricostruzione | variante | rovina di guerra ricavata dai modelli |
| Fermate degli autobus | P | |
| Mezzi: automobile, autobus, camion, filobus, treno, motorino | M | |

## Età globale

### Epoca 11 — Città globale
| Edificio | Genere | Note |
|---|---|---|
| Fabbrica riusata (loft, uffici, eventi) | variante | rifunzionalizzazione |
| Stazione dell'alta velocità | M | |
| Quartiere direzionale, torri di uffici | G + M | (blocco) |
| Centro commerciale di periferia | G | (capannone) |
| Polo logistico | G | (capannone grande) |
| Polo tecnologico, industria 4.0 | G | (capannone) |
| Tram moderno con fermate | R + P | |
| Piste ciclabili, bici condivise | S + P | |
| Parco sulla ferrovia dismessa | S + P | |
| Fiume riaperto | S | |
| Cassa d'espansione | R | contro le piene |
| Pannelli solari, tetti verdi | variante | pezzi aggiunti ai tetti |
| Albergo | G | (blocco) |
| Museo, biblioteca in un edificio storico | variante | recupero in loco |
| Data center | G | (capannone) |
| Mezzi: tram moderno, bus elettrico, auto, bici, monopattino | M | |

### Epoca 12 — Città futura
Facoltativa e speculativa: gli edifici nascono dalle tendenze della partita. Esempi da tenere a mente: dighe mobili e barriere, serre verticali, quartieri recintati, rovine dello sprawl, mezzi senza conducente.

---

## Pezzi che servono in ogni epoca
| Pezzo | Genere | Note |
|---|---|---|
| Mura e confini | R | stessi moduli (tratto, angolo, varco, torre, porta) con materiali d'epoca: palizzata, terrapieno, mattoni crudi, pietra, selenite, mattone, bastione |
| Ponti | R | legno, pietra, mattone, ferro, cemento |
| Strade | S + R | terra battuta, ghiaia, lastricato, ciottoli, macadam, asfalto; bordi e marciapiedi come rete |
| Canali | R | argini, chiuse, sostegni |
| Figure | M | 3 uomini e 3 donne, vesti per epoca (stesso corpo, vesti diverse) |
| Animali | M ✓ | servono fino all'Età industriale (cavalli da aggiungere per carri e carrozze) |
| Alberi | ✓ | ci sono già; servono filari e alberi da viale |

## Il conto (stima)
| Genere | Quanti, a occhio |
|---|---|
| M fatti a mano | circa 100 voci (alcune con più varianti); i 33 file del villaggio ci sono già, cantieri e animali compresi |
| G generatori | circa 35 famiglie, molte con lo stesso motore (cambiano materiali e proporzioni) |
| R reti | circa 30 voci, quasi tutte con gli stessi cinque moduli |
| P e S | circa 45, piccoli |
| Mezzi | circa 30 modelli in 11 epoche |

Al ritmo di oggi (un modello fatto a mano con prove in 15–30 minuti di lavoro di Claude), gli M di un'epoca prendono una o due sessioni. Il lavoro grosso sono i **generatori**: il primo (la casa a corte o la casa a schiera) va pensato come motore comune per tutte le epoche urbane.
