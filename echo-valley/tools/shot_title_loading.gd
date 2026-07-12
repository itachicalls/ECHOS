extends SceneTree

## Capture title + loading screens for visual check.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	await process_frame
	for spec in [
		{ "scene": "res://scenes/boot/loading.tscn", "name": "shot_loading.png" },
		{ "scene": "res://scenes/boot/title.tscn", "name": "shot_title.png" },
	]:
		var packed: PackedScene = load(spec.scene)
		var inst: Node = packed.instantiate()
		if inst.has_method("set") and inst.get("hold_on_complete") != null:
			inst.set("hold_on_complete", true)
		root.add_child(inst)
		for i in 50:
			await process_frame
		var img := root.get_texture().get_image()
		var out := ProjectSettings.globalize_path("user://%s" % spec.name)
		img.save_png(out)
		print("SHOT ", out)
		inst.queue_free()
		await process_frame
	print("SHOTS DONE")
	quit(0)
