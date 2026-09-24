#!/usr/bin/env python3
"""gate_descriptions.py — THE ONE READER of a gate's human-readable description
(GitHub #171 slice Q0, ruled 2026-09-24: "I want for each test a human-readable
description of the test (at least what it tests, how it tests and what is the
expected result)").

  python3 tools/gate_descriptions.py                 # census: declares / undeclared, one line per gate
  python3 tools/gate_descriptions.py --root DIR      # over a copy of the tree (the gate's controls)
  python3 tools/gate_descriptions.py --show tests/x.sh   # the three fields of one gate, as parsed

THE GRAMMAR — three fields in the gate's LEADING COMMENT BLOCK (every `#` line after
the shebang up to the first non-comment line; a bare `#` continues the block, as the
must-fire contract reads it), each starting at column 0, spelled exactly, in this
order, once each:

    # WHAT: <what the gate tests — the property, in the game's or the tree's terms>
    # HOW: <how it tests it — the legs, the instrument, the rig, the compare>
    # EXPECTS: <the expected result, and what a red means>

A field CONTINUES on the following lines while each is `#` followed by at least two
spaces (`#   ...`); it ENDS at the next `# WORD:` field, a bare `#`, or a `#` line
with a single space. A gate is DECLARES when all three fields are present, in order,
non-empty; anything else is UNDECLARED with the reason (a missing field, an empty
one, out of order, a duplicate, or a field outside the leading block).

WHY ONE READER: `tools/gen_gate_index.py` renders the fields per family into the
GENERATED gate index (the maintainer's functional-coverage view) and
`tests/test_gate_descriptions.sh` freezes the census (declares grows only). Two
parsers would drift; both import this file. Board-, game- and project-agnostic
(the must-fire contract's shape, BBX R10 by analogy).
"""
import argparse, os, re, sys

FIELDS = ("WHAT", "HOW", "EXPECTS")
FIELD_RE = re.compile(r"^# ([A-Z][A-Z-]+):(.*)$")
CONT_RE = re.compile(r"^#  +(\S.*)$")


def leading_block(text):
    """The leading comment block's lines (without the shebang)."""
    lines = text.splitlines()
    out = []
    for l in lines[1:] if lines and lines[0].startswith("#!") else lines:
        if not l.startswith("#"):
            break
        out.append(l)
    return out


def parse(text):
    """-> (fields: {WHAT, HOW, EXPECTS} -> str, problems: [str]) for one gate's text."""
    fields, order, problems = {}, [], []
    cur = None
    for l in leading_block(text):
        m = FIELD_RE.match(l)
        if m:
            name, rest = m.group(1), m.group(2).strip()
            if name in FIELDS:
                if name in fields:
                    problems.append(f"duplicate {name}")
                fields[name] = rest
                order.append(name)
                cur = name
            else:
                cur = None
            continue
        if cur is not None:
            c = CONT_RE.match(l)
            if c:
                fields[cur] = (fields[cur] + " " + c.group(1).strip()).strip()
                continue
            cur = None  # a bare `#`, a single-space `#` line, or anything else ends the field
    for f in FIELDS:
        if f not in fields:
            problems.append(f"missing {f}")
        elif not fields[f]:
            problems.append(f"empty {f}")
    present = [f for f in order if f in FIELDS]
    if not problems and present != list(FIELDS):
        problems.append("out of order: " + " ".join(present))
    return fields, problems


def census(root):
    """-> sorted [(class, gate, reason)] over tests/*.sh under root."""
    rows = []
    tdir = os.path.join(root, "tests")
    for name in sorted(os.listdir(tdir)):
        if not name.endswith(".sh"):
            continue
        p = os.path.join(tdir, name)
        with open(p, encoding="utf-8", errors="replace") as f:
            fields, problems = parse(f.read())
        gate = name[:-3]
        if problems:
            rows.append(("undeclared", gate, "; ".join(problems)))
        else:
            rows.append(("declares", gate, ""))
    return rows


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    ap.add_argument("--show", help="print the parsed fields of one gate")
    a = ap.parse_args()
    if a.show:
        with open(a.show, encoding="utf-8", errors="replace") as f:
            fields, problems = parse(f.read())
        for k in FIELDS:
            print(f"{k}: {fields.get(k, '')}")
        print("PROBLEMS: " + ("; ".join(problems) if problems else "none"))
        return 0 if not problems else 1
    rows = census(a.root)
    for cls, gate, why in rows:
        print(f"{cls}\t{gate}" + (f"\t{why}" if why else ""))
    nd = sum(1 for r in rows if r[0] == "declares")
    print(f"# {nd} declares, {len(rows) - nd} undeclared, {len(rows)} gates", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
