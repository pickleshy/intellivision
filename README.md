# IntyBASIC Game Builder

A development environment for creating Mattel Intellivision games using IntyBASIC.

## Features

- Shared library system for reusable code
- Multiple game projects in one workspace
- Pre-built music engine and demo songs
- Build scripts with emulator integration
- Comprehensive documentation in CLAUDE.md

## Requirements

### macOS (Apple Silicon)

1. **IntyBASIC Compiler** - Install to `~/intybasic/`
   - Download from: https://nanochess.org/intybasic.html

2. **jzIntv Emulator** - Install to `~/jzintv/`
   - Download from: http://spatula-city.org/~im14u2c/intv/
   - Requires Intellivision ROM files (exec.bin, grom.bin) in `~/jzintv/bin/`

3. **Rosetta 2** (Apple Silicon only)
   ```bash
   softwareupdate --install-rosetta
   ```

### Expected Tool Paths

```
~/intybasic/intybasic      # IntyBASIC compiler
~/jzintv/bin/as1600        # Assembler
~/jzintv/bin/jzintv        # Emulator
~/jzintv/bin/exec.bin      # Intellivision EXEC ROM
~/jzintv/bin/grom.bin      # Intellivision GROM
~/jzintv/bin/ivoice.bin    # Intellivoice ROM (optional)
```

## Quick Start

### Build and Run the Demo

```bash
# Build the orchestra demo
./games/orchestra-demo/build.sh

# Build and run in emulator
./games/orchestra-demo/build.sh run

# Build and run with Intellivoice
./games/orchestra-demo/build.sh voice
```

### Create a New Game

1. **Create project structure:**
   ```bash
   mkdir -p games/my-game/{src,assets,build}
   cp games/orchestra-demo/build.sh games/my-game/
   ```

2. **Edit build.sh** - Update the output filenames:
   ```bash
   ASM="$BUILD_DIR/mygame.asm"
   ROM="$BUILD_DIR/mygame.rom"
   LST="$BUILD_DIR/mygame.lst"
   ```

3. **Create your game** at `games/my-game/src/main.bas`:
   ```basic
   ' My Intellivision Game
   OPTION MAP 2

   ' Use shared music library
   INCLUDE "assets/music/nutcracker_intybasic.bas"

   main:
       CLS
       MODE 0, 0, 0, 0, 0
       PRINT AT 92, "HELLO WORLD"

       PLAY SIMPLE
       PLAY NUTMARCH

   loop:
       WAIT
       GOTO loop
   ```

4. **Build and run:**
   ```bash
   ./games/my-game/build.sh run
   ```

## Project Structure

```
intv-game-builder/
├── README.md              # This file
├── CLAUDE.md              # Technical reference & IntyBASIC docs
├── lib/                   # Shared libraries
│   └── zmus_engine.bas    # Assembly music engine
├── assets/
│   └── music/             # Shared music files
│       ├── greensleeves_music.bas
│       ├── canon_music.bas
│       └── nutcracker_intybasic.bas
├── docs/                  # Documentation
├── games/                 # Game projects
│   └── orchestra-demo/    # Example project
│       ├── src/main.bas
│       ├── build.sh
│       └── build/         # Compiled output
└── inty-midi-0.1.0.0-bin/ # MIDI converter (see README.txt)
```

## Shared Libraries

### Music Files (assets/music/)

| File | Format | Description |
|------|--------|-------------|
| `nutcracker_intybasic.bas` | Native MUSIC | Nutcracker March (3-channel) |
| `greensleeves_music.bas` | Native MUSIC | Greensleeves melody |
| `canon_music.bas` | Native MUSIC | Pachelbel's Canon |

**Usage:**
```basic
INCLUDE "assets/music/nutcracker_intybasic.bas"

PLAY SIMPLE    ' or PLAY FULL for 3 channels
PLAY NUTMARCH
```

### ZMUS Engine (lib/zmus_engine.bas)

Assembly-based music player with direct PSG control.

```basic
INCLUDE "lib/zmus_engine.bas"

USR ZMUS_INIT              ' Initialize once
USR ZMUS_PLAY(song_label)  ' Start song
USR ZMUS_UPDATE            ' Call every frame
USR ZMUS_STOP              ' Stop playback
```

## Documentation

- **CLAUDE.md** - Complete IntyBASIC language reference, assembly patterns, and best practices
- **docs/** - Additional documentation including community tips
- **IntyBASIC Manual** - https://github.com/nanochess/IntyBASIC/blob/master/manual.txt

## Emulator Controls (jzIntv)

| Key | Function |
|-----|----------|
| Arrow keys | D-pad directions |
| Left Shift | Left action button |
| Left Alt | Right action button |
| 0-9 | Keypad digits |
| - | Clear |
| = | Enter |
| F1 | Reset |
| Escape | Quit |

## License

This project template is provided as-is for Intellivision homebrew development.

IntyBASIC is (c) Oscar Toledo G. - https://nanochess.org/
jzIntv is by Joe Zbiciak - http://spatula-city.org/~im14u2c/intv/
