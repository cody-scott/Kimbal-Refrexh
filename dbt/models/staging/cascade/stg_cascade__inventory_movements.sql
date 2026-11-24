select
    movement_id,
    movement_date,
    store_id,
    sku,
    upper(movement_type) as movement_type,
    quantity,
    unit_cost
from {{ ref('raw_inventory_movements') }}
