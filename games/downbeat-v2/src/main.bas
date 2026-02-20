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
    CONST MAX_HITS = 5
    CONST FRAMES_PER_NOTE = 9   ' 16th note at 100 BPM (150ms per position)
    CONST MELODY_LENGTH = 128   ' Total 16th-note positions in full A strain (16 bars)
    CONST NOTE_VOLUME = 10      ' Background melody volume
    CONST SPAWN_OFFSET = 9      ' Spawn obstacles early to sync with melody
                                ' 128px / 1.668px/frame / 9 frames = ~8.5 beats

    ' Sprite register flags
    CONST SPR_VISIBLE = $0200
    CONST SPR_YSIZE   = $0100   ' Double-height (stretches 8x8 to 8x16)

    ' --- Variables ---
    PlayerY = GROUND_Y
    JumpActive = 0
    JumpFrame = 0
    FloatUsed = 0
    FloatActive = 0
    FloatTimer = 0
    HitCount = MAX_HITS - 3     ' Start with 3 of 5 hearts
    DamageTaken = 0
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

    ' Note arrays (4 slots for MOBs 1-4; MOB 5=flower, MOBs 6-7=pencils)
    DIM NoteActive(4)
    DIM NoteX(4)
    DIM NoteFrac(4)
    DIM NoteCleared(4)
    DIM #NotePitch(4)           ' PSG period for each obstacle (16-bit)
    DIM NoteColor(4)            ' Color per note slot (for varied colors)
    DIM JumpMap(128)            ' Rehearsal: record jump positions


    ' Pencil system (Level 2: falling pencils)
    DIM PencilState(2)          ' 0=inactive, 1=falling
    DIM PencilX(2)
    DIM PencilY(2)
    DIM PencilFrac(2)           ' Fall tick (falling) / scroll fraction (grounded)
    DIM PencilCleared(2)        ' Collision flag
    PencilSpawnTimer = 0
    PencilsSpawned = 0

    ' Flower system (Level 2: healing power-up)
    FlowerState = 0             ' 0=inactive, 1=drifting
    FlowerX = 0
    FlowerY = 0
    FlowerDriftY = 0            ' Fractional Y accumulator (slow vertical drift)
    FlowerSpawnTimer = 0
    FlowersSpawned = 0

    ' Level selector
    CurrentLevel = 0
    #LevelOffset = 0

    ' --- Color Stack mode: all black ---
    MODE 0, 0, 0, 0, 0
    WAIT

RestartGame:
    ' --- Reset all game state ---
    PlayerY = GROUND_Y
    JumpActive = 0
    JumpFrame = 0
    FloatUsed = 0
    FloatActive = 0
    FloatTimer = 0
    HitCount = MAX_HITS - 3     ' Start with 3 of 5 hearts
    DamageTaken = 0
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
    SOUND 0, 0, 0
    SOUND 1, 0, 0

    ' --- Clear screen ---
    CLS
    WAIT

    ' --- Define GRAM cards 0-6 (player, ground, note, heart, celebration, pencil, flower) ---
    DEFINE 0, 7, GramData
    WAIT

    ' --- Initialize all note slots ---
    FOR Slot = 0 TO 3
        NoteActive(Slot) = 0
        NoteCleared(Slot) = 0
        #NotePitch(Slot) = 0
        NoteColor(Slot) = 0
        SPRITE Slot + 1, 0, 0, 0
    NEXT Slot

    ' --- Initialize pencil slots ---
    PencilSpawnTimer = RANDOM(120) + 150
    PencilsSpawned = 0
    FOR Slot = 0 TO 1
        PencilState(Slot) = 0
        PencilCleared(Slot) = 0
        SPRITE Slot + 6, 0, 0, 0
    NEXT Slot

    ' --- Initialize flower ---
    FlowerState = 0
    FlowerSpawnTimer = RANDOM(120) + 60
    FlowersSpawned = 0
    SPRITE 5, 0, 0, 0

    ' --- Initialize jump recording ---
    FOR Slot = 0 TO 127
        JumpMap(Slot) = 0
    NEXT Slot

    ' --- Hide player sprite for level selector ---
    SPRITE 0, 0, 0, 0

    ' --- Level selector ---
    PRINT AT 25 COLOR 7, "DOWNBEAT!"
    PRINT AT 85 COLOR 5, "SELECT LEVEL"
    PRINT AT 102 COLOR 6, "1 MAPLE LEAF RAG"
    PRINT AT 122 COLOR 3, "2 PENCIL DROP"
    PRINT AT 142 COLOR 3, "3 LEVEL 3"

LevelSelect:
    WAIT
    IF CONT.key = 1 THEN CurrentLevel = 0 : GOTO LevelConfirm
    IF CONT.key = 2 THEN CurrentLevel = 1 : GOTO LevelConfirm
    IF CONT.key = 3 THEN CurrentLevel = 2 : GOTO LevelConfirm
    GOTO LevelSelect

LevelConfirm:
    #LevelOffset = LevelOffsets(CurrentLevel)
    CLS
    WAIT
    ' Redraw HUD after CLS — only show hearts the player has
    FOR Col = 0 TO MAX_HITS - 1
        IF Col < MAX_HITS - HitCount THEN
            PRINT AT HeartPositions(Col), 3 * 8 + 4 + $0800 + $1000
        END IF
    NEXT Col
    FOR Col = 0 TO 19
        PRINT AT 140 + Col, 1 * 8 + 7 + $0800
    NEXT Col

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
            #CurPSG = AllMelodyData(#LevelOffset + BeatCounter)
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
                CurObstacle = AllObstacleData(#LevelOffset + SpawnBeat)
                IF CurObstacle = 1 THEN
                    FreeSlot = 255
                    FOR Slot = 0 TO 3
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
                        #NotePitch(FreeSlot) = AllMelodyData(#LevelOffset + SpawnBeat)
                        NoteColor(FreeSlot) = 1  ' Cyan (pastel 9) — low 3 bits
                    END IF
                END IF
            END IF

            BeatCounter = BeatCounter + 1
            IF BeatCounter >= MELODY_LENGTH THEN SongDone = 1
        END IF
    END IF

    ' --- Pencil spawn (Level 2 only) ---
    IF CurrentLevel = 1 THEN
        IF PencilsSpawned < 2 AND SongDone = 0 THEN
            IF BeatCounter >= 20 AND BeatCounter < 108 THEN
                IF PencilSpawnTimer > 0 THEN
                    PencilSpawnTimer = PencilSpawnTimer - 1
                END IF
                IF PencilSpawnTimer = 0 THEN
                    ' Don't spawn while another pencil is falling
                    IF PencilState(0) = 1 OR PencilState(1) = 1 THEN
                        PencilSpawnTimer = 15  ' Retry shortly
                    ELSE
                    FreeSlot = 255
                    FOR Slot = 0 TO 1
                        IF PencilState(Slot) = 0 THEN
                            IF FreeSlot = 255 THEN FreeSlot = Slot
                        END IF
                    NEXT Slot
                    IF FreeSlot < 255 THEN
                        PencilState(FreeSlot) = 1
                        PencilX(FreeSlot) = RANDOM(60) + 100
                        PencilY(FreeSlot) = 0
                        PencilFrac(FreeSlot) = 0
                        PencilCleared(FreeSlot) = 0
                        PencilsSpawned = PencilsSpawned + 1
                        PencilSpawnTimer = RANDOM(180) + 300
                    ELSE
                        PencilSpawnTimer = 30  ' Retry in 0.5 sec
                    END IF
                    END IF
                END IF
            END IF
        END IF
    END IF

    ' --- Flower spawn (Level 2 only) ---
    IF CurrentLevel = 1 THEN
        IF FlowerState = 0 AND FlowersSpawned < 2 AND SongDone = 0 THEN
            IF BeatCounter >= 55 AND BeatCounter < 95 THEN
                IF FlowerSpawnTimer > 0 THEN
                    FlowerSpawnTimer = FlowerSpawnTimer - 1
                END IF
                IF FlowerSpawnTimer = 0 THEN
                    ' Don't spawn while a pencil is falling
                    IF PencilState(0) = 1 OR PencilState(1) = 1 THEN
                        FlowerSpawnTimer = 30
                    ELSE
                        FlowerState = 1
                        FlowerX = RANDOM(60) + 80
                        FlowerY = 0
                        FlowerDriftY = 0
                        FlowersSpawned = FlowersSpawned + 1
                        FlowerSpawnTimer = RANDOM(180) + 300
                    END IF
                END IF
            END IF
        END IF
    END IF

    ' --- Input: jump + peak float ---
    ' First press starts jump. Second press near peak (frames 15-20)
    ' triggers float: snap to peak height, hang 10 frames, then descend.
    IF CONT.BUTTON THEN
        IF ButtonReleased THEN
            IF JumpActive = 0 THEN
                JumpActive = 1
                JumpFrame = 0
                FloatUsed = 0
                ButtonReleased = 0
                ' Record jump position for rehearsal
                IF BeatCounter < MELODY_LENGTH THEN
                    JumpMap(BeatCounter) = 1
                END IF
            ELSEIF FloatUsed < 3 THEN
                IF FloatActive = 0 THEN
                    IF JumpFrame >= 15 THEN
                        IF JumpFrame <= 20 THEN
                            ' Trigger float: hang at peak (up to 3 per jump)
                            FloatActive = 1
                            FloatTimer = 10
                            FloatUsed = FloatUsed + 1
                            ButtonReleased = 0
                        END IF
                    END IF
                END IF
            END IF
        END IF
    ELSE
        ButtonReleased = 1
    END IF

    ' --- Update jump (with peak float) ---
    IF JumpActive THEN
        IF FloatActive THEN
            ' Hanging at peak height
            PlayerY = GROUND_Y - 20
            FloatTimer = FloatTimer - 1
            IF FloatTimer = 0 THEN
                FloatActive = 0
                JumpFrame = 18     ' Resume descent from here
            END IF
        ELSE
            PlayerY = GROUND_Y - JumpArc(JumpFrame)
            JumpFrame = JumpFrame + 1
            IF JumpFrame >= JUMP_FRAMES THEN
                JumpActive = 0
                FloatActive = 0
                PlayerY = GROUND_Y
            END IF
        END IF
    END IF

    ' --- Update player sprite (8x8 stretched to 8x16 via YSIZE) ---
    IF SongEndTimer > 0 AND DamageTaken = 0 THEN
        SPRITE 0, PLAYER_X + SPR_VISIBLE, PlayerY + SPR_YSIZE, 4 * 8 + 2 + $0800
    ELSE
        SPRITE 0, PLAYER_X + SPR_VISIBLE, PlayerY + SPR_YSIZE, 0 * 8 + 2 + $0800
    END IF

    ' --- Scroll obstacles ---
    ' Fixed-point scrolling: each frame adds SCROLL_FRAC (171) to NoteFrac.
    ' When NoteFrac overflows 256, move 2px instead of 1px.
    ' Effective speed: 1 + 171/256 = 1.668 px/frame ≈ 100 px/sec.
    ' 5 sprite slots (MOBs 1-5) are recycled as notes scroll off-screen.
    FOR Slot = 0 TO 3
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
                SPRITE Slot + 1, NoteX(Slot) + SPR_VISIBLE, NOTE_Y, 2 * 8 + NoteColor(Slot) + $0800 + $1000
            END IF
        END IF
    NEXT Slot

    ' --- Update pencils (Level 2 only) ---
    ' Pencils fall through the ground and off-screen. They only hurt
    ' the player by landing on them mid-fall — no grounded obstacles.
    IF CurrentLevel = 1 THEN
        FOR Slot = 0 TO 1
            IF PencilState(Slot) = 1 THEN
                ' Scroll left with the world
                PencilFrac(Slot) = PencilFrac(Slot) + SCROLL_FRAC
                IF PencilFrac(Slot) >= 256 THEN
                    PencilFrac(Slot) = PencilFrac(Slot) - 256
                    IF PencilX(Slot) >= 4 THEN
                        PencilX(Slot) = PencilX(Slot) - 2
                    ELSE
                        PencilState(Slot) = 0
                        SPRITE Slot + 6, 0, 0, 0
                    END IF
                ELSE
                    IF PencilX(Slot) >= 3 THEN
                        PencilX(Slot) = PencilX(Slot) - 1
                    ELSE
                        PencilState(Slot) = 0
                        SPRITE Slot + 6, 0, 0, 0
                    END IF
                END IF
                ' Fall downward — through ground and off screen
                IF PencilState(Slot) = 1 THEN
                    PencilY(Slot) = PencilY(Slot) + 2
                    IF PencilY(Slot) > 96 THEN
                        ' Off the bottom of the screen
                        PencilState(Slot) = 0
                        SPRITE Slot + 6, 0, 0, 0
                    ELSE
                        SPRITE Slot + 6, PencilX(Slot) + SPR_VISIBLE, PencilY(Slot), 5 * 8 + 6 + $0800
                    END IF
                END IF
            END IF
        NEXT Slot
    END IF

    ' --- Update flower (Level 2 only) ---
    IF CurrentLevel = 1 THEN
        IF FlowerState = 1 THEN
            ' Slow diagonal drift: ~0.5px left per frame, ~1px down every 3 frames
            FlowerDriftY = FlowerDriftY + 1
            ' Horizontal: move 1px every 2 frames
            IF FlowerDriftY AND 1 THEN
                IF FlowerX >= 3 THEN
                    FlowerX = FlowerX - 1
                ELSE
                    FlowerState = 0
                    SPRITE 5, 0, 0, 0
                END IF
            END IF
            ' Vertical: move 1px every 3 frames
            IF FlowerState = 1 THEN
                IF FlowerDriftY >= 3 THEN
                    FlowerDriftY = 0
                    FlowerY = FlowerY + 1
                END IF
                ' Off bottom of screen — missed it
                IF FlowerY > 90 THEN
                    FlowerState = 0
                    SPRITE 5, 0, 0, 0
                ELSE
                    SPRITE 5, FlowerX + SPR_VISIBLE, FlowerY, 6 * 8 + 4 + $0800 + $1000
                END IF
            END IF

            ' --- Flower collection (must be jumping/floating) ---
            IF FlowerState = 1 AND JumpActive THEN
                ' Check overlap: player at (PLAYER_X, PlayerY) 8x16
                ' Flower at (FlowerX, FlowerY) 8x8
                IF FlowerX + 8 > PLAYER_X THEN
                    IF FlowerX < PLAYER_X + 8 THEN
                        IF FlowerY + 8 > PlayerY THEN
                            IF FlowerY < PlayerY + 16 THEN
                                ' Collected! Heal 2 hearts
                                FlowerState = 0
                                SPRITE 5, 0, 0, 0
                                IF HitCount > 1 THEN
                                    HitCount = HitCount - 2
                                ELSE
                                    HitCount = 0
                                END IF
                                ' Redraw hearts
                                FOR Col = 0 TO MAX_HITS - 1
                                    IF Col < MAX_HITS - HitCount THEN
                                        PRINT AT HeartPositions(Col), 3 * 8 + 4 + $0800 + $1000
                                    ELSE
                                        PRINT AT HeartPositions(Col), 0
                                    END IF
                                NEXT Col
                                ' Tinkle SFX on Ch1 (very high, short)
                                SOUND 1, 80, 10
                                SfxTimer = 4
                            END IF
                        END IF
                    END IF
                END IF
            END IF
        END IF
    END IF

    ' --- Check collisions (crossing-point detection) ---
    ' Fires once when obstacle crosses PLAYER_X (NoteCleared prevents re-fire).
    ' Vertical check: if PlayerY + 12 > NOTE_Y, player's feet are below the
    ' note top = HIT. The 12px offset gives a 4px grace zone at the feet.
    ' On hit: detuned "dud" SFX on Ch1 (period + period/16 ≈ 1 semitone flat).
    FOR Slot = 0 TO 3
        IF NoteActive(Slot) THEN
            IF NoteCleared(Slot) = 0 THEN
                IF NoteX(Slot) < PLAYER_X THEN
                    ' Vertical: player body > note top = HIT (4px grace at feet)
                    IF PlayerY + 12 > NOTE_Y THEN
                        HitCount = HitCount + 1
                        DamageTaken = 1
                        NoteCleared(Slot) = 1
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
                        PRINT AT HeartPositions(MAX_HITS - HitCount), 0
                        IF HitCount >= MAX_HITS THEN GameOver = 1
                    END IF
                    ' Only mark cleared once note is well past player
                    IF NoteX(Slot) < PLAYER_X - 10 THEN NoteCleared(Slot) = 1
                END IF
            END IF
        END IF
    NEXT Slot

    ' --- Pencil collision (Level 2 only) ---
    ' Pencils hurt the player by falling on them (overlap check while falling).
    IF CurrentLevel = 1 THEN
        FOR Slot = 0 TO 1
            IF PencilState(Slot) = 1 THEN
                IF PencilCleared(Slot) = 0 THEN
                    ' Check X overlap: pencil 8px wide vs player 8px wide
                    IF PencilX(Slot) + 8 > PLAYER_X THEN
                        IF PencilX(Slot) < PLAYER_X + 8 THEN
                            ' Check Y overlap: pencil 8px tall vs player 16px tall
                            IF PencilY(Slot) + 8 > PlayerY THEN
                                IF PencilY(Slot) < PlayerY + 16 THEN
                                    HitCount = HitCount + 1
                                    DamageTaken = 1
                                    PencilCleared(Slot) = 1
                                    PencilState(Slot) = 0
                                    SPRITE Slot + 6, 0, 0, 0
                                    SOUND 1, 200, 12
                                    SfxTimer = 6
                                    PRINT AT HeartPositions(MAX_HITS - HitCount), 0
                                    IF HitCount >= MAX_HITS THEN GameOver = 1
                                END IF
                            END IF
                        END IF
                    END IF
                END IF
            END IF
        NEXT Slot
    END IF

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
        FOR Slot = 0 TO 3
            IF NoteActive(Slot) THEN ActiveCount = ActiveCount + 1
        NEXT Slot
        IF CurrentLevel = 1 THEN
            FOR Slot = 0 TO 1
                IF PencilState(Slot) THEN ActiveCount = ActiveCount + 1
            NEXT Slot
            IF FlowerState THEN ActiveCount = ActiveCount + 1
        END IF
        IF ActiveCount = 0 THEN
            SongEndTimer = SongEndTimer + 1
            IF SongEndTimer >= 30 THEN GameOver = 2  ' Brief pause then end
        END IF
    END IF

    GOTO MainLoop

    ' ==========================================
    ' End Screen (overlaid on game area)
    ' ==========================================
GameOverScreen:
    SOUND 0, 0, 0
    SOUND 1, 0, 0
    ' Hide all sprites except player (MOB 0)
    FOR Slot = 1 TO 7
        SPRITE Slot, 0, 0, 0
    NEXT Slot
    ' Clear play area (rows 1-6) but keep row 0 (hearts) and row 7 (ground)
    FOR Col = 20 TO 139
        PRINT AT Col, 0
    NEXT Col
    WAIT
    IF GameOver = 2 THEN
        ' Song complete — celebration pose
        SPRITE 0, PLAYER_X + SPR_VISIBLE, GROUND_Y + SPR_YSIZE, 4 * 8 + 2 + $0800
        IF DamageTaken = 0 THEN
            PRINT AT 163 COLOR 6, "PERFECT RUN!"
        ELSE
            PRINT AT 162 COLOR 5, "SONG COMPLETE!"
        END IF
        PRINT AT 183 COLOR 7, "PRESS TO REPLAY"
    ELSE
        ' Game over — normal pose
        SPRITE 0, PLAYER_X + SPR_VISIBLE, GROUND_Y + SPR_YSIZE, 0 * 8 + 2 + $0800
        PRINT AT 164 COLOR 2, "GAME OVER!"
        PRINT AT 183 COLOR 7, "PRESS TO RETRY"
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

AllMelodyData:
    ' === Level 0: Maple Leaf Rag ===
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

    ' === Level 1: Same melody as Maple Leaf Rag (obstacles differ) ===
    DATA 1438,    0, 1077,  539
    DATA  360,  539,  428,  360
    DATA 1017,  571,  360,  571
    DATA  480,  360,  807,    0
    DATA 1438,    0, 1077,  539
    DATA  360,  539,  428,  360
    DATA 1017,  571,  360,  571
    DATA  480,  360,  807,    0
    DATA 1438,  360, 1357,  539
    DATA  453,  339, 1438,  360
    DATA 1438,  360, 1357,  539
    DATA  453,  339, 1438,  360
    DATA    0,    0, 2155, 2155
    DATA 1812, 1077, 2155, 1077
    DATA  906,  539, 1077,  539
    DATA  453,  269,  539,  269
    DATA  226,  135,  135,    0
    DATA  135,    0,  135,    0
    DATA  135,  135,  428,  180
    DATA  160,  214,  180,  160
    DATA  428,  269,  453,  240
    DATA  226,  269,  240,  214
    DATA  428,  269,  214,  269
    DATA  240,    0,  269,    0
    DATA    0,  269,  906,    0
    DATA  269,    0,  269,    0
    DATA  269,  269,  855,  360
    DATA  320,  428,  360,  320
    DATA  855,  539,  906,  480
    DATA  453,  539,  480,  428
    DATA  855,  539,  428,  539
    DATA  480,    0,  539,    0

    ' === Level 2: Same melody as Maple Leaf Rag (obstacles differ) ===
    DATA 1438,    0, 1077,  539
    DATA  360,  539,  428,  360
    DATA 1017,  571,  360,  571
    DATA  480,  360,  807,    0
    DATA 1438,    0, 1077,  539
    DATA  360,  539,  428,  360
    DATA 1017,  571,  360,  571
    DATA  480,  360,  807,    0
    DATA 1438,  360, 1357,  539
    DATA  453,  339, 1438,  360
    DATA 1438,  360, 1357,  539
    DATA  453,  339, 1438,  360
    DATA    0,    0, 2155, 2155
    DATA 1812, 1077, 2155, 1077
    DATA  906,  539, 1077,  539
    DATA  453,  269,  539,  269
    DATA  226,  135,  135,    0
    DATA  135,    0,  135,    0
    DATA  135,  135,  428,  180
    DATA  160,  214,  180,  160
    DATA  428,  269,  453,  240
    DATA  226,  269,  240,  214
    DATA  428,  269,  214,  269
    DATA  240,    0,  269,    0
    DATA    0,  269,  906,    0
    DATA  269,    0,  269,    0
    DATA  269,  269,  855,  360
    DATA  320,  428,  360,  320
    DATA  855,  539,  906,  480
    DATA  453,  539,  480,  428
    DATA  855,  539,  428,  539
    DATA  480,    0,  539,    0

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

AllObstacleData:
    ' === Level 0: Maple Leaf Rag ===
    ' --- First half (bars 1-8): 9 obstacles (1 double) ---
    DATA 0,0,0,0, 0,0,0,0, 0,0,1,0, 0,0,0,0     ' M1-4:   pos 10 (D#5)
    DATA 0,0,0,0, 1,0,0,0, 0,0,1,0, 0,0,0,0     ' M5-8:   pos 20,26 (D#5,D#5)
    DATA 0,1,0,1, 0,0,0,0, 0,1,0,0, 0,0,0,1     ' M9-12:  pos 33,35,41,47 (D#5,D#5,D#5,D#5) DOUBLE
    DATA 0,0,0,0, 0,1,0,0, 0,0,0,0, 1,0,0,0     ' M13-16: pos 53,60 (G#3,B4 arpeggio)
    ' --- Second half (bars 9-16): 12 obstacles (4 doubles) ---
    DATA 0,0,0,0, 1,0,1,0, 0,0,0,0, 1,0,0,0     ' M17-20: pos 68,70,76 (G#6,G#6,F6) DOUBLE
    DATA 0,0,1,0, 1,0,0,0, 0,0,0,1, 0,0,0,0     ' M21-24: pos 82,84,91 (B4,B5,G#5) DOUBLE
    DATA 0,1,0,1, 0,0,0,0, 0,1,0,0, 0,0,0,0     ' M25-28: pos 97,99,105 (G#5,B3,G#5) DOUBLE
    DATA 1,0,1,0, 0,0,0,0, 0,1,0,0, 0,0,0,0     ' M29-32: pos 112,114,121 (C4,B3,G#4) DOUBLE

    ' === Level 1: Same obstacles as Level 0 (will be modified) ===
    DATA 0,0,0,0, 0,0,0,0, 0,0,1,0, 0,0,0,0
    DATA 0,0,0,0, 1,0,0,0, 0,0,1,0, 0,0,0,0
    DATA 0,1,0,1, 0,0,0,0, 0,1,0,0, 0,0,0,1
    DATA 0,0,0,0, 0,1,0,0, 0,0,0,0, 1,0,0,0
    DATA 0,0,0,0, 1,0,1,0, 0,0,0,0, 1,0,0,0
    DATA 0,0,1,0, 1,0,0,0, 0,0,0,1, 0,0,0,0
    DATA 0,1,0,1, 0,0,0,0, 0,1,0,0, 0,0,0,0
    DATA 1,0,1,0, 0,0,0,0, 0,1,0,0, 0,0,0,0

    ' === Level 2: Same obstacles as Level 0 (will be modified) ===
    DATA 0,0,0,0, 0,0,0,0, 0,0,1,0, 0,0,0,0
    DATA 0,0,0,0, 1,0,0,0, 0,0,1,0, 0,0,0,0
    DATA 0,1,0,1, 0,0,0,0, 0,1,0,0, 0,0,0,1
    DATA 0,0,0,0, 0,1,0,0, 0,0,0,0, 1,0,0,0
    DATA 0,0,0,0, 1,0,1,0, 0,0,0,0, 1,0,0,0
    DATA 0,0,1,0, 1,0,0,0, 0,0,0,1, 0,0,0,0
    DATA 0,1,0,1, 0,0,0,0, 0,1,0,0, 0,0,0,0
    DATA 1,0,1,0, 0,0,0,0, 0,1,0,0, 0,0,0,0

    ' ============================================
    ' Note Color Palette (5 cycling colors)
    ' ============================================

HeartPositions:
    DATA 19, 18, 17, 16, 15    ' Right-anchored: index 0=rightmost, fills leftward


LevelOffsets:
    DATA 0, 128, 256

    ' ============================================
    ' Graphics Data (GRAM cards 0-5, contiguous)
    ' ============================================

GramData:
    ' Card 0: Player (original alien — 8x8 stretched to 8x16 via YSIZE)
    BITMAP "..XXXX.."
    BITMAP ".XXXXXX."
    BITMAP "XX.XX.XX"
    BITMAP "XXXXXXXX"
    BITMAP "..XXXX.."
    BITMAP ".XXXXXX."
    BITMAP ".X.XX.X."
    BITMAP ".X....X."

    ' Card 1: Ground line
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"

    ' Card 2: Note obstacle (bold quarter note)
    BITMAP "...XX..."
    BITMAP "...XX..."
    BITMAP "...XX..."
    BITMAP "..XXXX.."
    BITMAP ".XXXXXX."
    BITMAP "XXXXXXXX"
    BITMAP ".XXXXXX."
    BITMAP "..XXXX.."

    ' Card 3: Heart (small, centered in card)
    BITMAP "........"
    BITMAP "..X..X.."
    BITMAP ".XXXXXX."
    BITMAP ".XXXXXX."
    BITMAP "..XXXX.."
    BITMAP "...XX..."
    BITMAP "........"
    BITMAP "........"

    ' Card 4: Player celebration (hands up!)
    BITMAP "X..XX..X"
    BITMAP ".XXXXXX."
    BITMAP "XX.XX.XX"
    BITMAP "XXXXXXXX"
    BITMAP "..XXXX.."
    BITMAP ".XXXXXX."
    BITMAP "..XXXX.."
    BITMAP "..X..X.."

    ' Card 5: Pencil (skinny symmetrical, point down)
    BITMAP "..XXXX.."
    BITMAP "..XXXX.."
    BITMAP "...XX..."
    BITMAP "...XX..."
    BITMAP "...XX..."
    BITMAP "...XX..."
    BITMAP "...XX..."
    BITMAP "...XX..."

    ' Card 6: Flower (healing power-up)
    BITMAP "..X.X..."
    BITMAP ".XXXXX.."
    BITMAP ".XXXXX.."
    BITMAP "..XXX..."
    BITMAP "...X...."
    BITMAP "...X...."
    BITMAP "..XX...."
    BITMAP "........"
