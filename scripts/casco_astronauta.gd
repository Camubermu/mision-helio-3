extends CanvasLayer
## Visor del casco de astronauta: bordes oscuros redondeados y datos del traje.
## Solo se ve cuando la cámara activa es una de "camaras_del_casco"
## (primera persona), no en las vistas desde afuera ni en el vehículo.

## Cámaras en primera persona donde se ve el casco.
@export var camaras_del_casco: Array[Camera3D] = []

var _datos: Label
var _tiempo := 0.0


func _ready() -> void:
	# Debajo del HUD (que queda encima) pero encima del mundo 3D.
	layer = -1
	var borde := TextureRect.new()
	borde.set_anchors_preset(Control.PRESET_FULL_RECT)
	borde.mouse_filter = Control.MOUSE_FILTER_IGNORE
	borde.stretch_mode = TextureRect.STRETCH_SCALE
	var degradado := Gradient.new()
	# Solo un borde fino y suave del visor; el centro queda limpio.
	degradado.offsets = PackedFloat32Array([0.0, 0.8, 0.95, 1.0])
	degradado.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0.05, 0.08, 0.12, 0.22), Color(0.03, 0.05, 0.08, 0.45)])
	var textura := GradientTexture2D.new()
	textura.gradient = degradado
	textura.fill = GradientTexture2D.FILL_RADIAL
	textura.fill_from = Vector2(0.5, 0.5)
	textura.fill_to = Vector2(1.05, 0.5)
	textura.width = 256
	textura.height = 256
	borde.texture = textura
	add_child(borde)

	_datos = Label.new()
	_datos.anchor_left = 1.0
	_datos.anchor_right = 1.0
	_datos.offset_left = -330
	_datos.offset_right = -30
	_datos.offset_top = 150
	_datos.offset_bottom = 230
	_datos.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_datos.add_theme_font_size_override("font_size", 18)
	_datos.add_theme_color_override("font_color", Color(0.55, 0.95, 1.0, 0.85))
	add_child(_datos)


func _process(delta: float) -> void:
	_tiempo += delta
	var camara := get_viewport().get_camera_3d()
	visible = camara != null and camaras_del_casco.has(camara)
	if visible:
		var oxigeno := int(ceil(Juego.get_meta("oxigeno", 98.0)))
		_datos.text = "SUIT: OK   PRESSURE: 4.3 psi\nOXYGEN: %d %%   RADIO: CHANNEL 1\nPULSE: %d bpm" % [oxigeno, 82 + int(sin(_tiempo * 0.3) * 6)]
