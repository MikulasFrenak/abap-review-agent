#!/usr/bin/env python3
"""
check_fixtures.py — deterministic regression test for abap-review-performance.

This is NOT the skill itself (the skill is the markdown prompt in
skills/abap-review-performance.md, run by an AI agent with judgment about
context and severity). This script implements only the mechanical
pattern-matching part described in that skill's Step 2, so the eval suite in
fixtures/ can be checked automatically, in CI, for free — no LLM call, no
API key, no cost. It exists to catch regressions in the fixtures themselves
(like the line-number mistakes in the first draft of this eval suite) and to
give a fast sanity check before trusting an agent's report.

Each fixture file documents its own expected findings in a header comment,
e.g. "Expected finding: ..., line 13." or "Expected findings: ..., lines 16
and 20." This script parses those comments, runs the detector, and diffs
the two sets. Exit code 0 = all fixtures match; 1 = mismatch found.

Usage: python3 scripts/check_fixtures.py [fixtures_dir]
"""

import re
import sys
from pathlib import Path

COMMENT_RE = re.compile(r'^\s*"')


def strip_comments(lines):
    """Return (line_no, upper_text) for non-comment, non-blank lines."""
    out = []
    for i, raw in enumerate(lines, start=1):
        stripped = raw.strip()
        if not stripped or COMMENT_RE.match(stripped) or stripped.startswith("*"):
            continue
        out.append((i, stripped))
    return out


def to_statements(code_lines):
    """Group (line_no, text) pairs into ABAP statements terminated by '.'.

    Returns a list of dicts: start_line, keyword (first token, upper), text
    (joined, upper, whitespace-collapsed).
    """
    statements = []
    buf = []
    start_line = None
    for line_no, text in code_lines:
        if start_line is None:
            start_line = line_no
        buf.append(text)
        if text.rstrip().endswith("."):
            joined = " ".join(buf)
            statements.append(
                {
                    "start_line": start_line,
                    "text": joined,
                    "upper": joined.upper(),
                    "keyword": joined.upper().split()[0].rstrip(".") if joined.split() else "",
                }
            )
            buf = []
            start_line = None
    return statements


def detect(statements):
    """Run the mechanical part of abap-review-performance. Returns a sorted
    list of (line_no, pattern) findings."""
    findings = []
    loop_stack = []
    select_stack = []

    for idx, stmt in enumerate(statements):
        upper = stmt["upper"]
        kw = stmt["keyword"]
        line = stmt["start_line"]

        if kw in ("ENDLOOP", "ENDDO", "ENDWHILE"):
            if loop_stack:
                loop_stack.pop()
            continue
        if kw == "ENDSELECT":
            if select_stack:
                select_stack.pop()
            continue

        is_select = kw == "SELECT"
        if is_select:
            if loop_stack:
                findings.append((line, "select_in_loop"))
            if select_stack:
                findings.append((line, "nested_select"))

            if "FOR ALL ENTRIES IN" in upper:
                m = re.search(r"FOR ALL ENTRIES IN (\w+)", upper)
                itab = m.group(1) if m else None
                guarded = False
                if itab:
                    for prev in statements[max(0, idx - 6):idx]:
                        pu = prev["upper"]
                        if prev["keyword"] == "IF" and itab in pu and (
                            "IS NOT INITIAL" in pu or "LINES(" in pu
                        ):
                            guarded = True
                            break
                if not guarded:
                    findings.append((line, "missing_for_all_entries_guard"))

            needs_endselect = not any(
                kw_ in upper for kw_ in ("INTO TABLE", "APPENDING TABLE", "SELECT SINGLE")
            )
            if needs_endselect:
                select_stack.append(line)
            continue

        if kw == "LOOP":
            if loop_stack:
                findings.append((line, "nested_loop"))
            loop_stack.append(line)
            continue

        if kw in ("DO", "WHILE"):
            loop_stack.append(line)
            continue

        if kw == "READ" and upper.startswith("READ TABLE") and loop_stack:
            if (
                "WITH TABLE KEY" not in upper
                and "BINARY SEARCH" not in upper
                and "WITH KEY" in upper
            ):
                findings.append((line, "linear_read_table"))

    return sorted(findings)


EXPECTED_RE = re.compile(r"line[s]?\s+([0-9]+(?:\s+and\s+[0-9]+)*)", re.IGNORECASE)


def parse_expected(raw_text):
    """Pull expected finding line numbers out of the fixture's own header
    comment. Returns a sorted list of ints (empty if the file says 'none')."""
    if "expected finding" not in raw_text.lower():
        return []
    if re.search(r"expected findings?:\s*none", raw_text, re.IGNORECASE):
        return []
    header = raw_text[: raw_text.lower().index("expected finding")]
    rest = raw_text[raw_text.lower().index("expected finding"):]
    # Only look within the comment block (stop at first non-comment line already
    # guaranteed since we're only fed the raw file text up to first code line
    # by the caller — see main()).
    del header
    m = EXPECTED_RE.search(rest)
    if not m:
        return []
    nums = re.findall(r"\d+", m.group(1))
    return sorted(int(n) for n in nums)


def main():
    fixtures_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("fixtures")
    if not fixtures_dir.is_dir():
        print(f"No such directory: {fixtures_dir}", file=sys.stderr)
        return 2

    files = sorted(fixtures_dir.glob("*.abap"))
    if not files:
        print(f"No .abap fixtures found in {fixtures_dir}", file=sys.stderr)
        return 2

    failures = 0
    for path in files:
        raw = path.read_text()
        lines = raw.splitlines()

        # Expected findings come from the header comment block (before the
        # first blank-separated code section) — parse the whole file's
        # comment text for an "Expected finding(s): ... line(s) N[, and M]."
        comment_text = "\n".join(
            l for l in lines if COMMENT_RE.match(l.strip())
        )
        expected = parse_expected(comment_text)

        code_lines = strip_comments(lines)
        statements = to_statements(code_lines)
        found = sorted(set(n for n, _ in detect(statements)))

        status = "PASS" if found == expected else "FAIL"
        if status == "FAIL":
            failures += 1
        print(f"[{status}] {path.name}: expected={expected} found={found}")
        if status == "FAIL":
            for line_no, pattern in detect(statements):
                print(f"    -> line {line_no}: {pattern}")

    print()
    if failures:
        print(f"{failures}/{len(files)} fixture(s) FAILED.")
        return 1
    print(f"All {len(files)} fixtures matched their expected findings.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
