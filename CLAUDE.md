# IntyBASIC Intellivision Development

## Overview

This project uses IntyBASIC to develop games for the Mattel Intellivision console (1979). IntyBASIC is an integer BASIC cross-compiler that generates CP1610 assembly code.

## Tool Locations (macOS Apple Silicon)

```
~/intybasic/intybasic     # IntyBASIC compiler
~/jzintv/bin/as1600       # Assembler (runs via Rosetta)
~/jzintv/bin/jzintv       # Emulator (runs via Rosetta)
~/jzintv/bin/exec.bin     # Intellivision EXEC ROM
~/jzintv/bin/grom.bin     # Intellivision GROM
```

## Build Commands

```bash
# Compile BASIC to assembly
intybasic game.bas game.asm

# Assemble to ROM
arch -x86_64 ~/jzintv/bin/as1600 -o game.rom -l game.lst game.asm

# Run in emulator (use jzintv_run wrapper - includes voice/ECS support)
~/jzintv/bin/jzintv_run game.rom

# Or use the project build script
./build.sh          # Just build
./build.sh run      # Build and run
./build.sh voice    # Build and run with Intellivoice
```

## Project Structure (IDE Layout)

This project is structured as an IntyBASIC "IDE" with shared libraries and individual game projects.

```
intv-game-builder/
├── CLAUDE.md                 # Development reference (this file)
├── lib/                      # Shared libraries
│   └── zmus_engine.bas       # ZMUS microprogrammed music engine
├── assets/
│   └── music/                # Shared music data files
│       ├── greensleeves_music.bas
│       ├── canon_music.bas
│       └── nutcracker_intybasic.bas
├── docs/                     # Documentation
├── games/                    # Individual game projects
│   └── orchestra-demo/
│       ├── src/main.bas      # Game source
│       ├── assets/           # Game-specific assets
│       ├── build/            # Compiled output
│       │   ├── game.asm
│       │   ├── game.rom
│       │   └── game.lst
│       └── build.sh          # Game build script
└── build.sh                  # Root build script (if any)
```

**Adding a new game:**
1. Create `games/your-game/src/`, `games/your-game/assets/`, `games/your-game/build/`
2. Copy `games/orchestra-demo/build.sh` as a template
3. Use `INCLUDE` with paths relative to project root for shared libraries

## IntyBASIC Language Reference

### Variables
- 8-bit variables: `a` to `z`, plus arrays `DIM array(size)`
- 16-bit variables: prefix with `#` → `#score`, `#array()`
- Constants: `CONST NAME = value`
- Signed/unsigned: `SIGNED var` or `UNSIGNED var`

### Control Flow
```basic
' Conditionals
IF condition THEN
    ' code
ELSEIF condition THEN
    ' code
ELSE
    ' code
END IF

' Single-line: IF condition GOTO label

' Loops
FOR i = 0 TO 10 STEP 1
    ' code
NEXT i

WHILE condition
    ' code
WEND

DO
    ' code
LOOP WHILE condition

' Jump table
ON expr GOTO label1, label2, label3
ON expr GOSUB proc1, proc2, proc3
```

### Procedures
```basic
label: PROCEDURE
    ' code
    RETURN
END
```

### Graphics

**Screen Modes:**
- `MODE 0, stack1, stack2, stack3, stack4` - Color Stack mode (4 colors cycle)
- `MODE 1` - Foreground/Background mode (independent colors per card)

**Display:**
- Screen is 20×12 cards (8×8 pixels each)
- BACKTAB address: row * 20 + column
- `PRINT AT position, value` - Write to screen
- `SCREEN array, x, y, width, height, stride` - Block copy

**Card Format (Color Stack) — GROM cards:**

The STIC uses an **interleaved** bit layout. The card number and color do NOT occupy contiguous bit ranges. This was verified by tracing IntyBASIC's compiled assembly output.

```
Bits 0-2:   Foreground color (low 3 bits, 0-7)
Bits 3-10:  GROM card number (card << 3, 8 bits = 0-255)
Bit 11:     0 (GROM flag)
Bit 12:     Foreground color bit 3 (for pastel/extended colors 8-15)
Bit 13:     Advance color stack
```

IntyBASIC encodes `PRINT AT pos COLOR color, "text"` as: `(grom_card << 3) XOR color`
Since GROM cards always have 000 in their low 3 bits, the XOR is effectively an OR.

**To change only the color of an existing GROM BACKTAB entry:**
```basic
' Mask $EFF8 clears bits 0-2 and bit 12 (all color bits)
#Card = PEEK($200 + position)
PRINT AT position, (#Card AND $EFF8) OR new_color
' Where new_color is 0-7 (e.g., 5=green, 7=white)
```

**WARNING:** Using wrong masks (e.g., clearing bits 3-5 or 9-12) will corrupt the card number and display garbage characters. The color bits are 0-2, NOT 9-12.

**BACKTAB Value Quick Reference (Color Stack):**

| Character | Color   | BACKTAB Value           | Example                    |
|-----------|---------|-------------------------|----------------------------|
| GROM 'A'  | Green 5 | (33 << 3) OR 5 = 269    | `PRINT AT pos, 269`       |
| GROM 'S'  | Green 5 | (51 << 3) OR 5 = 413    | `PRINT AT pos, 413`       |
| GROM 'S'  | White 7 | (51 << 3) OR 7 = 415    | `PRINT AT pos, 415`       |
| GRAM 0    | Blue 1  | (0 << 3) OR 1 + $800    | `PRINT AT pos, $0801`     |
| Space     | Any     | 0                        | `PRINT AT pos, 0`         |

GROM card numbers for letters: A=33, B=34, ..., Z=58. Digits: 0=16, 1=17, ..., 9=25.

**Card Format (Color Stack) — GRAM cards:**

```
Bits 0-2:   Foreground color (low 3 bits)
Bits 3-8:   GRAM card number (card << 3, 6 bits = 0-63)
Bits 9-10:  (unused)
Bit 11:     1 (GRAM flag)
Bit 12:     Foreground color bit 3
Bit 13:     Advance color stack
```

For GRAM cards in IntyBASIC: `(gram_card * 8) + color + $0800`

**Card Format (F/B Mode):**
```
Bits 0-7:   Card number
Bits 9-11:  Foreground color
Bit 12:     0=GROM, 1=GRAM
Bits 13-15: Background color
```

**GRAM Definition:**
```basic
DEFINE DEF00, count, label
' or
DEFINE ALTERNATE grom_card, count, label

label:
    BITMAP "........"
    BITMAP "..XXXX.."
    BITMAP ".X....X."
    BITMAP ".X....X."
    BITMAP ".XXXXXX."
    BITMAP ".X....X."
    BITMAP ".X....X."
    BITMAP "........"
```

### Sprites (MOBs - Movable Objects)

8 hardware sprites (0-7), each 8×8 or 8×16 pixels.

```basic
SPRITE 0, x + VISIBLE, y, card * 8 + color
SPRITE 1, x + VISIBLE + HIT, y + DOUBLEY, card * 8 + color + BEHIND

' Position: X (0-167), Y (0-104 visible)
' Flags: VISIBLE, HIT, BEHIND, DOUBLEX, DOUBLEY, FLIPX, FLIPY, MIRROR
```

**Collision Detection:**
```basic
IF COL0 AND HIT_SPRITE1 THEN ' Sprite 0 hit sprite 1
IF COL0 AND HIT_BACKGROUND THEN ' Sprite 0 hit background
WAIT ' Reset collision registers each frame
```

### Sound

3 tone channels + 1 noise channel + envelope generator.

```basic
' Simple tone
SOUND 0, frequency, volume  ' Channel 0-2, freq 0-4095, vol 0-15

' With envelope
SOUND 0, freq, volume + 16  ' Enable envelope on channel

' Noise
SOUND 4, noise_freq, channels  ' Noise mixed with channels (bits 0-2)

' Envelope
SOUND 5, period_low, period_high + shape * 16

' Play tracker music
PLAY music_label
PLAY OFF
```

**Music Data Format (Native IntyBASIC):**
```basic
music_label:
    DATA 7              ' Tempo (1-15, higher = faster)
    MUSIC A4,C4,G3,-    ' Three tone channels + drum
    MUSIC S,S,S,-       ' S = sustain (hold note)
    MUSIC -,-,-,-       ' - = silence
    MUSIC STOP          ' End marker

' Notes: C2-B6, use # for sharp (C#4), W for whole note
' Modifiers: S = sustain, M = medium, W = whole
```

### Music Systems Comparison

IntyBASIC supports two distinct music approaches:

| Feature | Native MUSIC/PLAY | ZMUS Engine |
|---------|-------------------|-------------|
| Setup | `PLAY SIMPLE` or `PLAY FULL` | `USR ZMUS_INIT` |
| Start | `PLAY song_label` | `USR ZMUS_PLAY(label)` |
| Update | Automatic (handled by ISR) | Manual `USR ZMUS_UPDATE` each frame |
| Stop | `PLAY OFF` | `USR ZMUS_STOP` |
| Data format | `MUSIC` statements | `DECLE` microprogrammed data |
| Channels | 2 (SIMPLE) or 3 (FULL) | 3 tone channels |
| Voice compat | SIMPLE leaves ch3 for voice | Full control |

**When to use which:**
- **Native MUSIC/PLAY**: Simpler, good for most games, integrates with Intellivoice
- **ZMUS Engine**: Direct PSG control, custom timing, microprogrammed sequences

## Library: ZMUS Music Engine

The ZMUS engine (`lib/zmus_engine.bas`) provides assembly-level music playback with direct PSG (AY-3-8914) control.

**Usage:**
```basic
' Include at top of your program
INCLUDE "lib/zmus_engine.bas"
INCLUDE "assets/music/your_song_zmus.bas"

' Initialize once at startup
USR ZMUS_INIT

' Start playing
USR ZMUS_PLAY(NUTMARCH)  ' Pass label of DECLE data

' Call every frame in game loop
main_loop:
    WAIT
    USR ZMUS_UPDATE
    ' ... game logic ...
    GOTO main_loop

' Stop playback
USR ZMUS_STOP

' Debug: play test tone (A4, 440Hz)
USR ZMUS_TEST
```

**Memory Layout:**
- Engine code: `$D000` (extra ROM segment)
- Stream record: `$360-$363` (4 words in RAM)
- PSG registers: `$1F0-$1FF`

**Creating ZMUS song data:**
Song data uses microprogrammed DECLE format. See existing songs in `assets/music/` for examples.

### Intellivoice

```basic
VOICE INIT              ' Initialize/reset Intellivoice
VOICE PLAY label        ' Play speech phrase
VOICE PLAY WAIT label   ' Play and wait for completion
VOICE NUMBER expr       ' Speak a number (0-999)
VOICE WAIT              ' Wait for speech to finish

' Check status
IF VOICE.AVAILABLE THEN ' Intellivoice detected
IF VOICE.PLAYING THEN   ' Currently speaking

' Define speech phrases (end with 0)
my_phrase:
    VOICE HH1,EH,LL,AO,PA2,0    ' "Hello"

' Phonemes: PA1-PA5, AA, AE, AO, AR, AW, AX, AY, BB1, BB2, CH, DD1, DD2,
' DH1, DH2, EH, EL, ER1, ER2, EY, FF, GG1, GG2, GG3, HH1, HH2, IH, IY,
' JH, KK1, KK2, KK3, LL, MM, NG, NN1, NN2, OR, OW, OY, PP, RR1, RR2,
' SH, SS, TH, TT1, TT2, UH, UW1, UW2, VV, WH, WW, XR, YR, YY1, YY2, ZH, ZZ
```

### Controllers

```basic
' Read controller (0 or 1)
c = CONT.key    ' Keypad: 0-9, 10=Clear, 11=Enter, 12+=disc
c = CONT1.key   ' Controller 2

' Disc directions (bits)
' 1=N, 2=NNE, 4=NE, 8=ENE, 16=E, 32=ESE, 64=SE, 128=SSE
' 256=S, 512=SSW, 1024=SW, 2048=WSW, 4096=W, 8192=WNW, 16384=NW, 32768=NNW

' Side buttons
c = CONT.button  ' Bits: 1=top, 2=bottom-left, 4=bottom-right
```

### Memory Map

```
$0000-$003F  Scratchpad RAM (8-bit vars here)
$0100-$035F  System RAM
$0200-$02EF  BACKTAB (screen memory)
$3800-$39FF  GRAM (64 cards × 8 bytes)
$5000-$6FFF  Default program ROM (8K)
$D000-$DFFF  Extra ROM (with ORG $D000)
$F000-$FFFF  Extra ROM (with ORG $F000)
```

### ROM Size and OPTION MAP (CRITICAL)

**Default 8K limit:** Without `OPTION MAP`, code must fit in $5000-$6FFF (8192 words).

**Symptom of overflow:** jzintv shows "CPU off in the weeds!" with a PC address outside ROM space (e.g., `$B203`). This means code overflowed into unmapped memory.

**Solution - Use OPTION MAP 2 for larger programs:**
```basic
    OPTION MAP 2    ' 42K static memory map (put at top of file!)

    ' ... main code in Segment 0 ($5000-$6FFF, 8K) ...

    SEGMENT 1       ' Switch to Segment 1 ($A000-$BFFF, 8K)

    ' ... additional procedures and data ...
```

**OPTION MAP 2 segments:**
| Segment | Address Range | Size |
|---------|---------------|------|
| 0 | $5000-$6FFF | 8K |
| 1 | $A000-$BFFF | 8K |
| 2 | $C040-$FFFF | 16K |
| 3 | $2100-$2FFF | 4K |
| 4 | $7100-$7FFF | 4K |
| 5 | $4810-$4FFF | 2K |

**Build output shows usage:** After successful compile with OPTION MAP, you'll see:
```
ROM USAGE (MAP #2):
    Static Seg #0        8K        7841       351 words
    Static Seg #1        8K         843      7349 words
    ...
```

**If Segment #0 shows negative available words**, move procedures/data to `SEGMENT 1`.

### Useful Statements

```basic
WAIT                ' Wait for vertical blank (call once per frame!)
DEFINE DEF00,n,lab  ' Define GRAM cards
SCREEN arr,x,y,w,h,s ' Block screen copy
SCROLL x, y         ' Hardware scroll offset
BORDER color        ' Border color (color stack mode)
POKE addr, value    ' Direct memory write
value = PEEK(addr)  ' Direct memory read
RANDOM(range)       ' Random number 0 to range-1
ABS(x), SGN(x)      ' Math functions
USR addr            ' Call assembly routine
ASM code            ' Inline assembly
```

### Inline Assembly

```basic
ASM MVI $200, R0    ' Single instruction
ASM MVII #1, R1

' Block of assembly
ASM ORG $D000
ASM ROMW 16
label:
ASM DECLE data1, data2
```

## Assembly Programming Patterns

### Critical: R4 Preservation

**R4 is IntyBASIC's stack pointer.** Any assembly routine called via `USR` MUST preserve R4 or IntyBASIC will crash.

```basic
ASM MY_ROUTINE: PROC
ASM         PSHR    R5              ' Save return address
ASM         PSHR    R4              ' CRITICAL: Save IntyBASIC stack pointer
ASM         ; ... your code here ...
ASM         PULR    R4              ' Restore R4 before returning
ASM         PULR    PC              ' Return
ASM         ENDP
```

**Symptom of R4 corruption:** Random crashes, "CPU off in the weeds", corrupted variables.

### PSG (AY-3-8914) Direct Access

The Intellivision's PSG is memory-mapped at `$1F0-$1FF`:

| Address | Description |
|---------|-------------|
| `$1F0` | Channel A period (low 8 bits) |
| `$1F1` | Channel B period (low 8 bits) |
| `$1F2` | Channel C period (low 8 bits) |
| `$1F4` | Channel A period (high 4 bits) |
| `$1F5` | Channel B period (high 4 bits) |
| `$1F6` | Channel C period (high 4 bits) |
| `$1F7` | Noise period |
| `$1F8` | Channel enable (bits 0-2=tone, 3-5=noise, 0=on) |
| `$1FB` | Channel A volume (0-15, bit 4=envelope) |
| `$1FC` | Channel B volume |
| `$1FD` | Channel C volume |
| `$1FE` | Envelope period low |
| `$1FF` | Envelope period high + shape |

**Example - Play A4 (440Hz) on channel A:**
```basic
ASM         MVII    #$FE,   R0      ' Period for 440Hz (NTSC)
ASM         MVO     R0,     $1F0    ' Channel A period low
ASM         CLRR    R0
ASM         MVO     R0,     $1F4    ' Channel A period high
ASM         MVII    #$3E,   R0      ' Enable tone A only
ASM         MVO     R0,     $1F8    ' Channel enable register
ASM         MVII    #$0F,   R0      ' Max volume
ASM         MVO     R0,     $1FB    ' Channel A volume
```

**Frequency calculation:** Period = 3579545 / (16 × frequency) for NTSC

### Assembly Pitfalls

1. **PLAY system conflict**: IntyBASIC's `PLAY SIMPLE`/`PLAY FULL` uses an ISR that writes PSG registers every frame. Direct PSG writes will be overwritten unless you use `PLAY OFF` first.

2. **R4 auto-increment**: R4 is used as auto-incrementing pointer. Using `MVI@` or `MVO@` with R4 will corrupt IntyBASIC's stack.

3. **ROM segment placement**: Use `ASM ORG $D000` with `ASM ROMW 16` for assembly routines to avoid conflicts with IntyBASIC-generated code.

4. **Register conventions**:
   - R0-R3: General purpose (freely usable)
   - R4: IntyBASIC stack pointer (PRESERVE!)
   - R5: Return address for `PSHR`/`PULR PC`
   - R6: Stack pointer (hardware)
   - R7: PC

5. **USR parameter passing**: First parameter to `USR routine(x)` is in R0.

### Common Patterns

**Game Loop:**
```basic
main_loop:
    WAIT              ' Sync to 60Hz
    GOSUB read_input
    GOSUB update_game
    GOSUB draw_screen
    GOTO main_loop
```

**Title Screen:**
```basic
    CLS
    MODE 0, 0, 0, 0, 0
    WAIT
    SCREEN title_data, 0, 0, 20, 12, 20
    
wait_start:
    WAIT
    IF CONT.button = 0 THEN GOTO wait_start
```

## Colors

```
0  = Black          8  = Grey
1  = Blue           9  = Cyan
2  = Red            10 = Orange
3  = Tan            11 = Brown
4  = Dark Green     12 = Pink
5  = Green          13 = Light Blue
6  = Yellow         14 = Yellow-Green
7  = White          15 = Purple
```

## Documentation Links

### Official Resources

- **IntyBASIC v1.5.1** (Latest): https://forums.atariage.com/topic/381333-intybasic-compiler-v151-bank-switching-integrated/
- **Manual**: https://github.com/nanochess/IntyBASIC/blob/master/manual.txt
- **Official Thread**: https://forums.atariage.com/topic/248209-the-intybasic-compiler-official-thread/
- **Source Code**: http://atariage.com/forums/topic/245278-intybasic-source-code-released/

### Books by Oscar Toledo G.

| Book | Description | Links |
|------|-------------|-------|
| Programming Games for Intellivision | Beginner - 4 games tutorial | [Amazon](https://www.amazon.com/Programming-Games-Intellivision-Toledo-Gutierrez/dp/1387929089/) / [Ebook](https://nanochess.org/store.html) |
| Advanced Game Programming for Intellivision | Music, sound FX, voice via PSG, graphics | [Amazon](https://www.amazon.com/-/es/dp/1716485630/) / [Ebook](https://nanochess.org/store.html) |

### Community Tools

| Tool | Purpose | Link |
|------|---------|------|
| IntyWorkshop | Online BITMAP statement generator | [AtariAge](http://atariage.com/forums/topic/243713-inty-workshop-updated/) |
| SpriteAid/IntyMapper | Sprite and map editing | [AtariAge](http://atariage.com/forums/topic/230758-a-couple-useful-tools/) |
| Sound Effect Editor | PSG sound design | [AtariAge](https://atariage.com/forums/topic/320358-sound-effect-editor/) |
| psg2bas | Convert CoolCV PSG logs to music | [AtariAge](http://atariage.com/forums/topic/275934-psg2bas-utility-to-convert-musicsounds/) |
| IntyMusic | Music viewer | [AtariAge](http://atariage.com/forums/topic/255530-intymusic-music-viewer/) |
| IntelliTool | Windows IDE | [AtariAge](http://atariage.com/forums/topic/266703-intellitool-ide-for-intybasic/) |
| Drawing Sheet | Graphics planning template | [AtariAge](http://atariage.com/forums/topic/271297-intellivision-drawing-sheet/) |

### Tutorials

- **Tips & Tricks**: http://atariage.com/forums/topic/257212-intybasic-tipstricks-and-dos-and-donts/
- **Voice without Intellivoice**: http://atariage.com/forums/topic/253650-voice-without-intellivoice/
- **SOUND 3 Envelopes**: http://atariage.com/forums/topic/248228-intybasic-sound3-example/
- **Coloured Squares Mode**: http://atariage.com/forums/topic/247948-intybasic-using-coloured-squares-mode/
- **Sprite Demos**: http://atariage.com/forums/topic/223031-intybasic-sprite-demos/

### Music Examples (by First Spear)

Great references for music composition:
- [Bach Fugue in D minor](https://atariage.com/forums/topic/304160-intybasic-rough-song-bach-fugue-in-d-minor/)
- [Flight of the Bumblebee](http://atariage.com/forums/topic/242617-intybasic-rough-song-flight-of-the-bumblebee/)
- [Maple Leaf Rag](http://atariage.com/forums/topic/242795-intybasic-rough-song-maple-leaf-rag/)
- [Fur Elise](http://atariage.com/forums/topic/241666-intybasic-rough-song-fur-elise/)
- [Full song list](https://forums.atariage.com/topic/248209-the-intybasic-compiler-official-thread/) (see "Songs made with IntyBASIC" section)

### Local Documentation

- `docs/IntyBASIC Tips_Tricks and Do's and Don'ts.pdf` - Community best practices
- `docs/The IntyBASIC compiler official thread.pdf` - Official thread archive with all resources

## Best Practices (from AtariAge Community)

See `docs/IntyBASIC Tips_Tricks and Do's and Don'ts.pdf` for full details.

**Code Structure:**
- **Plan ahead** - Write game loop logic on paper before coding
- **Use PROCEDURES** - `GOSUB ProcName` keeps code organized, avoids spaghetti
- **Avoid GOTOs** - Use `WHILE/WEND`, `FOR/NEXT`, `ON GOSUB` instead
- **Don't jump out of procedures** - Always exit via `RETURN`/`END` or stack overflow
- **Use descriptive variable names** - `PlayerX` not `x`, `LoopCounter` not `i`

**Performance:**
- **Use `ON GOTO`/`ON GOSUB`** instead of chains of `IF level = 1 THEN...`
- **Use lookup tables** instead of IF chains for data:
  ```basic
  Color = LevelColors(Level)  ' Instead of IF Level=1 THEN Color=RED...
  LevelColors: DATA CS_RED, CS_BLUE, CS_GREEN
  ```
- **Use `RANDOM(n)`** not `RAND` - RAND doesn't advance between WAITs

**Memory:**
- **Use `OPTION MAP 2`** - Don't limit yourself to 8K, modern carts support 42K+
- **Use `--CC3` or `--JLP`** flags for extra RAM if needed
- **Arrays are ZERO indexed and DIM specifies element count** - `DIM arr(5)` allocates exactly 5 elements (indices 0-4), NOT 6. If you need index 63, use `DIM arr(64)`. Off-by-one here causes reads from adjacent memory (other arrays/variables), leading to subtle bugs like sprites teleporting to wrong positions.

**Intellivoice:**
- **Call `VOICE INIT` only ONCE** at program start - Multiple calls can lock up real hardware (works in emulator but fails on console)

**Testing:**
- **Test on real hardware** - Emulator behavior differs from actual consoles
- **Get diverse testers** - Different ages find different issues

**Code Consolidation:**

As projects grow, repeated code patterns emerge. Extract these into utility procedures to reduce ROM usage and improve maintainability:

```basic
' --- Common utility procedures (place at start of SEGMENT 1) ---

' Hide all 8 hardware sprites in one call
HideAllSprites: PROCEDURE
    SPRITE 0, 0, 0, 0 : SPRITE 1, 0, 0, 0
    SPRITE 2, 0, 0, 0 : SPRITE 3, 0, 0, 0
    SPRITE 4, 0, 0, 0 : SPRITE 5, 0, 0, 0
    SPRITE 6, 0, 0, 0 : SPRITE 7, 0, 0, 0
    RETURN
END

' Silence SFX channel and reset state variables
SilenceSfx: PROCEDURE
    SOUND 2, , 0
    SfxVolume = 0
    SfxType = 0
    RETURN
END

' Reset enemy/game subsystem state (customize per game)
ClearEnemyState: PROCEDURE
    EnemyState = 0 : EnemyTimer = 0
    SPRITE SPR_ENEMY, 0, 0, 0
    RETURN
END
```

**Patterns worth consolidating:**
- **Full sprite hide blocks** - Any sequence that hides all 8 sprites → `GOSUB HideAllSprites`
- **SFX silence patterns** - `SOUND 2, , 0 : SfxVolume = 0 : SfxType = 0` → `GOSUB SilenceSfx`
- **State reset sequences** - Repeated variable resets + sprite hides → custom procedure
- **Transition sequences** - Screen clears, WAIT loops, HUD redraws

**When to consolidate:**
- Pattern appears 3+ times in codebase
- Pattern involves 3+ lines of code
- Pattern is likely to need changes (single point of maintenance)

**Audit technique:** Search for repeated patterns with grep:
```bash
grep -n "SPRITE.*0, 0, 0" src/main.bas | head -20
grep -n "SfxVolume = 0" src/main.bas
grep -n "RogueState = 0" src/main.bas
```

## Common Pitfalls (Learned the Hard Way)

### Color Stack BACKTAB Manipulation

When reading/modifying BACKTAB values directly with PEEK/PRINT AT:

1. **Color is in bits 0-2, NOT bits 9-12.** The STIC Color Stack format is interleaved — card number occupies bits 3-10, and foreground color occupies bits 0-2 (plus bit 12 for colors 8+). Many references incorrectly show color in bits 9-12.

2. **Use mask `$EFF8` to strip color.** This clears bits 0-2 and bit 12 without touching the card number. Then OR in the new color (0-7).

3. **Colors 8+ overflow in Color Stack mode.** The 3-bit foreground color field (bits 0-2) only supports colors 0-7. Colors like Cyan (9) will corrupt the card number via bit overflow, displaying garbage characters instead of text.

### DIM Array Sizing

`DIM arr(N)` allocates **exactly N elements** (indices 0 to N-1). This is a common off-by-one source:
- If your loop uses index 0-63, you need `DIM arr(64)`, not `DIM arr(63)`
- Out-of-bounds reads silently return data from whatever is next in memory (other arrays, variables), causing hard-to-trace bugs

### Sprite Colors vs Background

When cycling sprite colors, avoid colors that match background BACKTAB tile colors — the sprite becomes invisible against the background. For example, if your BACKTAB aliens use blue (1), don't include blue in a sprite color cycle.

### Sprite Attribute Color Encoding

Sprite attributes (third parameter to `SPRITE`) use the same color-in-low-bits pattern:
```basic
SPRITE n, x + SPR_VISIBLE, y, gram_card * 8 + color + $0800
'                                          ^^^^^ bits 0-2 = color (0-7)
'                                                 ^^^^^ bit 11 = GRAM flag
```

### Verifying Bit Formats via Assembly Output

When unsure about IntyBASIC's encoding, **always check the compiled .asm file**. This is the authoritative source:

1. Build the project to generate the .asm file
2. Search for the IntyBASIC source line (e.g., `PRINT AT 22 COLOR`)
3. Trace the `MVII` / `XOR` / `MVO@` instructions to see exact values
4. IntyBASIC uses XOR-chaining for string output — first char gets `base_value XOR color`, subsequent chars XOR a delta from the previous

Example from Space Intruders assembly:
```
MVII #408,R0       ; Base value for 'S' = GROM card 51 << 3 = 408
XOR _color,R0      ; XOR with color 5 → 408 XOR 5 = 413 written to BACKTAB
MVO@ R0,R4         ; Write to BACKTAB, auto-increment pointer
XORI #24,R0        ; XOR delta to get next char 'P' → 413 XOR 24 = 389
MVO@ R0,R4         ; Write 'P' to BACKTAB
```

This technique confirmed that foreground color is in bits 0-2 (not 9-12 as some references claim).

## Claude Code Guidelines

When helping with IntyBASIC development:

1. **Memory is precious** - Intellivision has very limited RAM. Prefer 8-bit variables, reuse variables, use constants.

2. **WAIT is critical** - Every game loop must call `WAIT` exactly once to sync with the display and reset collision registers.

3. **Test incrementally** - Build and test frequently. Assembly errors can be cryptic.

4. **GRAM is limited** - Only 64 definable characters (cards 0-63). Plan graphics carefully.

5. **Sprites have limits** - Only 8 MOBs, and only 2-4 per scanline before flickering.

6. **Use the listing file** - `game.lst` shows memory addresses and helps debug.

7. **Comments are free** - Use `'` or `REM` liberally; they don't affect ROM size.

8. **Watch ROM size** - Default 8K limit is easy to exceed with Intellivoice + music. If jzintv shows "CPU off in the weeds!", add `OPTION MAP 2` and use `SEGMENT 1` for overflow code/data.

9. **Run with voice** - Use `jzintv_run` or `./build.sh voice` for Intellivoice programs. Missing `--voice=1` causes silent failures.

10. **Verify bit formats in the .asm output** - Never trust documentation (including this file) over the compiled assembly. When doing BACKTAB manipulation, PEEK/POKE, or bit masking, always build first and check the .asm to confirm exact values and bit positions. See "Verifying Bit Formats via Assembly Output" above.

11. **Color Stack mode only supports colors 0-7 in foreground** - The 3-bit FG color field means only Black(0), Blue(1), Red(2), Tan(3), Dark Green(4), Green(5), Yellow(6), White(7). Pastel colors (8-15) require bit 12 set, which changes the BACKTAB word interpretation. Stick to 0-7 for `PRINT AT COLOR` text and BACKTAB card foregrounds.

## Critical Runtime Bugs (Debugged in Space Intruders)

These bugs were found through extensive debugging sessions and are easy to reintroduce. Future sessions should check for these patterns proactively.

### NEVER use GOTO to exit a FOR loop

IntyBASIC FOR/NEXT loops push state onto the R4 stack. Using GOTO to break out of a FOR loop **leaks stack space every iteration**. This causes a delayed crash — the game runs fine for minutes, then corrupts memory and resets.

```basic
' BAD — stack leak every time this runs:
FOR Row = 4 TO 0 STEP -1
    IF #AlienRow(Row) THEN
        GOTO DoneChecking       ' LEAKS! FOR state never cleaned up
    END IF
NEXT Row
DoneChecking:

' GOOD — use a sentinel variable, let the loop finish:
FoundRow = 255
FOR Row = 4 TO 0 STEP -1
    IF #AlienRow(Row) THEN
        IF FoundRow = 255 THEN FoundRow = Row
    END IF
NEXT Row
```

**Symptom:** Game works for 1-3 minutes, then crashes/resets to title screen. Saucer or other ISR-driven elements may still animate while gameplay is frozen.

### Sprite-to-BACKTAB coordinate offset (8 pixels)

Sprite coordinates have an **8-pixel offset** from BACKTAB card positions. BACKTAB column 0 starts at sprite X=8, BACKTAB row 0 starts at sprite Y=8. This is confirmed by `PLAYER_MIN_X = 8` aligning the player sprite with the left edge of the BACKTAB grid.

```basic
' Converting sprite position to BACKTAB card:
backtab_col = (sprite_x - 8) / 8
backtab_row = (sprite_y - 8) / 8

' Converting BACKTAB card to sprite position:
sprite_x = backtab_col * 8 + 8
sprite_y = backtab_row * 8 + 8
```

**Symptom:** Collision detection is off by 1 row and 1 column. Bullets appear to pass through aliens. Explosions appear at the wrong position.

### 8-bit variable unsigned underflow

IntyBASIC 8-bit variables are unsigned (0-255). Decrementing past 0 wraps to 255, not -1. This is especially dangerous with dynamic calculations:

```basic
' BAD — if Offset is 0 and MinCol is 5:
IF Offset + MinCol > 0 THEN     ' 0 + 5 = 5 > 0, TRUE
    Offset = Offset - 1          ' 0 - 1 = 255! Wraps to 255!
END IF

' GOOD — guard against underflow explicitly:
IF Offset > 0 THEN
    IF Offset + MinCol > 0 THEN
        Offset = Offset - 1
    ELSE
        ' Reverse direction instead
    END IF
ELSE
    ' Can't go lower, reverse
END IF
```

**Symptom:** PRINT AT with position 255+ writes past BACKTAB ($200-$2EF) into system RAM, corrupting variables. Game freezes or resets. May appear to work initially then crash when the variable reaches 0.

### PLAY SIMPLE conflicts with SOUND 4 (noise register)

`PLAY SIMPLE` (and `PLAY FULL`) use an ISR that writes PSG registers **every frame during WAIT**. The drum channel overwrites `SOUND 4` (noise mix register `$1F8`). Any noise-based SFX set via `SOUND 4` will be killed on the next WAIT.

```basic
' BAD — noise SFX immediately overwritten by drum ISR:
SOUND 4, 8, 4          ' Set noise — killed next WAIT!

' GOOD — use tone-based SFX on channel 3 (SOUND 2) instead:
SOUND 2, 200, 12       ' Tone on channel 3, not overwritten by PLAY SIMPLE
```

**Workaround:** Use `PLAY SIMPLE` (not FULL) and keep all SFX on channel 3 (`SOUND 2`). PLAY SIMPLE leaves channel 3 free for game use. Avoid `SOUND 4` entirely during music playback.

### Don't reinitialize PLAY mode from inside a PROCEDURE

Calling `PLAY SIMPLE` or `PLAY FULL` from inside a nested GOSUB/PROCEDURE can corrupt the ISR or stack state. Set the PLAY mode once at a top-level context (e.g., before entering the game loop), then only switch songs from inside procedures.

```basic
' BAD — reinitializing PLAY from inside nested procedure:
StartNewWave: PROCEDURE
    PLAY SIMPLE              ' Crashes! Already in PLAY SIMPLE
    PLAY si_dnb_fast
    RETURN
END

' GOOD — just switch the song:
StartNewWave: PROCEDURE
    PLAY si_dnb_fast         ' Fine — mode already set at StartGame
    RETURN
END
```

### SFX must be silenced manually during non-game-loop WAITs

If your game loop calls `UpdateSfx` to decay sound effects, that decay **stops running** during any sequence that uses its own WAIT loops (wave transitions, breather pauses, death sequences). The last SFX will sustain at full volume through the entire sequence.

```basic
' At the start of any transition with WAIT loops:
SOUND 2, , 0           ' Silence channel 3
SfxVolume = 0          ' Reset SFX state
SfxType = 0
```

### VOICE INIT must be gated on VOICE.AVAILABLE

`VOICE INIT` accesses Intellivoice hardware registers. If the emulator is not running with `--voice=1` (or on real hardware without the Intellivoice module), this can crash. Always gate it:

```basic
IF VOICE.AVAILABLE THEN
    VOICE INIT
END IF
```

`VOICE.AVAILABLE` safely detects hardware presence without initialization. `VOICE PLAY` and `VOICE NUMBER` are also safe to gate this way — they silently no-op if voice is unavailable.

### Button debounce at state transitions

When transitioning between game states (gameplay → game over → title screen → gameplay), the fire button is often still held from the previous state. Without debounce, the player blows through screens instantly.

```basic
' Two-phase debounce pattern:
' Phase 1: Wait for release
IF GameState = WAIT_RELEASE THEN
    IF CONT.BUTTON = 0 THEN GameState = WAIT_PRESS
    GOTO MainLoop
END IF
' Phase 2: Accept new press
IF GameState = WAIT_PRESS THEN
    IF CONT.BUTTON THEN
        ' Handle press
    END IF
END IF
```

### PRINT AT position bounds

BACKTAB is 240 entries (positions 0-239, address $200-$2EF). `PRINT AT` with position >= 240 writes to system RAM beyond BACKTAB, silently corrupting variables or stack. Always validate computed positions, especially when using dynamic offsets:

```basic
' Dangerous: dynamic offset could push past BACKTAB
PRINT AT #ScreenPos + AlienOffsetX + Col, #Card
' If AlienOffsetX wrapped to 255, this writes to garbage memory
```

### RETURN inside FOR loops is equally dangerous as GOTO

The original bug documentation covers `GOTO` out of FOR loops, but `RETURN` inside a FOR loop causes the **exact same R4 stack leak**. This was found in `FindShooter` where `RETURN` was used to exit early when a shooter was found — leaking stack space on every alien shot (~1/sec), crashing the game after 1-3 minutes.

```basic
' BAD — RETURN leaks FOR state just like GOTO:
FindShooter: PROCEDURE
    FOR Row = 4 TO 0 STEP -1
        IF #AlienRow(Row) AND #Mask THEN
            ABulletActive = 1
            RETURN               ' LEAKS! Same as GOTO out of FOR
        END IF
    NEXT Row
    RETURN
END

' GOOD — sentinel variable, let loop finish:
FindShooter: PROCEDURE
    HitRow = 255
    FOR Row = 4 TO 0 STEP -1
        IF #AlienRow(Row) AND #Mask THEN
            IF HitRow = 255 THEN HitRow = Row
        END IF
    NEXT Row
    IF HitRow < 255 THEN
        ABulletActive = 1
    END IF
    RETURN
END
```

**Rule: ANY early exit from a FOR loop (GOTO, RETURN, or implicit fall-through) leaks the R4 stack. Always use a sentinel variable and let the loop run to completion.**

### Unsigned underflow in collision comparisons

When comparing sprite positions with subtracted offsets, 8-bit unsigned underflow can silently break collision detection:

```basic
' BAD — if ABulletX < 6, this wraps to 250+:
IF BulletX >= ABulletX - 6 THEN  ' collision check

' GOOD — guard the subtraction:
IF ABulletX >= 6 THEN
    IF BulletX >= ABulletX - 6 THEN  ' safe
    END IF
END IF

' Also applies to pickup checks:
' BAD — if PowerUpX < 12, wraps to 244+:
IF PlayerX >= PowerUpX - 12 THEN  ' pickup range
```

**Symptom:** Collisions or pickups silently fail near the left/top edge of the screen. No crash, but gameplay events are missed. The comparison evaluates against 244-255 instead of a small negative number, so the condition is never true.

### Saucer explosion position ignores Y during chase

When the saucer is destroyed during a chase dive, the explosion BACKTAB position is calculated as `FlyX / 8` (column only), ignoring `FlyY`. The explosion always renders at row 0 regardless of the saucer's actual vertical position. To fix, include the row: `#ExplosionPos = (FlyY - 8) / 8 * 20 + (FlyX - 8) / 8`. Also guard against `FlyX / 8 >= 20` which wraps to the next BACKTAB row.

### Collision state guards checklist

Any code that sets `PlayerHit = 1` or triggers death SFX must check:
1. `DeathTimer = 0` — player is not already dying
2. `Invincible = 0` — player is not in post-respawn invincibility

Locations to guard (in Space Intruders):
- Alien bullet collision in `MoveAlienBullet`
- Saucer chase body collision in `UpdateSaucer`
- Any future collision source (e.g., alien reaching player row)

**Symptom without guards:** Death explosion SFX plays and sustains during invincibility, even though the downstream `PlayerHit` check correctly ignores the hit. The SFX triggers at the collision site before the state check.

### PRINT AT COLOR is persistent state

IntyBASIC's `PRINT AT position COLOR color, "text"` sets a **persistent foreground color** that applies to all subsequent `PRINT AT` calls without an explicit `COLOR`. This is not scoped to a line or procedure — it persists globally until the next `COLOR` is specified.

```basic
' BAD — score inherits yellow from WAVE banner:
PRINT AT 107 COLOR 6, "WAVE "     ' Sets persistent color to 6 (yellow)
' ... later in game loop ...
PRINT AT 227, <>#Score             ' Score renders yellow, not white!

' GOOD — always specify COLOR on HUD/score elements:
PRINT AT 220 COLOR COL_WHITE, "SCORE:"
PRINT AT 227 COLOR COL_WHITE, <>#Score
```

**Symptom:** HUD text (score, lives, labels) changes color after wave transitions, game over screens, or any sequence that uses `PRINT AT COLOR` with a different color. The text works fine initially but adopts the wrong color after the first color-setting PRINT in a different context.

**Rule: Always use explicit `COLOR` on any `PRINT AT` that renders persistent UI elements (score, lives, labels). Never rely on the default/inherited color state for HUD text.**

### CONT.BUTTON reads raw hardware ports (unreliable with ECS)

`CONT.BUTTON` compiles to a **raw read of PSG I/O ports** ($1FE/$1FF), XORed together and masked to bits 5-7. This is NOT debounced and reads mid-frame during game logic execution.

`CONT.KEY` uses the **debounced `_cnt1_key` variable** computed by the ISR during WAIT. It correctly identifies keypad presses with 2-frame debounce.

When ECS is loaded (`--ecsimg` flag in jzintv), the ECS keyboard shares the same I/O ports. **Keypad presses bleed into CONT.BUTTON** — pressing a keypad key makes CONT.BUTTON nonzero, indistinguishable from a side button press.

```basic
' BAD — keypad presses trigger this on title screen:
IF CONT.BUTTON THEN
    GOTO StartGame        ' Keypad "3" starts the game!
END IF

' GOOD — combine CONT.KEY gate with hold counter:
IF CONT.BUTTON THEN
    IF CONT.KEY >= 12 THEN
        IF FireHeld < 4 THEN FireHeld = FireHeld + 1
    ELSE
        FireHeld = 0       ' Keypad active — reset counter
    END IF
ELSE
    FireHeld = 0
END IF
IF FireHeld >= 4 THEN
    GOTO StartGame         ' Only after 4 frames of button-only input
END IF
```

**Why both guards are needed:**
- `CONT.KEY >= 12` alone fails: after releasing a keypad key, CONT.KEY returns to 12 while CONT.BUTTON may ghost for 1-2 more frames, triggering an instant start
- Hold counter alone fails: CONT.BUTTON stays set for the entire duration the keypad key is held, so any threshold is reached if the key is held long enough
- Combined: counter only increments when CONT.KEY confirms no keypad activity, AND requires sustained input to filter brief ghosts

**Also:** Terminal Enter key (`CONT.KEY = 11`) can ghost into jzIntv when launching from the command line. Avoid using Enter as an instant-action trigger on the title screen.

### The `<>` operator writes multiple BACKTAB positions for multi-digit numbers

IntyBASIC's `<>` (number-to-string) operator converts a number to its digit characters and writes them sequentially to BACKTAB starting at the `PRINT AT` position. A 3-digit number writes 3 consecutive positions:

```basic
' If Lives = 0 and Lives is unsigned 8-bit:
Lives - 1 = 255        ' Underflow!
PRINT AT 238, <> 255   ' Writes "2" at 238, "5" at 239, "5" at 240!
'                        Position 240 is PAST BACKTAB ($2EF)!
```

This is especially dangerous near the end of BACKTAB (positions 237-239, the bottom-right corner). Always guard `<>` writes near BACKTAB boundaries:

```basic
' SAFE — guard against multi-digit overflow:
IF Lives > 0 THEN
    PRINT AT 238, <> (Lives - 1)   ' Lives 1-9 = single digit, fits
END IF
```

**Symptom:** Seemingly random variable corruption or crashes when displaying numbers near the right edge or bottom of the screen. The extra digits silently write past position 239 into system RAM.

### Guard grid operations against empty data sets

When scanning arrays for min/max values (e.g., leftmost alive column in a grid), sentinel values from an empty scan can cause unsigned overflow if fed into arithmetic:

```basic
' Scanning for leftmost alive column:
HitRow = 8              ' Sentinel: "not found"
FOR LoopVar = 0 TO 9
    IF #AlienRow(LoopVar) THEN HitRow = LoopVar : ' found leftmost
NEXT LoopVar

' BAD — if grid is empty, HitRow=8, LoopVar ended at 0:
IF HitRow > 0 THEN
    AlienOffsetX = AlienOffsetX + HitRow   ' Adds 8! Overflow!
    BossCol = BossCol - HitRow             ' Underflows to 252!
END IF

' GOOD — verify scan found valid data:
IF HitRow > 0 AND HitRow <= LoopVar THEN
    ' Safe: HitRow is within actual data range
END IF
```

**Symptom:** Crash or corruption at the exact moment the last element is removed (last alien killed, last item collected). The empty-set case is rarely tested and the sentinel value passes simple `> 0` guards.

### Unsigned AlienOffsetX limits left march range for sparse formations

When using sparse alien formations (diamond, V-shape, etc.) where the leftmost alive column is > 0, the unsigned 8-bit `AlienOffsetX` creates an asymmetric march range. The grid can reach the right screen edge but stops early on the left because `AlienOffsetX` can't go below 0.

```basic
' Problem: Diamond leftmost at column 2, AlienOffsetX = 0
' Screen position = 0 + 2 = 2 (can't reach column 0!)
' But rightmost at column 6 can reach screen column 19

' Fix: Normalize grid data after loading so leftmost alive = column 0
' Shift all bitmasks right, increase AlienOffsetX to compensate
IF LeftmostCol > 0 THEN
    FOR Row = 0 TO ALIEN_ROWS - 1
        #AlienRow(Row) = #AlienRow(Row) / ColMaskData(LeftmostCol)
    NEXT Row
    AlienOffsetX = AlienOffsetX + LeftmostCol
    ' Also adjust boss column positions
    FOR BossIdx = 0 TO BossCount - 1
        BossCol(BossIdx) = BossCol(BossIdx) - LeftmostCol
    NEXT BossIdx
END IF
```

**Symptom:** Sparse formations march all the way to the right edge but reverse too early on the left, as if dead aliens are still present. The effect worsens as left-side aliens are killed.

### Clear screen regions when switching drawing modes

When two drawing modes use different offset calculations for the same screen region (e.g., a reveal animation vs standard gameplay), switching modes leaves "ghost" tiles from the old mode. The new mode's drawing and trail-clearing only covers its own coordinate range.

```basic
' Reveal mode draws at: WaveRevealCol + Col
' Standard mode draws at: AlienOffsetX + Col
' If AlienOffsetX > WaveRevealCol after normalization,
' tiles at positions WaveRevealCol..AlienOffsetX-1 are never overwritten

' Fix: one-time full clear of the shared screen region at mode switch
IF RevealMode = 0 AND PrevRevealMode = 1 THEN
    FOR Row = 0 TO ALIEN_ROWS - 1
        FOR Col = 0 TO 19
            PRINT AT RowStart + Col, 0
        NEXT Col
    NEXT Row
END IF
```

**Symptom:** Ghost tiles (colored squares, partial characters) persist in a strip on one side of the screen after an animation completes. They never go away because neither the new mode's drawing nor its trail-clearing touches those positions.

**General rule:** Whenever code switches between two drawing systems that use different offset calculations for the same BACKTAB region, clear the entire region once at the transition point.

### Reset state completely on wave/subwave transitions

When transitioning between subwaves (Pattern A → Pattern B) or waves, **all gameplay-relevant state must be explicitly reset**. Variables that accumulate during gameplay (march speed, power-up timers, SFX state) will carry over and cause incorrect behavior in the new wave.

```basic
' BAD — LoadPatternB resets aliens but not march speed:
' Pattern A accelerated CurrentMarchSpeed to 20 via descents
' Pattern B aliens immediately march at full speed!

' GOOD — reset speed when loading new pattern:
CurrentMarchSpeed = BaseMarchSpeed  ' Reset to wave's base speed
```

**Checklist for wave/subwave transitions:**
- `CurrentMarchSpeed = BaseMarchSpeed` (march speed)
- `MarchCount = 0` (march timer)
- `BombExpTimer = 0` (chain explosion state)
- `SfxVolume = 0 : SfxType = 0` (sound effects)
- Any power-up timers, bullet states, animation counters

## Performance Optimization Patterns

### ROM-based lookup tables vs FOR loop shifts

Bitmask shift operations (`FOR LoopVar = 1 TO Col : #Mask = #Mask * 2 : NEXT`) are extremely common in grid-based games but consume ~305 CPU cycles per lookup (for column 5). Replace with a ROM DATA table for ~31 cycles per lookup (89% reduction):

```basic
' BAD — 14 shift loops across codebase eat ~27-37% of frame budget during heavy action:
#Mask = 1
FOR LoopVar = 1 TO Col
    #Mask = #Mask * 2
NEXT LoopVar

' GOOD — ROM lookup table (zero RAM cost, constant time):
ColMaskData:
    DATA 1, 2, 4, 8, 16, 32, 64, 128, 256, 512

' Usage:
#Mask = ColMaskData(Col)
```

**Impact (measured in Space Intruders):**
- 14 shift loops replaced, ROM shrank by 319 words
- Normal gameplay: 4-7% of frame budget freed
- Heavy action (bomb explosion scanning all 12 cells): 27-37% freed
- CP1610 at ~895 kHz NTSC = ~14,915 cycles per frame at 60fps

**When to use:** Any repeated power-of-2 calculation, bitmask generation, or grid column addressing. Leave sequential shifts in place only when iterating columns in order (the shift is inherent to the loop).

### CPU profiling with BORDER color band

Use the STIC border color to visualize CPU usage per frame:

```basic
GameLoop:
    WAIT
    IF DebugMode THEN BORDER COL_RED    ' Start timing
    ' ... all game logic ...
    IF DebugMode THEN BORDER 0          ' End timing
    GOTO GameLoop
```

The red band height on screen is proportional to CPU time used. Taller band = more CPU consumed. Toggle with a keypad cheat code (e.g., type "36") so it's available during testing but hidden in normal play.

### DIM arrays consume 16-bit variable slots; DATA tables don't

`DIM #array(N)` allocates N words from the 16-bit variable pool (max 25 slots). If you run out, switch to ROM-based `DATA` tables which cost zero RAM:

```basic
' BAD — costs 10 of 25 16-bit variable slots:
DIM #ColMask(10)
FOR i = 0 TO 9 : #ColMask(i) = ColMaskData(i) : NEXT i

' GOOD — zero RAM cost, stored in ROM:
ColMaskData:
    DATA 1, 2, 4, 8, 16, 32, 64, 128, 256, 512
' Access: #Mask = ColMaskData(index)
```

### Use ADD instead of MUL for doubling

The CP1610 has no hardware multiply — IntyBASIC's `* 2` compiles to a software multiply routine. Use `var + var` instead, which compiles to a single `ADD` instruction:

```basic
' BAD — calls software multiply (~50+ cycles):
#Mask = #Mask * 2

' GOOD — single ADD instruction (~6 cycles):
#Mask = #Mask + #Mask
```

This applies to any power-of-2 multiply. For `* 4`, chain two adds: `#v = #v + #v : #v = #v + #v`. For arbitrary multiplies, stick with `*` since the alternatives are worse.

### OR chain vs FOR loop for boolean checks

When checking if ANY element in a small array is nonzero, an OR chain is faster than a loop with addition:

```basic
' SLOW — loop overhead per iteration (branch, increment, compare):
#Sum = 0
FOR Row = 0 TO 4
    #Sum = #Sum + #AlienRow(Row)
NEXT Row
IF #Sum > 0 THEN ...

' FAST — single expression, no loop overhead:
IF #AlienRow(0) OR #AlienRow(1) OR #AlienRow(2) OR #AlienRow(3) OR #AlienRow(4) THEN ...
```

Best for small fixed-size arrays (5-10 elements). For larger or variable-size arrays, the loop is more maintainable.

### Row-level pre-checks to skip expensive inner-loop operations

When an inner loop calls a PROCEDURE conditionally (e.g., checking if a grid cell is a boss), hoist the check outside the column loop at the row level:

```basic
' SLOW — FindBoss scans boss array on every cell:
FOR Col = 0 TO 9
    IF BossCount > 0 THEN
        GOSUB FindBoss    ' Called 10× per row even if no bosses on this row
    END IF
NEXT Col

' FAST — pre-check once per row:
RowHasBoss = 0
FOR BossIdx = 0 TO BossCount - 1
    IF Row = BossRow(BossIdx) THEN RowHasBoss = 1
NEXT BossIdx
FOR Col = 0 TO 9
    IF RowHasBoss THEN
        GOSUB FindBoss    ' Only called when this row actually has a boss
    END IF
NEXT Col
```

GOSUB has overhead (push R5, branch, return) even if the procedure does nothing. Avoiding unnecessary calls in tight inner loops saves significant frame budget.

### Track "last cleared" state to avoid redundant BACKTAB writes

When game logic progressively changes a screen region (e.g., aliens descending row by row), track what was last cleared to avoid re-clearing already-empty rows:

```basic
' BAD — clears rows 0 through AlienOffsetY every frame:
FOR ClearRow = 0 TO AlienOffsetY - 1
    ' Clear entire row... (redundantly re-clears rows cleared last frame)
NEXT ClearRow

' GOOD — only clear newly vacated rows:
IF AlienOffsetY > LastClearedY THEN
    FOR ClearRow = LastClearedY TO AlienOffsetY - 1
        ' Clear row...
    NEXT ClearRow
    LastClearedY = AlienOffsetY
END IF
```

Reset the tracking variable (`LastClearedY = 0`) at wave/level transitions. Each `PRINT AT 0` is a BACKTAB write (~12 cycles); clearing 20 columns × 5 rows = 100 unnecessary writes per frame.

### Extract repeated code blocks into PROCEDUREs

When the same 3+ line block appears in multiple places, extract it into a PROCEDURE. This saves ROM words (each duplicate costs the full instruction count) at the cost of one GOSUB/RETURN overhead per call:

```basic
' Before: 6 identical copies × 5 lines = 30 lines / ~60 ROM words
FlyState = 0
#FlyPhase = 0
#FlyLoopCount = RANDOM(360) + 180
SPRITE SPR_SAUCER, 0, 0, 0
SPRITE SPR_SAUCER2, 0, 0, 0

' After: 1 procedure + 6 GOSUB calls = ~17 ROM words saved per duplicate
DeactivateSaucer: PROCEDURE
    FlyState = 0
    #FlyPhase = 0
    #FlyLoopCount = RANDOM(360) + 180
    SPRITE SPR_SAUCER, 0, 0, 0
    SPRITE SPR_SAUCER2, 0, 0, 0
    RETURN
END
```

**Rule of thumb:** Extract if 3+ copies exist and the block is 3+ lines. Don't extract single-use code — the GOSUB overhead isn't worth it.

### Bit-packing boolean flags into a single 16-bit variable

When running low on 8-bit variable slots (max 187), pack multiple boolean flags into one 16-bit variable using bitwise operations. This trades slightly more complex code for significant variable savings:

```basic
' Define flag constants (powers of 2)
CONST FLAG_BULLET    = 1        ' Bit 0
CONST FLAG_ABULLET   = 2        ' Bit 1
CONST FLAG_CAPTURE   = 4        ' Bit 2
CONST FLAG_PLAYERHIT = 16       ' Bit 4
CONST FLAG_DEBUG     = 128      ' Bit 7
CONST FLAG_REVEAL    = 256      ' Bit 8 (needs 16-bit var)

' Declare the packed variable
#GameFlags = 0

' Set a flag (turn bit ON):
#GameFlags = #GameFlags OR FLAG_BULLET

' Clear a flag (turn bit OFF):
#GameFlags = #GameFlags AND ($FFFF XOR FLAG_BULLET)
' Or pre-compute the clear mask: CONST CLR_BULLET = $FFFE

' Test a flag:
IF #GameFlags AND FLAG_BULLET THEN ...      ' True if bit is set
IF (#GameFlags AND FLAG_REVEAL) = 0 THEN ... ' True if bit is clear
```

**Impact (measured in Space Intruders):**
- 10 boolean variables → 1 16-bit variable
- Freed 10 of 187 8-bit slots (177 used after)
- Cost: 1 of 25 16-bit slots

**When to use:** When 8-bit variables are scarce and you have multiple true/false flags. Group related flags together. Keep frequently-tested flags in the low byte for slightly faster access.

### GRAM card reuse between game states

GRAM cards defined for one game state (e.g., title screen custom font) can be redefined when entering another state (e.g., gameplay). This effectively doubles your GRAM budget for state-specific graphics:

```basic
' Title screen uses GRAM cards 25-36 for custom "SPACE INTRUDERS" font
CONST GRAM_FONT_S = 25
CONST GRAM_FONT_P = 26
' ... etc

TitleScreen:
    DEFINE GRAM_FONT_S, 12, TitleFontGfx  ' Load 12 custom letters
    ' ... display title ...

' At gameplay start, redefine those same cards for HUD use
StartGame:
    DEFINE GRAM_FONT_S, 4, PowerupIconGfx  ' Cards 25-28 now hold powerup icons
    WAIT
    DEFINE 29, 4, HudIndicatorGfx          ' Cards 29-32 for HUD indicators
    ' ...

' Display a gameplay HUD element using the redefined card:
PRINT AT 234, (GRAM_FONT_S * 8) + color + $0800
```

**Constraints:**
- DEFINE loads ~2-4 cards per WAIT without flicker
- Spread large redefines across multiple WAITs
- Cards revert to garbage if you return to title without re-defining

**When to use:** Any graphics that are exclusive to one game state (title-only fonts, gameplay-only HUD icons, cutscene-only art).

### Dirty flag pattern for expensive drawing operations

When a drawing procedure is expensive (loops over grid, multiple PRINT ATs), track whether anything changed and skip the call when nothing needs redrawing:

```basic
' BAD — DrawAliens called every frame even when nothing changed:
GameLoop:
    WAIT
    GOSUB DrawAliens    ' 50+ PRINT AT calls, always runs
    GOTO GameLoop

' GOOD — only draw when dirty:
AliensDirty = 0

GameLoop:
    WAIT

    ' Animation tick sets dirty flag
    ShimmerCount = ShimmerCount + 1
    IF ShimmerCount >= 16 THEN
        ShimmerCount = 0
        AnimFrame = AnimFrame XOR 1
        AliensDirty = 1
    END IF

    ' Alien killed sets dirty flag (in collision code)
    ' March occurred sets dirty flag (in march code)

    ' Single conditional draw
    IF AliensDirty THEN
        GOSUB DrawAliens
        AliensDirty = 0
    END IF

    GOTO GameLoop
```

**Impact:** Reduces DrawAliens from 60 calls/sec to ~4-10 calls/sec (only on animation frames, kills, or marches).

**When to use:** Any procedure that:
- Takes significant CPU time (large loops, many BACKTAB writes)
- Produces identical output when called repeatedly with unchanged state
- Has discrete "change events" that can set a dirty flag

### Inline GOSUB calls in hot paths when lookup is simple

When a small lookup procedure is called frequently in performance-critical code, inline the logic to eliminate GOSUB/RETURN overhead (~25 cycles per call):

```basic
' BAD — FindBoss called 50+ times per frame in collision loops:
FOR Col = 0 TO 9
    AlienGridCol = Col
    GOSUB FindBoss      ' ~25 cycle overhead × 50 calls = 1250 cycles
    IF FoundBoss < 255 THEN ...
NEXT Col

FindBoss: PROCEDURE
    FoundBoss = 255
    FOR BossIdx = 0 TO BossCount - 1
        IF BossHP(BossIdx) > 0 THEN
            IF AlienGridRow = BossRow(BossIdx) THEN
                IF AlienGridCol = BossCol(BossIdx) THEN FoundBoss = BossIdx
            END IF
        END IF
    NEXT BossIdx
    RETURN
END

' GOOD — inline the lookup:
FOR Col = 0 TO 9
    FoundBoss = 255
    IF BossCount > 0 THEN
        FOR BossIdx = 0 TO BossCount - 1
            IF BossHP(BossIdx) > 0 THEN
                IF AlienGridRow = BossRow(BossIdx) THEN
                    IF Col = BossCol(BossIdx) OR Col = BossCol(BossIdx) + 1 THEN
                        FoundBoss = BossIdx
                    END IF
                END IF
            END IF
        NEXT BossIdx
    END IF
    IF FoundBoss < 255 THEN ...
NEXT Col
```

**Trade-off:** Increases ROM size (duplicated code) but eliminates call overhead in tight loops. Profile with BORDER color band to verify the CPU savings justify the ROM cost.

**When to inline:**
- Procedure is called 10+ times per frame in nested loops
- Procedure body is small (<10 lines)
- Call sites can use loop variables directly (avoiding parameter setup)

**When to keep GOSUB:**
- Procedure is called 1-3 times per frame
- Procedure body is large (>20 lines)
- Code clarity matters more than microseconds

## CP1610 Processor Reference

The Intellivision uses a General Instrument CP1610 microprocessor (circa 1975). Understanding the CPU is essential for performance optimization and hand-tuned assembly routines.

### Architecture Overview

| Spec | Value |
|------|-------|
| Word size | 16-bit |
| Clock | 894.886 kHz (NTSC), 1.0 MHz (PAL) |
| Cycles per frame | ~14,915 (NTSC 60Hz), ~20,000 (PAL 50Hz) |
| Address space | 64K words (16-bit addressing) |
| Manufacturer | General Instrument, 1975 |

### Registers

| Register | Purpose | Notes |
|----------|---------|-------|
| R0 | General purpose | Freely usable |
| R1 | General purpose | Freely usable |
| R2 | General purpose | Freely usable |
| R3 | General purpose | Freely usable |
| R4 | IntyBASIC stack pointer | **MUST PRESERVE in USR routines** |
| R5 | Return address | Used by PULR PC pattern |
| R6 | Hardware stack pointer | System stack |
| R7 | Program counter | Execution pointer |

R4 and R5 support **auto-increment** addressing modes (`MVI@ R4, R0` reads from [R4] then increments R4). IntyBASIC relies on R4 as its variable stack — corrupting it causes delayed crashes.

### Common Instructions

| Instruction | Cycles | Description |
|-------------|--------|-------------|
| `MVI addr, Rd` | 10 | Load from memory to register |
| `MVO Rs, addr` | 11 | Store from register to memory |
| `MVII #imm, Rd` | 8 | Load immediate to register |
| `MVI@ Rs, Rd` | 8 | Load indirect (auto-increment if Rs=R4/R5) |
| `MVO@ Rs, Rd` | 9 | Store indirect (auto-increment if Rd=R4/R5) |
| `ADD Rs, Rd` | 6 | Rd = Rd + Rs |
| `ADDI #imm, Rd` | 8 | Rd = Rd + immediate |
| `SUB Rs, Rd` | 6 | Rd = Rd - Rs |
| `SUBI #imm, Rd` | 8 | Rd = Rd - immediate |
| `INCR Rd` | 6 | Rd = Rd + 1 |
| `DECR Rd` | 6 | Rd = Rd - 1 |
| `AND Rs, Rd` | 6 | Rd = Rd AND Rs |
| `XOR Rs, Rd` | 6 | Rd = Rd XOR Rs |
| `CMP Rs, Rd` | 6 | Compare (sets flags, no store) |
| `CMPI #imm, Rd` | 8 | Compare with immediate |
| `B addr` | 9 | Unconditional branch |
| `BC addr` | 7/9 | Branch if carry (7 if not taken, 9 if taken) |
| `BEQ addr` | 7/9 | Branch if equal/zero |
| `BNE addr` | 7/9 | Branch if not equal |
| `BPL addr` | 7/9 | Branch if plus (positive) |
| `BMI addr` | 7/9 | Branch if minus (negative) |
| `PSHR Rs` | 9 | Push register to stack (R6) |
| `PULR Rd` | 11 | Pull from stack to register |
| `JSR R5, addr` | 12 | Jump to subroutine (saves return in R5) |
| `CLRR Rd` | 6 | Clear register (Rd = 0) |
| `NEGR Rd` | 6 | Negate register (Rd = -Rd) |
| `SWAP Rd` | 6 | Swap bytes in register |

### Cycle Budget Planning

At ~14,915 cycles per frame (NTSC), here's how common operations cost:

| Operation | Approx Cycles | % of Frame |
|-----------|---------------|------------|
| Single BACKTAB write | 12-15 | 0.1% |
| Clear full screen (240 cards) | ~3,000 | 20% |
| IntyBASIC GOSUB/RETURN | ~25 | 0.17% |
| IntyBASIC FOR loop iteration | ~30 | 0.2% |
| IntyBASIC IF/THEN | ~15-25 | 0.1-0.17% |
| Multiply (software) | ~50-80 | 0.3-0.5% |
| Sprite update (1 MOB) | ~40 | 0.27% |

**Red flag thresholds:**
- If a single procedure takes >1,000 cycles, profile it
- If total game loop exceeds ~12,000 cycles, you'll see slowdown
- Leave ~2,000-3,000 cycles for ISR overhead (music, input)

### Memory-Mapped Hardware

| Address | Device |
|---------|--------|
| `$0000-$003F` | Scratchpad RAM (8-bit vars) |
| `$0100-$035F` | System RAM |
| `$0200-$02EF` | BACKTAB (screen memory) |
| `$01F0-$01FF` | PSG (AY-3-8914 sound chip) |
| `$0000-$003F` | STIC control registers |
| `$3800-$39FF` | GRAM (64 cards × 8 bytes) |
| `$5000-$6FFF` | Cartridge ROM (default 8K) |

### Assembly Calling Convention (IntyBASIC)

When writing `USR`-callable assembly:

```asm
MY_ROUTINE: PROC
    PSHR    R5          ; Save return address
    PSHR    R4          ; CRITICAL: Save IntyBASIC stack pointer

    ; R0 contains first parameter from USR call
    ; Use R0-R3 freely
    ; Do NOT use MVI@/MVO@ with R4

    ; Return value goes in R0
    MVII    #42, R0     ; Example: return 42

    PULR    R4          ; Restore IntyBASIC stack
    PULR    PC          ; Return (pops R5 into PC)
    ENDP
```

### Optimization Quick Reference

| Pattern | Slow | Fast |
|---------|------|------|
| Multiply by 2 | `* 2` (~50 cyc) | `+ var` (~6 cyc) |
| Loop for shift | `FOR...* 2...NEXT` (~305 cyc) | DATA table lookup (~31 cyc) |
| Clear array | FOR loop | Inline assignments for small arrays |
| Check any nonzero | FOR + sum | OR chain for fixed-size arrays |
| Repeated GOSUB | GOSUB in inner loop | Pre-check, hoist outside loop |

### Useful jzIntv Debugger Commands

When running `jzintv` with `--debugger`:

```
g               ; Go (run)
b $5000         ; Set breakpoint at address
s               ; Step one instruction
r               ; Show registers
m $200 $20      ; Dump memory (BACKTAB start)
w               ; Watch expression
q               ; Quit
```

Use `--sym-file=game.sym` (if generated) for symbolic debugging with labels.

### References

- **jzIntv SDK Documentation**: Included with jzIntv distribution
- **CP1610 Programmer's Reference**: AtariAge archives
- **as1600 Assembler Manual**: `~/jzintv/doc/` directory
- **Oscar Toledo G.'s Books**: Cover assembly optimization in depth
