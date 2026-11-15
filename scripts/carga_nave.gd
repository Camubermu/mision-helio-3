extends Area3D
## Zona alrededor de la nave para cargarle las cápsulas de helio-3.
## Cuando el jugador (o el vehículo) llega con cápsulas, vuelan a la nave.
## Al juntar las necesarias, la nave queda lista: el jugador se sube con E
## y empieza el despegue (señal nave_abordada).

signal nave_cargada
signal nave_abordada

## Cuántas cápsulas necesita la nave para despegar.
@export var helio3_necesario := 3
## Nivel al que se va cuando la nave está cargada (vacío = quedarse).
@export_file("*.tscn") var siguiente_nivel := ""

var cargado := 0
var abordada := false

var _jugador_cerca := false

@onready var _entrada: Node3D = $Entrada


func _ready() -> void:
	body_entered.connect(_al_entrar)
	body_exited.connect(_al_salir)


func esta_lista() -> bool:
	return cargado >= helio3_necesario


func _unhandled_input(event: InputEvent) -> void:
	if esta_lista() and not abordada and _jugador_cerca and event.is_action_pressed("interactuar"):
		get_viewport().set_input_as_handled()
		abordada = true
		Juego.ocultar_ayuda()
		nave_abordada.emit()


func _al_salir(cuerpo: Node3D) -> void:
	if Interactuable.es_jugador(cuerpo):
		_jugador_cerca = false
		Juego.ocultar_ayuda()


func _avisar_que_puede_subir() -> void:
	if esta_lista() and not abordada and _jugador_cerca:
		Juego.mostrar_ayuda("Presiona E para subir a la nave y despegar con el motor de helio-3")


func _al_entrar(cuerpo: Node3D) -> void:
	if Interactuable.es_jugador(cuerpo):
		_jugador_cerca = true
		_avisar_que_puede_subir()
	if not (cuerpo.is_in_group("vehiculo") or Interactuable.es_jugador(cuerpo)):
		return
	if esta_lista():
		if cuerpo.is_in_group("vehiculo"):
			Juego.mostrar_mensaje("Bájate del vehículo para subir a la nave")
		return
	if Juego.helio3 <= 0:
		Juego.mostrar_mensaje("La nave necesita %d cápsulas de helio-3 (tiene %d)" % [helio3_necesario, cargado])
		return
	var cantidad := mini(Juego.helio3, helio3_necesario - cargado)
	Juego.usar_helio3(cantidad)
	await _subir_capsulas(cuerpo, cantidad)
	cargado += cantidad
	if cargado >= helio3_necesario:
		Juego.mostrar_mensaje("¡Nave cargada con helio-3! Súbete con E para probar el motor")
		nave_cargada.emit()
		_avisar_que_puede_subir()
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
