extends Node3D
## Brazos del traje de astronauta vistos en primera persona.
## Va como hija de una Camera3D. Se mueven suave al respirar y al caminar,
## y la mano derecha se estira para tocar cosas (llamar a alcanzar()).

## Si es verdadero, la mano derecha se estira al presionar E.
@export var alcanzar_con_e := true
## Si es verdadero, las manos descansan abajo y relajadas (por ejemplo, sentado en la nave)
## y solo se levantan para tocar algo.
@export var en_reposo := false

const BLANCO := Color(0.74, 0.74, 0.72)
const GRIS := Color(0.55, 0.57, 0.6)
const AZUL := Color(0.15, 0.35, 0.8)

var _derecho: Node3D
var _izquierdo: Node3D
var _base_derecho := Vector3(0.17, -0.2, -0.36)
var _base_izquierdo := Vector3(-0.19, -0.22, -0.39)
## Giro del brazo al usar las manos y giro en reposo (más caído, muñeca relajada).
var _giro_activo := {}
var _giro_reposo := {}
var _tiempo := 0.0
var _estirando := false


func _ready() -> void:
	_derecho = _crear_brazo(1.0)
	_izquierdo = _crear_brazo(-1.0)
	if en_reposo:
		# Manos abajo, sobre las piernas: casi fuera de la vista.
		_base_derecho = Vector3(0.21, -0.46, -0.3)
		_base_izquierdo = Vector3(-0.23, -0.47, -0.31)
	for brazo in [_derecho, _izquierdo]:
		var lado := 1.0 if brazo == _derecho else -1.0
		_giro_activo[brazo] = brazo.rotation_degrees
		_giro_reposo[brazo] = Vector3(48, -8 * lado, 22 * lado)
		if en_reposo:
			brazo.rotation_degrees = _giro_reposo[brazo]
	_derecho.position = _base_derecho
	_izquierdo.position = _base_izquierdo


func _process(delta: float) -> void:
	_tiempo += delta
	var movimiento := _velocidad_del_cuerpo()
	var balanceo := sin(_tiempo * 6.0) * 0.02 * movimiento
	var respiracion := sin(_tiempo * 1.6) * 0.006
	if not _estirando:
		_derecho.position = _base_derecho + Vector3(0, respiracion + balanceo, 0)
	_izquierdo.position = _base_izquierdo + Vector3(0, respiracion - balanceo, 0)


func _unhandled_input(event: InputEvent) -> void:
	if alcanzar_con_e and is_visible_in_tree() and event.is_action_pressed("interactuar"):
		alcanzar()


## Estira la mano derecha hacia un punto (o hacia el frente si no hay punto) y la regresa.
func alcanzar(punto_global = null) -> void:
	if _estirando:
		return
	_estirando = true
	var destino := _base_derecho + Vector3(-0.06, 0.08, -0.22)
	if punto_global is Vector3:
		var local: Vector3 = get_parent().to_local(punto_global)
		# No se estira más de lo que alcanza el brazo.
		destino = local.limit_length(0.62) + Vector3(0.04, -0.1, 0.12)
	# Desde el reposo la mano tarda un poco más en subir y vuelve a bajar relajada.
	var subir := 0.3 if en_reposo else 0.18
	var bajar := 0.45 if en_reposo else 0.25
	var animacion := create_tween()
	animacion.tween_property(_derecho, "position", destino, subir).set_trans(Tween.TRANS_QUAD)
	animacion.parallel().tween_property(_derecho, "rotation_degrees", _giro_activo[_derecho], subir).set_trans(Tween.TRANS_QUAD)
	animacion.tween_interval(0.25 if en_reposo else 0.12)
	animacion.tween_property(_derecho, "position", _base_derecho, bajar).set_trans(Tween.TRANS_QUAD)
	var giro_final: Vector3 = _giro_reposo[_derecho] if en_reposo else _giro_activo[_derecho]
	animacion.parallel().tween_property(_derecho, "rotation_degrees", giro_final, bajar).set_trans(Tween.TRANS_QUAD)
	animacion.tween_callback(func(): _estirando = false)


func _velocidad_del_cuerpo() -> float:
	var nodo := get_parent()
	while nodo and not (nodo is CharacterBody3D):
		nodo = nodo.get_parent()
	if nodo is CharacterBody3D:
		var v := (nodo as CharacterBody3D).velocity
		return clampf(Vector2(v.x, v.z).length() / 4.0, 0.0, 1.0)
	return 0.0


## Brazo del traje (como el de los trajes de caminata espacial):
## antebrazo blanco con pliegues, anillo metálico de muñeca y guante con dedos.
## El origen del brazo está en la muñeca; el guante va hacia adelante (-Z).
func _crear_brazo(lado: float) -> Node3D:
	var brazo := Node3D.new()
	# El antebrazo viene desde abajo y desde afuera, y el guante sube un poco.
	brazo.rotation_degrees = Vector3(22, -18 * lado, 6 * lado)
	add_child(brazo)
	var tela := _material_tela(BLANCO)
	# Antebrazo con pliegues (anillos) hacia atrás.
	var antebrazo := _pieza(CylinderMesh.new(), BLANCO)
	(antebrazo.mesh as CylinderMesh).top_radius = 0.058
	(antebrazo.mesh as CylinderMesh).bottom_radius = 0.07
	(antebrazo.mesh as CylinderMesh).height = 0.42
	antebrazo.material_override = tela
	antebrazo.rotation_degrees.x = -90
	antebrazo.position.z = 0.23
	brazo.add_child(antebrazo)
	for k in 4:
		var pliegue := _pieza(TorusMesh.new(), BLANCO.darkened(0.1))
		(pliegue.mesh as TorusMesh).inner_radius = 0.055 + k * 0.003
		(pliegue.mesh as TorusMesh).outer_radius = 0.07 + k * 0.003
		pliegue.material_override = tela
		pliegue.rotation_degrees.x = 90
		pliegue.position.z = 0.12 + k * 0.07
		brazo.add_child(pliegue)
	# Anillo de la muñeca: metal azul con borde plateado.
	var anillo := _pieza(CylinderMesh.new(), Color(0.2, 0.32, 0.6))
	(anillo.mesh as CylinderMesh).top_radius = 0.062
	(anillo.mesh as CylinderMesh).bottom_radius = 0.062
	(anillo.mesh as CylinderMesh).height = 0.035
	(anillo.material_override as StandardMaterial3D).metallic = 0.7
	(anillo.material_override as StandardMaterial3D).roughness = 0.3
	anillo.rotation_degrees.x = 90
	anillo.position.z = 0.02
	brazo.add_child(anillo)
	var borde := _pieza(TorusMesh.new(), Color(0.8, 0.82, 0.85))
	(borde.mesh as TorusMesh).inner_radius = 0.058
	(borde.mesh as TorusMesh).outer_radius = 0.068
	(borde.material_override as StandardMaterial3D).metallic = 0.9
	borde.rotation_degrees.x = 90
	borde.position.z = 0.0
	brazo.add_child(borde)
	# Puño del guante (más ancho) y dorso.
	var puno := _pieza(CylinderMesh.new(), GRIS.lightened(0.35))
	(puno.mesh as CylinderMesh).top_radius = 0.055
	(puno.mesh as CylinderMesh).bottom_radius = 0.045
	(puno.mesh as CylinderMesh).height = 0.06
	puno.material_override = _material_tela(Color(0.68, 0.69, 0.7))
	puno.rotation_degrees.x = 90
	puno.position.z = -0.03
	brazo.add_child(puno)
	var mano := Node3D.new()
	mano.position.z = -0.1
	mano.rotation_degrees.z = -20 * lado
	brazo.add_child(mano)
	var palma := _pieza(SphereMesh.new(), Color(0.8, 0.8, 0.8))
	(palma.mesh as SphereMesh).radius = 0.05
	(palma.mesh as SphereMesh).height = 0.1
	palma.scale = Vector3(1.0, 0.45, 1.1)
	palma.material_override = _material_tela(Color(0.66, 0.67, 0.68))
	mano.add_child(palma)
	# Cuatro dedos un poco doblados, con puntas de goma oscura.
	for d in 4:
		var x := (-0.033 + d * 0.022) * lado
		var dedo := Node3D.new()
		dedo.position = Vector3(x, -0.004, -0.045)
		dedo.rotation_degrees.x = -25 - d * 4
		mano.add_child(dedo)
		var largo := 0.05 if d in [1, 2] else 0.042
		var falange := _pieza(CapsuleMesh.new(), Color(0.66, 0.67, 0.68))
		(falange.mesh as CapsuleMesh).radius = 0.011
		(falange.mesh as CapsuleMesh).height = largo
		falange.material_override = palma.material_override
		falange.rotation_degrees.x = 90
		falange.position.z = -largo * 0.4
		dedo.add_child(falange)
		var punta := _pieza(SphereMesh.new(), Color(0.25, 0.27, 0.32))
		(punta.mesh as SphereMesh).radius = 0.0115
		(punta.mesh as SphereMesh).height = 0.023
		punta.position.z = -largo * 0.85
		dedo.add_child(punta)
	var pulgar := Node3D.new()
	pulgar.position = Vector3(-0.045 * lado, -0.005, -0.005)
	pulgar.rotation_degrees = Vector3(-15, 40 * lado, 0)
	mano.add_child(pulgar)
	var pulgar_malla := _pieza(CapsuleMesh.new(), Color(0.66, 0.67, 0.68))
	(pulgar_malla.mesh as CapsuleMesh).radius = 0.012
	(pulgar_malla.mesh as CapsuleMesh).height = 0.045
	pulgar_malla.material_override = palma.material_override
	pulgar_malla.rotation_degrees.x = 90
	pulgar_malla.position.z = -0.02
	pulgar.add_child(pulgar_malla)
	return brazo


static func _material_tela(color: Color) -> StandardMaterial3D:
	var ruido := FastNoiseLite.new()
	ruido.frequency = 0.25
	var textura := NoiseTexture2D.new()
	textura.noise = ruido
	textura.width = 64
	textura.height = 64
	textura.seamless = true
	var tonos := Gradient.new()
	tonos.colors = PackedColorArray([color.darkened(0.12), color])
	textura.color_ramp = tonos
	var material := StandardMaterial3D.new()
	material.albedo_texture = textura
	material.uv1_triplanar = true
	material.uv1_scale = Vector3.ONE * 18.0
	material.roughness = 0.95
	return material


static func _pieza(malla: Mesh, color: Color) -> MeshInstance3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	var pieza := MeshInstance3D.new()
	pieza.mesh = malla
	pieza.material_override = material
	pieza.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return pieza
