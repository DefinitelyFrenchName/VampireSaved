#!/usr/bin/env python3
"""build_qs_songs.py — inject authored Z80 sound-driver content into a WIDE
build's vsw.z01/z02 members (+ packed samples into vsw.21m) — the M5 voice
arc (14z-86).

Usage:
    build_qs_songs.py <vsavjw.zip> <vs2.zip> [--vsav <vsav.zip>]
        [--manifest build/manifest/qs_songs.toml] [--ledger out.json]

TWO row kinds, both fully derived from the reference zips:

[[song]] — verbatim vs2 song-block copies at free vsavj ids (the 14z-86
ejection pilot shape): id, place, vs2_src, len.

[voice_batch] — THE VOICE BLOCKS (14z-86 batch; needs --vsav): for every
scoped vs2 id (minus excludes), copy the song VERBATIM and author the
support it references:
  * the vs2 voice NOTE TABLE (its 8th pointer-array slot — vsavj has 7):
    reached on vsavj by RELOCATING table 0 (byte-identical copy, pointer
    word at $3B04 repointed) and writing the vacated word at $3B12 as the
    8th slot pointer -> the authored T7. Songs' `1F 07` then resolves.
  * authored SAMPLE RECORDS at high indices whose addresses land in the
    post-envelope free zero run (base 0x45FA + n*8 — no table growth),
  * sample CONTENT: windows found byte-identical in vsav's image are
    referenced in place (end-EXCLUSIVE compare — the end-address byte is
    outside the audible window); absent windows are packed into the
    QSound EXTENSION member vsw.21m (banks 0x80+, WIDE v1.2) first-fit
    without crossing a 64 KB bank boundary.
  * table-1 entries the songs use ride vsavj's NATIVE table 1 — measured
    content-equivalent for every used index (14z-86).
Refusals: non-free id rows, non-zero placements, songs below flat
0x10000 (entry b0==0 is the driver's free/no-op marker), bank-boundary
crossings, relocation old-byte mismatches (RH-44). The diff is accounted
span-exact. Emits a ledger (id map + expected 68k remap strings) and the
curated table docs/project/tables/qs_voice_map.md (Rule 5).
"""
import argparse
import hashlib
import json
import os
import struct
import sys
import zipfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _minitoml
from audit_qs_voice_batch import anchors as _anchors, parse_track

TABLE = 0x9006
Z01, Z02 = "vsw.z01", "vsw.z02"
EXT = "vsw.21m"


def sha1(b):
    return hashlib.sha1(b).hexdigest()


class Author:
    """Tracks declared spans + refusals over the driver image."""

    def __init__(self, drv):
        self.drv = drv
        self.before = bytes(drv)
        self.spans = []          # (name, off, len)

    def claim(self, name, off, ln, need_zero=True, old=None):
        for on, oo, ol in self.spans:
            if off < oo + ol and oo < off + ln:
                sys.exit(f"{name}: span {off:#x}+{ln:#x} overlaps {on}")
        if need_zero and any(self.drv[off:off + ln]):
            sys.exit(f"{name}: span {off:#x}+{ln:#x} not zero-fill")
        if old is not None and bytes(self.drv[off:off + ln]) != old:
            sys.exit(f"{name}: old bytes {self.drv[off:off+ln].hex()} != "
                     f"expected {old.hex()} (RH-44)")
        self.spans.append((name, off, ln))

    def write(self, name, off, data, need_zero=True, old=None):
        self.claim(name, off, len(data), need_zero, old)
        self.drv[off:off + len(data)] = data

    def account(self):
        touched = set()
        for _, off, ln in self.spans:
            touched.update(range(off, off + ln))
        for i in range(len(self.drv)):
            if i not in touched and self.drv[i] != self.before[i]:
                sys.exit(f"diff accounting FAILED: byte {i:#x} changed "
                         f"outside every declared span")
        return len(touched)


def id_row(au, name, sid, mod, addr):
    if sid >= mod:
        sys.exit(f"{name}: id {sid:#x} >= mod {mod:#x}")
    if addr < 0x10000:
        sys.exit(f"{name}: song addr {addr:#x} < 0x10000 (b0==0 = free "
                 f"marker; unreachable)")
    row = TABLE + sid * 4
    if bytes(au.drv[row:row + 4]) != b"\x00\x00\x00\x00":
        sys.exit(f"{name}: id row {sid:#x} not free "
                 f"({au.drv[row:row+4].hex()})")
    au.write(f"{name}:idrow", row,
             bytes([(addr >> 16) & 0xFF, (addr >> 8) & 0xFF, addr & 0xFF, 0]),
             need_zero=True)


def parse_ids(spec):
    out = []
    for tok in spec.split(","):
        tok = tok.strip()
        if not tok:
            continue
        if "-" in tok:
            lo, hi = tok.split("-")
            out += list(range(int(lo, 16), int(hi, 16) + 1))
        else:
            out.append(int(tok, 16))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("vsavjw_zip")
    ap.add_argument("vs2_zip")
    ap.add_argument("--vsav", help="vsav.zip (needed for [voice_batch])")
    ap.add_argument("--manifest", default="build/manifest/qs_songs.toml")
    ap.add_argument("--ledger")
    a = ap.parse_args()

    with open(a.manifest) as f:
        man = _minitoml.loads(f.read())
    songs = man.get("song", [])
    vb = man.get("voice_batch") or {}

    zv2 = zipfile.ZipFile(a.vs2_zip)
    vs2 = zv2.read("vs2.01") + zv2.read("vs2.02")
    print(f"read {a.vs2_zip}:vs2.01+.02 sha1 {sha1(vs2)}")

    zin = zipfile.ZipFile(a.vsavjw_zip)
    names = zin.namelist()
    for m in (Z01, Z02):
        if m not in names:
            sys.exit(f"{a.vsavjw_zip} has no {m} — not a WIDE v1.1+ romset")
    drv = bytearray(zin.read(Z01) + zin.read(Z02))
    print(f"read {a.vsavjw_zip}:{Z01}+{Z02} sha1 {sha1(drv)}")
    au = Author(drv)

    hdr = drv[0x3B00] | (drv[0x3B01] << 8)
    mod = (drv[hdr] << 8) | drv[hdr + 1]
    if hdr + 6 != TABLE:
        sys.exit(f"anchor word($3B00)+6 = {hdr+6:#x} != {TABLE:#x}")

    # ---- [[song]] verbatim rows (the ejection pilot) --------------------
    for s in songs:
        sid, place, src, ln = s["id"], s["place"], s["vs2_src"], s["len"]
        name = s.get("name", f"id_{sid:#x}")
        if (place // 0x4000) != ((place + ln - 1) // 0x4000):
            sys.exit(f"{name}: placement crosses a 0x4000 bank boundary")
        blob = vs2[src:src + ln]
        if len(blob) != ln or not any(blob):
            sys.exit(f"{name}: vs2 source {src:#x}+{ln:#x} empty/short")
        au.write(name, place, blob)
        id_row(au, name, sid, mod, place)
        print(f"  {name}: id {sid:#x} -> {place:#06x} ({ln:#x} B)")

    # ---- [voice_batch] --------------------------------------------------
    ext_packed = []          # (ext_off, blob) into vsw.21m
    ledger = {"songs": [], "voices": [], "records": [], "t7": [],
              "remap": {}, "ext": []}
    if vb.get("enable"):
        if not a.vsav:
            sys.exit("[voice_batch] needs --vsav")
        zv = zipfile.ZipFile(a.vsav)
        qs = zv.read("vm3.11m") + zv.read("vm3.12m")
        q2 = zv2.read("vs2.11m") + zv2.read("vs2.12m")
        print(f"read {a.vsav}:vm3.11m+12m sha1 {sha1(qs)}")
        print(f"read {a.vs2_zip}:vs2.11m+12m sha1 {sha1(q2)}")

        v2table, v2mod, v2rec, v2ntp = _anchors(vs2)
        if len(v2ntp) != 8:
            sys.exit(f"vs2 note-ptr array has {len(v2ntp)} slots, expected 8")

        ids = [i for i in parse_ids(vb["ids"])
               if i not in set(parse_ids(vb.get("exclude", "")))]
        starts = sorted({(vs2[v2table + i * 4] << 16)
                         | (vs2[v2table + i * 4 + 1] << 8)
                         | vs2[v2table + i * 4 + 2]
                         for i in range(v2mod)} - {0})

        # 1. parse all scoped songs; collect T7 entries + samples
        import bisect
        plan = []
        t7_entries = {}          # e -> (vs2 sample#, ixd, instr)
        for vid in ids:
            row = v2table + (vid % v2mod) * 4
            addr = (vs2[row] << 16) | (vs2[row + 1] << 8) | vs2[row + 2]
            if addr == 0:
                continue
            bi = bisect.bisect_right(starts, addr)
            extent = (starts[bi] - addr) if bi < len(starts) else 0x40
            song = vs2[addr:addr + extent]
            hdrb = vs2[addr]
            slots = [struct.unpack_from(">H", vs2, addr + 1 + 2 * k)[0]
                     for k in range(16)]
            for k, w in [(k, w) for k, w in enumerate(slots) if w]:
                t = parse_track(vs2, addr + w, v2ntp, v2rec)
                for e in t["entries"]:
                    if e["table"] == 7:
                        prev = t7_entries.get(e["e"])
                        cur = (e["sample"], e["ixd"], e["instr"])
                        if prev and prev != cur:
                            sys.exit(f"T7 entry {e['e']:#x} used with two "
                                     f"different contents")
                        t7_entries[e["e"]] = cur
                        if e["instr"] != 0:
                            sys.exit(f"voice instr {e['instr']} != 0 — the "
                                     f"envelope-identity premise broke")
            plan.append({"vid": vid, "song": song, "hdr": hdrb})

        # 2. sample records for T7's samples: window -> vsav offset or ext
        rec_base_new = vb["records_base"]
        if (rec_base_new - 0x45FA) % 8:
            sys.exit("records_base not 8-aligned to 0x45FA")
        ext_cur = 0
        EXTLIM = 0x400000
        sample_map = {}          # vs2 sample# -> new record index
        rec_cur = rec_base_new
        for e in sorted(t7_entries):
            s, ixd, instr = t7_entries[e]
            if s in sample_map:
                continue
            ro = v2rec + s * 8
            rec = vs2[ro:ro + 8]
            bank, st = rec[0], struct.unpack_from("<H", vs2, ro + 1)[0]
            lo = struct.unpack_from("<H", vs2, ro + 3)[0]
            en = struct.unpack_from("<H", vs2, ro + 5)[0]
            w0, w1 = (bank << 16) | st, (bank << 16) | en
            # PACKING LAW #3 (14z-87b, the sword-plant beep): the record's
            # `end` offset is played/looped INCLUSIVE (proven by field
            # width: native windows end at 0xFFFF), so the copy must
            # include the byte AT `end`. The original exclusive copy left
            # every packed sample's last played byte holding the NEXT
            # blob's first byte — for a voice whose loop tail is silence,
            # one foreign byte = a ~1.8kHz impulse-train beep sustained to
            # keyoff (rec#0x3C8 / Donovan 0x705, fired at every plant;
            # 2 more contaminated records in the 14z-87b census).
            blob = q2[w0:w1 + 1]
            at = qs.find(blob)
            if at >= 0:
                nb, nst = at >> 16, at & 0xFFFF
                if (nst & 0x8000) != ((nst + (w1 - w0)) & 0x8000) \
                        or nst + (w1 - w0) + 1 > 0x10000 \
                        or (at & 1) != (w0 & 1):
                    # the two playback laws (both measured 14z-86): the
                    # window must live wholly in one half of its bank
                    # (signed pointer compare), and it must keep the
                    # SOURCE's byte parity — the members are stored
                    # pre-swapped and both emulators byteswap 16-bit
                    # pairs at load, so a lane-crossed copy plays with
                    # every byte pair exchanged (the "PC-speaker"
                    # distortion: RMS preserved, high band doubled)
                    at = -1
                else:
                    src_tag = f"vsav@{at:#x}"
            if at < 0:
                # pack into the extension: first fit, HALF-BANK (0x8000)
                # granularity — the DSP compares sample pointers SIGNED
                # 16-bit, so a window straddling offset 0x8000 in its bank
                # ends immediately (start positive, end "negative"; the
                # voice collapses to its silent loop tail — measured
                # 14z-86: the 4 quiet/truncated voices were exactly the
                # windows crossing 0x8000, and every NATIVE record lives
                # wholly in one half of its bank)
                if (w1 - w0 + 1) > 0x8000:
                    sys.exit(f"sample {s:#x}: window {w1-w0+1:#x} exceeds a "
                             f"half-bank — not expressible (native never is)")
                # BYTE-PARITY LAW (measured 14z-86): the members are
                # stored pre-swapped and byteswapped at load on BOTH
                # emulators, so the destination offset must keep the
                # source offset's parity or every byte pair plays
                # crossed (the "PC-speaker" distortion the maintainer
                # caught; file-level comparison is blind to it)
                if (ext_cur & 1) != (w0 & 1):
                    ext_cur += 1
                if (ext_cur & 0x7FFF) + (w1 - w0 + 1) > 0x8000:
                    ext_cur = ((ext_cur + 0x7FFF) & ~0x7FFF) | (w0 & 1)
                if ext_cur + (w1 - w0 + 1) > EXTLIM:
                    sys.exit("extension member vsw.21m overflow")
                ext_packed.append((ext_cur, blob))
                img = 0x800000 + ext_cur          # image offset (bank 0x80+)
                nb, nst = img >> 16, img & 0xFFFF
                src_tag = f"ext@{img:#x}"
                ledger["ext"].append({"sample": s, "img": img,
                                      "size": w1 - w0 + 1})
                ext_cur += w1 - w0 + 1
            n = (rec_cur - 0x45FA) // 8
            newrec = bytes([nb]) + struct.pack("<H", nst) \
                + struct.pack("<H", (nst + (lo - st)) & 0xFFFF) \
                + struct.pack("<H", nst + (en - st)) + bytes([rec[7]])
            au.write(f"rec:{s:#x}", rec_cur, newrec)
            ledger["records"].append({"vs2_sample": s, "new_index": n,
                                      "at": rec_cur, "rec": newrec.hex(),
                                      "src": src_tag})
            sample_map[s] = n
            rec_cur += 8

        # 3. the authored T7 note table
        t7 = vb["t7_base"]
        maxe = max(t7_entries)
        for e, (s, ixd, instr) in sorted(t7_entries.items()):
            cell = struct.pack("<H", sample_map[s]) + bytes([ixd, instr])
            au.write(f"t7:{e:#x}", t7 + e * 4, cell)
            ledger["t7"].append({"e": e, "vs2_sample": s,
                                 "new_sample": sample_map[s]})

        # 4. relocate table 0 + write the 8th pointer slot
        t0 = struct.unpack_from("<H", drv, 0x3B04)[0]
        t1 = struct.unpack_from("<H", drv, 0x3B06)[0]
        t0len = t1 - t0
        copy_at = vb["table0_copy"]
        au.write("table0:copy", copy_at, au.before[t0:t0 + t0len])
        au.write("table0:ptr", 0x3B04, struct.pack("<H", copy_at),
                 need_zero=False, old=au.before[0x3B04:0x3B06])
        au.write("t7:ptr", t0, struct.pack("<H", t7),
                 need_zero=False, old=au.before[t0:t0 + 2])

        # 5. songs (verbatim) + id rows; the 68k id map
        song_cur = vb["songs_base"]
        id_cur = vb["id_base"]
        for p in plan:
            ln = len(p["song"])
            if (song_cur // 0x4000) != ((song_cur + ln - 1) // 0x4000):
                song_cur = ((song_cur // 0x4000) + 1) * 0x4000
            au.write(f"voice:{p['vid']:#x}", song_cur, p["song"])
            id_row(au, f"voice:{p['vid']:#x}", id_cur, mod, song_cur)
            ledger["voices"].append({"vs2_id": p["vid"], "id": id_cur,
                                     "at": song_cur, "len": ln})
            song_cur += ln
            id_cur += 1
        print(f"  voice_batch: {len(plan)} songs, {len(sample_map)} records "
              f"({len(ledger['ext'])} packed into {EXT}, "
              f"{ext_cur} ext bytes), T7 {len(t7_entries)} entries "
              f"(max {maxe:#x}), ids {vb['id_base']:#x}-{id_cur-1:#x}")

        remap = {}
        for v in ledger["voices"]:
            remap[v["vs2_id"]] = v["id"]
        ledger["remap"] = {f"{k:#x}": f"{v:#x}" for k, v in remap.items()}

    touched = au.account()
    print(f"diff accounted: {touched} declared bytes, rest untouched")
    ledger["spans"] = [{"name": n, "off": o, "len": ln}
                       for n, o, ln in au.spans]

    out = {n: zin.read(n) for n in names}
    out[Z01] = bytes(drv[:0x20000])
    out[Z02] = bytes(drv[0x20000:])
    if ext_packed:
        if EXT not in names:
            sys.exit(f"{a.vsavjw_zip} has no {EXT} — not a WIDE romset")
        ext = bytearray(out[EXT])
        for off, blob in ext_packed:
            if any(ext[off:off + len(blob)]):
                sys.exit(f"extension span {off:#x} not zero")
            ext[off:off + len(blob)] = blob
        out[EXT] = bytes(ext)
    with zipfile.ZipFile(a.vsavjw_zip, "w", zipfile.ZIP_DEFLATED) as zf:
        for n in names:
            zf.writestr(n, out[n])
    print(f"wrote {a.vsavjw_zip}: {Z01} sha1 {sha1(out[Z01])}, "
          f"{Z02} sha1 {sha1(out[Z02])}"
          + (f", {EXT} sha1 {sha1(out[EXT])}" if ext_packed else ""))
    if a.ledger:
        json.dump(ledger, open(a.ledger, "w"), indent=1)
        print(f"wrote {a.ledger}")


if __name__ == "__main__":
    main()
