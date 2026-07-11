extends Area3D

@export var prompt: String = "Press E to interact"
@export var interaction_id: String = ""

signal interacted(id: String)

var _player_inside: bool = false


func _ready() -> void:
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)


func _unhandled_input(event: InputEvent) -> void:
	if not _player_inside:
		return
	if event.is_action_pressed("interact"):
		interacted.emit(interaction_id)
		get_viewport().set_input_as_handled()


func _on_enter(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_inside = true
		EventBus.toast.emit(prompt)


func _on_exit(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_inside = false
