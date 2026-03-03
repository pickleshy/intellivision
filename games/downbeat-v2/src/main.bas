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

    OPTION MAP 2        ' 42K memory map — required for voice library + melody data

    ' --- Constants ---
    CONST PLAYER_X = 40
    CONST GROUND_Y = 56
    CONST JUMP_FRAMES = 36
    CONST NOTE_Y = 60           ' Note 8x8, sitting on ground line
    CONST NOTE_SPAWN_X = 168    ' Just off right edge
    CONST SCROLL_FRAC = 171     ' Fractional speed per frame (171/256)
                                ' Total: 1 + 171/256 = 1.668 px/frame = 100 px/sec
    CONST MAX_HITS = 5
    CONST FRAMES_PER_NOTE = 9   ' 16th note at 100 BPM (150ms per position)
    CONST MELODY_LENGTH = 128   ' Total 16th-note positions in full A strain (16 bars)
    CONST NOTE_VOLUME = 10      ' Background melody volume
    CONST SPAWN_OFFSET = 9      ' Spawn obstacles early to sync with melody
                                ' 128px / 1.668px/frame / 9 frames = ~8.5 beats
    CONST TUBA_IMMTIME = 300    ' Immunity duration: 5 seconds at 60fps

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
    HurtTimer = 0
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
    DIM NoteWobble(4)           ' Wobble timer per note slot (counts down from 12 on hit)
    DIM JumpMap(128)            ' Rehearsal: record jump positions


    ' Pencil system (Level 2: falling pencils)
    DIM PencilState(2)          ' 0=inactive, 1=falling
    DIM PencilX(2)
    DIM PencilY(2)
    DIM PencilFrac(2)           ' Fall tick (falling) / scroll fraction (grounded)
    DIM PencilCleared(2)        ' Collision flag

    ' Sneeze system (Level 5: random screen shake distraction)
    DIM SneezeTimer         ' Frames remaining in current shake (0-180)
    DIM SneezeSpawnTimer    ' Frames until next sneeze check (counts down)
    DIM SneezesSpawned      ' How many sneezes have occurred this level
    DIM SneezeX             ' X shake offset: 0-6, applied as (SneezeX-3) to sprites
    DIM SneezeY             ' Y shake offset: 0-6, applied as (SneezeY-3) to sprites
    DIM SneezeActive        ' Cached: does current level have sneezes? (0/1)
    DIM SneezeMaxSneezes    ' Cached: max sneezes for current level
    DIM SneezeStart         ' Cached: earliest beat for sneeze spawning
    DIM SneezeEnd           ' Cached: latest beat for sneeze spawning

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

    ' Per-stage hazard windows (loaded at level select)
    PencilWinStart = 0
    PencilWinEnd = 0
    FlowerWinStart = 0
    FlowerWinEnd = 0

    ' --- Color Stack mode: all black ---
    MODE 0, 0, 0, 0, 0
    WAIT

    ' --- Initialize Intellivoice (once at startup) ---
    IF VOICE.AVAILABLE THEN VOICE INIT

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
    HurtTimer = 0
    ButtonReleased = 1
    BeatCounter = 0
    SpawnCountdown = FRAMES_PER_NOTE
    SongDone = 0
    SongEndTimer = 0
    #CurPSG = 0
    #PrevPSG = 0
    MelodyMute = 0
    SOUND 0, , 0
    SOUND 1, , 0
    SOUND 2, , 0
    SneezeTimer = 0
    SneezesSpawned = 0
    SneezeX = 3
    SneezeY = 3
    SneezeSpawnTimer = RANDOM(120) + 180

    ' --- Tuba/immunity state ---
    tubaState = 0               ' 0=never spawned, 1=active, 2=collected/despawned
    tubaX = 0
    tubaY = 0
    tubaDriftX = 0
    tubaDriftY = 0
    tubaBobDir = 0              ' Bob direction: 0=going down, 1=going up
    tubaSpawnTimer = RANDOM(90) + 60
    #immunityTimer = 0
    ImmuneFlash = 0
    FanfareStep = 0
    FanfareTimer = 0

    ' --- Clear screen ---
    CLS
    WAIT

    ' --- Define GRAM cards 0-8 (player, ground, note, heart, celebration, pencil, flower, scream, tuba) ---
    DEFINE 0, 9, GramData
    WAIT

    ' --- Initialize all note slots ---
    FOR Slot = 0 TO 3
        NoteActive(Slot) = 0
        NoteCleared(Slot) = 0
        NoteWobble(Slot) = 0
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
    PRINT AT 122 COLOR 3, "2 B STRAIN"
    PRINT AT 142 COLOR 3, "3 A TO C STRAIN"
    PRINT AT 162 COLOR 3, "4 C TO D HARD"
    PRINT AT 182 COLOR 2, "5 D STRAIN HARDEST"

    ' Let ISR settle on cold boot, then drain any held key
    FOR Slot = 0 TO 29
        WAIT
    NEXT Slot
LevelRelease:
    WAIT
    IF CONT.key < 12 THEN GOTO LevelRelease

LevelSelect:
    WAIT
    IF CONT.key = 1 THEN CurrentLevel = 0 : GOTO LevelConfirm
    IF CONT.key = 2 THEN CurrentLevel = 1 : GOTO LevelConfirm
    IF CONT.key = 3 THEN CurrentLevel = 2 : GOTO LevelConfirm
    IF CONT.key = 4 THEN CurrentLevel = 3 : GOTO LevelConfirm
    IF CONT.key = 5 THEN CurrentLevel = 4 : GOTO LevelConfirm
    GOTO LevelSelect

LevelConfirm:
    #LevelOffset = LevelOffsets(CurrentLevel)
    PencilWinStart = PencilWindowStarts(CurrentLevel)
    PencilWinEnd = PencilWindowEnds(CurrentLevel)
    FlowerWinStart = FlowerWindowStarts(CurrentLevel)
    FlowerWinEnd = FlowerWindowEnds(CurrentLevel)
    SneezeActive = SneezeEnabled(CurrentLevel)
    SneezeMaxSneezes = SneezeMaxCount(CurrentLevel)
    SneezeStart = SneezeStartBeat(CurrentLevel)
    SneezeEnd = SneezeEndBeat(CurrentLevel)
    TubaWinStart = TubaWindowStarts(CurrentLevel)
    TubaWinEnd = TubaWindowEnds(CurrentLevel)
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

    ' --- Pre-spawn notes for beat positions 0 to SPAWN_OFFSET-1 ---
    ' Normal spawn logic reads SPAWN_OFFSET beats ahead of BeatCounter,
    ' so beats 0-8 are never reached. Pre-place them at the X position
    ' they would occupy if they had been spawned before the game started.
    ' Formula: StartX = NOTE_SPAWN_X - (SPAWN_OFFSET - beat) * 15
    ' (15 px/beat = FRAMES_PER_NOTE * scroll_speed ≈ 9 * 1.668)
    FOR Col = 0 TO SPAWN_OFFSET - 1
        IF AllObstacleData(#LevelOffset + Col) = 1 THEN
            HurtTimer = NOTE_SPAWN_X - (SPAWN_OFFSET - Col) * 15
            IF HurtTimer > PLAYER_X THEN
                FreeSlot = 255
                FOR Slot = 0 TO 3
                    IF NoteActive(Slot) = 0 THEN
                        IF FreeSlot = 255 THEN FreeSlot = Slot
                    END IF
                NEXT Slot
                IF FreeSlot < 255 THEN
                    NoteActive(FreeSlot) = 1
                    NoteX(FreeSlot) = HurtTimer
                    NoteFrac(FreeSlot) = 0
                    NoteCleared(FreeSlot) = 0
                    NoteWobble(FreeSlot) = 0
                    #NotePitch(FreeSlot) = AllMelodyData(#LevelOffset + Col)
                    NoteColor(FreeSlot) = 1
                END IF
            END IF
        END IF
    NEXT Col
    HurtTimer = 0

    ' ==========================================
    ' Main loop
    ' ==========================================
MainLoop:
    WAIT
    IF GameOver THEN GOSUB GameOverScreen : GOTO RestartGame

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
            IF #immunityTimer > 0 THEN SpawnCountdown = 7 ELSE SpawnCountdown = FRAMES_PER_NOTE

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

    ' --- Pencil spawn (Stages 2+) ---
    IF CurrentLevel >= 1 THEN
        IF PencilsSpawned < 2 AND SongDone = 0 THEN
            IF BeatCounter >= PencilWinStart AND BeatCounter < PencilWinEnd THEN
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

    ' --- Flower spawn (Stages 2+) ---
    IF CurrentLevel >= 1 THEN
        IF FlowerState = 0 AND FlowersSpawned < 2 AND SongDone = 0 AND tubaState <> 1 THEN
            IF BeatCounter >= FlowerWinStart AND BeatCounter < FlowerWinEnd THEN
                IF FlowerSpawnTimer > 0 THEN
                    FlowerSpawnTimer = FlowerSpawnTimer - 1
                END IF
                IF FlowerSpawnTimer = 0 THEN
                    ' Don't spawn while a pencil is falling
                    IF PencilState(0) = 1 OR PencilState(1) = 1 THEN
                        FlowerSpawnTimer = 30
                    ELSE
                        FlowerState = 1
                        FlowerX = RANDOM(60) + 100
                        FlowerY = 0
                        FlowerDriftY = 0
                        FlowersSpawned = FlowersSpawned + 1
                        FlowerSpawnTimer = RANDOM(180) + 300
                    END IF
                END IF
            END IF
        END IF
    END IF

    ' --- Sneeze distraction (Level 5) ---
    ' SneezeX/Y are offsets stored as 0-6; applied as (val-3) to sprites,
    ' giving -3 to +3 pixels of shake. Default 3 = zero offset (no shake).
    IF SneezeActive THEN
        IF SneezeTimer > 0 THEN
            SneezeTimer = SneezeTimer - 1
            SneezeX = RANDOM(7)
            SneezeY = RANDOM(7)
            IF SneezeTimer = 0 THEN     ' Sneeze just ended — reset to zero offset
                SneezeX = 3
                SneezeY = 3
            END IF
        ELSE
            IF SneezesSpawned < SneezeMaxSneezes AND SongDone = 0 THEN
                IF BeatCounter >= SneezeStart AND BeatCounter <= SneezeEnd THEN
                    IF SneezeSpawnTimer > 0 THEN
                        SneezeSpawnTimer = SneezeSpawnTimer - 1
                    ELSE
                        SneezeTimer = 180
                        SneezesSpawned = SneezesSpawned + 1
                        SneezeSpawnTimer = RANDOM(120) + 360
                        IF VOICE.AVAILABLE THEN
                            IF VOICE.PLAYING = 0 THEN VOICE PLAY SneezePhrase
                        END IF
                    END IF
                END IF
            END IF
        END IF
    END IF

    ' --- Tuba spawn (procedure in Seg 1) ---
    GOSUB SpawnTuba

    ' --- Immunity timer (counts down from TUBA_IMMTIME each frame) ---
    IF #immunityTimer > 0 THEN
        #immunityTimer = #immunityTimer - 1
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
                ' Rehearsal mode: show beat number on screen (set to 255 = disabled)
                IF CurrentLevel = 255 THEN
                    PRINT AT 200 COLOR 6, "BEAT "
                    PRINT AT 205 COLOR 7, <> BeatCounter
                    PRINT AT 208, 0 : PRINT AT 209, 0
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

    ' --- Update player sprite (compute card first, single SPRITE call saves ROM) ---
    IF SongEndTimer > 0 AND DamageTaken = 0 THEN
        #PlayerCard = 4 * 8 + 2 + $0800    ' Celebration
    ELSEIF HurtTimer > 0 THEN
        #PlayerCard = 7 * 8 + 2 + $0800    ' Scream
    ELSEIF #immunityTimer > 0 THEN
        ' Flash yellow<->white. Faster in last 2 seconds (< 120 frames).
        ImmuneFlash = ImmuneFlash + 1
        IF #immunityTimer < 120 THEN
            IF ImmuneFlash >= 8 THEN ImmuneFlash = 0
            IF ImmuneFlash < 4 THEN
                #PlayerCard = 0 * 8 + 6 + $0800  ' Yellow fast
            ELSE
                #PlayerCard = 0 * 8 + 7 + $0800  ' White fast
            END IF
        ELSE
            IF ImmuneFlash >= 16 THEN ImmuneFlash = 0
            IF ImmuneFlash < 8 THEN
                #PlayerCard = 0 * 8 + 6 + $0800  ' Yellow slow
            ELSE
                #PlayerCard = 0 * 8 + 7 + $0800  ' White slow
            END IF
        END IF
    ELSE
        #PlayerCard = 0 * 8 + 2 + $0800    ' Normal red
    END IF
    SPRITE 0, PLAYER_X + SneezeX - 3 + SPR_VISIBLE, PlayerY + SneezeY - 3 + SPR_YSIZE, #PlayerCard

    ' --- Immunity countdown text ---
    ' Fires at exact timer values (once per threshold crossing).
    ' Placed AFTER sprite card block so ImmuneFlash=60 isn't reset by flash code.
    IF #immunityTimer = 180 THEN PRINT AT 184 COLOR 6, "MORTAL IN 3"
    IF #immunityTimer = 120 THEN PRINT AT 184 COLOR 6, "MORTAL IN 2"
    IF #immunityTimer = 60 THEN PRINT AT 184 COLOR 6, "MORTAL IN 1"
    IF #immunityTimer = 1 THEN
        PRINT AT 183 COLOR 2, "YOU ARE MORTAL"
        ImmuneFlash = 60        ' Repurpose ImmuneFlash as clear-delay timer
    END IF
    IF #immunityTimer = 0 AND ImmuneFlash > 0 THEN
        ImmuneFlash = ImmuneFlash - 1
        IF ImmuneFlash = 0 THEN
            FOR Col = 183 TO 196
                PRINT AT Col, 0
            NEXT Col
        END IF
    END IF

    ' --- Scroll obstacles ---
    ' Fixed-point scrolling: each frame adds SCROLL_FRAC (171) to NoteFrac.
    ' When NoteFrac overflows 256, move 2px instead of 1px.
    ' Effective speed: 1 + 171/256 = 1.668 px/frame ≈ 100 px/sec.
    ' 5 sprite slots (MOBs 1-5) are recycled as notes scroll off-screen.
    FOR Slot = 0 TO 3
        IF NoteActive(Slot) THEN
            IF #immunityTimer > 0 THEN NoteFrac(Slot) = NoteFrac(Slot) + 220 ELSE NoteFrac(Slot) = NoteFrac(Slot) + SCROLL_FRAC
            IF NoteFrac(Slot) >= 256 THEN
                NoteFrac(Slot) = NoteFrac(Slot) - 256
                NoteX(Slot) = NoteX(Slot) - 2
            ELSE
                NoteX(Slot) = NoteX(Slot) - 1
            END IF

            ' Deactivate at left edge: < 8 for normal exit, > 200 catches 8-bit unsigned wrap (e.g. 1-2=255)
            IF NoteX(Slot) < 8 OR NoteX(Slot) > 200 THEN
                NoteActive(Slot) = 0
                NoteWobble(Slot) = 0
                SPRITE Slot + 1, 0, 0, 0
            ELSEIF NoteWobble(Slot) > 0 THEN
                NoteWobble(Slot) = NoteWobble(Slot) - 1
                IF NoteWobble(Slot) AND 1 THEN
                    SPRITE Slot + 1, NoteX(Slot) + 2 + SneezeX - 3 + SPR_VISIBLE, NOTE_Y + SneezeY - 3, 2 * 8 + NoteColor(Slot) + $0800 + $1000
                ELSE
                    SPRITE Slot + 1, NoteX(Slot) - 2 + SneezeX - 3 + SPR_VISIBLE, NOTE_Y + SneezeY - 3, 2 * 8 + NoteColor(Slot) + $0800 + $1000
                END IF
            ELSE
                SPRITE Slot + 1, NoteX(Slot) + SneezeX - 3 + SPR_VISIBLE, NOTE_Y + SneezeY - 3, 2 * 8 + NoteColor(Slot) + $0800 + $1000
            END IF
        END IF
    NEXT Slot

    ' --- Update pencils (Level 2 only) ---
    ' Pencils fall through the ground and off-screen. They only hurt
    ' the player by landing on them mid-fall — no grounded obstacles.
    IF CurrentLevel >= 1 THEN
        FOR Slot = 0 TO 1
            IF PencilState(Slot) = 1 THEN
                ' Scroll left with the world
                IF #immunityTimer > 0 THEN PencilFrac(Slot) = PencilFrac(Slot) + 220 ELSE PencilFrac(Slot) = PencilFrac(Slot) + SCROLL_FRAC
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
                        SPRITE Slot + 6, PencilX(Slot) + SneezeX - 3 + SPR_VISIBLE, PencilY(Slot) + SneezeY - 3, 5 * 8 + 6 + $0800
                    END IF
                END IF
            END IF
        NEXT Slot
    END IF

    ' --- Update flower (Stages 2+) ---
    IF CurrentLevel >= 1 THEN
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
                    SPRITE 5, FlowerX + SneezeX - 3 + SPR_VISIBLE, FlowerY + SneezeY - 3, 6 * 8 + 4 + $0800 + $1000
                END IF
            END IF

            ' --- Flower collection ---
            IF FlowerState = 1 THEN
                ' Check overlap: player at (PLAYER_X, PlayerY) 8x16
                ' Flower at (FlowerX, FlowerY) 8x8
                IF FlowerX + 8 > PLAYER_X THEN
                    IF FlowerX < PLAYER_X + 8 THEN
                        IF FlowerY + 8 > PlayerY THEN
                            IF FlowerY < PlayerY + 16 THEN
                                ' Collected! Heal 1 heart
                                FlowerState = 0
                                SPRITE 5, 0, 0, 0
                                IF HitCount > 0 THEN
                                    HitCount = HitCount - 1
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

    ' --- Update tuba (procedure in Seg 1) ---
    GOSUB UpdateTuba

    ' --- Check collisions (overlap detection) ---
    ' Note sprite: [NoteX, NoteX+8]. Player sprite: [PLAYER_X, PLAYER_X+8] = [40, 48].
    ' First overlap: NoteX < PLAYER_X + 8 (note right edge enters player space).
    ' Last overlap:  NoteX > PLAYER_X - 8 (note left edge exits player space, i.e. NoteX >= 32).
    ' Active window: NoteX in (32, 48). Clear at NoteX < 32 (note fully past player).
    ' Vertical check: if PlayerY + 12 > NOTE_Y, player's feet are below the
    ' note top = HIT. The 12px offset gives a 4px grace zone at the feet.
    ' On hit: detuned "dud" SFX on Ch1 (period + period/16 ≈ 1 semitone flat).
    FOR Slot = 0 TO 3
        IF NoteActive(Slot) THEN
            IF NoteCleared(Slot) = 0 THEN
                IF NoteX(Slot) < PLAYER_X + 8 THEN
                    ' Vertical: player body > note top = HIT (4px grace at feet)
                    ' Skip damage if immunity is active — player runs through freely.
                    IF #immunityTimer = 0 THEN
                        IF PlayerY + 12 > NOTE_Y THEN
                            HitCount = HitCount + 1
                            DamageTaken = 1
                            NoteCleared(Slot) = 1
                            NoteWobble(Slot) = 12
                            HurtTimer = 10
                            ' Dud sound: flat by ~1 semitone on Channel B
                            IF #NotePitch(Slot) > 0 THEN
                                SOUND 1, #NotePitch(Slot) + #NotePitch(Slot) / 16, 12
                            ELSE
                                SOUND 1, 200, 12
                            END IF
                            SfxTimer = 6
                            ' Ouch voice
                            IF VOICE.AVAILABLE THEN
                                IF VOICE.PLAYING = 0 THEN VOICE PLAY OuchPhrase
                            END IF
                            ' Remove a heart (rightmost first)
                            PRINT AT HeartPositions(MAX_HITS - HitCount), 0
                            IF HitCount >= MAX_HITS THEN GameOver = 1
                        END IF
                    END IF
                    ' Clear once note has fully exited player space (NoteX < PLAYER_X - 8 = 32)
                    IF NoteX(Slot) < PLAYER_X - 8 THEN NoteCleared(Slot) = 1
                END IF
            END IF
        END IF
    NEXT Slot

    ' --- Pencil collision (Stages 2+) ---
    ' Pencils hurt the player by falling on them (overlap check while falling).
    IF CurrentLevel >= 1 THEN
        FOR Slot = 0 TO 1
            IF PencilState(Slot) = 1 THEN
                IF PencilCleared(Slot) = 0 THEN
                    ' Skip damage if immunity is active — pencil passes through.
                    IF #immunityTimer = 0 THEN
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
                                        HurtTimer = 10
                                        SOUND 1, 200, 12
                                        SfxTimer = 6
                                        IF VOICE.AVAILABLE THEN
                            IF VOICE.PLAYING = 0 THEN VOICE PLAY OuchPhrase
                        END IF
                                        PRINT AT HeartPositions(MAX_HITS - HitCount), 0
                                        IF HitCount >= MAX_HITS THEN GameOver = 1
                                    END IF
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

    ' --- Fanfare sequencer (procedure in Seg 1) ---
    GOSUB FanfareUpdate

    ' --- Hurt timer (scream sprite on player) ---
    IF HurtTimer > 0 THEN HurtTimer = HurtTimer - 1

    ' --- Check song completion ---
    ' After all 128 beats are spawned (SongDone=1), wait for remaining
    ' obstacles to scroll off-screen, then pause 0.5 sec before ending.
    IF SongDone THEN
        SOUND 0, , 0              ' Silence melody — song is over
        ActiveCount = 0
        FOR Slot = 0 TO 3
            IF NoteActive(Slot) THEN ActiveCount = ActiveCount + 1
        NEXT Slot
        IF CurrentLevel >= 1 THEN
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

    ' ============================================
    ' Data
    ' ============================================

JumpArc:
    DATA 0, 2, 4, 6, 8, 10, 11, 13, 14, 15, 16, 17, 18, 19, 19, 20, 20, 20
    DATA 20, 20, 20, 19, 19, 18, 17, 16, 15, 14, 13, 11, 10, 8, 6, 4, 2, 0

OuchPhrase:
    VOICE AW,PA1,0

SneezePhrase:
    VOICE AA,CH,UW2,PA1,0

' --- End screen voice phrases ---
EncorePhrase:
    VOICE AA,NN1,KK2,OR,PA1,0
BravoPhrase:
    VOICE PP,RR1,AA,VV,OW,PA2,BB1,EH,LL,IY,SS,IY,MM,OW,PA1,0
CarnegiePhrase:
    VOICE KK1,AR,NN1,EH,GG1,IY,PA2,HH1,AO,LL,PA2,LL,UH,KK3,SS,PA2,GG1,UH,DD1,PA2,AO,NN1,PA2,YY1,UW2,PA1,0
NeedsPracticePhrase:
    VOICE NN1,EY,DD1,SS,PA2,PP,RR1,AA,KK2,TT1,IH,SS,PA1,0
TechniquePhrase:
    VOICE TT2,EH,KK3,NN1,IY,KK3,PA2,NN1,IY,DD1,ZZ,PA2,WW,ER2,KK3,PA1,0
PracticeScalesPhrase:
    VOICE PP,RR1,AX,KK3,TT2,IH,SS,PA2,MM,OR,PA2,SS,KK3,EY,LL,ZZ,PA1,0

    SEGMENT 1           ' Melody + obstacle data tables overflow to $A000-$BFFF

    ' ============================================
    ' SpawnTuba - Spawn Golden Tuba of Immunity
    ' Called each frame from main loop.
    ' ============================================
SpawnTuba: PROCEDURE
    IF TubaWinEnd = 0 THEN RETURN     ' Feature disabled for this level
    IF tubaState > 0 THEN RETURN      ' Already spawned or on screen this session
    IF SongDone THEN RETURN           ' Song over
    IF FlowerState THEN RETURN        ' Flower using MOB 5
    IF BeatCounter < TubaWinStart THEN RETURN
    IF BeatCounter > TubaWinEnd THEN RETURN
    IF tubaSpawnTimer > 0 THEN
        tubaSpawnTimer = tubaSpawnTimer - 1
        RETURN
    END IF
    ' Spawn: enters from top of screen, drifts left as it falls into bob zone
    tubaState = 1
    tubaX = RANDOM(60) + 100    ' Spawn 100-159, same range as flower
    tubaY = 0               ' Starts above screen, falls into bob zone
    tubaDriftX = 0
    tubaDriftY = 0
    tubaBobDir = 0           ' Initially falling down
    RETURN
END

    ' ============================================
    ' UpdateTuba - Drift, despawn, collect check
    ' Called each frame from main loop.
    ' ============================================
UpdateTuba: PROCEDURE
    IF tubaState <> 1 THEN RETURN
    ' Drift left every 2 frames (same speed as flower)
    tubaDriftX = tubaDriftX + 1
    IF tubaDriftX >= 2 THEN
        tubaDriftX = 0
        IF tubaX > 0 THEN tubaX = tubaX - 1
    END IF
    ' Vertical: fall from top until Y=30 (bob zone entry), then oscillate 30<->50
    ' Fall phase: move down 1px every 2 frames until tubaY >= 30
    ' Bob phase:  oscillate 1px every 4 frames between 30 and 50
    '   Y=30 (top): catchable at jump peak (PlayerY=36, overlap: 30+8=38 > 36)
    '   Y=50 (bot): catchable while standing (PlayerY=56, overlap: 50+8=58 > 56)
    tubaDriftY = tubaDriftY + 1
    IF tubaY < 30 THEN
        ' Falling into bob zone
        IF tubaDriftY >= 2 THEN
            tubaDriftY = 0
            tubaY = tubaY + 1
        END IF
    ELSE
        ' Bobbing: oscillate between 30 and 50
        IF tubaDriftY >= 4 THEN
            tubaDriftY = 0
            IF tubaBobDir = 0 THEN
                IF tubaY < 50 THEN
                    tubaY = tubaY + 1
                ELSE
                    tubaBobDir = 1
                END IF
            ELSE
                IF tubaY > 30 THEN
                    tubaY = tubaY - 1
                ELSE
                    tubaBobDir = 0
                END IF
            END IF
        END IF
    END IF
    ' Despawn if off-screen left
    IF tubaX < 2 THEN
        tubaState = 2
        SPRITE 5, 0, 0, 0
        RETURN
    END IF
    ' Collection detection (player box [PLAYER_X..PLAYER_X+8] x [PlayerY..PlayerY+16])
    IF tubaX + 8 > PLAYER_X THEN
        IF tubaX < PLAYER_X + 8 THEN
            IF tubaY + 8 > PlayerY THEN
                IF tubaY < PlayerY + 16 THEN
                    ' Collected! Grant immunity and start fanfare
                    tubaState = 2
                    SPRITE 5, 0, 0, 0
                    #immunityTimer = TUBA_IMMTIME
                    FanfareStep = 1
                    FanfareTimer = 0
                    RETURN
                END IF
            END IF
        END IF
    END IF
    ' Update sprite (apply sneeze offset for visual consistency)
    SPRITE 5, tubaX + SneezeX - 3 + SPR_VISIBLE, tubaY + SneezeY - 3, 8 * 8 + 6 + $0800
    RETURN
END

    ' ============================================
    ' FanfareUpdate - C-E-G-C ascending fanfare on PSG Channel 2
    ' Called each frame from main loop.
    ' ============================================
FanfareUpdate: PROCEDURE
    IF FanfareStep = 0 THEN RETURN
    IF FanfareTimer > 0 THEN
        FanfareTimer = FanfareTimer - 1
        RETURN
    END IF
    ' Execute current step
    IF FanfareStep = 1 THEN
        SOUND 2, 855, 15    ' C4
        FanfareTimer = 8
        FanfareStep = 2
    ELSEIF FanfareStep = 2 THEN
        SOUND 2, 679, 15    ' E4
        FanfareTimer = 8
        FanfareStep = 3
    ELSEIF FanfareStep = 3 THEN
        SOUND 2, 571, 15    ' G4
        FanfareTimer = 8
        FanfareStep = 4
    ELSEIF FanfareStep = 4 THEN
        SOUND 2, 428, 15    ' C5
        FanfareTimer = 12
        FanfareStep = 5
    ELSE
        SOUND 2, , 0        ' Silence after fanfare complete
        FanfareStep = 0
    END IF
    RETURN
END

    ' ============================================
    ' GameOverScreen - End screen (game over or song complete)
    ' Called via GOSUB; RETURN leads back to RestartGame.
    ' ============================================
GameOverScreen: PROCEDURE
    SOUND 0, , 0
    SOUND 1, , 0
    SOUND 2, , 0
    #immunityTimer = 0
    FanfareStep = 0
    ImmuneFlash = 0
    ' Hide all sprites except player (MOB 0)
    FOR Slot = 1 TO 7
        SPRITE Slot, 0, 0, 0
    NEXT Slot
    ' Clear play area (rows 1-6) but keep row 0 (hearts) and row 7 (ground)
    FOR Col = 20 TO 139
        PRINT AT Col, 0
    NEXT Col
    WAIT
    ' --- End screen subtitle + voice (per-level, deterministic) ---
    ' Levels 0-1: Encore / Needs Practice
    ' Levels 2-3: Bravo Bellissimo / Technique Needs Work
    ' Level  4:   Carnegie Hall / Practice More Scales
    IF GameOver = 2 THEN
        IF CurrentLevel <= 1 THEN PRINT AT 26 COLOR 6, "ENCORE!"
        IF CurrentLevel = 2 OR CurrentLevel = 3 THEN PRINT AT 21 COLOR 6, "BRAVO BELLISSIMO!"
        IF CurrentLevel >= 4 THEN PRINT AT 23 COLOR 6, "CARNEGIE HALL!"
        IF VOICE.AVAILABLE THEN
            IF CurrentLevel <= 1 THEN VOICE PLAY EncorePhrase
            IF CurrentLevel = 2 OR CurrentLevel = 3 THEN VOICE PLAY BravoPhrase
            IF CurrentLevel >= 4 THEN VOICE PLAY CarnegiePhrase
        END IF
    ELSE
        IF CurrentLevel <= 1 THEN PRINT AT 23 COLOR 2, "NEEDS PRACTICE"
        IF CurrentLevel = 2 OR CurrentLevel = 3 THEN PRINT AT 20 COLOR 2, "TECHNIQUE NEEDS WORK"
        IF CurrentLevel >= 4 THEN PRINT AT 20 COLOR 2, "PRACTICE MORE SCALES"
        IF VOICE.AVAILABLE THEN
            IF CurrentLevel <= 1 THEN VOICE PLAY NeedsPracticePhrase
            IF CurrentLevel = 2 OR CurrentLevel = 3 THEN VOICE PLAY TechniquePhrase
            IF CurrentLevel >= 4 THEN VOICE PLAY PracticeScalesPhrase
        END IF
    END IF
    IF GameOver = 2 THEN
        ' Song complete — celebration pose
        SPRITE 0, PLAYER_X + SPR_VISIBLE, GROUND_Y + SPR_YSIZE, 4 * 8 + 2 + $0800
        IF CurrentLevel = 255 THEN
            ' Rehearsal mode: show jump beat map
            SPRITE 0, 0, 0, 0
            PRINT AT 22 COLOR 6, "JUMP BEATS:"
            Col = 40
            FOR Slot = 0 TO 127
                IF JumpMap(Slot) THEN
                    IF Col < 220 THEN
                        PRINT AT Col COLOR 7, <> Slot
                        IF Slot >= 100 THEN
                            Col = Col + 4
                        ELSEIF Slot >= 10 THEN
                            Col = Col + 3
                        ELSE
                            Col = Col + 2
                        END IF
                    END IF
                END IF
            NEXT Slot
        ELSE
            IF DamageTaken = 0 THEN
                PRINT AT 163 COLOR 6, "PERFECT RUN!"
            ELSE
                PRINT AT 162 COLOR 5, "SONG COMPLETE!"
            END IF
        END IF
        PRINT AT 183 COLOR 7, "PRESS TO REPLAY"
    ELSE
        ' Game over — normal pose
        SPRITE 0, PLAYER_X + SPR_VISIBLE, GROUND_Y + SPR_YSIZE, 0 * 8 + 2 + $0800
        PRINT AT 164 COLOR 2, "GAME OVER!"
        PRINT AT 183 COLOR 7, "PRESS TO RETRY"
    END IF
    ' --- Rehearsal mode: hold end screen for 10 seconds ---
    IF CurrentLevel = 255 AND GameOver = 2 THEN
        FOR Slot = 0 TO 599
            WAIT
        NEXT Slot
    END IF
    ' --- Wait for button release then press ---
GameOverRelease:
    WAIT
    IF CONT.BUTTON THEN GOTO GameOverRelease
GameOverWait:
    WAIT
    IF CONT.BUTTON = 0 THEN GOTO GameOverWait
    RETURN
END

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

    ' === Stage 1: B Strain (B-to-A from stage2_b_to_a_final.mid) ===
    ' --- B section (bars 1-8) ---
    DATA  360,  360,  960,  285   ' M01: D#5  D#5  A#3  G5
    DATA  180,  285,  240,  190   ' M01: D#6  G5   A#5  D6
    DATA  190,  285,  202,  285   ' M02: D6   G5   C#6  G5
    DATA  240,  214,  214,  360   ' M02: A#5  C6   C6   D#5
    DATA  240,  360, 1077,  428   ' M03: A#5  D#5  G#3  C5
    DATA  269,  428,  360,  320   ' M03: G#5  C5   D#5  F5
    DATA  320,  428,  269,  428   ' M04: F5   C5   G#5  C5
    DATA  360,  320,  320,  428   ' M04: D#5  F5   F5   C5
    DATA  320,  320,  960,  360   ' M05: F5   F5   A#3  D#5
    DATA  285,  480,  404,  320   ' M05: G5   A#4  C#5  F5
    DATA  320,  360,  285,  480   ' M06: F5   D#5  G5   A#4
    DATA  404,  320,  320,  404   ' M06: C#5  F5   F5   C#5
    DATA  320,  320,  855,  428   ' M07: F5   F5   C4   C5
    DATA  269,  428,  360,  320   ' M07: G#5  C5   D#5  F5
    DATA  320,  428,  269,  428   ' M08: F5   C5   G#5  C5
    DATA  360,  320,  320,  428   ' M08: D#5  F5   F5   C5
    ' --- A section return (bars 9-16) ---
    DATA  320,  320,  960,  285   ' M09: F5   F5   A#3  G5
    DATA  180,  285,  240,  190   ' M09: D#6  G5   A#5  D6
    DATA  190,  285,  202,  285   ' M10: D6   G5   C#6  G5
    DATA  240,  214,  214,  360   ' M10: A#5  C6   C6   D#5
    DATA  240,  360, 1077,  428   ' M11: A#5  D#5  G#3  C5
    DATA  269,  428,  360,  320   ' M11: G#5  C5   D#5  F5
    DATA  320,  428,  269,  269   ' M12: F5   C5   G#5  G#5
    DATA  269,  269,  285,  285   ' M12: G#5  G#5  G5   G5
    DATA  302,  302, 1281,  641   ' M13: F#5  F#5  F3   F4
    DATA  508,  428,  320,  428   ' M13: A4   C5   F5   C5
    DATA  508,  641,  960,  641   ' M14: A4   F4   A#3  F4
    DATA  480,  404,  320,  320   ' M14: A#4  C#5  F5   F5
    DATA  404,  404,  428,  428   ' M15: C#5  C#5  C5   C5
    DATA  960,  428, 1438,  480   ' M15: A#3  C5   D#3  A#4
    DATA  480,  719, 1077,  539   ' M16: A#4  D#4  G#3  G#4
    DATA  428,  360,  269,  269   ' M16: C5   D#5  G#5  G#5

    ' === Stage 2: A-to-C Strain (from stage3_a_to_c_final.mid) ===
    ' --- First half (bars 1-8): Theme + Contrast + Arpeggio ---
    DATA 1438,1438,1077,  539,  360,  539,  428,  360   ' M01: D#3 D#3 G#3 G#4 D#5 G#4 C5 D#5
    DATA  360,  571,  360,  571,  480,  360,  360,  360   ' M02: D#5 G4 D#5 G4 A#4 D#5 D#5 D#5
    DATA  360,  360, 1077,  539,  360,  539,  428,  360   ' M03: D#5 D#5 G#3 G#4 D#5 G#4 C5 D#5
    DATA  360,  571,  360,  571,  480,  360,  360,  360   ' M04: D#5 G4 D#5 G4 A#4 D#5 D#5 D#5
    DATA 1438,  360, 1357,  539,  453,  339, 1438,  360   ' M05: D#3 D#5 E3 G#4 B4 E5 D#3 D#5
    DATA 1438,  360, 1357,  539,  453,  339, 1438,  360   ' M06: D#3 D#5 E3 G#4 B4 E5 D#3 D#5
    DATA    0,    0, 2155, 2155, 1812, 1077, 2155, 1077   ' M07: --- --- G#2 G#2 B2 G#3 G#2 G#3
    DATA  906,  539, 1077,  539,  453,  269,  539,  269   ' M08: B3 G#4 G#3 G#4 B4 G#5 G#4 G#5
    ' --- Second half (bars 9-16): High chord + melody + resolution ---
    DATA  226,  135,  135,  135,  135,  135,  135,  135   ' M09: B5 G#6 G#6 G#6 G#6 G#6 G#6 G#6
    DATA  135,  135,  135,  180,  160,  214,  180,  160   ' M10: G#6 G#6 G#6 D#6 F6 C6 D#6 F6
    DATA  160,  269,  269,  240,  226,  269,  240,  214   ' M11: F6 G#5 G#5 A#5 B5 G#5 A#5 C6
    DATA  214,  269,  214,  269,  240,  240,  269,  269   ' M12: C6 G#5 C6 G#5 A#5 A#5 G#5 G#5
    DATA    0,  269,  269,  269,  269,  269,  269,  269   ' M13: --- G#5 G#5 G#5 G#5 G#5 G#5 G#5
    DATA  269,  269,  269,  360,  320,  428,  360,  320   ' M14: G#5 G#5 G#5 D#5 F5 C5 D#5 F5
    DATA  320,  539,  539,  480,  453,  539,  480,  428   ' M15: F5 G#4 G#4 A#4 B4 G#4 A#4 C5
    DATA  428,  539,  428,  539,  480,  480,  539,  539   ' M16: C5 G#4 C5 G#4 A#4 A#4 G#4 G#4

    ' === Stage 3: C-to-D Strain [hard] (36 obstacles) ===
    DATA    0,  269,  320,  269,  428,  360,  269,    0   ' pos 0-7
    DATA  428,  480,  539,  269,  428,  360,  269,    0   ' pos 8-15
    DATA  428,  480,  428,  539,  404,  480,  404,  320   ' pos 16-23
    DATA  539,  404,  320,  480,  404,  320,  539,  404   ' pos 24-31
    DATA  320,  480,  320,  269,  539,  428,  269,    0   ' pos 32-39
    DATA  428,  480,  539,  269,  539,  428,  269,    0   ' pos 40-47
    DATA  428,  480,  428,  539,  404,  480,  404,  320   ' pos 48-55
    DATA  539,  404,  320,  480,  404,  320,  539,  480   ' pos 56-63
    DATA  320,  508,  320,  240,  480,  381,  240,    0   ' pos 64-71
    DATA  320,  428,  480,  240,  381,  320,  240,    0   ' pos 72-79
    DATA  320,  428,  320,    0,  360,  240,  360,  302   ' pos 80-87
    DATA  214,    0,  360,  240,  360,  302,    0,    0   ' pos 88-95
    DATA  360,  240,    0,  202,    0,  202,    0,  214   ' pos 96-103
    DATA    0,  240,    0,  320,  404,  360,  302,    0   ' pos 104-111
    DATA  480,  320,  404,    0,  404,    0,  320,    0   ' pos 112-119
    DATA  428,  605, 1077,  641,  404,  320,  269,  202   ' pos 120-127

    ' === Stage 4: D Strain [hardest] (26 obstacles) ===
    DATA  360,    0,  269,    0,  320,    0,  269,    0   ' pos 0-7
    DATA  320,    0,  269,    0,  240,  214,    0,  240   ' pos 8-15
    DATA  269,  320,  360,  320,    0,  428,    0,    0   ' pos 16-23
    DATA    0, 1438, 2155,  360,  320,  428,  360,  320   ' pos 24-31
    DATA    0,  428,  360,    0,  320,  480,    0,    0   ' pos 32-39
    DATA    0, 2034, 1920,  404,  320,  480,  404,  320   ' pos 40-47
    DATA    0,  428,    0,  360,  320,  428,  360,  320   ' pos 48-55
    DATA    0,  428,    0,  360,  320,  428,  360,  320   ' pos 56-63
    DATA    0,  360,  269,    0,  320,    0,  269,    0   ' pos 64-71
    DATA  320,    0,  269,    0,  240,  214,    0,  240   ' pos 72-79
    DATA  269,  320,  269,    0,  320,    0,  360,  269   ' pos 80-87
    DATA    0,  428,    0,  360,  320,  428,  360,  320   ' pos 88-95
    DATA    0,  539,    0,  480,  539,    0,  539,    0   ' pos 96-103
    DATA  480,  539,    0,  480,  428,  539,  480,  428   ' pos 104-111
    DATA    0,  539,    0,  480,  428,  539,    0,  480   ' pos 112-119
    DATA  807,  719,  539,    0,  360,    0,  269,    0   ' pos 120-127

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

    ' === Stage 1: B Strain (from rehearsal: 5,11,20,27,36,43,51,59,67,72,77,82,87,92,96,102,110,119,125) ===
    DATA 0,0,0,0, 0,1,0,0, 0,0,0,1, 0,0,0,0   ' pos 0-15:   5,11
    DATA 0,0,0,0, 1,0,0,0, 0,0,0,1, 0,0,0,0   ' pos 16-31:  20,27
    DATA 0,0,0,0, 1,0,0,0, 0,0,0,1, 0,0,0,0   ' pos 32-47:  36,43
    DATA 0,0,0,1, 0,0,0,0, 0,0,0,1, 0,0,0,0   ' pos 48-63:  51,59
    DATA 0,0,0,1, 0,0,0,0, 1,0,0,0, 0,1,0,0   ' pos 64-79:  67,72,77
    DATA 0,0,1,0, 0,0,0,1, 0,0,0,0, 1,0,0,0   ' pos 80-95:  82,87,92
    DATA 1,0,0,0, 0,0,1,0, 0,0,0,0, 0,0,1,0   ' pos 96-111: 96,102,110
    DATA 0,0,0,0, 0,0,0,1, 0,0,0,0, 0,1,0,0   ' pos 112-127: 119,125

    ' === Stage 2: A-to-C Strain (18 obstacles from rehearsal) ===
    DATA 1,0,0,0, 0,0,0,0, 0,0,0,1, 0,0,0,0   ' pos 0-15: 0, 11
    DATA 0,0,0,0, 1,0,0,0, 0,0,0,0, 1,0,0,0   ' pos 16-31: 20, 28
    DATA 0,0,0,1, 0,0,0,0, 0,0,0,1, 0,0,0,0   ' pos 32-47: 35, 43
    DATA 0,0,0,1, 0,0,0,0, 0,0,1,0, 0,0,0,0   ' pos 48-63: 51, 58
    DATA 0,0,0,0, 1,0,0,0, 1,0,0,0, 0,0,0,0   ' pos 64-79: 68, 72, 76
    DATA 0,0,0,0, 1,0,0,0, 0,0,1,0, 0,0,0,0   ' pos 80-95: 84, 90
    DATA 1,0,0,0, 0,0,0,0, 0,0,1,0, 0,0,0,0   ' pos 96-111: 96, 106
    DATA 0,0,0,1, 0,0,0,1, 0,0,0,0, 0,0,0,1   ' pos 112-127: 115, 119, 127

    ' === Stage 3: C-to-D Strain [hard] (36 obstacles) ===
    DATA 0,0,0,0, 0,1,0,0, 0,1,0,0, 0,1,0,0   ' pos 0-15: beat 5,9,13
    DATA 0,1,0,0, 0,1,0,0, 0,1,1,0, 0,1,0,0   ' pos 16-31: beat 17,21,25,26,29
    DATA 0,1,1,0, 0,1,0,0, 0,1,0,0, 0,1,0,0   ' pos 32-47: beat 33,34,37,41,45
    DATA 0,1,0,0, 0,1,1,0, 0,1,0,0, 0,1,1,0   ' pos 48-63: beat 49,53,54,57,61,62
    DATA 0,1,0,0, 0,1,0,0, 0,1,0,0, 0,1,0,0   ' pos 64-79: beat 65,69,73,77
    DATA 0,1,0,0, 0,1,1,0, 0,1,0,0, 0,1,0,0   ' pos 80-95: beat 81,85,86,89,93
    DATA 0,1,0,0, 0,1,1,1, 0,0,0,0, 0,0,0,0   ' pos 96-111: beat 97,101,102,103
    DATA 0,1,0,0, 0,1,0,0, 0,1,0,0, 0,1,0,0   ' pos 112-127: beat 113,117,121,125

    ' === Stage 4: D Strain [hardest] ===
    DATA 0,0,0,0, 0,1,0,0, 0,0,0,0, 0,0,0,1   ' pos 0-15: beat 5,15
    DATA 0,0,0,0, 0,1,0,0, 0,0,0,0, 0,0,0,1   ' pos 16-31: beat 21,31
    DATA 0,0,0,0, 0,1,0,0, 0,0,0,0, 0,0,0,1   ' pos 32-47: beat 37,47
    DATA 1,1,0,0, 0,0,0,0, 0,1,0,0, 0,0,0,1   ' pos 48-63: beat 48,49,57,63
    DATA 1,1,0,0, 0,0,0,0, 0,1,0,0, 0,0,0,0   ' pos 64-79: beat 64,65,73
    DATA 0,0,0,1, 0,0,0,0, 0,1,0,0, 0,0,0,0   ' pos 80-95: beat 83,89
    DATA 0,0,0,1, 0,0,0,0, 0,1,0,0, 0,0,0,1   ' pos 96-111: beat 99,105,111
    DATA 1,1,0,0, 0,0,0,0, 0,1,1,0, 0,0,0,1   ' pos 112-127: beat 112,113,121,122,127

    ' ============================================
    ' Note Color Palette (5 cycling colors)
    ' ============================================

HeartPositions:
    DATA 19, 18, 17, 16, 15    ' Right-anchored: index 0=rightmost, fills leftward


LevelOffsets:
    DATA 0, 128, 256, 384, 512

    ' Per-stage hazard spawn windows (indexed by CurrentLevel)
    ' Stage 0: no hazards (window [0,0] = never spawns)
    ' Stages 1-2: pencils [20,108], flowers [55,95]
    ' Stage 3: pencils [20,108], flowers [30,126]
PencilWindowStarts:
    DATA 0, 20, 20, 20, 20
PencilWindowEnds:
    DATA 0, 108, 108, 108, 117
FlowerWindowStarts:
    DATA 0, 55, 55, 30, 30
FlowerWindowEnds:
    DATA 0, 95, 95, 126, 126
SneezeEnabled:
    DATA 0, 0, 0, 0, 1          ' Level 5 only
SneezeMaxCount:
    DATA 0, 0, 0, 0, 2          ' Level 5: up to 2 sneezes
SneezeStartBeat:
    DATA 0, 0, 0, 0, 12         ' Level 5: start at beat 12 (~10% of 128)
SneezeEndBeat:
    DATA 0, 0, 0, 0, 115        ' Level 5: end at beat 115 (~90% of 128)

TubaWindowStarts:
    DATA 32, 0, 0, 0, 32        ' Level 1 (testing) and Level 5: beat 32 (25%)
TubaWindowEnds:
    DATA 96, 0, 0, 0, 96        ' Level 1 (testing) and Level 5: beat 96 (75%)

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

    ' Card 7: Player scream (arms way up, wide scared eyes, open O mouth)
    BITMAP "X..XX..X"
    BITMAP ".XXXXXX."
    BITMAP "XX....XX"
    BITMAP "XXXXXXXX"
    BITMAP "...XX..."
    BITMAP "..X..X.."
    BITMAP "...XX..."
    BITMAP "..X..X.."

    ' Card 8: Golden Tuba of Immunity power-up
    BITMAP ".XXXXXXX"
    BITMAP "..XXXXX."
    BITMAP "...XXX.."
    BITMAP ".XX.X..."
    BITMAP "X..XX..."
    BITMAP "X.X.X..."
    BITMAP "X...X..."
    BITMAP ".XXX...."
