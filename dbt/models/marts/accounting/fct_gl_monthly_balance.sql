{#
  GENERAL LEDGER — periodic snapshot fact table.

  Grain: one row per account per store per MONTH, dense (a row even in months
  with no activity).

  Facts
    period_activity_amount   ADDITIVE across all dimensions (including time)
    ending_balance_amount    SEMI-ADDITIVE: never sum across months
#}

with months as (
    select distinct month_start_date as month_start_date
    from {{ ref('dim_date') }}
    where full_date between (select min(posting_date) from {{ ref('stg_cascade__gl_journal_lines') }})
                        and (select max(posting_date) from {{ ref('stg_cascade__gl_journal_lines') }})
),

account_store as (
    select distinct account_id, store_id from {{ ref('stg_cascade__gl_journal_lines') }}
),

activity as (
    select
        date_trunc('month', posting_date) as month_start_date,
        account_id,
        store_id,
        sum(signed_amount)                as period_activity_amount
    from {{ ref('stg_cascade__gl_journal_lines') }}
    group by all
),

dense as (
    select
        m.month_start_date,
        x.account_id,
        x.store_id,
        coalesce(a.period_activity_amount, 0) as period_activity_amount
    from months as m
    cross join account_store as x
    left join activity as a
        on  a.month_start_date = m.month_start_date
        and a.account_id = x.account_id
        and a.store_id = x.store_id
)

select
    {{ date_key('last_day(d.month_start_date)') }}       as month_end_date_key,
    {{ dim_key('acc.account_key') }}                      as account_key,
    {{ dim_key('s.store_key') }}                          as store_key,
    d.period_activity_amount,
    sum(d.period_activity_amount) over (
        partition by d.account_id, d.store_id
        order by d.month_start_date
        rows between unbounded preceding and current row
    )                                                     as ending_balance_amount
from dense as d
left join {{ ref('dim_account') }} as acc
    on acc.account_number = d.account_id
left join {{ ref('dim_store') }} as s
    on s.store_number = d.store_id
