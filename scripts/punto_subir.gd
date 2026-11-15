extends Interactuable
## Zona para subirse a un vehículo con E. Va como hija del vehículo (scripts/vehiculo.gd).
## Al presionar E busca al jugador en la zona; si la zona no lo detectó,
## también sirve estar a menos de "distancia_maxima" metros del vehículo.

## Distancia (metros) desde la que se puede subir aunque la zona no detecte al jugador.
@export var distancia_maxima := 8.0


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interactuar"):
		return
	var vehiculo := get_parent()
	# Si ya está manejando, la E es para bajarse: la maneja el vehículo.
	if vehiculo.get("conduciendo") or not vehiculo.has_method("subir"):
		return
	var jugador := _buscar_jugador()
	if jugador == null:
		return
	get_viewport().set_input_as_handled()
	vehiculo.subir(jugador)


## El jugador que está en la zona, o el dueño de la cámara activa si está cerca.
func _buscar_jugador() -> Node3D:
	if monitoring:
		for cuerpo in get_overlapping_bodies():
			if es_jugador(cuerpo) and _esta_activo(cuerpo):
				return cuerpo
	var camara := get_viewport().get_camera_3d()
	var nodo: Node = camara
	while nodo and not (nodo is CharacterBody3D):
		nodo = nodo.get_parent()
	if nodo is CharacterBody3D and es_jugador(nodo) and _esta_activo(nodo):
		var cuerpo := nodo as Node3D
		if cuerpo.global_position.distance_to(global_position) <= distancia_maxima:
			return cuerpo
	return null


static func _esta_activo(cuerpo: Node) -> bool:
	return cuerpo.is_inside_tree() and cuerpo.can_process() and (cuerpo as Node3D).is_visible_in_tree()
