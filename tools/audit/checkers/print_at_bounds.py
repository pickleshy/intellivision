"""Checker: PRINT AT position overflow (>= 240 corrupts system RAM).

BACKTAB has exactly 240 positions (0-239, addresses $200-$2EF).
PRINT AT with a position >= 240 silently writes past BACKTAB into
system RAM, corrupting variables, the stack, or ISR data.

Two classes are flagged:
  ERROR:  Literal constant position >= 240 (certain bug)
  WARN:   Computed position  constant >= 200  PLUS  a variable reference
          — the constant is within 40 of the limit, so any non-trivial
          variable offset can push it past 239.

Lower base constants (< 200) leave enough headroom for typical column
offsets (0-19) and are not flagged, keeping noise low.  Expressions
like "22 + FireCooldown" (max ~39) are safe and will not be reported.
"""

import re
from output import Finding
from config import SEVERITY_WARN, SEVERITY_ERROR

NAME = 'print-at-bounds'
DESCRIPTION = 'Detect PRINT AT positions that may reach >= 240 (past BACKTAB)'

# Extract the position expression from PRINT AT expr, value
RE_PRINT_AT = re.compile(r'\bPRINT\s+AT\s+([^,]+),', re.IGNORECASE)

# A pure integer literal
RE_LITERAL = re.compile(r'^\s*\d+\s*$')

# Has at least one + between a variable and something else
RE_VAR_PLUS = re.compile(r'[A-Za-z#]\w*\s*\+|\+\s*[A-Za-z#]\w*')

# Known-safe variable references that are always small (row starts, HUD positions)
# These contain variable names whose values are always < 20 (column offsets, etc.)
_SAFE_VARS = frozenset({'col', 'looopvar', 'loopvar'})


def run(source, lst_info):
    findings = []

    for sl in source.lines:
        if sl.is_comment or sl.is_blank:
            continue

        for m in RE_PRINT_AT.finditer(sl.code):
            pos_expr = m.group(1).strip()

            # Literal constant: check for certain overflow
            if RE_LITERAL.match(pos_expr):
                val = int(pos_expr.strip())
                if val >= 240:
                    findings.append(Finding(
                        checker=NAME,
                        severity=SEVERITY_ERROR,
                        filename=sl.filename,
                        line=sl.file_line,
                        message=(f'PRINT AT {val}: position {val} >= 240 — '
                                 f'writes past BACKTAB into system RAM!'),
                        suggestion='BACKTAB positions are 0-239 only',
                    ))
                continue

            # Computed expression: only flag when the leading constant is >= 200.
            # Lower bases leave enough headroom for any column/row offset (0-19),
            # so they generate too many false positives for typical game code.
            if RE_VAR_PLUS.search(pos_expr):
                # Extract the leading integer constant from the expression, if any
                leading = re.match(r'^\s*(\d+)\s*\+', pos_expr)
                if leading:
                    base = int(leading.group(1))
                    if base >= 200:
                        findings.append(Finding(
                            checker=NAME,
                            severity=SEVERITY_WARN,
                            filename=sl.filename,
                            line=sl.file_line,
                            message=(f'PRINT AT {pos_expr}: base {base} is within 40 of '
                                     f'BACKTAB limit (240) — verify variable offset '
                                     f'cannot push total to >= 240'),
                            suggestion='Ensure the sum of all position components cannot exceed 239',
                        ))

    return findings
