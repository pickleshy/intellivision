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
    IF SfxVolume = 0 THEN
        IF FlyState > 0 THEN
            ' Saucer ambient: lawnmower bass wobble (~124Hz <-> ~101Hz)
            ' Toggles every 8 frames (~7.5Hz) — motor-cycling putt-putt rate
            ' Period 1800/2200 = very deep bass square wave
            IF ShimmerCount AND 8 THEN
                SOUND 2, 1800, 8
            ELSE
                SOUND 2, 2200, 8
            END IF
        ELSE
            SOUND 2, , 0  ' Silence channel C (covers saucer leaving screen without kill)
        END IF
        RETURN
    END IF

    ' All SFX on channel 3 (SOUND 2) to coexist with PLAY SIMPLE music
    SOUND 2, #SfxPitch, SfxVolume

    ' Decay based on type
    IF SfxType = 2 THEN
        ' Saucer crash: slow decay + descending pitch (sustained crunch)
        POKE $1F8, PEEK($1F8) OR $20   ' Noise C off — clear stale state from pea shot
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
        POKE $1F8, PEEK($1F8) OR $20   ' Noise C off — clear stale state from pea shot
        #SfxPitch = #SfxPitch + 12
        IF SfxVolume > 3 THEN
            SfxVolume = SfxVolume - 3
        ELSE
            SfxVolume = 0
        END IF
    ELSEIF SfxType = 7 THEN
        ' Pea shooter: pure noise burst — classic Intellivision shot crack
        ' Period 6 (~9.3kHz) drifts to ~15 (~3.7kHz) as vol drops = crack → pop → gone
        ' #SfxPitch = 0 → tone at ~56kHz (ultrasonic, silent) — noise does all the work
        ' Total: ~4 frames at -3/frame = ~67ms, short and punchy
        #SfxPitch = 0
        POKE $1F9, 6 + (12 - SfxVolume)    ' Period 6→~14 as vol drops (crack deepens)
        POKE $1F8, PEEK($1F8) AND $DF       ' Noise C on
        IF SfxVolume > 3 THEN
            SfxVolume = SfxVolume - 3
        ELSE
            SfxVolume = 0
        END IF
    ELSEIF SfxType = 8 THEN
        ' Bomb launch: deep bass thrum + crack + whoosh arc (~28 frames, 0.47 sec)
        ' Phase 1 (vol>=12, ~4 frames): tone 2000 (~112Hz) + noise 4 (~14kHz)
        '   = deep bass thrum layered with bright crack — cannon body + punch
        '   $DB clears bits 2+5: enables both tone C AND noise C
        ' Phase 2 (vol 7-11, ~10 frames): noise 15 (~3.7kHz) — mid hiss
        '   tone switches to inaudible 4000 (~56Hz)
        ' Phase 3 (vol<=6, ~14 frames): noise 28 (~2kHz) — deep whoosh
        IF SfxVolume >= 12 THEN
            POKE $1F9, 4
            POKE $1F8, PEEK($1F8) AND $DB  ' Enable tone C + noise C (bass thrum + crack)
        ELSEIF SfxVolume >= 7 THEN
            #SfxPitch = 4000               ' Switch tone to inaudible
            POKE $1F9, 15
            POKE $1F8, PEEK($1F8) AND $DF  ' Noise C only
        ELSE
            POKE $1F9, 28
            POKE $1F8, PEEK($1F8) AND $DF  ' Noise C only
        END IF
        ' Decay every other frame (ShimmerCount parity) — doubles total duration
        IF (ShimmerCount AND 1) = 0 THEN
            IF SfxVolume > 1 THEN
                SfxVolume = SfxVolume - 1
            ELSE
                SfxVolume = 0
            END IF
        END IF
    ELSEIF SfxType = 9 THEN
        ' Shield impact: lasery crash — high noise+tone attack, descending laser tail
        ' Period 65→215 over 7 frames @ +25/frame: 3.4kHz→828Hz (bright → mid)
        ' Attack (vol>=9, ~3 frames): noise period 4 (~14kHz) + tone = crash impact crack
        ' Tail   (vol<9,  ~4 frames): pure tone, still descending = laser bleed-off
        ' Vol 13 @ -2/frame: 7 frames (~117ms) — punchy but not lingering
        #SfxPitch = #SfxPitch + 25     ' Sweep down in frequency each frame
        IF SfxVolume >= 9 THEN
            POKE $1F9, 4               ' High noise ~14kHz = crash impact
            POKE $1F8, PEEK($1F8) AND $DB  ' Tone C + noise C
        ELSE
            POKE $1F8, PEEK($1F8) OR $20   ' Tone C only = laser tail
        END IF
        IF SfxVolume > 2 THEN
            SfxVolume = SfxVolume - 2
        ELSE
            SfxVolume = 0
        END IF
    ELSEIF SfxType = 10 THEN
        ' Zod death: soft descending cry — heard frequently, must not grate
        ' Starts ~2556 Hz (pitch 70), slides ~1 octave over ~10 frames at vol 10
        POKE $1F8, PEEK($1F8) OR $20   ' Noise C off — clear stale state from pea shot
        #SfxPitch = #SfxPitch + 15
        IF SfxVolume > 1 THEN
            SfxVolume = SfxVolume - 1
        ELSE
            SfxVolume = 0
        END IF
    ELSEIF SfxType = 11 THEN
        ' Auto-fire machine gun chk: deep thunk, muted, repeats at bullet cadence
        ' Tone 1500 (~149Hz) + noise 26 (~2.1kHz) layered = deeper chunky body
        ' $DB enables both tone C + noise C for each short burst
        POKE $1F9, 26
        POKE $1F8, PEEK($1F8) AND $DB  ' Enable tone C + noise C
        IF SfxVolume > 5 THEN
            SfxVolume = SfxVolume - 5
        ELSE
            SfxVolume = 0
        END IF
    ELSEIF SfxType = 12 THEN
        ' Saucer kill: metallic "schwing" — noisy schw attack + long tonal ring
        ' Pitch ~1118Hz (period 200), gentle drift +2/frame = natural ring decay feel
        ' Attack (vol>=12, ~2 frames at -3/frame): noise period 8 (~7kHz) + tone ($DB)
        '   = "schw" metallic blade/impact
        ' Ring (vol<12): pure tone only, decay every other frame = ~18 frame sustain
        #SfxPitch = #SfxPitch + 2
        IF SfxVolume >= 12 THEN
            POKE $1F9, 8
            POKE $1F8, PEEK($1F8) AND $DB  ' Tone C + noise C = schw attack
            IF SfxVolume > 3 THEN
                SfxVolume = SfxVolume - 3
            ELSE
                SfxVolume = 0
            END IF
        ELSE
            POKE $1F8, PEEK($1F8) OR $20   ' Tone C only = pure metallic ring
            IF (ShimmerCount AND 1) = 0 THEN
                IF SfxVolume > 1 THEN
                    SfxVolume = SfxVolume - 1
                ELSE
                    SfxVolume = 0
                END IF
            END IF
        END IF
    ELSEIF SfxType = 13 THEN
        ' Powerup pickup: metallic belt-buckle snap + rising tonal ring (~7 frames)
        ' Period sweeps 600→250 (-50/frame) = rising pitch ~373Hz→890Hz = positive acquire feel
        ' Attack (vol>=10, ~2 frames): noise period 6 (~9kHz) + tone ($DB) = metallic clank
        ' Ring (vol<10, ~5 frames): pure tone only ($20), rising pitch sustain
        IF #SfxPitch > 50 THEN
            #SfxPitch = #SfxPitch - 50    ' Sweep up: rising pitch = "acquired!" feel
        END IF
        IF SfxVolume >= 10 THEN
            POKE $1F9, 6
            POKE $1F8, PEEK($1F8) AND $DB  ' Tone C + noise C = metallic snap
            IF SfxVolume > 3 THEN
                SfxVolume = SfxVolume - 3
            ELSE
                SfxVolume = 0
            END IF
        ELSE
            POKE $1F8, PEEK($1F8) OR $20   ' Tone C only = clean ring
            IF SfxVolume > 2 THEN
                SfxVolume = SfxVolume - 2
            ELSE
                SfxVolume = 0
            END IF
        END IF
    ELSEIF SfxType = 14 THEN
        ' Alien kill: spongey bwop — pure tone, slow decay, gentle pitch descent
        ' Period 180→444 over 12 frames @ +22/frame: 1.24kHz→505Hz (mid → mid-low)
        ' Vol 12 @ -1/frame: 12→1→0 = 12 frames (~200ms) — real body, not a blip
        ' Pure tone only — no noise keeps the attack soft and rounded
        POKE $1F8, PEEK($1F8) OR $20   ' Noise C off — pure tone only
        #SfxPitch = #SfxPitch + 22     ' Gentle pitch descent each frame
        IF SfxVolume > 1 THEN
            SfxVolume = SfxVolume - 1
        ELSE
            SfxVolume = 0
        END IF
    ELSE
        ' Misc tonal SFX (SfxType 1): wingman pew, boss ping, soft zap
        ' Pure tone, no noise — clear any stale noise C from prior SFX
        POKE $1F8, PEEK($1F8) OR $20   ' Noise C off
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
                            ' SOL-36 skeleton: record every killed normal alien as a row bit
                            ' SkeletonPos = bitmask for left column (Sol36Col), SkeletonRowsB for right
                            ' ColMaskData(LoopVar) gives bit values 1,2,4,8,16 for rows 0-4
                            IF FoundBoss = 255 THEN
                                IF HitRow = 0 THEN
                                    SkeletonPos = SkeletonPos OR ColMaskData(LoopVar)
                                ELSE
                                    SkeletonRowsB = SkeletonRowsB OR ColMaskData(LoopVar)
                                END IF
                                IF SkeletonTimer = 0 THEN
                                    DEFINE GRAM_SKELETON, 1, IntruderSkeletonGfx
                                END IF
                                SkeletonTimer = 15
                            END IF
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
                SfxType = 12 : SfxVolume = 15 : #SfxPitch = 200
                SOUND 2, 200, 15
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
    SfxType = 10 : SfxVolume = 10 : #SfxPitch = 70
    SOUND 2, 70, 10
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
    ' Restore GRAM_SKELETON (card 16) to ExplosionGfx3 if beam ended before timer expired
    IF SkeletonTimer > 0 THEN
        SkeletonTimer = 0
        DEFINE GRAM_SKELETON, 1, ExplosionGfx3
    END IF
    SkeletonPos = 0 : SkeletonRowsB = 0
    RETURN
END

' --------------------------------------------
' Sol36SputterStop - Force-end sputter (death/wave transition)
' Restores solid beam GRAM card and silences SFX
' --------------------------------------------
Sol36SputterStop: PROCEDURE
    Sol36SputterTimer = 0
    GOSUB Sol36Clear
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
        ' Spurt 2: rapid alternating flicker, red/orange
        ' NOTE: COL_ORANGE=10 corrupts BACKTAB card field (bits 3-8), showing GRAM_ORBITER (card 47)
        ' instead of GRAM_SOL36 (card 46). Use COL_RED=2 which appears orange-red on Intellivision.
        IF (Sol36SputterTimer AND 1) THEN AlienColor = COL_RED
    END IF
    ' Skip fizzle: end immediately when spurt 2 finishes (avoids stale tile flash)
    IF Sol36SputterTimer < 5 THEN Sol36SputterTimer = 0

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

    ' End of sputter: clear column, restore solid beam card
    IF Sol36SputterTimer = 0 THEN
        GOSUB Sol36Clear
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
    BossCount = 0 : BombExpTimer = 0 : ExplosionTimer = 0 : OrbitStep = 255 : OrbitStep2 = 255 : SkeletonTimer = 0 : SkeletonPos = 0 : SkeletonRowsB = 0 : WingmanExpTimer = 0

    ' ── LEVEL DESIGN: Boss Placement — data-driven (edit tables in data_tables.bas) ──
    ' BossHeader bits: 0-2=BossCount, 3=OrbitStep=0, 4=OrbitStep2=5
    ' BossColRow: col(bits 0-3) + row(bits 4-7).  BossAttrs: hp(0-2)+color(3-6)+type(7)
    HitCol = (Level - 1) AND 31       ' 0-based wave index 0-31
    Row = BossHeader(HitCol)
    BossCount = Row AND 7
    IF Row AND 8 THEN OrbitStep = 0
    IF Row AND 16 THEN OrbitStep2 = 5
    HitRow = HitCol + HitCol : HitRow = HitRow + HitRow   ' wave index * 4 = boss slot base
    IF BossCount > 0 THEN
        FOR LoopVar = 0 TO BossCount - 1
            Col = HitRow + LoopVar
            Row = BossColRow(Col)
            BossCol(LoopVar) = Row AND 15
            BossRow(LoopVar) = Row / 16
            Row = BossAttrs(Col)
            BossHP(LoopVar) = Row AND 7
            BossColor(LoopVar) = (Row / 8) AND 15
            BossType(LoopVar) = Row / 128
        NEXT LoopVar
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
    BossCount = 0 : BombExpTimer = 0 : ExplosionTimer = 0 : OrbitStep = 255 : OrbitStep2 = 255 : SkeletonTimer = 0 : SkeletonPos = 0 : SkeletonRowsB = 0 : WingmanExpTimer = 0
    ' Reset positions
    GOSUB ResetAlienGrid
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
    GOSUB ResetAlienGrid

    ' Reset all aliens to alive (9 bits = $1FF)
    FOR LoopVar = 0 TO ALIEN_ROWS - 1
        #AlienRow(LoopVar) = $1FF
    NEXT LoopVar

    ' Clear all boss slots
    FOR LoopVar = 0 TO MAX_BOSSES - 1
        BossHP(LoopVar) = 0
    NEXT LoopVar
    BossCount = 0 : BombExpTimer = 0 : ExplosionTimer = 0 : OrbitStep = 255 : OrbitStep2 = 255 : SkeletonTimer = 0 : SkeletonPos = 0 : SkeletonRowsB = 0 : WingmanExpTimer = 0

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

zod_phrase:
    VOICE ZZ, AA, AA, AA, DD1, PA1, 0

zod_death_phrase:
    VOICE ZZ, AA, AA, AA, AA, DD1, PA1, 0

' Saucer primary/secondary colors per power-up type
' Index by PowerUpType (0=beam, 1=rapid, 2=bomb, 3=mega, 4=shield)
SaucerColor1:
    DATA COL_BLUE, COL_YELLOW, COL_YELLOW, COL_RED, COL_CYAN
SaucerColor2:
    DATA COL_WHITE, COL_GREEN, COL_RED, COL_TAN, COL_BLUE

' Power-up weighted distribution (8 slots)
' beam=2, rapid=2, bomb=2, mega=1, shield=1
