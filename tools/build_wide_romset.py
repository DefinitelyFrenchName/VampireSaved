#!/usr/bin/env python3
"""build_wide_romset.py — assemble the CPS-2 WIDE romset overlay.

WIDE is an extended hardware profile (docs/project/cps2_wide.md). Its FBNeo driver
entry `vsavjw` is a clone of `vsav`, so the parent zip supplies gfx, Z80
and the stock QSound members; this builds the clone zip carrying:

  * the vsavj-specific program members + key (copied verbatim), and
  * the appended WIDE members, zero-filled at this stage.

The reference set in ROMDIR is never modified — the output is an overlay
directory of symlinks plus our one clone zip, which is how every patched
build in this project is fed to the emulator.

Usage: build_wide_romset.py <romdir> <outdir> [--qsound 2] [--gfx 0]
"""
import argparse
import binascii
import hashlib
import os
import zipfile

MEMBER = 0x400000  # every appended member is exactly one 4MB unit: the gfx
                   # loader consumes members 4 at a time and mis-sizes if
                   # they differ, and QSound's mask needs a power of two.


def check_disjoint(romdir, outdir):
    """The input directory is NEVER modified (this file's docstring, and rule
    7: ROMDIR holds reference dumps that live outside the tree). That promise
    is enforced here, at the CLI boundary, BEFORE any mutation (14z-94,
    GitHub #76).

    Without it, `outdir == romdir` is quietly destructive rather than a no-op:
    the cleanup loop below calls os.remove() on every `.zip` it finds — which
    are the SOURCE dumps — and then os.symlink(src, dst) with src == dst
    leaves a self-referential link where the reference set used to be. The
    zips are irreplaceable-by-us (rule 7 forbids keeping copies in the tree),
    so this is the one failure in this file with no undo.

    Rejected: identity, `..` spellings of the same directory, symlink
    aliases (realpath resolves all three), and containment in EITHER
    direction — output beneath the reference set writes into the immutable
    input, and input beneath the output means the build links into a tree it
    is itself mutating.

    realpath() is used rather than abspath() precisely because the alias
    cases are the ones a string comparison misses, and it does not require
    outdir to exist yet.
    """
    ir = os.path.realpath(romdir)
    orl = os.path.realpath(outdir)
    if ir == orl:
        raise SystemExit(
            f"refusing to build in place: romdir and outdir are the same "
            f"directory ({ir}).\n"
            f"  Given romdir={romdir!r} outdir={outdir!r}.\n"
            f"  The cleanup pass would DELETE the source zips it is meant to "
            f"read. Give outdir a separate path (build/<name>/rompath).")
    for parent, child, why in (
            (ir, orl, "the output would be written INSIDE the reference set, "
                      "which this tool promises never to modify"),
            (orl, ir, "the reference set is INSIDE the output directory, so "
                      "the build would link into a tree it is mutating")):
        if child.startswith(parent + os.sep):
            raise SystemExit(
                f"refusing to build: {why}.\n"
                f"  romdir={romdir!r} -> {ir}\n"
                f"  outdir={outdir!r} -> {orl}\n"
                f"  Give the two paths disjoint locations.")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("romdir")
    ap.add_argument("outdir")
    ap.add_argument("--qsound", type=int, default=2,
                    help="appended 4MB QSound members (2 => 8MB->16MB)")
    ap.add_argument("--gfx", type=int, default=0,
                    help="appended 4MB GFX members (must be a multiple of 4)")
    ap.add_argument("--prg", type=int, default=0,
                    help="appended 512KB program members (4 => 4MB->6MB)")
    ap.add_argument("--gfx-copy-group-b", action="store_true",
                    help="CANARY ROMSETS ONLY — fill the appended GFX group "
                         "with a byte copy of the stock group B, so WIDE "
                         "banks 4/5 mirror banks 2/3 (the B4 canary). NEVER "
                         "merge the result into a content build: see the "
                         "warning this prints")
    a = ap.parse_args()
    if a.gfx % 4:
        raise SystemExit("--gfx must be a multiple of 4 (the loader consumes "
                         "gfx members in groups of four)")

    check_disjoint(a.romdir, a.outdir)

    os.makedirs(a.outdir, exist_ok=True)
    for z in sorted(os.listdir(a.romdir)):
        if z.endswith(".zip"):
            dst = os.path.join(a.outdir, z)
            if os.path.islink(dst) or os.path.exists(dst):
                os.remove(dst)
            os.symlink(os.path.join(a.romdir, z), dst)

    src_path = os.path.join(a.romdir, "vsavj.zip")
    src = zipfile.ZipFile(src_path)
    print(f"  read {src_path} sha1 "
          f"{hashlib.sha1(open(src_path,'rb').read()).hexdigest()}")

    out_path = os.path.join(a.outdir, "vsavjw.zip")
    blank = b"\x00" * MEMBER
    with zipfile.ZipFile(out_path, "w", zipfile.ZIP_DEFLATED) as zf:
        for n in sorted(src.namelist()):
            zf.writestr(n, src.read(n))
        for i in range(a.qsound):
            zf.writestr(f"vsw.{21+i}m", blank)
        GROUP_B = ["vm3.14m", "vm3.16m", "vm3.18m", "vm3.20m"]
        parent = zipfile.ZipFile(os.path.join(a.romdir, "vsav.zip"))
        # WIDE v1.1 (14z-86): the Z80 driver members are CONTENT members
        # named vsw.z01/z02 (sentinel CRCs 0xdec0de38/39 in both
        # descriptors) so builds can patch the sound driver (M5 songs)
        # without hash-shadowing to vsav.zip's pristine vm3.01/02 (the
        # 14z-60z class). The canonical overlay carries stock bytes.
        for zn, pn in (("vsw.z01", "vm3.01"), ("vsw.z02", "vm3.02")):
            zf.writestr(zn, parent.read(pn))
        for i in range(a.gfx):
            name = f"vsw.{31+2*i}m"   # odd names mirror the stock interleave
            if a.gfx_copy_group_b and i < len(GROUP_B):
                zf.writestr(name, parent.read(GROUP_B[i]))
            else:
                zf.writestr(name, blank)
        for i in range(a.prg):
            zf.writestr(f"vsw.{41+i}", b"\x00" * 0x80000)
    print(f"  wrote {out_path}: vsavj members + {a.qsound} QSound + {a.gfx} GFX "
          f"+ {a.prg} PRG appended "
          f"({(MEMBER*(a.qsound+a.gfx) + 0x80000*a.prg)//(1024*1024)} MB of zero fill)")
    print("  NOTE: group C descriptor CRCs are SENTINELS (0xdec0de31..37), "
          "never member CRCs — any real value hash-shadows (pristine-B was "
          "14z-60z; the zero-fill CRC collides with the zero QSound members, "
          "14z-62d). Do not 'fix' them to match these files. The Z80 members "
          "vsw.z01/z02 (0xdec0de38/39) are the same class since WIDE v1.1.")
    print("  NOTE: descriptor sizes in FBNeo's VsavjwRomDesc[] must match "
          "these members exactly — a member LARGER than its declared length "
          "is silently truncated at load (load.cpp), with no diagnostic.")
    if a.gfx_copy_group_b:
        print()
        print("  *** CANARY ROMSET — NOT SHIPPABLE (14z-60z) ***")
        print("  Group C now holds byte copies of the stock group B members,")
        print("  so it carries THEIR CRCs. Both emulators resolve a ROM entry")
        print("  by hash before name, so in a set whose group B is PATCHED the")
        print("  loader matches group B's declared CRC against these copies and")
        print("  loads pristine tiles instead — the patch reverts silently.")
        print("  Build content overlays WITHOUT this flag; keep the canary in")
        print("  its own directory (build/wide_canary/rompath) and never pass")
        print("  it to pack_build.sh --merge. tools/audit_romset_identity.py")
        print("  fails any build that does.")


if __name__ == "__main__":
    main()
