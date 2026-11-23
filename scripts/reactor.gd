extends Interactuable
## Reactor de fusión de la nave. Con E y suficiente helio-3, se recarga la energía.

signal reactor_cargado

## Helio-3 que se necesita para recargar.
@export var helio3_necesario := 3

@onready var _nucleo: MeshInstance3D = $Nucleo

var cargado := false


func _ready() -> void:
	super()
	if texto_ayuda == "Press E":
		texto_ayuda = "Press E to refuel the reactor"
	# Copia del material para que cada reactor brille por separado.
	_nucleo.material_override = _nucleo.material_override.duplicate()


func interactuar() -> void:
	if cargado:
		Juego.mostrar_mensaje("The reactor is already fueled")
		return
	if not Juego.usar_helio3(helio3_necesario):
		var faltan := helio3_necesario - Juego.helio3
		Juego.mostrar_mensaje("You need %d more helium-3" % faltan)
		return
	cargado = true
	Juego.recargar_energia()
	Juego.mostrar_mensaje("Reactor refueled! The plasma engine has power")
	var material := _nucleo.material_override as StandardMaterial3D
	material.emission_energy_multiplier = 4.0
	reactor_cargado.emit()
	actualizar_ayuda()


func obtener_texto_ayuda() -> String:
	if cargado:
		return "Reactor fueled"
	return "%s (needs %d helium-3)" % [texto_ayuda, helio3_necesario]
