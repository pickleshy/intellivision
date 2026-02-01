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
