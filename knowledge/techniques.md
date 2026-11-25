# Kimball technique cards

One card per technique in the Kimball Group's dimensional modeling techniques list, using the Kimball names.
Each card gives the idea, when to use it, the pitfalls, the dbt/Snowflake pattern, and pointers into this repo.

- **DWT3** = *The Data Warehouse Toolkit, 3rd ed.* (Kimball & Ross). Ch. 2 summarizes every technique; the
  chapter listed is where it is taught in depth.
- **Lesson** paths are under `site/docs/`. **Lab** names are dbt models in `dbt/` (see `lab-catalog.md`).
- Explanations are original paraphrases. Point people to the book for the authoritative text.

---

## Fundamental concepts

### Four-step dimensional design process
- **DWT3:** Ch. 3 · **Lesson:** `foundations/four-step-process.mdx` · **Lab:** header of `fct_retail_sales`
- **What:** Design every star with four decisions in order: (1) select the business process, (2) declare the
  grain, (3) identify the dimensions, (4) identify the facts.
- **Key rule:** grain comes before dimensions and facts; it decides which dimensions are single-valued and which
  facts are true to a row.
- **Pitfall:** starting from a report or from source tables instead of a business process.

### Business processes
- **DWT3:** Ch. 3 · **Lesson:** `foundations/four-step-process.mdx`
- **What:** Operational activities that generate measurement events (verbs: sell, receive, ship, pay, enroll).
  Each becomes one or more fact tables. Not departments, not reports.
- **Pitfall:** "Marketing fact table". Marketing consumes several processes.

### Grain
- **DWT3:** Ch. 3, 4 · **Lesson:** `foundations/declaring-the-grain.mdx` · **Lab:** grain tests on every fact
- **What:** A business-language statement of exactly what one fact row represents. Prefer the most atomic grain
  the source captures.
- **dbt:** enforce with `dbt_utils.unique_combination_of_columns` on the grain columns plus `dbt_utils.equal_rowcount`
  against the source (catches fan-out).
- **Pitfalls:** mixed grains in one table; grain stated as a column list; a Type 2 join that fans out.

### Gather business requirements and data realities
- **DWT3:** Ch. 1, 18 · **Lesson:** `foundations/requirements-and-workshops.mdx`
- **What:** Balance what the business needs (decisions, measures, "by" phrases) with what sources capture (grain,
  quality, key stability, history). Profile data before designing.
- **dbt:** encode profiling findings as staging tests.

### Collaborative dimensional modeling workshops
- **DWT3:** Ch. 18 · **Lesson:** `foundations/requirements-and-workshops.mdx`
- **What:** Business experts and modelers design together, process by process: high-level bubble chart, then
  detailed column-level design (source, SCD type, rules), with an issues log.

### Dimensions for descriptive context
- **DWT3:** Ch. 1, 3 · **Lesson:** `foundations/star-schema-anatomy.mdx`
- **What:** Wide, denormalized, verbose tables of the who/what/where/when/why/how. Their attributes are the
  filters, groupings and labels. Rule of thumb: in `GROUP BY` or `WHERE`, it's a dimension attribute.

### Facts for measurements
- **DWT3:** Ch. 1, 3 · **Lesson:** `foundations/star-schema-anatomy.mdx`
- **What:** Numeric measurements of a process event at the declared grain, preferably additive. Rule of thumb:
  inside `SUM()`, it's a fact.

### Star schemas and OLAP cubes
- **DWT3:** Ch. 1 · **Lesson:** `foundations/why-dimensional-modeling.mdx`
- **What:** A fact table joined directly to its dimensions (one hop each). Cubes are the multidimensional
  equivalent; today, semantic layers play much of the cube role.

### Graceful extensions to dimensional models
- **DWT3:** Ch. 3 · **Lesson:** `foundations/star-schema-anatomy.mdx#graceful-extensions`
- **What:** Atomic stars absorb change without breaking queries: new attributes (add columns), new single-valued
  dimensions (add an FK; history points at a special row), new facts at the same grain.

---

## Basic fact table techniques

### Fact table structure
- **DWT3:** Ch. 3 · **Lesson:** `facts/keys-nulls-and-hygiene.mdx`
- **What:** Dimension FKs + optional degenerate dimensions + numeric facts. Deep and narrow; every row at one grain.

### Additive, semi-additive, non-additive facts
- **DWT3:** Ch. 3, 4 · **Lesson:** `facts/additivity.mdx` · **Lab:** `fct_retail_sales` (additive),
  `fct_inventory_daily_snapshot` and `fct_gl_monthly_balance.ending_balance_amount` (semi-additive)
- **What:** Additive facts sum across all dimensions. Semi-additive facts (balances, levels, headcount) don't sum
  across time: use the period-end value or the average of per-period totals. Non-additive facts (ratios, unit
  prices, distinct counts) never sum: store the additive components and compute at query time.
- **dbt:** semantic layer `non_additive_dimension` for semi-additive measures; ratio metrics for ratios.
- **Pitfalls:** stored percentages; `AVG(margin_pct)`; summing balances across days.

### Nulls in fact tables
- **DWT3:** Ch. 3 · **Lesson:** `facts/keys-nulls-and-hygiene.mdx`
- **What:** Null *facts* are fine (aggregates ignore them). Null *foreign keys* are not. Point them at special
  dimension rows (`-1` Unknown, `-2` Not applicable / Not yet happened).
- **Lab:** `dim_key()` macro = `coalesce(key, '-1')`.

### Conformed facts
- **DWT3:** Ch. 4 · **Lesson:** `bus/conformed-facts-and-drill-across.mdx`
- **What:** A measure appearing in several fact tables has an identical definition (and unit and currency), or it
  gets a different name.

### Transaction fact tables
- **DWT3:** Ch. 3, 6 · **Lesson:** `facts/transaction-fact-tables.mdx` · **Lab:** `fct_retail_sales`, `fct_order_lines`,
  `fct_inventory_transactions`, `fct_gl_journal_lines`
- **What:** One row per measurement event. Sparse, atomic, insert-only (corrections arrive as reversing rows).
- **dbt:** `incremental`, `merge` with `unique_key` = grain, a lookback window, `cluster_by` on the date key.

### Periodic snapshot fact tables
- **DWT3:** Ch. 4, 7, 9 · **Lesson:** `facts/periodic-snapshot-fact-tables.mdx` · **Lab:** `fct_inventory_daily_snapshot`,
  `fct_gl_monthly_balance`, `fct_headcount_monthly`
- **What:** One row per entity per regular period, dense (rows even when nothing changed). Records state:
  semi-additive levels plus additive period activity.
- **dbt:** build density with spine × entities and fill-forward; incremental by period (`delete+insert`).

### Accumulating snapshot fact tables
- **DWT3:** Ch. 4, 6, 13, 16 · **Lesson:** `facts/accumulating-snapshot-fact-tables.mdx` · **Lab:** `fct_po_line_pipeline`,
  `fct_order_fulfillment`
- **What:** One row per process instance with a defined start, standard milestones and an end. One role-playing date
  FK per milestone; lag facts; milestone counters; rows are **updated** as milestones occur.
- **dbt:** pivot milestones from an event log; full rebuild, or incremental merge on the instance key. Unreached
  milestones → date key `-2`.
- **Pitfall:** processes that loop or branch. Use a transaction fact of status changes instead or as well.

### Factless fact tables
- **DWT3:** Ch. 3, 13 · **Lesson:** `facts/factless-fact-tables.mdx` · **Lab:** `fct_promotion_coverage` (coverage),
  `fct_employee_events` (events with counters)
- **What:** Keys with no measures; the row's existence is the fact. Two kinds: event tracking (attendance) and
  coverage (eligibility), used to find what did **not** happen: coverage MINUS activity.
- **Lab query:** `analyses/promoted_products_that_did_not_sell.sql`.

### Aggregate fact tables or OLAP cubes
- **DWT3:** Ch. 4, 19 · **Lesson:** `advanced/aggregates-and-shrunken-dimensions.mdx` · **Lab:** `agg_sales_monthly_category_store`
- **What:** Pre-summarized copies of atomic facts at a coarser grain, for performance only. They must return
  exactly the atomic answer, using shrunken conformed dimensions.
- **dbt:** a singular test that totals tie (`tests/assert_aggregate_ties_to_atomic_fact.sql`). On Snowflake, often
  unnecessary; consider materialized or dynamic tables.

### Consolidated fact tables
- **DWT3:** Ch. 7 · **Lesson:** `advanced/consolidated-fact-tables.mdx` · **Lab:** `fct_budget_vs_actual`
- **What:** Facts from several processes pre-combined at a common grain (budget vs actual). Roll each up to the
  common grain first, then full outer join.

---

## Basic dimension table techniques

### Dimension table structure
- **DWT3:** Ch. 3 · **Lesson:** `foundations/star-schema-anatomy.mdx`
- **What:** Single surrogate PK, natural key, many verbose descriptive attributes, flattened hierarchies, row admin
  columns (for Type 2).

### Dimension surrogate keys
- **DWT3:** Ch. 3 · **Lesson:** `dimensions/surrogate-keys.mdx`
- **What:** A warehouse key with no meaning, one per dimension row (version). Enables Type 2 history, special
  members, integration and insulation from source keys.
- **dbt:** deterministic hash, `dbt_utils.generate_surrogate_key([natural_key, valid_from])`. Sequences break on
  rebuild; use a persisted incremental key map if integers are required.

### Natural, durable, and supernatural keys
- **DWT3:** Ch. 3 · **Lesson:** `dimensions/surrogate-keys.mdx`
- **What:** Natural key = source identifier. Durable (supernatural) key = warehouse key stable across all versions
  and sources. **Lab:** `product_durable_key = hash(sku)`.

### Drilling down
- **DWT3:** Ch. 3 · **Lesson:** `dimensions/attributes-and-hierarchies.mdx`
- **What:** Adding a more detailed dimension attribute (row header) to a query. Works because hierarchies are
  flattened.

### Degenerate dimensions
- **DWT3:** Ch. 3, 6 · **Lesson:** `dimensions/degenerate-dimensions.mdx` · **Lab:** `transaction_id`, `order_number`,
  `po_number`, `journal_entry_id`
- **What:** A dimension key on the fact with no dimension table (transaction/document numbers). Used for grouping
  lines into baskets and orders, as part of the grain and merge key, and for traceability.

### Denormalized flattened dimensions
- **DWT3:** Ch. 3 · **Lesson:** `dimensions/attributes-and-hierarchies.mdx` · **Lab:** `dim_product`, `dim_store`
- **What:** Hierarchy levels are columns on the member's row (product → subcategory → category → department), not
  separate tables.

### Multiple hierarchies in dimensions
- **DWT3:** Ch. 3 · **Lesson:** `dimensions/attributes-and-hierarchies.mdx#multiple-hierarchies`
- **What:** Independent rollups (geographic, format, size band) coexist as columns in one dimension.

### Flags and indicators as textual attributes
- **DWT3:** Ch. 3 · **Lesson:** `dimensions/attributes-and-hierarchies.mdx#flags-and-indicators-as-text`
- **What:** User-facing flags are readable values ('Weekend' / 'Weekday'), not Y/N or booleans. Keep `is_*`
  booleans only as SQL conveniences.

### Null attributes in dimensions
- **DWT3:** Ch. 3 · **Lesson:** `dimensions/attributes-and-hierarchies.mdx#null-attributes`
- **What:** Replace nulls in text attributes with 'Unknown', 'Not Applicable' or 'None' so grouping and filtering
  behave. True numerics and dates may stay null.

### Calendar date dimensions
- **DWT3:** Ch. 3 · **Lesson:** `dimensions/date-dimension.mdx` · **Lab:** `dim_date`
- **What:** One row per day with calendar, fiscal, holiday and indicator attributes, built decades wide. A smart
  integer key YYYYMMDD is allowed for dates only.
- **Snowflake:** `table(generator(rowcount => N))` with `row_number() over (order by seq4())`, since `seq4()` can
  have gaps; `dayofweekiso()`.
- **Pitfall:** relative attributes (`is_current_month`) go stale. Compute them in a view or semantic layer.

### Role-playing dimensions
- **DWT3:** Ch. 6, 12 · **Lesson:** `dimensions/role-playing-dimensions.mdx` · **Lab:** `dim_order_date`, `dim_ship_date`
  (views of `dim_date`)
- **What:** One physical dimension referenced several times by a fact in different roles. Expose a view per role
  with role-prefixed column names.

### Junk dimensions
- **DWT3:** Ch. 6 · **Lesson:** `dimensions/junk-dimensions.mdx` · **Lab:** `dim_order_profile`
- **What:** Low-cardinality flags and indicators combined into one dimension (Cartesian product if small, observed
  combinations if large). Avoids centipedes and text clutter on facts.

### Snowflaked dimensions
- **DWT3:** Ch. 3 · **Lesson:** `dimensions/outriggers-and-snowflaking.mdx`
- **What:** Normalizing a dimension's hierarchy into separate tables. Discouraged for presentation: harder to use,
  more joins, negligible savings. Normalize upstream if you like, but flatten in the mart.

### Outrigger dimensions
- **DWT3:** Ch. 3 · **Lesson:** `dimensions/outriggers-and-snowflaking.mdx#outriggers`
- **What:** A secondary dimension referenced by a dimension (e.g. county demographics via the customer, a
  product's launch date via a date key). Allowed sparingly, when an attribute cluster has a different grain or
  cadence.

---

## Integration via conformed dimensions

### Conformed dimensions
- **DWT3:** Ch. 4 · **Lesson:** `dimensions/conformed-dimensions.mdx` · **Lab:** `models/marts/core/`
- **What:** Same keys, attribute names, values and meaning across every fact table that uses the dimension. This is
  the integration backbone and what makes drill-across possible.
- **dbt:** exactly one model per conformed dimension, referenced via `ref()` by every fact; facts never re-derive
  dimension attributes.

### Shrunken dimensions
- **DWT3:** Ch. 4 · **Lesson:** `dimensions/conformed-dimensions.mdx#shrunken-dimensions` · **Lab:** `dim_month`,
  `dim_product_category`
- **What:** Conformed subsets: rollups (month, category) for aggregates or naturally coarse facts (budgets), or row
  and column subsets. Build them *from* the base dimension so values are identical.

### Drilling across
- **DWT3:** Ch. 4 · **Lesson:** `bus/conformed-facts-and-drill-across.mdx` · **Lab:** `analyses/drill_across_sales_vs_inventory.sql`
- **What:** Aggregate each fact separately to the common grain on conformed attributes, then full outer join the
  results. Never join fact tables directly at atomic grain.

### Value chain
- **DWT3:** Ch. 4 · **Lesson:** `bus/value-chain-and-roadmap.mdx`
- **What:** The sequence of processes a product flows through (PO → receipt → inventory → sale → return), tied
  together by conformed dimensions.

### Enterprise data warehouse bus architecture
- **DWT3:** Ch. 4 · **Lesson:** `bus/index.mdx`
- **What:** Build the warehouse incrementally, process by process, all plugging into shared conformed dimensions.
  The alternative it avoids: independent data marts.

### Enterprise data warehouse bus matrix
- **DWT3:** Ch. 4, 5 · **Lesson:** `bus/bus-matrix.mdx`
- **What:** Rows = business processes, columns = conformed dimensions. Architecture, integration plan and roadmap
  on one page.

### Detailed implementation bus matrix
- **DWT3:** Ch. 4 · **Lesson:** `bus/bus-matrix.mdx#the-detailed-implementation-bus-matrix`
- **What:** One row per fact table, with grain, facts and dimension roles.

### Opportunity/stakeholder matrix
- **DWT3:** Ch. 4 · **Lesson:** `bus/bus-matrix.mdx#opportunitystakeholder-matrix`
- **What:** Business processes × stakeholder groups; used to prioritize which bus-matrix row to deliver next.

---

## Dealing with slowly changing dimension attributes

SCD type is chosen **per attribute**, with the business. Decision guide: `decision-guides.md#choosing-an-scd-type`.

### Type 0: Retain Original
- **DWT3:** Ch. 5 · **Lesson:** `scd/types-0-and-1.mdx` · **Lab:** `scd_type0_product`
- **What:** The value never changes ("original category", "acquisition channel"). Often carried alongside a
  current version of the attribute.

### Type 1: Overwrite
- **DWT3:** Ch. 5 · **Lesson:** `scd/types-0-and-1.mdx` · **Lab:** `scd_type1_product`, `dim_store`
- **What:** Replace the value; history is lost and old facts restate. Right for corrections and attributes nobody
  analyzes historically.
- **dbt:** the default when a dimension is rebuilt from current source state, so you get it *by accident* unless you
  preserve history.

### Type 2: Add New Row
- **DWT3:** Ch. 5, 9 · **Lesson:** `scd/type-2.mdx` · **Lab:** `dim_product`, `dim_customer`, `dim_employee`,
  `int_product_versions`, macro `scd2_from_change_log`
- **What:** Expire the current row and insert a new row with a new surrogate key. Row admin columns: `valid_from`,
  `valid_to` (far future `9999-12-31 23:59:59`, not null), `is_current`, `version_number`, optional
  `row_change_reason`.
- **dbt:** snapshots (observe) or change-log reconstruction (preferred when a CDC/change log exists). Fact join:
  `event_ts >= valid_from and event_ts < valid_to` (half-open). Test with `scd2_valid_ranges`.
- **Pitfalls:** joining facts on the natural key (fan-out); counting rows as entities; Type 2 on rapidly changing
  attributes; two same-instant changes producing two versions.

### Type 3: Add New Attribute
- **DWT3:** Ch. 5 · **Lesson:** `scd/type-3.mdx` · **Lab:** `scd_type3_product`
- **What:** A `prior_<attr>` column alongside the current value, for alternate-reality reporting of *all* history
  under old or new structure after a planned reorg. One level of history.
- **Pitfall:** taking `lag(attr)` of the latest Type 2 version. Wrong if that version was opened by a change to a
  different attribute. Use the last version where *this* attribute changed.

### Type 4: Add Mini-Dimension
- **DWT3:** Ch. 5, 8, 10, 16 · **Lesson:** `scd/type-4-mini-dimensions.mdx` · **Lab:** `dim_customer_demographics`
- **What:** Rapidly changing attributes of a large dimension, banded, split into a small dimension of
  combinations; the fact carries both keys (profile at time of event).
- **Pitfall:** unbanded values (the mini-dimension becomes one row per customer). Current profile isn't reachable
  without facts → Type 5.

### Type 5: Add Mini-Dimension and Type 1 Outrigger
- **DWT3:** Ch. 5 · **Lesson:** `scd/types-5-6-7.mdx` · **Lab:** `scd_type5_customer`
- **What:** Type 4 plus the *current* mini-dimension key on the base dimension, overwritten (4 + 1).

### Type 6: Add Type 1 Attributes to Type 2 Dimension
- **DWT3:** Ch. 5 · **Lesson:** `scd/types-5-6-7.mdx` · **Lab:** `scd_type6_product`
- **What:** Each Type 2 row carries the historical value and the current value (overwritten on all versions), so
  one join gives as-was and as-is (1 + 2 + 3).

### Type 7: Dual Type 1 and Type 2 Dimensions
- **DWT3:** Ch. 5 · **Lesson:** `scd/types-5-6-7.mdx` · **Lab:** `scd_type7_product_current`,
  `fct_retail_sales.product_durable_key`, `analyses/as_was_vs_as_is.sql`
- **What:** The fact carries the surrogate key (→ Type 2 dimension, as-was) and the durable key (→ current-rows view,
  as-is).
- **Pitfall:** "as is" via `join on product_key where is_current` drops every fact recorded under an old version.

---

## Dealing with dimension hierarchies

### Fixed depth positional hierarchies
- **DWT3:** Ch. 3, 7 · **Lesson:** `dimensions/attributes-and-hierarchies.mdx` · **Lab:** `dim_product`
- **What:** Same number of levels for every member → flatten to named columns.

### Slightly ragged/variable depth hierarchies
- **DWT3:** Ch. 7 · **Lesson:** `advanced/ragged-and-recursive-hierarchies.mdx` · **Lab:** `dim_account.level_1..level_4`
- **What:** Flatten to the maximum depth and pad short branches by repeating the lowest real level downward.

### Ragged/variable depth hierarchies with hierarchy bridge tables
- **DWT3:** Ch. 7, 9 · **Lesson:** `advanced/ragged-and-recursive-hierarchies.mdx` · **Lab:** `bridge_account_hierarchy`,
  `bridge_employee_reporting`, `analyses/rollup_through_hierarchy_bridge.sql`
- **What:** One row per ancestor/descendant pair (including self at distance 0), with levels between. Rollup =
  fact → bridge (descendant) → dimension (ancestor), filtered to one ancestor.
- **dbt/Snowflake:** `with recursive` CTE. Facts should attach to leaves (or each node once) to avoid double
  counting.

### Ragged/variable depth hierarchies with pathstring attributes
- **DWT3:** Ch. 7 · **Lesson:** `advanced/ragged-and-recursive-hierarchies.mdx#3-pathstrings` · **Lab:** `dim_account.hierarchy_path`
- **What:** Encode the root-to-node path as a string; subtree filters become `LIKE` or `startswith`. Simple, but
  awkward when nodes move.

---

## Advanced fact table techniques

### Fact table surrogate keys
- **DWT3:** Ch. 3 · **Lesson:** `facts/keys-nulls-and-hygiene.mdx#fact-table-surrogate-keys`
- **What:** Optional single-column fact key, useful for updates, deletes, parent/child fact links and restartable
  loads. In dbt, a hash of the grain columns.

### Centipede fact tables
- **DWT3:** Ch. 3 · **Lesson:** `facts/keys-nulls-and-hygiene.mdx#centipede-fact-tables`
- **What:** Far too many FKs (hierarchy levels as separate dimensions, many flag dimensions). Fix: flatten
  hierarchies into one dimension; use junk dimensions.

### Numeric values as attributes or facts
- **DWT3:** Ch. 3 · **Lesson:** `facts/keys-nulls-and-hygiene.mdx#numeric-values-fact-or-attribute` · **Lab:** `price_band`,
  `store_size_band`
- **What:** If a number varies per event and is aggregated, it's a fact; if it's stable and used for
  filtering or banding, it's an attribute; sometimes both.

### Lag/duration facts
- **DWT3:** Ch. 4, 6 · **Lesson:** `facts/accumulating-snapshot-fact-tables.mdx` · **Lab:** `*_lag_days`
- **What:** Elapsed time between milestones stored as facts so analysts can `AVG()` them. Null until both
  milestones exist.

### Header/line fact tables
- **DWT3:** Ch. 6 · **Lesson:** `advanced/header-line-and-allocation.mdx` · **Lab:** `fct_order_lines`, `fct_order_fulfillment`
- **What:** Header facts can't be repeated on line rows (double counting). Allocate them to lines, or keep a
  header-grain fact.

### Allocated facts
- **DWT3:** Ch. 6 · **Lesson:** `advanced/header-line-and-allocation.mdx` · **Lab:** `int_order_lines_allocated`
- **What:** Distribute a coarser-grain amount to finer rows using an agreed basis (value, quantity, weight). Rounding
  must tie out: the remainder goes to one line, enforced by a test.

### Profit and loss fact tables using allocations
- **DWT3:** Ch. 6, 15 · **Lesson:** `advanced/header-line-and-allocation.mdx#profit--loss-facts`
- **What:** Atomic-grain fact with revenue and every allocated cost component down to net profit; each
  component is its own column.

### Multiple currency facts
- **DWT3:** Ch. 6, 7 · **Lesson:** `advanced/multiple-currencies-and-units.mdx` · **Lab:** `fct_order_lines`
  (`*_local`, `*_usd`, `local_currency_key`)
- **What:** Store amounts in the transaction currency and a standard reporting currency (converted at the
  transaction-date rate), plus a currency dimension. Never sum local amounts across currencies.

### Multiple units of measure facts
- **DWT3:** Ch. 6 · **Lesson:** `advanced/multiple-currencies-and-units.mdx#multiple-units-of-measure`
- **What:** Store one standard unit; carry conversion factors on the product dimension (or on the fact if they vary).

### Year-to-date facts
- **DWT3:** Ch. 7 · **Lesson:** `advanced/more-techniques.mdx#year-to-date-facts`
- **What:** Don't store YTD values (non-additive, break on restatement). Compute with windows or cumulative metrics.

### Multipass SQL to avoid fact-to-fact table joins
- **DWT3:** Ch. 4 · **Lesson:** `advanced/consolidated-fact-tables.mdx`
- **What:** Query each fact separately and merge result sets. The mechanics of drill-across.

### Timespan tracking in fact tables
- **DWT3:** Ch. 8, 16 · **Lesson:** `advanced/more-techniques.mdx#timespan-tracking-in-fact-tables`
- **What:** Effective/expiration timestamps on fact rows that describe a state over an interval (coverage, status),
  queried "as of" with range predicates.

### Late arriving facts
- **DWT3:** Ch. 19 · **Lesson:** `advanced/late-arriving-data.mdx` · **Lab:** lookback in `fct_retail_sales`
- **What:** Facts arriving after later facts. Look up dimension versions by event time, not load time; incremental
  filters must catch them (lookback window or load timestamp); rebuild affected snapshots and aggregates.

---

## Advanced dimension techniques

### Dimension-to-dimension table joins
- **DWT3:** Ch. 8 · **Lesson:** `dimensions/outriggers-and-snowflaking.mdx#dimension-to-dimension-joins`
- **What:** Dimensions normally relate through facts; direct joins are limited to outriggers and patterns like the
  Type 5 outrigger.

### Multivalued dimensions and bridge tables
- **DWT3:** Ch. 8, 10, 14 · **Lesson:** `advanced/multivalued-dimensions-and-bridges.mdx` · **Lab:** `bridge_customer_interest`,
  `analyses/weighted_vs_impact_interest_report.sql`, `tests/assert_interest_weights_sum_to_one.sql`
- **What:** When a fact relates to many members of a dimension (interests, account owners, diagnoses), a bridge
  table (often via a group key) with a weighting factor summing to 1 per group.
- **Reports:** weighted (× factor, ties to totals) vs impact (unweighted, double counts by design; never sum).

### Time varying multivalued bridge tables
- **DWT3:** Ch. 8, 10 · **Lesson:** `advanced/multivalued-dimensions-and-bridges.mdx#time-varying-bridges`
- **What:** `valid_from` / `valid_to` on bridge rows, joined with the fact's event time.

### Behavior tag time series
- **DWT3:** Ch. 8 · **Lesson:** `advanced/more-techniques.mdx#behavior-tag-time-series`
- **What:** A segment label per customer per period (e.g. monthly RFM tags) kept as a series, to analyze transitions.

### Behavior study groups
- **DWT3:** Ch. 8 · **Lesson:** `advanced/more-techniques.mdx#behavior-study-groups`
- **What:** Persist the set of entity keys meeting a complex condition as a table; join it to any fact.

### Aggregated facts as dimension attributes
- **DWT3:** Ch. 8 · **Lesson:** `advanced/more-techniques.mdx#aggregated-facts-as-dimension-attributes`
- **What:** Behavior metrics (lifetime spend, recency) banded into dimension attributes for filtering, refreshed
  on a schedule.

### Dynamic value bands
- **DWT3:** Ch. 10 · **Lesson:** `scd/type-4-mini-dimensions.mdx#dynamic-value-bands`
- **What:** Ad hoc banding of a fact via a band-definition table joined with a range predicate.

### Text comments dimension
- **DWT3:** Ch. 9, 14 · **Lesson:** `advanced/more-techniques.mdx#text-comments-dimension`
- **What:** Free text goes in its own dimension referenced by the fact, not as a column on a big fact.

### Multiple time zones
- **DWT3:** Ch. 12 · **Lesson:** `dimensions/date-dimension.mdx#multiple-time-zones`
- **What:** Local and standard (UTC) date and time roles on the fact. Snowflake: `convert_timezone()`.

### Measure type dimensions
- **DWT3:** Ch. 14 · **Lesson:** `advanced/more-techniques.mdx#measure-type-dimensions`
- **What:** For hundreds of sparse measures, one fact row per measurement plus a measure-type dimension. Only for
  genuinely sparse, heterogeneous measures (arithmetic across measures needs a pivot).

### Step dimensions
- **DWT3:** Ch. 8, 15 · **Lesson:** `advanced/more-techniques.mdx#step-dimensions`, `case-studies/ecommerce-clickstream.mdx`
- **What:** Position of an event within a sequence (step n of m, first and last flags), e.g. for session paths.

### Hot swappable dimensions
- **DWT3:** Ch. 10 · **Lesson:** `advanced/more-techniques.mdx#hot-swappable-and-abstract-generic-dimensions`
- **What:** Alternative versions of a dimension sharing a key, chosen at query time (e.g. per-client product views).

### Abstract generic dimensions
- **DWT3:** Ch. 2 · **Lesson:** `advanced/more-techniques.mdx#hot-swappable-and-abstract-generic-dimensions`
- **What:** Kimball cautions *against* generic catch-all dimensions (one "location" for stores, customers and
  vendors). Give each role its own clear dimension.

### Audit dimensions
- **DWT3:** Ch. 6 · **Lesson:** `advanced/audit-dimension-and-error-events.mdx` · **Lab:** `dim_audit`,
  `fct_retail_sales.audit_key`
- **What:** Describes the load that produced each fact row. In dbt: `invocation_id` as `audit_key`; `dim_audit` is
  incremental with `full_refresh=false`.

### Late arriving dimensions
- **DWT3:** Ch. 19 · **Lesson:** `dimensions/special-members.mdx#late-arriving-dimensions-inferred-members` · **Lab:** `dim_employee`
  (`is_inferred_member`)
- **What:** A fact references a member not yet in the dimension. Create an inferred member row from the natural
  key, flag it, and overwrite its attributes (Type 1) when the real record arrives. Hashed keys make that automatic
  on rebuild.

---

## Special purpose schemas

### Supertype and subtype schemas for heterogeneous products
- **DWT3:** Ch. 10, 16 · **Lesson:** `advanced/supertype-subtype.mdx`
- **What:** A core fact and dimension of attributes common to all product lines, plus subtype facts and dimensions
  per line at the same grain and keys. dbt: build subtypes, union common columns into the core.

### Real-time fact tables
- **DWT3:** Ch. 19 · **Lesson:** `advanced/more-techniques.mdx#real-time-fact-tables`
- **What:** A hot partition of recent data merged with history. Snowflake: Dynamic Tables, Snowpipe Streaming +
  frequent incremental runs.

### Error event schemas
- **DWT3:** Ch. 19 · **Lesson:** `advanced/audit-dimension-and-error-events.mdx#error-event-schemas`
- **What:** Data-quality failures recorded as rows (check, table, record, run). dbt: `store_failures`,
  `run_results.json`, packages like elementary.
