select
    sku,
    changed_at,
    lower(attribute_name) as attribute_name,
    old_value,
    new_value
from {{ ref('raw_product_changes') }}
