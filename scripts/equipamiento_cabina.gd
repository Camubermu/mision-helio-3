extends Node3D
## Equipamiento dentro de la cabina del cohete para que no se vea como un chasis vacío:
## estantes de soporte vital, paneles de interruptores, bolsas de carga, tanques de
## oxígeno, extintor, botiquín, pasamanos amarillos, cables, rejillas de aire,
## luces de techo, casco de repuesto, insignia de la misión, laptop y arneses.
## Todo se arma con piezas simples desde este script (va como hija del ViajeEspacial).

## Radio interior de la pared de la cabina y alturas del piso y del techo.
const RADIO := 1.72
const PISO := 1.4
const TECHO := 5.1

const BLANCO := Color(0.86, 0.87, 0.88)
const GRIS := Color(0.45, 0.47, 0.5)
const OSCURO := Color(0.12, 0.13, 0.15)
const AMARILLO := Color(0.95, 0.75, 0.1)
const ROJO := Color(0.8, 0.1, 0.08)

var _tela: StandardMaterial3D


func _ready() -> void:
	_tela = _material_tela()
	_panel_interruptores(270.0)
	_estante_soporte_vital(300.0)
	_cables_y_rejilla(330.0)
	_bolsas_de_carga(250.0, ["COMIDA · DÍA 1-3", "AGUA POTABLE", "HERRAMIENTAS"])
	_bolsas_de_carga(345.0, ["ROPA", "MUESTRAS LUNARES"])
	_extintor_y_botiquin(28.0)
	_tanques_oxigeno(55.0)
	_letrero_escotilla(0.0)
	_luces_de_techo()
	_laptop()
	_un_solo_asiento()
	_arnes(0.0)


# --- Utilidades ------------------------------------------------------------------

## Un soporte pegado a la pared en el ángulo dado, mirando hacia el centro.
## Su frente es -Z (hacia el centro de la cabina).
func _en_pared(angulo: float, altura: float, profundidad := 0.0) -> Node3D:
	var soporte := Node3D.new()
	add_child(soporte)
	var direccion := Vector3(cos(deg_to_rad(angulo)), 0, sin(deg_to_rad(angulo)))
	soporte.position = direccion * (RADIO - profundidad) + Vector3(0, altura, 0)
	# Su eje Z apunta hacia afuera, así el frente (-Z) mira al centro.
	soporte.rotation.y = atan2(direccion.x, direccion.z)
	return soporte


func _caja(padre: Node3D, tamano: Vector3, color: Color, lugar := Vector3.ZERO, brillo := 0.0) -> MeshInstance3D:
	var malla := BoxMesh.new()
	malla.size = tamano
	return _poner(padre, malla, _material(color, brillo), lugar)


func _cilindro(padre: Node3D, radio: float, alto: float, color: Color, lugar := Vector3.ZERO, giro := Vector3.ZERO) -> MeshInstance3D:
	var malla := CylinderMesh.new()
	malla.top_radius = radio
	malla.bottom_radius = radio
	malla.height = alto
	var pieza := _poner(padre, malla, _material(color), lugar)
	pieza.rotation_degrees = giro
	return pieza


func _poner(padre: Node3D, malla: Mesh, material: Material, lugar: Vector3) -> MeshInstance3D:
	var pieza := MeshInstance3D.new()
	pieza.mesh = malla
	pieza.material_override = material
	pieza.position = lugar
	padre.add_child(pieza)
	return pieza


## Texto pegado a una pieza (se lee desde el centro de la cabina).
func _etiqueta(padre: Node3D, texto: String, lugar: Vector3, tamano := 0.0012, color := Color(0.1, 0.1, 0.12)) -> Label3D:
	var etiqueta := Label3D.new()
	etiqueta.text = texto
	etiqueta.pixel_size = tamano
	etiqueta.font_size = 32
	etiqueta.outline_size = 0
	etiqueta.modulate = color
	etiqueta.position = lugar
	etiqueta.rotation.y = PI
	padre.add_child(etiqueta)
	return etiqueta


func _material(color: Color, brillo := 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.6
	if brillo > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = brillo
	return material


## Tela blanca con textura suave (bolsas de carga, arneses).
static func _material_tela() -> StandardMaterial3D:
	var ruido := FastNoiseLite.new()
	ruido.frequency = 0.2
	var textura := NoiseTexture2D.new()
	textura.noise = ruido
	textura.width = 64
	textura.height = 64
	textura.seamless = true
	var tonos := Gradient.new()
	tonos.colors = PackedColorArray([Color(0.78, 0.78, 0.76), Color(0.93, 0.93, 0.91)])
	textura.color_ramp = tonos
	var material := StandardMaterial3D.new()
	material.albedo_texture = textura
	material.uv1_triplanar = true
	material.uv1_scale = Vector3.ONE * 6.0
	material.roughness = 1.0
	return material


# --- Equipos ----------------------------------------------------------------------

func _panel_interruptores(angulo: float) -> void:
	var panel := _en_pared(angulo, 3.4, 0.03)
	_caja(panel, Vector3(0.8, 0.55, 0.04), Color(0.2, 0.22, 0.26))
	_etiqueta(panel, "ENERGÍA PRINCIPAL", Vector3(0, 0.22, -0.025), 0.0011, Color(0.9, 0.9, 0.9))
	for fila in 3:
		for columna in 6:
			var x := -0.3 + columna * 0.12
			var y := 0.1 - fila * 0.14
			_cilindro(panel, 0.012, 0.05, Color(0.8, 0.8, 0.82), Vector3(x, y, -0.04), Vector3(70, 0, 0))
			var encendido := (fila + columna) % 3 != 0
			_caja(panel, Vector3(0.02, 0.02, 0.01), Color(0.2, 1, 0.3) if encendido else ROJO, Vector3(x, y + 0.05, -0.025), 2.5)
	# Pasamanos amarillo debajo del panel.
	var pasamanos := _en_pared(angulo, 2.6, 0.07)
	_cilindro(pasamanos, 0.018, 0.7, AMARILLO, Vector3.ZERO, Vector3(0, 0, 90))
	for x in [-0.33, 0.33]:
		_cilindro(pasamanos, 0.012, 0.08, GRIS, Vector3(x, 0, 0.04), Vector3(90, 0, 0))
	# Insignia de la misión arriba.
	var insignia := _en_pared(angulo, 4.5, 0.01)
	var disco := _cilindro(insignia, 0.22, 0.01, Color(0.08, 0.15, 0.4), Vector3.ZERO, Vector3(90, 0, 0))
	disco.material_override = _material(Color(0.08, 0.15, 0.4))
	_cilindro(insignia, 0.235, 0.008, AMARILLO, Vector3(0, 0, 0.004), Vector3(90, 0, 0))
	_etiqueta(insignia, "MISIÓN\nHELIO-3\n★ 2026 ★", Vector3(0, 0, -0.01), 0.0013, Color(1, 0.9, 0.5))


func _estante_soporte_vital(angulo: float) -> void:
	var estante := _en_pared(angulo, PISO + 0.85, 0.16)
	_caja(estante, Vector3(0.62, 1.7, 0.3), BLANCO.darkened(0.05))
	for i in 4:
		var y := 0.6 - i * 0.4
		_caja(estante, Vector3(0.56, 0.34, 0.02), BLANCO, Vector3(0, y, -0.155))
		_caja(estante, Vector3(0.14, 0.025, 0.03), GRIS, Vector3(0, y + 0.1, -0.17))
	_etiqueta(estante, "SOPORTE VITAL\nCO2 · O2 · TEMP", Vector3(0, 0.78, -0.17), 0.0011)
	_caja(estante, Vector3(0.05, 0.05, 0.01), Color(0.2, 1, 0.3), Vector3(0.22, 0.78, -0.17), 3.0)
	# Casco de repuesto sujeto arriba.
	var soporte := _en_pared(angulo, 4.25, 0.22)
	var casco := _poner(soporte, SphereMesh.new(), _material(BLANCO), Vector3.ZERO)
	(casco.mesh as SphereMesh).radius = 0.17
	(casco.mesh as SphereMesh).height = 0.34
	var visor := _poner(soporte, SphereMesh.new(), _material(Color(0.85, 0.6, 0.15)), Vector3(0, 0.0, -0.06))
	(visor.mesh as SphereMesh).radius = 0.13
	(visor.mesh as SphereMesh).height = 0.22
	(visor.material_override as StandardMaterial3D).metallic = 0.9
	(visor.material_override as StandardMaterial3D).roughness = 0.15


func _cables_y_rejilla(angulo: float) -> void:
	var colores := [Color(0.1, 0.1, 0.1), ROJO, Color(0.1, 0.3, 0.8), AMARILLO.darkened(0.2)]
	var cables := _en_pared(angulo, (PISO + TECHO) / 2.0, 0.05)
	for i in colores.size():
		_cilindro(cables, 0.015, TECHO - PISO, colores[i], Vector3(-0.05 + i * 0.033, 0, 0))
	for y in [-1.2, -0.4, 0.4, 1.2]:
		_caja(cables, Vector3(0.17, 0.03, 0.05), GRIS, Vector3(0, y, 0))
	var rejilla := _en_pared(angulo + 8.0, 4.5, 0.02)
	_caja(rejilla, Vector3(0.4, 0.25, 0.03), OSCURO)
	for i in 6:
		_caja(rejilla, Vector3(0.38, 0.012, 0.02), GRIS, Vector3(0, -0.1 + i * 0.04, -0.02))
	_etiqueta(rejilla, "AIRE", Vector3(0, 0.17, -0.02), 0.001, Color(0.85, 0.85, 0.85))


func _bolsas_de_carga(angulo: float, nombres: Array) -> void:
	for i in nombres.size():
		var bolsa := _en_pared(angulo, PISO + 0.2 + i * 0.4, 0.2)
		var cuerpo := _caja(bolsa, Vector3(0.5, 0.36, 0.36), BLANCO)
		cuerpo.material_override = _tela
		for x in [-0.15, 0.15]:
			_caja(bolsa, Vector3(0.04, 0.37, 0.37), Color(0.2, 0.25, 0.35), Vector3(x, 0, 0))
		_caja(bolsa, Vector3(0.22, 0.09, 0.005), Color(0.98, 0.98, 0.98), Vector3(0, 0.02, -0.183))
		_etiqueta(bolsa, nombres[i], Vector3(0, 0.02, -0.187), 0.0008)


func _extintor_y_botiquin(angulo: float) -> void:
	var extintor := _en_pared(angulo, PISO + 0.55, 0.12)
	_cilindro(extintor, 0.07, 0.5, ROJO)
	_cilindro(extintor, 0.025, 0.08, OSCURO, Vector3(0, 0.29, 0))
	_caja(extintor, Vector3(0.08, 0.03, 0.03), OSCURO, Vector3(0.03, 0.33, 0))
	_caja(extintor, Vector3(0.2, 0.06, 0.04), GRIS, Vector3(0, 0.12, 0.07))
	var letrero := _en_pared(angulo, PISO + 1.0, 0.01)
	_caja(letrero, Vector3(0.24, 0.08, 0.005), ROJO)
	_etiqueta(letrero, "EXTINTOR", Vector3(0, 0, -0.005), 0.0012, Color.WHITE)
	var botiquin := _en_pared(angulo, 3.3, 0.08)
	_caja(botiquin, Vector3(0.34, 0.26, 0.14), Color(0.95, 0.95, 0.95))
	_caja(botiquin, Vector3(0.12, 0.035, 0.005), ROJO, Vector3(0, 0, -0.072))
	_caja(botiquin, Vector3(0.035, 0.12, 0.005), ROJO, Vector3(0, 0, -0.072))
	_etiqueta(botiquin, "PRIMEROS AUXILIOS", Vector3(0, -0.1, -0.073), 0.0007)


func _tanques_oxigeno(angulo: float) -> void:
	for i in 2:
		var tanque := _en_pared(angulo + (i * 9.0 - 4.5), PISO + 0.65, 0.14)
		_cilindro(tanque, 0.11, 1.15, Color(0.15, 0.45, 0.2))
		var tapa := _poner(tanque, SphereMesh.new(), _material(Color(0.15, 0.45, 0.2)), Vector3(0, 0.58, 0))
		(tapa.mesh as SphereMesh).radius = 0.11
		(tapa.mesh as SphereMesh).height = 0.16
		_cilindro(tanque, 0.03, 0.1, GRIS, Vector3(0, 0.7, 0))
		_cilindro(tanque, 0.045, 0.02, AMARILLO, Vector3(0, 0.74, 0), Vector3(90, 0, 0))
		_caja(tanque, Vector3(0.25, 0.03, 0.03), GRIS, Vector3(0, 0.3, 0.1))
		_caja(tanque, Vector3(0.25, 0.03, 0.03), GRIS, Vector3(0, -0.3, 0.1))
		_etiqueta(tanque, "O2\nALTA PRESIÓN", Vector3(0, 0.15, -0.112), 0.0009, Color.WHITE)
	var pasamanos := _en_pared(angulo + 14.0, 3.0, 0.07)
	_cilindro(pasamanos, 0.018, 0.9, AMARILLO)


func _letrero_escotilla(angulo: float) -> void:
	var letrero := _en_pared(angulo, 4.35, 0.01)
	_caja(letrero, Vector3(0.9, 0.12, 0.005), AMARILLO)
	for i in 8:
		_caja(letrero, Vector3(0.04, 0.12, 0.004), OSCURO, Vector3(-0.42 + i * 0.12, 0, -0.004))
	_caja(letrero, Vector3(0.6, 0.08, 0.004), AMARILLO, Vector3(0, 0, -0.006))
	_etiqueta(letrero, "ESCOTILLA · NO ABRIR EN VUELO", Vector3(0, 0, -0.009), 0.0009)
	for lado in [-1.0, 1.0]:
		var riel := _en_pared(angulo + lado * 22.0, 3.0, 0.07)
		_cilindro(riel, 0.018, 1.0, AMARILLO)


func _luces_de_techo() -> void:
	for angulo in [45.0, 225.0]:
		var direccion := Vector3(cos(deg_to_rad(angulo)), 0, sin(deg_to_rad(angulo)))
		var lampara := Node3D.new()
		add_child(lampara)
		lampara.position = direccion * 0.9 + Vector3(0, TECHO - 0.03, 0)
		lampara.rotation.y = -deg_to_rad(angulo)
		_caja(lampara, Vector3(0.6, 0.03, 0.18), Color(0.25, 0.27, 0.3))
		_caja(lampara, Vector3(0.54, 0.01, 0.13), Color(1, 0.97, 0.9), Vector3(0, -0.02, 0), 2.5)


## Laptop en un brazo metálico, a la derecha del asiento.
func _laptop() -> void:
	var laptop := Node3D.new()
	add_child(laptop)
	laptop.position = Vector3(-0.3, 2.55, -1.15)
	laptop.rotation_degrees = Vector3(0, -152, 0)
	_cilindro(laptop, 0.015, 0.6, GRIS, Vector3(0.1, -0.3, 0.1), Vector3(0, 0, 0))
	_caja(laptop, Vector3(0.34, 0.015, 0.24), OSCURO)
	var pantalla := Node3D.new()
	pantalla.position = Vector3(0, 0.11, 0.12)
	pantalla.rotation_degrees.x = -15
	laptop.add_child(pantalla)
	_caja(pantalla, Vector3(0.34, 0.22, 0.012), OSCURO)
	_caja(pantalla, Vector3(0.31, 0.19, 0.002), Color(0.02, 0.1, 0.2), Vector3(0, 0, -0.007), 1.5)
	_etiqueta(pantalla, "TRAYECTORIA\nTIERRA ─── LUNA\nCorrección: 0,3 m/s\nDía de misión: 2", Vector3(0, 0, -0.009), 0.0006, Color(0.5, 1, 0.8))


## Arnés de 4 puntos en el respaldo de cada asiento.
## El cohete trae dos asientos: quita el de la derecha (vacío) y centra el del jugador.
func _un_solo_asiento() -> void:
	var cohete := get_parent().get_node_or_null("Cohete") as Node3D
	if cohete == null:
		return
	var al_centro := cohete.global_basis * Vector3(0, 0, 0.5)
	for pieza in cohete.find_children("Asiento_*", "Node3D", true, false):
		# Nombres como "Asiento_Base_0" o "Asiento_Brazo_1_-1": el número del asiento va en el tercer lugar.
		var partes := String(pieza.name).split("_")
		if partes.size() < 3:
			continue
		if partes[2] == "1":
			pieza.visible = false
		elif partes[2] == "0":
			(pieza as Node3D).global_position += al_centro


func _arnes(z: float) -> void:
	var arnes := Node3D.new()
	add_child(arnes)
	arnes.position = Vector3(0.24, 2.45, z)
	for lado in [-1.0, 1.0]:
		var correa := _caja(arnes, Vector3(0.012, 0.6, 0.045), Color(0.1, 0.15, 0.35), Vector3(0, 0.05, lado * 0.11))
		correa.rotation_degrees.x = lado * 12.0
	var hebilla := _caja(arnes, Vector3(0.02, 0.07, 0.09), Color(0.75, 0.76, 0.78), Vector3(-0.005, -0.2, 0))
	(hebilla.material_override as StandardMaterial3D).metallic = 0.8
