#!/usr/bin/env python3
"""Place wave-2 Harmons into encounter tables."""
import json
from pathlib import Path

ROOT = Path(r"c:\Users\smyde\memoir\echo-valley")
enc_path = ROOT / "data" / "encounters.json"
enc = json.loads(enc_path.read_text(encoding="utf-8"))

placements = {
    "route1": [
        ("chirplet", 6, 4, 6),
        ("seedbit", 5, 4, 6),
        ("bubkit", 5, 4, 6),
        ("boltkit", 4, 5, 7),
    ],
    "route2": [
        ("scrapkit", 6, 7, 10),
        ("pebbit", 5, 8, 11),
        ("cindbit", 5, 8, 11),
        ("psybit", 4, 9, 11),
    ],
    "beach1": [
        ("merin", 8, 11, 14),
        ("scallapod", 7, 11, 14),
        ("maluga", 4, 13, 16),
        ("foamjaw", 5, 12, 15),
    ],
    "storm1": [
        ("spaero", 8, 17, 21),
        ("coilfox", 6, 18, 22),
        ("kackaburr", 6, 18, 22),
        ("voltforge", 3, 20, 23),
    ],
    "desert3": [
        ("ruffalo", 7, 15, 18),
        ("fuzall", 6, 15, 18),
        ("flarebit", 5, 16, 19),
        ("junkjaw", 5, 16, 19),
    ],
    "jungle2": [
        ("burrlock", 8, 15, 18),
        ("thorncap", 6, 16, 19),
        ("briarthorn", 3, 18, 21),
    ],
    "psychic1": [
        ("grimlit", 7, 27, 31),
        ("howler", 6, 28, 32),
        ("orbkit", 5, 28, 32),
        ("mindforge", 3, 30, 33),
    ],
    "graveyard1": [
        ("glimbit", 6, 39, 43),
        ("shadecap", 5, 40, 44),
        ("voidhelm", 3, 42, 46),
        ("leechrex", 3, 43, 46),
    ],
    "ashpeak1": [
        ("ashcoloss", 6, 42, 47),
        ("cindbit", 5, 40, 44),
        ("flarebit", 5, 41, 45),
    ],
    "skyreach1": [
        ("kackaburr", 7, 45, 50),
        ("nimbrawl", 6, 46, 51),
        ("chirplet", 4, 44, 48),
    ],
}

echo_ids = {e["id"] for e in json.loads((ROOT / "data" / "echoes.json").read_text(encoding="utf-8"))}
added = 0
for table, rows in placements.items():
    if table not in enc:
        continue
    have = {e["id"] for e in enc[table]["encounters"]}
    for eid, w, lo, hi in rows:
        if eid not in echo_ids or eid in have:
            continue
        enc[table]["encounters"].append({
            "id": eid, "weight": w, "level_min": lo, "level_max": hi
        })
        have.add(eid)
        added += 1

enc_path.write_text(json.dumps(enc, indent=2) + "\n", encoding="utf-8")
uids = {e["id"] for t in enc.values() for e in t["encounters"]}
print(f"placements +{added}; unique encounter ids {len(uids)}; tables {len(enc)}")
