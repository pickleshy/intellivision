# Downbeat v2 - Development Reference

## Overview

Moon Patrol-style rhythm runner. Player jumps over note obstacles while music plays on PSG Channel A. Full song = 128 16th-note positions (16 bars in 2/4 time at 100 BPM).

## Build

```bash
./build.sh          # Compile only
./build.sh run      # Compile and run in jzIntv
./build.sh voice    # Compile and run with Intellivoice
```

## Project Structure

```
games/downbeat-v2/
├── CLAUDE.md         # This file
├── README.md         # Player-facing documentation
├── build.sh          # Build and run script
├── src/
│   └── main.bas      # Main game source (~1100 lines)
├── build/            # Compiled output (generated)
├── assets/
│   └── maple_leaf_rag_a_strain.mid  # Reference MIDI for melody extraction
└── tools/
    └── parse_midi.py  # MIDI parser → IntyBASIC DATA statements
```

## Architecture

### Screen Layout (20x12 card grid)
- **Row 0**: HUD bar (hearts)
- **Rows 1-6**: Sky/playfield (player + notes + power-ups)
- **Row 7**: Ground line (GRAM card 1, white)
- **Rows 8-11**: Underground (unused)

### Sprite Allocation (8 MOBs)
- **MOB 0**: Player character (GRAM card 0, 8x16 double-height)
- **MOBs 1-4**: Note obstacles (GRAM card 2, 8x8, scrolling right-to-left)
- **MOB 5**: Flower power-up OR Golden Tuba (shared, mutually exclusive)
- **MOBs 6-7**: Falling pencils (GRAM card 5, 8x8)

### GRAM Cards
| Card | Use | Description |
|------|-----|-------------|
| 0 | Player | Alien sprite, 8x8 (rendered 8x16 with SPR_YSIZE) |
| 1 | Ground | Solid top 2 rows, drawn across row 7 |
| 2 | Note | Bold quarter note obstacle |
| 3 | Heart | Small centered heart for HUD lives display |
| 4 | Celebration | Arms-up player pose (song complete) |
| 5 | Pencil | Falling pencil hazard |
| 6 | Flower | Healing power-up |
| 7 | Scream | Hurt player pose |
| 8 | Tuba | Golden Tuba of Immunity power-up |

### Key Constants
| Constant | Value | Description |
|----------|-------|-------------|
| PLAYER_X | 40 | Player X position (fixed) |
| GROUND_Y | 56 | Player standing Y position |
| NOTE_Y | 60 | Note Y position (sits on ground) |
| JUMP_FRAMES | 36 | Jump duration (600ms at 60fps) |
| FRAMES_PER_NOTE | 9 | Frames per 16th note (150ms = 100 BPM) |
| MELODY_LENGTH | 128 | Total 16th-note positions in full song |
| NOTE_VOLUME | 10 | Background melody volume (0-15) |
| SPAWN_OFFSET | 9 | Beats ahead to spawn obstacles |
| SCROLL_FRAC | 171 | Fractional scroll per frame (171/256) |
| NOTE_SPAWN_X | 168 | Note spawn X position (just off right edge) |
| MAX_HITS | 5 | Total hearts (player starts with 3) |
| TUBA_IMMTIME | 300 | Immunity duration in frames (5 seconds) |

## Levels

6 levels selectable at startup (keypad 1-6):

| Level | Key | Song | Hazards | Special |
|-------|-----|------|---------|---------|
| 0 | 1 | Maple Leaf Rag — Full Chain | 5-stage run using stageIndices 0–4 | Tuba on stages 0+4 |
| 1 | 2 | B Strain | Notes + pencils + flowers | — |
| 2 | 3 | A-to-C Strain | Notes + pencils + flowers | — |
| 3 | 4 | C-to-D Strain (hard) | Notes + pencils + flowers | — |
| 4 | 5 | D Strain (hardest) | Notes + pencils + flowers + sneezes | Tuba |
| 5 | 6 | A Warrior's Legacy Stage 1a | Notes + flowers | Tuba |

Each level's hazard config is indexed by `#stageIndex` (not `CurrentLevel`).
Config tables: `LevelOffsets`, `LevelFirstStage`, `LevelStageCount`,
`PencilWindowStarts/Ends`, `FlowerWindowStarts/Ends`, `SneezeEnabled`,
`TubaWindowStarts/Ends`.

## Audio System (3 PSG Channels)

### Channel 0 — Background Melody
- Plays continuously, reads `AllMelodyData` DATA table at `BeatCounter`
- Period 0 = rest → channel silenced explicitly
- Consecutive identical periods use 1-frame mute/restore retrigger (AY-3-8914
  doesn't restart waveform on same period write)
- Volume: NOTE_VOLUME (10)

### Channel 1 — Hit SFX
- Detuned "dud" on note hit: `period + period/16` (~1 semitone flat)
- General hurt SFX (pencil hit): period 200
- SfxTimer counts down 6 frames then silences

### Channel 2 — Fanfare (Golden Tuba)
- C4(855) → E4(679) → G4(571) → C5(428) ascending fanfare
- FanfareStep state machine: 0=inactive, 1-4=notes, 5=done
- Each note holds 8 frames; C5 holds 12 frames
- Managed by `FanfareUpdate` PROCEDURE in SEGMENT 1

## Obstacle Spawning

### Beat-driven two-layer system
- `BeatCounter` advances every FRAMES_PER_NOTE (9) frames
- Layer A: melody plays at `BeatCounter`
- Layer B: obstacle at `BeatCounter + SPAWN_OFFSET` — spawned ahead so it
  arrives at player X exactly when that beat plays

### SPAWN_OFFSET derivation
```
Travel distance: NOTE_SPAWN_X - PLAYER_X = 168 - 40 = 128 pixels
Scroll speed: 1.668 px/frame
Travel time: 128 / 1.668 = 76.7 frames = 8.5 beats ≈ SPAWN_OFFSET (9)
```

### Fixed-Point Scrolling
Notes use 8.8 fixed-point: `NoteFrac += SCROLL_FRAC` (171) each frame.
If `NoteFrac >= 256`: subtract 256, move 2px. Otherwise: move 1px.
Effective: 1 + 171/256 = 1.668 px/frame.

## Hazard Systems

### Pencil System (Levels 1+)
- Two slots (MOBs 6-7) share 2 GRAM cards
- Spawn within configurable beat window (`PencilWindowStarts/Ends`)
- Fall from top at fixed X, then scroll left after grounding
- Collision: full bounding box overlap check

### Flower System (Levels 1+)
- Shares MOB 5 with Tuba (mutually exclusive via spawn guards)
- Spawns at X = RANDOM(60) + 100, drifts left 1px/2 frames, down 1px/3 frames
- Collection: any overlap with player restores one heart (up to MAX_HITS)
- Up to 2 flowers per run; spawn window configurable per level

### Sneeze Distraction (Level 5)
- Random screen shake (SneezeX/Y offsets applied to all sprites)
- 180-frame duration, up to 2 per run
- `VOICE PLAY SneezePhrase` on trigger (if Intellivoice available)
- Enabled via `SneezeEnabled` DATA table

### Golden Tuba of Immunity (Levels 0+5)
Collectible power-up that grants 10 seconds of invincibility.

**Behavior:**
- Spawns once per run within beat window (beats 32-96 on Levels 0 and 5)
- Enters from top of screen (tubaY=0), falls to bob zone (Y=30) at 1px/2 frames
- Then oscillates between Y=30 (catchable at jump peak) and Y=50 (catchable standing)
  at 1px/4 frames — the "bobbing" phase
- Drifts left at 1px/2 frames (same speed as flower); spawns at X=RANDOM(60)+100
- Shares MOB 5 with flower; flower spawn blocked while tuba active

**State variable:** `tubaState` = 0 (never spawned) / 1 (active) / 2 (collected/gone).
Merged from old `tubaActive` + `tubasSpawned` to stay within 8-bit variable limit.

**On collection:**
- `#immunityTimer = TUBA_IMMTIME` (600 frames)
- C-E-G-C fanfare on Channel 2
- Player sprite flashes yellow↔white: 16-frame cycle normally, 8-frame in final 2 seconds
- Notes, pencils, and sneezes pass through player; flowers and hearts still collectible

**Immunity bypass pattern:**
```basic
IF #immunityTimer = 0 THEN
    ' ... damage code ...
END IF
```

## Multi-Stage Progression

Multiple music stages can be chained into one continuous level run. Hearts and damage carry over between stages; dying ends the entire run. Golden Tuba immunity expires at each stage boundary.

### Variables
| Variable | Type | Purpose |
|----------|------|---------|
| `#currentStage` | 16-bit | 0-based stage index within current level run |
| `#totalStages` | 16-bit | Total stages for current level (from `LevelStageCount`) |
| `#stageIndex` | 16-bit | Absolute data-table index = `LevelFirstStage(level) + #currentStage` |

### Stage Data Model
All per-stage config tables are indexed by `#stageIndex`, not `CurrentLevel`. This allows Level 0 to chain 5 existing stage data blocks while levels 1–5 remain single-stage (where `LevelFirstStage(n) = n`).

```
LevelFirstStage:  DATA 0, 1, 2, 3, 4, 5   ' stageIndex for level's first stage
LevelStageCount:  DATA 5, 1, 1, 1, 1, 1   ' Level 0 = 5 stages, others = 1
```

### Stage Transition Flow
```
GameOver=2 detected in MainLoop
  → IF more stages remain: GOSUB StageComplete → GOSUB AdvanceStageReset → GOTO MainLoop
  → IF last stage (or GameOver=1): GOSUB GameOverScreen → GOTO RestartGame
```

**StageComplete** (Seg 1): silences sounds, hides hazards, celebration pose, shows "STAGE X COMPLETE!" with HUD hearts visible, waits for button.

**AdvanceStageReset** (Seg 1): advances `#currentStage` / `#stageIndex`, reloads hazard config from new stageIndex, resets all gameplay state except `HitCount` and `DamageTaken`, redraws screen, pre-spawns notes for new stage.

**"PERFECT RUN!"** requires no damage taken across all stages (DamageTaken is never reset between stages).

## Collision Detection

Notes use crossing-point detection (not hardware COL registers):
1. Check `NoteX(Slot) < PLAYER_X + 8` — note entered player space
2. Vertical: `PlayerY + 12 > NOTE_Y` — player feet below note top = HIT
3. `NoteCleared` flag ensures fires exactly once per obstacle
4. 12px offset gives 4px grace zone at feet

Pencils use full bounding box: X overlap AND Y overlap.

## Peak Float Mechanic

Second button press near jump peak (frames 15-20) triggers float:
- Snaps player to `GROUND_Y - 20` (peak height), holds for 10 frames
- Descent resumes from JumpFrame 18 (still at peak visually)
- `FloatUsed` flag prevents re-triggering per jump
- Float window: frames 15-20 (JumpArc values are all 20 = peak)

## End Screen

**Voice + subtitle per level (deterministic, not random):**

| Levels | Success phrase | Failure phrase |
|--------|---------------|----------------|
| 0-1 | "ENCORE!" | "NEEDS PRACTICE" |
| 2-3 | "BRAVO BELLISSIMO!" | "TECHNIQUE NEEDS WORK" |
| 4 | "CARNEGIE HALL!" | "PRACTICE MORE SCALES" |

Subtitle text displayed on screen AND corresponding Intellivoice phrase played.

**Game states:**
```
GameOver = 0: Playing
GameOver = 1: Failed (5 hits) → "GAME OVER!" + failure phrase + "PRESS TO RETRY"
GameOver = 2: Song complete  → "SONG COMPLETE!" + success phrase + "PRESS TO REPLAY"
             (or "PERFECT RUN!" if DamageTaken = 0)
```

`GameOverScreen` is a PROCEDURE in SEGMENT 1 (called via GOSUB, returns to RestartGame).

## ROM Layout (OPTION MAP 2)

The game uses OPTION MAP 2 to access two ROM segments:

| Segment | Range | Content |
|---------|-------|---------|
| Seg 0 | $5000-$6FFF | Main game code, graphics data, voice phrases |
| Seg 1 | $A000-$BFFF | Melody/obstacle DATA tables, SpawnTuba, UpdateTuba, FanfareUpdate, GameOverScreen, StageComplete, AdvanceStageReset |

**Key:** GOSUB compiles to JSR (absolute, full 64K range) — cross-segment PROCEDURE
calls work. GOTO uses relative branch — cannot reliably cross segments.

## Resource Budget

| Resource | Used | Available | Headroom |
|----------|------|-----------|----------|
| 8-bit variables | 219 | 219 | 0 (at limit!) |
| 16-bit variables | 12 | 45 | 33 |
| GRAM cards | 9 | 64 | 55 |
| MOB sprites | 8 | 8 | 0 |
| ROM Seg 0 | ~7353 words | 8192 | ~839 |
| ROM Seg 1 | ~4024 words | 8192 | ~4168 |

**8-bit variable budget is at the absolute limit.** Any new feature requiring new
variables must either reuse/merge existing ones or use 16-bit variables instead.

## MIDI to IntyBASIC Conversion

### Pipeline
1. Source MIDI at 100 BPM, 2/4 time, Format 0
2. `tools/parse_midi.py` — extracts highest note per tick, quantizes to 16th-note grid
3. Converts MIDI note → PSG period: `3579545 / (16 * 440 * 2^((note-69)/12))`
4. Outputs IntyBASIC DATA statements

**Limit:** PSG period registers are 12-bit (max 4095). Keep all periods below 4096.

**Lesson:** The "highest note per tick" algorithm faithfully captures authentic voicing.
Don't try to "smooth" or hand-edit — the original MIDI is authoritative.

## Obstacle Pattern Design: Rehearsal Mode

Built-in recording workflow for designing obstacle patterns:

1. **Set all ObstacleMap entries to 0** — player can't die, song plays freely
2. **Play through**: jump wherever feels natural. `JumpMap(128)` records beat positions.
3. **"SONG COMPLETE" screen** displays JumpMap grid (8×16 of beat positions)
4. **Convert to ObstacleMap**: min 6-beat gap between obstacles, ramp difficulty
5. **Playtest** and iterate

## IntyBASIC Gotchas Encountered

1. **PSG retrigger**: Same period write doesn't restart the waveform. Use explicit 1-frame mute/restore for repeated notes.

2. **12-bit PSG limit**: Period max 4095. Low notes overflow silently — keep periods below 4096.

3. **MIDI extraction**: "Highest note per tick" captures authentic voicing. Trust the MIDI data.

4. **Unsigned 8-bit scroll underflow**: `NoteX - 2` at position 0-1 wraps to 254-255. Guard with `NoteX < 2` check.

5. **Rest handling**: PSG period 0 = silence. Must call `SOUND 0,,0` explicitly.

6. **SOUND with empty parameters**: `SOUND 0, , 0` silences without changing period register.

7. **8-bit variable limit**: Currently at 219/219. Merging related boolean flags into a single multi-state variable (e.g., `tubaState` replacing `tubaActive`+`tubasSpawned`) is the main technique to stay within budget.

8. **ROM Seg 0 overflow**: Large procedures/DATA tables must move to SEGMENT 1. Extract via `label: PROCEDURE ... RETURN : END` and call with GOSUB (not GOTO). The GameOverScreen, SpawnTuba, UpdateTuba, and FanfareUpdate procedures are all in Seg 1 for this reason.

9. **GameOverScreen reconstruction pitfall**: The GameOverScreen PROCEDURE was reconstructed from an old git diff, accidentally reverting per-level phrase changes. When refactoring large blocks into procedures, always compare against the most recent commit, not `git diff HEAD`.

10. **VOICE phrases need a trailing pause before the `0` terminator**: The `0` terminator alone does not stop the final phoneme — the Intellivoice hardware requires an explicit `PA1` (or `PA2`) to end playback. Without it, the last phoneme keeps playing indefinitely. Always end phrases with `...,PA1,0`. Example: `VOICE AW,PA1,0` not `VOICE AW,0`.

## Visual Verification via AVI Recording

```bash
# Create keyboard hack file (one-time)
echo -e "MAP 0\nF9 SHOT\nF10 AVI" > /tmp/jzintv_keys.kbd

# Launch with recording support
arch -x86_64 ~/jzintv/bin/jzintv \
    --execimg=$HOME/jzintv/bin/exec.bin \
    --gromimg=$HOME/jzintv/bin/grom.bin \
    --kbdhackfile=/tmp/jzintv_keys.kbd \
    --avirate=1 -z3 build/downbeat2.rom
```

- **F10**: Toggle AVI recording (saves to `avi_NNNN.avi`)
- **F9**: Single screenshot
- **Escape**: Quit jzIntv

```bash
# Extract every frame
ffmpeg -i avi_0001.avi /tmp/frames/f_%04d.png

# Extract specific range (e.g., frames 400-500)
ffmpeg -i avi_0001.avi -vf "select='between(n\,400\,500)'" -vsync vfr /tmp/frames/f_%04d.png
```

## Known Pitfalls (from parent CLAUDE.md)

- NEVER use GOTO/RETURN to exit FOR loops (R4 stack leak)
- Sprite coords have 8px offset from BACKTAB positions
- 8-bit variables wrap at 0/255 (unsigned underflow)
- PLAY SIMPLE ISR overwrites SOUND 4 every frame
- Always gate VOICE INIT on VOICE.AVAILABLE
- Color Stack foreground limited to colors 0-7
- PRINT AT COLOR is persistent state — always specify explicitly
