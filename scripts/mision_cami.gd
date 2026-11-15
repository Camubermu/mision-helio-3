extends Node
## Ordena la misión de la escena de Cami:
##   1. Viaje a la Luna (fase 2): despega de la base (level 1), falla el motor químico
##      y se aluniza solo con el motor de helio-3.
##   2. Superficie lunar: excavar regolito, hacer cápsulas de helio-3 y cargar la nave.
##   3. Viaje a la Tierra (fase 5): el jugador sube a la nave con E, despega con el
##      motor de helio-3 y aterriza en la base. Al final se pasa a la escena level 1.
## En "Empezar en" eliges por dónde empieza al probar con F6.

enum Inicio { VIAJE_A_LA_LUNA, SUPERFICIE_LUNAR, VIAJE_A_LA_TIERRA }

## Por dónde empieza la escena.
@export var empezar_en := Inicio.VIAJE_A_LA_LUNA
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
	match empezar_en:
		Inicio.VIAJE_A_LA_LUNA:
			_viajar.call_deferred(0)
		Inicio.VIAJE_A_LA_TIERRA:
			_viajar.call_deferred(1)


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
		_encender_jugador(true)
		Juego.mostrar_mensaje("Plan nuevo: produce helio-3. Sube al vehículo extractor, excava regolito y llévalo al reactor")
	else:
		_guardar_resultado()
	if viaje.destino != 0 and not escena_final.is_empty():
		var espera := create_tween()
		espera.tween_interval(4.0)
		await espera.finished
		Juego.cambiar_nivel(escena_final)


## Guantes del traje en la cámara del jugador. Se crean desde aquí (y no en la escena)
## para que el editor no los borre al guardar. Como el jugador ya tiene cuerpo 3D
## con sus manos, los guantes solo aparecen al estirar la mano para tocar algo (E).
## La cápsula blanca de player.tscn es solo de prueba: se esconde porque el jugador
## ya tiene el cuerpo del astronauta (nodo "Cuerpo").
func _esconder_capsula() -> void:
	for hijo in jugador.get_children():
		if hijo is MeshInstance3D and (hijo as MeshInstance3D).mesh is CapsuleMesh:
			(hijo as MeshInstance3D).visible = false


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
