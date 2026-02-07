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
CONST LATENCY_OFFSET = 2

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
BeatHalf = 0            ' Alternation counter for 160 BPM
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
PerfectWindow = 2       ' Frames for perfect hit
GoodWindow = 5          ' Frames for good hit

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
InstrDecayCount = 0     ' Frames of instrument sound remaining
#InstrFreq = 0          ' Current instrument frequency
FeedbackDecay = 0       ' Frames of feedback sound remaining

' Display
CursorPulse = 0         ' Animation counter for cursor
BeatRow = 0             ' Current beat's grid row
BeatCol = 0             ' Current beat's grid column
CursorSprX = 0          ' Cursor sprite X
CursorSprY = 0          ' Cursor sprite Y
#BeatScreenPos = 0      ' BACKTAB position for current beat

' Tempo selection
TempoChoice = 1         ' 0=Adagio, 1=Moderato, 2=Allegro
DiscPrev = 0            ' Previous disc state for debounce

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
    PRINT AT 24 COLOR COL_WHITE, "DOWNBEAT"
    PRINT AT 65 COLOR COL_GREEN, "A RHYTHM GAME"
    PRINT AT 103 COLOR COL_TAN, "BY SHAYA B LYON"
    PRINT AT 187 COLOR COL_YELLOW, "PRESS FIRE"

    ' Debounce: wait for button release
TitleDebounce:
    WAIT
    IF CONT.BUTTON THEN GOTO TitleDebounce
    IF CONT.KEY < 12 THEN GOTO TitleDebounce

    ' Wait for new press
TitleLoop:
    WAIT
    IF CONT.BUTTON THEN
        IF CONT.KEY >= 12 THEN GOTO TempoSelect
    END IF
    GOTO TitleLoop

' ============================================
' TEMPO SELECTION
' ============================================
TempoSelect:
    GameState = GS_TEMPO_SEL
    CLS
    WAIT
    TempoChoice = 1  ' Default to Moderato

    PRINT AT 22 COLOR COL_WHITE, "SELECT TEMPO"

    PRINT AT 201 COLOR COL_GREEN, "DISC OR KEYS 1-3"
    PRINT AT 221 COLOR COL_YELLOW, "FIRE TO START"

    GOSUB DrawTempoChoices

    ' Debounce
TempoDebounce:
    WAIT
    IF CONT.BUTTON THEN GOTO TempoDebounce
    IF CONT.KEY < 12 THEN GOTO TempoDebounce

    DiscPrev = 0

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

    ' Fire button starts game
    IF CONT.BUTTON THEN
        IF CONT.KEY >= 12 THEN
            ' Load tempo parameters
            BeatFramesPerBeat = TempoFramesData(TempoChoice)
            MaxBeats = TempoBeatsData(TempoChoice)
            PerfectWindow = PerfectWindowData(TempoChoice)
            GoodWindow = GoodWindowData(TempoChoice)
            GOTO StartGame
        END IF
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
    BeatHalf = 0
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
    CursorPulse = 0

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

    ' Draw beat grid - Rows 2-7
    GOSUB DrawBeatGrid

    ' Draw sync meter - Row 8 (below melody grid)
    GOSUB DrawSyncMeter
    #GameFlags = #GameFlags AND ($FFFF XOR FLAG_SYNCDIRTY)

    ' Countdown
    GOSUB CountdownSequence

    ' Enter gameplay
    GameState = GS_GAMEPLAY
    BeatFrameCount = 0
    GOTO GameLoop

' ============================================
' MAIN GAME LOOP
' ============================================
GameLoop:
    WAIT

    ' --- Beat timing engine ---
    GOSUB UpdateBeat

    ' --- Metronome tick decay ---
    IF MetroDecay > 0 THEN
        MetroDecay = MetroDecay - 1
        IF MetroDecay = 0 THEN SOUND 0, 1, 0
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
    IF #GameFlags AND FLAG_BEATFIRE THEN
        ' Process early hit if pending
        IF #GameFlags AND FLAG_EARLYHIT THEN
            CurrentInstr = EarlyHitInstr
            HitQuality = EarlyHitQuality
            GOSUB ProcessHit
            #GameFlags = #GameFlags AND ($FFFF XOR FLAG_EARLYHIT)
        ELSEIF (#GameFlags AND FLAG_INPUTLOCKED) = 0 THEN
            ' No input this beat = miss
            IF DazeTimer = 0 THEN
                GOSUB HandleMissedBeat
            END IF
        END IF
        ' Reset for next beat
        #GameFlags = #GameFlags AND ($FFFF XOR (FLAG_INPUTLOCKED OR FLAG_BEATFIRE))
        CurrentInstr = 0
    END IF

    ' --- Update cursor ---
    GOSUB UpdateCursor

    ' --- Redraw sync meter if dirty ---
    IF #GameFlags AND FLAG_SYNCDIRTY THEN
        GOSUB DrawSyncMeter
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

    PRINT AT 22 COLOR COL_WHITE, "TURN COMPLETE!"

    PRINT AT 62 COLOR COL_TAN, "SCORE:"
    PRINT AT 69 COLOR COL_WHITE, <>#Score

    PRINT AT 82 COLOR COL_TAN, "BEST STREAK:"
    PRINT AT 95 COLOR COL_YELLOW, <>HitStreakBest

    PRINT AT 102 COLOR COL_TAN, "INSTRUMENTS:"
    PRINT AT 115 COLOR COL_GREEN, <>UniqueInstr
    PRINT AT 117 COLOR COL_TAN, "/8"

    ' Variety tier display
    IF UniqueInstr >= 8 THEN
        PRINT AT 122 COLOR COL_YELLOW, "MAESTRO! x3"
    ELSEIF UniqueInstr >= 7 THEN
        PRINT AT 122 COLOR COL_YELLOW, "VIRTUOSO x1.5"
    ELSEIF UniqueInstr >= 5 THEN
        PRINT AT 122 COLOR COL_GREEN, "SKILLED x1.25"
    ELSEIF UniqueInstr >= 3 THEN
        PRINT AT 122 COLOR COL_TAN, "DIVERSE x1.1"
    END IF

    PRINT AT 180 COLOR COL_YELLOW, "FIRE: PLAY AGAIN"
    PRINT AT 200 COLOR COL_TAN, "1: CHANGE TEMPO"

    ' Debounce
ResultsDebounce:
    WAIT
    IF CONT.BUTTON THEN GOTO ResultsDebounce
    IF CONT.KEY < 12 THEN GOTO ResultsDebounce

    ' Wait for choice
ResultsLoop:
    WAIT
    IF CONT.BUTTON THEN
        IF CONT.KEY >= 12 THEN GOTO StartGame
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
    IF BeatFramesPerBeat = 22 THEN
        ' 160 BPM: alternate 22/23 frames
        ' BeatHalf 0-2 use 23 frames, 3-7 use 22 frames
        IF BeatHalf < 3 THEN
            IF BeatFrameCount >= 23 THEN GOSUB FireBeat
        ELSE
            IF BeatFrameCount >= 22 THEN GOSUB FireBeat
        END IF
    ELSE
        IF BeatFrameCount >= BeatFramesPerBeat THEN GOSUB FireBeat
    END IF

    #TurnFrameCount = #TurnFrameCount + 1
    RETURN
END

' --- Fire a beat event ---
FireBeat: PROCEDURE
    BeatFrameCount = 0
    #GameFlags = #GameFlags OR FLAG_BEATFIRE
    TotalBeats = TotalBeats + 1

    ' 160 BPM alternation
    BeatHalf = BeatHalf + 1
    IF BeatHalf >= 8 THEN BeatHalf = 0

    ' Metronome click on channel 0
    SOUND 0, 60, 12
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

    ' Calculate distance from nearest beat boundary
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

        ' Silence metronome — instrument replaces it on hits
        SOUND 0, 1, 0
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
    IF TempVal > 119 THEN TempVal = 119

    ' Row = beat / 20, Col = beat mod 20
    BeatRow = TempVal / 20
    BeatCol = TempVal - (BeatRow * 20)

    ' Odd rows snake right-to-left
    IF BeatRow AND 1 THEN
        BeatCol = 19 - BeatCol
    END IF

    ' BACKTAB position (melody starts at row 2)
    #BeatScreenPos = RowStartData(BeatRow) + BeatCol

    ' Sprite position (8px offset)
    CursorSprX = BeatCol * 8 + 8
    CursorSprY = (BeatRow + 2) * 8 + 8
    RETURN
END

' --- Stamp instrument 2-letter code on melody grid ---
StampInstrument: PROCEDURE
    ' Each instrument takes 2 BACKTAB positions
    ' But at 20 columns that uses too much space
    ' Use single colored GROM character instead
    TempVal = InstrColorData(CurrentInstr - 1)

    ' Use first letter of instrument as single-char stamp
    IF CurrentInstr = 1 THEN PRINT AT #BeatScreenPos COLOR TempVal, "P"
    IF CurrentInstr = 2 THEN PRINT AT #BeatScreenPos COLOR TempVal, "T"
    IF CurrentInstr = 3 THEN PRINT AT #BeatScreenPos COLOR TempVal, "V"
    IF CurrentInstr = 4 THEN PRINT AT #BeatScreenPos COLOR TempVal, "O"
    IF CurrentInstr = 5 THEN PRINT AT #BeatScreenPos COLOR TempVal, "A"
    IF CurrentInstr = 6 THEN PRINT AT #BeatScreenPos COLOR TempVal, "B"
    IF CurrentInstr = 7 THEN PRINT AT #BeatScreenPos COLOR TempVal, "N"
    IF CurrentInstr = 8 THEN PRINT AT #BeatScreenPos COLOR TempVal, "X"
    IF CurrentInstr = 9 THEN PRINT AT #BeatScreenPos COLOR TempVal, "-"
    RETURN
END

' --- Play instrument sound on channel 1 ---
PlayInstrSound: PROCEDURE
    IF CurrentInstr = 9 THEN RETURN  ' REST = silence

    TempVal = CurrentInstr - 1
    #InstrFreq = InstrPeriodData(TempVal)
    InstrVol = InstrVolumeData(TempVal)
    InstrDecayCount = InstrDecayData(TempVal)

    SOUND 1, #InstrFreq, InstrVol

    ' Timpani: add noise
    IF CurrentInstr = 8 THEN
        POKE $1F7, 12
        TempVal = PEEK($1F8) AND $DB  ' Enable noise on channel B
        POKE $1F8, TempVal
    END IF
    RETURN
END

' --- Decay instrument sound each frame ---
UpdateInstrSfx: PROCEDURE
    InstrDecayCount = InstrDecayCount - 1
    IF InstrDecayCount = 0 THEN
        SOUND 1, 1, 0
        ' Disable noise
        TempVal = PEEK($1F8) OR $24
        POKE $1F8, TempVal
    ELSE
        IF InstrVol > 1 THEN InstrVol = InstrVol - 1
        SOUND 1, #InstrFreq, InstrVol
    END IF
    RETURN
END

' --- Update cursor sprite position ---
UpdateCursor: PROCEDURE
    IF TotalBeats = 0 THEN
        ' No beats yet, position at start
        CursorSprX = 8
        CursorSprY = 24  ' Row 2
    ELSE
        GOSUB BeatToScreen
    END IF

    ' Pulse animation
    CursorPulse = CursorPulse + 1
    IF CursorPulse >= 8 THEN CursorPulse = 0

    IF CursorPulse < 4 THEN
        TempVal = GRAM_CURSOR1
    ELSE
        TempVal = GRAM_CURSOR2
    END IF

    SPRITE SPR_CURSOR, CursorSprX + $0300, CursorSprY, TempVal * 8 + COL_YELLOW + $0800
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

' --- Draw sync meter on row 8 (below melody grid) ---
DrawSyncMeter: PROCEDURE
    TempVal = SyncMeter / 5  ' 0-20 blocks

    FOR LoopVar = 0 TO 19
        IF LoopVar < TempVal THEN
            ' Filled block: white per design doc
            PRINT AT 160 + LoopVar, GRAM_SYNC_FULL * 8 + COL_WHITE + $0800
        ELSE
            ' Empty block: dark green (grey stand-in)
            PRINT AT 160 + LoopVar, GRAM_SYNC_EMPTY * 8 + COL_DKGREEN + $0800
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
    IF TempoChoice = 0 THEN PRINT AT 9 COLOR COL_TAN, " 80"
    IF TempoChoice = 1 THEN PRINT AT 9 COLOR COL_TAN, "120"
    IF TempoChoice = 2 THEN PRINT AT 9 COLOR COL_TAN, "160"
    RETURN
END

' --- Draw beat grid (clean black) on rows 2-7 ---
DrawBeatGrid: PROCEDURE
    ' Grid starts empty — only hits and cursor are visible
    ' CLS already cleared it, but ensure it's clean after replays
    FOR LoopVar = 0 TO 5
        #BeatScreenPos = RowStartData(LoopVar)
        FOR TempVal = 0 TO 19
            PRINT AT #BeatScreenPos + TempVal, 0
        NEXT TempVal
    NEXT LoopVar
    RETURN
END

' --- Draw hit quality text on row 9 ---
DrawHitQuality: PROCEDURE
    ' Clear row 9
    PRINT AT 180 COLOR COL_BLACK, "                    "

    IF HitQuality = HIT_PERFECT THEN
        PRINT AT 180 COLOR COL_GREEN, "PERFECT!"
    ELSEIF HitQuality = HIT_GOOD THEN
        PRINT AT 181 COLOR COL_YELLOW, "GOOD"
    ELSEIF HitQuality = HIT_MISS THEN
        PRINT AT 181 COLOR COL_RED, "MISS"
    END IF

    ' Show hit streak
    IF HitStreak >= 3 THEN
        PRINT AT 190 COLOR COL_WHITE, "x"
        PRINT AT 191 COLOR COL_WHITE, <>HitStreak
    END IF
    RETURN
END

' --- Clear hit quality display ---
ClearHitDisplay: PROCEDURE
    PRINT AT 180 COLOR COL_BLACK, "                    "
    RETURN
END

' --- Draw instrument name on row 10 ---
DrawInstrumentName: PROCEDURE
    PRINT AT 200 COLOR COL_BLACK, "                    "

    IF CurrentInstr = 1 THEN PRINT AT 205 COLOR COL_BLUE, "PICCOLO"
    IF CurrentInstr = 2 THEN PRINT AT 205 COLOR COL_YELLOW, "TRUMPET"
    IF CurrentInstr = 3 THEN PRINT AT 206 COLOR COL_WHITE, "VIOLIN"
    IF CurrentInstr = 4 THEN PRINT AT 207 COLOR COL_TAN, "OBOE"
    IF CurrentInstr = 5 THEN PRINT AT 206 COLOR COL_RED, "VIOLA"
    IF CurrentInstr = 6 THEN PRINT AT 204 COLOR COL_GREEN, "TROMBONE"
    IF CurrentInstr = 7 THEN PRINT AT 205 COLOR COL_DKGREEN, "BASSOON"
    IF CurrentInstr = 8 THEN PRINT AT 205 COLOR COL_YELLOW, "TIMPANI"
    IF CurrentInstr = 9 THEN PRINT AT 207 COLOR COL_TAN, "REST"
    RETURN
END

' --- Draw instrument legend on row 11 ---
DrawLegend: PROCEDURE
    PRINT AT 220 COLOR COL_BLUE, "1"
    PRINT AT 222 COLOR COL_YELLOW, "2"
    PRINT AT 224 COLOR COL_WHITE, "3"
    PRINT AT 226 COLOR COL_TAN, "4"
    PRINT AT 228 COLOR COL_RED, "5"
    PRINT AT 230 COLOR COL_GREEN, "6"
    PRINT AT 232 COLOR COL_DKGREEN, "7"
    PRINT AT 234 COLOR COL_YELLOW, "8"
    PRINT AT 236 COLOR COL_TAN, "9"
    PRINT AT 237 COLOR COL_TAN, "R"
    RETURN
END

' --- Draw tempo selection choices ---
DrawTempoChoices: PROCEDURE
    ' Row 3 (pos 60): Adagio
    IF TempoChoice = 0 THEN
        PRINT AT 62 COLOR COL_GREEN, "1 ADAGIO     80"
    ELSE
        PRINT AT 62 COLOR COL_TAN, "1 ADAGIO     80"
    END IF

    ' Row 5 (pos 100): Moderato
    IF TempoChoice = 1 THEN
        PRINT AT 102 COLOR COL_YELLOW, "2 MODERATO  120"
    ELSE
        PRINT AT 102 COLOR COL_TAN, "2 MODERATO  120"
    END IF

    ' Row 7 (pos 140): Allegro
    IF TempoChoice = 2 THEN
        PRINT AT 142 COLOR COL_RED, "3 ALLEGRO   160"
    ELSE
        PRINT AT 142 COLOR COL_TAN, "3 ALLEGRO   160"
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
    SOUND 0, 120, 10
    FOR LoopVar = 0 TO TempVal
        WAIT
    NEXT LoopVar
    SOUND 0, 1, 0
    PRINT AT 109, " "

    ' "3"
    PRINT AT 109 COLOR COL_WHITE, "3"
    SOUND 0, 120, 10
    FOR LoopVar = 0 TO TempVal
        WAIT
    NEXT LoopVar
    SOUND 0, 1, 0
    PRINT AT 109, " "

    ' "2"
    PRINT AT 109 COLOR COL_YELLOW, "2"
    SOUND 0, 120, 10
    FOR LoopVar = 0 TO TempVal
        WAIT
    NEXT LoopVar
    SOUND 0, 1, 0
    PRINT AT 109, " "

    ' "1"
    PRINT AT 109 COLOR COL_GREEN, "1"
    SOUND 0, 60, 14
    FOR LoopVar = 0 TO TempVal
        WAIT
    NEXT LoopVar
    SOUND 0, 1, 0
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
    RETURN
END

' --- Grey out phrase notes on miss ---
' When a phrase breaks, dim all previously hit notes to dark green
GreyOutPhrase: PROCEDURE
    IF PhraseLen < 1 THEN RETURN
    IF TotalBeats < 2 THEN RETURN

    ' Phrase covers beats from (TotalBeats - 1 - PhraseLen) to (TotalBeats - 2)
    ' TotalBeats - 1 = current beat (missed), so phrase ends at TotalBeats - 2
    TempVal = TotalBeats - 2   ' Last hit beat in phrase
    IF TempVal >= PhraseLen THEN
        LoopVar = TempVal - PhraseLen + 1  ' First hit beat in phrase
    ELSE
        LoopVar = 0
    END IF

    WHILE LoopVar <= TempVal
        BeatRow = LoopVar / 20
        BeatCol = LoopVar - (BeatRow * 20)

        ' Odd rows snake right-to-left
        IF BeatRow AND 1 THEN
            BeatCol = 19 - BeatCol
        END IF

        #BeatScreenPos = RowStartData(BeatRow) + BeatCol

        ' Read current BACKTAB card, recolor to dark green
        #Card = PEEK($200 + #BeatScreenPos)
        IF #Card > 0 THEN
            PRINT AT #BeatScreenPos, (#Card AND $EFF8) OR COL_DKGREEN
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

' Tempo: frames per beat
TempoFramesData:
    DATA 45, 30, 22

' Tempo: beats per 45-sec turn
TempoBeatsData:
    DATA 60, 90, 120

' Perfect hit window (frames from beat) - fixed ±75ms = 5 frames at 60fps
PerfectWindowData:
    DATA 5, 5, 5

' Good hit window (frames from beat) - fixed ±125ms = 8 frames at 60fps
GoodWindowData:
    DATA 8, 8, 8

' Row start BACKTAB positions for melody rows 0-5 (screen rows 2-7)
RowStartData:
    DATA 40, 60, 80, 100, 120, 140

' Instrument colors (indexed 0-8 for instruments 1-9)
InstrColorData:
    DATA COL_BLUE, COL_YELLOW, COL_WHITE, COL_TAN, COL_RED, COL_GREEN, COL_DKGREEN, COL_YELLOW, COL_TAN

' Instrument PSG periods
InstrPeriodData:
    DATA 70, 127, 200, 170, 300, 500, 700, 900, 0

' Instrument volumes
InstrVolumeData:
    DATA 12, 14, 13, 10, 12, 14, 13, 15, 0

' Instrument decay (frames)
InstrDecayData:
    DATA 3, 6, 10, 6, 10, 8, 10, 4, 0

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
