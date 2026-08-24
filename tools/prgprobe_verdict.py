#!/usr/bin/env python3
"""prgprobe_verdict.py — read the 68k program-ROM read probe and say what it saw.

THE QUESTION IT ANSWERS (14z-107 (11), MiSTer slice D4). D4 declares a 6 MB
program window on cores/cps2w. The SDRAM image census proves the CPS-2 WIDE
romset's bytes are PLACED above CPU:$400000; nothing proved the 68k could READ
them, and "profile-on and profile-off are frame-for-frame identical" reads as
"the profile is innocent" only if the decode WORKS -- a dead decode produces
the same identity for the opposite reason. So this tool splits three ways:

  1. no read above CPU:$400000       -> the relocation is not implicated, and
                                        D4 stays UNPROVEN
  2. reads, and the bytes are right  -> D4 works
  3. reads, and the bytes are wrong  -> D4 IS the bug

WHAT IT COMPARES. The probe logs, per completed program-ROM read, the RAW
SDRAM word (`rom_data`) and the word the CPU LATCHED (`rom_dec`, what cpu_din
takes). The raw word is compared against the `.rom` the core downloaded --
`.rom` byte FULL_HEADER + <cpu byte address>, because the 68k program region
is placed at bank-0 offset 0 (cores/cps2w/hdl/jtcps1_sdram.v ROM_OFFSET, and
tools/mister_sdram_census.py checks all 67,108,864 bytes of that placement).
Optionally the same comparison is run against a dumped SDRAM bank 0 image.

THE BYTE ORDER IS DERIVED FROM THE CONTROL, NOT ASSUMED. A 68k word can be
read out of the file two ways and only one of them is right; guessing is how
an instrument produces a confident wrong answer. So both orders are scored on
the LOW sample -- addresses the game is provably executing from -- and the one
that matches ALL of it is then applied to the window. If neither reaches 100%,
the tool refuses instead of picking the better of two wrongs. (Measured on
vsavjw.rom, 14z-107 (11): the low sample scores 2000/2000 under
`rom[off+1]<<8 | rom[off]` and 59/2000 under the other, which is what CPS-2's
ROM_LOAD16_WORD_SWAP means once mra2rom has copied the member bytes verbatim.)

BOTH WORDS ARE JUDGED, AND FOR DIFFERENT REASONS. Below $400000 only the RAW
word can be compared: jtcps2_decrypt substitutes decrypted data for OPCODE
fetches inside the key's range, so `rom_dec` legitimately differs from the
`.rom` there and that difference is Capcom's, not a defect. ABOVE $400000 the
profile writes extension content RAW (cps2_wide.md "B4 prg"), so the CPU must
receive EXACTLY what the `.rom` holds -- and the question this tool exists to
answer is "what byte came back", which is the word the CPU LATCHED. A window
record therefore passes only when the raw word matches the `.rom` AND the CPU
received that raw word. Splitting the two is what makes the diagnosis useful:
raw wrong means the memory path is wrong (decode, slot width, offsets); raw
right and latched wrong means the memory path is FINE and something between
SDRAM and the 68k corrupted it. (Measured 14z-107 (11): the second case. All
ten window fetches were opcode fetches, all ten raw words were the .rom's, and
all ten latched words were the CPS-2 decryptor's output -- slice D5.)

THE INSTRUMENT IS CHECKED AGAINST ITS OWN LABEL FIRST, and that is not
ceremony: the probe's first draft classified reads by `rom_addr[21]` when the
window bit is `rom_addr[22]`, and reported 2,560 reads "above $400000" whose
addresses were all in $38C2A0-$3D8256. Nothing about the COUNT looked wrong.
So every HI record must land inside [$400000,$600000) and every LO record
below $400000, or the tool REFUSES and says the probe is mislabelled --
before any verdict is issued.

THE MUST-FIRE CONTROL IS IN THE SAME FILE. Reads BELOW $400000 are sampled by
the same probe through the same code path, and they are compared the same way.
A zero above the line is evidence only if the count below it is healthy AND
those bytes verify -- otherwise the instrument, not the core, is what is being
measured. The tool REFUSES to issue a verdict when the control is silent.

Usage:
  tools/prgprobe_verdict.py <prgprobe.txt> --rom <vsavjw.rom> [--bank0 <bin>]
"""
import argparse, os, sys, collections

FULL_HEADER = 64          # jtcps1_prom_we.v:58 — 44 header bytes + the 20-byte key
WINDOW_LO   = 0x400000    # the CPS-2 WIDE program extension, CPU addresses
WINDOW_HI   = 0x600000


def be(buf, off):
    return (buf[off] << 8) | buf[off + 1]


def le(buf, off):
    return (buf[off + 1] << 8) | buf[off]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("log")
    ap.add_argument("--rom", required=True, help="the .rom image the core downloaded")
    ap.add_argument("--bank0", help="a dumped SDRAM bank 0 image (optional cross-check)")
    ap.add_argument("--show", type=int, default=8, help="sample records to print")
    a = ap.parse_args()

    rom = open(a.rom, "rb").read()
    print("  rom   %s %d B" % (os.path.basename(a.rom), len(rom)))
    bank0 = open(a.bank0, "rb").read() if a.bank0 else None
    if bank0 is not None:
        print("  bank0 %s %d B" % (os.path.basename(a.bank0), len(bank0)))
    print("  probe %s" % a.log)

    hi, lo, cyc = [], [], []
    summary = None
    for line in open(a.log, "r", errors="replace"):
        f = line.split()
        if not f:
            continue
        if f[0] == "HI" or f[0] == "LO":
            #  KIND frame addr cpu raw fc
            rec = (int(f[1]), int(f[2], 16), int(f[3], 16), int(f[4], 16), int(f[5]))
            (hi if f[0] == "HI" else lo).append(rec)
        elif f[0] == "CYC":
            cyc.append((int(f[1]), f[2], int(f[3], 16), int(f[4])))
        elif f[0] == "PRGPROBE":
            summary = dict(zip(f[1::2], f[2::2]))

    if summary is None:
        sys.exit("FAIL: no PRGPROBE summary line — the probe never reported a frame")
    print()
    print("  == the run, from the probe's last per-frame line ==")
    for k in ("frame", "wide", "cyc", "cyc_hi_rd", "cyc_hi_wr", "rd_hi", "rd_lo",
              "blocks", "first_frame", "first_addr", "min", "max"):
        print("     %-12s %s" % (k, summary.get(k, "?")))

    n_hi   = int(summary["rd_hi"])
    n_lo   = int(summary["rd_lo"])
    n_cyc  = int(summary["cyc_hi_rd"]) + int(summary["cyc_hi_wr"])
    wide   = summary["wide"]

    # ---- the probe against its own label, BEFORE anything is concluded ------
    mis_hi = [r for r in hi if not (WINDOW_LO <= r[1] < WINDOW_HI)]
    mis_lo = [r for r in lo if r[1] >= WINDOW_LO]
    print()
    print("  == the instrument against its own label ==")
    if mis_hi or mis_lo:
        print("     MISLABELLED: %d HI records outside [$%06X,$%06X) and %d LO records at or above $%06X"
              % (len(mis_hi), WINDOW_LO, WINDOW_HI, len(mis_lo), WINDOW_LO))
        for frame, addr, cpu, raw, fc in (mis_hi[:3] + mis_lo[:3]):
            print("        frame %d CPU:$%06X" % (frame, addr))
        print("  REFUSED: the probe's HI/LO discriminator does not agree with the addresses")
        print("  it printed. Fix the probe, not the core — this is exactly the failure the")
        print("  first draft shipped with (rom_addr[21] where the window bit is [22]).")
        return 2
    print("     every one of the %d HI and %d LO records sampled falls on its own side of $%06X"
          % (len(hi), len(lo), WINDOW_LO))

    # ---- the silent-control refusal comes FIRST: with no control sample there
    # ---- is nothing to derive the byte order from, let alone a verdict ------
    if n_lo == 0 or not lo:
        print()
        print("  == the verdict (profile bit: wide_en = %s) ==" % wide)
        print("  REFUSED: the probe counted ZERO reads BELOW $400000 either. The")
        print("  instrument did not fire, so nothing above the line means anything.")
        return 2

    # ---- the byte order, DERIVED from the control ---------------------------
    def score(recs, order):
        n = ok_ = 0
        for frame, addr, cpu, raw, fc in recs:
            off = FULL_HEADER + addr
            if off + 1 >= len(rom):
                continue
            n += 1
            if raw == order(rom, off):
                ok_ += 1
        return ok_, n

    print()
    print("  == the byte order, derived from the control sample ==")
    orders = [("rom[off]<<8|rom[off+1]", be), ("rom[off+1]<<8|rom[off]", le)]
    scores = [(name, f) + score(lo, f) for name, f in orders]
    for name, _f, ok_, n in scores:
        print("     %-24s %6d / %-6d (%5.1f%%)" % (name, ok_, n, 100.0 * ok_ / n if n else 0.0))
    chosen = [t for t in scores if t[3] and t[2] == t[3]]
    if not chosen:
        print("  REFUSED: neither byte order accounts for ALL of the control sample.")
        print("  The comparison procedure itself is wrong; fix that before reading the window.")
        return 2
    order_name, order_fn = chosen[0][0], chosen[0][1]
    print("     -> using %s (it accounts for the whole control sample)" % order_name)

    # ---- the byte comparison, run identically on both classes ---------------
    def verify(recs):
        res = dict(n=0, hit=0, bank=0, dec=0, oob=0, first_bad=None)
        for frame, addr, cpu, raw, fc in recs:
            off = FULL_HEADER + addr
            if off + 1 >= len(rom):
                res["oob"] += 1
                continue
            res["n"] += 1
            if raw == order_fn(rom, off):
                res["hit"] += 1
            elif res["first_bad"] is None:
                res["first_bad"] = (frame, addr, raw, order_fn(rom, off), fc)
            if bank0 is not None and addr + 1 < len(bank0) and raw == order_fn(bank0, addr - FULL_HEADER):
                res["bank"] += 1
            if cpu == raw:
                res["dec"] += 1
        return res

    print()
    print("  == the byte comparison (raw SDRAM word vs the .rom at FULL_HEADER+addr) ==")
    rlo, rhi = verify(lo), verify(hi)
    # ABOVE the window the CPU must receive the raw word: the profile writes
    # extension content RAW, so anything the decryptor substitutes there is
    # corruption. This is the check whose absence made the first run of this
    # tool report "D4 WORKS" over ten fetches the CPU received as garbage.
    hi_latched_bad = [r for r in hi if r[2] != r[3]]
    for tag, r, total in (("LO (control, < $400000)", rlo, n_lo),
                          ("HI (the window, >= $400000)", rhi, n_hi)):
        print("     %-28s sampled %6d of %d" % (tag, r["n"], total))
        if r["n"]:
            print("        matches the .rom   %6d / %6d  (%5.1f%%)"
                  % (r["hit"], r["n"], 100.0 * r["hit"] / r["n"]))
            print("        cpu_word==raw_word %6d / %6d  (the rest are decrypted opcode fetches)"
                  % (r["dec"], r["n"]))
            if r["oob"]:
                print("        OUTSIDE the .rom   %6d" % r["oob"])
            if r["first_bad"]:
                fr, ad, rw, xb, fc = r["first_bad"]
                print("        first mismatch: frame %d CPU:$%06X read %04X, .rom holds %04X, fc %d"
                      % (fr, ad, rw, xb, fc))

    if a.show and hi:
        print()
        print("  == the first %d records above $400000 ==" % min(a.show, len(hi)))
        for frame, addr, cpu, raw, fc in hi[:a.show]:
            off = FULL_HEADER + addr
            want = order_fn(rom, off) if off + 1 < len(rom) else None
            print("     frame %5d CPU:$%06X cpu %04X raw %04X rom %s fc %d"
                  % (frame, addr, cpu, raw, "%04X" % want if want is not None else "----", fc))
    if a.show and cyc:
        print()
        print("  == the first %d 68k bus cycles in CPU:$400000-$5FFFFF ==" % min(a.show, len(cyc)))
        for frame, rw, addr, fc in cyc[:a.show]:
            print("     frame %5d %s CPU:$%06X fc %d" % (frame, rw, addr, fc))
        seen = collections.Counter(c[2] & ~0xFF for c in cyc)
        print("     %d distinct 256-byte pages among the %d logged cycles; commonest: %s"
              % (len(seen), len(cyc),
                 ", ".join("$%06X x%d" % (p, n) for p, n in seen.most_common(4))))

    # ---- the verdict --------------------------------------------------------
    print()
    print("  == the verdict (profile bit: wide_en = %s) ==" % wide)
    if rlo["n"] and rlo["hit"] != rlo["n"]:
        print("  REFUSED: the CONTROL sample does not verify (%d of %d matched the .rom)."
              % (rlo["hit"], rlo["n"]))
        print("  The comparison procedure itself is wrong; fix that before reading the window.")
        return 2
    print("  probe must-fire: %d reads below $400000, and the %d sampled bytes all match the .rom"
          % (n_lo, rlo["n"]))
    if n_hi == 0:
        print("  ANSWER 1: ZERO program-ROM reads above CPU:$400000 in this window.")
        print("            %d 68k bus cycles targeted $400000-$5FFFFF at all." % n_cyc)
        print("            The relocation is not implicated in what the run did;")
        print("            D4 is NOT exercised here and stays UNPROVEN.")
        return 1
    if rhi["n"] and rhi["hit"] != rhi["n"]:
        print("  ANSWER 3: %d reads above CPU:$400000, and the RAW words are WRONG"
              " (%d of %d matched the .rom)." % (n_hi, rhi["hit"], rhi["n"]))
        print("            The MEMORY PATH is the bug — root-cause the decode, the slot")
        print("            width and the offsets, not the driver.")
        return 3
    if hi_latched_bad:
        print("  ANSWER 3: %d reads above CPU:$400000. The raw words are ALL correct, and"
              % n_hi)
        print("            %d of %d sampled records reached the CPU as something ELSE."
              % (len(hi_latched_bad), rhi["n"]))
        print("            The memory path is FINE; something between SDRAM and the 68k")
        print("            corrupts it. fc of the affected records: %s"
              % ", ".join(sorted({str(r[4]) for r in hi_latched_bad})))
        if all(r[4] & 3 == 2 for r in hi_latched_bad):
            print("            All of them are OPCODE fetches (fc[1:0]==2'b10), which is")
            print("            precisely what jtcps2_dec_ctrl gates on: the CPS-2 DECRYPTOR.")
        return 3
    print("  ANSWER 2: %d reads above CPU:$400000; every sampled RAW word is the .rom's"
          % n_hi)
    print("            AND the CPU received it. The 6 MB decode delivers. D4 WORKS.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
