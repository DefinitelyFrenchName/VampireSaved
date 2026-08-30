#!/usr/bin/env python3
"""projectile_params.py — decode a PROJECTILE TYPE HANDLER's inline parameter
tables (character-data map phase 3, 14z-121).

  python3 tools/projectile_params.py <opcodes.bin> <handler_hex> [<handler_hex> ...] [--json out]

WHAT IT READS. Every $FF9400-pool projectile type has its own handler
(vs2 walker-2 LONG table 0x5C620[type], engine_internals "Which moves spawn
PROJECTILE-POOL objects"), and its parameters are INLINE in that handler,
not in a table family (14z-120 (10), Blizzard Sword). The init block has
ONE shape across the eight types measured (14z-121; Cosmo Disruption is
the exception — immediates per state, reported as such):

    moveq #0,d0 ; move.b $9a(a6),d0             ; +0x9A = the spawn's variant (from the attacker's +0x102)
    move.b/w T_26(pc,d0.w),$26(a6)              ; per-variant byte/word -> +0x26
    move.w   T_50(pc,d0.w),$50(a6)              ; per-variant word     -> +0x50
    moveq #0,d0 ; move.b $9a(a6),d0 ; move.w T_ix(pc,d0.w),d0   ; +0x9A -> a byte offset into the long tables
      -- or (Blizzard only) move.b $a(a6),d0 ; asl.w #3,d0        ; +0x0A*8 indexes 8-byte (xv,yv) pairs
    move.l T_xv(pc,d0.w),d1 ; move.l T_xa(pc,d0.w)|#imm,d2 ; tst.b $b(a6) ; bne ; neg.l d1 ; neg.l d2
    move.l d1,$40(a6) ; move.l d2,$48(a6)        ; x velocity, x acceleration (16.16, mirrored by flip_x)
    move.l T_yv(pc,d0.w),$44(a6) ; move.l T_ya(pc,d0.w)|#imm,$4c(a6)   ; y velocity, y acceleration
    rts

The pc-relative tables are read from the OPCODE view (that is the space
pc-relative reads are served from — cps2-emulation [CPE-8]); the image
must be the *_opcodes.bin. Prints the SHA-1 of what it reads.

OUTPUT per handler: the init block's address, every table's address and
raw words, and the evaluated (+0x26, +0x50, xv, xacc, yv, yacc) row for
each +0x9A index the tables hold (the +0x9A VALUES a spawn actually uses
are measured live by tests/test_projectile_params.sh, which compares the
live slot fields against these rows).
"""
import hashlib
import json
import re
import sys

import capstone


def dis(data, start, n):
    md = capstone.Cs(capstone.CS_ARCH_M68K, capstone.CS_MODE_BIG_ENDIAN | capstone.CS_MODE_M68K_000)
    out = []
    a = start
    while a < start + n:
        got = False
        for i in md.disasm(data[a:a + 10], a):
            out.append((i.address, i.size, i.mnemonic, i.op_str, i.bytes.hex()))
            a += i.size
            got = True
            break
        if not got:
            out.append((a, 2, "dc.w", data[a:a + 2].hex(), data[a:a + 2].hex()))
            a += 2
    return out


PCREL = re.compile(r"\$([0-9a-f]+)\(pc, d0\.w\)")


def s32(b):
    return int.from_bytes(b, "big", signed=True)


def f16(v):
    return v / 65536.0


def decode(data, h):
    """Return {"handler":..,"init":..,"shape":..,"tables":{..},"rows":[..]} or an 'immediate' report."""
    ins = dis(data, h, 0x800)
    # locate the init: `move.b $9a(a6), d0` followed within 3 instructions by a pc-relative move to $26(a6)
    init = None
    for k, (a, sz, mn, op, hx) in enumerate(ins):
        if mn == "move.b" and op == "$9a(a6), d0":
            for j in range(k + 1, min(k + 4, len(ins))):
                if ins[j][2] in ("move.b", "move.w") and ins[j][3].endswith("$26(a6)") and "(pc, d0.w)" in ins[j][3]:
                    init = k
                    break
        if init is not None:
            break
    if init is None:
        # Cosmo-style: immediates written straight to +0x40/+0x48/+0x44/+0x4c
        imm = []
        for a, sz, mn, op, hx in ins:
            m = re.match(r"#\$([0-9a-f]+), \$(40|44|48|4c)\(a6\)", op)
            if mn == "move.l" and m:
                v = int(m.group(1), 16)
                v = v - (1 << 32) if v & 0x80000000 else v
                imm.append({"pc": f"{a:#x}", "field": f"+0x{m.group(2)}", "value": v, "f16": f16(v)})
        return {"handler": f"{h:#x}", "shape": "immediate", "immediates": imm}
    tabs = {}
    shape = "B"
    d0_mode = None
    for a, sz, mn, op, hx in ins[init:init + 24]:
        m = PCREL.search(op)
        tgt = int(m.group(1), 16) if m else None
        if mn in ("move.b", "move.w") and op.endswith("$26(a6)") and tgt:
            tabs["t26"] = (tgt, "b" if mn == "move.b" else "w")
        elif mn == "move.w" and op.endswith("$50(a6)") and tgt:
            tabs["t50"] = (tgt, "w")
        elif mn == "move.w" and op.endswith(", d0") and tgt:
            tabs["tix"] = (tgt, "w"); d0_mode = "ix"
        elif mn == "move.b" and op == "$a(a6), d0":
            d0_mode = "a*8"; shape = "A"
        elif mn == "move.l" and op.endswith(", d1") and tgt:
            tabs["xv"] = (tgt, "l")
        elif mn == "move.l" and op.endswith(", d2"):
            if tgt: tabs["xa"] = (tgt, "l")
            else:
                v = int(re.match(r"#\$([0-9a-f]+)", op).group(1), 16); tabs["xa"] = (v - (1 << 32) if v & 0x80000000 else v, "imm")
        elif mn == "move.l" and op.endswith("$44(a6)"):
            if tgt: tabs["yv"] = (tgt, "l")
        elif mn == "move.l" and op.endswith("$4c(a6)"):
            if tgt: tabs["ya"] = (tgt, "l")
            else:
                v = int(re.match(r"#\$([0-9a-f]+)", op).group(1), 16); tabs["ya"] = (v - (1 << 32) if v & 0x80000000 else v, "imm")
        if mn == "rts":
            init_end = a
            break
    # raw tables: each pc-relative table runs to the next table start (or 8 words)
    starts = sorted({v[0] for v in tabs.values() if v[1] != "imm"})
    raw = {}
    for name, (addr, kind) in tabs.items():
        if kind == "imm":
            raw[name] = {"imm": addr, "f16": f16(addr)}
            continue
        nxt = min([s for s in starts if s > addr] + [addr + 32])
        raw[name] = {"addr": f"{addr:#x}", "bytes": data[addr:nxt].hex()}
    rows = []
    if shape == "A":
        for i in range(3):   # +0x0A = 0/1/2 (the 8-byte (xv, yv) pairs)
            d = i * 8
            r = {"index": {"+0x0A": i, "+0x9A": i * 2}}
            r["+0x26"] = data[tabs["t26"][0] + i * 2] if tabs["t26"][1] == "b" else int.from_bytes(data[tabs["t26"][0] + i * 2:][:2], "big")
            r["+0x50"] = int.from_bytes(data[tabs["t50"][0] + i * 2:][:2], "big")
            r["xv"] = s32(data[tabs["xv"][0] + d:][:4]); r["xa"] = tabs["xa"][0]
            r["yv"] = s32(data[tabs["yv"][0] + d:][:4]); r["ya"] = tabs["ya"][0]
            rows.append(r)
    else:
        for i in range(0, 8, 2):   # +0x9A even (the byte and word tables share one index)
            if "tix" not in tabs: break
            d = int.from_bytes(data[tabs["tix"][0] + i:][:2], "big")
            r = {"index": {"+0x9A": i, "long_offset": d}}
            r["+0x26"] = data[tabs["t26"][0] + i] if tabs["t26"][1] == "b" else int.from_bytes(data[tabs["t26"][0] + i:][:2], "big")
            r["+0x50"] = int.from_bytes(data[tabs["t50"][0] + i:][:2], "big")
            for f in ("xv", "xa", "yv", "ya"):
                r[f] = tabs[f][0] if tabs[f][1] == "imm" else s32(data[tabs[f][0] + d:][:4])
            rows.append(r)
    for r in rows:
        r["+0x26_kind"] = tabs["t26"][1]   # "b": one byte at +0x26; "w": a word at +0x26/+0x27 (the live byte at +0x26 is its HIGH byte)
        for f in ("xv", "xa", "yv", "ya"):
            r[f + "_f"] = round(f16(r[f]), 4)
    return {"handler": f"{h:#x}", "init": f"{ins[init][0]:#x}", "shape": shape, "tables": raw, "rows": rows}


def main():
    args = sys.argv[1:]
    out = None
    if "--json" in args:
        k = args.index("--json"); out = args[k + 1]; del args[k:k + 2]
    data = open(args[0], "rb").read()
    print(f"# {args[0]}  sha1 {hashlib.sha1(data).hexdigest()}")
    res = [decode(data, int(h, 16)) for h in args[1:]]
    for r in res:
        print(f"handler {r['handler']} shape {r['shape']}" + (f" init {r['init']}" if "init" in r else ""))
        if r["shape"] == "immediate":
            for im in r["immediates"]:
                print(f"  {im['pc']}  {im['field']} = {im['value']:#x} ({im['f16']})")
            continue
        for n, t in r["tables"].items():
            print(f"  {n:4s} " + (f"imm {t['imm']:#x} ({t['f16']})" if "imm" in t else f"{t['addr']} {t['bytes']}"))
        for row in r["rows"]:
            print(f"  idx {row['index']}  +0x26={row['+0x26']} +0x50={row['+0x50']}  xv={row['xv_f']} xa={row['xa_f']} yv={row['yv_f']} ya={row['ya_f']}")
    if out:
        json.dump(res, open(out, "w"), indent=1)


if __name__ == "__main__":
    main()
