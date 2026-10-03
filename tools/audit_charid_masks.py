#!/usr/bin/env python3
"""audit_charid_masks.py (14z-189, GitHub #162) — the per-character IMMEDIATE BITMASKS the engine tests
against a fighter's character id, compared between vs2 (native) and our build.

THE SHAPE: `move.l #imm,Dn` followed, within 12 bytes, by an operand word 0x0382 (the `+0x382` char id) and
a register `btst Dm,Dn` testing Dn — e.g. vsavj PRG:0x02ADB2 `move.l #$ef92ef96,d1 / move.b $382(a6),d0 /
btst.l d0,d1 / bne`. A 32-bit mask has one bit per character id (btst on a data register is mod 32), and
vsav keeps its high half (ids 0x10-0x1F) mostly equal to its low half (the aliasing guard). vs2 has its own
characters at 0x10/0x11/0x13 (Phobos, Pyron, Donovan), so where vs2's mask sets or clears a TENANT bit
differently from ours, our build runs vsavj's choice for that tenant — the #162 mechanism (vs2 PRG:0x02A108
0xEF9AEF96 sets bit 0x13; ours/vsavj PRG:0x02ADB2 0xEF92EF96 does not).

PAIRING: each vs2 site is paired to an ours site by the 12 bytes after the immediate (the code around the
test) with branch displacements wildcarded (the routines sit at different addresses); an unpaired vs2 site is printed as such.
NOT COVERED: masks in other shapes (immediate btst, word masks, a mask loaded from a table).

Usage: audit_charid_masks.py <vsav2 opcodes> <our verify_op.bin> [<vsavj opcodes>]  — prints the SHA-1 of
each image read, then one row per vs2 site: `<vs2 pc> <vs2 mask> <ours pc> <ours mask> <vsavj mask>
<tenant bits vs2> <tenant bits ours> SAME|DIFF|UNPAIRED`. With --plant-bit <hexpc>,<bit> the ours mask at
that site is read with that bit flipped (the gate's control).
"""
import hashlib, sys


def sites(b):
    out = []
    for i in range(0, len(b) - 18, 2):
        w = int.from_bytes(b[i:i + 2], "big")
        if (w & 0xF1FF) != 0x203C:          # move.l #imm,Dn
            continue
        n = (w >> 9) & 7
        win = b[i + 6:i + 18]
        if b"\x03\x82" not in win:
            continue
        for j in range(0, len(win) - 1, 2):
            x = int.from_bytes(win[j:j + 2], "big")
            if (x & 0xF1F8) == 0x0100 and (x & 7) == n:   # btst Dm,Dn testing the mask register
                out.append((i, int.from_bytes(b[i + 2:i + 6], "big"), win))
                break
    return out


def sig(win):
    """the 12-byte tail with branch displacements wildcarded: a Bcc/BRA/BSR keeps its condition byte only, and
    a 16-bit displacement word after a Bcc.w (low byte 0) is dropped — vs2's and ours' routines sit at
    different addresses, so their branch offsets differ while the code is the same"""
    ws = [int.from_bytes(win[k:k + 2], "big") for k in range(0, len(win) - 1, 2)]
    out, skip = [], False
    for w in ws:
        if skip:
            out.append("....")
            skip = False
            continue
        if (w & 0xF000) == 0x6000:
            out.append(f"{w >> 8:02x}..")
            skip = (w & 0xFF) == 0
        else:
            out.append(f"{w:04x}")
    return " ".join(out)


def tbits(m):
    return f"{(m >> 0x10) & 1}{(m >> 0x11) & 1}{(m >> 0x13) & 1}"


def main(argv):
    plant = None
    if "--plant-bit" in argv:
        k = argv.index("--plant-bit")
        pc, bit = argv[k + 1].split(",")
        plant = (int(pc, 16), int(bit, 16))
        argv = argv[:k] + argv[k + 2:]
    paths = argv[1:4]
    imgs = [open(p, "rb").read() for p in paths]
    for p, b in zip(paths, imgs):
        print(f"# {p} sha1 {hashlib.sha1(b).hexdigest()}")
    v2, ours = sites(imgs[0]), sites(imgs[1])
    vj = sites(imgs[2]) if len(imgs) > 2 else []
    bysig, vjsig = {}, {}
    for i, m, w in ours:
        if plant and i == plant[0]:
            m ^= 1 << plant[1]
        bysig.setdefault(sig(w), []).append((i, m))
    for i, m, w in vj:
        vjsig.setdefault(sig(w), []).append(m)
    print(f"SITES vs2 {len(v2)} ours {len(ours)} vsavj {len(vj)}")
    for i, m, w in v2:
        o = bysig.get(sig(w), [])
        vm = vjsig.get(sig(w), [])
        if not o:
            print(f"ROW {i:06x} {m:08x} - - {','.join(f'{x:08x}' for x in vm) or '-'} {tbits(m)} - UNPAIRED")
            continue
        for oi, om in o:
            verdict = "SAME" if tbits(om) == tbits(m) else "DIFF"
            print(f"ROW {i:06x} {m:08x} {oi:06x} {om:08x} {','.join(f'{x:08x}' for x in vm) or '-'} {tbits(m)} {tbits(om)} {verdict}")


if __name__ == "__main__":
    main(sys.argv)
