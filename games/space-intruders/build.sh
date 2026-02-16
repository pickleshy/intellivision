#!/bin/bash
# ============================================
# Space Intruders - Build Script
# ============================================
# A Space Invaders clone for Intellivision
#
# Usage: ./build.sh [run|voice]
#   - No args: compile only
#   - run: compile and launch in jzIntv emulator
#   - voice: compile and launch with Intellivoice support
# ============================================

set -e

# Navigate to project root (IDE directory)
PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GAME_DIR="$(cd "$(dirname "$0")" && pwd)"
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
ASM="$BUILD_DIR/intruders.asm"
ROM="$BUILD_DIR/intruders.rom"
LST="$BUILD_DIR/intruders.lst"

echo "=== Space Intruders Build ==="
echo "Project root: $PROJECT_ROOT"
echo ""

# Create build directory if needed
mkdir -p "$BUILD_DIR"

# Change to project root for correct INCLUDE paths
cd "$PROJECT_ROOT"

# Pre-build: Generate splash date (auto-updates build date in boot screen)
echo "[0/2] Generating splash date..."
"$GAME_DIR/scripts/generate_splash_date_print.sh" > "$GAME_DIR/src/splash_date_generated.bas"
echo "      Generated: splash_date_generated.bas ($(date +"%m/%d/%Y"))"

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
    echo "=== Launching jzIntv ==="
    arch -x86_64 $JZINTV \
        --execimg="$EXEC_ROM" \
        --gromimg="$GROM_ROM" \
        --voice=1 \
        -z3 \
        "$ROM"
elif [ "$1" = "voice" ]; then
    echo ""
    echo "=== Launching jzIntv (with Intellivoice) ==="
    arch -x86_64 $JZINTV \
        --execimg="$EXEC_ROM" \
        --gromimg="$GROM_ROM" \
        --voice=1 \
        -z3 \
        "$ROM"
fi
