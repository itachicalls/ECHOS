extends "res://scripts/world/overworld.gd"


func _build_map() -> void:
	map_w = 24
	map_h = 24
	default_spawn = Vector2i(10, 22)
	encounter_table = "desert3"

	fill_ground(0, 0, map_w - 1, map_h - 1, Tiles.SAND)
	for x in range(2, map_w, 4):
		for y in range(1, map_h, 4):
			set_ground(Vector2i(x, y), Tiles.SAND2)

	for x in map_w:
		if x != 10 and x != 11:
			place_tree(Vector2i(x, 0), Tiles.TREE_ORANGE_COL)
			place_tree(Vector2i(x, map_h - 1), Tiles.TREE_ORANGE_COL)
	for y in range(1, map_h - 1):
		place_tree(Vector2i(0, y), Tiles.TREE_ORANGE_COL)
		if y != 8 and y != 9:
			place_tree(Vector2i(map_w - 1, y), Tiles.TREE_ORANGE_COL)

	for y in range(0, 24):
		set_ground(Vector2i(10, y), Tiles.SAND_PATH)
		set_ground(Vector2i(11, y), Tiles.SAND_PATH)
	for x in range(11, 24):
		set_ground(Vector2i(x, 8), Tiles.SAND_PATH)
		set_ground(Vector2i(x, 9), Tiles.SAND_PATH)

	add_warp(Vector2i(10, 23), "desert2", Vector2i(9, 1), "down")
	add_warp(Vector2i(11, 23), "desert2", Vector2i(10, 1), "down")
	add_warp(Vector2i(23, 8), "jungle1", Vector2i(1, 10), "right")
	add_warp(Vector2i(23, 9), "jungle1", Vector2i(1, 11), "right")

	# oasis pond near the rest stop
	for x in range(3, 6):
		for y in range(6, 9):
			set_ground(Vector2i(x, y), Tiles.WATER)
			block(Vector2i(x, y))

	_brush_patch(14, 4, 19, 7)
	_brush_patch(3, 12, 8, 18)
	_brush_patch(15, 14, 20, 21)

	for p in [Vector2i(18, 6), Vector2i(5, 14), Vector2i(19, 18), Vector2i(8, 6)]:
		place_bush(p)

	# oasis clinic
	add_heal_station(Vector2i(7, 8), Vector2i(7, 7), "down")
	add_interact(Vector2i(8, 8), { "type": "sign", "text": "SCORCH ROUTE 3 - the oasis nurse heals weary travelers. East: Verdant Thicket." })

	add_trainer(Vector2i(17, 15), "left", {
		"id": "d3_warden", "name": "Sun Warden", "look": 5,
		"party": [{ "id": "craggan", "level": 15 }, { "id": "flarefox", "level": 16 }, { "id": "nocturn", "level": 15 }],
		"reward": 6,
		"intro": ["None pass the sun throne without proving themselves!", "Face the heat!"],
		"win_line": "The desert crowns you champion. Until we meet again.",
	})

	# DESERT GYM — seals the eastern pass to the Verdant Jungle.
	add_interact(Vector2i(21, 10), { "type": "sign", "text": "SCORCH TRIAL - Ranger Sol blocks the jungle pass. Earn his Sigil to cross!" })
	add_gym_gate({
		"id": "gym_desert", "name": "Ranger Sol", "look": 5,
		"party": [{ "id": "cindboth", "level": 17 }, { "id": "dunejaw", "level": 18 }, { "id": "flintaur", "level": 19 }],
		"reward": 7, "gym": true,
		"intro": ["I am Sol, Scorch Route Ranger.", "The jungle lies east — prove you can restore its resonance!"],
		"win_line": "You have the desert's fire in you. The pass east is yours!",
	}, Vector2i(22, 8), "left", [Vector2i(23, 8), Vector2i(23, 9)], Vector2i(22, 6), [Vector2i(22, 9)])

	# jagged rock hazards guarding the throne approach
	for p in [Vector2i(13, 10), Vector2i(14, 11), Vector2i(15, 10), Vector2i(16, 12), Vector2i(12, 13)]:
		if not is_blocked(p):
			add_desert_spikes(p)
	add_interact(Vector2i(9, 12), { "type": "sign", "text": "CAUTION: jagged rocks ahead sting careless Harmons." })


func _place_pickups() -> void:
	add_pickup(Vector2i(4, 20), "heart_salve", 2)
	add_pickup(Vector2i(20, 4), "echo_capsule", 3)


func _brush_patch(x0: int, y0: int, x1: int, y1: int) -> void:
	for x in range(x0, x1 + 1):
		for y in range(y0, y1 + 1):
			if not is_blocked(Vector2i(x, y)):
				place_tall_grass(Vector2i(x, y), Tiles.DESERT_BRUSH)
