extends "res://scripts/world/overworld.gd"

## CRAG CAVERNS - THE DEEP THRONE. The final chamber, where the Valley
## Champion waits atop an ancient dais lit by everburning torches.


func _build_map() -> void:
	map_w = 20
	map_h = 24
	default_spawn = Vector2i(9, 22)
	encounter_table = "cave2"

	fill_ground(0, 0, map_w - 1, map_h - 1, Tiles.CAVE_FLOOR)

	# solid rock border (only the south passage stays open)
	for x in map_w:
		if x != 9 and x != 10:
			place_rock(Vector2i(x, 0))
			place_rock(Vector2i(x, map_h - 1))
	for y in range(1, map_h - 1):
		place_rock(Vector2i(0, y))
		place_rock(Vector2i(map_w - 1, y))

	add_warp(Vector2i(9, 23), "cave1", Vector2i(9, 1), "down")
	add_warp(Vector2i(10, 23), "cave1", Vector2i(10, 1), "down")

	# --- champion's dais (top center) ---
	for x in range(6, 14):
		place_rock(Vector2i(x, 6))
	# leave a 2-wide gateway into the throne room
	blocked.erase(Vector2i(9, 6))
	blocked.erase(Vector2i(10, 6))
	set_ground(Vector2i(9, 6), Tiles.CAVE_FLOOR)
	set_ground(Vector2i(10, 6), Tiles.CAVE_FLOOR)
	for p in [Vector2i(8, 2), Vector2i(9, 2), Vector2i(10, 2), Vector2i(11, 2)]:
		set_ground(p, Tiles.CAVE_ALTAR)
	for p in [Vector2i(6, 2), Vector2i(13, 2), Vector2i(6, 5), Vector2i(13, 5)]:
		set_decor(p, Tiles.CAVE_TORCH)

	# winding approach through the depths
	_rock_row(2, 6, 9)
	_rock_row(9, 14, 9)
	_rock_col(9, 13, 6)
	_rock_row(6, 11, 13)
	_rock_col(9, 13, 13)
	_rock_row(3, 7, 17)
	_rock_row(12, 16, 17)

	for p in [Vector2i(1, 4), Vector2i(18, 4), Vector2i(1, 12), Vector2i(18, 12), Vector2i(1, 19), Vector2i(18, 19)]:
		set_decor(p, Tiles.CAVE_TORCH)

	_den(3, 10, 6, 12)
	_den(13, 10, 16, 12)
	_den(3, 18, 7, 21)
	_den(12, 18, 16, 21)

	add_heal_station(Vector2i(16, 21), Vector2i(16, 20), "down")
	add_interact(Vector2i(9, 20), { "type": "sign", "text": "THE DEEP THRONE. The Valley Champion tests all who reach the heart of the crag." })
	add_pickup(Vector2i(3, 3), "echo_capsule", 2)

	add_trainer(Vector2i(9, 4), "down", {
		"id": "champion", "name": "Champion Vael", "look": 3,
		"party": [
			{ "id": "titanag", "level": 34 },
			{ "id": "naiaqua", "level": 34 },
			{ "id": "cyclora", "level": 35 },
			{ "id": "flintaur", "level": 35 },
			{ "id": "obsidraith", "level": 36 },
			{ "id": "avalanther", "level": 37 },
		],
		"reward": 20, "gym": true,
		"intro": [
			"So. You crossed every gym, every route, every trial.",
			"I am Vael, Champion of Echo Valley.",
			"Show me the bond you forged on this journey!",
		],
		"win_line": "...Magnificent. Echo Valley has a new legend. The title is yours.",
	})


func _rock_row(x0: int, x1: int, y: int) -> void:
	for x in range(x0, x1 + 1):
		place_rock(Vector2i(x, y))


func _rock_col(y0: int, y1: int, x: int) -> void:
	for y in range(y0, y1 + 1):
		place_rock(Vector2i(x, y))


func _den(x0: int, y0: int, x1: int, y1: int) -> void:
	for x in range(x0, x1 + 1):
		for y in range(y0, y1 + 1):
			var c := Vector2i(x, y)
			if not is_blocked(c):
				set_ground(c, Tiles.CAVE_FLOOR2)
				grass[c] = true
