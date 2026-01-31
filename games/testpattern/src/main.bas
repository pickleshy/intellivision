' ============================================
' Test Pattern - Intellivision Color Reference
' ============================================
' Shows all 16 colors with labels
' Color Stack mode for full 16-color access
' Screen: 20 columns x 12 rows
' ============================================

    MODE 0, 0, 0, 0, 0   ' Color Stack mode, black BG
    CLS
    WAIT

    ' Define solid block in GRAM 0, outline block in GRAM 1
    DEFINE 0, 2, SolidBlock
    WAIT

    ' --- Title (row 0) ---
    PRINT AT 2 COLOR 7, "COLOR REFERENCE"

    ' --- Layout: two columns of 8 colors ---
    ' Left:  col 0=swatch, col 2-8=label     (colors 0-7)
    ' Right: col 10=swatch, col 12-19=label   (colors 8-15)
    '
    ' GRAM solid block in Color Stack:
    '   Colors 0-7:  0*8 + color + $0800
    '   Colors 8-15: 0*8 + (color AND 7) + $1800  (bit 12 set)

    ' === LEFT COLUMN: Colors 0-7 ===

    ' Row 2 (pos 40): Color 0 - Black (outline block so it's visible)
    PRINT AT 40, $080F       ' GRAM 1, color 7 (white outline, black interior)
    PRINT AT 42 COLOR 7, "0 BLACK"

    ' Row 3 (pos 60): Color 1 - Blue
    PRINT AT 60, $0801       ' GRAM 0, color 1
    PRINT AT 62 COLOR 7, "1 BLUE"

    ' Row 4 (pos 80): Color 2 - Red
    PRINT AT 80, $0802       ' GRAM 0, color 2
    PRINT AT 82 COLOR 7, "2 RED"

    ' Row 5 (pos 100): Color 3 - Tan
    PRINT AT 100, $0803      ' GRAM 0, color 3
    PRINT AT 102 COLOR 7, "3 TAN"

    ' Row 6 (pos 120): Color 4 - Dark Green
    PRINT AT 120, $0804      ' GRAM 0, color 4
    PRINT AT 122 COLOR 7, "4 DK GRN"

    ' Row 7 (pos 140): Color 5 - Green
    PRINT AT 140, $0805      ' GRAM 0, color 5
    PRINT AT 142 COLOR 7, "5 GREEN"

    ' Row 8 (pos 160): Color 6 - Yellow
    PRINT AT 160, $0806      ' GRAM 0, color 6
    PRINT AT 162 COLOR 7, "6 YELLOW"

    ' Row 9 (pos 180): Color 7 - White
    PRINT AT 180, $0807      ' GRAM 0, color 7
    PRINT AT 182 COLOR 7, "7 WHITE"

    ' === RIGHT COLUMN: Colors 8-15 (pastel) ===
    ' Bit 12 set + low 3 bits of color

    ' Row 2 (pos 50): Color 8 - Grey
    PRINT AT 50, $1800       ' GRAM 0, color 8
    PRINT AT 52 COLOR 7, "8 GREY"

    ' Row 3 (pos 70): Color 9 - Cyan
    PRINT AT 70, $1801       ' GRAM 0, color 9
    PRINT AT 72 COLOR 7, "9 CYAN"

    ' Row 4 (pos 90): Color 10 - Orange
    PRINT AT 90, $1802       ' GRAM 0, color 10
    PRINT AT 92 COLOR 7, "A ORANGE"

    ' Row 5 (pos 110): Color 11 - Brown
    PRINT AT 110, $1803      ' GRAM 0, color 11
    PRINT AT 112 COLOR 7, "B BROWN"

    ' Row 6 (pos 130): Color 12 - Pink
    PRINT AT 130, $1804      ' GRAM 0, color 12
    PRINT AT 132 COLOR 7, "C PINK"

    ' Row 7 (pos 150): Color 13 - Light Blue
    PRINT AT 150, $1805      ' GRAM 0, color 13
    PRINT AT 152 COLOR 7, "D LT BLU"

    ' Row 8 (pos 170): Color 14 - Yellow-Green
    PRINT AT 170, $1806      ' GRAM 0, color 14
    PRINT AT 172 COLOR 7, "E YL-GRN"

    ' Row 9 (pos 190): Color 15 - Purple
    PRINT AT 190, $1807      ' GRAM 0, color 15
    PRINT AT 192 COLOR 7, "F PURPLE"

    ' --- Row 11: footer ---
    PRINT AT 223 COLOR 6, "INTV PALETTE"

    ' Main loop
MainLoop:
    WAIT
    GOTO MainLoop

' ============================================
' Graphics Data
' ============================================
SolidBlock:
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"

OutlineBlock:
    BITMAP "XXXXXXXX"
    BITMAP "X......X"
    BITMAP "X......X"
    BITMAP "X......X"
    BITMAP "X......X"
    BITMAP "X......X"
    BITMAP "X......X"
    BITMAP "XXXXXXXX"
