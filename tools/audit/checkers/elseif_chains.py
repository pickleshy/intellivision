"""Checker: Long IF/ELSEIF chains.

Long chains testing the same variable can often be replaced with
ON var GOTO/GOSUB or DATA table lookups, which are more efficient
on the CP1610.
"""

import re
from output import Finding
from config import SEVERITY_INFO, SEVERITY_WARN, MAX_ELSEIF_CHAIN

NAME = 'elseif-chains'
DESCRIPTION = 'Find long IF/ELSEIF chains convertible to ON GOTO or DATA tables'

RE_ELSEIF = re.compile(r'^\s*ELSEIF\b', re.IGNORECASE)
RE_IF = re.compile(r'^\s*IF\b', re.IGNORECASE)
RE_END_IF = re.compile(r'^\s*END\s+IF', re.IGNORECASE)

# Extract the variable being tested: IF var = ... or ELSEIF var = ...
RE_TEST_VAR = re.compile(
    r'(?:ELSE)?IF\s+(#?\w+)\s*=\s*\d+\s+THEN',
    re.IGNORECASE
)


def run(source, lst_info):
    findings = []

    # Scan for chains of ELSEIF testing the same variable
    i = 0
    lines = source.lines
    while i < len(lines):
        sl = lines[i]
        if sl.is_comment or sl.is_blank:
            i += 1
            continue

        # Look for IF var = N THEN
        m = RE_TEST_VAR.match(sl.code)
        if not m:
            i += 1
            continue

        chain_var = m.group(1).upper()
        chain_start = sl.number
        chain_count = 1  # The initial IF

        # Count consecutive ELSEIFs testing the same variable
        j = i + 1
        while j < len(lines):
            next_sl = lines[j]
            if next_sl.is_comment or next_sl.is_blank:
                j += 1
                continue

            # Check for ELSEIF same_var = N
            m2 = RE_TEST_VAR.match(next_sl.code)
            if m2 and m2.group(1).upper() == chain_var:
                chain_count += 1
                j += 1
                continue

            # Check for plain ELSEIF (different pattern but still chained)
            if RE_ELSEIF.match(next_sl.code):
                chain_count += 1
                j += 1
                continue

            # Chain broken by anything else (END IF, other code, etc.)
            break

        if chain_count > MAX_ELSEIF_CHAIN:
            severity = SEVERITY_WARN if chain_count > 12 else SEVERITY_INFO
            findings.append(Finding(
                checker=NAME,
                severity=severity,
                filename=sl.filename,
                line=sl.file_line,
                end_line=lines[min(j - 1, len(lines) - 1)].file_line,
                message=f'{chain_count}-branch IF/ELSEIF chain on {chain_var}',
                suggestion=f'Consider ON {chain_var} GOTO/GOSUB or DATA table lookup',
            ))

        i = j  # Skip past the chain we just analyzed

    return findings
