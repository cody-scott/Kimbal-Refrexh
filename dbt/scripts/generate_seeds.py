"""
Deterministic seed-data generator for the Kimball Lab dbt project.

Cascade Outfitters is a fictional outdoor-gear retailer with physical stores,
a web channel, a distribution center, a general ledger and employees. Every
case study in the study site draws on the same company, so the dimensions
are conformed across business processes, as Kimball intends.

Run from the repo root:

    python dbt/scripts/generate_seeds.py

The output is written to dbt/seeds/. The random seed is fixed, so the files
are byte-for-byte reproducible.
"""

from __future__ import annotations

import csv
import random
from datetime import date, datetime, timedelta
from pathlib import Path

random.seed(42)

OUT = Path(__file__).resolve().parents[1] / "seeds"
OUT.mkdir(parents=True, exist_ok=True)

START = date(2025, 1, 1)
END = date(2025, 6, 30)


def daterange(start: date, end: date):
    d = start
    while d <= end:
        yield d
        d += timedelta(days=1)


def write(name: str, header: list[str], rows: list[list]):
    with open(OUT / f"{name}.csv", "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(header)
        w.writerows(rows)
    print(f"wrote {name}.csv ({len(rows)} rows)")


# ---------------------------------------------------------------------------
# Products: a three-level merchandise hierarchy (department > category >
# subcategory) plus attributes that change over time (to drive SCD lessons).
# ---------------------------------------------------------------------------
PRODUCTS = [
    # sku, name, brand, subcategory, category, department, package, price, cost
    ("SKU-1001", "Trailblazer 2P Tent", "Ridgeline", "Backpacking Tents", "Tents", "Camping", "Each", 349.00, 180.00),
    ("SKU-1002", "Basecamp 6P Tent", "Ridgeline", "Car Camping Tents", "Tents", "Camping", "Each", 499.00, 260.00),
    ("SKU-1003", "Ember 20F Sleeping Bag", "Northfork", "Down Bags", "Sleeping Bags", "Camping", "Each", 289.00, 140.00),
    ("SKU-1004", "Drift 40F Sleeping Bag", "Northfork", "Synthetic Bags", "Sleeping Bags", "Camping", "Each", 129.00, 60.00),
    ("SKU-1005", "Summit Stove", "Alpenglow", "Canister Stoves", "Camp Kitchen", "Camping", "Each", 79.00, 35.00),
    ("SKU-1006", "Fuel Canister 8oz", "Alpenglow", "Fuel", "Camp Kitchen", "Camping", "Each", 7.50, 3.00),
    ("SKU-2001", "Granite 65L Pack", "Switchback", "Backpacking Packs", "Packs", "Hiking", "Each", 279.00, 130.00),
    ("SKU-2002", "Daytripper 22L Pack", "Switchback", "Daypacks", "Packs", "Hiking", "Each", 99.00, 45.00),
    ("SKU-2003", "Ridge Runner Boot", "Talus", "Hiking Boots", "Footwear", "Hiking", "Pair", 189.00, 90.00),
    ("SKU-2004", "Wool Hiking Socks", "Talus", "Socks", "Footwear", "Hiking", "3-Pack", 24.00, 9.00),
    ("SKU-3001", "Stormshell Jacket", "Cirrus", "Rain Jackets", "Outerwear", "Apparel", "Each", 229.00, 105.00),
    ("SKU-3002", "Loft Puffy Jacket", "Cirrus", "Insulated Jackets", "Outerwear", "Apparel", "Each", 199.00, 92.00),
    ("SKU-3003", "Merino Base Layer", "Cirrus", "Base Layers", "Layers", "Apparel", "Each", 89.00, 38.00),
    ("SKU-3004", "Trail Cap", "Cirrus", "Headwear", "Accessories", "Apparel", "Each", 28.00, 10.00),
    ("SKU-4001", "Headlamp 400", "Lumen", "Headlamps", "Lighting", "Accessories", "Each", 45.00, 18.00),
    ("SKU-4002", "Water Filter", "Clearbrook", "Filters", "Hydration", "Accessories", "Each", 39.00, 15.00),
]

# A product change log: the source system records each attribute change.
# Used to build Type 2 history directly from a change feed (no snapshot needed).
product_changes = [
    # sku, changed_at, attribute, old_value, new_value
    ("SKU-1006", "2025-02-15 09:00:00", "category", "Camp Kitchen", "Fuel & Consumables"),
    ("SKU-2004", "2025-03-01 09:00:00", "category", "Footwear", "Socks & Accessories"),
    ("SKU-3004", "2025-03-01 09:00:00", "department", "Apparel", "Accessories"),
    ("SKU-1001", "2025-04-10 09:00:00", "brand", "Ridgeline", "Ridgeline Pro"),
    ("SKU-2003", "2025-05-01 09:00:00", "list_price", "189.00", "199.00"),
    ("SKU-1006", "2025-05-20 09:00:00", "package_size", "Each", "2-Pack"),
]
write("raw_product_changes", ["sku", "changed_at", "attribute_name", "old_value", "new_value"], product_changes)

# raw_products holds the CURRENT state of each product, as an OLTP table would:
# every change in the log has already been applied (and updated_at bumped).
COLS = ["sku", "product_name", "brand", "subcategory", "category", "department",
        "package_size", "list_price", "standard_cost", "updated_at"]
products_rows = []
for sku, name, brand, sub, cat, dept, pkg, price, cost in PRODUCTS:
    row = dict(zip(COLS, [sku, name, brand, sub, cat, dept, pkg, f"{price:.2f}", f"{cost:.2f}", "2024-12-01 00:00:00"]))
    for c_sku, changed_at, attr, _old, new in product_changes:
        if c_sku == sku:
            row[attr] = new
            row["updated_at"] = changed_at
    products_rows.append([row[c] for c in COLS])
write("raw_products", COLS, products_rows)

# ---------------------------------------------------------------------------
# Stores: a geographic hierarchy (store > district > region).
# ---------------------------------------------------------------------------
STORES = [
    (101, "Seattle Flagship", "Seattle", "WA", "Puget Sound", "Northwest", 42000, "2015-03-01", "Avery Chen"),
    (102, "Bellevue", "Bellevue", "WA", "Puget Sound", "Northwest", 28000, "2018-06-15", "Jordan Patel"),
    (103, "Portland Pearl", "Portland", "OR", "Willamette", "Northwest", 31000, "2016-09-01", "Riley Okafor"),
    (201, "Denver LoDo", "Denver", "CO", "Front Range", "Mountain", 35000, "2017-04-01", "Morgan Silva"),
    (202, "Boulder", "Boulder", "CO", "Front Range", "Mountain", 22000, "2019-10-01", "Casey Nguyen"),
    (999, "Web Store", "Online", "NA", "Digital", "Digital", 0, "2014-01-01", "Taylor Brooks"),
]
write(
    "raw_stores",
    ["store_id", "store_name", "city", "state", "district", "region",
     "square_footage", "opened_date", "manager_name"],
    [list(s) for s in STORES],
)

# ---------------------------------------------------------------------------
# Promotions (causal dimension). Includes a "no promotion" case handled in dbt.
# ---------------------------------------------------------------------------
PROMOS = [
    ("PRM-NEWYEAR", "New Year Gear Up", "Percent Off", "Email", "End Cap", "None", "2025-01-01", "2025-01-15"),
    ("PRM-WINTER", "Winter Clearance", "Percent Off", "Print", "Aisle", "None", "2025-02-01", "2025-02-28"),
    ("PRM-SPRING", "Spring Trail Days", "Dollar Off", "Social", "End Cap", "Mobile", "2025-04-01", "2025-04-20"),
    ("PRM-MEMBER", "Member Weekend", "Percent Off", "Email", "None", "Loyalty", "2025-05-23", "2025-05-26"),
    ("PRM-SUMMER", "Summer Camp Kickoff", "Bundle", "TV", "Floor Stack", "Paper", "2025-06-10", "2025-06-30"),
]
write(
    "raw_promotions",
    ["promo_code", "promo_name", "price_reduction_type", "ad_type",
     "display_type", "coupon_type", "start_date", "end_date"],
    [list(p) for p in PROMOS],
)


def promo_for(d: date) -> str | None:
    for code, *_rest, s, e in PROMOS:
        if date.fromisoformat(s) <= d <= date.fromisoformat(e):
            return code
    return None


# Promotion coverage: which products were on promotion in which stores, by day
# (the classic factless "coverage" table). Not every promoted product sells.
coverage = []
for code, _n, _r, _a, _d, _c, s, e in PROMOS:
    promo_skus = random.sample([p[0] for p in PRODUCTS], 5)
    promo_stores = [st[0] for st in STORES if st[0] != 999]
    for d in daterange(date.fromisoformat(s), date.fromisoformat(e)):
        for st in promo_stores:
            for sku in promo_skus:
                coverage.append([d.isoformat(), st, sku, code])
write("raw_promotion_coverage", ["coverage_date", "store_id", "sku", "promo_code"], coverage)

# ---------------------------------------------------------------------------
# Customers + a change log for SCD lessons (address moves, loyalty tier).
# ---------------------------------------------------------------------------
FIRST = ["Alex", "Sam", "Jamie", "Drew", "Quinn", "Reese", "Skyler", "Parker",
         "Rowan", "Emerson", "Hayden", "Logan", "Kendall", "Peyton", "Blake",
         "Cameron", "Dakota", "Finley", "Harper", "Jesse"]
LAST = ["Garcia", "Kim", "Johnson", "Haddad", "Mbeki", "Larsen", "Ito", "Novak",
        "Rossi", "Singh", "Walsh", "Dubois", "Moreno", "Fischer", "Clarke",
        "Romero", "Tanaka", "Olsen", "Byrne", "Costa"]
CITIES = [("Seattle", "WA"), ("Tacoma", "WA"), ("Portland", "OR"), ("Eugene", "OR"),
          ("Denver", "CO"), ("Boulder", "CO"), ("Salt Lake City", "UT"), ("Boise", "ID")]
TIERS = ["Basic", "Silver", "Gold"]

customers = []
for i in range(1, 61):
    city, state = random.choice(CITIES)
    bd = date(1960, 1, 1) + timedelta(days=random.randint(0, 365 * 40))
    customers.append([
        f"C{i:04d}", FIRST[i % 20], LAST[(i * 7) % 20],
        f"customer{i:04d}@example.com", bd.isoformat(), city, state,
        random.choice(TIERS[:2]), random.choice([25, 45, 65, 85, 120]) * 1000,
        "2024-12-01 00:00:00",
    ])

cust_changes = []
for c in random.sample(customers, 18):
    when = datetime(2025, 1, 1) + timedelta(days=random.randint(10, 170), hours=10)
    if random.random() < 0.5:
        city, state = random.choice([x for x in CITIES if x[0] != c[5]])
        cust_changes.append([c[0], when.isoformat(sep=" "), "city", c[5], city])
        cust_changes.append([c[0], when.isoformat(sep=" "), "state", c[6], state])
    else:
        new_tier = "Gold" if c[7] == "Silver" else "Silver"
        cust_changes.append([c[0], when.isoformat(sep=" "), "loyalty_tier", c[7], new_tier])
cust_changes.sort(key=lambda r: (r[0], r[1]))
write("raw_customer_changes", ["customer_id", "changed_at", "attribute_name", "old_value", "new_value"], cust_changes)

# Apply the change log so raw_customers shows CURRENT values (as an OLTP table would).
current_customers = [list(c) for c in customers]
by_id = {c[0]: c for c in current_customers}
col_idx = {"city": 5, "state": 6, "loyalty_tier": 7}
for cid, changed_at, attr, _old, new in cust_changes:
    by_id[cid][col_idx[attr]] = new
    by_id[cid][9] = changed_at
write(
    "raw_customers",
    ["customer_id", "first_name", "last_name", "email", "birth_date", "city",
     "state", "loyalty_tier", "annual_income", "updated_at"],
    current_customers,
)

# Multivalued customer interests (bridge-table lesson).
INTERESTS = ["Backpacking", "Climbing", "Trail Running", "Camping", "Paddling", "Skiing"]
cust_interests = []
for c in customers:
    for interest in random.sample(INTERESTS, random.randint(0, 3)):
        cust_interests.append([c[0], interest])
write("raw_customer_interests", ["customer_id", "interest"], cust_interests)

# ---------------------------------------------------------------------------
# Employees with a recursive manager relationship (hierarchy bridge lesson).
# ---------------------------------------------------------------------------
EMPLOYEES = [
    # id, name, title, manager_id, department, hire_date, store_id
    ("E001", "Taylor Brooks", "CEO", "", "Executive", "2014-01-01", ""),
    ("E002", "Morgan Silva", "VP Retail", "E001", "Retail Ops", "2015-02-01", ""),
    ("E003", "Jordan Patel", "VP Digital", "E001", "Digital", "2016-03-01", ""),
    ("E004", "Avery Chen", "Regional Director NW", "E002", "Retail Ops", "2015-03-01", ""),
    ("E005", "Casey Nguyen", "Regional Director Mountain", "E002", "Retail Ops", "2017-04-01", ""),
    ("E006", "Riley Okafor", "Store Manager", "E004", "Retail Ops", "2016-09-01", "103"),
    ("E007", "Skyler Ito", "Store Manager", "E004", "Retail Ops", "2018-06-15", "102"),
    ("E008", "Parker Novak", "Store Manager", "E005", "Retail Ops", "2019-10-01", "202"),
    ("E009", "Rowan Rossi", "Sales Associate", "E006", "Retail Ops", "2021-05-01", "103"),
    ("E010", "Emerson Singh", "Sales Associate", "E006", "Retail Ops", "2022-07-11", "103"),
    ("E011", "Hayden Walsh", "Sales Associate", "E007", "Retail Ops", "2023-01-09", "102"),
    ("E012", "Logan Dubois", "Sales Associate", "E008", "Retail Ops", "2023-03-20", "202"),
    ("E013", "Kendall Moreno", "Ecommerce Manager", "E003", "Digital", "2020-02-03", "999"),
    ("E014", "Peyton Fischer", "Analyst", "E013", "Digital", "2024-08-19", "999"),
]
write(
    "raw_employees",
    ["employee_id", "employee_name", "job_title", "manager_employee_id",
     "department", "hire_date", "home_store_id"],
    [list(e) for e in EMPLOYEES],
)

# ---------------------------------------------------------------------------
# POS transactions (retail sales: grain = one line on one POS ticket).
# ---------------------------------------------------------------------------
pos = []
txn_id = 500000
retail_stores = [s[0] for s in STORES if s[0] != 999]
for d in daterange(START, END):
    weekend = d.weekday() >= 5
    for store in retail_stores:
        n_txn = random.randint(3, 6) + (3 if weekend else 0)
        for _ in range(n_txn):
            txn_id += 1
            ts = datetime(d.year, d.month, d.day, random.randint(9, 20), random.randint(0, 59))
            cust = random.choice(customers)[0] if random.random() < 0.6 else ""
            cashier = random.choice(["E009", "E010", "E011", "E012", "E006", "E007", "E008"])
            promo = promo_for(d)
            for line in range(1, random.randint(1, 4) + 1):
                p = random.choice(PRODUCTS)
                qty = random.choice([1, 1, 1, 2, 3]) if p[0] not in ("SKU-1006", "SKU-2004") else random.randint(1, 6)
                disc = round(p[7] * qty * 0.15, 2) if promo and random.random() < 0.5 else 0.0
                pos.append([
                    txn_id, line, store, f"R{random.randint(1, 4)}", cashier, cust,
                    p[0], promo if disc else "", qty, f"{p[7]:.2f}", f"{disc:.2f}",
                    f"{p[8]:.2f}", ts.isoformat(sep=" "),
                ])
write(
    "raw_pos_transactions",
    ["transaction_id", "line_number", "store_id", "register_id", "cashier_employee_id",
     "customer_id", "sku", "promo_code", "quantity", "unit_price", "discount_amount",
     "unit_cost", "transaction_ts"],
    pos,
)

# ---------------------------------------------------------------------------
# Inventory: daily on-hand snapshot by store x product, plus the movements
# (receipts, sales, adjustments) that explain the changes.
# ---------------------------------------------------------------------------
on_hand = {(s, p[0]): random.randint(20, 60) for s in retail_stores for p in PRODUCTS}
sales_by_day = {}
for r in pos:
    key = (r[12][:10], r[2], r[6])
    sales_by_day[key] = sales_by_day.get(key, 0) + r[8]

inv_snap, inv_moves = [], []
move_id = 1
for d in daterange(START, END):
    for s in retail_stores:
        for p in PRODUCTS:
            k = (s, p[0])
            sold = sales_by_day.get((d.isoformat(), s, p[0]), 0)
            if sold:
                inv_moves.append([move_id, d.isoformat(), s, p[0], "SALE", -sold, f"{p[8]:.2f}"])
                move_id += 1
            on_hand[k] -= sold
            if on_hand[k] < 10:
                recv = random.randint(30, 50)
                inv_moves.append([move_id, d.isoformat(), s, p[0], "RECEIPT", recv, f"{p[8]:.2f}"])
                move_id += 1
                on_hand[k] += recv
            if random.random() < 0.003:
                inv_moves.append([move_id, d.isoformat(), s, p[0], "SHRINK", -1, f"{p[8]:.2f}"])
                move_id += 1
                on_hand[k] -= 1
            inv_snap.append([d.isoformat(), s, p[0], on_hand[k], f"{p[8]:.2f}", f"{p[7]:.2f}"])
write("raw_inventory_daily", ["snapshot_date", "store_id", "sku", "quantity_on_hand", "unit_cost", "unit_list_price"], inv_snap)
write("raw_inventory_movements", ["movement_id", "movement_date", "store_id", "sku", "movement_type", "quantity", "unit_cost"], inv_moves)

# ---------------------------------------------------------------------------
# Procurement: purchase orders to vendors, multiple transaction types.
# ---------------------------------------------------------------------------
VENDORS = [("V01", "Ridgeline Mfg", "US"), ("V02", "Northfork Down Co", "CA"),
           ("V03", "Switchback Packs", "US"), ("V04", "Cirrus Apparel", "CA"),
           ("V05", "Talus Footwear", "IT")]
BRAND_VENDOR = {"Ridgeline": "V01", "Northfork": "V02", "Alpenglow": "V01",
                "Switchback": "V03", "Talus": "V05", "Cirrus": "V04",
                "Lumen": "V03", "Clearbrook": "V03"}
write("raw_vendors", ["vendor_id", "vendor_name", "country"], [list(v) for v in VENDORS])

proc = []
po = 9000
for d in daterange(START, END):
    if d.weekday() != 0:  # POs go out on Mondays
        continue
    for vend in VENDORS:
        po += 1
        lines = [p for p in PRODUCTS if BRAND_VENDOR[p[2]] == vend[0]]
        for ln, p in enumerate(random.sample(lines, min(len(lines), random.randint(1, 3))), start=1):
            qty = random.randint(20, 80)
            proc.append([f"PO{po}", ln, vend[0], p[0], d.isoformat(), "PO_ISSUED", qty, f"{p[8]:.2f}"])
            recv_d = d + timedelta(days=random.randint(5, 20))
            if recv_d <= END:
                proc.append([f"PO{po}", ln, vend[0], p[0], recv_d.isoformat(), "RECEIVED", qty, f"{p[8]:.2f}"])
                inv_d = recv_d + timedelta(days=random.randint(1, 10))
                if inv_d <= END:
                    proc.append([f"PO{po}", ln, vend[0], p[0], inv_d.isoformat(), "INVOICED", qty, f"{p[8]:.2f}"])
                    pay_d = inv_d + timedelta(days=random.choice([15, 30, 45]))
                    if pay_d <= END:
                        proc.append([f"PO{po}", ln, vend[0], p[0], pay_d.isoformat(), "PAID", qty, f"{p[8]:.2f}"])
write(
    "raw_procurement_transactions",
    ["po_number", "po_line_number", "vendor_id", "sku", "transaction_date",
     "transaction_type", "quantity", "unit_cost"],
    proc,
)

# ---------------------------------------------------------------------------
# Web orders: header + lines, multiple dates (order, ship, deliver, return),
# order-level flags (junk dimension), header shipping charge (allocation lesson),
# and multiple currencies.
# ---------------------------------------------------------------------------
CURRENCIES = {"USD": 1.0, "CAD": 0.73, "EUR": 1.08}
fx = []
for d in daterange(START, END):
    for cur, base in CURRENCIES.items():
        rate = base if cur == "USD" else round(base * (1 + random.uniform(-0.02, 0.02)), 4)
        fx.append([d.isoformat(), cur, "USD", rate])
write("raw_fx_rates", ["rate_date", "from_currency", "to_currency", "exchange_rate"], fx)

orders, order_lines = [], []
order_no = 70000
for d in daterange(START, END):
    for _ in range(random.randint(2, 5)):
        order_no += 1
        cust = random.choice(customers)[0]
        cur = random.choices(["USD", "CAD", "EUR"], weights=[8, 2, 1])[0]
        rate = 1.0 if cur == "USD" else CURRENCIES[cur]
        payment = random.choice(["Credit Card", "PayPal", "Gift Card"])
        ship_method = random.choice(["Ground", "Ground", "2-Day", "Overnight"])
        gift = random.random() < 0.1
        ts = datetime(d.year, d.month, d.day, random.randint(0, 23), random.randint(0, 59))
        ship_d = d + timedelta(days=random.randint(0, 3))
        deliv_d = ship_d + timedelta(days={"Ground": 5, "2-Day": 2, "Overnight": 1}[ship_method])
        ship_ts = ship_d.isoformat() if ship_d <= END else ""
        deliv_ts = deliv_d.isoformat() if deliv_d <= END and ship_ts else ""
        ret_ts = ""
        if deliv_ts and random.random() < 0.08:
            r = deliv_d + timedelta(days=random.randint(3, 20))
            ret_ts = r.isoformat() if r <= END else ""
        status = "RETURNED" if ret_ts else "DELIVERED" if deliv_ts else "SHIPPED" if ship_ts else "PLACED"
        shipping_charge = {"Ground": 0.0, "2-Day": 15.0, "Overnight": 35.0}[ship_method] / rate
        orders.append([order_no, cust, ts.isoformat(sep=" "), cur, payment, ship_method,
                       "Y" if gift else "N", f"{shipping_charge:.2f}", ship_ts, deliv_ts, ret_ts, status])
        for ln in range(1, random.randint(1, 3) + 1):
            p = random.choice(PRODUCTS)
            qty = random.choice([1, 1, 2])
            price_local = round(p[7] / rate, 2)
            disc = round(price_local * qty * 0.1, 2) if promo_for(d) else 0.0
            order_lines.append([order_no, ln, p[0], qty, f"{price_local:.2f}", f"{disc:.2f}", f"{p[8]:.2f}"])
write(
    "raw_web_orders",
    ["order_number", "customer_id", "order_ts", "currency_code", "payment_method",
     "ship_method", "is_gift", "shipping_charge", "shipped_date", "delivered_date",
     "returned_date", "order_status"],
    orders,
)
write(
    "raw_web_order_lines",
    ["order_number", "line_number", "sku", "quantity", "unit_price_local",
     "discount_local", "unit_cost_usd"],
    order_lines,
)

# ---------------------------------------------------------------------------
# General ledger: chart of accounts with a ragged parent/child hierarchy, and
# journal lines. Budget figures by month for the budget-vs-actual lesson.
# ---------------------------------------------------------------------------
ACCOUNTS = [
    # account_id, name, parent, type
    ("1000", "Assets", "", "Asset"),
    ("1100", "Cash", "1000", "Asset"),
    ("1200", "Inventory", "1000", "Asset"),
    ("2000", "Liabilities", "", "Liability"),
    ("2100", "Accounts Payable", "2000", "Liability"),
    ("4000", "Revenue", "", "Revenue"),
    ("4100", "Store Revenue", "4000", "Revenue"),
    ("4110", "Store Merchandise Revenue", "4100", "Revenue"),
    ("4120", "Store Services Revenue", "4100", "Revenue"),
    ("4200", "Web Revenue", "4000", "Revenue"),
    ("5000", "Expenses", "", "Expense"),
    ("5100", "Cost of Goods Sold", "5000", "Expense"),
    ("5200", "Operating Expenses", "5000", "Expense"),
    ("5210", "Payroll", "5200", "Expense"),
    ("5220", "Rent", "5200", "Expense"),
    ("5221", "Store Rent", "5220", "Expense"),
    ("5222", "DC Rent", "5220", "Expense"),
    ("5230", "Marketing", "5200", "Expense"),
]
write("raw_gl_accounts", ["account_id", "account_name", "parent_account_id", "account_type"], [list(a) for a in ACCOUNTS])

LEAF = ["1100", "1200", "2100", "4110", "4120", "4200", "5100", "5210", "5221", "5222", "5230"]
gl = []
je = 1
for d in daterange(START, END):
    if d.day not in (1, 15) and d.weekday() != 4:
        continue
    for acct in random.sample(LEAF, 5):
        amt = round(random.uniform(500, 25000), 2)
        side = "D" if acct[0] in "15" else "C"
        gl.append([f"JE{je:05d}", d.isoformat(), acct, random.choice(retail_stores + [999]), side, f"{amt:.2f}"])
        je += 1
write("raw_gl_journal_lines", ["journal_entry_id", "posting_date", "account_id", "store_id", "debit_credit", "amount"], gl)

budget = []
for m in range(1, 7):
    for acct in ["4110", "4120", "4200", "5100", "5210", "5221", "5230"]:
        budget.append([f"2025-{m:02d}-01", acct, f"{random.uniform(20000, 90000):.2f}"])
write("raw_gl_budget", ["budget_month", "account_id", "budget_amount"], budget)

# ---------------------------------------------------------------------------
# Employee profile changes (HR transaction-tracking lesson).
# ---------------------------------------------------------------------------
hr_events = []
for e in EMPLOYEES:
    hr_events.append([e[0], e[5], "HIRE", e[2], e[6], 0])
hr_events += [
    ["E011", "2025-03-01", "PROMOTION", "Senior Sales Associate", "102", 0],
    ["E010", "2025-04-15", "TRANSFER", "Sales Associate", "101", 0],
    ["E012", "2025-05-31", "TERMINATION", "Sales Associate", "202", 1],
    ["E015", "2025-02-03", "HIRE", "Sales Associate", "201", 0],
    ["E016", "2025-05-12", "HIRE", "Sales Associate", "101", 0],
]
write("raw_employee_events", ["employee_id", "event_date", "event_type", "job_title", "store_id", "is_termination"], hr_events)

print("done")
