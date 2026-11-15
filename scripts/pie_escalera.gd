extends Interactuable
## Zona al pie de la escalera de la plataforma: con E el astronauta sube a la nave.
## Solo deja subir cuando la nave ya tiene su carga de helio-3 (scripts/carga_nave.gd).
## La crea scripts/nave_en_plataforma.gd.

## La escalera (scripts/escalera_plataforma.gd).
var escalera: Node
## La zona de carga de la nave.
var carga_nave: Node

var _jugador: Node3D


func _ready() -> void:
	super._ready()
	body_entered.connect(func(cuerpo):
		if es_jugador(cuerpo):
			_jugador = cuerpo)


func obtener_texto_ayuda() -> String:
	if carga_nave and carga_nave.has_method("esta_lista") and carga_nave.esta_lista():
		return "Presiona E para subir por la escalera a la nave"
	return "Escalera de acceso a la nave"


func interactuar() -> void:
	if escalera == null or escalera.ocupada:
		return
	if carga_nave and carga_nave.has_method("esta_lista") and not carga_nave.esta_lista():
		Juego.mostrar_mensaje("Primero carga %d cápsulas de helio-3 en la nave (al pie del cohete)" % carga_nave.helio3_necesario)
		return
	Juego.ocultar_ayuda()
	jugador_cerca = false
	escalera.subir(_jugador)
