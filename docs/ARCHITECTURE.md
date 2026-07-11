# Echoheart — Technical Architecture

## Recommended Engine: **Godot 4.x (GDScript)**

### Why Godot (not Unity / Unreal / custom)

| Criterion | Godot 4 | Unity | Unreal |
|-----------|---------|-------|--------|
| Mobile export | Excellent, light builds | Good, heavier | Overkill |
| Low-poly 3D | First-class | First-class | Overpowered |
| Indie cost | Free, no runtime fee | Install fees / terms risk | Free but heavy |
| Iteration speed | Very fast | Medium | Slow |
| Data-driven content | Resources + JSON | ScriptableObjects | Data assets |
| Multiplayer later | High-level multiplayer + ENet/WebRTC | Netcode packages | Advanced but complex |
| Team size fit | 1–3 indies | Fine | Studio-scale |

**Decision:** Godot 4.7 + GDScript + Resource-driven data.  
C# is available if we later need shared backend DTOs; start in GDScript for velocity.

---

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         App Shell                            │
│  Boot → SaveService → SceneRouter → Audio/UI services        │
└───────────────┬─────────────────────────────┬───────────────┘
                │                             │
        ┌───────▼────────┐            ┌───────▼────────┐
        │  Exploration   │            │    Battle      │
        │  (World scenes)│◄──handoff──►│  (Battle scene)│
        └───────┬────────┘            └───────┬────────┘
                │                             │
        ┌───────▼─────────────────────────────▼────────┐
        │              Game State (autoload)            │
        │  Party · Inventory · Flags · PlayerProfile    │
        └───────┬─────────────────────────────┬────────┘
                │                             │
        ┌───────▼────────┐            ┌───────▼────────┐
        │  Data Catalog  │            │  Save / Load   │
        │  EchoDefs etc. │            │  JSON slots    │
        └────────────────┘            └───────┬────────┘
                                              │
                                      ┌───────▼────────┐
                                      │ Multiplayer*   │
                                      │ (stub / later) │
                                      └────────────────┘
```

\*Multiplayer is a **port**, not a rewrite: battle and party operate on pure data models that can be owned locally or by a session authority.

---

## Folder Structure

```
echoheart/
├── project.godot
├── docs/
├── data/                      # Authorable content (JSON)
│   ├── echoes/
│   ├── chimes/
│   ├── encounters/
│   └── items/
├── resources/                 # Godot Resource wrappers / imported defs
├── scenes/
│   ├── boot/
│   ├── world/
│   │   ├── hearthmere_village.tscn
│   │   └── whisperwood.tscn
│   ├── player/
│   ├── battle/
│   └── ui/
├── scripts/
│   ├── autoload/              # Singletons
│   ├── core/                  # Types, enums, math
│   ├── creatures/             # Echo instance + catalog
│   ├── combat/                # Battle rules (pure-ish)
│   ├── exploration/           # Encounters, zones
│   ├── save/
│   ├── multiplayer/           # Stubs only in M1
│   ├── player/
│   └── ui/
├── assets/
│   ├── meshes/                # Placeholder CSG / glTF later
│   ├── materials/
│   ├── audio/
│   └── ui/
└── tests/                     # Optional GUT / script tests later
```

---

## Core Modules

### 1. Data Catalog (`EchoCatalog`)
- Loads JSON definitions at boot
- Immutable **EchoDefinition**, **ChimeDefinition**
- Runtime **EchoInstance** = definition_id + level + XP + current HP + temperament seed + IVs-lite

### 2. GameState (autoload)
- Party (max 3 active for battles; box later)
- Inventory (Resonance Charms, items)
- World flags / story beats
- Current zone id
- Emits signals: `party_changed`, `flags_changed`

### 3. SceneRouter
- Transitions: Village ↔ Forest ↔ Battle
- Passes `BattleRequest` payload (player party snapshot, wild/enemy party, context)
- Returns `BattleResult` (XP, captures, fainted flags)

### 4. Combat Engine (`BattleController` + `CombatResolver`)
- **CombatResolver** is pure logic: given state + action → new state + events
- **BattleController** drives UI, animations, input
- Enables headless simulation for AI, tests, and future netcode

### 5. Exploration
- Third-person `PlayerController`
- `FollowCamera`
- `EncounterField` areas (grass / mist) with weighted tables
- Zone portals

### 6. SaveService
- Slot-based JSON in `user://saves/`
- Versioned schema (`save_version`)
- Serializes GameState + player transform + zone

### 7. Multiplayer (stub)
- Interfaces only: `ISessionTransport`, `TradeOffer`, `FriendCode`
- No sockets in M1

---

## Data-Driven Content Example

```json
{
  "id": "emberkit",
  "name": "Emberkit",
  "resonance": "ember",
  "temperament": "bold",
  "base_stats": { "hp": 40, "power": 52, "guard": 40, "swift": 55, "bond": 45 },
  "chimes": ["ember_spark", "nuzzle", "warm_guard"],
  "evolve_to": "flarefox",
  "evolve_level": 16,
  "catch_rate": 0.35,
  "mesh": "res://assets/meshes/echoes/emberkit.tscn"
}
```

Adding a creature = new JSON + mesh scene. No code change.

---

## Battle Data Flow

```
Player selects Chime
  → BattleController validates
  → CombatResolver.resolve_turn(state, actions)
  → emits BattleEvents[] (damage, status, faint, switch)
  → UI plays events sequentially
  → check win/lose / capture prompt
```

---

## Mobile Optimization Principles

- Low-poly + baked-ish lighting (simple DirectionalLight + ambient)
- One active world scene at a time
- Object pooling for VFX later
- Combat is 2.5D stage (few draw calls)
- Texture atlases; avoid real-time GI
- Target: mid-range phones, 30–60 FPS

---

## Multiplayer-Ready Boundaries (Future)

| System | Local now | Online later |
|--------|-----------|--------------|
| Party ownership | GameState | Server-authoritative inventory |
| Battle | Local CombatResolver | Host or dedicated resolves turns |
| Capture RNG | Local seeded RNG | Server seed + commit |
| Trade | N/A | Atomic swap transaction |
| Presence | Single player | Room / lobby service |

Do **not** put networking inside CombatResolver. Keep it pure.

---

## Scene Graph (M1)

1. `boot.tscn` — load catalog, save, go to village or continue
2. `hearthmere_village.tscn` — hub + starter pick + save shrine
3. `whisperwood.tscn` — exploration + encounters
4. `battle.tscn` — turn-based UI + stage
5. `ui/hud.tscn`, `ui/party.tscn`, `ui/dialogue.tscn`
