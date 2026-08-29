#!/usr/bin/env python3
"""checkdocs.py — lock the load-bearing numbers the docs share, across documents.

  python3 tools/checkdocs.py              # check the tree, then self-test
  python3 tools/checkdocs.py -v           # ...and print every lock as it passes
  python3 tools/checkdocs.py --root DIR   # check a copy of the tree (the gate's
                                          # must-fire controls use this)
  python3 tools/checkdocs.py --locks F    # another lock table (default docs/doc_locks.tsv)

WHY THIS EXISTS (14z-118, the documentation audit). `tools/checkskills.py`
locks each SKILL to the docs it distils and requires every number a skill
quotes to be PRESENT in a log. It does not say whether two DOCS agree with
each other: the 14z-117 specimen was a page drawn from the atlas that
contradicted the atlas one hop away, and the survey behind
`docs/project/doc_audit_14z118.md` found the same address quoted in up to
five documents with nothing holding them together. This tool holds them.

THE LOCK TABLE (`docs/doc_locks.tsv`, tab-separated, `#` comments):

  label   canonical   key   files   also

  label      a short name for the fact ("obj_bank_table")
  canonical  the value every listed file must quote VERBATIM ("PRG:0x282D4"
             — the namespace is part of the value, CLAUDE.md §5 notation)
  key        a case-insensitive regex naming the fact in prose ("OBJ bank
             table"); used by check 2 below
  files      comma-separated repo-relative paths that must all quote it
  also       comma-separated values that may legitimately sit beside the key
             (a sibling romset's twin address, a paired second table); may
             be empty

TWO CHECKS, per row:
  1. PRESENCE — every file in `files` contains `canonical` verbatim. A doc
     that stops quoting the number (rewritten, retracted, renamed) fails
     loudly instead of drifting silently.
  2. NO RIVAL — in every listed file, on every line matching `key`, each
     token of the canonical's SHAPE that appears within WINDOW characters
     after the key match must be `canonical` or one of `also`. This is the
     "same label, different number" test: a page that says "the OBJ bank
     table `PRG:0x282D8`" fails. The window is deliberately short so that
     unrelated addresses later in a long sentence are not read as rivals;
     a key that matches noisy prose is tightened in the TSV, never widened
     here.

Shapes recognised: `PRG:0x…` / `CPU:$…` / `RAM:$…` / bare `0x…` hex, bare
`$FF…` RAM, comma-grouped or plain integers, hex hashes of 8+ characters.
Matching of the canonical itself is case-sensitive (the docs write hex in
upper case by convention); rival extraction is case-insensitive so a
lower-case rival is still a rival.

The extractors are negative-controlled on synthetic content every run
(`selftests`): a lock that has stopped matching passes every claim it no
longer finds, so the self-test asserts each failure mode still fires.
ROM-free, emulator-free, ~0.1 s (ci_portable, `tests/test_checkdocs.sh`).
"""
import argparse
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
WINDOW = 80

_SHAPES = [
    ("prg", re.compile(r"PRG:0x[0-9A-Fa-f]+", re.IGNORECASE)),
    ("cpu", re.compile(r"CPU:\$[0-9A-Fa-f]+", re.IGNORECASE)),
    ("ram", re.compile(r"RAM:\$[0-9A-Fa-f]+", re.IGNORECASE)),
    ("hexhash", re.compile(r"(?<![0-9A-Za-z])[0-9a-f]{8,}(?![0-9A-Za-z])")),
    ("hex", re.compile(r"(?<![A-Za-z:])0x[0-9A-Fa-f]+")),
    ("dollar", re.compile(r"(?<![A-Za-z:])\$[0-9A-Fa-f]{4,}")),
    ("int", re.compile(r"(?<![0-9A-Za-z.$x])[0-9]{1,3}(?:,[0-9]{3})+|(?<![0-9A-Za-z.$x])[0-9]{4,}(?![0-9A-Za-z,])")),
]


def shape_of(value):
    """Which extractor recognises this canonical value, whole."""
    for name, rx in _SHAPES:
        m = rx.fullmatch(value)
        if m:
            return name, rx
    return None, None


def norm(tok):
    return tok.lower()


def read_locks(path):
    rows = []
    for ln, line in enumerate(path.read_text().splitlines(), 1):
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        cols = line.split("\t")
        if len(cols) < 4:
            raise SystemExit(f"{path}:{ln}: expected 4-5 tab-separated columns, got {len(cols)}")
        label, canonical, key, files = (c.strip() for c in cols[:4])
        also = [a.strip() for a in cols[4].split(",")] if len(cols) > 4 and cols[4].strip() else []
        rows.append(dict(label=label, canonical=canonical, key=key,
                         files=[f.strip() for f in files.split(",") if f.strip()],
                         also=also, line=ln))
    return rows


def check_row(root, row):
    """Return a list of failure strings for one lock row (empty = pass)."""
    fails = []
    canon = row["canonical"]
    sname, rx = shape_of(canon)
    if sname is None:
        return [f"{row['label']}: canonical {canon!r} matches no known shape"]
    allowed = {norm(canon)} | {norm(a) for a in row["also"]}
    key = re.compile(row["key"], re.IGNORECASE)
    for rel in row["files"]:
        p = root / rel
        if not p.is_file():
            fails.append(f"{row['label']}: file MISSING: {rel}")
            continue
        text = p.read_text(errors="replace")
        if canon not in text:
            fails.append(f"{row['label']}: {rel} does not quote {canon} (PRESENCE)")
        for n, line in enumerate(text.splitlines(), 1):
            for km in key.finditer(line):
                window = line[km.end(): km.end() + WINDOW]
                for tm in rx.finditer(window):
                    tok = tm.group(0)
                    if norm(tok) not in allowed:
                        fails.append(f"{row['label']}: {rel}:{n} RIVAL {tok} beside "
                                     f"'{km.group(0)}' (canonical {canon})")
    return fails


def check(root, locks, verbose=False):
    rows = read_locks(locks)
    if not rows:
        print(f"FAIL: {locks} holds no locks")
        return False
    fails = []
    for row in rows:
        f = check_row(root, row)
        if f:
            fails.extend(f)
        elif verbose:
            print(f"  ok  {row['label']:<28} {row['canonical']:<18} in {len(row['files'])} files")
    for f in fails:
        print("FAIL:", f)
    print(f"{len(rows)} locks, {sum(len(r['files']) for r in rows)} file-sites, "
          f"{len(fails)} failures")
    return not fails


def selftests():
    """Every failure mode must fire on synthetic content (RH-9)."""
    import tempfile
    ok = True

    def run(label, files, tsv, expect):
        nonlocal ok
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            for rel, body in files.items():
                (root / rel).parent.mkdir(parents=True, exist_ok=True)
                (root / rel).write_text(body)
            (root / "locks.tsv").write_text(tsv)
            fails = []
            for row in read_locks(root / "locks.tsv"):
                fails.extend(check_row(root, row))
            hit = any(expect in f for f in fails) if expect else not fails
            print(f"  selftest {'ok  ' if hit else 'FAIL'} {label}")
            if not hit:
                for f in fails:
                    print("      got:", f)
                ok = False

    good = {"a.md": "The OBJ bank table `PRG:0x282D4` is 32 rows.\n",
            "b.md": "per-char OBJ bank table (PRG:0x282D4), measured.\n"}
    tsv = "t\tPRG:0x282D4\tOBJ bank table\ta.md,b.md\t\n"
    run("agreeing docs pass", good, tsv, None)
    run("missing file fires", good, "t\tPRG:0x282D4\tOBJ bank table\ta.md,c.md\t\n", "MISSING")
    run("presence fires on a doc that dropped the number",
        {"a.md": good["a.md"], "b.md": "the OBJ bank table lives somewhere.\n"}, tsv, "PRESENCE")
    run("rival fires on a different number beside the key",
        {"a.md": good["a.md"], "b.md": "OBJ bank table `PRG:0x282D8` (typo) and `PRG:0x282D4`.\n"},
        tsv, "RIVAL PRG:0x282D8")
    run("rival is case-insensitive",
        {"a.md": good["a.md"], "b.md": "OBJ bank table prg:0x282d8; PRG:0x282D4 too.\n"},
        tsv, "RIVAL prg:0x282d8")
    run("also-list allows the sibling twin",
        {"a.md": good["a.md"], "b.md": "OBJ bank table `PRG:0x282D4` / vsav2 `PRG:0x27530`.\n"},
        "t\tPRG:0x282D4\tOBJ bank table\ta.md,b.md\tPRG:0x27530\n", None)
    run("RAM shape",
        {"a.md": "id pair `RAM:$FF8782` / `RAM:$FF8B82`\n"},
        "t\tRAM:$FF8782\tid pair\ta.md\tRAM:$FF8B82\n", None)
    run("RAM rival fires",
        {"a.md": "id pair `RAM:$FF8783`\n"},
        "t\tRAM:$FF8782\tid pair\ta.md\t\n", "RIVAL")
    run("integer shape with comma grouping",
        {"a.md": "bank-5 non-blank count 6,272 tiles\n", "b.md": "non-blank count 6,272\n"},
        "t\t6,272\tnon-blank count\ta.md,b.md\t\n", None)
    run("integer rival fires",
        {"a.md": "non-blank count 6,271 tiles\n"},
        "t\t6,272\tnon-blank count\ta.md\t\n", "RIVAL 6,271")
    run("hash shape",
        {"a.md": "opcode-view sha1 22bb468496cc9738\n"},
        "t\t22bb468496cc9738\topcode-view sha1\ta.md\t\n", None)
    run("unknown shape is refused",
        {"a.md": "x\n"}, "t\tnot-a-number\tx\ta.md\t\n", "matches no known shape")
    return ok


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", type=Path, default=REPO)
    ap.add_argument("--locks", type=Path, default=None,
                    help="lock table (default <root>/docs/doc_locks.tsv)")
    ap.add_argument("-v", "--verbose", action="store_true")
    ap.add_argument("--no-selftest", action="store_true")
    a = ap.parse_args()
    locks = a.locks or (a.root / "docs" / "doc_locks.tsv")
    if not locks.is_file():
        sys.exit(f"FAIL: no lock table at {locks}")
    tree_ok = check(a.root, locks, a.verbose)
    self_ok = True if a.no_selftest else selftests()
    print("PASS" if tree_ok and self_ok else "FAIL")
    sys.exit(0 if tree_ok and self_ok else 1)


if __name__ == "__main__":
    main()
