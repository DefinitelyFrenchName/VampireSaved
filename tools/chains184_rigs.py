#!/usr/bin/env python3
"""chains184_rigs.py — the rigs of GitHub #184: the tenants' once never-entered a2 chains with NO attack record that
a focused native rig enters, one rig per tenant (14z-186).

WHY A SEPARATE GENERATOR. Like tools/chains174_rigs.py (whose pattern this copies), #184's rigs live OUTSIDE the naming
corpus (tests/replays/chains184/): the gates that glob tests/replays/naming/ follow it. The rigs are built with
tools/name_moves.py's own machinery — the select prologue, the position pins, the HP pin, the per-event stock poke, the
round-start guard — by installing the schedules into name_moves.SCHEDULES at run time under the part name "c184".
name_moves.py itself is not edited.

THE SCHEDULES ARE MEASURED (14z-186, build/agent186/t184_notes.md, probes p1-p17 / h1-h4 / p1): each event entered its
target chain on native vs2 at the parity gates' level-6 and RNG pins, as the chain-start write (vs2 PRG:0x02713C,
tests/lua/tap_writes.lua on the fighter's +0x1C) showed. Two per chain where a timing is involved, so one timing moving
is visible without losing the chain. Events whose outcome depends on a one-frame window (the grab whiffs) are phase-
sensitive: their frames are measured IN THIS RIG, not carried from the probes.

THE ENTRY CHECK (`entry`) reads a chain START from the chain-start write, never from node landing: vs2's chain-start
routine ends in ONE `move.l a0,$1c(a6)` (PRG:0x02713C) shared by its three table entries, and the anim walker's plain
advances pass through the same instruction; so a write from that PC is a start only when its node is some chain's start
AND the node written before it is not that node's predecessor inside any chain (loop edges included) — the landing
criterion is what counted Pyron's a2:0x49 (the tail of j.LP) as "entered" in 14z-185b (docs/project/gotchas.md "LANDING
ON A CHAIN'S START NODE IS NOT ENTERING THE CHAIN"). The tap labels a write one frame early (docs/platform/gotchas.md:
a line written during frame N belongs to replay.lua's frame N+1), so an event's window is [frame-1, next frame-1).

Usage:
  python3 tools/chains184_rigs.py gen <tenant> <out.rpl> <out.json>
  python3 tools/chains184_rigs.py all <out dir>      # <tenant>_c184.rpl / .json for the three
  python3 tools/chains184_rigs.py agree <tap log> <native trace> <frames> [shift]
      -> "agree changes N matched N unmatched N end F": the TAP run and the TRACED native run played identically — every
         node change the trace samples (frame F, node n) has a tap write of n at F-1 or F (the tap labels a write one frame
         early) — and the tap run reached its END line at the rig's last frame; exit 1 otherwise. shift: the tap's frames
         read +3 (the tap-shifted perturbation, which must fail)
  python3 tools/chains184_rigs.py outcome <tenant> <native trace> <tap log> <chains dir> <rig.json> [flip]
      -> per event, P2's HP dropped or not from its first target chain's start on, against OUTCOME; exit 1 on any WRONG (flip: every expectation
         inverted, the outcome-flipped perturbation, which must fail)
  python3 tools/chains184_rigs.py target-frames <tenant> <tap log> <chains dir> <rig.json>
      -> per event "<k> <trace frame> <chain>": where its LAST positive target chain starts (the in-chain perturbations)
  python3 tools/chains184_rigs.py entry <tenant> <tap log> <chains dir> <rig.json> [wrong|swap|nofilter]
      -> rows "entry <t> <k> <name> <target> ENTERED|MISSING:<chains>"; exit 1 on any MISSING.
         wrong: every target replaced by a2:0x7f; swap: every multi-chain target reversed; nofilter: the predecessor
         filter off (every write of a start node counted) — the three must-fire perturbations of tests/audit_chains184.sh
"""
import json
import re
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import name_moves as nm  # noqa: E402

B = nm.B
PART = "c184"


def blocked(r, n=120):
    # P2 holds back (R: P2 faces LEFT) through the event, so a hit on him is BLOCKED
    return [(0, n, "R", "p2")] + r


def p2_jump(k):
    return [(k, k + 2, "U", "p2")]


def start(at=0):
    return [(at, at + 2, "S1", "sys")]


CI = nm.seq_buttons(["MP", "LP", "L", "LK", "MK"])     # Change Immortal, the button sequence

SCHED = {
    "donovan": [
        # a2:0x2b — Killshread Surf/Dive's BLOCKED rebound (a2:0x28 -> 0x2b); the HIT is the separating control (no 0x2b)
        ("j.2LK blocked", blocked(nm.air_down("LK")), 300, "near"),
        ("j.2MK blocked", blocked(nm.air_down("MK")), 300, "near"),
        ("j.2LK hit (control: no rebound)", nm.air_down("LK"), 300, "near"),
        # a2:0x3d — Change Immortal's MISS: Up held through the flight climbs over P2 to the far wall
        ("Change Immortal, Up held, P2 crouches", CI + [(20, 120, "U"), (0, 200, "D", "p2")], 400, "far"),
        ("Change Immortal, Up held, P2 stands", CI + [(20, 120, "U")], 400, "far"),
        ("Change Immortal, Down held (control: contact)", CI + [(20, 120, "D")], 400, "far"),
        # a2:0x4d — a NORMAL Foot Stab connecting off Sword Grapple (a2:0x4c -> 0x4d)
        ("Foot Stab [8LK] off Sword Grapple, press at +104", nm.hcb_cont("HP") + [(104, 106, "U4")], 320, "near"),
        ("Foot Stab [8LP] off Sword Grapple, press at +104", nm.hcb_cont("HP") + [(104, 106, "U1")], 320, "near"),
        # a2:0x59 — the Start-button taunt (standing, crouching)
        ("taunt, crouching", [(0, 30, "D")] + start(10), 300, "far"),
        ("taunt, standing", start(0), 300, "far"),
        # a2:0x42 — Sword Grapple's WHIFF: P2's jump input in a two-frame window (phase-sensitive: frames measured here)
        ("Sword Grapple [HP], P2 jumps at +8", p2_jump(8) + nm.hcb_cont("HP"), 420, "near"),
        ("Sword Grapple [HP], P2 jumps at +9", p2_jump(9) + nm.hcb_cont("HP"), 420, "near"),
    ],
    "huitzil": [
        # a2:0x3d/0x3e — Sitting Attack CONNECTING off a sweep (0x3a 0x3b 0x3c, contact, 0x3d, 0x3e); its hits take P2's white HP
        ("Sitting Attack [8LP] off 2HK, press at +50", [(0, 3, "D6"), (50, 52, "U1")], 420, "near"),
        ("Sitting Attack [8LP] off 2HK, press at +55", [(0, 3, "D6"), (55, 57, "U1")], 420, "near"),
        # a2:0x53 — the Start-button taunt
        ("taunt, crouching", [(0, 30, "D")] + start(10), 300, "far"),
        ("taunt, standing", start(0), 300, "far"),
        # a2:0x4f — Circuit Scrapper's WHIFF (phase-sensitive)
        ("Circuit Scrapper [HP], P2 jumps at +16", p2_jump(16) + nm.hcb("HP"), 420, "near"),
        ("Circuit Scrapper [HP], P2 jumps at +17", p2_jump(17) + nm.hcb("HP"), 420, "near"),
    ],
    "pyron": [
        # a2:0x1f — the Start-button taunt, and Planet Burning's WHIFF (phase-sensitive)
        ("taunt, crouching", [(0, 30, "D")] + start(10), 300, "far"),
        ("taunt, standing", start(0), 300, "far"),
        ("Planet Burning [HP], P2 jumps at +16", p2_jump(16) + nm.hcb("HP"), 420, "near"),
        ("Planet Burning [HP], P2 jumps at +16 (2)", p2_jump(16) + nm.hcb("HP"), 420, "near"),   # a one-frame window
        # (+15 and +17 do not whiff, measured 14z-186): the second event repeats +16 later in the rig
    ],
}
TARGET = {   # event name -> the a2 chain(s) the event must START on native (in order); "!" + chain = must NOT start
    ("donovan", "j.2LK blocked"): "a2:0x28 a2:0x2b", ("donovan", "j.2MK blocked"): "a2:0x29 a2:0x2b",
    ("donovan", "j.2LK hit (control: no rebound)"): "a2:0x28 !a2:0x2b",
    ("donovan", "Change Immortal, Up held, P2 crouches"): "a2:0x3b a2:0x3d",
    ("donovan", "Change Immortal, Up held, P2 stands"): "a2:0x3b a2:0x3d",
    ("donovan", "Change Immortal, Down held (control: contact)"): "a2:0x3b a2:0x3c !a2:0x3d",
    ("donovan", "Foot Stab [8LK] off Sword Grapple, press at +104"): "a2:0x41 a2:0x4c a2:0x4d",
    ("donovan", "Foot Stab [8LP] off Sword Grapple, press at +104"): "a2:0x41 a2:0x4c a2:0x4d",
    ("donovan", "taunt, crouching"): "a2:0x59", ("donovan", "taunt, standing"): "a2:0x59",
    ("donovan", "Sword Grapple [HP], P2 jumps at +8"): "a2:0x41 a2:0x42",
    ("donovan", "Sword Grapple [HP], P2 jumps at +9"): "a2:0x41 a2:0x42",
    ("huitzil", "Sitting Attack [8LP] off 2HK, press at +50"): "a2:0x3c a2:0x3d a2:0x3e",
    ("huitzil", "Sitting Attack [8LP] off 2HK, press at +55"): "a2:0x3c a2:0x3d a2:0x3e",
    ("huitzil", "taunt, crouching"): "a2:0x53", ("huitzil", "taunt, standing"): "a2:0x53",
    ("huitzil", "Circuit Scrapper [HP], P2 jumps at +16"): "a2:0x1e a2:0x4f",
    ("huitzil", "Circuit Scrapper [HP], P2 jumps at +17"): "a2:0x1e a2:0x4f",
    ("pyron", "taunt, crouching"): "a2:0x1f", ("pyron", "taunt, standing"): "a2:0x1f",
    ("pyron", "Planet Burning [HP], P2 jumps at +16"): "a2:0x1e a2:0x1f",
    ("pyron", "Planet Burning [HP], P2 jumps at +16 (2)"): "a2:0x1e a2:0x1f",
}


# THE OUTCOME each event must show on native, read from P2's two HP words in the traced native leg (rule-checker run
# 2026-09-30-469: without it a WHIFF would pass for the "hit" control): "drop" = +0x50 (p2hp) or +0x52 (p2white) falls in
# the event's window, "none" = neither falls (a block, a miss, a whiff, a taunt). BOTH words: some hits take only the
# white word (Phobos's pursuit), and a check on +0x50 alone read those as "no damage" (14z-186).
OUTCOME = {
    "donovan": {"j.2LK blocked": "none", "j.2MK blocked": "none", "j.2LK hit (control: no rebound)": "drop",
                "Change Immortal, Up held, P2 crouches": "none", "Change Immortal, Up held, P2 stands": "none",
                "Change Immortal, Down held (control: contact)": "drop",
                "Foot Stab [8LK] off Sword Grapple, press at +104": "drop", "Foot Stab [8LP] off Sword Grapple, press at +104": "drop",
                "taunt, crouching": "none", "taunt, standing": "none",
                "Sword Grapple [HP], P2 jumps at +8": "none", "Sword Grapple [HP], P2 jumps at +9": "none"},
    # Phobos's pursuit DAMAGES only P2's WHITE HP word +0x52 (259 -> 257 -> 255 -> 254 over its three hits at +85/+90/+96;
    # +0x50 stays 272 — measured 14z-186, build/agent186/hui_hp), which is why the check reads BOTH words
    "huitzil": {"Sitting Attack [8LP] off 2HK, press at +50": "drop", "Sitting Attack [8LP] off 2HK, press at +55": "drop",
                "taunt, crouching": "none", "taunt, standing": "none",
                "Circuit Scrapper [HP], P2 jumps at +16": "none", "Circuit Scrapper [HP], P2 jumps at +17": "none"},
    "pyron": {"taunt, crouching": "none", "taunt, standing": "none",
              "Planet Burning [HP], P2 jumps at +16": "none", "Planet Burning [HP], P2 jumps at +16 (2)": "none"},
}


def trace_rows(trace):
    rows = {}
    for line in open(trace):
        f = line.split()
        if len(f) >= 3 and f[0] == "F":
            rows[int(f[1])] = {k: int(v) for k, v in (kv.split("=") for kv in f[2:])}
    return rows


def _target_frame(seq, lo, hi, chain, last):
    fs = [f for f, ch in seq if lo <= f < hi and ch == chain]
    return None if not fs else (fs[-1] if last else fs[0]) + 1   # the tap labels a write one frame early


def outcome(tenant, trace, log, chains, sched, mode=""):
    """per event: did P2's HP fall in the native trace from the start of the event's FIRST positive target chain to the
    next event — the move's own outcome, not its lead-in (a Change Immortal's first button is a 5MP that can hit before
    the move starts) — against OUTCOME; mode "flip" inverts every expectation (the outcome-flipped perturbation)."""
    R = trace_rows(trace)
    seq = starts_seen(log, chains)
    ev = json.load(open(sched))["events"]
    bad = 0
    for k, e in enumerate(ev):
        lo = e["frame"]; hi = ev[k + 1]["frame"] if k + 1 < len(ev) else lo + 600
        first = [g for g in TARGET[(tenant, e["name"])].split() if not g.startswith("!")][0]
        f0 = _target_frame(seq, lo - 1, hi - 1, first, last=False)
        if f0 is None:
            got = "NO-START"
        else:
            got = "drop" if any(R[f][w] < R[f - 1][w] for f in range(f0, hi) if f in R and f - 1 in R
                                for w in ("p2hp", "p2white") if w in R[f] and w in R[f - 1]) else "none"
        want = OUTCOME[tenant][e["name"]]
        if mode == "flip":
            want = "none" if want == "drop" else "drop"
        bad += got != want
        print(f"outcome\t{tenant}\t{k}\t{e['name']}\t{want} from {first}\t" + ("AS-EXPECTED" if got == want else f"WRONG:{got}"))
    return 1 if bad else 0


def target_frames(tenant, log, chains, sched):
    """per event: the TRACE frame on which its LAST positive target chain starts (the tap's frame + 1: the tap labels a
    write one frame early) — where the in-chain perturbations of tests/audit_chains184.sh land."""
    seq = starts_seen(log, chains)
    ev = json.load(open(sched))["events"]
    for k, e in enumerate(ev):
        lo = e["frame"] - 1
        hi = ev[k + 1]["frame"] - 1 if k + 1 < len(ev) else lo + 600
        last = [g for g in TARGET[(tenant, e["name"])].split() if not g.startswith("!")][-1]
        fr = _target_frame(seq, lo, hi, last, last=True)
        print(f"{k}\t{'-' if fr is None else fr}\t{last}")
    return 0


def gen(tenant, out_rpl, out_json):
    nm.SCHEDULES[tenant][PART] = SCHED[tenant]
    nm.METER_PARTS[tenant].add(PART)   # Change Immortal spends a stock; the per-event poke keeps 9 on every tenant alike
    nm.gen(tenant, PART, out_rpl, out_json)


def starts_seen(log, chains, nofilter=False):
    """[(frame, "table:0xNN")] — the chain STARTS the tap log records (see the docstring)."""
    _, starts, _ = nm.load_graph(chains)
    pred = {}
    for tn in ("a", "a2", "b", "c", "proj"):
        for ch in json.load(open(f"{chains}/{tn}.json"))["chains"].values():
            ns = [int(n["addr"], 16) for n in ch["nodes"]]
            for i in range(1, len(ns)):
                pred.setdefault(ns[i], set()).add(ns[i - 1])
            end = str(ch.get("end", ""))
            if end.startswith("loop:"):
                pred.setdefault(int(end[5:], 16), set()).add(ns[-1])
    got, hi = [], {}
    for line in open(log):
        m = re.match(r"frame (\d+) PC ([0-9a-f]+) off ([0-9a-f]+) data ([0-9a-f]+) mask ([0-9a-f]+)", line)
        if not m or int(m.group(2), 16) != 0x2713C:
            continue
        fr, off, data, mask = int(m.group(1)), int(m.group(3), 16), int(m.group(4), 16), int(m.group(5), 16)
        w = (data >> 16) & 0xFFFF if mask & 0xFFFF0000 else data & 0xFFFF
        if off & 2 == 0:
            hi[fr] = w
        elif fr in hi:
            got.append((fr, (hi.pop(fr) << 16) | w))
    seq, prev = [], None
    for fr, n in got:
        if n in starts and (nofilter or prev not in pred.get(n, set())):
            seq.append((fr, f"{starts[n][0]}:{starts[n][1]:#04x}"))
        prev = n
    return seq


def agree(log, trace, frames, mode=""):
    writes, hi, end = set(), {}, None
    for line in open(log):
        m = re.match(r"frame (\d+) PC ([0-9a-f]+) off ([0-9a-f]+) data ([0-9a-f]+) mask ([0-9a-f]+)", line)
        if m:
            fr, off, data, mask = int(m.group(1)), int(m.group(3), 16), int(m.group(4), 16), int(m.group(5), 16)
            fr += 3 if mode == "shift" else 0
            w = (data >> 16) & 0xFFFF if mask & 0xFFFF0000 else data & 0xFFFF
            if off & 2 == 0:
                hi[fr] = w
            elif fr in hi:
                writes.add((fr, (hi.pop(fr) << 16) | w))
            continue
        e = re.match(r"END (\d+) hits", line)
        if e:
            end = int(e.group(1))
    changes = matched = 0
    prev = None
    for line in open(trace):
        f = line.split()
        if len(f) < 3 or f[0] != "F":
            continue
        fr, node = int(f[1]), int(dict(kv.split("=") for kv in f[2:])["node"])
        if prev is not None and node != prev:
            changes += 1
            matched += (fr - 1, node) in writes or (fr, node) in writes
        prev = node
    ok = changes > 0 and matched == changes and end is not None and end >= int(frames) - 1
    print(f"agree changes {changes} matched {matched} unmatched {changes - matched} end {end}")
    return 0 if ok else 1


def entry(tenant, log, chains, sched, mode=""):
    seq = starts_seen(log, chains, nofilter=(mode == "nofilter"))
    ev = json.load(open(sched))["events"]
    bad = 0
    for k, e in enumerate(ev):
        lo = e["frame"] - 1
        hi = ev[k + 1]["frame"] - 1 if k + 1 < len(ev) else lo + 600
        got = [ch for fr, ch in seq if lo <= fr < hi]
        tgt = ["a2:0x7f"] if mode == "wrong" else TARGET[(tenant, e["name"])].split()
        if mode == "swap":
            pos = [g for g in tgt if not g.startswith("!")]
            if len(pos) > 1:
                it = iter(pos[::-1]); tgt = [g if g.startswith("!") else next(it) for g in tgt]
        i, miss = 0, []
        for g in tgt:
            if g.startswith("!"):
                if g[1:] in got:
                    miss.append(g)
                continue
            j = next((n for n in range(i, len(got)) if got[n] == g), None)
            if j is None:
                miss.append(g)
            else:
                i = j + 1
        bad += bool(miss)
        print(f"entry\t{tenant}\t{k}\t{e['name']}\t{' '.join(tgt)}\t" + ("ENTERED" if not miss else "MISSING:" + ",".join(miss)))
    return 1 if bad else 0


def main(argv):
    if len(argv) in (6, 7) and argv[0] == "outcome":
        return outcome(*argv[1:])
    if len(argv) == 5 and argv[0] == "target-frames":
        return target_frames(*argv[1:])
    if len(argv) in (4, 5) and argv[0] == "agree":
        return agree(*argv[1:])
    if len(argv) in (5, 6) and argv[0] == "entry":
        return entry(*argv[1:])
    if len(argv) == 4 and argv[0] == "gen":
        gen(argv[1], argv[2], argv[3]); return 0
    if len(argv) == 2 and argv[0] == "all":
        os.makedirs(argv[1], exist_ok=True)
        for t in SCHED:
            gen(t, os.path.join(argv[1], f"{t}_{PART}.rpl"), os.path.join(argv[1], f"{t}_{PART}.json"))
        return 0
    print(__doc__.split("Usage:")[1], file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
