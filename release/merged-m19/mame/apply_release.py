#!/usr/bin/env python3
"""apply_release.py --romdir DIR --out DIR [--manifest manifest.json]

Rebuild a VAMPIRE SAVED romset from a release package and YOUR reference
dumps. Shipped inside every package next to its manifest.json; also lives
in the project tree as tools/apply_release.py (one copy, the packager
copies it). NEEDS ONLY PYTHON 3: the VCDIFF decoder is below (since 14z-148,
2026-09-11 — xdelta3 used to be required; it is still what the PACKAGER
encodes with, so the patches are standard VCDIFF and `xdelta3 -d` applies
them too).

What it does, in order, failing loudly at the first problem:
  1. verifies every reference member the manifest names (zip, member, size,
     sha1) against your dumps — a wrong dump is reported by name;
  2. builds the source blob exactly as the packager did (fixed zip order,
     members sorted by name) and checks its sha1;
  3. for every target member: copies it pristine from the named reference
     member, or decodes its VCDIFF patch against the blob and checks the
     result's sha1 against the manifest;
  4. only then writes the output zips (stored, deterministic order).
Nothing is written unless every member verified.
"""
import argparse, hashlib, json, os, shutil, sys, zipfile

# ── a VCDIFF (RFC 3284) decoder: the default code table, no secondary
# compression, no custom table — exactly what the packager produces with
# `xdelta3 -e -S none`. A patch carrying either extension is REFUSED rather
# than misread. Pure Python; ~1 s per 4 MB member on a 2023 laptop.
VCD_MAGIC = b"\xd6\xc3\xc4\x00"
HDR_SECONDARY, HDR_CODETABLE, HDR_APPHEADER = 0x01, 0x02, 0x04
WIN_SOURCE, WIN_TARGET, WIN_ADLER32 = 0x01, 0x02, 0x04
NOOP, ADD, RUN, COPY = 0, 1, 2, 3
NEAR_SIZE, SAME_SIZE = 4, 3


def _default_code_table():
    """RFC 3284 section 5.6: 256 entries of (inst1, size1, mode1, inst2, size2, mode2)."""
    t = [(RUN, 0, 0, NOOP, 0, 0)]
    t += [(ADD, s, 0, NOOP, 0, 0) for s in range(0, 18)]
    for mode in range(9):
        t.append((COPY, 0, mode, NOOP, 0, 0))
        t += [(COPY, s, mode, NOOP, 0, 0) for s in range(4, 19)]
    for mode in range(6):
        for s1 in range(1, 5):
            t += [(ADD, s1, 0, COPY, s2, mode) for s2 in range(4, 7)]
    for mode in range(6, 9):
        t += [(ADD, s1, 0, COPY, 4, mode) for s1 in range(1, 5)]
    t += [(COPY, 4, mode, ADD, 1, 0) for mode in range(9)]
    assert len(t) == 256, len(t)
    return t


CODE_TABLE = _default_code_table()


class _Reader:
    __slots__ = ("b", "i")

    def __init__(self, b, i=0):
        self.b, self.i = b, i

    def byte(self):
        v = self.b[self.i]; self.i += 1; return v

    def varint(self):  # base-128, big-endian, high bit = continue
        v = 0
        while True:
            c = self.b[self.i]; self.i += 1
            v = (v << 7) | (c & 0x7F)
            if not c & 0x80:
                return v

    def take(self, n):
        s = self.b[self.i:self.i + n]; self.i += n; return s


class _AddrCache:
    def __init__(self):
        self.near = [0] * NEAR_SIZE; self.same = [0] * (SAME_SIZE * 256)
        self.nn = 0

    def update(self, a):
        self.near[self.nn] = a; self.nn = (self.nn + 1) % NEAR_SIZE
        self.same[a % (SAME_SIZE * 256)] = a

    def decode(self, here, mode, addrs):
        if mode == 0:
            a = addrs.varint()
        elif mode == 1:
            a = here - addrs.varint()
        elif mode < 2 + NEAR_SIZE:
            a = self.near[mode - 2] + addrs.varint()
        else:
            m = mode - 2 - NEAR_SIZE
            a = self.same[m * 256 + addrs.byte()]
        self.update(a)
        return a


def _adler32(data):
    import zlib
    return zlib.adler32(data) & 0xFFFFFFFF


def vcdiff_decode(patch, source):
    """Decode a VCDIFF stream against `source` (bytes/memoryview). Returns bytes."""
    r = _Reader(patch)
    if r.take(4) != VCD_MAGIC:
        raise ValueError("not a VCDIFF stream")
    hdr = r.byte()
    if hdr & HDR_SECONDARY:
        raise ValueError("VCDIFF secondary compression is not supported (the packager never uses it)")
    if hdr & HDR_CODETABLE:
        raise ValueError("VCDIFF custom code table is not supported")
    if hdr & HDR_APPHEADER:
        r.take(r.varint())
    out = bytearray()
    while r.i < len(patch):
        win = r.byte()
        src_len = src_pos = 0
        if win & (WIN_SOURCE | WIN_TARGET):
            src_len = r.varint(); src_pos = r.varint()
        r.varint()                       # delta encoding length (redundant)
        tgt_len = r.varint()
        if r.byte() != 0:
            raise ValueError("VCDIFF per-section compression is not supported")
        data_len = r.varint(); inst_len = r.varint(); addr_len = r.varint()
        want = int.from_bytes(r.take(4), 'big') if win & WIN_ADLER32 else None   # 4 raw bytes, not a varint
        data = _Reader(r.take(data_len)); inst = _Reader(r.take(inst_len)); addrs = _Reader(r.take(addr_len))
        if win & WIN_SOURCE:
            seg = memoryview(source)[src_pos:src_pos + src_len]
        elif win & WIN_TARGET:
            seg = memoryview(bytes(out))[src_pos:src_pos + src_len]
        else:
            seg = memoryview(b"")
        t = bytearray()
        cache = _AddrCache()
        while inst.i < inst_len:
            i1, s1, m1, i2, s2, m2 = CODE_TABLE[inst.byte()]
            for ins, size, mode in ((i1, s1, m1), (i2, s2, m2)):
                if ins == NOOP:
                    continue
                if size == 0:
                    size = inst.varint()
                if ins == ADD:
                    t += data.take(size)
                elif ins == RUN:
                    t += bytes((data.byte(),)) * size
                else:  # COPY
                    a = cache.decode(src_len + len(t), mode, addrs)
                    if a < src_len:
                        end = a + size
                        if end <= src_len:
                            t += seg[a:end]
                        else:  # a copy that runs from the source into the target
                            t += seg[a:src_len]
                            for k in range(end - src_len):
                                t.append(t[k])
                    else:
                        p = a - src_len
                        if p + size <= len(t):
                            t += t[p:p + size]
                        else:  # overlapping (run-like) copy: byte by byte
                            for k in range(size):
                                t.append(t[p + k])
        if len(t) != tgt_len:
            raise ValueError(f"VCDIFF window length mismatch: {len(t)} != {tgt_len}")
        if want is not None and _adler32(t) != want:
            raise ValueError("VCDIFF window adler32 mismatch")
        out += t
    return bytes(out)


def sha1(b):
    return hashlib.sha1(b).hexdigest()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--romdir", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--manifest", default=os.path.join(os.path.dirname(
        os.path.abspath(__file__)), "manifest.json"))
    a = ap.parse_args()
    here = os.path.dirname(os.path.abspath(a.manifest))
    m = json.load(open(a.manifest))

    # 1. the reference dumps
    refs = {}
    bad = []
    for r in m["source"]["recipe"]:
        zp = os.path.join(a.romdir, r["zip"])
        if not os.path.exists(zp):
            sys.exit(f"missing reference dump: {zp}")
        zf = refs.setdefault(r["zip"], zipfile.ZipFile(zp))
        try:
            d = zf.read(r["member"])
        except KeyError:
            bad.append(f"{r['zip']}/{r['member']}: member missing"); continue
        if len(d) != r["size"] or sha1(d) != r["sha1"]:
            bad.append(f"{r['zip']}/{r['member']}: sha1/size mismatch (wrong or modified dump)")
    if bad:
        sys.exit("reference dumps do not match the manifest:\n  " + "\n  ".join(bad))
    print(f"reference dumps verified: {len(m['source']['recipe'])} members")

    # 2. the source blob (in memory: ~140 MB)
    parts = []; h = hashlib.sha1()
    for z in m["source"]["order"]:
        for n in sorted(refs[z].namelist()):
            d = refs[z].read(n); parts.append(d); h.update(d)
    if h.hexdigest() != m["source"]["sha1"]:
        sys.exit("source blob sha1 mismatch — an extra or missing member in a reference zip")
    source = b"".join(parts); del parts
    print("source blob rebuilt and verified")

    # 3. every target member, verified before anything is written
    built = {}
    for zname, entries in m["zips"].items():
        built[zname] = []
        for e in entries:
            if "pristine_from" in e:
                d = refs[e["pristine_from"]["zip"]].read(e["pristine_from"]["member"])
            else:
                pf = os.path.join(here, e["patch"])
                if not os.path.exists(pf):
                    sys.exit(f"patch missing: {pf}")
                pb = open(pf, "rb").read()
                if sha1(pb) != e["patch_sha1"]:
                    sys.exit(f"patch file corrupted: {e['patch']}")
                try:
                    d = vcdiff_decode(pb, source)
                except (ValueError, IndexError) as ex:
                    sys.exit(f"{zname}/{e['member']}: cannot decode {e['patch']}: {ex} — NOT writing")
            if len(d) != e["size"] or sha1(d) != e["sha1"]:
                sys.exit(f"{zname}/{e['member']}: rebuilt member does not match the manifest — NOT writing")
            built[zname].append((e["member"], d))
        print(f"  {zname}: {len(entries)} members verified")

    # 4. write
    os.makedirs(a.out, exist_ok=True)
    for zname, ms in built.items():
        with zipfile.ZipFile(os.path.join(a.out, zname), "w", zipfile.ZIP_STORED) as zf:
            for n, d in ms:
                zi = zipfile.ZipInfo(n, date_time=(1997, 5, 19, 0, 0, 0))
                zf.writestr(zi, d)
    print(f"OK: wrote {', '.join(sorted(built))} to {a.out} — every member verified "
          f"(build {m.get('build_fingerprint') or '?'}, mark {m.get('version_string')!r})")


if __name__ == "__main__":
    main()
