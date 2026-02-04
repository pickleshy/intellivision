#!/bin/bash
# GROM Explorer - Build Script

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GAME_DIR="$(dirname "$0")"
BUILD_DIR="$GAME_DIR/build"

INTYBASIC=~/intybasic/intybasic
AS1600=~/jzintv/bin/as1600
JZINTV=~/jzintv/bin/jzintv
EXEC_ROM=~/jzintv/bin/exec.bin
GROM_ROM=~/jzintv/bin/grom.bin

SRC="$GAME_DIR/src/main.bas"
ASM="$BUILD_DIR/grom_explorer.asm"
ROM="$BUILD_DIR/grom_explorer.rom"
LST="$BUILD_DIR/grom_explorer.lst"

echo "=== GROM Explorer Build ==="
mkdir -p "$BUILD_DIR"
cd "$PROJECT_ROOT"

echo "[1/2] Compiling IntyBASIC..."
arch -x86_64 $INTYBASIC "$SRC" "$ASM" "$(dirname "$INTYBASIC")"

echo "[2/2] Assembling ROM..."
arch -x86_64 $AS1600 -o "$ROM" -l "$LST" "$ASM"

echo ""
echo "=== Build Complete ==="
echo "ROM: $ROM"

if [ "$1" = "run" ]; then
    echo ""
    echo "=== Launching jzIntv ==="
    arch -x86_64 $JZINTV \
        --execimg="$EXEC_ROM" \
        --gromimg="$GROM_ROM" \
        "$ROM"
fi
