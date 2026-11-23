extends CharacterBody3D
## Vehículo que el jugador maneja con la cámara en tercera persona.
## Súbete con E (zona PuntoSubir), maneja con W/S y A/D, gira la cámara con el mouse, bájate con E.
##
## Nodos que necesita: Pivote/Brazo/Camara (la cámara detrás del vehículo) y PuntoBajada
## (dónde aparece el jugador al bajarse). El modelo 3D va dentro de "Modelo".

## Velocidad máxima hacia adelante (metros por segundo).
@export var velocidad_maxima := 6.0
## Qué tan rápido acelera y frena.
@export var aceleracion := 4.0
## Qué tan rápido gira con A/D (radianes por segundo).
@export var velocidad_giro := 1.0

@export_group("Cámara")
## Qué tan lejos queda la cámara detrás del vehículo (metros).
@export var distancia_camara := 16.0
## Inclinación inicial de la cámara (grados, negativo = mira desde arriba).
@export var inclinacion_camara := -18.0
## Sensibilidad del mouse para girar la cámara.
@export var sensibilidad_mouse := 0.2
## Qué tan fuerte tiembla al excavar (0 = nada, 1 = normal, 2 = el doble).
@export var fuerza_vibracion := 1.0

@export_group("Animación")
## Nombres de las piezas del modelo que son orugas (su textura se mueve al avanzar).
@export var orugas: PackedStringArray = ["Oruga_Derecha", "Oruga_Izquierda"]
## Piezas que giran mientras alguien maneja. El valor dice el eje de giro
## y su largo las vueltas por segundo: Vector3(0.3, 0, 0) = 0.3 vueltas en el eje X.
@export var piezas_que_giran: Dictionary = {
	"Rueda_Cangilones": Vector3(0.35, 0, 0),
	"Tambor_Calentador": Vector3(0, 0, 0.15),
}

var conduciendo := false
## Qué tan fuerte tiembla el vehículo (0 = nada, 1 = mucho). Lo usa la Excavadora.
var vibracion := 0.0
## Multiplica la velocidad de las piezas que giran. Lo usa la Excavadora.
var ritmo_piezas := 1.0
## Texto que se agrega a la telemetría (por ejemplo, la carga de regolito).
var texto_extra := ""

var _jugador: Node3D
var _rapidez := 0.0
var _giro := 0.0
## Cada oruga con su material y su posición a los lados (x).
var _orugas: Array[Dictionary] = []
var _piezas_que_giran: Array[Dictionary] = []
var _posicion_modelo := Vector3.ZERO

@onready var _pivote: Node3D = $Pivote
@onready var _brazo: SpringArm3D = $Pivote/Brazo
@onready var _camara: Camera3D = $Pivote/Brazo/Camara
@onready var _bajada: Node3D = $PuntoBajada
@onready var _modelo: Node3D = $Modelo


func _ready() -> void:
	add_to_group("vehiculo")
	_posicion_modelo = _modelo.position
	# El brazo de la cámara se acorta si choca con rocas, pero no con el propio vehículo.
	_brazo.add_excluded_object(get_rid())
	_brazo.spring_length = distancia_camara
	_preparar_orugas()
	_preparar_piezas_que_giran()


func _physics_process(delta: float) -> void:
	# Estacionado se queda quieto: así no se hunde si el suelo de lejos aún no está armado
	# (por ejemplo, un terreno grande que solo arma el suelo cerca del jugador).
	if not conduciendo and is_zero_approx(_rapidez):
		velocity = Vector3.ZERO
		return
	if not is_on_floor():
		velocity += get_gravity() * delta

	var avance := 0.0
	_giro = 0.0
	if conduciendo:
		var mando := Input.get_vector("left", "right", "forward", "backward")
		avance = -mando.y
		_giro = -mando.x * velocidad_giro

	_rapidez = move_toward(_rapidez, avance * velocidad_maxima, aceleracion * delta)
	rotate_y(_giro * delta)

	var adelante := -global_basis.z
	velocity.x = adelante.x * _rapidez
	velocity.z = adelante.z * _rapidez
	move_and_slide()

	if conduciendo:
		Juego.mostrar_telemetria("Speed: %d km/h\n%sE to get out" % [absf(_rapidez * 3.6), texto_extra])


func _process(delta: float) -> void:
	_animar_orugas(delta)
	if conduciendo:
		for pieza in _piezas_que_giran:
			var eje: Vector3 = pieza.eje
			(pieza.nodo as Node3D).rotate_object_local(eje.normalized(), TAU * eje.length() * ritmo_piezas * delta)
	_temblar()


func _unhandled_input(event: InputEvent) -> void:
	if not conduciendo:
		return
	if event is InputEventMouseMotion:
		_pivote.rotation.y -= deg_to_rad(event.relative.x * sensibilidad_mouse)
		_brazo.rotation.x = clampf(_brazo.rotation.x - deg_to_rad(event.relative.y * sensibilidad_mouse), deg_to_rad(-70), deg_to_rad(5))
	elif event.is_action_pressed("interactuar"):
		get_viewport().set_input_as_handled()
		bajar()


## Sube al jugador: lo esconde, lo apaga y pasa a la cámara del vehículo.
func subir(jugador: Node3D) -> void:
	if conduciendo:
		return
	_jugador = jugador
	conduciendo = true
	jugador.visible = false
	# Apagado deja de moverse, de mirar con el mouse y de chocar.
	jugador.process_mode = Node.PROCESS_MODE_DISABLED
	_pivote.rotation = Vector3.ZERO
	_brazo.rotation = Vector3(deg_to_rad(inclinacion_camara), 0, 0)
	_camara.make_current()
	Juego.ocultar_ayuda()
	Juego.mostrar_mensaje("W/S drive · A/D turn · Mouse camera · E get out")


## Baja al jugador al lado del vehículo y le devuelve su cámara.
func bajar() -> void:
	if not conduciendo:
		return
	conduciendo = false
	vibracion = 0.0
	Juego.mostrar_telemetria("")
	if not is_instance_valid(_jugador):
		return
	_jugador.global_position = _bajada.global_position
	_jugador.global_rotation = Vector3(0, global_rotation.y, 0)
	if _jugador is CharacterBody3D:
		(_jugador as CharacterBody3D).velocity = Vector3.ZERO
	_jugador.process_mode = Node.PROCESS_MODE_INHERIT
	_jugador.visible = true
	var camaras := _jugador.find_children("*", "Camera3D", true, false)
	if not camaras.is_empty():
		(camaras[0] as Camera3D).make_current()
	_jugador = null


# --- Animación ------------------------------------------------------------

## Mueve un poco el modelo y la cámara al azar cuando hay vibración.
func _temblar() -> void:
	if vibracion <= 0.0:
		_modelo.position = _posicion_modelo
		_camara.h_offset = 0.0
		_camara.v_offset = 0.0
		return
	var fuerza := vibracion * fuerza_vibracion
	var azar := Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1))
	_modelo.position = _posicion_modelo + azar * 0.012 * fuerza
	_camara.h_offset = randf_range(-1, 1) * 0.025 * fuerza
	_camara.v_offset = randf_range(-1, 1) * 0.025 * fuerza


## Las orugas no tienen textura, así que les ponemos franjas que se puedan mover.
func _preparar_orugas() -> void:
	for nombre in orugas:
		var malla := _modelo.find_child(nombre, true, false) as MeshInstance3D
		if malla == null:
			continue
		var material := _crear_material_oruga()
		malla.material_override = material
		var centro := global_transform.affine_inverse() * (malla.global_transform * malla.get_aabb().get_center())
		_orugas.append({"material": material, "x": centro.x})


func _preparar_piezas_que_giran() -> void:
	for nombre in piezas_que_giran:
		var nodo := _modelo.find_child(nombre, true, false) as Node3D
		var eje: Vector3 = piezas_que_giran[nombre]
		if nodo and not eje.is_zero_approx():
			_piezas_que_giran.append({"nodo": nodo, "eje": eje})


func _animar_orugas(delta: float) -> void:
	var avance := get_real_velocity().dot(-global_basis.z)
	for oruga in _orugas:
		# Al girar, una oruga va más rápido que la otra (como un tanque).
		var rapidez_oruga: float = avance + _giro * oruga.x
		var material: StandardMaterial3D = oruga.material
		material.uv1_offset.z = fposmod(material.uv1_offset.z - rapidez_oruga * material.uv1_scale.z * delta, 1.0)


static func _crear_material_oruga() -> StandardMaterial3D:
	var franjas := Gradient.new()
	franjas.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	franjas.offsets = PackedFloat32Array([0.0, 0.5])
	franjas.colors = PackedColorArray([Color(0.14, 0.14, 0.15), Color(0.34, 0.34, 0.36)])
	var textura := GradientTexture2D.new()
	textura.gradient = franjas
	textura.width = 32
	textura.height = 32
	textura.fill_to = Vector2(1, 1)
	var material := StandardMaterial3D.new()
	material.albedo_texture = textura
	material.uv1_triplanar = true
	material.uv1_scale = Vector3.ONE * 2.5
	material.roughness = 0.9
	return material
