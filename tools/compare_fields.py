#!/usr/bin/env python3
"""compare_fields.py — compare mapped gameplay fields between two replay runs
from their per-frame RAM dumps (CLAUDE.md §4 dual-emulator protocol).

The two sides are directories containing dump files produced by the MAME
harness (tests/lua/replay.lua `DUMPS`, files `dump_<frame>_<addr>.bin`) or the
FBNeo harness (`-hdump`, files `<hout>.dump_<frame>_<addr>.bin`). Both are
68k-logical byte order and inclusive address ranges, so they are directly
comparable.

Two modes:
  * --anchor (default): the emulators traverse identical states on different
    frame indices (measured, session 2), so fixed-frame comparison is invalid.
    Each side's dumped frame window is searched for sync-anchor frames — the
    rising edge of the match-start predicate:
        $FF8004.l == 0x40000 and $FF8008.l == 0x40000
        and P1 HP ($FF8450.w) == 0x120 and P2 HP ($FF8850.w) == 0x120
    The i-th anchor of side A is compared to the i-th anchor of side B, at the
    anchor frame and at each --follow offset after it.
  * --exact: frame-for-frame comparison of all common dumped frames (for
    same-emulator runs, where frame indices align deterministically).

Fields come from a TSV (see tests/fields_m2a.tsv): name/base/addr/width, with
base abs|p1|p2 (p1=$FF8400, p2=$FF8800).

Usage:
    python3 tools/compare_fields.py <dir_a> <dir_b> --fields tests/fields_m2a.tsv
        [--exact] [--follow 0,1,5,30] [--label-a mame] [--label-b fbneo]
        [--skip-fields p1_anim_ptr,p2_anim_ptr]

Exit 0 = all compared fields agree; 3 = mismatch; 1 = usage/data error.
"""

import argparse
import re
import sys
from pathlib import Path

P1_BASE = 0xFF8400
P2_BASE = 0xFF8800

DUMP_RE = re.compile(r"(?:^|\.)dump_(\d+)_([0-9a-fA-F]{6})\.bin$")

# match-start predicate fields (docs/game/atlas/ram.md)
PRED_FLAGS = ((0xFF8004, 4, 0x40000), (0xFF8008, 4, 0x40000),
              (P1_BASE + 0x50, 2, 0x120), (P2_BASE + 0x50, 2, 0x120))


def load_side(d):
    """dir -> {frame: [(start, bytes), ...]}"""
    frames = {}
    d = Path(d)
    if not d.is_dir():
        sys.exit(f"not a directory: {d}")
    for p in d.iterdir():
        m = DUMP_RE.search(p.name)
        if m:
            frames.setdefault(int(m.group(1)), []).append(
                (int(m.group(2), 16), p.read_bytes()))
    if not frames:
        sys.exit(f"no dump_<frame>_<addr>.bin files in {d}")
    return frames


def read_at(ranges, addr, width):
    """Big-endian value at addr from [(start, bytes)] ranges; None if absent."""
    for start, blob in ranges:
        if start <= addr and addr + width <= start + len(blob):
            v = 0
            for i in range(width):
                v = (v << 8) | blob[addr - start + i]
            return v
    return None


def predicate(ranges):
    for addr, width, want in PRED_FLAGS:
        v = read_at(ranges, addr, width)
        if v is None:
            sys.exit(f"anchor predicate field ${addr:06X} not covered by dumps "
                     "(dump $FF8000-$FF8300 and $FF8400-$FF8C00 windows)")
        if v != want:
            return False
    return True


STABLE = 30  # debounce: the predicate flickers true transiently during round
             # intros (measured on 02_demitri_vs_cpu ~frame 2350); an anchor
             # must hold for STABLE frames to count as a real match start.


def find_anchors(frames):
    """Debounced rising-edge frames of the match-start predicate. A window
    whose FIRST frame already satisfies the predicate is ambiguous (the real
    anchor may lie before the window) and is NOT counted — widen the window.
    A rising edge counts only if every sampled frame in (edge, edge+STABLE]
    also satisfies the predicate, with coverage at least past edge+STABLE/2."""
    keys = sorted(frames)
    pred = {fr: predicate(frames[fr]) for fr in keys}
    anchors, prev = [], None
    for i, fr in enumerate(keys):
        cur = pred[fr]
        if prev is None and cur:
            print(f"WARNING: predicate already true at window start (frame {fr}) "
                  "— anchor may precede the dumped window", file=sys.stderr)
        if prev is False and cur:
            later = [k for k in keys[i + 1:] if k <= fr + STABLE]
            if later and later[-1] >= fr + STABLE // 2 and all(pred[k] for k in later):
                anchors.append(fr)
            else:
                print(f"NOTE: transient/uncovered predicate edge at frame {fr} "
                      "ignored (debounce)", file=sys.stderr)
        prev = cur
    return anchors


def parse_fields(path):
    fields = []
    for lineno, line in enumerate(Path(path).read_text().splitlines(), 1):
        line = line.split("#")[0].rstrip()
        if not line:
            continue
        parts = line.split("\t")
        if len(parts) < 4:
            sys.exit(f"{path}:{lineno}: expected name/base/addr/width[/phase] TSV")
        name, base, addr, width = parts[0], parts[1], int(parts[2], 0), int(parts[3])
        phase = parts[4] if len(parts) > 4 and parts[4] else "stable"
        if base == "p1":
            addr += P1_BASE
        elif base == "p2":
            addr += P2_BASE
        elif base != "abs":
            sys.exit(f"{path}:{lineno}: base must be abs|p1|p2")
        if width not in (1, 2, 4):
            sys.exit(f"{path}:{lineno}: width must be 1|2|4")
        if phase not in ("stable", "settled", "phase"):
            sys.exit(f"{path}:{lineno}: phase must be stable|settled|phase")
        fields.append((name, addr, width, phase))
    if not fields:
        sys.exit(f"{path}: no fields")
    return fields


def compare_frame(fields, a_ranges, b_ranges, tag, la, lb, skip):
    bad = 0
    for name, addr, width, _phase in fields:
        if name in skip:
            continue
        va = read_at(a_ranges, addr, width)
        vb = read_at(b_ranges, addr, width)
        if va is None or vb is None:
            side = la if va is None else lb
            print(f"MISSING {tag} {name} ${addr:06X}.{width} not dumped on {side}")
            bad += 1
        elif va != vb:
            print(f"MISMATCH {tag} {name} ${addr:06X}.{width} "
                  f"{la}={va:0{width*2}x} {lb}={vb:0{width*2}x}")
            bad += 1
    return bad


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("dir_a")
    ap.add_argument("dir_b", nargs="?")
    ap.add_argument("--list-anchors", action="store_true",
                    help="print anchor frames of dir_a and exit")
    ap.add_argument("--fields")
    ap.add_argument("--exact", action="store_true",
                    help="frame-exact comparison (same-emulator runs)")
    ap.add_argument("--follow", default="0",
                    help="comma list of frame offsets after each anchor")
    ap.add_argument("--settle", type=int, default=120,
                    help="offset at/after which 'settled' fields are compared")
    ap.add_argument("--label-a", default="A")
    ap.add_argument("--label-b", default="B")
    ap.add_argument("--skip-fields", default="",
                    help="comma list of field names to skip")
    args = ap.parse_args()

    if args.list_anchors:
        for fr in find_anchors(load_side(args.dir_a)):
            print(fr)
        return
    if not args.dir_b or not args.fields:
        ap.error("dir_b and --fields are required unless --list-anchors")

    fields = parse_fields(args.fields)
    skip = set(x for x in args.skip_fields.split(",") if x)
    a = load_side(args.dir_a)
    b = load_side(args.dir_b)
    la, lb = args.label_a, args.label_b
    bad = 0

    if args.exact:
        common = sorted(set(a) & set(b))
        if not common:
            sys.exit("no common dumped frames")
        for fr in common:
            bad += compare_frame(fields, a[fr], b[fr], f"frame {fr}", la, lb, skip)
        print(f"exact mode: {len(common)} frames compared")
    else:
        # anchor mode is cross-emulator: anim-cursor ('phase') fields are
        # inherently unlocked across emulators, and 'settled' fields are valid
        # only once the round has settled into neutral idle
        def fields_for(k):
            return [f for f in fields
                    if f[3] == "stable" or (f[3] == "settled" and k >= args.settle)]
        aa, ab = find_anchors(a), find_anchors(b)
        print(f"anchors: {la}={aa} {lb}={ab}")
        if not aa or not ab:
            sys.exit(f"no anchor found ({la}: {len(aa)}, {lb}: {len(ab)}) — "
                     "widen the dump window")
        if len(aa) != len(ab):
            print(f"ANCHOR-COUNT MISMATCH {la}={len(aa)} {lb}={len(ab)}")
            bad += 1
        follows = [int(x) for x in args.follow.split(",")]
        for i, (fa, fb) in enumerate(zip(aa, ab)):
            for k in follows:
                if fa + k in a and fb + k in b:
                    bad += compare_frame(fields_for(k), a[fa + k], b[fb + k],
                                         f"anchor{i}+{k} ({la}:{fa + k}/{lb}:{fb + k})",
                                         la, lb, skip)
                else:
                    print(f"MISSING anchor{i}+{k}: frame not dumped "
                          f"({la}:{fa + k} in={fa + k in a}, {lb}:{fb + k} in={fb + k in b})")
                    bad += 1

    if bad:
        print(f"FAIL: {bad} disagreement(s)")
        sys.exit(3)
    print("OK: all compared fields agree")


if __name__ == "__main__":
    main()
