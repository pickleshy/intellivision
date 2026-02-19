"""Checker: Redundant guard conditions.

Detects IF guards that are provably redundant because:
- BossCount > 0 wrapping a FOR 0 TO BossCount-1 (the FOR handles empty)
- Repeated identical conditions in the same procedure
"""

import re
from output import Finding
from config import SEVERITY_INFO, SEVERITY_WARN

NAME = 'redundant-guards'
DESCRIPTION = 'Detect guard conditions that are always true or redundant'

RE_BOSSCOUNT_GUARD = re.compile(r'IF\s+BossCount\s*>\s*0\s+THEN', re.IGNORECASE)
RE_FOR_BOSSCOUNT = re.compile(r'FOR\s+\w+\s*=\s*0\s+TO\s+BossCount\s*-\s*1', re.IGNORECASE)


def run(source, lst_info):
    findings = []

    # Pattern 1: BossCount > 0 guard wrapping FOR 0 TO BossCount-1
    _check_bosscount_guards(source, findings)

    # Pattern 2: Duplicate IF conditions in same procedure
    _check_duplicate_conditions(source, findings)

    return findings


def _check_bosscount_guards(source, findings):
    """Find IF BossCount > 0 THEN ... FOR i = 0 TO BossCount - 1."""
    for sl in source.lines:
        if sl.is_comment or sl.is_blank:
            continue
        if not RE_BOSSCOUNT_GUARD.search(sl.code):
            continue

        # Look ahead up to 5 lines for a matching FOR
        for offset in range(1, 6):
            next_sl = source.get_line(sl.number + offset)
            if next_sl is None:
                break
            if next_sl.is_comment or next_sl.is_blank:
                continue
            if RE_FOR_BOSSCOUNT.search(next_sl.code):
                findings.append(Finding(
                    checker=NAME,
                    severity=SEVERITY_INFO,
                    filename=sl.filename,
                    line=sl.file_line,
                    message='BossCount > 0 guard before FOR 0 TO BossCount-1 (FOR handles empty range)',
                    suggestion='The FOR loop body is skipped when BossCount=0; guard is redundant but harmless',
                ))
                break
            # Stop looking if we hit non-trivial code
            if next_sl.code and not next_sl.code.upper().startswith(('REM', "'", 'END')):
                break


def _check_duplicate_conditions(source, findings):
    """Find identical IF conditions appearing multiple times in the same procedure."""
    for proc_name, proc in source.procedures.items():
        conditions = {}  # normalized_condition -> [line_numbers]
        for line_num in range(proc.start_line, proc.end_line + 1):
            sl = source.get_line(line_num)
            if sl is None or sl.is_comment or sl.is_blank:
                continue

            # Extract IF conditions
            m = re.match(r'(?:ELSE)?IF\s+(.+?)\s+THEN', sl.code, re.IGNORECASE)
            if m:
                cond = m.group(1).strip().lower()
                cond = re.sub(r'\s+', ' ', cond)
                conditions.setdefault(cond, []).append((line_num, sl.filename, sl.file_line))

        for cond, line_infos in conditions.items():
            if len(line_infos) >= 3:
                locations = ', '.join(f'L{n}' for n, _, _ in line_infos)
                first_fname, first_fline = line_infos[0][1], line_infos[0][2]
                findings.append(Finding(
                    checker=NAME,
                    severity=SEVERITY_WARN,
                    filename=first_fname,
                    line=first_fline,
                    message=f'Condition "{cond}" repeated {len(line_infos)}x in {proc_name} ({locations})',
                    suggestion='Consider restructuring to test this condition once',
                ))
