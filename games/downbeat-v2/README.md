# DOWNBEAT! v2

A rhythm runner game for the Mattel Intellivision, built with IntyBASIC.

## What Is It?

DOWNBEAT! is a Moon Patrol-style side-scrolling runner where you jump over musical note obstacles in time with Scott Joplin's *Maple Leaf Rag*. The melody plays continuously on PSG Channel A while diamond-shaped note obstacles scroll toward the player. Jump to clear them — miss 3 and it's game over.

The game plays the complete A strain (16 bars) of the Maple Leaf Rag at 100 BPM, with 16 obstacles syncopated to melodic accents. On completion, a jump map shows your timing across all 128 beat positions.

## Building and Running

Requires IntyBASIC compiler, jzIntv assembler/emulator (see parent project CLAUDE.md for tool paths).

```bash
cd games/downbeat-v2
./build.sh          # Compile only
./build.sh run      # Compile and run in jzIntv emulator
./build.sh voice    # Compile and run with Intellivoice
```

## Controls

- **Side buttons (any)**: Jump
- Button must be released between jumps (debounced)
- Press button on end screens to replay

## Game Mechanics

### Scoring
- Notes scroll right-to-left toward the player
- Jump over notes to clear them (crossing-point detection at player X)
- Hit a note (still on ground when note passes) = 1 hit + dissonant "dud" sound
- 3 hits = Game Over
- Clear all 128 beats = Song Complete + jump map display

### Two-Layer Audio System
- **Layer A (Channel 0)**: Background melody plays the Maple Leaf Rag continuously, regardless of player actions. Uses PSG periods extracted from MIDI.
- **Layer B (Channel 1)**: Hit sound effects — a detuned version of the current melody note (~1 semitone flat) plays briefly when the player fails to jump over an obstacle.

### Obstacle Spawning
Notes spawn SPAWN_OFFSET (9) beats ahead of the melody, so they arrive at the player position exactly when that beat plays. This creates the illusion that obstacles and music are synchronized.

### Note Articulation
- Rests (PSG period = 0) silence the channel explicitly
- Consecutive identical notes use a 1-frame mute/restore cycle to retrigger the AY-3-8914 waveform, creating distinct note attacks

## Current Features

- Full Maple Leaf Rag A strain (128 16th-note positions, 16 bars in 2/4 time)
- MIDI-extracted melody (highest note per tick from Joplin arrangement)
- Sub-pixel fixed-point scrolling (171/256 fractional accumulator)
- 7-slot sprite pool for note obstacles (MOBs 1-7, recycled)
- Crossing-point collision with 4px vertical grace zone
- Jump arc lookup table (36 frames, parabolic)
- HUD with hit counter
- Song complete screen with 8x16 jump map grid
- Game over screen
- Play again on both end screens
- Detuned "dud" SFX on missed notes

## Project Structure

```
games/downbeat-v2/
├── README.md           # This file
├── CLAUDE.md           # Development reference for Claude Code
├── build.sh            # Build and run script
├── src/
│   └── main.bas        # Game source (~420 lines)
├── build/              # Compiled output (generated)
│   ├── downbeat2.asm
│   ├── downbeat2.rom
│   └── downbeat2.lst
├── assets/
│   └── maple_leaf_rag_a_strain.mid  # Reference MIDI
└── tools/
    └── parse_midi.py   # MIDI to IntyBASIC DATA converter
```

## Resource Usage

- 175 of 228 8-bit variables
- 9 of 55 16-bit variables
- 3 GRAM cards (player, ground, note)
- 8 MOBs (1 player + 7 note slots)
- Fits in default 8K ROM (no OPTION MAP needed)
