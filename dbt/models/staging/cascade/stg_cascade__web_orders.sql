-- Order header. Note the header-level shipping charge: it must be allocated
-- down to the line grain before it can live in the order-line fact table.
select
    order_number,
    customer_id,
    order_ts,
    order_ts::date                      as order_date,
    currency_code,
    payment_method,
    ship_method,
    is_gift = 'Y'                       as is_gift,
    shipping_charge                     as shipping_charge_local,
    shipped_date,
    delivered_date,
    returned_date,
    order_status
from {{ ref('raw_web_orders') }}
