extends Interactuable
## Zona simple: muestra su ayuda cuando el jugador está cerca y avisa (señal "usada")
## cuando presiona E. Sirve para conectar cualquier cosa sin escribir un script nuevo.

signal usada


func interactuar() -> void:
	usada.emit()
