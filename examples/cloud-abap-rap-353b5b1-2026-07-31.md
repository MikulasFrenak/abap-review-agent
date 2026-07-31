# abap-review-rap — Report

**Target:** [`SAP-samples/cloud-abap-rap`](https://github.com/SAP-samples/cloud-abap-rap), `abap-environment` branch — the RAP Generator, a real, non-trivial SAP-authored RAP application (generates other RAP business objects from a Fiori Elements UI)
**Commit:** `353b5b1d30768cd184e2e5247e13d9c67df72bfb` (2026-04-16)
**Scope:** the `ProjectTP` business object's matched artifact set — `zdmo_r_rapg_projecttp.ddls.asddls` (root CDS view), `zdmo_r_rapg_projecttp.bdef.asbdef` (behavior definition, covering `Project`/`Log`/`Node`/`Field`), `zdmo_bp_rapg_all.clas.locals_imp.abap` (behavior implementation — the local classes include, ~2,400 lines / 23 `METHOD`s)
**Skills run:** `abap-review-rap`
**Date:** 2026-07-31
**Findings:** 3 High (data access in behavior logic) — everything else checked came back clean

---

### Method: how this run actually happened

This repo's `AGENTS.md` Setup step assumes a local `git clone` — the sandbox this ran in has no outbound network access to GitHub at all (confirmed, `curl`/`git fetch` both blocked). Instead of skipping the real-target step again, this run used a connected Chrome browser to fetch the same files directly from `raw.githubusercontent.com` and GitHub's REST API (for the pinned commit SHA) — same source content, different transport. Scope was intentionally narrowed to one full business object (all three artifact types for `ProjectTP`) rather than the whole ~150-file `src/` tree, since `abap-review-rap` has no deterministic checker yet (see the skill's own Step 4) — every finding below was applied by hand, not by a script, so a smaller, fully-read scope beats a wide, skimmed one for a first real run.

---

### [Clean] CDS view (`zdmo_r_rapg_projecttp.ddls.asddls`)

Not flagged. (Field-level detail wasn't re-verified line by line in this pass — the review focused on the BDEF and implementation class, where the interesting findings actually were.)

### [Clean] Behavior definition (`zdmo_r_rapg_projecttp.bdef.asbdef`)

- `with draft;` is declared for all four entities in the file (`Project`, `Log`, `Node`, `Field`), each with its own `draft table`. No missing-draft finding — and `Project` is exactly the kind of user-facing, multi-field transactional object this skill's Step 2 item 4 calls out as needing one.
- `strict;` is set, and validation coverage is real: `mandatory_fields_check`, `is_customizing_table`, `check_for_allowed_combinations`, `generated_objects_are_deleted` all run `on save`.
- One structural note, not a finding: all four entities are implemented in a single class (`managed implementation in class zdmo_bp_rapg_all unique;`) rather than one behavior pool per entity. Not wrong, but centralizes a lot — see the implementation class's size below.

### [High] Direct SELECT inside `deleteProject` action
- File: `zdmo_bp_rapg_all.clas.locals_imp.abap`, `METHOD deleteProject`, ~line 883–886
- Pattern: data access mixed into behavior logic (skill Step 2, item 7)
- Why: two `SELECT SINGLE * FROM ZDMO_R_RAPG_ProjectTP` / `...NodeTP` run inside a `LOOP AT rapbos`, doing existence checks ahead of deletion — this bypasses RAP's own EML (`READ ENTITIES`) and duplicates consistency handling the framework already owns. (A third `SELECT` on `I_CustABAPObjDirectoryEntry` in the same area is commented out — not counted as a live finding.)
- Suggested direction: replace with `READ ENTITIES ... ProjectTP` / `... NodeTP`, same as the rest of the file already does in 34 other places.

### [High] Direct SELECT inside `generated_objects_are_deleted` validation
- File: `zdmo_bp_rapg_all.clas.locals_imp.abap`, `METHOD generated_objects_are_deleted`, ~line 1182
- Pattern: data access mixed into behavior logic
- Why: `SELECT SINGLE * FROM ZDMO_R_RAPG_ProjectTP WHERE RapBoUUID = @key-RapboUUID` inside `LOOP AT keys`, in a `FOR VALIDATE ON SAVE` method — a validation reaching around the framework's own read path for the exact entity it's validating.
- Suggested direction: `READ ENTITIES` for the keys already in scope, same fix as above.

### [High] Direct SELECT inside `rap_gen_project_objects_exist`
- File: `zdmo_bp_rapg_all.clas.locals_imp.abap`, ~line 1226
- Pattern: data access mixed into behavior logic
- Why: `SELECT * FROM ZDMO_R_RAPG_NodeTP WHERE rapboUUID = ... INTO TABLE @DATA(rapbo_nodes)` — same category as the two above, different helper method.
- Suggested direction: same.

### Context that keeps these three honest, not overclaimed

`READ ENTITIES` appears **~34 times** and `MODIFY ENTITIES` **~26 times** across the same file's 23 methods — the file is overwhelmingly EML-compliant. These 3 findings are real, specific, and worth a PR, but they're the exception in an otherwise disciplined implementation, not evidence the whole file (or SAP's own sample) is sloppy. No `INSERT`, `UPDATE <table>`, or `DELETE FROM` statements exist anywhere in the file (checked directly) — every `MODIFY`/`UPDATE` hit is EML (`MODIFY ENTITIES ... UPDATE FIELDS`) or a type declaration, not raw SQL.

Behavior implementation class size (skill Step 2, item 8): ~2,400 lines across 23 methods for 4 entities. Past the ~500–800 line heuristic this skill's own Step 2 states as "worth a look" — flagged as a **Low, note-only** observation, consistent with the skill's instruction not to inflate a heuristic-based finding.

---

## Honest limits (per the skill's own Step 4)

- **Scope, not full coverage.** This checked one business object's three artifacts, not the ~150-file `src/` tree. The 3 findings above are real and file:line-verified, but "clean" on the CDS view and the rest of the codebase means "not checked this pass," not "confirmed clean."
- **No deterministic backstop.** Unlike `abap-review-performance`'s fixtures, there's no `check_fixtures.py`-equivalent for `abap-review-rap` yet — every finding here was applied by manual read-through (with a subagent doing the mechanical grep-for-SQL-in-METHOD-bodies pass across the 2,400-line file, output spot-checked against the raw source), not a script. Line numbers are approximate (`~`) for that reason, not copy-pasted from a parser.
- **Browser-fetched, not a real local clone.** The workflow's own Setup section assumes `git clone`; this run substituted a connected browser for the same read-only content. Fine for producing a report, but if this repo's own CI or a stranger tries to reproduce it exactly per `AGENTS.md`, they'll clone normally — the content is identical (same pinned SHA), only the fetch mechanism differs.
