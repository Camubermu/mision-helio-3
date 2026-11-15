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
## Escena a la que se pasa al llegar a la Tierra (vacío = quedarse).
@export_file("*.tscn") var escena_final := "res://scenes/niveles/level1.tscn"


func _ready() -> void:
	viaje.terminado.connect(_al_terminar_viaje)
	carga_nave.nave_abordada.connect(_viajar.bind(1))
	match empezar_en:
		Inicio.VIAJE_A_LA_LUNA:
			_viajar.call_deferred(0)
		Inicio.VIAJE_A_LA_TIERRA:
			_viajar.call_deferred(1)


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
	elif not escena_final.is_empty():
		await get_tree().create_timer(4.0).timeout
		Juego.cambiar_nivel(escena_final)


## Prende o apaga al jugador de la superficie (y los datos del HUD).
func _encender_jugador(encendido: bool) -> void:
	jugador.visible = encendido
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
