{#
  Generic test for Type 2 dimensions. Fails if, for any natural key:
    * more than one row is current, or
    * effective ranges overlap, or
    * there is a gap between one version's valid_to and the next valid_from.

  Usage in YAML:
    data_tests:
      - scd2_valid_ranges:
          natural_key: sku
          valid_from: valid_from
          valid_to: valid_to
#}
{% test scd2_valid_ranges(model, natural_key, valid_from='valid_from', valid_to='valid_to', is_current='is_current') %}

with versions as (
    select
        {{ natural_key }} as natural_key,
        {{ valid_from }} as valid_from,
        {{ valid_to }} as valid_to,
        {{ is_current }} as is_current,
        lead({{ valid_from }}) over (
            partition by {{ natural_key }} order by {{ valid_from }}
        ) as next_valid_from
    from {{ model }}
    where {{ natural_key }} is not null
),

too_many_current as (
    select natural_key, 'multiple current rows' as problem
    from versions
    group by natural_key
    having count_if(is_current) > 1
),

bad_ranges as (
    select natural_key, 'overlap or gap between versions' as problem
    from versions
    where next_valid_from is not null
      and next_valid_from <> valid_to
)

select * from too_many_current
union all
select * from bad_ranges

{% endtest %}
