#!/bin/bash
# Copy build outputs to all known destinations.
# Run from the repo root: ./games/space-intruders/copy-everywhere.sh

GAME_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$GAME_DIR/build"
ASSETS_DIR="$GAME_DIR/assets"

GAME_TITLE="Space Intruders (2026)"

ROM="$BUILD_DIR/intruders.rom"
INTV_NOIR="$BUILD_DIR/intruders-nt-noir.intv"
INTV_POCKET="$BUILD_DIR/intruders-pocket.intv"

# Special cases!
# NT Noir path
INTV_NOIR_SD=/Volumes/NTNOIRE/INTV
# Analogue Pocket
INTV_POCKET_SD=/Volumes/POCKET/Assets/intv/common

# --- ROM: copy to all known locations ---
for d in \
    "$ASSETS_DIR" \
    ~/Games/Roms/INTV-Sprint/output/_Demo \
    /Volumes/DSLITE/roms/intv \
    /Volumes/INTV_SPRINT/_Demo
do
    if [[ -d "$d" ]]; then
        cp "$ROM" "$d/$GAME_TITLE.rom"
        echo "ROM  → $d/$GAME_TITLE.rom"
    fi
done

# --- INTV: copy to assets always ---
cp "$INTV_NOIR"   "$ASSETS_DIR/$GAME_TITLE-nt-noir.intv"
echo "INTV → $ASSETS_DIR/$GAME_TITLE-nt-noir.intv"

cp "$INTV_POCKET" "$ASSETS_DIR/$GAME_TITLE-pocket.intv"
echo "INTV → $ASSETS_DIR/$GAME_TITLE-pocket.intv"

# --- SD cards: copy if mounted ---
if [[ -d "$INTV_NOIR_SD" ]]; then
    cp "$INTV_NOIR" "$INTV_NOIR_SD/$GAME_TITLE.intv"
    echo "NOIR → $INTV_NOIR_SD/$GAME_TITLE.intv"
fi

if [[ -d "$INTV_POCKET_SD" ]]; then
    cp "$INTV_POCKET" "$INTV_POCKET_SD/$GAME_TITLE.intv"
    echo "PCKT → $INTV_POCKET_SD/$GAME_TITLE.intv"
fi

git add -u -v
