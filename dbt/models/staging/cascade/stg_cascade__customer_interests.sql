select distinct
    customer_id,
    interest
from {{ ref('raw_customer_interests') }}
