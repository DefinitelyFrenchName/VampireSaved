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
shared across gates, so they are set aside.
ONLY AN HONOURED RUN CERTIFIES (#349, 14z-218). Each control run is classified by tests/lib/classify.sh's
vs_classify_control, the one classifier of this tree, from done.tsv's 3rd column (the exit status) and
out/<gate>.<control>.out; a run with no done.tsv row or no .out is UNRECORDED. A gate is HOLLOW when ANY of its control
runs is not HONOURED: a REFUSED, SKIPped (LIES/UNJUDGED), TIMEOUT or DIED run stopped short of the mode's real run, so
its trace is not that control's write set, and a listed gate runs ALL its controls at once (tests/lib/static_job.sh,
tests/run_all_emulator.sh), so one uncertified control leaves the whole row unsupported. Until #349 only a gate whose
EVERY run printed a SKIP line read HOLLOW: on ERIS (14z-216) test_readme_recording's five controls were each REFUSED
(exit 3, 0 s, no release MAME for the host), wrote nothing, and read SAFE.
Verdicts, one line per gate: SAFE (may be listed), SHARED (keep its controls serial), HOLLOW (trace it where every
control mode runs to its own FAIL).
usage: controls_overlap.py <trace dir>... [--root DIR] [--classify FILE]   (--root for a done.tsv without its 5th
column; --classify names tests/lib/classify.sh, default the one beside this tool)"""
import collections, os, re, subprocess, sys, tempfile

args = sys.argv[1:]
default_root = None
if "--root" in args:
    i = args.index("--root"); default_root = args[i + 1].rstrip("/") + "/"; del args[i:i + 2]
classify_sh = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "tests", "lib", "classify.sh")
if "--classify" in args:
    i = args.index("--classify"); classify_sh = os.path.abspath(args[i + 1]); del args[i:i + 2]
if not os.path.isfile(classify_sh):
    sys.exit("controls_overlap.py: no classifier at %s" % classify_sh)
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


CLASSIFY = r'''. "$1"; T="$(printf '\t')"; exec 3< "$2"
while IFS="$T" read -r st log g c <&3; do
    vs_classify_control "$st" "$log" "tests/$g.sh" "$c"; printf '%s\t%s\n' "$VS_CTL_EXEC" "$VS_CTL_EXEC_DETAIL"
done'''


def classify(runs):  # [(exit, log, gate, control)] -> [(class, detail)], through tests/lib/classify.sh in one shell
    if not runs:
        return []
    with tempfile.NamedTemporaryFile("w", suffix=".tsv", delete=False) as f:
        f.writelines("%s\t%s\t%s\t%s\n" % r for r in runs)
    try:
        env = dict(os.environ); env.pop("REPO", None)
        out = subprocess.run(["sh", "-c", CLASSIFY, "classify", classify_sh, f.name], stdin=subprocess.DEVNULL,
                             capture_output=True, text=True, env=env).stdout.splitlines()
    finally:
        os.unlink(f.name)
    if len(out) != len(runs):
        sys.exit("controls_overlap.py: the classifier answered %d line(s) for %d run(s)" % (len(out), len(runs)))
    return [tuple((l.split("\t", 1) + [""])[:2]) for l in out]


by_gate = collections.defaultdict(dict); klass = collections.defaultdict(dict); pending = {}
for tr in args:
    roots, exits = {}, {}
    for row in open(os.path.join(tr, "done.tsv")):
        f = row.rstrip("\n").split("\t")
        if len(f) >= 2:
            roots[(f[0], f[1])] = (f[4].rstrip("/") + "/") if len(f) >= 5 and f[4] else default_root
            exits[(f[0], f[1])] = f[2] if len(f) >= 3 and re.fullmatch(r"[0-9]+", f[2]) else None
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
        if exits.get((g, c)) is None or not os.path.isfile(o) or "\t" in o:
            klass[g][c] = ("UNRECORDED", "no exit status in done.tsv or no out/%s.%s.out" % (g, c)); pending.pop((g, c), None)
        else:   # the run whose writes are scored is the run that is classified (a later trace dir replaces both)
            pending[(g, c)] = (exits[(g, c)], o, g, c)
for (_, _, g, c), k in zip(pending.values(), classify(list(pending.values()))):
    klass[g][c] = k
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
    uncert = [c for c in sorted(by_gate[g]) if klass[g][c][0] != "HONOURED"]   # HONOURED-ONLY (#349)
    hollow = bool(uncert)
    verdict[g] = "HOLLOW" if hollow else ("SHARED" if shared or wr or rshared else "SAFE")
    print("== %s: %d controls traced, %d paths written by 2+ of them, %d written by one and read by another, "
          "%d relative rename targets shared%s -> %s" % (g, len(by_gate[g]), len(shared), len(wr), len(rshared),
          ", %d of them not HONOURED (%s)" % (len(uncert), ", ".join(sorted(set(klass[g][c][0] for c in uncert))))
          if hollow else "", verdict[g]))
    for c in uncert[:8]:
        print("   (not HONOURED) %s %s: %s" % (c, klass[g][c][0], klass[g][c][1][:100]))
    for p, (ws, rs) in sorted(wr.items())[:8]:
        print("   (write/read) %s  written by %s, read by %s" % (p, ",".join(sorted(ws)), ",".join(sorted(rs))))
    for p, cs in sorted(shared.items())[:12]:
        print("   %s  <- %s" % (p, ",".join(sorted(cs))))
    for p, cs in sorted(rshared.items())[:4]:
        print("   (relative rename) %s  <- %s" % (p, ",".join(sorted(cs))))
for v in ("SAFE", "SHARED", "HOLLOW"):
    gs = [g for g in sorted(verdict) if verdict[g] == v]
    print("%s %d: %s" % (v, len(gs), " ".join(gs)))
