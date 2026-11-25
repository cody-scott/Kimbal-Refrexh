# Decision guides

Short decision procedures for the questions that come up in almost every dimensional design. Each guide ends with
the lesson to read for depth (paths under `site/docs/`).

---

## Which fact table type?

```text
Is the question about EVENTS (what happened)?            -> Transaction fact
Is it about a LEVEL / STATE at points in time?           -> Periodic snapshot (dense)
Is it about a PIPELINE with standard milestones
  and a start and end (velocity, where things are stuck)? -> Accumulating snapshot
Is there nothing to measure, only that something
  happened, or what COULD have happened?                 -> Factless (event or coverage)
```

Often more than one: inventory = snapshot + transactions; orders = line transactions + order accumulating
snapshot; HR = events + headcount snapshot.
→ `facts/index.mdx`, `foundations/declaring-the-grain.mdx`

## What grain?

1. Start from the **most atomic event** the source captures (ticket line, not ticket; ticket, not daily total).
2. Write it as a sentence: "one row per ___ per ___".
3. Check every candidate dimension is **single-valued** per row; if not → bridge or a different grain.
4. Check every candidate fact is **true to the grain**; if it lives on a header → allocate or a separate fact.
5. If two sets of facts have different natural grains → **two fact tables**.
→ `foundations/declaring-the-grain.mdx`

## Is this number a fact or an attribute?

| Varies per event and is summed or averaged | Stable descriptor used to filter or group | Both |
|---|---|---|
| fact | dimension attribute (banded) | fact on the event and band on the dimension |

→ `facts/keys-nulls-and-hygiene.mdx#numeric-values-fact-or-attribute`

## Choosing an SCD type

Decide **per attribute**, with the business:

```text
Correction (typo, data fix)?                                   -> Type 1
Nobody analyzes facts by it?                                   -> Type 1
Definitionally "original"/"at signup"?                         -> Type 0
Facts must show the value AT THE TIME of the event?
   Rapidly changing, in a big dimension?                       -> Type 4 mini-dimension (+ Type 5 for current profile)
   Otherwise                                                   -> Type 2
   ...and users also want "as is" (current) reporting?         -> + durable key on facts (Type 7) or current columns (Type 6)
After a planned reorg, ALL history under old AND new structure? -> Type 3 (prior_x column)
```

Lab defaults: Type 2 + durable key on facts (Type 7 available for free).
→ `scd/choosing-a-strategy.mdx`

## Snapshot or change log for Type 2?

| Source offers | Use |
|---|---|
| CDC stream, audit table, change log, loader history mode | **Reconstruct** (macro `scd2_from_change_log`): complete, business-dated, rebuildable |
| Only current state | **dbt snapshot**: start early, run at least as often as changes, make the table non-transient, never drop it |

→ `scd/snapshots-vs-change-logs.mdx`

## Many values per fact row?

```text
Exactly N named, ranked values (primary/secondary)?  -> positional columns or role-playing FKs
Variable number of values?                           -> bridge table (group key + weighting factor)
   Values change over time and history matters?      -> time-varying bridge (valid_from/valid_to)
Variable-depth parent/child (org chart, accounts)?   -> hierarchy bridge (ancestor/descendant pairs) or pathstring
   Only slightly ragged?                             -> flatten + pad
```

→ `advanced/multivalued-dimensions-and-bridges.mdx`, `advanced/ragged-and-recursive-hierarchies.mdx`

## One transaction fact or several?

Same dimensionality and same facts across transaction types → **one fact + transaction-type dimension**.
Different dimensions or measures (invoices with tax and freight, receipts with inspection results) → **separate
fact tables**.
→ `case-studies/procurement.mdx`

## Where do these flags go?

```text
Belongs to an existing dimension's entity?           -> attribute of that dimension
Document number with no attributes?                  -> degenerate dimension on the fact
Several low-cardinality flags with no home?          -> junk dimension
Free text?                                           -> text comments dimension
```

→ `dimensions/junk-dimensions.mdx`, `dimensions/degenerate-dimensions.mdx`

## Missing / not-applicable / late dimension members

| Situation | Key |
|---|---|
| Value expected but missing or unmatched (data problem) | `-1` Unknown, and monitor it |
| Legitimately no value (anonymous shopper, no receipt) | `-2` (business-meaningful label) |
| Milestone not reached (accumulating snapshot) | date key `-2` "Not Yet Happened" |
| Explicit business "none" (no promotion) | a real row ("No Promotion in Effect") |
| Member exists in facts before the dimension | inferred member row, `is_inferred_member = true` |

→ `dimensions/special-members.mdx`

## Comparing two processes

Constant need at one grain → **consolidated fact**. Otherwise → **drill-across**: aggregate each fact separately to
the shared conformed attributes, then full outer join. Never join facts at atomic grain.
→ `bus/conformed-facts-and-drill-across.mdx`, `advanced/consolidated-fact-tables.mdx`

## Build an aggregate?

Only if a rollup is queried constantly, the atomic fact is huge, or a tool can't push down SQL. Must tie out to
atomic (singular test); must use shrunken conformed dimensions; document whether it rolls up by historical or
current attributes.
→ `advanced/aggregates-and-shrunken-dimensions.mdx`

## Incremental strategy (dbt on Snowflake)

| Fact type | Strategy |
|---|---|
| Transaction, moderate size | `merge`, `unique_key` = grain, lookback window |
| Transaction, very large / backfills by date | `microbatch` on event time (dbt 1.9+), or merge + `incremental_predicates` |
| Periodic snapshot | `delete+insert` by period (or merge on grain) |
| Accumulating snapshot | full rebuild, or merge on instance key for instances with new events |
| Stateful history (snapshots, `dim_audit`) | never rebuild; `full_refresh=false`, non-transient |

→ `dbt/incremental-facts.mdx`

## Star vs One Big Table

Stars are the foundation (conformed, history-aware, one definition per attribute). Wide tables are an *output*
materialized from stars for a specific tool or ML use.
→ `foundations/modeling-approaches.mdx`
