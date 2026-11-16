extends Node3D
## Excavadora del vehículo. Va como hija del vehículo (scripts/vehiculo.gd).
##
## Cuando alguien maneja y la rueda toca una roca del grupo "roca_minable", el vehículo
## tiembla, la rueda gira rápido, el material sube por la cinta y se suma regolito.
## Cada roca se achica y desaparece cuando se le acaba el regolito.
##
## Hijos: PuntoExcavacion (dónde está la rueda) y Cinta (Marker3D en orden: el camino del material).
## Para que una roca se pueda excavar: selecciónala → pestaña Nodo → Grupos → "roca_minable".

const TrozoRegolito = preload("res://scripts/trozo_regolito.gd")

## Distancia máxima entre la rueda y la roca para poder excavar (metros).
@export var alcance := 2.5
## Segundos que tarda en sacar 1 de regolito.
@export var segundos_por_carga := 1.2
## Cuánto regolito cabe en el vehículo.
@export var capacidad := 12
## Cuánto regolito tiene cada roca antes de desaparecer.
@export var regolito_por_roca := 6
## Segundos que tarda un trocito en subir por la cinta.
@export var segundos_en_cinta := 1.6

var excavando := false

var _roca: Node3D
var _tiempo_carga := 0.0
var _tiempo_trozo := 0.0
var _tiempo_busqueda := 0.0
var _avisado_lleno := false

@onready var _vehiculo: Node = get_parent()
@onready var _punto: Node3D = $PuntoExcavacion
@onready var _cinta: Array[Node] = $Cinta.get_children()


func _physics_process(delta: float) -> void:
	_tiempo_busqueda -= delta
	if _tiempo_busqueda <= 0.0:
		_tiempo_busqueda = 0.2
		_roca = _roca_cercana()

	var hay_espacio := Juego.regolito < capacidad
	var conduce: bool = _vehiculo.conduciendo
	_cambiar_excavando(conduce and _roca != null and hay_espacio)
	_avisar_si_lleno(conduce and _roca != null and not hay_espacio)

	_vehiculo.vibracion = move_toward(_vehiculo.vibracion, 1.0 if excavando else 0.0, delta * 3.0)
	if conduce:
		_vehiculo.texto_extra = "Regolito: %d/%d\n" % [Juego.regolito, capacidad]

	if not excavando:
		_tiempo_carga = 0.0
		return
	_tiempo_carga += delta
	if _tiempo_carga >= segundos_por_carga:
		_tiempo_carga -= segundos_por_carga
		_sacar_carga()
	_tiempo_trozo -= delta
	if _tiempo_trozo <= 0.0:
		_tiempo_trozo = 0.25
		_subir_trozo_por_la_cinta()


func _cambiar_excavando(valor: bool) -> void:
	if valor == excavando:
		return
	excavando = valor
	_vehiculo.ritmo_piezas = 4.0 if excavando else 1.0
	if excavando:
		_avisado_lleno = false
		Juego.mostrar_mensaje("Excavando regolito...")


func _avisar_si_lleno(lleno: bool) -> void:
	if lleno and not _avisado_lleno:
		_avisado_lleno = true
		Juego.mostrar_mensaje("¡Carga llena! Lleva el regolito al reactor")


func _sacar_carga() -> void:
	if not is_instance_valid(_roca):
		return
	if _roca.get_meta("sin_helio", false):
		_analizar_roca_sin_helio()
		return
	Juego.agregar_regolito(1)
	var restante: int = _roca.get_meta("regolito", regolito_por_roca) - 1
	_roca.set_meta("regolito", restante)
	_roca.remove_meta("_caja")
	if restante <= 0:
		_roca.remove_from_group("roca_minable")
		_roca.queue_free()
		_roca = null
		Juego.mostrar_mensaje("Roca agotada. Busca otra")
	else:
		# La roca se achica con cada carga.
		_roca.scale *= 0.9


## Algunas rocas son basalto macizo: el viento solar solo deja helio-3 en el polvo fino
## (regolito) de la superficie, no adentro de las rocas duras. El vehículo lo descubre al excavar.
func _analizar_roca_sin_helio() -> void:
	var pasadas: int = _roca.get_meta("analisis", 0) + 1
	_roca.set_meta("analisis", pasadas)
	if pasadas == 1:
		Juego.mostrar_mensaje("Analizando la roca...")
		return
	_roca.remove_from_group("roca_minable")
	_roca.set_meta("analizada", true)
	# Se oscurece un poco para que se note que ya no sirve.
	for malla in _roca.find_children("*", "MeshInstance3D", true, false):
		(malla as MeshInstance3D).transparency = 0.0
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.25, 0.24, 0.24)
		(malla as MeshInstance3D).material_overlay = material
	_roca = null
	Juego.mostrar_mensaje("Análisis: esta roca es basalto duro, SIN helio-3. El helio-3 está en el regolito fino. Busca otra roca")


func _roca_cercana() -> Node3D:
	var mejor: Node3D = null
	var mejor_distancia := alcance
	for roca in get_tree().get_nodes_in_group("roca_minable"):
		if not (roca is Node3D) or roca.is_queued_for_deletion():
			continue
		var distancia := _distancia_a(roca)
		if distancia <= mejor_distancia:
			mejor = roca
			mejor_distancia = distancia
	return mejor


## Distancia desde la rueda hasta el borde de la roca (no hasta su centro).
func _distancia_a(roca: Node3D) -> float:
	if not roca.has_meta("_caja"):
		roca.set_meta("_caja", _caja_de(roca))
	var caja: AABB = roca.get_meta("_caja")
	var rueda := _punto.global_position
	return rueda.distance_to(rueda.clamp(caja.position, caja.end))


static func _caja_de(nodo: Node3D) -> AABB:
	var caja := AABB(nodo.global_position, Vector3.ZERO)
	for malla in nodo.find_children("*", "MeshInstance3D", true, false):
		var m := malla as MeshInstance3D
		caja = caja.merge(m.global_transform * m.get_aabb())
	return caja


func _subir_trozo_por_la_cinta() -> void:
	if _cinta.size() < 2:
		return
	var trozo := TrozoRegolito.crear()
	_vehiculo.add_child(trozo)
	var lado := Vector3(randf_range(-0.3, 0.3), 0, 0)
	trozo.position = _vehiculo.to_local((_cinta[0] as Node3D).global_position) + lado
	var tiempo_tramo := segundos_en_cinta / (_cinta.size() - 1)
	var animacion := trozo.create_tween()
	for i in range(1, _cinta.size()):
		var destino: Vector3 = _vehiculo.to_local((_cinta[i] as Node3D).global_position) + lado
		animacion.tween_property(trozo, "position", destino, tiempo_tramo)
	animacion.tween_callback(trozo.queue_free)
