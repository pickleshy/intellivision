    ' ============================================
    ' DOWNBEAT! v2 - Rhythm Runner
    ' Maple Leaf Rag - Complete A Strain
    '
    ' Moon Patrol-style runner where you jump over
    ' note obstacles in time with Joplin's melody.
    ' Two-layer system: Layer A plays melody on
    ' PSG Ch0 every beat, Layer B spawns obstacles
    ' SPAWN_OFFSET beats ahead so they arrive in
    ' sync with the music.
    ' ============================================

    ' --- Constants ---
    CONST PLAYER_X = 40
    CONST GROUND_Y = 48
    CONST JUMP_FRAMES = 36
    CONST NOTE_Y = 56           ' Note 8x8, bottom at Y=64 = ground
    CONST NOTE_SPAWN_X = 168    ' Just off right edge
    CONST SCROLL_FRAC = 171     ' Fractional speed per frame (171/256)
                                ' Total: 1 + 171/256 = 1.668 px/frame = 100 px/sec
    CONST MAX_HITS = 3
    CONST FRAMES_PER_NOTE = 9   ' 16th note at 100 BPM (150ms per position)
    CONST MELODY_LENGTH = 128   ' Total 16th-note positions in full A strain (16 bars)
    CONST NOTE_VOLUME = 10      ' Background melody volume
    CONST SPAWN_OFFSET = 9      ' Spawn obstacles early to sync with melody
                                ' 128px / 1.668px/frame / 9 frames = ~8.5 beats

    ' Sprite register flags
    CONST SPR_VISIBLE = $0200
    CONST SPR_YRES    = $0080   ' True 8x16 (two consecutive GRAM cards)

    ' --- Variables ---
    PlayerY = GROUND_Y
    JumpActive = 0
    JumpFrame = 0
    HitCount = 0
    GameOver = 0
    SfxTimer = 0
    ButtonReleased = 1

    ' Melody system
    BeatCounter = 0
    SpawnCountdown = FRAMES_PER_NOTE  ' First note after 1 beat delay
    SongDone = 0
    SongEndTimer = 0

    ' 16-bit variable for current PSG period
    #CurPSG = 0
    #PrevPSG = 0
    MelodyMute = 0

    ' Note arrays (7 slots for MOBs 1-7)
    DIM NoteActive(7)
    DIM NoteX(7)
    DIM NoteFrac(7)
    DIM NoteCleared(7)
    DIM #NotePitch(7)           ' PSG period for each obstacle (16-bit)
    DIM NoteColor(7)            ' Color per note slot (for varied colors)
    DIM JumpMap(128)            ' Rehearsal: record jump positions
    NoteColorIdx = 0            ' Cycling index into NoteColorPalette

    ' --- Color Stack mode: all black ---
    MODE 0, 0, 0, 0, 0
    WAIT

RestartGame:
    ' --- Reset all game state ---
    PlayerY = GROUND_Y
    JumpActive = 0
    JumpFrame = 0
    HitCount = 0
    GameOver = 0
    SfxTimer = 0
    ButtonReleased = 1
    BeatCounter = 0
    SpawnCountdown = FRAMES_PER_NOTE
    SongDone = 0
    SongEndTimer = 0
    #CurPSG = 0
    #PrevPSG = 0
    MelodyMute = 0
    NoteColorIdx = 0
    SOUND 0, 0, 0
    SOUND 1, 0, 0

    ' --- Clear screen ---
    CLS
    WAIT

    ' --- Define GRAM cards 0-6 (player x2, ground, note, heart) ---
    DEFINE 0, 4, GramPlayerData     ' Cards 0-3: standing + jumping
    WAIT
    DEFINE 4, 3, GramWorldData      ' Cards 4-6: ground, note, heart
    WAIT

    ' --- Draw HUD: 3 red hearts at top-right ---
    FOR Col = 0 TO 2
        PRINT AT 17 + Col, 6 * 8 + 2 + $0800  ' GRAM card 6, RED
    NEXT Col

    ' --- Draw ground line (Row 7, positions 140-159) ---
    FOR Col = 0 TO 19
        PRINT AT 140 + Col, 4 * 8 + 7 + $0800 ' GRAM card 4, WHITE
    NEXT Col

    ' --- Initialize all note slots ---
    FOR Slot = 0 TO 6
        NoteActive(Slot) = 0
        NoteCleared(Slot) = 0
        #NotePitch(Slot) = 0
        NoteColor(Slot) = 0
        SPRITE Slot + 1, 0, 0, 0
    NEXT Slot

    ' --- Initialize jump recording ---
    FOR Slot = 0 TO 127
        JumpMap(Slot) = 0
    NEXT Slot

    ' --- Wait for player to start ---
    PRINT AT 104 COLOR 7, "PRESS BUTTON"
WaitStart:
    WAIT
    IF CONT.BUTTON = 0 THEN GOTO WaitStart
    PRINT AT 104, "            "

    ' ==========================================
    ' Main loop
    ' ==========================================
MainLoop:
    WAIT
    IF GameOver THEN GOTO GameOverScreen

    ' --- Retrigger melody note after 1-frame mute ---
    ' AY-3-8914 doesn't restart waveform on same period write.
    ' MelodyMute was set last frame when a repeated note was detected.
    ' Restore the note now for a clean attack (~17ms silence gap).
    IF MelodyMute THEN
        SOUND 0, #PrevPSG, NOTE_VOLUME
        MelodyMute = 0
    END IF

    ' --- Beat-driven two-layer system ---
    ' SpawnCountdown counts frames between 16th notes (FRAMES_PER_NOTE=9).
    ' On each beat tick, Layer A plays the melody note and Layer B checks
    ' the obstacle map SPAWN_OFFSET beats ahead to spawn notes early.
    IF SongDone = 0 THEN
        SpawnCountdown = SpawnCountdown - 1
        IF SpawnCountdown = 0 THEN
            SpawnCountdown = FRAMES_PER_NOTE

            ' Layer A: Background melody (always plays)
            #CurPSG = MelodyPSG(BeatCounter)
            IF #CurPSG > 0 THEN
                IF #CurPSG = #PrevPSG THEN
                    SOUND 0, , 0           ' Mute 1 frame for retrigger
                    MelodyMute = 1
                ELSE
                    SOUND 0, #CurPSG, NOTE_VOLUME
                END IF
                #PrevPSG = #CurPSG
            ELSE
                SOUND 0, , 0              ' Silence on rest
                #PrevPSG = 0
            END IF

            ' Layer B: Obstacle spawning (read ahead for scroll sync)
            ' Spawn early so obstacle arrives at player when melody beat plays
            SpawnBeat = BeatCounter + SPAWN_OFFSET
            IF SpawnBeat < MELODY_LENGTH THEN
                CurObstacle = ObstacleMap(SpawnBeat)
                IF CurObstacle = 1 THEN
                    FreeSlot = 255
                    FOR Slot = 0 TO 6
                        IF NoteActive(Slot) = 0 THEN
                            IF FreeSlot = 255 THEN FreeSlot = Slot
                        END IF
                    NEXT Slot
                    IF FreeSlot < 255 THEN
                        NoteActive(FreeSlot) = 1
                        NoteX(FreeSlot) = NOTE_SPAWN_X
                        NoteFrac(FreeSlot) = 0
                        NoteCleared(FreeSlot) = 0
                        ' Pitch from arrival beat (what player hears)
                        #NotePitch(FreeSlot) = MelodyPSG(SpawnBeat)
                        ' Assign cycling color from palette
                        NoteColor(FreeSlot) = NoteColorPalette(NoteColorIdx)
                        NoteColorIdx = NoteColorIdx + 1
                        IF NoteColorIdx >= 5 THEN NoteColorIdx = 0
                    END IF
                END IF
            END IF

            BeatCounter = BeatCounter + 1
            IF BeatCounter >= MELODY_LENGTH THEN SongDone = 1
        END IF
    END IF

    ' --- Input: jump (require button release between jumps) ---
    IF CONT.BUTTON THEN
        IF ButtonReleased THEN
            IF JumpActive = 0 THEN
                JumpActive = 1
                JumpFrame = 0
                ButtonReleased = 0
                ' Record jump position for rehearsal
                IF BeatCounter < MELODY_LENGTH THEN
                    JumpMap(BeatCounter) = 1
                END IF
            END IF
        END IF
    ELSE
        ButtonReleased = 1
    END IF

    ' --- Update jump ---
    IF JumpActive THEN
        PlayerY = GROUND_Y - JumpArc(JumpFrame)
        JumpFrame = JumpFrame + 1
        IF JumpFrame >= JUMP_FRAMES THEN
            JumpActive = 0
            PlayerY = GROUND_Y
        END IF
    END IF

    ' --- Update player sprite (8x16 via YRES: cards 0-1 stand, 2-3 jump) ---
    IF JumpActive THEN
        SPRITE 0, PLAYER_X + SPR_VISIBLE, PlayerY + SPR_YRES, 2 * 8 + 2 + $0800
    ELSE
        SPRITE 0, PLAYER_X + SPR_VISIBLE, PlayerY + SPR_YRES, 0 * 8 + 2 + $0800
    END IF

    ' --- Scroll obstacles ---
    ' Fixed-point scrolling: each frame adds SCROLL_FRAC (171) to NoteFrac.
    ' When NoteFrac overflows 256, move 2px instead of 1px.
    ' Effective speed: 1 + 171/256 = 1.668 px/frame ≈ 100 px/sec.
    ' 7 sprite slots (MOBs 1-7) are recycled as notes scroll off-screen.
    FOR Slot = 0 TO 6
        IF NoteActive(Slot) THEN
            NoteFrac(Slot) = NoteFrac(Slot) + SCROLL_FRAC
            IF NoteFrac(Slot) >= 256 THEN
                NoteFrac(Slot) = NoteFrac(Slot) - 256
                NoteX(Slot) = NoteX(Slot) - 2
            ELSE
                NoteX(Slot) = NoteX(Slot) - 1
            END IF

            ' Deactivate at left edge (< 2 avoids unsigned wrap)
            IF NoteX(Slot) < 2 THEN
                NoteActive(Slot) = 0
                SPRITE Slot + 1, 0, 0, 0
            ELSE
                SPRITE Slot + 1, NoteX(Slot) + SPR_VISIBLE, NOTE_Y, 5 * 8 + NoteColor(Slot) + $0800
            END IF
        END IF
    NEXT Slot

    ' --- Check collisions (crossing-point detection) ---
    ' Fires once when obstacle crosses PLAYER_X (NoteCleared prevents re-fire).
    ' Vertical check: if PlayerY + 12 > NOTE_Y, player's feet are below the
    ' note top = HIT. The 12px offset gives a 4px grace zone at the feet.
    ' On hit: detuned "dud" SFX on Ch1 (period + period/16 ≈ 1 semitone flat).
    FOR Slot = 0 TO 6
        IF NoteActive(Slot) THEN
            IF NoteCleared(Slot) = 0 THEN
                IF NoteX(Slot) < PLAYER_X THEN
                    NoteCleared(Slot) = 1
                    ' Vertical: player body > note top = HIT (4px grace at feet)
                    IF PlayerY + 12 > NOTE_Y THEN
                        HitCount = HitCount + 1
                        NoteActive(Slot) = 0
                        SPRITE Slot + 1, 0, 0, 0
                        ' Dud sound: flat by ~1 semitone on Channel B
                        IF #NotePitch(Slot) > 0 THEN
                            SOUND 1, #NotePitch(Slot) + #NotePitch(Slot) / 16, 12
                        ELSE
                            SOUND 1, 200, 12
                        END IF
                        SfxTimer = 6
                        ' Remove a heart (rightmost first)
                        PRINT AT 17 + (MAX_HITS - HitCount), 0
                        IF HitCount >= MAX_HITS THEN GameOver = 1
                    END IF
                END IF
            END IF
        END IF
    NEXT Slot

    ' --- SFX timer (dud sound on Channel B) ---
    IF SfxTimer > 0 THEN
        SfxTimer = SfxTimer - 1
        IF SfxTimer = 0 THEN SOUND 1, 0, 0
    END IF

    ' --- Check song completion ---
    ' After all 128 beats are spawned (SongDone=1), wait for remaining
    ' obstacles to scroll off-screen, then pause 0.5 sec before ending.
    IF SongDone THEN
        ActiveCount = 0
        FOR Slot = 0 TO 6
            IF NoteActive(Slot) THEN ActiveCount = ActiveCount + 1
        NEXT Slot
        IF ActiveCount = 0 THEN
            SongEndTimer = SongEndTimer + 1
            IF SongEndTimer >= 30 THEN GameOver = 2  ' 0.5 sec pause
        END IF
    END IF

    GOTO MainLoop

    ' ==========================================
    ' End Screen
    ' ==========================================
GameOverScreen:
    SOUND 0, 0, 0
    SOUND 1, 0, 0
    FOR Slot = 0 TO 7
        SPRITE Slot, 0, 0, 0
    NEXT Slot
    IF GameOver = 2 THEN
        CLS
        WAIT
        PRINT AT 22 COLOR 5, "SONG COMPLETE!"
        ' Display 8 rows of 16 positions (0=no jump, 1=jump)
        FOR MapRow = 0 TO 7
            FOR Col = 0 TO 15
                IF JumpMap(MapRow * 16 + Col) THEN
                    PRINT AT 80 + MapRow * 20 + Col + 2, 142
                ELSE
                    PRINT AT 80 + MapRow * 20 + Col + 2, 135
                END IF
            NEXT Col
        NEXT MapRow
        PRINT AT 42 COLOR 7, "PRESS TO REPLAY"
    ELSE
        PRINT AT 105 COLOR 2, "GAME OVER!"
        PRINT AT 125 COLOR 7, "PRESS TO RETRY"
    END IF

    ' --- Wait for button release then press ---
GameOverRelease:
    WAIT
    IF CONT.BUTTON THEN GOTO GameOverRelease
GameOverWait:
    WAIT
    IF CONT.BUTTON = 0 THEN GOTO GameOverWait
    GOTO RestartGame

    ' ============================================
    ' Data
    ' ============================================

JumpArc:
    DATA 0, 2, 4, 6, 8, 10, 11, 13, 14, 15, 16, 17, 18, 19, 19, 20, 20, 20
    DATA 20, 20, 20, 19, 19, 18, 17, 16, 15, 14, 13, 11, 10, 8, 6, 4, 2, 0

    ' ============================================
    ' Maple Leaf Rag - A Strain Background Melody
    ' 128 entries on the 16th-note grid at 100 BPM.
    ' 16 bars in 2/4 time = complete A strain.
    '
    ' Values are AY-3-8914 PSG periods for NTSC:
    '   Period = 3579545 / (16 * frequency_hz)
    '   0 = rest (channel silenced explicitly)
    '
    ' Extracted from Joplin MIDI using parse_midi.py
    ' (highest note per tick at each quantized position).
    ' This data is authoritative — hand edits to the
    ' arpeggio/octave voicing sounded worse in testing.
    '
    ' Structure: M1-M8 = theme (repeated), M9-M12 = contrast,
    ' M13-M16 = ascending broken arpeggio transition,
    ' M17-M19 = high chord hits, M20-M24 = descending melody,
    ' M25-M32 = octave-lower reprise + final cadence.
    ' ============================================

MelodyPSG:
    ' --- First half: Theme + Contrast + Arpeggio (bars 1-8) ---
    ' Beat 1                              Beat 2
    DATA 1438,    0, 1077,  539           ' M1: D#3  ---  G#3  G#4
    DATA  360,  539,  428,  360           ' M2: D#5  G#4  C5   D#5
    DATA 1017,  571,  360,  571           ' M3: A3   G4   D#5  G4
    DATA  480,  360,  807,    0           ' M4: A#4  D#5  C#4  ---
    DATA 1438,    0, 1077,  539           ' M5: D#3  ---  G#3  G#4
    DATA  360,  539,  428,  360           ' M6: D#5  G#4  C5   D#5
    DATA 1017,  571,  360,  571           ' M7: A3   G4   D#5  G4
    DATA  480,  360,  807,    0           ' M8: A#4  D#5  C#4  ---
    DATA 1438,  360, 1357,  539           ' M9: D#3  D#5  E3   G#4
    DATA  453,  339, 1438,  360           ' M10: B4  E5   D#3  D#5
    DATA 1438,  360, 1357,  539           ' M11: D#3 D#5  E3   G#4
    DATA  453,  339, 1438,  360           ' M12: B4  E5   D#3  D#5
    DATA    0,    0, 2155, 2155           ' M13: ---  ---  G#2  G#2  (ascending arpeggio)
    DATA 1812, 1077, 2155, 1077           ' M14: B2   G#3  G#2  G#3
    DATA  906,  539, 1077,  539           ' M15: B3   G#4  G#3  G#4
    DATA  453,  269,  539,  269           ' M16: B4   G#5  G#4  G#5
    ' --- Second half: Theme high + Resolution (bars 9-16) ---
    DATA  226,  135,  135,    0           ' M17: B5   G#6  G#6  ---  (chord hits)
    DATA  135,    0,  135,    0           ' M18: G#6  ---  G#6  ---
    DATA  135,  135,  428,  180           ' M19: G#6  G#6  C5   D#6  (melody emerges)
    DATA  160,  214,  180,  160           ' M20: F6   C6   D#6  F6
    DATA  428,  269,  453,  240           ' M21: C5   G#5  B4   A#5
    DATA  226,  269,  240,  214           ' M22: B5   G#5  A#5  C6
    DATA  428,  269,  214,  269           ' M23: C5   G#5  C6   G#5
    DATA  240,    0,  269,    0           ' M24: A#5  ---  G#5  ---
    DATA    0,  269,  906,    0           ' M25: ---  G#5  B3   ---  (octave lower reprise)
    DATA  269,    0,  269,    0           ' M26: G#5  ---  G#5  ---
    DATA  269,  269,  855,  360           ' M27: G#5  G#5  C4   D#5
    DATA  320,  428,  360,  320           ' M28: F5   C5   D#5  F5
    DATA  855,  539,  906,  480           ' M29: C4   G#4  B3   A#4
    DATA  453,  539,  480,  428           ' M30: B4   G#4  A#4  C5
    DATA  855,  539,  428,  539           ' M31: C4   G#4  C5   G#4
    DATA  480,    0,  539,    0           ' M32: A#4  ---  G#4  ---  (final cadence)

    ' ============================================
    ' Obstacle Map
    ' 128 entries (one per 16th-note position).
    ' 1 = spawn obstacle at this beat, 0 = no obstacle.
    ' Placed on melodic accent beats (strong notes, phrase starts).
    ' Layer B reads this SPAWN_OFFSET beats ahead of BeatCounter
    ' so obstacles arrive at PLAYER_X when the melody note plays.
    ' 16 total obstacles, gaps of 6-10 beats for reaction time.
    ' Designed by playing the game and aligning with natural
    ' jump timing using the JumpMap recording feature.
    ' ============================================

ObstacleMap:
    ' --- First half (bars 1-8): 8 obstacles ---
    DATA 0,0,0,0, 0,0,0,0, 0,0,1,0, 0,0,0,0     ' M1-4:   pos 10 (D#5)
    DATA 0,0,0,0, 1,0,0,0, 0,0,1,0, 0,0,0,0     ' M5-8:   pos 20,26 (D#5,D#5)
    DATA 0,1,0,0, 0,0,0,0, 0,1,0,0, 0,0,0,1     ' M9-12:  pos 33,41,47 (D#5,D#5,D#5)
    DATA 0,0,0,0, 0,1,0,0, 0,0,0,0, 1,0,0,0     ' M13-16: pos 53,60 (G#3,B4 arpeggio)
    ' --- Second half (bars 9-16): 8 obstacles ---
    DATA 0,0,0,0, 1,0,0,0, 0,0,0,0, 1,0,0,0     ' M17-20: pos 68,76 (G#6,F6)
    DATA 0,0,1,0, 0,0,0,0, 0,0,0,1, 0,0,0,0     ' M21-24: pos 82,91 (B4,G#5)
    DATA 0,1,0,0, 0,0,0,0, 0,1,0,0, 0,0,0,0     ' M25-28: pos 97,105 (G#5,G#5)
    DATA 1,0,0,0, 0,0,0,0, 0,1,0,0, 0,0,0,0     ' M29-32: pos 112,121 (C4,G#4)

    ' ============================================
    ' Note Color Palette (5 cycling colors)
    ' ============================================

NoteColorPalette:
    DATA 6, 5, 7, 1, 3         ' Yellow, Green, White, Blue, Tan

    ' ============================================
    ' Graphics Data (GRAM cards 0-6)
    ' ============================================

    ' --- Player sprites (cards 0-3, loaded with first DEFINE) ---
GramPlayerData:
    ' Card 0: Player standing - top half (hat, face, shoulders)
    BITMAP ".XXXXXX."
    BITMAP ".XXXXXX."
    BITMAP "XXXXXXXX"
    BITMAP "..XXXX.."
    BITMAP "...XX..."
    BITMAP "..XXXX.."
    BITMAP ".XX..XX."
    BITMAP ".XX..XX."

    ' Card 1: Player standing - bottom half (jacket, legs, shoes)
    BITMAP ".XX..XX."
    BITMAP ".XXXXXX."
    BITMAP "..XXXX.."
    BITMAP "..XXXX.."
    BITMAP "..X..X.."
    BITMAP "..X..X.."
    BITMAP ".XX..XX."
    BITMAP "........"

    ' Card 2: Player jumping - top half (same hat, arms spread)
    BITMAP ".XXXXXX."
    BITMAP ".XXXXXX."
    BITMAP "XXXXXXXX"
    BITMAP "..XXXX.."
    BITMAP "...XX..."
    BITMAP "..XXXX.."
    BITMAP ".XXXXXX."
    BITMAP "X..XX..X"

    ' Card 3: Player jumping - bottom half (legs tucked, feet wide)
    BITMAP "..XXXX.."
    BITMAP "..XXXX.."
    BITMAP "..XXXX.."
    BITMAP "..X..X.."
    BITMAP ".X....X."
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"

    ' --- World sprites (cards 4-6, loaded with second DEFINE) ---
GramWorldData:
    ' Card 4: Ground line
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"

    ' Card 5: Musical note (eighth note shape)
    BITMAP "...XX..."
    BITMAP "...XXXX."
    BITMAP "...XX..."
    BITMAP "...XX..."
    BITMAP "...XX..."
    BITMAP "..XXXX.."
    BITMAP ".XXXXXX."
    BITMAP "..XXXX.."

    ' Card 6: Heart
    BITMAP ".XX..XX."
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP ".XXXXXX."
    BITMAP "..XXXX.."
    BITMAP "...XX..."
    BITMAP "........"
    BITMAP "........"
