' ============================================
' SPACE INTRUDERS - AI Systems Module
' ============================================
' Special enemy behaviors (wingman, rogue diver, bonus saucer)
' Segment: 4 (already in Seg 4)

    SEGMENT 4

' === AI Systems ===

    ' SEGMENT 4 — AI SYSTEMS (CAPTURE, ROGUE, SAUCER)
    ' ============================================================
    SEGMENT 4

' --------------------------------------------
' RogueFire - Rogue alien fires alien bullet at current position
' Resets RogueTimer; fires only if no bullet active and saucer not chasing
' --------------------------------------------
RogueFire: PROCEDURE
    RogueTimer = 0
    IF (#GameFlags AND FLAG_ABULLET) = 0 THEN
        IF FlyState <> SAUCER_CHASE THEN
            ABulletX = RogueX + 3
            ABulletY = RogueY + 8
            ABulFrame = ABulFrame AND 1
            #GameFlags = #GameFlags OR FLAG_ABULLET
        END IF
    END IF
    RETURN
END

' --------------------------------------------
' UpdateCapture - Orbit captured wingman around player ship
' --------------------------------------------
UpdateCapture: PROCEDURE
    ' Advance orbit step every 2 frames (16-step circle, slower orbit)
    IF (CaptureTimer AND 1) = 0 THEN
        CaptureStep = CaptureStep + 1
        IF CaptureStep >= 16 THEN CaptureStep = 0
    END IF

    ' Compute orbit position centered on player (use HitCol/HitRow as temps
    ' to avoid clobbering RogueX/RogueY which the rogue dive system needs)
    HitCol = PlayerX - 4 + CaptureOrbitDX(CaptureStep) - CAPTURE_ORBIT_R
    HitRow = PLAYER_Y - 12 + CaptureOrbitDY(CaptureStep) - CAPTURE_ORBIT_R

    ' Clamp X to valid sprite range
    IF HitCol > 200 THEN HitCol = 0  ' unsigned underflow guard
    IF HitCol > 160 THEN HitCol = 160

    ' Render wingman (skip if power-up capsule is using the sprite)
    ' Uses Mooninite-style graphics (GRAM_WINGMAN_F1/F2) in captured alien's color
    IF PowerUpState = 0 THEN
        IF AnimFrame = 0 THEN
            SPRITE SPR_POWERUP, HitCol + SPR_VISIBLE, HitRow, GRAM_WINGMAN_F1 * 8 + CaptureColor + $0800
        ELSE
            SPRITE SPR_POWERUP, HitCol + SPR_VISIBLE, HitRow, GRAM_WINGMAN_F2 * 8 + CaptureColor + $0800
        END IF
    END IF

    ' Rogue alien body collision with wingman (dogfight strafe only, not circle)
    IF RogueState = ROGUE_DIVE THEN
    IF RogueDivePhase = 254 THEN
        IF RogueX + 6 >= HitCol THEN
            IF HitCol + 8 >= RogueX THEN
                IF RogueY + 6 >= HitRow THEN
                    IF HitRow + 6 >= RogueY THEN
                        ' Rogue destroys wingman! Release capture
                        IF #GameFlags AND FLAG_CAPBULLET THEN
                            #ScreenPos = Row20Data(CapBulletRow) + CapBulletCol
                            IF #ScreenPos < 240 THEN PRINT AT #ScreenPos, 0
                        END IF
                        #GameFlags = #GameFlags AND $FFF3  ' Clear FLAG_CAPTURE + FLAG_CAPBULLET
                        SPRITE SPR_POWERUP, 0, 0, 0
                        SfxType = 1 : SfxVolume = 12 : #SfxPitch = 150
                        SOUND 2, 150, 12
                        RETURN
                    END IF
                END IF
            END IF
        END IF
    END IF
    END IF

    ' Fire timer — launch upward bullet
    IF CaptureTimer > 0 THEN
        CaptureTimer = CaptureTimer - 1
    ELSE
        CaptureTimer = CAPTURE_FIRE_RATE
        IF (#GameFlags AND FLAG_CAPBULLET) = 0 THEN
            ' Launch visible upward bullet from wingman position
            CapBulletCol = (HitCol - 8) / 8
            IF CapBulletCol > 19 THEN CapBulletCol = 19
            CapBulletRow = (HitRow - 8) / 8
            IF CapBulletRow > 11 THEN CapBulletRow = 11
            #GameFlags = #GameFlags OR FLAG_CAPBULLET
            ' SFX: soft pew on channel 3
            SfxType = 1 : SfxVolume = 6 : #SfxPitch = 500
            SOUND 2, 500, 6
        END IF
    END IF

    ' Update capture bullet (move up one row per frame)
    IF #GameFlags AND FLAG_CAPBULLET THEN
        ' Clear previous tile (skip row 0 = score display)
        IF CapBulletRow > 0 THEN
            #ScreenPos = Row20Data(CapBulletRow) + CapBulletCol
            IF #ScreenPos < 240 THEN
                PRINT AT #ScreenPos, 0
            END IF
        END IF

        ' Move up — stop at row 1 (don't enter score row 0)
        IF CapBulletRow <= 1 THEN
            ' Reached top of play area, deactivate
            #GameFlags = #GameFlags AND $FFF7
            GOTO CapBulletDone
        END IF
        CapBulletRow = CapBulletRow - 1

        ' Check for alien hit at new position
        GOSUB CaptureHitscan

        ' Check wingman bullet vs rogue sprite (not in grid)
        IF #GameFlags AND FLAG_CAPBULLET THEN
            IF RogueState = ROGUE_DIVE THEN
                IF RogueX >= 8 THEN
                    IF RogueY >= 8 THEN
                        IF CapBulletRow = (RogueY - 8) / 8 THEN
                            #ScreenPos = (RogueX - 8) / 8
                            IF CapBulletCol >= #ScreenPos THEN
                                IF CapBulletCol <= #ScreenPos + 1 THEN
                                    ' Wingman bullet kills rogue!
                                    RogueState = ROGUE_IDLE
                                    RogueTimer = 0 : RogueDivePhase = 0
                                    SPRITE SPR_FLYER, 0, 0, 0
                                    #ScreenPos = Row20Data(CapBulletRow) + CapBulletCol
                                    IF #ScreenPos < 240 THEN PRINT AT #ScreenPos, 0
                                    #GameFlags = #GameFlags AND $FFF7  ' Clear FLAG_CAPBULLET
                                    #Mask = 50 : GOSUB AddToScore
                                    #GameFlags = #GameFlags OR FLAG_SHOTLAND
                                    GOSUB BumpChain
                                    SfxType = 1 : SfxVolume = 14 : #SfxPitch = 180
                                    SOUND 2, 180, 14
                                END IF
                            END IF
                        END IF
                    END IF
                END IF
            END IF
        END IF

        ' Draw bullet tile if still active
        IF #GameFlags AND FLAG_CAPBULLET THEN
            #ScreenPos = Row20Data(CapBulletRow) + CapBulletCol
            IF #ScreenPos < 240 THEN
                PRINT AT #ScreenPos, GRAM_BULLET * 8 + COL_WHITE + $0800
            END IF
        END IF
    END IF
CapBulletDone:
    RETURN
END

' --------------------------------------------
' CaptureHitscan - Check if wingman bullet hit an alien at current row
' Uses CapBulletRow/CapBulletCol to check current position
' --------------------------------------------
CaptureHitscan: PROCEDURE
    ' Check if bullet is in the alien grid area
    HitCol = CapBulletCol
    IF HitCol < ALIEN_START_X + AlienOffsetX THEN RETURN
    IF HitCol >= ALIEN_START_X + AlienOffsetX + ALIEN_COLS THEN RETURN
    AlienGridCol = HitCol - ALIEN_START_X - AlienOffsetX

    ' Can't hit unrevealed columns during wave sweep-in
    IF AlienGridCol > WaveRevealCol THEN RETURN

    ' Check if this BACKTAB row corresponds to an alien grid row
    IF CapBulletRow < ALIEN_START_Y + AlienOffsetY THEN RETURN
    AlienGridRow = CapBulletRow - ALIEN_START_Y - AlienOffsetY
    IF AlienGridRow >= ALIEN_ROWS THEN RETURN

    ' Calculate bitmask for this column
    #Mask = ColMaskData(AlienGridCol)

    ' Check if alien is alive at this position
    IF (#AlienRow(AlienGridRow) AND #Mask) = 0 THEN RETURN

    ' Multi-boss intercept
    GOSUB FindBossAtCell
    IF FoundBoss < 255 THEN
        BossHP(FoundBoss) = BossHP(FoundBoss) - 1
        #GameFlags = #GameFlags AND $FFF7
        IF BossHP(FoundBoss) > 0 THEN
            ' Damaged but alive
            GOSUB UpdateBossColor
            SfxType = 1 : SfxVolume = 10 : #SfxPitch = 120
            SOUND 2, 120, 10
            RETURN
        ELSE
            ' Boss dead! Check type
            IF BossType(FoundBoss) = BOMB_TYPE THEN
                ' Bomb alien — chain explosion!
                GOSUB BombExplode
                RETURN
            ELSE
                ' Skull boss dead!
                GOSUB SkullBossDeath
                RETURN
            END IF
        END IF
    END IF

    ' Normal alien kill
    #AlienRow(AlienGridRow) = #AlienRow(AlienGridRow) XOR #Mask

    ' Clear BACKTAB tile (bullet tile will also be cleared)
    #ScreenPos = Row20Data(CapBulletRow) + HitCol
    IF #ScreenPos < 240 THEN
        PRINT AT #ScreenPos, 0
    END IF

    ' Score +10
    #Mask = 10 : GOSUB AddToScore

    ' Deactivate bullet (it hit something)
    #GameFlags = #GameFlags AND $FFF7

    ' Brief explosion visual
    IF #ScreenPos < 220 THEN
        GOSUB ClearPrevExplosion
        #ExplosionPos = #ScreenPos
        ExplosionTimer = 10
        PRINT AT #ExplosionPos, GRAM_EXPLOSION * 8 + COL_GREEN + $0800
    END IF

    ' SFX: soft zap on channel 3
    SfxType = 1 : SfxVolume = 8 : #SfxPitch = 300
    SOUND 2, 300, 8
    RETURN
END

' --------------------------------------------
' RoguePickAlien - Pick a random edge-column alien to go rogue
' --------------------------------------------
RoguePickAlien: PROCEDURE
    ' Pick left or right edge
    RogueCol = 0
    IF RANDOM(2) = 1 THEN RogueCol = ALIEN_COLS - 1

    ' Calculate bitmask for this column
    #Mask = ColMaskData(RogueCol)

    ' Count alive aliens in this column
    HitRow = 0
    FOR Row = 0 TO ALIEN_ROWS - 1
        IF #AlienRow(Row) AND #Mask THEN
            HitRow = HitRow + 1
        END IF
    NEXT Row

    ' If none found, try the other edge
    IF HitRow = 0 THEN
        IF RogueCol = 0 THEN
            RogueCol = ALIEN_COLS - 1
        ELSE
            RogueCol = 0
        END IF
        #Mask = ColMaskData(RogueCol)
        HitRow = 0
        FOR Row = 0 TO ALIEN_ROWS - 1
            IF #AlienRow(Row) AND #Mask THEN
                HitRow = HitRow + 1
            END IF
        NEXT Row
    END IF

    IF HitRow = 0 THEN RETURN  ' No edge aliens alive

    ' Pick a random alive row (sentinel pattern)
    LoopVar = RANDOM(HitRow)
    HitRow = 255
    FOR Row = 0 TO ALIEN_ROWS - 1
        IF #AlienRow(Row) AND #Mask THEN
            IF LoopVar = 0 THEN
                IF HitRow = 255 THEN HitRow = Row
            END IF
            IF LoopVar > 0 THEN LoopVar = LoopVar - 1
        END IF
    NEXT Row

    IF HitRow = 255 THEN RETURN

    RogueRow = HitRow

    ' Set alien type/color based on row (5 unique types)
    IF RogueRow = 0 THEN
        RogueCard = GRAM_ALIEN1
        RogueColor = WaveColor0
    ELSEIF RogueRow = 1 THEN
        RogueCard = GRAM_ALIEN2
        RogueColor = WaveColor1
    ELSEIF RogueRow = 2 THEN
        RogueCard = GRAM_ALIEN3
        RogueColor = WaveColor2
    ELSEIF RogueRow = 3 THEN
        RogueCard = GRAM_ALIEN4
        RogueColor = WaveColor3
    ELSE
        RogueCard = GRAM_ALIEN5
        RogueColor = WaveColor4
    END IF

    RogueState = ROGUE_SHAKE
    RogueTimer = ROGUE_SHAKE_TIME
    RETURN
END

' --------------------------------------------
' RogueUpdate - Update rogue alien (shake, dive, collision)
' --------------------------------------------
RogueUpdate: PROCEDURE
    ' --- SHAKE STATE ---
    IF RogueState = ROGUE_SHAKE THEN
        RogueTimer = RogueTimer - 1

        ' Flash alien's BACKTAB tile between normal and white
        #ScreenPos = Row20Data(ALIEN_START_Y + AlienOffsetY + RogueRow)
        #ScreenPos = #ScreenPos + ALIEN_START_X + AlienOffsetX + RogueCol
        IF #ScreenPos < 220 THEN
            IF RogueTimer AND 4 THEN
                #Card = (RogueCard + AnimFrame) * 8 + COL_WHITE + $0800
            ELSE
                #Card = (RogueCard + AnimFrame) * 8 + RogueColor + $0800
            END IF
            PRINT AT #ScreenPos, #Card
        END IF

        IF RogueTimer = 0 THEN
            ' Remove from grid (guard against double-XOR if bullet killed during shake)
            #Mask = ColMaskData(RogueCol)
            IF #AlienRow(RogueRow) AND #Mask THEN
                #AlienRow(RogueRow) = #AlienRow(RogueRow) XOR #Mask
            END IF

            ' Clear BACKTAB tile
            IF #ScreenPos < 220 THEN
                PRINT AT #ScreenPos, 0
            END IF

            ' Set up circle center (12px below alien's grid position)
            RogueCenterX = (ALIEN_START_X + AlienOffsetX + RogueCol) * 8 + 8
            RogueCenterY = (ALIEN_START_Y + AlienOffsetY + RogueRow) * 8 + 8 + 12
            ' Sprite starts at top of circle (step 24: offset +0, -12)
            RogueX = RogueCenterX
            RogueY = RogueCenterY - 12

            RogueState = ROGUE_DIVE
            RogueDivePhase = 24   ' Start at top of circle
            RogueCol = 0          ' Reuse as step counter during dive
            RogueTimer = 0
        END IF
        RETURN
    END IF

    ' --- DIVE STATE (circular spiral) ---
    IF RogueState = ROGUE_DIVE THEN

        ' Exit mode: straight down off screen
        IF RogueDivePhase = 255 THEN
            RogueY = RogueY + 2
            IF RogueY >= 112 THEN
                RogueState = ROGUE_IDLE
                RogueTimer = 0 : RogueDivePhase = 0
                SPRITE SPR_FLYER, 0, 0, 0
                RETURN
            END IF
            GOTO RogueDiveRender
        END IF

        ' Dogfight strafing: sweeping attack passes
        IF RogueDivePhase = 254 THEN
            ' If player died, escape off-screen
            IF DeathTimer > 0 THEN
                RogueDivePhase = 255
                GOTO RogueDiveRender
            END IF
            RogueTimer = RogueTimer + 1
            ' Horizontal strafe: sweep in current direction at 2px/frame
            IF RogueCenterX THEN
                ' Moving right
                RogueX = RogueX + 2
                IF RogueX >= 156 THEN
                    RogueCenterX = 0 : RogueCenterY = RogueCenterY + 1
                ELSEIF RogueX > PlayerX + 20 THEN
                    IF RogueX > 20 THEN
                        RogueCenterX = 0 : RogueCenterY = RogueCenterY + 1
                    END IF
                END IF
            ELSE
                ' Moving left
                IF RogueX >= 2 THEN
                    RogueX = RogueX - 2
                ELSE
                    RogueX = 0
                END IF
                IF RogueX <= 8 THEN
                    RogueCenterX = 1 : RogueCenterY = RogueCenterY + 1
                ELSEIF PlayerX > 20 THEN
                    IF RogueX + 20 < PlayerX THEN
                        RogueCenterX = 1 : RogueCenterY = RogueCenterY + 1
                    END IF
                END IF
            END IF
            ' Gradual descent: 1px every 3 frames
            RogueCol = RogueCol + 1
            IF RogueCol >= 3 THEN
                RogueCol = 0
                RogueY = RogueY + 1
            END IF
            ' Fire when crossing player X (within 8px), rate-limited
            IF RogueTimer >= 30 THEN
                IF RogueX + 8 >= PlayerX THEN
                    IF RogueX <= PlayerX + 8 THEN
                        GOSUB RogueFire
                    END IF
                END IF
            END IF
            ' Also fire when crossing wingman position (if present)
            IF #GameFlags AND FLAG_CAPTURE THEN
                IF RogueTimer >= 20 THEN
                    #ScreenPos = PlayerX - 4 + CaptureOrbitDX(CaptureStep) - CAPTURE_ORBIT_R
                    IF #ScreenPos < 200 THEN
                        IF RogueX + 8 >= #ScreenPos THEN
                            IF RogueX <= #ScreenPos + 8 THEN
                                GOSUB RogueFire
                            END IF
                        END IF
                    END IF
                END IF
            END IF
            ' Exit after 4 passes or past player
            IF RogueCenterY >= 4 THEN RogueDivePhase = 255
            IF RogueY >= PLAYER_Y + 10 THEN RogueDivePhase = 255
            GOTO RogueDiveRender
        END IF

        ' === Circular spiral phase ===

        ' Advance circle step every 2 frames
        RogueTimer = RogueTimer + 1
        IF (RogueTimer AND 1) = 0 THEN
            RogueDivePhase = RogueDivePhase + 1
            IF RogueDivePhase >= 32 THEN RogueDivePhase = 0
            RogueCol = RogueCol + 1
        END IF

        ' Drift center down 1px every 2 frames (spiral effect)
        IF (RogueTimer AND 1) = 0 THEN
            RogueCenterY = RogueCenterY + 1
        END IF

        ' Compute actual sprite position from center + circle offset
        RogueX = RogueCenterX + RogueCircleDX(RogueDivePhase) - 12
        RogueY = RogueCenterY + RogueCircleDY(RogueDivePhase) - 12

        ' Break from circle into dogfight after 1+ loops and near player line
        IF RogueCol >= 32 THEN
            IF RogueCenterY >= 68 THEN
                RogueDivePhase = 254
                IF RogueX < PlayerX THEN RogueCenterX = 1 ELSE RogueCenterX = 0
                RogueCenterY = 0  ' Pass counter
                RogueCol = 0     ' Descent frame counter
                RogueTimer = 0   ' Fire rate timer
            END IF
        END IF
        ' Safety: if sprite too low, go straight to chase
        IF RogueY >= 100 THEN
            IF RogueDivePhase < 32 THEN
                RogueDivePhase = 254
                IF RogueX < PlayerX THEN RogueCenterX = 1 ELSE RogueCenterX = 0
                RogueCenterY = 0
                RogueCol = 0
                RogueTimer = 0
            END IF
        END IF

        ' Fire bullet at bottom of circle (step 8, closest to player)
        IF RogueDivePhase = 8 THEN
            IF (RogueTimer AND 1) = 0 THEN
                IF (#GameFlags AND FLAG_ABULLET) = 0 THEN
                    IF FlyState <> SAUCER_CHASE THEN
                        ABulletX = RogueX + 3
                        ABulletY = RogueY + 8
                        ABulFrame = ABulFrame AND 1
                        #GameFlags = #GameFlags OR FLAG_ABULLET
                    END IF
                END IF
            END IF
        END IF

RogueDiveRender:
        ' Render rogue sprite
        SPRITE SPR_FLYER, RogueX + $0200, RogueY, (RogueCard + AnimFrame) * 8 + RogueColor + $0800

        ' Body collision with player
        IF DeathTimer = 0 THEN
            IF Invincible = 0 THEN
                IF RogueY >= PLAYER_Y - 6 THEN
                    IF RogueY <= PLAYER_Y + 6 THEN
                        IF RogueX >= PlayerX - 6 THEN
                            IF RogueX <= PlayerX + 8 THEN
                                ' Rogue body hit - check shield first
                                IF ShieldHits > 0 THEN
                                    GOSUB HitShield
                                ELSE
                                    #GameFlags = #GameFlags OR FLAG_PLAYERHIT
                                    SfxType = 3 : SfxVolume = 15 : #SfxPitch = 0
                                    SOUND 2, 0, 15
                                    POKE $1F9, 14
                                    POKE $1F8, PEEK($1F8) AND $DF
                                END IF
                                ' Either way, destroy rogue
                                RogueState = ROGUE_IDLE
                                RogueTimer = 0 : RogueDivePhase = 0
                                SPRITE SPR_FLYER, 0, 0, 0
                            END IF
                        END IF
                    END IF
                END IF
            END IF
        END IF
        RETURN
    END IF
    RETURN
END

' --------------------------------------------
' UpdateSaucer - Spawn, move, and check collision for flying saucer
' --------------------------------------------
UpdateSaucer: PROCEDURE
    ' Freeze saucer during death (keep visible, don't advance state)
    IF DeathTimer > 0 THEN
        IF FlyState > 0 THEN GOSUB SaucerAnimate
        RETURN
    END IF
    IF FlyState = 0 THEN
        ' Inactive - count up to random spawn threshold (1-4 seconds)
        #FlyPhase = #FlyPhase + 1
        IF #FlyPhase >= #FlyLoopCount THEN
            ' Spawn! Pick random direction
            #FlyPhase = 0
            IF RANDOM(2) = 0 THEN
                ' Fly left to right
                FlyState = 1
                FlyX = 0
            ELSE
                ' Fly right to left
                FlyState = 2
                FlyX = 159
            END IF
            FlyY = 8            ' Row 0 (sprites have 8px Y offset on STIC)
            FlySpeed = 0
            FlyColorTimer = 0
            FlyColor = 4        ' Dark Green
            ' Rare chance: saucer will go hostile at midpoint (1-in-8)
            IF RANDOM(8) = 0 THEN
                #GameFlags = #GameFlags OR FLAG_ANGRY
            ELSE
                #GameFlags = #GameFlags AND $FDFF
            END IF
        END IF
        RETURN
    END IF

    ' Swirl state: circular pattern before entering chase
    IF FlyState = SAUCER_SWIRL THEN
        ' If player death animation nearly done, escape (stay visible during explosion)
        IF DeathTimer > 0 THEN
            IF DeathTimer < 40 THEN
                FlyState = SAUCER_ESCAPE
                FlySpeed = 0
            END IF
            GOSUB SaucerAnimate : RETURN
        END IF

        ' Advance circle step every 2 frames
        FlySpeed = FlySpeed + 1
        IF (FlySpeed AND 1) = 0 THEN
            FlyColorTimer = FlyColorTimer + 1
            IF FlyColorTimer >= 32 THEN FlyColorTimer = 0
            #FlyLoopCount = #FlyLoopCount + 1
        END IF

        ' Drift center down 1px every 4 frames
        IF (FlySpeed AND 3) = 0 THEN
            FlyCenterY = FlyCenterY + 1
        END IF

        ' Compute sprite position from center + circle offset
        FlyX = FlyCenterX + RogueCircleDX(FlyColorTimer) - 12
        FlyY = FlyCenterY + RogueCircleDY(FlyColorTimer) - 12

        ' After 2 full loops (64 steps), transition to chase
        IF #FlyLoopCount >= 64 THEN
            FlyState = SAUCER_CHASE
            IF FlyX < PlayerX THEN FlyCenterX = 1 ELSE FlyCenterX = 0
            FlyCenterY = 0  ' Pass counter
            #FlyLoopCount = 0
            FlySpeed = 0
        END IF

        GOSUB SaucerAnimate : RETURN
    END IF

    ' Chase state: strafing attack passes (identical pattern to rogue dogfight)
    IF FlyState = SAUCER_CHASE THEN
        ' If player death animation nearly done, saucer escapes (stay visible during explosion)
        IF DeathTimer > 0 THEN
            IF DeathTimer < 40 THEN
                FlyState = SAUCER_ESCAPE
                FlySpeed = 0
            END IF
            GOSUB SaucerAnimate : RETURN
        END IF
        FlySpeed = FlySpeed + 1
        ' Horizontal strafe: sweep in current direction at 2px/frame
        IF FlyCenterX THEN
            ' Moving right
            FlyX = FlyX + 2
            IF FlyX >= 156 THEN
                FlyCenterX = 0 : FlyCenterY = FlyCenterY + 1
            ELSEIF FlyX > PlayerX + 20 THEN
                IF FlyX > 20 THEN
                    FlyCenterX = 0 : FlyCenterY = FlyCenterY + 1
                END IF
            END IF
        ELSE
            ' Moving left
            IF FlyX >= 2 THEN
                FlyX = FlyX - 2
            ELSE
                FlyX = 0
            END IF
            IF FlyX <= 8 THEN
                FlyCenterX = 1 : FlyCenterY = FlyCenterY + 1
            ELSEIF PlayerX > 20 THEN
                IF FlyX + 20 < PlayerX THEN
                    FlyCenterX = 1 : FlyCenterY = FlyCenterY + 1
                END IF
            END IF
        END IF
        ' Gradual descent: 1px every 3 frames
        #FlyLoopCount = #FlyLoopCount + 1
        IF #FlyLoopCount >= 3 THEN
            #FlyLoopCount = 0
            FlyY = FlyY + 1
        END IF
        ' Fire when crossing player X (within 8px), rate-limited
        IF FlySpeed >= 30 THEN
            IF FlyX + 8 >= PlayerX THEN
                IF FlyX <= PlayerX + 8 THEN
                    FlySpeed = 0
                    IF (#GameFlags AND FLAG_ABULLET) = 0 THEN
                        ABulletX = FlyX + 4
                        ABulletY = FlyY + 8
                        #GameFlags = #GameFlags OR FLAG_ABULLET
                    END IF
                END IF
            END IF
        END IF
        ' Body collision: saucer overlaps player
        IF FlyY >= PLAYER_Y - 8 THEN
            IF Invincible = 0 THEN
            IF FlyX >= PlayerX - 8 THEN
                IF FlyX <= PlayerX + 16 THEN
                    ' Saucer body hit - check shield first
                    IF ShieldHits > 0 THEN
                        GOSUB HitShield
                    ELSE
                        #GameFlags = #GameFlags OR FLAG_PLAYERHIT
                        SfxType = 3 : SfxVolume = 15 : #SfxPitch = 0
                        SOUND 2, 0, 15
                        POKE $1F9, 14
                        POKE $1F8, PEEK($1F8) AND $DF
                    END IF
                END IF
            END IF
            END IF
        END IF
        ' Exit after 4 passes or past player
        IF FlyCenterY >= 4 THEN
            FlyState = SAUCER_ESCAPE
            FlySpeed = 0
        END IF
        IF FlyY >= PLAYER_Y + 10 THEN
            FlyState = SAUCER_ESCAPE
            FlySpeed = 0
        END IF
        GOSUB SaucerAnimate : RETURN
    END IF

    ' Escape state: fly off diagonally (runs every frame)
    IF FlyState = SAUCER_ESCAPE THEN
        IF FlyY > 3 THEN
            FlyY = FlyY - 3
        ELSE
            FlyY = 0
        END IF
        FlyX = FlyX + 2
        IF FlyX > 167 THEN
            GOSUB DeactivateSaucer
            RETURN
        END IF
        IF FlyY = 0 THEN
            GOSUB DeactivateSaucer
            RETURN
        END IF
        GOSUB SaucerAnimate : RETURN
    END IF

    ' Normal movement (FlyState 1 or 2)
    FlySpeed = FlySpeed + 1
    IF FlySpeed >= 2 THEN
        FlySpeed = 0
        IF FlyState = 1 THEN
            FlyX = FlyX + 1
            IF FlyX > 167 THEN
                GOSUB DeactivateSaucer
                RETURN
            END IF
        ELSE
            IF FlyX > 0 THEN
                FlyX = FlyX - 1
            ELSE
                GOSUB DeactivateSaucer
                RETURN
            END IF
        END IF
        ' Normal saucer fires occasionally (slower than chase mode)
        FlyColorTimer = FlyColorTimer + 1
        IF FlyColorTimer >= 90 THEN
            FlyColorTimer = 0
            IF (#GameFlags AND FLAG_ABULLET) = 0 THEN
                ABulletX = FlyX + 4
                ABulletY = FlyY + 8
                #GameFlags = #GameFlags OR FLAG_ABULLET
            END IF
        END IF
        ' Midpoint check: angry saucer goes hostile at ~50% across screen
        IF #GameFlags AND FLAG_ANGRY THEN
            IF FlyX >= 72 THEN
                IF FlyX <= 88 THEN
                    #GameFlags = #GameFlags AND $FDFF
                    FlyState = SAUCER_SWIRL
                    FlyCenterX = FlyX
                    FlyCenterY = FlyY + 12
                    FlyColorTimer = 24  ' Start at top of circle
                    #FlyLoopCount = 0
                    FlySpeed = 0
                    FlyColor = COL_RED
                END IF
            END IF
        END IF
    END IF

    ' Normal movement ends here - call animation and return
    GOSUB SaucerAnimate
    RETURN
END

' --------------------------------------------
' SaucerAnimate - Saucer animation and bullet collision
' Extracted from UpdateSaucer for clarity
' --------------------------------------------
SaucerAnimate: PROCEDURE
    ' Animate saucer: color cycling only (single GRAM card, animation via color shift)
    ' Cards 42-44 freed for alien substep shift-2
    #FlyPhase = #FlyPhase + 1
    IF #FlyPhase >= 24 THEN #FlyPhase = 0

    ' Cycle colors (no GRAM frame switching)
    IF #FlyPhase < 12 THEN
        FlyColor = SaucerColor1(PowerUpType)     ' Primary color
    ELSE
        FlyColor = SaucerColor2(PowerUpType)     ' Secondary color
    END IF

    ' Draw saucer as 2 sprites: left half + FLIPX right half (16px wide)
    ' Handle pastel colors (8+) to avoid bit overflow into card number
    #Card = GRAM_SAUCER
    IF FlyColor >= 8 THEN
        #Card = #Card * 8 + (FlyColor AND 7) + $1800
    ELSE
        #Card = #Card * 8 + FlyColor + $0800
    END IF
    SPRITE SPR_SAUCER, FlyX + $0200, FlyY, #Card
    SPRITE SPR_SAUCER2, (FlyX + 8) + $0200, FlyY + $0400, #Card

    ' Check collision with player bullet (Y range follows saucer position)
    IF #GameFlags AND FLAG_BULLET THEN
        IF BulletY + 6 >= FlyY THEN
            IF BulletY <= FlyY + 6 THEN
                IF BulletX >= FlyX - 4 THEN
                    IF BulletX <= FlyX + 16 THEN
                        GOSUB SaucerHit
                    END IF
                END IF
            END IF
        END IF
    END IF

    ' Check collision with wingman bullet (convert BACKTAB row/col to pixels)
    IF #GameFlags AND FLAG_CAPBULLET THEN
        ' Convert wingman bullet to pixel coords: col*8+8, row*8+8
        CapPixelX = CapBulletCol * 8 + 8
        CapPixelY = CapBulletRow * 8 + 8
        IF CapPixelY + 6 >= FlyY THEN
            IF CapPixelY <= FlyY + 6 THEN
                IF CapPixelX >= FlyX - 4 THEN
                    IF CapPixelX <= FlyX + 16 THEN
                        ' Clear the wingman bullet from BACKTAB
                        #ScreenPos = Row20Data(CapBulletRow) + CapBulletCol
                        IF #ScreenPos < 240 THEN PRINT AT #ScreenPos, 0
                        #GameFlags = #GameFlags AND $FFF7  ' Deactivate wingman bullet
                        GOSUB SaucerHit
                    END IF
                END IF
            END IF
        END IF
    END IF

    RETURN
END

' --------------------------------------------
' SaucerHit - Handle saucer destruction (shared by player and wingman bullets)
' --------------------------------------------
SaucerHit: PROCEDURE
    ' Deactivate player bullet if it was the one that hit
    #GameFlags = #GameFlags AND $FFFE
    ChainCount = 0  ' Saucer is not an alien — break chain
    GOSUB DeactivateSaucer
    ' Saucer crash SFX (deep rumble + descending pitch)
    SfxType = 2 : SfxVolume = 15 : #SfxPitch = 150
    SOUND 2, 150, 15  ' Immediate tone hit on channel 3
    ' Bonus points
    #Mask = 10 : GOSUB AddToScore
    ' Drop power-up from saucer position
    PowerUpState = 1       ' Falling
    PowerUpX = FlyX        ' Drop from saucer X
    PowerUpY = FlyY      ' Start falling from saucer Y
    CapsuleFrame = 0
    ' First powerup tutorial hint (flashing)
    IF TutorialTimer = 255 THEN TutorialTimer = 180
    ' Clear previous explosion tile if still active
    GOSUB ClearPrevExplosion
    ' Show explosion at saucer position using BACKTAB
    #ExplosionPos = FlyX / 8
    ExplosionTimer = 15
    PRINT AT #ExplosionPos, GRAM_EXPLOSION * 8 + 4 + $1800
    RETURN
END

UpdateBossColor: PROCEDURE
    IF BossHP(FoundBoss) = 2 THEN BossColor(FoundBoss) = COL_YELLOW
    IF BossHP(FoundBoss) = 1 THEN BossColor(FoundBoss) = COL_RED
    RETURN
END

    ' ============================================================
