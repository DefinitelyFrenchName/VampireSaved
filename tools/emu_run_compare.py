#!/usr/bin/env python3
"""emu_run_compare.py <run A> <run B> — the per-row speed of two emulator-tier runs, compared over
the rows BOTH ran and BOTH passed (14z-193, #122; promoted from the scratch script that answered it).

A run is a tests/run_all_emulator.sh run directory or its results.tsv. A row is a gate, or a control
run `<gate>@<control>` (--controls). COMMON rows are those present in both runs with verdict PASS on
both: a FAIL, SKIP or TIMEOUT row's seconds measure something else (a crash, nothing, the cap), so it
never enters a sum. Prints the row counts (each run, common, only-A, only-B), then for each (lane,
kind) the common rows' summed seconds on each side and B / A, then the total.

What this does NOT measure: wall time (two runs of different content or job mix differ in wall for
reasons that are not the host), nor per-row contention — at --jobs N a row's seconds include what ran
beside it. Say so wherever its ratio is quoted.

    python3 tools/emu_run_compare.py <run A> <run B>
    python3 tools/emu_run_compare.py --selftest      # synthetic runs with known answers
"""
import csv, os, sys, tempfile


def load(p):
    if os.path.isdir(p):
        p = os.path.join(p, "results.tsv")
    return {r["gate"]: r for r in csv.DictReader(open(p), delimiter="\t")}


def compare(a, b):
    out = []
    common = [g for g in a if g in b and a[g]["verdict"] == "PASS" and b[g]["verdict"] == "PASS"]
    out.append("A_ROWS %d B_ROWS %d COMMON_BOTH_PASS %d" % (len(a), len(b), len(common)))
    out.append("ONLY_A %d ONLY_B %d" % (len([g for g in a if g not in b]), len([g for g in b if g not in a])))
    agg = {}
    for g in common:
        k = (a[g]["lane"], "control" if "@" in g else "gate")
        s = agg.setdefault(k, [0, 0, 0])
        s[0] += 1; s[1] += int(a[g]["seconds"]); s[2] += int(b[g]["seconds"])
    ta = tb = 0
    for k in sorted(agg):
        n, sa, sb = agg[k]; ta += sa; tb += sb
        out.append("LANE %s KIND %s N %d A_S %d B_S %d RATIO_B_OVER_A %.3f" % (k[0], k[1], n, sa, sb, sb / sa if sa else 0))
    out.append("TOTAL A_S %d B_S %d RATIO_B_OVER_A %.3f" % (ta, tb, tb / ta if ta else 0))
    return out


def selftest():
    head = "gate\tlane\tscope\tverdict\tseconds\tdetail\n"
    a = head + ("g1\tmame\trelease\tPASS\t100\t\n"
                "g1@c\tmame\trelease\tPASS\t10\tcontrol honoured\n"
                "g2\tmister\trelease\tPASS\t1000\t\n"
                "g3\tmame\trelease\tPASS\t50\t\n"        # FAIL on B: never summed
                "g4\tmame\tout\tSKIP\t0\t\n"             # SKIP on A: never summed
                "g5\tprereq\trelease\tPASS\t7\t\n")      # only in A
    b = head + ("g1\tmame\trelease\tPASS\t200\t\n"
                "g1@c\tmame\trelease\tPASS\t15\tcontrol honoured\n"
                "g2\tmister\trelease\tPASS\t2500\t\n"
                "g3\tmame\trelease\tFAIL\t1\texit 1\n"
                "g4\tmame\tout\tPASS\t30\t\n"
                "g6\tmister\trelease\tTIMEOUT\t7200\tkilled\n")  # only in B
    want = ["A_ROWS 6 B_ROWS 6 COMMON_BOTH_PASS 3",
            "ONLY_A 1 ONLY_B 1",
            "LANE mame KIND control N 1 A_S 10 B_S 15 RATIO_B_OVER_A 1.500",
            "LANE mame KIND gate N 1 A_S 100 B_S 200 RATIO_B_OVER_A 2.000",
            "LANE mister KIND gate N 1 A_S 1000 B_S 2500 RATIO_B_OVER_A 2.500",
            "TOTAL A_S 1110 B_S 2715 RATIO_B_OVER_A 2.446"]
    with tempfile.TemporaryDirectory() as d:
        pa, pb = os.path.join(d, "a.tsv"), os.path.join(d, "b.tsv")
        open(pa, "w").write(a); open(pb, "w").write(b)
        got = compare(load(pa), load(pb))
    ok = got == want
    for w, g in zip(want, got + [""] * len(want)):
        print(("  ok: " if w == g else "  FAIL: want %r got " % w) + g)
    if len(got) != len(want):
        print("  FAIL: %d lines, want %d" % (len(got), len(want)))
    print("SELFTEST PASS" if ok else "SELFTEST FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    if sys.argv[1:] == ["--selftest"]:
        sys.exit(selftest())
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    print("\n".join(compare(load(sys.argv[1]), load(sys.argv[2]))))
