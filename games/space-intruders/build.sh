#!/bin/bash
# ============================================
# Space Intruders - Build Script
# ============================================
# A Space Invaders clone for Intellivision
#
# Usage: ./build.sh [run|voice|intv|publish]
#   - No args: compile only
#   - run: compile and launch in jzIntv emulator
#   - voice: compile and launch with Intellivoice support
#   - intv: compile and convert to INTV2 format for Nt Mini Noir FPGA
#   - publish: compile, package assets, push to itch.io
# ============================================

set -e

# Navigate to project root (IDE directory)
PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GAME_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$GAME_DIR/build"
ASSETS_DIR="$GAME_DIR/assets"

# Tool paths
INTYBASIC=~/intybasic/intybasic
AS1600=~/jzintv/bin/as1600
JZINTV=~/jzintv/bin/jzintv
EXEC_ROM=~/jzintv/bin/exec.bin
GROM_ROM=~/jzintv/bin/grom.bin
ECS_ROM=~/jzintv/bin/ecs.bin
BUTLER=~/bin/butler
INTV2CONVERT=~/bin/intv2convert

# itch.io publishing config
ITCH_TARGET="paisleyboxers/space-intruders:rom"
ITCH_GAME_ID="4283442"

# Version: date-based
VERSION=$(date +"%Y.%m.%d")

# Asset naming convention
GAME_TITLE="Space Intruders (2026)"
ZIP_NAME="${GAME_TITLE}.zip"

# File names
SRC="$GAME_DIR/src/main.bas"
ASM="$BUILD_DIR/intruders.asm"
ROM="$BUILD_DIR/intruders.rom"
LST="$BUILD_DIR/intruders.lst"
INTV_NOIR="$BUILD_DIR/intruders-nt-noir.intv"
INTV_POCKET="$BUILD_DIR/intruders-pocket.intv"

echo "=== Space Intruders Build ==="
echo "Project root: $PROJECT_ROOT"
echo "Version: $VERSION"
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

# Convert to INTV2 format for both FPGA targets if requested
if [ "$1" = "intv" ]; then
    echo ""
    echo "=== Converting to INTV2 ==="

    echo ""
    echo "[intv 1/2] Nt Mini Noir (true word count, Intellivoice compatible)..."
    $INTV2CONVERT lst "$LST" "$INTV_NOIR"

    echo ""
    echo "[intv 2/2] Analogue Pocket (even-padded word count, Chip32 aligned)..."
    $INTV2CONVERT lst "$LST" "$INTV_POCKET" --pocket

    echo ""
    echo "=== INTV2 Output ==="
    echo "Nt Mini Noir:     $INTV_NOIR"
    echo "Analogue Pocket:  $INTV_POCKET"
    echo ""
    echo "Nt Mini Noir — copy intruders.intv to SD card."
    echo "Analogue Pocket — copy intruders-pocket.intv to SD card."
    echo ""
    echo "Required BIOS files in /BIOS/ (both consoles):"
    echo "  intvexec1.bin  — Executive ROM (CRC32: EEB54C63)"
    echo "  grom.bin       — GROM (CRC32: 683A4158)"
    echo "  012.bin        — Intellivoice 2K ROM (for speech)"
    exit 0
fi

# Publish to itch.io if requested
if [ "$1" = "publish" ]; then
    echo ""
    echo "=== Publishing to itch.io ==="

    # Step 3: Generate INTV files for both FPGA targets
    echo "[pub 1/4] Converting to INTV2..."
    $INTV2CONVERT lst "$LST" "$INTV_NOIR"
    $INTV2CONVERT lst "$LST" "$INTV_POCKET" --pocket

    # Step 4: Copy ROM + INTV files into assets
    echo "[pub 2/4] Copying ROM and INTV files to assets..."
    cp "$ROM"         "$ASSETS_DIR/${GAME_TITLE}.rom"
    echo "          $ROM -> assets/${GAME_TITLE}.rom"
    cp "$INTV_NOIR"   "$ASSETS_DIR/${GAME_TITLE}-nt-noir.intv"
    echo "          $INTV_NOIR -> assets/${GAME_TITLE}-nt-noir.intv"
    cp "$INTV_POCKET" "$ASSETS_DIR/${GAME_TITLE}-pocket.intv"
    echo "          $INTV_POCKET -> assets/${GAME_TITLE}-pocket.intv"

    # Step 5: Create zip from assets (remove first to guarantee a fresh archive)
    echo "[pub 3/4] Packaging ${ZIP_NAME}..."
    rm -f "$GAME_DIR/$ZIP_NAME"
    cd "$GAME_DIR/assets"
    zip -r "$GAME_DIR/$ZIP_NAME" . -x ".*" -x "__MACOSX/*" -x "art/*"
    cd "$GAME_DIR"
    echo "          Created: $ZIP_NAME ($(du -h "$ZIP_NAME" | cut -f1))"

    # Step 6: Push to itch.io
    echo "[pub 4/4] Pushing to itch.io..."
    echo "          Target:  $ITCH_TARGET"
    echo "          Version: $VERSION"
    $BUTLER push "$GAME_DIR/$ZIP_NAME" "$ITCH_TARGET" --userversion "$VERSION"

    echo ""
    echo "=== Published v${VERSION}! ==="
    echo "Verify: curl \"https://itch.io/api/1/x/wharf/latest?game_id=${ITCH_GAME_ID}&channel_name=rom\""
fi

# Run in emulator if requested
if [ "$1" = "run" ] || [ "$1" = "voice" ]; then
    echo ""
    echo "=== Launching jzIntv ==="
    arch -x86_64 $JZINTV \
        --execimg="$EXEC_ROM" \
        --gromimg="$GROM_ROM" \
        --voice=1 \
        --kbdhackfile="$GAME_DIR/intruders.kbd" \
        -z3 \
        "$ROM"
fi