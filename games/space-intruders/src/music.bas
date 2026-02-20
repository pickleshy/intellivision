' ============================================
' SPACE INTRUDERS - Music Module
' ============================================
' All game music tracks and voice data
' Segment: 3 (audio data)

    SEGMENT 3

' === Music Data ===

' ============================================
' Techno 8-bar loop: Em | Em | G | G | D | D | Em | Em
' 16th-note grid, tempo 6
space_intruders_theme:
  DATA 6

  ' ---- 1-bar intro "boot" (little climb) ----
  MUSIC E4X, E2Z, -, M1
  MUSIC G4X, S,   -, -
  MUSIC B4X, S,   -, -
  MUSIC E5X, S,   -, M3
  MUSIC D5X, S,   -, M2
  MUSIC B4X, S,   -, M3
  MUSIC G4X, S,   -, -
  MUSIC E4X, S,   -, M3
  MUSIC -,   S,   -, M1
  MUSIC -,   S,   -, -
  MUSIC -,   S,   -, M3
  MUSIC -,   S,   -, -
  MUSIC E4X, S,   -, M2
  MUSIC F4#X,S,   -, M3
  MUSIC G4X, S,   -, -
  MUSIC A4X, S,   -, M3

si_loop:
  ' ---- Bar 1 (Em) ----
  MUSIC E4X, E2Z, -, M1
  MUSIC B4X, S,   -, -
  MUSIC F4#X,S,   -, -
  MUSIC B4X, S,   -, M3
  MUSIC E5X, S,   -, M2
  MUSIC B4X, S,   -, M3
  MUSIC G4X, S,   -, -
  MUSIC B4X, S,   -, M3
  MUSIC D5X, S,   -, M1
  MUSIC B4X, S,   -, -
  MUSIC G4X, S,   -, M3
  MUSIC B4X, S,   -, -
  MUSIC E5X, S,   -, M2
  MUSIC B4X, S,   -, M3
  MUSIC F4#X,S,   -, -
  MUSIC B4X, S,   -, M3

  ' ---- Bar 2 (Em, variation) ----
  MUSIC E4X, E2Z, -, M1
  MUSIC B4X, S,   -, -
  MUSIC G4X, S,   -, -
  MUSIC B4X, S,   -, M3
  MUSIC E5X, S,   -, M2
  MUSIC B4X, S,   -, M3
  MUSIC F4#X,S,   -, -
  MUSIC B4X, S,   -, M3
  MUSIC D5X, S,   -, M1
  MUSIC B4X, S,   -, -
  MUSIC A4X, S,   -, M3
  MUSIC B4X, S,   -, -
  MUSIC E5X, S,   -, M2
  MUSIC B4X, S,   -, M3
  MUSIC G4X, S,   -, -
  MUSIC B4X, S,   -, M3

  ' ---- Bar 3 (G) ----
  MUSIC G4X, G2Z, -, M1
  MUSIC B4X, S,   -, -
  MUSIC D5X, S,   -, -
  MUSIC B4X, S,   -, M3
  MUSIC G5X, S,   -, M2
  MUSIC B4X, S,   -, M3
  MUSIC D5X, S,   -, -
  MUSIC B4X, S,   -, M3
  MUSIC A4X, S,   -, M1
  MUSIC B4X, S,   -, -
  MUSIC D5X, S,   -, M3
  MUSIC B4X, S,   -, -
  MUSIC G5X, S,   -, M2
  MUSIC B4X, S,   -, M3
  MUSIC D5X, S,   -, -
  MUSIC B4X, S,   -, M3

  ' ---- Bar 4 (G, variation) ----
  MUSIC G4X, G2Z, -, M1
  MUSIC B4X, S,   -, -
  MUSIC D5X, S,   -, -
  MUSIC B4X, S,   -, M3
  MUSIC F4#X,S,   -, M2
  MUSIC B4X, S,   -, M3
  MUSIC D5X, S,   -, -
  MUSIC B4X, S,   -, M3
  MUSIC E5X, S,   -, M1
  MUSIC B4X, S,   -, -
  MUSIC D5X, S,   -, M3
  MUSIC B4X, S,   -, -
  MUSIC G5X, S,   -, M2
  MUSIC B4X, S,   -, M3
  MUSIC D5X, S,   -, -
  MUSIC B4X, S,   -, M3

  ' ---- Bar 5 (D) ----
  MUSIC F4#X, D2Z, -, M1
  MUSIC A4X,  S,   -, -
  MUSIC D5X,  S,   -, -
  MUSIC A4X,  S,   -, M3
  MUSIC F4#5X,S,   -, M2
  MUSIC A4X,  S,   -, M3
  MUSIC D5X,  S,   -, -
  MUSIC A4X,  S,   -, M3
  MUSIC E5X,  S,   -, M1
  MUSIC A4X,  S,   -, -
  MUSIC D5X,  S,   -, M3
  MUSIC A4X,  S,   -, -
  MUSIC F4#5X,S,   -, M2
  MUSIC A4X,  S,   -, M3
  MUSIC D5X,  S,   -, -
  MUSIC A4X,  S,   -, M3

  ' ---- Bar 6 (D, variation) ----
  MUSIC F4#X, D2Z, -, M1
  MUSIC A4X,  S,   -, -
  MUSIC D5X,  S,   -, -
  MUSIC A4X,  S,   -, M3
  MUSIC C5X,  S,   -, M2
  MUSIC A4X,  S,   -, M3
  MUSIC D5X,  S,   -, -
  MUSIC A4X,  S,   -, M3
  MUSIC E5X,  S,   -, M1
  MUSIC A4X,  S,   -, -
  MUSIC D5X,  S,   -, M3
  MUSIC A4X,  S,   -, -
  MUSIC F4#5X,S,   -, M2
  MUSIC A4X,  S,   -, M3
  MUSIC D5X,  S,   -, -
  MUSIC A4X,  S,   -, M3

  ' ---- Bar 7 (Em, lift) ----
  MUSIC E4X, E2Z, -, M1
  MUSIC B4X, S,   -, -
  MUSIC F4#X,S,   -, -
  MUSIC B4X, S,   -, M3
  MUSIC E5X, S,   -, M2
  MUSIC B4X, S,   -, M3
  MUSIC G4X, S,   -, -
  MUSIC B4X, S,   -, M3
  MUSIC D5X, S,   -, M1
  MUSIC B4X, S,   -, -
  MUSIC G4X, S,   -, M3
  MUSIC B4X, S,   -, -
  MUSIC F4#5X,S,  -, M2
  MUSIC B4X,  S,  -, M3
  MUSIC E5X,  S,  -, -
  MUSIC B4X,  S,  -, M3

  ' ---- Bar 8 (Em, resolve) ----
  MUSIC E4X, E2Z, -, M1
  MUSIC B4X, S,   -, -
  MUSIC G4X, S,   -, -
  MUSIC B4X, S,   -, M3
  MUSIC E5X, S,   -, M2
  MUSIC B4X, S,   -, M3
  MUSIC F4#X,S,   -, -
  MUSIC B4X, S,   -, M3
  MUSIC D5X, S,   -, M1
  MUSIC B4X, S,   -, -
  MUSIC A4X, S,   -, M3
  MUSIC B4X, S,   -, -
  MUSIC G4X, S,   -, M2
  MUSIC F4#X,S,   -, M3
  MUSIC E4X, S,   -, -
  MUSIC -,   S,   -, M3

  MUSIC JUMP si_loop

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
' PLAY SIMPLE: Channel 3 free for SFX via SOUND 2
' ============================================================

    ' ============================================================
    ' SEGMENT 3 (continued) — MUSIC DATA
    ' ============================================================
    SEGMENT 3

' ------------------------------------------------------------
' Mid - "breakbeat emerging" — MAIN GAMEPLAY THEME (Gear 0, starting tempo)
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

  ' --- Bar 6: acid develops — D4 tension ---
  MUSIC E3X, E2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC D4X, -,   -, M3
  MUSIC -,   -,   -, M3
  MUSIC E3X, -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC G3X, -,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC E4X, E2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC D4X, -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC D4X, -,   -, M3
  MUSIC E3X, -,   -, M3

  ' --- Bar 7: acid peak — full 303 riff, insistent ---
  MUSIC E3X, E2,  -, M1
  MUSIC G3X, -,   -, M3
  MUSIC D4X, -,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC G3X, -,   -, M3
  MUSIC E4X, -,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC E3X, E2,  -, M1
  MUSIC D4X, -,   -, M3
  MUSIC G3X, -,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC E4X, -,   -, M2
  MUSIC E3X, -,   -, M3
  MUSIC D4X, -,   -, M3
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
  MUSIC D4X, -,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC G3X, -,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC E3X, -,   -, M3

  ' --- Bar 6: acid — D4 and E4 octave jump ---
  MUSIC E3X, E2,  -, M1
  MUSIC D4X, -,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC G3X, -,   -, M3
  MUSIC E4X, -,   -, M2
  MUSIC E3X, -,   -, M3
  MUSIC D4X, -,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC G3X, E2,  -, M1
  MUSIC E3X, -,   -, M3
  MUSIC D4X, -,   -, M3
  MUSIC E4X, -,   -, M3
  MUSIC E3X, -,   -, M2
  MUSIC D4X, -,   -, M3
  MUSIC G3X, -,   -, M3
  MUSIC E3X, -,   -, M3

  ' --- Bar 7: acid peak — relentless 303 ---
  MUSIC E3X, E2,  -, M1
  MUSIC G3X, -,   -, M3
  MUSIC D4X, -,   -, M3
  MUSIC E4X, -,   -, M3
  MUSIC E3X, -,   -, M2
  MUSIC G3X, -,   -, M3
  MUSIC D4X, -,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC E4X, E2,  -, M1
  MUSIC D4X, -,   -, M3
  MUSIC G3X, -,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC D4X, -,   -, M2
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
  MUSIC D4X, -,   -, M2
  MUSIC E3X, -,   -, M3
  MUSIC G3X, -,   -, M3
  MUSIC E4X, -,   -, M3
  MUSIC E3X, E2,  -, M1
  MUSIC D4X, -,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC G3X, -,   -, M3
  MUSIC E4X, -,   -, M2
  MUSIC E3X, -,   -, M3
  MUSIC D4X, -,   -, M3
  MUSIC G3X, -,   -, M3

  ' --- Bar 6: acid chaos — octave jumps, chromatic ---
  MUSIC E4X, E2,  -, M1
  MUSIC E3X, -,   -, M3
  MUSIC D4X, -,   -, M3
  MUSIC E4X, -,   -, M3
  MUSIC G3X, -,   -, M2
  MUSIC D4X, -,   -, M3
  MUSIC E3X, -,   -, M3
  MUSIC E4X, -,   -, M3
  MUSIC D4X, E2,  -, M1
  MUSIC E3X, -,   -, M3
  MUSIC G3X, -,   -, M3
  MUSIC E4X, -,   -, M3
  MUSIC E3X, -,   -, M2
  MUSIC D4X, -,   -, M3
  MUSIC E4X, -,   -, M3
  MUSIC E3X, -,   -, M3

  ' --- Bar 7: acid maximum — unrelenting 303 ---
  MUSIC E3X, E2,  -, M1
  MUSIC G3X, -,   -, M3
  MUSIC D4X, -,   -, M1
  MUSIC E4X, -,   -, M3
  MUSIC E3X, -,   -, M2
  MUSIC D4X, -,   -, M3
  MUSIC G3X, -,   -, M1
  MUSIC E4X, -,   -, M3
  MUSIC D4X, E2,  -, M2
  MUSIC E3X, -,   -, M3
  MUSIC E4X, -,   -, M1
  MUSIC G3X, -,   -, M3
  MUSIC D4X, -,   -, M2
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


' ============================================================
' GAME OVER MUSIC — DnB heartbeat tracks (4 gears)
' Heartbeat pulse + walking bass + synth stabs
' Distinct from gameplay music (si_bg_* = amen break + acid 303)
' ============================================================

' ------------------------------------------------------------
' Slow - "contemplative heartbeat"
' Tempo 11 (~55 BPM) - gentle pulse for early game over
' ------------------------------------------------------------
si_dnb_slow:
  DATA 11

si_dnb_slow_loop:

  ' --- Bar 1 (A): E3/C3 heartbeat ---
  MUSIC E3,  E2,  -, M1
  MUSIC S,   S,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC C3,  C2,  -, M1
  MUSIC S,   S,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -

  ' --- Bar 2 (A): same heartbeat, add a hat ---
  MUSIC E3,  E2,  -, M1
  MUSIC S,   S,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC C3,  C2,  -, M1
  MUSIC S,   S,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -

  ' --- Bar 3 (transition): melody emerges E3->G3->A3->G3 ---
  MUSIC E3,  E2,  -, M1
  MUSIC S,   S,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC G3,  G2,  -, M1
  MUSIC S,   S,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC A3,  A2,  -, M1
  MUSIC S,   S,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC G3,  G2,  -, M2
  MUSIC S,   S,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -

  ' --- Bar 4 (B): high stabs G4/D4 — gentle synth hook ---
  MUSIC G4,  G2,  -, M1
  MUSIC S,   S,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC D4,  A2,  -, M1
  MUSIC S,   S,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, -

  MUSIC JUMP si_dnb_slow_loop


' ------------------------------------------------------------
' Mid - "breakbeat emerging"
' Tempo 7 (~107 BPM) - half-time DnB feel
' ------------------------------------------------------------
si_dnb_mid:
  DATA 7

si_dnb_mid_loop:

  ' --- Bar 1 (A): heartbeat + bass phrase + breakbeat ---
  MUSIC E3,  E2,  -, M1
  MUSIC S,   S,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   G2,  -, -
  MUSIC -,   S,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   E2,  -, M1
  MUSIC -,   S,   -, M3
  MUSIC C3,  C2,  -, M1
  MUSIC S,   S,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   D2,  -, -
  MUSIC -,   S,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3

  ' --- Bar 2 (A): same groove ---
  MUSIC E3,  E2,  -, M1
  MUSIC S,   S,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   G2,  -, -
  MUSIC -,   S,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   E2,  -, M1
  MUSIC -,   S,   -, M3
  MUSIC C3,  C2,  -, M1
  MUSIC S,   S,   -, -
  MUSIC -,   -,   -, M3
  MUSIC -,   D2,  -, -
  MUSIC -,   S,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   -,   -, M3

  ' --- Bar 3 (transition): melody walks E3->G3->A3->B3, builds to hook ---
  MUSIC E3,  E2,  -, M1
  MUSIC S,   S,   -, -
  MUSIC -,   -,   -, M3
  MUSIC G3,  G2,  -, -
  MUSIC S,   S,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   E2,  -, M1
  MUSIC -,   S,   -, M3
  MUSIC A3,  A2,  -, M1
  MUSIC S,   S,   -, -
  MUSIC -,   -,   -, M3
  MUSIC B3,  B2,  -, -
  MUSIC S,   S,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   -,   -, M2
  MUSIC -,   -,   -, M3

  ' --- Bar 4 (B): high stabs G4/E4 over walking bass — synth hook ---
  MUSIC G4X, G2,  -, M1
  MUSIC -,   S,   -, -
  MUSIC E4X, -,   -, M3
  MUSIC -,   A2,  -, -
  MUSIC -,   S,   -, M2
  MUSIC G4X, -,   -, M3
  MUSIC -,   G2,  -, -
  MUSIC -,   S,   -, M3
  MUSIC D4X, B2,  -, M1
  MUSIC -,   S,   -, -
  MUSIC E4X, -,   -, M3
  MUSIC -,   A2,  -, -
  MUSIC -,   S,   -, M2
  MUSIC G4X, -,   -, M3
  MUSIC -,   E2,  -, M1
  MUSIC -,   -,   -, M3

  MUSIC JUMP si_dnb_mid_loop


' ------------------------------------------------------------
' Fast - "full DnB"
' Tempo 5 (~180 BPM) - classic DnB territory
' ------------------------------------------------------------
si_dnb_fast:
  DATA 5

si_dnb_fast_loop:

  ' --- Bar 1 (A): full amen groove ---
  MUSIC E3X, E2,  -, M1
  MUSIC -,   S,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   G2,  -, M3
  MUSIC -,   S,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   E2,  -, -
  MUSIC -,   -,   -, M3
  MUSIC C3X, C2,  -, -
  MUSIC -,   S,   -, M3
  MUSIC -,   -,   -, M1
  MUSIC -,   D2,  -, M3
  MUSIC -,   S,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   E2,  -, -
  MUSIC -,   -,   -, M2

  ' --- Bar 2 (A): same groove ---
  MUSIC E3X, E2,  -, M1
  MUSIC -,   S,   -, M3
  MUSIC -,   -,   -, -
  MUSIC -,   G2,  -, M3
  MUSIC -,   S,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   E2,  -, -
  MUSIC -,   -,   -, M3
  MUSIC C3X, C2,  -, -
  MUSIC -,   S,   -, M3
  MUSIC -,   -,   -, M1
  MUSIC -,   D2,  -, M3
  MUSIC -,   S,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC -,   E2,  -, -
  MUSIC -,   -,   -, M2

  ' --- Bar 3 (transition): rising riff E3->G3->A3->B3, drum fill out ---
  MUSIC E3X, E2,  -, M1
  MUSIC -,   S,   -, M3
  MUSIC G3X, -,   -, -
  MUSIC -,   G2,  -, M3
  MUSIC -,   S,   -, M2
  MUSIC -,   -,   -, M3
  MUSIC A3X, E2,  -, -
  MUSIC -,   S,   -, M3
  MUSIC -,   C2,  -, -
  MUSIC B3X, S,   -, M3
  MUSIC -,   -,   -, M1
  MUSIC A3X, D2,  -, M3
  MUSIC -,   S,   -, M2
  MUSIC B3X, -,   -, M2
  MUSIC -,   E2,  -, M1
  MUSIC -,   -,   -, M2

  ' --- Bar 4 (B): piercing stabs G4/E5 — synth riff over breakdown ---
  MUSIC G4X, G2,  -, -
  MUSIC -,   S,   -, -
  MUSIC E5X, A2,  -, M3
  MUSIC -,   S,   -, -
  MUSIC D4X, B2,  -, -
  MUSIC -,   S,   -, -
  MUSIC E5X, A2,  -, M3
  MUSIC -,   S,   -, -
  MUSIC G4X, G2,  -, M1
  MUSIC -,   S,   -, M3
  MUSIC E5X, -,   -, M2
  MUSIC -,   A2,  -, M3
  MUSIC D4X, S,   -, M1
  MUSIC -,   -,   -, M3
  MUSIC G4X, E2,  -, M2
  MUSIC -,   -,   -, M2

  MUSIC JUMP si_dnb_fast_loop


' ------------------------------------------------------------
' Panic - "final descent"
' Tempo 4 (~225 BPM) - frantic, relentless
' ------------------------------------------------------------
si_dnb_panic:
  DATA 4

si_dnb_panic_loop:

  ' --- Bar 1 (A): driving amen ---
  MUSIC E3X, E2,  -, M1
  MUSIC -,   S,   -, M3
  MUSIC -,   G2,  -, M3
  MUSIC -,   -,   -, M3
  MUSIC -,   E2,  -, M2
  MUSIC -,   S,   -, M3
  MUSIC -,   G2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC C3X, C2,  -, M1
  MUSIC -,   S,   -, M3
  MUSIC -,   D2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC -,   E2,  -, M2
  MUSIC -,   S,   -, M3
  MUSIC -,   G2,  -, M1
  MUSIC -,   -,   -, M2

  ' --- Bar 2 (A): same ---
  MUSIC E3X, E2,  -, M1
  MUSIC -,   S,   -, M3
  MUSIC -,   G2,  -, M3
  MUSIC -,   -,   -, M3
  MUSIC -,   E2,  -, M2
  MUSIC -,   S,   -, M3
  MUSIC -,   G2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC C3X, C2,  -, M1
  MUSIC -,   S,   -, M3
  MUSIC -,   D2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC -,   E2,  -, M2
  MUSIC -,   S,   -, M3
  MUSIC -,   G2,  -, M1
  MUSIC -,   -,   -, M2

  ' --- Bar 3 (transition): frantic rising E3->G3->A3->B3, snare roll ---
  MUSIC E3X, E2,  -, M1
  MUSIC -,   S,   -, M3
  MUSIC G3X, G2,  -, M3
  MUSIC -,   -,   -, M3
  MUSIC A3X, E2,  -, M2
  MUSIC -,   S,   -, M3
  MUSIC B3X, G2,  -, M1
  MUSIC -,   -,   -, M3
  MUSIC A3X, C2,  -, M1
  MUSIC B3X, S,   -, M3
  MUSIC A3X, D2,  -, M1
  MUSIC B3X, -,   -, M3
  MUSIC -,   E2,  -, M2
  MUSIC -,   -,   -, M2
  MUSIC -,   G2,  -, M2
  MUSIC -,   -,   -, M2

  ' --- Bar 4 (B): frantic arpeggios G4/E5/G5 — synth panic ---
  MUSIC G4X, G2,  -, M1
  MUSIC E5X, S,   -, M3
  MUSIC G5X, A2,  -, M3
  MUSIC E5X, -,   -, M3
  MUSIC D4X, B2,  -, M2
  MUSIC E5X, S,   -, M3
  MUSIC G5X, C3,  -, M1
  MUSIC E5X, S,   -, M3
  MUSIC G4X, B2,  -, M1
  MUSIC E5X, S,   -, M3
  MUSIC G5X, A2,  -, M1
  MUSIC E5X, -,   -, M3
  MUSIC D4X, G2,  -, M2
  MUSIC G4X, S,   -, M3
  MUSIC E5X, E2,  -, M1
  MUSIC G5X, -,   -, M2

  MUSIC JUMP si_dnb_panic_loop

' ============================================
' Y-AXIS ANIMATED TITLE FONT
' 4 rotation frames per letter (0°, 30°, 60°, 90°)
' Used during title screen cascade reveal/vanish
' ============================================

' Letter S - Frame 1 (0° full view)
FontSY1Gfx:
    BITMAP ".XXXXX.."
    BITMAP "XX...XX."
    BITMAP "XX......"
    BITMAP ".XXXXX.."
    BITMAP ".....XX."
    BITMAP ".....XX."
    BITMAP "XX...XX."
    BITMAP ".XXXXX.."

' Letter S - Frame 2 (30°)
FontSY2Gfx:
    BITMAP ".XXXXX.."
    BITMAP "XX...XX."
    BITMAP "XX......"
    BITMAP ".XXXXX.."
    BITMAP ".....XX."
    BITMAP ".....XX."
    BITMAP "XX...XX."
    BITMAP ".XXXXX.."

' Letter S - Frame 3 (60°)
FontSY3Gfx:
    BITMAP ".XXXXX.."
    BITMAP "XX...X.."
    BITMAP "XX......"
    BITMAP ".XXXXX.."
    BITMAP ".....X.."
    BITMAP ".....X.."
    BITMAP "XX...X.."
    BITMAP ".XXXXX.."

' Letter S - Frame 4 (90° edge view)
FontSY4Gfx:
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XXX..."

' Letter P - Frame 1 (0°)
FontPY1Gfx:
    BITMAP "XXXXXX.."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XXXXXX.."
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX......"

' Letter P - Frame 2 (30°)
FontPY2Gfx:
    BITMAP "XXXXXX.."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XXXXXX.."
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX......"

' Letter P - Frame 3 (60°)
FontPY3Gfx:
    BITMAP "XXXXXX.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XXXXXX.."
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX......"

' Letter P - Frame 4 (90°)
FontPY4Gfx:
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."

' Letter A - Frame 1 (0°)
FontAY1Gfx:
    BITMAP ".XXXXX.."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX..XXX."
    BITMAP "XXXXXXX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."

' Letter A - Frame 2 (30°)
FontAY2Gfx:
    BITMAP ".XXXXX.."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX..XXX."
    BITMAP "XXXXXXX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."

' Letter A - Frame 3 (60°)
FontAY3Gfx:
    BITMAP ".XXXXX.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX..XX.."
    BITMAP "XXXXXX.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."

' Letter A - Frame 4 (90°)
FontAY4Gfx:
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XXX..."
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."

' Letter C - Frame 1 (0°)
FontCY1Gfx:
    BITMAP ".XXXXX.."
    BITMAP "XX...XX."
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX...XX."
    BITMAP ".XXXXX.."

' Letter C - Frame 2 (30°)
FontCY2Gfx:
    BITMAP ".XXXXX.."
    BITMAP "XX...XX."
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX...XX."
    BITMAP ".XXXXX.."

' Letter C - Frame 3 (60°)
FontCY3Gfx:
    BITMAP ".XXXXX.."
    BITMAP "XX...X.."
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX...X.."
    BITMAP ".XXXXX.."

' Letter C - Frame 4 (90°)
FontCY4Gfx:
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XXX..."

' Letter E - Frame 1 (0°)
FontEY1Gfx:
    BITMAP "XXXXXXX."
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XXXXXXX."
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XXXXXXX."

' Letter E - Frame 2 (30°)
FontEY2Gfx:
    BITMAP "XXXXXXX."
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XXXXXXX."
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XXXXXXX."

' Letter E - Frame 3 (60°)
FontEY3Gfx:
    BITMAP "XXXXXX.."
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XXXXXX.."
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XX......"
    BITMAP "XXXXXX.."

' Letter E - Frame 4 (90°)
FontEY4Gfx:
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XXX..."

' Letter I - Frame 1 (0°)
FontIY1Gfx:
    BITMAP "XXXXXXX."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "XXXXXXX."

' Letter I - Frame 2 (30°)
FontIY2Gfx:
    BITMAP "XXXXXXX."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "XXXXXXX."

' Letter I - Frame 3 (60°)
FontIY3Gfx:
    BITMAP "XXXXXX.."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "XXXXXX.."

' Letter I - Frame 4 (90°)
FontIY4Gfx:
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XXX..."

' Letter N - Frame 1 (0°)
FontNY1Gfx:
    BITMAP "XX...XX."
    BITMAP "XXX..XX."
    BITMAP "XXXX.XX."
    BITMAP "XX.XXXX."
    BITMAP "XX..XXX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."

' Letter N - Frame 2 (30°)
FontNY2Gfx:
    BITMAP "XX...XX."
    BITMAP "XXX..XX."
    BITMAP "XXXX.XX."
    BITMAP "XX.XXXX."
    BITMAP "XX..XXX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."

' Letter N - Frame 3 (60°)
FontNY3Gfx:
    BITMAP "XX...X.."
    BITMAP "XXX..X.."
    BITMAP "XXXX.X.."
    BITMAP "XX.XXX.."
    BITMAP "XX..XX.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."

' Letter N - Frame 4 (90°)
FontNY4Gfx:
    BITMAP "..XX...."
    BITMAP "..XXX..."
    BITMAP "..XXX..."
    BITMAP "..XXX..."
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."

' Letter T - Frame 1 (0°)
FontTY1Gfx:
    BITMAP "XXXXXXX."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."

' Letter T - Frame 2 (30°)
FontTY2Gfx:
    BITMAP "XXXXXXX."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."

' Letter T - Frame 3 (60°)
FontTY3Gfx:
    BITMAP "XXXXXX.."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."

' Letter T - Frame 4 (90°)
FontTY4Gfx:
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."

' Letter R - Frame 1 (0°)
FontRY1Gfx:
    BITMAP "XXXXXX.."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XXXXXX.."
    BITMAP "XX..XX.."
    BITMAP "XX...XX."
    BITMAP "XX...XX."

' Letter R - Frame 2 (30°)
FontRY2Gfx:
    BITMAP "XXXXXX.."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XXXXXX.."
    BITMAP "XX..XX.."
    BITMAP "XX...XX."
    BITMAP "XX...XX."

' Letter R - Frame 3 (60°)
FontRY3Gfx:
    BITMAP "XXXXXX.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XXXXXX.."
    BITMAP "XX..XX.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."

' Letter R - Frame 4 (90°)
FontRY4Gfx:
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."

' Letter U - Frame 1 (0°)
FontUY1Gfx:
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP ".XXXXX.."

' Letter U - Frame 2 (30°)
FontUY2Gfx:
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP ".XXXXX.."

' Letter U - Frame 3 (60°)
FontUY3Gfx:
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP ".XXXXX.."

' Letter U - Frame 4 (90°)
FontUY4Gfx:
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XXX..."

' Letter D - Frame 1 (0°)
FontDY1Gfx:
    BITMAP "XXXXXX.."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XXXXXX.."

' Letter D - Frame 2 (30°)
FontDY2Gfx:
    BITMAP "XXXXXX.."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XX...XX."
    BITMAP "XXXXXX.."

' Letter D - Frame 3 (60°)
FontDY3Gfx:
    BITMAP "XXXXXX.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XX...X.."
    BITMAP "XXXXXX.."

' Letter D - Frame 4 (90°)
FontDY4Gfx:
    BITMAP "..XXX..."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XX...."
    BITMAP "..XXX..."
