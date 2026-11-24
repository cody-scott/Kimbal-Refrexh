{#
  TYPE 4: ADD MINI-DIMENSION.
  The volatile banded attributes are split out into their own small
  dimension; the FACT table carries both keys. Here: sales by the
  demographics in force at the time of each sale.
#}
select
    f.date_key,
    f.customer_key,
    f.customer_demographics_key,
    d.age_band,
    d.income_band,
    d.loyalty_tier,
    f.extended_net_sales_amount
from {{ ref('fct_retail_sales') }} as f
inner join {{ ref('dim_customer_demographics') }} as d
    on d.customer_demographics_key = f.customer_demographics_key
