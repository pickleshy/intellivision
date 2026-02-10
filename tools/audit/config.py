"""Configuration constants for the IntyBASIC audit toolkit."""

import glob
import os

# Project root: tools/audit/../../ = project root
_TOOL_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.normpath(os.path.join(_TOOL_DIR, '..', '..'))
GAMES_DIR = os.path.join(PROJECT_ROOT, 'games')

# Duplicate code detection
MIN_DUPLICATE_LINES = 3
MIN_DUPLICATE_COUNT = 2

# ELSEIF chain detection
MAX_ELSEIF_CHAIN = 8

# ROM budget thresholds (percent)
ROM_WARN_PERCENT = 85
ROM_ERROR_PERCENT = 95

# Variable limits (IntyBASIC)
VAR_8BIT_LIMIT = 187
VAR_16BIT_LIMIT = 25

# Severity levels (ordered by precedence)
SEVERITY_INFO = 'info'
SEVERITY_WARN = 'warn'
SEVERITY_ERROR = 'error'
SEVERITY_CRITICAL = 'critical'

SEVERITY_ORDER = {
    SEVERITY_INFO: 0,
    SEVERITY_WARN: 1,
    SEVERITY_ERROR: 2,
    SEVERITY_CRITICAL: 3,
}


def list_games():
    """Discover available games in the games/ directory."""
    games = []
    if not os.path.isdir(GAMES_DIR):
        return games
    for name in sorted(os.listdir(GAMES_DIR)):
        game_dir = os.path.join(GAMES_DIR, name)
        src = os.path.join(game_dir, 'src', 'main.bas')
        if os.path.isfile(src):
            games.append(name)
    return games


def resolve_game_paths(game_name):
    """Resolve source and listing file paths for a game.

    Returns (src_path, lst_path) where lst_path may be None.
    """
    game_dir = os.path.join(GAMES_DIR, game_name)
    src = os.path.join(game_dir, 'src', 'main.bas')
    if not os.path.isfile(src):
        return None, None

    # Find the .lst file in build/ (auto-discover name)
    build_dir = os.path.join(game_dir, 'build')
    lst = None
    if os.path.isdir(build_dir):
        lst_files = glob.glob(os.path.join(build_dir, '*.lst'))
        if len(lst_files) == 1:
            lst = lst_files[0]
        elif len(lst_files) > 1:
            # Multiple .lst files — pick the largest (likely the main build)
            lst = max(lst_files, key=os.path.getsize)

    return src, lst
