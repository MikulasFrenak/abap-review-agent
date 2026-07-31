# abap-review-agent

## Purpose

An agent skill pack that statically reviews ABAP source — performance anti-patterns, Clean Core violations, and RAP (RESTful ABAP Programming Model) artifact quality — and produces verifiable, file:line-referenced report artifacts. No SAP system required: every skill operates on source text (`.abap`/`.ddls`/`.bdef`) read straight off disk or fetched over the network, never against a live system. Built as, and doubling as a demonstration of, the [AI Delivery Playbook](https://github.com/MikulasFrenak/ai-delivery-playbook) methodology — agents draft findings, humans decide what ships.

## Structure

- `skills/abap-review-performance.md` — the original skill: SELECT-in-loop, nested SELECTs, missing `FOR ALL ENTRIES` guards, internal-table anti-patterns. Operates on plain `.abap`.
- `skills/abap-review-clean-core.md` — direct writes to standard tables, implicit enhancements, modification of standard objects, non-released API usage. Mirrors the governance question SAP's own ABAP Test Cockpit Clean Core check covers, without needing a system. Operates on plain `.abap`.
- `skills/abap-review-rap.md` — RAP-specific quality: `SELECT *`/missing `WHERE` in CDS views, missing draft on transactional business objects, data access mixed into behavior-implementation logic instead of EML (`READ ENTITIES`/`MODIFY ENTITIES`), oversized implementation classes, missing tests. The only skill of the three that reads `.ddls`/`.bdef` as well as `.clas.abap` — CDS/BDEF syntax doesn't fit the other two skills' plain-statement model, which is why this is a separate skill rather than a mode of `abap-review-performance`.
- `skills/abap-review-naming.md`, `skills/abap-review-security.md`, `skills/abap-review-report.md` — planned, not yet built (see `AGENTS.md`'s skill table).
- `workflows/abap-code-review.md` — orchestrates whichever `abap-review-*` skills apply into one run and one aggregated report.
- `fixtures/` — the eval suite, one small hand-written file per known issue plus a clean counterpart per category:
  - `fixtures/*.abap` (flat, top-level) — the original 5 performance fixtures, covered by the deterministic checker below.
  - `fixtures/clean-core/*.abap` — 4 fixtures for `abap-review-clean-core`.
  - `fixtures/rap/*` — 7 fixtures for `abap-review-rap`, organized as matched scenario trios (`.ddls.asddls` + `.bdef.asbdef` + `.clas.abap`) rather than one file per finding, since that's how a RAP object actually ships.
- `scripts/check_fixtures.py` — deterministic, non-LLM regression test. Only covers `abap-review-performance`'s mechanical pattern-matching (globs `fixtures/*.abap` non-recursively, so `fixtures/clean-core/` and `fixtures/rap/` are invisible to it by construction, not by accident — see Known Issues). Runs in CI on every push/PR via `.github/workflows/check-fixtures.yml`.
- `examples/` — published reports from real runs:
  - `examples/fixtures-2026-07-20.md` — self-check against the original 5 performance fixtures.
  - `examples/cloud-abap-rap-353b5b1-2026-07-31.md` — first real external-target report, `abap-review-rap` against [SAP-samples/cloud-abap-rap](https://github.com/SAP-samples/cloud-abap-rap)'s `ProjectTP` business object (pinned commit, 3 High findings, verified by hand).
- `docs/adoption.md` — how a team would actually bring this into their SAP review process, not just run it once.

## Known Issues & TODOs

- [ ] No deterministic (non-LLM) fixture checker for `abap-review-clean-core` or `abap-review-rap` yet — `check_fixtures.py`'s statement-parser model doesn't fit CDS/BDEF syntax. Every finding for these two skills has been applied by hand so far; a real checker (or at least a lighter grep-based one for the more mechanical findings — direct table writes, `SELECT *`, missing `WHERE`) is worth building once the fixture set stabilizes.
- [ ] `abap-review-rap`'s first real report (`examples/cloud-abap-rap-353b5b1-2026-07-31.md`) covers one business object's three artifacts, not a full codebase run — scope was deliberately narrow for a first real-target pass given the lack of a deterministic backstop.
- [ ] `README.md` still describes "Milestone 1 in progress" and doesn't mention Clean Core/RAP at all — stale as of this doc.md; worth a pass once the RAP/Clean Core work settles rather than mid-flight.
- [ ] `abap-review-naming`, `abap-review-security`, `abap-review-report` remain planned, not built.
- [ ] The abapGit demo target from the original brief still hasn't been run for real (blocked by sandbox network access); the RAP/Clean Core work found a workaround via a connected browser instead of a local clone — worth revisiting whether that same approach unblocks the original abapGit run too, instead of waiting indefinitely for local network access.
