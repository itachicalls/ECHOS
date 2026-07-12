extends "res://scripts/world/overworld.gd"

## THE DREAM REACH (Psychic Route) — a shifting causeway where mind-attuned Harmons
## drift. The seer-legend Aeonmind meditates at its heart, and a Dream Ranger seals
## the way to the Hollow Barrows.


func _build_map() -> void:
	map_w = 20
	map_h = 24
	default_spawn = Vector2i(9, 22)
	encounter_table = "psychic1"

	fill_ground(0, 0, map_w - 1, map_h - 1, Tiles.GRASS2)

	# tree border, south + north gaps
	for x in map_w:
		if x != 9 and x != 10:
			place_tree(Vector2i(x, 0), Tiles.TREE_GREEN_COL)
			place_tree(Vector2i(x, map_h - 1), Tiles.TREE_GREEN_COL)
	for y in range(1, map_h - 1):
		place_tree(Vector2i(0, y), Tiles.TREE_GREEN_COL)
		place_tree(Vector2i(map_w - 1, y), Tiles.TREE_GREEN_COL)

	# meandering stone causeway
	for y in range(0, map_h):
		set_ground(Vector2i(9, y), Tiles.STONE)
		set_ground(Vector2i(10, y), Tiles.STONE)
	for x in range(3, 17):
		set_ground(Vector2i(x, 8), Tiles.STONE)
		set_ground(Vector2i(x, 16), Tiles.STONE)

	add_warp(Vector2i(9, 23), "psychic_town", Vector2i(9, 1), "down")
	add_warp(Vector2i(10, 23), "psychic_town", Vector2i(10, 1), "down")
	add_warp(Vector2i(9, 0), "graveyard1", Vector2i(9, 22), "up")
	add_warp(Vector2i(10, 0), "graveyard1", Vector2i(10, 22), "up")

	# floating standing stones
	for p in [Vector2i(4, 5), Vector2i(15, 6), Vector2i(5, 19), Vector2i(14, 18), Vector2i(3, 12)]:
		add_ground_prop(Tiles.CRYSTAL, p, true)

	# dream-grass encounters
	_grass_patch(2, 9, 7, 15)
	_grass_patch(12, 9, 17, 15)
	_grass_patch(3, 17, 8, 21)
	_grass_patch(12, 3, 16, 7)

	# the meditating legend — a static, catchable encounter until claimed
	add_legend_encounter(Vector2i(9, 12), "aeonmind", 34,
		"At the causeway's heart, Aeonmind hovers in silent meditation. Its gaze snaps open - the air folds. It tests your resolve!")

	add_interact(Vector2i(9, 21), { "type": "sign", "text": "THE DREAM REACH - thought bends here. Mind-Harmons drift through the mist." })
	add_interact(Vector2i(11, 12), { "type": "sign", "text": "A sleeping presence hums at the causeway's center. Approach only if your team is ready." })

	add_trainer(Vector2i(6, 11), "right", {
		"id": "psy_esra", "name": "Dreamer Esra", "look": 12,
		"party": [{ "id": "psybud", "level": 27 }, { "id": "dreamlet", "level": 28 }],
		"reward": 5,
		"intro": ["I walk the space between waking and sleep.", "Let us see which of us is the dream!"],
		"win_line": "You are more real than I. Well dreamt.",
	})
	add_trainer(Vector2i(14, 14), "left", {
		"id": "psy_orin", "name": "Seer Orin", "look": 18,
		"party": [{ "id": "runelet", "level": 28 }, { "id": "orbitot", "level": 29 }],
		"reward": 5,
		"intro": ["The stones foretold your coming, keeper.", "But prophecy means nothing without proof!"],
		"win_line": "The vision was true. You burn bright.",
	}, 5)

	# DREAM GYM — seals the way to the Hollow Barrows.
	add_interact(Vector2i(11, 1), { "type": "sign", "text": "DREAM TRIAL - Ranger Sable guards the Hollow Barrows. Earn the Mind Sigil to pass." })
	add_gym_gate({
		"id": "gym_psychic", "name": "Ranger Sable", "look": 18,
		"party": [{ "id": "mesmind", "level": 30 }, { "id": "sigilix", "level": 31 }, { "id": "hypnaura", "level": 33 }],
		"reward": 6,
		"reward_items": { "heart_salve": 4 },
		"gym": true, "ranger": true,
		"intro": ["I am Sable, keeper of the Reach.", "Beyond lies death's quiet garden. Only a settled mind may enter. Show me yours!"],
		"win_line": "Your mind holds steady. The Barrows will not break you... I hope.",
	}, Vector2i(9, 1), "down", [Vector2i(9, 0), Vector2i(10, 0)], Vector2i(7, 1), [Vector2i(10, 1)])


func _place_pickups() -> void:
	add_pickup(Vector2i(4, 18), "echo_capsule", 4)
	add_pickup(Vector2i(16, 10), "heart_salve", 3)


func _grass_patch(x0: int, y0: int, x1: int, y1: int) -> void:
	for x in range(x0, x1 + 1):
		for y in range(y0, y1 + 1):
			if not is_blocked(Vector2i(x, y)) and not warps.has(Vector2i(x, y)):
				place_tall_grass(Vector2i(x, y))
