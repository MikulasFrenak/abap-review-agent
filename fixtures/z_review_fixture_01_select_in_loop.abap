REPORT z_review_fixture_01.

"! Known issue: SELECT inside LOOP AT (N+1 pattern).
"! Expected finding: abap-review-performance, High severity, line 12.

DATA: lt_orders TYPE TABLE OF vbak,
      lt_items  TYPE TABLE OF vbap,
      ls_order  TYPE vbak.

SELECT * FROM vbak INTO TABLE lt_orders WHERE vkorg = '1000'.

LOOP AT lt_orders INTO ls_order.
  SELECT * FROM vbap
    APPENDING TABLE lt_items
    WHERE vbeln = ls_order-vbeln.
ENDLOOP.
