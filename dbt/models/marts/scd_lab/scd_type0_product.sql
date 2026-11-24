{#
  TYPE 0: RETAIN ORIGINAL.
  The attribute never changes once set: "original category" means the category
  the product launched in, forever. Here: the value from the FIRST version.
#}
select
    sku,
    category    as original_category,
    department  as original_department,
    brand       as original_brand
from {{ ref('int_product_versions') }}
where version_number = 1
