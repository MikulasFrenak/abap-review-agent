"! Known issue: `{ * }` wildcard projection exposes every field of
"! the underlying table, including ones no consumer asked for, and
"! silently changes the view's shape on any schema change to
"! ztravel_fixture instead of failing loudly.
"! Expected finding: abap-review-rap, Medium severity, line 12.
@AbapCatalog.sqlViewName: 'ZRAPFIX01'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'RAP fixture 01 -- SELECT * anti-pattern'
define root view entity ZC_RapFixture01
  as select from ztravel_fixture
{
  *
}
