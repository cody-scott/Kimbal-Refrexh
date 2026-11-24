{{ config(materialized='view') }}
-- Role-playing view of dim_date for the order-date role. See dim_ship_date.
select
    date_key            as order_date_key,
    full_date           as order_date,
    day_of_week_name    as order_day_of_week,
    year_month          as order_year_month,
    calendar_quarter    as order_calendar_quarter,
    calendar_year       as order_calendar_year,
    fiscal_year_quarter as order_fiscal_year_quarter,
    weekday_indicator   as order_weekday_indicator,
    holiday_indicator   as order_holiday_indicator
from {{ ref('dim_date') }}
