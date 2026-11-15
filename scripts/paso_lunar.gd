extends Node
## Hace que el jugador camine "flotando" en la Luna: da saltitos suaves al caminar
## y con Espacio salta alto (la gravedad lunar es 6 veces menor).
## Va como hija del jugador. No cambia el script del jugador: solo le ajusta la velocidad.

## Impulso de cada saltito al caminar (metros por segundo hacia arriba).
@export var saltito := 1.0
## Impulso del salto con Espacio.
@export var salto := 3.2

var _cuerpo: CharacterBody3D
var _saltar := false


func _ready() -> void:
	_cuerpo = get_parent() as CharacterBody3D
	# Corre antes que el jugador, así el impulso entra en su movimiento de este cuadro.
	process_physics_priority = -10


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("propulsor"):
		_saltar = true


func _physics_process(_delta: float) -> void:
	if _cuerpo == null or not _cuerpo.is_on_floor():
		_saltar = false
		return
	if _saltar:
		_cuerpo.velocity.y = salto
	else:
		var v := _cuerpo.velocity
		if Vector2(v.x, v.z).length() > 1.0:
			_cuerpo.velocity.y = saltito
	_saltar = false
