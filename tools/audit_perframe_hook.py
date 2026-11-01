#!/usr/bin/env python3
"""audit_perframe_hook.py — is #294's per-frame palette port on a build EXACTLY vs2's routine, re-pointed and nothing
else? (14z-216, GitHub #294; the generator section is [perframe_hook] in tools/gen_donovan_patch.py.)

  python3 tools/audit_perframe_hook.py <build verify_op.bin> <vsavj opcodes.bin> <vs2 opcodes.bin> <vs2 data.bin>
        [--manifest build/manifest/donovan.toml] [--plant unmapped-escape|row-default|record-flip|half-hook|insn-flip|table-flip]

Reads the build's opcode image. STATE: `absent` (the per-frame table PRG:0x02ADEC equals vsavj's on every row and the
dead span PRG:0x024024 holds vsavj's bytes) or `hooked` (row 0x13 -> the dead span, which jumps to the body) — any
other mixture is `half` and fails. When hooked:
  T1 every row of the table other than the manifest's row equals vsavj's; the row's word gives the dead span;
  J  the dead span decodes `jmp <body>.l`;
  B  the body, decoded with the source's inline tables skipped at the same offsets, equals vs2's routine instruction
     for instruction (capstone, mnemonic + operand text) except the routine's EXTERNAL references — found by decoding
     the SOURCE, never read from the manifest — each of which must now land on the stub its target maps to: vs2's rts
     -> `rts`; the block-row re-upload -> `jmp <blk_twin>.l`; the sequence upload -> `subi.w #<first>,d0 / movea.l
     #<records>,a0 / jmp <seq_set+6>.l`; a lea (d16,PC) -> the same offset inside the appended tables;
  D  the inline tables equal vs2's opcode view, the appended tables vs2's data view, and the records block vs2's
     data view at <seq_src_base> + 32*<seq_first> for 32*<seq_count> bytes (compared as bytes, printed as SHA-1).
Prints addresses, counts, mnemonics and hashes only (rule 7). Exit 0 = the state is consistent and every check passes.
--plant: in-memory perturbations of the build image (controls): unmapped-escape restores one re-pointed branch's
vs2 displacement (B fires); row-default writes vsavj's word back into the row (half: the dead span still jumps);
record-flip flips one bit of the records block (D fires); half-hook restores the dead span's vsavj bytes (half);
insn-flip flips one bit of an ORDINARY instruction's immediate (the first cmpi with no external reference: B fires on
the operand text); table-flip flips one bit of the first inline PC-indexed table (D fires) — rule-checker run
2026-11-01-1548 Q4: without them, a check of the re-pointed references alone would pass the same.
"""
import argparse, hashlib, re, sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _minitoml import loads as toml_loads  # noqa: E402


def cs():
    import capstone
    return capstone.Cs(capstone.CS_ARCH_M68K, capstone.CS_MODE_BIG_ENDIAN | capstone.CS_MODE_M68K_000)


def one(md, img, a):
    return next(md.disasm(bytes(img[a:a + 10]), a, count=1), None)


def sext(w):
    return w - 0x10000 if w & 0x8000 else w


def i_(v):
    return v if isinstance(v, int) else int(str(v), 0)


def main():
    ap = argparse.ArgumentParser(usage=__doc__)
    ap.add_argument("build"); ap.add_argument("vsavj"); ap.add_argument("vs2op"); ap.add_argument("vs2data")
    ap.add_argument("--manifest", default="build/manifest/donovan.toml")
    ap.add_argument("--plant", choices=("unmapped-escape", "row-default", "record-flip", "half-hook", "insn-flip", "table-flip"))
    a = ap.parse_args()
    img = bytearray(open(a.build, "rb").read()); vj = open(a.vsavj, "rb").read()
    v2 = open(a.vs2op, "rb").read(); v2d = open(a.vs2data, "rb").read()
    ph = toml_loads(open(a.manifest).read())["perframe_hook"]
    md = cs()
    tbl, row, ds = i_(ph["table"]), i_(ph["row"]), i_(ph["dead_span"])
    s0, slen = i_(ph["src_routine"]), i_(ph["src_len"])
    print(f"# build {a.build} sha1 {hashlib.sha1(img).hexdigest()}")
    print(f"# vsavj sha1 {hashlib.sha1(vj).hexdigest()}; vs2 op sha1 {hashlib.sha1(v2).hexdigest()}")
    # the source routine: decode it, skip its inline PC-indexed tables (a byte table whose bytes follow an
    # unconditional branch or are reached only through (d8,PC,Dn)); found from the SOURCE's own pc-indexed operands
    inline, seen, a_, seq = {}, set(), s0, []
    while a_ < s0 + slen:
        if a_ in inline:
            a_ += inline[a_]; continue
        ins = one(md, v2, a_)
        if ins is None:
            print(f"FAIL  the source routine does not decode at 0x{a_:06X}"); return 1
        for neg, h in re.findall(r"(-?)\$([0-9a-f]+)", ins.op_str):
            if not neg and s0 <= int(h, 16) < s0 + slen:
                seen.add(int(h, 16))
        m = re.search(r"\$([0-9a-f]+)\(pc, d\d", ins.op_str)
        if m and s0 <= int(m.group(1), 16) < s0 + slen:
            t = int(m.group(1), 16)
            # an inline PC-indexed table runs from t to the first branch target past it seen so far (where the
            # routine resumes); none -> the routine's end
            nxt = sorted(x for x in seen if x > t)
            inline[t] = (nxt[0] if nxt else s0 + slen) - t
        seq.append((a_, ins)); a_ += ins.size
    if a_ != s0 + slen:
        print(f"FAIL  the source routine's decode ends at 0x{a_:06X}, not 0x{s0 + slen:06X}"); return 1
    ext = {}
    for pc, ins in seq:
        if ins.mnemonic.startswith(("btst", "bchg", "bclr", "bset")):
            continue
        if ins.mnemonic.startswith(("b", "db", "j", "lea")):
            for neg, h in re.findall(r"(-?)\$([0-9a-f]+)", ins.op_str):
                t = int(h, 16)
                if not neg and not (s0 <= t < s0 + slen) and t > 0x1000 and "(a" not in ins.op_str.split("$" + h)[1][:3]:
                    ext[pc] = (ins.mnemonic, t)
    kind_of = {i_(ph["src_rts"]): "rts", i_(ph["src_blk"]): "blk", i_(ph["src_seq"]): "seq"}
    lt0, ltlen = (i_(x) for x in str(ph["lea_tables"]).split(":"))
    print(f"# source routine vs2 0x{s0:06X} +0x{slen:X}: {len(seq)} instructions, inline tables "
          f"{', '.join(f'0x{t:06X}+{n}' for t, n in sorted(inline.items())) or 'none'}, {len(ext)} external references")
    bad = [f"0x{pc:06X} {m} -> 0x{t:06X}" for pc, (m, t) in ext.items()
           if t not in kind_of and not (m.startswith("lea") and lt0 <= t < lt0 + ltlen)]
    if bad:
        print("FAIL  external references with no mapping: " + "; ".join(bad)); return 1
    rsite = tbl + 2 * row
    # plants
    if a.plant == "row-default":
        img[rsite:rsite + 2] = vj[rsite:rsite + 2]
    if a.plant == "half-hook":
        img[ds:ds + 6] = vj[ds:ds + 6]
    tbl_same = all(img[tbl + 2 * r:tbl + 2 * r + 2] == vj[tbl + 2 * r:tbl + 2 * r + 2] for r in range(32))
    span_vanilla = img[ds:ds + 6] == vj[ds:ds + 6]
    if tbl_same and span_vanilla:
        print("STATE absent: the per-frame table equals vsavj's on all 32 rows and the dead span holds vsavj's bytes")
        return 0
    rw = int.from_bytes(img[rsite:rsite + 2], "big")
    others = [r for r in range(32) if r != row and img[tbl + 2 * r:tbl + 2 * r + 2] != vj[tbl + 2 * r:tbl + 2 * r + 2]]
    j = one(md, img, ds)
    jm = re.fullmatch(r"\$([0-9a-f]+)\.l", j.op_str) if j and j.mnemonic == "jmp" else None
    if others or tbl + sext(rw) != ds or not jm:
        print(f"STATE half: rows differing from vsavj other than 0x{row:X}: {[hex(r) for r in others]}; row 0x{row:X} "
              f"-> 0x{(tbl + sext(rw)) & 0xFFFFFF:06X} (dead span 0x{ds:06X}); dead span decodes "
              f"{(j.mnemonic + ' ' + j.op_str) if j else 'nothing'}")
        print("FAIL  the hook is half-applied"); return 1
    body = int(jm.group(1), 16)
    print(f"STATE hooked: row 0x{row:X} -> 0x{ds:06X}; jmp 0x{body:06X}; the other 31 rows equal vsavj's")
    o_rts, o_blk, o_seq, o_tab = slen, slen + 2, slen + 8, slen + 24
    if a.plant == "unmapped-escape":
        pc0 = sorted(p for p, (m, t) in ext.items() if t in kind_of)[0]
        o = pc0 - s0
        img[body + o + 2:body + o + 4] = v2[pc0 + 2:pc0 + 4]
    if a.plant == "insn-flip":
        # an ORDINARY instruction (no external reference): flip the low bit of the first cmpi's immediate byte
        pc0 = next(p for p, ins in seq if p not in ext and ins.mnemonic.startswith("cmpi"))
        img[body + (pc0 - s0) + 3] ^= 0x01
    if a.plant == "table-flip":
        t0 = sorted(inline)[0]
        img[body + (t0 - s0)] ^= 0x01
    fails = []
    # the stubs
    st_rts = one(md, img, body + o_rts)
    st_blk = one(md, img, body + o_blk)
    s1 = one(md, img, body + o_seq); s2 = one(md, img, body + o_seq + 4); s3 = one(md, img, body + o_seq + 10)
    if not (st_rts and st_rts.mnemonic == "rts"):
        fails.append("the rts stub is not rts")
    if not (st_blk and st_blk.mnemonic == "jmp" and st_blk.op_str == f"${i_(ph['blk_twin']):x}.l"):
        fails.append(f"the block-row stub is not jmp 0x{i_(ph['blk_twin']):X}")
    m2 = re.fullmatch(r"#\$([0-9a-f]+), a0", s2.op_str) if s2 and s2.mnemonic == "movea.l" else None
    if not (s1 and s1.mnemonic == "subi.w" and s1.op_str == f"#${i_(ph['seq_first']):x}, d0" and m2
            and s3 and s3.mnemonic == "jmp" and s3.op_str == f"${i_(ph['seq_set']) + 6:x}.l"):
        fails.append("the private sequence entry is not subi.w #first,d0 / movea.l #records,a0 / jmp seq_set+6")
    recs = int(m2.group(1), 16) if m2 else None
    if a.plant == "record-flip" and recs is not None:
        img[recs + 5] ^= 0x01
    want_stub = {"rts": body + o_rts, "blk": body + o_blk, "seq": body + o_seq}
    # B: instruction for instruction
    nb = 0
    for pc, sins in seq:
        o = pc - s0
        bins = one(md, img, body + o)
        if bins is None or bins.size != sins.size or bins.mnemonic != sins.mnemonic:
            fails.append(f"body +0x{o:X}: {bins.mnemonic if bins else '??'} where vs2 has {sins.mnemonic}"); continue
        if pc in ext:
            m, t = ext[pc]
            bt = [int(h, 16) for neg, h in re.findall(r"(-?)\$([0-9a-f]+)", bins.op_str) if not neg]
            want = want_stub.get(kind_of.get(t)) if t in kind_of else body + o_tab + (t - lt0)
            if not bt or bt[-1] != want:
                fails.append(f"body +0x{o:X} {m}: lands on 0x{bt[-1] if bt else 0:06X}, not 0x{want:06X} "
                             f"(vs2 target 0x{t:06X})")
            nb += 1
            continue
        # internal: operand text equal once both are expressed relative to their routine base
        def rel(s, base):
            return re.sub(r"\$([0-9a-f]+)", lambda mm: (f"<+{int(mm.group(1), 16) - base:x}>"
                          if base <= int(mm.group(1), 16) < base + slen + 0x40 else mm.group(0)), s)
        if rel(bins.op_str, body) != rel(sins.op_str, s0):
            fails.append(f"body +0x{o:X}: '{bins.mnemonic} {bins.op_str}' differs from vs2's '{sins.mnemonic} {sins.op_str}'")
    # D: tables and records
    for t, n in sorted(inline.items()):
        if img[body + (t - s0):body + (t - s0) + n] != v2[t:t + n]:
            fails.append(f"inline table 0x{t:06X}+{n} differs from vs2's opcode view")
    if img[body + o_tab:body + o_tab + ltlen] != v2d[lt0:lt0 + ltlen]:
        fails.append("the appended lea tables differ from vs2's data view")
    rlen = 32 * i_(ph["seq_count"]); rsrc = i_(ph["seq_src_base"]) + 32 * i_(ph["seq_first"])
    if recs is not None:
        got, want = bytes(img[recs:recs + rlen]), v2d[rsrc:rsrc + rlen]
        print(f"# records 0x{recs:06X} +0x{rlen:X}: sha1 {hashlib.sha1(got).hexdigest()[:12]}; vs2 0x{rsrc:06X}: "
              f"sha1 {hashlib.sha1(want).hexdigest()[:12]}")
        if got != want:
            fails.append("the records block differs from vs2's")
    print(f"# body: {len(seq)} instructions compared, {nb} re-pointed references checked")
    for f in fails:
        print(f"FAIL  {f}")
    print("VERDICT " + ("OK" if not fails else f"FAIL ({len(fails)})"))
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
