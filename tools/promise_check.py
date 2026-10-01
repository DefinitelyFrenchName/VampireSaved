#!/usr/bin/env python3
"""promise_check.py — every promise a sitting's record makes is FULFILLED, CARRIED or ruled NOT A PROMISE, and
each class holds (14z-187b, GitHub #190 P3; the maintainer, 2026-09-29: "Of note, P3 should be considered for
promotion later", worked 2026-10-01 at the maintainer's choice of "#190 P3 / #187 close tooling").

WHY. The close checklist's step 4 asks that every promise be fulfilled or made an open item.
tools/close_findings.py LISTS the candidates (its PROMISES section: PROMISE_PATTERNS over the sitting's STATE group
and its rule-checker resolutions) but checks nothing, and the two closes that checked built case-specific scratch:
14z-185's promises.py (two named promises, gate by gate) and 14z-186's promise_check.py (one START HERE item). This
is the MECHANISM. MEASURED while writing it: the pattern also matches finding text — three of 14z-184's five listed
"promises" are `until the landing` / `until the event` — so a class for a false hit, with its reason, is needed.

THE LIST is read, never typed: the same pattern over the same texts close_findings.py reads (the group
`## Session <key> — ...` of --state, and every ledger row whose session starts with the key, its resolution
column). Each hit is the whitespace-collapsed text from 70 characters before the match to 50 after it, clipped to
the table cell and the line the match is in.

THE CLASS FILE (a close's own, under build/; tab-separated, `#` comments):
  <match><TAB>FULFILLED<TAB>path § text       the promise was done: `text` is in the tracked file `path`
  <match><TAB>CARRIED<TAB>#N                  an open item: ticket #N, open or parked in docs/project/tickets.tsv
  <match><TAB>CARRIED<TAB>docs/NEXT_SESSION.md § text   an open item: `text` in NEXT_SESSION's START HERE
  <match><TAB>NOT-A-PROMISE<TAB>reason        the pattern's false hit, with the reason (three words at least)
`match` is a substring of exactly one listed promise. Texts are compared whitespace-collapsed.

THE VERDICT fails on any of:
  UNCLASSED     a listed promise no row matches
  AMBIGUOUS     a row whose match is in more than one promise
  STALE         a row whose match is in no promise, or an unknown class
  UNRESOLVED    FULFILLED: the path is not tracked, or the text is not in it
  PREDATES      FULFILLED: the text was already in the file at the sitting's base commit (the timing leg — a
                promise is not fulfilled by what was there before it was made)
  NOT OPEN      CARRIED #N: no index row, or its status is neither open nor parked
  NOT CARRIED   CARRIED in NEXT_SESSION: the text is not in its START HERE section
  NO REASON     NOT-A-PROMISE with fewer than three words of reason
The base commit is the parent of the first commit adding the sitting's STATE heading (close_findings.py's rule),
or --base.

A CLEAN RESULT PROVES ONLY THAT THE LISTED PROMISES ARE CLASSED: a promise the pattern does not match — a
commitment worded otherwise, or one made only in the transcript (the procedure check's QP1) — is not listed here.

Usage:
  python3 tools/promise_check.py --key 14z-187 --classes build/<dir>/promises.tsv [--state STATE.md] [--base C] [--root DIR]
  python3 tools/promise_check.py --selftest
"""
import argparse, os, re, subprocess, sys, tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from close_findings import PROMISE_PATTERNS  # the ONE pattern: what close_findings lists is what is checked

CLASSES = ("FULFILLED", "CARRIED", "NOT-A-PROMISE")


def ws(s):
    return re.sub(r"\s+", " ", s).strip()


def git(root, *a):
    return subprocess.run(["git", *a], cwd=root, capture_output=True, text=True).stdout


def find_promises(root, key, state_path):
    s = Path(state_path).read_text(errors="replace")
    m = re.search(rf"^## Session {re.escape(key)} — .*?(?=^## Session |^---$|^# |\Z)", s, re.M | re.S)
    if not m:
        sys.exit(f"no session group {key} in {state_path}")
    texts = [("STATE " + key, m.group(0))]
    led = Path(root) / "tests/rulecheck/ledger.tsv"
    if led.exists():
        for l in led.read_text().splitlines():
            t = l.split("\t")
            if len(t) > 9 and t[2].startswith(key):
                texts.append(("ledger " + t[0], t[9]))
    pat, out = re.compile(PROMISE_PATTERNS, re.I), []
    for src, text in texts:
        for h in pat.finditer(text):
            # the window never crosses a table cell or a line: two promises in neighbouring cells
            # would otherwise share context, and no match could name one of them
            lo = max(text.rfind("|", 0, h.start()), text.rfind("\n", 0, h.start())) + 1
            hi = min([i for i in (text.find("|", h.end()), text.find("\n", h.end())) if i >= 0] or [len(text)])
            out.append((src, ws(text[max(lo, h.start() - 70):min(hi, h.end() + 50)])))
    return out


def session_base(root, key):
    first = git(root, "log", "--reverse", "--format=%H", f"-S## Session {key} —", "--", "STATE.md").split()
    return git(root, "rev-parse", "--verify", "--quiet", f"{first[0]}^").strip() if first else None


def start_here(root):
    p = Path(root) / "docs/NEXT_SESSION.md"
    if not p.exists():
        return ""
    m = re.search(r"^## START HERE\n(.*?)(?=^## |\Z)", p.read_text(errors="replace"), re.M | re.S)
    return ws(m.group(1)) if m else ""


def ticket_status(root, n):
    p = Path(root) / "docs/project/tickets.tsv"
    for l in (p.read_text().splitlines() if p.exists() else []):
        t = l.split("\t")
        if t[0] == n and len(t) > 2:
            return t[2]
    return None


def check(root, key, classes_path, state_path, base):
    proms = find_promises(root, key, state_path)
    rows = []
    for l in Path(classes_path).read_text().splitlines():
        if not l.strip() or l.startswith("#"):
            continue
        t = l.split("\t")
        rows.append((t[0], t[1] if len(t) > 1 else "", t[2] if len(t) > 2 else ""))
    tracked = set(git(root, "ls-files").split())
    base = base or session_base(root, key)
    bad, claimed = [], set()
    for match, cls, ev in rows:
        hits = [i for i, (_, p) in enumerate(proms) if ws(match) in p]
        if cls not in CLASSES:
            bad.append(f"STALE       {match!r}: unknown class {cls!r}"); continue
        if not hits:
            bad.append(f"STALE       {match!r}: in no listed promise"); continue
        if len(hits) > 1:
            bad.append(f"AMBIGUOUS   {match!r}: in {len(hits)} promises"); continue
        claimed.add(hits[0])
        if cls == "FULFILLED":
            path, _, text = ev.partition(" § ")
            if path not in tracked or not (Path(root) / path).exists():
                bad.append(f"UNRESOLVED  {match!r}: {path} is not a tracked file"); continue
            if ws(text) == "" or ws(text) not in ws((Path(root) / path).read_text(errors="replace")):
                bad.append(f"UNRESOLVED  {match!r}: the text is not in {path}"); continue
            if not base:
                bad.append(f"UNRESOLVED  {match!r}: no base commit for {key} (pass --base)"); continue
            then = subprocess.run(["git", "show", f"{base}:{path}"], cwd=root, capture_output=True, text=True).stdout
            if ws(text) in ws(then):
                bad.append(f"PREDATES    {match!r}: the text was already in {path} at the base {base[:8]}"); continue
            print(f"  FULFILLED   {match!r} -> {path} § {ws(text)[:60]}")
        elif cls == "CARRIED":
            if ev.startswith("#"):
                st = ticket_status(root, ev[1:])
                if st not in ("open", "parked"):
                    bad.append(f"NOT OPEN    {match!r}: ticket {ev} is {st or 'not in the index'}"); continue
                print(f"  CARRIED     {match!r} -> ticket {ev} ({st})")
            else:
                path, _, text = ev.partition(" § ")
                if path != "docs/NEXT_SESSION.md" or not ws(text) or ws(text) not in start_here(root):
                    bad.append(f"NOT CARRIED {match!r}: not in docs/NEXT_SESSION.md's START HERE"); continue
                print(f"  CARRIED     {match!r} -> NEXT_SESSION START HERE § {ws(text)[:60]}")
        else:
            if len(ev.split()) < 3:
                bad.append(f"NO REASON   {match!r}: a NOT-A-PROMISE row needs its reason"); continue
            print(f"  NOT-A-PROMISE {match!r}: {ev}")
    for i, (src, p) in enumerate(proms):
        if i not in claimed:
            bad.append(f"UNCLASSED   {src}: ...{p[:150]}...")
    print(f"{len(proms)} promise(s) listed for {key}, {len(rows)} class row(s), base {base[:8] if base else '?'}")
    for b in bad:
        print(b)
    print("FAIL" if bad else "PASS: every listed promise is classed and its class holds"
          " (only the LISTED promises: a commitment the pattern does not match is not seen here)")
    return 1 if bad else 0


def selftest():
    """one case per failure condition, in a synthetic git repository"""
    d = tempfile.mkdtemp()
    def sh(*a): subprocess.run(a, cwd=d, check=True, capture_output=True)
    def w(p, s): os.makedirs(os.path.dirname(os.path.join(d, p)) or d, exist_ok=True); open(os.path.join(d, p), "w").write(s)
    sh("git", "init", "-q"); sh("git", "config", "user.email", "t@t"); sh("git", "config", "user.name", "t")
    w("docs/a.md", "an old fact was here\n")
    w("docs/project/tickets.tsv", "#h\n900\tbug\topen\tt\n901\tbug\tdone\tt\n")
    w("STATE.md", "# STATE\n\n## Session 99z-0 — old\n\nx\n")
    sh("git", "add", "-A"); sh("git", "commit", "-qm", "base")
    group = ("## Session 99z-1 — **selftest**\n\n| | |\n|---|---|\n"
             "| (1) | ALPHA the gate will be written next to the tool |\n"
             "| (2) | BRAVO the follow-up goes to next session as an item |\n"
             "| (3) | CHARLIE we held the pin until the landing frame |\n"
             "| (4) | DELTA the ticket will be fixed by the ticket owner |\n\n")
    # the oldest group ends at a level-1 heading, not at `---` (STATE.md since 14z-175): the standing
    # sections' quotes are not the sitting's promises, and the PASS case requires exactly four
    w("STATE.md", "# STATE\n\n" + group + "# STANDING SECTIONS\n\n- the maintainer: I'll install it\n")
    w("docs/a.md", "an old fact was here\nALPHA-DONE the gate was written\n")
    w("docs/NEXT_SESSION.md", "# N\n\n## START HERE\n\n1. **BRAVO-ITEM** the follow-up\n\n## OTHER\n\nBRAVO-OUTSIDE\n")
    sh("git", "add", "-A"); sh("git", "commit", "-qm", "session")
    good = "ALPHA\tFULFILLED\tdocs/a.md § ALPHA-DONE the gate was written\nBRAVO\tCARRIED\tdocs/NEXT_SESSION.md § BRAVO-ITEM\nCHARLIE\tNOT-A-PROMISE\tuntil the landing is a frame, not a commitment\nDELTA\tCARRIED\t#900\n"
    cases = [
        ("all classes hold", good, "PASS"),
        ("UNCLASSED", good.replace("DELTA\tCARRIED\t#900\n", ""), "UNCLASSED"),
        ("AMBIGUOUS", good + "the\tNOT-A-PROMISE\tmatches every row here\n", "AMBIGUOUS"),
        ("STALE (no promise)", good + "ZULU\tNOT-A-PROMISE\tno such promise at all\n", "STALE"),
        ("STALE (class)", good.replace("CHARLIE\tNOT-A-PROMISE", "CHARLIE\tMAYBE"), "STALE"),
        ("UNRESOLVED", good.replace("ALPHA-DONE the gate was written", "ALPHA-NEVER-WRITTEN"), "UNRESOLVED"),
        ("PREDATES", good.replace("ALPHA-DONE the gate was written", "an old fact was here"), "PREDATES"),
        ("NOT OPEN", good.replace("#900", "#901"), "NOT OPEN"),
        ("NOT CARRIED", good.replace("BRAVO-ITEM", "BRAVO-OUTSIDE"), "NOT CARRIED"),
        ("NO REASON", good.replace("until the landing is a frame, not a commitment", "no"), "NO REASON"),
    ]
    ok = True
    for name, rows, want in cases:
        cf = os.path.join(d, "classes.tsv"); open(cf, "w").write(rows)
        r = subprocess.run([sys.executable, __file__, "--key", "99z-1", "--classes", cf, "--root", d],
                           capture_output=True, text=True)
        got = r.stdout
        hit = (r.returncode == 0 and "PASS" in got and "4 promise(s) listed" in got) if want == "PASS" else (r.returncode == 1 and
              re.search(rf"^{re.escape(want.split(' (')[0])}\s", got, re.M) is not None)
        print(f"  {'ok  ' if hit else 'FAIL'}  {name}: {want}")
        ok = ok and hit
    print("SELFTEST PASS" if ok else "SELFTEST FAIL")
    sys.exit(0 if ok else 1)


def main():
    if "--selftest" in sys.argv:
        selftest()
    ap = argparse.ArgumentParser(description="every listed promise of a sitting is classed, and its class holds")
    ap.add_argument("--key", required=True)
    ap.add_argument("--classes", required=True)
    ap.add_argument("--state")
    ap.add_argument("--base")
    ap.add_argument("--root", default=str(Path(__file__).resolve().parent.parent))
    a = ap.parse_args()
    sys.exit(check(a.root, a.key, a.classes, a.state or os.path.join(a.root, "STATE.md"), a.base))


if __name__ == "__main__":
    main()
