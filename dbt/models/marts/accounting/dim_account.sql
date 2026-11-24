{#
  General ledger ACCOUNT dimension.

  The chart of accounts is a RAGGED hierarchy: leaves sit at different depths
  (Cash is level 2, Store Rent is level 4). Two complementary Kimball techniques:

  1. Flatten to fixed levels here (level_1..level_4), filling short branches
     by repeating the lowest real level downward. Easy for BI drag-and-drop.
  2. A BRIDGE table (bridge_account_hierarchy) for arbitrary-depth
     "roll up everything under X" questions.
#}

with recursive paths as (
    select
        account_id,
        account_name,
        account_type,
        parent_account_id,
        1                       as depth,
        account_name::varchar   as level_1,
        null::varchar           as level_2,
        null::varchar           as level_3,
        null::varchar           as level_4,
        account_id::varchar     as path
    from {{ ref('stg_cascade__gl_accounts') }}
    where parent_account_id is null

    union all

    select
        c.account_id,
        c.account_name,
        c.account_type,
        c.parent_account_id,
        p.depth + 1,
        p.level_1,
        iff(p.depth + 1 = 2, c.account_name, p.level_2),
        iff(p.depth + 1 = 3, c.account_name, p.level_3),
        iff(p.depth + 1 = 4, c.account_name, p.level_4),
        p.path || ' > ' || c.account_id
    from {{ ref('stg_cascade__gl_accounts') }} as c
    inner join paths as p on c.parent_account_id = p.account_id
),

leaves as (
    select a.account_id
    from {{ ref('stg_cascade__gl_accounts') }} as a
    where not exists (
        select 1 from {{ ref('stg_cascade__gl_accounts') }} as c
        where c.parent_account_id = a.account_id
    )
)

select
    {{ dbt_utils.generate_surrogate_key(['p.account_id']) }}     as account_key,
    p.account_id                                                 as account_number,
    p.account_name,
    p.account_type,
    iff(p.account_type in ('Asset', 'Expense'), 'Debit', 'Credit') as normal_balance,
    iff(p.account_type in ('Revenue', 'Expense'), 'Income Statement', 'Balance Sheet') as financial_statement,
    p.depth                                                      as hierarchy_depth,
    l.account_id is not null                                     as is_leaf,
    p.path                                                       as hierarchy_path,
    -- Fixed-depth flattening: pad short branches with the deepest real level
    p.level_1,
    coalesce(p.level_2, p.level_1)                               as level_2,
    coalesce(p.level_3, p.level_2, p.level_1)                    as level_3,
    coalesce(p.level_4, p.level_3, p.level_2, p.level_1)         as level_4
from paths as p
left join leaves as l on l.account_id = p.account_id
