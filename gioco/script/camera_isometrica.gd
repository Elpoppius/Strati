class_name CameraIsometrica
extends Node3D
## Camera ortografica a inclinazione fissa che ruota a scatti di 90°.
## Il nodo sta sul punto guardato (bersaglio); la Camera3D figlia lo guarda da lontano.

const INCLINAZIONE := -30.0
const DISTANZA := 20000.0
const DIM_MIN := 40.0
const DIM_MAX := 12000.0

var camera: Camera3D
var bersaglio := Vector3.ZERO
var yaw := 45.0
var yaw_obiettivo := 45.0
var dimensione := 2000.0
var dimensione_obiettivo := 2000.0
var limiti := Rect2(0.0, 0.0, 10000.0, 10000.0)
## Funzione (x, z) -> quota, per tenere il bersaglio sul terreno.
var funzione_quota: Callable


func _ready() -> void:
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.near = 10.0
	camera.far = DISTANZA * 3.0
	add_child(camera)
	camera.make_current()
	aggiorna()


## Ruota la vista di 90° (verso = 1 in senso orario, -1 antiorario).
func ruota(verso: int) -> void:
	yaw_obiettivo += 90.0 * verso


func zoom(fattore: float) -> void:
	dimensione_obiettivo = clampf(dimensione_obiettivo * fattore, DIM_MIN, DIM_MAX)


func vai_a(x: float, z: float, dim: float = -1.0) -> void:
	bersaglio.x = x
	bersaglio.z = z
	if dim > 0.0:
		dimensione_obiettivo = clampf(dim, DIM_MIN, DIM_MAX)
		dimensione = dimensione_obiettivo
	aggiorna()


## Direzioni orizzontali di destra e di avanti, secondo la rotazione attuale.
func assi_suolo() -> Array:
	var b := Basis.from_euler(Vector3(deg_to_rad(INCLINAZIONE), deg_to_rad(yaw), 0.0))
	var destra := Vector3(b.x.x, 0.0, b.x.z).normalized()
	var avanti := Vector3(-b.z.x, 0.0, -b.z.z).normalized()
	return [destra, avanti]


## Sposta la vista trascinando: delta in pixel dello schermo.
func trascina(delta_px: Vector2, altezza_vista: float) -> void:
	var metri_per_px := dimensione / maxf(altezza_vista, 1.0)
	var assi := assi_suolo()
	var sin_incl := absf(sin(deg_to_rad(INCLINAZIONE)))
	bersaglio -= assi[0] * delta_px.x * metri_per_px
	bersaglio += assi[1] * delta_px.y * metri_per_px / sin_incl
	aggiorna()


func _process(delta: float) -> void:
	var muovi := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		muovi.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		muovi.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		muovi.y += 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		muovi.y -= 1.0
	if muovi != Vector2.ZERO:
		var assi := assi_suolo()
		var velocita := dimensione * 0.8
		bersaglio += (assi[0] * muovi.x + assi[1] * muovi.y).normalized() * velocita * delta
	var k := 1.0 - exp(-10.0 * delta)
	yaw = lerpf(yaw, yaw_obiettivo, k)
	if absf(yaw - yaw_obiettivo) < 0.05:
		yaw = yaw_obiettivo
	dimensione = exp(lerpf(log(dimensione), log(dimensione_obiettivo), k))
	aggiorna()


func aggiorna() -> void:
	bersaglio.x = clampf(bersaglio.x, limiti.position.x, limiti.end.x)
	bersaglio.z = clampf(bersaglio.z, limiti.position.y, limiti.end.y)
	if funzione_quota.is_valid():
		bersaglio.y = funzione_quota.call(bersaglio.x, bersaglio.z)
	position = bersaglio
	if camera:
		var b := Basis.from_euler(Vector3(deg_to_rad(INCLINAZIONE), deg_to_rad(yaw), 0.0))
		camera.transform = Transform3D(b, b.z * DISTANZA)
		camera.size = dimensione
		# Piani di taglio stretti attorno al terreno visibile: le ombre coprono solo quella fetta
		# e restano nitide anche da vicino (la camera sta lontanissima, la profondità utile è poca).
		var margine := dimensione + 80.0 + clampf(dimensione * 0.3, 0.0, 900.0)
		camera.near = maxf(10.0, DISTANZA - margine)
		camera.far = DISTANZA + margine
