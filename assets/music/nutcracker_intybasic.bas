' ============================================
' Nutcracker March - IntyBASIC MUSIC Format
' Simplified 3-channel arrangement
' Original by Tchaikovsky
' ============================================
' Channel 1: Melody (high)
' Channel 2: Harmony (mid)
' Channel 3: Bass (low)
' ============================================

NutcrackerMarch:
    DATA 7

    ' VOLUME TEST: Same note A4 on each channel, then all together
    ' If all 3 channels work, the combined sound should be 3x louder

    ' A4 on CH1 only (should hear it)
    MUSIC A4,-,-,-
    MUSIC S,-,-,-
    MUSIC S,-,-,-
    MUSIC S,-,-,-
    MUSIC S,-,-,-
    MUSIC S,-,-,-
    MUSIC -,-,-,-
    MUSIC -,-,-,-

    ' A4 on CH2 only (should hear it)
    MUSIC -,A4,-,-
    MUSIC -,S,-,-
    MUSIC -,S,-,-
    MUSIC -,S,-,-
    MUSIC -,S,-,-
    MUSIC -,S,-,-
    MUSIC -,-,-,-
    MUSIC -,-,-,-

    ' A4 on CH3 only (does this play?)
    MUSIC -,-,A4,-
    MUSIC -,-,S,-
    MUSIC -,-,S,-
    MUSIC -,-,S,-
    MUSIC -,-,S,-
    MUSIC -,-,S,-
    MUSIC -,-,-,-
    MUSIC -,-,-,-

    ' A4 on ALL THREE (should be much louder if 3 channels work)
    MUSIC A4,A4,A4,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC -,-,-,-
    MUSIC -,-,-,-

    ' Opening fanfare - G major chord hits
    MUSIC G5,B4,G3,-
    MUSIC S,S,S,-
    MUSIC -,-,-,-
    MUSIC -,-,-,-
    MUSIC G5,B4,G3,-
    MUSIC S,S,S,-
    MUSIC -,-,-,-
    MUSIC -,-,-,-
    MUSIC G5,B4,G3,-
    MUSIC S,S,S,-
    MUSIC -,-,-,-
    MUSIC -,-,-,-
    MUSIC G5,D5,G3,-
    MUSIC S,S,S,-
    MUSIC -,-,-,-
    MUSIC -,-,-,-

    ' Main theme A - E minor feel
    MUSIC E5,B4,E3,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC -,-,-,-
    MUSIC -,-,-,-
    MUSIC E5,B4,E3,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC -,-,-,-
    MUSIC -,-,-,-

    MUSIC F5,C5,F3,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC -,-,-,-
    MUSIC -,-,-,-

    MUSIC G5,D5,G3,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-

    ' Theme B - higher melody
    MUSIC G5,E5,C4,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC -,-,-,-
    MUSIC -,-,-,-
    MUSIC G5,E5,C4,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC -,-,-,-
    MUSIC -,-,-,-

    MUSIC A5,F5,D4,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC -,-,-,-
    MUSIC -,-,-,-

    MUSIC B5,G5,D4,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-

    ' March section - staccato hits
    MUSIC G5,D5,G3,-
    MUSIC S,S,S,-
    MUSIC -,-,-,-
    MUSIC G5,D5,G3,-
    MUSIC S,S,S,-
    MUSIC -,-,-,-
    MUSIC A5,E5,A3,-
    MUSIC S,S,S,-
    MUSIC -,-,-,-
    MUSIC A5,E5,A3,-
    MUSIC S,S,S,-
    MUSIC -,-,-,-

    MUSIC B5,F5,B3,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-

    ' Descending passage
    MUSIC D6,A5,D4,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC -,-,-,-
    MUSIC C6,G5,C4,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC -,-,-,-
    MUSIC B5,F5,B3,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC -,-,-,-
    MUSIC A5,E5,A3,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC -,-,-,-

    ' Resolution chord
    MUSIC G5,D5,G3,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-

    ' Repeat theme A
    MUSIC E5,B4,E3,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC -,-,-,-
    MUSIC -,-,-,-
    MUSIC E5,B4,E3,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC -,-,-,-
    MUSIC -,-,-,-

    MUSIC F5,C5,F3,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC -,-,-,-
    MUSIC -,-,-,-

    MUSIC G5,D5,G3,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-

    ' Higher theme
    MUSIC B5,G5,G3,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC -,-,-,-
    MUSIC -,-,-,-
    MUSIC B5,G5,G3,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC -,-,-,-
    MUSIC -,-,-,-

    MUSIC C6,A5,A3,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC -,-,-,-
    MUSIC -,-,-,-

    MUSIC D6,B5,B3,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-

    ' Final descent
    MUSIC D6,A5,D4,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC -,-,-,-
    MUSIC C6,G5,C4,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC -,-,-,-
    MUSIC B5,F5,B3,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC -,-,-,-
    MUSIC A5,E5,A3,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC -,-,-,-

    ' Grand finale
    MUSIC G5,D5,G3,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC -,-,-,-
    MUSIC -,-,-,-

    MUSIC G5,B4,G2,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-
    MUSIC S,S,S,-

    MUSIC -,-,-,-

    MUSIC STOP
