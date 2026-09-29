#!/usr/bin/env python3
"""scratch_census.py — every scratch program a session wrote is CLASSED, and each class holds (14z-185b, GitHub
#190 P4, maintainer-ruled 2026-09-29 "P1+P2, then P4").

WHY. The close checklist's step 5 promotes a scratch script whose figures a document quotes. In the 14z-185
close, rule-checker runs 422, 438 and 439 found the census that was meant to show it printing classes and reasons
but checking only that a reason existed. The scratch census that answered them hard-coded that session's
directories and builds. This is the MECHANISM.

THE CLASS FILE (a session's own, under build/; tab-separated, `#` comments):
  path<TAB>PROMOTED<TAB>tools/the_tool.py          promoted into this tracked file
  path<TAB>CLOSE-CHECK<TAB>-                        a close-time check, run by the close's checks file
  path<TAB>NOT PROMOTED<TAB>the reason              kept as scratch, with its reason
`path` is repo-relative. Every PROGRAM (.py .sh .lua .pl) under the scratch directories must have a row.

THE VERDICT fails on any of:
  UNCLASSED   a scratch program with no row
  PROMOTED    its target is not a tracked file, or HANDOFF.md does not name it
  CLOSE-CHECK the close's checks file (--checks, tools/close_checks.py's format) runs no command naming it, or a
              tracked file names its path (a close check is scratch by definition: a tracked reference means it
              should have been promoted)
  NO REASON   a NOT PROMOTED row with an empty reason
  STALE       a row whose path does not exist, or an unknown class

Usage:
  python3 tools/scratch_census.py --classes FILE --dir DIR [--dir DIR]... [--checks CHECKS.tsv] [--root DIR]
  python3 tools/scratch_census.py --selftest
"""
import os, subprocess, sys, tempfile

PROG = (".py", ".sh", ".lua", ".pl")


def tracked(root):
    return set(subprocess.run(["git", "ls-files"], cwd=root, capture_output=True, text=True).stdout.split())


def names_path(root, files, path):
    """the tracked files whose text names `path`"""
    out = []
    for f in files:
        fp = os.path.join(root, f)
        try:
            if os.path.getsize(fp) > 4_000_000:
                continue
            if path in open(fp, encoding="utf-8", errors="ignore").read():
                out.append(f)
        except OSError:
            pass
    return out


def census(root, classes, dirs, checks):
    rows = {}
    for line in open(classes, encoding="utf-8"):
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        f = (line.rstrip("\n").split("\t") + ["", "", ""])[:3]
        rows[f[0]] = (f[1].strip(), f[2].strip())
    progs = []
    for d in dirs:
        for dp, dn, fs in os.walk(os.path.join(root, d)):
            dn[:] = [x for x in dn if x not in (".git", "__pycache__")]
            progs += [os.path.relpath(os.path.join(dp, x), root) for x in fs if x.endswith(PROG)]
    trk = tracked(root)
    handoff = open(os.path.join(root, "HANDOFF.md"), encoding="utf-8").read() if os.path.exists(os.path.join(root, "HANDOFF.md")) else ""
    cmds = ""
    if checks:
        cmds = "\n".join(l.split("\t", 2)[-1] for l in open(checks, encoding="utf-8") if l.strip() and not l.startswith("#"))
    bad = 0
    def fail(kind, msg):
        nonlocal bad
        bad += 1
        print(f"  {kind:11s} {msg}")
    for p in sorted(progs):
        if p not in rows:
            fail("UNCLASSED", p)
    for p, (cls, arg) in sorted(rows.items()):
        if not os.path.exists(os.path.join(root, p)):
            fail("STALE", f"{p}: no such file")
            continue
        if cls == "PROMOTED":
            if arg not in trk:
                fail("PROMOTED", f"{p}: target {arg or '(none)'} is not a tracked file")
            elif arg not in handoff:
                fail("PROMOTED", f"{p}: HANDOFF.md does not name {arg}")
            else:
                print(f"  ok          {p}: PROMOTED -> {arg}")
        elif cls == "CLOSE-CHECK":
            base = os.path.basename(p)
            if base not in cmds:
                fail("CLOSE-CHECK", f"{p}: the checks file runs no command naming {base}")
                continue
            refs = [f for f in names_path(root, sorted(trk), p)]
            if refs:
                fail("CLOSE-CHECK", f"{p}: named by tracked file(s) {', '.join(refs[:3])} — promote it")
            else:
                print(f"  ok          {p}: CLOSE-CHECK, run by the checks file")
        elif cls == "NOT PROMOTED":
            if not arg:
                fail("NO REASON", p)
            else:
                print(f"  ok          {p}: NOT PROMOTED — {arg[:80]}")
        else:
            fail("STALE", f"{p}: unknown class {cls!r}")
    print(f"scratch programs {len(progs)}  classed rows {len(rows)}  failures {bad}")
    return bad


def selftest():
    ok = True
    with tempfile.TemporaryDirectory() as root:
        def w(rel, t):
            p = os.path.join(root, rel)
            os.makedirs(os.path.dirname(p), exist_ok=True)
            open(p, "w").write(t)
        def sh(*c):
            subprocess.run(c, cwd=root, check=True, capture_output=True)
        sh("git", "init", "-q")
        w("tools/promoted.py", "print(1)\n")
        w("HANDOFF.md", "| run it | `tools/promoted.py` |\n")
        w("docs/doc.md", "nothing scratch here\n")
        sh("git", "add", "-A")
        sh("git", "-c", "user.email=t@t", "-c", "user.name=t", "commit", "-qm", "c")
        w("build/s/one.py", "x\n")
        w("build/s/check.py", "x\n")
        w("build/s/kept.sh", "x\n")
        w("build/s/notes.txt", "data, not a program\n")
        w("build/checks.tsv", "check\t0\tpython3 build/s/check.py\n")
        good = ("build/s/one.py\tPROMOTED\ttools/promoted.py\n"
                "build/s/check.py\tCLOSE-CHECK\t-\n"
                "build/s/kept.sh\tNOT PROMOTED\ta one-off plot, quoted nowhere\n")
        cases = [
            ("clean", good, None, 0),
            ("UNCLASSED", good.replace("build/s/kept.sh\tNOT PROMOTED\ta one-off plot, quoted nowhere\n", ""), None, 1),
            ("PROMOTED untracked", good.replace("tools/promoted.py\n", "tools/missing.py\n"), None, 1),
            ("PROMOTED not in HANDOFF", good, "handoff-drop", 1),
            ("CLOSE-CHECK not run", good, "check\t0\tpython3 build/s/other.py\n", 1),
            ("CLOSE-CHECK named by a tracked file", good, "tracked-ref", 1),
            ("NO REASON", good.replace("a one-off plot, quoted nowhere", ""), None, 1),
            ("STALE", good + "build/s/gone.py\tNOT PROMOTED\tdeleted since\n", None, 1),
        ]
        for name, cls, checks_override, want in cases:
            w("build/classes.tsv", cls)
            if checks_override == "tracked-ref":
                w("docs/doc.md", "see build/s/check.py\n")
                sh("git", "add", "docs/doc.md")
            elif checks_override == "handoff-drop":
                w("HANDOFF.md", "| nothing here |\n")
            elif checks_override:
                w("build/checks.tsv", checks_override)
            print(f"-- case {name}")
            got = census(root, os.path.join(root, "build/classes.tsv"), ["build/s"], os.path.join(root, "build/checks.tsv"))
            g = (got == 0) if want == 0 else (got >= 1)
            ok = ok and g
            print(("  ok: " if g else "  FAIL: ") + f"case {name}: {got} failure(s), expected " + ("none" if want == 0 else "at least one"))
            w("build/checks.tsv", "check\t0\tpython3 build/s/check.py\n")
            if checks_override == "tracked-ref":
                w("docs/doc.md", "nothing scratch here\n")
                sh("git", "add", "docs/doc.md")
            if checks_override == "handoff-drop":
                w("HANDOFF.md", "| run it | `tools/promoted.py` |\n")
    print("SELFTEST " + ("PASS" if ok else "FAIL"))
    return 0 if ok else 1


def main():
    a = sys.argv[1:]
    if a[:1] == ["--selftest"]:
        return selftest()
    opt = lambda k: [a[i + 1] for i, x in enumerate(a) if x == k]
    if not opt("--classes") or not opt("--dir"):
        sys.exit(__doc__)
    root = (opt("--root") or [os.getcwd()])[0]
    return 1 if census(root, opt("--classes")[0], opt("--dir"), (opt("--checks") or [None])[0]) else 0


if __name__ == "__main__":
    sys.exit(main())
