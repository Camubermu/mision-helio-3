extends Node3D
## Escenas en tercera persona del cohete (despegues, alunizaje y aterrizaje).
## Va como hija del ViajeEspacial y mueve a su hermano "Cohete".
##
## - En la Tierra se usa la base de la escena level 1 (nodo "BaseTierra").
## - El motor químico tiene llama azul (la arma este script).
## - El motor de plasma de helio-3 usa la llama "Plasma" del propio modelo.
## - Un panel muestra los datos del motor en cada escena.
## Espacio = saltar la escena.

## Segundos que dura el despegue desde la Tierra.
@export var duracion_despegue_tierra := 9.0
## Segundos que dura el despegue desde la Luna (el motor de helio-3 va al límite).
@export var duracion_despegue_luna := 12.0
## Segundos que dura el alunizaje o el aterrizaje.
@export var duracion_aterrizaje := 9.0
## Altura desde la que baja el cohete al aterrizar (metros).
@export var altura_aterrizaje := 90.0
## La base de la Tierra (la escena level 1, puesta para que la plataforma quede en el centro).
@export var base_tierra: Node3D

var _cohete: Node3D
var _plasma: Node3D
var _llama_quimica: Node3D
var _luz_quimica: OmniLight3D
var _camara: Camera3D
var _suelo_luna: MeshInstance3D
var _plataforma: MeshInstance3D
var _polvo: CPUParticles3D
var _material_polvo: StandardMaterial3D
var _cielo_tierra: Environment
var _panel: Control
var _titulo: Label
var _lineas: Label
var _barra_1: ProgressBar
var _barra_2: ProgressBar
var _nombre_barra_2: Label
var _estado: Label
var _saltar := false
var _tiempo := 0.0


func _ready() -> void:
	_cohete = get_parent().get_node("Cohete")
	_plasma = _cohete.find_child("Plasma", true, false)
	_armar_escenario()
	_armar_llama_quimica()
	_armar_panel()
	_preparar_base_tierra()
	visible = false
	_panel.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("propulsor"):
		get_viewport().set_input_as_handled()
		_saltar = true


# --- Las cuatro escenas -----------------------------------------------------

## Despegue desde la base con el motor químico (llama azul). Falla al salir de la atmósfera.
func despegar_de_la_tierra() -> void:
	_preparar(false)
	_camara.position = Vector3(-45, 3, 9)
	_titulo.text = "MOTOR QUÍMICO · DESPEGUE DESDE LA BASE"
	_nombre_barra_2.text = "Altitud (100 km)"
	var duracion := duracion_despegue_tierra
	var t := 0.0
	while t < duracion and not _saltar:
		t += _paso()
		var falla := t > duracion - 2.5
		var encendido := t > 1.5 and t < duracion - 1.0 and (not falla or randf() < 0.35)
		_llama(_llama_quimica, encendido)
		_luz_quimica.visible = encendido
		var subida := maxf(t - 2.2, 0.0)
		_cohete.position.y = 2.0 * subida * subida
		var altitud := clampf((t - 2.2) / (duracion - 4.7), 0.0, 1.0)
		_polvo.emitting = encendido and _cohete.position.y < 25.0
		if t < 1.5:
			_estado.text = "Cuenta regresiva: %d" % (3 - int(t * 2.0))
			_estado.modulate = Color.WHITE
		elif falla:
			_estado.text = "¡FALLA DEL MOTOR QUÍMICO! Fuga de combustible"
			_estado.modulate = Color(1, 0.3, 0.25) if fmod(t, 0.5) < 0.3 else Color(1, 0.8, 0.3)
		else:
			_estado.text = "Saliendo de la atmósfera..."
			_estado.modulate = Color(0.6, 0.9, 1)
		_lineas.text = "Altitud: %d km   Combustible químico: %d %%" % [altitud * 100.0, 0 if falla else 100 - int(t * 6)]
		_barra_1.value = 100.0 if encendido else 0.0
		_barra_2.value = altitud * 100.0
		_seguir_cohete(0.07 if encendido and _cohete.position.y < 40.0 else 0.02 if falla else 0.0)
		await get_tree().process_frame
	if not _saltar:
		Juego.mostrar_mensaje("¡El motor químico falló al salir de la atmósfera!")
	_terminar()


## El cohete baja sobre la Luna frenando solo con el motor de plasma de helio-3.
func alunizar() -> void:
	_preparar(true)
	_titulo.text = "MOTOR DE HELIO-3 · ALUNIZAJE"
	await _bajar(Vector3(34, 6, 30), 10.0, 4.0)
	if not _saltar:
		Juego.mostrar_mensaje("Alunizaje logrado con lo último del helio-3")
	_terminar()


## Prueba del motor de helio-3 para despegar: va al límite, pero vence la gravedad lunar.
func despegar_de_la_luna() -> void:
	_preparar(true)
	_camara.position = Vector3(-34, 4, 28)
	_titulo.text = "MOTOR DE HELIO-3 · DESPEGUE LUNAR"
	_nombre_barra_2.text = "Velocidad de escape"
	var duracion := duracion_despegue_luna
	var t := 0.0
	var altura := 0.0
	var velocidad := 0.0
	while t < duracion and not _saltar:
		var delta := _paso()
		t += delta
		var empuje := clampf(lerpf(60.0, 100.0, (t - 1.0) / 5.0), 0.0, 100.0) if t > 1.0 else 0.0
		var temperatura := lerpf(300.0, 2950.0, clampf((t - 1.0) / 6.0, 0.0, 1.0))
		_llama(_plasma, t > 1.0)
		# Al principio casi no sube (va al límite); después vence la gravedad.
		var aceleracion := 0.4 if t < 6.0 else 4.5
		if t > 2.0:
			velocidad += aceleracion * delta
			altura += velocidad * delta
		_cohete.position.y = altura
		var escape := clampf((t - 2.0) / (duracion - 4.5), 0.0, 1.0)
		_polvo.emitting = t > 1.0 and altura < 20.0
		_barra_1.value = empuje
		_barra_2.value = escape * 100.0
		_lineas.text = "Temperatura: %d °C   Velocidad: %s de 2,38 km/s" % [temperatura, ("%.2f" % (escape * 2.38)).replace(".", ",")]
		if t < 1.0:
			_estado.text = "Encendiendo el motor de helio-3..."
			_estado.modulate = Color.WHITE
		elif escape < 1.0 and empuje > 95.0:
			_estado.text = "¡MOTOR AL LÍMITE! Empuje 100 %"
			_estado.modulate = Color(1, 0.35, 0.2) if fmod(t, 0.5) < 0.3 else Color(1, 0.85, 0.3)
		elif escape < 1.0:
			_estado.text = "Subiendo potencia..."
			_estado.modulate = Color(1, 0.85, 0.3)
		else:
			_estado.text = "¡GRAVEDAD LUNAR VENCIDA! El motor de helio-3 funciona"
			_estado.modulate = Color(0.4, 1, 0.5)
		_seguir_cohete(0.09 if empuje > 95.0 and escape < 1.0 else 0.03 if t > 1.0 else 0.0)
		await get_tree().process_frame
	_terminar()


## El cohete vuelve a la base (level 1) frenando con el motor de helio-3.
func aterrizar_en_la_tierra() -> void:
	_preparar(false)
	_titulo.text = "MOTOR DE HELIO-3 · ATERRIZAJE EN LA BASE"
	await _bajar(Vector3(-42, 4, 9), 60.0, 30.0)
	if not _saltar:
		Juego.mostrar_mensaje("¡Aterrizaje en la base! Misión cumplida: el motor de helio-3 funcionó")
	_terminar()


# --- Partes comunes -----------------------------------------------------------

func _bajar(lugar_camara: Vector3, helio_inicio: float, helio_fin: float) -> void:
	_camara.position = lugar_camara
	_nombre_barra_2.text = "Helio-3 en tanque"
	var bajada := duracion_aterrizaje - 1.5
	var t := 0.0
	while t < duracion_aterrizaje and not _saltar:
		t += _paso()
		var avance := clampf(t / bajada, 0.0, 1.0)
		# Baja rápido al principio y muy despacio al final.
		_cohete.position.y = altura_aterrizaje * pow(1.0 - avance, 2.4)
		var en_el_aire := avance < 1.0
		_llama(_plasma, en_el_aire)
		_polvo.emitting = en_el_aire and _cohete.position.y < 18.0
		_barra_1.value = lerpf(60.0, 85.0, avance) if en_el_aire else 0.0
		_barra_2.value = lerpf(helio_inicio, helio_fin, avance)
		_lineas.text = "Altura: %d m   Helio-3: %d %%" % [_cohete.position.y, _barra_2.value]
		_estado.text = "Frenando..." if en_el_aire else "Contacto con el suelo. Motor apagado"
		_estado.modulate = Color(1, 0.85, 0.3) if en_el_aire else Color(0.4, 1, 0.5)
		_seguir_cohete(0.04 if en_el_aire and _cohete.position.y < 20.0 else 0.0)
		await get_tree().process_frame
	_cohete.position = Vector3.ZERO
	_llama(_plasma, false)


func _paso() -> float:
	return get_process_delta_time()


func _preparar(en_la_luna: bool) -> void:
	_saltar = false
	visible = true
	_panel.visible = true
	_cohete.position = Vector3.ZERO
	_llama(_plasma, false)
	_llama(_llama_quimica, false)
	_luz_quimica.visible = false
	_suelo_luna.visible = en_la_luna
	if base_tierra:
		base_tierra.visible = not en_la_luna
	_plataforma.visible = en_la_luna or base_tierra == null
	_material_polvo.albedo_color = Color(0.6, 0.58, 0.55, 0.55) if en_la_luna else Color(0.85, 0.85, 0.85, 0.5)
	# En la Tierra el cielo es azul; en la Luna se usa el cielo negro de la escena.
	_camara.environment = null if en_la_luna else _cielo_tierra
	_camara.make_current()


func _terminar() -> void:
	_polvo.emitting = false
	_camara.h_offset = 0.0
	_camara.v_offset = 0.0
	_cohete.position = Vector3.ZERO
	_llama(_llama_quimica, false)
	_luz_quimica.visible = false
	visible = false
	_panel.visible = false


func _llama(llama: Node3D, encendida: bool) -> void:
	if llama == null:
		return
	llama.visible = encendida
	if encendida:
		_tiempo += get_process_delta_time()
		var parpadeo := 1.0 + sin(_tiempo * 40.0) * 0.07 + randf_range(-0.05, 0.05)
		llama.scale = Vector3(1.0, parpadeo, 1.0)


func _seguir_cohete(temblor: float) -> void:
	_camara.look_at(_cohete.global_position + Vector3(0, 12, 0), Vector3.UP)
	_camara.h_offset = randf_range(-1, 1) * temblor
	_camara.v_offset = randf_range(-1, 1) * temblor


# --- Armado ------------------------------------------------------------------

## La base de level 1 se usa solo como decorado: sin su jugador ni su cielo.
func _preparar_base_tierra() -> void:
	if base_tierra == null:
		return
	for nombre in ["player", "WorldEnvironment"]:
		var nodo := base_tierra.get_node_or_null(nombre)
		if nodo:
			nodo.queue_free()


## Llama azul del motor químico: dos conos que brillan, debajo del cohete.
func _armar_llama_quimica() -> void:
	_llama_quimica = Node3D.new()
	_llama_quimica.name = "LlamaQuimica"
	_llama_quimica.position.y = 0.7
	for capa in [[2.2, 18.0, Color(0.25, 0.45, 1.0, 0.6)], [1.1, 10.0, Color(0.75, 0.9, 1.0, 0.85)]]:
		var cono := CylinderMesh.new()
		cono.top_radius = capa[0]
		cono.bottom_radius = 0.1
		cono.height = capa[1]
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		material.albedo_color = capa[2]
		cono.material = material
		var malla := MeshInstance3D.new()
		malla.mesh = cono
		malla.position.y = -capa[1] / 2.0
		malla.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_llama_quimica.add_child(malla)
	_luz_quimica = OmniLight3D.new()
	_luz_quimica.light_color = Color(0.4, 0.6, 1.0)
	_luz_quimica.light_energy = 5.0
	_luz_quimica.omni_range = 30.0
	_luz_quimica.position.y = -3.0
	_llama_quimica.add_child(_luz_quimica)
	_cohete.add_child(_llama_quimica)
	_llama_quimica.visible = false


## Panel con los datos del motor (a la izquierda de la pantalla).
func _armar_panel() -> void:
	var capa := CanvasLayer.new()
	capa.layer = 5
	add_child(capa)
	_panel = PanelContainer.new()
	_panel.position = Vector2(24, 110)
	_panel.custom_minimum_size = Vector2(580, 0)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.02, 0.05, 0.12, 0.8)
	estilo.set_corner_radius_all(10)
	estilo.set_content_margin_all(14)
	_panel.add_theme_stylebox_override("panel", estilo)
	capa.add_child(_panel)
	var columna := VBoxContainer.new()
	_panel.add_child(columna)
	_titulo = Label.new()
	_titulo.add_theme_font_size_override("font_size", 24)
	_titulo.add_theme_color_override("font_color", Color(0.5, 0.95, 1.0))
	columna.add_child(_titulo)
	_barra_1 = _fila_barra(columna, "Empuje del motor", Color(1.0, 0.55, 0.2))[1]
	var fila_2: Array = _fila_barra(columna, "", Color(0.3, 0.85, 1.0))
	_nombre_barra_2 = fila_2[0]
	_barra_2 = fila_2[1]
	_lineas = Label.new()
	_lineas.add_theme_font_size_override("font_size", 20)
	columna.add_child(_lineas)
	_estado = Label.new()
	_estado.add_theme_font_size_override("font_size", 24)
	_estado.add_theme_color_override("font_outline_color", Color.BLACK)
	_estado.add_theme_constant_override("outline_size", 6)
	columna.add_child(_estado)


static func _fila_barra(padre: Control, texto: String, color: Color) -> Array:
	var fila := HBoxContainer.new()
	padre.add_child(fila)
	var nombre := Label.new()
	nombre.text = texto
	nombre.custom_minimum_size = Vector2(210, 0)
	nombre.add_theme_font_size_override("font_size", 19)
	fila.add_child(nombre)
	var barra := ProgressBar.new()
	barra.custom_minimum_size = Vector2(330, 22)
	barra.show_percentage = true
	var relleno := StyleBoxFlat.new()
	relleno.bg_color = color
	barra.add_theme_stylebox_override("fill", relleno)
	fila.add_child(barra)
	return [nombre, barra]


func _armar_escenario() -> void:
	_suelo_luna = MeshInstance3D.new()
	var plano := PlaneMesh.new()
	plano.size = Vector2(600, 600)
	_suelo_luna.mesh = plano
	var material_suelo := StandardMaterial3D.new()
	material_suelo.albedo_color = Color(0.3, 0.3, 0.3)
	material_suelo.roughness = 1.0
	_suelo_luna.material_override = material_suelo
	add_child(_suelo_luna)

	_plataforma = MeshInstance3D.new()
	var disco := CylinderMesh.new()
	disco.top_radius = 9.0
	disco.bottom_radius = 9.5
	disco.height = 0.3
	_plataforma.mesh = disco
	_plataforma.position.y = -0.12
	var material_plataforma := StandardMaterial3D.new()
	material_plataforma.albedo_color = Color(0.25, 0.25, 0.27)
	_plataforma.material_override = material_plataforma
	add_child(_plataforma)

	_camara = Camera3D.new()
	_camara.fov = 60.0
	_camara.far = 3000.0
	add_child(_camara)

	_polvo = CPUParticles3D.new()
	_polvo.emitting = false
	_polvo.amount = 160
	_polvo.lifetime = 2.2
	_polvo.local_coords = false
	_polvo.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_polvo.emission_sphere_radius = 3.0
	_polvo.direction = Vector3(1, 0.15, 0)
	_polvo.spread = 180.0
	_polvo.flatness = 0.85
	_polvo.initial_velocity_min = 8.0
	_polvo.initial_velocity_max = 16.0
	_polvo.gravity = Vector3(0, -0.5, 0)
	_polvo.damping_min = 3.0
	_polvo.damping_max = 5.0
	_polvo.scale_amount_min = 2.0
	_polvo.scale_amount_max = 5.0
	var curva := Curve.new()
	curva.add_point(Vector2(0, 0.4))
	curva.add_point(Vector2(1, 1.0))
	_polvo.scale_amount_curve = curva
	var bola := SphereMesh.new()
	bola.radius = 0.5
	bola.height = 1.0
	bola.radial_segments = 8
	bola.rings = 4
	_material_polvo = StandardMaterial3D.new()
	_material_polvo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material_polvo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bola.material = _material_polvo
	_polvo.mesh = bola
	_polvo.position.y = 0.5
	add_child(_polvo)

	_cielo_tierra = Environment.new()
	_cielo_tierra.background_mode = Environment.BG_SKY
	_cielo_tierra.sky = Sky.new()
	_cielo_tierra.sky.sky_material = ProceduralSkyMaterial.new()
	_cielo_tierra.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	_cielo_tierra.tonemap_mode = Environment.TONE_MAPPER_FILMIC
