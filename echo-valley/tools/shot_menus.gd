extends Node

## Captures battle menus + versus draft for layout QA.

func _ready() -> void:
	GameState.party.clear()
	GameState.party.append(EchoCatalog.create_instance("emberkit", 12))
	GameState.party.append(EchoCatalog.create_instance("pebblit", 11))
	GameState.party.append(EchoCatalog.create_instance("aquari", 11))
	GameState.party.append(EchoCatalog.create_instance("wispurr", 12))
	SceneRouter._battle_request = {
		"kind": "wild", "enemies": [EchoCatalog.create_instance("mossling", 9)],
		"return_map": "route1", "can_flee": true, "can_catch": true,
	}
	await _snap_battle("main", func(b): b._open_main_menu(), false)
	await _snap_battle("switch", func(b): b._on_switch_menu(), false)
	await _snap_battle("fight", func(b): b._on_fight(), false)
	await _snap_battle("fight_hover", func(b): b._on_fight(), true)
	await _snap_versus()
	print("SHOTS DONE")
	get_tree().quit(0)


func _snap_battle(name: String, setup: Callable, hover: bool) -> void:
	var packed: PackedScene = load("res://scenes/battle/battle.tscn")
	var inst = packed.instantiate()
	add_child(inst)
	for i in 30:
		await get_tree().process_frame
	inst.phase = inst.Phase.CHOOSING
	inst.menu_root.visible = true
	inst.msg.visible = true
	inst.msg.text = "What will you do?"
	setup.call(inst)
	await get_tree().create_timer(0.15).timeout
	if hover:
		# Move the mouse over the first menu button to trigger its hover state.
		var btn := _first_button(inst.menu_root)
		if btn:
			var c := btn.get_global_rect().position + btn.size * 0.5
			get_viewport().warp_mouse(c)
			var ev := InputEventMouseMotion.new()
			ev.position = c
			ev.global_position = c
			get_viewport().push_input(ev)
			await get_tree().create_timer(0.15).timeout
	var img := get_viewport().get_texture().get_image()
	img.save_png("user://shot_battle_%s.png" % name)
	print("SHOT ", ProjectSettings.globalize_path("user://shot_battle_%s.png" % name))
	inst.queue_free()
	await get_tree().process_frame


func _first_button(node: Node) -> Button:
	for c in node.get_children():
		if c is Button:
			return c
		var found := _first_button(c)
		if found:
			return found
	return null


func _snap_versus() -> void:
	var packed: PackedScene = load("res://scenes/boot/versus_setup.tscn")
	var inst = packed.instantiate()
	add_child(inst)
	for i in 40:
		await get_tree().process_frame
	# force draft screen
	inst._screen = inst.Screen.CPU
	inst._rebuild()
	for i in 40:
		await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png("user://shot_versus_draft.png")
	print("SHOT ", ProjectSettings.globalize_path("user://shot_versus_draft.png"))
	inst.queue_free()
