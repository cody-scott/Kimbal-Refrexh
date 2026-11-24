{#
  BUDGET VS ACTUAL — consolidated fact table.

  Kimball: when business users constantly compare facts from different
  processes at the SAME grain, it can pay to pre-join them into one
  "consolidated" fact table. Budgets are set per account per month, so the
  actuals are rolled up to that grain first.

  Grain: one row per account per month (company-wide).
  Every measure is aligned to that grain; a full outer join keeps months
  with a budget but no actuals and vice-versa.
#}

with actuals as (
    select
        date_trunc('month', posting_date) as month_start_date,
        account_id,
        sum(signed_amount)                as actual_amount
    from {{ ref('stg_cascade__gl_journal_lines') }}
    group by all
),

budget as (
    select budget_month as month_start_date, account_id, sum(budget_amount) as budget_amount
    from {{ ref('stg_cascade__gl_budget') }}
    group by all
),

combined as (
    select
        coalesce(a.month_start_date, b.month_start_date) as month_start_date,
        coalesce(a.account_id, b.account_id)             as account_id,
        coalesce(a.actual_amount, 0)                     as actual_amount,
        coalesce(b.budget_amount, 0)                     as budget_amount
    from actuals as a
    full outer join budget as b
        on  b.month_start_date = a.month_start_date
        and b.account_id = a.account_id
)

select
    {{ date_key('last_day(c.month_start_date)') }}  as month_end_date_key,
    {{ dim_key('acc.account_key') }}                 as account_key,
    c.actual_amount,
    c.budget_amount,
    c.actual_amount - c.budget_amount               as variance_amount
from combined as c
left join {{ ref('dim_account') }} as acc
    on acc.account_number = c.account_id
