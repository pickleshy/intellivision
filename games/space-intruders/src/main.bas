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

' GRAM card assignments
CONST GRAM_SHIP     = 0         ' Player ship graphic (2 cards)
CONST GRAM_ALIEN1   = 2         ' Top row alien (2 cards for animation)
CONST GRAM_ALIEN2   = 4         ' Middle rows alien
CONST GRAM_ALIEN3   = 6         ' Bottom rows alien
CONST GRAM_BULLET   = 8         ' Bullet graphic

' Alien grid constants
CONST ALIEN_COLS    = 11        ' 11 aliens per row
CONST ALIEN_ROWS    = 5         ' 5 rows of aliens
CONST ALIEN_START_X = 1         ' Starting column on screen (leftmost)
CONST ALIEN_START_Y = 1         ' Starting row on screen
CONST ALIEN_MAX_X   = 8         ' Maximum X offset before reversing (20 - 11 - 1)
CONST MARCH_SPEED   = 160       ' Frames between march steps (slower = easier)

' Bullet constants
CONST BULLET_SPEED  = 2         ' Player bullet speed (slower)
CONST BULLET_TOP    = 8         ' Top of screen
CONST ALIEN_BULLET_SPEED = 2    ' Alien bullet speed
CONST ALIEN_SHOOT_RATE = 90     ' Frames between alien shots

' Colors
CONST COL_WHITE     = 7
CONST COL_GREEN     = 5
CONST COL_YELLOW    = 6
CONST COL_BLACK     = 0

' Sprite flags (standard IntyBASIC values)
CONST SPR_VISIBLE   = $0200     ' Make sprite visible
CONST SPR_HIT       = $0100     ' Enable collision detection
CONST GRAM_BIT      = $0800     ' GRAM flag for background cards (same as sprites)

' --------------------------------------------
' Variables
' --------------------------------------------
DIM #AlienRow(ALIEN_ROWS)       ' Bitmask of alive aliens per row (11 bits, needs 16-bit)
PlayerX     = 80                ' Player X position (center)
AnimFrame   = 0                 ' Animation frame (0 or 1)
FrameCount  = 0                 ' Frame counter for animation timing
AlienOffsetX = 0                ' Alien grid X offset (0 to ALIEN_MAX_X)
AlienOffsetY = 0                ' Alien grid Y offset (drops down)
AlienDir    = 1                 ' Movement direction (1=right, 255=left using unsigned)
MarchCount  = 0                 ' Frame counter for march timing
BulletX     = 0                 ' Bullet X position
BulletY     = 0                 ' Bullet Y position
BulletActive = 0                ' 1 = bullet flying, 0 = ready to fire
ABulletX    = 0                 ' Alien bullet X position
ABulletY    = 0                 ' Alien bullet Y position
ABulletActive = 0               ' 1 = alien bullet flying
ShootTimer  = 0                 ' Countdown to next alien shot
ShootCol    = 0                 ' Column to shoot from
#Score      = 0                 ' Player score
PlayerHit   = 0                 ' 1 = player was hit
HitTimer    = 0                 ' Countdown for hit effect
HitCol      = 0                 ' Collision check - column
HitRow      = 0                 ' Collision check - row
AlienGridRow = 0                ' Which row in alien grid
AlienGridCol = 0                ' Which column in alien grid
LoopVar     = 0                 ' General loop variable
Row         = 0                 ' Row counter for drawing
Col         = 0                 ' Column counter for drawing
AlienCard   = 0                 ' Current alien GRAM card
AlienColor  = 0                 ' Current alien color
#ScreenPos  = 0                 ' Screen position (16-bit for multiplication)
#Mask       = 0                 ' Bitmask for checking alive aliens
#Card       = 0                 ' Card value for PRINT

' --------------------------------------------
' Main Program
' --------------------------------------------
    WAIT

    ' Set up graphics mode (Foreground/Background - allows GRAM on background)
    MODE 1

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

    ' Initialize all aliens as alive (11 bits = $7FF)
    FOR LoopVar = 0 TO ALIEN_ROWS - 1
        #AlienRow(LoopVar) = $7FF
    NEXT LoopVar

    ' Draw the alien grid
    GOSUB DrawAliens

    ' Draw score area at bottom
    PRINT AT 220, "SCORE: 0"

    ' Initialize player sprite
    GOSUB DrawPlayer

' --------------------------------------------
' Main Game Loop
' --------------------------------------------
GameLoop:
    WAIT

    ' Handle player movement and firing
    GOSUB MovePlayer

    ' Update alien march FIRST (so collision check uses correct positions)
    MarchCount = MarchCount + 1
    IF MarchCount >= MARCH_SPEED THEN
        MarchCount = 0
        GOSUB MarchAliens
        AnimFrame = AnimFrame XOR 1
        GOSUB DrawAliens
    END IF

    ' Update bullet AFTER march (collision uses same offsets as drawing)
    IF BulletActive THEN
        GOSUB MoveBullet
    END IF

    ' Alien shooting logic
    GOSUB AlienShoot

    ' Update alien bullet
    IF ABulletActive THEN
        GOSUB MoveAlienBullet
    END IF

    ' Handle hit effect timer (turns off explosion sound)
    IF HitTimer > 0 THEN
        HitTimer = HitTimer - 1
        IF HitTimer = 0 THEN
            SOUND 0, , 0  ' Turn off explosion sound
        END IF
    END IF

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

                ' Clear the alien from screen
                PRINT AT HitRow * 20 + HitCol, 0
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
    SPRITE SPR_PLAYER, PlayerX + $0200, PLAYER_Y, GRAM_SHIP * 8 + COL_GREEN + $0800
    RETURN
END

' --------------------------------------------
' DrawBullet - Update bullet sprite
' --------------------------------------------
DrawBullet: PROCEDURE
    IF BulletActive THEN
        SPRITE SPR_PBULLET, BulletX + $0200, BulletY, GRAM_BULLET * 8 + COL_WHITE + $0800
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

    ' Check if off screen
    IF ABulletY > 96 THEN
        ABulletActive = 0
        RETURN
    END IF

    ' Check collision with player
    IF ABulletY >= PLAYER_Y - 4 THEN
        IF ABulletY <= PLAYER_Y + 8 THEN
            IF ABulletX >= PlayerX THEN
                IF ABulletX <= PlayerX + 8 THEN
                    ' HIT! Player is hit
                    PlayerHit = 1
                    ABulletActive = 0
                    ' Play explosion sound and set timer
                    SOUND 0, 100, 15
                    HitTimer = 20  ' Sound plays for ~1/3 second
                END IF
            END IF
        END IF
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
    ' For each row, clear the ENTIRE possible width before drawing
    ' Start at column 0 to catch any edge artifacts
    FOR Row = 0 TO ALIEN_ROWS - 1
        ' Calculate BASE screen position for this row (start at column 0)
        #ScreenPos = (ALIEN_START_Y + AlienOffsetY + Row) * 20

        ' Clear from column 0 through the rightmost possible alien position
        ' With spacing: rightmost = ALIEN_START_X + ALIEN_MAX_X + (ALIEN_COLS-1)*SPACING
        FOR Col = 0 TO 19
            PRINT AT #ScreenPos + Col, 0
        NEXT Col
    NEXT Row

    ' Also clear the row ABOVE if we've dropped
    IF AlienOffsetY > 0 THEN
        #ScreenPos = (ALIEN_START_Y + AlienOffsetY - 1) * 20
        FOR Col = 0 TO 19
            PRINT AT #ScreenPos + Col, 0
        NEXT Col
    END IF

    ' Now draw the aliens at their current position
    FOR Row = 0 TO ALIEN_ROWS - 1
        ' Calculate BASE screen position for this row
        #ScreenPos = (ALIEN_START_Y + AlienOffsetY + Row) * 20 + ALIEN_START_X + AlienOffsetX

        ' Determine which alien type and color for this row
        IF Row = 0 THEN
            AlienCard = GRAM_ALIEN1 + AnimFrame
            AlienColor = COL_WHITE
        ELSEIF Row < 3 THEN
            AlienCard = GRAM_ALIEN2 + AnimFrame
            AlienColor = COL_YELLOW
        ELSE
            AlienCard = GRAM_ALIEN3 + AnimFrame
            AlienColor = COL_GREEN
        END IF

        ' Build card value for FG/BG mode: GRAM_BIT + card + (fgcolor * 8)
        #Card = GRAM_BIT + AlienCard + (AlienColor * 8)

        ' Draw each alien in the row
        #Mask = 1
        FOR Col = 0 TO ALIEN_COLS - 1
            IF #AlienRow(Row) AND #Mask THEN
                ' Alien is alive - draw it
                PRINT AT #ScreenPos + Col, #Card
            END IF
            #Mask = #Mask * 2
        NEXT Col
    NEXT Row
    RETURN
END

' --------------------------------------------
' Graphics Data
' --------------------------------------------
ShipGfx:
    ' Player ship - 8x8 cannon shape
    BITMAP "...XX..."
    BITMAP "...XX..."
    BITMAP "..XXXX.."
    BITMAP "..XXXX.."
    BITMAP ".XXXXXX."
    BITMAP ".XXXXXX."
    BITMAP "XXXXXXXX"
    BITMAP "X.XXXX.X"

    ' Second frame (same for now, can animate later)
    BITMAP "...XX..."
    BITMAP "...XX..."
    BITMAP "..XXXX.."
    BITMAP "..XXXX.."
    BITMAP ".XXXXXX."
    BITMAP ".XXXXXX."
    BITMAP "XXXXXXXX"
    BITMAP "X.XXXX.X"

' Alien Type 1 - Top row (small squid) - 1px gap right & bottom
Alien1Gfx:
    ' Frame 1 - tentacles OUT
    BITMAP "..XX...."
    BITMAP ".XXXX..."
    BITMAP "XX..XX.."
    BITMAP ".XXXX..."
    BITMAP "..XX...."
    BITMAP ".X..X..."
    BITMAP "X....X.."
    BITMAP "........"
    ' Frame 2 - tentacles IN
    BITMAP "..XX...."
    BITMAP ".XXXX..."
    BITMAP "XX..XX.."
    BITMAP ".XXXX..."
    BITMAP "..XX...."
    BITMAP "X....X.."
    BITMAP ".X..X..."
    BITMAP "........"

' Alien Type 2 - Middle rows (crab with claws) - 1px gap right & bottom
Alien2Gfx:
    ' Frame 1 - claws UP
    BITMAP "X....X.."
    BITMAP ".XXXX..."
    BITMAP "XXXXXX.."
    BITMAP "X.XX.X.."
    BITMAP "XXXXXX.."
    BITMAP "..XX...."
    BITMAP ".X..X..."
    BITMAP "........"
    ' Frame 2 - claws DOWN
    BITMAP "..XX...."
    BITMAP ".XXXX..."
    BITMAP "XXXXXX.."
    BITMAP "X.XX.X.."
    BITMAP "XXXXXX.."
    BITMAP "X....X.."
    BITMAP ".X..X..."
    BITMAP "........"

' Alien Type 3 - Bottom rows (wide octopus) - 1px gap right & bottom
Alien3Gfx:
    ' Frame 1 - arms OUT
    BITMAP ".XXXX..."
    BITMAP "XXXXXX.."
    BITMAP "X.XX.X.."
    BITMAP "XXXXXX.."
    BITMAP "X.XX.X.."
    BITMAP "X....X.."
    BITMAP ".X..X..."
    BITMAP "........"
    ' Frame 2 - arms IN
    BITMAP ".XXXX..."
    BITMAP "XXXXXX.."
    BITMAP "X.XX.X.."
    BITMAP "XXXXXX.."
    BITMAP "X.XX.X.."
    BITMAP ".X..X..."
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
