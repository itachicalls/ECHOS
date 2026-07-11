extends Node

const SAVE_VERSION := 1
const SAVE_PATH := "user://echo_valley_save.json"


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game(silent: bool = false) -> bool:
	var payload := {
		"save_version": SAVE_VERSION,
		"timestamp": Time.get_datetime_string_from_system(),
		"state": GameState.to_dict(),
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		if not silent:
			EventBus.toast.emit("Save failed.")
		return false
	f.store_string(JSON.stringify(payload, "\t"))
	if not silent:
		EventBus.toast.emit("Game saved.")
	return true


func load_game() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	GameState.from_dict(parsed.get("state", {}))
	return true


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)
