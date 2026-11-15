extends RefCounted
## Crea trocitos de regolito para las animaciones (cinta del vehículo y descarga en el reactor).
## Uso: var trozo := TrozoRegolito.crear()   (con: const TrozoRegolito = preload("res://scripts/trozo_regolito.gd"))

static var _material: StandardMaterial3D


static func crear() -> MeshInstance3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.albedo_color = Color(0.52, 0.5, 0.47)
		_material.roughness = 1.0
	var radio := randf_range(0.15, 0.3)
	var malla := SphereMesh.new()
	malla.radius = radio
	malla.height = radio * 1.6
	malla.radial_segments = 6
	malla.rings = 3
	var trozo := MeshInstance3D.new()
	trozo.mesh = malla
	trozo.material_override = _material
	trozo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	trozo.rotation = Vector3(randf() * TAU, randf() * TAU, 0)
	return trozo
