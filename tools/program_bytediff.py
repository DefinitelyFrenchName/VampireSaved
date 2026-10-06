#!/usr/bin/env python3
"""program_bytediff.py — a freeze's WHOLE program change, byte by byte (14z-192; promoted from the scratch
build/agent192/m23/freeze/program_bytediff.py after rule-checker run 2026-10-06-699).

WHY. A freeze's delta was read as OP SETS (patch.json ops keyed by op, address and content) and attributed op by op
with tools/attribute_patch_delta.py. Neither sees a byte that changes INSIDE a placed data file whose op is kept — the
op's key names the file, not its bytes — and attribute_patch_delta.py reads the NEW build's gen.log, which the solo
tracks do not write, so on them it does not run at all. That is the class M22's #194 byte was (one byte inside the
placed fixed_hitbox_proj.bin). This tool reads no op list: it decrypts each build's OWN romset (tools/cps2_decrypt.py,
the opcode view and the data view) and lists every byte range that differs in either view, so nothing the program
carries can change unseen.

CONTROL. On M21 -> M22 (pyron44 -> pyron45) it shows #194's byte at PRG:0x0FDF69 (data 4F -> 44, inside the file
placed at 0x0FDC70) beside #195's three sites and two thunks, and hui59 -> hui60 shows 0 bytes, as registered
(build/agent192/m23/freeze/program_bytediff_control.txt). The opcode and data views differ in which bytes they show
for one word (the encryption is per word), so a one-byte data change can read as two opcode bytes: compare WORDS.

Usage: python3 tools/program_bytediff.py [--record] <OLD build dir> <NEW build dir> [<OLD> <NEW> ...]
  Reads <dir>/rompath/vsavjw.zip (else vsavj.zip); prints, per pair, the range count and byte count in each view
  and every differing range (address, old and new bytes, truncated to 12 bytes). Static; no emulator.
  --record (#231 part 2, 14z-193): the same ranges with NO BYTES — each range's view, span and length, and per pair
  the sha1 of each whole decrypted view, old and new — the form tests/expected/freeze_bytediff/ commits. The bytes
  are reference-ROM bytes, which may never enter the tree (CLAUDE.md rule 7), and neither may a per-range hash: a
  1- or 2-byte range's sha1 is its bytes by brute force. A whole 4 MiB image's sha1 is not.
"""
import hashlib, os, subprocess, sys, tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def views(d):
    rp = os.path.join(d, "rompath")
    z = os.path.join(rp, "vsavjw.zip")
    if not os.path.exists(z):
        z = os.path.join(rp, "vsavj.zip")
    if not os.path.exists(z):
        sys.exit(f"program_bytediff: no vsavjw.zip or vsavj.zip under {rp}")
    t = tempfile.mkdtemp()
    subprocess.run([sys.executable, os.path.join(REPO, "tools", "cps2_decrypt.py"), z, t + "/op.bin",
                    "--data-out", t + "/data.bin"], capture_output=True, check=True)
    return open(t + "/op.bin", "rb").read(), open(t + "/data.bin", "rb").read()


def ranges(a, b):
    n = max(len(a), len(b))
    a, b = a.ljust(n, b"\0"), b.ljust(n, b"\0")
    out, i = [], 0
    while i < n:
        if a[i] != b[i]:
            j = i
            while j < n and a[j] != b[j]:
                j += 1
            out.append((i, j - 1, a[i:j].hex(), b[i:j].hex()))
            i = j
        else:
            i += 1
    return out


def main(argv):
    record = bool(argv) and argv[0] == "--record"
    if record:
        argv = argv[1:]
    if len(argv) < 2 or len(argv) % 2:
        sys.exit(__doc__.split("Usage: ")[1])
    for x, y in zip(argv[0::2], argv[1::2]):
        (ox, dx), (oy, dy) = views(x), views(y)
        ro, rd = ranges(ox, oy), ranges(dx, dy)
        if record:
            sh = lambda v: hashlib.sha1(v).hexdigest()
            print(f"PAIR {x} {y} op {len(ro)} data {len(rd)}")
            print(f"IMAGES op {sh(ox)} -> {sh(oy)} data {sh(dx)} -> {sh(dy)}")
            for tag, rs in (("op", ro), ("data", rd)):
                for i, j, _a, _b in rs:
                    print(f"RANGE {tag} 0x{i:06x}-0x{j:06x} len {j - i + 1}")
            continue
        print(f"== {x} -> {y}: opcode view {len(ro)} range(s), {sum(r[1] - r[0] + 1 for r in ro)} byte(s); "
              f"data view {len(rd)} range(s), {sum(r[1] - r[0] + 1 for r in rd)} byte(s)")
        for tag, rs in (("op  ", ro), ("data", rd)):
            for i, j, a, b in rs:
                print(f"   {tag} 0x{i:06x}-0x{j:06x}  {a[:24]} -> {b[:24]}")


if __name__ == "__main__":
    main(sys.argv[1:])
