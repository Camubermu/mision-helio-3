extends Node3D
## Escena de demostracion: suelo lunar, sol, camara orbital y la cosechadora.
##
## Controles:
##   W / Flecha arriba      avanzar
##   S / Flecha abajo       retroceder
##   A,D / Flechas lado     girar (mientras se mueve)
##   Espacio                activar / desactivar mineria
##   Raton (arrastrar)      orbitar camara
##   Rueda del raton        acercar / alejar

const RUTA_EXTRACTOR := "res://models/extractor/extractor.tscn"

var extractor: Extractor
var camara: Camera3D
var etiqueta: Label
var _yaw := 0.6
var _pitch := 0.32
var _dist := 16.0


func _ready() -> void:
	_crear_entorno()
	_crear_suelo()
	_crear_rocas()
	extractor = (load(RUTA_EXTRACTOR) as PackedScene).instantiate() as Extractor
	add_child(extractor)
	camara = Camera3D.new()
	camara.far = 800.0
	camara.fov = 50.0
	add_child(camara)
	camara.make_current()
	_crear_hud()


func _physics_process(_delta: float) -> void:
	var adelante := Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W)
	var atras := Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S)
	var izq := Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A)
	var der := Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D)
	extractor.mover(int(adelante) - int(atras))
	extractor.girar(float(int(izq) - int(der)))


func _unhandled_input(evento: InputEvent) -> void:
	if evento is InputEventKey and evento.pressed and not evento.echo and evento.keycode == KEY_SPACE:
		extractor.minando = not extractor.minando
	elif evento is InputEventMouseMotion and (evento.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		_yaw -= evento.relative.x * 0.005
		_pitch = clampf(_pitch + evento.relative.y * 0.005, 0.05, 1.45)
	elif evento is InputEventMouseButton and evento.pressed:
		if evento.button_index == MOUSE_BUTTON_WHEEL_UP:
			_dist = maxf(6.0, _dist - 1.0)
		elif evento.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_dist = minf(60.0, _dist + 1.0)


func _process(_delta: float) -> void:
	# Camara que sigue a la maquina (gira con ella).
	var foco := extractor.global_position + Vector3(0, 2.5, 0)
	var yaw := _yaw + extractor.rotation.y
	var desplazamiento := Vector3(sin(yaw) * cos(_pitch), sin(_pitch), cos(yaw) * cos(_pitch)) * _dist
	camara.global_position = foco + desplazamiento
	camara.look_at(foco, Vector3.UP)
	etiqueta.text = "Animacion: %s   |   velocidad: %.2f m/s\nW/S avanzar-retroceder   A/D girar   ESPACIO mineria   raton: camara" % [
		extractor.animacion_actual, extractor.velocidad * absi(extractor.direccion)]


func _crear_entorno() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.01, 0.01, 0.02)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.3, 0.32, 0.4)
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var mundo := WorldEnvironment.new()
	mundo.environment = env
	add_child(mundo)

	var sol := DirectionalLight3D.new()
	sol.light_energy = 2.4
	sol.shadow_enabled = true
	sol.directional_shadow_max_distance = 80.0
	sol.rotation_degrees = Vector3(-32, 40, 0)
	add_child(sol)


func _crear_suelo() -> void:
	var ruido := FastNoiseLite.new()
	ruido.frequency = 0.03
	ruido.fractal_octaves = 4
	var textura := NoiseTexture2D.new()
	textura.noise = ruido
	textura.width = 512
	textura.height = 512
	textura.seamless = true
	var material := StandardMaterial3D.new()
	material.albedo_texture = textura
	material.albedo_color = Color(0.8, 0.77, 0.72)
	material.roughness = 1.0
	material.uv1_scale = Vector3(60, 60, 1)
	var plano := PlaneMesh.new()
	plano.size = Vector2(600, 600)
	plano.material = material
	var suelo := MeshInstance3D.new()
	suelo.mesh = plano
	add_child(suelo)


func _crear_rocas() -> void:
	# Rocas repartidas con semilla fija: sirven de referencia visual para ver el avance.
	var azar := RandomNumberGenerator.new()
	azar.seed = 7
	var malla := SphereMesh.new()
	malla.radius = 0.5
	malla.height = 0.7
	malla.radial_segments = 8
	malla.rings = 4
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.32, 0.31, 0.3)
	material.roughness = 1.0
	malla.material = material
	for i in 220:
		var pos := Vector2(azar.randf_range(-90, 90), azar.randf_range(-90, 90))
		if pos.length() < 7.0:
			continue
		var roca := MeshInstance3D.new()
		roca.mesh = malla
		var tam := azar.randf_range(0.3, 1.6)
		roca.scale = Vector3(tam, tam * azar.randf_range(0.5, 1.0), tam * azar.randf_range(0.7, 1.3))
		roca.position = Vector3(pos.x, tam * 0.15, pos.y)
		roca.rotation.y = azar.randf() * TAU
		add_child(roca)


func _crear_hud() -> void:
	var capa := CanvasLayer.new()
	add_child(capa)
	etiqueta = Label.new()
	etiqueta.position = Vector2(16, 12)
	capa.add_child(etiqueta)
