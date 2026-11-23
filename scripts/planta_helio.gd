extends Node
## Planta de helio-3 de la estación lunar: lleva la cuenta del proceso real, etapa por etapa.
##   1-2. Exploración y excavación: el vehículo extractor junta regolito y lo deja en la tolva.
##   3. Clasificación (Laboratorio): tamices y separadores dejan solo los granos finos.
##   4. Calentamiento (Reactor): a 700-1.000 °C el regolito suelta los gases atrapados.
##   5. Captura de gases (Depósitos): filtrar, comprimir y enfriar; se guarda el hidrógeno.
##   6. Separación isotópica (Núcleo): destilación criogénica que separa helio-3 de helio-4.
##   7. Almacenamiento (Esclusa): el helio-3 se envasa en cápsulas para llevarlo a la nave.
## Las consolas (scripts/consola_planta.gd) preguntan aquí si su etapa puede empezar.

signal cambio

enum Etapa { CLASIFICAR = 3, CALENTAR = 4, CAPTURAR = 5, SEPARAR = 6, ALMACENAR = 7 }

const NOMBRES := {
	Etapa.CLASIFICAR: "Regolith beneficiation",
	Etapa.CALENTAR: "Heating",
	Etapa.CAPTURAR: "Gas capture",
	Etapa.SEPARAR: "Isotope separation",
	Etapa.ALMACENAR: "Storage",
}
const LUGARES := {
	Etapa.CLASIFICAR: "the Laboratory",
	Etapa.CALENTAR: "the Reactor",
	Etapa.CAPTURAR: "the Gas tanks",
	Etapa.SEPARAR: "the station Core",
	Etapa.ALMACENAR: "the Airlock",
}

## Cuánto regolito hace falta para una cápsula de helio-3.
@export var regolito_por_capsula := 3
## Cápsula que sale al terminar.
@export var capsula: PackedScene = preload("res://scenes/objetos/capsula_helio3.tscn")
## Reactor (scripts/procesador_helio.gd), para que brille mientras calienta.
@export var reactor: Node
## Dónde salen las cápsulas (lo pone la estación: frente a la esclusa).
@export var salida_capsulas: Node3D

## Regolito esperando en la tolva (lo deja el vehículo en el reactor).
var regolito_en_tolva := 0
## Cápsulas que saldrán del lote que se está procesando.
var lote := 0
## Etapa que toca ahora.
var etapa: Etapa = Etapa.CLASIFICAR
## Datos del lote (para las pantallas de las consolas).
var datos := {}


func _ready() -> void:
	add_to_group("planta_helio")


## El vehículo (o el jugador) deja regolito en la tolva.
func recibir_regolito(cantidad: int) -> void:
	regolito_en_tolva += cantidad
	cambio.emit()
	if etapa == Etapa.CLASIFICAR and lote == 0:
		Juego.mostrar_mensaje("Regolith in the hopper: %d. Stage 3: go to the Laboratory and sort it" % regolito_en_tolva)


## Explica por qué una etapa no puede empezar (vacío = sí puede).
func motivo_para_no_empezar(de_etapa: Etapa) -> String:
	if de_etapa != etapa:
		return "First finish stage %d: %s in %s" % [etapa, NOMBRES[etapa], LUGARES[etapa]]
	if de_etapa == Etapa.CLASIFICAR and lote == 0 and regolito_en_tolva < regolito_por_capsula:
		return "The hopper has %d regolith. %d more needed: dig more with the rover and drop it at the reactor" % [regolito_en_tolva, regolito_por_capsula - regolito_en_tolva]
	return ""


## Empieza el lote (al iniciar la clasificación toma el regolito de la tolva).
func preparar_lote() -> void:
	if lote > 0:
		return
	lote = regolito_en_tolva / regolito_por_capsula
	regolito_en_tolva -= lote * regolito_por_capsula
	# Cada carga del vehículo representa unas 30 toneladas de regolito.
	datos = {"toneladas": lote * regolito_por_capsula * 30}
	cambio.emit()


## Una consola terminó su etapa: pasa a la siguiente.
func completar(de_etapa: Etapa) -> void:
	if de_etapa != etapa:
		return
	if de_etapa == Etapa.ALMACENAR:
		_sacar_capsulas()
		etapa = Etapa.CLASIFICAR
		lote = 0
		Juego.mostrar_mensaje("Helium-3 packed! Pick up the capsules in front of the airlock and take them to the ship")
	else:
		etapa = (de_etapa + 1) as Etapa
		Juego.mostrar_mensaje("Stage %d done. Continue with stage %d: %s in %s" % [de_etapa, etapa, NOMBRES[etapa], LUGARES[etapa]])
	cambio.emit()


## El reactor brilla y tiembla mientras calienta.
func calentar_reactor(segundos: float) -> void:
	if reactor and reactor.has_method("calentar"):
		reactor.calentar(segundos)


func _sacar_capsulas() -> void:
	if salida_capsulas == null:
		return
	for i in lote:
		var nueva := capsula.instantiate() as Node3D
		if nueva is Area3D:
			nueva.monitoring = false
		get_tree().current_scene.add_child(nueva)
		var lado := salida_capsulas.global_basis.x * ((i % 5) - 2.0) * 1.3
		nueva.global_position = salida_capsulas.global_position + Vector3.UP * 3.0
		var animacion := nueva.create_tween()
		animacion.tween_interval(i * 0.25)
		animacion.tween_property(nueva, "global_position", salida_capsulas.global_position + lado, 0.6) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		if nueva is Area3D:
			animacion.tween_property(nueva, "monitoring", true, 0.0)
