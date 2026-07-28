extends "res://scripts/world/overworld.gd"

## MANOR GALLERIES — discoverable themed area.


func _build_map() -> void:
	map_w = 20
	map_h = 24
	default_spawn = Vector2i(9, 22)
	encounter_table = "haunted_manor2"

	fill_ground(0, 0, map_w - 1, map_h - 1, Tiles.CAVE_FLOOR2)

	for x in map_w:
		if x != 9 and x != 10:
			place_rock(Vector2i(x, 0))
			place_rock(Vector2i(x, map_h - 1))
	for y in range(1, map_h - 1):
		place_rock(Vector2i(0, y))
		place_rock(Vector2i(map_w - 1, y))

	for y in range(0, map_h):
		set_ground(Vector2i(9, y), Tiles.CAVE_FLOOR)
		set_ground(Vector2i(10, y), Tiles.CAVE_FLOOR)
	for x in range(3, 17):
		set_ground(Vector2i(x, 12), Tiles.CAVE_FLOOR)

	add_warp(Vector2i(9, 23), "haunted_manor1", Vector2i(9, 1), "down")
	add_warp(Vector2i(10, 23), "haunted_manor1", Vector2i(10, 1), "down")

	add_warp(Vector2i(9, 0), "haunted_manor3", Vector2i(9, 22), "up")
	add_warp(Vector2i(10, 0), "haunted_manor3", Vector2i(10, 22), "up")

	_brush_patch(2, 8, 7, 14)
	_brush_patch(12, 8, 17, 14)
	_brush_patch(3, 16, 8, 21)
	_brush_patch(12, 3, 16, 7)

	for p in [Vector2i(4, 6), Vector2i(15, 8), Vector2i(7, 12), Vector2i(12, 18)]:
		add_ground_prop(Tiles.TOMBSTONE, p, true)

	add_interact(Vector2i(9, 21), { "type": "sign", "text": "MANOR GALLERIES - Paintings whisper. Corridors refuse to stay still." })

	add_trainer(Vector2i(5, 10), "right", {
		"id": "haunted_manor2_t0", "name": "Hunter Rex", "look": 17,
		"party": [{ "id": "arcanexus", "level": 16 }, { "id": "willowick", "level": 17 }],
		"reward": 4,
		"intro": ["Manor Galleries tests every keeper.", "Show me your bond!"],
		"win_line": "Well fought. Come talk again — I know a path you might have missed.",
		"after_lines": [
			"Still here? Good. Listen close:",
			"North leads deeper — the next wing of Manor Galleries waits.",
		],
		"hint": "North leads deeper — the next wing of Manor Galleries waits.",
	}, 3)
	add_trainer(Vector2i(14, 14), "left", {
		"id": "haunted_manor2_t1", "name": "Acolyte Vee", "look": 6,
		"party": [{ "id": "cosmindra", "level": 17 }, { "id": "aeonmind", "level": 18 }, { "id": "orbkit", "level": 19 }],
		"reward": 5,
		"intro": ["Manor Galleries tests every keeper.", "Show me your bond!"],
		"win_line": "Well fought. Come talk again — I know a path you might have missed.",
		"after_lines": [
			"Still here? Good. Listen close:",
			"North leads deeper — the next wing of Manor Galleries waits.",
		],
		"hint": "North leads deeper — the next wing of Manor Galleries waits.",
	}, 4)
	add_trainer(Vector2i(6, 17), "up", {
		"id": "haunted_manor2_t2", "name": "Scholar Otto", "look": 1,
		"party": [{ "id": "telephase", "level": 18 }, { "id": "siphon", "level": 19 }],
		"reward": 6,
		"intro": ["Manor Galleries tests every keeper.", "Show me your bond!"],
		"win_line": "Well fought. Come talk again — I know a path you might have missed.",
		"after_lines": [
			"Still here? Good. Listen close:",
			"North leads deeper — the next wing of Manor Galleries waits.",
		],
		"hint": "North leads deeper — the next wing of Manor Galleries waits.",
	}, 5)

	add_npc(Vector2i(11, 20), "left", Color(1, 1, 1), {
		"type": "npc",
		"lines": [
			"Paintings whisper. Corridors refuse to stay still.",
			"Beat the keepers here — talk to them again for path rumors.",
		],
	}, Tiles.TRAINER_PATHS[6], 1)


func _on_map_step(_cell: Vector2i) -> void:
	try_path_ambush("faction_ambush_manor", [
		"The gallery lights gutter...",
		"Veil shades peel from the portraits!",
		"\"This house remembers. You are not welcome.\"",
	], [
		{
			"id": "manor_veil1", "name": "Veil Shade", "look": 9,
			"party": [{ "id": "shadelet", "level": 16 }, { "id": "wispurr", "level": 17 }],
			"reward": 3,
			"intro": ["Dust and memory — fight!"],
			"win_line": "The portraits go still...",
			"after_lines": ["North: the crypt. Bring shadow-ready Harmons."],
		},
		{
			"id": "manor_veil2", "name": "Veil Curator", "look": 4,
			"party": [{ "id": "hexling", "level": 17 }, { "id": "gloomkin", "level": 18 }],
			"reward": 3,
			"intro": ["Catalog your fear."],
			"win_line": "Noted. You persist.",
			"after_lines": ["The crypt keeps a shadow-lord. Be ready."],
		},
	])


func _place_pickups() -> void:
	add_pickup(Vector2i(3, 19), "echo_capsule", 2)
	add_pickup(Vector2i(16, 5), "heart_salve", 1)
	add_pickup(Vector2i(4, 9), "great_capsule", 1)
	add_pickup(Vector2i(17, 18), "super_salve", 1)


func _brush_patch(x0: int, y0: int, x1: int, y1: int) -> void:
	for x in range(x0, x1 + 1):
		for y in range(y0, y1 + 1):
			if not is_blocked(Vector2i(x, y)) and not warps.has(Vector2i(x, y)):
				place_tall_grass(Vector2i(x, y), Tiles.CAVE_FLOOR2)
