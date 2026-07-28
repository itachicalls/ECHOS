extends "res://scripts/world/overworld.gd"

## VINE CATHEDRAL — discoverable themed area.


func _build_map() -> void:
	map_w = 20
	map_h = 24
	default_spawn = Vector2i(9, 22)
	encounter_table = "vine_cathedral"

	fill_ground(0, 0, map_w - 1, map_h - 1, Tiles.GRASS)

	for x in map_w:
		if x != 9 and x != 10:
			place_tree(Vector2i(x, 0), Tiles.TREE_GREEN_COL)
			place_tree(Vector2i(x, map_h - 1), Tiles.TREE_GREEN_COL)
	for y in range(1, map_h - 1):
		place_tree(Vector2i(0, y), Tiles.TREE_GREEN_COL)
		place_tree(Vector2i(map_w - 1, y), Tiles.TREE_GREEN_COL)

	for y in range(0, map_h):
		set_ground(Vector2i(9, y), Tiles.PATH)
		set_ground(Vector2i(10, y), Tiles.PATH)
	for x in range(3, 17):
		set_ground(Vector2i(x, 12), Tiles.PATH)

	add_warp(Vector2i(9, 23), "jungle1", Vector2i(18, 10), "down")
	add_warp(Vector2i(10, 23), "jungle1", Vector2i(19, 10), "down")

	_brush_patch(2, 8, 7, 14)
	_brush_patch(12, 8, 17, 14)
	_brush_patch(3, 16, 8, 21)
	_brush_patch(12, 3, 16, 7)

	for p in [Vector2i(4, 8), Vector2i(15, 7), Vector2i(7, 15)]:
		place_bush(p)
	set_decor(Vector2i(12, 12), Tiles.MUSHROOM)

	add_interact(Vector2i(9, 21), { "type": "sign", "text": "VINE CATHEDRAL - Living arches of ivy form a green nave." })

	add_trainer(Vector2i(5, 10), "right", {
		"id": "vine_cathedral_t0", "name": "Acolyte Vee", "look": 10,
		"party": [{ "id": "mindflare", "level": 19 }, { "id": "psybit", "level": 20 }],
		"reward": 4,
		"intro": ["Vine Cathedral tests every keeper.", "Show me your bond!"],
		"win_line": "Well fought. Come talk again — I know a path you might have missed.",
		"after_lines": [
			"Still here? Good. Listen close:",
			"Talk to every beaten keeper. We trade rumors for tough fights.",
		],
		"hint": "Talk to every beaten keeper. We trade rumors for tough fights.",
	}, 3)
	add_trainer(Vector2i(14, 14), "left", {
		"id": "vine_cathedral_t1", "name": "Scholar Otto", "look": 9,
		"party": [{ "id": "chorusprime", "level": 20 }, { "id": "mossling", "level": 21 }, { "id": "verdantaur", "level": 22 }],
		"reward": 5,
		"intro": ["Vine Cathedral tests every keeper.", "Show me your bond!"],
		"win_line": "Well fought. Come talk again — I know a path you might have missed.",
		"after_lines": [
			"Still here? Good. Listen close:",
			"Side paths hide mansions, towers, and mines off the main gym road.",
		],
		"hint": "Side paths hide mansions, towers, and mines off the main gym road.",
	}, 4)
	add_trainer(Vector2i(6, 17), "up", {
		"id": "vine_cathedral_t2", "name": "Warden Pia", "look": 0,
		"party": [{ "id": "leechrex", "level": 21 }, { "id": "fernkit", "level": 22 }],
		"reward": 6,
		"intro": ["Vine Cathedral tests every keeper.", "Show me your bond!"],
		"win_line": "Well fought. Come talk again — I know a path you might have missed.",
		"after_lines": [
			"Still here? Good. Listen close:",
			"After Champion Vael, the western Tidecross trail opens from Harmona Rest. After Primordius, go south to Ashpeak.",
		],
		"hint": "After Champion Vael, the western Tidecross trail opens from Harmona Rest. After Primordius, go south to Ashpeak.",
	}, 5)

	add_npc(Vector2i(11, 20), "left", Color(1, 1, 1), {
		"type": "npc",
		"lines": [
			"Living arches of ivy form a green nave.",
			"Beat the keepers here — talk to them again for path rumors.",
		],
	}, Tiles.TRAINER_PATHS[7], 1)


func _place_pickups() -> void:
	add_pickup(Vector2i(3, 19), "echo_capsule", 2)
	add_pickup(Vector2i(16, 5), "heart_salve", 2)
	add_pickup(Vector2i(4, 9), "great_capsule", 1)
	add_pickup(Vector2i(17, 18), "super_salve", 1)


func _brush_patch(x0: int, y0: int, x1: int, y1: int) -> void:
	for x in range(x0, x1 + 1):
		for y in range(y0, y1 + 1):
			if not is_blocked(Vector2i(x, y)) and not warps.has(Vector2i(x, y)):
				place_tall_grass(Vector2i(x, y), Tiles.TALL_GRASS)
