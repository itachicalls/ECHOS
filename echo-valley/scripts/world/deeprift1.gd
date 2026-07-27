extends "res://scripts/world/overworld.gd"

## DEEP RIFT — post-game shadow/psychic endgame north of Frostvale.


func _build_map() -> void:
	map_w = 20
	map_h = 24
	default_spawn = Vector2i(9, 22)
	encounter_table = "deeprift1"

	fill_ground(0, 0, map_w - 1, map_h - 1, Tiles.CAVE_FLOOR)
	for x in map_w:
		if x != 9 and x != 10:
			set_ground(Vector2i(x, 0), Tiles.CAVE_WALL)
			block(Vector2i(x, 0))
			set_ground(Vector2i(x, map_h - 1), Tiles.CAVE_WALL)
			block(Vector2i(x, map_h - 1))
	for y in range(1, map_h - 1):
		set_ground(Vector2i(0, y), Tiles.CAVE_WALL)
		block(Vector2i(0, y))
		set_ground(Vector2i(map_w - 1, y), Tiles.CAVE_WALL)
		block(Vector2i(map_w - 1, y))

	for y in range(0, map_h):
		set_ground(Vector2i(9, y), Tiles.STONE)
		set_ground(Vector2i(10, y), Tiles.STONE)
	for x in range(3, 17):
		set_ground(Vector2i(x, 10), Tiles.STONE)
		set_ground(Vector2i(x, 16), Tiles.STONE)

	set_ground(Vector2i(9, 3), Tiles.CAVE_ALTAR)
	set_ground(Vector2i(10, 3), Tiles.CAVE_ALTAR)

	add_warp(Vector2i(9, 23), "frostvale1", Vector2i(9, 1), "down")
	add_warp(Vector2i(10, 23), "frostvale1", Vector2i(10, 1), "down")

	for p in [Vector2i(4, 6), Vector2i(15, 5), Vector2i(5, 18), Vector2i(14, 17), Vector2i(3, 12)]:
		add_ground_prop(Tiles.CRYSTAL, p, true)

	_den(2, 11, 7, 15)
	_den(12, 11, 17, 15)
	_den(3, 17, 8, 21)
	_den(12, 4, 16, 8)

	add_interact(Vector2i(9, 21), { "type": "sign", "text": "THE DEEP RIFT - thought and shadow braid here. FRACTURAEL stirs at the altar." })
	add_interact(Vector2i(11, 4), { "type": "sign", "text": "\"Where the Fracture cut deepest, a new dream learned to speak.\"" })

	add_trainer(Vector2i(5, 13), "right", {
		"id": "rift_oracle", "name": "Rift Oracle", "look": 9,
		"party": [{ "id": "shadelet", "level": 56 }, { "id": "voidmonarch", "level": 58 }, { "id": "cryptid", "level": 59 }],
		"reward": 13,
		"intro": ["The Rift reads your intent.", "Rewrite it in battle!"],
		"win_line": "Your chapter holds. Proceed.",
	}, 4)
	add_trainer(Vector2i(14, 14), "left", {
		"id": "rift_seer", "name": "Deep Seer", "look": 18,
		"party": [{ "id": "mesmind", "level": 57 }, { "id": "hypnaura", "level": 59 }, { "id": "astralynx", "level": 60 }],
		"reward": 13,
		"intro": ["Mind folds upon mind here.", "Stay lucid — or shatter!"],
		"win_line": "Lucid enough. The altar awaits.",
	}, 5)
	add_trainer(Vector2i(4, 18), "right", {
		"id": "rift_cantor", "name": "Fracture Cantor", "look": 16,
		"party": [{ "id": "gloomkin", "level": 55 }, { "id": "phantling", "level": 57 }, { "id": "reaperwing", "level": 60 }],
		"reward": 12,
		"intro": ["We hymn the cut in the world.", "Match our dissonance!"],
		"win_line": "Harmony from fracture. Rare.",
	}, 4)
	add_trainer(Vector2i(15, 7), "down", {
		"id": "rift_archon", "name": "Rift Archon", "look": 4,
		"party": [{ "id": "sigilix", "level": 58 }, { "id": "mindflare", "level": 60 }, { "id": "grimsovereign", "level": 62 }],
		"reward": 14,
		"intro": ["Beyond this hall lies FRACTURAEL.", "Earn the right to stand before it!"],
		"win_line": "The Rift yields. Face the dream.",
	}, 5)
	add_legend_encounter(Vector2i(9, 4), "fracturael", 70,
		"The altar cracks into violet geometry. FRACTURAEL — fracture given will — unfolds toward you!")

	add_heal_station(Vector2i(12, 20), Vector2i(12, 19), "down")


func _place_pickups() -> void:
	add_pickup(Vector2i(3, 20), "ultra_capsule", 4)
	add_pickup(Vector2i(16, 6), "max_salve", 3)
	add_pickup(Vector2i(6, 8), "super_salve", 3)
	add_pickup(Vector2i(17, 18), "ultra_capsule", 2)


func _den(x0: int, y0: int, x1: int, y1: int) -> void:
	for x in range(x0, x1 + 1):
		for y in range(y0, y1 + 1):
			var c := Vector2i(x, y)
			if not is_blocked(c) and not warps.has(c):
				set_ground(c, Tiles.CAVE_FLOOR2)
				grass[c] = true
