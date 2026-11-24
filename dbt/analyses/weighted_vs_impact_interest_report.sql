-- Multivalued bridge: weighted (ties to total) vs impact (double counts) reporting.
select
    i.interest_name,
    sum(f.extended_net_sales_amount * b.weighting_factor) as weighted_net_sales,
    sum(f.extended_net_sales_amount)                      as impact_net_sales
from {{ ref('fct_retail_sales') }} f
join {{ ref('dim_customer') }} c              on c.customer_key = f.customer_key
join {{ ref('bridge_customer_interest') }} b  on b.customer_durable_key = c.customer_durable_key
join {{ ref('dim_interest') }} i              on i.interest_key = b.interest_key
group by all
order by weighted_net_sales desc
