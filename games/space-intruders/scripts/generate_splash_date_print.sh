#!/bin/bash
# Generate splash date using standard PRINT statements (GROM font)
# Usage: ./scripts/generate_splash_date_print.sh > src/splash_date_generated.bas

set -e

# Get current date in MM/DD/YYYY format
DATE_STR=$(date +"%m/%d/%Y")

# Build the full date line: "BETA - MM/DD/YYYY"
FULL_LINE="BETA - $DATE_STR"

# Generate output
cat << 'EOF'
' ============================================
' AUTO-GENERATED: Splash Date Line (PRINT format)
' Generated at build time by scripts/generate_splash_date_print.sh
' DO NOT EDIT - This file is regenerated every build
' ============================================

SplashDate_Print: PROCEDURE
    ' Line 2: BETA - MM/DD/YYYY (row 10, one line up from bottom, centered)
EOF

# Calculate starting position for centering
# Screen is 20 columns wide, text length determines offset
TEXT_LEN=${#FULL_LINE}
START_COL=$(( (20 - TEXT_LEN) / 2 ))
START_POS=$(( 200 + START_COL ))  # Row 10 = 200 (one line up from bottom)

# Output PRINT statement
echo "    PRINT AT $START_POS COLOR COL_WHITE, \"$FULL_LINE\""

# Close procedure
cat << 'EOF'
    RETURN
END

' Build date:
EOF

echo "' Generated: $(date)"
echo "' Text: \"$FULL_LINE\" ($TEXT_LEN chars, centered at column $START_COL)"
