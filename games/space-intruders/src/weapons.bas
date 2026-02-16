' ============================================
' SPACE INTRUDERS - Weapons Module
' ============================================
' Alien bullet physics, mega beam, and bomb weapon systems
' Segment: 2

    SEGMENT 2

' === Weapons Systems ===

AlienShoot: PROCEDURE
    ' Saucer owns the bullet during chase
    IF FlyState = SAUCER_CHASE THEN RETURN
    ShootTimer = ShootTimer + 1
    IF ShootTimer >= ALIEN_SHOOT_RATE THEN
        ShootTimer = 0
        IF (#GameFlags AND FLAG_ABULLET) = 0 THEN
            ' Pick random column
            ShootCol = RANDOM(ALIEN_COLS)
            ' Find bottom-most alien in that column and spawn bullet
            GOSUB FindShooter
        END IF
    END IF
    RETURN
END

' --------------------------------------------
' FindShooter - Find bottom alien in ShootCol, fire bullet
' --------------------------------------------
FindShooter: PROCEDURE
    ' Calculate bitmask for this column
    #Mask = ColMaskData(ShootCol)

    ' Search from bottom row up for an alive alien
    ' NOTE: Must NOT use RETURN/GOTO to exit FOR loop (R4 stack leak)
    HitRow = 255
    FOR Row = ALIEN_ROWS - 1 TO 0 STEP -1
        IF #AlienRow(Row) AND #Mask THEN
            IF HitRow = 255 THEN HitRow = Row
        END IF
    NEXT Row
    IF HitRow < 255 THEN
        ' Convert BACKTAB coords to sprite coords (+8 offset) and position at alien center/bottom
        ABulletX = (ALIEN_START_X + AlienOffsetX + ShootCol) * 8 + 11  ' +8 sprite offset, +3 to center
        ABulletY = (ALIEN_START_Y + AlienOffsetY + HitRow) * 8 + 16   ' +8 sprite offset, +8 to bottom of card
        #GameFlags = #GameFlags OR FLAG_ABULLET
        ' Check if shooter is a boss — fire beam laser instead of zigzag
        ABulFrame = ABulFrame AND 1   ' Clear type bit, keep anim frame
        IF BossCount > 0 THEN
            FOR LoopVar = 0 TO BossCount - 1
                IF BossHP(LoopVar) > 0 THEN
                    IF HitRow = BossRow(LoopVar) THEN
                        IF ShootCol = BossCol(LoopVar) OR ShootCol = BossCol(LoopVar) + 1 THEN
                            ABulFrame = ABulFrame OR 2   ' Set beam type bit
                        END IF
                    END IF
                END IF
            NEXT LoopVar
        END IF
    END IF
    RETURN
END

' --------------------------------------------
' MoveAlienBullet - Move alien bullet down + check player collision
' --------------------------------------------
MoveAlienBullet: PROCEDURE
    ABulletY = ABulletY + ALIEN_BULLET_SPEED
    ABulFrame = ABulFrame XOR 1  ' Toggle anim frame (bit 0), preserve type (bit 1)

    ' Check if bullet went off screen
    IF ABulletY >= 104 THEN
        #GameFlags = #GameFlags AND $FFFD
        SPRITE SPR_ABULLET, 0, 0, 0
        RETURN
    END IF

    ' Check wingman collision (bullet sponge - absorbs hits, wingman survives!)
    IF #GameFlags AND FLAG_CAPTURE THEN
        ' Wingman hitbox: 8x8 sprite at RogueX, RogueY
        IF ABulletY >= RogueY - 2 THEN
            IF ABulletY <= RogueY + 8 THEN
                IF ABulletX >= RogueX - 2 THEN
                    IF ABulletX <= RogueX + 8 THEN
                        ' Wingman absorbs the hit - destroy bullet, wingman lives!
                        #GameFlags = #GameFlags AND $FFFD  ' Clear alien bullet only
                        SPRITE SPR_ABULLET, 0, 0, 0
                        ' Shield ping SFX (different from death)
                        SfxType = 6 : SfxVolume = 10 : #SfxPitch = 300
                        SOUND 2, 300, 10
                        RETURN
                    END IF
                END IF
            END IF
        END IF
    END IF

    ' Check player collision
    IF DeathTimer = 0 THEN
        IF Invincible = 0 THEN
            IF ABulletY >= PLAYER_Y - 4 THEN
                IF ABulletY <= PLAYER_Y + 8 THEN
                    IF ABulletX >= PlayerX - 2 THEN
                        IF ABulletX <= PlayerX + 10 THEN
                            ' Bullet hit - check shield first
                            IF ShieldHits > 0 THEN
                                GOSUB HitShield
                            ELSE
                                #GameFlags = #GameFlags OR FLAG_PLAYERHIT
                                SfxType = 3 : SfxVolume = 15 : #SfxPitch = 0
                                SOUND 2, 0, 15
                                POKE $1F7, 14
                                POKE $1F8, PEEK($1F8) AND $DF
                            END IF
                            ' Either way, destroy the bullet
                            #GameFlags = #GameFlags AND $FFFD
                            SPRITE SPR_ABULLET, 0, 0, 0
                        END IF
                    END IF
                END IF
            END IF
        END IF
    END IF
    RETURN
END

' --------------------------------------------
' DrawAlienBullet - Draw alien bullet sprite with color phase animation
' --------------------------------------------
DrawAlienBullet: PROCEDURE
    IF #GameFlags AND FLAG_ABULLET THEN
        IF ABulFrame AND 2 THEN
            ' Boss beam laser: green/white flash, DOUBLEY for 16px tall
            IF ABulFrame AND 1 THEN
                SPRITE SPR_ABULLET, ABulletX + $0200, ABulletY + $0100, GRAM_BEAM * 8 + COL_GREEN + $0800
            ELSE
                SPRITE SPR_ABULLET, ABulletX + $0200, ABulletY + $0100, GRAM_BEAM * 8 + COL_WHITE + $0800
            END IF
        ELSE
            ' Normal zigzag bolt
            IF ABulFrame AND 1 THEN
                SPRITE SPR_ABULLET, ABulletX + $0200, ABulletY, GRAM_ZIGZAG1 * 8 + COL_WHITE + $0800
            ELSE
                SPRITE SPR_ABULLET, ABulletX + $0200, ABulletY, GRAM_ZIGZAG1 * 8 + COL_YELLOW + $0800
            END IF
        END IF
    END IF
    RETURN
END

' --- SetEntrancePattern: Set entrance mode from DATA table ---
' Input: LoopVar = wave index (0-31)
' Sets WaveEntrance: 0=left sweep, 1=top-down reveal, 2=fly-down from above
