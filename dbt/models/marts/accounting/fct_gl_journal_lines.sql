{#
  GENERAL LEDGER — transaction fact table.
  Grain: one row per journal entry line.
#}
select
    {{ date_key('j.posting_date') }}                 as posting_date_key,
    {{ dim_key('a.account_key') }}                    as account_key,
    {{ dim_key('s.store_key') }}                      as store_key,  -- conformed with retail sales
    j.journal_entry_id,                               -- degenerate
    j.debit_credit                                    as debit_credit_indicator,
    j.amount                                          as journal_amount,
    j.signed_amount                                   as signed_amount
from {{ ref('stg_cascade__gl_journal_lines') }} as j
left join {{ ref('dim_account') }} as a
    on a.account_number = j.account_id
left join {{ ref('dim_store') }} as s
    on s.store_number = j.store_id
