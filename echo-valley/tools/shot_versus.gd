extends SceneTree

## Capture the versus mode-select showdown screen for a visual check.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	await process_frame
	var packed: PackedScene = load("res://scenes/boot/versus_setup.tscn")
	var inst: Node = packed.instantiate()
	root.add_child(inst)
	# Let the arena animate to a mid-clash frame.
	for i in 130:
		await process_frame
	var img := root.get_texture().get_image()
	var out := ProjectSettings.globalize_path("user://shot_versus_mode.png")
	img.save_png(out)
	print("SHOT ", out)
	inst.queue_free()
	await process_frame
	print("SHOTS DONE")
	quit(0)
