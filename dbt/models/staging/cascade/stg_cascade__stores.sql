select
    store_id,
    store_name,
    city,
    state,
    district,
    region,
    nullif(square_footage, 0)               as square_footage,
    opened_date,
    manager_name,
    iff(store_id = 999, 'Digital', 'Physical') as channel
from {{ ref('raw_stores') }}
