extends Node

## Lightweight linear story tracker. Stages complete when their GameState flag is set.

signal stage_advanced(stage: Dictionary)

var intro_lines: Array = []
var stages: Array = []


func _ready() -> void:
	_load()


func _load() -> void:
	var f := FileAccess.open("res://data/story.json", FileAccess.READ)
	if f == null:
		return
	var data: Variant = JSON.parse_string(f.get_as_text())
	if typeof(data) == TYPE_DICTIONARY:
		intro_lines = data.get("intro", [])
		stages = data.get("stages", [])


func _stage_done(stage: Dictionary) -> bool:
	var flag := String(stage.get("flag", ""))
	if flag == "__complete__":
		return false
	return bool(GameState.flags.get(flag, false))


## Index of the first incomplete stage (clamped to last).
func current_index() -> int:
	for i in stages.size():
		if not _stage_done(stages[i]):
			return i
	return maxi(0, stages.size() - 1)


func current_stage() -> Dictionary:
	if stages.is_empty():
		return {}
	return stages[current_index()]


func completed_count() -> int:
	var n := 0
	for s in stages:
		if _stage_done(s):
			n += 1
	return n


## Call after events that may complete a stage. Emits a toast + signal on advance.
func notify_progress() -> void:
	var idx := current_index()
	var last := int(GameState.flags.get("story_index", 0))
	if idx > last:
		GameState.flags["story_index"] = idx
		var stage: Dictionary = stages[idx]
		EventBus.toast.emit("New objective: %s" % String(stage.get("title", "")))
		stage_advanced.emit(stage)
