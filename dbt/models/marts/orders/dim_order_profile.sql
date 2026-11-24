{#
  Order profile JUNK DIMENSION.

  Low-cardinality flags and indicators (payment method, ship method, gift flag)
  that don't belong to any other dimension. Rather than three tiny dimensions
  or three text columns cluttering the fact table, Kimball combines them
  into one "junk" dimension.

  Built as the full Cartesian product of the allowed values (3 x 3 x 2 = 18 rows)
  so every combination has a key before any order arrives. When the
  combination space is huge, build it from the combinations actually observed instead.
#}

with payment_methods as (
    select column1 as payment_method from values ('Credit Card'), ('PayPal'), ('Gift Card')
),
ship_methods as (
    select column1 as ship_method, column2 as ship_speed_band
    from values ('Ground', 'Standard'), ('2-Day', 'Expedited'), ('Overnight', 'Expedited')
),
gift_flags as (
    select column1 as is_gift, column2 as gift_indicator
    from values (true, 'Gift Order'), (false, 'Not a Gift')
)

select
    {{ dbt_utils.generate_surrogate_key(['p.payment_method', 's.ship_method', 'g.is_gift']) }} as order_profile_key,
    p.payment_method,
    s.ship_method,
    s.ship_speed_band,
    g.is_gift,
    g.gift_indicator
from payment_methods as p
cross join ship_methods as s
cross join gift_flags as g

union all

{{ unknown_member_row({
    'order_profile_key': unknown_key(), 'payment_method': "'Unknown'", 'ship_method': "'Unknown'",
    'ship_speed_band': "'Unknown'", 'is_gift': 'null', 'gift_indicator': "'Unknown'",
}) }}
