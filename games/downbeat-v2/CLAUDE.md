# Downbeat v2 - Development Reference

## Overview

Moon Patrol-style rhythm runner. Player jumps over note obstacles while the Maple Leaf Rag A strain plays on PSG Channel A. Full A strain = 128 16th-note positions (16 bars in 2/4 time at 100 BPM).

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
│   └── main.bas      # Main game source (~420 lines)
├── build/            # Compiled output (generated)
├── assets/
│   └── maple_leaf_rag_a_strain.mid  # Reference MIDI for melody extraction
└── tools/
    └── parse_midi.py  # MIDI parser → IntyBASIC DATA statements
```

## Architecture

### Screen Layout (20x12 card grid)
- **Row 0**: HUD bar (HITS counter)
- **Rows 1-6**: Sky/playfield (player + notes)
- **Row 7**: Ground line (GRAM card 1, white)
- **Rows 8-11**: Underground (unused)

### Sprite Allocation (8 MOBs)
- **MOB 0**: Player character (GRAM card 0, 8x16 double-height, RED)
- **MOBs 1-7**: Note obstacles (GRAM card 2, 8x8, YELLOW, scrolling right-to-left)

### GRAM Cards
| Card | Use | Description |
|------|-----|-------------|
| 0 | Player | Humanoid figure, 8x8 (rendered 8x16 with SPR_YSIZE) |
| 1 | Ground | Solid top 2 rows, drawn across row 7 |
| 2 | Note | Diamond shape, used for all obstacles |

### Key Constants
| Constant | Value | Description |
|----------|-------|-------------|
| PLAYER_X | 40 | Player X position (fixed) |
| GROUND_Y | 48 | Player standing Y position |
| NOTE_Y | 56 | Note Y position (sits on ground) |
| JUMP_FRAMES | 36 | Jump duration (600ms at 60fps) |
| FRAMES_PER_NOTE | 9 | Frames per 16th note (150ms = 100 BPM) |
| MELODY_LENGTH | 128 | Total 16th-note positions in full A strain |
| NOTE_VOLUME | 10 | Background melody volume (0-15) |
| SPAWN_OFFSET | 9 | Beats ahead to spawn obstacles |
| SCROLL_FRAC | 171 | Fractional scroll per frame (171/256) |
| NOTE_SPAWN_X | 168 | Spawn X position (just off right edge) |
| MAX_HITS | 3 | Hits before game over |

## Two-Layer Audio System

The game uses a beat-driven two-layer approach where both layers advance from the same BeatCounter:

### Layer A: Background Melody (Channel 0)
- Plays continuously regardless of player actions
- Reads PSG periods from `MelodyPSG` DATA table (128 entries)
- Period = 0 means rest → channel silenced explicitly
- Consecutive identical periods use 1-frame mute/restore retrigger
- Volume: NOTE_VOLUME (10)

### Layer B: Obstacle Spawning
- Reads `ObstacleMap` DATA table at `BeatCounter + SPAWN_OFFSET`
- SPAWN_OFFSET (9 beats) compensates for scroll travel time
- Notes scroll 128px from spawn to player at ~1.668 px/frame = ~8.5 beats
- Each obstacle stores the melody pitch at its arrival beat for detuned "dud" SFX

### Note Retrigger Mechanism
The AY-3-8914 PSG doesn't restart its waveform when the same period is written. To articulate repeated notes:
1. On beat tick: if new period = previous period, mute channel (SOUND 0,,0) and set MelodyMute flag
2. Next frame (after WAIT): if MelodyMute, restore the note at full volume
3. Result: 1-frame silence gap creates audible note separation (~17ms)

### Hit SFX (Channel 1)
When a note hits the player, a detuned version plays: `period + period/16` (~1 semitone flat). This creates a dissonant "wrong note" effect. SfxTimer counts down 6 frames then silences Channel 1.

## MIDI to IntyBASIC Conversion

### Pipeline
1. Source: `assets/maple_leaf_rag_a_strain.mid` (100 BPM, 2/4 time, Format 0)
2. Tool: `tools/parse_midi.py` — parses MIDI, extracts highest note per tick, quantizes to 16th-note grid
3. Output: PSG period DATA statements for IntyBASIC

### How parse_midi.py Works
- Reads MIDI header, tracks, and events (note on/off, tempo, time signature)
- Groups simultaneous notes by tick position
- Takes the highest MIDI note at each tick (captures melody over bass)
- Quantizes to 16th-note grid: `q_pos = round(tick / ticks_per_16th)`
- Converts MIDI note → PSG period: `3579545 / (16 * 440 * 2^((note-69)/12))`
- Outputs IntyBASIC DATA statements with note names in comments

### PSG Period Reference (NTSC, key of Ab/G#)
| Note | MIDI | Period | Note | MIDI | Period |
|------|------|--------|------|------|--------|
| G#2 | 44 | 2155 | G#5 | 80 | 269 |
| B2 | 47 | 1812 | B5 | 83 | 226 |
| G#3 | 56 | 1077 | C6 | 84 | 214 |
| B3 | 59 | 906 | D#6 | 87 | 180 |
| G#4 | 68 | 539 | F6 | 89 | 160 |
| B4 | 71 | 453 | G#6 | 92 | 135 |
| D#5 | 75 | 360 | | | |

**Limit**: PSG period registers are 12-bit (max 4095). G#1 (period 4310) overflows — use G#2 (2155) as the lowest usable note.

### Lesson: Trust the MIDI Extraction
The "highest note per tick" approach faithfully captures Joplin's voicing, including the zigzag arpeggio in M13-M16 where broken chords alternate between octaves. Attempts to "smooth" or octave-shift the arpeggio sounded worse. The original MIDI data should be treated as authoritative.

## Obstacle Pattern Design

### How ObstacleMap Works
- 128-entry DATA table, one entry per 16th-note position
- 1 = obstacle spawned at this beat, 0 = no obstacle
- Obstacles arrive at player X when that beat's melody note plays (via SPAWN_OFFSET)
- 16 total obstacles across the full A strain, gaps of 6-10 beats

### Design Process
1. Play the game with no obstacles, listen to the melody
2. Use JumpMap recording to capture natural jump timing
3. Place obstacles on melodic accent beats (strong notes, phrase starts)
4. Ensure gaps are 6+ beats apart (player needs time to land + react)
5. Gradually increase density in second half for difficulty curve

### Current Obstacle Placement
```
First half (bars 1-8): 8 obstacles
  M1-4: pos 10 | M5-8: pos 20, 26 | M9-12: pos 33, 41, 47 | M13-16: pos 53, 60

Second half (bars 9-16): 8 obstacles
  M17-20: pos 68, 76 | M21-24: pos 82, 91 | M25-28: pos 97, 105 | M29-32: pos 112, 121
```

## Collision Detection

Uses crossing-point detection rather than bounding box or hardware COL registers:

1. Each frame, check if `NoteX(Slot) < PLAYER_X` (note has passed the player column)
2. `NoteCleared` flag ensures this fires exactly once per obstacle
3. If the note has crossed AND `PlayerY + 12 > NOTE_Y` (player feet below note top), it's a HIT
4. The 12px offset provides a 4px grace zone at the player's feet for near-misses

**Why not hardware collision?** Hardware COL registers can't distinguish "jumped over" from "hit" — we need the vertical position check.

## Sprite Pool Management

7 note slots (MOBs 1-7) are managed as a simple pool:

- **Spawn**: Linear scan for first `NoteActive(Slot) = 0`, allocate it
- **Scroll**: Each frame, advance X by 1 + fractional accumulator overflow (0 or 1 extra pixel)
- **Despawn**: When `NoteX < 2` (left edge), deactivate and hide sprite
- **Recycle**: Deactivated slots become available for new spawns immediately

The pool never runs out in practice — max 3-4 notes on screen simultaneously with current obstacle density and scroll speed.

## Fixed-Point Scrolling

Notes use 8.8 fixed-point for sub-pixel precision:
- Each frame: `NoteFrac += SCROLL_FRAC` (171)
- If `NoteFrac >= 256`: subtract 256, move 2 pixels
- Otherwise: move 1 pixel
- Effective speed: 1 + 171/256 = 1.668 px/frame = 100 px/sec at 60fps

This gives smooth scrolling that syncs precisely with the 100 BPM tempo.

## Timing Derivation

The critical relationship: **obstacles must arrive at the player when their beat plays**.

```
Tempo: 100 BPM in 2/4 time
16th note duration: 60 / 100 / 4 = 0.15 sec = 9 frames at 60fps
Scroll speed: 1.668 px/frame
Travel distance: NOTE_SPAWN_X - PLAYER_X = 168 - 40 = 128 pixels
Travel time: 128 / 1.668 = 76.7 frames
Travel in beats: 76.7 / 9 = 8.5 beats ≈ SPAWN_OFFSET (9)
```

The slight round-up (9 vs 8.5) means notes arrive ~0.5 beats early, giving the player a hair more reaction time.

## Game States

```
GameOver = 0: Playing (main loop)
GameOver = 1: Failed (3 hits) → "GAME OVER!" + "PRESS TO RETRY"
GameOver = 2: Completed song → "SONG COMPLETE!" + jump map + "PRESS TO REPLAY"
```

Both end screens wait for button release then press, then jump to `RestartGame` which resets all state.

## Resource Budget

| Resource | Used | Available | Headroom |
|----------|------|-----------|----------|
| 8-bit variables | 175 | 228 | 53 |
| 16-bit variables | 9 | 55 | 46 |
| GRAM cards | 3 | 64 | 61 |
| MOB sprites | 8 | 8 | 0 |
| ROM | ~2.3K | 8K | ~5.7K |

## IntyBASIC Gotchas Encountered

1. **PSG retrigger**: Writing the same period to the AY-3-8914 doesn't restart the waveform. Need explicit mute/restore cycle for repeated notes.

2. **12-bit PSG limit**: Period registers max at 4095. Low bass notes (G#1 = 4310) overflow silently, producing wrong pitches. Keep periods below 4096.

3. **MIDI extraction vs hand-composition**: The "highest note per tick" algorithm from parse_midi.py captures authentic Joplin voicing better than hand-composed alternatives. Trust the MIDI data.

4. **Unsigned 8-bit scroll underflow**: `NoteX - 2` at position 0-1 wraps to 254-255. Guard with `NoteX < 2` check before deactivating.

5. **Rest handling**: PSG period 0 in MelodyPSG means "silence this beat" — must explicitly call `SOUND 0,,0` rather than leaving the previous note sustaining.

6. **SOUND with empty parameters**: `SOUND 0, , 0` (empty frequency, zero volume) silences a channel without changing its period register. Useful for muting.

## Known Pitfalls (from parent CLAUDE.md)

- NEVER use GOTO/RETURN to exit FOR loops (R4 stack leak)
- Sprite coords have 8px offset from BACKTAB positions
- 8-bit variables wrap at 0/255 (unsigned underflow)
- PLAY SIMPLE ISR overwrites SOUND 4 every frame
- Always gate VOICE INIT on VOICE.AVAILABLE
- Color Stack foreground limited to colors 0-7
- PRINT AT COLOR is persistent state — always specify explicitly
