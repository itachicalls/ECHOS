extends Node2D

## Grid-based Pokemon-style movement with a 4-direction animated sprite.
## Running Shoes speed you up; Resonance Bike mounts for outdoor dashes.

const TILE := 16
const STEP_WALK := 0.16
const STEP_RUN := 0.10
const STEP_BIKE := 0.065

const PlayerAvatarScript := preload("res://scripts/core/player_avatar.gd")

var world: Node2D
var cell: Vector2i = Vector2i.ZERO
var facing: String = "down"
var moving: bool = false
var input_locked: bool = false

var sprite: AnimatedSprite2D
var cam: Camera2D
var _bike_glow: ColorRect

const DIRS := {
	"up": Vector2i(0, -1),
	"down": Vector2i(0, 1),
	"left": Vector2i(-1, 0),
	"right": Vector2i(1, 0),
}
const ROW := { "down": 0, "right": 1, "up": 2, "left": 3 }

const BIKE_BLOCKED := [
	"cave1", "cave2", "haunted_manor1", "haunted_manor2", "haunted_manor3",
	"crystal_mines1", "crystal_mines2", "whispering_gallery", "salt_catacombs",
	"forgotten_library", "abandoned_lab", "clockwork_vault", "glacial_archive",
	"deeprift1",
]


func setup(p_world: Node2D, p_cell: Vector2i, p_facing: String) -> void:
	world = p_world
	cell = p_cell
	facing = p_facing if p_facing != "" else "down"
	position = Vector2(cell.x * TILE, cell.y * TILE)
	_enforce_bike_indoors()


func _ready() -> void:
	add_to_group("player")
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = _build_frames()
	sprite.centered = false
	sprite.offset = Vector2(0, -16)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)

	_bike_glow = ColorRect.new()
	_bike_glow.size = Vector2(14, 4)
	_bike_glow.position = Vector2(1, 12)
	_bike_glow.color = Color("6ec8ff", 0.0)
	_bike_glow.z_index = -1
	add_child(_bike_glow)

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
	_refresh_bike_visual()


func _build_frames() -> SpriteFrames:
	var tex: Texture2D = load(PlayerAvatarScript.sprite_path(GameState.player_avatar))
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
		sf.add_frame(idle, _frame(tex, 0, r))
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
	if world and dir == "down" and world.has_method("is_ledge") and world.is_ledge(target):
		var landing: Vector2i = target + DIRS["down"]
		if not world.is_blocked(landing):
			_hop(landing)
			return
	if world and world.is_blocked(target):
		_play_idle()
		return
	_step(target)


func _step_time() -> float:
	if bool(GameState.flags.get("bike_mounted", false)):
		return STEP_BIKE
	if ItemCatalog.has_item("running_shoes"):
		return STEP_RUN
	return STEP_WALK


func _walk_anim_speed() -> float:
	if bool(GameState.flags.get("bike_mounted", false)):
		return 16.0
	if ItemCatalog.has_item("running_shoes"):
		return 12.0
	return 9.0


func _hop(landing: Vector2i) -> void:
	moving = true
	sprite.sprite_frames.set_animation_speed("walk_%s" % facing, _walk_anim_speed())
	sprite.play("walk_%s" % facing)
	var t := _step_time()
	var tween := create_tween()
	tween.tween_property(self, "position", Vector2(landing.x * TILE, landing.y * TILE), t * 2.0).set_trans(Tween.TRANS_SINE)
	var hop := create_tween()
	hop.tween_property(sprite, "offset:y", -22.0, t).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	hop.tween_property(sprite, "offset:y", -16.0, t).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
	cell = landing
	GameState.player_cell = cell
	moving = false
	if world:
		world.on_player_step(cell)


func _step(target: Vector2i) -> void:
	moving = true
	sprite.sprite_frames.set_animation_speed("walk_%s" % facing, _walk_anim_speed())
	sprite.play("walk_%s" % facing)
	var tween := create_tween()
	tween.tween_property(self, "position", Vector2(target.x * TILE, target.y * TILE), _step_time())
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


func _enforce_bike_indoors() -> void:
	if not bool(GameState.flags.get("bike_mounted", false)):
		return
	var map_id := String(GameState.current_map)
	if map_id in BIKE_BLOCKED:
		GameState.flags["bike_mounted"] = false
		_refresh_bike_visual()


func _refresh_bike_visual() -> void:
	if _bike_glow == null:
		return
	var on := bool(GameState.flags.get("bike_mounted", false))
	_bike_glow.color = Color("6ec8ff", 0.55 if on else 0.0)
	if sprite:
		sprite.modulate = Color("c8e8ff") if on else Color.WHITE


static func can_mount_bike_here() -> bool:
	return String(GameState.current_map) not in BIKE_BLOCKED


static func toggle_bike() -> String:
	if not ItemCatalog.has_item("resonance_bike"):
		return "You don't have a Resonance Bike."
	var tree := Engine.get_main_loop() as SceneTree
	if bool(GameState.flags.get("bike_mounted", false)):
		GameState.flags["bike_mounted"] = false
		if tree:
			for p in tree.get_nodes_in_group("player"):
				if p.has_method("_refresh_bike_visual"):
					p._refresh_bike_visual()
		return "You hop off the Resonance Bike."
	if not can_mount_bike_here():
		return "Too tight to bike here — try the open routes."
	GameState.flags["bike_mounted"] = true
	if tree:
		for p in tree.get_nodes_in_group("player"):
			if p.has_method("_refresh_bike_visual"):
				p._refresh_bike_visual()
	return "You mount the Resonance Bike!"
