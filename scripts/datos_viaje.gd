extends RefCounted
## Datos que se muestran en las pantallas del cohete durante el viaje.
## Los números imitan a las misiones Apolo (unos 3 días entre la Tierra y la Luna).

const DISTANCIA_KM := 384400
const HORAS_DE_VIAJE := 72.0

const CURIOSIDADES_LUNA: PackedStringArray = [
	"La Luna está a 384.400 km de la Tierra en promedio",
	"Las misiones Apolo tardaron unos 3 días en llegar a la Luna",
	"La gravedad de la Luna es 6 veces menor: allá pesarías 6 veces menos",
	"El viento solar deja helio-3 en el suelo lunar desde hace millones de años",
	"En la Tierra casi no hay helio-3: la atmósfera y el campo magnético lo frenan",
	"Las huellas del Apolo 11 siguen ahí: en la Luna no hay viento que las borre",
	"Un día lunar dura unos 29 días y medio de la Tierra",
	"La Luna se aleja de la Tierra unos 3,8 cm cada año",
]

const CURIOSIDADES_TIERRA: PackedStringArray = [
	"El helio-3 podría usarse en reactores de fusión sin dejar casi residuos",
	"Desde la Luna, la Tierra se ve casi 4 veces más grande que la Luna desde aquí",
	"La Tierra es el único planeta conocido con agua líquida en su superficie",
	"Al volver, las cápsulas Apolo entraban a la atmósfera a casi 40.000 km/h",
	"El escudo térmico protege la nave de más de 2.000 °C al entrar a la atmósfera",
	"Solo 12 personas han caminado sobre la Luna, todas entre 1969 y 1972",
	"La atmósfera de la Tierra nos protege de la radiación del Sol",
]


## Velocidad en km/h. Al salir va muy rápido, se frena a mitad de camino
## (la gravedad de la Tierra lo jala hacia atrás) y acelera al llegar.
static func velocidad(hacia_la_luna: bool, avance: float) -> int:
	var t := avance if hacia_la_luna else 1.0 - avance
	var km_h: float
	if t < 0.85:
		km_h = lerpf(39000.0, 3700.0, ease(t / 0.85, 0.35))
	else:
		km_h = lerpf(3700.0, 8500.0, (t - 0.85) / 0.15)
	return int(km_h)


static func distancia(avance: float) -> int:
	return int(DISTANCIA_KM * (1.0 - avance))


## "Día 2, 07:30" según cuánto lleva del viaje de 3 días.
static func reloj(avance: float) -> String:
	var minutos := int(avance * HORAS_DE_VIAJE * 60.0)
	return "Día %d, %02d:%02d" % [floori(minutos / 1440.0) + 1, floori(minutos / 60.0) % 24, minutos % 60]


static func falta(avance: float) -> String:
	var minutos := int((1.0 - avance) * HORAS_DE_VIAJE * 60.0)
	return "%d h %02d min" % [floori(minutos / 60.0), minutos % 60]


## Afuera hace mucho calor al sol y mucho frío a la sombra (la nave gira despacio).
static func temperatura(tiempo: float) -> String:
	var lado := sin(tiempo * 0.35)
	return "+120 °C (al sol)" if lado > 0.0 else "-150 °C (a la sombra)"


static func curiosidad(hacia_la_luna: bool, tiempo: float) -> String:
	var lista := CURIOSIDADES_LUNA if hacia_la_luna else CURIOSIDADES_TIERRA
	return "¿Sabías que...? " + lista[int(tiempo / 6.0) % lista.size()]


static func con_puntos(numero: int) -> String:
	var texto := str(numero)
	var resultado := ""
	while texto.length() > 3:
		resultado = "." + texto.right(3) + resultado
		texto = texto.left(texto.length() - 3)
	return texto + resultado
