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

THIS FILE OWNS THE MATCHER (14z-95, GitHub #43(a)). `masked_search` below is
importable and parameterised, and `reconcile_batch.py` calls it instead of
carrying the copy it had drifted away from. The CLI here takes the permissive
parameters (score every hit, relax the anchor on a miss); the batch tool is
pinned to its own measured values. Do not re-inline this anywhere: the two
tools disagreeing about the same input is the defect #43 records.
"""

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import cps2_decrypt as cps  # noqa: E402
import scan_code_refs  # noqa: E402


class WindowUnusable(Exception):
    """The window is almost entirely wildcarded operands.

    A DISTINCT signal from "no candidate found" (GitHub #43, drift (c)).
    The batch tool used to return [] here, which the caller could not tell
    apart from a genuine miss, so an unusable WINDOW was recorded as an
    unresolvable TARGET and the row was left open for the wrong reason.
    """


def masked_search(src_img, dst_img, addr, length, *,
                  hit_cap=None, allow_fallback=True):
    """THE wildcarded-instruction matcher. One implementation, two callers.

    Wildcards the operand bytes that legitimately differ between builds,
    anchors on the longest must-match run, and scores every candidate.
    Returns [(score, base), ...] sorted best-first; [] means no candidate.

    WHY IT IS PARAMETERISED (GitHub #43, maintainer-ruled 2026-08-18).
    `reconcile_batch.py` carried a COPY of this function that had drifted in
    three ways, so the human-facing tool and the machine one gave different
    answers for the same input. The copy is deleted; the differences it had
    accumulated survive as arguments, because they are real choices and the
    batch tool's current values are load-bearing on 357 committed rows:

      hit_cap        None = score every anchor hit (this tool's behaviour).
                     An int stops the sweep once that many hits are
                     collected — and note the cap lands BEFORE the score
                     sort, so it keeps the first N by ADDRESS, not the best
                     N. That is why it is a cap and not a `--top`.
      allow_fallback True = when the full anchor scores nothing, retry with
                     its first half. The batch tool has never done this,
                     which is why a target this tool resolves interactively
                     can be recorded as `open`.

    The batch tool is pinned to (64, False) — its measured behaviour today,
    NOT a better one. Changing either value re-resolves rows and therefore
    moves built bytes, which is CLAUDE.md rule 6 and a separate, ratified
    step (#43(b)). Measured before the refactor landed, over all 328
    reconciliation rows x 5 retry windows: identical results at (64, False)
    on 1640 of 1640 probes, and 183 of 1640 CHANGE at (None, True) — so the
    parameters are inert as pinned and genuinely decide results when freed.
    """
    pat = bytearray(src_img[addr:addr + length])
    mask = bytearray(b"\x01" * len(pat))  # 1 = must match
    for ref in scan_code_refs.scan(bytes(pat), addr):
        if ref["how"] == "charid_imm":
            continue
        span = ref["width"] // 8
        for i in range(ref["off"], min(ref["off"] + span, len(mask))):
            mask[i] = 0
    hard = mask.count(1)
    if hard < 8:
        raise WindowUnusable(
            f"window {addr:#x}+{length:#x} is nearly all operands "
            f"({hard} hard bytes) — widen it")

    # anchor: longest run of must-match bytes, used with bytes.find
    best_run, cur_start = (0, 0), None
    for i, m in enumerate(list(mask) + [0]):
        if m and cur_start is None:
            cur_start = i
        elif not m and cur_start is not None:
            if i - cur_start > best_run[0]:
                best_run = (i - cur_start, cur_start)
            cur_start = None
    run_len, run_off = best_run
    anchor = bytes(pat[run_off:run_off + run_len])

    def sweep(needle):
        out = []
        pos = dst_img.find(needle)
        while pos != -1:
            if hit_cap is not None and len(out) >= hit_cap:
                break
            base = pos - run_off
            if 0 <= base <= len(dst_img) - len(pat):
                match = sum(1 for i in range(len(pat))
                            if mask[i] and dst_img[base + i] == pat[i])
                out.append((match / hard, base))
            pos = dst_img.find(needle, pos + 2)
        return out

    scores = sweep(anchor)
    if not scores and allow_fallback:
        scores = sweep(anchor[:max(8, run_len // 2)])
    scores.sort(key=lambda s: (-s[0], s[1]))
    return scores


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

    # the human-facing tool takes the permissive parameters: score every
    # anchor hit, and relax the anchor when the full one finds nothing
    try:
        scores = masked_search(src_img, dst_img, args.addr, args.length,
                               hit_cap=None, allow_fallback=True)
    except WindowUnusable as e:
        sys.exit(f"{e} (widen --len)")

    print(f"src 0x{args.addr:06X}+0x{args.length:X}: "
          f"{len(scores)} candidates")
    for score, base in scores[:args.top]:
        print(f"  0x{base:06X}  score {score:.2f}")
    if not scores:
        sys.exit(2)


if __name__ == "__main__":
    main()
