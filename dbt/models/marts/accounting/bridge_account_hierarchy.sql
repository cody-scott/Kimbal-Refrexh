{#
  Hierarchy BRIDGE for the ragged chart of accounts.

  Grain: one row per (ancestor, descendant) PAIR, including each account
  paired with itself at distance 0.

  To total everything rolling up to "Operating Expenses" at any depth:

      select sum(f.signed_amount)
      from fct_gl_journal_lines f
      join bridge_account_hierarchy b on b.descendant_account_key = f.account_key
      join dim_account a              on a.account_key = b.ancestor_account_key
      where a.account_name = 'Operating Expenses'

  Facts post to leaves only, so each fact row is counted exactly once
  per ancestor: no double counting.
#}

with recursive pairs as (
    select
        account_id as ancestor_account_id,
        account_id as descendant_account_id,
        0          as levels_between
    from {{ ref('stg_cascade__gl_accounts') }}

    union all

    select
        p.ancestor_account_id,
        c.account_id,
        p.levels_between + 1
    from pairs as p
    inner join {{ ref('stg_cascade__gl_accounts') }} as c
        on c.parent_account_id = p.descendant_account_id
)

select
    {{ dbt_utils.generate_surrogate_key(['p.ancestor_account_id']) }}   as ancestor_account_key,
    {{ dbt_utils.generate_surrogate_key(['p.descendant_account_id']) }} as descendant_account_key,
    p.levels_between,
    p.levels_between = 0                                                as is_self,
    d.is_leaf                                                           as descendant_is_leaf
from pairs as p
inner join {{ ref('dim_account') }} as d
    on d.account_number = p.descendant_account_id
