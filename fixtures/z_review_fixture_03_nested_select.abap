REPORT z_review_fixture_03.

"! Known issue: nested SELECT ... ENDSELECT loops.
"! The outer SELECT is already a database loop; the inner SELECT
"! turns it into a row-by-row N+1 pattern, worse than fixture 01.
"! Expected finding: abap-review-performance, High severity, line 12.

DATA: ls_vbak TYPE vbak,
      ls_vbap TYPE vbap.

SELECT * FROM vbak INTO ls_vbak.
  SELECT * FROM vbap INTO ls_vbap WHERE vbeln = ls_vbak-vbeln.
  ENDSELECT.
ENDSELECT.
