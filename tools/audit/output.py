"""Output formatting for audit findings."""

import json
from dataclasses import dataclass, asdict
from config import SEVERITY_ORDER


@dataclass
class Finding:
    checker: str
    severity: str
    line: int = 0          # 0 means no specific line (per-file line number)
    end_line: int = 0      # 0 means single line
    message: str = ''
    suggestion: str = ''
    filename: str = ''     # Short filename (e.g. "player.bas"), empty = unknown


# ANSI color codes
COLORS = {
    'critical': '\033[1;31m',  # Bold red
    'error': '\033[31m',       # Red
    'warn': '\033[33m',        # Yellow
    'info': '\033[36m',        # Cyan
    'ok': '\033[32m',          # Green
    'reset': '\033[0m',
    'bold': '\033[1m',
    'dim': '\033[2m',
}

ICONS = {
    'critical': '!!',
    'error': 'XX',
    'warn': '!!',
    'info': '--',
    'ok': 'OK',
}


def _color(severity, text, use_color=True):
    if not use_color:
        return text
    c = COLORS.get(severity, '')
    return f"{c}{text}{COLORS['reset']}" if c else text


def format_text(findings, use_color=True):
    """Format findings as human-readable text."""
    lines = []

    # Group by checker
    by_checker = {}
    for f in findings:
        by_checker.setdefault(f.checker, []).append(f)

    for checker, items in by_checker.items():
        lines.append('')
        lines.append(_color('bold', f'[{checker}]', use_color))

        for f in items:
            icon = ICONS.get(f.severity, '--')
            sev_tag = _color(f.severity, f'[{icon}]', use_color)
            loc = ''
            if f.line > 0:
                if f.end_line > 0 and f.end_line != f.line:
                    loc = f':L{f.line}-{f.end_line}'
                else:
                    loc = f':L{f.line}'
            if f.filename:
                loc = f'  [{f.filename}{loc}]'

            lines.append(f'  {sev_tag} {f.message}{loc}')
            if f.suggestion:
                lines.append(f'       {_color("dim", f.suggestion, use_color)}')

    # Summary
    counts = {'critical': 0, 'error': 0, 'warn': 0, 'info': 0}
    for f in findings:
        if f.severity in counts:
            counts[f.severity] += 1

    lines.append('')
    summary_parts = []
    for sev in ('critical', 'error', 'warn', 'info'):
        n = counts[sev]
        label = f'{n} {sev}'
        if n > 0:
            label = _color(sev, label, use_color)
        summary_parts.append(label)

    max_sev = max((SEVERITY_ORDER.get(f.severity, 0) for f in findings), default=0)
    exit_code = 0 if max_sev == 0 else (1 if max_sev <= 1 else 2)
    lines.append(f"Summary: {', '.join(summary_parts)} — exit code {exit_code}")

    return '\n'.join(lines)


def format_json(findings):
    """Format findings as JSON."""
    counts = {'critical': 0, 'error': 0, 'warn': 0, 'info': 0}
    for f in findings:
        if f.severity in counts:
            counts[f.severity] += 1

    max_sev = max((SEVERITY_ORDER.get(f.severity, 0) for f in findings), default=0)
    exit_code = 0 if max_sev == 0 else (1 if max_sev <= 1 else 2)

    output = {
        'findings': [asdict(f) for f in findings],
        'summary': counts,
        'exit_code': exit_code,
    }
    return json.dumps(output, indent=2)


def get_exit_code(findings):
    """Return exit code based on max severity."""
    max_sev = max((SEVERITY_ORDER.get(f.severity, 0) for f in findings), default=0)
    if max_sev >= 2:
        return 2
    if max_sev >= 1:
        return 1
    return 0
