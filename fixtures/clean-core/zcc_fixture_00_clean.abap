CLASS zcl_cc_fixture_00 DEFINITION PUBLIC.
  PUBLIC SECTION.
    METHODS log_custom_event
      IMPORTING iv_event_type TYPE zde_event_type.
ENDCLASS.

"! Clean counterpart to fixtures 01-03: same intent (persist a
"! change, extend standard behaviour, read reference data), written
"! without the Clean Core violations. Expected findings: none. This
"! fixture exists to catch false positives -- a skill that flags
"! this file is over-triggering.

CLASS zcl_cc_fixture_00 IMPLEMENTATION.
  METHOD log_custom_event.
    DATA ls_log TYPE zcc_event_log.

    " Custom Z-table, not a standard SAP table -- Clean Core has no
    " objection to a custom app owning and writing its own data.
    ls_log-event_type = iv_event_type.
    ls_log-created_at = utclong_current( ).

    INSERT zcc_event_log FROM ls_log.

    " Extension via a released BAdI, not an implicit enhancement.
    " (Illustrative call -- a real project would have a matching
    " BAdI definition/enhancement spot for zif_cc_event_badi.)
    zcl_cc_badi_handler=>get_instance( )->on_event_logged( ls_log ).
  ENDMETHOD.
ENDCLASS.
