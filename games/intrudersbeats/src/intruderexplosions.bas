' ============================================================
' Space Intruders - EXPLOSIONS Sound Test ROM
' Comprehensive explosion SFX library for AY-3-8914 PSG
'
' Build: ./build_explosions.sh [run]
' ============================================================
' PAGE 1 (Keypad 1-9): Tone-based explosions (music-safe)
'   Works with PLAY SIMPLE — channel 3 (SOUND 2) only
'   1 = Fast Pop (small alien death)
'   2 = Descending Crash (saucer/machine)
'   3 = Low Boom (heavy impact)
'   4 = Metallic Ring (robot/metal)
'   5 = Double-Tap (ricochet)
'   6 = Rising Burst (energy weapon)
'   7 = Sub Rumble (earthquake)
'   8 = Bright Zap (electric)
'   9 = Warble Crunch (alien ship)
'
' PAGE 2 (press 0 to switch, then 1-9): Noise explosions
'   PLAY OFF — full PSG access including noise register
'   1 = White Noise Burst (pure hiss)
'   2 = Deep Rumble (low noise)
'   3 = Crackling Fire (bright noise + tone)
'   4 = Player Death Boom (long white noise)
'   5 = Chain Reaction (noise + tone layers)
'   6 = Envelope Decay (hardware envelope)
'   7 = Full Channel Blast (3-channel + noise)
'   8 = Muffled Boom (distant explosion)
'   9 = Static Burst (electric discharge)
'
' Press 0 to toggle between pages
' Side button = toggle background music (page 1 only)
' ============================================================

' --- 16-bit SFX state ---
#sfx_freq = 0
#sfx_vol = 0
#sfx_freq2 = 0
#sfx_vol2 = 0
#sfx_phase = 0

' --- 8-bit state ---
sfx_timer = 0
sfx_type = 0
page = 1
music_on = 1
prev_k = 12
prev_b = 0

' -----------------------------
' Title / UI
' -----------------------------
CLS
MODE 0,0,0,0,0
WAIT

GOSUB DrawPage1

' Start background music
PLAY SIMPLE
PLAY VOLUME 12
PLAY si_exp_music

main_loop:
  WAIT

  ' --- SFX decay engine ---
  IF sfx_timer > 0 THEN
    sfx_timer = sfx_timer - 1
    GOSUB UpdateSfx
    IF sfx_timer = 0 THEN GOSUB SilenceAll
  END IF

  ' --- Keypad input (debounced) ---
  k = CONT.key
  IF k <> prev_k THEN
    IF k = 0 THEN
      ' Toggle page
      IF page = 1 THEN
        page = 2
        PLAY OFF
        music_on = 0
        GOSUB SilenceAll
        GOSUB DrawPage2
      ELSE
        page = 1
        PLAY SIMPLE
        PLAY VOLUME 12
        PLAY si_exp_music
        music_on = 1
        GOSUB DrawPage1
      END IF
    END IF

    IF page = 1 THEN
      IF k >= 1 AND k <= 9 THEN GOSUB TriggerPage1
    END IF
    IF page = 2 THEN
      IF k >= 1 AND k <= 9 THEN GOSUB TriggerPage2
    END IF
  END IF
  prev_k = k

  ' --- Side button = toggle music (page 1 only) ---
  b = CONT.button
  IF b > 0 AND prev_b = 0 THEN
    IF page = 1 THEN
      IF music_on THEN
        PLAY OFF
        music_on = 0
      ELSE
        PLAY SIMPLE
        PLAY VOLUME 12
        PLAY si_exp_music
        music_on = 1
      END IF
    END IF
  END IF
  prev_b = b

  GOTO main_loop


' ============================================================
' PAGE DRAWING
' ============================================================

DrawPage1: PROCEDURE
  CLS
  WAIT
  PRINT AT 2   COLOR 7, "EXPLOSIONS - PAGE 1"
  PRINT AT 22  COLOR 5, " TONE (MUSIC-SAFE) "
  PRINT AT 42  COLOR 3, "1=POP    2=CRASH"
  PRINT AT 62  COLOR 3, "3=BOOM   4=METAL"
  PRINT AT 82  COLOR 3, "5=DBTAP  6=ENERGY"
  PRINT AT 102 COLOR 3, "7=RUMBLE 8=ZAP"
  PRINT AT 122 COLOR 3, "9=WCRUNCH"
  PRINT AT 162 COLOR 6, "0=SWITCH TO PAGE 2"
  PRINT AT 182 COLOR 6, "BUTTON=MUSIC ON/OFF"
  RETURN
  END

DrawPage2: PROCEDURE
  CLS
  WAIT
  PRINT AT 2   COLOR 2, "EXPLOSIONS - PAGE 2"
  PRINT AT 22  COLOR 5, " NOISE (MUSIC OFF) "
  PRINT AT 42  COLOR 3, "1=WHITE  2=DEEP"
  PRINT AT 62  COLOR 3, "3=FIRE   4=DEATH"
  PRINT AT 82  COLOR 3, "5=CHAIN  6=ENVLP"
  PRINT AT 102 COLOR 3, "7=FULL   8=MUFFLE"
  PRINT AT 122 COLOR 3, "9=STATIC"
  PRINT AT 162 COLOR 6, "0=SWITCH TO PAGE 1"
  RETURN
  END


' ============================================================
' PAGE 1: TONE-BASED EXPLOSIONS (channel 3 / SOUND 2 only)
' Compatible with PLAY SIMPLE music
' ============================================================

TriggerPage1: PROCEDURE
  ' Clear status
  PRINT AT 220 COLOR 7, "          "

  IF k = 1 THEN
    ' --- FAST POP: quick descending tone ---
    sfx_type = 11
    #sfx_freq = 120
    #sfx_vol = 15
    sfx_timer = 7
    SOUND 2, 120, 15
    PRINT AT 220 COLOR 7, "FAST POP  "
  END IF

  IF k = 2 THEN
    ' --- DESCENDING CRASH: slow pitch drop ---
    sfx_type = 12
    #sfx_freq = 100
    #sfx_vol = 15
    sfx_timer = 20
    SOUND 2, 100, 15
    PRINT AT 220 COLOR 2, "CRASH!    "
  END IF

  IF k = 3 THEN
    ' --- LOW BOOM: deep tone burst ---
    sfx_type = 13
    #sfx_freq = 600
    #sfx_vol = 15
    sfx_timer = 18
    SOUND 2, 600, 15
    PRINT AT 220 COLOR 2, "BOOM!     "
  END IF

  IF k = 4 THEN
    ' --- METALLIC RING: high tone with fast modulation ---
    sfx_type = 14
    #sfx_freq = 80
    #sfx_vol = 14
    #sfx_phase = 0
    sfx_timer = 16
    SOUND 2, 80, 14
    PRINT AT 220 COLOR 3, "METAL!    "
  END IF

  IF k = 5 THEN
    ' --- DOUBLE-TAP: two quick bursts ---
    sfx_type = 15
    #sfx_freq = 150
    #sfx_vol = 15
    #sfx_phase = 0
    sfx_timer = 16
    SOUND 2, 150, 15
    PRINT AT 220 COLOR 6, "DBL-TAP!  "
  END IF

  IF k = 6 THEN
    ' --- RISING BURST: ascending then cut ---
    sfx_type = 16
    #sfx_freq = 500
    #sfx_vol = 14
    sfx_timer = 12
    SOUND 2, 500, 14
    PRINT AT 220 COLOR 5, "ENERGY!   "
  END IF

  IF k = 7 THEN
    ' --- SUB RUMBLE: very low sustained tone ---
    sfx_type = 17
    #sfx_freq = 900
    #sfx_vol = 15
    sfx_timer = 30
    SOUND 2, 900, 15
    PRINT AT 220 COLOR 1, "RUMBLE... "
  END IF

  IF k = 8 THEN
    ' --- BRIGHT ZAP: high pitch snap ---
    sfx_type = 18
    #sfx_freq = 60
    #sfx_vol = 15
    sfx_timer = 5
    SOUND 2, 60, 15
    PRINT AT 220 COLOR 6, "ZAP!      "
  END IF

  IF k = 9 THEN
    ' --- WARBLE CRUNCH: alternating pitch decay ---
    sfx_type = 19
    #sfx_freq = 200
    #sfx_vol = 15
    #sfx_phase = 0
    sfx_timer = 22
    SOUND 2, 200, 15
    PRINT AT 220 COLOR 2, "CRUNCH!   "
  END IF

  RETURN
  END


' ============================================================
' PAGE 2: NOISE-BASED EXPLOSIONS (full PSG access)
' PLAY must be OFF for these
' ============================================================

TriggerPage2: PROCEDURE
  GOSUB SilenceAll
  PRINT AT 220 COLOR 7, "          "

  IF k = 1 THEN
    ' --- WHITE NOISE BURST: pure hiss ---
    sfx_type = 21
    #sfx_vol = 15
    sfx_timer = 12
    POKE $1F7, 10
    POKE $1F8, $1F
    SOUND 2, 0, 15
    PRINT AT 220 COLOR 7, "WHITE!    "
  END IF

  IF k = 2 THEN
    ' --- DEEP RUMBLE: low noise period ---
    sfx_type = 22
    #sfx_vol = 15
    sfx_timer = 25
    POKE $1F7, 28
    POKE $1F8, $1F
    SOUND 2, 0, 15
    PRINT AT 220 COLOR 1, "DEEP...   "
  END IF

  IF k = 3 THEN
    ' --- CRACKLING FIRE: bright noise + low tone ---
    sfx_type = 23
    #sfx_vol = 15
    #sfx_freq = 300
    sfx_timer = 20
    POKE $1F7, 6
    POKE $1F8, $19
    SOUND 2, 300, 15
    PRINT AT 220 COLOR 2, "FIRE!     "
  END IF

  IF k = 4 THEN
    ' --- PLAYER DEATH: long white noise boom ---
    sfx_type = 24
    #sfx_vol = 15
    sfx_timer = 60
    POKE $1F7, 14
    POKE $1F8, $1F
    SOUND 2, 0, 15
    PRINT AT 220 COLOR 2, "DEATH!!   "
  END IF

  IF k = 5 THEN
    ' --- CHAIN REACTION: noise + dual tone ---
    sfx_type = 25
    #sfx_vol = 15
    #sfx_freq = 150
    #sfx_freq2 = 80
    sfx_timer = 24
    POKE $1F7, 12
    POKE $1F8, $18
    SOUND 0, 150, 14
    SOUND 2, 80, 15
    PRINT AT 220 COLOR 6, "CHAIN!!   "
  END IF

  IF k = 6 THEN
    ' --- ENVELOPE DECAY: hardware auto-decay ---
    sfx_type = 26
    sfx_timer = 40
    SOUND 5, 80, 0
    SOUND 2, 200, 31
    POKE $1F7, 10
    POKE $1F8, $1B
    PRINT AT 220 COLOR 5, "ENVELOPE! "
  END IF

  IF k = 7 THEN
    ' --- FULL CHANNEL BLAST: all 3 channels + noise ---
    sfx_type = 27
    #sfx_vol = 15
    sfx_timer = 22
    POKE $1F7, 8
    POKE $1F8, $00
    SOUND 0, 80, 15
    SOUND 1, 150, 14
    SOUND 2, 50, 15
    PRINT AT 220 COLOR 2, "FULL!!    "
  END IF

  IF k = 8 THEN
    ' --- MUFFLED BOOM: high noise period, low vol ---
    sfx_type = 28
    #sfx_vol = 10
    sfx_timer = 14
    POKE $1F7, 25
    POKE $1F8, $1F
    SOUND 2, 0, 10
    PRINT AT 220 COLOR 3, "MUFFLED   "
  END IF

  IF k = 9 THEN
    ' --- STATIC BURST: very bright noise, fast decay ---
    sfx_type = 29
    #sfx_vol = 15
    sfx_timer = 8
    POKE $1F7, 2
    POKE $1F8, $1F
    SOUND 2, 0, 15
    PRINT AT 220 COLOR 6, "STATIC!   "
  END IF

  RETURN
  END


' ============================================================
' SFX UPDATE — called every frame during sfx_timer > 0
' ============================================================

UpdateSfx: PROCEDURE

  ' ---- PAGE 1: TONE-BASED ----

  IF sfx_type = 11 THEN
    ' Fast Pop: rapid descending + vol decay
    #sfx_freq = #sfx_freq + 25
    IF #sfx_vol >= 2 THEN #sfx_vol = #sfx_vol - 2 ELSE #sfx_vol = 0
    SOUND 2, #sfx_freq, #sfx_vol
  END IF

  IF sfx_type = 12 THEN
    ' Descending Crash: slow pitch drop + slow decay
    #sfx_freq = #sfx_freq + 12
    IF sfx_timer < 14 THEN
      IF #sfx_vol > 0 THEN #sfx_vol = #sfx_vol - 1
    END IF
    SOUND 2, #sfx_freq, #sfx_vol
  END IF

  IF sfx_type = 13 THEN
    ' Low Boom: deep rumble with random pitch jitter
    #sfx_freq = #sfx_freq + 8
    IF #sfx_freq > 1200 THEN #sfx_freq = 1200
    IF #sfx_vol > 0 THEN #sfx_vol = #sfx_vol - 1
    SOUND 2, #sfx_freq + RANDOM(30), #sfx_vol
  END IF

  IF sfx_type = 14 THEN
    ' Metallic Ring: pitch wobble + decay
    #sfx_phase = #sfx_phase + 1
    IF (#sfx_phase AND 1) THEN
      SOUND 2, #sfx_freq, #sfx_vol
    ELSE
      SOUND 2, #sfx_freq + 40, #sfx_vol
    END IF
    #sfx_freq = #sfx_freq + 5
    IF sfx_timer < 10 THEN
      IF #sfx_vol > 0 THEN #sfx_vol = #sfx_vol - 1
    END IF
  END IF

  IF sfx_type = 15 THEN
    ' Double-Tap: burst, silence, burst
    #sfx_phase = #sfx_phase + 1
    IF #sfx_phase <= 5 THEN
      ' First burst
      IF #sfx_vol >= 3 THEN #sfx_vol = #sfx_vol - 3 ELSE #sfx_vol = 0
      SOUND 2, #sfx_freq, #sfx_vol
    END IF
    IF #sfx_phase > 5 AND #sfx_phase <= 8 THEN
      ' Silence gap
      SOUND 2, 0, 0
    END IF
    IF #sfx_phase = 9 THEN
      ' Second burst (deeper)
      #sfx_freq = 250
      #sfx_vol = 12
      SOUND 2, 250, 12
    END IF
    IF #sfx_phase > 9 THEN
      ' Second burst decay
      #sfx_freq = #sfx_freq + 20
      IF #sfx_vol >= 2 THEN #sfx_vol = #sfx_vol - 2 ELSE #sfx_vol = 0
      SOUND 2, #sfx_freq, #sfx_vol
    END IF
  END IF

  IF sfx_type = 16 THEN
    ' Rising Burst: pitch ascends then cuts
    IF #sfx_freq > 80 THEN #sfx_freq = #sfx_freq - 35
    IF sfx_timer < 4 THEN
      IF #sfx_vol >= 3 THEN #sfx_vol = #sfx_vol - 3 ELSE #sfx_vol = 0
    END IF
    SOUND 2, #sfx_freq, #sfx_vol
  END IF

  IF sfx_type = 17 THEN
    ' Sub Rumble: very low with jitter, slow decay
    #sfx_freq = #sfx_freq + RANDOM(20)
    IF #sfx_freq > 1500 THEN #sfx_freq = 1500
    IF (sfx_timer AND 3) = 0 THEN
      IF #sfx_vol > 0 THEN #sfx_vol = #sfx_vol - 1
    END IF
    SOUND 2, #sfx_freq, #sfx_vol
  END IF

  IF sfx_type = 18 THEN
    ' Bright Zap: fast pitch rise + cut
    #sfx_freq = #sfx_freq + 8
    IF #sfx_vol >= 3 THEN #sfx_vol = #sfx_vol - 3 ELSE #sfx_vol = 0
    SOUND 2, #sfx_freq, #sfx_vol
  END IF

  IF sfx_type = 19 THEN
    ' Warble Crunch: alternating high/low pitch
    #sfx_phase = #sfx_phase + 1
    IF (#sfx_phase AND 1) THEN
      SOUND 2, #sfx_freq, #sfx_vol
    ELSE
      SOUND 2, #sfx_freq + 120, #sfx_vol
    END IF
    #sfx_freq = #sfx_freq + 6
    IF (sfx_timer AND 1) = 0 THEN
      IF #sfx_vol > 0 THEN #sfx_vol = #sfx_vol - 1
    END IF
  END IF

  ' ---- PAGE 2: NOISE-BASED ----

  IF sfx_type = 21 THEN
    ' White Noise: straight decay
    IF #sfx_vol > 0 THEN #sfx_vol = #sfx_vol - 1
    SOUND 2, 0, #sfx_vol
    POKE $1F7, 10
  END IF

  IF sfx_type = 22 THEN
    ' Deep Rumble: slow decay, noise deepens
    IF (sfx_timer AND 1) = 0 THEN
      IF #sfx_vol > 0 THEN #sfx_vol = #sfx_vol - 1
    END IF
    POKE $1F7, 28 + (25 - sfx_timer) / 8
    SOUND 2, 0, #sfx_vol
  END IF

  IF sfx_type = 23 THEN
    ' Crackling Fire: noise brightens, tone descends
    #sfx_freq = #sfx_freq + 15
    IF (sfx_timer AND 1) = 0 THEN
      IF #sfx_vol > 0 THEN #sfx_vol = #sfx_vol - 1
    END IF
    POKE $1F7, 6 + RANDOM(5)
    SOUND 2, #sfx_freq, #sfx_vol
  END IF

  IF sfx_type = 24 THEN
    ' Player Death: long noise with deepening period
    IF (sfx_timer AND 3) = 0 THEN
      IF #sfx_vol > 0 THEN #sfx_vol = #sfx_vol - 1
    END IF
    POKE $1F7, 14 + (60 - sfx_timer) / 4
    SOUND 2, 0, #sfx_vol
  END IF

  IF sfx_type = 25 THEN
    ' Chain Reaction: dual tone + noise, tones descend
    #sfx_freq = #sfx_freq + 10
    #sfx_freq2 = #sfx_freq2 + 6
    IF (sfx_timer AND 1) = 0 THEN
      IF #sfx_vol > 0 THEN #sfx_vol = #sfx_vol - 1
    END IF
    POKE $1F7, 12 + (24 - sfx_timer) / 3
    SOUND 0, #sfx_freq, #sfx_vol
    SOUND 2, #sfx_freq2, #sfx_vol
  END IF

  IF sfx_type = 26 THEN
    ' Envelope: hardware handles decay, just manage noise
    IF sfx_timer > 20 THEN
      POKE $1F7, 10 + (40 - sfx_timer) / 3
    END IF
  END IF

  IF sfx_type = 27 THEN
    ' Full Channel Blast: all channels decay together
    IF #sfx_vol > 0 THEN #sfx_vol = #sfx_vol - 1
    SOUND 0, 80 + RANDOM(20), #sfx_vol
    SOUND 1, 150 + RANDOM(30), #sfx_vol
    SOUND 2, 50 + RANDOM(15), #sfx_vol
    IF #sfx_vol > 3 THEN
      POKE $1F7, 8 + (22 - sfx_timer) / 3
    END IF
  END IF

  IF sfx_type = 28 THEN
    ' Muffled Boom: slow decay, stays quiet
    IF (sfx_timer AND 1) = 0 THEN
      IF #sfx_vol > 0 THEN #sfx_vol = #sfx_vol - 1
    END IF
    POKE $1F7, 25 + RANDOM(4)
    SOUND 2, 0, #sfx_vol
  END IF

  IF sfx_type = 29 THEN
    ' Static Burst: very bright, fast decay
    IF #sfx_vol >= 2 THEN #sfx_vol = #sfx_vol - 2 ELSE #sfx_vol = 0
    POKE $1F7, 2 + RANDOM(3)
    SOUND 2, 0, #sfx_vol
  END IF

  RETURN
  END


' ============================================================
' SILENCE ALL CHANNELS
' ============================================================

SilenceAll: PROCEDURE
  SOUND 0, 0, 0
  SOUND 1, 0, 0
  SOUND 2, 0, 0
  POKE $1F8, $3F
  sfx_type = 0
  sfx_timer = 0
  #sfx_vol = 0
  RETURN
  END


' ============================================================
' BACKGROUND MUSIC — simple amen loop for testing SFX overlay
' ============================================================
si_exp_music:
  DATA 7

si_exp_music_loop:

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

  MUSIC JUMP si_exp_music_loop
