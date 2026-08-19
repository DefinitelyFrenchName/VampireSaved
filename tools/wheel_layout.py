#!/usr/bin/env python3
"""wheel_layout.py — turn measured cell positions into a TABLE B proposal.

The select wheel's adjacency is HAND-TUNED: the best geometric model
reproduces only 100/128 of Capcom's shipped transitions
(docs/game/atlas/select_screen.md). So this tool does NOT generate a wheel and
hand it to the build. It:

  1. maps positions from a CAPTURE's pixel frame into the arcade frame, by
     least-squares affine fit against the 16 cells whose arcade positions
     are already measured (`tools/wheel_positions.py`);
  2. DRAFTS adjacency for the new cells geometrically, clearly labelled as
     a draft;
  3. lets every direction be overridden by hand;
  4. VALIDATES the result the way the engine will read it, and prints the
     exact byte diff against vanilla.

Steps 1 and 4 are the load-bearing ones. Step 2 is a starting point a human
corrects — a generated table would be plausibly wrong in exactly the way
only playtesting catches.

Usage:
  # fit a capture's pixel coordinates into the arcade frame
  wheel_layout.py fit --refs refs.json

  # draft + validate a proposed layout, and emit the byte diff
  wheel_layout.py propose --data <vsavj_data.bin> --layout layout.json

refs.json   {"00": [px,py], "01": [px,py], ...}  — pixel coords of any
            KNOWN cells in the capture (>=3, more is better)
            plus "new": {"10": [px,py], "11": [...], "13": [...]}

layout.json {"cells": {"10": {"pos": [x,y], "adjacency": {"R": "0x11"}},
                       ...},
             "edges_in": [{"from": "0x0C", "dir": "R", "to": "0x10"}, ...]}
            `adjacency` may be partial; unspecified directions are drafted.
"""

import argparse
import json
import math
import sys

# TABLE B's address and column order come from select_wheel.wheel_facts
# (GitHub #48): this tool used to restate both as literals with no --set
# argument, so pointed at a vsav2 image it would silently have read TABLE B
# at vsavj's address (vsav2's is 0x01588E) and emitted a plausible-looking
# garbage proposal. wheel_facts also runs the KNOWN_PATHS ground truth
# (vsavj), so a wrong labelling REFUSES instead of proposing a table wired
# to the wrong stick directions. The two module globals below are BOUND in
# main() from wheel_facts; draft_adjacency/validate read them.
import select_wheel as _sw

NDIR, NCELL = _sw.NDIR, _sw.NCELL
TABLE_B = None                      # bound from wheel_facts in main()
DIR_ORDER = None                    # bound from wheel_facts in main()
DIRV = {"R": (1, 0), "L": (-1, 0), "D": (0, 1), "U": (0, -1),
        "DR": (1, 1), "DL": (-1, 1), "UR": (1, -1), "UL": (-1, -1)}

# Measured arcade-frame centres (docs/game/atlas/select_screen.md, gate section 4)
KNOWN = {
    0x00: (224, 112), 0x01: (160, 112), 0x02: (280, 80), 0x03: (192, 96),
    0x04: (304, 96), 0x05: (336, 112), 0x06: (192, 128), 0x07: (208, 80),
    0x08: (224, 144), 0x09: (272, 144), 0x0A: (304, 128), 0x0B: (248, 152),
    0x0C: (248, 96), 0x0D: (248, 128), 0x0E: (272, 112), 0x0F: (248, 64),
}
# geometric model fitted to Capcom's own table: 100/128. Draft only.
WRAP_X, SECTOR_DEG = 184, 65


def affine_fit(pairs):
    """pairs: [((px,py),(ax,ay))]. Least-squares 6-parameter affine
    px,py -> ax,ay. Solves the 3x3 normal equations per output axis.

    Affine (not similarity) on purpose: a console capture can differ from
    the arcade frame in horizontal and vertical scale independently
    (non-square pixels, 512x448 vs 384x224), and interlacing that halves
    vertical resolution is just another vertical scale factor — which is
    why a field-only deinterlace costs nothing here.
    """
    n = len(pairs)
    if n < 3:
        raise SystemExit("need >= 3 reference cells, got %d" % n)
    S = [[0.0] * 3 for _ in range(3)]
    tx = [0.0] * 3
    ty = [0.0] * 3
    for (px, py), (ax, ay) in pairs:
        v = (px, py, 1.0)
        for i in range(3):
            for j in range(3):
                S[i][j] += v[i] * v[j]
            tx[i] += v[i] * ax
            ty[i] += v[i] * ay

    def solve(M, b):
        M = [row[:] + [b[i]] for i, row in enumerate(M)]
        for c in range(3):
            p = max(range(c, 3), key=lambda r: abs(M[r][c]))
            if abs(M[p][c]) < 1e-9:
                raise SystemExit("reference points are degenerate (collinear?)")
            M[c], M[p] = M[p], M[c]
            for r in range(3):
                if r == c:
                    continue
                f = M[r][c] / M[c][c]
                for k in range(c, 4):
                    M[r][k] -= f * M[c][k]
        return [M[i][3] / M[i][i] for i in range(3)]

    return solve(S, tx), solve(S, ty)


def apply_affine(A, B, p):
    return (A[0] * p[0] + A[1] * p[1] + A[2],
            B[0] * p[0] + B[1] * p[1] + B[2])


def draft_adjacency(pos, cell):
    """Nearest cell inside each direction's sector, with horizontal wrap."""
    out = {}
    for name in DIR_ORDER:
        vx, vy = DIRV[name]
        n = math.hypot(vx, vy)
        ux, uy = vx / n, vy / n
        best = None
        for o, (ox, oy) in pos.items():
            if o == cell:
                continue
            dx = ox - pos[cell][0]
            dy = oy - pos[cell][1]
            dx = (dx + WRAP_X / 2) % WRAP_X - WRAP_X / 2
            L = math.hypot(dx, dy)
            if L == 0:
                continue
            proj = (dx * ux + dy * uy) / L
            if proj < math.cos(math.radians(SECTOR_DEG)):
                continue
            s = L / max(proj, 1e-9)
            if best is None or s < best[0]:
                best = (s, o)
        # No cell in this sector => point at SELF, never 0xFF. The engine
        # writes TABLE B's byte straight into $3(a6) AND $382(a6) with no
        # validity check (the `bmi` guards TABLE A's output, not this read),
        # so an 0xFF here is committed as character id 0xFF and indexes ~1KB
        # past every 32-entry table. Vanilla's idiom for "no move that way"
        # is self-reference, used at exactly the wheel's extremes: cell 0x0B
        # Down and cell 0x0F Up both point at themselves, and no live
        # vanilla row contains 0xFF.
        out[name] = best[1] if best else cell
    return out


def load_rows(data_path, set_name):
    """All 32 TABLE B rows + binding of TABLE_B/DIR_ORDER (GitHub #48)."""
    global TABLE_B, DIR_ORDER
    dat = open(data_path, "rb").read()
    cfg, rows, order = _sw.wheel_facts(dat, set_name)
    TABLE_B, DIR_ORDER = cfg["table_b"], order
    return rows


def validate(rows, new_cells):
    """The checks the engine's behaviour actually depends on."""
    errs, warns = [], []
    live = {c for c, r in enumerate(rows) if any(v != 0xFF for v in r)}
    # An 0xFF INSIDE a live row is committed as character id 0xFF and
    # indexes ~1KB past every 32-entry table. Vanilla never does it.
    for c in sorted(live):
        for d, v in enumerate(rows[c]):
            if v == 0xFF:
                errs.append("cell %02X %s is 0xFF in a LIVE row — the engine "
                            "would commit id 0xFF (use self-reference for "
                            "'no move', as vanilla does)" % (c, DIR_ORDER[d]))
    for c in sorted(live):
        for d, v in enumerate(rows[c]):
            if v == 0xFF:
                continue
            if v not in live:
                errs.append("cell %02X %s -> %02X, which is not a live cell"
                            % (c, DIR_ORDER[d], v))
            if v >= NCELL:
                errs.append("cell %02X %s -> %02X, outside the table"
                            % (c, DIR_ORDER[d], v))
    targets = {v for c in live for v in rows[c] if v != 0xFF}
    for c in new_cells:
        if c not in targets:
            errs.append("new cell %02X is not the target of ANY direction — "
                        "drawn but unreachable by the cursor" % c)
    # reachability from the default cell
    seen, stack = set(), [0x01]
    while stack:
        c = stack.pop()
        if c in seen or c not in live:
            continue
        seen.add(c)
        stack.extend(v for v in rows[c] if v != 0xFF)
    for c in new_cells:
        if c not in seen:
            errs.append("new cell %02X unreachable from the default cell 01"
                        % c)
    for c in new_cells:
        if c in (0x12, 0x18) or c < 0x10:
            errs.append("id %02X is RESERVED (docs/game/atlas/id_space.md)" % c)
    return errs, warns


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("mode", choices=["fit", "propose"])
    ap.add_argument("--refs")
    ap.add_argument("--data")
    ap.add_argument("--layout")
    ap.add_argument("--set", default="vsavj", choices=sorted(_sw.SETS),
                    help="which game's tables to read (GitHub #48: was "
                         "hardcoded vsavj)")
    args = ap.parse_args()

    if args.mode == "fit":
        refs = json.load(open(args.refs))
        pairs = [((refs[k][0], refs[k][1]), KNOWN[int(k, 16)])
                 for k in refs if k != "new" and int(k, 16) in KNOWN]
        A, B = affine_fit(pairs)
        res = [math.hypot(*(apply_affine(A, B, p)[i] - a[i] for i in (0, 1)))
               for p, a in pairs]
        rms = math.sqrt(sum(r * r for r in res) / len(res))
        print("affine fit from %d reference cells" % len(pairs))
        print("  x = %.4f*px + %.4f*py + %.2f" % tuple(A))
        print("  y = %.4f*px + %.4f*py + %.2f" % tuple(B))
        print("  RMS residual: %.2f arcade px  (max %.2f)"
              % (rms, max(res)))
        if rms > 4:
            print("  WARNING: residual is large — check the reference points")
        for k, p in (refs.get("new") or {}).items():
            x, y = apply_affine(A, B, p)
            print("  new cell %s -> arcade (%.1f, %.1f)" % (k, x, y))
        return 0

    rows = load_rows(args.data, args.set)
    lay = json.load(open(args.layout))
    pos = dict(KNOWN)
    new_cells = []
    for k, spec in lay["cells"].items():
        c = int(k, 16)
        pos[c] = tuple(spec["pos"])
        new_cells.append(c)

    print("proposing %d new cells: %s\n"
          % (len(new_cells), " ".join("%02X" % c for c in new_cells)))
    n_draft = n_given = 0
    before = [r[:] for r in rows]
    for k, spec in lay["cells"].items():
        c = int(k, 16)
        drafted = draft_adjacency(pos, c)
        given = {d: int(v, 16) for d, v in (spec.get("adjacency") or {}).items()}
        row = []
        for i, d in enumerate(DIR_ORDER):
            if d in given:
                row.append(given[d]); src = "given"; n_given += 1
            elif drafted[d] is not None:
                row.append(drafted[d]); src = "DRAFT"; n_draft += 1
            else:
                row.append(0xFF); src = "none"
            print("  cell %02X %-2s -> %s   (%s)"
                  % (c, d, "--" if row[-1] == 0xFF else "%02X" % row[-1], src))
        rows[c] = row
        print()
    for e in lay.get("edges_in", []):
        c, d, t = int(e["from"], 16), e["dir"], int(e["to"], 16)
        i = DIR_ORDER.index(d)
        print("  edge in: cell %02X %s : %02X -> %02X"
              % (c, d, rows[c][i], t))
        rows[c][i] = t

    errs, warns = validate(rows, new_cells)
    print("\nbyte diff against vanilla TABLE B (PRG:0x%06X):" % TABLE_B)
    n = 0
    for c in range(NCELL):
        for d in range(NDIR):
            if rows[c][d] != before[c][d]:
                print("  %06X  %02X -> %02X   (cell %02X %s)"
                      % (TABLE_B + c * NDIR + d, before[c][d], rows[c][d],
                         c, DIR_ORDER[d]))
                n += 1
    print("  %d bytes changed" % n)

    if errs:
        print("\nFAIL:")
        for e in errs:
            print("  " + e)
        return 1
    print("\nOK: every target is live, the new cells are reachable from the "
          "default cell, and no reserved id is used")
    if n_draft:
        print("NOTE: %d entries are geometric DRAFTS (the real table is "
              "hand-tuned, 100/128) — review them before building." % n_draft)
    else:
        print("All %d entries were given explicitly; nothing was drafted."
              % n_given)
    return 0


if __name__ == "__main__":
    sys.exit(main())
