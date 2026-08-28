#!/usr/bin/env python3
"""scan_quote_window.py — is there free ROM within signed-16-bit reach of the
win-quote bank base? (14z-116; re-derives the 14z-76 claim as a script.)

WHY THIS EXISTS. `patch_index.md` "DEFERRED BY MAINTAINER DECISION (14z-76)
— the win-quote bank relocation" rests on one measurement: "that window was
scanned: ZERO free bytes — not one run of 0x40 bytes of 00/FF". That
sentence was the whole reason the cheap fix was ruled impossible and the
whole-bank relocation named as the only path — and it existed nowhere as
code, so nobody could re-run it, vary the threshold, or check the second hop.
This is that scan.

WHAT THE REACH ACTUALLY IS. Two hops, both SIGNED 16-bit:
  first-level:  a winner's block = bank + int16(first[winner])
  second-level: a string = block + int16(second[L])
so a ported block must sit within +/-0x8000 of the BANK BASE, and its strings
within +/-0x8000 of the BLOCK. `--hops 2` therefore also scans around each
existing block, which is the window a block appended next to an existing one
could use.

A "free run" here is a run of identical 0x00 or 0xFF bytes — the only two
fills this project ever treats as unclaimed, and even then only outside the
base image (`gen_donovan_patch.alloc`'s 0xFF contract). Inside a 4 MB
reference image a run of 00 is NOT proof of deadness: it may be real data
that happens to be zero. So this tool REPORTS candidates; it does not certify
them free. Anything it found would still owe the deadness-register treatment
(a measured claim, a named guard, a positive control).

Usage:
  scan_quote_window.py <data.bin> [--bank 0x32D28A] [--reach 0x8000]
                       [--min-run 0x20] [--hops 1|2] [--root 0x0112BC]
Prints the SHA-1 of the image read.
"""
import argparse
import hashlib
from pathlib import Path


def runs(d, lo, hi, minlen):
    out, i = [], max(lo, 0)
    hi = min(hi, len(d))
    while i < hi:
        v = d[i]
        if v in (0x00, 0xFF):
            j = i
            while j < hi and d[j] == v:
                j += 1
            if j - i >= minlen:
                out.append((i, j - i, v))
            i = j
        else:
            i += 1
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("image")
    ap.add_argument("--bank", type=lambda x: int(x, 0), default=0x32D28A)
    ap.add_argument("--root", type=lambda x: int(x, 0), default=0x0112BC)
    ap.add_argument("--reach", type=lambda x: int(x, 0), default=0x8000)
    ap.add_argument("--min-run", type=lambda x: int(x, 0), default=0x20)
    ap.add_argument("--hops", type=int, choices=(1, 2), default=2)
    a = ap.parse_args()

    d = Path(a.image).read_bytes()
    print(f"# {a.image}  sha1 {hashlib.sha1(d).hexdigest()}  ({len(d)} bytes)")
    sw = lambda x: int.from_bytes(d[x:x + 2], "big", signed=True)  # noqa: E731

    banks = [int.from_bytes(d[a.root + 4 * i:a.root + 4 * i + 4], "big") for i in range(4)]
    print("# region banks: " + " ".join(f"{b:06x}" for b in banks)
          + "   (the four are LANGUAGE variants — see engine_internals.md)")

    total = 0
    lo, hi = a.bank - a.reach, a.bank + a.reach
    r = runs(d, lo, hi, a.min_run)
    total += len(r)
    print(f"hop 1  bank {a.bank:06x} +/-{a.reach:#x} -> [{lo:06x},{hi:06x}): "
          f"{len(r)} run(s) of >= {a.min_run:#x} bytes of 00/FF"
          + ("" if not r else "  " + ", ".join(f"{x:06x}x{n:#x}({v:#04x})" for x, n, v in r)))

    if a.hops == 2:
        first = [sw(a.bank + 2 * i) for i in range(0x21)]
        blocks = sorted({a.bank + f for f in first})
        found = []
        for b in blocks:
            for x, n, v in runs(d, b - a.reach, b + a.reach, a.min_run):
                found.append((b, x, n, v))
        # de-duplicate by run start: the blocks' windows overlap heavily
        uniq = {}
        for b, x, n, v in found:
            uniq.setdefault((x, n, v), []).append(b)
        total += len(uniq)
        print(f"hop 2  {len(blocks)} distinct winner blocks, each +/-{a.reach:#x}: "
              f"{len(uniq)} distinct run(s)")
        for (x, n, v), bs in sorted(uniq.items())[:20]:
            print(f"        {x:06x} x{n:#x} of {v:#04x}  reachable from {len(bs)} block(s)")

    print(f"VERDICT: {total} candidate run(s). "
          + ("Appending in reach is IMPOSSIBLE — the whole bank must move, or the "
             "lookup must be diverted for tenant winners only."
             if total == 0 else
             "Candidates found — each still owes a deadness proof with a positive "
             "control before a single byte is written there (STATE 'THE DEADNESS "
             "REGISTER')."))


if __name__ == "__main__":
    main()
