"""Checker: Inefficient arithmetic patterns.

The CP1610 has no hardware multiply — `* 2` compiles to a software multiply
routine (~50 cycles), while `+ var` is a single ADD instruction (~6 cycles).
Also detects FOR-loop bitmask shifts that should use DATA table lookups.
"""

import re
from output import Finding
from config import SEVERITY_INFO, SEVERITY_WARN

NAME = 'inefficient-arith'
DESCRIPTION = 'Detect * 2 (should be + var) and shift loops (should be DATA table)'

# Match patterns like: var = var * 2 or #var = #var * 2
RE_MUL2 = re.compile(r'(#?\w+)\s*=\s*\1\s*\*\s*2\b', re.IGNORECASE)

# Match shift loop pattern: #Mask = #Mask * 2 (inside a FOR loop)
RE_SHIFT_IN_LOOP = re.compile(r'(#?\w+)\s*=\s*\1\s*\*\s*2', re.IGNORECASE)

# Match self-add (the efficient form) for comparison
RE_SELF_ADD = re.compile(r'(#?\w+)\s*=\s*\1\s*\+\s*\1\b', re.IGNORECASE)


def run(source, lst_info):
    findings = []

    # Track which lines are inside FOR loops
    in_for = set()
    for fl in source.for_loops:
        for line_num in range(fl.start_line, fl.end_line + 1):
            in_for.add(line_num)

    for sl in source.lines:
        if sl.is_comment or sl.is_blank:
            continue

        # Check for * 2 pattern
        m = RE_MUL2.search(sl.code)
        if m:
            var = m.group(1)
            is_in_loop = sl.number in in_for
            severity = SEVERITY_WARN if is_in_loop else SEVERITY_INFO

            findings.append(Finding(
                checker=NAME,
                severity=severity,
                line=sl.number,
                message=f'{var} = {var} * 2 — software multiply (~50 cycles)',
                suggestion=f'Use {var} = {var} + {var} instead (single ADD, ~6 cycles)',
            ))

    return findings
