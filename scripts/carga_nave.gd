extends Area3D
## Zona alrededor de la nave para cargarle las cápsulas de helio-3.
## Cuando el jugador (o el vehículo) llega con cápsulas, vuelan a la nave.
## Al juntar las necesarias, la nave queda lista: el jugador se sube con E
## y empieza el despegue (señal nave_abordada).

signal nave_cargada
signal nave_abordada

## Cuántas cápsulas necesita la nave para despegar.
@export var helio3_necesario := 3
## Si es verdadero, el jugador sube a la nave con E dentro de esta zona.
## Si es falso, sube por otro lado (por ejemplo, la escalera de la plataforma).
@export var abordar_con_e := true
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
	if abordar_con_e and esta_lista() and not abordada and _jugador_cerca and event.is_action_pressed("interactuar"):
		get_viewport().set_input_as_handled()
		abordada = true
		Juego.ocultar_ayuda()
		nave_abordada.emit()


func _al_salir(cuerpo: Node3D) -> void:
	if Interactuable.es_jugador(cuerpo):
		_jugador_cerca = false
		Juego.ocultar_ayuda()


func _avisar_que_puede_subir() -> void:
	if abordar_con_e and esta_lista() and not abordada and _jugador_cerca:
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
		if abordar_con_e:
			Juego.mostrar_mensaje("¡Nave cargada con helio-3! Súbete con E para probar el motor")
		else:
			Juego.mostrar_mensaje("¡Nave cargada con helio-3! Sube por la escalera de la torre (E al pie de la escalera)")
		nave_cargada.emit()
		_avisar_que_puede_subir()
		if not siguiente_nivel.is_empty():
			await _esperar(3.0)
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
		await _esperar(0.35)
	await _esperar(1.0)


## Espera unos segundos. Si la escena se reinicia (tecla R), la espera se cancela sola.
func _esperar(segundos: float) -> Signal:
	var espera := create_tween()
	espera.tween_interval(segundos)
	return espera.finished
