{#
  Emit the SELECT for a dimension's unknown-member row.
  Usage (inside a dimension model):

    union all
    {{ unknown_member_row({'product_key': unknown_key(), 'sku': "'N/A'", 'product_name': "'Unknown Product'"}) }}

  Pass every column of the dimension so the UNION lines up.
#}
{% macro unknown_member_row(columns) -%}
    select
    {%- for name, value in columns.items() %}
        {{ value }} as {{ name }}{{ "," if not loop.last }}
    {%- endfor %}
{%- endmacro %}
