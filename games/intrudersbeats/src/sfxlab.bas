' ============================================================
' Space Intruders SFX Lab
' 27 creative arcade & Intellivision-inspired sound effects
' 3 pages x 9 sounds each — full 3-channel PSG (no music ISR)
'
' PAGE 1: LASERS      PAGE 2: EXPLOSIONS    PAGE 3: DEATHS
'  1: CLASSIC ZAP      1: TINY PUFF          1: QUICK SPLAT
'  2: GALAGA DUAL      2: ASTEROID SPLIT     2: ASTROSMASH BOOM
'  3: SI MISSILE       3: GALAGA MID-SHIP    3: SAD DESCENT
'  4: DEFENDER CRACK   4: CAPITAL SHIP       4: ROBOTIC FAILURE
'  5: PLASMA CANNON    5: SHOCKWAVE BOMB     5: ELECTRIC FIZZLE
'  6: TWIN LASER       6: METAL CRUNCH       6: LONG WAIL
'  7: TEMPEST ZAP      7: CHAIN REACTION     7: SIREN WINDDOWN
'  8: RICOCHET BOING   8: NUCLEAR FLASH      8: VAPORIZE
'  9: RAPID FIRE       9: BOSS MELTDOWN      9: GRAND FINALE
'
' Controls:
'   Keypad 1-9 = Trigger SFX for current page
'   Keypad 0   = Silence
'   CLEAR (10) = Previous page
'   ENTER (11) = Next page
'
' Build: ./build_sfxlab.sh [run]
' ============================================================

OPTION MAP 2        ' Use 42K static map — ROM overflows 8K default

' --- PSG $1F8 Enable Register bitmasks (0 = channel ON, 1 = OFF) ---
CONST EN_SILENT     = $3F   ' All off
CONST EN_TONE_C     = $3B   ' Tone C only
CONST EN_NOISE_C    = $1F   ' Noise C only
CONST EN_TC_NC      = $1B   ' Tone C + Noise C
CONST EN_TONE_A     = $3E   ' Tone A only
CONST EN_TA_TC      = $3A   ' Tone A + Tone C
CONST EN_TA_NC      = $1E   ' Tone A + Noise C
CONST EN_TA_NA      = $36   ' Tone A + Noise A
CONST EN_NA         = $37   ' Noise A only
CONST EN_ABC        = $38   ' Tone A + B + C
CONST EN_ABC_NC     = $18   ' Tone A + B + C + Noise C

' --- SFX State ---
sfx_type = 0        ' 0=silent, 1-9=laser, 10-18=explosion, 19-27=death
sfx_timer = 0       ' Frames remaining (decremented before dispatch)
sfx_phase = 0       ' Multi-phase tracker (reused per sound)
#sfx_freq = 0       ' Channel C period (16-bit, higher = lower pitch)
#sfx_freq2 = 0      ' Channel A period (for dual/tri-channel sounds)
sfx_vol = 0         ' Channel C volume (0-15)
sfx_vol2 = 0        ' Channel A volume
sfx_vol3 = 0        ' Channel B volume OR burst counter (shared)

' --- UI State ---
page = 0            ' 0=Lasers, 1=Explosions, 2=Deaths
prev_k = 12         ' Debounce — last key
misc = 0            ' Scratch variable

' --- Init ---
    CLS
    MODE 0, 0, 0, 0, 0
    WAIT
    SOUND 0, 0, 0 : SOUND 1, 0, 0 : SOUND 2, 0, 0
    POKE $1F8, EN_SILENT

    GOSUB DrawPage
    PRINT AT 0 COLOR 7, "SFX LAB  CLR/ENT=PG "

MainLoop:
    WAIT
    GOSUB UpdateSfx
    k = CONT.key
    IF k <> prev_k THEN
        IF k >= 1 AND k <= 9 THEN GOSUB TriggerSfx
        IF k = 0 THEN GOSUB SilenceSfx
        IF k = 10 THEN GOSUB PrevPage
        IF k = 11 THEN GOSUB NextPage
    END IF
    prev_k = k
    GOTO MainLoop


' ============================================================
' PAGE NAVIGATION
' ============================================================

PrevPage: PROCEDURE
    IF page > 0 THEN page = page - 1 ELSE page = 2
    GOSUB SilenceSfx
    GOSUB DrawPage
    PRINT AT 0 COLOR 7, "SFX LAB  CLR/ENT=PG "
    RETURN
END

NextPage: PROCEDURE
    IF page < 2 THEN page = page + 1 ELSE page = 0
    GOSUB SilenceSfx
    GOSUB DrawPage
    PRINT AT 0 COLOR 7, "SFX LAB  CLR/ENT=PG "
    RETURN
END

SilenceSfx: PROCEDURE
    SOUND 0, 0, 0 : SOUND 1, 0, 0 : SOUND 2, 0, 0
    POKE $1F8, EN_SILENT
    sfx_type = 0 : sfx_timer = 0
    PRINT AT 220 COLOR 3, "  0=SILENCE         "
    RETURN
END


' ============================================================
' PAGE DISPLAY
' ============================================================

DrawPage: PROCEDURE
    IF page = 0 THEN GOSUB DrawLaserPage
    IF page = 1 THEN GOSUB DrawExplosionPage
    IF page = 2 THEN GOSUB DrawDeathPage
    RETURN
END

DrawLaserPage: PROCEDURE
    PRINT AT 20  COLOR 6, "<PAGE 1: LASERS    >"
    PRINT AT 40  COLOR 5, "1: CLASSIC ZAP      "
    PRINT AT 60  COLOR 5, "2: GALAGA DUAL      "
    PRINT AT 80  COLOR 5, "3: SI MISSILE       "
    PRINT AT 100 COLOR 5, "4: DEFENDER CRACK   "
    PRINT AT 120 COLOR 5, "5: PLASMA CANNON    "
    PRINT AT 140 COLOR 5, "6: TWIN LASER       "
    PRINT AT 160 COLOR 5, "7: TEMPEST ZAP      "
    PRINT AT 180 COLOR 5, "8: RICOCHET BOING   "
    PRINT AT 200 COLOR 5, "9: RAPID FIRE BURST "
    PRINT AT 220 COLOR 3, "  CLR/ENT=PAGE 1-9  "
    RETURN
END

DrawExplosionPage: PROCEDURE
    PRINT AT 20  COLOR 2, "<PAGE 2: EXPLOSIONS>"
    PRINT AT 40  COLOR 5, "1: TINY PUFF        "
    PRINT AT 60  COLOR 5, "2: ASTEROID SPLIT   "
    PRINT AT 80  COLOR 5, "3: GALAGA MID-SHIP  "
    PRINT AT 100 COLOR 5, "4: CAPITAL SHIP     "
    PRINT AT 120 COLOR 5, "5: SHOCKWAVE BOMB   "
    PRINT AT 140 COLOR 5, "6: METAL CRUNCH     "
    PRINT AT 160 COLOR 5, "7: CHAIN REACTION   "
    PRINT AT 180 COLOR 5, "8: NUCLEAR FLASH    "
    PRINT AT 200 COLOR 5, "9: BOSS MELTDOWN    "
    PRINT AT 220 COLOR 3, "  CLR/ENT=PAGE 1-9  "
    RETURN
END

DrawDeathPage: PROCEDURE
    PRINT AT 20  COLOR 3, "<PAGE 3: DEATHS    >"
    PRINT AT 40  COLOR 5, "1: QUICK SPLAT      "
    PRINT AT 60  COLOR 5, "2: ASTROSMASH BOOM  "
    PRINT AT 80  COLOR 5, "3: SAD DESCENT      "
    PRINT AT 100 COLOR 5, "4: ROBOTIC FAILURE  "
    PRINT AT 120 COLOR 5, "5: ELECTRIC FIZZLE  "
    PRINT AT 140 COLOR 5, "6: LONG WAIL        "
    PRINT AT 160 COLOR 5, "7: SIREN WINDDOWN   "
    PRINT AT 180 COLOR 5, "8: VAPORIZE         "
    PRINT AT 200 COLOR 5, "9: GRAND FINALE     "
    PRINT AT 220 COLOR 3, "  CLR/ENT=PAGE 1-9  "
    RETURN
END


' ============================================================
' SFX TRIGGER — compute sfx_type from page+key, init sound
' ============================================================

TriggerSfx: PROCEDURE
    SOUND 0, 0, 0 : SOUND 1, 0, 0 : SOUND 2, 0, 0
    POKE $1F8, EN_SILENT
    sfx_phase = 0
    IF page = 0 THEN
        sfx_type = k
        ON k - 1 GOSUB InitL1,InitL2,InitL3,InitL4,InitL5,InitL6,InitL7,InitL8,InitL9
    END IF
    IF page = 1 THEN
        sfx_type = k + 9
        ON k - 1 GOSUB InitE1,InitE2,InitE3,InitE4,InitE5,InitE6,InitE7,InitE8,InitE9
    END IF
    IF page = 2 THEN
        sfx_type = k + 18
        ON k - 1 GOSUB InitD1,InitD2,InitD3,InitD4,InitD5,InitD6,InitD7,InitD8,InitD9
    END IF
    GOSUB ShowPlayingName
    RETURN
END

ShowPlayingName: PROCEDURE
    IF sfx_type <= 9 THEN
        ON sfx_type - 1 GOSUB NameL1,NameL2,NameL3,NameL4,NameL5,NameL6,NameL7,NameL8,NameL9
        RETURN
    END IF
    IF sfx_type <= 18 THEN
        ON sfx_type - 10 GOSUB NameE1,NameE2,NameE3,NameE4,NameE5,NameE6,NameE7,NameE8,NameE9
        RETURN
    END IF
    ON sfx_type - 19 GOSUB NameD1,NameD2,NameD3,NameD4,NameD5,NameD6,NameD7,NameD8,NameD9
    RETURN
END


' ============================================================
' SFX UPDATE ENGINE — called every WAIT frame
' Decrements timer, silences on expiry, dispatches handler
' ============================================================

UpdateSfx: PROCEDURE
    IF sfx_type = 0 THEN RETURN
    sfx_timer = sfx_timer - 1
    IF sfx_timer = 0 THEN
        SOUND 0, 0, 0 : SOUND 1, 0, 0 : SOUND 2, 0, 0
        POKE $1F8, EN_SILENT
        sfx_type = 0
        RETURN
    END IF
    IF sfx_type <= 9 THEN
        ON sfx_type - 1 GOSUB UpdateL1,UpdateL2,UpdateL3,UpdateL4,UpdateL5,UpdateL6,UpdateL7,UpdateL8,UpdateL9
        RETURN
    END IF
    IF sfx_type <= 18 THEN
        ON sfx_type - 10 GOSUB UpdateE1,UpdateE2,UpdateE3,UpdateE4,UpdateE5,UpdateE6,UpdateE7,UpdateE8,UpdateE9
        RETURN
    END IF
    ON sfx_type - 19 GOSUB UpdateD1,UpdateD2,UpdateD3,UpdateD4,UpdateD5,UpdateD6,UpdateD7,UpdateD8,UpdateD9
    RETURN
END


' ============================================================
' PAGE 1: LASERS  (sfx_type 1-9)
' ============================================================

' L1: CLASSIC ZAP — Astrosmash-style high-to-mid descending laser
InitL1: PROCEDURE
    sfx_timer = 12 : sfx_vol = 14 : #sfx_freq = 80
    POKE $1F8, EN_TONE_C
    SOUND 2, 80, 14
    RETURN
END
UpdateL1: PROCEDURE
    #sfx_freq = #sfx_freq + 18
    IF #sfx_freq > 900 THEN #sfx_freq = 900
    IF sfx_vol > 1 THEN sfx_vol = sfx_vol - 1
    SOUND 2, #sfx_freq, sfx_vol
    RETURN
END
NameL1: PROCEDURE
    PRINT AT 220 COLOR 6, ">> CLASSIC ZAP      "
    RETURN
END

' L2: GALAGA DUAL — two detuned tones sliding together, fat beat
InitL2: PROCEDURE
    sfx_timer = 16 : sfx_vol = 13 : sfx_vol2 = 13
    #sfx_freq = 110 : #sfx_freq2 = 100
    POKE $1F8, EN_TA_TC
    SOUND 0, 100, 13
    SOUND 2, 110, 13
    RETURN
END
UpdateL2: PROCEDURE
    #sfx_freq = #sfx_freq + 22
    #sfx_freq2 = #sfx_freq2 + 18
    IF sfx_vol > 1 THEN sfx_vol = sfx_vol - 1
    IF sfx_vol2 > 1 THEN sfx_vol2 = sfx_vol2 - 1
    SOUND 0, #sfx_freq2, sfx_vol2
    SOUND 2, #sfx_freq, sfx_vol
    RETURN
END
NameL2: PROCEDURE
    PRINT AT 220 COLOR 6, ">> GALAGA DUAL      "
    RETURN
END

' L3: SI MISSILE — Space Invaders buzzy raspy shot (tone + noise)
InitL3: PROCEDURE
    sfx_timer = 14 : sfx_vol = 12 : #sfx_freq = 400
    POKE $1F9, 14
    POKE $1F8, EN_TC_NC
    SOUND 2, 400, 12
    RETURN
END
UpdateL3: PROCEDURE
    IF sfx_vol > 1 THEN sfx_vol = sfx_vol - 1
    SOUND 2, #sfx_freq, sfx_vol
    RETURN
END
NameL3: PROCEDURE
    PRINT AT 220 COLOR 6, ">> SI MISSILE       "
    RETURN
END

' L4: DEFENDER CRACK — 5-frame ultra-fast electric crack, max punch
InitL4: PROCEDURE
    sfx_timer = 5 : sfx_vol = 15 : #sfx_freq = 50
    POKE $1F9, 4
    POKE $1F8, EN_TC_NC
    SOUND 2, 50, 15
    RETURN
END
UpdateL4: PROCEDURE
    #sfx_freq = #sfx_freq + 80
    IF sfx_vol > 4 THEN sfx_vol = sfx_vol - 4 ELSE sfx_vol = 0
    SOUND 2, #sfx_freq, sfx_vol
    RETURN
END
NameL4: PROCEDURE
    PRINT AT 220 COLOR 6, ">> DEFENDER CRACK   "
    RETURN
END

' L5: PLASMA CANNON — 3-phase: deep thud -> mid whoosh -> rumble tail
' Phase 0 (vol2>=10): tone A 2200 + noise A (bass thrum + bright crack)
' Phase 1 (vol2 4-9): noise A period 20 only (mid whoosh arc)
' Phase 2 (vol2 1-3): tone A 3000 + noise C period 28 (deep rumble)
InitL5: PROCEDURE
    sfx_timer = 22 : sfx_vol2 = 14
    POKE $1F9, 4
    POKE $1F8, EN_TA_NA
    SOUND 0, 2200, 14
    RETURN
END
UpdateL5: PROCEDURE
    IF sfx_vol2 >= 10 THEN
        POKE $1F9, 4
        POKE $1F8, EN_TA_NA
        SOUND 0, 2200, sfx_vol2
    ELSEIF sfx_vol2 >= 4 THEN
        POKE $1F9, 20
        POKE $1F8, EN_NA
        SOUND 0, 4000, sfx_vol2
    ELSE
        POKE $1F9, 28
        POKE $1F8, EN_TA_NC
        SOUND 0, 3000, sfx_vol2
        SOUND 2, 350, sfx_vol2
    END IF
    IF (sfx_timer AND 1) = 0 THEN
        IF sfx_vol2 > 1 THEN sfx_vol2 = sfx_vol2 - 1 ELSE sfx_vol2 = 0
    END IF
    RETURN
END
NameL5: PROCEDURE
    PRINT AT 220 COLOR 6, ">> PLASMA CANNON    "
    RETURN
END

' L6: TWIN LASER — two closely-tuned beams, detuned for fat chorus
InitL6: PROCEDURE
    sfx_timer = 14 : sfx_vol = 13 : sfx_vol2 = 13
    #sfx_freq = 105 : #sfx_freq2 = 100
    POKE $1F8, EN_TA_TC
    SOUND 0, 100, 13
    SOUND 2, 105, 13
    RETURN
END
UpdateL6: PROCEDURE
    #sfx_freq = #sfx_freq + 12
    #sfx_freq2 = #sfx_freq2 + 10
    IF sfx_vol > 1 THEN sfx_vol = sfx_vol - 1
    IF sfx_vol2 > 1 THEN sfx_vol2 = sfx_vol2 - 1
    SOUND 0, #sfx_freq2, sfx_vol2
    SOUND 2, #sfx_freq, sfx_vol
    RETURN
END
NameL6: PROCEDURE
    PRINT AT 220 COLOR 6, ">> TWIN LASER       "
    RETURN
END

' L7: TEMPEST ZAP — noise crack burst then descending tone tail
' Phase 0 (timer>=8): pure noise C at max vol
' Phase 1 (timer<8):  tone C descending
InitL7: PROCEDURE
    sfx_timer = 10 : sfx_vol = 15 : #sfx_freq = 80
    sfx_phase = 0
    POKE $1F9, 4
    POKE $1F8, EN_NOISE_C
    RETURN
END
UpdateL7: PROCEDURE
    IF sfx_phase = 0 THEN
        IF sfx_timer <= 7 THEN
            sfx_phase = 1
            POKE $1F8, EN_TONE_C
        END IF
    ELSE
        #sfx_freq = #sfx_freq + 25
        IF sfx_vol > 2 THEN sfx_vol = sfx_vol - 2 ELSE sfx_vol = 0
        SOUND 2, #sfx_freq, sfx_vol
    END IF
    RETURN
END
NameL7: PROCEDURE
    PRINT AT 220 COLOR 6, ">> TEMPEST ZAP      "
    RETURN
END

' L8: RICOCHET BOING — pitch bounces back and forth like a ricocheting beam
' sfx_phase 0=descending (period rising), 1=ascending (period falling)
InitL8: PROCEDURE
    sfx_timer = 24 : sfx_vol = 13 : #sfx_freq = 80
    sfx_phase = 0
    POKE $1F8, EN_TONE_C
    SOUND 2, 80, 13
    RETURN
END
UpdateL8: PROCEDURE
    IF sfx_phase = 0 THEN
        #sfx_freq = #sfx_freq + 20
        IF #sfx_freq >= 480 THEN sfx_phase = 1
    ELSE
        IF #sfx_freq > 20 THEN #sfx_freq = #sfx_freq - 20
        IF #sfx_freq <= 100 THEN sfx_phase = 0
    END IF
    IF (sfx_timer AND 3) = 0 THEN
        IF sfx_vol > 1 THEN sfx_vol = sfx_vol - 1
    END IF
    SOUND 2, #sfx_freq, sfx_vol
    RETURN
END
NameL8: PROCEDURE
    PRINT AT 220 COLOR 6, ">> RICOCHET BOING   "
    RETURN
END

' L9: RAPID FIRE BURST — 3 machine-gun pulses, each slightly lower pitch
' sfx_phase cycles 0-5: frames 0-3=ON, frames 4-5=OFF (6-frame burst)
' sfx_vol3: burst count (0=high, 1=mid, 2=low pitched)
InitL9: PROCEDURE
    sfx_timer = 18 : sfx_phase = 0 : sfx_vol3 = 0
    #sfx_freq = 120
    POKE $1F8, EN_TONE_C
    SOUND 2, 120, 14
    RETURN
END
UpdateL9: PROCEDURE
    sfx_phase = sfx_phase + 1
    IF sfx_phase >= 6 THEN
        sfx_phase = 0
        IF sfx_vol3 < 2 THEN sfx_vol3 = sfx_vol3 + 1
    END IF
    IF sfx_phase < 4 THEN
        #sfx_freq = 120 + sfx_vol3 * 40
        POKE $1F8, EN_TONE_C
        SOUND 2, #sfx_freq, 14
    ELSE
        POKE $1F8, EN_SILENT
        SOUND 2, 0, 0
    END IF
    RETURN
END
NameL9: PROCEDURE
    PRINT AT 220 COLOR 6, ">> RAPID FIRE BURST "
    RETURN
END


SEGMENT 1

' ============================================================
' PAGE 2: EXPLOSIONS  (sfx_type 10-18)
' ============================================================

' E1: TINY PUFF — Space Invaders alien death, 100ms noise puff
InitE1: PROCEDURE
    sfx_timer = 7 : sfx_vol = 11
    POKE $1F9, 16
    POKE $1F8, EN_NOISE_C
    SOUND 2, 0, 11
    RETURN
END
UpdateE1: PROCEDURE
    IF sfx_vol > 2 THEN sfx_vol = sfx_vol - 2 ELSE sfx_vol = 0
    SOUND 2, 0, sfx_vol
    RETURN
END
NameE1: PROCEDURE
    PRINT AT 220 COLOR 2, ">> TINY PUFF        "
    RETURN
END

' E2: ASTEROID SPLIT — bass impact then mid noise tail
' Phase transition at timer=10: tone+noise -> noise only, deeper period
InitE2: PROCEDURE
    sfx_timer = 18 : sfx_vol = 14 : #sfx_freq = 800
    POKE $1F9, 12
    POKE $1F8, EN_TC_NC
    SOUND 2, 800, 14
    RETURN
END
UpdateE2: PROCEDURE
    IF sfx_vol > 1 THEN sfx_vol = sfx_vol - 1
    IF sfx_timer = 10 THEN
        POKE $1F9, 20
        POKE $1F8, EN_NOISE_C
    END IF
    SOUND 2, #sfx_freq, sfx_vol
    RETURN
END
NameE2: PROCEDURE
    PRINT AT 220 COLOR 2, ">> ASTEROID SPLIT   "
    RETURN
END

' E3: GALAGA MID-SHIP — satisfying medium explosion, slow noise decay
InitE3: PROCEDURE
    sfx_timer = 22 : sfx_vol = 15
    POKE $1F9, 8
    POKE $1F8, EN_NOISE_C
    SOUND 2, 0, 15
    RETURN
END
UpdateE3: PROCEDURE
    IF (sfx_timer AND 1) = 0 THEN
        IF sfx_vol > 1 THEN sfx_vol = sfx_vol - 1
    END IF
    IF sfx_timer = 12 THEN POKE $1F9, 20
    SOUND 2, 0, sfx_vol
    RETURN
END
NameE3: PROCEDURE
    PRINT AT 220 COLOR 2, ">> GALAGA MID-SHIP  "
    RETURN
END

' E4: CAPITAL SHIP DESTROY — massive 3-phase, all channels
' Phase 0 (timer>=22): 3-tone chord + noise C at full blast (8 frames)
' Phase 1 (timer 10-21): noise C storm, mid period, fading (12 frames)
' Phase 2 (timer 1-9): deep rumble tail, slow fade (9 frames)
InitE4: PROCEDURE
    sfx_timer = 30 : sfx_vol = 15 : sfx_vol2 = 15 : sfx_vol3 = 15
    POKE $1F9, 4
    POKE $1F8, EN_ABC_NC
    SOUND 0, 300, 15 : SOUND 1, 400, 15 : SOUND 2, 500, 15
    RETURN
END
UpdateE4: PROCEDURE
    IF sfx_timer >= 22 THEN
        IF sfx_vol > 1 THEN sfx_vol = sfx_vol - 1
        IF sfx_vol2 > 1 THEN sfx_vol2 = sfx_vol2 - 1
        IF sfx_vol3 > 1 THEN sfx_vol3 = sfx_vol3 - 1
        SOUND 0, 300, sfx_vol2 : SOUND 1, 400, sfx_vol3 : SOUND 2, 500, sfx_vol
    ELSEIF sfx_timer >= 10 THEN
        IF sfx_timer = 21 THEN
            SOUND 0, 0, 0 : SOUND 1, 0, 0
            POKE $1F8, EN_NOISE_C
            POKE $1F9, 16
            sfx_vol = 15
        END IF
        IF (sfx_timer AND 1) = 0 THEN
            IF sfx_vol > 1 THEN sfx_vol = sfx_vol - 1
        END IF
        SOUND 2, 0, sfx_vol
    ELSE
        IF sfx_timer = 9 THEN
            POKE $1F9, 28
            sfx_vol = 10
        END IF
        IF (sfx_timer AND 1) = 0 THEN
            IF sfx_vol > 1 THEN sfx_vol = sfx_vol - 1
        END IF
        SOUND 2, 0, sfx_vol
    END IF
    RETURN
END
NameE4: PROCEDURE
    PRINT AT 220 COLOR 2, ">> CAPITAL SHIP     "
    RETURN
END

' E5: SHOCKWAVE BOMB — instant crack, then bass + rumble, deep tail
' Uses volume level as phase gate (no separate phase counter needed)
InitE5: PROCEDURE
    sfx_timer = 16 : sfx_vol = 15
    POKE $1F9, 4
    POKE $1F8, EN_NOISE_C
    SOUND 2, 0, 15
    RETURN
END
UpdateE5: PROCEDURE
    IF sfx_vol >= 10 THEN
        POKE $1F9, 4
        POKE $1F8, EN_TC_NC
        SOUND 2, 3000, sfx_vol
    ELSEIF sfx_vol >= 4 THEN
        POKE $1F9, 20
        SOUND 2, 3000, sfx_vol
    ELSE
        POKE $1F9, 28
        POKE $1F8, EN_NOISE_C
        SOUND 2, 0, sfx_vol
    END IF
    IF sfx_vol > 1 THEN sfx_vol = sfx_vol - 1 ELSE sfx_vol = 0
    RETURN
END
NameE5: PROCEDURE
    PRINT AT 220 COLOR 2, ">> SHOCKWAVE BOMB   "
    RETURN
END

' E6: METAL CRUNCH — metallic "schwing": noise attack + long tonal ring
' Attack (vol>=12): noise period 8 + tone, vol -3/frame
' Ring (vol<12): tone only, slow drift, decay every other frame
InitE6: PROCEDURE
    sfx_timer = 28 : sfx_vol = 15 : #sfx_freq = 180
    POKE $1F9, 8
    POKE $1F8, EN_TC_NC
    SOUND 2, 180, 15
    RETURN
END
UpdateE6: PROCEDURE
    #sfx_freq = #sfx_freq + 2
    IF sfx_vol >= 12 THEN
        POKE $1F9, 8
        POKE $1F8, EN_TC_NC
        IF sfx_vol > 3 THEN sfx_vol = sfx_vol - 3 ELSE sfx_vol = 0
    ELSE
        POKE $1F8, EN_TONE_C
        IF (sfx_timer AND 1) = 0 THEN
            IF sfx_vol > 1 THEN sfx_vol = sfx_vol - 1
        END IF
    END IF
    SOUND 2, #sfx_freq, sfx_vol
    RETURN
END
NameE6: PROCEDURE
    PRINT AT 220 COLOR 2, ">> METAL CRUNCH     "
    RETURN
END

' E7: CHAIN REACTION — 5 sequential detonations, each noise period deepens
' sfx_phase 0-5: frames 0-3=burst ON, 4-5=gap
' sfx_vol3: burst number 0-4 -> noise period 12,16,20,24,28
InitE7: PROCEDURE
    sfx_timer = 30 : sfx_vol3 = 0 : sfx_phase = 0
    POKE $1F9, 12
    POKE $1F8, EN_NOISE_C
    SOUND 2, 0, 14
    RETURN
END
UpdateE7: PROCEDURE
    sfx_phase = sfx_phase + 1
    IF sfx_phase >= 6 THEN
        sfx_phase = 0
        IF sfx_vol3 < 4 THEN sfx_vol3 = sfx_vol3 + 1
    END IF
    IF sfx_phase < 4 THEN
        POKE $1F9, 12 + sfx_vol3 * 4
        POKE $1F8, EN_NOISE_C
        SOUND 2, 0, 14
    ELSE
        POKE $1F8, EN_SILENT
        SOUND 2, 0, 0
    END IF
    RETURN
END
NameE7: PROCEDURE
    PRINT AT 220 COLOR 2, ">> CHAIN REACTION   "
    RETURN
END

' E8: NUCLEAR FLASH — all 3 channels + noise at absolute maximum
' The loudest sound the PSG can produce; -2/frame on all channels
InitE8: PROCEDURE
    sfx_timer = 10 : sfx_vol = 15 : sfx_vol2 = 15 : sfx_vol3 = 15
    POKE $1F9, 4
    POKE $1F8, EN_ABC_NC
    SOUND 0, 200, 15 : SOUND 1, 300, 15 : SOUND 2, 400, 15
    RETURN
END
UpdateE8: PROCEDURE
    IF sfx_vol > 2 THEN sfx_vol = sfx_vol - 2 ELSE sfx_vol = 0
    IF sfx_vol2 > 2 THEN sfx_vol2 = sfx_vol2 - 2 ELSE sfx_vol2 = 0
    IF sfx_vol3 > 2 THEN sfx_vol3 = sfx_vol3 - 2 ELSE sfx_vol3 = 0
    SOUND 0, 200, sfx_vol2
    SOUND 1, 300, sfx_vol3
    SOUND 2, 400, sfx_vol
    RETURN
END
NameE8: PROCEDURE
    PRINT AT 220 COLOR 2, ">> NUCLEAR FLASH    "
    RETURN
END

' E9: BOSS REACTOR MELTDOWN — epic 4-phase, 40-frame sequence
' Phase 0 (timer>=35): rising alarm tone (period descends = pitch rises)
' Phase 1 (timer 25-34): noise chaos, period cycles 4/12/20/28 each 2fr
' Phase 2 (timer 10-24): deep bass channel A + noise C low rumble
' Phase 3 (timer 1-9):  3 aftershock noise pulses
InitE9: PROCEDURE
    sfx_timer = 40 : sfx_vol = 14 : sfx_phase = 0 : #sfx_freq = 300
    POKE $1F8, EN_TONE_C
    SOUND 2, 300, 14
    RETURN
END
UpdateE9: PROCEDURE
    IF sfx_timer >= 35 THEN
        IF #sfx_freq > 50 THEN #sfx_freq = #sfx_freq - 40
        SOUND 2, #sfx_freq, 14
    ELSEIF sfx_timer >= 25 THEN
        IF sfx_timer = 34 THEN POKE $1F8, EN_NOISE_C
        sfx_phase = sfx_phase + 1
        IF sfx_phase >= 4 THEN sfx_phase = 0
        POKE $1F9, 4 + sfx_phase * 8
        SOUND 2, 0, 15
    ELSEIF sfx_timer >= 10 THEN
        IF sfx_timer = 24 THEN
            SOUND 0, 2000, 13
            POKE $1F9, 24
            POKE $1F8, EN_TA_NC
            sfx_vol2 = 13
        END IF
        IF (sfx_timer AND 1) = 0 THEN
            IF sfx_vol2 > 1 THEN sfx_vol2 = sfx_vol2 - 1
        END IF
        SOUND 0, 2000, sfx_vol2
    ELSE
        IF sfx_timer = 9 THEN
            SOUND 0, 0, 0
            POKE $1F8, EN_SILENT
            sfx_phase = 0
        END IF
        sfx_phase = sfx_phase + 1
        IF sfx_phase >= 6 THEN sfx_phase = 0
        IF sfx_phase < 3 THEN
            POKE $1F9, 16
            POKE $1F8, EN_NOISE_C
            SOUND 2, 0, 10
        ELSE
            POKE $1F8, EN_SILENT
            SOUND 2, 0, 0
        END IF
    END IF
    RETURN
END
NameE9: PROCEDURE
    PRINT AT 220 COLOR 2, ">> BOSS MELTDOWN    "
    RETURN
END


' ============================================================
' PAGE 3: PLAYER DEATHS  (sfx_type 19-27)
' ============================================================

' D1: QUICK SPLAT — short noise+tone burst (the "oops" death)
InitD1: PROCEDURE
    sfx_timer = 10 : sfx_vol = 13 : #sfx_freq = 600
    POKE $1F9, 16
    POKE $1F8, EN_TC_NC
    SOUND 2, 600, 13
    RETURN
END
UpdateD1: PROCEDURE
    IF sfx_vol > 1 THEN sfx_vol = sfx_vol - 1
    #sfx_freq = #sfx_freq + 40
    SOUND 2, #sfx_freq, sfx_vol
    RETURN
END
NameD1: PROCEDURE
    PRINT AT 220 COLOR 3, ">> QUICK SPLAT      "
    RETURN
END

' D2: ASTROSMASH BOOM — pure white noise, period deepens as it fades
' Authentic Intellivision death sound — noise period 14->24 over 22 frames
InitD2: PROCEDURE
    sfx_timer = 22 : sfx_vol = 15
    POKE $1F9, 14
    POKE $1F8, EN_NOISE_C
    SOUND 2, 0, 15
    RETURN
END
UpdateD2: PROCEDURE
    POKE $1F9, 14 + (22 - sfx_timer) / 2
    IF (sfx_timer AND 1) = 0 THEN
        IF sfx_vol > 1 THEN sfx_vol = sfx_vol - 1
    END IF
    SOUND 2, 0, sfx_vol
    RETURN
END
NameD2: PROCEDURE
    PRINT AT 220 COLOR 3, ">> ASTROSMASH BOOM  "
    RETURN
END

' D3: SAD DESCENT — pitch plummets from high to bass over 25 frames
' Volume held high until final 5 frames then drops sharply
InitD3: PROCEDURE
    sfx_timer = 25 : sfx_vol = 14 : #sfx_freq = 80
    POKE $1F8, EN_TONE_C
    SOUND 2, 80, 14
    RETURN
END
UpdateD3: PROCEDURE
    #sfx_freq = #sfx_freq + 70
    IF #sfx_freq > 2000 THEN #sfx_freq = 2000
    IF sfx_timer <= 5 THEN
        IF sfx_vol > 3 THEN sfx_vol = sfx_vol - 3 ELSE sfx_vol = 0
    END IF
    SOUND 2, #sfx_freq, sfx_vol
    RETURN
END
NameD3: PROCEDURE
    PRINT AT 220 COLOR 3, ">> SAD DESCENT      "
    RETURN
END

' D4: ROBOTIC FAILURE — motor winding down, alternation rate slows
' sfx_phase: frame counter; threshold grows as timer decreases
InitD4: PROCEDURE
    sfx_timer = 24 : sfx_vol = 13 : #sfx_freq = 280 : sfx_phase = 0
    POKE $1F8, EN_TONE_C
    SOUND 2, 280, 13
    RETURN
END
UpdateD4: PROCEDURE
    sfx_phase = sfx_phase + 1
    misc = 2
    IF sfx_timer <= 18 THEN misc = 4
    IF sfx_timer < 7 THEN misc = 8
    IF sfx_phase >= misc THEN
        sfx_phase = 0
        IF #sfx_freq = 280 THEN #sfx_freq = 330 ELSE #sfx_freq = 280
    END IF
    IF sfx_vol > 1 THEN sfx_vol = sfx_vol - 1
    SOUND 2, #sfx_freq, sfx_vol
    RETURN
END
NameD4: PROCEDURE
    PRINT AT 220 COLOR 3, ">> ROBOTIC FAILURE  "
    RETURN
END

' D5: ELECTRIC FIZZLE — noise period cycles bright/mid/deep each frame
' Creates rapid crackling electrical texture with bass tone underneath
InitD5: PROCEDURE
    sfx_timer = 18 : sfx_vol = 14 : #sfx_freq = 150 : sfx_phase = 0
    POKE $1F9, 6
    POKE $1F8, EN_TC_NC
    SOUND 2, 150, 14
    RETURN
END
UpdateD5: PROCEDURE
    sfx_phase = sfx_phase + 1
    IF sfx_phase >= 3 THEN sfx_phase = 0
    IF sfx_phase = 0 THEN POKE $1F9, 6
    IF sfx_phase = 1 THEN POKE $1F9, 16
    IF sfx_phase = 2 THEN POKE $1F9, 26
    IF (sfx_timer AND 1) = 0 THEN
        IF sfx_vol > 1 THEN sfx_vol = sfx_vol - 1
    END IF
    SOUND 2, #sfx_freq, sfx_vol
    RETURN
END
NameD5: PROCEDURE
    PRINT AT 220 COLOR 3, ">> ELECTRIC FIZZLE  "
    RETURN
END

' D6: LONG WAIL — digital death cry, oscillates between two pitches
' sfx_phase 0-7=high cry (period 200), 8-15=low cry (period 360)
' ~4 complete cycles over 35 frames — mournful oscillation
InitD6: PROCEDURE
    sfx_timer = 35 : sfx_vol = 14 : sfx_phase = 0
    POKE $1F8, EN_TONE_C
    SOUND 2, 200, 14
    RETURN
END
UpdateD6: PROCEDURE
    sfx_phase = sfx_phase + 1
    IF sfx_phase >= 16 THEN sfx_phase = 0
    IF sfx_phase < 8 THEN
        SOUND 2, 200, sfx_vol
    ELSE
        SOUND 2, 360, sfx_vol
    END IF
    IF (sfx_timer AND 4) = 0 AND (sfx_timer AND 1) = 0 THEN
        IF sfx_vol > 1 THEN sfx_vol = sfx_vol - 1
    END IF
    RETURN
END
NameD6: PROCEDURE
    PRINT AT 220 COLOR 3, ">> LONG WAIL        "
    RETURN
END

' D7: SIREN WINDDOWN — police siren losing power, alternation slows
' Fast siren -> half-speed -> quarter-speed as timer decreases
InitD7: PROCEDURE
    sfx_timer = 20 : sfx_vol = 13 : #sfx_freq = 150 : sfx_phase = 0
    POKE $1F8, EN_TONE_C
    SOUND 2, 150, 13
    RETURN
END
UpdateD7: PROCEDURE
    sfx_phase = sfx_phase + 1
    misc = 2
    IF sfx_timer <= 14 THEN misc = 4
    IF sfx_timer < 7 THEN misc = 6
    IF sfx_phase >= misc THEN
        sfx_phase = 0
        IF #sfx_freq = 150 THEN #sfx_freq = 320 ELSE #sfx_freq = 150
    END IF
    IF (sfx_timer AND 3) = 0 THEN
        IF sfx_vol > 1 THEN sfx_vol = sfx_vol - 1
    END IF
    SOUND 2, #sfx_freq, sfx_vol
    RETURN
END
NameD7: PROCEDURE
    PRINT AT 220 COLOR 3, ">> SIREN WINDDOWN   "
    RETURN
END

' D8: VAPORIZE — energy weapon disintegration, 3-phase noise+tone arc
' Phase 0 (vol>=10): bright noise flash + high tone
' Phase 1 (vol 4-9): mid noise crackle + ascending pitch (period falls)
' Phase 2 (vol<4): deep noise residual only
InitD8: PROCEDURE
    sfx_timer = 18 : sfx_vol = 14 : #sfx_freq = 400
    POKE $1F9, 4
    POKE $1F8, EN_TC_NC
    SOUND 2, 400, 14
    RETURN
END
UpdateD8: PROCEDURE
    IF sfx_vol >= 10 THEN
        POKE $1F9, 4
        POKE $1F8, EN_TC_NC
        SOUND 2, #sfx_freq, sfx_vol
    ELSEIF sfx_vol >= 4 THEN
        POKE $1F9, 10
        IF #sfx_freq > 20 THEN #sfx_freq = #sfx_freq - 20
        SOUND 2, #sfx_freq, sfx_vol
    ELSE
        POKE $1F9, 18
        POKE $1F8, EN_NOISE_C
        SOUND 2, 0, sfx_vol
    END IF
    IF sfx_vol > 1 THEN sfx_vol = sfx_vol - 1 ELSE sfx_vol = 0
    RETURN
END
NameD8: PROCEDURE
    PRINT AT 220 COLOR 3, ">> VAPORIZE         "
    RETURN
END

' D9: GRAND FINALE — 5-phase, 50-frame epic death (the alpha and omega)
' Phase 0 (timer 44-50): all 3 tones + noise at max vol — total annihilation
' Phase 1 (timer 30-43): each channel descends at different rate
' Phase 2 (timer 15-29): deep noise C sustain, fading
' Phase 3 (timer 6-14):  3 aftershock pulses
' Phase 4 (timer 1-5):   single low echo tone fades out
InitD9: PROCEDURE
    sfx_timer = 50 : sfx_vol = 15 : sfx_vol2 = 15 : sfx_vol3 = 15
    sfx_phase = 0
    #sfx_freq = 200 : #sfx_freq2 = 250
    POKE $1F9, 4
    POKE $1F8, EN_ABC_NC
    SOUND 0, 200, 15 : SOUND 1, 300, 15 : SOUND 2, 400, 15
    RETURN
END
UpdateD9: PROCEDURE
    IF sfx_timer >= 44 THEN
        SOUND 0, 200, sfx_vol2
        SOUND 1, 300, sfx_vol3
        SOUND 2, 400, sfx_vol
    ELSEIF sfx_timer >= 30 THEN
        IF sfx_timer = 43 THEN
            POKE $1F8, EN_ABC_NC
            POKE $1F9, 12
        END IF
        #sfx_freq = #sfx_freq + 30
        #sfx_freq2 = #sfx_freq2 + 25
        IF sfx_vol > 1 THEN sfx_vol = sfx_vol - 1
        IF sfx_vol2 > 1 THEN sfx_vol2 = sfx_vol2 - 1
        IF sfx_vol3 > 1 THEN sfx_vol3 = sfx_vol3 - 1
        SOUND 0, #sfx_freq, sfx_vol2
        SOUND 1, 350, sfx_vol3
        SOUND 2, #sfx_freq2, sfx_vol
    ELSEIF sfx_timer >= 15 THEN
        IF sfx_timer = 29 THEN
            SOUND 0, 0, 0 : SOUND 1, 0, 0
            POKE $1F8, EN_NOISE_C
            POKE $1F9, 24
            sfx_vol = 14
        END IF
        IF (sfx_timer AND 1) = 0 THEN
            IF sfx_vol > 1 THEN sfx_vol = sfx_vol - 1
        END IF
        SOUND 2, 0, sfx_vol
    ELSEIF sfx_timer >= 6 THEN
        IF sfx_timer = 14 THEN sfx_phase = 0
        sfx_phase = sfx_phase + 1
        IF sfx_phase >= 6 THEN sfx_phase = 0
        IF sfx_phase < 3 THEN
            POKE $1F9, 16
            POKE $1F8, EN_NOISE_C
            SOUND 2, 0, 11
        ELSE
            POKE $1F8, EN_SILENT
            SOUND 2, 0, 0
        END IF
    ELSE
        IF sfx_timer = 5 THEN
            POKE $1F8, EN_TONE_C
            sfx_vol = 7
        END IF
        IF sfx_vol > 1 THEN sfx_vol = sfx_vol - 1
        SOUND 2, 3000, sfx_vol
    END IF
    RETURN
END
NameD9: PROCEDURE
    PRINT AT 220 COLOR 3, ">> GRAND FINALE     "
    RETURN
END
