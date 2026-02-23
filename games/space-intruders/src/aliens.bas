' ============================================
' SPACE INTRUDERS - Alien Grid Module
' ============================================
' Alien grid physics, rendering, and drawing optimization
' Segment: 2 (CRITICAL - contains DRAW_ROW_FAST ASM routine)

    SEGMENT 2

' === Alien Grid System ===

' --------------------------------------------
' UpdateOrbiter - Sprite crab orbiting bomb boss (SPR_FLYER, GRAM_ORBITER card 47)
' SmallCrabF1Gfx defined on card 47 at StartGame.
' Both orbiters alternate SPR_FLYER each frame (30fps each) when both active.
' Path: 10-step clockwise square around the 2-wide boss. OrbitDX/OrbitDY biased +1.
' --------------------------------------------
UpdateOrbiter: PROCEDURE
    ' Advance OrbitStep every 8 frames; deactivate when boss is dead
    IF OrbitStep < 10 THEN
        IF BossHP(0) = 0 THEN
            OrbitStep = 255
        ELSEIF ShimmerCount = 0 OR ShimmerCount = 8 THEN
            OrbitStep = OrbitStep + 1
            IF OrbitStep >= 10 THEN OrbitStep = 0
        END IF
    END IF
    ' Advance OrbitStep2 every 8 frames; deactivate when boss is dead
    IF OrbitStep2 < 10 THEN
        IF BossHP(1) = 0 THEN
            OrbitStep2 = 255
        ELSEIF ShimmerCount = 0 OR ShimmerCount = 8 THEN
            OrbitStep2 = OrbitStep2 + 1
            IF OrbitStep2 >= 10 THEN OrbitStep2 = 0
        END IF
    END IF
    ' Animate orbiter GRAM card: swap frames every 4 frames (bit 2 of ShimmerCount)
    IF OrbitStep < 10 OR OrbitStep2 < 10 THEN
        IF ShimmerCount AND 4 THEN
            DEFINE GRAM_ORBITER, 1, SmallCrabF2Gfx
        ELSE
            DEFINE GRAM_ORBITER, 1, SmallCrabF1Gfx
        END IF
    END IF

    ' Position SPR_FLYER; alternate between orbiters each frame when both active
    IF OrbitStep < 10 THEN
        IF OrbitStep2 < 10 AND (ShimmerCount AND 1) THEN
            ' Both active, odd frame: show orbiter 1
            Col = AlienOffsetX + BossCol(1) + OrbitDX(OrbitStep2) - 1
            Row = AlienOffsetY + BossRow(1) + OrbitDY(OrbitStep2)
        ELSE
            ' Orbiter 0 only, or even frame: show orbiter 0
            Col = AlienOffsetX + BossCol(0) + OrbitDX(OrbitStep) - 1
            Row = AlienOffsetY + BossRow(0) + OrbitDY(OrbitStep)
        END IF
        SPRITE SPR_FLYER, Col * 8 + 8 + SPR_VISIBLE, Row * 8 + 8, GRAM_ORBITER * 8 + COL_YELLOW + $0800
    ELSEIF OrbitStep2 < 10 THEN
        ' Only orbiter 1 active
        Col = AlienOffsetX + BossCol(1) + OrbitDX(OrbitStep2) - 1
        Row = AlienOffsetY + BossRow(1) + OrbitDY(OrbitStep2)
        SPRITE SPR_FLYER, Col * 8 + 8 + SPR_VISIBLE, Row * 8 + 8, GRAM_ORBITER * 8 + COL_YELLOW + $0800
    ELSE
        ' Both orbiters inactive — hide sprite and clear cleanup flag
        SPRITE SPR_FLYER, 0, 0, 0
        OrbiterDeathTimer = 0
    END IF
    RETURN
END

' --------------------------------------------
' OrbiterHitEffect - Shared explosion/score/chain/SFX for orbiter kills
' Input: HitRow, HitCol = grid position of hit
' Shows same BACKTAB explosion flash as regular alien deaths.
' --------------------------------------------
' --------------------------------------------
' ClearOrbitPath - Clear alive aliens from the 8 surrounding cells of an orbiter boss
' Input: AlienGridRow = boss row, AlienGridCol = boss left column
' Iterates all 10 OrbitDX/OrbitDY steps; skips the boss's own 2 cells.
' Call after force-setting boss cells alive and after grid normalization.
' --------------------------------------------
ClearOrbitPath: PROCEDURE
    FOR LoopVar = 0 TO 9
        Row = AlienGridRow + OrbitDY(LoopVar)
        IF Row < ALIEN_ROWS THEN
            ' Guard unsigned underflow: AlienGridCol + OrbitDX - 1 could be -1
            IF AlienGridCol + OrbitDX(LoopVar) >= 1 THEN
                Col = AlienGridCol + OrbitDX(LoopVar) - 1
                IF Col < ALIEN_COLS THEN
                    ' Don't clear the boss's own 2 cells (row=BossRow, col=BossCol or BossCol+1)
                    IF Row <> AlienGridRow OR (Col <> AlienGridCol AND Col <> AlienGridCol + 1) THEN
                        #Mask = ColMaskData(Col)
                        IF #AlienRow(Row) AND #Mask THEN
                            #AlienRow(Row) = #AlienRow(Row) XOR #Mask
                        END IF
                    END IF
                END IF
            END IF
        END IF
    NEXT LoopVar
    RETURN
END

OrbiterHitEffect: PROCEDURE
    ' Kill any alive alien at this grid position so the cell stays blank after
    ' the explosion fades (otherwise DrawAliens redraws the alive alien every frame,
    ' making it look like the orbiter survived the hit).
    IF HitRow >= ALIEN_START_Y + AlienOffsetY THEN
        IF HitRow < ALIEN_START_Y + AlienOffsetY + ALIEN_ROWS THEN
            IF HitCol >= ALIEN_START_X + AlienOffsetX THEN
                IF HitCol < ALIEN_START_X + AlienOffsetX + ALIEN_COLS THEN
                    AlienGridRow = HitRow - ALIEN_START_Y - AlienOffsetY
                    AlienGridCol = HitCol - ALIEN_START_X - AlienOffsetX
                    #Mask = ColMaskData(AlienGridCol)
                    IF #AlienRow(AlienGridRow) AND #Mask THEN
                        #AlienRow(AlienGridRow) = #AlienRow(AlienGridRow) XOR #Mask
                    END IF
                END IF
            END IF
        END IF
    END IF
    ' Explosion flash
    #ScreenPos = HitRow * 20 + HitCol
    IF #ScreenPos < 220 THEN
        GOSUB ClearPrevExplosion
        #ExplosionPos = #ScreenPos
        ExplosionTimer = 15
        PRINT AT #ScreenPos, GRAM_EXPLOSION * 8 + 4 + $1800
    END IF
    #GameFlags = #GameFlags AND $FFFE  ' Kill bullet
    #GameFlags = #GameFlags OR FLAG_SHOTLAND
    GOSUB BumpChain
    #Mask = 25 : GOSUB AddToScore
    SfxType = 1 : SfxVolume = 12 : #SfxPitch = 1800
    SOUND 2, 1800, 12
    RETURN
END

' --------------------------------------------
' KillBossesInBlast - Kill all bosses in 4-wide × 3-tall blast radius
' Prereq: BombExpRow/BombExpCol set to grid center of explosion
' --------------------------------------------
KillBossesInBlast: PROCEDURE
    FOR LoopVar = 0 TO BossCount - 1
        IF BossHP(LoopVar) > 0 THEN
            IF BossRow(LoopVar) >= BombExpRow - 1 THEN
            IF BossRow(LoopVar) <= BombExpRow + 1 THEN
                IF BossCol(LoopVar) + 1 >= BombExpCol - 1 THEN
                IF BossCol(LoopVar) <= BombExpCol + 2 THEN
                    Row = BossRow(LoopVar)
                    Col = BossCol(LoopVar)
                    BossHP(LoopVar) = 0
                    #Mask = ColMaskData(Col)
                    IF #AlienRow(Row) AND #Mask THEN
                        #AlienRow(Row) = #AlienRow(Row) XOR #Mask
                    END IF
                    #Mask = ColMaskData(Col + 1)
                    IF #AlienRow(Row) AND #Mask THEN
                        #AlienRow(Row) = #AlienRow(Row) XOR #Mask
                    END IF
                    #Mask = 10 : GOSUB AddToScore
                END IF
                END IF
            END IF
            END IF
        END IF
    NEXT LoopVar
    RETURN
END

' --------------------------------------------
' TriggerPlayerBomb - Trigger area bomb explosion from player weapon
' Prereq: AlienGridRow/AlienGridCol set to hit grid position
' --------------------------------------------
TriggerPlayerBomb: PROCEDURE
    IF #GameFlags AND FLAG_BOMB THEN
        #GameFlags = #GameFlags AND $FFFE  ' Kill bullet
        IF BombExpTimer = 0 THEN
            BombExpRow = AlienGridRow
            BombExpCol = AlienGridCol
            GOSUB PlayerBombExplode
        END IF
    END IF
    RETURN
END

' --------------------------------------------
' DrawPressFire_Grey - Draw "PRESS FIRE" text in grey (color 8 / $1800)
' Used on title screen and game-over screen
' --------------------------------------------
DrawPressFire_Grey: PROCEDURE
    PRINT AT 205, GRAM_FONT_P * 8 + $1800
    PRINT AT 206, GRAM_FONT_R * 8 + $1800
    PRINT AT 207, GRAM_FONT_E * 8 + $1800
    PRINT AT 208, GRAM_FONT_S * 8 + $1800
    PRINT AT 209, GRAM_FONT_S * 8 + $1800
    PRINT AT 210, 0
    PRINT AT 211, GRAM_FONT_F * 8 + $1800
    PRINT AT 212, GRAM_FONT_I * 8 + $1800
    PRINT AT 213, GRAM_FONT_R * 8 + $1800
    PRINT AT 214, GRAM_FONT_E * 8 + $1800
    RETURN
END

' --------------------------------------------
' DrawPressFire_White - Draw "PRESS FIRE" text in white (color 7 / COL_WHITE)
' Used on title screen and game-over screen
' --------------------------------------------
DrawPressFire_White: PROCEDURE
    PRINT AT 205, GRAM_FONT_P * 8 + COL_WHITE + $0800
    PRINT AT 206, GRAM_FONT_R * 8 + COL_WHITE + $0800
    PRINT AT 207, GRAM_FONT_E * 8 + COL_WHITE + $0800
    PRINT AT 208, GRAM_FONT_S * 8 + COL_WHITE + $0800
    PRINT AT 209, GRAM_FONT_S * 8 + COL_WHITE + $0800
    PRINT AT 210, 0
    PRINT AT 211, GRAM_FONT_F * 8 + COL_WHITE + $0800
    PRINT AT 212, GRAM_FONT_I * 8 + COL_WHITE + $0800
    PRINT AT 213, GRAM_FONT_R * 8 + COL_WHITE + $0800
    PRINT AT 214, GRAM_FONT_E * 8 + COL_WHITE + $0800
    RETURN
END

' --------------------------------------------
' ShimmerPressFire - Advance shimmer counter and draw PRESS FIRE in grey or white
' Uses PowerUpType as counter (0-3), WavePhase for palette index
' Called every frame from title screen and game-over screen
' --------------------------------------------
ShimmerPressFire: PROCEDURE
    PowerUpType = PowerUpType + 1
    IF PowerUpType >= 4 THEN
        PowerUpType = 0
        WavePhase = WavePhase + 1
        IF WavePhase >= 4 THEN WavePhase = 0
        IF WaveColors(WavePhase) = 0 THEN
            GOSUB DrawPressFire_Grey
        ELSE
            GOSUB DrawPressFire_White
        END IF
    END IF
    RETURN
END

' --------------------------------------------
' BombExplode - Chain explosion when bomb alien dies
' Expects: FoundBoss = the bomb's slot index (already HP=0)
' Kills all aliens in 4-wide × 3-tall blast radius
' --------------------------------------------
BombExplode: PROCEDURE
    ' Save bomb position for chain explosion rendering
    BombExpRow = BossRow(FoundBoss)
    BombExpCol = BossCol(FoundBoss)
    BombExpTimer = 30
    ' Kill the orbiter matching this bomb boss slot; set OrbiterDeathTimer so
    ' UpdateOrbiter runs one more frame after this to hide SPR_FLYER (it already
    ' ran earlier this frame and drew the sprite before BombExplode fired).
    IF FoundBoss = 0 THEN OrbitStep = 255 : OrbiterDeathTimer = 1
    IF FoundBoss = 1 THEN OrbitStep2 = 255 : OrbiterDeathTimer = 1

    ' Clear bomb's own two columns (guarded to prevent resurrection)
    #Mask = ColMaskData(BombExpCol)
    IF #AlienRow(BombExpRow) AND #Mask THEN
        #AlienRow(BombExpRow) = #AlienRow(BombExpRow) XOR #Mask
    END IF
    #Mask = ColMaskData(BombExpCol + 1)
    IF #AlienRow(BombExpRow) AND #Mask THEN
        #AlienRow(BombExpRow) = #AlienRow(BombExpRow) XOR #Mask
    END IF

    ' Kill all bosses in blast radius
    GOSUB KillBossesInBlast

    ' XOR out all regular aliens in blast radius (no FindBoss needed now)
    FOR Row = BombExpRow - 1 TO BombExpRow + 1
        IF Row >= 0 THEN
        IF Row < ALIEN_ROWS THEN
            FOR Col = BombExpCol - 1 TO BombExpCol + 2
                IF Col >= 0 THEN
                IF Col < ALIEN_COLS THEN
                    ' Skip the bomb's own cells (already XOR'd above)
                    IF Row = BombExpRow THEN
                        IF Col = BombExpCol OR Col = BombExpCol + 1 THEN
                            Col = Col  ' No-op, let loop continue
                        ELSE
                            ' Kill regular alien at this position (bosses already handled)
                            #Mask = ColMaskData(Col)
                            IF #AlienRow(Row) AND #Mask THEN
                                #AlienRow(Row) = #AlienRow(Row) XOR #Mask
                                #Mask = 10 : GOSUB AddToScore
                            END IF
                        END IF
                    ELSE
                        ' Different row — kill regular alien
                        #Mask = ColMaskData(Col)
                        IF #AlienRow(Row) AND #Mask THEN
                            #AlienRow(Row) = #AlienRow(Row) XOR #Mask
                            #Mask = 10 : GOSUB AddToScore
                        END IF
                    END IF
                END IF
                END IF
            NEXT Col
        END IF
        END IF
    NEXT Row

    ' Score for bomb itself
    #Mask = BOMB_SCORE : GOSUB AddToScore

    ' Big SFX (white noise boom, same as ship explosion)
    SfxType = 5 : SfxVolume = 15 : #SfxPitch = 0
    SOUND 2, 0, 15

    ' Screen shake for the explosion
    ShakeTimer = 20

    RETURN
END

' PlayerBombExplode — area explosion from player bomb weapon
' Prereq: BombExpRow/BombExpCol set to grid coordinates of hit
' Lives in Seg 4 to relieve Seg 2 pressure; cross-segment GOSUB works with MAP 2.
    SEGMENT 4
PlayerBombExplode: PROCEDURE
    BombExpTimer = 30

    ' Kill all bosses in blast radius
    GOSUB KillBossesInBlast

    ' Kill regular aliens in blast radius
    FOR Row = BombExpRow - 1 TO BombExpRow + 1
        IF Row >= 0 THEN
        IF Row < ALIEN_ROWS THEN
            FOR Col = BombExpCol - 1 TO BombExpCol + 2
                IF Col >= 0 THEN
                IF Col < ALIEN_COLS THEN
                    #Mask = ColMaskData(Col)
                    IF #AlienRow(Row) AND #Mask THEN
                        #AlienRow(Row) = #AlienRow(Row) XOR #Mask
                        #Mask = 10 : GOSUB AddToScore
                    END IF
                END IF
                END IF
            NEXT Col
        END IF
        END IF
    NEXT Row

    ' Boom SFX + screen shake
    SfxType = 5 : SfxVolume = 15 : #SfxPitch = 0
    SOUND 2, 0, 15
    ShakeTimer = 20
    NeedRedraw = 1

    RETURN
END

    ' ============================================================
    ' Back to SEGMENT 2 — COLLISION LOGIC & ALIEN DRAWING
    ' ============================================================
    SEGMENT 2

' --------------------------------------------
' CheckOneColumn - Check single column for alien hit
' Expects: HitCol, HitRow, AlienGridRow set
' --------------------------------------------
CheckOneColumn: PROCEDURE
    IF HitCol >= ALIEN_START_X + AlienOffsetX THEN
        IF HitCol < ALIEN_START_X + AlienOffsetX + ALIEN_COLS THEN
            AlienGridCol = HitCol - ALIEN_START_X - AlienOffsetX

            ' Can't hit unrevealed columns during wave sweep-in
            IF AlienGridCol > WaveRevealCol THEN RETURN

            ' Calculate bitmask for this column
            #Mask = ColMaskData(AlienGridCol)

            IF #AlienRow(AlienGridRow) AND #Mask THEN
                ' Multi-boss intercept
                GOSUB FindBossAtCell
                IF FoundBoss < 255 THEN
                    BossHP(FoundBoss) = BossHP(FoundBoss) - 1
                    ' Beam: apply second hit to same boss if budget remains
                    IF BeamTimer > 0 THEN
                        BeamHits = BeamHits - 1  ' audit-ignore: bullet cleared when BeamHits=0 prevents re-entry
                        IF BeamHits > 0 THEN
                            IF BossHP(FoundBoss) > 0 THEN
                                BossHP(FoundBoss) = BossHP(FoundBoss) - 1
                                BeamHits = BeamHits - 1  ' audit-ignore: guarded by IF BeamHits > 0 above
                            END IF
                        END IF
                    END IF
                    IF BossHP(FoundBoss) > 0 THEN
                        ' Damaged but alive — stop bullet unless beam has hits left
                        IF BeamTimer = 0 OR BeamHits = 0 THEN
                            #GameFlags = #GameFlags AND $FFFE
                        END IF
                        #GameFlags = #GameFlags OR FLAG_SHOTLAND  ' Hit landed — chain preserved
                        GOSUB UpdateBossColor
                        SfxType = 1 : SfxVolume = 14 : #SfxPitch = 220
                        SOUND 2, 220, 14
                        ' Bomb weapon: area explosion even on non-kill hit
                        GOSUB TriggerPlayerBomb
                        RETURN
                    ELSE
                        ' Boss dead! Check type
                        IF BossType(FoundBoss) = BOMB_TYPE THEN
                            ' Bomb alien — chain explosion!
                            IF BeamTimer = 0 OR BeamHits = 0 THEN
                                #GameFlags = #GameFlags AND $FFFE
                            END IF
                            #GameFlags = #GameFlags OR FLAG_SHOTLAND
                            GOSUB BumpChain
                            GOSUB BombExplode
                            RETURN
                        ELSE
                            ' Skull boss dead!
                            IF BeamTimer = 0 OR BeamHits = 0 THEN
                                #GameFlags = #GameFlags AND $FFFE
                            END IF
                            #GameFlags = #GameFlags OR FLAG_SHOTLAND
                            GOSUB BumpChain
                            GOSUB SkullBossDeath
                            ' Bomb weapon: area explosion on skull boss kill
                            IF #GameFlags AND FLAG_BOMB THEN
                                IF BombExpTimer = 0 THEN
                                    BombExpRow = AlienGridRow
                                    BombExpCol = AlienGridCol
                                    GOSUB PlayerBombExplode
                                END IF
                            END IF
                            RETURN
                        END IF
                    END IF
                END IF

                ' Normal alien kill
                #AlienRow(AlienGridRow) = #AlienRow(AlienGridRow) XOR #Mask
                NeedRedraw = 1  ' Ensure dead tile is cleared next frame

                ' Beam: decrement pierce budget; stop when exhausted
                IF BeamTimer > 0 THEN
                    BeamHits = BeamHits - 1  ' audit-ignore: bullet cleared on next line when BeamHits=0 prevents re-entry
                    IF BeamHits = 0 THEN #GameFlags = #GameFlags AND $FFFE
                ELSE
                    #GameFlags = #GameFlags AND $FFFE
                END IF

                ' Chain combo scoring: 10, 20, 30, 40, 50 (bonus capped at 50)
                #GameFlags = #GameFlags OR FLAG_SHOTLAND
                GOSUB BumpChain
                ' Bonus caps at 50 points (chain 5+), but chain counter keeps growing for display
                ' Bonus caps at 50 points (chain 5+), but chain counter keeps growing for display
                IF ChainCount <= 5 THEN
                    #Mask = ChainCount * 10 : GOSUB AddToScore
                ELSE
                    #Mask = 50 : GOSUB AddToScore
                END IF

                ' Noise explosion SFX (short punchy crunch)
                SfxType = 1 : SfxVolume = 12 : #SfxPitch = 1800
                SOUND 2, 1800, 12  ' Immediate bass hit on channel 3

                ' Clear previous explosion tile if still active
                GOSUB ClearPrevExplosion
                ' Show explosion on BACKTAB (replaces alien, stays in place)
                #ExplosionPos = HitRow * 20 + HitCol
                GOSUB ShowChainExplosion
                ' Bomb weapon: area explosion on alien kill
                GOSUB TriggerPlayerBomb
            END IF
        END IF
    END IF
    RETURN
END

' --------------------------------------------
' DrawShipVisible - Render ship body + shield/accent sprite
' Called from DrawPlayer for both normal and invincible-flash-on frames.
' Checks Invincible>0 to choose solid yellow vs yellow/orange on damaged shield.
' --------------------------------------------
DrawShipVisible: PROCEDURE
    SPRITE SPR_PLAYER, PlayerX + $0200, PLAYER_Y + $0100, GRAM_SHIP * 8 + COL_WHITE + $0800
    ' Accent sprite: shield dome if active, engine glow if not
    IF ShieldHits > 0 THEN
        IF ShieldHits >= 2 THEN
            ' Full shield: fast blue/white flash (every 2 frames)
            IF ShimmerCount AND 2 THEN
                SPRITE SPR_SHIP_ACCENT, PlayerX + $0200, PLAYER_Y + $0100, GRAM_SHIELD * 8 + COL_BLUE + $0800
            ELSE
                SPRITE SPR_SHIP_ACCENT, PlayerX + $0200, PLAYER_Y + $0100, GRAM_SHIELD * 8 + COL_WHITE + $0800
            END IF
        ELSE
            ' Damaged shield: invincible=solid yellow; normal=yellow/orange flash
            IF Invincible > 0 OR (MarchCount AND 4) THEN
                SPRITE SPR_SHIP_ACCENT, PlayerX + $0200, PLAYER_Y + $0100, GRAM_SHIELD * 8 + COL_YELLOW + $0800
            ELSE
                ' Orange (10) is pastel: use (10 AND 7)=2 + $1800
                SPRITE SPR_SHIP_ACCENT, PlayerX + $0200, PLAYER_Y + $0100, GRAM_SHIELD * 8 + 2 + $1800
            END IF
        END IF
    ELSE
        SPRITE SPR_SHIP_ACCENT, PlayerX + $0200, PLAYER_Y + $0100, GRAM_SHIP_ACCENT * 8 + $1800
    END IF
    RETURN
END

' --------------------------------------------
' DrawPlayer - Update player sprite
' --------------------------------------------
DrawPlayer: PROCEDURE
    ' SPRITE n, x + flags, y + flags, card*8 + color
    ' X: position + $200 (visible)
    ' A: card*8 + color + $800 (GRAM)
    ' Two stacked sprites for 2-color ship: body (green) + accent (cyan)
    IF DeathTimer > 0 THEN
        ' Ship explosion animation (multi-phase visual)
        IF DeathTimer > 67 THEN
            ' Phase 1 - Initial blast: tight explosion, red (8 frames)
            SPRITE SPR_PLAYER, PlayerX + $0200, PLAYER_Y, GRAM_EXPLOSION * 8 + 2 + $0800
            SPRITE SPR_SHIP_ACCENT, PlayerX + $0204, PLAYER_Y, GRAM_EXPLOSION * 8 + 6 + $0800
        ELSEIF DeathTimer > 57 THEN
            ' Phase 2 - Expanding: scattered debris, yellow/white (10 frames)
            SPRITE SPR_PLAYER, PlayerX + $01FE, PLAYER_Y + 2, GRAM_EXPLOSION2 * 8 + 6 + $0800
            SPRITE SPR_SHIP_ACCENT, PlayerX + $0204, PLAYER_Y - 2, GRAM_EXPLOSION2 * 8 + 7 + $0800
        ELSEIF DeathTimer > 47 THEN
            ' Phase 3 - Dissipating: sparse particles, white/tan (10 frames)
            ' GRAM_EXPLOSION3 (card 16) time-shares with GRAM_SKELETON — use card 15 instead
            SPRITE SPR_PLAYER, PlayerX + $01FC, PLAYER_Y + 4, GRAM_EXPLOSION2 * 8 + 7 + $0800
            SPRITE SPR_SHIP_ACCENT, PlayerX + $0206, PLAYER_Y - 4, GRAM_EXPLOSION2 * 8 + 3 + $0800
        ELSEIF DeathTimer > 39 THEN
            ' Phase 4 - Fading embers: blink on/off (8 frames)
            IF DeathTimer AND 2 THEN
                SPRITE SPR_PLAYER, PlayerX + $0200, PLAYER_Y, GRAM_EXPLOSION2 * 8 + 3 + $0800
                SPRITE SPR_SHIP_ACCENT, 0, 0, 0
            ELSE
                SPRITE SPR_PLAYER, 0, 0, 0
                SPRITE SPR_SHIP_ACCENT, 0, 0, 0
            END IF
        ELSE
            ' Hidden - SFX continues playing through remaining frames
            SPRITE SPR_PLAYER, 0, 0, 0
            SPRITE SPR_SHIP_ACCENT, 0, 0, 0
        END IF
    ELSEIF Invincible > 0 THEN
        ' Flash during invincibility (show every other frame)
        IF Invincible AND 4 THEN
            GOSUB DrawShipVisible
        ELSE
            SPRITE SPR_PLAYER, 0, 0, 0
            SPRITE SPR_SHIP_ACCENT, 0, 0, 0
        END IF
    ELSE
        ' Normal display - body + accent sprite (DOUBLEY for 16px tall)
        GOSUB DrawShipVisible
    END IF

    RETURN
END

' --------------------------------------------
' DrawBullet - Update bullet sprite with color cycling
' --------------------------------------------
DrawBullet: PROCEDURE
    IF #GameFlags AND FLAG_BULLET THEN
        ' Increment color timer, switch color every 4 frames
        BulletColor = BulletColor + 1
        IF BulletColor >= 8 THEN BulletColor = 0

        ' Solid red for frames 0-3, solid white for frames 4-7
        IF BulletColor < 4 THEN
            AlienColor = COL_RED
        ELSE
            AlienColor = COL_WHITE
        END IF

        IF BeamTimer > 0 THEN
            ' Wide beam mode: 8px wide x 16px tall, centered on bullet position
            IF BulletX >= 3 THEN
                SPRITE SPR_PBULLET, (BulletX - 3) + $0200, BulletY + $0100, GRAM_BEAM * 8 + AlienColor + $0800
            ELSE
                SPRITE SPR_PBULLET, $0200, BulletY + $0100, GRAM_BEAM * 8 + AlienColor + $0800
            END IF
        ELSEIF #GameFlags AND FLAG_BOMB THEN
            ' Bomb weapon: animated capsule sprite in yellow
            SPRITE SPR_PBULLET, BulletX + $0200, BulletY, (GRAM_CAP_F1 + BulletColor / 2) * 8 + COL_YELLOW + $0800
        ELSE
            SPRITE SPR_PBULLET, BulletX + $0200, BulletY, GRAM_BULLET * 8 + AlienColor + $0800
        END IF
    ELSE
        ' Hide bullet sprite
        SPRITE SPR_PBULLET, 0, 0, 0
    END IF
    RETURN
END

' --------------------------------------------
' AlienShoot - Decide when and where aliens shoot
' --------------------------------------------
ComputeBossCard: PROCEDURE
    IF BossType(FoundBoss) = BOMB_TYPE THEN
        ' Bomb alien: use BossColor, flash red/white at HP=1
        HitCol = BossColor(FoundBoss)
        IF BossHP(FoundBoss) = 1 THEN
            IF ShimmerCount AND 4 THEN HitCol = COL_WHITE ELSE HitCol = COL_RED
        END IF
        IF HitCol >= 8 THEN
            #Card = (HitCol AND 7) + $1800
        ELSE
            #Card = HitCol + $0800
        END IF
        IF Col = BossCol(FoundBoss) THEN
            IF AnimFrame = 0 THEN
                #Card = GRAM_BOMB1 * 8 + #Card
            ELSE
                #Card = GRAM_BOMB1_F1 * 8 + #Card
            END IF
        ELSE
            IF AnimFrame = 0 THEN
                #Card = GRAM_BOMB2 * 8 + #Card
            ELSE
                #Card = GRAM_BOMB2_F1 * 8 + #Card
            END IF
        END IF
    ELSE
        ' Skull boss: use BossColor directly
        IF BossColor(FoundBoss) >= 8 THEN
            #Card = (BossColor(FoundBoss) AND 7) + $1800
        ELSE
            #Card = BossColor(FoundBoss) + $0800
        END IF
        IF Col = BossCol(FoundBoss) THEN
            IF AnimFrame = 0 THEN
                #Card = GRAM_BAND1 * 8 + #Card
            ELSE
                #Card = GRAM_BAND1_F1 * 8 + #Card
            END IF
        ELSE
            IF AnimFrame = 0 THEN
                #Card = GRAM_BAND2 * 8 + #Card
            ELSE
                #Card = GRAM_BAND2_F1 * 8 + #Card
            END IF
        END IF
    END IF
    RETURN
END

' --------------------------------------------
' DrawAliens - Draw all aliens to background
' --------------------------------------------
DrawAliens: PROCEDURE
    ' Clear rows above current alien position (only when new descent occurs)
    ' Cap at row 10 to protect HUD on row 11
    IF AlienOffsetY > LastClearedY THEN
        FOR ClearRow = LastClearedY TO AlienOffsetY - 1
            IF ALIEN_START_Y + ClearRow < 11 THEN
                #ScreenPos = Row20Data(ALIEN_START_Y + ClearRow)
                ' Only clear alien area + trails (not full 20 columns)
                FOR Col = ALIEN_START_X + AlienOffsetX TO ALIEN_START_X + AlienOffsetX + ALIEN_COLS + 1
                    IF Col < 20 THEN PRINT AT #ScreenPos + Col, 0
                NEXT Col
            END IF
        NEXT ClearRow
        LastClearedY = AlienOffsetY
    END IF

    ' Draw aliens and clear trail in ONE pass (no flicker)
    FOR Row = 0 TO ALIEN_ROWS - 1
        ' Calculate effective screen row
        ClearRow = ALIEN_START_Y + AlienOffsetY + Row
        HitCol = 1  ' Default: draw this row (reuse HitCol as skip flag)
        ' Fly-down mode: subtract offset (aliens start above screen)
        ' WaveRevealRow = rows hidden above screen (counts down to 0)
        IF WaveEntrance = 2 THEN
            IF ClearRow < WaveRevealRow THEN
                ' Row is above screen, skip entirely
                HitCol = 0
            ELSE
                ClearRow = ClearRow - WaveRevealRow
            END IF
        END IF
        ' Skip if this row would land on the HUD (row 11 = positions 220+)
        IF HitCol AND ClearRow < 11 THEN
        #ScreenPos = Row20Data(ClearRow)

        ' Determine which alien type and wave color for this row (5 unique types)
        ' Set base color first
        IF Row = 0 THEN
            AlienColor = WaveColor0
        ELSEIF Row = 1 THEN
            AlienColor = WaveColor1
        ELSEIF Row = 2 THEN
            AlienColor = WaveColor2
        ELSEIF Row = 3 THEN
            AlienColor = WaveColor3
        ELSE
            AlienColor = WaveColor4
        END IF

        ' Select card based on ShiftPos (substep march position)
        ' SubstepState bits 0-1 = ShiftPos (always 0 with march disabled)
        ' AnimFrame AND 1: selects BASE (F0/F2) or BASE+1 (F1); DEFINE-swap provides F2 data in BASE
        IF (SubstepState AND 3) = 0 THEN
            ' Base position: use standard alien cards with animation
            IF Row = 0 THEN
                AlienCard = GRAM_ALIEN1 + (AnimFrame AND 1)
            ELSEIF Row = 1 THEN
                AlienCard = GRAM_ALIEN2 + (AnimFrame AND 1)
            ELSEIF Row = 2 THEN
                AlienCard = GRAM_ALIEN3 + (AnimFrame AND 1)
            ELSEIF Row = 3 THEN
                AlienCard = GRAM_ALIEN4 + (AnimFrame AND 1)
            ELSE
                AlienCard = GRAM_ALIEN5 + (AnimFrame AND 1)
            END IF
        ELSEIF (SubstepState AND 3) = 1 THEN
            ' Shift-1 (+1px): lookup table (31,32,37,38,47) - constant time!
            AlienCard = Shift1CardData(Row)
        ELSE
            ' Shift-2 (+2px): lookup table (42,43,44,38,47) - constant time!
            AlienCard = Shift2CardData(Row)
        END IF

        ' Color Stack mode - SAME format as sprites!
        ' card * 8 + color + $0800 (GRAM flag)
        #Card = AlienCard * 8 + AlienColor + $0800

        ' Pre-check: cache boss indices for this row (eliminates FindBoss GOSUB)
        RowBoss1 = 255 : RowBoss2 = 255
        IF BossCount > 0 THEN
            FOR LoopVar = 0 TO BossCount - 1
                IF BossHP(LoopVar) > 0 THEN
                    IF Row = BossRow(LoopVar) THEN
                        IF RowBoss1 = 255 THEN RowBoss1 = LoopVar ELSE RowBoss2 = LoopVar
                    END IF
                END IF
            NEXT LoopVar
        END IF

        IF #GameFlags AND FLAG_REVEAL THEN
            ' Slide-in mode: clear only trail columns (not all 20!)
            ' Left group slides right → clear previous left edge
            IF WaveRevealCol > 0 THEN
                FOR Col = 0 TO 4
                    PRINT AT #ScreenPos + WaveRevealCol - 1 + Col, 0
                NEXT Col
            END IF
            ' Right group slides left → clear previous right edge
            IF RightRevealCol < 9 THEN
                FOR Col = 5 TO 9
                    PRINT AT #ScreenPos + RightRevealCol + 1 + Col, 0
                NEXT Col
            END IF
            #Mask = 1
            FOR Col = 0 TO ALIEN_COLS - 1
                IF #AlienRow(Row) AND #Mask THEN
                    ' Check for boss in dual-reveal mode (inline)
                    FoundBoss = 255
                    IF RowBoss1 < 255 THEN
                        IF Col = BossCol(RowBoss1) OR Col = BossCol(RowBoss1) + 1 THEN FoundBoss = RowBoss1
                        IF FoundBoss = 255 AND RowBoss2 < 255 THEN
                            IF Col = BossCol(RowBoss2) OR Col = BossCol(RowBoss2) + 1 THEN FoundBoss = RowBoss2
                        END IF
                    END IF
                    IF FoundBoss < 255 THEN GOSUB ComputeBossCard
                    ' Boss cards use BossCol to pick offset (prevents split at col 4/5 boundary)
                    IF FoundBoss < 255 THEN
                        IF BossCol(FoundBoss) < 5 THEN
                            PRINT AT #ScreenPos + WaveRevealCol + Col, #Card
                        ELSE
                            PRINT AT #ScreenPos + RightRevealCol + Col, #Card
                        END IF
                    ELSEIF Col < 5 THEN
                        PRINT AT #ScreenPos + WaveRevealCol + Col, #Card
                    ELSE
                        PRINT AT #ScreenPos + RightRevealCol + Col, #Card
                    END IF
                    ' Restore normal alien card for next column
                    #Card = AlienCard * 8 + AlienColor + $0800
                END IF
                #Mask = #Mask + #Mask
            NEXT Col
        ELSE
            ' Standard mode: two paths for performance
            IF WaveRevealCol >= ALIEN_COLS - 1 AND WaveEntrance <> 1 THEN
            ' FAST PATH: reveal complete, skip all warp/reveal checks
            ' Pre-add row offset once (saves 2 additions per cell × 9 cols)
            #ScreenPos = #ScreenPos + ALIEN_START_X + AlienOffsetX
            IF #AlienRow(Row) = 0 THEN
                ' EMPTY ROW: clear all 9 columns + trail edges
                ' Must clear interior columns (not just trail edges) because after
                ' a grid descent the row above a boss maps to this screen row —
                ' trail-only clearing leaves stale boss tiles from the prior descent.
                FOR Col = 0 TO ALIEN_COLS - 1
                    PRINT AT #ScreenPos + Col, 0
                NEXT Col
                IF AlienOffsetX > 0 THEN
                    PRINT AT #ScreenPos - 1, 0
                END IF
                IF AlienOffsetX < ALIEN_MAX_X THEN
                    PRINT AT #ScreenPos + ALIEN_COLS, 0
                END IF
            ELSEIF RowBoss1 < 255 THEN
                ' BOSS ROW: per-cell boss checking required
                #Mask = 1
                FOR Col = 0 TO ALIEN_COLS - 1
                    IF #AlienRow(Row) AND #Mask THEN
                        FoundBoss = 255
                        IF Col = BossCol(RowBoss1) OR Col = BossCol(RowBoss1) + 1 THEN FoundBoss = RowBoss1
                        IF FoundBoss = 255 AND RowBoss2 < 255 THEN
                            IF Col = BossCol(RowBoss2) OR Col = BossCol(RowBoss2) + 1 THEN FoundBoss = RowBoss2
                        END IF
                        IF FoundBoss < 255 THEN
                            GOSUB ComputeBossCard
                            PRINT AT #ScreenPos + Col, #Card
                            #Card = AlienCard * 8 + AlienColor + $0800
                        ELSE
                            PRINT AT #ScreenPos + Col, #Card
                        END IF
                    ELSE
                        PRINT AT #ScreenPos + Col, 0
                    END IF
                    #Mask = #Mask + #Mask
                NEXT Col
                IF AlienOffsetX > 0 THEN
                    PRINT AT #ScreenPos - 1, 0
                END IF
                IF AlienOffsetX < ALIEN_MAX_X THEN
                    PRINT AT #ScreenPos + ALIEN_COLS, 0
                END IF
            ELSE
                ' NO-BOSS ROW: BASIC loop (simple and reliable)
                #Mask = 1
                FOR Col = 0 TO ALIEN_COLS - 1
                    IF #AlienRow(Row) AND #Mask THEN
                        PRINT AT #ScreenPos + Col, #Card
                    ELSE
                        PRINT AT #ScreenPos + Col, 0
                    END IF
                    #Mask = #Mask + #Mask
                NEXT Col
                IF AlienOffsetX > 0 THEN
                    PRINT AT #ScreenPos - 1, 0
                END IF
                IF AlienOffsetX < ALIEN_MAX_X THEN
                    PRINT AT #ScreenPos + ALIEN_COLS, 0
                END IF
            END IF
            ELSE
            ' REVEAL PATH: warp-in effects + reveal gating
            IF WaveEntrance = 1 AND Row > WaveRevealRow THEN
                ' Row not yet revealed in top-down mode - skip drawing
            ELSE
            #Mask = 1
            FOR Col = 0 TO ALIEN_COLS - 1
                IF WaveEntrance = 1 OR Col <= WaveRevealCol THEN
                    IF #AlienRow(Row) AND #Mask THEN
                        FoundBoss = 255
                        IF RowBoss1 < 255 THEN
                            IF Col = BossCol(RowBoss1) OR Col = BossCol(RowBoss1) + 1 THEN FoundBoss = RowBoss1
                            IF FoundBoss = 255 AND RowBoss2 < 255 THEN
                                IF Col = BossCol(RowBoss2) OR Col = BossCol(RowBoss2) + 1 THEN FoundBoss = RowBoss2
                            END IF
                        END IF
                        IF FoundBoss < 255 THEN
                            GOSUB ComputeBossCard
                            PRINT AT #ScreenPos + ALIEN_START_X + AlienOffsetX + Col, #Card
                            #Card = AlienCard * 8 + AlienColor + $0800
                        ELSE
                            ' Warp-in: materialize frames for currently revealing elements
                            IF WaveEntrance = 1 AND Row = WaveRevealRow AND WaveRevealRow < ALIEN_ROWS - 1 THEN
                                PRINT AT #ScreenPos + ALIEN_START_X + AlienOffsetX + Col, (GRAM_WARP1 + MarchCount) * 8 + AlienColor + $0800
                            ELSEIF Col = WaveRevealCol AND WaveRevealCol < ALIEN_COLS - 1 THEN
                                PRINT AT #ScreenPos + ALIEN_START_X + AlienOffsetX + Col, (GRAM_WARP1 + MarchCount) * 8 + AlienColor + $0800
                            ELSE
                                PRINT AT #ScreenPos + ALIEN_START_X + AlienOffsetX + Col, #Card
                            END IF
                        END IF
                    ELSE
                        PRINT AT #ScreenPos + ALIEN_START_X + AlienOffsetX + Col, 0
                    END IF
                END IF
                #Mask = #Mask + #Mask
            NEXT Col
            END IF  ' top-down row gating
            ' Clear trail on BOTH edges (reveal path)
            IF AlienOffsetX > 0 THEN
                PRINT AT #ScreenPos + ALIEN_START_X + AlienOffsetX - 1, 0
            END IF
            IF AlienOffsetX < ALIEN_MAX_X THEN
                PRINT AT #ScreenPos + ALIEN_START_X + AlienOffsetX + ALIEN_COLS, 0
            END IF
            END IF  ' fast vs reveal path
        END IF
        END IF  ' row < 11 (protect HUD)
    NEXT Row
    RETURN
END

' --------------------------------------------
' DrawWaveBanner - Render wave announcement text
' Called from game loop banner overlay block
' WaveAnnouncerType: 1=WAVE X, 2=ALERT!, 3=INCOMING HORDE!
' --------------------------------------------
DrawWaveBanner: PROCEDURE
    IF WaveAnnouncerType = 1 THEN
        PRINT AT 127 COLOR 1, "WAVE "
        PRINT AT 132 COLOR 1, <> Level
    ELSEIF WaveAnnouncerType = 2 THEN
        PRINT AT 127 COLOR COL_RED, "ALERT!"
    ELSE
        PRINT AT 123 COLOR COL_RED, "INCOMING HORDE!"
    END IF
    RETURN
END

' --------------------------------------------
' ClearWaveBanner - Erase wave announcement text
' --------------------------------------------
ClearWaveBanner: PROCEDURE
    IF WaveAnnouncerType = 3 THEN
        PRINT AT 123, "               "
    ELSE
        PRINT AT 127, "       "
    END IF
    RETURN
END

' --------------------------------------------
' SpinWaveBannerLetter - Animate one frame of the spin-out
' Called from game loop during WaveAnnouncerTimer 1-20 (type 1 only)
' Phases 0-3 = W,A,V,E; 4 frames per phase (0=hold full, 1=narrow, 2=edge, 3=blank)
' Card 32 (GRAM_FONT_T) pre-loaded at StartNewWave with WaveSpinWGfx
' Card 47 (GRAM_ORBITER) pre-loaded at StartNewWave with WaveSpinEdgeGfx
' --------------------------------------------
SpinWaveBannerLetter: PROCEDURE
    IF WaveBannerPhase >= 4 THEN RETURN     ' All letters done, no-op
    Col = 127 + WaveBannerPhase             ' W=127, A=128, V=129, E=130
    IF WaveBannerFrame = 1 THEN
        ' Narrow frame: card 32 holds current phase's narrow bitmap
        PRINT AT Col, GRAM_FONT_T * 8 + 1 + $0800
        ' Pre-load NEXT phase's narrow bitmap into card 32 for next phase Frame 1
        IF WaveBannerPhase = 0 THEN
            DEFINE GRAM_FONT_T, 1, WaveSpinAGfx
        ELSEIF WaveBannerPhase = 1 THEN
            DEFINE GRAM_FONT_T, 1, WaveSpinVGfx
        ELSEIF WaveBannerPhase = 2 THEN
            DEFINE GRAM_FONT_T, 1, WaveSpinEGfx
        END IF
        ' No DEFINE at Phase 3 (E is the last)
    ELSEIF WaveBannerFrame = 2 THEN
        ' Edge-on: card 47 holds WaveSpinEdgeGfx (pre-loaded at StartNewWave)
        PRINT AT Col, GRAM_ORBITER * 8 + 1 + $0800
    ELSEIF WaveBannerFrame = 3 THEN
        ' Blank: letter has spun away
        PRINT AT Col, 0
    END IF
    ' Frame 0: do nothing, GROM character already showing from DrawWaveBanner
    RETURN
END

' --------------------------------------------
' CheckWaveWin - Check if all aliens are dead
' --------------------------------------------
' --------------------------------------------
' LoadPatternB - Transition to Pattern B formation
' --------------------------------------------
