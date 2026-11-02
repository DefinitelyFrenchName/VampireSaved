#!/usr/bin/env python3
"""crash_sweep.py — the call sites of `vs_ctl_show_err`, and the table that proves each one (#310, 14z-218).

`tests/lib/controls.sh` `vs_ctl_show_err` re-prints a perturbed copy's crash so a control MODE reads DIED or UNJUDGED,
never HONOURED (#310 group 5, 14z-215). `tests/test_crash_sweep.sh` proves every CALL of it: for each call site, a row of
`tests/expected/crash_sweep.tsv` plants a crash (a PATH shim, `tests/lib/crash_sweep.sh`) in what the mode runs, and the
mode must read DIED or UNJUDGED on the gate as it stands and HONOURED on a copy with the helper neutered — the second leg
is what shows the row reaches THAT call. This tool is the static half:

  sites  <gate.sh>                  one line per call site: its KEY, `<first argument>#<k>` (the k-th call with that
                                    argument in the gate). Keys survive edits that move lines; a new or removed call
                                    changes the set, which `check` reports.
  copy   <gate.sh> <out> [--neuter] the gate with each call wrapped as `vs_sweep_site '<key>' vs_ctl_show_err …`: the
                                    wrapper (inserted after the gate's one `. "$REPO/tests/lib/controls.sh"` line) runs
                                    the call unchanged and, when it returns non-zero (it fired), appends the key to
                                    $VS_SWEEP_SITES. --neuter also redefines the helper as `return 0` (the KNOWN-BAD leg).
  callers                           every tests/*.sh with at least one call site, with its count.
  check  <table.tsv>                the table is complete and well-formed: every caller is either covered (each of its
                                    site keys is the `site` of at least one row) or named on an `# EXEMPT: <gate> — why`
                                    line, or the site itself on an `# EXEMPT-SITE: <gate> <key> — why` line (a call no
                                    plant can reach, e.g. an expected-exception call behind a check for that exception);
                                    every row names an existing gate, its tier (static|emulator|linux), a declared
                                    mode (or PLAIN), a live site key or `-` (a regression row), kind py|sh|pyx, an nth >= 1, and expectations from the vocabulary below. Exit 1 on any
                                    problem, each printed `PROBLEM: …`.

A call is the word `vs_ctl_show_err` at a command position (line start, after `;`, `|`, `&`, `{`, `(`, `!`, `if`, `elif`,
`then`, `else`, `do`, `while`, `until`) on a line that is not a comment. Text inside a heredoc counts when it is code a gate writes and runs (a stub gate):
the table names such a gate on an EXEMPT line with its reason. Refuses (exit 2) a gate with no controls.sh source line,
or with more than one.
"""
import os
import re
import sys

CALL = re.compile(r'(^\s*|[;|&{(]\s*|\b(?:then|else|elif|if|do|while|until)\s+|!\s+)vs_ctl_show_err(?=\s)')
SRC_LINE = re.compile(r'(?m)^\. "\$REPO/tests/lib/controls\.sh".*$')
COLS = ["gate", "tier", "mode", "kind", "ere", "nth", "site", "fx", "kb", "note"]
TIERS = {"static", "emulator", "linux"}   # where the row runs: tests/test_crash_sweep.sh (static), its emulator
#   scope (--tier emulator: the target gate needs MAME/FBNeo), or a Linux host with podman (audit_release_linux_cleanhost)
FX_OK = {"DIED", "UNJUDGED", "DIED|UNJUDGED", "FAIL"}      # FAIL: a PLAIN row's verdict
KB_OK = {"HONOURED", "PASS", "-"}                           # -: the row is a regression row with no known-bad leg


def _calls(text):
    """-> [(line index, match, key)] for every call site, keys `<arg>#<k>`."""
    out, seen = [], {}
    for i, ln in enumerate(text.split("\n")):
        if re.match(r"\s*#", ln):
            continue
        for m in CALL.finditer(ln):
            rest = ln[m.end():].lstrip()
            a = re.match(r'("[^"]*"|\S+)', rest)
            arg = (a.group(1) if a else "?").replace("'", "")
            seen[arg] = seen.get(arg, 0) + 1
            out.append((i, m, "%s#%d" % (arg, seen[arg])))
    return out


def sites(path):
    return [k for _, _, k in _calls(open(path).read())]


def copy(src, dst, neuter=False):
    text = open(src).read()
    lines = text.split("\n")
    by_line = {}
    for i, m, k in _calls(text):
        by_line.setdefault(i, []).append((m, k))
    for i, calls in by_line.items():
        ln = lines[i]
        for m, k in sorted(calls, key=lambda c: -c[0].start()):   # right to left: earlier offsets stay valid
            ln = ln[:m.start()] + m.group(1) + "vs_sweep_site '%s' vs_ctl_show_err" % k + ln[m.end():]
        lines[i] = ln
    s2 = "\n".join(lines)
    src_lines = list(SRC_LINE.finditer(s2))
    if len(src_lines) != 1:
        print("REFUSED: %s has %d controls.sh source lines (need 1)" % (src, len(src_lines)))
        sys.exit(2)
    wrap = ('\nvs_sweep_site() { _vss_k="$1"; shift; "$@"; _vss_r=$?; '
            '[ "$_vss_r" = 0 ] || printf \'%s\\n\' "$_vss_k" >> "${VS_SWEEP_SITES:-/dev/null}"; return "$_vss_r"; }'
            '   # test_crash_sweep: the site tag (#310)')
    if neuter:
        wrap += '\nvs_ctl_show_err() { return 0; }   # test_crash_sweep: the KNOWN-BAD leg, the helper neutered (#310)'
    e = src_lines[0].end()
    open(dst, "w").write(s2[:e] + wrap + s2[e:])


def callers(root):
    out = []
    td = os.path.join(root, "tests")
    for f in sorted(os.listdir(td)):
        if f.endswith(".sh") and not f.startswith("."):
            n = len(_calls(open(os.path.join(td, f), errors="replace").read()))
            if n:
                out.append((f[:-3], n))
    return out


def declared(path):
    pat = re.compile(r"^# MUST-FIRE: (perturbed-copy|shadow-tool|known-bad): ([a-z0-9-]+) — (.+)$")
    names = []
    for ln in open(path, errors="replace"):
        if ln.startswith("#!"):
            continue
        if not ln.startswith("#"):
            break
        m = pat.match(ln.rstrip("\n"))
        if m:
            names.append(m.group(2))
    return names


def read_table(path):
    rows, exempt, probs = [], {}, []
    exempt_sites = {}
    for n, ln in enumerate(open(path), 1):
        ln = ln.rstrip("\n")
        m = re.match(r"^# EXEMPT: ([A-Za-z0-9_]+) — (.+)$", ln)
        if m:
            exempt[m.group(1)] = m.group(2)
            continue
        m = re.match(r"^# EXEMPT-SITE: ([A-Za-z0-9_]+) (\S+) — (.+)$", ln)
        if m:
            exempt_sites[(m.group(1), m.group(2))] = m.group(3)
            continue
        if not ln or ln.startswith("#"):
            continue
        t = ln.split("\t")
        if t == COLS:
            continue
        if len(t) != len(COLS):
            probs.append("line %d: %d columns, need %d" % (n, len(t), len(COLS)))
            continue
        r = dict(zip(COLS, t))
        r["line"] = n
        rows.append(r)
    return rows, exempt, exempt_sites, probs


def check(root, table):
    rows, exempt, exempt_sites, probs = read_table(table)
    live = {g: set(sites(os.path.join(root, "tests", g + ".sh"))) for g, _ in callers(root)}
    covered = {}
    for r in rows:
        where = "line %d (%s %s)" % (r["line"], r["gate"], r["mode"])
        gp = os.path.join(root, "tests", r["gate"] + ".sh")
        if not os.path.isfile(gp):
            probs.append("%s: no gate tests/%s.sh" % (where, r["gate"]))
            continue
        if r["mode"] != "PLAIN" and r["mode"] not in declared(gp):
            probs.append("%s: mode %s is not declared by the gate" % (where, r["mode"]))
        if r["tier"] not in TIERS:
            probs.append("%s: tier %r (one of %s)" % (where, r["tier"], ", ".join(sorted(TIERS))))
        if r["kind"] not in ("py", "sh", "pyx"):
            probs.append("%s: kind %r (py|sh|pyx)" % (where, r["kind"]))
        if not r["nth"].isdigit() or int(r["nth"]) < 1:
            probs.append("%s: nth %r (an integer >= 1)" % (where, r["nth"]))
        try:
            re.compile(r["ere"])
        except re.error as e:
            probs.append("%s: ere does not compile (%s)" % (where, e))
        if r["fx"] not in FX_OK:
            probs.append("%s: fx %r (one of %s)" % (where, r["fx"], ", ".join(sorted(FX_OK))))
        if r["kb"] not in KB_OK:
            probs.append("%s: kb %r (one of %s)" % (where, r["kb"], ", ".join(sorted(KB_OK))))
        if (r["mode"] == "PLAIN") != (r["fx"] == "FAIL"):
            probs.append("%s: a PLAIN row expects FAIL and a mode row DIED/UNJUDGED (got %s)" % (where, r["fx"]))
        if r["site"] != "-":
            if r["site"] not in live.get(r["gate"], set()):
                probs.append("%s: site %s is not a call site of the gate (a moved or removed call: re-sweep)" % (where, r["site"]))
            if r["kb"] == "-" and not r["note"].strip():
                probs.append("%s: a site row with no known-bad leg (kb -) must say why in its note (the crash surfaces with the helper neutered too)" % where)
            covered.setdefault(r["gate"], set()).add(r["site"])
    for g, ks in sorted(live.items()):
        if g in exempt:
            continue
        for k in sorted(ks - covered.get(g, set())):
            if (g, k) in exempt_sites:
                continue
            probs.append("UNCOVERED %s %s: no row proves this call site (add one, or an `# EXEMPT: %s — why` line)" % (g, k, g))
    for g in sorted(exempt):
        if g not in live:
            probs.append("EXEMPT %s names no caller (a stale exemption)" % g)
    for (g, k) in sorted(exempt_sites):
        if k not in live.get(g, set()):
            probs.append("EXEMPT-SITE %s %s is not a call site of the gate (a stale exemption)" % (g, k))
        elif k in covered.get(g, set()):
            probs.append("EXEMPT-SITE %s %s is covered by a row too (drop the exemption)" % (g, k))
    for p in probs:
        print("PROBLEM: " + p)
    print("crash_sweep check: %d caller(s), %d site(s), %d row(s), %d exempt gate(s), %d exempt site(s), %d problem(s)"
          % (len(live), sum(len(v) for v in live.values()), len(rows), len(exempt), len(exempt_sites), len(probs)))
    return 1 if probs else 0


def main(argv):
    root = os.environ.get("CRASH_SWEEP_ROOT") or os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    if not argv:
        print(__doc__)
        return 2
    cmd = argv[0]
    if cmd == "sites" and len(argv) == 2:
        for k in sites(argv[1]):
            print(k)
        return 0
    if cmd == "copy" and len(argv) in (3, 4):
        copy(argv[1], argv[2], neuter=argv[3:] == ["--neuter"])
        return 0
    if cmd == "callers" and len(argv) == 1:
        for g, n in callers(root):
            print("%s\t%d" % (g, n))
        return 0
    if cmd == "check" and len(argv) == 2:
        return check(root, argv[1])
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
