extends Node

const SAVE_VERSION := 1
const SAVE_PATH := "user://saves/slot_1.json"


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> bool:
	var payload := {
		"save_version": SAVE_VERSION,
		"timestamp": Time.get_datetime_string_from_system(),
		"state": GameState.to_dict(),
	}
	DirAccess.make_dir_recursive_absolute("user://saves")
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not write save file.")
		EventBus.toast.emit("Save failed.")
		return false
	file.store_string(JSON.stringify(payload, "\t"))
	EventBus.toast.emit("Game saved.")
	return true


func load_game() -> bool:
	if not has_save():
		EventBus.toast.emit("No save found.")
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		EventBus.toast.emit("Could not read save.")
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		EventBus.toast.emit("Save file corrupted.")
		return false
	var version := int(parsed.get("save_version", 0))
	if version > SAVE_VERSION:
		EventBus.toast.emit("Save is from a newer version.")
		return false
	# Future: migrate older versions here.
	GameState.from_dict(parsed.get("state", {}))
	EventBus.toast.emit("Game loaded.")
	return true


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)
