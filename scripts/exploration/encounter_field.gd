extends Area3D

@export var table_id: String = "whisperwood_grass"

var _table: Dictionary = {}
var _steps_in_field: int = 0
var _player: CharacterBody3D
var _cooldown: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_table = _load_table(table_id)
	monitoring = true


func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta


func bind_player(player: CharacterBody3D) -> void:
	if _player and _player.moved_step.is_connected(_on_player_step):
		_player.moved_step.disconnect(_on_player_step)
	_player = player
	if _player and not _player.moved_step.is_connected(_on_player_step):
		_player.moved_step.connect(_on_player_step)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_steps_in_field = 0


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		_steps_in_field = 0


func _on_player_step() -> void:
	if _cooldown > 0.0:
		return
	if _player == null or not overlaps_body(_player):
		return
	if not GameState.has_starter():
		return
	if GameState.get_living_party().is_empty():
		EventBus.toast.emit("Your Echoes need rest at the Save Shrine.")
		return

	_steps_in_field += 1
	GameState.encounter_steps += 1
	var mercy := int(_table.get("mercy_steps", 10))
	var min_steps := int(_table.get("min_steps", 20))
	if _steps_in_field < mercy:
		return
	if GameState.encounter_steps < min_steps:
		return
	var chance := float(_table.get("chance_per_step", 0.08))
	if randf() > chance:
		return

	var pick := _weighted_pick(_table.get("encounters", []))
	if pick.is_empty():
		return
	var level := randi_range(int(pick.level_min), int(pick.level_max))
	_cooldown = 2.0
	GameState.encounter_steps = 0
	_steps_in_field = 0
	EventBus.toast.emit("A wild Echo stirs...")
	await get_tree().create_timer(0.35).timeout
	SceneRouter.start_wild_battle(String(pick.id), level, GameState.current_zone)


func _weighted_pick(entries: Array) -> Dictionary:
	var total := 0
	for entry in entries:
		total += int(entry.get("weight", 1))
	if total <= 0:
		return {}
	var roll := randi_range(1, total)
	var running := 0
	for entry in entries:
		running += int(entry.get("weight", 1))
		if roll <= running:
			return entry
	return {}


func _load_table(id: String) -> Dictionary:
	var file := FileAccess.open("res://data/encounters/encounters.json", FileAccess.READ)
	if file == null:
		return {}
	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	return data.get(id, {})
