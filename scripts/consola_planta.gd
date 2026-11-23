extends Interactuable
## Consola de una etapa de la planta de helio-3 (etapas 3 a 7 del proceso real).
## Con E se abre un panel con controles: el jugador tiene que elegir bien los valores
## (como lo haría un operador de verdad) para que la etapa funcione.
## La consola se arma sola (pedestal, pantalla y zona). La planta es scripts/planta_helio.gd.

const Planta = preload("res://scripts/planta_helio.gd")

## Etapa que maneja esta consola (3 = clasificación ... 7 = almacenamiento).
@export_range(3, 7) var etapa := 3
## La planta (si no se elige, se busca en el grupo "planta_helio").
@export var planta: Node

const AZUL := Color(0.45, 0.85, 1.0)
const VERDE := Color(0.45, 1.0, 0.55)
const ROJO := Color(1.0, 0.45, 0.4)
const AMARILLO := Color(1.0, 0.85, 0.35)

var _jugador: Node3D
var _capa: CanvasLayer
var _caja: VBoxContainer
var _datos: RichTextLabel
var _estado: Label
var _barra: ProgressBar
var _boton_accion: Button
var _accion: Callable
var _actualizar: Callable
var _ocupado := false
var _luz_material: StandardMaterial3D
var _letrero: Label3D


func _ready() -> void:
	super._ready()
	if planta == null:
		planta = get_tree().get_first_node_in_group("planta_helio")
	body_entered.connect(_recordar_jugador)
	_armar_consola_3d()
	if planta:
		planta.cambio.connect(_refrescar_luz)
	_refrescar_luz()


func obtener_texto_ayuda() -> String:
	return "E: stage %d console · %s" % [etapa, Planta.NOMBRES[etapa]]


func _recordar_jugador(cuerpo: Node3D) -> void:
	if es_jugador(cuerpo):
		_jugador = cuerpo


func _unhandled_input(event: InputEvent) -> void:
	if _capa != null:
		if event.is_action_pressed("interactuar") or event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			_cerrar()
		return
	super._unhandled_input(event)


func interactuar() -> void:
	if planta == null:
		Juego.mostrar_mensaje("This console is not connected to the plant")
		return
	var motivo: String = planta.motivo_para_no_empezar(etapa)
	if not motivo.is_empty():
		Juego.mostrar_mensaje(motivo)
		return
	_abrir()


# --- Panel -------------------------------------------------------------------

func _abrir() -> void:
	if etapa == Planta.Etapa.CLASIFICAR:
		planta.preparar_lote()
	_tocar_con_la_mano()
	_capa = CanvasLayer.new()
	_capa.layer = 20
	add_child(_capa)
	var fondo := ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.45)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_capa.add_child(fondo)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(980, 0)
	panel.position = Vector2(-490, -330)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.02, 0.06, 0.13, 0.96)
	estilo.border_color = AZUL
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(12)
	estilo.set_content_margin_all(22)
	panel.add_theme_stylebox_override("panel", estilo)
	_capa.add_child(panel)
	_caja = VBoxContainer.new()
	_caja.add_theme_constant_override("separation", 10)
	panel.add_child(_caja)
	var titulo := Label.new()
	titulo.text = "STAGE %d · %s" % [etapa, String(Planta.NOMBRES[etapa]).to_upper()]
	titulo.add_theme_font_size_override("font_size", 30)
	titulo.add_theme_color_override("font_color", AZUL)
	_caja.add_child(titulo)

	match etapa:
		Planta.Etapa.CLASIFICAR: _armar_clasificar()
		Planta.Etapa.CALENTAR: _armar_calentar()
		Planta.Etapa.CAPTURAR: _armar_capturar()
		Planta.Etapa.SEPARAR: _armar_separar()
		Planta.Etapa.ALMACENAR: _armar_almacenar()

	_datos = RichTextLabel.new()
	_datos.bbcode_enabled = true
	_datos.fit_content = true
	_datos.add_theme_font_size_override("normal_font_size", 20)
	_datos.add_theme_font_size_override("bold_font_size", 20)
	_caja.add_child(_datos)
	_barra = ProgressBar.new()
	_barra.custom_minimum_size = Vector2(0, 24)
	_barra.visible = false
	_caja.add_child(_barra)
	_estado = Label.new()
	_estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_estado.add_theme_font_size_override("font_size", 21)
	_caja.add_child(_estado)
	var botones := HBoxContainer.new()
	botones.add_theme_constant_override("separation", 16)
	_caja.add_child(botones)
	if _accion.is_valid():
		_boton_accion = _boton(botones, _texto_accion, func(): _hacer_accion())
	_boton(botones, "Close (E)", _cerrar)
	if _actualizar.is_valid():
		_actualizar.call()

	if _jugador:
		_jugador.process_mode = Node.PROCESS_MODE_DISABLED
	Juego.soltar_mouse()


var _texto_accion := ""


func _cerrar() -> void:
	if _capa == null:
		return
	_capa.queue_free()
	_capa = null
	_accion = Callable()
	_actualizar = Callable()
	_ocupado = false
	if _jugador:
		_jugador.process_mode = Node.PROCESS_MODE_INHERIT
	Juego.capturar_mouse()


func _hacer_accion() -> void:
	if _ocupado or not _accion.is_valid():
		return
	_accion.call()


## Muestra un aviso abajo del panel (rojo = error, verde = bien).
func _avisar(texto: String, color := ROJO) -> void:
	_estado.text = texto
	_estado.add_theme_color_override("font_color", color)


## Barra de progreso mientras la máquina trabaja.
func _trabajar(texto: String, segundos: float) -> void:
	_ocupado = true
	_avisar(texto, AMARILLO)
	_barra.visible = true
	_barra.value = 0
	var animacion := create_tween()
	animacion.tween_property(_barra, "value", 100.0, segundos)
	await animacion.finished
	_ocupado = false


func _terminar_etapa(texto: String) -> void:
	_avisar(texto + "  (closes automatically)", VERDE)
	if _boton_accion:
		_boton_accion.disabled = true
	planta.completar(etapa)
	var espera := create_tween()
	espera.tween_interval(2.5)
	await espera.finished
	_cerrar()


# --- Etapa 3: clasificación ------------------------------------------------------

func _armar_clasificar() -> void:
	_explicar("Almost all the helium-3 left by the solar wind is in the finest regolith grains (smaller than 100 to 200 micrometers). To avoid heating tons of useless soil, the fine grains are first separated with sieves and separators.")
	var malla := _deslizador("Sieve mesh", 50, 500, 400, " µm")
	var magnetico := _interruptor("Magnetic separator (removes grains with iron)")
	var electro := _interruptor("Electrostatic separator (separates minerals by electric charge)")
	var centrifugo := _interruptor("Centrifugal separator (optional: sorts by weight)")
	var toneladas: int = planta.datos.get("toneladas", 0)
	_actualizar = func():
		var fino := clampf(1.0 - (malla.value - 50.0) / 450.0, 0.0, 1.0)
		var concentrado := toneladas * lerpf(0.6, 0.18, fino)
		var ppb := lerpf(12.0, 38.0, fino) + (4.0 if magnetico.button_pressed else 0.0) + (4.0 if electro.button_pressed else 0.0) + (2.0 if centrifugo.button_pressed else 0.0)
		_datos.text = "Regolith in batch: [b]%d t[/b]   ·   Concentrate going to the reactor: [b]%d t[/b]\nHelium-3 in the concentrate: [b]%d ppb[/b] (parts per billion)" % [toneladas, concentrado, ppb]
	malla.value_changed.connect(func(_v): _actualizar.call())
	for interruptor in [magnetico, electro, centrifugo]:
		interruptor.toggled.connect(func(_v): _actualizar.call())
	_preparar_accion("Sort", func():
		if malla.value > 150:
			_avisar("The mesh lets big grains through. Lower it to 150 µm or less.")
		elif not (magnetico.button_pressed and electro.button_pressed):
			_avisar("Turn on the magnetic and electrostatic separators.")
		else:
			await _trabajar("Sieving and separating the fine grains...", 3.0)
			_terminar_etapa("Concentrate ready! Now only the helium-3-rich part gets heated."))


# --- Etapa 4: calentamiento ------------------------------------------------------------

func _armar_calentar() -> void:
	_explicar("The concentrate goes into the furnace. Between 700 and 1,000 °C the grains release the gases they held: helium-3, helium-4, hydrogen, nitrogen and others. It is not pure helium-3 yet: it is a mixture.")
	var temperatura := _deslizador("Furnace temperature", 20, 1400, 20, " °C")
	var fuente := OptionButton.new()
	for opcion in ["Solar concentrators (mirrors that focus sunlight)", "Electricity from solar panels", "Small nuclear reactor at the base"]:
		fuente.add_item(opcion)
	fuente.add_theme_font_size_override("font_size", 19)
	_fila("Energy", fuente)
	_actualizar = func():
		var gas := clampf((temperatura.value - 300.0) / 600.0, 0.0, 1.0) * 100.0
		_datos.text = "Gas released from the concentrate: [b]%d %%[/b]" % gas
	temperatura.value_changed.connect(func(_v): _actualizar.call())
	_preparar_accion("Heat", func():
		var t := temperatura.value
		if t < 700:
			_avisar("At %d °C the grains release almost no gas. Raise it to 700-1,000 °C." % t)
		elif t > 1000:
			_avisar("Too much! Above 1,000 °C the regolith starts to melt and energy is wasted. Lower it to 700-1,000 °C.")
		else:
			planta.calentar_reactor(4.5)
			await _trabajar("Heating to %d °C with %s..." % [t, fuente.get_item_text(fuente.selected).split(" (")[0].to_lower()], 4.5)
			_terminar_etapa("Gases released. Now they must be captured before they escape into the vacuum."))


# --- Etapa 5: captura de gases ------------------------------------------------------------

func _armar_capturar() -> void:
	_explicar("The Moon has no air: if the gases get out, they are lost in the vacuum. So they are captured in a closed system and cleaned in order: filter, compress and cool.")
	var paso := [0]
	var mezclas := [
		"Dust: [b]yes[/b]   ·   Pressure: [b]0.1 bar[/b]\nHydrogen [b]64 %[/b] · Helium-4 [b]22 %[/b] · Nitrogen and others [b]14 %[/b] · Helium-3 [b]0.01 %[/b]",
		"Dust: [b]filtered[/b]   ·   Pressure: [b]0.1 bar[/b]\nHydrogen [b]64 %[/b] · Helium-4 [b]22 %[/b] · Nitrogen and others [b]14 %[/b] · Helium-3 [b]0.01 %[/b]",
		"Dust: [b]filtered[/b]   ·   Pressure: [b]50 bar[/b] (compressed)\nHydrogen [b]64 %[/b] · Helium-4 [b]22 %[/b] · Nitrogen and others [b]14 %[/b] · Helium-3 [b]0.01 %[/b]",
		"Cooled to [b]-250 °C[/b]: hydrogen and nitrogen turn liquid and separate. Helium stays a gas.\nHelium stream: Helium-4 [b]99.96 %[/b] · Helium-3 [b]0.04 %[/b]\n[color=#73ff8c]Hydrogen saved: it is used to make water and fuel at the base.[/color]",
	]
	_actualizar = func(): _datos.text = mezclas[paso[0]]
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	_caja.add_child(fila)
	var nombres := ["1. Filter dust", "2. Compress", "3. Cool"]
	var trabajos := ["Filtering lunar dust...", "Compressing the gas mixture...", "Cooling to -250 °C..."]
	for i in 3:
		_boton(fila, nombres[i], func():
			if _ocupado:
				return
			if paso[0] != i:
				_avisar("That step is not next. The order is: filter, compress and cool." if paso[0] < i else "That step is already done.")
				return
			await _trabajar(trabajos[i], 2.0)
			paso[0] += 1
			_actualizar.call()
			if paso[0] == 3:
				_terminar_etapa("Helium captured! But the helium-3 is still mixed with a lot of helium-4.")
			else:
				_avisar("Done. Continue with step %d." % (paso[0] + 1), VERDE))


# --- Etapa 6: separación isotópica --------------------------------------------------------

func _armar_separar() -> void:
	_explicar("Helium-3 and helium-4 are the same element (isotopes): no filter can separate them. But helium-3 boils at -270 °C and helium-4 at -269 °C. In a very cold cryogenic distillation, helium-3 evaporates first. Repeating the step several times gives almost pure helium-3.")
	var pureza := [0.04, 1.0, 12.0, 55.0, 92.0, 99.9]
	var paso := [0]
	_actualizar = func():
		_datos.text = "Column temperature: [b]-271 °C[/b] (2 degrees above absolute zero)\nHelium-3 purity: [b]%s %%[/b]   ·   Stages done: [b]%d of 5[/b]" % [str(pureza[paso[0]]), paso[0]]
	_preparar_accion("Run a distillation stage", func():
		await _trabajar("Distilling at -271 °C...", 1.6)
		paso[0] += 1
		_actualizar.call()
		if paso[0] >= 5:
			_terminar_etapa("Helium-3 at 99.9%! Ready to pack.")
		else:
			_avisar("Purity went up. Repeat: each stage separates a little more.", VERDE))


# --- Etapa 7: almacenamiento ------------------------------------------------------------

func _armar_almacenar() -> void:
	_explicar("Pure helium-3 is stored in capsules with pressure and temperature control so it does not escape. Then it goes to the ascent ship to return to Earth.")
	var presion := _deslizador("Filling pressure", 10, 400, 10, " bar")
	var cantidad: int = planta.lote
	_actualizar = func():
		_datos.text = "Capsules in this batch: [b]%d[/b]   ·   Pressure: [b]%d bar[/b]" % [cantidad, presion.value]
	presion.value_changed.connect(func(_v): _actualizar.call())
	_preparar_accion("Pack", func():
		if presion.value < 150:
			_avisar("With so little pressure very little helium-3 fits. Raise it to 150-300 bar.")
		elif presion.value > 300:
			_avisar("Danger! The capsules hold up to 300 bar. Lower the pressure.")
		else:
			await _trabajar("Filling the capsules at %d bar..." % presion.value, 2.5)
			_terminar_etapa("%d capsules ready! They come out through the airlock." % cantidad))


# --- Piezas del panel ------------------------------------------------------------

func _explicar(texto: String) -> void:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta.custom_minimum_size = Vector2(930, 0)
	etiqueta.add_theme_font_size_override("font_size", 19)
	etiqueta.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
	_caja.add_child(etiqueta)


func _preparar_accion(texto: String, accion: Callable) -> void:
	_texto_accion = texto
	_accion = accion


func _fila(nombre: String, control: Control) -> void:
	var fila := HBoxContainer.new()
	var etiqueta := Label.new()
	etiqueta.text = nombre
	etiqueta.custom_minimum_size = Vector2(250, 0)
	etiqueta.add_theme_font_size_override("font_size", 20)
	fila.add_child(etiqueta)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(control)
	_caja.add_child(fila)


func _deslizador(nombre: String, minimo: float, maximo: float, inicio: float, unidad: String) -> HSlider:
	var fila := HBoxContainer.new()
	var etiqueta := Label.new()
	etiqueta.custom_minimum_size = Vector2(250, 0)
	etiqueta.add_theme_font_size_override("font_size", 20)
	fila.add_child(etiqueta)
	var deslizador := HSlider.new()
	deslizador.min_value = minimo
	deslizador.max_value = maximo
	deslizador.step = 10
	deslizador.value = inicio
	deslizador.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deslizador.custom_minimum_size = Vector2(0, 30)
	fila.add_child(deslizador)
	var valor := Label.new()
	valor.custom_minimum_size = Vector2(110, 0)
	valor.add_theme_font_size_override("font_size", 22)
	valor.add_theme_color_override("font_color", AMARILLO)
	fila.add_child(valor)
	var mostrar := func(v: float): valor.text = "%d%s" % [v, unidad]
	mostrar.call(inicio)
	deslizador.value_changed.connect(mostrar)
	etiqueta.text = nombre
	_caja.add_child(fila)
	return deslizador


func _interruptor(texto: String) -> CheckButton:
	var interruptor := CheckButton.new()
	interruptor.text = texto
	interruptor.add_theme_font_size_override("font_size", 19)
	_caja.add_child(interruptor)
	return interruptor


func _boton(padre: Control, texto: String, al_presionar: Callable) -> Button:
	var boton := Button.new()
	boton.text = texto
	boton.custom_minimum_size = Vector2(200, 46)
	boton.add_theme_font_size_override("font_size", 20)
	boton.pressed.connect(al_presionar)
	padre.add_child(boton)
	return boton


## La mano del astronauta se estira hacia la pantalla al usar la consola.
func _tocar_con_la_mano() -> void:
	if _jugador == null:
		return
	var brazos := _jugador.find_child("Brazos", true, false)
	if brazos and brazos.has_method("alcanzar"):
		brazos.alcanzar(global_position + Vector3.UP * 1.3)


# --- Consola en 3D --------------------------------------------------------------

func _armar_consola_3d() -> void:
	# Zona donde aparece la ayuda (delante de la consola).
	var zona := CollisionShape3D.new()
	var caja := BoxShape3D.new()
	caja.size = Vector3(3.0, 3.0, 3.2)
	zona.shape = caja
	zona.position = Vector3(0, 1.5, 1.4)
	add_child(zona)
	# Pedestal sólido.
	var cuerpo := StaticBody3D.new()
	add_child(cuerpo)
	var choque := CollisionShape3D.new()
	var caja_pie := BoxShape3D.new()
	caja_pie.size = Vector3(1.0, 1.2, 0.6)
	choque.shape = caja_pie
	choque.position.y = 0.6
	cuerpo.add_child(choque)
	_caja_3d(Vector3(0.9, 1.1, 0.5), Vector3(0, 0.55, 0), Color(0.82, 0.84, 0.88))
	_caja_3d(Vector3(1.0, 0.06, 0.6), Vector3(0, 0.03, 0), Color(0.25, 0.27, 0.3))
	var pantalla := _caja_3d(Vector3(1.1, 0.7, 0.08), Vector3(0, 1.35, 0.05), Color(0.05, 0.12, 0.25))
	pantalla.rotation_degrees.x = -25
	(pantalla.material_override as StandardMaterial3D).emission_enabled = true
	(pantalla.material_override as StandardMaterial3D).emission = Color(0.1, 0.35, 0.7)
	_letrero = Label3D.new()
	_letrero.text = "STAGE %d\n%s" % [etapa, String(Planta.NOMBRES[etapa]).to_upper()]
	_letrero.font_size = 40
	_letrero.pixel_size = 0.0018
	_letrero.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_letrero.width = 520.0
	_letrero.modulate = AZUL
	_letrero.outline_size = 8
	_letrero.position = Vector3(0, 0, 0.05)
	pantalla.add_child(_letrero)
	var luz := _caja_3d(Vector3(0.16, 0.16, 0.16), Vector3(0.38, 1.8, 0.0), Color.GRAY)
	_luz_material = luz.material_override
	_luz_material.emission_enabled = true


func _caja_3d(tamano: Vector3, lugar: Vector3, color: Color) -> MeshInstance3D:
	var malla := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = tamano
	malla.mesh = caja
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.5
	malla.material_override = material
	malla.position = lugar
	add_child(malla)
	return malla


## Luz verde: es el turno de esta etapa. Gris: todavía no (o ya pasó).
func _refrescar_luz() -> void:
	if _luz_material == null:
		return
	var es_su_turno: bool = planta != null and planta.etapa == etapa
	var color := VERDE if es_su_turno else Color(0.3, 0.3, 0.32)
	_luz_material.albedo_color = color
	_luz_material.emission = color
	_luz_material.emission_energy_multiplier = 2.0 if es_su_turno else 0.0
