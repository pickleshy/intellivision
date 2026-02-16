#!/bin/bash
# Generate TinyFont splash date for current build date
# Usage: ./scripts/generate_splash_date.sh > src/splash_date_generated.bas

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CHAR_LIB="$SCRIPT_DIR/tinyfont_chars.txt"

# Get current date in MM/DD/YYYY format
DATE_STR=$(date +"%m/%d/%Y")

# Build the full date line: "BETA - MM/DD/YYYY" (17 chars)
FULL_LINE="BETA - $DATE_STR"

# Function to look up character pattern from library
get_char_pattern() {
    local char="$1"
    case "$char" in
        " ") echo "0,0,0,0" ;;
        "-") echo "0,E,0,0" ;;
        "/") echo "2,4,8,4" ;;
        "0") echo "E,A,A,E" ;;
        "1") echo "4,C,4,E" ;;
        "2") echo "E,2,8,E" ;;
        "3") echo "E,2,2,E" ;;
        "4") echo "A,A,E,2" ;;
        "5") echo "E,8,2,E" ;;
        "6") echo "C,8,E,A" ;;
        "7") echo "E,2,4,4" ;;
        "8") echo "E,A,E,A" ;;
        "9") echo "E,A,E,2" ;;
        "B") echo "C,A,A,C" ;;
        "E") echo "E,C,C,E" ;;
        "T") echo "E,4,4,4" ;;
        "A") echo "4,A,E,A" ;;
        *) echo "0,0,0,0" ;;  # Unknown char = space
    esac
}

# Function to combine two 4-pixel characters into one GRAM card (4 hex words)
combine_chars() {
    local left_pattern="$1"
    local right_pattern="$2"

    IFS=',' read -r l0 l1 l2 l3 <<< "$left_pattern"
    IFS=',' read -r r0 r1 r2 r3 <<< "$right_pattern"

    # Combine: left nibble (row 0) + right nibble = one hex word
    # Each character is 4 pixels wide, so left char = high nibble, right char = low nibble
    printf "\$%s%s00, \$%s%s%s%s, \$%s%s%s%s, \$00%s%s" \
        "$l0" "$r0" "$l1" "$l2" "$r1" "$r2" "$l3" "$r3" "$l1" "$r2" "$l3" "$r3"
}

# Generate output
cat << 'EOF'
' ============================================
' AUTO-GENERATED: Splash Date Line
' Generated at build time by scripts/generate_splash_date.sh
' DO NOT EDIT - This file is regenerated every build
' ============================================

SplashDate_Generated:  ' Date line cards (9 cards for "BETA - MM/DD/YYYY")
EOF

# Process characters in pairs (2 chars per GRAM card)
# For odd-length strings, last character gets paired with space
card_count=0
for i in $(seq 0 2 $((${#FULL_LINE} - 1))); do
    left_char="${FULL_LINE:$i:1}"

    # Get right character (or space if we're at the end)
    if [ $((i + 1)) -lt ${#FULL_LINE} ]; then
        right_char="${FULL_LINE:$((i+1)):1}"
    else
        right_char=" "
    fi

    left_pattern=$(get_char_pattern "$left_char")
    right_pattern=$(get_char_pattern "$right_char")

    card_data=$(combine_chars "$left_pattern" "$right_pattern")

    # Add comment showing which characters
    echo "    DATA $card_data  ' \"$left_char$right_char\""

    card_count=$((card_count + 1))
done

echo ""
echo "' Build date: $DATE_STR"
echo "' Generated: $(date)"
