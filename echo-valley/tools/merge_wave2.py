#!/usr/bin/env python3
import json
from pathlib import Path

ROOT = Path(r"c:\Users\smyde\memoir\echo-valley")
echoes_path = ROOT / "data" / "echoes.json"
frag_path = ROOT / "tools" / "wave2_entries.json"

echoes = json.loads(echoes_path.read_text(encoding="utf-8"))
frag = json.loads(frag_path.read_text(encoding="utf-8"))
if isinstance(frag, dict):
    frag = [frag]
have = {e["id"] for e in echoes}
added = 0
for e in frag:
    if e["id"] in have:
        continue
    echoes.append(e)
    have.add(e["id"])
    added += 1
echoes_path.write_text(json.dumps(echoes, indent=2) + "\n", encoding="utf-8")
print(f"merged +{added}, total {len(echoes)}")
