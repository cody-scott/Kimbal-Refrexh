-- Allocated header shipping must sum back to the header charge on every order.
select o.order_number
from {{ ref('stg_cascade__web_orders') }} o
join (
    select order_number, sum(allocated_shipping_amount_local) as allocated
    from {{ ref('fct_order_lines') }}
    group by order_number
) l on l.order_number = o.order_number
where abs(l.allocated - o.shipping_charge_local) > 0.001
