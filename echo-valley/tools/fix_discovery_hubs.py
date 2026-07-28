#!/usr/bin/env python3
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1] / "scripts" / "world"

FIXES = {
    "route1": [
        ("willow_fen", [(18, 10), (19, 10), (18, 11), (19, 11)], [(19, 10), (19, 11)], "right", [],
         "WILLOW FEN - misty east thicket."),
        ("scarlet_orchard", [(1, 10), (2, 10), (1, 11), (2, 11)], [(1, 10), (1, 11)], "left", [],
         "SCARLET ORCHARD - west fruit grove."),
    ],
    "desert1": [
        ("belltower1", [(17, 10), (18, 10), (17, 11), (18, 11)], [(18, 10), (18, 11)], "right",
         ["trainer_gym_grass"], "BELLTOWER - climb after Meadow Sigil."),
    ],
    "desert2": [
        ("ember_forge", [(1, 10), (2, 10), (1, 11), (2, 11)], [(1, 10), (1, 11)], "left", [],
         "EMBER FORGE - abandoned smithy."),
    ],
    "desert3": [
        ("salt_catacombs", [(21, 10), (22, 10), (21, 11), (22, 11)], [(22, 10), (22, 11)], "right",
         ["trainer_gym_desert"], "SALT CATACOMBS - after Scorch Sigil."),
    ],
    "jungle1": [
        ("vine_cathedral", [(19, 10), (20, 10), (19, 11), (20, 11)], [(20, 10), (20, 11)], "right", [],
         "VINE CATHEDRAL - living nave."),
    ],
    "jungle2": [
        ("crystal_mines1", [(1, 10), (2, 10), (1, 11), (2, 11)], [(1, 10), (1, 11)], "left", [],
         "CRYSTAL MINES - sparkling seam."),
    ],
    "jungle3": [
        ("thornwall_keep", [(1, 10), (2, 10), (1, 11), (2, 11)], [(1, 10), (1, 11)], "left",
         ["trainer_j3_rival"], "THORNWALL KEEP - after Rival Sabo."),
    ],
    "cave1": [
        ("whispering_gallery", [(17, 10), (18, 10), (17, 11), (18, 11)], [(18, 10), (18, 11)], "right", [],
         "WHISPERING GALLERY - echoing side hall."),
    ],
    "beach1": [
        ("coral_cathedral", [(1, 10), (2, 10), (1, 11), (2, 11)], [(1, 10), (1, 11)], "left", [],
         "CORAL CATHEDRAL - reef spires."),
    ],
    "tide_town": [
        ("sunken_ruins", [(1, 10), (2, 10), (1, 11), (2, 11)], [(1, 10), (1, 11)], "left", [],
         "SUNKEN RUINS - drowned plaza."),
        ("moonlit_lake", [(17, 10), (18, 10), (17, 11), (18, 11)], [(18, 10), (18, 11)], "right", [],
         "MOONLIT LAKE - silver water."),
    ],
    "storm1": [
        ("thunder_spire", [(17, 10), (18, 10), (17, 11), (18, 11)], [(18, 10), (18, 11)], "right",
         ["trainer_gym_storm"], "THUNDER SPIRE - after Charge Sigil."),
    ],
    "psychic_town": [
        ("mirror_marsh", [(17, 10), (18, 10), (17, 11), (18, 11)], [(18, 10), (18, 11)], "right", [],
         "MIRROR MARSH - still pools."),
    ],
    "psychic1": [
        ("forgotten_library", [(1, 10), (2, 10), (1, 11), (2, 11)], [(1, 10), (1, 11)], "left",
         ["trainer_gym_psychic"], "FORGOTTEN LIBRARY - after Dream Sigil."),
    ],
    "ashpeak1": [
        ("starfall_crater", [(17, 10), (18, 10), (17, 11), (18, 11)], [(18, 10), (18, 11)], "right",
         ["story_complete"], "STARFALL CRATER - post-fate bruise."),
    ],
    "skyreach1": [
        ("cloud_garden", [(1, 10), (2, 10), (1, 11), (2, 11)], [(1, 10), (1, 11)], "left",
         ["legend_skysovereign"], "CLOUD GARDEN - after SKYSOVEREIGN."),
    ],
    "graveyard1": [
        ("bonebridge", [(17, 10), (18, 10), (17, 11), (18, 11)], [(18, 10), (18, 11)], "right", [],
         "BONEBRIDGE - rib causeway."),
    ],
    "frostvale1": [
        ("aurora_cliff", [(1, 10), (2, 10), (1, 11), (2, 11)], [(1, 10), (1, 11)], "left",
         ["legend_hallowraith"], "AURORA CLIFF - after HALLOWRAITH."),
        ("glacial_archive", [(17, 10), (18, 10), (17, 11), (18, 11)], [(18, 10), (18, 11)], "right",
         ["legend_hallowraith"], "GLACIAL ARCHIVE - after HALLOWRAITH."),
    ],
}

RETURNS = {
    "willow_fen": ("route1", (17, 10)),
    "scarlet_orchard": ("route1", (3, 10)),
    "mushroom_grotto": ("route2", (15, 10)),
    "haunted_manor1": ("route2", (3, 14)),
    "belltower1": ("desert1", (16, 10)),
    "ember_forge": ("desert2", (3, 10)),
    "salt_catacombs": ("desert3", (20, 10)),
    "vine_cathedral": ("jungle1", (18, 10)),
    "crystal_mines1": ("jungle2", (3, 10)),
    "thornwall_keep": ("jungle3", (3, 10)),
    "whispering_gallery": ("cave1", (16, 10)),
    "coral_cathedral": ("beach1", (3, 10)),
    "sunken_ruins": ("tide_town", (3, 10)),
    "moonlit_lake": ("tide_town", (16, 10)),
    "thunder_spire": ("storm1", (16, 10)),
    "mirror_marsh": ("psychic_town", (16, 10)),
    "forgotten_library": ("psychic1", (3, 10)),
    "windmill_ridge": ("town", (4, 14)),
    "abandoned_lab": ("town", (21, 8)),
    "starfall_crater": ("ashpeak1", (16, 10)),
    "cloud_garden": ("skyreach1", (3, 10)),
    "bonebridge": ("graveyard1", (16, 10)),
    "aurora_cliff": ("frostvale1", (3, 10)),
    "glacial_archive": ("frostvale1", (16, 10)),
}


def esc(s: str) -> str:
    return s.replace("\\", "\\\\").replace('"', '\\"')


def main() -> None:
    for parent, entries in FIXES.items():
        path = ROOT / f"{parent}.gd"
        text = path.read_text(encoding="utf-8")
        text2 = re.sub(r"\n\t# discovery:.*?(?=\nfunc |\Z)", "\n", text, flags=re.S)
        blocks = []
        for child, opens, warps, facing, gates, sign in entries:
            lines = [f"\n\t# discovery: {child}"]
            for c in opens:
                lines.append(f"\topen_passage(Vector2i({c[0]}, {c[1]}), Tiles.PATH)")
            gate = "[" + ", ".join(f'"{g}"' for g in gates) + "]" if gates else "[]"
            blocked = "Side path sealed for now..."
            for i, w in enumerate(warps):
                spawn = f"Vector2i({9 + i}, 22)"
                if gates:
                    lines.append(
                        f'\tadd_warp(Vector2i({w[0]}, {w[1]}), "{child}", {spawn}, "{facing}", {gate}, "{esc(blocked)}")'
                    )
                else:
                    lines.append(
                        f'\tadd_warp(Vector2i({w[0]}, {w[1]}), "{child}", {spawn}, "{facing}")'
                    )
            sx, sy = opens[0]
            sign_x = sx - 1 if facing == "right" else sx + 1
            lines.append(
                f'\tadd_interact(Vector2i({sign_x}, {sy}), {{ "type": "sign", "text": "{esc(sign)}" }})'
            )
            blocks.append("\n".join(lines) + "\n")
        block = "".join(blocks)
        if "func _place_pickups" in text2:
            text2 = text2.replace("func _place_pickups", block + "\nfunc _place_pickups", 1)
        elif "func _brush_patch" in text2:
            text2 = text2.replace("func _brush_patch", block + "\nfunc _brush_patch", 1)
        elif "func _grass_patch" in text2:
            text2 = text2.replace("func _grass_patch", block + "\nfunc _grass_patch", 1)
        else:
            raise SystemExit(f"no insert point {parent}")
        path.write_text(text2, encoding="utf-8")
        print("fixed hub", parent)

    for child, (parent, cell) in RETURNS.items():
        path = ROOT / f"{child}.gd"
        if not path.exists():
            print("missing", child)
            continue
        text = path.read_text(encoding="utf-8")
        text = re.sub(
            r'add_warp\(Vector2i\(9, 23\), "[^"]+", Vector2i\(\d+, \d+\), "down"\)',
            f'add_warp(Vector2i(9, 23), "{parent}", Vector2i({cell[0]}, {cell[1]}), "down")',
            text,
            count=1,
        )
        text = re.sub(
            r'add_warp\(Vector2i\(10, 23\), "[^"]+", Vector2i\(\d+, \d+\), "down"\)',
            f'add_warp(Vector2i(10, 23), "{parent}", Vector2i({cell[0] + 1}, {cell[1]}), "down")',
            text,
            count=1,
        )
        path.write_text(text, encoding="utf-8")
        print("return", child, "->", parent, cell)


if __name__ == "__main__":
    main()
