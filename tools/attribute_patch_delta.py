#!/usr/bin/env python3
"""attribute_patch_delta.py — attribute one build's patch against another's, OP BY OP, so a freeze's
program delta is EXPLAINED byte class by byte class before it ships (14z-170; promoted from the
scratch build/rc170/delta_ops.py, whose run found the x2b7ef4 placeholder corruption — docs/project/
gotchas.md "A RESOLVER THAT SCANS IN PLACE READS ITS OWN OUTPUT").

The two patch.json op lists are ALIGNED by (kind, length) with difflib, so inserted and deleted ops
are named rather than shifting every later pair; each op's logical bytes are read (data/code hex,
*_file ops from the patch dir, pokes as words). A paired op is
  SAME       same address, byte-identical;
  RELOCATED  same address, the bytes differ only by relocated longs (a pointer into a region that
             moved, rewritten in place — a table's poke32 into a shifted tenant region);
  MOVED      address changed, bytes equal after relocation;
  EDIT       bytes differ in a way relocation does not explain — printed with its gen.log note.
(Until rule-checker run 2026-09-19-63 Q4 an in-place relocation was counted as SAME, so it was never
listed: merged-m19's vm3j.07b moved on such pokes alone while no listed op fell in that member.)
RELOCATION: a 4-byte big-endian window (or a 24-bit address under a flag byte) whose old value lies
inside some op's or placed region's OLD span and whose new value is that value + the span's delta;
plus two named rules — a ONE-PAST-THE-END bound moves with its span, and a BIASED BASE just below a
span borrows that span's delta (the win-palette thunk's `a0 = block - 0xA00`).

Every EDIT is a claim for a human to check against the design; this tool does not know the design.
Usage: python3 tools/attribute_patch_delta.py <OLD build dir> <NEW build dir> [--moved] [--same]   (--moved itemizes
the MOVED and RELOCATED ops, --same the SAME ops with their old and new indices, so every class the tool counts is one
its listing can show — rule-checker run 2026-09-19-79 Q1; static; reads
<dir>/patch/patch.json, placements.json, the op files, and NEW's gen.log)"""
import json, sys, bisect
def load(b):
    ops = json.load(open(f"{b}/patch/patch.json"))["ops"]; out = []
    for o in ops:
        k = o["op"]; a = int(o["addr"], 0)
        if k in ("data", "code"): raw = bytes.fromhex(o["hex"])
        elif k in ("data_file", "code_file"): raw = open(f"{b}/patch/{o['path']}", "rb").read()
        elif k == "poke16": raw = (int(o["val"], 0) & 0xFFFF).to_bytes(2, "big")
        elif k == "poke32": raw = (int(o["val"], 0) & 0xFFFFFFFF).to_bytes(4, "big")
        else: raw = b""
        out.append((k, a, raw))
    return out
LIST_MOVED = "--moved" in sys.argv
LIST_SAME = "--same" in sys.argv
sys.argv = [x for x in sys.argv if x not in ("--moved", "--same")]
A, B = load(sys.argv[1]), load(sys.argv[2])
print("ops", len(A), len(B))
spans = sorted((a, a + len(r), bb - a) for (k, a, r), (_, bb, _r) in zip(A, B) if len(r))
starts = [s[0] for s in spans]
def delta_of(v):
    """the delta of a span CONTAINING v (spans overlap: op spans and region spans), preferring a
    nonzero one; a containment scan, since bisecting overlapping intervals misses (14z-170)"""
    ds = {d for s0, s1, d in spans if s0 <= v < s1}
    if not ds:
        # a ONE-PAST-THE-END bound: a value equal to a span's old END moves with that span
        # (an address-range test's `#end` — 14z-170, the M19 merged patch's Pyron bound, rule-checker run 54 Q1)
        ds = {d for s0, s1, d in spans if v == s1}
    if not ds:
        # a BIASED BASE: a value just below the span it serves, which the engine indexes with a
        # positive offset (the win-palette thunk's `a0 = block - 0xA00`, op 806's Phobos base):
        # the nearest span starting within 0x1000 above the value lends its delta
        above = [(s0 - v, d) for s0, s1, d in spans if 0 < s0 - v <= 0x1000]
        if above:
            ds = {min(above)[1]}
    nz = [d for d in ds if d]
    return nz[0] if len(nz) == 1 else (0 if ds == {0} else (None if not ds else ("AMBIG", sorted(ds))))
notes = {}
for line in open(f"{sys.argv[2]}/gen.log"):
    t = line.split()
    if len(t) > 1 and t[1].startswith("0x"):
        try: notes.setdefault(int(t[1], 16), line.strip()[:150])
        except ValueError: pass
import difflib
sm = difflib.SequenceMatcher(None, [(k, len(r)) for k, a, r in A], [(k, len(r)) for k, a, r in B], autojunk=False)
pairs = []; inserted = []; deleted = []
for tag, i1, i2, j1, j2 in sm.get_opcodes():
    if tag == "equal":
        pairs += list(zip(range(i1, i2), range(j1, j2)))
    else:
        # a replace block: pair element-wise by position, the surplus is inserted/deleted
        n = min(i2 - i1, j2 - j1)
        pairs += list(zip(range(i1, i1 + n), range(j1, j1 + n)))
        deleted += list(range(i1 + n, i2)); inserted += list(range(j1 + n, j2))
spans = sorted((A[i][1], A[i][1] + len(A[i][2]), B[j][1] - A[i][1]) for i, j in pairs if len(A[i][2]))
po = json.load(open(f"{sys.argv[1]}/patch/placements.json"))["regions"]; pn = json.load(open(f"{sys.argv[2]}/patch/placements.json"))["regions"]
spans += [(po[k]["dst"], po[k]["dst"] + po[k]["len"], pn[k]["dst"] - po[k]["dst"]) for k in po]
# the inserted/deleted ops' neighbours: a paired op whose bytes are IDENTICAL but whose address moved gives its delta too
spans = sorted(set(spans)); starts = [x[0] for x in spans]
print("aligned pairs", len(pairs))
for j in inserted: print(f"  INSERTED op[{j}] {B[j][0]} {B[j][1]:#08x} len {len(B[j][2]):#x}: {B[j][2].hex()[:96]}")
for i in deleted: print(f"  DELETED op[{i}] {A[i][0]} {A[i][1]:#08x} len {len(A[i][2]):#x}: {A[i][2].hex()[:96]}")
same = moved = inplace = 0; edits = []; relocs = []; moved_list = []; inplace_list = []; same_list = []
for i, j in pairs:
    (k, a, r), (k2, b, s) = A[i], B[j]
    if k != k2: edits.append((i, k, a, b, "KIND CHANGED")); continue
    if r == s:
        if a == b: same += 1; same_list.append((i, j, k, a, len(r)))
        else: moved += 1; moved_list.append((i, k, a, b, len(r)))
        continue
    if len(r) != len(s):
        edits.append((i, k, a, b, f"length {len(r):#x} -> {len(s):#x}")); continue
    bad = []
    j = 0
    while j < len(r):
        if r[j] == s[j]: j += 1; continue
        ok = False
        for st in range(max(0, j - 3), min(j, len(r) - 4) + 1):
            ov = int.from_bytes(r[st:st+4], "big"); nv = int.from_bytes(s[st:st+4], "big")
            d = delta_of(ov)
            if isinstance(d, int) and d and nv == ov + d: ok = True; relocs.append((ov, nv, a + st)); j = st + 4; break
            # a 24-bit address with a flag in the top byte (the 68000 ignores A24-A31)
            d = delta_of(ov & 0xFFFFFF)
            if isinstance(d, int) and d and (nv >> 24) == (ov >> 24) and (nv & 0xFFFFFF) == (ov & 0xFFFFFF) + d:
                ok = True; relocs.append((ov & 0xFFFFFF, nv & 0xFFFFFF, a + st)); j = st + 4; break
        if not ok: bad.append(j); j += 1
    if bad:
        edits.append((i, k, a, b, f"{len(bad)} bytes at +{bad[0]:#x}..+{bad[-1]:#x}: {r[bad[0]:bad[-1]+1].hex()[:64]} -> {s[bad[0]:bad[-1]+1].hex()[:64]}"))
    elif a == b: inplace += 1; inplace_list.append((i, k, a, b, len(r)))
    else: moved += 1; moved_list.append((i, k, a, b, len(r)))
print(f"SAME {same}  RELOCATED {inplace}  MOVED {moved}  EDIT {len(edits)}")
# THE CONTENT CONTROL on the RELOCATED class (rule-checker run 2026-09-19-56 Q4): the arithmetic
# above (new = old + the span's delta) is only a relocation if the pointer's TARGET holds the same
# bytes in both images. Each target is read in the opcode view and the data view of both builds
# (verify_op.bin / verify_data.bin — code below 0x100000 is encrypted in the data view, so the two
# views together cover code and data); a target identical in EITHER view is content-identical.
# A differing target is listed: it is a relocation into content that ITSELF changed (an edited
# region) or a byte change the arithmetic mis-classed — for a human to read, never absorbed.
def _img(b, v):
    try: return open(f"{b}/verify_{v}.bin", "rb").read()
    except OSError: return None
_io, _in = _img(sys.argv[1], "op"), _img(sys.argv[2], "op")
_do, _dn = _img(sys.argv[1], "data"), _img(sys.argv[2], "data")
if _io is None or _do is None or _in is None or _dn is None:
    print("RELOCATION TARGETS: not checked (a verify_op.bin / verify_data.bin is missing)")
else:
    def _span_end(v):  # the end of the narrowest OLD span holding v (the window never crosses into a neighbour)
        ends = [s1 for s0, s1, d in spans if s0 <= v < s1]
        return min(ends) if ends else v + 8
    def _reloc_equal(x, y):  # equal, or every differing byte covered by a relocated long (as the op check above)
        if x == y: return True
        k = 0
        while k < len(x):
            if x[k] == y[k]: k += 1; continue
            hit = False
            for st in range(max(0, k - 3), min(k, len(x) - 4) + 1):
                ov_, nv_ = int.from_bytes(x[st:st+4], "big"), int.from_bytes(y[st:st+4], "big")
                d_ = delta_of(ov_)
                if isinstance(d_, int) and d_ and nv_ == ov_ + d_: hit = True; k = st + 4; break
                d_ = delta_of(ov_ & 0xFFFFFF)
                if isinstance(d_, int) and d_ and (nv_ >> 24) == (ov_ >> 24) and (nv_ & 0xFFFFFF) == (ov_ & 0xFFFFFF) + d_: hit = True; k = st + 4; break
            if not hit: return False
        return True
    ident = exact = 0; diff = []
    for ov, nv, site in sorted(set(relocs)):
        W = max(2, min(8, _span_end(ov) - ov))
        if max(ov, nv) + W > min(len(_io), len(_in), len(_do), len(_dn)): diff.append((ov, nv, site, "out of image")); continue
        if _io[ov:ov+W] == _in[nv:nv+W] or _do[ov:ov+W] == _dn[nv:nv+W]: ident += 1; exact += 1
        elif _reloc_equal(_io[ov:ov+W], _in[nv:nv+W]) or _reloc_equal(_do[ov:ov+W], _dn[nv:nv+W]): ident += 1
        else: diff.append((ov, nv, site, f"content differs ({W} bytes): {_io[ov:ov+W].hex()} -> {_in[nv:nv+W].hex()}"))
    print(f"RELOCATION TARGETS: {len(set(relocs))} distinct, {ident} content-identical ({exact} byte-exact, the rest modulo relocated longs; window <= 8 bytes, clamped to the target's span, opcode or data view), {len(diff)} differ")
    for ov, nv, site, why in diff[:40]: print(f"  TARGET {ov:#08x} -> {nv:#08x} (pointer at {site:#08x}): {why}")
if LIST_SAME:
    for i, j, k, a, n in same_list: print(f"  SAME op[{i}] -> op[{j}] {k} {a:#08x} len {n:#x}")
if LIST_MOVED:
    for i, k, a, b, n in inplace_list: print(f"  RELOCATED op[{i}] {k} {a:#08x} len {n:#x} (in place)")
    for i, k, a, b, n in moved_list: print(f"  MOVED op[{i}] {k} {a:#08x} -> {b:#08x} len {n:#x}")
for i, k, a, b, why in edits:
    print(f"  EDIT op[{i}] {k} {a:#08x} -> {b:#08x}: {why}")
    if b in notes: print(f"        gen.log: {notes[b]}")
