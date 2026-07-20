---
name: abap-code-review
disable-model-invocation: true
description: Orchestrates the abap-review-* skills into a single end-to-end run against a repo or folder of ABAP source — produces one human-verifiable report with file:line references. NEVER auto-invoke — only run when the user explicitly types /abap-code-review.
---

# abap-code-review — Full Review Workflow

## Overview

Point this at a folder of ABAP source (a local clone of abapGit, a pinned commit, or any other ABAP codebase) and it runs the available `abap-review-*` skills in sequence, then aggregates their output into one report. This is the workflow a stranger should be able to run and reproduce the same result — reproducibility is the whole point of the demo.

## Inputs

- **Target path**: folder containing `.abap` files to review
- **Commit/version reference**: if the target is a git clone, record the exact commit SHA in the report header. Without this, "reproducible by anyone" is just a claim, not a fact.
- **Skills to run**: default is all available `abap-review-*` skills (currently: `abap-review-performance`; `abap-review-naming` and `abap-review-security` join once built)

## Steps

1. **Confirm scope** — target path, commit SHA, which skills to run. Don't guess; ask if any of these aren't already clear from context.
2. **Run each skill** in turn against the target path, collecting each skill's findings (see each skill's own file for its per-pattern methodology).
3. **Aggregate** — combine all findings into one report:
   - Header: target, commit SHA, date, skills run, total findings by severity
   - Findings grouped by severity (High → Medium → Low), each with file:line, pattern, why, suggested direction (per the format each skill defines)
4. **Verify a sample by hand** — before publishing a report (e.g. to `examples/`), manually check a handful of findings across severities. Note the sample size and how many held up as real in the report itself. This is what makes the report credible instead of just agent output taken on faith.
5. **Publish** — save the finished report under `examples/`, named for the target and date (e.g. `examples/abapgit-<short-sha>-<yyyy-mm-dd>.md`).

## What this workflow does NOT do

- No auto-fixes — every finding is a pointer for a human to act on, not a patch
- No SAP system integration — this never connects to a live SAP system or ATC
- No claim of completeness — a clean report means "no findings for the patterns this skill set currently checks," not "this code has no issues"
