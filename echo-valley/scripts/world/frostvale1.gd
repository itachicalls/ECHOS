extends "res://scripts/world/overworld.gd"

## FROSTVALE REACH — post-game ice/rock/shadow route beyond Skyreach.


func _build_map() -> void:
	map_w = 20
	map_h = 24
	default_spawn = Vector2i(9, 22)
	encounter_table = "frostvale1"

	fill_ground(0, 0, map_w - 1, map_h - 1, Tiles.SAND2)
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
	for x in range(2, 18):
		set_ground(Vector2i(x, 11), Tiles.STONE)

	# frozen pools
	for c in [Vector2i(3, 4), Vector2i(4, 4), Vector2i(3, 5), Vector2i(15, 15), Vector2i(16, 15), Vector2i(15, 16)]:
		set_ground(c, Tiles.WATER)
		block(c)

	add_warp(Vector2i(9, 23), "skyreach1", Vector2i(9, 1), "down")
	add_warp(Vector2i(10, 23), "skyreach1", Vector2i(10, 1), "down")
	add_warp(Vector2i(9, 0), "deeprift1", Vector2i(9, 22), "up")
	add_warp(Vector2i(10, 0), "deeprift1", Vector2i(10, 22), "up")

	for p in [Vector2i(4, 8), Vector2i(15, 7), Vector2i(5, 17), Vector2i(14, 18)]:
		add_ground_prop(Tiles.CRYSTAL, p, true)

	_brush_patch(2, 12, 7, 20)
	_brush_patch(12, 12, 17, 20)
	_brush_patch(3, 3, 8, 9)
	_brush_patch(12, 3, 16, 9)

	add_interact(Vector2i(9, 21), { "type": "sign", "text": "FROSTVALE REACH - ice crowns ancient stone. HALLOWRAITH waits where the cold bites deepest." })

	add_trainer(Vector2i(5, 14), "right", {
		"id": "frost_rime", "name": "Rime Warden", "look": 13,
		"party": [{ "id": "frostfin", "level": 52 }, { "id": "glacielle", "level": 54 }, { "id": "glacierra", "level": 55 }],
		"reward": 11,
		"intro": ["The frost remembers every footfall.", "Leave your warmth here!"],
		"win_line": "Thawed. Climb if you dare.",
	}, 4)
	add_trainer(Vector2i(14, 9), "left", {
		"id": "frost_shard", "name": "Shard Pilgrim", "look": 8,
		"party": [{ "id": "shardling", "level": 53 }, { "id": "graniteor", "level": 55 }, { "id": "obsidraith", "level": 56 }],
		"reward": 11,
		"intro": ["Stone and snow share a vow.", "Break it if you can!"],
		"win_line": "The vow bends to you.",
	}, 5)
	add_trainer(Vector2i(6, 6), "down", {
		"id": "frost_veil", "name": "Veil Cryomancer", "look": 18,
		"party": [{ "id": "shadelet", "level": 54 }, { "id": "hexling", "level": 55 }, { "id": "wraithorn", "level": 57 }],
		"reward": 12,
		"intro": ["Shadows freeze thicker here.", "Show me fire that survives!"],
		"win_line": "Your heat remains. Pass.",
	}, 4)
	add_trainer(Vector2i(15, 18), "up", {
		"id": "frost_aval", "name": "Avalanche Scout", "look": 5,
		"party": [{ "id": "snowmelt", "level": 53 }, { "id": "avalanther", "level": 56 }, { "id": "golemith", "level": 58 }],
		"reward": 12,
		"intro": ["One wrong step buries a keeper.", "Prove you belong on this ridge!"],
		"win_line": "Stable footing. North waits.",
	}, 5)
	add_legend_encounter(Vector2i(9, 5), "hallowraith", 65,
		"Frost peels from a standing tomb. HALLOWRAITH — hollow saint of rime — turns its lantern on you!")

	add_heal_station(Vector2i(12, 20), Vector2i(12, 19), "down")


func _place_pickups() -> void:
	add_pickup(Vector2i(3, 18), "ultra_capsule", 3)
	add_pickup(Vector2i(16, 4), "max_salve", 2)
	add_pickup(Vector2i(4, 7), "super_salve", 3)
	add_pickup(Vector2i(17, 15), "ultra_capsule", 2)


func _brush_patch(x0: int, y0: int, x1: int, y1: int) -> void:
	for x in range(x0, x1 + 1):
		for y in range(y0, y1 + 1):
			if not is_blocked(Vector2i(x, y)) and not warps.has(Vector2i(x, y)):
				place_tall_grass(Vector2i(x, y), Tiles.DESERT_BRUSH)
