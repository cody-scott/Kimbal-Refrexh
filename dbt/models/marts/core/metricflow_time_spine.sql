-- Day-grain time spine required by the dbt Semantic Layer (MetricFlow).
-- Kept separate from dim_date because the spine must not contain special rows.
select full_date as date_day
from {{ ref('dim_date') }}
where date_key > 0
