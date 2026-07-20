# abap-review-agent

An AI agent skill pack that reviews ABAP source code against well-established ABAP conventions — naming, performance, and security — and produces verifiable, file:line-referenced report artifacts. No SAP system required: review is pure static text analysis over `.abap` source, demoed against real open-source ABAP ([abapGit](https://github.com/abapGit/abapGit)).

Built with, and demonstrating, the [AI Delivery Playbook](https://github.com/MikulasFrenak/ai-delivery-playbook) methodology: agents draft, humans decide. Every report is meant to be independently reproducible — clone this repo, run the workflow, get the same findings.

## What it actually checks

This isn't a made-up rulebook — each dimension maps to conventions that are already public, documented, and widely used in the SAP/ABAP world:

- **Performance** (`abap-review-performance`, built) — the classic, well-documented ABAP database/internal-table anti-patterns: SELECT inside a loop, nested SELECTs, `FOR ALL ENTRIES` without an emptiness guard (a well-known correctness footgun, not just a slow-query issue), and internal-table operations that should use a sorted/hashed table or `BINARY SEARCH` instead of a linear scan.
- **Naming** (`abap-review-naming`, planned) — conventions in the spirit of SAP's own public [Clean ABAP](https://github.com/SAP/styleguides/blob/main/clean-abap/CleanABAP.md) style guide: consistent naming (no leftover Hungarian-notation inconsistency), no obsolete statements.
- **Security** (`abap-review-security`, planned) — dynamic SQL without validation, `AUTHORITY-CHECK` gaps, hardcoded credentials.

Every finding is a pointer for a human to judge, not an auto-fix. A regex match is not proof of a real problem — see each skill's own "honest limits" section.

## Status

**Milestone 1 in progress.** `abap-review-performance` is built and verified against the eval fixtures in `fixtures/` — see `examples/fixtures-2026-07-20.md`. A deterministic (non-LLM) regression test, `scripts/check_fixtures.py`, re-implements the mechanical part of the same logic and runs in CI on every push/PR — free, no API key, no LLM call.

```bash
python3 scripts/check_fixtures.py fixtures/
```

Next: run the workflow against a pinned abapGit commit for the real public demo (blocked in the dev sandbox this was built in — no outbound access to github.com there; needs a normal internet connection, see `AGENTS.md` → Setup).

## How it works

1. `skills/abap-review-performance.md` — the review skill itself: what it looks for, how it's found, how it's reported, and its own honest limits. See `AGENTS.md` for the full skill table, including the planned naming/security skills.
2. `workflows/abap-code-review.md` — orchestrates the skills into one run and one report; this is what a stranger runs to reproduce a result.
3. `fixtures/` — small hand-written ABAP files, each with one known, labeled issue (plus one clean file with none) — the eval suite that keeps the skill honest.
4. `scripts/check_fixtures.py` — deterministic, non-LLM regression test over the fixtures; catches mechanical regressions fast and free, run automatically in CI (`.github/workflows/check-fixtures.yml`).
5. `examples/` — published reports from real runs, with file:line findings.

See `AGENTS.md` for full conventions (repo layout, branching, public-repo hygiene, setup) — read that before making changes here. See `docs/adoption.md` for how a team would actually bring this into their SAP change/review process, not just run it once as a demo.
