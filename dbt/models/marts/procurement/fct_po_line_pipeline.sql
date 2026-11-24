{#
  PROCUREMENT PIPELINE — accumulating snapshot fact table.

  Grain: one row per PURCHASE ORDER LINE. The row is created when the PO
  is issued and UPDATED as the line reaches each milestone.

  Multiple date foreign keys (role-playing the date dimension), one per
  milestone. Milestones not yet reached point at the special
  "Not Yet Happened" date row (-2), never at NULL.

  Lag facts (days between milestones) make pipeline-velocity analysis a
  simple AVG() instead of a self-join.

  dbt note: rebuilt in full each run (`table`). At scale you would make it
  incremental with a merge on (po_number, po_line_number), re-merging only
  lines that changed since the last run.
#}

with pivoted as (
    select
        po_number,
        po_line_number,
        any_value(vendor_id)                                             as vendor_id,
        any_value(sku)                                                   as sku,
        max(iff(transaction_type = 'PO_ISSUED', transaction_date, null)) as issued_date,
        max(iff(transaction_type = 'RECEIVED',  transaction_date, null)) as received_date,
        max(iff(transaction_type = 'INVOICED',  transaction_date, null)) as invoiced_date,
        max(iff(transaction_type = 'PAID',      transaction_date, null)) as paid_date,
        max(iff(transaction_type = 'PO_ISSUED', quantity, null))         as ordered_quantity,
        max(iff(transaction_type = 'RECEIVED',  quantity, null))         as received_quantity,
        max(iff(transaction_type = 'PO_ISSUED', quantity * unit_cost, null)) as ordered_amount
    from {{ ref('stg_cascade__procurement_transactions') }}
    group by po_number, po_line_number
)

select
    coalesce({{ date_key('issued_date') }}, -1)          as po_issued_date_key,
    coalesce({{ date_key('received_date') }}, -2)        as received_date_key,
    coalesce({{ date_key('invoiced_date') }}, -2)        as invoiced_date_key,
    coalesce({{ date_key('paid_date') }}, -2)            as paid_date_key,
    {{ dim_key('p.product_key') }}                        as product_key,
    {{ dim_key('v.vendor_key') }}                         as vendor_key,
    x.po_number,
    x.po_line_number,
    case
        when paid_date is not null     then 'Paid'
        when invoiced_date is not null then 'Invoiced'
        when received_date is not null then 'Received'
        else 'Open'
    end                                                   as pipeline_status,

    -- Facts
    x.ordered_quantity,
    coalesce(x.received_quantity, 0)                      as received_quantity,
    x.ordered_amount,
    datediff(day, issued_date, received_date)             as issued_to_received_lag_days,
    datediff(day, received_date, invoiced_date)           as received_to_invoiced_lag_days,
    datediff(day, invoiced_date, paid_date)               as invoiced_to_paid_lag_days,
    datediff(day, issued_date, paid_date)                 as issued_to_paid_lag_days,

    -- Milestone counters: SUM() these to count lines reaching each step
    iff(received_date is not null, 1, 0)                  as received_count,
    iff(invoiced_date is not null, 1, 0)                  as invoiced_count,
    iff(paid_date is not null, 1, 0)                      as paid_count
from pivoted as x
left join {{ ref('dim_product') }} as p
    on  p.sku = x.sku
    and x.issued_date::timestamp_ntz >= p.valid_from
    and x.issued_date::timestamp_ntz <  p.valid_to
left join {{ ref('dim_vendor') }} as v
    on v.vendor_id = x.vendor_id
