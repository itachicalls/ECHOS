extends Node3D

@export var sensitivity: float = 1.6
@export var min_pitch: float = -35.0
@export var max_pitch: float = 55.0
@export var zoom_distance: float = 7.5
@export var follow_smoothing: float = 8.0

@onready var pivot: Node3D = $Pivot
@onready var spring_arm: SpringArm3D = $Pivot/SpringArm3D
@onready var camera: Camera3D = $Pivot/SpringArm3D/Camera3D

var _yaw: float = 0.0
var _pitch: float = -18.0


func _ready() -> void:
	spring_arm.spring_length = zoom_distance
	_apply_rotation()


func _process(delta: float) -> void:
	var yaw_input := Input.get_axis("camera_left", "camera_right")
	_yaw -= yaw_input * sensitivity * 60.0 * delta
	# Mouse look while right mouse held (desktop convenience).
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		var motion := Input.get_last_mouse_velocity()
		_yaw -= motion.x * 0.012
		_pitch -= motion.y * 0.012
	_pitch = clampf(_pitch, min_pitch, max_pitch)
	_apply_rotation()


func _apply_rotation() -> void:
	rotation_degrees.y = _yaw
	pivot.rotation_degrees.x = _pitch
