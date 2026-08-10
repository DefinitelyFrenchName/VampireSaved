#!/usr/bin/env python3
"""audit_variant_dispatch.py — sweep every PER-CHARACTER JUMP TABLE whose
variant half (rows 0x10-0x1F) ALIASES the base half (0x00-0x0F), and
check the tenant's row against vs2's own value (14z-75).

WHY THIS EXISTS. The single most common defect shape in this port is a
32-row per-character table where vsav aliases rows 0x10-0x1F onto
0x00-0x0F, so a tenant at a variant id silently inherits a base-half
character's behaviour. Pyron's sprite/HUD blink was this, THREE TIMES
OVER, in three different tables — and chasing it one screen at a time
found only the first. This audit finds them all at once, statically.

THE SHAPE, mechanically: `jmp (d8,PC,Dn.w)` preceded by a
`move.b <char id>,Dn / add.w Dn,Dn` — a word-displacement jump table at
`jmp_addr + 2 + d8`, indexed by `id*2`. A table qualifies when at least
12 of its 16 variant rows equal their base-half counterpart (not all 16:
vsav does fill the odd variant row, e.g. 0x12 in table 0x2A8A4).

THE CHECK: for each qualifying table, locate vs2's twin by matching the
code preceding the jmp, then require

    ours[tenant_row] == vs2[tenant_row]

i.e. the tenant behaves as its own game does. A row where ours differs is
either a spurious inherited routine (ours does something vs2 does not —
the blink) or a missing one (vs2 does something ours does not). Both are
reported; only the first is a live defect, and the direction is printed
so they are never confused.

Usage: audit_variant_dispatch.py <vsavj_op.bin> <vs2_op.bin> [build_op.bin]
                                 [--tenant 0x11] [--expect-clean]
  With no build image, audits vsavj itself (shows the raw exposure).
  --expect-clean makes any ours-does-more row a FAILURE (exit 1).
"""

import struct
import sys
from pathlib import Path

ROWS_OF_INTEREST = (0x10, 0x11, 0x13)   # Huitzil, Pyron, Donovan
MIN_ALIASED = 12


def qualifying_tables(img):
    """(jmp_addr, table_base, entries[32], n_aliased) for each candidate."""
    out = []
    for a in range(0, len(img) - 4, 2):
        if img[a] != 0x4E or img[a + 1] != 0xFB:
            continue
        ext = struct.unpack(">H", img[a + 2:a + 4])[0]
        if ext & 0x0700:                      # scaled / long forms: not this idiom
            continue
        base = a + 2 + (ext & 0xFF)
        if base + 0x40 > len(img):
            continue
        e = [struct.unpack(">H", img[base + 2 * i:base + 2 * i + 2])[0]
             for i in range(32)]
        if len(set(e[:16])) < 2:              # a flat table indexes nothing
            continue
        n = sum(1 for i in range(16, 32) if e[i] == e[i & 0x0F])
        if n >= MIN_ALIASED:
            out.append((a, base, e, n))
    return out


def _all(img, pat):
    out, i = [], img.find(pat)
    while i != -1:
        out.append(i)
        i = img.find(pat, i + 1)
    return out


def _table_at(img, ja):
    ext = struct.unpack(">H", img[ja + 2:ja + 4])[0]
    b = ja + 2 + (ext & 0xFF)
    return b, [struct.unpack(">H", img[b + 2 * k:b + 2 * k + 2])[0]
               for k in range(32)]


def find_twin(vj, vs2, jmp_addr):
    """vs2's table for the same dispatcher.

    Unique context match first. When the context is NOT unique the match
    is made by ORDINAL correspondence — the k-th occurrence in vsavj maps
    to the k-th in vs2 — which is required, not optional: vsav ships TWO
    byte-identical copies of the `move.b ($382,A6)` dispatcher, and
    demanding uniqueness silently skipped the very table that carried the
    first instance of this defect (14z-75).
    """
    for n in (0x40, 0x30, 0x20, 0x14, 0x0C):
        ctx = vj[jmp_addr - n:jmp_addr + 4]
        hj, h2 = _all(vj, ctx), _all(vs2, ctx)
        if not h2:
            continue
        if len(hj) == len(h2) == 1:
            return _table_at(vs2, h2[0] + n)
        if len(hj) == len(h2) and (jmp_addr - n) in hj:
            return _table_at(vs2, h2[hj.index(jmp_addr - n)] + n)
    return None, None


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    tenant = 0x11
    if "--tenant" in sys.argv:
        tenant = int(sys.argv[sys.argv.index("--tenant") + 1], 0)
    strict = "--expect-clean" in sys.argv

    vj = Path(args[0]).read_bytes()
    vs2 = Path(args[1]).read_bytes()
    ours = Path(args[2]).read_bytes() if len(args) > 2 else vj

    tables = qualifying_tables(vj)
    print(f"per-character jump tables with an aliased variant half: "
          f"{len(tables)}")
    untwinned, spurious, missing, ok = [], [], [], 0

    for jmp_addr, base, e, n in tables:
        b2, e2 = find_twin(vj, vs2, jmp_addr)
        o = [struct.unpack(">H", ours[base + 2 * k:base + 2 * k + 2])[0]
             for k in range(32)]
        if e2 is None:
            untwinned.append(base)
            print(f"  table {base:#08x} (jmp {jmp_addr:#08x}) alias {n}/16 "
                  f"— vs2 twin NOT FOUND, cannot judge")
            continue
        row_states = []
        for r in ROWS_OF_INTEREST:
            if o[r] == e2[r]:
                continue
            # which direction?
            default = e2[r] == 0x0040 or o[r] != 0x0040 and e2[r] == 0x0040
            if e2[r] == 0x0040:
                row_states.append((r, "OURS-DOES-MORE", o[r], e2[r]))
            elif o[r] == 0x0040:
                row_states.append((r, "ours-does-less", o[r], e2[r]))
            else:
                row_states.append((r, "OURS-DIFFERS", o[r], e2[r]))
        if not row_states:
            ok += 1
            print(f"  table {base:#08x}  vs2 {b2:#08x}  alias {n}/16  "
                  f"ok (rows 0x10/0x11/0x13 all match vs2)")
            continue
        print(f"  table {base:#08x}  vs2 {b2:#08x}  alias {n}/16")
        for r, kind, ov, vv in row_states:
            print(f"      row {r:#04x}: ours {ov:#06x}  vs2 {vv:#06x}  {kind}")
            if kind == "OURS-DOES-MORE":
                spurious.append((base, r, ov, vv))
            else:
                missing.append((base, r, ov, vv))

    print(f"\nsummary: {ok} clean, {len(spurious)} row(s) where OURS RUNS A "
          f"ROUTINE vs2 DOES NOT (the live defect class), "
          f"{len(missing)} where vs2 runs one we do not, "
          f"{len(untwinned)} unjudgeable")
    t_sp = [s for s in spurious if s[1] == tenant]
    if t_sp:
        print(f"TENANT {tenant:#04x} INHERITS {len(t_sp)} spurious routine(s):")
        for base, r, ov, vv in t_sp:
            print(f"   table {base:#08x} row {r:#04x}: {ov:#06x} "
                  f"(should be {vv:#06x})")
    else:
        print(f"TENANT {tenant:#04x}: no spurious inherited routine")
    if strict and t_sp:
        print("FAIL: tenant inherits a base-half routine vs2 does not run")
        sys.exit(1)
    print("OK")


if __name__ == "__main__":
    main()
