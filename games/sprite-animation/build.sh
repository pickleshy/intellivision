#!/bin/bash
# ============================================
# Sprite Animation - Build Script
# ============================================
# Letter animation experiments for Intellivision
#
# Usage: ./build.sh [run|voice]
#   - No args: compile only
#   - run: compile and launch in jzIntv emulator
#   - voice: compile and launch with Intellivoice support
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
ECS_ROM=~/jzintv/bin/ecs.bin

# File names
SRC="$GAME_DIR/src/main.bas"
ASM="$BUILD_DIR/sprite-anim.asm"
ROM="$BUILD_DIR/sprite-anim.rom"
LST="$BUILD_DIR/sprite-anim.lst"

echo "=== Sprite Animation Build ==="
echo "Project root: $PROJECT_ROOT"
echo ""

# Create build directory if needed
mkdir -p "$BUILD_DIR"

# Change to project root for correct INCLUDE paths
cd "$PROJECT_ROOT"

# Step 1: Compile BASIC to assembly
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
if [ "$1" = "run" ]; then
    echo ""
    echo "=== Launching jzIntv (with ECS) ==="
    arch -x86_64 $JZINTV \
        --execimg="$EXEC_ROM" \
        --gromimg="$GROM_ROM" \
        --ecsimg="$ECS_ROM" \
        -z3 \
        "$ROM"
elif [ "$1" = "voice" ]; then
    echo ""
    echo "=== Launching jzIntv (with Intellivoice + ECS) ==="
    arch -x86_64 $JZINTV \
        --execimg="$EXEC_ROM" \
        --gromimg="$GROM_ROM" \
        --ecsimg="$ECS_ROM" \
        --voice=1 \
        -z3 \
        "$ROM"
fi
