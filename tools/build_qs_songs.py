#!/usr/bin/env python3
"""build_qs_songs.py — inject authored Z80 sound-driver songs into a WIDE
build's vsw.z01/z02 members (the M5 voice arc, 14z-86).

Usage:
    build_qs_songs.py <vsavjw.zip> <vs2.zip> [--manifest build/manifest/qs_songs.toml]

Reads the manifest's [[song]] rows (id, place, vs2_src, len), copies each
song block VERBATIM from the vs2 driver members, writes the id-table entry
`[addr24 BE][0x00]` at flat 0x9006+id*4, and rewrites the zip in place.
Format facts: docs/game/engine_internals.md "The QSound Z80 driver".

Refusals (each one is a measured law, not a style choice):
  * target id row not all-zero (b0==0 rows are the driver's own free
    marker — overwriting a live row would hijack an existing sound);
  * placement span not all-zero in the input members;
  * placement below flat 0x10000 (entry byte0 would be 0 == the free
    marker: the song would be silently unreachable);
  * placement crossing a 0x4000 bank boundary (the driver's cp $C0 wrap
    helper would handle it, but an authored block has no reason to cross
    one — kept as a simplicity invariant);
  * id >= the table mod, or two rows colliding.

Prints the SHA-1 of everything read and written, and accounts the diff:
exactly (4 + len) changed bytes per song, nothing else (RH-46).
"""
import argparse
import hashlib
import os
import sys
import zipfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _minitoml

TABLE = 0x9006          # id table flat base (derived from word($3B00)+6;
                        # asserted against the member below, never trusted)
Z01, Z02 = "vsw.z01", "vsw.z02"


def sha1(b):
    return hashlib.sha1(b).hexdigest()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("vsavjw_zip")
    ap.add_argument("vs2_zip")
    ap.add_argument("--manifest", default="build/manifest/qs_songs.toml")
    a = ap.parse_args()

    with open(a.manifest) as f:
        songs = _minitoml.loads(f.read()).get("song", [])
    if not songs:
        sys.exit("manifest has no [[song]] rows")

    zv2 = zipfile.ZipFile(a.vs2_zip)
    vs2 = zv2.read("vs2.01") + zv2.read("vs2.02")
    print(f"read {a.vs2_zip}:vs2.01+.02 sha1 {sha1(vs2)}")

    zin = zipfile.ZipFile(a.vsavjw_zip)
    names = zin.namelist()
    for m in (Z01, Z02):
        if m not in names:
            sys.exit(f"{a.vsavjw_zip} has no {m} — not a WIDE v1.1 romset "
                     f"(rebuild the overlay with tools/build_wide_romset.py)")
    drv = bytearray(zin.read(Z01) + zin.read(Z02))
    print(f"read {a.vsavjw_zip}:{Z01}+{Z02} sha1 {sha1(drv)}")
    before = bytes(drv)

    # derive + assert the table base from the member's own anchor
    hdr = drv[0x3B00] | (drv[0x3B01] << 8)
    mod = (drv[hdr] << 8) | drv[hdr + 1]
    if hdr + 6 != TABLE:
        sys.exit(f"anchor word($3B00)+6 = {hdr+6:#x} != {TABLE:#x} — "
                 f"driver layout moved, re-derive before authoring")

    placed = []
    for s in songs:
        sid, place, src, ln = s["id"], s["place"], s["vs2_src"], s["len"]
        name = s.get("name", f"id_{sid:#x}")
        if sid >= mod:
            sys.exit(f"{name}: id {sid:#x} >= table mod {mod:#x}")
        if place < 0x10000:
            sys.exit(f"{name}: placement {place:#x} < 0x10000 — entry b0 "
                     f"would be 0 (the FREE marker); unreachable by design")
        if (place // 0x4000) != ((place + ln - 1) // 0x4000):
            sys.exit(f"{name}: placement {place:#x}+{ln:#x} crosses a "
                     f"0x4000 bank boundary")
        row = TABLE + sid * 4
        if drv[row:row + 4] != b"\x00\x00\x00\x00":
            sys.exit(f"{name}: id row {sid:#x} not free "
                     f"({drv[row:row+4].hex()}) — refusing to hijack")
        if any(drv[place:place + ln]):
            sys.exit(f"{name}: placement {place:#x}+{ln:#x} not zero-fill")
        for oname, op, oln in placed:
            if place < op + oln and op < place + ln:
                sys.exit(f"{name}: placement overlaps {oname}")
        blob = vs2[src:src + ln]
        if len(blob) != ln or not any(blob):
            sys.exit(f"{name}: vs2 source {src:#x}+{ln:#x} empty/short")
        drv[place:place + ln] = blob
        drv[row:row + 4] = bytes([(place >> 16) & 0xFF, (place >> 8) & 0xFF,
                                  place & 0xFF, 0x00])
        placed.append((name, place, ln))
        print(f"  {name}: id {sid:#x} row @{row:#x} -> {place:#06x} "
              f"({ln:#x} B from vs2 {src:#x})")

    # diff accounting (RH-46): every byte outside the declared spans is
    # untouched, every byte inside them is exactly the intended content.
    # (A changed-byte COUNT would under-read: song blocks contain zeros
    # written over zero fill.)
    spans = []
    for s in songs:
        spans.append((TABLE + s["id"] * 4, 4))
        spans.append((s["place"], s["len"]))
    touched = set()
    for off, ln in spans:
        touched.update(range(off, off + ln))
    for i in range(len(drv)):
        if i not in touched and drv[i] != before[i]:
            sys.exit(f"diff accounting FAILED: byte {i:#x} changed outside "
                     f"every declared span")
    for s in songs:
        blob = vs2[s["vs2_src"]:s["vs2_src"] + s["len"]]
        if drv[s["place"]:s["place"] + s["len"]] != blob:
            sys.exit(f"diff accounting FAILED: {s.get('name')} placement "
                     f"does not equal its vs2 source")
    print(f"diff accounted: {len(songs)} songs, "
          f"{sum(ln for _, ln in spans)} declared bytes, rest untouched")

    # rewrite the zip with the two members replaced, everything else verbatim
    out = {}
    for n in names:
        out[n] = zin.read(n)
    out[Z01] = bytes(drv[:0x20000])
    out[Z02] = bytes(drv[0x20000:])
    with zipfile.ZipFile(a.vsavjw_zip, "w", zipfile.ZIP_DEFLATED) as zf:
        for n in names:
            zf.writestr(n, out[n])
    print(f"wrote {a.vsavjw_zip}: {Z01} sha1 {sha1(out[Z01])}, "
          f"{Z02} sha1 {sha1(out[Z02])}")


if __name__ == "__main__":
    main()
