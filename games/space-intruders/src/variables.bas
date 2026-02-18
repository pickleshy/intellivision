' ============================================
' SPACE INTRUDERS - Variables Module
' ============================================
' All game state variable declarations
' No segment placement (declarations are global)

' === Variable Declarations ===

' ============================================================
' VARIABLES
' ============================================================

' -- Arrays --
DIM #AlienRow(ALIEN_ROWS)       ' Bitmask of alive aliens per row (11 bits, needs 16-bit)
DIM FlyColors(6)               ' Saucer color cycle (6 entries, indices 0-5)
DIM WaveColors(4)               ' 4-color cycle for title screen wave effect
' StarPos/StarType arrays REMOVED - replaced with hybrid static+animated (saves 32 slots!)

' -- Core State --
#GameFlags  = 0                 ' Bit-packed booleans (see FLAG_* constants)
#Score      = 0                 ' Player score (lower 16 bits of 32-bit score)
#ScoreHigh  = 0                 ' Player score (upper 16 bits, max 4.29 billion total)
#HighScore  = 0                 ' Session high score (lower 16 bits, persists until ROM reset)
#HighScoreHigh = 0              ' Session high score (upper 16 bits)
#NextLife   = 1000              ' Score threshold for next extra life
Level       = 1                 ' Current wave/level
Lives       = STARTING_LIVES    ' Player lives remaining
GameOver    = 0                 ' 0=playing, 3-6=game over phases

' -- Player & Input --
PlayerX     = 80                ' Player X position (center)
DeathTimer  = 0                 ' Countdown during death animation
Invincible  = 0                 ' Invincibility timer after respawn
Key1Held    = 0                 ' Debounce flag for keypad 1
CheatCode   = 0                 ' Packed cheat entry: bits 0-2=held timer, bit 3=got '3'
ShakeTimer  = 0                 ' Screen shake countdown (0 = no shake)

' -- Bullet State --
BulletX     = 0                 ' Bullet X position
BulletY     = 0                 ' Bullet Y position
BulletColor = 0                 ' Bullet color phase (0-2 for color cycling)
BeamHits    = 0                 ' Beam pierce budget (2 = fresh shot, 0 = spent)
BeamTimer   = 0                 ' Wide beam countdown (300 frames = 5 sec, 0 = normal)
ABulletX    = 0                 ' Alien bullet X position
ABulletY    = 0                 ' Alien bullet Y position
ABulFrame   = 0                 ' Bit 0: anim frame (0/1), Bit 1: type (0=zigzag, 2=beam)
ShootTimer  = 0                 ' Countdown to next alien shot
ShootCol    = 0                 ' Column to shoot from

' -- Alien Grid & March --
AnimFrame   = 0                 ' Animation frame (0 or 1)
ShimmerCount = 0                ' Frame counter for shimmer updates
SubstepState = 0                ' Packed: ShiftPos (bits 0-1) + DefineStep*4 (bits 2-3)
AlienOffsetX = 0                ' Alien grid X offset (0 to ALIEN_MAX_X)
AlienOffsetY = 0                ' Alien grid Y offset (drops down)
LastClearedY = 0                ' Last AlienOffsetY that had rows cleared above it
AlienDir    = 1                 ' Movement direction (1=right, 255=left using unsigned)
MarchCount  = 0                 ' Frame counter for march timing
CurrentMarchSpeed = 160         ' Current march speed (decreases per wave)
BaseMarchSpeed = 60             ' March speed at start of wave (before descent accel)
MusicGear   = 0                 ' Current music gear (0=slow,1=mid,2=fast,3=panic)
#AliensAlive = 0                ' Count of remaining aliens
WaveRevealCol = ALIEN_COLS - 1  ' Column reveal counter (starts fully revealed)
WaveRevealRow = ALIEN_ROWS - 1  ' Row reveal: top-down=rows revealed, fly-down=rows hidden above
RightRevealCol = ALIEN_COLS - 1 ' Right-side reveal col (counts down in dual mode)

' -- Collision & Drawing Temps --
HitCol      = 0                 ' Multi-use: collision col, beam col, BACKTAB col, boss color, skip flag, wingman X
HitRow      = 0                 ' Multi-use: collision row, alive-row sentinel, leftmost-col sentinel, orbit temp
NeedRedraw  = 0                 ' DrawAliens dirty flag / reveal-complete gate
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
WavePhase   = 0                 ' Color wave phase for big alien (0-3)

' -- Explosion & Chain Combo --
ExplosionTimer = 0              ' Explosion display countdown (0 = no explosion)
#ExplosionPos  = 0              ' Explosion BACKTAB position (screen address)
ChainCount  = 0                 ' Consecutive successful shots (chain combo)
ChainMax    = 0                 ' Best chain this game
ChainTimeout = 0                ' Frames until chain goes cold (90 = 1.5 sec)
ChainTimer  = 0                 ' Chain reaction laser SFX countdown (0 = inactive)
#ChainFreq1 = 0                ' Chain SFX channel A frequency (mid crunch)
#ChainFreq2 = 0                ' Chain SFX channel C frequency (sub rumble)
ChainVol   = 0                 ' Chain SFX shared volume (0-15, converted from 16-bit to free slot)
BombExpTimer = 0                ' Chain explosion countdown (0=inactive, 20=active)
BombExpRow   = 0                ' Grid row of exploded bomb
BombExpCol   = 0                ' Left grid column of exploded bomb

' -- Boss System --
DIM BossCol(MAX_BOSSES)            ' Left column of each boss (0-7)
DIM BossRow(MAX_BOSSES)            ' Grid row of each boss (0-4)
DIM BossHP(MAX_BOSSES)             ' HP per boss (0=dead/unused, 1-3=alive)
DIM BossColor(MAX_BOSSES)          ' Display color per boss
DIM BossType(MAX_BOSSES)           ' 0=skull (multi-hit), 1=bomb (chain explosion)
BossCount      = 0                 ' Number of boss slots in use (0-4)
FoundBoss      = 0                 ' Temp: result of boss lookup (0-3 or 255=none)
RowBoss1       = 255               ' Cached: 1st boss index on current row (255=none)
RowBoss2       = 255               ' Cached: 2nd boss index on current row (255=none)
DIM BossBeamHit(MAX_BOSSES)        ' Beam damage tracker per boss (reset each beam activation)
OrbitStep      = 255               ' Orbiter path index (0-9 = active, 255 = inactive)
OrbitStep2     = 255               ' Second orbiter path index (boss slot 1)
WaveColor0     = 6                 ' Squid color (row 0) — default yellow
WaveColor1     = 1                 ' Crab color (row 1) — default blue
WaveColor2     = 5                 ' Octopus color (row 2) — default green
WaveColor3     = 2                 ' Beetle color (row 3) — default red
WaveColor4     = 7                 ' Jellyfish color (row 4) — default white

' -- Saucer & Flight Engine --
FlyX        = 0                 ' Flying sprite X position (from path table)
FlyY        = 0                 ' Flying sprite Y position (from path table)
#FlyPhase    = 0                 ' Path position index (16-bit for >255 waypoints)
FlySpeed    = 0                 ' Frame counter for path advance
FlyFrame    = 0                 ' Flying sprite animation frame
FlyColorIdx = 0                 ' Color cycle index (0-5)
FlyColorTimer = 0               ' Frame counter for color change
FlyColor    = 7                 ' Current sprite color
FlyState    = 0                 ' 0=enter, 1=looping, 2=exit, 3=offscreen pause
FlyCenterX  = 0                 ' Saucer swirl circle center X
FlyCenterY  = 0                 ' Saucer swirl circle center Y
#FlyLoopCount = 0                ' Number of completed figure-8 loops
#FlyPathLen  = 0                 ' Current pattern waypoint count
FlyTransSpd = 0                 ' Pixels per frame during transition (also encodes pattern: 1=figure8, 2=diamond)
#PathXAddr  = 0                 ' ROM address of FlyPathXData (set at title init)
#PathYAddr  = 0                 ' ROM address of FlyPathYData (set at title init)

' -- Rogue Alien --
RogueState     = 0                 ' 0=idle, 1=shake, 2=dive
RogueTimer     = 0                 ' Cooldown / countdown timer
RogueRow       = 0                 ' Grid row (0-4)
RogueCol       = 0                 ' Grid column (0 or 8)
RogueX         = 0                 ' Sprite X (pixels)
RogueY         = 0                 ' Sprite Y (pixels)
RogueCard      = 0                 ' GRAM card for alien type
RogueColor     = 0                 ' Color for alien type
RogueDivePhase = 0                 ' Circle step index (0-31) or 255=exit
RogueCenterX   = 0                 ' Circle center X during dive
RogueCenterY   = 0                 ' Circle center Y during dive

' -- Capture Wingman --
CaptureColor   = 0                 ' Color of captured alien type
CaptureStep    = 0                 ' Orbit step index (0-15, 16-step circle)
CaptureTimer   = 0                 ' Countdown to next hitscan shot
CapBulletCol   = 0                 ' BACKTAB column of wingman bullet
CapBulletRow   = 0                 ' Current BACKTAB row (counts down toward aliens)

' -- Power-Up System --
' These vars double as title-screen animation state (see [title:] comments at init sites)
PowerUpState = 0                ' 0=none, 1=falling, 2=landed / [title: anim frame counter]
PowerUpType  = 0                ' 0=beam, 1=rapid, 2=bomb, 3=mega, 4=shield / [title: shimmer counter]
PowerUpX     = 1                ' Capsule X position / [title: march direction 1=right, 0=left]
CapsuleFrame = 0                ' Capsule animation frame 0-7 / [title: slide-in position]
CapsuleColor1 = 0               ' Capsule primary color / [title: march step counter]
CapsuleColor2 = 0               ' Capsule secondary color / [title: grid left-edge column]
FireCooldown = 0                ' Frames until next shot allowed / [title: bolt sweep position]
PowerUpY    = 0                 ' Power-up capsule Y position (separate from saucer FlyY)
#PowerTimer = 0                 ' Landing timeout (counts down from 300)
RapidTimer  = 0                 ' Rapid fire countdown (300 frames = 5 sec, 0 = normal)
MegaTimer  = 0                  ' Mega beam countdown (120 frames = 2 sec, 0 = normal, converted to 8-bit)
MegaBeamCol = 0                 ' BACKTAB column of active beam (0-19)
MegaBeamTimer = 0               ' Beam display countdown (0 = inactive)
ShieldHits  = 0                 ' Shield charges (0=none, 1=damaged, 2=full)
TutorialTimer  = 0              ' First powerup hint: 255=ready, 1-180=showing, 0=done

' -- Sound Effects --
SfxVolume   = 0                 ' Current decay volume (0 = silent)
SfxType     = 0                 ' 0=none, 1=alien, 2=saucer, 3=death, 4=mega, 5=bomb, 6=parry, 7=shoot, 8=(free)
#SfxPitch   = 0                 ' Current tone period (16-bit for pitch values >255)

' -- Starfield & Parallax --
StarTimer   = 0                 ' Frame counter: title star anim (5 frames) / gameplay silhouette scroll (10 frames)
SilhOffset  = 0                 ' Silhouette scroll position (0 to SILH_MAP_LEN-1)

' -- Title Screen & Game Over --
TitleMarchX = 0                 ' Title screen alien X offset / bolt frame counter
TitleAnimState = 0              ' 0=reveal, 1=normal, 2=vanish, 3=done
RevealCol   = 0                 ' Current letter revealing (0-14)
VanishCol   = 255               ' Current letter vanishing (255=not started)
GOAnimIdx    = 255               ' Game over: animating letter (255=none, 0-7=letter)
GOAnimFrame  = 0                 ' Game over: animation frame (0=full, 1=60°, 2=edge, 3=done)
ScorePairM   = 0                 ' Cached million+hundred-thousands pair from ScoreCard=4 computation

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
    DEFINE GRAM_ALIEN4, 2, Alien4Gfx      ' Cards 19-20 (reuses title crab slots)
    WAIT
    DEFINE GRAM_ALIEN5, 2, Alien5Gfx      ' Cards 30-31 (reuses title font slots)
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
    DEFINE GRAM_WINGMAN_F1, 1, WingmanF1Gfx
    WAIT
    DEFINE GRAM_WINGMAN_F2, 1, WingmanF2Gfx
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
    DEFINE GRAM_SAUCER, 1, SaucerGfx      ' Single frame, animation via color shift
    WAIT
    ' Cards 42-44: Freed for alien substep shift-2
    DEFINE GRAM_BEAM, 1, BeamGfx
    WAIT
    DEFINE GRAM_CAP_F1, 4, CapsuleF1Gfx
    WAIT
    DEFINE GRAM_SHIP_HUD, 1, ShipHudGfx
    WAIT
    DEFINE GRAM_MEGA_BEAM, 1, MegaBeamGfx
    WAIT
    DEFINE GRAM_ZIGZAG1, 1, ZigzagF1Gfx
    WAIT
    DEFINE GRAM_BOMB1, 1, SquidLeftF1Gfx
    WAIT
    DEFINE GRAM_BOMB2, 1, SquidRightF1Gfx
    WAIT
    DEFINE GRAM_BOMB1_F1, 1, SquidLeftF2Gfx
    WAIT
    DEFINE GRAM_BOMB2_F1, 1, SquidRightF2Gfx
    WAIT
    DEFINE GRAM_CHAIN_CH, 1, ChainCHGfx
    WAIT
    DEFINE GRAM_CHAIN_AI, 1, ChainAIGfx
    WAIT
    DEFINE GRAM_CHAIN_N, 1, ChainNGfx
    WAIT
    DEFINE GRAM_SCORE_SC, 1, ScoreSCGfx
    WAIT
    DEFINE GRAM_SCORE_OR, 1, ScoreORGfx
    WAIT
    DEFINE GRAM_SCORE_E, 1, ScoreEGfx
    WAIT

    ' Initialize wave colors for PRESS FIRE shimmer (GRAM font, supports colors 8+)
    ' Grey/White flash
    WaveColors(0) = COL_WHITE
    WaveColors(1) = COL_WHITE
    WaveColors(2) = 0              ' Grey (color 8 encoded as $1800 base)
    WaveColors(3) = 0              ' Grey

    ' Note: Intellivoice initialization moved to lib_init.bas

    ' Boot splash: show developer URL for ~1 second
