class_name Tiles
extends RefCounted

## Kenney CC0 tile identities. Every tile is Vector3i(source, col, row) where
## source indexes SHEETS below. Cohesive "Tiny" art style (tiny-town + tiny-dungeon)
## with roguelike used only for water.

const SHEETS := [
	{ "path": "res://assets/kenney/tiny_town_sheet.png", "sep": Vector2i(0, 0) },      # 0
	{ "path": "res://assets/kenney/tiny_dungeon_sheet.png", "sep": Vector2i(0, 0) },   # 1
	{ "path": "res://assets/kenney/roguelike_sheet.png", "sep": Vector2i(1, 1) },      # 2
	{ "path": "res://assets/kenney/gen/tall_grass.png", "sep": Vector2i(0, 0) },       # 3
	{ "path": "res://assets/kenney/gen/desert_brush.png", "sep": Vector2i(0, 0) },     # 4
	{ "path": "res://assets/kenney/gen/grass_field.png", "sep": Vector2i(0, 0) },      # 5
	{ "path": "res://assets/kenney/gen/path_set.png", "sep": Vector2i(0, 0) },         # 6 (4x4 autotile)
	{ "path": "res://assets/kenney/gen/cobble_set.png", "sep": Vector2i(0, 0) },       # 7 (4x4 autotile)
]

# --- ground / decor tiles: Vector3i(source, col, row) ---
const GRASS := Vector3i(5, 0, 0)
const GRASS2 := Vector3i(0, 2, 0)
const TALL_GRASS := Vector3i(3, 0, 0)
const DESERT_BRUSH := Vector3i(4, 0, 0)
# PATH is a marker: the overworld auto-tiles all PATH cells into the correct
# edge/corner piece of the path_set (source 6). (3,3) = fully-connected center.
const PATH := Vector3i(6, 3, 3)
const DIRT := Vector3i(6, 3, 3)
const PATH_SOURCE := 6
const LEDGE := Vector3i(0, 9, 6)  # horizontal wooden rail = hop-down ledge
# STONE is a marker too: auto-tiled cobblestone plaza (source 7).
const STONE := Vector3i(7, 3, 3)
const STONE_SOURCE := 7
const WATER := Vector3i(2, 1, 0)
const SAND := Vector3i(1, 0, 4)
const SAND2 := Vector3i(1, 2, 4)
const SAND_PATH := Vector3i(1, 3, 4)
const FLOWERS := Vector3i(0, 2, 0)
const BUSH := Vector3i(0, 5, 0)
const MUSHROOM := Vector3i(0, 5, 2)

# --- tree sprites (tiny-town, 16x32 = treetop + trunk, referenced by column) ---
const TREE_GREEN_COL := 4
const TREE_ORANGE_COL := 3
const TREE_SHEET := "res://assets/kenney/tiny_town_sheet.png"

# --- house tiles (tiny-town), 3 wide x 3 tall ---
const HOUSE_ROWS := [
	[Vector2i(4, 4), Vector2i(5, 4), Vector2i(6, 4)],  # roof
	[Vector2i(4, 6), Vector2i(5, 6), Vector2i(6, 6)],  # upper wall + windows
	[Vector2i(4, 7), Vector2i(5, 7), Vector2i(6, 7)],  # lower wall + door
]
const HOUSE_W := 3
const HOUSE_H := 3

# --- character / prop / item sprite paths ---
const TRAINER_PATHS := [
	"res://assets/kenney/chars/trainer_wizard.png",
	"res://assets/kenney/chars/trainer_monk.png",
	"res://assets/kenney/chars/trainer_smith.png",
	"res://assets/kenney/chars/trainer_viking.png",
	"res://assets/kenney/chars/trainer_scout.png",
	"res://assets/kenney/chars/trainer_knight.png",
]

const NURSE := "res://assets/kenney/chars/nurse.png"
const SHRINE_FOUNTAIN := "res://assets/kenney/props/shrine_fountain.png"
const HEAL_CROSS := "res://assets/kenney/props/heal_cross.png"
const ECHO_CAPSULE := "res://assets/kenney/items/echo_capsule.png"
const HEART_SALVE := "res://assets/kenney/items/heart_salve.png"
const SPIKES := "res://assets/kenney/props/spikes.png"
const THORNS := "res://assets/kenney/props/thorns.png"


static func sheet_count() -> int:
	return SHEETS.size()
