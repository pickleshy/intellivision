' ============================================
' PROJECT_NAME - Intellivision Game
' Author: Mike Holzinger
' Date: 2026
' ============================================
' Built with IntyBASIC
' https://nanochess.org/intybasic.html
' ============================================

    ' --- Constants ---
    CONST SCREEN_WIDTH = 20
    CONST SCREEN_HEIGHT = 12
    
    CONST COLOR_BLACK = 0
    CONST COLOR_BLUE = 1
    CONST COLOR_RED = 2
    CONST COLOR_TAN = 3
    CONST COLOR_GREEN = 5
    CONST COLOR_YELLOW = 6
    CONST COLOR_WHITE = 7

    ' Sprite flags
    CONST VISIBLE = $0200
    CONST HIT = $0100

    ' --- Variables ---
    ' 8-bit: a-z
    ' 16-bit: #var
    
    DIM player_x(1)
    DIM player_y(1)
    
    #score = 0

    ' --- Initialize ---
init:
    WAIT
    CLS
    MODE 0, COLOR_BLUE, COLOR_BLUE, COLOR_BLUE, COLOR_BLUE
    
    player_x(0) = 80
    player_y(0) = 50
    
    GOSUB draw_title
    GOSUB wait_for_start

    ' --- Main Game Loop ---
main_loop:
    WAIT
    
    GOSUB read_input
    GOSUB update_game
    GOSUB draw_sprites
    
    GOTO main_loop

' ============================================
' SUBROUTINES
' ============================================

draw_title: PROCEDURE
    ' Draw title screen
    PRINT AT 50, "GAME TITLE"
    PRINT AT 130, "PRESS ANY KEY"
    RETURN
END

wait_for_start: PROCEDURE
wait_loop:
    WAIT
    IF CONT.button = 0 AND CONT.key = 12 THEN GOTO wait_loop
    CLS
    RETURN
END

read_input: PROCEDURE
    ' Read controller and update player position
    c = CONT
    
    ' Disc directions
    IF c AND $0004 THEN player_x(0) = player_x(0) + 1  ' East
    IF c AND $0400 THEN player_x(0) = player_x(0) - 1  ' West
    IF c AND $0001 THEN player_y(0) = player_y(0) - 1  ' North
    IF c AND $0100 THEN player_y(0) = player_y(0) + 1  ' South
    
    ' Clamp to screen bounds
    IF player_x(0) < 8 THEN player_x(0) = 8
    IF player_x(0) > 159 THEN player_x(0) = 159
    IF player_y(0) < 8 THEN player_y(0) = 8
    IF player_y(0) > 96 THEN player_y(0) = 96
    
    RETURN
END

update_game: PROCEDURE
    ' Game logic goes here
    RETURN
END

draw_sprites: PROCEDURE
    ' Draw player sprite
    SPRITE 0, player_x(0) + VISIBLE, player_y(0), 0 + COLOR_WHITE
    RETURN
END

' ============================================
' DATA SECTION
' ============================================

' Custom graphics would go here:
' gfx_player:
'     BITMAP "...XX..."
'     BITMAP "...XX..."
'     BITMAP ".XXXXXX."
'     BITMAP "XXXXXXXX"
'     BITMAP "X.XXXX.X"
'     BITMAP "..XXXX.."
'     BITMAP ".XX..XX."
'     BITMAP ".XX..XX."
