extends Node

const ZONE_SCENES := {
	"hearthmere": "res://scenes/world/hearthmere_village.tscn",
	"whisperwood": "res://scenes/world/whisperwood.tscn",
	"battle": "res://scenes/battle/battle.tscn",
	"boot": "res://scenes/boot/boot.tscn",
	"versus_setup": "res://scenes/boot/versus_setup.tscn",
}

var _pending_battle: Dictionary = {}
var _return_zone: String = "whisperwood"


func go_to_zone(zone_id: String, spawn_position: Vector3 = Vector3.INF) -> void:
	if not ZONE_SCENES.has(zone_id):
		push_error("Unknown zone: %s" % zone_id)
		return
	if spawn_position != Vector3.INF:
		GameState.player_position = spawn_position
	GameState.current_zone = zone_id
	get_tree().change_scene_to_file(ZONE_SCENES[zone_id])


func start_wild_battle(enemy_definition_id: String, enemy_level: int, return_zone: String = "") -> void:
	_return_zone = return_zone if return_zone != "" else GameState.current_zone
	var enemy := EchoCatalog.create_instance(enemy_definition_id, enemy_level)
	_pending_battle = {
		"kind": "wild",
		"enemies": [enemy],
		"return_zone": _return_zone,
		"can_flee": true,
	}
	EventBus.battle_started.emit(_pending_battle)
	get_tree().change_scene_to_file(ZONE_SCENES.battle)


func start_trainer_battle(enemies: Array, return_zone: String = "boot", can_flee: bool = false) -> void:
	_return_zone = return_zone
	_pending_battle = {
		"kind": "trainer",
		"enemies": enemies,
		"return_zone": return_zone,
		"can_flee": can_flee,
		"trainer_name": "Rival",
	}
	EventBus.battle_started.emit(_pending_battle)
	get_tree().change_scene_to_file(ZONE_SCENES.battle)


func get_battle_request() -> Dictionary:
	return _pending_battle


func finish_battle(result: Dictionary) -> void:
	EventBus.battle_ended.emit(result)
	if GameState.play_mode == "versus":
		get_tree().change_scene_to_file(ZONE_SCENES.boot)
		return
	var zone := String(result.get("return_zone", _return_zone))
	go_to_zone(zone)
