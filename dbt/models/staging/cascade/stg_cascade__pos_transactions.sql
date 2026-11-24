-- Grain of the source: one line item on one point-of-sale ticket.
select
    transaction_id,
    line_number,
    store_id,
    register_id,
    cashier_employee_id,
    nullif(customer_id, '')             as customer_id,
    sku,
    nullif(promo_code, '')              as promo_code,
    quantity,
    unit_price,
    discount_amount,
    unit_cost,
    transaction_ts,
    transaction_ts::date                as transaction_date
from {{ ref('raw_pos_transactions') }}
