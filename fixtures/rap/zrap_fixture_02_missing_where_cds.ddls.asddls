"! Known issue: the view's own name/label promise a filtered subset
"! ("open" orders only), but the select has no WHERE clause -- it
"! actually exposes every order regardless of status. A consumer
"! reading the name would reasonably assume filtering already
"! happened here.
"! Expected finding: abap-review-rap, Medium severity, line 11.
@AbapCatalog.sqlViewName: 'ZRAPFIX02'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'RAP fixture 02 -- Open Orders (missing WHERE)'
define view entity ZC_OpenOrdersFixture02
  as select from ztravel_fixture
{
  key travel_id,
      overall_status,
      total_price
}
