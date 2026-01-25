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
    ' Sneeze page: Normal, Big, Tiny, Triple, Stifled, Cartoon
    IF k = 1 THEN GOSUB sneeze_normal
    IF k = 2 THEN GOSUB sneeze_big
    IF k = 3 THEN GOSUB sneeze_tiny
    IF k = 4 THEN GOSUB sneeze_triple
    IF k = 5 THEN GOSUB sneeze_stifled
    IF k = 6 THEN GOSUB sneeze_cartoon
    IF k = 0 THEN GOSUB next_page
    GOTO skip_input

page2_input:
    ' Special sounds
    IF k = 1 THEN GOSUB say_bravo
    IF k = 2 THEN GOSUB say_encore
    IF k = 3 THEN GOSUB count_words
    IF k = 4 THEN GOSUB pencil_drop
    IF k = 5 THEN GOSUB orchestra_tune
    IF k = 0 THEN GOSUB next_page
    GOTO skip_input

page3_input:
    ' Music player page
    IF k = 1 THEN GOSUB play_greensleeves
    IF k = 2 THEN GOSUB play_canon
    IF k = 3 THEN GOSUB play_tuning
    IF k = 4 THEN GOSUB play_nutcracker
    IF k = 5 THEN GOSUB stop_music
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
    PRINT AT 40, "--- SNEEZES ---"
    PRINT AT 60, "1: NORMAL"
    PRINT AT 80, "2: BIG DRAMATIC"
    PRINT AT 100, "3: TINY"
    PRINT AT 120, "4: TRIPLE"
    PRINT AT 140, "5: STIFLED"
    PRINT AT 160, "6: CARTOON"
    PRINT AT 200, "0: MORE >"
    GOTO draw_done
draw_page2:
    PRINT AT 40, "--- SPECIAL ---"
    PRINT AT 60, "1: BRAVO"
    PRINT AT 80, "2: ENCORE"
    PRINT AT 100, "3: COUNT WORDS"
    PRINT AT 120, "4: PENCIL DROP"
    PRINT AT 140, "5: ORCH TUNING"
    PRINT AT 200, "0: MORE >"
    GOTO draw_done
draw_page3:
    PRINT AT 40, "--- MUSIC ---"
    PRINT AT 60, "1: GREENSLEEVES"
    PRINT AT 80, "2: CANON IN D"
    PRINT AT 100, "3: ORCH TUNING"
    PRINT AT 120, "4: NUTCRACKER"
    PRINT AT 140, "5: STOP MUSIC"
    PRINT AT 180, "(music plays in bg)"
    PRINT AT 200, "0: MORE >"
    GOTO draw_done
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

    ' Print phrase name and phoneme breakdown based on vid
    IF vid = 0 THEN
        PRINT AT 60, "CELLO"
        PRINT AT 80, "CH-EH-LL-OW"
    END IF
    IF vid = 1 THEN
        PRINT AT 60, "OBOE"
        PRINT AT 80, "OW-BB1-OW"
    END IF
    IF vid = 2 THEN
        PRINT AT 60, "BASS"
        PRINT AT 80, "BB1-EY-SS"
    END IF
    IF vid = 3 THEN
        PRINT AT 60, "TIMPANI"
        PRINT AT 80, "TT1-IH-MM-PP-UH-NN1-IY"
    END IF
    IF vid = 4 THEN
        PRINT AT 60, "TROMBONE"
        PRINT AT 80, "TT1-RR1-AO-MM-BB1-OW-NN1"
    END IF
    IF vid = 5 THEN
        PRINT AT 60, "PICCOLO"
        PRINT AT 80, "PP-IH-KK1-UH-LL-OW"
    END IF
    IF vid = 6 THEN
        PRINT AT 60, "TRUMPET"
        PRINT AT 80, "TT1-RR1-AX-MM-PP-IH-TT1"
    END IF
    IF vid = 7 THEN
        PRINT AT 60, "VIOLA"
        PRINT AT 80, "VV-IY-OW-LL-UH"
    END IF
    IF vid = 8 THEN
        PRINT AT 60, "TUBA"
        PRINT AT 80, "TT1-UW1-BB1-UH"
    END IF
    IF vid = 9 THEN
        PRINT AT 60, "ACHOO!"
        PRINT AT 80, "AA-CH-UW1"
    END IF
    IF vid = 10 THEN
        PRINT AT 60, "BRAVO"
        PRINT AT 80, "BB1-RR1-AA-VV-OW"
    END IF
    IF vid = 11 THEN
        PRINT AT 60, "ENCORE"
        PRINT AT 80, "AO-NN1-KK1-AO-RR1"
    END IF
    IF vid = 12 THEN
        PRINT AT 60, "PENCIL DROP"
        PRINT AT 80, "PP-TT1-TT2-TT1 (SFX)"
    END IF

    PRINT AT 120, "INTELLIVOICE OUTPUT:"
    PRINT AT 220, "BTN=EXIT"

    ' Wait for controller release (debounce)
    WHILE CONT.BUTTON
        WAIT
    WEND

    ' Start the voice based on vid
    ON vid GOSUB vp0,vp1,vp2,vp3,vp4,vp5,vp6,vp7,vp8,vp9,vp10,vp11,vp12
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
            PRINT AT 142, "_"
        ELSEIF r < 4 THEN
            PRINT AT 142, "="
        ELSEIF r < 6 THEN
            PRINT AT 142, "#"
        ELSE
            PRINT AT 142, "@"
        END IF

        r = (tick + RAND + 3) AND 7
        IF r < 2 THEN
            PRINT AT 144, "_"
        ELSEIF r < 4 THEN
            PRINT AT 144, "="
        ELSEIF r < 6 THEN
            PRINT AT 144, "#"
        ELSE
            PRINT AT 144, "@"
        END IF

        r = (tick + RAND + 5) AND 7
        IF r < 2 THEN
            PRINT AT 146, "_"
        ELSEIF r < 4 THEN
            PRINT AT 146, "="
        ELSEIF r < 6 THEN
            PRINT AT 146, "#"
        ELSE
            PRINT AT 146, "@"
        END IF

        r = (tick + RAND + 2) AND 7
        IF r < 2 THEN
            PRINT AT 148, "_"
        ELSEIF r < 4 THEN
            PRINT AT 148, "="
        ELSEIF r < 6 THEN
            PRINT AT 148, "#"
        ELSE
            PRINT AT 148, "@"
        END IF

        r = (tick + RAND + 7) AND 7
        IF r < 2 THEN
            PRINT AT 150, "_"
        ELSEIF r < 4 THEN
            PRINT AT 150, "="
        ELSEIF r < 6 THEN
            PRINT AT 150, "#"
        ELSE
            PRINT AT 150, "@"
        END IF

        r = (tick + RAND + 1) AND 7
        IF r < 2 THEN
            PRINT AT 152, "_"
        ELSEIF r < 4 THEN
            PRINT AT 152, "="
        ELSEIF r < 6 THEN
            PRINT AT 152, "#"
        ELSE
            PRINT AT 152, "@"
        END IF

        ' Blinking SPEAKING indicator
        IF (tick AND 4) THEN
            PRINT AT 180, "** SPEAKING **"
        ELSE
            PRINT AT 180, "              "
        END IF

        PRINT AT 200, "FRAME: "
        PRINT AT 207, <3>tick
    WEND

    PRINT AT 142, "          "
    PRINT AT 180, "--- DONE ---  "
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

' Move sneeze procedures to Segment 1 to avoid overflow
    SEGMENT 1

sneeze_normal: PROCEDURE
    ' PSG-based sneeze effect: "Ahh...CHOO!"
    CLS
    PRINT AT 6, "NORMAL SNEEZE"
    PRINT AT 60, "Ahh...CHOO!"
    PRINT AT 220, "BTN=EXIT"

    WHILE CONT.BUTTON: WAIT: WEND

    ' Phase 1: Build-up "Ahhh..." - rising tone with slight warble
    PRINT AT 100, "  Ahhh...  "
    FOR i = 0 TO 20
        freq = 300 - (i * 5)
        vol = 8 + (i / 4)
        SOUND 0, freq, vol
        SOUND 1, freq + 3, vol - 2  ' Slight detuning for texture
        WAIT
        IF CONT.BUTTON THEN GOTO sn_done
    NEXT i

    ' Phase 2: Pause/inhale - quick silence
    SOUND 0, 0, 0
    SOUND 1, 0, 0
    PRINT AT 100, "           "
    FOR i = 1 TO 8: WAIT: NEXT i

    ' Phase 3: "CHOO!" - explosive noise burst
    PRINT AT 100, "  CHOO!!   "
    SOUND 4, 12, 7          ' Noise on all 3 channels
    SOUND 0, 120, 15        ' Low fundamental
    SOUND 1, 180, 12        ' Mid tone
    SOUND 2, 90, 10         ' Sub bass

    ' Rapid decay
    FOR i = 15 TO 0 STEP -1
        SOUND 0, 120, i
        SOUND 1, 180, (i * 3) / 4
        SOUND 2, 90, i / 2
        WAIT
        IF CONT.BUTTON THEN GOTO sn_done
    NEXT i

    ' Cleanup
sn_done:
    SOUND 0, 0, 0
    SOUND 1, 0, 0
    SOUND 2, 0, 0
    SOUND 4, 0, 0

    PRINT AT 100, " *sniff*   "
    FOR i = 1 TO 40: WAIT: NEXT i

    GOSUB draw_menu
    RETURN
END

sneeze_big: PROCEDURE
    ' BIG DRAMATIC sneeze - long build-up, massive explosion
    CLS
    PRINT AT 6, "BIG SNEEZE"
    PRINT AT 60, "AAAAHHHHH...CHOOO!!!"
    PRINT AT 220, "BTN=EXIT"

    WHILE CONT.BUTTON: WAIT: WEND

    ' Phase 1: Long dramatic build-up with crescendo
    PRINT AT 100, " AAAAAHHH.."
    FOR i = 0 TO 40
        freq = 400 - (i * 4)
        vol = 5 + (i / 5)
        IF vol > 14 THEN vol = 14
        SOUND 0, freq, vol
        SOUND 1, freq + 5, vol - 2
        SOUND 2, freq - 10, vol / 2  ' Deep undertone
        WAIT
        IF CONT.BUTTON THEN GOTO sb_done
    NEXT i

    ' Phase 2: Suspenseful pause
    SOUND 0, 0, 0
    SOUND 1, 0, 0
    SOUND 2, 0, 0
    PRINT AT 100, "           "
    FOR i = 1 TO 15: WAIT: NEXT i

    ' Phase 3: MASSIVE "CHOOOOO!!!" - all channels at max
    PRINT AT 100, "CHOOOOO!!!!"
    SOUND 4, 8, 7           ' Heavy noise
    SOUND 0, 80, 15         ' Deep bass
    SOUND 1, 150, 15        ' Mid tone
    SOUND 2, 60, 15         ' Sub rumble

    ' Long dramatic decay
    FOR i = 15 TO 0 STEP -1
        SOUND 0, 80, i
        SOUND 1, 150, i
        SOUND 2, 60, i
        WAIT: WAIT  ' Slow decay
        IF CONT.BUTTON THEN GOTO sb_done
    NEXT i

sb_done:
    SOUND 0, 0, 0
    SOUND 1, 0, 0
    SOUND 2, 0, 0
    SOUND 4, 0, 0

    PRINT AT 100, " *SNIFF*   "
    FOR i = 1 TO 50: WAIT: NEXT i

    GOSUB draw_menu
    RETURN
END

sneeze_tiny: PROCEDURE
    ' TINY sneeze - quick high-pitched little "achoo"
    CLS
    PRINT AT 6, "TINY SNEEZE"
    PRINT AT 60, "ah-choo!"
    PRINT AT 220, "BTN=EXIT"

    WHILE CONT.BUTTON: WAIT: WEND

    ' Phase 1: Quick little "ah" - high pitched
    PRINT AT 100, "   ah...   "
    FOR i = 0 TO 6
        freq = 600 - (i * 10)
        SOUND 0, freq, 8
        WAIT
        IF CONT.BUTTON THEN GOTO st_done
    NEXT i

    ' Phase 2: Tiny pause
    SOUND 0, 0, 0
    FOR i = 1 TO 3: WAIT: NEXT i

    ' Phase 3: Little "choo" - quick and light
    PRINT AT 100, "  choo!    "
    SOUND 4, 20, 3          ' Light noise
    SOUND 0, 400, 10        ' High tone

    ' Quick decay
    FOR i = 10 TO 0 STEP -2
        SOUND 0, 400, i
        WAIT
        IF CONT.BUTTON THEN GOTO st_done
    NEXT i

st_done:
    SOUND 0, 0, 0
    SOUND 4, 0, 0

    PRINT AT 100, " *snf*     "
    FOR i = 1 TO 30: WAIT: NEXT i

    GOSUB draw_menu
    RETURN
END

sneeze_triple: PROCEDURE
    ' TRIPLE sneeze - ah...ah...ah-CHOO!
    CLS
    PRINT AT 6, "TRIPLE SNEEZE"
    PRINT AT 60, "ah..ah..ah-CHOO!"
    PRINT AT 220, "BTN=EXIT"

    WHILE CONT.BUTTON: WAIT: WEND

    ' First "ah" - building
    PRINT AT 100, "   ah...   "
    FOR i = 0 TO 8
        SOUND 0, 350 - (i * 5), 8
        WAIT
        IF CONT.BUTTON THEN GOTO s3_done
    NEXT i
    SOUND 0, 0, 0
    FOR i = 1 TO 10: WAIT: NEXT i

    ' Second "ah" - stronger
    PRINT AT 100, "   AH...   "
    FOR i = 0 TO 10
        SOUND 0, 320 - (i * 5), 10
        SOUND 1, 325 - (i * 5), 6
        WAIT
        IF CONT.BUTTON THEN GOTO s3_done
    NEXT i
    SOUND 0, 0, 0
    SOUND 1, 0, 0
    FOR i = 1 TO 8: WAIT: NEXT i

    ' Third "AH" - building to climax
    PRINT AT 100, "   AAH..   "
    FOR i = 0 TO 15
        vol = 8 + (i / 3)
        SOUND 0, 280 - (i * 4), vol
        SOUND 1, 285 - (i * 4), vol - 3
        WAIT
        IF CONT.BUTTON THEN GOTO s3_done
    NEXT i

    ' Quick pause
    SOUND 0, 0, 0
    SOUND 1, 0, 0
    PRINT AT 100, "           "
    FOR i = 1 TO 5: WAIT: NEXT i

    ' Final big CHOO!
    PRINT AT 100, "  CHOO!!!  "
    SOUND 4, 10, 7
    SOUND 0, 100, 15
    SOUND 1, 160, 13
    SOUND 2, 80, 11

    ' Decay
    FOR i = 15 TO 0 STEP -1
        SOUND 0, 100, i
        SOUND 1, 160, (i * 3) / 4
        SOUND 2, 80, i / 2
        WAIT
        IF CONT.BUTTON THEN GOTO s3_done
    NEXT i

s3_done:
    SOUND 0, 0, 0
    SOUND 1, 0, 0
    SOUND 2, 0, 0
    SOUND 4, 0, 0

    PRINT AT 100, "*sniff snf*"
    FOR i = 1 TO 50: WAIT: NEXT i

    GOSUB draw_menu
    RETURN
END

sneeze_stifled: PROCEDURE
    ' STIFLED sneeze - suppressed, muffled
    CLS
    PRINT AT 6, "STIFLED SNEEZE"
    PRINT AT 60, "(trying not to sneeze)"
    PRINT AT 220, "BTN=EXIT"

    WHILE CONT.BUTTON: WAIT: WEND

    ' Phase 1: Struggling to hold it in
    PRINT AT 100, " nnngggh.. "
    FOR i = 0 TO 25
        freq = 200 + (RANDOM(30))
        vol = 5 + (i / 6)
        IF vol > 10 THEN vol = 10
        SOUND 0, freq, vol
        WAIT
        IF CONT.BUTTON THEN GOTO ss_done
    NEXT i

    ' Phase 2: The suppressed explosion
    PRINT AT 100, "  -mmpf!-  "
    SOUND 4, 25, 4          ' Muffled noise
    SOUND 0, 250, 8         ' Mid tone, not too loud
    SOUND 1, 180, 6

    ' Quick muffled decay
    FOR i = 8 TO 0 STEP -1
        SOUND 0, 250, i
        SOUND 1, 180, i - 2
        IF i > 5 THEN SOUND 4, 25, 3
        WAIT
        IF CONT.BUTTON THEN GOTO ss_done
    NEXT i

ss_done:
    SOUND 0, 0, 0
    SOUND 1, 0, 0
    SOUND 4, 0, 0

    PRINT AT 100, " *ow...*   "
    FOR i = 1 TO 40: WAIT: NEXT i

    GOSUB draw_menu
    RETURN
END

sneeze_cartoon: PROCEDURE
    ' CARTOON sneeze - over-the-top slide whistle style
    CLS
    PRINT AT 6, "CARTOON SNEEZE"
    PRINT AT 60, "WAAAAH-CHOOEY!"
    PRINT AT 220, "BTN=EXIT"

    WHILE CONT.BUTTON: WAIT: WEND

    ' Phase 1: Cartoon wind-up with rising pitch
    PRINT AT 100, " WAAAAAHH! "
    FOR i = 0 TO 30
        freq = 800 - (i * 15)  ' Slide down
        SOUND 0, freq, 12
        SOUND 1, freq / 2, 8   ' Harmony
        WAIT
        IF CONT.BUTTON THEN GOTO sc_done
    NEXT i

    ' Quick slide up before explosion
    FOR i = 0 TO 10
        freq = 350 + (i * 30)  ' Slide up!
        SOUND 0, freq, 14
        WAIT
        IF CONT.BUTTON THEN GOTO sc_done
    NEXT i

    ' Phase 2: Comical explosion with warble
    PRINT AT 100, " CHOOEY!!! "
    FOR i = 0 TO 20
        f = 100 + ((i AND 3) * 50)  ' Warbling
        SOUND 4, 8, 5
        SOUND 0, f, 15 - (i / 2)
        SOUND 1, f + 100, 12 - (i / 2)
        SOUND 2, 50, 10 - (i / 3)
        WAIT
        IF CONT.BUTTON THEN GOTO sc_done
    NEXT i

    ' Cartoon "boing" aftermath
    FOR i = 0 TO 10
        freq = 300 + (i * 40)  ' Rising boing
        SOUND 0, freq, 8 - (i / 2)
        WAIT
        IF CONT.BUTTON THEN GOTO sc_done
    NEXT i

sc_done:
    SOUND 0, 0, 0
    SOUND 1, 0, 0
    SOUND 2, 0, 0
    SOUND 4, 0, 0

    PRINT AT 100, " ~splat~   "
    FOR i = 1 TO 50: WAIT: NEXT i

    GOSUB draw_menu
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
    PRINT AT 80, "(built-in numbers)"
    PRINT AT 120, "INTELLIVOICE OUTPUT:"
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
                PRINT AT 142, "==#=="
            ELSE
                PRINT AT 142, "@@@@@"
            END IF
            IF (tick AND 4) THEN
                PRINT AT 180, "** SPEAKING **"
            ELSE
                PRINT AT 180, "              "
            END IF
        NEXT j
    NEXT i
cw_done:
    PRINT AT 142, "          "
    PRINT AT 180, "--- DONE ---  "
    FOR j = 1 TO 60: WAIT: NEXT j
    GOSUB draw_menu
    RETURN
END

pencil_drop: PROCEDURE
    vid = 12: GOSUB voice_viz
    RETURN
END

' --- Music Playback Procedures ---
play_greensleeves: PROCEDURE
    CLS
    PRINT AT 6, "NOW PLAYING"
    PRINT AT 60, "GREENSLEEVES"
    PRINT AT 80, "(Traditional)"
    PRINT AT 120, "Music plays in"
    PRINT AT 140, "background..."
    PRINT AT 200, "BTN=BACK"

    WHILE CONT.BUTTON: WAIT: WEND

    PLAY FULL
    PLAY Greensleeves

    ' Wait for button to return to menu
    WHILE CONT.BUTTON = 0
        WAIT
        ' Show playing indicator
        IF (FRAME AND 15) < 8 THEN
            PRINT AT 160, "   [PLAYING]   "
        ELSE
            PRINT AT 160, "               "
        END IF
    WEND

    GOSUB draw_menu
    RETURN
END

play_canon: PROCEDURE
    CLS
    PRINT AT 6, "NOW PLAYING"
    PRINT AT 60, "CANON IN D"
    PRINT AT 80, "(Pachelbel)"
    PRINT AT 120, "Music plays in"
    PRINT AT 140, "background..."
    PRINT AT 200, "BTN=BACK"

    WHILE CONT.BUTTON: WAIT: WEND

    PLAY FULL
    PLAY Canon_in_D

    ' Wait for button to return to menu
    WHILE CONT.BUTTON = 0
        WAIT
        IF (FRAME AND 15) < 8 THEN
            PRINT AT 160, "   [PLAYING]   "
        ELSE
            PRINT AT 160, "               "
        END IF
    WEND

    GOSUB draw_menu
    RETURN
END

play_tuning: PROCEDURE
    CLS
    PRINT AT 6, "NOW PLAYING"
    PRINT AT 60, "ORCH TUNING"
    PRINT AT 80, "(A440 + chords)"
    PRINT AT 120, "Music plays in"
    PRINT AT 140, "background..."
    PRINT AT 200, "BTN=BACK"

    WHILE CONT.BUTTON: WAIT: WEND

    PLAY FULL
    PLAY intellivision_orchestra_tuning

    WHILE CONT.BUTTON = 0
        WAIT
        IF (FRAME AND 15) < 8 THEN
            PRINT AT 160, "   [PLAYING]   "
        ELSE
            PRINT AT 160, "               "
        END IF
    WEND

    GOSUB draw_menu
    RETURN
END

stop_music: PROCEDURE
    PLAY OFF
    GOSUB draw_menu
    RETURN
END

' --- Nutcracker March (IntyBASIC MUSIC) ---
play_nutcracker: PROCEDURE
    CLS
    PRINT AT 6, "RAW SOUND TEST"
    PRINT AT 40, "Testing PSG"
    PRINT AT 60, "channels 0,1,2"
    PRINT AT 100, "v5 - PLAY OFF"
    PRINT AT 200, "BTN=BACK"

    WHILE CONT.BUTTON: WAIT: WEND

    ' === RAW SOUND TEST - bypasses MUSIC system ===
    ' First disable the music system completely
    PLAY OFF
    FOR i = 0 TO 10: WAIT: NEXT i

    ' Test channel 0 (A4 = 440Hz, period ~254)
    PRINT AT 140, "Channel 0..."
    SOUND 0, 254, 15  ' Channel 0, period 254, volume 15
    FOR i = 0 TO 60: WAIT: NEXT i
    SOUND 0, 0, 0     ' Silence
    FOR i = 0 TO 30: WAIT: NEXT i

    ' Test channel 1
    PRINT AT 140, "Channel 1..."
    SOUND 1, 254, 15  ' Channel 1, same note
    FOR i = 0 TO 60: WAIT: NEXT i
    SOUND 1, 0, 0     ' Silence
    FOR i = 0 TO 30: WAIT: NEXT i

    ' Test channel 2
    PRINT AT 140, "Channel 2..."
    SOUND 2, 254, 15  ' Channel 2, same note
    FOR i = 0 TO 60: WAIT: NEXT i
    SOUND 2, 0, 0     ' Silence
    FOR i = 0 TO 30: WAIT: NEXT i

    ' Test all 3 together (should be louder)
    PRINT AT 140, "All 3 chans!"
    SOUND 0, 254, 15
    SOUND 1, 254, 15
    SOUND 2, 254, 15
    FOR i = 0 TO 90: WAIT: NEXT i
    SOUND 0, 0, 0
    SOUND 1, 0, 0
    SOUND 2, 0, 0

    PRINT AT 140, "Test complete"

    ' Now play the actual music
    PLAY FULL
    PLAY NutcrackerMarch

    ' Wait for button or music to end
    WHILE CONT.BUTTON = 0
        WAIT
        ' Show playing indicator
        IF MUSIC.PLAYING THEN
            IF (FRAME AND 15) < 8 THEN
                PRINT AT 160, "   [PLAYING]   "
            ELSE
                PRINT AT 160, "               "
            END IF
        ELSE
            PRINT AT 160, "   [FINISHED]  "
        END IF
    WEND

    ' Stop the music when exiting
    PLAY OFF

    ' Return to SIMPLE mode for voice compatibility
    PLAY SIMPLE

    GOSUB draw_menu
    RETURN
END

' Move remaining procedures to Segment 1 to save space
    SEGMENT 1

orchestra_tune: PROCEDURE
    ' Play the A440 tuning music from MIDI
    CLS
    WAIT
    PRINT AT 6, "ORCH TUNING"

    ' Static labels - clear gaps too
    PRINT AT 60, "INSTRUMENTS:        "
    PRINT AT 80, "                    "
    PRINT AT 220, "BTN=EXIT"

    ' Initialize instrument display (all inactive/grey initially)
    PRINT AT 100 COLOR 8, "FLUTE    ---        "
    PRINT AT 120 COLOR 8, "CLARINET ---        "
    PRINT AT 140 COLOR 8, "BASS     ---        "

    ' Wait for controller release (debounce)
    WHILE CONT.BUTTON
        WAIT
    WEND

    ' Start playback
    PLAY intellivision_orchestra_tuning
    #tick = 0

    ' Wait for music to finish with visual feedback
    WHILE MUSIC.PLAYING
        WAIT
        #tick = #tick + 1

        ' Check for early exit (any button or disc)
        IF CONT.BUTTON THEN
            PLAY OFF
            EXIT WHILE
        END IF

        ' Reset all instruments to OFF each frame
        flute_on = 0
        clarinet_on = 0
        bass_on = 0

        ' Music timeline (33 ticks per note, 8 notes per section = 264 ticks):
        '   0-263:    Flute only
        '   264-527:  Flute + Clarinet
        '   528-791:  All three
        '   792-1055: All three (alternating)
        '   1056-1319: Flute + Clarinet (bass stops)
        '   1320-1583: All three, then silence

        ' Flute (Channel 1) - active until tick 1550
        IF #tick < 1550 THEN flute_on = 1

        ' Clarinet (Channel 2) - starts at 264
        IF #tick >= 264 THEN
            IF #tick < 1550 THEN clarinet_on = 1
        END IF

        ' Bass (Channel 3) - plays 528-1055, then 1320-1549
        IF #tick >= 528 THEN
            IF #tick < 1056 THEN bass_on = 1
        END IF
        IF #tick >= 1320 THEN
            IF #tick < 1550 THEN bass_on = 1
        END IF

        ' Clear display rows first (null out the area)
        PRINT AT 100, "                    "
        PRINT AT 120, "                    "
        PRINT AT 140, "                    "

        ' Set colors based on active state (6=yellow, 7=white)
        fc = 7: IF flute_on = 1 THEN fc = 6
        cc = 7: IF clarinet_on = 1 THEN cc = 6
        bc = 7: IF bass_on = 1 THEN bc = 6

        ' Print instrument names with color
        PRINT AT 100 COLOR fc, "FLUTE    ---"
        PRINT AT 120 COLOR cc, "CLARINET ---"
        PRINT AT 140 COLOR bc, "BASS     ---"

        ' Add pulsing ### for active instruments
        IF flute_on = 1 THEN
            IF (#tick AND 7) < 4 THEN PRINT AT 109 COLOR 6, "###"
        END IF
        IF clarinet_on = 1 THEN
            IF ((#tick + 2) AND 7) < 4 THEN PRINT AT 129 COLOR 6, "###"
        END IF
        IF bass_on = 1 THEN
            IF ((#tick + 4) AND 7) < 4 THEN PRINT AT 149 COLOR 6, "###"
        END IF

        ' Show tick counter for debug (row 10)
        PRINT AT 200 COLOR 7, "TICK: "
        PRINT AT 206, <4>#tick
    WEND

    ' Show completion
    PRINT AT 120 COLOR 7, "--- DONE ---    "
    FOR j = 1 TO 60: WAIT: NEXT j

    ' Redraw menu
    GOSUB draw_menu
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

' ============================================
' MUSIC DATA SECTION (from MIDI conversion)
' Move to Segment 2 for more space
' ============================================
    SEGMENT 2

INCLUDE "assets/music/tuning_music.bas"
INCLUDE "assets/music/greensleeves_music.bas"
INCLUDE "assets/music/canon_music.bas"

' ============================================
' NUTCRACKER MARCH - IntyBASIC MUSIC FORMAT
' Simplified 3-channel arrangement
' ============================================
INCLUDE "assets/music/nutcracker_intybasic.bas"

