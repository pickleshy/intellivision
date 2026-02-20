# Space Intruders - Development Roadmap

## Development Priority: Polish First

---

## 1. Bugs (Known Issues)

- [x] **Captured alien dive bomb behavior** — Rogue now dogfights both wingman and player ship with strafing passes, targeted firing, and body collision.
- [x] **Game over score position 110 shows GROM 'T'** — GRAM card 32 was shared by `GRAM_SCORE_M` (millions digit) and `GRAM_FONT_T`. Game over `DEFINE GRAM_FONT_E, 4, FontEGfx` loaded cards 29-32 including 'T' into card 32, overwriting the millions digit. Fixed by reducing count 4→3 (skip card 32; GRAM_FONT_T is never rendered in game over text).
- [x] **'R' in PRESS FIRE shows TinyFont 'E' on game over and title screen** — GRAM card 33 was shared by `GRAM_SHIELD` and `GRAM_FONT_R`. Game over loaded `GOEBlankGfx` into card 33 immediately after the font batch loaded 'R' there, destroying it. `LoadAnimatedFont` preserves cards 19-38 so the corruption persisted on title return. Fixed by moving `GOEBlankGfx` to card 57 (`GRAM_BOMB2_F1`, free during game over and title screen).
- [x] **Lives counter shows 'E' on first wave** — GRAM card 29 is shared by `GRAM_LIVES_DIG` and `GRAM_FONT_E`. The `game_init.bas` pre-init loop fired 5 `UpdateScoreDisplay` calls (ScoreCard 3-7), stopping at the chain digit (card 28) and never reaching ScoreCard=8 (lives digit, card 29). Card 29 retained 'E' font data from boot. Fixed by adding a 6th pre-init call.
- [x] **#NextLife overflow awards burst of extra lives at high scores** — `#NextLife` is 16-bit; after the 13th extra life (score ~61,000), adding 5,000 wraps to ~464. Every subsequent frame `#Score >= 464` is true, awarding 12+ lives in one burst. Fixed with unsigned overflow detection: `IF #NextLife < 5000 THEN #NextLife = 65535`.
- [ ] **CONT.BUTTON bitmask breaks input** — Using `CONT.BUTTON AND bitmask` (e.g., `AND 3` to exclude bottom-right, `AND 4` to isolate bottom-right) causes all controller input to stop working in jzintv. Suspected IntyBASIC compilation quirk with bitwise AND on hardware register reads. Needs assembly listing investigation to see what instructions are generated. Capture currently uses keypad 0 as workaround. Removing `--ecsimg` from jzintv_run resolved ECS keyboard bleed-through into CONT.BUTTON but did not fix the bitmask issue.
- [ ] **Dead alien pop-in during march** — A dead alien (cleared from `#AlienRow`) occasionally becomes visible for a frame or two when the grid marches. Suspected cause: `DRAW_ROW_FAST` writes the correct `0` to dead cells, but the march trail redraw (`NeedRedraw=3`) or a stale `BACKTAB` position is rendering the tile before the column bitmask is checked. Repro: watch a sparse grid march left/right after several kills, particularly near the boundary of a march step. Needs `NeedRedraw` logic audit and march trail clear ordering check.
- [ ] **Skull boss split → rogue animation / orphan alien** — Skull boss occasionally triggers the rogue dive animation and leaves a small alien tile visible on the opposite side of the sprite pattern. Suspected double-XOR resurrection or a `BossHP` race with `RoguePickAlien` selecting the boss grid cell before `SkullBossGridClear` has run. Repro: kill skull boss at the exact frame a rogue selection fires. Check `RoguePickAlien` guard against boss-occupied cells.
- [x] **Pea shooter fires during SOL-36 sputter phase** — When `MegaTimer` hits 0 and `MegaSputterTimer` is active, the `ELSE` branch in `player.bas` fire logic allowed normal pea shooter firing. Fixed by changing `ELSE` to `ELSEIF MegaSputterTimer = 0 THEN` so the player is locked out of all normal fire while the sputter countdown is running.
- [ ] **SOL-36 not added to auto-fire sequence** — When SOL-36 (mega beam) powerup is active, it does not fire automatically alongside the player's normal bullet cadence. Needs investigation of `MegaTimer` check placement in the fire logic path and whether `FireCooldown` is gating beam shots correctly.
- [ ] **Sprites not cleared on player death** — On player death, one or more sprite MOBs (suspected: `SPR_PBULLET`, `SPR_SHIP_ACCENT`, or `SPR_POWERUP`) remain visible during the death animation or respawn delay. Check death sequence in `gameloop.bas` to confirm `HideAllSprites` (or equivalent per-sprite zeroing) runs before the first WAIT of the death state.

---

## 1b. Testing Harness & Regression Checklist

### Score System Testing
- [ ] **Score display regression harness** — Build a cheat-code-triggered score injection mode (e.g., keypad "99") that directly sets `#Score` and `#ScoreHigh` to boundary values and verifies HUD displays correctly. Test cases:
  - `#Score=0, #ScoreHigh=0` → displays `0000000`
  - `#Score=65535, #ScoreHigh=0` → displays `0065535`
  - `#Score=0, #ScoreHigh=1` → displays `0065536` (seamless boundary crossing)
  - `#Score=12345, #ScoreHigh=1` → displays `0077881`
  - `#Score=0, #ScoreHigh=2` → displays `0131072`
  - High-value: `#Score=0, #ScoreHigh=10` → displays `0655360`
- [ ] **HUD score display** — Verify 7-digit zero-padded display (positions 223–226) updates correctly at each boundary. Confirm card 32 (millions/hundred-thousands) shows `00` at game start and updates correctly above 100,000.
- [ ] **Game over score display** — Verify 7-digit score appears at positions 110–113 on the game over screen. Confirm the "NEW HIGH SCORE!" label at row 6 uses card 33 (not card 32) and does not corrupt the digit display.
- [ ] **Score label corruption regression** — During warp-in reveal animation, confirm SCORE label cards (34–36) are stable and do not flash or corrupt. Guard (`ScoreCard < 3`) should prevent label round-robin during reveal; card 32 should still update.
- [ ] **Round-robin order verification** — Step through a full 9-frame cycle (ScoreCard 0–8) and confirm each GRAM card (34, 35, 36, 32, 61, 62, 63, 28, 29) updates exactly once per cycle with correct data.

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

### Recently Completed
- [x] Active powerup indicator (HUD shows active powerup)
- [x] Better wingman firing as partner (BACKTAB bullets, can kill rogue)
- [x] Beam weapon rework (2-hit pierce, 2px laser shared with boss beam)
- [x] Boss beam laser (green/white flash, reuses player beam GRAM)
- [x] Wingman goodbye animation (stop at center, "bye!" speech bubbles)
- [x] Rogue vs wingman dogfight (body collision, wingman bullet kills rogue, strafing fire at wingman)
- [x] Bug fixes: powerup capsule ghost, wingman bullet ghost tile, mega beam vs rogue, rogue/wingman variable conflict

### Backlog
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
- [x] Define wave count target (8-wave arcade loop)
- [x] Design pattern variety (8 Pattern B formations, data-driven WaveDefTable)
- [x] Place bosses (per-wave table-driven placement)
- [x] Plan wave entrance animations (3 types + pincer)
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
- [ ] Saucer animation may cause frame drops (needs profiling)

### Completed Optimizations
- [x] ColMaskData ROM lookup table (replaced 14 shift loops, 27-37% frame savings in heavy action)
- [x] DrawAliens dirty flag pattern (60→4-10 calls/sec)
- [x] Row-level boss pre-check cache (RowBoss1/RowBoss2, eliminated FindBoss GOSUB)
- [x] Variable audit: 187→183 8-bit vars (ABulletType packed, RowHasBoss/BossIdx/LaserColor eliminated)
- [x] Rogue circle fire bug fix (condition was always true, wasting cycles)
- [x] Debug mode (type "36"): BORDER color band shows CPU usage
- [x] Score display division audit — replaced `#Score/10` (6553 iters worst case) with `/1000` + `/100` chain; vast improvement at high scores
- [x] ScoreCard=6: `#Score/100` (655 iters = ~14K cycles) → `/1000` + `/100` + `/10` chain (max 65+9+9 iters = ~1830 cycles). Saves ~12,580 cycles/8-frame = ~1,572 cycles/frame (~11% of budget)
- [x] ScoreCard=5: `#Mask/10` on L_mod1000 (99 iters = ~2178 cycles) → `/100` + `/10` chain (9+9 iters + mul = ~600 cycles). Saves ~210 cycles/frame amortized
- [x] ChainTimer noise freq: `(24-ChainTimer)/3` (0-7 iters/frame) → 25-entry `ChainNoiseFreq` lookup. Constant ~31 cycles every frame during active chain

### Division Audit Results (2026-02-18)
All IntyBASIC `/2`, `/4`, `/8` operations compile to fast shifts — zero concern.

**Remaining non-power-of-2 divisions in gameplay code (hot path):**

| File | Line | Expression | Runs | Max iters | Cycles | Impact |
|------|------|-----------|------|-----------|--------|--------|
| `utils.bas` | 138 | `#Score / 100` | Every 8 frames (ScoreCard=6) | 655 | ~14,410 | **HIGH** — ~12% frame amortized |
| `utils.bas` | 131 | `#Mask / 10` | Every 8 frames (ScoreCard=5) | 99 | ~2,178 | Medium — ~1.8% frame amortized |
| `gameloop.bas` | 441 | `(24-ChainTimer) / 3` | Every frame during chain | 8 | ~176 | Low — 1.2% during chain only |

**Wave-load / title-only (no concern):**
- `waves.bas:108,828` — `#AlienRow / ColMaskData(HitRow)` — runs once at wave load
- `waves.bas:997` — `(Level-1) / 6` — runs once at wave load (110 cycles)
- `title.bas:168` — `FlyX / 5` — title screen only
- `title_animation.bas:121` — `GOAnimFrame / 3` — title screen only

**Proposed fixes (utils.bas ScoreCard=5 and ScoreCard=6):**
- ScoreCard=6: Replace `#Score/100` (655 iters) → `#Score/1000` + `/100` + `/10` (≤65+9+9 iters). Saves ~12,580 cycles/8-frame = ~1,572 cycles/frame.
- ScoreCard=5: Replace `#Mask/10` (99 iters) → `/100` + `/10` chain on L_mod1000 (9+9 iters). Saves ~1,678 cycles/8-frame = ~210 cycles/frame.
- Net savings: ~1,782 cycles/frame amortized (~12% of frame budget freed).

### Remaining Optimization Targets
| Routine | Priority | Notes |
|---------|----------|-------|
| SaucerAnimate | Medium | Suspected CPU spike, needs profiling |
| ~~ChainTimer noise calc~~ | ~~Low~~ | ~~`(24-ChainTimer)/3` every frame; 25-entry lookup table~~ |
| Collision detection loops | Low | Already optimized with lookup tables |

### Future: CP1610 Assembly Optimization
See detailed spec #14 below — only pursue after feature-complete.

---

## 7. Features (Backlog)

### Completed
- [x] Captured alien escape after 2 waves (spec #15) — goodbye animation with speech bubbles
- [x] Large sprite alien variants (spec #8) — BACKTAB 2x2 LARGE_TYPE bosses
- [x] Wave entrance animations (spec #9) — left sweep, top-down, fly-down + pincer
- [x] Title screen: 3D rotating letters (spec #1) — Y-axis rotation cascade

### Near-Term
- [ ] Destructible barriers/shields (spec #2)
- [ ] Wave announcement transition (spec #6)

### Medium-Term
- [ ] Boss fight (spec #3) — dedicated boss wave (skull/bomb/large exist but no standalone encounter)

### Stretch Goals
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

### Spec #16: Title Screen F/B Mode — 3-Color Aliens (body + shadow + eyes)

**Goal:** Make all 9 title screen aliens display 3 distinct colors simultaneously:
1. **Body** — solid foreground pixels (currently `COL_GREEN`)
2. **Shadow** — blank pixels on each alien showing a dark shadow color (e.g. `COL_TAN` or `COL_BLUE`)
3. **Eyes** — red glow via BEHIND sprites punching through the eye socket blanks

**Why the current approach can't do this:**
- Color Stack background (`MODE 0, shadow, 0, 0, 0`) changes ALL blank pixels globally — stars, text gaps, everything turns the shadow color. Tried this; it looked wrong.
- BEHIND sprites for shadow would need 18 sprites for 9 aliens (9 × 2 half-tiles). Only 7 free. Not feasible.

**The correct hardware solution: F/B Mode (MODE 1)**

In `MODE 1` each BACKTAB card has an independent foreground AND background color encoded in the BACKTAB word itself. The alien tiles get `FG=COL_GREEN, BG=shadow_color`. All other tiles (stars, text, silhouette) get their usual FG color with `BG=0` (black). BEHIND sprites still punch through blank pixels to show the red eye glow on top of the shadow.

**BACKTAB encoding change (critical):**

| Mode | GRAM card encoding |
|------|--------------------|
| Color Stack (current) | `(card * 8) OR fg_color OR $0800` |
| F/B Mode | `card OR (fg_color << 9) OR $1000 OR (bg_color << 13)` |

Note: in F/B mode the GRAM flag is **bit 12** (not bit 11), and the card number is NOT shifted by 3.

**Files that need updating (title screen BACKTAB writers):**

- `title_animation.bas` — `DrawAlienGrid`, `DrawTitleAnimated`, `DrawStaticStars`, `DrawSilhouette`, `AnimateStars`, `ZodRender` (PRINT AT values and GRAM card calculations)
- `title.bas` — `TitleScreen` init (`MODE 0` → `MODE 1`), `TitleLoop` BEHIND sprite GRAM card values, any direct PRINT AT calls (bolt sweep, PRESS FIRE, slide-in text)
- `game_init.bas` — `StartGame`: add `MODE 0, 0, 0, 0, 0` after CLS to revert for gameplay

**Shadow color suggestion:** `COL_TAN` (3) — warm bone/shadow on green aliens looks natural.
Or `COL_BLUE` (1) — cooler "lit from top, shadow below" alien look. User to decide.

**Eye glow sprites:** Unchanged in concept. BEHIND sprites still show through blank eye socket pixels in F/B mode (BEHIND priority is above tile background but below tile foreground — same as Color Stack). The center-column glow sprites already in `TitleLoop` should continue to work. Once F/B mode is working, revisit whether all 9 aliens can have glow (would need 9 sprites; 7 available without Zod, 8 if Zod is removed for title).

**Current state going into this work:**
- Aliens drawn in `DrawAlienGrid` using `RowColor = COL_GREEN` (uniform — per-row coloring was removed)
- Center-column glow: 6 BEHIND sprites (sprites 0,1,2,3,4,6), cards `GRAM_BOMB2_F1` (57) and `GRAM_CHAIN_CH` (58), `COL_RED`
- Zod on sprite 5 (`SPR_FLYER`)
- All BACKTAB encoding currently uses Color Stack format

**Estimated effort:** Medium. ~50-80 BACKTAB writes across 2 files need re-encoding. No logic changes, pure format translation. Build and visual-test after each procedure converted.

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

## Resource Budget Summary

### GRAM (64 cards)
**Currently allocated:** ~61 of 64 cards
**Free slots:** 3 (cards 13, 41, 53)
**Reclaimable during gameplay:** 12 (title font, cards 25-36)
**Available for new features during gameplay:** 15 cards

### Variables
**8-bit:** 157/187 used (30 free) — *updated 2026-02-18*
**16-bit:** 25/25 used (0 free — use bit-packing in #GameFlags for new booleans)
**#GameFlags:** 15/16 bits used (bit 11 free)

### ROM — *updated 2026-02-18 (36,162 words)*
**Total:** 36,403 of 42,016 words used (6,013 available)
**Seg 0:** 2,035 words free (main loop + Intellivoice runtime)
**Seg 1:** ~8 words free ⚠️ FULL — do not add procedures here; use `SEGMENT 2` (utilities + game loop inline)
**Seg 2:** 1,369 words free (collision, alien drawing, DATA tables)
**Seg 3:** 414 words free (title animation + music data)
**Seg 4:** 917 words free (AI systems)
**Seg 5:** 1,199 words free (compact_score + PackedPairs)

**If Seg 1 overflows:** Move procedures to Seg 2 with `SEGMENT 2` directive; cross-segment GOSUB works with MAP 2.

### Sprites
**8/8 allocated** — no free MOBs during gameplay

---

## Ideas Parking Lot
- Two-player co-op mode?
- Sound improvements (more musical variety)
- High score persistence (requires SRAM/JLP)
- Easter eggs / cheat codes
- Attract mode demo playback
- Wingman "goodbye" animation when player dies

## Variable Optimization Notes (for future sessions)
**Medium wins available if more slots needed:**
- BulletColor → reuse a frame counter (1 var)
- GOAnimFrame → share with gameplay-only counter during game-over (1 var)
- BombExpTimer → reuse ExplosionTimer if mutually exclusive (1 var)
- RevealCol/VanishCol/WavePhase/TitleAnimState → derive from timers, title-only (4 vars)
