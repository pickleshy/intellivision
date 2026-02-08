' ============================================
' DOWNBEAT - A Rhythm Game for Intellivision
' Phase 1: Single Player Prototype
' Based on ORCHESTRA! design by Shaya Bendix Lyon
' ============================================

OPTION MAP 2    ' Enable 42K ROM

' --------------------------------------------
' Constants
' --------------------------------------------

' Game states
CONST GS_TITLE      = 0
CONST GS_TEMPO_SEL  = 1
CONST GS_COUNTDOWN  = 2
CONST GS_GAMEPLAY   = 3
CONST GS_ROUND_END  = 4
CONST GS_RESULTS    = 5

' Intellivision colors (Color Stack foreground 0-7)
CONST COL_BLACK   = 0
CONST COL_BLUE    = 1
CONST COL_RED     = 2
CONST COL_TAN     = 3
CONST COL_DKGREEN = 4
CONST COL_GREEN   = 5
CONST COL_YELLOW  = 6
CONST COL_WHITE   = 7

' Sprite assignments
CONST SPR_CURSOR  = 0    ' Beat cursor on melody grid

' GRAM card assignments
CONST GRAM_SYNC_FULL  = 0  ' Sync meter: filled block
CONST GRAM_SYNC_EMPTY = 1  ' Sync meter: empty block
CONST GRAM_CURSOR1    = 2  ' Beat cursor frame 1 (bright)
CONST GRAM_CURSOR2    = 3  ' Beat cursor frame 2 (dim)
CONST GRAM_BEAT_EMPTY = 4  ' Empty beat slot on melody grid
CONST GRAM_DASH       = 5  ' Connecting dash between beats
CONST GRAM_VERT       = 6  ' Vertical connector at row turns

' Grid layout
CONST GRID_COLS  = 16   ' Columns per melody row (2 col padding each side)
CONST GRID_LEFT  = 2    ' Left padding columns
CONST GRID_ROWS  = 5    ' Number of melody rows (on screen rows 2,4,6,8,10)

' Bit-packed game flags (#GameFlags)
CONST FLAG_BEATFIRE    = 1    ' Bit 0: Beat event fired this frame
CONST FLAG_KEYHELD     = 2    ' Bit 1: Key is being held (edge detect)
CONST FLAG_INPUTLOCKED = 4    ' Bit 2: Input already processed this beat
CONST FLAG_EARLYHIT    = 8    ' Bit 3: Early hit pending for next beat
CONST FLAG_SYNCDIRTY   = 16   ' Bit 4: Sync meter needs redraw
CONST FLAG_SCOREDIRTY  = 32   ' Bit 5: Score needs redraw
CONST FLAG_DAZE        = 64   ' Bit 6: Player in daze state
CONST FLAG_DEBUG       = 128  ' Bit 7: Debug mode

' Latency compensation (frames to shift late window)
' Accounts for audio/visual processing delay in emulator
' 3 frames = 50ms — covers typical display pipeline lag
CONST LATENCY_OFFSET = 3
CONST RELEASE_FRAMES = 8   ' Frames of volume fade at note end

' Hit quality values
CONST HIT_NONE    = 0
CONST HIT_MISS    = 1
CONST HIT_GOOD    = 2
CONST HIT_PERFECT = 3

' --------------------------------------------
' Variables
' --------------------------------------------
GameState = GS_TITLE
#GameFlags = 0
#Score = 0

' Beat engine
BeatFrameCount = 0      ' Frames since last beat
BeatFramesPerBeat = 30  ' Frames per beat (set by tempo)
TotalBeats = 0          ' Total beats this turn
MaxBeats = 90           ' Beats per turn (set by tempo)

' Turn timer
#TurnFrameCount = 0

' Metronome
MetroDecay = 0          ' Frames of metronome tick remaining
MetroFlash = 0          ' Frames of border flash remaining

' Input
CurrentInstr = 0        ' Currently pressed instrument (1-9, 0=none)
LastKeyPress = 12       ' Previous frame CONT.KEY
EarlyHitInstr = 0       ' Instrument for pending early hit
EarlyHitQuality = 0     ' Quality for pending early hit

' Hit detection
HitQuality = 0          ' Last hit quality (HIT_NONE/MISS/GOOD/PERFECT)
HitDisplayTimer = 0     ' Frames to show hit text
PerfectWindow = 10      ' Frames for perfect hit
GoodWindow = 14         ' Frames for good hit

' Phrases and streaks
PhraseLen = 0           ' Current consecutive hit count
PerfectStreak = 0       ' Consecutive perfect hits
StreakBest = 0          ' Best perfect streak this turn
HitStreak = 0           ' Consecutive hits of any quality (Perfect+Good)
HitStreakBest = 0       ' Best hit streak this turn

' Sync meter
SyncMeter = 100         ' 0-100 sync percentage (starts full per spec)
DazeTimer = 0           ' Frames of daze remaining

' Instrument sounds
InstrVol = 0            ' Current instrument volume (decaying)
InstrPeakVol = 0        ' Target sustain volume for envelope
InstrDecayCount = 0     ' Frames of instrument sound remaining
#InstrFreq = 0          ' Current instrument frequency
FeedbackDecay = 0       ' Frames of feedback sound remaining

' Display
BeatRow = 0             ' Current beat's grid row
BeatCol = 0             ' Current beat's grid column
CursorSprX = 0          ' Cursor sprite X
CursorSprY = 0          ' Cursor sprite Y
#BeatScreenPos = 0      ' BACKTAB position for current beat

' Tempo selection
TempoChoice = 1         ' 0=Adagio, 1=Moderato, 2=Allegro
DiscPrev = 0            ' Previous disc state for debounce
FireHeld = 0            ' Consecutive frames fire held (ghost filter)

' Instrument variety
DIM InstrUsed(9)        ' 0 or 1 for each instrument used
UniqueInstr = 0         ' Count of unique instruments

' Temporary/loop vars
LoopVar = 0
TempVal = 0

' --------------------------------------------
' Initialization
' --------------------------------------------
    WAIT
    MODE 0, 0, 0, 0, 0   ' Color Stack: all black background
    CLS
    BORDER COL_BLACK

    ' Initialize Intellivoice (once only, gated on hardware presence)
    IF VOICE.AVAILABLE THEN
        VOICE INIT
    END IF

    ' Define GRAM cards for gameplay
    GOSUB DefineGramCards
    WAIT
    WAIT

    GOTO TitleScreen

' ============================================
' TITLE SCREEN
' ============================================
TitleScreen:
    GameState = GS_TITLE
    CLS
    WAIT

    ' Hide all sprites
    GOSUB HideAllSprites

    ' Draw title
    PRINT AT 24 COLOR COL_RED, "DOWNBEAT!"
    PRINT AT 65 COLOR COL_BLUE, "A RHYTHM GAME"
    PRINT AT 103 COLOR COL_WHITE, "BY SHAYA B LYON"
    PRINT AT 187 COLOR COL_YELLOW, "PRESS FIRE"

    ' Debounce: wait for button release
TitleDebounce:
    WAIT
    IF CONT.BUTTON THEN GOTO TitleDebounce
    IF CONT.KEY < 12 THEN GOTO TitleDebounce

    ' Wait for new press (FireHeld counter filters keypad ghosts)
    FireHeld = 0
TitleLoop:
    WAIT
    IF CONT.BUTTON THEN
        IF CONT.KEY >= 12 THEN
            IF FireHeld < 4 THEN FireHeld = FireHeld + 1
        ELSE
            FireHeld = 0
        END IF
    ELSE
        FireHeld = 0
    END IF
    IF FireHeld >= 4 THEN GOTO TempoSelect
    GOTO TitleLoop

' ============================================
' TEMPO SELECTION
' ============================================
TempoSelect:
    GameState = GS_TEMPO_SEL
    CLS
    WAIT
    TempoChoice = 1  ' Default to Moderato

    PRINT AT 22 COLOR COL_RED, "SELECT TEMPO"

    PRINT AT 201 COLOR COL_WHITE, "DISC OR KEYS 1-3"
    PRINT AT 221 COLOR COL_YELLOW, "FIRE TO START"

    GOSUB DrawTempoChoices

    ' Debounce
TempoDebounce:
    WAIT
    IF CONT.BUTTON THEN GOTO TempoDebounce
    IF CONT.KEY < 12 THEN GOTO TempoDebounce

    DiscPrev = 0
    FireHeld = 0

    ' Selection loop
TempoLoop:
    WAIT
    TempVal = CONT.KEY

    ' Direct keypad select
    IF TempVal = 1 THEN
        IF TempoChoice <> 0 THEN TempoChoice = 0 : GOSUB DrawTempoChoices
    END IF
    IF TempVal = 2 THEN
        IF TempoChoice <> 1 THEN TempoChoice = 1 : GOSUB DrawTempoChoices
    END IF
    IF TempVal = 3 THEN
        IF TempoChoice <> 2 THEN TempoChoice = 2 : GOSUB DrawTempoChoices
    END IF

    ' Disc up/down to cycle tempo
    IF CONT.UP THEN
        IF DiscPrev = 0 THEN
            DiscPrev = 1
            IF TempoChoice > 0 THEN
                TempoChoice = TempoChoice - 1
                GOSUB DrawTempoChoices
            END IF
        END IF
    ELSEIF CONT.DOWN THEN
        IF DiscPrev = 0 THEN
            DiscPrev = 1
            IF TempoChoice < 2 THEN
                TempoChoice = TempoChoice + 1
                GOSUB DrawTempoChoices
            END IF
        END IF
    ELSE
        DiscPrev = 0
    END IF

    ' Fire button starts game (FireHeld counter filters keypad ghosts)
    IF CONT.BUTTON THEN
        IF CONT.KEY >= 12 THEN
            IF FireHeld < 4 THEN FireHeld = FireHeld + 1
        ELSE
            FireHeld = 0
        END IF
    ELSE
        FireHeld = 0
    END IF
    IF FireHeld >= 4 THEN
        ' Load tempo parameters
        FireHeld = 0
        BeatFramesPerBeat = TempoFramesData(TempoChoice)
        MaxBeats = TempoBeatsData(TempoChoice)
        PerfectWindow = PerfectWindowData(TempoChoice)
        GoodWindow = GoodWindowData(TempoChoice)
        GOTO StartGame
    END IF
    GOTO TempoLoop

' ============================================
' START GAME - Initialize and run countdown
' ============================================
StartGame:
    GameState = GS_COUNTDOWN
    CLS
    WAIT

    ' Reset all game state
    #Score = 0
    #GameFlags = FLAG_SYNCDIRTY OR FLAG_SCOREDIRTY
    TotalBeats = 0
    BeatFrameCount = 0
    #TurnFrameCount = 0
    SyncMeter = 100   ' Start full per spec
    PhraseLen = 0
    PerfectStreak = 0
    StreakBest = 0
    HitStreak = 0
    HitStreakBest = 0
    UniqueInstr = 0
    CurrentInstr = 0
    HitQuality = HIT_NONE
    HitDisplayTimer = 0
    DazeTimer = 0
    MetroFlash = 0
    MetroDecay = 0
    InstrDecayCount = 0
    FeedbackDecay = 0
    LastKeyPress = 12
    EarlyHitInstr = 0
    EarlyHitQuality = 0

    ' Clear instrument usage
    FOR LoopVar = 0 TO 8
        InstrUsed(LoopVar) = 0
    NEXT LoopVar

    ' Silence all channels
    SOUND 0, 1, 0
    SOUND 1, 1, 0
    SOUND 2, 1, 0

    ' Draw HUD - Row 0
    PRINT AT 0 COLOR COL_WHITE, "DOWNBEAT"
    GOSUB DrawBPM
    PRINT AT 15 COLOR COL_WHITE, "    0"

    ' Draw beat grid - Rows 2,4,6,8,10 (16 cols with 2-col padding)
    GOSUB DrawBeatGrid

    ' Sync meter display hidden (logic still active for future 2-player use)
    ' GOSUB DrawSyncMeter
    #GameFlags = #GameFlags AND ($FFFF XOR FLAG_SYNCDIRTY)

    ' Countdown
    GOSUB CountdownSequence

    ' Enter gameplay
    GameState = GS_GAMEPLAY
    BeatFrameCount = BeatFramesPerBeat - 1  ' Fire beat on first frame so beat "1" is active
    GOTO GameLoop

' ============================================
' MAIN GAME LOOP
' ============================================
GameLoop:
    WAIT

    ' --- Beat timing engine ---
    GOSUB UpdateBeat

    ' --- Metronome tick decay (channel B) ---
    IF MetroDecay > 0 THEN
        MetroDecay = MetroDecay - 1
        IF MetroDecay = 0 THEN SOUND 1, 1, 0
    END IF

    ' --- Metronome border flash ---
    IF MetroFlash > 0 THEN
        MetroFlash = MetroFlash - 1
        IF MetroFlash > 0 THEN
            BORDER COL_WHITE
        ELSE
            BORDER COL_BLACK
        END IF
    END IF

    ' --- Instrument SFX decay ---
    IF InstrDecayCount > 0 THEN
        GOSUB UpdateInstrSfx
    END IF

    ' --- Feedback SFX decay ---
    IF FeedbackDecay > 0 THEN
        FeedbackDecay = FeedbackDecay - 1
        IF FeedbackDecay = 0 THEN SOUND 2, 1, 0
    END IF

    ' --- Hit display timer ---
    IF HitDisplayTimer > 0 THEN
        HitDisplayTimer = HitDisplayTimer - 1
        IF HitDisplayTimer = 0 THEN
            GOSUB ClearHitDisplay
        END IF
    END IF

    ' --- Daze handling ---
    IF DazeTimer > 0 THEN
        DazeTimer = DazeTimer - 1
        IF DazeTimer AND 4 THEN
            BORDER COL_RED
        ELSE
            BORDER COL_BLACK
        END IF
        IF DazeTimer = 0 THEN BORDER COL_BLACK
        ' During daze, skip input processing
    ELSE
        ' --- Normal: read input and check timing ---
        GOSUB ReadInput
        IF CurrentInstr > 0 THEN
            GOSUB CheckHitTiming
        END IF
    END IF

    ' --- Beat advance processing ---
    ' Miss detection is DEFERRED: when an active beat fires, the player
    ' gets the full late window (GoodWindow frames) to press a key.
    ' The miss is only declared when the NEXT passive beat fires and
    ' FLAG_INPUTLOCKED is still clear (no hit was registered).
    IF #GameFlags AND FLAG_BEATFIRE THEN
        IF (TotalBeats AND 1) = 0 THEN
            ' PASSIVE beat — stamp dash, then check if previous active beat was missed
            GOSUB BeatToScreen
            PRINT AT #BeatScreenPos, GRAM_DASH * 8 + COL_WHITE + $0800

            ' Draw vertical connector when last beat of a row is stamped
            IF BeatRow < GRID_ROWS - 1 THEN
                ' Check snaked BeatCol: even rows end at right (col 15), odd rows end at left (col 0)
                TempVal = GRID_COLS - 1
                IF BeatRow AND 1 THEN TempVal = 0
                IF BeatCol = TempVal THEN
                    PRINT AT ConnectorPosData(BeatRow), GRAM_VERT * 8 + COL_WHITE + $0800
                END IF
            END IF

            ' Was previous active beat missed?
            IF (#GameFlags AND FLAG_INPUTLOCKED) = 0 THEN
                IF DazeTimer = 0 AND TotalBeats > 1 THEN
                    TotalBeats = TotalBeats - 1  ' Point to missed active beat
                    GOSUB HandleMissedBeat
                    TotalBeats = TotalBeats + 1  ' Restore
                END IF
            END IF
            ' Clear input lock — ready for next active beat
            #GameFlags = #GameFlags AND ($FFFF XOR FLAG_INPUTLOCKED)
        ELSE
            ' ACTIVE beat — process early hits only; late hits handled by
            ' CheckHitTiming on subsequent frames; miss deferred to passive beat
            IF #GameFlags AND FLAG_EARLYHIT THEN
                CurrentInstr = EarlyHitInstr
                HitQuality = EarlyHitQuality
                GOSUB ProcessHit
                #GameFlags = #GameFlags AND ($FFFF XOR FLAG_EARLYHIT)
                #GameFlags = #GameFlags OR FLAG_INPUTLOCKED  ' Mark beat as hit
            END IF
        END IF
        ' Clear beat fire flag (but NOT input lock — needed for deferred miss check)
        #GameFlags = #GameFlags AND ($FFFF XOR FLAG_BEATFIRE)
        CurrentInstr = 0
    END IF

    ' --- Update cursor ---
    GOSUB UpdateCursor

    ' --- Sync meter redraw hidden (logic still active) ---
    IF #GameFlags AND FLAG_SYNCDIRTY THEN
        ' GOSUB DrawSyncMeter
        #GameFlags = #GameFlags AND ($FFFF XOR FLAG_SYNCDIRTY)
    END IF

    ' --- Redraw score if dirty ---
    IF #GameFlags AND FLAG_SCOREDIRTY THEN
        GOSUB DrawScore
        #GameFlags = #GameFlags AND ($FFFF XOR FLAG_SCOREDIRTY)
    END IF

    ' --- Check turn end ---
    IF TotalBeats >= MaxBeats THEN
        GOTO RoundEnd
    END IF

    GOTO GameLoop

' ============================================
' ROUND END
' ============================================
RoundEnd:
    GameState = GS_ROUND_END

    ' Silence all channels
    SOUND 0, 1, 0
    SOUND 1, 1, 0
    SOUND 2, 1, 0
    BORDER COL_BLACK

    ' Final phrase bonus
    IF PhraseLen >= 3 THEN
        GOSUB AwardPhraseBonus
    END IF

    ' Apply variety multiplier
    GOSUB ApplyVariety

    ' Update final score display
    GOSUB DrawScore

    ' Hide cursor
    SPRITE SPR_CURSOR, 0, 0, 0

    ' Brief pause (1.5 sec)
    FOR LoopVar = 0 TO 89
        WAIT
    NEXT LoopVar

    GOTO ResultsScreen

' ============================================
' RESULTS SCREEN
' ============================================
ResultsScreen:
    GameState = GS_RESULTS
    CLS
    WAIT

    PRINT AT 22 COLOR COL_RED, "TURN COMPLETE!"

    PRINT AT 62 COLOR COL_BLUE, "SCORE:"
    PRINT AT 69 COLOR COL_YELLOW, <>#Score

    PRINT AT 82 COLOR COL_BLUE, "BEST STREAK:"
    PRINT AT 95 COLOR COL_YELLOW, <>HitStreakBest

    PRINT AT 102 COLOR COL_BLUE, "INSTRUMENTS:"
    PRINT AT 115 COLOR COL_YELLOW, <>UniqueInstr
    PRINT AT 117 COLOR COL_WHITE, "/8"

    ' Variety tier display (escalating: White → Blue → Yellow → Red)
    IF UniqueInstr >= 8 THEN
        PRINT AT 122 COLOR COL_RED, "MAESTRO! x3"
    ELSEIF UniqueInstr >= 7 THEN
        PRINT AT 122 COLOR COL_YELLOW, "VIRTUOSO x1.5"
    ELSEIF UniqueInstr >= 5 THEN
        PRINT AT 122 COLOR COL_BLUE, "SKILLED x1.25"
    ELSEIF UniqueInstr >= 3 THEN
        PRINT AT 122 COLOR COL_WHITE, "DIVERSE x1.1"
    END IF

    PRINT AT 180 COLOR COL_YELLOW, "FIRE: PLAY AGAIN"
    PRINT AT 200 COLOR COL_WHITE, "1: CHANGE TEMPO"

    ' Debounce
ResultsDebounce:
    WAIT
    IF CONT.BUTTON THEN GOTO ResultsDebounce
    IF CONT.KEY < 12 THEN GOTO ResultsDebounce

    ' Wait for choice (FireHeld counter filters keypad ghosts)
    FireHeld = 0
ResultsLoop:
    WAIT
    ' Fire button replays (FireHeld counter filters keypad ghosts)
    IF CONT.BUTTON THEN
        IF CONT.KEY >= 12 THEN
            IF FireHeld < 4 THEN FireHeld = FireHeld + 1
        ELSE
            FireHeld = 0
        END IF
    ELSE
        FireHeld = 0
    END IF
    IF FireHeld >= 4 THEN
        FireHeld = 0
        GOTO StartGame
    END IF
    IF CONT.KEY = 1 THEN GOTO TempoSelect
    GOTO ResultsLoop

' ============================================
' SEGMENT 1 - Procedures
' ============================================
    SEGMENT 1

' --- Utility: Hide all sprites ---
HideAllSprites: PROCEDURE
    SPRITE 0, 0, 0, 0 : SPRITE 1, 0, 0, 0
    SPRITE 2, 0, 0, 0 : SPRITE 3, 0, 0, 0
    SPRITE 4, 0, 0, 0 : SPRITE 5, 0, 0, 0
    SPRITE 6, 0, 0, 0 : SPRITE 7, 0, 0, 0
    RETURN
END

' --- Beat Timing Engine ---
UpdateBeat: PROCEDURE
    ' Clear beat event flag from previous frame
    #GameFlags = #GameFlags AND ($FFFF XOR FLAG_BEATFIRE)

    BeatFrameCount = BeatFrameCount + 1

    ' Check if beat threshold reached
    IF BeatFrameCount >= BeatFramesPerBeat THEN GOSUB FireBeat

    #TurnFrameCount = #TurnFrameCount + 1
    RETURN
END

' --- Fire a beat event ---
FireBeat: PROCEDURE
    BeatFrameCount = 0
    #GameFlags = #GameFlags OR FLAG_BEATFIRE
    TotalBeats = TotalBeats + 1

    ' Metronome click on channel B — low tick (~280 Hz)
    SOUND 1, 400, 10
    MetroDecay = 3

    ' Border flash
    MetroFlash = 4
    BORDER COL_WHITE
    RETURN
END

' --- Read keypad input with edge detection ---
ReadInput: PROCEDURE
    TempVal = CONT.KEY
    CurrentInstr = 0

    IF TempVal >= 1 AND TempVal <= 9 THEN
        ' Check edge: was not pressed last frame
        IF LastKeyPress >= 10 OR LastKeyPress = 0 THEN
            CurrentInstr = TempVal
        END IF
    END IF
    LastKeyPress = TempVal
    RETURN
END

' --- Check hit timing relative to nearest beat ---
CheckHitTiming: PROCEDURE
    IF #GameFlags AND FLAG_INPUTLOCKED THEN RETURN

    ' On passive beats (even TotalBeats), only accept early presses
    ' for the next active beat — never stamp dots on passive positions
    IF (TotalBeats AND 1) = 0 THEN
        IF BeatFrameCount > (BeatFramesPerBeat / 2) + LATENCY_OFFSET THEN
            ' Second half of passive interval — close to next active beat
            TempVal = BeatFramesPerBeat - BeatFrameCount
            IF TempVal <= PerfectWindow THEN
                EarlyHitQuality = HIT_PERFECT
                EarlyHitInstr = CurrentInstr
                #GameFlags = #GameFlags OR FLAG_EARLYHIT
            ELSEIF TempVal <= GoodWindow THEN
                EarlyHitQuality = HIT_GOOD
                EarlyHitInstr = CurrentInstr
                #GameFlags = #GameFlags OR FLAG_EARLYHIT
            END IF
        END IF
        CurrentInstr = 0
        RETURN
    END IF

    ' --- Active beat timing ---
    ' Apply latency compensation: the perceived beat is LATENCY_OFFSET
    ' frames after the actual beat fire (audio/visual processing delay)
    ' This shifts the "ideal press point" later, forgiving late presses

    ' Late distance (frames since beat), compensated
    IF BeatFrameCount >= LATENCY_OFFSET THEN
        TempVal = BeatFrameCount - LATENCY_OFFSET
    ELSE
        TempVal = 0  ' Within offset of beat = treat as on-beat
    END IF

    ' Early distance (frames to next beat), uncompensated
    LoopVar = BeatFramesPerBeat - BeatFrameCount
    IF LoopVar < TempVal THEN TempVal = LoopVar

    ' TempVal = distance from nearest beat (latency-adjusted)

    ' Determine hit quality
    IF TempVal <= PerfectWindow THEN
        HitQuality = HIT_PERFECT
    ELSEIF TempVal <= GoodWindow THEN
        HitQuality = HIT_GOOD
    ELSE
        HitQuality = HIT_MISS
    END IF

    ' Check if this is an early press (closer to next beat)
    ' Shift split point by LATENCY_OFFSET to match compensated window
    IF BeatFrameCount > (BeatFramesPerBeat / 2) + LATENCY_OFFSET THEN
        ' Early press for NEXT beat — store and process on beat fire
        EarlyHitInstr = CurrentInstr
        EarlyHitQuality = HitQuality
        #GameFlags = #GameFlags OR FLAG_EARLYHIT
        CurrentInstr = 0   ' Don't process now
        RETURN
    END IF

    ' Late press (after beat) — process immediately
    #GameFlags = #GameFlags OR FLAG_INPUTLOCKED
    GOSUB ProcessHit
    RETURN
END

' --- Process a successful or failed hit ---
ProcessHit: PROCEDURE
    IF HitQuality >= HIT_GOOD THEN
        ' --- Good or Perfect hit ---
        GOSUB BeatToScreen

        ' Stamp instrument code on melody grid
        GOSUB StampInstrument

        ' Track variety (REST=9 does not count)
        IF CurrentInstr < 9 THEN
            IF InstrUsed(CurrentInstr - 1) = 0 THEN
                InstrUsed(CurrentInstr - 1) = 1
                UniqueInstr = UniqueInstr + 1
            END IF
        END IF

        ' Update phrase
        PhraseLen = PhraseLen + 1

        ' Score and streaks
        HitStreak = HitStreak + 1
        IF HitStreak > HitStreakBest THEN HitStreakBest = HitStreak
        IF HitQuality = HIT_PERFECT THEN
            #Score = #Score + 10
            PerfectStreak = PerfectStreak + 1
            IF PerfectStreak > StreakBest THEN StreakBest = PerfectStreak
            GOSUB CheckStreakBonus
        ELSE
            #Score = #Score + 5
            PerfectStreak = 0
        END IF

        ' Sync meter
        IF HitQuality = HIT_PERFECT THEN
            SyncMeter = SyncMeter + 10
            IF SyncMeter > 100 THEN SyncMeter = 100
        ELSE
            SyncMeter = SyncMeter + 5
            IF SyncMeter > 100 THEN SyncMeter = 100
        END IF

        ' Silence metronome (channel B) — instrument replaces it on hits
        SOUND 1, 1, 0
        MetroDecay = 0

        ' Show instrument name and play sound
        GOSUB DrawInstrumentName
        GOSUB PlayInstrSound

        ' Feedback sound
        IF HitQuality = HIT_PERFECT THEN
            SOUND 2, 50, 10
            FeedbackDecay = 4
        ELSE
            SOUND 2, 100, 8
            FeedbackDecay = 3
        END IF
    ELSE
        ' --- Miss ---
        GOSUB BeatToScreen
        ' Stamp grey dot for missed beat
        PRINT AT #BeatScreenPos, GRAM_BEAT_EMPTY * 8 + COL_TAN + $0800

        ' Grey out phrase notes, then break phrase
        GOSUB GreyOutPhrase
        IF PhraseLen >= 3 THEN GOSUB AwardPhraseBonus
        PhraseLen = 0
        PerfectStreak = 0
        HitStreak = 0

        ' Sync meter drain
        IF SyncMeter >= 15 THEN
            SyncMeter = SyncMeter - 15
        ELSE
            SyncMeter = 0
        END IF

        ' Check sync depletion
        IF SyncMeter = 0 THEN
            DazeTimer = 120   ' 2-second daze
            SyncMeter = 50    ' Reset to 50%
            PhraseLen = 0
        END IF

        ' Miss feedback sound
        SOUND 2, 800, 6
        FeedbackDecay = 4
    END IF

    #GameFlags = #GameFlags OR (FLAG_SYNCDIRTY OR FLAG_SCOREDIRTY)

    ' Display hit quality
    GOSUB DrawHitQuality
    HitDisplayTimer = 20
    RETURN
END

' --- Handle a beat with no input (auto-miss) ---
HandleMissedBeat: PROCEDURE
    HitQuality = HIT_MISS
    GOSUB BeatToScreen
    ' Stamp grey dot for missed beat
    PRINT AT #BeatScreenPos, GRAM_BEAT_EMPTY * 8 + COL_TAN + $0800

    ' Grey out phrase notes, then break phrase
    GOSUB GreyOutPhrase
    IF PhraseLen >= 3 THEN GOSUB AwardPhraseBonus
    PhraseLen = 0
    PerfectStreak = 0
    HitStreak = 0

    ' Sync drain
    IF SyncMeter >= 15 THEN
        SyncMeter = SyncMeter - 15
    ELSE
        SyncMeter = 0
    END IF

    IF SyncMeter = 0 THEN
        DazeTimer = 120
        SyncMeter = 50
        PhraseLen = 0
    END IF

    #GameFlags = #GameFlags OR FLAG_SYNCDIRTY

    GOSUB DrawHitQuality
    HitDisplayTimer = 20
    RETURN
END

' --- Convert TotalBeats to screen position ---
BeatToScreen: PROCEDURE
    ' Use beat before current (TotalBeats already incremented by FireBeat)
    TempVal = TotalBeats - 1
    IF TempVal > (GRID_ROWS * GRID_COLS - 1) THEN TempVal = GRID_ROWS * GRID_COLS - 1

    ' Row = beat / GRID_COLS, Col = beat mod GRID_COLS
    BeatRow = TempVal / GRID_COLS
    BeatCol = TempVal - (BeatRow * GRID_COLS)

    ' Odd rows snake right-to-left
    IF BeatRow AND 1 THEN
        BeatCol = GRID_COLS - 1 - BeatCol
    END IF

    ' BACKTAB position (with left padding)
    #BeatScreenPos = RowStartData(BeatRow) + BeatCol + GRID_LEFT

    ' Sprite position (8px offset, account for left padding)
    CursorSprX = (BeatCol + GRID_LEFT) * 8 + 8
    CursorSprY = RowSpriteYData(BeatRow)
    RETURN
END

' --- Stamp colored round dot on melody grid ---
StampInstrument: PROCEDURE
    TempVal = InstrColorData(CurrentInstr - 1)
    PRINT AT #BeatScreenPos, GRAM_CURSOR1 * 8 + TempVal + $0800
    RETURN
END

' --- Play instrument sound on channel A (0) ---
PlayInstrSound: PROCEDURE
    ' REST: barely audible tick for feedback per audio spec
    IF CurrentInstr = 9 THEN
        SOUND 0, 400, 2
        InstrDecayCount = 2
        #InstrFreq = 400
        InstrVol = 2
        InstrPeakVol = 2
        RETURN
    END IF

    TempVal = CurrentInstr - 1
    #InstrFreq = InstrPeriodData(TempVal)
    InstrVol = InstrVolumeData(TempVal)
    InstrPeakVol = InstrPeakVolData(TempVal)
    InstrDecayCount = InstrDecayData(TempVal)

    SOUND 0, #InstrFreq, InstrVol

    ' Timpani: add noise on channel C
    IF CurrentInstr = 8 THEN
        POKE $1F7, 12
        TempVal = PEEK($1F8) AND $DB  ' Enable noise on channel A
        POKE $1F8, TempVal
    END IF
    RETURN
END

' --- Instrument envelope: attack → sustain → release ---
UpdateInstrSfx: PROCEDURE
    InstrDecayCount = InstrDecayCount - 1
    IF InstrDecayCount = 0 THEN
        SOUND 0, 1, 0
        ' Disable noise
        TempVal = PEEK($1F8) OR $24
        POKE $1F8, TempVal
    ELSE
        IF InstrVol < InstrPeakVol THEN
            ' Attack: ramp up toward sustain (strings/woodwinds)
            InstrVol = InstrVol + 2
            IF InstrVol > InstrPeakVol THEN InstrVol = InstrPeakVol
        ELSEIF InstrVol > InstrPeakVol THEN
            ' Percussive: quick decay toward sustain (trumpet/timpani)
            InstrVol = InstrVol - 1
        ELSEIF InstrDecayCount <= RELEASE_FRAMES THEN
            ' Release: fade out
            IF InstrVol >= 2 THEN
                InstrVol = InstrVol - 2
            ELSE
                InstrVol = 0
            END IF
        END IF
        SOUND 0, #InstrFreq, InstrVol
    END IF
    RETURN
END

' --- Update cursor sprite position ---
UpdateCursor: PROCEDURE
    IF TotalBeats = 0 THEN
        ' No beats yet, position at first grid column
        CursorSprX = GRID_LEFT * 8 + 8
        CursorSprY = 24  ' Row 2
    ELSE
        GOSUB BeatToScreen
    END IF

    ' Full dot cursor (goldenrod)
    SPRITE SPR_CURSOR, CursorSprX + $0300, CursorSprY, GRAM_CURSOR1 * 8 + COL_YELLOW + $0800
    RETURN
END

' --- Award phrase bonus ---
AwardPhraseBonus: PROCEDURE
    IF PhraseLen >= 6 THEN
        #Score = #Score + 75
    ELSEIF PhraseLen >= 5 THEN
        #Score = #Score + 50
    ELSEIF PhraseLen >= 4 THEN
        #Score = #Score + 30
    ELSEIF PhraseLen >= 3 THEN
        #Score = #Score + 20
    END IF
    #GameFlags = #GameFlags OR FLAG_SCOREDIRTY
    RETURN
END

' --- Check perfect streak bonuses ---
CheckStreakBonus: PROCEDURE
    IF PerfectStreak = 5 THEN #Score = #Score + 50
    IF PerfectStreak = 8 THEN #Score = #Score + 100
    IF PerfectStreak = 10 THEN #Score = #Score + 200
    IF PerfectStreak = 15 THEN #Score = #Score + 500
    RETURN
END

' --- Apply variety multiplier at turn end ---
ApplyVariety: PROCEDURE
    ' Safe multiplier: cap base score before multiply to prevent overflow
    IF UniqueInstr >= 8 THEN
        ' 3x: cap at 21845 to prevent 16-bit overflow
        IF #Score > 21845 THEN
            #Score = 65535
        ELSE
            #Score = #Score + #Score + #Score
        END IF
    ELSEIF UniqueInstr >= 7 THEN
        ' 1.5x: score + score/2
        #Score = #Score + #Score / 2
    ELSEIF UniqueInstr >= 5 THEN
        ' 1.25x: score + score/4
        #Score = #Score + #Score / 4
    ELSEIF UniqueInstr >= 3 THEN
        ' 1.1x: score + score/10
        #Score = #Score + #Score / 10
    END IF
    RETURN
END

' --- Draw sync meter on row 1 ---
DrawSyncMeter: PROCEDURE
    TempVal = SyncMeter / 5  ' 0-20 blocks

    FOR LoopVar = 0 TO 19
        IF LoopVar < TempVal THEN
            ' Filled block: white per design doc
            PRINT AT 20 + LoopVar, GRAM_SYNC_FULL * 8 + COL_WHITE + $0800
        ELSE
            ' Empty block: dark green (grey stand-in)
            PRINT AT 20 + LoopVar, GRAM_SYNC_EMPTY * 8 + COL_DKGREEN + $0800
        END IF
    NEXT LoopVar
    RETURN
END

' --- Draw score on row 0 ---
DrawScore: PROCEDURE
    ' Right-align on row 0, positions 15-19
    PRINT AT 13 COLOR COL_WHITE, "       "
    IF #Score < 10 THEN
        PRINT AT 19 COLOR COL_WHITE, <>#Score
    ELSEIF #Score < 100 THEN
        PRINT AT 18 COLOR COL_WHITE, <>#Score
    ELSEIF #Score < 1000 THEN
        PRINT AT 17 COLOR COL_WHITE, <>#Score
    ELSEIF #Score < 10000 THEN
        PRINT AT 16 COLOR COL_WHITE, <>#Score
    ELSE
        PRINT AT 15 COLOR COL_WHITE, <>#Score
    END IF
    RETURN
END

' --- Draw BPM on row 0 ---
DrawBPM: PROCEDURE
    IF TempoChoice = 0 THEN PRINT AT 9 COLOR COL_TAN, " 90"
    IF TempoChoice = 1 THEN PRINT AT 9 COLOR COL_TAN, "110"
    IF TempoChoice = 2 THEN PRINT AT 9 COLOR COL_TAN, "130"
    RETURN
END

' --- Draw beat grid (clean black) on melody rows ---
DrawBeatGrid: PROCEDURE
    ' Grid starts empty — only hits and cursor are visible
    ' CLS already cleared it, but ensure it's clean after replays
    FOR LoopVar = 0 TO GRID_ROWS - 1
        #BeatScreenPos = RowStartData(LoopVar) + GRID_LEFT
        FOR TempVal = 0 TO GRID_COLS - 1
            PRINT AT #BeatScreenPos + TempVal, 0
        NEXT TempVal
    NEXT LoopVar
    RETURN
END

' --- Draw hit quality text on row 11 (left side) ---
DrawHitQuality: PROCEDURE
    ' Clear left half of row 11
    PRINT AT 220 COLOR COL_BLACK, "          "

    IF HitQuality = HIT_PERFECT THEN
        PRINT AT 220 COLOR COL_GREEN, "PERFECT!"
    ELSEIF HitQuality = HIT_GOOD THEN
        PRINT AT 221 COLOR COL_YELLOW, "GOOD"
    ELSEIF HitQuality = HIT_MISS THEN
        PRINT AT 221 COLOR COL_RED, "MISS"
    END IF
    RETURN
END

' --- Clear hit quality display ---
ClearHitDisplay: PROCEDURE
    PRINT AT 220 COLOR COL_BLACK, "          "
    RETURN
END

' --- Draw instrument name on row 11 (right side) ---
DrawInstrumentName: PROCEDURE
    ' Clear right half of row 11
    PRINT AT 231 COLOR COL_BLACK, "         "

    IF CurrentInstr = 1 THEN PRINT AT 232 COLOR COL_BLUE, "PICCOLO"
    IF CurrentInstr = 2 THEN PRINT AT 232 COLOR COL_YELLOW, "TRUMPET"
    IF CurrentInstr = 3 THEN PRINT AT 233 COLOR COL_WHITE, "VIOLIN"
    IF CurrentInstr = 4 THEN PRINT AT 235 COLOR COL_TAN, "OBOE"
    IF CurrentInstr = 5 THEN PRINT AT 234 COLOR COL_RED, "VIOLA"
    IF CurrentInstr = 6 THEN PRINT AT 231 COLOR COL_GREEN, "TROMBONE"
    IF CurrentInstr = 7 THEN PRINT AT 232 COLOR COL_DKGREEN, "BASSOON"
    IF CurrentInstr = 8 THEN PRINT AT 232 COLOR COL_YELLOW, "TIMPANI"
    IF CurrentInstr = 9 THEN PRINT AT 235 COLOR COL_TAN, "REST"
    RETURN
END


' --- Draw tempo selection choices ---
DrawTempoChoices: PROCEDURE
    ' Row 3 (pos 60): Adagio — Blue when selected (calm/slow)
    IF TempoChoice = 0 THEN
        PRINT AT 62 COLOR COL_BLUE, "1 ADAGIO     90"
    ELSE
        PRINT AT 62 COLOR COL_WHITE, "1 ADAGIO     90"
    END IF

    ' Row 5 (pos 100): Moderato — Yellow when selected (warm/balanced)
    IF TempoChoice = 1 THEN
        PRINT AT 102 COLOR COL_YELLOW, "2 MODERATO  110"
    ELSE
        PRINT AT 102 COLOR COL_WHITE, "2 MODERATO  110"
    END IF

    ' Row 7 (pos 140): Allegro — Red when selected (fast/energetic)
    IF TempoChoice = 2 THEN
        PRINT AT 142 COLOR COL_RED, "3 ALLEGRO   130"
    ELSE
        PRINT AT 142 COLOR COL_WHITE, "3 ALLEGRO   130"
    END IF
    RETURN
END

' --- Countdown sequence (4-3-2-1 at tempo speed per spec) ---
CountdownSequence: PROCEDURE
    ' Each number displayed for exactly one beat duration
    ' TempVal = frames to wait per beat (BeatFramesPerBeat - 1 for FOR loop)
    IF BeatFramesPerBeat >= 1 THEN
        TempVal = BeatFramesPerBeat - 1
    ELSE
        TempVal = 29  ' Fallback to 120 BPM
    END IF

    ' "4"
    PRINT AT 109 COLOR COL_WHITE, "4"
    SOUND 1, 400, 10
    IF VOICE.AVAILABLE THEN VOICE NUMBER 4
    FOR LoopVar = 0 TO TempVal
        WAIT
    NEXT LoopVar
    SOUND 1, 1, 0
    PRINT AT 109, " "

    ' "3"
    PRINT AT 109 COLOR COL_WHITE, "3"
    SOUND 1, 400, 10
    IF VOICE.AVAILABLE THEN VOICE NUMBER 3
    FOR LoopVar = 0 TO TempVal
        WAIT
    NEXT LoopVar
    SOUND 1, 1, 0
    PRINT AT 109, " "

    ' "2"
    PRINT AT 109 COLOR COL_YELLOW, "2"
    SOUND 1, 400, 12
    IF VOICE.AVAILABLE THEN VOICE NUMBER 2
    FOR LoopVar = 0 TO TempVal
        WAIT
    NEXT LoopVar
    SOUND 1, 1, 0
    PRINT AT 109, " "

    ' "1"
    PRINT AT 109 COLOR COL_GREEN, "1"
    SOUND 1, 400, 12
    IF VOICE.AVAILABLE THEN VOICE NUMBER 1
    FOR LoopVar = 0 TO TempVal
        WAIT
    NEXT LoopVar
    SOUND 1, 1, 0
    PRINT AT 109, " "
    RETURN
END

' --- Define GRAM cards ---
DefineGramCards: PROCEDURE
    ' Card 0: Sync meter filled block
    DEFINE 0, 1, GfxSyncFull
    WAIT
    ' Card 1: Sync meter empty block
    DEFINE 1, 1, GfxSyncEmpty
    WAIT
    ' Card 2: Cursor bright
    DEFINE 2, 1, GfxCursorBright
    WAIT
    ' Card 3: Cursor dim
    DEFINE 3, 1, GfxCursorDim
    WAIT
    ' Card 4: Empty beat slot
    DEFINE 4, 1, GfxBeatEmpty
    WAIT
    ' Card 5: Connecting dash (subway map line)
    DEFINE 5, 1, GfxDash
    WAIT
    ' Card 6: Vertical connector at row turns
    DEFINE 6, 1, GfxVert
    WAIT
    RETURN
END

' --- Grey out phrase notes on miss ---
' When a phrase breaks, dim instrument dots to dark green (skip dashes)
GreyOutPhrase: PROCEDURE
    IF PhraseLen < 1 THEN RETURN
    IF TotalBeats < 2 THEN RETURN

    ' With every-other-beat, N hits span up to 2*N beat positions
    ' Walk back enough to cover all phrase dots plus interleaved dashes
    TempVal = TotalBeats - 2   ' Last potential hit position
    LoopVar = PhraseLen + PhraseLen  ' Double range for passive gaps
    IF TempVal >= LoopVar THEN
        LoopVar = TempVal - LoopVar + 1
    ELSE
        LoopVar = 0
    END IF

    WHILE LoopVar <= TempVal
        BeatRow = LoopVar / GRID_COLS
        BeatCol = LoopVar - (BeatRow * GRID_COLS)

        ' Odd rows snake right-to-left
        IF BeatRow AND 1 THEN
            BeatCol = GRID_COLS - 1 - BeatCol
        END IF

        #BeatScreenPos = RowStartData(BeatRow) + BeatCol + GRID_LEFT

        ' Only recolor dots (GRAM_CURSOR1), skip dashes and empty slots
        #Card = PEEK($200 + #BeatScreenPos)
        IF #Card AND $0800 THEN
            IF (#Card AND $1F8) = (GRAM_CURSOR1 * 8) THEN
                PRINT AT #BeatScreenPos, (#Card AND $EFF8) OR COL_DKGREEN
            END IF
        END IF

        LoopVar = LoopVar + 1
    WEND
    RETURN
END

' ============================================
' SEGMENT 2 - Data Tables and GRAM Graphics
' ============================================
    SEGMENT 2

' --- ROM Lookup Tables ---

' Tempo: frames per beat (90/110/130 BPM)
TempoFramesData:
    DATA 40, 33, 28

' Tempo: beats per turn (capped to grid capacity: 5 rows × 16 cols = 80)
TempoBeatsData:
    DATA 67, 80, 80

' Perfect hit window (frames from beat) - ±167ms = 10 frames at 60fps
' Generous but still distinct from Good for scoring
PerfectWindowData:
    DATA 10, 10, 10

' Good hit window (frames from beat) - ±233ms = 14 frames at 60fps
' Very forgiving — most presses near a beat should register
GoodWindowData:
    DATA 14, 14, 14

' Row start BACKTAB positions for melody rows 0-4 (screen rows 2,4,6,8,10)
RowStartData:
    DATA 40, 80, 120, 160, 200

' Sprite Y positions for melody rows 0-4 (screen rows 2,4,6,8,10)
RowSpriteYData:
    DATA 24, 40, 56, 72, 88

' Vertical connector BACKTAB positions (gap rows 3,5,7,9 at turn columns)
' Row 0→1: screen row 3 col 17=77, Row 1→2: row 5 col 2=102
' Row 2→3: screen row 7 col 17=157, Row 3→4: row 9 col 2=182
ConnectorPosData:
    DATA 77, 102, 157, 182

' Instrument colors (indexed 0-8 for instruments 1-9)
InstrColorData:
    DATA COL_BLUE, COL_YELLOW, COL_WHITE, COL_TAN, COL_RED, COL_GREEN, COL_DKGREEN, COL_YELLOW, COL_TAN

' Instrument PSG periods (from audio spec)
' Piccolo=35, Trumpet=70, Violin=90, Oboe=140, Viola=190, Trombone=250, Bassoon=350, Timpani=700, REST=0
InstrPeriodData:
    DATA 35, 70, 90, 140, 190, 250, 350, 700, 0

' Instrument initial volume (attack start)
' Sharp attack (brass/perc) starts at/above peak; soft attack (strings) starts low
InstrVolumeData:
    DATA 14, 15, 8, 12, 7, 11, 9, 15, 0

' Instrument peak/sustain volume
' Strings build to full sustain; percussion settles to lower sustain
InstrPeakVolData:
    DATA 14, 14, 14, 14, 13, 14, 12, 12, 0

' Instrument total duration (frames)
' Longer for sustained instruments, shorter for percussive
' Piccolo=14(233ms) Trumpet=18(300ms) Violin=28(467ms) Oboe=16(267ms)
' Viola=26(433ms) Trombone=20(333ms) Bassoon=30(500ms) Timpani=16(267ms)
InstrDecayData:
    DATA 14, 18, 28, 16, 26, 20, 30, 16, 0

' --- GRAM Bitmap Data ---

' Sync meter: filled block
GfxSyncFull:
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"

' Sync meter: empty block
GfxSyncEmpty:
    BITMAP "X......X"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "X......X"

' Beat cursor: bright frame
GfxCursorBright:
    BITMAP "..XXXX.."
    BITMAP ".XXXXXX."
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP "XXXXXXXX"
    BITMAP ".XXXXXX."
    BITMAP "..XXXX.."

' Beat cursor: dim frame
GfxCursorDim:
    BITMAP "........"
    BITMAP "..XXXX.."
    BITMAP ".XXXXXX."
    BITMAP ".XXXXXX."
    BITMAP ".XXXXXX."
    BITMAP ".XXXXXX."
    BITMAP "..XXXX.."
    BITMAP "........"

' Empty beat slot marker
GfxBeatEmpty:
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "...XX..."
    BITMAP "...XX..."
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"

' Connecting dash (short rail between station dots, 2px margins for gap)
GfxDash:
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "..XXXX.."
    BITMAP "..XXXX.."
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"

' Vertical connector at snaking row turns
GfxVert:
    BITMAP "..XXXX.."
    BITMAP "..XXXX.."
    BITMAP "..XXXX.."
    BITMAP "..XXXX.."
    BITMAP "..XXXX.."
    BITMAP "..XXXX.."
    BITMAP "..XXXX.."
    BITMAP "..XXXX.."
