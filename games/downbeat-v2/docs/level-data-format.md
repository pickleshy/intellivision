# Downbeat Level Data Format

Reference for the level design tool. Describes the exact data format needed to import levels into the IntyBASIC code.

## Game Structure

```
Level = a complete piece of music (e.g., Maple Leaf Rag, Scheherazade)
  └── Stage = one segment of the piece (e.g., A strain, B strain)
        └── 128 beats of melody + obstacles + hazard config
```

**Example:**
- **Level 1: Maple Leaf Rag** (5 stages)
  - Stage 1: A Strain (easy) — notes only
  - Stage 2: A Strain + Pencil Drop (medium) — notes + pencils + flowers
  - Stage 3: B Strain (medium) — notes only, new melody
  - Stage 4: TBD (hard)
  - Stage 5: TBD (hardest)
- **Level 2: Scheherazade** → stages TBD
- **Level 3: TBD** → stages TBD

Stages within a level are played sequentially. The player hears the full piece over the course of all stages. Hearts carry over between stages.

**Current implementation note:** The in-game "level selector" currently maps to individual stages (for easier testing). The tool should model the full Level > Stage hierarchy so it's ready when sequential stage play is implemented.

---

## Engine Constants (fixed across all stages)

- 100 BPM, 2/4 time, 16 bars = 128 sixteenth-note positions per stage
- FRAMES_PER_NOTE = 9 (150ms per grid position)
- SPAWN_OFFSET = 9 beats (obstacles spawn early to sync with melody)
- Scroll speed: ~1.668 px/frame (SCROLL_FRAC = 171/256)
- PLAYER_X = 40, GROUND_Y = 48, NOTE_Y = 56

---

## Stage Data

Each stage consists of two required data arrays (128 entries each) plus optional hazard/power-up configuration.

### 1. Melody / PSG Data (required)

128 integers, one per 16th-note position. Each value is an AY-3-8914 PSG period (NTSC), or `0` for rest/silence.

```json
"melody": [1438, 0, 1077, 539, 360, 539, 428, 360, ...]
```

- **Formula:** `Period = 3579545 / (16 * frequency_hz)`
- **From MIDI note:** `freq = 440 * 2^((midi_note - 69) / 12)`
- **Range:** 135 (G#6) to 2155 (G#2). Max 4095 (12-bit register limit).
- **`0`** = rest (channel silenced with `SOUND 0,,0`)
- **Extraction method:** "highest note per tick" from MIDI — for each 16th-note position, take the highest pitch note that is sounding

#### Key PSG Periods (Ab major, NTSC)

| Note | Period | Note | Period |
|------|--------|------|--------|
| G#6 | 135 | G4 | 571 |
| B5 | 226 | G#4 | 539 |
| G#5 | 269 | A#4/Bb4 | 480 |
| D#5/Eb5 | 360 | B4 | 453 |
| F5 | 320 | C5 | 428 |
| C#5/Db5 | 403 | A3 | 1017 |
| C6 | 214 | G#3 | 1077 |
| D#6 | 180 | D#3/Eb3 | 1438 |
| B3 | 906 | G#2 | 2155 |
| B2 | 1812 | E3 | 1357 |

#### Retrigger behavior

The AY-3-8914 doesn't restart a waveform when the same period is written again. The engine handles this with a 1-frame mute/restore cycle for repeated identical notes — no special data encoding needed.

#### IntyBASIC DATA format

```basic
AllMelodyData:
    ' === Stage 0: A Strain ===
    DATA 1438,    0, 1077,  539   ' M01 beat 1: D#3  ---  G#3  G#4
    DATA  360,  539,  428,  360   ' M01 beat 2: D#5  G#4  C5   D#5
    ' ... (32 lines of 4 values = 128 entries per stage)
    ' === Stage 1: B Strain ===
    DATA  360,  360,  960,  285   ' M01 beat 1: D#5  D#5  A#3  G5
    ' ... (128 more entries)
```

---

### 2. Obstacle Pattern (required)

128 integers (0 or 1), one per 16th-note grid position.

```json
"obstacles": [0,0,0,0, 0,1,0,0, 0,0,0,1, 0,0,0,0, ...]
```

- **`1`** = spawn a note obstacle at this beat
- **`0`** = no obstacle
- Obstacles spawn `SPAWN_OFFSET` (9) beats ahead of the melody so they arrive at PLAYER_X exactly when that beat's melody note plays
- **Minimum gap:** ~6 beats between obstacles (player needs time to land + react)
- **Recommended density:** 15-20 obstacles across 128 beats

#### Design workflow (rehearsal recording)

1. Set all 128 obstacle entries to 0 (blank runner)
2. Play the stage — melody plays, no obstacles
3. Jump where it feels natural with the music
4. End screen displays "JUMP BEATS:" with all beat numbers
5. Use those beat numbers to populate the obstacle array

#### IntyBASIC DATA format

```basic
AllObstacleData:
    ' === Stage 0: A Strain ===
    DATA 0,0,0,0, 0,1,0,0, 0,0,0,1, 0,0,0,0   ' pos 0-15:   5,11
    DATA 0,0,0,0, 1,0,0,0, 0,0,0,1, 0,0,0,0   ' pos 16-31:  20,27
    ' ... (8 lines of 16 values = 128 entries per stage)
```

---

### 3. Hazards and Power-ups (optional, per stage)

Each stage can enable any combination of hazards and power-ups. These are currently hardcoded per-stage with `CurrentLevel` checks, but the tool should model them as data.

#### Pencils (hazard — falling damage)

Falling pencils that damage the player on contact.

```json
"pencils": {
    "enabled": true,
    "max_count": 2,
    "spawn_window": [20, 108],
    "initial_delay_range": [120, 270],
    "respawn_delay_range": [300, 480],
    "spawn_x_range": [100, 159],
    "fall_speed": 2
}
```

| Field | Type | Description |
|-------|------|-------------|
| `enabled` | bool | Whether pencils appear in this stage |
| `max_count` | int | Total pencils across the whole stage |
| `spawn_window` | [int, int] | `[first_beat, last_beat]` — only spawn between these beats |
| `initial_delay_range` | [int, int] | `[min_frames, min+random_frames]` before first pencil |
| `respawn_delay_range` | [int, int] | `[min_frames, min+random_frames]` between pencils |
| `spawn_x_range` | [int, int] | `[min_x, min+random_x]` horizontal spawn position |
| `fall_speed` | int | Pixels per frame downward (currently 2) |

**Behavior:** Fall from top, scroll left with world, pass through ground, disappear off bottom. Damage on overlap only while falling.

#### Flowers (power-up — healing)

Healing power-ups that restore hearts when collected mid-jump.

```json
"flowers": {
    "enabled": true,
    "max_count": 2,
    "spawn_window": [55, 95],
    "initial_delay_range": [60, 180],
    "respawn_delay_range": [300, 480],
    "spawn_x_range": [80, 139],
    "heal_amount": 1
}
```

| Field | Type | Description |
|-------|------|-------------|
| `enabled` | bool | Whether flowers appear in this stage |
| `max_count` | int | Total flowers across the whole stage |
| `spawn_window` | [int, int] | `[first_beat, last_beat]` — only spawn between these beats |
| `initial_delay_range` | [int, int] | `[min_frames, min+random_frames]` before first flower |
| `respawn_delay_range` | [int, int] | `[min_frames, min+random_frames]` between flowers |
| `spawn_x_range` | [int, int] | `[min_x, min+random_x]` horizontal spawn position |
| `heal_amount` | int | Hearts restored on collection (currently 1) |

**Behavior:** Drift diagonally (left + down). Collected only while jumping. Pink/magenta (pastel 12). Won't spawn while a pencil is falling.

#### Tuba (power-up — invincibility) [NOT YET IMPLEMENTED]

A floating tuba that grants temporary invincibility when collected.

```json
"tuba": {
    "enabled": false,
    "max_count": 1,
    "spawn_window": [40, 100],
    "invincibility_frames": 180
}
```

The tool should include this in the schema so stages can be designed with tuba placement in mind, even before the engine supports it.

#### Sneeze (hazard — screen shake) [NOT YET IMPLEMENTED]

A sneeze event that shakes the screen, disorienting the player.

```json
"sneeze": {
    "enabled": false,
    "beat_triggers": [64, 96],
    "shake_frames": 30
}
```

The tool should include this in the schema. `beat_triggers` is an array of beat positions where the sneeze fires (like the obstacle array but for screen-shake events).

---

## Level Metadata

```json
{
    "name": "Maple Leaf Rag",
    "composer": "Scott Joplin",
    "key": "Ab major",
    "bpm": 100,
    "starting_hearts": 3,
    "max_hearts": 5,
    "stages": [ ... ]
}
```

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Display name for the level |
| `composer` | string | Composer name (for display/reference) |
| `key` | string | Musical key (for reference) |
| `bpm` | int | Tempo (currently fixed at 100 for all levels) |
| `starting_hearts` | int | Hearts at level start (currently 3) |
| `max_hearts` | int | Maximum hearts allowed (currently 5) |
| `stages` | array | Ordered list of stage objects |

---

## Complete Level JSON Example

```json
{
    "name": "Maple Leaf Rag",
    "composer": "Scott Joplin",
    "key": "Ab major",
    "bpm": 100,
    "starting_hearts": 3,
    "max_hearts": 5,
    "stages": [
        {
            "name": "A Strain",
            "stage_index": 0,
            "difficulty": "easy",
            "midi_source": "maple_leaf_rag_a_strain.mid",
            "melody": [
                1438, 0, 1077, 539, 360, 539, 428, 360,
                1017, 571, 360, 571, 480, 360, 807, 0,
                1438, 0, 1077, 539, 360, 539, 428, 360,
                1017, 571, 360, 571, 480, 360, 807, 0,
                1438, 360, 1357, 539, 453, 339, 1438, 360,
                1438, 360, 1357, 539, 453, 339, 1438, 360,
                0, 0, 2155, 2155, 1812, 1077, 2155, 1077,
                906, 539, 1077, 539, 453, 269, 539, 269,
                226, 135, 135, 0, 135, 0, 135, 0,
                135, 135, 428, 180, 160, 214, 180, 160,
                428, 269, 453, 240, 226, 269, 240, 214,
                428, 269, 214, 269, 240, 0, 269, 0,
                0, 269, 906, 0, 269, 0, 269, 0,
                269, 269, 855, 360, 320, 428, 360, 320,
                855, 539, 906, 480, 453, 539, 480, 428,
                855, 539, 428, 539, 480, 0, 539, 0
            ],
            "obstacles": [
                0,0,0,0, 0,0,0,0, 0,0,1,0, 0,0,0,0,
                0,0,0,0, 1,0,0,0, 0,0,1,0, 0,0,0,0,
                0,1,0,1, 0,0,0,0, 0,1,0,0, 0,0,0,1,
                0,0,0,0, 0,1,0,0, 0,0,0,0, 1,0,0,0,
                0,0,0,0, 1,0,1,0, 0,0,0,0, 1,0,0,0,
                0,0,1,0, 1,0,0,0, 0,0,0,1, 0,0,0,0,
                0,1,0,1, 0,0,0,0, 0,1,0,0, 0,0,0,0,
                1,0,1,0, 0,0,0,0, 0,1,0,0, 0,0,0,0
            ],
            "pencils": { "enabled": false },
            "flowers": { "enabled": false },
            "tuba": { "enabled": false },
            "sneeze": { "enabled": false }
        },
        {
            "name": "Pencil Drop",
            "stage_index": 1,
            "difficulty": "medium",
            "midi_source": "maple_leaf_rag_a_strain.mid",
            "melody": ["... same 128 PSG periods ..."],
            "obstacles": ["... 128 obstacle entries ..."],
            "pencils": {
                "enabled": true,
                "max_count": 2,
                "spawn_window": [20, 108],
                "initial_delay_range": [120, 270],
                "respawn_delay_range": [300, 480],
                "spawn_x_range": [100, 159],
                "fall_speed": 2
            },
            "flowers": {
                "enabled": true,
                "max_count": 2,
                "spawn_window": [55, 95],
                "initial_delay_range": [60, 180],
                "respawn_delay_range": [300, 480],
                "spawn_x_range": [80, 139],
                "heal_amount": 1
            },
            "tuba": { "enabled": false },
            "sneeze": { "enabled": false }
        },
        {
            "name": "B Strain",
            "stage_index": 2,
            "difficulty": "medium",
            "midi_source": "stage2_b_to_a_final.mid",
            "melody": ["... 128 PSG periods from B strain MIDI ..."],
            "obstacles": ["... 128 obstacle entries from rehearsal ..."],
            "pencils": { "enabled": false },
            "flowers": { "enabled": false },
            "tuba": { "enabled": false },
            "sneeze": { "enabled": false }
        }
    ]
}
```

---

## Import Pipeline

### Current workflow (manual)

1. MIDI file → `extract_melody.py` → 128 PSG periods
2. Rehearsal play → screenshot jump beats → obstacle array
3. Paste both arrays into `AllMelodyData:` and `AllObstacleData:` in main.bas
4. Each stage block is 128 entries, indexed by `#LevelOffset` (0, 128, 256...)

### Ideal tool output

The level editor should export either:

**Option A: JSON** (as above) — Claude or a conversion script reads it and generates IntyBASIC DATA statements.

**Option B: Direct IntyBASIC DATA** — ready to paste:

```basic
' === Stage 1: PENCIL DROP ===
' Melody (128 PSG periods)
DATA 1438, 0, 1077, 539, 360, 539, 428, 360
DATA 1017, 571, 360, 571, 480, 360, 807, 0
' ... (16 lines of 8 values)

' Obstacles (128 entries, 0 or 1)
DATA 0,0,0,0, 0,0,0,0, 0,0,1,0, 0,0,0,0
DATA 0,0,0,0, 1,0,0,0, 0,0,1,0, 0,0,0,0
' ... (8 lines of 16 values)
```

### Adding a new stage slot

1. Append 128 melody entries to `AllMelodyData:`
2. Append 128 obstacle entries to `AllObstacleData:`
3. Add offset to `LevelOffsets:` (e.g., `DATA 0, 128, 256, 384`)
4. Add stage name to selector screen
5. Add keypad handler for the new stage number
6. Add `CurrentLevel` checks for any stage-specific features (pencils, flowers, etc.)

### Future: sequential stage play

When sequential play is implemented, the selector will choose a **level** (piece of music), and stages will auto-advance on completion. Hearts carry between stages. The `LevelOffsets` table and `CurrentLevel` index will be replaced with a two-tier lookup (level → stage → data offset).

---

## Hardware Resource Allocation

### MOB (Sprite) Slots

| MOB | Use |
|-----|-----|
| 0 | Player (8x16 with YSIZE stretch) |
| 1-4 | Note obstacles (up to 4 on screen) |
| 5 | Flower power-up (or tuba, time-shared) |
| 6-7 | Pencils (up to 2) |

### GRAM Cards

| Card | Use |
|------|-----|
| 0 | Player (normal pose) |
| 1 | Ground line |
| 2 | Note obstacle (quarter note shape) |
| 3 | Heart (HUD) |
| 4 | Player celebration (hands up) |
| 5 | Pencil |
| 6 | Flower |
| 7-63 | Available for tuba, sneeze effects, etc. |

### ROM Budget

Each stage adds 256 words of ROM (128 melody + 128 obstacles). With OPTION MAP 2 providing 42K+ words, there's room for many stages. Current usage is ~5.5K.
