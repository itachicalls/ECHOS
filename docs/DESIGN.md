# Echoheart — Game Design Document

**Working title:** Echoheart  
**Genre:** Cozy low-poly 3D creature-collection RPG  
**Platforms:** Mobile-first (iOS/Android), desktop for development  
**Players:** 1–2 (local foundation now; online later)

## Elevator Pitch

Two friends wander a small, handcrafted world of glowing valleys and quiet towns, discovering **Echoes** — living resonances of emotion and place. Catch them, bond with them, train them, and settle friendly rivalries in turn-based battles. Discovery first. Competition second. Friendship always.

## Emotional Pillars

1. **Discovery** — every zone hides something worth finding
2. **Collection** — Echoes feel personal, not checklist fodder
3. **Friendship** — bond with Echoes and with another player
4. **Competition** — fair, readable battles that reward preparation

## Tone & Feel

- Classic handheld RPG nostalgia without copying any existing IP
- Soft low-poly shapes, readable silhouettes, warm lighting
- Short sessions that still feel meaningful
- Charm over spectacle

## World Structure

Connected open zones (not seamless open world):

| Zone | Role |
|------|------|
| **Hearthmere** (town hub) | Rest, shop, NPCs, starters, save shrine |
| **Whisperwood** | First exploration, common Echoes, gentle encounters |
| **Glimmercave** | Mid-game types, status-focused Echoes |
| **Tideglass Shore** | Water Echoes, rare spawns at dusk |
| **Rare pockets** | One-off legendary-adjacent Echoes (post-slice) |

## Echoes (Creatures)

An **Echo** is a magical creature born from a place’s lingering feeling.

Each Echo has:
- **Name** — original, memorable
- **Resonance** (element/type)
- **Temperament** (personality) — affects flavor + minor battle quirks later
- **Stats** — HP, Power, Guard, Swift, Bond
- **Chimes** (abilities)
- **Harmonic Path** (evolution)
- **Silhouette** — unique low-poly design language

### Resonances (Types)

| Resonance | Strong vs | Weak vs |
|-----------|-----------|---------|
| Ember | Verdant, Frost | Tide, Stone |
| Tide | Ember, Stone | Verdant, Spark |
| Verdant | Tide, Stone | Ember, Gust |
| Spark | Tide, Gust | Stone, Ember |
| Stone | Spark, Gust | Tide, Verdant |
| Gust | Verdant, Ember | Spark, Stone |
| Shade | Gust, Spark | Ember, Verdant |
| Lumen | Shade, Frost | Shade*, Stone |
| Frost | Verdant, Gust | Ember, Stone |

\*Lumen vs Shade is mutual pressure — design favors readable rock-paper-scissors clusters, not a 9×9 nightmare.

### Starter Trio (Milestone 1)

| Name | Resonance | Temperament | Fantasy |
|------|-----------|-------------|---------|
| **Emberkit** | Ember | Bold | Tiny flame-fox with ember-tipped ears |
| **Tideling** | Tide | Gentle | Round water-droplet otter |
| **Mossprite** | Verdant | Curious | Leaf-crowned forest sprite |

Each evolves once in the vertical slice (or shows evolution UI stub with data ready).

## Core Loop

Explore → Encounter Echo → Battle / Bond → Train → Evolve → Challenge trainers → Explore further

**Bonding** (catching) uses a **Resonance Charm** after weakening — not a 1:1 ball clone. Flavor: attune your heart to theirs.

## Battle System

- Turn-based, **3 Echoes per team**
- Select Chime (move) each turn
- Resonance advantages (~1.5× / 0.66×)
- Status: Glowburn, Drench, Rooted, Static, Drowsy, Focused
- Switch Echoes (costs turn)
- XP on win; level-ups mid-battle queue after turn
- Evolution check after battle (or on level threshold)

## Multiplayer (Deferred Architecture)

Design for later; do not ship networking in M1:
- Trainer battles (async or realtime turn sync)
- Trading Echoes
- Friend codes / invites
- Co-op exploration (shared zone presence)

See `ARCHITECTURE.md` for session/service boundaries.

## Content Cap (Launch Scope Mindset)

- Max **20 Echoes** for early commercial slice
- 4–5 zones
- Clear starter path + rival + one gym-like “Resonance Trial”

## Non-Goals (M1)

- Full online multiplayer
- Crafting economy
- Open-world streaming
- Photoreal graphics
- Complex skill trees
