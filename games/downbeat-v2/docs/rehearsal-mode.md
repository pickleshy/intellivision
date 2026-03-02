# Rehearsal Mode — Obstacle Design Workflow

## Overview

Rehearsal mode is how we design obstacle patterns for new stages. Instead of guessing where obstacles should go, you play through the melody with no obstacles and jump wherever feels natural — the game records your jump positions, and those become the obstacle placements.

## Prerequisites

- A MIDI file for the new stage (128 positions, 2/4 time, 100 BPM)
- The extraction script: `tools/parse_midi.py`

## Step-by-Step Workflow

### 1. Extract Melody from MIDI

```bash
cd games/downbeat-v2
python3 tools/parse_midi.py your_stage.mid
```

This outputs 128 PSG period values (one per 16th-note position). The script uses "highest note per tick" extraction — trust this method; it sounds right for Maple Leaf Rag.

### 2. Import Melody into the Game

In `src/main.bas`, find the `AllMelodyData:` section and replace the target stage's placeholder silence (128 zeros) with the extracted DATA values. Keep the same formatting: 8 values per line, comments showing note names.

### 3. Set Up Rehearsal Slot

The code activates rehearsal features when `CurrentLevel = 255` (a sentinel value). To rehearse a new stage:

1. Add the stage's melody data to `AllMelodyData:` and set its obstacle data to all zeros
2. In the keypad handler, temporarily change the target stage's `CurrentLevel` assignment from its real index to `255`

With `CurrentLevel = 255` active:
- **During gameplay:** Each jump prints "BEAT [number]" at the bottom of the screen
- **On song complete:** Displays "JUMP BEATS:" followed by all recorded beat positions
- **End screen holds for 10 seconds** so you can screenshot/photograph the beat numbers

The obstacle map for the rehearsal stage must be **all zeros** (blank runner — no obstacles to dodge).

### 4. Play the Rehearsal

1. Build and run: `cd games/downbeat-v2 && bash build.sh run`
2. Select the rehearsal stage
3. Listen to the melody and **jump wherever feels natural** — don't overthink it
4. At the end, the JUMP BEATS screen appears with all your positions
5. Screenshot or photograph the numbers (you have 10 seconds)

### 5. Place Obstacles

Give the beat numbers to the assistant. They go into `AllObstacleData:` at the correct stage slot — a 128-entry array where `1` = obstacle at that beat position, `0` = empty.

Example: beats `5, 11, 20, 27` become:
```
DATA 0,0,0,0, 0,1,0,0, 0,0,0,1, 0,0,0,0   ' pos 0-15: 5, 11
DATA 0,0,0,0, 1,0,0,0, 0,0,0,1, 0,0,0,0   ' pos 16-31: 20, 27
```

### 6. Test the Stage

After placing obstacles, rebuild and play the stage again. This time you'll have notes to dodge. Iterate if the pattern doesn't feel right — you can always re-enter rehearsal by zeroing out the obstacles.

### 7. Finalize

Once the obstacle pattern feels good:
- Enable pencils and flowers (stages 2+ get them automatically via `CurrentLevel >= 1`)
- Update the level selector name in the `PRINT AT` statements
- Move to the next stage

## Technical Details

### How Rehearsal Recording Works

- `DIM JumpMap(128)` — initialized to all zeros at game start
- When the player jumps, `JumpMap(BeatCounter) = 1` records the position
- The end screen iterates JumpMap and prints all positions where value = 1

### Rehearsal Code Locations (in main.bas)

| Feature | Where | Trigger |
|---------|-------|---------|
| Jump recording | ~line 459 | Always active (JumpMap array, every jump) |
| Beat display on jump | ~line 462 | `IF CurrentLevel = 255 THEN` |
| End screen beat list | ~line 992 | `IF CurrentLevel = 255 THEN` |
| 10-second hold | ~line 1026 | `IF CurrentLevel = 255 AND GameOver = 2 THEN` |

### Enabling Rehearsal for a Stage

The sentinel value `255` is never a real stage index, so it's safe to use temporarily:

1. Find the keypad handler for your target stage (search for `CurrentLevel =` assignments)
2. Change that assignment to `CurrentLevel = 255`
3. Build, play, record jumps
4. Change it back to the real stage index before committing

### MIDI Extraction Script Details

- Input: Standard MIDI file (Type 0 or Type 1, single track expected)
- Grid: 128 positions = 16 bars x 8 sixteenths (2/4 time at 100 BPM)
- Method: "Highest note per tick" — finds the highest MIDI note sounding at each grid position
- Output: PSG period values (NTSC: `Period = 3579545 / (16 * freq_hz)`)
- Handles notes sustaining from before tick 0 (pre-existing notes)
- PSG periods >4095 are automatically halved (octave up) to fit 12-bit register

### Tips

- Play the rehearsal 2-3 times to get comfortable with the melody before committing to a pattern
- Jump on strong beats and phrase starts — these feel most natural as obstacles
- Leave 5-8 beat gaps between obstacles for reaction time
- 15-20 obstacles per 128-beat stage is a good density
- Pairs of obstacles 2 beats apart create satisfying "double jump" patterns
