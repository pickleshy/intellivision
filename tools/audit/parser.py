"""IntyBASIC source file parser.

Parses a .bas file into structured data: lines, procedures, segments,
labels, and FOR loop scopes.
"""

import re
from dataclasses import dataclass, field


@dataclass
class SourceLine:
    """A single line from the source file."""
    number: int           # 1-based line number
    raw: str              # Original text
    stripped: str          # Whitespace-trimmed, no inline comment
    code: str             # Code portion only (comment removed)
    indent: int           # Leading space count
    is_comment: bool      # Entire line is a comment
    is_blank: bool        # Empty or whitespace-only


@dataclass
class Procedure:
    name: str
    start_line: int
    end_line: int


@dataclass
class ForLoop:
    variable: str
    start_line: int
    end_line: int  # Line of matching NEXT


@dataclass
class ParsedSource:
    """Structured representation of an IntyBASIC source file."""
    lines: list = field(default_factory=list)           # list[SourceLine]
    procedures: dict = field(default_factory=dict)      # {name: Procedure}
    segments: dict = field(default_factory=dict)        # {segment_num: line_number}
    labels: dict = field(default_factory=dict)          # {name: line_number}
    for_loops: list = field(default_factory=list)       # list[ForLoop]
    raw_lines: list = field(default_factory=list)       # list[str] original lines

    def get_line(self, n):
        """Get SourceLine by 1-based line number."""
        if 1 <= n <= len(self.lines):
            return self.lines[n - 1]
        return None

    def line_range(self, start, end):
        """Get stripped code for line range [start, end] (1-based, inclusive)."""
        return [self.lines[i - 1].code for i in range(start, end + 1)
                if 1 <= i <= len(self.lines)]


# Regex patterns
RE_COMMENT_FULL = re.compile(r"^\s*(?:'|REM\b)", re.IGNORECASE)
RE_INLINE_COMMENT = re.compile(r"\s+'.*$")
RE_LABEL = re.compile(r"^(\w+):\s*$|^(\w+):\s")
RE_PROCEDURE = re.compile(r"^(\w+):\s*PROCEDURE\b", re.IGNORECASE)
RE_END = re.compile(r"^\s*END\s*$", re.IGNORECASE)
RE_SEGMENT = re.compile(r"^\s*SEGMENT\s+(\d+)", re.IGNORECASE)
RE_FOR = re.compile(r"\bFOR\s+(\w+)\s*=", re.IGNORECASE)
RE_NEXT = re.compile(r"\bNEXT\s+(\w+)", re.IGNORECASE)
RE_GOTO = re.compile(r"\bGOTO\s+(\w+)", re.IGNORECASE)
RE_RETURN = re.compile(r"\bRETURN\b", re.IGNORECASE)


def strip_comment(line):
    """Remove inline comment from a line of IntyBASIC code."""
    in_string = False
    for i, ch in enumerate(line):
        if ch == '"':
            in_string = not in_string
        elif ch == "'" and not in_string:
            return line[:i].rstrip()
    return line


def parse_source(filepath):
    """Parse an IntyBASIC .bas file into a ParsedSource."""
    with open(filepath, 'r', encoding='utf-8', errors='replace') as f:
        raw_lines = f.readlines()

    source = ParsedSource(raw_lines=[l.rstrip('\n') for l in raw_lines])

    # Phase 1: Parse each line
    for i, raw in enumerate(raw_lines, 1):
        raw_stripped = raw.rstrip('\n')
        trimmed = raw_stripped.strip()
        is_blank = len(trimmed) == 0
        is_comment = bool(RE_COMMENT_FULL.match(raw_stripped)) if not is_blank else False
        code = strip_comment(trimmed) if not is_comment else ''
        indent = len(raw_stripped) - len(raw_stripped.lstrip())

        sl = SourceLine(
            number=i,
            raw=raw_stripped,
            stripped=trimmed,
            code=code.strip(),
            indent=indent,
            is_comment=is_comment,
            is_blank=is_blank,
        )
        source.lines.append(sl)

    # Phase 2: Extract labels, procedures, segments
    proc_stack = []  # (name, start_line)
    for sl in source.lines:
        if sl.is_comment or sl.is_blank:
            continue

        # Segment directives
        m = RE_SEGMENT.match(sl.code)
        if m:
            source.segments[int(m.group(1))] = sl.number
            continue

        # Procedure start
        m = RE_PROCEDURE.match(sl.code)
        if m:
            name = m.group(1)
            proc_stack.append((name, sl.number))
            source.labels[name] = sl.number
            continue

        # END (closes procedure)
        if RE_END.match(sl.code) and proc_stack:
            name, start = proc_stack.pop()
            source.procedures[name] = Procedure(name, start, sl.number)
            continue

        # Standalone label
        m = RE_LABEL.match(sl.code)
        if m:
            label_name = m.group(1) or m.group(2)
            source.labels[label_name] = sl.number

    # Phase 3: Track FOR/NEXT loops
    for_stack = []  # (variable, start_line)
    for sl in source.lines:
        if sl.is_comment or sl.is_blank:
            continue

        # Handle multi-statement lines (colon-separated)
        statements = _split_statements(sl.code)
        for stmt in statements:
            m = RE_FOR.search(stmt)
            if m:
                for_stack.append((m.group(1), sl.number))

            m = RE_NEXT.search(stmt)
            if m:
                var = m.group(1)
                # Find matching FOR (search from top of stack)
                for j in range(len(for_stack) - 1, -1, -1):
                    if for_stack[j][0].upper() == var.upper():
                        fvar, fstart = for_stack.pop(j)
                        source.for_loops.append(ForLoop(fvar, fstart, sl.number))
                        break

    return source


def _split_statements(code):
    """Split a code line on ':' separators, respecting strings."""
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
