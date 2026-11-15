extends Node3D
## Astronauta con esqueleto y animaciones de Mixamo (models/personaje/mixamo/).
## Junta las 4 animaciones en un solo AnimationPlayer con nombres en español:
##   "caminar", "subir_escaleras", "bajar_escaleras" y "quieto".
## Si va como hijo de un CharacterBody3D (el jugador), elige solo entre "quieto" y
## "caminar" según qué tan rápido se mueve.
## Para usar otra animación: poner("nombre", rapidez).

## Animación con la que empieza.
@export var animacion_inicial := "quieto"
## Si es verdadero y el padre es un CharacterBody3D, camina o se queda quieto solo.
@export var automatica := true

const CARPETA := "res://models/personaje/mixamo/"
## Mixamo pensó que el modelo estaba en centímetros: en la escena se agranda 100 veces.
const ESCALA := 100.0
const ARCHIVOS := {
	"caminar": "Walking.fbx",
	"subir_escaleras": "Ascending Stairs.fbx",
	"bajar_escaleras": "Descending Stairs.fbx",
	"quieto": "Breathing Idle.fbx",
}

## Las animaciones y los colores se preparan una sola vez para todos los astronautas.
static var _biblioteca: AnimationLibrary
static var _colores: Array[Material] = []
## Metros por segundo que avanza la animación de caminar (para que los pies no patinen).
static var _velocidad_caminar := 1.4

var animaciones: AnimationPlayer
var _actual := ""
var _cuerpo: CharacterBody3D


func _ready() -> void:
	animaciones = find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _biblioteca == null:
		_preparar_biblioteca()
	if animaciones:
		if animaciones.has_animation_library(""):
			animaciones.remove_animation_library("")
		animaciones.add_animation_library("", _biblioteca)
	_pintar()
	if automatica:
		_cuerpo = get_parent() as CharacterBody3D
	poner(animacion_inicial)


func _physics_process(_delta: float) -> void:
	if _cuerpo == null:
		return
	var v := _cuerpo.velocity
	var rapidez := Vector2(v.x, v.z).length()
	if rapidez > 0.4:
		poner("caminar", rapidez)
	else:
		poner("quieto")


## Pone una animación. "rapidez" ajusta su velocidad: metros por segundo al caminar
## o escalones por segundo en la escalera.
func poner(nombre: String, rapidez := 0.0, velocidad := 1.0) -> void:
	if animaciones == null or not animaciones.has_animation(nombre):
		return
	if nombre == "caminar" and rapidez > 0.0:
		# Más rápido que 1,8 veces se ve acelerado: en la Luna se avanza a saltitos.
		velocidad = clampf(rapidez / _velocidad_caminar, 0.6, 1.8)
	elif nombre.ends_with("escaleras") and rapidez > 0.0:
		# En la escalera "rapidez" son escalones por segundo (cada vuelta de la animación = 2 escalones).
		velocidad = rapidez * animaciones.get_animation(nombre).length / 2.0
	animaciones.speed_scale = velocidad
	if nombre != _actual:
		_actual = nombre
		animaciones.play(nombre, 0.2)


static func _preparar_biblioteca() -> void:
	_biblioteca = AnimationLibrary.new()
	for nombre in ARCHIVOS:
		var escena := load(CARPETA + ARCHIVOS[nombre]) as PackedScene
		if escena == null:
			continue
		var nodo := escena.instantiate()
		var reproductor := nodo.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if reproductor and reproductor.get_animation_list().size() > 0:
			var animacion := reproductor.get_animation(reproductor.get_animation_list()[0]).duplicate() as Animation
			animacion.loop_mode = Animation.LOOP_LINEAR
			if nombre == "caminar":
				_velocidad_caminar = _quitar_avance(animacion, false)
			elif nombre.ends_with("escaleras"):
				# En la escalera la animación también sube (o baja) la cadera: se quita,
				# porque el juego ya mueve al astronauta. Si no, sube o baja el doble.
				_quitar_avance(animacion, true)
			_biblioteca.add_animation(nombre, animacion)
		nodo.free()
	_colores = _colores_originales()


## Las animaciones de Mixamo avanzan solas; el juego ya mueve al astronauta, así que se
## quita ese avance (y la subida o bajada si "tambien_altura"). Devuelve los metros por segundo.
static func _quitar_avance(animacion: Animation, tambien_altura: bool) -> float:
	for pista in animacion.get_track_count():
		if animacion.track_get_type(pista) != Animation.TYPE_POSITION_3D:
			continue
		if not String(animacion.track_get_path(pista)).ends_with("Hips"):
			continue
		var claves := animacion.track_get_key_count(pista)
		if claves < 2:
			return 1.4
		var inicio: Vector3 = animacion.track_get_key_value(pista, 0)
		var fin: Vector3 = animacion.track_get_key_value(pista, claves - 1)
		var avance := Vector3(fin.x - inicio.x, (fin.y - inicio.y) if tambien_altura else 0.0, fin.z - inicio.z)
		for k in claves:
			var parte := animacion.track_get_key_time(pista, k) / animacion.length
			var valor: Vector3 = animacion.track_get_key_value(pista, k)
			animacion.track_set_key_value(pista, k, valor - avance * parte)
		# El modelo de Mixamo viene 100 veces más chico (la escena lo agranda x100).
		return maxf(Vector2(avance.x, avance.z).length() * ESCALA / animacion.length, 0.5)
	return 1.4


## Mixamo aclara los colores: se vuelven a poner los del modelo original (personaje.glb).
static func _colores_originales() -> Array[Material]:
	var lista: Array[Material] = []
	var escena := load("res://models/personaje/personaje.glb") as PackedScene
	if escena == null:
		return lista
	var nodo := escena.instantiate()
	for malla in nodo.find_children("*", "MeshInstance3D", true, false):
		var m := malla as MeshInstance3D
		for i in m.mesh.get_surface_count():
			lista.append(m.mesh.surface_get_material(i))
	nodo.free()
	return lista


func _pintar() -> void:
	for malla in find_children("*", "MeshInstance3D", true, false):
		var m := malla as MeshInstance3D
		for i in mini(m.mesh.get_surface_count(), _colores.size()):
			m.set_surface_override_material(i, _colores[i])
