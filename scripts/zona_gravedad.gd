extends Area3D
## Cambia la gravedad dentro de su caja. Por defecto, la de la Luna.
## Tierra: 9.8   Luna: 1.62   Marte: 3.71

@export var gravedad := 1.62


func _ready() -> void:
	gravity_space_override = Area3D.SPACE_OVERRIDE_REPLACE
	gravity_direction = Vector3.DOWN
	gravity = gravedad
