CLASS zbp_rap_fixture00 DEFINITION PUBLIC ABSTRACT FINAL FOR BEHAVIOR OF zc_rapfixture00opentravels.
  PRIVATE SECTION.
    METHODS validateDates FOR VALIDATE ON SAVE
      IMPORTING keys FOR travel ~ validateDates.
ENDCLASS.

"! Clean counterpart to fixture 04: reads via the object's own EML
"! (READ ENTITIES) instead of a direct SELECT against the
"! persistence table -- goes through RAP's own buffering and
"! consistency handling rather than bypassing it. Expected findings:
"! none.

CLASS zbp_rap_fixture00 IMPLEMENTATION.
  METHOD validateDates.
    READ ENTITIES OF zc_rapfixture00opentravels IN LOCAL MODE
      ENTITY travel
        FIELDS ( begin_date end_date )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_travel).

    LOOP AT lt_travel INTO DATA(ls_travel).
      IF ls_travel-begin_date > ls_travel-end_date.
        APPEND VALUE #( %tky               = ls_travel-%tky
                         %msg              = new_message( id       = 'ZRAP_FIXTURE'
                                                           number   = '001'
                                                           severity = if_abap_behv_message=>severity-error ) )
               TO reported-travel.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
