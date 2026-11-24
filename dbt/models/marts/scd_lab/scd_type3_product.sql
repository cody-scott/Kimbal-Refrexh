{#
  TYPE 3: ADD NEW ATTRIBUTE.
  Keep one row per product, but store the prior value in an extra column.
  Supports "show me sales under the old and new category side by side"
  (an alternate reality), for one prior value only.
#}
with ranked as (
    select
        sku,
        category,
        lag(category) over (partition by sku order by valid_from) as prior_category,
        valid_from,
        is_current
    from {{ ref('int_product_versions') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['sku']) }} as product_key,
    sku,
    category                                          as current_category,
    coalesce(prior_category, category)                as prior_category,
    iff(prior_category is null, null, valid_from)     as category_changed_at
from ranked
where is_current
