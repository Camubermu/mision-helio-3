extends Node3D
## Siembra rocas por la superficie lunar (sobre el terreno de Emil).
## La mayoría tienen regolito con helio-3 (rocas del demo). Algunas son rocas sin helio-3
## (las de Sele, scenes/objetos/RocasSinHelio3): al excavarlas el vehículo las analiza y
## avisa que no sirven, así que hay que buscar más rocas y la misión dura más.
## Lo crea scripts/mision_cami.gd al empezar.

## Cuántas rocas en total.
@export var cantidad := 50
## Cuántas de ellas no tienen helio-3.
@export var sin_helio := 16
## Zona donde se siembran (en el mundo): esquina y tamaño.
@export var zona := Rect2(200, 120, 280, 300)
## Distancia mínima entre rocas.
@export var separacion := 7.0
## Lugares donde no se ponen rocas: [centro, radio].
var lugares_libres: Array = []
## El terreno (Terrain3D) para saber la altura del suelo.
var terreno: Node

const CON_HELIO := ["res://demo/assets/models/RockA.tscn", "res://demo/assets/models/RockB.tscn", "res://demo/assets/models/RockC.glb"]
const SIN_HELIO := "res://scenes/objetos/RocasSinHelio3/rocas_sin_helio_3.tscn"


func _ready() -> void:
	var azar := RandomNumberGenerator.new()
	azar.seed = 2026
	var puestas: Array[Vector3] = []
	var intentos := 0
	while puestas.size() < cantidad and intentos < cantidad * 60:
		intentos += 1
		var lugar := Vector3(zona.position.x + azar.randf() * zona.size.x, 0, zona.position.y + azar.randf() * zona.size.y)
		if not _sirve(lugar, puestas):
			continue
		lugar.y = _altura(lugar)
		puestas.append(lugar)
	# Las primeras de la lista son las que no tienen helio-3 (quedan repartidas al azar).
	for i in puestas.size():
		_poner_roca(puestas[i], i < sin_helio, azar)


func _sirve(lugar: Vector3, puestas: Array[Vector3]) -> bool:
	for libre in lugares_libres:
		var centro: Vector3 = libre[0]
		if Vector2(lugar.x - centro.x, lugar.z - centro.z).length() < float(libre[1]):
			return false
	for otra in puestas:
		if Vector2(lugar.x - otra.x, lugar.z - otra.z).length() < separacion:
			return false
	# Solo en suelo casi plano, para que el vehículo pueda llegar.
	var bajo := INF
	var alto := -INF
	for dx in [-3.0, 0.0, 3.0]:
		for dz in [-3.0, 0.0, 3.0]:
			var h := _altura(lugar + Vector3(dx, 0, dz))
			bajo = minf(bajo, h)
			alto = maxf(alto, h)
	return alto - bajo < 0.6


func _altura(lugar: Vector3) -> float:
	if terreno == null or terreno.get("data") == null:
		return 0.0
	var h: float = terreno.data.get_height(lugar)
	return 0.0 if is_nan(h) else h


func _poner_roca(lugar: Vector3, vacia: bool, azar: RandomNumberGenerator) -> void:
	var roca := Node3D.new()
	roca.name = "RocaSinHelio" if vacia else "Roca"
	add_child(roca)
	var modelo: Node3D
	if vacia:
		# La escena de Sele trae 4 rocas juntas: se usa una sola, centrada.
		var todas: Node3D = load(SIN_HELIO).instantiate()
		var piezas := todas.find_children("*", "MeshInstance3D", true, false)
		var elegida := piezas[azar.randi() % piezas.size()] as MeshInstance3D
		elegida.get_parent().remove_child(elegida)
		todas.free()
		modelo = elegida
		var centro := elegida.get_aabb().get_center()
		elegida.transform = Transform3D.IDENTITY
		elegida.position = -Vector3(centro.x, elegida.get_aabb().position.y, centro.z)
		var envoltorio := Node3D.new()
		envoltorio.add_child(elegida)
		modelo = envoltorio
	else:
		modelo = load(CON_HELIO[azar.randi() % CON_HELIO.size()]).instantiate()
	roca.add_child(modelo)
	roca.position = lugar
	roca.rotation.y = azar.randf() * TAU
	# Todas más o menos del mismo tamaño (unos 2 m de ancho).
	var caja := _caja(modelo)
	var ancho := maxf(caja.size.x, caja.size.z)
	if ancho > 0.01:
		modelo.scale = Vector3.ONE * (azar.randf_range(1.8, 2.6) / ancho)
	caja = _caja(modelo)
	modelo.position.y -= caja.position.y
	# Choque para que el vehículo no la atraviese.
	var cuerpo := StaticBody3D.new()
	var forma := CollisionShape3D.new()
	var figura := BoxShape3D.new()
	figura.size = caja.size * 0.85
	forma.shape = figura
	forma.position = Vector3(caja.get_center().x, caja.size.y / 2.0, caja.get_center().z)
	cuerpo.add_child(forma)
	roca.add_child(cuerpo)
	roca.add_to_group("roca_minable")
	if vacia:
		roca.set_meta("sin_helio", true)


## Caja del modelo medida desde la roca.
static func _caja(modelo: Node3D) -> AABB:
	var caja := AABB()
	var primera := true
	for malla in modelo.find_children("*", "MeshInstance3D", true, false) + ([modelo] if modelo is MeshInstance3D else []):
		var m := malla as MeshInstance3D
		var hasta := Transform3D.IDENTITY
		var nodo: Node3D = m
		while nodo != null and nodo != modelo.get_parent():
			hasta = nodo.transform * hasta
			nodo = nodo.get_parent() as Node3D
		var a: AABB = hasta * m.get_aabb()
		caja = a if primera else caja.merge(a)
		primera = false
	return caja
