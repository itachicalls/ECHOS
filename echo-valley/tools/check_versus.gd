extends Node

## Headless smoke test: instantiate versus_setup and build each screen
## (MODE, CPU, ONLINE, DRAFT) to catch runtime/layout errors. Writes result.

func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var log: PackedStringArray = PackedStringArray()
	var packed: PackedScene = load("res://scenes/boot/versus_setup.tscn")
	if packed == null:
		_finish(["FAIL: could not load versus_setup.tscn"], 1)
		return
	var inst: Node = packed.instantiate()
	add_child(inst)
	await get_tree().process_frame
	await get_tree().process_frame
	log.append("OK build MODE children=%d" % inst.get_child_count())

	for scr in ["CPU", "ONLINE", "DRAFT"]:
		inst._screen = inst.Screen[scr]
		inst._rebuild()
		await get_tree().process_frame
		await get_tree().process_frame
		log.append("OK build %s" % scr)

	# sanity: online screen wired the code field + host/join refs
	inst._screen = inst.Screen.ONLINE
	inst._rebuild()
	await get_tree().process_frame
	if inst._code_in == null:
		log.append("WARN: _code_in null on ONLINE")
	if inst._code_lbl == null:
		log.append("WARN: _code_lbl null on ONLINE")
	log.append("VERSUS UI OK")
	_finish(log, 0)


func _finish(lines: PackedStringArray, code: int) -> void:
	for l in lines:
		print(l)
	var f := FileAccess.open("res://_versuscheck.txt", FileAccess.WRITE)
	if f:
		f.store_string("\n".join(lines) + "\n")
		f.close()
	get_tree().quit(code)
