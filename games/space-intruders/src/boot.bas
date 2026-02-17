' ============================================
' SPACE INTRUDERS - Boot Module
' ============================================
' Initial program startup and boot animation
' Segment: 0 (main segment)

    SEGMENT 0

' === Boot Sequence ===

' ============================================
' Reset state and return to title screen
' (shared by GameOver=2 and GameOver=6)
' ============================================
ResetToTitle:
    PLAY OFF
    ' Silence all PSG channels (PLAY OFF stops ISR but leaves registers hot)
    SOUND 0, , 0
    SOUND 1, , 0
    SOUND 2, , 0
    POKE $1F8, $3F  ' Disable all tone + noise
    GameOver = 0
    Lives = STARTING_LIVES
    Level = 1
    #Score = 0
    #ScoreHigh = 0
    #NextLife = 1000
    PlayerX = 80
    AlienOffsetX = 0
    AlienOffsetY = 0
    LastClearedY = 0
    AlienDir = 1
    MarchCount = 0
    #GameFlags = #GameFlags AND $FFFC : ABulFrame = 0  ' Clear FLAG_BULLET + FLAG_ABULLET
    RogueState = 0 : RogueTimer = 0 : RogueDivePhase = 0
    FOR LoopVar = 0 TO MAX_BOSSES - 1 : BossHP(LoopVar) = 0 : NEXT LoopVar
    BossCount = 0 : BombExpTimer = 0 : OrbitStep = 255 : OrbitStep2 = 255
    #GameFlags = #GameFlags AND $EFF3  ' Clear FLAG_CAPTURE + FLAG_CAPBULLET + FLAG_KEY0HELD
    #GameFlags = #GameFlags AND ($FFFF XOR FLAG_BOMB)
    MegaTimer = 0
    MegaBeamTimer = 0
    #GameFlags = #GameFlags AND $FFBF
    Key1Held = 0
    #GameFlags = #GameFlags AND $BEFF  ' Clear FLAG_SUBWAVE + FLAG_REVEAL
    RightRevealCol = ALIEN_COLS - 1
    DeathTimer = 0
    Invincible = 0
    ShakeTimer = 0
    SCROLL 0, 0
    GOSUB HideAllSprites

    ' Clean ISR state before transitioning to TitleScreen (prevents ISR pollution from gameplay)
    POKE $0345, 0    ' Clear _gram2_bitmap trigger
    POKE $0108, 0    ' Clear _gram2_total counter

    ' Explicit jump required since TitleScreen is now in SEGMENT 1
    GOTO TitleScreen
