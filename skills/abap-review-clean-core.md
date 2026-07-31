---
name: abap-review-clean-core
disable-model-invocation: true
description: Scans ABAP source for Clean Core violations — direct writes to standard tables, implicit enhancements, modification of SAP standard objects, and use of non-released ("classic") APIs from custom code. Produces a severity-ranked, file:line-referenced list of findings. Report-only — never rewrites ABAP automatically. NEVER auto-invoke — only run when the user explicitly types /abap-review-clean-core or as a step inside the abap-code-review workflow.
---

# abap-review-clean-core — Clean Core Violation Scan

## Overview

Scans custom ABAP source for patterns that violate SAP's Clean Core principle: keep the standard system unmodified and upgrade-safe, and only extend it through released, stable extension points. This matters concretely, not abstractly — in SAP S/4HANA Cloud and the BTP ABAP environment, upgrades run automatically. Code that modifies the standard or calls a non-released internal API can break silently on the next upgrade, with no warning at write time. SAP's own ABAP Test Cockpit (ATC) ships a dedicated Clean Core check (Feb 2025) plus a Clean Core Levels / extensibility rating (A–D, Aug 2025) covering exactly this ground — this skill is a lighter-weight, no-system-required approximation of that same governance question, for the same report-only reason `abap-review-performance` exists: draft findings for a human to confirm, not a system-of-record.

Like `abap-review-performance`, this is pattern-based static analysis, not the real ATC. It cannot resolve whether a called API is actually on SAP's released list — it can only flag *suspicious* patterns worth a human (or the real ATC) checking.

---

## Workflow

### Step 1: Confirm Scope

Same as `abap-review-performance` Step 1 — which repo/folder or pinned commit, whole codebase or a subpath. Clean Core findings apply across `.abap` (classes, programs, function modules) — this skill does not need to parse CDS/BDEF syntax; that's `abap-review-rap`'s job.

### Step 2: Scan for Violations

**1. Direct writes to non-custom tables**
`INSERT`/`UPDATE`/`MODIFY`/`DELETE` statements (not `MODIFY ... FROM TABLE` on a custom `Z`/`Y` table) targeting a standard SAP table (naming heuristic: no `Z`/`Y` prefix, e.g. `VBAK`, `MARA`, `BKPF`) from outside a RAP behavior implementation class. This is the single highest-risk Clean Core violation category — SAP's own guidance places it in the top tier of technical debt.
- Severity: **High**, always.
- Exception: writes inside a RAP behavior-implementation `SAVE`/`MODIFY` method targeting the object's own persistence are expected and not a finding — read the surrounding class context before flagging.

**2. Implicit enhancements**
`ENHANCEMENT-POINT` / `ENHANCEMENT-SECTION` usage, or any code physically inside an enhancement implementation that isn't a released BAdI. Implicit enhancements inject custom code directly into SAP standard execution paths — invisible to the standard's own code, and a common source of silent upgrade breakage.
- Severity: **High**, always.

**3. Modification of standard objects**
Any custom code physically inside a namespace/package that isn't `Z`/`Y` (i.e. editing SAP-delivered objects directly, "modification" in SAP's own terminology — access keys, SSCR). Grep for file paths / package headers outside custom namespaces containing non-trivial diffs from a known-standard baseline; when the target is a git clone, a package-naming check is usually sufficient without a real baseline diff.
- Severity: **High**, always — this is the exact pattern Clean Core exists to eliminate.

**4. Non-released ("classic") API usage**
Calls from custom code (`Z`/`Y` namespace) to a standard function module, class, or interface that is a well-known *internal* SAP API rather than a released one — e.g. direct calls into internal FI/CO posting function modules, undocumented internal classes, or direct table access via `SELECT` on a standard table's underlying DB table instead of a released CDS view/API. This mirrors SAP's own ATC "Usage of APIs" check, which verifies custom code only consumes released interfaces, classes, function modules, CDS views, and DDIC objects.
- Severity: **Medium** by default — flag for human/real-ATC confirmation, since this skill cannot check SAP's actual release-status registry. **High** if the call is to a well-known internal-only object (heuristic: no public API documentation exists, or the object name matches a documented "do not call directly" pattern).
- Be honest in the report: this category has the highest false-positive risk of the four, because "is this API released" is not something static text analysis alone can answer with certainty.

### Step 3: Produce the Report

Same structured Markdown format as `abap-review-performance` Step 3 (severity-grouped, file:line, pattern, why, suggested direction). Suggested direction here typically points at the released alternative where one is documented (e.g. "use the released CDS view/API instead of direct table access") rather than a generic "fix this."

### Step 4: Be Honest About Limits

- This is not the real ABAP Test Cockpit and does not have access to SAP's actual API release-status registry — category 4 findings are the weakest of the four and need the most human verification.
- "Standard table" / "custom namespace" detection is a naming heuristic (`Z`/`Y` prefix), not a real system lookup — a codebase with unusual naming conventions will produce noise.
- Like `abap-review-performance`, state the checked-sample verification rate in any published report rather than overclaiming accuracy.
