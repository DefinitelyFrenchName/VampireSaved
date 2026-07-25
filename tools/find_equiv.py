#!/usr/bin/env python3
"""find_equiv.py — find a vsav2 engine routine's equivalent in vsavj by
wildcarded instruction-pattern search (the productized M1 method that
located the per-character loader in all three sets).

Takes a window of decrypted code at --addr in the source set, wildcards the
operand bytes that legitimately differ between builds (absolute-address
longs and ROM-plausible immediates, via scan_code_refs), and slides the
masked pattern over the destination set's opcode image, ranking candidates
by matching non-wildcarded bytes.

Usage:
    python3 tools/find_equiv.py <src_set.zip> <dst_set.zip> \
        --addr 0x0280B8 [--len 0x40] [--top 5]

Prints ranked candidate addresses. A score of 1.00 means every
non-wildcarded byte matches — near-certain equivalent; verify with a
write-trace before recording status=verified in reconciliation.toml.
"""

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import cps2_decrypt as cps  # noqa: E402
import scan_code_refs  # noqa: E402


def plaintext_image(zpath):
    words, keybytes, prgs, sha1s = cps.load_set(zpath)
    cipher = cps.Cipher(keybytes)
    pt = cipher.transform(list(words), decrypt=True)
    return bytes(cps.words_to_logical_bytes(pt))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src", type=Path)
    ap.add_argument("dst", type=Path)
    ap.add_argument("--addr", required=True, type=lambda x: int(x, 0))
    ap.add_argument("--len", dest="length", type=lambda x: int(x, 0),
                    default=0x40)
    ap.add_argument("--top", type=int, default=5)
    args = ap.parse_args()

    print(f"decrypting {args.src.name} ...", file=sys.stderr)
    src_img = plaintext_image(args.src)
    print(f"decrypting {args.dst.name} ...", file=sys.stderr)
    dst_img = plaintext_image(args.dst)

    pat = bytearray(src_img[args.addr:args.addr + args.length])
    mask = bytearray(b"\x01" * len(pat))  # 1 = must match
    for ref in scan_code_refs.scan(bytes(pat), args.addr):
        if ref["how"] == "charid_imm":
            continue
        span = ref["width"] // 8
        for i in range(ref["off"], min(ref["off"] + span, len(mask))):
            mask[i] = 0
    hard = mask.count(1)
    if hard < 8:
        sys.exit("window is nearly all operands — widen --len")

    # anchor: longest run of must-match bytes, used with bytes.find
    best_run, run_start, cur_start = (0, 0), 0, None
    for i, m in enumerate(list(mask) + [0]):
        if m and cur_start is None:
            cur_start = i
        elif not m and cur_start is not None:
            if i - cur_start > best_run[0]:
                best_run = (i - cur_start, cur_start)
            cur_start = None
    run_len, run_off = best_run
    anchor = bytes(pat[run_off:run_off + run_len])

    scores = []
    pos = dst_img.find(anchor)
    while pos != -1:
        base = pos - run_off
        if 0 <= base <= len(dst_img) - len(pat):
            match = sum(1 for i in range(len(pat))
                        if mask[i] and dst_img[base + i] == pat[i])
            scores.append((match / hard, base))
        pos = dst_img.find(anchor, pos + 2)

    if not scores:
        # fall back: relax to the first half of the anchor
        anchor2 = anchor[:max(8, run_len // 2)]
        pos = dst_img.find(anchor2)
        while pos != -1:
            base = pos - run_off
            if 0 <= base <= len(dst_img) - len(pat):
                match = sum(1 for i in range(len(pat))
                            if mask[i] and dst_img[base + i] == pat[i])
                scores.append((match / hard, base))
            pos = dst_img.find(anchor2, pos + 2)

    scores.sort(key=lambda s: (-s[0], s[1]))
    print(f"src 0x{args.addr:06X}+0x{args.length:X} ({hard} hard bytes, "
          f"anchor {run_len}B@+{run_off:#x}): {len(scores)} candidates")
    for score, base in scores[:args.top]:
        print(f"  0x{base:06X}  score {score:.2f}")
    if not scores:
        sys.exit(2)


if __name__ == "__main__":
    main()
