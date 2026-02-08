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
CONST PLAYER_MAX_X  = 160       ' Right boundary (sprite X=160 → screen pixels 152-159)
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

' Parallax silhouette (GAMEPLAY ONLY — reuses spark slots 21-24)
CONST GRAM_SILH_1Q   = 21      ' Silhouette: bottom 2px fill
CONST GRAM_SILH_HALF = 22      ' Silhouette: bottom 4px fill
CONST GRAM_SILH_3Q   = 23      ' Silhouette: bottom 6px fill
CONST GRAM_SILH_FULL = 24      ' Silhouette: all 8px fill
CONST SILH_MAP_LEN   = 40      ' Silhouette height map column count

' Custom title font (TITLE SCREEN ONLY - redefined at StartGame for gameplay HUD)
CONST GRAM_FONT_S = 25          ' Reused as GRAM_HUD_1 during gameplay
CONST GRAM_FONT_P = 26          ' Reused as GRAM_HUD_2 during gameplay
CONST GRAM_FONT_A = 27          ' Reused as GRAM_HUD_3 during gameplay
CONST GRAM_FONT_C = 28          ' Reused as GRAM_HUD_4 during gameplay
CONST GRAM_FONT_E = 29          ' Reused as GRAM_HUD_5 during gameplay
CONST GRAM_FONT_I = 30          ' Reused as GRAM_HUD_6 during gameplay
CONST GRAM_FONT_N = 31          ' Reused as GRAM_HUD_7 during gameplay
CONST GRAM_FONT_T = 32          ' Reused as GRAM_HUD_8 during gameplay
CONST GRAM_FONT_R = 33          ' Reused as GRAM_HUD_9 during gameplay
CONST GRAM_FONT_U = 34          ' Reused as GRAM_HUD_10 during gameplay
CONST GRAM_FONT_D = 35          ' Reused as GRAM_HUD_11 during gameplay
CONST GRAM_FONT_F = 36          ' Reused as GRAM_HUD_12 during gameplay
CONST GRAM_FONT_G = 37          ' Game over screen only
CONST GRAM_FONT_M = 38          ' Game over screen only
CONST GRAM_FONT_O = 40          ' Game over screen only (skip 39=saucer)
CONST GRAM_FONT_V = 41          ' Game over screen only

' Gameplay HUD slots (reuse title font cards 25-36 after title screen)
' Powerup HUD indicator GRAM slots (reuse title font cards 25-32)
CONST GRAM_PWR_BE = 25          ' BEAM tile 1: "BE"
CONST GRAM_PWR_AM = 26          ' BEAM tile 2: "AM"
CONST GRAM_PWR_RP = 27          ' RAPID tile 1: "RP"
CONST GRAM_PWR_ID = 28          ' RAPID tile 2: "ID"
CONST GRAM_PWR_QU = 29          ' QUAD tile 1: "QU"
CONST GRAM_PWR_AD = 30          ' QUAD tile 2: "AD"
CONST GRAM_PWR_ME = 31          ' MEGA tile 1: "ME"
CONST GRAM_PWR_GA = 32          ' MEGA tile 2: "GA"
' Shield and remaining HUD slots (title font cards 33-36)
CONST GRAM_SHIELD = 33          ' Shield arc above player ship
CONST GRAM_WARP1  = 34          ' Warp-in frame 1: single pixel (arriving)
CONST GRAM_WARP2  = 35          ' Warp-in frame 2: forming cluster
CONST GRAM_WARP3  = 36          ' Warp-in frame 3: coalescing shape
CONST GRAM_STAR1  = 37        ' Star dot (upper-left pixel)
CONST GRAM_STAR2  = 38        ' Star dot (lower-right pixel)
CONST GRAM_SAUCER = 39         ' Flying saucer (bonus target)
CONST GRAM_BEAM   = 40         ' Wide beam shot (full 8px width)
CONST GRAM_POWERUP = 41        ' Power-up capsule graphic
CONST GRAM_SAUCER_F2 = 42      ' Saucer frame 2 (left window lit)
CONST GRAM_SAUCER_F3 = 43      ' Saucer frame 3 (middle window lit)
CONST GRAM_SAUCER_F4 = 44      ' Saucer frame 4 (right window + engine glow)
CONST GRAM_SHIP_HUD = 45       ' Compact ship icon for HUD lives display
CONST GRAM_MEGA_BEAM = 46      ' Solid block for mega beam column
CONST GRAM_QUAD    = 47         ' Quad laser (4 thin vertical lines)
CONST GRAM_CAP_F1  = 48         ' Capsule animation frame 1
CONST GRAM_CAP_F2  = 49         ' Capsule animation frame 2
CONST GRAM_CAP_F3  = 50         ' Capsule animation frame 3
CONST GRAM_CAP_F4  = 51         ' Capsule animation frame 4
CONST GRAM_ZIGZAG1 = 52         ' Zigzag bolt frame 1
CONST GRAM_ZIGZAG2 = 53         ' Zigzag bolt frame 2
CONST GRAM_BOMB1    = 54        ' Bomb alien left half frame 1
CONST GRAM_BOMB2    = 55        ' Bomb alien right half frame 1
CONST GRAM_BOMB1_F1 = 56        ' Bomb alien left half frame 2
CONST GRAM_BOMB2_F1 = 57        ' Bomb alien right half frame 2
CONST GRAM_CHAIN_CH = 58        ' Compact "CH" for chain display
CONST GRAM_CHAIN_AI = 59        ' Compact "AI" for chain display
CONST GRAM_CHAIN_N  = 60        ' Compact "N" for chain display
CONST GRAM_SCORE_SC = 61        ' Compact "SC" for score label
CONST GRAM_SCORE_OR = 62        ' Compact "OR" for score label
CONST GRAM_SCORE_E  = 63        ' Compact "E" for score label

' Wingman sprite (Mooninite-style) - uses free slots 13 and 18
CONST GRAM_WINGMAN_F1 = 13      ' Wingman frame 1 (legs together)
CONST GRAM_WINGMAN_F2 = 18      ' Wingman frame 2 (legs apart)

' Animated title font GRAM card bases (TITLE SCREEN ONLY)
' Animated font: 3 frames per letter (full, 60°, edge), 33 cards total
' Uses gameplay-only cards during title, reloaded at StartGame
' Avoids reserved: 9-12 (band), 19-24 (crab/sparks), 25-36 (GRAM_FONT), 37-38 (stars)
CONST TGRAM_S = 0               ' Cards 0-2 (full, 60°, edge)
CONST TGRAM_P = 3               ' Cards 3-5
CONST TGRAM_A = 6               ' Cards 6-8
CONST TGRAM_C = 13              ' Cards 13-15 (skip 9-12 band)
CONST TGRAM_E = 16              ' Cards 16-18
CONST TGRAM_I = 39              ' Cards 39-41 (skip 19-38)
CONST TGRAM_N = 42              ' Cards 42-44
CONST TGRAM_T = 45              ' Cards 45-47
CONST TGRAM_R = 48              ' Cards 48-50
CONST TGRAM_U = 51              ' Cards 51-53
CONST TGRAM_D = 54              ' Cards 54-56
' Game Over animated letters (reuse title slots during game over)
CONST TGRAM_G = 0               ' Cards 0-2 (reuse TGRAM_S slot)
CONST TGRAM_M = 3               ' Cards 3-5 (reuse TGRAM_P slot)
CONST TGRAM_O = 51              ' Cards 51-53 (reuse TGRAM_U slot)
CONST TGRAM_V = 54              ' Cards 54-56 (reuse TGRAM_D slot)

' Speech bubble GRAM cards (reuse title font slots 25-26 during gameplay)
CONST GRAM_BYE1     = 25        ' "bye!" left half (b + y)
CONST GRAM_BYE2     = 26        ' "bye!" right half (e + !)

' Large alien (2x2 BACKTAB cards = 16x16 pixels)
' TL/TR use title-only crab slots (free during gameplay)
' BL/BR use warp-in slots (warp-in only used in Pattern A, large alien only in Pattern B)
CONST GRAM_LARGE_TL = 19       ' Top-left quadrant (reuse crab F1)
CONST GRAM_LARGE_TR = 20       ' Top-right quadrant (reuse crab F2)
CONST GRAM_LARGE_BL = 34       ' Bottom-left quadrant (reuse warp-in F1)
CONST GRAM_LARGE_BR = 35       ' Bottom-right quadrant (reuse warp-in F2)

' Additional sprite slots
CONST SPR_SHIP_ACCENT = 4       ' Ship accent sprite (stacked for 2-color effect)
CONST SPR_FLYER     = 5         ' Title screen flying alien
CONST SPR_SAUCER    = 6         ' Gameplay flying saucer
CONST SPR_POWERUP   = 7         ' Power-up drop/pickup sprite

' Alien grid constants
CONST ALIEN_COLS    = 9         ' 9 aliens per row
CONST ALIEN_ROWS    = 5         ' 5 rows of aliens
CONST ALIEN_START_X = 0         ' Starting column on screen (leftmost)
CONST ALIEN_START_Y = 1         ' Starting row on screen
CONST ALIEN_MAX_X   = 11        ' Maximum X offset before reversing (20 - 9)
CONST MARCH_SPEED_START = 60   ' Starting frames between march steps
CONST MARCH_SPEED_MIN = 24      ' Fastest march speed (minimum frames) - balanced

' Bullet constants
CONST BULLET_SPEED  = 2         ' Player bullet speed (pixels per frame)
CONST BULLET_TOP    = 8         ' Top of screen
CONST ALIEN_BULLET_SPEED = 2    ' Alien bullet speed (pixels per frame) - doubled for challenge
CONST ALIEN_SHOOT_RATE = 40     ' Frames between alien shots (~1.5/sec)
CONST RAPID_SPEED    = 4        ' Rapid fire bullet speed (4px/frame)
CONST RAPID_COOLDOWN = 3        ' Frames between rapid fire shots

' Colors
CONST COL_WHITE     = 7
CONST COL_BLUE      = 1
CONST COL_GREEN     = 5
CONST COL_YELLOW    = 6
CONST COL_BLACK     = 0
CONST COL_RED       = 2
CONST COL_TAN       = 3
CONST COL_CYAN      = 9
CONST COL_ORANGE    = 10
CONST COL_PINK      = 12
CONST COL_LTBLUE    = 13
CONST COL_PURPLE    = 15

' Flight engine states
CONST FLT_IDLE       = 0          ' Engine inactive
CONST FLT_TRANSITION = 1          ' Moving toward first waypoint
CONST FLT_FOLLOWING  = 2          ' Following pattern path
CONST FLT_DONE       = 3          ' Completed all loops

' Flight pattern IDs
CONST PAT_FIGURE8    = 0          ' Title screen figure-8
CONST PAT_DIAMOND    = 1          ' Game over diamond orbit

' Angry saucer chase
CONST SAUCER_CHASE   = 3          ' Saucer state: pursuing player
CONST SAUCER_ESCAPE  = 4          ' Saucer state: flying off after chase
CONST SAUCER_SWIRL   = 5          ' Saucer state: circular swirl before chase
CONST CHASE_CHANCE   = 2000       ' 1/N per movement tick (~8% per pass)
CONST CHASE_SPEED_X  = 2          ' Horizontal tracking speed (px per frame)
CONST CHASE_DRIFT_Y  = 4          ' Descend 1px every N frames (slow drift down)
CONST CHASE_FIRE_RATE = 45        ' Frames between saucer shots (~1.3 per second)

' Rogue alien constants
CONST ROGUE_IDLE       = 0
CONST ROGUE_SHAKE      = 1
CONST ROGUE_DIVE       = 2
CONST ROGUE_COOLDOWN   = 120      ' ~2 sec between trigger checks
CONST ROGUE_SHAKE_TIME = 30       ' 0.5 sec shake telegraph
CONST ROGUE_CHANCE     = 6        ' 1-in-6 per check

' Capture wingman constants
CONST CAPTURE_FIRE_RATE = 90      ' Frames between allied hitscan shots (~1.5 sec)
CONST CAPTURE_ORBIT_R   = 6      ' Orbit radius (pixels)

' Boss alien constants
CONST BOSS_HP_MAX  = 3          ' Hits to destroy boss
CONST BOSS_SCORE   = 100        ' Bonus score on boss kill
CONST BOMB_SCORE   = 50         ' Score for bomb alien itself
CONST MAX_BOSSES   = 4          ' Maximum simultaneous special aliens
CONST SKULL_TYPE   = 0          ' BossType: multi-hit skull boss
CONST BOMB_TYPE    = 1          ' BossType: single-hit bomb alien (chain explodes)
CONST LARGE_TYPE   = 2          ' BossType: 2x2 large alien (Phase B)

' Game constants
CONST STARTING_LIVES = 4          ' 4 ships total (current + 3 extras)

' Sprite flags (standard IntyBASIC values)
CONST SPR_VISIBLE   = $0200     ' Make sprite visible
CONST SPR_HIT       = $0100     ' Enable collision detection

' Bit-packed game flags (saves 9 8-bit variable slots using 1 16-bit slot)
' Usage: Set=#GameFlags OR flag, Clear=#GameFlags AND ($FFFF XOR flag), Test=#GameFlags AND flag
CONST FLAG_BULLET    = 1        ' Bit 0: BulletActive
CONST FLAG_ABULLET   = 2        ' Bit 1: ABulletActive
CONST FLAG_CAPTURE   = 4        ' Bit 2: CaptureActive
CONST FLAG_CAPBULLET = 8        ' Bit 3: CapBulletActive
CONST FLAG_PLAYERHIT = 16       ' Bit 4: PlayerHit
CONST FLAG_SHOTLAND  = 32       ' Bit 5: ShotLanded
CONST FLAG_AUTOFIRE  = 64       ' Bit 6: AutoFire
CONST FLAG_DEBUG     = 128      ' Bit 7: DebugMode
CONST FLAG_REVEAL    = 256      ' Bit 8: RevealMode (pincer)
CONST FLAG_ANGRY     = 512      ' Bit 9: FlyAngry
CONST FLAG_TOPDOWN   = 1024     ' Bit 10: TopDown reveal mode (rows appear in place)
CONST FLAG_FLYDOWN   = 2048     ' Bit 11: FlyDown mode (aliens descend from above)
CONST FLAG_KEY0HELD  = 4096     ' Bit 12: Key0 debounce (wingman toggle)
CONST FLAG_DUAL      = 8192     ' Bit 13: Quad laser active
CONST FLAG_SUBWAVE   = 16384    ' Bit 14: SubWave (1=Pattern B formation)
CONST FLAG_HASLARGE  = 32768    ' Bit 15: HasLargeAlien (gates LARGE_TYPE checks in hot paths)

' --------------------------------------------
' Variables
' --------------------------------------------
DIM #AlienRow(ALIEN_ROWS)       ' Bitmask of alive aliens per row (11 bits, needs 16-bit)
' FlyPathX/Y moved to ROM DATA tables (see Segment 1) to save 128 8-bit vars
DIM FlyColors(6)               ' Color cycle (6 entries, indices 0-5)
DIM WaveColors(4)               ' 4-color cycle for title screen wave effect
#GameFlags  = 0                 ' Bit-packed booleans (see FLAG_* constants)
PlayerX     = 80                ' Player X position (center)
AnimFrame   = 0                 ' Animation frame (0 or 1)
ShimmerCount = 0                ' Frame counter for shimmer updates
AlienOffsetX = 0                ' Alien grid X offset (0 to ALIEN_MAX_X)
AlienOffsetY = 0                ' Alien grid Y offset (drops down)
LastClearedY = 0                ' Last AlienOffsetY that had rows cleared above it
AlienDir    = 1                 ' Movement direction (1=right, 255=left using unsigned)
MarchCount  = 0                 ' Frame counter for march timing
BulletX     = 0                 ' Bullet X position
BulletY     = 0                 ' Bullet Y position
' BulletActive packed into #GameFlags (FLAG_BULLET)
BulletColor = 0                 ' Bullet color phase (0-2 for color cycling)
' AlienColor eliminated — uses AlienColor as temp in DrawBullet/MegaBeam
ABulletX    = 0                 ' Alien bullet X position
ABulletY    = 0                 ' Alien bullet Y position
' ABulletActive packed into #GameFlags (FLAG_ABULLET)
ABulFrame   = 0                 ' Bit 0: anim frame (0/1), Bit 1: type (0=zigzag, 2=beam)
ShootTimer  = 0                 ' Countdown to next alien shot
ShootCol    = 0                 ' Column to shoot from
#Score      = 0                 ' Player score
' PlayerHit packed into #GameFlags (FLAG_PLAYERHIT)
DeathTimer  = 0                 ' Countdown during death animation
Invincible  = 0                 ' Invincibility timer after respawn
Lives       = STARTING_LIVES    ' Player lives remaining
Level       = 1                 ' Current wave/level
GameOver    = 0                 ' 1 = game over state
CurrentMarchSpeed = 160         ' Current march speed (decreases per wave)
MusicGear   = 0                 ' Current music gear (0=slow,1=mid,2=fast,3=panic)
BaseMarchSpeed = 60             ' March speed at start of wave (before descent accel)
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
#ScreenPos  = 0                 ' Screen position (16-bit for multiplication)
#Mask       = 0                 ' Bitmask for checking alive aliens
#Card       = 0                 ' Card value for PRINT
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
#FlyPhase    = 0                 ' Path position index (16-bit for >255 waypoints)
FlySpeed    = 0                 ' Frame counter for path advance
FlyFrame    = 0                 ' Flying sprite animation frame
FlyColorIdx = 0                 ' Color cycle index (0-5)
FlyColorTimer = 0               ' Frame counter for color change
FlyColor    = 7                 ' Current sprite color
SaucerCard  = GRAM_SAUCER       ' Current saucer GRAM card (animation frame)
FlyState    = 0                 ' 0=enter, 1=looping, 2=exit, 3=offscreen pause
' FlyAngry packed into #GameFlags (FLAG_ANGRY)
FlyCenterX  = 0                 ' Saucer swirl circle center X
FlyCenterY  = 0                 ' Saucer swirl circle center Y
#FlyLoopCount = 0                ' Number of completed figure-8 loops
SlidePos    = 0                 ' PRESS/FIRE slide-in position (0-5 sliding, 6+ = done)
' Title animation state (Y-axis rotation cascade)
' Uses dynamic frame calculation instead of array (saves 15 8-bit vars)
TitleAnimState = 0              ' 0=reveal, 1=normal, 2=vanish, 3=done
RevealCol   = 0                 ' Current letter revealing (0-14)
VanishCol   = 255               ' Current letter vanishing (255=not started)
' Starfield variables
DIM StarPos(16)                 ' Star BACKTAB positions (16 stars, max 239 fits 8-bit)
DIM StarType(16)                ' Star type: 0=slow/dim, 1=fast/bright
StarCount   = 0                 ' Number of active stars
StarTimer   = 0                 ' Frame counter for scroll updates
StarTick    = 0                 ' Tick counter (for slow layer)
SilhOffset  = 0                 ' Silhouette scroll position (0 to SILH_MAP_LEN-1)
BeamHits   = 0                 ' Beam pierce budget (2 = fresh shot, 0 = spent)
BeamTimer  = 0                 ' Wide beam countdown (300 frames = 5 sec, 0 = normal)
ChainTimer = 0                 ' Chain reaction laser SFX countdown (0 = inactive)
#ChainFreq1 = 0                ' Chain SFX channel A frequency (mid crunch)
#ChainFreq2 = 0                ' Chain SFX channel C frequency (sub rumble)
#ChainVol  = 0                 ' Chain SFX shared volume
' Power-up drop variables (reuse title-screen vars during gameplay)
' TitleFrame reuses TitleFrame (title-only)
' TitleMarchDir reuses TitleMarchDir (title-only)
' SlidePos reuses SlidePos (title-only)
PowerUpY    = 0                 ' Power-up capsule Y position (separate from saucer FlyY)
#PowerTimer = 0                 ' Landing timeout (counts down from 300)
' Rapid fire variables (reuse title-screen vars during gameplay)
' PowerUpType reuses TitleColor (title-only): 0=beam, 1=rapid fire
' FireCooldown reuses TitleJitter (title-only): frames until next shot allowed
RapidTimer = 0                 ' Rapid fire countdown (300 frames = 5 sec, 0 = normal)
#PathXAddr  = 0                 ' ROM address of FlyPathXData (set at title init)
#PathYAddr  = 0                 ' ROM address of FlyPathYData (set at title init)
' Sound effect variables
SfxVolume   = 0                 ' Current decay volume (0 = silent)
SfxType     = 0                 ' 0=none, 1=alien, 2=saucer, 3=death, 4=mega, 5=bomb, 6=parry, 7=shoot, 8=quad
#SfxPitch   = 0                 ' Current tone period (16-bit for pitch values >255)
' Quad laser variables
' DualTimer packed into #GameFlags (FLAG_DUAL)
WaveRevealCol = ALIEN_COLS - 1  ' Column reveal counter (starts fully revealed)
#NextLife   = 1000              ' Score threshold for next extra life
#MegaTimer  = 0                 ' Mega beam countdown (120 frames = 2 sec, 0 = normal)
MegaBeamCol = 0                 ' BACKTAB column of active beam (0-19)
MegaBeamTimer = 0               ' Beam display countdown (0 = inactive)
ShieldHits    = 0               ' Shield charges (0=none, 1=damaged, 2=full)
' AutoFire packed into #GameFlags (FLAG_AUTOFIRE)
Key1Held    = 0                 ' Debounce flag for keypad 1
' DebugMode packed into #GameFlags (FLAG_DEBUG)
CheatCode   = 0                 ' Packed cheat entry: bits 0-2=held timer, bit 3=got '3'
' SubWave packed into #GameFlags (FLAG_SUBWAVE)
' RevealMode packed into #GameFlags (FLAG_REVEAL for pincer, FLAG_TOPDOWN for top-down)
RightRevealCol = ALIEN_COLS - 1 ' Right-side reveal col (counts down in dual mode)
WaveRevealRow = ALIEN_ROWS - 1  ' Row reveal: top-down=rows revealed, fly-down=rows hidden above
#HighScore  = 0                 ' Session high score (persists until ROM reset)
ChainCount  = 0                 ' Consecutive successful shots (chain combo)
ChainMax    = 0                 ' Best chain this game
' ShotLanded packed into #GameFlags (FLAG_SHOTLAND)
ChainTimeout = 0                ' Frames until chain goes cold (90 = 1.5 sec)
' Rogue alien variables
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
' Capture wingman variables
' CaptureActive packed into #GameFlags (FLAG_CAPTURE)
CaptureColor   = 0                 ' Color of captured alien type
CaptureStep    = 0                 ' Orbit step index (0-15, 16-step circle)
CaptureTimer   = 0                 ' Countdown to next hitscan shot
' Key0Held packed into #GameFlags (FLAG_KEY0HELD)
' CapBulletActive packed into #GameFlags (FLAG_CAPBULLET)
CapBulletCol   = 0                 ' BACKTAB column of wingman bullet
CapBulletRow   = 0                 ' Current BACKTAB row (counts down toward aliens)
' Boss alien state (array-based, up to MAX_BOSSES simultaneous)
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
' Column bitmask lookup table is in ROM (see ColMaskData near end of file)
' Chain explosion state (bomb alien)
BombExpTimer   = 0                 ' Chain explosion countdown (0=inactive, 20=active)
BombExpRow     = 0                 ' Grid row of exploded bomb
BombExpCol     = 0                 ' Left grid column of exploded bomb
' Wave color palette (set at start of each wave from DATA table)
WaveColor0     = 6                 ' Squid color (row 0) — default yellow
WaveColor1     = 1                 ' Crab color (rows 1-2) — default blue
WaveColor2     = 5                 ' Octopus color (rows 3-4) — default green

' Tutorial message state (first powerup hint)
TutorialTimer  = 0                 ' 255=ready, 1-180=showing, 0=done

' Flight engine variables
#FlyPathLen  = 0                 ' Current pattern waypoint count
FlyStepRate = 0                 ' Frames between waypoint advances
FlyMaxLoops = 0                 ' 0=infinite, N=stop after N loops
FlyTransSpd = 0                 ' Pixels per frame during transition

' Game Over letter animation (Zod fly-by triggers rotation)
GOAnimIdx    = 255               ' Currently animating letter (255=none, 0-7=letter)
GOAnimFrame  = 0                 ' Animation frame (0=full, 1=60°, 2=edge, 3=done)

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
    DEFINE GRAM_SAUCER, 1, SaucerGfx
    WAIT
    DEFINE GRAM_SAUCER_F2, 1, SaucerF2Gfx
    WAIT
    DEFINE GRAM_SAUCER_F3, 1, SaucerF3Gfx
    WAIT
    DEFINE GRAM_SAUCER_F4, 1, SaucerF4Gfx
    WAIT
    DEFINE GRAM_BEAM, 1, BeamGfx
    WAIT
    DEFINE GRAM_CAP_F1, 4, CapsuleF1Gfx
    WAIT
    DEFINE GRAM_SHIP_HUD, 1, ShipHudGfx
    WAIT
    DEFINE GRAM_MEGA_BEAM, 1, MegaBeamGfx
    WAIT
    DEFINE GRAM_QUAD, 1, QuadGfx
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

    ' Initialize Intellivoice (once only — multiple calls can lock real hardware)
    IF VOICE.AVAILABLE THEN VOICE INIT

' ============================================
' Reset state and return to title screen
' (shared by GameOver=2 and GameOver=6)
' ============================================
ResetToTitle:
    PLAY OFF
    ' Silence all PSG channels (PLAY OFF stops ISR but leaves registers hot)
    SOUND 0, , 0
    SOUND 1, , 0
    SOUND 2, , 0
    POKE $1F8, $3F  ' Disable all tone + noise
    GameOver = 0
    Lives = STARTING_LIVES
    Level = 1
    #Score = 0
    #NextLife = 1000
    PlayerX = 80
    AlienOffsetX = 0
    AlienOffsetY = 0
    LastClearedY = 0
    AlienDir = 1
    MarchCount = 0
    #GameFlags = #GameFlags AND $FFFC : ABulFrame = 0  ' Clear FLAG_BULLET + FLAG_ABULLET
    RogueState = 0 : RogueTimer = 0 : RogueDivePhase = 0
    FOR LoopVar = 0 TO MAX_BOSSES - 1 : BossHP(LoopVar) = 0 : NEXT LoopVar
    BossCount = 0 : BombExpTimer = 0
    #GameFlags = #GameFlags AND $EFF3  ' Clear FLAG_CAPTURE + FLAG_CAPBULLET + FLAG_KEY0HELD
    #GameFlags = #GameFlags AND ($FFFF XOR FLAG_DUAL)
    #MegaTimer = 0
    MegaBeamTimer = 0
    #GameFlags = #GameFlags AND $FFBF
    Key1Held = 0
    #GameFlags = #GameFlags AND $BEFF  ' Clear FLAG_SUBWAVE + FLAG_REVEAL
    RightRevealCol = ALIEN_COLS - 1
    DeathTimer = 0
    Invincible = 0
    ShakeTimer = 0
    SCROLL 0, 0
    GOSUB HideAllSprites

' ============================================
' TITLE SCREEN
' ============================================
TitleScreen:
    CLS

    ' Initialize Y-axis letter animation state
    TitleAnimState = 0     ' 0=reveal phase (uses dynamic frame calculation)
    RevealCol = 0          ' Current reveal position (0-14)
    VanishCol = 0          ' Current vanish position (0-14)

    ' Load animated title font GRAM (uses gameplay cards 0-55, preserves band/crab/sparks/stars)
    GOSUB LoadAnimatedFont

    ' Restore star graphics (cards 37-38, not touched by animated font)
    DEFINE GRAM_STAR1, 1, Star1Gfx   ' Card 37
    WAIT
    DEFINE GRAM_STAR2, 1, Star2Gfx   ' Card 38

    TitleFrame = 0
    TitleMarchDir = 1      ' 1=right, 0=left
    TitleMarchCount = 0    ' Frame counter for march steps
    TitleGridCol = 4       ' BACKTAB column of grid left edge

    ' Display title text with initial animation frames (edge view)
    GOSUB DrawTitleAnimated

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

    ' Initialize Zod via flight engine
    FlyColors(0) = 7 : FlyColors(1) = 6 : FlyColors(2) = 5
    FlyColors(3) = 3 : FlyColors(4) = 5 : FlyColors(5) = 6
    FlyFrame = 0 : FlyColorIdx = 0 : FlyColorTimer = 0 : FlyColor = 7
    FlyX = 0 : FlyY = 0   ' Start off-screen top-left
    LoopVar = PAT_FIGURE8
    GOSUB FlightStart

    ' Start title music (PLAY FULL for full 3-channel theme)
    PLAY FULL
    PLAY VOLUME 12
    PLAY space_intruders_theme

' --------------------------------------------
' Title Loop - card-step march (no SCROLL)
' --------------------------------------------
    ' Wait for all buttons/keys released before accepting input
TitleDebounce:
    WAIT
    IF CONT.BUTTON OR CONT.KEY < 12 THEN GOTO TitleDebounce

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
    ' --- Zod flight: engine handles transition + pattern, hand-coded exit/pause ---
    IF FlyState <= FLT_DONE THEN
        ' Engine active: transition, following, or just finished
        GOSUB FlightTick
        IF FlyState = FLT_DONE THEN
            FlyState = 4       ' Switch to hand-coded exit wobble
            #FlyPhase = 0
        END IF
    ELSEIF FlyState = 4 THEN
        ' Exit right with Y wobble (hand-coded)
        FlySpeed = FlySpeed + 1
        IF FlySpeed >= 3 THEN
            FlySpeed = 0
            FlyX = FlyX + 4
            #FlyPhase = #FlyPhase + 1
            IF (#FlyPhase AND 3) = 0 THEN
                FlyY = 53
            ELSEIF (#FlyPhase AND 3) = 1 THEN
                FlyY = 56
            ELSEIF (#FlyPhase AND 3) = 2 THEN
                FlyY = 59
            ELSE
                FlyY = 56
            END IF
            IF FlyX > 167 THEN
                FlyState = 5       ' Offscreen pause
                #FlyPhase = 0
            END IF
        END IF
    ELSE
        ' FlyState=5: Offscreen pause (~1 sec = 20 steps × 3 frames)
        FlySpeed = FlySpeed + 1
        IF FlySpeed >= 3 THEN
            FlySpeed = 0
            #FlyPhase = #FlyPhase + 1
            IF #FlyPhase >= 20 THEN
                ' Restart: re-enter from top-left
                FlyX = 0 : FlyY = 0
                LoopVar = PAT_FIGURE8
                GOSUB FlightStart
                ' Reset title animation for another reveal cascade
                TitleAnimState = 0
                RevealCol = 0
                GOSUB DrawTitleAnimated
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

    ' Draw Zod (or hide if offscreen pause)
    FlyFrame = FlyFrame + 1
    IF FlyFrame >= 16 THEN FlyFrame = 0
    IF FlyState = 5 THEN
        SPRITE SPR_FLYER, 0, 0, 0
    ELSE
        IF FlyFrame < 8 THEN
            SPRITE SPR_FLYER, FlyX + SPR_VISIBLE, FlyY, GRAM_CRAB_F1 * 8 + FlyColor + $0800
        ELSE
            SPRITE SPR_FLYER, FlyX + SPR_VISIBLE, FlyY, GRAM_CRAB_F2 * 8 + FlyColor + $0800
        END IF
    END IF

    ' --- Y-Axis Letter Animation ---
    ' Simple: Zod's X position directly determines which letters are revealed
    IF TitleAnimState = 0 THEN
        ' RevealCol = FlyX / 5, capped at 14
        Col = FlyX / 5
        IF Col > 14 THEN Col = 14
        IF Col <> RevealCol THEN
            RevealCol = Col
            GOSUB DrawTitleAnimated
        END IF
        ' All letters revealed when RevealCol reaches 14
        IF RevealCol >= 14 THEN
            TitleAnimState = 1
            GOSUB DrawTitleAnimated  ' Redraw all letters as full (state 1)
        END IF
    END IF

    ' Vanish cascade: VanishCol 0-15 = letters (fast), 16+ = screen wipe (2 cols/frame)
    IF TitleAnimState = 2 THEN
        IF VanishCol < 16 THEN
            ' Phase 1: Letter vanish animation (2x speed)
            VanishCol = VanishCol + 2
            GOSUB DrawTitleAnimated
        ELSE
            ' Phase 2: Screen wipe - clear 1 column per frame (smooth sweep)
            WipeCol = VanishCol - 16
            IF WipeCol < 20 THEN
                FOR Row = 0 TO 11
                    PRINT AT Row * 20 + WipeCol, 0
                NEXT Row
            END IF
            VanishCol = VanishCol + 1
            GOSUB HideAllSprites
        END IF
        IF VanishCol >= 36 THEN
            ' Wipe complete - transition to gameplay
            SOUND 0, , 0 : SOUND 1, , 0 : SOUND 2, , 0
            POKE $1F8, $3F
            PLAY SIMPLE : PLAY VOLUME 12 : PLAY si_bg_slow
            GOTO StartGame
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
    ' Wait until flyer begins pattern before starting slide-in
    IF FlyState = FLT_TRANSITION THEN GOTO SkipPressfire

    ' When Zod exits (state 4): rapid flash then disappear
    IF FlyState = 4 THEN
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

    ' When Zod is offscreen (state 5): clear text and reset for next cycle
    IF FlyState = 5 THEN
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

    ' Cheat code: type "36" on keypad to toggle debug mode
    ' CheatCode packed: bits 0-2 = held timer, bit 3 = got '3'
    IF CONT.KEY = 3 THEN
        IF (CheatCode AND 7) = 0 THEN
            CheatCode = 8 + 5  ' Set state=1 (bit 3), held=5
        END IF
    ELSEIF CONT.KEY = 6 THEN
        IF (CheatCode AND 7) = 0 THEN
            CheatCode = (CheatCode AND 8) + 5  ' Keep state, set held=5
            IF CheatCode >= 8 THEN
                #GameFlags = #GameFlags XOR FLAG_DEBUG
                CheatCode = 5  ' Clear state, keep held=5
                ' Flash border to confirm
                IF #GameFlags AND FLAG_DEBUG THEN
                    BORDER COL_RED
                    PRINT AT 219 COLOR COL_RED, "DEBUG"
                ELSE
                    BORDER 0
                    PRINT AT 219, 0
                    PRINT AT 220, 0
                    PRINT AT 221, 0
                    PRINT AT 222, 0
                    PRINT AT 223, 0
                END IF
            END IF
        END IF
    ELSE
        IF CheatCode AND 7 THEN CheatCode = CheatCode - 1
        ' Reset cheat state if a non-3/6 key is pressed
        IF CONT.KEY < 12 THEN
            IF CONT.KEY <> 3 THEN
                IF CONT.KEY <> 6 THEN CheatCode = CheatCode AND 7  ' Clear bit 3
            END IF
        END IF
    END IF

    ' Fire button: must hold 4 frames with NO keypad key active
    IF CONT.BUTTON THEN
        IF CONT.KEY >= 12 THEN
            IF Key1Held < 4 THEN Key1Held = Key1Held + 1
        ELSE
            Key1Held = 0    ' Keypad active — reset counter
        END IF
    ELSE
        Key1Held = 0
    END IF
    IF Key1Held >= 4 THEN
        ' Start vanish cascade (only if not already vanishing)
        IF TitleAnimState = 0 OR TitleAnimState = 1 THEN
            TitleAnimState = 2
            VanishCol = 0
        END IF
    END IF

    GOTO TitleLoop

    SEGMENT 1   ' All procedures in Segment 1 (Seg 0 reserved for main code + Intellivoice runtime)

' ============================================
' UTILITY PROCEDURES (shared code consolidation)
' ============================================

' --- HideAllSprites: Hide all 8 hardware sprites ---
HideAllSprites: PROCEDURE
    SPRITE 0, 0, 0, 0 : SPRITE 1, 0, 0, 0
    SPRITE 2, 0, 0, 0 : SPRITE 3, 0, 0, 0
    SPRITE 4, 0, 0, 0 : SPRITE 5, 0, 0, 0
    SPRITE 6, 0, 0, 0 : SPRITE 7, 0, 0, 0
    RETURN
END

' --- HitShield: Absorb a hit on the shield, announce if shields down ---
HitShield: PROCEDURE
    ShieldHits = ShieldHits - 1
    SfxType = 9 : SfxVolume = 12 : #SfxPitch = 800
    SOUND 2, 800, 12
    IF ShieldHits = 0 THEN
        IF VOICE.AVAILABLE THEN VOICE PLAY shields_down_phrase
    END IF
    RETURN
END

' --- SilenceSfx: Stop all sound effects on channel 3 ---
SilenceSfx: PROCEDURE
    SOUND 2, , 0
    SfxVolume = 0
    SfxType = 0
    RETURN
END

' --- ClearRogueOnly: Reset rogue alien state (preserves wingman) ---
ClearRogueOnly: PROCEDURE
    RogueState = 0 : RogueTimer = 0 : RogueDivePhase = 0
    SPRITE SPR_FLYER, 0, 0, 0
    RETURN
END

    SEGMENT 3   ' Title animation procedures (Seg 1 near capacity)

' --- LoadAnimatedFont: Load 33 frames (3 per letter: full, 60°, edge) ---
' Loads frames 1, 3, 4 for each letter (skips frame 2 for smoother 3-step)
' Preserves: 9-12 (band), 19-38 (crab/sparks/font/stars)
LoadAnimatedFont: PROCEDURE
    ' S: cards 0-2 (full, 60°, edge)
    DEFINE 0, 1, FontSY1Gfx : WAIT
    DEFINE 1, 1, FontSY3Gfx : WAIT
    DEFINE 2, 1, FontSY4Gfx : WAIT
    ' P: cards 3-5
    DEFINE 3, 1, FontPY1Gfx : WAIT
    DEFINE 4, 1, FontPY3Gfx : WAIT
    DEFINE 5, 1, FontPY4Gfx : WAIT
    ' A: cards 6-8
    DEFINE 6, 1, FontAY1Gfx : WAIT
    DEFINE 7, 1, FontAY3Gfx : WAIT
    DEFINE 8, 1, FontAY4Gfx : WAIT
    ' C: cards 13-15 (skip 9-12 band)
    DEFINE 13, 1, FontCY1Gfx : WAIT
    DEFINE 14, 1, FontCY3Gfx : WAIT
    DEFINE 15, 1, FontCY4Gfx : WAIT
    ' E: cards 16-18
    DEFINE 16, 1, FontEY1Gfx : WAIT
    DEFINE 17, 1, FontEY3Gfx : WAIT
    DEFINE 18, 1, FontEY4Gfx : WAIT
    ' I: cards 39-41 (skip 19-38)
    DEFINE 39, 1, FontIY1Gfx : WAIT
    DEFINE 40, 1, FontIY3Gfx : WAIT
    DEFINE 41, 1, FontIY4Gfx : WAIT
    ' N: cards 42-44
    DEFINE 42, 1, FontNY1Gfx : WAIT
    DEFINE 43, 1, FontNY3Gfx : WAIT
    DEFINE 44, 1, FontNY4Gfx : WAIT
    ' T: cards 45-47
    DEFINE 45, 1, FontTY1Gfx : WAIT
    DEFINE 46, 1, FontTY3Gfx : WAIT
    DEFINE 47, 1, FontTY4Gfx : WAIT
    ' R: cards 48-50
    DEFINE 48, 1, FontRY1Gfx : WAIT
    DEFINE 49, 1, FontRY3Gfx : WAIT
    DEFINE 50, 1, FontRY4Gfx : WAIT
    ' U: cards 51-53
    DEFINE 51, 1, FontUY1Gfx : WAIT
    DEFINE 52, 1, FontUY3Gfx : WAIT
    DEFINE 53, 1, FontUY4Gfx : WAIT
    ' D: cards 54-56
    DEFINE 54, 1, FontDY1Gfx : WAIT
    DEFINE 55, 1, FontDY3Gfx : WAIT
    DEFINE 56, 1, FontDY4Gfx : WAIT
    RETURN
END

' --- DrawTitleAnimated: Draw title text using computed animation frames ---
' 3 frames: 0=full, 1=60°, 2=edge. Smoother reveal/vanish cascade.
' State 0 (reveal): Row < RevealCol=full, Row=RevealCol=60°, Row > RevealCol=edge
' State 1 (normal): all full
' State 2 (vanish): Row < VanishCol=edge, Row=VanishCol=60°, Row > VanishCol=full
' State 3 (done): all edge
DrawTitleAnimated: PROCEDURE
    FOR Row = 0 TO 14
        IF Row = 5 THEN GOTO DrawAnimSkip  ' Skip space position

        ' Compute frame: 0=full, 1=60°, 2=edge
        Col = 2  ' Default: edge
        IF TitleAnimState = 0 THEN
            ' Reveal: before RevealCol=full, at RevealCol=60°, after=edge
            IF Row < RevealCol THEN Col = 0
            IF Row = RevealCol THEN Col = 1
        END IF
        IF TitleAnimState = 1 THEN Col = 0  ' Normal: all full
        IF TitleAnimState = 2 THEN
            ' Vanish: before VanishCol=edge, at VanishCol=60°, after=full
            Col = 0  ' Default full
            IF Row < VanishCol THEN Col = 2
            IF Row = VanishCol THEN Col = 1
        END IF

        ' Lookup GRAM card from appropriate frame table
        IF Col = 0 THEN LoopVar = TitleGramF0(Row)
        IF Col = 1 THEN LoopVar = TitleGramF1(Row)
        IF Col = 2 THEN LoopVar = TitleGramF2(Row)
        #Card = LoopVar * 8 + COL_TAN + $0800
        PRINT AT 22 + Row, #Card

DrawAnimSkip:
    NEXT Row
    RETURN
END

' GRAM card lookup tables for 3 frames (full, 60°, edge)
' Index: 0=S, 1=P, 2=A, 3=C, 4=E, 5=skip, 6=I, 7=N, 8=T, 9=R, 10=U, 11=D, 12=E, 13=R, 14=S
TitleGramF0:
    DATA 0, 3, 6, 13, 16, 0, 39, 42, 45, 48, 51, 54, 16, 48, 0
TitleGramF1:
    DATA 1, 4, 7, 14, 17, 0, 40, 43, 46, 49, 52, 55, 17, 49, 1
TitleGramF2:
    DATA 2, 5, 8, 15, 18, 0, 41, 44, 47, 50, 53, 56, 18, 50, 2

' --- DrawGOLetter: Draw animating game over letter ---
' Uses GOAnimIdx (0-7) and GOAnimFrame (0-19)
' Animation: 0-4=full, 5-9=60°, 10-14=edge, 15-19=full (half rotation)
' Letters: 0=G, 1=A, 2=M, 3=E, 4=O, 5=V, 6=E, 7=R
DrawGOLetter: PROCEDURE
    ' Get BACKTAB position for this letter
    LoopVar = GOLetterPos(GOAnimIdx)

    ' Determine animation frame: 0-2=full(0), 3-5=60°(1), 6-8=edge(2), 9=full(0)
    Col = GOAnimFrame / 3
    IF Col > 2 THEN Col = 0  ' Wrap back to full at end

    ' Get base GRAM card for this letter's animation
    Row = GOLetterGram(GOAnimIdx) + Col

    ' Draw the letter
    #Card = Row * 8 + COL_TAN + $0800
    PRINT AT LoopVar, #Card
    RETURN
END

' Game Over letter BACKTAB positions
GOLetterPos:
    DATA 45, 46, 47, 48, 50, 51, 52, 53

' Game Over animated GRAM base cards (frame 0 = full)
' 0=G(0), 1=A(6), 2=M(3), 3=E(16), 4=O(51), 5=V(54), 6=E(16), 7=R(48)
GOLetterGram:
    DATA 0, 6, 3, 16, 51, 54, 16, 48

' Game Over STATIC GRAM cards (original fonts)
' G=37, A=27, M=38, E=29, O=40, V=41, E=29, R=33
GOLetterStaticGram:
    DATA 37, 27, 38, 29, 40, 41, 29, 33

    SEGMENT 1   ' Back to Segment 1 for remaining procedures

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
            StarPos(LoopVar) = 60 + Col       ' Row 3
        ELSEIF Row = 1 THEN
            StarPos(LoopVar) = 80 + Col       ' Row 4
        ELSEIF Row = 2 THEN
            StarPos(LoopVar) = 160 + Col      ' Row 8
        ELSEIF Row = 3 THEN
            StarPos(LoopVar) = 180 + Col      ' Row 9
        ELSE
            StarPos(LoopVar) = 220 + Col      ' Row 11
        END IF
        ' Alternate star type: even=slow/dim, odd=fast/bright
        StarType(LoopVar) = LoopVar AND 1
        ' Draw the star
        IF StarType(LoopVar) = 0 THEN
            PRINT AT StarPos(LoopVar), GRAM_STAR1 * 8 + 4 + $0800  ' Dark green, dim
        ELSE
            PRINT AT StarPos(LoopVar), GRAM_STAR2 * 8 + 7 + $0800  ' White, bright
        END IF
        StarCount = StarCount + 1
    NEXT LoopVar
    RETURN
END

' --- ScrollStars: shift all stars left with parallax ---
ScrollStars: PROCEDURE
    FOR LoopVar = 0 TO StarCount - 1
        ' Calculate row and column from BACKTAB position
        Row = StarPos(LoopVar) / 20
        Col = StarPos(LoopVar) - (Row * 20)

        ' Clear old position
        PRINT AT StarPos(LoopVar), 0

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
        StarPos(LoopVar) = Row * 20 + Col

        ' Redraw star
        IF StarType(LoopVar) = 0 THEN
            PRINT AT StarPos(LoopVar), GRAM_STAR1 * 8 + 4 + $0800
        ELSE
            PRINT AT StarPos(LoopVar), GRAM_STAR2 * 8 + 7 + $0800
        END IF
    NEXT LoopVar
    RETURN
END

' --- DrawSilhouette: draw scrolling mountain silhouette on row 0 ---
DrawSilhouette: PROCEDURE
    FOR Col = 0 TO 19
        LoopVar = SilhOffset + Col
        IF LoopVar >= SILH_MAP_LEN THEN LoopVar = LoopVar - SILH_MAP_LEN
        Row = SilhHeightMap(LoopVar)
        PRINT AT Col, SilhCardMap(Row)
    NEXT Col
    RETURN
END

' ============================================
' START GAME - Initialize gameplay
' ============================================
StartGame:
    CLS

    ' Reload ALL gameplay GRAM cards overwritten by animated title font
    ' Cards 0-8: Ship, aliens, bullet
    DEFINE GRAM_SHIP, 2, ShipGfx          ' Cards 0-1
    WAIT
    DEFINE GRAM_ALIEN1, 2, Alien1Gfx      ' Cards 2-3
    WAIT
    DEFINE GRAM_ALIEN2, 2, Alien2Gfx      ' Cards 4-5
    WAIT
    DEFINE GRAM_ALIEN3, 2, Alien3Gfx      ' Cards 6-7
    WAIT
    DEFINE GRAM_BULLET, 1, BulletGfx      ' Card 8
    WAIT
    ' Cards 9-12: Band (preserved during title - already correct from init)
    ' But reload to ensure consistency after any title animation quirks
    DEFINE GRAM_BAND1, 1, Band1Gfx
    WAIT
    DEFINE GRAM_BAND2, 1, Band2Gfx
    WAIT
    DEFINE GRAM_BAND1_F1, 1, Band1F1Gfx
    WAIT
    DEFINE GRAM_BAND2_F1, 1, Band2F1Gfx
    WAIT
    ' Cards 13-18: Wingman, explosions, ship accent
    DEFINE GRAM_WINGMAN_F1, 1, WingmanF1Gfx  ' Card 13
    WAIT
    DEFINE GRAM_EXPLOSION, 1, ExplosionGfx    ' Card 14
    WAIT
    DEFINE GRAM_EXPLOSION2, 1, ExplosionGfx2  ' Card 15
    WAIT
    DEFINE GRAM_EXPLOSION3, 1, ExplosionGfx3  ' Card 16
    WAIT
    DEFINE GRAM_SHIP_ACCENT, 2, ShipAccentGfx ' Cards 17-18
    WAIT
    DEFINE GRAM_SILH_1Q, 4, SilhGfx           ' Cards 21-24: silhouette fill levels
    WAIT

    ' Redefine title font GRAM cards (25-32) for powerup HUD indicators
    ' 8 tiles: BEAM(BE,AM), RAPID(RP,ID), QUAD(QU,AD), MEGA(ME,GA)
    DEFINE GRAM_PWR_BE, 4, PowerupBEGfx  ' Cards 25-28: BE, AM, RP, ID
    WAIT
    DEFINE GRAM_PWR_QU, 4, PowerupQUGfx  ' Cards 29-32: QU, AD, ME, GA
    WAIT
    DEFINE GRAM_SHIELD, 1, ShieldArcGfx  ' Card 33: Shield arc
    WAIT
    DEFINE GRAM_WARP1, 3, WarpInGfx1    ' Cards 34-36: Warp-in animation
    WAIT
    ' Cards 39-55: Saucer, beams, capsules, bombs, zigzag
    DEFINE GRAM_SAUCER, 1, SaucerGfx      ' Card 39
    WAIT
    DEFINE GRAM_BEAM, 1, BeamGfx          ' Card 40
    WAIT
    DEFINE GRAM_SAUCER_F2, 3, SaucerF2Gfx ' Cards 42-44 (skips 41=POWERUP, reused from capsule)
    WAIT
    DEFINE GRAM_SHIP_HUD, 1, ShipHudGfx   ' Card 45
    WAIT
    DEFINE GRAM_MEGA_BEAM, 1, MegaBeamGfx ' Card 46
    WAIT
    DEFINE GRAM_QUAD, 1, QuadGfx          ' Card 47
    WAIT
    DEFINE GRAM_CAP_F1, 4, CapsuleF1Gfx   ' Cards 48-51
    WAIT
    DEFINE GRAM_ZIGZAG1, 2, ZigzagF1Gfx   ' Cards 52-53
    WAIT
    DEFINE GRAM_BOMB1, 2, SquidLeftF1Gfx  ' Cards 54-55
    WAIT
    DEFINE GRAM_BOMB1_F1, 1, SquidLeftF2Gfx  ' Card 56 (overwritten by title anim)
    WAIT
    DEFINE GRAM_BOMB2_F1, 1, SquidRightF2Gfx ' Card 57

    ' Initialize all aliens as alive (9 bits = $1FF)
    FOR LoopVar = 0 TO ALIEN_ROWS - 1
        #AlienRow(LoopVar) = $1FF
    NEXT LoopVar

    ' Initialize level, march speed, and wave 1 palette
    Level = 1
    WaveColor0 = 6 : WaveColor1 = 1 : WaveColor2 = 5  ' Yellow / Blue / Green
    BaseMarchSpeed = MARCH_SPEED_START
    CurrentMarchSpeed = MARCH_SPEED_START
    MusicGear = 0
    WaveRevealRow = 0
    #GameFlags = #GameFlags AND $BEFF  ' Clear FLAG_SUBWAVE + FLAG_REVEAL
    LoopVar = 0  ' Wave 1 = index 0
    GOSUB SetEntrancePattern
    RightRevealCol = ALIEN_COLS - 1

    ' Draw HUD: SCORE (left) | CHAIN | POWERUP | LIVES (right)
    ' New layout: 220-222=SCORE, 223-227=digits, 228-230=CHAIN, 231-232=count,
    '             233-234=powerup (when active), 235=ship, 236=X, 237=lives
    ' Score label at 220-222, value at 223+
    PRINT AT 220, GRAM_SCORE_SC * 8 + COL_WHITE + $0800
    PRINT AT 221, GRAM_SCORE_OR * 8 + COL_WHITE + $0800
    PRINT AT 222, GRAM_SCORE_E * 8 + COL_WHITE + $0800
    PRINT AT 223 COLOR COL_WHITE, "0"
    PRINT AT 224, 0 : PRINT AT 225, 0 : PRINT AT 226, 0 : PRINT AT 227, 0
    ' Chain label at 228-230, count at 231-232
    ' Start grey + hyphen since ChainCount = 0
    PRINT AT 228, GRAM_CHAIN_CH * 8 + $1800
    PRINT AT 229, GRAM_CHAIN_AI * 8 + $1800
    PRINT AT 230, GRAM_CHAIN_N * 8 + $1800
    PRINT AT 231, 111                            ' GROM hyphen in white
    PRINT AT 232, 0                              ' Clear second digit slot
    ' Powerup indicator at 233-234 (clear initially)
    PRINT AT 233, 0 : PRINT AT 234, 0
    ' Lives: X tile at 236, count at 238 (with gap)
    PRINT AT 236, (GRAM_SHIP_HUD * 8) + COL_WHITE + $0800
    PRINT AT 238 COLOR COL_WHITE, "2"

    ' Initialize parallax silhouette on row 0
    SilhOffset = 0
    StarTimer = 0
    GOSUB DrawSilhouette

    ' Initialize saucer (inactive, random spawn delay 1-4 seconds)
    FlyState = 0
    #FlyPhase = 0  ' Spawn countdown (counts up to threshold)
    #FlyLoopCount = RANDOM(360) + 180  ' Random spawn threshold
    BeamTimer = 0  ' No beam power-up
    RapidTimer = 0 ' No rapid fire
    #GameFlags = #GameFlags AND ($FFFF XOR FLAG_DUAL)  ' No dual laser
    #MegaTimer = 0  ' No mega beam
    MegaBeamTimer = 0
    ShieldHits = 0  ' No shield
    TitleFrame = 0  ' No power-up drop
    ' Weighted power-up: 0=beam(2), 1=rapid(3), 2=quad(2), 3=mega(1) out of 8
    TitleColor = PowerUpWeights(RANDOM(8))
    TitleJitter = 0 ' No fire cooldown
    ChainCount = 0  ' Reset kill chain
    ChainMax = 0    ' Reset best chain for new game
    RogueState = 0 : RogueTimer = 0 : RogueDivePhase = 0
    FOR LoopVar = 0 TO MAX_BOSSES - 1 : BossHP(LoopVar) = 0 : NEXT LoopVar
    BossCount = 0 : BombExpTimer = 0  ' Wave 1 has no boss
    #GameFlags = #GameFlags AND $FFF3  ' Clear FLAG_CAPTURE + FLAG_CAPBULLET
    TutorialTimer = 255              ' Ready to show "GET THE POWERUP!" on first drop
    SPRITE SPR_FLYER, 0, 0, 0
    SPRITE SPR_SAUCER, 0, 0, 0
    SPRITE SPR_SAUCER2, 0, 0, 0
    SPRITE SPR_POWERUP, 0, 0, 0

    ' Wave 1 announcement
    IF VOICE.AVAILABLE THEN
        VOICE PLAY wave_phrase
        VOICE WAIT
        VOICE NUMBER 1
    END IF
    PRINT AT 107 COLOR 6, "WAVE 1"
    FOR LoopVar = 0 TO 90
        WAIT
    NEXT LoopVar
    FOR LoopVar = 0 TO 7
        IF (LoopVar AND 1) = 0 THEN
            PRINT AT 107, "       "
        ELSE
            PRINT AT 107 COLOR 6, "WAVE 1"
        END IF
        FOR Row = 0 TO 4
            WAIT
        NEXT Row
    NEXT LoopVar
    PRINT AT 107, "       "

    ' Ship reveal animation (procedure in Segment 2)
    GOSUB ShipReveal

    ' Initialize player sprite (removes BEHIND flag)
    GOSUB DrawPlayer

' --------------------------------------------
' Main Game Loop
' --------------------------------------------
GameLoop:
    WAIT
    ' Debug mode: CPU profiling — red border during game logic
    IF #GameFlags AND FLAG_DEBUG THEN BORDER COL_RED

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

    ' Game Over screen with bolt sweep effect (GameOver=5: release, 6: accept)
    IF GameOver >= 5 THEN
        ' White bolt sweep across "GAME OVER" text at row 2 (pos 45)
        ' TitleMarchX = frame counter, advance bolt every 6 frames
        ' TitleJitter = bolt position (0-8 on text, 9-13 gap between sweeps)
        TitleMarchX = TitleMarchX + 1
        IF TitleMarchX >= 6 THEN
            TitleMarchX = 0
            ' Restore current bolt position to tan and clear sparks
            IF TitleJitter < 9 THEN
                #Card = PEEK($22D + TitleJitter)
                PRINT AT 45 + TitleJitter, (#Card AND $EFF8) OR COL_TAN
                PRINT AT 25 + TitleJitter, 0     ' Clear spark above (row 1)
                PRINT AT 65 + TitleJitter, 0     ' Clear spark below (row 3)
            END IF
            ' Advance bolt position
            TitleJitter = TitleJitter + 1
            IF TitleJitter >= 14 THEN TitleJitter = 0
            ' Set new bolt position to white with sparks
            IF TitleJitter < 9 THEN
                #Card = PEEK($22D + TitleJitter)
                PRINT AT 45 + TitleJitter, (#Card AND $EFF8) OR COL_WHITE
                PRINT AT 25 + TitleJitter, GRAM_SPARK_UP * 8 + $1800
                PRINT AT 65 + TitleJitter, GRAM_SPARK_DN * 8 + $1800
            END IF
        END IF
        ' Spark 2-frame animation: switch to trailing frame at frame 3
        IF TitleJitter < 9 THEN
            IF TitleMarchX >= 3 THEN
                PRINT AT 25 + TitleJitter, GRAM_SPARK_UP2 * 8 + $1800
                PRINT AT 65 + TitleJitter, GRAM_SPARK_DN2 * 8 + $1800
            END IF
        END IF

        ' "PRESS FIRE" shimmer: alternate white/tan every 4 frames
        TitleColor = TitleColor + 1
        IF TitleColor >= 4 THEN
            TitleColor = 0
            WavePhase = WavePhase + 1
            IF WavePhase >= 4 THEN WavePhase = 0
            IF WaveColors(WavePhase) = 0 THEN
                PRINT AT 205 COLOR COL_TAN, "PRESS FIRE"
            ELSE
                PRINT AT 205 COLOR COL_WHITE, "PRESS FIRE"
            END IF
        END IF

        ' --- Zod diamond orbit via flight engine ---
        GOSUB FlightTick
        GOSUB ZodRender

        ' --- Game Over letter wave animation ---
        MarchCount = MarchCount + 1
        IF MarchCount >= 120 THEN
            MarchCount = 0
            IF GOAnimIdx >= 8 THEN GOAnimIdx = 0 : GOAnimFrame = 0
        END IF

        ' Zod bump: at letter row, trigger that letter
        IF FlyY >= 16 AND FlyY <= 32 THEN
            Col = (FlyX - 8) / 8
            IF Col >= 5 AND Col <= 13 THEN
                IF Col < 9 THEN GOAnimIdx = Col - 5 ELSE GOAnimIdx = Col - 6
            END IF
        END IF

        ' Animate current letter, then next
        IF GOAnimIdx < 8 THEN
            GOSUB DrawGOLetter
            GOAnimFrame = GOAnimFrame + 1
            IF GOAnimFrame > 9 THEN
                GOSUB DrawGOLetterStatic
                GOAnimIdx = GOAnimIdx + 1
                GOAnimFrame = 0
            END IF
        END IF

        ' Button debounce: GameOver=5 waits for release, GameOver=6 accepts press
        IF GameOver = 5 THEN
            IF CONT.BUTTON = 0 AND CONT.KEY = 12 THEN GameOver = 6
        END IF
        IF GameOver = 6 THEN
            IF CONT.BUTTON OR CONT.KEY = 1 THEN
                GOTO ResetToTitle
            END IF
        END IF
        IF #GameFlags AND FLAG_DEBUG THEN BORDER 0
        GOTO GameLoop
    END IF

    ' Handle player movement and firing (only if not dead)
    IF DeathTimer = 0 THEN
        GOSUB MovePlayer
    END IF

    ' Animate alien walk frames independently (every 16 frames)
    ' Reuse HitCol as dirty flag (avoids new variable, gets reset later anyway)
    HitCol = 0
    ShimmerCount = ShimmerCount + 1
    IF ShimmerCount >= 16 THEN
        ShimmerCount = 0
        AnimFrame = AnimFrame XOR 1
        HitCol = 1  ' Animation changed, need redraw
    END IF

    ' Advance wave reveal
    IF #GameFlags AND FLAG_FLYDOWN THEN
        ' Fly-down: entire grid descends from above screen
        ' WaveRevealRow = rows still hidden above (counts DOWN to 0)
        IF WaveRevealRow > 0 THEN
            WaveRevealRow = WaveRevealRow - 1
            HitCol = 1  ' Descent continues, redraw needed
            IF WaveRevealRow = 0 THEN
                ' Descent complete, clear flag and wipe ghost trails
                #GameFlags = #GameFlags AND ($FFFF XOR FLAG_FLYDOWN)
                ' Clear rows 0 through ALIEN_ROWS-1 to remove any fly-down ghosts
                FOR ClearRow = 0 TO ALIEN_ROWS - 1
                    #ScreenPos = ClearRow * 20
                    FOR Col = 0 TO ALIEN_COLS + 1
                        PRINT AT #ScreenPos + Col, 0
                    NEXT Col
                NEXT ClearRow
                GOSUB DrawSilhouette  ' Restore row 0 silhouette after ghost wipe
            END IF
        END IF
    ELSEIF #GameFlags AND FLAG_TOPDOWN THEN
        ' Top-to-bottom row reveal with warp-in animation
        IF WaveRevealRow < ALIEN_ROWS - 1 THEN
            MarchCount = MarchCount + 1
            IF MarchCount >= 3 THEN
                ' Warp complete for this row, advance to next
                MarchCount = 0
                WaveRevealRow = WaveRevealRow + 1
            END IF
            HitCol = 1  ' Warp animation needs redraw every frame
        END IF
    ELSEIF (#GameFlags AND FLAG_REVEAL) = 0 THEN
        ' Standard left-to-right reveal with warp-in animation
        IF WaveRevealCol < ALIEN_COLS - 1 THEN
            MarchCount = MarchCount + 1
            IF MarchCount >= 3 THEN
                ' Warp complete for this column, advance to next
                MarchCount = 0
                WaveRevealCol = WaveRevealCol + 1
            END IF
            HitCol = 1  ' Warp animation needs redraw every frame
        END IF
    ELSE
        ' Dual-slide mode (Pattern B) - halves fly in from screen edges
        ' Advance every frame (no timer) to match fly-down speed
        IF WaveRevealCol < 5 THEN WaveRevealCol = WaveRevealCol + 1
        IF RightRevealCol > 5 THEN RightRevealCol = RightRevealCol - 1
        IF WaveRevealCol >= 5 AND RightRevealCol <= 5 THEN
            ' Slide complete - switch to normal march mode
            #GameFlags = #GameFlags AND $FEFF
            WaveRevealCol = ALIEN_COLS - 1
            ' Clear alien area to remove ghost tiles
            FOR ClearRow = 0 TO ALIEN_ROWS - 1
                IF ALIEN_START_Y + AlienOffsetY + ClearRow < 11 THEN
                    #ScreenPos = (ALIEN_START_Y + AlienOffsetY + ClearRow) * 20
                    FOR Col = 0 TO 19
                        PRINT AT #ScreenPos + Col, 0
                    NEXT Col
                END IF
            NEXT ClearRow
        END IF
        HitCol = 1  ' Pattern B always redraws during slide-in
    END IF

    ' Single DrawAliens call per frame (if needed)
    IF HitCol THEN GOSUB DrawAliens

    ' Check if reveal is complete (all entrance animations done)
    HitCol = 0
    IF WaveRevealCol >= ALIEN_COLS - 1 THEN
        IF (#GameFlags AND FLAG_FLYDOWN) = 0 THEN HitCol = 1
    END IF

    ' Update alien march (only after reveal is complete, and not during death)
    IF HitCol THEN
    IF DeathTimer = 0 THEN
    MarchCount = MarchCount + 1
    IF MarchCount >= CurrentMarchSpeed THEN
        MarchCount = 0
        GOSUB MarchAliens
        GOSUB DrawAliens
        ' Check if aliens reached the bottom (invasion!)
        ' Find bottom-most alive row (scan from bottom up, stop at first alive)
        HitRow = 255  ' sentinel: no alive row found
        FOR Row = ALIEN_ROWS - 1 TO 0 STEP -1
            IF #AlienRow(Row) THEN
                IF HitRow = 255 THEN HitRow = Row
            END IF
        NEXT Row
        ' Check invasion threshold (aliens reached ship baseline)
        IF HitRow < 255 THEN
          IF GameOver = 0 THEN
            IF ALIEN_START_Y + AlienOffsetY + HitRow >= 10 THEN
                ' Invasion! Lose a life and reset formation
                IF DeathTimer = 0 AND Invincible = 0 THEN
                    Lives = Lives - 1
                    GOSUB UpdateLivesHUD
                    ' Clear power-ups, bullets, rogue, wingman
                    BeamTimer = 0 : RapidTimer = 0
                    #GameFlags = #GameFlags AND ($FFFF XOR FLAG_DUAL) : #MegaTimer = 0 : ShieldHits = 0
                    #GameFlags = #GameFlags AND $FFFC  ' Clear FLAG_BULLET + FLAG_ABULLET
                    RogueState = ROGUE_IDLE : RogueTimer = 0 : RogueDivePhase = 0
                    #GameFlags = #GameFlags AND $FFF3  ' Clear FLAG_CAPTURE + FLAG_CAPBULLET
                    GOSUB SilenceSfx
                    SPRITE SPR_PLAYER, 0, 0, 0
                    SPRITE SPR_SHIP_ACCENT, 0, 0, 0
                    SPRITE SPR_PBULLET, 0, 0, 0
                    SPRITE SPR_ABULLET, 0, 0, 0
                    SPRITE SPR_FLYER, 0, 0, 0
                    SPRITE SPR_POWERUP, 0, 0, 0
                    TitleFrame = 0  ' Cancel any falling/landed capsule
                    IF Lives = 0 THEN
                        ' No lives left — game over
                        GameOver = 3
                        DeathTimer = 75
                        ShakeTimer = 30
                    ELSE
                        ' INVASION! Aliens freeze in place, then reset to middle
                        ' Extra 30 frames (105-75) = freeze phase with aliens visible
                        DeathTimer = 105
                        ShakeTimer = 45  ' Longer shake for dramatic effect
                        ' Don't reset aliens yet — they freeze where they are
                        ' Clear and reset happens at DeathTimer = 75 (see below)
                    END IF
                END IF
            END IF
          END IF
        END IF
    END IF
    END IF ' DeathTimer gate for march
    END IF ' reveal complete gate

    ' Update bullets
    IF #GameFlags AND FLAG_BULLET THEN
        GOSUB MoveBullet
    END IF

    ' Alien shooting logic
    GOSUB AlienShoot

    ' Update captured wingman position (before bullet collision check)
    IF #GameFlags AND FLAG_CAPTURE THEN GOSUB UpdateCapture

    ' Update alien bullet
    IF #GameFlags AND FLAG_ABULLET THEN
        GOSUB MoveAlienBullet
    END IF

    ' Update explosion effect (BACKTAB tile with 3-frame animation)
    ' 16 frames for chain kills (1 white flash + 15 explosion), 15 otherwise
    IF ExplosionTimer > 0 THEN
        ExplosionTimer = ExplosionTimer - 1
        IF #ExplosionPos < 220 THEN
        IF ExplosionTimer = 0 THEN
            PRINT AT #ExplosionPos, 0  ' Clear
        ELSEIF ExplosionTimer > 15 THEN
            ' Chain flash: 1 frame white (frame 16 only)
            PRINT AT #ExplosionPos, GRAM_EXPLOSION * 8 + COL_WHITE + $0800
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
    END IF

    ' Chain explosion rendering (bomb alien blast radius)
    IF BombExpTimer > 0 THEN
        BombExpTimer = BombExpTimer - 1
        ' Determine explosion frame — flash red/white every frame
        IF BombExpTimer > 13 THEN
            AlienCard = GRAM_EXPLOSION
        ELSEIF BombExpTimer > 6 THEN
            AlienCard = GRAM_EXPLOSION2
        ELSE
            AlienCard = GRAM_EXPLOSION3
        END IF
        IF BombExpTimer AND 1 THEN
            AlienColor = COL_RED
        ELSE
            AlienColor = COL_WHITE
        END IF
        ' Draw explosion on all cells in blast radius (4 cols × 3 rows)
        FOR Row = BombExpRow - 1 TO BombExpRow + 1
            IF Row >= 0 THEN
            IF Row < ALIEN_ROWS THEN
                #ScreenPos = (ALIEN_START_Y + AlienOffsetY + Row) * 20
                FOR Col = BombExpCol - 1 TO BombExpCol + 2
                    IF Col >= 0 THEN
                    IF Col < ALIEN_COLS THEN
                        IF BombExpTimer > 0 THEN
                            PRINT AT #ScreenPos + ALIEN_START_X + AlienOffsetX + Col, AlienCard * 8 + AlienColor + $0800
                        ELSE
                            PRINT AT #ScreenPos + ALIEN_START_X + AlienOffsetX + Col, 0
                        END IF
                    END IF
                    END IF
                NEXT Col
            END IF
            END IF
        NEXT Row
    END IF

    ' Chain reaction laser SFX decay (takes priority over regular SFX)
    IF ChainTimer > 0 THEN
        ChainTimer = ChainTimer - 1
        #ChainFreq1 = #ChainFreq1 + 10
        #ChainFreq2 = #ChainFreq2 + 6
        IF (ChainTimer AND 1) = 0 THEN
            IF #ChainVol > 0 THEN #ChainVol = #ChainVol - 1
        END IF
        POKE $1F7, 12 + (24 - ChainTimer) / 3
        SOUND 0, #ChainFreq1, #ChainVol
        SOUND 2, #ChainFreq2, #ChainVol
        IF ChainTimer = 0 THEN
            ' SFX done — silence and restart music
            SOUND 0, 0, 0
            SOUND 2, 0, 0
            POKE $1F8, $3F
            SfxVolume = 0 : SfxType = 0
            PLAY SIMPLE
            PLAY VOLUME 12
            ON MusicGear GOTO ChainGearMid, ChainGearFast, ChainGearPanic
            PLAY si_bg_slow
            GOTO ChainDone
ChainGearMid:
            PLAY si_bg_mid
            GOTO ChainDone
ChainGearFast:
            PLAY si_bg_fast
            GOTO ChainDone
ChainGearPanic:
            PLAY si_bg_panic
ChainDone:
        END IF
    END IF

    ' Update explosion sound effect (noise decay)
    GOSUB UpdateSfx

    ' Update flying saucer
    GOSUB UpdateSaucer

    ' Update power-up drop/pickup
    GOSUB UpdatePowerUp

    ' Update rogue alien
    IF RogueState = ROGUE_IDLE THEN
        RogueTimer = RogueTimer + 1
        IF RogueTimer >= ROGUE_COOLDOWN THEN
            RogueTimer = 0
            IF DeathTimer = 0 THEN
                IF WaveRevealCol >= ALIEN_COLS - 1 THEN
                    IF RANDOM(ROGUE_CHANCE) = 0 THEN
                        GOSUB RoguePickAlien
                    END IF
                END IF
            END IF
        END IF
    ELSE
        GOSUB RogueUpdate
    END IF

    ' Check bullet-vs-bullet collision (PARRY - tight hitbox, high reward)
    IF #GameFlags AND FLAG_BULLET THEN
        IF #GameFlags AND FLAG_ABULLET THEN
            ' Tight hitbox: X within 3 pixels, Y within 4 pixels (skill shot!)
            IF BulletX >= ABulletX - 3 THEN
                IF BulletX <= ABulletX + 3 THEN
                    IF BulletY >= ABulletY - 4 THEN
                        IF BulletY <= ABulletY + 4 THEN
                            ' PARRY! Bullets collide - destroy both
                            #GameFlags = #GameFlags AND $FFFC  ' Clear FLAG_BULLET + FLAG_ABULLET
                            #GameFlags = #GameFlags OR FLAG_SHOTLAND  ' Parry counts as a successful hit — chain preserved
                            SPRITE SPR_PBULLET, 0, 0, 0
                            SPRITE SPR_ABULLET, 0, 0, 0
                            ' Skill bonus for the risky parry
                            #Score = #Score + 25
                            ' Bright zap SFX (type 6)
                            SfxType = 6 : SfxVolume = 15 : #SfxPitch = 60
                        END IF
                    END IF
                END IF
            END IF
        END IF
    END IF

    ' Check player bullet vs rogue alien
    IF #GameFlags AND FLAG_BULLET THEN
        IF RogueState = ROGUE_DIVE THEN
            IF BulletY >= RogueY - 4 THEN
                IF BulletY <= RogueY + 8 THEN
                    IF BulletX >= RogueX - 4 THEN
                        IF BulletX <= RogueX + 10 THEN
                            #GameFlags = #GameFlags AND $FFFE
                            SPRITE SPR_PBULLET, 0, 0, 0
                            RogueState = ROGUE_IDLE
                            RogueTimer = 0 : RogueDivePhase = 0
                            SPRITE SPR_FLYER, 0, 0, 0
                            #Score = #Score + 50
                            #GameFlags = #GameFlags OR FLAG_SHOTLAND
                            ChainCount = ChainCount + 1
                            IF ChainCount > ChainMax THEN ChainMax = ChainCount
                            IF ChainCount > 50 THEN ChainCount = 50
                            ChainTimeout = 90
                            SfxType = 1 : SfxVolume = 14 : #SfxPitch = 180
                            SOUND 2, 180, 14
                            ' Show explosion at rogue position
                            IF ExplosionTimer > 0 THEN
                                IF #ExplosionPos < 220 THEN PRINT AT #ExplosionPos, 0
                            END IF
                            #ExplosionPos = (RogueY - 8) / 8 * 20 + (RogueX - 8) / 8
                            IF #ExplosionPos < 220 THEN
                                IF ChainCount >= 2 THEN
                                    ExplosionTimer = 16
                                    PRINT AT #ExplosionPos, GRAM_EXPLOSION * 8 + COL_WHITE + $0800
                                ELSE
                                    ExplosionTimer = 15
                                    PRINT AT #ExplosionPos, GRAM_EXPLOSION * 8 + 4 + $1800
                                END IF
                            END IF
                        END IF
                    END IF
                END IF
            END IF
        END IF
    END IF

    ' Check if player was hit (only if not already dying or invincible)
    IF #GameFlags AND FLAG_PLAYERHIT THEN
        IF DeathTimer = 0 THEN
            IF Invincible = 0 THEN
                #GameFlags = #GameFlags AND $FFEF
                Lives = Lives - 1
                GOSUB UpdateLivesHUD
                ' Lose all power-ups on death (mega laser too)
                BeamTimer = 0 : RapidTimer = 0
                #GameFlags = #GameFlags AND ($FFFF XOR FLAG_DUAL) : #MegaTimer = 0 : ShieldHits = 0
                #GameFlags = #GameFlags AND $FFFC  ' Clear FLAG_BULLET + FLAG_ABULLET
                SPRITE SPR_PBULLET, 0, 0, 0
                ' Clear wingman and any active capsule (dies with player)
                #GameFlags = #GameFlags AND $FFF3  ' Clear FLAG_CAPTURE + FLAG_CAPBULLET
                SPRITE SPR_POWERUP, 0, 0, 0
                TitleFrame = 0  ' Cancel any falling/landed capsule
                ' Rogue: if diving, let it complete escape animation; otherwise clear it
                IF RogueState <> ROGUE_DIVE THEN
                    RogueState = 0 : RogueTimer = 0 : RogueDivePhase = 0
                    SPRITE SPR_FLYER, 0, 0, 0
                END IF
                IF Lives = 0 THEN
                    ' Pre-game-over: play death explosion, then aliens crawl
                    GameOver = 3
                    DeathTimer = 75
                    ShakeTimer = 30
                    SPRITE SPR_PLAYER, 0, 0, 0
                ELSE
                    ' Start death sequence (75 frames = 1.25 seconds)
                    DeathTimer = 75
                    ShakeTimer = 30
                    SPRITE SPR_PLAYER, 0, 0, 0
                END IF
            ELSE
                #GameFlags = #GameFlags AND $FFEF
            END IF
        ELSE
            #GameFlags = #GameFlags AND $FFEF
        END IF
    END IF

    ' Handle death timer (respawn after death)
    IF DeathTimer > 0 THEN
        DeathTimer = DeathTimer - 1
        ' Invasion reset: after 30-frame freeze, clear and reposition aliens
        IF DeathTimer = 75 THEN
            IF GameOver = 0 THEN
                ' Clear alien area
                FOR Row = 1 TO 10
                    #ScreenPos = Row * 20
                    FOR Col = 0 TO 19
                        PRINT AT #ScreenPos + Col, 0
                    NEXT Col
                NEXT Row
                ' Reset alien formation to middle of screen
                AlienOffsetY = 2  ' Rows 3-7 instead of 1-5
                LastClearedY = 0
                AlienOffsetX = 0
                AlienDir = 1
                MarchCount = 0
                ' Redraw aliens at new position
                GOSUB DrawAliens
            END IF
        END IF
        IF DeathTimer = 0 THEN
            IF GameOver = 3 THEN
                ' Explosion done — let aliens crawl for 1 more second
                DeathTimer = 60
                GameOver = 4
            ELSEIF GameOver = 4 THEN
                ' Alien crawl done — fancy Game Over screen
                #GameFlags = #GameFlags AND $FFF3  ' Clear FLAG_CAPTURE + FLAG_CAPBULLET
                GOSUB SilenceSfx
                ' Game-over music: intensity matches how far the player got
                IF Level >= 5 THEN
                    PLAY si_dnb_panic
                ELSEIF Level >= 3 THEN
                    PLAY si_dnb_fast
                ELSEIF Level >= 2 THEN
                    PLAY si_dnb_mid
                ELSE
                    PLAY si_dnb_slow
                END IF
                ShakeTimer = 0
                SCROLL 0, 0
                CLS
                GOSUB HideAllSprites
                ' Update high score
                IF #Score > #HighScore THEN #HighScore = #Score
                ' Reload title font for game over screen (powerup HUD overwrote it)
                DEFINE GRAM_FONT_S, 4, FontSGfx  ' Cards 25-28: S, P, A, C
                WAIT
                DEFINE GRAM_FONT_E, 4, FontEGfx  ' Cards 29-32: E, I, N, T
                WAIT
                DEFINE GRAM_FONT_R, 4, FontRGfx  ' Cards 33-36: R, U, D, F
                WAIT
                DEFINE GRAM_FONT_G, 2, FontGGfx  ' Cards 37-38: G, M
                WAIT
                DEFINE GRAM_FONT_O, 2, FontOGfx  ' Cards 40-41: O, V
                WAIT
                DEFINE GRAM_SPARK_UP, 4, SparkUpGfx  ' Cards 21-24: restore sparks (silhouette overwrote)
                WAIT
                ' Load animated frames for A, E, R (reuse title animation GRAM slots)
                ' A frames: full, 60°, edge (cards 6-8)
                DEFINE TGRAM_A, 1, FontAY1Gfx : WAIT
                DEFINE TGRAM_A + 1, 1, FontAY3Gfx : WAIT
                DEFINE TGRAM_A + 2, 1, FontAY4Gfx : WAIT
                ' E frames: full, 60°, edge (cards 16-18)
                DEFINE TGRAM_E, 1, FontEY1Gfx : WAIT
                DEFINE TGRAM_E + 1, 1, FontEY3Gfx : WAIT
                DEFINE TGRAM_E + 2, 1, FontEY4Gfx : WAIT
                ' R frames: full, 60°, edge (cards 48-50)
                DEFINE TGRAM_R, 1, FontRY1Gfx : WAIT
                DEFINE TGRAM_R + 1, 1, FontRY3Gfx : WAIT
                DEFINE TGRAM_R + 2, 1, FontRY4Gfx : WAIT
                ' G frames: full, 60°, edge (cards 0-2)
                DEFINE TGRAM_G, 1, FontGY1Gfx : WAIT
                DEFINE TGRAM_G + 1, 1, FontGY3Gfx : WAIT
                DEFINE TGRAM_G + 2, 1, FontGY4Gfx : WAIT
                ' M frames: full, 60°, edge (cards 3-5)
                DEFINE TGRAM_M, 1, FontMY1Gfx : WAIT
                DEFINE TGRAM_M + 1, 1, FontMY3Gfx : WAIT
                DEFINE TGRAM_M + 2, 1, FontMY4Gfx : WAIT
                ' O frames: full, 60°, edge (cards 51-53)
                DEFINE TGRAM_O, 1, FontOY1Gfx : WAIT
                DEFINE TGRAM_O + 1, 1, FontOY3Gfx : WAIT
                DEFINE TGRAM_O + 2, 1, FontOY4Gfx : WAIT
                ' V frames: full, 60°, edge (cards 54-56)
                DEFINE TGRAM_V, 1, FontVY1Gfx : WAIT
                DEFINE TGRAM_V + 1, 1, FontVY3Gfx : WAIT
                DEFINE TGRAM_V + 2, 1, FontVY4Gfx : WAIT
                ' Initialize game over letter animation
                GOAnimIdx = 8 : GOAnimFrame = 0 : MarchCount = 0
                ' "GAME OVER" in custom font at row 2 col 5, centered
                PRINT AT 45, GRAM_FONT_G * 8 + COL_TAN + $0800
                PRINT AT 46, GRAM_FONT_A * 8 + COL_TAN + $0800
                PRINT AT 47, GRAM_FONT_M * 8 + COL_TAN + $0800
                PRINT AT 48, GRAM_FONT_E * 8 + COL_TAN + $0800
                PRINT AT 50, GRAM_FONT_O * 8 + COL_TAN + $0800
                PRINT AT 51, GRAM_FONT_V * 8 + COL_TAN + $0800
                PRINT AT 52, GRAM_FONT_E * 8 + COL_TAN + $0800
                PRINT AT 53, GRAM_FONT_R * 8 + COL_TAN + $0800
                ' Score at row 5, centered using compact GRAM tiles
                PRINT AT 106, GRAM_SCORE_SC * 8 + COL_WHITE + $0800
                PRINT AT 107, GRAM_SCORE_OR * 8 + COL_WHITE + $0800
                PRINT AT 108, GRAM_SCORE_E * 8 + COL_WHITE + $0800
                PRINT AT 110 COLOR COL_WHITE, <>#Score
                ' High score at row 6 (centered under score)
                IF #Score >= #HighScore THEN
                    PRINT AT 125 COLOR COL_YELLOW, "NEW HIGH!"
                ELSE
                    PRINT AT 122 COLOR COL_YELLOW, "HIGH SCORE "
                    PRINT AT 133, <>#HighScore
                END IF
                ' Best chain at row 7 (if achieved a chain)
                IF ChainMax > 1 THEN
                    PRINT AT 143 COLOR COL_BLUE, "BEST CHAIN "
                    PRINT AT 154, <>ChainMax
                END IF
                ' "PRESS FIRE" at row 10, centered using custom font
                PRINT AT 205, GRAM_FONT_P * 8 + COL_WHITE + $0800
                PRINT AT 206, GRAM_FONT_R * 8 + COL_WHITE + $0800
                PRINT AT 207, GRAM_FONT_E * 8 + COL_WHITE + $0800
                PRINT AT 208, GRAM_FONT_S * 8 + COL_WHITE + $0800
                PRINT AT 209, GRAM_FONT_S * 8 + COL_WHITE + $0800
                PRINT AT 211, GRAM_FONT_F * 8 + COL_WHITE + $0800
                PRINT AT 212, GRAM_FONT_I * 8 + COL_WHITE + $0800
                PRINT AT 213, GRAM_FONT_R * 8 + COL_WHITE + $0800
                PRINT AT 214, GRAM_FONT_E * 8 + COL_WHITE + $0800
                ' Voice announcement
                IF VOICE.AVAILABLE THEN
                    VOICE PLAY game_over_phrase
                END IF
                ' Initialize bolt sweep effect
                TitleJitter = 0
                TitleMarchX = 0
                WavePhase = 0
                TitleColor = 0
                ' Initialize Zod via flight engine (sweep in from right)
                FlyX = 168 : FlyY = 1
                FlyFrame = 0 : FlyColor = COL_WHITE
                FlyColorIdx = 0 : FlyColorTimer = 0
                FlyColors(0) = 7 : FlyColors(1) = 6 : FlyColors(2) = 5
                FlyColors(3) = 3 : FlyColors(4) = 5 : FlyColors(5) = 6
                LoopVar = PAT_DIAMOND
                GOSUB FlightStart
                GameOver = 5
                GOTO GameLoop
            ELSE
                ' Normal respawn at center with invincibility
                PlayerX = 80
                GOSUB ShipReveal
                Invincible = 120
            END IF
        END IF
    END IF

    ' Handle invincibility countdown
    IF Invincible > 0 THEN
        Invincible = Invincible - 1
    END IF

    ' (Explosion sound decay now handled by UpdateSfx)

    ' Check if all aliens are dead (wave win)
    GOSUB CheckWaveWin

    ' Tick down power-up timers
    ' Beam, Rapid, Dual persist until death (no countdown)
    ' Only MegaTimer counts down (5-second window)
    IF TitleJitter > 0 THEN
        TitleJitter = TitleJitter - 1
    END IF
    IF #MegaTimer > 0 THEN
        #MegaTimer = #MegaTimer - 1
    END IF

    ' Update powerup HUD indicator (positions 233-234, yellow color)
    IF BeamTimer > 0 THEN
        PRINT AT 233, GRAM_PWR_BE * 8 + COL_YELLOW + $0800
        PRINT AT 234, GRAM_PWR_AM * 8 + COL_YELLOW + $0800
    ELSEIF RapidTimer > 0 THEN
        PRINT AT 233, GRAM_PWR_RP * 8 + COL_YELLOW + $0800
        PRINT AT 234, GRAM_PWR_ID * 8 + COL_YELLOW + $0800
    ELSEIF #GameFlags AND FLAG_DUAL THEN
        PRINT AT 233, GRAM_PWR_QU * 8 + COL_YELLOW + $0800
        PRINT AT 234, GRAM_PWR_AD * 8 + COL_YELLOW + $0800
    ELSEIF #MegaTimer > 0 THEN
        PRINT AT 233, GRAM_PWR_ME * 8 + COL_YELLOW + $0800
        PRINT AT 234, GRAM_PWR_GA * 8 + COL_YELLOW + $0800
    ELSE
        ' No powerup active - clear indicator
        PRINT AT 233, 0 : PRINT AT 234, 0
    END IF

    ' Mega beam display countdown + sweep-up from turret + color cycling
    ' Beam follows ship movement and kills aliens it sweeps over
    IF MegaBeamTimer > 0 THEN
        MegaBeamTimer = MegaBeamTimer - 1
        ' Clear old beam column before updating position
        FOR LoopVar = 0 TO 9
            #ScreenPos = LoopVar * 20 + MegaBeamCol
            PRINT AT #ScreenPos, 0
        NEXT LoopVar
        ' Track ship position: recalculate beam column each frame
        ' Sprite-to-BACKTAB offset: col = (spriteX - 8) / 8, centered on ship (+4)
        MegaBeamCol = (PlayerX - 4) / 8
        IF MegaBeamCol > 19 THEN MegaBeamCol = 19
        ' Kill aliens in new column position
        GOSUB MegaBeamKill
        ' Calculate beam top row: sweeps UP from row 9 (at ship turret)
        ' Frames elapsed = 20 - MegaBeamTimer. Sweep 2 rows/frame.
        Col = (20 - MegaBeamTimer) * 2
        IF Col > 9 THEN Col = 9
        Col = 9 - Col
        ' Color cycle: white → yellow → red
        IF MegaBeamTimer > 13 THEN
            AlienColor = COL_WHITE
        ELSEIF MegaBeamTimer > 6 THEN
            AlienColor = COL_YELLOW
        ELSE
            AlienColor = COL_RED
        END IF
        ' Draw beam from top row (Col) down to row 9 (at ship turret)
        FOR LoopVar = Col TO 9
            #ScreenPos = LoopVar * 20 + MegaBeamCol
            PRINT AT #ScreenPos, GRAM_MEGA_BEAM * 8 + AlienColor + $0800
        NEXT LoopVar
        IF MegaBeamTimer = 0 THEN
            GOSUB MegaBeamClear
        END IF
    END IF

    ' Update sprites
    GOSUB DrawPlayer
    GOSUB DrawBullet
    GOSUB DrawAlienBullet

    ' Update score display (position 229+ in new HUD layout)
    PRINT AT 223 COLOR COL_WHITE, <>#Score

    ' Extra life: first at 1000, then every 5000
    IF #Score >= #NextLife THEN
        #NextLife = #NextLife + 5000
        IF Lives < 9 THEN
            Lives = Lives + 1
            GOSUB UpdateLivesHUD
            ' Announce extra life
            IF VOICE.AVAILABLE THEN
                VOICE PLAY extra_life_phrase
            END IF
        END IF
    END IF

    ' Tutorial message: "GET THE POWERUP!" (flashing, first drop only)
    ' TutorialTimer: 255=ready, 1-254=showing, 0=done
    IF TutorialTimer > 0 AND TutorialTimer < 255 THEN
        TutorialTimer = TutorialTimer - 1
        IF TutorialTimer = 0 THEN
            ' Clear message when timer expires
            PRINT AT 180, "                    "
        ELSE
            ' Flash every 4 frames (2 on, 2 off) - row 9 centered
            IF TutorialTimer AND 2 THEN
                PRINT AT 182 COLOR 6, "GET THE POWERUP!"
            ELSE
                PRINT AT 180, "                    "
            END IF
        END IF
    ELSE
        ' Chain timeout: goes cold after 1.5 sec (90 frames) without a kill
        IF ChainCount > 0 THEN
            IF ChainTimeout > 0 THEN
                ChainTimeout = ChainTimeout - 1
            ELSE
                ChainCount = 0  ' Timeout — chain goes cold
            END IF
        END IF
        ' Chain counter display: grey when inactive, blue when active
        IF ChainCount = 0 THEN
            ' Grey label + hyphen for inactive chain
            PRINT AT 228, GRAM_CHAIN_CH * 8 + $1800
            PRINT AT 229, GRAM_CHAIN_AI * 8 + $1800
            PRINT AT 230, GRAM_CHAIN_N * 8 + $1800
            PRINT AT 231, 111                        ' GROM hyphen
            PRINT AT 232, 0                          ' Clear second digit slot
        ELSE
            ' Blue label + count for active chain
            PRINT AT 228, GRAM_CHAIN_CH * 8 + COL_BLUE + $0800
            PRINT AT 229, GRAM_CHAIN_AI * 8 + COL_BLUE + $0800
            PRINT AT 230, GRAM_CHAIN_N * 8 + COL_BLUE + $0800
            PRINT AT 231 COLOR COL_BLUE, <>ChainCount
            ' Clear trailing digit when count shrinks (10->9)
            IF ChainCount < 10 THEN
                PRINT AT 232, 0
            END IF
        END IF
    END IF

    ' Parallax silhouette scroll on row 0 (every 10 frames)
    IF GameOver = 0 THEN
        StarTimer = StarTimer + 1
        IF StarTimer >= 10 THEN
            StarTimer = 0
            SilhOffset = SilhOffset + 1
            IF SilhOffset >= SILH_MAP_LEN THEN SilhOffset = 0
            GOSUB DrawSilhouette
        END IF
    END IF

    ' Debug mode: end CPU profiling — black border shows idle time
    IF #GameFlags AND FLAG_DEBUG THEN BORDER 0

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

    ' Keypad 1: toggle auto-fire (with debounce)
    IF CONT.KEY = 1 THEN
        IF Key1Held = 0 THEN
            Key1Held = 1
            #GameFlags = #GameFlags XOR FLAG_AUTOFIRE
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
    IF CONT.KEY = 0 THEN
        IF (#GameFlags AND FLAG_KEY0HELD) = 0 THEN
            #GameFlags = #GameFlags OR FLAG_KEY0HELD
            IF RogueDivePhase = 254 THEN
                IF (#GameFlags AND FLAG_CAPTURE) = 0 THEN
                    ' Capture the rogue alien as wingman
                    #GameFlags = #GameFlags OR FLAG_CAPTURE
                    CaptureColor = RogueColor
                    CaptureStep = 0
                    CaptureTimer = CAPTURE_FIRE_RATE
                    CaptureWaves = 0
                    ' Cancel rogue — it's now captured
                    RogueState = ROGUE_IDLE
                    RogueTimer = 0
                    SPRITE SPR_FLYER, 0, 0, 0
                    ' Capture SFX: rising tone
                    SfxType = 2 : SfxVolume = 14 : #SfxPitch = 400
                    SOUND 2, 400, 14
                END IF
            END IF
        END IF
    ELSE
        #GameFlags = #GameFlags AND $EFFF  ' Clear FLAG_KEY0HELD
    END IF

    ' Fire: side buttons (not keypad) or auto-fire
    IF CONT.BUTTON OR (#GameFlags AND FLAG_AUTOFIRE) THEN
    IF CONT.KEY >= 12 OR (#GameFlags AND FLAG_AUTOFIRE) THEN
        IF #MegaTimer > 0 THEN
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
                POKE $1F7, 8
                POKE $1F8, PEEK($1F8) AND $DF
            END IF
        ELSEIF #GameFlags AND FLAG_DUAL THEN
            ' Quad laser: single center bullet with wide hitbox
            IF (#GameFlags AND FLAG_BULLET) = 0 THEN
                BulletX = PlayerX  ' Align with turret (drawn at BulletX, 8px wide)
                BulletY = PLAYER_Y - 4
                #GameFlags = #GameFlags OR FLAG_BULLET
                #GameFlags = #GameFlags AND $FFDF     ' New shot — hasn't hit anything yet
                ' Quad laser SFX: rising burst energy weapon
                SfxType = 8 : SfxVolume = 14 : #SfxPitch = 500
                SOUND 2, 500, 14
            END IF
        ELSE
            ' Normal/beam/rapid: single center shot
            IF (#GameFlags AND FLAG_BULLET) = 0 THEN
                IF TitleJitter = 0 THEN
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
                        #ChainVol = 15
                        POKE $1F7, 12
                        POKE $1F8, $18
                        SOUND 0, 150, 14
                        SOUND 2, 80, 15
                    ELSE
                        ' Pea shooter SFX: descending laser zap
                        SfxType = 7 : SfxVolume = 14 : #SfxPitch = 150
                        SOUND 2, 150, 14
                    END IF
                    IF RapidTimer > 0 THEN
                        TitleJitter = RAPID_COOLDOWN
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
    ' Check collision FIRST at current position (so bullet is visible at hit point)
    GOSUB CheckBulletHit

    ' Then move bullet up (rapid fire = 3px, dual = 2px, normal = 1.25px)
    IF #GameFlags AND FLAG_BULLET THEN
        IF RapidTimer > 0 THEN
            IF BulletY > BULLET_TOP + RAPID_SPEED THEN
                BulletY = BulletY - RAPID_SPEED
            ELSE
                #GameFlags = #GameFlags AND $FFFE
                IF #GameFlags = #GameFlags AND $FFDF THEN ChainCount = 0   ' Whiff — break chain
            END IF
        ELSEIF (#GameFlags AND FLAG_DUAL) OR BeamTimer > 0 THEN
            ' Quad laser / beam: flat 2px/frame
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
            ELSEIF #GameFlags AND FLAG_DUAL THEN
                ' Quad laser: 4 columns centered on sprite (32px kill zone)
                IF BulletX >= 12 THEN
                    HitCol = (BulletX - 12) / 8
                    GOSUB CheckOneColumn
                END IF

                IF #GameFlags AND FLAG_BULLET THEN
                    HitCol = (BulletX - 4) / 8
                    GOSUB CheckOneColumn
                END IF

                IF #GameFlags AND FLAG_BULLET THEN
                    HitCol = (BulletX + 4) / 8
                    GOSUB CheckOneColumn
                END IF

                IF #GameFlags AND FLAG_BULLET THEN
                    HitCol = (BulletX + 12) / 8
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

' --------------------------------------------
' BombExplode - Chain explosion when bomb alien dies
' Expects: FoundBoss = the bomb's slot index (already HP=0)
' Kills all aliens in 4-wide × 3-tall blast radius
' --------------------------------------------
BombExplode: PROCEDURE
    ' Save bomb position for chain explosion rendering
    BombExpRow = BossRow(FoundBoss)
    BombExpCol = BossCol(FoundBoss)
    BombExpTimer = 20

    ' XOR out bomb's own two columns
    #Mask = ColMaskData(BombExpCol)
    #AlienRow(BombExpRow) = #AlienRow(BombExpRow) XOR #Mask
    #Mask = ColMaskData(BombExpCol + 1)
    #AlienRow(BombExpRow) = #AlienRow(BombExpRow) XOR #Mask

    ' --- OPTIMIZATION: Pre-scan bosses in blast radius (4 checks vs 48) ---
    ' Check each boss once; if in blast radius, kill it now
    FOR LoopVar = 0 TO BossCount - 1
        IF BossHP(LoopVar) > 0 THEN
            ' Check if boss row is in blast radius (BombExpRow-1 to BombExpRow+1)
            IF BossRow(LoopVar) >= BombExpRow - 1 THEN
            IF BossRow(LoopVar) <= BombExpRow + 1 THEN
                ' Check if boss columns overlap blast radius (BombExpCol-1 to BombExpCol+2)
                ' Boss occupies BossCol and BossCol+1
                IF BossCol(LoopVar) + 1 >= BombExpCol - 1 THEN
                IF BossCol(LoopVar) <= BombExpCol + 2 THEN
                    ' Boss is in blast radius - kill it
                    Row = BossRow(LoopVar)
                    Col = BossCol(LoopVar)
                    BossHP(LoopVar) = 0
                    ' XOR out both boss columns from alien grid
                    #AlienRow(Row) = #AlienRow(Row) XOR ColMaskData(Col)
                    #AlienRow(Row) = #AlienRow(Row) XOR ColMaskData(Col + 1)
                    #Score = #Score + 10
                END IF
                END IF
            END IF
            END IF
        END IF
    NEXT LoopVar

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
                                #Score = #Score + 10
                            END IF
                        END IF
                    ELSE
                        ' Different row — kill regular alien
                        #Mask = ColMaskData(Col)
                        IF #AlienRow(Row) AND #Mask THEN
                            #AlienRow(Row) = #AlienRow(Row) XOR #Mask
                            #Score = #Score + 10
                        END IF
                    END IF
                END IF
                END IF
            NEXT Col
        END IF
        END IF
    NEXT Row

    ' Score for bomb itself
    #Score = #Score + BOMB_SCORE

    ' Big SFX (white noise boom, same as ship explosion)
    SfxType = 5 : SfxVolume = 15 : #SfxPitch = 0
    SOUND 2, 0, 15

    ' Screen shake for the explosion
    ShakeTimer = 20

    RETURN
END

    SEGMENT 2   ' Move CheckOneColumn+ to Segment 2 (Seg 1 full after Phase B)

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
                ' Multi-boss intercept (inlined FindBoss for speed)
                FoundBoss = 255
                IF BossCount > 0 THEN
                    FOR LoopVar = 0 TO BossCount - 1
                        IF BossHP(LoopVar) > 0 THEN
                            IF AlienGridRow = BossRow(LoopVar) THEN
                                IF AlienGridCol = BossCol(LoopVar) OR AlienGridCol = BossCol(LoopVar) + 1 THEN
                                    FoundBoss = LoopVar
                                END IF
                            ELSEIF #GameFlags AND FLAG_HASLARGE THEN
                                ' Only check bottom-half match when a large alien exists
                                IF BossType(LoopVar) = LARGE_TYPE THEN
                                    IF AlienGridRow = BossRow(LoopVar) + 1 THEN
                                        IF AlienGridCol = BossCol(LoopVar) OR AlienGridCol = BossCol(LoopVar) + 1 THEN
                                            FoundBoss = LoopVar
                                        END IF
                                    END IF
                                END IF
                            END IF
                        END IF
                    NEXT LoopVar
                END IF
                IF FoundBoss < 255 THEN
                    BossHP(FoundBoss) = BossHP(FoundBoss) - 1
                    ' Beam: apply second hit to same boss if budget remains
                    IF BeamTimer > 0 THEN
                        BeamHits = BeamHits - 1
                        IF BeamHits > 0 THEN
                            IF BossHP(FoundBoss) > 0 THEN
                                BossHP(FoundBoss) = BossHP(FoundBoss) - 1
                                BeamHits = BeamHits - 1
                            END IF
                        END IF
                    END IF
                    IF BossHP(FoundBoss) > 0 THEN
                        ' Damaged but alive — stop bullet unless beam has hits left
                        IF BeamTimer = 0 OR BeamHits = 0 THEN
                            #GameFlags = #GameFlags AND $FFFE
                        END IF
                        #GameFlags = #GameFlags OR FLAG_SHOTLAND  ' Hit landed — chain preserved
                        IF BossHP(FoundBoss) = 2 THEN BossColor(FoundBoss) = COL_YELLOW
                        IF BossHP(FoundBoss) = 1 THEN BossColor(FoundBoss) = COL_RED
                        SfxType = 1 : SfxVolume = 14 : #SfxPitch = 120
                        SOUND 2, 120, 14
                        RETURN
                    ELSE
                        ' Boss dead! Check type
                        IF BossType(FoundBoss) = BOMB_TYPE THEN
                            ' Bomb alien — chain explosion!
                            IF BeamTimer = 0 OR BeamHits = 0 THEN
                                #GameFlags = #GameFlags AND $FFFE
                            END IF
                            #GameFlags = #GameFlags OR FLAG_SHOTLAND
                            ChainCount = ChainCount + 1  ' Bomb kill counts!
                            IF ChainCount > ChainMax THEN ChainMax = ChainCount
                            IF ChainCount > 50 THEN ChainCount = 50
                            ChainTimeout = 90
                            GOSUB BombExplode
                            RETURN
                        ELSEIF BossType(FoundBoss) = LARGE_TYPE THEN
                            ' Large 2x2 alien dead! Clear all 4 grid cells
                            ' Top row (BossRow): cols BossCol and BossCol+1
                            #AlienRow(BossRow(FoundBoss)) = #AlienRow(BossRow(FoundBoss)) XOR ColMaskData(BossCol(FoundBoss))
                            #AlienRow(BossRow(FoundBoss)) = #AlienRow(BossRow(FoundBoss)) XOR ColMaskData(BossCol(FoundBoss) + 1)
                            ' Bottom row (BossRow+1): cols BossCol and BossCol+1
                            Row = BossRow(FoundBoss) + 1
                            IF Row < ALIEN_ROWS THEN
                                #AlienRow(Row) = #AlienRow(Row) XOR ColMaskData(BossCol(FoundBoss))
                                #AlienRow(Row) = #AlienRow(Row) XOR ColMaskData(BossCol(FoundBoss) + 1)
                            END IF
                            ' Clear all 4 BACKTAB tiles
                            #ExplosionPos = (ALIEN_START_Y + AlienOffsetY + BossRow(FoundBoss)) * 20 + ALIEN_START_X + AlienOffsetX + BossCol(FoundBoss)
                            IF #ExplosionPos < 220 THEN PRINT AT #ExplosionPos, 0
                            IF #ExplosionPos + 1 < 220 THEN PRINT AT #ExplosionPos + 1, 0
                            IF #ExplosionPos + 20 < 220 THEN PRINT AT #ExplosionPos + 20, 0
                            IF #ExplosionPos + 21 < 220 THEN PRINT AT #ExplosionPos + 21, 0
                            ' Big score + explosion on all 4 tiles
                            #Score = #Score + BOSS_SCORE + BOSS_SCORE
                            IF BeamTimer = 0 OR BeamHits = 0 THEN
                                #GameFlags = #GameFlags AND $FFFE
                            END IF
                            #GameFlags = #GameFlags OR FLAG_SHOTLAND
                            ChainCount = ChainCount + 1
                            IF ChainCount > ChainMax THEN ChainMax = ChainCount
                            IF ChainCount > 50 THEN ChainCount = 50
                            ChainTimeout = 90
                            ExplosionTimer = 25
                            ' Show explosion on top-left and bottom-right for visual spread
                            IF #ExplosionPos < 220 THEN
                                PRINT AT #ExplosionPos, GRAM_EXPLOSION * 8 + COL_RED + $1800
                            END IF
                            IF #ExplosionPos + 21 < 220 THEN
                                PRINT AT #ExplosionPos + 21, GRAM_EXPLOSION * 8 + COL_RED + $1800
                            END IF
                            SfxType = 1 : SfxVolume = 15 : #SfxPitch = 60
                            SOUND 2, 60, 15
                            RETURN
                        ELSE
                            ' Skull boss dead! XOR BOTH columns out
                            #AlienRow(BossRow(FoundBoss)) = #AlienRow(BossRow(FoundBoss)) XOR ColMaskData(BossCol(FoundBoss))
                            #AlienRow(BossRow(FoundBoss)) = #AlienRow(BossRow(FoundBoss)) XOR ColMaskData(BossCol(FoundBoss) + 1)
                            ' Clear both BACKTAB tiles
                            #ExplosionPos = (ALIEN_START_Y + AlienOffsetY + BossRow(FoundBoss)) * 20 + ALIEN_START_X + AlienOffsetX + BossCol(FoundBoss)
                            IF #ExplosionPos < 220 THEN PRINT AT #ExplosionPos, 0
                            IF #ExplosionPos + 1 < 220 THEN PRINT AT #ExplosionPos + 1, 0
                            ' Big score + explosion
                            #Score = #Score + BOSS_SCORE
                            IF BeamTimer = 0 OR BeamHits = 0 THEN
                                #GameFlags = #GameFlags AND $FFFE
                            END IF
                            #GameFlags = #GameFlags OR FLAG_SHOTLAND
                            ChainCount = ChainCount + 1  ' Skull boss kill counts!
                            IF ChainCount > ChainMax THEN ChainMax = ChainCount
                            IF ChainCount > 50 THEN ChainCount = 50
                            ChainTimeout = 90
                            ExplosionTimer = 20
                            IF #ExplosionPos < 220 THEN
                                PRINT AT #ExplosionPos, GRAM_EXPLOSION * 8 + COL_RED + $1800
                            END IF
                            SfxType = 1 : SfxVolume = 15 : #SfxPitch = 80
                            SOUND 2, 80, 15
                            RETURN
                        END IF
                    END IF
                END IF

                ' Normal alien kill
                #AlienRow(AlienGridRow) = #AlienRow(AlienGridRow) XOR #Mask

                ' Beam: decrement pierce budget; stop when exhausted
                IF BeamTimer > 0 THEN
                    BeamHits = BeamHits - 1
                    IF BeamHits = 0 THEN #GameFlags = #GameFlags AND $FFFE
                ELSE
                    #GameFlags = #GameFlags AND $FFFE
                END IF

                ' Chain combo scoring: 10, 20, 30, 40, 50 (bonus capped at 50)
                #GameFlags = #GameFlags OR FLAG_SHOTLAND
                ChainCount = ChainCount + 1
                IF ChainCount > ChainMax THEN ChainMax = ChainCount
                IF ChainCount > 50 THEN ChainCount = 50
                ChainTimeout = 90
                ' Bonus caps at 50 points (chain 5+), but chain counter keeps growing for display
                IF ChainCount <= 5 THEN
                    #Score = #Score + ChainCount * 10
                ELSE
                    #Score = #Score + 50
                END IF

                ' Noise explosion SFX (short punchy crunch)
                SfxType = 1 : SfxVolume = 12 : #SfxPitch = 200
                SOUND 2, 200, 12  ' Immediate tone hit on channel 3

                ' Clear previous explosion tile if still active
                IF ExplosionTimer > 0 THEN
                    IF #ExplosionPos < 220 THEN PRINT AT #ExplosionPos, 0
                END IF
                ' Show explosion on BACKTAB (replaces alien, stays in place)
                #ExplosionPos = HitRow * 20 + HitCol
                IF #ExplosionPos < 220 THEN
                    IF ChainCount >= 2 THEN
                        ExplosionTimer = 16
                        PRINT AT #ExplosionPos, GRAM_EXPLOSION * 8 + COL_WHITE + $0800
                    ELSE
                        ExplosionTimer = 15
                        PRINT AT #ExplosionPos, GRAM_EXPLOSION * 8 + 4 + $1800
                    END IF
                END IF
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
            SPRITE SPR_PLAYER, PlayerX + $01FC, PLAYER_Y + 4, GRAM_EXPLOSION3 * 8 + 7 + $0800
            SPRITE SPR_SHIP_ACCENT, PlayerX + $0206, PLAYER_Y - 4, GRAM_EXPLOSION3 * 8 + 3 + $0800
        ELSEIF DeathTimer > 39 THEN
            ' Phase 4 - Fading embers: blink on/off (8 frames)
            IF DeathTimer AND 2 THEN
                SPRITE SPR_PLAYER, PlayerX + $0200, PLAYER_Y, GRAM_EXPLOSION3 * 8 + 3 + $0800
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
                    SPRITE SPR_SHIP_ACCENT, PlayerX + $0200, PLAYER_Y + $0100, GRAM_SHIELD * 8 + COL_YELLOW + $0800
                END IF
            ELSE
                SPRITE SPR_SHIP_ACCENT, PlayerX + $0200, PLAYER_Y + $0100, GRAM_SHIP_ACCENT * 8 + $1800
            END IF
        ELSE
            SPRITE SPR_PLAYER, 0, 0, 0
            SPRITE SPR_SHIP_ACCENT, 0, 0, 0
        END IF
    ELSE
        ' Normal display - body + accent sprite (DOUBLEY for 16px tall)
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
                ' Damaged shield - flash yellow/orange
                IF MarchCount AND 4 THEN
                    SPRITE SPR_SHIP_ACCENT, PlayerX + $0200, PLAYER_Y + $0100, GRAM_SHIELD * 8 + COL_YELLOW + $0800
                ELSE
                    ' Orange (10) is pastel: use (10 AND 7)=2 + $1800
                    SPRITE SPR_SHIP_ACCENT, PlayerX + $0200, PLAYER_Y + $0100, GRAM_SHIELD * 8 + 2 + $1800
                END IF
            END IF
        ELSE
            SPRITE SPR_SHIP_ACCENT, PlayerX + $0200, PLAYER_Y + $0100, GRAM_SHIP_ACCENT * 8 + $1800
        END IF
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
        ELSEIF #GameFlags AND FLAG_DUAL THEN
            ' Quad laser mode: 4-line pattern sprite
            SPRITE SPR_PBULLET, BulletX + $0200, BulletY, GRAM_QUAD * 8 + AlienColor + $0800
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
AlienShoot: PROCEDURE
    ' Saucer owns the bullet during chase
    IF FlyState = SAUCER_CHASE THEN RETURN
    ShootTimer = ShootTimer + 1
    IF ShootTimer >= ALIEN_SHOOT_RATE THEN
        ShootTimer = 0
        IF #GameFlags = #GameFlags AND $FFFD THEN
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
' Input: LoopVar = wave index (0-7)
' WaveEntranceData values: 0=left sweep, 1=top-down reveal, 2=fly-down from above
SetEntrancePattern: PROCEDURE
    ' Clear both entrance flags
    #GameFlags = #GameFlags AND $F3FF  ' Clear FLAG_TOPDOWN + FLAG_FLYDOWN
    WaveRevealCol = 0
    WaveRevealRow = 0
    HitRow = WaveEntranceData(LoopVar)
    IF HitRow = 1 THEN
        ' Top-down reveal: rows appear in place one at a time
        #GameFlags = #GameFlags OR FLAG_TOPDOWN
        WaveRevealCol = ALIEN_COLS - 1
        ' WaveRevealRow counts UP (0 to ALIEN_ROWS-1) for rows revealed
    ELSEIF HitRow = 2 THEN
        ' Fly-down: entire grid descends from above screen
        #GameFlags = #GameFlags OR FLAG_FLYDOWN
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
' MarchAliens - Move alien grid (dynamic boundaries)
' --------------------------------------------
MarchAliens: PROCEDURE
    ' Find leftmost and rightmost alive columns across all rows
    HitRow = ALIEN_COLS - 1       ' LeftmostCol: start high, find min
    LoopVar = 0                   ' RightmostCol: start low, find max
    FOR Row = 0 TO ALIEN_ROWS - 1
        IF #AlienRow(Row) THEN
            #Mask = 1
            FOR Col = 0 TO ALIEN_COLS - 1
                IF #AlienRow(Row) AND #Mask THEN
                    IF Col < HitRow THEN HitRow = Col
                    IF Col > LoopVar THEN LoopVar = Col
                END IF
                #Mask = #Mask + #Mask
            NEXT Col
        END IF
    NEXT Row

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
                    #ScreenPos = (ALIEN_START_Y + AlienOffsetY + Row) * 20
                    PRINT AT #ScreenPos + ALIEN_START_X + AlienOffsetX + Col, 0
                END IF
            NEXT Row
        NEXT Col
        ' Shift bitmasks so leftmost alive becomes column 0
        FOR Row = 0 TO ALIEN_ROWS - 1
            #AlienRow(Row) = #AlienRow(Row) / ColMaskData(HitRow)
        NEXT Row
        AlienOffsetX = AlienOffsetX + HitRow
        ' Adjust boss grid positions
        FOR LoopVar = 0 TO BossCount - 1
            IF BossHP(LoopVar) > 0 THEN
                BossCol(LoopVar) = BossCol(LoopVar) - HitRow
            END IF
        NEXT LoopVar
        ' Update boundaries after shift
        LoopVar = LoopVar - HitRow
        HitRow = 0
    END IF

    IF AlienDir = 1 THEN
        ' Moving right
        IF ALIEN_START_X + AlienOffsetX + LoopVar < 19 THEN
            ' Trail clearing handled by DrawAliens edge-clear (called after MarchAliens)
            AlienOffsetX = AlienOffsetX + 1
        ELSE
            ' Hit right edge - drop down and reverse
            AlienOffsetY = AlienOffsetY + 1
            AlienDir = 255
            ' Accelerate march + music on descent (balanced ramp)
            IF CurrentMarchSpeed > 6 THEN
                CurrentMarchSpeed = CurrentMarchSpeed - 6
            END IF
            GOSUB UpdateMusicGear
        END IF
    ELSE
        ' Moving left
        ' Guard: AlienOffsetX is unsigned 8-bit, can't go below 0
        IF AlienOffsetX > 0 THEN
            IF AlienOffsetX + HitRow > 0 THEN
                ' Trail clearing handled by DrawAliens edge-clear (called after MarchAliens)
                AlienOffsetX = AlienOffsetX - 1
            ELSE
                ' Hit left edge - drop down and reverse
                AlienOffsetY = AlienOffsetY + 1
                AlienDir = 1
                IF CurrentMarchSpeed > 6 THEN
                    CurrentMarchSpeed = CurrentMarchSpeed - 6
                END IF
                GOSUB UpdateMusicGear
            END IF
        ELSE
            ' AlienOffsetX = 0: reverse (can't represent negative offset)
            AlienOffsetY = AlienOffsetY + 1
            AlienDir = 1
            IF CurrentMarchSpeed > 6 THEN
                CurrentMarchSpeed = CurrentMarchSpeed - 6
            END IF
            GOSUB UpdateMusicGear
        END IF
    END IF
    RETURN
END

' --------------------------------------------
' UpdateMusicGear - Switch music tempo based on alien descent
' Called after each AlienOffsetY increment
' --------------------------------------------
UpdateMusicGear: PROCEDURE
    ' Calculate target gear from descent + wave
    IF Level >= 2 THEN
        ' Wave 2+: start at mid, escalate faster
        LoopVar = 1 + AlienOffsetY / 2
    ELSE
        ' Wave 1: start at slow, gradual buildup
        LoopVar = AlienOffsetY / 2
    END IF
    IF LoopVar > 3 THEN LoopVar = 3

    ' Only switch if gear changed
    IF LoopVar = MusicGear THEN RETURN
    MusicGear = LoopVar

    ON MusicGear GOTO GearMid, GearFast, GearPanic
    ' Gear 0 = slow (fallthrough)
    PLAY si_bg_slow
    RETURN
GearMid:
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
' UpdateLivesHUD - Show lives remaining (X tile at 236, number at 237)
' Replaces 4 identical IF/ELSEIF chains (invasion, death, extra life, wave start)
' --------------------------------------------
UpdateLivesHUD: PROCEDURE
    IF Lives > 0 THEN
        PRINT AT 238 COLOR COL_WHITE, <> (Lives - 1)
    END IF
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
    IF SfxVolume = 0 THEN RETURN

    ' All SFX on channel 3 (SOUND 2) to coexist with PLAY SIMPLE music
    SOUND 2, #SfxPitch, SfxVolume

    ' Decay based on type
    IF SfxType = 2 THEN
        ' Saucer crash: slow decay + descending pitch (sustained crunch)
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
                POKE $1F7, 14 + (75 - DeathTimer) / 4
            ELSE
                POKE $1F7, 14
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
        IF MegaBeamTimer > 0 THEN
            IF (MegaBeamTimer AND 3) = 0 THEN
                IF SfxVolume > 1 THEN SfxVolume = SfxVolume - 1
            END IF
            POKE $1F7, 8 + (20 - MegaBeamTimer) / 2
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
            ' Noise period deepens over time (14 → ~24)
            POKE $1F7, 14 + (20 - BombExpTimer) / 2
        ELSE
            SfxVolume = 0
        END IF
        ' Enable noise only on channel C (pure white noise)
        IF SfxVolume > 0 THEN
            POKE $1F8, PEEK($1F8) AND $DF ' Bit 5 clear: noise C on
        END IF
    ELSEIF SfxType = 6 THEN
        ' Parry: bright zap - fast ascending pitch + very fast decay
        #SfxPitch = #SfxPitch + 12
        IF SfxVolume > 3 THEN
            SfxVolume = SfxVolume - 3
        ELSE
            SfxVolume = 0
        END IF
    ELSEIF SfxType = 7 THEN
        ' Pea shooter: descending laser zap (pitch rises = lower tone)
        #SfxPitch = #SfxPitch + 15
        IF #SfxPitch > 800 THEN #SfxPitch = 800
        IF SfxVolume > 1 THEN
            SfxVolume = SfxVolume - 1
        ELSE
            SfxVolume = 0
        END IF
    ELSEIF SfxType = 8 THEN
        ' Quad laser: rising burst energy weapon (pitch descends = higher tone)
        IF #SfxPitch > 80 THEN #SfxPitch = #SfxPitch - 35
        IF #SfxPitch <= 115 THEN
            ' Near end of pitch rise, fast volume cut
            IF SfxVolume > 3 THEN
                SfxVolume = SfxVolume - 3
            ELSE
                SfxVolume = 0
            END IF
        END IF
    ELSEIF SfxType = 9 THEN
        ' Shield absorb: high-pitched ping with fast decay
        #SfxPitch = #SfxPitch + 50
        IF #SfxPitch > 1200 THEN #SfxPitch = 1200
        IF SfxVolume > 2 THEN
            SfxVolume = SfxVolume - 2
        ELSE
            SfxVolume = 0
        END IF
    ELSE
        ' Alien: fast decay (2 per frame)
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
' MegaBeamKill - Kill all aliens in the beam column
' --------------------------------------------
MegaBeamKill: PROCEDURE
    ' Kill aliens in beam column AND adjacent column (brutal 16px hitbox)
    FOR HitRow = 0 TO 1
        IF HitRow = 0 THEN
            HitCol = MegaBeamCol
        ELSE
            HitCol = MegaBeamCol + 1
        END IF
        IF HitCol >= ALIEN_START_X + AlienOffsetX THEN
            IF HitCol < ALIEN_START_X + AlienOffsetX + ALIEN_COLS THEN
                AlienGridCol = HitCol - ALIEN_START_X - AlienOffsetX
                IF AlienGridCol <= WaveRevealCol THEN
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
                                        IF BossHP(FoundBoss) = 2 THEN BossColor(FoundBoss) = COL_YELLOW
                                        IF BossHP(FoundBoss) = 1 THEN BossColor(FoundBoss) = COL_RED
                                    ELSE
                                        ' Boss dead! Check type
                                        IF BossType(FoundBoss) = BOMB_TYPE THEN
                                            ' Bomb alien — chain explosion!
                                            GOSUB BombExplode
                                        ELSE
                                            ' Skull boss dead! XOR both columns
                                            #AlienRow(BossRow(FoundBoss)) = #AlienRow(BossRow(FoundBoss)) XOR ColMaskData(BossCol(FoundBoss))
                                            #AlienRow(BossRow(FoundBoss)) = #AlienRow(BossRow(FoundBoss)) XOR ColMaskData(BossCol(FoundBoss) + 1)
                                            #Score = #Score + BOSS_SCORE
                                        END IF
                                        ' Restore #Mask for current column iteration
                                        #Mask = ColMaskData(AlienGridCol)
                                    END IF
                                END IF
                            ELSE
                                ' Normal alien kill
                                #AlienRow(LoopVar) = #AlienRow(LoopVar) XOR #Mask
                                ChainCount = ChainCount + 1
                                IF ChainCount > ChainMax THEN ChainMax = ChainCount
                                IF ChainCount > 50 THEN ChainCount = 50
                                ChainTimeout = 90
                                IF ChainCount > 5 THEN
                                    #Score = #Score + 50
                                ELSE
                                    #Score = #Score + ChainCount * 10
                                END IF
                            END IF
                            #ExplosionPos = (ALIEN_START_Y + AlienOffsetY + LoopVar) * 20 + HitCol
                            IF #ExplosionPos < 220 THEN
                                IF ChainCount >= 2 THEN
                                    PRINT AT #ExplosionPos, GRAM_EXPLOSION * 8 + COL_WHITE + $0800
                                ELSE
                                    PRINT AT #ExplosionPos, GRAM_EXPLOSION * 8 + 4 + $1800
                                END IF
                            END IF
                        END IF
                    NEXT LoopVar
                    IF ChainCount >= 2 THEN ExplosionTimer = 16 ELSE ExplosionTimer = 15
                END IF
            END IF
        END IF
    NEXT HitRow
    ' Kill saucer if beam overlaps it (beam = 16px from MegaBeamCol*8)
    IF FlyState > 0 THEN
        #ScreenPos = MegaBeamCol * 8
        ' Saucer spans FlyX to FlyX+15, beam spans #ScreenPos to #ScreenPos+15
        IF #ScreenPos + 15 >= FlyX THEN
            IF #ScreenPos <= FlyX + 15 THEN
                ' Destroy saucer
                GOSUB DeactivateSaucer
                SfxType = 2 : SfxVolume = 15 : #SfxPitch = 150
                SOUND 2, 150, 15
                #Score = #Score + 100
                ' Drop power-up from saucer position
                TitleFrame = 1
                TitleMarchDir = FlyX
                PowerUpY = FlyY
                SlidePos = 0
                ' Clear previous explosion tile if still active
                IF ExplosionTimer > 0 THEN
                    IF #ExplosionPos < 220 THEN PRINT AT #ExplosionPos, 0
                END IF
                #ExplosionPos = FlyX / 8
                ExplosionTimer = 15
                PRINT AT #ExplosionPos, GRAM_EXPLOSION * 8 + 4 + $1800
            END IF
        END IF
    END IF
    ' Kill rogue alien in dogfight if beam overlaps it
    IF RogueState = ROGUE_DIVE THEN
        #ScreenPos = MegaBeamCol * 8
        ' Rogue sprite is 8px wide at RogueX; beam is 16px wide at #ScreenPos
        IF #ScreenPos + 15 >= RogueX THEN
            IF #ScreenPos <= RogueX + 8 THEN
                ' Destroy rogue
                RogueState = ROGUE_IDLE
                RogueTimer = 0 : RogueDivePhase = 0
                SPRITE SPR_FLYER, 0, 0, 0
                #Score = #Score + 50
                #GameFlags = #GameFlags OR FLAG_SHOTLAND
                ChainCount = ChainCount + 1
                IF ChainCount > ChainMax THEN ChainMax = ChainCount
                IF ChainCount > 50 THEN ChainCount = 50
                ChainTimeout = 90
                SfxType = 1 : SfxVolume = 14 : #SfxPitch = 180
                SOUND 2, 180, 14
            END IF
        END IF
    END IF
    RETURN
END

' --------------------------------------------
' MegaBeamDraw - Draw beam column on BACKTAB (starts at row 8, above ship)
' --------------------------------------------
MegaBeamDraw: PROCEDURE
    ' Start with just the beam origin row (row 8, above ship turret)
    #ScreenPos = 8 * 20 + MegaBeamCol
    PRINT AT #ScreenPos, GRAM_MEGA_BEAM * 8 + COL_WHITE + $0800
    RETURN
END

' --------------------------------------------
' MegaBeamClear - Clear beam column from BACKTAB
' --------------------------------------------
MegaBeamClear: PROCEDURE
    FOR LoopVar = 0 TO 9
        #ScreenPos = LoopVar * 20 + MegaBeamCol
        PRINT AT #ScreenPos, 0
    NEXT LoopVar
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
        TitleGridCol = COL_BLUE      ' Beam: blue/white
        TitleMarchCount = COL_WHITE
    ELSEIF TitleColor = 1 THEN
        TitleGridCol = COL_YELLOW    ' Rapid: yellow/green
        TitleMarchCount = COL_GREEN
    ELSEIF TitleColor = 2 THEN
        TitleGridCol = COL_WHITE     ' Dual: white/tan
        TitleMarchCount = COL_TAN
    ELSEIF TitleColor = 3 THEN
        TitleGridCol = COL_RED       ' Mega: red/tan
        TitleMarchCount = COL_TAN
    ELSE
        TitleGridCol = COL_CYAN      ' Shield: cyan/blue
        TitleMarchCount = COL_BLUE
    END IF

    IF TitleFrame = 1 THEN
        ' Falling: move down 2px per frame
        PowerUpY = PowerUpY + 2
        IF PowerUpY >= PLAYER_Y THEN
            ' Landed at player level
            PowerUpY = PLAYER_Y
            TitleFrame = 2
            #PowerTimer = 300   ' 5 seconds to pick up
            SlidePos = 0
        END IF
        ' Draw falling capsule (animated frame + color flash)
        SlidePos = SlidePos + 1
        IF SlidePos >= 8 THEN SlidePos = 0
        IF SlidePos < 4 THEN
            SPRITE SPR_POWERUP, TitleMarchDir + $0200, PowerUpY, (GRAM_CAP_F1 + SlidePos / 2) * 8 + TitleGridCol + $0800
        ELSE
            SPRITE SPR_POWERUP, TitleMarchDir + $0200, PowerUpY, (GRAM_CAP_F1 + SlidePos / 2) * 8 + TitleMarchCount + $0800
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
                    BeamTimer = 1
                    RapidTimer = 0 : #GameFlags = #GameFlags AND ($FFFF XOR FLAG_DUAL) : #MegaTimer = 0
                    IF VOICE.AVAILABLE THEN VOICE PLAY beam_phrase
                ELSEIF TitleColor = 1 THEN
                    RapidTimer = 1
                    BeamTimer = 0 : #GameFlags = #GameFlags AND ($FFFF XOR FLAG_DUAL) : #MegaTimer = 0
                    IF VOICE.AVAILABLE THEN VOICE PLAY rapid_phrase
                ELSEIF TitleColor = 2 THEN
                    #GameFlags = #GameFlags OR FLAG_DUAL
                    BeamTimer = 0 : RapidTimer = 0 : #MegaTimer = 0
                    IF VOICE.AVAILABLE THEN VOICE PLAY quad_phrase
                ELSEIF TitleColor = 3 THEN
                    #MegaTimer = 120
                    BeamTimer = 0 : RapidTimer = 0 : #GameFlags = #GameFlags AND ($FFFF XOR FLAG_DUAL)
                    IF VOICE.AVAILABLE THEN VOICE PLAY mega_phrase
                ELSE
                    ' Shield - coexists with weapons, just set hits
                    ShieldHits = 2
                    IF VOICE.AVAILABLE THEN VOICE PLAY shield_phrase
                END IF
                TitleFrame = 0
                SPRITE SPR_POWERUP, 0, 0, 0
                ' Clear tutorial message if showing
                IF TutorialTimer > 0 THEN
                    IF TutorialTimer < 255 THEN
                        TutorialTimer = 0
                        PRINT AT 180, "                    "
                    END IF
                END IF
                ' Weighted random next power-up type
                TitleColor = PowerUpWeights(RANDOM(8))
                RETURN
            END IF
        END IF
    END IF

    ' Check timeout
    IF #PowerTimer = 0 THEN
        TitleFrame = 0
        SPRITE SPR_POWERUP, 0, 0, 0
        ' Clear tutorial message if showing
        IF TutorialTimer > 0 THEN
            IF TutorialTimer < 255 THEN
                TutorialTimer = 0
                PRINT AT 200, "                    "
            END IF
        END IF
        RETURN
    END IF

    ' Draw landed capsule with flash effect + animated frame
    SlidePos = SlidePos + 1
    IF SlidePos >= 8 THEN SlidePos = 0
    IF #PowerTimer < 100 THEN
        ' Rapid flash in last ~1.7 seconds (every 2 frames)
        IF SlidePos < 2 THEN
            SPRITE SPR_POWERUP, TitleMarchDir + $0200, PLAYER_Y, (GRAM_CAP_F1 + SlidePos / 2) * 8 + TitleGridCol + $0800
        ELSEIF SlidePos < 4 THEN
            SPRITE SPR_POWERUP, 0, 0, 0  ' Invisible
        ELSEIF SlidePos < 6 THEN
            SPRITE SPR_POWERUP, TitleMarchDir + $0200, PLAYER_Y, (GRAM_CAP_F1 + SlidePos / 2) * 8 + TitleMarchCount + $0800
        ELSE
            SPRITE SPR_POWERUP, 0, 0, 0  ' Invisible
        END IF
    ELSE
        ' Normal flash (animated frame + color cycle)
        IF SlidePos < 4 THEN
            SPRITE SPR_POWERUP, TitleMarchDir + $0200, PLAYER_Y, (GRAM_CAP_F1 + SlidePos / 2) * 8 + TitleGridCol + $0800
        ELSE
            SPRITE SPR_POWERUP, TitleMarchDir + $0200, PLAYER_Y, (GRAM_CAP_F1 + SlidePos / 2) * 8 + TitleMarchCount + $0800
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
                #ScreenPos = (ALIEN_START_Y + ClearRow) * 20
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
        IF #GameFlags AND FLAG_FLYDOWN THEN
            IF ClearRow < WaveRevealRow THEN
                ' Row is above screen, skip entirely
                HitCol = 0
            ELSE
                ClearRow = ClearRow - WaveRevealRow
            END IF
        END IF
        ' Skip if this row would land on the HUD (row 11 = positions 220+)
        IF HitCol AND ClearRow < 11 THEN
        #ScreenPos = ClearRow * 20

        ' Determine which alien type and wave color for this row
        IF Row = 0 THEN
            AlienCard = GRAM_ALIEN1 + AnimFrame
            AlienColor = WaveColor0  ' Squid color (wave palette)
        ELSEIF Row < 3 THEN
            AlienCard = GRAM_ALIEN2 + AnimFrame
            AlienColor = WaveColor1  ' Crab color (wave palette)
        ELSE
            AlienCard = GRAM_ALIEN3 + AnimFrame
            AlienColor = WaveColor2  ' Octopus color (wave palette)
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
                    ELSEIF #GameFlags AND FLAG_HASLARGE THEN
                        ' Only check bottom-half match when a large alien exists
                        IF BossType(LoopVar) = LARGE_TYPE THEN
                            IF Row = BossRow(LoopVar) + 1 THEN
                                IF RowBoss1 = 255 THEN RowBoss1 = LoopVar ELSE RowBoss2 = LoopVar
                            END IF
                        END IF
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
                    ' Check for boss in dual-reveal mode (inline, no GOSUB)
                    FoundBoss = 255
                    IF RowBoss1 < 255 THEN
                        IF RowBoss1 < 255 THEN
                            IF Col = BossCol(RowBoss1) OR Col = BossCol(RowBoss1) + 1 THEN FoundBoss = RowBoss1
                        END IF
                        IF FoundBoss = 255 AND RowBoss2 < 255 THEN
                            IF Col = BossCol(RowBoss2) OR Col = BossCol(RowBoss2) + 1 THEN FoundBoss = RowBoss2
                        END IF
                    END IF
                    IF FoundBoss < 255 THEN
                        ' Special alien in slide-in mode
                        IF BossType(FoundBoss) = LARGE_TYPE THEN
                            ' Large 2x2 alien — pulse color on shimmer
                            IF BossColor(FoundBoss) >= 8 THEN
                                #Card = (BossColor(FoundBoss) AND 7) + $1800
                            ELSE
                                #Card = BossColor(FoundBoss) + $0800
                            END IF
                            IF ShimmerCount AND 8 THEN #Card = COL_WHITE + $0800
                            ' Select quadrant based on row/col
                            IF Row = BossRow(FoundBoss) THEN
                                IF Col = BossCol(FoundBoss) THEN
                                    #Card = GRAM_LARGE_TL * 8 + #Card
                                ELSE
                                    #Card = GRAM_LARGE_TR * 8 + #Card
                                END IF
                            ELSE
                                IF Col = BossCol(FoundBoss) THEN
                                    #Card = GRAM_LARGE_BL * 8 + #Card
                                ELSE
                                    #Card = GRAM_LARGE_BR * 8 + #Card
                                END IF
                            END IF
                        ELSEIF BossType(FoundBoss) = BOMB_TYPE THEN
                            ' Flash red/white when bomb alien at HP=1
                            HitCol = BossColor(FoundBoss)
                            IF BossHP(FoundBoss) = 1 THEN
                                IF ShimmerCount AND 4 THEN HitCol = COL_WHITE ELSE HitCol = COL_RED
                            END IF
                            ' Compute color offset: pastel colors (8+) need $1800, others $0800
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
                            ' Compute color offset: pastel colors (8+) need $1800, others $0800
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
                    END IF
                    IF Col < 5 THEN
                        ' Left group: slides in from left edge
                        PRINT AT #ScreenPos + WaveRevealCol + Col, #Card
                    ELSE
                        ' Right group: slides in from right edge
                        PRINT AT #ScreenPos + RightRevealCol + Col, #Card
                    END IF
                    ' Restore normal alien card for next column
                    #Card = AlienCard * 8 + AlienColor + $0800
                END IF
                #Mask = #Mask + #Mask
            NEXT Col
        ELSE
            ' Standard mode: draw with column/row reveal gating
            ' Top-down mode gates by row, left sweep gates by column
            IF (#GameFlags AND FLAG_TOPDOWN) AND Row > WaveRevealRow THEN
                ' Row not yet revealed in top-down mode - skip drawing
            ELSE
            #Mask = 1
            FOR Col = 0 TO ALIEN_COLS - 1
                IF (#GameFlags AND FLAG_TOPDOWN) OR Col <= WaveRevealCol THEN
                    IF #AlienRow(Row) AND #Mask THEN
                        ' Check if this cell is a boss (inline, no GOSUB)
                        FoundBoss = 255
                        IF RowBoss1 < 255 THEN
                            IF RowBoss1 < 255 THEN
                                IF Col = BossCol(RowBoss1) OR Col = BossCol(RowBoss1) + 1 THEN FoundBoss = RowBoss1
                            END IF
                            IF FoundBoss = 255 AND RowBoss2 < 255 THEN
                                IF Col = BossCol(RowBoss2) OR Col = BossCol(RowBoss2) + 1 THEN FoundBoss = RowBoss2
                            END IF
                        END IF
                        IF FoundBoss < 255 THEN
                            ' Special alien — large, bomb, or skull boss
                            IF BossType(FoundBoss) = LARGE_TYPE THEN
                                ' Large 2x2 alien — pulse color on shimmer
                                IF BossColor(FoundBoss) >= 8 THEN
                                    #Card = (BossColor(FoundBoss) AND 7) + $1800
                                ELSE
                                    #Card = BossColor(FoundBoss) + $0800
                                END IF
                                IF ShimmerCount AND 8 THEN #Card = COL_WHITE + $0800
                                IF Row = BossRow(FoundBoss) THEN
                                    IF Col = BossCol(FoundBoss) THEN
                                        PRINT AT #ScreenPos + ALIEN_START_X + AlienOffsetX + Col, GRAM_LARGE_TL * 8 + #Card
                                    ELSE
                                        PRINT AT #ScreenPos + ALIEN_START_X + AlienOffsetX + Col, GRAM_LARGE_TR * 8 + #Card
                                    END IF
                                ELSE
                                    IF Col = BossCol(FoundBoss) THEN
                                        PRINT AT #ScreenPos + ALIEN_START_X + AlienOffsetX + Col, GRAM_LARGE_BL * 8 + #Card
                                    ELSE
                                        PRINT AT #ScreenPos + ALIEN_START_X + AlienOffsetX + Col, GRAM_LARGE_BR * 8 + #Card
                                    END IF
                                END IF
                            ELSEIF BossType(FoundBoss) = BOMB_TYPE THEN
                                ' Bomb alien: use BossColor, but flash red/white at HP=1
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
                                        PRINT AT #ScreenPos + ALIEN_START_X + AlienOffsetX + Col, GRAM_BOMB1 * 8 + #Card
                                    ELSE
                                        PRINT AT #ScreenPos + ALIEN_START_X + AlienOffsetX + Col, GRAM_BOMB1_F1 * 8 + #Card
                                    END IF
                                ELSE
                                    IF AnimFrame = 0 THEN
                                        PRINT AT #ScreenPos + ALIEN_START_X + AlienOffsetX + Col, GRAM_BOMB2 * 8 + #Card
                                    ELSE
                                        PRINT AT #ScreenPos + ALIEN_START_X + AlienOffsetX + Col, GRAM_BOMB2_F1 * 8 + #Card
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
                                        PRINT AT #ScreenPos + ALIEN_START_X + AlienOffsetX + Col, GRAM_BAND1 * 8 + #Card
                                    ELSE
                                        PRINT AT #ScreenPos + ALIEN_START_X + AlienOffsetX + Col, GRAM_BAND1_F1 * 8 + #Card
                                    END IF
                                ELSE
                                    IF AnimFrame = 0 THEN
                                        PRINT AT #ScreenPos + ALIEN_START_X + AlienOffsetX + Col, GRAM_BAND2 * 8 + #Card
                                    ELSE
                                        PRINT AT #ScreenPos + ALIEN_START_X + AlienOffsetX + Col, GRAM_BAND2_F1 * 8 + #Card
                                    END IF
                                END IF
                            END IF
                            ' Restore normal alien card for subsequent columns
                            #Card = AlienCard * 8 + AlienColor + $0800
                        ELSE
                            ' Warp-in: show materialize frames for currently revealing elements
                            IF (#GameFlags AND FLAG_TOPDOWN) AND Row = WaveRevealRow AND WaveRevealRow < ALIEN_ROWS - 1 THEN
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
            ' Clear trail on BOTH edges to handle direction reversals cleanly
            IF AlienOffsetX > 0 THEN
                PRINT AT #ScreenPos + ALIEN_START_X + AlienOffsetX - 1, 0
            END IF
            IF AlienOffsetX < ALIEN_MAX_X THEN
                PRINT AT #ScreenPos + ALIEN_START_X + AlienOffsetX + ALIEN_COLS, 0
            END IF
            END IF  ' top-down row gating
        END IF
        END IF  ' row < 11 (protect HUD)
    NEXT Row
    RETURN
END

' --------------------------------------------
' CheckWaveWin - Check if all aliens are dead
' --------------------------------------------
' --------------------------------------------
' LoadPatternB - Transition to Pattern B formation
' --------------------------------------------
LoadPatternB: PROCEDURE
    #GameFlags = #GameFlags OR FLAG_SUBWAVE

    ' Silence any lingering SFX
    SOUND 2, , 0
    POKE $1F8, PEEK($1F8) OR $20  ' Disable noise on channel C
    SfxVolume = 0
    SfxType = 0

    ' Clear active bullets, rogue (but preserve wingman!)
    #GameFlags = #GameFlags AND $FFFC  ' Clear FLAG_BULLET + FLAG_ABULLET
    ' Clear wingman bullet BACKTAB tile before deactivating
    IF #GameFlags AND FLAG_CAPBULLET THEN
        #ScreenPos = CapBulletRow * 20 + CapBulletCol
        IF #ScreenPos < 240 THEN PRINT AT #ScreenPos, 0
        #GameFlags = #GameFlags AND $FFF7  ' Clear FLAG_CAPBULLET
    END IF
    MegaBeamTimer = 0
    GOSUB ClearRogueOnly
    SPRITE SPR_PBULLET, 0, 0, 0
    SPRITE SPR_ABULLET, 0, 0, 0
    SPRITE SPR_SAUCER, 0, 0, 0
    SPRITE SPR_SAUCER2, 0, 0, 0
    FlyState = 0
    #FlyPhase = 0
    TitleFrame = 0
    ' Hide capsule sprite if no wingman using it
    IF (#GameFlags AND FLAG_CAPTURE) = 0 THEN SPRITE SPR_POWERUP, 0, 0, 0

    ' Reset alien positions (center the grid on screen)
    AlienOffsetX = 5
    AlienOffsetY = 0
    LastClearedY = 0
    AlienDir = 1
    MarchCount = 0
    CurrentMarchSpeed = BaseMarchSpeed  ' Reset speed (don't inherit Pattern A's acceleration)

    ' Look up which pattern to use for this level
    LoopVar = (Level - 1) AND 7
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
    BossCount = 0 : BombExpTimer = 0

    ' Pattern B boss placement per wave (wraps every 8)
    LoopVar = (Level - 1) AND 7  ' 0-based wave index

    IF LoopVar = 1 THEN
        ' Wave 2 Pattern B (Diamond): 1 skull center
        BossCount = 1
        BossCol(0) = 4 : BossRow(0) = 2
        BossHP(0) = BOSS_HP_MAX : BossColor(0) = 10 : BossType(0) = SKULL_TYPE
    ELSEIF LoopVar = 3 THEN
        ' Wave 4 Pattern B (Cross): 1 skull on horizontal bar
        BossCount = 1
        BossCol(0) = 3 : BossRow(0) = 2
        BossHP(0) = BOSS_HP_MAX : BossColor(0) = 9 : BossType(0) = SKULL_TYPE
    ELSEIF LoopVar = 5 THEN
        ' Wave 6 Pattern B (Arrow): no bosses (no adjacent cols)
        ' BossCount already 0
    ELSEIF LoopVar = 6 THEN
        ' Wave 7 Pattern B (Fortress): 1 large alien center
        BossCount = 1
        BossCol(0) = 3 : BossRow(0) = 1
        BossHP(0) = BOSS_HP_MAX : BossColor(0) = 12 : BossType(0) = LARGE_TYPE
    ELSEIF LoopVar = 7 THEN
        ' Wave 8 Pattern B (Phalanx): 2 skulls on dense rows
        BossCount = 2
        BossCol(0) = 2 : BossRow(0) = 0
        BossHP(0) = BOSS_HP_MAX : BossColor(0) = 9 : BossType(0) = SKULL_TYPE
        BossCol(1) = 2 : BossRow(1) = 4
        BossHP(1) = BOSS_HP_MAX : BossColor(1) = 10 : BossType(1) = SKULL_TYPE
    END IF

    ' Load large alien GRAM cards if any LARGE_TYPE boss in this pattern
    FoundBoss = 0
    FOR LoopVar = 0 TO BossCount - 1
        IF BossType(LoopVar) = LARGE_TYPE THEN FoundBoss = 1
    NEXT LoopVar
    IF FoundBoss THEN
        #GameFlags = #GameFlags OR FLAG_HASLARGE
        DEFINE GRAM_LARGE_TL, 2, LargeAlienTLGfx  ' Cards 19-20 (TL + TR)
        WAIT
        DEFINE GRAM_LARGE_BL, 2, LargeAlienBLGfx  ' Cards 34-35 (BL + BR, reuse warp-in slots)
        WAIT
    ELSE
        #GameFlags = #GameFlags AND ($FFFF XOR FLAG_HASLARGE)
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

    ' Set dual-slide mode: halves fly in from screen edges
    #GameFlags = #GameFlags OR FLAG_REVEAL
    #GameFlags = #GameFlags AND $FBFF  ' Clear top-down flag for pincer
    WaveRevealCol = 0              ' Left group starts at far left
    RightRevealCol = 10            ' Right group starts at far right

    ' Clear alien area on screen (rows 0-10)
    FOR LoopVar = 0 TO 10
        #ScreenPos = LoopVar * 20
        FOR Col = 0 TO 19
            PRINT AT #ScreenPos + Col, 0
        NEXT Col
    NEXT LoopVar

    ' Redraw HUD (cleared by above loop at row 11) - grey since chain resets
    ' Score at 220-227
    PRINT AT 220, GRAM_SCORE_SC * 8 + COL_WHITE + $0800
    PRINT AT 221, GRAM_SCORE_OR * 8 + COL_WHITE + $0800
    PRINT AT 222, GRAM_SCORE_E * 8 + COL_WHITE + $0800
    PRINT AT 223 COLOR COL_WHITE, <>#Score
    ' Chain at 228-232 (grey/inactive)
    PRINT AT 228, GRAM_CHAIN_CH * 8 + $1800
    PRINT AT 229, GRAM_CHAIN_AI * 8 + $1800
    PRINT AT 230, GRAM_CHAIN_N * 8 + $1800
    PRINT AT 231, 111                            ' GROM hyphen
    PRINT AT 232, 0
    ' Powerup cleared
    PRINT AT 233, 0 : PRINT AT 234, 0
    ' Lives at 236-238
    PRINT AT 236, (GRAM_SHIP_HUD * 8) + COL_WHITE + $0800

    ' Visual/audio cue: "ALERT!" flash
    PRINT AT 107 COLOR COL_RED, "ALERT!"
    SOUND 2, 200, 12
    FOR LoopVar = 0 TO 20
        WAIT
    NEXT LoopVar
    SOUND 2, 100, 14
    FOR LoopVar = 0 TO 15
        WAIT
    NEXT LoopVar
    SOUND 2, , 0

    ' Flash-off
    FOR LoopVar = 0 TO 5
        IF (LoopVar AND 1) = 0 THEN
            PRINT AT 107, "      "
        ELSE
            PRINT AT 107 COLOR COL_RED, "ALERT!"
        END IF
        FOR Row = 0 TO 3
            WAIT
        NEXT Row
    NEXT LoopVar
    PRINT AT 107, "      "

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
                GOSUB LoadPatternB
            ELSE
                GOSUB StartNewWave
            END IF
        END IF
    END IF
    RETURN
END

' --------------------------------------------
' StartNewWave - Reset aliens for next wave
' --------------------------------------------
StartNewWave: PROCEDURE
    ' Silence any lingering SFX (game loop UpdateSfx won't run during transition)
    SOUND 2, , 0
    SfxVolume = 0
    SfxType = 0
    ChainCount = 0  ' Reset kill chain for new wave
    #GameFlags = #GameFlags AND ($FFFF XOR FLAG_HASLARGE)  ' Clear until LoadPatternB sets it

    ' Increment level
    Level = Level + 1

    ' Set wave color palette (cycles through 6 palettes)
    LoopVar = (Level - 1) - ((Level - 1) / 6) * 6  ' MOD 6
    WaveColor0 = WavePalette0(LoopVar)
    WaveColor1 = WavePalette1(LoopVar)
    WaveColor2 = WavePalette2(LoopVar)

    ' Set base march speed for this wave (faster each wave)
    IF BaseMarchSpeed > MARCH_SPEED_MIN + 10 THEN
        BaseMarchSpeed = BaseMarchSpeed - 10
    ELSE
        BaseMarchSpeed = MARCH_SPEED_MIN
    END IF
    CurrentMarchSpeed = BaseMarchSpeed

    ' Set initial music gear (descent will escalate within wave)
    IF Level >= 2 THEN
        MusicGear = 1
        PLAY si_bg_mid
    ELSE
        MusicGear = 0
        PLAY si_bg_slow
    END IF

    ' Reset alien positions
    AlienOffsetX = 0
    AlienOffsetY = 0
    LastClearedY = 0
    AlienDir = 1
    MarchCount = 0

    ' Reset all aliens to alive (9 bits = $1FF)
    FOR LoopVar = 0 TO ALIEN_ROWS - 1
        #AlienRow(LoopVar) = $1FF
    NEXT LoopVar

    ' Clear all boss slots
    FOR LoopVar = 0 TO MAX_BOSSES - 1
        BossHP(LoopVar) = 0
    NEXT LoopVar
    BossCount = 0 : BombExpTimer = 0

    ' Boss placement per wave (wraps every 8 waves)
    ' Boss colors: Cyan(9), Orange(10), Pink(12) contrast well against alien row colors
    LoopVar = (Level - 1) AND 7  ' 0-based wave index, wraps after 8

    IF LoopVar = 2 THEN
        ' Wave 3: 2 skull top + 1 bomb bottom
        BossCount = 3
        BossCol(0) = 1 : BossRow(0) = 0
        BossHP(0) = BOSS_HP_MAX : BossColor(0) = 9 : BossType(0) = SKULL_TYPE
        BossCol(1) = 6 : BossRow(1) = 0
        BossHP(1) = BOSS_HP_MAX : BossColor(1) = 9 : BossType(1) = SKULL_TYPE
        BossCol(2) = 4 : BossRow(2) = 3
        BossHP(2) = 2 : BossColor(2) = 12 : BossType(2) = BOMB_TYPE
    ELSEIF LoopVar = 3 THEN
        ' Wave 4: 2 skull top + 1 skull mid + 1 bomb bottom
        BossCount = 4
        BossCol(0) = 1 : BossRow(0) = 0
        BossHP(0) = BOSS_HP_MAX : BossColor(0) = 9 : BossType(0) = SKULL_TYPE
        BossCol(1) = 6 : BossRow(1) = 0
        BossHP(1) = BOSS_HP_MAX : BossColor(1) = 9 : BossType(1) = SKULL_TYPE
        BossCol(2) = 3 : BossRow(2) = 1
        BossHP(2) = BOSS_HP_MAX : BossColor(2) = 10 : BossType(2) = SKULL_TYPE
        BossCol(3) = 4 : BossRow(3) = 3
        BossHP(3) = 2 : BossColor(3) = 12 : BossType(3) = BOMB_TYPE
    ELSEIF LoopVar = 4 THEN
        ' Wave 5: 1 skull top + 1 skull mid + 2 bomb bottom
        BossCount = 4
        BossCol(0) = 1 : BossRow(0) = 0
        BossHP(0) = BOSS_HP_MAX : BossColor(0) = 10 : BossType(0) = SKULL_TYPE
        BossCol(1) = 4 : BossRow(1) = 2
        BossHP(1) = BOSS_HP_MAX : BossColor(1) = 12 : BossType(1) = SKULL_TYPE
        BossCol(2) = 2 : BossRow(2) = 4
        BossHP(2) = 2 : BossColor(2) = 9 : BossType(2) = BOMB_TYPE
        BossCol(3) = 6 : BossRow(3) = 4
        BossHP(3) = 2 : BossColor(3) = 9 : BossType(3) = BOMB_TYPE
    ELSEIF LoopVar = 5 THEN
        ' Wave 6: flanking skulls + center skull + bomb bottom
        BossCount = 4
        BossCol(0) = 0 : BossRow(0) = 1
        BossHP(0) = BOSS_HP_MAX : BossColor(0) = 10 : BossType(0) = SKULL_TYPE
        BossCol(1) = 7 : BossRow(1) = 1
        BossHP(1) = BOSS_HP_MAX : BossColor(1) = 10 : BossType(1) = SKULL_TYPE
        BossCol(2) = 4 : BossRow(2) = 2
        BossHP(2) = BOSS_HP_MAX : BossColor(2) = 12 : BossType(2) = SKULL_TYPE
        BossCol(3) = 4 : BossRow(3) = 4
        BossHP(3) = 2 : BossColor(3) = 9 : BossType(3) = BOMB_TYPE
    ELSEIF LoopVar = 6 THEN
        ' Wave 7: center pressure + flanking bombs
        BossCount = 4
        BossCol(0) = 3 : BossRow(0) = 0
        BossHP(0) = BOSS_HP_MAX : BossColor(0) = 9 : BossType(0) = SKULL_TYPE
        BossCol(1) = 3 : BossRow(1) = 2
        BossHP(1) = BOSS_HP_MAX : BossColor(1) = 12 : BossType(1) = SKULL_TYPE
        BossCol(2) = 1 : BossRow(2) = 3
        BossHP(2) = 2 : BossColor(2) = 10 : BossType(2) = BOMB_TYPE
        BossCol(3) = 6 : BossRow(3) = 3
        BossHP(3) = 2 : BossColor(3) = 10 : BossType(3) = BOMB_TYPE
    ELSEIF LoopVar >= 7 THEN
        ' Wave 8: max intensity
        BossCount = 4
        BossCol(0) = 1 : BossRow(0) = 0
        BossHP(0) = BOSS_HP_MAX : BossColor(0) = 9 : BossType(0) = SKULL_TYPE
        BossCol(1) = 6 : BossRow(1) = 0
        BossHP(1) = BOSS_HP_MAX : BossColor(1) = 9 : BossType(1) = SKULL_TYPE
        BossCol(2) = 4 : BossRow(2) = 2
        BossHP(2) = BOSS_HP_MAX : BossColor(2) = 12 : BossType(2) = SKULL_TYPE
        BossCol(3) = 3 : BossRow(3) = 4
        BossHP(3) = 2 : BossColor(3) = 10 : BossType(3) = BOMB_TYPE
    END IF

    ' Clear any active bullets (power-ups AND wingman persist until death!)
    #GameFlags = #GameFlags AND $FFFC  ' Clear FLAG_BULLET + FLAG_ABULLET
    ' Clear wingman bullet BACKTAB tile before deactivating
    IF #GameFlags AND FLAG_CAPBULLET THEN
        #ScreenPos = CapBulletRow * 20 + CapBulletCol
        IF #ScreenPos < 240 THEN PRINT AT #ScreenPos, 0
        #GameFlags = #GameFlags AND $FFF7  ' Clear FLAG_CAPBULLET
    END IF
    #MegaTimer = 0
    MegaBeamTimer = 0
    GOSUB ClearRogueOnly
    SPRITE SPR_PBULLET, 0, 0, 0
    SPRITE SPR_ABULLET, 0, 0, 0
    SPRITE SPR_SAUCER, 0, 0, 0
    SPRITE SPR_SAUCER2, 0, 0, 0
    FlyState = 0
    #FlyPhase = 0
    TitleFrame = 0
    ' Hide capsule sprite if no wingman using it
    IF (#GameFlags AND FLAG_CAPTURE) = 0 THEN SPRITE SPR_POWERUP, 0, 0, 0
    TitleJitter = 0
    WaveRevealRow = 0
    #GameFlags = #GameFlags AND $BEFF  ' Clear FLAG_SUBWAVE + FLAG_REVEAL
    LoopVar = Level - 1
    IF LoopVar > 7 THEN LoopVar = LoopVar AND 7
    GOSUB SetEntrancePattern
    RightRevealCol = ALIEN_COLS - 1

    ' Clear screen (aliens will paint in via game loop)
    CLS

    ' Redraw HUD - Score at 220-227, Chain at 228-232, Powerup at 233-234, Lives at 235-237
    PRINT AT 220, GRAM_SCORE_SC * 8 + COL_WHITE + $0800
    PRINT AT 221, GRAM_SCORE_OR * 8 + COL_WHITE + $0800
    PRINT AT 222, GRAM_SCORE_E * 8 + COL_WHITE + $0800
    PRINT AT 223 COLOR COL_WHITE, <>#Score
    ' Chain - respect chain state
    IF ChainCount = 0 THEN
        PRINT AT 228, GRAM_CHAIN_CH * 8 + $1800
        PRINT AT 229, GRAM_CHAIN_AI * 8 + $1800
        PRINT AT 230, GRAM_CHAIN_N * 8 + $1800
        PRINT AT 231, 111                        ' GROM hyphen
        PRINT AT 232, 0
    ELSE
        PRINT AT 228, GRAM_CHAIN_CH * 8 + COL_BLUE + $0800
        PRINT AT 229, GRAM_CHAIN_AI * 8 + COL_BLUE + $0800
        PRINT AT 230, GRAM_CHAIN_N * 8 + COL_BLUE + $0800
        PRINT AT 231 COLOR COL_BLUE, <>ChainCount
        IF ChainCount < 10 THEN PRINT AT 232, 0
    END IF
    ' Powerup indicator cleared
    PRINT AT 233, 0 : PRINT AT 234, 0
    ' Lives at 236-238
    PRINT AT 236, (GRAM_SHIP_HUD * 8) + COL_WHITE + $0800
    GOSUB UpdateLivesHUD

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
        DEFINE GRAM_PWR_BE, 4, PowerupBEGfx  ' Cards 25-28: BE, AM, RP, ID
        WAIT
    SkipEscape:
    END IF

    ' Note: large alien BL/BR now use cards 34-35 (warp-in slots), no HUD conflict

    ' Restore warp-in GRAM cards (large alien may have overwritten slots 34-35)
    DEFINE GRAM_WARP1, 2, WarpInGfx1    ' Cards 34-35: warp-in frames 1-2
    WAIT

    ' Phase A: Breather pause (blank screen + HUD only)
    FOR LoopVar = 0 TO 30
        WAIT
    NEXT LoopVar

    ' Phase B: Voice announcement + Banner display
    IF VOICE.AVAILABLE THEN
        VOICE PLAY wave_phrase        ' Say "WAVE"
        VOICE WAIT                    ' Wait for speech to finish
        VOICE NUMBER Level            ' Say the number
    END IF
    PRINT AT 107 COLOR 6, "WAVE "     ' Yellow, centered row 5 col 7
    PRINT AT 112, <> Level
    FOR LoopVar = 0 TO 90
        WAIT
    NEXT LoopVar

    ' Phase C: Flash-off (blink then vanish)
    FOR LoopVar = 0 TO 7
        IF (LoopVar AND 1) = 0 THEN
            PRINT AT 107, "       "   ' Hide
        ELSE
            PRINT AT 107 COLOR 6, "WAVE "
            PRINT AT 112, <> Level
        END IF
        FOR Row = 0 TO 4
            WAIT
        NEXT Row
    NEXT LoopVar
    PRINT AT 107, "       "           ' Final clear

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

quad_phrase:
    VOICE KK2, WW, AO, DD1, PA1, LL, EY, ZZ, ER1, ZZ, PA1, 0

mega_phrase:
    VOICE MM, EH, GG2, AX, PA1, BB1, IY, MM, PA1, 0

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

' Saucer primary/secondary colors per power-up type
' Index by TitleColor (0=beam, 1=rapid, 2=dual, 3=mega, 4=shield)
SaucerColor1:
    DATA COL_BLUE, COL_YELLOW, COL_WHITE, COL_RED, COL_CYAN
SaucerColor2:
    DATA COL_WHITE, COL_GREEN, COL_TAN, COL_TAN, COL_BLUE

' Power-up weighted distribution (8 slots)
' beam=2, rapid=2, quad=2, mega=1, shield=1
PowerUpWeights:
    DATA 0, 0, 1, 1, 2, 2, 3, 4

' --------------------------------------------
' UpdateCapture - Orbit captured wingman around player ship
' --------------------------------------------
UpdateCapture: PROCEDURE
    ' Advance orbit step every 2 frames (16-step circle, slower orbit)
    IF (CaptureTimer AND 1) = 0 THEN
        CaptureStep = CaptureStep + 1
        IF CaptureStep >= 16 THEN CaptureStep = 0
    END IF

    ' Compute orbit position centered on player (use HitCol/HitRow as temps
    ' to avoid clobbering RogueX/RogueY which the rogue dive system needs)
    HitCol = PlayerX - 4 + CaptureOrbitDX(CaptureStep) - CAPTURE_ORBIT_R
    HitRow = PLAYER_Y - 12 + CaptureOrbitDY(CaptureStep) - CAPTURE_ORBIT_R

    ' Clamp X to valid sprite range
    IF HitCol > 200 THEN HitCol = 0  ' unsigned underflow guard
    IF HitCol > 160 THEN HitCol = 160

    ' Render wingman (skip if power-up capsule is using the sprite)
    ' Uses Mooninite-style graphics (GRAM_WINGMAN_F1/F2) in captured alien's color
    IF TitleFrame = 0 THEN
        IF AnimFrame = 0 THEN
            SPRITE SPR_POWERUP, HitCol + SPR_VISIBLE, HitRow, GRAM_WINGMAN_F1 * 8 + CaptureColor + $0800
        ELSE
            SPRITE SPR_POWERUP, HitCol + SPR_VISIBLE, HitRow, GRAM_WINGMAN_F2 * 8 + CaptureColor + $0800
        END IF
    END IF

    ' Rogue alien body collision with wingman
    IF RogueState = ROGUE_DIVE THEN
        IF RogueX + 6 >= HitCol THEN
            IF HitCol + 8 >= RogueX THEN
                IF RogueY + 6 >= HitRow THEN
                    IF HitRow + 6 >= RogueY THEN
                        ' Rogue destroys wingman! Release capture
                        IF #GameFlags AND FLAG_CAPBULLET THEN
                            #ScreenPos = CapBulletRow * 20 + CapBulletCol
                            IF #ScreenPos < 240 THEN PRINT AT #ScreenPos, 0
                        END IF
                        #GameFlags = #GameFlags AND $FFF3  ' Clear FLAG_CAPTURE + FLAG_CAPBULLET
                        SPRITE SPR_POWERUP, 0, 0, 0
                        SfxType = 1 : SfxVolume = 12 : #SfxPitch = 150
                        SOUND 2, 150, 12
                        RETURN
                    END IF
                END IF
            END IF
        END IF
    END IF

    ' Fire timer — launch upward bullet
    IF CaptureTimer > 0 THEN
        CaptureTimer = CaptureTimer - 1
    ELSE
        CaptureTimer = CAPTURE_FIRE_RATE
        IF (#GameFlags AND FLAG_CAPBULLET) = 0 THEN
            ' Launch visible upward bullet from wingman position
            CapBulletCol = (HitCol - 8) / 8
            IF CapBulletCol > 19 THEN CapBulletCol = 19
            CapBulletRow = (HitRow - 8) / 8
            IF CapBulletRow > 11 THEN CapBulletRow = 11
            #GameFlags = #GameFlags OR FLAG_CAPBULLET
            ' SFX: soft pew on channel 3
            SfxType = 1 : SfxVolume = 6 : #SfxPitch = 500
            SOUND 2, 500, 6
        END IF
    END IF

    ' Update capture bullet (move up one row per frame)
    IF #GameFlags AND FLAG_CAPBULLET THEN
        ' Clear previous tile (skip row 0 = score display)
        IF CapBulletRow > 0 THEN
            #ScreenPos = CapBulletRow * 20 + CapBulletCol
            IF #ScreenPos < 240 THEN
                PRINT AT #ScreenPos, 0
            END IF
        END IF

        ' Move up — stop at row 1 (don't enter score row 0)
        IF CapBulletRow <= 1 THEN
            ' Reached top of play area, deactivate
            #GameFlags = #GameFlags AND $FFF7
            GOTO CapBulletDone
        END IF
        CapBulletRow = CapBulletRow - 1

        ' Check for alien hit at new position
        GOSUB CaptureHitscan

        ' Check wingman bullet vs rogue sprite (not in grid)
        IF #GameFlags AND FLAG_CAPBULLET THEN
            IF RogueState = ROGUE_DIVE THEN
                IF RogueX >= 8 THEN
                    IF RogueY >= 8 THEN
                        IF CapBulletRow = (RogueY - 8) / 8 THEN
                            #ScreenPos = (RogueX - 8) / 8
                            IF CapBulletCol >= #ScreenPos THEN
                                IF CapBulletCol <= #ScreenPos + 1 THEN
                                    ' Wingman bullet kills rogue!
                                    RogueState = ROGUE_IDLE
                                    RogueTimer = 0 : RogueDivePhase = 0
                                    SPRITE SPR_FLYER, 0, 0, 0
                                    #ScreenPos = CapBulletRow * 20 + CapBulletCol
                                    IF #ScreenPos < 240 THEN PRINT AT #ScreenPos, 0
                                    #GameFlags = #GameFlags AND $FFF7  ' Clear FLAG_CAPBULLET
                                    #Score = #Score + 50
                                    #GameFlags = #GameFlags OR FLAG_SHOTLAND
                                    ChainCount = ChainCount + 1
                                    IF ChainCount > ChainMax THEN ChainMax = ChainCount
                                    IF ChainCount > 50 THEN ChainCount = 50
                                    ChainTimeout = 90
                                    SfxType = 1 : SfxVolume = 14 : #SfxPitch = 180
                                    SOUND 2, 180, 14
                                END IF
                            END IF
                        END IF
                    END IF
                END IF
            END IF
        END IF

        ' Draw bullet tile if still active
        IF #GameFlags AND FLAG_CAPBULLET THEN
            #ScreenPos = CapBulletRow * 20 + CapBulletCol
            IF #ScreenPos < 240 THEN
                PRINT AT #ScreenPos, GRAM_BULLET * 8 + COL_WHITE + $0800
            END IF
        END IF
    END IF
CapBulletDone:
    RETURN
END

' --------------------------------------------
' CaptureHitscan - Check if wingman bullet hit an alien at current row
' Uses CapBulletRow/CapBulletCol to check current position
' --------------------------------------------
CaptureHitscan: PROCEDURE
    ' Check if bullet is in the alien grid area
    HitCol = CapBulletCol
    IF HitCol < ALIEN_START_X + AlienOffsetX THEN RETURN
    IF HitCol >= ALIEN_START_X + AlienOffsetX + ALIEN_COLS THEN RETURN
    AlienGridCol = HitCol - ALIEN_START_X - AlienOffsetX

    ' Can't hit unrevealed columns during wave sweep-in
    IF AlienGridCol > WaveRevealCol THEN RETURN

    ' Check if this BACKTAB row corresponds to an alien grid row
    IF CapBulletRow < ALIEN_START_Y + AlienOffsetY THEN RETURN
    AlienGridRow = CapBulletRow - ALIEN_START_Y - AlienOffsetY
    IF AlienGridRow >= ALIEN_ROWS THEN RETURN

    ' Calculate bitmask for this column
    #Mask = ColMaskData(AlienGridCol)

    ' Check if alien is alive at this position
    IF (#AlienRow(AlienGridRow) AND #Mask) = 0 THEN RETURN

    ' Multi-boss intercept (inlined FindBoss for speed)
    FoundBoss = 255
    IF BossCount > 0 THEN
        FOR LoopVar = 0 TO BossCount - 1
            IF BossHP(LoopVar) > 0 THEN
                IF AlienGridRow = BossRow(LoopVar) THEN
                    IF AlienGridCol = BossCol(LoopVar) OR AlienGridCol = BossCol(LoopVar) + 1 THEN
                        FoundBoss = LoopVar
                    END IF
                END IF
            END IF
        NEXT LoopVar
    END IF
    IF FoundBoss < 255 THEN
        BossHP(FoundBoss) = BossHP(FoundBoss) - 1
        #GameFlags = #GameFlags AND $FFF7
        IF BossHP(FoundBoss) > 0 THEN
            ' Damaged but alive
            IF BossHP(FoundBoss) = 2 THEN BossColor(FoundBoss) = COL_YELLOW
            IF BossHP(FoundBoss) = 1 THEN BossColor(FoundBoss) = COL_RED
            SfxType = 1 : SfxVolume = 10 : #SfxPitch = 120
            SOUND 2, 120, 10
            RETURN
        ELSE
            ' Boss dead! Check type
            IF BossType(FoundBoss) = BOMB_TYPE THEN
                ' Bomb alien — chain explosion!
                GOSUB BombExplode
                RETURN
            ELSE
                ' Skull boss dead! XOR BOTH columns out
                #AlienRow(BossRow(FoundBoss)) = #AlienRow(BossRow(FoundBoss)) XOR ColMaskData(BossCol(FoundBoss))
                #AlienRow(BossRow(FoundBoss)) = #AlienRow(BossRow(FoundBoss)) XOR ColMaskData(BossCol(FoundBoss) + 1)
                #ExplosionPos = (ALIEN_START_Y + AlienOffsetY + BossRow(FoundBoss)) * 20 + ALIEN_START_X + AlienOffsetX + BossCol(FoundBoss)
                IF #ExplosionPos < 220 THEN PRINT AT #ExplosionPos, 0
                IF #ExplosionPos + 1 < 220 THEN PRINT AT #ExplosionPos + 1, 0
                #Score = #Score + BOSS_SCORE
                ExplosionTimer = 20
                IF #ExplosionPos < 220 THEN
                    PRINT AT #ExplosionPos, GRAM_EXPLOSION * 8 + COL_RED + $1800
                END IF
                SfxType = 1 : SfxVolume = 15 : #SfxPitch = 80
                SOUND 2, 80, 15
                RETURN
            END IF
        END IF
    END IF

    ' Normal alien kill
    #AlienRow(AlienGridRow) = #AlienRow(AlienGridRow) XOR #Mask

    ' Clear BACKTAB tile (bullet tile will also be cleared)
    #ScreenPos = CapBulletRow * 20 + HitCol
    IF #ScreenPos < 240 THEN
        PRINT AT #ScreenPos, 0
    END IF

    ' Score +10
    #Score = #Score + 10

    ' Deactivate bullet (it hit something)
    #GameFlags = #GameFlags AND $FFF7

    ' Brief explosion visual
    IF #ScreenPos < 220 THEN
        IF ExplosionTimer > 0 THEN
            IF #ExplosionPos < 220 THEN PRINT AT #ExplosionPos, 0
        END IF
        #ExplosionPos = #ScreenPos
        ExplosionTimer = 10
        PRINT AT #ExplosionPos, GRAM_EXPLOSION * 8 + COL_GREEN + $0800
    END IF

    ' SFX: soft zap on channel 3
    SfxType = 1 : SfxVolume = 8 : #SfxPitch = 300
    SOUND 2, 300, 8
    RETURN
END

' --------------------------------------------
' RoguePickAlien - Pick a random edge-column alien to go rogue
' --------------------------------------------
RoguePickAlien: PROCEDURE
    ' Pick left or right edge
    RogueCol = 0
    IF RANDOM(2) = 1 THEN RogueCol = ALIEN_COLS - 1

    ' Calculate bitmask for this column
    #Mask = ColMaskData(RogueCol)

    ' Count alive aliens in this column
    HitRow = 0
    FOR Row = 0 TO ALIEN_ROWS - 1
        IF #AlienRow(Row) AND #Mask THEN
            HitRow = HitRow + 1
        END IF
    NEXT Row

    ' If none found, try the other edge
    IF HitRow = 0 THEN
        IF RogueCol = 0 THEN
            RogueCol = ALIEN_COLS - 1
        ELSE
            RogueCol = 0
        END IF
        #Mask = ColMaskData(RogueCol)
        HitRow = 0
        FOR Row = 0 TO ALIEN_ROWS - 1
            IF #AlienRow(Row) AND #Mask THEN
                HitRow = HitRow + 1
            END IF
        NEXT Row
    END IF

    IF HitRow = 0 THEN RETURN  ' No edge aliens alive

    ' Pick a random alive row (sentinel pattern)
    LoopVar = RANDOM(HitRow)
    HitRow = 255
    FOR Row = 0 TO ALIEN_ROWS - 1
        IF #AlienRow(Row) AND #Mask THEN
            IF LoopVar = 0 THEN
                IF HitRow = 255 THEN HitRow = Row
            END IF
            IF LoopVar > 0 THEN LoopVar = LoopVar - 1
        END IF
    NEXT Row

    IF HitRow = 255 THEN RETURN

    RogueRow = HitRow

    ' Set alien type/color based on row (uses wave palette)
    IF RogueRow = 0 THEN
        RogueCard = GRAM_ALIEN1
        RogueColor = WaveColor0
    ELSEIF RogueRow < 3 THEN
        RogueCard = GRAM_ALIEN2
        RogueColor = WaveColor1
    ELSE
        RogueCard = GRAM_ALIEN3
        RogueColor = WaveColor2
    END IF

    RogueState = ROGUE_SHAKE
    RogueTimer = ROGUE_SHAKE_TIME
    RETURN
END

' --------------------------------------------
' RogueUpdate - Update rogue alien (shake, dive, collision)
' --------------------------------------------
RogueUpdate: PROCEDURE
    ' --- SHAKE STATE ---
    IF RogueState = ROGUE_SHAKE THEN
        RogueTimer = RogueTimer - 1

        ' Flash alien's BACKTAB tile between normal and white
        #ScreenPos = (ALIEN_START_Y + AlienOffsetY + RogueRow) * 20
        #ScreenPos = #ScreenPos + ALIEN_START_X + AlienOffsetX + RogueCol
        IF #ScreenPos < 220 THEN
            IF RogueTimer AND 4 THEN
                #Card = (RogueCard + AnimFrame) * 8 + COL_WHITE + $0800
            ELSE
                #Card = (RogueCard + AnimFrame) * 8 + RogueColor + $0800
            END IF
            PRINT AT #ScreenPos, #Card
        END IF

        IF RogueTimer = 0 THEN
            ' Remove from grid (guard against double-XOR if bullet killed during shake)
            #Mask = ColMaskData(RogueCol)
            IF #AlienRow(RogueRow) AND #Mask THEN
                #AlienRow(RogueRow) = #AlienRow(RogueRow) XOR #Mask
            END IF

            ' Clear BACKTAB tile
            IF #ScreenPos < 220 THEN
                PRINT AT #ScreenPos, 0
            END IF

            ' Set up circle center (12px below alien's grid position)
            RogueCenterX = (ALIEN_START_X + AlienOffsetX + RogueCol) * 8 + 8
            RogueCenterY = (ALIEN_START_Y + AlienOffsetY + RogueRow) * 8 + 8 + 12
            ' Sprite starts at top of circle (step 24: offset +0, -12)
            RogueX = RogueCenterX
            RogueY = RogueCenterY - 12

            RogueState = ROGUE_DIVE
            RogueDivePhase = 24   ' Start at top of circle
            RogueCol = 0          ' Reuse as step counter during dive
            RogueTimer = 0
        END IF
        RETURN
    END IF

    ' --- DIVE STATE (circular spiral) ---
    IF RogueState = ROGUE_DIVE THEN

        ' Exit mode: straight down off screen
        IF RogueDivePhase = 255 THEN
            RogueY = RogueY + 2
            IF RogueY >= 112 THEN
                RogueState = ROGUE_IDLE
                RogueTimer = 0 : RogueDivePhase = 0
                SPRITE SPR_FLYER, 0, 0, 0
                RETURN
            END IF
            GOTO RogueDiveRender
        END IF

        ' Dogfight strafing: sweeping attack passes
        IF RogueDivePhase = 254 THEN
            ' If player died, escape off-screen
            IF DeathTimer > 0 THEN
                RogueDivePhase = 255
                GOTO RogueDiveRender
            END IF
            RogueTimer = RogueTimer + 1
            ' Horizontal strafe: sweep in current direction at 2px/frame
            IF RogueCenterX THEN
                ' Moving right
                RogueX = RogueX + 2
                IF RogueX >= 156 THEN
                    RogueCenterX = 0 : RogueCenterY = RogueCenterY + 1
                ELSEIF RogueX > PlayerX + 20 THEN
                    IF RogueX > 20 THEN
                        RogueCenterX = 0 : RogueCenterY = RogueCenterY + 1
                    END IF
                END IF
            ELSE
                ' Moving left
                IF RogueX >= 2 THEN
                    RogueX = RogueX - 2
                ELSE
                    RogueX = 0
                END IF
                IF RogueX <= 8 THEN
                    RogueCenterX = 1 : RogueCenterY = RogueCenterY + 1
                ELSEIF PlayerX > 20 THEN
                    IF RogueX + 20 < PlayerX THEN
                        RogueCenterX = 1 : RogueCenterY = RogueCenterY + 1
                    END IF
                END IF
            END IF
            ' Gradual descent: 1px every 3 frames
            RogueCol = RogueCol + 1
            IF RogueCol >= 3 THEN
                RogueCol = 0
                RogueY = RogueY + 1
            END IF
            ' Fire when crossing player X (within 8px), rate-limited
            IF RogueTimer >= 30 THEN
                IF RogueX + 8 >= PlayerX THEN
                    IF RogueX <= PlayerX + 8 THEN
                        RogueTimer = 0
                        IF (#GameFlags AND FLAG_ABULLET) = 0 THEN
                            IF FlyState <> SAUCER_CHASE THEN
                                ABulletX = RogueX + 3
                                ABulletY = RogueY + 8
                                ABulFrame = ABulFrame AND 1
                                #GameFlags = #GameFlags OR FLAG_ABULLET
                            END IF
                        END IF
                    END IF
                END IF
            END IF
            ' Also fire when crossing wingman position (if present)
            IF #GameFlags AND FLAG_CAPTURE THEN
                IF RogueTimer >= 20 THEN
                    #ScreenPos = PlayerX - 4 + CaptureOrbitDX(CaptureStep) - CAPTURE_ORBIT_R
                    IF #ScreenPos < 200 THEN
                        IF RogueX + 8 >= #ScreenPos THEN
                            IF RogueX <= #ScreenPos + 8 THEN
                                RogueTimer = 0
                                IF (#GameFlags AND FLAG_ABULLET) = 0 THEN
                                    IF FlyState <> SAUCER_CHASE THEN
                                        ABulletX = RogueX + 3
                                        ABulletY = RogueY + 8
                                        ABulFrame = ABulFrame AND 1
                                        #GameFlags = #GameFlags OR FLAG_ABULLET
                                    END IF
                                END IF
                            END IF
                        END IF
                    END IF
                END IF
            END IF
            ' Exit after 4 passes or past player
            IF RogueCenterY >= 4 THEN RogueDivePhase = 255
            IF RogueY >= PLAYER_Y + 10 THEN RogueDivePhase = 255
            GOTO RogueDiveRender
        END IF

        ' === Circular spiral phase ===

        ' Advance circle step every 2 frames
        RogueTimer = RogueTimer + 1
        IF (RogueTimer AND 1) = 0 THEN
            RogueDivePhase = RogueDivePhase + 1
            IF RogueDivePhase >= 32 THEN RogueDivePhase = 0
            RogueCol = RogueCol + 1
        END IF

        ' Drift center down 1px every 2 frames (spiral effect)
        IF (RogueTimer AND 1) = 0 THEN
            RogueCenterY = RogueCenterY + 1
        END IF

        ' Compute actual sprite position from center + circle offset
        RogueX = RogueCenterX + RogueCircleDX(RogueDivePhase) - 12
        RogueY = RogueCenterY + RogueCircleDY(RogueDivePhase) - 12

        ' Break from circle into dogfight after 1+ loops and near player line
        IF RogueCol >= 32 THEN
            IF RogueCenterY >= 68 THEN
                RogueDivePhase = 254
                IF RogueX < PlayerX THEN RogueCenterX = 1 ELSE RogueCenterX = 0
                RogueCenterY = 0  ' Pass counter
                RogueCol = 0     ' Descent frame counter
                RogueTimer = 0   ' Fire rate timer
            END IF
        END IF
        ' Safety: if sprite too low, go straight to chase
        IF RogueY >= 100 THEN
            IF RogueDivePhase < 32 THEN
                RogueDivePhase = 254
                IF RogueX < PlayerX THEN RogueCenterX = 1 ELSE RogueCenterX = 0
                RogueCenterY = 0
                RogueCol = 0
                RogueTimer = 0
            END IF
        END IF

        ' Fire bullet at bottom of circle (step 8, closest to player)
        IF RogueDivePhase = 8 THEN
            IF (RogueTimer AND 1) = 0 THEN
                IF (#GameFlags AND FLAG_ABULLET) = 0 THEN
                    IF FlyState <> SAUCER_CHASE THEN
                        ABulletX = RogueX + 3
                        ABulletY = RogueY + 8
                        ABulFrame = ABulFrame AND 1
                        #GameFlags = #GameFlags OR FLAG_ABULLET
                    END IF
                END IF
            END IF
        END IF

RogueDiveRender:
        ' Render rogue sprite
        SPRITE SPR_FLYER, RogueX + $0200, RogueY, (RogueCard + AnimFrame) * 8 + RogueColor + $0800

        ' Body collision with player
        IF DeathTimer = 0 THEN
            IF Invincible = 0 THEN
                IF RogueY >= PLAYER_Y - 6 THEN
                    IF RogueY <= PLAYER_Y + 6 THEN
                        IF RogueX >= PlayerX - 6 THEN
                            IF RogueX <= PlayerX + 8 THEN
                                ' Rogue body hit - check shield first
                                IF ShieldHits > 0 THEN
                                    GOSUB HitShield
                                ELSE
                                    #GameFlags = #GameFlags OR FLAG_PLAYERHIT
                                    SfxType = 1 : SfxVolume = 15 : #SfxPitch = 100
                                    SOUND 2, 100, 15
                                END IF
                                ' Either way, destroy rogue
                                RogueState = ROGUE_IDLE
                                RogueTimer = 0 : RogueDivePhase = 0
                                SPRITE SPR_FLYER, 0, 0, 0
                            END IF
                        END IF
                    END IF
                END IF
            END IF
        END IF
        RETURN
    END IF
    RETURN
END

' --------------------------------------------
' UpdateSaucer - Spawn, move, and check collision for flying saucer
' --------------------------------------------
UpdateSaucer: PROCEDURE
    IF FlyState = 0 THEN
        ' Inactive - count up to random spawn threshold (1-4 seconds)
        #FlyPhase = #FlyPhase + 1
        IF #FlyPhase >= #FlyLoopCount THEN
            ' Spawn! Pick random direction
            #FlyPhase = 0
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
            FlyColorTimer = 0
            FlyColor = 4        ' Dark Green
            ' Rare chance: saucer will go hostile at midpoint (1-in-8)
            IF RANDOM(8) = 0 THEN
                #GameFlags = #GameFlags OR FLAG_ANGRY
            ELSE
                #GameFlags = #GameFlags AND $FDFF
            END IF
        END IF
        RETURN
    END IF

    ' Swirl state: circular pattern before entering chase
    IF FlyState = SAUCER_SWIRL THEN
        ' If player death animation nearly done, escape (stay visible during explosion)
        IF DeathTimer > 0 THEN
            IF DeathTimer < 40 THEN
                FlyState = SAUCER_ESCAPE
                FlySpeed = 0
            END IF
            GOSUB SaucerAnimate : RETURN
        END IF

        ' Advance circle step every 2 frames
        FlySpeed = FlySpeed + 1
        IF (FlySpeed AND 1) = 0 THEN
            FlyColorTimer = FlyColorTimer + 1
            IF FlyColorTimer >= 32 THEN FlyColorTimer = 0
            #FlyLoopCount = #FlyLoopCount + 1
        END IF

        ' Drift center down 1px every 4 frames
        IF (FlySpeed AND 3) = 0 THEN
            FlyCenterY = FlyCenterY + 1
        END IF

        ' Compute sprite position from center + circle offset
        FlyX = FlyCenterX + RogueCircleDX(FlyColorTimer) - 12
        FlyY = FlyCenterY + RogueCircleDY(FlyColorTimer) - 12

        ' After 2 full loops (64 steps), transition to chase
        IF #FlyLoopCount >= 64 THEN
            FlyState = SAUCER_CHASE
            IF FlyX < PlayerX THEN FlyCenterX = 1 ELSE FlyCenterX = 0
            FlyCenterY = 0  ' Pass counter
            #FlyLoopCount = 0
            FlySpeed = 0
        END IF

        GOSUB SaucerAnimate : RETURN
    END IF

    ' Chase state: strafing attack passes (identical pattern to rogue dogfight)
    IF FlyState = SAUCER_CHASE THEN
        ' If player death animation nearly done, saucer escapes (stay visible during explosion)
        IF DeathTimer > 0 THEN
            IF DeathTimer < 40 THEN
                FlyState = SAUCER_ESCAPE
                FlySpeed = 0
            END IF
            GOSUB SaucerAnimate : RETURN
        END IF
        FlySpeed = FlySpeed + 1
        ' Horizontal strafe: sweep in current direction at 2px/frame
        IF FlyCenterX THEN
            ' Moving right
            FlyX = FlyX + 2
            IF FlyX >= 156 THEN
                FlyCenterX = 0 : FlyCenterY = FlyCenterY + 1
            ELSEIF FlyX > PlayerX + 20 THEN
                IF FlyX > 20 THEN
                    FlyCenterX = 0 : FlyCenterY = FlyCenterY + 1
                END IF
            END IF
        ELSE
            ' Moving left
            IF FlyX >= 2 THEN
                FlyX = FlyX - 2
            ELSE
                FlyX = 0
            END IF
            IF FlyX <= 8 THEN
                FlyCenterX = 1 : FlyCenterY = FlyCenterY + 1
            ELSEIF PlayerX > 20 THEN
                IF FlyX + 20 < PlayerX THEN
                    FlyCenterX = 1 : FlyCenterY = FlyCenterY + 1
                END IF
            END IF
        END IF
        ' Gradual descent: 1px every 3 frames
        #FlyLoopCount = #FlyLoopCount + 1
        IF #FlyLoopCount >= 3 THEN
            #FlyLoopCount = 0
            FlyY = FlyY + 1
        END IF
        ' Fire when crossing player X (within 8px), rate-limited
        IF FlySpeed >= 30 THEN
            IF FlyX + 8 >= PlayerX THEN
                IF FlyX <= PlayerX + 8 THEN
                    FlySpeed = 0
                    IF (#GameFlags AND FLAG_ABULLET) = 0 THEN
                        ABulletX = FlyX + 4
                        ABulletY = FlyY + 8
                        #GameFlags = #GameFlags OR FLAG_ABULLET
                    END IF
                END IF
            END IF
        END IF
        ' Body collision: saucer overlaps player
        IF FlyY >= PLAYER_Y - 8 THEN
            IF Invincible = 0 THEN
            IF FlyX >= PlayerX - 8 THEN
                IF FlyX <= PlayerX + 16 THEN
                    ' Saucer body hit - check shield first
                    IF ShieldHits > 0 THEN
                        GOSUB HitShield
                    ELSE
                        #GameFlags = #GameFlags OR FLAG_PLAYERHIT
                    END IF
                END IF
            END IF
            END IF
        END IF
        ' Exit after 4 passes or past player
        IF FlyCenterY >= 4 THEN
            FlyState = SAUCER_ESCAPE
            FlySpeed = 0
        END IF
        IF FlyY >= PLAYER_Y + 10 THEN
            FlyState = SAUCER_ESCAPE
            FlySpeed = 0
        END IF
        GOSUB SaucerAnimate : RETURN
    END IF

    ' Escape state: fly off diagonally (runs every frame)
    IF FlyState = SAUCER_ESCAPE THEN
        IF FlyY > 3 THEN
            FlyY = FlyY - 3
        ELSE
            FlyY = 0
        END IF
        FlyX = FlyX + 2
        IF FlyX > 167 THEN
            GOSUB DeactivateSaucer
            RETURN
        END IF
        IF FlyY = 0 THEN
            GOSUB DeactivateSaucer
            RETURN
        END IF
        GOSUB SaucerAnimate : RETURN
    END IF

    ' Normal movement (FlyState 1 or 2)
    FlySpeed = FlySpeed + 1
    IF FlySpeed >= 2 THEN
        FlySpeed = 0
        IF FlyState = 1 THEN
            FlyX = FlyX + 1
            IF FlyX > 167 THEN
                GOSUB DeactivateSaucer
                RETURN
            END IF
        ELSE
            IF FlyX > 0 THEN
                FlyX = FlyX - 1
            ELSE
                GOSUB DeactivateSaucer
                RETURN
            END IF
        END IF
        ' Normal saucer fires occasionally (slower than chase mode)
        FlyColorTimer = FlyColorTimer + 1
        IF FlyColorTimer >= 90 THEN
            FlyColorTimer = 0
            IF #GameFlags = #GameFlags AND $FFFD THEN
                ABulletX = FlyX + 4
                ABulletY = FlyY + 8
                #GameFlags = #GameFlags OR FLAG_ABULLET
            END IF
        END IF
        ' Midpoint check: angry saucer goes hostile at ~50% across screen
        IF #GameFlags AND FLAG_ANGRY THEN
            IF FlyX >= 72 THEN
                IF FlyX <= 88 THEN
                    #GameFlags = #GameFlags AND $FDFF
                    FlyState = SAUCER_SWIRL
                    FlyCenterX = FlyX
                    FlyCenterY = FlyY + 12
                    FlyColorTimer = 24  ' Start at top of circle
                    #FlyLoopCount = 0
                    FlySpeed = 0
                    FlyColor = COL_RED
                END IF
            END IF
        END IF
    END IF

    ' Normal movement ends here - call animation and return
    GOSUB SaucerAnimate
    RETURN
END

' --------------------------------------------
' SaucerAnimate - Saucer animation and bullet collision
' Extracted from UpdateSaucer for clarity
' --------------------------------------------
SaucerAnimate: PROCEDURE
    ' Animate saucer: 4-frame window scan + color based on powerup type
    ' Uses pre-loaded GRAM frames (no DEFINE during gameplay for performance)
    #FlyPhase = #FlyPhase + 1
    IF #FlyPhase >= 24 THEN #FlyPhase = 0
    IF #FlyPhase < 6 THEN
        SaucerCard = GRAM_SAUCER                ' All windows dark
        FlyColor = SaucerColor1(TitleColor)     ' Primary color
    ELSEIF #FlyPhase < 12 THEN
        SaucerCard = GRAM_SAUCER_F2             ' Inner window lit
        FlyColor = SaucerColor2(TitleColor)     ' Secondary color
    ELSEIF #FlyPhase < 18 THEN
        SaucerCard = GRAM_SAUCER_F3             ' Outer window lit
        FlyColor = SaucerColor1(TitleColor)     ' Primary color
    ELSE
        SaucerCard = GRAM_SAUCER_F4             ' Both windows + engine glow
        FlyColor = SaucerColor2(TitleColor)     ' Secondary color
    END IF

    ' Draw saucer as 2 sprites: left half + FLIPX right half (16px wide)
    ' Handle pastel colors (8+) to avoid bit overflow into card number
    IF FlyColor >= 8 THEN
        #Card = SaucerCard * 8 + (FlyColor AND 7) + $1800
    ELSE
        #Card = SaucerCard * 8 + FlyColor + $0800
    END IF
    SPRITE SPR_SAUCER, FlyX + $0200, FlyY, #Card
    SPRITE SPR_SAUCER2, (FlyX + 8) + $0200, FlyY + $0400, #Card

    ' Check collision with player bullet (Y range follows saucer position)
    IF #GameFlags AND FLAG_BULLET THEN
        IF BulletY + 6 >= FlyY THEN
            IF BulletY <= FlyY + 6 THEN
                IF BulletX >= FlyX - 4 THEN
                    IF BulletX <= FlyX + 16 THEN
                        GOSUB SaucerHit
                    END IF
                END IF
            END IF
        END IF
    END IF

    ' Check collision with wingman bullet (convert BACKTAB row/col to pixels)
    IF #GameFlags AND FLAG_CAPBULLET THEN
        ' Convert wingman bullet to pixel coords: col*8+8, row*8+8
        CapPixelX = CapBulletCol * 8 + 8
        CapPixelY = CapBulletRow * 8 + 8
        IF CapPixelY + 6 >= FlyY THEN
            IF CapPixelY <= FlyY + 6 THEN
                IF CapPixelX >= FlyX - 4 THEN
                    IF CapPixelX <= FlyX + 16 THEN
                        ' Clear the wingman bullet from BACKTAB
                        #ScreenPos = CapBulletRow * 20 + CapBulletCol
                        IF #ScreenPos < 240 THEN PRINT AT #ScreenPos, 0
                        #GameFlags = #GameFlags AND $FFF7  ' Deactivate wingman bullet
                        GOSUB SaucerHit
                    END IF
                END IF
            END IF
        END IF
    END IF

    RETURN
END

' --------------------------------------------
' SaucerHit - Handle saucer destruction (shared by player and wingman bullets)
' --------------------------------------------
SaucerHit: PROCEDURE
    ' Deactivate player bullet if it was the one that hit
    #GameFlags = #GameFlags AND $FFFE
    ChainCount = 0  ' Saucer is not an alien — break chain
    GOSUB DeactivateSaucer
    ' Saucer crash SFX (deep rumble + descending pitch)
    SfxType = 2 : SfxVolume = 15 : #SfxPitch = 150
    SOUND 2, 150, 15  ' Immediate tone hit on channel 3
    ' Bonus points
    #Score = #Score + 100
    ' Drop power-up from saucer position
    TitleFrame = 1       ' Falling
    TitleMarchDir = FlyX        ' Drop from saucer X
    PowerUpY = FlyY      ' Start falling from saucer Y
    SlidePos = 0
    ' First powerup tutorial hint (flashing)
    IF TutorialTimer = 255 THEN TutorialTimer = 180
    ' Clear previous explosion tile if still active
    IF ExplosionTimer > 0 THEN
        IF #ExplosionPos < 220 THEN PRINT AT #ExplosionPos, 0
    END IF
    ' Show explosion at saucer position using BACKTAB
    #ExplosionPos = FlyX / 8
    ExplosionTimer = 15
    PRINT AT #ExplosionPos, GRAM_EXPLOSION * 8 + 4 + $1800
    RETURN
END

' Column bitmask lookup table: ColMaskData(n) = 2^n (0-9)
ColMaskData:
    DATA 1, 2, 4, 8, 16, 32, 64, 128, 256, 512

' Pattern B formations (5 bitmasks per pattern, one per row)
PatternBData:
    DATA $100, $082, $044, $028, $010  ' 0: V-shape (chevron pointing down)
    DATA $010, $038, $07C, $038, $010  ' 1: Diamond
    DATA $101, $101, $101, $101, $101  ' 2: Walls (left+right columns)
    DATA $010, $010, $1FF, $010, $010  ' 3: Cross / Plus
    DATA $155, $0AA, $155, $0AA, $155  ' 4: Checkerboard
    DATA $010, $028, $044, $082, $101  ' 5: Arrow pointing up
    DATA $038, $07C, $0FE, $07C, $038  ' 6: Fortress (dense concentric diamond)
    DATA $1FF, $000, $1FF, $000, $1FF  ' 7: Phalanx (3 dense rows, 2 gaps)

' Which pattern B per level (wraps after 8)
PatternBIndex:
    DATA 0, 1, 2, 3, 4, 5, 6, 7

' ============================================
' Flight Patterns — DATA tables
' ============================================

' Rogue alien circular flight offsets (32 steps, radius 12, bias 12)
' Step 0 = rightmost (3 o'clock), step 8 = bottom, step 16 = left, step 24 = top
RogueCircleDX:
    DATA 24, 24, 23, 22, 20, 19, 17, 14
    DATA 12, 10, 7, 5, 4, 2, 1, 0
    DATA 0, 0, 1, 2, 4, 5, 7, 10
    DATA 12, 14, 17, 19, 20, 22, 23, 24

RogueCircleDY:
    DATA 12, 14, 17, 19, 20, 22, 23, 24
    DATA 24, 24, 23, 22, 20, 19, 17, 14
    DATA 12, 10, 7, 5, 4, 2, 1, 0
    DATA 0, 0, 1, 2, 4, 5, 7, 10

' Capture wingman orbit offsets (16 steps, radius 6, bias 6)
' Step 0 = rightmost, step 4 = bottom, step 8 = left, step 12 = top
CaptureOrbitDX:
    DATA 12, 11, 10, 8, 6, 4, 2, 1
    DATA 0, 1, 2, 4, 6, 8, 10, 11

CaptureOrbitDY:
    DATA 6, 8, 10, 11, 12, 11, 10, 8
    DATA 6, 4, 2, 1, 0, 1, 2, 4

' Wave color palettes (6 palettes, indexed by (Level-1) MOD 6)
' Each palette: squid (row 0), crab (rows 1-2), octopus (rows 3-4)
WavePalette0:
    DATA 6, 7, 5, 2, 1, 3  ' Squid colors:  Yel, Wht, Grn, Red, Blu, Tan
WavePalette1:
    DATA 1, 2, 3, 7, 5, 6  ' Crab colors:   Blu, Red, Tan, Wht, Grn, Yel
WavePalette2:
    DATA 5, 6, 1, 3, 2, 7  ' Octopus colors: Grn, Yel, Blu, Tan, Red, Wht

' Wave entrance patterns (8 entries, indexed by (Level-1) MOD 8)
' 0 = left sweep (columns appear left-to-right)
' 1 = top-down (rows appear top-to-bottom)
' Pattern B always uses pincer (both sides meet in middle)
WaveEntranceData:
    ' 0=Left sweep, 1=Top-down reveal (rows in place), 2=Fly-down from above
    DATA 1, 0, 1, 0, 2, 0, 1, 2  ' Waves 1-8: T, L, T, L, F, L, T, F

' Pattern 0: Figure-8 Lissajous (title screen, 316 waypoints)
' x = 84 + 50*sin(t), y = 56 + 18*sin(2t)
' High density: every segment = 1px, path IS the curve
FlightFigure8X:
    DATA 84, 85, 85, 86, 86, 87, 88, 89
    DATA 89, 90, 91, 92, 92, 93, 93, 94
    DATA 95, 95, 96, 96, 97, 98, 98, 99
    DATA 99, 100, 101, 101, 102, 103, 103, 104
    DATA 105, 106, 107, 108, 109, 109, 110, 111
    DATA 112, 113, 114, 115, 115, 116, 117, 118
    DATA 119, 120, 121, 122, 123, 123, 124, 125
    DATA 126, 126, 127, 128, 129, 129, 130, 130
    DATA 130, 131, 131, 132, 132, 132, 133, 133
    DATA 133, 133, 134, 134, 134, 134, 134, 134
    DATA 134, 134, 134, 134, 134, 133, 133, 133
    DATA 133, 132, 132, 132, 131, 131, 130, 130
    DATA 130, 129, 129, 128, 127, 126, 126, 125
    DATA 124, 123, 123, 122, 121, 120, 119, 118
    DATA 117, 116, 115, 115, 114, 113, 112, 111
    DATA 110, 109, 109, 108, 107, 106, 105, 104
    DATA 103, 103, 102, 101, 101, 100, 99, 99
    DATA 98, 98, 97, 96, 96, 95, 95, 94
    DATA 93, 93, 92, 92, 91, 90, 89, 89
    DATA 88, 87, 86, 86, 85, 85, 84, 83
    DATA 83, 82, 82, 81, 80, 79, 79, 78
    DATA 77, 76, 76, 75, 75, 74, 73, 73
    DATA 72, 72, 71, 70, 70, 69, 69, 68
    DATA 67, 67, 66, 65, 65, 64, 63, 62
    DATA 61, 60, 59, 59, 58, 57, 56, 55
    DATA 54, 53, 53, 52, 51, 50, 49, 48
    DATA 47, 46, 45, 45, 44, 43, 42, 42
    DATA 41, 40, 39, 39, 38, 38, 38, 37
    DATA 37, 36, 36, 36, 35, 35, 35, 35
    DATA 34, 34, 34, 34, 34, 34, 34, 34
    DATA 34, 34, 34, 35, 35, 35, 35, 36
    DATA 36, 36, 37, 37, 38, 38, 38, 39
    DATA 39, 40, 41, 42, 42, 43, 44, 45
    DATA 45, 46, 47, 48, 49, 50, 51, 52
    DATA 53, 53, 54, 55, 56, 57, 58, 59
    DATA 59, 60, 61, 62, 63, 64, 65, 65
    DATA 66, 67, 67, 68, 69, 69, 70, 70
    DATA 71, 72, 72, 73, 73, 74, 75, 75
    DATA 76, 76, 77, 78, 79, 79, 80, 81
    DATA 82, 82, 83, 83
FlightFigure8Y:
    DATA 56, 56, 57, 57, 58, 58, 59, 59
    DATA 60, 60, 61, 61, 62, 62, 63, 63
    DATA 63, 64, 64, 65, 65, 65, 66, 66
    DATA 67, 67, 67, 68, 68, 68, 69, 69
    DATA 70, 70, 71, 71, 71, 72, 72, 72
    DATA 73, 73, 73, 73, 74, 74, 74, 74
    DATA 74, 74, 74, 74, 74, 73, 73, 73
    DATA 73, 72, 72, 71, 71, 70, 70, 69
    DATA 68, 68, 67, 67, 66, 65, 64, 63
    DATA 62, 61, 61, 60, 59, 58, 57, 56
    DATA 55, 54, 53, 52, 51, 51, 50, 49
    DATA 48, 47, 46, 45, 45, 44, 44, 43
    DATA 42, 42, 41, 41, 40, 40, 39, 39
    DATA 39, 39, 38, 38, 38, 38, 38, 38
    DATA 38, 38, 38, 39, 39, 39, 39, 40
    DATA 40, 40, 41, 41, 41, 42, 42, 43
    DATA 43, 44, 44, 44, 45, 45, 45, 46
    DATA 46, 47, 47, 47, 48, 48, 49, 49
    DATA 49, 50, 50, 51, 51, 52, 52, 53
    DATA 53, 54, 54, 55, 55, 56, 56, 56
    DATA 57, 57, 58, 58, 59, 59, 60, 60
    DATA 61, 61, 62, 62, 63, 63, 63, 64
    DATA 64, 65, 65, 65, 66, 66, 67, 67
    DATA 67, 68, 68, 68, 69, 69, 70, 70
    DATA 71, 71, 71, 72, 72, 72, 73, 73
    DATA 73, 73, 74, 74, 74, 74, 74, 74
    DATA 74, 74, 74, 73, 73, 73, 73, 72
    DATA 72, 71, 71, 70, 70, 69, 68, 68
    DATA 67, 67, 66, 65, 64, 63, 62, 61
    DATA 61, 60, 59, 58, 57, 56, 55, 54
    DATA 53, 52, 51, 51, 50, 49, 48, 47
    DATA 46, 45, 45, 44, 44, 43, 42, 42
    DATA 41, 41, 40, 40, 39, 39, 39, 39
    DATA 38, 38, 38, 38, 38, 38, 38, 38
    DATA 38, 39, 39, 39, 39, 40, 40, 40
    DATA 41, 41, 41, 42, 42, 43, 43, 44
    DATA 44, 44, 45, 45, 45, 46, 46, 47
    DATA 47, 47, 48, 48, 49, 49, 49, 50
    DATA 50, 51, 51, 52, 52, 53, 53, 54
    DATA 54, 55, 55, 56

' Pattern 1: Organic Orbit (game over, 356 waypoints)
' x = 78 + 70*cos(t) + 6*cos(3t), y = 19 + 17*sin(t) + 3*sin(2t)
' High density: every segment = 1px, path IS the curve
FlightOrbitX:
    DATA 154, 154, 154, 153, 153, 152, 152, 151
    DATA 150, 149, 149, 148, 147, 147, 146, 145
    DATA 145, 144, 143, 143, 142, 141, 140, 140
    DATA 139, 138, 137, 136, 135, 134, 134, 133
    DATA 132, 131, 130, 129, 128, 127, 126, 126
    DATA 125, 124, 123, 122, 121, 121, 120, 119
    DATA 118, 117, 116, 115, 114, 113, 112, 111
    DATA 110, 109, 108, 107, 106, 105, 105, 104
    DATA 103, 102, 101, 100, 99, 98, 97, 96
    DATA 95, 94, 93, 92, 91, 90, 89, 88
    DATA 87, 86, 85, 84, 83, 83, 82, 81
    DATA 80, 79, 78, 77, 76, 75, 74, 74
    DATA 73, 72, 71, 70, 69, 68, 67, 66
    DATA 65, 64, 63, 62, 62, 61, 60, 59
    DATA 58, 57, 56, 55, 54, 53, 52, 51
    DATA 51, 50, 49, 48, 47, 46, 46, 45
    DATA 44, 43, 42, 41, 40, 39, 38, 37
    DATA 36, 35, 35, 34, 33, 32, 31, 30
    DATA 30, 29, 28, 27, 26, 25, 25, 24
    DATA 23, 22, 21, 20, 20, 19, 18, 17
    DATA 16, 15, 14, 13, 12, 11, 10, 9
    DATA 8, 8, 7, 6, 5, 5, 4, 3
    DATA 3, 2, 2, 2, 3, 3, 4, 5
    DATA 5, 6, 7, 8, 8, 9, 10, 11
    DATA 12, 13, 14, 15, 16, 17, 18, 19
    DATA 20, 20, 21, 22, 23, 24, 25, 25
    DATA 26, 27, 28, 29, 30, 30, 31, 32
    DATA 33, 34, 35, 35, 36, 37, 38, 39
    DATA 40, 41, 42, 43, 44, 45, 46, 46
    DATA 47, 48, 49, 50, 51, 51, 52, 53
    DATA 54, 55, 56, 57, 58, 59, 60, 61
    DATA 62, 62, 63, 64, 65, 66, 67, 68
    DATA 69, 70, 71, 72, 73, 74, 74, 75
    DATA 76, 77, 78, 79, 80, 81, 82, 83
    DATA 83, 84, 85, 86, 87, 88, 89, 90
    DATA 91, 92, 93, 94, 95, 96, 97, 98
    DATA 99, 100, 101, 102, 103, 104, 105, 105
    DATA 106, 107, 108, 109, 110, 111, 112, 113
    DATA 114, 115, 116, 117, 118, 119, 120, 121
    DATA 121, 122, 123, 124, 125, 126, 126, 127
    DATA 128, 129, 130, 131, 132, 133, 134, 134
    DATA 135, 136, 137, 138, 139, 140, 140, 141
    DATA 142, 143, 143, 144, 145, 145, 146, 147
    DATA 147, 148, 149, 149, 150, 151, 152, 152
    DATA 153, 153, 154, 154
FlightOrbitY:
    DATA 19, 20, 21, 21, 22, 23, 24, 24
    DATA 25, 25, 26, 26, 26, 27, 27, 27
    DATA 28, 28, 28, 29, 29, 29, 29, 30
    DATA 30, 30, 31, 31, 31, 31, 32, 32
    DATA 32, 32, 33, 33, 33, 33, 33, 34
    DATA 34, 34, 34, 34, 34, 35, 35, 35
    DATA 35, 35, 35, 35, 36, 36, 36, 36
    DATA 36, 36, 36, 36, 36, 36, 37, 37
    DATA 37, 37, 37, 37, 37, 37, 37, 37
    DATA 37, 37, 37, 37, 37, 37, 37, 37
    DATA 37, 37, 37, 37, 37, 36, 36, 36
    DATA 36, 36, 36, 36, 36, 36, 36, 35
    DATA 35, 35, 35, 35, 35, 35, 34, 34
    DATA 34, 34, 34, 34, 33, 33, 33, 33
    DATA 33, 33, 32, 32, 32, 32, 32, 32
    DATA 31, 31, 31, 31, 31, 31, 30, 30
    DATA 30, 30, 30, 30, 29, 29, 29, 29
    DATA 29, 29, 28, 28, 28, 28, 28, 28
    DATA 27, 27, 27, 27, 27, 27, 26, 26
    DATA 26, 26, 26, 26, 25, 25, 25, 25
    DATA 25, 24, 24, 24, 24, 23, 23, 23
    DATA 23, 22, 22, 22, 22, 21, 21, 21
    DATA 20, 20, 19, 18, 18, 17, 17, 17
    DATA 16, 16, 16, 16, 15, 15, 15, 15
    DATA 14, 14, 14, 14, 13, 13, 13, 13
    DATA 13, 12, 12, 12, 12, 12, 12, 11
    DATA 11, 11, 11, 11, 11, 10, 10, 10
    DATA 10, 10, 10, 9, 9, 9, 9, 9
    DATA 9, 8, 8, 8, 8, 8, 8, 7
    DATA 7, 7, 7, 7, 7, 6, 6, 6
    DATA 6, 6, 6, 5, 5, 5, 5, 5
    DATA 5, 4, 4, 4, 4, 4, 4, 3
    DATA 3, 3, 3, 3, 3, 3, 2, 2
    DATA 2, 2, 2, 2, 2, 2, 2, 2
    DATA 1, 1, 1, 1, 1, 1, 1, 1
    DATA 1, 1, 1, 1, 1, 1, 1, 1
    DATA 1, 1, 1, 1, 1, 1, 1, 2
    DATA 2, 2, 2, 2, 2, 2, 2, 2
    DATA 2, 3, 3, 3, 3, 3, 3, 3
    DATA 4, 4, 4, 4, 4, 4, 5, 5
    DATA 5, 5, 5, 6, 6, 6, 6, 7
    DATA 7, 7, 7, 8, 8, 8, 9, 9
    DATA 9, 9, 10, 10, 10, 11, 11, 11
    DATA 12, 12, 12, 13, 13, 14, 14, 15
    DATA 16, 17, 17, 18

' ============================================
' Flight Engine Procedures
' ============================================

' --------------------------------------------
' FlightStart - Load a pattern and begin transition
' Input: LoopVar = pattern ID (PAT_FIGURE8, PAT_DIAMOND, etc.)
' Preserves current FlyX/FlyY as starting position
' --------------------------------------------
FlightStart: PROCEDURE
    IF LoopVar = PAT_FIGURE8 THEN
        #PathXAddr = VARPTR FlightFigure8X(0)
        #PathYAddr = VARPTR FlightFigure8Y(0)
        #FlyPathLen = 316
        FlyStepRate = 2
        FlyMaxLoops = 2
        FlyTransSpd = 1
    ELSEIF LoopVar = PAT_DIAMOND THEN
        #PathXAddr = VARPTR FlightOrbitX(0)
        #PathYAddr = VARPTR FlightOrbitY(0)
        #FlyPathLen = 356
        FlyStepRate = 2
        FlyMaxLoops = 0       ' Infinite
        FlyTransSpd = 2
    END IF
    FlyState = FLT_TRANSITION
    #FlyPhase = 0
    FlySpeed = 0
    #FlyLoopCount = 0
    RETURN
    END

' --------------------------------------------
' FlightTick - Per-frame flight engine update
' Updates FlyX, FlyY. Sets FlyState to FLT_DONE when loops complete.
' --------------------------------------------
FlightTick: PROCEDURE
    IF FlyState = FLT_IDLE THEN RETURN
    IF FlyState >= FLT_DONE THEN RETURN

    IF FlyState = FLT_TRANSITION THEN
        ' Move toward first waypoint each frame
        Col = PEEK(#PathXAddr)    ' Target X
        Row = PEEK(#PathYAddr)    ' Target Y
        ' Step X toward target
        IF FlyX < Col THEN
            FlyX = FlyX + FlyTransSpd
            IF FlyX > Col THEN FlyX = Col
        ELSEIF FlyX > Col THEN
            IF FlyX >= FlyTransSpd THEN
                FlyX = FlyX - FlyTransSpd
            ELSE
                FlyX = 0
            END IF
            IF FlyX < Col THEN FlyX = Col
        END IF
        ' Step Y toward target
        IF FlyY < Row THEN
            FlyY = FlyY + FlyTransSpd
            IF FlyY > Row THEN FlyY = Row
        ELSEIF FlyY > Row THEN
            IF FlyY >= FlyTransSpd THEN
                FlyY = FlyY - FlyTransSpd
            ELSE
                FlyY = 0
            END IF
            IF FlyY < Row THEN FlyY = Row
        END IF
        ' Check if arrived at target
        IF FlyX = Col THEN
            IF FlyY = Row THEN
                FlyState = FLT_FOLLOWING
                #FlyPhase = 0
                FlySpeed = 0
            END IF
        END IF
        RETURN
    END IF

    ' FLT_FOLLOWING: traverse high-density curve
    ' FlyStepRate = waypoints to advance per frame (speed control)
    #FlyPhase = #FlyPhase + FlyStepRate
    IF #FlyPhase >= #FlyPathLen THEN
        #FlyPhase = 0
        #FlyLoopCount = #FlyLoopCount + 1
        IF FlyMaxLoops > 0 THEN
            IF #FlyLoopCount >= FlyMaxLoops THEN
                FlyState = FLT_DONE
                RETURN
            END IF
        END IF
    END IF
    FlyX = PEEK(#PathXAddr + #FlyPhase)
    FlyY = PEEK(#PathYAddr + #FlyPhase)
    RETURN
    END

' --------------------------------------------
' ZodRender - Draw Zod with wing flap + color cycle
' Called each frame during game over screen
' --------------------------------------------
ZodRender: PROCEDURE
    FlyFrame = FlyFrame + 1
    IF FlyFrame >= 16 THEN FlyFrame = 0
    FlyColorTimer = FlyColorTimer + 1
    IF FlyColorTimer >= 24 THEN
        FlyColorTimer = 0
        FlyColorIdx = FlyColorIdx + 1
        IF FlyColorIdx >= 6 THEN FlyColorIdx = 0
        FlyColor = FlyColors(FlyColorIdx)
    END IF
    IF FlyFrame < 8 THEN
        SPRITE SPR_FLYER, FlyX + SPR_VISIBLE, FlyY, GRAM_CRAB_F1 * 8 + FlyColor + $0800
    ELSE
        SPRITE SPR_FLYER, FlyX + SPR_VISIBLE, FlyY, GRAM_CRAB_F2 * 8 + FlyColor + $0800
    END IF
    RETURN
    END

    ' (continuing in Segment 2 — flight engine, graphics data, music)

' --------------------------------------------
' Graphics Data
' --------------------------------------------
ShipGfx:
    ' Player ship body - Frame 0 (blocky tank-style cannon)
    BITMAP "........"
    BITMAP "...XX..."
    BITMAP "...XX..."
    BITMAP "..XXXX.."
    BITMAP "X.X..X.X"
    BITMAP "XXXXXXXX"
    BITMAP "XX....XX"
    BITMAP "........"

    ' Frame 1 (engine glow variation)
    BITMAP "........"
    BITMAP "...XX..."
    BITMAP "...XX..."
    BITMAP "..XXXX.."
    BITMAP "X.X..X.X"
    BITMAP "XXXXXXXX"
    BITMAP "X......X"
    BITMAP "........"

' Compact "X" multiplier for HUD lives display
ShipHudGfx:
    BITMAP "...#...."
    BITMAP "#.#.#.#."
    BITMAP "#######."
    BITMAP "##...##."
    BITMAP "........"
    BITMAP "....X.X."
    BITMAP ".....X.."
    BITMAP "....X.X."

' Ship accent overlay (fills gaps in body for 2-color effect)
ShipAccentGfx:
    ' Frame 0 - engine glow (cyan fills center gap in rows 6-7)
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "..XXXX.."
    BITMAP "..XXXX.."
    BITMAP "........"

    ' Frame 1 - brighter engine glow
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP ".XXXXXX."
    BITMAP ".XXXXXX."
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

' Warp-in animation frames (universal for all alien types)
WarpInGfx1:
    ' Frame 1: single pixel - just arriving from hyperspace
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "...X...."
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"

WarpInGfx2:
    ' Frame 2: forming cluster - coalescing from warp
    BITMAP "........"
    BITMAP "........"
    BITMAP "...X...."
    BITMAP "..XXX..."
    BITMAP "..X.X..."
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"

WarpInGfx3:
    ' Frame 3: nearly solid - about to lock in as alien
    BITMAP "........"
    BITMAP "...X...."
    BITMAP "..XXX..."
    BITMAP "..X.X..."
    BITMAP "..XXX..."
    BITMAP "..XXX..."
    BITMAP "........"
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

' --- WINGMAN (Mooninite-style, 8x8) ---
' Blocky rectangular alien with attitude
WingmanF1Gfx:
    BITMAP "........"
    BITMAP ".XXXXXX."
    BITMAP ".X.XX.X."
    BITMAP ".XXXXXX."
    BITMAP ".X....X."
    BITMAP ".X....X."
    BITMAP "..X..X.."
    BITMAP "........"

WingmanF2Gfx:
    BITMAP "........"
    BITMAP ".XXXXXX."
    BITMAP ".X.XX.X."
    BITMAP ".XXXXXX."
    BITMAP "..X..X.."
    BITMAP ".X....X."
    BITMAP ".X....X."
    BITMAP "........"

' Speech bubble graphics (escape animation)
' Two cards side by side spell "bye!" in lowercase
Bye1Gfx:
    BITMAP "X......."
    BITMAP "X......."
    BITMAP "XX..X.X."
    BITMAP "X.X.X.X."
    BITMAP "X.X.X.X."
    BITMAP "XX...X.."
    BITMAP "....XX.."
    BITMAP "........"

Bye2Gfx:
    BITMAP "....X..."
    BITMAP "....X..."
    BITMAP ".XX.X..."
    BITMAP "XXX.X..."
    BITMAP "X......."
    BITMAP ".XX.X..."
    BITMAP "........"
    BITMAP "........"

' Large alien 2x2 (16x16 pixels) - placeholder art
' User can replace with final bitmaps later
' TL and TR form top half, BL and BR form bottom half
LargeAlienTLGfx:
    BITMAP "..XXXX.."
    BITMAP ".XXXXXX."
    BITMAP "XXXXXXXX"
    BITMAP "XX.XX.XX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP ".XXXXXX."
    BITMAP ".XXXXXX."

LargeAlienTRGfx:
    BITMAP "..XXXX.."
    BITMAP ".XXXXXX."
    BITMAP "XXXXXXXX"
    BITMAP "XX.XX.XX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP ".XXXXXX."
    BITMAP ".XXXXXX."

LargeAlienBLGfx:
    BITMAP ".XX..XX."
    BITMAP ".XX..XX."
    BITMAP "..X..X.."
    BITMAP "..XXXX.."
    BITMAP ".XX..XX."
    BITMAP "XX....XX"
    BITMAP "........"
    BITMAP "........"

LargeAlienBRGfx:
    BITMAP ".XX..XX."
    BITMAP ".XX..XX."
    BITMAP "..X..X.."
    BITMAP "..XXXX.."
    BITMAP ".XX..XX."
    BITMAP "XX....XX"
    BITMAP "........"
    BITMAP "........"

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

FontGGfx:
    BITMAP ".XXXXXX."
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX..XXX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP ".XXXXX.."


FontMGfx:
    BITMAP "XX...XX."
    BITMAP "XXX.XXX."
    BITMAP "XXXXXXX."
    BITMAP "XX.X.XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."

FontOGfx:
    BITMAP ".XXXXX.."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP ".XXXXX.."

FontVGfx:
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP ".XX.XX.."
    BITMAP "..XXX..."
    BITMAP "...X...."

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

' --- Parallax Silhouette fill levels (cards 21-24, gameplay only) ---
SilhGfx:
    ' Card 21: GRAM_SILH_1Q — bottom 2 pixels
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"

    ' Card 22: GRAM_SILH_HALF — bottom 4 pixels
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"

    ' Card 23: GRAM_SILH_3Q — bottom 6 pixels
    BITMAP "........"
    BITMAP "........"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"

    ' Card 24: GRAM_SILH_FULL — all 8 pixels
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"

' Silhouette height map (40 columns, mountain range profile)
' Values 0-4 index into SilhCardMap
SilhHeightMap:
    DATA 0, 0, 1, 2, 3, 4, 4, 3, 2, 1
    DATA 0, 0, 0, 1, 2, 3, 4, 3, 2, 0
    DATA 0, 1, 2, 4, 4, 4, 3, 2, 1, 0
    DATA 0, 0, 1, 3, 4, 3, 1, 0, 0, 0

' Pre-computed BACKTAB card values for each height level (purple, color 15)
SilhCardMap:
    DATA 0
    DATA 6319
    DATA 6327
    DATA 6335
    DATA 6343

' --- Flying Saucer (rounded rectangle) ---
SaucerGfx:
    ' Frame 1: windows dark (gaps visible)
    BITMAP ".....XXX"
    BITMAP "...XXXXX"
    BITMAP "..XXXXXX"
    BITMAP ".XX.XX.X"
    BITMAP "XXXXXXXX"
    BITMAP "..XXX..X"
    BITMAP "...X...."
    BITMAP "........"

SaucerF2Gfx:
    ' Frame 2: inner window lit (col 3)
    BITMAP ".....XXX"
    BITMAP "...XXXXX"
    BITMAP "..XXXXXX"
    BITMAP ".XXXXX.X"
    BITMAP "XXXXXXXX"
    BITMAP "..XXX..X"
    BITMAP "...X...."
    BITMAP "........"

SaucerF3Gfx:
    ' Frame 3: outer window lit (col 6)
    BITMAP ".....XXX"
    BITMAP "...XXXXX"
    BITMAP "..XXXXXX"
    BITMAP ".XX.XXXX"
    BITMAP "XXXXXXXX"
    BITMAP "..XXX..X"
    BITMAP "...X...."
    BITMAP "........"

SaucerF4Gfx:
    ' Frame 4: both windows lit + engine glow
    BITMAP ".....XXX"
    BITMAP "...XXXXX"
    BITMAP "..XXXXXX"
    BITMAP ".XXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "..XXXXXX"
    BITMAP "...X...."
    BITMAP "........"

' --- Beam Laser (2px centered column, shared with boss laser) ---
BeamGfx:
    BITMAP "...XX..."
    BITMAP "...XX..."
    BITMAP "...XX..."
    BITMAP "...XX..."
    BITMAP "...XX..."
    BITMAP "...XX..."
    BITMAP "...XX..."
    BITMAP "...XX..."

' --- Power-Up Capsule Frames (Arkanoid-style with scrolling band) ---
CapsuleF1Gfx:
    BITMAP "..XXXX.."
    BITMAP ".XXXXXX."
    BITMAP ".X....X."
    BITMAP ".XXXXXX."
    BITMAP ".XXXXXX."
    BITMAP ".XXXXXX."
    BITMAP ".XXXXXX."
    BITMAP "..XXXX.."

CapsuleF2Gfx:
    BITMAP "..XXXX.."
    BITMAP ".XXXXXX."
    BITMAP ".XXXXXX."
    BITMAP ".X....X."
    BITMAP ".XXXXXX."
    BITMAP ".XXXXXX."
    BITMAP ".XXXXXX."
    BITMAP "..XXXX.."

CapsuleF3Gfx:
    BITMAP "..XXXX.."
    BITMAP ".XXXXXX."
    BITMAP ".XXXXXX."
    BITMAP ".XXXXXX."
    BITMAP ".X....X."
    BITMAP ".XXXXXX."
    BITMAP ".XXXXXX."
    BITMAP "..XXXX.."

CapsuleF4Gfx:
    BITMAP "..XXXX.."
    BITMAP ".XXXXXX."
    BITMAP ".XXXXXX."
    BITMAP ".XXXXXX."
    BITMAP ".XXXXXX."
    BITMAP ".X....X."
    BITMAP ".XXXXXX."
    BITMAP "..XXXX.."

' Alien laser frame 1 (thin line, slight wobble)
ZigzagF1Gfx:
    BITMAP "...X...."
    BITMAP "...X...."
    BITMAP "...X...."
    BITMAP "...X...."
    BITMAP "...X...."
    BITMAP "...X...."
    BITMAP "...X...."
    BITMAP "...X...."

' Mega beam solid block (fills entire card)
MegaBeamGfx:
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"

' Quad laser (4 thin lines spread across 8px)
QuadGfx:
    BITMAP ".X.X.X.X"
    BITMAP ".X.X.X.X"
    BITMAP ".X.X.X.X"
    BITMAP ".X.X.X.X"
    BITMAP ".X.X.X.X"
    BITMAP ".X.X.X.X"
    BITMAP ".X.X.X.X"
    BITMAP ".X.X.X.X"

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

' --- COMPACT CHAIN TEXT (3 tiles, 5px tall) ---
' Tile 1: CH
ChainCHGfx:
    BITMAP "........"
    BITMAP ".###.#.#"
    BITMAP ".#...#.#"
    BITMAP ".#...###"
    BITMAP ".#...#.#"
    BITMAP ".###.#.#"
    BITMAP "........"
    BITMAP "........"

' Tile 2: AI
ChainAIGfx:
    BITMAP "........"
    BITMAP "..#..#.#"
    BITMAP ".#.#.#.#"
    BITMAP ".###.#.#"
    BITMAP ".#.#.#.#"
    BITMAP ".#.#.#.#"
    BITMAP "........"
    BITMAP "........"

' Tile 3: N
ChainNGfx:
    BITMAP "........"
    BITMAP "..#....."
    BITMAP "#.#.#..."
    BITMAP "###....."
    BITMAP ".##.#..."
    BITMAP "..#....."
    BITMAP "........"
    BITMAP "........"

' --- COMPACT SCORE TEXT (3 tiles) ---
' Tile 1: SC
ScoreSCGfx:
    BITMAP "........"
    BITMAP ".##..##."
    BITMAP "#...#..."
    BITMAP ".#..#..."
    BITMAP "..#.#..."
    BITMAP "##...##."
    BITMAP "........"
    BITMAP "........"

' Tile 2: OR
ScoreORGfx:
    BITMAP "........"
    BITMAP ".#..##.."
    BITMAP "#.#.#.#."
    BITMAP "#.#.##.."
    BITMAP "#.#.#.#."
    BITMAP ".#..#.#."
    BITMAP "........"
    BITMAP "........"

' Tile 3: E
ScoreEGfx:
    BITMAP "........"
    BITMAP "###....."
    BITMAP "#....#.."
    BITMAP "##......"
    BITMAP "#....#.."
    BITMAP "###....."
    BITMAP "........"
    BITMAP "........"

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

' (Figure-8 path data moved to Segment 2 — see Flight Patterns section)

' Powerup HUD indicator graphics (8 tiles, 2 per powerup)
' Displayed in yellow (color 6) when powerup is active

' === BEAM powerup (tiles 1-2) ===
PowerupBEGfx:
    BITMAP "........"
    BITMAP "##..###."
    BITMAP "#.#.#..."
    BITMAP "##..##.."
    BITMAP "#.#.#..."
    BITMAP "##..###."
    BITMAP "........"
    BITMAP "........"

PowerupAMGfx:
    BITMAP "........"
    BITMAP ".#..#.#."
    BITMAP "#.#.###."
    BITMAP "###.###."
    BITMAP "#.#.#.#."
    BITMAP "#.#.#.#."
    BITMAP "........"
    BITMAP "........"

' === RAPID powerup (tiles 3-4) ===
PowerupRPGfx:
    BITMAP "........"
    BITMAP "##..##.."
    BITMAP "#.#.#.#."
    BITMAP "##..##.."
    BITMAP "#.#.#..."
    BITMAP "#.#.#..."
    BITMAP "........"
    BITMAP "........"

PowerupIDGfx:
    BITMAP "........"
    BITMAP ".#..##.."
    BITMAP ".#..#.#."
    BITMAP ".#..#.#."
    BITMAP ".#..#.#."
    BITMAP ".#..##.."
    BITMAP "........"
    BITMAP "........"

' === QUAD powerup (tiles 5-6) ===
PowerupQUGfx:
    BITMAP "........"
    BITMAP ".XX..X.X"
    BITMAP "X..X.X.X"
    BITMAP "X..X.X.X"
    BITMAP "X.XX.X.X"
    BITMAP ".XXX..XX"
    BITMAP "........"
    BITMAP "........"

PowerupADGfx:
    BITMAP "........"
    BITMAP "..#..##."
    BITMAP ".#.#.#.#"
    BITMAP ".###.#.#"
    BITMAP ".#.#.#.#"
    BITMAP ".#.#.##."
    BITMAP "........"
    BITMAP "........"

' === MEGA powerup (tiles 7-8) ===
PowerupMEGfx:
    BITMAP "........"
    BITMAP "#.#.###."
    BITMAP "###.#..."
    BITMAP "###.##.."
    BITMAP "#.#.#..."
    BITMAP "#.#.###."
    BITMAP "........"
    BITMAP "........"

PowerupGAGfx:
    BITMAP "........"
    BITMAP ".##..#.."
    BITMAP "#...#.#."
    BITMAP "#.#.###."
    BITMAP "#.#.#.#."
    BITMAP ".##.#.#."
    BITMAP "........"
    BITMAP "........"

' === SHIELD dome graphic (solid bar above ship) ===
ShieldArcGfx:
    BITMAP "..####.."
    BITMAP ".##..##."
    BITMAP ".##..##."
    BITMAP "##....##"
    BITMAP "##....##"
    BITMAP "#......#"
    BITMAP "#......#"
    BITMAP "........"

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

' ============================================================
' 8-BAR LOOP: AMEN BREAK → ACID 303
'
' Source: "Amen, Brother" by The Winstons (1969)
'         + TB-303 acid bass line style (Phuture, Hardfloor)
'
' Bars 1-2: Amen drums + sub-bass (groove foundation)
' Bar 3:    Hook enters — rising E3->G3->A3
' Bar 4:    Hook resolves — G3->E3
' Bars 5-7: Acid section — 303 riff on ch1, four-on-floor drums
' Bar 8:    Strip-back — riff drops, turnaround to amen
'
' Ch1 = hook (bars 3-4) / 303 acid riff (bars 5-7)
' Ch2 = sub-bass (E2 locked with kicks)
' Drums = amen (bars 1-4), four-on-floor + hats (bars 5-8)
' PLAY SIMPLE: Channel 3 free for SFX via SOUND 2
' ============================================================

    SEGMENT 3   ' Gameplay music in Segment 3 (Seg 2 near capacity)

' ------------------------------------------------------------
' Slow - "invaders far away"
' Tempo 11 (~55 BPM) - sparse, deliberate
' ------------------------------------------------------------
si_bg_slow:
  DATA 11

si_bg_slow_loop:

  ' --- Bar 1: drums + bass only ---
  MUSIC -,   E2,  -, M1
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   E2,  -, M1
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -

  ' --- Bar 2: drums + bass, snare enters ---
  MUSIC -,   E2,  -, M1
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   E2,  -, M1
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -

  ' --- Bar 3: hook enters — E3...G3...A3 ---
  MUSIC E3,  E2,  -, M1
  MUSIC S,   -,   -, -
  MUSIC -,   -,   -, M1
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC G3,  G2,  -, M3
  MUSIC S,   -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M2
  MUSIC A3,  A2,  -, M1
  MUSIC S,   -,   -, M1
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2

  ' --- Bar 4: hook resolves — G3...E3, turnaround ---
  MUSIC G3,  G2,  -, M1
  MUSIC S,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC E3,  E2,  -, -
  MUSIC S,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M1

  ' --- Bar 5: acid intro — sparse E3 stabs, four-on-floor ---
  MUSIC E3X, E2,  -, M1
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC E3X, E2,  -, M1
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC G3X, -,   -, M3
  MUSIC -,   -,   -, -

  ' --- Bar 6: acid develops — D4 enters ---
  MUSIC E3X, E2,  -, M1
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC D4X, -,   -, -
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC E3X, -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC G3X, E2,  -, M1
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC E3X, -,   -, M3
  MUSIC -,   -,   -, -

  ' --- Bar 7: acid peak — full 303 sequence ---
  MUSIC E3X, E2,  -, M1
  MUSIC -,   -,   -, -
  MUSIC G3X, -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC D4X, -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC E3X, -,   -, M3
  MUSIC G3X, -,   -, -
  MUSIC E3X, E2,  -, M1
  MUSIC -,   -,   -, -
  MUSIC D4X, -,   -, M3
  MUSIC G3X, -,   -, -
  MUSIC E3X, -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -

  ' --- Bar 8: strip-back — riff drops, turnaround ---
  MUSIC E3,  E2,  -, M1
  MUSIC S,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   E2,  -, M1
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   E2,  -, M1

  MUSIC JUMP si_bg_slow_loop


' ------------------------------------------------------------
' Mid - "breakbeat emerging" — MAIN GAMEPLAY THEME
' Tempo 7 (~107 BPM) - classic amen groove
' ------------------------------------------------------------
si_bg_mid:
  DATA 7

si_bg_mid_loop:

  ' --- Bar 1: amen + bass (no melody) ---
  MUSIC -,   E2,  -, M1
  MUSIC -,   -,   -, -
  MUSIC -,   E2,  -, M1
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M2
  MUSIC -,   G2,  -, M1
  MUSIC -,   -,   -, M1
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2

  ' --- Bar 2: same (groove locks) ---
  MUSIC -,   E2,  -, M1
  MUSIC -,   -,   -, -
  MUSIC -,   E2,  -, M1
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M2
  MUSIC -,   G2,  -, M1
  MUSIC -,   -,   -, M1
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2

  ' --- Bar 3: hook enters — E3...G3...A3 rising ---
  MUSIC E3,  E2,  -, M1
  MUSIC S,   -,   -, -
  MUSIC -,   E2,  -, M1
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC G3,  G2,  -, M3
  MUSIC S,   -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC A3,  A2,  -, M1
  MUSIC S,   -,   -, -
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -

  ' --- Bar 4: hook resolves — G3...E3, turnaround ---
  MUSIC G3,  G2,  -, M1
  MUSIC S,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC E3,  E2,  -, M2
  MUSIC S,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M1
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M2
  MUSIC -,   E2,  -, M1

  ' --- Bar 5: acid intro — 303 enters, four-on-floor kicks ---
  MUSIC E3X, E2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC G3X, -,   -, M3
  MUSIC E3X, E2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC G3X, -,   -, M3
  MUSIC E3X, -,   -, M3

  ' --- Bar 6: acid develops — D4 tension ---
  MUSIC E3X, E2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC D4X, -,   -, M3
  MUSIC -,   -,   -, M3
  MUSIC E3X, -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC G3X, -,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC E4X, E2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC D4X, -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC D4X, -,   -, M3
  MUSIC E3X, -,   -, M3

  ' --- Bar 7: acid peak — full 303 riff, insistent ---
  MUSIC E3X, E2,  -, M1
  MUSIC G3X, -,   -, M3
  MUSIC D4X, -,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC G3X, -,   -, M3
  MUSIC E4X, -,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC E3X, E2,  -, M1
  MUSIC D4X, -,   -, M3
  MUSIC G3X, -,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC E4X, -,   -, M2
  MUSIC E3X, -,   -, M3
  MUSIC D4X, -,   -, M3
  MUSIC E3X, -,   -, M3

  ' --- Bar 8: strip-back — riff drops out, turnaround to amen ---
  MUSIC E3,  E2,  -, M1
  MUSIC S,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   E2,  -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M1
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   E2,  -, M1

  MUSIC JUMP si_bg_mid_loop


' ------------------------------------------------------------
' Fast - "full DnB"
' Tempo 5 (~180 BPM) - amen + hat ride
' ------------------------------------------------------------
si_bg_fast:
  DATA 5

si_bg_fast_loop:

  ' --- Bar 1: amen + bass + hat ride (no melody) ---
  MUSIC -,   E2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC -,   E2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   G2,  -, M1
  MUSIC -,   -,   -, M1
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2

  ' --- Bar 2: same ---
  MUSIC -,   E2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC -,   E2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   G2,  -, M1
  MUSIC -,   -,   -, M1
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2

  ' --- Bar 3: hook — E3X...G3X...A3X staccato ---
  MUSIC E3X, E2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC -,   E2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC G3X, G2,  -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M3
  MUSIC A3X, A2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M3

  ' --- Bar 4: hook resolves — G3X...E3X, breakdown ---
  MUSIC G3X, G2,  -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC E3X, E2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M1
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M1
  MUSIC -,   -,   -, M2

  ' --- Bar 5: acid — 303 rapid fire, four-on-floor ---
  MUSIC E3X, E2,  -, M1
  MUSIC E3X, -,   -, M3
  MUSIC G3X, -,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC E3X, -,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC G3X, -,   -, M3
  MUSIC E3X, E2,  -, M1
  MUSIC E3X, -,   -, M3
  MUSIC D4X, -,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC G3X, -,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC E3X, -,   -, M3

  ' --- Bar 6: acid — D4 and E4 octave jump ---
  MUSIC E3X, E2,  -, M1
  MUSIC D4X, -,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC G3X, -,   -, M3
  MUSIC E4X, -,   -, M2
  MUSIC E3X, -,   -, M3
  MUSIC D4X, -,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC G3X, E2,  -, M1
  MUSIC E3X, -,   -, M3
  MUSIC D4X, -,   -, M3
  MUSIC E4X, -,   -, M3
  MUSIC E3X, -,   -, M2
  MUSIC D4X, -,   -, M3
  MUSIC G3X, -,   -, M3
  MUSIC E3X, -,   -, M3

  ' --- Bar 7: acid peak — relentless 303 ---
  MUSIC E3X, E2,  -, M1
  MUSIC G3X, -,   -, M3
  MUSIC D4X, -,   -, M3
  MUSIC E4X, -,   -, M3
  MUSIC E3X, -,   -, M2
  MUSIC G3X, -,   -, M3
  MUSIC D4X, -,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC E4X, E2,  -, M1
  MUSIC D4X, -,   -, M3
  MUSIC G3X, -,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC D4X, -,   -, M2
  MUSIC E4X, -,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC G3X, -,   -, M3

  ' --- Bar 8: strip-back — riff dies, turnaround ---
  MUSIC E3X, E2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   E2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M1
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   E2,  -, M1

  MUSIC JUMP si_bg_fast_loop


' ------------------------------------------------------------
' Panic - "final descent"
' Tempo 4 (~225 BPM) - relentless
' ------------------------------------------------------------
si_bg_panic:
  DATA 4

si_bg_panic_loop:

  ' --- Bar 1: amen + bass, no melody ---
  MUSIC -,   E2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC -,   E2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   G2,  -, M1
  MUSIC -,   -,   -, M1
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2

  ' --- Bar 2: same ---
  MUSIC -,   E2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC -,   E2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   G2,  -, M1
  MUSIC -,   -,   -, M1
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2

  ' --- Bar 3: urgent hook — E3X...A3X...B3X ---
  MUSIC E3X, E2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC -,   E2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC A3X, A2,  -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M2
  MUSIC B3X, B2,  -, M2
  MUSIC -,   -,   -, M1
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M2

  ' --- Bar 4: hook crashes down — A3X...E3X, chaos ---
  MUSIC A3X, A2,  -, M1
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M1
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M1
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M1
  MUSIC -,   -,   -, M2
  MUSIC E3X, E2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M1
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M1
  MUSIC -,   -,   -, M2

  ' --- Bar 5: acid frenzy — every 16th is a note ---
  MUSIC E3X, E2,  -, M1
  MUSIC E3X, -,   -, M3
  MUSIC G3X, -,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC D4X, -,   -, M2
  MUSIC E3X, -,   -, M3
  MUSIC G3X, -,   -, M3
  MUSIC E4X, -,   -, M3
  MUSIC E3X, E2,  -, M1
  MUSIC D4X, -,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC G3X, -,   -, M3
  MUSIC E4X, -,   -, M2
  MUSIC E3X, -,   -, M3
  MUSIC D4X, -,   -, M3
  MUSIC G3X, -,   -, M3

  ' --- Bar 6: acid chaos — octave jumps, chromatic ---
  MUSIC E4X, E2,  -, M1
  MUSIC E3X, -,   -, M3
  MUSIC D4X, -,   -, M3
  MUSIC E4X, -,   -, M3
  MUSIC G3X, -,   -, M2
  MUSIC D4X, -,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC E4X, -,   -, M3
  MUSIC D4X, E2,  -, M1
  MUSIC E3X, -,   -, M3
  MUSIC G3X, -,   -, M3
  MUSIC E4X, -,   -, M3
  MUSIC E3X, -,   -, M2
  MUSIC D4X, -,   -, M3
  MUSIC E4X, -,   -, M3
  MUSIC E3X, -,   -, M3

  ' --- Bar 7: acid maximum — unrelenting 303 ---
  MUSIC E3X, E2,  -, M1
  MUSIC G3X, -,   -, M3
  MUSIC D4X, -,   -, M1
  MUSIC E4X, -,   -, M3
  MUSIC E3X, -,   -, M2
  MUSIC D4X, -,   -, M3
  MUSIC G3X, -,   -, M1
  MUSIC E4X, -,   -, M3
  MUSIC D4X, E2,  -, M2
  MUSIC E3X, -,   -, M3
  MUSIC E4X, -,   -, M1
  MUSIC G3X, -,   -, M3
  MUSIC D4X, -,   -, M2
  MUSIC E4X, -,   -, M3
  MUSIC E3X, -,   -, M1
  MUSIC G3X, -,   -, M3

  ' --- Bar 8: strip-back — acid dies, turnaround ---
  MUSIC E3X, E2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M1
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   E2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M1
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M1
  MUSIC -,   E2,  -, M2

  MUSIC JUMP si_bg_panic_loop


' ============================================================
' GAME OVER MUSIC — DnB heartbeat tracks (4 gears)
' Heartbeat pulse + walking bass + synth stabs
' Distinct from gameplay music (si_bg_* = amen break + acid 303)
' ============================================================

' ------------------------------------------------------------
' Slow - "contemplative heartbeat"
' Tempo 11 (~55 BPM) - gentle pulse for early game over
' ------------------------------------------------------------
si_dnb_slow:
  DATA 11

si_dnb_slow_loop:

  ' --- Bar 1 (A): E3/C3 heartbeat ---
  MUSIC E3,  E2,  -, M1
  MUSIC S,   S,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC C3,  C2,  -, M1
  MUSIC S,   S,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -

  ' --- Bar 2 (A): same heartbeat, add a hat ---
  MUSIC E3,  E2,  -, M1
  MUSIC S,   S,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC C3,  C2,  -, M1
  MUSIC S,   S,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -

  ' --- Bar 3 (transition): melody emerges E3->G3->A3->G3 ---
  MUSIC E3,  E2,  -, M1
  MUSIC S,   S,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC G3,  G2,  -, M1
  MUSIC S,   S,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC A3,  A2,  -, M1
  MUSIC S,   S,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC G3,  G2,  -, M2
  MUSIC S,   S,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -

  ' --- Bar 4 (B): high stabs G4/D4 — gentle synth hook ---
  MUSIC G4,  G2,  -, M1
  MUSIC S,   S,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC D4,  A2,  -, M1
  MUSIC S,   S,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -

  MUSIC JUMP si_dnb_slow_loop


' ------------------------------------------------------------
' Mid - "breakbeat emerging"
' Tempo 7 (~107 BPM) - half-time DnB feel
' ------------------------------------------------------------
si_dnb_mid:
  DATA 7

si_dnb_mid_loop:

  ' --- Bar 1 (A): heartbeat + bass phrase + breakbeat ---
  MUSIC E3,  E2,  -, M1
  MUSIC S,   S,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   G2,  -, -
  MUSIC -,   S,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   E2,  -, M1
  MUSIC -,   S,   -, M3
  MUSIC C3,  C2,  -, M1
  MUSIC S,   S,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   D2,  -, -
  MUSIC -,   S,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3

  ' --- Bar 2 (A): same groove ---
  MUSIC E3,  E2,  -, M1
  MUSIC S,   S,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   G2,  -, -
  MUSIC -,   S,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   E2,  -, M1
  MUSIC -,   S,   -, M3
  MUSIC C3,  C2,  -, M1
  MUSIC S,   S,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   D2,  -, -
  MUSIC -,   S,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3

  ' --- Bar 3 (transition): melody walks E3->G3->A3->B3, builds to hook ---
  MUSIC E3,  E2,  -, M1
  MUSIC S,   S,   -, -
  MUSIC -,   -,   -, M3
  MUSIC G3,  G2,  -, -
  MUSIC S,   S,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   E2,  -, M1
  MUSIC -,   S,   -, M3
  MUSIC A3,  A2,  -, M1
  MUSIC S,   S,   -, -
  MUSIC -,   -,   -, M3
  MUSIC B3,  B2,  -, -
  MUSIC S,   S,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3

  ' --- Bar 4 (B): high stabs G4/E4 over walking bass — synth hook ---
  MUSIC G4X, G2,  -, M1
  MUSIC -,   S,   -, -
  MUSIC E4X, -,   -, M3
  MUSIC -,   A2,  -, -
  MUSIC -,   S,   -, M2
  MUSIC G4X, -,   -, M3
  MUSIC -,   G2,  -, -
  MUSIC -,   S,   -, M3
  MUSIC D4X, B2,  -, M1
  MUSIC -,   S,   -, -
  MUSIC E4X, -,   -, M3
  MUSIC -,   A2,  -, -
  MUSIC -,   S,   -, M2
  MUSIC G4X, -,   -, M3
  MUSIC -,   E2,  -, M1
  MUSIC -,   -,   -, M3

  MUSIC JUMP si_dnb_mid_loop


' ------------------------------------------------------------
' Fast - "full DnB"
' Tempo 5 (~180 BPM) - classic DnB territory
' ------------------------------------------------------------
si_dnb_fast:
  DATA 5

si_dnb_fast_loop:

  ' --- Bar 1 (A): full amen groove ---
  MUSIC E3X, E2,  -, M1
  MUSIC -,   S,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   G2,  -, M3
  MUSIC -,   S,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   E2,  -, -
  MUSIC -,   -,   -, M3
  MUSIC C3X, C2,  -, -
  MUSIC -,   S,   -, M3
  MUSIC -,   -,   -, M1
  MUSIC -,   D2,  -, M3
  MUSIC -,   S,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   E2,  -, -
  MUSIC -,   -,   -, M2

  ' --- Bar 2 (A): same groove ---
  MUSIC E3X, E2,  -, M1
  MUSIC -,   S,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   G2,  -, M3
  MUSIC -,   S,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   E2,  -, -
  MUSIC -,   -,   -, M3
  MUSIC C3X, C2,  -, -
  MUSIC -,   S,   -, M3
  MUSIC -,   -,   -, M1
  MUSIC -,   D2,  -, M3
  MUSIC -,   S,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   E2,  -, -
  MUSIC -,   -,   -, M2

  ' --- Bar 3 (transition): rising riff E3->G3->A3->B3, drum fill out ---
  MUSIC E3X, E2,  -, M1
  MUSIC -,   S,   -, M3
  MUSIC G3X, -,   -, -
  MUSIC -,   G2,  -, M3
  MUSIC -,   S,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC A3X, E2,  -, -
  MUSIC -,   S,   -, M3
  MUSIC -,   C2,  -, -
  MUSIC B3X, S,   -, M3
  MUSIC -,   -,   -, M1
  MUSIC A3X, D2,  -, M3
  MUSIC -,   S,   -, M2
  MUSIC B3X, -,   -, M2
  MUSIC -,   E2,  -, M1
  MUSIC -,   -,   -, M2

  ' --- Bar 4 (B): piercing stabs G4/E5 — synth riff over breakdown ---
  MUSIC G4X, G2,  -, -
  MUSIC -,   S,   -, -
  MUSIC E5X, A2,  -, M3
  MUSIC -,   S,   -, -
  MUSIC D4X, B2,  -, -
  MUSIC -,   S,   -, -
  MUSIC E5X, A2,  -, M3
  MUSIC -,   S,   -, -
  MUSIC G4X, G2,  -, M1
  MUSIC -,   S,   -, M3
  MUSIC E5X, -,   -, M2
  MUSIC -,   A2,  -, M3
  MUSIC D4X, S,   -, M1
  MUSIC -,   -,   -, M3
  MUSIC G4X, E2,  -, M2
  MUSIC -,   -,   -, M2

  MUSIC JUMP si_dnb_fast_loop


' ------------------------------------------------------------
' Panic - "final descent"
' Tempo 4 (~225 BPM) - frantic, relentless
' ------------------------------------------------------------
si_dnb_panic:
  DATA 4

si_dnb_panic_loop:

  ' --- Bar 1 (A): driving amen ---
  MUSIC E3X, E2,  -, M1
  MUSIC -,   S,   -, M3
  MUSIC -,   G2,  -, M3
  MUSIC -,   -,   -, M3
  MUSIC -,   E2,  -, M2
  MUSIC -,   S,   -, M3
  MUSIC -,   G2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC C3X, C2,  -, M1
  MUSIC -,   S,   -, M3
  MUSIC -,   D2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC -,   E2,  -, M2
  MUSIC -,   S,   -, M3
  MUSIC -,   G2,  -, M1
  MUSIC -,   -,   -, M2

  ' --- Bar 2 (A): same ---
  MUSIC E3X, E2,  -, M1
  MUSIC -,   S,   -, M3
  MUSIC -,   G2,  -, M3
  MUSIC -,   -,   -, M3
  MUSIC -,   E2,  -, M2
  MUSIC -,   S,   -, M3
  MUSIC -,   G2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC C3X, C2,  -, M1
  MUSIC -,   S,   -, M3
  MUSIC -,   D2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC -,   E2,  -, M2
  MUSIC -,   S,   -, M3
  MUSIC -,   G2,  -, M1
  MUSIC -,   -,   -, M2

  ' --- Bar 3 (transition): frantic rising E3->G3->A3->B3, snare roll ---
  MUSIC E3X, E2,  -, M1
  MUSIC -,   S,   -, M3
  MUSIC G3X, G2,  -, M3
  MUSIC -,   -,   -, M3
  MUSIC A3X, E2,  -, M2
  MUSIC -,   S,   -, M3
  MUSIC B3X, G2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC A3X, C2,  -, M1
  MUSIC B3X, S,   -, M3
  MUSIC A3X, D2,  -, M1
  MUSIC B3X, -,   -, M3
  MUSIC -,   E2,  -, M2
  MUSIC -,   -,   -, M2
  MUSIC -,   G2,  -, M2
  MUSIC -,   -,   -, M2

  ' --- Bar 4 (B): frantic arpeggios G4/E5/G5 — synth panic ---
  MUSIC G4X, G2,  -, M1
  MUSIC E5X, S,   -, M3
  MUSIC G5X, A2,  -, M3
  MUSIC E5X, -,   -, M3
  MUSIC D4X, B2,  -, M2
  MUSIC E5X, S,   -, M3
  MUSIC G5X, C3,  -, M1
  MUSIC E5X, S,   -, M3
  MUSIC G4X, B2,  -, M1
  MUSIC E5X, S,   -, M3
  MUSIC G5X, A2,  -, M1
  MUSIC E5X, -,   -, M3
  MUSIC D4X, G2,  -, M2
  MUSIC G4X, S,   -, M3
  MUSIC E5X, E2,  -, M1
  MUSIC G5X, -,   -, M2

  MUSIC JUMP si_dnb_panic_loop

' ============================================
' Y-AXIS ANIMATED TITLE FONT
' 4 rotation frames per letter (0°, 30°, 60°, 90°)
' Used during title screen cascade reveal/vanish
' ============================================

' Letter S - Frame 1 (0° full view)
FontSY1Gfx:
    BITMAP ".XXXXX.."
    BITMAP "XX...XX."
    BITMAP "XX......"
    BITMAP ".XXXXX.."
    BITMAP ".....XX."
    BITMAP ".....XX."
    BITMAP "XX...XX."
    BITMAP ".XXXXX.."

' Letter S - Frame 2 (30°)
FontSY2Gfx:
    BITMAP ".XXXXX.."
    BITMAP "XX...XX."
    BITMAP "XX......"
    BITMAP ".XXXXX.."
    BITMAP ".....XX."
    BITMAP ".....XX."
    BITMAP "XX...XX."
    BITMAP ".XXXXX.."

' Letter S - Frame 3 (60°)
FontSY3Gfx:
    BITMAP ".XXXXX.."
    BITMAP "XX...X.."
    BITMAP "XX......"
    BITMAP ".XXXXX.."
    BITMAP ".....X.."
    BITMAP ".....X.."
    BITMAP "XX...X.."
    BITMAP ".XXXXX.."

' Letter S - Frame 4 (90° edge view)
FontSY4Gfx:
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XXX..."

' Letter P - Frame 1 (0°)
FontPY1Gfx:
    BITMAP "XXXXXX.."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XXXXXX.."
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX......"

' Letter P - Frame 2 (30°)
FontPY2Gfx:
    BITMAP "XXXXXX.."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XXXXXX.."
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX......"

' Letter P - Frame 3 (60°)
FontPY3Gfx:
    BITMAP "XXXXXX.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XXXXXX.."
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX......"

' Letter P - Frame 4 (90°)
FontPY4Gfx:
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."

' Letter A - Frame 1 (0°)
FontAY1Gfx:
    BITMAP ".XXXXX.."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX..XXX."
    BITMAP "XXXXXXX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."

' Letter A - Frame 2 (30°)
FontAY2Gfx:
    BITMAP ".XXXXX.."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX..XXX."
    BITMAP "XXXXXXX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."

' Letter A - Frame 3 (60°)
FontAY3Gfx:
    BITMAP ".XXXXX.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX..XX.."
    BITMAP "XXXXXX.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."

' Letter A - Frame 4 (90°)
FontAY4Gfx:
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XXX..."
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."

' Letter C - Frame 1 (0°)
FontCY1Gfx:
    BITMAP ".XXXXX.."
    BITMAP "XX...XX."
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX...XX."
    BITMAP ".XXXXX.."

' Letter C - Frame 2 (30°)
FontCY2Gfx:
    BITMAP ".XXXXX.."
    BITMAP "XX...XX."
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX...XX."
    BITMAP ".XXXXX.."

' Letter C - Frame 3 (60°)
FontCY3Gfx:
    BITMAP ".XXXXX.."
    BITMAP "XX...X.."
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX...X.."
    BITMAP ".XXXXX.."

' Letter C - Frame 4 (90°)
FontCY4Gfx:
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XXX..."

' Letter E - Frame 1 (0°)
FontEY1Gfx:
    BITMAP "XXXXXXX."
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XXXXXXX."
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XXXXXXX."

' Letter E - Frame 2 (30°)
FontEY2Gfx:
    BITMAP "XXXXXXX."
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XXXXXXX."
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XXXXXXX."

' Letter E - Frame 3 (60°)
FontEY3Gfx:
    BITMAP "XXXXXX.."
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XXXXXX.."
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XXXXXX.."

' Letter E - Frame 4 (90°)
FontEY4Gfx:
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XXX..."

' Letter I - Frame 1 (0°)
FontIY1Gfx:
    BITMAP "XXXXXXX."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "XXXXXXX."

' Letter I - Frame 2 (30°)
FontIY2Gfx:
    BITMAP "XXXXXXX."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "XXXXXXX."

' Letter I - Frame 3 (60°)
FontIY3Gfx:
    BITMAP "XXXXXX.."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "XXXXXX.."

' Letter I - Frame 4 (90°)
FontIY4Gfx:
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XXX..."

' Letter N - Frame 1 (0°)
FontNY1Gfx:
    BITMAP "XX...XX."
    BITMAP "XXX..XX."
    BITMAP "XXXX.XX."
    BITMAP "XX.XXXX."
    BITMAP "XX..XXX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."

' Letter N - Frame 2 (30°)
FontNY2Gfx:
    BITMAP "XX...XX."
    BITMAP "XXX..XX."
    BITMAP "XXXX.XX."
    BITMAP "XX.XXXX."
    BITMAP "XX..XXX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."

' Letter N - Frame 3 (60°)
FontNY3Gfx:
    BITMAP "XX...X.."
    BITMAP "XXX..X.."
    BITMAP "XXXX.X.."
    BITMAP "XX.XXX.."
    BITMAP "XX..XX.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."

' Letter N - Frame 4 (90°)
FontNY4Gfx:
    BITMAP "..XX...."
    BITMAP "..XXX..."
    BITMAP "..XXX..."
    BITMAP "..XXX..."
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."

' Letter T - Frame 1 (0°)
FontTY1Gfx:
    BITMAP "XXXXXXX."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."

' Letter T - Frame 2 (30°)
FontTY2Gfx:
    BITMAP "XXXXXXX."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."

' Letter T - Frame 3 (60°)
FontTY3Gfx:
    BITMAP "XXXXXX.."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."

' Letter T - Frame 4 (90°)
FontTY4Gfx:
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."

' Letter R - Frame 1 (0°)
FontRY1Gfx:
    BITMAP "XXXXXX.."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XXXXXX.."
    BITMAP "XX..XX.."
    BITMAP "XX...XX."
    BITMAP "XX...XX."

' Letter R - Frame 2 (30°)
FontRY2Gfx:
    BITMAP "XXXXXX.."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XXXXXX.."
    BITMAP "XX..XX.."
    BITMAP "XX...XX."
    BITMAP "XX...XX."

' Letter R - Frame 3 (60°)
FontRY3Gfx:
    BITMAP "XXXXXX.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XXXXXX.."
    BITMAP "XX..XX.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."

' Letter R - Frame 4 (90°)
FontRY4Gfx:
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."

' Letter U - Frame 1 (0°)
FontUY1Gfx:
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP ".XXXXX.."

' Letter U - Frame 2 (30°)
FontUY2Gfx:
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP ".XXXXX.."

' Letter U - Frame 3 (60°)
FontUY3Gfx:
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP ".XXXXX.."

' Letter U - Frame 4 (90°)
FontUY4Gfx:
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XXX..."

' Letter D - Frame 1 (0°)
FontDY1Gfx:
    BITMAP "XXXXXX.."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XXXXXX.."

' Letter D - Frame 2 (30°)
FontDY2Gfx:
    BITMAP "XXXXXX.."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XXXXXX.."

' Letter D - Frame 3 (60°)
FontDY3Gfx:
    BITMAP "XXXXXX.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XXXXXX.."

' Letter D - Frame 4 (90°)
FontDY4Gfx:
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XXX..."

' ============================================
' GAME OVER LETTERS: G, M, O, V
' Y-Axis rotation frames
' ============================================

' Letter G - Frame 1 (0°)
FontGY1Gfx:
    BITMAP ".XXXXXX."
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX..XXX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP ".XXXXX.."

' Letter G - Frame 3 (60°)
FontGY3Gfx:
    BITMAP ".XXXXX.."
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX..XX.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP ".XXXXX.."

' Letter G - Frame 4 (90°)
FontGY4Gfx:
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XXX..."

' Letter M - Frame 1 (0°)
FontMY1Gfx:
    BITMAP "XX...XX."
    BITMAP "XXX.XXX."
    BITMAP "XXXXXXX."
    BITMAP "XX.X.XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."

' Letter M - Frame 3 (60°)
FontMY3Gfx:
    BITMAP "XX...X.."
    BITMAP "XXX.XX.."
    BITMAP "XXXXXX.."
    BITMAP "XX.X.X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."

' Letter M - Frame 4 (90°)
FontMY4Gfx:
    BITMAP "..XX...."
    BITMAP "..XXX..."
    BITMAP "..XXX..."
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."

' Letter O - Frame 1 (0°)
FontOY1Gfx:
    BITMAP ".XXXXX.."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP ".XXXXX.."

' Letter O - Frame 3 (60°)
FontOY3Gfx:
    BITMAP ".XXXXX.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP ".XXXXX.."

' Letter O - Frame 4 (90°)
FontOY4Gfx:
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XXX..."

' Letter V - Frame 1 (0°)
FontVY1Gfx:
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP ".XX.XX.."
    BITMAP "..XXX..."
    BITMAP "...X...."

' Letter V - Frame 3 (60°)
FontVY3Gfx:
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP ".XX.XX.."
    BITMAP "..XXX..."
    BITMAP "...X...."

' Letter V - Frame 4 (90°)
FontVY4Gfx:
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..X....."