#!/usr/bin/env python3
"""IntyBASIC Audit Toolkit — detect code smells and resource usage.

Usage:
    python audit.py space-intruders           # Audit a game by name
    python audit.py --list-games              # Show available games
    python audit.py space-intruders --check for-loop-exit
    python audit.py space-intruders --json    # JSON output
    python audit.py space-intruders --min-severity warn
    python audit.py --list-checkers           # List available checkers
"""

import argparse
import os
import sys

# Add tool directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from config import list_games, resolve_game_paths, SEVERITY_ORDER
from parser import parse_source
from lst_parser import parse_lst
from output import format_text, format_json, get_exit_code
from checkers import discover_checkers


def main():
    checkers = discover_checkers()

    ap = argparse.ArgumentParser(
        description='IntyBASIC code audit toolkit',
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    ap.add_argument('game', nargs='?', default=None,
                     help='Game name (directory under games/)')
    ap.add_argument('--src', default=None,
                     help='Override path to .bas source file')
    ap.add_argument('--lst', default=None,
                     help='Override path to .lst listing file')
    ap.add_argument('--check', action='append', metavar='NAME',
                     help='Run only these checkers (repeatable)')
    ap.add_argument('--json', action='store_true',
                     help='Output as JSON')
    ap.add_argument('--no-color', action='store_true',
                     help='Disable ANSI color codes')
    ap.add_argument('--min-severity', default='info',
                     choices=['info', 'warn', 'error', 'critical'],
                     help='Minimum severity to display')
    ap.add_argument('--list-checkers', action='store_true',
                     help='List available checkers and exit')
    ap.add_argument('--list-games', action='store_true',
                     help='List available games and exit')

    args = ap.parse_args()

    # List checkers mode
    if args.list_checkers:
        print('Available checkers:')
        for name in sorted(checkers.keys()):
            mod = checkers[name]
            desc = getattr(mod, 'DESCRIPTION', '')
            print(f'  {name:25s} {desc}')
        sys.exit(0)

    # List games mode
    if args.list_games:
        games = list_games()
        if not games:
            print('No games found in games/ directory.', file=sys.stderr)
            sys.exit(1)
        print('Available games:')
        for g in games:
            src, lst = resolve_game_paths(g)
            lst_status = 'built' if lst else 'no .lst'
            print(f'  {g:30s} ({lst_status})')
        sys.exit(0)

    # Resolve paths — game name or explicit --src
    if args.src:
        src_path = os.path.abspath(args.src)
        lst_path = os.path.abspath(args.lst) if args.lst else None
    elif args.game:
        src_path, lst_path = resolve_game_paths(args.game)
        if src_path is None:
            available = list_games()
            print(f'Error: game "{args.game}" not found.', file=sys.stderr)
            if available:
                print(f'Available: {", ".join(available)}', file=sys.stderr)
            sys.exit(1)
        # Allow --lst override even with game name
        if args.lst:
            lst_path = os.path.abspath(args.lst)
    else:
        ap.print_help()
        print('\nError: specify a game name or use --src.', file=sys.stderr)
        sys.exit(1)

    if not os.path.isfile(src_path):
        print(f'Error: source file not found: {src_path}', file=sys.stderr)
        sys.exit(1)

    # Parse source
    source = parse_source(src_path)

    # Parse listing (optional — some checkers work without it)
    lst_info = None
    if lst_path and os.path.isfile(lst_path):
        lst_info = parse_lst(lst_path)

    # Determine which checkers to run
    if args.check:
        selected = {}
        for name in args.check:
            if name not in checkers:
                print(f'Error: unknown checker "{name}"', file=sys.stderr)
                print(f'Available: {", ".join(sorted(checkers.keys()))}',
                      file=sys.stderr)
                sys.exit(1)
            selected[name] = checkers[name]
    else:
        selected = checkers

    # Header
    if not args.json:
        game_label = args.game or os.path.basename(src_path)
        title = f'IntyBASIC Audit \u2014 {game_label}'
        print(title)
        print('\u2550' * len(title))

    # Run checkers
    all_findings = []
    for name in sorted(selected.keys()):
        mod = selected[name]
        try:
            findings = mod.run(source, lst_info)
            all_findings.extend(findings)
        except Exception as e:
            print(f'Error in checker {name}: {e}', file=sys.stderr)

    # Filter by minimum severity
    min_sev = SEVERITY_ORDER.get(args.min_severity, 0)
    filtered = [f for f in all_findings
                if SEVERITY_ORDER.get(f.severity, 0) >= min_sev]

    # Output
    if args.json:
        print(format_json(filtered))
    else:
        print(format_text(filtered, use_color=not args.no_color))

    sys.exit(get_exit_code(filtered))


if __name__ == '__main__':
    main()
