extends Node3D
## Viaje en el cohete cohete_kodland_lujo_godot, en tres partes:
##   1. Despegue visto desde afuera (scripts/cinematica_cohete.gd).
##   2. Viaje sentado en la cabina: en la pantalla curva se ve el destino acercándose
##      y en el monitor el jugador revisa combustibles, motores, daños y navegación
##      con las teclas 1-4 (o clic).
##   3. Alunizaje o aterrizaje visto desde afuera.
##
## La historia: se despega de la base (level 1) con el motor químico de llama azul,
## que falla al salir de la atmósfera. Se viaja y se aluniza solo con el motor de
## plasma de helio-3, pero no alcanza para volver: hay que producir helio-3 en la Luna
## y probar el motor de helio-3 también para despegar.
##
## Hijos: Cohete, Asiento/Camara, LuzAlarma y Cinematica.
## Espacio = saltar la parte actual (sirve para probar rápido).

signal terminado
signal _fin_cabina

const Datos = preload("res://scripts/datos_viaje.gd")
const MonitorCabina = preload("res://scripts/monitor_cabina.gd")

enum Destino { LUNA, TIERRA }

## Segundos que dura el viaje en la cabina.
@export var duracion := 35.0
## Segundo del viaje a la Luna en que se avisa el cambio de plan.
@export var momento_cambio_plan := 15.0
## Sensibilidad del mouse para mirar dentro de la cabina.
@export var sensibilidad_mouse := 0.15
## Nombre de la pieza del cohete donde se ve el destino.
@export var nombre_pantalla := "Pantalla_curva"
## Nombre de la pieza del cohete donde está el monitor con botones.
@export var nombre_monitor := "Monitor_pantalla"

var viajando := false
var destino := Destino.LUNA

var _tiempo := 0.0
var _plan_cambiado := false
var _alarma_hasta := 0.0
var _vista: SubViewport
var _camara_vista: Camera3D
var _planeta: MeshInstance3D
var _nubes: MeshInstance3D
var _monitor: MonitorCabina
var _datos_vista: Label
var _curiosidad: Label
var _barra: ColorRect
var _marca: ColorRect
var _giro_base := Vector3.ZERO
## Panel de comunicaciones con la Tierra (scripts/comunicaciones_cabina.gd).
var _comunicaciones: Node
var _mirar := Vector2.ZERO

@onready var _asiento: Node3D = $Asiento
@onready var _camara: Camera3D = $Asiento/Camara
@onready var _alarma: OmniLight3D = $LuzAlarma
@onready var _cohete: Node3D = $Cohete
@onready var _cinematica: Node = $Cinematica
@onready var _cabina: Node = get_node_or_null("CabinaRealista")
@onready var _brazos: Node = get_node_or_null("Asiento/Camara/Brazos")


func _ready() -> void:
	_crear_vista_espacio()
	_monitor = MonitorCabina.new()
	add_child(_monitor)
	_poner_en_pieza(nombre_pantalla, _vista)
	_poner_en_pieza(nombre_monitor, _monitor)
	_mirar_a_la_pantalla()
	_alarma.light_energy = 0.0
	_comunicaciones = load("res://scripts/comunicaciones_cabina.gd").new()
	add_child(_comunicaciones)
	_comunicaciones.configurar(_cabina._pitar if _cabina else Callable(), _tocar_monitor)
	set_process(false)


## Verdadero mientras se habla con la Tierra (el viaje se detiene).
func comunicando() -> bool:
	return _comunicaciones != null and _comunicaciones.activa


## Empieza el viaje completo hacia la Luna o hacia la Tierra.
func empezar(nuevo_destino: Destino) -> void:
	destino = nuevo_destino
	var hacia_la_luna := destino == Destino.LUNA
	Juego.mostrar_telemetria("")
	if hacia_la_luna:
		Juego.mostrar_mensaje("Fase 2: despegue desde la base con el motor químico")
		await _cinematica.despegar_de_la_tierra()
	else:
		Juego.mostrar_mensaje("Fase 5: prueba del motor de helio-3 para despegar de la Luna")
		await _cinematica.despegar_de_la_luna()
	if not is_inside_tree():
		return

	_empezar_cabina()
	await _fin_cabina

	if hacia_la_luna:
		Juego.mostrar_mensaje("Alunizaje solo con el motor de helio-3...")
		await _cinematica.alunizar()
	else:
		Juego.mostrar_mensaje("Aterrizando en la base con el motor de helio-3...")
		await _cinematica.aterrizar_en_la_tierra()
	if not is_inside_tree():
		return
	terminado.emit()


func _empezar_cabina() -> void:
	_tiempo = 0.0
	_plan_cambiado = false
	viajando = true
	_preparar_planeta()
	_vista.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_monitor.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_mirar = Vector2.ZERO
	_aplicar_mirada()
	_camara.make_current()
	if destino == Destino.LUNA:
		_monitor.cambiar(MonitorCabina.Pagina.DANOS)
		_alarma_hasta = 6.0
		Juego.mostrar_mensaje("El motor químico falló. Seguimos con el motor de plasma de helio-3. Teclas 1-4: revisa el monitor")
	else:
		_monitor.cambiar(MonitorCabina.Pagina.MOTORES)
		_alarma_hasta = 0.0
		Juego.mostrar_mensaje("¡El motor de helio-3 funcionó! Rumbo a casa. Teclas 1-4: revisa el monitor")
	if _cabina:
		_cabina.empezar(destino == Destino.LUNA, momento_cambio_plan)
	set_process(true)
	if destino == Destino.LUNA:
		# Control de Misión llama por radio al rato de la falla.
		var llamada := create_tween()
		llamada.tween_interval(2.0)
		llamada.tween_callback(func():
			if viajando:
				_comunicaciones.empezar_falla())


## Verdadero mientras suena la alarma de la cabina.
func alarma_activa() -> bool:
	return viajando and _tiempo < _alarma_hasta


func _process(delta: float) -> void:
	# Mientras se habla con la Tierra, el viaje no avanza.
	if not comunicando():
		_tiempo += delta
	var avance := clampf(_tiempo / duracion, 0.0, 1.0)
	# El destino se acerca cada vez más rápido.
	_camara_vista.position.z = lerpf(10.0, 1.75, ease(avance, 1.6))
	_planeta.rotate_y(delta * 0.04)
	if _nubes:
		_nubes.rotate_y(delta * 0.06)

	if destino == Destino.LUNA and not _plan_cambiado and _tiempo >= momento_cambio_plan:
		_cambiar_plan()
	_monitor.dibujar(destino == Destino.LUNA, avance, _tiempo)
	_actualizar_vista(avance)
	_animar_alarma()

	if avance >= 1.0:
		_terminar()


func _unhandled_input(event: InputEvent) -> void:
	if not viajando:
		return
	if comunicando():
		# Con el panel abierto el mouse es para elegir respuestas. Espacio igual salta el viaje.
		if event.is_action_pressed("propulsor"):
			get_viewport().set_input_as_handled()
			_terminar()
		elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_4:
			_monitor.cambiar((event.physical_keycode - KEY_1) as MonitorCabina.Pagina)
		return
	if event is InputEventMouseMotion:
		_mirar.x = clampf(_mirar.x - event.relative.x * sensibilidad_mouse, -75.0, 75.0)
		_mirar.y = clampf(_mirar.y - event.relative.y * sensibilidad_mouse, -45.0, 45.0)
		_aplicar_mirada()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_monitor.siguiente()
		_tocar_monitor()
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_4:
		_monitor.cambiar((event.physical_keycode - KEY_1) as MonitorCabina.Pagina)
		_tocar_monitor()
	elif event.is_action_pressed("propulsor"):
		get_viewport().set_input_as_handled()
		_terminar()


## Al empezar, el pasajero mira de frente a la pantalla curva.
func _mirar_a_la_pantalla() -> void:
	var pieza := _cohete.find_child(nombre_pantalla, true, false) as MeshInstance3D
	if pieza:
		var centro := pieza.global_transform * pieza.get_aabb().get_center()
		_asiento.look_at(centro, Vector3.UP)
	_giro_base = _asiento.rotation


## El mouse gira la cabeza a partir de la posición de frente a la pantalla.
func _aplicar_mirada() -> void:
	_asiento.rotation = Vector3(0, _giro_base.y + deg_to_rad(_mirar.x), 0)
	_camara.rotation = Vector3(_giro_base.x + deg_to_rad(_mirar.y), 0, 0)


## La mano del astronauta se estira y toca el monitor.
func _tocar_monitor() -> void:
	var pieza := _cohete.find_child(nombre_monitor, true, false) as MeshInstance3D
	if _brazos and pieza:
		_brazos.alcanzar(pieza.global_transform * pieza.get_aabb().get_center())


func _cambiar_plan() -> void:
	_plan_cambiado = true
	_alarma_hasta = _tiempo + 4.0
	_monitor.cambiar(MonitorCabina.Pagina.COMBUSTIBLE)
	Juego.mostrar_mensaje("CAMBIO DE PLAN: el helio-3 solo alcanza para alunizar. Habrá que producirlo en la Luna")
	_comunicaciones.empezar_cambio_de_plan()


func _animar_alarma() -> void:
	if _tiempo >= _alarma_hasta:
		_alarma.light_energy = 0.0
		_camara.h_offset = 0.0
		_camara.v_offset = 0.0
		return
	var pulso := sin(_tiempo * 7.0) * 0.5 + 0.5
	_alarma.light_energy = pulso * 3.0
	_camara.h_offset = randf_range(-1, 1) * 0.006
	_camara.v_offset = randf_range(-1, 1) * 0.006


func _terminar() -> void:
	if not viajando:
		return
	viajando = false
	set_process(false)
	_comunicaciones.cerrar()
	_alarma.light_energy = 0.0
	_camara.h_offset = 0.0
	_camara.v_offset = 0.0
	_vista.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_monitor.render_target_update_mode = SubViewport.UPDATE_DISABLED
	if _cabina:
		_cabina.terminar()
	_fin_cabina.emit()


# --- Vista del espacio en la pantalla curva -------------------------------

func _crear_vista_espacio() -> void:
	_vista = SubViewport.new()
	_vista.size = Vector2i(1200, 300)
	_vista.own_world_3d = true
	_vista.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(_vista)

	var ambiente := WorldEnvironment.new()
	ambiente.environment = Environment.new()
	ambiente.environment.background_mode = Environment.BG_COLOR
	ambiente.environment.background_color = Color(0, 0, 0.01)
	ambiente.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ambiente.environment.ambient_light_color = Color(0.08, 0.09, 0.12)
	_vista.add_child(ambiente)

	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-15, -60, 0)
	sol.light_energy = 1.4
	_vista.add_child(sol)

	_camara_vista = Camera3D.new()
	_camara_vista.fov = 32.0
	_camara_vista.position = Vector3(0, 0, 10)
	_vista.add_child(_camara_vista)

	_planeta = MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radial_segments = 64
	esfera.rings = 32
	_planeta.mesh = esfera
	_planeta.rotation_degrees.z = 12.0
	_vista.add_child(_planeta)

	_vista.add_child(_crear_estrellas())
	_crear_datos_en_vista()


## Letreros encima de la vista: velocidad, llegada, barra de avance y curiosidades.
func _crear_datos_en_vista() -> void:
	_datos_vista = Label.new()
	_datos_vista.position = Vector2(24, 12)
	_datos_vista.size = Vector2(1152, 40)
	_datos_vista.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_datos_vista.add_theme_font_size_override("font_size", 26)
	_datos_vista.add_theme_color_override("font_color", Color(0.55, 0.95, 1.0))
	_vista.add_child(_datos_vista)

	_barra = ColorRect.new()
	_barra.color = Color(0.4, 0.8, 1.0, 0.35)
	_barra.position = Vector2(130, 222)
	_barra.size = Vector2(940, 4)
	_vista.add_child(_barra)
	_marca = ColorRect.new()
	_marca.color = Color(0.5, 1.0, 1.0)
	_marca.size = Vector2(14, 14)
	_vista.add_child(_marca)
	for i in 2:
		var punta := Label.new()
		punta.name = "Punta%d" % i
		punta.position = Vector2(30 if i == 0 else 1085, 208)
		punta.add_theme_font_size_override("font_size", 22)
		_vista.add_child(punta)

	_curiosidad = Label.new()
	_curiosidad.position = Vector2(0, 246)
	_curiosidad.size = Vector2(1200, 50)
	_curiosidad.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_curiosidad.add_theme_font_size_override("font_size", 24)
	_curiosidad.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	_vista.add_child(_curiosidad)


func _actualizar_vista(avance: float) -> void:
	var hacia_la_luna := destino == Destino.LUNA
	_datos_vista.text = "VELOCIDAD %s km/h      LLEGADA EN %s      DISTANCIA %s km" % [
		Datos.con_puntos(Datos.velocidad(hacia_la_luna, avance)),
		Datos.falta(avance),
		Datos.con_puntos(Datos.distancia(avance)),
	]
	(_vista.get_node("Punta0") as Label).text = "TIERRA" if hacia_la_luna else "LUNA"
	(_vista.get_node("Punta1") as Label).text = "LUNA" if hacia_la_luna else "TIERRA"
	_marca.position = Vector2(_barra.position.x + _barra.size.x * avance - 7, 217)
	_curiosidad.text = Datos.curiosidad(hacia_la_luna, _tiempo)


func _preparar_planeta() -> void:
	if _nubes:
		_nubes.queue_free()
		_nubes = null
	if destino == Destino.LUNA:
		_planeta.material_override = _material_luna()
	else:
		_planeta.material_override = _material_tierra()
		_nubes = MeshInstance3D.new()
		var esfera := SphereMesh.new()
		esfera.radius = 0.51
		esfera.height = 1.02
		esfera.radial_segments = 64
		esfera.rings = 32
		_nubes.mesh = esfera
		_nubes.material_override = _material_nubes()
		_planeta.add_child(_nubes)


static func _material_luna() -> StandardMaterial3D:
	var ruido := FastNoiseLite.new()
	ruido.noise_type = FastNoiseLite.TYPE_CELLULAR
	ruido.frequency = 0.03
	ruido.fractal_octaves = 3
	var grises := Gradient.new()
	grises.colors = PackedColorArray([Color(0.25, 0.25, 0.26), Color(0.62, 0.61, 0.58)])
	var color := NoiseTexture2D.new()
	color.width = 1024
	color.height = 512
	color.seamless = true
	color.noise = ruido
	color.color_ramp = grises
	var relieve := NoiseTexture2D.new()
	relieve.width = 1024
	relieve.height = 512
	relieve.seamless = true
	relieve.noise = ruido
	relieve.as_normal_map = true
	relieve.bump_strength = 6.0
	var material := StandardMaterial3D.new()
	material.albedo_texture = color
	material.normal_enabled = true
	material.normal_texture = relieve
	material.roughness = 1.0
	return material


static func _material_tierra() -> StandardMaterial3D:
	var ruido := FastNoiseLite.new()
	ruido.frequency = 0.006
	ruido.fractal_octaves = 5
	var colores := Gradient.new()
	colores.offsets = PackedFloat32Array([0.0, 0.52, 0.55, 0.62, 0.78, 1.0])
	colores.colors = PackedColorArray([
		Color(0.02, 0.08, 0.3), Color(0.06, 0.25, 0.6), Color(0.76, 0.7, 0.5),
		Color(0.2, 0.5, 0.18), Color(0.12, 0.32, 0.12), Color(0.95, 0.95, 0.97),
	])
	var textura := NoiseTexture2D.new()
	textura.width = 1024
	textura.height = 512
	textura.seamless = true
	textura.noise = ruido
	textura.color_ramp = colores
	var material := StandardMaterial3D.new()
	material.albedo_texture = textura
	material.roughness = 0.7
	return material


static func _material_nubes() -> StandardMaterial3D:
	var ruido := FastNoiseLite.new()
	ruido.frequency = 0.012
	ruido.fractal_octaves = 4
	ruido.seed = 7
	var nubes := Gradient.new()
	nubes.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	nubes.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 0), Color(1, 1, 1, 0.85)])
	var textura := NoiseTexture2D.new()
	textura.width = 1024
	textura.height = 512
	textura.seamless = true
	textura.noise = ruido
	textura.color_ramp = nubes
	var material := StandardMaterial3D.new()
	material.albedo_texture = textura
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material


static func _crear_estrellas() -> MultiMeshInstance3D:
	var punto := SphereMesh.new()
	punto.radius = 0.06
	punto.height = 0.12
	punto.radial_segments = 4
	punto.rings = 2
	var blanco := StandardMaterial3D.new()
	blanco.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	blanco.albedo_color = Color(1, 1, 1)
	punto.material = blanco
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = punto
	multi.instance_count = 500
	var azar := RandomNumberGenerator.new()
	azar.seed = 42
	for i in multi.instance_count:
		var direccion := Vector3(azar.randf_range(-1, 1), azar.randf_range(-1, 1), azar.randf_range(-1, 1)).normalized()
		var tamano := azar.randf_range(0.5, 1.6)
		multi.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * tamano), direccion * 60.0))
	var estrellas := MultiMeshInstance3D.new()
	estrellas.multimesh = multi
	return estrellas


## Pone lo que se ve en una SubViewport sobre una pieza del cohete (como una pantalla).
func _poner_en_pieza(nombre: String, vista: SubViewport) -> void:
	var pieza := _cohete.find_child(nombre, true, false) as MeshInstance3D
	if pieza == null:
		push_warning("No encontré la pieza '%s' en el cohete" % nombre)
		return
	var material := StandardMaterial3D.new()
	material.albedo_texture = vista.get_texture()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pieza.material_override = material
