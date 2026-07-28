#!/usr/bin/env python3
"""Generate ~25 themed discoverable routes, encounters, and router entries."""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / "scripts" / "world"
SCENES = ROOT / "scenes" / "world"
ENC_PATH = ROOT / "data" / "encounters.json"
ROUTER = ROOT / "scripts" / "autoload" / "scene_router.gd"

# id, title, theme, lv_min, lv_max, resonances, next_map, parent_hint
# theme: grass|sand|cave|haunted|tower|psychic|fire|ice|beach|storm
ROUTES = [
    # --- early / mid discoverables ---
    {"id": "willow_fen", "title": "Willow Fen", "theme": "grass", "lv": (6, 10),
     "res": ["grass", "water", "shadow"], "next": None,
     "blurb": "Misty willows hide soft-footed Harmons."},
    {"id": "scarlet_orchard", "title": "Scarlet Orchard", "theme": "grass", "lv": (7, 11),
     "res": ["grass", "fire"], "next": None,
     "blurb": "Fruit trees blush red; bees and fire-kits quarrel."},
    {"id": "mushroom_grotto", "title": "Mushroom Grotto", "theme": "cave", "lv": (8, 13),
     "res": ["grass", "shadow", "rock"], "next": None,
     "blurb": "Bioluminescent fungi carpet a damp hollow."},
    {"id": "haunted_manor1", "title": "Hollowbrook Manor", "theme": "haunted", "lv": (10, 15),
     "res": ["shadow", "psychic"], "next": "haunted_manor2",
     "blurb": "A shuttered estate. Dust motes move like eyes."},
    {"id": "haunted_manor2", "title": "Manor Galleries", "theme": "haunted", "lv": (14, 19),
     "res": ["shadow", "psychic", "air"], "next": "haunted_manor3",
     "blurb": "Paintings whisper. Corridors refuse to stay still."},
    {"id": "haunted_manor3", "title": "Manor Crypt", "theme": "haunted", "lv": (18, 24),
     "res": ["shadow", "rock", "psychic"], "next": None,
     "blurb": "The family vault. Something still keeps house."},
    {"id": "belltower1", "title": "Belltower Ascent", "theme": "tower", "lv": (12, 17),
     "res": ["air", "electric", "rock"], "next": "belltower2",
     "blurb": "Wind howls through cracked belfry stairs."},
    {"id": "belltower2", "title": "Belltower Midspire", "theme": "tower", "lv": (16, 22),
     "res": ["air", "electric", "psychic"], "next": "belltower3",
     "blurb": "Ropes and gears. The bells remember names."},
    {"id": "belltower3", "title": "Belltower Crown", "theme": "tower", "lv": (20, 26),
     "res": ["air", "electric", "shadow"], "next": None,
     "blurb": "Above the clouds — a storm-legend nests here."},
    {"id": "ember_forge", "title": "Ember Forge", "theme": "fire", "lv": (14, 20),
     "res": ["fire", "rock"], "next": None,
     "blurb": "Abandoned smithy still glowing with old heat."},
    {"id": "salt_catacombs", "title": "Salt Catacombs", "theme": "cave", "lv": (13, 19),
     "res": ["rock", "water", "shadow"], "next": None,
     "blurb": "White halls carved from dried sea-beds."},
    {"id": "vine_cathedral", "title": "Vine Cathedral", "theme": "grass", "lv": (16, 22),
     "res": ["grass", "psychic"], "next": None,
     "blurb": "Living arches of ivy form a green nave."},
    {"id": "crystal_mines1", "title": "Crystal Mines", "theme": "cave", "lv": (15, 21),
     "res": ["rock", "electric", "psychic"], "next": "crystal_mines2",
     "blurb": "Faceted walls hum with trapped lightning."},
    {"id": "crystal_mines2", "title": "Crystal Heart", "theme": "cave", "lv": (20, 26),
     "res": ["rock", "psychic", "electric"], "next": None,
     "blurb": "The seam where the Fracture cracked stone."},
    {"id": "whispering_gallery", "title": "Whispering Gallery", "theme": "cave", "lv": (22, 28),
     "res": ["shadow", "psychic", "rock"], "next": None,
     "blurb": "Echoes answer before you speak."},
    {"id": "coral_cathedral", "title": "Coral Cathedral", "theme": "beach", "lv": (14, 20),
     "res": ["water", "psychic"], "next": None,
     "blurb": "Tide-built spires of living reef."},
    {"id": "sunken_ruins", "title": "Sunken Ruins", "theme": "beach", "lv": (16, 22),
     "res": ["water", "shadow", "rock"], "next": None,
     "blurb": "A drowned plaza. Bells toll underwater."},
    {"id": "thunder_spire", "title": "Thunder Spire", "theme": "storm", "lv": (22, 30),
     "res": ["electric", "air"], "next": None,
     "blurb": "A lone needle of stone that invites lightning."},
    {"id": "mirror_marsh", "title": "Mirror Marsh", "theme": "psychic", "lv": (26, 34),
     "res": ["psychic", "water", "shadow"], "next": None,
     "blurb": "Still pools show futures you might refuse."},
    {"id": "forgotten_library", "title": "Forgotten Library", "theme": "psychic", "lv": (28, 36),
     "res": ["psychic", "shadow", "air"], "next": None,
     "blurb": "Shelves rearrange when you look away."},
    {"id": "windmill_ridge", "title": "Windmill Ridge", "theme": "grass", "lv": (18, 26),
     "res": ["air", "grass", "electric"], "next": None,
     "blurb": "Old mills still turn on dry winds."},
    {"id": "abandoned_lab", "title": "Archive Lab Ruins", "theme": "psychic", "lv": (24, 32),
     "res": ["psychic", "electric", "shadow"], "next": "clockwork_vault",
     "blurb": "The Memory Archive's sealed annex."},
    {"id": "clockwork_vault", "title": "Clockwork Vault", "theme": "tower", "lv": (28, 36),
     "res": ["electric", "rock", "psychic"], "next": None,
     "blurb": "Gears older than the Chorus keep time."},
    {"id": "moonlit_lake", "title": "Moonlit Lake", "theme": "beach", "lv": (20, 28),
     "res": ["water", "shadow", "psychic"], "next": None,
     "blurb": "Silver water that never warms."},
    {"id": "starfall_crater", "title": "Starfall Crater", "theme": "psychic", "lv": (30, 40),
     "res": ["psychic", "rock", "air"], "next": None,
     "blurb": "A bruise in the earth where a star died."},
    {"id": "thornwall_keep", "title": "Thornwall Keep", "theme": "grass", "lv": (22, 30),
     "res": ["grass", "rock", "shadow"], "next": None,
     "blurb": "A briar-fort held by stubborn rangers."},
    {"id": "cloud_garden", "title": "Cloud Garden", "theme": "tower", "lv": (32, 42),
     "res": ["air", "grass", "psychic"], "next": None,
     "blurb": "Terraces float above Ashpeak's smoke."},
    {"id": "bonebridge", "title": "Bonebridge Causeway", "theme": "haunted", "lv": (34, 44),
     "res": ["shadow", "rock"], "next": None,
     "blurb": "A span of ribs over a black ravine."},
    {"id": "aurora_cliff", "title": "Aurora Cliff", "theme": "ice", "lv": (40, 50),
     "res": ["air", "water", "psychic"], "next": None,
     "blurb": "Lights dance where ice meets sky."},
    {"id": "glacial_archive", "title": "Glacial Archive", "theme": "ice", "lv": (48, 58),
     "res": ["water", "psychic", "shadow"], "next": None,
     "blurb": "Frozen shelves of Chorus memory."},
]

TRAINER_NAMES = [
    ("Wanderer", "Ash"), ("Scout", "Mira"), ("Keeper", "Jon"), ("Sage", "Lira"),
    ("Hunter", "Rex"), ("Acolyte", "Vee"), ("Scholar", "Otto"), ("Warden", "Pia"),
    ("Seeker", "Cal"), ("Mystic", "Noa"), ("Ranger", "Tess"), ("Curator", "Ivo"),
]

THEME_GROUND = {
    "grass": "Tiles.GRASS",
    "sand": "Tiles.SAND",
    "cave": "Tiles.CAVE_FLOOR",
    "haunted": "Tiles.CAVE_FLOOR2",
    "tower": "Tiles.STONE",
    "psychic": "Tiles.GRASS2",
    "fire": "Tiles.SAND2",
    "ice": "Tiles.CAVE_FLOOR",
    "beach": "Tiles.SAND",
    "storm": "Tiles.GRASS2",
}

THEME_PATH = {
    "grass": "Tiles.PATH",
    "sand": "Tiles.SAND_PATH",
    "cave": "Tiles.CAVE_FLOOR",
    "haunted": "Tiles.CAVE_FLOOR",
    "tower": "Tiles.STONE",
    "psychic": "Tiles.PATH",
    "fire": "Tiles.STONE",
    "ice": "Tiles.STONE",
    "beach": "Tiles.SAND_PATH",
    "storm": "Tiles.PATH",
}

THEME_BRUSH = {
    "grass": "Tiles.TALL_GRASS",
    "sand": "Tiles.DESERT_BRUSH",
    "cave": "Tiles.CAVE_FLOOR2",
    "haunted": "Tiles.CAVE_FLOOR2",
    "tower": "Tiles.DESERT_BRUSH",
    "psychic": "Tiles.TALL_GRASS",
    "fire": "Tiles.DESERT_BRUSH",
    "ice": "Tiles.DESERT_BRUSH",
    "beach": "Tiles.DESERT_BRUSH",
    "storm": "Tiles.TALL_GRASS",
}


def load_echoes_by_res() -> dict[str, list[str]]:
    data = json.loads((ROOT / "data" / "echoes.json").read_text(encoding="utf-8"))
    by: dict[str, list[str]] = {}
    for e in data:
        by.setdefault(e.get("resonance", "rock"), []).append(e["id"])
    return by


def pick_party(by_res: dict[str, list[str]], resonances: list[str], lv: int, n: int) -> list[dict]:
    pool: list[str] = []
    for r in resonances:
        pool.extend(by_res.get(r, [])[:40])
    if not pool:
        pool = by_res.get("rock", ["pebblit"])
    out = []
    for i in range(n):
        eid = pool[(lv * 3 + i * 7) % len(pool)]
        out.append({"id": eid, "level": lv + (i % 3)})
    return out


def encounter_block(by_res: dict[str, list[str]], route: dict) -> dict:
    lo, hi = route["lv"]
    encounters = []
    weights = [18, 14, 12, 10, 8, 8, 6, 6, 5, 4]
    pool: list[str] = []
    for r in route["res"]:
        pool.extend(by_res.get(r, [])[:30])
    seen = set()
    uniq = []
    for p in pool:
        if p not in seen:
            seen.add(p)
            uniq.append(p)
    for i, w in enumerate(weights):
        if i >= len(uniq):
            break
        encounters.append({
            "id": uniq[i],
            "weight": w,
            "level_min": lo + (i % 3),
            "level_max": min(hi, lo + 4 + (i % 3)),
        })
    return {"chance_per_step": 0.13, "encounters": encounters}


def gd_escape(s: str) -> str:
    return s.replace("\\", "\\\\").replace('"', '\\"')


def render_map(route: dict, by_res: dict[str, list[str]]) -> str:
    rid = route["id"]
    theme = route["theme"]
    ground = THEME_GROUND[theme]
    path = THEME_PATH[theme]
    brush = THEME_BRUSH[theme]
    lo, hi = route["lv"]
    mid = (lo + hi) // 2
    title = route["title"]
    blurb = route["blurb"]
    nxt = route.get("next")

    border_fn = {
        "grass": "place_tree(Vector2i(x, y), Tiles.TREE_GREEN_COL)",
        "sand": "place_rock(Vector2i(x, y))",
        "cave": "place_rock(Vector2i(x, y))",
        "haunted": "place_rock(Vector2i(x, y))",
        "tower": "place_rock(Vector2i(x, y))",
        "psychic": "place_tree(Vector2i(x, y), Tiles.TREE_ORANGE_COL)",
        "fire": "place_rock(Vector2i(x, y))",
        "ice": "place_rock(Vector2i(x, y))",
        "beach": "place_rock(Vector2i(x, y))",
        "storm": "place_tree(Vector2i(x, y), Tiles.TREE_ORANGE_COL)",
    }[theme]

    # parent warp is filled by hub patches; south gate returns via default_parent later
    next_warps = ""
    if nxt:
        next_warps = f"""
	add_warp(Vector2i(9, 0), "{nxt}", Vector2i(9, 22), "up")
	add_warp(Vector2i(10, 0), "{nxt}", Vector2i(10, 22), "up")
"""

    trainers = []
    for i in range(3):
        prefix, name = TRAINER_NAMES[(hash(rid) + i) % len(TRAINER_NAMES)]
        tid = f"{rid}_t{i}"
        party = pick_party(by_res, route["res"], mid + i, 2 + (i % 2))
        party_s = ", ".join(
            '{ "id": "%s", "level": %d }' % (p["id"], p["level"]) for p in party
        )
        cells = [(5, 10), (14, 14), (6, 17)][i]
        facing = ["right", "left", "up"][i]
        hint = f"Rumor: keep exploring — {title} hides more than one path."
        if nxt:
            hint = f"Deeper still: the way north climbs into the next hall of {title}."
        elif i == 2:
            hint = f"When you're ready for bigger trials, return to Harmona Rest — west opens after the Champion, south after Primordius."
        trainers.append(f"""
	add_trainer(Vector2i({cells[0]}, {cells[1]}), "{facing}", {{
		"id": "{tid}", "name": "{prefix} {name}", "look": {(hash(tid) % 18)},
		"party": [{party_s}],
		"reward": {3 + i + lo // 10},
		"intro": ["{gd_escape(title)} tests every keeper.", "Show me your bond!"],
		"win_line": "Well fought. The land remembers you.",
		"after_lines": [
			"Still training here? Good — this place rewards patience.",
			"{gd_escape(hint)}",
		],
		"hint": "{gd_escape(hint)}",
	}}, {3 + i})""")

    decor = ""
    if theme in ("haunted",):
        decor = """
	for p in [Vector2i(4, 6), Vector2i(15, 8), Vector2i(7, 12), Vector2i(12, 18)]:
		add_ground_prop(Tiles.TOMBSTONE, p, true)
"""
    elif theme in ("beach",):
        decor = """
	for p in [Vector2i(3, 8), Vector2i(16, 6), Vector2i(5, 16)]:
		add_ground_prop(Tiles.PALM, p, true)
"""
    elif theme in ("cave", "crystal"):
        decor = """
	for p in [Vector2i(4, 7), Vector2i(15, 9), Vector2i(8, 15)]:
		add_ground_prop(Tiles.CRYSTAL, p, true)
"""
    elif theme == "psychic":
        decor = """
	for p in [Vector2i(5, 6), Vector2i(14, 7), Vector2i(10, 16)]:
		add_ground_prop(Tiles.CRYSTAL, p, true)
"""
    elif theme == "grass":
        decor = """
	for p in [Vector2i(4, 8), Vector2i(15, 7), Vector2i(7, 15)]:
		place_bush(p)
	set_decor(Vector2i(12, 12), Tiles.MUSHROOM)
"""

    legend = ""
    # a few signature legends on end-of-chain maps
    legends = {
        "haunted_manor3": ("umbrix", 28, "The crypt unseals. A shadow-lord answers the house call!"),
        "belltower3": ("stormraptor", 28, "Thunder crowns the spire. A storm-raptor claims the bells!"),
        "crystal_mines2": ("arcanexus", 30, "The crystal heart pulses. An arcane Harmon steps through!"),
        "starfall_crater": ("cosmindra", 42, "Starlight coagulates. COSMINDRA regards the crater as nest!"),
        "glacial_archive": ("cryoleth", 55, "Frost archives awaken. CRYOLETH thaws from a shelf of ice!"),
        "thunder_spire": ("thunderoc", 32, "The needle sings. THUNDEROC dives from a black cloud!"),
        "clockwork_vault": ("tesloom", 38, "Gears lock. TESLOOM — living dynamo — steps from the vault!"),
        "bonebridge": ("voidmonarch", 46, "Across the ribs, VOIDMONARCH waits with a courtier's bow."),
        "cloud_garden": ("stratoson", 44, "Clouds part. STRATOSON blooms above the terrace!"),
    }
    if rid in legends:
        lid, llv, ltxt = legends[rid]
        legend = f"""
	add_legend_encounter(Vector2i(9, 6), "{lid}", {llv},
		"{gd_escape(ltxt)}")
"""

    return f'''extends "res://scripts/world/overworld.gd"

## {title.upper()} — discoverable themed area.


func _build_map() -> void:
	map_w = 20
	map_h = 24
	default_spawn = Vector2i(9, 22)
	encounter_table = "{rid}"

	fill_ground(0, 0, map_w - 1, map_h - 1, {ground})
	for x in map_w:
		if x != 9 and x != 10:
			var _bx := x
			var _by := 0
			x = _bx
			# borders
			pass
	for x in map_w:
		if x != 9 and x != 10:
			{border_fn.replace("(x, y)", "(x, 0)")}
			{border_fn.replace("(x, y)", "(x, map_h - 1)")}
	for y in range(1, map_h - 1):
		{border_fn.replace("(x, y)", "(0, y)")}
		{border_fn.replace("(x, y)", "(map_w - 1, y)")}

	for y in range(0, map_h):
		set_ground(Vector2i(9, y), {path})
		set_ground(Vector2i(10, y), {path})
	for x in range(3, 17):
		set_ground(Vector2i(x, 12), {path})

	# south exit is wired by hub; placeholder return uses parent_map override via warps added externally
	# north continues chain when present
{next_warps}
	_brush_patch(2, 8, 7, 14)
	_brush_patch(12, 8, 17, 14)
	_brush_patch(3, 16, 8, 21)
	_brush_patch(12, 3, 16, 7)
{decor}
	add_interact(Vector2i(9, 21), {{ "type": "sign", "text": "{gd_escape(title.upper())} - {gd_escape(blurb)}" }})
{''.join(trainers)}
{legend}
	add_npc(Vector2i(11, 20), "left", Color(1, 1, 1), {{
		"type": "npc",
		"lines": [
			"{gd_escape(blurb)}",
			"Beat the keepers here — they share rumors about where to go next.",
		],
	}}, Tiles.TRAINER_PATHS[{(hash(rid) % 10)}], 1)


func _place_pickups() -> void:
	add_pickup(Vector2i(3, 19), "echo_capsule", {1 + lo // 12})
	add_pickup(Vector2i(16, 5), "heart_salve", {1 + lo // 15})
	add_pickup(Vector2i(4, 9), "great_capsule", {1 + lo // 18})
	add_pickup(Vector2i(17, 18), "super_salve" if {lo} < 30 else "max_salve", 1)


func _brush_patch(x0: int, y0: int, x1: int, y1: int) -> void:
	for x in range(x0, x1 + 1):
		for y in range(y0, y1 + 1):
			if not is_blocked(Vector2i(x, y)) and not warps.has(Vector2i(x, y)):
				place_tall_grass(Vector2i(x, y), {brush})
'''


def fix_border_code(src: str) -> str:
    """Clean the awkward border generation in render_map."""
    # The generated border has a useless loop — rewrite maps with a cleaner template instead.
    return src


def render_map_clean(route: dict, by_res: dict[str, list[str]], parent: str | None) -> str:
    rid = route["id"]
    theme = route["theme"]
    ground = THEME_GROUND[theme]
    path = THEME_PATH[theme]
    brush = THEME_BRUSH[theme]
    lo, hi = route["lv"]
    mid = (lo + hi) // 2
    title = route["title"]
    blurb = route["blurb"]
    nxt = route.get("next")

    tree_themes = {"grass", "psychic", "storm"}
    if theme in tree_themes:
        col = "Tiles.TREE_ORANGE_COL" if theme != "grass" else "Tiles.TREE_GREEN_COL"
        border_h = f"""
	for x in map_w:
		if x != 9 and x != 10:
			place_tree(Vector2i(x, 0), {col})
			place_tree(Vector2i(x, map_h - 1), {col})
	for y in range(1, map_h - 1):
		place_tree(Vector2i(0, y), {col})
		place_tree(Vector2i(map_w - 1, y), {col})
"""
    else:
        border_h = """
	for x in map_w:
		if x != 9 and x != 10:
			place_rock(Vector2i(x, 0))
			place_rock(Vector2i(x, map_h - 1))
	for y in range(1, map_h - 1):
		place_rock(Vector2i(0, y))
		place_rock(Vector2i(map_w - 1, y))
"""

    parent_warps = ""
    if parent:
        parent_warps = f"""
	add_warp(Vector2i(9, 23), "{parent}", Vector2i(9, 1), "down")
	add_warp(Vector2i(10, 23), "{parent}", Vector2i(10, 1), "down")
"""

    next_warps = ""
    if nxt:
        next_warps = f"""
	add_warp(Vector2i(9, 0), "{nxt}", Vector2i(9, 22), "up")
	add_warp(Vector2i(10, 0), "{nxt}", Vector2i(10, 22), "up")
"""

    trainers_src = []
    for i in range(3):
        prefix, name = TRAINER_NAMES[(abs(hash(rid)) + i) % len(TRAINER_NAMES)]
        tid = f"{rid}_t{i}"
        party = pick_party(by_res, route["res"], mid + i, 2 + (i % 2))
        party_s = ", ".join(
            '{ "id": "%s", "level": %d }' % (p["id"], p["level"]) for p in party
        )
        cells = [(5, 10), (14, 14), (6, 17)][i]
        facing = ["right", "left", "up"][i]
        if nxt:
            hint = f"North leads deeper — the next wing of {title} waits."
        elif i == 0:
            hint = "Talk to every beaten keeper. We trade rumors for tough fights."
        elif i == 1:
            hint = "Side paths hide mansions, towers, and mines off the main gym road."
        else:
            hint = "After Champion Vael, the western Tidecross trail opens from Harmona Rest. After Primordius, go south to Ashpeak."
        trainers_src.append(f"""
	add_trainer(Vector2i({cells[0]}, {cells[1]}), "{facing}", {{
		"id": "{tid}", "name": "{prefix} {name}", "look": {abs(hash(tid)) % 18},
		"party": [{party_s}],
		"reward": {3 + i + lo // 10},
		"intro": ["{gd_escape(title)} tests every keeper.", "Show me your bond!"],
		"win_line": "Well fought. Come talk again — I know a path you might have missed.",
		"after_lines": [
			"Still here? Good. Listen close:",
			"{gd_escape(hint)}",
		],
		"hint": "{gd_escape(hint)}",
	}}, {3 + i})""")

    if theme == "haunted":
        decor = """
	for p in [Vector2i(4, 6), Vector2i(15, 8), Vector2i(7, 12), Vector2i(12, 18)]:
		add_ground_prop(Tiles.TOMBSTONE, p, true)
"""
    elif theme == "beach":
        decor = """
	for p in [Vector2i(3, 8), Vector2i(16, 6), Vector2i(5, 16)]:
		add_ground_prop(Tiles.PALM, p, true)
"""
    elif theme in ("cave", "fire", "ice", "tower"):
        decor = """
	for p in [Vector2i(4, 7), Vector2i(15, 9), Vector2i(8, 15)]:
		add_ground_prop(Tiles.CRYSTAL, p, true)
"""
    elif theme == "psychic":
        decor = """
	for p in [Vector2i(5, 6), Vector2i(14, 7), Vector2i(10, 16)]:
		add_ground_prop(Tiles.CRYSTAL, p, true)
"""
    else:
        decor = """
	for p in [Vector2i(4, 8), Vector2i(15, 7), Vector2i(7, 15)]:
		place_bush(p)
	set_decor(Vector2i(12, 12), Tiles.MUSHROOM)
"""

    legends = {
        "haunted_manor3": ("umbrix", 28, "The crypt unseals. A shadow-lord answers the house call!"),
        "belltower3": ("stormraptor", 28, "Thunder crowns the spire. A storm-raptor claims the bells!"),
        "crystal_mines2": ("arcanexus", 30, "The crystal heart pulses. An arcane Harmon steps through!"),
        "starfall_crater": ("cosmindra", 42, "Starlight coagulates. COSMINDRA regards the crater as nest!"),
        "glacial_archive": ("cryoleth", 55, "Frost archives awaken. CRYOLETH thaws from a shelf of ice!"),
        "thunder_spire": ("thunderoc", 32, "The needle sings. THUNDEROC dives from a black cloud!"),
        "clockwork_vault": ("tesloom", 38, "Gears lock. TESLOOM — living dynamo — steps from the vault!"),
        "bonebridge": ("voidmonarch", 46, "Across the ribs, VOIDMONARCH waits with a courtier's bow."),
        "cloud_garden": ("stratoson", 44, "Clouds part. STRATOSON blooms above the terrace!"),
        "moonlit_lake": ("leviaqua", 30, "The lake silver-boils. LEVIAQUA surfaces under the moon!"),
        "forgotten_library": ("somnarch", 36, "Books slam shut. SOMNARCH — dream-librarian — opens an eye!"),
    }
    legend = ""
    if rid in legends:
        lid, llv, ltxt = legends[rid]
        legend = f"""
	add_legend_encounter(Vector2i(9, 6), "{lid}", {llv},
		"{gd_escape(ltxt)}")
"""

    salve = "super_salve" if lo < 30 else "max_salve"
    return f'''extends "res://scripts/world/overworld.gd"

## {title.upper()} — discoverable themed area.


func _build_map() -> void:
	map_w = 20
	map_h = 24
	default_spawn = Vector2i(9, 22)
	encounter_table = "{rid}"

	fill_ground(0, 0, map_w - 1, map_h - 1, {ground})
{border_h}
	for y in range(0, map_h):
		set_ground(Vector2i(9, y), {path})
		set_ground(Vector2i(10, y), {path})
	for x in range(3, 17):
		set_ground(Vector2i(x, 12), {path})
{parent_warps}{next_warps}
	_brush_patch(2, 8, 7, 14)
	_brush_patch(12, 8, 17, 14)
	_brush_patch(3, 16, 8, 21)
	_brush_patch(12, 3, 16, 7)
{decor}
	add_interact(Vector2i(9, 21), {{ "type": "sign", "text": "{gd_escape(title.upper())} - {gd_escape(blurb)}" }})
{''.join(trainers_src)}
{legend}
	add_npc(Vector2i(11, 20), "left", Color(1, 1, 1), {{
		"type": "npc",
		"lines": [
			"{gd_escape(blurb)}",
			"Beat the keepers here — talk to them again for path rumors.",
		],
	}}, Tiles.TRAINER_PATHS[{abs(hash(rid)) % 10}], 1)


func _place_pickups() -> void:
	add_pickup(Vector2i(3, 19), "echo_capsule", {1 + lo // 12})
	add_pickup(Vector2i(16, 5), "heart_salve", {1 + lo // 15})
	add_pickup(Vector2i(4, 9), "great_capsule", {max(1, 1 + lo // 18)})
	add_pickup(Vector2i(17, 18), "{salve}", 1)


func _brush_patch(x0: int, y0: int, x1: int, y1: int) -> void:
	for x in range(x0, x1 + 1):
		for y in range(y0, y1 + 1):
			if not is_blocked(Vector2i(x, y)) and not warps.has(Vector2i(x, y)):
				place_tall_grass(Vector2i(x, y), {brush})
'''


# Hub attachment: child_id -> (parent_map, gate_flags or None, note)
# Warps placed on parent pointing INTO child at (9,22). Return warps handled in child.
HUBS = {
    "willow_fen": ("route1", None, "east thicket"),
    "scarlet_orchard": ("route1", None, "west grove"),
    "mushroom_grotto": ("route2", None, "east hollow"),
    "haunted_manor1": ("route2", ["trainer_r2_rival"], "shuttered east manor"),
    "belltower1": ("desert1", ["trainer_gym_grass"], "ruined tower north-east"),
    "ember_forge": ("desert2", None, "smithy side path"),
    "salt_catacombs": ("desert3", ["trainer_gym_desert"], "salt stairs"),
    "vine_cathedral": ("jungle1", None, "living nave"),
    "crystal_mines1": ("jungle2", None, "sparkling seam"),
    "thornwall_keep": ("jungle3", ["trainer_j3_rival"], "briar fort"),
    "whispering_gallery": ("cave1", None, "echoing side hall"),
    "coral_cathedral": ("beach1", None, "reef spires"),
    "sunken_ruins": ("tide_town", None, "drowned plaza"),
    "moonlit_lake": ("tide_town", None, "silver lake"),
    "thunder_spire": ("storm1", ["trainer_gym_storm"], "lightning needle"),
    "mirror_marsh": ("psychic_town", None, "still pools"),
    "forgotten_library": ("psychic1", ["trainer_gym_psychic"], "lost stacks"),
    "windmill_ridge": ("town", ["trainer_champion"], "ridge mills"),
    "abandoned_lab": ("town", ["trainer_champion"], "archive annex"),
    "starfall_crater": ("ashpeak1", ["story_complete"], "star bruise"),
    "cloud_garden": ("skyreach1", ["legend_skysovereign"], "floating terraces"),
    "bonebridge": ("graveyard1", None, "rib causeway"),
    "aurora_cliff": ("frostvale1", ["legend_hallowraith"], "light cliffs"),
    "glacial_archive": ("frostvale1", ["legend_hallowraith"], "ice library"),
}


def write_scene(map_id: str) -> None:
    SCENES.mkdir(parents=True, exist_ok=True)
    (SCENES / f"{map_id}.tscn").write_text(
        f"""[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/world/{map_id}.gd" id="1"]

[node name="{map_id}" type="Node2D"]
script = ExtResource("1")
""",
        encoding="utf-8",
    )


def patch_router(ids: list[str]) -> None:
    text = ROUTER.read_text(encoding="utf-8")
    marker = '\t"deeprift1": "res://scenes/world/deeprift1.tscn",\n}'
    if "willow_fen" in text:
        print("router already patched")
        return
    extra = "".join(
        f'\t"{i}": "res://scenes/world/{i}.tscn",\n' for i in ids
    )
    if marker not in text:
        raise SystemExit("router marker missing")
    ROUTER.write_text(text.replace(marker, f'\t"deeprift1": "res://scenes/world/deeprift1.tscn",\n\t# --- discovery atlas ---\n{extra}}}'), encoding="utf-8")


def patch_encounters(by_res: dict[str, list[str]], routes: list[dict]) -> None:
    data = json.loads(ENC_PATH.read_text(encoding="utf-8"))
    for r in routes:
        data[r["id"]] = encounter_block(by_res, r)
    ENC_PATH.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


def inject_hub_warp(parent: str, child: str, gate: list | None, label: str) -> None:
    path = SCRIPTS / f"{parent}.gd"
    if not path.exists():
        print(f"skip missing parent {parent}")
        return
    text = path.read_text(encoding="utf-8")
    marker = f'warp_to_{child}'
    if marker in text or f'"{child}"' in text and f'add_warp' in text and child in text:
        # crude: if child already referenced as warp target, skip
        if f'"{child}"' in text:
            print(f"hub {parent} already links {child}")
            return

    # Prefer east edge cells that vary by hash to reduce overlap
    h = abs(hash(child))
    if parent == "town":
        # north-east / north-west side spurs on path row
        cells = [(24, 8), (24, 9)] if "lab" in child or "abandoned" in child else [(1, 8), (1, 9)]
        spawn_back = (23, 8) if cells[0][0] == 24 else (2, 8)
    elif parent in ("route1", "route2"):
        cells = [(16, 8 + h % 3), (16, 9 + h % 3)] if "manor" in child or "mushroom" in child or "willow" in child else [(1, 8 + h % 3), (1, 9 + h % 3)]
        # route1 width 20-ish — check
        cells = [(map_edge_x(parent), 10), (map_edge_x(parent), 11)]
        if child in ("scarlet_orchard",):
            cells = [(1, 10), (1, 11)]
        spawn_back = (cells[0][0] - 1 if cells[0][0] > 5 else cells[0][0] + 1, cells[0][1])
    else:
        # east side spur
        cells = [(18, 10), (18, 11)]
        if h % 2 == 0:
            cells = [(1, 10), (1, 11)]
        spawn_back = (cells[0][0] - 1 if cells[0][0] > 5 else cells[0][0] + 1, cells[0][1])

    gate_arg = "[]"
    blocked = ""
    if gate:
        gate_arg = "[" + ", ".join(f'"{g}"' for g in gate) + "]"
        blocked = f',\n\t\t"{gd_escape(label)} still sleeps. Progress the story further.")'
        # fix formatting — use full warp calls
    req = gate_arg
    blocked_txt = f'{label} is sealed for now...' if gate else ""

    block = f"""
	# discovery: {child}
	set_ground(Vector2i({cells[0][0]}, {cells[0][1]}), Tiles.PATH)
	set_ground(Vector2i({cells[1][0]}, {cells[1][1]}), Tiles.PATH)
	add_warp(Vector2i({cells[0][0]}, {cells[0][1]}), "{child}", Vector2i(9, 22), "right" if {cells[0][0]} > 10 else "left", {req}, "{gd_escape(blocked_txt) if blocked_txt else gd_escape(label + ' — a side path.')}")
	add_warp(Vector2i({cells[1][0]}, {cells[1][1]}), "{child}", Vector2i(10, 22), "right" if {cells[0][0]} > 10 else "left", {req}, "{gd_escape(blocked_txt) if blocked_txt else gd_escape(label + ' — a side path.')}")
	add_interact(Vector2i({spawn_back[0]}, {spawn_back[1]}), {{ "type": "sign", "text": "{gd_escape(label.upper())} - side path to a unique area." }})
"""
    # Fix invalid GDScript ternary in string — rewrite properly
    facing = "right" if cells[0][0] > 10 else "left"
    bt = blocked_txt if blocked_txt else f"{label} — a side path."
    block = f"""
	# discovery: {child}
	set_ground(Vector2i({cells[0][0]}, {cells[0][1]}), Tiles.PATH)
	set_ground(Vector2i({cells[1][0]}, {cells[1][1]}), Tiles.PATH)
	add_warp(Vector2i({cells[0][0]}, {cells[0][1]}), "{child}", Vector2i(9, 22), "{facing}", {req}, "{gd_escape(bt)}")
	add_warp(Vector2i({cells[1][0]}, {cells[1][1]}), "{child}", Vector2i(10, 22), "{facing}", {req}, "{gd_escape(bt)}")
	add_interact(Vector2i({spawn_back[0]}, {spawn_back[1]}), {{ "type": "sign", "text": "SIDE PATH - {gd_escape(label)}." }})
"""

    # Insert before last function or at end of _build_map — find _place_pickups or end of _build_map
    if "func _place_pickups" in text:
        text = text.replace("func _place_pickups", block + "\nfunc _place_pickups", 1)
    elif "func _brush_patch" in text:
        text = text.replace("func _brush_patch", block + "\nfunc _brush_patch", 1)
    elif "func _grass_patch" in text:
        text = text.replace("func _grass_patch", block + "\nfunc _grass_patch", 1)
    else:
        # append before final helper or at EOF inside _build_map — fallback append at end of file with note
        text = text.rstrip() + "\n" + block + "\n"
        print(f"warning: appended hub block awkwardly for {parent}->{child}")
    path.write_text(text, encoding="utf-8")
    print(f"linked {parent} -> {child} at {cells}")


def map_edge_x(parent: str) -> int:
    widths = {
        "route1": 19, "route2": 17, "town": 24,
        "desert1": 19, "desert2": 19, "desert3": 19,
        "jungle1": 19, "jungle2": 19, "jungle3": 19,
        "cave1": 19, "beach1": 19, "tide_town": 19,
        "storm1": 19, "psychic_town": 19, "psychic1": 19,
        "graveyard1": 19, "ashpeak1": 19, "skyreach1": 19, "frostvale1": 19,
    }
    return widths.get(parent, 18)


def main() -> None:
    by_res = load_echoes_by_res()
    # Validate legend IDs exist
    all_ids = {e for ids in by_res.values() for e in ids}
    for r in ROUTES:
        pass

    parent_of: dict[str, str] = {}
    for child, (parent, _g, _l) in HUBS.items():
        parent_of[child] = parent
    # chain parents
    for r in ROUTES:
        if r.get("next"):
            parent_of[r["next"]] = r["id"]

    for r in ROUTES:
        parent = parent_of.get(r["id"])
        src = render_map_clean(r, by_res, parent)
        (SCRIPTS / f"{r['id']}.gd").write_text(src, encoding="utf-8")
        write_scene(r["id"])
        print("wrote", r["id"], "parent=", parent)

    patch_router([r["id"] for r in ROUTES])
    patch_encounters(by_res, ROUTES)

    for child, (parent, gate, label) in HUBS.items():
        inject_hub_warp(parent, child, gate, label)

    print("done", len(ROUTES), "routes")


if __name__ == "__main__":
    main()
