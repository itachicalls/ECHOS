extends "res://scripts/world/overworld.gd"

## SALTWIND COVE — a breezy coastal town: a clinic, dock chatter, and the trail
## north into the storm-lashed Voltmarsh.


func _build_map() -> void:
	map_w = 20
	map_h = 24
	default_spawn = Vector2i(9, 21)

	fill_ground(0, 0, map_w - 1, map_h - 1, Tiles.SAND)

	# harbor water along the east edge
	for x in range(15, map_w):
		for y in range(2, 12):
			set_ground(Vector2i(x, y), Tiles.WATER)
			block(Vector2i(x, y))

	# tree/palm border with north + south gates
	for x in map_w:
		if x != 9 and x != 10:
			add_ground_prop(Tiles.PALM, Vector2i(x, 0), true)
			add_ground_prop(Tiles.PALM, Vector2i(x, map_h - 1), true)

	# cobble plaza + paths
	for y in range(0, map_h):
		set_ground(Vector2i(9, y), Tiles.SAND_PATH)
		set_ground(Vector2i(10, y), Tiles.SAND_PATH)
	fill_ground(8, 11, 11, 13, Tiles.STONE)
	for x in range(3, 16):
		set_ground(Vector2i(x, 12), Tiles.SAND_PATH)

	add_warp(Vector2i(9, 23), "beach1", Vector2i(9, 1), "down")
	add_warp(Vector2i(10, 23), "beach1", Vector2i(10, 1), "down")
	add_warp(Vector2i(9, 0), "storm1", Vector2i(9, 22), "up")
	add_warp(Vector2i(10, 0), "storm1", Vector2i(10, 22), "up")

	# clinic
	place_house(Vector2i(3, 4))
	for y in range(7, 13):
		set_ground(Vector2i(4, y), Tiles.SAND_PATH)
	add_heal_station(Vector2i(4, 7), Vector2i(4, 6), "down")
	add_interact(Vector2i(5, 7), { "type": "sign", "text": "COVE CLINIC - heal your team and save before heading into the marsh." })

	# guide + flavor NPCs
	add_npc(Vector2i(10, 12), "left", Color(1, 1, 1), {
		"type": "guide",
		"greeting": "Storm-chasers, huh? Here's what the coast whispers:",
	}, Tiles.NURSE)
	add_npc(Vector2i(12, 10), "left", Color(1, 1, 1), {
		"type": "npc",
		"lines": [
			"North of here the sky never stops crackling - the Voltmarsh.",
			"They say the Fracture struck hardest along this coast. New Harmons keep surfacing.",
		],
	}, Tiles.TRAINER_PATHS[10], 2)
	add_npc(Vector2i(6, 15), "up", Color(1, 1, 1), {
		"type": "npc",
		"lines": [
			"A hooded trio's been asking about keepers who carry too much resonance.",
			"If they corner you in the marsh... stand your ground.",
		],
	}, Tiles.TRAINER_PATHS[18], 2)
	add_interact(Vector2i(9, 20), { "type": "sign", "text": "SALTWIND COVE - last safe rest before the Voltmarsh. Stock up!" })

	for p in [Vector2i(6, 9), Vector2i(13, 15), Vector2i(5, 17)]:
		set_ground(p, Tiles.FLOWERS)


func _place_pickups() -> void:
	add_pickup(Vector2i(12, 15), "echo_capsule", 3)
