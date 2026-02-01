' ============================================================
' Music Sample - "Intruder Drive" Player
' ============================================================
' A simple wrapper to play the Space Intruders theme music
' Uses PLAY FULL (3 channels + drums)
' ============================================================

    ' --- Setup screen ---
    CLS
    MODE 0, 0, 0, 0, 0
    WAIT

    ' --- Title text ---
    PRINT AT 43 COLOR 7, "INTRUDER DRIVE"
    PRINT AT 104 COLOR 5, "MUSIC SAMPLE"
    PRINT AT 162 COLOR 3, "PRESS ANY BUTTON"

    ' --- Wait for button press ---
wait_start:
    WAIT
    IF CONT.button = 0 THEN GOTO wait_start

    ' --- Start music ---
    PLAY FULL
    PLAY VOLUME 12
    PLAY space_intruders_theme

    CLS
    WAIT
    PRINT AT 43 COLOR 7, "INTRUDER DRIVE"
    PRINT AT 103 COLOR 5, "NOW PLAYING..."

    ' --- Main loop ---
main_loop:
    WAIT
    GOTO main_loop

' ============================================================
' Music Data - "Intruder Drive" (original)
' - Techno-ish 16th arp + bass pulse
' - Sharp syntax is like F4# (not F#4)
' - Instruments: X for lead, Z for bass
' - PLAY FULL format: ch1 (lead), ch2 (bass), ch3, drums
' ============================================================

' ------------------------------------------------------------
' 16th-note grid: tempo = 6 ticks ~ fast techno
' ------------------------------------------------------------
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
  ' ==========================================================
  ' 8-bar loop (each bar = 16 steps)
  ' Progression: Em | Em | G | G | D | D | Em | Em
  ' ==========================================================

  ' ---- Bar 1 (Em) + drums ----
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

  ' ---- Bar 2 (Em, variation) + drums ----
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

  ' ---- Bar 3 (G) + drums ----
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

  ' ---- Bar 4 (G, variation) + drums ----
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

  ' ---- Bar 5 (D) + drums ----
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

  ' ---- Bar 6 (D, variation) + drums ----
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

  ' ---- Bar 7 (Em, lift) + drums ----
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

  ' ---- Bar 8 (Em, resolve) + drums ----
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

  MUSIC JUMP si_loop  ' loop forever
