class_name Interactuable
extends Area3D
## Base para cualquier objeto que el jugador usa con la tecla E.
##
## Cuando el jugador entra en la zona (la CollisionShape3D de este nodo),
## aparece la ayuda en pantalla. Si presiona E, se llama a interactuar().
##
## Para hacer un objeto nuevo:
##     extends Interactuable
##     func interactuar() -> void:
##         Juego.mostrar_mensaje("¡Me usaste!")

## Texto que aparece cuando el jugador está cerca.
@export var texto_ayuda := "Presiona E"

var jugador_cerca := false


func _ready() -> void:
	body_entered.connect(_al_entrar)
	body_exited.connect(_al_salir)


func _unhandled_input(event: InputEvent) -> void:
	if jugador_cerca and event.is_action_pressed("interactuar"):
		get_viewport().set_input_as_handled()
		interactuar()


## Lo que pasa al presionar E. Cada objeto lo cambia a su manera.
func interactuar() -> void:
	pass


## El texto de ayuda. Un objeto lo puede cambiar (por ejemplo, para mostrar cuánto falta).
func obtener_texto_ayuda() -> String:
	return texto_ayuda


## Vuelve a escribir la ayuda (úsalo después de que algo cambie).
func actualizar_ayuda() -> void:
	if jugador_cerca:
		Juego.mostrar_ayuda(obtener_texto_ayuda())


## Quita el objeto del nivel y limpia la ayuda.
func desaparecer() -> void:
	if jugador_cerca:
		Juego.ocultar_ayuda()
	jugador_cerca = false
	queue_free()


static func es_jugador(cuerpo: Node) -> bool:
	return cuerpo is CharacterBody3D and not cuerpo.is_in_group("nave")


func _al_entrar(cuerpo: Node3D) -> void:
	if es_jugador(cuerpo):
		jugador_cerca = true
		actualizar_ayuda()


func _al_salir(cuerpo: Node3D) -> void:
	if es_jugador(cuerpo):
		jugador_cerca = false
		Juego.ocultar_ayuda()
