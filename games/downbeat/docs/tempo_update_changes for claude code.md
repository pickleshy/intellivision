# Tempo Update - Implementation Changes
## DOWNBEAT! - Revised Tempo Values

**Date:** Based on playtesting feedback  
**Reason:** Original tempos were too fast for strategic gameplay

---

## Summary of Changes

The three tempo settings have been adjusted to allow players more time for strategic decision-making while maintaining challenge.

### Old Values ❌

| Tempo    | BPM | Milliseconds/Beat | Frames/Beat (60fps) |
|----------|-----|-------------------|---------------------|
| Adagio   | 80  | 750ms             | 45 frames           |
| Moderato | 120 | 500ms             | 30 frames           |
| Allegro  | 160 | 375ms             | 22 frames           |

### New Values ✅

| Tempo    | BPM | Milliseconds/Beat | Frames/Beat (60fps) | Beats in 45 sec |
|----------|-----|-------------------|---------------------|-----------------|
| Adagio   | 90  | 667ms             | 40 frames           | 67 beats        |
| Moderato | 110 | 545ms             | 33 frames           | 82 beats        |
| Allegro  | 130 | 462ms             | 28 frames           | 97 beats        |

---

## What Needs to Change in Your Code

### 1. Tempo Constant Definitions

**Find and replace these values:**

```basic
REM OLD - Remove these
CONST ADAGIO_BPM = 80
CONST MODERATO_BPM = 120
CONST ALLEGRO_BPM = 160

REM NEW - Use these instead
CONST ADAGIO_BPM = 90
CONST MODERATO_BPM = 110
CONST ALLEGRO_BPM = 130
```

### 2. Milliseconds per Beat Calculations

**Update these calculated values:**

```basic
REM OLD
REM Adagio: 750ms, Moderato: 500ms, Allegro: 375ms

REM NEW
REM Adagio: 667ms, Moderato: 545ms, Allegro: 462ms
```

**If you have millisecond constants:**

```basic
REM OLD - Remove
CONST ADAGIO_MS = 750
CONST MODERATO_MS = 500
CONST ALLEGRO_MS = 375

REM NEW - Replace with
CONST ADAGIO_MS = 667
CONST MODERATO_MS = 545
CONST ALLEGRO_MS = 462
```

### 3. Frame-Based Timing (IntyBASIC at 60 FPS)

**Update frames per beat:**

```basic
REM OLD tempo initialization
SELECT CASE tempo
    CASE 0: frames_per_beat = 45    REM Adagio (750ms)
    CASE 1: frames_per_beat = 30    REM Moderato (500ms)
    CASE 2: frames_per_beat = 22    REM Allegro (375ms)
END SELECT

REM NEW tempo initialization
SELECT CASE tempo
    CASE 0: frames_per_beat = 40    REM Adagio (667ms)
    CASE 1: frames_per_beat = 33    REM Moderato (545ms)
    CASE 2: frames_per_beat = 28    REM Allegro (462ms)
END SELECT
```

### 4. UI Display Text

**Update tempo selection screen labels:**

```basic
REM Adagio wedge
REM OLD: Display "80"
REM NEW: Display "90"

REM Moderato wedge
REM OLD: Display "120"
REM NEW: Display "110"

REM Allegro wedge
REM OLD: Display "160"
REM NEW: Display "130"
```

**Screen coordinates for numbers (if hardcoded):**
- Adagio "90" at pixel position (30, 62)
- Moderato "110" at pixel position (73, 52)
- Allegro "130" at pixel position (118, 62)

### 5. Beat Count in 45 Seconds

**Update these if you're tracking total beats per turn:**

```basic
REM OLD expected beats in 45-second turn
REM Adagio: 60, Moderato: 90, Allegro: 108

REM NEW expected beats in 45-second turn
REM Adagio: 67, Moderato: 82, Allegro: 97
```

**If you have array sizing based on beat count:**

```basic
REM OLD - might need 108 beat capacity
DIM note_data(108)

REM NEW - can optimize to 97 beat capacity
DIM note_data(97)
```

---

## Files That Need Updates

Based on typical game structure, check these areas:

### Core Game Files
- [ ] **Constants/Config file** - BPM values, milliseconds, frame counts
- [ ] **Beat clock/timing system** - Frame-per-beat calculations
- [ ] **Tempo selection screen** - Display text (90, 110, 130)
- [ ] **Game initialization** - Tempo setup logic

### Audio Files  
- [ ] **Countdown timing** - Uses same tempo for 4,3,2,1 count
- [ ] **Music timing** - If you have tempo-synced music

### Testing/Debug Files
- [ ] **Test cases** - Any hardcoded tempo values in tests
- [ ] **Debug display** - If showing BPM values

---

## Quick Verification Checklist

After making changes, verify:

- [ ] Adagio feels comfortable and beginner-friendly (~1.5 beats/sec)
- [ ] Moderato is the default and feels engaging (~1.8 beats/sec)
- [ ] Allegro is challenging but not panic-inducing (~2.2 beats/sec)
- [ ] Players have time to use helper powers (maestro, baton, partner)
- [ ] Countdown uses correct tempo timing
- [ ] Tempo labels show 90, 110, 130 (not 80, 120, 160)
- [ ] Beat timing feels accurate at all three speeds
- [ ] 45-second turn duration still works correctly

---

## Why These Specific Values?

**90 BPM (Adagio):**
- Familiar groove (think "Billie Jean" by Michael Jackson)
- 667ms between beats = plenty of decision time
- Beginner-friendly

**110 BPM (Moderato):**
- Sweet spot for rhythm games
- 545ms = enough time to think but still engaging
- Not too fast, not too slow

**130 BPM (Allegro):**
- Challenging but achievable
- 462ms = requires good timing but allows strategic play
- Much more reasonable than 160 BPM (which was too fast)

**Benefits:**
- Better pacing for 9-button instrument selection
- Time to monitor sabotage and use helper powers
- More accessible to casual players
- Still challenging at highest difficulty

---

## Testing Recommendations

1. **Play each tempo for a full 45-second turn**
2. **Try using helper powers at each speed** - should feel natural, not frantic
3. **Test with sabotage active** - should be challenging but fair
4. **Get feedback from playtesters** - especially on Allegro difficulty

If Allegro still feels too fast/slow, consider:
- Too fast? Try 120 BPM (500ms/beat, 30 frames)
- Too slow? Try 140 BPM (429ms/beat, 26 frames)

---

**End of Implementation Changes**

*All three main specification documents (Design Doc, Rhythm Engine Spec, Audio Spec) have been updated with these new values.*