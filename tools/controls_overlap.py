#!/usr/bin/env python3
"""controls_overlap.py — WHICH GATES' CONTROLS SHARE A WRITTEN PATH (#315, 14z-207; lane S's ctl_overlap.py, #312).

Reads the traces tools/trace_controls.sh wrote (one or more trace directories; each holds st/<gate>.<control>.st,
out/<gate>.<control>.out and done.tsv, whose 5th column is the repository root that control ran in) and, per gate,
lists every path written by TWO OR MORE of its controls and every path one control writes and another reads. A write
is a successful open/openat/creat with O_WRONLY, O_RDWR or O_CREAT (its path the absolute one strace -y printed), or a
rename's target. A RELATIVE rename target is placed (#321, 14z-210: five emulator gates read SHARED only on a
relative `vsavjw.zip`, every one inside its own mktemp dir) by the directory strace -y printed for its renameat
dirfd (`AT_FDCWD</dir>` or `N</dir>`), else by the same pid's last `AT_FDCWD</dir>`; one that cannot be placed is kept as
written and listed apart, which reads SHARED. /dev, /proc, /sys, pipes
and sockets are ignored; a path under a control's own mktemp directory (/tmp/tmp.*, /tmp/<name>.<6+ random>) differs
per control and cannot collide; Python's bytecode caches (__pycache__/*.pyc) are written atomically and are already
shared across gates, so they are set aside. A gate is HOLLOW when every one of its control runs printed a SKIP line:
its trace wrote nothing a passing run writes, and it cannot earn a row from that trace.
Verdicts, one line per gate: SAFE (may be listed), SHARED (keep its controls serial), HOLLOW (trace it where it runs).
usage: controls_overlap.py <trace dir>... [--root DIR]   (--root for a done.tsv without its 5th column)"""
import collections, os, re, sys

args = sys.argv[1:]
default_root = None
if "--root" in args:
    i = args.index("--root"); default_root = args[i + 1].rstrip("/") + "/"; del args[i:i + 2]
OPEN_RET = re.compile(r'^(\d+)\s+(?:open|openat|creat)\((.*)\)\s+=\s+(\d+)<([^>]*)>')
RENAME = re.compile(r'^(\d+)\s+rename(?:at2?)?\((.*)\)\s+=\s+0')
CWD = re.compile(r'AT_FDCWD<([^>]*)>')
NEWDIR = re.compile(r'<([^>]*)>,\s*"((?:[^"\\]|\\.)*)"(?:,\s*[A-Z_|0-9]+)?\s*$')   # renameat's new dirfd, then the target
UNF = re.compile(r'^(\d+)\s+(\w+)\((.*) <unfinished \.\.\.>\s*$')
RES = re.compile(r'^(\d+)\s+<\.\.\. (\w+) resumed>(.*)$')
TMP = re.compile(r"^/tmp/(tmp\.|[^/]*\.[A-Za-z0-9]{6,}(/|$))")
PYC = re.compile(r"(^|/)__pycache__/[^/]+\.pyc$")


def lines(path):  # strace's lines with every split call re-joined (#283)
    pend = {}
    for line in open(path, errors="replace"):
        line = line.rstrip("\n")
        m = UNF.match(line)
        if m:
            pend[(m.group(1), m.group(2))] = "%s %s(%s" % (m.group(1), m.group(2), m.group(3)); continue
        m = RES.match(line)
        if m:
            head = pend.pop((m.group(1), m.group(2)), None)
            if head is not None:
                yield head + m.group(3)
            continue
        yield line


def writes(path, root):
    out, rel, rd = set(), set(), set()
    cwd = {}   # pid -> its last AT_FDCWD directory, as strace -y printed it
    for line in lines(path):
        pid = line.split(None, 1)[0] if line[:1].isdigit() else None
        c = CWD.search(line)
        if pid and c:
            cwd[pid] = c.group(1)
        m = OPEN_RET.match(line)
        if m:
            a, p = m.group(2), m.group(4)
            if p.startswith(("/dev/", "/proc/", "/sys/", "pipe:", "socket:", "anon_inode:")):
                continue
            q = p[len(root):] if p.startswith(root) else p
            (out if re.search(r"O_WRONLY|O_RDWR|O_CREAT", a) or line.split("(")[0].endswith("creat") else rd).add(q)
            continue
        m = RENAME.match(line)
        if m:
            q = re.findall(r'"([^"]*)"', m.group(2))
            if q:
                t = q[-1]
                if not t.startswith("/"):
                    d = NEWDIR.search(m.group(2))
                    base = d.group(1) if d and d.group(2) == t else cwd.get(m.group(1))
                    if base and base.startswith("/"):
                        t = os.path.normpath(os.path.join(base, t))
                (out if t.startswith("/") else rel).add(t[len(root):] if t.startswith(root) else t)
    return out, rel, rd


by_gate = collections.defaultdict(dict); skipped = collections.defaultdict(list)
for tr in args:
    roots = {}
    for row in open(os.path.join(tr, "done.tsv")):
        f = row.rstrip("\n").split("\t")
        if len(f) >= 2:
            roots[(f[0], f[1])] = (f[4].rstrip("/") + "/") if len(f) >= 5 and f[4] else default_root
    st = os.path.join(tr, "st")
    for name in sorted(os.listdir(st)):
        if not name.endswith(".st"):
            continue
        g, c = name[:-3].split(".", 1)
        root = roots.get((g, c)) or default_root
        if root is None:
            sys.exit("controls_overlap.py: no root for %s.%s (done.tsv has no 5th column; pass --root)" % (g, c))
        by_gate[g][c] = writes(os.path.join(st, name), root)
        o = os.path.join(tr, "out", g + "." + c + ".out")
        skipped[g].append(os.path.exists(o) and any(l.startswith("SKIP") for l in open(o, errors="replace")))
verdict = {}
for g in sorted(by_gate):
    seen = collections.defaultdict(set); rel = collections.defaultdict(set); read = collections.defaultdict(set)
    for c, (w, r, rd) in by_gate[g].items():
        for p in w:
            seen[p].add(c)
        for p in r:
            rel[p].add(c)
        for p in rd:
            read[p].add(c)
    keep = lambda p: not TMP.match(p) and not PYC.search(p)
    wr = {p: (seen[p], read[p] - seen[p]) for p in seen if read.get(p, set()) - seen[p] and keep(p)}
    shared = {p: cs for p, cs in seen.items() if len(cs) > 1 and keep(p)}
    rshared = {p: cs for p, cs in rel.items() if len(cs) > 1}
    hollow = all(skipped[g])
    verdict[g] = "HOLLOW" if hollow else ("SHARED" if shared or wr or rshared else "SAFE")
    print("== %s: %d controls traced, %d paths written by 2+ of them, %d written by one and read by another, "
          "%d relative rename targets shared%s -> %s" % (g, len(by_gate[g]), len(shared), len(wr), len(rshared),
                                                         ", every control SKIPped" if hollow else "", verdict[g]))
    for p, (ws, rs) in sorted(wr.items())[:8]:
        print("   (write/read) %s  written by %s, read by %s" % (p, ",".join(sorted(ws)), ",".join(sorted(rs))))
    for p, cs in sorted(shared.items())[:12]:
        print("   %s  <- %s" % (p, ",".join(sorted(cs))))
    for p, cs in sorted(rshared.items())[:4]:
        print("   (relative rename) %s  <- %s" % (p, ",".join(sorted(cs))))
for v in ("SAFE", "SHARED", "HOLLOW"):
    gs = [g for g in sorted(verdict) if verdict[g] == v]
    print("%s %d: %s" % (v, len(gs), " ".join(gs)))
