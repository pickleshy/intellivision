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
CONST SPR_SAUCER2   = 3         ' Saucer right half (mirrored)

' GRAM card assignments
CONST GRAM_SHIP     = 0         ' Player ship graphic (2 cards)
CONST GRAM_ALIEN1   = 2         ' Top row alien (2 cards for animation)
CONST GRAM_ALIEN2   = 4         ' Middle rows alien
CONST GRAM_ALIEN3   = 6         ' Bottom rows alien
CONST GRAM_BULLET   = 8         ' Bullet graphic
' Title screen big alien - 2 side-by-side 8x8 sprites (16x8)
CONST GRAM_BAND1    = 9         ' Alien left half
CONST GRAM_BAND2    = 10        ' Alien right half
CONST GRAM_BAND1_F1 = 11        ' Alien left half - Frame 2
CONST GRAM_BAND2_F1 = 12        ' Alien right half - Frame 2
CONST GRAM_INV_TEST = 13        ' Inverted alien for testing
CONST GRAM_EXPLOSION = 14       ' Explosion frame 1 (tight pop)
CONST GRAM_EXPLOSION2 = 15      ' Explosion frame 2 (expanding scatter)
CONST GRAM_EXPLOSION3 = 16      ' Explosion frame 3 (dissipate)
CONST GRAM_SHIP_ACCENT = 17     ' Ship accent overlay (2 cards for animation)
CONST GRAM_CRAB_F1  = 19        ' Small crab frame 1 (title screen flyer)
CONST GRAM_CRAB_F2  = 20        ' Small crab frame 2
CONST GRAM_SPARK_UP = 21        ' Bolt spark above letter frame 1
CONST GRAM_SPARK_DN = 22        ' Bolt spark below letter frame 1
CONST GRAM_SPARK_UP2 = 23       ' Bolt spark above letter frame 2 (trailing)
CONST GRAM_SPARK_DN2 = 24       ' Bolt spark below letter frame 2 (trailing)

' Custom title font
CONST GRAM_FONT_S = 25
CONST GRAM_FONT_P = 26
CONST GRAM_FONT_A = 27
CONST GRAM_FONT_C = 28
CONST GRAM_FONT_E = 29
CONST GRAM_FONT_I = 30
CONST GRAM_FONT_N = 31
CONST GRAM_FONT_T = 32
CONST GRAM_FONT_R = 33
CONST GRAM_FONT_U = 34
CONST GRAM_FONT_D = 35
CONST GRAM_FONT_F = 36
CONST GRAM_STAR1  = 37        ' Star dot (upper-left pixel)
CONST GRAM_STAR2  = 38        ' Star dot (lower-right pixel)
CONST GRAM_SAUCER = 39         ' Flying saucer (bonus target)
CONST GRAM_BEAM   = 40         ' Wide beam shot (full 8px width)
CONST GRAM_POWERUP = 41        ' Power-up capsule graphic

' Additional sprite slots
CONST SPR_SHIP_ACCENT = 4       ' Ship accent sprite (stacked for 2-color effect)
CONST SPR_FLYER     = 5         ' Title screen flying alien
CONST SPR_SAUCER    = 6         ' Gameplay flying saucer
CONST SPR_POWERUP   = 7         ' Power-up drop/pickup sprite

' Alien grid constants
CONST ALIEN_COLS    = 9         ' 9 aliens per row
CONST ALIEN_ROWS    = 5         ' 5 rows of aliens
CONST ALIEN_START_X = 1         ' Starting column on screen (leftmost)
CONST ALIEN_START_Y = 1         ' Starting row on screen
CONST ALIEN_MAX_X   = 10        ' Maximum X offset before reversing (20 - 9 - 1)
' CONST MARCH_SPEED_START = 160   ' Starting frames between march steps
CONST MARCH_SPEED_START = 60   ' Starting frames between march steps
CONST MARCH_SPEED_MIN = 20      ' Fastest march speed (minimum frames)

' Bullet constants
CONST BULLET_SPEED  = 1         ' Player bullet speed (slower)
CONST BULLET_TOP    = 8         ' Top of screen
CONST ALIEN_BULLET_SPEED = 2    ' Alien bullet speed
CONST ALIEN_SHOOT_RATE = 90     ' Frames between alien shots
CONST RAPID_SPEED    = 3        ' Rapid fire bullet speed (3px/frame)
CONST RAPID_COOLDOWN = 8        ' Frames between rapid fire shots

' Colors
CONST COL_WHITE     = 7
CONST COL_BLUE      = 1
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
' FlyPathX/Y moved to ROM DATA tables (see Segment 1) to save 128 8-bit vars
DIM FlyColors(6)               ' Color cycle (6 entries, indices 0-5)
DIM WaveColors(4)               ' 4-color cycle for title screen wave effect
PlayerX     = 80                ' Player X position (center)
AnimFrame   = 0                 ' Animation frame (0 or 1)
' (FrameCount, ColorPhase removed - unused)
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
' (ColorIndex removed - unused)
#ScreenPos  = 0                 ' Screen position (16-bit for multiplication)
#Mask       = 0                 ' Bitmask for checking alive aliens
#Card       = 0                 ' Card value for PRINT
' (GameState removed - unused)
TitleColor  = 0                 ' Color index for title sprite shimmer
TitleFrame  = 0                 ' Animation frame for title alien
ShakeTimer  = 0                 ' Screen shake countdown (0 = no shake)
TitleMarchX = 0                 ' Title screen alien X offset
TitleMarchDir = 1               ' Title march direction (1=right, 0=left)
TitleMarchCount = 0             ' Title march timing counter
TitleJitter = 0                 ' Title screen jitter phase (0-7)
WavePhase   = 0                 ' Color wave phase for big alien (0-3)
ExplosionTimer = 0              ' Explosion display countdown (0 = no explosion)
#ExplosionPos  = 0              ' Explosion BACKTAB position (screen address)
FlyX        = 0                 ' Flying sprite X position (from path table)
FlyY        = 0                 ' Flying sprite Y position (from path table)
FlyPhase    = 0                 ' Path position index (0-31)
FlySpeed    = 0                 ' Frame counter for path advance
FlyFrame    = 0                 ' Flying sprite animation frame
FlyColorIdx = 0                 ' Color cycle index (0-5)
FlyColorTimer = 0               ' Frame counter for color change
FlyColor    = 7                 ' Current sprite color
FlyState    = 0                 ' 0=enter, 1=looping, 2=exit, 3=offscreen pause
FlyLoopCount = 0                ' Number of completed figure-8 loops
SlidePos    = 0                 ' PRESS/FIRE slide-in position (0-5 sliding, 6+ = done)
' Starfield variables
DIM #StarPos(16)                ' Star BACKTAB positions (16 stars, 16-bit for safe math)
DIM StarType(16)                ' Star type: 0=slow/dim, 1=fast/bright
StarCount   = 0                 ' Number of active stars
StarTimer   = 0                 ' Frame counter for scroll updates
StarTick    = 0                 ' Tick counter (for slow layer)
#BeamTimer  = 0                 ' Wide beam countdown (300 frames = 5 sec, 0 = normal)
' Power-up drop variables (reuse title-screen vars during gameplay)
' TitleFrame reuses TitleFrame (title-only)
' TitleMarchDir reuses TitleMarchDir (title-only)
' SlidePos reuses SlidePos (title-only)
#PowerTimer = 0                 ' Landing timeout (counts down from 300)
' Rapid fire variables (reuse title-screen vars during gameplay)
' PowerUpType reuses TitleColor (title-only): 0=beam, 1=rapid fire
' FireCooldown reuses TitleJitter (title-only): frames until next shot allowed
#RapidTimer = 0                 ' Rapid fire countdown (300 frames = 5 sec, 0 = normal)
#PathXAddr  = 0                 ' ROM address of FlyPathXData (set at title init)
#PathYAddr  = 0                 ' ROM address of FlyPathYData (set at title init)

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
    ' Title screen big alien (2 side-by-side 8x8 sprites)
    DEFINE GRAM_BAND1, 1, Band1Gfx
    WAIT
    DEFINE GRAM_BAND2, 1, Band2Gfx
    WAIT
    DEFINE GRAM_BAND1_F1, 1, Band1F1Gfx
    WAIT
    DEFINE GRAM_BAND2_F1, 1, Band2F1Gfx
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
    DEFINE GRAM_CRAB_F1, 1, SmallCrabF1Gfx
    WAIT
    DEFINE GRAM_CRAB_F2, 1, SmallCrabF2Gfx
    WAIT
    DEFINE GRAM_SPARK_UP, 1, SparkUpGfx
    WAIT
    DEFINE GRAM_SPARK_DN, 1, SparkDnGfx
    WAIT
    DEFINE GRAM_SPARK_UP2, 1, SparkUpGfx2
    WAIT
    DEFINE GRAM_SPARK_DN2, 1, SparkDnGfx2
    WAIT
    ' Custom title font (11 letters)
    DEFINE GRAM_FONT_S, 1, FontSGfx
    WAIT
    DEFINE GRAM_FONT_P, 1, FontPGfx
    WAIT
    DEFINE GRAM_FONT_A, 1, FontAGfx
    WAIT
    DEFINE GRAM_FONT_C, 1, FontCGfx
    WAIT
    DEFINE GRAM_FONT_E, 1, FontEGfx
    WAIT
    DEFINE GRAM_FONT_I, 1, FontIGfx
    WAIT
    DEFINE GRAM_FONT_N, 1, FontNGfx
    WAIT
    DEFINE GRAM_FONT_T, 1, FontTGfx
    WAIT
    DEFINE GRAM_FONT_R, 1, FontRGfx
    WAIT
    DEFINE GRAM_FONT_U, 1, FontUGfx
    WAIT
    DEFINE GRAM_FONT_D, 1, FontDGfx
    WAIT
    DEFINE GRAM_FONT_F, 1, FontFGfx
    WAIT
    DEFINE GRAM_STAR1, 1, Star1Gfx
    WAIT
    DEFINE GRAM_STAR2, 1, Star2Gfx
    WAIT
    DEFINE GRAM_SAUCER, 1, SaucerGfx
    WAIT
    DEFINE GRAM_BEAM, 1, BeamGfx
    WAIT
    DEFINE GRAM_POWERUP, 1, PowerUpGfx
    WAIT

    ' Initialize row colors (0-7 only for MODE 1)
    ' Blue, Red, Tan, Green, Yellow - rainbow wave
    RowColors(0) = 1   ' Blue
    RowColors(1) = 2   ' Red
    RowColors(2) = 3   ' Tan
    RowColors(3) = 5   ' Green
    RowColors(4) = 6   ' Yellow

    ' Initialize wave colors for PRESS FIRE shimmer (GRAM font, supports colors 8+)
    ' Grey/White flash
    WaveColors(0) = COL_WHITE
    WaveColors(1) = COL_WHITE
    WaveColors(2) = 0              ' Grey (color 8 encoded as $1800 base)
    WaveColors(3) = 0              ' Grey

' ============================================
' TITLE SCREEN
' ============================================
TitleScreen:
    CLS
    TitleFrame = 0
    TitleMarchDir = 1      ' 1=right, 0=left
    TitleMarchCount = 0    ' Frame counter for march steps
    TitleGridCol = 4       ' BACKTAB column of grid left edge

    ' Display title text - row 1
    ' Title text using custom GRAM font (green = color 5)
    PRINT AT 22, GRAM_FONT_S * 8 + COL_TAN + $0800  ' S
    PRINT AT 23, GRAM_FONT_P * 8 + COL_TAN + $0800  ' P
    PRINT AT 24, GRAM_FONT_A * 8 + COL_TAN + $0800  ' A
    PRINT AT 25, GRAM_FONT_C * 8 + COL_TAN + $0800  ' C
    PRINT AT 26, GRAM_FONT_E * 8 + COL_TAN + $0800  ' E
    '   position 27 = space (leave black)
    PRINT AT 28, GRAM_FONT_I * 8 + COL_TAN + $0800  ' I
    PRINT AT 29, GRAM_FONT_N * 8 + COL_TAN + $0800  ' N
    PRINT AT 30, GRAM_FONT_T * 8 + COL_TAN + $0800  ' T
    PRINT AT 31, GRAM_FONT_R * 8 + COL_TAN + $0800  ' R
    PRINT AT 32, GRAM_FONT_U * 8 + COL_TAN + $0800  ' U
    PRINT AT 33, GRAM_FONT_D * 8 + COL_TAN + $0800  ' D
    PRINT AT 34, GRAM_FONT_E * 8 + COL_TAN + $0800  ' E
    PRINT AT 35, GRAM_FONT_R * 8 + COL_TAN + $0800  ' R
    PRINT AT 36, GRAM_FONT_S * 8 + COL_TAN + $0800  ' S

    ' Generate scrolling starfield on safe rows (3, 4, 8, 9, 11)
    StarTimer = 0
    StarTick = 0
    GOSUB GenerateStars

    ' "PRESS FIRE" slides in from edges — don't print here
    WavePhase = 0          ' Color cycle index for PRESS FIRE
    TitleColor = 0         ' Frame counter for color change / slide timer
    SlidePos = 0           ' Slide-in position (0=edges, 5=final, 6+=done)
    TitleJitter = 0        ' Bolt position (0-14 = char, 15-19 = gap between sweeps)
    TitleMarchX = 0        ' Bolt frame counter

    ' Draw 3x3 alien grid on BACKTAB (rows 5-7, starting at TitleGridCol)
    GOSUB DrawAlienGrid

    ' Flying crab path stored in ROM DATA tables
    ' Load ROM addresses into 16-bit vars for PEEK access
    ' VARPTR works with DATA labels in IntyBASIC
    #PathXAddr = VARPTR FlyPathXData(0)
    #PathYAddr = VARPTR FlyPathYData(0)
    ' Color cycle: White → Yellow → Green → Blue → Green → Yellow
    FlyColors(0) = 7 : FlyColors(1) = 6 : FlyColors(2) = 5
    FlyColors(3) = 3 : FlyColors(4) = 5 : FlyColors(5) = 6
    FlyPhase = 0
    FlySpeed = 0
    FlyFrame = 0
    FlyColorIdx = 0
    FlyColorTimer = 0
    FlyColor = 7
    FlyState = 0           ' Start with entry from left
    FlyLoopCount = 0
    FlyX = 0               ' Start off-screen top-left
    FlyY = 0               ' Start at top of screen

    ' Start title music
    PLAY FULL
    PLAY VOLUME 12
    PLAY space_intruders_theme

' --------------------------------------------
' Title Loop - card-step march (no SCROLL)
' --------------------------------------------
TitleLoop:
    WAIT

    ' Hide unused sprites
    SPRITE 0, 0, 0, 0
    SPRITE 1, 0, 0, 0
    SPRITE 2, 0, 0, 0
    SPRITE 3, 0, 0, 0
    SPRITE 4, 0, 0, 0
    SPRITE 6, 0, 0, 0
    SPRITE 7, 0, 0, 0

    ' --- Flying crab "Zod" state machine ---
    ' States: 0=enter from left, 1=figure-8 loops, 2=exit right, 3=offscreen pause
    FlySpeed = FlySpeed + 1
    IF FlySpeed >= 3 THEN
        FlySpeed = 0

        IF FlyState = 0 THEN
            ' Enter from top-left: diagonal path to center (84, 56)
            FlyX = FlyX + 4
            FlyY = FlyY + 3
            IF FlyX >= 84 THEN
                FlyX = 84
                FlyY = 56         ' Snap to figure-8 start
                FlyState = 1       ' Start figure-8
                FlyPhase = 0
                FlyLoopCount = 0
            END IF

        ELSEIF FlyState = 1 THEN
            ' Figure-8 looping
            FlyPhase = FlyPhase + 1
            IF FlyPhase >= 64 THEN
                FlyPhase = 0
                FlyLoopCount = FlyLoopCount + 1
                IF FlyLoopCount >= 2 THEN
                    FlyState = 2   ' Done looping, exit right
                    FlyX = 84
                    FlyY = 56
                END IF
            END IF
            IF FlyState = 1 THEN
                FlyX = PEEK(#PathXAddr + FlyPhase)
                FlyY = PEEK(#PathYAddr + FlyPhase)
            END IF

        ELSEIF FlyState = 2 THEN
            ' Exit to right with wobble: X increases by 4, Y oscillates
            FlyX = FlyX + 4
            FlyPhase = FlyPhase + 1
            ' Wobble: 4-step cycle → up, center, down, center (±3px)
            IF (FlyPhase AND 3) = 0 THEN
                FlyY = 53
            ELSEIF (FlyPhase AND 3) = 1 THEN
                FlyY = 56
            ELSEIF (FlyPhase AND 3) = 2 THEN
                FlyY = 59
            ELSE
                FlyY = 56
            END IF
            IF FlyX > 167 THEN
                FlyState = 3       ' Offscreen pause
                FlyPhase = 0       ' Reuse as pause counter
            END IF

        ELSE
            ' Offscreen pause (~1 sec = 20 steps × 3 frames)
            FlyPhase = FlyPhase + 1
            IF FlyPhase >= 20 THEN
                FlyState = 0       ' Restart: enter from top-left
                FlyX = 0
                FlyY = 0
            END IF
        END IF
    END IF

    ' Gradual color shift every 32 frames
    FlyColorTimer = FlyColorTimer + 1
    IF FlyColorTimer >= 32 THEN
        FlyColorTimer = 0
        FlyColorIdx = FlyColorIdx + 1
        IF FlyColorIdx >= 6 THEN FlyColorIdx = 0
        FlyColor = FlyColors(FlyColorIdx)
    END IF

    ' Draw flying crab (animate + show/hide based on state)
    FlyFrame = FlyFrame + 1
    IF FlyFrame >= 16 THEN FlyFrame = 0
    IF FlyState = 3 THEN
        ' Hidden during offscreen pause
        SPRITE SPR_FLYER, 0, 0, 0
    ELSE
        IF FlyFrame < 8 THEN
            SPRITE SPR_FLYER, FlyX + SPR_VISIBLE, FlyY, GRAM_CRAB_F1 * 8 + FlyColor + $0800
        ELSE
            SPRITE SPR_FLYER, FlyX + SPR_VISIBLE, FlyY, GRAM_CRAB_F2 * 8 + FlyColor + $0800
        END IF
    END IF

    ' March animation - move grid 1 card every 32 frames
    TitleMarchCount = TitleMarchCount + 1
    IF TitleMarchCount >= 32 THEN
        TitleMarchCount = 0

        IF TitleMarchDir = 1 THEN
            TitleGridCol = TitleGridCol + 1
            IF TitleGridCol >= 10 THEN
                TitleMarchDir = 0  ' Reverse to left
            END IF
        ELSE
            TitleGridCol = TitleGridCol - 1
            IF TitleGridCol <= 1 THEN
                TitleMarchDir = 1  ' Reverse to right
            END IF
        END IF

        GOSUB DrawAlienGrid
    END IF

    ' Title text white bolt sweep - advance every 6 frames
    ' Color Stack BACKTAB: FG color in bits 0-2 (and bit 12 for pastel colors 8+)
    ' GROM card number in bits 3-10. Mask $EFF8 clears color bits 0-2 and 12.
    TitleMarchX = TitleMarchX + 1
    IF TitleMarchX >= 6 THEN
        TitleMarchX = 0
        ' Restore current bolt position to green and clear sparks (if visible)
        IF TitleJitter < 15 THEN
            #Card = PEEK($216 + TitleJitter)
            PRINT AT 22 + TitleJitter, (#Card AND $EFF8) OR $0003
            PRINT AT 2 + TitleJitter, 0    ' Clear spark above
            PRINT AT 42 + TitleJitter, 0   ' Clear spark below
        END IF
        ' Advance bolt position
        TitleJitter = TitleJitter + 1
        IF TitleJitter >= 20 THEN TitleJitter = 0
        ' Set new bolt position to white and place sparks (if visible)
        IF TitleJitter < 15 THEN
            #Card = PEEK($216 + TitleJitter)
            PRINT AT 22 + TitleJitter, (#Card AND $EFF8) OR $0007
            ' Grey sparks: color 8 on GRAM = low bits 0 + bit 12 → card*8 + $1800
            PRINT AT 2 + TitleJitter, GRAM_SPARK_UP * 8 + $1800
            PRINT AT 42 + TitleJitter, GRAM_SPARK_DN * 8 + $1800
        END IF
    END IF

    ' Spark 2-frame animation: frame 1 (0-2) → frame 2 (3-5) within each bolt step
    IF TitleJitter < 15 THEN
        IF TitleMarchX >= 3 THEN
            ' Frame 2: trailing dot position
            PRINT AT 2 + TitleJitter, GRAM_SPARK_UP2 * 8 + $1800
            PRINT AT 42 + TitleJitter, GRAM_SPARK_DN2 * 8 + $1800
        END IF
    END IF

    ' Screen shake (title screen) - same pattern as gameplay
    IF ShakeTimer > 0 THEN
        ShakeTimer = ShakeTimer - 1
        IF ShakeTimer > 0 THEN
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
    END IF

    ' "PRESS FIRE" slide-in from edges, then shimmer (GRAM font)
    ' Wait until flyer begins figure-8 before starting slide-in
    IF FlyState = 0 THEN GOTO SkipPressfire

    ' When Zod exits (state 2): rapid flash then disappear
    IF FlyState = 2 THEN
        ' Toggle visible/invisible every 2 frames for rapid blink
        TitleColor = TitleColor + 1
        IF TitleColor >= 4 THEN TitleColor = 0
        IF TitleColor < 2 THEN
            ' Visible frame (grey = dim flash)
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
        ELSE
            ' Invisible frame (clear)
            FOR LoopVar = 205 TO 214
                PRINT AT LoopVar, 0
            NEXT LoopVar
        END IF
        GOTO SkipPressfire
    END IF

    ' When Zod is offscreen (state 3): clear text and reset for next cycle
    IF FlyState = 3 THEN
        IF SlidePos > 0 THEN
            FOR LoopVar = 200 TO 219
                PRINT AT LoopVar, 0
            NEXT LoopVar
            SlidePos = 0
            TitleColor = 0
            WavePhase = 0
        END IF
        GOTO SkipPressfire
    END IF

    IF SlidePos <= 5 THEN
        ' Slide-in phase: PRESS from left, FIRE from right
        TitleColor = TitleColor + 1
        IF TitleColor >= 8 THEN
            TitleColor = 0
            ' Clear row 10
            FOR LoopVar = 200 TO 219
                PRINT AT LoopVar, 0
            NEXT LoopVar
            ' "PRESS" slides from col 0 to col 5 (white, GRAM)
            #Card = 200 + SlidePos
            PRINT AT #Card, GRAM_FONT_P * 8 + COL_WHITE + $0800
            PRINT AT #Card + 1, GRAM_FONT_R * 8 + COL_WHITE + $0800
            PRINT AT #Card + 2, GRAM_FONT_E * 8 + COL_WHITE + $0800
            PRINT AT #Card + 3, GRAM_FONT_S * 8 + COL_WHITE + $0800
            PRINT AT #Card + 4, GRAM_FONT_S * 8 + COL_WHITE + $0800
            ' "FIRE" slides from col 16 to col 11
            #Card = 216 - SlidePos
            PRINT AT #Card, GRAM_FONT_F * 8 + COL_WHITE + $0800
            PRINT AT #Card + 1, GRAM_FONT_I * 8 + COL_WHITE + $0800
            PRINT AT #Card + 2, GRAM_FONT_R * 8 + COL_WHITE + $0800
            PRINT AT #Card + 3, GRAM_FONT_E * 8 + COL_WHITE + $0800
            SlidePos = SlidePos + 1
            ' Trigger impact shake when words connect (SlidePos just became 6)
            IF SlidePos = 6 THEN ShakeTimer = 8
        END IF
    ELSE
        ' Shimmer - cycle Grey/White every 12 frames
        TitleColor = TitleColor + 1
        IF TitleColor >= 4 THEN
            TitleColor = 0
            WavePhase = WavePhase + 1
            IF WavePhase >= 4 THEN WavePhase = 0
            ' WaveColors: 0=grey (use $1800), 7=white (use $0800+7)
            IF WaveColors(WavePhase) = 0 THEN
                ' Grey = color 8: GRAM card * 8 + $1800 (bit 12 set, low bits 0)
                PRINT AT 205, GRAM_FONT_P * 8 + $1800
                PRINT AT 206, GRAM_FONT_R * 8 + $1800
                PRINT AT 207, GRAM_FONT_E * 8 + $1800
                PRINT AT 208, GRAM_FONT_S * 8 + $1800
                PRINT AT 209, GRAM_FONT_S * 8 + $1800
                PRINT AT 210, 0  ' space
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
                PRINT AT 210, 0  ' space
                PRINT AT 211, GRAM_FONT_F * 8 + COL_WHITE + $0800
                PRINT AT 212, GRAM_FONT_I * 8 + COL_WHITE + $0800
                PRINT AT 213, GRAM_FONT_R * 8 + COL_WHITE + $0800
                PRINT AT 214, GRAM_FONT_E * 8 + COL_WHITE + $0800
            END IF
        END IF
    END IF
SkipPressfire:

    ' Scrolling starfield - update every 5 frames
    StarTimer = StarTimer + 1
    IF StarTimer >= 5 THEN
        StarTimer = 0
        StarTick = StarTick + 1
        GOSUB ScrollStars
    END IF

    ' Animation - toggle walk frame every 16 frames via GRAM redefine
    ShimmerCount = ShimmerCount + 1
    IF ShimmerCount >= 16 THEN
        ShimmerCount = 0
        TitleFrame = 1 - TitleFrame
        IF TitleFrame = 0 THEN
            DEFINE GRAM_BAND1, 1, Band1Gfx
            WAIT
            DEFINE GRAM_BAND2, 1, Band2Gfx
        ELSE
            DEFINE GRAM_BAND1, 1, Band1F1Gfx
            WAIT
            DEFINE GRAM_BAND2, 1, Band2F1Gfx
        END IF
    END IF

    ' Check for fire button to start game
    IF CONT.BUTTON THEN
        PLAY OFF                       ' Stop title music
        SPRITE SPR_FLYER, 0, 0, 0  ' Hide flyer before gameplay
        GOTO StartGame
    END IF

    GOTO TitleLoop

' --- Draw 3x3 alien grid on BACKTAB ---
DrawAlienGrid: PROCEDURE
    ' Clear rows 5-7 first (cols 0-19)
    FOR LoopVar = 100 TO 159
        PRINT AT LoopVar, 0
    NEXT LoopVar
    ' Card values for left/right halves (GRAM + blue foreground)
    #Card = (GRAM_BAND1 * 8) + COL_BLUE + $0800
    #Mask = (GRAM_BAND2 * 8) + COL_BLUE + $0800
    ' Draw 3 rows of 3 aliens (each alien = 2 cards wide, 1 card gap between)
    FOR LoopVar = 0 TO 2
        #ScreenPos = (5 + LoopVar) * 20 + TitleGridCol
        ' Alien 1
        PRINT AT #ScreenPos, #Card
        PRINT AT #ScreenPos + 1, #Mask
        ' Alien 2 (offset +3 cards)
        PRINT AT #ScreenPos + 3, #Card
        PRINT AT #ScreenPos + 4, #Mask
        ' Alien 3 (offset +6 cards)
        PRINT AT #ScreenPos + 6, #Card
        PRINT AT #ScreenPos + 7, #Mask
    NEXT LoopVar
    RETURN
END

' --- GenerateStars: place 16 random stars on safe rows ---
GenerateStars: PROCEDURE
    StarCount = 0
    ' Safe rows: 3(60-79), 4(80-99), 8(160-179), 9(180-199), 11(220-239)
    FOR LoopVar = 0 TO 15
        ' Pick a safe row: 0-1=row3, 2-4=row4, 5-7=row8, 8-10=row9, 11-15=row11
        Col = RANDOM(20)
        Row = RANDOM(5)
        IF Row = 0 THEN
            #StarPos(LoopVar) = 60 + Col       ' Row 3
        ELSEIF Row = 1 THEN
            #StarPos(LoopVar) = 80 + Col       ' Row 4
        ELSEIF Row = 2 THEN
            #StarPos(LoopVar) = 160 + Col      ' Row 8
        ELSEIF Row = 3 THEN
            #StarPos(LoopVar) = 180 + Col      ' Row 9
        ELSE
            #StarPos(LoopVar) = 220 + Col      ' Row 11
        END IF
        ' Alternate star type: even=slow/dim, odd=fast/bright
        StarType(LoopVar) = LoopVar AND 1
        ' Draw the star
        IF StarType(LoopVar) = 0 THEN
            PRINT AT #StarPos(LoopVar), GRAM_STAR1 * 8 + 4 + $0800  ' Dark green, dim
        ELSE
            PRINT AT #StarPos(LoopVar), GRAM_STAR2 * 8 + 7 + $0800  ' White, bright
        END IF
        StarCount = StarCount + 1
    NEXT LoopVar
    RETURN
END

' --- ScrollStars: shift all stars left with parallax ---
ScrollStars: PROCEDURE
    FOR LoopVar = 0 TO StarCount - 1
        ' Calculate row and column from BACKTAB position
        Row = #StarPos(LoopVar) / 20
        Col = #StarPos(LoopVar) - (Row * 20)

        ' Clear old position
        PRINT AT #StarPos(LoopVar), 0

        ' Parallax: slow stars move every other tick, fast every tick
        IF StarType(LoopVar) = 0 THEN
            ' Slow/dim: move every 2nd tick
            IF (StarTick AND 1) = 0 THEN
                IF Col = 0 THEN
                    Col = 19
                ELSE
                    Col = Col - 1
                END IF
            END IF
        ELSE
            ' Fast/bright: move every tick
            IF Col = 0 THEN
                Col = 19
            ELSE
                Col = Col - 1
            END IF
        END IF

        ' Update position
        #StarPos(LoopVar) = Row * 20 + Col

        ' Redraw star
        IF StarType(LoopVar) = 0 THEN
            PRINT AT #StarPos(LoopVar), GRAM_STAR1 * 8 + 4 + $0800
        ELSE
            PRINT AT #StarPos(LoopVar), GRAM_STAR2 * 8 + 7 + $0800
        END IF
    NEXT LoopVar
    RETURN
END

' ============================================
' START GAME - Initialize gameplay
' ============================================
StartGame:
    CLS

    ' Initialize all aliens as alive (9 bits = $1FF)
    FOR LoopVar = 0 TO ALIEN_ROWS - 1
        #AlienRow(LoopVar) = $1FF
    NEXT LoopVar

    ' Initialize march speed
    CurrentMarchSpeed = MARCH_SPEED_START

    ' Draw the alien grid
    GOSUB DrawAliens

    ' Draw score and lives
    PRINT AT 220, "SCORE: 0"
    ' Lives ship icon (GRAM card 0, green, Color Stack mode)
    PRINT AT 236, (GRAM_SHIP * 8) + COL_WHITE + $0800
    PRINT AT 237 COLOR COL_WHITE, "X4"

    ' Initialize saucer (inactive, spawn after ~5 seconds)
    FlyState = 0
    FlyPhase = 0  ' Spawn countdown (counts up to threshold)
    #BeamTimer = 0  ' No beam power-up
    #RapidTimer = 0 ' No rapid fire
    TitleFrame = 0  ' No power-up drop
    TitleColor = 0  ' First drop is beam
    TitleJitter = 0 ' No fire cooldown
    SPRITE SPR_SAUCER, 0, 0, 0
    SPRITE SPR_SAUCER2, 0, 0, 0
    SPRITE SPR_POWERUP, 0, 0, 0

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
            SPRITE SPR_SAUCER, 0, 0, 0
            SPRITE SPR_SAUCER2, 0, 0, 0
            SPRITE SPR_POWERUP, 0, 0, 0
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

    ' Animate alien walk frames independently (every 16 frames)
    ShimmerCount = ShimmerCount + 1
    IF ShimmerCount >= 16 THEN
        ShimmerCount = 0
        AnimFrame = AnimFrame XOR 1
        GOSUB DrawAliens
    END IF

    ' Update alien march
    MarchCount = MarchCount + 1
    IF MarchCount >= CurrentMarchSpeed THEN
        MarchCount = 0
        GOSUB MarchAliens
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

    ' Update flying saucer
    GOSUB UpdateSaucer

    ' Update power-up drop/pickup
    GOSUB UpdatePowerUp

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
                    PRINT AT 237 COLOR COL_WHITE, "X3"
                END IF
                IF Lives = 2 THEN
                    PRINT AT 237 COLOR COL_WHITE, "X2"
                END IF
                IF Lives = 1 THEN
                    PRINT AT 237 COLOR COL_WHITE, "X1"
                END IF
                IF Lives = 0 THEN
                    ' Game over
                    PRINT AT 237 COLOR COL_WHITE, "X0"
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

    ' Tick down power-up timers
    IF #BeamTimer > 0 THEN
        #BeamTimer = #BeamTimer - 1
    END IF
    IF #RapidTimer > 0 THEN
        #RapidTimer = #RapidTimer - 1
    END IF
    IF TitleJitter > 0 THEN
        TitleJitter = TitleJitter - 1
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

    ' Fire: side buttons or keypad 1 (auto-fire, works while moving)
    IF CONT.BUTTON OR CONT.KEY = 1 THEN
        IF BulletActive = 0 THEN
            IF TitleJitter = 0 THEN
                BulletX = PlayerX + 3  ' Center of ship
                BulletY = PLAYER_Y - 4
                BulletActive = 1
                IF #RapidTimer > 0 THEN
                    TitleJitter = RAPID_COOLDOWN
                END IF
            END IF
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
    ' Move bullet up (rapid fire = 3px/frame, normal = 1px/frame)
    IF #RapidTimer > 0 THEN
        IF BulletY > BULLET_TOP + RAPID_SPEED THEN
            BulletY = BulletY - RAPID_SPEED
        ELSE
            BulletActive = 0
        END IF
    ELSE
        IF BulletY > BULLET_TOP + BULLET_SPEED THEN
            BulletY = BulletY - BULLET_SPEED
        ELSE
            BulletActive = 0
        END IF
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

            IF #BeamTimer > 0 THEN
                ' Wide beam mode: beam covers BulletX-3 to BulletX+4 (8px)
                ' Check every column the beam touches
                IF BulletX >= 3 THEN
                    HitCol = (BulletX - 3) / 8
                    GOSUB CheckOneColumn
                END IF

                IF BulletActive THEN
                    HitCol = (BulletX) / 8
                    GOSUB CheckOneColumn
                END IF

                IF BulletActive THEN
                    HitCol = (BulletX + 4) / 8
                    GOSUB CheckOneColumn
                END IF
            ELSE
                ' Normal bullet: check columns from BulletX-1 to BulletX+6
                IF BulletX >= 8 THEN
                    HitCol = (BulletX - 1) / 8
                    GOSUB CheckOneColumn
                END IF

                IF BulletActive THEN
                    HitCol = (BulletX + 2) / 8
                    GOSUB CheckOneColumn
                END IF

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

                ' Beam pierces through; normal bullet stops
                IF #BeamTimer = 0 THEN
                    BulletActive = 0
                END IF

                ' Update score
                #Score = #Score + 10

                ' Show explosion on BACKTAB (replaces alien, stays in place)
                #ExplosionPos = HitRow * 20 + HitCol
                ExplosionTimer = 15  ' Show for 15 frames (~250ms total)
                ' Frame 1 starts pink (color 12 = $1804 for GRAM)
                PRINT AT #ExplosionPos, GRAM_EXPLOSION * 8 + 4 + $1800
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
            SPRITE SPR_PLAYER, PlayerX + $0200, PLAYER_Y, GRAM_SHIP * 8 + COL_WHITE + $0800
            SPRITE SPR_SHIP_ACCENT, PlayerX + $0200, PLAYER_Y, GRAM_SHIP_ACCENT * 8 + $1800
        ELSE
            SPRITE SPR_PLAYER, 0, 0, 0
            SPRITE SPR_SHIP_ACCENT, 0, 0, 0
        END IF
    ELSE
        ' Normal display - body + accent stacked at same position
        SPRITE SPR_PLAYER, PlayerX + $0200, PLAYER_Y, GRAM_SHIP * 8 + COL_WHITE + $0800
        SPRITE SPR_SHIP_ACCENT, PlayerX + $0200, PLAYER_Y, GRAM_SHIP_ACCENT * 8 + $1800
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

        IF #BeamTimer > 0 THEN
            ' Wide beam mode: 8px wide x 16px tall, centered on bullet position
            IF BulletX >= 3 THEN
                SPRITE SPR_PBULLET, (BulletX - 3) + $0200, BulletY + $0100, GRAM_BEAM * 8 + LaserColor + $0800
            ELSE
                SPRITE SPR_PBULLET, $0200, BulletY + $0100, GRAM_BEAM * 8 + LaserColor + $0800
            END IF
        ELSE
            SPRITE SPR_PBULLET, BulletX + $0200, BulletY, GRAM_BULLET * 8 + LaserColor + $0800
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

    SEGMENT 1   ' Move remaining procedures + graphics to Segment 1 ($A000-$BFFF, 8K)

' --------------------------------------------
' UpdateSaucer - Spawn, move, and check collision for flying saucer
' --------------------------------------------
UpdateSaucer: PROCEDURE
    IF FlyState = 0 THEN
        ' Inactive - count up to spawn threshold (~2 seconds)
        FlyPhase = FlyPhase + 1
        IF FlyPhase >= 120 THEN
            ' Spawn! Pick random direction
            FlyPhase = 0
            IF RANDOM(2) = 0 THEN
                ' Fly left to right
                FlyState = 1
                FlyX = 0
            ELSE
                ' Fly right to left
                FlyState = 2
                FlyX = 159
            END IF
            FlyY = 8            ' Row 0 (sprites have 8px Y offset on STIC)
            FlySpeed = 0
            FlyColor = 1        ' Cyan (low 3 bits; $1000 adds bit 3 in SPRITE)
        END IF
        RETURN
    END IF

    ' Active - move saucer
    FlySpeed = FlySpeed + 1
    IF FlySpeed >= 2 THEN
        FlySpeed = 0
        IF FlyState = 1 THEN
            FlyX = FlyX + 1
            IF FlyX > 167 THEN
                ' Off screen right - deactivate
                FlyState = 0
                SPRITE SPR_SAUCER, 0, 0, 0
                SPRITE SPR_SAUCER2, 0, 0, 0
                RETURN
            END IF
        ELSE
            IF FlyX > 0 THEN
                FlyX = FlyX - 1
            ELSE
                ' Off screen left - deactivate
                FlyState = 0
                SPRITE SPR_SAUCER, 0, 0, 0
                SPRITE SPR_SAUCER2, 0, 0, 0
                RETURN
            END IF
        END IF
    END IF

    ' Draw saucer as 2 sprites: left half + FLIPX right half (16px wide, cyan)
    SPRITE SPR_SAUCER, FlyX + $0200, FlyY, GRAM_SAUCER * 8 + FlyColor + $1800
    SPRITE SPR_SAUCER2, (FlyX + 8) + $0200, FlyY + $0400, GRAM_SAUCER * 8 + FlyColor + $1800

    ' Check collision with player bullet (16px wide hitbox)
    IF BulletActive THEN
        IF BulletY < 14 THEN
            ' Bullet is in saucer Y range (top of screen)
            IF BulletX >= FlyX - 4 THEN
                IF BulletX <= FlyX + 16 THEN
                    ' HIT the saucer!
                    BulletActive = 0
                    FlyState = 0
                    SPRITE SPR_SAUCER, 0, 0, 0
                    SPRITE SPR_SAUCER2, 0, 0, 0
                    ' Bonus points
                    #Score = #Score + 50
                    ' Drop power-up from saucer position
                    TitleFrame = 1       ' Falling
                    TitleMarchDir = FlyX        ' Drop from saucer X
                    FlyY = 8             ' Start falling from row 0
                    SlidePos = 0
                    ' Show explosion at saucer position using BACKTAB
                    #ExplosionPos = FlyX / 8
                    ExplosionTimer = 15
                    PRINT AT #ExplosionPos, GRAM_EXPLOSION * 8 + 4 + $1800
                END IF
            END IF
        END IF
    END IF
    RETURN
END

' --------------------------------------------
' UpdatePowerUp - Handle falling/landed power-up capsule
' --------------------------------------------
UpdatePowerUp: PROCEDURE
    IF TitleFrame = 0 THEN RETURN

    ' Set capsule flash colors based on power-up type
    ' Reuse TitleGridCol/TitleMarchCount as temp color vars
    IF TitleColor = 0 THEN
        TitleGridCol = COL_YELLOW    ' Beam: yellow/white
        TitleMarchCount = COL_WHITE
    ELSE
        TitleGridCol = COL_GREEN     ' Rapid: green/blue
        TitleMarchCount = COL_BLUE
    END IF

    IF TitleFrame = 1 THEN
        ' Falling: move down 2px per frame
        FlyY = FlyY + 2
        IF FlyY >= PLAYER_Y THEN
            ' Landed at player level
            FlyY = PLAYER_Y
            TitleFrame = 2
            #PowerTimer = 300   ' 5 seconds to pick up
            SlidePos = 0
        END IF
        ' Draw falling capsule (color flash every 4 frames)
        SlidePos = SlidePos + 1
        IF SlidePos >= 8 THEN SlidePos = 0
        IF SlidePos < 4 THEN
            SPRITE SPR_POWERUP, TitleMarchDir + $0200, FlyY, GRAM_POWERUP * 8 + TitleGridCol + $0800
        ELSE
            SPRITE SPR_POWERUP, TitleMarchDir + $0200, FlyY, GRAM_POWERUP * 8 + TitleMarchCount + $0800
        END IF
        RETURN
    END IF

    ' State 2: Landed - waiting for pickup
    #PowerTimer = #PowerTimer - 1

    ' Check pickup: player X overlaps power-up X (within ±12px)
    IF DeathTimer = 0 THEN
        IF PlayerX >= TitleMarchDir - 12 THEN
            IF PlayerX <= TitleMarchDir + 12 THEN
                ' Picked up! Activate power-up based on type
                IF TitleColor = 0 THEN
                    #BeamTimer = 300
                    #RapidTimer = 0
                ELSE
                    #RapidTimer = 300
                    #BeamTimer = 0
                END IF
                TitleFrame = 0
                SPRITE SPR_POWERUP, 0, 0, 0
                TitleColor = TitleColor XOR 1
                RETURN
            END IF
        END IF
    END IF

    ' Check timeout
    IF #PowerTimer = 0 THEN
        TitleFrame = 0
        SPRITE SPR_POWERUP, 0, 0, 0
        RETURN
    END IF

    ' Draw landed capsule with flash effect
    SlidePos = SlidePos + 1
    IF SlidePos >= 8 THEN SlidePos = 0
    IF #PowerTimer < 100 THEN
        ' Rapid flash in last ~1.7 seconds (every 2 frames)
        IF SlidePos < 2 THEN
            SPRITE SPR_POWERUP, TitleMarchDir + $0200, PLAYER_Y, GRAM_POWERUP * 8 + TitleGridCol + $0800
        ELSEIF SlidePos < 4 THEN
            SPRITE SPR_POWERUP, 0, 0, 0  ' Invisible
        ELSEIF SlidePos < 6 THEN
            SPRITE SPR_POWERUP, TitleMarchDir + $0200, PLAYER_Y, GRAM_POWERUP * 8 + TitleMarchCount + $0800
        ELSE
            SPRITE SPR_POWERUP, 0, 0, 0  ' Invisible
        END IF
    ELSE
        ' Normal flash (slow color cycle)
        IF SlidePos < 4 THEN
            SPRITE SPR_POWERUP, TitleMarchDir + $0200, PLAYER_Y, GRAM_POWERUP * 8 + TitleGridCol + $0800
        ELSE
            SPRITE SPR_POWERUP, TitleMarchDir + $0200, PLAYER_Y, GRAM_POWERUP * 8 + TitleMarchCount + $0800
        END IF
    END IF
    RETURN
END

' --------------------------------------------
' DrawAliens - Draw all aliens to background
' --------------------------------------------
DrawAliens: PROCEDURE
    ' Clear ALL rows above current alien position (handles multiple drops)
    IF AlienOffsetY > 0 THEN
        FOR ClearRow = 0 TO AlienOffsetY - 1
            #ScreenPos = (ALIEN_START_Y + ClearRow) * 20
            FOR Col = 0 TO 19
                PRINT AT #ScreenPos + Col, 0
            NEXT Col
        NEXT ClearRow
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

    ' Reset all aliens to alive (9 bits = $1FF)
    FOR LoopVar = 0 TO ALIEN_ROWS - 1
        #AlienRow(LoopVar) = $1FF
    NEXT LoopVar

    ' Clear any active bullets
    BulletActive = 0
    ABulletActive = 0
    SPRITE SPR_PBULLET, 0, 0, 0
    SPRITE SPR_ABULLET, 0, 0, 0
    SPRITE SPR_SAUCER, 0, 0, 0
    SPRITE SPR_SAUCER2, 0, 0, 0
    SPRITE SPR_POWERUP, 0, 0, 0
    FlyState = 0
    FlyPhase = 0
    TitleFrame = 0
    #RapidTimer = 0
    TitleJitter = 0

    ' Clear screen and redraw
    CLS
    GOSUB DrawAliens

    ' Redraw HUD
    PRINT AT 220, "SCORE:"
    PRINT AT 227, <>#Score
    PRINT AT 236, (GRAM_SHIP * 8) + COL_WHITE + $0800
    IF Lives = 4 THEN
        PRINT AT 237 COLOR COL_WHITE, "X4"
    END IF
    IF Lives = 3 THEN
        PRINT AT 237 COLOR COL_WHITE, "X3"
    END IF
    IF Lives = 2 THEN
        PRINT AT 237 COLOR COL_WHITE, "X2"
    END IF
    IF Lives = 1 THEN
        PRINT AT 237 COLOR COL_WHITE, "X1"
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
' GenerateGameStars - Place twinkling stars on row 0
' --------------------------------------------
GenerateGameStars: PROCEDURE
    StarCount = 0
    StarTimer = 0
    StarTick = 0
    ' Place 6 stars on row 0 (positions 0-19)
    FOR LoopVar = 0 TO 5
        Col = RANDOM(20)
        #StarPos(LoopVar) = Col           ' Row 0
        StarType(LoopVar) = LoopVar AND 1
        IF StarType(LoopVar) = 0 THEN
            PRINT AT Col, GRAM_STAR1 * 8 + 4 + $0800
        ELSE
            PRINT AT Col, GRAM_STAR2 * 8 + 7 + $0800
        END IF
        StarCount = StarCount + 1
    NEXT LoopVar
    ' Place 6 stars on row 10 (positions 200-219)
    FOR LoopVar = 6 TO 11
        Col = RANDOM(20)
        #StarPos(LoopVar) = 200 + Col     ' Row 10
        StarType(LoopVar) = LoopVar AND 1
        IF StarType(LoopVar) = 0 THEN
            PRINT AT 200 + Col, GRAM_STAR1 * 8 + 4 + $0800
        ELSE
            PRINT AT 200 + Col, GRAM_STAR2 * 8 + 7 + $0800
        END IF
        StarCount = StarCount + 1
    NEXT LoopVar
    RETURN
END

' --------------------------------------------
' TwinkleStars - Toggle one star on/off every 4 frames
' --------------------------------------------
TwinkleStars: PROCEDURE
    StarTimer = StarTimer + 1
    IF StarTimer >= 4 THEN
        StarTimer = 0
        ' Toggle current star visible/invisible
        #Card = PEEK($200 + #StarPos(StarTick))
        IF #Card = 0 THEN
            ' Star is off - turn it back on
            IF StarType(StarTick) = 0 THEN
                PRINT AT #StarPos(StarTick), GRAM_STAR1 * 8 + 4 + $0800
            ELSE
                PRINT AT #StarPos(StarTick), GRAM_STAR2 * 8 + 7 + $0800
            END IF
        ELSE
            ' Star is on - turn it off
            PRINT AT #StarPos(StarTick), 0
        END IF
        ' Advance to next star
        StarTick = StarTick + 1
        IF StarTick >= StarCount THEN StarTick = 0
    END IF
    RETURN
END

' --------------------------------------------
' Graphics Data
' --------------------------------------------
ShipGfx:
    ' Player ship body - Frame 0 (blocky tank-style cannon)
    BITMAP "...XX..."
    BITMAP "...XX..."
    BITMAP "..XXXX.."
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XX....XX"
    BITMAP "XX....XX"

    ' Frame 1 (engine glow variation)
    BITMAP "...XX..."
    BITMAP "...XX..."
    BITMAP "..XXXX.."
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "X......X"
    BITMAP "X......X"

' Ship accent overlay (fills gaps in body for 2-color effect)
ShipAccentGfx:
    ' Frame 0 - engine glow (cyan fills center gap in rows 6-7)
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "..XXXX.."
    BITMAP "..XXXX.."

    ' Frame 1 - brighter engine glow
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP ".XXXXXX."
    BITMAP ".XXXXXX."

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
' Space Invaders Sprite Library
' All wide aliens = 2 side-by-side 8x8 sprites (16x8)
' Centered/padded to fit 8-pixel GRAM cards
' ============================================

' --- SKULL INVADER (12x8 → padded to 16x8) ---
' Title screen big alien
Band1Gfx:
    ' SKULL left - Frame 1
    BITMAP "......XX"
    BITMAP "...XXXXX"
    BITMAP "..XXXXXX"
    BITMAP "..XXX..X"
    BITMAP "..XXXXXX"
    BITMAP ".....XX."
    BITMAP "....XX.."
    BITMAP "..XX...."

Band2Gfx:
    ' SKULL right - Frame 1
    BITMAP "XX......"
    BITMAP "XXXXX..."
    BITMAP "XXXXXX.."
    BITMAP "X..XXX.."
    BITMAP "XXXXXX.."
    BITMAP ".XX....."
    BITMAP "..XX...."
    BITMAP "....XX.."

Band1F1Gfx:
    ' SKULL left - Frame 2
    BITMAP "......XX"
    BITMAP "...XXXXX"
    BITMAP "..XXXXXX"
    BITMAP "..XXX..X"
    BITMAP "..XXXXXX"
    BITMAP "....XXX."
    BITMAP "...XX..X"
    BITMAP "....XX.."

Band2F1Gfx:
    ' SKULL right - Frame 2
    BITMAP "XX......"
    BITMAP "XXXXX..."
    BITMAP "XXXXXX.."
    BITMAP "X..XXX.."
    BITMAP "XXXXXX.."
    BITMAP ".XXX...."
    BITMAP "X..XX..."
    BITMAP "..XX...."

' --- SMALL CRAB (6x8 → centered in 8x8) ---
SmallCrabF1Gfx:
    BITMAP "...XX..."
    BITMAP "..XXXX.."
    BITMAP ".XXXXXX."
    BITMAP "XX.XX.XX"
    BITMAP "XXXXXXXX"
    BITMAP "..X..X.."
    BITMAP ".X.XX.X."
    BITMAP "..X..X.."

SmallCrabF2Gfx:
    BITMAP "...XX..."
    BITMAP "..XXXX.."
    BITMAP ".XXXXXX."
    BITMAP "XX.XX.XX"
    BITMAP "XXXXXXXX"
    BITMAP ".X.XX.X."
    BITMAP "........"
    BITMAP ".X....X."

' ============================================
' Custom Title Font - "SPACE INTRUDERS"
' Outlined / hollow style - wide and spacey
' ============================================

FontSGfx:
    BITMAP ".XXXXX.."
    BITMAP "XX...XX."
    BITMAP "XX......"
    BITMAP ".XXXXX.."
    BITMAP ".....XX."
    BITMAP ".....XX."
    BITMAP "XX...XX."
    BITMAP ".XXXXX.."

FontPGfx:
    BITMAP "XXXXXX.."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XXXXXX.."
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX......"

FontAGfx:
    BITMAP ".XXXXX.."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX..XXX."
    BITMAP "XXXXXXX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."

FontCGfx:
    BITMAP ".XXXXX.."
    BITMAP "XX...XX."
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX...XX."
    BITMAP ".XXXXX.."

FontEGfx:
    BITMAP "XXXXXXX."
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XXXXXXX."
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XXXXXXX."

FontIGfx:
    BITMAP "XXXXXXX."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "XXXXXXX."

FontNGfx:
    BITMAP "XX...XX."
    BITMAP "XXX..XX."
    BITMAP "XXXX.XX."
    BITMAP "XX.XXXX."
    BITMAP "XX..XXX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."

FontTGfx:
    BITMAP "XXXXXXX."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."

FontRGfx:
    BITMAP "XXXXXX.."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XXXXXX.."
    BITMAP "XX..XX.."
    BITMAP "XX...XX."
    BITMAP "XX...XX."

FontUGfx:
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP ".XXXXX.."

FontDGfx:
    BITMAP "XXXXXX.."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XXXXXX.."

FontFGfx:
    BITMAP "XXXXXXX."
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XXXXXXX."
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX......"

' --- Star dots (single pixel at different positions for variety) ---
Star1Gfx:
    BITMAP "........"
    BITMAP "..X....."
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"

Star2Gfx:
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP ".....X.."
    BITMAP "........"
    BITMAP "........"

' --- Flying Saucer (rounded rectangle) ---
SaucerGfx:
    BITMAP ".....XXX"
    BITMAP "...XXXXX"
    BITMAP "..XXXXXX"
    BITMAP ".XX.XX.X"
    BITMAP "XXXXXXXX"
    BITMAP "..XXX..X"
    BITMAP "...X...."
    BITMAP "........"

' --- Wide Beam (4px centered column) ---
BeamGfx:
    BITMAP "..XXXX.."
    BITMAP "..XXXX.."
    BITMAP "..XXXX.."
    BITMAP "..XXXX.."
    BITMAP "..XXXX.."
    BITMAP "..XXXX.."
    BITMAP "..XXXX.."
    BITMAP "..XXXX.."

' --- Power-Up Capsule (flashing pickup) ---
PowerUpGfx:
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "..XXXX.."
    BITMAP ".XX..XX."
    BITMAP ".XXXXXX."
    BITMAP "..XXXX.."
    BITMAP "........"

' --- BOLT SPARK (above letter - points down) ---
SparkUpGfx:
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP ".......X"

' --- BOLT SPARK (below letter - points up) ---
SparkDnGfx:
    BITMAP ".......X"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"

' --- BOLT SPARK frame 2 (above - dot trails left) ---
SparkUpGfx2:
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "......X."

' --- BOLT SPARK frame 2 (below - dot trails right) ---
SparkDnGfx2:
    BITMAP "......X."
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"

' --- SQUID (11x8 → padded to 16x8) ---
SquidLeftF1Gfx:
    BITMAP "....X..."
    BITMAP "..X..X.."
    BITMAP "..X.XXXX"
    BITMAP "..XXX.XX"
    BITMAP "..XXXXXX"
    BITMAP "...XXXXX"
    BITMAP "....X..."
    BITMAP "...X...."

SquidRightF1Gfx:
    BITMAP "..X....."
    BITMAP ".X..X..."
    BITMAP "XXX.X..."
    BITMAP "X.XXX..."
    BITMAP "XXXXX..."
    BITMAP "XXXX...."
    BITMAP "..X....."
    BITMAP "...X...."

SquidLeftF2Gfx:
    BITMAP "....X..."
    BITMAP ".....X.."
    BITMAP "....XXXX"
    BITMAP "...XX.XX"
    BITMAP "..XXXXXX"
    BITMAP "..X.XXXX"
    BITMAP "..X.X..."
    BITMAP ".....XX."

SquidRightF2Gfx:
    BITMAP "..X....."
    BITMAP ".X......"
    BITMAP "XXX....."
    BITMAP "X.XX...."
    BITMAP "XXXXX..."
    BITMAP "XXX.X..."
    BITMAP "..X.X..."
    BITMAP "XX......"

' --- WIDE CRAB (14x7 → padded to 16x8) ---
WideCrabLeftF1Gfx:
    BITMAP ".....XXX"
    BITMAP "...XXXXX"
    BITMAP "..XXXXXX"
    BITMAP ".XX.XX.X"
    BITMAP ".XXXXXXX"
    BITMAP "..XXX..X"
    BITMAP "...X...."
    BITMAP "........"

WideCrabRightF1Gfx:
    BITMAP "XXX....."
    BITMAP "XXXXX..."
    BITMAP "XXXXXX.."
    BITMAP "X.XX.XX."
    BITMAP "XXXXXXX."
    BITMAP "X..XXX.."
    BITMAP "....X..."
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

' ============================================
' Flying Crab Path Data (ROM, saves 128 RAM vars)
' ============================================
' Figure-8 Lissajous: X = 84 + 50*sin(t), Y = 56 + 18*sin(2t)
FlyPathXData:
    DATA 84, 89, 94, 99, 103, 108, 112, 116
    DATA 119, 123, 126, 128, 130, 132, 133, 134
    DATA 134, 134, 133, 132, 130, 128, 126, 123
    DATA 119, 116, 112, 108, 103, 99, 94, 89
    DATA 84, 79, 74, 69, 65, 60, 56, 52
    DATA 49, 45, 42, 40, 38, 36, 35, 34
    DATA 34, 34, 35, 36, 38, 40, 42, 45
    DATA 49, 52, 56, 60, 65, 69, 74, 79

FlyPathYData:
    DATA 56, 60, 63, 66, 69, 71, 73, 74
    DATA 74, 74, 73, 71, 69, 66, 63, 60
    DATA 56, 52, 49, 46, 43, 41, 39, 38
    DATA 38, 38, 39, 41, 43, 46, 49, 52
    DATA 56, 60, 63, 66, 69, 71, 73, 74
    DATA 74, 74, 73, 71, 69, 66, 63, 60
    DATA 56, 52, 49, 46, 43, 41, 39, 38
    DATA 38, 38, 39, 41, 43, 46, 49, 52

' ============================================
' Music Data - "Intruder Drive" theme
' ============================================
' Techno 8-bar loop: Em | Em | G | G | D | D | Em | Em
' 16th-note grid, tempo 6
space_intruders_theme:
  DATA 6

  ' ---- 1-bar intro "boot" (little climb) ----
  MUSIC E4X, E2Z, -, M1
  MUSIC G4X, S,   -, -
  MUSIC B4X, S,   -, -
  MUSIC E5X, S,   -, M3
  MUSIC D5X, S,   -, M2
  MUSIC B4X, S,   -, M3
  MUSIC G4X, S,   -, -
  MUSIC E4X, S,   -, M3
  MUSIC -,   S,   -, M1
  MUSIC -,   S,   -, -
  MUSIC -,   S,   -, M3
  MUSIC -,   S,   -, -
  MUSIC E4X, S,   -, M2
  MUSIC F4#X,S,   -, M3
  MUSIC G4X, S,   -, -
  MUSIC A4X, S,   -, M3

si_loop:
  ' ---- Bar 1 (Em) ----
  MUSIC E4X, E2Z, -, M1
  MUSIC B4X, S,   -, -
  MUSIC F4#X,S,   -, -
  MUSIC B4X, S,   -, M3
  MUSIC E5X, S,   -, M2
  MUSIC B4X, S,   -, M3
  MUSIC G4X, S,   -, -
  MUSIC B4X, S,   -, M3
  MUSIC D5X, S,   -, M1
  MUSIC B4X, S,   -, -
  MUSIC G4X, S,   -, M3
  MUSIC B4X, S,   -, -
  MUSIC E5X, S,   -, M2
  MUSIC B4X, S,   -, M3
  MUSIC F4#X,S,   -, -
  MUSIC B4X, S,   -, M3

  ' ---- Bar 2 (Em, variation) ----
  MUSIC E4X, E2Z, -, M1
  MUSIC B4X, S,   -, -
  MUSIC G4X, S,   -, -
  MUSIC B4X, S,   -, M3
  MUSIC E5X, S,   -, M2
  MUSIC B4X, S,   -, M3
  MUSIC F4#X,S,   -, -
  MUSIC B4X, S,   -, M3
  MUSIC D5X, S,   -, M1
  MUSIC B4X, S,   -, -
  MUSIC A4X, S,   -, M3
  MUSIC B4X, S,   -, -
  MUSIC E5X, S,   -, M2
  MUSIC B4X, S,   -, M3
  MUSIC G4X, S,   -, -
  MUSIC B4X, S,   -, M3

  ' ---- Bar 3 (G) ----
  MUSIC G4X, G2Z, -, M1
  MUSIC B4X, S,   -, -
  MUSIC D5X, S,   -, -
  MUSIC B4X, S,   -, M3
  MUSIC G5X, S,   -, M2
  MUSIC B4X, S,   -, M3
  MUSIC D5X, S,   -, -
  MUSIC B4X, S,   -, M3
  MUSIC A4X, S,   -, M1
  MUSIC B4X, S,   -, -
  MUSIC D5X, S,   -, M3
  MUSIC B4X, S,   -, -
  MUSIC G5X, S,   -, M2
  MUSIC B4X, S,   -, M3
  MUSIC D5X, S,   -, -
  MUSIC B4X, S,   -, M3

  ' ---- Bar 4 (G, variation) ----
  MUSIC G4X, G2Z, -, M1
  MUSIC B4X, S,   -, -
  MUSIC D5X, S,   -, -
  MUSIC B4X, S,   -, M3
  MUSIC F4#X,S,   -, M2
  MUSIC B4X, S,   -, M3
  MUSIC D5X, S,   -, -
  MUSIC B4X, S,   -, M3
  MUSIC E5X, S,   -, M1
  MUSIC B4X, S,   -, -
  MUSIC D5X, S,   -, M3
  MUSIC B4X, S,   -, -
  MUSIC G5X, S,   -, M2
  MUSIC B4X, S,   -, M3
  MUSIC D5X, S,   -, -
  MUSIC B4X, S,   -, M3

  ' ---- Bar 5 (D) ----
  MUSIC F4#X, D2Z, -, M1
  MUSIC A4X,  S,   -, -
  MUSIC D5X,  S,   -, -
  MUSIC A4X,  S,   -, M3
  MUSIC F4#5X,S,   -, M2
  MUSIC A4X,  S,   -, M3
  MUSIC D5X,  S,   -, -
  MUSIC A4X,  S,   -, M3
  MUSIC E5X,  S,   -, M1
  MUSIC A4X,  S,   -, -
  MUSIC D5X,  S,   -, M3
  MUSIC A4X,  S,   -, -
  MUSIC F4#5X,S,   -, M2
  MUSIC A4X,  S,   -, M3
  MUSIC D5X,  S,   -, -
  MUSIC A4X,  S,   -, M3

  ' ---- Bar 6 (D, variation) ----
  MUSIC F4#X, D2Z, -, M1
  MUSIC A4X,  S,   -, -
  MUSIC D5X,  S,   -, -
  MUSIC A4X,  S,   -, M3
  MUSIC C5X,  S,   -, M2
  MUSIC A4X,  S,   -, M3
  MUSIC D5X,  S,   -, -
  MUSIC A4X,  S,   -, M3
  MUSIC E5X,  S,   -, M1
  MUSIC A4X,  S,   -, -
  MUSIC D5X,  S,   -, M3
  MUSIC A4X,  S,   -, -
  MUSIC F4#5X,S,   -, M2
  MUSIC A4X,  S,   -, M3
  MUSIC D5X,  S,   -, -
  MUSIC A4X,  S,   -, M3

  ' ---- Bar 7 (Em, lift) ----
  MUSIC E4X, E2Z, -, M1
  MUSIC B4X, S,   -, -
  MUSIC F4#X,S,   -, -
  MUSIC B4X, S,   -, M3
  MUSIC E5X, S,   -, M2
  MUSIC B4X, S,   -, M3
  MUSIC G4X, S,   -, -
  MUSIC B4X, S,   -, M3
  MUSIC D5X, S,   -, M1
  MUSIC B4X, S,   -, -
  MUSIC G4X, S,   -, M3
  MUSIC B4X, S,   -, -
  MUSIC F4#5X,S,  -, M2
  MUSIC B4X,  S,  -, M3
  MUSIC E5X,  S,  -, -
  MUSIC B4X,  S,  -, M3

  ' ---- Bar 8 (Em, resolve) ----
  MUSIC E4X, E2Z, -, M1
  MUSIC B4X, S,   -, -
  MUSIC G4X, S,   -, -
  MUSIC B4X, S,   -, M3
  MUSIC E5X, S,   -, M2
  MUSIC B4X, S,   -, M3
  MUSIC F4#X,S,   -, -
  MUSIC B4X, S,   -, M3
  MUSIC D5X, S,   -, M1
  MUSIC B4X, S,   -, -
  MUSIC A4X, S,   -, M3
  MUSIC B4X, S,   -, -
  MUSIC G4X, S,   -, M2
  MUSIC F4#X,S,   -, M3
  MUSIC E4X, S,   -, -
  MUSIC -,   S,   -, M3

  MUSIC JUMP si_loop