{#
  PROCUREMENT — ONE transaction fact table with a transaction-type dimension.

  Grain: one row per procurement transaction on a PO line.

  Kimball's design question (Procurement chapter): one fact table with a
  transaction-type dimension, or one fact table per transaction type?
  One table is right when the transaction types share the same
  dimensionality and measures (they do here: quantity and amount).
  If invoices had tax and freight measures that POs lack, separate fact
  tables would avoid lots of null/zero columns.
#}
select
    {{ date_key('t.transaction_date') }}                         as transaction_date_key,
    {{ dim_key('p.product_key') }}                                as product_key,
    {{ dim_key('v.vendor_key') }}                                 as vendor_key,
    {{ dim_key('tt.procurement_transaction_type_key') }}          as procurement_transaction_type_key,
    t.po_number,                                                  -- degenerate
    t.po_line_number,                                             -- degenerate
    t.quantity                                                    as transaction_quantity,
    t.quantity * t.unit_cost                                      as transaction_amount
from {{ ref('stg_cascade__procurement_transactions') }} as t
left join {{ ref('dim_product') }} as p
    on  p.sku = t.sku
    and t.transaction_date::timestamp_ntz >= p.valid_from
    and t.transaction_date::timestamp_ntz <  p.valid_to
left join {{ ref('dim_vendor') }} as v
    on v.vendor_id = t.vendor_id
left join {{ ref('dim_procurement_transaction_type') }} as tt
    on tt.transaction_type = t.transaction_type
