' ============================================
' SPACE INTRUDERS - Flight Engine Module
' ============================================
' Waypoint-based movement for flying objects
' Segment: 2

    SEGMENT 2

' === Flight Engine ===

' ============================================
' Flight Patterns — DATA tables
' ============================================

' Rogue alien circular flight offsets (32 steps, radius 12, bias 12)
' Step 0 = rightmost (3 o'clock), step 8 = bottom, step 16 = left, step 24 = top
RogueCircleDX:
    DATA 24, 24, 23, 22, 20, 19, 17, 14
    DATA 12, 10, 7, 5, 4, 2, 1, 0
    DATA 0, 0, 1, 2, 4, 5, 7, 10
    DATA 12, 14, 17, 19, 20, 22, 23, 24

RogueCircleDY:
    DATA 12, 14, 17, 19, 20, 22, 23, 24
    DATA 24, 24, 23, 22, 20, 19, 17, 14
    DATA 12, 10, 7, 5, 4, 2, 1, 0
    DATA 0, 0, 1, 2, 4, 5, 7, 10

' Capture wingman orbit offsets (16 steps, radius 6, bias 6)
' Step 0 = rightmost, step 4 = bottom, step 8 = left, step 12 = top
CaptureOrbitDX:
    DATA 12, 11, 10, 8, 6, 4, 2, 1
    DATA 0, 1, 2, 4, 6, 8, 10, 11

CaptureOrbitDY:
    DATA 6, 8, 10, 11, 12, 11, 10, 8
    DATA 6, 4, 2, 1, 0, 1, 2, 4

' Wave color palettes (6 palettes, cycling via (Level-1) MOD 6)
' Independent of the 32-wave cycle — provides 6-color variety
' Each palette: one per alien row (5 rows, 5 palettes)
WavePalette0:
    DATA 6, 7, 5, 1, 2, 3
WavePalette1:
    DATA 5, 6, 1, 2, 1, 7
WavePalette2:
    DATA 7, 5, 2, 3, 6, 7
WavePalette3:
    DATA 2, 3, 7, 5, 6, 1
WavePalette4:
    DATA 3, 2, 6, 7, 5, 5

' Wave entrance patterns (32 entries, indexed by (Level-1) AND 31)
' 0 = left sweep (columns appear left-to-right)
' 1 = top-down (rows appear top-to-bottom)
' Pattern B always uses pincer (both sides meet in middle)
WaveEntranceData:
    ' 0=Left sweep, 1=Top-down reveal (rows in place), 2=Fly-down from above
    DATA 1, 0, 2, 0, 2, 2, 1, 2  ' Waves  1- 8
    DATA 2, 2, 1, 2, 2, 1, 2, 2  ' Waves  9-16
    DATA 2, 2, 1, 2, 2, 1, 2, 2  ' Waves 17-24
    DATA 1, 2, 2, 2, 1, 2, 2, 1  ' Waves 25-32

' ╚══════════════════ END LEVEL DESIGN DATA ══════════════════╝

' Pattern 0: Figure-8 Lissajous (title screen, 316 waypoints)
' x = 84 + 50*sin(t), y = 56 + 18*sin(2t)
' High density: every segment = 1px, path IS the curve
FlightFigure8X:
    DATA 84, 85, 85, 86, 86, 87, 88, 89
    DATA 89, 90, 91, 92, 92, 93, 93, 94
    DATA 95, 95, 96, 96, 97, 98, 98, 99
    DATA 99, 100, 101, 101, 102, 103, 103, 104
    DATA 105, 106, 107, 108, 109, 109, 110, 111
    DATA 112, 113, 114, 115, 115, 116, 117, 118
    DATA 119, 120, 121, 122, 123, 123, 124, 125
    DATA 126, 126, 127, 128, 129, 129, 130, 130
    DATA 130, 131, 131, 132, 132, 132, 133, 133
    DATA 133, 133, 134, 134, 134, 134, 134, 134
    DATA 134, 134, 134, 134, 134, 133, 133, 133
    DATA 133, 132, 132, 132, 131, 131, 130, 130
    DATA 130, 129, 129, 128, 127, 126, 126, 125
    DATA 124, 123, 123, 122, 121, 120, 119, 118
    DATA 117, 116, 115, 115, 114, 113, 112, 111
    DATA 110, 109, 109, 108, 107, 106, 105, 104
    DATA 103, 103, 102, 101, 101, 100, 99, 99
    DATA 98, 98, 97, 96, 96, 95, 95, 94
    DATA 93, 93, 92, 92, 91, 90, 89, 89
    DATA 88, 87, 86, 86, 85, 85, 84, 83
    DATA 83, 82, 82, 81, 80, 79, 79, 78
    DATA 77, 76, 76, 75, 75, 74, 73, 73
    DATA 72, 72, 71, 70, 70, 69, 69, 68
    DATA 67, 67, 66, 65, 65, 64, 63, 62
    DATA 61, 60, 59, 59, 58, 57, 56, 55
    DATA 54, 53, 53, 52, 51, 50, 49, 48
    DATA 47, 46, 45, 45, 44, 43, 42, 42
    DATA 41, 40, 39, 39, 38, 38, 38, 37
    DATA 37, 36, 36, 36, 35, 35, 35, 35
    DATA 34, 34, 34, 34, 34, 34, 34, 34
    DATA 34, 34, 34, 35, 35, 35, 35, 36
    DATA 36, 36, 37, 37, 38, 38, 38, 39
    DATA 39, 40, 41, 42, 42, 43, 44, 45
    DATA 45, 46, 47, 48, 49, 50, 51, 52
    DATA 53, 53, 54, 55, 56, 57, 58, 59
    DATA 59, 60, 61, 62, 63, 64, 65, 65
    DATA 66, 67, 67, 68, 69, 69, 70, 70
    DATA 71, 72, 72, 73, 73, 74, 75, 75
    DATA 76, 76, 77, 78, 79, 79, 80, 81
    DATA 82, 82, 83, 83
FlightFigure8Y:
    DATA 56, 56, 57, 57, 58, 58, 59, 59
    DATA 60, 60, 61, 61, 62, 62, 63, 63
    DATA 63, 64, 64, 65, 65, 65, 66, 66
    DATA 67, 67, 67, 68, 68, 68, 69, 69
    DATA 70, 70, 71, 71, 71, 72, 72, 72
    DATA 73, 73, 73, 73, 74, 74, 74, 74
    DATA 74, 74, 74, 74, 74, 73, 73, 73
    DATA 73, 72, 72, 71, 71, 70, 70, 69
    DATA 68, 68, 67, 67, 66, 65, 64, 63
    DATA 62, 61, 61, 60, 59, 58, 57, 56
    DATA 55, 54, 53, 52, 51, 51, 50, 49
    DATA 48, 47, 46, 45, 45, 44, 44, 43
    DATA 42, 42, 41, 41, 40, 40, 39, 39
    DATA 39, 39, 38, 38, 38, 38, 38, 38
    DATA 38, 38, 38, 39, 39, 39, 39, 40
    DATA 40, 40, 41, 41, 41, 42, 42, 43
    DATA 43, 44, 44, 44, 45, 45, 45, 46
    DATA 46, 47, 47, 47, 48, 48, 49, 49
    DATA 49, 50, 50, 51, 51, 52, 52, 53
    DATA 53, 54, 54, 55, 55, 56, 56, 56
    DATA 57, 57, 58, 58, 59, 59, 60, 60
    DATA 61, 61, 62, 62, 63, 63, 63, 64
    DATA 64, 65, 65, 65, 66, 66, 67, 67
    DATA 67, 68, 68, 68, 69, 69, 70, 70
    DATA 71, 71, 71, 72, 72, 72, 73, 73
    DATA 73, 73, 74, 74, 74, 74, 74, 74
    DATA 74, 74, 74, 73, 73, 73, 73, 72
    DATA 72, 71, 71, 70, 70, 69, 68, 68
    DATA 67, 67, 66, 65, 64, 63, 62, 61
    DATA 61, 60, 59, 58, 57, 56, 55, 54
    DATA 53, 52, 51, 51, 50, 49, 48, 47
    DATA 46, 45, 45, 44, 44, 43, 42, 42
    DATA 41, 41, 40, 40, 39, 39, 39, 39
    DATA 38, 38, 38, 38, 38, 38, 38, 38
    DATA 38, 39, 39, 39, 39, 40, 40, 40
    DATA 41, 41, 41, 42, 42, 43, 43, 44
    DATA 44, 44, 45, 45, 45, 46, 46, 47
    DATA 47, 47, 48, 48, 49, 49, 49, 50
    DATA 50, 51, 51, 52, 52, 53, 53, 54
    DATA 54, 55, 55, 56

' Pattern 1: Organic Orbit (game over, 356 waypoints)
' x = 78 + 70*cos(t) + 6*cos(3t), y = 19 + 17*sin(t) + 3*sin(2t)
' High density: every segment = 1px, path IS the curve
FlightOrbitX:
    DATA 154, 154, 154, 153, 153, 152, 152, 151
    DATA 150, 149, 149, 148, 147, 147, 146, 145
    DATA 145, 144, 143, 143, 142, 141, 140, 140
    DATA 139, 138, 137, 136, 135, 134, 134, 133
    DATA 132, 131, 130, 129, 128, 127, 126, 126
    DATA 125, 124, 123, 122, 121, 121, 120, 119
    DATA 118, 117, 116, 115, 114, 113, 112, 111
    DATA 110, 109, 108, 107, 106, 105, 105, 104
    DATA 103, 102, 101, 100, 99, 98, 97, 96
    DATA 95, 94, 93, 92, 91, 90, 89, 88
    DATA 87, 86, 85, 84, 83, 83, 82, 81
    DATA 80, 79, 78, 77, 76, 75, 74, 74
    DATA 73, 72, 71, 70, 69, 68, 67, 66
    DATA 65, 64, 63, 62, 62, 61, 60, 59
    DATA 58, 57, 56, 55, 54, 53, 52, 51
    DATA 51, 50, 49, 48, 47, 46, 46, 45
    DATA 44, 43, 42, 41, 40, 39, 38, 37
    DATA 36, 35, 35, 34, 33, 32, 31, 30
    DATA 30, 29, 28, 27, 26, 25, 25, 24
    DATA 23, 22, 21, 20, 20, 19, 18, 17
    DATA 16, 15, 14, 13, 12, 11, 10, 9
    DATA 8, 8, 7, 6, 5, 5, 4, 3
    DATA 3, 2, 2, 2, 3, 3, 4, 5
    DATA 5, 6, 7, 8, 8, 9, 10, 11
    DATA 12, 13, 14, 15, 16, 17, 18, 19
    DATA 20, 20, 21, 22, 23, 24, 25, 25
    DATA 26, 27, 28, 29, 30, 30, 31, 32
    DATA 33, 34, 35, 35, 36, 37, 38, 39
    DATA 40, 41, 42, 43, 44, 45, 46, 46
    DATA 47, 48, 49, 50, 51, 51, 52, 53
    DATA 54, 55, 56, 57, 58, 59, 60, 61
    DATA 62, 62, 63, 64, 65, 66, 67, 68
    DATA 69, 70, 71, 72, 73, 74, 74, 75
    DATA 76, 77, 78, 79, 80, 81, 82, 83
    DATA 83, 84, 85, 86, 87, 88, 89, 90
    DATA 91, 92, 93, 94, 95, 96, 97, 98
    DATA 99, 100, 101, 102, 103, 104, 105, 105
    DATA 106, 107, 108, 109, 110, 111, 112, 113
    DATA 114, 115, 116, 117, 118, 119, 120, 121
    DATA 121, 122, 123, 124, 125, 126, 126, 127
    DATA 128, 129, 130, 131, 132, 133, 134, 134
    DATA 135, 136, 137, 138, 139, 140, 140, 141
    DATA 142, 143, 143, 144, 145, 145, 146, 147
    DATA 147, 148, 149, 149, 150, 151, 152, 152
    DATA 153, 153, 154, 154
FlightOrbitY:
    DATA 19, 20, 21, 21, 22, 23, 24, 24
    DATA 25, 25, 26, 26, 26, 27, 27, 27
    DATA 28, 28, 28, 29, 29, 29, 29, 30
    DATA 30, 30, 31, 31, 31, 31, 32, 32
    DATA 32, 32, 33, 33, 33, 33, 33, 34
    DATA 34, 34, 34, 34, 34, 35, 35, 35
    DATA 35, 35, 35, 35, 36, 36, 36, 36
    DATA 36, 36, 36, 36, 36, 36, 37, 37
    DATA 37, 37, 37, 37, 37, 37, 37, 37
    DATA 37, 37, 37, 37, 37, 37, 37, 37
    DATA 37, 37, 37, 37, 37, 36, 36, 36
    DATA 36, 36, 36, 36, 36, 36, 36, 35
    DATA 35, 35, 35, 35, 35, 35, 34, 34
    DATA 34, 34, 34, 34, 33, 33, 33, 33
    DATA 33, 33, 32, 32, 32, 32, 32, 32
    DATA 31, 31, 31, 31, 31, 31, 30, 30
    DATA 30, 30, 30, 30, 29, 29, 29, 29
    DATA 29, 29, 28, 28, 28, 28, 28, 28
    DATA 27, 27, 27, 27, 27, 27, 26, 26
    DATA 26, 26, 26, 26, 25, 25, 25, 25
    DATA 25, 24, 24, 24, 24, 23, 23, 23
    DATA 23, 22, 22, 22, 22, 21, 21, 21
    DATA 20, 20, 19, 18, 18, 17, 17, 17
    DATA 16, 16, 16, 16, 15, 15, 15, 15
    DATA 14, 14, 14, 14, 13, 13, 13, 13
    DATA 13, 12, 12, 12, 12, 12, 12, 11
    DATA 11, 11, 11, 11, 11, 10, 10, 10
    DATA 10, 10, 10, 9, 9, 9, 9, 9
    DATA 9, 8, 8, 8, 8, 8, 8, 7
    DATA 7, 7, 7, 7, 7, 6, 6, 6
    DATA 6, 6, 6, 5, 5, 5, 5, 5
    DATA 5, 4, 4, 4, 4, 4, 4, 3
    DATA 3, 3, 3, 3, 3, 3, 2, 2
    DATA 2, 2, 2, 2, 2, 2, 2, 2
    DATA 1, 1, 1, 1, 1, 1, 1, 1
    DATA 1, 1, 1, 1, 1, 1, 1, 1
    DATA 1, 1, 1, 1, 1, 1, 1, 2
    DATA 2, 2, 2, 2, 2, 2, 2, 2
    DATA 2, 3, 3, 3, 3, 3, 3, 3
    DATA 4, 4, 4, 4, 4, 4, 5, 5
    DATA 5, 5, 5, 6, 6, 6, 6, 7
    DATA 7, 7, 7, 8, 8, 8, 9, 9
    DATA 9, 9, 10, 10, 10, 11, 11, 11
    DATA 12, 12, 12, 13, 13, 14, 14, 15
    DATA 16, 17, 17, 18

' ============================================
' Flight Engine Procedures
' ============================================

' --------------------------------------------
' FlightStart - Load a pattern and begin transition
' Input: LoopVar = pattern ID (PAT_FIGURE8, PAT_DIAMOND, etc.)
' Preserves current FlyX/FlyY as starting position
' --------------------------------------------
FlightStart: PROCEDURE
    IF LoopVar = PAT_FIGURE8 THEN
        #PathXAddr = VARPTR FlightFigure8X(0)
        #PathYAddr = VARPTR FlightFigure8Y(0)
        #FlyPathLen = 316
        FlyTransSpd = 1  ' Figure-8: 1px transition, max 2 loops
    ELSEIF LoopVar = PAT_DIAMOND THEN
        #PathXAddr = VARPTR FlightOrbitX(0)
        #PathYAddr = VARPTR FlightOrbitY(0)
        #FlyPathLen = 356
        FlyTransSpd = 2  ' Diamond orbit: 2px transition, infinite loops
    END IF
    FlyState = FLT_TRANSITION
    #FlyPhase = 0
    FlySpeed = 0
    #FlyLoopCount = 0
    RETURN
    END

' --------------------------------------------
' FlightTick - Per-frame flight engine update
' Updates FlyX, FlyY. Sets FlyState to FLT_DONE when loops complete.
' --------------------------------------------
FlightTick: PROCEDURE
    IF FlyState = FLT_IDLE THEN RETURN
    IF FlyState >= FLT_DONE THEN RETURN

    IF FlyState = FLT_TRANSITION THEN
        ' Move toward first waypoint each frame
        Col = PEEK(#PathXAddr)    ' Target X
        Row = PEEK(#PathYAddr)    ' Target Y
        ' Step X toward target
        IF FlyX < Col THEN
            FlyX = FlyX + FlyTransSpd
            IF FlyX > Col THEN FlyX = Col
        ELSEIF FlyX > Col THEN
            IF FlyX >= FlyTransSpd THEN
                FlyX = FlyX - FlyTransSpd
            ELSE
                FlyX = 0
            END IF
            IF FlyX < Col THEN FlyX = Col
        END IF
        ' Step Y toward target
        IF FlyY < Row THEN
            FlyY = FlyY + FlyTransSpd
            IF FlyY > Row THEN FlyY = Row
        ELSEIF FlyY > Row THEN
            IF FlyY >= FlyTransSpd THEN
                FlyY = FlyY - FlyTransSpd
            ELSE
                FlyY = 0
            END IF
            IF FlyY < Row THEN FlyY = Row
        END IF
        ' Check if arrived at target
        IF FlyX = Col THEN
            IF FlyY = Row THEN
                FlyState = FLT_FOLLOWING
                #FlyPhase = 0
                FlySpeed = 0
            END IF
        END IF
        RETURN
    END IF

    ' FLT_FOLLOWING: traverse high-density curve
    ' FLY_STEP_RATE = waypoints to advance per frame (speed control)
    #FlyPhase = #FlyPhase + FLY_STEP_RATE
    IF #FlyPhase >= #FlyPathLen THEN
        #FlyPhase = 0
        #FlyLoopCount = #FlyLoopCount + 1
        IF FlyTransSpd = 1 THEN  ' Figure-8 pattern: max 2 loops
            IF #FlyLoopCount >= 2 THEN
                FlyState = FLT_DONE
                RETURN
            END IF
        END IF
    END IF
    FlyX = PEEK(#PathXAddr + #FlyPhase)
    FlyY = PEEK(#PathYAddr + #FlyPhase)
    RETURN
    END

' --------------------------------------------
' ZodRender - Draw Zod with wing flap + color cycle
' Called each frame during game over screen
' --------------------------------------------
