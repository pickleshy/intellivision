' ============================================
' SPACE INTRUDERS - Constants Module
' ============================================
' Game configuration and constant definitions
' No segment placement needed (constants are resolved at compile time)

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
CONST GRAM_ALIEN4   = 19        ' Row 3 alien (reuses title-only crab card slots)
CONST GRAM_ALIEN5   = 30        ' Row 4 alien (reuses title-only font card slots)
' Substep march shift cards (dynamically DEFINE'd during gameplay)
' Shift-1: Non-contiguous free cards (no conflicts!)
CONST GRAM_SHIFT1_R0 = 31       ' Shift-1 row 0 (title font N, free during gameplay)
CONST GRAM_SHIFT1_R1 = 32       ' Shift-1 row 1 (title font T, free during gameplay)
CONST GRAM_SHIFT1_R2 = 37       ' Shift-1 row 2 (star 1, title only)
CONST GRAM_SHIFT1_R3 = 38       ' Shift-1 row 3 (star 2, title only)
CONST GRAM_ORBITER   = 47       ' Orbiter sprite card (SmallCrabF1Gfx, defined at StartGame)
' Shift-2: Limited to rows 0-2 only (rows 3-4 use shift-1 or snap)
CONST GRAM_SHIFT2_BASE = 42     ' Shift-2 rows 0-2 in cards 42-44 (saucer freed!)
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
CONST GRAM_PWR1 = 25            ' Powerup tile 1 (dynamic, DEFINE'd per type)
CONST GRAM_PWR2 = 26            ' Powerup tile 2 (dynamic, DEFINE'd per type)
CONST GRAM_PWR3 = 27            ' Powerup tile 3 (dynamic, RAPID="D_" or SOL36="36")
CONST GRAM_CHAIN_DIG = 28       ' Chain digit display (dynamic, round-robin)
CONST GRAM_LIVES_DIG = 29       ' Lives digit display (dynamic, round-robin)
' Shield and remaining HUD slots (title font cards 33-36)
CONST GRAM_SHIELD = 33          ' Shield arc above player ship
CONST GRAM_WARP1  = 34          ' Warp-in frame 1: single pixel (arriving)
CONST GRAM_WARP2  = 35          ' Warp-in frame 2: forming cluster
CONST GRAM_WARP3  = 36          ' Warp-in frame 3: coalescing shape
CONST GRAM_STAR1  = 37        ' Star dot (upper-left pixel)
CONST GRAM_STAR2  = 38        ' Star dot (lower-right pixel)
CONST GRAM_SAUCER = 39         ' Flying saucer (single frame, animation via color shift)
CONST GRAM_BEAM   = 40         ' Wide beam shot (full 8px width)
CONST GRAM_POWERUP = 41        ' Power-up capsule graphic
' Cards 42-44: Freed for alien substep shift-2 (saucer uses color animation only)
CONST GRAM_SHIP_HUD = 45       ' Compact ship icon for HUD lives display
CONST GRAM_MEGA_BEAM = 46      ' Solid block for mega beam column
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
CONST GRAM_SCORE_M  = 32        ' Score digits D6,D5 (millions + hundred-thousands)
CONST GRAM_SCORE_SC = 61        ' Score digits D4,D3 (title: "SC" label, gameplay: ten-thousands + thousands)
CONST GRAM_SCORE_OR = 62        ' Score digits D2,D1 (title: "OR" label, gameplay: hundreds + tens)
CONST GRAM_SCORE_E  = 63        ' Score digit D0 (title: "E" label, gameplay: ones + blank)

' UpdateScoreDisplay round-robin card assignments (extended for 7-digit display)
CONST SCORE_CARD_M  = 32        ' Millions + hundred-thousands (D6D5)
CONST SCORE_CARD0 = 61          ' Ten-thousands + thousands (D4D3)
CONST SCORE_CARD1 = 62          ' Hundreds + tens (D2D1)
CONST SCORE_CARD2 = 63          ' Ones + blank (D0)

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
CONST MARCH_SPEED_MIN = 16      ' Fastest march speed (minimum frames) — 3.75/sec peak

' Bullet constants
CONST BULLET_SPEED  = 2         ' Player bullet speed (pixels per frame)
CONST BULLET_TOP    = 8         ' Top of screen
CONST ALIEN_BULLET_SPEED = 2    ' Alien bullet speed (pixels per frame) - doubled for challenge
CONST ALIEN_SHOOT_RATE = 40     ' Frames between alien shots (~1.5/sec)
CONST FLY_STEP_RATE = 2         ' Waypoints to advance per frame (flight engine)
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
CONST ROGUE_CAPTURED   = 3  ' Zip animation: rogue flies from capture point to ship
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
' Bits 10-11: FREE (was FLAG_TOPDOWN/FLAG_FLYDOWN, replaced by WaveEntrance variable)
CONST FLAG_KEY0HELD  = 4096     ' Bit 12: Capture button debounce (lower-right action)
CONST FLAG_BOMB      = 8192     ' Bit 13: Bomb weapon active
CONST FLAG_SUBWAVE   = 16384    ' Bit 14: SubWave (1=Pattern B formation)
CONST FLAG_REINFORCE = 32768    ' Bit 15: Reinforcement already triggered this wave
