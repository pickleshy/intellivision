' ============================================
' SPACE INTRUDERS
' A Space Invaders clone for Intellivision
' ============================================
' This file orchestrates the game by including all subsystem modules.

OPTION MAP 2    ' Enable 42K ROM

' === Constants & Configuration ===
INCLUDE "games/space-intruders/src/constants.bas"
INCLUDE "games/space-intruders/src/variables.bas"

' === External Libraries ===
INCLUDE "games/space-intruders/src/lib_init.bas"

' === Startup & Boot ===
INCLUDE "games/space-intruders/src/boot.bas"

' === Title Screen ===
INCLUDE "games/space-intruders/src/title_animation.bas"
INCLUDE "games/space-intruders/src/title.bas"

' === Shared Utilities ===
INCLUDE "games/space-intruders/src/utils.bas"

' === Core Gameplay ===
INCLUDE "games/space-intruders/src/game_init.bas"
INCLUDE "games/space-intruders/src/player.bas"
INCLUDE "games/space-intruders/src/aliens.bas"
INCLUDE "games/space-intruders/src/ctrltest_inline.bas"
INCLUDE "games/space-intruders/src/weapons.bas"
INCLUDE "games/space-intruders/src/powerups.bas"
INCLUDE "games/space-intruders/src/waves.bas"
INCLUDE "games/space-intruders/src/ai.bas"
INCLUDE "games/space-intruders/src/flight_engine.bas"

' === Game Loop (inline for performance) ===
INCLUDE "games/space-intruders/src/gameloop.bas"

' === Data Assets ===
INCLUDE "games/space-intruders/src/graphics.bas"
INCLUDE "games/space-intruders/src/qr_code.bas"
INCLUDE "games/space-intruders/src/music.bas"
INCLUDE "games/space-intruders/src/data_tables.bas"
