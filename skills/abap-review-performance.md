---
name: abap-review-performance
disable-model-invocation: true
description: Scans ABAP source files for well-known performance anti-patterns — SELECT inside a loop, nested SELECTs, missing FOR ALL ENTRIES guards, and inefficient internal-table operations. Produces a severity-ranked, file:line-referenced list of findings. Report-only — never rewrites ABAP automatically. NEVER auto-invoke — only run when the user explicitly types /abap-review-performance or as a step inside the abap-code-review workflow.
---

# abap-review-performance — Performance Anti-Pattern Scan

## Overview

Scans one or more ABAP source files (`.abap`, or exported objects from abapGit's serialization format) for a fixed set of well-documented performance anti-patterns. This is a **report-only** skill: it flags findings with file:line references and a plain-language reason, but never edits code. Some matches need human judgment — a `SELECT` inside a loop that runs at most twice at startup is not the same risk as one inside a loop over a large business table. That call belongs to the person reading the report, not to this skill.

---

## Workflow

### Step 1: Confirm Scope

Ask if not already clear from context:
- Which repo/folder, or which pinned commit (for the abapGit demo target, always state the exact commit SHA in the report header so results are reproducible)
- Whole codebase, or a specific package/subpath?

### Step 2: Scan for Anti-Patterns

For each `.abap` file in scope, check for the following. Use `grep -n`/`rg -n` for the mechanical part, then read surrounding context before flagging — a raw pattern match without context produces noise, not a useful report.

**1. SELECT inside a loop**
`SELECT` (or `SELECT SINGLE`) statement lexically inside a `LOOP AT` / `DO` / `WHILE` block, where the select's WHERE clause depends on a loop variable. Classic N+1 pattern — should be hoisted out and rewritten as a single `SELECT ... FOR ALL ENTRIES IN itab` or a `JOIN`.
- Severity: **High** if the outer loop iterates over a business-data internal table (order lines, documents, etc.); **Medium** if the loop bound is small/fixed (e.g. a handful of config rows).

**2. Nested SELECTs**
A `SELECT ... ENDSELECT` loop (or a `SELECT` returning multiple rows processed row-by-row) containing another `SELECT` inside it. Same root cause as #1, worse — the outer statement is itself already a loop over the database.
- Severity: **High**, always — this is never the right pattern in modern ABAP.

**3. Missing FOR ALL ENTRIES guard**
`SELECT ... FOR ALL ENTRIES IN itab ...` where `itab` is not checked for emptiness immediately before the statement. If `itab` is empty, `FOR ALL ENTRIES` silently drops the implicit restriction and the statement selects **the entire table** — a well-known ABAP footgun, not a hypothetical one.
- Severity: **High** — this is a correctness bug as much as a performance one (unbounded result set), not just slow.
- Look for: an `IF itab IS NOT INITIAL.` / `IF lines( itab ) > 0.` guard (or equivalent) wrapping the SELECT. Flag if absent.

**4. Internal table anti-patterns**
- `READ TABLE itab ... WITH KEY ...` on a `STANDARD TABLE` without `BINARY SEARCH`, inside a loop that runs many times — linear search where a sorted/hashed table or binary search would be O(log n) instead of O(n).
- Nested `LOOP AT ... LOOP AT ...` over two potentially large internal tables (O(n×m)) where a `READ TABLE ... WITH KEY` or a hashed-table lookup would do.
- `APPEND` inside a loop where the target could instead be built with `INSERT LINES OF` or a table expression — minor, but worth a **Low**-severity note if the loop is large.
- Severity: **Medium** by default; **High** if the table involved is clearly large business data (order items, material master, etc. — infer from naming, don't assume).

### Step 3: Produce the Report

Structured Markdown (or JSON, if feeding the `abap-review-report` aggregator skill), one entry per finding:

```
### [SEVERITY] <short title>
- File: `path/to/file.abap:LINE`
- Pattern: <which of the 4 categories above>
- Why: <one or two sentences, plain language>
- Suggested direction: <not a rewritten fix — a pointer, e.g. "hoist the SELECT above the loop and batch with FOR ALL ENTRIES">
```

Group by severity (High → Medium → Low). Include a header with: scope (files/commit reviewed), total findings by severity, and the date of the run.

### Step 4: Be Honest About Limits

This is pattern-based static analysis, not a compiler or ATC (ABAP Test Cockpit) replacement. State plainly in the report:
- False positives are possible — a `SELECT` inside a loop bounded to run once or twice is technically a match but not a real problem
- The scan cannot see runtime data volumes — severity calls on "is this table large" are inferred from naming/context, not measured
- If verifying a sample of findings by hand (recommended before publishing), note the checked sample size and how many held up
