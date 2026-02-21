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

' --- AddToScore: Add points to 32-bit score with carry propagation ---
' Call with: #Mask = X : GOSUB AddToScore  (X is the amount to add, as 16-bit)
' Carry detection: if result < addend, overflow occurred
' PLACED FIRST to avoid forward reference issues across segments
AddToScore: PROCEDURE
    #Score = #Score + #Mask     ' Add points (in #Mask) to lower 16 bits
    IF #Score < #Mask THEN      ' If result < addend, carry (unsigned overflow)
        #ScoreHigh = #ScoreHigh + 1   ' Increment upper 16 bits
    END IF
    RETURN
END

' --- BootSplash: 1-second TinyFont developer URL at startup ---
BootSplash: PROCEDURE
    ' Load TinyFont pairs into temporary GRAM cards 0-10 for URL line
    DEFINE 0, 4, SplashBatch0
    WAIT
    DEFINE 4, 4, SplashBatch1
    WAIT
    DEFINE 8, 3, SplashBatch2
    WAIT
    ' Load QR tiles into cards 11-35 and draw 5x5 grid (rows 1-5, cols 7-11)
    GOSUB DrawQrCode
    ' Line 1: PAISLEYBOXERS.ITCH.IO (row 7, col 5, 11 cards TinyFont — below QR)
    FOR LoopVar = 0 TO 10
        PRINT AT 145 + LoopVar, LoopVar * 8 + COL_WHITE + $0800
    NEXT LoopVar
    ' Line 2: BETA - MM/DD/YYYY (row 10, centered, GROM font via generated procedure)
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
    IF ScoreCard > 8 THEN ScoreCard = 0

    ' Guard: skip label cards during warp-in reveal (cards 34-36 in use)
    ' Only applies to ScoreCards 0-2 (label cards that use cards 34-36).
    ' ScoreCard=3 (GRAM_SCORE_M, card 32) is independent and must NOT be guarded.
    IF ScoreCard < 3 THEN
        IF WaveRevealCol < ALIEN_COLS - 1 THEN
            ScoreCard = 4
        ELSEIF WaveEntrance = 1 THEN
            IF WaveRevealRow < ALIEN_ROWS - 1 THEN
                ScoreCard = 4
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
        ' Card SCORE_CARD_M: millions + hundred-thousands
        ' ScorePairM cached by ScoreCard=4 (1 frame earlier in cycle).
        ' Always writes "00" when score < 100,000 → zero-padded 7-digit display.
        #Mask = ScorePairM
        POKE $0107, SCORE_CARD_M
    ELSEIF ScoreCard = 4 THEN
        ' Card 61: ten-thousands + thousands (pair index 0-99)
        ' 32-bit: 65536 = 65*1000 + 536, so total/1000 = H*65 + (H*536 + L mod 1000)/1000
        #Mask = #Score / 1000               ' L_th: thousands in lower word (0-65, max 655 iters)
        IF #ScoreHigh > 0 THEN
            ' Save L_th, compute (H*536 + L mod 1000) for carry into thousands
            #ScreenPos = #Mask              ' Preserve L_th in scratch 16-bit var
            #Mask = #Score - #Mask * 1000  ' L_mod1000 (0-999)
            #Mask = #Mask + #ScoreHigh * 536  ' Adjusted bucket (~80 cycle mul, safe H≤122)
            LoopVar = #Mask / 1000         ' Carry from mod-1000 bucket (0-5 for H≤10)
            #Mask = #ScreenPos + #ScoreHigh * 65 + LoopVar  ' Total thousands (0-999)
            ScorePairM = #Mask / 100       ' Cache million+hundred-thousands pair index
            #Mask = #Mask - ScorePairM * 100  ' Ten-thousands+thousands pair (0-99)
        ELSE
            ScorePairM = 0                 ' Score ≤ 65535: no hundred-thousands digits
        END IF
        POKE $0107, SCORE_CARD0
    ELSEIF ScoreCard = 5 THEN
        ' Card 62: hundreds + tens (pair index 0-99)
        ' 32-bit: (total mod 1000) / 10 = ((H*536 + L mod 1000) mod 1000) / 10
        #Mask = #Score / 1000
        #Mask = #Score - #Mask * 1000       ' L_mod1000 (0-999, needs 16-bit)
        IF #ScoreHigh > 0 THEN
            #Mask = #Mask + #ScoreHigh * 536  ' Adjusted bucket (~80 cycle mul, safe H≤122)
            HitRow = #Mask / 1000            ' Carry (8-bit safe for H≤122: max 54)
            #Mask = #Mask - HitRow * 1000    ' total mod 1000 (0-999)
        END IF
        ' PERF: /10 on 0-999 = 99 iters. Use /100 (9 iters) + /10 (9 iters) + mul.
        HitRow = #Mask / 100               ' Hundreds digit (0-9, max 9 iters ~200 cycles)
        #Mask = #Mask - HitRow * 100       ' L mod 100 (0-99)
        Col = #Mask / 10                   ' Tens digit (0-9 iters ~200 cycles) audit-ignore: bounded 0-99 by prior /100
        #Mask = HitRow * 10 + Col          ' Hundreds+tens pair (0-99)
        POKE $0107, SCORE_CARD1
    ELSEIF ScoreCard = 6 THEN
        ' Card 63: ones + blank (pair index 100-109)
        ' PERF: Avoid #Score/100 (up to 655 iters at max score).
        ' Use /1000 (max 65 iters) → mod1000 → /100 (max 9) → mod100 → /10 (max 9).
        ' 32-bit correction: 65536 mod 10 = 6, so ones digit += (H*6) mod 10
        #Mask = #Score / 1000              ' Same budget as ScoreCard=4,5 (max 65 iters)
        #Mask = #Score - #Mask * 1000     ' L_mod1000 (0-999)
        HitRow = #Mask / 100              ' Hundreds (0-9 iters ~200 cycles)
        #Mask = #Mask - HitRow * 100      ' L mod 100 (0-99)
        HitRow = #Mask / 10               ' Tens (0-9 iters ~200 cycles) audit-ignore: bounded 0-99 by prior /100
        #Mask = #Mask - HitRow * 10       ' ones_L = L mod 10 (0-9)
        IF #ScoreHigh > 0 THEN
            ' Add H's contribution to ones: H * (65536 mod 10) = H * 6, then mod 10
            #Card = #ScoreHigh * 6        ' H*6 (~80 cycle mul; ≤ 65535 for H ≤ 10922)
            HitRow = #Card / 10           ' Tens of H*6 (max 60 iters for H≤100) audit-ignore: H≤10 in practice
            #Card = #Card - HitRow * 10   ' H*6 mod 10 (0-9)
            #Mask = #Mask + #Card         ' ones_L + H_ones (0-18, fits in 16-bit)
            IF #Mask >= 10 THEN #Mask = #Mask - 10  ' Final ones digit (0-9)
        END IF
        #Mask = #Mask + 100
        POKE $0107, SCORE_CARD2
    ELSEIF ScoreCard = 7 THEN
        ' Card 28: chain digit (TinyFont via PackedPairs)
        ' Shows "00" through "99" - leading zero for single digits
        POKE $0107, GRAM_CHAIN_DIG
        #Mask = ChainCount  ' PackedPairs index 0="00", 1="01", ..., 99="99"
    ELSEIF ScoreCard = 8 THEN
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
    ShieldHits = ShieldHits - 1  ' audit-ignore: all callers guard with IF ShieldHits > 0 THEN
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
    #Mask = BOSS_SCORE : GOSUB AddToScore
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

' --- DoScreenShake: Apply scroll offset based on ShakeTimer bits ---
' Call while ShakeTimer > 0 (after decrement) to produce shake pattern
DoScreenShake: PROCEDURE
    IF ShakeTimer AND 2 THEN
        SCROLL 1, 0
    ELSEIF ShakeTimer AND 1 THEN
        SCROLL 0, 1
    ELSE
        SCROLL -1, 0
    END IF
    RETURN
END

    ' ============================================================

' Segment 2 — shared display helper (keeps Segment 1 budget clear)
    SEGMENT 2

' --- PrintScore7Grom: print 7 GROM zero-padded score digits ---
' Inputs:
'   #ScreenPos = D6D5D4D3 (total/1000, 0-9999)
'   #Mask      = D2D1D0   (total mod 1000, 0-999)
'   ShootTimer = starting BACKTAB position (advanced by 6 internally)
'   ABulFrame  = GROM foreground color bits (e.g. COL_WHITE=7, COL_YELLOW=6)
' Clobbers: Col
PrintScore7Grom: PROCEDURE
    Col = #ScreenPos / 1000               ' D6 millions (0-9)
    PRINT AT ShootTimer, (16 + Col) * 8 + ABulFrame
    ShootTimer = ShootTimer + 1
    #ScreenPos = #ScreenPos - Col * 1000
    Col = #ScreenPos / 100                ' D5 hundred-thousands (0-9)
    PRINT AT ShootTimer, (16 + Col) * 8 + ABulFrame
    ShootTimer = ShootTimer + 1
    #ScreenPos = #ScreenPos - Col * 100
    Col = #ScreenPos / 10                 ' D4 ten-thousands (0-9) audit-ignore: bounded 0-99 by prior /100
    PRINT AT ShootTimer, (16 + Col) * 8 + ABulFrame
    Col = #ScreenPos - Col * 10           ' D3 thousands (0-9, uses old Col=D4)
    ShootTimer = ShootTimer + 1
    PRINT AT ShootTimer, (16 + Col) * 8 + ABulFrame
    ShootTimer = ShootTimer + 1
    Col = #Mask / 100                     ' D2 hundreds (0-9)
    PRINT AT ShootTimer, (16 + Col) * 8 + ABulFrame
    ShootTimer = ShootTimer + 1
    #Mask = #Mask - Col * 100
    Col = #Mask / 10                      ' D1 tens (0-9) audit-ignore: bounded 0-99 by prior /100
    PRINT AT ShootTimer, (16 + Col) * 8 + ABulFrame
    Col = #Mask - Col * 10                ' D0 ones (0-9, uses old Col=D1)
    ShootTimer = ShootTimer + 1
    PRINT AT ShootTimer, (16 + Col) * 8 + ABulFrame
    RETURN
END

' ============================================================
' SEGMENT 2 — PROCEDURES MOVED HERE TO RELIEVE SEG 1 PRESSURE
' Cross-segment GOSUB works fine with OPTION MAP 2.
' ============================================================
    SEGMENT 2

' --- ResetAlienGrid: zero alien position / direction / march state ---
' Called by StartNewWave and ReloadHorde in waves.bas.
' Does NOT reset CurrentMarchSpeed (caller handles that, since each site uses a different value).
ResetAlienGrid: PROCEDURE
    AlienOffsetX = 0
    AlienOffsetY = 0
    LastClearedY = 0
    AlienDir = 1
    MarchCount = 0
    RETURN
END

' --- DebugCycleWeapon: cycle powerup weapons on debug key 2 ---
' Caller (gameloop.bas) checks CONT.KEY=2 and debounce bit $0400 before calling.
' Sets $0400 held-flag then activates the next weapon in the cycle:
'   nothing/shield → beam → rapid → bomb → mega → shield → ...
DebugCycleWeapon: PROCEDURE
    #GameFlags = #GameFlags OR $0400
    IF Sol36Timer > 0 THEN
        ShieldHits = 2 : Sol36Timer = 0
    ELSEIF #GameFlags AND FLAG_BOMB THEN
        Sol36Timer = 120
        BeamTimer = 0 : RapidTimer = 0
        #GameFlags = #GameFlags AND ($FFFF XOR FLAG_BOMB)
        DEFINE GRAM_PWR1, 3, PowerupSol36Gfx
    ELSEIF RapidTimer > 0 THEN
        #GameFlags = #GameFlags OR FLAG_BOMB
        BeamTimer = 0 : RapidTimer = 0 : Sol36Timer = 0
        DEFINE GRAM_PWR1, 2, PowerupBombGfx
    ELSEIF BeamTimer > 0 THEN
        RapidTimer = 1
        BeamTimer = 0 : #GameFlags = #GameFlags AND ($FFFF XOR FLAG_BOMB) : Sol36Timer = 0
        DEFINE GRAM_PWR1, 3, PowerupRapidGfx
    ELSE
        BeamTimer = 1
        RapidTimer = 0 : #GameFlags = #GameFlags AND ($FFFF XOR FLAG_BOMB) : Sol36Timer = 0
        DEFINE GRAM_PWR1, 2, PowerupBeamGfx
    END IF
    RETURN
END

' --- ShieldOrDamage: absorb hit via shield, or flag player hit with SFX ---
' Used by alien bullet, rogue dive, and saucer body collision sites.
ShieldOrDamage: PROCEDURE
    IF ShieldHits > 0 THEN
        GOSUB HitShield
    ELSE
        #GameFlags = #GameFlags OR FLAG_PLAYERHIT
        SfxType = 3 : SfxVolume = 15 : #SfxPitch = 0
        SOUND 2, 0, 15
        POKE $1F9, 14
        POKE $1F8, PEEK($1F8) AND $DF
    END IF
    RETURN
END
