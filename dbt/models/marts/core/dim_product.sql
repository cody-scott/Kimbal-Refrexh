{#
  Product dimension: Type 2 on brand / category / department / package_size.

  Keys
    product_key          surrogate key, one per VERSION of a product (what facts store)
    product_durable_key  one per PRODUCT for all time (supports Type 7 / "as is" reporting)
    sku                  the natural (business) key from the source

  The merchandise hierarchy (subcategory > category > department) is
  denormalized into this one table. Kimball: resist snowflaking it into
  separate category and department tables.
#}

with versions as (
    select * from {{ ref('int_product_versions') }}
),

current_products as (
    select * from {{ ref('stg_cascade__products') }}
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['v.sku', 'v.valid_from']) }} as product_key,
        {{ dbt_utils.generate_surrogate_key(['v.sku']) }}                as product_durable_key,
        v.sku,

        -- Type 1 attributes: always the current value, on every version
        p.product_name,
        p.subcategory,

        -- Type 2 attributes: the value in force during this version
        v.brand,
        v.category,
        v.department,
        v.package_size,

        -- Numeric descriptors used for filtering / banding, not summing.
        p.list_price                as current_list_price,
        case
            when p.list_price < 50  then 'Under $50'
            when p.list_price < 150 then '$50 - $149'
            when p.list_price < 300 then '$150 - $299'
            else '$300 and up'
        end                         as price_band,

        -- Row administration
        v.valid_from,
        v.valid_to,
        v.is_current,
        v.version_number
    from versions as v
    inner join current_products as p on p.sku = v.sku
)

select * from final

union all

{{ unknown_member_row({
    'product_key': unknown_key(),
    'product_durable_key': unknown_key(),
    'sku': "'N/A'",
    'product_name': "'Unknown Product'",
    'subcategory': "'Unknown'",
    'brand': "'Unknown'",
    'category': "'Unknown'",
    'department': "'Unknown'",
    'package_size': "'Unknown'",
    'current_list_price': 'null',
    'price_band': "'Unknown'",
    'valid_from': "'1900-01-01'::timestamp_ntz",
    'valid_to': scd_end_of_time(),
    'is_current': 'true',
    'version_number': '1',
}) }}
