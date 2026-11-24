-- Small, static "transaction type" dimension. Descriptions and groupings
-- live here instead of in CASE expressions scattered across BI tools.
select
    {{ dbt_utils.generate_surrogate_key(['column1']) }} as inventory_movement_type_key,
    column1 as movement_type,
    column2 as movement_type_description,
    column3 as movement_direction,
    column4 as is_shrink
from values
    ('RECEIPT', 'Received from distribution center', 'Inbound',  false),
    ('SALE',    'Sold to customer',                  'Outbound', false),
    ('SHRINK',  'Lost, damaged or stolen',           'Outbound', true)
