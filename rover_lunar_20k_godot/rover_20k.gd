extends CharacterBody3D
@export var speed := 6.0
@export var turn_speed := 1.6
@export var gravity := 9.8
func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = -0.1
    var forward_input := Input.get_axis("ui_down", "ui_up")
    var turn_input := Input.get_axis("ui_left", "ui_right")
    if abs(forward_input) > 0.01:
        rotate_y(-turn_input * turn_speed * delta)
    var forward := -global_transform.basis.z
    velocity.x = forward.x * forward_input * speed
    velocity.z = forward.z * forward_input * speed
    move_and_slide()
