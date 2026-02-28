#!/bin/bash
# ============================================
# Space Intruders SFX Lab - Build Script
# 27-sound creative SFX test ROM (no music)
# ============================================
#
# Usage: ./build_sfxlab.sh [run]
#   - No args: compile only
#   - run: compile and launch in jzIntv emulator
# ============================================

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GAME_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$GAME_DIR/build"

INTYBASIC=~/intybasic/intybasic
AS1600=~/jzintv/bin/as1600
JZINTV=~/jzintv/bin/jzintv
EXEC_ROM=~/jzintv/bin/exec.bin
GROM_ROM=~/jzintv/bin/grom.bin

SRC="$GAME_DIR/src/sfxlab.bas"
ASM="$BUILD_DIR/sfxlab.asm"
ROM="$BUILD_DIR/sfxlab.rom"
LST="$BUILD_DIR/sfxlab.lst"

echo "=== Space Intruders SFX Lab Build ==="
echo "Project root: $PROJECT_ROOT"
echo ""

mkdir -p "$BUILD_DIR"
cd "$PROJECT_ROOT"

echo "[1/2] Compiling IntyBASIC..."
arch -x86_64 $INTYBASIC "$SRC" "$ASM" "$(dirname "$INTYBASIC")"
echo "      Generated: $ASM"

echo "[2/2] Assembling ROM..."
arch -x86_64 $AS1600 -o "$ROM" -l "$LST" "$ASM"
echo "      Generated: $ROM"

echo ""
echo "=== Build Complete ==="
echo "ROM: $ROM"
echo "LST: $LST"

if [ "$1" = "run" ]; then
    echo ""
    echo "=== Launching jzIntv ==="
    arch -x86_64 $JZINTV \
        --execimg="$EXEC_ROM" \
        --gromimg="$GROM_ROM" \
        "$ROM"
fi
