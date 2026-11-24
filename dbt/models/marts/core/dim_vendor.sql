select
    {{ dbt_utils.generate_surrogate_key(['vendor_id']) }} as vendor_key,
    vendor_id,
    vendor_name,
    vendor_country,
    iff(vendor_country = 'US', 'Domestic', 'Import')      as sourcing_type
from {{ ref('stg_cascade__vendors') }}

union all

{{ unknown_member_row({
    'vendor_key': unknown_key(), 'vendor_id': "'N/A'", 'vendor_name': "'Unknown Vendor'",
    'vendor_country': "'Unknown'", 'sourcing_type': "'Unknown'",
}) }}
