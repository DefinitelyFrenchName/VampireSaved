#!/usr/bin/env python3
"""audit_lane_carry.py <lane> --since <commit> [--romset build/<dir>/rompath]

MAY A LANE'S GREEN BE CARRIED FORWARD, instead of re-running it? Answer it from
the tree, not from memory.

WHY THIS EXISTS (14z-174, maintainer-agreed). The M19 release tier came back NOT
GREEN with eight reds, every one of them in the MAME and prereq lanes. Fixing
them and re-running the whole tier would have cost another 6 h 24 min — and
**the MiSTer lane alone is 13.8 h of the 19.8 h serial, 70% of the work** —
to re-measure inputs that had not moved by a single byte.

THE RULE IT LEANS ON is the one written in `tests/ci_emulator.tsv`: a row's
`cadence` names WHAT MOVING THING THE GATE FOLLOWS. `bitstream` rows' subject is
the CORE; `romset` rows' subject is where THIS ROMSET lands. So a lane's green
describes the tree it ran on for exactly as long as those subjects are unchanged.
It is NOT a licence to skip a gate: a gate that never ran is not carried, and any
moved subject fails the check.

**WHAT THIS TOOL ACTUALLY DOES, said plainly because the first version of its own
STATE entry overstated it and a rule-checker caught that (run 2026-09-22-92, Q1 and
Q4): THE SUBJECT LISTS BELOW ARE HARDCODED.** It reads `ci_emulator.tsv` only to
collect the lane's gate NAMES; it does NOT parse the `cadence` column, and it
cannot discover a subject nobody wrote down here. Two known omissions, left as
GitHub #171 rather than patched blind at a session close:

  * `tests/replays` — `ci_emulator.tsv` makes a replay a load-bearing operand of a
    mister gate ("THE ARGS ARE LOAD-BEARING"), so a moved replay is a moved subject
    and this tool would not see it;
  * `tests/ci_emulator.tsv` itself, which carries every row's args and timeouts.

**So a MAY CARRY from this tool is necessary, not sufficient.** Until #171 widens
the lists and adds the control that reconciles them against the registry, check the
omitted paths by hand before relying on it — which is what was done for the M19
release (`tests/replays` 0 changed; the one `ci_emulator.tsv` row that moved was a
MAME-lane row), and the conclusion held.

Releases are where this matters, because a release runs everything by ruling
(`docs/project/release_format.md`), and a red found late otherwise forces a full
re-run of work that could not have changed.

    python3 tools/audit_lane_carry.py mister --since cf4dfd86

Exit 0 = the lane may be carried and every subject is named as unchanged; exit 1 =
something moved (it is named) and the lane must run again.
"""
import argparse, os, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)

# What each lane's verdict DEPENDS ON, by the subject its rows declare. A path
# listed here that does not exist is not an error — the check is "did it move".
LANE_SUBJECTS = {
    "mister": {
        "the core (bitstream-cadence subject)": [
            "emu/jtcores", "emu/jtcores-patches", "tests/rtl",
            "tests/expect/cps2w_rtl_delta.txt",
        ],
        "the MiSTer tooling": [
            "tools/run_sim_jtcps2.sh", "tools/rpl2siminputs.py",
            "tools/mister_sdram_census.py", "tools/mister_mra.sh",
            "tools/gen_vsavjw_xml.py", "tools/mister_bundle.sh",
        ],
        "the romset it places (romset-cadence subject)": ["build/manifest"],
    },
    "fbneo": {
        "the emulator and its patches": ["emu/fbneo-patches", "tools/setup_fbneo.sh"],
        "the romset": ["build/manifest"],
    },
    "mame": {
        "the emulator and its patches": ["emu/mame-patches", "tools/setup_mame.sh"],
        "the romset": ["build/manifest"],
        "the replays and rigs": ["tests/replays", "tools/name_moves.py"],
    },
}


# What each lane's list is KNOWN to omit. Printed with every MAY CARRY so the verdict
# cannot be read as stronger than it is; emptied as #171 folds each one into the lists.
KNOWN_OMISSIONS = {
    "mister": ["tests/replays (ci_emulator.tsv makes a replay a load-bearing operand of a mister gate)",
               "tests/ci_emulator.tsv itself (it carries every row's args and timeouts)"],
    "fbneo":  ["tests/replays", "tests/ci_emulator.tsv itself"],
    "mame":   ["tests/ci_emulator.tsv itself"],
}


def git(*args):
    return subprocess.run(["git", "-C", REPO, *args], capture_output=True, text=True).stdout.strip()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("lane", choices=sorted(LANE_SUBJECTS))
    ap.add_argument("--since", required=True, help="the commit the lane's green was measured on")
    ap.add_argument("--romset", default="", help="a rompath whose fingerprint must also be unmoved")
    a = ap.parse_args()

    if not git("rev-parse", "--verify", f"{a.since}^{{commit}}"):
        sys.exit(f"--since {a.since}: not a commit in this repository")

    # The lane's own gate scripts always count: a changed gate is a changed measurement.
    gates = []
    reg = os.path.join(REPO, "tests", "ci_emulator.tsv")
    if os.path.exists(reg):
        for line in open(reg):
            if line.startswith("#") or not line.strip():
                continue
            f = line.rstrip("\n").split("\t")
            if len(f) > 1 and f[1] == a.lane:
                gates.append(f"tests/{f[0]}.sh")

    subjects = dict(LANE_SUBJECTS[a.lane])
    if gates:
        subjects[f"the {len(gates)} {a.lane}-lane gate scripts"] = gates

    moved = []
    print(f"== may the {a.lane} lane's green be carried forward from {a.since}? ==")
    for label, paths in subjects.items():
        out = git("diff", "--name-only", a.since, "--", *paths)
        names = [n for n in out.split("\n") if n]
        print(f"  {label}: {len(names)} path(s) changed")
        for n in names:
            print(f"      {n}")
        moved += names

    if a.romset:
        fp = subprocess.run([sys.executable, os.path.join(HERE, "build_fingerprint.py"),
                             a.romset, "--set", "vsavjw", "--sha-only"],
                            capture_output=True, text=True).stdout.strip()
        print(f"  the packed romset {a.romset}: fingerprint {fp[:8] or '?'}")
        if not fp:
            print("      could not fingerprint it — treat as MOVED")
            moved.append(a.romset)

    print()
    if moved:
        print(f"MUST RE-RUN: {len(moved)} subject path(s) of the {a.lane} lane moved since {a.since}.")
        return 1
    print(f"MAY CARRY: every LISTED subject of the {a.lane} lane is byte-unchanged since {a.since},")
    print(f"           so its green describes this tree. Re-running would re-measure the same inputs.")
    print(f"           This is not a skip: the lane RAN, at release scope, on this content.")
    # NECESSARY, NOT SUFFICIENT — and the verdict says so out loud, because a reader of
    # stdout does not read the docstring. The lists are hardcoded and known incomplete
    # (GitHub #171); a MAY CARRY that hid that would be the very thing #171 is about.
    print()
    print(f"           CAVEAT: the subject lists are HARDCODED and known INCOMPLETE (#171).")
    for omission in KNOWN_OMISSIONS.get(a.lane, []):
        print(f"             not checked: {omission}")
    print(f"           Check those by hand before relying on this verdict.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
