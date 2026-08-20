#!/usr/bin/env python3
"""audit_pointer_flow.py — the composed-output pointer/flow comb (14z-100).

Scans a build dir's patch/patch.json (the op list actually applied to the
image) and classifies EVERY address the patch introduces:

  * op destinations           — every byte the patch writes must land inside
                                the 6MB WIDE program space;
  * poke32 values             — the vanilla-site repoints (the class with no
                                structural validator before this tool);
  * abs.l operands in code    — via tools/scan_code_refs.scan (opcode-context
                                triage: jsr/jmp/lea/pea/movea/move/cmpi);
  * bare longs in data        — pointer tables (the #92 class lived here).

Target classes:
  PATCHED     inside a byte range this patch writes (sub-tagged TRIPWIRE
              when the target is one of the planted 4AFC ILLEGALs — an
              unresolved reference, deferred LOUDLY by design);
  VANILLA     < 0x400000 and not patched — the stock image (presumed valid:
              the superset-invariant corpus guards its behavior);
  RAM         work/hardware RAM (24-bit masked >= 0xFF0000);
  SENTINEL    exactly 0x00400000 — the vanilla table-terminator value. NOT
              dereferenceable: a consumer walking past its family reads
              open bus here (GitHub #92). Bucketed separately, not flagged.
  WIDE-HOLE   0x400000..0x5FFFFF but NOT written by the patch — nothing is
              there but fill. A code-context pointer here is a FLAG.
  IO-OTHER    0x600000..0xFEFFFF (CPS registers, QSound, mirrors) — FLAG
              only in code context.

Verdict: FLAGGED findings (WIDE-HOLE any context, IO-OTHER code context,
op extents outside the image) are compared against a frozen baseline file
when --baseline is given: any finding NOT in the baseline fails (growth),
any baseline line no longer found fails (the build under test is not the
frozen one). Without --baseline, prints everything and exits 0 (survey
mode, for producing the register).

Usage:
  tools/audit_pointer_flow.py <builddir> [--baseline FILE] [--md OUT.md]

The tool reads only build outputs (patch/patch.json + the *_file blobs +
placements.json); it never touches $ROMDIR (rule 7 clean).
"""
import argparse
import json
import os
import struct
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import scan_code_refs  # noqa: E402

WIDE_TOP = 0x600000
STOCK_TOP = 0x400000
SENTINEL = 0x400000  # the exact value 0x00400000 as a stored long

# CPS-2 hardware windows, from MAME's authoritative map
# (emu/mame/src/mame/capcom/cps2.cpp:1282-1314). Accesses here are normal
# hardware I/O, never flagged. 0x400000-0x40000F is the CpsFrg output
# share — RESERVED on the WIDE profile (read-shadowed by ROM, HANDOFF).
HW_WINDOWS = (
    (0x400000, 0x400010),   # CPS2 object output / WIDE reserved
    (0x618000, 0x61A000),   # QSound shared RAM
    (0x620000, 0x620030),   # comm board
    (0x660000, 0x664002),   # optional add-on RAM + enable
    (0x700000, 0x702000),   # object RAM (direct)
    (0x708000, 0x710000),   # object RAM (mirrored window)
    (0x800100, 0x800180),   # CPS-A/B mirrors
    (0x804000, 0x804200),   # inputs / EEPROM / volume / objram bank
    (0x900000, 0x930000),   # video RAM
)


def in_hw(t):
    return any(s <= t < e for s, e in HW_WINDOWS)


def op_length(op, patchdir):
    if "hex" in op:
        return len(op["hex"]) // 2
    if op["op"] == "poke32":
        return 4
    if op["op"] == "poke16":
        return 2
    if "path" in op:
        return os.path.getsize(os.path.join(patchdir, op["path"]))
    raise SystemExit(f"unknown op shape: {op}")


def payload(op, patchdir):
    if "hex" in op:
        return bytes.fromhex(op["hex"])
    if "path" in op:
        return open(os.path.join(patchdir, op["path"]), "rb").read()
    return b""


def merge_intervals(iv):
    iv = sorted(iv)
    out = []
    for s, e in iv:
        if out and s <= out[-1][1]:
            out[-1][1] = max(out[-1][1], e)
        else:
            out.append([s, e])
    return out


PRG_MEMBERS = [  # member -> base (file bytes are LE-word order)
    ("vm3j.03d", 0x000000), ("vm3j.04d", 0x080000), ("vm3j.05a", 0x100000),
    ("vm3j.06b", 0x180000), ("vm3j.07b", 0x200000), ("vm3j.08a", 0x280000),
    ("vm3j.09b", 0x300000), ("vm3j.10b", 0x380000),
    ("vsw.41", 0x400000), ("vsw.42", 0x480000),
    ("vsw.43", 0x500000), ("vsw.44", 0x580000),
]


class Image:
    """The patch op map PLUS the shipped image bytes. The op map alone
    under-counts content: the gfx/select channel writes PRG-space pools
    (e.g. the win_pal thunk's palette pools at 0x4C41E0/0x4CA180) into
    the vsw.* members outside patch.json — measured 14z-100, the reason
    'hole' is decided on the ARTIFACT's bytes, not the op list."""

    def __init__(self, ops, patchdir, builddir):
        self.written = merge_intervals(
            (int(o["addr"], 16), int(o["addr"], 16) + op_length(o, patchdir))
            for o in ops)
        self.tripwires = {int(o["addr"], 16) for o in ops
                          if o["op"] == "code" and o.get("hex") == "4afc"}
        self.prg = None
        zp = os.path.join(builddir, "rompath", "vsavjw.zip")
        if os.path.exists(zp):
            import zipfile
            img = bytearray(WIDE_TOP)
            with zipfile.ZipFile(zp) as z:
                have = set(z.namelist())
                for name, base in PRG_MEMBERS:
                    if name not in have:
                        continue
                    raw = z.read(name)
                    sw = bytearray(len(raw))   # LE-word file order -> logical
                    sw[0::2] = raw[1::2]
                    sw[1::2] = raw[0::2]
                    img[base:base + len(sw)] = sw
            self.prg = bytes(img)

    def is_written(self, a):
        import bisect
        i = bisect.bisect_right(self.written, [a, WIDE_TOP + 1]) - 1
        return i >= 0 and self.written[i][0] <= a < self.written[i][1]

    def is_fill(self, a):
        """True when the shipped image holds only fill at a (16b window)."""
        if self.prg is None:
            return True   # no image available: fall back to the op map
        w = self.prg[a & ~1:(a & ~1) + 16]
        return len(set(w)) == 1 and w[0] in (0x00, 0xFF)

    def classify(self, target, strength):
        """strength: 'strong' (address-register/flow context or poke32),
        'weak' (move-immediate: may be a plain constant), 'data' (bare
        long in a data payload). Returns (class, flag_tier|None)."""
        t = target & 0xFFFFFF if target >= 0x1000000 else target
        # 68k 24-bit bus: high byte ignored; normalise
        if t >= 0xFF0000:
            return "RAM", None
        if target == SENTINEL:
            return "SENTINEL", None
        if in_hw(t):
            return "HW", None
        if self.is_written(t):
            return ("PATCHED-TRIPWIRE" if t in self.tripwires else "PATCHED"), None
        if t < STOCK_TOP:
            return "VANILLA", None
        if t < WIDE_TOP and not self.is_fill(t):
            return "WIDE-CONTENT", None    # gfx/select-channel content
        if t < WIDE_TOP:
            if strength == "strong":
                return "WIDE-HOLE", "STRONG"
            if strength == "weak":
                return "WIDE-HOLE", "WEAK"
            # data long: packed non-pointer data dominates; only an EVEN
            # value is even dereferenceable — report those, WEAK tier
            return "WIDE-HOLE", ("WEAK" if t % 2 == 0 else None)
        return "IO-OTHER", ("STRONG" if strength == "strong" else None)


def scan_data_longs(blob, base):
    """Aligned bare longs that look like pointers (the #92 table class)."""
    for i in range(0, len(blob) - 3, 2):
        v = struct.unpack(">I", blob[i:i + 4])[0]
        if 0x1000 <= v < WIDE_TOP or (v & 0xFFFFFF) >= 0xFF0000:
            yield base + i, v


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("builddir")
    ap.add_argument("--baseline")
    ap.add_argument("--md")
    args = ap.parse_args()

    patchdir = os.path.join(args.builddir, "patch")
    doc = json.load(open(os.path.join(patchdir, "patch.json")))
    ops = doc["ops"]
    img = Image(ops, patchdir, args.builddir)

    counts = {}
    flagged = []   # (tier, kind, where, target, cls)

    def note(kind, where, target, strength):
        cls, tier = img.classify(target, strength)
        counts[cls] = counts.get(cls, 0) + 1
        if tier:
            flagged.append((tier, kind, where, target, cls))

    # 1. op extents
    for o in ops:
        a = int(o["addr"], 16)
        ln = op_length(o, patchdir)
        if not (0 <= a and a + ln <= WIDE_TOP):
            flagged.append(("STRONG", "op-extent", o["addr"], a + ln, "OFF-IMAGE"))
    # 2. poke32 values (the repoint class)
    for o in ops:
        if o["op"] == "poke32":
            v = int(o["val"], 16)
            if v >= 0x1000000 and (v & 0xFFFFFF) < 0xFF0000:
                counts["NONADDR"] = counts.get("NONADDR", 0) + 1
                continue   # packed data words (e.g. hud_name_entry pairs)
            note("poke32", o["addr"], v, "strong")
    # 3. code payload operands (opcode-context triage)
    WEAK_HOWS = {"bare_long", "move_imm", "move_src", "cmpi_l"}
    for o in ops:
        if o["op"] in ("code", "code_file"):
            blob = payload(o, patchdir)
            base = int(o["addr"], 16)
            for ref in scan_code_refs.scan(blob, base):
                if ref.get("how") == "charid_imm" or ref.get("target") is None:
                    continue
                strength = "weak" if ref["how"] in WEAK_HOWS else "strong"
                note(f"code:{ref['how']}",
                     f"{o['addr']}+{ref['off']:#x}", ref["target"], strength)
    # 4. data payload bare longs
    for o in ops:
        if o["op"] in ("data", "data_file"):
            blob = payload(o, patchdir)
            base = int(o["addr"], 16)
            for where, v in scan_data_longs(blob, base):
                note("data:long", f"{where:#x}", v, "data")

    lines = [f"{tier}\t{kind}\t{where}\t{t:#x}\t{cls}"
             for tier, kind, where, t, cls in sorted(flagged)]

    print(f"pointer-flow: {len(ops)} ops, {len(img.tripwires)} tripwires, "
          f"classes: " + ", ".join(f"{k}={v}" for k, v in sorted(counts.items())))
    n_strong = sum(1 for t, *_ in flagged if t == "STRONG")
    print(f"FLAGGED: {len(lines)} ({n_strong} STRONG)")
    for ln in lines:
        print("  " + ln)

    if args.md:
        with open(args.md, "w") as f:
            f.write("| tier | kind | where | target | class |\n|---|---|---|---|---|\n")
            for tier, kind, where, t, cls in sorted(flagged):
                f.write(f"| {tier} | {kind} | {where} | {t:#x} | {cls} |\n")

    if args.baseline:
        # Frozen expectation: STRONG findings verbatim (each was REVIEWED —
        # the two shipped ones are the win_pal sparse-block BIASED BASES,
        # verified benign 14z-100 via the 5*row markers), plus per-kind
        # WEAK counts (packed-data noise churns; its GROWTH is the signal).
        from collections import Counter
        wc = Counter(kind for t, kind, *_ in flagged if t == "WEAK")
        have = ([ln for ln in lines if ln.startswith("STRONG")] +
                [f"WEAK-COUNT\t{k}\t{n}" for k, n in sorted(wc.items())])
        want = [ln.rstrip("\n") for ln in open(args.baseline)
                if ln.strip() and not ln.startswith("#")]
        grown = [ln for ln in have if ln not in want]
        gone = [ln for ln in want if ln not in have]
        if grown:
            print(f"FAIL: {len(grown)} finding(s) NOT in baseline (growth):")
            for ln in grown:
                print("  + " + ln)
        if gone:
            print(f"FAIL: {len(gone)} baseline line(s) no longer found "
                  f"(not the frozen build?):")
            for ln in gone:
                print("  - " + ln)
        sys.exit(1 if (grown or gone) else 0)


if __name__ == "__main__":
    main()
