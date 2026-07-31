CLASS zcl_cc_fixture_01 DEFINITION PUBLIC.
  PUBLIC SECTION.
    METHODS approve_order IMPORTING iv_vbeln TYPE vbeln_va.
ENDCLASS.

"! Known issue: direct write to a standard SAP table (VBAK, no Z/Y
"! prefix) from a plain custom class -- not a RAP behavior
"! implementation's own SAVE method, so this is exactly the pattern
"! Clean Core exists to eliminate. Breaks silently on the next
"! upgrade if VBAK's structure or update logic changes.
"! Expected finding: abap-review-clean-core, High severity, line 20.

CLASS zcl_cc_fixture_01 IMPLEMENTATION.
  METHOD approve_order.
    DATA ls_vbak TYPE vbak.

    SELECT SINGLE * FROM vbak INTO ls_vbak WHERE vbeln = iv_vbeln.
    ls_vbak-abstk = 'A'.

    UPDATE vbak FROM ls_vbak.
  ENDMETHOD.
ENDCLASS.
