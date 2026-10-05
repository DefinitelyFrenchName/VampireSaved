#!/usr/bin/env python3
"""audit_charid_names.py — EVERY IN-TREE CHARACTER-ID -> NAME MAP AGREES WITH THE ATLAS (GitHub #218, 14z-191).

    python3 tools/audit_charid_names.py [--floor N]      # the census over tools/ and tests/ (exit 1 on a red)
    python3 tools/audit_charid_names.py --plant [--floor N]   # the census plus a planted SHIFTED map (must be red)

WHY. `tools/audit_poked_legs.py`'s NAMES map carried 0x0A-0x0E shifted by one row against the atlas
(Q-Bee at 0x0A, Lilith at 0x0D, Sasquatch at 0x0E — #218, found 14z-189 by the retraction grep for the
"0x0D = Lilith" correction). A label map is not a measurement: nothing reads it back, so a wrong row
survives until a human compares it with the table. This census is that comparison, made for every map.

THE REFERENCE is the slot table in `docs/game/atlas/character_tables.md` ("Slot→character map, vsavj"), every
entry pinned there by a scripted pick (select-screen name + the in-match pointer readback). Each row gives the
accepted names: the words before a parenthesis and the alias inside it (`Lei-Lei (Hsien-Ko)`), compared
case- and punctuation-blind. Slot 0x0B (the random cell) is not a character and is not judged; ids outside
the table (0x10+, the tenants and the hidden variants) are not judged either.

WHAT IS A MAP. Every dict literal, by AST (never by importing), in a tracked `.py` under tools/ or tests/,
whose entries are `<int>: "<name>"` or `<key>: (<int>, "<name>", ...)` and where at least four names are
characters of the table (whatever id they sit at) — so a dict of chain ids or move names is not a map. Each
pair of such a map whose id is in the table is JUDGED: its name must be one of that row's accepted names. A
name that is no character of the table ("random", "?") is not judged.

WHAT IT DOES NOT CLAIM: maps written outside Python (shell `case` arms, Lua tables, prose in documents) are not
read; nor whether the atlas itself is right — that is the scripted picks' claim, not this tool's.
ROM-free, emulator-free, under a second. Gate: tests/test_charid_names.sh.
"""
import argparse
import ast
import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
ATLAS = "docs/game/atlas/character_tables.md"
HEADING = "## Slot→character map, vsavj"
NOT_JUDGED = {0x0B}
SHOWN = {}                                         # id -> the row's leading name, for messages

# the planted control: the #218 shape itself, the five rows 0x0A-0x0E as audit_poked_legs.py had them
PLANT = '''NAMES = {0x00: "Bulleta", 0x01: "Demitri", 0x02: "Gallon", 0x03: "Victor", 0x04: "Zabel",
         0x09: "Aulbath", 0x0A: "Q-Bee", 0x0B: "random", 0x0C: "Lei-Lei", 0x0D: "Lilith", 0x0E: "Sasquatch"}
'''


def norm(s):
    return re.sub(r"[^a-z0-9]", "", s.lower())


def atlas_table(root):
    """{id: set(normalised accepted names)} from the atlas slot table; refuses a table it cannot read."""
    text = (root / ATLAS).read_text(encoding="utf-8")
    if HEADING not in text:
        sys.exit(f"REFUSED: {ATLAS} has no heading '{HEADING}'")
    body = text.split(HEADING, 1)[1].split("\n## ", 1)[0]
    table = {}
    for line in body.splitlines():
        if not line.startswith("| 0x"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        for i in range(0, len(cells) - 1):
            m = re.fullmatch(r"0x([0-9A-Fa-f]{2})", cells[i])
            if not m:
                continue
            cid = int(m.group(1), 16)
            if cid in NOT_JUDGED:
                continue
            cell = cells[i + 1]
            names = set()
            head = cell.split("(", 1)[0].strip()
            if head:
                names.add(norm(head))
                SHOWN[cid] = head
            for alias in re.findall(r"\(([^)]*)\)", cell):
                first = alias.split("=")[0].strip()      # "0x18 = Oboro Bishamon" is not an alias of 0x08
                if first and not first.startswith("0x"):
                    names.add(norm(first))
            table[cid] = names
    want = set(range(0x10)) - NOT_JUDGED
    if set(table) != want:
        sys.exit(f"REFUSED: the atlas table read {len(table)} ids, expected {len(want)} "
                 f"(missing {sorted(want - set(table))})")
    return table


def pairs_of(node):
    """the (id, name) pairs of a dict literal of either shape, or None when it is neither."""
    out = []
    for k, v in zip(node.keys, node.values):
        if isinstance(k, ast.Constant) and isinstance(k.value, int) and not isinstance(k.value, bool) \
                and isinstance(v, ast.Constant) and isinstance(v.value, str):
            out.append((k.value, v.value))
        elif isinstance(v, ast.Tuple) and len(v.elts) >= 2 and isinstance(v.elts[0], ast.Constant) \
                and isinstance(v.elts[0].value, int) and not isinstance(v.elts[0].value, bool) \
                and isinstance(v.elts[1], ast.Constant) and isinstance(v.elts[1].value, str):
            out.append((v.elts[0].value, v.elts[1].value))
    return out or None


def census(sources, table):
    """sources: [(label, text)]. Returns (maps, bad): maps = [(label, line, judged)], bad = [str]."""
    every = {n: cid for cid, ns in table.items() for n in ns}
    maps, bad = [], []
    for label, text in sources:
        try:
            tree = ast.parse(text)
        except SyntaxError:
            continue
        for node in ast.walk(tree):
            if not isinstance(node, ast.Dict):
                continue
            prs = pairs_of(node)
            if not prs or sum(1 for _, n in prs if norm(n) in every) < 4:
                continue
            judged = 0
            for cid, name in prs:
                if cid not in table or norm(name) not in every:
                    continue
                judged += 1
                if norm(name) not in table[cid]:
                    bad.append(f"{label}:{node.lineno}: id 0x{cid:02X} named '{name}', the atlas says "
                               f"'{SHOWN.get(cid, sorted(table[cid])[0])}' ('{name}' is 0x{every[norm(name)]:02X})")
            maps.append((label, node.lineno, judged))
    return maps, bad


def tracked_sources(root):
    files = subprocess.run(["git", "-C", str(root), "ls-files", "tools", "tests"], capture_output=True,
                           text=True, check=True).stdout.split()
    return [(f, (root / f).read_text(encoding="utf-8", errors="replace"))
            for f in files if f.endswith(".py") and (root / f).is_file()]


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--floor", type=int, default=1, help="the fewest maps the census must find")
    ap.add_argument("--plant", action="store_true", help="add the planted shifted map (must be red)")
    a = ap.parse_args()
    table = atlas_table(REPO)
    sources = tracked_sources(REPO)
    if a.plant:
        sources.append(("<plant: the #218 shift>", PLANT))
    maps, bad = census(sources, table)
    print(f"atlas: {len(table)} ids judged ({ATLAS}); {len(sources)} Python files; "
          f"{len(maps)} character maps, {sum(j for *_, j in maps)} pairs judged")
    for label, line, judged in maps:
        print(f"  map {label}:{line}  ({judged} pairs judged)")
    for b in bad:
        print(f"MISMATCH {b}")
    planted = [b for b in bad if b.startswith("<plant")]
    if a.plant and planted:
        print(f"CONTROL FIRED: shifted-map — the planted #218 shift was reported ({len(planted)} rows)")
    elif a.plant:
        print("CONTROL DEAD: shifted-map — the planted shift passed the census")
    if len(maps) < a.floor:
        print(f"FAIL: {len(maps)} maps found, below the floor {a.floor} — the census stopped seeing maps")
        return 1
    if bad:
        print(f"FAIL: {len(bad)} id->name pairs disagree with the atlas")
        return 1
    print("PASS: every id->name pair agrees with the atlas")
    return 0


if __name__ == "__main__":
    sys.exit(main())
