extends Area3D
## Cápsula de helio-3 que sale del reactor. Flota y gira.
## Cuando el jugador (o el vehículo) la toca, la recoge: suma 1 de helio-3.
## Llévalas a la nave (pieza carga_nave.tscn).

var _recogida := false
var _tiempo := randf() * TAU

@onready var _cuerpo: Node3D = $Cuerpo


func _ready() -> void:
	body_entered.connect(_al_tocar)


func _process(delta: float) -> void:
	_tiempo += delta
	_cuerpo.position.y = 0.9 + sin(_tiempo * 2.0) * 0.15
	_cuerpo.rotate_y(delta * 1.5)


func _al_tocar(cuerpo: Node3D) -> void:
	if _recogida:
		return
	if not (cuerpo.is_in_group("vehiculo") or Interactuable.es_jugador(cuerpo)):
		return
	_recogida = true
	Juego.agregar_helio3(1)
	Juego.mostrar_mensaje("+1 helium-3 capsule (you have %d). Take them to the ship" % Juego.helio3)
	var animacion := create_tween()
	animacion.tween_property(self, "scale", Vector3.ONE * 0.01, 0.25)
	animacion.tween_callback(queue_free)
