# DOWNBEAT! Runner Prototype - IntyBASIC Implementation
## Minimum Viable Prototype (MVP) Design Document

**Game Concept:** Moon Patrol-style runner where player jumps over musical notes to perform "Twinkle Twinkle Little Star"

**Target Platform:** Intellivision (real hardware)  
**Language:** IntyBASIC  
**Prototype Goal:** Test if core jumping/rhythm gameplay is fun

---

## 1. Intellivision / IntyBASIC Technical Constraints

### Hardware Limits

**Display:**
- Resolution: 160 × 96 pixels (20 × 12 card grid)
- Each card: 8×8 pixels
- Color depth: 16 colors from fixed STIC palette
- Framerate: 60 FPS (NTSC) / 50 FPS (PAL)
- Overscan: ~5-10 pixels lost on all edges on CRT TVs

**Memory:**
- System RAM: 352 bytes (scratchpad)
- Graphics RAM: 240 bytes
- Total RAM: ~1.4KB (very limited!)

**Sprites (MOBs - Moving OBjects):**
- **Maximum: 8 sprites total** (hardware limit)
- Size: 8×8, 8×16, or 16×16 pixels
- Colors: Each sprite can use 1 foreground color
- Priority: Sprites can go in front or behind background
- Collisions: Hardware collision detection available
- Limitations: Max 4-5 sprites per scanline (flicker if exceeded)

**Background (Cards):**
- Grid: 20 cards wide × 12 cards tall
- Each card: 8×8 pixels from GROM (Graphics ROM)
- GROM: 256 predefined card patterns
- GRAM: 64 custom card patterns (can define your own)
- Colors: Each card has 1 foreground + 1 background color

**Sound (AY-3-8914 PSG):**
- 3 independent square wave channels
- 1 noise channel
- No sampling or complex waveforms
- Frequency range: ~30 Hz to 125 KHz

**Controller:**
- 16-button keypad (0-9, Clear, Enter, side buttons)
- 8-way disc (directional control)
- 4 side action buttons (top/bottom on each side)

**CPU:**
- General Instrument CP1610 running at ~0.894 MHz
- 10-bit word size (not 8-bit!)
- Limited processing power

### IntyBASIC Language Specifics

**Data Types:**
- Integer only (16-bit signed: -32768 to 32767)
- No floating point
- Arrays supported but consume RAM quickly
- Strings limited (mainly for PRINT)

**Key Commands:**
- `SPRITE` - Define and move MOBs
- `SCREEN` - Set background card/color
- `PRINT` - Text display using GROM font
- `SOUND` - Generate audio on PSG channels
- `CONT` - Read controller input
- `#BACKTAB` - Direct background manipulation
- `WAIT` - Wait for next frame (60 Hz sync)

**Performance:**
- All code must complete within 1/60 second per frame
- Avoid complex calculations in main loop
- Use lookup tables instead of math when possible
- Fixed-point math required (no floats)

**ROM Space:**
- Typical cartridge: 8K (can go up to 48K with bank switching)
- Code + data must fit in ROM
- Graphics data (GRAM definitions) consume ROM space

---

## 2. MVP Screen Layout

### Visual Structure

```
┌────────────────────────────────────────┐  Y=0
│ HITS: 0/3           SCORE: 0           │  (Cards 0-19, Row 0)
├────────────────────────────────────────┤  Y=8
│                                        │
│              SKY AREA                  │  (Cards 0-19, Rows 1-5)
│                                        │
│                                        │
│           [Player]                     │  Y=48 (MOB sprite)
├────────────────────────────────────────┤  Y=56
│ ════════════════════════════════════   │  (Ground line, Row 7)
│         [■]   [■]      [■]             │  (Note MOBs)
│                                        │
│                                        │
└────────────────────────────────────────┘  Y=96
  0                                    160
  Card columns: 0  1  2  3 ... 18  19
```

### Card Grid Layout

**Row 0 (Y=0-7): UI Bar**
- Black background cards
- White text using PRINT AT
- Left side: "HITS: 0/3"
- Right side: Score counter

**Rows 1-6 (Y=8-55): Sky/Playfield**
- All black cards (empty sky)
- Player and note sprites appear here

**Row 7 (Y=56-63): Ground**
- White horizontal line (ground surface)
- Can use GRAM custom card with white top pixels

**Rows 8-11 (Y=64-95): Underground**
- Black cards (not visible in gameplay)

### Sprite Allocation (8 MOBs Maximum)

**MOB 0: Player Character**
- Size: 8×16 pixels (double-height)
- Color: RED ($04 in STIC palette)
- X position: 40 (fixed, 1/4 from left edge)
- Y position: Variable (32-52 range)
- Priority: In front of background

**MOBs 1-7: Note Obstacles (7 notes maximum on screen)**
- Size: 8×8 pixels each
- Color: YELLOW ($06 in STIC palette)
- X position: Scrolling right-to-left
- Y position: 48 (sitting on ground at Y=56)
- Priority: In front of background
- Recycled: When note scrolls off left, reuse sprite for new note on right

**Sprite Reuse Strategy:**
```basic
REM Track which notes are active
DIM note_active(7)     REM 0=inactive, 1=active
DIM note_x_pos(7)      REM X position (0-160)
DIM note_pitch(7)      REM Which note (for audio)

REM Find inactive sprite slot
PROCEDURE GET_FREE_SPRITE
    DIM i
    FOR i = 0 TO 6
        IF note_active(i) = 0 THEN
            RETURN i
        END IF
    NEXT i
    RETURN -1    REM No free sprites
END
```

---

## 3. Scrolling & Movement

### Moon Patrol Style Movement

**Player:** 
- Stays at fixed X = 40 pixels
- Only Y changes (jumping)
- Appears to run in place

**Notes:**
- Spawn at X = 168 (just off right edge)
- Scroll leftward each frame
- Despawn at X = -8 (off left edge)

### Scroll Speed

**Target: 100 pixels/second**

At 60 FPS:
```
100 pixels/sec ÷ 60 frames/sec = 1.67 pixels/frame
```

**Fixed-Point Math:**

IntyBASIC only has integers. To get sub-pixel movement:
```basic
REM Use 8-bit fixed-point: position * 256
REM This gives 1/256 pixel precision

CONST SCROLL_SPEED_FIXED = 427   REM 427/256 = 1.668 ≈ 1.67 px/frame

DIM note_x_fixed(7)   REM Fixed-point X positions (x256)

REM Each frame:
note_x_fixed(i) = note_x_fixed(i) - SCROLL_SPEED_FIXED
note_x_pos(i) = note_x_fixed(i) / 256    REM Convert to screen pixels
```

**Why fixed-point?**
- Avoids cumulative rounding errors
- Smooth sub-pixel movement
- Standard technique for Intellivision games

---

## 4. Jump Mechanics

### Jump Parameters

**Timing:**
- Duration: 600ms = 36 frames (at 60 FPS)
- Total arc: Up 18 frames, down 18 frames

**Height:**
- Ground Y: 48 (player standing on ground at Y=56)
- Jump peak: Y = 28 (20 pixels above ground)
- Arc range: Y = 28 to Y = 48

**Arc Shape:**
- Parabolic curve (realistic gravity feel)
- Formula: `height = -4 * t * (t - 1)` where t goes from 0 to 1

### Implementation

**State Variables:**
```basic
DIM jump_active         REM 0=on ground, 1=jumping
DIM jump_frame          REM Current frame in jump (0-35)
DIM player_y            REM Current Y position

CONST GROUND_Y = 48
CONST JUMP_HEIGHT = 20
CONST JUMP_FRAMES = 36
```

**Jump Arc Calculation:**
```basic
PROCEDURE UPDATE_PLAYER_JUMP
    IF jump_active = 1 THEN
        REM Calculate parabolic arc using integer math
        REM Arc formula: y = -4*t*(t-1) where t = jump_frame/36
        
        DIM t, arc_height
        
        REM Fixed-point: t = (jump_frame * 256) / 36
        t = (jump_frame * 256) / JUMP_FRAMES
        
        REM arc_height = -4 * t * (t - 256) / 256
        REM Simplified: arc_height = (4 * t * (256 - t)) / 256
        arc_height = (t * (256 - t)) / 64
        
        REM Apply to player position
        player_y = GROUND_Y - ((JUMP_HEIGHT * arc_height) / 256)
        
        REM Advance frame
        jump_frame = jump_frame + 1
        
        REM End jump when complete
        IF jump_frame >= JUMP_FRAMES THEN
            jump_active = 0
            jump_frame = 0
            player_y = GROUND_Y
        END IF
    ELSE
        player_y = GROUND_Y
    END IF
    
    REM Update sprite position
    SPRITE 0, player_y, 40, SPR00    REM MOB 0, Y, X, sprite data
END
```

**Triggering Jump:**
```basic
PROCEDURE HANDLE_INPUT
    REM Check any action button (4 side buttons)
    REM CONT.BUTTON returns bitmask of pressed buttons
    
    IF CONT.BUTTON <> 0 AND jump_active = 0 THEN
        jump_active = 1
        jump_frame = 0
    END IF
END
```

**Lookup Table Alternative (Performance Optimization):**

Instead of calculating arc every frame, pre-compute:
```basic
REM Define jump arc as 36-value lookup table
DATA jump_arc_table
    DATA 0, 2, 4, 6, 8, 9, 11, 12, 14, 15
    DATA 16, 17, 18, 18, 19, 19, 20, 20, 20
    DATA 20, 20, 20, 19, 19, 18, 18, 17, 16
    DATA 15, 14, 12, 11, 9, 8, 6, 4, 2, 0

DIM jump_arc(36)   REM Load into array at startup

REM Then in update:
player_y = GROUND_Y - jump_arc(jump_frame)
```

---

## 5. Collision Detection

### When to Check

**Every frame:**
- After updating player Y position
- After scrolling all notes

### Collision Logic

**Bounding Boxes:**
```
Player (8×16 sprite):
- X: 40 to 48
- Y: player_y to (player_y + 16)
- Bottom edge: player_y + 16

Note (8×8 sprite):
- X: note_x to (note_x + 8)
- Y: 48 to 56
- Top edge: 48
```

**Collision Test:**
```basic
PROCEDURE CHECK_NOTE_COLLISION(note_index)
    DIM note_x, player_bottom, note_top
    DIM h_overlap, v_overlap
    
    note_x = note_x_pos(note_index)
    
    REM Only check active notes
    IF note_active(note_index) = 0 THEN RETURN 0
    
    REM Horizontal overlap test
    h_overlap = 0
    IF note_x < 48 AND note_x + 8 > 40 THEN
        h_overlap = 1
    END IF
    
    IF h_overlap = 0 THEN RETURN 0   REM No horizontal overlap
    
    REM Vertical overlap test
    player_bottom = player_y + 16
    note_top = 48
    
    v_overlap = 0
    IF player_bottom > note_top THEN
        v_overlap = 1    REM Player hit the note!
    ELSE
        v_overlap = 0    REM Player jumped over it!
    END IF
    
    RETURN v_overlap
END
```

**Hardware Collision Detection (Alternative):**

Intellivision has built-in collision detection:
```basic
REM Check if MOB 0 (player) collided with any other MOB
IF COL0 <> 0 THEN
    REM COL0 is bitmask of which MOBs collided with MOB 0
    REM Check which note was hit
    IF COL0 AND $02 THEN REM Collided with MOB 1 (note 0)
    IF COL0 AND $04 THEN REM Collided with MOB 2 (note 1)
    REM etc...
END IF
```

**But:** Hardware collision doesn't distinguish "jumped over" vs "hit". We need custom logic to check if player is ABOVE note.

---

## 6. Melody System: "Twinkle Twinkle Little Star"

### Full Song Data

**Complete melody (48 beats):**
```basic
REM Twinkle Twinkle Little Star
REM Tempo: 100 BPM = 600ms per beat = 36 frames per beat

DATA melody_notes
    REM Verse 1: Twinkle twinkle little star
    DATA 0, 0, 4, 4, 5, 5, 4, -1
    REM How I wonder what you are
    DATA 3, 3, 2, 2, 1, 1, 0, -1
    REM Verse 2: Up above the world so high
    DATA 4, 4, 3, 3, 2, 2, 1, -1
    REM Like a diamond in the sky
    DATA 4, 4, 3, 3, 2, 2, 1, -1
    REM Verse 1 repeat
    DATA 0, 0, 4, 4, 5, 5, 4, -1
    DATA 3, 3, 2, 2, 1, 1, 0, -1

REM Note values: 0=C, 1=D, 2=E, 3=F, 4=G, 5=A, -1=REST

DIM melody(48)   REM Load at startup
CONST MELODY_LENGTH = 48
```

### Note Frequencies (PSG)

**Musical notes to PSG frequency:**
```basic
REM AY-3-8914 PSG frequency = 111860 / (16 * desired_Hz)
REM Middle C scale (C4-A4):

CONST NOTE_C = 425    REM C4 = 262 Hz
CONST NOTE_D = 378    REM D4 = 294 Hz  
CONST NOTE_E = 337    REM E4 = 330 Hz
CONST NOTE_F = 318    REM F4 = 349 Hz
CONST NOTE_G = 283    REM G4 = 392 Hz
CONST NOTE_A = 252    REM A4 = 440 Hz

DIM note_freq(6)      REM Lookup table
note_freq(0) = NOTE_C
note_freq(1) = NOTE_D
note_freq(2) = NOTE_E
note_freq(3) = NOTE_F
note_freq(4) = NOTE_G
note_freq(5) = NOTE_A
```

### Note Spawning Timing

**At 100 BPM:**
- 600ms per beat
- = 36 frames per beat (at 60 FPS)

**Spawn Schedule:**
```basic
DIM beat_counter        REM Current beat (0-47)
DIM frames_until_spawn  REM Countdown to next beat
CONST FRAMES_PER_BEAT = 36

PROCEDURE SPAWN_NEXT_NOTE
    REM Check if it's time to spawn
    frames_until_spawn = frames_until_spawn - 1
    
    IF frames_until_spawn <= 0 AND beat_counter < MELODY_LENGTH THEN
        REM Get note pitch for this beat
        DIM pitch
        pitch = melody(beat_counter)
        
        REM Don't spawn for REST beats (-1)
        IF pitch >= 0 THEN
            REM Find free sprite slot
            DIM slot
            slot = GET_FREE_SPRITE()
            
            IF slot >= 0 THEN
                REM Activate note
                note_active(slot) = 1
                note_x_pos(slot) = 168       REM Spawn off right edge
                note_x_fixed(slot) = 168 * 256
                note_pitch(slot) = pitch
                
                REM Position sprite
                SPRITE slot + 1, 48, note_x_pos(slot), SPR_NOTE
            END IF
        END IF
        
        REM Advance to next beat
        beat_counter = beat_counter + 1
        frames_until_spawn = FRAMES_PER_BEAT
    END IF
END
```

### Note Spacing on Screen

**At 100 px/sec scroll and 600ms beat:**
```
Distance = 100 px/sec * 0.6 sec = 60 pixels between notes
```

This is perfect spacing - notes won't overlap or get too crowded.

---

## 7. Audio System

### Sound Channels

**Channel Allocation:**
- Channel A (0): Melody notes when cleared
- Channel B (1): Unused in MVP
- Channel C (2): Unused in MVP

### Playing Notes

**When note is cleared (jumped over):**
```basic
PROCEDURE PLAY_NOTE(pitch_index)
    DIM freq
    
    freq = note_freq(pitch_index)
    
    REM Play on channel A, volume 15 (max)
    SOUND 0, freq, 15
    
    REM Schedule note off after 200ms (12 frames)
    note_off_timer = 12
END

REM In main loop:
IF note_off_timer > 0 THEN
    note_off_timer = note_off_timer - 1
    IF note_off_timer = 0 THEN
        SOUND 0, 0, 0    REM Silence channel A
    END IF
END IF
```

**Simple feedback sound for hits:**
```basic
PROCEDURE PLAY_HIT_SOUND
    REM Low buzzing noise
    SOUND 0, 100, 10   REM Low frequency, medium volume
    WAIT               REM 1 frame
    SOUND 0, 0, 0      REM Immediate cutoff
END
```

---

## 8. Game State & Flow

### State Machine

```basic
DIM game_state          REM Current state
CONST STATE_PLAYING = 0
CONST STATE_GAMEOVER = 1
CONST STATE_SUCCESS = 2
```

### Main Game Loop

```basic
REM Initialization (once at startup)
PROCEDURE INIT_GAME
    REM Load melody data
    FOR i = 0 TO 47
        READ melody(i)
    NEXT i
    
    REM Load note frequencies
    note_freq(0) = NOTE_C
    note_freq(1) = NOTE_D
    note_freq(2) = NOTE_E
    note_freq(3) = NOTE_F
    note_freq(4) = NOTE_G
    note_freq(5) = NOTE_A
    
    REM Initialize game vars
    hit_count = 0
    beat_counter = 0
    frames_until_spawn = FRAMES_PER_BEAT
    game_state = STATE_PLAYING
    
    REM Clear all notes
    FOR i = 0 TO 6
        note_active(i) = 0
    NEXT i
    
    REM Setup player sprite
    DEFINE 0, 1, player_sprite_data   REM Define MOB 0 graphics
    SPRITE 0, GROUND_Y, 40, SPR00 + RED
    
    REM Setup note sprite pattern (used by MOBs 1-7)
    DEFINE 1, 1, note_sprite_data
    
    REM Draw background
    CLS
    CALL DRAW_UI
    CALL DRAW_GROUND
END

REM Main Loop (runs every frame)
DO
    REM Handle input
    CALL HANDLE_INPUT
    
    REM Update player jump
    CALL UPDATE_PLAYER_JUMP
    
    REM Spawn notes on beat
    CALL SPAWN_NEXT_NOTE
    
    REM Scroll all active notes
    FOR i = 0 TO 6
        IF note_active(i) = 1 THEN
            REM Scroll left
            note_x_fixed(i) = note_x_fixed(i) - SCROLL_SPEED_FIXED
            note_x_pos(i) = note_x_fixed(i) / 256
            
            REM Update sprite position
            SPRITE i + 1, 48, note_x_pos(i), SPR01 + YELLOW
            
            REM Despawn if off screen
            IF note_x_pos(i) < -8 THEN
                note_active(i) = 0
                SPRITE i + 1, 0, 0, 0    REM Hide sprite
            END IF
        END IF
    NEXT i
    
    REM Check collisions
    FOR i = 0 TO 6
        IF note_active(i) = 1 THEN
            DIM hit
            hit = CHECK_NOTE_COLLISION(i)
            
            IF hit = 1 THEN
                REM Player hit the note!
                hit_count = hit_count + 1
                note_active(i) = 0    REM Remove note
                SPRITE i + 1, 0, 0, 0
                CALL PLAY_HIT_SOUND
                CALL UPDATE_UI
                
                REM Check for game over
                IF hit_count >= 3 THEN
                    game_state = STATE_GAMEOVER
                END IF
            ELSE IF note_x_pos(i) < 32 AND note_cleared(i) = 0 THEN
                REM Note passed player - jumped successfully!
                note_cleared(i) = 1
                CALL PLAY_NOTE(note_pitch(i))
            END IF
        END IF
    NEXT i
    
    REM Update UI
    REM (prints happen here)
    
    REM Check win condition
    IF beat_counter >= MELODY_LENGTH THEN
        REM All notes spawned, check if all cleared
        DIM all_cleared
        all_cleared = 1
        FOR i = 0 TO 6
            IF note_active(i) = 1 THEN all_cleared = 0
        NEXT i
        
        IF all_cleared = 1 THEN
            game_state = STATE_SUCCESS
        END IF
    END IF
    
    REM Wait for next frame (60 Hz sync)
    WAIT
LOOP WHILE game_state = STATE_PLAYING

REM Game Over or Success screens
IF game_state = STATE_GAMEOVER THEN
    CALL SHOW_GAME_OVER
ELSE IF game_state = STATE_SUCCESS THEN
    CALL SHOW_SUCCESS
END IF
```

---

## 9. Sprite Graphics Definition

### Player Sprite (8×16 Double-Height)

**Simple box placeholder:**
```basic
REM Sprite data: 8 bytes for 8×8, double for 8×16
player_sprite_data:
    DATA $FF, $FF, $C3, $C3, $C3, $C3, $FF, $FF   REM Top half
    DATA $FF, $FF, $C3, $C3, $C3, $C3, $FF, $FF   REM Bottom half
    
REM Pattern:
REM 11111111  (top border)
REM 11111111
REM 11000011  (hollow box)
REM 11000011
REM 11000011
REM 11000011
REM 11111111  (bottom border)
REM 11111111
```

### Note Sprite (8×8)

**Simple square:**
```basic
note_sprite_data:
    DATA $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
    
REM Pattern: solid 8×8 square
REM 11111111
REM 11111111
REM 11111111
REM 11111111
REM 11111111
REM 11111111
REM 11111111
REM 11111111
```

### Defining Sprites in Code

```basic
REM Define sprite patterns for MOBs
DEFINE 0, 2, player_sprite_data    REM MOB 0, 2 cards (8×16)
DEFINE 1, 1, note_sprite_data       REM MOB 1-7, 1 card each (8×8)
```

---

## 10. Background Graphics

### Ground Line

**Using GRAM custom card:**
```basic
REM Define custom card with white line at top
ground_card_data:
    DATA $FF, $FF, $00, $00, $00, $00, $00, $00
    
REM Load into GRAM slot 0
DEFINE GRAM 0, 1, ground_card_data

REM Draw ground line across row 7
FOR x = 0 TO 19
    SCREEN x + 7 * 20, 0, WHITE   REM Card index 0, white color
NEXT x
```

### UI Text Display

**Using built-in font:**
```basic
PROCEDURE DRAW_UI
    PRINT AT 1, "HITS:", hit_count, "/3"
    PRINT AT 14, "SCORE:", score
END

PROCEDURE UPDATE_UI
    PRINT AT 6, hit_count
END
```

**Text positioning:**
- `PRINT AT position` uses card grid (20 cards wide)
- Position = row * 20 + column
- Row 0: positions 0-19

---

## 11. Memory Management

### RAM Usage Estimate

**Variables:**
```basic
REM Game state (2 bytes each)
DIM game_state, jump_active, jump_frame, player_y
DIM beat_counter, frames_until_spawn, hit_count, score
REM = 8 vars × 2 bytes = 16 bytes

REM Arrays (2 bytes per element)
DIM note_active(7)      REM 8 × 2 = 16 bytes
DIM note_x_pos(7)       REM 8 × 2 = 16 bytes
DIM note_x_fixed(7)     REM 8 × 2 = 16 bytes
DIM note_pitch(7)       REM 8 × 2 = 16 bytes
DIM note_cleared(7)     REM 8 × 2 = 16 bytes
DIM melody(48)          REM 48 × 2 = 96 bytes
DIM note_freq(6)        REM 6 × 2 = 12 bytes
REM Total arrays: 188 bytes

REM Total RAM: ~204 bytes (well within 352-byte limit!)
```

**Optimization tips:**
- Share variables when possible
- Use bit-packing for boolean flags
- Reuse temporary variables across procedures

---

## 12. ROM Usage Estimate

**Code:**
- Main loop + procedures: ~2-3 KB
- Melody data: 48 × 2 bytes = 96 bytes
- Sprite definitions: ~32 bytes
- GRAM card data: ~16 bytes

**Total: ~3-4 KB (fits easily in 8K cartridge)**

---

## 13. Implementation Checklist

### Phase 1: Basic Display
- [ ] Initialize screen (CLS, draw ground)
- [ ] Define player sprite graphics
- [ ] Display player sprite at fixed position
- [ ] Draw UI text (hits, score)

### Phase 2: Player Control
- [ ] Implement jump state machine
- [ ] Handle controller input (any button = jump)
- [ ] Update player Y position each frame
- [ ] Test jump arc timing and height

### Phase 3: Note Scrolling
- [ ] Define note sprite graphics
- [ ] Spawn single test note at right edge
- [ ] Scroll note leftward using fixed-point math
- [ ] Despawn note when off-screen
- [ ] Test smooth scrolling at 100 px/sec

### Phase 4: Collision Detection
- [ ] Implement bounding box collision test
- [ ] Detect when player hits note (game over)
- [ ] Detect when player jumps over note (success)
- [ ] Update hit counter on collision

### Phase 5: Melody System
- [ ] Load Twinkle Twinkle melody data
- [ ] Spawn notes on beat (36-frame intervals)
- [ ] Handle REST beats (no spawn)
- [ ] Manage sprite reuse pool (7 notes max)

### Phase 6: Audio
- [ ] Define note frequency table
- [ ] Play note when successfully jumped
- [ ] Play error sound when hit
- [ ] Add note-off timer (don't sustain forever)

### Phase 7: Game Flow
- [ ] Implement game states (playing/gameover/success)
- [ ] Add game over screen (hit 3 notes)
- [ ] Add success screen (complete melody)
- [ ] Add restart functionality

### Phase 8: Polish
- [ ] Fine-tune scroll speed (test feel)
- [ ] Fine-tune jump arc (test feel)
- [ ] Adjust audio timing and volume
- [ ] Test full 29-second playthrough

---

## 14. Testing & Tuning

### Critical Playtesting Questions

After first playable build:

1. **Jump feel:**
   - Is 600ms (36 frames) too slow? Too fast?
   - Is 20px height enough clearance?
   - Does arc feel natural?

2. **Scroll speed:**
   - Is 100 px/sec too fast to react?
   - Can you see notes approaching in time?
   - Is spacing between notes comfortable?

3. **Difficulty:**
   - Are 3 hits too forgiving? Too harsh?
   - Is Twinkle Twinkle boring or good for testing?
   - Does 29 seconds feel right?

4. **Fun factor:**
   - Do you want to play it again?
   - Is jumping satisfying?
   - Does melody playback feel rewarding?

### Tuning Parameters

**Easy adjustments:**
```basic
REM Scroll speed
CONST SCROLL_SPEED_FIXED = 427   REM Decrease = slower/easier

REM Jump duration
CONST JUMP_FRAMES = 36           REM Increase = longer hang-time

REM Jump height  
CONST JUMP_HEIGHT = 20           REM Increase = higher jumps

REM Hit limit
CONST MAX_HITS = 3               REM Increase = more forgiving

REM Tempo
CONST FRAMES_PER_BEAT = 36       REM Increase = slower song
```

---

## 15. Known Limitations & Future Expansion

### MVP Limitations

**What's NOT in this prototype:**
- No second player / sabotage
- No power-ups (immunity, bouquets)
- No energy meter (just 3-hit counter)
- No multiple melodies
- No difficulty levels
- No background graphics
- No fancy sprites (just boxes)
- No ditches or advanced obstacles

### Expansion Path

**After MVP validated:**
1. Add visual polish (better sprites)
2. Add more melodies (different lengths/difficulties)
3. Add power-up system (immunity tuba, healing flowers)
4. Add 2-player sabotage mode
5. Add background parallax layers
6. Add difficulty tiers (faster scroll, less forgiveness)

---

## 16. IntyBASIC Code Template

### Complete Skeleton

```basic
REM ============================================
REM DOWNBEAT! Runner Prototype
REM ============================================

REM Constants
CONST GROUND_Y = 48
CONST JUMP_HEIGHT = 20
CONST JUMP_FRAMES = 36
CONST SCROLL_SPEED_FIXED = 427
CONST FRAMES_PER_BEAT = 36
CONST MELODY_LENGTH = 48
CONST MAX_HITS = 3

REM Game variables
DIM game_state, jump_active, jump_frame, player_y
DIM beat_counter, frames_until_spawn, hit_count
DIM note_off_timer

REM Note arrays
DIM note_active(7), note_x_pos(7), note_x_fixed(7)
DIM note_pitch(7), note_cleared(7)

REM Melody data
DIM melody(48), note_freq(6)

REM Sprite data
player_sprite_data:
    DATA $FF, $FF, $C3, $C3, $C3, $C3, $FF, $FF
    DATA $FF, $FF, $C3, $C3, $C3, $C3, $FF, $FF

note_sprite_data:
    DATA $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF

melody_data:
    DATA 0, 0, 4, 4, 5, 5, 4, -1
    DATA 3, 3, 2, 2, 1, 1, 0, -1
    DATA 4, 4, 3, 3, 2, 2, 1, -1
    DATA 4, 4, 3, 3, 2, 2, 1, -1
    DATA 0, 0, 4, 4, 5, 5, 4, -1
    DATA 3, 3, 2, 2, 1, 1, 0, -1

REM ============================================
REM Initialization
REM ============================================
PROCEDURE INIT_GAME
    REM Load melody
    RESTORE melody_data
    FOR i = 0 TO 47
        READ melody(i)
    NEXT i
    
    REM Load note frequencies
    note_freq(0) = 425  : REM C
    note_freq(1) = 378  : REM D
    note_freq(2) = 337  : REM E
    note_freq(3) = 318  : REM F
    note_freq(4) = 283  : REM G
    note_freq(5) = 252  : REM A
    
    REM Initialize state
    hit_count = 0
    beat_counter = 0
    frames_until_spawn = FRAMES_PER_BEAT
    jump_active = 0
    player_y = GROUND_Y
    
    REM Clear notes
    FOR i = 0 TO 6
        note_active(i) = 0
        note_cleared(i) = 0
    NEXT i
    
    REM Define sprites
    DEFINE 0, 2, player_sprite_data
    DEFINE 1, 1, note_sprite_data
    
    REM Setup display
    CLS
    CALL DRAW_GROUND
    CALL DRAW_UI
    
    REM Show player
    SPRITE 0, player_y, 40, $0800 + $0004   REM Red color
END

REM ============================================
REM Main Loop
REM ============================================
CALL INIT_GAME

DO
    REM Input
    IF CONT.BUTTON <> 0 AND jump_active = 0 THEN
        jump_active = 1
        jump_frame = 0
    END IF
    
    REM Update jump
    IF jump_active = 1 THEN
        DIM t, arc
        t = (jump_frame * 256) / JUMP_FRAMES
        arc = (t * (256 - t)) / 64
        player_y = GROUND_Y - ((JUMP_HEIGHT * arc) / 256)
        jump_frame = jump_frame + 1
        IF jump_frame >= JUMP_FRAMES THEN
            jump_active = 0
            player_y = GROUND_Y
        END IF
    END IF
    
    REM Update sprite
    SPRITE 0, player_y, 40, $0800 + $0004
    
    REM Spawn notes
    frames_until_spawn = frames_until_spawn - 1
    IF frames_until_spawn <= 0 AND beat_counter < MELODY_LENGTH THEN
        DIM pitch
        pitch = melody(beat_counter)
        IF pitch >= 0 THEN
            DIM slot
            slot = -1
            FOR i = 0 TO 6
                IF note_active(i) = 0 THEN slot = i : i = 7
            NEXT i
            IF slot >= 0 THEN
                note_active(slot) = 1
                note_x_pos(slot) = 168
                note_x_fixed(slot) = 168 * 256
                note_pitch(slot) = pitch
                note_cleared(slot) = 0
            END IF
        END IF
        beat_counter = beat_counter + 1
        frames_until_spawn = FRAMES_PER_BEAT
    END IF
    
    REM Scroll notes
    FOR i = 0 TO 6
        IF note_active(i) = 1 THEN
            note_x_fixed(i) = note_x_fixed(i) - SCROLL_SPEED_FIXED
            note_x_pos(i) = note_x_fixed(i) / 256
            SPRITE i + 1, 48, note_x_pos(i), $0800 + $0006
            
            IF note_x_pos(i) < -8 THEN
                note_active(i) = 0
                SPRITE i + 1, 0, 0, 0
            END IF
        END IF
    NEXT i
    
    REM Collisions
    FOR i = 0 TO 6
        IF note_active(i) = 1 THEN
            DIM nx
            nx = note_x_pos(i)
            IF nx < 48 AND nx + 8 > 40 THEN
                DIM pb
                pb = player_y + 16
                IF pb > 48 THEN
                    REM Hit!
                    hit_count = hit_count + 1
                    note_active(i) = 0
                    SPRITE i + 1, 0, 0, 0
                    SOUND 0, 100, 10
                    CALL DRAW_UI
                    IF hit_count >= MAX_HITS THEN game_state = 1
                ELSE IF nx < 32 AND note_cleared(i) = 0 THEN
                    REM Cleared!
                    note_cleared(i) = 1
                    SOUND 0, note_freq(note_pitch(i)), 15
                    note_off_timer = 12
                END IF
            END IF
        END IF
    NEXT i
    
    REM Audio timing
    IF note_off_timer > 0 THEN
        note_off_timer = note_off_timer - 1
        IF note_off_timer = 0 THEN SOUND 0, 0, 0
    END IF
    
    WAIT
LOOP WHILE game_state = 0

REM Game over
PRINT AT 100, "GAME OVER!"

REM ============================================
REM Procedures
REM ============================================
PROCEDURE DRAW_GROUND
    FOR x = 0 TO 19
        SCREEN x + 7 * 20, $00, $07   REM White card
    NEXT x
END

PROCEDURE DRAW_UI
    PRINT AT 1, "HITS:", hit_count, "/", MAX_HITS
END
```

---

**End of Design Document**

This prototype can be built and tested quickly to determine if the core runner/jumping gameplay is fun before adding complexity like sabotage, power-ups, or visual polish.