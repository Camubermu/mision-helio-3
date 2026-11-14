class_name Extractor
extends Node3D
## Cosechadora lunar de Helio-3.
##
## Controla las animaciones del modelo y mueve la maquina de forma que las
## orugas no patinen. El frente de la maquina apunta a -Z (convencion de Godot);
## el nodo "Modelo" ya viene girado 180 grados respecto al GLB (cuyo frente es +Z).
##
## Uso rapido desde otro script:
##     $Extractor.mover(1)        # adelante
##     $Extractor.mover(-1)       # atras
##     $Extractor.mover(0)        # detenerse
##     $Extractor.girar(1.0)      # girar a la izquierda (solo mientras se mueve)
##     $Extractor.minando = true  # activar rueda de canguilones, tambor y cinta

## Se emite cada vez que cambia la animacion activa ("reposo", "avanzar", ...).
signal animacion_cambiada(nombre: String)

## Metros que avanzan las orugas en UN ciclo de la animacion (2 * PI * 0.665).
const CICLO_DISTANCIA := 4.1783
## Duracion en segundos de cada ciclo de animacion.
const CICLO_DURACION := 6.0
## Velocidad a la que la animacion de orugas coincide exactamente con el suelo.
const VELOCIDAD_BASE := CICLO_DISTANCIA / CICLO_DURACION

## Velocidad de avance en m/s. Las orugas se acompasan solas.
@export var velocidad: float = 0.696
## Velocidad de giro en rad/s.
@export var velocidad_giro: float = 0.35
## Activa/desactiva la mineria (rueda de canguilones, tambor y cinta).
@export var minando: bool = false:
	set(valor):
		minando = valor
		if is_node_ready():
			_actualizar_animacion()

## 1 = adelante, -1 = atras, 0 = quieto.
var direccion: int = 0
## 1 = izquierda, -1 = derecha, 0 = recto.
var giro: float = 0.0
## Nombre de la animacion que se esta reproduciendo.
var animacion_actual: String = ""

var _player: AnimationPlayer


func _ready() -> void:
	var jugadores := find_children("*", "AnimationPlayer", true, false)
	if jugadores.is_empty():
		push_error("Extractor: no se encontro un AnimationPlayer dentro del modelo. Revisa la importacion del .glb.")
		return
	_player = jugadores[0] as AnimationPlayer
	# Todas las animaciones estan pensadas para repetirse sin cortes.
	for nombre in _player.get_animation_list():
		if nombre != "RESET":
			_player.get_animation(nombre).loop_mode = Animation.LOOP_LINEAR
	_actualizar_animacion()


func _physics_process(delta: float) -> void:
	if direccion == 0:
		return
	# Frente = -Z local. Con direccion = -1 retrocede.
	global_translate(-global_transform.basis.z * direccion * velocidad * delta)
	if giro != 0.0:
		rotate_y(giro * velocidad_giro * delta)


## Avanza (1), retrocede (-1) o se detiene (0).
func mover(dir: int) -> void:
	direccion = clampi(dir, -1, 1)
	_actualizar_animacion()


## Gira a la izquierda (+1) o derecha (-1). Solo tiene efecto mientras la maquina se mueve.
func girar(valor: float) -> void:
	giro = clampf(valor, -1.0, 1.0)


## Detiene la maquina (no apaga la mineria).
func detener() -> void:
	giro = 0.0
	mover(0)


func _actualizar_animacion() -> void:
	if _player == null:
		return
	var nombre := "reposo"
	if direccion != 0 and minando:
		nombre = "avanzar_minando"
	elif direccion != 0:
		nombre = "avanzar"
	elif minando:
		nombre = "minar"
	if not _player.has_animation(nombre):
		push_warning("Extractor: falta la animacion '%s'" % nombre)
		return

	# Velocidad de reproduccion: acompasa las orugas con la velocidad real (negativa = marcha atras).
	var escala := 1.0
	if direccion != 0:
		escala = direccion * velocidad / VELOCIDAD_BASE

	if nombre != animacion_actual:
		# Conserva la fase del ciclo al cambiar de animacion para que no haya saltos.
		var fase := _player.current_animation_position if _player.is_playing() else 0.0
		_player.play(nombre)
		_player.seek(fase, true)
		animacion_actual = nombre
		animacion_cambiada.emit(nombre)
	_player.speed_scale = escala
