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

# Run in emulator
arch -x86_64 ~/jzintv/bin/jzintv \
    --execimg=~/jzintv/bin/exec.bin \
    --gromimg=~/jzintv/bin/grom.bin \
    game.rom
```

## Project Structure

```
project/
├── CLAUDE.md
├── src/
│   └── main.bas          # Main game source
├── assets/
│   ├── graphics.bmp      # Source graphics (use IntyColor to convert)
│   └── sounds/           # Sound data
├── build/
│   ├── game.asm          # Generated assembly
│   ├── game.rom          # Compiled ROM
│   └── game.lst          # Listing file (for debugging)
├── lib/                  # Shared libraries/includes
└── build.sh              # Build script
```

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

**Card Format (Color Stack):**
```
Bits 0-7:   Card number (0-255 GROM, 256+ GRAM)
Bits 9-12:  Foreground color
Bit 13:     Advance color stack
```

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

**Music Data Format:**
```basic
music_label:
    MUSIC S1, -, -  ' Note on channel 1
    MUSIC -, S2, -  ' Note on channel 2
    MUSIC STOP      ' End marker

' Notes: C2-B6, use # for sharp (C#4)
' S = staccato, M = medium, - = silence
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

- Manual: https://github.com/nanochess/IntyBASIC/blob/master/manual.txt
- AtariAge Forums: https://atariage.com/forums/forum/144-intellivision-programming/
- Book: "Programming Games for Intellivision" by Oscar Toledo G.

## Claude Code Guidelines

When helping with IntyBASIC development:

1. **Memory is precious** - Intellivision has very limited RAM. Prefer 8-bit variables, reuse variables, use constants.

2. **WAIT is critical** - Every game loop must call `WAIT` exactly once to sync with the display and reset collision registers.

3. **Test incrementally** - Build and test frequently. Assembly errors can be cryptic.

4. **GRAM is limited** - Only 64 definable characters (cards 0-63). Plan graphics carefully.

5. **Sprites have limits** - Only 8 MOBs, and only 2-4 per scanline before flickering.

6. **Use the listing file** - `game.lst` shows memory addresses and helps debug.

7. **Comments are free** - Use `'` or `REM` liberally; they don't affect ROM size.
