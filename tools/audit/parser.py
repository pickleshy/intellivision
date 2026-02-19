"""IntyBASIC source file parser.

Parses a .bas file into structured data: lines, procedures, segments,
labels, and FOR loop scopes.  INCLUDE directives are expanded inline so
all checkers see the full combined source.
"""

import os
import re
from dataclasses import dataclass, field


@dataclass
class SourceLine:
    """A single line from the source file."""
    number: int           # 1-based GLOBAL line number (used for range comparisons)
    raw: str              # Original text
    stripped: str          # Whitespace-trimmed, no inline comment
    code: str             # Code portion only (comment removed)
    indent: int           # Leading space count
    is_comment: bool      # Entire line is a comment
    is_blank: bool        # Empty or whitespace-only
    filename: str = ''    # Short filename (e.g. "player.bas")
    file_line: int = 0    # 1-based line number within the original file


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
        """Get SourceLine by 1-based GLOBAL line number."""
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
RE_INCLUDE = re.compile(r'^\s*INCLUDE\s+"([^"]+)"', re.IGNORECASE)


def strip_comment(line):
    """Remove inline comment from a line of IntyBASIC code."""
    in_string = False
    for i, ch in enumerate(line):
        if ch == '"':
            in_string = not in_string
        elif ch == "'" and not in_string:
            return line[:i].rstrip()
    return line


def _find_project_root(start_path):
    """Walk up from start_path to find the directory containing 'games/'."""
    d = os.path.dirname(os.path.abspath(start_path))
    for _ in range(12):
        if os.path.isdir(os.path.join(d, 'games')):
            return d
        parent = os.path.dirname(d)
        if parent == d:
            break
        d = parent
    # Fallback: directory of the start file
    return os.path.dirname(os.path.abspath(start_path))


def _expand_includes(filepath, project_root, seen=None):
    """Return flat list of (short_filename, file_line_1based, raw_text).

    INCLUDE directives are replaced with the content of the referenced file.
    Circular includes are detected and skipped.
    """
    if seen is None:
        seen = set()

    abs_path = os.path.abspath(filepath)
    if abs_path in seen:
        return []   # Prevent circular includes
    seen.add(abs_path)

    short_name = os.path.basename(filepath)
    result = []

    try:
        with open(filepath, 'r', encoding='utf-8', errors='replace') as f:
            lines = f.readlines()
    except FileNotFoundError:
        return result

    for i, raw in enumerate(lines, 1):
        m = RE_INCLUDE.match(raw)
        if m:
            include_rel = m.group(1)
            include_abs = os.path.join(project_root, include_rel)
            result.extend(_expand_includes(include_abs, project_root, seen))
        else:
            result.append((short_name, i, raw))

    return result


def parse_source(filepath, project_root=None):
    """Parse an IntyBASIC .bas file into a ParsedSource.

    INCLUDE directives are expanded recursively so all checkers receive the
    full combined source.  Each SourceLine carries filename and file_line for
    accurate per-file location reporting in findings.
    """
    if project_root is None:
        project_root = _find_project_root(filepath)

    expanded = _expand_includes(filepath, project_root)

    source = ParsedSource(raw_lines=[raw.rstrip('\n') for _, _, raw in expanded])

    # Phase 1: Parse each line
    for global_num, (short_name, file_line, raw) in enumerate(expanded, 1):
        raw_stripped = raw.rstrip('\n')
        trimmed = raw_stripped.strip()
        is_blank = len(trimmed) == 0
        is_comment = bool(RE_COMMENT_FULL.match(raw_stripped)) if not is_blank else False
        code = strip_comment(trimmed) if not is_comment else ''
        indent = len(raw_stripped) - len(raw_stripped.lstrip())

        sl = SourceLine(
            number=global_num,
            raw=raw_stripped,
            stripped=trimmed,
            code=code.strip(),
            indent=indent,
            is_comment=is_comment,
            is_blank=is_blank,
            filename=short_name,
            file_line=file_line,
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
