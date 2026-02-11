REM Module:			BString.bas
REM
REM Description:	An example of creating and using packed ASCII strings.
REM Author(s):		Mark Ball
REM Date:			24/03/16
REM Version:		1.01F
REM
REM HISTORY
REM -------
REM 1.00F 24/03/16 - First release.
REM 1.01F 24/03/16 - Fixed a comment delimiter bug.
REM -------------------------------------------------------------------------

	' We need some important constants.
    include "constants.bas"

REM -------------------------------------------------------------------------
REM BSTRING - Compact an ASCII string into DECLES.
REM -------------------------------------------------------------------------
REM This assembly language macro is used to pack 2 ASCII bytes into
REM each DECLE of memory. A NULL terminator is automatically appended (if
REM required).
REM -------------------------------------------------------------------------
    asm MACRO BSTRING(aString)
    asm @@__length: QSET STRLEN(%aString%)/2
    asm @@__null_included: QSET STRLEN(%aString%) AND 1
    asm @@__index: QSET 0

    asm ; Handle the body of the string.
    asm ; Compact the ASCII string into 2 characters per DECLE in
    asm ; a byte order that is legible in a *.rom.
    asm REPEAT @@__length
    asm     DECLE (ASC(%aString%,@@__index)*256)+ASC(%aString%,@@__index+1)
    asm     @@__index: QSET @@__index+2
    asm ENDR

    asm ; Handle the tail end of the string.
    asm ; Rules:
    asm ; 1) If its an even length it needs a NULL terminator added.
    asm ; 2) If its an odd length the NULL terminator is packed into
    asm ;    the last character.
    asm IF @@__null_included =0
    asm     DECLE 0
    asm ELSE
    asm     DECLE ASC(%aString%,@@__index)*256
    asm ENDI

    asm ENDM
REM -------------------------------------------------------------------------
REM BSTRING - END
REM -------------------------------------------------------------------------

REM -------------------------------------------------------------------------
REM Initialisation.
REM -------------------------------------------------------------------------
    ' Display some packed strings.
    call BPRINTAT(varptr msg1(0))
    call BPRINTAT(varptr msg2(0))

REM -------------------------------------------------------------------------
REM Main loop
REM -------------------------------------------------------------------------	
loop:
    wait
    goto loop

REM -------------------------------------------------------------------------
REM Message to print on screen.
REM -------------------------------------------------------------------------
REM 1st element - The destination on screen (must use constants).
REM 2nd element - The colour of the text (with GRAM flag set).
REM 3rd element - The string to print (wrapped in the BSTRING MACRO).
REM -------------------------------------------------------------------------
msg1:
    data SCREENADDR(0,0), CS_WHITE
    asm BSTRING("Packed strings!")
msg2:
    data SCREENADDR(0,1), CS_BLUE
    asm BSTRING("HELLO WORLD!")

REM -------------------------------------------------------------------------
REM BPRINTAT - Display a byte packed string.
REM -------------------------------------------------------------------------
REM
REM Usage:
REM CALL BPRINTAT(A)
REM
REM Input:
REM		A - VARPTR of a message data structure. Where :-
REM         1st data element is the destination address in RAM.
REM 		2nd data element is the text/background colour+GRAM.
REM         3rd-Nth data element is the string in upper case with limited punctuation.
REM
REM Returns:
REM Nothing!
REM
REM Trashes:
REM r0-r1, r3-r5
REM
REM -------------------------------------------------------------------------
    asm BPRINTAT: PROC
    asm pshr r5

    asm movr r0, r5     ; Get the argument pointer.
    asm mvi@ r5, r4     ; Get the destination on screen.
    asm mvi@ r5, r3     ; Get the text message's final colour.

    asm ; Print the characters until a NULL terminator is found.
    asm @@L1:
    asm mvi@ r5, r1     ; Get a packed character DECLE.
    asm movr r1, r0     ; MSB is the first to be displayed...
    asm swap r0, 1      ; So swap it over, to make it easier to use.

    asm ; Process 1st character.
    asm andi #$FF, r0   ; Junk the MSB to get what we are interested in.
    asm beq @@AllDone   ; If its a NULL terminator then we are done.
    asm subi #' ', r0   ; Convert to an Inty GROM index.
    asm sll r0, 2
    asm sll r0, 1       ; x8
    asm xorr r3, r0     ; Mix in the colour.
    asm mvo@ r0, r4     ; Put it on the screen.

    asm ; Process 2nd character.
    asm andi #$FF, r1   ; Junk the MSB to get what we are interested in.
    asm beq @@AllDone   ; If its a NULL terminator then we are done.
    asm subi #' ', r1   ; Convert to an Inty GROM index.
    asm sll r1, 2
    asm sll r1, 1       ; x8
    asm xorr r3, r1     ; Mix in the colour.
    asm mvo@ r1, r4     ; Put it on the screen.

    asm ; Handle some more of the string.
    asm b @@L1

    asm ; All done!
    asm @@AllDone: 
	asm mvo r4, _screen ; Keep IntyBASIC print position tracker up to date.
    asm pulr pc

    asm ENDP
REM -------------------------------------------------------------------------
REM BPRINTAT - END
REM -------------------------------------------------------------------------
