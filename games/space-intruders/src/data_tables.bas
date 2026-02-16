' ============================================
' SPACE INTRUDERS - Data Tables Module
' ============================================
' ROM lookup tables for performance optimization
'  Segment 2 (main tables) and Segment 5 (PackedPairs)

    SEGMENT 2

' PowerUp weighted random selection
PowerUpWeights:
    DATA 0, 0, 1, 1, 2, 2, 3, 4

' Bitmask lookup table
ColMaskData:
    DATA 1, 2, 4, 8, 16, 32, 64, 128, 256, 512

' Row-to-BACKTAB-position lookup: Row20Data(n) = n * 20 (rows 0-11)
' Replaces software multiply in DrawAliens hot path (~20-50 cyc saved per use)
Row20Data:
    DATA 0, 20, 40, 60, 80, 100, 120, 140, 160, 180, 200, 220, 240

' ╔════════════════════════════════════════════════════════════╗
' ║  LEVEL DESIGN — 32-wave cycle (AND 31 wrapping)          ║
' ║  Edit here or use Wave Designer tool:                     ║
' ║  Run: cd tools/wave-designer && python3 app.py            ║
' ╚════════════════════════════════════════════════════════════╝

' Pattern B formations: 5 bitmasks per pattern (rows 0-4), 9 cols = bits 0-8

' Parallax silhouette data
SilhHeightMap:
    DATA 0, 0, 1, 2, 3, 4, 4, 3, 2, 1
    DATA 0, 0, 0, 1, 2, 3, 4, 3, 2, 0
    DATA 0, 1, 2, 4, 4, 4, 3, 2, 1, 0
    DATA 0, 0, 1, 3, 4, 3, 1, 0, 0, 0

' Pre-computed BACKTAB card values for each height level (purple, color 15)
SilhCardMap:
    DATA 0
    DATA 6319
    DATA 6327
    DATA 6335
    DATA 6343

' --- Flying Saucer (rounded rectangle) ---

    SEGMENT 5
' Score display packed digit data
PackedPairs:
    DATA $4400, $EEAA, $AAEE, $0044  ' 00
    DATA $4400, $E4AC, $A4E4, $004E  ' 01
    DATA $4400, $E2AA, $A8E4, $004E  ' 02
    DATA $4E00, $E4A2, $AAE2, $0044  ' 03
    DATA $4800, $EAA8, $AEEA, $0042  ' 04
    DATA $4E00, $ECA8, $AAE2, $0044  ' 05
    DATA $4600, $ECA8, $AAEA, $0044  ' 06
    DATA $4E00, $E2A2, $A4E4, $0044  ' 07
    DATA $4400, $E4AA, $AAEA, $0044  ' 08
    DATA $4600, $EAAA, $A2E6, $0042  ' 09
    DATA $4400, $4ECA, $4A4E, $00E4  ' 10
    DATA $4400, $44CC, $4444, $00EE  ' 11
    DATA $4400, $42CA, $4844, $00EE  ' 12
    DATA $4E00, $44C2, $4A42, $00E4  ' 13
    DATA $4800, $4AC8, $4E4A, $00E2  ' 14
    DATA $4E00, $4CC8, $4A42, $00E4  ' 15
    DATA $4600, $4CC8, $4A4A, $00E4  ' 16
    DATA $4E00, $42C2, $4444, $00E4  ' 17
    DATA $4400, $44CA, $4A4A, $00E4  ' 18
    DATA $4600, $4ACA, $4246, $00E2  ' 19
    DATA $4400, $2EAA, $8A4E, $00E4  ' 20
    DATA $4400, $24AC, $8444, $00EE  ' 21
    DATA $4400, $22AA, $8844, $00EE  ' 22
    DATA $4E00, $24A2, $8A42, $00E4  ' 23
    DATA $4800, $2AA8, $8E4A, $00E2  ' 24
    DATA $4E00, $2CA8, $8A42, $00E4  ' 25
    DATA $4600, $2CA8, $8A4A, $00E4  ' 26
    DATA $4E00, $22A2, $8444, $00E4  ' 27
    DATA $4400, $24AA, $8A4A, $00E4  ' 28
    DATA $4600, $2AAA, $8246, $00E2  ' 29
    DATA $E400, $4E2A, $AA2E, $0044  ' 30
    DATA $E400, $442C, $A424, $004E  ' 31
    DATA $E400, $422A, $A824, $004E  ' 32
    DATA $EE00, $4422, $AA22, $0044  ' 33
    DATA $E800, $4A28, $AE2A, $0042  ' 34
    DATA $EE00, $4C28, $AA22, $0044  ' 35
    DATA $E600, $4C28, $AA2A, $0044  ' 36
    DATA $EE00, $4222, $A424, $0044  ' 37
    DATA $E400, $442A, $AA2A, $0044  ' 38
    DATA $E600, $4A2A, $A226, $0042  ' 39
    DATA $8400, $AE8A, $EAAE, $0024  ' 40
    DATA $8400, $A48C, $E4A4, $002E  ' 41
    DATA $8400, $A28A, $E8A4, $002E  ' 42
    DATA $8E00, $A482, $EAA2, $0024  ' 43
    DATA $8800, $AA88, $EEAA, $0022  ' 44
    DATA $8E00, $AC88, $EAA2, $0024  ' 45
    DATA $8600, $AC88, $EAAA, $0024  ' 46
    DATA $8E00, $A282, $E4A4, $0024  ' 47
    DATA $8400, $A48A, $EAAA, $0024  ' 48
    DATA $8600, $AA8A, $E2A6, $0022  ' 49
    DATA $E400, $CE8A, $AA2E, $0044  ' 50
    DATA $E400, $C48C, $A424, $004E  ' 51
    DATA $E400, $C28A, $A824, $004E  ' 52
    DATA $EE00, $C482, $AA22, $0044  ' 53
    DATA $E800, $CA88, $AE2A, $0042  ' 54
    DATA $EE00, $CC88, $AA22, $0044  ' 55
    DATA $E600, $CC88, $AA2A, $0044  ' 56
    DATA $EE00, $C282, $A424, $0044  ' 57
    DATA $E400, $C48A, $AA2A, $0044  ' 58
    DATA $E600, $CA8A, $A226, $0042  ' 59
    DATA $6400, $CE8A, $AAAE, $0044  ' 60
    DATA $6400, $C48C, $A4A4, $004E  ' 61
    DATA $6400, $C28A, $A8A4, $004E  ' 62
    DATA $6E00, $C482, $AAA2, $0044  ' 63
    DATA $6800, $CA88, $AEAA, $0042  ' 64
    DATA $6E00, $CC88, $AAA2, $0044  ' 65
    DATA $6600, $CC88, $AAAA, $0044  ' 66
    DATA $6E00, $C282, $A4A4, $0044  ' 67
    DATA $6400, $C48A, $AAAA, $0044  ' 68
    DATA $6600, $CA8A, $A2A6, $0042  ' 69
    DATA $E400, $2E2A, $4A4E, $0044  ' 70
    DATA $E400, $242C, $4444, $004E  ' 71
    DATA $E400, $222A, $4844, $004E  ' 72
    DATA $EE00, $2422, $4A42, $0044  ' 73
    DATA $E800, $2A28, $4E4A, $0042  ' 74
    DATA $EE00, $2C28, $4A42, $0044  ' 75
    DATA $E600, $2C28, $4A4A, $0044  ' 76
    DATA $EE00, $2222, $4444, $0044  ' 77
    DATA $E400, $242A, $4A4A, $0044  ' 78
    DATA $E600, $2A2A, $4246, $0042  ' 79
    DATA $4400, $4EAA, $AAAE, $0044  ' 80
    DATA $4400, $44AC, $A4A4, $004E  ' 81
    DATA $4400, $42AA, $A8A4, $004E  ' 82
    DATA $4E00, $44A2, $AAA2, $0044  ' 83
    DATA $4800, $4AA8, $AEAA, $0042  ' 84
    DATA $4E00, $4CA8, $AAA2, $0044  ' 85
    DATA $4600, $4CA8, $AAAA, $0044  ' 86
    DATA $4E00, $42A2, $A4A4, $0044  ' 87
    DATA $4400, $44AA, $AAAA, $0044  ' 88
    DATA $4600, $4AAA, $A2A6, $0042  ' 89
    DATA $6400, $AEAA, $2A6E, $0024  ' 90
    DATA $6400, $A4AC, $2464, $002E  ' 91
    DATA $6400, $A2AA, $2864, $002E  ' 92
    DATA $6E00, $A4A2, $2A62, $0024  ' 93
    DATA $6800, $AAA8, $2E6A, $0022  ' 94
    DATA $6E00, $ACA8, $2A62, $0024  ' 95
    DATA $6600, $ACA8, $2A6A, $0024  ' 96
    DATA $6E00, $A2A2, $2464, $0024  ' 97
    DATA $6400, $A4AA, $2A6A, $0024  ' 98
    DATA $6600, $AAAA, $2266, $0022  ' 99
PackedPairsSingle:
    DATA $4000, $E0A0, $A0E0, $0040  ' 0_
    DATA $4000, $40C0, $4040, $00E0  ' 1_
    DATA $4000, $20A0, $8040, $00E0  ' 2_
    DATA $E000, $4020, $A020, $0040  ' 3_
    DATA $8000, $A080, $E0A0, $0020  ' 4_
    DATA $E000, $C080, $A020, $0040  ' 5_
    DATA $6000, $C080, $A0A0, $0040  ' 6_
    DATA $E000, $2020, $4040, $0040  ' 7_
    DATA $4000, $40A0, $A0A0, $0040  ' 8_
    DATA $6000, $A0A0, $2060, $0020  ' 9_

' Pre-computed TinyFont character pair shapes for HUD "SCORE:" label.
' From TinyFont.bas LEFT + RIGHT shapes XOR'd (bits don't overlap).
' 3 entries: "SC", "OR", "E:" — 4 packed DECLEs each = 12 ROM words.
TinyFontLabelData:
    DATA $6400, $488A, $AA28, $0044  ' "SC" (card 34)
    DATA $4C00, $AAAA, $AAAC, $004A  ' "OR" (card 35)
    DATA $E000, $C880, $8080, $00E8  ' "E:" (card 36)

' Chain cards 58-60 are static (DEFINE'd at StartGame from ChainCHGfx/AIGfx/NGfx).
PatternBData:
    DATA $081, $042, $024, $018, $024  '  0: Chevron
    DATA $0D6, $038, $06C, $092, $000  '  1: Diamond
    DATA $099, $0BD, $099, $081, $081  '  2: Pillars
    DATA $081, $08D, $101, $162, $102  '  3: Dual Pillars
    DATA $155, $0AA, $16D, $092, $155  '  4: Checkerboard
    DATA $030, $048, $0B4, $17A, $084  '  5: Arrow
    DATA $078, $084, $1B6, $0CC, $078  '  6: Fortress
    DATA $0FE, $0FE, $0FE, $0FE, $0FE '  7: Phalanx
    DATA $010, $038, $1C7, $038, $010  '  8: Cross
    DATA $183, $0C6, $000, $0C6, $183  '  9: Wings
    DATA $007, $038, $1C0, $038, $007  ' 10: Zigzag
    DATA $1FF, $101, $101, $101, $1FF  ' 11: Frame
    DATA $111, $000, $054, $000, $111  ' 12: Scatter
    DATA $1FF, $07C, $038, $010, $000  ' 13: Funnel
    DATA $010, $028, $044, $0AA, $1FF  ' 14: Inverted V
    DATA $1FF, $1FF, $000, $1FF, $1FF  ' 15: Dense Rows
    DATA $038, $07C, $0FE, $07C, $038  ' 16: Fortress (alt)
    DATA $155, $0AA, $155, $0AA, $155  ' 17: Checkerboard (alt)
    DATA $010, $038, $1FF, $038, $010  ' 18: Cross (alt)
    DATA $101, $10D, $101, $161, $101  ' 19: Dual Pillars (alt)
    DATA $010, $028, $044, $082, $101  ' 20: Arrow (alt)
    DATA $119, $13D, $119, $101, $101  ' 21: Pillars (alt)
    DATA $1FF, $000, $1FF, $000, $1FF  ' 22: Phalanx (alt)

' Which pattern B per level (wraps after 32)
PatternBIndex:
    DATA 0, 1, 2, 3, 4, 5, 6, 7        ' Waves  1-8
    DATA 8, 9, 10, 11, 0, 12, 13, 14   ' Waves  9-16
    DATA 15, 16, 9, 17, 11, 18, 19, 20 ' Waves 17-24
    DATA 14, 21, 10, 15, 13, 22, 12, 16 ' Waves 25-32

' Orbiter path around 2-wide bomb boss (10 steps, biased +1)
' Actual offset = DATA value - 1 (so 0 means -1, 1 means 0, etc.)
'   Step:  0   1   2   3   4   5   6   7   8   9
'   Cell: TL  T1  T2  TR   R  BR  B2  B1  BL   L
OrbitDX:
    DATA 0, 1, 2, 3, 3, 3, 2, 1, 0, 0
OrbitDY:
