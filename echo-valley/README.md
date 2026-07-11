# Echo Valley

A cozy pixel-art creature-collection RPG in the spirit of classic handheld monster games —
built from scratch with an original world, creatures ("Echoes"), and mechanics.

Built with **Godot 4.7** (2D) + GDScript. GBA-style resolution (240×160), grid movement,
tall-grass encounters, and turn-based battles.

## Play it

```bash
# from the echo-valley folder
npm run export:web   # exports the web build with Godot
npm run serve        # serves it at http://localhost:8080
# or both at once:
npm run play
```

Then open http://localhost:8080. You can also just open `project.godot` in the Godot editor
and press F5.

### Controls
- **Move:** WASD / Arrow keys (tile-by-tile, like classic Pokémon)
- **Interact / Confirm:** J / Space / Enter (talk to signs, heal at the Echo Rest)
- **Cancel:** K / Esc

## What's in this build
- **Title screen** with New Adventure, starter selection (Emberkit / Tideling / Mossling), Continue, and **Versus Battle**.
- **Echo Valley Town** — cottages, a pond, an Echo Rest (heals your team + saves), signs.
- **Route 1 & Route 2** — tall-grass meadows with wild encounters; Route 2 (Echowood) adds a pond, tougher wilds, and higher levels. Town → Route 1 → Route 2 all connect.
- **15 Echoes** across 6 resonances, with 3 evolution lines each side of the map (Pebblit→Craggan, Zephyr→Gustrel, Duskling→Nocturn, plus the three starters).
- **NPC trainers** — walk up and talk to challenge them; beat them once for an Echo Charm reward, and they remember they lost. Includes a recurring **Rival**.
- **Grid-based movement** with a 4-direction animated hero and a smooth follow camera.
- **Turn-based battles** — Fight (type-advantage chimes), switch Echoes, Catch (with a full throw/shake/capture animation), and Run.
- **Versus mode** — draft any 3 Echoes at Lv15 and battle an AI rival, standalone from your save.
- **Progression** — XP, leveling, and evolution (e.g. Emberkit → Flarefox at Lv12).
- **Save/Load** — autosaves on catch/heal/battle end; Continue from the title.

## Architecture
- `scripts/autoload/` — global singletons: `EventBus`, `EchoCatalog`, `GameState`, `SaveService`, `SceneRouter`.
- `scripts/core/` `scripts/creatures/` — data-driven Echo/Chime definitions + runtime instances.
- `scripts/combat/combat_resolver.gd` — **pure** turn logic (no nodes/UI) so it's testable and multiplayer-ready.
- `scripts/world/` — the overworld engine (`overworld.gd`) builds tilesets/maps in code; `town.gd`/`route1.gd` lay out each map.
- `scripts/player/` — grid movement + animation.
- `scripts/ui/` `scripts/battle/` `scripts/boot/` — HUD/dialogue, battle scene, title.
- `data/` — `echoes.json`, `chimes.json`, `encounters.json`. Add content here with no code changes.

## Content is data-driven
New Echoes, moves, and encounter tables are added by editing the JSON in `data/` —
stats, types, learnset, evolution, catch rate, and sprite path all live there.

## Multiplayer boundary (future)
`combat_resolver.gd` is a pure function of `(state, playerAction, enemyAction) -> state`, and
`SceneRouter.start_trainer_battle()` already exists. That's the seam for versus battles / co-op later.

See `CREDITS.md` for asset licenses.
