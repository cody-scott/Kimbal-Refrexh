select
    coverage_date,
    store_id,
    sku,
    promo_code
from {{ ref('raw_promotion_coverage') }}
