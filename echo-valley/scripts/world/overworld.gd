extends Node2D

## Base overworld: builds the tileset + layers, tracks collision/grass/warps,
## spawns the player, and drives encounters. Subclass and override _build_map().

const TILE := 16
const PlayerScene = preload("res://scenes/player/player.tscn")
const HudScene = preload("res://scenes/ui/hud.tscn")
const PauseMenuScript = preload("res://scripts/ui/pause_menu.gd")
const NpcScript = preload("res://scripts/world/npc.gd")

const STEP_DIRS := {
	"up": Vector2i(0, -1),
	"down": Vector2i(0, 1),
	"left": Vector2i(-1, 0),
	"right": Vector2i(1, 0),
}

var ground: TileMapLayer
var decor: TileMapLayer
var _tileset: TileSet
var _sources: Array[int] = []
var _created: Dictionary = {}

var blocked: Dictionary = {}
var grass: Dictionary = {}
var warps: Dictionary = {}
var interacts: Dictionary = {}
var ledges: Dictionary = {}
var hazards: Dictionary = {}
var pickups: Dictionary = {}
var npcs: Array = []
var _path_cells: Dictionary = {}
var _stone_cells: Dictionary = {}

var map_w: int = 20
var map_h: int = 20
var default_spawn: Vector2i = Vector2i(5, 5)
var encounter_table: String = ""

var player: Node2D
var _encounter_data: Dictionary = {}
var _busy: bool = false
var _cutscene: bool = false
var _pending_trainer: Dictionary = {}

const FACING_ROW := { "down": 0, "right": 1, "up": 2, "left": 3 }


func _ready() -> void:
	_setup_tileset()
	ground = _make_layer(0)
	decor = _make_layer(1)
	add_child(ground)
	add_child(decor)
	_build_map()
	_autotile_paths()
	_load_encounters()
	_spawn_player()
	add_child(HudScene.instantiate())
	add_child(PauseMenuScript.new())
	_place_pickups()
	StoryService.notify_progress.call_deferred()


# --- override in subclasses ---
func _build_map() -> void:
	pass


func _place_pickups() -> void:
	pass


# --- objects & hazards ---
func add_ledge(cell: Vector2i) -> void:
	# a south-facing ledge: you can hop DOWN across it, but not walk up onto it
	ledges[cell] = true
	set_decor(cell, Tiles.LEDGE)
	block(cell)


func add_spikes(cell: Vector2i, text: String = "Sharp thorns! Your lead Harmon took a scratch.") -> void:
	add_prop(Tiles.THORNS, cell, false)
	add_hazard(cell, text)


func add_desert_spikes(cell: Vector2i, text: String = "Jagged rocks! Your lead Harmon got nicked.") -> void:
	add_prop(Tiles.SPIKES, cell, false)
	add_hazard(cell, text)


func is_ledge(cell: Vector2i) -> bool:
	return ledges.get(cell, false)


func add_hazard(cell: Vector2i, text: String = "Ouch! The terrain stings!") -> void:
	hazards[cell] = { "text": text }


func add_pickup(cell: Vector2i, item: String, amount: int = 1, sprite_path: String = "") -> void:
	var flag := "pickup_%s_%d_%d" % [name.to_lower(), cell.x, cell.y]
	if bool(GameState.flags.get(flag, false)):
		return
	var path := sprite_path
	if path == "":
		path = Tiles.ECHO_CAPSULE if item == "echo_capsule" else Tiles.ECHO_CAPSULE
	var spr := Sprite2D.new()
	spr.texture = load(path)
	spr.centered = true
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Sit on the tile floor — never use the tall-character -16 offset.
	spr.position = Vector2(cell.x * TILE + 8, cell.y * TILE + 10)
	spr.z_index = 2
	add_child(spr)
	pickups[cell] = { "item": item, "amount": amount, "sprite": spr, "flag": flag }


func _collect_pickup(cell: Vector2i) -> void:
	if not pickups.has(cell) or _busy:
		return
	var p: Dictionary = pickups[cell]
	pickups.erase(cell)
	var spr: Node = p.sprite
	if is_instance_valid(spr):
		spr.queue_free()
	GameState.flags[p.flag] = true
	GameState.inventory[p.item] = int(GameState.inventory.get(p.item, 0)) + int(p.amount)
	var nice := "Heart Salve" if p.item == "heart_salve" else "Echo Capsule"
	EventBus.toast.emit("Found %d %s!" % [int(p.amount), nice])


func _apply_hazard(cell: Vector2i) -> void:
	if not hazards.has(cell):
		return
	var lead: EchoInstance = null
	for e in GameState.party:
		if e and not e.is_fainted():
			lead = e
			break
	if lead == null:
		return
	var dmg := maxi(1, int(round(float(lead.max_hp()) * 0.12)))
	lead.current_hp = maxi(1, lead.current_hp - dmg)
	EventBus.party_changed.emit()
	EventBus.toast.emit(String(hazards[cell].get("text", "Ouch!")))


# --- tile helpers ---
func _setup_tileset() -> void:
	_tileset = TileSet.new()
	_tileset.tile_size = Vector2i(TILE, TILE)
	_sources.clear()
	for entry in Tiles.SHEETS:
		var src := TileSetAtlasSource.new()
		src.texture = load(String(entry.path))
		src.texture_region_size = Vector2i(TILE, TILE)
		src.separation = entry.sep
		_sources.append(_tileset.add_source(src))


func _make_layer(z: int) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.tile_set = _tileset
	layer.z_index = z
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return layer


func _ensure_tile(tile: Vector3i) -> void:
	if _created.has(tile):
		return
	var src := _tileset.get_source(_sources[tile.x]) as TileSetAtlasSource
	src.create_tile(Vector2i(tile.y, tile.z))
	_created[tile] = true


func set_ground(cell: Vector2i, tile: Vector3i) -> void:
	_ensure_tile(tile)
	ground.set_cell(cell, _sources[tile.x], Vector2i(tile.y, tile.z))
	if tile == Tiles.PATH:
		_path_cells[cell] = true
		_stone_cells.erase(cell)
	elif tile == Tiles.STONE:
		_stone_cells[cell] = true
		_path_cells.erase(cell)
	else:
		_path_cells.erase(cell)
		_stone_cells.erase(cell)


func _set_ground_raw(cell: Vector2i, tile: Vector3i) -> void:
	_ensure_tile(tile)
	ground.set_cell(cell, _sources[tile.x], Vector2i(tile.y, tile.z))


## Replace PATH/STONE markers with the correct connected edge/corner tile so
## roads and plazas have crisp grassy borders instead of a flat block.
func _autotile_paths() -> void:
	# paths and plazas connect to each other (no grass seam at junctions)
	var solid: Dictionary = {}
	for c in _path_cells:
		solid[c] = true
	for c in _stone_cells:
		solid[c] = true
	_autotile_set(_path_cells, Tiles.PATH_SOURCE, solid)
	_autotile_set(_stone_cells, Tiles.STONE_SOURCE, solid)


func _autotile_set(cells: Dictionary, source: int, solid: Dictionary) -> void:
	for cell in cells.keys():
		var mask := 0
		if solid.has(cell + Vector2i(0, -1)):
			mask |= 1   # N connected
		if solid.has(cell + Vector2i(1, 0)):
			mask |= 2   # E connected
		if solid.has(cell + Vector2i(0, 1)):
			mask |= 4   # S connected
		if solid.has(cell + Vector2i(-1, 0)):
			mask |= 8   # W connected
		_set_ground_raw(cell, Vector3i(source, mask % 4, mask / 4))


func set_decor(cell: Vector2i, tile: Vector3i) -> void:
	_ensure_tile(tile)
	decor.set_cell(cell, _sources[tile.x], Vector2i(tile.y, tile.z))


func fill_ground(x0: int, y0: int, x1: int, y1: int, tile: Vector3i) -> void:
	for x in range(x0, x1 + 1):
		for y in range(y0, y1 + 1):
			set_ground(Vector2i(x, y), tile)


func block(cell: Vector2i) -> void:
	blocked[cell] = true


func place_bush(cell: Vector2i) -> void:
	set_decor(cell, Tiles.BUSH)
	block(cell)


## A solid cave wall: stone-brick ground tile that blocks movement.
func place_rock(cell: Vector2i) -> void:
	set_ground(cell, Tiles.CAVE_WALL)
	block(cell)


func place_tree(cell: Vector2i, col: int = Tiles.TREE_GREEN_COL) -> void:
	# 16x32 sprite (treetop + trunk) whose base sits on `cell`.
	var spr := Sprite2D.new()
	spr.texture = load(Tiles.TREE_SHEET)
	spr.region_enabled = true
	spr.region_rect = Rect2(col * TILE, 0, TILE, TILE * 2)
	spr.centered = false
	spr.offset = Vector2(0, -TILE)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.position = Vector2(cell.x * TILE, cell.y * TILE)
	spr.z_index = 3
	add_child(spr)
	block(cell)


func place_tall_grass(cell: Vector2i, tile: Vector3i = Tiles.TALL_GRASS) -> void:
	set_ground(cell, tile)
	grass[cell] = true


func place_house(origin: Vector2i) -> void:
	for row in Tiles.HOUSE_H:
		for col in Tiles.HOUSE_W:
			var atlas: Vector2i = Tiles.HOUSE_ROWS[row][col]
			var cell := origin + Vector2i(col, row)
			set_decor(cell, Vector3i(0, atlas.x, atlas.y))
			block(cell)


func add_warp(cell: Vector2i, target_map: String, target_cell: Vector2i, facing: String = "down") -> void:
	warps[cell] = { "map": target_map, "cell": target_cell, "facing": facing }


func add_interact(cell: Vector2i, data: Dictionary) -> void:
	interacts[cell] = data


func add_npc(cell: Vector2i, facing: String, tint: Color, data: Dictionary, texture_path: String = "", roam: int = 0) -> Node2D:
	var npc := NpcScript.new()
	add_child(npc)
	npc.setup(self, cell, facing, data, texture_path, tint)
	if roam > 0:
		npc.kind = "wander"
		npc.wander_radius = roam
	npcs.append(npc)
	return npc


func add_trainer(cell: Vector2i, facing: String, trainer: Dictionary, sight: int = 4) -> Node2D:
	var look: int = int(trainer.get("look", _look_from_id(String(trainer.get("id", "")))))
	look = clampi(look, 0, Tiles.TRAINER_PATHS.size() - 1)
	var npc := add_npc(cell, facing, Color(1, 1, 1), { "type": "trainer", "trainer": trainer }, Tiles.TRAINER_PATHS[look])
	if sight > 0:
		npc.kind = "sentry"
		npc.sight = sight
	return npc


## A gym leader who seals a region exit until defeated. While the leader is
## unbeaten the exit tiles are blocked and the leader stands in the gateway
## (challenging on sight). Once "trainer_<id>" is set, the leader steps aside
## and the path opens. Call AFTER laying down the exit warps.
func add_gym_gate(trainer: Dictionary, leader_cell: Vector2i, facing: String, exit_cells: Array, side_cell: Vector2i, barrier_cells: Array = [], sight: int = 5) -> void:
	var id := String(trainer.get("id", ""))
	var beaten := bool(GameState.flags.get("trainer_" + id, false))
	if beaten:
		add_trainer(side_cell, facing, trainer, 0)
		return
	add_trainer(leader_cell, facing, trainer, sight)
	for c in exit_cells:
		block(c)
	for c in barrier_cells:
		place_bush(c)


func add_prop(sprite_path: String, cell: Vector2i, blocks: bool = false) -> Sprite2D:
	var spr := Sprite2D.new()
	spr.texture = load(sprite_path)
	spr.centered = false
	spr.offset = Vector2(0, -16)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.position = Vector2(cell.x * TILE, cell.y * TILE)
	spr.z_index = 3
	add_child(spr)
	if blocks:
		block(cell)
	return spr


func add_heal_station(nurse_cell: Vector2i, emblem_cell: Vector2i, facing: String = "down") -> Node2D:
	# Echo Rest clinic: a red medical cross emblem above a nurse you talk to.
	var cross := add_prop(Tiles.HEAL_CROSS, emblem_cell, false)
	cross.z_index = 6
	var nurse := add_npc(nurse_cell, facing, Color(1, 1, 1), {
		"type": "heal",
		"npc_sprite": true,
	}, Tiles.NURSE)
	return nurse


func _place_sprite_prop(sheet: String, cell: Vector2i, atlas: Vector2i, w: int, h: int, block_tiles: bool) -> Sprite2D:
	var spr := Sprite2D.new()
	spr.texture = load(sheet)
	spr.region_enabled = true
	spr.region_rect = Rect2(atlas.x * 16, atlas.y * 16, w, h)
	spr.centered = false
	spr.offset = Vector2(0, -16)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.position = Vector2(cell.x * TILE, cell.y * TILE)
	spr.z_index = 3
	add_child(spr)
	if block_tiles:
		block(cell)
	return spr


func _look_from_id(id: String) -> int:
	return absi(id.hash()) % 6


# --- queries used by the player ---
func is_blocked(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= map_w or cell.y >= map_h:
		return true
	if blocked.get(cell, false):
		return true
	for npc in npcs:
		if is_instance_valid(npc) and (npc.cell == cell or npc.target_cell == cell):
			return true
	return false


func is_grass(cell: Vector2i) -> bool:
	return grass.get(cell, false)


func try_interact(cell: Vector2i) -> void:
	if _busy or _cutscene:
		return
	for npc in npcs:
		if is_instance_valid(npc) and npc.cell == cell:
			npc.face_towards(player.cell if player else cell)
			_handle_interact(npc.data)
			return
	if interacts.has(cell):
		_handle_interact(interacts[cell])


# --- line-of-sight trainer marches up and challenges the player ---
func begin_sentry(npc: Node2D) -> void:
	if _cutscene or _busy:
		return
	_cutscene = true
	if player and player.has_method("set_input_locked"):
		player.set_input_locked(true)
	await _sentry_alert(npc)
	await _sentry_walkup(npc)
	if player:
		npc.face_towards(player.cell)
	await get_tree().create_timer(0.15).timeout
	_cutscene = false
	_on_trainer_interact(npc.data.get("trainer", {}))


func _sentry_alert(npc: Node2D) -> void:
	var mark := Label.new()
	mark.text = "!"
	mark.add_theme_font_size_override("font_size", 16)
	mark.add_theme_color_override("font_color", Color("ffd166"))
	mark.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	mark.add_theme_constant_override("outline_size", 3)
	mark.z_index = 20
	mark.position = npc.position + Vector2(3, -30)
	add_child(mark)
	var tw := create_tween()
	tw.tween_property(mark, "position:y", mark.position.y - 6.0, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.4)
	tw.tween_callback(mark.queue_free)
	await get_tree().create_timer(0.6).timeout


func _sentry_walkup(npc: Node2D) -> void:
	var guard := 0
	while player and _manhattan(npc.cell, player.cell) > 1 and guard < 24:
		guard += 1
		var nc: Vector2i = npc.cell + STEP_DIRS[npc.facing]
		if nc == player.cell:
			break
		if is_blocked(nc):
			break
		await npc._step(nc)


func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


func on_player_step(cell: Vector2i) -> void:
	if pickups.has(cell):
		_collect_pickup(cell)
	if hazards.has(cell):
		_apply_hazard(cell)
	if warps.has(cell):
		var w: Dictionary = warps[cell]
		SceneRouter.go_to_map(String(w.map), Vector2i(w.cell.x, w.cell.y) if w.cell is Vector2i else w.cell, String(w.facing))
		return
	if is_grass(cell):
		_roll_encounter()


func _handle_interact(data: Dictionary) -> void:
	match String(data.get("type", "")):
		"heal":
			if player and player.has_method("set_input_locked"):
				player.set_input_locked(true)
			await _play_heal_animation()
			GameState.heal_party()
			SaveService.save_game()
			if player and player.has_method("set_input_locked"):
				player.set_input_locked(false)
			EventBus.dialogue_requested.emit([
				"Welcome to Harmona Rest! Let me tend to your team.",
				"Your %s are fully healed. Journey saved — good luck!" % GameStrings.CREATURE_PLURAL_LOWER,
			])
		"sign":
			EventBus.dialogue_requested.emit([String(data.get("text", "..."))])
		"npc":
			EventBus.dialogue_requested.emit(data.get("lines", ["Hello!"]))
		"guide":
			var stage := StoryService.current_stage()
			var lines := [
				String(data.get("greeting", "Let me check your journey...")),
				"Your goal: %s" % String(stage.get("objective", "Explore %s!" % GameStrings.GAME_NAME)),
			]
			var hint := String(stage.get("hint", ""))
			if hint != "":
				lines.append("Hint: " + hint)
			EventBus.dialogue_requested.emit(lines)
		"trainer":
			_on_trainer_interact(data.get("trainer", {}))


func _play_heal_animation() -> void:
	_busy = true
	var center := Vector2(player.position.x + 8, player.position.y - 8)
	for i in 8:
		var cross := Sprite2D.new()
		cross.texture = load(Tiles.HEAL_CROSS)
		cross.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		cross.centered = true
		cross.scale = Vector2(0.35, 0.35)
		cross.modulate = Color("7dffb8")
		cross.position = center + Vector2(randf_range(-14, 14), randf_range(-18, 2))
		cross.z_index = 12
		add_child(cross)
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(cross, "position:y", cross.position.y - 18.0, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(cross, "modulate:a", 0.0, 0.55)
		tw.chain().tween_callback(cross.queue_free)
		await get_tree().create_timer(0.07).timeout
	var pulse := ColorRect.new()
	pulse.color = Color("7dffb8", 0.0)
	pulse.size = Vector2(240, 160)
	pulse.z_index = 11
	add_child(pulse)
	var pt := create_tween()
	pt.tween_property(pulse, "color", Color("7dffb8", 0.22), 0.12)
	pt.tween_property(pulse, "color", Color("7dffb8", 0.0), 0.28)
	await pt.finished
	pulse.queue_free()
	_busy = false


func _on_trainer_interact(trainer: Dictionary) -> void:
	var id := String(trainer.get("id", ""))
	if bool(GameState.flags.get("trainer_" + id, false)):
		EventBus.dialogue_requested.emit([String(trainer.get("win_line", "That was a great battle!"))])
		return
	if GameState.living_party().is_empty():
		EventBus.dialogue_requested.emit(["Your %s are too tired to battle..." % GameStrings.CREATURE_PLURAL_LOWER])
		return
	_pending_trainer = trainer
	EventBus.dialogue_closed.connect(_launch_trainer, CONNECT_ONE_SHOT)
	EventBus.dialogue_requested.emit(trainer.get("intro", ["Let's battle!"]))


func _launch_trainer() -> void:
	var trainer := _pending_trainer
	_pending_trainer = {}
	if trainer.is_empty():
		return
	var enemies: Array = []
	for m in trainer.get("party", []):
		var inst := EchoCatalog.create_instance(String(m.get("id", "")), int(m.get("level", 5)))
		if inst:
			enemies.append(inst)
	SceneRouter.start_trainer_battle(enemies, String(trainer.get("name", "Rival")), GameState.current_map, {
		"trainer_id": String(trainer.get("id", "")),
		"reward": int(trainer.get("reward", 2)),
		"win_line": String(trainer.get("win_line", "")),
		"gym": bool(trainer.get("gym", false)),
		"ranger": bool(trainer.get("ranger", false)),
	})


func _spawn_player() -> void:
	player = PlayerScene.instantiate()
	add_child(player)
	player.z_index = 5
	var cell := GameState.player_cell
	if GameState.current_map != name.to_lower() and cell == Vector2i(0, 0):
		cell = default_spawn
	if cell == Vector2i(0, 0):
		cell = default_spawn
	player.setup(self, cell, GameState.player_facing)


func _load_encounters() -> void:
	if encounter_table == "":
		return
	var f := FileAccess.open("res://data/encounters.json", FileAccess.READ)
	if f == null:
		return
	var data: Variant = JSON.parse_string(f.get_as_text())
	if typeof(data) == TYPE_DICTIONARY:
		_encounter_data = data.get(encounter_table, {})


func _roll_encounter() -> void:
	if _busy or _encounter_data.is_empty():
		return
	if GameState.living_party().is_empty():
		return
	if randf() > float(_encounter_data.get("chance_per_step", 0.12)):
		return
	var entries: Array = _encounter_data.get("encounters", [])
	var total := 0
	for e in entries:
		total += int(e.get("weight", 1))
	if total <= 0:
		return
	var roll := randi_range(1, total)
	var run := 0
	for e in entries:
		run += int(e.get("weight", 1))
		if roll <= run:
			_busy = true
			var lvl := randi_range(int(e.level_min), int(e.level_max))
			EventBus.toast.emit("A wild %s rustles!" % GameStrings.CREATURE_LOWER)
			await get_tree().create_timer(0.35).timeout
			SceneRouter.start_wild_battle(String(e.id), lvl)
			return
