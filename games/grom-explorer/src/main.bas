' ============================================
' GROM Explorer - View all 256 GROM characters
' ============================================
' Navigate with disc: Up/Down changes page
' Each page shows 64 characters (8 rows x 8 cols)
' Card number shown in hex below each character
'
' Page 0: Cards 0-63
' Page 1: Cards 64-127
' Page 2: Cards 128-191
' Page 3: Cards 192-255
' ============================================

Page = 0

MODE 0, 0, 0, 0, 0  ' Color stack mode, black background
WAIT

MainLoop:
    CLS
    WAIT

    ' Title
    PRINT AT 0 COLOR 7, "GROM EXPLORER PG:"
    PRINT AT 18, <>Page

    ' Calculate starting card for this page
    StartCard = Page * 64

    ' Draw 8 rows of 8 characters each
    FOR Row = 0 TO 7
        FOR Col = 0 TO 7
            Card = StartCard + Row * 8 + Col

            ' Position: row 1-8 (skip title), columns spread out
            ' Each character gets 2 columns (char + space)
            ScreenPos = (Row + 1) * 20 + Col * 2 + 2

            ' Draw the GROM character (card << 3 gives BACKTAB value)
            ' Use color 7 (white) for visibility
            PRINT AT ScreenPos, (Card * 8) + 7
        NEXT Col
    NEXT Row

    ' Draw card numbers below (in hex-ish: show decimal for now)
    PRINT AT 200 COLOR 3, "CARDS:"
    PRINT AT 207, <>StartCard
    PRINT AT 211 COLOR 3, "-"
    PRINT AT 212, <>(StartCard + 63)

    ' Instructions
    PRINT AT 180 COLOR 5, "DISC UP/DN = PAGE"

InputLoop:
    WAIT

    ' Read disc
    Dir = CONT.UP + CONT.DOWN * 2

    IF Dir = 1 THEN
        ' Up - previous page
        IF Page > 0 THEN
            Page = Page - 1
            GOTO MainLoop
        END IF
    END IF

    IF Dir = 2 THEN
        ' Down - next page
        IF Page < 3 THEN
            Page = Page + 1
            GOTO MainLoop
        END IF
    END IF

    GOTO InputLoop
