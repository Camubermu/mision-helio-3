extends RefCounted
## Datos que se muestran en las pantallas del cohete durante el viaje.
## Los números imitan a las misiones Apolo (unos 3 días entre la Tierra y la Luna).

const DISTANCIA_KM := 384400
const HORAS_DE_VIAJE := 72.0

const CURIOSIDADES_LUNA: PackedStringArray = [
	"The Moon is 384,400 km from Earth on average",
	"The Apollo missions took about 3 days to reach the Moon",
	"Moon gravity is 6 times weaker: you would weigh 6 times less there",
	"The solar wind has been leaving helium-3 in lunar soil for millions of years",
	"There is almost no helium-3 on Earth: the atmosphere and magnetic field block it",
	"Apollo 11 footprints are still there: there is no wind on the Moon to erase them",
	"A lunar day lasts about 29 and a half Earth days",
	"The Moon moves about 3.8 cm away from Earth every year",
]

const CURIOSIDADES_TIERRA: PackedStringArray = [
	"Helium-3 could be used in fusion reactors with almost no waste",
	"From the Moon, Earth looks almost 4 times bigger than the Moon looks from here",
	"Earth is the only known planet with liquid water on its surface",
	"On return, Apollo capsules entered the atmosphere at almost 40,000 km/h",
	"The heat shield protects the ship from over 2,000 °C when entering the atmosphere",
	"Only 12 people have walked on the Moon, all between 1969 and 1972",
	"Earth's atmosphere protects us from the Sun's radiation",
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
	return "Day %d, %02d:%02d" % [floori(minutos / 1440.0) + 1, floori(minutos / 60.0) % 24, minutos % 60]


static func falta(avance: float) -> String:
	var minutos := int((1.0 - avance) * HORAS_DE_VIAJE * 60.0)
	return "%d h %02d min" % [floori(minutos / 60.0), minutos % 60]


## Afuera hace mucho calor al sol y mucho frío a la sombra (la nave gira despacio).
static func temperatura(tiempo: float) -> String:
	var lado := sin(tiempo * 0.35)
	return "+120 °C (in sunlight)" if lado > 0.0 else "-150 °C (in shadow)"


static func curiosidad(hacia_la_luna: bool, tiempo: float) -> String:
	var lista := CURIOSIDADES_LUNA if hacia_la_luna else CURIOSIDADES_TIERRA
	return "Did you know...? " + lista[int(tiempo / 6.0) % lista.size()]


static func con_puntos(numero: int) -> String:
	var texto := str(numero)
	var resultado := ""
	while texto.length() > 3:
		resultado = "," + texto.right(3) + resultado
		texto = texto.left(texto.length() - 3)
	return texto + resultado
