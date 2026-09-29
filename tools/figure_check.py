#!/usr/bin/env python3
"""figure_check.py — every figure a close STATES equals the output it came from, and every figure of a
claim is either checked or named as unchecked (14z-185b, GitHub #190 P1, maintainer-ruled 2026-09-29
"P1+P2, then P4").

WHY. In the 14z-185 close, rule-checker runs 417, 424, 436 and 440 each found a figure the close's prose
stated that no check had compared with its source, or a claim figure nobody had listed as unchecked. The
scratch checker that answered them (build/agent185/close/close_figures.py) hard-coded that close's own
phrases. This is its MECHANISM; a close writes only its SPEC (under build/, like its other checks).

THE SPEC (tab-separated, `#` comments), three row kinds:
  figure<TAB>NAME<TAB>DOC<TAB>DOC_REGEX<TAB>SOURCE<TAB>SOURCE_REGEX
      DOC is a repo path, optionally `PATH::MARKER` to search only the lines containing MARKER (a STATE
      row's key, say). DOC_REGEX and SOURCE_REGEX are Python regexes with ONE group: the figure as stated
      and the value in the output. Equal after dropping thousands separators (and as numbers).
  claim<TAB>PATH[::MARKER]
      the claim whose figures are censused (at most one claim row).
  unchecked<TAB>FIGURE<TAB>REASON
      a claim figure deliberately not compared, with its reason.

THE VERDICT fails on ANY of four things, each its own plant in the selftest (#185 item 5):
  MISMATCH    a figure row's stated value differs from its source value
  NOT FOUND   a figure row's DOC_REGEX or SOURCE_REGEX matches nothing (or a file is missing)
  UNCOVERED   a claim figure (tools/agent/extract.py's `figures()`: 2+ digits or a decimal, never an issue
              number, a session key, a year, hex or a date) that no figure row on the claim states and no
              unchecked row names
  STALE       an unchecked row whose figure the claim no longer contains, or with an empty reason

Usage:
  python3 tools/figure_check.py SPEC [--root DIR]     exit 0 all clean, 1 any failure
  python3 tools/figure_check.py --selftest
"""
import os, re, sys, tempfile

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "agent"))
from extract import figures  # noqa: E402


def norm(v):
    v = v.replace(",", "").strip()
    try:
        return repr(float(v))
    except ValueError:
        return v


def text_of(root, spec):
    path, _, marker = spec.partition("::")
    fp = os.path.join(root, path)
    if not os.path.isfile(fp):
        return None
    t = open(fp, encoding="utf-8", errors="replace").read()
    if marker:
        t = "\n".join(l for l in t.split("\n") if marker in l)
    return t


def read_spec(path):
    figs, claim, unchecked = [], None, []
    for n, line in enumerate(open(path, encoding="utf-8"), 1):
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        f = line.rstrip("\n").split("\t")
        if f[0] == "figure" and len(f) == 6:
            figs.append(f[1:])
        elif f[0] == "claim" and len(f) == 2 and claim is None:
            claim = f[1]
        elif f[0] == "unchecked" and len(f) == 3:
            unchecked.append((f[1], f[2]))
        else:
            sys.exit(f"{path}:{n}: not a figure / claim / unchecked row (or a second claim row)")
    return figs, claim, unchecked


def check(spec, root):
    figs, claim, unchecked = read_spec(spec)
    bad = 0
    stated_on_claim = set()
    for name, doc, drx, src, srx in figs:
        dt, st = text_of(root, doc), text_of(root, src)
        dm = re.search(drx, dt) if dt is not None else None
        sm = re.search(srx, st) if st is not None else None
        if not dm or not sm:
            print(f"  NOT FOUND  {name}: " + ("the stated figure" if not dm else "the source value")
                  + f" ({doc if not dm else src})")
            bad += 1
            continue
        a, b = dm.group(1), sm.group(1)
        if norm(a) != norm(b):
            print(f"  MISMATCH   {name}: stated {a} in {doc}, source {b} in {src}")
            bad += 1
        else:
            print(f"  ok         {name}: {a}")
        if claim is not None and doc == claim:
            stated_on_claim.add(a.replace(",", ""))
    if claim is not None:
        ct = text_of(root, claim)
        if ct is None:
            print(f"  NOT FOUND  the claim {claim}")
            return bad + 1
        cf = figures(ct)
        un = {f.replace(",", ""): r for f, r in unchecked}
        for f in cf:
            if f in stated_on_claim:
                continue
            if f in un and un[f].strip():
                print(f"  unchecked  {f}: {un[f]}")
            else:
                print(f"  UNCOVERED  claim figure {f}: no figure row states it and no unchecked row names it")
                bad += 1
        for f, r in unchecked:
            if f.replace(",", "") not in cf or not r.strip():
                print(f"  STALE      unchecked {f}: " + ("the claim no longer contains it" if f.replace(",", "") not in cf else "empty reason"))
                bad += 1
        print(f"claim figures: {len(cf)}  checked {len([f for f in cf if f in stated_on_claim])}  "
              f"unchecked {len([f for f in cf if f not in stated_on_claim and f in un])}")
    print(f"figure rows: {len(figs)}  failures: {bad}")
    return bad


def selftest():
    ok = True
    with tempfile.TemporaryDirectory() as d:
        def w(rel, t):
            open(os.path.join(d, rel), "w").write(t)
        w("row.md", "| CLOSE | the checks: 72 runs, 0 not as expected |\nother line 99 runs\n")
        w("claim.txt", "The close ran 72 checks over 1,539 files; run 446 is OK.\n")
        w("out.txt", "run: full  checks run 72  not as expected 0\nfiles 1539\n")
        base = ("figure\truns\trow.md::CLOSE\t(\\d+) runs\tout.txt\tchecks run (\\d+)\n"
                "figure\tclaim-runs\tclaim.txt\tran (\\d+) checks\tout.txt\tchecks run (\\d+)\n"
                "figure\tclaim-files\tclaim.txt\tover ([\\d,]+) files\tout.txt\tfiles (\\d+)\n"
                "claim\tclaim.txt\n"
                "unchecked\t446\ta rule-checker run id, not a measurement\n")
        cases = [
            ("clean", base, 0),
            ("MISMATCH", base.replace("checks run (\\d+)\n", "not as expected (\\d+)\n", 1), 1),
            ("NOT FOUND", base.replace("(\\d+) runs", "(\\d+) passes", 1), 1),
            ("UNCOVERED", base.replace("unchecked\t446\ta rule-checker run id, not a measurement\n", ""), 1),
            ("STALE", base + "unchecked\t999\tno longer in the claim\n", 1),
        ]
        for name, spec, want in cases:
            w("spec.tsv", spec)
            print(f"-- case {name}")
            got = check(os.path.join(d, "spec.tsv"), d)
            good = (got == 0) == (want == 0) and (want == 0 or got >= 1)
            ok = ok and good
            print(("  ok: " if good else "  FAIL: ") + f"case {name}: {got} failure(s), expected " + ("none" if want == 0 else "at least one"))
    print("SELFTEST " + ("PASS" if ok else "FAIL"))
    return 0 if ok else 1


def main():
    a = sys.argv[1:]
    if a[:1] == ["--selftest"]:
        return selftest()
    if not a:
        sys.exit(__doc__)
    root = a[a.index("--root") + 1] if "--root" in a else os.getcwd()
    return 1 if check(a[0], root) else 0


if __name__ == "__main__":
    sys.exit(main())
