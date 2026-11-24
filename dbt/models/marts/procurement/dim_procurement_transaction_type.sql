select
    {{ dbt_utils.generate_surrogate_key(['column1']) }} as procurement_transaction_type_key,
    column1 as transaction_type,
    column2 as transaction_type_description,
    column3 as pipeline_step_number
from values
    ('PO_ISSUED', 'Purchase order issued to vendor', 1),
    ('RECEIVED',  'Goods received at DC',            2),
    ('INVOICED',  'Vendor invoice received',         3),
    ('PAID',      'Vendor paid',                     4)
