-- Staging: one row per product as the source system has it right now.
-- Staging models rename, cast and clean. They do NOT apply dimensional logic.
select
    sku,
    trim(product_name)          as product_name,
    trim(brand)                 as brand,
    trim(subcategory)           as subcategory,
    trim(category)              as category,
    trim(department)            as department,
    package_size,
    list_price,
    standard_cost,
    updated_at
from {{ ref('raw_products') }}
