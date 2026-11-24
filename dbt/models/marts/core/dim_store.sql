{#
  Store dimension (Type 1). The geographic hierarchy
  (store > district > region) is flattened into the row.
  The Web Store is a real member, so web activity can conform
  with store activity on the same dimension.
#}
select
    {{ dbt_utils.generate_surrogate_key(['store_id']) }} as store_key,
    store_id                                             as store_number,
    store_name,
    channel                                              as store_channel,
    city                                                 as store_city,
    state                                                as store_state,
    district                                             as store_district,
    region                                               as store_region,
    square_footage                                       as selling_square_footage,
    case
        when square_footage is null  then 'Not Applicable'
        when square_footage < 25000  then 'Small (< 25k sq ft)'
        when square_footage < 35000  then 'Medium (25-35k sq ft)'
        else 'Large (35k+ sq ft)'
    end                                                  as store_size_band,
    opened_date                                          as first_open_date,
    manager_name                                         as store_manager
from {{ ref('stg_cascade__stores') }}

union all

{{ unknown_member_row({
    'store_key': unknown_key(), 'store_number': '-1', 'store_name': "'Unknown Store'",
    'store_channel': "'Unknown'", 'store_city': "'Unknown'", 'store_state': "'Unknown'",
    'store_district': "'Unknown'", 'store_region': "'Unknown'",
    'selling_square_footage': 'null', 'store_size_band': "'Unknown'",
    'first_open_date': 'null', 'store_manager': "'Unknown'",
}) }}
