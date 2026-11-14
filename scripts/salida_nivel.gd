extends Area3D
## Zona que lleva al siguiente nivel cuando el jugador entra.

## El nivel al que se va (elige el archivo .tscn en el Inspector).
@export_file("*.tscn") var siguiente_nivel := ""
## Helio-3 que hay que tener para poder salir (0 = no hace falta).
@export var helio3_necesario := 0
## Si está activo, hay que recargar el reactor (energía llena) antes de salir.
@export var necesita_energia_llena := false


func _ready() -> void:
	body_entered.connect(_al_entrar)


func _al_entrar(cuerpo: Node3D) -> void:
	if not Interactuable.es_jugador(cuerpo):
		return
	if Juego.helio3 < helio3_necesario:
		Juego.mostrar_mensaje("Necesitas %d de helio-3 para seguir" % helio3_necesario)
		return
	if necesita_energia_llena and Juego.energia < Juego.ENERGIA_MAX:
		Juego.mostrar_mensaje("Primero recarga el reactor")
		return
	Juego.cambiar_nivel(siguiente_nivel)
