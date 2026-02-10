"""Parser for IntyBASIC .lst (listing) files.

Extracts ROM usage per segment and variable counts from the assembler output.
"""

import re
from dataclasses import dataclass, field


@dataclass
class SegmentInfo:
    number: int
    size_k: int       # Size in K (e.g., 8, 16, 4, 2)
    size_words: int   # Size in words
    used: int         # Words used
    available: int    # Words available


@dataclass
class LstInfo:
    segments: list = field(default_factory=list)  # list[SegmentInfo]
    total_used: int = 0
    total_available: int = 0
    total_size: int = 0
    var_8bit_user: int = 0     # User-defined 8-bit variables (var_NAME)
    var_16bit_user: int = 0    # User-defined 16-bit variables (var_&NAME)
    var_8bit_total: int = 0    # All 8-bit allocations in $100-$1FF range
    var_16bit_total: int = 0   # All 16-bit allocations in $308-$35F range


# ROM USAGE table patterns
RE_SEGMENT_LINE = re.compile(
    r'Static Seg #(\d+)\s+(\d+)K\s+(\d+)\s+(\d+)\s+words'
)
RE_TOTAL_LINE = re.compile(
    r'TOTAL:\s+(\d+)K\s+(\d+)\s+(\d+)\s+words'
)

# Variable patterns (user-defined vars only, not system)
RE_VAR_8BIT = re.compile(r'^0x[\da-fA-F]+\s+var_(\w+):\s+RMB\s+1')
RE_VAR_16BIT = re.compile(r'^0x[\da-fA-F]+\s+var_&(\w+):\s+RMB\s+1')
# Any ALLOCATED RMB 1 (must have address prefix 0x to confirm it was assembled)
RE_ALLOCATED_RMB1 = re.compile(r'^0x[\da-fA-F]+\s+\S+.*\bRMB\s+1\b')

# Size lookup
SIZE_K_TO_WORDS = {2: 2032, 4: 3840, 8: 8192, 16: 16320}


def parse_lst(filepath):
    """Parse an IntyBASIC .lst file for ROM usage and variable counts."""
    info = LstInfo()

    try:
        with open(filepath, 'r', encoding='utf-8', errors='replace') as f:
            lines = f.readlines()
    except FileNotFoundError:
        return info

    var_8bit_names = set()
    var_16bit_names = set()
    in_8bit_section = False
    in_16bit_section = False
    total_8bit_rmb = 0
    total_16bit_rmb = 0

    for line in lines:
        stripped = line.strip()

        # ROM USAGE segment lines
        m = RE_SEGMENT_LINE.search(stripped)
        if m:
            seg_num = int(m.group(1))
            size_k = int(m.group(2))
            used = int(m.group(3))
            available = int(m.group(4))
            info.segments.append(SegmentInfo(
                number=seg_num,
                size_k=size_k,
                size_words=SIZE_K_TO_WORDS.get(size_k, size_k * 1024),
                used=used,
                available=available,
            ))
            continue

        # ROM USAGE total line
        m = RE_TOTAL_LINE.search(stripped)
        if m:
            info.total_size = int(m.group(1)) * 1024
            info.total_used = int(m.group(2))
            info.total_available = int(m.group(3))
            continue

        # Track section boundaries
        if '8-bits variables' in stripped:
            in_8bit_section = True
            in_16bit_section = False
            continue
        if '16-bits variables' in stripped:
            in_16bit_section = True
            in_8bit_section = False
            continue

        # Count ALL RMB 1 in 8-bit section (includes system + user)
        if in_8bit_section and RE_ALLOCATED_RMB1.search(stripped):
            total_8bit_rmb += 1

        # Count ALL RMB 1 in 16-bit section
        if in_16bit_section and RE_ALLOCATED_RMB1.search(stripped):
            total_16bit_rmb += 1

        # 8-bit user variables
        m = RE_VAR_8BIT.match(stripped)
        if m:
            name = m.group(1)
            if not name.startswith('&'):
                var_8bit_names.add(name)
            continue

        # 16-bit user variables
        m = RE_VAR_16BIT.match(stripped)
        if m:
            var_16bit_names.add(m.group(1))
            continue

    info.var_8bit_user = len(var_8bit_names)
    info.var_16bit_user = len(var_16bit_names)
    info.var_8bit_total = total_8bit_rmb
    info.var_16bit_total = total_16bit_rmb

    return info
