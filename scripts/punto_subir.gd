extends Interactuable
## Zona para subirse a un vehículo con E. Va como hija del vehículo (scripts/vehiculo.gd).

var _jugador: Node3D


func _ready() -> void:
	super._ready()
	body_entered.connect(_recordar_jugador)


func _recordar_jugador(cuerpo: Node3D) -> void:
	if es_jugador(cuerpo):
		_jugador = cuerpo


func interactuar() -> void:
	var vehiculo := get_parent()
	if is_instance_valid(_jugador) and vehiculo.has_method("subir"):
		vehiculo.subir(_jugador)
