"! Clean counterpart to fixtures 01-02: explicit field list (no `{ *
"! }`), and a real WHERE clause backing the "Open" in the view's own
"! name. Expected findings: none.
@AbapCatalog.sqlViewName: 'ZRAPFIX00'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'RAP fixture 00 -- clean Open Travels view'
define view entity ZC_RapFixture00OpenTravels
  as select from ztravel_fixture
  where overall_status = 'O'
{
  key travel_id,
      customer_id,
      begin_date,
      end_date,
      overall_status,
      total_price
}
