REPORT zcc_fixture_02.

"! Known issue: custom logic injected via an implicit enhancement
"! point instead of a released BAdI/enhancement spot. Invisible to
"! the standard program's own source, and a classic silent-breakage
"! risk on upgrade -- the standard object doesn't know custom code
"! is running inside it.
"! Expected finding: abap-review-clean-core, High severity, line 13.

START-OF-SELECTION.
  WRITE: / 'Standard processing here'.

  ENHANCEMENT-POINT zcc_fixture_02_ep_01 SPOTS zcc_fixture_02_spot.
* Custom logic silently injected into a standard execution path --
* should be a released BAdI implementation instead.

  WRITE: / 'More standard processing'.
