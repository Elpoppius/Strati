class_name Cursori
extends RefCounted
## Cursori del mouse di Strati (richiesta di Fede del 26/11/2026: "crea anche un cursore vero e
## proprio per il puntatore"). Nello stile dell'HUD: bianco a tratto pieno con il bordo scuro.
## Tre forme: la freccia, la freccia con il quadratino quando sotto il puntatore c'è qualcosa da
## scegliere (una casa, una persona, un edificio), il mirino quando è scelto uno strumento.

const FRECCIA := 0
const SCEGLI := 1
const STRUMENTO := 2
const FILE := ["res://asset/cursori/freccia.svg", "res://asset/cursori/scegli.svg", "res://asset/cursori/strumento.svg"]
const PUNTE := [Vector2(3, 2), Vector2(3, 2), Vector2(16, 16)]

static var _attuale := -1
static var _texture: Array = []


static func imposta(forma: int) -> void:
	if forma == _attuale:
		return
	_attuale = forma
	if DisplayServer.get_name() == "headless":
		return
	if _texture.is_empty():
		for f in FILE:
			_texture.append(load(f))
	Input.set_custom_mouse_cursor(_texture[forma], Input.CURSOR_ARROW, PUNTE[forma])


## La forma in uso (per le verifiche).
static func attuale() -> int:
	return _attuale
