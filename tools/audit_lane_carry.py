#!/usr/bin/env python3
"""audit_lane_carry.py <lane> --since <commit> [--romset build/<dir>/rompath] [--repo DIR]

MAY A LANE'S GREEN BE CARRIED FORWARD, instead of re-running it? Answer it from
the tree, not from memory.

WHY THIS EXISTS (14z-174, maintainer-agreed). The M19 release tier came back NOT
GREEN with eight reds, every one of them in the MAME and prereq lanes. Fixing
them and re-running the whole tier would have cost another 6 h 24 min — and
**the MiSTer lane alone is 13.8 h of the 19.8 h serial, 70% of the work** —
to re-measure inputs that had not moved by a single byte.

THE RULE IT LEANS ON: a gate's `# FOLLOWS:` header names the repo path prefixes its
verdict depends on (GitHub #171 slice Q3, ruled 2026-09-24 — the reader is
tools/gate_follows.py, the census and the reconciliation that keeps a declaration no
narrower than the gate's text are tests/test_gate_follows.sh). A lane's SUBJECTS are
DERIVED: the union of its gates' declarations, plus every one of its gate scripts and
tests/ci_emulator.tsv (the registry carries each row's args and timeout). So a lane's
green describes the tree it ran on for exactly as long as those subjects are
unchanged. It is NOT a licence to skip a gate: a gate that never ran is not carried,
and any moved subject fails the check.

WHAT THE FIRST VERSION WAS, said plainly because a rule-checker caught its STATE entry
overstating it (run 2026-09-22-92, Q1 and Q4): the subject lists were HARDCODED per
lane, could not discover a subject nobody wrote down, and printed two known omissions
(`tests/replays`, the registry itself) with every MAY CARRY. This version deletes those
lists: the declarations are the subjects, and a gate WITHOUT a declaration makes the
verdict MUST RE-RUN by construction — its subjects cannot be derived, so its green
cannot be carried. That is the control the ticket asked for.

Releases are where this matters, because a release runs everything by ruling
(`docs/project/release_format.md`), and a red found late otherwise forces a full
re-run of work that could not have changed.

    python3 tools/audit_lane_carry.py mister --since cf4dfd86

Exit 0 = the lane may be carried and every derived subject is named as unchanged;
exit 1 = something moved (it is named), or a gate of the lane declares nothing, and
the lane must run again.
"""
import argparse, os, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import gate_follows as gf

LANES = ("prereq", "mame", "fbneo", "mister")


def git(repo, *args):
    return subprocess.run(["git", "-C", repo, *args], capture_output=True, text=True).stdout.strip()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("lane", choices=LANES)
    ap.add_argument("--since", required=True, help="the commit the lane's green was measured on")
    ap.add_argument("--romset", default="", help="a rompath whose fingerprint must also be unmoved")
    ap.add_argument("--repo", default=os.path.dirname(HERE), help="the checkout (default: this tree)")
    a = ap.parse_args()
    repo = a.repo

    if not git(repo, "rev-parse", "--verify", f"{a.since}^{{commit}}"):
        sys.exit(f"--since {a.since}: not a commit in this repository")

    subjects, undeclared = gf.lane_subjects(repo, a.lane)
    gates = [s for s in subjects if s.startswith("tests/") and s.endswith(".sh")
             and s[len("tests/"):-3] in gf.registry_rows(repo)]
    print(f"== may the {a.lane} lane's green be carried forward from {a.since}? ==")
    print(f"  subjects DERIVED from the {len(gates)} gates' # FOLLOWS: declarations: "
          f"{len(subjects)} path prefix(es), incl. the gate scripts and tests/ci_emulator.tsv")

    # Every changed path since the commit, committed or in the working tree, plus
    # untracked files; matched against the prefixes (a prefix is a string prefix, as
    # tests/ci_cadence.tsv's triggers are — `tools/gen_` covers every generator).
    changed = [l for l in git(repo, "diff", "--name-only", a.since).split("\n") if l]
    untracked = [l for l in git(repo, "ls-files", "--others", "--exclude-standard").split("\n") if l]
    moved = sorted(p for p in set(changed + untracked) if gf.covered(p, subjects))
    print(f"  {len(moved)} subject path(s) changed since {a.since}")
    for n in moved:
        print(f"      {n}")

    if a.romset:
        fp = subprocess.run([sys.executable, os.path.join(HERE, "build_fingerprint.py"),
                             a.romset, "--set", "vsavjw", "--sha-only"],
                            capture_output=True, text=True).stdout.strip()
        print(f"  the packed romset {a.romset}: fingerprint {fp[:8] or '?'}")
        if not fp:
            print("      could not fingerprint it — treat as MOVED")
            moved.append(a.romset)

    print()
    if undeclared:
        print(f"MUST RE-RUN: {len(undeclared)} gate(s) of the {a.lane} lane declare no # FOLLOWS:, so their")
        print(f"             subjects cannot be derived and their green cannot be carried: {' '.join(undeclared)}")
        return 1
    if moved:
        print(f"MUST RE-RUN: {len(moved)} subject path(s) of the {a.lane} lane moved since {a.since}.")
        return 1
    print(f"MAY CARRY: every DERIVED subject of the {a.lane} lane is byte-unchanged since {a.since},")
    print(f"           so its green describes this tree. Re-running would re-measure the same inputs.")
    print(f"           This is not a skip: the lane RAN, at release scope, on this content.")
    print(f"           The subjects are the gates' own declarations (tests/test_gate_follows.sh keeps")
    print(f"           each no narrower than its script's text); a path a gate reaches only through a")
    print(f"           tool's internals and did not declare is outside this verdict.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
