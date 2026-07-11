class_name EchoDatabase
extends RefCounted

## Shared content database. Autoload EchoCatalog owns the live instance.
static var instance: EchoDatabase

var echoes: Dictionary = {}
var chimes: Dictionary = {}


func has_echo(id: String) -> bool:
	return echoes.has(id)


func get_echo(id: String) -> EchoDefinition:
	return echoes.get(id) as EchoDefinition


func get_chime(id: String) -> ChimeDefinition:
	return chimes.get(id) as ChimeDefinition


func all_echo_ids() -> Array[String]:
	var ids: Array[String] = []
	for key in echoes.keys():
		ids.append(String(key))
	ids.sort()
	return ids


func create_instance(definition_id: String, level: int = 5) -> EchoInstance:
	if not has_echo(definition_id):
		push_error("Unknown echo definition: %s" % definition_id)
		return null
	return EchoInstance.new(definition_id, level)


func load_from_res() -> void:
	chimes.clear()
	echoes.clear()
	_load_chimes("res://data/chimes")
	_load_echoes("res://data/echoes")


func _load_chimes(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_error("Missing chimes folder: %s" % path)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var data: Variant = _read_json("%s/%s" % [path, file_name])
			if typeof(data) == TYPE_ARRAY:
				for entry: Variant in data:
					var chime: ChimeDefinition = ChimeDefinition.from_dict(entry as Dictionary)
					chimes[chime.id] = chime
			elif typeof(data) == TYPE_DICTIONARY:
				var chime: ChimeDefinition = ChimeDefinition.from_dict(data as Dictionary)
				chimes[chime.id] = chime
		file_name = dir.get_next()
	dir.list_dir_end()


func _load_echoes(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_error("Missing echoes folder: %s" % path)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var data: Variant = _read_json("%s/%s" % [path, file_name])
			if typeof(data) == TYPE_ARRAY:
				for entry: Variant in data:
					var echo: EchoDefinition = EchoDefinition.from_dict(entry as Dictionary)
					echoes[echo.id] = echo
			elif typeof(data) == TYPE_DICTIONARY:
				var echo: EchoDefinition = EchoDefinition.from_dict(data as Dictionary)
				echoes[echo.id] = echo
		file_name = dir.get_next()
	dir.list_dir_end()


func _read_json(path: String) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to read %s" % path)
		return null
	var text := file.get_as_text()
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null:
		push_error("Invalid JSON: %s" % path)
	return parsed
