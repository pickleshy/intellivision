"""Checker: Expensive 16-bit division by small constants.

IntyBASIC's '/' operator compiles to O(quotient) repeated subtraction —
NOT binary division.  Cost: approximately (A / B) * 22 CPU cycles.

CP1610 NTSC budget: ~14,915 cycles per frame (60Hz).

Worst-case examples with a 16-bit variable (#VAR, max 65535):
  #VAR /   10  →  6,553 iterations * 22 =  144,166 cycles  (9.7 frames!)
  #VAR /  100  →    655 iterations * 22 =   14,410 cycles  (97% of frame)
  #VAR / 1000  →     65 iterations * 22 =    1,430 cycles  (10% of frame)

Mitigation: shrink the dividend first with a mod-reduction step:
    tmp = #VAR / 1000        ' at most 65 iters — acceptable
    rem = #VAR - tmp * 1000  ' remainder 0-999 (8-bit safe)
    digit = rem / 10         ' at most 99 iters — acceptable

Findings are only generated for 16-bit variables (#VAR) divided by
small constants.  8-bit divisions are bounded by 255 and usually safe.

To suppress a known-safe finding (e.g., variable is already bounded
to a small range by prior code), add  ' audit-ignore  anywhere on the
same source line:
    Col = #Mask / 10  ' audit-ignore: bounded to 0-99 by prior /100 step
"""

import re
from output import Finding
from config import SEVERITY_WARN, SEVERITY_ERROR

NAME = 'division-hotspot'
DESCRIPTION = 'Detect 16-bit division by small constants (O(N/D) repeated subtraction)'

# Match:  #VarName / integer_constant
RE_16BIT_DIV = re.compile(r'(#\w+)\s*/\s*(\d+)\b')

# Suppress marker in the raw source line (before comment stripping)
_SUPPRESS = 'audit-ignore'

# Thresholds
# N <= 10  → worst case 6,553 iters → ~9.7 frames: ERROR
# N <= 99  → worst case   655 iters → ~1 frame:    WARN
_ERROR_MAX_DIVISOR = 10
_WARN_MAX_DIVISOR = 99
_NTSC_CYCLES_PER_FRAME = 14_915
_CYCLES_PER_ITER = 22


def _worst_case(divisor):
    iters = 65535 // max(divisor, 1)
    cycles = iters * _CYCLES_PER_ITER
    frames = cycles / _NTSC_CYCLES_PER_FRAME
    return iters, cycles, frames


def run(source, lst_info):
    findings = []

    for sl in source.lines:
        if sl.is_comment or sl.is_blank:
            continue

        # Skip lines where the developer has annotated as known-safe
        if _SUPPRESS in sl.raw:
            continue

        for m in RE_16BIT_DIV.finditer(sl.code):
            var = m.group(1)
            divisor = int(m.group(2))

            if divisor == 0 or divisor > _WARN_MAX_DIVISOR:
                continue

            iters, cycles, frames = _worst_case(divisor)

            if divisor <= _ERROR_MAX_DIVISOR:
                findings.append(Finding(
                    checker=NAME,
                    severity=SEVERITY_ERROR,
                    filename=sl.filename,
                    line=sl.file_line,
                    message=(
                        f'{var} / {divisor}: worst-case {iters:,} iterations '
                        f'(~{cycles:,} cycles = {frames:.1f} frames at NTSC max value)'
                    ),
                    suggestion=(
                        f'Shrink dividend first: tmp = {var} / {divisor * 10}; '
                        f'rem = {var} - tmp * {divisor * 10}; digit = rem / {divisor}'
                    ),
                ))
            else:
                findings.append(Finding(
                    checker=NAME,
                    severity=SEVERITY_WARN,
                    filename=sl.filename,
                    line=sl.file_line,
                    message=(
                        f'{var} / {divisor}: up to {iters:,} iterations if {var} is large '
                        f'(~{cycles:,} cycles worst case)'
                    ),
                    suggestion='Cache the quotient or reduce dividend before dividing',
                ))

    return findings
