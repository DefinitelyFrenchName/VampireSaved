#!/usr/bin/env python3
"""freeze_set_shape.py — a newly frozen expectation set LOSES NOTHING its predecessor held (14z-185b, GitHub #150,
maintainer-ruled 2026-09-29: "S1 nothing lost", "P1 by family", "D1 full driver").

WHY. The freeze ritual had three silent-green failure modes (docs/project/gotchas.md, 14z-159): an unpinned
`MAME_BIN`, a set frozen into an EMPTY directory (the authored classes never carried, so the whole legacy corpus
self-freezes into a tautology, [VSP-36]), and a merged set keeping the tenant `.sha1` that `--freeze` regenerates
(#111). This gate checks the SHAPE of a set against its predecessor, never its values: it cannot make a wrong
expectation look right.

THE PREDECESSOR (P1). A numbered set is `<x>-m<N><y>` under tests/expected/ (x one of donovan, huitzil, pyron,
merged); its FAMILY is `<x>-m*<y>`; its predecessor is the family's highest lower N. A one-set family has none.

THE RULE (S1), per set with a predecessor. FAIL on any of:
  LOST        a `.masked` or `.skip` name of the predecessor absent from the set; a `.sha1` name absent unless it
              reappears as a `.masked`, `.skip` or `.diverge` (a RECLASSIFICATION: promoted to an authored spec —
              measured 14z-185b, 13 of the 14 historical `.sha1` removals);
  MASK        the predecessor's mask changed or removed (a mask introduced where the predecessor had none is the
              masked basis arriving: printed, allowed);
  MERGED SHA1 a `merged-m*` set holding any `.sha1` (#111: tenant-content expectations belong to the solo sets);
  STALE       an exception row that no longer matches a loss.
A loss named in tests/expected/set_shape_exceptions.tsv (`set<TAB>class<TAB>name<TAB>reason`) is allowed and
printed. Additions are allowed and printed.

Usage:
  python3 tools/freeze_set_shape.py [--set NAME] [--root DIR]    every numbered set, or one; exit 0 clean, 1 any failure
  python3 tools/freeze_set_shape.py --selftest
"""
import os, re, sys, tempfile

FAM = re.compile(r"^((?:donovan|huitzil|pyron|merged)-m)(\d+)(.*)$")
EXC = "tests/expected/set_shape_exceptions.tsv"


def sets_of(base):
    fams = {}
    for d in os.listdir(base):
        m = FAM.match(d)
        if m and os.path.isdir(os.path.join(base, d)):
            fams.setdefault(m.group(1) + "*" + m.group(3), []).append((int(m.group(2)), d))
    pred = {}
    for fam, rows in fams.items():
        rows.sort()
        for (_, a), (_, b) in zip(rows, rows[1:]):
            pred[b] = a
    return pred, {d for rows in fams.values() for _, d in rows}


def shape(base, d):
    fs = os.listdir(os.path.join(base, d))
    names = lambda ext: {f[:-len(ext)] for f in fs if f.endswith(ext)}
    mp = os.path.join(base, d, "mask")
    return {"masked": names(".masked"), "skip": names(".skip"), "sha1": names(".sha1"),
            "diverge": names(".diverge"), "mask": open(mp).read() if os.path.exists(mp) else None}


def check(root, only=None):
    base = os.path.join(root, "tests/expected")
    pred, allsets = sets_of(base)
    exc = {}
    ep = os.path.join(root, EXC)
    if os.path.exists(ep):
        for line in open(ep, encoding="utf-8"):
            if line.strip() and not line.startswith("#"):
                f = (line.rstrip("\n").split("\t") + ["", "", "", ""])[:4]
                exc[(f[0], f[1], f[2])] = f[3]
    used, bad = set(), 0
    todo = sorted(allsets) if only is None else [only]
    for s in todo:
        if s not in allsets:
            print(f"  FAIL        {s}: not a numbered expectation set under tests/expected/")
            bad += 1
            continue
        B = shape(base, s)
        if s.startswith("merged-m") and B["sha1"]:
            print(f"  MERGED SHA1 {s}: {len(B['sha1'])} .sha1 ({' '.join(sorted(B['sha1']))[:120]})")
            bad += 1
        if s not in pred:
            continue
        A = shape(base, pred[s])
        lost = []
        for cls in ("masked", "skip"):
            lost += [(cls, n) for n in sorted(A[cls] - B[cls])]
        reclass = B["masked"] | B["skip"] | B["diverge"]
        for n in sorted(A["sha1"] - B["sha1"]):
            if n in reclass:
                print(f"  reclassed   {s}: {n}.sha1 -> {'/'.join(c for c in ('masked', 'skip', 'diverge') if n in B[c])}")
            else:
                lost.append(("sha1", n))
        for cls, n in lost:
            k = (s, cls, n)
            if k in exc and exc[k].strip():
                used.add(k)
                print(f"  excepted    {s}: {n}.{cls} — {exc[k][:100]}")
            else:
                print(f"  LOST        {s}: {n}.{cls} (held by {pred[s]})")
                bad += 1
        if A["mask"] is not None and A["mask"] != B["mask"]:
            k = (s, "mask", "mask")
            if k in exc and exc[k].strip():
                used.add(k)
                print(f"  excepted    {s}: mask — {exc[k][:100]}")
            else:
                print(f"  MASK        {s}: the mask of {pred[s]} changed or removed")
                bad += 1
        elif A["mask"] is None and B["mask"] is not None:
            print(f"  introduced  {s}: the mask (its predecessor {pred[s]} had none)")
        add = {c: len(B[c] - A[c]) for c in ("masked", "skip", "sha1") if B[c] - A[c]}
        if add:
            print(f"  added       {s}: " + " ".join(f"{c} +{v}" for c, v in add.items()))
    if only is None:
        for k in exc:
            if k not in used:
                print(f"  STALE       exception {k[0]} {k[1]} {k[2]}: matches no loss")
                bad += 1
    print(f"sets checked {len(todo)}  with a predecessor {sum(1 for s in todo if s in pred)}  failures {bad}")
    return bad


def selftest():
    ok = True
    with tempfile.TemporaryDirectory() as root:
        base = os.path.join(root, "tests/expected")
        def mk(d, files):
            os.makedirs(os.path.join(base, d), exist_ok=True)
            for f in files:
                open(os.path.join(base, d, f), "w").write("x" if f != "mask" else "4182-41a2")
        def reset():
            import shutil
            shutil.rmtree(base, ignore_errors=True)
            mk("donovan-m1", ["a.masked", "b.skip", "t.sha1", "mask"])
            mk("merged-m1", ["a.masked", "mask"])
            open(os.path.join(root, EXC), "w").write("# set\tclass\tname\treason\n")
        cases = [
            ("clean (a replay added)", ["a.masked", "b.skip", "t.sha1", "c.masked", "mask"], [], "donovan-m2", 0),
            ("an empty-dir freeze", ["t.sha1"], [], "donovan-m2", 1),
            ("a lost .skip", ["a.masked", "t.sha1", "mask"], [], "donovan-m2", 1),
            ("a .sha1 reclassified as .masked", ["a.masked", "b.skip", "t.masked", "mask"], [], "donovan-m2", 0),
            ("a .sha1 lost", ["a.masked", "b.skip", "mask"], [], "donovan-m2", 1),
            ("a .sha1 lost, declared", ["a.masked", "b.skip", "mask"], ["donovan-m2\tsha1\tt\twhy it left"], "donovan-m2", 0),
            ("the mask changed", ["a.masked", "b.skip", "t.sha1"], [], "donovan-m2", 1),
            ("a merged set with a .sha1", ["a.masked", "mask", "z.sha1"], [], "merged-m2", 1),
            ("a stale exception", ["a.masked", "b.skip", "t.sha1", "mask"], ["donovan-m2\tmasked\tnever\tno such loss"], "donovan-m2", 1),
        ]
        for name, files, exc_rows, newset, want in cases:
            reset()
            mk(newset, files)
            if exc_rows:
                open(os.path.join(root, EXC), "a").write("\n".join(exc_rows) + "\n")
            if "mask" in files and newset == "donovan-m2" and name == "the mask changed":
                pass
            print(f"-- case {name}")
            got = check(root)
            g = (got == 0) if want == 0 else (got >= 1)
            ok = ok and g
            print(("  ok: " if g else "  FAIL: ") + f"case {name}: {got} failure(s), expected " + ("none" if want == 0 else "at least one"))
    print("SELFTEST " + ("PASS" if ok else "FAIL"))
    return 0 if ok else 1


def main():
    a = sys.argv[1:]
    if a[:1] == ["--selftest"]:
        return selftest()
    root = a[a.index("--root") + 1] if "--root" in a else os.getcwd()
    only = a[a.index("--set") + 1] if "--set" in a else None
    return 1 if check(root, only) else 0


if __name__ == "__main__":
    sys.exit(main())
