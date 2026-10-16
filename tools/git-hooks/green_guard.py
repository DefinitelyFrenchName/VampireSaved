#!/usr/bin/env python3
"""green_guard.py — THE DETERMINISTIC GREEN GUARD (GitHub #290, ruled 2026-10-16, 14z-203; DECISIONS_HISTORY.md
"Ruled 2026-10-16 (14z-203) — #290: the green guard sits at the commit, with a light push check on the tip").

WHAT: no commit, and no push of a tip, whose exact tree has no strict GREEN run of the whole static tier with ROMDIR
  set. The class it holds (#288's one recurring real catch of the procedure check): a red tier read as green, a close
  tier called green, a commit made without its tier (rule-checker runs 2026-10-13-1016, 2026-10-13-1028,
  2026-10-15-1091).
HOW: tests/run_all_static.sh writes, at its end, its scope and verdict into its results file and calls `record`, which
  appends one row to the index (<git common dir>/green_index.tsv). The pre-commit hook calls `check-commit` (the tree is `git write-tree` of
  the index, what the commit will hold); the pre-push hook calls `check-push` (the tree of each pushed TIP only, read
  from the hook's stdin). A row COUNTS when: verdict GREEN, strict 1, tier all, romdir set, cadence session, freeze or
  release, and its tree is the tree asked about. Any --exec-controls and --confirm form counts (the maintainer: "Also
  confirm without controls").
EXPECTS: exit 0 to allow, 1 to refuse (the reason on stderr names the tree, the newest row for it and the command that
  makes one).
OVERRIDE: the maintainer's own `! git commit --no-verify` / `! git push --no-verify`. There is no override file or
  variable on purpose.
NOT HELD: a commit git makes without the pre-commit hook (a clean merge, cherry-pick, rebase, revert, --no-verify;
  measured 2026-10-16, build/agent203/t290/hook_fire_probe.txt) unless it is the pushed tip; a row written by hand
  into the index (the guard holds a misread verdict, not a forged one); the emulator tier.
MUST-FIRE: tests/test_green_guard.sh — its controls run a PATCHED COPY of this file (the GUARD-TREE and GUARD-SCOPE
  lines), never a switch read here: an environment switch in the guard would be a bypass.

Edit-locked with the other git hooks (ruled Q4, "Lock them (Recommended)").
"""
import os
import subprocess
import sys
import time

FIELDS = ("tree", "verdict", "strict", "tier", "romdir", "cadence", "exec_controls", "results", "utc")
COUNTED_CADENCES = ("session", "freeze", "release")
ZERO = "0" * 40
MAKE_ONE = ("ROMDIR=... tests/run_on_snapshot.sh --commit <a commit of this tree> -- tests/run_all_static.sh --strict "
            "--exec-controls none   (or --strict --confirm <newest results.tsv>, with or without --exec-controls none)")


def git(*args, cwd=None):
    return subprocess.run(("git",) + args, cwd=cwd, check=True, capture_output=True, text=True).stdout.strip()


def index_path(root):
    # IN THE GIT DIRECTORY, not under build/ (14z-203): the index changes with every run, and under build/ it matched
    # the R6 templates of tools/static_confirm.py (`build/$b`), so every --confirm re-ran the gates holding one. It is
    # per-clone state, like the hooks, and never part of a tree.
    return os.path.join(git("rev-parse", "--path-format=absolute", "--git-common-dir", cwd=root), "green_index.tsv")


def rows(path):
    out = []
    try:
        with open(path) as f:
            for line in f:
                if line.startswith("#") or not line.strip():
                    continue
                parts = line.rstrip("\n").split("\t")
                if len(parts) == len(FIELDS):
                    out.append(dict(zip(FIELDS, parts)))
    except FileNotFoundError:
        pass
    return out


def counts(row):
    """-> None when the row counts, else the reason it does not."""
    bad = [k for k, want in (("verdict", "GREEN"), ("strict", "1"), ("tier", "all"), ("romdir", "set"))   # GUARD-SCOPE
           if row[k] != want]
    if row["cadence"] not in COUNTED_CADENCES:
        bad.append("cadence")
    return None if not bad else "its " + ", ".join(f"{k} is {row[k]!r}" for k in bad)


def judge(tree, all_rows):
    """-> (ok, message)."""
    mine = [r for r in all_rows if r["tree"] == tree]   # GUARD-TREE
    for r in reversed(mine):
        if counts(r) is None:
            return True, f"green guard: tree {tree[:12]} has a strict GREEN run of the whole tier ({r['results']}, {r['utc']})"
    if mine:
        r = mine[-1]
        why = f"its newest run ({r['results']}, {r['utc']}) does not count: {counts(r)}"
    else:
        why = "no run of the static tier was recorded at this tree"
    return False, f"green guard: REFUSED — tree {tree} has no strict GREEN run of the whole tier with ROMDIR set; {why}.\n  Make one: {MAKE_ONE}"


def check_commit(root):
    tree = git("write-tree", cwd=root)
    ok, msg = judge(tree, rows(index_path(root)))
    print(msg, file=sys.stderr)
    return 0 if ok else 1


def check_push(root, stdin):
    all_rows = rows(index_path(root))
    rc = 0
    for line in stdin.read().splitlines():
        parts = line.split()
        if len(parts) != 4 or parts[1] == ZERO:     # a deletion pushes no tree
            continue
        tree = git("rev-parse", parts[1] + "^{tree}", cwd=root)
        ok, msg = judge(tree, all_rows)
        print(f"{parts[0]} -> {parts[2]}: {msg}", file=sys.stderr)
        rc = rc or (0 if ok else 1)
    return rc


def header(results):
    h = {}
    with open(results) as f:
        for line in f:
            if not line.startswith("# "):
                continue
            k, _, v = line[2:].rstrip("\n").partition(" ")
            h.setdefault(k, v)
    return h


def record(results, index):
    """Append the run's row; the runner calls it last. A run whose tree moved, or with no verdict, writes none."""
    h = header(results)
    missing = [k for k in ("tree", "tree_end", "verdict", "strict", "tier", "romdir", "cadence", "exec_controls") if k not in h]
    if missing:
        print(f"green guard: no index row — {results} lacks {', '.join(missing)}", file=sys.stderr)
        return 1
    if h["tree"] != h["tree_end"]:
        print(f"green guard: no index row — the tree moved during the run ({h['tree'][:12]} -> {h['tree_end'][:12]})", file=sys.stderr)
        return 0
    os.makedirs(os.path.dirname(index), exist_ok=True)
    new = not os.path.exists(index)
    with open(index, "a") as f:
        if new:
            f.write("# " + "\t".join(FIELDS) + "\n")
        f.write("\t".join((h["tree"], h["verdict"], h["strict"], h["tier"], h["romdir"], h["cadence"],
                           h["exec_controls"], os.path.abspath(results),
                           time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()))) + "\n")
    return 0


def main(argv):
    if len(argv) >= 2 and argv[1] == "check-commit":
        return check_commit(git("rev-parse", "--show-toplevel"))
    if len(argv) >= 2 and argv[1] == "check-push":
        return check_push(git("rev-parse", "--show-toplevel"), sys.stdin)
    if len(argv) == 4 and argv[1] == "record":
        return record(argv[2], argv[3])
    print("usage: green_guard.py check-commit | check-push (stdin: the pre-push lines) | record <results.tsv> <index>",
          file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
