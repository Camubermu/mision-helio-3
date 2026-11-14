extends CanvasLayer
## Pantalla de datos: combustible, energía, regolito, helio-3, mensajes y ayuda.
## Ponla en cualquier nivel (arrastra scenes/ui/hud.tscn) y se actualiza sola.

## Muestra la cruz del centro (útil en primera persona; apágala en el nivel de la nave).
@export var mostrar_mira := true
## Segundos que se ve un mensaje.
@export var duracion_mensaje := 3.0

@onready var _barra_combustible: ProgressBar = $Panel/Datos/FilaCombustible/Barra
@onready var _barra_energia: ProgressBar = $Panel/Datos/FilaEnergia/Barra
@onready var _regolito: Label = $Panel/Datos/Regolito
@onready var _helio3: Label = $Panel/Datos/Helio3
@onready var _mira: Label = $Mira
@onready var _ayuda: Label = $Ayuda
@onready var _mensaje: Label = $Mensaje
@onready var _telemetria: Label = $Telemetria
@onready var _temporizador: Timer = $TemporizadorMensaje


func _ready() -> void:
	_mira.visible = mostrar_mira
	_ayuda.visible = false
	_mensaje.visible = false
	_telemetria.visible = false

	Juego.combustible_cambio.connect(_al_cambiar_combustible)
	Juego.energia_cambio.connect(_al_cambiar_energia)
	Juego.regolito_cambio.connect(_al_cambiar_regolito)
	Juego.helio3_cambio.connect(_al_cambiar_helio3)
	Juego.mensaje_nuevo.connect(_al_recibir_mensaje)
	Juego.ayuda_cambio.connect(_al_cambiar_ayuda)
	Juego.telemetria_cambio.connect(_al_cambiar_telemetria)
	_temporizador.timeout.connect(_ocultar_mensaje)

	# Muestra los valores actuales al entrar al nivel.
	_al_cambiar_combustible(Juego.combustible, Juego.COMBUSTIBLE_MAX)
	_al_cambiar_energia(Juego.energia, Juego.ENERGIA_MAX)
	_al_cambiar_regolito(Juego.regolito)
	_al_cambiar_helio3(Juego.helio3)


func _al_cambiar_combustible(valor: float, maximo: float) -> void:
	_barra_combustible.max_value = maximo
	_barra_combustible.value = valor


func _al_cambiar_energia(valor: float, maximo: float) -> void:
	_barra_energia.max_value = maximo
	_barra_energia.value = valor


func _al_cambiar_regolito(valor: int) -> void:
	_regolito.text = "Regolito: %d" % valor


func _al_cambiar_helio3(valor: int) -> void:
	_helio3.text = "Helio-3: %d" % valor


func _al_recibir_mensaje(texto: String) -> void:
	_mensaje.text = texto
	_mensaje.visible = true
	_temporizador.start(duracion_mensaje)


func _ocultar_mensaje() -> void:
	_mensaje.visible = false


func _al_cambiar_ayuda(texto: String) -> void:
	_ayuda.text = texto
	_ayuda.visible = not texto.is_empty()


func _al_cambiar_telemetria(texto: String) -> void:
	_telemetria.text = texto
	_telemetria.visible = not texto.is_empty()
