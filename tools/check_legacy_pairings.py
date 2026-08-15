#!/usr/bin/env python3
"""check_legacy_pairings.py — does a replay load the SAME CHARACTERS as vanilla?

THE QUESTION THIS ANSWERS, and why it needed asking (14z-88 -> 14z-89).
A replay whose loaded character ids equal vanilla's is LEGACY CONTENT: the
superset invariant says its work RAM must match vanilla's, and it belongs on
the masked vanilla basis (a `.masked` expectation).  A replay that loads a
tenant has no vanilla oracle and can only be self-frozen (`.sha1`).

Filenames do not answer it.  Most of the `*_don_*` replays were authored on
the SUBSTITUTION track, where select cell 0x0F was Donovan; on the current
de-substituted WIDE builds that cell is JEDAH, so they load vanilla ids and
have been legacy content for many sessions while wearing tenant names and
carrying self-frozen expectations.  That is exactly how the 14z-88 medallion
regression (replay 38, Victor vs Jedah) went green in every battery.

THE SIGNATURE IS +0x60, NOT +0x382.  The obvious field, the character id at
player-block +0x382 ($FF8782/$FF8B82), is only the char id AT SELECT: in match
the engine REASSIGNS it as the voice-flavor class, and the borrow that writes
it draws from a sound-state-fed candidate list (docs/game/atlas/ram.md, 14z-87).
Comparing it across a whole run would call legacy pairings "tenant" on voice
noise.  So the verdict rides on +0x60.l ($FF8460/$FF8860), the per-character
hitbox-data base — a ROM pointer, constant for the whole match, and different
for every character (Demitri 0x93B6A, Victor 0x9769E).  Legacy characters are
never relocated (the superset invariant), so a legacy pairing's pointers are
identical on both legs; a tenant's point into placed data and cannot collide.
+0x382 is still parsed and REPORTED, because it is what a human reads.

PHASE TOLERANCE.  The comparison is over the ordered sequence of DISTINCT
(p1hb, p2hb) pairs, not the frame-indexed trajectory: engine hooks cost cycles,
so the build can load the same characters a frame or two later.  A frame-indexed
diff would report that as a different match.

DEAD INSTRUMENT != AGREEMENT.  A field_trace leg that produced no samples, or
no FIELDSUMMARY, is a dead run — and a dead run compares "equal" to anything.
That is refused (exit 3) rather than reported as LEGACY.

Usage:  check_legacy_pairings.py <vanilla.field> <build.field> [--name NAME]
Exit:   0 LEGACY   1 TENANT   2 NO-MATCH (neither leg ever loaded a fighter)
        3 DEAD/malformed leg (never a verdict)
"""

import argparse
import sys


def load(path):
    """-> (samples, ok) ; samples = [(frame, {name: value})], ok = summary seen."""
    samples, ok = [], False
    try:
        fh = open(path)
    except OSError as e:
        print("DEAD: cannot read %s (%s)" % (path, e))
        return [], False
    with fh:
        for line in fh:
            line = line.strip()
            if line.startswith("FIELDSUMMARY"):
                # "FIELDSUMMARY frames=<n>" — n is the LOGGED sample count
                try:
                    ok = int(line.split("=")[1]) > 0
                except (IndexError, ValueError):
                    ok = False
                continue
            if not line.startswith("F "):
                continue
            f = line.split()
            vals = {}
            for tok in f[2:]:
                if "=" in tok:
                    k, v = tok.split("=", 1)
                    try:
                        vals[k] = int(v)
                    except ValueError:
                        pass
            samples.append((int(f[1]), vals))
    return samples, ok


def distinct_runs(samples, keys, skip_zero=True):
    """Ordered sequence of distinct value-tuples for `keys` (consecutive
    duplicates collapsed). Phase-independent by construction."""
    out = []
    for _, vals in samples:
        t = tuple(vals.get(k, 0) for k in keys)
        if skip_zero and not any(t):
            continue
        if not out or out[-1] != t:
            out.append(t)
    return out


def fmt(seq):
    return " -> ".join("(" + ",".join("%X" % v for v in t) + ")" for t in seq) or "(none)"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("vanilla")
    ap.add_argument("build")
    ap.add_argument("--name", default="")
    args = ap.parse_args()

    tag = (args.name + ": ") if args.name else ""
    va, va_ok = load(args.vanilla)
    bu, bu_ok = load(args.build)

    # Liveness first. A blind instrument and a real agreement look identical
    # (docs/GOTCHAS.md, paid for three times in 14z-71) — so an incomplete or
    # empty leg is refused, never folded into a verdict.
    dead = []
    if not va_ok or not va:
        dead.append("vanilla leg (%s)" % args.vanilla)
    if not bu_ok or not bu:
        dead.append("build leg (%s)" % args.build)
    if dead:
        print("%sDEAD — no verdict: %s" % (tag, "; ".join(dead)))
        return 3

    HB = ("p1hb", "p2hb")
    ID = ("p1id", "p2id")
    v_hb, b_hb = distinct_runs(va, HB), distinct_runs(bu, HB)
    v_id, b_id = distinct_runs(va, ID), distinct_runs(bu, ID)

    if not v_hb and not b_hb:
        # Select/attract-only replay: no fighter block was ever populated on
        # either leg. The character-id question does not apply; whether the
        # replay is tenant-affected is decided by what the SCREEN does (an
        # extended select wheel is a real difference), which this instrument
        # cannot see. Reported, never silently called legacy.
        print("%sNO-MATCH — no fighter loaded on either leg (select/attract only); "
              "ids vanilla=%s build=%s" % (tag, fmt(v_id), fmt(b_id)))
        return 2

    if v_hb == b_hb:
        print("%sLEGACY — same characters as vanilla: %s" % (tag, fmt(v_hb)))
        print("%s  ids (select-time; +0x382 is the voice class in match): "
              "vanilla=%s build=%s" % (tag, fmt(v_id), fmt(b_id)))
        return 0

    n = min(len(v_hb), len(b_hb))
    first = next((i for i in range(n) if v_hb[i] != b_hb[i]), n)
    print("%sTENANT — characters differ from vanilla (first at distinct-pair #%d: "
          "vanilla=%s build=%s)"
          % (tag, first,
             fmt([v_hb[first]]) if first < len(v_hb) else "(end)",
             fmt([b_hb[first]]) if first < len(b_hb) else "(end)"))
    print("%s  full: vanilla=%s" % (tag, fmt(v_hb)))
    print("%s        build  =%s" % (tag, fmt(b_hb)))
    return 1


if __name__ == "__main__":
    sys.exit(main())
