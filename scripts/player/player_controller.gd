extends CharacterBody3D

signal moved_step

@export var move_speed: float = 5.5
@export var acceleration: float = 18.0
@export var turn_speed: float = 10.0
@export var gravity: float = 20.0

@onready var visual: Node3D = $Visual
@onready var camera_rig: Node3D = $CameraRig

var _step_accum: float = 0.0
var _input_enabled: bool = true


func _ready() -> void:
	global_position = GameState.player_position
	rotation.y = GameState.player_yaw


func _physics_process(delta: float) -> void:
	if not _input_enabled:
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)
		if not is_on_floor():
			velocity.y -= gravity * delta
		move_and_slide()
		return

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var cam_basis := camera_rig.global_transform.basis
	var forward := -cam_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := cam_basis.x
	right.y = 0.0
	right = right.normalized()
	var direction := (forward * -input_dir.y + right * input_dir.x)
	if direction.length() > 1.0:
		direction = direction.normalized()

	var target := direction * move_speed
	velocity.x = move_toward(velocity.x, target.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target.z, acceleration * delta)
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	move_and_slide()

	if direction.length() > 0.05:
		var target_yaw := atan2(direction.x, direction.z)
		visual.rotation.y = lerp_angle(visual.rotation.y, target_yaw, turn_speed * delta)
		_step_accum += velocity.length() * delta
		if _step_accum >= 1.0:
			_step_accum = 0.0
			moved_step.emit()

	GameState.player_position = global_position
	GameState.player_yaw = visual.rotation.y


func set_input_enabled(enabled: bool) -> void:
	_input_enabled = enabled
