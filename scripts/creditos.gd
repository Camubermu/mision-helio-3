extends CanvasLayer
## Créditos del juego: suben por la pantalla al terminar la misión.
## Al final, Enter (o E) vuelve a empezar la misión desde la base.
## Para cambiar los nombres, edita "lineas" (cada texto es una línea; "" deja un espacio,
## y las que empiezan con "#" son títulos).

@export var lineas: PackedStringArray = [
	"#MISIÓN HELIO-3",
	"Un viaje a la Luna para traer helio-3, el combustible del futuro",
	"",
	"",
	"#EQUIPO",
	"Camilo · Líder del equipo y escena de la misión",
	"Patrox · Fase 1: Despegue desde la base",
	"Elgamer202122 · Fase 2: Viaje a la Luna",
	"Emil · Fase 3: Exploración de la superficie lunar",
	"Seledy96 · Fase 4: Minería y estación lunar",
	"MrNano12 · Fase 5: Despegue de la Luna",
	"",
	"",
	"#LA CIENCIA DE LA MISIÓN",
	"El helio-3 llega a la Luna con el viento solar",
	"Se extrae del regolito: clasificar, calentar a 700-1.000 °C,",
	"capturar los gases, separar los isótopos y almacenar",
	"Algún día podría dar energía limpia con reactores de fusión",
	"",
	"",
	"#HERRAMIENTAS",
	"Motor de juego: Godot 4",
	"Terreno lunar: Terrain3D",
	"Animaciones del astronauta: Mixamo",
	"Modelos 3D: hechos por el equipo",
	"",
	"",
	"#GRACIAS",
	"NASA Space Apps Challenge",
	"Kodland",
	"Y a ti, por completar la misión",
	"",
	"",
	"",
	"#FIN",
]
## Segundos que tardan los créditos en pasar.
@export var duracion := 38.0

var _columna: VBoxContainer
var _aviso: Label
var _terminado := false


func _ready() -> void:
	layer = 60
	var fondo := ColorRect.new()
	fondo.color = Color(0.0, 0.01, 0.04, 0.0)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	create_tween().tween_property(fondo, "color:a", 1.0, 1.5)
	_estrellas(fondo)

	var ancho := get_viewport().get_visible_rect().size.x
	_columna = VBoxContainer.new()
	_columna.alignment = BoxContainer.ALIGNMENT_CENTER
	_columna.custom_minimum_size.x = ancho
	_columna.size.x = ancho
	_columna.add_theme_constant_override("separation", 10)
	add_child(_columna)
	for texto in lineas:
		var etiqueta := Label.new()
		etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		etiqueta.custom_minimum_size.x = ancho
		if texto.begins_with("#"):
			etiqueta.text = texto.substr(1)
			etiqueta.add_theme_font_size_override("font_size", 44)
			etiqueta.add_theme_color_override("font_color", Color(0.45, 0.85, 1.0))
		else:
			etiqueta.text = texto if not texto.is_empty() else " "
			etiqueta.add_theme_font_size_override("font_size", 28)
			etiqueta.add_theme_color_override("font_color", Color(0.92, 0.95, 1.0))
		_columna.add_child(etiqueta)

	_aviso = Label.new()
	_aviso.text = "Presiona Enter para jugar otra vez"
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_aviso.add_theme_font_size_override("font_size", 26)
	_aviso.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	_aviso.modulate.a = 0.0
	add_child(_aviso)
	_pasar.call_deferred()


func _pasar() -> void:
	var alto := get_viewport().get_visible_rect().size
	await get_tree().process_frame
	_columna.reset_size()
	_columna.position = Vector2(0, alto.y)
	_aviso.position = Vector2(alto.x / 2.0 - 260, alto.y - 70)
	_aviso.size.x = 520
	# Sube hasta que la palabra "FIN" queda en el centro de la pantalla.
	var final := alto.y / 2.0 - _columna.size.y + 30.0
	var animacion := create_tween()
	animacion.tween_property(_columna, "position:y", final, duracion)
	animacion.tween_callback(func(): _terminado = true)
	animacion.tween_property(_aviso, "modulate:a", 1.0, 0.8)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interactuar"):
		get_viewport().set_input_as_handled()
		if _terminado:
			_jugar_otra_vez()
		else:
			# Adelanta los créditos.
			Engine.time_scale = 4.0 if is_equal_approx(Engine.time_scale, 1.0) else 1.0


func _jugar_otra_vez() -> void:
	Engine.time_scale = 1.0
	Juego.remove_meta("resultado_mision")
	Juego.reiniciar_datos()
	get_tree().reload_current_scene()


func _exit_tree() -> void:
	Engine.time_scale = 1.0


## Unas estrellas quietas de fondo.
func _estrellas(fondo: Control) -> void:
	var azar := RandomNumberGenerator.new()
	azar.seed = 7
	for i in 120:
		var punto := ColorRect.new()
		var tam := azar.randf_range(1.5, 3.5)
		punto.size = Vector2(tam, tam)
		punto.color = Color(1, 1, 1, azar.randf_range(0.3, 0.9))
		punto.anchor_left = azar.randf()
		punto.anchor_top = azar.randf()
		punto.anchor_right = punto.anchor_left
		punto.anchor_bottom = punto.anchor_top
		fondo.add_child(punto)
