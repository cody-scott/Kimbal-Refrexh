{#
  Rebuild Kimball Type 2 history from an attribute-level change log.

  Many sources (CDC feeds, audit tables, ERP change documents) record
  "attribute X changed from A to B at time T". Unlike a dbt snapshot, this
  can reconstruct history that happened before the warehouse existed,
  and it is idempotent: a full refresh reproduces exactly the same rows.

  Arguments
    current_relation   one row per natural key with CURRENT attribute values
    changes_relation   columns: <natural_key>, changed_at, attribute_name, old_value, new_value
    natural_key        the business key column name
    tracked_columns    Type 2 attributes (a change in any opens a new row)
    passthrough_columns  other columns copied from the current row (Type 1 behaviour)
    beginning_of_time  valid_from for each key's first version

  Output columns
    <natural_key>, valid_from, valid_to, is_current, version_number,
    <tracked_columns...>, <passthrough_columns...>
#}
{% macro scd2_from_change_log(
        current_relation,
        changes_relation,
        natural_key,
        tracked_columns,
        passthrough_columns=[],
        beginning_of_time="'1900-01-01'::timestamp_ntz") %}

with current_rows as (
    select * from {{ current_relation }}
),

tracked_changes as (
    select *
    from {{ changes_relation }}
    where attribute_name in (
        {%- for c in tracked_columns %}'{{ c }}'{{ "," if not loop.last }}{% endfor -%}
    )
),

-- Every moment a new version begins: the beginning of time, plus every
-- distinct timestamp at which any tracked attribute changed.
version_starts as (
    select {{ natural_key }}, {{ beginning_of_time }} as valid_from
    from current_rows
    union
    select {{ natural_key }}, changed_at
    from tracked_changes
),

-- Value intervals per attribute: the first change's old_value was true
-- from the beginning of time; each new_value is true from its changed_at.
attribute_intervals as (
    select {{ natural_key }}, attribute_name, new_value as attribute_value, changed_at as value_from
    from tracked_changes
    union all
    select {{ natural_key }}, attribute_name, old_value, {{ beginning_of_time }}
    from tracked_changes
    qualify row_number() over (
        partition by {{ natural_key }}, attribute_name order by changed_at
    ) = 1
),

-- For each version start, the value of each changed attribute in force then.
attribute_as_of as (
    select
        v.{{ natural_key }},
        v.valid_from,
        i.attribute_name,
        i.attribute_value
    from version_starts as v
    inner join attribute_intervals as i
        on  i.{{ natural_key }} = v.{{ natural_key }}
        and i.value_from <= v.valid_from
    qualify row_number() over (
        partition by v.{{ natural_key }}, v.valid_from, i.attribute_name
        order by i.value_from desc
    ) = 1
),

versions as (
    select
        v.{{ natural_key }},
        v.valid_from,
        {%- for c in tracked_columns %}
        -- attributes that never changed fall back to the current value
        coalesce(
            max(iff(a.attribute_name = '{{ c }}', a.attribute_value, null)),
            any_value(cur.{{ c }})::varchar
        ) as {{ c }},
        {%- endfor %}
        {%- for c in passthrough_columns %}
        any_value(cur.{{ c }}) as {{ c }},
        {%- endfor %}
        count(*) as _attribute_rows
    from version_starts as v
    inner join current_rows as cur
        on cur.{{ natural_key }} = v.{{ natural_key }}
    left join attribute_as_of as a
        on  a.{{ natural_key }} = v.{{ natural_key }}
        and a.valid_from = v.valid_from
    group by v.{{ natural_key }}, v.valid_from
)

select
    {{ natural_key }},
    valid_from,
    coalesce(
        lead(valid_from) over (partition by {{ natural_key }} order by valid_from),
        {{ scd_end_of_time() }}
    ) as valid_to,
    lead(valid_from) over (partition by {{ natural_key }} order by valid_from) is null as is_current,
    row_number() over (partition by {{ natural_key }} order by valid_from) as version_number,
    {{ (tracked_columns + passthrough_columns) | join(',\n    ') }}
from versions

{% endmacro %}
