' ============================================
' SPACE INTRUDERS - Wave Management Module
' ============================================
' Wave transitions, pattern loading, alien spawning
' Segment: 2

    SEGMENT 2

' === Wave Management ===

' --------------------------------------------
' ClearBulletsAndBeam - Clear bullet flags, capbullet tile, and beam timer
' Called from LoadPatternB and ReloadHorde during wave transitions
' --------------------------------------------
ClearBulletsAndBeam: PROCEDURE
    #GameFlags = #GameFlags AND $FFFC  ' Clear FLAG_BULLET + FLAG_ABULLET
    IF #GameFlags AND FLAG_CAPBULLET THEN
        #ScreenPos = Row20Data(CapBulletRow) + CapBulletCol
        IF #ScreenPos < 240 THEN PRINT AT #ScreenPos, 0
        #GameFlags = #GameFlags AND $FFF7  ' Clear FLAG_CAPBULLET
    END IF
    Sol36BeamTimer = 0
    RETURN
END

' --------------------------------------------
' ClearWaveObjects - Hide enemy sprites and reset flight state for wave transitions
' Called from LoadPatternB and StartNewWave
' --------------------------------------------
ClearWaveObjects: PROCEDURE
    GOSUB ClearRogueOnly
    SPRITE SPR_PBULLET, 0, 0, 0
    SPRITE SPR_ABULLET, 0, 0, 0
    SPRITE SPR_SAUCER, 0, 0, 0
    SPRITE SPR_SAUCER2, 0, 0, 0
    FlyState = 0
    #FlyPhase = 0
    PowerUpState = 0
    IF (#GameFlags AND FLAG_CAPTURE) = 0 THEN SPRITE SPR_POWERUP, 0, 0, 0
    RETURN
END

SetEntrancePattern: PROCEDURE
    ' Reset entrance mode (0=left sweep, 1=top-down, 2=fly-down)
    WaveEntrance = 0
    WaveRevealCol = 0
    WaveRevealRow = 0
    HitRow = WaveEntranceData(LoopVar)
    IF HitRow = 1 THEN
        ' Top-down reveal: rows appear in place one at a time
        WaveEntrance = 1
        WaveRevealCol = ALIEN_COLS - 1
        ' WaveRevealRow counts UP (0 to ALIEN_ROWS-1) for rows revealed
    ELSEIF HitRow = 2 THEN
        ' Fly-down: entire grid descends from above screen
        WaveEntrance = 2
        WaveRevealCol = ALIEN_COLS - 1
        WaveRevealRow = 6  ' Rows hidden above (counts DOWN to 0)
    END IF
    RETURN
END

' --- ShipReveal: Animate ship rising from behind HUD ---
ShipReveal: PROCEDURE
    ' BEHIND ($2000) makes HUD tiles occlude the ship as it rises
    FOR LoopVar = 100 TO PLAYER_Y STEP -1
        SPRITE SPR_PLAYER, PlayerX + $2200, LoopVar + $0100, GRAM_SHIP * 8 + COL_WHITE + $0800
        SPRITE SPR_SHIP_ACCENT, PlayerX + $2200, LoopVar + $0100, GRAM_SHIP_ACCENT * 8 + $1800
        WAIT
    NEXT LoopVar
    RETURN
END

' --- DrawGOLetterStatic: Restore letter to static GRAM font ---
DrawGOLetterStatic: PROCEDURE
    ' Get BACKTAB position for this letter
    LoopVar = GOLetterPos(GOAnimIdx)

    ' Get static GRAM card for this letter
    Row = GOLetterStaticGram(GOAnimIdx)

    ' Draw the letter with static font
    #Card = Row * 8 + COL_TAN + $0800
    PRINT AT LoopVar, #Card
    RETURN
END

' --------------------------------------------
' HandleDescent - Shared descent logic (called from MarchAliens)
' Accelerates march speed, updates music gear
' Caller must set AlienDir before calling
' --------------------------------------------
HandleDescent: PROCEDURE
    AlienOffsetY = AlienOffsetY + 1
    IF CurrentMarchSpeed > MARCH_SPEED_MIN THEN
        CurrentMarchSpeed = CurrentMarchSpeed - 6
        IF CurrentMarchSpeed < MARCH_SPEED_MIN THEN CurrentMarchSpeed = MARCH_SPEED_MIN
    END IF
    GOSUB UpdateMusicGear
    RETURN
END

' --------------------------------------------
' MarchAliens - Move alien grid (dynamic boundaries)
' --------------------------------------------
MarchAliens: PROCEDURE
    ' Find leftmost and rightmost alive columns via OR-chain (~300 cyc vs ~1500)
    ' Combine all rows into single column-presence mask
    #Mask = #AlienRow(0) OR #AlienRow(1) OR #AlienRow(2) OR #AlienRow(3) OR #AlienRow(4)
    HitRow = ALIEN_COLS - 1       ' LeftmostCol: first match in 0→8 scan
    LoopVar = 0                   ' RightmostCol: last match in 0→8 scan
    FOR Col = 0 TO ALIEN_COLS - 1
        IF #Mask AND ColMaskData(Col) THEN
            IF HitRow = ALIEN_COLS - 1 THEN HitRow = Col  ' First match = leftmost
            LoopVar = Col  ' Always update = last match is rightmost
        END IF
    NEXT Col

    ' HitRow = leftmost alive col, LoopVar = rightmost alive col
    ' Right boundary: ALIEN_START_X + AlienOffsetX + LoopVar must stay <= 19
    ' Left boundary: ALIEN_START_X + AlienOffsetX + HitRow must stay >= 0

    ' Runtime grid normalization: when leftmost alive column > 0,
    ' dead left columns limit the left march range (AlienOffsetX is
    ' unsigned and can't go below 0). Shift bitmasks right and increase
    ' offset to reclaim that space. This keeps march range symmetric.
    ' Guard: HitRow <= LoopVar ensures aliens exist (empty grid → HitRow=8, LoopVar=0)
    IF HitRow > 0 AND HitRow <= LoopVar THEN
        ' Clear the abandoned left columns on screen
        FOR Col = 0 TO HitRow - 1
            FOR Row = 0 TO ALIEN_ROWS - 1
                IF ALIEN_START_Y + AlienOffsetY + Row < 11 THEN
                    #ScreenPos = Row20Data(ALIEN_START_Y + AlienOffsetY + Row)
                    PRINT AT #ScreenPos + ALIEN_START_X + AlienOffsetX + Col, 0
                END IF
            NEXT Row
        NEXT Col
        ' Shift bitmasks so leftmost alive becomes column 0
        FOR Row = 0 TO ALIEN_ROWS - 1
            #AlienRow(Row) = #AlienRow(Row) / ColMaskData(HitRow)
        NEXT Row
        AlienOffsetX = AlienOffsetX + HitRow
        ' Save rightmost col before boss loop overwrites LoopVar
        Col = LoopVar - HitRow
        ' Adjust boss grid positions (guard BossCount=0 to avoid unsigned underflow)
        IF BossCount > 0 THEN
            FOR LoopVar = 0 TO BossCount - 1
                IF BossHP(LoopVar) > 0 THEN
                    BossCol(LoopVar) = BossCol(LoopVar) - HitRow
                END IF
            NEXT LoopVar
        END IF
        ' Restore rightmost col for boundary check below
        LoopVar = Col
        HitRow = 0
    END IF

    IF AlienDir = 1 THEN
        ' Moving right
        IF ALIEN_START_X + AlienOffsetX + LoopVar < 19 THEN
            ' Trail clearing handled by DrawAliens edge-clear (called after MarchAliens)
            AlienOffsetX = AlienOffsetX + 1
        ELSE
            ' Hit right edge - drop down and reverse
            AlienDir = 255
            GOSUB HandleDescent
        END IF
    ELSE
        ' Moving left
        ' Guard: AlienOffsetX is unsigned 8-bit, can't go below 0
        IF AlienOffsetX > 0 THEN
            IF AlienOffsetX + HitRow > 0 THEN
                ' Trail clearing handled by DrawAliens edge-clear (called after MarchAliens)
                AlienOffsetX = AlienOffsetX - 1  ' audit-ignore: guarded by IF AlienOffsetX > 0 THEN two lines above
            ELSE
                ' Hit left edge - drop down and reverse
                AlienDir = 1
                GOSUB HandleDescent
            END IF
        ELSE
            ' AlienOffsetX = 0: reverse (can't represent negative offset)
            AlienDir = 1
            GOSUB HandleDescent
        END IF
    END IF
    RETURN
END

' --------------------------------------------
' UpdateMusicGear - Switch music tempo based on alien descent
' Called after each AlienOffsetY increment
' --------------------------------------------
UpdateMusicGear: PROCEDURE
    ' Calculate target gear: 0=mid, 1=fast, 2=panic
    LoopVar = AlienOffsetY / 2
    IF LoopVar > 2 THEN LoopVar = 2

    ' Only switch if gear changed
    IF LoopVar = MusicGear THEN RETURN
    MusicGear = LoopVar

    ON MusicGear GOTO GearFast, GearPanic
    ' Gear 0 = mid (fallthrough)
    PLAY si_bg_mid
    RETURN
GearFast:
    PLAY si_bg_fast
    RETURN
GearPanic:
    PLAY si_bg_panic
    RETURN
END

' --------------------------------------------
' DrawHUD - Full HUD redraw (score, chain, powerup, lives)
' Called after CLS or screen clears. Shows current #Score and chain state.
' --------------------------------------------
DrawHUD: PROCEDURE
    ' Score: 7-digit zero-padded display (223-226) using 4 packed digit cards (32, 61-63)
    ' Label (220-222) set by round-robin during gameplay
    PRINT AT 223, GRAM_SCORE_M * 8 + COL_WHITE + $0800   ' D6D5 (millions + hundred-thousands, "00" when score < 100K)
    PRINT AT 224, GRAM_SCORE_SC * 8 + COL_WHITE + $0800  ' D4D3 (ten-thousands + thousands)
    PRINT AT 225, GRAM_SCORE_OR * 8 + COL_WHITE + $0800  ' D2D1 (hundreds + tens)
    PRINT AT 226, GRAM_SCORE_E * 8 + COL_WHITE + $0800   ' D0 (ones + blank)
    PRINT AT 227, 0  ' Blank separator
    ' Chain label (228-230): static GRAM cards CH, AI, N — grey when inactive
    ' Position 231: TinyFont digit for chain 10+, updated by round-robin
    ' Position 232: powerup area
    PRINT AT 228, GRAM_CHAIN_CH * 8 + $1800
    PRINT AT 229, GRAM_CHAIN_AI * 8 + $1800
    PRINT AT 230, GRAM_CHAIN_N * 8 + $1800
    PRINT AT 231, 0  ' Blank initially (digit shown when chain >= 10)
    ' Powerup indicator cleared (3 cells: 233-235)
    PRINT AT 233, 0 : PRINT AT 234, 0 : PRINT AT 235, 0
    ' Lives: ship icon at 237, TinyFont digit at 239 (card 29, round-robin) — moved right +1
    PRINT AT 237, (GRAM_SHIP_HUD * 8) + COL_WHITE + $0800
    PRINT AT 239, GRAM_LIVES_DIG * 8 + COL_WHITE + $0800
    RETURN
END

' --------------------------------------------
' DeactivateSaucer - Hide saucer sprites and reset flight state
' Replaces 6 identical reset blocks
' --------------------------------------------
DeactivateSaucer: PROCEDURE
    FlyState = 0
    #FlyPhase = 0
    #FlyLoopCount = RANDOM(360) + 180
    SPRITE SPR_SAUCER, 0, 0, 0
    SPRITE SPR_SAUCER2, 0, 0, 0
    RETURN
END

' --------------------------------------------
' UpdateSfx - Noise channel explosion with attack-decay
' --------------------------------------------
UpdateSfx: PROCEDURE
    IF SfxVolume = 0 THEN RETURN

    ' All SFX on channel 3 (SOUND 2) to coexist with PLAY SIMPLE music
    SOUND 2, #SfxPitch, SfxVolume

    ' Decay based on type
    IF SfxType = 2 THEN
        ' Saucer crash: slow decay + descending pitch (sustained crunch)
        IF (BulletColor AND 1) = 0 THEN
            IF SfxVolume > 1 THEN
                SfxVolume = SfxVolume - 1
            ELSE
                SfxVolume = 0
            END IF
        END IF
        #SfxPitch = #SfxPitch + 8
    ELSEIF SfxType = 3 THEN
        ' Player death: pure white noise boom (Astrosmash-style)
        ' No tone on channel C - only noise via PSG POKE after ISR
        ' DeathTimer=0 on first frame (before PlayerHit sets it)
        #SfxPitch = 0
        IF DeathTimer > 5 OR DeathTimer = 0 THEN
            ' Slow volume decay: drop 1 every 4 frames
            IF DeathTimer > 0 THEN
                IF (DeathTimer AND 3) = 0 THEN
                    IF SfxVolume > 1 THEN
                        SfxVolume = SfxVolume - 1
                    END IF
                END IF
                ' Noise period deepens over time (14 → ~31)
                POKE $1F9, 14 + (75 - DeathTimer) / 4
            ELSE
                POKE $1F9, 14
            END IF
        ELSE
            SfxVolume = 0
        END IF
        ' Enable noise only on channel C (no tone = pure white noise)
        IF SfxVolume > 0 THEN
            POKE $1F8, PEEK($1F8) AND $DF ' Bit 5 clear: noise C on
        END IF
    ELSEIF SfxType = 4 THEN
        ' Mega beam blast: bright crackle → fade
        #SfxPitch = 0
        IF Sol36BeamTimer > 0 THEN
            IF (Sol36BeamTimer AND 3) = 0 THEN
                IF SfxVolume > 1 THEN SfxVolume = SfxVolume - 1
            END IF
            POKE $1F9, 8 + (20 - Sol36BeamTimer) / 2
            POKE $1F8, PEEK($1F8) AND $DF
        ELSE
            SfxVolume = 0
        END IF
    ELSEIF SfxType = 5 THEN
        ' Bomb explosion: white noise boom (same envelope as ship death)
        #SfxPitch = 0
        IF BombExpTimer > 2 THEN
            ' Slow volume decay: drop 1 every 2 frames
            IF (BombExpTimer AND 1) = 0 THEN
                IF SfxVolume > 1 THEN
                    SfxVolume = SfxVolume - 1
                END IF
            END IF
            ' Noise period deepens over time (14 → ~23), BombExpTimer starts at 30
            POKE $1F9, 14 + (30 - BombExpTimer) / 3
        ELSE
            SfxVolume = 0
        END IF
        ' Enable noise only on channel C (pure white noise)
        IF SfxVolume > 0 THEN
            POKE $1F8, PEEK($1F8) AND $DF ' Bit 5 clear: noise C on
        END IF
    ELSEIF SfxType = 6 THEN
        ' Parry: bright zap - fast ascending pitch + very fast decay
        #SfxPitch = #SfxPitch + 12
        IF SfxVolume > 3 THEN
            SfxVolume = SfxVolume - 3
        ELSE
            SfxVolume = 0
        END IF
    ELSEIF SfxType = 7 THEN
        ' Pea shooter: descending laser zap (pitch rises = lower tone)
        #SfxPitch = #SfxPitch + 15
        IF #SfxPitch > 800 THEN #SfxPitch = 800
        IF SfxVolume > 1 THEN
            SfxVolume = SfxVolume - 1
        ELSE
            SfxVolume = 0
        END IF
    ELSEIF SfxType = 9 THEN
        ' Shield absorb: high-pitched ping with fast decay
        #SfxPitch = #SfxPitch + 50
        IF #SfxPitch > 1200 THEN #SfxPitch = 1200
        IF SfxVolume > 2 THEN
            SfxVolume = SfxVolume - 2
        ELSE
            SfxVolume = 0
        END IF
    ELSE
        ' Alien: fast decay (2 per frame)
        IF SfxVolume > 2 THEN
            SfxVolume = SfxVolume - 2
        ELSE
            SfxVolume = 0
        END IF
    END IF

    ' Silence when done
    IF SfxVolume = 0 THEN
        SOUND 2, , 0           ' Silence channel 3 (ISR restores $1F8 next WAIT)
        SfxType = 0
    END IF
    RETURN
END

' UpdateSaucer moved to Segment 2

' --------------------------------------------
' Sol36Kill - Kill all aliens in the beam column
' --------------------------------------------
Sol36Kill: PROCEDURE
    ' Kill aliens in beam column AND adjacent column (brutal 16px hitbox)
    FOR HitRow = 0 TO 1
        IF HitRow = 0 THEN
            HitCol = Sol36Col
        ELSE
            HitCol = Sol36Col + 1
        END IF
        IF HitCol >= ALIEN_START_X + AlienOffsetX THEN
            IF HitCol < ALIEN_START_X + AlienOffsetX + ALIEN_COLS THEN
                AlienGridCol = HitCol - ALIEN_START_X - AlienOffsetX
                ' Only guard during active reveal animation, allow all columns otherwise
                IF (#GameFlags AND FLAG_REVEAL) = 0 OR AlienGridCol <= WaveRevealCol THEN
                    ' Build bitmask for this column
                    #Mask = ColMaskData(AlienGridCol)
                    ' Kill alien in every row at this column
                    FOR LoopVar = 0 TO ALIEN_ROWS - 1
                        IF #AlienRow(LoopVar) AND #Mask THEN
                            ' Multi-boss intercept in mega beam (inlined FindBoss)
                            AlienGridRow = LoopVar
                            FoundBoss = 255
                            IF BossCount > 0 THEN
                                FOR Row = 0 TO BossCount - 1
                                    IF BossHP(Row) > 0 THEN
                                        IF AlienGridRow = BossRow(Row) THEN
                                            IF AlienGridCol = BossCol(Row) OR AlienGridCol = BossCol(Row) + 1 THEN
                                                FoundBoss = Row
                                            END IF
                                        END IF
                                    END IF
                                NEXT Row
                            END IF
                            IF FoundBoss < 255 THEN
                                ' Only deal 1 damage per boss per beam activation
                                IF BossBeamHit(FoundBoss) < 1 THEN
                                    BossBeamHit(FoundBoss) = BossBeamHit(FoundBoss) + 1
                                    BossHP(FoundBoss) = BossHP(FoundBoss) - 1
                                    IF BossHP(FoundBoss) > 0 THEN
                                        GOSUB UpdateBossColor
                                    ELSE
                                        ' Boss dead! Check type
                                        IF BossType(FoundBoss) = BOMB_TYPE THEN
                                            ' Bomb alien — chain explosion!
                                            GOSUB BombExplode
                                        ELSE
                                            ' Skull boss dead!
                                            GOSUB SkullBossGridClear
                                            #Mask = BOSS_SCORE : GOSUB AddToScore
                                        END IF
                                        ' Restore #Mask for current column iteration
                                        #Mask = ColMaskData(AlienGridCol)
                                    END IF
                                END IF
                            ELSE
                                ' Normal alien kill
                                #AlienRow(LoopVar) = #AlienRow(LoopVar) XOR #Mask
                                GOSUB BumpChain
                                IF ChainCount > 5 THEN
                                    #Mask = 50 : GOSUB AddToScore
                                ELSE
                                    #Mask = ChainCount * 10 : GOSUB AddToScore
                                END IF
                                ' Restore #Mask - AddToScore clobbers it!
                                #Mask = ColMaskData(AlienGridCol)
                            END IF
                            #ExplosionPos = (ALIEN_START_Y + AlienOffsetY + LoopVar) * 20 + HitCol
                            GOSUB ShowChainExplosion
                        END IF
                    NEXT LoopVar
                    IF ChainCount >= 2 THEN ExplosionTimer = 16 ELSE ExplosionTimer = 15
                END IF
            END IF
        END IF
    NEXT HitRow
    ' Kill saucer if beam overlaps it (beam = 16px from Sol36Col*8)
    IF FlyState > 0 THEN
        #ScreenPos = Sol36Col * 8
        ' Saucer spans FlyX to FlyX+15, beam spans #ScreenPos to #ScreenPos+15
        IF #ScreenPos + 15 >= FlyX THEN
            IF #ScreenPos <= FlyX + 15 THEN
                ' Destroy saucer
                GOSUB DeactivateSaucer
                SfxType = 2 : SfxVolume = 15 : #SfxPitch = 150
                SOUND 2, 150, 15
                #Mask = 100 : GOSUB AddToScore
                ' Drop power-up from saucer position
                PowerUpState = 1
                PowerUpX = FlyX
                PowerUpY = FlyY
                CapsuleFrame = 0
                ' Clear previous explosion tile if still active
                GOSUB ClearPrevExplosion
                #ExplosionPos = FlyX / 8
                ExplosionTimer = 15
                PRINT AT #ExplosionPos, GRAM_EXPLOSION * 8 + 4 + $1800
            END IF
        END IF
    END IF
    ' Kill rogue alien in dogfight if beam overlaps it
    IF RogueState = ROGUE_DIVE THEN
        #ScreenPos = Sol36Col * 8
        ' Rogue sprite is 8px wide at RogueX; beam is 16px wide at #ScreenPos
        IF #ScreenPos + 15 >= RogueX THEN
            IF #ScreenPos <= RogueX + 8 THEN
                ' Destroy rogue
                GOSUB DestroyRogue
            END IF
        END IF
    END IF
    RETURN
END

' --------------------------------------------
' DestroyRogue - Shared rogue alien kill sequence (score, SFX, state reset)
' Called from Sol36Kill and player-bullet rogue collision
' --------------------------------------------
DestroyRogue: PROCEDURE
    RogueState = ROGUE_IDLE
    RogueTimer = 0 : RogueDivePhase = 0
    SPRITE SPR_FLYER, 0, 0, 0
    #Mask = 50 : GOSUB AddToScore
    #GameFlags = #GameFlags OR FLAG_SHOTLAND
    GOSUB BumpChain
    SfxType = 1 : SfxVolume = 14 : #SfxPitch = 180
    SOUND 2, 180, 14
    RETURN
END

' --------------------------------------------
' Sol36Draw - Draw beam column on BACKTAB (starts at row 8, above ship)
' --------------------------------------------
Sol36Draw: PROCEDURE
    ' Start with just the beam origin row (row 8, above ship turret)
    #ScreenPos = 8 * 20 + Sol36Col
    PRINT AT #ScreenPos, GRAM_SOL36 * 8 + COL_WHITE + $0800
    RETURN
END

' --------------------------------------------
' Sol36Clear - Clear beam column from BACKTAB
' --------------------------------------------
Sol36Clear: PROCEDURE
    FOR LoopVar = 0 TO 9
        #ScreenPos = Row20Data(LoopVar) + Sol36Col
        PRINT AT #ScreenPos, 0
    NEXT LoopVar
    RETURN
END

' --------------------------------------------
' Sol36SputterStop - Force-end sputter (death/wave transition)
' Restores solid beam GRAM card and silences SFX
' --------------------------------------------
Sol36SputterStop: PROCEDURE
    Sol36SputterTimer = 0
    DEFINE GRAM_SOL36, 1, Sol36Gfx
    ' Only silence SFX if mega beam was actually playing (SfxType=4).
    ' Do NOT clear SfxType=3 (death explosion) — that was set by the collision
    ' code on this same frame and must sustain through the death animation.
    IF SfxType = 4 THEN
        SOUND 2, , 0
        SfxType = 0 : SfxVolume = 0
    END IF
    RETURN
END

' --------------------------------------------
' Sol36SputterUpdate - SOL-36 fade-out: 60-frame thin sputter + 2 kill spurts
'
' Phase timing (Sol36SputterTimer counts down from 95):
'   94→35 (60 frames): continuous thin beam, flickers 3-on/1-off, RED
'   34→30  (5 frames): gap 1 — beam off
'   29→20 (10 frames): kill spurt 1 — fast alternating flicker, YELLOW
'   19→15  (5 frames): gap 2 — beam off
'   14→ 5 (10 frames): kill spurt 2 — fast alternating flicker, ORANGE
'    4→ 1  (4 frames): fizzle — beam off
'       0           : restore solid beam card, done
'
' Kill sweeps fire once at: T=94 (sputter start), T=29 (spurt 1), T=13 (spurt 2)
' Beam column tracks player position every frame.
' Card 46 (GRAM_SOL36) holds SolSputterGfx thin stripe; restored to
' Sol36Gfx solid block at T=0 or via Sol36SputterStop on force-clear.
' --------------------------------------------
Sol36SputterUpdate: PROCEDURE
    Sol36SputterTimer = Sol36SputterTimer - 1  ' audit-ignore: caller (gameloop) guards with IF Sol36SputterTimer > 0

    ' Clear previous beam column
    FOR LoopVar = 0 TO 9
        #ScreenPos = Row20Data(LoopVar) + Sol36Col
        PRINT AT #ScreenPos, 0
    NEXT LoopVar

    ' Track beam column — follow player
    Sol36Col = (PlayerX - 4) / 8
    IF Sol36Col > 19 THEN Sol36Col = 19

    ' Kill sweeps at start of sputter and each final spurt
    IF Sol36SputterTimer = 94 OR Sol36SputterTimer = 29 OR Sol36SputterTimer = 13 THEN
        FOR Row = 0 TO MAX_BOSSES - 1
            BossBeamHit(Row) = 0
        NEXT Row
        GOSUB Sol36Kill
    END IF

    ' Determine beam color this frame (0 = off)
    AlienColor = 0
    IF Sol36SputterTimer >= 35 THEN
        ' Continuous sputter: on for 3 of every 4 frames (AND 3 = 0 is off)
        IF (Sol36SputterTimer AND 3) <> 0 THEN AlienColor = COL_RED
    ELSEIF Sol36SputterTimer >= 30 THEN
        ' Gap 1: off
    ELSEIF Sol36SputterTimer >= 20 THEN
        ' Spurt 1: rapid alternating flicker, yellow
        IF (Sol36SputterTimer AND 1) THEN AlienColor = COL_YELLOW
    ELSEIF Sol36SputterTimer >= 15 THEN
        ' Gap 2: off
    ELSEIF Sol36SputterTimer >= 5 THEN
        ' Spurt 2: rapid alternating flicker, orange
        IF (Sol36SputterTimer AND 1) THEN AlienColor = COL_ORANGE
    END IF
    ' T=4 to T=1: fizzle — AlienColor stays 0

    ' Draw or silence based on beam state
    IF AlienColor > 0 THEN
        FOR LoopVar = 0 TO 9
            #ScreenPos = Row20Data(LoopVar) + Sol36Col
            PRINT AT #ScreenPos, GRAM_SOL36 * 8 + AlienColor + $0800
        NEXT LoopVar
        SOUND 2, 0, 6
    ELSE
        SOUND 2, , 0
    END IF

    ' End of sputter: restore solid beam card
    IF Sol36SputterTimer = 0 THEN
        DEFINE GRAM_SOL36, 1, Sol36Gfx
        SOUND 2, , 0
        SfxType = 0 : SfxVolume = 0
    END IF
    RETURN
END

' --------------------------------------------
' UpdatePowerUp - Handle falling/landed power-up capsule
' --------------------------------------------
LoadPatternB: PROCEDURE
    #GameFlags = #GameFlags OR FLAG_SUBWAVE

    ' Clean ISR state before WAIT loops (prevents cumulative frame budget leak)
    POKE $0345, 0    ' Clear _gram2_bitmap trigger
    POKE $0108, 0    ' Clear _gram2_total counter

    ' Silence any lingering SFX
    SOUND 2, , 0
    POKE $1F8, PEEK($1F8) OR $20  ' Disable noise on channel C
    SfxVolume = 0
    SfxType = 0

    ' Clear active bullets, rogue (but preserve wingman!)
    GOSUB ClearBulletsAndBeam
    #GameFlags = #GameFlags AND ($FFFF XOR FLAG_REINFORCE)
    GOSUB ClearWaveObjects

    ' Reset alien positions (center the grid on screen)
    AlienOffsetX = 5
    AlienOffsetY = 0
    LastClearedY = 0
    AlienDir = 1
    MarchCount = 0
    CurrentMarchSpeed = BaseMarchSpeed  ' Reset speed (don't inherit Pattern A's acceleration)

    ' Look up which pattern to use for this level
    LoopVar = (Level - 1) AND 31
    LoopVar = PatternBIndex(LoopVar)
    ' Load bitmasks from packed data (each pattern = 5 consecutive words)
    Col = LoopVar * 5
    FOR LoopVar = 0 TO ALIEN_ROWS - 1
        #AlienRow(LoopVar) = PatternBData(Col + LoopVar)
    NEXT LoopVar

    ' Clear all boss slots
    FOR LoopVar = 0 TO MAX_BOSSES - 1
        BossHP(LoopVar) = 0
    NEXT LoopVar
    BossCount = 0 : BombExpTimer = 0 : OrbitStep = 255 : OrbitStep2 = 255

    ' ── LEVEL DESIGN: Boss Placement (edit here or paste from Wave Designer) ──
    LoopVar = (Level - 1) AND 31  ' 0-based wave index (0-31)
    ' Boss types: SKULL_TYPE=0 (3 HP multi-hit), BOMB_TYPE=1 (2 HP chain explode)
    ' Bosses are 2-wide: occupy BossCol and BossCol+1. Max 4 bosses per wave.
    ' Orbiters: OrbitStep/OrbitStep2 = 0 to activate (bomb bosses only, max 2).

    IF LoopVar = 0 THEN
        ' Wave 1: 1 skull boss
        BossCount = 1
        BossCol(0) = 3 : BossRow(0) = 3
        BossHP(0) = 3 : BossColor(0) = 9 : BossType(0) = SKULL_TYPE
    ELSEIF LoopVar = 1 THEN
        ' Wave 2: 2 skull bosses
        BossCount = 2
        BossCol(0) = 2 : BossRow(0) = 2
        BossHP(0) = 3 : BossColor(0) = 9 : BossType(0) = SKULL_TYPE
        BossCol(1) = 5 : BossRow(1) = 2
        BossHP(1) = 3 : BossColor(1) = 9 : BossType(1) = SKULL_TYPE
    ELSEIF LoopVar = 2 THEN
        ' Wave 3: 1 bomb boss (no orbiter — conflicts with surrounding alien sprites)
        BossCount = 1
        BossCol(0) = 3 : BossRow(0) = 1
        BossHP(0) = 2 : BossColor(0) = 10 : BossType(0) = BOMB_TYPE
    ELSEIF LoopVar = 3 THEN
        ' Wave 4: 2 bomb bosses + 2 orbiters
        BossCount = 2
        BossCol(0) = 2 : BossRow(0) = 1
        BossHP(0) = 2 : BossColor(0) = 10 : BossType(0) = BOMB_TYPE
        BossCol(1) = 5 : BossRow(1) = 3
        BossHP(1) = 2 : BossColor(1) = 10 : BossType(1) = BOMB_TYPE
        OrbitStep = 0
        OrbitStep2 = 5
    ELSEIF LoopVar = 4 THEN
        ' Wave 5: 2 skull bosses
        BossCount = 2
        BossCol(0) = 2 : BossRow(0) = 2
        BossHP(0) = 3 : BossColor(0) = 9 : BossType(0) = SKULL_TYPE
        BossCol(1) = 5 : BossRow(1) = 2
        BossHP(1) = 3 : BossColor(1) = 9 : BossType(1) = SKULL_TYPE
    ELSEIF LoopVar = 5 THEN
        ' Wave 6: 3 skull bosses
        BossCount = 3
        BossCol(0) = 3 : BossRow(0) = 3
        BossHP(0) = 3 : BossColor(0) = 9 : BossType(0) = SKULL_TYPE
        BossCol(1) = 5 : BossRow(1) = 3
        BossHP(1) = 3 : BossColor(1) = 9 : BossType(1) = SKULL_TYPE
        BossCol(2) = 4 : BossRow(2) = 2
        BossHP(2) = 3 : BossColor(2) = 9 : BossType(2) = SKULL_TYPE
    ELSEIF LoopVar = 6 THEN
        ' Wave 7: 1 bomb boss
        BossCount = 1
        BossCol(0) = 4 : BossRow(0) = 2
        BossHP(0) = 2 : BossColor(0) = 10 : BossType(0) = BOMB_TYPE
    ELSEIF LoopVar = 7 THEN
        ' Wave 8: 2 skull bosses
        BossCount = 2
        BossCol(0) = 1 : BossRow(0) = 1
        BossHP(0) = 3 : BossColor(0) = 9 : BossType(0) = SKULL_TYPE
        BossCol(1) = 6 : BossRow(1) = 3
        BossHP(1) = 3 : BossColor(1) = 9 : BossType(1) = SKULL_TYPE
    ' ── Waves 9-16 ──
    ' Wave 9 (LoopVar=8): no bosses
    ELSEIF LoopVar = 9 THEN
        ' Wave 10: 2 skull bosses on wings
        BossCount = 2
        BossCol(0) = 0 : BossRow(0) = 1
        BossHP(0) = 3 : BossColor(0) = 9 : BossType(0) = SKULL_TYPE
        BossCol(1) = 6 : BossRow(1) = 1
        BossHP(1) = 3 : BossColor(1) = 9 : BossType(1) = SKULL_TYPE
    ELSEIF LoopVar = 10 THEN
        ' Wave 11: 1 bomb boss (no orbiter — Zigzag pattern is too dense for orbit clearance)
        BossCount = 1
        BossCol(0) = 4 : BossRow(0) = 2
        BossHP(0) = 2 : BossColor(0) = 10 : BossType(0) = BOMB_TYPE
    ELSEIF LoopVar = 11 THEN
        ' Wave 12: 2 skulls guarding corners
        BossCount = 2
        BossCol(0) = 0 : BossRow(0) = 0
        BossHP(0) = 3 : BossColor(0) = 12 : BossType(0) = SKULL_TYPE
        BossCol(1) = 7 : BossRow(1) = 4
        BossHP(1) = 3 : BossColor(1) = 12 : BossType(1) = SKULL_TYPE
    ' Wave 13 (LoopVar=12): no bosses (breather)
    ELSEIF LoopVar = 13 THEN
        ' Wave 14: 1 bomb boss
        BossCount = 1
        BossCol(0) = 2 : BossRow(0) = 2
        BossHP(0) = 2 : BossColor(0) = 10 : BossType(0) = BOMB_TYPE
    ELSEIF LoopVar = 14 THEN
        ' Wave 15: 1 skull boss
        BossCount = 1
        BossCol(0) = 3 : BossRow(0) = 0
        BossHP(0) = 3 : BossColor(0) = 9 : BossType(0) = SKULL_TYPE
    ELSEIF LoopVar = 15 THEN
        ' Wave 16: 1 bomb + 1 skull
        BossCount = 2
        BossCol(0) = 3 : BossRow(0) = 1
        BossHP(0) = 4 : BossColor(0) = 10 : BossType(0) = BOMB_TYPE
        BossCol(1) = 6 : BossRow(1) = 3
        BossHP(1) = 3 : BossColor(1) = 9 : BossType(1) = SKULL_TYPE
    ' ── Waves 17-24: Harder ──
    ELSEIF LoopVar = 16 THEN
        ' Wave 17: 3 skulls
        BossCount = 3
        BossCol(0) = 1 : BossRow(0) = 0
        BossHP(0) = 3 : BossColor(0) = 9 : BossType(0) = SKULL_TYPE
        BossCol(1) = 4 : BossRow(1) = 0
        BossHP(1) = 3 : BossColor(1) = 12 : BossType(1) = SKULL_TYPE
        BossCol(2) = 7 : BossRow(2) = 4
        BossHP(2) = 3 : BossColor(2) = 10 : BossType(2) = SKULL_TYPE
    ELSEIF LoopVar = 17 THEN
        ' Wave 18: 2 bombs (no orbiters — Fortress alt is too dense; boss 1 orbit also exits grid below row 4)
        BossCount = 2
        BossCol(0) = 1 : BossRow(0) = 1
        BossHP(0) = 2 : BossColor(0) = 10 : BossType(0) = BOMB_TYPE
        BossCol(1) = 5 : BossRow(1) = 3
        BossHP(1) = 2 : BossColor(1) = 10 : BossType(1) = BOMB_TYPE
    ELSEIF LoopVar = 18 THEN
        ' Wave 19: 1 bomb w/ orbiter + 1 skull
        BossCount = 2
        BossCol(0) = 1 : BossRow(0) = 1
        BossHP(0) = 2 : BossColor(0) = 10 : BossType(0) = BOMB_TYPE
        BossCol(1) = 6 : BossRow(1) = 3
        BossHP(1) = 3 : BossColor(1) = 9 : BossType(1) = SKULL_TYPE
        OrbitStep = 0
    ELSEIF LoopVar = 19 THEN
        ' Wave 20: 2 bombs + 2 orbiters
        BossCount = 2
        BossCol(0) = 1 : BossRow(0) = 0
        BossHP(0) = 2 : BossColor(0) = 10 : BossType(0) = BOMB_TYPE
        BossCol(1) = 5 : BossRow(1) = 4
        BossHP(1) = 2 : BossColor(1) = 10 : BossType(1) = BOMB_TYPE
        OrbitStep = 0
        OrbitStep2 = 5
    ELSEIF LoopVar = 20 THEN
        ' Wave 21: 3 skulls
        BossCount = 3
        BossCol(0) = 0 : BossRow(0) = 0
        BossHP(0) = 3 : BossColor(0) = 12 : BossType(0) = SKULL_TYPE
        BossCol(1) = 7 : BossRow(1) = 0
        BossHP(1) = 3 : BossColor(1) = 12 : BossType(1) = SKULL_TYPE
        BossCol(2) = 3 : BossRow(2) = 4
        BossHP(2) = 3 : BossColor(2) = 9 : BossType(2) = SKULL_TYPE
    ELSEIF LoopVar = 21 THEN
        ' Wave 22: 1 bomb + 2 skulls (no orbiter — Cross alt row 2 is solid $1FF)
        BossCount = 3
        BossCol(0) = 3 : BossRow(0) = 2
        BossHP(0) = 2 : BossColor(0) = 10 : BossType(0) = BOMB_TYPE
        BossCol(1) = 1 : BossRow(1) = 0
        BossHP(1) = 3 : BossColor(1) = 9 : BossType(1) = SKULL_TYPE
        BossCol(2) = 1 : BossRow(2) = 4
        BossHP(2) = 3 : BossColor(2) = 9 : BossType(2) = SKULL_TYPE
    ' Wave 23 (LoopVar=22): no bosses (breather)
    ELSEIF LoopVar = 23 THEN
        ' Wave 24: 2 bombs w/ orbiters
        BossCount = 2
        BossCol(0) = 2 : BossRow(0) = 1
        BossHP(0) = 5 : BossColor(0) = 12 : BossType(0) = BOMB_TYPE
        OrbitStep = 0
        BossCol(1) = 6 : BossRow(1) = 3
        BossHP(1) = 5 : BossColor(1) = 12 : BossType(1) = BOMB_TYPE
        OrbitStep2 = 5
    ' ── Waves 25-32: Endgame gauntlet ──
    ELSEIF LoopVar = 24 THEN
        ' Wave 25: 4 bosses — 1 bomb w/ orbiter + 3 skulls
        BossCount = 4
        BossCol(0) = 1 : BossRow(0) = 4
        BossHP(0) = 2 : BossColor(0) = 10 : BossType(0) = BOMB_TYPE
        BossCol(1) = 5 : BossRow(1) = 3
        BossHP(1) = 3 : BossColor(1) = 9 : BossType(1) = SKULL_TYPE
        BossCol(2) = 3 : BossRow(2) = 2
        BossHP(2) = 3 : BossColor(2) = 12 : BossType(2) = SKULL_TYPE
        BossCol(3) = 7 : BossRow(3) = 4
        BossHP(3) = 3 : BossColor(3) = 9 : BossType(3) = SKULL_TYPE
        OrbitStep = 0
    ELSEIF LoopVar = 25 THEN
        ' Wave 26: 2 bombs + 2 orbiters
        BossCount = 2
        BossCol(0) = 3 : BossRow(0) = 1
        BossHP(0) = 2 : BossColor(0) = 10 : BossType(0) = BOMB_TYPE
        BossCol(1) = 3 : BossRow(1) = 3
        BossHP(1) = 2 : BossColor(1) = 10 : BossType(1) = BOMB_TYPE
        OrbitStep = 0
        OrbitStep2 = 5
    ELSEIF LoopVar = 26 THEN
        ' Wave 27: 3 skulls
        BossCount = 3
        BossCol(0) = 0 : BossRow(0) = 0
        BossHP(0) = 3 : BossColor(0) = 9 : BossType(0) = SKULL_TYPE
        BossCol(1) = 4 : BossRow(1) = 2
        BossHP(1) = 3 : BossColor(1) = 12 : BossType(1) = SKULL_TYPE
        BossCol(2) = 0 : BossRow(2) = 4
        BossHP(2) = 3 : BossColor(2) = 9 : BossType(2) = SKULL_TYPE
    ELSEIF LoopVar = 27 THEN
        ' Wave 28: 4 bosses — 2 bombs + 2 skulls (no orbiters — Phalanx alt rows 0,2 are solid $1FF)
        BossCount = 4
        BossCol(0) = 1 : BossRow(0) = 0
        BossHP(0) = 2 : BossColor(0) = 10 : BossType(0) = BOMB_TYPE
        BossCol(1) = 5 : BossRow(1) = 0
        BossHP(1) = 2 : BossColor(1) = 10 : BossType(1) = BOMB_TYPE
        BossCol(2) = 1 : BossRow(2) = 4
        BossHP(2) = 3 : BossColor(2) = 9 : BossType(2) = SKULL_TYPE
        BossCol(3) = 5 : BossRow(3) = 4
        BossHP(3) = 3 : BossColor(3) = 12 : BossType(3) = SKULL_TYPE
    ELSEIF LoopVar = 28 THEN
        ' Wave 29: 2 skulls
        BossCount = 2
        BossCol(0) = 1 : BossRow(0) = 0
        BossHP(0) = 3 : BossColor(0) = 12 : BossType(0) = SKULL_TYPE
        BossCol(1) = 6 : BossRow(1) = 0
        BossHP(1) = 3 : BossColor(1) = 12 : BossType(1) = SKULL_TYPE
    ELSEIF LoopVar = 29 THEN
        ' Wave 30: 3 skulls
        BossCount = 3
        BossCol(0) = 0 : BossRow(0) = 0
        BossHP(0) = 3 : BossColor(0) = 9 : BossType(0) = SKULL_TYPE
        BossCol(1) = 4 : BossRow(1) = 2
        BossHP(1) = 3 : BossColor(1) = 12 : BossType(1) = SKULL_TYPE
        BossCol(2) = 0 : BossRow(2) = 4
        BossHP(2) = 3 : BossColor(2) = 10 : BossType(2) = SKULL_TYPE
    ELSEIF LoopVar = 30 THEN
        ' Wave 31: 2 bombs — boss 1 orbiter only (boss 0 at row 0 is in solid Dense Rows row)
        BossCount = 2
        BossCol(0) = 2 : BossRow(0) = 0
        BossHP(0) = 2 : BossColor(0) = 10 : BossType(0) = BOMB_TYPE
        BossCol(1) = 5 : BossRow(1) = 2
        BossHP(1) = 2 : BossColor(1) = 10 : BossType(1) = BOMB_TYPE
        OrbitStep2 = 5  ' Only boss 1 (row 2, sparse area) gets an orbiter
    ELSEIF LoopVar = 31 THEN
        ' Wave 32: 3 skull bosses
        BossCount = 3
        BossCol(0) = 1 : BossRow(0) = 0
        BossHP(0) = 4 : BossColor(0) = 15 : BossType(0) = SKULL_TYPE
        BossCol(1) = 4 : BossRow(1) = 2
        BossHP(1) = 4 : BossColor(1) = 15 : BossType(1) = SKULL_TYPE
        BossCol(2) = 7 : BossRow(2) = 4
        BossHP(2) = 4 : BossColor(2) = 15 : BossType(2) = SKULL_TYPE
    END IF

    ' ── END Boss Placement ──

    ' Force-set boss cells alive in grid (pattern data may have gaps)
    ' Without this, XOR on death resurrects dead cells → "ghost alien" bug
    IF BossCount > 0 THEN
        FOR LoopVar = 0 TO BossCount - 1
            ' Skull/bomb: set 2-wide columns
            #AlienRow(BossRow(LoopVar)) = #AlienRow(BossRow(LoopVar)) OR ColMaskData(BossCol(LoopVar))
            #AlienRow(BossRow(LoopVar)) = #AlienRow(BossRow(LoopVar)) OR ColMaskData(BossCol(LoopVar) + 1)
        NEXT LoopVar
    END IF

    ' Normalize grid: shift bitmasks so leftmost alive column = 0
    ' This ensures symmetric march range (AlienOffsetX can't go below 0)
    HitRow = 8
    FOR Row = 0 TO ALIEN_ROWS - 1
        IF #AlienRow(Row) THEN
            #Mask = 1
            FOR Col = 0 TO 8
                IF #AlienRow(Row) AND #Mask THEN
                    IF Col < HitRow THEN HitRow = Col
                END IF
                #Mask = #Mask + #Mask
            NEXT Col
        END IF
    NEXT Row
    IF HitRow > 0 THEN
        FOR Row = 0 TO ALIEN_ROWS - 1
            #AlienRow(Row) = #AlienRow(Row) / ColMaskData(HitRow)
        NEXT Row
        AlienOffsetX = AlienOffsetX + HitRow
        FOR LoopVar = 0 TO BossCount - 1
            BossCol(LoopVar) = BossCol(LoopVar) - HitRow
        NEXT LoopVar
    END IF

    ' ── Clear orbit path cells for orbiter bosses (after normalization) ──
    ' Removes any alive aliens in the 8 cells the orbiter sprite will cross.
    ' Boss cells (BossCol, BossCol+1) are preserved by ClearOrbitPath.
    IF OrbitStep < 10 THEN
        AlienGridRow = BossRow(0) : AlienGridCol = BossCol(0)
        GOSUB ClearOrbitPath
    END IF
    IF OrbitStep2 < 10 THEN
        AlienGridRow = BossRow(1) : AlienGridCol = BossCol(1)
        GOSUB ClearOrbitPath
    END IF

    ' Set dual-slide mode: halves fly in from screen edges
    #GameFlags = #GameFlags OR FLAG_REVEAL
    WaveEntrance = 0                   ' Clear entrance mode for dual-slide
    WaveRevealCol = 0              ' Left group starts at far left
    RightRevealCol = 10            ' Right group starts at far right

    ' Clear alien area on screen (rows 0-10)
    FOR LoopVar = 0 TO 10
        #ScreenPos = Row20Data(LoopVar)
        FOR Col = 0 TO 19
            PRINT AT #ScreenPos + Col, 0
        NEXT Col
    NEXT LoopVar

    ' Redraw HUD (cleared by above loop at row 11)
    GOSUB DrawHUD

    ' Brief audio cue + banner overlay (displays during fly-down entrance animation)
    SOUND 2, 200, 12
    FOR LoopVar = 0 TO 3
        WAIT
    NEXT LoopVar
    SOUND 2, , 0
    WaveAnnouncerTimer = 50
    WaveAnnouncerType = 2

    RETURN
END

' --------------------------------------------
' CheckWaveWin - Check if all aliens defeated
' --------------------------------------------
CheckWaveWin: PROCEDURE
    ' Don't trigger wave win during game over sequence
    IF GameOver > 0 THEN RETURN

    ' Check if any aliens remain (OR is single-cycle vs loop+add)
    #AliensAlive = #AlienRow(0) OR #AlienRow(1) OR #AlienRow(2) OR #AlienRow(3) OR #AlienRow(4)

    ' Count active rogue as alive
    IF RogueState >= ROGUE_DIVE THEN #AliensAlive = #AliensAlive + 1

    ' If no aliens left, wait for explosion then advance
    IF #AliensAlive = 0 THEN
        IF ExplosionTimer = 0 THEN
            IF (#GameFlags AND FLAG_SUBWAVE) = 0 THEN
                ' Relentless waves: send a second horde before Pattern B
                Col = (Level - 1) AND 31
                IF Col = 2 OR Col = 5 OR Col = 8 OR Col = 11 OR Col = 14 OR Col = 17 OR Col = 20 OR Col = 23 OR Col = 26 OR Col = 29 THEN  ' Waves 3,6,9,12,15,18,21,24,27,30
                    IF (#GameFlags AND FLAG_REINFORCE) = 0 THEN
                        GOSUB ReloadHorde
                        RETURN
                    END IF
                END IF
                GOSUB LoadPatternB
            ELSE
                GOSUB StartNewWave
            END IF
        END IF
    END IF
    RETURN
END

' --------------------------------------------
' ReloadHorde - Send a second wave of aliens (relentless wave mechanic)
' Resets the grid to full and triggers fly-down entrance
' --------------------------------------------
ReloadHorde: PROCEDURE
    #GameFlags = #GameFlags OR FLAG_REINFORCE  ' Mark second horde

    ' Clean ISR state before WAIT loops (prevents cumulative frame budget leak)
    POKE $0345, 0    ' Clear _gram2_bitmap trigger
    POKE $0108, 0    ' Clear _gram2_total counter

    ' Silence SFX
    GOSUB SilenceSfx
    POKE $1F8, PEEK($1F8) OR $20  ' Disable noise on channel C
    ' Clear bullets and rogue (preserve wingman)
    GOSUB ClearBulletsAndBeam
    GOSUB ClearRogueOnly
    SPRITE SPR_PBULLET, 0, 0, 0
    SPRITE SPR_ABULLET, 0, 0, 0
    PowerUpState = 0
    ' Reset alien grid to full
    FOR LoopVar = 0 TO ALIEN_ROWS - 1
        #AlienRow(LoopVar) = $1FF
    NEXT LoopVar
    BossCount = 0 : BombExpTimer = 0 : OrbitStep = 255 : OrbitStep2 = 255
    ' Reset positions
    AlienOffsetX = 0
    AlienOffsetY = 0
    LastClearedY = 0
    AlienDir = 1
    MarchCount = 0
    CurrentMarchSpeed = BaseMarchSpeed
    ' Clear screen and redraw HUD + silhouette
    CLS
    GOSUB DrawHUD
    GOSUB DrawSilhouette
    ' Set fly-down entrance
    WaveEntrance = 2
    WaveRevealCol = ALIEN_COLS - 1
    WaveRevealRow = 6  ' Rows hidden above (counts DOWN to 0)
    RightRevealCol = ALIEN_COLS - 1
    NeedRedraw = 0  ' Reset reveal-complete gate
    ' Fire-and-forget voice, banner overlay drives display during entrance animation
    IF VOICE.AVAILABLE THEN
        VOICE PLAY reinforce_phrase
    END IF
    WaveAnnouncerTimer = 50
    WaveAnnouncerType = 3
    RETURN
END

' --------------------------------------------
' StartNewWave - Reset aliens for next wave
' --------------------------------------------
StartNewWave: PROCEDURE
    ' Clean ISR state before WAIT loops (prevents cumulative frame budget leak)
    POKE $0345, 0    ' Clear _gram2_bitmap trigger
    POKE $0108, 0    ' Clear _gram2_total counter

    ' Silence any lingering SFX (game loop UpdateSfx won't run during transition)
    SOUND 2, , 0
    SfxVolume = 0
    SfxType = 0
    ChainCount = 0  ' Reset kill chain for new wave
    #GameFlags = #GameFlags AND ($FFFF XOR FLAG_REINFORCE)  ' Clear reinforcement flag
    ' Increment level
    Level = Level + 1

    ' Set wave color palette (cycles through 6 palettes)
    LoopVar = (Level - 1) - ((Level - 1) / 6) * 6  ' MOD 6
    WaveColor0 = WavePalette0(LoopVar)
    WaveColor1 = WavePalette1(LoopVar)
    WaveColor2 = WavePalette2(LoopVar)
    WaveColor3 = WavePalette3(LoopVar)
    WaveColor4 = WavePalette4(LoopVar)

    ' March speed: same starting speed every wave (challenge comes from level variety)
    CurrentMarchSpeed = MARCH_SPEED_START

    ' Set initial music gear: always start at 0 (mid) — slow gear removed
    MusicGear = 0

    ' Reset alien positions
    AlienOffsetX = 0
    AlienOffsetY = 0
    LastClearedY = 0
    AlienDir = 1
    MarchCount = 0

    ' Reset all aliens to alive (9 bits = $1FF)
    FOR LoopVar = 0 TO ALIEN_ROWS - 1
        #AlienRow(LoopVar) = $1FF
    NEXT LoopVar

    ' Clear all boss slots
    FOR LoopVar = 0 TO MAX_BOSSES - 1
        BossHP(LoopVar) = 0
    NEXT LoopVar
    BossCount = 0 : BombExpTimer = 0 : OrbitStep = 255 : OrbitStep2 = 255

    ' Pattern A = pure small alien horde (no bosses)
    ' Bosses only appear in Pattern B formations

    ' Clear any active bullets (power-ups AND wingman persist until death!)
    GOSUB ClearBulletsAndBeam
    Sol36Timer = 0
    IF Sol36SputterTimer > 0 THEN GOSUB Sol36SputterStop
    GOSUB ClearWaveObjects
    FireCooldown = 0
    WaveRevealRow = 0
    #GameFlags = #GameFlags AND $BEFF  ' Clear FLAG_SUBWAVE + FLAG_REVEAL
    LoopVar = Level - 1
    IF LoopVar > 31 THEN LoopVar = LoopVar AND 31
    GOSUB SetEntrancePattern
    RightRevealCol = ALIEN_COLS - 1

    ' Clear screen (aliens will paint in via game loop)
    CLS

    ' Redraw HUD + silhouette (CLS wiped everything)
    GOSUB DrawHUD

    ' Redraw parallax silhouette on row 0 (CLS wiped it)
    GOSUB DrawSilhouette

    ' Silence any lingering SFX before transition WAITs
    GOSUB SilenceSfx
    POKE $1F8, PEEK($1F8) OR $20  ' Disable noise on channel C

    ' === Captured alien escape animation (after 2 waves) ===
    IF #GameFlags AND FLAG_CAPTURE THEN
        CaptureWaves = CaptureWaves + 1
        IF CaptureWaves < 2 THEN GOTO SkipEscape
        ' Load "bye!" GRAM cards into reclaimable title font slots
        DEFINE GRAM_BYE1, 2, Bye1Gfx
        WAIT

        ' Show player ship + wingman on blank screen
        SPRITE SPR_PLAYER, PlayerX + $0200, PLAYER_Y + $0100, GRAM_SHIP * 8 + COL_WHITE + $0800

        ' Phase 1: One farewell orbit (16 steps x 2 frames = 32 frames)
        FOR LoopVar = 0 TO 15
            CaptureStep = LoopVar
            RogueX = PlayerX - 4 + CaptureOrbitDX(CaptureStep) - CAPTURE_ORBIT_R
            RogueY = PLAYER_Y - 12 + CaptureOrbitDY(CaptureStep) - CAPTURE_ORBIT_R
            IF RogueX > 200 THEN RogueX = 0
            IF RogueX > 160 THEN RogueX = 160
            IF AnimFrame = 0 THEN
                SPRITE SPR_POWERUP, RogueX + SPR_VISIBLE, RogueY, GRAM_WINGMAN_F1 * 8 + CaptureColor + $0800
            ELSE
                SPRITE SPR_POWERUP, RogueX + SPR_VISIBLE, RogueY, GRAM_WINGMAN_F2 * 8 + CaptureColor + $0800
            END IF
            WAIT
            WAIT
        NEXT LoopVar

        ' Phase 2: Alien flies to center screen and pauses
        ' Target: roughly center screen (X=80, Y=44 = row 4.5 area)
        WHILE RogueX <> 80 OR RogueY <> 44
            IF RogueX < 80 THEN
                RogueX = RogueX + 2
                IF RogueX > 80 THEN RogueX = 80
            ELSEIF RogueX > 80 THEN
                IF RogueX >= 2 THEN RogueX = RogueX - 2 ELSE RogueX = 0
                IF RogueX < 80 THEN RogueX = 80
            END IF
            IF RogueY < 44 THEN
                RogueY = RogueY + 2
                IF RogueY > 44 THEN RogueY = 44
            ELSEIF RogueY > 44 THEN
                IF RogueY >= 2 THEN RogueY = RogueY - 2 ELSE RogueY = 0
                IF RogueY < 44 THEN RogueY = 44
            END IF
            IF AnimFrame = 0 THEN
                SPRITE SPR_POWERUP, RogueX + SPR_VISIBLE, RogueY, GRAM_WINGMAN_F1 * 8 + CaptureColor + $0800
            ELSE
                SPRITE SPR_POWERUP, RogueX + SPR_VISIBLE, RogueY, GRAM_WINGMAN_F2 * 8 + CaptureColor + $0800
            END IF
            WAIT
        WEND

        ' Brief pause at center
        FOR LoopVar = 0 TO 15
            WAIT
        NEXT LoopVar

        ' Phase 3: Alien says "bye!" in its color next to wingman
        Row = (RogueY - 8) / 8
        IF Row > 10 THEN Row = 10
        HitCol = (RogueX - 8) / 8 + 2
        IF HitCol > 18 THEN HitCol = 18  ' Need 2 cards side by side
        #ScreenPos = Row * 20 + HitCol
        PRINT AT #ScreenPos, GRAM_BYE1 * 8 + CaptureColor + $0800
        PRINT AT #ScreenPos + 1, GRAM_BYE2 * 8 + CaptureColor + $0800
        FOR LoopVar = 0 TO 40
            WAIT
        NEXT LoopVar

        ' Phase 4: Ship says "bye!" — 1 row above ship
        HitCol = (PlayerX - 8) / 8
        IF HitCol > 18 THEN HitCol = 18
        Row = 9 * 20 + HitCol  ' Row 9 = one tile above ship (row 10)
        PRINT AT Row, GRAM_BYE1 * 8 + COL_WHITE + $0800
        PRINT AT Row + 1, GRAM_BYE2 * 8 + COL_WHITE + $0800
        FOR LoopVar = 0 TO 45
            WAIT
        NEXT LoopVar

        ' Flash off the ship text rapidly (4 blinks)
        FOR LoopVar = 0 TO 7
            IF (LoopVar AND 1) = 0 THEN
                PRINT AT Row, 0
                PRINT AT Row + 1, 0
            ELSE
                PRINT AT Row, GRAM_BYE1 * 8 + COL_WHITE + $0800
                PRINT AT Row + 1, GRAM_BYE2 * 8 + COL_WHITE + $0800
            END IF
            WAIT
            WAIT
        NEXT LoopVar
        PRINT AT Row, 0
        PRINT AT Row + 1, 0

        ' Phase 5: Alien flies straight up off screen (3px/frame)
        PRINT AT #ScreenPos, 0      ' Clear alien "bye!"
        PRINT AT #ScreenPos + 1, 0
        WHILE RogueY > 0
            IF RogueY >= 3 THEN
                RogueY = RogueY - 3
            ELSE
                RogueY = 0
            END IF
            IF AnimFrame = 0 THEN
                SPRITE SPR_POWERUP, RogueX + SPR_VISIBLE, RogueY, GRAM_WINGMAN_F1 * 8 + CaptureColor + $0800
            ELSE
                SPRITE SPR_POWERUP, RogueX + SPR_VISIBLE, RogueY, GRAM_WINGMAN_F2 * 8 + CaptureColor + $0800
            END IF
            WAIT
        WEND

        ' Clear capture state
        SPRITE SPR_POWERUP, 0, 0, 0
        SPRITE SPR_PLAYER, 0, 0, 0
        #GameFlags = #GameFlags AND $FFF3  ' Clear FLAG_CAPTURE + FLAG_CAPBULLET
        CaptureStep = 0
        CaptureTimer = 0

        ' Brief pause after fly-off
        FOR LoopVar = 0 TO 10
            WAIT
        NEXT LoopVar

        ' Restore powerup HUD GRAM cards (bye! overwrote slots 25-26)
        IF BeamTimer > 0 THEN
            DEFINE GRAM_PWR1, 2, PowerupBeamGfx
        ELSEIF RapidTimer > 0 THEN
            DEFINE GRAM_PWR1, 2, PowerupRapidGfx
        ELSEIF #GameFlags AND FLAG_BOMB THEN
            DEFINE GRAM_PWR1, 2, PowerupBombGfx
        ELSEIF Sol36Timer > 0 THEN
            DEFINE GRAM_PWR1, 3, PowerupSol36Gfx
        END IF
        WAIT
    SkipEscape:
    END IF

    ' Re-define warp-in animation cards (TinyFont label round-robin overwrites during gameplay)
    DEFINE GRAM_WARP1, 3, WarpInGfx1    ' Cards 34-36: Warp-in animation
    WAIT

    ' Fire-and-forget voice + music, then launch banner overlay (displays during entrance)
    IF VOICE.AVAILABLE THEN
        VOICE PLAY wave_phrase        ' Say "WAVE"
        VOICE NUMBER Level            ' Say the number
    END IF
    PLAY si_bg_mid
    WaveAnnouncerTimer = 90
    WaveAnnouncerType = 1
    ' Reset spin state and pre-load GRAM cards for WAVE spin-out animation
    WaveBannerPhase = 0
    WaveBannerFrame = 0
    DEFINE GRAM_FONT_T, 1, WaveSpinWGfx     ' Card 32 = W narrow (first spin phase)
    DEFINE GRAM_ORBITER, 1, WaveSpinEdgeGfx ' Card 47 = edge-on (shared all phases)
    ' Brief pause for CLS to settle before entrance animation begins
    FOR LoopVar = 0 TO 13
        WAIT
    NEXT LoopVar

    RETURN
END

' Intellivoice speech data
wave_phrase:
    VOICE WW, EY, VV, PA2, 0

extra_life_phrase:
    VOICE EH, EH, KK1, SS, TT1, RR1, AX, PA2, LL, AY, FF, PA1, 0

beam_phrase:
    VOICE BB1, IH, GG1, PA1, LL, EY, ZZ, ER1, PA1, 0

rapid_phrase:
    VOICE RR1, AA, PP, IH, DD2, PA1, FF, AY, ER1, PA1, 0

bomb_phrase:
    VOICE BB1, AO, MM, BB2, PA1, 0

mega_phrase:
    VOICE SS, OW, LL, PA2, TH, ER1, TT2, IY, PA1, SS, IH, KK2, SS, PA1, 0

shield_phrase:
    VOICE SH, IY, LL, DD1, PA1, AO, NN1, PA1, 0

shields_down_phrase:
    VOICE SH, IY, LL, DD1, ZZ, PA2, DD1, AW, NN1, PA1, 0

game_over_phrase:
    VOICE GG1, EY, MM, PA2, OW, VV, ER1, PA2, 0

auto_on_phrase:
    VOICE AO, TT2, OW, PA2, AO, NN1, PA1, 0

auto_off_phrase:
    VOICE AO, TT2, OW, PA2, AO, FF, PA1, 0

reinforce_phrase:
    VOICE IH, NN1, KK2, AX, MM, IH, NN1, PA2, HH1, OR, DD1, PA1, 0

' Saucer primary/secondary colors per power-up type
' Index by PowerUpType (0=beam, 1=rapid, 2=bomb, 3=mega, 4=shield)
SaucerColor1:
    DATA COL_BLUE, COL_YELLOW, COL_YELLOW, COL_RED, COL_CYAN
SaucerColor2:
    DATA COL_WHITE, COL_GREEN, COL_RED, COL_TAN, COL_BLUE

' Power-up weighted distribution (8 slots)
' beam=2, rapid=2, bomb=2, mega=1, shield=1
