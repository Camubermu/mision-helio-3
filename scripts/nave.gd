extends CharacterBody3D
## Módulo de aterrizaje. Espacio = propulsor (gasta combustible).
## W/S y A/D = inclinar la nave. Aterriza suave y derecha para ganar.

signal aterrizo
signal choco

## Fuerza del propulsor (la gravedad de la Luna es 1.62).
@export var empuje := 4.5
## Qué tan rápido se inclina con WASD.
@export var velocidad_giro := 1.0
## Combustible que gasta por segundo con el propulsor encendido.
@export var consumo := 6.0
## Velocidad máxima para aterrizar sin chocar (metros por segundo).
@export var velocidad_segura := 3.0
## Inclinación máxima para aterrizar sin volcar (grados).
@export var inclinacion_segura := 15.0
## Nivel al que se va después de aterrizar bien (vacío = quedarse).
@export_file("*.tscn") var siguiente_nivel := ""
## Altura del suelo, para calcular la altura de la nave.
@export var altura_suelo := 0.0
## Dónde queda la cámara respecto a la nave.
@export var distancia_camara := Vector3(0, 14, 22)

enum Estado { VOLANDO, ATERRIZADA, ESTRELLADA }

const INCLINACION_MAXIMA := deg_to_rad(60.0)

var estado := Estado.VOLANDO

@onready var _llama: MeshInstance3D = $Llama
@onready var _camara: Camera3D = $Camara


func _ready() -> void:
	add_to_group("nave")
	_llama.visible = false
	_mover_camara()


func _physics_process(delta: float) -> void:
	if estado != Estado.VOLANDO:
		return

	velocity += get_gravity() * delta

	var encendido := Input.is_action_pressed("propulsor") and Juego.gastar_combustible(consumo * delta)
	if encendido:
		velocity += global_basis.y * empuje * delta
	_llama.visible = encendido

	var giro := Input.get_vector("left", "right", "forward", "backward")
	rotation.x = clampf(rotation.x + giro.y * velocidad_giro * delta, -INCLINACION_MAXIMA, INCLINACION_MAXIMA)
	rotation.z = clampf(rotation.z - giro.x * velocidad_giro * delta, -INCLINACION_MAXIMA, INCLINACION_MAXIMA)

	var velocidad_antes := velocity
	move_and_slide()
	if get_slide_collision_count() > 0:
		_al_tocar_suelo(velocidad_antes)

	_mostrar_datos()


func _process(_delta: float) -> void:
	_mover_camara()


func inclinacion_grados() -> float:
	return rad_to_deg(global_basis.y.angle_to(Vector3.UP))


func _al_tocar_suelo(velocidad_impacto: Vector3) -> void:
	var rapidez := velocidad_impacto.length()
	velocity = Vector3.ZERO
	_llama.visible = false
	if rapidez <= velocidad_segura and inclinacion_grados() <= inclinacion_segura:
		estado = Estado.ATERRIZADA
		Juego.mostrar_mensaje("¡Alunizaje exitoso!")
		aterrizo.emit()
		_ir_al_siguiente_nivel()
	else:
		estado = Estado.ESTRELLADA
		Juego.mostrar_mensaje("¡La nave se estrelló! Presiona R para intentar otra vez")
		choco.emit()


func _ir_al_siguiente_nivel() -> void:
	if siguiente_nivel.is_empty():
		return
	await get_tree().create_timer(2.5).timeout
	Juego.cambiar_nivel(siguiente_nivel)


func _mostrar_datos() -> void:
	var altura := global_position.y - altura_suelo
	var bajada := -velocity.y
	var aviso := "  ¡MUY RÁPIDO!" if velocity.length() > velocidad_segura else ""
	Juego.mostrar_telemetria(
		"Altura: %d m\nVelocidad: %.1f m/s%s\nInclinación: %d°" % [altura, bajada, aviso, inclinacion_grados()]
	)


func _mover_camara() -> void:
	# La cámara sigue a la nave pero no se inclina con ella (así no marea).
	_camara.global_position = global_position + distancia_camara
	# Mira un poco por debajo de la nave para que se vea el suelo y la plataforma.
	_camara.look_at(global_position + Vector3(0, -10, 0), Vector3.UP)
