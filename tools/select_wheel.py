#!/usr/bin/env python3
"""select_wheel.py — decode and structurally verify the character-select
cursor navigation tables.

Mechanism (re-derived 14z-60 from the consumer, NOT from a session log —
docs/atlas/select_screen.md):

  vsavj PRG:0x020A58   (vs2 twin PRG:0x01F620)
    andi.w  #$f,d2           ; d2 = joystick direction nibble
    lea     $211d4(pc),a0    ; TABLE A
    move.b  (a0,d2.w),d1     ; d1 = direction index 0-7, or $ff
    bmi     <no move>        ; $ff (negative) = illegal combination
    move.b  $3(a6),d0        ; d0 = CURRENT cursor cell
    lsl.w   #3,d0            ; *8  <-- NO MASK: the full byte indexes
    lea     $211e4(pc),a0    ; TABLE B
    lea     (a0,d0.w),a0     ; row base = TABLE_B + cell*8
    move.b  (a0,d1.w),d0     ; new cell = row[direction]
    move.b  d0,$3(a6)        ; commit cursor cell      (PRG:0x020A7C)
    move.b  d0,$382(a6)      ; commit CHARACTER ID     (PRG:0x020A80)

Both stores take the SAME value, so the wheel cell index IS the character
id. Because the row index is unmasked, TABLE B is 32 rows (0x00-0x1F) and
cells in the variant half 0x10-0x1F are addressable BY CONSTRUCTION —
vsav2 ships live rows at 0x10/0x11/0x13 (Huitzil/Pyron/Donovan) and 0x18.

VIEW: both tables are reached via `lea`/`movea.l` then `(An,Dn)`, i.e.
DATA space. They are NOT in the opcode image — reading them there yields
plausible garbage (docs/GOTCHAS.md, "PC-relative reads are PROGRAM-space;
(An)-based reads are DATA-space").

Usage:
  select_wheel.py <data_image.bin> --set vsavj [--json out.json]

  data_image.bin  DATA-space image (tools/cps2_decrypt.py --data-out)
"""

import argparse
import hashlib
import json
import sys

# Per-set table addresses. Derived from the consumer site in each set's
# OPCODE image (the two `lea`/`movea.l` operands), never by scanning for
# plausible-looking table content.
SETS = {
    "vsavj": {
        "nav_site": 0x020A58,
        "commit_cell": 0x020A7C,
        "commit_id": 0x020A80,
        "table_a": 0x0211D4,
        "table_b": 0x0211E4,
    },
    "vsav2": {
        "nav_site": 0x01F620,
        "commit_cell": 0x01F646,
        "commit_id": 0x01F64A,
        "table_a": 0x01FE2C,
        "table_b": 0x01588E,
    },
}

NCELL = 32          # rows in TABLE B (5-bit cell/char id, unmasked index)
NDIR = 8            # bytes per row
DEAD = 0xFF         # a row of $ff = unreachable cell; a $ff target = no move


def sha1_of(path):
    h = hashlib.sha1()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def decode_table_a(dat, base):
    """16-entry joystick-nibble -> direction table.

    Returns (raw bytes, {nibble: dir}, {dir: nibble}).
    """
    raw = dat[base:base + 16]
    fwd = {i: v for i, v in enumerate(raw) if v != DEAD}
    rev = {}
    for nib, d in fwd.items():
        rev.setdefault(d, nib)
    return raw, fwd, rev


def check_table_a(raw, fwd):
    """The nibble bits are {0:up, 1:down, 2:left, 3:right}; a combination
    is legal iff it is non-empty and holds no opposing pair. Assert the
    table implements exactly that, and that the 8 legal combinations map
    onto directions 0-7 bijectively."""
    errs = []
    for i in range(16):
        opposed = (i & 3) == 3 or (i & 12) == 12
        legal = i != 0 and not opposed
        got_legal = raw[i] != DEAD
        if legal != got_legal:
            errs.append("nibble %X: expected %s, table says %s (%02x)"
                        % (i, "legal" if legal else "illegal",
                           "legal" if got_legal else "illegal", raw[i]))
    if sorted(fwd.values()) != list(range(NDIR)):
        errs.append("legal entries are not a permutation of 0-7: %s"
                    % sorted(fwd.values()))
    return errs


# Nibble bit -> stick direction. NOT derivable from TABLE A: its structure
# (opposing pairs illegal) is symmetric under swapping which bit-pair is
# vertical, so the table alone cannot tell U/D from L/R. Pinned instead by
# two independently recorded cursor paths, which have a UNIQUE joint
# solution over all 8 labelings x 16 start cells (see KNOWN_PATHS).
BIT_NAMES = {0: "R", 1: "L", 2: "D", 3: "U"}

# Ground truth for the labeling above (CLAUDE.md §4: a verdict's logic is
# validated before its verdicts are trusted). Both are prior, independent
# records: tests/replays/11_pick_donovan.rpl picks Jedah from the default
# position, and docs/atlas/character_tables.md closed Aulbath with L,L,D.
DEFAULT_CELL = 0x01                      # Demitri, per both sources
KNOWN_PATHS = [
    ("UUR", 0x0F, "tests/replays/11_pick_donovan.rpl (Jedah)"),
    ("LLD", 0x09, "docs/atlas/character_tables.md (Aulbath)"),
]


def dir_names(rev):
    """Name each direction by the stick bits its nibble carries."""
    out = {}
    for d, nib in rev.items():
        out[d] = "".join(BIT_NAMES[b] for b in (3, 2, 1, 0) if nib & (1 << b))
    return out


def check_known_paths(rows, names):
    """Walk each recorded cursor path from the default cell and require the
    documented destination. This is what pins BIT_NAMES; if it fails, the
    labeling is wrong and every direction column is mislabelled."""
    inv = {n: d for d, n in names.items()}
    errs = []
    for path, want, src in KNOWN_PATHS:
        c = DEFAULT_CELL
        trail = ["%02X" % c]
        for step in path:
            c = rows[c][inv[step]]
            trail.append("%02X" % c)
        if c != want:
            errs.append("path %s from %02X gave %s, expected %02X — %s"
                        % (path, DEFAULT_CELL, "->".join(trail), want, src))
    return errs


def decode_table_b(dat, base):
    rows = []
    for c in range(NCELL):
        rows.append(list(dat[base + c * NDIR: base + (c + 1) * NDIR]))
    return rows


def analyse_table_b(rows):
    """Classify rows and check the graph.

    Three classes, because the cell byte is written from TWO places — this
    routine's navigation store, and whatever else writes $3(a6)/$382(a6)
    (the flavor/variant path):

      dead        row is all-$ff: not a cursor position at all.
      navigable   live row, reachable from the first live cell by walking
                  directions — the wheel proper.
      entry-only  live row that no direction targets. Unreachable BY
                  NAVIGATION, but a valid cursor position if something
                  else puts that id in $3(a6); its own row then governs
                  where the stick takes you. vsavj's whole variant half
                  is this (16 verbatim copies); vs2's cell 0x18 is this.

    Errors are structural only: a row pointing at a dead cell, a row
    mixing live entries with $ff, or a target outside the table.
    """
    live = [c for c, r in enumerate(rows) if any(v != DEAD for v in r)]
    dead = [c for c in range(NCELL) if c not in live]
    errs = []

    # partially-dead rows are a decode error, not a design (either the
    # cell exists or it does not)
    for c in live:
        vs = rows[c]
        if any(v == DEAD for v in vs):
            errs.append("cell %02X: mixed live/$ff row %s"
                        % (c, " ".join("%02x" % v for v in vs)))

    targets = set()
    for c in live:
        for v in rows[c]:
            if v == DEAD:
                continue
            targets.add(v)
            if v in dead:
                errs.append("cell %02X points at DEAD cell %02X" % (c, v))
            if v >= NCELL:
                errs.append("cell %02X points outside the table: %02X" % (c, v))

    # navigable = reachable from the first live cell by walking directions
    seen, stack = set(), [live[0]] if live else []
    while stack:
        c = stack.pop()
        if c in seen:
            continue
        seen.add(c)
        for v in rows[c]:
            if v != DEAD and v in live and v not in seen:
                stack.append(v)
    navigable = sorted(seen)
    entry_only = [c for c in live if c not in seen]

    return live, dead, navigable, entry_only, errs


def gen_walk(rows, navigable, names, start_frame, period):
    """Generate an input script visiting EVERY (cell, direction) pair of the
    navigable subgraph, plus the cell sequence it must produce.

    Every press is a test: transit moves are predictions too. Greedy — take
    an untested direction at the current cell, else walk the shortest path
    to the nearest cell that still has one.
    """
    inv = {n: d for d, n in names.items()}
    todo = {(c, d) for c in navigable for d in range(NDIR)}
    # shortest paths as direction lists, over navigable cells
    def route(src, dsts):
        seen, q = {src: []}, [src]
        while q:
            nxt = []
            for c in q:
                if c in dsts and c != src:
                    return seen[c]
                for d in range(NDIR):
                    v = rows[c][d]
                    if v not in seen:
                        seen[v] = seen[c] + [d]
                        nxt.append(v)
            q = nxt
        return None

    cur, frame, lines, expect = DEFAULT_CELL, start_frame, [], []

    def press(d):
        nonlocal cur, frame
        nxt = rows[cur][d]
        expect.append({"frame": frame, "from": cur, "dir": d,
                       "dir_name": names[d], "to": nxt})
        lines.append("%d p1=%s" % (frame, names[d]))
        todo.discard((cur, d))
        cur, frame = nxt, frame + period

    while todo:
        here = [d for d in range(NDIR) if (cur, d) in todo]
        if here:
            press(here[0])
            continue
        dsts = {c for c, _ in todo}
        path = route(cur, dsts)
        if path is None:
            break
        for d in path:
            press(d)
    return lines, expect, sorted(todo)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("image", help="DATA-space image (cps2_decrypt --data-out)")
    ap.add_argument("--set", required=True, choices=sorted(SETS))
    ap.add_argument("--json", help="write the decoded tables here")
    ap.add_argument("--walk-rpl", help="write a full-coverage input script")
    ap.add_argument("--walk-expect", help="write the expected cell sequence")
    ap.add_argument("--walk-start", type=int, default=900,
                    help="frame of the first cursor press (select is up ~889)")
    ap.add_argument("--walk-period", type=int, default=3,
                    help="frames between presses (input is edge-triggered)")
    args = ap.parse_args()

    cfg = SETS[args.set]
    print("read %s  sha1 %s" % (args.image, sha1_of(args.image)))
    dat = open(args.image, "rb").read()
    print("set %s: TABLE A PRG:0x%06X  TABLE B PRG:0x%06X  nav site PRG:0x%06X"
          % (args.set, cfg["table_a"], cfg["table_b"], cfg["nav_site"]))
    print("commit: cell -> $03(a6) at PRG:0x%06X, char id -> $382(a6) at "
          "PRG:0x%06X" % (cfg["commit_cell"], cfg["commit_id"]))

    raw_a, fwd_a, rev_a = decode_table_a(dat, cfg["table_a"])
    errs = ["TABLE A: " + e for e in check_table_a(raw_a, fwd_a)]
    names = dir_names(rev_a)
    print("\nTABLE A  %s" % " ".join("%02x" % b for b in raw_a))
    print("  legal nibbles: " + ", ".join(
        "%X->%d(%s)" % (n, d, names[d]) for n, d in sorted(fwd_a.items())))

    rows = decode_table_b(dat, cfg["table_b"])
    live, dead, navigable, entry_only, errs_b = analyse_table_b(rows)
    errs += ["TABLE B: " + e for e in errs_b]

    print("\nTABLE B  %d rows x %d: navigable %d, entry-only %d, dead %d"
          % (NCELL, NDIR, len(navigable), len(entry_only), len(dead)))
    print("  dir order: " + " ".join("%d=%s" % (d, names[d])
                                     for d in range(NDIR)))
    hdr = "  cell |" + "".join("%4s" % names[d] for d in range(NDIR))
    print(hdr)
    print("  " + "-" * (len(hdr) - 2))
    for c in range(NCELL):
        if c in dead:
            continue
        print("    %02X |" % c + "".join(
            "%4s" % ("--" if v == DEAD else "%02X" % v) for v in rows[c])
            + ("" if c in navigable else "   (entry-only)"))
    if dead:
        print("  dead cells ($ff rows): "
              + " ".join("%02X" % c for c in dead))
    if entry_only:
        print("  entry-only cells (no direction targets them): "
              + " ".join("%02X" % c for c in entry_only))

    if args.set == "vsavj":
        pe = check_known_paths(rows, names)
        errs += ["known cursor path: " + e for e in pe]
        if not pe:
            print("\n  known cursor paths reproduce (%s) — direction "
                  "labelling confirmed" % ", ".join(
                      "%s->%02X" % (p, w) for p, w, _ in KNOWN_PATHS))

    hi_nav = [c for c in navigable if c >= 0x10]
    hi_ent = [c for c in entry_only if c >= 0x10]
    print("\n  VARIANT half (0x10-0x1F): navigable %s | entry-only %s"
          % (" ".join("%02X" % c for c in hi_nav) or "none",
             " ".join("%02X" % c for c in hi_ent) or "none"))
    lo_rows = [rows[c] for c in range(0x10)]
    hi_rows = [rows[c] for c in range(0x10, 0x20)]
    print("  upper 16 rows == lower 16 rows (whole-half alias): %s"
          % (lo_rows == hi_rows))

    if args.walk_rpl or args.walk_expect:
        lines, expect, missed = gen_walk(rows, navigable, names,
                                         args.walk_start, args.walk_period)
        if missed:
            errs.append("walk could not reach %d (cell,dir) pairs: %s"
                        % (len(missed), missed[:8]))
        npair = len(navigable) * NDIR
        print("\nwalk: %d presses covering %d/%d (cell,direction) pairs, "
              "frames %d-%d" % (len(expect), npair - len(missed), npair,
                                args.walk_start,
                                expect[-1]["frame"] if expect else 0))
        if args.walk_rpl:
            with open(args.walk_rpl, "w") as f:
                f.write("# GENERATED by tools/select_wheel.py --walk-rpl "
                        "(set %s) — do not hand-edit.\n"
                        "# Visits every (cell,direction) pair of the wheel; "
                        "each press is a prediction to verify.\n"
                        % args.set)
                f.write("300-305 sys=C1\n800-803 sys=S1\n")
                f.write("\n".join(lines) + "\n")
                f.write("%d wait\n" % (expect[-1]["frame"] + 60))
            print("wrote %s" % args.walk_rpl)
        if args.walk_expect:
            with open(args.walk_expect, "w") as f:
                json.dump({"set": args.set, "start_cell": DEFAULT_CELL,
                           "commit_pc": cfg["commit_cell"],
                           "presses": expect}, f, indent=1)
            print("wrote %s" % args.walk_expect)

    if args.json:
        with open(args.json, "w") as f:
            json.dump({"set": args.set, "table_a": list(raw_a),
                       "table_b": rows, "navigable": navigable,
                       "entry_only": entry_only, "dead": dead,
                       "dirs": {str(d): names[d] for d in names}}, f, indent=1)
        print("\nwrote %s" % args.json)

    if errs:
        print("\nFAIL:")
        for e in errs:
            print("  " + e)
        return 1
    print("\nOK: table A is a complete 8-way decode; every TABLE B target "
          "is a live cell (%d navigable, %d entry-only)"
          % (len(navigable), len(entry_only)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
