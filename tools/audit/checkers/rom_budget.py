"""Checker: ROM segment usage and variable budget.

Parses the .lst file to show per-segment fill percentages and variable
counts, with color-coded warnings for approaching limits.
"""

from output import Finding
from config import (
    SEVERITY_INFO, SEVERITY_WARN, SEVERITY_ERROR,
    ROM_WARN_PERCENT, ROM_ERROR_PERCENT,
    VAR_8BIT_LIMIT, VAR_16BIT_LIMIT,
)

NAME = 'rom-budget'
DESCRIPTION = 'Report ROM segment usage and variable counts from .lst file'


def _bar(used, total, width=20):
    """Generate a text-based progress bar."""
    if total == 0:
        return ' ' * width
    filled = int(width * used / total)
    filled = min(filled, width)
    return '\u2588' * filled + '\u2591' * (width - filled)


def run(source, lst_info):
    findings = []

    if not lst_info or not lst_info.segments:
        findings.append(Finding(
            checker=NAME,
            severity=SEVERITY_WARN,
            message='No ROM usage data found in .lst file (build first?)',
        ))
        return findings

    # Per-segment usage
    for seg in lst_info.segments:
        total = seg.used + seg.available
        if total == 0:
            continue
        pct = seg.used * 100.0 / total
        bar = _bar(seg.used, total)

        if pct >= ROM_ERROR_PERCENT:
            severity = SEVERITY_ERROR
        elif pct >= ROM_WARN_PERCENT:
            severity = SEVERITY_WARN
        else:
            severity = SEVERITY_INFO

        findings.append(Finding(
            checker=NAME,
            severity=severity,
            message=f'Seg {seg.number}: {bar}  {seg.used}/{total} ({pct:.1f}%) \u2014 {seg.available} free',
        ))

    # Total ROM usage
    if lst_info.total_used > 0:
        total = lst_info.total_used + lst_info.total_available
        pct = lst_info.total_used * 100.0 / total
        findings.append(Finding(
            checker=NAME,
            severity=SEVERITY_INFO,
            message=f'Total ROM: {lst_info.total_used}/{total} words ({pct:.1f}%)',
        ))

    # 8-bit user variables (from .lst var_ entries)
    if lst_info.var_8bit_user > 0:
        findings.append(Finding(
            checker=NAME,
            severity=SEVERITY_INFO,
            message=f'8-bit user vars: {lst_info.var_8bit_user} (run build.sh to see total/limit from compiler)',
        ))

    # 16-bit user variables
    if lst_info.var_16bit_user > 0:
        remaining = VAR_16BIT_LIMIT - lst_info.var_16bit_user
        if remaining <= 0:
            severity = SEVERITY_ERROR
        elif remaining <= 2:
            severity = SEVERITY_WARN
        else:
            severity = SEVERITY_INFO
        findings.append(Finding(
            checker=NAME,
            severity=severity,
            message=f'16-bit user vars: {lst_info.var_16bit_user}/{VAR_16BIT_LIMIT} ({remaining} free)',
        ))

    return findings
