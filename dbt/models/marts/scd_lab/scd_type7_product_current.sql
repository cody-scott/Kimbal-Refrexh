{#
  TYPE 7: DUAL TYPE 1 AND TYPE 2 DIMENSIONS.
  The fact table carries BOTH the Type 2 surrogate key (product_key) and the
  durable key (product_durable_key). Join on product_key to dim_product for
  "as was"; join on product_durable_key to this current-row view for "as is".

  It's a view: nothing to maintain.
#}
{{ config(materialized='view') }}
select
    product_durable_key,
    sku,
    product_name,
    brand        as current_brand,
    category     as current_category,
    department   as current_department
from {{ ref('dim_product') }}
where is_current
