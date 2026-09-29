#!/usr/bin/env python3
"""static_confirm.py — WHICH STATIC-TIER GATES MUST RE-RUN AFTER A CHANGE? (14z-185b, GitHub #188,
route A, maintainer-ruled 2026-09-29: "A, backtested"; then "History for now, traced on WSL2 later").

PROVISIONAL. Not wired into tests/run_all_static.sh: route A is trusted only after the traced test
(every gate's ACTUAL reads under strace on Linux) finds no read this predictor misses. Until then
it is a measurement, and its backtest over the recorded reds is what it has.

THE PREDICTION, over-approximate by design (a wrong STALE costs a re-run; a wrong CARRIED hides a red).
A registered gate (tests/ci_portable.txt, tests/ci_static.txt) is STALE for a changed path c when:
  R1 c is a program in the gate's reach (tools/battery_reach.py's STRICT closure from tests/<gate>.sh:
     paths and imports on CODE lines — a comment runs nothing; measured 14z-185b, the non-strict set
     marked 160 of 185 gates stale for a STATE.md-only change, because comments name most tools);
  R2 a CODE line of a file in the reach names c's basename (word bounded, as battery_reach's --dirty);
  R3 a file in the reach names one of c's ancestor directories as a directory — the token followed by
     an optional `/` and then a non-path character (a quote, space, `*`, `)`, end of line), or as
     quoted components joined by commas (`"docs", "project"`);
  R4 the reach reads the whole tree (`git ls-files`, `git grep`, `git status`, `os.walk(`, `rglob(`,
     `find .`, `glob.glob(` with `**`): every change.
Otherwise the gate is CARRIED.

Usage:
  python3 tools/static_confirm.py predict --root DIR (--base COMMIT [--head COMMIT] | --changed PATH ...)
      the changed set is `git diff --name-only BASE HEAD` in DIR (HEAD defaults to the working
      tree: tracked changes plus untracked files), and/or the --changed paths; prints each STALE gate
      with its first reason, the CARRIED count, and the share of gates re-run.
  python3 tools/static_confirm.py backtest EVENTS --repo DIR
      EVENTS: `gate<TAB>base<TAB>head<TAB>extra changed paths (space-separated, or -)<TAB>note`,
      one recorded red per row. Each head is checked out in a temporary worktree; the red gate must
      be STALE. Exit 1 on any miss.
  python3 tools/static_confirm.py --selftest
      a synthetic repo of five gates, one per reader class, with known answers.
"""
import os, re, subprocess, sys, tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import battery_reach as br   # noqa: E402

WHOLE = re.compile(r"git\s+(?:ls-files|grep|status)\b|os\.walk\(|\.rglob\(|\bfind\s+\.(?:\s|$)|glob\.glob\([^)]*\*\*")
_TEXT = {}


def text(root, p):
    """a file's CODE: comment lines (`#`, `--`) and python docstrings dropped, as battery_reach's
    strict set does — a comment runs nothing and reads nothing."""
    k = (root, p)
    if k not in _TEXT:
        try:
            t = open(os.path.join(root, p), encoding="utf-8", errors="replace").read()
        except OSError:
            t = ""
        skip = br.docstring_lines(p, t)
        _TEXT[k] = "\n".join("" if (i + 1) in skip or l.strip().startswith(("#", "--")) else l
                              for i, l in enumerate(t.split("\n")))
    return _TEXT[k]


def registry(root):
    names = []
    for f in ("tests/ci_portable.txt", "tests/ci_static.txt"):
        fp = os.path.join(root, f)
        if os.path.exists(fp):
            for line in open(fp, encoding="utf-8"):
                n = line.split("#", 1)[0].strip()
                if n:
                    names.append(n)
    return names


def reach(root, gate, files):
    br.STRICT[0] = True
    br.EXTRA[:] = []
    seen, _ = br.closure(root, [f"tests/{gate}.sh"], files)
    return sorted(seen)


def dir_patterns(c):
    parts = c.split("/")[:-1]
    pats = []
    for k in range(1, len(parts) + 1):
        d = "/".join(parts[:k])
        pats.append((d, re.compile(r"(?<![\w.-])" + re.escape(d) + r"/?(?=[\"'\s*)\]]|$)", re.M)))
        if k > 1:
            joined = r"[\"']\s*,\s*[\"']".join(re.escape(x) for x in parts[:k])
            pats.append((d, re.compile(r"[\"']" + joined + r"[\"']")))
    return pats


def patterns(c):
    """-> (basename regex, [(dir, regex)]) for a changed path, compiled once per path."""
    base = os.path.basename(c)
    return (re.compile(r"(?<![\w.-])" + re.escape(base) + r"(?![\w-])") if base else None, dir_patterns(c))


def stale_reason(root, rch, blob, c, pats):
    """the first rule that makes this gate STALE for c; `blob` is the reach's texts joined (searched
    once), the file is named only on a hit."""
    if c in rch:
        return f"R1 {c} is in the reach"
    bpat, dps = pats
    tests = ([("R2", bpat, os.path.basename(c))] if bpat else []) + [("R3", rx, d) for d, rx in dps]
    for rule, rx, what in tests:
        if rx.search(blob):
            where = next((p for p in rch if rx.search(text(root, p))), "?")
            return f"R2 {where} names {what}" if rule == "R2" else f"R3 {where} reads directory {what}"
    return None


def changed_set(root, base, head, extra):
    out = set(extra)
    if base:
        args = ["git", "diff", "--name-only", base] + ([head] if head else [])
        out |= set(subprocess.run(args, cwd=root, capture_output=True, text=True, check=True).stdout.split())
        if not head:
            out |= set(subprocess.run(["git", "ls-files", "--others", "--exclude-standard"], cwd=root,
                                      capture_output=True, text=True).stdout.split())
    return sorted(out)


_REFS = {}


def _cached_refs(orig):
    def refs(root, p, files):
        k = (root, p)
        if k not in _REFS:
            _REFS[k] = orig(root, p, files)
        return _REFS[k]
    return refs


br.refs = _cached_refs(br.refs)   # one reference scan per file, shared by every gate's closure


def predict(root, changed):
    files = br.index(root, [])
    gates = registry(root)
    pats = {c: patterns(c) for c in changed}
    stale, carried = {}, []
    for g in gates:
        rch = reach(root, g, files)
        blob = "\n".join(text(root, p) for p in rch)
        why = None
        for c in changed:
            why = stale_reason(root, rch, blob, c, pats[c])
            if why:
                break
        if not why and changed and WHOLE.search(blob):
            where = next((p for p in rch if WHOLE.search(text(root, p))), "?")
            why = f"R4 {where} reads the whole tree"
        if why:
            stale[g] = why
        else:
            carried.append(g)
    return gates, stale, carried


def show(gates, stale, carried, changed):
    print(f"changed paths: {len(changed)}")
    for g, why in stale.items():
        print(f"  STALE   {g:40s} {why}")
    share = 100.0 * len(stale) / len(gates) if gates else 0.0
    print(f"stale {len(stale)} / {len(gates)} gates ({share:.1f}% re-run), carried {len(carried)}")


def backtest(events, repo):
    miss = 0
    for n, line in enumerate(open(events, encoding="utf-8"), 1):
        if not line.strip() or line.startswith("#"):
            continue
        gate, base, head, extra, note = (line.rstrip("\n").split("\t") + ["", "", "", "", ""])[:5]
        extra = [] if extra in ("", "-") else extra.split()
        with tempfile.TemporaryDirectory() as d:
            wt = os.path.join(d, "wt")
            subprocess.run(["git", "worktree", "add", "--detach", "-q", wt, head], cwd=repo, check=True)
            try:
                _TEXT.clear(); _REFS.clear()
                changed = changed_set(wt, base, head, extra)
                gates, stale, carried = predict(wt, changed)
                ok = gate in stale
                miss += not ok
                share = 100.0 * len(stale) / len(gates) if gates else 0.0
                print(f"{'CAUGHT' if ok else 'MISSED'} {gate} ({base[:8]}..{head[:8]}, {len(changed)} changed): "
                      f"{stale.get(gate, 'carried')}; re-run {len(stale)}/{len(gates)} ({share:.1f}%) — {note}")
            finally:
                subprocess.run(["git", "worktree", "remove", "--force", wt], cwd=repo)
    print(f"backtest: {'no miss' if not miss else str(miss) + ' MISSED'}")
    return 1 if miss else 0


def selftest():
    ok = True
    with tempfile.TemporaryDirectory() as root:
        def w(rel, t, x=False):
            p = os.path.join(root, rel)
            os.makedirs(os.path.dirname(p), exist_ok=True)
            open(p, "w").write(t)
            if x:
                os.chmod(p, 0o755)
        w("tests/ci_portable.txt", "g_named\ng_prog\ng_dir\ng_join\ng_whole\n")
        w("tests/g_named.sh", "#!/bin/sh\ngrep x docs/data/table.tsv\n", True)
        w("tests/g_prog.sh", "#!/bin/sh\npython3 tools/helper.py\n", True)
        w("tools/helper.py", "import sys\n")
        w("tests/g_dir.sh", "#!/bin/sh\nfor f in docs/game/*.md; do :; done\n", True)
        w("tests/g_join.sh", "#!/bin/sh\npython3 -c \"import os; os.listdir(os.path.join('x', 'docs', 'project'))\"\n", True)
        w("tests/g_whole.sh", "#!/bin/sh\ngit ls-files | wc -l\n", True)
        cases = [
            # g_join names 'docs' as a bare quoted directory: every change under docs/ is STALE for it
            # (over-approximate by design, R3 at depth 1)
            ("docs/data/table.tsv", {"g_named", "g_join", "g_whole"}),
            ("tools/helper.py", {"g_prog", "g_whole"}),
            ("docs/game/new.md", {"g_dir", "g_join", "g_whole"}),
            ("docs/project/x.md", {"g_join", "g_whole"}),
            ("STATE.md", {"g_whole"}),
            ("tests/g_named.sh", {"g_named", "g_whole"}),
        ]
        for c, want in cases:
            _TEXT.clear(); _REFS.clear()
            _, stale, _ = predict(root, [c])
            got = set(stale)
            good = got == want
            ok = ok and good
            print(f"  {'ok' if good else 'FAIL'}: {c} -> stale {sorted(got)}" + ("" if good else f", expected {sorted(want)}"))
    print("SELFTEST " + ("PASS" if ok else "FAIL"))
    return 0 if ok else 1


def main():
    a = sys.argv[1:]
    if a[:1] == ["--selftest"]:
        return selftest()
    def opt(k, many=False):
        v = [a[i + 1] for i, x in enumerate(a) if x == k]
        return v if many else (v[0] if v else None)
    if a[:1] == ["predict"] and opt("--root"):
        root = os.path.abspath(opt("--root"))
        changed = changed_set(root, opt("--base"), opt("--head"), opt("--changed", True))
        gates, stale, carried = predict(root, changed)
        show(gates, stale, carried, changed)
        return 0
    if a[:1] == ["backtest"] and len(a) >= 2 and opt("--repo"):
        return backtest(a[1], os.path.abspath(opt("--repo")))
    sys.exit(__doc__)


if __name__ == "__main__":
    sys.exit(main())
