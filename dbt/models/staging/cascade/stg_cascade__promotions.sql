select
    promo_code,
    promo_name,
    price_reduction_type,
    ad_type,
    display_type,
    coupon_type,
    start_date,
    end_date
from {{ ref('raw_promotions') }}
