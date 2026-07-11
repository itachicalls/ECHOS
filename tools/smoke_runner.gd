extends Node

## Run with: godot --headless --path . res://tools/smoke_runner.tscn


func _ready() -> void:
	await get_tree().process_frame
	var failed := 0
	print("--- Echoheart smoke test ---")

	if EchoCatalog.all_echo_ids().size() < 3:
		printerr("FAIL: expected starter echoes in catalog")
		failed += 1
	else:
		print("PASS: catalog has echoes")

	for starter in ["emberkit", "tideling", "mossprite"]:
		if not EchoCatalog.has_echo(starter):
			printerr("FAIL: missing starter %s" % starter)
			failed += 1

	var player: EchoInstance = EchoCatalog.create_instance("emberkit", 5)
	var enemy: EchoInstance = EchoCatalog.create_instance("pebblit", 4)
	var state: Dictionary = CombatResolver.build_opening_state([player], [enemy])
	var action := {"type": EchoTypes.BattleActionType.CHIME, "chime_id": "ember_spark"}
	var enemy_action := {"type": EchoTypes.BattleActionType.CHIME, "chime_id": "pebble_tap"}
	state = CombatResolver.resolve_turn(state, action, enemy_action)
	if state.get("log", []).is_empty():
		printerr("FAIL: combat produced no events")
		failed += 1
	else:
		print("PASS: combat resolved a turn (%d events)" % state.log.size())

	GameState.choose_starter("tideling")
	if not GameState.has_starter():
		printerr("FAIL: starter not set")
		failed += 1
	else:
		print("PASS: starter bonded")

	if not SaveService.save_game():
		printerr("FAIL: save_game")
		failed += 1
	else:
		print("PASS: save_game")

	GameState.party.clear()
	if not SaveService.load_game() or GameState.party.is_empty():
		printerr("FAIL: load_game")
		failed += 1
	else:
		print("PASS: load_game restored party (%s)" % GameState.party[0].display_name())

	var grower: EchoInstance = EchoCatalog.create_instance("mossprite", 11)
	var events: Array[Dictionary] = grower.gain_xp(9999)
	var evolved := false
	for event in events:
		if String(event.get("type", "")) == "evolve":
			evolved = true
	if grower.level < 12 or not evolved:
		printerr("FAIL: evolution path (level=%d evolved=%s)" % [grower.level, evolved])
		failed += 1
	else:
		print("PASS: Mossprite evolved to %s at Lv%d" % [grower.display_name(), grower.level])

	if failed == 0:
		print("--- ALL SMOKE TESTS PASSED ---")
		get_tree().quit(0)
	else:
		printerr("--- %d TEST(S) FAILED ---" % failed)
		get_tree().quit(1)
