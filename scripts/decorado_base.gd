extends Node3D
## Decorado de la base de lanzamiento en la Tierra (va en level1).
## Llena los espacios vacíos con el suelo y las instalaciones de una base real:
## edificio de ensamblaje, tanques de combustible, torre de agua (para enfriar la
## plataforma en el despegue), pararrayos, antena de comunicaciones, postes de luz,
## camión de carga y letrero de bienvenida. Todo con choque para no atravesarlo.
## También se ve en el despegue y el aterrizaje de la escena Cami (que usa level1 de fondo).

const BLANCO := Color(0.88, 0.89, 0.9)
const GRIS := Color(0.45, 0.47, 0.5)
const OSCURO := Color(0.16, 0.17, 0.19)
const NARANJA := Color(0.95, 0.45, 0.1)
const ROJO := Color(0.75, 0.12, 0.1)
const VERDE_K := Color(0.13, 0.82, 0.38)


func _ready() -> void:
	_suelo()
	_edificio_ensamblaje(Vector3(-36, 0, -46))
	_tanque_esfera(Vector3(62, 0, -28), 4.5, "LOX")
	_tanque_esfera(Vector3(62, 0, -44), 4.5, "LH2")
	for i in 3:
		_tanque_cilindro(Vector3(52 + i * 5.0, 0, 18), 1.6, 9.0)
	_torre_agua(Vector3(-12, 0, -42))
	for lugar in [Vector3(4, 0, -34), Vector3(48, 0, -34), Vector3(46, 0, 8)]:
		_pararrayos(lugar)
	_antena(Vector3(-22, 0, 9))
	for i in 6:
		_poste_luz(Vector3(-2 + i * 7.0, 0, 3.5))
	_camion(Vector3(10, 0, -24), 0.4)
	_letrero(Vector3(15, 0, -1.2))
	_conos()


# --- Suelo -------------------------------------------------------------------------

## Suelo grande de tierra y pasto seco debajo de todo: ya no se ve el vacío en los bordes.
func _suelo() -> void:
	var malla := MeshInstance3D.new()
	var plano := PlaneMesh.new()
	plano.size = Vector2(900, 900)
	malla.mesh = plano
	malla.position = Vector3(0, -0.3, -60)
	var ruido := FastNoiseLite.new()
	ruido.frequency = 0.02
	ruido.fractal_octaves = 5
	var textura := NoiseTexture2D.new()
	textura.noise = ruido
	textura.seamless = true
	textura.width = 512
	textura.height = 512
	var tonos := Gradient.new()
	tonos.offsets = PackedFloat32Array([0.0, 0.45, 0.7, 1.0])
	tonos.colors = PackedColorArray([Color(0.33, 0.3, 0.22), Color(0.42, 0.4, 0.27), Color(0.38, 0.42, 0.25), Color(0.5, 0.46, 0.34)])
	textura.color_ramp = tonos
	var material := StandardMaterial3D.new()
	material.albedo_texture = textura
	material.uv1_triplanar = true
	material.uv1_scale = Vector3.ONE * 0.03
	material.roughness = 1.0
	malla.material_override = material
	add_child(malla)
	_choque(Vector3(900, 0.2, 900), Vector3(0, -0.4, -60))


# --- Edificios e instalaciones -------------------------------------------------------

func _edificio_ensamblaje(lugar: Vector3) -> void:
	var edificio := _grupo(lugar)
	_caja(edificio, Vector3(26, 34, 22), Vector3(0, 17, 0), BLANCO, true)
	# Puerta gigante por donde sale el cohete armado.
	_caja(edificio, Vector3(10, 28, 0.3), Vector3(0, 14, 11.1), GRIS)
	for i in 7:
		_caja(edificio, Vector3(10, 0.25, 0.4), Vector3(0, 3 + i * 4.0, 11.2), OSCURO)
	# Franjas de color y el logo.
	_caja(edificio, Vector3(26.2, 1.2, 22.2), Vector3(0, 31, 0), VERDE_K)
	var logo := Label3D.new()
	logo.text = "K  KODLAND"
	logo.font_size = 180
	logo.pixel_size = 0.03
	logo.modulate = Color(0.1, 0.12, 0.15)
	# En la pared del costado que mira hacia la plataforma.
	logo.position = Vector3(13.15, 22, 0)
	logo.rotation_degrees.y = 90
	edificio.add_child(logo)
	var nombre := Label3D.new()
	nombre.text = "ASSEMBLY BUILDING"
	nombre.font_size = 120
	nombre.pixel_size = 0.02
	nombre.modulate = Color(0.1, 0.12, 0.15)
	nombre.position = Vector3(0, 30, 11.2)
	edificio.add_child(nombre)


func _tanque_esfera(lugar: Vector3, radio: float, texto: String) -> void:
	var tanque := _grupo(lugar)
	for i in 6:
		var angulo := TAU * i / 6.0
		_cilindro(tanque, 0.25, radio + 1.0, Vector3(cos(angulo) * radio * 0.8, (radio + 1.0) / 2.0, sin(angulo) * radio * 0.8), GRIS)
	var esfera := MeshInstance3D.new()
	var malla := SphereMesh.new()
	malla.radius = radio
	malla.height = radio * 2.0
	esfera.mesh = malla
	esfera.material_override = _material(BLANCO, 0.3)
	esfera.position.y = radio + 1.5
	tanque.add_child(esfera)
	var letrero := Label3D.new()
	letrero.text = texto
	letrero.font_size = 160
	letrero.pixel_size = 0.02
	letrero.modulate = Color(0.1, 0.2, 0.6)
	letrero.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	letrero.position = Vector3(0, radio + 1.5, 0)
	letrero.no_depth_test = false
	tanque.add_child(letrero)
	_choque(Vector3(radio * 2, radio * 2 + 1.5, radio * 2), lugar + Vector3(0, radio + 0.75, 0))


func _tanque_cilindro(lugar: Vector3, radio: float, alto: float) -> void:
	var tanque := _grupo(lugar)
	_cilindro(tanque, radio, alto, Vector3(0, alto / 2.0, 0), BLANCO)
	_cilindro(tanque, radio + 0.05, 0.4, Vector3(0, alto * 0.7, 0), NARANJA)
	_choque(Vector3(radio * 2, alto, radio * 2), lugar + Vector3(0, alto / 2.0, 0))


## Torre de agua: en el despegue se echa agua sobre la plataforma para frenar el ruido y el calor.
func _torre_agua(lugar: Vector3) -> void:
	var torre := _grupo(lugar)
	for x in [-2.0, 2.0]:
		for z in [-2.0, 2.0]:
			_cilindro(torre, 0.25, 22, Vector3(x, 11, z), GRIS)
	var deposito := MeshInstance3D.new()
	var malla := SphereMesh.new()
	malla.radius = 4.0
	malla.height = 7.0
	deposito.mesh = malla
	deposito.material_override = _material(BLANCO, 0.2)
	deposito.position.y = 25
	torre.add_child(deposito)
	_caja(torre, Vector3(8.2, 0.6, 0.2), Vector3(0, 25, 4.0), Color(0.2, 0.45, 0.85))
	_choque(Vector3(5, 22, 5), lugar + Vector3(0, 11, 0))


func _pararrayos(lugar: Vector3) -> void:
	var mastil := _grupo(lugar)
	_cilindro(mastil, 0.25, 50, Vector3(0, 25, 0), GRIS)
	_cilindro(mastil, 0.06, 6, Vector3(0, 53, 0), OSCURO)
	var luz := MeshInstance3D.new()
	var bola := SphereMesh.new()
	bola.radius = 0.4
	bola.height = 0.8
	luz.mesh = bola
	var rojo := _material(ROJO, 0.0)
	rojo.emission_enabled = true
	rojo.emission = Color(1, 0.1, 0.05)
	rojo.emission_energy_multiplier = 3.0
	luz.material_override = rojo
	luz.position.y = 50.5
	mastil.add_child(luz)
	_choque(Vector3(0.6, 50, 0.6), lugar + Vector3(0, 25, 0))


func _antena(lugar: Vector3) -> void:
	var antena := _grupo(lugar)
	_caja(antena, Vector3(3, 3, 3), Vector3(0, 1.5, 0), BLANCO, true)
	_cilindro(antena, 0.3, 4, Vector3(0, 5, 0), GRIS)
	var plato := MeshInstance3D.new()
	var malla := CylinderMesh.new()
	malla.top_radius = 3.2
	malla.bottom_radius = 0.6
	malla.height = 1.2
	plato.mesh = malla
	plato.material_override = _material(BLANCO, 0.4)
	plato.position.y = 7.5
	plato.rotation_degrees = Vector3(-50, 30, 0)
	antena.add_child(plato)


func _poste_luz(lugar: Vector3) -> void:
	var poste := _grupo(lugar)
	_cilindro(poste, 0.12, 8, Vector3(0, 4, 0), GRIS)
	_caja(poste, Vector3(0.8, 0.25, 0.4), Vector3(0, 8, 0), OSCURO)
	_choque(Vector3(0.3, 8, 0.3), lugar + Vector3(0, 4, 0))


func _camion(lugar: Vector3, giro: float) -> void:
	var camion := _grupo(lugar)
	camion.rotation.y = giro
	_caja(camion, Vector3(2.4, 2.4, 2.2), Vector3(0, 1.6, 3.2), NARANJA, true)
	_caja(camion, Vector3(2.0, 0.9, 0.1), Vector3(0, 2.1, 4.31), Color(0.2, 0.3, 0.4))
	_caja(camion, Vector3(2.5, 0.5, 6.5), Vector3(0, 0.75, -0.6), OSCURO, true)
	_cilindro(camion, 1.1, 5.5, Vector3(0, 2.1, -0.9), BLANCO).rotation_degrees.x = 90
	for x in [-1.2, 1.2]:
		for z in [2.6, -1.5, -3.0]:
			_cilindro(camion, 0.5, 0.4, Vector3(x, 0.5, z), Color(0.08, 0.08, 0.08)).rotation_degrees.z = 90


func _letrero(lugar: Vector3) -> void:
	var cartel := _grupo(lugar)
	for x in [-3.5, 3.5]:
		_cilindro(cartel, 0.12, 3.2, Vector3(x, 1.6, 0), GRIS)
	_caja(cartel, Vector3(8, 2.2, 0.2), Vector3(0, 3.6, 0), Color(0.08, 0.12, 0.2), true)
	var texto := Label3D.new()
	texto.text = "LAUNCH BASE\nMISSION HELIUM-3 · KODLAND"
	texto.font_size = 90
	texto.pixel_size = 0.009
	texto.modulate = Color(0.55, 0.95, 1.0)
	texto.position = Vector3(0, 3.6, 0.12)
	cartel.add_child(texto)
	var atras := texto.duplicate() as Label3D
	atras.position.z = -0.12
	atras.rotation_degrees.y = 180
	cartel.add_child(atras)


## Conos naranjas a lo largo del camino a la plataforma.
func _conos() -> void:
	for i in 7:
		var cono := MeshInstance3D.new()
		var malla := CylinderMesh.new()
		malla.top_radius = 0.03
		malla.bottom_radius = 0.25
		malla.height = 0.7
		cono.mesh = malla
		cono.material_override = _material(NARANJA, 0.0)
		cono.position = Vector3(6 + i * 4.0, 0.3, -4.6)
		add_child(cono)


# --- Piezas ----------------------------------------------------------------------------

func _grupo(lugar: Vector3) -> Node3D:
	var nodo := Node3D.new()
	nodo.position = lugar
	add_child(nodo)
	return nodo


func _caja(padre: Node3D, tamano: Vector3, lugar: Vector3, color: Color, solida := false) -> MeshInstance3D:
	var malla := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = tamano
	malla.mesh = caja
	malla.material_override = _material(color, 0.2)
	malla.position = lugar
	padre.add_child(malla)
	if solida:
		var cuerpo := StaticBody3D.new()
		var forma := CollisionShape3D.new()
		var figura := BoxShape3D.new()
		figura.size = tamano
		forma.shape = figura
		cuerpo.add_child(forma)
		malla.add_child(cuerpo)
	return malla


func _cilindro(padre: Node3D, radio: float, alto: float, lugar: Vector3, color: Color) -> MeshInstance3D:
	var malla := MeshInstance3D.new()
	var cilindro := CylinderMesh.new()
	cilindro.top_radius = radio
	cilindro.bottom_radius = radio
	cilindro.height = alto
	malla.mesh = cilindro
	malla.material_override = _material(color, 0.3)
	malla.position = lugar
	padre.add_child(malla)
	return malla


func _choque(tamano: Vector3, lugar: Vector3) -> void:
	var cuerpo := StaticBody3D.new()
	var forma := CollisionShape3D.new()
	var figura := BoxShape3D.new()
	figura.size = tamano
	forma.shape = figura
	cuerpo.add_child(forma)
	cuerpo.position = lugar
	add_child(cuerpo)


## Material con un poco de textura (ruido) para que no se vea de plástico.
func _material(color: Color, metal: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	var ruido := FastNoiseLite.new()
	ruido.frequency = 0.15
	var textura := NoiseTexture2D.new()
	textura.noise = ruido
	textura.seamless = true
	textura.width = 64
	textura.height = 64
	var tonos := Gradient.new()
	tonos.colors = PackedColorArray([color.darkened(0.12), color])
	textura.color_ramp = tonos
	material.albedo_texture = textura
	material.uv1_triplanar = true
	material.uv1_scale = Vector3.ONE * 0.5
	material.metallic = metal
	material.roughness = 0.6
	return material
