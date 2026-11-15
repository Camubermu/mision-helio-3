extends Node3D
## Secuencia de lanzamiento - Kodland / Mision Helio-3
## ENTER o ESPACIO = iniciar cuenta regresiva  |  ESC = reiniciar

@export var plataforma: Node3D
@export var cohete: Node3D
@export var camara: Camera3D
@export var cuenta_regresiva: int = 5
@export var altura_cubierta: float = 14.0   # solo si no se encuentra el nodo "Punto_Cohete"
@export var animacion: StringName = &"liberar_cohete"
@export var altura_vuelo: float = 1200.0
@export var tiempo_ascenso: float = 24.0

var _anim: AnimationPlayer
var _plasma: Node3D
var _etiqueta := Label.new()
var _lanzando := false
var _siguiendo := false
var _vibra := 0.0


func _ready() -> void:
	_crear_entorno()
	var sol := get_node_or_null("Sol") as DirectionalLight3D
	if sol:
		sol.rotation_degrees = Vector3(-48.0, -35.0, 0.0)
		sol.shadow_enabled = true

	_anim = plataforma.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _anim == null:
		push_warning("No se encontro el AnimationPlayer de la plataforma.")
	_plasma = _buscar_plasma(cohete)

	# El cohete se apoya sobre la cubierta (nodo marcador "Punto_Cohete")
	var punto := plataforma.find_child("Punto_Cohete", true, false) as Node3D
	cohete.global_position = punto.global_position if punto else Vector3(0.0, altura_cubierta, 0.0)
	_encender_plasma(0.0)

	if camara:
		camara.far = 5000.0
		camara.look_at_from_position(Vector3(48.0, 30.0, 66.0), Vector3(5.0, 26.0, 0.0))

	var capa := CanvasLayer.new()
	add_child(capa)
	_etiqueta.position = Vector2(28.0, 24.0)
	_etiqueta.add_theme_font_size_override("font_size", 34)
	_etiqueta.text = "ENTER: iniciar lanzamiento   |   ESC: reiniciar"
	capa.add_child(_etiqueta)


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_accept") and not _lanzando:
		lanzar()
	elif e.is_action_pressed("ui_cancel"):
		get_tree().reload_current_scene()


func lanzar() -> void:
	_lanzando = true
	for i in range(cuenta_regresiva, 0, -1):
		_etiqueta.text = "T-%d" % i
		await get_tree().create_timer(1.0).timeout

	_etiqueta.text = "ENCENDIDO - liberando sujeciones"
	create_tween().tween_method(_encender_plasma, 0.0, 1.0, 7.0).set_trans(Tween.TRANS_SINE)
	create_tween().tween_property(self, "_vibra", 0.10, 6.0)

	var duracion := 9.0
	if _anim:
		_anim.play(animacion)
		duracion = _anim.get_animation(animacion).length
	await get_tree().create_timer(duracion).timeout

	_etiqueta.text = "DESPEGUE"
	_despegar()


func _despegar() -> void:
	_siguiendo = true
	var y0 := cohete.position.y
	var tw := create_tween()
	tw.tween_property(cohete, "position:y", y0 + altura_vuelo, tiempo_ascenso) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	create_tween().tween_property(self, "_vibra", 0.0, 6.0)
	await tw.finished
	_etiqueta.text = "Mision Helio-3 en ascenso"


func _process(_delta: float) -> void:
	if camara == null:
		return
	if _siguiendo:
		camara.look_at(cohete.global_position + Vector3(0.0, 20.0, 0.0))
	camara.h_offset = randf_range(-1.0, 1.0) * _vibra
	camara.v_offset = randf_range(-1.0, 1.0) * _vibra


func _encender_plasma(k: float) -> void:
	if _plasma == null:
		return
	_plasma.visible = k > 0.001
	_plasma.scale = Vector3(lerpf(0.55, 1.0, k), maxf(k, 0.02), lerpf(0.55, 1.0, k))


func _buscar_plasma(n: Node) -> Node3D:
	if n is Node3D and String(n.name) == "Plasma":
		return n as Node3D
	for hijo in n.get_children():
		var r := _buscar_plasma(hijo)
		if r != null:
			return r
	return null


func _crear_entorno() -> void:
	var mat_cielo := ProceduralSkyMaterial.new()
	mat_cielo.sky_top_color = Color(0.20, 0.38, 0.75)
	mat_cielo.sky_horizon_color = Color(0.65, 0.78, 0.92)
	mat_cielo.ground_horizon_color = Color(0.65, 0.78, 0.92)
	mat_cielo.ground_bottom_color = Color(0.25, 0.27, 0.30)
	var cielo := Sky.new()
	cielo.sky_material = mat_cielo
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = cielo
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	var we := get_node_or_null("Entorno") as WorldEnvironment
	if we:
		we.environment = env
