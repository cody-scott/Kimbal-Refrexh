{#
  SHRUNKEN ROLLUP DIMENSION of dim_date: one row per month.
  Kimball: aggregate fact tables need dimensions at THEIR grain, built as
  conformed subsets of the base dimension: same column names, same
  values, so drill-across between grains still works.
#}
select distinct
    calendar_year * 100 + month_number             as month_key,
    year_month,
    month_start_date,
    month_end_date,
    month_number,
    month_abbr,
    calendar_quarter,
    calendar_year_quarter,
    calendar_year,
    fiscal_year,
    fiscal_quarter,
    fiscal_year_quarter
from {{ ref('dim_date') }}
where date_key > 0
