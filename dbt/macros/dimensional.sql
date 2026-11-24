{#
  Small helpers that encode Kimball conventions so every model applies them
  the same way. Keep them boring: a modeler reading the compiled SQL should
  still see plain Snowflake SQL.
#}

{# The surrogate key used for the "Unknown" / "Not Applicable" member rows. #}
{% macro unknown_key() -%}
    {{ var('unknown_key') }}
{%- endmacro %}

{#
  Look up a dimension key from a fact, falling back to the unknown member.
  Kimball: fact-table foreign keys should never be null. A missing member
  points to the special row instead, so inner joins never silently drop facts.
#}
{% macro dim_key(column) -%}
    coalesce({{ column }}, {{ unknown_key() }})
{%- endmacro %}

{#
  The far-future "valid to" date for current rows in Type 2 dimensions.
  Using a real date (not null) keeps BETWEEN joins simple.
#}
{% macro scd_end_of_time() -%}
    '9999-12-31 23:59:59'::timestamp_ntz
{%- endmacro %}

{#
  Turn a date into the integer smart key YYYYMMDD. Kimball allows a
  meaningful key for the date dimension (and only the date dimension),
  because it makes fact-table partitioning and pruning easy.
#}
{% macro date_key(date_expr) -%}
    (year({{ date_expr }}) * 10000 + month({{ date_expr }}) * 100 + day({{ date_expr }}))
{%- endmacro %}
