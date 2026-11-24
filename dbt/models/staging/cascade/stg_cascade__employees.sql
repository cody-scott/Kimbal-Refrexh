select
    employee_id,
    employee_name,
    job_title,
    nullif(manager_employee_id, '')        as manager_employee_id,
    department,
    hire_date,
    try_to_number(nullif(home_store_id, '')) as home_store_id
from {{ ref('raw_employees') }}
