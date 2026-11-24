{#
  Employee dimension, Type 2 on job title and home store.

  Versions come from HR events (hire, promotion, transfer, termination).
  Kimball's HR chapter adds a "row change reason" attribute so analysts
  can see WHY each version exists.

  Late-arriving dimension members: some events reference employees not yet
  in the employee master (E015, E016). Rather than drop those events, we
  create an INFERRED member row with what we know. A later load can
  overwrite it (Type 1) once the master record arrives.
#}

with events as (
    select * from {{ ref('stg_cascade__employee_events') }}
),

employees as (
    select * from {{ ref('stg_cascade__employees') }}
),

all_employee_ids as (
    select employee_id, false as is_inferred_member from employees
    union all
    select distinct e.employee_id, true
    from events as e
    where not exists (select 1 from employees as m where m.employee_id = e.employee_id)
),

versions as (
    select
        ev.employee_id,
        ev.event_date::timestamp_ntz                                        as valid_from,
        coalesce(
            lead(ev.event_date) over (partition by ev.employee_id order by ev.event_date)::timestamp_ntz,
            {{ scd_end_of_time() }}
        )                                                                   as valid_to,
        lead(ev.event_date) over (partition by ev.employee_id order by ev.event_date) is null
                                                                            as is_current,
        ev.event_type                                                       as row_change_reason,
        ev.job_title,
        ev.store_id                                                         as home_store_number,
        iff(ev.is_termination, 'Terminated', 'Active')                      as employment_status
    from events as ev
)

select
    {{ dbt_utils.generate_surrogate_key(['v.employee_id', 'v.valid_from']) }} as employee_key,
    {{ dbt_utils.generate_surrogate_key(['v.employee_id']) }}                as employee_durable_key,
    v.employee_id,
    coalesce(m.employee_name, 'Inferred: ' || v.employee_id)                 as employee_name,
    coalesce(m.department, 'Unknown')                                        as department,
    m.hire_date,
    v.job_title,
    v.home_store_number,
    v.employment_status,
    v.row_change_reason,
    ids.is_inferred_member,
    v.valid_from,
    v.valid_to,
    v.is_current
from versions as v
inner join all_employee_ids as ids on ids.employee_id = v.employee_id
left join employees as m on m.employee_id = v.employee_id

union all

{{ unknown_member_row({
    'employee_key': unknown_key(), 'employee_durable_key': unknown_key(), 'employee_id': "'N/A'",
    'employee_name': "'Unknown Employee'", 'department': "'Unknown'", 'hire_date': 'null',
    'job_title': "'Unknown'", 'home_store_number': 'null', 'employment_status': "'Unknown'",
    'row_change_reason': "'N/A'", 'is_inferred_member': 'false',
    'valid_from': "'1900-01-01'::timestamp_ntz", 'valid_to': scd_end_of_time(), 'is_current': 'true',
}) }}
