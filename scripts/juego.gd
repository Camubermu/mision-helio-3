extends Node
## Datos del juego que se comparten entre TODOS los niveles.
##
## Está cargado siempre (Autoload) con el nombre "Juego".
## Desde cualquier script se usa así:
##     Juego.agregar_regolito(1)
##     Juego.mostrar_mensaje("¡Hola!")
##     Juego.cambiar_nivel("res://scenes/niveles/mi_nivel.tscn")

signal combustible_cambio(valor: float, maximo: float)
signal energia_cambio(valor: float, maximo: float)
signal regolito_cambio(valor: int)
signal helio3_cambio(valor: int)
signal mensaje_nuevo(texto: String)
## Texto pequeño cerca de la mira, por ejemplo "Presiona E para excavar". "" lo oculta.
signal ayuda_cambio(texto: String)
## Datos de vuelo de la nave (altura, velocidad). "" lo oculta.
signal telemetria_cambio(texto: String)

const COMBUSTIBLE_MAX := 100.0
const ENERGIA_MAX := 100.0

var combustible: float = COMBUSTIBLE_MAX:
	set(valor):
		combustible = clampf(valor, 0.0, COMBUSTIBLE_MAX)
		combustible_cambio.emit(combustible, COMBUSTIBLE_MAX)

var energia: float = ENERGIA_MAX:
	set(valor):
		energia = clampf(valor, 0.0, ENERGIA_MAX)
		energia_cambio.emit(energia, ENERGIA_MAX)

var regolito: int = 0:
	set(valor):
		regolito = maxi(valor, 0)
		regolito_cambio.emit(regolito)

var helio3: int = 0:
	set(valor):
		helio3 = maxi(valor, 0)
		helio3_cambio.emit(helio3)

## Copia de los datos al empezar el nivel, para poder reiniciarlo con R.
var _al_iniciar_nivel: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_guardar_inicio_nivel()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reiniciar"):
		reiniciar_nivel()


# --- Recursos -------------------------------------------------------------

## Gasta combustible. Devuelve false si ya no queda.
func gastar_combustible(cantidad: float) -> bool:
	if combustible <= 0.0:
		return false
	combustible -= cantidad
	return true


func agregar_regolito(cantidad: int = 1) -> void:
	regolito += cantidad


## Usa regolito. Devuelve false (y no gasta nada) si no alcanza.
func usar_regolito(cantidad: int) -> bool:
	if regolito < cantidad:
		return false
	regolito -= cantidad
	return true


func agregar_helio3(cantidad: int = 1) -> void:
	helio3 += cantidad


## Usa helio-3. Devuelve false (y no gasta nada) si no alcanza.
func usar_helio3(cantidad: int) -> bool:
	if helio3 < cantidad:
		return false
	helio3 -= cantidad
	return true


func recargar_energia() -> void:
	energia = ENERGIA_MAX


# --- Pantalla -------------------------------------------------------------

func mostrar_mensaje(texto: String) -> void:
	mensaje_nuevo.emit(texto)


func mostrar_ayuda(texto: String) -> void:
	ayuda_cambio.emit(texto)


func ocultar_ayuda() -> void:
	ayuda_cambio.emit("")


func mostrar_telemetria(texto: String) -> void:
	telemetria_cambio.emit(texto)


# --- Niveles --------------------------------------------------------------

## Va a otro nivel. Ejemplo: Juego.cambiar_nivel("res://scenes/niveles/nivel_luna.tscn")
func cambiar_nivel(ruta: String) -> void:
	if ruta.is_empty() or not ResourceLoader.exists(ruta):
		push_error("No existe el nivel: '%s'" % ruta)
		mostrar_mensaje("Falta el siguiente nivel")
		return
	_limpiar_pantalla()
	_guardar_inicio_nivel()
	get_tree().change_scene_to_file.call_deferred(ruta)


## Vuelve a empezar el nivel actual con los datos que había al entrar (tecla R).
func reiniciar_nivel() -> void:
	_restaurar_inicio_nivel()
	_limpiar_pantalla()
	get_tree().reload_current_scene.call_deferred()


## Vuelve todo a cero, como al empezar el juego.
func reiniciar_datos() -> void:
	combustible = COMBUSTIBLE_MAX
	energia = ENERGIA_MAX
	regolito = 0
	helio3 = 0
	_guardar_inicio_nivel()


func _limpiar_pantalla() -> void:
	ocultar_ayuda()
	mostrar_telemetria("")


func _guardar_inicio_nivel() -> void:
	_al_iniciar_nivel = {
		"combustible": combustible,
		"energia": energia,
		"regolito": regolito,
		"helio3": helio3,
	}


func _restaurar_inicio_nivel() -> void:
	for nombre: String in _al_iniciar_nivel:
		set(nombre, _al_iniciar_nivel[nombre])
