# Space Intruders - Development Roadmap

## Development Priority: Polish First

---

## 1. Bugs (Known Issues)

- [ ] **Captured alien dive bomb behavior** — Captured alien slams directly into the player ship instead of engaging in a dogfight. Should behave as an adversarial encounter (strafing, evasion) rather than a kamikaze run.

---

## 2. Polish (Visual/Feel)

### Completed
- [x] HUD cleanup and layout optimization
  - [x] Compact SCORE tiles (3 GRAM)
  - [x] Compact CHAIN tiles (3 GRAM)
  - [x] Chain current/best display (N/N format)
  - [x] Tutorial text repositioned (row 9 centered, faster flash)
  - [x] Lives display styling (ship+X tile, spaced count)
- [x] Rogue Alien / Wingman revamp
  - [x] Mooninite-style sprite design
  - [x] Persistent across wave/pattern transitions
  - [x] Bullet sponge behavior (absorbs enemy fire)

### In Progress
- [ ] Color tuning and visual consistency
- [ ] Physics/collision refinement

### Backlog
- [ ] Active powerup indicator (see detailed spec below)
- [ ] Better wingman firing as partner (optional tuning)
- [ ] Impact pause / "dopamine moments" (see spec #7)
- [ ] Saucer animation refactor (see spec #11)

---

## 3. Balance (Difficulty Tuning)

**Current state:** Spiky/inconsistent — difficulty jumps around unpredictably.

### Tuning Levers

| Category | Variables | Current | Notes |
|----------|-----------|---------|-------|
| **March Speed** | `BaseMarchSpeed`, `CurrentMarchSpeed` | Per-wave base | Accelerates on descent |
| **Alien Bullets** | Fire rate, speed, count | ? | May need wave scaling |
| **Player Power** | Powerup duration, drop rate | Fixed? | Wingman is powerful |
| **Forgiveness** | Lives, invincibility frames | 3 lives | Post-respawn i-frames |
| **Alien Count** | Grid density per wave | Varies | Sparse = easier? |

### Balance Tasks
- [ ] Profile difficulty curve across waves 1-5
- [ ] Document current speed/fire-rate values per wave
- [ ] Identify specific "spike" moments (which wave? which event?)
- [ ] Tune march speed progression
- [ ] Tune alien fire rate progression
- [ ] Consider alien count → speed relationship (fewer aliens = faster)
- [ ] Playtest and iterate

### Design Questions
- Should remaining alien count affect march speed? (Classic SI behavior)
- Should powerups scale with difficulty or stay constant?
- Is wingman too powerful as bullet sponge?

---

## 4. Level Design (Waves & Patterns)

**Current scope:** Undecided — need more playtesting.

### Options

| Scope | Waves | Session Length | Notes |
|-------|-------|----------------|-------|
| Arcade | 5-8 | ~10 min | Quick sessions, high replayability |
| Medium | 10-15 | ~20 min | More progression, boss every 5 waves? |
| Endless | Loop | Until death | Waves repeat with scaling difficulty |

### Wave Content Tasks
- [ ] Define wave count target
- [ ] Design pattern variety (formations per wave)
- [ ] Place bosses (every N waves?)
- [ ] Plan wave entrance animations (see spec #9)
- [ ] Extended first wave / tutorial escalation (see spec #10)

### Current Patterns
_Document existing patterns here as reference._

---

## 5. Audio/Music

### Current State
- Background music: DNB track via PLAY SIMPLE
- SFX: Player shoot, alien death, explosions, powerup pickup, shield ping
- Intellivoice: Not currently used in gameplay

### Tasks
- [ ] Audit SFX variety (enough feedback for all events?)
- [ ] Consider wave-specific music variation
- [ ] Tune SFX volumes relative to music
- [ ] Intellivoice callouts? ("WAVE 3", "EXTRA LIFE", etc.)

### Ideas
- Victory fanfare on wave clear
- Tension music when few aliens remain
- Boss fight music

---

## 6. Performance

### Known Issues
- [ ] Saucer animation may cause frame drops
- [ ] Need to profile with debug border colors

### Optimization Targets
| Routine | Priority | Notes |
|---------|----------|-------|
| SaucerAnimate | High | Suspected CPU spike |
| Alien grid rendering | Medium | Especially with bosses |
| Collision detection loops | Medium | Multiple nested loops |
| DrawAliens shimmer | Low | Already uses dirty flag |

### Tools
- Debug mode (type "36"): BORDER color band shows CPU usage
- Assembly listing: Check compiled output for hot paths

### Future: CP1610 Assembly Optimization
See detailed spec #14 below — only pursue after feature-complete.

---

## 7. Features (Backlog)

### Near-Term
- [ ] Destructible barriers/shields (spec #2)
- [ ] Wave announcement transition (spec #6)
- [ ] Captured alien escape after 2 waves (spec #15)

### Medium-Term
- [ ] Boss fight (spec #3)
- [ ] Large sprite alien variants (spec #8)
- [ ] Wave entrance animations (spec #9)

### Stretch Goals
- [ ] Title screen: 3D rotating letters (spec #1)
- [ ] Player 2 controls Zod on title/game over (spec #4)
- [ ] Zod shoots away letters on game over (spec #5)
- [ ] Saucer explosion: escaping aliens (spec #12)

---

## Detailed Feature Specs

### Spec #0b: Active Powerup Indicator (HUD Polish)
**Current:** No visual indicator of active powerup in HUD.

**Options:**
| Style | GRAM Cost | Look |
|-------|-----------|------|
| 4 compact icons (B/R/Q/M) | 4 cards (reuse) | Matches CHAIN/SCORE style |
| GROM text labels | 0 cards | "BEAM"/"RAPID"/etc |
| Colored pip/dot | 1 card | Color-coded indicator |

**HUD placement:** Position 234-235 (gap between SCORE and lives)

**Variables:** 0 (use existing BeamTimer/RapidTimer/DualTimer/MegaTimer checks)

---

### Spec #1: Title Screen 3D Rotating Letters
**Concept:** Animate "SPACE INTRUDERS" with pseudo-3D rotation effect using GRAM reloading.

- Use existing 12 font GRAM slots (25-36)
- Precompute 6-8 rotation frames per letter in ROM
- DEFINE new frames each tick during title sequence
- Can reload 2-4 GRAM cards per WAIT without flicker

**ROM cost:** ~14 letters x 8 frames x 8 bytes = ~900 bytes
**GRAM cost:** 0 additional (reuses existing font slots)

---

### Spec #2: Destructible Barriers/Shields
**Concept:** Classic Space Invaders style barriers that erode when hit.

- Use 2-4 GRAM cards for barrier tile patterns
- Place barrier segments on BACKTAB between player and aliens
- On bullet hit: modify GRAM bitmap data directly at $3800+
- Punch "holes" in the bitmap where projectiles impact

**GRAM cost:** 2-4 cards (can use free slots 13, 41, 53)

---

### Spec #3: Boss Fight
**Concept:** Large boss enemy taking up ~1/3 of screen.

**Options:**
- Multi-sprite boss (4-6 MOBs)
- BACKTAB boss (larger, card-aligned)
- Hybrid (body on BACKTAB, weak points as sprites)

**Boss fight phases:**
1. Entrance (descends from top)
2. Attack patterns (projectiles, movement)
3. Weak point mechanics
4. Health bar display
5. Death sequence (explosion cascade)

---

### Spec #4: Player 2 Controls Zod (Title/Game Over)
- Read CONT1 (controller 2) disc input
- Switch from auto-pilot to manual control on input
- Revert to auto-pilot after ~3 seconds of no input

---

### Spec #5: Zod Shoots Away Letters (Game Over)
- Zod fires small projectile
- Check collision against BACKTAB text positions
- On hit: clear that BACKTAB position (letter disappears)
- Optional: show small explosion at hit position

---

### Spec #6: Wave Announcement Transition
**Concept:** Brief (~1 second) "WAVE X" with visual flair.

**Options:**
| Style | Complexity |
|-------|------------|
| DOS Tab Bounce | Medium |
| Wavy Text | Medium |
| Starfield Warp | High |
| Color Cascade | Low |

---

### Spec #7: Impact Pause / "Dopamine Moments"
**Concept:** Brief freeze-frame on significant events.

**Triggers:** Bomb alien final hit, skull boss death, saucer hit, extra life, wave clear, player death.

**Effects:**
- Color flash (alien cycles white/red)
- Screen shake (SCROLL offset oscillates ±1)
- Time freeze (all movement stops, only target animates)

**Cost:** 1 variable (`ImpactPause`), 5-15 frames per event

---

### Spec #8: Large Sprite Alien Variants
- Use MOB sprites instead of BACKTAB for select "big" aliens
- 16x16 pixels using DOUBLEX/DOUBLEY
- Takes 2-3 hits to destroy
- Drops better powerups

---

### Spec #9: Wave Entrance Animations

| Type | Description |
|------|-------------|
| "Too Quiet" Pincer | Aliens crawl UP from bottom corners |
| Cascade Drop | Rows drop from top, settle |
| Spiral In | Aliens spiral from edges to grid positions |
| Teleport | Aliens "beam in" one by one |

---

### Spec #10: Extended First Wave (Tutorial Escalation)
- Wave 1 starts with standard grid
- At ~half killed: "REINFORCEMENTS!" + additional row drops
- At ~75% killed: "THEY KEEP COMING!" + another row
- Teaches escalation, prevents wave 1 from being "too easy"

---

### Spec #11: Saucer Animation Refactor
**Current:** Simple color blinking.

**Goal:** Animated "center light grid" that rotates/pulses.

**Options:**
| Style | GRAM Cost |
|-------|-----------|
| Rotating lights | 4-6 frames |
| Pulsing core | 3-4 frames |
| Scanning beam | 4 frames |

---

### Spec #12: Saucer Explosion Escaping Aliens
**Speculative — may exceed complexity budget.**

- When saucer destroyed, 1-3 mini-alien sprites "escape"
- Mini-aliens scatter outward with velocity vectors
- Brief effect (10-15 frames) then cleanup

---

### Spec #13: HUD "ALIEN CAPTURED" Indicator
Depends on defining capture mechanic. Currently speculative.

---

### Spec #14: CP1610 Assembly Optimization
**When:** After gameplay is feature-complete.

**Targets:**
| Routine | Opportunity |
|---------|-------------|
| Collision loops | Unroll, register caching |
| Alien grid iteration | Precompute row addresses |
| BACKTAB writes | Batch writes |
| Sprite updates | Combine MOB register writes |

**Risk:** Maintenance burden, harder to debug. Only for proven bottlenecks.

---

### Spec #15: Captured Alien Escape After 2 Waves
**Concept:** Captured alien has a limited "loyalty" window. After surviving 2 waves as the player's wingman, it flies away during the next wave announcement — a charming nod to the alien escaping back to its kind.

**Behavior:**
- Track waves survived with captured alien (counter increments at wave clear)
- At wave 2 threshold, during the wave announcement transition:
  - Captured alien sprite breaks formation from the player
  - Flies upward/offscreen with a brief animation
  - Optional: small visual flourish (color flash, trail)
- Next wave starts without captured alien (wingman slot empty)
- Player must capture a new one

**Variables:** 1 (wave counter for captured alien tenure)
**GRAM cost:** 0 (reuse existing wingman sprites)

**Design questions:**
- Should there be a visual/audio cue warning the player ("alien is restless")?
- Should the escape be preventable (e.g., feed it powerups)?
- Does the alien rejoin the enemy grid or just disappear?

---

## GRAM Budget Summary

**Currently allocated:** ~61 of 64 cards
**Free slots:** 3 (cards 13, 41, 53)
**Reclaimable during gameplay:** 12 (title font, cards 25-36)

**Available for new features during gameplay:** 15 cards

---

## Ideas Parking Lot
- Two-player co-op mode?
- Sound improvements (more musical variety)
- High score persistence (requires SRAM/JLP)
- Easter eggs / cheat codes
- Attract mode demo playback
- Wingman "goodbye" animation when player dies
