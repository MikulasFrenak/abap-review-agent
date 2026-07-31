---
name: abap-review-rap
disable-model-invocation: true
description: Scans ABAP RESTful Programming Model (RAP) artifacts — CDS views, behavior definitions (BDEF), and behavior implementation classes — for common quality issues — SELECT * in CDS views, missing draft handling on transactional business objects, behavior-implementation classes mixing data access with business logic, and oversized/undocumented artifacts. Produces a severity-ranked, file:line-referenced list of findings. Report-only. NEVER auto-invoke — only run when the user explicitly types /abap-review-rap or as a step inside the abap-code-review workflow.
---

# abap-review-rap — RAP Artifact Quality Scan

## Overview

Scans a RAP business object's artifacts — the CDS view (`.ddls`), behavior definition (`.bdef`), and behavior implementation class (`.clas.abap`) — for issues specific to the RESTful ABAP Programming Model rather than classic ABAP. RAP is SAP's strategic model for cloud-ready, Fiori-enabled custom development; most of what makes a RAP object "good" or "bad" isn't captured by `abap-review-performance`'s loop/SELECT patterns, because a RAP object's logic is split declaratively (CDS annotations, BDEF operations) rather than living entirely in procedural code.

Same report-only, human-verifies-the-call posture as every other skill in this pack.

**Why this is a separate skill from `abap-review-performance` and `abap-review-clean-core`**: those two both operate purely on `.abap` text and can lean on statement-level parsing (loop/select tracking). RAP review has to reason across three different artifact types with three different syntaxes — a CDS view definition, a declarative behavior definition, and an ABAP OOP class — so the scope, the file types in play, and the kind of judgment required are genuinely different work, not a variation of the same pattern.

---

## Workflow

### Step 1: Confirm Scope

Same as the other `abap-review-*` skills, plus one RAP-specific question: **which artifact types are in scope for this run** — CDS views only, behavior definitions only, behavior implementation classes only, or all three for a given business object? A RAP object typically ships as a matched set (root CDS view + BDEF + implementation class, often plus a projection view/service definition), so a full review usually wants all three read together, not independently — a finding in the implementation class often only makes sense once you've read the BDEF it implements.

### Step 2: Scan for Issues

**In the CDS view (`.ddls`):**

1. **`SELECT *` instead of an explicit field list** — pulls every column of the underlying table/view, including ones the consuming app never uses; also silently changes shape on a schema change instead of failing loudly.
   - Severity: **Medium**.
2. **Missing or overly broad `WHERE` clause** on a view meant to expose a filtered subset — infer intent from the view's name/annotations; a genuinely unfiltered root view is fine, one whose name implies filtering ("Open", "Active", "MyOrders") but has no `WHERE` is a real finding.
   - Severity: **Medium**.
3. **Deeply nested associations/joins without clear justification** — every additional association is another join the database has to plan; flag when a view chains associations several levels deep for fields that could come from a flatter path.
   - Severity: **Low**, note only.

**In the behavior definition (`.bdef`):**

4. **Transactional business object without draft enabled** (`with draft;` / `with draft table`). SAP's own guidance treats drafts as effectively required for multi-user transactional apps — without one, concurrent edits silently overwrite each other instead of surfacing a conflict.
   - Severity: **High** if the object's name/annotations clearly indicate a user-facing transactional app (order entry, request forms); **Medium** otherwise, since a purely internal/batch-oriented BO legitimately may not need drafts.
5. **`managed` behavior reimplementing what `unmanaged` exists for, or vice versa** — a `managed` BDEF with heavy custom `save`/validation logic fighting the framework's own CRUD handling is a sign `unmanaged` (or a managed BO with a saver class) would fit better; flag for a human read, this one needs real judgment, not a pattern match.
   - Severity: **Low**, note only — flag, don't assert.
6. **Missing validations/determinations on fields with obvious business constraints** (e.g. a date-range field pair with no cross-field validation) — infer from field naming, note as a possible gap rather than a confirmed one.
   - Severity: **Low**, note only.

**In the behavior implementation class (`.clas.abap`):**

7. **Data access mixed into behavior-logic methods** — direct `SELECT`/`MODIFY` against database tables inside a `determination`/`validation`/action method, instead of going through the object's own EML (`READ ENTITIES`/`MODIFY ENTITIES`) or a dedicated reuse layer. Breaks the RAP layering the whole model exists to enforce, and duplicates logic the framework should own.
   - Severity: **High**.
8. **Oversized class** — a behavior implementation class that's grown into one file handling many unrelated operations/validations instead of staying focused per SAP's own "keep it clean, apply SOLID" guidance. Use line count as a rough proxy (flag past ~500–800 lines as worth a look), but state plainly this is a heuristic, not a real complexity metric.
   - Severity: **Low**, note only.
9. **No corresponding ABAP Unit tests** for the behavior implementation class — check for a sibling test class (`<name>_test` or similar convention) or `FOR TESTING` methods; RAP logic without tests is a common, well-documented gap (behavior implementations without testing produce runtime errors that unit tests would have caught earlier).
   - Severity: **Medium**.

### Step 3: Produce the Report

Same format as the other skills, with one addition: group findings **by business object** (all three artifact types together) rather than by file, since that's how a reviewer actually reasons about a RAP object — "here's everything wrong with the SalesOrder BO," not three disconnected file lists.

### Step 4: Be Honest About Limits

- This skill reads CDS/BDEF/class *source text* — it does not activate anything in a real SAP system, so it cannot see runtime draft-table state, real service binding config, or actual annotation-driven UI behavior. A finding here is "the source looks like X," not "the running app does X."
- Items 5, 6, and 8 are explicitly judgment calls, marked Low/note-only for that reason — resist the temptation to inflate their severity just because they were easy to pattern-match.
- No deterministic (non-LLM) regression checker exists yet for this skill, unlike `abap-review-performance`'s `check_fixtures.py` — CDS/BDEF syntax doesn't fit that script's statement-parsing model, and building a real one is separate, follow-on work. State this plainly in any published report: findings here have had less mechanical cross-checking than the performance skill's.
