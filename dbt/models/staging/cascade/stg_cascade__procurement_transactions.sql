select
    po_number,
    po_line_number,
    vendor_id,
    sku,
    transaction_date,
    upper(transaction_type) as transaction_type,
    quantity,
    unit_cost
from {{ ref('raw_procurement_transactions') }}
