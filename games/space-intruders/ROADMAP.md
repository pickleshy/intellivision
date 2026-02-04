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

## Ideas Parking Lot
- Different alien formations per wave
- Two-player co-op mode?
- Sound improvements (more musical variety)
- High score persistence (requires SRAM/JLP)
- Easter eggs / cheat codes
- Attract mode demo playback
