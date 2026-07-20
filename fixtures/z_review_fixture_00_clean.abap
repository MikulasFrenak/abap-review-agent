REPORT z_review_fixture_00.

"! Clean counterpart to fixtures 01-04: same intent, written
"! without the anti-patterns. Expected findings: none. This fixture
"! exists to catch false positives — a skill that flags this file
"! is over-triggering.

DATA: lt_orders TYPE TABLE OF vbak,
      lt_items  TYPE TABLE OF vbap,
      lt_keys   TYPE TABLE OF vbak,
      lt_materials TYPE SORTED TABLE OF mara WITH UNIQUE KEY matnr,
      lt_plants    TYPE HASHED TABLE OF marc WITH UNIQUE KEY matnr,
      ls_material  TYPE mara,
      ls_plant     TYPE marc.

SELECT * FROM vbak INTO TABLE lt_orders WHERE vkorg = '1000'.

" Batched instead of SELECT-in-loop: single FOR ALL ENTRIES, guarded.
IF lt_orders IS NOT INITIAL.
  SELECT * FROM vbap
    INTO TABLE lt_items
    FOR ALL ENTRIES IN lt_orders
    WHERE vbeln = lt_orders-vbeln.
ENDIF.

" Same guard pattern for a second FOR ALL ENTRIES source.
IF lt_keys IS NOT INITIAL.
  SELECT * FROM vbap
    APPENDING TABLE lt_items
    FOR ALL ENTRIES IN lt_keys
    WHERE vbeln = lt_keys-vbeln.
ENDIF.

" Hashed/sorted tables with unique keys instead of nested LOOP AT / linear READ TABLE.
LOOP AT lt_materials INTO ls_material.
  READ TABLE lt_plants INTO ls_plant WITH TABLE KEY matnr = ls_material-matnr.
ENDLOOP.
