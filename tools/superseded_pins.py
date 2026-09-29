#!/usr/bin/env python3
"""superseded_pins.py — does a LIVE line in tests/ or tools/ pin a fingerprint the registry has SUPERSEDED?
(14z-185b, GitHub #167; found by the 14z-170 M19 close tier.)

WHY. A freeze moves the builds, and the re-point sweep renames every `build/<name>` it can find. A pinned
FINGERPRINT names no build, so the sweep cannot see it: tests/test_phasec_spaces.sh held donovan-m19-stock's
key after the M19 freeze moved the stock twin, and went red only at the close tier (freeze cadence).
docs/project/gotchas.md "THE RE-POINT SWEEP SEES BUILD NAMES IN THIS TREE" is the finding; this is its gate.

SUPERSEDED. tests/expected/registry.tsv rows are `key<TAB>name<TAB>note`. A row's FAMILY is its name with the
milestone number taken out (`donovan-m23-stage4` -> `donovan-m*-stage4`; `donovan-m2b` -> `donovan-m*b`); the
row with the highest number is the family's CURRENT one. A key is superseded when a non-current row of a
family carries it and the current row of that family does not (a build unchanged across freezes keeps its key
current).

A PIN is a hex token of 8 to 40 characters on a LIVE line of a program (.sh .py .lua .pl) under tests/ or
tools/ that is a prefix of a superseded key. Not live: a comment line (`#`, `--`), a python docstring line, and
a line recording provenance (`RE-FROZEN`, `(was `, `SUPERSEDED`). NAMED EXEMPTIONS (EXEMPT below) are pins held
on purpose.

Usage:
  python3 tools/superseded_pins.py [--root DIR]        exit 0 no live pin, 1 any
  python3 tools/superseded_pins.py --selftest
"""
import os, re, sys, tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# pins held ON PURPOSE: (file, the key's first 8 hex, why)
EXEMPT = [("tools/rulecheck.py", "00f9cf13",
           "BIRTH_REGISTRY_KEY: merged-m18's whole-set key, the rule-checker's permanent birth anchor (#167's ask)")]
PROG = (".sh", ".py", ".lua", ".pl")
HEX = re.compile(r"(?<![0-9a-fA-F])([0-9a-f]{8,40})(?![0-9a-fA-F])")
FAMILY = re.compile(r"^(.*-m)(\d+)(.*)$")
PROVENANCE = re.compile(r"RE-FROZEN|\(was |SUPERSEDED")


def registry(root):
    fams = {}
    for line in open(os.path.join(root, "tests/expected/registry.tsv"), encoding="utf-8"):
        if not line.strip() or line.startswith("#"):
            continue
        f = line.rstrip("\n").split("\t")
        if len(f) < 2 or not re.fullmatch(r"[0-9a-f]{40}", f[0]):
            continue
        m = FAMILY.match(f[1])
        fam, n = ((m.group(1) + "*" + m.group(3)), int(m.group(2))) if m else (f[1], 0)
        fams.setdefault(fam, []).append((n, f[0], f[1]))
    superseded = {}
    for fam, rows in fams.items():
        top = max(n for n, _, _ in rows)
        current = {k for n, k, _ in rows if n == top}
        for n, k, name in rows:
            if n < top and k not in current:
                superseded[k] = (name, fam, [nm for nn, kk, nm in rows if nn == top][0])
    return superseded


def live_lines(root, p):
    try:
        t = open(os.path.join(root, p), encoding="utf-8", errors="replace").read()
    except OSError:
        return []
    skip = set()
    if p.endswith(".py"):
        try:
            import battery_reach as br
            skip = br.docstring_lines(p, t)
        except Exception:
            skip = set()
    out = []
    for i, l in enumerate(t.split("\n"), 1):
        s = l.strip()
        if i in skip or s.startswith(("#", "--")) or PROVENANCE.search(l):
            continue
        out.append((i, l))
    return out


def scan(root):
    sup = registry(root)
    hits, used = [], set()
    for top in ("tests", "tools"):
        for dp, dn, fs in os.walk(os.path.join(root, top)):
            dn[:] = [x for x in dn if x not in (".git", "__pycache__", "rulecheck")]
            for fn in fs:
                if not fn.endswith(PROG):
                    continue
                p = os.path.relpath(os.path.join(dp, fn), root)
                if p == "tools/superseded_pins.py":   # its own EXEMPT list names the exempt keys
                    continue
                for i, l in live_lines(root, p):
                    for m in HEX.finditer(l):
                        tok = m.group(1)
                        for k, (name, fam, cur) in sup.items():
                            if k.startswith(tok):
                                if any(p == ep and tok.startswith(ek) for ep, ek, _ in EXEMPT):
                                    used.add((p, tok[:8]))
                                    continue
                                hits.append((p, i, tok, name, cur))
    stale = [(ep, ek) for ep, ek, _ in EXEMPT if (ep, ek) not in used]
    return sup, hits, stale


def report(root):
    sup, hits, stale = scan(root)
    for p, i, tok, name, cur in hits:
        print(f"  PIN   {p}:{i} holds {tok[:12]} — {name}, superseded by {cur}")
    for ep, ek, why in EXEMPT:
        if (ep, ek) in stale:
            print(f"  STALE exemption {ep} {ek}: no live pin matches it any more — remove it from EXEMPT")
        else:
            print(f"  exempt {ep} {ek}: {why}")
    print(f"superseded keys {len(sup)}  live pins {len(hits)}  stale exemptions {len(stale)}")
    return 1 if hits or stale else 0


def selftest():
    ok = True
    with tempfile.TemporaryDirectory() as root:
        def w(rel, t):
            p = os.path.join(root, rel)
            os.makedirs(os.path.dirname(p), exist_ok=True)
            open(p, "w").write(t)
        old, new, same = "a" * 40, "b" * 40, "c" * 40
        birth, merged_now = "00f9cf13" + "0" * 32, "d" * 40
        w("tests/expected/registry.tsv", f"# k\tname\tnote\n{old}\tdonovan-m1-stock\tx\n{new}\tdonovan-m2-stock\tx\n"
          f"{same}\tdonovan-m1-stage4\tx\n{same}\tdonovan-m2-stage4\tunchanged\n"
          f"{birth}\tmerged-m1\tthe birth key\n{merged_now}\tmerged-m2\tx\n")
        exempt_ok = f'BIRTH_REGISTRY_KEY = "{birth}"\n'
        cases = [
            ("clean", f'EXPECT="{new}"\n# was {old} in M1\n', exempt_ok, 0),
            ("a live superseded pin", f'EXPECT="${{1:-{old[:8]}}}"\n', exempt_ok, 1),
            ("a comment", f"# EXPECT={old}\n", exempt_ok, 0),
            ("a provenance note", f'EXPECT="{new}"  # RE-FROZEN (was {old[:8]})\n', exempt_ok, 0),
            ("a key unchanged across freezes", f'EXPECT="{same}"\n', exempt_ok, 0),
            ("the named exemption gone stale", f'EXPECT="{new}"\n', "x = 1\n", 1),
            ("the exempt key pinned elsewhere", f'KEY="{birth}"\n', exempt_ok, 1),
        ]
        for name, body, rc, want in cases:
            w("tests/test_x.sh", body)
            w("tools/rulecheck.py", rc)
            print(f"-- case {name}")
            got = report(root)
            g = got == want
            ok = ok and g
            print(("  ok: " if g else "  FAIL: ") + f"case {name}: exit {got}, expected {want}")
    print("SELFTEST " + ("PASS" if ok else "FAIL"))
    return 0 if ok else 1


def main():
    a = sys.argv[1:]
    if a[:1] == ["--selftest"]:
        return selftest()
    root = a[a.index("--root") + 1] if "--root" in a else os.getcwd()
    return report(root)


if __name__ == "__main__":
    sys.exit(main())
