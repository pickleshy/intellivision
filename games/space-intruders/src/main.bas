' ============================================
' SPACE INTRUDERS
' A Space Invaders clone for Intellivision
' ============================================

OPTION MAP 2    ' Enable 42K ROM

' --------------------------------------------
' Constants
' --------------------------------------------
CONST PLAYER_Y      = 88        ' Player Y position (near bottom)
CONST PLAYER_MIN_X  = 8         ' Left boundary
CONST PLAYER_MAX_X  = 152       ' Right boundary (160 - 8 for sprite width)
CONST PLAYER_SPEED  = 2         ' Pixels per frame

' Sprite slot assignments
CONST SPR_PLAYER    = 0         ' Player ship sprite
CONST SPR_PBULLET   = 1         ' Player bullet sprite
CONST SPR_ABULLET   = 2         ' Alien bullet sprite
CONST SPR_EXPLOSION = 3         ' Explosion effect sprite

' GRAM card assignments
CONST GRAM_SHIP     = 0         ' Player ship graphic (2 cards)
CONST GRAM_ALIEN1   = 2         ' Top row alien (2 cards for animation)
CONST GRAM_ALIEN2   = 4         ' Middle rows alien
CONST GRAM_ALIEN3   = 6         ' Bottom rows alien
CONST GRAM_BULLET   = 8         ' Bullet graphic
' Title screen color banding test - 4 cards, each with 2 rows of alien
CONST GRAM_BAND1    = 9         ' Rows 1-2 of alien
CONST GRAM_BAND2    = 10        ' Rows 3-4 of alien
CONST GRAM_BAND3    = 11        ' Rows 5-6 of alien
CONST GRAM_BAND4    = 12        ' Rows 7-8 of alien
CONST GRAM_INV_TEST = 13        ' Inverted alien for testing
CONST GRAM_EXPLOSION = 14       ' Explosion frame 1 (tight pop)
CONST GRAM_EXPLOSION2 = 15      ' Explosion frame 2 (expanding scatter)
CONST GRAM_EXPLOSION3 = 16      ' Explosion frame 3 (dissipate)
CONST GRAM_SHIP_ACCENT = 17     ' Ship accent overlay (2 cards for animation)

' Additional sprite slots
CONST SPR_SHIP_ACCENT = 4       ' Ship accent sprite (stacked for 2-color effect)

' Alien grid constants
CONST ALIEN_COLS    = 11        ' 11 aliens per row
CONST ALIEN_ROWS    = 5         ' 5 rows of aliens
CONST ALIEN_START_X = 1         ' Starting column on screen (leftmost)
CONST ALIEN_START_Y = 1         ' Starting row on screen
CONST ALIEN_MAX_X   = 8         ' Maximum X offset before reversing (20 - 11 - 1)
' CONST MARCH_SPEED_START = 160   ' Starting frames between march steps
CONST MARCH_SPEED_START = 60   ' Starting frames between march steps
CONST MARCH_SPEED_MIN = 20      ' Fastest march speed (minimum frames)

' Bullet constants
CONST BULLET_SPEED  = 1         ' Player bullet speed (slower)
CONST BULLET_TOP    = 8         ' Top of screen
CONST ALIEN_BULLET_SPEED = 2    ' Alien bullet speed
CONST ALIEN_SHOOT_RATE = 90     ' Frames between alien shots

' Colors
CONST COL_WHITE     = 7
CONST COL_GREEN     = 5
CONST COL_YELLOW    = 6
CONST COL_BLACK     = 0
CONST COL_RED       = 2
CONST COL_TAN       = 3
CONST COL_CYAN      = 9
CONST COL_PINK      = 12
CONST COL_LTBLUE    = 13
CONST COL_PURPLE    = 15

' Game constants
CONST STARTING_LIVES = 4          ' 4 ships total (current + 3 extras)

' Sprite flags (standard IntyBASIC values)
CONST SPR_VISIBLE   = $0200     ' Make sprite visible
CONST SPR_HIT       = $0100     ' Enable collision detection

' --------------------------------------------
' Variables
' --------------------------------------------
DIM #AlienRow(ALIEN_ROWS)       ' Bitmask of alive aliens per row (11 bits, needs 16-bit)
DIM RowColors(5)                ' 5-color cycle for row shimmer (colors 1-6 only)
PlayerX     = 80                ' Player X position (center)
AnimFrame   = 0                 ' Animation frame (0 or 1)
FrameCount  = 0                 ' Frame counter for animation timing
ColorPhase  = 0                 ' Color shimmer phase (0-7)
ShimmerCount = 0                ' Frame counter for shimmer updates
AlienOffsetX = 0                ' Alien grid X offset (0 to ALIEN_MAX_X)
AlienOffsetY = 0                ' Alien grid Y offset (drops down)
AlienDir    = 1                 ' Movement direction (1=right, 255=left using unsigned)
MarchCount  = 0                 ' Frame counter for march timing
BulletX     = 0                 ' Bullet X position
BulletY     = 0                 ' Bullet Y position
BulletActive = 0                ' 1 = bullet flying, 0 = ready to fire
BulletColor = 0                 ' Bullet color phase (0-2 for color cycling)
LaserColor  = 0                 ' Current laser color (calculated each frame)
ABulletX    = 0                 ' Alien bullet X position
ABulletY    = 0                 ' Alien bullet Y position
ABulletActive = 0               ' 1 = alien bullet flying
ShootTimer  = 0                 ' Countdown to next alien shot
ShootCol    = 0                 ' Column to shoot from
#Score      = 0                 ' Player score
PlayerHit   = 0                 ' 1 = player was hit
HitTimer    = 0                 ' Countdown for hit effect
DeathTimer  = 0                 ' Countdown during death animation
Invincible  = 0                 ' Invincibility timer after respawn
Lives       = STARTING_LIVES    ' Player lives remaining
Level       = 1                 ' Current wave/level
GameOver    = 0                 ' 1 = game over state
CurrentMarchSpeed = 160         ' Current march speed (decreases per wave)
#AliensAlive = 0                ' Count of remaining aliens
HitCol      = 0                 ' Collision check - column
HitRow      = 0                 ' Collision check - row
AlienGridRow = 0                ' Which row in alien grid
AlienGridCol = 0                ' Which column in alien grid
LoopVar     = 0                 ' General loop variable
Row         = 0                 ' Row counter for drawing
Col         = 0                 ' Column counter for drawing
AlienCard   = 0                 ' Current alien GRAM card
AlienColor  = 0                 ' Current alien color
ColorIndex  = 0                 ' Index into shimmer color cycle
#ScreenPos  = 0                 ' Screen position (16-bit for multiplication)
#Mask       = 0                 ' Bitmask for checking alive aliens
#Card       = 0                 ' Card value for PRINT
GameState   = 0                 ' 0 = title screen, 1 = playing
TitleColor  = 0                 ' Color index for title sprite shimmer
TitleFrame  = 0                 ' Animation frame for title alien
ShakeTimer  = 0                 ' Screen shake countdown (0 = no shake)
TitleMarchX = 0                 ' Title screen alien X offset
TitleMarchDir = 1               ' Title march direction (1=right, 0=left)
TitleMarchCount = 0             ' Title march timing counter
ExplosionTimer = 0              ' Explosion display countdown (0 = no explosion)
#ExplosionPos  = 0              ' Explosion BACKTAB position (screen address)
ExplosionColor = 0              ' Explosion color (matches destroyed alien)

' --------------------------------------------
' Main Program
' --------------------------------------------
    WAIT

    ' Set up graphics mode - Color Stack mode (same encoding as sprites!)
    MODE 0, 0, 0, 0, 0   ' Black color stack

    ' Clear screen first
    CLS

    ' Define graphics in GRAM (after CLS to ensure clean state)
    ' Add WAIT between each DEFINE to ensure proper loading
    DEFINE GRAM_SHIP, 2, ShipGfx
    WAIT
    DEFINE GRAM_ALIEN1, 2, Alien1Gfx
    WAIT
    DEFINE GRAM_ALIEN2, 2, Alien2Gfx
    WAIT
    DEFINE GRAM_ALIEN3, 2, Alien3Gfx
    WAIT
    DEFINE GRAM_BULLET, 1, BulletGfx
    WAIT
    ' Color banding test cards (each has 2 rows of the alien)
    DEFINE GRAM_BAND1, 1, Band1Gfx
    WAIT
    DEFINE GRAM_BAND2, 1, Band2Gfx
    WAIT
    DEFINE GRAM_BAND3, 1, Band3Gfx
    WAIT
    DEFINE GRAM_BAND4, 1, Band4Gfx
    WAIT
    DEFINE GRAM_INV_TEST, 1, InvertedAlienGfx
    WAIT
    DEFINE GRAM_EXPLOSION, 1, ExplosionGfx
    WAIT
    DEFINE GRAM_EXPLOSION2, 1, ExplosionGfx2
    WAIT
    DEFINE GRAM_EXPLOSION3, 1, ExplosionGfx3
    WAIT
    DEFINE GRAM_SHIP_ACCENT, 2, ShipAccentGfx
    WAIT

    ' Initialize row colors (0-7 only for MODE 1)
    ' Blue, Red, Tan, Green, Yellow - rainbow wave
    RowColors(0) = 1   ' Blue
    RowColors(1) = 2   ' Red
    RowColors(2) = 3   ' Tan
    RowColors(3) = 5   ' Green
    RowColors(4) = 6   ' Yellow

' ============================================
' TITLE SCREEN
' ============================================
TitleScreen:
    CLS
    GameState = 0
    TitleColor = 0
    TitleFrame = 0
    ShimmerCount = 0
    TitleMarchX = 0
    TitleMarchDir = 1
    TitleMarchCount = 0

    ' Display title text (top half of screen)
    ' Screen is 20 columns wide, "SPACE INTRUDERS" is 15 chars
    ' Center at column 2 (position 42 = row 2 * 20 + col 2)
    PRINT AT 42, "SPACE INTRUDERS"

    ' Vertical "PRESS" and "FIRE" side by side (columns 2 and 5)
    ' Row 4
    PRINT AT 82, "P"
    PRINT AT 85, "F"
    ' Row 5
    PRINT AT 102, "R"
    PRINT AT 105, "I"
    ' Row 6
    PRINT AT 122, "E"
    PRINT AT 125, "R"
    ' Row 7
    PRINT AT 142, "S"
    PRINT AT 145, "E"
    ' Row 8
    PRINT AT 162, "S"

' --------------------------------------------
' Title Loop - 2x2 sprite grid with color banding test
' --------------------------------------------
TitleLoop:
    WAIT

    ' Cycle color phase every 8 frames (0-4 for 5 colors)
    ShimmerCount = ShimmerCount + 1
    IF ShimmerCount >= 8 THEN
        ShimmerCount = 0
        TitleColor = TitleColor + 1
        IF TitleColor > 4 THEN
            TitleColor = 0
        END IF
    END IF

    ' March animation - move every 12 frames
    TitleMarchCount = TitleMarchCount + 1
    IF TitleMarchCount >= 12 THEN
        TitleMarchCount = 0
        TitleFrame = TitleFrame XOR 1  ' Toggle animation frame
        IF TitleMarchDir = 1 THEN
            ' Moving right
            TitleMarchX = TitleMarchX + 2
            IF TitleMarchX >= 20 THEN
                TitleMarchDir = 0  ' Reverse to left
            END IF
        ELSE
            ' Moving left
            TitleMarchX = TitleMarchX - 2
            IF TitleMarchX <= 0 THEN
                TitleMarchDir = 1  ' Reverse to right
            END IF
        END IF
    END IF

    ' 3x3 grid using all 8 sprites (bottom row has 2 centered)
    ' Color banding by ROW - all sprites in a row share the same color
    ' Base X: 58 + TitleMarchX (starts left, marches right)
    ' Y positions: 40, 48, 56 (3 rows, 8 pixels apart)

    ' Row 0: sprites 0, 1, 2 (3 across)
    ColorIndex = TitleColor
    AlienColor = RowColors(ColorIndex)
    SPRITE 0, 58 + TitleMarchX + SPR_VISIBLE, 40, (GRAM_ALIEN2 + TitleFrame) * 8 + AlienColor + $0800
    SPRITE 1, 66 + TitleMarchX + SPR_VISIBLE, 40, (GRAM_ALIEN2 + TitleFrame) * 8 + AlienColor + $0800
    SPRITE 2, 74 + TitleMarchX + SPR_VISIBLE, 40, (GRAM_ALIEN2 + TitleFrame) * 8 + AlienColor + $0800

    ' Row 1: sprites 3, 4, 5 (3 across)
    ColorIndex = TitleColor + 1
    IF ColorIndex > 4 THEN ColorIndex = ColorIndex - 5
    AlienColor = RowColors(ColorIndex)
    SPRITE 3, 58 + TitleMarchX + SPR_VISIBLE, 48, (GRAM_ALIEN2 + TitleFrame) * 8 + AlienColor + $0800
    SPRITE 4, 66 + TitleMarchX + SPR_VISIBLE, 48, (GRAM_ALIEN2 + TitleFrame) * 8 + AlienColor + $0800
    SPRITE 5, 74 + TitleMarchX + SPR_VISIBLE, 48, (GRAM_ALIEN2 + TitleFrame) * 8 + AlienColor + $0800

    ' Row 2: sprites 6, 7 (2 centered - only 8 sprites available)
    ColorIndex = TitleColor + 2
    IF ColorIndex > 4 THEN ColorIndex = ColorIndex - 5
    AlienColor = RowColors(ColorIndex)
    SPRITE 6, 62 + TitleMarchX + SPR_VISIBLE, 56, (GRAM_ALIEN2 + TitleFrame) * 8 + AlienColor + $0800
    SPRITE 7, 70 + TitleMarchX + SPR_VISIBLE, 56, (GRAM_ALIEN2 + TitleFrame) * 8 + AlienColor + $0800

    ' Check for fire button to start game
    IF CONT.BUTTON THEN
        ' Hide all 8 sprites used on title screen
        SPRITE 0, 0, 0, 0
        SPRITE 1, 0, 0, 0
        SPRITE 2, 0, 0, 0
        SPRITE 3, 0, 0, 0
        SPRITE 4, 0, 0, 0
        SPRITE 5, 0, 0, 0
        SPRITE 6, 0, 0, 0
        SPRITE 7, 0, 0, 0
        GOTO StartGame
    END IF

    GOTO TitleLoop

' ============================================
' START GAME - Initialize gameplay
' ============================================
StartGame:
    GameState = 1
    CLS

    ' Initialize all aliens as alive (11 bits = $7FF)
    FOR LoopVar = 0 TO ALIEN_ROWS - 1
        #AlienRow(LoopVar) = $7FF
    NEXT LoopVar

    ' Initialize march speed
    CurrentMarchSpeed = MARCH_SPEED_START

    ' Draw the alien grid
    GOSUB DrawAliens

    ' Draw score and lives
    PRINT AT 220, "SCORE: 0"
    ' Lives ship icon as background card (GRAM + green foreground)
    PRINT AT 236, (GRAM_SHIP * 8) + (COL_GREEN * $200) + $0800
    PRINT AT 237, "x4"

    ' Initialize player sprite
    GOSUB DrawPlayer

' --------------------------------------------
' Main Game Loop
' --------------------------------------------
GameLoop:
    WAIT

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

    ' Skip gameplay if game over
    IF GameOver THEN
        IF CONT.BUTTON THEN
            ' Reset variables and go back to title screen
            GameOver = 0
            Lives = STARTING_LIVES
            Level = 1
            #Score = 0
            PlayerX = 80
            AlienOffsetX = 0
            AlienOffsetY = 0
            AlienDir = 1
            MarchCount = 0
            BulletActive = 0
            ABulletActive = 0
            DeathTimer = 0
            Invincible = 0
            ShakeTimer = 0
            SCROLL 0, 0  ' Reset scroll
            ' Hide all sprites
            SPRITE SPR_PLAYER, 0, 0, 0
            SPRITE SPR_PBULLET, 0, 0, 0
            SPRITE SPR_ABULLET, 0, 0, 0
            GOTO TitleScreen
        END IF
        GOTO GameLoop
    END IF

    ' Handle player movement and firing (only if not dead)
    IF DeathTimer = 0 THEN
        GOSUB MovePlayer
    END IF

    ' DIAGNOSTIC: Shimmer disabled - testing basic alien display first
    ' ShimmerCount = ShimmerCount + 1
    ' IF ShimmerCount >= 10 THEN
    '     ShimmerCount = 0
    '     ColorPhase = ColorPhase + 1
    '     IF ColorPhase >= 5 THEN
    '         ColorPhase = 0
    '     END IF
    '     IF MarchCount < CurrentMarchSpeed - 1 THEN
    '         GOSUB DrawAliens
    '     END IF
    ' END IF

    ' Update alien march
    MarchCount = MarchCount + 1
    IF MarchCount >= CurrentMarchSpeed THEN
        MarchCount = 0
        GOSUB MarchAliens
        AnimFrame = AnimFrame XOR 1
        GOSUB DrawAliens
        ' Check if aliens reached the bottom (invasion!)
        ' Bottom alien row = ALIEN_START_Y + AlienOffsetY + ALIEN_ROWS - 1
        ' If this reaches row 10 (one above player), game over
        IF AlienOffsetY >= 5 THEN
            GameOver = 1
            ShakeTimer = 40  ' Big shake on invasion!
            PRINT AT 105, "INVASION!"
            PRINT AT 125, "PRESS FIRE"
            SPRITE SPR_PLAYER, 0, 0, 0
        END IF
    END IF

    ' Update bullet
    IF BulletActive THEN
        GOSUB MoveBullet
    END IF

    ' Alien shooting logic
    GOSUB AlienShoot

    ' Update alien bullet
    IF ABulletActive THEN
        GOSUB MoveAlienBullet
    END IF

    ' Update explosion effect (BACKTAB tile with 3-frame animation)
    ' 15 total frames: 5 per animation frame (~83ms each, ~250ms total)
    IF ExplosionTimer > 0 THEN
        ExplosionTimer = ExplosionTimer - 1
        IF ExplosionTimer = 0 THEN
            PRINT AT #ExplosionPos, 0  ' Clear explosion from screen
        ELSEIF ExplosionTimer > 10 THEN
            ' Frame 1: tight pop (frames 15-11)
            PRINT AT #ExplosionPos, GRAM_EXPLOSION * 8 + ExplosionColor + $0800
        ELSEIF ExplosionTimer > 5 THEN
            ' Frame 2: expanding scatter (frames 10-6)
            PRINT AT #ExplosionPos, GRAM_EXPLOSION2 * 8 + ExplosionColor + $0800
        ELSE
            ' Frame 3: dissipate (frames 5-1)
            PRINT AT #ExplosionPos, GRAM_EXPLOSION3 * 8 + ExplosionColor + $0800
        END IF
    END IF

    ' Check bullet-vs-bullet collision
    IF BulletActive THEN
        IF ABulletActive THEN
            ' Check if bullets are close enough to collide
            ' X within 6 pixels, Y within 8 pixels
            IF BulletX >= ABulletX - 6 THEN
                IF BulletX <= ABulletX + 6 THEN
                    IF BulletY >= ABulletY - 8 THEN
                        IF BulletY <= ABulletY + 8 THEN
                            ' Bullets collide! Destroy both
                            BulletActive = 0
                            ABulletActive = 0
                            ' Small score bonus for the skillful shot
                            #Score = #Score + 5
                        END IF
                    END IF
                END IF
            END IF
        END IF
    END IF

    ' Check if player was hit (only if not already dying or invincible)
    IF PlayerHit THEN
        IF DeathTimer = 0 THEN
            IF Invincible = 0 THEN
                PlayerHit = 0
                Lives = Lives - 1
                ' Update lives display
                IF Lives = 3 THEN
                    PRINT AT 237, "x3"
                END IF
                IF Lives = 2 THEN
                    PRINT AT 237, "x2"
                END IF
                IF Lives = 1 THEN
                    PRINT AT 237, "x1"
                END IF
                IF Lives = 0 THEN
                    ' Game over
                    PRINT AT 237, "x0"
                    GameOver = 1
                    ShakeTimer = 30  ' Big shake on game over
                    PRINT AT 105, "GAME OVER"
                    PRINT AT 125, "PRESS FIRE"
                    SPRITE SPR_PLAYER, 0, 0, 0
                ELSE
                    ' Start death sequence (60 frames = 1 second)
                    DeathTimer = 60
                    ShakeTimer = 15  ' Shake on death
                    SPRITE SPR_PLAYER, 0, 0, 0
                END IF
            ELSE
                PlayerHit = 0
            END IF
        ELSE
            PlayerHit = 0
        END IF
    END IF

    ' Handle death timer (respawn after death)
    IF DeathTimer > 0 THEN
        DeathTimer = DeathTimer - 1
        IF DeathTimer = 0 THEN
            ' Respawn at center with invincibility
            PlayerX = 80
            Invincible = 120
        END IF
    END IF

    ' Handle invincibility countdown
    IF Invincible > 0 THEN
        Invincible = Invincible - 1
    END IF

    ' Handle hit effect timer (turns off explosion sound)
    IF HitTimer > 0 THEN
        HitTimer = HitTimer - 1
        IF HitTimer = 0 THEN
            SOUND 0, , 0
        END IF
    END IF

    ' Check if all aliens are dead (wave win)
    GOSUB CheckWaveWin

    ' Update sprites
    GOSUB DrawPlayer
    GOSUB DrawBullet
    GOSUB DrawAlienBullet

    ' Update score display
    PRINT AT 227, <>#Score

    GOTO GameLoop

' --------------------------------------------
' MovePlayer - Handle player input
' --------------------------------------------
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

    ' Fire button (any action button)
    IF CONT.BUTTON THEN
        IF BulletActive = 0 THEN
            ' Fire new bullet from player position
            BulletX = PlayerX + 3  ' Center of ship
            BulletY = PLAYER_Y - 4
            BulletActive = 1
        END IF
    END IF

    RETURN
END

' --------------------------------------------
' MarchAliens - Move alien grid
' --------------------------------------------
MarchAliens: PROCEDURE
    ' Move in current direction
    IF AlienDir = 1 THEN
        ' Moving right
        AlienOffsetX = AlienOffsetX + 1
        IF AlienOffsetX >= ALIEN_MAX_X THEN
            ' Hit right edge - drop down and reverse
            AlienOffsetY = AlienOffsetY + 1
            AlienDir = 255  ' Will subtract 1 (unsigned wraps)
        END IF
    ELSE
        ' Moving left
        IF AlienOffsetX > 0 THEN
            AlienOffsetX = AlienOffsetX - 1
        ELSE
            ' Hit left edge - drop down and reverse
            AlienOffsetY = AlienOffsetY + 1
            AlienDir = 1
        END IF
    END IF
    RETURN
END

' --------------------------------------------
' MoveBullet - Update bullet position and check collisions
' --------------------------------------------
MoveBullet: PROCEDURE
    ' Move bullet up
    IF BulletY > BULLET_TOP + BULLET_SPEED THEN
        BulletY = BulletY - BULLET_SPEED
    ELSE
        ' Bullet reached top - deactivate
        BulletActive = 0
    END IF

    ' Check collision with aliens
    IF BulletActive THEN
        GOSUB CheckBulletHit
    END IF

    RETURN
END

' --------------------------------------------
' CheckBulletHit - See if bullet hit an alien
' Uses expanded hitbox - checks wide horizontal and vertical range
' --------------------------------------------
CheckBulletHit: PROCEDURE
    ' Check primary row (where bullet tip is)
    HitRow = BulletY / 8
    GOSUB CheckRowForHit

    ' Also check row above (bullet may be straddling boundary)
    IF BulletActive THEN
        IF BulletY > 8 THEN
            HitRow = (BulletY - 4) / 8
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

            ' Check wide horizontal range (bullet center +/- tolerance)
            ' Bullet graphic center is at BulletX+3, check 6 pixel range
            HitCol = (BulletX + 1) / 8
            GOSUB CheckOneColumn

            IF BulletActive THEN
                HitCol = (BulletX + 4) / 8
                GOSUB CheckOneColumn
            END IF

            IF BulletActive THEN
                HitCol = (BulletX + 6) / 8
                GOSUB CheckOneColumn
            END IF
        END IF
    END IF
    RETURN
END

' --------------------------------------------
' CheckOneColumn - Check single column for alien hit
' Expects: HitCol, HitRow, AlienGridRow set
' --------------------------------------------
CheckOneColumn: PROCEDURE
    IF HitCol >= ALIEN_START_X + AlienOffsetX THEN
        IF HitCol < ALIEN_START_X + AlienOffsetX + ALIEN_COLS THEN
            AlienGridCol = HitCol - ALIEN_START_X - AlienOffsetX

            ' Calculate bitmask for this column
            #Mask = 1
            IF AlienGridCol > 0 THEN
                FOR LoopVar = 1 TO AlienGridCol
                    #Mask = #Mask * 2
                NEXT LoopVar
            END IF

            IF #AlienRow(AlienGridRow) AND #Mask THEN
                ' HIT! Kill the alien
                #AlienRow(AlienGridRow) = #AlienRow(AlienGridRow) XOR #Mask
                BulletActive = 0

                ' Update score
                #Score = #Score + 10

                ' Match explosion color to alien type
                IF AlienGridRow = 0 THEN
                    ExplosionColor = COL_WHITE   ' Squid
                ELSEIF AlienGridRow < 3 THEN
                    ExplosionColor = COL_RED     ' Crab
                ELSE
                    ExplosionColor = COL_GREEN   ' Octopus
                END IF

                ' Show explosion on BACKTAB (replaces alien, stays in place)
                #ExplosionPos = HitRow * 20 + HitCol
                ExplosionTimer = 15  ' Show for 15 frames (~250ms total)
                PRINT AT #ExplosionPos, GRAM_EXPLOSION * 8 + ExplosionColor + $0800
            END IF
        END IF
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
        ' Player is dead - hide both sprites
        SPRITE SPR_PLAYER, 0, 0, 0
        SPRITE SPR_SHIP_ACCENT, 0, 0, 0
    ELSEIF Invincible > 0 THEN
        ' Flash during invincibility (show every other frame)
        IF Invincible AND 4 THEN
            SPRITE SPR_PLAYER, PlayerX + $0200, PLAYER_Y, GRAM_SHIP * 8 + COL_GREEN + $0800
            SPRITE SPR_SHIP_ACCENT, PlayerX + $0200, PLAYER_Y, GRAM_SHIP_ACCENT * 8 + COL_CYAN + $0800
        ELSE
            SPRITE SPR_PLAYER, 0, 0, 0
            SPRITE SPR_SHIP_ACCENT, 0, 0, 0
        END IF
    ELSE
        ' Normal display - body + accent stacked at same position
        SPRITE SPR_PLAYER, PlayerX + $0200, PLAYER_Y, GRAM_SHIP * 8 + COL_GREEN + $0800
        SPRITE SPR_SHIP_ACCENT, PlayerX + $0200, PLAYER_Y, GRAM_SHIP_ACCENT * 8 + COL_CYAN + $0800
    END IF
    RETURN
END

' --------------------------------------------
' DrawBullet - Update bullet sprite with color cycling
' --------------------------------------------
DrawBullet: PROCEDURE
    IF BulletActive THEN
        ' Increment color timer, switch color every 4 frames
        BulletColor = BulletColor + 1
        IF BulletColor >= 8 THEN BulletColor = 0

        ' Solid red for frames 0-3, solid white for frames 4-7
        IF BulletColor < 4 THEN
            LaserColor = COL_RED
        ELSE
            LaserColor = COL_WHITE
        END IF

        SPRITE SPR_PBULLET, BulletX + $0200, BulletY, GRAM_BULLET * 8 + LaserColor + $0800
    ELSE
        ' Hide bullet sprite
        SPRITE SPR_PBULLET, 0, 0, 0
    END IF
    RETURN
END

' --------------------------------------------
' AlienShoot - Decide when and where aliens shoot
' --------------------------------------------
AlienShoot: PROCEDURE
    ' Only shoot if no alien bullet active
    IF ABulletActive = 0 THEN
        ShootTimer = ShootTimer + 1
        IF ShootTimer >= ALIEN_SHOOT_RATE THEN
            ShootTimer = 0
            ' Pick random column
            ShootCol = RANDOM(ALIEN_COLS)
            ' Find bottom-most alien in that column
            GOSUB FindShooter
        END IF
    END IF
    RETURN
END

' --------------------------------------------
' FindShooter - Find bottom alien in ShootCol to shoot
' --------------------------------------------
FindShooter: PROCEDURE
    ' Calculate bitmask for this column
    #Mask = 1
    IF ShootCol > 0 THEN
        FOR LoopVar = 1 TO ShootCol
            #Mask = #Mask * 2
        NEXT LoopVar
    END IF

    ' Search from bottom row up for an alive alien
    FOR Row = ALIEN_ROWS - 1 TO 0 STEP -1
        IF #AlienRow(Row) AND #Mask THEN
            ' Found an alien - fire from its position
            ' Calculate pixel position: card position * 8 + offset for center
            ABulletX = (ALIEN_START_X + AlienOffsetX + ShootCol) * 8 + 3
            ABulletY = (ALIEN_START_Y + AlienOffsetY + Row) * 8 + 8
            ABulletActive = 1
            RETURN
        END IF
    NEXT Row
    ' No alien in this column - don't shoot
    RETURN
END

' --------------------------------------------
' MoveAlienBullet - Move alien bullet down and check player hit
' --------------------------------------------
MoveAlienBullet: PROCEDURE
    ABulletY = ABulletY + ALIEN_BULLET_SPEED

    ' Check collision with player FIRST (before off-screen check)
    ' Wide hitbox: Y range 70-100, X range PlayerX-8 to PlayerX+16
    IF ABulletY >= 70 THEN
        IF ABulletY <= 100 THEN
            IF ABulletX >= PlayerX - 8 THEN
                IF ABulletX <= PlayerX + 16 THEN
                    ' HIT! Player is hit
                    PlayerHit = 1
                    ABulletActive = 0
                    SOUND 0, 100, 15
                    HitTimer = 20
                    RETURN
                END IF
            END IF
        END IF
    END IF

    ' Check if off screen (after collision check)
    IF ABulletY > 100 THEN
        ABulletActive = 0
    END IF

    RETURN
END

' --------------------------------------------
' DrawAlienBullet - Update alien bullet sprite
' --------------------------------------------
DrawAlienBullet: PROCEDURE
    IF ABulletActive THEN
        SPRITE SPR_ABULLET, ABulletX + $0200, ABulletY, GRAM_BULLET * 8 + COL_YELLOW + $0800
    ELSE
        ' Hide alien bullet sprite
        SPRITE SPR_ABULLET, 0, 0, 0
    END IF
    RETURN
END

' --------------------------------------------
' DrawAliens - Draw all aliens to background
' --------------------------------------------
DrawAliens: PROCEDURE
    ' Clear the row ABOVE first (where aliens came from when dropping)
    IF AlienOffsetY > 0 THEN
        #ScreenPos = (ALIEN_START_Y + AlienOffsetY - 1) * 20
        FOR Col = 0 TO 19
            PRINT AT #ScreenPos + Col, 0
        NEXT Col
    END IF

    ' Draw aliens and clear trail in ONE pass (no flicker)
    FOR Row = 0 TO ALIEN_ROWS - 1
        #ScreenPos = (ALIEN_START_Y + AlienOffsetY + Row) * 20

        ' Determine which alien type for this row
        ' Use DIFFERENT COLORS per type to diagnose issues
        IF Row = 0 THEN
            AlienCard = GRAM_ALIEN1 + AnimFrame
            AlienColor = 7  ' White for squid (row 0)
        ELSEIF Row < 3 THEN
            AlienCard = GRAM_ALIEN2 + AnimFrame
            AlienColor = 2  ' Red for crab (rows 1-2)
        ELSE
            AlienCard = GRAM_ALIEN3 + AnimFrame
            AlienColor = 5  ' Green for octopus (rows 3-4)
        END IF

        ' Color Stack mode - SAME format as sprites!
        ' card * 8 + color + $0800 (GRAM flag)
        #Card = AlienCard * 8 + AlienColor + $0800

        ' Draw aliens using PRINT AT (standard IntyBASIC)
        #Mask = 1
        FOR Col = 0 TO ALIEN_COLS - 1
            IF #AlienRow(Row) AND #Mask THEN
                PRINT AT #ScreenPos + ALIEN_START_X + AlienOffsetX + Col, #Card
            ELSE
                PRINT AT #ScreenPos + ALIEN_START_X + AlienOffsetX + Col, 0
            END IF
            #Mask = #Mask * 2
        NEXT Col

        ' Clear trail on BOTH edges to handle direction reversals cleanly
        ' Left edge: clear if we're not at leftmost position
        IF AlienOffsetX > 0 THEN
            PRINT AT #ScreenPos + ALIEN_START_X + AlienOffsetX - 1, 0
        END IF
        ' Right edge: clear if we're not at rightmost position
        IF AlienOffsetX < ALIEN_MAX_X THEN
            PRINT AT #ScreenPos + ALIEN_START_X + AlienOffsetX + ALIEN_COLS, 0
        END IF
    NEXT Row
    RETURN
END

' --------------------------------------------
' CheckWaveWin - Check if all aliens are dead
' --------------------------------------------
CheckWaveWin: PROCEDURE
    ' Count remaining aliens
    #AliensAlive = 0
    FOR LoopVar = 0 TO ALIEN_ROWS - 1
        #AliensAlive = #AliensAlive + #AlienRow(LoopVar)
    NEXT LoopVar

    ' If no aliens left, start new wave
    IF #AliensAlive = 0 THEN
        GOSUB StartNewWave
    END IF
    RETURN
END

' --------------------------------------------
' StartNewWave - Reset aliens for next wave
' --------------------------------------------
StartNewWave: PROCEDURE
    ' Increment level
    Level = Level + 1

    ' Speed up aliens (reduce march delay)
    IF CurrentMarchSpeed > MARCH_SPEED_MIN + 20 THEN
        CurrentMarchSpeed = CurrentMarchSpeed - 20
    ELSE
        CurrentMarchSpeed = MARCH_SPEED_MIN
    END IF

    ' Reset alien positions
    AlienOffsetX = 0
    AlienOffsetY = 0
    AlienDir = 1
    MarchCount = 0

    ' Reset all aliens to alive
    FOR LoopVar = 0 TO ALIEN_ROWS - 1
        #AlienRow(LoopVar) = $7FF
    NEXT LoopVar

    ' Clear any active bullets
    BulletActive = 0
    ABulletActive = 0
    SPRITE SPR_PBULLET, 0, 0, 0
    SPRITE SPR_ABULLET, 0, 0, 0

    ' Clear screen and redraw
    CLS
    GOSUB DrawAliens

    ' Redraw HUD
    PRINT AT 220, "SCORE:"
    PRINT AT 227, <>#Score
    PRINT AT 236, (GRAM_SHIP * 8) + (COL_GREEN * $200) + $0800
    IF Lives = 4 THEN
        PRINT AT 237, "x4"
    END IF
    IF Lives = 3 THEN
        PRINT AT 237, "x3"
    END IF
    IF Lives = 2 THEN
        PRINT AT 237, "x2"
    END IF
    IF Lives = 1 THEN
        PRINT AT 237, "x1"
    END IF

    ' Brief pause to show new wave
    PRINT AT 90, "WAVE"
    PRINT AT 95, <> Level
    FOR LoopVar = 0 TO 60
        WAIT
    NEXT LoopVar

    ' Clear wave message
    PRINT AT 90, "    "
    PRINT AT 95, "  "

    RETURN
END

' --------------------------------------------
' Graphics Data
' --------------------------------------------
ShipGfx:
    ' Player ship body - Frame 0
    BITMAP "...XX..."
    BITMAP "..XXXX.."
    BITMAP ".XXXXXX."
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP ".XXXXXX."
    BITMAP "..X..X.."
    BITMAP ".X....X."

    ' Frame 1 (subtle wing/engine flicker)
    BITMAP "...XX..."
    BITMAP "..XXXX.."
    BITMAP ".XXXXXX."
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "..X..X.."
    BITMAP "X......X"

' Ship accent overlay (stacked MOB for 2-color effect)
ShipAccentGfx:
    ' Frame 0 (cockpit + small engine dots)
    BITMAP "........"
    BITMAP "...XX..."
    BITMAP "...XX..."
    BITMAP "........"
    BITMAP "........"
    BITMAP "..X..X.."
    BITMAP "........"
    BITMAP "........"

    ' Frame 1 (engine flicker)
    BITMAP "........"
    BITMAP "...XX..."
    BITMAP "...XX..."
    BITMAP "........"
    BITMAP "........"
    BITMAP ".X....X."
    BITMAP "........"
    BITMAP "........"

' Alien Type 1 - Top row (small squid) - 1px gap right & bottom
Alien1Gfx:
    ' Frame 0 - arms IN tight (default pose)
    BITMAP "..XX...."
    BITMAP ".XXXX..."
    BITMAP "XXXXXX.."
    BITMAP ".X..X..."
    BITMAP ".XXXX..."
    BITMAP ".X..X..."
    BITMAP "..XX...."
    BITMAP "........"
    ' Frame 1 - arms OUT wide (animated pose)
    BITMAP "..XX...."
    BITMAP ".XXXX..."
    BITMAP "XX..XX.."
    BITMAP ".XXXX..."
    BITMAP "X.XX.X.."
    BITMAP "X....X.."
    BITMAP ".X..X..."
    BITMAP "........"

' Alien Type 2 - Middle rows (crab with claws) - 1px gap right & bottom
Alien2Gfx:
    ' Frame 0 - claws DOWN and IN (default pose)
    BITMAP ".X..X..."
    BITMAP "XXXXXX.."
    BITMAP "XX..XX.."
    BITMAP "XXXXXX.."
    BITMAP ".XXXX..."
    BITMAP ".XXXX..."
    BITMAP ".X..X..."
    BITMAP "........"
    ' Frame 1 - claws UP and OUT (animated pose)
    BITMAP "X....X.."
    BITMAP "X.XX.X.."
    BITMAP "XXXXXX.."
    BITMAP "XX..XX.."
    BITMAP "XXXXXX.."
    BITMAP ".XXXX..."
    BITMAP "X....X.."
    BITMAP "........"

' Alien Type 3 - Bottom rows (wide octopus) - 1px gap right & bottom
Alien3Gfx:
    ' Frame 0 - legs IN narrow (default pose)
    BITMAP "..XX...."
    BITMAP ".XXXX..."
    BITMAP "XX..XX.."
    BITMAP "XXXXXX.."
    BITMAP "X.XX.X.."
    BITMAP ".X..X..."
    BITMAP "..XX...."
    BITMAP "........"
    ' Frame 1 - legs OUT wide (animated pose)
    BITMAP "..XX...."
    BITMAP ".XXXX..."
    BITMAP "XX..XX.."
    BITMAP "XXXXXX.."
    BITMAP "X.XX.X.."
    BITMAP "X....X.."
    BITMAP "X....X.."
    BITMAP "........"

' Bullet graphic
BulletGfx:
    BITMAP "...XX..."
    BITMAP "...XX..."
    BITMAP "...XX..."
    BITMAP "...XX..."
    BITMAP "...XX..."
    BITMAP "...XX..."
    BITMAP "...XX..."
    BITMAP "...XX..."

' ============================================
' Color Banding Test Graphics - Title Screen Only
' 2 cards: top half (4 rows) and bottom half (4 rows)
' Non-overlapping sprites for clean color wave
' ============================================
Band1Gfx:
    ' TOP HALF of alien (rows 1-4)
    BITMAP "X....X.."
    BITMAP "X.XX.X.."
    BITMAP "XXXXXX.."
    BITMAP "XX..XX.."
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"

Band2Gfx:
    ' BOTTOM HALF of alien (rows 5-8)
    BITMAP "XXXXXX.."
    BITMAP ".XXXX..."
    BITMAP "X....X.."
    BITMAP ".X..X..."
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"

Band3Gfx:
    ' (unused for now)
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"

Band4Gfx:
    ' (unused for now)
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"

' Alien2 drawn with DOTS as the alien body (for F/B mode BACKTAB)
' In F/B mode: . = foreground color, X = background/black
' Dots placed exactly where original Alien2 has X pixels
InvertedAlienGfx:
    BITMAP ".XXXX.XX"
    BITMAP ".X..X.XX"
    BITMAP "......XX"
    BITMAP "..XX..XX"
    BITMAP "......XX"
    BITMAP "X....XXX"
    BITMAP ".XXXX.XX"
    BITMAP "XXXXXXXX"

' Explosion graphics - 3 frame animation
' Frame 1 - tight pop (dense core)
ExplosionGfx:
    BITMAP "...X...."
    BITMAP "..XXX..."
    BITMAP ".XX.XX.."
    BITMAP "..XXX..."
    BITMAP "...X...."
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"

' Frame 2 - expanding scatter (classic "pop")
ExplosionGfx2:
    BITMAP "..X.X..."
    BITMAP ".X...X.."
    BITMAP "X..X..X."
    BITMAP "...X...."
    BITMAP "X..X..X."
    BITMAP ".X...X.."
    BITMAP "..X.X..."
    BITMAP "........"

' Frame 3 - wide sparse particles (dissipate)
ExplosionGfx3:
    BITMAP "X......."
    BITMAP "..X..X.."
    BITMAP "....X..."
    BITMAP ".X....X."
    BITMAP "...X...."
    BITMAP "..X..X.."
    BITMAP "X......."
    BITMAP "........"