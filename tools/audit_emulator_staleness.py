#!/usr/bin/env python3
"""audit_emulator_staleness.py — WHICH EMULATOR GATES' GREEN IS STALE, and is any
row's runtime eating its cap? (GitHub #171 slices Q4 and Q5, ruled 2026-09-24:
"NOTE at session, FAIL at freeze/release"; "Half the cap".)

  python3 tools/audit_emulator_staleness.py                    # each gate's newest row over every recorded run
  python3 tools/audit_emulator_staleness.py --run build/emu_sweep_X   # one run
  python3 tools/audit_emulator_staleness.py --cadence freeze   # a stale gate is a FAIL, not a NOTE
  python3 tools/audit_emulator_staleness.py --names            # stale gate names only, one per line
                                                               # (what run_all_emulator.sh --stale runs)
  python3 tools/audit_emulator_staleness.py --root DIR --repo DIR   # over a copy (the gate's controls)

WHAT IT READS. A run directory written by tests/run_all_emulator.sh: `results.tsv` (one
row per gate and per control, `gate lane scope verdict seconds detail`) and `commit.txt`
(the HEAD the run was taken on, first line; the dirty tracked paths after it). A run
without `commit.txt` predates this tool and is skipped.

THE RUN OF RECORD IS PER GATE (14z-192, GitHub #211). By default every recorded run
under build/ is read, oldest first by the mtime of its `results.tsv`, and each gate (and
each control row) keeps its NEWEST row, judged against THAT run's commit. Until 14z-192
the newest run DIRECTORY was the run of record for every gate: a two-gate `--stale` re-run
then hid every other gate's staleness, and a run that selected NO gate (an empty
`results.tsv`, printed GREEN) hid them all. A run with no rows now contributes nothing.
`--run DIR` still judges one run alone.

STALENESS. For every gate that PASSED in that run, the paths its `# FOLLOWS:` header
declares (read by tools/gate_follows.py — the declaration, its own script and
tests/ci_emulator.tsv) are diffed against the recorded commit: `git diff --name-only
<commit>` (tracked changes since, committed or in the working tree) plus untracked files
under a declared prefix. A gate with a moved path is STALE: its green describes a tree
that no longer exists. An UNDECLARED gate cannot be judged and is named as such — at
freeze/release cadence that is a FAIL too, because the slice's census makes declaring
the norm.

THE VERDICT BY CADENCE (the ruling): at `session` cadence a stale list is a NOTE — the
information a session acts on (`run_all_emulator.sh --stale` re-runs exactly those) —
and the exit is 0; at `freeze` or `release` cadence it is a FAIL (exit 1), because a
freeze or a release runs the tier on the commit it builds from, so a stale gate there
means the run was not on the commit it should have been.

HEADROOM (Q5, every cadence). Each row's `seconds` against its cap — the registry row's
7th column, else the runner's default 5,400 s; a control row `<gate>@<name>` shares its
gate's cap — and any row AT OR ABOVE HALF its cap FAILS: the M19 release run's own
contention roughly halved a 300 s control's headroom, and 0.5 is where a measured
number stops being a safe cap. The figure the ruling was measured on: max ratio 0.38.

Exit 0 = nothing stale at session cadence (stale gates NOTEd) and every row under half
its cap; exit 1 = a FAIL as above; exit 2 = no run of record.
"""
import argparse, bisect, glob, os, subprocess, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gate_follows as gf

DEFAULT_CAP = 5400
HEADROOM = 0.5


def git(repo, *args):
    r = subprocess.run(["git", "-C", repo, *args], capture_output=True, text=True)
    return r.stdout


def recorded_runs(root):
    """Every run directory under build/ carrying commit.txt and results.tsv, oldest first
    by the mtime of results.tsv."""
    cands = []
    for d in glob.glob(os.path.join(root, "build", "emu_*")):
        if os.path.isfile(os.path.join(d, "commit.txt")) and os.path.isfile(os.path.join(d, "results.tsv")):
            cands.append((os.path.getmtime(os.path.join(d, "results.tsv")), d))
    return [d for _, d in sorted(cands)]


def newest_rows(root):
    """-> ({row gate: row with 'run' and 'commit'}, runs read). Each gate's NEWEST row over
    every recorded run (#211); a run with no rows, or no commit, contributes nothing."""
    best, runs = {}, recorded_runs(root)
    for d in runs:
        commit, dirty, rows = read_run(d)
        if not commit:
            continue
        for r in rows:
            best[r["gate"]] = dict(r, run=d, commit=commit)
    return best, runs


def read_run(run):
    commit_lines = open(os.path.join(run, "commit.txt"), encoding="utf-8").read().splitlines()
    commit = commit_lines[0].split()[0] if commit_lines and commit_lines[0].strip() else ""
    dirty = [l.strip() for l in commit_lines[1:] if l.strip()]
    rows = []
    for i, line in enumerate(open(os.path.join(run, "results.tsv"), encoding="utf-8")):
        f = line.rstrip("\n").split("\t")
        if i == 0 and f[0] == "gate":
            continue
        if len(f) < 5:
            continue
        rows.append({"gate": f[0], "lane": f[1], "scope": f[2], "verdict": f[3],
                     "seconds": f[4], "detail": f[5] if len(f) > 5 else ""})
    return commit, dirty, rows


_UNTRACKED = {}   # repo -> (tracked paths changed in the working tree vs HEAD, untracked files)


def moved_paths(repo, commit):
    """Tracked paths that differ between <commit> and the working tree, plus untracked files
    (listed once per repository: they do not depend on the commit, and build/ makes the
    listing the slow half when several commits are judged — #211)."""
    if not git(repo, "rev-parse", "--verify", f"{commit}^{{commit}}").strip():
        return None
    # <commit> -> working tree as (<commit> -> HEAD) | (HEAD -> working tree): the tree
    # diff is cheap and the working-tree half is taken once (~6 s each against this
    # tree's working tree, 5 commits at 14z-192). A superset of the direct diff — a path
    # changed after <commit> and changed back in the working tree is reported, never missed.
    changed = set(l for l in git(repo, "diff", "--name-only", commit, "HEAD").splitlines() if l)
    if repo not in _UNTRACKED:
        wt = set(l for l in git(repo, "diff", "--name-only", "HEAD").splitlines() if l)
        un = set(l for l in git(repo, "ls-files", "--others", "--exclude-standard").splitlines() if l)
        _UNTRACKED[repo] = (wt, un)
    wt, un = _UNTRACKED[repo]
    return changed | wt, un


def stale_gates(root, repo, commit, rows):
    """-> (stale: {gate: [moved paths]}, undeclared: [gate], passed: [gate], unknown: [gate]).
    A row carrying its own 'commit' (newest_rows) is judged against it; otherwise against
    `commit`. `unknown` names passed gates whose recorded commit is not in the repository."""
    moved, pools = {}, {}
    stale, undeclared, passed, unknown = {}, [], [], []
    for r in rows:
        if "@" in r["gate"] or r["verdict"] != "PASS":
            continue
        g = r["gate"]
        passed.append(g)
        c = r.get("commit") or commit
        if c not in moved:
            moved[c] = moved_paths(repo, c)
        if moved[c] is None:
            unknown.append(g)
            continue
        changed, untracked = moved[c]
        if c not in pools:
            allp = changed | untracked
            pools[c] = (sorted(allp), allp, {})
        p = os.path.join(root, f"tests/{g}.sh")
        if not os.path.exists(p):
            undeclared.append(g)
            continue
        toks, problems = gf.declared(open(p, encoding="utf-8", errors="replace").read())
        if problems:
            undeclared.append(g)
            continue
        prefixes = list(toks) + [f"tests/{g}.sh"] + list(gf.IMPLIED)
        hits = sorted(_covered_hits(pools[c], prefixes))
        if hits:
            stale[g] = hits
    return stale, undeclared, passed, unknown


def _covered_hits(pool, prefixes):
    """The paths of `pool` that gf.covered() accepts for `prefixes` — the same rule (a path
    starting with a prefix, or equal to it without its trailing slash), by bisection on the
    sorted list, per prefix cached: a linear scan of 50,897 untracked paths per gate took
    ~50 s over 189 gates (#211)."""
    srt, allp, cache = pool
    out = set()
    for p in prefixes:
        if p not in cache:
            got = set()
            i = bisect.bisect_left(srt, p)
            while i < len(srt) and srt[i].startswith(p):
                got.add(srt[i]); i += 1
            bare = p.rstrip("/")
            if bare in allp:
                got.add(bare)
            cache[p] = got
        out |= cache[p]
    return out


def headroom(root, rows):
    """-> [(row gate, seconds, cap, ratio)] for rows at or above HEADROOM of their cap."""
    reg = gf.registry_rows(root)
    over = []
    for r in rows:
        base = r["gate"].split("@")[0]
        cap_s = reg.get(base, {}).get("timeout", "")
        try:
            cap = int(cap_s) if cap_s and cap_s != "-" else DEFAULT_CAP
        except ValueError:
            cap = DEFAULT_CAP
        try:
            sec = float(r["seconds"])
        except ValueError:
            continue
        if cap > 0 and sec / cap >= HEADROOM:
            over.append((r["gate"], sec, cap, sec / cap))
    return over


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    ap.add_argument("--root", default=here, help="the tree whose gates and registry are read")
    ap.add_argument("--repo", default=None, help="the git repository diffed (default: --root)")
    ap.add_argument("--run", default=None, help="one run directory (default: each gate's newest row over every recorded run)")
    ap.add_argument("--cadence", default="session", choices=("session", "freeze", "release"))
    ap.add_argument("--names", action="store_true", help="print stale gate names only")
    a = ap.parse_args()
    root = a.root
    repo = a.repo or root
    if a.run:
        commit, dirty, rows = read_run(a.run)
        if not commit:
            print(f"NO RUN OF RECORD: {a.run}/commit.txt has no commit on its first line")
            return 2
        head = (f"run {a.run} on {commit[:12]}"
                f"{' (DIRTY tree: ' + str(len(dirty)) + ' tracked path(s))' if dirty else ''}")
        where = "there"
    else:
        best, runs = newest_rows(root)
        reg = gf.registry_rows(root)   # a gate the registry no longer lists is not in the tier
        rows = [r for r in best.values() if r["gate"].split("@")[0] in reg]
        commit = ""
        if not rows:
            if a.names:
                return 0
            print("NO RUN OF RECORD: no build/emu_* directory carries commit.txt and a row "
                  "(tests/run_all_emulator.sh writes it since 14z-180)")
            return 2
        nrec = len({r["run"] for r in rows})
        head = (f"each gate's newest row over {len(runs)} recorded run(s) "
                f"({nrec} still the newest for some gate; newest {runs[-1]})")
        where = "in their newest run"
    stale, undeclared, passed, unknown = stale_gates(root, repo, commit, rows)
    if a.names:
        for g in sorted(stale):
            print(g)
        return 0

    rc = 0
    since = {r["gate"]: (r.get("commit") or commit) for r in rows}
    print(f"== emulator staleness: {head} ==")
    print(f"  {len(passed)} gate(s) PASSED {where}; cadence {a.cadence}")
    if unknown:
        print(f"  FAIL: {len(unknown)} passed gate(s) recorded on a commit not in this repository: "
              + " ".join(f"{g}({since[g][:12]})" for g in sorted(unknown)))
        rc = 1
    if stale:
        word = "FAIL" if a.cadence != "session" else "NOTE"
        print(f"  {word}: {len(stale)} stale gate(s) — a declared path moved since the commit it passed on:")
        for g in sorted(stale):
            print(f"      {g}: {' '.join(stale[g][:6])}{' …' if len(stale[g]) > 6 else ''}  (since {since[g][:12]})")
        if a.cadence != "session":
            rc = 1
        else:
            print("      re-run exactly these: tests/run_all_emulator.sh --stale")
    else:
        print(f"  ok: no passed gate has a moved input since the commit it passed on")
    if undeclared:
        word = "FAIL" if a.cadence != "session" else "NOTE"
        print(f"  {word}: {len(undeclared)} passed gate(s) without a FOLLOWS declaration cannot be judged: {' '.join(undeclared)}")
        if a.cadence != "session":
            rc = 1
    over = headroom(root, rows)
    if over:
        print(f"  FAIL: {len(over)} row(s) at or above {HEADROOM:.1f} of their cap:")
        for g, sec, cap, ratio in over:
            print(f"      {g}: {sec:.0f} s of {cap} s ({ratio:.2f})")
        rc = 1
    else:
        ratios = []
        reg = gf.registry_rows(root)
        for r in rows:
            base = r["gate"].split("@")[0]
            cap_s = reg.get(base, {}).get("timeout", "")
            try:
                cap = int(cap_s) if cap_s and cap_s != "-" else DEFAULT_CAP
                ratios.append(float(r["seconds"]) / cap)
            except ValueError:
                pass
        print(f"  ok: every row under half its cap (max ratio {max(ratios):.2f} over {len(ratios)} rows)" if ratios
              else "  ok: no timed rows")
    print("PASS" if rc == 0 else "FAIL")
    return rc


if __name__ == "__main__":
    sys.exit(main())
