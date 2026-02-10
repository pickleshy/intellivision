"""Checker: Repeated sprite-hide and SFX-reset sequences.

Detects copy-pasted reset patterns that could be extracted into procedures:
- Consecutive SPRITE n, 0, 0, 0 blocks
- SfxVolume = 0 / SfxType = 0 sequences
"""

import re
from collections import defaultdict
from output import Finding
from config import SEVERITY_INFO, SEVERITY_WARN

NAME = 'reset-duplication'
DESCRIPTION = 'Find repeated sprite-hide and SFX-reset sequences'

RE_SPRITE_HIDE = re.compile(r'SPRITE\s+\w+,\s*0,\s*0,\s*0', re.IGNORECASE)
RE_SFX_RESET = re.compile(
    r'SfxVolume\s*=\s*0|SfxType\s*=\s*0|SOUND\s+2\s*,\s*,\s*0',
    re.IGNORECASE
)


def run(source, lst_info):
    findings = []

    # Pattern 1: Sprite hide blocks (3+ consecutive SPRITE n, 0, 0, 0)
    _check_sprite_hide_blocks(source, findings)

    # Pattern 2: SFX reset patterns
    _check_sfx_resets(source, findings)

    return findings


def _check_sprite_hide_blocks(source, findings):
    """Find blocks of 3+ consecutive sprite hides."""
    blocks = []  # [(start_line, end_line, count)]
    current_start = None
    current_count = 0

    for sl in source.lines:
        if sl.is_comment or sl.is_blank:
            continue

        # Check each statement on multi-statement lines
        has_sprite_hide = bool(RE_SPRITE_HIDE.search(sl.code))

        if has_sprite_hide:
            if current_start is None:
                current_start = sl.number
                current_count = 1
            else:
                current_count += 1
        else:
            if current_count >= 3:
                blocks.append((current_start, sl.number - 1, current_count))
            current_start = None
            current_count = 0

    # Handle end of file
    if current_count >= 3:
        blocks.append((current_start, source.lines[-1].number, current_count))

    if len(blocks) >= 2:
        locations = ', '.join(f'L{b[0]}({b[2]} sprites)' for b in blocks)
        severity = SEVERITY_WARN if len(blocks) >= 3 else SEVERITY_INFO
        findings.append(Finding(
            checker=NAME,
            severity=severity,
            line=blocks[0][0],
            message=f'{len(blocks)} sprite-hide blocks found: {locations}',
            suggestion='Consider extracting into a HideAllSprites procedure',
        ))


def _check_sfx_resets(source, findings):
    """Find repeated SFX reset sequences (SfxVolume=0, SfxType=0)."""
    # Find all lines with SFX reset patterns
    reset_lines = []
    for sl in source.lines:
        if sl.is_comment or sl.is_blank:
            continue
        if RE_SFX_RESET.search(sl.code):
            reset_lines.append(sl.number)

    # Group into clusters (consecutive or near-consecutive lines)
    clusters = []
    current_cluster = []
    for line_num in reset_lines:
        if current_cluster and line_num - current_cluster[-1] > 2:
            if len(current_cluster) >= 2:
                clusters.append(current_cluster[:])
            current_cluster = []
        current_cluster.append(line_num)
    if len(current_cluster) >= 2:
        clusters.append(current_cluster[:])

    if len(clusters) >= 3:
        locations = ', '.join(f'L{c[0]}' for c in clusters[:5])
        findings.append(Finding(
            checker=NAME,
            severity=SEVERITY_WARN,
            line=clusters[0][0],
            message=f'{len(clusters)} SFX reset sequences found: {locations}',
            suggestion='Consider extracting into a SilenceSfx procedure if not already done',
        ))
    elif len(clusters) >= 2:
        locations = ', '.join(f'L{c[0]}' for c in clusters)
        findings.append(Finding(
            checker=NAME,
            severity=SEVERITY_INFO,
            line=clusters[0][0],
            message=f'{len(clusters)} SFX reset sequences found: {locations}',
            suggestion='May be worth extracting if pattern grows',
        ))
