' ============================================
' Starfield Demo - Intellivision
' ============================================
' Three starfield modes, cycle with action button
' Mode A: Static random stars
' Mode B: Static + twinkling
' Mode C: Scrolling parallax
' ============================================

    MODE 0, 0, 0, 0, 0   ' Color Stack mode, black BG
    CLS
    WAIT

    ' Define star GRAM cards
    ' GRAM 0: dot top-left
    ' GRAM 1: dot center-right
    ' GRAM 2: dot bottom-center
    ' GRAM 3: dot top-right + bottom-left (double star)
    DEFINE 0, 4, StarDot1
    WAIT

' --- Variables ---
DIM StarPos(40)            ' Star BACKTAB positions (max 40 stars)
DIM StarCard(40)           ' Star GRAM card for each position
StarCount = 0              ' Number of active stars
StarMode  = 0              ' 0=A static, 1=B twinkle, 2=C scroll
TwinkleIdx = 0             ' Current star to twinkle
TwinkleTimer = 0           ' Frame counter for twinkle
ScrollTimer = 0            ' Frame counter for scroll speed
ScrollTick = 0             ' Counts scroll updates (for slow layer)
ButtonHeld = 0             ' Debounce flag
LoopVar = 0                ' General loop variable
#ScreenPos = 0             ' Temp screen position
#Card = 0                  ' Temp card value

' --- Star color constants ---
' Blue (1) for dim distant stars, White (7) for bright ones
' Dark Green (4) for very dim stars
CONST COL_DIM    = 4       ' Dark green (barely visible)
CONST COL_MED    = 1       ' Blue (medium)
CONST COL_BRIGHT = 7       ' White (bright)

' --- Generate initial starfield ---
GOSUB GenerateStars
GOSUB DrawStars
GOSUB DrawModeLabel

' ============================================
' Main Loop
' ============================================
MainLoop:
    WAIT

    ' --- Check button press (with debounce) ---
    IF CONT.BUTTON THEN
        IF ButtonHeld = 0 THEN
            ButtonHeld = 1
            ' Cycle mode: 0 → 1 → 2 → 0
            StarMode = StarMode + 1
            IF StarMode >= 3 THEN StarMode = 0
            ' Regenerate stars for new mode
            CLS
            GOSUB GenerateStars
            GOSUB DrawStars
            GOSUB DrawModeLabel
        END IF
    ELSE
        ButtonHeld = 0
    END IF

    ' --- Mode-specific per-frame updates ---
    IF StarMode = 1 THEN
        ' Mode B: Twinkle - toggle 1 star per frame
        TwinkleTimer = TwinkleTimer + 1
        IF TwinkleTimer >= 3 THEN
            TwinkleTimer = 0
            ' Toggle current star visible/invisible
            #ScreenPos = StarPos(TwinkleIdx)
            #Card = PEEK($200 + #ScreenPos)
            IF #Card = 0 THEN
                ' Star is off - turn it back on
                ' Pick brightness based on card type
                IF StarCard(TwinkleIdx) = 0 THEN
                    PRINT AT #ScreenPos, 0 * 8 + COL_DIM + $0800
                ELSEIF StarCard(TwinkleIdx) = 1 THEN
                    PRINT AT #ScreenPos, 1 * 8 + COL_MED + $0800
                ELSEIF StarCard(TwinkleIdx) = 2 THEN
                    PRINT AT #ScreenPos, 2 * 8 + COL_BRIGHT + $0800
                ELSE
                    PRINT AT #ScreenPos, 3 * 8 + COL_BRIGHT + $0800
                END IF
            ELSE
                ' Star is on - turn it off
                PRINT AT #ScreenPos, 0
            END IF
            ' Advance to next star
            TwinkleIdx = TwinkleIdx + 1
            IF TwinkleIdx >= StarCount THEN TwinkleIdx = 0
        END IF

    ELSEIF StarMode = 2 THEN
        ' Mode C: Scroll - shift stars left at different speeds
        ScrollTimer = ScrollTimer + 1
        IF ScrollTimer >= 4 THEN
            ScrollTimer = 0
            ScrollTick = ScrollTick + 1
            ' Move each star left by 1 column, wrap around
            FOR LoopVar = 0 TO StarCount - 1
                ' Calculate current row and column
                #ScreenPos = StarPos(LoopVar)
                Row = #ScreenPos / 20
                Col = #ScreenPos - (Row * 20)

                ' Clear old position
                PRINT AT #ScreenPos, 0

                ' Determine speed layer by card type
                ' Card 0 (dim) = slow (every other tick)
                ' Card 1 (med) = normal (every tick)
                ' Card 2-3 (bright) = fast (2 cols per tick)
                IF StarCard(LoopVar) = 0 THEN
                    ' Slow layer: only move on even ticks
                    IF (ScrollTick AND 1) = 0 THEN
                        IF Col = 0 THEN
                            Col = 19
                        ELSE
                            Col = Col - 1
                        END IF
                    END IF
                ELSEIF StarCard(LoopVar) = 1 THEN
                    ' Medium layer: move 1
                    IF Col = 0 THEN
                        Col = 19
                    ELSE
                        Col = Col - 1
                    END IF
                ELSE
                    ' Fast layer: move 2
                    IF Col <= 1 THEN
                        Col = Col + 18
                    ELSE
                        Col = Col - 2
                    END IF
                END IF

                ' Update position and redraw
                StarPos(LoopVar) = Row * 20 + Col
                #ScreenPos = StarPos(LoopVar)

                IF StarCard(LoopVar) = 0 THEN
                    PRINT AT #ScreenPos, 0 * 8 + COL_DIM + $0800
                ELSEIF StarCard(LoopVar) = 1 THEN
                    PRINT AT #ScreenPos, 1 * 8 + COL_MED + $0800
                ELSEIF StarCard(LoopVar) = 2 THEN
                    PRINT AT #ScreenPos, 2 * 8 + COL_BRIGHT + $0800
                ELSE
                    PRINT AT #ScreenPos, 3 * 8 + COL_BRIGHT + $0800
                END IF
            NEXT LoopVar

            ' Redraw label (scroll may overwrite it)
            GOSUB DrawModeLabel
        END IF
    END IF

    GOTO MainLoop

' ============================================
' GenerateStars - Place random stars
' ============================================
GenerateStars: PROCEDURE
    StarCount = 0
    TwinkleIdx = 0
    ScrollTimer = 0
    ScrollTick = 0

    ' Place ~35 stars in rows 0-10 (skip row 11 for labels)
    FOR LoopVar = 0 TO 34
        ' Random position: row 0-10, col 0-19
        Row = RANDOM(11)
        Col = RANDOM(20)
        #ScreenPos = Row * 20 + Col

        ' Random card type (0-3) determines brightness/dot position
        StarCard(LoopVar) = RANDOM(4)
        StarPos(LoopVar) = #ScreenPos
        StarCount = StarCount + 1
    NEXT LoopVar
    RETURN
END

' ============================================
' DrawStars - Render all stars to screen
' ============================================
DrawStars: PROCEDURE
    FOR LoopVar = 0 TO StarCount - 1
        #ScreenPos = StarPos(LoopVar)
        IF StarCard(LoopVar) = 0 THEN
            PRINT AT #ScreenPos, 0 * 8 + COL_DIM + $0800
        ELSEIF StarCard(LoopVar) = 1 THEN
            PRINT AT #ScreenPos, 1 * 8 + COL_MED + $0800
        ELSEIF StarCard(LoopVar) = 2 THEN
            PRINT AT #ScreenPos, 2 * 8 + COL_BRIGHT + $0800
        ELSE
            PRINT AT #ScreenPos, 3 * 8 + COL_BRIGHT + $0800
        END IF
    NEXT LoopVar
    RETURN
END

' ============================================
' DrawModeLabel - Show current mode on row 11
' ============================================
DrawModeLabel: PROCEDURE
    ' Clear row 11
    FOR LoopVar = 220 TO 239
        PRINT AT LoopVar, 0
    NEXT LoopVar

    IF StarMode = 0 THEN
        PRINT AT 220 COLOR 6, "A: STATIC STARS"
    ELSEIF StarMode = 1 THEN
        PRINT AT 220 COLOR 6, "B: TWINKLE"
    ELSE
        PRINT AT 220 COLOR 6, "C: SCROLLING"
    END IF
    RETURN
END

' ============================================
' Graphics Data - Star dot patterns
' ============================================
' Each card has a single pixel dot at a different position
' This gives variety so stars don't all look the same

' GRAM 0: dot at top-left (row 1, col 1) - dim distant
StarDot1:
    BITMAP "........"
    BITMAP ".X......"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"

' GRAM 1: dot at center-right (row 3, col 5) - medium
StarDot2:
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP ".....X.."
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"

' GRAM 2: dot at bottom-center (row 6, col 3) - bright
StarDot3:
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "...X...."
    BITMAP "........"

' GRAM 3: two dots (row 1 col 6, row 5 col 2) - bright double
StarDot4:
    BITMAP "........"
    BITMAP "......X."
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "..X....."
    BITMAP "........"
    BITMAP "........"
