# Dimensional design review checklist

Use this to review a proposed star, a dbt model, or a query. Severity: **🔴 blocker** (wrong numbers),
**🟠 major** (fragile or hard to use), **🟡 minor** (convention or clarity).

## Business process and grain

- 🔴 Is there a grain statement in business language, and does every row match it?
- 🔴 Is the grain enforced by a uniqueness test on the grain columns?
- 🔴 Mixed grains (lines and headers, daily actuals and monthly budgets) in one table?
- 🟠 Is the grain atomic? If not, is a summary-only design justified?
- 🟠 Is the table named for a business process (not a report or department)?

## Facts

- 🔴 Header-level amounts repeated on line rows?
- 🔴 Stored ratios, percentages, averages or unit prices that will be summed?
- 🔴 Semi-additive facts (balances, levels) documented and not summed across time in queries?
- 🟠 Extended amounts stored (not just unit amounts)?
- 🟠 Distinct counts in aggregates labeled non-additive?
- 🟡 Facts conformed (same definition and name) across fact tables?

## Foreign keys and joins

- 🔴 Any fact FK that can be null? (Should point at Unknown `-1` / N/A `-2` rows.)
- 🔴 Fact-to-Type-2-dimension joins point-in-time with a half-open interval on the **event** timestamp?
- 🔴 Any join on a natural key to a Type 2 dimension (fan-out)? Is there a row-count reconciliation test?
- 🔴 Two fact tables joined directly at atomic grain (should be drill-across)?
- 🔴 "As is" reporting implemented as `join on surrogate key where is_current` (drops history)?
- 🟠 `relationships` tests on every FK?

## Dimensions

- 🟠 Surrogate keys (deterministic in dbt) rather than natural keys as PKs?
- 🟠 Hierarchies flattened (no snowflaking); ragged hierarchies handled with bridge or padding?
- 🟠 Special members present (Unknown; Not applicable where meaningful)?
- 🟠 SCD type decided and documented per attribute? Type 2 tested with `scd2_valid_ranges`?
- 🟠 Rapidly changing attributes in a mini-dimension rather than Type 2?
- 🟡 Verbose labels instead of codes and Y/N flags; no null text attributes?
- 🟡 Attribute names unique across the star (`store_city` vs `customer_city`)?
- 🟡 Low-cardinality flags in a junk dimension rather than on the fact?

## Integration

- 🔴 More than one model for the same conceptual dimension (non-conformed)?
- 🟠 Does the design reuse the conformed dimensions in `marts/core`?
- 🟠 Do shrunken or rollup dimensions derive from the base dimension?
- 🟡 Bus matrix updated?

## Multivalued and hierarchies

- 🔴 Bridge used without weighting where totals must tie? Weights sum to 1 (test)?
- 🔴 Hierarchy bridge rollups grouping by all ancestors at once (double counting)?
- 🟠 Facts attach to leaves only (or each node once)?

## dbt and Snowflake

- 🔴 Incremental `unique_key` exactly equals the grain?
- 🔴 Incremental filter catches late-arriving rows (lookback or load timestamp)?
- 🟠 Full refresh produces the same result as incremental history?
- 🟠 Stateful tables (snapshots, `dim_audit`) protected: `full_refresh=false`, non-transient?
- 🟡 `cluster_by` only on large facts, on the common filter column?
- 🟡 Model and column descriptions, with the grain and SCD policy documented?

## Answer format for a review

1. **Verdict:** one line.
2. **Findings:** ordered by severity, each with *what*, *why it matters (consequence)*, *fix*, and the Kimball
   technique and lesson path.
3. **What's good:** brief.
