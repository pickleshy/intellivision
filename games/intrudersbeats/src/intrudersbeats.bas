' ============================================================
' Space Intruders - DNB Heartbeat ROM
' Space-Invaders-inspired heartbeat + drum & bass breakbeat
'
' Build toolchain (typical):
'   intybasic intrudersbeats.bas intrudersbeats.asm
'   as1600  intrudersbeats.asm -o intrudersbeats.bin
'   jzintv  intrudersbeats.bin
' ============================================================
' Notes:
' - PLAY SIMPLE uses 2 tone channels + drum lane.
'   Channel 3 is FREE for gameplay SFX via SOUND 2.
' - Ch1: heartbeat (E3/C3), Ch2: sub-bass (E2/G2/C2/D2)
' - Drums: M1=kick, M2=snare, M3=hat
' ============================================================

' -----------------------------
' Title / UI
' -----------------------------
CLS
MODE 0,0,0,0,0
WAIT

PRINT AT 42  COLOR 7, "SPACE INTRUDERS"
PRINT AT 82  COLOR 5, "DNB HEARTBEAT TEST"
PRINT AT 122 COLOR 3, "KEYPAD 1-4 = GEAR"
PRINT AT 162 COLOR 6, "BUTTONS = SFX TEST"

' SFX decay timer
sfx_timer = 0

' Start default
GOSUB StartSlow

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
  ' Visual feedback on row 11
  PRINT AT 220, 0
  PRINT AT 221, 0
  PRINT AT 222, 0
  PRINT AT 223, 0
  PRINT AT 224, 0

  IF CONT.button = 1 THEN GOSUB SfxShoot
  IF CONT.button = 2 THEN GOSUB SfxExplode
  IF CONT.button = 4 THEN GOSUB SfxPowerup

  GOTO main_loop

' --- SFX on channel 3 (SOUND 2) — layered over PLAY SIMPLE music ---

SfxShoot: PROCEDURE
  ' High-pitched laser zap
  SOUND 2, 200, 14
  sfx_timer = 4
  PRINT AT 220 COLOR 7, "SHOOT"
  RETURN
  END

SfxExplode: PROCEDURE
  ' Low boom (noise channel mixed with tone)
  SOUND 2, 800, 12
  SOUND 4, 8, 4        ' Noise on channel 3
  sfx_timer = 10
  PRINT AT 220 COLOR 2, "BOOM!"
  RETURN
  END

SfxPowerup: PROCEDURE
  ' Rising tone
  SOUND 2, 400, 13
  sfx_timer = 8
  PRINT AT 220 COLOR 6, "POWER"
  RETURN
  END

StartSlow: PROCEDURE
  gear = 1
  PLAY SIMPLE
  PLAY VOLUME 12
  PLAY si_dnb_slow
  RETURN
  END

StartMid: PROCEDURE
  gear = 2
  PLAY SIMPLE
  PLAY VOLUME 12
  PLAY si_dnb_mid
  RETURN
  END

StartFast: PROCEDURE
  gear = 3
  PLAY SIMPLE
  PLAY VOLUME 12
  PLAY si_dnb_fast
  RETURN
  END

StartPanic: PROCEDURE
  gear = 4
  PLAY SIMPLE
  PLAY VOLUME 12
  PLAY si_dnb_panic
  RETURN
  END


' ============================================================
' MUSIC DATA
' PLAY SIMPLE format: ch1, ch2, drums  (ch3 free for SFX)
'
' Design:
'   Ch1 = heartbeat (E3 <-> C3, mid-range thump with sustain)
'   Ch2 = sub-bass (E2/G2/C2/D2 phrases, sustained notes)
'   Drums = breakbeat (amen-style kick/snare/hat)
'
' Tempo reference (NTSC 60fps, 16 steps/bar):
'   11 = ~55 BPM (ambient)     7 = ~107 BPM (building)
'    5 = ~180 BPM (proper DnB)  4 = ~225 BPM (frantic)
' ============================================================

' ------------------------------------------------------------
' Slow - "invaders far away"
' 4-bar form: 3 bars heartbeat (A) + 1 bar shift (B)
' Tempo 11 (~55 BPM) - slow, deliberate thump
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
' 4-bar form: 3 bars groove (A) + 1 bar hook (B)
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
' 4-bar form: 3 bars amen groove (A) + 1 bar breakdown/hook (B)
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
' 4-bar form: 3 bars relentless (A) + 1 bar ascending hook (B)
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
