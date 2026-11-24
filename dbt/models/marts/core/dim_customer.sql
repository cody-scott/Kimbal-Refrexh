{#
  Customer dimension: Type 2 on city / state / loyalty_tier.

  Rapidly changing, analytically interesting attributes (age band,
  income band) are NOT here. They live in the dim_customer_demographics
  mini-dimension (Type 4), so they don't explode the row count of this table.

  Two special rows:
    '-1'  Unknown customer (data problem)
    '-2'  Anonymous walk-in shopper (a legitimate business case: no loyalty card)
#}

with versions as (
    select * from {{ ref('int_customer_versions') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['customer_id', 'valid_from']) }} as customer_key,
    {{ dbt_utils.generate_surrogate_key(['customer_id']) }}               as customer_durable_key,
    customer_id,
    full_name                                                            as customer_name,
    first_name,
    last_name,
    email,
    city                                                                 as customer_city,
    state                                                                as customer_state,
    loyalty_tier,
    birth_date,
    valid_from,
    valid_to,
    is_current,
    version_number
from versions

union all

{{ unknown_member_row({
    'customer_key': unknown_key(), 'customer_durable_key': unknown_key(), 'customer_id': "'N/A'",
    'customer_name': "'Unknown Customer'", 'first_name': "'Unknown'", 'last_name': "'Unknown'",
    'email': 'null', 'customer_city': "'Unknown'", 'customer_state': "'Unknown'",
    'loyalty_tier': "'Unknown'", 'birth_date': 'null',
    'valid_from': "'1900-01-01'::timestamp_ntz", 'valid_to': scd_end_of_time(),
    'is_current': 'true', 'version_number': '1',
}) }}

union all

{{ unknown_member_row({
    'customer_key': "'-2'", 'customer_durable_key': "'-2'", 'customer_id': "'ANON'",
    'customer_name': "'Anonymous Shopper'", 'first_name': "'Anonymous'", 'last_name': "'Shopper'",
    'email': 'null', 'customer_city': "'Not Applicable'", 'customer_state': "'Not Applicable'",
    'loyalty_tier': "'Not a Member'", 'birth_date': 'null',
    'valid_from': "'1900-01-01'::timestamp_ntz", 'valid_to': scd_end_of_time(),
    'is_current': 'true', 'version_number': '1',
}) }}
