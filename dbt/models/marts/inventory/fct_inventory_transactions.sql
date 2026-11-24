{#
  INVENTORY — transaction fact table.

  Grain: one row per inventory movement (receipt, sale, shrink).
  quantity_change is fully ADDITIVE: summing movements over any period
  gives the net change in on-hand for that period. Running-summing it
  from the beginning of time reproduces the periodic snapshot (expensive!
  which is exactly why Kimball also keeps the snapshot).
#}
select
    {{ date_key('m.movement_date') }}                    as date_key,
    {{ dim_key('p.product_key') }}                        as product_key,
    {{ dim_key('s.store_key') }}                          as store_key,
    {{ dbt_utils.generate_surrogate_key(['m.movement_type']) }} as inventory_movement_type_key,
    m.movement_id,                                        -- degenerate
    m.movement_type,
    m.quantity                                            as quantity_change,
    m.quantity * m.unit_cost                              as value_change_at_cost
from {{ ref('stg_cascade__inventory_movements') }} as m
left join {{ ref('dim_product') }} as p
    on  p.sku = m.sku
    and m.movement_date::timestamp_ntz >= p.valid_from
    and m.movement_date::timestamp_ntz <  p.valid_to
left join {{ ref('dim_store') }} as s
    on s.store_number = m.store_id
