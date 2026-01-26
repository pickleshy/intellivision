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
- **Arrays are ZERO indexed** - `DIM arr(5)` gives indices 0-4

**Intellivoice:**
- **Call `VOICE INIT` only ONCE** at program start - Multiple calls can lock up real hardware (works in emulator but fails on console)

**Testing:**
- **Test on real hardware** - Emulator behavior differs from actual consoles
- **Get diverse testers** - Different ages find different issues

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
