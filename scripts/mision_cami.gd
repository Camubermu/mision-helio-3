extends Node
## Ordena la misión de la escena de Cami:
##   1. Viaje a la Luna (fase 2): despega de la base (level 1), falla el motor químico
##      y se aluniza solo con el motor de helio-3.
##   2. Superficie lunar: excavar regolito, hacer cápsulas de helio-3 y cargar la nave.
##   3. Viaje a la Tierra (fase 5): el jugador sube a la nave con E, despega con el
##      motor de helio-3 y aterriza en la base. Al final se pasa a la escena level 1.
## En "Empezar en" eliges por dónde empieza al probar con F6.

enum Inicio { VIAJE_A_LA_LUNA, SUPERFICIE_LUNAR, VIAJE_A_LA_TIERRA, DESDE_LA_BASE }

## Por dónde empieza la escena. "Desde la base" = como en el juego de verdad: si se abre
## esta escena directo, se va a la base (level 1) y el jugador camina hasta la nave.
## Las otras opciones sirven para probar una parte sin jugar todo.
@export var empezar_en := Inicio.DESDE_LA_BASE
## Escena de la base, donde empieza el juego.
@export_file("*.tscn") var escena_base := "res://scenes/niveles/level1.tscn"
## El nodo del viaje en cohete (scripts/viaje_espacial.gd).
@export var viaje: Node3D
## El jugador que camina por la Luna.
@export var jugador: Node3D
## La zona de carga de la nave (scripts/carga_nave.gd).
@export var carga_nave: Node
## El HUD, para esconder los datos durante el viaje.
@export var hud: CanvasLayer
## La superficie lunar (terreno de Emil). Se esconde durante el viaje para que
## no aparezca en las escenas del espacio ni de la Tierra.
@export var superficie: Node3D
## Escena a la que se pasa al llegar a la Tierra (vacío = quedarse).
@export_file("*.tscn") var escena_final := "res://scenes/niveles/level1.tscn"


## Terreno de la superficie (Terrain3D). Solo arma el suelo sólido cerca de un punto.
var _terreno: Node3D
## La escalera para subir a la nave (la crea la plataforma al empezar).
var _escalera: Node
## Cuándo empezó la misión (para la pantalla de resultados de la base).
var _inicio_msec := 0


func _ready() -> void:
	_inicio_msec = Time.get_ticks_msec()
	_poner_guantes()
	if jugador.has_node("Cuerpo"):
		_esconder_capsula()
	if superficie:
		_preparar_superficie()
		var terrenos := superficie.find_children("*", "Terrain3D", true, false)
		if not terrenos.is_empty():
			_terreno = terrenos[0]
			_terreno.set("collision_radius", 128)
	viaje.terminado.connect(_al_terminar_viaje)
	carga_nave.nave_abordada.connect(_viajar.bind(1))
	_preparar_luna()
	_conectar_escalera.call_deferred()
	match empezar_en:
		Inicio.DESDE_LA_BASE:
			# La base avisa (con esta marca) que el jugador ya subió a la nave.
			if Juego.has_meta("subio_en_la_base"):
				Juego.remove_meta("subio_en_la_base")
				_viajar.call_deferred(0)
			else:
				Juego.cambiar_nivel.call_deferred(escena_base)
		Inicio.VIAJE_A_LA_LUNA:
			_viajar.call_deferred(0)
		Inicio.VIAJE_A_LA_TIERRA:
			_viajar.call_deferred(1)


## Lo que cambia en cada partida: cuántas cápsulas pide la nave, las rocas y el oxígeno.
func _preparar_luna() -> void:
	# La nave necesita entre 15 y 20 cápsulas de helio-3 para despegar (al azar).
	if not Juego.has_meta("helio3_necesario"):
		Juego.set_meta("helio3_necesario", randi_range(15, 20))
	carga_nave.helio3_necesario = Juego.get_meta("helio3_necesario")
	# Las 3 rocas de prueba se cambian por un campo de 50 rocas (algunas sin helio-3).
	var suelo := get_parent().get_node_or_null("SueloLunar")
	if suelo:
		for roca in suelo.get_children():
			if roca.is_in_group("roca_minable"):
				roca.queue_free()
	var campo := Node3D.new()
	campo.name = "CampoDeRocas"
	campo.set_script(load("res://scripts/campo_rocas.gd"))
	campo.set("terreno", _terreno)
	var libres := [[Vector3(350, 0, 188), 47.0], [Vector3(278, 0, 286), 30.0], [Vector3(295, 0, 274), 10.0]]
	var reactor := get_parent().get_node_or_null("ProcesadorHelio") as Node3D
	if reactor:
		libres.append([reactor.global_position, 16.0])
	campo.set("lugares_libres", libres)
	get_parent().add_child.call_deferred(campo)
	# Oxígeno del traje.
	var oxigeno := CanvasLayer.new()
	oxigeno.name = "OxigenoTraje"
	oxigeno.set_script(load("res://scripts/oxigeno_traje.gd"))
	oxigeno.set("jugador", jugador)
	add_child(oxigeno)


## De la escena de la superficie solo se usa el terreno: su cielo y sus otros
## objetos se quitan para que manden el cielo y los objetos de esta escena.
func _preparar_superficie() -> void:
	for hijo in superficie.get_children():
		if hijo.is_class("Terrain3D"):
			continue
		if hijo is WorldEnvironment:
			hijo.queue_free()
		elif hijo is Node3D:
			(hijo as Node3D).visible = false
			hijo.process_mode = Node.PROCESS_MODE_DISABLED


func _physics_process(_delta: float) -> void:
	# El suelo sólido del terreno sigue al jugador (o al vehículo si lo maneja),
	# no a la cámara: así nada se cae mientras la cámara está en el espacio.
	if _terreno == null:
		return
	var objetivo: Node3D = jugador
	for vehiculo in get_tree().get_nodes_in_group("vehiculo"):
		if vehiculo.get("conduciendo"):
			objetivo = vehiculo
	if _terreno.get("collision_target") != objetivo:
		_terreno.set("collision_target", objetivo)


func _viajar(destino: int) -> void:
	for vehiculo in get_tree().get_nodes_in_group("vehiculo"):
		if vehiculo.get("conduciendo"):
			vehiculo.bajar()
	_encender_jugador(false)
	viaje.empezar(destino)


func _al_terminar_viaje() -> void:
	if viaje.destino == 0:
		await _bajar_por_la_escalera()
		_encender_jugador(true)
		Juego.mostrar_mensaje("Plan nuevo: la nave necesita %d cápsulas de helio-3. Excava regolito con el vehículo, déjalo en el reactor y sigue las etapas en la estación. ¡Vigila tu oxígeno!" % carga_nave.helio3_necesario)
	else:
		_guardar_resultado()
	if viaje.destino != 0 and not escena_final.is_empty():
		var espera := create_tween()
		espera.tween_interval(4.0)
		await espera.finished
		Juego.cambiar_nivel(escena_final)


## La cápsula blanca de player.tscn es solo de prueba: se esconde porque el jugador
## ya tiene el cuerpo del astronauta (nodo "Cuerpo").
func _esconder_capsula() -> void:
	for hijo in jugador.get_children():
		if hijo is MeshInstance3D and (hijo as MeshInstance3D).mesh is CapsuleMesh:
			(hijo as MeshInstance3D).visible = false


## Guantes del traje en la cámara del jugador. Se crean desde aquí (y no en la escena)
## para que el editor no los borre al guardar. Como el jugador ya tiene cuerpo 3D
## con sus manos, los guantes solo aparecen al estirar la mano para tocar algo (E).
func _poner_guantes() -> void:
	var camara := jugador.find_child("Camera3D", true, false) as Camera3D
	if camara == null or camara.has_node("Brazos"):
		return
	var brazos := Node3D.new()
	brazos.name = "Brazos"
	brazos.set_script(load("res://scripts/brazos_astronauta.gd"))
	brazos.set("solo_al_alcanzar", true)
	# Mismos colores que el traje naranja del astronauta (scenes/personajes/astronauta.tscn).
	brazos.set("color_manga", Color(0.86, 0.5, 0.3))
	brazos.set("color_mano", Color(0.9, 0.86, 0.78))
	camara.add_child(brazos)


## La escalera de la plataforma (scripts/escalera_plataforma.gd): por ahí se sube a la nave.
func _conectar_escalera() -> void:
	_escalera = get_tree().get_first_node_in_group("escalera_nave")
	if _escalera:
		_escalera.abordo.connect(_viajar.bind(1))


## Al alunizar, el astronauta sale de la nave y baja la escalera; ahí empieza a jugar.
func _bajar_por_la_escalera() -> void:
	if _escalera == null:
		return
	if superficie:
		superficie.visible = true
	_escalera.bajar()
	await _escalera.en_el_suelo
	jugador.global_position = _escalera.punto_pie() + Vector3.UP * 1.0
	jugador.global_rotation = Vector3(0, _escalera.giro_al_bajar(), 0)


## Guarda el resultado de la misión para la pantalla de la base (scripts/pantalla_mision.gd).
func _guardar_resultado() -> void:
	Juego.set_meta("resultado_mision", {
		"capsulas": carga_nave.get("cargado"),
		"necesarias": carga_nave.get("helio3_necesario"),
		# El aterrizaje en la base termina con el 30 % del tanque de helio-3.
		"tanque_helio": 30,
		"capsulas_extra": Juego.helio3,
		"minutos": int((Time.get_ticks_msec() - _inicio_msec) / 60000.0),
	})


## Prende o apaga al jugador de la superficie (y los datos del HUD).
func _encender_jugador(encendido: bool) -> void:
	jugador.visible = encendido
	if superficie:
		superficie.visible = encendido
	jugador.process_mode = Node.PROCESS_MODE_INHERIT if encendido else Node.PROCESS_MODE_DISABLED
	if hud:
		for nombre in ["Panel", "Mira"]:
			var nodo := hud.get_node_or_null(nombre) as CanvasItem
			if nodo:
				nodo.visible = encendido
	if encendido:
		var camaras := jugador.find_children("*", "Camera3D", true, false)
		if not camaras.is_empty():
			(camaras[0] as Camera3D).make_current()
