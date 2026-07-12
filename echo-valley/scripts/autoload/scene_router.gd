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
	"cave1": "res://scenes/world/cave1.tscn",
	"cave2": "res://scenes/world/cave2.tscn",
}
const TITLE := "res://scenes/boot/title.tscn"
const BATTLE := "res://scenes/battle/battle.tscn"
const VERSUS_SETUP := "res://scenes/boot/versus_setup.tscn"

var _battle_request: Dictionary = {}
var _return_map: String = "route1"
var _busy: bool = false
var _transition_queue: Array[Callable] = []
var _draining_queue: bool = false


func is_busy() -> bool:
	return _busy


func go_to_map(map_id: String, spawn_cell: Vector2i = Vector2i(-999, -999), facing: String = "") -> void:
	var resolved := _normalize_map_id(map_id)
	_apply_map_state(resolved, spawn_cell, facing)
	_run_transition(_swap_scene.bind(MAPS[resolved]))


func go_to_map_and_wait(map_id: String, spawn_cell: Vector2i = Vector2i(-999, -999), facing: String = "") -> void:
	var resolved := _normalize_map_id(map_id)
	_apply_map_state(resolved, spawn_cell, facing)
	await _run_transition_async(_swap_scene.bind(MAPS[resolved]))


func _normalize_map_id(map_id: String) -> String:
	if not MAPS.has(map_id):
		push_error("Unknown map: %s — falling back to town" % map_id)
		return "town"
	return map_id


func _apply_map_state(map_id: String, spawn_cell: Vector2i, facing: String) -> void:
	GameState.current_map = map_id
	if spawn_cell != Vector2i(-999, -999):
		GameState.player_cell = spawn_cell
	if facing != "":
		GameState.player_facing = facing


func go_to_title() -> void:
	_run_transition(_swap_scene.bind(TITLE))


func go_to_versus_setup() -> void:
	_run_transition(_swap_scene.bind(VERSUS_SETUP))


func start_wild_battle(def_id: String, level: int) -> void:
	_return_map = GameState.current_map
	var enemy := EchoCatalog.create_instance(def_id, level)
	var was_caught := bool(GameState.caught.get(def_id, false))
	var was_seen := bool(GameState.seen.get(def_id, false))
	GameState.mark_seen(def_id)
	_battle_request = {
		"kind": "wild", "enemies": [enemy], "return_map": _return_map,
		"can_flee": true, "can_catch": true, "level": level,
		"enemy_team_ids": [def_id],
		"enemy_was_caught": was_caught,
		"enemy_first_seen": not was_seen,
	}
	_run_transition(_swap_scene.bind(BATTLE))


func start_fishing_battle(map_id: String) -> void:
	_return_map = map_id
	var def_id := EchoCatalog.random_water_echo_id()
	var lv := _fishing_level_for_map(map_id)
	var enemy := EchoCatalog.create_instance(def_id, lv)
	GameState.mark_seen(def_id)
	_battle_request = {
		"kind": "fishing",
		"enemies": [enemy],
		"return_map": _return_map,
		"can_flee": true,
		"can_catch": true,
		"level": lv,
		"enemy_team_ids": [def_id],
		"enemy_first_seen": not bool(GameState.seen.get(def_id, false)),
		"enemy_was_caught": bool(GameState.caught.get(def_id, false)),
	}
	_run_transition(_swap_scene.bind(BATTLE))


func _fishing_level_for_map(map_id: String) -> int:
	match map_id:
		"route1": return randi_range(3, 6)
		"route2": return randi_range(7, 10)
		"desert1", "desert2": return randi_range(9, 12)
		"jungle1", "jungle2": return randi_range(12, 16)
		_: return randi_range(5, 12)


func start_ambush_chain(trainers: Array, map_id: String) -> void:
	_return_map = map_id
	_run_transition(_launch_ambush_at.bind(trainers, 0, map_id))


func _launch_ambush_at(trainers: Array, index: int, map_id: String) -> void:
	if index >= trainers.size():
		return
	var trainer: Dictionary = trainers[index]
	var enemies: Array = []
	var enemy_ids: Array[String] = []
	for m in trainer.get("party", []):
		var inst := EchoCatalog.create_instance(String(m.get("id", "")), int(m.get("level", 10)))
		if inst:
			enemies.append(inst)
			enemy_ids.append(inst.definition_id)
	_battle_request = {
		"kind": "ambush",
		"enemies": enemies,
		"trainer_name": String(trainer.get("name", "Agent")),
		"return_map": map_id,
		"can_flee": false,
		"can_catch": false,
		"trainer_id": String(trainer.get("id", "")),
		"reward": int(trainer.get("reward", 0)),
		"win_line": String(trainer.get("win_line", "")),
		"intro": trainer.get("intro", []),
		"ambush_chain": trainers,
		"ambush_index": index,
		"level": int(trainer.get("party", [{}])[0].get("level", 10)) if trainer.get("party", []).size() > 0 else 10,
		"enemy_team_ids": enemy_ids,
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
		"reward_items": extra.get("reward_items", {}),
		"win_line": String(extra.get("win_line", "")),
		"gym": bool(extra.get("gym", false)),
		"ranger": bool(extra.get("ranger", false)),
		"level": level, "enemy_team_ids": enemy_ids,
	}
	_run_transition(_swap_scene.bind(BATTLE))


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
	_run_transition(_swap_scene.bind(BATTLE))


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
	_run_transition(_swap_scene.bind(BATTLE))


func get_battle_request() -> Dictionary:
	return _battle_request


func ensure_visible() -> void:
	_busy = false
	if _draining_queue and _transition_queue.is_empty():
		_draining_queue = false
	if not _draining_queue and _transition_queue.size() > 0:
		_drain_queue_async()


func finish_battle(result: Dictionary) -> void:
	_run_transition(_finish_battle_async.bind(result))


func _finish_battle_async(result: Dictionary) -> void:
	var res := String(result.get("result", ""))
	if res == "win" and _battle_request.get("ambush_chain") is Array:
		var chain: Array = _battle_request.ambush_chain
		var next_i := int(_battle_request.get("ambush_index", 0)) + 1
		if next_i < chain.size():
			var map_id := String(_battle_request.get("return_map", _return_map))
			await _launch_ambush_at(chain, next_i, map_id)
			return
		GameState.flags["faction_ambush_route2"] = true
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


func _run_transition(job: Callable) -> void:
	_transition_queue.append(job)
	if not _draining_queue:
		_drain_queue_async()


func _run_transition_async(job: Callable) -> void:
	_transition_queue.append(job)
	if not _draining_queue:
		_drain_queue_async()
	while _draining_queue or _transition_queue.size() > 0:
		await get_tree().process_frame


func _drain_queue_async() -> void:
	_draining_queue = true
	while _transition_queue.size() > 0:
		var job: Callable = _transition_queue.pop_front()
		_busy = true
		_lock_players(true)
		await job.call()
		_busy = false
		_lock_players(false)
	_draining_queue = false


func _swap_scene(path: String) -> void:
	var tree := get_tree()
	var err := tree.change_scene_to_file(path)
	if err != OK:
		push_error("Scene change failed: %s (%d)" % [path, err])
		return

	var ready := false
	for _i in 180:
		await tree.process_frame
		var scene := tree.current_scene
		if scene != null and scene.is_node_ready():
			ready = true
			break
	if not ready:
		push_error("Scene change timed out waiting for ready: %s" % path)


func _lock_players(v: bool) -> void:
	for p in get_tree().get_nodes_in_group("player"):
		if p.has_method("set_input_locked"):
			p.set_input_locked(v)
