"""
Smoke-test the Snowflake-dialect dbt project without a Snowflake account.

1. `dbt compile --profiles-dir ci` renders all Jinja (refs, macros, tests).
2. This script reads target/manifest.json, loads the seeds into DuckDB,
   transpiles each compiled model from Snowflake SQL to DuckDB SQL with
   sqlglot, builds the models in dependency order, and runs every data test.

Usage (from dbt/):
    dbt deps && dbt compile --profiles-dir ci
    python scripts/smoke_test_duckdb.py

Exit code 1 on any build or test failure. Snapshots, unit tests and the
semantic layer are not exercised (they need a real warehouse or dbt Cloud).
"""

from __future__ import annotations

import json
import re
import sys
from graphlib import TopologicalSorter
from pathlib import Path

import duckdb
import sqlglot
from sqlglot import exp

ROOT = Path(__file__).resolve().parents[1]
manifest = json.loads((ROOT / "target" / "manifest.json").read_text())
nodes = manifest["nodes"]

TYPE_MAP = {
    "timestamp_ntz": "TIMESTAMP",
    "integer": "INTEGER",
    "varchar": "VARCHAR",
    "date": "DATE",
}


def duck_type(t: str) -> str:
    t = t.lower()
    if t.startswith("number"):
        return t.replace("number", "DECIMAL")
    return TYPE_MAP.get(t, t.upper())


def relation(node) -> str:
    return f'"{node["database"]}"."{node["schema"]}"."{node["alias"]}"'


FORMAT_MAP = [("YYYY", "%Y"), ("MM", "%m"), ("DD", "%d")]


def _to_char(m: re.Match) -> str:
    fmt = m.group(2)
    for sf, dk in FORMAT_MAP:
        fmt = fmt.replace(sf, dk)
    return f"strftime({m.group(1)}, '{fmt}')"


def transpile(sql: str) -> str:
    # sqlglot drops the format argument of Snowflake TO_CHAR; translate it first.
    sql = re.sub(r"to_char\(([^,()]+(?:\([^()]*\))?), '([^']+)'\)", _to_char, sql, flags=re.I)
    out = []
    for tree in sqlglot.parse(sql, read="snowflake"):
        # Snowflake names VALUES columns column1..N; DuckDB names them col0..
        for values in tree.find_all(exp.Values):
            if not values.alias and values.expressions:
                n = len(values.expressions[0].expressions)
                values.set("alias", exp.TableAlias(
                    this=exp.to_identifier("v"),
                    columns=[exp.to_identifier(f"column{i + 1}") for i in range(n)],
                ))
        out.append(tree.sql(dialect="duckdb"))
    return ";\n".join(out)


any_node = next(n for n in nodes.values() if n["resource_type"] == "model")
# Build into a separate file attached under the compiled database name, so the
# profile's own (empty) database is untouched and `dbt compile` never sees
# existing tables (which would flip is_incremental() to true).
db_path = ROOT / "target" / "smoke.duckdb"
db_path.unlink(missing_ok=True)
con = duckdb.connect()
con.execute(f"attach '{db_path}' as \"{any_node['database']}\"")
selected = {
    uid: n for uid, n in nodes.items()
    if n["resource_type"] in ("seed", "model", "test", "analysis") and n["package_name"] == "kimball_lab"
}

graph = {uid: [d for d in n["depends_on"].get("nodes", []) if d in selected] for uid, n in selected.items()}
order = list(TopologicalSorter(graph).static_order())

failures: list[str] = []
built = tested = analyses = 0
for uid in order:
    n = selected[uid]
    rt = n["resource_type"]
    con.execute(f'create schema if not exists "{n["database"]}"."{n["schema"]}"')
    try:
        if rt == "seed":
            types = {k: duck_type(v) for k, v in n["config"].get("column_types", {}).items()}
            csv_path = ROOT / n["original_file_path"]
            col_types = ", ".join(f"'{k}': '{v}'" for k, v in types.items())
            types_arg = f", types={{{col_types}}}" if types else ""
            con.execute(
                f"create or replace table {relation(n)} as "
                f"select * from read_csv('{csv_path}', header=true, all_varchar=false{types_arg})"
            )
            built += 1
        elif rt == "model":
            mat = n["config"]["materialized"]
            sql = transpile(n["compiled_code"])
            kind = "view" if mat == "view" else "table"
            con.execute(f"create or replace {kind} {relation(n)} as {sql}")
            built += 1
        elif rt == "analysis":
            con.execute(f"select count(*) from ({transpile(n['compiled_code'])}) t").fetchone()
            analyses += 1
        else:  # data test
            sql = transpile(n["compiled_code"])
            fail_calc = n["config"].get("fail_calc", "count(*)")
            bad = con.execute(f"select {fail_calc} from ({sql}) t").fetchone()[0] or 0
            tested += 1
            if bad:
                failures.append(f"TEST FAIL  {n['name']}: {bad} failing rows")
    except Exception as exc:  # noqa: BLE001
        failures.append(f"ERROR      {rt} {n['name']}: {str(exc).splitlines()[0][:300]}")

print(f"built {built} seeds/models, ran {tested} data tests, executed {analyses} analyses")
for f in failures:
    print(f)
sys.exit(1 if failures else 0)
