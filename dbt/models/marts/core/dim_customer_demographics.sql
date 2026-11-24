{#
  Customer demographics MINI-DIMENSION (Kimball Type 4).

  Instead of tracking every age / income change as a new Type 2 row in a
  large customer dimension, we pre-build every COMBINATION of banded values.
  The fact table captures which combination applied at the time of each event.

  Bands, not raw values: banding is what keeps the mini-dimension small
  (4 age bands x 4 income bands x 3 tiers = 48 rows).
#}

with age_bands as (
    select column1 as age_band, column2 as age_band_sort
    from values ('Under 35', 1), ('35-49', 2), ('50-64', 3), ('65+', 4)
),

income_bands as (
    select column1 as income_band, column2 as income_band_sort
    from values ('Under $50k', 1), ('$50k-$99k', 2), ('$100k-$149k', 3), ('$150k+', 4)
),

tiers as (
    select column1 as loyalty_tier from values ('Basic'), ('Silver'), ('Gold')
)

select
    {{ dbt_utils.generate_surrogate_key(['a.age_band', 'i.income_band', 't.loyalty_tier']) }}
        as customer_demographics_key,
    a.age_band,
    a.age_band_sort,
    i.income_band,
    i.income_band_sort,
    t.loyalty_tier
from age_bands as a
cross join income_bands as i
cross join tiers as t

union all

{{ unknown_member_row({
    'customer_demographics_key': unknown_key(), 'age_band': "'Unknown'", 'age_band_sort': '99',
    'income_band': "'Unknown'", 'income_band_sort': '99', 'loyalty_tier': "'Unknown'",
}) }}
