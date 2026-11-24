{#
  TYPE 6: ADD TYPE 1 ATTRIBUTES TO A TYPE 2 DIMENSION  (1 + 2 + 3 = 6).
  Each version keeps its historical value (Type 2) AND carries the current
  value, overwritten on every row (Type 1). One join answers both
  "as it was" and "as it is now".
#}
select
    v.product_key,
    v.sku,
    v.category                as historical_category,   -- Type 2
    cur.category              as current_category,      -- Type 1, same on all versions
    v.department              as historical_department,
    cur.department            as current_department,
    v.valid_from,
    v.valid_to,
    v.is_current
from {{ ref('dim_product') }} as v
inner join {{ ref('dim_product') }} as cur
    on  cur.sku = v.sku
    and cur.is_current
where v.sku <> 'N/A'
