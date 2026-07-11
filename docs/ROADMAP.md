# Echoheart — Development Roadmap

## Milestone 1 — Vertical Slice (NOW)
**Goal:** Playable loop in one sitting.

- [x] Engine + project scaffold
- [ ] Third-person movement
- [ ] Follow camera
- [ ] Hearthmere village (low-poly placeholders)
- [ ] Whisperwood exploration zone + portal
- [ ] 3 starter Echoes (data + simple meshes)
- [ ] Wild encounter system
- [ ] Turn-based battle (attack, type chart, switch)
- [ ] XP + leveling
- [ ] Save / load
- [ ] Basic HUD + battle UI

**Exit criteria:** Start game → pick starter → explore forest → battle → gain XP → save → reload party intact.

---

## Milestone 2 — Collection Depth
- Resonance Charm capture flow after battle
- Party management UI (3 active)
- 7 more Echoes (total 10)
- Evolution after level threshold + short VFX
- Status effects (2–3)
- Items (potion-equivalent, charm)
- Trainer NPC battle
- Dialogue system

---

## Milestone 3 — World Expansion
- Glimmercave + Tideglass Shore
- Encounter tables per zone / time-of-day stub
- Rare spawn locations
- Town services (heal shrine, shop)
- Audio pass (footsteps, battle stings, ambient)
- Polish camera + mobile touch controls

---

## Milestone 4 — Content Complete (20 Echoes)
- Full 20 Echo roster + evolutions
- Resonance Trial (gym-like boss)
- Rival / friend NPC arc
- Balance pass on type chart + XP curve
- Accessibility (text size, colorblind type icons)

---

## Milestone 5 — Multiplayer Foundation
- Friend codes / lobby
- Ranked-free trainer battles (turn sync)
- Trading
- Anti-cheat basics (server validation of party legality)
- Co-op exploration prototype (optional presence)

---

## Milestone 6 — Ship Prep
- Performance on target devices
- Tutorials / onboarding
- Store pages, soft launch
- Analytics + crash reporting
- Live-ops hooks for new Echo JSON drops

---

## Hardest Technical Challenges

1. **Combat feel without complexity**  
   Readable turns, snappy UI, and satisfying feedback while keeping `CombatResolver` testable and netcode-ready.

2. **Data vs presentation split**  
   Echoes must be authorable as data; meshes/VFX must hot-swap without rewriting battle logic.

3. **Encounter pacing**  
   Too many battles = fatigue; too few = empty world. Needs tunable rates + “mercy” timers.

4. **Save schema evolution**  
   Versioned saves as content grows; never brick player parties.

5. **Mobile input + camera**  
   Third-person on touch is harder than keyboard; virtual stick + smart camera collision.

6. **Future multiplayer without rewrite**  
   Keeping battle/party as pure state machines is the cost we pay now to avoid a rewrite later.

7. **Creature identity at low-poly**  
   Silhouette, color, and animation must carry charm with almost no texture detail.
