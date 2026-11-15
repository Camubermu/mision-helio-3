extends SubViewport
## Monitor de la cabina del cohete con 4 pantallas que el jugador cambia:
##   1 COMBUSTIBLE · 2 MOTORES · 3 DAÑOS · 4 NAVEGACIÓN
## Teclas 1-4 o clic para cambiar. Lo maneja scripts/viaje_espacial.gd.

const Datos = preload("res://scripts/datos_viaje.gd")

enum Pagina { COMBUSTIBLE, MOTORES, DANOS, NAVEGACION }
const NOMBRES := ["1 COMBUST.", "2 MOTORES", "3 DAÑOS", "4 NAVEG."]

const VERDE := Color(0.3, 1.0, 0.5)
const ROJO := Color(1.0, 0.25, 0.2)
const AMBAR := Color(1.0, 0.75, 0.2)

var pagina := Pagina.DANOS

var _fondo: ColorRect
var _pestanas: Array[ColorRect] = []
var _texto: Label
var _diagrama: Control
var _partes: Dictionary = {}
var _tiempo := 0.0


func _init() -> void:
	size = Vector2i(512, 290)
	render_target_update_mode = SubViewport.UPDATE_DISABLED


func _ready() -> void:
	_fondo = ColorRect.new()
	_fondo.size = Vector2(512, 290)
	_fondo.color = Color(0.02, 0.06, 0.16)
	add_child(_fondo)
	for i in 4:
		var pestana := ColorRect.new()
		pestana.position = Vector2(6 + i * 126, 6)
		pestana.size = Vector2(120, 30)
		add_child(pestana)
		var nombre := Label.new()
		nombre.text = NOMBRES[i]
		nombre.size = pestana.size
		nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nombre.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		nombre.add_theme_font_size_override("font_size", 17)
		pestana.add_child(nombre)
		_pestanas.append(pestana)
	_texto = Label.new()
	_texto.position = Vector2(16, 44)
	_texto.size = Vector2(480, 240)
	_texto.add_theme_font_size_override("font_size", 21)
	add_child(_texto)
	_crear_diagrama()


func cambiar(nueva: Pagina) -> void:
	pagina = nueva


func siguiente() -> void:
	pagina = ((pagina + 1) % 4) as Pagina


## Dibuja la pantalla actual. "falla" = el motor químico está dañado.
func dibujar(hacia_la_luna: bool, avance: float, tiempo: float) -> void:
	_tiempo = tiempo
	for i in 4:
		_pestanas[i].color = Color(0.2, 0.55, 0.9) if i == pagina else Color(0.08, 0.16, 0.3)
	_diagrama.visible = pagina == Pagina.DANOS
	_texto.position.x = 250 if pagina == Pagina.DANOS else 16
	_texto.size.x = 250 if pagina == Pagina.DANOS else 480
	match pagina:
		Pagina.COMBUSTIBLE:
			_texto.text = _combustible(hacia_la_luna, avance)
		Pagina.MOTORES:
			_texto.text = _motores(hacia_la_luna)
		Pagina.DANOS:
			_texto.text = _danos(hacia_la_luna)
			_pintar_diagrama()
		Pagina.NAVEGACION:
			_texto.text = _navegacion(hacia_la_luna, avance)


static func helio3(hacia_la_luna: bool, avance: float) -> int:
	# A la Luna se gasta casi todo (solo alcanza para alunizar).
	# De vuelta van los tanques llenos con las cápsulas recolectadas.
	return int(lerpf(45.0, 10.0, avance)) if hacia_la_luna else int(lerpf(100.0, 55.0, avance))


func _combustible(hacia_la_luna: bool, avance: float) -> String:
	var helio := helio3(hacia_la_luna, avance)
	var lineas := PackedStringArray([
		"Químico (despegue):   %s  0 %%  FUGA" % _barra(0),
		"Helio-3 (plasma):     %s %d %%" % [_barra(helio), helio],
		"Oxígeno cabina:       %s %d %%" % [_barra(98 - int(avance * 4)), 98 - int(avance * 4)],
		"Batería:              %s %d %%" % [_barra(100 - int(avance * 13)), 100 - int(avance * 13)],
	])
	if hacia_la_luna and helio < 25:
		lineas.append("¡El helio-3 solo alcanza para alunizar!")
	elif not hacia_la_luna:
		lineas.append("Tanques llenos con helio-3 lunar")
	return "\n".join(lineas)


func _motores(hacia_la_luna: bool) -> String:
	var lineas := PackedStringArray([
		"MOTOR QUÍMICO (llama azul)",
		"  Estado: %s" % ("FALLA - apagado" if hacia_la_luna else "DAÑADO - apagado"),
		"  Presión de bomba: 0 bar",
		"MOTOR DE PLASMA (helio-3)",
		"  Estado: ENCENDIDO",
		"  Empuje: %d %%   Temp: %d °C" % [35 + int(sin(_tiempo) * 3), 900 + int(sin(_tiempo * 0.7) * 40)],
	])
	return "\n".join(lineas)


func _danos(hacia_la_luna: bool) -> String:
	var lineas := PackedStringArray([
		"DAÑOS:",
		"Motor químico:",
		"  bomba rota",
		"Tanque químico:",
		"  fuga (abajo)",
		"Resto: OK" if hacia_la_luna else "Reparar en la base",
	])
	return "\n".join(lineas)


func _navegacion(hacia_la_luna: bool, avance: float) -> String:
	var lineas := PackedStringArray([
		"Destino: %s" % ("LUNA" if hacia_la_luna else "TIERRA (base level 1)"),
		"Distancia: %s km" % Datos.con_puntos(Datos.distancia(avance)),
		"Velocidad: %s km/h" % Datos.con_puntos(Datos.velocidad(hacia_la_luna, avance)),
		"Tiempo: %s" % Datos.reloj(avance),
		"Llegada en: %s" % Datos.falta(avance),
		"Afuera: %s" % Datos.temperatura(_tiempo),
	])
	return "\n".join(lineas)


static func _barra(porcentaje: int) -> String:
	var llenos := clampi(floori(porcentaje / 10.0), 0, 10)
	return "[" + "|".repeat(llenos) + ".".repeat(10 - llenos) + "]"


## Dibujo simple del cohete por partes para la pantalla de daños.
func _crear_diagrama() -> void:
	_diagrama = Control.new()
	_diagrama.position = Vector2(60, 50)
	add_child(_diagrama)
	var piezas := [
		["nariz", Vector2(40, 0), Vector2(40, 35)],
		["cabina", Vector2(30, 38), Vector2(60, 50)],
		["tanque_helio", Vector2(30, 91), Vector2(60, 45)],
		["tanque_quimico", Vector2(30, 139), Vector2(60, 45)],
		["motor_quimico", Vector2(20, 187), Vector2(35, 40)],
		["motor_plasma", Vector2(65, 187), Vector2(35, 40)],
	]
	for pieza in piezas:
		var rect := ColorRect.new()
		rect.position = pieza[1]
		rect.size = pieza[2]
		_diagrama.add_child(rect)
		_partes[pieza[0]] = rect


func _pintar_diagrama() -> void:
	var parpadeo := ROJO if fmod(_tiempo, 0.8) < 0.5 else Color(0.4, 0.05, 0.05)
	for nombre in _partes:
		var danada: bool = nombre == "tanque_quimico" or nombre == "motor_quimico"
		(_partes[nombre] as ColorRect).color = parpadeo if danada else VERDE.darkened(0.3)
