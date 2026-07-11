# Echoheart

Cozy low-poly 3D Echo-collection RPG built in **Godot 4.7**.

Discover **Echoes**, train them, evolve them, and clash in turn-based battles. Designed for friends and couples — discovery first, competition second.

## Quick Start

1. Install / open **Godot 4.7+**
2. Import this folder (`memoir` / project root)
3. Press **F5** (Play)

### Milestone 1 loop

1. **New Adventure** on the title screen  
2. In **Hearthmere**, walk to the three colored pedestals and press **E** to bond with a starter  
3. Use the **Save Shrine** (north) to heal & save  
4. Enter the **Whisperwood Gate** (south)  
5. Walk through tall grass to trigger wild battles  
6. Win for XP / level-ups / evolution at level 12  

### Controls

| Action | Input |
|--------|--------|
| Move | WASD / Arrows |
| Camera | Q / R, or hold RMB + mouse |
| Interact | E / Space |
| Quick save | Esc |

## Docs

- [Design](docs/DESIGN.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Roadmap](docs/ROADMAP.md)

## Project layout

```
data/          JSON definitions (Echoes, Chimes, encounters)
scenes/        Boot, world, battle, player, UI
scripts/       Autoloads, combat, creatures, exploration
docs/          Design & production docs
```

## Adding content

Drop a new Echo into `data/echoes/echoes.json` and optional chimes into `data/chimes/chimes.json`. No code changes required for basic creatures.

## Engine choice

Godot 4 — free, mobile-friendly, fast iteration, Resource/JSON data pipeline, and a clean path to multiplayer later without rewriting battle logic (`CombatResolver` is pure data).
