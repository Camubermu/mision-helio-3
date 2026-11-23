extends CanvasLayer
## Panel de comunicaciones con la Tierra dentro de la cabina.
## Cuando falla el motor químico (y luego en el cambio de plan), Control de Misión llama
## por radio y el astronauta responde eligiendo botones. Si la respuesta no coincide con
## lo que dice el monitor, Control pide revisarlo (teclas 1-4) y vuelve a preguntar.
## Mientras se habla, el viaje se detiene. Lo crea scripts/viaje_espacial.gd.

signal termino

## Conversaciones: cada paso tiene lo que dice Control y las respuestas.
## Cada respuesta: [texto del botón, paso siguiente, lo que contesta Control (opcional)].
## "fin" termina la conversación.
const FALLA := {
	"inicio": {
		"control": "Helium-3, this is Mission Control on Earth. We see an alarm on your ship. What is happening?",
		"respuestas": [
			["The chemical engine failed when leaving the atmosphere", "combustible"],
			["There is a leak in the chemical fuel tank", "combustible"],
			["We don't know, the alarm won't stop", "inicio", "Check the DAMAGE page on the monitor (key 3) and tell me what you see."],
		],
	},
	"combustible": {
		"control": "Copy. We confirm the failure in your data. How much chemical fuel do you have left?",
		"respuestas": [
			["0%: the tank is empty", "plasma"],
			["Half a tank", "combustible", "Negative, Helium-3. Check the FUEL page on the monitor (key 1): your data says otherwise."],
			["The tank is full", "combustible", "Negative. Check the FUEL page (key 1) before answering."],
		],
	},
	"plasma": {
		"control": "Understood: no chemical engine. Activate the helium-3 plasma engine to continue to the Moon. Do you confirm?",
		"respuestas": [
			["Activate the helium-3 plasma engine", "listo"],
			["Is it safe?", "plasma", "Yes. The helium-3 engine is what you came to test. Check the ENGINES page (key 2): it is ready."],
		],
	},
	"listo": {
		"control": "Helium-3 engine on and stable. Good job, crew. Continue to the Moon. Control out.",
		"respuestas": [["Copy, Control. Helium-3 out", "fin"]],
	},
}
const CAMBIO_DE_PLAN := {
	"inicio": {
		"control": "Helium-3, we ran the numbers: the helium-3 in your tank is only enough to land on the Moon, not to come back.",
		"respuestas": [
			["So what do we do?", "plan"],
			["Can we come back now?", "inicio", "Negative. There is no chemical fuel left and the helium-3 is not enough to turn around."],
		],
	},
	"plan": {
		"control": "There is a station and a reactor on the Moon. Dig regolith, process it in the station and load the ship with helium-3 capsules.",
		"respuestas": [
			["Why does the regolith have helium-3?", "plan", "The solar wind left it in the lunar dust over billions of years. There is almost none on Earth."],
			["Understood, Control. We will produce helium-3", "fin2"],
		],
	},
	"fin2": {
		"control": "The whole Earth is counting on you. Watch your suit oxygen. Control out.",
		"respuestas": [["Copy. Helium-3 out", "fin"]],
	},
}

var activa := false

var _conversacion: Dictionary
var _panel: PanelContainer
var _historial: VBoxContainer
var _botones: VBoxContainer
var _desplazar: ScrollContainer
var _pitar: Callable
var _al_tocar: Callable


## "pitar": función para los tonos Quindar de la radio. "al_tocar": la mano toca el panel.
func configurar(pitar: Callable, al_tocar: Callable) -> void:
	_pitar = pitar
	_al_tocar = al_tocar


func _ready() -> void:
	layer = 6
	_armar()
	_panel.visible = false


func empezar_falla() -> void:
	_empezar(FALLA)


func empezar_cambio_de_plan() -> void:
	_empezar(CAMBIO_DE_PLAN)


func _empezar(conversacion: Dictionary) -> void:
	_conversacion = conversacion
	activa = true
	for hijo in _historial.get_children():
		hijo.queue_free()
	_panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_ir_a("inicio")


func _ir_a(paso: String) -> void:
	if paso == "fin":
		_terminar()
		return
	var datos: Dictionary = _conversacion[paso]
	_linea("CONTROL (Earth)", datos.control, Color(0.55, 1.0, 0.65))
	_mostrar_respuestas(datos.respuestas)


func _mostrar_respuestas(respuestas: Array) -> void:
	for hijo in _botones.get_children():
		hijo.queue_free()
	for respuesta in respuestas:
		var boton := Button.new()
		boton.text = "▶  " + String(respuesta[0])
		boton.alignment = HORIZONTAL_ALIGNMENT_LEFT
		boton.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		boton.custom_minimum_size = Vector2(0, 44)
		boton.add_theme_font_size_override("font_size", 20)
		boton.pressed.connect(_responder.bind(respuesta))
		_botones.add_child(boton)


func _responder(respuesta: Array) -> void:
	for hijo in _botones.get_children():
		(hijo as Button).disabled = true
	if _al_tocar.is_valid():
		_al_tocar.call()
	_linea("YOU (Helium-3)", respuesta[0], Color(0.6, 0.85, 1.0))
	if _pitar.is_valid():
		_pitar.call(2475.0, 0.25)
	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree():
		return
	if _pitar.is_valid():
		_pitar.call(2525.0, 0.25)
	if respuesta.size() > 2:
		_linea("CONTROL (Earth)", respuesta[2], Color(0.55, 1.0, 0.65))
		var siguiente: String = respuesta[1]
		_mostrar_respuestas(_conversacion[siguiente].respuestas)
	else:
		_ir_a(respuesta[1])


func _terminar() -> void:
	await get_tree().create_timer(1.2).timeout
	if not is_inside_tree():
		return
	_panel.visible = false
	activa = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	termino.emit()


## Cierra el panel de golpe (por ejemplo, si el viaje termina o se salta).
func cerrar() -> void:
	if not activa:
		return
	_panel.visible = false
	activa = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _linea(quien: String, texto: String, color: Color) -> void:
	var etiqueta := RichTextLabel.new()
	etiqueta.bbcode_enabled = true
	etiqueta.fit_content = true
	etiqueta.scroll_active = false
	etiqueta.add_theme_font_size_override("normal_font_size", 20)
	etiqueta.add_theme_font_size_override("bold_font_size", 20)
	etiqueta.text = "[b][color=#%s]%s:[/color][/b] %s" % [color.to_html(false), quien, texto]
	_historial.add_child(etiqueta)
	await get_tree().process_frame
	if is_instance_valid(_desplazar):
		_desplazar.scroll_vertical = int(_desplazar.get_v_scroll_bar().max_value)


func _armar() -> void:
	_panel = PanelContainer.new()
	# A la derecha, para que se vea el monitor del centro mientras se contesta.
	_panel.anchor_left = 1.0
	_panel.anchor_right = 1.0
	_panel.anchor_top = 0.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = -560
	_panel.offset_right = -20
	_panel.offset_top = 20
	_panel.offset_bottom = -20
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.04, 0.06, 0.08, 0.94)
	estilo.border_color = Color(0.95, 0.6, 0.15)
	estilo.set_border_width_all(3)
	estilo.set_corner_radius_all(10)
	estilo.set_content_margin_all(16)
	_panel.add_theme_stylebox_override("panel", estilo)
	add_child(_panel)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 10)
	_panel.add_child(columna)
	var titulo := Label.new()
	titulo.text = "📡 COMMUNICATIONS · EARTH"
	titulo.add_theme_font_size_override("font_size", 22)
	titulo.add_theme_color_override("font_color", Color(1.0, 0.75, 0.3))
	columna.add_child(titulo)
	_desplazar = ScrollContainer.new()
	_desplazar.custom_minimum_size = Vector2(0, 220)
	_desplazar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_desplazar.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	columna.add_child(_desplazar)
	_historial = VBoxContainer.new()
	_historial.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_desplazar.add_child(_historial)
	var ayuda := Label.new()
	ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ayuda.text = "Choose with the mouse. The data is on the monitor (keys 1-4)."
	ayuda.add_theme_font_size_override("font_size", 16)
	ayuda.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
	columna.add_child(ayuda)
	_botones = VBoxContainer.new()
	_botones.add_theme_constant_override("separation", 6)
	columna.add_child(_botones)
