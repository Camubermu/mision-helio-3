extends Node3D
## Detalles para que la cabina se sienta como una misión de verdad:
## - Objetos flotando en gravedad cero (lápiz, lista de verificación, gotas de agua
##   y un muñeco: los astronautas llevan uno para saber cuándo ya no hay gravedad).
## - Radio con el Control de Misión, con los "tonos Quindar" que usaba el Apolo.
## - Luces del tablero parpadeando, zumbido de la cabina y alarma sonora.
## - Estrellas por la ventana y un leve flotar del pasajero.
## Va como hija del ViajeEspacial, que la prende y apaga con empezar() y terminar().

const RADIO_LUNA := [
	[2.0, "Helio-3, aquí Control. Confirmamos falla del motor químico. Mantengan la calma."],
	[8.0, "Motor de plasma estable. Revisen combustible con la tecla 1 y daños con la 3."],
	[-1.0, "Helio-3, malas noticias: el helio-3 no alcanza para volver. Nuevo plan: producirlo en la Luna."],
	[26.0, "Preparen el alunizaje. Toda la Tierra los está mirando. Buena suerte."],
]
const RADIO_TIERRA := [
	[2.0, "¡Helio-3, los vemos! El despegue con el motor de helio-3 fue un éxito."],
	[12.0, "Todos los sistemas normales. La base level 1 los espera."],
	[26.0, "Preparen el aterrizaje. Bienvenidos a casa, tripulación."],
]

## Zona de la cabina donde flotan los objetos (coordenadas del cohete).
@export var zona_flotar := AABB(Vector3(-0.75, 2.3, -1.2), Vector3(1.35, 1.3, 2.0))

var activa := false

var _viaje: Node
var _asiento: Node3D
var _base_asiento := Vector3.ZERO
var _flotantes: Array[Dictionary] = []
var _luces: Array[Dictionary] = []
var _estrellas: MultiMeshInstance3D
var _radio: Label
var _panel_radio: PanelContainer
var _lineas: Array = []
var _siguiente := 0
var _tiempo := 0.0
var _momento_plan := 15.0

var _sonido: AudioStreamPlayer
var _reproduccion: AudioStreamGeneratorPlayback
var _muestra := 0.0
var _tono := 0.0
var _tono_restante := 0
var _ruido := 0.0
const FRECUENCIA := 16000.0


func _ready() -> void:
	_viaje = get_parent()
	_asiento = _viaje.get_node("Asiento")
	_base_asiento = _asiento.position
	_crear_flotantes()
	_preparar_luces(_viaje.get_node("Cohete"))
	_crear_estrellas()
	_crear_radio()
	_crear_sonido()
	visible = false
	set_process(false)


func empezar(hacia_la_luna: bool, momento_plan: float) -> void:
	activa = true
	visible = true
	_estrellas.visible = true
	_tiempo = 0.0
	_momento_plan = momento_plan
	_lineas = RADIO_LUNA if hacia_la_luna else RADIO_TIERRA
	_siguiente = 0
	_panel_radio.visible = false
	for objeto in _flotantes:
		objeto.nodo.position = objeto.inicio
	if _sonido:
		_sonido.play()
		_reproduccion = _sonido.get_stream_playback()
	set_process(true)


func terminar() -> void:
	activa = false
	visible = false
	_estrellas.visible = false
	_panel_radio.visible = false
	_asiento.position = _base_asiento
	if _sonido:
		_sonido.stop()
	set_process(false)


func _process(delta: float) -> void:
	_tiempo += delta
	_mover_flotantes(delta)
	_parpadear_luces()
	_revisar_radio()
	# En gravedad cero el pasajero flota un poquito en su asiento.
	_asiento.position = _base_asiento + Vector3(sin(_tiempo * 0.5) * 0.01, sin(_tiempo * 0.8) * 0.015, 0)
	_llenar_sonido()


# --- Radio ------------------------------------------------------------------

func _revisar_radio() -> void:
	if _siguiente >= _lineas.size():
		return
	var momento: float = _lineas[_siguiente][0]
	if momento < 0.0:
		momento = _momento_plan + 0.5
	if _tiempo >= momento:
		_decir(_lineas[_siguiente][1])
		_siguiente += 1


func _decir(texto: String) -> void:
	_radio.text = "CONTROL DE MISIÓN (radio):  " + texto
	_panel_radio.visible = true
	_pitar(2525.0, 0.25)
	var espera := get_tree().create_timer(6.0)
	espera.timeout.connect(func():
		if _radio.text.ends_with(texto):
			_panel_radio.visible = false
			_pitar(2475.0, 0.25))


func _crear_radio() -> void:
	var capa := CanvasLayer.new()
	capa.layer = 4
	add_child(capa)
	_panel_radio = PanelContainer.new()
	_panel_radio.anchor_left = 0.5
	_panel_radio.anchor_right = 0.5
	_panel_radio.anchor_top = 1.0
	_panel_radio.anchor_bottom = 1.0
	_panel_radio.offset_left = -560
	_panel_radio.offset_right = 560
	_panel_radio.offset_top = -120
	_panel_radio.offset_bottom = -40
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0, 0.06, 0.02, 0.8)
	estilo.border_color = Color(0.3, 1, 0.5, 0.6)
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(8)
	estilo.set_content_margin_all(12)
	_panel_radio.add_theme_stylebox_override("panel", estilo)
	capa.add_child(_panel_radio)
	_radio = Label.new()
	_radio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_radio.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_radio.add_theme_font_size_override("font_size", 22)
	_radio.add_theme_color_override("font_color", Color(0.55, 1, 0.65))
	_panel_radio.add_child(_radio)
	_panel_radio.visible = false


# --- Objetos flotando ----------------------------------------------------------

func _crear_flotantes() -> void:
	var azar := RandomNumberGenerator.new()
	azar.seed = 3
	var objetos: Array[Node3D] = [_lapiz(), _lista(), _muneco()]
	for i in 4:
		objetos.append(_gota())
	for objeto in objetos:
		add_child(objeto)
		var inicio := zona_flotar.position + Vector3(azar.randf(), azar.randf(), azar.randf()) * zona_flotar.size
		objeto.position = inicio
		_flotantes.append({
			"nodo": objeto,
			"inicio": inicio,
			"velocidad": Vector3(azar.randf_range(-1, 1), azar.randf_range(-1, 1), azar.randf_range(-1, 1)).normalized() * azar.randf_range(0.04, 0.1),
			"giro": Vector3(azar.randf_range(-1, 1), azar.randf_range(-1, 1), azar.randf_range(-1, 1)) * 0.6,
		})


func _mover_flotantes(delta: float) -> void:
	for objeto in _flotantes:
		var nodo: Node3D = objeto.nodo
		var velocidad: Vector3 = objeto.velocidad
		nodo.position += velocidad * delta
		var giro: Vector3 = objeto.giro
		nodo.rotation += giro * delta
		# Rebota suave en los bordes de la zona.
		for eje in 3:
			if nodo.position[eje] < zona_flotar.position[eje] and velocidad[eje] < 0.0:
				velocidad[eje] = -velocidad[eje]
			elif nodo.position[eje] > zona_flotar.end[eje] and velocidad[eje] > 0.0:
				velocidad[eje] = -velocidad[eje]
		objeto.velocidad = velocidad


func _lapiz() -> Node3D:
	var lapiz := _pieza(CylinderMesh.new(), Color(0.15, 0.3, 0.85))
	(lapiz.mesh as CylinderMesh).top_radius = 0.008
	(lapiz.mesh as CylinderMesh).bottom_radius = 0.008
	(lapiz.mesh as CylinderMesh).height = 0.15
	return lapiz


func _lista() -> Node3D:
	var lista := _pieza(BoxMesh.new(), Color(0.95, 0.95, 0.92))
	(lista.mesh as BoxMesh).size = Vector3(0.22, 0.3, 0.012)
	var texto := Label3D.new()
	texto.text = "LISTA DE VERIFICACIÓN\n\n[x] Trajes sellados\n[x] Radio OK\n[x] Plasma encendido\n[  ] Alunizaje"
	texto.font_size = 18
	texto.pixel_size = 0.0007
	texto.modulate = Color(0.1, 0.1, 0.15)
	texto.outline_size = 0
	texto.position.z = 0.008
	lista.add_child(texto)
	var pinza := _pieza(BoxMesh.new(), Color(0.6, 0.6, 0.62))
	(pinza.mesh as BoxMesh).size = Vector3(0.08, 0.03, 0.02)
	pinza.position = Vector3(0, 0.15, 0.008)
	lista.add_child(pinza)
	return lista


## Muñeco "indicador de gravedad cero": cuando empieza a flotar, ya no hay gravedad.
func _muneco() -> Node3D:
	var muneco := Node3D.new()
	var cuerpo := _pieza(CapsuleMesh.new(), Color(1, 0.55, 0.15))
	(cuerpo.mesh as CapsuleMesh).radius = 0.04
	(cuerpo.mesh as CapsuleMesh).height = 0.12
	muneco.add_child(cuerpo)
	var cabeza := _pieza(SphereMesh.new(), Color(1, 0.85, 0.7))
	(cabeza.mesh as SphereMesh).radius = 0.04
	(cabeza.mesh as SphereMesh).height = 0.08
	cabeza.position.y = 0.09
	muneco.add_child(cabeza)
	return muneco


func _gota() -> Node3D:
	var gota := _pieza(SphereMesh.new(), Color(0.5, 0.75, 1.0, 0.6))
	var radio := randf_range(0.012, 0.025)
	(gota.mesh as SphereMesh).radius = radio
	(gota.mesh as SphereMesh).height = radio * 2.0
	(gota.material_override as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	(gota.material_override as StandardMaterial3D).roughness = 0.05
	return gota


static func _pieza(malla: Mesh, color: Color) -> MeshInstance3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	var pieza := MeshInstance3D.new()
	pieza.mesh = malla
	pieza.material_override = material
	return pieza


# --- Luces del tablero -----------------------------------------------------------

func _preparar_luces(cohete: Node) -> void:
	for malla in cohete.find_children("*", "MeshInstance3D", true, false):
		var nombre := String(malla.name)
		var es_ambar := nombre.begins_with("Luz_ambar")
		if not (es_ambar or nombre.begins_with("Luz_cian") or nombre.contains("_luz_")):
			continue
		var m := malla as MeshInstance3D
		var original := m.get_active_material(0) as BaseMaterial3D
		var material: BaseMaterial3D = original.duplicate() if original else StandardMaterial3D.new()
		material.emission_enabled = true
		material.emission = Color(1, 0.6, 0.1) if es_ambar else Color(0.3, 0.95, 1)
		m.material_override = material
		_luces.append({"material": material, "ambar": es_ambar, "ritmo": randf_range(0.6, 2.5), "fase": randf() * TAU})


func _parpadear_luces() -> void:
	var alarma: bool = _viaje.alarma_activa()
	for luz in _luces:
		var material: BaseMaterial3D = luz.material
		if luz.ambar:
			material.emission_energy_multiplier = (4.0 if fmod(_tiempo, 0.6) < 0.3 else 0.2) if alarma else 0.3
		else:
			material.emission_energy_multiplier = 1.0 + sin(_tiempo * luz.ritmo + luz.fase) * 0.8


# --- Estrellas por la ventana ------------------------------------------------------

func _crear_estrellas() -> void:
	var punto := SphereMesh.new()
	punto.radius = 0.25
	punto.height = 0.5
	punto.radial_segments = 4
	punto.rings = 2
	var blanco := StandardMaterial3D.new()
	blanco.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	punto.material = blanco
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = punto
	multi.instance_count = 600
	var azar := RandomNumberGenerator.new()
	azar.seed = 11
	for i in multi.instance_count:
		var direccion := Vector3(azar.randf_range(-1, 1), azar.randf_range(-1, 1), azar.randf_range(-1, 1)).normalized()
		multi.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * azar.randf_range(0.5, 1.5)), direccion * 220.0))
	_estrellas = MultiMeshInstance3D.new()
	_estrellas.multimesh = multi
	_estrellas.visible = false
	# Las estrellas van en el ViajeEspacial (no en esta cabina) para no moverse con nada.
	_viaje.add_child.call_deferred(_estrellas)


# --- Sonido (se fabrica con números, sin archivos de audio) ----------------------------

func _crear_sonido() -> void:
	var generador := AudioStreamGenerator.new()
	generador.mix_rate = FRECUENCIA
	generador.buffer_length = 0.15
	_sonido = AudioStreamPlayer.new()
	_sonido.stream = generador
	_sonido.volume_db = -6.0
	add_child(_sonido)


func _pitar(frecuencia: float, segundos: float) -> void:
	_tono = frecuencia
	_tono_restante = int(segundos * FRECUENCIA)


func _llenar_sonido() -> void:
	if _reproduccion == null:
		return
	var alarma: bool = _viaje.alarma_activa()
	for i in _reproduccion.get_frames_available():
		_muestra += 1.0 / FRECUENCIA
		# Zumbido grave de los ventiladores de la cabina.
		_ruido = lerpf(_ruido, randf_range(-1, 1), 0.05)
		var s := sin(TAU * 58.0 * _muestra) * 0.03 + _ruido * 0.05
		if _tono_restante > 0:
			s += sin(TAU * _tono * _muestra) * 0.18
			_tono_restante -= 1
		if alarma:
			var nota := 880.0 if fmod(_muestra, 0.5) < 0.25 else 660.0
			s += (0.06 if sin(TAU * nota * _muestra) > 0.0 else -0.06)
		_reproduccion.push_frame(Vector2(s, s))
