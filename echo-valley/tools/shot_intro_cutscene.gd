extends SceneTree
## Capture intro cutscene slides for visual verification.

const OUT := "user://shot_intro_%s.png"


func _init() -> void:
	call_deferred("_run")


func _find(node: Node, suffix: String) -> Node:
	for child in node.get_children():
		if child.get_script() and String(child.get_script().resource_path).ends_with(suffix):
			return child
		var found := _find(child, suffix)
		if found:
			return found
	return null


func _run() -> void:
	var scene := load("res://scenes/boot/intro_cutscene.tscn")
	if scene == null:
		push_error("intro_cutscene.tscn missing")
		quit(1)
		return

	var visuals := ["chorus", "fracture", "harmons", "disturbance", "veil", "journey", "town", "bond", "depart"]
	for visual in visuals:
		var cut: Node = scene.instantiate()
		cut.sequence_id = "opening"
		cut.starter_id = "emberkit"
		root.add_child(cut)
		# Let the scene's own _run finish its intro fade + first slide build,
		# then override the visual so each screenshot shows a distinct scene.
		await create_timer(1.1).timeout
		var stage := _find(cut, "intro_cutscene_stage.gd")
		var backdrop := _find(cut, "intro_cutscene_backdrop.gd")
		if backdrop and backdrop.has_method("set_visual"):
			backdrop.call("set_visual", visual)
		if stage and stage.has_method("build"):
			stage.call("build", visual, "emberkit")
			stage.call("animate", 1.2)
		await create_timer(0.6).timeout
		var img: Image = root.get_viewport().get_texture().get_image()
		var path := OUT % visual
		img.save_png(path)
		print("SHOT ", ProjectSettings.globalize_path(path))
		cut.queue_free()
		await process_frame

	print("INTRO SHOTS DONE")
	quit()
