extends Node

## Captures the versus DRAFT screen (echo select grid) and the ONLINE screen.

func _ready() -> void:
	await _run()

func _run() -> void:
	var vp := get_viewport()
	var packed: PackedScene = load("res://scenes/boot/versus_setup.tscn")

	# --- mode select ---
	var inst0: Node = packed.instantiate()
	add_child(inst0)
	for i in 12:
		await get_tree().process_frame
	vp.get_texture().get_image().save_png("user://shot_mode.png")
	print("SHOT ", ProjectSettings.globalize_path("user://shot_mode.png"))
	inst0.queue_free()
	await get_tree().process_frame

	# --- CPU draft (echo select grid) ---
	var inst: Node = packed.instantiate()
	add_child(inst)
	await get_tree().process_frame
	inst._screen = inst.Screen.CPU
	inst._rebuild()
	# pre-select a couple echoes to show selected state
	for i in 30:
		await get_tree().process_frame
	var img := vp.get_texture().get_image()
	img.save_png("user://shot_draft.png")
	print("SHOT ", ProjectSettings.globalize_path("user://shot_draft.png"))
	inst.queue_free()
	await get_tree().process_frame

	# --- Online lobby screen ---
	var inst2: Node = packed.instantiate()
	add_child(inst2)
	await get_tree().process_frame
	inst2._screen = inst2.Screen.ONLINE
	inst2._rebuild()
	for i in 20:
		await get_tree().process_frame
	var img2 := vp.get_texture().get_image()
	img2.save_png("user://shot_online.png")
	print("SHOT ", ProjectSettings.globalize_path("user://shot_online.png"))
	inst2.queue_free()
	await get_tree().process_frame

	print("SHOTS DONE")
	get_tree().quit(0)
