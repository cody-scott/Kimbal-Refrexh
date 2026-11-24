{#
  Type 2 history for products, rebuilt from the source change log.

  Written out longhand (rather than calling the scd2_from_change_log macro)
  so you can read every step. int_customer_versions does the same job with
  the macro.

  Tracked as Type 2: brand, category, department, package_size
  Treated as Type 1: product_name, subcategory, list_price, standard_cost
#}

with current_products as (
    select * from {{ ref('stg_cascade__products') }}
),

changes as (
    select *
    from {{ ref('stg_cascade__product_changes') }}
    where attribute_name in ('brand', 'category', 'department', 'package_size')
),

-- 1. Each moment a new version begins.
version_starts as (
    select sku, '1900-01-01'::timestamp_ntz as valid_from from current_products
    union
    select sku, changed_at from changes
),

-- 2. When each value of each changed attribute was in force.
attribute_intervals as (
    select sku, attribute_name, new_value as attribute_value, changed_at as value_from
    from changes
    union all
    -- the value before the first recorded change held from the beginning
    select sku, attribute_name, old_value, '1900-01-01'::timestamp_ntz
    from changes
    qualify row_number() over (partition by sku, attribute_name order by changed_at) = 1
),

-- 3. The value of each attribute as of each version start.
attribute_as_of as (
    select v.sku, v.valid_from, i.attribute_name, i.attribute_value
    from version_starts as v
    inner join attribute_intervals as i
        on i.sku = v.sku and i.value_from <= v.valid_from
    qualify row_number() over (
        partition by v.sku, v.valid_from, i.attribute_name order by i.value_from desc
    ) = 1
),

-- 4. Pivot back to one row per version. Attributes that never changed
--    take their current value.
versions as (
    select
        v.sku,
        v.valid_from,
        coalesce(max(iff(a.attribute_name = 'brand', a.attribute_value, null)), any_value(p.brand))               as brand,
        coalesce(max(iff(a.attribute_name = 'category', a.attribute_value, null)), any_value(p.category))         as category,
        coalesce(max(iff(a.attribute_name = 'department', a.attribute_value, null)), any_value(p.department))     as department,
        coalesce(max(iff(a.attribute_name = 'package_size', a.attribute_value, null)), any_value(p.package_size)) as package_size
    from version_starts as v
    inner join current_products as p on p.sku = v.sku
    left join attribute_as_of as a on a.sku = v.sku and a.valid_from = v.valid_from
    group by v.sku, v.valid_from
)

-- 5. Close each version where the next one opens.
select
    sku,
    valid_from,
    coalesce(lead(valid_from) over (partition by sku order by valid_from), {{ scd_end_of_time() }}) as valid_to,
    lead(valid_from) over (partition by sku order by valid_from) is null as is_current,
    row_number() over (partition by sku order by valid_from) as version_number,
    brand,
    category,
    department,
    package_size
from versions
