extends Node2D

## Grid-based Pokemon-style movement with a 4-direction animated sprite.

const TILE := 16
const STEP_TIME := 0.16

var world: Node2D
var cell: Vector2i = Vector2i.ZERO
var facing: String = "down"
var moving: bool = false
var input_locked: bool = false

var sprite: AnimatedSprite2D
var cam: Camera2D

const DIRS := {
	"up": Vector2i(0, -1),
	"down": Vector2i(0, 1),
	"left": Vector2i(-1, 0),
	"right": Vector2i(1, 0),
}
const ROW := { "down": 0, "right": 1, "up": 2, "left": 3 }


func setup(p_world: Node2D, p_cell: Vector2i, p_facing: String) -> void:
	world = p_world
	cell = p_cell
	facing = p_facing if p_facing != "" else "down"
	position = Vector2(cell.x * TILE, cell.y * TILE)


func _ready() -> void:
	add_to_group("player")
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = _build_frames()
	sprite.centered = false
	sprite.offset = Vector2(0, -16)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)

	cam = Camera2D.new()
	cam.position = Vector2(8, 4)
	cam.zoom = Vector2(1, 1)
	cam.position_smoothing_enabled = false
	if world:
		cam.limit_left = 0
		cam.limit_top = 0
		cam.limit_right = world.map_w * TILE
		cam.limit_bottom = world.map_h * TILE
	add_child(cam)
	cam.make_current()

	_play_idle()


func _build_frames() -> SpriteFrames:
	var tex: Texture2D = load("res://assets/sprites/hero.png")
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for dir in ROW.keys():
		var r: int = ROW[dir]
		var idle := "idle_%s" % dir
		var walk := "walk_%s" % dir
		sf.add_animation(idle)
		sf.add_animation(walk)
		sf.set_animation_loop(idle, true)
		sf.set_animation_loop(walk, true)
		sf.set_animation_speed(idle, 2.0)
		sf.set_animation_speed(walk, 9.0)
		# idle uses frame 0
		sf.add_frame(idle, _frame(tex, 0, r))
		# walk cycle 0,1,2,3
		for c in 4:
			sf.add_frame(walk, _frame(tex, c, r))
	return sf


func _frame(tex: Texture2D, col: int, row: int) -> AtlasTexture:
	var at := AtlasTexture.new()
	at.atlas = tex
	at.region = Rect2(col * 16, row * 32, 16, 32)
	return at


func _process(_delta: float) -> void:
	if moving or input_locked or SceneRouter.is_busy():
		return
	if Input.is_action_just_pressed("interact"):
		if world:
			world.try_interact(cell + DIRS[facing])
		return
	var dir := ""
	if Input.is_action_pressed("move_up"): dir = "up"
	elif Input.is_action_pressed("move_down"): dir = "down"
	elif Input.is_action_pressed("move_left"): dir = "left"
	elif Input.is_action_pressed("move_right"): dir = "right"
	if dir == "":
		_play_idle()
		return
	facing = dir
	GameState.player_facing = facing
	var target: Vector2i = cell + DIRS[dir]
	# South-facing ledges: hop down across them for a two-tile jump.
	if world and dir == "down" and world.has_method("is_ledge") and world.is_ledge(target):
		var landing: Vector2i = target + DIRS["down"]
		if not world.is_blocked(landing):
			_hop(landing)
			return
	if world and world.is_blocked(target):
		_play_idle()
		return
	_step(target)


func _hop(landing: Vector2i) -> void:
	moving = true
	sprite.play("walk_%s" % facing)
	var tween := create_tween()
	tween.tween_property(self, "position", Vector2(landing.x * TILE, landing.y * TILE), STEP_TIME * 2.0).set_trans(Tween.TRANS_SINE)
	# little arc via sprite offset
	var hop := create_tween()
	hop.tween_property(sprite, "offset:y", -22.0, STEP_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	hop.tween_property(sprite, "offset:y", -16.0, STEP_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
	cell = landing
	GameState.player_cell = cell
	moving = false
	if world:
		world.on_player_step(cell)


func _step(target: Vector2i) -> void:
	moving = true
	sprite.play("walk_%s" % facing)
	var tween := create_tween()
	tween.tween_property(self, "position", Vector2(target.x * TILE, target.y * TILE), STEP_TIME)
	await tween.finished
	cell = target
	GameState.player_cell = cell
	moving = false
	if world:
		world.on_player_step(cell)


func _play_idle() -> void:
	if sprite:
		sprite.play("idle_%s" % facing)


func set_input_locked(v: bool) -> void:
	input_locked = v
	if v:
		_play_idle()
