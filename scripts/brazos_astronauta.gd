extends Node3D
## Brazos del traje de astronauta vistos en primera persona.
## Va como hija de una Camera3D. Se mueven suave al respirar y al caminar,
## y la mano derecha se estira para tocar cosas (llamar a alcanzar()).

## Si es verdadero, la mano derecha se estira al presionar E.
@export var alcanzar_con_e := true

const BLANCO := Color(0.92, 0.92, 0.9)
const GRIS := Color(0.55, 0.57, 0.6)
const AZUL := Color(0.15, 0.35, 0.8)

var _derecho: Node3D
var _izquierdo: Node3D
var _base_derecho := Vector3(0.2, -0.24, -0.3)
var _base_izquierdo := Vector3(-0.22, -0.26, -0.33)
var _tiempo := 0.0
var _estirando := false


func _ready() -> void:
	_derecho = _crear_brazo(1.0)
	_izquierdo = _crear_brazo(-1.0)
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
	var animacion := create_tween()
	animacion.tween_property(_derecho, "position", destino, 0.18).set_trans(Tween.TRANS_QUAD)
	animacion.tween_interval(0.12)
	animacion.tween_property(_derecho, "position", _base_derecho, 0.25).set_trans(Tween.TRANS_QUAD)
	animacion.tween_callback(func(): _estirando = false)


func _velocidad_del_cuerpo() -> float:
	var nodo := get_parent()
	while nodo and not (nodo is CharacterBody3D):
		nodo = nodo.get_parent()
	if nodo is CharacterBody3D:
		var v := (nodo as CharacterBody3D).velocity
		return clampf(Vector2(v.x, v.z).length() / 4.0, 0.0, 1.0)
	return 0.0


## Manga blanca con franja azul y guante gris, apuntando hacia adelante.
func _crear_brazo(lado: float) -> Node3D:
	var brazo := Node3D.new()
	brazo.rotation_degrees = Vector3(4, 14 * lado, 0)
	add_child(brazo)
	var manga := _pieza(CapsuleMesh.new(), BLANCO)
	(manga.mesh as CapsuleMesh).radius = 0.075
	(manga.mesh as CapsuleMesh).height = 0.5
	manga.rotation_degrees.x = 90
	manga.position.z = 0.16
	brazo.add_child(manga)
	var franja := _pieza(CylinderMesh.new(), AZUL)
	(franja.mesh as CylinderMesh).top_radius = 0.079
	(franja.mesh as CylinderMesh).bottom_radius = 0.079
	(franja.mesh as CylinderMesh).height = 0.04
	franja.rotation_degrees.x = 90
	franja.position.z = 0.05
	brazo.add_child(franja)
	var puno := _pieza(CylinderMesh.new(), GRIS)
	(puno.mesh as CylinderMesh).top_radius = 0.07
	(puno.mesh as CylinderMesh).bottom_radius = 0.08
	(puno.mesh as CylinderMesh).height = 0.06
	puno.rotation_degrees.x = 90
	puno.position.z = -0.1
	brazo.add_child(puno)
	var guante := _pieza(BoxMesh.new(), GRIS.darkened(0.15))
	(guante.mesh as BoxMesh).size = Vector3(0.1, 0.055, 0.13)
	guante.position = Vector3(0, -0.005, -0.18)
	brazo.add_child(guante)
	var pulgar := _pieza(CapsuleMesh.new(), GRIS.darkened(0.15))
	(pulgar.mesh as CapsuleMesh).radius = 0.018
	(pulgar.mesh as CapsuleMesh).height = 0.08
	pulgar.rotation_degrees = Vector3(90, 0, 35 * lado)
	pulgar.position = Vector3(-0.055 * lado, 0.0, -0.16)
	brazo.add_child(pulgar)
	return brazo


static func _pieza(malla: Mesh, color: Color) -> MeshInstance3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	var pieza := MeshInstance3D.new()
	pieza.mesh = malla
	pieza.material_override = material
	pieza.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return pieza
