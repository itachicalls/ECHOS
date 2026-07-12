class_name PlayerAvatar
extends RefCounted

## Playable keeper appearances — 64x128 hero-layout sheets (16x32 frames).

const IDS: Array[String] = ["keeper", "curly", "cap"]

const PATHS := {
	"keeper": "res://assets/sprites/hero.png",
	"curly": "res://assets/sprites/hero_curly.png",
	"cap": "res://assets/sprites/hero_cap.png",
}

const LABELS := {
	"keeper": "Classic",
	"curly": "Curly",
	"cap": "Cap",
}

const BLURBS := {
	"keeper": "Red shirt — classic valley look",
	"curly": "Pink dress — warm & spirited",
	"cap": "Street cap — cool & confident",
}

const DEFAULT_NAMES := {
	"keeper": "Ash",
	"curly": "Luna",
	"cap": "Kai",
}

const MAX_NAME_LEN := 12


static func normalize_id(id: String) -> String:
	return id if id in IDS else "keeper"


static func sprite_path(id: String) -> String:
	var key := normalize_id(id)
	return String(PATHS.get(key, PATHS.keeper))


static func sanitize_name(name: String, avatar_id: String = "keeper") -> String:
	var trimmed := name.strip_edges()
	if trimmed == "":
		return String(DEFAULT_NAMES.get(normalize_id(avatar_id), "Keeper"))
	if trimmed.length() > MAX_NAME_LEN:
		return trimmed.substr(0, MAX_NAME_LEN)
	return trimmed


static func idle_preview_texture(id: String) -> Texture2D:
	var path := sprite_path(id)
	if not ResourceLoader.exists(path):
		path = PATHS.keeper
	var tex: Texture2D = load(path)
	if tex == null:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	atlas.region = Rect2(0, 0, 16, 32)
	return atlas
