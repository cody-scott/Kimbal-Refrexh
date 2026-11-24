select
    {{ dbt_utils.generate_surrogate_key(['interest']) }} as interest_key,
    interest                                             as interest_name,
    case
        when interest in ('Backpacking', 'Camping', 'Trail Running') then 'Trail'
        when interest in ('Climbing') then 'Vertical'
        else 'Water & Snow'
    end                                                  as interest_group
from (select distinct interest from {{ ref('stg_cascade__customer_interests') }})
