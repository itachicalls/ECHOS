#!/usr/bin/env python3
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ids = {e["id"] for e in json.loads((ROOT / "data/echoes.json").read_text(encoding="utf-8"))}
enc = json.loads((ROOT / "data/encounters.json").read_text(encoding="utf-8"))
missing = []
for mid, table in enc.items():
    for e in table.get("encounters", []):
        if e["id"] not in ids:
            missing.append((mid, e["id"]))
print("encounter missing", len(missing), missing[:15])

party_bad = []
for p in (ROOT / "scripts/world").glob("*.gd"):
    for m in re.finditer(r'"id": "([a-z0-9_]+)"', p.read_text(encoding="utf-8")):
        i = m.group(1)
        if i.endswith(("_t0", "_t1", "_t2")):
            continue
        # party member lines sit near "level"
        pass
    # extract party ids only
    for m in re.finditer(r'\{\s*"id": "([a-z0-9_]+)",\s*"level":', p.read_text(encoding="utf-8")):
        i = m.group(1)
        if i not in ids:
            party_bad.append((p.name, i))
print("party missing", len(party_bad), party_bad[:20])

router = (ROOT / "scripts/autoload/scene_router.gd").read_text(encoding="utf-8")
map_ids = re.findall(r'"([a-z0-9_]+)": "res://scenes/world/', router)
scenes = {p.stem for p in (ROOT / "scenes/world").glob("*.tscn")}
scripts = {p.stem for p in (ROOT / "scripts/world").glob("*.gd")}
print("router maps", len(map_ids))
print("missing scenes", [m for m in map_ids if m not in scenes])
print("missing scripts", [m for m in map_ids if m not in scripts])
print("enc tables missing for maps", [m for m in map_ids if m not in enc and m not in ("town", "tide_town", "psychic_town")])
