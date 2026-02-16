' ============================================
' SPACE INTRUDERS - Powerups Module
' ============================================
' Power-up drops and pickups
' Segment: 2

    SEGMENT 2

UpdatePowerUp: PROCEDURE
    IF PowerUpState = 0 THEN RETURN

    ' Set capsule flash colors based on power-up type
    ' Reuse CapsuleColor2/CapsuleColor1 as temp color vars
    IF PowerUpType = 0 THEN
        CapsuleColor2 = COL_BLUE      ' Beam: blue/white
        CapsuleColor1 = COL_WHITE
    ELSEIF PowerUpType = 1 THEN
        CapsuleColor2 = COL_YELLOW    ' Rapid: yellow/green
        CapsuleColor1 = COL_GREEN
    ELSEIF PowerUpType = 2 THEN
        CapsuleColor2 = COL_YELLOW    ' Bomb: yellow/red danger pulse
        CapsuleColor1 = COL_RED
    ELSEIF PowerUpType = 3 THEN
        CapsuleColor2 = COL_RED       ' Mega: red/tan
        CapsuleColor1 = COL_TAN
    ELSE
        CapsuleColor2 = COL_CYAN      ' Shield: cyan/blue
        CapsuleColor1 = COL_BLUE
    END IF

    IF PowerUpState = 1 THEN
        ' Falling: move down 2px per frame
        PowerUpY = PowerUpY + 2
        IF PowerUpY >= PLAYER_Y THEN
            ' Landed at player level
            PowerUpY = PLAYER_Y
            PowerUpState = 2
            #PowerTimer = 300   ' 5 seconds to pick up
            CapsuleFrame = 0
        END IF
        ' Draw falling capsule (animated frame + color flash)
        CapsuleFrame = CapsuleFrame + 1
        IF CapsuleFrame >= 8 THEN CapsuleFrame = 0
        IF CapsuleFrame < 4 THEN
            SPRITE SPR_POWERUP, PowerUpX + $0200, PowerUpY, (GRAM_CAP_F1 + CapsuleFrame / 2) * 8 + CapsuleColor2 + $0800
        ELSE
            SPRITE SPR_POWERUP, PowerUpX + $0200, PowerUpY, (GRAM_CAP_F1 + CapsuleFrame / 2) * 8 + CapsuleColor1 + $0800
        END IF
        RETURN
    END IF

    ' State 2: Landed - waiting for pickup
    #PowerTimer = #PowerTimer - 1

    ' Check pickup: player X overlaps power-up X (within ±12px)
    IF DeathTimer = 0 THEN
        IF PlayerX >= PowerUpX - 12 THEN
            IF PlayerX <= PowerUpX + 12 THEN
                ' Picked up! Activate power-up based on type
                IF PowerUpType = 0 THEN
                    BeamTimer = 1
                    RapidTimer = 0 : #GameFlags = #GameFlags AND ($FFFF XOR FLAG_BOMB) : #MegaTimer = 0
                    DEFINE GRAM_PWR1, 2, PowerupBeamGfx
                    IF VOICE.AVAILABLE THEN VOICE PLAY beam_phrase
                ELSEIF PowerUpType = 1 THEN
                    RapidTimer = 1
                    BeamTimer = 0 : #GameFlags = #GameFlags AND ($FFFF XOR FLAG_BOMB) : #MegaTimer = 0
                    DEFINE GRAM_PWR1, 3, PowerupRapidGfx
                    IF VOICE.AVAILABLE THEN VOICE PLAY rapid_phrase
                ELSEIF PowerUpType = 2 THEN
                    #GameFlags = #GameFlags OR FLAG_BOMB
                    BeamTimer = 0 : RapidTimer = 0 : #MegaTimer = 0
                    DEFINE GRAM_PWR1, 2, PowerupBombGfx
                    IF VOICE.AVAILABLE THEN VOICE PLAY bomb_phrase
                ELSEIF PowerUpType = 3 THEN
                    #MegaTimer = 120
                    BeamTimer = 0 : RapidTimer = 0 : #GameFlags = #GameFlags AND ($FFFF XOR FLAG_BOMB)
                    DEFINE GRAM_PWR1, 2, PowerupMegaGfx
                    IF VOICE.AVAILABLE THEN VOICE PLAY mega_phrase
                ELSE
                    ' Shield - coexists with weapons, just set hits
                    ShieldHits = 2
                    IF VOICE.AVAILABLE THEN VOICE PLAY shield_phrase
                END IF
                PowerUpState = 0
                SPRITE SPR_POWERUP, 0, 0, 0
                ' Clear tutorial message if showing
                IF TutorialTimer > 0 THEN
                    IF TutorialTimer < 255 THEN
                        TutorialTimer = 0
                        PRINT AT 180, "                    "
                    END IF
                END IF
                ' Weighted random next power-up type
                PowerUpType = PowerUpWeights(RANDOM(8))
                RETURN
            END IF
        END IF
    END IF

    ' Check timeout
    IF #PowerTimer = 0 THEN
        PowerUpState = 0
        SPRITE SPR_POWERUP, 0, 0, 0
        ' Clear tutorial message if showing
        IF TutorialTimer > 0 THEN
            IF TutorialTimer < 255 THEN
                TutorialTimer = 0
                PRINT AT 200, "                    "
            END IF
        END IF
        RETURN
    END IF

    ' Draw landed capsule with flash effect + animated frame
    CapsuleFrame = CapsuleFrame + 1
    IF CapsuleFrame >= 8 THEN CapsuleFrame = 0
    IF #PowerTimer < 100 THEN
        ' Rapid flash in last ~1.7 seconds (every 2 frames)
        IF CapsuleFrame < 2 THEN
            SPRITE SPR_POWERUP, PowerUpX + $0200, PLAYER_Y, (GRAM_CAP_F1 + CapsuleFrame / 2) * 8 + CapsuleColor2 + $0800
        ELSEIF CapsuleFrame < 4 THEN
            SPRITE SPR_POWERUP, 0, 0, 0  ' Invisible
        ELSEIF CapsuleFrame < 6 THEN
            SPRITE SPR_POWERUP, PowerUpX + $0200, PLAYER_Y, (GRAM_CAP_F1 + CapsuleFrame / 2) * 8 + CapsuleColor1 + $0800
        ELSE
            SPRITE SPR_POWERUP, 0, 0, 0  ' Invisible
        END IF
    ELSE
        ' Normal flash (animated frame + color cycle)
        IF CapsuleFrame < 4 THEN
            SPRITE SPR_POWERUP, PowerUpX + $0200, PLAYER_Y, (GRAM_CAP_F1 + CapsuleFrame / 2) * 8 + CapsuleColor2 + $0800
        ELSE
            SPRITE SPR_POWERUP, PowerUpX + $0200, PLAYER_Y, (GRAM_CAP_F1 + CapsuleFrame / 2) * 8 + CapsuleColor1 + $0800
        END IF
    END IF
    RETURN
END

' --------------------------------------------
' ComputeBossCard - Build #Card BACKTAB value for a boss alien
' Input: FoundBoss = boss slot, Col = current grid column
' Output: #Card = full BACKTAB card value (GRAM + color + flags)
' Uses: HitCol (temp for bomb flash color)
' --------------------------------------------
