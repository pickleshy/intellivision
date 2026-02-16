# Space Intruders - STIC Graphics Research & Constraints

## Project Context

This is a test ROM for **Space Intruders**, an Intellivision homebrew game built with IntyBASIC and assembly. The game is a Space Invaders clone heavily inspired by **Space Invaders Extreme** (DS/PSP) and **Titan Attacks**. The test ROM is focused on rendering a 45-alien horde using BACKTAB cards and exploring advanced color/animation techniques.

## STIC Architecture - Key Facts

The STIC (AY-3-8900) renders autonomously from latched data. It is NOT a dumb framebuffer — you cannot feed it scanline data in real time like the Atari 2600 TIA. This fundamentally limits "racing the beam" approaches.

### Display Specs
- Background: 20x12 grid of 8x8 cards = 240 cards total (BACKTAB at $0200-$02EF)
- Resolution: 159x96 visible pixels (160th column blanked)
- MOBs (sprites): 8 maximum, 8x8 or 8x16, single color each
- Palette: 16 colors (8 primary + 8 pastel), restrictions on where pastels can appear
- GRAM: 64 programmable 8x8 cards
- GROM: 256 built-in cards (alphanumeric + utility shapes)

### The Fundamental Lock-Out Rule
GRAM and STIC registers can ONLY be written during vertical blank (vblank). During active display, the STIC owns the bus. If your vblank code doesn't finish in time, you either skip enabling display (causing a blank/flicker frame) or accept partial updates. There is NO mid-scanline register manipulation possible.

### CPU Timing
- CP1610 runs at ~894.886 KHz (NTSC)
- Instructions take 4-12 microcycles each
- Vblank window is your entire budget for GRAM redefinition, BACKTAB updates, MOB register writes, and color stack changes

## Display Modes

### Color Stack Mode (RECOMMENDED for this project)
- 4-entry circular color queue for background colors ($0028-$002B)
- "Advance" bit on any BACKTAB card moves to next stack entry before rendering
- GRAM-sourced cards: foreground can be ANY of 16 colors, background comes from stack
- GROM-sourced cards: foreground limited to primary colors (0-7)
- Allows Colored Squares sub-mode

### Foreground/Background (FGBG) Mode
- Per-card foreground AND background color control
- BUT: foreground limited to primary colors only (no pastels 8-15)
- Colored Squares mode NOT available in FGBG
- More flexible color placement, less flexible color range

### Colored Squares Mode (Color Stack sub-mode only)
- Each 8x8 card divided into four 4x4 quadrants
- Each quadrant can be one of 7 primary colors, or color 7 = current stack color
- Great for chunky colorful backgrounds, explosions, UI elements
- Too low-res for alien sprites

## Proven Techniques for Multicolor / Advanced Graphics

### 1. GRAM Sequencing (PRIMARY TECHNIQUE)
Redefine GRAM card bitmaps each frame during vblank to animate BACKTAB-based entities. This was used in original Mattel titles (Space Armada, Star Strike, TRON Solar Sailer). Your 45-alien horde should use this as the primary animation method.

**Key considerations:**
- Each GRAM card = 8 bytes to redefine
- Budget your vblank time: how many GRAM cards can you redefine per frame?
- You share 64 GRAM slots between ALL game graphics (aliens, player, bullets, UI, explosions)
- Multiple BACKTAB cards can reference the SAME GRAM card with DIFFERENT colors — one alien bitmap definition can appear in many colors across the grid

### 2. Daniel Bass "Bi-Color Technique" (FRAME ALTERNATION)
Invented by Blue Sky Rangers programmer Daniel Bass, used in Tower of Doom. Alternate the foreground color of a BACKTAB card between frames to create the illusion of a third "blended" color through CRT persistence of vision.

**Caveats:**
- Looks great on real CRT hardware with NTSC phosphor persistence
- Will likely show visible flicker on LCD displays and in RGB-output emulators (jzintv)
- Mattel marketing originally FORBADE flickering techniques
- Consider making this an optional visual mode, not a requirement
- An IntyBASIC approximation was created by AtariAge user "decle"

### 3. Color Stack Advance Tricks
Engineer your BACKTAB layout so color stack advance bits hit at strategic card positions. This lets different rows of your alien horde have different background colors without needing FGBG mode.

**Example for alien horde:**
- Row 1 aliens: stack color = dark blue background
- Advance bit on transition card → Row 2: stack color = dark green background  
- Advance bit → Row 3: stack color = black, etc.
- Gives visual variety "for free" without extra GRAM or MOB resources

### 4. MOB + BACKTAB Overlay (MULTICOLOR SPRITES)
The standard technique for getting 3+ colors in a single character:
- Draw part of the character as a BACKTAB card (2 colors: foreground + background)
- Overlay a single-color MOB on top, positioned to align with the card
- Result: up to 3 visible colors in one character cell

**For the alien horde:** You have 8 MOBs total. You can't overlay every alien. Use MOBs strategically for:
- Boss/special aliens that need extra color
- The currently-targeted or "active" row
- Player ship, bullets, and explosions will also need MOBs

### 5. MOB Multiplexing (USE WITH CAUTION)
Reposition MOBs between frames to cover more than 8 on-screen entities. Each MOB appears in a different position on alternating frames.

**Caveats:**
- Causes visible flicker (Mattel marketing forbade this)
- Consider only for non-critical visual flourishes
- The Atari 2600 relies on this heavily; the Intellivision community generally avoids it

## BACKTAB Card Encoding Quick Reference

### Color Stack Mode BACKTAB Word (16 bits)
```
Bit 15-14: Not used by STIC
Bit 13:    Advance color stack (1 = advance before rendering)
Bit 12:    Colored Squares flag (with bit 11=0)
Bit 11:    GRAM/GROM select (0=GROM, 1=GRAM) — or part of Colored Squares
Bit 10-3:  Card # (GROM 0-255 or GRAM 0-63)
Bit 2-0:   Foreground color (primary 0-7 for GROM; for GRAM, bit 9 extends to 0-15)
```
For GRAM cards in Color Stack mode, the foreground color encoding uses bits from the card number field to allow all 16 colors.

### MOB Registers
- X position: $0000-$0007 (includes visibility bit, interaction enable)
- Y position: $0008-$000F (includes vertical size, Y-flip, vertical resolution)  
- Attribute: $0010-$0017 (card #, color, horizontal flip/mirror, priority, stretch)
- Collision: $0018-$001F (read-only, cleared on read)

## Practical Plan for 45-Alien Horde Test ROM

### GRAM Budget
- Alien type A frames: 2-4 GRAM cards (animation frames)
- Alien type B frames: 2-4 GRAM cards
- Alien type C frames: 2-4 GRAM cards
- Player ship: 1-2 GRAM cards
- Bullets/projectiles: 1-2 GRAM cards
- Explosions: 2-4 GRAM cards
- UI elements: as needed
- **Total: Plan for ~20-30 GRAM cards used, leaving headroom in the 64-card limit**

### BACKTAB Layout for Horde
- 45 aliens = 9 columns × 5 rows (or 15 columns × 3 rows, etc.)
- Each alien = 1 BACKTAB card referencing a GRAM card
- Same GRAM card can serve entire rows with different foreground colors per BACKTAB entry
- Use color stack advances between rows for background color variation

### Animation Strategy
- Swap between 2 GRAM definitions per alien type each frame (or every N frames)
- All aliens of the same type share the same GRAM card — redefining it once animates ALL of them
- This is extremely CPU-efficient compared to updating individual BACKTAB entries

### Assembly Optimization Notes
- GRAM writes: use tight loops with auto-increment addressing
- BACKTAB updates: only write cards that changed (dirty-flag approach)
- Profile your vblank budget — if you exceed it, the frame blanks
- IntyBASIC's `DEFINE` statement handles GRAM loading but for fine control, use inline assembly via `ASM` blocks

## Key References & Resources

### Documentation
- Joe Zbiciak's STIC documentation: spatula-city.org/~im14u2c/intv/jzintv/doc/programming/stic.txt
- Intellivision Wiki STIC page: wiki.intellivision.us/index.php?title=STIC
- SDK-1600 documentation (bundled with jzintv source)

### Source Code to Study  
- **Space Patrol** by Joe Zbiciak — ROM freely released at spacepatrol.info, considered the technical pinnacle of Intellivision homebrew
- **Christmas Carol vs Ghost of Christmas Presents** by DZ-Jay — maximizes hardware utilization
- **IntyColor** tool by nanochess (GitHub: nanochess/IntyColor) — image-to-Intellivision converter with MOB overlay support (-m flag)

### Books
- "Programming Games for Intellivision" by Oscar Toledo G. (nanochess)
- "Advanced Game Programming for Intellivision" by Oscar Toledo G. — covers waveform audio, advanced GRAM techniques, and more

### Community
- AtariAge Intellivision Programming forum (forums.atariage.com/forum/144-intellivision-programming/)
- Key threads: "IntyBASIC interlacing?" (Jan 2025), "How to avoid screen tearing" (Dec 2022), "Colored Squares Snake Game", "Big Blocky Things on my Intellivision"
- IntyBASIC compiler: nanochess.org/intybasic.html

## What Is NOT Possible

- **No mid-scanline color register changes** — STIC locks CPU out during active display
- **No per-scanline BACKTAB manipulation** — all changes must happen in vblank
- **No true beam racing** — the STIC is not the Atari TIA; it renders from latched state
- **No more than 2 colors per BACKTAB card** (foreground + background) without MOB overlay or frame-alternation tricks
- **No pastel foreground colors in FGBG mode**
- **No Colored Squares in FGBG mode**
- **MOBs are single-color only** — multicolor sprites require MOB+BACKTAB compositing

---

# Advanced Techniques from Space Patrol

*Patterns learned from Joe Zbiciak's Space Patrol source code*

## Sprite Multiplexing (12 Sprites on 8 MOBs)

Space Patrol tracks **12 software sprites** and multiplexes them onto the STIC's 8 MOBs using round-robin allocation.

### Key Architecture

**Sprite Groups:**
- **Group 1:** Bad guys (0-4) → 3 MOBs
- **Group 2:** Bullets (5-11) → 3 MOBs
- **Reserved:** Player tank (2 MOBs)

**Multiplex Strategy:**
- Each group maintains a **counter** tracking where it left off last frame
- Start allocation from counter position, wrap around when reaching end
- Skip inactive sprites (SPAT = 0)
- Dynamic MOB allocation: Loan unused MOBs to the group that needs them

**Cycle Cost (from Space Patrol source):**
- Best case (all inactive): **97 cycles**
- Average case (2 active): **~350 cycles**
- Worst case (3 active + wrap): **631 cycles**

### IntyBASIC Approximation

```basic
' Track 12 entities, display 8 on screen via round-robin
CONST MAX_ENTITIES = 12
DIM EntityX(12), EntityY(12), EntityActive(12), EntityCard(12)
MuxCounter = 0

UpdateMuxedSprites: PROCEDURE
    SpriteSlot = 0
    FOR i = 0 TO MAX_ENTITIES - 1
        Idx = (i + MuxCounter) MOD MAX_ENTITIES
        IF EntityActive(Idx) THEN
            SPRITE SpriteSlot, EntityX(Idx) + VISIBLE, EntityY(Idx), EntityCard(Idx) * 8
            SpriteSlot = SpriteSlot + 1
            IF SpriteSlot >= 8 THEN RETURN  ' All MOBs allocated
        END IF
    NEXT i
    MuxCounter = (MuxCounter + 1) MOD MAX_ENTITIES
    RETURN
END
```

**Effect:** Sprites with indices > 8 flicker on/off each frame, but all 12 are visible (just not simultaneously). With proper game design, this is barely noticeable.

---

## Cycle Budget Tracking & Inline Annotations

Space Patrol's code includes **cycle counts on every instruction** with running subtotals. This is production-level discipline for performance-critical code.

### Example from Space Patrol's ISR

```asm
ENGINE1 PROC
    ; We may have as little as 3500 cycles for all VBLANK updates!

    MVO R0, $20             ;  11  Enable display
@@1:
    ; Copy 24 MOB registers (unrolled for speed)
    CLRR R5                 ;   6  Point to MOB registers
    MVI  SDATP, R4          ;  10  Point to shadow copy
                            ;----
                            ;  27  (subtotal)

    REPEAT 24
        MVI@ R4, R0         ;   8  Load shadow value
        MVO@ R0, R5         ;   9  Write to STIC
    ENDR                    ;----
                            ; 408  (17*24 = 24 MOB registers)
                            ; 435  (carried forward)

    ; ... more updates ...

    ; WORST CASE PATH ANNOTATION:
    ; MOB copy:     408
    ; Collision:     72
    ; Ground GRAM: 1536
    ; Bullet GRAM:   58
    ; ====================
    ; Total:       2074 cycles (leaves ~1400 for other work)
```

### IntyBASIC Application

Track cycle budgets in comments for critical sections:

```basic
' ===== CRITICAL PATH - 60×/sec =====
' BUDGET: ~12,000 cycles (ISR takes ~2500)

GameLoop:
    WAIT                                ' Mandatory 60fps sync

    ' --- Sprite updates (~480 cycles) ---
    FOR i = 0 TO 7
        SPRITE i, X(i) + VISIBLE, Y(i), Card * 8
    NEXT i                              ' ~60 cyc/iter × 8 = 480

    ' --- Physics (~800 cycles) ---
    FOR i = 0 TO 9
        EnemyX(i) = EnemyX(i) + VelX(i) ' ~80 cyc/iter × 10 = 800
    NEXT i

    ' --- Collision detection (~1500 cycles) ---
    IF BulletActive THEN
        GOSUB CheckCollisions           ' ~150 + inner loops
    END IF

    ' ESTIMATED TOTAL: ~2780 / 12000 = 23% of budget
    GOTO GameLoop
```

**Frame Budget (NTSC at 60Hz):**
- Total available: **14,915 cycles/frame**
- ISR overhead: **~2,000-3,000 cycles** (music, input, GRAM)
- Game logic budget: **~10,000-12,000 cycles**
- **Safe target: ~10,000 cycles** (leaves safety margin)

---

## Memory Management Macros

### Compile-Time RAM Allocation Tracking

Space Patrol uses assembler macros to auto-assign RAM addresses with overflow detection:

```asm
.SCRMEM SET $102    ; Scratch RAM pool starts at $102
.SYSMEM SET $2F0    ; System RAM pool starts at $2F0

; SCRATCH macro: allocate from scratchpad
MACRO SCRATCH length
    EQU .SCRMEM             ; Variable gets current address
    .SCRMEM SET .SCRMEM + length
    IF .SCRMEM > $1F0
        ERR "Scratch Memory Overflow"  ; Assembler error!
    ENDI
ENDM

; Usage:
PlayerX    SCRATCH 1    ; Auto-assigned $102
PlayerY    SCRATCH 1    ; Auto-assigned $103
BulletX    SCRATCH 5    ; Auto-assigned $104-$108
```

**Benefits:**
- Automatic address assignment (no manual bookkeeping)
- Compile-time overflow detection
- Clear separation of memory regions
- Easy to see total usage in `.lst` file

**IntyBASIC Lesson:**
- IntyBASIC handles this automatically, but track variable counts manually
- 8-bit vars: **187 max** (1 free causes slowdown!)
- 16-bit vars: **25 max**
- Use meaningful names; trust compiler for addresses

---

## INITMEM: Compressed Initialization System

**Problem:** Initializing 50+ variables to non-zero values wastes ROM:
```asm
; Naive approach (3 words per init)
MVII #100, R0
MVO  R0,   EnemyHP
MVII #5,   R0
MVO  R0,   PlayerSpeed
; ... 50× = 150 ROM words!
```

**Space Patrol's Solution:** Compressed initialization records (1-2 words each).

### Record Format
```
Bits 15-10: Encoded value (6 bits)
Bits 9-0:   Variable address (10 bits)

Value Encoding:
  $20-$3F: Constants $00-$1F (direct encode)
  $00-$0F: Index into 8-bit constant table
  $10-$1E: Index into 16-bit constant table
  $1F:     Escape code (full 16-bit value follows)
```

### Usage
```asm
CALL INITMEM.0
    INIT EnemyHP,     100    ; Escaped value (2 words)
    INIT PlayerSpeed,   5    ; Direct-encoded (1 word)
    INIT Lives,         3    ; Direct-encoded (1 word)
    INIT_DONE                ; Terminator
```

**ROM Savings:** ~1.5 words/variable average vs 3 words naive.

**IntyBASIC Lesson:**
- Use `CONST` for repeated values
- Use `DATA` tables instead of duplicating init code
- Group similar initializations to reuse constants

---

## 1s Complement Fixed-Point Math

### Standard 8.8 Fixed-Point
```
[Integer: 8 MSBs][Fraction: 8 LSBs]
Reading X: MVI + SWAP (to move integer to low byte) = 14 cycles
```

### Space Patrol's Inverted Layout
```
[Fraction: 8 MSBs][Integer: 8 LSBs]
Reading X: MVI only (integer already in low byte!) = 8 cycles
```

**Savings:** 6 cycles per coordinate read × 12 sprites × 2 coords = **144 cycles/frame**.

**Why It Works:**
- 1s complement arithmetic is **commutative with rotation** (SWAP)
- Allows treating X/Y as single 16-bit word: `[Y frac][X int]`
- Fast block reads with `SDBD; MVI@`

**IntyBASIC Application:**
Not directly applicable (IntyBASIC uses 16-bit integers), but the principle is:
- **Store data in the format you access most frequently**
- Avoid repeated conversions in hot loops

---

## Two-Phase GRAM Update Strategy

### Separate Interrupt and Background Contexts

**Background Context (game loop):**
- Calculate what GRAM cards need updating
- Prepare bitmap data in shadow buffers
- Set flags indicating updates needed
- **No direct GRAM writes** (not in VBLANK!)

**Interrupt Context (ISR, during VBLANK):**
- Check flags
- Block-copy shadow data → GRAM
- Update STIC MOB registers
- **Cycle-counted to fit in ~3500 cycles**

### Example from Space Patrol

```asm
; Background: Prepare scrolling ground data
UpdateGroundPhase:
    MVI  PhaseCounter, R0
    INCR R0
    ANDI #$1F, R0           ; Wrap at 32
    MVO  R0, PhaseCounter

    ; Compute pointer to correct ground bitmap
    SLL  R0, 3              ; × 8 (each card = 8 bytes)
    ADDI #GroundBitmaps, R0
    MVO  R0, GDATA          ; Store pointer for ISR

; ISR: Copy prepared data to GRAM
ENGINE1:
    MVI  GDATA, R0          ; Get prepared pointer
    MVO  R0,    GGRAM       ; Write to GRAM destination
    ; ... (block copy follows)
```

**IntyBASIC Equivalent:**

Use `POKE _gram2_*` ISR variables instead of direct GRAM writes:

```basic
' Background: Prepare TinyFont digit for score display
ScoreCard = (ScoreCard + 1) MOD 8
Digit = #Score / 1000           ' Get thousands digit
BitmapIdx = PackedPairs(Digit)  ' Lookup in ROM table

' Trigger ISR to update GRAM (writes during VBLANK)
POKE $0107, 61 + ScoreCard      ' Target card
POKE $0108, 4                   ' 4 rows to copy
POKE $0345, BitmapIdx           ' Source bitmap (LAST = trigger!)
```

**Key:** Set `_gram2_bitmap` LAST. It triggers the ISR. If set before `_gram2_total`, ISR loop wraps to 65535 iterations!

---

## Data-Driven Level Design

### Pattern: Separate Data from Code

**Space Patrol's Spawn System:**

Instead of hardcoding:
```asm
IF Level = 1 THEN
    SpawnSaucer(50, 20, FAST)
ELSEIF Level = 2 THEN
    SpawnTank(30, 10, SLOW)
```

Use data tables:
```asm
SpawnTable_Level1:
    DECLE SPAWN_SAUCER, 50, 20, SPEED_FAST
    DECLE SPAWN_END

SpawnTable_Level2:
    DECLE SPAWN_TANK, 30, 10, SPEED_SLOW
    DECLE SPAWN_TANK, 70, 10, SPEED_SLOW
    DECLE SPAWN_END
```

**Benefits:**
- Easy to add levels (just data, no code)
- Non-programmers can edit
- ROM-efficient (data denser than code)

### IntyBASIC Application

Space Intruders uses this heavily:

```basic
' 32-wave cycle definitions
PatternBIndex:
    DATA 0,1,2,3,4,5,6,7,0,1,2,3,8,9,10,11
    DATA 0,1,2,3,12,13,14,15,0,1,2,3,4,5,6,7

WaveEntrances:
    DATA 0,1,0,2,0,1,0,2,0,1,0,2,0,1,0,2
    DATA 0,1,0,2,0,1,0,2,0,1,0,2,0,1,0,2

' Load wave data (called once per wave)
LoadWave: PROCEDURE
    PatternIdx = PatternBIndex(Level AND 31)
    Entrance = WaveEntrances(Level AND 31)
    IF PatternIdx = 0 THEN
        GOSUB LoadFullGrid
    ELSE
        GOSUB LoadCreativePattern
    END IF
    RETURN
END
```

---

## Build System: C Utilities for Data Generation

Space Patrol uses C programs to generate assembly from designer-friendly formats.

### Examples

**mkfont16:** `.fnt` bitmaps → compressed assembly
**wasm3:** `.wr3` world files → spawn tables + collision maps
**makerock:** Bitmap source → convolved rock/crater graphics

### Makefile Integration

```makefile
# Auto-generate assembly from source data
genasm/font.asm: fonts/*.fnt exe/mkfont16
    exe/mkfont16 fonts/*.fnt > genasm/font.asm

genasm/level1.asm: world/level1.wr3 exe/wasm3
    exe/wasm3 genasm/level1.asm world/level1.wr3

# ROM depends on generated files
bin/game.rom: main.asm genasm/font.asm genasm/level1.asm
    as1600 -o bin/game.rom main.asm
```

### IntyBASIC Application

Python script to generate wave data:
```python
# tools/generate_waves.py
import json

with open('data/waves.json') as f:
    waves = json.load(f)

with open('src/wave_data.bas', 'w') as out:
    out.write("' AUTO-GENERATED - DO NOT EDIT\n")
    out.write("WavePatterns:\n")
    for wave in waves:
        out.write(f"    DATA {wave['pattern']}, {wave['speed']}\n")
```

Designer-friendly JSON:
```json
[
  {"pattern": 0, "speed": 60},
  {"pattern": 1, "speed": 55},
  ...
]
```

---

## Key Takeaways for IntyBASIC Development

1. **Sprite Multiplexing:** Round-robin allocation enables >8 objects
2. **Cycle Budgeting:** Annotate expensive sections; profile with BORDER color
3. **Memory Tracking:** Use meaningful names; track 8/16-bit var counts
4. **GRAM Strategy:** Prepare data in main loop, update in VBLANK/ISR
5. **Data Layout:** Store data in the format you access most frequently
6. **Data-Driven Design:** Use DATA tables instead of IF/ELSEIF chains
7. **Build Automation:** Generate code from designer-friendly formats

---

## Additional References

- **Space Patrol Source:** `games/spacepatrol/` (this repository)
- **Joe Zbiciak's SDK-1600:** http://spatula-city.org/~im14u2c/intv/
- **Space Patrol Official Site:** http://spacepatrol.info/
- **CP1610 Instruction Timing:** jzIntv SDK documentation
