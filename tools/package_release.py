#!/usr/bin/env python3
"""package_release.py <build_rompath> <out_dir> --romdir ROMDIR --name NAME
                      [--version TEXT]

THE RELEASE PACKAGER (14z-105). Turns a frozen build's rompath (the two
zips tools/build_merged.sh packs) into a distributable patch set that
carries NO ROM CONTENT (CLAUDE.md rule 7):

  out/NAME/
    patches/<set>/d_<member>.xdelta xdelta3 deltas, one per member that
                                    differs from (or does not exist in) the
                                    reference dumps
    manifest.json                   per-member target sha1/size, which
                                    members are copied PRISTINE from which
                                    reference zip, the SOURCE recipe + its
                                    sha1, the build fingerprint, the version
                                    string
    apply_release.py                the community applier (pure python +
                                    xdelta3): rebuilds the two zips from the
                                    user's own dumps and VERIFIES every
                                    member's sha1 before writing anything
    README.md                       what it is, what you need, how to apply

THE SOURCE. Every delta is computed against ONE source blob: the
concatenation, in the fixed order below, of every member of the four named
reference dumps (vsavj, vsav, vsav2, vhunt2 — all four are in
docs/checksums.txt). A modified vsavj member is mostly a copy of itself; a
NEW WIDE member (vsw.31m…) is mostly copies out of vsav2/vhunt2 gfx. xdelta3
expresses both as source-window copies, so the patch files hold only the
bytes the PORT generates or authors (relocated code, tables, the glyph
tiles) plus copy instructions. Secondary compression is OFF (-S none) on
purpose: the rule-7 gate (tests/test_release_roundtrip.sh §3) scans the
patch bytes for verbatim reference-ROM runs, and a compressed stream would
hide one.

Deterministic: member order is sorted, xdelta3 is invoked with fixed flags,
the manifest records everything the applier needs. Run it under
tests/test_release_roundtrip.sh, which applies the result to pristine dumps
and requires byte-identity with the build.
"""
import argparse, hashlib, json, os, shutil, subprocess, sys, zipfile

SOURCE_ORDER = ["vsavj.zip", "vsav.zip", "vsav2.zip", "vhunt2.zip"]
XDELTA_FLAGS = ["-e", "-S", "none", "-B", str(1 << 28), "-W", str(1 << 23), "-f"]


def sha1(b):
    return hashlib.sha1(b).hexdigest()


def build_source(romdir, out_path):
    """Concatenate every member of the four reference zips, sorted by
    member name within each zip, in SOURCE_ORDER. Returns (sha1, recipe)."""
    recipe = []
    h = hashlib.sha1()
    with open(out_path, "wb") as f:
        for z in SOURCE_ORDER:
            zf = zipfile.ZipFile(os.path.join(romdir, z))
            for n in sorted(zf.namelist()):
                d = zf.read(n)
                f.write(d); h.update(d)
                recipe.append({"zip": z, "member": n, "size": len(d), "sha1": sha1(d)})
    return h.hexdigest(), recipe


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("rompath")
    ap.add_argument("out")
    ap.add_argument("--romdir", required=True)
    ap.add_argument("--name", required=True, help="release name, e.g. merged-m6")
    ap.add_argument("--version", default="", help="the in-game version string")
    a = ap.parse_args()
    if not shutil.which("xdelta3"):
        sys.exit("xdelta3 not found on PATH (brew install xdelta)")

    rel = os.path.join(a.out, a.name)
    if os.path.exists(rel):
        shutil.rmtree(rel)
    os.makedirs(os.path.join(rel, "patches"))
    work = os.path.join(a.out, f".work-{a.name}")
    os.makedirs(work, exist_ok=True)

    # reference inventory (sha1 -> (zip, member)) and the source blob
    ref = {}
    for z in SOURCE_ORDER:
        zf = zipfile.ZipFile(os.path.join(a.romdir, z))
        for n in zf.namelist():
            ref[sha1(zf.read(n))] = (z, n)
    src_path = os.path.join(work, "source.bin")
    src_sha, recipe = build_source(a.romdir, src_path)
    print(f"source blob: {os.path.getsize(src_path)} bytes, sha1 {src_sha}")

    members = {}
    npatch = ncopy = 0
    for zname in sorted(os.listdir(a.rompath)):
        if not zname.endswith(".zip"):
            continue
        zf = zipfile.ZipFile(os.path.join(a.rompath, zname))
        members[zname] = []
        for n in sorted(zf.namelist()):
            d = zf.read(n); h = sha1(d)
            entry = {"member": n, "size": len(d), "sha1": h}
            if h in ref:
                entry["pristine_from"] = {"zip": ref[h][0], "member": ref[h][1]}
                ncopy += 1
            else:
                tgt = os.path.join(work, f"{zname}.{n}.bin")
                open(tgt, "wb").write(d)
                # directory named WITHOUT the .zip suffix: the repo's *.zip
                # ignore rule would otherwise swallow the whole patch dir
                zdir = zname[:-4] if zname.endswith(".zip") else zname
                pdir = os.path.join(rel, "patches", zdir)
                os.makedirs(pdir, exist_ok=True)
                # file named AWAY from the member's part number: the repo's
                # rule-7 ignore patterns (vm3*.*, *.[0-9][0-9]m ...) match the
                # raw member names, and a patch file is not ROM content
                pname = "d_" + n.replace(".", "_") + ".xdelta"
                pf = os.path.join(pdir, pname)
                subprocess.run(["xdelta3"] + XDELTA_FLAGS + ["-s", src_path, tgt, pf],
                               check=True)
                entry["patch"] = f"patches/{zdir}/{pname}"
                entry["patch_size"] = os.path.getsize(pf)
                entry["patch_sha1"] = sha1(open(pf, "rb").read())
                npatch += 1
                print(f"  {zname}/{n}: delta {entry['patch_size']} bytes")
            members[zname].append(entry)

    # THE BUILD IDENTITY IS THE WHOLE-SET KEY (14z-148): since the 14z-132
    # whole-set keying a merged build's PROGRAM key is shared with the
    # blanks-only legacy instrument, so the registry keys releases on the
    # whole set — and the old scrape here (`--set` then a hex grep) printed
    # `?` in every README since then.
    fp = None
    try:
        setname = "vsavjw" if os.path.exists(os.path.join(a.rompath, "vsavjw.zip")) else "vsavj"
        out = subprocess.run([sys.executable, os.path.join(os.path.dirname(__file__),
                              "build_fingerprint.py"), a.rompath, "--set", setname, "--set-key"],
                             capture_output=True, text=True).stdout
        import re
        fp = re.findall(r"\b[0-9a-f]{40}\b", out)[-1]
    except Exception:
        pass

    manifest = {
        "name": a.name, "version_string": a.version,
        "build_fingerprint": fp,
        "source": {"order": SOURCE_ORDER, "sha1": src_sha,
                   "size": os.path.getsize(src_path), "recipe": recipe},
        "xdelta3_flags": XDELTA_FLAGS,
        "zips": members,
    }
    json.dump(manifest, open(os.path.join(rel, "manifest.json"), "w"), indent=1)
    shutil.copy(os.path.join(os.path.dirname(__file__), "apply_release.py"),
                os.path.join(rel, "apply_release.py"))
    open(os.path.join(rel, "README.md"), "w").write(readme(a, manifest, npatch, ncopy))
    shutil.rmtree(work)
    print(f"packaged {a.name}: {npatch} patched members, {ncopy} pristine copies -> {rel}")


def readme(a, m, npatch, ncopy):
    """THE END-USER README (common part; tools/package_release_platforms.py
    appends the per-platform "Play on …" section). Written for someone who
    owns the dumps and has never seen this project; the inventory of what a
    release is and is not is docs/project/release_format.md (ruled 2026-09-11).
    The diagnostics in "If it does not work" are MEASURED (STATE 14z-148)."""
    zips = ", ".join(sorted(m["zips"]))
    key = (m["build_fingerprint"] or "?")[:8]
    return f"""# VAMPIRE SAVED — {m['name']} (in-game mark "{m['version_string']}")

Full-roster Vampire Savior on the real CPS-2 engine: the 15+1 of vsavj plus
Donovan, Huitzil/Phobos and Pyron, and a hand-pickable Oboro Bishamon. Runs
on the CPS-2 WIDE profile — an extended CPS-2 board that a patched FBNeo, a
patched MAME (driver `vsavjw`) or the `jtcps2w` MiSTer core implements.

**THIS PACKAGE CONTAINS NO ROM DATA AND NO COPYRIGHTED ASSET, EVER.** It is a
set of patches computed against the four reference dumps you must already
own, a manifest, and an applier that rebuilds the romset from YOUR dumps and
verifies every byte before writing anything. Nothing in it can be played
without your own dumps.

## What is in this package
- `patches/` — {npatch} VCDIFF patch files (xdelta3 format), one per rebuilt member
- `manifest.json` — every target member's SHA-1 and size, which members are
  copied pristine from which dump, the exact source recipe
- `apply_release.py` — the applier (Python 3, nothing else needed)
- this README, plus the platform notes beside it

## What you need
- **Python 3** (3.8 or newer). No other tool: the applier decodes the
  patches itself.
- **The four reference dumps, unmodified, with these exact names** in one
  directory: `vsavj.zip` (Vampire Savior, Japan 970519), `vsav.zip` (Europe
  970519), `vsav2.zip` (Vampire Savior 2, Japan 970913), `vhunt2.zip`
  (Vampire Hunter 2, Japan 970929). The applier checks every member's SHA-1
  against the manifest before doing anything, so a wrong, renamed or
  modified dump is reported by name, never silently patched over.

## Build the romset (one command)
    python3 apply_release.py --romdir /path/to/your/dumps --out ./rompath

`./rompath/` then holds `{zips}`. The applier refuses to write if any rebuilt
member's SHA-1 does not match the manifest. Keep your pristine `vsav.zip`
next to it when you play: the WIDE set is a clone of `vsav` and the emulator
resolves the unmodified members from the parent.

## Identify the build
- In game: the mark `{m['version_string']}` at the bottom-right of the
  character-select screen, and the boot name screen reads VAMPIRE SAVED.
- On disk: whole-set key `{key}` (`manifest.json` has every member's SHA-1).

## If it does not work
- **"Unknown system: vsavjw" / "no such driver"** — the emulator is not the
  patched one. Use the prebuilt binary or the recipe in `EMULATOR.md`.
- **The game sits on the QSound / CAPCOM legal screen and never reaches the
  title** — you renamed the set to force it into an unpatched emulator. The
  stock 4 MB driver never loads the program extension, the sound driver or
  the QSound extension, so the boot handshake never completes (measured
  2026-09-11: no crash, no gameplay, the legal screen forever). It needs the
  patched emulator; renaming is never the fix.
- **"reference dumps do not match the manifest"** — a dump is wrong,
  modified or from another region; the message names the member.
- **Netplay** — every peer needs the same emulator build AND the same romset
  (compare the whole-set key above).

## What is patched
{npatch} members are rebuilt, {ncopy} are copied pristine from your dumps.
The patches hold only bytes the port generates or authors (relocated code,
tables, the version glyphs); everything that comes from the original games
is expressed as a reference into YOUR dumps, which is what keeps this package
free of copyrighted content — and a gate scans every patch for verbatim
reference-ROM bytes before a release is cut.
"""


if __name__ == "__main__":
    main()
