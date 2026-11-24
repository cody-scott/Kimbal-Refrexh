-- "Which products were on promotion but did not sell?"
-- The classic factless-fact question: coverage MINUS activity.
-- Compile with `dbt compile -s promoted_products_that_did_not_sell` and run in Snowflake.
with promoted as (
    select date_key, product_key, store_key, promotion_key
    from {{ ref('fct_promotion_coverage') }}
),
sold as (
    select distinct date_key, product_key, store_key, promotion_key
    from {{ ref('fct_retail_sales') }}
)

select
    pr.promo_name,
    p.product_name,
    s.store_name,
    count(*) as days_promoted_without_a_promoted_sale
from (select * from promoted minus select * from sold) as unsold
join {{ ref('dim_promotion') }} as pr on pr.promotion_key = unsold.promotion_key
join {{ ref('dim_product') }}   as p  on p.product_key   = unsold.product_key
join {{ ref('dim_store') }}     as s  on s.store_key     = unsold.store_key
group by all
order by days_promoted_without_a_promoted_sale desc
