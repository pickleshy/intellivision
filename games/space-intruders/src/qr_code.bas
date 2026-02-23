' ============================================================
' QR Code - https://paisleyboxers.itch.io/space-intruders
' Version 3, 29x29 modules, padded to 40x40px = 5x5 GRAM tiles
' 25 GRAM cards: QR_GRAM_BASE through QR_GRAM_BASE+24
' ============================================================
' Include alongside graphics.bas (Segment 2 data).
' Call DrawQrCode from BootSplash.
'
' NOTE: QR_GRAM_BASE=0 conflicts with TinyFont URL (also cards 0-10).
' Either raise QR_GRAM_BASE to 11+ and keep TinyFont, or remove the
' TinyFont URL from BootSplash (the QR encodes the same URL anyway).
'
' No new variables needed — reuses: LoopVar, Col, Row, WipeCol.
' ============================================================

CONST QR_GRAM_BASE = 11  ' First GRAM card used (occupies +11 through +35); cards 0-10 = TinyFont URL
CONST QR_X        = 7   ' Left column on BACKTAB — centered: (20-5)/2 = 7.5 → col 7
CONST QR_Y        = 1   ' Top row on BACKTAB — rows 1-5, leaving row 7 for TinyFont URL

    SEGMENT 2

' --- QR Tile Bitmaps ---
' 25 tiles in row-major order: tile 0=top-left, tile 24=bottom-right.
' Split into batches of 4 for safe DEFINE (matches BootSplash convention).

QrBatch0:   ' Tiles 0-3
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP ".....###"
    BITMAP ".....#.."
    BITMAP ".....#.#"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "####...#"
    BITMAP "...#..#."
    BITMAP "##.#.#.."
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "..###.##"
    BITMAP "..#.###."
    BITMAP "#......."
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "#..#####"
    BITMAP "#..#...."
    BITMAP "#..#.###"

QrBatch1:   ' Tiles 4-7
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "##......"
    BITMAP ".#......"
    BITMAP ".#......"
    BITMAP ".....#.#"
    BITMAP ".....#.#"
    BITMAP ".....#.."
    BITMAP ".....###"
    BITMAP "........"
    BITMAP ".....###"
    BITMAP ".....###"
    BITMAP ".....#.."
    BITMAP "##.#..#."
    BITMAP "##.#..#."
    BITMAP "...#...#"
    BITMAP "####.#.#"
    BITMAP ".....#.."
    BITMAP ".#####.."
    BITMAP "###.#.#."
    BITMAP "##.###.#"
    BITMAP ".#.#...#"
    BITMAP ".#####.."
    BITMAP "##.#####"
    BITMAP ".#.#.#.#"
    BITMAP "#.#.###."
    BITMAP ".##..##."
    BITMAP "####.##."
    BITMAP "##....##"

QrBatch2:   ' Tiles 8-11
    BITMAP "...#.###"
    BITMAP "##.#.###"
    BITMAP "##.#...."
    BITMAP ".#.#####"
    BITMAP "........"
    BITMAP "..##...#"
    BITMAP ".###..#."
    BITMAP ".##.#..#"
    BITMAP ".#......"
    BITMAP ".#......"
    BITMAP ".#......"
    BITMAP "##......"
    BITMAP "........"
    BITMAP "........"
    BITMAP ".#......"
    BITMAP "##......"
    BITMAP ".....###"
    BITMAP "......##"
    BITMAP ".....###"
    BITMAP ".....#.#"
    BITMAP ".....#.#"
    BITMAP "........"
    BITMAP "......#."
    BITMAP ".....#.#"
    BITMAP "#.#...##"
    BITMAP "##.#.#.#"
    BITMAP "#.#.#.##"
    BITMAP "#..#...."
    BITMAP ".##.#..."
    BITMAP "##.#...."
    BITMAP "..#..#.."
    BITMAP "##.###.#"

QrBatch3:   ' Tiles 12-15
    BITMAP ".##...##"
    BITMAP "#.#..##."
    BITMAP "#.##.#.."
    BITMAP "..##...#"
    BITMAP "#.#.#.#."
    BITMAP ".##..###"
    BITMAP "####.#.."
    BITMAP "##...##."
    BITMAP "..#.#..."
    BITMAP "..###.#."
    BITMAP ".###..#."
    BITMAP "..#####."
    BITMAP "##..###."
    BITMAP ".###..#."
    BITMAP ".#.#..##"
    BITMAP ".#..##.."
    BITMAP "#......."
    BITMAP "##......"
    BITMAP ".#......"
    BITMAP "##......"
    BITMAP "#......."
    BITMAP "##......"
    BITMAP ".#......"
    BITMAP "##......"
    BITMAP "......##"
    BITMAP ".....#.."
    BITMAP "........"
    BITMAP ".....###"
    BITMAP ".....#.."
    BITMAP ".....#.#"
    BITMAP ".....#.#"
    BITMAP ".....#.#"

QrBatch4:   ' Tiles 16-19
    BITMAP "#.#..###"
    BITMAP "##.###.#"
    BITMAP ".....#.."
    BITMAP "####.##."
    BITMAP "...#.##."
    BITMAP "##.#.##."
    BITMAP "##.#..##"
    BITMAP "##.#.###"
    BITMAP ".####.#."
    BITMAP "###...#."
    BITMAP "#.#..#.."
    BITMAP ".......#"
    BITMAP "..#...##"
    BITMAP "..#...#."
    BITMAP ".##..#.."
    BITMAP ".#....#."
    BITMAP "#...#.#."
    BITMAP "######.."
    BITMAP ".#...#.#"
    BITMAP "##.#.##."
    BITMAP ".#...##."
    BITMAP ".#####.."
    BITMAP ".#..##.#"
    BITMAP "#...###."
    BITMAP "#......."
    BITMAP "........"
    BITMAP "##......"
    BITMAP "##......"
    BITMAP "........"
    BITMAP "#......."
    BITMAP "##......"
    BITMAP ".#......"

QrBatch5:   ' Tiles 20-23
    BITMAP ".....#.."
    BITMAP ".....###"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "...#.#.."
    BITMAP "####.#.."
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "..##.###"
    BITMAP "..#.####"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "###.#..."
    BITMAP "##...##."
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"

QrBatch6:   ' Tile 24
    BITMAP "#......."
    BITMAP "##......"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"
    BITMAP "........"

' --- DrawQrCode: Load GRAM and render 5x5 QR grid to BACKTAB ---
' White modules on black background (QR scanners accept this orientation).
' 7 DEFINE+WAIT calls load all 25 tiles before drawing.
DrawQrCode: PROCEDURE
    DEFINE QR_GRAM_BASE,      4, QrBatch0 : WAIT
    DEFINE QR_GRAM_BASE +  4, 4, QrBatch1 : WAIT
    DEFINE QR_GRAM_BASE +  8, 4, QrBatch2 : WAIT
    DEFINE QR_GRAM_BASE + 12, 4, QrBatch3 : WAIT
    DEFINE QR_GRAM_BASE + 16, 4, QrBatch4 : WAIT
    DEFINE QR_GRAM_BASE + 20, 4, QrBatch5 : WAIT
    DEFINE QR_GRAM_BASE + 24, 1, QrBatch6 : WAIT
    FOR LoopVar = 0 TO 4
        Row = LoopVar * 5
        FOR Col = 0 TO 4
            WipeCol = (QR_Y + LoopVar) * 20 + (QR_X + Col)
            PRINT AT WipeCol, (QR_GRAM_BASE + Row + Col) * 8 + COL_WHITE + $0800
        NEXT Col
    NEXT LoopVar
    RETURN
END