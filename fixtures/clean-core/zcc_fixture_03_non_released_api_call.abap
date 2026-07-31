CLASS zcl_cc_fixture_03 DEFINITION PUBLIC.
  PUBLIC SECTION.
    METHODS get_material_stock
      IMPORTING iv_matnr        TYPE matnr
      RETURNING VALUE(rv_stock) TYPE mard-labst.
ENDCLASS.

"! Known issue: direct SELECT against a standard table's underlying
"! DB table (MARD) instead of going through a released CDS view/API
"! for material stock. This skill cannot confirm MARD access is
"! actually unreleased (no registry lookup) -- flagged Medium, for
"! human/real-ATC confirmation, per abap-review-clean-core's own
"! stated limits on this category.
"! Expected finding: abap-review-clean-core, Medium severity, line 18.

CLASS zcl_cc_fixture_03 IMPLEMENTATION.
  METHOD get_material_stock.
    SELECT SINGLE labst FROM mard
      INTO rv_stock
      WHERE matnr = iv_matnr.
  ENDMETHOD.
ENDCLASS.
