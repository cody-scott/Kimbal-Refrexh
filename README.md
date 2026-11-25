# Kimball Refresh

[![dbt CI](https://github.com/cody-scott/Kimbal-Refrexh/actions/workflows/dbt-ci.yml/badge.svg)](https://github.com/cody-scott/Kimbal-Refrexh/actions/workflows/dbt-ci.yml)
[![Site](https://github.com/cody-scott/Kimbal-Refrexh/actions/workflows/deploy-site.yml/badge.svg)](https://github.com/cody-scott/Kimbal-Refrexh/actions/workflows/deploy-site.yml)

A comprehensive study guide and teaching site for **dimensional modeling the Kimball way**, implemented in
**dbt** on **Snowflake**.

- **`site/`**: the study site (Docusaurus): about 80 lessons across 9 modules, with quizzes, exercises, ER diagrams, case
  studies, a Kimball techniques index and progress tracking. Lessons embed SQL straight from the dbt project, so
  the code shown is always the code that runs.
- **`dbt/`**: the companion lab: a complete Kimball warehouse for the fictional retailer *Cascade Outfitters*
  (retail sales, inventory, procurement, web orders, general ledger, HR, CRM) covering transaction, periodic and
  accumulating snapshot facts, factless facts, SCD Types 0 to 7, mini/junk/role-playing/conformed dimensions,
  hierarchy and multivalued bridges, allocation, multi-currency, aggregates, consolidated facts, an audit dimension,
  tests, unit tests and a semantic layer.

The primary source throughout is *The Data Warehouse Toolkit, 3rd Edition* (Ralph Kimball & Margy Ross) and
the Kimball Group's published dimensional modeling techniques. The site is an independent study companion,
not affiliated with the Kimball Group or Wiley.

## Read the site

Published to GitHub Pages from `main`: <https://cody-scott.github.io/Kimbal-Refrexh/>

Run locally:

```bash
cd site
npm ci
npm start          # dev server with hot reload
npm run build      # production build (fails on broken links or stale code excerpts)
```

## Run the lab on Snowflake

```bash
cd dbt
pip install -r requirements.txt
cp profiles.example.yml ~/.dbt/profiles.yml   # set SNOWFLAKE_* env vars
dbt deps && dbt seed && dbt build
```

See the site's [Set up the lab](https://cody-scott.github.io/Kimbal-Refrexh/setup) page for details.

## Validate without Snowflake

CI compiles the project on DuckDB, transpiles the Snowflake SQL with sqlglot, builds the whole DAG and runs all
data tests and analyses:

```bash
cd dbt
dbt deps
dbt compile --profiles-dir ci
python scripts/smoke_test_duckdb.py
```

## GitHub Pages setup (one time)

Repository **Settings → Pages → Build and deployment → Source: GitHub Actions**. The `Site` workflow then
deploys on every push to `main`.
