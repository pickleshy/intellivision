' ============================================
' SPACE INTRUDERS - Game Initialization Module
' ============================================
' StartGame procedure - transition from title to gameplay
' Segment: 1

    SEGMENT 1

' === Game Initialization ===

' ============================================
' START GAME - Initialize gameplay
' ============================================
StartGame:
    CLS

    ' Reset score for new game (high score comparison happens at game-over)
    #Score = 0 : #ScoreHigh = 0

    ' Reload ALL gameplay GRAM cards overwritten by animated title font
    ' Cards 0-8: Ship, aliens, bullet
    DEFINE GRAM_SHIP, 2, ShipGfx          ' Cards 0-1
    WAIT
    DEFINE GRAM_ALIEN1, 2, Alien1Gfx      ' Cards 2-3
    WAIT
    DEFINE GRAM_ALIEN2, 2, Alien2Gfx      ' Cards 4-5
    WAIT
    DEFINE GRAM_ALIEN3, 2, Alien3Gfx      ' Cards 6-7
    WAIT
    DEFINE GRAM_ALIEN4, 2, Alien4Gfx      ' Cards 19-20
    WAIT
    DEFINE GRAM_ALIEN5, 2, Alien5Gfx      ' Cards 30-31
    WAIT
    DEFINE GRAM_BULLET, 1, BulletGfx      ' Card 8
    WAIT
    ' Cards 9-12: Band (preserved during title - already correct from init)
    ' But reload to ensure consistency after any title animation quirks
    DEFINE GRAM_BAND1, 1, Band1Gfx
    WAIT
    DEFINE GRAM_BAND2, 1, Band2Gfx
    WAIT
    DEFINE GRAM_BAND1_F1, 1, Band1F1Gfx
    WAIT
    DEFINE GRAM_BAND2_F1, 1, Band2F1Gfx
    WAIT
    ' Cards 13-18: Wingman, explosions, ship accent
    DEFINE GRAM_WINGMAN_F1, 1, WingmanF1Gfx  ' Card 13
    WAIT
    DEFINE GRAM_EXPLOSION, 1, ExplosionGfx    ' Card 14
    WAIT
    DEFINE GRAM_EXPLOSION2, 1, ExplosionGfx2  ' Card 15
    WAIT
    DEFINE GRAM_EXPLOSION3, 1, ExplosionGfx3  ' Card 16
    WAIT
    DEFINE GRAM_SHIP_ACCENT, 2, ShipAccentGfx ' Cards 17-18
    WAIT
    DEFINE GRAM_SILH_1Q, 4, SilhGfx           ' Cards 21-24: silhouette fill levels
    WAIT

    ' Redefine title font GRAM cards (25-27) for powerup HUD (TinyFont)
    ' 3 generic cards: DEFINE'd per powerup type at pickup time
    ' Default to BEAM ("BE" + "AM") so cards aren't garbage
    DEFINE GRAM_PWR1, 2, PowerupBeamGfx  ' Cards 25-26: BE, AM
    WAIT
    DEFINE GRAM_SHIELD, 1, ShieldArcGfx  ' Card 33: Shield arc
    WAIT
    DEFINE GRAM_WARP1, 3, WarpInGfx1    ' Cards 34-36: Warp-in animation
    WAIT
    ' Cards 39-55: Saucer, beams, capsules, bombs, zigzag
    DEFINE GRAM_SAUCER, 1, SaucerGfx      ' Card 39 (single frame, animation via color shift)
    WAIT
    DEFINE GRAM_BEAM, 1, BeamGfx          ' Card 40
    WAIT
    ' Card 42 freed for alien substep shift-2
    WAIT
    DEFINE GRAM_SHIP_HUD, 1, ShipHudGfx   ' Card 45
    WAIT
    DEFINE GRAM_SOL36, 1, Sol36Gfx ' Card 46
    WAIT
    DEFINE GRAM_ORBITER, 1, SmallCrabF1Gfx ' Card 47: orbiter sprite (small crab)
    WAIT
    DEFINE GRAM_CAP_F1, 4, CapsuleF1Gfx   ' Cards 48-51
    WAIT
    DEFINE GRAM_ZIGZAG1, 2, ZigzagF1Gfx   ' Cards 52-53
    WAIT
    DEFINE GRAM_BOMB1, 2, SquidLeftF1Gfx  ' Cards 54-55
    WAIT
    DEFINE GRAM_BOMB1_F1, 1, SquidLeftF2Gfx  ' Card 56 (overwritten by title anim)
    WAIT
    DEFINE GRAM_BOMB2_F1, 1, SquidRightF2Gfx ' Card 57
    WAIT
    DEFINE GRAM_CHAIN_CH, 3, ChainCHGfx   ' Cards 58-60: Chain labels
    WAIT
    ' Initialize score digit display (skip label cards 0-2 during first wave reveal)
    ScoreCard = 2    ' First call goes to ScoreCard=3 (card 32 = GRAM_SCORE_M)
    GOSUB UpdateScoreDisplay : WAIT   ' ScoreCard = 3 (D6D5 millions, card 32)
    GOSUB UpdateScoreDisplay : WAIT   ' ScoreCard = 4 (D4D3 ten-thousands+thousands, card 61)
    GOSUB UpdateScoreDisplay : WAIT   ' ScoreCard = 5 (D2D1 hundreds+tens, card 62)
    GOSUB UpdateScoreDisplay : WAIT   ' ScoreCard = 6 (D0 ones, card 63)
    GOSUB UpdateScoreDisplay : WAIT   ' ScoreCard = 7 (chain digit, card 28 = GRAM_CHAIN_DIG)
    GOSUB UpdateScoreDisplay : WAIT   ' ScoreCard = 8 (lives digit, card 29 = GRAM_LIVES_DIG)

    ' Initialize all aliens as alive (9 bits = $1FF)
    FOR LoopVar = 0 TO ALIEN_ROWS - 1
        #AlienRow(LoopVar) = $1FF
    NEXT LoopVar

    ' Initialize level, march speed, and wave 1 palette
    Level = 1
    WaveColor0 = 6 : WaveColor1 = 1 : WaveColor2 = 5 : WaveColor3 = 2 : WaveColor4 = 7  ' Yel / Blu / Grn / Red / Wht
    BaseMarchSpeed = MARCH_SPEED_START
    CurrentMarchSpeed = MARCH_SPEED_START
    MusicGear = 0
    WaveRevealRow = 0
    #GameFlags = #GameFlags AND $BEFF  ' Clear FLAG_SUBWAVE + FLAG_REVEAL
    LoopVar = 0  ' Wave 1 = index 0
    GOSUB SetEntrancePattern
    RightRevealCol = ALIEN_COLS - 1

    ' Draw HUD (score=0, chain=0, lives=3 at game start — DrawHUD handles it)
    GOSUB DrawHUD

    ' Initialize parallax silhouette on row 0
    SilhOffset = 0
    StarTimer = 0
    GOSUB DrawSilhouette

    ' Initialize saucer (inactive, random spawn delay 1-4 seconds)
    FlyState = 0
    #FlyPhase = 0  ' Spawn countdown (counts up to threshold)
    #FlyLoopCount = RANDOM(360) + 180  ' Random spawn threshold
    BeamTimer = 0  ' No beam power-up
    RapidTimer = 0 ' No rapid fire
    #GameFlags = #GameFlags AND ($FFFF XOR FLAG_BOMB)  ' No bomb weapon
    Sol36Timer = 0  ' No mega beam
    Sol36BeamTimer = 0
    ShieldHits = 0  ' No shield
    PowerUpState = 0  ' No power-up drop
    ' Weighted power-up: 0=beam(2), 1=rapid(3), 2=bomb(2), 3=mega(1) out of 8
    PowerUpType = PowerUpWeights(RANDOM(8))
    FireCooldown = 0 ' No fire cooldown
    CapsuleFrame = 0  ' Reset capsule animation (title-shared)
    CapsuleColor1 = 0 ' Reset temp color storage (title-shared)
    CapsuleColor2 = 0 ' Reset temp color storage (title-shared)
    ChainCount = 0  ' Reset kill chain
    ChainMax = 0    ' Reset best chain for new game
    RogueState = 0 : RogueTimer = 0 : RogueDivePhase = 0
    FOR LoopVar = 0 TO MAX_BOSSES - 1 : BossHP(LoopVar) = 0 : NEXT LoopVar
    BossCount = 0 : BombExpTimer = 0 : OrbitStep = 255 : OrbitStep2 = 255 : BossType(0) = SKULL_TYPE  ' Wave 1 has no boss
    #GameFlags = #GameFlags AND $FFF3  ' Clear FLAG_CAPTURE + FLAG_CAPBULLET
    CaptureWaves = 0                 ' Reset captured alien wave counter
    TutorialTimer = 255              ' Ready to show "GET THE POWERUP!" on first drop
    SPRITE SPR_FLYER, 0, 0, 0
    SPRITE SPR_SAUCER, 0, 0, 0
    SPRITE SPR_SAUCER2, 0, 0, 0
    SPRITE SPR_POWERUP, 0, 0, 0

    ' Wave 1 announcement — same WaveAnnouncerTimer system as waves 2+
    ' GameLoop drives the static display (70 frames) then spin-out (20 frames)
    IF VOICE.AVAILABLE THEN
        VOICE PLAY wave_phrase
        VOICE NUMBER 1
    END IF
    PLAY si_bg_mid
    WaveAnnouncerTimer = 90
    WaveAnnouncerType = 1
    WaveBannerPhase = 0
    WaveBannerFrame = 0
    DEFINE GRAM_FONT_T, 1, WaveSpinWGfx     ' Card 32 = W narrow (first spin phase)
    DEFINE GRAM_ORBITER, 1, WaveSpinEdgeGfx ' Card 47 = edge-on (shared all phases)
    GOSUB DrawWaveBanner                     ' Show banner immediately; GameLoop maintains + spins out

    ' Ship reveal animation (procedure in Segment 2)
    GOSUB ShipReveal

    ' Initialize player sprite (removes BEHIND flag)
