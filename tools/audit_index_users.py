#!/usr/bin/env python3
"""audit_index_users.py — WHO drives a dispatch index into a danger window?

THE GAP THIS CLOSES (14z-78). `audit_index_space.py` derives, for every
`jmp (d8,PC,Dn.w)` table, how many entries vsavj has versus vs2, and reports
the tables where vs2 is LONGER. That names a DANGER WINDOW — the entry numbers
a ported character can drive that vsavj's table cannot answer.

It stops there. Nothing said which tenant DATA actually lands in one.

That omission has now cost two crashes in the SAME table (`0x018468`, vsavj 80
entries, vs2 84, window [80..83]):

    Pyron   Cosmo Disruption      entry 81   fixed 14z-74/75
    Phobos  Plasma Trap (214+MK)  entry 82   found 14z-78, by PLAYTEST

After Cosmo was fixed nobody asked who else drove 80, 82 or 83 of the same
table — so Plasma Trap sat crashing on every Phobos build while every gate was
green, and was found only because a human played the move. Entry 83 is STILL
unaccounted for. This tool answers the question statically, for every tenant,
without anyone playing anything.

HOW IT RECOGNISES AN INDEX. Learned from the one ratified instance rather than
guessed: `pyron.toml`'s Cosmo fix rewrites `0x0151 -> 0x014F` at vs2
`0x0D0C7E` in region `hitbox_proj`. The sub-state index is the LOW BYTE of a
word `0x01NN`. So a candidate is a word-aligned `0x01NN` inside one of the
tenant's OWN ported region spans, with NN in some table's danger window.

WHAT IT DELIBERATELY DOES NOT CLAIM, and this matters for reading the output.
`0x01NN` is a byte PATTERN, not a proof of meaning, and a candidate is not a
defect. Two things must both hold for a crash: the word must really be a
sub-state index, AND the character's code must actually DISPATCH that record.
This tool can only see the first.

The measured evidence that the noise is real: DONOVAN reports 17 candidates on
table 0x18464 alone, at a consistent 0x20 record stride — and he is the most
heavily played build in the project and has never crashed this way. So most of
his hits are either a different field that merely looks like an index, or an
index on a record his code never reaches (the DEAD-ROW question, which is a
runtime one). Pyron's and Phobos' real defects sit at the same stride, so the
pattern alone cannot separate them.

THIS DOES NOT REDUCE THE SCOPE OF MOVES TO PLAYTEST, and an earlier version of
this docstring wrongly implied it did (maintainer-corrected, 14z-78). Two
reasons, both structural:

  * it reports vs2 ADDRESSES, not moves, so there is no move-set to narrow TO;
  * it sees exactly ONE defect class. A move can crash from a dead table row,
    an allocator on an unseeded pool, or an effect-class stub, and this sweep
    stays silent on every one of them.

So a full movelist pass — every move, every strength, every tenant — remains
required, and skipping a move because it is absent here would be unsafe. The
output is a PRIOR, not a filter: it says where to look once something trips,
and what to suspect first. A hit is a reason to test; only the test, or a
runtime deadness probe on the record, decides.

The companion instrument for the pass itself is `tests/lua/index_watch.lua`,
which attributes a dangerous dispatch to the move as it is played. It secures
the sweep; it does not shorten it either.

THE SHARPENING THIS WANTS NEXT: a vanilla baseline. If vsav's OWN characters
carry the same field at the same record offset and it never exceeds the vsavj
table's last valid entry, then the field IS the index and any tenant value
inside a danger window is a genuine defect rather than a coincidence. That
control would cut the list to the real ones and is cheap to add.

SHARED SPANS ARE FILTERED, and that filter is load-bearing. `x2b7ef4` carries
`0x0150/51/52/53` at stride 8 at the SAME vs2 addresses for every tenant: it is
the dispatch data itself, not any character's index. A hit at one address for
two or more tenants is therefore reported separately and never as a tenant
candidate — without that split, every tenant reports the same four false hits.

TRAP (inherited from audit_index_space): a danger window is in ENTRY numbers,
but a dispatcher's register holds entry*2. This tool works in ENTRY numbers
throughout — the `0x01NN` byte is the entry, not the doubled register value.

Usage:
  audit_index_users.py <vsavj_op.bin> <vs2_op.bin> <vs2_data.bin> \
                       <tenant>=<extract_dir> [<tenant>=<extract_dir> ...]
                       [--json OUT]
"""
import argparse
import json
import pathlib
import sys

import subprocess
import tempfile

_HERE = pathlib.Path(__file__).resolve().parent


def _int(v):
    return v if isinstance(v, int) else int(str(v), 16)


def risky_windows(vsavj_op, vs2_op):
    """[(jmp, base, n_vsavj, n_vs2)] for tables where vs2 is LONGER.

    Obtained by RUNNING `audit_index_space.py` rather than re-deriving the
    counts here. That is deliberate: two instruments that disagree about where
    a danger window is would be worse than one, and this way the window is
    always exactly what the frozen sweep reports.
    """
    with tempfile.NamedTemporaryFile(suffix=".json") as tf:
        subprocess.run(
            [sys.executable, str(_HERE / "audit_index_space.py"),
             str(vsavj_op), str(vs2_op), "--json", tf.name],
            check=True, capture_output=True)
        d = json.loads(pathlib.Path(tf.name).read_text())
    # field types are mixed in that file (addresses are hex strings, counts
    # are ints), so normalise rather than assume.
    return [(_int(r["jmp"]), _int(r["base"]),
             int(r["n_vsavj"]) if not isinstance(r["n_vsavj"], str)
             else _int(r["n_vsavj"]),
             int(r["n_vs2"]) if not isinstance(r["n_vs2"], str)
             else _int(r["n_vs2"]))
            for r in d["risky"]]


def scan(vs2_data, regions, windows):
    """Word-aligned 0x01NN inside a tenant's spans, NN in a danger window."""
    wanted = {}
    for jmp, base, n_vj, n_v2 in windows:
        for entry in range(n_vj, n_v2):
            wanted.setdefault(entry, []).append((jmp, base, n_vj, n_v2))
    hits = []
    for name, r in regions.items():
        src, ln = _int(r["src"]), _int(r["len"])
        for a in range(src if src % 2 == 0 else src + 1, src + ln - 1, 2):
            w = int.from_bytes(vs2_data[a:a + 2], "big")
            if (w >> 8) != 0x01:
                continue
            entry = w & 0xFF
            if entry in wanted:
                hits.append({"region": name, "addr": a, "word": w,
                             "entry": entry, "tables": wanted[entry]})
    return hits


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("vsavj_op", type=pathlib.Path)
    ap.add_argument("vs2_op", type=pathlib.Path)
    ap.add_argument("vs2_data", type=pathlib.Path)
    ap.add_argument("tenants", nargs="+", help="name=extract_dir")
    ap.add_argument("--json", type=pathlib.Path)
    args = ap.parse_args()

    vj = args.vsavj_op.read_bytes()
    v2 = args.vs2_op.read_bytes()
    v2d = args.vs2_data.read_bytes()

    windows = risky_windows(args.vsavj_op, args.vs2_op)
    print("== risky tables (vs2 longer than vsavj) ==")
    for jmp, base, n_vj, n_v2 in windows:
        print(f"   jmp {jmp:#08x}  base {base:#08x}  vsavj {n_vj}  vs2 {n_v2}"
              f"  DANGER ENTRIES [{n_vj}..{n_v2 - 1}]")
    if not windows:
        print("   (none — nothing to sweep)")

    per = {}
    for spec in args.tenants:
        name, _, d = spec.partition("=")
        regs = json.loads((pathlib.Path(d) / "regions.json").read_text())["regions"]
        per[name] = scan(v2d, regs, windows)

    # A hit at the SAME vs2 address for 2+ tenants is shared dispatch data,
    # not any character's index. Split it out; see the module docstring.
    seen = {}
    for name, hits in per.items():
        for h in hits:
            seen.setdefault(h["addr"], set()).add(name)
    shared = {a for a, who in seen.items() if len(who) > 1}

    print("\n== TENANT-OWNED candidates — where to look, NOT a shortened test list ==")
    rows = []
    for name in sorted(per):
        own = [h for h in per[name] if h["addr"] not in shared]
        print(f"\n  {name}: {len(own)} candidate(s)")
        for h in sorted(own, key=lambda x: x["addr"]):
            tb = ", ".join(f"table {t[0]:#x} (vsavj {t[2]})" for t in h["tables"])
            print(f"     entry {h['entry']:>3}  word {h['word']:#06x}  "
                  f"{h['region']}@{h['addr']:#08x}   -> {tb}")
            rows.append(dict(tenant=name, **{k: h[k] for k in
                                             ("region", "addr", "word", "entry")}))
    nsh = len(shared)
    print(f"\n  ({nsh} address(es) filtered as SHARED dispatch data, seen at the "
          f"same vs2 address for 2+ tenants)")

    if args.json:
        args.json.write_text(json.dumps(
            {"windows": [{"jmp": j, "base": b, "n_vsavj": nv, "n_vs2": n2}
                         for j, b, nv, n2 in windows],
             "candidates": rows,
             "shared_filtered": sorted(shared)}, indent=1))
    return 0


if __name__ == "__main__":
    sys.exit(main())
