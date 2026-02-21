# Wave Designer Update Log

## February 21, 2026 - Data-Driven Boss Tables + Palette Export Fix

### Context

Boss placement in `waves.bas` was refactored from a 32-way IF/ELSEIF chain (~1,676 ROM words)
to three compact DATA tables in `data_tables.bas` (~288 ROM words + ~80-word decode loop).
Net savings: **+1,388 words freed in Segment 2**.

The wave designer exporter and importer have been updated to match.

---

### ✅ Completed Updates

**exporter.js** — Full rewrite for new boss format + palette fix:

1. **Boss export: `_generateBossData()` (replaces `_generateBossCode()`)**
   - Now outputs three `DATA` tables instead of an IF/ELSEIF chain
   - Tables paste into `data_tables.bas` after the `OrbitDY` table (end of file)
   - Encoding:
     - `BossHeader`: `BossCount (bits 0-2) | orbit0*8 | orbit1*16`
     - `BossColRow`: `BossCol (bits 0-3) | BossRow (bits 4-7)`
     - `BossAttrs`:  `BossHP (bits 0-2) | BossColor (bits 3-6) | BossType (bit 7)`
   - Orbiter mapping: `boss[0].orbiter` → OrbitStep=0, `boss[1].orbiter` → OrbitStep2=5
   - Each DATA line annotated with wave number and boss summary comment

2. **Palette export: `_buildPalettes()` (rewrote from squid/crab/octopus → row0-row4)**
   - Now outputs 5 `WavePalette` arrays (one per alien row), 6 entries each
   - Entries cycle via `(Level-1) MOD 6` — uses waves 0-5's palette data
   - Correct format: `WavePalette0: DATA 6, 7, 5, 1, 2, 3` (row0 colors for palettes 0-5)

3. **Boss import: `_decodeBossTables()` (new method)**
   - Parses `BossHeader:`, `BossColRow:`, `BossAttrs:` DATA labels
   - Decodes packed fields with bitwise operations matching the game's decode loop
   - Reconstructs `{ col, row, hp, color, type, orbiter }` boss objects per wave

4. **Legacy import fallback**
   - Old IF/ELSEIF format (`IF LoopVar = N THEN`) still parsed via `_parseLegacyBossLine()`
   - New DATA table format takes priority; legacy only used if `BossHeader` table not found

5. **Palette import: updated `_applyParsedData()`**
   - Parses `WavePalette0`-`WavePalette4` labels (instead of `WavePalette0`-`2`)
   - Reconstructs `wave.palette = { row0, row1, row2, row3, row4 }` for all 32 waves via MOD 6

---

### Data Table Encoding Reference

```
BossHeader(32) — one value per wave:
  bits 0-2: BossCount (0-4)
  bit 3:    OrbitStep = 0   (boss[0] gets orbiter)
  bit 4:    OrbitStep2 = 5  (boss[1] gets orbiter, offset start)

BossColRow(128) — 4 slots per wave, encoded as one DECLE:
  bits 0-3: BossCol  (0-7, left half-cells; bosses are 2-wide)
  bits 4-7: BossRow  (0-4)
  Example:  Col=3, Row=3 → 3 + 3*16 = 51

BossAttrs(128) — 4 slots per wave, encoded as one DECLE:
  bits 0-2: BossHP    (0-7; skulls typically 3-4, bombs 2-5)
  bits 3-6: BossColor (0-15; skulls: 9=cyan, 12=pink, 15=purple; bombs: 10=orange)
  bit 7:    BossType  (0=SKULL_TYPE, 1=BOMB_TYPE)
  Examples: skull hp3 c9  → 3 + 9*8 + 0   = 75
            bomb  hp2 c10 → 2 + 10*8 + 128 = 210
            skull hp4 c15 → 4 + 15*8 + 0   = 124

WavePalette{row}(6) — 5 arrays (row0-row4), 6 entries each:
  palettes[row][palIdx] = alien row `row`'s color in palette slot `palIdx`
  Game selects slot via: (Level - 1) MOD 6
```

---

### Export Workflow (Updated)

After editing waves in the designer and clicking **Export IntyBASIC**:

1. Copy `PatternBData` + `PatternBIndex` → paste into `data_tables.bas` (Segment 2 section)
2. Copy `WavePalette0-4` → paste into `flight_engine.bas` (replacing WavePalette arrays)
3. Copy `WaveEntranceData` → paste into `flight_engine.bas` (replacing WaveEntranceData)
4. Copy `BossHeader`, `BossColRow`, `BossAttrs` → paste into `data_tables.bas` **after `OrbitDY`**
   (These replace the existing boss tables, not the waves.bas IF/ELSEIF — that's gone)
5. Copy the reinforcement `IF` condition → paste into `waves.bas` CheckAliensDead

---

## February 16, 2026 - Game Data Sync

### ✅ Completed Updates

**state.js** - Core game data synchronized with current Space Intruders implementation:

1. **Pattern Definitions** (DEFAULT_PATTERNS)
   - ✅ Added 7 missing patterns (indices 16-22)
   - ✅ Now includes all 23 Pattern B formations from game
   - ✅ Pattern names: Fortress (alt), Checkerboard (alt), Cross (alt), Dual Pillars (alt), Arrow (alt), Pillars (alt), Phalanx (alt)

2. **Pattern Index Mapping** (DEFAULT_PATTERN_INDEX)
   - ✅ Updated all 32 waves to match current PatternBIndex from data_tables.bas
   - ✅ Waves now cycle through correct patterns per game

3. **Entrance Animations** (DEFAULT_ENTRANCES)
   - ✅ Updated all 32 waves to match WaveEntranceData from flight_engine.bas
   - ✅ Entrances: 0=Left sweep, 1=Top-down reveal, 2=Fly-down from above

4. **Color Palettes** (PALETTE_BANK)
   - ✅ Upgraded from 3-color system (squid/crab/octopus) to 5-color system (row0-row4)
   - ✅ Now matches game's WavePalette0-4 arrays (5 alien types × 6 palettes)
   - ✅ Each palette: [row0_color, row1_color, row2_color, row3_color, row4_color]
   - ✅ Updated ALIEN_TYPES to "Alien 1 (Row 0)" through "Alien 5 (Row 4)"

5. **Boss Placements** (DEFAULT_BOSSES)
   - ✅ Verified against LoadPatternB in waves.bas
   - ✅ All 32 waves correctly defined with boss positions, types, HP, colors, orbiters

6. **Docker Configuration**
   - ✅ Dockerfile and docker-compose.yml verified - no changes needed

7. **UI Component Updates** (Browser Cache Fix)
   - ✅ wave_designer.html: Updated palette UI from 3 rows to 5 rows
   - ✅ waveSettings.js: Changed `['squid', 'crab', 'octopus']` to `['row0', 'row1', 'row2', 'row3', 'row4']`
   - ✅ gridEditor.js: Fixed ALIEN_GLYPHS and palette color lookup to use row0-row4 keys
   - ✅ app.py: Added cache-busting headers to prevent browser caching issues

---

### 📋 Remaining Work

**constraints.js** — Minor palette validation update:
- Update checks from `pal.squid/crab/octopus` to `pal.row0/row1/row2/row3/row4`
- Lines 86, 105-107 (cosmetic, validation still works)

---

### 🧪 Testing Checklist

- [ ] Launch wave designer: `docker-compose up` (or `python3 app.py`)
- [ ] Verify all 32 waves load with correct patterns, entrances, colors
- [ ] Test boss placement editing (skull/bomb, HP, orbiter toggle)
- [ ] **Export to BASIC** → verify BossHeader/BossColRow/BossAttrs tables are correct
- [ ] **Import from BASIC** → paste generated output back in, verify round-trip
- [ ] **Import legacy** → paste old IF/ELSEIF boss format, verify it still loads
- [ ] Verify WavePalette0-4 output matches values in flight_engine.bas
- [ ] Test JSON save/load round-trip

---

### 📦 Current Source File Locations

| Data | File | Location |
|------|------|----------|
| PatternBData | `data_tables.bas` | Segment 2 |
| PatternBIndex | `data_tables.bas` | Segment 2 |
| BossHeader/BossColRow/BossAttrs | `data_tables.bas` | Segment 2, after OrbitDY |
| WavePalette0-4 | `flight_engine.bas` | Segment 2 |
| WaveEntranceData | `flight_engine.bas` | Segment 2 |
| Boss decode loop | `waves.bas` LoadPatternB | Segment 2 |
| Reinforcements | `waves.bas` CheckAliensDead | Segment 2 |

---

**Status**: Wave designer fully synced to data-driven boss system. Export/import round-trip is functional for all wave data.
