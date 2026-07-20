# abap-review-agent — Agent Guide

Agent guide for this repo, adapted from [`ai-delivery-playbook`](https://github.com/MikulasFrenak/ai-delivery-playbook). Any AI coding tool (Claude Code, Codex, Copilot, Cursor, Aider) should read this before exploring code or writing a plan.

See `abap-review-agent-brief.md`-derived scope below for the product intent. This file is process/conventions only.

---

## What this is

An agent skill pack that reviews ABAP source code — naming conventions, performance anti-patterns, security issues — and produces verifiable report artifacts (file:line findings, severity-ranked). No SAP system required: review is pure static text analysis over `.abap` source files, run against real open-source ABAP (abapGit) for a public, reproducible demo.

Agents draft findings. Humans decide what's real and what ships. No auto-fixes in v1.

---

## Repo Layout

```
/skills           # prompt-skills, one per review dimension (see Skills table below)
/workflows         # abap-code-review.md — orchestrates skills into one run
/fixtures          # small hand-written ABAP files with known, labeled issues — the eval suite
/examples          # published reports from real runs (e.g. against abapGit) — real findings, real file:line refs
/vendor            # pinned external ABAP source to review (e.g. abapGit at a fixed commit) — gitignored, cloned locally per the Setup section below
/scripts           # check_fixtures.py — deterministic (non-LLM) regression test for the mechanical part of abap-review-performance, run in CI
/.github/workflows # check-fixtures.yml — runs scripts/check_fixtures.py on every push/PR, free (no API key, no LLM call)
```

**Testing.** `python3 scripts/check_fixtures.py fixtures/` is the automated test suite — it re-implements the mechanical pattern-matching from `skills/abap-review-performance.md` Step 2 (no LLM involved) and checks it against each fixture's own "Expected finding(s): ... line(s) N" header comment. Run it after touching any fixture or changing the skill's detection logic; CI runs it on every push/PR. It is deliberately *not* a replacement for the skill itself — the skill's judgment calls (severity based on table size, context-aware false-positive filtering) aren't and can't be fully captured by a regex script. It exists to catch mechanical regressions fast and free, not to validate the agent's judgment.

---

## Stack Decisions

- No build, no runtime dependency on an SAP system. Skills are markdown prompt-files (playbook convention) that instruct an AI agent how to read `.abap` files, pattern-match anti-patterns, and produce a structured report (Markdown/JSON).
- Demo/eval target: [abapGit](https://github.com/abapGit/abapGit) — large, real, respected open-source ABAP codebase. Run against a **pinned commit** so results are reproducible by anyone who clones this repo.
- Reports are the product: every run must be independently verifiable — a stranger clones this repo, runs the workflow, gets the same findings.

---

## Branching & Commits

Personal project, not ticket-tracked — same convention as `family-trails-eu`:

```
feature/short-kebab-desc   # new functionality
bugfix/short-kebab-desc    # broken behaviour / failing tests
chore/short-kebab-desc     # deps, refactor, config
trivial/short-kebab-desc   # tooling, docs, config
```

One working branch until merge — don't fragment small related changes across branches; merge-conflict risk isn't worth it on a solo project.

Commit format:
```
Summary (imperative, max 72 chars)

- What changed and why
- Non-obvious decisions
```

`main` is never committed to directly. Squash-merge PRs, auto-delete source branch after merge.

---

## Skills

Copied/adapted from the playbook pattern — see `ai-delivery-playbook/skills/` for the reference implementations and frontmatter convention (`name`, `disable-model-invocation: true`, `description`). **Never auto-invoke a skill from its description alone** — only run when explicitly invoked via its slash command, same policy as every other repo in this ecosystem.

| Skill | When to use |
|---|---|
| `abap-review-performance` | SELECT-in-loop, nested SELECTs, missing FOR ALL ENTRIES guards, internal-table anti-patterns |
| `abap-review-naming` | Naming conventions in the spirit of SAP's public [Clean ABAP](https://github.com/SAP/styleguides/blob/main/clean-abap/CleanABAP.md) guide, Hungarian notation consistency, obsolete statements *(planned)* |
| `abap-review-security` | Dynamic SQL, AUTHORITY-CHECK gaps, hardcoded credentials *(planned)* |
| `abap-review-report` | Aggregates findings from the other skills into one structured, severity-ranked report artifact *(planned)* |
| `abap-code-review` (workflow) | Point at a repo/folder → run the skills above → human-verifiable report with file:line references |

## MCP Invocation Policy

Never call any MCP tool automatically — only when explicitly requested or as part of a skill's documented flow.

## Research Before Implementing

For any non-trivial task: search for current best practices first, identify 2–3 approaches with trade-offs, recommend one and check it against this file's conventions, then wait for explicit go-ahead before writing code.

---

## Public Repo Hygiene

This repo is public from day one. Never commit:
- Personal file-system paths or personal email addresses
- Any credentials, tokens, or API keys — none should be needed for this project
- Anything proprietary from a client/employer codebase — only public, open-source ABAP (abapGit) is used as a review target

Run `/public-repo-check` before every push (copy the skill from `ai-delivery-playbook/skills/public-repo-check.md` when ready).

---

## Setup

1. `python3 scripts/check_fixtures.py fixtures/` — no dependencies beyond Python 3 stdlib, works immediately after cloning.
2. To run the real demo target (abapGit) rather than just the eval fixtures — needs a machine with normal internet access, not a network-restricted sandbox:
   ```bash
   git clone https://github.com/abapGit/abapGit.git vendor/abapgit
   cd vendor/abapgit && git rev-parse HEAD   # record this SHA in the report header — it's what makes the report reproducible
   ```
3. Run the `/abap-code-review` workflow against `vendor/abapgit/src` (or the relevant subpath) with an AI coding agent (Claude Code or similar) that has read this file and the skill files under `skills/`.
4. Verify a sample of findings by hand before publishing, then save the report under `examples/abapgit-<short-sha>-<date>.md`.

---

## Success Criteria (from the brief)

- A stranger can clone this repo, run the workflow, and get the same report
- At least one real conversation started because of it
- Verified honestly — document the false-positive rate rather than overclaiming accuracy
