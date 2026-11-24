select
    vendor_id,
    vendor_name,
    country as vendor_country
from {{ ref('raw_vendors') }}
