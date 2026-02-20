' ============================================
' SPACE INTRUDERS - Player Control Module
' ============================================
' Player movement and projectile physics
' Segment: 2

    SEGMENT 2

' === Player Control ===

MovePlayer: PROCEDURE
    ' Left movement
    IF CONT.LEFT THEN
        IF PlayerX > PLAYER_MIN_X THEN
            PlayerX = PlayerX - PLAYER_SPEED
        END IF
    END IF

    ' Right movement
    IF CONT.RIGHT THEN
        IF PlayerX < PLAYER_MAX_X THEN
            PlayerX = PlayerX + PLAYER_SPEED
        END IF
    END IF

    ' Keypad 1: toggle auto-fire (with debounce)
    IF CONT.KEY = 1 THEN
        IF Key1Held = 0 THEN
            Key1Held = 1
            #GameFlags = #GameFlags XOR FLAG_AUTOFIRE
            AutoFireFlash = 60  ' 1 second fast-blink flash at row 10
            IF #GameFlags AND FLAG_AUTOFIRE THEN
                IF VOICE.AVAILABLE THEN VOICE PLAY auto_on_phrase
            ELSE
                IF VOICE.AVAILABLE THEN VOICE PLAY auto_off_phrase
            END IF
        END IF
    ELSE
        Key1Held = 0
    END IF

    ' Keypad 0: capture rogue alien during dogfight (with debounce)
    ' On keyboard: numpad 0 (see intruders.kbd — KP0 PD0L_KP0)
    IF CONT.KEY = 0 THEN
        IF (#GameFlags AND FLAG_KEY0HELD) = 0 THEN
            #GameFlags = #GameFlags OR FLAG_KEY0HELD
            IF RogueDivePhase = 254 THEN
                IF (#GameFlags AND FLAG_CAPTURE) = 0 THEN
                    ' Capture the rogue alien — start zip-to-ship animation
                    CaptureColor = RogueColor
                    CaptureStep = 0
                    CaptureTimer = CAPTURE_FIRE_RATE
                    CaptureWaves = 0
                    ' ROGUE_CAPTURED: rogue stays visible as it zips to the ship.
                    ' FLAG_CAPTURE is set only when zip completes (in RogueUpdate).
                    RogueState = ROGUE_CAPTURED
                    RogueTimer = 0
                    ' Capture SFX: rising tone
                    SfxType = 2 : SfxVolume = 14 : #SfxPitch = 400
                    SOUND 2, 400, 14
                END IF
            END IF
        END IF
    END IF
    IF CONT.KEY <> 0 THEN
        #GameFlags = #GameFlags AND $EFFF  ' Clear FLAG_KEY0HELD when key released
    END IF

    ' Fire: side buttons (not keypad) or auto-fire
    IF CONT.BUTTON OR (#GameFlags AND FLAG_AUTOFIRE) THEN
    IF CONT.KEY >= 12 OR (#GameFlags AND FLAG_AUTOFIRE) THEN
        IF MegaTimer > 0 THEN
            ' Mega beam: instant column blast (reusable for 5 sec)
            IF MegaBeamTimer = 0 THEN
                MegaBeamCol = (PlayerX - 4) / 8
                IF MegaBeamCol > 19 THEN MegaBeamCol = 19
                MegaBeamTimer = 20
                ' Reset beam damage tracker for each boss
                FOR LoopVar = 0 TO MAX_BOSSES - 1
                    BossBeamHit(LoopVar) = 0
                NEXT LoopVar
                GOSUB MegaBeamKill
                GOSUB MegaBeamDraw
                ' SFX: loud crackle blast
                SfxType = 4 : SfxVolume = 15 : #SfxPitch = 0
                SOUND 2, 0, 15
                POKE $1F9, 8
                POKE $1F8, PEEK($1F8) AND $DF
            END IF
        ELSEIF #GameFlags AND FLAG_BOMB THEN
            ' Bomb weapon: fires capsule projectile, one shot
            IF (#GameFlags AND FLAG_BULLET) = 0 THEN
                BulletX = PlayerX
                BulletY = PLAYER_Y - 4
                #GameFlags = #GameFlags OR FLAG_BULLET
                #GameFlags = #GameFlags AND $FFDF     ' New shot
                ' Bomb launch SFX: deep thunk
                SfxType = 7 : SfxVolume = 14 : #SfxPitch = 100
                SOUND 2, 100, 14
            END IF
        ELSEIF MegaSputterTimer = 0 THEN
            ' Normal/beam/rapid: single center shot
            IF (#GameFlags AND FLAG_BULLET) = 0 THEN
                IF FireCooldown = 0 THEN
                    ' Beam drawn at BulletX-3, normal drawn at BulletX
                    IF BeamTimer > 0 THEN
                        BulletX = PlayerX + 3  ' Beam: offset for -3 draw adjustment
                    ELSE
                        BulletX = PlayerX  ' Normal/rapid: direct draw position
                    END IF
                    BulletY = PLAYER_Y - 4
                    #GameFlags = #GameFlags OR FLAG_BULLET
                    #GameFlags = #GameFlags AND $FFDF     ' New shot — hasn't hit anything yet
                    IF BeamTimer > 0 THEN
                        BeamHits = 2  ' Beam pierces 2 consecutive targets then stops
                        ' Chain reaction laser SFX: kill music, dual-tone + noise
                        PLAY OFF
                        ChainTimer = 24
                        #ChainFreq1 = 150
                        #ChainFreq2 = 80
                        ChainVol = 15
                        POKE $1F9, 12
                        POKE $1F8, $18
                        SOUND 0, 150, 14
                        SOUND 2, 80, 15
                    ELSE
                        ' Pea shooter SFX: descending laser zap
                        SfxType = 7 : SfxVolume = 14 : #SfxPitch = 150
                        SOUND 2, 150, 14
                    END IF
                    IF RapidTimer > 0 THEN
                        FireCooldown = RAPID_COOLDOWN
                    END IF
                END IF
            END IF
        END IF
    END IF
    END IF

    RETURN
END


' --------------------------------------------
' MoveBullet - Update bullet position and check collisions
' --------------------------------------------
MoveBullet: PROCEDURE
    ' Check orbiter collisions FIRST (orbiters intercept bullets before the alien grid does,
    ' because the orbit path often overlaps formation cells — prioritizing orbiters ensures
    ' the visible sprite, not a hidden alien, receives the hit)
    IF OrbitStep < 10 THEN
    IF #GameFlags AND FLAG_BULLET THEN
        Col = BossCol(0) + OrbitDX(OrbitStep) - 1
        Row = BossRow(0) + OrbitDY(OrbitStep) - 1
        HitRow = (BulletY - 8) / 8
        HitCol = (BulletX - 8) / 8
        IF HitCol = ALIEN_START_X + AlienOffsetX + Col THEN
            IF HitRow = ALIEN_START_Y + AlienOffsetY + Row THEN
                GOSUB OrbiterHitEffect
                OrbiterDeathTimer = 1
                OrbitStep = 255
            END IF
        END IF
    END IF
    END IF
    IF OrbitStep2 < 10 THEN
    IF #GameFlags AND FLAG_BULLET THEN
        Col = BossCol(1) + OrbitDX(OrbitStep2) - 1
        Row = BossRow(1) + OrbitDY(OrbitStep2) - 1
        HitRow = (BulletY - 8) / 8
        HitCol = (BulletX - 8) / 8
        IF HitCol = ALIEN_START_X + AlienOffsetX + Col THEN
            IF HitRow = ALIEN_START_Y + AlienOffsetY + Row THEN
                GOSUB OrbiterHitEffect
                OrbiterDeathTimer = 1
                OrbitStep2 = 255
            END IF
        END IF
    END IF
    END IF

    ' Check alien grid collision (after orbiters, so their sprite takes priority over any
    ' alien sharing the same grid cell)
    GOSUB CheckBulletHit

    ' Then move bullet up (rapid fire = 3px, bomb/beam = 2px, normal = 1.25px)
    IF #GameFlags AND FLAG_BULLET THEN
        IF RapidTimer > 0 THEN
            IF BulletY > BULLET_TOP + RAPID_SPEED THEN
                BulletY = BulletY - RAPID_SPEED
            ELSE
                #GameFlags = #GameFlags AND $FFFE
                IF #GameFlags = #GameFlags AND $FFDF THEN ChainCount = 0   ' Whiff — break chain
            END IF
        ELSEIF (#GameFlags AND FLAG_BOMB) OR BeamTimer > 0 THEN
            ' Bomb / beam: flat 2px/frame
            IF BulletY > BULLET_TOP + 2 THEN
                BulletY = BulletY - 2
            ELSE
                #GameFlags = #GameFlags AND $FFFE
                IF #GameFlags = #GameFlags AND $FFDF THEN ChainCount = 0   ' Whiff — break chain
            END IF
        ELSE
            ' Normal pea shooter: flat 2px/frame
            IF BulletY > BULLET_TOP + BULLET_SPEED THEN
                BulletY = BulletY - BULLET_SPEED
            ELSE
                #GameFlags = #GameFlags AND $FFFE
                IF #GameFlags = #GameFlags AND $FFDF THEN ChainCount = 0   ' Whiff — break chain
            END IF
        END IF
    END IF

    RETURN
END

' --------------------------------------------
' CheckBulletHit - See if bullet hit an alien
' Uses expanded hitbox - checks wide horizontal and vertical range
' --------------------------------------------
CheckBulletHit: PROCEDURE
    ' Check primary row (where bullet tip is)
    ' Sprite coords have 8px offset from BACKTAB: column 0 = sprite X=8, row 0 = sprite Y=8
    HitRow = (BulletY - 8) / 8
    GOSUB CheckRowForHit

    ' Also check row above (bullet may be straddling boundary)
    IF #GameFlags AND FLAG_BULLET THEN
        IF BulletY > 16 THEN
            HitRow = (BulletY - 12) / 8
            GOSUB CheckRowForHit
        END IF
    END IF

    RETURN
END

' --------------------------------------------
' CheckRowForHit - Check one row for alien collision
' Expects: HitRow set
' --------------------------------------------
CheckRowForHit: PROCEDURE
    ' Check if in alien row range
    IF HitRow >= ALIEN_START_Y + AlienOffsetY THEN
        IF HitRow < ALIEN_START_Y + AlienOffsetY + ALIEN_ROWS THEN
            AlienGridRow = HitRow - ALIEN_START_Y - AlienOffsetY

            IF BeamTimer > 0 THEN
                ' Wide beam mode: beam covers BulletX-3 to BulletX+4 (8px)
                ' Subtract 8 from X for sprite-to-BACKTAB offset
                IF BulletX >= 11 THEN
                    HitCol = (BulletX - 11) / 8
                    GOSUB CheckOneColumn
                END IF

                IF #GameFlags AND FLAG_BULLET THEN
                    HitCol = (BulletX - 8) / 8
                    GOSUB CheckOneColumn
                END IF

                IF #GameFlags AND FLAG_BULLET THEN
                    HitCol = (BulletX - 4) / 8
                    GOSUB CheckOneColumn
                END IF
            ELSE
                ' Normal bullet: subtract 8 for sprite-to-BACKTAB offset
                IF BulletX >= 9 THEN
                    HitCol = (BulletX - 9) / 8
                    GOSUB CheckOneColumn
                END IF

                IF #GameFlags AND FLAG_BULLET THEN
                    HitCol = (BulletX - 6) / 8
                    GOSUB CheckOneColumn
                END IF

                IF #GameFlags AND FLAG_BULLET THEN
                    HitCol = (BulletX - 4) / 8
                    GOSUB CheckOneColumn
                END IF

                IF #GameFlags AND FLAG_BULLET THEN
                    HitCol = (BulletX - 2) / 8
                    GOSUB CheckOneColumn
                END IF
            END IF
        END IF
    END IF
    RETURN
END

