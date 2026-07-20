REPORT z_review_fixture_02.

"! Known issue: FOR ALL ENTRIES without an emptiness guard.
"! If lt_keys is empty, the WHERE restriction is silently dropped
"! and the statement selects the entire VBAP table.
"! Expected finding: abap-review-performance, High severity, line 11.

DATA: lt_keys  TYPE TABLE OF vbak,
      lt_items TYPE TABLE OF vbap.

SELECT * FROM vbap
  INTO TABLE lt_items
  FOR ALL ENTRIES IN lt_keys
  WHERE vbeln = lt_keys-vbeln.
