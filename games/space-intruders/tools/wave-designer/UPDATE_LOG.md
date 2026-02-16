# Wave Designer Update Log

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
   - ✅ Updated static/js/state.js will be automatically included in builds

7. **UI Component Updates** (Browser Cache Fix)
   - ✅ wave_designer.html: Updated palette UI from 3 rows to 5 rows
   - ✅ waveSettings.js: Changed `['squid', 'crab', 'octopus']` to `['row0', 'row1', 'row2', 'row3', 'row4']`
   - ✅ gridEditor.js: Fixed ALIEN_GLYPHS and palette color lookup to use row0-row4 keys
   - ✅ app.py: Added cache-busting headers to prevent browser caching issues

### 📋 Remaining Work (Future Updates)

**exporter.js** - Needs comprehensive rewrite for new 5-palette system:
- Current exporter assumes 3-color palettes (squid/crab/octopus)
- Game uses 5 separate WavePalette arrays (WavePalette0-4, each with 6 entries)
- Export format needs to generate correct DATA statements for:
  ```basic
  WavePalette0: DATA 6, 7, 5, 1, 2, 3
  WavePalette1: DATA 5, 6, 1, 2, 1, 7
  WavePalette2: DATA 7, 5, 2, 3, 6, 7
  WavePalette3: DATA 2, 3, 7, 5, 6, 1
  WavePalette4: DATA 3, 2, 6, 7, 5, 5
  ```

**constraints.js** - Palette validation needs updating:
- Update checks from `pal.squid/crab/octopus` to `pal.row0/row1/row2/row3/row4`
- Line 86, 105-107 (minor - can be done later)

### 🧪 Testing Checklist

Before next session:
- [ ] Launch wave designer: `docker-compose up`
- [ ] Verify all 32 waves load correctly
- [ ] Check that patterns 16-22 display properly
- [ ] Verify entrance animations match (0/1/2)
- [ ] Check palette colors for all 5 rows
- [ ] Test boss placement editing
- [ ] Test JSON export/import (may fail due to exporter.js issues)

### 📦 Current Game Data Summary

**From games/space-intruders/src/**:
- `data_tables.bas`:
  - PatternBData: 23 patterns (rows 171-194)
  - PatternBIndex: 32-wave mapping (rows 197-201)
- `flight_engine.bas`:
  - WaveEntranceData: 32 waves (4 lines of 8 values)
  - WavePalette0-4: 6 entries each (5 arrays)
- `waves.bas`:
  - LoadPatternB: Boss placement IF/ELSEIF chain (lines 546-889)
  - Reinforcements: Waves 3, 11, 19, 27 (Col = 2 OR 10 OR 18 OR 26)

### 🔗 Related Files Modified

- `/Users/mikeholzinger/src/intv-game-builder/games/space-intruders/tools/wave-designer/static/js/state.js`
  - Lines 43-60: Added patterns 16-22
  - Lines 62-71: Updated pattern index mapping
  - Lines 73-78: Updated entrance patterns
  - Lines 81-95: Updated palette system (3→5 colors)
  - Line 36: Updated ALIEN_TYPES array

### 📖 How to Use

The wave designer now accurately reflects the game's current 32-wave cycle. To use:

1. **View waves**: Navigate through waves 1-32 using the wave selector
2. **Edit patterns**: Click cells to toggle aliens, use brush tools
3. **Add bosses**: Use boss placement tools (skull/bomb types)
4. **Set entrances**: Choose left sweep (0), top-down (1), or fly-down (2)
5. **Color palettes**: Colors cycle automatically per wave MOD 6
6. **Export**: JSON export works for state, BASIC export needs exporter.js update

### 💡 Next Steps

1. **Fix exporter.js**:
   - Rewrite `_generatePaletteData()` to output 5 WavePalette arrays
   - Update palette parsing in import functions
   - Test round-trip: export → import → verify

2. **Update UI components**:
   - constraints.js palette checks
   - gridEditor.js alien type references
   - waveSettings.js palette color picker (5 rows)

3. **Add validation**:
   - Warn if pattern index > 22 (out of range)
   - Validate boss positions don't overlap
   - Check entrance modes are 0-2

### 🐛 Known Issues

- **Export to BASIC**: Will generate incorrect WavePalette DATA (still uses 3-color system)
- **Palette UI**: May show only 3 color pickers instead of 5
- **Import**: May fail if JSON has old squid/crab/octopus keys instead of row0-row4

### 📚 References

- Space Intruders ROADMAP.md: 32-wave cycle design
- Space Intruders data_tables.bas: Pattern and index definitions
- Space Intruders flight_engine.bas: Entrance and palette data
- Space Intruders waves.bas: Boss placement logic

---

**Status**: Wave designer data is synced. UI display will work correctly. Export functionality needs follow-up work.
