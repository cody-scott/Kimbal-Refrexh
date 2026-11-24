{{ config(materialized='view') }}
{#
  ROLE-PLAYING DIMENSION view.

  There is ONE physical date dimension. When a fact table has several date
  keys (order date, ship date...), each role gets a view with
  role-specific column names, so a query or BI tool joining both never
  confuses "month" with "month". It costs nothing: it's a view.
#}
select
    date_key            as ship_date_key,
    full_date           as ship_date,
    day_of_week_name    as ship_day_of_week,
    year_month          as ship_year_month,
    calendar_quarter    as ship_calendar_quarter,
    calendar_year       as ship_calendar_year,
    fiscal_year_quarter as ship_fiscal_year_quarter,
    weekday_indicator   as ship_weekday_indicator,
    holiday_indicator   as ship_holiday_indicator
from {{ ref('dim_date') }}
