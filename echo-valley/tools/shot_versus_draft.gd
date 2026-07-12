extends SceneTree

## Capture the versus draft team-select screen.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	await process_frame
	var packed: PackedScene = load("res://scenes/boot/versus_setup.tscn")
	var inst: Node = packed.instantiate()
	root.add_child(inst)
	await process_frame
	if inst.has_method("_go_cpu"):
		inst.call("_go_cpu")
	await process_frame
	await process_frame
	var sel: Array = inst.get("_selected")
	sel.clear()
	sel.append("emberkit")
	sel.append("tideling")
	inst.call("_rebuild")
	for i in 40:
		await process_frame
	var img := root.get_texture().get_image()
	var out := ProjectSettings.globalize_path("user://shot_versus_draft.png")
	img.save_png(out)
	print("SHOT ", out)
	inst.queue_free()
	await process_frame
	print("SHOTS DONE")
	quit(0)
