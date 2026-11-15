extends Area3D
## Zona del reactor que convierte regolito en helio-3.
##
## Cuando el vehículo (o el jugador) entra con regolito, el material vuela al reactor,
## el reactor tiembla y brilla mientras procesa, y salen cápsulas de helio-3
## que el jugador recoge y lleva a la nave.
## Pon esta zona alrededor del reactor y en "Reactor" elige el modelo del reactor.

const TrozoRegolito = preload("res://scripts/trozo_regolito.gd")

## El modelo del reactor que tiembla y brilla mientras procesa.
@export var reactor: Node3D
## Si es verdadero, la zona se pone sola donde está el reactor
## (así puedes mover el reactor en el editor sin tener que mover también la zona).
@export var seguir_al_reactor := true
## Cuánto regolito se necesita para 1 de helio-3.
@export var regolito_por_helio := 3
## Segundos que tarda en hacer 1 de helio-3.
@export var segundos_por_helio := 2.0
## Piezas del modelo que brillan al procesar (basta con el comienzo del nombre).
@export var partes_que_brillan: PackedStringArray = ["port_light", "reactor_cap", "top_dome", "inspection_port"]
## Color del brillo.
@export var color_brillo := Color(0.3, 0.9, 1.0)
## Cápsula que sale por cada helio-3.
@export var capsula: PackedScene = preload("res://scenes/objetos/capsula_helio3.tscn")
## Colores para pintar el reactor: comienzo del nombre de la pieza → color.
## Bórralos todos si el modelo ya trae sus propios colores.
@export var colores_reactor: Dictionary = {
	"radiator_face": Color(0.1, 0.22, 0.5),
	"radiator_panel": Color(0.18, 0.2, 0.26),
	"radiator_fin": Color(0.75, 0.77, 0.8),
	"radiator_border": Color(0.35, 0.37, 0.42),
	"reactor_pressure": Color(0.82, 0.84, 0.88),
	"top_shoulder": Color(0.82, 0.84, 0.88),
	"top_dome": Color(0.55, 0.6, 0.68),
	"structural_band": Color(0.85, 0.62, 0.18),
	"lower_gold_ring": Color(0.85, 0.62, 0.18),
	"base_lower": Color(0.3, 0.32, 0.36),
	"vertical_rib": Color(0.3, 0.32, 0.36),
	"wing_support": Color(0.3, 0.32, 0.36),
	"connector": Color(0.85, 0.62, 0.18),
	"coolant_line": Color(0.95, 0.42, 0.1),
	"side_pump": Color(0.8, 0.2, 0.15),
	"service_unit": Color(0.8, 0.2, 0.15),
	"landing_leg": Color(0.45, 0.47, 0.5),
	"leg_brace": Color(0.45, 0.47, 0.5),
	"footpad": Color(0.25, 0.26, 0.28),
	"antenna_dish": Color(0.92, 0.92, 0.95),
	"antenna_mast": Color(0.3, 0.32, 0.36),
	"antenna_tip": Color(0.9, 0.15, 0.1),
	"reactor_cap": Color(0.2, 0.75, 0.9),
	"inspection_port": Color(0.15, 0.55, 0.7),
	"port_light": Color(0.3, 0.9, 1.0),
}

var procesando := false

var _materiales_brillo: Array[BaseMaterial3D] = []
var _posicion_reactor := Vector3.ZERO
var _tiempo := 0.0
var _capsulas_creadas := 0

@onready var _entrada: Node3D = $Entrada
@onready var _salida_capsulas: Node3D = $SalidaCapsulas


func _ready() -> void:
	body_entered.connect(_al_entrar)
	if reactor and seguir_al_reactor:
		var lugar := reactor.global_position
		global_position = Vector3(lugar.x, global_position.y, lugar.z)
	if reactor:
		_posicion_reactor = reactor.position
		_pintar_reactor()
		_preparar_brillo()


func _process(delta: float) -> void:
	if reactor == null:
		return
	_tiempo += delta
	var fuerza := 1.0 if procesando else 0.0
	reactor.position = _posicion_reactor + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)) * 0.03 * fuerza
	for material in _materiales_brillo:
		# Apagado brilla poquito; procesando, pulsa fuerte.
		material.emission_energy_multiplier = lerpf(0.3, 2.5 + sin(_tiempo * 6.0) * 1.5, fuerza)


func _al_entrar(cuerpo: Node3D) -> void:
	var vale := cuerpo.is_in_group("vehiculo") or Interactuable.es_jugador(cuerpo)
	if vale and not procesando:
		_procesar(cuerpo)


func _procesar(cuerpo: Node3D) -> void:
	var lotes := Juego.regolito / regolito_por_helio
	if lotes == 0:
		if Juego.regolito > 0:
			Juego.mostrar_mensaje("El reactor necesita %d de regolito (tienes %d)" % [regolito_por_helio, Juego.regolito])
		else:
			Juego.mostrar_mensaje("Trae regolito con el vehículo extractor para hacer helio-3")
		return

	procesando = true
	Juego.usar_regolito(lotes * regolito_por_helio)
	Juego.mostrar_mensaje("Descargando regolito en el reactor...")
	await _descargar(cuerpo, lotes * regolito_por_helio)

	for i in lotes:
		Juego.mostrar_mensaje("Procesando regolito... %d/%d" % [i + 1, lotes])
		await _esperar(segundos_por_helio)
		_sacar_capsula()

	Juego.mostrar_mensaje("¡Listo! Salieron %d cápsulas de helio-3. Recógelas" % lotes)
	procesando = false


## Los trocitos vuelan desde el vehículo hasta la entrada del reactor.
func _descargar(cuerpo: Node3D, cantidad: int) -> void:
	var desde := cuerpo.global_position + Vector3.UP * 4.0
	for i in mini(cantidad, 20):
		var trozo := TrozoRegolito.crear()
		get_tree().current_scene.add_child(trozo)
		trozo.global_position = desde
		var animacion := trozo.create_tween()
		animacion.tween_property(trozo, "global_position", _entrada.global_position, 0.8)
		animacion.tween_callback(trozo.queue_free)
		await _esperar(0.12)
	await _esperar(0.8)


## Una cápsula sale del reactor y cae en fila junto a él.
func _sacar_capsula() -> void:
	var nueva := capsula.instantiate() as Node3D
	# Mientras vuela no se puede recoger; al caer, sí.
	if nueva is Area3D:
		nueva.monitoring = false
	get_tree().current_scene.add_child(nueva)
	var lado := Vector3((_capsulas_creadas % 6 - 2.5) * 1.3, 0, 0)
	_capsulas_creadas += 1
	nueva.global_position = _entrada.global_position
	var animacion := nueva.create_tween()
	animacion.tween_property(nueva, "global_position", _salida_capsulas.global_position + lado, 0.7) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if nueva is Area3D:
		animacion.tween_property(nueva, "monitoring", true, 0.0)


func _pintar_reactor() -> void:
	for malla in reactor.find_children("*", "MeshInstance3D", true, false):
		var m := malla as MeshInstance3D
		for inicio in colores_reactor:
			if String(m.name).begins_with(inicio):
				var material := StandardMaterial3D.new()
				material.albedo_color = colores_reactor[inicio]
				material.metallic = 0.5
				material.roughness = 0.45
				m.material_override = material
				break


func _preparar_brillo() -> void:
	for malla in reactor.find_children("*", "MeshInstance3D", true, false):
		var m := malla as MeshInstance3D
		if not _brilla(m.name):
			continue
		var original := (m.material_override if m.material_override else m.get_active_material(0)) as BaseMaterial3D
		var material: BaseMaterial3D = original.duplicate() if original else StandardMaterial3D.new()
		material.emission_enabled = true
		material.emission = color_brillo
		material.emission_energy_multiplier = 0.0
		m.material_override = material
		_materiales_brillo.append(material)


func _brilla(nombre: String) -> bool:
	for inicio in partes_que_brillan:
		if nombre.begins_with(inicio):
			return true
	return false


## Espera unos segundos. Si la escena se reinicia (tecla R), la espera se cancela sola.
func _esperar(segundos: float) -> Signal:
	var espera := create_tween()
	espera.tween_interval(segundos)
	return espera.finished
