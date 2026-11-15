extends Node3D
## Estación lunar convertida en planta de helio-3.
## Va en la raíz de la estación (scenes/objetos/EstacionLunar/estacion_lunar.tscn).
## Al empezar:
##   - les pone choque a los módulos y pasillos (el modelo no trae),
##   - pone una consola por etapa frente a su módulo:
##       3 Laboratorio · 4 Reactor · 5 Depósitos de gas · 6 Núcleo · 7 Esclusa,
##   - marca la salida de las cápsulas frente a la esclusa.
## Todo se crea desde aquí para que el editor no lo borre al guardar la escena.

const Consola = preload("res://scripts/consola_planta.gd")

## La planta (scripts/planta_helio.gd).
@export var planta: Node
## El reactor (zona scripts/procesador_helio.gd): ahí va la consola del calentamiento.
@export var reactor: Node3D

## Dónde va cada consola, en metros del modelo sin escalar (frente = +Z).
const CONSOLAS := {
	3: Vector3(5.1, 0, 2.9),     # Laboratorio
	5: Vector3(-7.6, 0, 2.2),    # Depósitos de gas, junto al hábitat
	6: Vector3(2.5, 0, 2.5),     # Núcleo (esquina entre pasillos)
	7: Vector3(1.9, 0, 7.6),     # Esclusa, al lado de la rampa
}
## Salida de las cápsulas: frente a la rampa de la esclusa.
const SALIDA_CAPSULAS := Vector3(0, 0, 9.2)
## Piezas sólidas (comienzo del nombre).
const PIEZAS_SOLIDAS := ["Pasillo presurizado", "Núcleo · casco", "Hábitat · casco", "Laboratorio · casco",
	"Esclusa · casco", "Invernadero · casco", "Depósito exterior"]


func _ready() -> void:
	_poner_choques()
	_poner_consolas.call_deferred()


func _poner_choques() -> void:
	for malla in find_children("*", "MeshInstance3D", true, false):
		var m := malla as MeshInstance3D
		var es_solida := false
		for inicio in PIEZAS_SOLIDAS:
			if String(m.name).begins_with(inicio):
				es_solida = true
				break
		if not es_solida:
			continue
		# Caja de la pieza medida desde la raíz de la estación.
		var caja: AABB = (global_transform.affine_inverse() * m.global_transform) * m.get_aabb()
		var cuerpo := StaticBody3D.new()
		var forma := CollisionShape3D.new()
		var figura := BoxShape3D.new()
		# Desde el suelo hasta el techo de la pieza.
		figura.size = Vector3(caja.size.x, caja.end.y, caja.size.z)
		forma.shape = figura
		forma.position = Vector3(caja.get_center().x, caja.end.y / 2.0, caja.get_center().z)
		cuerpo.add_child(forma)
		add_child(cuerpo)


func _poner_consolas() -> void:
	var escena := get_parent()
	for numero in CONSOLAS:
		_crear_consola(escena, numero, to_global(CONSOLAS[numero]), global_rotation.y)
	if reactor:
		# Consola del horno, al costado del reactor.
		_crear_consola(escena, 4, reactor.global_position + Vector3(8.5, 0, 3.0), 0.0)
	if planta:
		var salida := Marker3D.new()
		salida.name = "SalidaCapsulas"
		escena.add_child(salida)
		salida.global_position = to_global(SALIDA_CAPSULAS)
		salida.global_rotation.y = global_rotation.y
		planta.salida_capsulas = salida


func _crear_consola(escena: Node, numero: int, lugar: Vector3, giro: float) -> void:
	var consola := Area3D.new()
	consola.set_script(Consola)
	consola.name = "ConsolaEtapa%d" % numero
	consola.set("etapa", numero)
	consola.set("planta", planta)
	escena.add_child(consola)
	consola.global_position = Vector3(lugar.x, global_position.y, lugar.z)
	consola.global_rotation.y = giro
