select
    account_id,
    account_name,
    nullif(parent_account_id, '') as parent_account_id,
    account_type
from {{ ref('raw_gl_accounts') }}
