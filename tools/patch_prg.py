#!/usr/bin/env python3
"""patch_prg.py — apply a program-ROM patch to a CPS-2 romset, producing new
program files. Chainable (src,out) builder; the null patch is bit-identical.

Everything works in 68k WORD-VALUE space (word index = logical byte addr / 2),
so all addresses match the analysis views (docs/game/atlas: vsavj_opcodes.bin /
vsavj_data.bin are 68k-logical). Byte order is converted only at the file
boundary. The 68k sees big-endian logical words for BOTH data reads and
(post-decryption) opcode fetches, so:
  * data / poke ops set raw word values (the 68k reads them directly).
  * code ops set the ENCRYPTED word values so opcode fetches decrypt to the
    intended instructions (raw if the target is outside the encrypted range).

Usage:
    python3 tools/patch_prg.py <src_set.zip> <out_dir> --patch patch.json
    python3 tools/patch_prg.py <src_set.zip> <out_dir>            # null (copy)

Patch JSON: {"ops":[ ... ]} applied in order. Addresses/lengths are 68k byte
values and must be even (word-aligned). Ops:
  {"op":"poke16","addr":"0xBD9CA","val":"0x1234"}
  {"op":"poke32","addr":"0xBD97A","val":"0x000C8DF8"}   # big-endian long
  {"op":"data","addr":"0xBF69A","hex":"deadbeef"}       # raw logical bytes
  {"op":"data_file","addr":"0xBF69A","path":"blob.bin"} #   (from vsav2 data view)
  {"op":"code","addr":"0xBF800","hex":"4e714e75"}       # plaintext opcodes,
  {"op":"code_file","addr":"0xBF800","path":"code.bin"} #   stored re-encrypted

Prints SHA-1s. The null case must round-trip bit-identically (asserted).
"""

import argparse
import hashlib
import json
import sys
import zipfile
from array import array
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import cps2_decrypt as cps  # noqa: E402


def _int(x):
    return x if isinstance(x, int) else int(x, 0)


def load_stored(zpath):
    """Return (member_names, member_lengths, word_values, keybytes).
    word_values: list of 16-bit ints, index = logical word address."""
    with zipfile.ZipFile(zpath) as zf:
        names = zf.namelist()
        keys = [n for n in names if n.endswith(".key")]
        prgs = sorted((n for n in names if cps._PRG_RE.search(n)),
                      key=lambda n: int(cps._PRG_RE.search(n).group(1)))
        if len(keys) != 1 or not prgs:
            raise SystemExit(f"{zpath}: need 1 .key + program files")
        lengths = []
        blob = b""
        for n in prgs:
            b = zf.read(n)
            lengths.append(len(b))
            blob += b
        keybytes = zf.read(keys[0])
    words = cps.words_from_file_bytes(blob)  # correct word VALUES on any host
    return prgs, lengths, list(words), keybytes


def _raw_words_be(raw):
    """Logical big-endian byte stream -> word values."""
    if len(raw) % 2:
        raise SystemExit("blob must be even length (word-aligned)")
    return [(raw[i] << 8) | raw[i + 1] for i in range(0, len(raw), 2)]


def set_words(words, byte_addr, vals):
    if byte_addr % 2:
        raise SystemExit(f"addr 0x{byte_addr:X} must be word-aligned")
    wi = byte_addr // 2
    if wi + len(vals) > len(words):
        raise SystemExit(f"write at 0x{byte_addr:X} exceeds program ROM")
    words[wi:wi + len(vals)] = vals


def apply_ops(words, keybytes, ops, patchdir):
    cipher = cps.Cipher(keybytes)
    # OP-OVERLAP ASSERTION (14z-65, M3b Phase 0): two ops writing one word is
    # always a generator bug — application order decides the bytes silently
    # (found live: tail_data_ptr[tenant] vs the sound_table ptr row, both at
    # 0x0BF466 on WIDE builds). Word granularity is deliberate: odd-aligned
    # byte pokes are merged with PRISTINE neighbor bytes by the generator, so
    # a second op sharing the word would resurrect vanilla bytes over the
    # first op's write — a real corruption class, not a false positive.
    writer = {}

    def _desc(i):
        o = ops[i]
        d = f"op[{i}] {o['op']}@{o['addr']}"
        if "path" in o:
            d += f" ({o['path']})"
        return d

    def claim(i, byte_addr, nwords):
        wi = byte_addr // 2
        for w in range(wi, wi + nwords):
            j = writer.get(w)
            if j is not None:
                raise SystemExit(
                    f"OP OVERLAP at 0x{w*2:06X}: {_desc(j)} then {_desc(i)} — "
                    f"two ops write the same word and the later silently "
                    f"wins. Fix the generator (explicit ownership); do not "
                    f"reorder ops.")
            writer[w] = i

    for i, op in enumerate(ops):
        kind, addr = op["op"], _int(op["addr"])
        if kind == "poke16":
            vals = [_int(op["val"]) & 0xFFFF]
        elif kind == "poke32":
            v = _int(op["val"]) & 0xFFFFFFFF
            vals = [(v >> 16) & 0xFFFF, v & 0xFFFF]
        elif kind in ("data", "data_file"):
            raw = bytes.fromhex(op["hex"]) if kind == "data" else (patchdir / op["path"]).read_bytes()
            vals = _raw_words_be(raw)
        elif kind in ("code", "code_file"):
            raw = bytes.fromhex(op["hex"]) if kind == "code" else (patchdir / op["path"]).read_bytes()
            vals = cipher.crypt_words_at(_raw_words_be(raw), addr // 2, decrypt=False)
        else:
            raise SystemExit(f"unknown op {kind}")
        claim(i, addr, len(vals))
        set_words(words, addr, vals)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src", type=Path)
    ap.add_argument("out_dir", type=Path)
    ap.add_argument("--patch", type=Path)
    args = ap.parse_args()

    names, lengths, words, keybytes = load_stored(args.src)

    # ── program-image extension (Phase C step 2) ─────────────────────────────
    # The generator states the requirement in patch.json ("image"), because it
    # is what knows the build profile. Grow BEFORE applying ops, so ops may
    # target extension addresses. Fill is 0xFF to match the allocator's
    # "destination must be 0xFF fill" contract.
    #
    # NOTE the CRC consequence: these appended members carry real content, so
    # their CRCs will NOT match the zero-fill CRCs in the emulator descriptors.
    # For PRG members that is tolerated (unlike gfx/QSound, where FBNeo
    # silently substitutes 0xFF fill — docs/GOTCHAS.md). Verified, not assumed:
    # tests/test_phasec_image.sh.
    spec = json.loads(args.patch.read_text()) if args.patch else {}

    # ── SOURCE-SET IDENTITY (14z-94, GitHub #18) ─────────────────────────────
    # A generated patch.json carries only {op, addr, val|hex|path}: no
    # expected-old bytes and, until now, no statement of what it was generated
    # AGAINST. Every old-byte check lives in the generator and runs against the
    # CACHED decrypted views, so nothing joined the verified image to the one
    # written here — these ops would apply at these offsets to ANY zip with one
    # .key and a program member. This docstring even advertises chaining onto
    # "a PREVIOUS BUILDER'S OUTPUT", which is precisely where the generator's
    # premises (0xFF fill at the allocation, dst_old_head at the destination)
    # no longer hold.
    #
    # A MISMATCH IS FATAL. An ABSENT identity is only a warning, because
    # hand-written synthetic patches are legitimate (several gates build one
    # inline) — but every generator-produced patch carries the field, so the
    # real pipeline is covered and the warning names what is unprotected.
    want = spec.get("src_program_identity")
    if want:
        got = cps.program_identity(args.src)
        if got != want:
            raise SystemExit(
                f"{args.src}: source-set mismatch — this patch was generated "
                f"against program identity {want[:16]}..., this zip is "
                f"{got[:16]}.... The old-byte verification behind every op was "
                f"done against a DIFFERENT image; applying it would write "
                f"verified-nowhere bytes. Re-generate against this source, or "
                f"patch the source it was generated from.")
    elif args.patch:
        print(f"  warning: {args.patch} carries no src_program_identity — "
              f"applying it UNVERIFIED against {args.src}", file=sys.stderr)
    image = spec.get("image")
    if image:
        base = sum(lengths)
        target, msize = int(image["extend_to"]), int(image["member_size"])
        fill = int(image.get("fill", 0xFF))
        if target < base or (target - base) % msize:
            raise SystemExit(f"image: bad extend_to {target:#x} from base {base:#x}")
        add = (target - base) // msize
        if add != len(image["member_names"]):
            raise SystemExit("image: member_names count does not match extend_to")
        fillword = (fill << 8) | fill
        words.extend([fillword] * ((target - base) // 2))
        names = list(names) + list(image["member_names"])
        lengths = list(lengths) + [msize] * add
        print(f"image: {base:#x} -> {target:#x} "
              f"(+{add} x {msize:#x}: {', '.join(image['member_names'])}, "
              f"fill {fill:#04x})")

    orig = list(words)

    if args.patch:
        apply_ops(words, keybytes, spec.get("ops", []), args.patch.resolve().parent)
    else:
        print("null patch (no ops)")

    blob = cps.words_to_file_bytes(array("H", words))
    args.out_dir.mkdir(parents=True, exist_ok=True)
    pos = changed = 0
    for name, ln in zip(names, lengths):
        seg = blob[pos:pos + ln]
        (args.out_dir / name).write_bytes(seg)
        tag = "  CHANGED" if words[pos // 2:(pos + ln) // 2] != orig[pos // 2:(pos + ln) // 2] else ""
        if tag:
            changed += 1
        print(f"  {name}  sha1 {hashlib.sha1(seg).hexdigest()}{tag}")
        pos += ln
    if not args.patch and changed:
        raise SystemExit("null patch modified files — bug")
    print(f"{changed} member(s) changed")


if __name__ == "__main__":
    main()
