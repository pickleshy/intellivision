' ════════════════════════════════════════
' Stage 3: Stage 4  [hardest]
' Source: warrior-legacy_violin.mid  BPM: 92
' Obstacles: 18  Start slot: 404
' ════════════════════════════════════════

' --- Melody (128 PSG periods) ---
    DATA  320,    0,    0,    0,  339,    0,    0,    0   ' pos 0-7
    DATA  254,    0,  285,    0,  320,    0,    0,    0   ' pos 8-15
    DATA  381,    0,    0,    0,    0,    0,  381,    0   ' pos 16-23
    DATA  339,    0,  320,    0,  339,  381,  428,    0   ' pos 24-31
    DATA    0,    0,    0,    0,  508,    0,    0,    0   ' pos 32-39
    DATA    0,    0,  428,    0,  381,    0, 1524,    0   ' pos 40-47
    DATA 1524, 1524, 1524,    0, 1524,    0,    0,    0   ' pos 48-55
    DATA    0,    0,    0,    0,  762,    0,    0,    0   ' pos 56-63
    DATA  679,    0,    0,    0,  641,    0,  508,    0   ' pos 64-71
    DATA  320,    0,  339,    0,  381,    0,    0,    0   ' pos 72-79
    DATA    0,    0,    0,    0,    0,    0,    0,    0   ' pos 80-87
    DATA  428,    0,    0,    0,  508,    0,    0,    0   ' pos 88-95
    DATA    0,    0,    0,    0,    0,    0,  508,    0   ' pos 96-103
    DATA  320,    0,  339,    0,  320,    0,    0,    0   ' pos 104-111
    DATA    0,    0,    0,    0,    0,    0,  320,    0   ' pos 112-119
    DATA  285,    0,    0,    0,  254,    0,  641,    0   ' pos 120-127

' --- Obstacles (128 entries) ---
    DATA 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0   ' pos 0-15
    DATA 1,0,0,0, 0,0,0,0, 0,0,0,0, 1,0,0,0   ' pos 16-31: beat 16,28
    DATA 1,0,0,0, 1,0,0,0, 1,0,0,0, 1,0,0,0   ' pos 32-47: beat 32,36,40,44
    DATA 0,0,0,0, 0,0,0,0, 0,0,0,0, 1,0,0,0   ' pos 48-63: beat 60
    DATA 0,0,0,0, 1,0,0,0, 0,0,0,0, 1,0,0,0   ' pos 64-79: beat 68,76
    DATA 0,0,0,0, 0,0,0,0, 1,0,1,0, 1,0,0,0   ' pos 80-95: beat 88,90,92
    DATA 0,0,0,0, 0,0,0,0, 1,0,1,0, 1,0,0,0   ' pos 96-111: beat 104,106,108
    DATA 0,0,0,0, 1,0,0,0, 1,0,0,1, 0,0,0,0   ' pos 112-127: beat 116,120,123

' --- Hazard Config ---
' PENCILS: max=2, window=[20,108]
' FLOWERS: max=2, window=[55,128], heal=1
' TUBA: max=1, window=[50,100], invincibility=180f
' SNEEZE: enabled=1, maxSneezes=1, spawnStartPercent=20, spawnEndPercent=90
