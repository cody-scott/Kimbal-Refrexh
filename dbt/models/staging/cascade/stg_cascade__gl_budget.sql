select
    budget_month,
    account_id,
    budget_amount
from {{ ref('raw_gl_budget') }}
