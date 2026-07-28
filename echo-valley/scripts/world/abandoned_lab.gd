extends "res://scripts/world/overworld.gd"

## ARCHIVE LAB RUINS — discoverable themed area.


func _build_map() -> void:
	map_w = 20
	map_h = 24
	default_spawn = Vector2i(9, 22)
	encounter_table = "abandoned_lab"

	fill_ground(0, 0, map_w - 1, map_h - 1, Tiles.GRASS2)

	for x in map_w:
		if x != 9 and x != 10:
			place_tree(Vector2i(x, 0), Tiles.TREE_ORANGE_COL)
			place_tree(Vector2i(x, map_h - 1), Tiles.TREE_ORANGE_COL)
	for y in range(1, map_h - 1):
		place_tree(Vector2i(0, y), Tiles.TREE_ORANGE_COL)
		place_tree(Vector2i(map_w - 1, y), Tiles.TREE_ORANGE_COL)

	for y in range(0, map_h):
		set_ground(Vector2i(9, y), Tiles.PATH)
		set_ground(Vector2i(10, y), Tiles.PATH)
	for x in range(3, 17):
		set_ground(Vector2i(x, 12), Tiles.PATH)

	add_warp(Vector2i(9, 23), "town", Vector2i(20, 9), "down")
	add_warp(Vector2i(10, 23), "town", Vector2i(21, 9), "down")

	add_warp(Vector2i(9, 0), "clockwork_vault", Vector2i(9, 22), "up")
	add_warp(Vector2i(10, 0), "clockwork_vault", Vector2i(10, 22), "up")

	_brush_patch(2, 8, 7, 14)
	_brush_patch(12, 8, 17, 14)
	_brush_patch(3, 16, 8, 21)
	_brush_patch(12, 3, 16, 7)

	for p in [Vector2i(5, 6), Vector2i(14, 7), Vector2i(10, 16)]:
		add_ground_prop(Tiles.CRYSTAL, p, true)

	add_interact(Vector2i(9, 21), { "type": "sign", "text": "ARCHIVE LAB RUINS - The Memory Archive's sealed annex." })

	add_trainer(Vector2i(5, 10), "right", {
		"id": "abandoned_lab_t0", "name": "Keeper Jon", "look": 1,
		"party": [{ "id": "ossuary", "level": 28 }, { "id": "candleflit", "level": 29 }],
		"reward": 5,
		"intro": ["Archive Lab Ruins tests every keeper.", "Show me your bond!"],
		"win_line": "Well fought. Come talk again — I know a path you might have missed.",
		"after_lines": [
			"Still here? Good. Listen close:",
			"North leads deeper — the next wing of Archive Lab Ruins waits.",
		],
		"hint": "North leads deeper — the next wing of Archive Lab Ruins waits.",
	}, 3)
	add_trainer(Vector2i(14, 14), "left", {
		"id": "abandoned_lab_t1", "name": "Sage Lira", "look": 3,
		"party": [{ "id": "reaperwing", "level": 29 }, { "id": "psybud", "level": 30 }, { "id": "sigilix", "level": 31 }],
		"reward": 6,
		"intro": ["Archive Lab Ruins tests every keeper.", "Show me your bond!"],
		"win_line": "Well fought. Come talk again — I know a path you might have missed.",
		"after_lines": [
			"Still here? Good. Listen close:",
			"North leads deeper — the next wing of Archive Lab Ruins waits.",
		],
		"hint": "North leads deeper — the next wing of Archive Lab Ruins waits.",
	}, 4)
	add_trainer(Vector2i(6, 17), "up", {
		"id": "abandoned_lab_t2", "name": "Hunter Rex", "look": 10,
		"party": [{ "id": "tombthorn", "level": 30 }, { "id": "dreamlet", "level": 31 }],
		"reward": 7,
		"intro": ["Archive Lab Ruins tests every keeper.", "Show me your bond!"],
		"win_line": "Well fought. Come talk again — I know a path you might have missed.",
		"after_lines": [
			"Still here? Good. Listen close:",
			"North leads deeper — the next wing of Archive Lab Ruins waits.",
		],
		"hint": "North leads deeper — the next wing of Archive Lab Ruins waits.",
	}, 5)

	add_npc(Vector2i(11, 20), "left", Color(1, 1, 1), {
		"type": "npc",
		"lines": [
			"The Memory Archive's sealed annex.",
			"Beat the keepers here — talk to them again for path rumors.",
		],
	}, Tiles.TRAINER_PATHS[2], 1)


func _on_map_step(_cell: Vector2i) -> void:
	try_path_ambush("faction_ambush_lab", [
		"Console lights flicker to life...",
		"Veil researchers step from the dark annex!",
		"\"The Clockwork Vault is not for keepers.\"",
	], [
		{
			"id": "lab_veil1", "name": "Veil Researcher", "look": 9,
			"party": [{ "id": "psybud", "level": 26 }, { "id": "blinkit", "level": 27 }],
			"reward": 5,
			"intro": ["Subject acquired. Engage!"],
			"win_line": "Hypothesis overturned...",
			"after_lines": ["North: Clockwork Vault. Bring Electric and Psychic."],
		},
		{
			"id": "lab_veil2", "name": "Veil Analyst", "look": 5,
			"party": [{ "id": "mesmind", "level": 27 }, { "id": "plasmind", "level": 28 }],
			"reward": 5,
			"intro": ["Your resonance is an outlier!"],
			"win_line": "We'll revise the model.",
			"after_lines": ["Tesloom waits in the vault gears."],
		},
	])


func _place_pickups() -> void:
	add_pickup(Vector2i(3, 19), "echo_capsule", 3)
	add_pickup(Vector2i(16, 5), "heart_salve", 2)
	add_pickup(Vector2i(4, 9), "great_capsule", 2)
	add_pickup(Vector2i(17, 18), "super_salve", 1)


func _brush_patch(x0: int, y0: int, x1: int, y1: int) -> void:
	for x in range(x0, x1 + 1):
		for y in range(y0, y1 + 1):
			if not is_blocked(Vector2i(x, y)) and not warps.has(Vector2i(x, y)):
				place_tall_grass(Vector2i(x, y), Tiles.TALL_GRASS)
