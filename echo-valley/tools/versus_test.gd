extends SceneTree

## Headless versus flow: setup scene + battle scene with drafted teams.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var db := EchoDatabase.new()
	db.load_from_res()
	EchoDatabase.instance = db

	GameState.play_mode = "versus"
	var setup: PackedScene = load("res://scenes/boot/versus_setup.tscn")
	var inst: Node = setup.instantiate()
	root.add_child(inst)
	await process_frame
	await process_frame
	print("OK versus_setup children=", inst.get_child_count())

	var player_team: Array = []
	var enemy_team: Array = []
	for id in ["emberkit", "tideling", "mossling"]:
		player_team.append(EchoCatalog.create_instance(id, 15))
	for id in ["pebblit", "zephyr", "duskling"]:
		enemy_team.append(EchoCatalog.create_instance(id, 15))

	SceneRouter._battle_request = {
		"kind": "versus",
		"trainer_name": "Test Rival",
		"can_flee": false,
		"can_catch": false,
		"player_override": player_team,
		"enemies": enemy_team,
		"level": 15,
		"player_team_ids": ["emberkit", "tideling", "mossling"],
		"enemy_team_ids": ["pebblit", "zephyr", "duskling"],
	}
	inst.queue_free()
	await process_frame

	var battle_ps: PackedScene = load("res://scenes/battle/battle.tscn")
	var battle: Node = battle_ps.instantiate()
	root.add_child(battle)
	await process_frame
	await process_frame
	await process_frame
	print("OK battle children=", battle.get_child_count())
	print("VERSUS TEST DONE")
	quit(0)
