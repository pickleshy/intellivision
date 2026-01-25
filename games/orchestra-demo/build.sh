#!/bin/bash
# ============================================
# Orchestra Demo - Build Script
# ============================================
# Builds the Orchestra/Intellivoice demo ROM
#
# Usage: ./build.sh [run]
#   - No args: compile only
#   - run: compile and launch in jzIntv emulator
# ============================================

set -e

# Navigate to project root (IDE directory)
PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GAME_DIR="$(dirname "$0")"
BUILD_DIR="$GAME_DIR/build"

# Tool paths
INTYBASIC=~/intybasic/intybasic
AS1600=~/jzintv/bin/as1600
JZINTV=~/jzintv/bin/jzintv
EXEC_ROM=~/jzintv/bin/exec.bin
GROM_ROM=~/jzintv/bin/grom.bin
IVOICE_ROM=~/jzintv/bin/ivoice.bin

# File names
SRC="$GAME_DIR/src/main.bas"
ASM="$BUILD_DIR/orchestra.asm"
ROM="$BUILD_DIR/orchestra.rom"
LST="$BUILD_DIR/orchestra.lst"

echo "=== Orchestra Demo Build ==="
echo "Project root: $PROJECT_ROOT"
echo ""

# Create build directory if needed
mkdir -p "$BUILD_DIR"

# Change to project root for correct INCLUDE paths
cd "$PROJECT_ROOT"

# Step 1: Compile BASIC to assembly
# Third arg tells IntyBASIC where to find prologue/epilogue
echo "[1/2] Compiling IntyBASIC..."
arch -x86_64 $INTYBASIC "$SRC" "$ASM" "$(dirname "$INTYBASIC")"
echo "      Generated: $ASM"

# Step 2: Assemble to ROM
echo "[2/2] Assembling ROM..."
arch -x86_64 $AS1600 -o "$ROM" -l "$LST" "$ASM"
echo "      Generated: $ROM"

echo ""
echo "=== Build Complete ==="
echo "ROM: $ROM"
echo "LST: $LST"

# Run in emulator if requested
if [ "$1" = "run" ] || [ "$1" = "voice" ]; then
    echo ""
    echo "=== Launching jzIntv ==="
    VOICE_FLAG=""
    if [ "$1" = "voice" ]; then
        VOICE_FLAG="--voice=1"
        echo "(Intellivoice enabled)"
    fi
    arch -x86_64 $JZINTV \
        --execimg="$EXEC_ROM" \
        --gromimg="$GROM_ROM" \
        $VOICE_FLAG \
        "$ROM"
fi
