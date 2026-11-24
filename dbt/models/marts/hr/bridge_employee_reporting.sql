{#
  Recursive REPORTING HIERARCHY bridge (Kimball's "variable-depth hierarchy").

  Grain: one row per (manager, subordinate) pair at any distance, including
  each employee paired with themselves (distance 0).

  "Total sales rung up by everyone under the VP of Retail" becomes a
  simple join through this table, no recursive SQL at query time.

  Built from CURRENT reporting lines. A time-variant version would add
  effective/expiration dates to every bridge row.
#}

with recursive org as (
    select
        employee_id as manager_employee_id,
        employee_id as subordinate_employee_id,
        0           as levels_below
    from {{ ref('stg_cascade__employees') }}

    union all

    select
        o.manager_employee_id,
        e.employee_id,
        o.levels_below + 1
    from org as o
    inner join {{ ref('stg_cascade__employees') }} as e
        on e.manager_employee_id = o.subordinate_employee_id
)

select
    {{ dbt_utils.generate_surrogate_key(['manager_employee_id']) }}     as manager_durable_key,
    {{ dbt_utils.generate_surrogate_key(['subordinate_employee_id']) }} as subordinate_durable_key,
    manager_employee_id,
    subordinate_employee_id,
    levels_below,
    levels_below = 0                                                    as is_self
from org
