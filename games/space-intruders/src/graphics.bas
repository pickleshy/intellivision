' ============================================
' SPACE INTRUDERS - Graphics Module
' ============================================
' BITMAP definitions for all game graphics
' Segment: 3 (pure data - moved from Seg 2 to free critical space)

    SEGMENT 3

' === Graphics Data === 

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

' Alien Type 4 - Row 3 (beetle/shield bug) - 1px gap right & bottom
Alien4Gfx:
    ' Frame 0 - antennae up, legs in
    BITMAP "X....X.."
    BITMAP ".XXXX..."
    BITMAP "XXXXXX.."
    BITMAP "XX..XX.."
    BITMAP "XXXXXX.."
    BITMAP ".X..X..."
    BITMAP "..XX...."
    BITMAP "........"
    ' Frame 1 - antennae angled, legs out
    BITMAP ".X..X..."
    BITMAP ".XXXX..."
    BITMAP "XXXXXX.."
    BITMAP "XX..XX.."
    BITMAP "XXXXXX.."
    BITMAP "X....X.."
    BITMAP "..XX...."
    BITMAP "........"

' Alien Type 5 - Row 4 (jellyfish/bell) - 1px gap right & bottom
Alien5Gfx:
    ' Frame 0 - tentacles narrow
    BITMAP "..XX...."
    BITMAP ".XXXX..."
    BITMAP "XXXXXX.."
    BITMAP "XXXXXX.."
    BITMAP ".X..X..."
    BITMAP ".X..X..."
    BITMAP "X....X.."
    BITMAP "........"
    ' Frame 1 - tentacles spread
    BITMAP "..XX...."
    BITMAP ".XXXX..."
    BITMAP "XXXXXX.."
    BITMAP "XXXXXX.."
    BITMAP "X.XX.X.."
    BITMAP ".X..X..."
    BITMAP ".X..X..."
    BITMAP "........"

' --------------------------------------------
' Alien Frame 2 Bitmaps (DEFINE-swap 3rd animation frame)
' Loaded into GRAM card BASE for each alien type when AnimFrame=2,
' restored to F0 data when AnimFrame returns to 0.
' Source: alien_test.bas cards 20-24.
' --------------------------------------------
Alien1F2Gfx:
    ' Squid Frame 2 - arms mid-spread (between F0 and F1)
    BITMAP "..XX...."
    BITMAP ".XXXX..."
    BITMAP "X.XX.X.."
    BITMAP "XXXXXX.."
    BITMAP ".X..X..."
    BITMAP "X....X.."
    BITMAP ".X..X..."
    BITMAP "........"

Alien2F2Gfx:
    ' Crab Frame 2 - claws mid-position
    BITMAP "X....X.."
    BITMAP ".XXXX..."
    BITMAP "XXXXXX.."
    BITMAP "XXXXXX.."
    BITMAP ".XXXX..."
    BITMAP ".X..X..."
    BITMAP ".X..X..."
    BITMAP "........"

Alien3F2Gfx:
    ' Octopus Frame 2 - legs mid-spread
    BITMAP "..XX...."
    BITMAP ".XXXX..."
    BITMAP "XX..XX.."
    BITMAP "XXXXXX.."
    BITMAP ".XXXX..."
    BITMAP "X....X.."
    BITMAP "X....X.."
    BITMAP "........"

Alien4F2Gfx:
    ' Beetle Frame 2 - antennae wide, legs shifted
    BITMAP ".X..X..."
    BITMAP "XXXXXX.."
    BITMAP "XXXXXX.."
    BITMAP "XX..XX.."
    BITMAP "XXXXXX.."
    BITMAP "X....X.."
    BITMAP ".X..X..."
    BITMAP "........"

Alien5F2Gfx:
    ' Jellyfish Frame 2 - tentacles curled up / body puffed
    BITMAP "..XX...."
    BITMAP ".XXXX..."
    BITMAP "XXXXXX.."
    BITMAP "XXXXXX.."
    BITMAP "XXXXXX.."
    BITMAP ".X..X..."
    BITMAP "X....X.."
    BITMAP "........"

' --------------------------------------------
' Shifted Alien Graphics (Substep March)
' --------------------------------------------
' Cards 34-38: Shift-1 all 5 rows (time-shared with warp-in + stars)
' Cards 25-27: Shift-2 rows 0-2 (time-shared with powerup HUD, guarded)
' Cards 43, 47: Shift-2 rows 3-4 (reclaimed from saucer F3 + free slot)
' --------------------------------------------
' Frame 0, Shift-1 (+1px): Individual rows for non-contiguous loading
Shift1F0Row0:    ' Squid F0 shifted right 1px (card 31)
    BITMAP "...XX..."
    BITMAP "..XXXX.."
    BITMAP ".XXXXXX."
    BITMAP "..X..X.."
    BITMAP "..XXXX.."
    BITMAP "..X..X.."
    BITMAP "...XX..."
    BITMAP "........"

Shift1F0Row1:    ' Crab F0 shifted right 1px (card 32)
    BITMAP "..X..X.."
    BITMAP ".XXXXXX."
    BITMAP ".XX..XX."
    BITMAP ".XXXXXX."
    BITMAP "..XXXX.."
    BITMAP "..XXXX.."
    BITMAP "..X..X.."
    BITMAP "........"

Shift1F0Row2:    ' Octopus F0 shifted right 1px (card 37)
    BITMAP "...XX..."
    BITMAP "..XXXX.."
    BITMAP ".XX..XX."
    BITMAP ".XXXXXX."
    BITMAP ".X.XX.X."
    BITMAP "..X..X.."
    BITMAP "...XX..."
    BITMAP "........"

Shift1F0Row3:    ' Beetle F0 shifted right 1px (card 38)
    BITMAP ".X....X."
    BITMAP "..XXXX.."
    BITMAP ".XXXXXX."
    BITMAP ".XX..XX."
    BITMAP ".XXXXXX."
    BITMAP "..X..X.."
    BITMAP "...XX..."
    BITMAP "........"

Shift1F0Row4:    ' Jellyfish F0 shifted right 1px (card 47)
    BITMAP "...XX..."
    BITMAP "..XXXX.."
    BITMAP ".XXXXXX."
    BITMAP ".XXXXXX."
    BITMAP "..X..X.."
    BITMAP "..X..X.."
    BITMAP ".X....X."
    BITMAP "........"

' Frame 1, Shift-1 (+1px): Individual rows for non-contiguous loading
Shift1F1Row0:    ' Squid F1 shifted right 1px (card 31)
    BITMAP "...XX..."
    BITMAP "..XXXX.."
    BITMAP ".XX..XX."
    BITMAP "..XXXX.."
    BITMAP ".X.XX.X."
    BITMAP ".X....X."
    BITMAP "..X..X.."
    BITMAP "........"

Shift1F1Row1:    ' Crab F1 shifted right 1px (card 32)
    BITMAP ".X....X."
    BITMAP ".X.XX.X."
    BITMAP ".XXXXXX."
    BITMAP ".XX..XX."
    BITMAP ".XXXXXX."
    BITMAP "..XXXX.."
    BITMAP ".X....X."
    BITMAP "........"

Shift1F1Row2:    ' Octopus F1 shifted right 1px (card 37)
    BITMAP "...XX..."
    BITMAP "..XXXX.."
    BITMAP ".XX..XX."
    BITMAP ".XXXXXX."
    BITMAP ".X.XX.X."
    BITMAP ".X....X."
    BITMAP ".X....X."
    BITMAP "........"

Shift1F1Row3:    ' Beetle F1 shifted right 1px (card 38)
    BITMAP "..X..X.."
    BITMAP "..XXXX.."
    BITMAP ".XXXXXX."
    BITMAP ".XX..XX."
    BITMAP ".XXXXXX."
    BITMAP ".X....X."
    BITMAP "...XX..."
    BITMAP "........"

Shift1F1Row4:    ' Jellyfish F1 shifted right 1px (card 47)
    BITMAP "...XX..."
    BITMAP "..XXXX.."
    BITMAP ".XXXXXX."
    BITMAP ".XXXXXX."
    BITMAP ".X.XX.X."
    BITMAP "..X..X.."
    BITMAP "..X..X.."
    BITMAP "........"

' Frame 0, Shift-2 (+2px): Rows 0-2 (cards 25-27)
Shift2F0Rows0_2:
    ' Squid F0 shifted right 2px
    BITMAP "....XX.."
    BITMAP "...XXXX."
    BITMAP "..XXXXXX"
    BITMAP "...X..X."
    BITMAP "...XXXX."
    BITMAP "...X..X."
    BITMAP "....XX.."
    BITMAP "........"

    ' Crab F0 shifted right 2px
    BITMAP "...X..X."
    BITMAP "..XXXXXX"
    BITMAP "..XX..XX"
    BITMAP "..XXXXXX"
    BITMAP "...XXXX."
    BITMAP "...XXXX."
    BITMAP "...X..X."
    BITMAP "........"

    ' Octopus F0 shifted right 2px
    BITMAP "....XX.."
    BITMAP "...XXXX."
    BITMAP "..XX..XX"
    BITMAP "..XXXXXX"
    BITMAP "..X.XX.X"
    BITMAP "...X..X."
    BITMAP "....XX.."
    BITMAP "........"

' Frame 1, Shift-2 (+2px): Rows 0-2 (cards 25-27)
Shift2F1Rows0_2:
    ' Squid F1 shifted right 2px
    BITMAP "....XX.."
    BITMAP "...XXXX."
    BITMAP "..XX..XX"
    BITMAP "...XXXX."
    BITMAP "..X.XX.X"
    BITMAP "..X....X"
    BITMAP "...X..X."
    BITMAP "........"

    ' Crab F1 shifted right 2px
    BITMAP "..X....X"
    BITMAP "..X.XX.X"
    BITMAP "..XXXXXX"
    BITMAP "..XX..XX"
    BITMAP "..XXXXXX"
    BITMAP "...XXXX."
    BITMAP "..X....X"
    BITMAP "........"

    ' Octopus F1 shifted right 2px
    BITMAP "....XX.."
    BITMAP "...XXXX."
    BITMAP "..XX..XX"
    BITMAP "..XXXXXX"
    BITMAP "..X.XX.X"
    BITMAP "..X....X"
    BITMAP "..X....X"
    BITMAP "........"

' Frame 0, Shift-2 (+2px): Row 3 (card 43)
Shift2F0Row3:
    ' Beetle F0 shifted right 2px
    BITMAP "..X....X"
    BITMAP "...XXXX."
    BITMAP "..XXXXXX"
    BITMAP "..XX..XX"
    BITMAP "..XXXXXX"
    BITMAP "...X..X."
    BITMAP "....XX.."
    BITMAP "........"

' Frame 0, Shift-2 (+2px): Row 4 (card 47)
Shift2F0Row4:
    ' Jellyfish F0 shifted right 2px
    BITMAP "....XX.."
    BITMAP "...XXXX."
    BITMAP "..XXXXXX"
    BITMAP "..XXXXXX"
    BITMAP "...X..X."
    BITMAP "...X..X."
    BITMAP "..X....X"
    BITMAP "........"

' Frame 1, Shift-2 (+2px): Row 3 (card 43)
Shift2F1Row3:
    ' Beetle F1 shifted right 2px
    BITMAP "...X..X."
    BITMAP "...XXXX."
    BITMAP "..XXXXXX"
    BITMAP "..XX..XX"
    BITMAP "..XXXXXX"
    BITMAP "..X....X"
    BITMAP "....XX.."
    BITMAP "........"

' Frame 1, Shift-2 (+2px): Row 4 (card 47)
Shift2F1Row4:
    ' Jellyfish F1 shifted right 2px
    BITMAP "....XX.."
    BITMAP "...XXXX."
    BITMAP "..XXXXXX"
    BITMAP "..XXXXXX"
    BITMAP "..X.XX.X"
    BITMAP "...X..X."
    BITMAP "...X..X."
    BITMAP "........"

' SOL-36 death skeleton (GRAM card 16 / GRAM_SKELETON, time-shared with GRAM_EXPLOSION3)
' Shown flashing at killed alien BACKTAB position during beam sequence.
' GRAM_EXPLOSION3 is never visible during beam (beam clear wipes it each frame), so safe.
IntruderSkeletonGfx:
    BITMAP "........"
    BITMAP "...XXX.."
    BITMAP "...X.X.."
    BITMAP ".X..X..X"
    BITMAP "..XXXXX."
    BITMAP "....X..."
    BITMAP "...XXX.."
    BITMAP "..X...X."

IntruderSkeletonGfx2:
    BITMAP "........"
    BITMAP "...XXX.."
    BITMAP "...X.X.."
    BITMAP "....X..."
    BITMAP ".XXXXXXX"
    BITMAP "....X..."
    BITMAP "..XXXXX."
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

' --- SKULL EYE GLOW MASKS (title screen BEHIND sprites) ---
' Used with BEHIND sprites to project red glow through eye socket blanks.
' Only row 3 has pixels — all other rows zero to prevent leakage through
' jaw gaps and top-corner padding blanks.
' Band1 eye sockets: row 3 blank at positions 5,6 ("..XXX..X" → ".....XX." glow)
' Band2 eye sockets: row 3 blank at positions 1,2 ("X..XXX.." → ".XX....." glow)
BandGlow1Gfx:
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP ".....XX."   ' row 3: left eye socket (positions 5,6)
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"

BandGlow2Gfx:
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP ".XX....."   ' row 3: right eye socket (positions 1,2)
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"

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

' --- TinyFont boot splash: PAISLEYBOXERS.ITCH.IO / BETA - 02/12/2026 ---
' 20 pairs in 5 DEFINE batches of 4 cards each (cards 0-19, temporary)
SplashBatch0:  ' Cards 0-3
    DATA $C400, $AAAA, $8ACE, $008A  ' "PA"
    DATA $E600, $4448, $4A42, $00E4  ' "IS"
    DATA $8E00, $8C88, $8888, $00EE  ' "LE"
    DATA $AC00, $ACAA, $4A4A, $004C  ' "YB"
SplashBatch1:  ' Cards 4-7
    DATA $4A00, $A4AA, $AAAA, $004A  ' "OX"
    DATA $EC00, $CA8A, $8A8C, $00EA  ' "ER"
    DATA $6000, $4080, $A020, $0044  ' "S."
    DATA $EE00, $4444, $4444, $00E4  ' "IT"
SplashBatch2:  ' Cards 8-11
    DATA $4A00, $8EAA, $AA8A, $004A  ' "CH"
    DATA $0E00, $0404, $0404, $004E  ' ".I"
    DATA $4000, $A0A0, $A0A0, $0040  ' "O "
    DATA $CE00, $CCA8, $A8A8, $00CE  ' "BE"

' --- Splash Date Line (auto-generated at build time) ---
INCLUDE "games/space-intruders/src/splash_date_generated.bas"

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
Sol36Gfx:
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"

' SOL-36 sputter phase — thin 2px center stripe, DEFINE-swapped into card 46
SolSputterGfx:
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."

' (Card 47 freed — was QuadGfx)
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

' --- COMPACT CHAIN TEXT (3 tiles, TinyFont 4px) ---
' Tile 1: CH (C left + H right)
ChainCHGfx:
    BITMAP "........"
    BITMAP ".X..X.X."
    BITMAP "X.X.X.X."
    BITMAP "X...XXX."
    BITMAP "X...X.X."
    BITMAP "X.X.X.X."
    BITMAP ".X..X.X."
    BITMAP "........"

' Tile 2: AI (A left + I right)
ChainAIGfx:
    BITMAP "........"
    BITMAP ".X..XXX."
    BITMAP "X.X..X.."
    BITMAP "X.X..X.."
    BITMAP "XXX..X.."
    BITMAP "X.X..X.."
    BITMAP "X.X.XXX."
    BITMAP "........"

' Tile 3: N: (N left + colon right, static — digits use GROM)
ChainNGfx:
    BITMAP "........"
    BITMAP "X.X....."
    BITMAP "XXX....."
    BITMAP "XXX.X..."
    BITMAP "XXX....."
    BITMAP "XXX....."
    BITMAP "X.X.X..."
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

' --- GAME OVER TinyFont labels (12 cards) ---

' Batch 1: SC, OR, E_, NE (cards 9-12)
GOBatch1:
    ' SC (S left + C right)
    BITMAP "........"
    BITMAP ".XX..X.."
    BITMAP "X...X.X."
    BITMAP ".X..X..."
    BITMAP "..X.X..."
    BITMAP "X.X.X.X."
    BITMAP ".X...X.."
    BITMAP "........"
    ' OR (O left + R right)
    BITMAP "........"
    BITMAP ".X..XX.."
    BITMAP "X.X.X.X."
    BITMAP "X.X.X.X."
    BITMAP "X.X.XX.."
    BITMAP "X.X.X.X."
    BITMAP ".X..X.X."
    BITMAP "........"
    ' E: (E left + colon right)
    BITMAP "........"
    BITMAP "XXX....."
    BITMAP "X......."
    BITMAP "XX..X..."
    BITMAP "X......."
    BITMAP "X......."
    BITMAP "XXX.X..."
    BITMAP "........"
    ' NE (N left + E right)
    BITMAP "........"
    BITMAP "X.X.XXX."
    BITMAP "XXX.X..."
    BITMAP "XXX.XX.."
    BITMAP "XXX.X..."
    BITMAP "XXX.X..."
    BITMAP "X.X.XXX."
    BITMAP "........"

' Batch 2: W_, HI, GH (cards 13-15)
GOBatch2:
    ' W_ (W left + blank right)
    BITMAP "........"
    BITMAP "X.X....."
    BITMAP "X.X....."
    BITMAP "X.X....."
    BITMAP "XXX....."
    BITMAP "XXX....."
    BITMAP "X.X....."
    BITMAP "........"
    ' HI (H left + I right)
    BITMAP "........"
    BITMAP "X.X.XXX."
    BITMAP "X.X..X.."
    BITMAP "XXX..X.."
    BITMAP "X.X..X.."
    BITMAP "X.X..X.."
    BITMAP "X.X.XXX."
    BITMAP "........"
    ' GH (G left + H right)
    BITMAP "........"
    BITMAP ".XX.X.X."
    BITMAP "X...X.X."
    BITMAP "X...XXX."
    BITMAP "X.X.X.X."
    BITMAP "X.X.X.X."
    BITMAP ".X..X.X."
    BITMAP "........"

' Batch 3: TO, P_, CH, AI (cards 42-45)
GOBatch3:
    ' TO (T left + O right)
    BITMAP "........"
    BITMAP "XXX..X.."
    BITMAP ".X..X.X."
    BITMAP ".X..X.X."
    BITMAP ".X..X.X."
    BITMAP ".X..X.X."
    BITMAP ".X...X.."
    BITMAP "........"
    ' P_ (P left + blank right)
    BITMAP "........"
    BITMAP "XX......"
    BITMAP "X.X....."
    BITMAP "X.X....."
    BITMAP "XX......"
    BITMAP "X......."
    BITMAP "X......."
    BITMAP "........"
    ' CH (C left + H right)
    BITMAP "........"
    BITMAP ".X..X.X."
    BITMAP "X.X.X.X."
    BITMAP "X...XXX."
    BITMAP "X...X.X."
    BITMAP "X.X.X.X."
    BITMAP ".X..X.X."
    BITMAP "........"
    ' AI (A left + I right)
    BITMAP "........"
    BITMAP ".X..XXX."
    BITMAP "X.X..X.."
    BITMAP "X.X..X.."
    BITMAP "XXX..X.."
    BITMAP "X.X..X.."
    BITMAP "X.X.XXX."
    BITMAP "........"

' Batch 4: N: (card 46)
GOBatch4:
    ' N: (N left + colon right)
    BITMAP "........"
    BITMAP "X.X....."
    BITMAP "XXX....."
    BITMAP "XXX.X..."
    BITMAP "XXX....."
    BITMAP "XXX....."
    BITMAP "X.X.X..."
    BITMAP "........"

' E_ without colon (card 20, for "NEW HIGH SCORE!")
GOEBlankGfx:
    BITMAP "........"
    BITMAP "XXX....."
    BITMAP "X......."
    BITMAP "XX......"
    BITMAP "X......."
    BITMAP "X......."
    BITMAP "XXX....."
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

' === BEAM powerup TinyFont: "BE" + "AM" (2 cards, 3rd blank) ===
PowerupBeamGfx:
    BITMAP "........"
    BITMAP "XX..XXX."
    BITMAP "X.X.X..."
    BITMAP "XX..XX.."
    BITMAP "X.X.X..."
    BITMAP "X.X.X..."
    BITMAP "XX..XXX."
    BITMAP "........"

    BITMAP "........"
    BITMAP ".X..X.X."
    BITMAP "X.X.XXX."
    BITMAP "X.X.XXX."
    BITMAP "XXX.X.X."
    BITMAP "X.X.X.X."
    BITMAP "X.X.X.X."
    BITMAP "........"

' === RAPID powerup TinyFont: "RA" + "PI" + "D_" (3 cards) ===
PowerupRapidGfx:
    BITMAP "........"
    BITMAP "XX...X.."
    BITMAP "X.X.X.X."
    BITMAP "X.X.X.X."
    BITMAP "XX..XXX."
    BITMAP "X.X.X.X."
    BITMAP "X.X.X.X."
    BITMAP "........"

    BITMAP "........"
    BITMAP "XX..XXX."
    BITMAP "X.X..X.."
    BITMAP "X.X..X.."
    BITMAP "XX...X.."
    BITMAP "X....X.."
    BITMAP "X...XXX."
    BITMAP "........"

    BITMAP "........"
    BITMAP "XX......"
    BITMAP "X.X....."
    BITMAP "X.X....."
    BITMAP "X.X....."
    BITMAP "X.X....."
    BITMAP "XX......"
    BITMAP "........"

' === BOMB powerup TinyFont: "BO" + "MB" (2 cards) ===
PowerupBombGfx:
    ' "BO" (B left + O right)
    BITMAP "........"
    BITMAP "XX...X.."
    BITMAP "X.X.X.X."
    BITMAP "XX..X.X."
    BITMAP "X.X.X.X."
    BITMAP "X.X.X.X."
    BITMAP "XX...X.."
    BITMAP "........"
    ' "MB" (M left + B right)
    BITMAP "........"
    BITMAP "X.X.XX.."
    BITMAP "XXX.X.X."
    BITMAP "XXX.XX.."
    BITMAP "X.X.X.X."
    BITMAP "X.X.X.X."
    BITMAP "X.X.XX.."
    BITMAP "........"

' === SOL-36 powerup TinyFont: "SO" + "L-" + "36" (3 cards) ===
PowerupSol36Gfx:
    ' Card 25: "SO" (S left + O right)
    BITMAP "........"
    BITMAP ".XX..X.."
    BITMAP "X...X.X."
    BITMAP ".XX.X.X."
    BITMAP "..X.X.X."
    BITMAP "..X.X.X."
    BITMAP "XX...X.."
    BITMAP "........"

    ' Card 26: "L-" (L left + dash right)
    BITMAP "........"
    BITMAP "X......."
    BITMAP "X......."
    BITMAP "X...XX.."
    BITMAP "X...XX.."
    BITMAP "X......."
    BITMAP "XXX....."
    BITMAP "........"

    ' Card 27: "36" (3 left + 6 right)
    BITMAP "........"
    BITMAP ".XX..XX."
    BITMAP "..X.X..."
    BITMAP ".XX.XX.."
    BITMAP "..X.X.X."
    BITMAP "..X.X.X."
    BITMAP ".XX..XX."
    BITMAP "........"

' === Y-axis spin frames for WAVE banner letters ===
' Used during wave transition spin-out animation (WaveAnnouncerType=1, timer 1-20)
' Card 32 (GRAM_FONT_T) cycles through these via DEFINE; card 47 (GRAM_ORBITER) = edge-on
WaveSpinWGfx:
    ' W at ~60 deg Y-axis rotation (narrow, columns 2-6, centered)
    BITMAP "..X...X."
    BITMAP "..X...X."
    BITMAP "..X...X."
    BITMAP "..X.X.X."
    BITMAP "..XXXXX."
    BITMAP "..XX.XX."
    BITMAP "..X...X."
    BITMAP "........"

WaveSpinAGfx:
    ' A at ~60 deg Y-axis rotation (narrow, columns 2-6)
    BITMAP "...XX..."
    BITMAP "..X..X.."
    BITMAP "..X..X.."
    BITMAP "..XXXXX."
    BITMAP "..X..X.."
    BITMAP "..X..X.."
    BITMAP "..X..X.."
    BITMAP "........"

WaveSpinVGfx:
    ' V at ~60 deg Y-axis rotation (narrow, columns 2-6)
    BITMAP "..X...X."
    BITMAP "..X...X."
    BITMAP "..X...X."
    BITMAP "..X...X."
    BITMAP "..XX.XX."
    BITMAP "..XXXXX."
    BITMAP "...XXX.."
    BITMAP "....X..."

WaveSpinEGfx:
    ' E at ~60 deg Y-axis rotation (narrow, columns 2-5)
    BITMAP "..XXXX.."
    BITMAP "..X....."
    BITMAP "..X....."
    BITMAP "..XXXX.."
    BITMAP "..X....."
    BITMAP "..X....."
    BITMAP "..XXXX.."
    BITMAP "........"

WaveSpinEdgeGfx:
    ' Edge-on frame shared by all letters (thin vertical bar, card 47)
    BITMAP "...XX..."
    BITMAP "...XX..."
    BITMAP "...XX..."
    BITMAP "...XX..."
    BITMAP "...XX..."
    BITMAP "...XX..."
    BITMAP "...XX..."
    BITMAP "........"

' === SHIELD dome graphic (solid bar above ship) ===
ShieldArcGfx:
    BITMAP "..####.."
    BITMAP "..#..#.."
    BITMAP ".##..##."
    BITMAP "##....##"
    BITMAP "##.##.##"
    BITMAP "#......#"
    BITMAP "#.####.#"
    BITMAP "###..###"

' === SPRITES from the French grafitti artist, SPACE INVADER

sprite_0_0:
    BITMAP "........"
    BITMAP "........"
    BITMAP "......X."
    BITMAP "....XXXX"
    BITMAP "....X..X"
    BITMAP "...XXXXX"
    BITMAP "...X..X."
    BITMAP "........"

sprite_0_1:
    BITMAP "........"
    BITMAP "........"
    BITMAP ".X......"
    BITMAP "XXX....."
    BITMAP "..X....."
    BITMAP "XXX....."
    BITMAP "X.XX...."
    BITMAP "........"

sprite_2_0:
    BITMAP "........"
    BITMAP "......XX"
    BITMAP ".....XXX"
    BITMAP ".....X.."
    BITMAP "...XXXXX"
    BITMAP "...X.XXX"
    BITMAP "...X..X."
    BITMAP "...XX..."

sprite_2_1:
    BITMAP "..XXXX.."
    BITMAP "XXXXXX.."
    BITMAP "XXX.XX.."
    BITMAP "XX..X..."
    BITMAP "XXXXXX.."
    BITMAP "XXXX.X.."
    BITMAP "X.X..X.."
    BITMAP "....XX.."

sprite_3_0:
    BITMAP "........"
    BITMAP ".......X"
    BITMAP "......XX"
    BITMAP "......X."
    BITMAP ".....XXX"
    BITMAP "....XX.X"
    BITMAP "........"
    BITMAP "........"

sprite_3_1:
    BITMAP "........"
    BITMAP "XX......"
    BITMAP "XXX....."
    BITMAP "X.X....."
    BITMAP "XXXX...."
    BITMAP ".X.XX..."
    BITMAP "X......."
    BITMAP "........"

sprite_4:
    BITMAP "........"
    BITMAP "........"
    BITMAP "...X.X.."
    BITMAP "..XXXXX."
    BITMAP "..X.X.X."
    BITMAP ".XXXXXXX"
    BITMAP ".X.X.X.X"
    BITMAP "........"

sprite_5_0:
    BITMAP ".......X"
    BITMAP "........"
    BITMAP "........"
    BITMAP ".......X"
    BITMAP "...XX.XX"
    BITMAP ".......X"
    BITMAP "........"
    BITMAP ".X.X.X.X"

sprite_5_1:
    BITMAP "..X....."
    BITMAP "X..X...."
    BITMAP "XXXXX..."
    BITMAP "XXXXXX.."
    BITMAP "..X..X.."
    BITMAP "XXXXXXX."
    BITMAP "X..X..X."
    BITMAP "..X..X.."

sprite_6_0:
    BITMAP "......XX"
    BITMAP "...X.XXX"
    BITMAP "...XX..X"
    BITMAP "...X.XXX"
    BITMAP "......X."
    BITMAP ".......X"
    BITMAP "........"
    BITMAP "........"

sprite_6_1:
    BITMAP "XX......"
    BITMAP "XXX.X..."
    BITMAP "..XXX..."
    BITMAP "XXX.X..."
    BITMAP ".X......"
    BITMAP "..X....."
    BITMAP "X..X...."
    BITMAP "........"

sprite_7_0:
    BITMAP "........"
    BITMAP "........"
    BITMAP ".......X"
    BITMAP "......XX"
    BITMAP "........"
    BITMAP ".....XXX"
    BITMAP ".....X.X"
    BITMAP "....XX.."

sprite_7_1:
    BITMAP "........"
    BITMAP "........"
    BITMAP "XXX....."
    BITMAP "XXX....."
    BITMAP "X..X...."
    BITMAP "XXXX...."
    BITMAP ".X.X...."
    BITMAP "...XX..."

sprite_8:
    BITMAP "........"
    BITMAP "...X.X.."
    BITMAP "..XXXXX."
    BITMAP ".X..X..X"
    BITMAP ".XXXXXXX"
    BITMAP "..X...X."
    BITMAP ".X.X.X.X"
    BITMAP "........"

sprite_9:
    BITMAP "........"
    BITMAP "..XXXX.."
    BITMAP ".XXXXXX."
    BITMAP ".X.XX.X."
    BITMAP "XXXXXXXX"
    BITMAP "X.X..X.X"
    BITMAP "X.X..X.X"
    BITMAP "........"

sprite_10_0:
    BITMAP "........"
    BITMAP "......X."
    BITMAP ".....XXX"
    BITMAP ".....X.X"
    BITMAP ".....XXX"
    BITMAP "....XXXX"
    BITMAP "...XX.X."
    BITMAP "........"

sprite_10_1:
    BITMAP "........"
    BITMAP "X......."
    BITMAP "XX......"
    BITMAP ".X......"
    BITMAP "XX......"
    BITMAP "XXX....."
    BITMAP "X.XX...."
    BITMAP "........"

sprite_11_0:
    BITMAP "........"
    BITMAP "......X."
    BITMAP "....X.XX"
    BITMAP ".....X.."
    BITMAP "......XX"
    BITMAP ".....X.X"
    BITMAP "..X.X.X."
    BITMAP "........"

sprite_11_1:
    BITMAP "........"
    BITMAP ".X......"
    BITMAP "XXX.X..."
    BITMAP "X..X...."
    BITMAP "XXX....."
    BITMAP ".X.X...."
    BITMAP "X.X....."
    BITMAP "........"

sprite_12_0:
    BITMAP ".....XXX"
    BITMAP "...XX..X"
    BITMAP "..XXXXXX"
    BITMAP "..XX.XX."
    BITMAP "..XX...X"
    BITMAP "....XX.X"
    BITMAP "....XX.X"
    BITMAP "....XX.."

sprite_12_1:
    BITMAP "XXXX...."
    BITMAP "XX..XX.."
    BITMAP "XXXXXX.."
    BITMAP "..XX.XX."
    BITMAP "XX...XX."
    BITMAP "XX.XX..."
    BITMAP "XX.XX..."
    BITMAP "...XX..."

sprite_13_0:
    BITMAP "......X."
    BITMAP "......XX"
    BITMAP "...X.XXX"
    BITMAP "...XXX.X"
    BITMAP ".....X.X"
    BITMAP "....XXXX"
    BITMAP "...XX.X."
    BITMAP "..XX...X"

sprite_13_1:
    BITMAP ".X......"
    BITMAP "XX......"
    BITMAP "XXX.X..."
    BITMAP "X.XXX..."
    BITMAP "X.X....."
    BITMAP "XXXX...."
    BITMAP ".X.XX..."
    BITMAP "X...XX.."

sprite_14_0:
    BITMAP "......X."
    BITMAP ".......X"
    BITMAP "......XX"
    BITMAP ".....XX."
    BITMAP "....XXX."
    BITMAP "......XX"
    BITMAP ".....XXX"
    BITMAP ".....X.X"

sprite_14_1:
    BITMAP "..X....."
    BITMAP "XX......"
    BITMAP "XXX....."
    BITMAP "X.XX...."
    BITMAP "X.XXX..."
    BITMAP "XXX....."
    BITMAP "XXXX...."
    BITMAP ".X.X...."
