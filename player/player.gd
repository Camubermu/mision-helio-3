extends CharacterBody3D

@export var speed: float = 4.5
@export var acceleration: float = 15.0
@export var deceleration: float = 15.0

@export_group("Head Bob")
@export var bob_amplitude: float = 0.25
@export var bob_frequency: float = 1
@export var bob_smoothing: float = 12.0

@onready var camera: Camera3D = $head/Camera3D

var camera_base_position: Vector3
var bob_phase: float = 0.0


func _ready() -> void:
	camera_base_position = camera.position


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction := (
		transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)
	).normalized()

	var target_velocity := direction * speed
	var change_rate := acceleration if direction != Vector3.ZERO else deceleration

	velocity.x = move_toward(
		velocity.x, target_velocity.x, change_rate * delta
	)
	velocity.z = move_toward(
		velocity.z, target_velocity.z, change_rate * delta
	)

	move_and_slide()
	update_head_bob(delta)


func update_head_bob(delta: float) -> void:
	# Usa el movimiento real para evitar balancearse contra una pared.
	var real_velocity := get_real_velocity()
	var horizontal_speed := Vector2(real_velocity.x, real_velocity.z).length()
	var speed_ratio := clampf(horizontal_speed / maxf(speed, 0.001), 0.0, 1.0)

	var bob_offset := Vector3.ZERO

	if is_on_floor() and horizontal_speed > 0.1:
		bob_phase += TAU * bob_frequency * speed_ratio * delta

		bob_offset.x = sin(bob_phase) * bob_amplitude * 0.5 * speed_ratio
		bob_offset.y = (cos(bob_phase * 2.0) - 1.0) * bob_amplitude * 0.5 * speed_ratio

	camera.position = camera.position.lerp(
		camera_base_position + bob_offset,
		1.0 - exp(-bob_smoothing * delta)
	)
