# Audio Specification - IntyBASIC
## DOWNBEAT! - Sound System for Real Intellivision Hardware

This document defines the audio implementation for DOWNBEAT! using IntyBASIC and the Intellivision's PSG (Programmable Sound Generator) and Intellivoice module.

---

## 1. Intellivision Sound Hardware Overview

### AY-3-8914 PSG (Programmable Sound Generator)

**Capabilities:**
- **3 independent sound channels** (A, B, C)
- **Frequency range:** ~30 Hz to ~125,000 Hz (practical range ~100-4000 Hz)
- **Volume control:** 16 levels (0-15) per channel
- **Envelope control:** Basic ADSR capability
- **Noise generator:** White noise for percussion effects

**Limitations:**
- Square wave only (no sine, triangle, or sawtooth)
- No wavetable synthesis
- Limited polyphony (3 notes maximum)
- No pitch bending during note
- Relatively short envelope times

### Intellivoice Speech Synthesizer

**Capabilities:**
- Pre-recorded speech samples (phoneme-based)
- Clear, robotic voice quality
- Can speak while game plays
- Independent from PSG channels

**Limitations:**
- Samples must be pre-encoded
- Limited sample ROM space
- Speech blocks other audio briefly during playback
- Phoneme synthesis (not waveform samples)

---

## 2. Sound Channel Allocation Strategy

### Channel Assignment

For DOWNBEAT!, allocate the 3 PSG channels as follows:

**Channel A (Primary Melody):**
- Instrument notes when player hits beat
- Highest priority
- Most frequently used

**Channel B (Secondary/Harmony):**
- Metronome tick sounds
- Sabotage sound effects (brief)
- Secondary priority

**Channel C (Bass/Percussion):**
- Timpani (low percussion notes)
- Bass instruments (Bassoon, low notes)
- Sound effects that don't conflict with melody

**Intellivoice (Independent):**
- Countdown: "FOUR", "THREE", "TWO", "ONE"
- Player announcements: "PLAYER ONE", "PLAYER TWO"
- Victory: "BRAVO!", "PLAYER ONE WINS", etc.
- Sabotage: "ACHOO!" (sneeze)

---

## 3. Instrument Sound Definitions

### IntyBASIC Sound Format

IntyBASIC uses `SOUND` command with parameters:
```basic
SOUND channel, frequency, volume
```

Where:
- `channel`: 0-2 (channels A, B, C) or 3-5 (with noise), 6 (noise only)
- `frequency`: 0-4095 (higher = higher pitch)
- `volume`: 0-15 (0 = silent, 15 = loudest)

**Frequency Calculation:**
```
frequency = 3579545 / (32 * desired_Hz)
```

### Instrument Definitions (as IntyBASIC constants)

```basic
REM Instrument Frequency Definitions (approximate Hz -> PSG values)

REM High Register
CONST PICCOLO_FREQ = 35      REM ~3000 Hz (very high)
CONST TRUMPET_FREQ = 70      REM ~1500 Hz (high brass)
CONST VIOLIN_FREQ = 90       REM ~1200 Hz (mid-high strings)

REM Mid Register  
CONST OBOE_FREQ = 140        REM ~800 Hz (mid woodwind)
CONST VIOLA_FREQ = 190       REM ~600 Hz (mid strings)
CONST TROMBONE_FREQ = 250    REM ~450 Hz (mid-low brass)

REM Low Register
CONST BASSOON_FREQ = 350     REM ~320 Hz (low woodwind)
CONST TIMPANI_FREQ = 700     REM ~160 Hz (very low percussion)

REM Metronome
CONST TICK_FREQ = 400        REM ~280 Hz (clear click)

REM Note: These are base frequencies. Actual musical notes would
REM need to be calculated from standard pitch (A440) for melody
```

### Instrument Envelopes (Attack/Decay timing)

Each instrument has characteristic attack and decay:

```basic
REM ============================================
REM PICCOLO - Quick attack, steady sustain
REM ============================================
PROCEDURE PLAY_PICCOLO
    SOUND 0, PICCOLO_FREQ, 15     REM Full volume immediately
    WAIT                           REM Hold for ~1/60 sec
    SOUND 0, PICCOLO_FREQ, 14     REM Sustain at high volume
    REM Continue for duration, then release
END

REM ============================================
REM TRUMPET - Sharp attack, bold sustain
REM ============================================
PROCEDURE PLAY_TRUMPET
    SOUND 0, TRUMPET_FREQ, 15     REM Sharp attack
    WAIT
    SOUND 0, TRUMPET_FREQ, 14     REM Strong sustain
    WAIT
    SOUND 0, TRUMPET_FREQ, 13     REM Gradual decay
END

REM ============================================
REM VIOLIN - Soft attack, smooth sustain
REM ============================================
PROCEDURE PLAY_VIOLIN
    SOUND 0, VIOLIN_FREQ, 8       REM Soft start (bow attack)
    WAIT
    SOUND 0, VIOLIN_FREQ, 12      REM Build to sustain
    WAIT
    SOUND 0, VIOLIN_FREQ, 14      REM Full sustain
    REM Hold at 14 for duration
END

REM ============================================
REM OBOE - Medium attack, buzzy character
REM ============================================
PROCEDURE PLAY_OBOE
    SOUND 0, OBOE_FREQ, 12        REM Medium attack
    WAIT
    SOUND 0, OBOE_FREQ, 14        REM Full sustain
    REM Can add slight frequency wobble for reed effect
END

REM ============================================
REM VIOLA - Soft attack, warm sustain
REM ============================================
PROCEDURE PLAY_VIOLA
    SOUND 0, VIOLA_FREQ, 7        REM Soft bow start
    WAIT
    SOUND 0, VIOLA_FREQ, 11       REM Build up
    WAIT
    SOUND 0, VIOLA_FREQ, 13       REM Warm sustain
END

REM ============================================
REM TROMBONE - Smooth attack, brassy sustain
REM ============================================
PROCEDURE PLAY_TROMBONE
    SOUND 0, TROMBONE_FREQ, 11    REM Smooth but bold
    WAIT
    SOUND 0, TROMBONE_FREQ, 14    REM Full brass
END

REM ============================================
REM BASSOON - Soft attack, deep sustain
REM ============================================
PROCEDURE PLAY_BASSOON
    SOUND 2, BASSOON_FREQ, 9      REM Channel C (bass)
    WAIT
    SOUND 2, BASSOON_FREQ, 12     REM Deep sustain
END

REM ============================================
REM TIMPANI - Sharp attack, booming decay
REM ============================================
PROCEDURE PLAY_TIMPANI
    REM Use noise channel for percussive attack
    SOUND 6, 0, 15                REM Noise burst (attack)
    SOUND 2, TIMPANI_FREQ, 15     REM Low tone (boom)
    WAIT
    SOUND 6, 0, 0                 REM Cut noise
    SOUND 2, TIMPANI_FREQ, 12     REM Decay
    WAIT
    SOUND 2, TIMPANI_FREQ, 8      REM Continue decay
    WAIT
    SOUND 2, TIMPANI_FREQ, 4      REM Fade out
    WAIT
    SOUND 2, TIMPANI_FREQ, 0      REM Silence
END

REM ============================================
REM REST - Complete silence
REM ============================================
PROCEDURE PLAY_REST
    REM Optional: very quiet tick for feedback
    SOUND 1, TICK_FREQ, 2         REM Barely audible
    WAIT
    SOUND 1, TICK_FREQ, 0         REM Silence
END
```

### Note Duration Control

For rhythm game, notes should be SHORT (one beat or less):

```basic
REM Duration in frames (60 FPS)
CONST NOTE_SHORT = 15      REM 0.25 seconds (1/4 beat at 120 BPM)
CONST NOTE_MEDIUM = 25     REM 0.42 seconds 
CONST NOTE_LONG = 30       REM 0.5 seconds (one beat at 120 BPM)

REM Example: Play instrument for specific duration
PROCEDURE PLAY_NOTE(instrument, duration)
    DIM frames
    
    SELECT CASE instrument
        CASE 0: REM Piccolo
            FOR frames = 0 TO duration
                SOUND 0, PICCOLO_FREQ, 14
                WAIT
            NEXT frames
            SOUND 0, 0, 0  REM Stop
            
        CASE 1: REM Trumpet
            FOR frames = 0 TO duration
                SOUND 0, TRUMPET_FREQ, 14
                WAIT
            NEXT frames
            SOUND 0, 0, 0
            
        REM ... continue for other instruments
    END SELECT
END
```

---

## 4. Metronome Tick Sound

### Simple Click

```basic
REM ============================================
REM METRONOME TICK - Clear, short click
REM ============================================
PROCEDURE PLAY_TICK
    SOUND 1, TICK_FREQ, 12        REM Channel B, medium volume
    WAIT
    WAIT                           REM Hold briefly (2 frames = 33ms)
    SOUND 1, TICK_FREQ, 0         REM Cut immediately
END
```

### Alternative: Pitched Tick

For musical feel, tick can be pitched:

```basic
PROCEDURE PLAY_TICK_PITCHED
    REM Higher pitch = more noticeable
    SOUND 1, 200, 15              REM ~560 Hz, loud
    WAIT
    SOUND 1, 200, 8               REM Quick decay
    WAIT
    SOUND 1, 200, 0               REM Cut
END
```

---

## 5. Sabotage Sound Effects

### SNEEZE - Combined with Intellivoice

```basic
REM Sound effect plays while "ACHOO!" voice plays
PROCEDURE PLAY_SNEEZE
    REM Trigger voice (see Intellivoice section)
    PLAY VOICE ACHOO
    
    REM Add brief noise burst for effect
    SOUND 6, 0, 12                REM Noise channel
    FOR i = 0 TO 10
        WAIT
    NEXT i
    SOUND 6, 0, 0                 REM Cut noise
END
```

### DROP PENCIL - Clatter Sound

```basic
REM Bouncing pencil clatter
PROCEDURE PLAY_DROP_PENCIL
    REM Initial impact (high)
    SOUND 1, 100, 12
    FOR i = 0 TO 3: WAIT: NEXT i
    
    REM First bounce (lower)
    SOUND 1, 150, 10
    FOR i = 0 TO 2: WAIT: NEXT i
    
    REM Second bounce (even lower)
    SOUND 1, 200, 8
    FOR i = 0 TO 2: WAIT: NEXT i
    
    REM Final settle
    SOUND 1, 250, 5
    FOR i = 0 TO 2: WAIT: NEXT i
    
    SOUND 1, 0, 0                 REM Silence
END
```

### COUNT OUT LOUD - Intellivoice Only

```basic
REM This is pure Intellivoice, no PSG sound needed
PROCEDURE PLAY_COUNT_OUT_LOUD
    PLAY VOICE ONE
    REM Wait for speech to complete (timing varies)
    FOR i = 0 TO 20: WAIT: NEXT i
    
    PLAY VOICE TWO
    FOR i = 0 TO 20: WAIT: NEXT i
    
    PLAY VOICE THREE
    FOR i = 0 TO 20: WAIT: NEXT i
    
    PLAY VOICE FOUR
    FOR i = 0 TO 20: WAIT: NEXT i
END
```

---

## 6. Intellivoice Implementation

### Speech Sample Definitions

IntyBASIC uses `VOICE` statements to define speech:

```basic
REM Define voice samples (in separate voice data section)
VOICE_DATA ACHOO
    REM Phoneme data for "ACHOO!" would go here
    REM This requires IntyBASIC voice compiler
END

VOICE_DATA ONE
    REM Phonemes for "ONE"
END

VOICE_DATA TWO
    REM Phonemes for "TWO"
END

VOICE_DATA THREE
    REM Phonemes for "THREE"
END

VOICE_DATA FOUR
    REM Phonemes for "FOUR"
END

VOICE_DATA PLAYER_ONE
    REM Phonemes for "PLAYER ONE"
END

VOICE_DATA PLAYER_TWO
    REM Phonemes for "PLAYER TWO"
END

VOICE_DATA BRAVO
    REM Phonemes for "BRAVO!"
END

VOICE_DATA WINS
    REM Phonemes for "WINS"
END
```

### Playing Voice Samples

```basic
REM Play voice sample
PROCEDURE SAY_COUNTDOWN_NUMBER(num)
    SELECT CASE num
        CASE 4: PLAY VOICE FOUR
        CASE 3: PLAY VOICE THREE
        CASE 2: PLAY VOICE TWO
        CASE 1: PLAY VOICE ONE
    END SELECT
END

REM Player announcement
PROCEDURE ANNOUNCE_PLAYER(player)
    IF player = 1 THEN
        PLAY VOICE PLAYER_ONE
    ELSE
        PLAY VOICE PLAYER_TWO
    END IF
END

REM Victory announcement
PROCEDURE ANNOUNCE_WINNER(player)
    IF player = 1 THEN
        PLAY VOICE PLAYER_ONE
        REM Wait for completion
        FOR i = 0 TO 40: WAIT: NEXT i
        PLAY VOICE WINS
    ELSE
        PLAY VOICE PLAYER_TWO
        FOR i = 0 TO 40: WAIT: NEXT i
        PLAY VOICE WINS
    END IF
END
```

### Voice Timing Considerations

**Important:** Intellivoice blocks other audio during speech!

```basic
REM Check if voice is still playing
REM (IntyBASIC may have VOICE_BUSY function)

PROCEDURE WAIT_FOR_VOICE
    REM Wait until voice completes
    WHILE VOICE_BUSY
        WAIT
    WEND
END

REM Example: Don't start music until voice finishes
PLAY VOICE BRAVO
WAIT_FOR_VOICE
REM Now safe to play music
```

---

## 7. Background Music (Title & Victory)

### Orchestra Tuning (Title Screen)

Create randomized tuning-up effect:

```basic
REM Orchestra warming up - random notes
PROCEDURE PLAY_TUNING_LOOP
    DIM inst, freq, vol, duration
    
    REM Generate random instrument sounds
    FOR i = 0 TO 5
        inst = RAND(8)             REM Random instrument 0-7
        
        SELECT CASE inst
            CASE 0: freq = PICCOLO_FREQ
            CASE 1: freq = TRUMPET_FREQ
            CASE 2: freq = VIOLIN_FREQ
            CASE 3: freq = OBOE_FREQ
            CASE 4: freq = VIOLA_FREQ
            CASE 5: freq = TROMBONE_FREQ
            CASE 6: freq = BASSOON_FREQ
            CASE 7: freq = TIMPANI_FREQ
        END SELECT
        
        REM Random volume and duration for "warming up" feel
        vol = 8 + RAND(7)          REM Volume 8-15
        duration = 10 + RAND(20)   REM 10-30 frames
        
        REM Play on random channel
        SOUND RAND(3), freq, vol
        
        FOR j = 0 TO duration
            WAIT
        NEXT j
        
        REM Silence channel
        SOUND RAND(3), 0, 0
        
        REM Brief pause between sounds
        FOR j = 0 TO 5: WAIT: NEXT j
    NEXT i
END

REM Call repeatedly in title screen loop
REM This creates continuous random warm-up sounds
```

### Victory Music (Simplified)

Due to ROM constraints, victory music should be SHORT:

```basic
REM Simple fanfare using 3 channels
PROCEDURE PLAY_VICTORY_FANFARE
    REM Channel A: Melody
    SOUND 0, TRUMPET_FREQ, 15
    REM Channel B: Harmony (5th above)
    SOUND 1, TRUMPET_FREQ * 3 / 2, 12
    REM Channel C: Bass
    SOUND 2, TIMPANI_FREQ, 10
    
    REM Hold chord
    FOR i = 0 TO 30: WAIT: NEXT i
    
    REM Next chord (higher)
    SOUND 0, PICCOLO_FREQ, 15
    SOUND 1, TRUMPET_FREQ, 12
    SOUND 2, TROMBONE_FREQ, 10
    
    FOR i = 0 TO 30: WAIT: NEXT i
    
    REM Final chord (resolution)
    SOUND 0, VIOLIN_FREQ, 15
    SOUND 1, OBOE_FREQ, 12
    SOUND 2, BASSOON_FREQ, 10
    
    FOR i = 0 TO 60: WAIT: NEXT i
    
    REM Silence all
    SOUND 0, 0, 0
    SOUND 1, 0, 0
    SOUND 2, 0, 0
END
```

**Note:** For actual classical piece excerpts (45-60 seconds), you would need to:
1. Convert MIDI to note sequences
2. Store as data tables
3. Create note player that reads tables
4. This requires significant ROM space

---

## 8. Sound Priority System

### Channel Management

Since only 3 channels exist, prioritize sounds:

```basic
REM Priority levels
CONST PRIORITY_INSTRUMENT = 3      REM Highest (player feedback)
CONST PRIORITY_TICK = 2            REM Medium (metronome)
CONST PRIORITY_EFFECT = 1          REM Lowest (sabotage effects)

DIM channel_priority(3)            REM Track current priority per channel

PROCEDURE PLAY_SOUND_WITH_PRIORITY(channel, freq, vol, priority)
    REM Only play if priority is higher than current
    IF priority >= channel_priority(channel) THEN
        SOUND channel, freq, vol
        channel_priority(channel) = priority
    END IF
END

REM Reset priorities each frame
PROCEDURE RESET_PRIORITIES
    channel_priority(0) = 0
    channel_priority(1) = 0
    channel_priority(2) = 0
END
```

### Instrument vs Tick Logic

```basic
REM On each beat
PROCEDURE ON_BEAT
    IF instrument_was_played THEN
        REM Instrument takes priority
        CALL PLAY_INSTRUMENT_NOTE
        REM Don't play tick
    ELSE
        REM No instrument, play tick
        CALL PLAY_TICK
    END IF
END
```

---

## 9. Audio Timing Integration with Game Loop

### Frame-Based Timing

IntyBASIC runs at 60 FPS. Sync audio to game timing:

```basic
DIM beat_frame              REM Frame when next beat occurs
DIM frames_per_beat         REM Frames between beats

REM Initialize for tempo
SELECT CASE tempo
    CASE 0: frames_per_beat = 45    REM Adagio (750ms = 45 frames)
    CASE 1: frames_per_beat = 30    REM Moderato (500ms = 30 frames)
    CASE 2: frames_per_beat = 22    REM Allegro (375ms = 22.5 frames ≈ 22)
END SELECT

REM In main game loop
IF frame_counter >= beat_frame THEN
    CALL ON_BEAT
    beat_frame = beat_frame + frames_per_beat
END IF
```

### Audio Feedback on Button Press

```basic
REM When player presses instrument button
PROCEDURE HANDLE_BUTTON_PRESS(instrument)
    REM Calculate timing
    delta = ABS(frame_counter - beat_frame)
    
    IF delta <= 4 THEN                    REM Perfect (±67ms at 60fps)
        CALL PLAY_INSTRUMENT(instrument)
        REM Visual feedback (not shown)
    ELSE IF delta <= 7 THEN               REM Good (±117ms)
        CALL PLAY_INSTRUMENT(instrument)
    ELSE
        REM Miss - no sound (tick will play at beat)
    END IF
END
```

---

## 10. ROM Space Considerations

### Audio Data Size Estimates

**PSG Sound Code:**
- Instrument procedures: ~50-100 bytes each
- Sound effect procedures: ~30-80 bytes each
- Music sequences: Variable (can be large!)
- **Total PSG code: ~1-2 KB**

**Intellivoice Samples:**
- Each word: ~200-500 bytes (phoneme data)
- Estimated total for DOWNBEAT!:
  - Numbers (1-4): ~800 bytes
  - Player/announcements: ~1500 bytes
  - Victory phrases: ~1000 bytes
  - Sabotage: ~300 bytes
  - **Total voice: ~3.5-4 KB**

**Background Music:**
- Classical excerpts (45-60 sec): ~5-8 KB each
- 4 pieces = **20-32 KB** (significant!)

**Recommendation:** 
- Keep victory music SHORT (5-10 seconds)
- OR use only 1-2 classical excerpts
- Total audio budget: ~8-10 KB realistic

---

## 11. Implementation Checklist

### PSG Sound System
- [ ] Define frequency constants for all 8 instruments
- [ ] Implement instrument play procedures with envelopes
- [ ] Implement metronome tick sound
- [ ] Implement sabotage sound effects (sneeze, drop pencil)
- [ ] Create sound priority system
- [ ] Integrate with beat timing system

### Intellivoice System
- [ ] Create voice data for countdown (4, 3, 2, 1)
- [ ] Create voice data for player announcements
- [ ] Create voice data for victory/celebration
- [ ] Create voice data for sabotage ("ACHOO!")
- [ ] Implement voice playback procedures
- [ ] Add voice completion waiting logic

### Music System
- [ ] Implement orchestra tuning loop (title screen)
- [ ] Create victory fanfare OR
- [ ] Convert classical piece excerpts to note data
- [ ] Implement music playback system
- [ ] Test music doesn't overflow ROM

### Integration
- [ ] Sync sounds with game timing (60 FPS)
- [ ] Ensure instrument replaces tick on beat
- [ ] Handle voice blocking during speech
- [ ] Test all sounds on real hardware
- [ ] Optimize ROM usage

---

## 12. Testing Notes

### Real Hardware Testing Required

**Critical tests:**
- PSG frequencies may sound different on real TV speakers
- Intellivoice timing varies by phrase length
- Channel conflicts need real hardware to verify
- Volume levels may need adjustment on real hardware

**Test sequence:**
1. Test each instrument sound individually
2. Test rapid note changes (beat timing)
3. Test all 3 channels simultaneously
4. Test Intellivoice + PSG overlap
5. Test full gameplay audio chaos (all sounds at once)
6. Test on real CRT TV speakers (not emulator!)

---

**End of Audio Specification - IntyBASIC**