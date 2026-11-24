{#
  EMPLOYEE EVENTS — transaction fact table (Kimball HR: "employee profile
  transaction tracking"). Nearly factless: the counters exist so that
  SUM() gives hires, terminations, promotions in any slice.

  Grain: one row per HR event per employee.
#}
select
    {{ date_key('ev.event_date') }}                             as event_date_key,
    {{ dim_key('e.employee_key') }}                              as employee_key,
    {{ dim_key('s.store_key') }}                                 as store_key,
    ev.event_type,
    iff(ev.event_type = 'HIRE', 1, 0)                            as hire_count,
    iff(ev.event_type = 'TERMINATION', 1, 0)                     as termination_count,
    iff(ev.event_type = 'PROMOTION', 1, 0)                       as promotion_count,
    iff(ev.event_type = 'TRANSFER', 1, 0)                        as transfer_count
from {{ ref('stg_cascade__employee_events') }} as ev
left join {{ ref('dim_employee') }} as e
    on  e.employee_id = ev.employee_id
    and ev.event_date::timestamp_ntz = e.valid_from  -- each event opens exactly one version
left join {{ ref('dim_store') }} as s
    on s.store_number = ev.store_id
