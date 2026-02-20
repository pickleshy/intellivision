' ============================================
' SPACE INTRUDERS - Title Screen Module
' ============================================
' Title screen rendering and input handling
' Segment: 1 (non-critical, moved from Seg 0 to free main segment)

    SEGMENT 1

' === Title Screen Logic ===

' ============================================
' TITLE SCREEN
' ============================================
TitleScreen:
    CLS

    ' Initialize Y-axis letter animation state
    TitleAnimState = 0     ' 0=reveal phase (uses dynamic frame calculation)
    RevealCol = 0          ' Current reveal position (0-14)
    VanishCol = 0          ' Current vanish position (0-14)

    ' Load animated title font GRAM (uses gameplay cards 0-55, preserves band/crab/sparks/stars)
    GOSUB LoadAnimatedFont

    ' Restore star graphics (cards 37-38, not touched by animated font)
    DEFINE GRAM_STAR1, 1, Star1Gfx   ' Card 37
    WAIT
    DEFINE GRAM_STAR2, 1, Star2Gfx   ' Card 38
    WAIT
    ' Reload band alien sprites (cards 9-12, game over TinyFont overwrites them)
    GOSUB ReloadBandSprites
    ' Reload Zod crab sprites (cards 19-20, boot splash date overwrites them)
    DEFINE GRAM_CRAB_F1, 2, SmallCrabF1Gfx
    WAIT

    PowerUpState = 0      ' [title: animation frame counter]
    PowerUpX = 1          ' [title: march direction 1=right, 0=left]
    CapsuleColor1 = 0     ' [title: march step counter]
    CapsuleColor2 = 4     ' [title: grid left-edge column]

    ' Display title text with initial animation frames (edge view)
    GOSUB DrawTitleAnimated

    ' Static star field (25 stars, no arrays!) + 2 animated stars for motion
    GOSUB DrawStaticStars
    BulletX = RANDOM(20)    ' Animated star 1 starting position
    ABulletX = RANDOM(20)   ' Animated star 2 starting position

    ' "PRESS FIRE" slides in from edges — don't print here
    WavePhase = 0          ' Color cycle index for PRESS FIRE
    PowerUpType = 0        ' [title: color shimmer / slide timer]
    CapsuleFrame = 0       ' [title: slide-in position 0=edges, 5=final, 6+=done]
    FireCooldown = 0       ' [title: bolt sweep position 0-14=char, 15-19=gap]
    TitleMarchX = 0        ' Bolt frame counter

    ' Draw 3x3 alien grid on BACKTAB (rows 5-7, starting at CapsuleColor2)
    GOSUB DrawAlienGrid

    ' Initialize Zod via flight engine
    FlyColors(0) = 7 : FlyColors(1) = 6 : FlyColors(2) = 5
    FlyColors(3) = 3 : FlyColors(4) = 5 : FlyColors(5) = 6
    FlyFrame = 0 : FlyColorIdx = 0 : FlyColorTimer = 0 : FlyColor = 7
    FlyX = 0 : FlyY = 0   ' Start off-screen top-left
    LoopVar = PAT_FIGURE8
    GOSUB FlightStart

    ' Start title music (PLAY FULL for full 3-channel theme)
    PLAY FULL
    PLAY VOLUME 12
    PLAY space_intruders_theme

' --------------------------------------------
' Title Loop - card-step march (no SCROLL)
' --------------------------------------------
    ' Wait for all buttons/keys released before accepting input
TitleDebounce:
    WAIT
    IF CONT.BUTTON OR CONT.KEY < 12 THEN GOTO TitleDebounce

TitleLoop:
    WAIT

    ' Hide unused sprites
    SPRITE 0, 0, 0, 0
    SPRITE 1, 0, 0, 0
    SPRITE 2, 0, 0, 0
    SPRITE 3, 0, 0, 0
    SPRITE 4, 0, 0, 0
    SPRITE 6, 0, 0, 0
    SPRITE 7, 0, 0, 0

    ' --- Flying crab "Zod" state machine ---
    ' States: 0=enter from left, 1=figure-8 loops, 2=exit right, 3=offscreen pause
    ' --- Zod flight: engine handles transition + pattern, hand-coded exit/pause ---
    IF FlyState <= FLT_DONE THEN
        ' Engine active: transition, following, or just finished
        GOSUB FlightTick
        IF FlyState = FLT_DONE THEN
            FlyState = 4       ' Switch to hand-coded exit wobble
            #FlyPhase = 0
        END IF
    ELSEIF FlyState = 4 THEN
        ' Exit right with Y wobble (hand-coded)
        FlySpeed = FlySpeed + 1
        IF FlySpeed >= 3 THEN
            FlySpeed = 0
            FlyX = FlyX + 4
            #FlyPhase = #FlyPhase + 1
            IF (#FlyPhase AND 3) = 0 THEN
                FlyY = 53
            ELSEIF (#FlyPhase AND 3) = 1 THEN
                FlyY = 56
            ELSEIF (#FlyPhase AND 3) = 2 THEN
                FlyY = 59
            ELSE
                FlyY = 56
            END IF
            IF FlyX > 167 THEN
                FlyState = 5       ' Offscreen pause
                #FlyPhase = 0
            END IF
        END IF
    ELSE
        ' FlyState=5: Offscreen pause (~1 sec = 20 steps × 3 frames)
        FlySpeed = FlySpeed + 1
        IF FlySpeed >= 3 THEN
            FlySpeed = 0
            #FlyPhase = #FlyPhase + 1
            IF #FlyPhase >= 20 THEN
                ' Restart: re-enter from top-left
                FlyX = 0 : FlyY = 0
                LoopVar = PAT_FIGURE8
                GOSUB FlightStart
                ' Reset title animation for another reveal cascade
                TitleAnimState = 0
                RevealCol = 0
                GOSUB DrawTitleAnimated
            END IF
        END IF
    END IF

    ' Gradual color shift every 32 frames
    FlyColorTimer = FlyColorTimer + 1
    IF FlyColorTimer >= 32 THEN
        FlyColorTimer = 0
        FlyColorIdx = FlyColorIdx + 1
        IF FlyColorIdx >= 6 THEN FlyColorIdx = 0
        FlyColor = FlyColors(FlyColorIdx)
    END IF

    ' Draw Zod (or hide if offscreen pause)
    FlyFrame = FlyFrame + 1
    IF FlyFrame >= 16 THEN FlyFrame = 0
    IF FlyState = 5 THEN
        SPRITE SPR_FLYER, 0, 0, 0
    ELSE
        IF FlyFrame < 8 THEN
            SPRITE SPR_FLYER, FlyX + SPR_VISIBLE, FlyY, GRAM_CRAB_F1 * 8 + FlyColor + $0800
        ELSE
            SPRITE SPR_FLYER, FlyX + SPR_VISIBLE, FlyY, GRAM_CRAB_F2 * 8 + FlyColor + $0800
        END IF
    END IF

    ' --- Y-Axis Letter Animation ---
    ' Simple: Zod's X position directly determines which letters are revealed
    IF TitleAnimState = 0 THEN
        ' RevealCol = FlyX / 5, capped at 14
        Col = FlyX / 5
        IF Col > 14 THEN Col = 14
        IF Col <> RevealCol THEN
            RevealCol = Col
            GOSUB DrawTitleAnimated
        END IF
        ' All letters revealed when RevealCol reaches 14
        IF RevealCol >= 14 THEN
            TitleAnimState = 1
            GOSUB DrawTitleAnimated  ' Redraw all letters as full (state 1)
        END IF
    END IF

    ' Vanish cascade: VanishCol 0-15 = letters (fast), 16+ = screen wipe (2 cols/frame)
    IF TitleAnimState = 2 THEN
        IF VanishCol < 16 THEN
            ' Phase 1: Letter vanish animation (2x speed)
            VanishCol = VanishCol + 2
            GOSUB DrawTitleAnimated
        ELSE
            ' Phase 2: Screen wipe - clear 1 column per frame (smooth sweep)
            WipeCol = VanishCol - 16
            IF WipeCol < 20 THEN
                FOR Row = 0 TO 11
                    PRINT AT Row * 20 + WipeCol, 0
                NEXT Row
            END IF
            VanishCol = VanishCol + 1
            GOSUB HideAllSprites
        END IF
        IF VanishCol >= 36 THEN
            ' Wipe complete - transition to gameplay
            SOUND 0, , 0 : SOUND 1, , 0 : SOUND 2, , 0
            POKE $1F8, $3F
            PLAY SIMPLE : PLAY VOLUME 12 : PLAY si_bg_mid
            GOTO StartGame
        END IF
    END IF

    ' March animation - move grid 1 card every 32 frames
    CapsuleColor1 = CapsuleColor1 + 1
    IF CapsuleColor1 >= 32 THEN
        CapsuleColor1 = 0

        IF PowerUpX = 1 THEN
            CapsuleColor2 = CapsuleColor2 + 1
            IF CapsuleColor2 >= 10 THEN
                PowerUpX = 0  ' Reverse to left
            END IF
        ELSE
            CapsuleColor2 = CapsuleColor2 - 1  ' audit-ignore: <= 1 reversal below; momentarily 0 is fine (bounces back next frame)
            IF CapsuleColor2 <= 1 THEN
                PowerUpX = 1  ' Reverse to right
            END IF
        END IF

        GOSUB DrawAlienGrid
    END IF

    ' Title text white bolt sweep - advance every 6 frames
    ' Color Stack BACKTAB: FG color in bits 0-2 (and bit 12 for pastel colors 8+)
    ' GROM card number in bits 3-10. Mask $EFF8 clears color bits 0-2 and 12.
    TitleMarchX = TitleMarchX + 1
    IF TitleMarchX >= 6 THEN
        TitleMarchX = 0
        ' Restore current bolt position to green and clear sparks (if visible)
        IF FireCooldown < 15 THEN
            #Card = PEEK($216 + FireCooldown)
            PRINT AT 22 + FireCooldown, (#Card AND $EFF8) OR $0003
            PRINT AT 2 + FireCooldown, 0    ' Clear spark above
            PRINT AT 42 + FireCooldown, 0   ' Clear spark below
        END IF
        ' Advance bolt position
        FireCooldown = FireCooldown + 1
        IF FireCooldown >= 20 THEN FireCooldown = 0
        ' Set new bolt position to white and place sparks (if visible)
        IF FireCooldown < 15 THEN
            #Card = PEEK($216 + FireCooldown)
            PRINT AT 22 + FireCooldown, (#Card AND $EFF8) OR $0007
            ' Grey sparks: color 8 on GRAM = low bits 0 + bit 12 → card*8 + $1800
            PRINT AT 2 + FireCooldown, GRAM_SPARK_UP * 8 + $1800
            PRINT AT 42 + FireCooldown, GRAM_SPARK_DN * 8 + $1800
        END IF
    END IF

    ' Spark 2-frame animation: frame 1 (0-2) → frame 2 (3-5) within each bolt step
    IF FireCooldown < 15 THEN
        IF TitleMarchX >= 3 THEN
            ' Frame 2: trailing dot position
            PRINT AT 2 + FireCooldown, GRAM_SPARK_UP2 * 8 + $1800
            PRINT AT 42 + FireCooldown, GRAM_SPARK_DN2 * 8 + $1800
        END IF
    END IF

    ' Screen shake (title screen) - same pattern as gameplay
    IF ShakeTimer > 0 THEN
        ShakeTimer = ShakeTimer - 1
        IF ShakeTimer > 0 THEN
            GOSUB DoScreenShake
        ELSE
            SCROLL 0, 0  ' Reset to normal when done
        END IF
    END IF

    ' "PRESS FIRE" slide-in from edges, then shimmer (GRAM font)
    ' Wait until flyer begins pattern before starting slide-in
    IF FlyState = FLT_TRANSITION THEN GOTO SkipPressfire

    ' When Zod exits (state 4): rapid flash then disappear
    IF FlyState = 4 THEN
        ' Toggle visible/invisible every 2 frames for rapid blink
        PowerUpType = PowerUpType + 1
        IF PowerUpType >= 4 THEN PowerUpType = 0
        IF PowerUpType < 2 THEN
            ' Visible frame (grey = dim flash)
            GOSUB DrawPressFire_Grey
        ELSE
            ' Invisible frame (clear)
            FOR LoopVar = 205 TO 214
                PRINT AT LoopVar, 0
            NEXT LoopVar
        END IF
        GOTO SkipPressfire
    END IF

    ' When Zod is offscreen (state 5): clear text and reset for next cycle
    IF FlyState = 5 THEN
        IF CapsuleFrame > 0 THEN
            FOR LoopVar = 200 TO 219
                PRINT AT LoopVar, 0
            NEXT LoopVar
            CapsuleFrame = 0
            PowerUpType = 0
            WavePhase = 0
        END IF
        GOTO SkipPressfire
    END IF

    IF CapsuleFrame <= 5 THEN
        ' Slide-in phase: PRESS from left, FIRE from right
        PowerUpType = PowerUpType + 1
        IF PowerUpType >= 8 THEN
            PowerUpType = 0
            ' Clear row 10
            FOR LoopVar = 200 TO 219
                PRINT AT LoopVar, 0
            NEXT LoopVar
            ' "PRESS" slides from col 0 to col 5 (white, GRAM)
            #Card = 200 + CapsuleFrame
            PRINT AT #Card, GRAM_FONT_P * 8 + COL_WHITE + $0800
            PRINT AT #Card + 1, GRAM_FONT_R * 8 + COL_WHITE + $0800
            PRINT AT #Card + 2, GRAM_FONT_E * 8 + COL_WHITE + $0800
            PRINT AT #Card + 3, GRAM_FONT_S * 8 + COL_WHITE + $0800
            PRINT AT #Card + 4, GRAM_FONT_S * 8 + COL_WHITE + $0800
            ' "FIRE" slides from col 16 to col 11
            #Card = 216 - CapsuleFrame
            PRINT AT #Card, GRAM_FONT_F * 8 + COL_WHITE + $0800
            PRINT AT #Card + 1, GRAM_FONT_I * 8 + COL_WHITE + $0800
            PRINT AT #Card + 2, GRAM_FONT_R * 8 + COL_WHITE + $0800
            PRINT AT #Card + 3, GRAM_FONT_E * 8 + COL_WHITE + $0800
            CapsuleFrame = CapsuleFrame + 1
            ' Trigger impact shake when words connect (CapsuleFrame just became 6)
            IF CapsuleFrame = 6 THEN ShakeTimer = 8
        END IF
    ELSE
        ' Shimmer - cycle Grey/White every 12 frames
        GOSUB ShimmerPressFire
    END IF
SkipPressfire:

    ' Animate stars - 2 scrolling stars give illusion of motion (every 5 frames)
    StarTimer = StarTimer + 1
    IF StarTimer >= 5 THEN
        StarTimer = 0
        GOSUB AnimateStars
    END IF

    ' Animation - toggle walk frame every 16 frames via GRAM redefine
    ShimmerCount = ShimmerCount + 1
    IF ShimmerCount >= 16 THEN
        ShimmerCount = 0
        PowerUpState = 1 - PowerUpState
        IF PowerUpState = 0 THEN
            DEFINE GRAM_BAND1, 1, Band1Gfx
            WAIT
            DEFINE GRAM_BAND2, 1, Band2Gfx
        ELSE
            DEFINE GRAM_BAND1, 1, Band1F1Gfx
            WAIT
            DEFINE GRAM_BAND2, 1, Band2F1Gfx
        END IF
    END IF

    ' Cheat code: type "36" on keypad to toggle debug mode
    ' CheatCode packed: bits 0-2 = held timer, bit 3 = got '3'
    IF CONT.KEY = 3 THEN
        IF (CheatCode AND 7) = 0 THEN
            CheatCode = 8 + 5  ' Set state=1 (bit 3), held=5
        END IF
    ELSEIF CONT.KEY = 6 THEN
        IF (CheatCode AND 7) = 0 THEN
            CheatCode = (CheatCode AND 8) + 5  ' Keep state, set held=5
            IF CheatCode >= 8 THEN
                #GameFlags = #GameFlags XOR FLAG_DEBUG
                CheatCode = 5  ' Clear state, keep held=5
                ' Flash border to confirm
                IF #GameFlags AND FLAG_DEBUG THEN
                    BORDER COL_RED
                    PRINT AT 215 COLOR COL_RED, "DEBUG"
                ELSE
                    BORDER 0
                    PRINT AT 215, 0
                    PRINT AT 216, 0
                    PRINT AT 217, 0
                    PRINT AT 218, 0
                    PRINT AT 219, 0
                END IF
            END IF
        END IF
    ELSE
        IF CheatCode AND 7 THEN CheatCode = CheatCode - 1  ' audit-ignore: AND 7 guard ensures lower bits nonzero (>= 1)
        ' Reset cheat state if a non-3/6 key is pressed
        IF CONT.KEY < 12 THEN
            IF CONT.KEY <> 3 THEN
                IF CONT.KEY <> 6 THEN CheatCode = CheatCode AND 7  ' Clear bit 3
            END IF
        END IF
    END IF

    ' Fire button: must hold 4 frames with NO keypad key active
    IF CONT.BUTTON THEN
        IF CONT.KEY >= 12 THEN
            IF Key1Held < 4 THEN Key1Held = Key1Held + 1
        ELSE
            Key1Held = 0    ' Keypad active — reset counter
        END IF
    ELSE
        Key1Held = 0
    END IF
    IF Key1Held >= 4 THEN
        ' Start vanish cascade (only if not already vanishing)
        IF TitleAnimState = 0 OR TitleAnimState = 1 THEN
            TitleAnimState = 2
            VanishCol = 0
        END IF
    END IF

    GOTO TitleLoop

