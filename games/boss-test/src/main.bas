' ============================================
' SAUCER BOSS BATTLE — Test ROM
' ============================================
' Stationary saucer with sliding shield panels.
' Alien visible through central viewport.
'
' ENTRANCE: Alien flies smooth SCROLL-based
' figure-8 (sub-pixel), then ascends to
' position. Saucer materializes around it.
' ============================================

' --- Constants ---
CONST BOSS_MAX_HP   = 10
CONST RESPAWN_TIME  = 90
CONST TOTAL_PATH    = 105   ' Total entrance trajectory steps

' Colors (Color Stack foreground 0-7 only)
CONST COL_BLACK     = 0
CONST COL_BLUE      = 1
CONST COL_RED       = 2
CONST COL_TAN       = 3
CONST COL_DGREEN    = 4
CONST COL_GREEN     = 5
CONST COL_YELLOW    = 6
CONST COL_WHITE     = 7

' GRAM card assignments (16 cards total)
CONST GC_ALIEN0     = 0
CONST GC_ALIEN1     = 1
CONST GC_ALIEN2     = 2
CONST GC_ALIEN3     = 3
CONST GC_ALIEN4     = 4
CONST GC_ALIEN5     = 5
CONST GC_HULL       = 6
CONST GC_DOME_L     = 7
CONST GC_DOME_R     = 8
CONST GC_BOT_L      = 9
CONST GC_BOT_R      = 10
CONST GC_ENGINE     = 11
CONST GC_SHIELD     = 12
CONST GC_SHIP       = 13
CONST GC_EXPLODE    = 14
CONST GC_BULLET     = 15

' Saucer layout positions (BACKTAB coordinates)
CONST SAUCER_LEFT   = 3
CONST SAUCER_RIGHT  = 16
CONST DOME_TOP      = 1
CONST HULL_TOP      = 2
CONST HULL_BOTTOM   = 5
CONST BOT_ROW       = 6
CONST VP_LEFT       = 8
CONST VP_RIGHT      = 11

' Player
CONST PLAYER_Y      = 88
CONST PLAYER_MIN_X  = 8
CONST PLAYER_MAX_X  = 152
CONST BULLET_SPEED  = 3

' Shield
CONST SHIELD_WIDTH  = 2
CONST GAP_INTERVAL  = 50

' Sprite flags
CONST SPR_VIS       = $0200

' Game states
CONST GS_ENTRANCE   = 0
CONST GS_PLAYING    = 1
CONST GS_DYING      = 2
CONST GS_RESPAWN    = 3

' --- Variables ---
PlayerX      = 80
BulletActive = 0
BulletX      = 0
BulletY      = 0
BulletCol    = 0
BulletRow    = 0

BossHP       = BOSS_MAX_HP
BossColor    = COL_WHITE
HitFlash     = 0

ShieldOff    = 0
ShieldDir    = 0
GapTimer     = 0

AnimFrame    = 0
ShimmerCount = 0

GameState    = GS_ENTRANCE
EntStep      = 0
EntTimer     = 0

' SCROLL-based flight variables
PathStep     = 0
FlyTimer     = 0
FlyCol       = 255     ' Current alien card column (255 = not drawn)
FlyRow       = 255     ' Current alien card row
TargetX      = 0       ' Target pixel X from trajectory
TargetY      = 0       ' Target pixel Y from trajectory
NewCardCol   = 0       ' Computed card column
NewCardRow   = 0       ' Computed card row
ScrollX      = 0       ' Sub-pixel scroll offset X (0-7)
ScrollY      = 0       ' Sub-pixel scroll offset Y (0-7)

DeathTimer   = 0

#Score       = 0
#Card        = 0
#ScreenPos   = 0

Row          = 0
Col          = 0
LoopVar      = 0
GramCard     = 0
IsShielded   = 0

' --- Initialization ---
MODE 0, 0, 0, 0, 0
CLS
BORDER 0
WAIT

' Define GRAM cards (4 per WAIT)
DEFINE 0, 4, GfxBatch0
WAIT
DEFINE 4, 4, GfxBatch1
WAIT
DEFINE 8, 4, GfxBatch2
WAIT
DEFINE 12, 4, GfxBatch3
WAIT

' No HUD during entrance — drawn after saucer build

' --- Main Loop ---
MainLoop:
    WAIT

    ' Animation counters (always run)
    ShimmerCount = ShimmerCount + 1
    IF ShimmerCount >= 16 THEN
        ShimmerCount = 0
        AnimFrame = AnimFrame XOR 1
    END IF

    IF GameState = GS_ENTRANCE THEN
        GOSUB DoEntrance
    ELSEIF GameState = GS_PLAYING THEN
        GOSUB ReadInput
        GOSUB UpdateShield
        GOSUB MoveBullet
        GOSUB DrawPlayer
        IF ShimmerCount = 0 THEN
            GOSUB DrawAlienLegs
        END IF
        IF HitFlash > 0 THEN
            HitFlash = HitFlash - 1
            IF HitFlash = 0 THEN
                BossColor = COL_WHITE
                GOSUB DrawViewport
            END IF
        END IF
    ELSEIF GameState = GS_DYING THEN
        GOSUB DoBossDeath
        GOSUB DrawPlayer
    ELSEIF GameState = GS_RESPAWN THEN
        DeathTimer = DeathTimer - 1
        GOSUB DrawPlayer
        IF DeathTimer = 0 THEN
            GOSUB ResetBoss
        END IF
    END IF

    GOTO MainLoop

' ============================================
' ENTRANCE — Smooth SCROLL figure-8 flight
' then saucer materialization
' ============================================
' EntStep 0: Brief pause (black screen)
' EntStep 1: SCROLL-based figure-8 flight (sub-pixel smooth)
' EntStep 2: Pause at final position
' EntStep 3: Draw inner hull pillars
' EntStep 4: Draw outer hull
' EntStep 5: Draw dome and bottom
' EntStep 6: Shields engage
' EntStep 7: Draw HUD, start combat

DoEntrance: PROCEDURE
    EntTimer = EntTimer + 1

    IF EntStep = 0 THEN
        ' --- Brief black screen pause ---
        IF EntTimer >= 30 THEN
            PathStep = 0
            FlyTimer = 0
            FlyCol = 255
            FlyRow = 255
            EntStep = 1
            EntTimer = 0
        END IF

    ELSEIF EntStep = 1 THEN
        ' --- SMOOTH SCROLL FIGURE-8 FLIGHT ---
        ' Screen is black except for 4x4 alien on BACKTAB.
        ' SCROLL shifts entire display for sub-pixel positioning.
        ' Alien card position only changes at card boundaries.

        FlyTimer = FlyTimer + 1
        IF FlyTimer >= 2 THEN
            FlyTimer = 0

            ' Get target pixel position from trajectory table
            TargetX = Figure8X(PathStep)
            TargetY = Figure8Y(PathStep)

            ' Compute card position (ceiling division by 8)
            NewCardCol = (TargetX + 7) / 8
            NewCardRow = (TargetY + 7) / 8

            ' If card position changed, clear old and draw new
            IF NewCardCol <> FlyCol OR NewCardRow <> FlyRow THEN
                IF FlyCol < 255 THEN
                    GOSUB ClearAlienFlight
                END IF
                FlyCol = NewCardCol
                FlyRow = NewCardRow
                GOSUB DrawAlienFlight
            ELSEIF ShimmerCount = 0 THEN
                ' Redraw for leg wiggle animation
                GOSUB DrawAlienFlight
            END IF

            ' Compute sub-pixel scroll offset (0-7)
            ' Formula: scroll = (8 - (pixel AND 7)) AND 7
            ' This makes: card*8 - scroll = target pixel
            ScrollX = (8 - (TargetX AND 7)) AND 7
            ScrollY = (8 - (TargetY AND 7)) AND 7
            SCROLL ScrollX, ScrollY

            ' Engine hum — tone follows height
            SOUND 2, 100 + TargetY * 4, 5

            ' Advance path
            PathStep = PathStep + 1
            IF PathStep >= TOTAL_PATH THEN
                ' Flight complete — alien at card(8,2), scroll(0,0)
                SCROLL 0, 0
                SOUND 2, , 0
                EntStep = 2
                EntTimer = 0
            END IF
        END IF

    ELSEIF EntStep = 2 THEN
        ' --- Pause at final position (alien visible, menacing) ---
        ' Redraw for leg animation during pause
        IF ShimmerCount = 0 THEN
            GOSUB DrawAlienFlight
        END IF
        IF EntTimer >= 30 THEN
            EntStep = 3
            EntTimer = 0
        END IF

    ELSEIF EntStep = 3 THEN
        ' --- Draw inner hull pillars (cols 7 and 12) ---
        IF EntTimer >= 12 THEN
            FOR Row = HULL_TOP TO HULL_BOTTOM
                PRINT AT Row * 20 + 7, GC_HULL * 8 + COL_YELLOW + $0800
                PRINT AT Row * 20 + 12, GC_HULL * 8 + COL_YELLOW + $0800
            NEXT Row
            SOUND 2, 300, 6
            EntStep = 4
            EntTimer = 0
        END IF

    ELSEIF EntStep = 4 THEN
        ' --- Draw outer hull (cols 3-6, 13-16) ---
        IF EntTimer >= 12 THEN
            FOR Row = HULL_TOP TO HULL_BOTTOM
                FOR Col = SAUCER_LEFT TO 6
                    PRINT AT Row * 20 + Col, GC_HULL * 8 + COL_YELLOW + $0800
                NEXT Col
                FOR Col = 13 TO SAUCER_RIGHT
                    PRINT AT Row * 20 + Col, GC_HULL * 8 + COL_YELLOW + $0800
                NEXT Col
            NEXT Row
            SOUND 2, 250, 6
            EntStep = 5
            EntTimer = 0
        END IF

    ELSEIF EntStep = 5 THEN
        ' --- Draw dome and bottom ---
        IF EntTimer >= 12 THEN
            GOSUB DrawDome
            GOSUB DrawBottom
            SOUND 2, 200, 6
            EntStep = 6
            EntTimer = 0
        END IF

    ELSEIF EntStep = 6 THEN
        ' --- Shields engage ---
        IF EntTimer >= 20 THEN
            ShieldOff = 1
            ShieldDir = 0
            GOSUB DrawViewport
            SOUND 2, 150, 8
            EntStep = 7
            EntTimer = 0
        END IF

    ELSEIF EntStep = 7 THEN
        ' --- Draw HUD, brief pause, then combat ---
        IF EntTimer = 10 THEN
            SOUND 2, , 0
            GOSUB DrawHUD
        END IF
        IF EntTimer >= 30 THEN
            GameState = GS_PLAYING
            GapTimer = 0
        END IF
    END IF

    GOSUB DrawPlayer
    RETURN
END

' ============================================
' ALIEN FLIGHT DRAWING — Card-position based
' ============================================
' Uses FlyCol, FlyRow (card coordinates 0-19, 0-11)
' Draws 4x4 alien at that BACKTAB position.
' SCROLL provides sub-pixel visual offset.

DrawAlienFlight: PROCEDURE
    FOR Row = 0 TO 3
        IF FlyRow + Row < 12 THEN
            #ScreenPos = (FlyRow + Row) * 20
            FOR Col = 0 TO 3
                IF FlyCol + Col < 20 THEN
                    GOSUB GetAlienCard
                    IF GramCard < 255 THEN
                        ' Tentacle wiggle: swap legs on AnimFrame
                        IF AnimFrame THEN
                            IF GramCard = GC_ALIEN4 THEN
                                GramCard = GC_ALIEN5
                            ELSEIF GramCard = GC_ALIEN5 THEN
                                GramCard = GC_ALIEN4
                            END IF
                        END IF
                        #Card = GramCard * 8 + BossColor + $0800
                        PRINT AT #ScreenPos + FlyCol + Col, #Card
                    END IF
                END IF
            NEXT Col
        END IF
    NEXT Row
    RETURN
END

' Clear 4x4 alien at FlyCol, FlyRow
ClearAlienFlight: PROCEDURE
    FOR Row = 0 TO 3
        IF FlyRow + Row < 12 THEN
            #ScreenPos = (FlyRow + Row) * 20
            FOR Col = 0 TO 3
                IF FlyCol + Col < 20 THEN
                    PRINT AT #ScreenPos + FlyCol + Col, 0
                END IF
            NEXT Col
        END IF
    NEXT Row
    RETURN
END

' ============================================
' SAUCER DRAWING
' ============================================
DrawDome: PROCEDURE
    PRINT AT DOME_TOP * 20 + 5, GC_DOME_L * 8 + COL_YELLOW + $0800
    FOR Col = 6 TO 13
        PRINT AT DOME_TOP * 20 + Col, GC_HULL * 8 + COL_YELLOW + $0800
    NEXT Col
    PRINT AT DOME_TOP * 20 + 14, GC_DOME_R * 8 + COL_YELLOW + $0800
    RETURN
END

DrawBottom: PROCEDURE
    PRINT AT BOT_ROW * 20 + 5, GC_BOT_L * 8 + COL_YELLOW + $0800
    PRINT AT BOT_ROW * 20 + 6, GC_HULL * 8 + COL_YELLOW + $0800
    PRINT AT BOT_ROW * 20 + 7, GC_HULL * 8 + COL_YELLOW + $0800
    PRINT AT BOT_ROW * 20 + 8, GC_ENGINE * 8 + COL_RED + $0800
    PRINT AT BOT_ROW * 20 + 9, GC_ENGINE * 8 + COL_RED + $0800
    PRINT AT BOT_ROW * 20 + 10, GC_ENGINE * 8 + COL_RED + $0800
    PRINT AT BOT_ROW * 20 + 11, GC_ENGINE * 8 + COL_RED + $0800
    PRINT AT BOT_ROW * 20 + 12, GC_HULL * 8 + COL_YELLOW + $0800
    PRINT AT BOT_ROW * 20 + 13, GC_HULL * 8 + COL_YELLOW + $0800
    PRINT AT BOT_ROW * 20 + 14, GC_BOT_R * 8 + COL_YELLOW + $0800
    RETURN
END

' ============================================
' VIEWPORT — Alien + sliding shields
' ============================================
DrawViewport: PROCEDURE
    FOR Row = 0 TO 3
        #ScreenPos = (HULL_TOP + Row) * 20
        FOR Col = 0 TO 3
            IsShielded = 0
            IF Col >= ShieldOff THEN
                IF Col < ShieldOff + SHIELD_WIDTH THEN
                    IsShielded = 1
                END IF
            END IF

            IF IsShielded THEN
                PRINT AT #ScreenPos + VP_LEFT + Col, GC_SHIELD * 8 + COL_BLUE + $0800
            ELSE
                GOSUB GetAlienCard
                IF GramCard = 255 THEN
                    PRINT AT #ScreenPos + VP_LEFT + Col, 0
                ELSE
                    IF AnimFrame THEN
                        IF GramCard = GC_ALIEN4 THEN
                            GramCard = GC_ALIEN5
                        ELSEIF GramCard = GC_ALIEN5 THEN
                            GramCard = GC_ALIEN4
                        END IF
                    END IF
                    #Card = GramCard * 8 + BossColor + $0800
                    PRINT AT #ScreenPos + VP_LEFT + Col, #Card
                END IF
            END IF
        NEXT Col
    NEXT Row
    RETURN
END

' Look up alien card for grid position (Row, Col = 0-3)
GetAlienCard: PROCEDURE
    IF Row = 0 THEN
        IF Col = 0 OR Col = 3 THEN
            GramCard = 255
        ELSEIF Col = 1 THEN
            GramCard = GC_ALIEN0
        ELSE
            GramCard = GC_ALIEN1
        END IF
    ELSEIF Row = 1 THEN
        IF Col = 0 THEN
            GramCard = GC_ALIEN0
        ELSEIF Col = 1 THEN
            GramCard = GC_ALIEN2
        ELSEIF Col = 2 THEN
            GramCard = GC_ALIEN3
        ELSE
            GramCard = GC_ALIEN1
        END IF
    ELSEIF Row = 2 THEN
        IF Col <= 1 THEN
            GramCard = GC_ALIEN2
        ELSE
            GramCard = GC_ALIEN3
        END IF
    ELSE
        IF Col = 0 THEN
            GramCard = GC_ALIEN4
        ELSEIF Col = 3 THEN
            GramCard = GC_ALIEN5
        ELSE
            GramCard = 255
        END IF
    END IF
    RETURN
END

DrawAlienLegs: PROCEDURE
    #ScreenPos = (HULL_TOP + 3) * 20
    FOR Col = 0 TO 3
        IsShielded = 0
        IF Col >= ShieldOff THEN
            IF Col < ShieldOff + SHIELD_WIDTH THEN
                IsShielded = 1
            END IF
        END IF
        IF IsShielded = 0 THEN
            Row = 3
            GOSUB GetAlienCard
            IF GramCard < 255 THEN
                IF AnimFrame THEN
                    IF GramCard = GC_ALIEN4 THEN
                        GramCard = GC_ALIEN5
                    ELSEIF GramCard = GC_ALIEN5 THEN
                        GramCard = GC_ALIEN4
                    END IF
                END IF
                #Card = GramCard * 8 + BossColor + $0800
                PRINT AT #ScreenPos + VP_LEFT + Col, #Card
            END IF
        END IF
    NEXT Col
    RETURN
END

' ============================================
' SHIELD UPDATE
' ============================================
UpdateShield: PROCEDURE
    GapTimer = GapTimer + 1
    IF GapTimer < GAP_INTERVAL THEN RETURN
    GapTimer = 0

    IF ShieldDir = 0 THEN
        ShieldOff = ShieldOff + 1
        IF ShieldOff >= 3 THEN
            ShieldOff = 2
            ShieldDir = 1
        END IF
    ELSE
        IF ShieldOff > 0 THEN
            ShieldOff = ShieldOff - 1
        END IF
        IF ShieldOff = 0 THEN
            ShieldDir = 0
        END IF
    END IF

    GOSUB DrawViewport
    RETURN
END

' ============================================
' HUD
' ============================================
DrawHUD: PROCEDURE
    PRINT AT 0 COLOR COL_WHITE, "SCORE"
    PRINT AT 6 COLOR COL_WHITE, <>#Score
    PRINT AT 15 COLOR COL_WHITE, "HP"
    PRINT AT 18 COLOR COL_WHITE, <> BossHP
    RETURN
END

' ============================================
' INPUT
' ============================================
ReadInput: PROCEDURE
    IF CONT.LEFT THEN
        IF PlayerX > PLAYER_MIN_X THEN PlayerX = PlayerX - 2
    END IF
    IF CONT.RIGHT THEN
        IF PlayerX < PLAYER_MAX_X THEN PlayerX = PlayerX + 2
    END IF
    IF CONT.BUTTON THEN
        IF BulletActive = 0 THEN
            BulletActive = 1
            BulletX = PlayerX + 4
            BulletY = PLAYER_Y - 4
            SOUND 2, 800, 10
        END IF
    END IF
    RETURN
END

' ============================================
' BULLET — PEEK-based collision
' ============================================
MoveBullet: PROCEDURE
    IF BulletActive = 0 THEN
        SPRITE 1, 0, 0, 0
        RETURN
    END IF

    BulletY = BulletY - BULLET_SPEED

    IF BulletY < 8 OR BulletY > 200 THEN
        BulletActive = 0
        SPRITE 1, 0, 0, 0
        RETURN
    END IF

    BulletCol = (BulletX - 8) / 8
    BulletRow = (BulletY - 8) / 8

    IF BulletRow >= DOME_TOP AND BulletRow <= BOT_ROW THEN
        #ScreenPos = BulletRow * 20 + BulletCol
        #Card = PEEK($200 + #ScreenPos)

        IF #Card = 0 THEN
            ' Empty — pass through
        ELSEIF #Card AND $0800 THEN
            GramCard = (#Card AND $01F8) / 8
            IF GramCard <= GC_ALIEN5 THEN
                BulletActive = 0
                SPRITE 1, 0, 0, 0
                GOSUB DamageAlien
                RETURN
            ELSEIF GramCard = GC_SHIELD THEN
                BulletActive = 0
                SPRITE 1, 0, 0, 0
                SOUND 2, 200, 6
                RETURN
            ELSE
                BulletActive = 0
                SPRITE 1, 0, 0, 0
                SOUND 2, 150, 4
                RETURN
            END IF
        END IF
    END IF

    IF BulletActive THEN
        SPRITE 1, BulletX + SPR_VIS, BulletY, GC_BULLET * 8 + COL_WHITE + $0800
    END IF
    RETURN
END

' ============================================
' DAMAGE
' ============================================
DamageAlien: PROCEDURE
    IF BossHP > 0 THEN
        BossHP = BossHP - 1
        #Score = #Score + 100
    END IF

    IF BossHP = 0 THEN
        GameState = GS_DYING
        DeathTimer = 0
        SOUND 2, 40, 15
    ELSE
        BossColor = COL_RED
        HitFlash = 10
        GOSUB DrawViewport
        GOSUB DrawHUD
        SOUND 2, 120, 12
    END IF
    RETURN
END

' ============================================
' BOSS DEATH
' ============================================
DoBossDeath: PROCEDURE
    DeathTimer = DeathTimer + 1

    IF DeathTimer <= 30 THEN
        IF (DeathTimer AND 3) = 0 THEN
            Row = HULL_TOP + RANDOM(4)
            Col = VP_LEFT + RANDOM(4)
            PRINT AT Row * 20 + Col, GC_EXPLODE * 8 + COL_RED + $0800
        END IF
        IF DeathTimer <= 15 THEN
            LoopVar = 15 - DeathTimer
            SOUND 2, 30 + DeathTimer * 8, LoopVar
        END IF
    ELSEIF DeathTimer = 35 THEN
        FOR Row = HULL_TOP TO HULL_BOTTOM
            FOR Col = VP_LEFT TO VP_RIGHT
                PRINT AT Row * 20 + Col, 0
            NEXT Col
        NEXT Row
    ELSEIF DeathTimer = 45 THEN
        FOR Row = HULL_TOP TO HULL_BOTTOM
            PRINT AT Row * 20 + 7, 0
            PRINT AT Row * 20 + 12, 0
        NEXT Row
        SOUND 2, , 0
    ELSEIF DeathTimer = 55 THEN
        FOR Row = HULL_TOP TO HULL_BOTTOM
            FOR Col = SAUCER_LEFT TO 6
                PRINT AT Row * 20 + Col, 0
            NEXT Col
            FOR Col = 13 TO SAUCER_RIGHT
                PRINT AT Row * 20 + Col, 0
            NEXT Col
        NEXT Row
    ELSEIF DeathTimer = 65 THEN
        FOR Col = 5 TO 14
            PRINT AT DOME_TOP * 20 + Col, 0
            PRINT AT BOT_ROW * 20 + Col, 0
        NEXT Col
    ELSEIF DeathTimer >= 80 THEN
        GameState = GS_RESPAWN
        DeathTimer = RESPAWN_TIME
    END IF
    RETURN
END

' ============================================
' RESPAWN
' ============================================
ResetBoss: PROCEDURE
    BossHP = BOSS_MAX_HP
    BossColor = COL_WHITE
    HitFlash = 0
    ShieldOff = 0
    ShieldDir = 0
    GapTimer = 0
    GameState = GS_ENTRANCE
    EntStep = 0
    EntTimer = 0
    FlyCol = 255
    FlyRow = 255
    PathStep = 0
    CLS
    WAIT
    RETURN
END

' ============================================
' PLAYER
' ============================================
DrawPlayer: PROCEDURE
    SPRITE 0, PlayerX + SPR_VIS, PLAYER_Y, GC_SHIP * 8 + COL_GREEN + $0800
    RETURN
END

' ============================================
' DATA — SCROLL-based trajectory tables
' ============================================
' 105 steps: 80-step Lissajous figure-8 + 25-step cosine-ease ascent
' Figure-8: center (64,36), amplitude X=44, Y=16
' Ascent: (64,36) to (64,16) with ease-in-out
' Pixel positions for alien top-left corner.
' At step 0: pixel(64,36) -> card(8,5) -> center of screen
' At step 104: pixel(64,16) -> card(8,2) -> saucer viewport position

' X pixel trajectory (105 entries)
Figure8X:
    DATA 64, 67, 71, 74, 78, 81, 84, 87, 90, 93
    DATA 95, 97, 100, 102, 103, 105, 106, 107, 107, 108
    DATA 108, 108, 107, 107, 106, 105, 103, 102, 100, 97
    DATA 95, 93, 90, 87, 84, 81, 78, 74, 71, 67
    DATA 64, 61, 57, 54, 50, 47, 44, 41, 38, 35
    DATA 33, 31, 28, 26, 25, 23, 22, 21, 21, 20
    DATA 20, 20, 21, 21, 22, 23, 25, 26, 28, 31
    DATA 33, 35, 38, 41, 44, 47, 50, 54, 57, 61
    DATA 64, 64, 64, 64, 64, 64, 64, 64, 64, 64
    DATA 64, 64, 64, 64, 64, 64, 64, 64, 64, 64
    DATA 64, 64, 64, 64, 64

' Y pixel trajectory (105 entries)
Figure8Y:
    DATA 36, 39, 41, 43, 45, 47, 49, 50, 51, 52
    DATA 52, 52, 51, 50, 49, 47, 45, 43, 41, 39
    DATA 36, 33, 31, 29, 27, 25, 23, 22, 21, 20
    DATA 20, 20, 21, 22, 23, 25, 27, 29, 31, 33
    DATA 36, 39, 41, 43, 45, 47, 49, 50, 51, 52
    DATA 52, 52, 51, 50, 49, 47, 45, 43, 41, 39
    DATA 36, 33, 31, 29, 27, 25, 23, 22, 21, 20
    DATA 20, 20, 21, 22, 23, 25, 27, 29, 31, 33
    DATA 36, 36, 36, 35, 35, 34, 33, 32, 31, 30
    DATA 29, 27, 26, 25, 23, 22, 21, 20, 19, 18
    DATA 17, 17, 16, 16, 16

' ============================================
' GRAM GRAPHICS DATA
' ============================================

' Batch 0: Cards 0-3 (alien upper body)
GfxBatch0:
    ' Card 0 — right-half top, full bottom
    BITMAP "....XXXX"
    BITMAP "....XXXX"
    BITMAP "....XXXX"
    BITMAP "....XXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    ' Card 1 — left-half top, full bottom
    BITMAP "XXXX...."
    BITMAP "XXXX...."
    BITMAP "XXXX...."
    BITMAP "XXXX...."
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    ' Card 2 — full top, right-half bottom
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "....XXXX"
    BITMAP "....XXXX"
    BITMAP "....XXXX"
    BITMAP "....XXXX"
    ' Card 3 — full top, left-half bottom
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXX...."
    BITMAP "XXXX...."
    BITMAP "XXXX...."
    BITMAP "XXXX...."

' Batch 1: Cards 4-7 (alien legs + hull + dome-L)
GfxBatch1:
    ' Card 4 — leg left
    BITMAP "XXXX...."
    BITMAP "XXXX...."
    BITMAP "XXXX...."
    BITMAP "XXXX...."
    BITMAP "....XXXX"
    BITMAP "....XXXX"
    BITMAP "....XXXX"
    BITMAP "....XXXX"
    ' Card 5 — leg right
    BITMAP "....XXXX"
    BITMAP "....XXXX"
    BITMAP "....XXXX"
    BITMAP "....XXXX"
    BITMAP "XXXX...."
    BITMAP "XXXX...."
    BITMAP "XXXX...."
    BITMAP "XXXX...."
    ' Card 6 — Saucer hull
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "X.X..X.X"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "X..XX..X"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    ' Card 7 — Dome slope left
    BITMAP "........"
    BITMAP "........"
    BITMAP "......XX"
    BITMAP "....XXXX"
    BITMAP "..XXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"

' Batch 2: Cards 8-11
GfxBatch2:
    ' Card 8 — Dome slope right
    BITMAP "........"
    BITMAP "........"
    BITMAP "XX......"
    BITMAP "XXXX...."
    BITMAP "XXXXXX.."
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    ' Card 9 — Bottom slope left
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXX.."
    BITMAP "XXXX...."
    BITMAP "XX......"
    BITMAP "........"
    BITMAP "........"
    ' Card 10 — Bottom slope right
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "..XXXXXX"
    BITMAP "....XXXX"
    BITMAP "......XX"
    BITMAP "........"
    BITMAP "........"
    ' Card 11 — Engine flame
    BITMAP "XXXXXXXX"
    BITMAP ".XX..XX."
    BITMAP "..X..X.."
    BITMAP ".XX..XX."
    BITMAP "..X..X.."
    BITMAP "...XX..."
    BITMAP "........"
    BITMAP "........"

' Batch 3: Cards 12-15
GfxBatch3:
    ' Card 12 — Shield panel
    BITMAP "X.X.X.X."
    BITMAP ".X.X.X.X"
    BITMAP "X.X.X.X."
    BITMAP ".X.X.X.X"
    BITMAP "X.X.X.X."
    BITMAP ".X.X.X.X"
    BITMAP "X.X.X.X."
    BITMAP ".X.X.X.X"
    ' Card 13 — Player ship
    BITMAP "........"
    BITMAP "...XX..."
    BITMAP "...XX..."
    BITMAP "..XXXX.."
    BITMAP "X.X..X.X"
    BITMAP "XXXXXXXX"
    BITMAP "XX....XX"
    BITMAP "........"
    ' Card 14 — Explosion
    BITMAP "X..XX..X"
    BITMAP "..X..X.."
    BITMAP ".X....X."
    BITMAP "X......X"
    BITMAP "X......X"
    BITMAP ".X....X."
    BITMAP "..X..X.."
    BITMAP "X..XX..X"
    ' Card 15 — Bullet
    BITMAP "........"
    BITMAP "...XX..."
    BITMAP "...XX..."
    BITMAP "...XX..."
    BITMAP "...XX..."
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
