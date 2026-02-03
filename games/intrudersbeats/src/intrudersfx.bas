' ============================================================
' Space Intruders - Sound Effects Test ROM
' All game SFX on channel 3 (SOUND 2) over PLAY SIMPLE music
'
' Build: ./build_sfx.sh [run]
' ============================================================
' Keypad 1-9 = trigger SFX
' Side buttons = toggle background music on/off
'
' SFX bank:
'   1 = Player shoot (laser zap)
'   2 = Alien explode (burst + noise)
'   3 = Player death (descending boom)
'   4 = Powerup collect (rising tone)
'   5 = Saucer flyby (warble)
'   6 = Wave clear (ascending fanfare)
'   7 = Alien bullet (low pop)
'   8 = Shield hit (clunk)
'   9 = Extra life (bright ping)
'   0 = Silence channel 3
' ============================================================

' SFX state
sfx_timer = 0
sfx_type = 0
#sfx_freq = 0
#sfx_vol = 0
music_on = 1

' -----------------------------
' Title / UI
' -----------------------------
CLS
MODE 0,0,0,0,0
WAIT

PRINT AT 2   COLOR 7, "SPACE INTRUDERS SFX"
PRINT AT 42  COLOR 5, "KEYPAD 1-9 = SFX"
PRINT AT 62  COLOR 3, "1=SHOOT 2=EXPLODE"
PRINT AT 82  COLOR 3, "3=DEATH 4=POWERUP"
PRINT AT 102 COLOR 3, "5=SAUCER 6=WAVECLR"
PRINT AT 122 COLOR 3, "7=ABULT 8=SHIELD"
PRINT AT 142 COLOR 3, "9=XLIFE 0=SILENCE"
PRINT AT 182 COLOR 6, "BUTTON=MUSIC ON/OFF"

' Start background music (mid gear)
PLAY SIMPLE
PLAY VOLUME 12
PLAY si_sfx_music

' Debounce
prev_k = 12
prev_b = 0

main_loop:
  WAIT

  ' --- SFX decay engine ---
  IF sfx_timer > 0 THEN
    sfx_timer = sfx_timer - 1

    ' Type-specific decay behavior
    IF sfx_type = 1 THEN
      ' Shoot: descending frequency
      #sfx_freq = #sfx_freq + 15
      IF #sfx_freq > 800 THEN #sfx_freq = 800
      IF #sfx_vol > 0 THEN #sfx_vol = #sfx_vol - 1
      SOUND 2, #sfx_freq, #sfx_vol
    END IF

    IF sfx_type = 2 THEN
      ' Explode: noise decays
      IF #sfx_vol > 0 THEN #sfx_vol = #sfx_vol - 1
      SOUND 2, #sfx_freq, #sfx_vol
    END IF

    IF sfx_type = 3 THEN
      ' Death: slow descending pitch + volume
      #sfx_freq = #sfx_freq + 25
      IF #sfx_freq > 1500 THEN #sfx_freq = 1500
      IF #sfx_vol > 0 THEN #sfx_vol = #sfx_vol - 1
      SOUND 2, #sfx_freq, #sfx_vol
    END IF

    IF sfx_type = 4 THEN
      ' Powerup: ascending frequency
      IF #sfx_freq > 100 THEN #sfx_freq = #sfx_freq - 20 ELSE #sfx_freq = 80
      IF #sfx_vol > 0 THEN #sfx_vol = #sfx_vol - 1
      SOUND 2, #sfx_freq, #sfx_vol
    END IF

    IF sfx_type = 5 THEN
      ' Saucer: warbling frequency
      IF (sfx_timer AND 1) THEN
        SOUND 2, #sfx_freq - 30, #sfx_vol
      ELSE
        SOUND 2, #sfx_freq + 30, #sfx_vol
      END IF
      IF sfx_timer < 10 THEN
        #sfx_vol = #sfx_vol - 1
        IF #sfx_vol < 0 THEN #sfx_vol = 0
      END IF
    END IF

    IF sfx_type = 6 THEN
      ' Wave clear: step through ascending tones
      IF sfx_timer = 18 THEN SOUND 2, 300, 14
      IF sfx_timer = 14 THEN SOUND 2, 250, 14
      IF sfx_timer = 10 THEN SOUND 2, 200, 14
      IF sfx_timer = 6  THEN SOUND 2, 150, 13
      IF sfx_timer = 2  THEN SOUND 2, 120, 12
    END IF

    IF sfx_type = 7 THEN
      ' Alien bullet: quick decay
      IF #sfx_vol >= 3 THEN #sfx_vol = #sfx_vol - 3 ELSE #sfx_vol = 0
      SOUND 2, #sfx_freq, #sfx_vol
    END IF

    IF sfx_type = 8 THEN
      ' Shield hit: frequency jump then decay
      IF #sfx_vol >= 2 THEN #sfx_vol = #sfx_vol - 2 ELSE #sfx_vol = 0
      #sfx_freq = #sfx_freq + 40
      SOUND 2, #sfx_freq, #sfx_vol
    END IF

    IF sfx_type = 9 THEN
      ' Extra life: bright ascending
      IF #sfx_freq > 75 THEN #sfx_freq = #sfx_freq - 15 ELSE #sfx_freq = 60
      IF (sfx_timer AND 2) THEN
        SOUND 2, #sfx_freq, #sfx_vol
      ELSE
        SOUND 2, #sfx_freq - 30, #sfx_vol
      END IF
      IF sfx_timer < 6 THEN
        #sfx_vol = #sfx_vol - 2
        IF #sfx_vol < 0 THEN #sfx_vol = 0
      END IF
    END IF

    ' Silence when done
    IF sfx_timer = 0 THEN
      SOUND 2, 0, 0
      sfx_type = 0
    END IF
  END IF

  ' --- Keypad input (debounced) ---
  k = CONT.key

  ' Clear status line
  PRINT AT 220 COLOR 7, "          "

  IF k <> prev_k THEN
    IF k = 1 THEN GOSUB SfxShoot
    IF k = 2 THEN GOSUB SfxExplode
    IF k = 3 THEN GOSUB SfxDeath
    IF k = 4 THEN GOSUB SfxPowerup
    IF k = 5 THEN GOSUB SfxSaucer
    IF k = 6 THEN GOSUB SfxWaveClear
    IF k = 7 THEN GOSUB SfxAlienBullet
    IF k = 8 THEN GOSUB SfxShieldHit
    IF k = 9 THEN GOSUB SfxExtraLife
    IF k = 0 THEN
      SOUND 2, 0, 0
      sfx_timer = 0
      sfx_type = 0
      PRINT AT 220 COLOR 3, " SILENCE  "
    END IF
  END IF
  prev_k = k

  ' --- Side button = toggle music ---
  b = CONT.button
  IF b > 0 AND prev_b = 0 THEN
    IF music_on THEN
      PLAY OFF
      music_on = 0
      PRINT AT 202 COLOR 2, "  MUSIC OFF  "
    ELSE
      PLAY SIMPLE
      PLAY VOLUME 12
      PLAY si_sfx_music
      music_on = 1
      PRINT AT 202 COLOR 5, "  MUSIC ON   "
    END IF
  END IF
  prev_b = b

  GOTO main_loop


' ============================================================
' SFX PROCEDURES — all fire on channel 3 (SOUND 2)
' ============================================================

SfxShoot: PROCEDURE
  ' High-pitched descending laser zap
  sfx_type = 1
  #sfx_freq = 150
  #sfx_vol = 14
  sfx_timer = 8
  SOUND 2, 150, 14
  PRINT AT 220 COLOR 7, " SHOOT!   "
  RETURN
  END

SfxExplode: PROCEDURE
  ' Mid-frequency burst with noise texture
  sfx_type = 2
  #sfx_freq = 500
  #sfx_vol = 15
  sfx_timer = 14
  SOUND 2, 500, 15
  PRINT AT 220 COLOR 2, " EXPLODE! "
  RETURN
  END

SfxDeath: PROCEDURE
  ' Low descending boom — player destroyed
  sfx_type = 3
  #sfx_freq = 300
  #sfx_vol = 15
  sfx_timer = 25
  SOUND 2, 300, 15
  PRINT AT 220 COLOR 2, " DEATH!   "
  RETURN
  END

SfxPowerup: PROCEDURE
  ' Rising tone — collected powerup
  sfx_type = 4
  #sfx_freq = 500
  #sfx_vol = 14
  sfx_timer = 12
  SOUND 2, 500, 14
  PRINT AT 220 COLOR 6, " POWERUP! "
  RETURN
  END

SfxSaucer: PROCEDURE
  ' Warbling mid-tone — saucer flyby
  sfx_type = 5
  #sfx_freq = 350
  #sfx_vol = 12
  sfx_timer = 40
  SOUND 2, 350, 12
  PRINT AT 220 COLOR 5, " SAUCER~  "
  RETURN
  END

SfxWaveClear: PROCEDURE
  ' Ascending fanfare — wave completed
  sfx_type = 6
  #sfx_freq = 350
  #sfx_vol = 14
  sfx_timer = 20
  SOUND 2, 350, 14
  PRINT AT 220 COLOR 6, " WAVE CLR!"
  RETURN
  END

SfxAlienBullet: PROCEDURE
  ' Quick low pop — alien fires
  sfx_type = 7
  #sfx_freq = 600
  #sfx_vol = 12
  sfx_timer = 4
  SOUND 2, 600, 12
  PRINT AT 220 COLOR 1, " A-BULLET "
  RETURN
  END

SfxShieldHit: PROCEDURE
  ' Short clunk — shield absorbs hit
  sfx_type = 8
  #sfx_freq = 400
  #sfx_vol = 13
  sfx_timer = 6
  SOUND 2, 400, 13
  PRINT AT 220 COLOR 3, " SHIELD!  "
  RETURN
  END

SfxExtraLife: PROCEDURE
  ' Bright ascending ping — extra life awarded
  sfx_type = 9
  #sfx_freq = 250
  #sfx_vol = 14
  sfx_timer = 16
  SOUND 2, 250, 14
  PRINT AT 220 COLOR 6, " +1 LIFE! "
  RETURN
  END


' ============================================================
' BACKGROUND MUSIC — Mid gear loop for SFX testing context
' Stripped-down 4-bar amen groove so SFX are audible
' ============================================================
si_sfx_music:
  DATA 7

si_sfx_music_loop:

  ' --- Bar 1: amen + bass ---
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

  ' --- Bar 2: same ---
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

  ' --- Bar 3: hook enters ---
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

  ' --- Bar 4: hook resolves ---
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

  MUSIC JUMP si_sfx_music_loop
