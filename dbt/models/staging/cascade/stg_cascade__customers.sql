select
    customer_id,
    first_name,
    last_name,
    first_name || ' ' || last_name as full_name,
    lower(email)                   as email,
    birth_date,
    city,
    state,
    loyalty_tier,
    annual_income,
    updated_at
from {{ ref('raw_customers') }}
