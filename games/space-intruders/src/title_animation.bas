' ============================================
' SPACE INTRUDERS - Title Animation Module
' ============================================
' Animated Y-axis rotating font for title/game-over screens
' Segment: 3

    SEGMENT 3

' === Animated Font System ===

    ' SEGMENT 3 — TITLE SCREEN ANIMATION
    ' ============================================================
    SEGMENT 3

' --- LoadAnimatedFont: Load 33 frames (3 per letter: full, 60°, edge) ---
' Loads frames 1, 3, 4 for each letter (skips frame 2 for smoother 3-step)
' Preserves: 9-12 (band), 19-38 (crab/sparks/font/stars)
LoadAnimatedFont: PROCEDURE
    ' S: cards 0-2 (full, 60°, edge)
    DEFINE 0, 1, FontSY1Gfx : WAIT
    DEFINE 1, 1, FontSY3Gfx : WAIT
    DEFINE 2, 1, FontSY4Gfx : WAIT
    ' P: cards 3-5
    DEFINE 3, 1, FontPY1Gfx : WAIT
    DEFINE 4, 1, FontPY3Gfx : WAIT
    DEFINE 5, 1, FontPY4Gfx : WAIT
    ' A: cards 6-8
    DEFINE 6, 1, FontAY1Gfx : WAIT
    DEFINE 7, 1, FontAY3Gfx : WAIT
    DEFINE 8, 1, FontAY4Gfx : WAIT
    ' C: cards 13-15 (skip 9-12 band)
    DEFINE 13, 1, FontCY1Gfx : WAIT
    DEFINE 14, 1, FontCY3Gfx : WAIT
    DEFINE 15, 1, FontCY4Gfx : WAIT
    ' E: cards 16-18
    DEFINE 16, 1, FontEY1Gfx : WAIT
    DEFINE 17, 1, FontEY3Gfx : WAIT
    DEFINE 18, 1, FontEY4Gfx : WAIT
    ' I: cards 39-41 (skip 19-38)
    DEFINE 39, 1, FontIY1Gfx : WAIT
    DEFINE 40, 1, FontIY3Gfx : WAIT
    DEFINE 41, 1, FontIY4Gfx : WAIT
    ' N: cards 42-44
    DEFINE 42, 1, FontNY1Gfx : WAIT
    DEFINE 43, 1, FontNY3Gfx : WAIT
    DEFINE 44, 1, FontNY4Gfx : WAIT
    ' T: cards 45-47
    DEFINE 45, 1, FontTY1Gfx : WAIT
    DEFINE 46, 1, FontTY3Gfx : WAIT
    DEFINE 47, 1, FontTY4Gfx : WAIT
    ' R: cards 48-50
    DEFINE 48, 1, FontRY1Gfx : WAIT
    DEFINE 49, 1, FontRY3Gfx : WAIT
    DEFINE 50, 1, FontRY4Gfx : WAIT
    ' U: cards 51-53
    DEFINE 51, 1, FontUY1Gfx : WAIT
    DEFINE 52, 1, FontUY3Gfx : WAIT
    DEFINE 53, 1, FontUY4Gfx : WAIT
    ' D: cards 54-56
    DEFINE 54, 1, FontDY1Gfx : WAIT
    DEFINE 55, 1, FontDY3Gfx : WAIT
    DEFINE 56, 1, FontDY4Gfx : WAIT
    RETURN
END

' --- DrawTitleAnimated: Draw title text using computed animation frames ---
' 3 frames: 0=full, 1=60°, 2=edge. Smoother reveal/vanish cascade.
' State 0 (reveal): Row < RevealCol=full, Row=RevealCol=60°, Row > RevealCol=edge
' State 1 (normal): all full
' State 2 (vanish): Row < VanishCol=edge, Row=VanishCol=60°, Row > VanishCol=full
' State 3 (done): all edge
DrawTitleAnimated: PROCEDURE
    FOR Row = 0 TO 14
        IF Row = 5 THEN GOTO DrawAnimSkip  ' Skip space position

        ' Compute frame: 0=full, 1=60°, 2=edge
        Col = 2  ' Default: edge
        IF TitleAnimState = 0 THEN
            ' Reveal: before RevealCol=full, at RevealCol=60°, after=edge
            IF Row < RevealCol THEN Col = 0
            IF Row = RevealCol THEN Col = 1
        END IF
        IF TitleAnimState = 1 THEN Col = 0  ' Normal: all full
        IF TitleAnimState = 2 THEN
            ' Vanish: before VanishCol=edge, at VanishCol=60°, after=full
            Col = 0  ' Default full
            IF Row < VanishCol THEN Col = 2
            IF Row = VanishCol THEN Col = 1
        END IF

        ' Lookup GRAM card from appropriate frame table
        IF Col = 0 THEN LoopVar = TitleGramF0(Row)
        IF Col = 1 THEN LoopVar = TitleGramF1(Row)
        IF Col = 2 THEN LoopVar = TitleGramF2(Row)
        #Card = LoopVar * 8 + COL_TAN + $0800
        PRINT AT 22 + Row, #Card

DrawAnimSkip:
    NEXT Row
    RETURN
END

' GRAM card lookup tables for 3 frames (full, 60°, edge)
' Index: 0=S, 1=P, 2=A, 3=C, 4=E, 5=skip, 6=I, 7=N, 8=T, 9=R, 10=U, 11=D, 12=E, 13=R, 14=S
TitleGramF0:
    DATA 0, 3, 6, 13, 16, 0, 39, 42, 45, 48, 51, 54, 16, 48, 0
TitleGramF1:
    DATA 1, 4, 7, 14, 17, 0, 40, 43, 46, 49, 52, 55, 17, 49, 1
TitleGramF2:
    DATA 2, 5, 8, 15, 18, 0, 41, 44, 47, 50, 53, 56, 18, 50, 2

' --- DrawGOLetter: Draw animating game over letter ---
' Uses GOAnimIdx (0-7) and GOAnimFrame (0-19)
' Animation: 0-4=full, 5-9=60°, 10-14=edge, 15-19=full (half rotation)
' Letters: 0=G, 1=A, 2=M, 3=E, 4=O, 5=V, 6=E, 7=R
DrawGOLetter: PROCEDURE
    ' Get BACKTAB position for this letter
    LoopVar = GOLetterPos(GOAnimIdx)

    ' Determine animation frame: 0-2=full(0), 3-5=60°(1), 6-8=edge(2), 9=full(0)
    Col = GOAnimFrame / 3
    IF Col > 2 THEN Col = 0  ' Wrap back to full at end

    ' Get base GRAM card for this letter's animation
    Row = GOLetterGram(GOAnimIdx) + Col

    ' Draw the letter
    #Card = Row * 8 + COL_TAN + $0800
    PRINT AT LoopVar, #Card
    RETURN
END

' Game Over letter BACKTAB positions
GOLetterPos:
    DATA 45, 46, 47, 48, 50, 51, 52, 53

' Game Over animated GRAM base cards (frame 0 = full)
' 0=G(0), 1=A(6), 2=M(3), 3=E(16), 4=O(51), 5=V(54), 6=E(16), 7=R(48)
GOLetterGram:
    DATA 0, 6, 3, 16, 51, 54, 16, 48

' Game Over STATIC GRAM cards (original fonts)
' G=37, A=27, M=38, E=29, O=40, V=41, E=29, R=33
GOLetterStaticGram:
    DATA 37, 27, 38, 29, 40, 41, 29, 33

    SEGMENT 2  ' Title drawing procs moved to Seg 2 (Seg 1 critically full)

' --- Draw 3x3 alien grid on BACKTAB ---
DrawAlienGrid: PROCEDURE
    ' Clear rows 5-7 first (cols 0-19)
    FOR LoopVar = 100 TO 159
        PRINT AT LoopVar, 0
    NEXT LoopVar
    ' Card values for left/right halves (GRAM + blue foreground)
    #Card = (GRAM_BAND1 * 8) + COL_BLUE + $0800
    #Mask = (GRAM_BAND2 * 8) + COL_BLUE + $0800
    ' Draw 3 rows of 3 aliens (each alien = 2 cards wide, 1 card gap between)
    FOR LoopVar = 0 TO 2
        #ScreenPos = (5 + LoopVar) * 20 + CapsuleColor2
        ' Alien 1
        PRINT AT #ScreenPos, #Card
        PRINT AT #ScreenPos + 1, #Mask
        ' Alien 2 (offset +3 cards)
        PRINT AT #ScreenPos + 3, #Card
        PRINT AT #ScreenPos + 4, #Mask
        ' Alien 3 (offset +6 cards)
        PRINT AT #ScreenPos + 6, #Card
        PRINT AT #ScreenPos + 7, #Mask
    NEXT LoopVar
    RETURN
END


' --- DrawStaticStars: 3-layer parallax starfield (avoids alien grid rows 5-7) ---
' Layer 1 (far): Rows 8-11, dense, dim (dark green)
' Layer 2 (mid): Rows 1-2, medium density, medium brightness
' Layer 3 (near): Row 0, sparse, bright
DrawStaticStars: PROCEDURE
    ' Layer 1: Far stars (rows 8-11, below aliens) - very dense, dim
    FOR LoopVar = 0 TO 39  ' 40 stars, ~10 per row
        Col = RANDOM(20)
        Row = RANDOM(4) + 8  ' Rows 8-11
        PRINT AT Row * 20 + Col, GRAM_STAR1 * 8 + 4 + $0800  ' Dark green
    NEXT LoopVar

    ' Layer 2: Mid stars (rows 2-4, between logo and aliens) - dense
    FOR LoopVar = 0 TO 29  ' 30 stars, ~10 per row
        Col = RANDOM(20)
        Row = RANDOM(3) + 2  ' Rows 2-4
        PRINT AT Row * 20 + Col, GRAM_STAR2 * 8 + 5 + $0800  ' Green
    NEXT LoopVar

    ' Layer 3: Bright accent stars (rows 2-4) - sparse, white
    FOR LoopVar = 0 TO 8  ' 9 stars, ~3 per row
        Col = RANDOM(20)
        Row = RANDOM(3) + 2  ' Rows 2-4
        PRINT AT Row * 20 + Col, GRAM_STAR1 * 8 + 7 + $0800  ' White (brightest)
    NEXT LoopVar
    RETURN
END

' --- AnimateStars: 2 animated stars for motion illusion ---
' Uses BulletX/ABulletX (unused on title screen) - saves 30+ variables!
AnimateStars: PROCEDURE
    ' Clear old positions
    PRINT AT 60 + BulletX, 0   ' Row 3 (near layer, fast scroll)
    PRINT AT 80 + ABulletX, 0  ' Row 4 (mid layer, slow scroll)

    ' Update positions (scroll left - different speeds for parallax)
    ' Fast star (row 3): moves every frame
    IF BulletX = 0 THEN
        BulletX = 19
    ELSE
        BulletX = BulletX - 1
    END IF

    ' Slow star (row 4): moves every other frame (StarTimer driven)
    IF StarTimer >= 5 THEN
        IF ABulletX = 0 THEN
            ABulletX = 19
        ELSE
            ABulletX = ABulletX - 1
        END IF
    END IF

    ' Draw new positions (both bright white for visibility)
    PRINT AT 60 + BulletX, GRAM_STAR2 * 8 + 7 + $0800   ' Row 3, white (fast)
    PRINT AT 80 + ABulletX, GRAM_STAR1 * 8 + 7 + $0800  ' Row 4, white (slow)
    RETURN
END

' --- DrawSilhouette: draw scrolling mountain silhouette on row 0 ---
DrawSilhouette: PROCEDURE
    FOR Col = 0 TO 19
        LoopVar = SilhOffset + Col
        IF LoopVar >= SILH_MAP_LEN THEN LoopVar = LoopVar - SILH_MAP_LEN
        Row = SilhHeightMap(LoopVar)
        PRINT AT Col, SilhCardMap(Row)
    NEXT Col
    RETURN
END

ZodRender: PROCEDURE
    FlyFrame = FlyFrame + 1
    IF FlyFrame >= 16 THEN FlyFrame = 0
    FlyColorTimer = FlyColorTimer + 1
    IF FlyColorTimer >= 24 THEN
        FlyColorTimer = 0
        FlyColorIdx = FlyColorIdx + 1
        IF FlyColorIdx >= 6 THEN FlyColorIdx = 0
        FlyColor = FlyColors(FlyColorIdx)
    END IF
    IF FlyFrame < 8 THEN
        SPRITE SPR_FLYER, FlyX + SPR_VISIBLE, FlyY, GRAM_CRAB_F1 * 8 + FlyColor + $0800
    ELSE
        SPRITE SPR_FLYER, FlyX + SPR_VISIBLE, FlyY, GRAM_CRAB_F2 * 8 + FlyColor + $0800
    END IF
    RETURN
    END
' ============================================
' GAME OVER LETTERS: G, M, O, V
' Y-Axis rotation frames
' ============================================

' Letter G - Frame 1 (0°)
FontGY1Gfx:
    BITMAP ".XXXXXX."
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX..XXX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP ".XXXXX.."

' Letter G - Frame 3 (60°)
FontGY3Gfx:
    BITMAP ".XXXXX.."
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX..XX.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP ".XXXXX.."

' Letter G - Frame 4 (90°)
FontGY4Gfx:
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XXX..."

' Letter M - Frame 1 (0°)
FontMY1Gfx:
    BITMAP "XX...XX."
    BITMAP "XXX.XXX."
    BITMAP "XXXXXXX."
    BITMAP "XX.X.XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."

' Letter M - Frame 3 (60°)
FontMY3Gfx:
    BITMAP "XX...X.."
    BITMAP "XXX.XX.."
    BITMAP "XXXXXX.."
    BITMAP "XX.X.X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."

' Letter M - Frame 4 (90°)
FontMY4Gfx:
    BITMAP "..XX...."
    BITMAP "..XXX..."
    BITMAP "..XXX..."
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."

' Letter O - Frame 1 (0°)
FontOY1Gfx:
    BITMAP ".XXXXX.."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP ".XXXXX.."

' Letter O - Frame 3 (60°)
FontOY3Gfx:
    BITMAP ".XXXXX.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP ".XXXXX.."

' Letter O - Frame 4 (90°)
FontOY4Gfx:
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XXX..."

' Letter V - Frame 1 (0°)
FontVY1Gfx:
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP ".XX.XX.."
    BITMAP "..XXX..."
    BITMAP "...X...."

' Letter V - Frame 3 (60°)
FontVY3Gfx:
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP ".XX.XX.."
    BITMAP "..XXX..."
    BITMAP "...X...."

' Letter V - Frame 4 (90°)
FontVY4Gfx:
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..X....."

    ' ============================================================
    ' SEGMENT 5 — SCORE DATA + COMPACT SCORE ASSEMBLY LIBRARY
    ' ============================================================
    SEGMENT 5

    INCLUDE "lib/compact_score.bas"

' Pre-computed packed digit pair shapes for DEFINE ALTERNATE score update.
' 110 entries: 0-99 = two-digit pairs (L*10+R), 100-109 = single digit + blank.
' Each entry = 4 packed DECLEs (2 rows per word, 8 rows per GRAM card).
' Format matches IntyBASIC BITMAP/DEFINE: Word N = (row[2N+1] << 8) | row[2N]
