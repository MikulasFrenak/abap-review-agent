# abap-review-agent

An agent skill pack that reviews ABAP source code for well-known performance, naming and security anti-patterns, and produces verifiable, file:line-referenced report artifacts. No SAP system required — review is pure static text analysis, demoed against real open-source ABAP ([abapGit](https://github.com/abapGit/abapGit)).

Built with, and demonstrating, the [AI Delivery Playbook](https://github.com/MikulasFrenak/ai-delivery-playbook) methodology: agents draft, humans decide. Every report is meant to be independently reproducible — clone this repo, run the workflow, get the same findings.

## Status

**Milestone 1 in progress.** `abap-review-performance` (SELECT-in-loop, nested SELECTs, missing FOR ALL ENTRIES guards, internal-table anti-patterns) is built and verified against the eval fixtures in `fixtures/` — see `examples/fixtures-2026-07-20.md`. A deterministic (non-LLM) regression test, `scripts/check_fixtures.py`, runs the mechanical part of the same logic and checks it in CI on every push/PR — free, no API key. Next: run it against a pinned abapGit commit for the real public demo.

```bash
python3 scripts/check_fixtures.py fixtures/
```

## How it works

1. `skills/abap-review-performance.md` — the review skill itself (see `AGENTS.md` for the full skill table, including planned `abap-review-naming` / `abap-review-security`)
2. `workflows/abap-code-review.md` — orchestrates the skills into one run and one report
3. `fixtures/` — small hand-written ABAP files with known, labeled issues (the eval suite)
4. `examples/` — published reports from real runs, with file:line findings

See `AGENTS.md` for full conventions (repo layout, branching, public-repo hygiene) — read that before making changes here.
