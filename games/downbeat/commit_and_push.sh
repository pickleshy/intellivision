#!/bin/bash
# Commit and push Downbeat changes
# Usage: ./commit_and_push.sh "Your commit message here"

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ROM_SRC="$SCRIPT_DIR/build/downbeat.rom"
ROM_DST="$SCRIPT_DIR/assets/Downbeat (2026).rom"

# Require a commit message
if [ -z "$1" ]; then
    echo "Usage: ./commit_and_push.sh \"Your commit message\""
    exit 1
fi

# Step 1: Build the ROM
echo "=== Step 1: Building ROM ==="
"$SCRIPT_DIR/build.sh"
echo ""

# Step 2: Copy compiled ROM to assets
echo "=== Step 2: Copying ROM to assets ==="
if [ -f "$ROM_SRC" ]; then
    cp "$ROM_SRC" "$ROM_DST"
    echo "Copied build/downbeat.rom -> assets/Downbeat (2026).rom"
else
    echo "ERROR: No compiled ROM found at $ROM_SRC"
    echo "Build failed — aborting."
    exit 1
fi
echo ""

# Step 3: Stage and commit
echo "=== Step 3: Committing ==="
cd "$REPO_ROOT"
git add games/downbeat/
echo "Staged games/downbeat/"
echo ""
echo "Changes to be committed:"
git diff --cached --stat -- games/downbeat/
echo ""
git commit -m "$1"
echo ""

# Step 4: Push to current branch
echo "=== Step 4: Pushing ==="
BRANCH=$(git branch --show-current)
git push origin "$BRANCH"
echo ""
echo "Done! Committed and pushed to $BRANCH"
