extends Node3D
## Estación lunar Kodland (lunar_station_kodland.tscn) convertida en planta de helio-3.
## Va en la raíz de la estación. Al empezar:
##   - les pone choque a las paredes, pisos y vidrios (el modelo no trae),
##   - prende luces dentro de las salas,
##   - pone una consola por etapa del proceso en su sala:
##       3 Laboratorio · 4 Sala del horno · 5 Captura de gases · 6 Laboratorio criogénico · 7 Almacén
##   - pone la recarga de oxígeno en la esclusa (la entrada),
##   - marca la salida de las cápsulas frente a la rampa de la esclusa.
## Todo se crea desde aquí para que el editor no lo borre al guardar la escena.

const Consola = preload("res://scripts/consola_planta.gd")

## La planta (scripts/planta_helio.gd).
@export var planta: Node
## El reactor de afuera (brilla mientras se calienta el regolito).
@export var reactor: Node3D
## Altura del piso de la estación sobre el suelo.
@export var piso := 0.3

## Salas: nombre, centro (metros del modelo) y si llevan luz.
const SALAS := {
	"LABORATORY": Vector3(-15, 0, 0),
	"CRYOGENIC LAB": Vector3(-32, 0, 0),
	"GAS CAPTURE": Vector3(-17, 0, -15),
	"GREENHOUSE": Vector3(0, 0, -15),
	"COMMUNICATIONS": Vector3(16, 0, -15),
	"CREW QUARTERS": Vector3(15, 0, 0),
	"LIVING MODULE": Vector3(32, 0, 0),
	"STORAGE": Vector3(-9.5, 0, 10),
	"FURNACE ROOM": Vector3(9.5, 0, 10),
	"AIRLOCK": Vector3(0, 0, 13),
	"CORE": Vector3(0, 0, 0),
}
## Consolas de cada etapa: [lugar, hacia dónde mira el frente].
const CONSOLAS := {
	3: [Vector3(-11.5, 0, 2.4), Vector3(0, 0, -1)],
	4: [Vector3(6.4, 0, 10.4), Vector3(0, 0, -1)],
	5: [Vector3(-16.5, 0, -11.3), Vector3(0, 0, -1)],
	6: [Vector3(-28.5, 0, 2.4), Vector3(0, 0, -1)],
	7: [Vector3(-5.6, 0, 6.3), Vector3(0, 0, 1)],
}
## Recarga de oxígeno en la esclusa: [lugar, hacia dónde mira].
const OXIGENO := [Vector3(2.4, 0, 12.0), Vector3(-1, 0, 0)]
## Salida de las cápsulas: frente a la rampa de la esclusa.
const SALIDA_CAPSULAS := Vector3(0, 0, 20.5)
## Piezas del modelo que son sólidas.
## (Muebles, camas, máquinas e invernadero también: no se pueden atravesar.)
const PIEZAS_SOLIDAS := ["hull", "found", "floor", "glass", "prop", "fabG", "fabB", "fabP", "bed", "soil", "plant", "orange"]

## Punto de recarga de oxígeno (lo usa el oxígeno del traje si el astronauta se queda sin aire).
var punto_oxigeno: Node3D


func _ready() -> void:
	add_to_group("estacion_lunar")
	_poner_choques()
	_poner_luces()
	_poner_consolas.call_deferred()


## Caja de la estación en el mundo (para saber si el astronauta está adentro).
func caja_mundo() -> AABB:
	return AABB(to_global(Vector3(-38.5, -1, -20.5)), Vector3(77, 6, 37) * global_basis.get_scale())


func _poner_choques() -> void:
	for malla in find_children("*", "MeshInstance3D", true, false):
		var m := malla as MeshInstance3D
		if not String(m.name) in PIEZAS_SOLIDAS:
			continue
		var cuerpo := StaticBody3D.new()
		var forma := CollisionShape3D.new()
		forma.shape = m.mesh.create_trimesh_shape()
		cuerpo.add_child(forma)
		m.add_child(cuerpo)


func _poner_luces() -> void:
	for nombre in SALAS:
		var luz := OmniLight3D.new()
		luz.light_color = Color(0.95, 0.97, 1.0)
		luz.light_energy = 1.3
		luz.omni_range = 11.0
		luz.position = SALAS[nombre] + Vector3(0, 2.9, 0)
		add_child(luz)


func _poner_consolas() -> void:
	var escena := get_parent()
	for numero in CONSOLAS:
		var consola := Area3D.new()
		consola.set_script(Consola)
		consola.name = "ConsolaEtapa%d" % numero
		consola.set("etapa", numero)
		consola.set("planta", planta)
		escena.add_child(consola)
		_colocar(consola, CONSOLAS[numero][0], CONSOLAS[numero][1])
	punto_oxigeno = _crear_recarga_oxigeno(escena)
	if planta:
		var salida := Marker3D.new()
		salida.name = "SalidaCapsulas"
		escena.add_child(salida)
		salida.global_position = to_global(SALIDA_CAPSULAS)
		salida.global_rotation.y = global_rotation.y
		planta.salida_capsulas = salida
	_letreros()


## Pone algo en el piso de la estación, con su frente (+Z) mirando hacia "frente".
func _colocar(nodo: Node3D, lugar: Vector3, frente: Vector3) -> void:
	nodo.global_position = to_global(lugar + Vector3(0, piso, 0))
	var mundo := global_basis * frente
	nodo.global_rotation = Vector3(0, atan2(mundo.x, mundo.z), 0)


## Estación de recarga: un tanque verde y un botón grande. E para recargar.
func _crear_recarga_oxigeno(escena: Node) -> Node3D:
	var base := Node3D.new()
	base.name = "RecargaOxigeno"
	escena.add_child(base)
	_colocar(base, OXIGENO[0], OXIGENO[1])
	var tanque := MeshInstance3D.new()
	var cilindro := CylinderMesh.new()
	cilindro.top_radius = 0.25
	cilindro.bottom_radius = 0.25
	cilindro.height = 1.5
	tanque.mesh = cilindro
	tanque.material_override = _material(Color(0.15, 0.6, 0.3), 0.4)
	tanque.position = Vector3(-0.35, 0.75, -0.1)
	base.add_child(tanque)
	var caja := MeshInstance3D.new()
	var malla := BoxMesh.new()
	malla.size = Vector3(0.5, 1.1, 0.35)
	caja.mesh = malla
	caja.material_override = _material(Color(0.85, 0.87, 0.9), 0.3)
	caja.position = Vector3(0.25, 0.55, -0.05)
	base.add_child(caja)
	var boton := MeshInstance3D.new()
	var disco := CylinderMesh.new()
	disco.top_radius = 0.09
	disco.bottom_radius = 0.1
	disco.height = 0.06
	boton.mesh = disco
	var rojo := _material(Color(0.1, 0.8, 1.0), 0.2)
	rojo.emission_enabled = true
	rojo.emission = Color(0.1, 0.7, 1.0)
	boton.material_override = rojo
	boton.rotation_degrees.x = 90
	boton.position = Vector3(0.25, 0.9, 0.14)
	base.add_child(boton)
	var letrero := Label3D.new()
	letrero.text = "OXYGEN\nREFILL"
	letrero.font_size = 40
	letrero.pixel_size = 0.0025
	letrero.modulate = Color(0.5, 0.95, 1.0)
	letrero.outline_size = 8
	letrero.position = Vector3(0, 1.75, 0)
	base.add_child(letrero)
	var zona := Area3D.new()
	zona.name = "ZonaRecarga"
	zona.set_script(load("res://scripts/zona_e.gd"))
	zona.set("texto_ayuda", "Press E to refill your suit oxygen")
	var forma := CollisionShape3D.new()
	var figura := BoxShape3D.new()
	figura.size = Vector3(2.2, 2.5, 2.4)
	forma.shape = figura
	forma.position = Vector3(0, 1.25, 1.1)
	zona.add_child(forma)
	base.add_child(zona)
	return base


## Nombre de cada sala, grande, en lo alto.
func _letreros() -> void:
	for nombre in SALAS:
		if nombre == "CORE":
			continue
		var letrero := Label3D.new()
		letrero.text = nombre
		letrero.font_size = 64
		letrero.pixel_size = 0.006
		letrero.modulate = Color(0.85, 0.95, 1.0)
		letrero.outline_size = 10
		letrero.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		letrero.position = SALAS[nombre] + Vector3(0, 2.75, 0)
		add_child(letrero)


static func _material(color: Color, metal: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metal
	material.roughness = 0.4
	return material
