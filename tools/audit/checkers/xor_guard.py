"""Checker: Unguarded XOR on grid/bit arrays (double-XOR resurrection bug).

XOR is used to toggle bits in the alien grid and other bit arrays.
If a bit has already been cleared (by a bullet, a bomb, or another
system running in the same frame), a blind XOR will SET it back to 1,
resurrecting a dead alien or entity.

Safe pattern:
    IF #AlienRow(Row) AND #Mask THEN          <- guard: bit is set?
        #AlienRow(Row) = #AlienRow(Row) XOR #Mask  <- safe toggle

Dangerous pattern (no guard):
    #AlienRow(Row) = #AlienRow(Row) XOR #Mask <- resurrection bug!

The checker looks for   #Arr(idx) = #Arr(idx) XOR expr
without a matching AND guard on the same or preceding 45 lines.
The wider window is necessary because guards are often in an outer
IF block many lines above the actual XOR statement.  In the deepest
case found in Space Intruders (MegaBeamKill), the guard sits ~38
code lines above the XOR; 45 gives a comfortable margin.
"""

import re
from output import Finding
from config import SEVERITY_WARN

NAME = 'xor-guard'
DESCRIPTION = 'Detect unguarded XOR on arrays (double-XOR resurrection bug)'

# Match:  #Array(index) = #Array(index) XOR something
RE_ARRAY_XOR = re.compile(
    r'(#\w+\(\w+\))\s*=\s*\1\s*XOR\b',
    re.IGNORECASE,
)

# An AND guard preceding the XOR: IF expr AND expr THEN
RE_AND_GUARD = re.compile(r'\bIF\b.+\bAND\b.+\bTHEN\b', re.IGNORECASE)


def run(source, lst_info):
    findings = []
    # Rolling window of last 45 non-blank code lines.
    # Guards on array XORs are often in an outer IF block many lines above
    # (e.g., the XOR is inside an IF/ELSE chain nested inside the actual
    # AND guard).  2 lines is far too narrow; 45 covers the deepest nesting
    # seen in Space Intruders (MegaBeamKill guard ~38 lines above the XOR)
    # without reaching into unrelated procedures.
    LOOKBACK = 45
    prev = [''] * LOOKBACK

    for sl in source.lines:
        if sl.is_comment or sl.is_blank:
            continue

        m = RE_ARRAY_XOR.search(sl.code)
        if m:
            array_expr = m.group(1)

            guarded = bool(RE_AND_GUARD.search(sl.code))
            if not guarded:
                for p in prev:
                    if RE_AND_GUARD.search(p):
                        guarded = True
                        break

            if not guarded:
                findings.append(Finding(
                    checker=NAME,
                    severity=SEVERITY_WARN,
                    filename=sl.filename,
                    line=sl.file_line,
                    message=(f'Unguarded XOR on {array_expr}: if bit is already 0, '
                             f'XOR sets it back to 1 (resurrection bug)'),
                    suggestion=(f'Add guard: IF {array_expr} AND #Mask THEN '
                                f'before the XOR'),
                ))

        prev = prev[1:] + [sl.code]

    return findings
