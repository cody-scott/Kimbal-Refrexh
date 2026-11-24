{#
  Promotion dimension: a "causal" dimension describing conditions believed
  to cause a sale. Kimball: sales with no promotion point at an explicit
  "No Promotion in Effect" row, not at NULL.
#}
select
    {{ dbt_utils.generate_surrogate_key(['promo_code']) }} as promotion_key,
    promo_code,
    promo_name,
    price_reduction_type,
    ad_type,
    display_type,
    coupon_type,
    start_date                                             as promotion_begin_date,
    end_date                                               as promotion_end_date
from {{ ref('stg_cascade__promotions') }}

union all

select
    {{ dbt_utils.generate_surrogate_key(["'NONE'"]) }},
    'NONE', 'No Promotion in Effect', 'No Price Reduction', 'No Ad',
    'No Display', 'No Coupon', null, null

union all

{{ unknown_member_row({
    'promotion_key': unknown_key(), 'promo_code': "'N/A'", 'promo_name': "'Unknown Promotion'",
    'price_reduction_type': "'Unknown'", 'ad_type': "'Unknown'", 'display_type': "'Unknown'",
    'coupon_type': "'Unknown'", 'promotion_begin_date': 'null', 'promotion_end_date': 'null',
}) }}
