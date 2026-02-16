' ============================================
' SPACE INTRUDERS - Library Initialization Module
' ============================================
' Initialize external libraries (ZMUS engine, Intellivoice, PLAY system)
' Segment: 0 (must be in main segment for library initialization)

    SEGMENT 0

' === Library Includes ===
' Note: ZMUS engine and compact_score are currently embedded inline
' Future: INCLUDE "lib/zmus_engine.bas"
' Future: INCLUDE "lib/compact_score.bas"

' === Intellivoice Initialization ===
    IF VOICE.AVAILABLE THEN VOICE INIT

    ' Boot splash: show developer URL for ~1 second
    GOSUB BootSplash

' === Note: PLAY SIMPLE/FULL initialized at gameplay start ===
' (See title.bas for PLAY FULL, StartGame for PLAY SIMPLE)
