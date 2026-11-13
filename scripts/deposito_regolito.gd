extends Interactuable
## Roca de regolito (suelo lunar). Con E se excava y da regolito.
## Después de varias excavaciones se acaba y desaparece.

## Regolito que da cada vez que se excava.
@export var regolito_por_excavacion := 1
## Cuántas veces se puede excavar antes de que se acabe.
@export var excavaciones := 3

@onready var _roca: Node3D = $Roca

var _restantes := 0


func _ready() -> void:
	super()
	_restantes = excavaciones
	if texto_ayuda == "Presiona E":
		texto_ayuda = "Presiona E para excavar regolito"


func interactuar() -> void:
	if _restantes <= 0:
		return
	_restantes -= 1
	Juego.agregar_regolito(regolito_por_excavacion)
	Juego.mostrar_mensaje("+%d regolito" % regolito_por_excavacion)
	if _restantes <= 0:
		desaparecer()
		return
	# La roca se achica cada vez que se excava.
	var tamano := 0.4 + 0.6 * float(_restantes) / float(excavaciones)
	_roca.scale = Vector3.ONE * tamano
	actualizar_ayuda()


func obtener_texto_ayuda() -> String:
	return "%s (%d)" % [texto_ayuda, _restantes]
