"""Checker: Near-identical code blocks appearing multiple times.

This is the #1 LLM code smell — copy-pasting blocks instead of extracting
them into shared procedures.
"""

import re
from collections import defaultdict
from output import Finding
from config import SEVERITY_WARN, SEVERITY_ERROR, MIN_DUPLICATE_LINES, MIN_DUPLICATE_COUNT

NAME = 'duplicate-code'
DESCRIPTION = 'Find repeated code blocks (3+ lines, 2+ occurrences)'

# Lines to skip entirely (structural, data, or inherently repetitive)
RE_SKIP = re.compile(
    r'^\s*(?:'
    r'BITMAP\s|'
    r'DATA\s|'
    r'MUSIC\s|'
    r'DEFINE\s|'
    r'WAIT\s*$|'
    r'END\s*IF|'
    r'END\s*$|'
    r'NEXT\s|'
    r'WEND|'
    r'LOOP|'
    r'ELSE\s*$'
    r')',
    re.IGNORECASE
)


def _normalize(code):
    """Normalize a line for comparison: lowercase, collapse whitespace."""
    s = code.strip().lower()
    s = re.sub(r'\s+', ' ', s)
    return s


def run(source, lst_info):
    findings = []

    # Build list of code-only lines (skip blanks, comments, structural-only)
    code_lines = []
    for sl in source.lines:
        if sl.is_comment or sl.is_blank:
            continue
        if RE_SKIP.match(sl.code):
            continue
        code_lines.append((sl.number, sl.filename, sl.file_line, _normalize(sl.code)))

    if len(code_lines) < MIN_DUPLICATE_LINES:
        return findings

    # Scan from largest to smallest block size; keep only maximal blocks
    all_duplicates = []

    for block_size in range(8, MIN_DUPLICATE_LINES - 1, -1):
        seen = defaultdict(list)

        for i in range(len(code_lines) - block_size + 1):
            block = tuple(code_lines[i + j][3] for j in range(block_size))
            key = hash(block)
            seen[key].append(i)

        for key, indices in seen.items():
            if len(indices) < MIN_DUPLICATE_COUNT:
                continue

            # Filter overlapping matches
            non_overlapping = []
            last_end = -1
            for idx in sorted(indices):
                if idx > last_end:
                    non_overlapping.append(idx)
                    last_end = idx + block_size - 1

            if len(non_overlapping) < MIN_DUPLICATE_COUNT:
                continue

            # Verify actual content match (hash collision check)
            first_block = tuple(code_lines[non_overlapping[0] + j][3]
                                for j in range(block_size))
            matches = []
            for idx in non_overlapping:
                block = tuple(code_lines[idx + j][3] for j in range(block_size))
                if block == first_block:
                    matches.append(idx)

            if len(matches) < MIN_DUPLICATE_COUNT:
                continue

            # Store (global_line, filename, file_line) for each match start
            loc_tuples = [(code_lines[idx][0], code_lines[idx][1], code_lines[idx][2])
                          for idx in matches]
            all_duplicates.append((block_size, loc_tuples))

    # Deduplicate: keep only the largest blocks per location
    findings = _build_findings(source, all_duplicates)
    return findings


def _build_findings(source, all_duplicates):
    """Build findings, keeping only the largest non-overlapping duplicates."""
    if not all_duplicates:
        return []

    # Sort by block size descending
    all_duplicates.sort(key=lambda x: -x[0])

    # Track which source lines are already covered
    covered = set()
    findings = []

    for block_size, loc_tuples in all_duplicates:
        # loc_tuples: list of (global_line, filename, file_line)
        first_gln, first_fname, first_fline = loc_tuples[0]
        if first_gln in covered:
            continue

        # Mark all lines in all occurrences as covered (by global line)
        for gln, _, _ in loc_tuples:
            for offset in range(block_size):
                covered.add(gln + offset)

        # Build finding
        if block_size >= 6 or len(loc_tuples) >= 4:
            severity = SEVERITY_ERROR
        else:
            severity = SEVERITY_WARN

        first_sl = source.get_line(first_gln)
        first_line_text = first_sl.code if first_sl else ''
        if len(first_line_text) > 60:
            first_line_text = first_line_text[:57] + '...'

        locations = ', '.join(f'{fn}:L{fl}' for _, fn, fl in loc_tuples)
        findings.append(Finding(
            checker=NAME,
            severity=severity,
            filename=first_fname,
            line=first_fline,
            end_line=first_fline + block_size - 1,
            message=f'{block_size}-line block repeated {len(loc_tuples)}x at {locations}',
            suggestion=f'First line: {first_line_text}',
        ))

    return findings
