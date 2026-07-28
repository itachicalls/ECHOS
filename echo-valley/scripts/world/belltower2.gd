extends "res://scripts/world/overworld.gd"

## BELLTOWER MIDSPIRE — discoverable themed area.


func _build_map() -> void:
	map_w = 20
	map_h = 24
	default_spawn = Vector2i(9, 22)
	encounter_table = "belltower2"

	fill_ground(0, 0, map_w - 1, map_h - 1, Tiles.STONE)

	for x in map_w:
		if x != 9 and x != 10:
			place_rock(Vector2i(x, 0))
			place_rock(Vector2i(x, map_h - 1))
	for y in range(1, map_h - 1):
		place_rock(Vector2i(0, y))
		place_rock(Vector2i(map_w - 1, y))

	for y in range(0, map_h):
		set_ground(Vector2i(9, y), Tiles.STONE)
		set_ground(Vector2i(10, y), Tiles.STONE)
	for x in range(3, 17):
		set_ground(Vector2i(x, 12), Tiles.STONE)

	add_warp(Vector2i(9, 23), "belltower1", Vector2i(9, 1), "down")
	add_warp(Vector2i(10, 23), "belltower1", Vector2i(10, 1), "down")

	add_warp(Vector2i(9, 0), "belltower3", Vector2i(9, 22), "up")
	add_warp(Vector2i(10, 0), "belltower3", Vector2i(10, 22), "up")

	_brush_patch(2, 8, 7, 14)
	_brush_patch(12, 8, 17, 14)
	_brush_patch(3, 16, 8, 21)
	_brush_patch(12, 3, 16, 7)

	for p in [Vector2i(4, 7), Vector2i(15, 9), Vector2i(8, 15)]:
		add_ground_prop(Tiles.CRYSTAL, p, true)

	add_interact(Vector2i(9, 21), { "type": "sign", "text": "BELLTOWER MIDSPIRE - Ropes and gears. The bells remember names." })

	add_trainer(Vector2i(5, 10), "right", {
		"id": "belltower2_t0", "name": "Scholar Otto", "look": 16,
		"party": [{ "id": "tempestria", "level": 19 }, { "id": "hypnaura", "level": 20 }],
		"reward": 4,
		"intro": ["Belltower Midspire tests every keeper.", "Show me your bond!"],
		"win_line": "Well fought. Come talk again — I know a path you might have missed.",
		"after_lines": [
			"Still here? Good. Listen close:",
			"North leads deeper — the next wing of Belltower Midspire waits.",
		],
		"hint": "North leads deeper — the next wing of Belltower Midspire waits.",
	}, 3)
	add_trainer(Vector2i(14, 14), "left", {
		"id": "belltower2_t1", "name": "Warden Pia", "look": 15,
		"party": [{ "id": "coilfox", "level": 20 }, { "id": "somnarch", "level": 21 }, { "id": "blinkit", "level": 22 }],
		"reward": 5,
		"intro": ["Belltower Midspire tests every keeper.", "Show me your bond!"],
		"win_line": "Well fought. Come talk again — I know a path you might have missed.",
		"after_lines": [
			"Still here? Good. Listen close:",
			"North leads deeper — the next wing of Belltower Midspire waits.",
		],
		"hint": "North leads deeper — the next wing of Belltower Midspire waits.",
	}, 4)
	add_trainer(Vector2i(6, 17), "up", {
		"id": "belltower2_t2", "name": "Seeker Cal", "look": 0,
		"party": [{ "id": "mesmind", "level": 21 }, { "id": "arcanexus", "level": 22 }],
		"reward": 6,
		"intro": ["Belltower Midspire tests every keeper.", "Show me your bond!"],
		"win_line": "Well fought. Come talk again — I know a path you might have missed.",
		"after_lines": [
			"Still here? Good. Listen close:",
			"North leads deeper — the next wing of Belltower Midspire waits.",
		],
		"hint": "North leads deeper — the next wing of Belltower Midspire waits.",
	}, 5)

	add_npc(Vector2i(11, 20), "left", Color(1, 1, 1), {
		"type": "npc",
		"lines": [
			"Ropes and gears. The bells remember names.",
			"Beat the keepers here — talk to them again for path rumors.",
		],
	}, Tiles.TRAINER_PATHS[2], 1)


func _on_map_step(_cell: Vector2i) -> void:
	try_path_ambush("faction_ambush_belltower", [
		"Thunder rolls inside the midspire...",
		"Storm agents rappel from the bell ropes!",
		"\"The crown belongs to the Fracture's storm!\"",
	], [
		{
			"id": "tower_storm1", "name": "Storm Agent", "look": 6,
			"party": [{ "id": "sparklit", "level": 18 }, { "id": "wattpup", "level": 19 }],
			"reward": 3,
			"intro": ["Feel the charge!"],
			"win_line": "Bells... still ringing for you.",
			"after_lines": ["Climb. Something nests at the crown."],
		},
		{
			"id": "tower_storm2", "name": "Bolt Warden", "look": 7,
			"party": [{ "id": "voltwing", "level": 19 }, { "id": "zaptenna", "level": 20 }],
			"reward": 4,
			"intro": ["No higher without a fight!"],
			"win_line": "The spire yields a step.",
			"after_lines": ["A storm-raptor waits above."],
		},
	])


func _place_pickups() -> void:
	add_pickup(Vector2i(3, 19), "echo_capsule", 2)
	add_pickup(Vector2i(16, 5), "heart_salve", 2)
	add_pickup(Vector2i(4, 9), "great_capsule", 1)
	add_pickup(Vector2i(17, 18), "super_salve", 1)


func _brush_patch(x0: int, y0: int, x1: int, y1: int) -> void:
	for x in range(x0, x1 + 1):
		for y in range(y0, y1 + 1):
			if not is_blocked(Vector2i(x, y)) and not warps.has(Vector2i(x, y)):
				place_tall_grass(Vector2i(x, y), Tiles.DESERT_BRUSH)
