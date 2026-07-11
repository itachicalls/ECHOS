extends Node

const MAPS := {
	"town": "res://scenes/world/town.tscn",
	"route1": "res://scenes/world/route1.tscn",
	"route2": "res://scenes/world/route2.tscn",
	"desert1": "res://scenes/world/desert1.tscn",
	"desert2": "res://scenes/world/desert2.tscn",
	"desert3": "res://scenes/world/desert3.tscn",
	"jungle1": "res://scenes/world/jungle1.tscn",
	"jungle2": "res://scenes/world/jungle2.tscn",
	"jungle3": "res://scenes/world/jungle3.tscn",
}
const TITLE := "res://scenes/boot/title.tscn"
const BATTLE := "res://scenes/battle/battle.tscn"
const VERSUS_SETUP := "res://scenes/boot/versus_setup.tscn"

var _battle_request: Dictionary = {}
var _return_map: String = "route1"
var _busy: bool = false


func _ready() -> void:
	pass


func go_to_map(map_id: String, spawn_cell: Vector2i = Vector2i(-999, -999), facing: String = "") -> void:
	if not MAPS.has(map_id):
		push_error("Unknown map: %s" % map_id)
		return
	GameState.current_map = map_id
	if spawn_cell != Vector2i(-999, -999):
		GameState.player_cell = spawn_cell
	if facing != "":
		GameState.player_facing = facing
	await _swap_scene(MAPS[map_id])


func go_to_title() -> void:
	await _swap_scene(TITLE)


func go_to_versus_setup() -> void:
	await _swap_scene(VERSUS_SETUP)


func start_wild_battle(def_id: String, level: int) -> void:
	_return_map = GameState.current_map
	var enemy := EchoCatalog.create_instance(def_id, level)
	GameState.mark_seen(def_id)
	_battle_request = {
		"kind": "wild", "enemies": [enemy], "return_map": _return_map,
		"can_flee": true, "can_catch": true, "level": level,
		"enemy_team_ids": [def_id],
	}
	await _swap_scene(BATTLE)


func start_trainer_battle(enemies: Array, trainer_name: String, return_map: String, extra: Dictionary = {}) -> void:
	_return_map = return_map
	var enemy_ids: Array[String] = []
	var level := 10
	for e in enemies:
		if e is EchoInstance:
			enemy_ids.append(e.definition_id)
			level = e.level
	_battle_request = {
		"kind": "trainer", "enemies": enemies, "trainer_name": trainer_name,
		"return_map": return_map, "can_flee": false, "can_catch": false,
		"trainer_id": String(extra.get("trainer_id", "")),
		"reward": int(extra.get("reward", 0)),
		"win_line": String(extra.get("win_line", "")),
		"level": level, "enemy_team_ids": enemy_ids,
	}
	await _swap_scene(BATTLE)


func start_versus_battle(player_ids: Array, enemy_ids: Array, rival_name: String, level: int) -> void:
	_return_map = "town"
	_battle_request = {
		"kind": "versus",
		"trainer_name": rival_name,
		"can_flee": false,
		"can_catch": false,
		"return_map": "town",
		"online": false,
		"level": level,
		"player_team_ids": player_ids,
		"enemy_team_ids": enemy_ids,
	}
	await _swap_scene(BATTLE)


func start_online_versus_battle(player_ids: Array, enemy_ids: Array, opponent_name: String, is_host: bool, level: int) -> void:
	_return_map = "town"
	_battle_request = {
		"kind": "versus",
		"trainer_name": opponent_name,
		"can_flee": false,
		"can_catch": false,
		"return_map": "town",
		"online": true,
		"online_role": "host" if is_host else "guest",
		"level": level,
		"player_team_ids": player_ids,
		"enemy_team_ids": enemy_ids,
	}
	await _swap_scene(BATTLE)


func get_battle_request() -> Dictionary:
	return _battle_request


func ensure_visible() -> void:
	_busy = false


func finish_battle(result: Dictionary) -> void:
	var res := String(result.get("result", ""))
	if GameState.play_mode == "versus" or String(_battle_request.get("kind", "")) == "versus":
		GameState.play_mode = "solo"
		await _swap_scene(TITLE)
		return
	if res == "loss":
		await _swap_scene(MAPS["town"])
		return
	var map_id := String(_battle_request.get("return_map", _return_map))
	if not MAPS.has(map_id):
		map_id = _return_map if MAPS.has(_return_map) else "town"
	await _swap_scene(MAPS[map_id])


func _swap_scene(path: String) -> void:
	while _busy:
		await get_tree().process_frame
	_busy = true
	_lock_players(true)
	var err := get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	_busy = false
	_lock_players(false)
	if err != OK:
		push_error("Scene change failed: %s (%d)" % [path, err])


func _lock_players(v: bool) -> void:
	for p in get_tree().get_nodes_in_group("player"):
		if p.has_method("set_input_locked"):
			p.set_input_locked(v)
