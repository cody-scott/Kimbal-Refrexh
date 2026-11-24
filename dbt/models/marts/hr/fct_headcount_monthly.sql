{#
  HEADCOUNT — periodic snapshot fact table.

  Grain: one row per employee per month-end they were on the books.
  Kimball's HR chapter pairs this snapshot with the event fact: events answer
  "what happened", the snapshot answers "what did the workforce look like".

  headcount is semi-additive across time: sum across stores, not months.
#}

with month_ends as (
    select distinct month_end_date
    from {{ ref('dim_date') }}
    where full_date between '2025-01-01' and '2025-06-30'
)

select
    {{ date_key('m.month_end_date') }}                as month_end_date_key,
    e.employee_key,
    {{ dim_key('s.store_key') }}                       as store_key,
    1                                                  as headcount,
    datediff(month, e.hire_date, m.month_end_date)     as tenure_months
from month_ends as m
inner join {{ ref('dim_employee') }} as e
    on  m.month_end_date::timestamp_ntz >= e.valid_from
    and m.month_end_date::timestamp_ntz <  e.valid_to
    and e.employment_status = 'Active'
    and e.employee_key <> {{ unknown_key() }}
left join {{ ref('dim_store') }} as s
    on s.store_number = e.home_store_number
