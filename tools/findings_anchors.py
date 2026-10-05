#!/usr/bin/env python3
"""findings_anchors.py — every finding's HOME ANCHOR in a close's findings row is really in its home file
(14z-189, promoted from the close's scratch check after rule-checker run 2026-10-04-643 Q1/Q4).

WHY. A findings row gives each finding a home as `` `path` anchor text / test ``. `tools/homes_tracked.py` checks
that each named FILE is tracked; nothing checked that the ANCHOR TEXT is in it. At the 14z-189 close two findings
cited descriptive anchors ("the ugrep section", "The session column") that no line of their file held.

  python3 tools/findings_anchors.py check ROW_TITLE STATE_FILE
      for every finding (a), (b), ... of the row: the words after the backticked home file, up to ' / ' (and without
      a trailing ', GitHub #N'), must be found as a fixed string in that file. A home that is only a ticket
      (`GitHub #N`) is listed SKIP; any OTHER home with no backticked file is UNRESOLVED and counts as not found —
      #224 (14z-191): an anchor holding the table's own separator ` — ` split there, the tail ("#162 is parked")
      read as a home with no file, and it was SKIPped with exit 0, a check passing without checking.
      Prints `anchors checked N  not found M`; exit 1 when M > 0.
  python3 tools/findings_anchors.py plant ROW_TITLE STATE_FILE OUT
      writes OUT, a copy of STATE_FILE whose FIRST file-anchored finding has its anchor replaced by one no file holds
      (the check's must-fire plant, generated from the live row so it never goes stale).
  python3 tools/findings_anchors.py --selftest [--perturb skip-unresolved]
      a synthetic row with a found anchor, a missing anchor and a ticket-only home, each against its known answer,
      and a home split by the table's separator (#224). `--perturb skip-unresolved` restores the pre-#224 SKIP of
      an unresolved home — its self-test must FAIL (the must-fire control of tests/test_close_standing.sh).

WHAT IT CANNOT SEE: whether the anchored paragraph STATES the finding (a hand read); a home given only as a ticket.
"""
import os, re, sys, tempfile

PLANTED = "ZZ-NO-FILE-HOLDS-THIS-ANCHOR"
PERTURB = ""

def row_of(title, state):
    for line in open(state, encoding="utf-8"):
        if line.startswith("| **" + title):
            return line
    sys.exit(f"no row starting with '| **{title}' in {state}")

def findings(row):
    body = row[row.index("| (a) ") + 2:].rstrip().rstrip("|").rstrip()
    items = re.split(r"(?:^|;\s)\(([a-z])\)\s", body)
    for i in range(1, len(items) - 1, 2):
        letter, text = items[i], items[i + 1]
        home = text.rsplit(" — ", 1)[-1].split(" / ")[0].strip()
        m = re.match(r"`([^`]+)`\s+(.*)$", home)
        if not m:
            yield letter, None, home
        else:
            yield letter, m.group(1), re.sub(r",\s*GitHub #\d+\s*$", "", m.group(2)).strip()

def check(title, state, root="."):
    bad = n = 0
    for letter, path, anchor in findings(row_of(title, state)):
        if path is None:
            if re.fullmatch(r"GitHub #\d+", anchor) or PERTURB == "skip-unresolved":
                print(f"SKIP  ({letter}) home is a ticket only: {anchor}")
            else:
                n += 1; bad += 1
                print(f"FAIL  ({letter}) home UNRESOLVED (no backticked file, not a GitHub #N): {anchor[:70]}")
            continue
        n += 1
        try:
            found = anchor in open(os.path.join(root, path), encoding="utf-8").read()
        except OSError:
            found = False
        print(("ok    " if found else "FAIL  ") + f"({letter}) {path} § {anchor}")
        bad += not found
    print(f"anchors checked {n}  not found {bad}  ({state})")
    return 1 if bad else 0

def plant(title, state, out):
    row = row_of(title, state)
    for letter, path, anchor in findings(row):
        if path:
            new = row.replace(f"`{path}` {anchor}", f"`{path}` {PLANTED}", 1)
            if new != row:
                text = open(state, encoding="utf-8").read().replace(row, new, 1)
                os.makedirs(os.path.dirname(out) or ".", exist_ok=True)
                open(out, "w", encoding="utf-8").write(text)
                print(f"planted: finding ({letter}) anchor -> {PLANTED} in {out}")
                return 0
    print("REFUSED: no file-anchored finding to plant")
    return 3

def selftest():
    d = tempfile.mkdtemp()
    open(os.path.join(d, "home.md"), "w").write("THE REAL HEADING is here\n")
    st = os.path.join(d, "STATE.md")
    open(st, "w").write("| **(9) T** | (a) one — `home.md` THE REAL HEADING / none (r); (b) two — GitHub #5 / `t.sh` |\n")
    ok = check("(9) T", st, d) == 0
    out = os.path.join(d, "plant.md")
    ok &= plant("(9) T", st, out) == 0 and check("(9) T", out, d) == 1
    # #224: an anchor carrying the table's separator splits there and leaves a home with no file — a FAIL, not a SKIP
    st2 = os.path.join(d, "STATE2.md")
    open(st2, "w").write("| **(8) U** | (a) one — `home.md` THE REAL — HEADING / none (r) |\n")
    ok &= check("(8) U", st2, d) == 1
    print("SELFTEST " + ("PASS" if ok else "FAIL") + ": a found anchor passes, a ticket home is SKIP, the generated plant fails, "
          "a home split by the separator fails")
    return 0 if ok else 1

if __name__ == "__main__":
    a = sys.argv[1:]
    if a[:1] == ["--selftest"] and a[1:] in ([], ["--perturb", "skip-unresolved"]):
        PERTURB = a[2] if len(a) == 3 else ""
        sys.exit(selftest())
    if len(a) == 3 and a[0] == "check":
        sys.exit(check(a[1], a[2]))
    if len(a) == 4 and a[0] == "plant":
        sys.exit(plant(a[1], a[2], a[3]))
    sys.exit(__doc__)
