# DOWNBEAT! - Game Design Document

**Platform:** Intellivision (with Intellivoice module)  
**Genre:** Competitive Rhythm/Music Game  
**Players:** 2  
**Copyright:** Shaya Bendix Lyon

---

## Core Concept

DOWNBEAT! is a competitive rhythm game where two players alternate between building melodies and sabotaging their opponent. Players must maintain perfect timing with a metronome while creating musical phrases using nine different instruments, all while defending against (or deploying) creative distractions.

---

## Game Overview

### Basic Gameplay Loop

**Round Structure:**
1. **Player A's Turn (Building Phase - 45 seconds)**
   - Player A builds a melody by pressing instrument buttons in rhythm
   - Player B acts as saboteur, using distraction buttons to disrupt Player A
   
2. **Scoring for Player A**
   - Points tallied based on timing accuracy, melody complexity, and phrase completion
   
3. **Player B's Turn (Building Phase - 45 seconds)**
   - Roles reverse: Player B builds, Player A sabotages
   
4. **Scoring for Player B**
   
5. **Round Winner Declared**
   - Player with higher score wins the round
   - Intellivoice announces "BRAVO!" or applause (randomized)

**Match Structure:**
- Best of 3 rounds
- First player to win 2 rounds wins the match

---

## Controls & Overlay

### Instrument Buttons (Red - 3x3 grid)
**Top Row:**
- PICCOLO
- TRUMPET
- VIOLIN

**Middle Row:**
- OBOE
- VIOLA
- TROMBONE

**Bottom Row:**
- BASSOON
- TIMPANI
- REST

### Helper Buttons (Black - Bottom Row)
- **MAESTRO** - Rhythm assist + immunity (3-4 beats)
- **BATON** - Enhanced metronome visibility
- **PARTNER** - Preemptive sabotage reflection

### Side Buttons

**Left Side (Labeled SNEEZE / DISTRACT):**
- SNEEZE (top)
- DISTRACT (label only)

**Right Side (Labeled DROP PENCIL / COUNT OUT LOUD):**
- DROP PENCIL (top)
- COUNT OUT LOUD (bottom)

**Bottom Center:**
- CHANGE TEMPO

---

## Gameplay Mechanics

### Building a Melody

**Rhythm System:**
- Visual metronome is the goldenrod pulsing dot [●] showing the next beat position on the snake line
- Players press instrument buttons when the goldenrod dot pulses
- Successful timing adds that instrument's note to the snake line as a colored icon
- Player builds one continuous melody line for the full 45-second turn
- The snake line grows progressively as notes are added

**Phrases:**
- 3+ consecutive successful notes creates a "phrase" (for scoring purposes)
- Phrases don't loop or play back automatically
- Phrases are just scoring markers for combo bonuses
- Longer unbroken combos = higher phrase bonuses

**Combo & Variety:**
- Using diverse instruments creates richer melodies and higher variety multipliers
- Longer unbroken combos = higher phrase bonuses
- Active phrase notes display in full color
- Broken phrase notes turn grey (but remain visible on snake)

**Missing Beats:**
- Missing the rhythm means no note is added to the snake
- Sync meter depletes
- Breaks the current phrase (previous notes turn grey)
- If sync meter empties completely, current phrase is lost and sync resets to 50%

### Helper Powers (Builder's Tools)

**METRONOME** (Unlimited uses)
- Makes the metronome MORE visible/obvious
- Bigger, brighter, clearer pulse for several beats
- Helps track beat through visual chaos

**GLANCE AT MAESTRO** (2 per turn, can earn 3rd)
- Provides 3-4 beats of "auto-pilot"
- Any instrument button pressed lands perfectly on beat
- Includes sabotage immunity during this window
- Visual: Maestro figure appears conducting
- **Earn bonus use:** Hit 8-10 consecutive beats perfectly
- Cap: Maximum 3 maestro uses per turn

**GLANCE AT PARTNER** (1 per turn)
- Preemptive sabotage reflection
- Press any time during building phase (no visual indicator for opponent)
- Next sabotage triggered by opponent:
  - Is completely blocked ("REFLECTED!" appears)
  - Gets banked for builder's revenge next round
- Trap stays armed until triggered or turn ends
- Strategic: anticipate when sabotage is coming

### Sabotage Powers (Saboteur's Tools)

Each sabotage type has 2-3 uses per turn with cooldown (5-8 seconds) between uses.

**SNEEZE**
- **Effect:** Screen shake + Intellivoice "ACHOO!"
- **Duration:** Instant (1-2 beats of disruption)
- **Strategy:** Precision timing - use right before a critical beat to startle

**DROP PENCIL**
- **Effect:** Animated pencils bounce across Player A's side/metronome area + pencil clatter sound
- **Duration:** 4-6 beats of visual obstruction
- **Strategy:** Area denial - obscures vision when opponent has momentum

**COUNT OUT LOUD**
- **Effect:** Intellivoice counts "ONE, TWO, THREE, FOUR" in WRONG tempo
- **Duration:** One count cycle (3-5 beats)
- **Strategy:** Cognitive confusion - creates conflicting rhythm information

**Note:** CHANGE TEMPO is not available during gameplay. Tempo is selected pre-game and remains fixed for the entire match.

### Reflected Sabotages

- When Player A successfully reflects a sabotage, it's banked
- At start of Player A's saboteur turn (next round), banked sabotages appear as bonus attacks
- These are in addition to normal sabotage allowances
- Visual indicator shows which sabotages were banked

---

## Audio Design

### Intellivoice Cues

**Game Start:**
- Orchestra tuning up (cacophony of instruments)
- Silence, then "ORCHESTRA!"

**During Gameplay:**
- "ACHOO!" (sneeze sabotage)
- "ONE, TWO, THREE, FOUR" (count out loud sabotage)
- "REFLECTED!" (successful reflection)
- "MAESTRO!" (bonus maestro earned)

**Between Rounds:**
- "PLAYER ONE" / "PLAYER TWO" (announcing turns)

**Victory:**
- "BRAVO!" or applause sound (randomized per round)

### Instrument Sounds
- 9 distinct instrument tones using Intellivision sound chip
- Each instrument button produces recognizable sound when pressed on-beat
- Phrases play back layered sounds of included instruments

### Sound Effects
- Metronome pulse (audible tick/beep)
- Pencil clatter (DROP PENCIL sabotage)
- Success chimes (phrases completed, bonuses earned)
- Miss sounds (off-beat notes)

---

## Visual Design & Screen Layout

### Color Palette - Final

**Primary Colors:**
- **Plum:** #4d02d9 (Player 2 theme, vivid electric purple)
- **Magenta:** #990099 (UI accents, rich saturated)
- **Tomato:** #f10909 (Player 1 theme, bright punchy red)
- **Goldenrod:** #ffa227 (accent - metronome pulse, active lightning icon)
- **Dark Grey:** #191717 (main background)
- **Darker Grey:** #0f0f0f or #0a0a0a (top bar background, nearly black)
- **White:** #FFFFFF (active elements, sync meter, top hat icon)
- **Medium Grey:** #555555 (used/unavailable powers, empty sync meter blocks, broken phrase icons)

### Instrument Colors

Each instrument has a unique color for visual clarity:
- **Piccolo:** Light cyan/bright blue
- **Trumpet:** Bright yellow
- **Violin:** White
- **Oboe:** Orange
- **Viola:** Magenta #990099
- **Trombone:** Lime/yellow-green
- **Bassoon:** Dark orange
- **Timpani:** Tomato #f10909
- **Rest:** Light grey/silver

**Color behavior:**
- **Active phrase:** Full saturation instrument colors
- **Broken phrase:** All icons become medium grey #555555 (lose color, keep shape)

### Screen Layout - Asymmetric (Builder Focus)

**Overall structure:** Builder gets ~70% of screen, saboteur gets ~20%

```
┌─────────────────────────────────────────┐
│ MODERATO  🎩🎩 ⚡     P1: BUILDER 450   │ ← Top bar (Black)
├─────────────────────────────────────────┤
│ PLAYER 1                                │
│                                         │
│ [Tr]—[Vn]—[R]—[Ob]—[Va]—[Tr]—[Pi]—[Bs]│ → Row 1 (L→R)
│                                         │
│                     [●]—[Ob]—[Vn]—[Ti] │ ← Row 2 (R→L)
│                                         │
│ [continuing snake pattern...]          │ → Row 3 (L→R)
│                                         │
│                                         │ ← Row 4 (R→L)
│                                         │
│ Sync: ████████░░░                       │ ← White/Gray meter
│                                         │
├─────────────────────────────────────────┤
│ PLAYER 2: 320 │ 💥•• (5s) 📝•• 🗣••     │ ← Saboteur bar
└─────────────────────────────────────────┘
```

### Top Bar Design

**Background:** Black

**Contents (left to right):**
- Current tempo (ADAGIO / MODERATO / ALLEGRO)
- Power icons: 🎩🎩 ⚡
- Current player role and score (P1: BUILDER 450)

**Power Icons:**
- **Top Hat (🎩):** BATON uses
  - Active: White with black details
  - Used: Gray
  - Shows 2 or 3 hats depending on uses remaining
- **Lightning (⚡):** PARTNER use
  - Active: Orange
  - Used: Gray

### Melody Line - Snaking Pattern

**Behavior:** Progressive building - line only appears as player hits notes

**Pattern:** Alternating left-to-right, right-to-left rows
- Row 1: Left → Right (12-15 beats)
- Row 2: Right → Left (12-15 beats)
- Row 3: Left → Right
- Row 4: Right → Left
- (6 rows total can hold ~72-90 beats = full 45-second turn)

**Visual elements:**
- **Completed notes:** Colored instrument icons/letters (Pi, Tr, Vn, Ob, Va, Tb, Bs, Ti, R)
- **Next beat:** Orange pulsing circle [●] - THIS IS THE METRONOME
- **Connecting lines:** Dashes (—) in player's theme color (Red or Purple)
- **Active phrase:** Full saturation instrument colors
- **Broken phrase:** Icons turn Gray

**Icon representation:**
- Primary: Instrument icons (if readable at small size)
- Fallback: Two-letter codes (Pi, Tr, Vn, Ob, Va, Tb, Bs, Ti, R)

### Sync Meter Design

**Position:** Below melody area, above saboteur bar

**Colors:**
- Full blocks: White
- Empty blocks: Gray
- Background: Black

**Behavior:**
- Fills/depletes based on hit accuracy
- **Critical state (below 20%):** White blocks pulse/flash gently

**Visual:** `Sync: ████████░░░`

### Saboteur Bar Design

**Position:** Bottom strip (~20% of screen)

**Contents:**
- Saboteur's current score
- Sabotage status indicators:
  - 💥 SNEEZE uses (with cooldown timer if active)
  - 📝 DROP PENCIL uses (with cooldown timer)
  - 🗣️ COUNT OUT LOUD uses (with cooldown timer)
- Format: `PLAYER 2: 320 │ 💥•• (5s) 📝•• 🗣••`

### Sabotage Visual Effects

**SNEEZE:**
- Effect: Entire screen shakes
- Intensity: Medium (5-6 pixel random jitter)
- Duration: 1 second
- Audio: Intellivoice "ACHOO!"

**DROP PENCIL:**
- Effect: Single pencil drops and bounces with physics
- Visual: Yellow rectangle with pink eraser tip
- Physics: 
  - Drops from random x-position at top of builder area
  - Bounces at slight angles (15-30°, alternating left/right)
  - Height decreases: 70% → 40% → 20% → settles
  - Creates zigzag pattern as it crosses melody line
- Duration: 4-6 beats, then fades out
- Audio: Clatter sound on each bounce (decreasing volume)

**COUNT OUT LOUD:**
- Effect: Audio only (no visual)
- Audio: Intellivoice counts "ONE, TWO, THREE, FOUR" in wrong tempo
- Duration: One count cycle (3-5 beats)

---

## Power Economy Summary

### Starting Each Turn

**Unlimited:**
- ∞ METRONOME (visual clarity)

**Limited:**
- 2 GLANCE AT MAESTRO (earn 3rd via perfect streak)
- 1 GLANCE AT PARTNER (preemptive reflection)
- 2-3 SNEEZE (with cooldown)
- 2-3 DROP PENCIL (with cooldown)
- 2-3 COUNT OUT LOUD (with cooldown)

**Plus:**
- Any banked/reflected sabotages from previous round

---

## Game Flow

### Match Start
1. Orchestra tuning sound
2. "ORCHESTRA!" announcement
3. Brief instructions screen (optional)
4. Round 1 begins

### Round Flow
1. "PLAYER ONE" announcement
2. 5-second countdown
3. Player 1 builds (45 sec) / Player 2 sabotages
4. Score display for Player 1
5. "PLAYER TWO" announcement
6. 5-second countdown
7. Player 2 builds (45 sec) / Player 1 sabotages
8. Score display for Player 2
9. Round winner announced ("BRAVO!" or applause)
10. Brief pause showing round scores
11. Display banked reflections (if any)
12. Next round or match end

### Match End
- Winner declared
- Final score screen
- Option to play again

---

## Design Philosophy

**Core Principles:**
- Eyes stay on screen (not controller)
- Turn-based prevents audio chaos
- Strategic depth through limited resources
- Accessible but skill-rewarding
- Authentic Intellivision aesthetic and limitations

**Balance Goals:**
- Helper powers provide safety net without being overpowered
- Sabotage is disruptive but not impossible to overcome
- Skill expression through timing, anticipation, and resource management
- Comeback potential through reflection mechanic

---

## Turn & Round Structure

### Turn Length
**45 seconds per building phase**
- At ~120 BPM (2 beats/sec): ~90 beats per turn
- Allows 10-15 phrases if playing well
- Saboteur can attack 5-7 times with cooldowns
- Builder can block ~3 attacks maximum

### Early Turn Ending
**Only one way to end early: Sync meter depletes completely**

When sync meter empties:
1. Current phrase is lost
2. 2-second "dazed" effect (screen effect/animation)
3. Sync meter resets to 50%
4. Metronome continues
5. Player resumes building from current position
6. No time is added back

**No early ending for:**
- Perfect performance (bonus points only, continue playing)
- Voluntary quit (not allowed - must play full 45 seconds)
- Saboteur running out of sabotages (builder continues unmolested)

### Round Structure
**Best of 3 rounds** (Best of 5 available as option)

Each round:
1. Player A builds (45 sec) while Player B sabotages
2. Score tallied for Player A
3. Player B builds (45 sec) while Player A sabotages
4. Score tallied for Player B
5. Round winner declared (higher score wins)

**Round Tie-Breaker** (if scores are equal):
1. First check: Who used more instrument variety?
2. Second check: Who had longest perfect streak?
3. Third check: Who missed fewer beats?

### Between-Round Flow (~10-12 seconds)

After both players complete their turns:
1. Round scores compared side-by-side (3-4 seconds)
2. Round winner declared
3. Intellivoice: "BRAVO!" or applause (randomized)
4. Match score updates (e.g., PLAYER 1: 1, PLAYER 2: 0)
5. Banked reflections displayed as icons (e.g., "REVENGE: [SNEEZE] [DROP PENCIL]")
6. 3-second countdown: "3... 2... 1..."
7. Intellivoice announces next player: "PLAYER ONE!" or "PLAYER TWO!"
8. Next round begins

### Match Win Conditions
- **Best of 3:** First player to win 2 rounds
- **Best of 5:** First player to win 3 rounds

### Match End Sequence
1. Final round winner declared
2. Match winner announced
3. Intellivoice: "PLAYER ONE WINS!" or "PLAYER TWO WINS!"
4. Victory fanfare (more elaborate than round applause)
5. Optional: Final statistics screen showing:
   - Total scores across all rounds
   - Best phrases created
   - Most reflections landed
   - Perfect beat streaks
6. "Press any button to play again"

**Total match time:**
- Best of 3: ~6 minutes (4.5 min gameplay + transitions)
- Best of 5: ~10 minutes (7.5 min gameplay + transitions)

---

## Scoring System

### Per-Note Scoring
- **Perfect timing** (dead-center on metronome beat): **10 points**
- **Good timing** (close to beat): **5 points**
- **Miss** (off-beat or no press): **0 points** (no point penalty, but affects sync meter)

### Phrase Bonuses
Completing consecutive successful notes creates phrases with bonuses:
- **3-note phrase**: +20 bonus points
- **4-note phrase**: +30 bonus points
- **5-note phrase**: +50 bonus points
- **6+ note phrase**: +75 bonus points

Phrases can include REST notes (silence), which don't break the combo.

### Variety Multiplier
Applied to final turn score based on number of unique instruments used (excluding REST):
- **3-4 different instruments**: 1.1x multiplier
- **5-6 different instruments**: 1.25x multiplier
- **7-8 different instruments**: 1.5x multiplier
- **All 8 instruments used**: **3x multiplier** 🎉

### Perfect Streak Rewards
Consecutive perfect-timing notes earn bonuses:
- **5 perfect in a row**: +50 bonus points
- **8 perfect in a row**: +100 bonus points + **earn bonus MAESTRO use**
- **10 perfect in a row**: +200 bonus points
- **15 perfect in a row**: +500 bonus points

### Sync Meter Mechanics
- **Hit perfect note**: Sync meter +10%
- **Hit good note**: Sync meter +5%
- **Miss note**: Sync meter -15%
- **Sync meter depletes to 0%**: 
  - Current phrase is lost
  - 2-second "dazed" effect
  - Sync meter resets to 50%
  - Player continues building

### Example Score Calculation
Player's turn:
- 30 notes hit (20 perfect @ 10pts, 10 good @ 5pts) = **250 points**
- 4 phrases completed (3-note, 4-note, 5-note, 6-note) = **+170 bonus**
- Used 7 different instruments = **1.5x multiplier**
- One 8-note perfect streak = **+100 bonus + maestro earned**

**Final Score:** (250 + 170 + 100) × 1.5 = **780 points**

---

## Tempo System

### Pre-Game Tempo Selection

**Using directional disc:**
- Rotate disc clockwise/counter-clockwise to select tempo
- Three difficulty levels using musical terms:
  - **Adagio** - 90 BPM (Easy/Slow) - ~1.5 beats per second
  - **Moderato** - 110 BPM (Medium/Default) - ~1.83 beats per second
  - **Allegro** - 130 BPM (Hard/Fast) - ~2.17 beats per second

**Selection process:**
1. Game displays "SELECT TEMPO" screen
2. Either player rotates disc to choose tempo
3. Visual tempo arc shows current selection (default: Moderato)
4. Press any button to confirm and start match
5. Selected tempo remains constant for entire match

**Overlay label:** "SELECT TEMPO" appears above directional disc

**During gameplay:** Directional disc is not used (tempo is locked for the match)

---

## Instruments & REST Button

### Button Layout
**9 total buttons arranged in 3x3 grid:**

**Top Row:**
- CELLO
- OBOE  
- BASS

**Middle Row:**
- TIMPANI
- TROMBONE
- PICCOLO

**Bottom Row:**
- TRUMPET
- VIOLA
- **REST** (Button #9)

### REST Button Mechanics
- Pressing REST on-beat = successful beat (maintains combo/phrase)
- Scores same as other notes (5-10 points based on timing)
- Sound: Silence OR very quiet confirmation tick
- **Counts toward phrase building** (doesn't break combos)
- **Does NOT count toward variety multiplier** (it's absence of instrument)
- Allows for rhythmic patterns with intentional silence

Example phrase: Cello-Oboe-REST-Bass = 4-note phrase with breathing room

**Note:** Final instrumentation (which 8 instruments to use) will be determined later. REST stays in position #9.

---

## To Be Determined

The following elements still need design:

1. **Specific Instrument Sounds**
   - What each of the 8 instruments sounds like on Intellivision sound chip
   - How to make them recognizably different
   - Final selection of which 8 instruments to include

2. **Screen Layout Details**
   - Exact positioning of all UI elements
   - Color scheme (Intellivision 16-color palette)
   - Metronome visual design (bouncing baton? pulsing circle? pendulum?)
   - Tempo arc visual design
   - Sprite design for falling pencils and other effects
   - How phrases are visualized building up

---

## Technical Notes

**Platform Limitations:**
- Intellivision: 16 colors, limited sprites, 3-channel sound
- Intellivoice: Speech synthesis for voice cues
- Single screen shared by both players
- Controller overlay provides button labels

**Design Accommodations:**
- Simple geometric visuals (blocks, basic shapes)
- Clear, high-contrast metronome
- Minimal text (rely on voice cues)
- Abstract representation over realism