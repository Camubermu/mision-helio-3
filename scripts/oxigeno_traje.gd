extends CanvasLayer
## Oxígeno del traje del astronauta en la Luna.
## - Baja mientras el astronauta está afuera (caminando o en el vehículo).
## - Dentro de la estación lunar no baja (hay aire).
## - Se recarga en la esclusa de la estación: botón "RECARGA DE OXÍGENO" con E.
## - Si llega a 0, el equipo de la estación rescata al astronauta y lo lleva a la recarga.
## Lo crea scripts/mision_cami.gd. El casco muestra el valor (Juego.get_meta("oxigeno")).

## Minutos que dura el tanque lleno afuera.
@export var minutos := 7.0

var oxigeno := 100.0
var jugador: CharacterBody3D

var _barra: ProgressBar
var _texto: Label
var _caja: Control
var _relleno: StyleBoxFlat
var _avisos := {}
var _recargando := false
var _rescatando := false
var _conectado := false
var _tiempo := 0.0


func _ready() -> void:
	layer = 3
	_armar_barra()
	Juego.set_meta("oxigeno", oxigeno)


func _process(delta: float) -> void:
	_tiempo += delta
	_conectar_recarga()
	var afuera := _en_la_superficie()
	_caja.visible = afuera or _dentro_de_la_estacion()
	if afuera and not _recargando and not _rescatando and not _dentro_de_la_estacion():
		oxigeno = maxf(oxigeno - 100.0 / (minutos * 60.0) * delta, 0.0)
		_avisar()
		if oxigeno <= 0.0:
			_rescatar()
	_dibujar()
	Juego.set_meta("oxigeno", oxigeno)


## El astronauta está en la Luna (a pie o manejando), no en la nave ni en una escena.
func _en_la_superficie() -> bool:
	if jugador == null:
		return false
	if jugador.visible and jugador.can_process():
		return true
	return _vehiculo_manejado() != null


func _vehiculo_manejado() -> Node3D:
	for vehiculo in get_tree().get_nodes_in_group("vehiculo"):
		if vehiculo.get("conduciendo"):
			return vehiculo
	return null


func _dentro_de_la_estacion() -> bool:
	if jugador == null or not jugador.visible:
		return false
	for estacion in get_tree().get_nodes_in_group("estacion_lunar"):
		if estacion.has_method("caja_mundo") and estacion.caja_mundo().has_point(jugador.global_position):
			return true
	return false


func _avisar() -> void:
	for limite in [50, 25, 10]:
		if oxigeno <= limite and not _avisos.has(limite):
			_avisos[limite] = true
			match limite:
				50: Juego.mostrar_mensaje("Oxígeno del traje al 50 %. Recuerda: se recarga en la esclusa de la estación")
				25: Juego.mostrar_mensaje("¡Oxígeno al 25 %! Ve a la estación a recargarlo")
				10: Juego.mostrar_mensaje("¡ALERTA! Oxígeno al 10 %. ¡Vuelve YA a la esclusa de la estación!")


# --- Recarga y rescate -------------------------------------------------------------------

func _conectar_recarga() -> void:
	if _conectado:
		return
	var zona := get_tree().current_scene.find_child("ZonaRecarga", true, false) if get_tree().current_scene else null
	if zona and zona.has_signal("usada"):
		zona.usada.connect(recargar)
		_conectado = true


func recargar() -> void:
	if _recargando:
		return
	_recargando = true
	Juego.mostrar_mensaje("Recargando oxígeno... sssss")
	var brazos := jugador.find_child("Brazos", true, false) if jugador else null
	if brazos and brazos.has_method("alcanzar"):
		brazos.alcanzar()
	var animacion := create_tween()
	animacion.tween_property(self, "oxigeno", 100.0, 3.0 * (1.0 - oxigeno / 100.0) + 0.5)
	await animacion.finished
	_avisos.clear()
	_recargando = false
	Juego.mostrar_mensaje("Oxígeno al 100 %%. Tienes unos %d minutos afuera" % int(minutos))


func _rescatar() -> void:
	_rescatando = true
	var negro := ColorRect.new()
	negro.color = Color(0, 0, 0, 0)
	negro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(negro)
	Juego.mostrar_mensaje("¡Te quedaste sin oxígeno!")
	var oscurecer := create_tween()
	oscurecer.tween_property(negro, "color:a", 1.0, 1.5)
	await oscurecer.finished
	var vehiculo := _vehiculo_manejado()
	if vehiculo and vehiculo.has_method("bajar"):
		vehiculo.bajar()
	var recarga := get_tree().current_scene.find_child("RecargaOxigeno", true, false) as Node3D
	if recarga and jugador:
		jugador.global_position = recarga.global_position + recarga.global_basis.z * 1.4 + Vector3.UP * 1.0
		jugador.velocity = Vector3.ZERO
	oxigeno = 100.0
	_avisos.clear()
	Juego.mostrar_mensaje("El equipo de la estación te rescató y recargó tu traje. ¡Vigila el oxígeno!")
	var aclarar := create_tween()
	aclarar.tween_property(negro, "color:a", 0.0, 1.5)
	await aclarar.finished
	negro.queue_free()
	_rescatando = false


# --- Barra en pantalla ---------------------------------------------------------------------

func _armar_barra() -> void:
	_caja = VBoxContainer.new()
	_caja.position = Vector2(24, 232)
	_caja.custom_minimum_size = Vector2(300, 0)
	add_child(_caja)
	_texto = Label.new()
	_texto.add_theme_font_size_override("font_size", 20)
	_texto.add_theme_color_override("font_outline_color", Color.BLACK)
	_texto.add_theme_constant_override("outline_size", 5)
	_caja.add_child(_texto)
	_barra = ProgressBar.new()
	_barra.custom_minimum_size = Vector2(300, 18)
	_barra.show_percentage = false
	_relleno = StyleBoxFlat.new()
	_relleno.bg_color = Color(0.3, 0.85, 1.0)
	_barra.add_theme_stylebox_override("fill", _relleno)
	_caja.add_child(_barra)


func _dibujar() -> void:
	_barra.value = oxigeno
	var dentro := _dentro_de_la_estacion()
	_texto.text = "Oxígeno del traje: %d %%%s" % [ceili(oxigeno), "  (en la estación: no baja)" if dentro else ""]
	var critico := oxigeno <= 25.0
	var color := Color(1.0, 0.3, 0.25) if critico else (Color(1.0, 0.8, 0.3) if oxigeno <= 50.0 else Color(0.3, 0.85, 1.0))
	if oxigeno <= 10.0 and fmod(_tiempo, 0.6) < 0.3:
		color = Color(1, 1, 1)
	_relleno.bg_color = color
	_texto.add_theme_color_override("font_color", color if critico else Color(0.9, 0.95, 1.0))
