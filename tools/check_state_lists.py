#!/usr/bin/env python3
"""check_state_lists.py — AN OPEN LIST HOLDS ONLY WHAT IS OPEN (CLAUDE.md [VSP-17]).

  python3 tools/check_state_lists.py              # check the tree
  python3 tools/check_state_lists.py -v           # ...and print every violation key
  python3 tools/check_state_lists.py --freeze     # rewrite the debt file (a reviewed diff)
  python3 tools/check_state_lists.py --root DIR   # a copy of the tree (the gate's controls)

WHY THIS EXISTS (14z-154; maintainer-ruled 2026-09-14). STATE.md's open lists
had filled with items marked closed IN PLACE — struck through, "DONE", "FIXED" —
because STATE.md's own header prescribed that, the port skill repeated it, and
nothing read the lists, the ~150 KB budget or the three-group rule. The
maintainer: the discipline must be "documented and enforced", not "just a
mention somewhere that never sees any systematic action". The law is now
CLAUDE.md [VSP-17] and [VSP-182]; this is the enforcement.

WHAT IT CHECKS, each violation named by a stable KEY:
  size          STATE.md is at most 150 KiB
  groups        at most three session groups above `# STANDING SECTIONS`
  structure     exactly one `# STANDING SECTIONS` heading in STATE.md
  section:<h>   a `## ` heading under the standing sections that is not one of
                Standing rulings / STANDING PRINCIPLE / Decisions pending /
                THE DEADNESS REGISTER — or any heading there naming bugs, a
                backlog or tickets (tickets are docs/project/tickets.tsv)
  pending:<e>   an entry of STATE.md's "Decisions pending" carrying a CLOSED
                MARKER anywhere in it: `~~`, or one of the capitalised words in
                MARKERS below
  start-here:<e>  the same, for an entry of docs/NEXT_SESSION.md "START HERE"
  ruling:<e>    a "Standing rulings" entry that is more than one physical line,
                or names no home for its full entry (`DECISIONS_HISTORY.md` or a
                backticked path)
  ledger:<k>    THE LEDGER still in STATE.md, or a ledger key in STATE_HISTORY.md
                resolving to no record below the ledger (a `## Session <key>`
                heading or a `| **<key>` row label)

WHAT IT DOES NOT CLAIM: that an entry with no marker IS open. A closed item
described without any marker word passes; the markers are what marking in place
leaves behind, and that is the pattern the ruling retired.

THE DEBT (the retrofit, 2026-09-14): tests/expected/state_open_lists_debt.txt
lists the violations that existed when the rule was written. A violation not in
it FAILS; a listed key that no longer occurs FAILS too, until it is removed — so
the list stays exact and can only shrink. `--freeze` rewrites it, and REFUSES to
add a key without `--allow-growth "<reason>"`, which writes the reason into the
file (the rule-5 census's rule, 14z-141).
ROM-free, emulator-free, well under a second (ci_portable, tests/test_state_open_lists.sh).
"""
import argparse
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
STATE = "STATE.md"
HISTORY = "STATE_HISTORY.md"
NEXT = "docs/NEXT_SESSION.md"
DEBT = "tests/expected/state_open_lists_debt.txt"
BUDGET_KIB = 150
MAX_GROUPS = 3
ALLOWED_SECTIONS = ["Standing rulings", "STANDING PRINCIPLE", "Decisions pending", "THE DEADNESS REGISTER"]
TICKET_WORDS = re.compile(r"\b(bugs?|backlog|tickets?)\b", re.I)
MARKERS = ["DECIDED", "DONE", "FIXED", "CLOSED", "RESOLVED", "SETTLED", "RULED", "IMPLEMENTED",
           "DECLINED", "WITHDRAWN", "RETRACTED", "SHIPPED", "LANDED"]
MARKER_RE = re.compile(r"~~|\b(" + "|".join(MARKERS) + r")\b")
HOME_RE = re.compile(r"DECISIONS_HISTORY\.md|`[\w./-]+\.(?:md|sh|py|tsv|toml)`")
HDR_RE = re.compile(r"^(#{1,3}) (.*)$")
# A ledger line names its session in one of TWO forms — `- Session KEY — …` (the
# rollover recipe's) and `- **KEY** (date) — …` (four lines since 14z-156). Until
# 14z-179 only the first was matched, so the second form was never checked.
LEDGER_KEY_RE = re.compile(r"^- (?:Sessions? |\*\*)([0-9][0-9a-z-]*)")


def headings(lines):
    """[(level, title, first_line_index)] outside code fences; consecutive
    same-level heading lines are ONE wrapped header (the house style)."""
    out, fence, i = [], False, 0
    while i < len(lines):
        if lines[i].startswith("```"):
            fence = not fence
            i += 1
            continue
        m = None if fence else HDR_RE.match(lines[i])
        if not m:
            i += 1
            continue
        lvl, title, j = len(m.group(1)), m.group(2).strip(), i + 1
        while j < len(lines):
            mm = HDR_RE.match(lines[j])
            if not mm or len(mm.group(1)) != lvl:
                break
            title += " " + mm.group(2).strip()
            j += 1
        out.append((lvl, title, i))
        i = j
    return out


def body(lines, hdrs, idx):
    """The lines of heading idx up to the next heading of the same or a higher level."""
    lvl, _, start = hdrs[idx]
    end = len(lines)
    for l2, _, s2 in hdrs[idx + 1:]:
        if l2 <= lvl:
            end = s2
            break
    first = start + 1
    while first < end and HDR_RE.match(lines[first]):
        first += 1
    return lines[first:end]


ENTRY_RE = re.compile(r"^(?:- |\d+\. )")


def entries(block):
    """Top-level entries of a section body, each as its list of lines.

    A `- ` BULLET or a `1. ` NUMBERED item both start one. The numbered shape was
    added 14z-172: NEXT_SESSION's "START HERE" became a numbered list on
    2026-09-18 and this function only knew bullets, so the start-here check
    parsed ZERO entries and asserted nothing for ten revisions of that file —
    a dead branch nothing noticed because no must-fire control exercised it
    ([VSP-181], and `closed-start-here` is now that control).
    """
    out, cur = [], None
    for line in block:
        if ENTRY_RE.match(line):
            cur = [line]
            out.append(cur)
        elif HDR_RE.match(line):
            cur = None
        elif cur is not None:
            cur.append(line)
    return out


def key_of(text):
    t = re.sub(r"[*~`]", "", text[2:] if text.startswith("- ") else text)
    return " ".join(t.split())[:70]


def find_section(hdrs, lines, name, level=2):
    for k, (lvl, title, _) in enumerate(hdrs):
        if lvl == level and title.startswith(name):
            return body(lines, hdrs, k)
    return None


def violations(root):
    v = {}   # key -> message
    s_path = root / STATE
    s_text = s_path.read_text()
    s = s_text.splitlines()
    hdrs = headings(s)

    kib = len(s_text.encode()) / 1024
    if kib > BUDGET_KIB:
        v["size"] = f"STATE.md is {kib:.1f} KiB, over the {BUDGET_KIB} KiB budget — roll the oldest group"
    standing = [h for h in hdrs if h[0] == 1 and h[1].startswith("STANDING SECTIONS")]
    if len(standing) != 1:
        v["structure"] = f"STATE.md has {len(standing)} `# STANDING SECTIONS` headings, where exactly one is expected"
        return v
    split = standing[0][2]
    groups = [h for h in hdrs if h[0] == 2 and h[2] < split and h[1].startswith("Session")]
    if len(groups) > MAX_GROUPS:
        v["groups"] = (f"{len(groups)} session groups above # STANDING SECTIONS, at most {MAX_GROUPS} — "
                       f"roll the oldest to STATE_HISTORY.md")
    if any(h[0] == 1 and h[1].startswith("THE LEDGER") for h in hdrs):
        v["ledger:in-state"] = "THE LEDGER is still in STATE.md — it lives at the head of STATE_HISTORY.md"
    for lvl, title, i in hdrs:
        if i <= split or lvl == 1:
            continue
        if lvl == 2 and not any(title.startswith(a) for a in ALLOWED_SECTIONS):
            v[f"section:{key_of(title)}"] = (f"`## {title[:60]}` is not a standing section — the standing "
                                             f"sections are {' / '.join(ALLOWED_SECTIONS)}")
        elif TICKET_WORDS.search(title):
            v[f"section:{key_of(title)}"] = (f"`{'#' * lvl} {title[:60]}` lists tickets in STATE.md — bugs, "
                                             f"cosmetic items and evolutions are listed only in "
                                             f"docs/project/tickets.tsv")

    after = s[split:]
    ahdrs = headings(after)
    pend = find_section(ahdrs, after, "Decisions pending")
    for e in entries(pend or []):
        m = MARKER_RE.search("\n".join(e))
        if m:
            v[f"pending:{key_of(e[0])}"] = (f"a Decisions pending entry carries the closed marker `{m.group(0)}` — "
                                            f"a ruled decision moves to DECISIONS_HISTORY.md in the commit "
                                            f"that records it")
    rulings = find_section(ahdrs, after, "Standing rulings")
    for e in entries(rulings or []):
        extra = [x for x in e[1:] if x.strip()]
        if extra:
            v[f"ruling:{key_of(e[0])}"] = "a standing ruling is ONE line — the full entry lives in DECISIONS_HISTORY.md"
        elif not HOME_RE.search(e[0]):
            v[f"ruling:{key_of(e[0])}"] = "a standing ruling names no home for its full entry"

    n_path = root / NEXT
    if n_path.is_file():
        n = n_path.read_text().splitlines()
        start = find_section(headings(n), n, "START HERE")
        for e in entries(start or []):
            m = MARKER_RE.search("\n".join(e))
            if m:
                v[f"start-here:{key_of(e[0])}"] = (f"a START HERE entry carries the closed marker `{m.group(0)}` — "
                                                   f"an open list holds only what is open")

    h_path = root / HISTORY
    h = h_path.read_text().splitlines()
    led = [i for i, line in enumerate(h) if line.startswith("# THE LEDGER")]
    if len(led) != 1:
        v["ledger:missing"] = f"STATE_HISTORY.md has {len(led)} `# THE LEDGER` headings, where exactly one is expected"
        return v
    end = next((i for i in range(led[0] + 1, len(h)) if h[i] == "---" or h[i].startswith("## ")), len(h))
    records = "\n".join(h[end:])
    for line in h[led[0]:end]:
        m = LEDGER_KEY_RE.match(line)
        if not m:
            continue
        key = m.group(1).rstrip("-")
        pat = re.compile(r"(?m)^(?:#{2,3} Sessions? |\| \*\*)" + re.escape(key) + r"(?![0-9A-Za-z])")
        if not pat.search(records):
            v[f"ledger:{key}"] = f"the ledger key {key} resolves to no record below THE LEDGER in STATE_HISTORY.md"
    return v


def read_debt(path):
    if not path.is_file():
        return None
    return {line.rstrip("\n") for line in path.read_text().splitlines() if line.strip() and not line.startswith("#")}


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--root", default=str(REPO))
    ap.add_argument("--freeze", action="store_true")
    ap.add_argument("--allow-growth", metavar="REASON",
                    help="--freeze only: let the shrink-only list grow; the reason is written into the file")
    ap.add_argument("-v", "--verbose", action="store_true")
    a = ap.parse_args()
    root = Path(a.root).resolve()
    v = violations(root)
    debt_path = root / DEBT

    if a.freeze:
        old = read_debt(debt_path)
        added, gone = sorted(set(v) - (old or set())), sorted((old or set()) - set(v))
        if old is not None and added and not a.allow_growth:
            # the rule5 census's rule (14z-141): a shrink-only inventory never
            # grows by reflex — say why, and the reason is written into the file
            print(f"REFUSED: freezing would ADD {len(added)} violation key(s) to a shrink-only list:")
            for k in added:
                print(f"  {k}")
            print('fix them, or re-run with --allow-growth "<reason>" (written into the file)')
            return 3
        head = ["# tests/expected/state_open_lists_debt.txt — the violations of the open-list rule",
                "# (CLAUDE.md [VSP-17], maintainer-ruled 2026-09-14) that existed when it was written.",
                "# Read by tools/check_state_lists.py (gate tests/test_state_open_lists.sh). SHRINK-ONLY:",
                "# a violation not listed here fails, and a listed one that no longer occurs fails until",
                "# it is removed. Rewritten by --freeze, which is a reviewed diff and REFUSES to grow the",
                "# list without --allow-growth \"<reason>\"."]
        if debt_path.is_file():   # earlier growth reasons are kept, never rewritten away
            head += [line for line in debt_path.read_text().splitlines() if line.startswith("# GROWN:")]
        if old is not None and added:
            head.append(f"# GROWN: {', '.join(added)} — {a.allow_growth}")
        debt_path.write_text("\n".join(head + sorted(v)) + "\n")
        print(f"froze {len(v)} violation key(s) into {DEBT}")
        for k in added:
            print(f"  ADDED  {k}")
        for k in gone:
            print(f"  retired  {k}")
        return 0

    debt = read_debt(debt_path)
    fails = []
    if debt is None:
        fails.append(f"no debt file at {DEBT} — run --freeze once, as a reviewed diff")
        debt = set()
    for k in sorted(v):
        if k not in debt:
            fails.append(f"{k} — {v[k]}")
    for k in sorted(debt - set(v)):
        fails.append(f"{k} — no longer occurs: retire it from {DEBT} in this commit")
    if a.verbose:
        for k in sorted(v):
            print(f"  {'debt ' if k in debt else 'NEW  '} {k}")
    kib = len((root / STATE).read_bytes()) / 1024
    for f in fails:
        print(f"  FAIL  {f}")
    if fails:
        print(f"FAIL: {len(fails)} problem(s) with STATE.md's open lists")
        return 1
    print(f"PASS: STATE.md {kib:.1f} KiB; open lists clean apart from the frozen debt "
          f"({len(debt)} key(s), shrink-only); every ledger key resolves")
    return 0


if __name__ == "__main__":
    sys.exit(main())
