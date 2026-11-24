{#
  AGGREGATE FACT TABLE: retail sales rolled up to month x category x store.

  Aggregates are a PERFORMANCE technique, not a modeling one: they must
  return exactly what the atomic fact returns for the same question.
  The data test on this model checks that totals tie out to fct_retail_sales.

  Rolls up by the CURRENT category (Type 1 perspective), which is what
  most dashboards want.
#}
select
    year(f.transaction_date) * 100 + month(f.transaction_date)           as month_key,
    {{ dbt_utils.generate_surrogate_key(['cur.current_category', 'cur.current_department']) }} as product_category_key,
    f.store_key,
    sum(f.sales_quantity)                                                as sales_quantity,
    sum(f.extended_net_sales_amount)                                     as net_sales_amount,
    sum(f.extended_cost_amount)                                          as cost_amount,
    sum(f.extended_gross_profit_amount)                                  as gross_profit_amount,
    count(distinct f.transaction_id)                                     as transaction_count  -- non-additive across months/categories!
from {{ ref('fct_retail_sales') }} as f
inner join {{ ref('scd_type7_product_current') }} as cur
    on cur.product_durable_key = f.product_durable_key
group by all
