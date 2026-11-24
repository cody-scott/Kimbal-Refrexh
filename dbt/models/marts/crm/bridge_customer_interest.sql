{#
  MULTIVALUED DIMENSION bridge: a customer has zero, one or many interests.

  Grain: one row per customer (durable key) per interest.

  weighting_factor = 1 / number of interests for that customer, so a
  "weighted" report allocates each customer's sales across their interests
  and still ties to the total. An unweighted ("impact") report counts the
  full sale under every interest; it's useful, but it double counts by design.

  Keyed on the customer DURABLE key so customer Type 2 changes don't
  require re-versioning the bridge.
#}
select
    {{ dbt_utils.generate_surrogate_key(['customer_id']) }} as customer_durable_key,
    {{ dbt_utils.generate_surrogate_key(['interest']) }}    as interest_key,
    1 / count(*) over (partition by customer_id)            as weighting_factor
from {{ ref('stg_cascade__customer_interests') }}
