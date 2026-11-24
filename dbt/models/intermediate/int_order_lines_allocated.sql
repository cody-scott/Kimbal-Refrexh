{#
  Allocate the order-HEADER shipping charge down to the LINE grain.

  Kimball (Order Management): header-level facts can't sit in a line-grain
  fact table as-is. Repeating the header amount on every line would
  double-count it. Allocate it, here in proportion to each line's share of
  the order's gross amount, so that SUM(allocated) over the lines equals the
  header charge exactly.

  The last line absorbs the rounding remainder so the total ties out to the cent.
#}

with lines as (
    select * from {{ ref('stg_cascade__web_order_lines') }}
),

orders as (
    select * from {{ ref('stg_cascade__web_orders') }}
),

shares as (
    select
        l.*,
        o.shipping_charge_local,
        l.quantity * l.unit_price_local                                           as gross_amount_local,
        (l.quantity * l.unit_price_local)
            / nullif(sum(l.quantity * l.unit_price_local) over (partition by l.order_number), 0) as line_share,
        row_number() over (partition by l.order_number order by l.line_number desc) as reverse_line_rank
    from lines as l
    inner join orders as o on o.order_number = l.order_number
),

rounded as (
    select
        *,
        round(shipping_charge_local * line_share, 2) as rounded_allocation
    from shares
)

select
    order_number,
    line_number,
    sku,
    quantity,
    unit_price_local,
    discount_local,
    unit_cost_usd,
    gross_amount_local,
    case
        when reverse_line_rank = 1
            then shipping_charge_local
                 - (sum(rounded_allocation) over (partition by order_number) - rounded_allocation)
        else rounded_allocation
    end as allocated_shipping_local
from rounded
