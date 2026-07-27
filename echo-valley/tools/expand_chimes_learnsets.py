#!/usr/bin/env python3
"""Add a large wave of new chimes and extend learnsets to high levels."""
import json
from pathlib import Path

ROOT = Path(r"c:\Users\smyde\memoir\echo-valley")
CHIMES = ROOT / "data" / "chimes.json"
ECHOES = ROOT / "data" / "echoes.json"

NEW = [
    # FIRE
    ("wildfire_nova", "Wildfire Nova", "fire", "attack", 88, 0.9, "A blooming nova of wildfire."),
    ("phoenix_dive", "Phoenix Dive", "fire", "attack", 95, 0.88, "Dive from flame and rise again."),
    ("solar_cataclysm", "Solar Cataclysm", "fire", "attack", 110, 0.82, "A sun-crushing finale."),
    ("magma_mortar", "Magma Mortar", "fire", "attack", 78, 0.92, "Lob molten shells."),
    ("cinder_barrage", "Cinder Barrage", "fire", "attack", 70, 0.95, "A storm of cinders."),
    ("heat_mirage", "Heat Mirage", "fire", "buff", 0, 1.0, "Raise Swift in shimmering heat."),
    # WATER
    ("maelstrom_spin", "Maelstrom Spin", "water", "attack", 86, 0.9, "Spin into a crushing whirl."),
    ("abyss_pressure", "Abyss Pressure", "water", "attack", 94, 0.88, "Crush with trench pressure."),
    ("ocean_collapse", "Ocean Collapse", "water", "attack", 112, 0.8, "The sea itself falls."),
    ("foam_lance", "Foam Lance", "water", "attack", 72, 0.95, "A spear of hardened foam."),
    ("riptide_rush", "Riptide Rush", "water", "attack", 68, 0.97, "A rushing undertow strike."),
    ("tide_ward", "Tide Ward", "water", "buff", 0, 1.0, "Raise Guard with the tide."),
    # GRASS
    ("bloom_barrage", "Bloom Barrage", "grass", "attack", 84, 0.92, "Petals become blades."),
    ("verdant_judgment", "Verdant Judgment", "grass", "attack", 96, 0.88, "Nature's verdict."),
    ("gaia_rupture", "Gaia Rupture", "grass", "attack", 110, 0.82, "The land ruptures green."),
    ("thorn_orbit", "Thorn Orbit", "grass", "attack", 74, 0.95, "Thorns orbit then strike."),
    ("pollen_bomb", "Pollen Bomb", "grass", "attack", 66, 0.95, "Explosive pollen burst."),
    ("photosurge", "Photosurge", "grass", "heal", 0, 1.0, "Heal in a surge of light."),
    # ROCK
    ("tectonic_slam", "Tectonic Slam", "rock", "attack", 90, 0.88, "A plate-shifting slam."),
    ("mountain_fall", "Mountain Fall", "rock", "attack", 98, 0.85, "Drop a mountain."),
    ("world_fracture", "World Fracture", "rock", "attack", 115, 0.78, "Crack the world open."),
    ("crystal_barrage", "Crystal Barrage", "rock", "attack", 76, 0.93, "Shards rain down."),
    ("fault_line", "Fault Line", "rock", "attack", 80, 0.9, "Split the ground."),
    ("iron_bulwark", "Iron Bulwark", "rock", "buff", 0, 1.0, "Raise Guard sharply."),
    # AIR
    ("cyclone_spin", "Cyclone Spin", "air", "attack", 85, 0.92, "A spinning cyclone."),
    ("tempest_crown", "Tempest Crown", "air", "attack", 97, 0.88, "Crown the foe in storm."),
    ("sky_sovereign_blow", "Sky Sovereign Blow", "air", "attack", 112, 0.8, "The sky's final decree."),
    ("wind_shear", "Wind Shear", "air", "attack", 70, 0.97, "A shearing blade of wind."),
    ("jet_stream", "Jet Stream", "air", "attack", 64, 1.0, "Ride the jet stream in."),
    ("tailwind", "Tailwind", "air", "buff", 0, 1.0, "Raise Swift for the team."),
    # SHADOW
    ("void_rift", "Void Rift", "shadow", "attack", 88, 0.9, "Tear a rift of void."),
    ("reaper_scythe", "Reaper Scythe", "shadow", "attack", 98, 0.86, "A scythe of night."),
    ("eclipse_finale", "Eclipse Finale", "shadow", "attack", 114, 0.8, "Black out the sun."),
    ("nightmare_coil", "Nightmare Coil", "shadow", "attack", 76, 0.92, "Coil of living nightmare."),
    ("soul_siphon", "Soul Siphon", "shadow", "attack", 70, 0.95, "Drain the foe's soul."),
    ("shade_cloak", "Shade Cloak", "shadow", "buff", 0, 1.0, "Raise Guard in shadow."),
    # ELECTRIC
    ("plasma_lance", "Plasma Lance", "electric", "attack", 90, 0.9, "A lance of plasma."),
    ("storm_monarch", "Storm Monarch", "electric", "attack", 100, 0.86, "Claim the storm's throne."),
    ("zero_point_arc", "Zero-Point Arc", "electric", "attack", 116, 0.78, "An arc that unmakes."),
    ("ion_barrage", "Ion Barrage", "electric", "attack", 74, 0.95, "A rain of ions."),
    ("static_nova", "Static Nova", "electric", "attack", 82, 0.92, "A nova of static."),
    ("overcharge", "Overcharge", "electric", "buff", 0, 1.0, "Raise Power dangerously."),
    # PSYCHIC
    ("dream_collapse", "Dream Collapse", "psychic", "attack", 96, 0.88, "Collapse the dreamspace."),
    ("chorus_singularity", "Chorus Singularity", "psychic", "attack", 118, 0.78, "The Chorus becomes a point."),
    ("orbit_crush", "Orbit Crush", "psychic", "attack", 84, 0.9, "Crush with orbital force."),
    ("mirage_barrage", "Mirage Barrage", "psychic", "attack", 72, 0.95, "Illusions strike as one."),
    ("thought_spike", "Thought Spike", "psychic", "attack", 68, 0.97, "A spike of pure thought."),
    ("mind_fortress", "Mind Fortress", "psychic", "buff", 0, 1.0, "Raise Guard of the mind."),
    # NORMAL / multi
    ("nova_burst", "Nova Burst", "none", "attack", 80, 0.92, "A colorless nova."),
    ("barrage", "Barrage", "none", "attack", 65, 0.98, "A relentless barrage."),
    ("orbit_strike", "Orbit Strike", "none", "attack", 70, 0.95, "Strike from every angle."),
    ("quake_pulse", "Quake Pulse", "rock", "attack", 75, 0.93, "A pulsing quake."),
    ("mirror_shard", "Mirror Shard", "psychic", "attack", 60, 1.0, "Shatter mirrored light."),
    ("hex_nova", "Hex Nova", "shadow", "attack", 85, 0.9, "A nova of hexes."),
]

# aliases for moves that may already exist under different names
ALIASES_CHECK = {
    "bubble_pop": ["bubble", "bubble_pop", "splash"],
    "leaf_cut": ["leaf_cut", "razor_leaf", "leaf_slash"],
    "pebble_toss": ["pebble_toss", "rock_toss", "stone_chip"],
    "gust": ["gust", "breeze"],
    "shadow_nip": ["shadow_nip", "shade_nip", "night_nip"],
    "aqua_slash": ["aqua_slash", "water_slash"],
    "stone_bash": ["stone_bash", "rock_bash"],
    "wing_slash": ["wing_slash", "air_slash"],
    "night_slash": ["night_slash", "shadow_slash"],
    "quake_stomp": ["quake_stomp", "stomp", "tremor"],
    "inferno_pulse": ["inferno_pulse", "inferno"],
    "tide_surge": ["tide_surge", "surge"],
    "spore_cloud": ["spore_cloud", "spore"],
    "boulder_crash": ["boulder_crash", "boulder"],
    "gale_force": ["gale_force", "gale"],
    "sky_dive": ["sky_dive", "dive"],
    "curse_wail": ["curse_wail", "wail"],
}


def main():
    chimes = json.loads(CHIMES.read_text(encoding="utf-8"))
    by_id = {c["id"]: c for c in chimes}

    # Ensure basic learnset seeds exist (map to existing if needed)
    seed_fallbacks = {
        "bubble_pop": "splash" if "splash" in by_id else "tackle",
        "leaf_cut": "razor_leaf" if "razor_leaf" in by_id else "tackle",
        "pebble_toss": "rock_toss" if "rock_toss" in by_id else "tackle",
        "gust": "breeze" if "breeze" in by_id else "tackle",
        "shadow_nip": "shade_nip" if "shade_nip" in by_id else "tackle",
        "aqua_slash": "water_slash" if "water_slash" in by_id else "tackle",
        "stone_bash": "rock_smash" if "rock_smash" in by_id else "tackle",
        "wing_slash": "air_slash" if "air_slash" in by_id else "tackle",
        "night_slash": "shadow_claw" if "shadow_claw" in by_id else "tackle",
        "quake_stomp": "tremor" if "tremor" in by_id else "tackle",
        "inferno_pulse": "inferno" if "inferno" in by_id else "flame_wave",
        "tide_surge": "tide_wave" if "tide_wave" in by_id else "tackle",
        "spore_cloud": "spore_burst" if "spore_burst" in by_id else "tackle",
        "boulder_crash": "boulder_toss" if "boulder_toss" in by_id else "tackle",
        "gale_force": "gale" if "gale" in by_id else "tackle",
        "sky_dive": "dive" if "dive" in by_id else "tackle",
        "curse_wail": "wail" if "wail" in by_id else "hex_bolt",
        "ember_spark": "ember_spark",
        "fire_fang": "fire_fang",
        "flame_wave": "flame_wave",
        "spark_bite": "spark_bite",
        "thunder_bolt": "thunder_bolt",
        "shock_wave": "shock_wave",
        "volt_tackle": "volt_tackle",
        "psy_nudge": "psy_nudge" if "psy_nudge" in by_id else "psywave",
        "psy_beam": "psy_beam",
        "mind_crush": "mind_crush",
        "psi_pulse": "psi_pulse",
        "astral_gaze": "astral_gaze",
        "vine_lash": "vine_lash",
        "canopy_crash": "canopy_crash",
        "hex_bolt": "hex_bolt",
    }

    added = 0
    for row in NEW:
        cid, name, res, cat, power, acc, desc = row
        if cid in by_id:
            continue
        entry = {
            "id": cid,
            "name": name,
            "resonance": res,
            "category": cat,
            "power": power,
            "accuracy": acc,
            "description": desc,
        }
        if cat == "heal":
            entry["heal_pct"] = 0.45
        if cat == "buff":
            entry["stat"] = "swift" if "Swift" in desc or "swift" in desc.lower() or cid in ("heat_mirage", "tailwind", "jet_stream") else "guard" if "Guard" in desc or "ward" in cid or "fortress" in cid or "bulwark" in cid or "cloak" in cid else "power"
            entry["stages"] = 1
        if cid in ("soul_siphon",):
            entry["lifesteal"] = 0.45
        chimes.append(entry)
        by_id[cid] = entry
        added += 1

    # Ensure seed moves exist as aliases if missing
    for need, fallback in seed_fallbacks.items():
        if need not in by_id and fallback in by_id:
            src = dict(by_id[fallback])
            src["id"] = need
            src["name"] = need.replace("_", " ").title()
            chimes.append(src)
            by_id[need] = src
            added += 1
        elif need not in by_id:
            chimes.append({
                "id": need, "name": need.replace("_", " ").title(),
                "resonance": "none", "category": "attack", "power": 45,
                "accuracy": 1.0, "description": "A resonant strike.",
            })
            by_id[need] = chimes[-1]
            added += 1

    CHIMES.write_text(json.dumps(chimes, indent=2) + "\n", encoding="utf-8")
    print(f"chimes: +{added}, total {len(chimes)}")

    echoes = json.loads(ECHOES.read_text(encoding="utf-8"))
    high_by_res = {
        "fire": [("wildfire_nova", 40), ("phoenix_dive", 55), ("solar_cataclysm", 70), ("cinder_barrage", 32)],
        "water": [("maelstrom_spin", 40), ("abyss_pressure", 55), ("ocean_collapse", 70), ("riptide_rush", 32)],
        "grass": [("bloom_barrage", 40), ("verdant_judgment", 55), ("gaia_rupture", 70), ("thorn_orbit", 32)],
        "rock": [("tectonic_slam", 40), ("mountain_fall", 55), ("world_fracture", 70), ("crystal_barrage", 32)],
        "air": [("cyclone_spin", 40), ("tempest_crown", 55), ("sky_sovereign_blow", 70), ("wind_shear", 32)],
        "shadow": [("void_rift", 40), ("reaper_scythe", 55), ("eclipse_finale", 70), ("nightmare_coil", 32)],
        "electric": [("plasma_lance", 40), ("storm_monarch", 55), ("zero_point_arc", 70), ("ion_barrage", 32)],
        "psychic": [("dream_collapse", 40), ("chorus_singularity", 70), ("orbit_crush", 40), ("mirage_barrage", 32)],
    }

    extended = 0
    for e in echoes:
        res = e.get("resonance", "none")
        extras = high_by_res.get(res, [("nova_burst", 40), ("barrage", 32), ("orbit_strike", 50)])
        ls = e.setdefault("learnset", [])
        have = {x.get("chime") for x in ls}
        for cid, lv in extras:
            if cid in by_id and cid not in have:
                ls.append({"level": lv, "chime": cid})
                have.add(cid)
                extended += 1
        ls.sort(key=lambda x: (int(x.get("level", 1)), x.get("chime", "")))

    ECHOES.write_text(json.dumps(echoes, indent=2) + "\n", encoding="utf-8")
    print(f"learnset entries added: {extended}")


if __name__ == "__main__":
    main()
