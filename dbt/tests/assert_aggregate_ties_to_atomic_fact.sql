-- Aggregates must return the same answer as the atomic fact. Fails on any difference.
select
    (select sum(extended_net_sales_amount) from {{ ref('fct_retail_sales') }})            as atomic_total,
    (select sum(net_sales_amount)          from {{ ref('agg_sales_monthly_category_store') }}) as aggregate_total
where atomic_total <> aggregate_total
