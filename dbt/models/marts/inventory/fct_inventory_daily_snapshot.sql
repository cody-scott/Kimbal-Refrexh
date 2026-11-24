{{ config(cluster_by=['date_key']) }}
{#
  INVENTORY — periodic snapshot fact table.

  Grain: one row per product per store per DAY (end-of-day position).
  Dense: a row exists even when nothing moved, so "on hand" is always
  available for every day.

  quantity_on_hand is SEMI-ADDITIVE: it sums across stores and products,
  but NOT across days. Summing a week of daily balances is meaningless;
  use the period-end value or the average daily balance instead.
#}
select
    {{ date_key('i.snapshot_date') }}                    as date_key,
    {{ dim_key('p.product_key') }}                        as product_key,
    {{ dim_key('s.store_key') }}                          as store_key,
    i.snapshot_date,
    i.quantity_on_hand,                                   -- semi-additive
    i.quantity_on_hand * i.unit_cost                      as inventory_value_at_cost,        -- semi-additive
    i.quantity_on_hand * i.unit_list_price                as inventory_value_at_list_price   -- semi-additive
from {{ ref('stg_cascade__inventory_daily') }} as i
left join {{ ref('dim_product') }} as p
    on  p.sku = i.sku
    and i.snapshot_date::timestamp_ntz >= p.valid_from
    and i.snapshot_date::timestamp_ntz <  p.valid_to
left join {{ ref('dim_store') }} as s
    on s.store_number = i.store_id
