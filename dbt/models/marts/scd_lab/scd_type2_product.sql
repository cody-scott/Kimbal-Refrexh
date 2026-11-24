{#
  TYPE 2: ADD NEW ROW.
  A new row (with a new surrogate key) for every change; effective and
  expiration timestamps plus a current-row flag. Facts point to the version
  in force when they happened. This is the production dim_product, re-shown
  here so all the types sit side by side.
#}
select
    product_key, sku, brand, category, department, package_size,
    valid_from, valid_to, is_current
from {{ ref('dim_product') }}
where sku <> 'N/A'
