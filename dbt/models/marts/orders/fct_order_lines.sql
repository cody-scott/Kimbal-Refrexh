{#
  ORDER LINES — transaction fact table.

  Grain: one row per line on a web order.

  Patterns demonstrated
    * Role-playing dates: order_date_key and ship_date_key,
      both pointing at the one physical dim_date.
    * Junk dimension: order_profile_key.
    * Degenerate dimension: order_number (the "header" has no table of its own).
    * Allocated header facts: allocated_shipping_* (see int_order_lines_allocated).
    * Multiple currencies: every amount in the transaction (local) currency AND
      the standard reporting currency (USD), plus a currency dimension
      identifying the local currency.
#}

with lines as (
    select * from {{ ref('int_order_lines_allocated') }}
),
orders as (
    select * from {{ ref('stg_cascade__web_orders') }}
),
fx as (
    select * from {{ ref('stg_cascade__fx_rates') }} where to_currency = 'USD'
)

select
    {{ date_key('o.order_date') }}                                     as order_date_key,
    coalesce({{ date_key('o.shipped_date') }}, -2)                     as ship_date_key,
    {{ dim_key('p.product_key') }}                                      as product_key,
    {{ dim_key('c.customer_key') }}                                     as customer_key,
    {{ dim_key('op.order_profile_key') }}                               as order_profile_key,
    {{ dim_key('cur.currency_key') }}                                   as local_currency_key,
    {{ dim_key('st.store_key') }}                                       as store_key,  -- conformed: the Web Store

    o.order_number,                                                    -- degenerate
    l.line_number,                                                     -- degenerate

    -- Facts in transaction (local) currency
    l.quantity                                                         as order_quantity,
    l.gross_amount_local                                               as gross_order_amount_local,
    l.discount_local                                                   as discount_amount_local,
    l.gross_amount_local - l.discount_local                            as net_order_amount_local,
    l.allocated_shipping_local                                         as allocated_shipping_amount_local,

    -- Same facts in the standard reporting currency (USD), converted at the
    -- order-date rate. Storing both avoids a currency join in every query.
    round(l.gross_amount_local * fx.exchange_rate, 2)                  as gross_order_amount_usd,
    round(l.discount_local * fx.exchange_rate, 2)                      as discount_amount_usd,
    round((l.gross_amount_local - l.discount_local) * fx.exchange_rate, 2) as net_order_amount_usd,
    round(l.allocated_shipping_local * fx.exchange_rate, 2)            as allocated_shipping_amount_usd,
    l.quantity * l.unit_cost_usd                                       as extended_cost_usd
from lines as l
inner join orders as o
    on o.order_number = l.order_number
left join fx
    on  fx.rate_date = o.order_date
    and fx.from_currency = o.currency_code
left join {{ ref('dim_product') }} as p
    on  p.sku = l.sku
    and o.order_ts >= p.valid_from
    and o.order_ts <  p.valid_to
left join {{ ref('dim_customer') }} as c
    on  c.customer_id = o.customer_id
    and o.order_ts >= c.valid_from
    and o.order_ts <  c.valid_to
left join {{ ref('dim_order_profile') }} as op
    on  op.payment_method = o.payment_method
    and op.ship_method = o.ship_method
    and op.is_gift = o.is_gift
left join {{ ref('dim_currency') }} as cur
    on cur.currency_code = o.currency_code
left join {{ ref('dim_store') }} as st
    on st.store_number = 999
