extends Node3D
## Piernas y botas del traje de astronauta, para verlas al mirar hacia abajo.
## Va como hija del jugador (CharacterBody3D), a la altura de los pies.
## Las piernas dan pasos según la velocidad y se separan al ir por el aire.

const BLANCO := Color(0.74, 0.74, 0.72)
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


## Pierna del traje: muslo y espinilla blancos con pliegues en la rodilla,
## anillo metálico en el tobillo y bota lunar con suela gruesa de goma.
## Gira desde la cadera, que queda un poco detrás de los ojos.
func _crear_pierna(x: float) -> Node3D:
	var cadera := Node3D.new()
	cadera.position = Vector3(x, 0.95, 0.14)
	add_child(cadera)
	var tela := _material_tela(BLANCO)
	var muslo := _pieza(CylinderMesh.new(), BLANCO)
	(muslo.mesh as CylinderMesh).top_radius = 0.095
	(muslo.mesh as CylinderMesh).bottom_radius = 0.08
	(muslo.mesh as CylinderMesh).height = 0.42
	muslo.material_override = tela
	muslo.position.y = -0.21
	cadera.add_child(muslo)
	for k in 3:
		var pliegue := _pieza(TorusMesh.new(), BLANCO)
		(pliegue.mesh as TorusMesh).inner_radius = 0.07
		(pliegue.mesh as TorusMesh).outer_radius = 0.09
		pliegue.material_override = tela
		pliegue.position.y = -0.42 - k * 0.04
		cadera.add_child(pliegue)
	var espinilla := _pieza(CylinderMesh.new(), BLANCO)
	(espinilla.mesh as CylinderMesh).top_radius = 0.078
	(espinilla.mesh as CylinderMesh).bottom_radius = 0.07
	(espinilla.mesh as CylinderMesh).height = 0.36
	espinilla.material_override = tela
	espinilla.position.y = -0.66
	cadera.add_child(espinilla)
	var tobillo := _pieza(CylinderMesh.new(), Color(0.2, 0.32, 0.6))
	(tobillo.mesh as CylinderMesh).top_radius = 0.075
	(tobillo.mesh as CylinderMesh).bottom_radius = 0.075
	(tobillo.mesh as CylinderMesh).height = 0.03
	(tobillo.material_override as StandardMaterial3D).metallic = 0.7
	tobillo.position.y = -0.84
	cadera.add_child(tobillo)
	# Bota: caña blanca, empeine redondeado y suela gris con tacos.
	var cana := _pieza(CylinderMesh.new(), BLANCO)
	(cana.mesh as CylinderMesh).top_radius = 0.08
	(cana.mesh as CylinderMesh).bottom_radius = 0.09
	(cana.mesh as CylinderMesh).height = 0.1
	cana.material_override = _material_tela(Color(0.7, 0.7, 0.68))
	cana.position.y = -0.9
	cadera.add_child(cana)
	var empeine := _pieza(SphereMesh.new(), BLANCO)
	(empeine.mesh as SphereMesh).radius = 0.08
	(empeine.mesh as SphereMesh).height = 0.12
	empeine.scale = Vector3(1.05, 0.8, 1.6)
	empeine.material_override = cana.material_override
	empeine.position = Vector3(0, -0.93, -0.07)
	cadera.add_child(empeine)
	var suela := _pieza(BoxMesh.new(), SUELA)
	(suela.mesh as BoxMesh).size = Vector3(0.17, 0.045, 0.32)
	suela.position = Vector3(0, -0.975, -0.05)
	cadera.add_child(suela)
	for k in 5:
		var taco := _pieza(BoxMesh.new(), SUELA.darkened(0.3))
		(taco.mesh as BoxMesh).size = Vector3(0.175, 0.012, 0.025)
		taco.position = Vector3(0, -0.998, -0.18 + k * 0.065)
		cadera.add_child(taco)
	# Polvo lunar pegado en la punta de la bota.
	var polvo := _pieza(SphereMesh.new(), Color(0.55, 0.53, 0.5))
	(polvo.mesh as SphereMesh).radius = 0.06
	(polvo.mesh as SphereMesh).height = 0.06
	polvo.scale = Vector3(1.3, 0.5, 1.0)
	polvo.position = Vector3(0, -0.955, -0.16)
	cadera.add_child(polvo)
	return cadera


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
	material.uv1_scale = Vector3.ONE * 14.0
	material.roughness = 0.95
	return material


static func _pieza(malla: Mesh, color: Color) -> MeshInstance3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	var pieza := MeshInstance3D.new()
	pieza.mesh = malla
	pieza.material_override = material
	return pieza
