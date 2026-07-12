extends Node2D

## Overworld NPC: static, wandering, or a line-of-sight "sentry" trainer that
## marches up to challenge the player. Occupies its cell for collision.

const TILE := 16
const STEP := 0.2

const DIRS := {
	"up": Vector2i(0, -1),
	"down": Vector2i(0, 1),
	"left": Vector2i(-1, 0),
	"right": Vector2i(1, 0),
}
const FACING_ROW := { "down": 0, "right": 1, "up": 2, "left": 3 }

var world                             # Overworld (untyped: uses dynamic props/methods)
var cell: Vector2i
var target_cell: Vector2i
var facing: String = "down"
var data: Dictionary = {}
var kind: String = "static"          # static | wander | sentry
var home: Vector2i
var wander_radius: int = 2
var sight: int = 0
var use_sheet: bool = false

var moving: bool = false
var triggered: bool = false
var _wander_timer: float = 0.0
var sprite: Sprite2D


func setup(p_world, p_cell: Vector2i, p_facing: String, p_data: Dictionary, texture_path: String, tint: Color) -> void:
	world = p_world
	cell = p_cell
	target_cell = p_cell
	home = p_cell
	facing = p_facing if p_facing != "" else "down"
	data = p_data
	position = Vector2(cell.x * TILE, cell.y * TILE)

	sprite = Sprite2D.new()
	if texture_path != "":
		sprite.texture = load(texture_path)
		sprite.region_enabled = false
		use_sheet = false
	else:
		sprite.texture = load("res://assets/sprites/hero.png")
		sprite.region_enabled = true
		use_sheet = true
		_apply_facing_region()
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.modulate = tint
	_apply_sprite_layout(sprite)
	add_child(sprite)
	z_index = 4
	_wander_timer = randf_range(1.0, 3.0)


func _apply_sprite_layout(spr: Sprite2D) -> void:
	if spr.texture == null:
		spr.offset = Vector2(0, -16)
		return
	var th := spr.texture.get_height()
	spr.scale = Vector2.ONE
	if th >= 28:
		spr.offset = Vector2(0, -16)
	else:
		# 16×16 Kenney tiles — keep native size, anchor feet on the tile.
		spr.offset = Vector2(0, -8)


func _apply_facing_region() -> void:
	if use_sheet and sprite:
		sprite.region_rect = Rect2(0, FACING_ROW.get(facing, 0) * 32, 16, 32)


func face(dir: String) -> void:
	if dir == "":
		return
	facing = dir
	_apply_facing_region()


func face_towards(other: Vector2i) -> void:
	var d := other - cell
	if absi(d.x) >= absi(d.y):
		face("right" if d.x > 0 else "left")
	else:
		face("down" if d.y > 0 else "up")


func _process(delta: float) -> void:
	if world == null or moving:
		return
	if _defeated():
		return
	if _scene_locked():
		return
	match kind:
		"wander":
			_wander_timer -= delta
			if _wander_timer <= 0.0:
				_wander_timer = randf_range(1.4, 3.4)
				_try_wander()
		"sentry":
			if not triggered:
				_check_sight()


func _defeated() -> bool:
	if kind != "sentry":
		return false
	if String(data.get("type", "")) == "greeter":
		var g: Dictionary = data.get("greeter", {})
		return bool(GameState.flags.get("greeter_" + String(g.get("id", "")), false))
	var t: Dictionary = data.get("trainer", {})
	return bool(GameState.flags.get("trainer_" + String(t.get("id", "")), false))


func _scene_locked() -> bool:
	if EventBus.dialogue_active or EventBus.menu_active:
		return true
	return bool(world.get("_busy")) or bool(world.get("_cutscene"))


func _try_wander() -> void:
	var dirs := ["up", "down", "left", "right"]
	dirs.shuffle()
	for dir in dirs:
		var nc: Vector2i = cell + DIRS[dir]
		if absi(nc.x - home.x) > wander_radius or absi(nc.y - home.y) > wander_radius:
			continue
		face(dir)
		if _can_enter(nc):
			_step(nc)
			return
	# even if blocked, turning is fine (already faced)


func _can_enter(nc: Vector2i) -> bool:
	if world.is_blocked(nc):
		return false
	if world.player and world.player.cell == nc:
		return false
	return true


func _step(nc: Vector2i) -> void:
	moving = true
	target_cell = nc
	var tw := create_tween()
	tw.tween_property(self, "position", Vector2(nc.x * TILE, nc.y * TILE), STEP)
	await tw.finished
	cell = nc
	target_cell = nc
	moving = false


func _check_sight() -> void:
	if world.player == null:
		return
	var step: Vector2i = DIRS[facing]
	var probe := cell
	for i in sight:
		probe += step
		if world.is_blocked(probe) and world.player.cell != probe:
			return
		if world.player.cell == probe:
			triggered = true
			_engage()
			return


func _engage() -> void:
	if world.has_method("begin_sentry"):
		world.begin_sentry(self)
