#!/usr/bin/env python3
"""rng_forms.py — the parity gates' verdicts under three RNG forms, compared against the gates' own 0000 pin
(GitHub #183, 14z-186). Reads the work dir tests/audit_rng_forms.sh fills:

  mp_<F>.got.tsv          audit_move_parity's per-event table (ALL=1, GOT_OUT) for form F in A, B, C
  c174_<F>/got.tsv        audit_chains174's rows (KEEP)
  c184_<F>/got.tsv        audit_chains184's rows (KEEP; absent when the gate stopped before its table)
  <gate>_<F>.log          each run's log

Form A is the gates' own pin (0000 on every frame from 2363), B a non-zero word on every frame (0100), C a seed
then free (5a5a 2363..2599). Every B/C row is compared against form A's row BY THE SAME SCRIPT ON THE SAME BUILD;
form A's move_parity table is itself compared against the frozen tests/expected/move_parity_events.tsv, so a build
or basis move cannot pass for an RNG effect.

Usage: rng_forms.py <work dir> <expected tsv> [--freeze] [--control NAME]
Prints `key<TAB>value` rows; exit 1 on a check failing or a row differing from the expectation.
"""
import argparse, collections, os, re, sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FROZEN_MP = os.path.join(REPO, "tests/expected/move_parity_events.tsv")


def mp_table(p):
    d = {}
    for l in open(p):
        if l.startswith("#") or not l.strip():
            continue
        f = l.rstrip("\n").split("\t")
        if len(f) >= 4 and f[1].isdigit():
            d[(f[0], int(f[1]))] = f[3:]          # verdict and the columns after it
    return d


def chains_table(p):
    if not os.path.exists(p):
        return None
    d = {}
    for l in open(p):
        f = l.rstrip("\n").split("\t")
        if f and f[0] == "parity" and len(f) > 4:
            d[(f[1], int(f[2]))] = f[4:]
    return d


def transitions(base, got):
    """{transition: [key, ...]} — 'same' counted, every other transition listed by key."""
    out = collections.defaultdict(list)
    for k in sorted(set(base) | set(got)):
        a, b = base.get(k), got.get(k)
        if a is not None and b is not None and a == b:
            out["same"].append(k); continue
        out[f"{a[0] if a else 'ABSENT'}->{b[0] if b else 'ABSENT'}"].append(k)
    return out


def verdict_line(log):
    v = [l.strip() for l in open(log) if re.match(r"^(PASS|FAIL)[: ]", l)]
    return v[-1] if v else "NONE"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("work"); ap.add_argument("expected")
    ap.add_argument("--freeze", action="store_true"); ap.add_argument("--control", default="")
    a = ap.parse_args()
    W, ctl = a.work, a.control
    rows, fails, fired = {}, [], {}
    def ok(m): print(f"  ok    {m}")
    def bad(m): print(f"  FAIL  {m}"); fails.append(m)

    mp = {f: mp_table(f"{W}/mp_{f}.got.tsv") for f in "ABC"}
    c174 = {f: chains_table(f"{W}/c174_{f}/got.tsv") for f in "ABC"}
    c184 = {f: chains_table(f"{W}/c184_{f}/got.tsv") for f in "ABC"}
    # --- the must-fire perturbations, applied to COPIES (in-gate) or to the real input (mode) ---
    def flip_one_ident(t):
        t = dict(t); k = next(k for k in sorted(t) if t[k][0] == "IDENT"); t[k] = ["DIFF"] + t[k][1:]; return t
    def move_one(t):
        t = dict(t); k = sorted(t)[len(t) // 2]; t[k] = ["DIFF" if t[k][0] == "IDENT" else "IDENT"] + t[k][1:]; return t
    fired["ident-flipped"] = any(k.startswith("IDENT->DIFF") for k in transitions(mp["A"], flip_one_ident(mp["B"])))
    fired["baseline-moved"] = mp_table(FROZEN_MP) != move_one(mp["A"])
    fired["form-inert"] = not [k for k in transitions(mp["A"], mp["A"]) if k != "same"]
    if ctl == "ident-flipped":
        mp["B"] = flip_one_ident(mp["B"])
    elif ctl == "baseline-moved":
        mp["A"] = move_one(mp["A"])
    elif ctl == "form-inert":
        mp["B"] = dict(mp["A"])

    print("== 1. form A — the gates' own 0000 pin — passes each gate and equals the frozen move_parity table")
    for g in ("mp", "c174", "c184"):
        v = verdict_line(f"{W}/{g}_A.log")
        (ok if v.startswith("PASS") else bad)(f"{g} under A: {v[:100]}")
    fz = mp_table(FROZEN_MP)
    same = fz == mp["A"]
    (ok if same else bad)(f"move_parity under A equals tests/expected/move_parity_events.tsv ({len(mp['A'])} rows)"
                          + ("" if same else f" — {sum(1 for k in set(fz) | set(mp['A']) if fz.get(k) != mp['A'].get(k))} rows differ"))

    print("== 2. forms B and C against form A")
    for g, tab in (("mp", mp), ("c174", c174)):
        for f in "BC":
            if tab["A"] is None or tab[f] is None:
                rows[f"{g}\t{f}\tstopped"] = "no table"; continue
            for t, ks in sorted(transitions(tab["A"], tab[f]).items()):
                rows[f"{g}\t{f}\t{t}"] = f"{len(ks)}" + ("" if t == "same" else "\t" + " ".join(f"{p}:{e}" for p, e in ks))
    for f in "BC":
        wrong = [l.strip() for l in open(f"{W}/c184_{f}.log") if "WRONG:" in l]
        rows[f"c184\t{f}\toutcome-wrong"] = f"{len(wrong)}" + ("\t" + " | ".join(w.split("\t", 1)[-1] for w in wrong) if wrong else "")
        rows[f"c184\t{f}\ttable"] = "absent" if c184[f] is None else f"{len(c184[f])} rows"
    for k in sorted(rows):
        print(f"  {k}\t{rows[k]}")

    print("== 3. the reading ruled on (#183, 2026-09-30)")
    b_new = [k for k in rows if k.startswith("mp\tB\tIDENT->") and "DIFF" in k] + \
            [k for k in rows if k.startswith("c174\tB\tIDENT->") and "DIFF" in k]
    (ok if not b_new else bad)("under B (a non-zero word every frame) no IDENT row of move_parity or chains174 turns DIFF"
                               + ("" if not b_new else f": {b_new}"))
    b_moves = sum(int(v.split("\t")[0]) for k, v in rows.items() if k.startswith("mp\tB\t") and not k.endswith("\tsame"))
    (ok if b_moves > 0 else bad)(f"under B the pin reaches the game: {b_moves} move_parity rows move")

    print("== 4. the frozen expectation")
    if a.freeze:
        with open(a.expected, "w") as fh:
            fh.write("# tests/audit_rng_forms.sh — frozen by FREEZE=1 (tools/rng_forms.py). gate<TAB>form<TAB>what<TAB>value\n")
            for k in sorted(rows):
                fh.write(f"{k}\t{rows[k]}\n")
        print(f"  FROZEN {a.expected} ({len(rows)} rows)")
    elif not os.path.exists(a.expected):
        bad(f"no expectation at {a.expected} (FREEZE=1 after review)")
    else:
        exp = {}
        for l in open(a.expected):
            if l.startswith("#") or not l.strip():
                continue
            f = l.rstrip("\n").split("\t")
            exp["\t".join(f[:3])] = "\t".join(f[3:])
        diff = [k for k in sorted(set(exp) | set(rows)) if exp.get(k) != rows.get(k)]
        for k in diff:
            bad(f"{k.replace(chr(9), ' ')}: frozen {str(exp.get(k))[:80]} got {str(rows.get(k))[:80]}")
        if not diff:
            ok(f"all {len(rows)} rows equal the frozen expectation")

    print("== 5. controls")
    for n in ("ident-flipped", "baseline-moved", "form-inert"):
        print(f"CONTROL FIRED: {n} — the perturbed copy is caught" if fired.get(n) else f"CONTROL DEAD: {n} — the perturbed copy was not caught")
        if not fired.get(n):
            fails.append(n)
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
