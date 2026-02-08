# Rhythm Engine Technical Specification
## DOWNBEAT! - Core Timing System

This document defines the exact technical requirements for implementing the rhythm/timing engine in DOWNBEAT!

---

## 1. Tempo System

### Tempo Values (BPM to Milliseconds)

The game supports three tempo settings:

| Tempo Name | BPM | Milliseconds per Beat | Beats in 45 seconds |
|------------|-----|----------------------|---------------------|
| Adagio     | 90  | 667ms                | 67 beats            |
| Moderato   | 110 | 545ms                | 82 beats            |
| Allegro    | 130 | 462ms                | 97 beats            |

**Calculation:**
```javascript
const millisecondsPerBeat = (60 / bpm) * 1000;
```

**Turn Duration:**
- Fixed at 45 seconds (45,000ms)
- Number of beats varies by tempo
- Turn ends after exactly 45 seconds OR when sync meter depletes to 0%

---

## 2. Timing Windows

### Hit Detection Thresholds

When a player presses an instrument button, measure the time delta between button press and the nearest beat.

**Timing Classifications:**

| Classification | Delta Range | Points Awarded | Sync Meter Effect |
|----------------|-------------|----------------|-------------------|
| **PERFECT**    | ±75ms       | 10 points      | +10%              |
| **GOOD**       | ±125ms      | 5 points       | +5%               |
| **MISS**       | >125ms      | 0 points       | -15%              |

**Important:**
- Treat early and late hits equally (±75ms means 75ms before OR after beat)
- A press at exactly the beat moment (0ms delta) = PERFECT
- Outside ±125ms = always a MISS

### Implementation Logic

```javascript
function classifyHit(buttonPressTime, nearestBeatTime) {
  const delta = Math.abs(buttonPressTime - nearestBeatTime);
  
  if (delta <= 75) return "PERFECT";   // ±75ms window
  if (delta <= 125) return "GOOD";     // ±125ms window
  return "MISS";                        // Outside window
}
```

---

## 3. Beat Clock System

### Core Beat Timer

The game must maintain a precise beat clock that:

1. **Starts** when countdown completes (after "1" fades, first gameplay beat begins)
2. **Ticks** at exact tempo intervals (750ms / 500ms / 375ms)
3. **Runs** for exactly 45 seconds
4. **Does not drift** over time (use absolute timing, not cumulative intervals)

### Recommended Implementation Pattern

Use `performance.now()` for high-precision timing:

```javascript
class BeatClock {
  constructor(bpm) {
    this.bpm = bpm;
    this.beatInterval = (60 / bpm) * 1000; // milliseconds per beat
    this.startTime = null;
    this.currentBeat = 0;
    this.isRunning = false;
  }
  
  start() {
    this.startTime = performance.now();
    this.isRunning = true;
    this.tick();
  }
  
  tick() {
    if (!this.isRunning) return;
    
    const now = performance.now();
    const elapsed = now - this.startTime;
    
    // Calculate which beat we should be on
    const expectedBeat = Math.floor(elapsed / this.beatInterval);
    
    // If we've reached a new beat
    if (expectedBeat > this.currentBeat) {
      this.currentBeat = expectedBeat;
      this.onBeat(this.currentBeat);
    }
    
    // Check if turn is over (45 seconds)
    if (elapsed >= 45000) {
      this.stop();
      return;
    }
    
    requestAnimationFrame(() => this.tick());
  }
  
  onBeat(beatNumber) {
    // Trigger beat event
    // - Play tick sound (if no instrument played)
    // - Pulse visual metronome
    // - Update UI
  }
  
  getCurrentBeatTime() {
    // Returns exact timestamp of current beat
    return this.startTime + (this.currentBeat * this.beatInterval);
  }
  
  getNextBeatTime() {
    // Returns exact timestamp of next beat
    return this.startTime + ((this.currentBeat + 1) * this.beatInterval);
  }
  
  stop() {
    this.isRunning = false;
    // Trigger turn end
  }
}
```

**Critical:**
- Use `performance.now()` not `Date.now()` (higher precision)
- Calculate expected beat from elapsed time (prevents drift)
- Don't use `setInterval` (can drift and be imprecise)

---

## 4. Input Timing

### Button Press Handling

When player presses any instrument button:

1. **Capture timestamp** immediately: `const pressTime = performance.now();`
2. **Find nearest beat:**
   - Compare to current beat time
   - Compare to next beat time
   - Use whichever is closer
3. **Calculate delta:** `Math.abs(pressTime - nearestBeatTime)`
4. **Classify hit:** PERFECT / GOOD / MISS
5. **Only accept hit if within GOOD window** (±125ms)

### Example Implementation

```javascript
function handleInstrumentPress(instrument) {
  const pressTime = performance.now();
  const currentBeatTime = beatClock.getCurrentBeatTime();
  const nextBeatTime = beatClock.getNextBeatTime();
  
  // Find nearest beat
  const deltaFromCurrent = Math.abs(pressTime - currentBeatTime);
  const deltaFromNext = Math.abs(pressTime - nextBeatTime);
  
  const nearestBeatTime = deltaFromCurrent < deltaFromNext 
    ? currentBeatTime 
    : nextBeatTime;
  
  const delta = Math.abs(pressTime - nearestBeatTime);
  
  // Classify hit
  let classification;
  if (delta <= 75) classification = "PERFECT";
  else if (delta <= 125) classification = "GOOD";
  else classification = "MISS";
  
  // Process result
  if (classification !== "MISS") {
    addNoteToMelody(instrument, classification);
    playInstrumentSound(instrument); // Replaces tick sound
    updateScore(classification);
    updateSyncMeter(classification);
    moveMetronomePulse(); // Move to next position
  } else {
    // Miss - no note added
    updateSyncMeter("MISS");
    // Tick sound still plays at beat
  }
}
```

**Important edge case:**
- If player presses button exactly between two beats, use the NEXT beat (break ties forward)
- This prevents "hitting too early for next beat but too late for current beat" confusion

---

## 5. Visual Metronome (Orange Pulse)

### Pulse Behavior

**Static Pulse with Glow Effect:**

The orange dot [●] functions as follows:

1. **Position:** Always sits at the NEXT beat position on the snake line
2. **At rest:** Orange circle at normal brightness
3. **On beat:** Pulses/glows brighter
4. **After player hit:** Moves to next position immediately

### Pulse Animation Timing

**Glow Animation:**
- **Trigger:** At exact beat moment
- **Duration:** 500ms (half a beat)
- **Effect:** Brightness increases then fades back to normal
- **Frequency:** Pulses twice per beat (once per beat hit, fades over half beat, next beat triggers again)

**Animation Curve:**
```javascript
// At beat moment
function triggerPulse() {
  const startTime = performance.now();
  const duration = 500; // ms
  
  function animate() {
    const elapsed = performance.now() - startTime;
    const progress = Math.min(elapsed / duration, 1.0);
    
    // Ease out: bright at start, fades to normal
    const brightness = 1.0 + (1.0 * (1 - progress)); // 2.0 -> 1.0
    
    updatePulseBrightness(brightness);
    
    if (progress < 1.0) {
      requestAnimationFrame(animate);
    }
  }
  
  animate();
}
```

### Pulse Movement

**When pulse moves to next position:**
- Immediately after player successfully hits (PERFECT or GOOD)
- OR at the beat moment if player didn't hit (auto-advance)

**Movement is instant** (no slide animation)

**Visual states:**
```javascript
// Pulse positions on snake
const pulsePositions = [
  {row: 1, index: 0},  // First beat
  {row: 1, index: 1},  // Second beat
  {row: 1, index: 2},  // etc...
  // ... continues through snake pattern
];

let currentPulseIndex = 0;

function movePulseToNext() {
  currentPulseIndex++;
  renderPulseAt(pulsePositions[currentPulseIndex]);
}
```

---

## 6. Audio System

### Metronome Tick

**Tick Sound:**
- Plays at every beat
- Simple, clear click/beep sound
- Gets REPLACED (not layered) when player hits instrument on beat

**Tick Timing:**
```javascript
function onBeat(beatNumber) {
  // Check if player hit an instrument this beat
  if (!instrumentWasPlayedThisBeat) {
    playTickSound();
  }
  // If instrument was played, its sound already replaced the tick
  
  triggerPulse(); // Visual pulse
}
```

### Instrument Sounds

**When instrument is played on beat:**
- Instrument sound plays at the exact moment player presses (responsive)
- Replaces the tick sound for that beat
- Sound should be short enough to not overlap with next beat's sound

**Sound Timing:**
```javascript
function playInstrumentSound(instrument) {
  // Play immediately when button pressed
  // Don't wait for beat - gives instant feedback
  audioContext.playSound(instrumentSounds[instrument]);
  
  // Mark that instrument was played this beat
  // (prevents tick from playing at next beat event)
  instrumentPlayedThisBeat = true;
}
```

**Reset flag:**
```javascript
function onBeat(beatNumber) {
  instrumentPlayedThisBeat = false; // Reset for new beat
  // ... rest of beat logic
}
```

---

## 7. Countdown Timing

### Countdown Behavior

The 4-beat countdown (4, 3, 2, 1) uses the SAME timing as gameplay:

**Countdown Beat Timing:**
- Each number appears for exactly one beat duration
- At selected tempo (750ms / 500ms / 375ms per number)
- Beat clock doesn't start yet (this is pre-game)

**Audio during countdown:**
- Intellivoice counts: "FOUR, THREE, TWO, ONE"
- Metronome tick plays with each number
- Both synchronized to tempo

**Implementation:**
```javascript
function startCountdown(tempo) {
  const beatDuration = (60 / tempo) * 1000;
  let count = 4;
  
  function countdown() {
    if (count > 0) {
      displayNumber(count);
      playVoice(numberToWord(count)); // "FOUR", "THREE", etc.
      playTickSound();
      count--;
      setTimeout(countdown, beatDuration);
    } else {
      // Countdown complete
      hideNumber();
      startGameplay(); // Start beat clock
    }
  }
  
  countdown();
}
```

**Transition to gameplay:**
- After "1" displays for one beat duration
- Number fades out
- Sync meter appears
- Beat clock starts
- First orange pulse [●] appears
- Game begins

---

## 8. Sync Meter Integration

### Sync Meter Updates

**Initial state:**
- Starts at 100% (full bar)

**Updates:**
- PERFECT hit: +10% (capped at 100%)
- GOOD hit: +5% (capped at 100%)
- MISS: -15%

**Critical state:**
- When below 20%: white blocks pulse/flash

**Depletion (0%):**
- Current phrase is lost
- 2-second "dazed" effect
- Sync meter resets to 50%
- Game continues

### Sync Meter Timing

**Update happens immediately** when hit is classified:
```javascript
function updateSyncMeter(classification) {
  if (classification === "PERFECT") {
    syncMeter = Math.min(syncMeter + 10, 100);
  } else if (classification === "GOOD") {
    syncMeter = Math.min(syncMeter + 5, 100);
  } else { // MISS
    syncMeter = Math.max(syncMeter - 15, 0);
  }
  
  if (syncMeter === 0) {
    handleSyncMeterDepletion();
  }
  
  renderSyncMeter();
}
```

---

## 9. Phrase System Integration

### Phrase Building

**Phrase = 3+ consecutive successful hits (PERFECT or GOOD)**

**Phrase state tracking:**
```javascript
let currentPhrase = [];
let completedPhrases = [];

function addNoteToMelody(instrument, classification) {
  const note = {
    instrument: instrument,
    quality: classification,
    timestamp: performance.now(),
    beatNumber: beatClock.currentBeat
  };
  
  currentPhrase.push(note);
  
  // Render note in snake
  renderNote(note);
  
  // Check if phrase is complete (3+ notes)
  if (currentPhrase.length >= 3) {
    // Phrase is active and scoring
    updatePhraseScore();
  }
}

function handleMiss() {
  if (currentPhrase.length > 0) {
    // Break phrase - turn notes gray
    currentPhrase.forEach(note => {
      setNoteColor(note, "gray");
    });
    
    // Move to completed (broken) phrases
    completedPhrases.push([...currentPhrase]);
    currentPhrase = [];
  }
}
```

---

## 10. Performance Considerations

### Timing Accuracy Requirements

**Target accuracy:**
- Beat timing precision: ±1ms
- No cumulative drift over 45 seconds
- Consistent frame rate (60 FPS preferred)

**Testing:**
- At end of 45-second turn, clock should be accurate within ±10ms
- Beat events should fire within ±2ms of expected time
- No noticeable audio/visual desync

### Optimization Notes

- Use `requestAnimationFrame` for visual updates
- Use `performance.now()` for all timing measurements
- Avoid blocking operations during beat events
- Pre-load all audio samples
- Render animations efficiently (CSS transforms, GPU acceleration)

---

## 11. Edge Cases

### Edge Case Handling

**Player presses multiple buttons simultaneously:**
- Only first press counts
- Subsequent presses ignored until next beat

**Player presses button during countdown:**
- Ignore all presses during countdown
- Only accept input after countdown completes

**Player presses button after turn ends:**
- Ignore all input
- Show turn completion screen

**Rapid button mashing:**
- Limit to one input per beat window
- Once a note is placed for a beat, that beat is "locked"

**Browser tab loses focus:**
- Pause game immediately
- Show "paused" screen
- Resume when tab regains focus (or restart turn)

---

## 12. Debug / Testing Tools

### Recommended Debug Features

For development and testing:

**Visual debug overlay:**
- Show current beat number
- Display time until next beat (ms)
- Show last button press delta
- Display sync meter percentage
- Show current phrase length

**Timing visualization:**
- Visual indicator showing PERFECT/GOOD/MISS windows
- Show where player's presses landed relative to beat

**Test mode:**
- Slow motion (50% tempo)
- Auto-play (perfect hits every beat)
- Show exact timing numbers on screen

**Console logging:**
```javascript
console.log(`Beat ${beatNumber}: 
  Expected: ${expectedTime}ms
  Actual: ${actualTime}ms
  Drift: ${actualTime - expectedTime}ms
`);
```

---

## 13. Summary Checklist

When implementing the rhythm engine, ensure:

- [ ] Tempo converts correctly to milliseconds
- [ ] Beat clock uses `performance.now()` and doesn't drift
- [ ] Timing windows are exactly ±75ms (PERFECT) and ±125ms (GOOD)
- [ ] Early and late hits treated equally
- [ ] Orange pulse sits at next beat, pulses over 500ms
- [ ] Tick sound plays unless replaced by instrument
- [ ] Countdown uses same tempo timing as gameplay
- [ ] Sync meter updates immediately on hit classification
- [ ] Phrases track correctly (3+ consecutive successful hits)
- [ ] Turn ends at exactly 45 seconds
- [ ] No timing drift over full turn duration
- [ ] Edge cases handled (multi-press, tab focus, etc.)

---

## Implementation Priority

**Phase 1: Core Beat Clock**
1. Implement BeatClock class with precise timing
2. Test for drift over 45 seconds
3. Verify beat events fire accurately

**Phase 2: Input Detection**
4. Implement button press timing capture
5. Implement hit classification logic
6. Test timing windows (±75ms, ±125ms)

**Phase 3: Visual Feedback**
7. Implement orange pulse positioning
8. Implement pulse glow animation (500ms)
9. Test pulse movement

**Phase 4: Audio Integration**
10. Implement tick sound system
11. Implement instrument sound playback
12. Test tick replacement logic

**Phase 5: Integration**
13. Connect to sync meter
14. Connect to phrase system
15. Full gameplay testing

---

**End of Rhythm Engine Technical Specification**