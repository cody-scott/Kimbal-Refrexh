-- Signed amount: debits positive for asset/expense accounts' natural balance.
select
    journal_entry_id,
    posting_date,
    account_id,
    store_id,
    debit_credit,
    amount,
    iff(debit_credit = 'D', amount, -amount) as signed_amount
from {{ ref('raw_gl_journal_lines') }}
