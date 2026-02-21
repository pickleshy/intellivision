"""Checker: Unguarded 8-bit subtraction (unsigned underflow).

8-bit variables in IntyBASIC are unsigned (0-255). Subtracting past 0
wraps to 255, not -1.  This is a common silent bug class.

Safe pattern (guarded):
    IF Foo > 0 THEN Foo = Foo - 1    ' single-line guard
    IF Foo > 0 THEN                  ' multi-line guard (prev line)
        Foo = Foo - 1

Dangerous pattern (unguarded):
    Foo = Foo - 1                    ' wraps to 255 if Foo is 0!

Only self-decrements are checked (X = X - N).  16-bit variables (#X)
are excluded — they are signed or large enough that underflow is
rarely the concern.
"""

import re
from output import Finding
from config import SEVERITY_WARN

NAME = 'unsigned-underflow'
DESCRIPTION = 'Detect unguarded 8-bit self-decrement (unsigned wrap-to-255)'

_SUPPRESS = 'audit-ignore'

# Self-decrement: Foo = Foo - N  (8-bit: no # prefix)
RE_SELF_DEC = re.compile(r'\b([A-Za-z]\w*)\s*=\s*\1\s*-\s*(\d+)\b')

# Guard patterns on the same or previous code line
# Matches: IF Foo > 0, IF Foo >= N, IF Foo <> 0
RE_GUARD = re.compile(r'\bIF\s+({var})\s*(>|>=|<>)\s*\d+\b', re.IGNORECASE)

# Skip loop counter variables commonly used in FOR/NEXT (safe by construction)
# and names that are clearly 16-bit despite missing # (none in this codebase)
_SKIP_VARS = frozenset({
    'loopvar', 'row', 'col', 'hitrow', 'bossidx', 'i', 'j', 'k',
})


def _guarded(var, line1, line2):
    """Return True if var is guarded by a recognizable safety check.

    Recognised patterns (on the current or previous code line):
      IF Foo > 0         — compare vs literal zero
      IF Foo > N         — compare vs any integer
      IF Foo >= N        — compare vs any integer
      IF Foo <> 0        — not-equal check
      IF Foo > CONST_NAME  — compare vs named constant (e.g. MARCH_SPEED_MIN)
      IF Foo >= CONST_NAME
      IF Foo THEN        — truthy guard (non-zero check)
    """
    # Compare vs integer or named identifier: IF Foo > 0 / IF Foo > SOME_CONST
    pat_cmp = re.compile(
        r'\bIF\s+' + re.escape(var) + r'\s*(>|>=|<>)\s*[\w$]+\b',
        re.IGNORECASE,
    )
    # Truthy guard: IF Foo THEN
    pat_truthy = re.compile(
        r'\bIF\s+' + re.escape(var) + r'\s+THEN\b',
        re.IGNORECASE,
    )
    return bool(
        pat_cmp.search(line1) or pat_cmp.search(line2) or
        pat_truthy.search(line1) or pat_truthy.search(line2)
    )


def run(source, lst_info):
    findings = []
    prev_code = ''

    for sl in source.lines:
        if sl.is_comment or sl.is_blank:
            continue

        if _SUPPRESS in sl.raw:
            prev_code = sl.code
            continue

        for m in RE_SELF_DEC.finditer(sl.code):
            var = m.group(1)
            amount = int(m.group(2))

            if var.lower() in _SKIP_VARS:
                continue

            # Single-line guard: IF Foo > 0 THEN Foo = Foo - 1
            # Multi-line guard: previous code line has IF Foo > 0
            if not _guarded(var, sl.code, prev_code):
                findings.append(Finding(
                    checker=NAME,
                    severity=SEVERITY_WARN,
                    filename=sl.filename,
                    line=sl.file_line,
                    message=(f'{var} = {var} - {amount}: unguarded 8-bit subtraction '
                             f'— wraps to {256 - amount} if {var} is 0'),
                    suggestion=f'Guard with: IF {var} > 0 THEN {var} = {var} - {amount}',
                ))

        prev_code = sl.code

    return findings
