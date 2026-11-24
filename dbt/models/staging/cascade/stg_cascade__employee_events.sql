select
    employee_id,
    event_date,
    upper(event_type)               as event_type,
    job_title,
    try_to_number(store_id)         as store_id,
    is_termination::boolean         as is_termination
from {{ ref('raw_employee_events') }}
