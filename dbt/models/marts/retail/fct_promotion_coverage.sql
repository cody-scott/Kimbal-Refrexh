{#
  PROMOTION COVERAGE — factless fact table (coverage).

  Grain: one row per product per store per day that the product was on
  promotion. There are no measures: the row's existence IS the fact.

  Why it exists: the sales fact only records what SOLD. To answer
  "which promoted products did NOT sell?" you need a record of what was
  eligible, then subtract what sold (see analyses/promoted_products_that_did_not_sell.sql).
#}
select
    {{ date_key('c.coverage_date') }}           as date_key,
    {{ dim_key('p.product_key') }}               as product_key,
    {{ dim_key('s.store_key') }}                 as store_key,
    {{ dim_key('pr.promotion_key') }}            as promotion_key,
    1                                            as promotion_count  -- optional "counter" fact for convenient SUM()
from {{ ref('stg_cascade__promotion_coverage') }} as c
left join {{ ref('dim_product') }} as p
    on  p.sku = c.sku
    and c.coverage_date::timestamp_ntz >= p.valid_from
    and c.coverage_date::timestamp_ntz <  p.valid_to
left join {{ ref('dim_store') }} as s
    on s.store_number = c.store_id
left join {{ ref('dim_promotion') }} as pr
    on pr.promo_code = c.promo_code
