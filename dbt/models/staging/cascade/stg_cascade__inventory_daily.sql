select
    snapshot_date,
    store_id,
    sku,
    quantity_on_hand,
    unit_cost,
    unit_list_price
from {{ ref('raw_inventory_daily') }}
