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

' Additional sprite slots
CONST SPR_SHIP_ACCENT = 4       ' Ship accent sprite (stacked for 2-color effect)
CONST SPR_FLYER     = 5         ' Title screen flying alien

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
DIM FlyPathX(64)               ' Figure-8 X positions (64 points, indices 0-63)
DIM FlyPathY(64)               ' Figure-8 Y positions (64 points, indices 0-63)
DIM FlyColors(6)               ' Color cycle (6 entries, indices 0-5)
DIM WaveColors(4)               ' 4-color cycle for title screen wave effect
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
TitleJitter = 0                 ' Title screen jitter phase (0-7)
WavePhase   = 0                 ' Color wave phase for big alien (0-3)
ExplosionTimer = 0              ' Explosion display countdown (0 = no explosion)
#ExplosionPos  = 0              ' Explosion BACKTAB position (screen address)
ExplosionColor = 0              ' Explosion color (matches destroyed alien)
FlyX        = 0                 ' Flying sprite X position (from path table)
FlyY        = 0                 ' Flying sprite Y position (from path table)
FlyPhase    = 0                 ' Path position index (0-31)
FlySpeed    = 0                 ' Frame counter for path advance
FlyFrame    = 0                 ' Flying sprite animation frame
FlyColorIdx = 0                 ' Color cycle index (0-5)
FlyColorTimer = 0               ' Frame counter for color change
FlyColor    = 7                 ' Current sprite color

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

    ' Initialize row colors (0-7 only for MODE 1)
    ' Blue, Red, Tan, Green, Yellow - rainbow wave
    RowColors(0) = 1   ' Blue
    RowColors(1) = 2   ' Red
    RowColors(2) = 3   ' Tan
    RowColors(3) = 5   ' Green
    RowColors(4) = 6   ' Yellow

    ' Initialize wave colors for title screen big alien
    WaveColors(0) = COL_WHITE
    WaveColors(1) = COL_YELLOW
    WaveColors(2) = COL_GREEN
    WaveColors(3) = COL_BLUE

' ============================================
' TITLE SCREEN
' ============================================
TitleScreen:
    CLS
    GameState = 0
    TitleFrame = 0
    TitleMarchDir = 1      ' 1=right, 0=left
    TitleMarchCount = 0    ' Frame counter for march steps
    TitleGridCol = 4       ' BACKTAB column of grid left edge

    ' Display title text - row 1
    PRINT AT 22 COLOR COL_GREEN, "SPACE INTRUDERS"

    ' "PRESS FIRE" - bottom of screen (row 10)
    PRINT AT 205 COLOR COL_WHITE, "PRESS FIRE"
    WavePhase = 0          ' Color cycle index for PRESS FIRE
    TitleColor = 0         ' Frame counter for color change
    TitleJitter = 0        ' Bolt position (0-14 = char, 15-19 = gap between sweeps)
    TitleMarchX = 0        ' Bolt frame counter

    ' Draw 3x3 alien grid on BACKTAB (rows 5-7, starting at TitleGridCol)
    GOSUB DrawAlienGrid

    ' Initialize flying crab sprite (64-point figure-8 Lissajous path)
    ' X = 84 + 50*sin(θ), Y = 56 + 18*sin(2θ) — tighter Y to stay between text
    FlyPathX(0) = 84 : FlyPathX(1) = 89 : FlyPathX(2) = 94 : FlyPathX(3) = 99
    FlyPathX(4) = 103 : FlyPathX(5) = 108 : FlyPathX(6) = 112 : FlyPathX(7) = 116
    FlyPathX(8) = 119 : FlyPathX(9) = 123 : FlyPathX(10) = 126 : FlyPathX(11) = 128
    FlyPathX(12) = 130 : FlyPathX(13) = 132 : FlyPathX(14) = 133 : FlyPathX(15) = 134
    FlyPathX(16) = 134 : FlyPathX(17) = 134 : FlyPathX(18) = 133 : FlyPathX(19) = 132
    FlyPathX(20) = 130 : FlyPathX(21) = 128 : FlyPathX(22) = 126 : FlyPathX(23) = 123
    FlyPathX(24) = 119 : FlyPathX(25) = 116 : FlyPathX(26) = 112 : FlyPathX(27) = 108
    FlyPathX(28) = 103 : FlyPathX(29) = 99 : FlyPathX(30) = 94 : FlyPathX(31) = 89
    FlyPathX(32) = 84 : FlyPathX(33) = 79 : FlyPathX(34) = 74 : FlyPathX(35) = 69
    FlyPathX(36) = 65 : FlyPathX(37) = 60 : FlyPathX(38) = 56 : FlyPathX(39) = 52
    FlyPathX(40) = 49 : FlyPathX(41) = 45 : FlyPathX(42) = 42 : FlyPathX(43) = 40
    FlyPathX(44) = 38 : FlyPathX(45) = 36 : FlyPathX(46) = 35 : FlyPathX(47) = 34
    FlyPathX(48) = 34 : FlyPathX(49) = 34 : FlyPathX(50) = 35 : FlyPathX(51) = 36
    FlyPathX(52) = 38 : FlyPathX(53) = 40 : FlyPathX(54) = 42 : FlyPathX(55) = 45
    FlyPathX(56) = 49 : FlyPathX(57) = 52 : FlyPathX(58) = 56 : FlyPathX(59) = 60
    FlyPathX(60) = 65 : FlyPathX(61) = 69 : FlyPathX(62) = 74 : FlyPathX(63) = 79
    FlyPathY(0) = 56 : FlyPathY(1) = 60 : FlyPathY(2) = 63 : FlyPathY(3) = 66
    FlyPathY(4) = 69 : FlyPathY(5) = 71 : FlyPathY(6) = 73 : FlyPathY(7) = 74
    FlyPathY(8) = 74 : FlyPathY(9) = 74 : FlyPathY(10) = 73 : FlyPathY(11) = 71
    FlyPathY(12) = 69 : FlyPathY(13) = 66 : FlyPathY(14) = 63 : FlyPathY(15) = 60
    FlyPathY(16) = 56 : FlyPathY(17) = 52 : FlyPathY(18) = 49 : FlyPathY(19) = 46
    FlyPathY(20) = 43 : FlyPathY(21) = 41 : FlyPathY(22) = 39 : FlyPathY(23) = 38
    FlyPathY(24) = 38 : FlyPathY(25) = 38 : FlyPathY(26) = 39 : FlyPathY(27) = 41
    FlyPathY(28) = 43 : FlyPathY(29) = 46 : FlyPathY(30) = 49 : FlyPathY(31) = 52
    FlyPathY(32) = 56 : FlyPathY(33) = 60 : FlyPathY(34) = 63 : FlyPathY(35) = 66
    FlyPathY(36) = 69 : FlyPathY(37) = 71 : FlyPathY(38) = 73 : FlyPathY(39) = 74
    FlyPathY(40) = 74 : FlyPathY(41) = 74 : FlyPathY(42) = 73 : FlyPathY(43) = 71
    FlyPathY(44) = 69 : FlyPathY(45) = 66 : FlyPathY(46) = 63 : FlyPathY(47) = 60
    FlyPathY(48) = 56 : FlyPathY(49) = 52 : FlyPathY(50) = 49 : FlyPathY(51) = 46
    FlyPathY(52) = 43 : FlyPathY(53) = 41 : FlyPathY(54) = 39 : FlyPathY(55) = 38
    FlyPathY(56) = 38 : FlyPathY(57) = 38 : FlyPathY(58) = 39 : FlyPathY(59) = 41
    FlyPathY(60) = 43 : FlyPathY(61) = 46 : FlyPathY(62) = 49 : FlyPathY(63) = 52
    ' Color cycle: White → Yellow → Green → Blue → Green → Yellow
    FlyColors(0) = 7 : FlyColors(1) = 6 : FlyColors(2) = 5
    FlyColors(3) = 3 : FlyColors(4) = 5 : FlyColors(5) = 6
    FlyPhase = 0
    FlySpeed = 0
    FlyFrame = 0
    FlyColorIdx = 0
    FlyColorTimer = 0
    FlyColor = 7

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

    ' --- Flying crab sprite (figure-8 path) ---
    ' Advance path position every 3 frames (64 pts × 3 = ~3.2 sec loop)
    FlySpeed = FlySpeed + 1
    IF FlySpeed >= 3 THEN
        FlySpeed = 0
        FlyPhase = FlyPhase + 1
        IF FlyPhase >= 64 THEN FlyPhase = 0
    END IF

    ' Read current position from path arrays
    FlyX = FlyPathX(FlyPhase)
    FlyY = FlyPathY(FlyPhase)

    ' Gradual color shift every 32 frames
    FlyColorTimer = FlyColorTimer + 1
    IF FlyColorTimer >= 32 THEN
        FlyColorTimer = 0
        FlyColorIdx = FlyColorIdx + 1
        IF FlyColorIdx >= 6 THEN FlyColorIdx = 0
        FlyColor = FlyColors(FlyColorIdx)
    END IF

    ' Draw flying crab (swap animation frame every 16 frames)
    FlyFrame = FlyFrame + 1
    IF FlyFrame >= 16 THEN FlyFrame = 0
    IF FlyFrame < 8 THEN
        SPRITE SPR_FLYER, FlyX + SPR_VISIBLE, FlyY, GRAM_CRAB_F1 * 8 + FlyColor + $0800
    ELSE
        SPRITE SPR_FLYER, FlyX + SPR_VISIBLE, FlyY, GRAM_CRAB_F2 * 8 + FlyColor + $0800
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
        ' Restore current bolt position to green (if visible)
        IF TitleJitter < 15 THEN
            #Card = PEEK($216 + TitleJitter)
            PRINT AT 22 + TitleJitter, (#Card AND $EFF8) OR $0005
        END IF
        ' Advance bolt position
        TitleJitter = TitleJitter + 1
        IF TitleJitter >= 20 THEN TitleJitter = 0
        ' Set new bolt position to white (if visible)
        IF TitleJitter < 15 THEN
            #Card = PEEK($216 + TitleJitter)
            PRINT AT 22 + TitleJitter, (#Card AND $EFF8) OR $0007
        END IF
    END IF

    ' "PRESS FIRE" color pulse - cycle every 40 frames
    TitleColor = TitleColor + 1
    IF TitleColor >= 40 THEN
        TitleColor = 0
        WavePhase = WavePhase + 1
        IF WavePhase >= 4 THEN WavePhase = 0
        PRINT AT 205 COLOR WaveColors(WavePhase), "PRESS FIRE"
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

            ' Check wide horizontal range - expanded for better hit detection
            ' Bullet visible pixels are at BulletX+3 and BulletX+4
            ' Check columns from BulletX-1 to BulletX+7 to catch edge cases

            ' Check left of bullet (catches left edge of aliens)
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