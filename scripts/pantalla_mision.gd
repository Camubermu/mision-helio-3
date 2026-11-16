extends Node3D
## Pantalla de la base con la explicación de la misión, el plan y el resultado.
## Muestra una página a la vez y cambia sola cada "segundos_por_pagina"
## (siguiente_pagina() la cambia antes, por ejemplo con E):
##   1. ¿Por qué esta misión?  2. Plan de la misión  3. Resultado (al volver de la Luna;
##   lo guarda scripts/mision_cami.gd en Juego.set_meta("resultado_mision", {...})).
## El frente de la pantalla mira hacia +Z del nodo.

## Ancho y alto de la imagen de la pantalla (metros).
@export var tamano := Vector2(3.4, 1.85)

const AZUL := Color(0.45, 0.85, 1.0)
const VERDE := Color(0.45, 1.0, 0.55)
const AMARILLO := Color(1.0, 0.85, 0.35)

## Segundos que se queda cada página.
@export var segundos_por_pagina := 25.0

var _vista: SubViewport
var _texto: RichTextLabel
var _pie: Label
var _pagina := 0
var _tiempo := 0.0


func _ready() -> void:
	_armar_pantalla()
	# Al volver de la Luna empieza mostrando el resultado.
	_pagina = 2 if Juego.has_meta("resultado_mision") else 0
	actualizar()


func _process(delta: float) -> void:
	_tiempo += delta
	if _tiempo >= segundos_por_pagina:
		siguiente_pagina()


func _paginas() -> Array:
	var lista := [_texto_por_que(), _texto_plan()]
	if Juego.has_meta("resultado_mision"):
		lista.append(_texto_resultado())
	return lista


func siguiente_pagina() -> void:
	_pagina += 1
	actualizar()


## Vuelve a escribir la pantalla (por si cambió el resultado de la misión).
func actualizar() -> void:
	_tiempo = 0.0
	var lista := _paginas()
	_pagina = _pagina % lista.size()
	_texto.text = lista[_pagina]
	_ajustar_letra()
	var puntos := ""
	for i in lista.size():
		puntos += "●  " if i == _pagina else "○  "
	_pie.text = "%sPágina %d de %d  ·  cambia sola (E junto a la pantalla: siguiente)" % [puntos, _pagina + 1, lista.size()]
	_vista.render_target_update_mode = SubViewport.UPDATE_ONCE


## Achica la letra hasta que la página entra completa en la pantalla.
func _ajustar_letra() -> void:
	var tamano := 43
	while tamano > 22:
		_texto.add_theme_font_size_override("normal_font_size", tamano)
		_texto.add_theme_font_size_override("bold_font_size", tamano)
		if _texto.get_content_height() <= _texto.size.y:
			return
		tamano -= 2


func _texto_por_que() -> String:
	return "\n".join([
		"[color=#73d9ff][font_size=58][b]¿POR QUÉ ESTA MISIÓN?[/b][/font_size][/color]",
		"",
		"La humanidad usa cada día [b]más energía eléctrica[/b]: hogares, escuelas, hospitales, fábricas, computadoras y autos eléctricos.",
		"",
		"Hoy gran parte sale de quemar carbón, petróleo y gas, que contaminan el aire y calientan el planeta. Las centrales nucleares actuales no echan humo, pero dejan [b]desechos radiactivos[/b] que son peligrosos por miles de años.",
		"",
		"Por eso los científicos investigan [color=#73ff8c][b]fuentes de energía alternativas, limpias y sin desechos radiactivos[/b][/color].",
		"",
		"Una de las más prometedoras es la [b]fusión con helio-3[/b]: libera muchísima energía y casi no deja residuos radiactivos. El problema: en la Tierra casi no hay helio-3. En la Luna, el viento del Sol lo fue dejando en el suelo durante miles de millones de años.",
		"",
		"[color=#ffd95a][b]TU MISIÓN:[/b] viajar a la Luna, producir helio-3 y traer una muestra para que los científicos lo investiguen.[/color]",
	])


func _texto_plan() -> String:
	return "\n".join([
		"[color=#73d9ff][font_size=58][b]PLAN DE LA MISIÓN HELIO-3[/b][/font_size][/color]",
		"",
		"[b]1.[/b] Despegue desde esta base con el motor químico. Si falla, el motor de plasma de helio-3 toma el control.",
		"",
		"[b]2.[/b] Viaje de 3 días hasta la Luna (384.400 km). En la cabina revisa combustible, motores y daños.",
		"",
		"[b]3.[/b] Alunizaje en la plataforma. Baja por la escalera de la torre.",
		"",
		"[b]4.[/b] Con el vehículo extractor excava regolito y déjalo en la tolva del reactor.",
		"",
		"[b]5.[/b] En la estación lunar sigue las etapas en sus salas: clasificar (Laboratorio), calentar a 700-1.000 °C (Sala del horno), capturar los gases, separar el helio-3 (Laboratorio criogénico) y envasarlo (Almacén). El oxígeno se recarga en la Esclusa.",
		"",
		"[b]6.[/b] Carga entre 15 y 20 cápsulas en la nave (ella te dirá cuántas), sube por la escalera y regresa a esta base. ¡Vigila el oxígeno del traje!",
	])


func _texto_resultado() -> String:
	if not Juego.has_meta("resultado_mision"):
		return "\n".join([
			"[color=#73d9ff][font_size=58][b]RESULTADO DE LA MISIÓN[/b][/font_size][/color]",
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
		"[color=#73d9ff][font_size=58][b]RESULTADO DE LA MISIÓN[/b][/font_size][/color]",
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

	_texto = RichTextLabel.new()
	_texto.bbcode_enabled = true
	_texto.scroll_active = false
	_texto.position = Vector2(60, 44)
	_texto.size = Vector2(resolucion.x - 120, resolucion.y - 130)
	_texto.add_theme_font_size_override("normal_font_size", 43)
	_texto.add_theme_font_size_override("bold_font_size", 43)
	_texto.add_theme_color_override("default_color", Color(0.9, 0.94, 1.0))
	_vista.add_child(_texto)
	_pie = Label.new()
	_pie.position = Vector2(60, resolucion.y - 70)
	_pie.add_theme_font_size_override("font_size", 30)
	_pie.add_theme_color_override("font_color", Color(0.55, 0.7, 0.85))
	_vista.add_child(_pie)

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
