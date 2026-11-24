-- DRILL ACROSS: compare two business processes through CONFORMED dimensions.
-- Kimball rule: aggregate each fact table SEPARATELY to the common grain,
-- then join the result sets on the conformed attributes. Never join two
-- fact tables directly at their atomic grain (fan-out = wrong numbers).
with sales as (
    select d.year_month, p.category, sum(f.sales_quantity) as units_sold
    from {{ ref('fct_retail_sales') }} f
    join {{ ref('dim_date') }} d    on d.date_key = f.date_key
    join {{ ref('dim_product') }} p on p.product_key = f.product_key
    group by all
),
inventory as (
    -- semi-additive: average daily on-hand within the month, not a sum
    select year_month, category, avg(daily_units) as avg_daily_units_on_hand
    from (
        select d.year_month, d.full_date, p.category, sum(f.quantity_on_hand) as daily_units
        from {{ ref('fct_inventory_daily_snapshot') }} f
        join {{ ref('dim_date') }} d    on d.date_key = f.date_key
        join {{ ref('dim_product') }} p on p.product_key = f.product_key
        group by all
    )
    group by all
)

select
    coalesce(s.year_month, i.year_month) as year_month,
    coalesce(s.category, i.category)     as category,
    s.units_sold,
    i.avg_daily_units_on_hand,
    round(s.units_sold / nullif(i.avg_daily_units_on_hand, 0), 2) as turns_in_month
from sales s
full outer join inventory i
    on i.year_month = s.year_month and i.category = s.category
order by 1, 2
