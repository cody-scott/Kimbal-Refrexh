{#
  TYPE 5: MINI-DIMENSION + TYPE 1 OUTRIGGER  (4 + 1 = 5).
  The base customer dimension carries the key of the customer's CURRENT
  mini-dimension row, overwritten (Type 1) as it changes. You can then report
  on current demographics without going through the fact table.
#}
with latest_profile as (
    select
        c.customer_id,
        f.customer_demographics_key
    from {{ ref('fct_retail_sales') }} as f
    inner join {{ ref('dim_customer') }} as c on c.customer_key = f.customer_key
    where c.customer_id not in ('N/A', 'ANON')
    qualify row_number() over (partition by c.customer_id order by f.transaction_ts desc) = 1
)

select
    c.customer_key,
    c.customer_id,
    c.customer_name,
    c.customer_city,
    c.is_current,
    lp.customer_demographics_key as current_customer_demographics_key  -- Type 1 outrigger
from {{ ref('dim_customer') }} as c
left join latest_profile as lp on lp.customer_id = c.customer_id
