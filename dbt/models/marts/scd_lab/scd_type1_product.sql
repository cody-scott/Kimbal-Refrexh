{#
  TYPE 1: OVERWRITE.
  One row per product, current values only. History is lost: last year's
  sales now roll up under this year's category.
#}
select
    {{ dbt_utils.generate_surrogate_key(['sku']) }} as product_key,
    sku,
    product_name,
    brand,
    category,
    department,
    package_size
from {{ ref('stg_cascade__products') }}
