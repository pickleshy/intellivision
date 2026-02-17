' ============================================
' SPACE INTRUDERS - Game Loop Module
' ============================================
' Core 60Hz game loop orchestration
' Segment: 1 (must be inline - critical path)

    SEGMENT 1

' === Main Game Loop ===

' --------------------------------------------
' Main Game Loop
' --------------------------------------------
GameLoop:
    WAIT
    ' Debug mode: CPU profiling — red border during game logic
    IF #GameFlags AND FLAG_DEBUG THEN BORDER COL_RED

    ' Debug: press 9 on keypad to skip wave (clears all aliens)
    IF #GameFlags AND FLAG_DEBUG THEN
        IF CONT.KEY = 9 THEN
            #AlienRow(0) = 0 : #AlienRow(1) = 0
            #AlienRow(2) = 0 : #AlienRow(3) = 0
            #AlienRow(4) = 0
            RogueState = 0
            ExplosionTimer = 0
        END IF
    END IF

    ' Screen shake effect
    IF ShakeTimer > 0 THEN
        ShakeTimer = ShakeTimer - 1
        ' Alternate between offset positions for shake
        IF ShakeTimer AND 2 THEN
            SCROLL 1, 0
        ELSEIF ShakeTimer AND 1 THEN
            SCROLL 0, 1
        ELSE
            SCROLL -1, 0
        END IF
    ELSE
        SCROLL 0, 0  ' Reset to normal when done
    END IF

    ' Game Over screen with bolt sweep effect (GameOver=5: release, 6: accept)
    IF GameOver >= 5 THEN
        ' White bolt sweep across "GAME OVER" text at row 2 (pos 45)
        ' TitleMarchX = frame counter, advance bolt every 6 frames
        ' FireCooldown = bolt position (0-8 on text, 9-13 gap between sweeps)
        TitleMarchX = TitleMarchX + 1
        IF TitleMarchX >= 6 THEN
            TitleMarchX = 0
            ' Restore current bolt position to tan and clear sparks
            IF FireCooldown < 9 THEN
                #Card = PEEK($22D + FireCooldown)
                PRINT AT 45 + FireCooldown, (#Card AND $EFF8) OR COL_TAN
                PRINT AT 25 + FireCooldown, 0     ' Clear spark above (row 1)
                PRINT AT 65 + FireCooldown, 0     ' Clear spark below (row 3)
            END IF
            ' Advance bolt position
            FireCooldown = FireCooldown + 1
            IF FireCooldown >= 14 THEN FireCooldown = 0
            ' Set new bolt position to white with sparks
            IF FireCooldown < 9 THEN
                #Card = PEEK($22D + FireCooldown)
                PRINT AT 45 + FireCooldown, (#Card AND $EFF8) OR COL_WHITE
                PRINT AT 25 + FireCooldown, GRAM_SPARK_UP * 8 + $1800
                PRINT AT 65 + FireCooldown, GRAM_SPARK_DN * 8 + $1800
            END IF
        END IF
        ' Spark 2-frame animation: switch to trailing frame at frame 3
        IF FireCooldown < 9 THEN
            IF TitleMarchX >= 3 THEN
                PRINT AT 25 + FireCooldown, GRAM_SPARK_UP2 * 8 + $1800
                PRINT AT 65 + FireCooldown, GRAM_SPARK_DN2 * 8 + $1800
            END IF
        END IF

        ' "PRESS FIRE" shimmer: alternate grey/white every 4 frames (GRAM font)
        PowerUpType = PowerUpType + 1
        IF PowerUpType >= 4 THEN
            PowerUpType = 0
            WavePhase = WavePhase + 1
            IF WavePhase >= 4 THEN WavePhase = 0
            IF WaveColors(WavePhase) = 0 THEN
                ' Grey = color 8: GRAM card * 8 + $1800 (bit 12 set, low bits 0)
                PRINT AT 205, GRAM_FONT_P * 8 + $1800
                PRINT AT 206, GRAM_FONT_R * 8 + $1800
                PRINT AT 207, GRAM_FONT_E * 8 + $1800
                PRINT AT 208, GRAM_FONT_S * 8 + $1800
                PRINT AT 209, GRAM_FONT_S * 8 + $1800
                PRINT AT 211, GRAM_FONT_F * 8 + $1800
                PRINT AT 212, GRAM_FONT_I * 8 + $1800
                PRINT AT 213, GRAM_FONT_R * 8 + $1800
                PRINT AT 214, GRAM_FONT_E * 8 + $1800
            ELSE
                ' White = color 7: GRAM card * 8 + 7 + $0800
                PRINT AT 205, GRAM_FONT_P * 8 + COL_WHITE + $0800
                PRINT AT 206, GRAM_FONT_R * 8 + COL_WHITE + $0800
                PRINT AT 207, GRAM_FONT_E * 8 + COL_WHITE + $0800
                PRINT AT 208, GRAM_FONT_S * 8 + COL_WHITE + $0800
                PRINT AT 209, GRAM_FONT_S * 8 + COL_WHITE + $0800
                PRINT AT 211, GRAM_FONT_F * 8 + COL_WHITE + $0800
                PRINT AT 212, GRAM_FONT_I * 8 + COL_WHITE + $0800
                PRINT AT 213, GRAM_FONT_R * 8 + COL_WHITE + $0800
                PRINT AT 214, GRAM_FONT_E * 8 + COL_WHITE + $0800
            END IF
        END IF

        ' --- Zod diamond orbit via flight engine ---
        GOSUB FlightTick
        GOSUB ZodRender

        ' --- Game Over letter wave animation ---
        MarchCount = MarchCount + 1
        IF MarchCount >= 120 THEN
            MarchCount = 0
            IF GOAnimIdx >= 8 THEN GOAnimIdx = 0 : GOAnimFrame = 0
        END IF

        ' Zod bump: at letter row, trigger that letter
        IF FlyY >= 16 AND FlyY <= 32 THEN
            Col = (FlyX - 8) / 8
            IF Col >= 5 AND Col <= 13 THEN
                IF Col < 9 THEN GOAnimIdx = Col - 5 ELSE GOAnimIdx = Col - 6
            END IF
        END IF

        ' Animate current letter, then next
        IF GOAnimIdx < 8 THEN
            GOSUB DrawGOLetter
            GOAnimFrame = GOAnimFrame + 1
            IF GOAnimFrame > 9 THEN
                GOSUB DrawGOLetterStatic
                GOAnimIdx = GOAnimIdx + 1
                GOAnimFrame = 0
            END IF
        END IF

        ' Button debounce: GameOver=5 waits for release, GameOver=6 accepts press
        IF GameOver = 5 THEN
            IF CONT.BUTTON = 0 AND CONT.KEY = 12 THEN GameOver = 6
        END IF
        IF GameOver = 6 THEN
            IF CONT.BUTTON OR CONT.KEY = 1 THEN
                GOTO ResetToTitle
            END IF
        END IF
        IF #GameFlags AND FLAG_DEBUG THEN BORDER 0
        GOTO GameLoop
    END IF

    ' Handle player movement and firing (only if not dead)
    IF DeathTimer = 0 THEN
        GOSUB MovePlayer
    END IF

    ' Animate alien walk frames independently (every 24 frames ≈ 2.5/sec)
    NeedRedraw = 0
    ShimmerCount = ShimmerCount + 1
    IF ShimmerCount >= 24 THEN
        ShimmerCount = 0
        AnimFrame = AnimFrame XOR 1
        NeedRedraw = 1  ' Animation changed, need redraw
        SubstepState = (SubstepState AND 3) OR 4  ' DefineStep = 1, ShiftPos unchanged
    END IF

    ' DEFINE shift GRAM cards: DISABLED FOR PERFORMANCE TESTING
    ' Substep animation (smooth march) costs ~6 DEFINE calls per cycle
    ' Commenting out to test if this is the performance bottleneck
    ' Uncomment to re-enable smooth march animation
    '
    ' IF (SubstepState / 4) = 1 THEN
    '     ' Load shift-1 rows 0-2 (cards 31, 32, 37 - non-contiguous)
    '     IF AnimFrame = 0 THEN
    '         DEFINE GRAM_SHIFT1_R0, 1, Shift1F0Row0
    '         WAIT
    '         DEFINE GRAM_SHIFT1_R1, 1, Shift1F0Row1
    '         WAIT
    '         DEFINE GRAM_SHIFT1_R2, 1, Shift1F0Row2
    '     ELSE
    '         DEFINE GRAM_SHIFT1_R0, 1, Shift1F1Row0
    '         WAIT
    '         DEFINE GRAM_SHIFT1_R1, 1, Shift1F1Row1
    '         WAIT
    '         DEFINE GRAM_SHIFT1_R2, 1, Shift1F1Row2
    '     END IF
    '     SubstepState = (SubstepState AND 3) OR 8  ' DefineStep = 2
    ' ELSEIF (SubstepState / 4) = 2 THEN
    '     ' Load shift-1 rows 3-4 (cards 38, 47) + shift-2 rows 0-2 (cards 42-44)
    '     IF AnimFrame = 0 THEN
    '         DEFINE GRAM_SHIFT1_R3, 1, Shift1F0Row3       ' Card 38
    '         WAIT
    '         DEFINE GRAM_SHIFT1_R4, 1, Shift1F0Row4       ' Card 47
    '         WAIT
    '         DEFINE GRAM_SHIFT2_BASE, 3, Shift2F0Rows0_2  ' Cards 42-44
    '     ELSE
    '         DEFINE GRAM_SHIFT1_R3, 1, Shift1F1Row3       ' Card 38
    '         WAIT
    '         DEFINE GRAM_SHIFT1_R4, 1, Shift1F1Row4       ' Card 47
    '         WAIT
    '         DEFINE GRAM_SHIFT2_BASE, 3, Shift2F1Rows0_2  ' Cards 42-44
    '     END IF
    '     SubstepState = SubstepState AND 3  ' DefineStep = 0
    ' END IF

    ' Advance wave reveal
    IF WaveEntrance = 2 THEN
        ' Fly-down: entire grid descends from above screen
        ' WaveRevealRow = rows still hidden above (counts DOWN to 0)
        IF WaveRevealRow > 0 THEN
            WaveRevealRow = WaveRevealRow - 1
            NeedRedraw = 1  ' Descent continues, redraw needed
            IF WaveRevealRow = 0 THEN
                ' Descent complete, wipe ghost trails
                WaveEntrance = 0
                ' Clear rows 0 through ALIEN_ROWS-1 to remove any fly-down ghosts
                FOR ClearRow = 0 TO ALIEN_ROWS - 1
                    #ScreenPos = ClearRow * 20
                    FOR Col = 0 TO ALIEN_COLS + 1
                        PRINT AT #ScreenPos + Col, 0
                    NEXT Col
                NEXT ClearRow
                GOSUB DrawSilhouette  ' Restore row 0 silhouette after ghost wipe
            END IF
        END IF
    ELSEIF WaveEntrance = 1 THEN
        ' Top-to-bottom row reveal with warp-in animation
        IF WaveRevealRow < ALIEN_ROWS - 1 THEN
            MarchCount = MarchCount + 1
            IF MarchCount >= 3 THEN
                ' Warp complete for this row, advance to next
                MarchCount = 0
                WaveRevealRow = WaveRevealRow + 1
            END IF
            NeedRedraw = 1  ' Warp animation needs redraw every frame
        END IF
    ELSEIF (#GameFlags AND FLAG_REVEAL) = 0 THEN
        ' Standard left-to-right reveal with warp-in animation
        IF WaveRevealCol < ALIEN_COLS - 1 THEN
            MarchCount = MarchCount + 1
            IF MarchCount >= 3 THEN
                ' Warp complete for this column, advance to next
                MarchCount = 0
                WaveRevealCol = WaveRevealCol + 1
            END IF
            NeedRedraw = 1  ' Warp animation needs redraw every frame
        END IF
    ELSE
        ' Dual-slide mode (Pattern B) - halves fly in from screen edges
        ' Advance every frame (no timer) to match fly-down speed
        IF WaveRevealCol < 5 THEN WaveRevealCol = WaveRevealCol + 1
        IF RightRevealCol > 5 THEN RightRevealCol = RightRevealCol - 1
        IF WaveRevealCol >= 5 AND RightRevealCol <= 5 THEN
            ' Slide complete - switch to normal march mode
            #GameFlags = #GameFlags AND $FEFF
            WaveRevealCol = ALIEN_COLS - 1
            ' Clear alien area to remove ghost tiles
            FOR ClearRow = 0 TO ALIEN_ROWS - 1
                IF ALIEN_START_Y + AlienOffsetY + ClearRow < 11 THEN
                    #ScreenPos = (ALIEN_START_Y + AlienOffsetY + ClearRow) * 20
                    FOR Col = 0 TO 19
                        PRINT AT #ScreenPos + Col, 0
                    NEXT Col
                END IF
            NEXT ClearRow
        END IF
        NeedRedraw = 1  ' Pattern B always redraws during slide-in
    END IF

    ' March processing (3-substep: 0→1px→2px→snap to next column)
    IF WaveRevealCol >= ALIEN_COLS - 1 THEN
    IF WaveEntrance <> 2 THEN
    IF DeathTimer = 0 THEN
        MarchCount = MarchCount + 1
        IF MarchCount >= CurrentMarchSpeed THEN
            MarchCount = 0
            ' SUBSTEP DISABLED - Snap-only march for maximum performance
            ' Aliens move 8px instantly (classic march behavior)
            SubstepState = 0  ' Always snap position
            GOSUB MarchAliens
            NeedRedraw = 1
            '
            ' ORIGINAL SUBSTEP CODE (commented for performance testing):
            ' IF AlienDir = 1 THEN
            '     ' Moving right
            '     IF (SubstepState AND 3) < 2 THEN
            '         SubstepState = SubstepState + 1  ' Shift +1px or +2px
            '         NeedRedraw = 1
            '     ELSE
            '         ' Substep complete, snap to next column
            '         SubstepState = SubstepState AND 12  ' ShiftPos = 0, keep DefineStep
            '         GOSUB MarchAliens  ' Actual grid position change
            '         NeedRedraw = 1
            '     END IF
            ' ELSE
            '     ' Moving left (AlienDir = 255)
            '     IF (SubstepState AND 3) > 0 THEN
            '         SubstepState = SubstepState - 1  ' De-shift
            '         NeedRedraw = 1
            '     ELSE
            '         ' At base position, snap to previous column
            '         SubstepState = (SubstepState AND 12) OR 2  ' ShiftPos = 2
            '         GOSUB MarchAliens  ' Actual grid position change
            '         NeedRedraw = 1
            '     END IF
            ' END IF
            ' Check if aliens reached the bottom (invasion!)
            ' Find bottom-most alive row (scan from bottom up, stop at first alive)
            HitRow = 255  ' sentinel: no alive row found
            FOR Row = ALIEN_ROWS - 1 TO 0 STEP -1
                IF #AlienRow(Row) THEN
                    IF HitRow = 255 THEN HitRow = Row
                END IF
            NEXT Row
            ' Check invasion threshold (aliens reached ship baseline)
            IF HitRow < 255 THEN
              IF GameOver = 0 THEN
                IF ALIEN_START_Y + AlienOffsetY + HitRow >= 10 THEN
                    ' Invasion! Lose a life and reset formation
                    IF DeathTimer = 0 AND Invincible = 0 THEN
                        Lives = Lives - 1
                        ' Clear power-ups, bullets, rogue, wingman
                        BeamTimer = 0 : RapidTimer = 0
                        #GameFlags = #GameFlags AND ($FFFF XOR FLAG_BOMB) : MegaTimer = 0 : ShieldHits = 0
                        #GameFlags = #GameFlags AND $FFFC  ' Clear FLAG_BULLET + FLAG_ABULLET
                        RogueState = ROGUE_IDLE : RogueTimer = 0 : RogueDivePhase = 0
                        #GameFlags = #GameFlags AND $FFF3  ' Clear FLAG_CAPTURE + FLAG_CAPBULLET
                        GOSUB SilenceSfx
                        SPRITE SPR_PLAYER, 0, 0, 0
                        SPRITE SPR_SHIP_ACCENT, 0, 0, 0
                        SPRITE SPR_PBULLET, 0, 0, 0
                        SPRITE SPR_ABULLET, 0, 0, 0
                        SPRITE SPR_FLYER, 0, 0, 0
                        SPRITE SPR_POWERUP, 0, 0, 0
                        PowerUpState = 0  ' Cancel any falling/landed capsule
                        IF Lives = 0 THEN
                            ' No lives left — game over
                            GameOver = 3
                            DeathTimer = 75
                            ShakeTimer = 30
                        ELSE
                            ' INVASION! Aliens freeze in place, then reset to middle
                            ' Extra 30 frames (105-75) = freeze phase with aliens visible
                            DeathTimer = 105
                            ShakeTimer = 45  ' Longer shake for dramatic effect
                            ' Don't reset aliens yet — they freeze where they are
                            ' Clear and reset happens at DeathTimer = 75 (see below)
                        END IF
                    END IF
                END IF
              END IF
            END IF
        END IF
    END IF
    END IF
    END IF

    ' Single DrawAliens call per frame (shimmer, reveal, or march)
    IF NeedRedraw THEN GOSUB DrawAliens
    ' Orbiter draws on top of grid (after DrawAliens clears empty cells)
    IF OrbitStep < 10 OR OrbitStep2 < 10 THEN GOSUB UpdateOrbiter

    ' (Relentless wave mechanic is now handled in CheckWaveWin → ReloadHorde)

    ' Update bullets
    IF #GameFlags AND FLAG_BULLET THEN
        GOSUB MoveBullet
    END IF

    ' Alien shooting logic
    GOSUB AlienShoot

    ' Update captured wingman position (before bullet collision check)
    IF #GameFlags AND FLAG_CAPTURE THEN GOSUB UpdateCapture

    ' Update alien bullet
    IF #GameFlags AND FLAG_ABULLET THEN
        GOSUB MoveAlienBullet
    END IF

    ' Update explosion effect (BACKTAB tile with 3-frame animation)
    ' 16 frames for chain kills (1 white flash + 15 explosion), 15 otherwise
    IF ExplosionTimer > 0 THEN
        ExplosionTimer = ExplosionTimer - 1
        IF #ExplosionPos < 220 THEN
        IF ExplosionTimer = 0 THEN
            PRINT AT #ExplosionPos, 0  ' Clear
        ELSEIF ExplosionTimer > 15 THEN
            ' Chain flash: 1 frame white (frame 16 only)
            PRINT AT #ExplosionPos, GRAM_EXPLOSION * 8 + COL_WHITE + $0800
        ELSEIF ExplosionTimer > 10 THEN
            ' Frame 1: tight pop (frames 15-11) - Pink (color 12)
            PRINT AT #ExplosionPos, GRAM_EXPLOSION * 8 + 4 + $1800
        ELSEIF ExplosionTimer > 5 THEN
            ' Frame 2: expanding scatter (frames 10-6) - White
            PRINT AT #ExplosionPos, GRAM_EXPLOSION2 * 8 + COL_WHITE + $0800
        ELSE
            ' Frame 3: dissipate (frames 5-1) - White
            PRINT AT #ExplosionPos, GRAM_EXPLOSION3 * 8 + COL_WHITE + $0800
        END IF
        END IF
    END IF

    ' Chain explosion rendering (bomb alien blast radius)
    IF BombExpTimer > 0 THEN
        BombExpTimer = BombExpTimer - 1
        ' Determine explosion frame — flash red/white every frame
        IF BombExpTimer > 13 THEN
            AlienCard = GRAM_EXPLOSION
        ELSEIF BombExpTimer > 6 THEN
            AlienCard = GRAM_EXPLOSION2
        ELSE
            AlienCard = GRAM_EXPLOSION3
        END IF
        IF BombExpTimer AND 1 THEN
            AlienColor = COL_RED
        ELSE
            AlienColor = COL_WHITE
        END IF
        ' Draw explosion on all cells in blast radius (4 cols × 3 rows)
        FOR Row = BombExpRow - 1 TO BombExpRow + 1
            IF Row >= 0 THEN
            IF Row < ALIEN_ROWS THEN
                #ScreenPos = Row20Data(ALIEN_START_Y + AlienOffsetY + Row)
                FOR Col = BombExpCol - 1 TO BombExpCol + 2
                    IF Col >= 0 THEN
                    IF Col < ALIEN_COLS THEN
                        IF BombExpTimer > 0 THEN
                            PRINT AT #ScreenPos + ALIEN_START_X + AlienOffsetX + Col, AlienCard * 8 + AlienColor + $0800
                        ELSE
                            PRINT AT #ScreenPos + ALIEN_START_X + AlienOffsetX + Col, 0
                        END IF
                    END IF
                    END IF
                NEXT Col
            END IF
            END IF
        NEXT Row
    END IF

    ' Chain reaction laser SFX decay (takes priority over regular SFX)
    IF ChainTimer > 0 THEN
        ChainTimer = ChainTimer - 1
        #ChainFreq1 = #ChainFreq1 + 10
        #ChainFreq2 = #ChainFreq2 + 6
        IF (ChainTimer AND 1) = 0 THEN
            IF ChainVol > 0 THEN ChainVol = ChainVol - 1
        END IF
        POKE $1F7, 12 + (24 - ChainTimer) / 3
        SOUND 0, #ChainFreq1, ChainVol
        SOUND 2, #ChainFreq2, ChainVol
        IF ChainTimer = 0 THEN
            ' SFX done — silence and restart music
            SOUND 0, 0, 0
            SOUND 2, 0, 0
            POKE $1F8, $3F
            SfxVolume = 0 : SfxType = 0
            PLAY SIMPLE
            PLAY VOLUME 12
            ON MusicGear GOTO ChainGearMid, ChainGearFast, ChainGearPanic
            PLAY si_bg_slow
            GOTO ChainDone
ChainGearMid:
            PLAY si_bg_mid
            GOTO ChainDone
ChainGearFast:
            PLAY si_bg_fast
            GOTO ChainDone
ChainGearPanic:
            PLAY si_bg_panic
ChainDone:
        END IF
    END IF

    ' Update explosion sound effect (noise decay)
    GOSUB UpdateSfx

    ' Update flying saucer
    GOSUB UpdateSaucer

    ' Update power-up drop/pickup
    GOSUB UpdatePowerUp

    ' Update rogue alien
    IF RogueState = ROGUE_IDLE THEN
        RogueTimer = RogueTimer + 1
        IF RogueTimer >= ROGUE_COOLDOWN THEN
            RogueTimer = 0
            IF DeathTimer = 0 THEN
                IF WaveRevealCol >= ALIEN_COLS - 1 THEN
                    IF RANDOM(ROGUE_CHANCE) = 0 THEN
                        GOSUB RoguePickAlien
                    END IF
                END IF
            END IF
        END IF
    ELSE
        GOSUB RogueUpdate
    END IF

    ' Check bullet-vs-bullet collision (PARRY - tight hitbox, high reward)
    IF #GameFlags AND FLAG_BULLET THEN
        IF #GameFlags AND FLAG_ABULLET THEN
            ' Tight hitbox: X within 3 pixels, Y within 4 pixels (skill shot!)
            IF BulletX >= ABulletX - 3 THEN
                IF BulletX <= ABulletX + 3 THEN
                    IF BulletY >= ABulletY - 4 THEN
                        IF BulletY <= ABulletY + 4 THEN
                            ' PARRY! Bullets collide - destroy both
                            #GameFlags = #GameFlags AND $FFFC  ' Clear FLAG_BULLET + FLAG_ABULLET
                            #GameFlags = #GameFlags OR FLAG_SHOTLAND  ' Parry counts as a successful hit — chain preserved
                            SPRITE SPR_PBULLET, 0, 0, 0
                            SPRITE SPR_ABULLET, 0, 0, 0
                            ' Skill bonus for the risky parry
                            Points = 25 : GOSUB AddToScore
                            ' Bright zap SFX (type 6)
                            SfxType = 6 : SfxVolume = 15 : #SfxPitch = 60
                        END IF
                    END IF
                END IF
            END IF
        END IF
    END IF

    ' Check player bullet vs rogue alien
    IF #GameFlags AND FLAG_BULLET THEN
        IF RogueState = ROGUE_DIVE THEN
            IF BulletY >= RogueY - 4 THEN
                IF BulletY <= RogueY + 8 THEN
                    IF BulletX >= RogueX - 4 THEN
                        IF BulletX <= RogueX + 10 THEN
                            #GameFlags = #GameFlags AND $FFFE
                            SPRITE SPR_PBULLET, 0, 0, 0
                            RogueState = ROGUE_IDLE
                            RogueTimer = 0 : RogueDivePhase = 0
                            SPRITE SPR_FLYER, 0, 0, 0
                            Points = 50 : GOSUB AddToScore
                            #GameFlags = #GameFlags OR FLAG_SHOTLAND
                            GOSUB BumpChain
                            SfxType = 1 : SfxVolume = 14 : #SfxPitch = 180
                            SOUND 2, 180, 14
                            ' Show explosion at rogue position
                            GOSUB ClearPrevExplosion
                            #ExplosionPos = (RogueY - 8) / 8 * 20 + (RogueX - 8) / 8
                            GOSUB ShowChainExplosion
                        END IF
                    END IF
                END IF
            END IF
        END IF
    END IF

    ' Check if player was hit (only if not already dying or invincible)
    IF #GameFlags AND FLAG_PLAYERHIT THEN
        IF DeathTimer = 0 THEN
            IF Invincible = 0 THEN
                #GameFlags = #GameFlags AND $FFEF
                Lives = Lives - 1
                ' Lose all power-ups on death (mega laser too)
                BeamTimer = 0 : RapidTimer = 0
                #GameFlags = #GameFlags AND ($FFFF XOR FLAG_BOMB) : MegaTimer = 0 : ShieldHits = 0
                #GameFlags = #GameFlags AND $FFFC  ' Clear FLAG_BULLET + FLAG_ABULLET
                SPRITE SPR_PBULLET, 0, 0, 0
                ' Clear wingman and any active capsule (dies with player)
                #GameFlags = #GameFlags AND $FFF3  ' Clear FLAG_CAPTURE + FLAG_CAPBULLET
                SPRITE SPR_POWERUP, 0, 0, 0
                PowerUpState = 0  ' Cancel any falling/landed capsule
                ' Rogue: if diving, let it complete escape animation; otherwise clear it
                IF RogueState <> ROGUE_DIVE THEN
                    RogueState = 0 : RogueTimer = 0 : RogueDivePhase = 0
                    SPRITE SPR_FLYER, 0, 0, 0
                END IF
                IF Lives = 0 THEN
                    ' Pre-game-over: play death explosion, then aliens crawl
                    GameOver = 3
                    DeathTimer = 75
                    ShakeTimer = 30
                    SPRITE SPR_PLAYER, 0, 0, 0
                ELSE
                    ' Start death sequence (75 frames = 1.25 seconds)
                    DeathTimer = 75
                    ShakeTimer = 30
                    SPRITE SPR_PLAYER, 0, 0, 0
                END IF
            ELSE
                #GameFlags = #GameFlags AND $FFEF
            END IF
        ELSE
            #GameFlags = #GameFlags AND $FFEF
        END IF
    END IF

    ' Handle death timer (respawn after death)
    IF DeathTimer > 0 THEN
        DeathTimer = DeathTimer - 1
        ' Invasion reset: after 30-frame freeze, clear and reposition aliens
        IF DeathTimer = 75 THEN
            IF GameOver = 0 THEN
                ' Clear alien area
                FOR Row = 1 TO 10
                    #ScreenPos = Row * 20
                    FOR Col = 0 TO 19
                        PRINT AT #ScreenPos + Col, 0
                    NEXT Col
                NEXT Row
                ' Reset alien formation to middle of screen
                AlienOffsetY = 2  ' Rows 3-7 instead of 1-5
                LastClearedY = 0
                AlienOffsetX = 0
                AlienDir = 1
                MarchCount = 0
                ' Redraw aliens at new position
                GOSUB DrawAliens
            END IF
        END IF
        IF DeathTimer = 0 THEN
            IF GameOver = 3 THEN
                ' Explosion done — let aliens crawl for 1 more second
                DeathTimer = 60
                GameOver = 4
            ELSEIF GameOver = 4 THEN
                ' Alien crawl done — fancy Game Over screen
                #GameFlags = #GameFlags AND $FFF3  ' Clear FLAG_CAPTURE + FLAG_CAPBULLET
                GOSUB SilenceSfx
                ' Game-over music: intensity matches how far the player got
                IF Level >= 5 THEN
                    PLAY si_dnb_panic
                ELSEIF Level >= 3 THEN
                    PLAY si_dnb_fast
                ELSEIF Level >= 2 THEN
                    PLAY si_dnb_mid
                ELSE
                    PLAY si_dnb_slow
                END IF
                ShakeTimer = 0
                SCROLL 0, 0
                CLS
                GOSUB HideAllSprites
                ' Update high score (32-bit comparison and copy)
                IF #ScoreHigh > #HighScoreHigh THEN
                    #HighScore = #Score
                    #HighScoreHigh = #ScoreHigh
                ELSEIF #ScoreHigh = #HighScoreHigh THEN
                    IF #Score > #HighScore THEN
                        #HighScore = #Score
                        #HighScoreHigh = #ScoreHigh
                    END IF
                END IF
                ' Reload title font for game over screen (powerup HUD overwrote it)
                DEFINE GRAM_FONT_S, 4, FontSGfx  ' Cards 25-28: S, P, A, C
                WAIT
                DEFINE GRAM_FONT_E, 4, FontEGfx  ' Cards 29-32: E, I, N, T
                WAIT
                DEFINE GRAM_FONT_R, 4, FontRGfx  ' Cards 33-36: R, U, D, F
                WAIT
                DEFINE GRAM_FONT_G, 2, FontGGfx  ' Cards 37-38: G, M
                WAIT
                DEFINE GRAM_FONT_O, 2, FontOGfx  ' Cards 40-41: O, V
                WAIT
                DEFINE GRAM_SPARK_UP, 4, SparkUpGfx  ' Cards 21-24: restore sparks (silhouette overwrote)
                WAIT
                ' Load animated frames for A, E, R (reuse title animation GRAM slots)
                ' A frames: full, 60°, edge (cards 6-8)
                DEFINE TGRAM_A, 1, FontAY1Gfx : WAIT
                DEFINE TGRAM_A + 1, 1, FontAY3Gfx : WAIT
                DEFINE TGRAM_A + 2, 1, FontAY4Gfx : WAIT
                ' E frames: full, 60°, edge (cards 16-18)
                DEFINE TGRAM_E, 1, FontEY1Gfx : WAIT
                DEFINE TGRAM_E + 1, 1, FontEY3Gfx : WAIT
                DEFINE TGRAM_E + 2, 1, FontEY4Gfx : WAIT
                ' R frames: full, 60°, edge (cards 48-50)
                DEFINE TGRAM_R, 1, FontRY1Gfx : WAIT
                DEFINE TGRAM_R + 1, 1, FontRY3Gfx : WAIT
                DEFINE TGRAM_R + 2, 1, FontRY4Gfx : WAIT
                ' G frames: full, 60°, edge (cards 0-2)
                DEFINE TGRAM_G, 1, FontGY1Gfx : WAIT
                DEFINE TGRAM_G + 1, 1, FontGY3Gfx : WAIT
                DEFINE TGRAM_G + 2, 1, FontGY4Gfx : WAIT
                ' M frames: full, 60°, edge (cards 3-5)
                DEFINE TGRAM_M, 1, FontMY1Gfx : WAIT
                DEFINE TGRAM_M + 1, 1, FontMY3Gfx : WAIT
                DEFINE TGRAM_M + 2, 1, FontMY4Gfx : WAIT
                ' O frames: full, 60°, edge (cards 51-53)
                DEFINE TGRAM_O, 1, FontOY1Gfx : WAIT
                DEFINE TGRAM_O + 1, 1, FontOY3Gfx : WAIT
                DEFINE TGRAM_O + 2, 1, FontOY4Gfx : WAIT
                ' V frames: full, 60°, edge (cards 54-56)
                DEFINE TGRAM_V, 1, FontVY1Gfx : WAIT
                DEFINE TGRAM_V + 1, 1, FontVY3Gfx : WAIT
                DEFINE TGRAM_V + 2, 1, FontVY4Gfx : WAIT
                ' Load TinyFont labels for game over screen
                DEFINE 9, 4, GOBatch1      ' Cards 9-12: SC, OR, E:, NE
                WAIT
                DEFINE 32, 1, GOEBlankGfx  ' Card 32: E_ (no colon, for SCORE!) - moved from card 20 to avoid Zod conflict
                WAIT
                DEFINE 13, 3, GOBatch2     ' Cards 13-15: W_, HI, GH
                WAIT
                DEFINE 42, 4, GOBatch3     ' Cards 42-45: TO, P_, CH, AI
                WAIT
                DEFINE 46, 1, GOBatch4     ' Card 46: N_ (clean, no colon)
                WAIT
                ' Reload Zod crab (cards 19-20) - no longer conflicts with GOEBlankGfx (now card 32)
                DEFINE GRAM_CRAB_F1, 2, SmallCrabF1Gfx
                WAIT
                ' Chain count digit: PackedPairs → card 47 via ISR POKE
                IF ChainMax > 1 THEN
                    IF ChainMax >= 10 THEN
                        #Mask = ChainMax
                    ELSE
                        #Mask = ChainMax + 100
                    END IF
                    #Mask = #Mask + #Mask  ' *2
                    #Mask = #Mask + #Mask  ' *4
                    #Mask = VARPTR PackedPairs(0) + #Mask
                    POKE $0107, 47         ' _gram2_target = card 47
                    POKE $0108, 1          ' _gram2_total = 1 card
                    POKE $0345, #Mask      ' _gram2_bitmap = source (TRIGGER — last!)
                    WAIT
                END IF
                ' Initialize game over letter animation
                GOAnimIdx = 8 : GOAnimFrame = 0 : MarchCount = 0
                ' "GAME OVER" in custom font at row 2 col 5, centered
                PRINT AT 45, GRAM_FONT_G * 8 + COL_TAN + $0800
                PRINT AT 46, GRAM_FONT_A * 8 + COL_TAN + $0800
                PRINT AT 47, GRAM_FONT_M * 8 + COL_TAN + $0800
                PRINT AT 48, GRAM_FONT_E * 8 + COL_TAN + $0800
                PRINT AT 50, GRAM_FONT_O * 8 + COL_TAN + $0800
                PRINT AT 51, GRAM_FONT_V * 8 + COL_TAN + $0800
                PRINT AT 52, GRAM_FONT_E * 8 + COL_TAN + $0800
                PRINT AT 53, GRAM_FONT_R * 8 + COL_TAN + $0800
                ' Score at row 5: TinyFont label + packed digit cards
                FOR LoopVar = 0 TO 2
                    PRINT AT 107 + LoopVar, (9 + LoopVar) * 8 + COL_WHITE + $0800
                NEXT LoopVar
                PRINT AT 110, GRAM_SCORE_SC * 8 + COL_WHITE + $0800
                PRINT AT 111, GRAM_SCORE_OR * 8 + COL_WHITE + $0800
                PRINT AT 112, GRAM_SCORE_E * 8 + COL_WHITE + $0800
                ' High score at row 6
                IF #ScoreHigh > #HighScoreHigh OR (#ScoreHigh = #HighScoreHigh AND #Score >= #HighScore) THEN
                    ' New high: TinyFont "NEW HIGH SCORE!" (single space)
                    FOR LoopVar = 0 TO 3
                        PRINT AT 126 + LoopVar, (12 + LoopVar) * 8 + COL_YELLOW + $0800
                    NEXT LoopVar
                    PRINT AT 130, 0                              ' Blank GROM space
                    PRINT AT 131, 9 * 8 + COL_YELLOW + $0800    ' SC
                    PRINT AT 132, 10 * 8 + COL_YELLOW + $0800   ' OR
                    PRINT AT 133, 32 * 8 + COL_YELLOW + $0800   ' E_ (card 32)
                    PRINT AT 134 COLOR COL_YELLOW, "!"
                ELSE
                    ' TinyFont "HIGH" + GROM digits
                    PRINT AT 126, 14 * 8 + COL_YELLOW + $0800
                    PRINT AT 127, 15 * 8 + COL_YELLOW + $0800
                    ' TODO: Show full 32-bit high score (#HighScoreHigh + #HighScore)
                    PRINT AT 129 COLOR COL_YELLOW, <>#HighScore
                END IF
                ' Top chain at row 7 (if achieved a chain)
                IF ChainMax > 1 THEN
                    PRINT AT 147, 42 * 8 + COL_BLUE + $0800   ' TO
                    PRINT AT 148, 43 * 8 + COL_BLUE + $0800   ' P_
                    PRINT AT 149, 44 * 8 + COL_BLUE + $0800   ' CH
                    PRINT AT 150, 45 * 8 + COL_BLUE + $0800   ' AI
                    PRINT AT 151, 46 * 8 + COL_BLUE + $0800   ' N:
                    PRINT AT 152, 47 * 8 + COL_BLUE + $0800   ' digit
                END IF
                ' "PRESS FIRE" at row 10, centered using custom font
                PRINT AT 205, GRAM_FONT_P * 8 + COL_WHITE + $0800
                PRINT AT 206, GRAM_FONT_R * 8 + COL_WHITE + $0800
                PRINT AT 207, GRAM_FONT_E * 8 + COL_WHITE + $0800
                PRINT AT 208, GRAM_FONT_S * 8 + COL_WHITE + $0800
                PRINT AT 209, GRAM_FONT_S * 8 + COL_WHITE + $0800
                PRINT AT 211, GRAM_FONT_F * 8 + COL_WHITE + $0800
                PRINT AT 212, GRAM_FONT_I * 8 + COL_WHITE + $0800
                PRINT AT 213, GRAM_FONT_R * 8 + COL_WHITE + $0800
                PRINT AT 214, GRAM_FONT_E * 8 + COL_WHITE + $0800
                ' Voice announcement
                IF VOICE.AVAILABLE THEN
                    VOICE PLAY game_over_phrase
                END IF
                ' Initialize bolt sweep effect
                FireCooldown = 0   ' [game-over: bolt sweep position 0-8=text, 9-13=gap]
                TitleMarchX = 0
                WavePhase = 0
                PowerUpType = 0    ' [game-over: PRESS FIRE shimmer counter]
                ' Initialize Zod via flight engine (sweep in from right)
                FlyX = 168 : FlyY = 1
                FlyFrame = 0 : FlyColor = COL_WHITE
                FlyColorIdx = 0 : FlyColorTimer = 0
                FlyColors(0) = 7 : FlyColors(1) = 6 : FlyColors(2) = 5
                FlyColors(3) = 3 : FlyColors(4) = 5 : FlyColors(5) = 6
                LoopVar = PAT_DIAMOND
                GOSUB FlightStart
                GameOver = 5
                GOTO GameLoop
            ELSE
                ' Normal respawn at center with invincibility
                PlayerX = 80
                GOSUB ShipReveal
                Invincible = 120
            END IF
        END IF
    END IF

    ' Handle invincibility countdown
    IF Invincible > 0 THEN
        Invincible = Invincible - 1
    END IF

    ' (Explosion sound decay now handled by UpdateSfx)

    ' Check if all aliens are dead (wave win)
    GOSUB CheckWaveWin

    ' Tick down power-up timers
    ' Beam, Rapid, Bomb persist until death (no countdown)
    ' Only MegaTimer counts down (5-second window)
    IF FireCooldown > 0 THEN
        FireCooldown = FireCooldown - 1
    END IF
    IF MegaTimer > 0 THEN
        MegaTimer = MegaTimer - 1
    END IF

    ' Update powerup HUD indicator (positions 233-235, yellow TinyFont)
    ' Cards 25-27 are DEFINE'd per powerup type at pickup time
    IF BeamTimer > 0 OR RapidTimer > 0 OR (#GameFlags AND FLAG_BOMB) OR MegaTimer > 0 THEN
        PRINT AT 233, GRAM_PWR1 * 8 + COL_YELLOW + $0800
        PRINT AT 234, GRAM_PWR2 * 8 + COL_YELLOW + $0800
        IF RapidTimer > 0 THEN
            PRINT AT 235, GRAM_PWR3 * 8 + COL_YELLOW + $0800
        ELSE
            PRINT AT 235, 0
        END IF
    ELSE
        ' No powerup active - clear indicator
        PRINT AT 233, 0 : PRINT AT 234, 0 : PRINT AT 235, 0
    END IF

    ' Mega beam display countdown + sweep-up from turret + color cycling
    ' Beam follows ship movement and kills aliens it sweeps over
    IF MegaBeamTimer > 0 THEN
        MegaBeamTimer = MegaBeamTimer - 1
        ' Clear old beam column before updating position
        FOR LoopVar = 0 TO 9
            #ScreenPos = Row20Data(LoopVar) + MegaBeamCol
            PRINT AT #ScreenPos, 0
        NEXT LoopVar
        ' Track ship position: recalculate beam column each frame
        ' Sprite-to-BACKTAB offset: col = (spriteX - 8) / 8, centered on ship (+4)
        MegaBeamCol = (PlayerX - 4) / 8
        IF MegaBeamCol > 19 THEN MegaBeamCol = 19
        ' Kill aliens in new column position
        GOSUB MegaBeamKill
        ' Calculate beam top row: sweeps UP from row 9 (at ship turret)
        ' Frames elapsed = 20 - MegaBeamTimer. Sweep 2 rows/frame.
        Col = (20 - MegaBeamTimer) * 2
        IF Col > 9 THEN Col = 9
        Col = 9 - Col
        ' Color cycle: white → yellow → red
        IF MegaBeamTimer > 13 THEN
            AlienColor = COL_WHITE
        ELSEIF MegaBeamTimer > 6 THEN
            AlienColor = COL_YELLOW
        ELSE
            AlienColor = COL_RED
        END IF
        ' Draw beam from top row (Col) down to row 9 (at ship turret)
        FOR LoopVar = Col TO 9
            #ScreenPos = Row20Data(LoopVar) + MegaBeamCol
            PRINT AT #ScreenPos, GRAM_MEGA_BEAM * 8 + AlienColor + $0800
        NEXT LoopVar
        IF MegaBeamTimer = 0 THEN
            GOSUB MegaBeamClear
        END IF
    END IF

    ' Update sprites
    GOSUB DrawPlayer
    GOSUB DrawBullet
    GOSUB DrawAlienBullet

    ' Update score display — round-robin 1 GRAM card per frame via DEFINE ALTERNATE
    GOSUB UpdateScoreDisplay

    ' Extra life: first at 1000, then every 5000
    IF #Score >= #NextLife THEN
        #NextLife = #NextLife + 5000
        IF Lives < 9 THEN
            Lives = Lives + 1
            ' Announce extra life
            IF VOICE.AVAILABLE THEN
                VOICE PLAY extra_life_phrase
            END IF
        END IF
    END IF

    ' Tutorial message: "GET THE POWERUP!" (flashing, first drop only)
    ' TutorialTimer: 255=ready, 1-254=showing, 0=done
    IF TutorialTimer > 0 AND TutorialTimer < 255 THEN
        TutorialTimer = TutorialTimer - 1
        IF TutorialTimer = 0 THEN
            ' Clear message when timer expires
            PRINT AT 180, "                    "
        ELSE
            ' Flash every 4 frames (2 on, 2 off) - row 9 centered
            IF TutorialTimer AND 2 THEN
                PRINT AT 182 COLOR 6, "GET THE POWERUP!"
            ELSE
                PRINT AT 180, "                    "
            END IF
        END IF
    ELSE
        ' Chain timeout: goes cold after 1.5 sec (90 frames) without a kill
        IF ChainCount > 0 THEN
            IF ChainTimeout > 0 THEN
                ChainTimeout = ChainTimeout - 1
            ELSE
                ChainCount = 0  ' Timeout — chain goes cold
            END IF
        END IF
        ' Chain counter display: grey when inactive, blue when active
        ' Cards 58-60 are static GRAM (CH, AI, N). Digit at position 231 shows "00"-"99"
        IF ChainCount = 0 THEN
            ' Inactive: grey "CHAIN00" (TinyFont shows "00" when chain is 0)
            PRINT AT 228, GRAM_CHAIN_CH * 8 + $1800
            PRINT AT 229, GRAM_CHAIN_AI * 8 + $1800
            PRINT AT 230, GRAM_CHAIN_N * 8 + $1800
            PRINT AT 231, GRAM_CHAIN_DIG * 8 + $1800  ' "00" in grey (TinyFont)
        ELSE
            ' Active 1-99: blue "CHAIN" with digit (leading zero for 1-9)
            PRINT AT 228, GRAM_CHAIN_CH * 8 + COL_BLUE + $0800
            PRINT AT 229, GRAM_CHAIN_AI * 8 + COL_BLUE + $0800
            PRINT AT 230, GRAM_CHAIN_N * 8 + COL_BLUE + $0800
            PRINT AT 231, GRAM_CHAIN_DIG * 8 + COL_BLUE + $0800
        END IF
    END IF

    ' Parallax silhouette scroll on row 0 (every 10 frames)
    IF GameOver = 0 THEN
        StarTimer = StarTimer + 1
        IF StarTimer >= 10 THEN
            StarTimer = 0
            SilhOffset = SilhOffset + 1
            IF SilhOffset >= SILH_MAP_LEN THEN SilhOffset = 0
            GOSUB DrawSilhouette
        END IF
    END IF

    ' Debug mode: end CPU profiling — black border shows idle time
    IF #GameFlags AND FLAG_DEBUG THEN BORDER 0

    GOTO GameLoop
