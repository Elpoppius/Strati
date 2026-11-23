class_name MappaDati
extends Resource
## Dati naturali di una mappa: quote e strati su una griglia quadrata di pixel.
## Il pixel (0, 0) è l'angolo nord-ovest. In 3D: x verso est, z verso sud, y in alto.
## Il pixel (i, j) corrisponde al punto (i * metri_per_px, j * metri_per_px) del mondo.

const TERRA := 0
const FIUME := 1
const TORRENTE := 2
const TORRENTE_EST := 3
const PALUDE := 4
const GESSI := 5
const NOMI_TIPO := ["Terra", "Fiume", "Torrente stagionale", "Torrente", "Palude", "Gessi"]
const NOMI_ZONA := ["Bassa pianura", "Alta pianura", "Fascia pedecollinare", "Colline"]

@export var nome: String = ""
@export var lato: int = 0
@export var metri_per_px: float = 40.0
@export var quota_min: float = 0.0
@export var quota_max: float = 0.0
@export var altezze: PackedFloat32Array
@export var tipo: PackedByteArray
@export var zona: PackedByteArray
@export var fertilita: PackedByteArray
@export var piena: PackedByteArray
@export var acqua: PackedByteArray
@export var acqua_stagionale: PackedByteArray
@export var copertura: PackedByteArray
## Distanza dal bordo dell'acqua: 128 = riva, 2 m per unità, sotto 128 si è in acqua.
@export var distanza_acqua: PackedByteArray
## Bosco a 10 m (stessa griglia di distanza_acqua): 128 = margine, sopra è bosco.
## Lo usano lo shader del terreno e la posa degli alberi (Alberi).
@export var bosco_fine: PackedByteArray
## Lato della griglia di distanza_acqua e bosco_fine (più fine di quella del terreno).
@export var lato_acqua: int = 0
@export var sorgenti: PackedVector2Array
## Ogni sito è un Dictionary { "n": int, "nome": String, "px": Vector2 }.
@export var siti: Array = []


func lato_metri() -> float:
	return (lato - 1) * metri_per_px


func indice(x: int, y: int) -> int:
	return y * lato + x


func pixel_da_mondo(xm: float, zm: float) -> Vector2i:
	return Vector2i(clampi(roundi(xm / metri_per_px), 0, lato - 1), clampi(roundi(zm / metri_per_px), 0, lato - 1))


func mondo_da_pixel(p: Vector2) -> Vector2:
	return p * metri_per_px


## Quota in metri (senza esagerazione) in un punto qualunque, con interpolazione bilineare.
func quota(xm: float, zm: float) -> float:
	var fx := clampf(xm / metri_per_px, 0.0, lato - 1.001)
	var fz := clampf(zm / metri_per_px, 0.0, lato - 1.001)
	var x0 := int(fx)
	var z0 := int(fz)
	var tx := fx - x0
	var tz := fz - z0
	var a := altezze[indice(x0, z0)]
	var b := altezze[indice(x0 + 1, z0)]
	var c := altezze[indice(x0, z0 + 1)]
	var d := altezze[indice(x0 + 1, z0 + 1)]
	return lerpf(lerpf(a, b, tx), lerpf(c, d, tx), tz)


func edificabile_px(p: Vector2i) -> bool:
	var t := tipo[indice(p.x, p.y)]
	return t == TERRA or t == GESSI


## Tutte le informazioni sul terreno in un punto del mondo, per la lettura del lotto.
func campione(xm: float, zm: float) -> Dictionary:
	var p := pixel_da_mondo(xm, zm)
	var i := indice(p.x, p.y)
	return {
		"quota": quota(xm, zm),
		"tipo": tipo[i],
		"nome_tipo": NOMI_TIPO[tipo[i]],
		"zona": NOMI_ZONA[zona[i]],
		"fertilita": fertilita[i] / 255.0 * 1.2,
		"piena": piena[i] / 255.0,
		"acqua": acqua[i] / 255.0,
		"acqua_stagionale": acqua_stagionale[i] / 255.0,
		"bosco": copertura[i] > 127,
		"edificabile": edificabile_px(p),
	}
