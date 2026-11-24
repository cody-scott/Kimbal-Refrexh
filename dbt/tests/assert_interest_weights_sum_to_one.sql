-- Weighted bridge reporting only ties out if each customer's weights sum to 1.
select customer_durable_key, sum(weighting_factor) as total_weight
from {{ ref('bridge_customer_interest') }}
group by customer_durable_key
having abs(sum(weighting_factor) - 1) > 0.000001
