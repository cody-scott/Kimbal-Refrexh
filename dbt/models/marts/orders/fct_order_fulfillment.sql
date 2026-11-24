{#
  ORDER FULFILLMENT — accumulating snapshot fact table.

  Grain: one row per web ORDER, covering its whole life:
  placed -> shipped -> delivered -> (returned).

  Each run rebuilds the current state of every order. Milestones that have
  not happened yet point at the date dimension's "Not Yet Happened" row (-2).
#}

with orders as (
    select * from {{ ref('stg_cascade__web_orders') }}
),
order_totals as (
    select
        order_number,
        sum(order_quantity)          as order_quantity,
        sum(net_order_amount_usd)    as net_order_amount_usd
    from {{ ref('fct_order_lines') }}
    group by order_number
)

select
    {{ date_key('o.order_date') }}                         as order_date_key,
    coalesce({{ date_key('o.shipped_date') }}, -2)         as ship_date_key,
    coalesce({{ date_key('o.delivered_date') }}, -2)       as delivery_date_key,
    coalesce({{ date_key('o.returned_date') }}, -2)        as return_date_key,
    {{ dim_key('c.customer_key') }}                         as customer_key,
    {{ dim_key('op.order_profile_key') }}                   as order_profile_key,
    o.order_number,
    o.order_status                                         as current_order_status,

    t.order_quantity,
    t.net_order_amount_usd,

    datediff(day, o.order_date, o.shipped_date)            as order_to_ship_lag_days,
    datediff(day, o.shipped_date, o.delivered_date)        as ship_to_delivery_lag_days,
    datediff(day, o.order_date, o.delivered_date)          as order_to_delivery_lag_days,

    1                                                      as order_count,
    iff(o.shipped_date is not null, 1, 0)                  as shipped_count,
    iff(o.delivered_date is not null, 1, 0)                as delivered_count,
    iff(o.returned_date is not null, 1, 0)                 as returned_count
from orders as o
left join order_totals as t
    on t.order_number = o.order_number
left join {{ ref('dim_customer') }} as c
    on  c.customer_id = o.customer_id
    and o.order_ts >= c.valid_from
    and o.order_ts <  c.valid_to
left join {{ ref('dim_order_profile') }} as op
    on  op.payment_method = o.payment_method
    and op.ship_method = o.ship_method
    and op.is_gift = o.is_gift
