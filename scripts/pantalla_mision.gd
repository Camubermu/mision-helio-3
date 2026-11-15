extends Node3D
## Pantalla de la base con el plan de la misión y su resultado.
## Antes de la misión muestra el plan y la importancia del helio-3.
## Al volver de la Luna muestra también el resultado (lo guarda scripts/mision_cami.gd
## en Juego.set_meta("resultado_mision", {...})).
## El frente de la pantalla mira hacia +Z del nodo.

## Ancho y alto de la imagen de la pantalla (metros).
@export var tamano := Vector2(3.4, 1.85)

const AZUL := Color(0.45, 0.85, 1.0)
const VERDE := Color(0.45, 1.0, 0.55)
const AMARILLO := Color(1.0, 0.85, 0.35)

var _vista: SubViewport
var _plan: RichTextLabel
var _resultado: RichTextLabel


func _ready() -> void:
	_armar_pantalla()
	actualizar()


## Vuelve a escribir la pantalla (por si cambió el resultado de la misión).
func actualizar() -> void:
	_plan.text = _texto_plan()
	_resultado.text = _texto_resultado()
	_vista.render_target_update_mode = SubViewport.UPDATE_ONCE


func _texto_plan() -> String:
	return "\n".join([
		"[color=#73d9ff][b]PLAN DE LA MISIÓN HELIO-3[/b][/color]",
		"",
		"[b]1.[/b] Despegue desde esta base con el motor químico. Si falla, el motor de plasma de helio-3 toma el control.",
		"[b]2.[/b] Viaje de 3 días hasta la Luna (384.400 km). En la cabina revisa combustible, motores y daños.",
		"[b]3.[/b] Alunizaje sobre la plataforma de lanzamiento.",
		"[b]4.[/b] Maneja el vehículo extractor, excava regolito (el polvo lunar) y llévalo al reactor.",
		"[b]5.[/b] El reactor separa el helio-3: recoge las cápsulas y carga 3 en la nave.",
		"[b]6.[/b] Sube a la nave con E, despega de la Luna y regresa a esta base con la muestra.",
		"",
		"[color=#ffd95a][b]¿Por qué traer helio-3?[/b][/color]",
		"• El viento del Sol deja helio-3 en el suelo de la Luna desde hace miles de millones de años. En la Tierra casi no hay.",
		"• Podría ser combustible para reactores de fusión: mucha energía y muy pocos residuos radiactivos.",
		"• Con una muestra real, los científicos pueden estudiarlo en el laboratorio.",
	])


func _texto_resultado() -> String:
	if not Juego.has_meta("resultado_mision"):
		return "\n".join([
			"[color=#73d9ff][b]RESULTADO DE LA MISIÓN[/b][/color]",
			"",
			"[color=#ffd95a]Misión en preparación.[/color]",
			"",
			"Todavía no hay resultados.",
			"Completa la misión y regresa a esta base: aquí verás lo que lograste.",
		])
	var datos: Dictionary = Juego.get_meta("resultado_mision")
	var capsulas: int = datos.get("capsulas", 0)
	var necesarias: int = datos.get("necesarias", 3)
	var tanque: int = datos.get("tanque_helio", 0)
	var extra: int = datos.get("capsulas_extra", 0)
	var minutos: int = datos.get("minutos", 0)
	var lineas := [
		"[color=#73d9ff][b]RESULTADO DE LA MISIÓN[/b][/color]",
		"",
		"[color=#73ff8c][font_size=44][b]¡MISIÓN CUMPLIDA![/b][/font_size][/color]",
		"",
		"Cápsulas de helio-3 traídas: [b]%d de %d[/b]" % [capsulas, necesarias],
		"Helio-3 que quedó en el tanque del motor: [b]%d %%[/b]" % tanque,
	]
	if extra > 0:
		lineas.append("Cápsulas extra recogidas por el astronauta: [b]%d[/b]" % extra)
	if minutos > 0:
		lineas.append("Duración de la misión: [b]%d min[/b]" % minutos)
	lineas.append_array([
		"",
		"El motor de plasma de helio-3 funcionó: despegó de la Luna y aterrizó en la base.",
		"",
		"[color=#ffd95a][b]El combustible de helio-3 sobrante se usará en investigaciones energéticas[/b][/color] para desarrollar energía limpia de fusión.",
	])
	return "\n".join(lineas)


# --- Armado ------------------------------------------------------------------

func _armar_pantalla() -> void:
	var resolucion := Vector2i(int(tamano.x * 560.0), int(tamano.y * 560.0))
	_vista = SubViewport.new()
	_vista.size = resolucion
	_vista.transparent_bg = false
	_vista.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(_vista)

	var fondo := ColorRect.new()
	fondo.color = Color(0.02, 0.05, 0.11)
	fondo.size = resolucion
	_vista.add_child(fondo)

	var columnas := HBoxContainer.new()
	columnas.position = Vector2(40, 34)
	columnas.size = Vector2(resolucion.x - 80, resolucion.y - 68)
	columnas.add_theme_constant_override("separation", 50)
	_vista.add_child(columnas)
	_plan = _columna(columnas, 1.15)
	var linea := ColorRect.new()
	linea.color = Color(0.3, 0.6, 0.9, 0.6)
	linea.custom_minimum_size = Vector2(4, 0)
	columnas.add_child(linea)
	_resultado = _columna(columnas, 1.0)

	# Marco oscuro y la imagen de la pantalla.
	var marco := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = Vector3(tamano.x + 0.14, tamano.y + 0.14, 0.06)
	marco.mesh = caja
	var material_marco := StandardMaterial3D.new()
	material_marco.albedo_color = Color(0.08, 0.09, 0.11)
	material_marco.metallic = 0.5
	material_marco.roughness = 0.4
	marco.material_override = material_marco
	marco.position.z = -0.03
	add_child(marco)

	var imagen := MeshInstance3D.new()
	var plano := QuadMesh.new()
	plano.size = tamano
	imagen.mesh = plano
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = _vista.get_texture()
	imagen.material_override = material
	imagen.position.z = 0.002
	add_child(imagen)

	# Un brillo azul suave delante de la pantalla.
	var luz := OmniLight3D.new()
	luz.light_color = Color(0.5, 0.75, 1.0)
	luz.light_energy = 0.6
	luz.omni_range = 2.5
	luz.position.z = 0.6
	add_child(luz)


func _columna(padre: Control, peso: float) -> RichTextLabel:
	var texto := RichTextLabel.new()
	texto.bbcode_enabled = true
	texto.fit_content = false
	texto.scroll_active = false
	texto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texto.size_flags_stretch_ratio = peso
	texto.add_theme_font_size_override("normal_font_size", 31)
	texto.add_theme_font_size_override("bold_font_size", 31)
	texto.add_theme_color_override("default_color", Color(0.9, 0.94, 1.0))
	padre.add_child(texto)
	return texto
