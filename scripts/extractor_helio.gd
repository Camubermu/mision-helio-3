extends Interactuable
## Máquina que calienta el regolito para sacar helio-3.
## Con E: usa regolito y da helio-3.

## Regolito que se necesita para cada carga.
@export var regolito_necesario := 3
## Helio-3 que se obtiene por cada carga.
@export var helio3_por_carga := 1


func _ready() -> void:
	super()
	if texto_ayuda == "Presiona E":
		texto_ayuda = "Presiona E para calentar regolito"


func interactuar() -> void:
	if not Juego.usar_regolito(regolito_necesario):
		var faltan := regolito_necesario - Juego.regolito
		Juego.mostrar_mensaje("Necesitas %d regolito más" % faltan)
		return
	Juego.agregar_helio3(helio3_por_carga)
	Juego.mostrar_mensaje("¡Extrajiste %d de helio-3!" % helio3_por_carga)
	actualizar_ayuda()


func obtener_texto_ayuda() -> String:
	return "%s (%d regolito → %d helio-3)" % [texto_ayuda, regolito_necesario, helio3_por_carga]
