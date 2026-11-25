# Knowledge base

Agent-oriented reference for this repo: compact, searchable, and grounded in the study site (`site/docs/`) and the
lab dbt project (`dbt/`). The `kimball-modeler` agent (`.claude/agents/kimball-modeler.md`) answers from these
files first; people can read them too.

## Files

| File | Use it for | Maintained |
|---|---|---|
| [`techniques.md`](techniques.md) | One card per Kimball technique: idea, when to use, pitfalls, dbt pattern, DWT3 chapter, lesson path, lab model | by hand |
| [`decision-guides.md`](decision-guides.md) | "Which fact type / grain / SCD type / bridge / incremental strategy?" decision procedures | by hand |
| [`conventions.md`](conventions.md) | How code and lessons in this repo must be written (keys, special members, tests, MDX rules) | by hand |
| [`review-checklist.md`](review-checklist.md) | Severity-ranked checklist for reviewing a design, model or query | by hand |
| [`lab-catalog.md`](lab-catalog.md) | Every dbt model: layer, materialization, inputs, consumers, tests, header comment (grain and technique) | **generated**: `python dbt/scripts/build_lab_catalog.py` |

## Where to look for what

| Question type | First stop | Then |
|---|---|---|
| "What is X / when do I use X?" | `techniques.md` (search the technique name) | the lesson path on the card |
| "Should I use X or Y?" | `decision-guides.md` | the linked lesson |
| "Show me an example of X" | `lab-catalog.md` → model file under `dbt/` | `dbt/analyses/` for queries |
| "Review my model / design / query" | `review-checklist.md` + `conventions.md` | the relevant technique cards |
| "Write me a model for X" | `conventions.md` + the closest lab model | then verify with the smoke test |
| "What does the book say about X?" | `site/docs/reference/reading-guide.mdx` and the card's DWT3 chapter | point to the chapter; don't quote it |
| "Quiz me" | `<Quiz>` blocks in `site/docs/**` and `site/docs/practice/*` | |
| Definitions | `site/docs/reference/glossary.mdx` | |
| Every technique → lesson → chapter | `site/docs/reference/techniques-index.mdx` | |

Useful searches:

```bash
grep -n "^### " knowledge/techniques.md                 # list all technique cards
grep -rn "Type 2" site/docs --include=*.mdx -l           # lessons mentioning a topic
grep -n -A30 '### `fct_order_lines`' knowledge/lab-catalog.md   # one model's catalog entry
grep -rln "valid_from" dbt/models                        # code using a pattern
```

## Asking the agent

In Claude Code, from this repo, ask for the agent by name or just ask a modeling question:

- "Use the kimball-modeler agent: what's the difference between Type 6 and Type 7, with lab examples?"
- "Ask kimball-modeler to review `dbt/models/marts/orders/fct_order_lines.sql` against the checklist."
- "kimball-modeler: design a star for gym check-ins and memberships, four steps plus bus-matrix row."
- "kimball-modeler: quiz me on semi-additive facts, five questions, harder than the site's."
- "kimball-modeler: write a dbt model for a customer returns fact following the repo conventions, and run the smoke test."
- "kimball-modeler: which lessons should I read before tackling bridge tables? Make me a study plan."

## Keeping it current

- After changing dbt models: `cd dbt && dbt compile --profiles-dir ci && python scripts/build_lab_catalog.py`.
  CI fails if `lab-catalog.md` is stale.
- When adding a lesson or lab model for a technique, update that technique's card in `techniques.md`.
