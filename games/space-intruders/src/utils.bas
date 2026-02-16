' ============================================
' SPACE INTRUDERS - Utilities Module
' ============================================
' Reusable helper functions shared across all systems
' Segment: 1

    SEGMENT 1

' === Shared Utility Procedures ===

    ' SEGMENT 1 — UTILITY & CORE GAMEPLAY PROCEDURES
    ' ============================================================
    SEGMENT 1

' --- BootSplash: 1-second TinyFont developer URL at startup ---
BootSplash: PROCEDURE
    ' Load TinyFont pairs into temporary GRAM cards 0-10 for URL line
    DEFINE 0, 4, SplashBatch0
    WAIT
    DEFINE 4, 4, SplashBatch1
    WAIT
    DEFINE 8, 3, SplashBatch2
    WAIT
    ' Line 1: PAISLEYBOXERS.ITCH.IO (row 5, col 5, 11 cards TinyFont)
    FOR LoopVar = 0 TO 10
        PRINT AT 105 + LoopVar, LoopVar * 8 + COL_WHITE + $0800
    NEXT LoopVar
    ' Line 2: BETA - MM/DD/YYYY (row 7, centered, GROM font via generated procedure)
    GOSUB SplashDate_Print
    ' Hold for ~3 seconds
    FOR LoopVar = 0 TO 179
        WAIT
    NEXT LoopVar
    CLS
    WAIT
    RETURN
END

' ============================================
' UTILITY PROCEDURES (shared code consolidation)
' ============================================

    SEGMENT 2  ' UpdateScoreDisplay moved to Seg 2 (Seg 1 critically full)

' --- UpdateScoreDisplay: Update 1 GRAM card per frame via DEFINE ALTERNATE ---
' POKEs ISR's _gram2_* variables so the ISR copies data to GRAM during VBLANK.
' 7-card round-robin: cards 34-36 (TinyFont "SC"/"OR"/"E:" label) +
' cards 61-63 (packed digits D4D3/D2D1/D0) + card 28 (chain digit).
' Chain label cards 58-60 are static (defined once at StartGame).
' Chain digit card 28 uses PackedPairs for TinyFont digit rendering.
' Lives digit card 29 uses PackedPairs for TinyFont digit rendering.
' Full cycle = 8 frames. Reveal guard skips label cards during warp-in.
' Label cards also write their BACKTAB entry (synced with GRAM update at VBLANK).
UpdateScoreDisplay: PROCEDURE
    ScoreCard = ScoreCard + 1
    IF ScoreCard > 7 THEN ScoreCard = 0

    ' Guard: skip label cards during warp-in reveal (cards 34-36 in use)
    IF ScoreCard < 3 THEN
        IF WaveRevealCol < ALIEN_COLS - 1 THEN
            ScoreCard = 3
        ELSEIF WaveEntrance = 1 THEN
            IF WaveRevealRow < ALIEN_ROWS - 1 THEN
                ScoreCard = 3
            END IF
        END IF
    END IF

    IF ScoreCard = 0 THEN
        ' Card 34: TinyFont "SC" label + BACKTAB at 220
        POKE $0107, 34
        #Mask = VARPTR TinyFontLabelData(0)
        IF GameOver = 0 THEN PRINT AT 220, GRAM_WARP1 * 8 + COL_WHITE + $0800
    ELSEIF ScoreCard = 1 THEN
        ' Card 35: TinyFont "OR" label + BACKTAB at 221
        POKE $0107, 35
        #Mask = VARPTR TinyFontLabelData(0) + 4
        IF GameOver = 0 THEN PRINT AT 221, GRAM_WARP2 * 8 + COL_WHITE + $0800
    ELSEIF ScoreCard = 2 THEN
        ' Card 36: TinyFont "E:" label + BACKTAB at 222
        POKE $0107, 36
        #Mask = VARPTR TinyFontLabelData(0) + 8
        IF GameOver = 0 THEN PRINT AT 222, GRAM_WARP3 * 8 + COL_WHITE + $0800
    ELSEIF ScoreCard = 3 THEN
        ' Card 61: ten-thousands + thousands (pair index 0-65)
        #Mask = #Score / 1000
        POKE $0107, SCORE_CARD0
    ELSEIF ScoreCard = 4 THEN
        ' Card 62: hundreds + tens (pair index 0-99)
        #Mask = #Score / 1000
        #Mask = #Score - #Mask * 1000
        #Mask = #Mask / 10
        POKE $0107, SCORE_CARD1
    ELSEIF ScoreCard = 5 THEN
        ' Card 63: ones + blank (pair index 100-109)
        #Mask = #Score / 10
        #Mask = #Score - #Mask * 10
        #Mask = #Mask + 100
        POKE $0107, SCORE_CARD2
    ELSEIF ScoreCard = 6 THEN
        ' Card 28: chain digit (TinyFont via PackedPairs)
        POKE $0107, GRAM_CHAIN_DIG
        IF ChainCount >= 10 THEN
            ' Two-digit: PackedPairs index = ChainCount directly (tens*10+ones)
            #Mask = ChainCount
        ELSE
            ' Single digit or zero: PackedPairs index 100+ (digit + blank)
            #Mask = ChainCount + 100
        END IF
    ELSE
        ' Card 29: lives digit (TinyFont via PackedPairs)
        POKE $0107, GRAM_LIVES_DIG
        IF Lives > 10 THEN
            #Mask = Lives - 1
        ELSEIF Lives > 0 THEN
            #Mask = Lives + 99
        ELSE
            #Mask = 100
        END IF
    END IF

    ' Compute ROM address for PackedPairs entries (score + chain digits)
    IF ScoreCard >= 3 THEN
        #Mask = #Mask + #Mask  ' *2
        #Mask = #Mask + #Mask  ' *4
        #Mask = VARPTR PackedPairs(0) + #Mask
    END IF

    ' CRITICAL: Set _gram2_total BEFORE _gram2_bitmap (the trigger).
    ' ISR gates on _gram2_bitmap != 0; if set first with _gram2_total still 0,
    ' ISR's DECR+BNE loop wraps to 65535 iterations.
    POKE $0108, 1           ' _gram2_total = 1 card (set before trigger)
    POKE $0345, #Mask       ' _gram2_bitmap = source ROM address (TRIGGER — last)
    RETURN
END

    SEGMENT 1  ' Back to Seg 1 for remaining utility procedures

HideAllSprites: PROCEDURE
    SPRITE 0, 0, 0, 0 : SPRITE 1, 0, 0, 0
    SPRITE 2, 0, 0, 0 : SPRITE 3, 0, 0, 0
    SPRITE 4, 0, 0, 0 : SPRITE 5, 0, 0, 0
    SPRITE 6, 0, 0, 0 : SPRITE 7, 0, 0, 0
    RETURN
END

' --- HitShield: Absorb a hit on the shield, announce if shields down ---
HitShield: PROCEDURE
    ShieldHits = ShieldHits - 1
    SfxType = 9 : SfxVolume = 12 : #SfxPitch = 800
    SOUND 2, 800, 12
    IF ShieldHits = 0 THEN
        IF VOICE.AVAILABLE THEN VOICE PLAY shields_down_phrase
    END IF
    RETURN
END

' --- ReloadBandSprites: Restore alien band GRAM (cards 9-12) ---
' Game over TinyFont overwrites cards 9-12; call before DrawAlienGrid on title screen.
ReloadBandSprites: PROCEDURE
    DEFINE GRAM_BAND1, 2, Band1Gfx       ' Cards 9-10: skull left/right frame 1
    WAIT
    DEFINE GRAM_BAND1_F1, 2, Band1F1Gfx  ' Cards 11-12: skull left/right frame 2
    WAIT
    RETURN
END

' --- SilenceSfx: Stop all sound effects on channel 3 ---
SilenceSfx: PROCEDURE
    SOUND 2, , 0
    SfxVolume = 0
    SfxType = 0
    RETURN
END

' --- ClearRogueOnly: Reset rogue alien state (preserves wingman) ---
ClearRogueOnly: PROCEDURE
    RogueState = 0 : RogueTimer = 0 : RogueDivePhase = 0
    SPRITE SPR_FLYER, 0, 0, 0
    RETURN
END

' --- BumpChain: Increment chain combo, update max, reset timeout ---
BumpChain: PROCEDURE
    ChainCount = ChainCount + 1
    IF ChainCount > ChainMax THEN ChainMax = ChainCount
    IF ChainCount > 50 THEN ChainCount = 50
    ChainTimeout = 90
    RETURN
END

' --- ClearPrevExplosion: Wipe old explosion tile before placing new one ---
ClearPrevExplosion: PROCEDURE
    IF ExplosionTimer > 0 THEN
        IF #ExplosionPos < 220 THEN PRINT AT #ExplosionPos, 0
    END IF
    RETURN
END

' --- ShowChainExplosion: Display explosion with chain-color logic ---
' Expects: #ExplosionPos already set to desired BACKTAB position
ShowChainExplosion: PROCEDURE
    IF #ExplosionPos < 220 THEN
        IF ChainCount >= 2 THEN
            ExplosionTimer = 16
            PRINT AT #ExplosionPos, GRAM_EXPLOSION * 8 + COL_WHITE + $0800
        ELSE
            ExplosionTimer = 15
            PRINT AT #ExplosionPos, GRAM_EXPLOSION * 8 + 4 + $1800
        END IF
    END IF
    RETURN
END

' --- SkullBossGridClear: Remove skull boss from grid (guarded XOR) ---
' Input: FoundBoss (global). Clobbers: #Mask
SkullBossGridClear: PROCEDURE
    #Mask = ColMaskData(BossCol(FoundBoss))
    IF #AlienRow(BossRow(FoundBoss)) AND #Mask THEN
        #AlienRow(BossRow(FoundBoss)) = #AlienRow(BossRow(FoundBoss)) XOR #Mask
    END IF
    #Mask = ColMaskData(BossCol(FoundBoss) + 1)
    IF #AlienRow(BossRow(FoundBoss)) AND #Mask THEN
        #AlienRow(BossRow(FoundBoss)) = #AlienRow(BossRow(FoundBoss)) XOR #Mask
    END IF
    RETURN
END

' --- SkullBossDeath: Full skull boss death (grid + BACKTAB + score + explosion + SFX) ---
' Input: FoundBoss (global). Calls: SkullBossGridClear
SkullBossDeath: PROCEDURE
    GOSUB SkullBossGridClear
    #ExplosionPos = (ALIEN_START_Y + AlienOffsetY + BossRow(FoundBoss)) * 20 + ALIEN_START_X + AlienOffsetX + BossCol(FoundBoss)
    IF #ExplosionPos < 220 THEN PRINT AT #ExplosionPos, 0
    IF #ExplosionPos + 1 < 220 THEN PRINT AT #ExplosionPos + 1, 0
    #Score = #Score + BOSS_SCORE
    ExplosionTimer = 20
    IF #ExplosionPos < 220 THEN
        PRINT AT #ExplosionPos, GRAM_EXPLOSION * 8 + COL_RED + $1800
    END IF
    SfxType = 1 : SfxVolume = 15 : #SfxPitch = 80
    SOUND 2, 80, 15
    RETURN
END

' --- FindBossAtCell: Look up boss at AlienGridRow/AlienGridCol ---
' Input:  AlienGridRow, AlienGridCol (globals)
' Output: FoundBoss (0..BossCount-1 if found, 255 if not)
FindBossAtCell: PROCEDURE
    FoundBoss = 255
    IF BossCount > 0 THEN
        FOR LoopVar = 0 TO BossCount - 1
            IF BossHP(LoopVar) > 0 THEN
                IF AlienGridRow = BossRow(LoopVar) THEN
                    IF AlienGridCol = BossCol(LoopVar) OR AlienGridCol = BossCol(LoopVar) + 1 THEN
                        FoundBoss = LoopVar
                    END IF
                END IF
            END IF
        NEXT LoopVar
    END IF
    RETURN
END

    ' ============================================================
