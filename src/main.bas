' ============================================
' Intellivoice Demo - Intellivision Game
' Author: Mike Holzinger
' Date: 2026
' ============================================
' Demonstrates Intellivoice speech synthesis
' ============================================

    ' Use 42K static memory map (compatible with JLP and modern PCBs)
    OPTION MAP 2

    ' --- Constants ---
    CONST COLOR_BLACK = 0
    CONST COLOR_BLUE = 1
    CONST COLOR_WHITE = 7
    CONST MAX_PAGE = 3

    ' --- Variables ---
    last_key = 12  ' 12 = no key pressed
    page = 0       ' Menu page

    ' --- Initialize ---
    WAIT
    CLS
    MODE 0, COLOR_BLUE, COLOR_BLUE, COLOR_BLUE, COLOR_BLUE

    ' Initialize Intellivoice
    VOICE INIT

    ' Initialize music player (SIMPLE uses 2 channels, leaves room for voice)
    PLAY SIMPLE

    ' Say intro phrase
    VOICE PLAY intro_phrase

    GOSUB draw_menu

    ' --- Main Game Loop ---
main_loop:
    WAIT

    k = CONT.key

    ' Only trigger on new key press (debounce)
    IF k = last_key THEN GOTO skip_input
    last_key = k

    ' Route to correct page handler
    IF page = 0 THEN GOTO page0_input
    IF page = 1 THEN GOTO page1_input
    IF page = 2 THEN GOTO page2_input
    IF page = 3 THEN GOTO page3_input
    GOTO skip_input

page0_input:
    ' Instruments A: Cello, Oboe, Bass, Timpani, Trombone, Piccolo
    IF k = 1 THEN GOSUB say_cello
    IF k = 2 THEN GOSUB say_oboe
    IF k = 3 THEN GOSUB say_bass
    IF k = 4 THEN GOSUB say_timpani
    IF k = 5 THEN GOSUB say_trombone
    IF k = 6 THEN GOSUB say_piccolo
    IF k = 0 THEN GOSUB next_page
    GOTO skip_input

page1_input:
    ' Instruments B + Actions: Trumpet, Viola, Tuba, Sneeze
    IF k = 1 THEN GOSUB say_trumpet
    IF k = 2 THEN GOSUB say_viola
    IF k = 3 THEN GOSUB say_tuba
    IF k = 4 THEN GOSUB say_sneeze
    IF k = 0 THEN GOSUB next_page
    GOTO skip_input

page2_input:
    ' Special sounds
    IF k = 1 THEN GOSUB say_bravo
    IF k = 2 THEN GOSUB say_encore
    IF k = 3 THEN GOSUB count_words
    IF k = 4 THEN GOSUB pencil_drop
    IF k = 5 THEN GOSUB orchestra_tune
    IF k = 6 THEN GOSUB say_shaya
    IF k = 0 THEN GOSUB next_page
    GOTO skip_input

page3_input:
    ' Test sounds (original)
    IF k = 1 THEN GOSUB say_hello
    IF k = 2 THEN GOSUB say_ready
    IF k = 3 THEN GOSUB count_up
    IF k = 4 THEN GOSUB say_go
    IF k = 5 THEN GOSUB say_coins
    IF k = 0 THEN GOSUB next_page
    GOTO skip_input

skip_input:
    GOTO main_loop

' ============================================
' SUBROUTINES
' ============================================

draw_menu: PROCEDURE
    CLS
    PRINT AT 6, "ORCHESTRA!"
    IF page = 0 THEN GOTO draw_page0
    IF page = 1 THEN GOTO draw_page1
    IF page = 2 THEN GOTO draw_page2
    IF page = 3 THEN GOTO draw_page3
    GOTO draw_done
draw_page0:
    PRINT AT 40, "--- INSTRUMENTS A ---"
    PRINT AT 60, "1: CELLO"
    PRINT AT 80, "2: OBOE"
    PRINT AT 100, "3: BASS"
    PRINT AT 120, "4: TIMPANI"
    PRINT AT 140, "5: TROMBONE"
    PRINT AT 160, "6: PICCOLO"
    PRINT AT 200, "0: MORE >"
    GOTO draw_done
draw_page1:
    PRINT AT 40, "--- INSTRUMENTS B ---"
    PRINT AT 60, "1: TRUMPET"
    PRINT AT 80, "2: VIOLA"
    PRINT AT 100, "3: TUBA"
    PRINT AT 120, "4: SNEEZE"
    PRINT AT 200, "0: MORE >"
    GOTO draw_done
draw_page2:
    PRINT AT 40, "--- SPECIAL ---"
    PRINT AT 60, "1: BRAVO"
    PRINT AT 80, "2: ENCORE"
    PRINT AT 100, "3: COUNT WORDS"
    PRINT AT 120, "4: PENCIL DROP"
    PRINT AT 140, "5: ORCH TUNING"
    PRINT AT 160, "6: VOICE VIS"
    PRINT AT 200, "0: MORE >"
    GOTO draw_done
draw_page3:
    PRINT AT 40, "--- TEST SOUNDS ---"
    PRINT AT 60, "1: HELLO"
    PRINT AT 80, "2: READY"
    PRINT AT 100, "3: COUNT 1-5"
    PRINT AT 120, "4: GO"
    PRINT AT 140, "5: COINS"
    PRINT AT 200, "0: MORE >"
draw_done:
    RETURN
END

next_page: PROCEDURE
    page = page + 1
    IF page > MAX_PAGE THEN page = 0
    GOSUB draw_menu
    RETURN
END

' ============================================
' VOICE VISUALIZER (shared routine)
' ============================================
' Call with: vid = phrase_id (0-17), then GOSUB voice_viz
' This displays animated bars while voice plays

voice_viz: PROCEDURE
    CLS
    PRINT AT 6, "VOICE VISUALIZER"
    PRINT AT 40, "PHRASE:"

    ' Print phrase name based on vid
    IF vid = 0 THEN PRINT AT 60, "CELLO"
    IF vid = 1 THEN PRINT AT 60, "OBOE"
    IF vid = 2 THEN PRINT AT 60, "BASS"
    IF vid = 3 THEN PRINT AT 60, "TIMPANI"
    IF vid = 4 THEN PRINT AT 60, "TROMBONE"
    IF vid = 5 THEN PRINT AT 60, "PICCOLO"
    IF vid = 6 THEN PRINT AT 60, "TRUMPET"
    IF vid = 7 THEN PRINT AT 60, "VIOLA"
    IF vid = 8 THEN PRINT AT 60, "TUBA"
    IF vid = 9 THEN PRINT AT 60, "ACHOO!"
    IF vid = 10 THEN PRINT AT 60, "BRAVO"
    IF vid = 11 THEN PRINT AT 60, "ENCORE"
    IF vid = 12 THEN PRINT AT 60, "PENCIL DROP"
    IF vid = 13 THEN PRINT AT 60, "SHAYA'S GAME"
    IF vid = 14 THEN PRINT AT 60, "HELLO"
    IF vid = 15 THEN PRINT AT 60, "READY"
    IF vid = 16 THEN PRINT AT 60, "GO!"
    IF vid = 17 THEN PRINT AT 60, "COINS DETECTED"

    PRINT AT 100, "INTELLIVOICE OUTPUT:"
    PRINT AT 220, "BTN=EXIT"

    ' Wait for controller release (debounce)
    WHILE CONT.BUTTON
        WAIT
    WEND

    ' Start the voice based on vid
    ON vid GOSUB vp0,vp1,vp2,vp3,vp4,vp5,vp6,vp7,vp8,vp9,vp10,vp11,vp12,vp13,vp14,vp15,vp16,vp17
    tick = 0

    ' Animate while voice is playing
    WHILE VOICE.PLAYING
        WAIT

        ' Check for early exit
        IF CONT.BUTTON THEN
            VOICE INIT
            EXIT WHILE
        END IF

        tick = tick + 1

        ' Animated bars
        r = (tick + RAND) AND 7
        IF r < 2 THEN
            PRINT AT 122, "_"
        ELSEIF r < 4 THEN
            PRINT AT 122, "="
        ELSEIF r < 6 THEN
            PRINT AT 122, "#"
        ELSE
            PRINT AT 122, "@"
        END IF

        r = (tick + RAND + 3) AND 7
        IF r < 2 THEN
            PRINT AT 124, "_"
        ELSEIF r < 4 THEN
            PRINT AT 124, "="
        ELSEIF r < 6 THEN
            PRINT AT 124, "#"
        ELSE
            PRINT AT 124, "@"
        END IF

        r = (tick + RAND + 5) AND 7
        IF r < 2 THEN
            PRINT AT 126, "_"
        ELSEIF r < 4 THEN
            PRINT AT 126, "="
        ELSEIF r < 6 THEN
            PRINT AT 126, "#"
        ELSE
            PRINT AT 126, "@"
        END IF

        r = (tick + RAND + 2) AND 7
        IF r < 2 THEN
            PRINT AT 128, "_"
        ELSEIF r < 4 THEN
            PRINT AT 128, "="
        ELSEIF r < 6 THEN
            PRINT AT 128, "#"
        ELSE
            PRINT AT 128, "@"
        END IF

        r = (tick + RAND + 7) AND 7
        IF r < 2 THEN
            PRINT AT 130, "_"
        ELSEIF r < 4 THEN
            PRINT AT 130, "="
        ELSEIF r < 6 THEN
            PRINT AT 130, "#"
        ELSE
            PRINT AT 130, "@"
        END IF

        r = (tick + RAND + 1) AND 7
        IF r < 2 THEN
            PRINT AT 132, "_"
        ELSEIF r < 4 THEN
            PRINT AT 132, "="
        ELSEIF r < 6 THEN
            PRINT AT 132, "#"
        ELSE
            PRINT AT 132, "@"
        END IF

        ' Blinking SPEAKING indicator
        IF (tick AND 4) THEN
            PRINT AT 160, "** SPEAKING **"
        ELSE
            PRINT AT 160, "              "
        END IF

        PRINT AT 200, "FRAME: "
        PRINT AT 207, <3>tick
    WEND

    PRINT AT 122, "          "
    PRINT AT 160, "--- DONE ---  "
    FOR j = 1 TO 60: WAIT: NEXT j

    GOSUB draw_menu
    RETURN
END

' Voice play helpers (called via ON GOSUB)
vp0: PROCEDURE
    VOICE PLAY cello_phrase
    RETURN
END

vp1: PROCEDURE
    VOICE PLAY oboe_phrase
    RETURN
END

vp2: PROCEDURE
    VOICE PLAY bass_phrase
    RETURN
END

vp3: PROCEDURE
    VOICE PLAY timpani_phrase
    RETURN
END

vp4: PROCEDURE
    VOICE PLAY trombone_phrase
    RETURN
END

vp5: PROCEDURE
    VOICE PLAY piccolo_phrase
    RETURN
END

vp6: PROCEDURE
    VOICE PLAY trumpet_phrase
    RETURN
END

vp7: PROCEDURE
    VOICE PLAY viola_phrase
    RETURN
END

vp8: PROCEDURE
    VOICE PLAY tuba_phrase
    RETURN
END

vp9: PROCEDURE
    VOICE PLAY sneeze_phrase
    RETURN
END

vp10: PROCEDURE
    VOICE PLAY bravo_phrase
    RETURN
END

vp11: PROCEDURE
    VOICE PLAY encore_phrase
    RETURN
END

vp12: PROCEDURE
    VOICE PLAY pencil_phrase
    RETURN
END

vp13: PROCEDURE
    VOICE PLAY shaya_phrase
    RETURN
END

vp14: PROCEDURE
    VOICE PLAY hello_phrase
    RETURN
END

vp15: PROCEDURE
    VOICE PLAY ready_phrase
    RETURN
END

vp16: PROCEDURE
    VOICE PLAY go_phrase
    RETURN
END

vp17: PROCEDURE
    VOICE PLAY coins_phrase
    RETURN
END

' --- Instrument Procedures (now use visualizer) ---
say_cello: PROCEDURE
    vid = 0: GOSUB voice_viz
    RETURN
END

say_oboe: PROCEDURE
    vid = 1: GOSUB voice_viz
    RETURN
END

say_bass: PROCEDURE
    vid = 2: GOSUB voice_viz
    RETURN
END

say_timpani: PROCEDURE
    vid = 3: GOSUB voice_viz
    RETURN
END

say_trombone: PROCEDURE
    vid = 4: GOSUB voice_viz
    RETURN
END

say_piccolo: PROCEDURE
    vid = 5: GOSUB voice_viz
    RETURN
END

say_trumpet: PROCEDURE
    vid = 6: GOSUB voice_viz
    RETURN
END

say_viola: PROCEDURE
    vid = 7: GOSUB voice_viz
    RETURN
END

say_tuba: PROCEDURE
    vid = 8: GOSUB voice_viz
    RETURN
END

say_sneeze: PROCEDURE
    vid = 9: GOSUB voice_viz
    RETURN
END

' --- Special Procedures ---
say_bravo: PROCEDURE
    vid = 10: GOSUB voice_viz
    RETURN
END

say_encore: PROCEDURE
    vid = 11: GOSUB voice_viz
    RETURN
END

count_words: PROCEDURE
    ' Count 1-5 using built-in VOICE NUMBER with visualizer
    CLS
    PRINT AT 6, "VOICE VISUALIZER"
    PRINT AT 40, "PHRASE:"
    PRINT AT 60, "COUNT WORDS 1-5"
    PRINT AT 100, "INTELLIVOICE OUTPUT:"
    PRINT AT 220, "BTN=EXIT"

    WHILE CONT.BUTTON: WAIT: WEND

    tick = 0
    FOR i = 1 TO 5
        VOICE NUMBER i
        FOR j = 1 TO 30
            WAIT
            IF CONT.BUTTON THEN
                VOICE INIT
                GOTO cw_done
            END IF
            tick = tick + 1
            r = (tick + RAND) AND 7
            IF r < 4 THEN
                PRINT AT 122, "==#=="
            ELSE
                PRINT AT 122, "@@@@@"
            END IF
            IF (tick AND 4) THEN
                PRINT AT 160, "** SPEAKING **"
            ELSE
                PRINT AT 160, "              "
            END IF
        NEXT j
    NEXT i
cw_done:
    PRINT AT 122, "          "
    PRINT AT 160, "--- DONE ---  "
    FOR j = 1 TO 60: WAIT: NEXT j
    GOSUB draw_menu
    RETURN
END

pencil_drop: PROCEDURE
    vid = 12: GOSUB voice_viz
    RETURN
END

orchestra_tune: PROCEDURE
    ' Play the A440 tuning music from MIDI
    CLS
    PRINT AT 6, "ORCH TUNING"

    ' Show instruments used in this piece
    PRINT AT 60, "INSTRUMENTS:"
    PRINT AT 80, "Y=FLUTE X=CLARINET"
    PRINT AT 100, "Z=BASS"

    ' Channel labels
    PRINT AT 140, "CH1   CH2   CH3"

    ' Wait for controller release (debounce)
    WHILE CONT.BUTTON
        WAIT
    WEND

    ' Start playback
    PLAY intellivision_orchestra_tuning
    tick = 0

    ' Show hint for early exit
    PRINT AT 220, "BTN=EXIT"

    ' Wait for music to finish with visual feedback
    WHILE MUSIC.PLAYING
        WAIT

        ' Check for early exit (any button or disc)
        IF CONT.BUTTON THEN
            PLAY OFF
            EXIT WHILE
        END IF

        ' Animate channel indicators based on frame
        ' Use tick counter to create pulsing effect
        tick = tick + 1

        ' Channel 1 indicator (position 160)
        IF (tick AND 7) < 4 THEN
            PRINT AT 160, "###"
        ELSE
            PRINT AT 160, "---"
        END IF

        ' Channel 2 indicator (position 166)
        IF ((tick + 2) AND 7) < 4 THEN
            PRINT AT 166, "###"
        ELSE
            PRINT AT 166, "---"
        END IF

        ' Channel 3 indicator (position 172)
        IF ((tick + 4) AND 7) < 4 THEN
            PRINT AT 172, "###"
        ELSE
            PRINT AT 172, "---"
        END IF

        ' Show tick counter for debug
        PRINT AT 200, "TICK: "
        PRINT AT 206, <3>tick
    WEND

    ' Show completion
    PRINT AT 160, "--- DONE ---"
    FOR j = 1 TO 60: WAIT: NEXT j

    ' Redraw menu
    GOSUB draw_menu
    RETURN
END

' Move remaining procedures to Segment 1 to save space
    SEGMENT 1

say_shaya: PROCEDURE
    vid = 13: GOSUB voice_viz
    RETURN
END

' --- Test Sound Procedures ---
say_hello: PROCEDURE
    vid = 14: GOSUB voice_viz
    RETURN
END

say_ready: PROCEDURE
    vid = 15: GOSUB voice_viz
    RETURN
END

count_up: PROCEDURE
    ' Special: uses VOICE NUMBER, so has its own visualizer
    CLS
    PRINT AT 6, "VOICE VISUALIZER"
    PRINT AT 40, "PHRASE:"
    PRINT AT 60, "COUNTING 1-5"
    PRINT AT 100, "INTELLIVOICE OUTPUT:"
    PRINT AT 220, "BTN=EXIT"

    WHILE CONT.BUTTON: WAIT: WEND

    tick = 0
    FOR i = 1 TO 5
        VOICE NUMBER i
        FOR j = 1 TO 30
            WAIT
            IF CONT.BUTTON THEN
                VOICE INIT
                GOTO count_done
            END IF
            tick = tick + 1
            r = (tick + RAND) AND 7
            IF r < 4 THEN
                PRINT AT 122, "==#=="
            ELSE
                PRINT AT 122, "@@@@@"
            END IF
            IF (tick AND 4) THEN
                PRINT AT 160, "** SPEAKING **"
            ELSE
                PRINT AT 160, "              "
            END IF
        NEXT j
    NEXT i
count_done:
    PRINT AT 122, "          "
    PRINT AT 160, "--- DONE ---  "
    FOR j = 1 TO 60: WAIT: NEXT j
    GOSUB draw_menu
    RETURN
END

say_go: PROCEDURE
    vid = 16: GOSUB voice_viz
    RETURN
END

say_coins: PROCEDURE
    vid = 17: GOSUB voice_viz
    RETURN
END

' ============================================
' VOICE DATA SECTION
' ============================================
' Phonemes: PA1-PA5, OY, AY, EH, KK1-KK3, PP, JH,
' NN1-NN2, IH, TT1-TT2, RR1-RR2, AX, MM, DH1-DH2, IY, EY,
' DD1-DD2, UW1-UW2, AO, AA, YY1-YY2, AE, HH1-HH2, BB1-BB2,
' TH, UH, AW, GG1-GG3, VV, SH, ZH, FF, ZZ, NG, LL, WW,
' XR, WH, CH, ER1-ER2, OW, SS, OR, AR, YR, EL

intro_phrase:
    VOICE HH1,EH,LL,AO,PA2,0

' --- INSTRUMENT PHRASES ---
cello_phrase:
    ' "Cello" - CHEL-oh
    VOICE CH,EH,LL,PA1,OW,PA2,0

oboe_phrase:
    ' "Oboe" - OH-boh
    VOICE OW,PA1,BB1,OW,PA2,0

bass_phrase:
    ' "Bass" - BAYSS
    VOICE BB1,EY,SS,PA2,0

timpani_phrase:
    ' "Timpani" - TIM-puh-nee
    VOICE TT1,IH,MM,PA1
    VOICE PP,UH,NN1,IY,PA2,0

trombone_phrase:
    ' "Trombone" - TRAHM-bohn
    VOICE TT1,RR1,AO,MM,PA1
    VOICE BB1,OW,NN1,PA2,0

piccolo_phrase:
    ' "Piccolo" - PIK-uh-loh
    VOICE PP,IH,KK1,PA1
    VOICE UH,LL,OW,PA2,0

trumpet_phrase:
    ' "Trumpet" - TRUM-pit
    VOICE TT1,RR1,AX,MM,PA1
    VOICE PP,IH,TT1,PA2,0

viola_phrase:
    ' "Viola" - vee-OH-luh
    VOICE VV,IY,PA1
    VOICE OW,LL,UH,PA2,0

tuba_phrase:
    ' "Tuba" - TOO-buh
    VOICE TT1,UW1,PA1
    VOICE BB1,UH,PA2,0

sneeze_phrase:
    ' "Achoo!" - AH...CHOO
    VOICE AA,PA1,PA1
    VOICE CH,UW1,PA2,0

' --- SPECIAL PHRASES ---
bravo_phrase:
    ' "Bravo" - BRAH-VOH
    VOICE BB1,RR1,AA,PA1
    VOICE VV,OW,PA2,0

encore_phrase:
    ' "Encore" - AHN-KOR
    VOICE AO,NN1,PA1
    VOICE KK1,AO,RR1,PA2,0

pencil_phrase:
    ' Pencil drop sound effect
    VOICE PP,PA1,TT1,PA1,TT2,PA1,TT1,PA2,0

shaya_phrase:
    ' "Shaya's Game Test" - SHY-uh's GAYM TEST
    VOICE SH,AY,PA1,UH,ZZ,PA2
    VOICE GG1,EY,MM,PA2
    VOICE TT1,EH,SS,TT1,PA2,0

' --- TEST PHRASES ---
hello_phrase:
    VOICE HH1,EH,LL,AO,PA1,0

ready_phrase:
    VOICE RR1,EH,DD1,IY,PA1,0

go_phrase:
    VOICE GG1,AO,PA1,0

coins_phrase:
    ' "Coins detected"
    VOICE KK1,OY,NN1,SS,PA1,PA1
    VOICE DD2,IH,TT1,EH,KK1,TT1,EH,DD1,PA1,PA2
    VOICE IH,NN1,PA1,PA1
    VOICE PP,AO,KK2,EH,TT1,PA1,PA2,0

' ============================================
' MUSIC DATA SECTION (from MIDI conversion)
' ============================================
INCLUDE "assets/tuning_music.bas"

