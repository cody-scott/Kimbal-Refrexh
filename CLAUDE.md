# Kimball Refresh

A study site (`site/`, Docusaurus) and a companion dbt lab (`dbt/`, Snowflake dialect) for learning Kimball
dimensional modeling. The primary source is *The Data Warehouse Toolkit, 3rd ed.*; lessons paraphrase it and
must never reproduce its text.

## Where things are

- `knowledge/`: agent-oriented reference. Start at `knowledge/README.md`. `lab-catalog.md` is generated; don't
  edit it by hand.
- `.claude/agents/kimball-modeler.md`: subagent for modeling questions, reviews, designs, quizzes and building
  lab models. Delegate dimensional modeling work to it.
- `site/docs/<module>/*.mdx`: lessons. Components: `<KimballRef>`, `<DbtFile path=... lines=...>`, `<Quiz>`.
- `dbt/models/{staging,intermediate,marts,semantic}`: the lab. Seeds come from `dbt/scripts/generate_seeds.py`.

## Rules

Follow `knowledge/conventions.md` for all code and lessons (keys, special members, half-open Type 2 joins, required
tests, MDX rules).

## Verify

```bash
cd dbt && dbt compile --profiles-dir ci && python scripts/smoke_test_duckdb.py   # no Snowflake needed
python scripts/build_lab_catalog.py                                              # refresh knowledge/lab-catalog.md
cd site && npm run build                                                         # fails on broken links or stale DbtFile ranges
```

CI (`.github/workflows/`) runs the same checks. The site deploys to GitHub Pages from `main`.
