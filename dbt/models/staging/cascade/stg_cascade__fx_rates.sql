select
    rate_date,
    from_currency,
    to_currency,
    exchange_rate
from {{ ref('raw_fx_rates') }}
