"""
Verify that knowledge/*.md only references things that exist:
  * lesson paths (site/docs/...mdx), including #anchors
  * lab model / analysis / test names in backticks that look like dbt objects

Usage (repo root or dbt/): python dbt/scripts/check_knowledge_refs.py
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
DOCS = REPO / "site" / "docs"
KNOW = REPO / "knowledge"

def slug(heading: str) -> str:
    s = heading.strip().lower()
    s = re.sub(r"[`*_]", "", s)
    s = re.sub(r"[^\w\s-]", "", s)
    return re.sub(r"\s", "-", s)

anchors: dict[str, set[str]] = {}
for f in DOCS.rglob("*.mdx"):
    rel = f.relative_to(DOCS).as_posix()
    anchors[rel] = {slug(m.group(1)) for m in re.finditer(r"^#{2,6}\s+(.+?)\s*$", f.read_text(), re.M)}

dbt_names = {p.stem for p in (REPO / "dbt").rglob("*.sql") if "dbt_packages" not in p.parts and "target" not in p.parts}
dbt_names |= {"snap_products", "snap_customers"}

errors = []
for f in sorted(KNOW.glob("*.md")):
    if f.name == "lab-catalog.md":
        continue
    text = f.read_text()
    for m in re.finditer(r"`((?:foundations|facts|dimensions|scd|advanced|bus|dbt|case-studies|practice|reference)/[\w./-]+\.mdx)(#[\w-]+)?`", text):
        path, anchor = m.group(1), m.group(2)
        if path not in anchors:
            errors.append(f"{f.name}: missing lesson {path}")
        elif anchor and anchor[1:] not in anchors[path]:
            errors.append(f"{f.name}: missing anchor {path}{anchor}")
    for m in re.finditer(r"`((?:fct|dim|bridge|agg|int|stg|scd|snap)_[a-z0-9_]+)`", text):
        if not m.group(1).endswith("_") and m.group(1) not in dbt_names:
            errors.append(f"{f.name}: unknown dbt object {m.group(1)}")
    for m in re.finditer(r"`((?:analyses|tests|models|macros|scripts)/[\w./-]+)`", text):
        if not (REPO / "dbt" / m.group(1)).exists():
            errors.append(f"{f.name}: missing file dbt/{m.group(1)}")

for e in sorted(set(errors)):
    print(e)
print(f"{len(set(errors))} broken references")
sys.exit(1 if errors else 0)
