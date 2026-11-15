extends Node3D
## Escalera de acero junto a la torre de la plataforma de lanzamiento.
## Sube en 4 tramos desde el suelo hasta el brazo de acceso que lleva a la nave.
## La arma este script (va como hija de la plataforma; la crea scripts/nave_en_plataforma.gd).
##
## - Es sólida: el jugador también puede subirla caminando.
## - subir(jugador): escena en tercera persona: el astronauta sube y entra a la nave.
## - bajar(): escena en tercera persona: el astronauta sale de la nave y baja al suelo.
## Si la escena del astronauta trae animaciones (por ejemplo, de Mixamo), se usan:
## ver "animacion_caminar", "animacion_subir", "animacion_bajar" y "animacion_quieto".

signal abordo
signal en_el_suelo

## Altura del piso del brazo de acceso (metros sobre el suelo).
@export var altura := 15.45
## El astronauta que se ve subir y bajar.
@export var escena_astronauta: PackedScene = preload("res://scenes/personajes/astronauta.tscn")
## Nombres de las animaciones del astronauta (si las tiene).
@export var animacion_caminar := "caminar"
@export var animacion_subir := "subir_escaleras"
@export var animacion_bajar := "bajar_escaleras"
@export var animacion_quieto := "quieto"
## Escalones por segundo al subir o bajar.
@export var escalones_por_segundo := 3.0
## Metros por segundo al caminar.
@export var velocidad_caminando := 1.6

const TRAMOS := 4
const ESCALONES := 20
const HUELLA := 0.3
const INICIO_X := 10.5
const FIN_X := 16.5
const CARRIL_A := 3.95
const CARRIL_B := 5.55
const ANCHO := 1.3
const ACERO := Color(0.55, 0.57, 0.6)
const AMARILLO := Color(0.95, 0.75, 0.1)

var ocupada := false
var _camara: Camera3D
var _actor: Node3D
var _animacion: AnimationPlayer
var _saltar := false


func _ready() -> void:
	add_to_group("escalera_nave")
	_armar()
	_camara = Camera3D.new()
	_camara.fov = 60.0
	_camara.far = 3000.0
	add_child(_camara)


func _unhandled_input(event: InputEvent) -> void:
	if ocupada and event.is_action_pressed("propulsor"):
		get_viewport().set_input_as_handled()
		_saltar = true


## Lugar al pie de la escalera (para el jugador, en coordenadas del mundo).
func punto_pie() -> Vector3:
	return to_global(Vector3(INICIO_X - 1.6, 0, CARRIL_A))


## Hacia dónde mira el jugador al bajar (lejos de la escalera).
func giro_al_bajar() -> float:
	return global_rotation.y + PI / 2.0


# --- Escenas de subir y bajar ---------------------------------------------------------

## El astronauta camina hasta la escalera, sube los 4 tramos, cruza el brazo y entra a la nave.
func subir(jugador: Node3D = null) -> void:
	if ocupada:
		return
	ocupada = true
	if jugador:
		jugador.visible = false
		jugador.process_mode = Node.PROCESS_MODE_DISABLED
	Juego.mostrar_mensaje("Subiendo a la nave... (Espacio para saltar la escena)")
	await _recorrer(_camino(), false)
	if not is_inside_tree():
		return
	_quitar_actor()
	ocupada = false
	abordo.emit()


## El astronauta sale de la nave, cruza el brazo y baja la escalera hasta el suelo.
func bajar() -> void:
	if ocupada:
		return
	ocupada = true
	Juego.mostrar_mensaje("Bajando de la nave... (Espacio para saltar la escena)")
	var camino := _camino()
	camino.reverse()
	await _recorrer(camino, true)
	if not is_inside_tree():
		return
	_quitar_actor()
	ocupada = false
	en_el_suelo.emit()


## Puntos del recorrido de abajo hacia arriba: [lugar, es_escalera].
func _camino() -> Array:
	var puntos := [[Vector3(INICIO_X - 1.6, 0, CARRIL_A), false], [Vector3(INICIO_X, 0, CARRIL_A), false]]
	var subida := altura / TRAMOS
	for tramo in TRAMOS:
		var y0 := subida * tramo
		var y1 := subida * (tramo + 1)
		if tramo % 2 == 0:
			puntos.append([Vector3(FIN_X, y1, CARRIL_A), true])
			puntos.append([Vector3(FIN_X + 0.75, y1, CARRIL_A), false])
			puntos.append([Vector3(FIN_X + 0.75, y1, CARRIL_B), false])
			puntos.append([Vector3(FIN_X, y1, CARRIL_B), false])
		else:
			puntos.append([Vector3(INICIO_X, y1, CARRIL_B), true])
			if tramo < TRAMOS - 1:
				puntos.append([Vector3(INICIO_X - 0.75, y1, CARRIL_B), false])
				puntos.append([Vector3(INICIO_X - 0.75, y1, CARRIL_A), false])
				puntos.append([Vector3(INICIO_X, y1, CARRIL_A), false])
	# Arriba: pasarela hasta el brazo de acceso y por el brazo hasta la nave.
	puntos.append([Vector3(INICIO_X - 0.75, altura, CARRIL_B), false])
	puntos.append([Vector3(INICIO_X - 0.75, altura, 0.0), false])
	puntos.append([Vector3(2.3, altura, 0.0), false])
	return puntos


func _recorrer(puntos: Array, bajando: bool) -> void:
	_saltar = false
	_crear_actor()
	_actor.position = puntos[0][0]
	_camara.make_current()
	for i in range(1, puntos.size()):
		if _saltar or not is_inside_tree():
			break
		var desde: Vector3 = puntos[i - 1][0]
		var hasta: Vector3 = puntos[i][0]
		# El tramo es escalera si el punto de arriba lo es.
		var es_escalera: bool = puntos[i][1] if not bajando else puntos[i - 1][1]
		await _mover(desde, hasta, es_escalera, bajando)
	if is_inside_tree() and not bajando:
		# Entra a la nave: se agacha un poco y desaparece por la escotilla.
		await _esperar(0.4)


func _mover(desde: Vector3, hasta: Vector3, es_escalera: bool, bajando: bool) -> void:
	var plano := Vector3(hasta.x - desde.x, 0, hasta.z - desde.z)
	if plano.length() > 0.01:
		_actor.rotation.y = atan2(-plano.x, -plano.z)
	var duracion := plano.length() / velocidad_caminando
	var nombre := animacion_caminar
	if es_escalera:
		duracion = ESCALONES / escalones_por_segundo
		nombre = animacion_bajar if bajando else animacion_subir
	_poner_animacion(nombre)
	var t := 0.0
	while t < duracion:
		if _saltar or not is_inside_tree():
			return
		t += get_process_delta_time()
		var avance := clampf(t / duracion, 0.0, 1.0)
		_actor.position = desde.lerp(hasta, avance)
		_balanceo(t, es_escalera, bajando)
		_seguir_con_camara()
		await get_tree().process_frame
	_actor.position = hasta


## Sin animaciones: el cuerpo sube y baja con cada paso y se inclina en la escalera.
func _balanceo(t: float, es_escalera: bool, bajando: bool) -> void:
	var modelo := _actor.get_child(0) as Node3D
	if modelo == null or _animacion != null:
		return
	var pasos := escalones_por_segundo if es_escalera else velocidad_caminando * 1.6
	var fase := t * pasos * PI
	modelo.position.y = absf(sin(fase)) * (0.07 if es_escalera else 0.04)
	modelo.rotation.z = sin(fase) * 0.04
	modelo.rotation.x = (-0.12 if not bajando else 0.08) if es_escalera else 0.0


func _seguir_con_camara() -> void:
	var objetivo := _actor.global_position + Vector3.UP * 1.0
	# Desde afuera, del lado contrario a las columnas de la plataforma.
	var lugar := to_global(_actor.position + Vector3(3.5, 3.0, 9.5))
	_camara.global_position = _camara.global_position.lerp(lugar, 0.08) if _camara.global_position.distance_to(lugar) < 20.0 else lugar
	_camara.look_at(objetivo, Vector3.UP)


func _crear_actor() -> void:
	_quitar_actor()
	_actor = Node3D.new()
	add_child(_actor)
	var modelo: Node3D = escena_astronauta.instantiate()
	_actor.add_child(modelo)
	_animacion = modelo.find_child("AnimationPlayer", true, false) as AnimationPlayer
	_camara.global_position = to_global(Vector3(INICIO_X - 6.0, 2.5, 12.0))


func _quitar_actor() -> void:
	if is_instance_valid(_actor):
		_actor.queue_free()
	_actor = null
	_animacion = null


func _poner_animacion(nombre: String) -> void:
	if _animacion == null:
		return
	if _animacion.has_animation(nombre):
		_animacion.play(nombre)
	elif _animacion.has_animation(animacion_caminar):
		_animacion.play(animacion_caminar)


func _esperar(segundos: float) -> void:
	var espera := create_tween()
	espera.tween_interval(segundos)
	await espera.finished


# --- Armado de la escalera ------------------------------------------------------------

func _armar() -> void:
	var acero := _material(ACERO, 0.7)
	var amarillo := _material(AMARILLO, 0.2)
	var subida := altura / TRAMOS
	var largo := FIN_X - INICIO_X
	for tramo in TRAMOS:
		var y0 := subida * tramo
		var carril := CARRIL_A if tramo % 2 == 0 else CARRIL_B
		var hacia_mas_x := tramo % 2 == 0
		_tramo(y0, subida, carril, hacia_mas_x, acero, amarillo)
		# Descanso al final del tramo.
		var y1 := y0 + subida
		var x_descanso := FIN_X + 0.75 if hacia_mas_x else INICIO_X - 0.75
		var fondo := (CARRIL_A + CARRIL_B) / 2.0
		_caja(Vector3(1.5, 0.12, 3.0), Vector3(x_descanso, y1 - 0.06, fondo), acero, true)
		# Columnas que sostienen el descanso.
		for z in [CARRIL_A - 0.6, CARRIL_B + 0.6]:
			var lado := 0.7 if hacia_mas_x else -0.7
			_caja(Vector3(0.18, y1, 0.18), Vector3(x_descanso + lado, y1 / 2.0, z), acero, false)
		_baranda(Vector3(x_descanso + (0.72 if hacia_mas_x else -0.72), y1, fondo), Vector3(0, 0, 3.0), amarillo)
	# Pasarela de arriba hasta el brazo de acceso (y piso del brazo para caminar).
	_caja(Vector3(1.5, 0.12, CARRIL_B + 0.6), Vector3(INICIO_X - 0.75, altura - 0.06, (CARRIL_B + 0.6) / 2.0), acero, true)
	_baranda(Vector3(INICIO_X - 1.5, altura, (CARRIL_B + 0.6) / 2.0), Vector3(0, 0, CARRIL_B + 0.6), amarillo)
	var piso_brazo := StaticBody3D.new()
	var forma := CollisionShape3D.new()
	var caja := BoxShape3D.new()
	caja.size = Vector3(9.7, 0.2, 1.2)
	forma.shape = caja
	forma.position = Vector3(6.6, altura - 0.1, 0)
	piso_brazo.add_child(forma)
	add_child(piso_brazo)
	# Letrero al pie de la escalera.
	var letrero := Label3D.new()
	letrero.text = "ACCESO A LA NAVE\n↑ 15 m"
	letrero.font_size = 64
	letrero.pixel_size = 0.006
	letrero.modulate = AMARILLO
	letrero.outline_size = 10
	letrero.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	letrero.position = Vector3(INICIO_X - 1.6, 2.6, CARRIL_A - 1.2)
	add_child(letrero)


## Un tramo de escalera: largueros, escalones, barandas y una rampa invisible para caminar.
func _tramo(y0: float, subida: float, carril: float, hacia_mas_x: bool, acero: Material, amarillo: Material) -> void:
	var largo := FIN_X - INICIO_X
	var x0 := INICIO_X if hacia_mas_x else FIN_X
	var direccion := 1.0 if hacia_mas_x else -1.0
	var contrahuella := subida / ESCALONES
	for i in ESCALONES:
		var x := x0 + direccion * (i + 0.5) * HUELLA
		var y := y0 + (i + 1) * contrahuella
		_caja(Vector3(HUELLA + 0.02, 0.05, ANCHO), Vector3(x, y - 0.025, carril), acero, false)
	var inclinacion := atan2(subida, largo)
	var hipotenusa := Vector2(largo, subida).length()
	var centro := Vector3(x0 + direccion * largo / 2.0, y0 + subida / 2.0, carril)
	for lado in [-1.0, 1.0]:
		var larguero := _caja(Vector3(hipotenusa, 0.3, 0.08), centro + Vector3(0, -0.1, lado * (ANCHO / 2.0 + 0.04)), acero, false)
		larguero.rotation.z = inclinacion * direccion
		var baranda := _caja(Vector3(hipotenusa, 0.05, 0.05), centro + Vector3(0, 1.0, lado * (ANCHO / 2.0 + 0.04)), amarillo, false)
		baranda.rotation.z = inclinacion * direccion
		# Pared invisible bajo la baranda: no se puede caer por los lados.
		_pared(Vector3(hipotenusa, 1.1, 0.06), centro + Vector3(0, 0.6, lado * (ANCHO / 2.0 + 0.04)), inclinacion * direccion)
		for k in 4:
			var avance := (k + 0.5) / 4.0
			var poste := Vector3(x0 + direccion * largo * avance, y0 + subida * avance + 0.5, carril + lado * (ANCHO / 2.0 + 0.04))
			_caja(Vector3(0.04, 1.0, 0.04), poste, amarillo, false)
	# Rampa invisible (lo que pisa el jugador al subir caminando).
	var cuerpo := StaticBody3D.new()
	var forma := CollisionShape3D.new()
	var caja := BoxShape3D.new()
	caja.size = Vector3(hipotenusa, 0.1, ANCHO)
	forma.shape = caja
	cuerpo.add_child(forma)
	cuerpo.position = centro
	cuerpo.rotation.z = inclinacion * direccion
	add_child(cuerpo)


## Baranda a lo largo del eje Z (descansos y pasarela), con dos postes.
func _baranda(centro: Vector3, largo: Vector3, material: Material) -> void:
	_caja(Vector3(0.05, 0.05, largo.z), centro + Vector3(0, 1.0, 0), material, false)
	_pared(Vector3(0.06, 1.1, largo.z), centro + Vector3(0, 0.55, 0), 0.0)
	for lado in [-0.5, 0.5]:
		_caja(Vector3(0.04, 1.0, 0.04), centro + Vector3(0, 0.5, largo.z * lado), material, false)


## Pared invisible (solo choque), girada en Z para seguir la inclinación de un tramo.
func _pared(tamano: Vector3, lugar: Vector3, giro_z: float) -> void:
	var cuerpo := StaticBody3D.new()
	var forma := CollisionShape3D.new()
	var figura := BoxShape3D.new()
	figura.size = tamano
	forma.shape = figura
	cuerpo.add_child(forma)
	cuerpo.position = lugar
	cuerpo.rotation.z = giro_z
	add_child(cuerpo)


func _caja(tamano: Vector3, lugar: Vector3, material: Material, solido: bool) -> MeshInstance3D:
	var malla := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = tamano
	malla.mesh = caja
	malla.material_override = material
	malla.position = lugar
	add_child(malla)
	if solido:
		var cuerpo := StaticBody3D.new()
		var forma := CollisionShape3D.new()
		var figura := BoxShape3D.new()
		figura.size = tamano
		forma.shape = figura
		cuerpo.add_child(forma)
		malla.add_child(cuerpo)
	return malla


func _material(color: Color, metal: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metal
	material.roughness = 0.45
	return material
