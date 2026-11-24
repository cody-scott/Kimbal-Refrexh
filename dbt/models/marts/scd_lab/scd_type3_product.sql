{#
  TYPE 3: ADD NEW ATTRIBUTE.
  Keep one row per product, but store the prior value in an extra column.
  Supports "show me sales under the old and new category side by side"
  (an alternate reality), for one prior value only.

  Careful: the prior value must come from the last version where the
  CATEGORY changed, not simply the previous version (which may have been
  opened by a change to some other attribute).
#}
with category_changes as (
    select
        sku,
        category,
        valid_from,
        lag(category) over (partition by sku order by valid_from) as previous_category
    from {{ ref('int_product_versions') }}
    qualify previous_category is distinct from category   -- first version, or a real category change
),

latest_change as (
    select *
    from category_changes
    qualify row_number() over (partition by sku order by valid_from desc) = 1
)

select
    {{ dbt_utils.generate_surrogate_key(['sku']) }}        as product_key,
    sku,
    category                                               as current_category,
    coalesce(previous_category, category)                  as prior_category,
    iff(previous_category is null, null, valid_from)       as category_changed_at
from latest_change
