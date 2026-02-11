' ============================================
' COMPACT_SCORE - 4px Packed Digit Score Display
' ============================================
' Renders a 16-bit score as 5 compact 4px-wide digits across 3 GRAM cards.
' Each card holds 2 digits (left in bits 7-5, right in bits 3-1).
' Card 2 holds the ones digit in the left half, right half blank.
'
' IMPORTANT: Must be called during VBLANK (via ON FRAME GOSUB) since
' GRAM is only writable during vertical blanking interval.
'
' USAGE:
'   1. Define GRAM card constants BEFORE including this file:
'      CONST SCORE_CARD0 = 61   ' Ten-thousands + thousands
'      CONST SCORE_CARD1 = 62   ' Hundreds + tens
'      CONST SCORE_CARD2 = 63   ' Ones + blank
'
'   2. INCLUDE this file (place in a SEGMENT with room):
'      INCLUDE "lib/compact_score.bas"
'
'   3. Set up BACKTAB to display these GRAM cards (in DrawHUD or similar):
'      PRINT AT pos, SCORE_CARD0 * 8 + color + $0800
'      PRINT AT pos+1, SCORE_CARD1 * 8 + color + $0800
'      PRINT AT pos+2, SCORE_CARD2 * 8 + color + $0800
'
'   4. Register ON FRAME GOSUB handler (once at init):
'      ON FRAME GOSUB ScoreFrame
'
'   5. Handler calls this routine each frame:
'      ScoreFrame: PROCEDURE
'          Row = USR COMPACT_SCORE(#Score)
'          RETURN
'      END
'
' MEMORY:
'   ~120 words code + 80 words shape data = ~200 ROM words total
'   0 words RAM (writes directly to GRAM during VBLANK)
'
' REGISTERS:
'   Input: R0 = score (0-65535)
'   Trashes: R0-R5
'   Preserves: R4 (IntyBASIC stack pointer)
'
' TECHNIQUE:
'   Composites left+right 4px digit shapes via XOR directly into GRAM.
'   Must run during VBLANK (ON FRAME GOSUB) since GRAM is only CPU-
'   writable during vertical blanking. Packed DECLEs are unpacked via
'   MVO@ (low byte) + SWAP + MVO@ (high byte) for 2 GRAM rows each.
'   Digit extraction via repeated subtraction (no hardware divide).
'   Shape data from TinyFont.bas (GroovyBee, AtariAge).
'
' ============================================

ASM COMPACT_SCORE: PROC
ASM     PSHR    R5              ; Save return address
ASM     PSHR    R4              ; Save IntyBASIC stack pointer

    ' -----------------------------------------------
    ' Extract D4 (ten-thousands digit) via repeated subtraction
    ' R0 = score, R1 = D4 counter
    ' -----------------------------------------------
ASM     CLRR    R1              ; R1 = 0 (digit counter)
ASM @@d4:
ASM     CMPI    #10000, R0
ASM     BLT     @@d4done
ASM     SUBI    #10000, R0
ASM     INCR    R1
ASM     B       @@d4
ASM @@d4done:
    ' R1 = D4 (0-6), R0 = remainder (0-9999)

    ' -----------------------------------------------
    ' Extract D3 (thousands digit)
    ' -----------------------------------------------
ASM     CLRR    R2              ; R2 = 0
ASM @@d3:
ASM     CMPI    #1000,  R0
ASM     BLT     @@d3done
ASM     SUBI    #1000,  R0
ASM     INCR    R2
ASM     B       @@d3
ASM @@d3done:
    ' R2 = D3 (0-9), R0 = remainder (0-999)

    ' -----------------------------------------------
    ' Composite Card 0: digits D4, D3 -> GRAM card 61
    ' R5 auto-increments through cards 61-63 (consecutive)
    ' -----------------------------------------------
ASM     PSHR    R0              ; Save remainder on stack

    ' Compute left shape address: @@LeftShapes + D4 * 4
ASM     SLL     R1,     2       ; D4 * 4
ASM     ADDI    #@@LeftShapes, R1

    ' Compute right shape address: @@RightShapes + D3 * 4
ASM     SLL     R2,     2       ; D3 * 4
ASM     ADDI    #@@RightShapes, R2

ASM     MOVR    R1,     R4      ; R4 = left source (auto-inc on MVI@)
ASM     MOVR    R2,     R3      ; R3 = right source (manual inc)
ASM     MVII    #$39E8, R5      ; R5 = GRAM dest: $3800 + 61*8

    ' Composite 4 packed words -> 8 GRAM rows (unpack low/high bytes)
ASM     REPEAT  4
ASM     MVI@    R4,     R0      ; Load left packed word (2 rows)
ASM     MVI@    R3,     R1      ; Load right packed word (R3 no auto-inc)
ASM     XORR    R1,     R0      ; Combine (XOR = OR, bits don't overlap)
ASM     MVO@    R0,     R5      ; Write low byte (even row) to GRAM
ASM     SWAP    R0              ; Get high byte
ASM     MVO@    R0,     R5      ; Write high byte (odd row) to GRAM
ASM     INCR    R3              ; Advance right pointer manually
ASM     ENDR

    ' -----------------------------------------------
    ' Extract D2 (hundreds digit)
    ' -----------------------------------------------
ASM     PULR    R0              ; Restore remainder (0-999)
ASM     CLRR    R1
ASM @@d2:
ASM     CMPI    #100,   R0
ASM     BLT     @@d2done
ASM     SUBI    #100,   R0
ASM     INCR    R1
ASM     B       @@d2
ASM @@d2done:
    ' R1 = D2 (0-9), R0 = remainder (0-99)

    ' -----------------------------------------------
    ' Extract D1 (tens digit)
    ' -----------------------------------------------
ASM     CLRR    R2
ASM @@d1:
ASM     CMPI    #10,    R0
ASM     BLT     @@d1done
ASM     SUBI    #10,    R0
ASM     INCR    R2
ASM     B       @@d1
ASM @@d1done:
    ' R2 = D1 (0-9), R0 = D0 (ones digit, 0-9)

    ' -----------------------------------------------
    ' Composite Card 1: digits D2, D1
    ' R5 already points to card 62 GRAM from Card 0 auto-increment
    ' -----------------------------------------------
ASM     PSHR    R0              ; Save D0 for card 2

ASM     SLL     R1,     2       ; D2 * 4
ASM     ADDI    #@@LeftShapes, R1
ASM     SLL     R2,     2       ; D1 * 4
ASM     ADDI    #@@RightShapes, R2

ASM     MOVR    R1,     R4      ; R4 = left source
ASM     MOVR    R2,     R3      ; R3 = right source
    ' R5 continues at card 62 GRAM (auto-incremented by Card 0)

ASM     REPEAT  4
ASM     MVI@    R4,     R0
ASM     MVI@    R3,     R1
ASM     XORR    R1,     R0
ASM     MVO@    R0,     R5      ; Write low byte (even row) to GRAM
ASM     SWAP    R0
ASM     MVO@    R0,     R5      ; Write high byte (odd row) to GRAM
ASM     INCR    R3
ASM     ENDR

    ' -----------------------------------------------
    ' Card 2: D0 + blank (left digit only)
    ' R5 already points to card 63 GRAM from Card 1 auto-increment
    ' -----------------------------------------------
ASM     PULR    R0              ; Restore D0 (0-9)
ASM     SLL     R0,     2       ; D0 * 4
ASM     ADDI    #@@LeftShapes, R0
ASM     MOVR    R0,     R4      ; R4 = left source
    ' R5 continues at card 63 GRAM

    ' No right digit - unpack left shape directly to GRAM
ASM     REPEAT  4
ASM     MVI@    R4,     R0      ; Load packed word
ASM     MVO@    R0,     R5      ; Write low byte (even row) to GRAM
ASM     SWAP    R0
ASM     MVO@    R0,     R5      ; Write high byte (odd row) to GRAM
ASM     ENDR

ASM     PULR    R4              ; Restore IntyBASIC stack pointer
ASM     PULR    PC              ; Return

    ' -----------------------------------------------
    ' Shape data — packed DECLE format (from TinyFont.bas)
    ' Each digit = 4 words, Word N = (row[2N+1] << 8) | row[2N]
    ' Left digits use bits 7-5, right digits use bits 3-1
    ' -----------------------------------------------

ASM @@LeftShapes:
    ' Left half digit shapes (0-9)
ASM     DECLE   $4000, $E0A0, $A0E0, $0040     ; 0
ASM     DECLE   $4000, $40C0, $4040, $00E0     ; 1
ASM     DECLE   $4000, $20A0, $8040, $00E0     ; 2
ASM     DECLE   $E000, $4020, $A020, $0040     ; 3
ASM     DECLE   $8000, $A080, $E0A0, $0020     ; 4
ASM     DECLE   $E000, $C080, $A020, $0040     ; 5
ASM     DECLE   $6000, $C080, $A0A0, $0040     ; 6
ASM     DECLE   $E000, $2020, $4040, $0040     ; 7
ASM     DECLE   $4000, $40A0, $A0A0, $0040     ; 8
ASM     DECLE   $6000, $A0A0, $2060, $0020     ; 9

ASM @@RightShapes:
    ' Right half digit shapes (0-9)
ASM     DECLE   $0400, $0E0A, $0A0E, $0004     ; 0
ASM     DECLE   $0400, $040C, $0404, $000E     ; 1
ASM     DECLE   $0400, $020A, $0804, $000E     ; 2
ASM     DECLE   $0E00, $0402, $0A02, $0004     ; 3
ASM     DECLE   $0800, $0A08, $0E0A, $0002     ; 4
ASM     DECLE   $0E00, $0C08, $0A02, $0004     ; 5
ASM     DECLE   $0600, $0C08, $0A0A, $0004     ; 6
ASM     DECLE   $0E00, $0202, $0404, $0004     ; 7
ASM     DECLE   $0400, $040A, $0A0A, $0004     ; 8
ASM     DECLE   $0600, $0A0A, $0206, $0002     ; 9

ASM     ENDP
