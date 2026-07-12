extends "res://scripts/world/overworld.gd"

## MIRAGE HOLLOW — a hushed psychic town of standing stones and dreamers. A clinic,
## cryptic seers, and the causeway north into the Dream Reach.


func _build_map() -> void:
	map_w = 20
	map_h = 24
	default_spawn = Vector2i(9, 21)

	fill_ground(0, 0, map_w - 1, map_h - 1, Tiles.GRASS2)

	# stone border with north + south gates
	for x in map_w:
		if x != 9 and x != 10:
			place_tree(Vector2i(x, 0), Tiles.TREE_GREEN_COL)
			place_tree(Vector2i(x, map_h - 1), Tiles.TREE_GREEN_COL)
	for y in range(1, map_h - 1):
		place_tree(Vector2i(0, y), Tiles.TREE_GREEN_COL)
		place_tree(Vector2i(map_w - 1, y), Tiles.TREE_GREEN_COL)

	# central cobbled ring + paths
	for y in range(0, map_h):
		set_ground(Vector2i(9, y), Tiles.STONE)
		set_ground(Vector2i(10, y), Tiles.STONE)
	fill_ground(7, 10, 12, 14, Tiles.STONE)
	for x in range(3, 17):
		set_ground(Vector2i(x, 12), Tiles.STONE)

	add_warp(Vector2i(9, 23), "storm1", Vector2i(9, 1), "down")
	add_warp(Vector2i(10, 23), "storm1", Vector2i(10, 1), "down")
	add_warp(Vector2i(9, 0), "psychic1", Vector2i(9, 22), "up")
	add_warp(Vector2i(10, 0), "psychic1", Vector2i(10, 22), "up")

	# ring of crystal standing-stones around the plaza
	for p in [Vector2i(7, 9), Vector2i(12, 9), Vector2i(6, 12), Vector2i(13, 12), Vector2i(7, 15), Vector2i(12, 15)]:
		add_ground_prop(Tiles.CRYSTAL, p, true)

	# clinic
	place_house(Vector2i(3, 4))
	for y in range(7, 13):
		set_ground(Vector2i(4, y), Tiles.STONE)
	add_heal_station(Vector2i(4, 7), Vector2i(4, 6), "down")
	add_interact(Vector2i(5, 7), { "type": "sign", "text": "HOLLOW SANCTUM - rest, save, and clear your mind before the Dream Reach." })

	add_npc(Vector2i(10, 13), "left", Color(1, 1, 1), {
		"type": "guide",
		"greeting": "The stones told me you'd come. Your path ahead:",
	}, Tiles.NURSE)
	add_npc(Vector2i(13, 8), "left", Color(1, 1, 1), {
		"type": "npc",
		"lines": [
			"The Reach north bends thought and memory. Trust your Harmons, not your eyes.",
			"Some keepers glimpse a mind older than the Chorus itself sleeping there.",
		],
	}, Tiles.TRAINER_PATHS[12], 2)
	add_npc(Vector2i(6, 16), "up", Color(1, 1, 1), {
		"type": "npc",
		"lines": [
			"Beyond the Reach lie the Hollow Barrows - a graveyard where the Fracture never healed.",
			"They say a Primordial dreams beneath the tombs. I'd not wake it lightly.",
		],
	}, Tiles.TRAINER_PATHS[18], 2)
	add_interact(Vector2i(9, 20), { "type": "sign", "text": "MIRAGE HOLLOW - where dreamers gather. North: the Dream Reach." })

	for p in [Vector2i(6, 8), Vector2i(14, 15), Vector2i(5, 17)]:
		set_ground(p, Tiles.FLOWERS)


func _place_pickups() -> void:
	add_pickup(Vector2i(13, 16), "heart_salve", 3)
