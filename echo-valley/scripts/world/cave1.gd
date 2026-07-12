extends "res://scripts/world/overworld.gd"

## CRAG CAVERNS - UPPER HALL. A rocky, torch-lit cavern reached from the
## jungle's northern pass. Winding stone corridors, rubble, and hardy spelunkers.


func _build_map() -> void:
	map_w = 20
	map_h = 24
	default_spawn = Vector2i(9, 22)
	encounter_table = "cave1"

	fill_ground(0, 0, map_w - 1, map_h - 1, Tiles.CAVE_FLOOR)

	# solid rock border (leave the south entrance + north pass open)
	for x in map_w:
		if x != 9 and x != 10:
			place_rock(Vector2i(x, 0))
			place_rock(Vector2i(x, map_h - 1))
	for y in range(1, map_h - 1):
		place_rock(Vector2i(0, y))
		place_rock(Vector2i(map_w - 1, y))

	# warps: south back to the jungle, north deeper into the caverns
	add_warp(Vector2i(9, 23), "jungle3", Vector2i(9, 1), "down")
	add_warp(Vector2i(10, 23), "jungle3", Vector2i(10, 1), "down")
	add_warp(Vector2i(9, 0), "cave2", Vector2i(9, 22), "up")
	add_warp(Vector2i(10, 0), "cave2", Vector2i(10, 22), "up")

	# interior rock walls carving a winding route
	_rock_row(2, 6, 2)
	_rock_row(8, 14, 2)
	_rock_row(3, 8, 8)
	_rock_row(12, 17, 6)
	_rock_row(3, 11, 12)
	_rock_row(6, 10, 16)
	_rock_row(13, 17, 15)
	_rock_col(4, 8, 6)
	_rock_col(8, 13, 13)

	# wall torches for atmosphere
	for p in [Vector2i(1, 4), Vector2i(18, 5), Vector2i(1, 12), Vector2i(18, 14), Vector2i(1, 19), Vector2i(18, 20)]:
		set_decor(p, Tiles.CAVE_TORCH)

	# shadowed rubble patches = wild encounters
	_den(2, 3, 5, 6)
	_den(14, 3, 17, 6)
	_den(3, 13, 7, 16)
	_den(14, 16, 17, 20)
	_den(8, 18, 11, 21)

	# a lantern-lit rest camp deeper in
	add_heal_station(Vector2i(3, 10), Vector2i(3, 9), "down")
	add_interact(Vector2i(9, 21), { "type": "sign", "text": "CRAG CAVERNS - UPPER HALL. Watch your step; the deep dark holds strong Echoes." })

	add_trainer(Vector2i(8, 5), "down", {
		"id": "cave1_spelunker", "name": "Spelunker Rhod", "look": 5,
		"party": [{ "id": "cobblit", "level": 23 }, { "id": "shardling", "level": 24 }, { "id": "bouldrake", "level": 25 }],
		"reward": 8,
		"intro": ["Ha! A surface-dweller in MY caverns?", "Let's see if your Echoes can take the pressure!"],
		"win_line": "Solid team. The deeper hall's just ahead.",
	})
	add_trainer(Vector2i(15, 11), "left", {
		"id": "cave1_seer", "name": "Cave Seer Luma", "look": 6,
		"party": [{ "id": "shadelet", "level": 24 }, { "id": "umbrapaw", "level": 25 }, { "id": "flintling", "level": 25 }],
		"reward": 9,
		"intro": ["The dark whispers of a challenger...", "Prove your light is worth following!"],
		"win_line": "Your flame burns bright. Go on, seeker.",
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
