# Screen Layout & Rendering Specification
## DOWNBEAT! - Visual Implementation Guide

This document defines exact pixel coordinates, sizes, colors, and rendering specifications for all screens in DOWNBEAT!

---

## 1. Screen Resolution & Constraints

### Intellivision Display
- **Resolution:** 159 × 96 pixels
- **Aspect Ratio:** ~1.66:1 (wider than standard)
- **Color Depth:** 16 colors (fixed palette)
- **Safe Area:** Consider 5px border on all sides for TV overscan

### Recommended Implementation Resolution
For modern development, scale up for visibility while maintaining aspect ratio:
- **Development:** 1590 × 960 pixels (10x scale)
- **Or:** 795 × 480 pixels (5x scale)
- **Final:** Scale down to 159 × 96 for authentic look

**All coordinates below are given in ORIGINAL 159×96 resolution**

---

## 2. Intellivision Color Palette

### Complete 16-Color Palette with Hex Approximations

| Color Name   | Hex Code | RGB           | Usage in DOWNBEAT! |
|--------------|----------|---------------|--------------------|
| Black        | #000000  | 0, 0, 0       | Background         |
| Blue         | #002DFF  | 0, 45, 255    | (unused)           |
| Red          | #FF3D10  | 255, 61, 16   | Player 1, Timpani  |
| Tan          | #C9CFAB  | 201, 207, 171 | (unused)           |
| Dark Green   | #386B3F  | 56, 107, 63   | Bassoon            |
| Green        | #00A756  | 0, 167, 86    | Adagio selection   |
| Yellow       | #FAEA50  | 250, 234, 80  | Trumpet            |
| White        | #FAFFFF  | 250, 255, 255 | Text, UI elements  |
| Gray         | #A7A8A8  | 167, 168, 168 | Disabled, Rest     |
| Cyan         | #5ACBFF  | 90, 203, 255  | Piccolo            |
| Orange       | #FF9F27  | 255, 159, 39  | Metronome, accents |
| Brown        | #A66A23  | 166, 106, 35  | (unused)           |
| Pink         | #FF3276  | 255, 50, 118  | Viola, UI accents  |
| Light Blue   | #B4DDEF  | 180, 221, 239 | Violin             |
| Yellow-Green | #C9D487  | 201, 212, 135 | Trombone           |
| Purple       | #D37ACA  | 211, 122, 202 | Player 2, Oboe     |

### Color Usage Map

**Theme Colors:**
- Player 1: Red (#FF3D10)
- Player 2: Purple (#D37ACA)
- Accent/Metronome: Orange (#FF9F27)
- Background: Black (#000000)
- Text: White (#FAFFFF)
- Disabled: Gray (#A7A8A8)

**Instrument Colors:**
- Piccolo: Cyan (#5ACBFF)
- Trumpet: Yellow (#FAEA50)
- Violin: Light Blue (#B4DDEF)
- Oboe: Orange (#FF9F27)
- Viola: Pink (#FF3276)
- Trombone: Yellow-Green (#C9D487)
- Bassoon: Dark Green (#386B3F)
- Timpani: Red (#FF3D10)
- Rest: Gray (#A7A8A8)

---

## 3. Main Gameplay Screen Layout

### Overall Structure (159×96 pixels)

```
┌─────────────────────────────────────────┐  0px
│ TOP BAR (12px height)                   │
├─────────────────────────────────────────┤  12px
│                                         │
│ PLAYER AREA (67px height)               │
│                                         │
│                                         │
├─────────────────────────────────────────┤  79px
│ SABOTEUR BAR (17px height)              │
└─────────────────────────────────────────┘  96px
 0px                                   159px
```

### Top Bar (0, 0, 159, 12)

**Background:** Black

**Elements (left to right):**

1. **Tempo Label** (2, 2)
   - Text: "MODERATO" / "ADAGIO" / "ALLEGRO"
   - Font: Press Start 2P, 6px
   - Color: White
   - Max width: 50px

2. **Power Icons** (55, 2)
   - Baton (top hat): 8×8px sprites
   - Spacing: 2px between hats
   - Partner (lightning): 8×8px sprite
   - Example: 🎩 (55,2) 🎩 (65,2) ⚡ (75,2)
   - Active color: White (baton), Orange (partner)
   - Used color: Gray

3. **Player Info** (100, 2)
   - Format: "P1: BUILDER 450"
   - Font: Press Start 2P, 6px
   - Player name color: Red or Purple
   - Role color: Orange
   - Score color: White
   - Right-aligned at x=157

### Player Area (0, 12, 159, 67)

**Background:** Black

**Melody Snake Grid:**
- **Total area:** 159×55px (leave 12px at bottom for sync meter)
- **Rows:** 6 rows
- **Row height:** 9px each (54px total)
- **Row spacing:** No gap between rows

**Snake Pattern:**
```
Row 1 (y=12):  Left→Right  [0, 12, 159, 9]
Row 2 (y=21):  Right→Left  [0, 21, 159, 9]
Row 3 (y=30):  Left→Right  [0, 30, 159, 9]
Row 4 (y=39):  Right→Left  [0, 39, 159, 9]
Row 5 (y=48):  Left→Right  [0, 48, 159, 9]
Row 6 (y=57):  Right→Left  [0, 57, 159, 9]
```

**Note Icons:**
- Size: 7×7px
- Spacing: 2px between notes (9px total width per note)
- ~17 notes fit per row (17 × 9 = 153px)
- Icon rendering: 2-letter code (Pi, Tr, Vn, etc.) or small sprite
- Font: Press Start 2P, 5px (for letters)
- Color: Instrument color (active) or Gray (broken)

**Metronome Pulse [●]:**
- Size: 7×7px filled circle
- Color: Orange
- Position: Next beat position in snake
- Glow effect: Scale up to 9×9px or increase brightness

**Connecting Lines:**
- 1px horizontal line between notes
- Color: Red (P1) or Purple (P2)
- Y position: Centered in row (y + 4)

**Sync Meter** (2, 68, 155, 8)
- Label: "SYNC:" at (2, 68)
- Bar: (25, 68, 130, 8)
- Filled blocks: White
- Empty blocks: Gray
- 10 blocks total, each 13px wide
- Critical state (<20%): pulse/flash white blocks

### Saboteur Bar (0, 79, 159, 17)

**Background:** Black
**Border:** 1px White line at top (y=79)

**Layout:**

1. **Saboteur Info** (2, 81)
   - Format: "PLAYER 2: 320"
   - Font: Press Start 2P, 6px
   - Player color: Red or Purple
   - Score color: White

2. **Divider** (80, 79, 1, 17)
   - Vertical line, White

3. **Sabotage Status** (85, 81)
   - Icons: 💥 📝 🗣️ (6×6px each)
   - Dots: •• (2×2px each, spaced 2px)
   - Layout: [💥]•• (5s) [📝]•• [🗣️]••
   - Icon spacing: 15px between groups
   - Active: Full color
   - Cooldown: Show timer in parentheses "(5s)"
   - Used: Gray

---

## 4. Tempo Selection Screen Layout

### Structure (159×96 pixels)

```
Title Area:        (0, 5, 159, 12)
Pie Wedge Area:    (0, 20, 159, 50)
Instructions:      (0, 72, 159, 8)
Start Prompt:      (0, 82, 159, 8)
Copyright:         (0, 90, 159, 6)
```

### Elements

**1. Title** (Center, y=5)
- Text: "DOWNBEAT!"
- Font: SF Intellivised, 10px
- Color: White
- Centered horizontally

**2. Subtitle** (Center, y=18)
- Text: "TEMPO SELECTION"
- Font: Press Start 2P, 6px
- Color: White
- Centered horizontally

**3. Pie Wedge Arc** (Center, y=30)

**Wedge Dimensions:**
- Total arc width: 120px
- Total arc height: 40px
- Center point: (79, 50)

**Three Wedges:**
- Left (Adagio): ~36px wide, color when selected: Green
- Center (Moderato): ~48px wide, color when selected: Orange (default)
- Right (Allegro): ~36px wide, color when selected: Red
- Unselected: Gray

**Labels on wedges:**
- Font: Press Start 2P, 5px
- Color: White (always)
- Adagio: "Adagio" at (25, 55), "80" at (30, 62)
- Moderato: "Mod." at (70, 45), "120" at (73, 52)
- Allegro: "Allegro" at (115, 55), "160" at (118, 62)

**4. Instructions** (Center, y=72)
- Text: "◄ Rotate disc to select tempo ►"
- Font: Press Start 2P, 5px
- Color: White
- Centered

**5. Start Prompt** (Center, y=82)
- Text: "Press any button to start"
- Font: Press Start 2P, 5px
- Color: White
- Centered

**6. Copyright** (Center, y=90)
- Text: "© Shaya Bendix Lyon"
- Font: Press Start 2P, 4px
- Color: Gray
- Centered

---

## 5. Turn Completion Screen

### Structure (159×96 pixels)

```
Player Name:       (5, 20)
Points:            (5, 32)
Best Streak:       (5, 46)
Instruments:       (5, 56)
```

**Background:** Black

**Elements:**

1. **Player Name** (5, 20)
   - Text: "PLAYER 1" or "PLAYER 2"
   - Font: Press Start 2P, 7px
   - Color: Red (P1) or Purple (P2)

2. **Points** (5, 32)
   - Text: "450 POINTS!"
   - Font: Press Start 2P, 8px
   - Color: Orange

3. **Best Streak** (5, 46)
   - Text: "BEST BEAT STREAK: 15"
   - Font: Press Start 2P, 5px
   - Color: White

4. **Instruments** (5, 56)
   - Text: "INSTRUMENTS: 6/8"
   - Font: Press Start 2P, 5px
   - Color: White (or Orange if 8/8)

---

## 6. Player Announcement Screen

### Structure (159×96 pixels)

```
Round:             (5, 20)
Player:            (5, 35)
Role:              (5, 50)
Prompt:            (5, 70)
```

**Background:** Black

**Elements:**

1. **Round** (5, 20)
   - Text: "ROUND 2"
   - Font: Press Start 2P, 6px
   - Color: White

2. **Player** (5, 35)
   - Text: "PLAYER TWO"
   - Font: Press Start 2P, 7px
   - Color: Red or Purple

3. **Role** (5, 50)
   - Text: "BUILDER" or "SABOTEUR"
   - Font: Press Start 2P, 7px
   - Color: Orange

4. **Prompt** (5, 70)
   - Text: "Press any button for downbeat"
   - Font: Press Start 2P, 5px
   - Color: White

---

## 7. Countdown Screen

**Background:** Main game screen (already loaded)

**Countdown Number:**
- Position: Center of player area (79, 40)
- Size: 24×24px
- Font: Press Start 2P, 24px (large!)
- Color: Orange
- Centered both horizontally and vertically
- Numbers: 4, 3, 2, 1
- No background box (sufficient contrast on black)

**Animation:**
Each number appears for one beat duration, then replaced by next number.

---

## 8. Round Comparison Screen

### Structure (159×96 pixels)

```
Header:            (Center, y=10)
P1 Label:          (20, 30)  P2 Label:          (90, 30)
P1 Score:          (20, 40)  P2 Score:          (90, 40)
Winner:            (Center, y=55)
Match Score:       (Center, y=70)
```

**Background:** Black

**Elements:**

1. **Header** (Centered, y=10)
   - Text: "ROUND 1 COMPLETE"
   - Font: Press Start 2P, 6px
   - Color: White

2. **Player 1** (20, 30)
   - Label: "PLAYER 1"
   - Score: "450 POINTS"
   - Font: Press Start 2P, 6px
   - Color: Red
   - Left-aligned at x=20

3. **Player 2** (90, 30)
   - Label: "PLAYER 2"
   - Score: "520 POINTS"
   - Font: Press Start 2P, 6px
   - Color: Purple
   - Left-aligned at x=90

4. **Winner** (Centered, y=55)
   - Text: "PLAYER 2 WINS ROUND!"
   - Font: Press Start 2P, 6px
   - Color: Winner's color (Red or Purple)

5. **Match Score** (Centered, y=70)
   - Text: "MATCH SCORE: P1: 0 P2: 1"
   - Font: Press Start 2P, 5px
   - Color: White

---

## 9. Match Winner Screen

### Structure (159×96 pixels)

```
Stars Top:         (Center, y=15)
Rehearsal:         (Center, y=28)
Winner:            (Center, y=40)
Score:             (Center, y=52)
Stars Bottom:      (Center, y=62)
Prompt:            (Center, y=80)
```

**Background:** Black

**Elements:**

1. **Stars Top** (Centered, y=15)
   - Text: "★★★★★★★★★★★★★★★"
   - Font: Press Start 2P, 6px
   - Color: Orange

2. **Rehearsal** (Centered, y=28)
   - Text: "REHEARSAL COMPLETE"
   - Font: Press Start 2P, 6px
   - Color: White

3. **Winner** (Centered, y=40)
   - Text: "PLAYER 2 WINS!"
   - Font: Press Start 2P, 7px
   - Color: Winner's color (Red or Purple)

4. **Score** (Centered, y=52)
   - Text: "2 - 1"
   - Font: Press Start 2P, 8px
   - Color: White

5. **Stars Bottom** (Centered, y=62)
   - Text: "★★★★★★★★★★★★★★★"
   - Font: Press Start 2P, 6px
   - Color: Orange

6. **Prompt** (Centered, y=80)
   - Text: "Press any button to play again"
   - Font: Press Start 2P, 5px
   - Color: White

---

## 10. Rendering Guidelines

### Text Rendering

**Font: Press Start 2P**
- Available sizes: 4px, 5px, 6px, 7px, 8px, 24px
- Always use pixel-perfect rendering (no anti-aliasing at native res)
- Letter spacing: Default (slightly tight)
- Line height: 1.2× font size

**Font: SF Intellivised**
- Only for "DOWNBEAT!" title
- Size: 10px
- Pixel-perfect rendering

### Sprite Rendering

**Power Icons (8×8px):**
- Top hat: White with black details (2px black band)
- Lightning bolt: Angular zig-zag shape, Orange
- Use sprite sheets for efficiency

**Sabotage Icons (6×6px):**
- 💥 SNEEZE: Starburst shape
- 📝 DROP PENCIL: Simple rectangle
- 🗣️ COUNT OUT LOUD: Speech bubble or sound waves
- Simplified for small size

**Note Icons (7×7px):**
- Either: Small instrument sprites
- Or: 2-letter codes in 5px font
- Both approaches valid

### Color Transitions

**Pulse Glow Animation:**
- Start: Normal Orange (#FF9F27)
- Peak: Bright Orange (increase brightness by 50%)
- End: Back to normal
- Duration: 500ms
- Easing: Ease-out

**Broken Phrase Transition:**
- From: Instrument color
- To: Gray (#A7A8A8)
- Duration: 200ms
- Easing: Linear

**Sync Meter Critical Flash:**
- Blink between White and Gray
- Period: 500ms (on for 250ms, off for 250ms)
- Only when <20%

### Performance Notes

**At 159×96 resolution:**
- Rendering should be extremely fast
- Use canvas or WebGL for pixel-perfect rendering
- Consider using a shader for retro CRT effect (optional)
- Target 60 FPS minimum

**Scaling for modern displays:**
- Use nearest-neighbor scaling (no smoothing)
- Maintain exact pixel aspect ratio
- Scale by integer multiples when possible (2x, 5x, 10x)

---

## 11. Coordinate Reference Tables

### Snake Row Positions

| Row | Y Start | Direction | Capacity |
|-----|---------|-----------|----------|
| 1   | 12      | L→R       | 17 notes |
| 2   | 21      | R→L       | 17 notes |
| 3   | 30      | L→R       | 17 notes |
| 4   | 39      | R→L       | 17 notes |
| 5   | 48      | L→R       | 17 notes |
| 6   | 57      | R→L       | 17 notes |

**Total capacity:** 102 notes (more than enough for 90 beats at Moderato)

### Note Position Calculation

```javascript
function getNotePosition(beatNumber) {
  const notesPerRow = 17;
  const rowIndex = Math.floor(beatNumber / notesPerRow);
  const posInRow = beatNumber % notesPerRow;
  
  const row = rowIndex % 6; // Wrap to 6 rows
  const y = 12 + (row * 9);
  
  // Alternate direction
  const isLeftToRight = (row % 2 === 0);
  const x = isLeftToRight 
    ? (posInRow * 9) + 1 
    : 159 - ((posInRow + 1) * 9);
  
  return { x, y, row };
}
```

### Common Element Positions

| Element | X | Y | Width | Height |
|---------|---|---|-------|--------|
| Top Bar | 0 | 0 | 159 | 12 |
| Player Area | 0 | 12 | 159 | 67 |
| Sync Meter | 25 | 68 | 130 | 8 |
| Saboteur Bar | 0 | 79 | 159 | 17 |
| Countdown Number | 67 | 28 | 24 | 24 |

---

## 12. Implementation Checklist

### Rendering System

- [ ] Set up canvas at 159×96 (or scaled equivalent)
- [ ] Load Press Start 2P font
- [ ] Load SF Intellivised font
- [ ] Create 16-color palette lookup
- [ ] Implement nearest-neighbor scaling
- [ ] Create sprite sheets for icons

### Gameplay Screen

- [ ] Render top bar with tempo, icons, player info
- [ ] Render snake grid (6 rows)
- [ ] Render note icons with correct colors
- [ ] Render connecting lines
- [ ] Render metronome pulse with glow
- [ ] Render sync meter with blocks
- [ ] Render saboteur bar with status

### Static Screens

- [ ] Render tempo selection with pie wedges
- [ ] Render turn completion screen
- [ ] Render player announcement screen
- [ ] Render countdown overlay
- [ ] Render round comparison screen
- [ ] Render match winner screen

### Animations

- [ ] Metronome pulse glow (500ms)
- [ ] Phrase break color transition (200ms)
- [ ] Sync meter critical flash (500ms cycle)
- [ ] Countdown number transitions

### Color Accuracy

- [ ] Verify all 16 Intellivision colors match
- [ ] Test color visibility on black background
- [ ] Verify player color distinction (Red vs Purple)
- [ ] Check instrument color uniqueness

---

**End of Screen Layout & Rendering Specification**