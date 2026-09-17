#!/usr/bin/env python3
"""select_paths.py — the REAL cursor path to any select cell, for either player,
on any decoded wheel (GitHub #151 step 3, 14z-161).

Why: the early-window pick poke ([VSP-123]) lands AFTER the select confirm, so
a poked leg carries the CURSOR character's confirm-time latch (`+0x3BD`,
`+0x3C2`, `+0x3E0`; `tests/audit_forced_pick_fidelity.sh`). A real cursor path
has no such artifact by construction. This tool turns a decoded TABLE B
(`tools/select_wheel.py --json`) into the shortest press sequence from each
player's DEFAULT cell to the wanted cell — cell index IS character id
(`docs/game/atlas/select_screen.md`).

Default cells (measured, 14z-161): P1 starts on `0x01`; P2 starts on `0x05` —
the one start from which the four P2 paths measured in 14z-160 (Victor R,R;
Phobos L,L; Pyron L,L,UL; Donovan R,R,R on vsav2) all resolve, with no
mirroring. `--check` re-derives the 14z-160 paths on the vsav2 wheel and the
merged-wheel P1 paths measured on the build, and fails if any differ.

Usage:
  select_paths.py <wheel.json> --cell 10 [--player 1|2]        # one path
  select_paths.py <wheel.json> --all                           # every navigable cell, both players
  select_paths.py <wheel.json> --resolve 1 "R R"               # walk a path, print the cell
  select_paths.py <wheel.json> --rpl-prologue 1 10 [--p2 03] [--start 1100 --period 20]
                                                              # the replay lines that replace a
                                                              # rig's pre-confirm cursor lines
  select_paths.py <vsav2 wheel.json> --check
"""
import argparse, json, sys
from collections import deque

DIRS = ["R", "L", "D", "U", "DR", "DL", "UR", "UL"]     # TABLE B column order
START = {1: 0x01, 2: 0x05}


def load(path):
    w = json.load(open(path))
    return w["table_b"]


def step(tb, cell, mv):
    return tb[cell][DIRS.index(mv)]


def resolve(tb, start, path):
    c = start
    for m in path:
        c = step(tb, c, m)
    return c


def shortest(tb, start, goal):
    """BFS over TABLE B; cardinal moves first so ties prefer R/L/D/U."""
    if start == goal:
        return []
    prev = {start: None}
    q = deque([start])
    while q:
        c = q.popleft()
        for mv in DIRS:
            n = tb[c][DIRS.index(mv)]
            if n == 0xFF or n in prev:
                continue
            prev[n] = (c, mv)
            if n == goal:
                out = []
                while prev[n] is not None:
                    c0, m0 = prev[n]
                    out.append(m0); n = c0
                return out[::-1]
            q.append(n)
    return None


def navigable(tb):
    seen = set()
    for s in START.values():
        q = deque([s]); seen.add(s)
        while q:
            c = q.popleft()
            for n in tb[c]:
                if n != 0xFF and n not in seen:
                    seen.add(n); q.append(n)
    return sorted(seen)


def prologue_lines(tb, p1, p2, start=1100, period=20, confirm=(1300, 1360)):
    """Replay lines for both cursors, then the two confirms (P1 at confirm[0],
    P2 at confirm[1]) — the shape every naming/judge rig uses."""
    out = []
    for player, goal in ((1, p1), (2, p2)):
        if goal is None:
            continue
        path = shortest(tb, START[player], goal)
        if path is None:
            raise SystemExit(f"FAIL: cell {goal:#x} is unreachable for P{player}")
        t = start + (4 if player == 2 else 0)
        for m in path:
            out.append(f"{t}-{t + 2} p{player}={m}"); t += period
        if t - period + 2 >= confirm[player - 1]:
            raise SystemExit(f"FAIL: P{player}'s path ({len(path)} moves) does not fit before its confirm")
    out.append(f"{confirm[0]}-{confirm[0] + 2} p1=1")
    out.append(f"{confirm[1]}-{confirm[1] + 2} p2=1")
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("wheel")
    ap.add_argument("--cell", type=lambda s: int(s, 16))
    ap.add_argument("--player", type=int, default=1, choices=(1, 2))
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--resolve", nargs=2, metavar=("PLAYER", "PATH"))
    ap.add_argument("--rpl-prologue", nargs=2, metavar=("P1_CELL", "P2_CELL"))
    ap.add_argument("--start", type=int, default=1100)
    ap.add_argument("--period", type=int, default=20)
    ap.add_argument("--check", action="store_true")
    a = ap.parse_args()
    tb = load(a.wheel)
    if a.check:
        want = {(1, 0x10): "L L L", (1, 0x11): "R R R", (1, 0x13): "R R",
                (2, 0x03): "R R", (2, 0x10): "L L", (2, 0x11): "L L UL", (2, 0x13): "R R R"}
        bad = 0
        for (pl, cell), path in want.items():
            got = resolve(tb, START[pl], path.split())
            s = shortest(tb, START[pl], cell)
            print(f"  P{pl} {path:8s} -> {got:#04x} (want {cell:#04x}); shortest {' '.join(s) if s else None} ({len(s) if s else '-'} moves)")
            if got != cell or s is None or len(s) > len(path.split()):
                bad += 1
        if bad:
            print("FAIL: select_paths --check"); sys.exit(1)
        print("PASS: select_paths --check (the 14z-160 paths resolve and are shortest)")
        return
    if a.resolve:
        pl = int(a.resolve[0])
        print(f"{resolve(tb, START[pl], a.resolve[1].split()):#04x}")
        return
    if a.rpl_prologue:
        p1 = int(a.rpl_prologue[0], 16) if a.rpl_prologue[0] != "-" else None
        p2 = int(a.rpl_prologue[1], 16) if a.rpl_prologue[1] != "-" else None
        print("\n".join(prologue_lines(tb, p1, p2, a.start, a.period)))
        return
    cells = navigable(tb) if a.all else [a.cell]
    players = (1, 2) if a.all else (a.player,)
    for pl in players:
        for c in cells:
            if c is None:
                continue
            p = shortest(tb, START[pl], c)
            print(f"P{pl} {c:#04x}: {' '.join(p) if p is not None else 'UNREACHABLE'}")


if __name__ == "__main__":
    main()
