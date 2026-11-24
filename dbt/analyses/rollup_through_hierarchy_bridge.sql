-- Total every journal line under each account at ANY depth, via the bridge.
select
    anc.account_name             as rollup_account,
    anc.hierarchy_depth,
    sum(f.signed_amount)         as total_signed_amount,
    count(distinct f.account_key) as leaf_accounts_with_activity
from {{ ref('fct_gl_journal_lines') }} f
join {{ ref('bridge_account_hierarchy') }} b on b.descendant_account_key = f.account_key
join {{ ref('dim_account') }} anc           on anc.account_key = b.ancestor_account_key
group by all
order by anc.hierarchy_depth, anc.account_name
