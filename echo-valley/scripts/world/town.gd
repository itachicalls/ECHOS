extends "res://scripts/world/overworld.gd"


func _ready() -> void:
	super()
	_maybe_intro.call_deferred()


func _maybe_intro() -> void:
	if not bool(GameState.flags.get("intro_seen", false)):
		GameState.flags["intro_seen"] = true
		EventBus.dialogue_requested.emit(StoryService.intro_lines)
		SaveService.save_game()


func _place_pickups() -> void:
	add_pickup(Vector2i(6, 13), "echo_capsule", 1)
	add_pickup(Vector2i(21, 16), "heart_salve", 1)
	add_pickup(Vector2i(3, 8), "great_capsule", 1)


func _build_map() -> void:
	map_w = 26
	map_h = 20
	default_spawn = Vector2i(12, 16)

	fill_ground(0, 0, map_w - 1, map_h - 1, Tiles.GRASS)

	# tree-lined border: north->Route1, west->coast, south->Ashpeak (post-game)
	for x in map_w:
		if x != 12 and x != 13:
			place_tree(Vector2i(x, 0), Tiles.TREE_GREEN_COL)
		if x != 12 and x != 13:
			place_tree(Vector2i(x, map_h - 1), Tiles.TREE_GREEN_COL)
	for y in range(1, map_h - 1):
		if y != 14 and y != 15:
			place_tree(Vector2i(0, y), Tiles.TREE_GREEN_COL)
		place_tree(Vector2i(map_w - 1, y), Tiles.TREE_GREEN_COL)

	# north path -> Route 1
	for y in range(0, 16):
		set_ground(Vector2i(12, y), Tiles.PATH)
		set_ground(Vector2i(13, y), Tiles.PATH)
	add_warp(Vector2i(12, 0), "route1", Vector2i(9, 22), "up")
	add_warp(Vector2i(13, 0), "route1", Vector2i(10, 22), "up")

	# south path -> Ashpeak (post-game, after fate choice)
	for y in range(16, 20):
		set_ground(Vector2i(12, y), Tiles.PATH)
		set_ground(Vector2i(13, y), Tiles.PATH)
	# open south border for post-game caldera
	for x in [12, 13]:
		# clear blocking trees on south gate if present
		pass
	add_warp(Vector2i(12, 19), "ashpeak1", Vector2i(9, 22), "down",
		["story_complete"],
		"Ashpeak Caldera still sleeps. Face PRIMORDIUS and choose the valley's fate first.")
	add_warp(Vector2i(13, 19), "ashpeak1", Vector2i(10, 22), "down",
		["story_complete"],
		"Ashpeak Caldera still sleeps. Face PRIMORDIUS and choose the valley's fate first.")
	add_interact(Vector2i(11, 18), { "type": "sign", "text": "ASHPEAK TRAIL - opens after you decide the valley's fate at the Hollow Barrows." })

	# main east-west path (extended west to the coast gate)
	for x in range(0, 23):
		set_ground(Vector2i(x, 15), Tiles.PATH)
	for x in range(0, 4):
		set_ground(Vector2i(x, 14), Tiles.PATH)

	# West coast gate — sealed until Champion or Rival Sabo (jungle) is beaten.
	add_warp(Vector2i(0, 14), "beach1", Vector2i(18, 10), "left",
		["trainer_champion", "trainer_j3_rival"],
		"The western trail is still sealed by the Fracture...")
	add_warp(Vector2i(0, 15), "beach1", Vector2i(18, 11), "left",
		["trainer_champion", "trainer_j3_rival"],
		"The western trail is still sealed by the Fracture...")
	add_interact(Vector2i(2, 16), { "type": "sign", "text": "TIDECROSS TRAIL - west to the shore. Opens after Champion Vael (or Rival Sabo in Verdant Route 3)." })

	# discovery doors — off the main west corridor so Tidecross stays clear
	open_passage(Vector2i(2, 12), Tiles.PATH)
	open_passage(Vector2i(3, 12), Tiles.PATH)
	add_warp(Vector2i(2, 12), "windmill_ridge", Vector2i(9, 22), "up",
		["trainer_champion"],
		"Windmill Ridge is quiet until a Champion returns to Harmona Rest.")
	add_warp(Vector2i(3, 12), "windmill_ridge", Vector2i(10, 22), "up",
		["trainer_champion"],
		"Windmill Ridge is quiet until a Champion returns to Harmona Rest.")
	add_interact(Vector2i(4, 12), { "type": "sign", "text": "WINDMILL RIDGE - side trail. Unlocks after Champion Vael." })

	open_passage(Vector2i(20, 8), Tiles.PATH)
	open_passage(Vector2i(21, 8), Tiles.PATH)
	add_warp(Vector2i(20, 8), "abandoned_lab", Vector2i(9, 22), "up",
		["trainer_champion"],
		"The Archive Lab stays sealed until the Champion's title is claimed.")
	add_warp(Vector2i(21, 8), "abandoned_lab", Vector2i(10, 22), "up",
		["trainer_champion"],
		"The Archive Lab stays sealed until the Champion's title is claimed.")
	add_interact(Vector2i(20, 9), { "type": "sign", "text": "ARCHIVE LAB RUINS - east annex. Unlocks after Champion Vael." })

	# cobble plaza in the center
	fill_ground(11, 14, 15, 16, Tiles.STONE)

	# a calm pond, north-west
	for x in range(3, 7):
		for y in range(3, 6):
			set_ground(Vector2i(x, y), Tiles.WATER)
			block(Vector2i(x, y))

	# Echo Rest clinic (top-right): building + nurse out front + cross emblem
	place_house(Vector2i(16, 2))
	for y in range(6, 15):
		set_ground(Vector2i(17, y), Tiles.PATH)
	add_heal_station(Vector2i(17, 6), Vector2i(17, 5), "down")
	add_interact(Vector2i(18, 6), { "type": "sign", "text": "ECHO REST - talk to the nurse to heal your team and save." })

	# player's cottage (lower-left)
	place_house(Vector2i(4, 9))
	set_ground(Vector2i(5, 12), Tiles.PATH)
	set_ground(Vector2i(5, 13), Tiles.PATH)
	set_ground(Vector2i(5, 14), Tiles.PATH)
	add_interact(Vector2i(5, 12), { "type": "sign", "text": "Your cozy cottage. Home sweet home." })

	# starter sign near spawn
	add_interact(Vector2i(11, 16), { "type": "sign", "text": "HARMONA VALLEY - tall grass to the north hides wild Harmons!" })

	# Warden Odalie: your guide. Talk to her (or press M) to review objectives.
	add_npc(Vector2i(13, 15), "left", Color(1, 1, 1), {
		"type": "guide",
		"greeting": "Ah, our new keeper! Here's what lies ahead:",
	}, Tiles.NURSE)
	add_interact(Vector2i(13, 16), { "type": "sign", "text": "TIP: Press M to open your menu - check your Party, Bag, and Journal." })

	# roaming villagers with world-building chatter
	add_npc(Vector2i(9, 11), "down", Color(1, 1, 1), {
		"type": "npc",
		"lines": [
			"Long ago The Chorus linked every creature to the land.",
			"The Fracture shattered that bond — but Harmons still carry its memories.",
			"Beat trainers, then talk to them again — they share path rumors.",
			"After the Champion, go WEST for Tidecross. After Primordius, go SOUTH for Ashpeak.",
		],
	}, Tiles.TRAINER_PATHS[3], 2)
	add_npc(Vector2i(20, 13), "left", Color(1, 1, 1), {
		"type": "npc",
		"lines": [
			"Careful north of here - trainers on Route 1 will challenge you the moment they spot you!",
			"Meet their eyes and there's no backing out. That's Keeper's honor.",
		],
	}, Tiles.TRAINER_PATHS[5], 3)
	add_npc(Vector2i(7, 17), "up", Color(1, 1, 1), {
		"type": "npc",
		"lines": [
			"My Echo evolved after our hundredth battle together!",
			"Keep yours close and it'll grow stronger - and change shape.",
		],
	}, Tiles.TRAINER_PATHS[2], 2)
	add_interact(Vector2i(15, 6), { "type": "sign", "text": "ECHO REST CLINIC - free healing for wandering keepers. Rest here, then venture out!" })

	# Side quests
	add_npc(Vector2i(6, 12), "down", Color(1, 1, 1), {
		"type": "quest", "quest_id": "q_cottage_herbs",
	}, Tiles.TRAINER_PATHS[8])
	add_npc(Vector2i(4, 7), "right", Color(1, 1, 1), {
		"type": "quest", "quest_id": "q_pond_favor",
	}, Tiles.TRAINER_PATHS[1])

	# Market stall — trade capsules for a care bundle (once).
	add_npc(Vector2i(15, 14), "left", Color(1, 1, 1), {
		"type": "shop",
		"shop_id": "town_market",
		"cost": 4,
		"give": { "great_capsule": 2, "heart_salve": 2, "repel_charm": 1 },
		"lines": [
			"Harmona Market! Four Echo Capsules gets you a starter care bundle.",
			"Great Capsules, salves, and a Repel Charm. Deal?",
		],
		"sold_out": ["Stock's gone for now — restock after your next big trip!"],
	}, Tiles.TRAINER_PATHS[7])

	# decorative flowers, bushes, mushrooms
	for p in [Vector2i(9, 8), Vector2i(10, 8), Vector2i(21, 11), Vector2i(20, 12), Vector2i(8, 17), Vector2i(20, 17)]:
		set_ground(p, Tiles.FLOWERS)
	for p in [Vector2i(8, 3), Vector2i(21, 5), Vector2i(9, 12), Vector2i(22, 8)]:
		place_bush(p)
	for p in [Vector2i(7, 7), Vector2i(22, 14)]:
		set_decor(p, Tiles.MUSHROOM)
