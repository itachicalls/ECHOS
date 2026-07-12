class_name AmbushActor
extends Node2D

## Temporary overworld sprite that marches in for ambush cutscenes (Kenney trainer assets).

const TILE := 16
const STEP_TIME := 0.18
const FACING_ROW := { "down": 0, "right": 1, "up": 2, "left": 3 }

var world
var cell: Vector2i
var target_cell: Vector2i
var facing: String = "down"
var sprite: Sprite2D
var use_sheet: bool = false


func setup(p_world, spawn: Vector2i, dest: Vector2i, look: int) -> void:
	world = p_world
	cell = spawn
	target_cell = dest
	position = Vector2(cell.x * TILE, cell.y * TILE)
	z_index = 6

	var idx := clampi(look, 0, Tiles.TRAINER_PATHS.size() - 1)
	sprite = Sprite2D.new()
	sprite.texture = load(Tiles.TRAINER_PATHS[idx])
	var tex := sprite.texture
	use_sheet = tex != null and tex.get_width() == 64 and tex.get_height() == 128
	sprite.region_enabled = use_sheet
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var th := 32 if use_sheet else (tex.get_height() if tex else 32)
	sprite.offset = Vector2(0, -16) if th >= 28 else Vector2(0, -8)
	add_child(sprite)
	_apply_facing()


func _apply_facing() -> void:
	if sprite == null:
		return
	if use_sheet:
		sprite.region_rect = Rect2(0, FACING_ROW.get(facing, 0) * 32, 16, 32)
	else:
		sprite.flip_h = facing == "left"


func face_towards(other: Vector2i) -> void:
	var d := other - cell
	if absi(d.x) >= absi(d.y):
		facing = "right" if d.x > 0 else "left"
	else:
		facing = "down" if d.y > 0 else "up"
	_apply_facing()


func walk_to_target() -> void:
	while cell != target_cell:
		var delta := target_cell - cell
		var next := cell
		if absi(delta.x) >= absi(delta.y) and delta.x != 0:
			next = cell + Vector2i(signi(delta.x), 0)
			facing = "right" if delta.x > 0 else "left"
		elif delta.y != 0:
			next = cell + Vector2i(0, signi(delta.y))
			facing = "down" if delta.y > 0 else "up"
		else:
			break
		if world and world.is_blocked(next) and (world.player == null or world.player.cell != next):
			break
		_apply_facing()
		await _step(next)


func _step(nc: Vector2i) -> void:
	var tw := create_tween()
	tw.tween_property(self, "position", Vector2(nc.x * TILE, nc.y * TILE), STEP_TIME).set_trans(Tween.TRANS_LINEAR)
	await tw.finished
	cell = nc
