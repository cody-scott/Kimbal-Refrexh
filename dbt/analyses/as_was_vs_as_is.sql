-- Type 2 vs Type 7 reporting on the same fact table.
-- SKU-2004 (Wool Hiking Socks) moved from "Footwear" to "Socks & Accessories" on 2025-03-01.
select
    'as was (Type 2 join)' as perspective,
    p.category,
    sum(f.extended_net_sales_amount) as net_sales
from {{ ref('fct_retail_sales') }} f
join {{ ref('dim_product') }} p on p.product_key = f.product_key
where p.sku = 'SKU-2004'
group by all

union all

select
    'as is (Type 7 durable-key join)',
    c.current_category,
    sum(f.extended_net_sales_amount)
from {{ ref('fct_retail_sales') }} f
join {{ ref('scd_type7_product_current') }} c on c.product_durable_key = f.product_durable_key
where c.sku = 'SKU-2004'
group by all
