extends Node3D
## Base de lanzamiento en la Tierra (va en level1, la sala donde empieza y termina el juego).
##
## Al empezar la misión (fase 1):
##   1. El jugador aparece mirando la pantalla con el plan de la misión.
##   2. Sale por la puerta y camina hasta la plataforma de lanzamiento.
##   3. Sube por la escalera de la torre (caminando, o con E al pie para verlo en tercera persona).
##   4. Al llegar arriba, entra a la nave y empieza la cuenta atrás del despegue (escena Cami).
## Al volver de la Luna (hay resultado de la misión): el jugador ve el resultado en la
## pantalla y luego aparecen los créditos (E junto a la pantalla, o solos después de un rato).
##
## Todo se arma desde este script para que el editor no lo borre al guardar la escena.

## Escena donde sigue la misión (despegue, viaje y Luna).
@export_file("*.tscn") var escena_mision := "res://scenes/niveles/Cami.tscn"
## Dónde va la plataforma (coincide con la base que se ve en el despegue de la escena Cami).
@export var lugar_plataforma := Vector3(25, -0.17, -12)
## Segundos que espera en la sala al volver antes de mostrar los créditos solos.
@export var segundos_antes_de_creditos := 40.0

const Creditos = preload("res://scripts/creditos.gd")

var _jugador: CharacterBody3D
var _escalera: Node
var _saliendo := false
var _creditos_mostrados := false


func _ready() -> void:
	# Esta escena también se usa como decorado en el despegue de Cami: ahí no hace nada.
	if get_tree().current_scene != get_parent():
		queue_free()
		return
	_jugador = get_parent().get_node_or_null("player") as CharacterBody3D
	_poner_suelo_exterior()
	_poner_plataforma()
	_preparar_jugador.call_deferred()
	if not _mision_terminada():
		_poner_zona_pantalla("E: siguiente página de la pantalla", func():
			var pantalla := get_parent().get_node_or_null("PantallaMision")
			if pantalla:
				pantalla.siguiente_pagina())
	if _mision_terminada():
		_preparar_final.call_deferred()
	else:
		Juego.mostrar_mensaje("Lee el plan de la misión en la pantalla. Después sal por la puerta y sube por la escalera de la torre hasta la nave")


func _mision_terminada() -> bool:
	return Juego.has_meta("resultado_mision")


# --- El jugador -------------------------------------------------------------------

func _preparar_jugador() -> void:
	if _jugador == null:
		return
	# Empieza mirando la pantalla de la misión (en la pared izquierda de la sala).
	var pantalla := get_parent().get_node_or_null("PantallaMision") as Node3D
	if pantalla:
		var mirar := pantalla.global_position - _jugador.global_position
		_jugador.rotation.y = atan2(-mirar.x, -mirar.z)
	# Cuerpo del astronauta. El jugador de esta escena está estirado (escala distinta en
	# cada eje), así que el cuerpo se ajusta para verse con su tamaño real.
	if not _jugador.has_node("Cuerpo"):
		var cuerpo: Node3D = load("res://scenes/personajes/astronauta_animado.tscn").instantiate()
		cuerpo.name = "Cuerpo"
		var escala := _jugador.scale
		cuerpo.scale = Vector3(0.911 / escala.x, 0.911 / escala.y, 0.911 / escala.z)
		cuerpo.position = Vector3(0, -1.0 / escala.y, 0.08 / escala.z)
		_jugador.add_child(cuerpo)
		for hijo in _jugador.get_children():
			if hijo is MeshInstance3D and (hijo as MeshInstance3D).mesh is CapsuleMesh:
				(hijo as MeshInstance3D).visible = false


# --- Suelo y plataforma ---------------------------------------------------------------

## El exterior de la base no tiene suelo sólido: se pone uno a la altura del terreno.
func _poner_suelo_exterior() -> void:
	var cuerpo := StaticBody3D.new()
	cuerpo.name = "SueloExterior"
	var forma := CollisionShape3D.new()
	var caja := BoxShape3D.new()
	caja.size = Vector3(148, 1, 22)
	forma.shape = caja
	forma.position = Vector3(0, -0.55, -10)
	cuerpo.add_child(forma)
	add_child(cuerpo)


func _poner_plataforma() -> void:
	var nave: Node3D = load("res://models/cohete_final/cohete_kodland_lujo_godot.tscn").instantiate()
	nave.name = "Nave"
	add_child(nave)
	var plataforma: Node3D = load("res://models/Lanzamiento/plataforma_kodland.tscn").instantiate()
	plataforma.name = "Plataforma"
	plataforma.set_script(load("res://scripts/nave_en_plataforma.gd"))
	plataforma.set("nave", nave)
	plataforma.set("gravedad_lunar", false)
	# La posición va antes de agregarla: al agregarla, la plataforma acomoda la nave encima.
	plataforma.position = lugar_plataforma
	add_child(plataforma)
	_escalera = plataforma.get_node_or_null("Escalera")
	if _escalera == null:
		return
	if _mision_terminada():
		# La misión ya terminó: no se vuelve a subir.
		var pie := plataforma.get_node_or_null("PieEscalera")
		if pie:
			pie.queue_free()
		return
	_escalera.abordo.connect(_ir_a_la_mision)
	_poner_llegada_arriba(plataforma)


## Zona en el brazo de acceso (arriba de la escalera): al entrar, el astronauta sube a la nave.
func _poner_llegada_arriba(plataforma: Node3D) -> void:
	var zona := Area3D.new()
	zona.name = "LlegadaArriba"
	var forma := CollisionShape3D.new()
	var caja := BoxShape3D.new()
	caja.size = Vector3(5.0, 2.5, 1.6)
	forma.shape = caja
	zona.add_child(forma)
	plataforma.add_child(zona)
	zona.position = Vector3(4.5, float(_escalera.get("altura")) + 1.2, 0)
	zona.body_entered.connect(func(cuerpo):
		if cuerpo == _jugador:
			_ir_a_la_mision())


## Zona con E delante de la pantalla de la sala.
func _poner_zona_pantalla(texto: String, al_usar: Callable) -> void:
	var pantalla := get_parent().get_node_or_null("PantallaMision") as Node3D
	if pantalla == null:
		return
	var zona := Area3D.new()
	zona.set_script(load("res://scripts/zona_e.gd"))
	zona.set("texto_ayuda", texto)
	var forma := CollisionShape3D.new()
	var caja := BoxShape3D.new()
	caja.size = Vector3(3.0, 2.5, 3.5)
	forma.shape = caja
	zona.add_child(forma)
	add_child(zona)
	zona.global_position = pantalla.global_position + pantalla.global_basis.z * 1.5 + Vector3.DOWN * 0.3
	zona.usada.connect(al_usar)


func _ir_a_la_mision() -> void:
	if _saliendo:
		return
	_saliendo = true
	if _jugador:
		_jugador.process_mode = Node.PROCESS_MODE_DISABLED
	Juego.mostrar_mensaje("Escotilla cerrada. ¡Prepárate para la cuenta atrás!")
	var negro := _pantalla_negra()
	var animacion := create_tween()
	animacion.tween_property(negro, "color:a", 1.0, 1.2)
	await animacion.finished
	Juego.set_meta("subio_en_la_base", true)
	Juego.cambiar_nivel(escena_mision)


func _pantalla_negra() -> ColorRect:
	var capa := CanvasLayer.new()
	capa.layer = 50
	add_child(capa)
	var negro := ColorRect.new()
	negro.color = Color(0, 0, 0, 0)
	negro.set_anchors_preset(Control.PRESET_FULL_RECT)
	negro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(negro)
	return negro


# --- Final: resultado y créditos ------------------------------------------------------------

func _preparar_final() -> void:
	Juego.mostrar_mensaje("¡Bienvenido de vuelta a la base! Mira el resultado de la misión en la pantalla (E junto a la pantalla: créditos)")
	_poner_zona_pantalla("Presiona E para terminar la misión y ver los créditos", mostrar_creditos)
	var espera := create_tween()
	espera.tween_interval(segundos_antes_de_creditos)
	espera.tween_callback(mostrar_creditos)


func mostrar_creditos() -> void:
	if _creditos_mostrados:
		return
	_creditos_mostrados = true
	Juego.ocultar_ayuda()
	if _jugador:
		_jugador.process_mode = Node.PROCESS_MODE_DISABLED
	var creditos := CanvasLayer.new()
	creditos.set_script(Creditos)
	add_child(creditos)
