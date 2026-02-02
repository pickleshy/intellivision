' ============================================================
' Space Intruders - Background Gameplay Music
' 8-bar loop: Amen break (bars 1-4) → Acid section (bars 5-8)
'
' Build: ./build_background.sh [run]
' ============================================================
' Notes:
' - PLAY SIMPLE: ch1 = hook/303 riff, ch2 = bass, drums
' - Channel 3 free for SFX via SOUND 2
' - Bars 1-2: Amen drums + bass (no melody)
' - Bars 3-4: Hook enters (E3->G3->A3 rising, resolves)
' - Bars 5-7: Acid 303 riff (E3/G3/A#3, four-on-floor kicks)
' - Bar 8: Strip-back turnaround into amen loop
' ============================================================

' -----------------------------
' Title / UI
' -----------------------------
CLS
MODE 0,0,0,0,0
WAIT

PRINT AT 42  COLOR 7, "SPACE INTRUDERS"
PRINT AT 82  COLOR 5, "RHYTHM FOUNDATION"
PRINT AT 122 COLOR 3, "KEYPAD 1-4 = GEAR"
PRINT AT 162 COLOR 6, "BUTTONS = SFX TEST"

' SFX decay timer
sfx_timer = 0

' Start default
GOSUB StartMid

main_loop:
  WAIT

  ' Decay SFX on channel 3
  IF sfx_timer > 0 THEN
    sfx_timer = sfx_timer - 1
    IF sfx_timer = 0 THEN SOUND 2, 0, 0
  END IF

  ' Keypad 1-4 = select gear directly
  k = CONT.key
  IF k = 1 THEN GOSUB StartSlow
  IF k = 2 THEN GOSUB StartMid
  IF k = 3 THEN GOSUB StartFast
  IF k = 4 THEN GOSUB StartPanic

  ' Side buttons = SFX test (fires on channel 3 over the music)
  PRINT AT 220, 0
  PRINT AT 221, 0
  PRINT AT 222, 0
  PRINT AT 223, 0
  PRINT AT 224, 0

  IF CONT.button = 1 THEN GOSUB SfxShoot
  IF CONT.button = 2 THEN GOSUB SfxExplode
  IF CONT.button = 4 THEN GOSUB SfxPowerup

  GOTO main_loop

' --- SFX on channel 3 (SOUND 2) ---

SfxShoot: PROCEDURE
  SOUND 2, 200, 14
  sfx_timer = 4
  PRINT AT 220 COLOR 7, "SHOOT"
  RETURN
  END

SfxExplode: PROCEDURE
  SOUND 2, 800, 12
  SOUND 4, 8, 4
  sfx_timer = 10
  PRINT AT 220 COLOR 2, "BOOM!"
  RETURN
  END

SfxPowerup: PROCEDURE
  SOUND 2, 400, 13
  sfx_timer = 8
  PRINT AT 220 COLOR 6, "POWER"
  RETURN
  END

StartSlow: PROCEDURE
  gear = 1
  PLAY SIMPLE
  PLAY VOLUME 12
  PLAY si_bg_slow
  RETURN
  END

StartMid: PROCEDURE
  gear = 2
  PLAY SIMPLE
  PLAY VOLUME 12
  PLAY si_bg_mid
  RETURN
  END

StartFast: PROCEDURE
  gear = 3
  PLAY SIMPLE
  PLAY VOLUME 12
  PLAY si_bg_fast
  RETURN
  END

StartPanic: PROCEDURE
  gear = 4
  PLAY SIMPLE
  PLAY VOLUME 12
  PLAY si_bg_panic
  RETURN
  END


' ============================================================
' 8-BAR LOOP: AMEN BREAK → ACID 303
'
' Source: "Amen, Brother" by The Winstons (1969)
'         + TB-303 acid bass line style (Phuture, Hardfloor)
'
' Bars 1-2: Amen drums + sub-bass (groove foundation)
' Bar 3:    Hook enters — rising E3->G3->A3
' Bar 4:    Hook resolves — G3->E3
' Bars 5-7: Acid section — 303 riff on ch1, four-on-floor drums
' Bar 8:    Strip-back — riff drops, turnaround to amen
'
' Ch1 = hook (bars 3-4) / 303 acid riff (bars 5-7)
' Ch2 = sub-bass (E2 locked with kicks)
' Drums = amen (bars 1-4), four-on-floor + hats (bars 5-8)
' ============================================================

' ------------------------------------------------------------
' Slow - "invaders far away"
' Tempo 11 (~55 BPM) - sparse, deliberate
' ------------------------------------------------------------
si_bg_slow:
  DATA 11

si_bg_slow_loop:

  ' --- Bar 1: drums + bass only ---
  MUSIC -,   E2,  -, M1
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   E2,  -, M1
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -

  ' --- Bar 2: drums + bass, snare enters ---
  MUSIC -,   E2,  -, M1
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   E2,  -, M1
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -

  ' --- Bar 3: hook enters — E3...G3...A3 ---
  MUSIC E3,  E2,  -, M1
  MUSIC S,   -,   -, -
  MUSIC -,   -,   -, M1
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC G3,  G2,  -, M3
  MUSIC S,   -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M2
  MUSIC A3,  A2,  -, M1
  MUSIC S,   -,   -, M1
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2

  ' --- Bar 4: hook resolves — G3...E3, turnaround ---
  MUSIC G3,  G2,  -, M1
  MUSIC S,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC E3,  E2,  -, -
  MUSIC S,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M1

  ' --- Bar 5: acid intro — sparse E3 stabs, four-on-floor ---
  MUSIC E3X, E2,  -, M1
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC E3X, E2,  -, M1
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC G3X, -,   -, M3
  MUSIC -,   -,   -, -

  ' --- Bar 6: acid develops — D4enters ---
  MUSIC E3X, E2,  -, M1
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC D4X,-,   -, -
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC E3X, -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC G3X, E2,  -, M1
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC E3X, -,   -, M3
  MUSIC -,   -,   -, -

  ' --- Bar 7: acid peak — full 303 sequence ---
  MUSIC E3X, E2,  -, M1
  MUSIC -,   -,   -, -
  MUSIC G3X, -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC D4X,-,   -, M2
  MUSIC -,   -,   -, -
  MUSIC E3X, -,   -, M3
  MUSIC G3X, -,   -, -
  MUSIC E3X, E2,  -, M1
  MUSIC -,   -,   -, -
  MUSIC D4X,-,   -, M3
  MUSIC G3X, -,   -, -
  MUSIC E3X, -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -

  ' --- Bar 8: strip-back — riff drops, turnaround ---
  MUSIC E3,  E2,  -, M1
  MUSIC S,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   E2,  -, M1
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   E2,  -, M1

  MUSIC JUMP si_bg_slow_loop


' ------------------------------------------------------------
' Mid - "breakbeat emerging" — MAIN GAMEPLAY THEME
' Tempo 7 (~107 BPM) - classic amen groove
' ------------------------------------------------------------
si_bg_mid:
  DATA 7

si_bg_mid_loop:

  ' --- Bar 1: amen + bass (no melody) ---
  MUSIC -,   E2,  -, M1
  MUSIC -,   -,   -, -
  MUSIC -,   E2,  -, M1
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M2
  MUSIC -,   G2,  -, M1
  MUSIC -,   -,   -, M1
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2

  ' --- Bar 2: same (groove locks) ---
  MUSIC -,   E2,  -, M1
  MUSIC -,   -,   -, -
  MUSIC -,   E2,  -, M1
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M2
  MUSIC -,   G2,  -, M1
  MUSIC -,   -,   -, M1
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2

  ' --- Bar 3: hook enters — E3...G3...A3 rising ---
  MUSIC E3,  E2,  -, M1
  MUSIC S,   -,   -, -
  MUSIC -,   E2,  -, M1
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC G3,  G2,  -, M3
  MUSIC S,   -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC A3,  A2,  -, M1
  MUSIC S,   -,   -, -
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -

  ' --- Bar 4: hook resolves — G3...E3, turnaround ---
  MUSIC G3,  G2,  -, M1
  MUSIC S,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC E3,  E2,  -, M2
  MUSIC S,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M1
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M2
  MUSIC -,   E2,  -, M1

  ' --- Bar 5: acid intro — 303 enters, four-on-floor kicks ---
  MUSIC E3X, E2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC G3X, -,   -, M3
  MUSIC E3X, E2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC G3X, -,   -, M3
  MUSIC E3X, -,   -, M3

  ' --- Bar 6: acid develops — D4tension ---
  MUSIC E3X, E2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC D4X,-,   -, M3
  MUSIC -,   -,   -, M3
  MUSIC E3X, -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC G3X, -,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC E4X, E2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC D4X,-,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC D4X,-,   -, M3
  MUSIC E3X, -,   -, M3

  ' --- Bar 7: acid peak — full 303 riff, insistent ---
  MUSIC E3X, E2,  -, M1
  MUSIC G3X, -,   -, M3
  MUSIC D4X,-,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC G3X, -,   -, M3
  MUSIC E4X, -,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC E3X, E2,  -, M1
  MUSIC D4X,-,   -, M3
  MUSIC G3X, -,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC E4X, -,   -, M2
  MUSIC E3X, -,   -, M3
  MUSIC D4X,-,   -, M3
  MUSIC E3X, -,   -, M3

  ' --- Bar 8: strip-back — riff drops out, turnaround to amen ---
  MUSIC E3,  E2,  -, M1
  MUSIC S,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   E2,  -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M1
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   E2,  -, M1

  MUSIC JUMP si_bg_mid_loop


' ------------------------------------------------------------
' Fast - "full DnB"
' Tempo 5 (~180 BPM) - amen + hat ride
' Hook uses staccato X notes at this speed
' ------------------------------------------------------------
si_bg_fast:
  DATA 5

si_bg_fast_loop:

  ' --- Bar 1: amen + bass + hat ride (no melody) ---
  MUSIC -,   E2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC -,   E2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   G2,  -, M1
  MUSIC -,   -,   -, M1
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2

  ' --- Bar 2: same ---
  MUSIC -,   E2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC -,   E2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   G2,  -, M1
  MUSIC -,   -,   -, M1
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2

  ' --- Bar 3: hook — E3X...G3X...A3X staccato ---
  MUSIC E3X, E2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC -,   E2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC G3X, G2,  -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M3
  MUSIC A3X, A2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M3

  ' --- Bar 4: hook resolves — G3X...E3X, breakdown ---
  MUSIC G3X, G2,  -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC E3X, E2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M1
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M1
  MUSIC -,   -,   -, M2

  ' --- Bar 5: acid — 303 rapid fire, four-on-floor ---
  MUSIC E3X, E2,  -, M1
  MUSIC E3X, -,   -, M3
  MUSIC G3X, -,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC E3X, -,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC G3X, -,   -, M3
  MUSIC E3X, E2,  -, M1
  MUSIC E3X, -,   -, M3
  MUSIC D4X,-,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC G3X, -,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC E3X, -,   -, M3

  ' --- Bar 6: acid — D4and E4 octave jump ---
  MUSIC E3X, E2,  -, M1
  MUSIC D4X,-,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC G3X, -,   -, M3
  MUSIC E4X, -,   -, M2
  MUSIC E3X, -,   -, M3
  MUSIC D4X,-,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC G3X, E2,  -, M1
  MUSIC E3X, -,   -, M3
  MUSIC D4X,-,   -, M3
  MUSIC E4X, -,   -, M3
  MUSIC E3X, -,   -, M2
  MUSIC D4X,-,   -, M3
  MUSIC G3X, -,   -, M3
  MUSIC E3X, -,   -, M3

  ' --- Bar 7: acid peak — relentless 303 ---
  MUSIC E3X, E2,  -, M1
  MUSIC G3X, -,   -, M3
  MUSIC D4X,-,   -, M3
  MUSIC E4X, -,   -, M3
  MUSIC E3X, -,   -, M2
  MUSIC G3X, -,   -, M3
  MUSIC D4X,-,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC E4X, E2,  -, M1
  MUSIC D4X,-,   -, M3
  MUSIC G3X, -,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC D4X,-,   -, M2
  MUSIC E4X, -,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC G3X, -,   -, M3

  ' --- Bar 8: strip-back — riff dies, turnaround ---
  MUSIC E3X, E2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   E2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M1
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   E2,  -, M1

  MUSIC JUMP si_bg_fast_loop


' ------------------------------------------------------------
' Panic - "final descent"
' Tempo 4 (~225 BPM) - relentless
' Hook is urgent — higher register A3/B3
' ------------------------------------------------------------
si_bg_panic:
  DATA 4

si_bg_panic_loop:

  ' --- Bar 1: amen + bass, no melody ---
  MUSIC -,   E2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC -,   E2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   G2,  -, M1
  MUSIC -,   -,   -, M1
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2

  ' --- Bar 2: same ---
  MUSIC -,   E2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC -,   E2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   G2,  -, M1
  MUSIC -,   -,   -, M1
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2

  ' --- Bar 3: urgent hook — E3X...A3X...B3X ---
  MUSIC E3X, E2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC -,   E2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC A3X, A2,  -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M2
  MUSIC B3X, B2,  -, M2
  MUSIC -,   -,   -, M1
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M2

  ' --- Bar 4: hook crashes down — A3X...E3X, chaos ---
  MUSIC A3X, A2,  -, M1
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M1
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M1
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M1
  MUSIC -,   -,   -, M2
  MUSIC E3X, E2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M1
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M1
  MUSIC -,   -,   -, M2

  ' --- Bar 5: acid frenzy — every 16th is a note ---
  MUSIC E3X, E2,  -, M1
  MUSIC E3X, -,   -, M3
  MUSIC G3X, -,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC D4X,-,   -, M2
  MUSIC E3X, -,   -, M3
  MUSIC G3X, -,   -, M3
  MUSIC E4X, -,   -, M3
  MUSIC E3X, E2,  -, M1
  MUSIC D4X,-,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC G3X, -,   -, M3
  MUSIC E4X, -,   -, M2
  MUSIC E3X, -,   -, M3
  MUSIC D4X,-,   -, M3
  MUSIC G3X, -,   -, M3

  ' --- Bar 6: acid chaos — octave jumps, chromatic ---
  MUSIC E4X, E2,  -, M1
  MUSIC E3X, -,   -, M3
  MUSIC D4X,-,   -, M3
  MUSIC E4X, -,   -, M3
  MUSIC G3X, -,   -, M2
  MUSIC D4X,-,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC E4X, -,   -, M3
  MUSIC D4X,E2,  -, M1
  MUSIC E3X, -,   -, M3
  MUSIC G3X, -,   -, M3
  MUSIC E4X, -,   -, M3
  MUSIC E3X, -,   -, M2
  MUSIC D4X,-,   -, M3
  MUSIC E4X, -,   -, M3
  MUSIC E3X, -,   -, M3

  ' --- Bar 7: acid maximum — unrelenting 303 ---
  MUSIC E3X, E2,  -, M1
  MUSIC G3X, -,   -, M3
  MUSIC D4X,-,   -, M1
  MUSIC E4X, -,   -, M3
  MUSIC E3X, -,   -, M2
  MUSIC D4X,-,   -, M3
  MUSIC G3X, -,   -, M1
  MUSIC E4X, -,   -, M3
  MUSIC D4X,E2,  -, M2
  MUSIC E3X, -,   -, M3
  MUSIC E4X, -,   -, M1
  MUSIC G3X, -,   -, M3
  MUSIC D4X,-,   -, M2
  MUSIC E4X, -,   -, M3
  MUSIC E3X, -,   -, M1
  MUSIC G3X, -,   -, M3

  ' --- Bar 8: strip-back — acid dies, turnaround ---
  MUSIC E3X, E2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M1
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   E2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M1
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M1
  MUSIC -,   E2,  -, M2

  MUSIC JUMP si_bg_panic_loop
