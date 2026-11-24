{{
  config(
    materialized='incremental',
    unique_key=['transaction_id', 'line_number'],
    incremental_strategy='merge',
    cluster_by=['date_key'],
    on_schema_change='append_new_columns'
  )
}}

{#
  RETAIL SALES — transaction fact table.

  Step 1  Business process:  point-of-sale retail sales
  Step 2  Grain:             ONE ROW PER PRODUCT LINE ON A POS TRANSACTION
                             (the most atomic data the source captures)
  Step 3  Dimensions:        date, product, store, promotion, customer,
                             customer demographics (mini-dim), cashier (employee)
                             + degenerate dimensions: transaction_id, line_number
  Step 4  Facts:             quantity and extended amounts (all fully additive)

  Type 2 dimensions are joined "as of" the transaction timestamp so each
  sale points to the version of the product / customer in force at the time.
#}

with sales as (
    select *
    from {{ ref('stg_cascade__pos_transactions') }}
    {% if is_incremental() %}
    -- Reprocess a 3-day lookback window to catch late-arriving rows.
    where transaction_date >= (select dateadd(day, -3, max(transaction_date)) from {{ this }})
    {% endif %}
),

products  as (select * from {{ ref('dim_product') }}),
customers as (select * from {{ ref('dim_customer') }}),
employees as (select * from {{ ref('dim_employee') }}),
stores    as (select * from {{ ref('dim_store') }}),
promos    as (select * from {{ ref('dim_promotion') }}),
demos     as (select * from {{ ref('dim_customer_demographics') }}),

customer_profile as (
    -- band the customer's age (at the time of sale) and income for the mini-dimension
    select
        s.transaction_id,
        s.line_number,
        case
            when datediff(year, c.birth_date, s.transaction_date) < 35 then 'Under 35'
            when datediff(year, c.birth_date, s.transaction_date) < 50 then '35-49'
            when datediff(year, c.birth_date, s.transaction_date) < 65 then '50-64'
            else '65+'
        end as age_band,
        case
            when cur.annual_income < 50000  then 'Under $50k'
            when cur.annual_income < 100000 then '$50k-$99k'
            when cur.annual_income < 150000 then '$100k-$149k'
            else '$150k+'
        end as income_band,
        c.loyalty_tier
    from sales as s
    inner join customers as c
        on  c.customer_id = s.customer_id
        and s.transaction_ts >= c.valid_from
        and s.transaction_ts <  c.valid_to
    inner join {{ ref('stg_cascade__customers') }} as cur
        on cur.customer_id = s.customer_id
)

select
    -- Dimension foreign keys (never null: unknown members catch misses)
    {{ date_key('s.transaction_date') }}                         as date_key,
    {{ dim_key('p.product_key') }}                                as product_key,
    {{ dim_key('p.product_durable_key') }}                        as product_durable_key,
    {{ dim_key('st.store_key') }}                                 as store_key,
    case
        when s.promo_code is null then {{ dbt_utils.generate_surrogate_key(["'NONE'"]) }}
        else {{ dim_key('pr.promotion_key') }}
    end                                                           as promotion_key,
    case
        when s.customer_id is null then '-2'                       -- anonymous shopper
        else {{ dim_key('c.customer_key') }}
    end                                                           as customer_key,
    case
        when s.customer_id is null then {{ unknown_key() }}
        else {{ dim_key('d.customer_demographics_key') }}
    end                                                           as customer_demographics_key,
    {{ dim_key('e.employee_key') }}                               as cashier_key,

    -- Degenerate dimensions: the POS ticket number has no attributes of
    -- its own, but it is how you group lines into a basket.
    s.transaction_id,
    s.line_number,
    s.register_id,
    s.transaction_ts,
    s.transaction_date,

    -- Facts. Store EXTENDED amounts (unit x quantity): they are additive.
    -- Unit prices are non-additive; they can be derived by division.
    s.quantity                                                    as sales_quantity,
    s.quantity * s.unit_price                                     as extended_gross_sales_amount,
    s.discount_amount                                             as extended_discount_amount,
    s.quantity * s.unit_price - s.discount_amount                 as extended_net_sales_amount,
    s.quantity * s.unit_cost                                      as extended_cost_amount,
    s.quantity * s.unit_price - s.discount_amount
        - s.quantity * s.unit_cost                                as extended_gross_profit_amount,

    -- Audit dimension: which dbt run wrote (or last re-merged) this row
    '{{ invocation_id }}'                                         as audit_key
from sales as s
left join products as p
    on  p.sku = s.sku
    and s.transaction_ts >= p.valid_from
    and s.transaction_ts <  p.valid_to
left join stores as st
    on st.store_number = s.store_id
left join promos as pr
    on pr.promo_code = s.promo_code
left join customers as c
    on  c.customer_id = s.customer_id
    and s.transaction_ts >= c.valid_from
    and s.transaction_ts <  c.valid_to
left join customer_profile as cp
    on  cp.transaction_id = s.transaction_id
    and cp.line_number = s.line_number
left join demos as d
    on  d.age_band = cp.age_band
    and d.income_band = cp.income_band
    and d.loyalty_tier = cp.loyalty_tier
left join employees as e
    on  e.employee_id = s.cashier_employee_id
    and s.transaction_ts >= e.valid_from
    and s.transaction_ts <  e.valid_to
