#!/usr/bin/env python3
"""decode_win_quotes.py — decode and RESOLVE the win-quote text system of
vsavj / vsav2, on the pristine images or on a BUILT image (14z-116).

WHY THIS EXISTS. The three tenants show a host character's win quote because
vsavj's first-level table aliases its variant half (engine_internals.md "THE
WIN-QUOTE TEXT SYSTEM"). Before any byte is moved, the structure has to be
READ — nothing in the tree had ever decoded a single line — and after bytes
move, the FULL selector chain has to be re-walked on the built image for
every (winner, loser, random) triple a tenant can reach, because a wrong
16-bit offset does not crash: it hands the renderer a garbage `len.w` and
the renderer spawns that many objects. That is the silent-poison shape.

THE SYSTEM, as the selector reads it (vsavj `PRG:0x00C87C`, vs2 `0x00B140`;
both decoded 14z-116 from the OPCODE view):

    d0 = $93(a5)                     ; REGION byte, values 0/2/4 (a word index
                                     ; elsewhere), so the ROOT is a 4-long
                                     ; per-region array: bank = root[2*d0]
    d0 = $158(a5)  (winner id)       ; 0x9996 fold applied earlier: 0B->04, 1B->14
    if winner-struct flags ($3b4==0 && $3bc!=0): d0 = 0x20     (vsavj)
    vs2 also forces 0x20 for ids 0x18/0x19 and on $3c3 != 0
    blk = bank + first[d0]           ; FIRST-LEVEL: 0x21 signed words at bank+0
    A   = tableA[d0*32 + loser]      ; 33 rows x 32, pc-relative (OPCODE view)
    d1  = prng() & 0xF               ; $FF80D4 LCG - the random line pick
    L   = tableB[A*16 + d1]          ; 3 rows x 16, pc-relative
    str = blk + second[L]            ; SECOND-LEVEL: 16 signed words at blk+0
    $30(a4) = str                    ; installed into work RAM (RAM:$FFF230)

STRING FORMAT (renderer vsavj `PRG:0x089062`): records of `len.w, code.w[len]`
repeated until `len == 0` (vanilla's longest line is 17 codes and its
longest string 33; the hard bound is the renderer's 66-word buffer, see
MAX_TOTAL); the drawer adds `0x3800`
to each code (masked to 12 bits). Codes are printed as hex — the glyph set
is Capcom's Japanese font and this tool does not pretend to read it; use
`render` on the gfx image to LOOK at a line (tools/render_quote_lines.py).

Every offset is a SIGNED 16-bit displacement: first-level relative to the
BANK base, second-level relative to the winner BLOCK. That is why a tenant
block cannot simply be appended somewhere far away (patch_index.md
"DEFERRED ... win-quote bank relocation").

Usage:
  decode_win_quotes.py dump    <set|data.bin> [--opcodes op.bin] [--region N] [--winner W] [--json out]
  decode_win_quotes.py resolve <set|data.bin> --opcodes op.bin --winner W --loser L [--d1 N|all] [--region N]
  decode_win_quotes.py audit   <data.bin> --opcodes op.bin --pristine <vsavj_data.bin> --pristine-opcodes <op.bin>
                               [--winners 0x10,0x11,0x13] [--bank-lo A --bank-hi B]
      audit = the build-time validator: every (tenant winner x loser 0..0x1F x
      d1 0..15) resolves to a well-formed string inside [bank-lo, bank-hi),
      and every VANILLA winner's chain resolves to the IDENTICAL address and
      bytes as on the pristine image. Exit 1 on any violation.

<set> is `vsavj` or `vsav2` (reads build/out/<set>_data.bin / _opcodes.bin);
a path is a raw 68k-logical data-view image (4 MB pristine or 6 MB WIDE).
Prints the SHA-1 of every image read.
"""
import argparse
import hashlib
import json
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent

# Per-game constants, all decoded from the OPCODE view of the selector.
GAMES = {
    "vsavj": dict(root=0x0112BC, table_a=0x00C912, table_b=0x00C8E2,
                  selector=0x00C87C, prng_var=0xD4, oboro_ids=()),
    "vsav2": dict(root=0x00F954, table_a=0x00B1EA, table_b=0x00B1BA,
                  selector=0x00B140, prng_var=0xD4, oboro_ids=(0x18, 0x19)),
}
FIRST_LEVEL_ENTRIES = 0x21   # winners 0x00-0x1F + the forced 0x20 row
SECOND_LEVEL_ENTRIES = 16    # table B values are 0..15
TABLE_A_ROWS, TABLE_A_COLS = 0x21, 32
TABLE_B_ROWS = 3
# THE REAL BOUND IS THE RENDERER'S OWN BUFFER, MEASURED 14z-116 — not a
# line width. `PRG:0x089062` does `lea $4c(a6),a0` and stores every masked
# code with `move.w d0,(a0)+` until a zero-length record; the next field the
# routine takes an address of is `$d0(a6)`, so the buffer is 0x84 bytes =
# 66 words. Vanilla's own longest line is 17 codes and its longest STRING is
# 33 codes (measured over all 4 banks x 33 winners x 16 lines), so a 16-code
# "line limit" is wrong — vsavj ships 17s. What a bad offset actually
# overruns is this buffer, which is why the audit bounds the TOTAL.
MAX_LINE = 17          # longest single line vsavj ships (measured)
MAX_TOTAL = 66         # words between +0x4C and +0xD0 — the hard overrun bound
MAX_TOTAL_SEEN = 61    # longest string vsavj ships, measured over all four
                       # REGION banks. The four are LANGUAGE variants, not
                       # copies: bank 0 is the Japanese text (16-code lines,
                       # longest string 33) and banks 1-3 are English
                       # (half-width glyphs, lines to 30, strings to 61).
                       # The renderer's per-region advance table at
                       # `PRG:0x0890B6` indexed by the object's +0x39 says the
                       # same thing: 0x10 px for region 0, 0x08 for 1-3.
FONT_BASE = 0x3800
# The pal-0 quote objects use font tiles ~0x3EE5-0x427F plus 0x3820 = space
# (engine_internals.md); as CODES (before +0x3800) that is 0x06E5-0x0A7F and
# 0x0020. Anything outside is reported, not refused — the range is a
# measured envelope, not a law (see tools/audit_quote_font.py for parity).
CODE_SPACE = 0x1020  # observed padding code (renders as blank)


def sha1(p):
    return hashlib.sha1(Path(p).read_bytes()).hexdigest()


def load(path):
    data = Path(path).read_bytes()
    print(f"# {path}  sha1 {hashlib.sha1(data).hexdigest()}  ({len(data)} bytes)")
    return data


def resolve_set(arg, opcodes):
    """Return (game_key, data_bytes, opcode_bytes)."""
    if arg in GAMES:
        d = load(REPO / "build" / "out" / f"{arg}_data.bin")
        o = load(opcodes or REPO / "build" / "out" / f"{arg}_opcodes.bin")
        return arg, d, o
    d = load(arg)
    o = load(opcodes) if opcodes else None
    return "vsavj", d, o


def w(b, a):
    return int.from_bytes(b[a:a + 2], "big")


def sw(b, a):
    return int.from_bytes(b[a:a + 2], "big", signed=True)


def l(b, a):
    return int.from_bytes(b[a:a + 4], "big")


def fold(idx):
    """The 0x9996 winner/loser mapper: pass-through but 0x0B->0x04, 0x1B->0x14."""
    return {0x0B: 0x04, 0x1B: 0x14}.get(idx, idx)


def read_string(b, addr, limit=64):
    """Walk records `len.w code.w[len]` until len==0. Returns (lines, end,
    problems). Never trusts len: a len past the renderer's own buffer is a
    problem, and the walk stops after `limit` records so garbage cannot run
    away."""
    lines, probs, p, n = [], [], addr, 0
    while n < limit:
        ln = w(b, p)
        p += 2
        if ln == 0:
            break
        if ln > MAX_TOTAL:
            probs.append(f"len {ln} > the {MAX_TOTAL}-word buffer at {p - 2:06x}")
            return lines, p, probs
        codes = [w(b, p + 2 * i) for i in range(ln)]
        p += 2 * ln
        lines.append(codes)
        n += 1
    else:
        probs.append(f"no terminator within {limit} records from {addr:06x}")
    tot = sum(len(x) for x in lines)
    if tot > MAX_TOTAL:
        probs.append(f"total {tot} words OVERRUNS the renderer's {MAX_TOTAL}-word buffer")
    elif tot > MAX_TOTAL_SEEN:
        probs.append(f"total {tot} words exceeds vanilla's longest ({MAX_TOTAL_SEEN})")
    if len(lines) > 2:
        probs.append(f"{len(lines)} records (expected <= 2 lines)")
    return lines, p, probs


def bank_base(d, game, region):
    return l(d, GAMES[game]["root"] + 4 * region)


def first_level(d, bank):
    return [sw(d, bank + 2 * i) for i in range(FIRST_LEVEL_ENTRIES)]


def second_level(d, blk):
    return [sw(d, blk + 2 * i) for i in range(SECOND_LEVEL_ENTRIES)]


def table_a(o, game):
    base = GAMES[game]["table_a"]
    return [[o[base + r * TABLE_A_COLS + c] for c in range(TABLE_A_COLS)]
            for r in range(TABLE_A_ROWS)]


def table_b(o, game):
    base = GAMES[game]["table_b"]
    return [[o[base + r * 16 + c] for c in range(16)] for r in range(TABLE_B_ROWS)]


def resolve(d, o, game, winner, loser, d1, region=0, force20=False):
    """Walk the selector chain exactly. Returns a dict with every hop."""
    bank = bank_base(d, game, region)
    wi = fold(winner)
    li = fold(loser)
    if force20 or wi in GAMES[game]["oboro_ids"]:
        wi = 0x20
    fl = sw(d, bank + 2 * wi)
    blk = bank + fl
    a_val = o[GAMES[game]["table_a"] + wi * 32 + li]
    b_val = o[GAMES[game]["table_b"] + a_val * 16 + (d1 & 0xF)]
    off = sw(d, blk + 2 * b_val)
    s = blk + off
    lines, end, probs = read_string(d, s)
    if not (bank <= s < bank + 0x10000):
        probs.append(f"string {s:06x} outside bank window")
    return dict(bank=bank, winner=wi, loser=li, first=fl, block=blk, A=a_val,
                d1=d1 & 0xF, L=b_val, second=off, string=s, end=end,
                lines=lines, problems=probs)


def fmt_line(codes):
    return " ".join(f"{c:04x}" for c in codes)


def cmd_dump(args):
    game, d, o = resolve_set(args.set, args.opcodes)
    region = args.region
    root = GAMES[game]["root"]
    print(f"game {game}  root PRG:0x{root:06X}  regions:",
          " ".join(f"{l(d, root + 4 * i):06x}" for i in range(4)))
    bank = bank_base(d, game, region)
    fl = first_level(d, bank)
    print(f"region {region} bank PRG:0x{bank:06X}")
    print("first-level:", " ".join(f"{x:04x}" for x in fl))
    out = {"game": game, "bank": bank, "first": fl, "winners": {}}
    winners = [args.winner] if args.winner is not None else range(FIRST_LEVEL_ENTRIES)
    for wi in winners:
        blk = bank + fl[wi]
        sl = second_level(d, blk)
        # THE FORCED ROW HAS EXACTLY ONE LINE (measured 14z-116): table A's
        # row 0x20 is uniformly 2 and table B's row 2 is all zeros, so the
        # selector can only ever produce L = 0 there. Its "second-level
        # table" is one entry; slots 1.. are string bytes, and dumping them
        # as offsets is what produces the `len 4128` noise below. Resolve
        # never walks them.
        reach = 1 if wi == 0x20 else SECOND_LEVEL_ENTRIES
        rec = {"block": blk, "second": sl, "lines": []}
        alias = [x for x in range(wi) if fl[x] == fl[wi]]
        tag = f" (alias of {alias[0]:02x})" if alias else ""
        print(f"\nwinner {wi:02x}{tag}: block PRG:0x{blk:06X}  second-level "
              + " ".join(f"{x:04x}" for x in sl))
        if alias and not args.verbose:
            continue
        for li, off in enumerate(sl[:reach]):
            s = blk + off
            lines, end, probs = read_string(d, s)
            rec["lines"].append({"idx": li, "addr": s, "codes": lines, "problems": probs})
            body = " | ".join(fmt_line(c) for c in lines)
            flag = ("  !! " + "; ".join(probs)) if probs else ""
            print(f"  L{li:02d} @{s:06x} [{','.join(str(len(c)) for c in lines)}] {body}{flag}")
        out["winners"][f"{wi:02x}"] = rec
    if args.json:
        Path(args.json).write_text(json.dumps(out, indent=1))
        print(f"# wrote {args.json}")


def cmd_resolve(args):
    game, d, o = resolve_set(args.set, args.opcodes)
    if o is None:
        sys.exit("resolve needs --opcodes (tables A/B are read pc-relatively)")
    d1s = range(16) if args.d1 == "all" else [int(args.d1, 0)]
    for d1 in d1s:
        r = resolve(d, o, game, args.winner, args.loser, d1, args.region, args.force20)
        body = " | ".join(fmt_line(c) for c in r["lines"])
        flag = ("  !! " + "; ".join(r["problems"])) if r["problems"] else ""
        print(f"w{r['winner']:02x} l{r['loser']:02x} d1={d1:2d}: A={r['A']} L={r['L']:2d} "
              f"blk={r['block']:06x} str={r['string']:06x} "
              f"[{','.join(str(len(c)) for c in r['lines'])}] {body}{flag}")


def cmd_audit(args):
    d = load(args.image)
    o = load(args.opcodes)
    pd = load(args.pristine)
    po = load(args.pristine_opcodes)
    game = "vsavj"
    winners = [int(x, 0) for x in args.winners.split(",")]
    bad = 0
    # (1) tenant winners: every reachable triple well-formed and inside the
    # declared window.
    lo, hi = args.bank_lo, args.bank_hi
    seen = set()
    for wi in winners:
        for li in range(0x20):
            for d1 in range(16):
                r = resolve(d, o, game, wi, li, d1)
                probs = list(r["problems"])
                if lo is not None and not (lo <= r["string"] < hi):
                    probs.append(f"string {r['string']:06x} outside [{lo:06x},{hi:06x})")
                if lo is not None and not (lo <= r["block"] < hi):
                    probs.append(f"block {r['block']:06x} outside [{lo:06x},{hi:06x})")
                if sum(len(x) for x in r["lines"]) > MAX_TOTAL:
                    probs.append("string overruns the renderer buffer")
                for ln in r["lines"]:
                    for c in ln:
                        if c != CODE_SPACE and not (0x0600 <= c <= 0x0AFF):
                            probs.append(f"code {c:04x} outside the font envelope")
                            break
                if probs:
                    bad += 1
                    print(f"FAIL tenant w{wi:02x} l{li:02x} d1={d1}: " + "; ".join(probs))
                seen.add(r["string"])
    print(f"tenant chains: {len(winners) * 0x20 * 16} walked, {len(seen)} distinct strings, {bad} bad")
    # (2) vanilla winners: chain identical to pristine, string bytes identical.
    vbad = 0
    for wi in list(range(0x10)) + [0x20]:
        for li in range(0x20):
            for d1 in range(16):
                r = resolve(d, o, game, wi, li, d1, force20=(wi == 0x20))
                p = resolve(pd, po, game, wi, li, d1, force20=(wi == 0x20))
                if r["string"] != p["string"] or d[r["string"]:r["end"]] != pd[p["string"]:p["end"]] \
                        or r["lines"] != p["lines"]:
                    vbad += 1
                    if vbad <= 10:
                        print(f"FAIL vanilla w{wi:02x} l{li:02x} d1={d1}: built {r['string']:06x} vs pristine {p['string']:06x}")
    print(f"vanilla chains: {17 * 0x20 * 16} walked, {vbad} differ from pristine")
    # (3) the vanilla bank bytes and the root array are untouched.
    bank = bank_base(pd, game, 0)
    nb = l(pd, GAMES[game]["root"] + 4)  # region-1 bank follows region 0
    span_same = d[bank:nb] == pd[bank:nb]
    root_same = d[GAMES[game]["root"]:GAMES[game]["root"] + 16] == pd[GAMES[game]["root"]:GAMES[game]["root"] + 16]
    ta = GAMES[game]["table_a"]
    tb = GAMES[game]["table_b"]
    tables_same = o[tb:ta + TABLE_A_ROWS * TABLE_A_COLS] == po[tb:ta + TABLE_A_ROWS * TABLE_A_COLS]
    print(f"vanilla bank {bank:06x}-{nb:06x} byte-identical: {span_same}; root array: {root_same}; tables A/B: {tables_same}")
    ok = bad == 0 and vbad == 0 and root_same and tables_same and (span_same or args.allow_bank_variant_rows)
    if not span_same and args.allow_bank_variant_rows:
        diffs = [i for i in range(bank, nb) if d[i] != pd[i]]
        allowed = {bank + 2 * i + k for i in range(0x10, 0x20) for k in (0, 1)}
        stray = [i for i in diffs if i not in allowed]
        print(f"bank diffs: {len(diffs)} bytes, {len(stray)} outside the variant rows 0x10-0x1F")
        ok = ok and not stray
    print("AUDIT", "PASS" if ok else "FAIL")
    sys.exit(0 if ok else 1)


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("dump")
    p.add_argument("set")
    p.add_argument("--opcodes")
    p.add_argument("--region", type=lambda x: int(x, 0), default=0)
    p.add_argument("--winner", type=lambda x: int(x, 0))
    p.add_argument("--json")
    p.add_argument("--verbose", action="store_true", help="dump aliased winners too")
    p.set_defaults(fn=cmd_dump)
    p = sub.add_parser("resolve")
    p.add_argument("set")
    p.add_argument("--opcodes")
    p.add_argument("--winner", type=lambda x: int(x, 0), required=True)
    p.add_argument("--loser", type=lambda x: int(x, 0), required=True)
    p.add_argument("--d1", default="all")
    p.add_argument("--region", type=lambda x: int(x, 0), default=0)
    p.add_argument("--force20", action="store_true")
    p.set_defaults(fn=cmd_resolve)
    p = sub.add_parser("audit")
    p.add_argument("image")
    p.add_argument("--opcodes", required=True)
    p.add_argument("--pristine", required=True)
    p.add_argument("--pristine-opcodes", required=True)
    p.add_argument("--winners", default="0x10,0x11,0x13")
    p.add_argument("--bank-lo", type=lambda x: int(x, 0))
    p.add_argument("--bank-hi", type=lambda x: int(x, 0))
    p.add_argument("--allow-bank-variant-rows", action="store_true",
                   help="D0 shape: the vanilla bank may differ ONLY at first-level rows 0x10-0x1F")
    p.set_defaults(fn=cmd_audit)
    args = ap.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
