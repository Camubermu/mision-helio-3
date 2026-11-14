extends Area3D
## Zona alrededor de la nave para cargarle las cápsulas de helio-3.
## Cuando el jugador (o el vehículo) llega con cápsulas, vuelan a la nave.
## Al juntar las necesarias, la nave queda lista (y si hay siguiente nivel, se pasa a él).

signal nave_cargada

## Cuántas cápsulas necesita la nave para despegar.
@export var helio3_necesario := 3
## Nivel al que se va cuando la nave está cargada (vacío = quedarse).
@export_file("*.tscn") var siguiente_nivel := ""

var cargado := 0

@onready var _entrada: Node3D = $Entrada


func _ready() -> void:
	body_entered.connect(_al_entrar)


func _al_entrar(cuerpo: Node3D) -> void:
	if not (cuerpo.is_in_group("vehiculo") or Interactuable.es_jugador(cuerpo)):
		return
	if cargado >= helio3_necesario:
		return
	if Juego.helio3 <= 0:
		Juego.mostrar_mensaje("La nave necesita %d cápsulas de helio-3 (tiene %d)" % [helio3_necesario, cargado])
		return
	var cantidad := mini(Juego.helio3, helio3_necesario - cargado)
	Juego.usar_helio3(cantidad)
	await _subir_capsulas(cuerpo, cantidad)
	cargado += cantidad
	if cargado >= helio3_necesario:
		Juego.mostrar_mensaje("¡Nave cargada con helio-3! Lista para despegar")
		nave_cargada.emit()
		if not siguiente_nivel.is_empty():
			await get_tree().create_timer(3.0).timeout
			Juego.cambiar_nivel(siguiente_nivel)
	else:
		Juego.mostrar_mensaje("Nave: %d/%d cápsulas de helio-3" % [cargado, helio3_necesario])


## Copias de la cápsula vuelan desde el jugador hasta la entrada de la nave.
func _subir_capsulas(cuerpo: Node3D, cantidad: int) -> void:
	var molde := load("res://scenes/objetos/capsula_helio3.tscn") as PackedScene
	for i in cantidad:
		var capsula := molde.instantiate() as Node3D
		capsula.monitoring = false
		get_tree().current_scene.add_child(capsula)
		capsula.global_position = cuerpo.global_position + Vector3.UP * 1.5
		var animacion := capsula.create_tween()
		animacion.tween_property(capsula, "global_position", _entrada.global_position, 1.0)
		animacion.tween_callback(capsula.queue_free)
		await get_tree().create_timer(0.35).timeout
	await get_tree().create_timer(1.0).timeout
