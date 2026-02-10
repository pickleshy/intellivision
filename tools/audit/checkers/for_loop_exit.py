"""Checker: GOTO/RETURN inside FOR loops (R4 stack leak).

This is a CRITICAL safety check. On the CP1610, IntyBASIC FOR/NEXT loops
push state onto R4. Exiting via GOTO or RETURN leaks stack space, causing
a delayed crash after 1-3 minutes of gameplay.

A GOTO to a label that is still within the same FOR loop body (before
NEXT) is safe — the loop iteration still completes. Only GOTOs that
jump past the NEXT (exiting the loop) are dangerous.
"""

import re
from output import Finding
from config import SEVERITY_CRITICAL, SEVERITY_WARN

NAME = 'for-loop-exit'
DESCRIPTION = 'Detect GOTO/RETURN inside FOR loops (R4 stack leak — crash bug)'

RE_FOR = re.compile(r'\bFOR\s+(\w+)\s*=', re.IGNORECASE)
RE_NEXT = re.compile(r'\bNEXT\s+(\w+)', re.IGNORECASE)
RE_GOTO = re.compile(r'\bGOTO\s+(\w+)', re.IGNORECASE)
RE_RETURN = re.compile(r'\bRETURN\b', re.IGNORECASE)


def run(source, lst_info):
    findings = []

    # Phase 1: Build FOR/NEXT scope map using parser's for_loops
    # Each ForLoop has (variable, start_line, end_line) where end_line = NEXT line
    loop_ranges = {}  # (start, end) for each FOR
    for fl in source.for_loops:
        loop_ranges[(fl.start_line, fl.end_line)] = fl.variable

    # Phase 2: Scan for GOTO/RETURN inside FOR scopes
    for sl in source.lines:
        if sl.is_comment or sl.is_blank:
            continue

        statements = _split_statements(sl.code)
        for stmt in statements:
            # Check GOTO
            m = RE_GOTO.search(stmt)
            if m:
                target_label = m.group(1)
                target_line = source.labels.get(target_label, 0)
                _check_goto_in_loops(source, sl, target_label, target_line,
                                     loop_ranges, findings)

            # Check RETURN
            if RE_RETURN.search(stmt) and not RE_FOR.search(stmt):
                _check_return_in_loops(source, sl, loop_ranges, findings)

    return findings


def _check_goto_in_loops(source, sl, target_label, target_line, loop_ranges, findings):
    """Check if a GOTO at sl.number exits any active FOR loop."""
    for (start, end), var in loop_ranges.items():
        if start < sl.number <= end:
            # This line is inside this FOR loop
            if target_line == 0:
                # Can't resolve target — warn
                findings.append(Finding(
                    checker=NAME,
                    severity=SEVERITY_WARN,
                    line=sl.number,
                    message=f'GOTO {target_label} inside FOR {var} (L{start}) — target not found, verify manually',
                    suggestion='Ensure the GOTO target is before NEXT (within the loop body)',
                ))
            elif target_line < start or target_line > end:
                # Target is outside the FOR loop — this is the dangerous case
                findings.append(Finding(
                    checker=NAME,
                    severity=SEVERITY_CRITICAL,
                    line=sl.number,
                    message=f'GOTO {target_label} exits FOR {var} loop (L{start}-L{end}) — R4 stack leak!',
                    suggestion='Use a sentinel variable and let the FOR loop complete naturally',
                ))
            # else: target is within the loop body — safe (e.g., skip-ahead pattern)


def _check_return_in_loops(source, sl, loop_ranges, findings):
    """Check if a RETURN is inside any active FOR loop."""
    for (start, end), var in loop_ranges.items():
        if start < sl.number <= end:
            findings.append(Finding(
                checker=NAME,
                severity=SEVERITY_CRITICAL,
                line=sl.number,
                message=f'RETURN inside FOR {var} loop (L{start}-L{end}) — R4 stack leak!',
                suggestion='Use a sentinel variable and let the FOR loop complete naturally',
            ))


def _split_statements(code):
    parts = []
    current = []
    in_string = False
    for ch in code:
        if ch == '"':
            in_string = not in_string
            current.append(ch)
        elif ch == ':' and not in_string:
            parts.append(''.join(current).strip())
            current = []
        else:
            current.append(ch)
    if current:
        parts.append(''.join(current).strip())
    return [p for p in parts if p]
