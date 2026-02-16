#!/bin/bash
# Generate TinyFont splash date using BITMAP format (clearer than DATA hex)
# Usage: ./scripts/generate_splash_date_bitmap.sh > src/splash_date_generated.bas

set -e

# Get current date in MM/DD/YYYY format
DATE_STR=$(date +"%m/%d/%Y")

# Build the full date line: "BETA - MM/DD/YYYY" (17 chars)
FULL_LINE="BETA - $DATE_STR"

# TinyFont 6-pixel-tall patterns (6 rows, X=pixel on, .=pixel off)
# Each character is 4 pixels wide × 6 pixels tall for better readability
get_bitmap_pattern() {
    local char="$1"
    case "$char" in
        "B") echo "XXX.|X..X|XXX.|X..X|X..X|XXX." ;;  # Block B
        "E") echo "XXXX|X...|XXX.|X...|X...|XXXX" ;;  # Block E
        "T") echo "XXXX|.XX.|.XX.|.XX.|.XX.|.XX." ;;  # Block T
        "A") echo ".XX.|X..X|X..X|XXXX|X..X|X..X" ;;  # Block A
        "0") echo ".XX.|X..X|X..X|X..X|X..X|.XX." ;;  # Digit 0
        "1") echo ".XX.|XXX.|.XX.|.XX.|.XX.|XXXX" ;;  # Digit 1
        "2") echo "XXX.|X..X|...X|.XX.|XX..|XXXX" ;;  # Digit 2
        "3") echo "XXX.|X..X|..XX|...X|X..X|XXX." ;;  # Digit 3
        "4") echo "X..X|X..X|X..X|XXXX|...X|...X" ;;  # Digit 4
        "5") echo "XXXX|X...|XXX.|...X|X..X|XXX." ;;  # Digit 5
        "6") echo ".XX.|X...|XXX.|X..X|X..X|.XX." ;;  # Digit 6
        "7") echo "XXXX|...X|..X.|.XX.|.XX.|.XX." ;;  # Digit 7
        "8") echo ".XX.|X..X|.XX.|X..X|X..X|.XX." ;;  # Digit 8
        "9") echo ".XX.|X..X|X..X|.XXX|...X|.XX." ;;  # Digit 9
        "/") echo "...X|...X|..X.|.X..|X...|X..." ;;  # Slash
        "-") echo "....|....|XXXX|....|....|...." ;;  # Dash
        " ") echo "....|....|....|....|....|...." ;;  # Space
        *) echo "....|....|....|....|....|...." ;;  # Unknown = space
    esac
}

# Generate output
cat << 'EOF'
' ============================================
' AUTO-GENERATED: Splash Date Line (BITMAP format)
' Generated at build time by scripts/generate_splash_date_bitmap.sh
' DO NOT EDIT - This file is regenerated every build
' ============================================

SplashDate_Generated:
EOF

# Process characters in pairs (2 chars per GRAM card)
for i in $(seq 0 2 $((${#FULL_LINE} - 1))); do
    left_char="${FULL_LINE:$i:1}"

    # Get right character (or space if at end)
    if [ $((i + 1)) -lt ${#FULL_LINE} ]; then
        right_char="${FULL_LINE:$((i+1)):1}"
    else
        right_char=" "
    fi

    # Get bitmap patterns (6 rows each, pipe-separated)
    left_pattern=$(get_bitmap_pattern "$left_char")
    right_pattern=$(get_bitmap_pattern "$right_char")

    # Split into rows
    IFS='|' read -r l0 l1 l2 l3 l4 l5 <<< "$left_pattern"
    IFS='|' read -r r0 r1 r2 r3 r4 r5 <<< "$right_pattern"

    # Combine left and right patterns into 8-pixel-wide BITMAP statements
    # All BITMAPs must be contiguous (no comments between them)
    # TinyFont is now 6 pixels tall, so rows 0-5 are the character, rows 6-7 are blank
    echo "    BITMAP \"$l0$r0\""
    echo "    BITMAP \"$l1$r1\""
    echo "    BITMAP \"$l2$r2\""
    echo "    BITMAP \"$l3$r3\""
    echo "    BITMAP \"$l4$r4\""
    echo "    BITMAP \"$l5$r5\""
    echo "    BITMAP \"........\""
    echo "    BITMAP \"........\""
done

echo "' Build date: $DATE_STR"
echo "' Generated: $(date)"
