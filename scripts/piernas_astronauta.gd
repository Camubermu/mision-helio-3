extends Node3D
## Piernas y botas del traje de astronauta, para verlas al mirar hacia abajo.
## Va como hija del jugador (CharacterBody3D), a la altura de los pies.
## Las piernas dan pasos según la velocidad y se separan al ir por el aire.

const BLANCO := Color(0.92, 0.92, 0.9)
const SUELA := Color(0.3, 0.3, 0.32)

var _pierna_izquierda: Node3D
var _pierna_derecha: Node3D
var _fase := 0.0


func _ready() -> void:
	_pierna_izquierda = _crear_pierna(-0.13)
	_pierna_derecha = _crear_pierna(0.13)


func _process(delta: float) -> void:
	var cuerpo := get_parent() as CharacterBody3D
	if cuerpo == null:
		return
	var v := cuerpo.velocity
	var rapidez := Vector2(v.x, v.z).length()
	# Sentido del paso según si va hacia adelante o hacia atrás.
	var adelante := -cuerpo.global_basis.z
	var sentido := signf(Vector3(v.x, 0, v.z).dot(adelante)) if rapidez > 0.1 else 0.0
	_fase += delta * rapidez * 2.2
	var paso := sin(_fase) * clampf(rapidez / 3.0, 0.0, 1.0) * 30.0 * sentido
	var en_el_aire := 0.0 if cuerpo.is_on_floor() else 12.0
	_pierna_izquierda.rotation_degrees.x = paso + en_el_aire
	_pierna_derecha.rotation_degrees.x = -paso - en_el_aire * 0.5


## Pierna blanca con rodillera y bota gris; gira desde la cadera.
func _crear_pierna(x: float) -> Node3D:
	var cadera := Node3D.new()
	cadera.position = Vector3(x, 0.95, -0.05)
	add_child(cadera)
	var pierna := _pieza(CapsuleMesh.new(), BLANCO)
	(pierna.mesh as CapsuleMesh).radius = 0.11
	(pierna.mesh as CapsuleMesh).height = 0.9
	pierna.position.y = -0.45
	cadera.add_child(pierna)
	var rodilla := _pieza(SphereMesh.new(), BLANCO.darkened(0.08))
	(rodilla.mesh as SphereMesh).radius = 0.12
	(rodilla.mesh as SphereMesh).height = 0.2
	rodilla.position = Vector3(0, -0.45, -0.04)
	cadera.add_child(rodilla)
	var bota := _pieza(BoxMesh.new(), BLANCO.darkened(0.12))
	(bota.mesh as BoxMesh).size = Vector3(0.2, 0.16, 0.34)
	bota.position = Vector3(0, -0.86, -0.06)
	cadera.add_child(bota)
	var suela := _pieza(BoxMesh.new(), SUELA)
	(suela.mesh as BoxMesh).size = Vector3(0.22, 0.05, 0.36)
	suela.position = Vector3(0, -0.94, -0.06)
	cadera.add_child(suela)
	return cadera


static func _pieza(malla: Mesh, color: Color) -> MeshInstance3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	var pieza := MeshInstance3D.new()
	pieza.mesh = malla
	pieza.material_override = material
	return pieza
