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
    '        press 2 on keypad to cycle powerup weapons (bit 10 = key debounce)
    IF #GameFlags AND FLAG_DEBUG THEN
        IF CONT.KEY = 9 THEN
            #AlienRow(0) = 0 : #AlienRow(1) = 0
            #AlienRow(2) = 0 : #AlienRow(3) = 0
            #AlienRow(4) = 0
            RogueState = 0
            ExplosionTimer = 0
        END IF
        IF CONT.KEY = 2 THEN
            IF (#GameFlags AND $0400) = 0 THEN GOSUB DebugCycleWeapon
        ELSE
            #GameFlags = #GameFlags AND ($FFFF XOR $0400)
        END IF
    END IF

    ' Screen shake effect
    IF ShakeTimer > 0 THEN
        ShakeTimer = ShakeTimer - 1
        ' Alternate between offset positions for shake
        GOSUB DoScreenShake
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
        GOSUB ShimmerPressFire

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
            IF cont1.b0 = 0 AND CONT.KEY = 12 THEN GameOver = 6
        END IF
        IF GameOver = 6 THEN
            IF cont1.b0 OR CONT.KEY = 1 THEN
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

    ' Animate alien walk frames independently (every 24 frames ≈ 2.5/sec, 3-frame cycle)
    ' NOTE: NeedRedraw is NOT reset here — it's reset after DrawAliens (line below) so
    ' kills that happen AFTER DrawAliens (MoveBullet, MegaBeam, etc.) carry forward to
    ' the next frame and ensure the dead tile is cleared promptly.
    ShimmerCount = ShimmerCount + 1
    IF ShimmerCount >= 24 THEN
        ShimmerCount = 0
        AnimFrame = AnimFrame + 1
        IF AnimFrame > 2 THEN AnimFrame = 0
        NeedRedraw = 1
    END IF

    ' DEFINE-swap: pre-load card BASE bitmaps 3 frames before AnimFrame changes.
    ' ShimmerCount 21/22/23 fire while the CURRENT frame is still displaying — GRAM is
    ' fully loaded by the time the tick fires at 24 and AnimFrame changes.
    ' AnimFrame=1 → about to enter F2: load F2 bitmaps.
    ' AnimFrame=2 → about to re-enter F0: restore F0 bitmaps.
    ' ShimmerCount doubles as the step counter — no extra variable needed.
    IF ShimmerCount = 21 THEN
        IF AnimFrame = 1 THEN
            DEFINE GRAM_ALIEN1, 1, Alien1F2Gfx   ' Squid F2 → card 2
            DEFINE GRAM_ALIEN2, 1, Alien2F2Gfx   ' Crab F2 → card 4
        ELSEIF AnimFrame = 2 THEN
            DEFINE GRAM_ALIEN1, 1, Alien1Gfx     ' Squid F0 restored → card 2
            DEFINE GRAM_ALIEN2, 1, Alien2Gfx     ' Crab F0 restored → card 4
        END IF
    ELSEIF ShimmerCount = 22 THEN
        IF AnimFrame = 1 THEN
            DEFINE GRAM_ALIEN3, 1, Alien3F2Gfx   ' Octopus F2 → card 6
            DEFINE GRAM_ALIEN4, 1, Alien4F2Gfx   ' Beetle F2 → card 19
        ELSEIF AnimFrame = 2 THEN
            DEFINE GRAM_ALIEN3, 1, Alien3Gfx     ' Octopus F0 restored → card 6
            DEFINE GRAM_ALIEN4, 1, Alien4Gfx     ' Beetle F0 restored → card 19
        END IF
    ELSEIF ShimmerCount = 23 THEN
        IF AnimFrame = 1 THEN
            DEFINE GRAM_ALIEN5, 1, Alien5F2Gfx   ' Jellyfish F2 → card 30
        ELSEIF AnimFrame = 2 THEN
            DEFINE GRAM_ALIEN5, 1, Alien5Gfx     ' Jellyfish F0 restored → card 30
        END IF
    END IF

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
                        Lives = Lives - 1  ' audit-ignore: DeathTimer prevents re-entry; game-over triggers when Lives=0
                        ' Clear power-ups, bullets, rogue, wingman
                        BeamTimer = 0 : RapidTimer = 0
                        #GameFlags = #GameFlags AND ($FFFF XOR FLAG_BOMB) : Sol36Timer = 0 : ShieldHits = 0
                        GOSUB Sol36SputterStop
                        #GameFlags = #GameFlags AND $FFFC  ' Clear FLAG_BULLET + FLAG_ABULLET
                        RogueState = ROGUE_IDLE : RogueTimer = 0 : RogueDivePhase = 0
                        #GameFlags = #GameFlags AND $FFF3  ' Clear FLAG_CAPTURE + FLAG_CAPBULLET
                        GOSUB SilenceSfx
                        ' Invasion death explosion (aliens crushed the ship)
                        SfxType = 3 : SfxVolume = 15 : #SfxPitch = 0
                        SOUND 2, 0, 15
                        POKE $1F9, 14
                        POKE $1F8, PEEK($1F8) AND $DF
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
    IF NeedRedraw THEN GOSUB DrawAliens : NeedRedraw = 0
    ' Orbiter draws on top of grid (after DrawAliens clears empty cells)
    IF OrbitStep < 10 OR OrbitStep2 < 10 OR OrbiterDeathTimer > 0 THEN GOSUB UpdateOrbiter

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
            ' Frames 5-1: card 16 (GRAM_EXPLOSION3) time-shares with GRAM_SKELETON — just clear
            PRINT AT #ExplosionPos, 0
        END IF
        END IF
    END IF

    ' Chain explosion rendering (bomb alien blast radius)
    IF BombExpTimer > 0 THEN
        BombExpTimer = BombExpTimer - 1
        ' Determine explosion frame — flash red/white every frame
        IF BombExpTimer > 20 THEN
            AlienCard = GRAM_EXPLOSION
        ELSEIF BombExpTimer > 9 THEN
            AlienCard = GRAM_EXPLOSION2
        ELSE
            ' Card 16 (GRAM_EXPLOSION3) time-shares with GRAM_SKELETON — hold scatter frame instead
            AlienCard = GRAM_EXPLOSION2
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

    ' Wave announcement overlay (banner displays DURING alien entrance animation)
    ' DrawWaveBanner / ClearWaveBanner / SpinWaveBannerLetter in Seg 2 (cross-seg GOSUB OK)
    IF WaveAnnouncerTimer > 0 THEN
        WaveAnnouncerTimer = WaveAnnouncerTimer - 1
        IF WaveAnnouncerTimer > 20 THEN
            ' Static display phase: show banner text
            GOSUB DrawWaveBanner
        ELSEIF WaveAnnouncerType = 1 THEN
            ' Spin-out phase (type 1 = WAVE X only): animate letters one by one
            IF WaveAnnouncerTimer > 0 THEN
                GOSUB SpinWaveBannerLetter
                WaveBannerFrame = WaveBannerFrame + 1
                IF WaveBannerFrame >= 4 THEN
                    WaveBannerFrame = 0
                    WaveBannerPhase = WaveBannerPhase + 1
                END IF
            ELSE
                ' Timer expired: clear remaining text and restore card 47 for orbiter
                PRINT AT 127, "       "
                DEFINE GRAM_ORBITER, 1, SmallCrabF1Gfx
            END IF
        ELSE
            ' Types 2/3 (ALERT! / INCOMING HORDE!): flash effect during exit window
            IF WaveAnnouncerTimer AND 4 THEN
                GOSUB DrawWaveBanner
            ELSE
                GOSUB ClearWaveBanner
            END IF
        END IF
    END IF

    ' Chain reaction laser SFX decay (takes priority over regular SFX)
    IF ChainTimer > 0 THEN
        ChainTimer = ChainTimer - 1
        #ChainFreq1 = #ChainFreq1 + 10
        #ChainFreq2 = #ChainFreq2 + 6
        IF (ChainTimer AND 1) = 0 THEN
            IF ChainVol > 0 THEN ChainVol = ChainVol - 1
        END IF
        POKE $1F9, ChainNoiseFreq(ChainTimer)   ' Replaces /3 division (was 0-7 iters/frame)
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
            ON MusicGear GOTO ChainGearFast, ChainGearPanic
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
                            #Mask = 25 : GOSUB AddToScore
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
                            GOSUB DestroyRogue
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
                Lives = Lives - 1  ' audit-ignore: DeathTimer=0 AND Invincible=0 gate; game-over triggers when Lives=0
                ' Lose all power-ups on death (mega laser too)
                BeamTimer = 0 : RapidTimer = 0
                #GameFlags = #GameFlags AND ($FFFF XOR FLAG_BOMB) : Sol36Timer = 0 : Sol36BeamTimer = 0 : ShieldHits = 0
                GOSUB Sol36SputterStop
                #GameFlags = #GameFlags AND $FFFC  ' Clear FLAG_BULLET + FLAG_ABULLET
                SPRITE SPR_PBULLET, 0, 0, 0
                SPRITE SPR_SHIP_ACCENT, 0, 0, 0
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
                ' Check and update high score; ShakeTimer reused as IsNewHigh flag
                ' (ShakeTimer was just set to 0 above, and isn't used during the game over screen)
                ' IMPORTANT: flag must be set BEFORE updating #HighScore, so the comparison
                ' is against the previous best (not the just-updated value).
                '
                ' BUG WORKAROUND: IntyBASIC UNSIGNED `>` compiles BEQ $+4 which falls INTO
                ' the then-body on equal case, making `>` behave as `>=`. Guard every `>`
                ' with an explicit `<>` check so the equal case never reaches the inner IF.
                IF #ScoreHigh <> #HighScoreHigh THEN
                    IF #ScoreHigh > #HighScoreHigh THEN
                        ShakeTimer = 1
                        #HighScore = #Score
                        #HighScoreHigh = #ScoreHigh
                    END IF
                ELSEIF #Score <> #HighScore THEN
                    IF #Score > #HighScore THEN
                        ShakeTimer = 1
                        #HighScore = #Score
                        #HighScoreHigh = #ScoreHigh
                    END IF
                END IF
                ' Reload title font for game over screen (powerup HUD overwrote it)
                DEFINE GRAM_FONT_S, 4, FontSGfx  ' Cards 25-28: S, P, A, C
                WAIT
                DEFINE GRAM_FONT_E, 3, FontEGfx  ' Cards 29-31: E, I, N  (skip card 32 = GRAM_SCORE_M digit; GRAM_FONT_T never used in game over)
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
                DEFINE 57, 1, GOEBlankGfx  ' Card 57 (GRAM_BOMB2_F1): E_ (no colon, for SCORE!) — free during game over and title screen
                WAIT
                DEFINE 13, 3, GOBatch2     ' Cards 13-15: W_, HI, GH
                WAIT
                DEFINE 42, 4, GOBatch3     ' Cards 42-45: TO, P_, CH, AI
                WAIT
                DEFINE 46, 1, GOBatch4     ' Card 46: N_ (clean, no colon)
                WAIT
                ' Reload Zod crab (cards 19-20)
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
                ' Score at row 5: GROM "SCORE: " (cols 3-9) + 7 GROM digits (cols 10-16)
                PRINT AT 103 COLOR COL_WHITE, "SCORE: "
                ' Decompose score into 7 individual GROM digits — same math as UpdateScoreDisplay
                #Mask = #Score / 1000
                HitRow = #Mask                        ' 8-bit save, max 65
                #Mask = #Score - #Mask * 1000         ' low mod-1000 (0-999)
                IF #ScoreHigh > 0 THEN
                    #Mask = #Mask + #ScoreHigh * 536
                    Col = #Mask / 1000
                    #Mask = #Mask - Col * 1000
                    #ScreenPos = HitRow + #ScoreHigh * 65 + Col
                ELSE
                    #ScreenPos = HitRow               ' total/1000 (0-65 for sub-65K scores)
                END IF
                ' #ScreenPos = D6D5D4D3 (total/1000, 0-9999), #Mask = D2D1D0 (total mod 1000, 0-999)
                ShootTimer = 110 : ABulFrame = COL_WHITE
                GOSUB PrintScore7Grom  ' prints cols 10-16 (positions 110-116)
                ' High score at row 6
                IF ShakeTimer THEN  ' ShakeTimer=1 means new high score was set above
                    ' New high: TinyFont "NEW HIGH SCORE" (all TinyFont, 7 cards at pos 126-132)
                    ' Cards 12-15 = NE,W_,HI,GH  Cards 9,10,57 = SC,OR,E_
                    FOR LoopVar = 0 TO 3
                        PRINT AT 126 + LoopVar, (12 + LoopVar) * 8 + COL_YELLOW + $0800
                    NEXT LoopVar
                    PRINT AT 130,  9 * 8 + COL_YELLOW + $0800   ' SC
                    PRINT AT 131, 10 * 8 + COL_YELLOW + $0800   ' OR
                    PRINT AT 132, 57 * 8 + COL_YELLOW + $0800   ' E_
                ELSE
                    ' GROM "HIGH: " label + 7-digit score (mirrors "SCORE: " label on row above)
                    PRINT AT 123 COLOR COL_YELLOW, "HIGH: "
                    ' 7-digit 32-bit high score as GROM chars at positions 129-135
                    ' Same 32-bit decomposition as UpdateScoreDisplay (safe for H <= 122)
                    #Mask = #HighScore / 1000            ' L_th (0-65)
                    HitRow = #Mask                       ' 8-bit save (max 65)
                    #Mask = #HighScore - #Mask * 1000    ' L_mod1000 (0-999)
                    IF #HighScoreHigh > 0 THEN
                        #Mask = #Mask + #HighScoreHigh * 536
                        Col = #Mask / 1000               ' carry (0-5)
                        #Mask = #Mask - Col * 1000       ' total_mod1000 (0-999)
                        #ScreenPos = HitRow + #HighScoreHigh * 65 + Col  ' total/1000 (0-9999)
                    ELSE
                        #ScreenPos = HitRow
                    END IF
                    ' D6D5D4D3 from #ScreenPos (total/1000), D2D1D0 from #Mask (total mod 1000)
                    ShootTimer = 129 : ABulFrame = COL_YELLOW
                    GOSUB PrintScore7Grom  ' prints cols 9-15 (positions 129-135)
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
                GOSUB DrawPressFire_White
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
    ' Only Sol36Timer counts down (5-second window)
    IF FireCooldown > 0 THEN
        FireCooldown = FireCooldown - 1
    END IF
    IF CapBtnTimer > 0 THEN
        CapBtnTimer = CapBtnTimer - 1
    END IF
    IF Sol36Timer > 0 THEN
        Sol36Timer = Sol36Timer - 1
        IF Sol36Timer = 0 AND Sol36SputterTimer = 0 THEN
            ' SOL-36 expired — enter sputter phase (thin beam flicker + 2 final spurts)
            Sol36BeamTimer = 0
            DEFINE GRAM_SOL36, 1, SolSputterGfx
            Sol36SputterTimer = 95
        END IF
    END IF

    ' Update powerup HUD indicator (positions 233-235, yellow TinyFont)
    ' Cards 25-27 are DEFINE'd per powerup type at pickup time
    IF BeamTimer > 0 OR RapidTimer > 0 OR (#GameFlags AND FLAG_BOMB) OR Sol36Timer > 0 THEN
        PRINT AT 233, GRAM_PWR1 * 8 + COL_YELLOW + $0800
        PRINT AT 234, GRAM_PWR2 * 8 + COL_YELLOW + $0800
        IF RapidTimer > 0 OR Sol36Timer > 0 THEN
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
    IF Sol36BeamTimer > 0 THEN
        Sol36BeamTimer = Sol36BeamTimer - 1
        ' Clear old beam column before updating position
        FOR LoopVar = 0 TO 9
            #ScreenPos = Row20Data(LoopVar) + Sol36Col
            PRINT AT #ScreenPos, 0
        NEXT LoopVar
        ' Track ship position: recalculate beam column each frame
        ' Sprite-to-BACKTAB offset: col = (spriteX - 8) / 8, centered on ship (+4)
        Sol36Col = (PlayerX - 4) / 8
        IF Sol36Col > 19 THEN Sol36Col = 19
        ' Clear new column entirely (DrawAliens may have drawn alien cards there above the sweep top)
        FOR LoopVar = 0 TO 9
            #ScreenPos = Row20Data(LoopVar) + Sol36Col
            PRINT AT #ScreenPos, 0
        NEXT LoopVar
        ' Kill aliens in new column position
        GOSUB Sol36Kill
        ' Calculate beam top row: sweeps UP from row 9 (at ship turret)
        ' Frames elapsed = 20 - Sol36BeamTimer. Sweep 2 rows/frame.
        Col = (20 - Sol36BeamTimer) * 2
        IF Col > 9 THEN Col = 9
        Col = 9 - Col
        ' Color cycle: white → yellow → red
        IF Sol36BeamTimer > 13 THEN
            AlienColor = COL_WHITE
        ELSEIF Sol36BeamTimer > 6 THEN
            AlienColor = COL_YELLOW
        ELSE
            AlienColor = COL_RED
        END IF
        ' Draw beam from top row (Col) down to row 9 (at ship turret)
        FOR LoopVar = Col TO 9
            #ScreenPos = Row20Data(LoopVar) + Sol36Col
            PRINT AT #ScreenPos, GRAM_SOL36 * 8 + AlienColor + $0800
        NEXT LoopVar
        ' Skeleton animation: 2-frame pose swap driven by SkeletonTimer bits
        ' Bit 0 (AND 1): on/off flicker — show skeleton on ODD frames only
        ' Bit 1 (AND 2): pose select — frame A on set, frame B on clear
        ' Countdown is in outer block below; this only draws using pre-decrement value.
        IF SkeletonTimer > 0 THEN
            IF SkeletonTimer AND 1 THEN
                ' Select and load the pose for this frame (DEFINE fires before WAIT → card 16 ready)
                IF SkeletonTimer AND 2 THEN
                    DEFINE GRAM_SKELETON, 1, IntruderSkeletonGfx   ' Pose A
                ELSE
                    DEFINE GRAM_SKELETON, 1, IntruderSkeletonGfx2  ' Pose B
                END IF
                FOR LoopVar = 0 TO ALIEN_ROWS - 1
                    IF SkeletonPos AND ColMaskData(LoopVar) THEN
                        #ScreenPos = Row20Data(ALIEN_START_Y + AlienOffsetY + LoopVar) + Sol36Col
                        PRINT AT #ScreenPos, GRAM_SKELETON * 8 + COL_WHITE + $0800
                    END IF
                    IF SkeletonRowsB AND ColMaskData(LoopVar) THEN
                        #ScreenPos = Row20Data(ALIEN_START_Y + AlienOffsetY + LoopVar) + Sol36Col + 1
                        PRINT AT #ScreenPos, GRAM_SKELETON * 8 + COL_WHITE + $0800
                    END IF
                NEXT LoopVar
            END IF
        END IF
        IF Sol36BeamTimer = 0 THEN
            GOSUB Sol36Clear
        END IF
    END IF

    ' SOL-36 sputter phase: thin beam flicker + 2 final kill spurts
    IF Sol36SputterTimer > 0 THEN
        GOSUB Sol36SputterUpdate
    END IF

    ' SkeletonTimer countdown (outside beam block so it runs even after Sol36Timer expires and
    ' Sol36BeamTimer is force-killed to 0 at line 855, bypassing the beam block).
    ' Sol36Clear handles the end-of-beam case (force-clears to 0 + fires restore DEFINE directly).
    ' This block handles the Sol36Timer-expiry case where SkeletonTimer is left stranded > 0.
    IF SkeletonTimer > 0 THEN
        SkeletonTimer = SkeletonTimer - 1
        IF SkeletonTimer = 0 THEN
            DEFINE GRAM_SKELETON, 1, ExplosionGfx3  ' Restore card 16 to GRAM_EXPLOSION3
            SkeletonPos = 0 : SkeletonRowsB = 0
        END IF
    END IF

    ' Update sprites
    GOSUB DrawPlayer
    GOSUB DrawBullet
    GOSUB DrawAlienBullet

    ' Update score display — round-robin 1 GRAM card per frame via DEFINE ALTERNATE
    ' Skip during WAVE X spin-out: card 32 (GRAM_SCORE_M) is repurposed for spin frames
    IF WaveAnnouncerType = 1 AND WaveAnnouncerTimer > 0 AND WaveAnnouncerTimer <= 20 THEN
        GOTO SkipScoreUpdate
    END IF
    GOSUB UpdateScoreDisplay
SkipScoreUpdate:

    ' Extra life: first at 1000, then every 5000
    ' Guard: #NextLife is 16-bit; after 13th extra life (score ~61000), adding 5000
    ' wraps to a small value, firing every frame. Detect overflow like AddToScore carry.
    IF #Score >= #NextLife THEN
        #NextLife = #NextLife + 5000
        IF #NextLife < 5000 THEN  ' Overflow: wrapped to small value — push to 65535
            #NextLife = 65535
        END IF
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

    ' Auto-fire status flash: row 10 center (positions 206-213), 1 second, fast blink
    ' AND 2 = toggle every 2 frames (15 Hz); green = ON, yellow = OFF, black = blink-off or expired
    IF AutoFireFlash > 0 THEN
        AutoFireFlash = AutoFireFlash - 1
        IF AutoFireFlash = 0 THEN
            PRINT AT 206 COLOR COL_BLACK, "        "   ' Expired — clear row 10 flash area
        ELSEIF (AutoFireFlash AND 2) THEN
            IF #GameFlags AND FLAG_AUTOFIRE THEN
                PRINT AT 206 COLOR COL_GREEN, "AUTO  ON"
            ELSE
                PRINT AT 206 COLOR COL_YELLOW, "AUTO OFF"
            END IF
        ELSE
            PRINT AT 206 COLOR COL_BLACK, "        "   ' Blink-off phase
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
