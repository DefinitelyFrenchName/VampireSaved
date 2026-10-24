#!/usr/bin/env python3
"""controls_concurrent.py — THE CONCURRENT-CONTROLS LIST STILL DESCRIBES THE GATES IT NAMES (#315, 14z-207).

tests/controls_concurrent.txt lets tests/run_all_static.sh --jobs N run a gate's must-fire controls beside one another
(#312). A gate earns its row from a WRITE TRACE of each of its control modes (no path two of them write, none writes a
path a sibling reads); the row records the git blob of the script that was traced. This census reads every row and
names:
  BADROW        a row that is not  gate<TAB>traced blob<TAB>trace<TAB>reason
  MISSING       a row whose tests/<gate>.sh does not exist
  UNREGISTERED  a gate in neither tests/ci_portable.txt nor tests/ci_static.txt (the runner never schedules it)
  FEWCONTROLS   a gate whose header declares fewer than two must-fire controls (nothing to run beside another)
  STALE         a gate whose script's blob differs from the traced one (the trace no longer describes it)
Each named row says: re-trace it or take it off the list. The declared controls are read as tests/lib/controls.sh's
vs_ctl_declared reads them: `# MUST-FIRE: <shape>: <name> — ...` lines in the header block (the comment lines after the
shebang, up to the first line that is not a comment). The blob is git's: sha1 of "blob <size>\\0" + the bytes.
usage: controls_concurrent.py [--root DIR] [--list FILE]     exit 1 when any row is named
Gate: tests/test_controls_concurrent.sh."""
import argparse, hashlib, os, re, sys

SHAPES = "perturbed-copy|shadow-tool|known-bad"
DECL = re.compile(r"^# MUST-FIRE: (?:%s): ([a-z0-9-]+) — .+$" % SHAPES)


def blob(path):
    data = open(path, "rb").read()
    return hashlib.sha1(b"blob %d\0" % len(data) + data).hexdigest()


def declared(path):
    names = []
    with open(path, encoding="utf-8", errors="replace") as f:
        for i, line in enumerate(f):
            line = line.rstrip("\n")
            if i == 0:
                continue
            if not line.startswith("#"):
                break
            m = DECL.match(line)
            if m:
                names.append(m.group(1))
    return names


def registered(root):
    regs = set()
    for r in ("tests/ci_portable.txt", "tests/ci_static.txt"):
        p = os.path.join(root, r)
        if os.path.exists(p):
            for line in open(p, encoding="utf-8"):
                f = line.split()
                if f and not f[0].startswith("#"):
                    regs.add(f[0])
    return regs


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=".")
    ap.add_argument("--list", default=None)
    a = ap.parse_args()
    lst = a.list or os.path.join(a.root, "tests/controls_concurrent.txt")
    regs = registered(a.root)
    named = rows = 0
    for n, line in enumerate(open(lst, encoding="utf-8"), 1):
        line = line.rstrip("\n")
        if not line or line.startswith("#"):
            continue
        rows += 1
        f = line.split("\t")
        if len(f) != 4 or not re.fullmatch(r"[0-9a-f]{40}", f[1]):
            print("BADROW\t%s:%d\t%s — want gate<TAB>traced blob<TAB>trace<TAB>reason" % (os.path.basename(lst), n, line[:60]))
            named += 1
            continue
        g, want = f[0], f[1]
        s = os.path.join(a.root, "tests", g + ".sh")
        if not os.path.exists(s):
            print("MISSING\t%s\ttests/%s.sh does not exist — re-trace it or take it off the list" % (g, g)); named += 1
            continue
        if g not in regs:
            print("UNREGISTERED\t%s\tin neither tests/ci_portable.txt nor tests/ci_static.txt — re-trace it or take it off the list" % g)
            named += 1
        k = len(declared(s))
        if k < 2:
            print("FEWCONTROLS\t%s\t%d\tdeclares %d must-fire control(s), fewer than two — re-trace it or take it off the list" % (g, k, k))
            named += 1
        now = blob(s)
        if now != want:
            print("STALE\t%s\t%s\t%s\tthe script changed after its write trace — re-trace it or take it off the list"
                  % (g, want[:12], now[:12]))
            named += 1
    print("%d listed gate(s) read; %d row(s) named" % (rows, named))
    return 1 if named else 0


if __name__ == "__main__":
    sys.exit(main())
