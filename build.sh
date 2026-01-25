#!/bin/bash
# IntyBASIC Build Script
# Usage: ./build.sh [run]

set -e

PROJECT_NAME="game"
SRC_DIR="src"
BUILD_DIR="build"

# Tool paths (adjust if needed)
INTYBASIC="${INTYBASIC:-$HOME/intybasic/intybasic}"
AS1600="${AS1600:-$HOME/jzintv/bin/as1600}"
JZINTV="${JZINTV:-$HOME/jzintv/bin/jzintv}"
EXEC_BIN="${EXEC_BIN:-$HOME/jzintv/bin/exec.bin}"
GROM_BIN="${GROM_BIN:-$HOME/jzintv/bin/grom.bin}"
IVOICE_BIN="${IVOICE_BIN:-$HOME/jzintv/bin/ivoice.bin}"

# Create build directory
mkdir -p "$BUILD_DIR"

echo "=== Compiling IntyBASIC ==="
# IntyBASIC is also x86_64, needs Rosetta on Apple Silicon
if [[ $(uname -m) == "arm64" ]]; then
    arch -x86_64 "$INTYBASIC" "$SRC_DIR/main.bas" "$BUILD_DIR/$PROJECT_NAME.asm" "$(dirname "$INTYBASIC")"
else
    "$INTYBASIC" "$SRC_DIR/main.bas" "$BUILD_DIR/$PROJECT_NAME.asm" "$(dirname "$INTYBASIC")"
fi

echo "=== Assembling ==="
# Use arch -x86_64 for Apple Silicon Macs
if [[ $(uname -m) == "arm64" ]]; then
    arch -x86_64 "$AS1600" -o "$BUILD_DIR/$PROJECT_NAME.rom" -l "$BUILD_DIR/$PROJECT_NAME.lst" "$BUILD_DIR/$PROJECT_NAME.asm"
else
    "$AS1600" -o "$BUILD_DIR/$PROJECT_NAME.rom" -l "$BUILD_DIR/$PROJECT_NAME.lst" "$BUILD_DIR/$PROJECT_NAME.asm"
fi

echo "=== Build complete: $BUILD_DIR/$PROJECT_NAME.rom ==="

# Run if requested
if [[ "$1" == "run" || "$1" == "voice" ]]; then
    echo "=== Launching emulator ==="
    VOICE_FLAG=""
    if [[ "$1" == "voice" ]]; then
        VOICE_FLAG="--voice=1"
        echo "(Intellivoice enabled)"
    fi
    if [[ $(uname -m) == "arm64" ]]; then
        arch -x86_64 "$JZINTV" --execimg="$EXEC_BIN" --gromimg="$GROM_BIN" $VOICE_FLAG "$BUILD_DIR/$PROJECT_NAME.rom"
    else
        "$JZINTV" --execimg="$EXEC_BIN" --gromimg="$GROM_BIN" $VOICE_FLAG "$BUILD_DIR/$PROJECT_NAME.rom"
    fi
fi
