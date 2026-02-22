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
- [x] **Dead alien pop-in during march** — Root cause: `NeedRedraw = 0` was reset at frame-start, but kills happen in `CheckOneColumn` *after* `DrawAliens` runs. Dead tile persisted until next march/shimmer (up to 24+ frames). Fix: moved `NeedRedraw = 0` reset to *after* `DrawAliens` (`IF NeedRedraw THEN GOSUB DrawAliens : NeedRedraw = 0`), added `NeedRedraw = 1` in `CheckOneColumn` after kill and in `SkullBossDeath`. Latches redraw to next frame for any late-frame kill.
- [x] **Skull boss split → rogue animation / orphan alien** — Investigated: no double-XOR resurrection found. `SkullBossGridClear` properly guarded for both cells. `RoguePickAlien` rejects boss cells via `FindBossAtCell` + `BossHP > 0` guard. The "orphan tile" was the same stale-BACKTAB issue as the pop-in bug; fixed by the NeedRedraw latch. `SkullBossDeath` now also sets `NeedRedraw = 1`.
- [x] **Pea shooter fires during SOL-36 sputter phase** — When `MegaTimer` hits 0 and `MegaSputterTimer` is active, the `ELSE` branch in `player.bas` fire logic allowed normal pea shooter firing. Fixed by changing `ELSE` to `ELSEIF MegaSputterTimer = 0 THEN` so the player is locked out of all normal fire while the sputter countdown is running.
- [x] **SOL-36 not added to auto-fire sequence** — Moved Sol36 firing block out of the button-press ELSEIF chain into its own unconditional block before the button gate. Sol36 now auto-fires at its 20-frame cadence regardless of button state, and fires simultaneously alongside normal bullets (player can fire both at once). player.bas.
- [x] **Sprites not cleared on player death** — `SPR_SHIP_ACCENT` was missing from the bullet-hit death path (only cleared on invasion death and game-over screen). Added `SPRITE SPR_SHIP_ACCENT, 0, 0, 0` after `SPR_PBULLET` hide in gameloop.bas death sequence.
- [x] **SOL-36 beam column shows alien bitmaps instead of laser sputter** — The beam block cleared the *old* `Sol36Col` before updating to the new player position, but only drew rows `Col`–`9` at the new column. Rows `0`–`Col-1` retained alien GRAM cards from `DrawAliens`. Fixed by adding a full-column clear of the new `Sol36Col` before drawing the beam sweep. gameloop.bas.
- [x] **Capture/wingman bullets don't hit saucer at row 0** — Saucer starts at `FlyY=8` (BACKTAB row 0). Bullet deactivated at `CapBulletRow <= 1` so it never reached row 0; at row 1 `CapPixelY=16 > FlyY+6=14` so collision also failed. Fixed: deactivation changed to `= 0`, letting bullet reach row 0 invisibly (draw guard added for score row). `SaucerAnimate` now sees `CapBulletRow=0`, `CapPixelY=8` matching `FlyY=8`. ai.bas.
- [x] **Wave announcement overlaps bottom alien row** — Banner at BACKTAB row 5 (positions 103/107/112) overlapped the lowest alien row. Shifted all positions down one row (+20): `107→127`, `112→132`, `103→123`. Updated `DrawWaveBanner`, `ClearWaveBanner`, `SpinWaveBannerLetter`, and timer-expired clear in gameloop.bas. aliens.bas + gameloop.bas.
- [ ] **SOL-36 cleanup** — Known issues with the SOL-36 auto-cannon still to be investigated and resolved. Tracked for next dedicated SOL-36 session.

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
- [x] Game over screen polish — "HIGH: NNNNNNN" label when not a new high, all-TinyFont "NEW HIGH SCORE" when it is; 7-digit zero-padded 32-bit score display
- [x] Saucer score tuned to 100 points
- [x] Wingman capture bullet now reaches saucer at row 0 (deactivation threshold fix)
- [x] SOL-36 beam column alien bitmap bleed fixed (full-column clear before beam draw)
- [x] Wave announcement repositioned to row 6 (was overlapping bottom alien row at row 5)

### Backlog
- [ ] Impact pause / "dopamine moments" (see spec #7)
- [ ] Saucer animation refactor (see spec #11)
- [ ] **Kill counter on game over screen** — Display total aliens killed during the session (e.g. "KILLS: NNN") on the game over screen as a fun stat. Cost: 2 × 8-bit vars (`KillCount` 0-99, `KillCountHi` 0-9, tracking up to 999 kills), ~80-100 ROM words. Increment at each `#AlienRow XOR #Mask` kill site across player.bas, aliens.bas, waves.bas, ai.bas. Display using GROM digits on row 8 of the game over screen. Add only after all primary features are complete.

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
- Background music: DNB track via PLAY SIMPLE (4 speed gears: slow/mid/fast/panic)
- SFX: Player shoot, alien death, explosions, powerup pickup, shield ping, saucer hit, chain combo noise, rogue dive rumble
- Intellivoice: **Active in gameplay** — wave number announcement ("Wave One", "Wave Two", etc.) and "Shields Down" callout

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

### Division Audit Results (2026-02-18, fixes applied 2026-02-21)
All IntyBASIC `/2`, `/4`, `/8` operations compile to fast shifts — zero concern.

**Remaining non-power-of-2 divisions in gameplay hot path (post-fix):**

| File | Expression | Runs | Max iters | Cycles | Impact |
|------|-----------|------|-----------|--------|--------|
| `utils.bas` (ScoreCard=6) | `/1000` + `/100` + `/10` chain | Every 8 frames | ≤65+9+9 | ~1,830 | Low — ~1.5% frame amortized |
| `utils.bas` (ScoreCard=5) | `/100` + `/10` chain on L_mod1000 | Every 8 frames | ≤9+9 | ~600 | Negligible |
| `gameloop.bas` | `(24-ChainTimer) / 3` replaced by `ChainNoiseFreq` lookup | — | — | ~31 | Eliminated |

**Wave-load / title-only (no concern):**
- `waves.bas` — `#AlienRow / ColMaskData(HitRow)` — runs once at wave load
- `waves.bas` — `(Level-1) / 6` — runs once at wave load (~110 cycles)
- `title.bas` — `FlyX / 5` — title screen only
- `title_animation.bas` — `GOAnimFrame / 3` — title screen only

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
- [x] Boss system (spec #8) — BACKTAB 2×2 skull and bomb boss types, per-wave data-driven placement, HP, color cycling, orbiter companions
- [x] Wave entrance animations (spec #9) — left sweep, top-down, fly-down + pincer
- [x] Title screen: 3D rotating letters (spec #1) — Y-axis rotation cascade
- [x] Wave announcement transition (spec #6) — spinning WAVE N letters with color cascade, ALERT! and INCOMING HORDE! variants, wave banner spin-in/spin-out animation

### Near-Term
- [ ] **SOL-36 skeleton death effect** (spec #17) — When the SOL-36 beam kills an alien, flash an invader skeleton sprite at that cell instead of the normal death pop. See spec below.
- [ ] Destructible barriers/shields (spec #2)

### Medium-Term
- [ ] Boss fight (spec #3) — dedicated boss wave (skull and bomb boss types exist but no standalone boss-only encounter)

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

### Spec #17: SOL-36 Skeleton Death Effect

**Concept:** When the SOL-36 auto-cannon beam kills an alien, briefly flash an "invader skeleton" GRAM card at that BACKTAB cell — as if the laser burns away the alien's body and leaves its skeletal frame exposed for a moment. Normal bullet kills show a chain-colored explosion pop; SOL-36 kills currently show nothing special. The skeleton gives SOL-36 a distinct, satisfying visual identity.

**Visual design (GRAM skeleton card):**
- Single 8×8 GRAM card at card 32 (free during gameplay — only used by title font)
- Pixel-art "invader X-ray" — what remains after vaporization. Design options:
  - **Bones/lattice**: ribs, limbs, and antennae visible as bare strokes
  - **Ghostly outline**: hollow silhouette — just the perimeter edges, empty inside
  - **Ember core**: only the "hot" interior remains (eye dots + central node)
- Color: White (7) for stark "burned out" contrast, or Cyan (9) for a spectral glow
- Duration: 16 frames (~0.27s) — visible but not lingering

**Variables needed (3 × 8-bit, affordable within 19 free slots):**

| Variable | Purpose | Range |
|----------|---------|-------|
| `Sol36SkelMask` | Bitmask of rows killed (bit N = row N killed) | 0–31 (5 row bits) |
| `Sol36SkelTimer` | Countdown to 0 (0 = inactive) | 0–16 |
| `Sol36SkelCol` | Column where kills occurred (same as Sol36Col at fire) | 0–9 |

**Implementation — `weapons.bas` (`MegaBeamKill`):**
1. At start of each SOL-36 fire: `Sol36SkelMask = 0` (clear from previous fire)
2. At each alien kill site (inside row loop): `Sol36SkelMask = Sol36SkelMask OR ColMaskData(AlienGridRow)` — reuse the existing `ColMaskData` table; rows 0-4 map to masks 1, 2, 4, 8, 16
3. After sweep completes: `IF Sol36SkelMask THEN Sol36SkelTimer = 16 : Sol36SkelCol = Sol36Col`

**Rendering — `gameloop.bas` (after DrawAliens, before HUD):**
```basic
IF Sol36SkelTimer > 0 THEN
    Sol36SkelTimer = Sol36SkelTimer - 1
    FOR AlienGridRow = 0 TO 4
        IF Sol36SkelMask AND ColMaskData(AlienGridRow) THEN
            ' Compute BACKTAB position matching DrawAliens coordinate math
            #Card = (ALIEN_ROW_START + AlienOffsetY + AlienGridRow) * 20 + AlienOffsetX + Sol36SkelCol
            PRINT AT #Card COLOR COL_WHITE, (GRAM_SKELETON * 8 + $0800)
        END IF
    NEXT AlienGridRow
END IF
```
Note: `#Card` is safe as a temp here (no AddToScore call in this block). Use the same row-start constant as `DrawAliens`.

**State resets — all 3 wave transition procedures:**
```basic
Sol36SkelTimer = 0
Sol36SkelMask = 0
```

**GRAM definition — `game_init.bas` (full GRAM reload block):**
```basic
DEFINE 32, 1, SkeletonGfx   ' GRAM_SKELETON = 32, card 32 is free during gameplay
```

**Graphics — `graphics.bas`:**
```basic
SkeletonGfx:
    BITMAP "........"   ' to be designed — see visual options above
    BITMAP "..X..X.."
    BITMAP "..XXXX.."
    BITMAP ".X.XX.X."
    BITMAP "..XXXX.."
    BITMAP "...XX..."
    BITMAP "..X..X.."
    BITMAP "........"
```

**Files to modify:**
- `weapons.bas` — `MegaBeamKill`: set `Sol36SkelMask` bit per row kill, arm timer after sweep
- `gameloop.bas` — add skeleton render block after `DrawAliens`
- `game_init.bas` — `DEFINE 32, 1, SkeletonGfx` + reset `Sol36SkelMask=0, Sol36SkelTimer=0`
- `waves.bas` — `StartNewWave`, `LoadPatternB`, `ReloadHorde`: reset `Sol36SkelMask=0, Sol36SkelTimer=0`
- `graphics.bas` — add `SkeletonGfx` BITMAP data (8 rows)

**ROM cost estimate:** ~50–70 words (timer check, 5-iteration FOR loop, PRINT AT, MegaBeamKill additions)
**GRAM cost:** 1 card (card 32, already free during gameplay)
**Variable cost:** 3 × 8-bit (Sol36SkelMask, Sol36SkelTimer, Sol36SkelCol)

**Design note — why not per-kill explosions?** The SOL-36 often kills multiple aliens in one sweep (up to 5 in a full column). Showing `ShowChainExplosion` per kill would re-trigger the GRAM define 5× in one frame, overloading the ISR. The skeleton approach is safer: write BACKTAB cards (instant), let them persist for 16 frames, then DrawAliens naturally clears them as dead cells (DRAW_ROW_FAST always writes 0 to dead cells).

---

## Resource Budget Summary

### GRAM (64 cards)
**Currently allocated:** ~61 of 64 cards
**Free slots:** 3 (cards 13, 41, 53)
**Reclaimable during gameplay:** 12 (title font, cards 25-36)
**Available for new features during gameplay:** 15 cards

### Variables
**8-bit:** 168/187 used (19 free) — *updated 2026-02-21*
**16-bit:** 25/25 used (0 free — use bit-packing in #GameFlags for new booleans)
**#GameFlags:** 15/16 bits used (bit 11 free)

### ROM — *updated 2026-02-21 (36,306 words)*
**Total:** 36,306 of 42,016 words used (5,710 available)
**Seg 0:** 2,017 words free (main loop + Intellivoice runtime)
**Seg 1:** 172 words free ⚠️ very tight — add new procedures to Seg 2 via `SEGMENT 2` directive
**Seg 2:** 1,845 words free (collision, alien drawing, DATA tables)
**Seg 3:** 639 words free (title animation + music data)
**Seg 4:** 537 words free (AI systems + PlayerBombExplode)
**Seg 5:** 901 words free (compact_score + PackedPairs)

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
