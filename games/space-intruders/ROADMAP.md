# Space Intruders - Feature Roadmap

## Current Priority: Polish Phase
- [x] HUD cleanup and layout optimization
  - [x] Compact SCORE tiles (3 GRAM)
  - [x] Compact CHAIN tiles (3 GRAM)
  - [x] Chain current/best display (N/N format)
  - [x] Tutorial text repositioned (row 9 centered, faster flash)
  - [ ] Lives display styling (see below)
- [ ] Color tuning and visual consistency
- [ ] Physics/collision refinement
- [ ] Performance optimization (saucer CPU spikes)

---

## Future Features

### 0. Lives Display Styling (HUD Polish)
**Current:** Ship icon (GRAM_SHIP_HUD) + "X3" (GROM text)

**Options to consider:**
| Style | GRAM Cost | Look |
|-------|-----------|------|
| Ship + styled X | +1 card | Custom X tile matches font |
| Combined ship+X tile | +0 cards | Single compact tile |
| Ship + number only | +0 cards | Drop X, just "3" |
| Hearts for lives | +1-2 cards | ♥♥♥ (repeat tile) |
| Lives bar | +2 cards | Filled/empty segments |

**Decision:** TBD - thinking about it

---

### 1. Title Screen: 3D Rotating Letters
**Concept:** Animate "SPACE INTRUDERS" with pseudo-3D rotation effect using GRAM reloading.

**Technical approach:**
- Use existing 12 font GRAM slots (25-36)
- Precompute 6-8 rotation frames per letter in ROM
- DEFINE new frames each tick during title sequence
- Can reload 2-4 GRAM cards per WAIT without flicker

**Variations:**
- All letters rotate together (same angle) - simplest
- Wave rotation (letters offset in phase) - most visually striking
- One letter at a time - sequential spotlight effect

**ROM cost:** ~14 letters × 8 frames × 8 bytes = ~900 bytes
**GRAM cost:** 0 additional (reuses existing font slots)

---

### 2. Destructible Barriers/Shields
**Concept:** Classic Space Invaders style barriers that erode when hit by bullets.

**Technical approach:**
- Use 2-4 GRAM cards for barrier tile patterns
- Place barrier segments on BACKTAB between player and aliens
- On bullet hit: modify GRAM bitmap data directly at $3800+
- Punch "holes" in the bitmap where projectiles impact
- No GRAM slot cycling needed - just data modification

**GRAM cost:** 2-4 cards (can use free slots 13, 41, 53)
**Collision:** Check bullet Y/X against barrier BACKTAB positions

**Design considerations:**
- Barrier placement (3-4 barriers across screen?)
- How much protection before fully destroyed?
- Do alien bullets also destroy barriers?
- Visual style (brick pattern? solid? organic?)

---

### 3. Boss Fight
**Concept:** Large boss enemy taking up ~1/3 of screen, climactic battle.

**Technical approach - Option A: Multi-sprite boss**
- Use multiple MOBs (sprites) positioned together
- 8 MOBs available, could dedicate 4-6 to boss
- Each MOB is 8x8 or 8x16, so 4 MOBs = 32x16 pixels
- Requires disabling other sprites during boss phase
- Can animate by updating sprite GRAM cards

**Technical approach - Option B: BACKTAB boss**
- Draw boss using BACKTAB tiles (like aliens)
- Much larger possible size (8x8 cards, many on screen)
- Less smooth movement (card-aligned)
- Could be 6x4 cards = 48x32 pixels easily
- Animate with GRAM reloading

**Technical approach - Option C: Hybrid**
- Body on BACKTAB (large, detailed)
- Eyes/weapons/weak points as sprites (smooth movement, collision)
- Best of both worlds

**Boss fight phases:**
1. Boss entrance (descends from top?)
2. Attack patterns (projectiles, movement)
3. Weak point mechanics (hit specific area?)
4. Health bar display
5. Death sequence (explosion cascade?)

**GRAM cost:** 4-8 cards for boss tiles (reload during boss phase)
**Design:** Need to define boss appearance, attack patterns, health system

---

## GRAM Budget Summary

**Currently allocated:** 61 of 64 cards
**Free slots:** 3 (cards 13, 41, 53)
**Reclaimable during gameplay:** 12 (title font, cards 25-36)

**Available for new features during gameplay:** 15 cards

| Feature | GRAM Cost | Notes |
|---------|-----------|-------|
| Barriers | 2-4 cards | Use free slots |
| Boss tiles | 4-8 cards | Reload into font slots during boss phase |
| 3D title | 0 cards | Reuses font slots during title only |
| HUD compacts | 0-3 cards | Already done (CHAIN, SCORE) |

---

## Performance Notes

**Current issues:**
- Saucer animation may be causing frame drops
- Need to profile with debug border colors

**Optimization targets:**
- SaucerAnimate procedure
- Alien grid rendering (especially with bosses)
- Collision detection loops

---

## Interactive Features

### 4. Player 2 Controls Zod (Title/Game Over)
**Concept:** Second player can grab controller 2 and fly Zod around on title screen and game over screen.

**Technical approach:**
- Read CONT1 (controller 2) disc input during title/game over states
- If CONT1 input detected, switch from auto-pilot to manual control
- Map disc directions to Zod X/Y velocity
- Revert to auto-pilot after ~3 seconds of no input

**Controls:**
- Disc: 8-direction movement
- Fire button: Shoot (game over only, see below)

**States affected:**
- Title screen (GameState = 0)
- Game over screen (GameOver = 5, 6)

**Cost:** Minimal - just input reading and position updates

---

### 5. Zod Shoots Away Letters (Game Over)
**Concept:** On game over, Player 2 (or auto-Zod) can shoot the letters, making them disappear or explode.

**Technical approach:**
- Zod fires small projectile (reuse alien bullet sprite or BACKTAB?)
- Check projectile collision against BACKTAB text positions
- On hit: clear that BACKTAB position (letter disappears)
- Optional: show small explosion at hit position
- Could track "letters destroyed" as mini-game score

**Target letters:**
- "GAME OVER" (row 2, positions 45-53)
- "SCORE XXXX" (row 5)
- "NEW HIGH!" or "HIGH SCORE" (row 6)
- "BEST CHAIN X" (row 7)
- "PRESS FIRE" (row 10)

**Gameplay loop:**
- Auto-Zod or P2 flies around shooting
- Each letter hit = satisfying pop
- Could respawn letters after all destroyed for endless fun

**Cost:**
- 1 variable for Zod bullet active/position
- Collision check against BACKTAB rows
- Reuse existing explosion SFX

---

### 6. Wave Announcement Transition (Low Priority)
**Concept:** Brief (~1 second) flashy "WAVE X" announcement between waves with visual flair.

**Visual options:**

| Style | Description | Complexity |
|-------|-------------|------------|
| DOS Tab Bounce | Letters slide in from sides, bounce to center | Medium |
| Wavy Text | Letters oscillate vertically in sine wave | Medium |
| Starfield Warp | Background stars streak during transition | High |
| Color Cascade | Letters cycle through colors rapidly | Low |
| Zoom Effect | "WAVE" small→large using GRAM reload | High |

**Starfield warp idea:**
- During wave transition, modify star update to streak vertically
- Stars move 4-8x faster, leaving "trail" effect
- Creates hyperspace/warp feel for ~1 second
- Return to normal star drift when wave starts

**Implementation approach:**
1. After wave clear, enter transition state (~60 frames)
2. Display "WAVE X" centered (row 5 or 6)
3. Apply chosen visual effect to text and/or stars
4. Brief audio sting (fanfare or whoosh)
5. Clear text, resume gameplay

**Letter animation (DOS-style bounce):**
```
Frame 0:  W         E      (letters at edges)
Frame 10: .W.     .E.      (moving inward)
Frame 20: ..WA  VE..       (converging)
Frame 30:   WAVE           (settled at center)
```

**Wavy text (sine oscillation):**
- Each letter Y offset = sin(frame + letter_index * 30) * 2
- Creates ripple effect across "WAVE X"
- Use BACKTAB row shifting or sprite overlay

**Cost:**
- 60 frames of transition time
- Minimal GRAM (text is GROM)
- Star warp: modify existing star update logic temporarily

---

### 7. Impact Pause / "Dopamine Moments" (Polish)
**Concept:** Brief freeze-frame moments on significant events to make kills feel impactful.

**Trigger events:**
- Bomb alien final hit (before chain explosion)
- Skull boss destruction
- Saucer hit
- Extra life awarded
- Wave clear (last alien)
- Player death

**Animation sequence (example: Bomb Alien):**
```
Frame 0:    Bullet connects
Frame 1-5:  FREEZE - game pauses, bomb alien flashes
Frame 6-10: Shake effect (screen jitter or sprite wobble)
Frame 11:   BOOM - explosion cascade begins
Frame 12+:  Resume normal gameplay
```

**Visual effects during pause:**
| Effect | Description | Cost |
|--------|-------------|------|
| Color flash | Alien cycles white/red rapidly | Low |
| Screen shake | SCROLL offset oscillates ±1 | Low |
| Sprite wobble | X/Y position jitters | Low |
| Time freeze | All movement stops, only target animates | Medium |
| Zoom pulse | Brief GRAM swap for "bulge" frame | High |

**Implementation approach:**
1. Add `ImpactPause` variable (countdown timer)
2. When triggered, set `ImpactPause = 10` (or appropriate frames)
3. In game loop, if `ImpactPause > 0`:
   - Skip normal movement/updates
   - Run impact animation (flash/shake)
   - Decrement timer
4. When timer hits 0, trigger the actual explosion/effect

**Screen shake technique:**
```basic
IF ImpactPause > 0 THEN
    IF ImpactPause AND 1 THEN
        SCROLL 1, 0
    ELSE
        SCROLL -1, 0
    END IF
    ImpactPause = ImpactPause - 1
    IF ImpactPause = 0 THEN SCROLL 0, 0
END IF
```

**Dopamine design principles:**
- Anticipation (brief pause before explosion)
- Visual contrast (flash/shake draws attention)
- Audio sync (charge-up sound → boom)
- Scale with importance (bigger pause for bigger events)

**Cost:**
- 1 variable (`ImpactPause`)
- Few cycles per frame for shake/flash
- 5-15 frames of "frozen" time per event

---

---

### 8. Large Sprite Alien Intruders (Surprise Variants)
**Concept:** Occasionally replace standard grid aliens with larger sprite-based enemies for variety.

**Technical approach:**
- Use MOB sprites instead of BACKTAB for select "big" aliens
- Could be 2x2 tile equivalent (16x16 pixels using DOUBLEX/DOUBLEY)
- Mix into pattern maps as surprise elements
- Different collision hitbox (larger)

**Placement options:**
- Replace center alien with large variant
- Spawn as mini-boss mid-wave
- Entire row of large aliens (fewer columns)

**Behavior variations:**
- Takes 2-3 hits to destroy
- Drops better powerups
- Different movement pattern (slower but menacing)
- Unique explosion (bigger, more frames)

**GRAM cost:** 2-4 cards for large alien frames
**Sprite cost:** 1-2 MOBs per large alien on screen

**Optional: Death Particle Effect**
When a large intruder is destroyed, particle debris could fall from the explosion to signify defeating a "big boy":

```
Frame 0:   Large alien explodes (flash + expand)
Frame 1-3: 2-4 particle sprites spawn at explosion center
Frame 4-8: Particles fall with slight horizontal drift
           Each particle: small GRAM card (2x2 or 4x4 pixels)
Frame 9+:  Particles fade or fall off-screen
```

| Approach | Sprites | Look |
|----------|---------|------|
| Reuse alien bullet sprites | 0 extra | Falling debris using existing MOBs |
| Dedicated particle sprites | 2-4 MOBs | Distinct debris shapes |
| BACKTAB particles | 0 MOBs | Card-aligned, chunkier feel |

**Implementation notes:**
- Could reuse explosion sprite slots after main explosion finishes
- Particles inherit color from exploded alien
- Gravity acceleration: Y velocity increases each frame
- Brief effect (10-15 frames max) to avoid disrupting gameplay
- Mark as optional/polish — game works fine without it

---

### 9. Wave Entrance Animations (Variety)
**Concept:** Different dramatic entrances for alien waves to keep gameplay fresh.

**Entrance Type A: "Too Quiet" Pincer**
```
1. Wave starts with EMPTY grid
2. Text flashes: "IT'S TOO QUIET..."
3. 1-second pause (tension builds)
4. Aliens crawl UP from bottom-left and bottom-right
5. Two pillars rise, meet in center
6. Grid snaps into formation
7. Gameplay begins
```

**Entrance Type B: Cascade Drop**
```
1. First row drops from top, settles
2. Second row drops, settles above first
3. Continue until full grid formed
4. Creates "curtain falling" effect
5. Each row slightly delayed for wave effect
```

**Entrance Type C: Spiral In**
```
1. Aliens spiral inward from screen edges
2. Each follows curved path to grid position
3. Creates swirling vortex effect
4. More complex but visually striking
```

**Entrance Type D: Teleport/Materialize**
```
1. Grid positions flash empty outlines
2. Aliens "beam in" one by one (random order)
3. Flash effect on each materialization
4. Sci-fi transporter feel
```

**Implementation:**
- Add `EntranceType` variable (0-3)
- `EntrancePhase` tracks animation progress
- Each type has own state machine
- Standard grid rendering after entrance complete

**Wave assignment:**
- Wave 1: Normal (immediate)
- Wave 3: Cascade Drop
- Wave 5: "Too Quiet" Pincer
- Wave 7+: Random selection

---

### 10. Extended First Wave (Tutorial Escalation)
**Concept:** Wave 1 starts easy, then MORE aliens drop in as player gains confidence.

**Sequence:**
```
Phase 1 (0-30 sec):
- Standard 5x9 grid, slow speed
- Player learns controls

Phase 2 (when ~half killed):
- "REINFORCEMENTS!" text flashes
- Additional row drops from top
- Grid now 6x9

Phase 3 (when ~75% killed):
- "THEY KEEP COMING!"
- Another row drops
- Grid now 7x9
- Speed increases slightly
```

**Technical approach:**
- Track `AliensKilled` count
- At thresholds, trigger reinforcement drop
- Use existing alien row rendering, just add to #AlienRow array
- Extend ALIEN_ROWS temporarily for wave 1

**Design goals:**
- Teaches player that waves escalate
- Prevents wave 1 from being "too easy"
- Creates narrative tension
- Rewards aggressive play (kill fast before reinforcements)

**Alternative: Continuous Trickle**
- Instead of row drops, aliens spawn 1-2 at a time from top
- Endless feel until player clears a threshold
- More arcade-style pressure

---

### 11. Saucer Animation Refactor (Polish)
**Current:** Simple color blinking — looks like cheap LED lights.

**Goal:** Animated "center light grid" that appears to rotate/pulse around the saucer's center while maintaining powerup color coding.

**Concept approaches:**

| Style | Description | GRAM Cost |
|-------|-------------|-----------|
| Rotating lights | 3-4 "light dots" orbit center in sequence | 4-6 frames |
| Pulsing core | Center expands/contracts with color glow | 3-4 frames |
| Scanning beam | Horizontal or diagonal line sweeps across | 4 frames |
| Shimmer pattern | Alternating pixels create movement illusion | 2-3 frames |

**Frame sequence example (rotating lights):**
```
Frame 0:  ○·····     (light at 12 o'clock)
Frame 1:  ·○····     (light at 2 o'clock)
Frame 2:  ··○···     (light at 4 o'clock)
Frame 3:  ···○··     (light at 6 o'clock)
...etc, cycling through positions
```

**Powerup color integration:**
- Base saucer shape stays consistent across frames
- Light/core element changes color to indicate powerup type
- Color still visible at a glance, but now with motion

**Technical approach:**
- Define 4-6 GRAM frames for saucer animation
- Cycle through frames every 4-8 ticks
- Reload GRAM cards during WAIT (2-3 per frame is safe)
- Or use multiple GRAM slots and swap card index

**GRAM cost:** 4-6 cards (could reuse title font slots during gameplay)

---

### 12. Saucer Explosion: Escaping Aliens (Speculative)
**Concept:** When a saucer is destroyed, 1-3 small alien sprites "escape" from the explosion and scatter.

**POSSIBILITY — may exceed complexity budget. Document for future consideration.**

**Visual sequence:**
```
Frame 0:    Saucer hit — flash white
Frame 1-5:  Explosion expands
Frame 3:    2-3 mini-alien sprites spawn at explosion center
Frame 4-10: Mini-aliens scatter outward (different velocities)
Frame 11+:  Mini-aliens fall off screen or fade
```

**Sprite approach:**
- Reuse explosion sprite slots after initial burst
- Mini-aliens: small GRAM card (could be 1x1 tile, 8x8 pixels)
- Each has velocity vector (dx, dy) set at spawn
- Simple physics: move by velocity each frame, maybe add gravity

**Behavior options:**
| Variant | Complexity | Feel |
|---------|------------|------|
| Scatter and vanish | Low | Quick visual reward |
| Fall and bounce once | Medium | Cartoonish |
| Become collectible powerups | High | Gameplay integration |
| Attack player briefly | High | Risk/reward tension |

**Why this might be cut:**
- Requires spare MOB sprites (may conflict with bullets, player, explosions)
- Adds state tracking for each escaping alien
- CPU cost during already-busy explosion sequence

**Why it could work:**
- Saucer explosions are rare events (not every frame)
- Could limit to 2 mini-aliens max
- Brief effect (10-15 frames) then cleanup

---

### 13. HUD: "ALIEN CAPTURED" Indicator
**Concept:** Visual feedback when player captures an alien (if capture mechanic exists) or when saucer-related collection occurs.

**Display options:**

| Style | Location | Duration |
|-------|----------|----------|
| Flash text "CAPTURED!" | Center screen (row 5-6) | 30-60 frames |
| HUD icon lights up | Bottom row near score | Persistent while active |
| Captured alien portrait | Corner of screen | Until released/used |
| Counter "+1 ALIEN" | Near chain display | Brief flash |

**If tied to saucer mechanic:**
- Player shoots saucer → alien escapes → player "catches" it?
- Captured alien becomes temporary wingman?
- Or: saucer was carrying captured ally, freeing them = bonus

**HUD integration approaches:**
```
Style A (flash text):
    PRINT AT 109 COLOR 6, "CAPTURED!"
    CaptureFlash = 45  ' frames to display

Style B (icon):
    ' Reserve 1 GRAM card for "captured alien" icon
    ' Light up in HUD row when CapturedCount > 0
    PRINT AT 218, GRAM_CAPTURED * 8 + COL_GREEN + $0800

Style C (counter):
    PRINT AT 215 COLOR 5, "+"
    PRINT AT 216, <>CapturedCount
```

**GRAM cost:** 0-1 cards (text is GROM, icon would need 1 GRAM)
**Variables:** 1-2 (CapturedCount, CaptureFlash timer)

**Note:** This feature depends on defining what "capture" means in gameplay. Currently speculative — add to parking lot if no capture mechanic planned.

---

## Ideas Parking Lot
- Two-player co-op mode?
- Sound improvements (more musical variety)
- High score persistence (requires SRAM/JLP)
- Easter eggs / cheat codes
- Attract mode demo playback
