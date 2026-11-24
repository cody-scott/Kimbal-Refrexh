-- SHRUNKEN ROLLUP DIMENSION of dim_product at the category grain (current hierarchy).
select distinct
    {{ dbt_utils.generate_surrogate_key(['category', 'department']) }} as product_category_key,
    category,
    department
from {{ ref('dim_product') }}
where is_current
