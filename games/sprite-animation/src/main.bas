' ============================================
' Rotating Letter Animation Demo
' ============================================
' Y-Axis rotation (horizontal spin)
' 4 frames: 0° -> 30° -> 60° -> 90°
' ============================================

' Animation timing (frames per step)
CONST ANIM_SLOW   = 8    ' Slow spin
CONST ANIM_MEDIUM = 5    ' Medium spin
CONST ANIM_FAST   = 3    ' Fast spin

' Colors
CONST COL_WHITE  = 7
CONST COL_YELLOW = 6
CONST COL_GREEN  = 5

' GRAM card assignments
' Each letter gets 4 consecutive cards (Frame1-4)
' "SPACE INTRUDERS" unique letters: S, P, A, C, E, I, N, T, R, U, D
' 11 letters x 4 frames = 44 GRAM cards (0-43)

CONST GRAM_S = 0     ' Cards 0, 1, 2, 3
CONST GRAM_P = 4     ' Cards 4, 5, 6, 7
CONST GRAM_A = 8     ' Cards 8, 9, 10, 11
CONST GRAM_C = 12    ' Cards 12, 13, 14, 15
CONST GRAM_E = 16    ' Cards 16, 17, 18, 19
CONST GRAM_I = 20    ' Cards 20, 21, 22, 23
CONST GRAM_N = 24    ' Cards 24, 25, 26, 27
CONST GRAM_T = 28    ' Cards 28, 29, 30, 31
CONST GRAM_R = 32    ' Cards 32, 33, 34, 35
CONST GRAM_U = 36    ' Cards 36, 37, 38, 39
CONST GRAM_D = 40    ' Cards 40, 41, 42, 43

' Variables
ac = 0       ' AnimCounter
as = 0       ' AnimStep (0-7 for wobble)
dm = 0       ' DemoMode: 0=single, 1=full
sp = ANIM_MEDIUM  ' Speed
fo = 0       ' Frame offset (0-3)

' ============================================
' MAIN PROGRAM
' ============================================

    MODE 0, 0, 0, 0, 0
    PLAY SIMPLE       ' Initialize ISR for controller reading (DO NOT use PLAY OFF!)
    WAIT

    ' Load all letter GRAM frames
    GOSUB LoadAllGRAM

    ' Start with single letter test
    CLS
    PRINT AT 20 COLOR COL_WHITE, "Y-AXIS ROTATION TEST"
    PRINT AT 60 COLOR COL_WHITE, "PRESS FIRE FOR DEMO"
    PRINT AT 180 COLOR COL_WHITE, "KEYPAD 1/2/3 = SPEED"

    ' Display test letter "S" at center
    PRINT AT 129, (GRAM_S * 8) + COL_YELLOW + $0800

    dm = 0

MainLoop:
    WAIT

    ' Check for fire button to switch modes
    IF CONT.BUTTON THEN
        IF dm = 0 THEN
            dm = 1
            CLS
            PRINT AT 20 COLOR COL_WHITE, "SPACE INTRUDERS"
            PRINT AT 60 COLOR COL_WHITE, "PRESS FIRE TO GO BACK"
            GOSUB DrawFullTitle
        ELSE
            dm = 0
            CLS
            PRINT AT 20 COLOR COL_WHITE, "Y-AXIS ROTATION TEST"
            PRINT AT 60 COLOR COL_WHITE, "PRESS FIRE FOR DEMO"
            PRINT AT 180 COLOR COL_WHITE, "KEYPAD 1/2/3 = SPEED"
            PRINT AT 129, (GRAM_S * 8) + COL_YELLOW + $0800
        END IF
        ' Debounce
        FOR d = 0 TO 15 : WAIT : NEXT d
    END IF

    ' Update animation counter
    ac = ac + 1
    IF ac >= sp THEN
        ac = 0

        ' Advance animation step (0-7 for wobble: 0,1,2,3,2,1,0,...)
        ' Wobble: F1->F2->F3->F4->F3->F2->F1...
        as = as + 1
        IF as > 5 THEN as = 0

        ' Map step to frame offset (wobble pattern)
        ' Steps 0,1,2,3 = frames 0,1,2,3
        ' Steps 4,5 = frames 2,1 (return)
        IF as = 0 THEN fo = 0
        IF as = 1 THEN fo = 1
        IF as = 2 THEN fo = 2
        IF as = 3 THEN fo = 3
        IF as = 4 THEN fo = 2
        IF as = 5 THEN fo = 1

        ' Update display based on mode
        IF dm = 0 THEN
            GOSUB UpdateSingle
        ELSE
            GOSUB UpdateFull
        END IF
    END IF

    ' Check keypad for speed adjustment (direct like Space Intruders)
    IF CONT.KEY = 1 THEN sp = ANIM_SLOW   : PRINT AT 200 COLOR COL_WHITE, "SLOW  "
    IF CONT.KEY = 2 THEN sp = ANIM_MEDIUM : PRINT AT 200 COLOR COL_WHITE, "MEDIUM"
    IF CONT.KEY = 3 THEN sp = ANIM_FAST   : PRINT AT 200 COLOR COL_WHITE, "FAST  "

    ' Debug: show raw key value
    ky = CONT.KEY
    PRINT AT 220 COLOR COL_WHITE, "KEY="
    PRINT AT 224, <> ky

    GOTO MainLoop

' ============================================
' UPDATE SINGLE LETTER
' ============================================
UpdateSingle: PROCEDURE
    PRINT AT 129, ((GRAM_S + fo) * 8) + COL_YELLOW + $0800
    RETURN
END

' ============================================
' DRAW FULL TITLE (initial)
' ============================================
DrawFullTitle: PROCEDURE
    ' "SPACE INTRUDERS" at row 5, starting col 3 (position 103)
    PRINT AT 103, (GRAM_S * 8) + COL_GREEN + $0800
    PRINT AT 104, (GRAM_P * 8) + COL_GREEN + $0800
    PRINT AT 105, (GRAM_A * 8) + COL_GREEN + $0800
    PRINT AT 106, (GRAM_C * 8) + COL_GREEN + $0800
    PRINT AT 107, (GRAM_E * 8) + COL_GREEN + $0800
    ' 108 = space
    PRINT AT 109, (GRAM_I * 8) + COL_GREEN + $0800
    PRINT AT 110, (GRAM_N * 8) + COL_GREEN + $0800
    PRINT AT 111, (GRAM_T * 8) + COL_GREEN + $0800
    PRINT AT 112, (GRAM_R * 8) + COL_GREEN + $0800
    PRINT AT 113, (GRAM_U * 8) + COL_GREEN + $0800
    PRINT AT 114, (GRAM_D * 8) + COL_GREEN + $0800
    PRINT AT 115, (GRAM_E * 8) + COL_GREEN + $0800
    PRINT AT 116, (GRAM_R * 8) + COL_GREEN + $0800
    PRINT AT 117, (GRAM_S * 8) + COL_GREEN + $0800
    RETURN
END

' ============================================
' UPDATE FULL TITLE (animation)
' ============================================
UpdateFull: PROCEDURE
    PRINT AT 103, ((GRAM_S + fo) * 8) + COL_GREEN + $0800
    PRINT AT 104, ((GRAM_P + fo) * 8) + COL_GREEN + $0800
    PRINT AT 105, ((GRAM_A + fo) * 8) + COL_GREEN + $0800
    PRINT AT 106, ((GRAM_C + fo) * 8) + COL_GREEN + $0800
    PRINT AT 107, ((GRAM_E + fo) * 8) + COL_GREEN + $0800
    PRINT AT 109, ((GRAM_I + fo) * 8) + COL_GREEN + $0800
    PRINT AT 110, ((GRAM_N + fo) * 8) + COL_GREEN + $0800
    PRINT AT 111, ((GRAM_T + fo) * 8) + COL_GREEN + $0800
    PRINT AT 112, ((GRAM_R + fo) * 8) + COL_GREEN + $0800
    PRINT AT 113, ((GRAM_U + fo) * 8) + COL_GREEN + $0800
    PRINT AT 114, ((GRAM_D + fo) * 8) + COL_GREEN + $0800
    PRINT AT 115, ((GRAM_E + fo) * 8) + COL_GREEN + $0800
    PRINT AT 116, ((GRAM_R + fo) * 8) + COL_GREEN + $0800
    PRINT AT 117, ((GRAM_S + fo) * 8) + COL_GREEN + $0800
    RETURN
END

' ============================================
' LOAD ALL GRAM FRAMES (Y-axis, 4 per letter)
' ============================================
LoadAllGRAM: PROCEDURE
    ' S (cards 0-3)
    DEFINE GRAM_S, 1, FontSY1Gfx
    WAIT
    DEFINE GRAM_S + 1, 1, FontSY2Gfx
    WAIT
    DEFINE GRAM_S + 2, 1, FontSY3Gfx
    WAIT
    DEFINE GRAM_S + 3, 1, FontSY4Gfx
    WAIT

    ' P (cards 4-7)
    DEFINE GRAM_P, 1, FontPY1Gfx
    WAIT
    DEFINE GRAM_P + 1, 1, FontPY2Gfx
    WAIT
    DEFINE GRAM_P + 2, 1, FontPY3Gfx
    WAIT
    DEFINE GRAM_P + 3, 1, FontPY4Gfx
    WAIT

    ' A (cards 8-11)
    DEFINE GRAM_A, 1, FontAY1Gfx
    WAIT
    DEFINE GRAM_A + 1, 1, FontAY2Gfx
    WAIT
    DEFINE GRAM_A + 2, 1, FontAY3Gfx
    WAIT
    DEFINE GRAM_A + 3, 1, FontAY4Gfx
    WAIT

    ' C (cards 12-15)
    DEFINE GRAM_C, 1, FontCY1Gfx
    WAIT
    DEFINE GRAM_C + 1, 1, FontCY2Gfx
    WAIT
    DEFINE GRAM_C + 2, 1, FontCY3Gfx
    WAIT
    DEFINE GRAM_C + 3, 1, FontCY4Gfx
    WAIT

    ' E (cards 16-19)
    DEFINE GRAM_E, 1, FontEY1Gfx
    WAIT
    DEFINE GRAM_E + 1, 1, FontEY2Gfx
    WAIT
    DEFINE GRAM_E + 2, 1, FontEY3Gfx
    WAIT
    DEFINE GRAM_E + 3, 1, FontEY4Gfx
    WAIT

    ' I (cards 20-23)
    DEFINE GRAM_I, 1, FontIY1Gfx
    WAIT
    DEFINE GRAM_I + 1, 1, FontIY2Gfx
    WAIT
    DEFINE GRAM_I + 2, 1, FontIY3Gfx
    WAIT
    DEFINE GRAM_I + 3, 1, FontIY4Gfx
    WAIT

    ' N (cards 24-27)
    DEFINE GRAM_N, 1, FontNY1Gfx
    WAIT
    DEFINE GRAM_N + 1, 1, FontNY2Gfx
    WAIT
    DEFINE GRAM_N + 2, 1, FontNY3Gfx
    WAIT
    DEFINE GRAM_N + 3, 1, FontNY4Gfx
    WAIT

    ' T (cards 28-31)
    DEFINE GRAM_T, 1, FontTY1Gfx
    WAIT
    DEFINE GRAM_T + 1, 1, FontTY2Gfx
    WAIT
    DEFINE GRAM_T + 2, 1, FontTY3Gfx
    WAIT
    DEFINE GRAM_T + 3, 1, FontTY4Gfx
    WAIT

    ' R (cards 32-35)
    DEFINE GRAM_R, 1, FontRY1Gfx
    WAIT
    DEFINE GRAM_R + 1, 1, FontRY2Gfx
    WAIT
    DEFINE GRAM_R + 2, 1, FontRY3Gfx
    WAIT
    DEFINE GRAM_R + 3, 1, FontRY4Gfx
    WAIT

    ' U (cards 36-39)
    DEFINE GRAM_U, 1, FontUY1Gfx
    WAIT
    DEFINE GRAM_U + 1, 1, FontUY2Gfx
    WAIT
    DEFINE GRAM_U + 2, 1, FontUY3Gfx
    WAIT
    DEFINE GRAM_U + 3, 1, FontUY4Gfx
    WAIT

    ' D (cards 40-43)
    DEFINE GRAM_D, 1, FontDY1Gfx
    WAIT
    DEFINE GRAM_D + 1, 1, FontDY2Gfx
    WAIT
    DEFINE GRAM_D + 2, 1, FontDY3Gfx
    WAIT
    DEFINE GRAM_D + 3, 1, FontDY4Gfx
    WAIT

    RETURN
END

' ============================================
' Y-AXIS BITMAP DATA (4 frames per letter)
' ============================================

' Letter S - Frame 1 (0°)
FontSY1Gfx:
    BITMAP ".XXXXX.."
    BITMAP "XX...XX."
    BITMAP "XX......"
    BITMAP ".XXXXX.."
    BITMAP ".....XX."
    BITMAP ".....XX."
    BITMAP "XX...XX."
    BITMAP ".XXXXX.."

' Letter S - Frame 2 (30°)
FontSY2Gfx:
    BITMAP ".XXXXX.."
    BITMAP "XX...XX."
    BITMAP "XX......"
    BITMAP ".XXXXX.."
    BITMAP ".....XX."
    BITMAP ".....XX."
    BITMAP "XX...XX."
    BITMAP ".XXXXX.."

' Letter S - Frame 3 (60°)
FontSY3Gfx:
    BITMAP ".XXXXX.."
    BITMAP "XX...X.."
    BITMAP "XX......"
    BITMAP ".XXXXX.."
    BITMAP ".....X.."
    BITMAP ".....X.."
    BITMAP "XX...X.."
    BITMAP ".XXXXX.."

' Letter S - Frame 4 (90°)
FontSY4Gfx:
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XXX..."

' Letter P - Frame 1 (0°)
FontPY1Gfx:
    BITMAP "XXXXXX.."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XXXXXX.."
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX......"

' Letter P - Frame 2 (30°)
FontPY2Gfx:
    BITMAP "XXXXXX.."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XXXXXX.."
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX......"

' Letter P - Frame 3 (60°)
FontPY3Gfx:
    BITMAP "XXXXXX.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XXXXXX.."
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX......"

' Letter P - Frame 4 (90°)
FontPY4Gfx:
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."

' Letter A - Frame 1 (0°)
FontAY1Gfx:
    BITMAP ".XXXXX.."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX..XXX."
    BITMAP "XXXXXXX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."

' Letter A - Frame 2 (30°)
FontAY2Gfx:
    BITMAP ".XXXXX.."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX..XXX."
    BITMAP "XXXXXXX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."

' Letter A - Frame 3 (60°)
FontAY3Gfx:
    BITMAP ".XXXXX.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX..XX.."
    BITMAP "XXXXXX.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."

' Letter A - Frame 4 (90°)
FontAY4Gfx:
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XXX..."
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."

' Letter C - Frame 1 (0°)
FontCY1Gfx:
    BITMAP ".XXXXX.."
    BITMAP "XX...XX."
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX...XX."
    BITMAP ".XXXXX.."

' Letter C - Frame 2 (30°)
FontCY2Gfx:
    BITMAP ".XXXXX.."
    BITMAP "XX...XX."
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX...XX."
    BITMAP ".XXXXX.."

' Letter C - Frame 3 (60°)
FontCY3Gfx:
    BITMAP ".XXXXX.."
    BITMAP "XX...X.."
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX...X.."
    BITMAP ".XXXXX.."

' Letter C - Frame 4 (90°)
FontCY4Gfx:
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XXX..."

' Letter E - Frame 1 (0°)
FontEY1Gfx:
    BITMAP "XXXXXXX."
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XXXXXXX."
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XXXXXXX."

' Letter E - Frame 2 (30°)
FontEY2Gfx:
    BITMAP "XXXXXXX."
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XXXXXXX."
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XXXXXXX."

' Letter E - Frame 3 (60°)
FontEY3Gfx:
    BITMAP "XXXXXX.."
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XXXXXX.."
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XXXXXX.."

' Letter E - Frame 4 (90°)
FontEY4Gfx:
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XXX..."

' Letter I - Frame 1 (0°)
FontIY1Gfx:
    BITMAP "XXXXXXX."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "XXXXXXX."

' Letter I - Frame 2 (30°)
FontIY2Gfx:
    BITMAP "XXXXXXX."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "XXXXXXX."

' Letter I - Frame 3 (60°)
FontIY3Gfx:
    BITMAP "XXXXXX.."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "XXXXXX.."

' Letter I - Frame 4 (90°)
FontIY4Gfx:
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XXX..."

' Letter N - Frame 1 (0°)
FontNY1Gfx:
    BITMAP "XX...XX."
    BITMAP "XXX..XX."
    BITMAP "XXXX.XX."
    BITMAP "XX.XXXX."
    BITMAP "XX..XXX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."

' Letter N - Frame 2 (30°)
FontNY2Gfx:
    BITMAP "XX...XX."
    BITMAP "XXX..XX."
    BITMAP "XXXX.XX."
    BITMAP "XX.XXXX."
    BITMAP "XX..XXX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."

' Letter N - Frame 3 (60°)
FontNY3Gfx:
    BITMAP "XX...X.."
    BITMAP "XXX..X.."
    BITMAP "XXXX.X.."
    BITMAP "XX.XXX.."
    BITMAP "XX..XX.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."

' Letter N - Frame 4 (90°)
FontNY4Gfx:
    BITMAP "..XX...."
    BITMAP "..XXX..."
    BITMAP "..XXX..."
    BITMAP "..XXX..."
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."

' Letter T - Frame 1 (0°)
FontTY1Gfx:
    BITMAP "XXXXXXX."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."

' Letter T - Frame 2 (30°)
FontTY2Gfx:
    BITMAP "XXXXXXX."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."

' Letter T - Frame 3 (60°)
FontTY3Gfx:
    BITMAP "XXXXXX.."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."

' Letter T - Frame 4 (90°)
FontTY4Gfx:
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."

' Letter R - Frame 1 (0°)
FontRY1Gfx:
    BITMAP "XXXXXX.."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XXXXXX.."
    BITMAP "XX..XX.."
    BITMAP "XX...XX."
    BITMAP "XX...XX."

' Letter R - Frame 2 (30°)
FontRY2Gfx:
    BITMAP "XXXXXX.."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XXXXXX.."
    BITMAP "XX..XX.."
    BITMAP "XX...XX."
    BITMAP "XX...XX."

' Letter R - Frame 3 (60°)
FontRY3Gfx:
    BITMAP "XXXXXX.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XXXXXX.."
    BITMAP "XX..XX.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."

' Letter R - Frame 4 (90°)
FontRY4Gfx:
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."

' Letter U - Frame 1 (0°)
FontUY1Gfx:
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP ".XXXXX.."

' Letter U - Frame 2 (30°)
FontUY2Gfx:
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP ".XXXXX.."

' Letter U - Frame 3 (60°)
FontUY3Gfx:
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP ".XXXXX.."

' Letter U - Frame 4 (90°)
FontUY4Gfx:
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XXX..."

' Letter D - Frame 1 (0°)
FontDY1Gfx:
    BITMAP "XXXXXX.."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XXXXXX.."

' Letter D - Frame 2 (30°)
FontDY2Gfx:
    BITMAP "XXXXXX.."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XXXXXX.."

' Letter D - Frame 3 (60°)
FontDY3Gfx:
    BITMAP "XXXXXX.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XXXXXX.."

' Letter D - Frame 4 (90°)
FontDY4Gfx:
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XXX..."
