select
    order_number,
    line_number,
    sku,
    quantity,
    unit_price_local,
    discount_local,
    unit_cost_usd
from {{ ref('raw_web_order_lines') }}
