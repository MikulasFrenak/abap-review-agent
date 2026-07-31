CLASS zbp_rap_fixture04 DEFINITION PUBLIC ABSTRACT FINAL FOR BEHAVIOR OF zc_rapfixture04travel.
  PRIVATE SECTION.
    METHODS validateDates FOR VALIDATE ON SAVE
      IMPORTING keys FOR travel ~ validateDates.
ENDCLASS.

"! Known issue: a direct SELECT against the persistence table inside
"! a validation method, instead of going through the object's own
"! EML (READ ENTITIES). Bypasses the RAP framework's own buffering
"! and consistency handling -- the whole point of the layering RAP
"! exists to enforce -- and duplicates logic the framework should
"! own.
"! Expected finding: abap-review-rap, High severity, line 19.

CLASS zbp_rap_fixture04 IMPLEMENTATION.
  METHOD validateDates.
    DATA lt_travel TYPE TABLE OF ztravel_fixture.

    SELECT * FROM ztravel_fixture
      INTO TABLE lt_travel
      FOR ALL ENTRIES IN keys
      WHERE travel_id = keys-travel_id.

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
