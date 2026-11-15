extends Node3D
## Plataforma de lanzamiento con la nave estacionada encima (por ejemplo, en la Luna).
## Va en la raíz de una plataforma (models/Lanzamiento/plataforma_kodland.tscn).
## Al empezar: sube la nave a la cubierta, cierra los brazos sobre ella, apaga su llama
## y sube también la entrada y el choque de la zona de carga para que coincidan con la nave.

## La nave que se apoya en la plataforma.
@export var nave: Node3D
## La zona de carga de la nave (scripts/carga_nave.gd), si hay.
@export var carga_nave: Node3D
## Animación de la plataforma que suelta el cohete (al revés, lo sujeta).
@export var animacion_soltar: StringName = &"liberar_cohete"
## Verdadero en la Luna: el astronauta sube y baja la escalera con poca gravedad.
@export var gravedad_lunar := true


func _ready() -> void:
	var cubierta := _altura_cubierta()
	if nave:
		nave.global_position = Vector3(global_position.x, global_position.y + cubierta, global_position.z)
		var llama := nave.find_child("Plasma", true, false) as Node3D
		if llama:
			llama.visible = false
	_subir_zona_de_carga(cubierta)
	_cerrar_brazos()
	_poner_escalera()


func _altura_cubierta() -> float:
	var punto := find_child("Punto_Cohete", true, false) as Node3D
	return to_local(punto.global_position).y if punto else 0.0


## La zona de carga sigue en el suelo (para que el jugador llegue caminando),
## pero las cápsulas vuelan a la nave y el choque queda donde está la nave.
func _subir_zona_de_carga(cubierta: float) -> void:
	if carga_nave == null:
		return
	for nombre in ["Entrada", "ColisionCohete"]:
		var nodo := carga_nave.get_node_or_null(nombre) as Node3D
		if nodo:
			nodo.position.y += cubierta


func _cerrar_brazos() -> void:
	var animacion := find_child("AnimationPlayer", true, false) as AnimationPlayer
	if animacion and animacion.has_animation(animacion_soltar):
		animacion.play(animacion_soltar)
		animacion.seek(0.0, true)
		animacion.pause()


## Escalera junto a la torre (scripts/escalera_plataforma.gd) y la zona con E al pie.
func _poner_escalera() -> void:
	var escalera := Node3D.new()
	escalera.name = "Escalera"
	escalera.set_script(load("res://scripts/escalera_plataforma.gd"))
	escalera.set("gravedad_lunar", gravedad_lunar)
	add_child(escalera)
	var pie := Area3D.new()
	pie.name = "PieEscalera"
	pie.set_script(load("res://scripts/pie_escalera.gd"))
	pie.set("escalera", escalera)
	pie.set("carga_nave", carga_nave)
	var forma := CollisionShape3D.new()
	var caja := BoxShape3D.new()
	caja.size = Vector3(4.0, 3.0, 4.0)
	forma.shape = caja
	forma.position.y = 1.5
	pie.add_child(forma)
	add_child(pie)
	pie.global_position = escalera.punto_pie()
	if carga_nave:
		carga_nave.set("abordar_con_e", false)
