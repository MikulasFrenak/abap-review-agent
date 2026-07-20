REPORT z_review_fixture_04.

"! Known issues: nested LOOP AT ... LOOP AT over two potentially
"! large internal tables (O(n x m)), plus a linear READ TABLE
"! inside the outer loop without BINARY SEARCH or a hashed/sorted
"! table type.
"! Expected findings: abap-review-performance, Medium severity,
"! lines 12 and 16.

DATA: lt_materials TYPE TABLE OF mara,
      lt_plants    TYPE TABLE OF marc,
      ls_material  TYPE mara,
      ls_plant     TYPE marc.

LOOP AT lt_materials INTO ls_material.
  LOOP AT lt_plants INTO ls_plant WHERE matnr = ls_material-matnr.
    " nested loop over two potentially large tables
  ENDLOOP.

  READ TABLE lt_plants INTO ls_plant WITH KEY matnr = ls_material-matnr.
ENDLOOP.
