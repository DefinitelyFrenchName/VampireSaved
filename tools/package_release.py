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
concatenation, in the fixed order below, of every member of the THREE named
reference dumps (vsavj, vsav, vsav2 — all in docs/checksums.txt). vhunt2 was
the fourth until 14z-149 (maintainer-ruled 2026-09-11, "asking the user for a
fourth dump is a lose / lose situation"): it is the port's extraction ORACLE,
never a content source — no atlas range is tagged VH2 — and the 0.76 MB of
copy instructions the M18 patches drew from it were runs byte-identical in
vsav2, the encoder picking one of two equal matches. A modified vsavj member
is mostly a copy of itself; a NEW WIDE member (vsw.31m…) is mostly copies out
of vsav2 gfx. xdelta3
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

SOURCE_ORDER = ["vsavj.zip", "vsav.zip", "vsav2.zip"]   # three since 14z-149; vhunt2 is the oracle, not a source
XDELTA_FLAGS = ["-e", "-S", "none", "-B", str(1 << 28), "-W", str(1 << 23), "-f"]

# ── THE STANDALONE SET (ruled 2026-09-20, route (c)) ────────────────────────
# A build packs only the members it AUTHORS, and the emulators resolve the rest
# from the parent `vsav.zip` plus, on MAME, the QSound BIOS set — so a player
# had to place three archives and the READMEs named two of them (the MAME
# README never mentioned the BIOS at all, measured 2026-09-20: MAME reports
# `dl-1425.bin - NOT FOUND (qsound_hle)` and refuses the set).  The RELEASED
# zip is therefore COMPLETED here: every member the emulators want is copied in
# PRISTINE from the player's own dumps, so one file in `roms/` is the whole
# instruction.  The build is untouched — no fingerprint, expectation set,
# registry row or MiSTer CRC moves — and what the release adds is byte-identical
# to the dumps it came from, which the applier verifies by SHA-1 like any other
# pristine copy.  Measured equivalent to the three-archive arrangement over
# 12,120 frames of `05_timeout_idle` on BOTH emulators, work RAM and framebuffer
# alike, with the de-substitution invariant intact; the gates that hold it are
# `test_release_roundtrip.sh` section 1 and `test_release_binaries.sh`.
#
# `qsound_hle.zip` is a PRISTINE SOURCE ONLY — deliberately NOT in SOURCE_ORDER.
# The source blob is what every xdelta is encoded against, so adding a zip to it
# rewrites every patch file and puts a fourth dump in the blob recipe for the
# sake of one 24 KB member.  A pristine copy needs no blob entry.
PRISTINE_ONLY_SOURCES = ["qsound_hle.zip"]
# MAME's QSound DSP program is a BIOS-SET member, not part of ROM_START(vsavjw),
# which is why no in-tree load map declares it.  FBNeo's descriptor omits it
# entirely (its QSound is HLE), so it is inert there — an unlisted zip member.
QSOUND_BIOS = ("qsound_hle.zip", "dl-1425.bin")
# ...and it is the one OPTIONAL completion member (maintainer-ruled 2026-09-20): "most
# people playing on emulator would likely want a fully self-supporting rom ... however
# MiSTer players will have their own qsound file present on their MiSTer as soon as they
# play any CPS-2 game and our wide core should leverage that by default". Who needs it:
# MAME does (its descriptor lists dl-1425.bin as a BIOS-set member and refuses the set
# without it); FBNeo does NOT (its descriptor omits it, its QSound is HLE); MiSTer does
# not need it INSIDE the zip, because the WIDE MRA's part chain is
# `vsavjw.zip|vsav.zip|qsound.zip` and resolves it from the card's own qsound.zip. So the
# applier includes it by DEFAULT and `--no-qsound-bios` leaves it out, which also drops
# qsound_hle.zip from the dumps the applier requires at all.
OPTIONAL_TAG = "qsound-bios"


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


def standalone_completion(present):
    """The members a RELEASED `vsavjw.zip` must gain to stand alone, given the
    members the build's own zip already carries.

    DERIVED, never listed twice: `gen_vsavjw_xml.PARENT_MEMBERS` is the tree's
    declaration of which members live in the parent zip (it exists for the
    MiSTer catalogue, which must mark them `merge=`), so the completion is
    exactly those the build does not author itself, plus the QSound BIOS member.
    If the profile ever grows a parent-resident member and that set is not
    updated, `test_release_binaries.sh` fails on the emulator's own
    `-verifyroms`, which is a behavioural check with no list to rot.
    """
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import gen_vsavjw_xml
    want = [("vsav.zip", m) for m in sorted(gen_vsavjw_xml.PARENT_MEMBERS)
            if m not in present]
    if QSOUND_BIOS[1] not in present:
        want.append(QSOUND_BIOS)
    return want


def applied_set_key(zips):
    """The whole-set key of what the APPLIER writes — computed exactly as
    tools/build_fingerprint.py wholeset_key() does (zip name, then each member
    name and its bytes, both sorted), so the README can name the identity the
    player actually gets rather than the build's, which the standalone
    completion moves away from.
    """
    h = hashlib.sha1()
    for zname in sorted(zips):
        h.update(zname.encode())
        for member, data in sorted(zips[zname], key=lambda kv: kv[0]):
            h.update(member.encode())
            h.update(data)
    return h.hexdigest()


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
    for z in SOURCE_ORDER + PRISTINE_ONLY_SOURCES:
        zp = os.path.join(a.romdir, z)
        if not os.path.exists(zp):
            sys.exit(f"missing reference dump: {zp}")
        zf = zipfile.ZipFile(zp)
        for n in zf.namelist():
            ref[sha1(zf.read(n))] = (z, n)
    src_path = os.path.join(work, "source.bin")
    src_sha, recipe = build_source(a.romdir, src_path)
    print(f"source blob: {os.path.getsize(src_path)} bytes, sha1 {src_sha}")

    members = {}
    contents = {}          # zname -> [(member, bytes)], for the applied-set key
    nfill = []             # the standalone completion, for the log and the README
    npatch = ncopy = 0
    for zname in sorted(os.listdir(a.rompath)):
        if not zname.endswith(".zip"):
            continue
        zf = zipfile.ZipFile(os.path.join(a.rompath, zname))
        members[zname] = []
        contents[zname] = []
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
            contents[zname].append((n, d))

        # THE STANDALONE COMPLETION (see the header note).  Only the WIDE set is
        # completed: it is the one a player launches.  Every added member is a
        # PRISTINE COPY out of the player's own dumps, so nothing new is
        # distributed and the applier verifies each by SHA-1 before writing.
        if zname == "vsavjw.zip":
            present = {m for m, _ in contents[zname]}
            for zsrc, msrc in standalone_completion(present):
                d = zipfile.ZipFile(os.path.join(a.romdir, zsrc)).read(msrc)
                h = sha1(d)
                if ref.get(h) is None:
                    sys.exit(f"{zsrc}/{msrc}: not in the reference inventory")
                entry = {"member": msrc, "size": len(d), "sha1": h,
                          "pristine_from": {"zip": zsrc, "member": msrc}}
                if (zsrc, msrc) == QSOUND_BIOS:
                    entry["optional"] = OPTIONAL_TAG
                    entry["optional_why"] = ("MAME needs it; FBNeo's descriptor omits it; "
                                             "MiSTer resolves it from the card's qsound.zip")
                members[zname].append(entry)
                contents[zname].append((msrc, d))
                ncopy += 1
                # MACHINE-READ FIELD: exactly "<member> <- <zip>", nothing else.
                # test_release_roundtrip.sh section 1 splits on " <- " and OPENS the right
                # half as a path; a "(optional)" marker appended here made it try to open
                # "qsound_hle.zip (optional)" (caught by that gate, 2026-09-20). Whether a
                # member is optional is the entry's own `optional` field, and the README
                # derives its wording from that.
                nfill.append(f"{msrc} <- {zsrc}")

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

    # The pristine-only reference zips the completion actually drew from, with
    # each member's size and sha1 so the applier verifies them exactly as it
    # verifies the blob's recipe. Absent when nothing was drawn from them, so an
    # older-shaped release stays valid.
    pristine_sources = []
    for z in PRISTINE_ONLY_SOURCES:
        used = sorted({e["pristine_from"]["member"]
                       for mz in members.values() for e in mz
                       if e.get("pristine_from", {}).get("zip") == z})
        if not used:
            continue
        zf = zipfile.ZipFile(os.path.join(a.romdir, z))
        pristine_sources.append({"zip": z, "members": [
            {"member": n, "size": len(zf.read(n)), "sha1": sha1(zf.read(n))}
            for n in used]})

    manifest = {
        "name": a.name, "version_string": a.version,
        "build_fingerprint": fp,
        # What the APPLIER writes. It differs from build_fingerprint by the
        # standalone completion above and is the key a player can check. TWO keys since
        # 2026-09-20, because the QSound BIOS member is optional: the default variant and
        # the `--no-qsound-bios` one, so either output can be checked against the manifest.
        "applied_set_key": applied_set_key(contents),
        "applied_set_key_no_qsound_bios": applied_set_key(
            {z: [(n, d) for (n, d) in ms
                 if not any(e["member"] == n and e.get("optional") == OPTIONAL_TAG
                            for e in members[z])]
             for z, ms in contents.items()}),
        "standalone_completion": sorted(nfill),
        "source": {"order": SOURCE_ORDER, "sha1": src_sha,
                   "size": os.path.getsize(src_path), "recipe": recipe},
        "pristine_sources": pristine_sources,
        "xdelta3_flags": XDELTA_FLAGS,
        "zips": members,
    }
    json.dump(manifest, open(os.path.join(rel, "manifest.json"), "w"), indent=1)
    shutil.copy(os.path.join(os.path.dirname(__file__), "apply_release.py"),
                os.path.join(rel, "apply_release.py"))
    open(os.path.join(rel, "README.md"), "w").write(readme(a, manifest, npatch, ncopy))
    shutil.rmtree(work)
    print(f"packaged {a.name}: {npatch} patched members, {ncopy} pristine copies -> {rel}")
    if nfill:
        print(f"  standalone completion ({len(nfill)}): " + ", ".join(sorted(nfill)))
        print(f"  applied set key: {manifest['applied_set_key'][:8]}")


def readme(a, m, npatch, ncopy):
    """THE END-USER README (common part; tools/package_release_platforms.py
    appends the per-platform "Play on …" section). Written for someone who
    owns the dumps and has never seen this project; the inventory of what a
    release is and is not is docs/project/release_format.md (ruled 2026-09-11).
    The diagnostics in "If it does not work" are MEASURED (STATE 14z-148)."""
    zips = ", ".join(sorted(m["zips"]))
    key = (m["build_fingerprint"] or "?")[:8]
    akey = (m.get("applied_set_key") or "?")[:8]
    akeymin = (m.get("applied_set_key_no_qsound_bios") or "?")[:8]
    fillrows = m.get("standalone_completion") or []
    nfill = len(fillrows)
    opt = {e["member"] for z in m.get("zips", {}).values() for e in z if e.get("optional")}
    fill = ", ".join(r + (" (optional)" if r.split(" <- ")[0] in opt else "")
                     for r in fillrows) if fillrows else "none"
    return f"""# VAMPIRE SAVED — {m['name']}

**What this is.** Vampire Savior (the arcade fighting game, 1997) with three
characters added who were never in it: **Donovan**, **Phobos** (called Huitzil in
the Western release) and **Pyron**. They come from two sister games Capcom built
on the same hardware. Nothing else is changed — every original character plays
exactly as before. Once it is running, the character-select screen shows the mark
`{m['version_string']}` in the bottom-right corner, which is how you can tell you
are playing this and not the original.

**What you need before you start.** Three things, and the first one is the one we
cannot help with:

1. **Your own copies of the original arcade game files.** These are the contents
   of an arcade machine's chips, usually called *ROM sets* or *dumps*; they are
   ordinary `.zip` files. **We cannot give them to you** — they are Capcom's
   property, and this package deliberately contains none of them. You need
   `vsavj.zip`, `vsav.zip` and `vsav2.zip`, unmodified, with exactly those names,
   together in one folder. (A fourth, `qsound_hle.zip`, only for MAME — see
   "One optional member" below.)
2. **Python 3** — a free programming language macOS and Linux already include and
   Windows offers in its store. You will not write any; one command uses it. To
   check, open a terminal and type `python3 --version`.
3. **Room and time**: about 60 MB of free disk space for the package and the
   file you build, and ten minutes. The build briefly uses around 150 MB of
   memory, which any machine made this century has.

**What you are going to do — three steps, in this order:**

> **1. Build the game file.** One command turns *your* files into a new file,
> `vsavjw.zip`. That file is the modified game.
> **2. Get the emulator** — the program that pretends to be the arcade machine.
> This package already contains one, prepared for this game. **An ordinary
> emulator you may already own will not work**; the reason is below.
> **3. Put them together and play.** On **macOS**, double-click
> **`PLAY.command`** and it does steps 2 and 3 for you. On Linux, run
> `sh PLAY.command`. On **Windows there is no launcher yet** — follow "Play on…"
> below by hand; it is four short steps.

**THIS PACKAGE CONTAINS NO ROM DATA AND NO COPYRIGHTED ASSET, EVER.** What it
carries instead is a list of *differences* — "take these bytes from the file you
already own, change these ones". Applied to your files they produce the modified
game; by themselves they are not playable and contain nothing of Capcom's. Every
byte produced is checked against an expected fingerprint before anything is
written, so a wrong, renamed or damaged file is reported by name instead of being
silently used.

**Why an ordinary emulator will not work.** The three added characters need more
storage than a real CPS-2 arcade board had, so this version runs on a slightly
extended board. A normal emulator knows only the original board: it will refuse
the file, or sit on the startup screen forever. The emulator here is an ordinary
FBNeo or MAME with one small published change that teaches it the larger board —
that is the only difference, and you can read the change if you want to.

## What is in this package
- `PLAY.command` — **on macOS, double-click this to play** once you have done
  step 1 (on Linux, `sh PLAY.command`; **not yet available for Windows**). It
  finds the right emulator for your machine, checks it really is the prepared
  one, puts the game file where the emulator will look, and starts it. If
  anything is missing it tells you which thing and what to do about it.
- `apply_release.py` — the program that does step 1. Needs Python 3 and nothing
  else.
- `patches/` — {npatch} files of differences, one for each part of the game that
  changed. Not readable, not playable, and no use without your own game files.
- `manifest.json` — the list of expected fingerprints the applier checks
  everything against. You never edit this.
- this README, plus notes for your platform beside it

## What you need
- **Python 3** (3.8 or newer). No other tool: the applier decodes the
  patches itself.
- **The reference dumps, unmodified, with these exact names** in one
  directory: `vsavj.zip` (Vampire Savior, Japan 970519), `vsav.zip` (Europe
  970519), `vsav2.zip` (Vampire Savior 2, Japan 970913) — and `qsound_hle.zip`
  (the QSound BIOS set) UNLESS you pass `--no-qsound-bios`, for which see
  "One optional member" below. Vampire Hunter 2 is
  NOT needed (it is the project's verification oracle, not a source of
  anything in the set). The applier checks every member's SHA-1
  against the manifest before doing anything, so a wrong, renamed or
  modified dump is reported by name, never silently patched over.

## Build the romset (one command)

"Romset" is just the name for the game file the emulator loads. To make yours,
open a terminal, go to this folder, and run the line below — replacing
`/path/to/your/dumps` with the folder that holds your `vsavj.zip`, `vsav.zip`
and `vsav2.zip`:

    python3 apply_release.py --romdir /path/to/your/dumps --out ./rompath

If you have never used a terminal: on macOS open **Terminal** from
Applications > Utilities, type `cd ` (with the space), drag this folder onto the
window, and press Return — you are now "in" this folder. On Windows use
**PowerShell** the same way. It prints a line per step and finishes with `OK:`.

`./rompath/` then holds `{zips}`, and that is **the only file you place** —
it is a STANDALONE set: every member the emulator asks for is inside it,
including the ones normally resolved from the parent `vsav.zip` and MAME's
QSound BIOS, each copied pristine from your own dumps and SHA-1 verified. You
do not put `vsav.zip`, `vsavj.zip` or `qsound_hle.zip` in the emulator's rom
directory. The applier refuses to write if any member's SHA-1 does not match
the manifest. One member is optional — see below if you are on MiSTer.

<!--PLAY-->

## One optional member — the sound chip's own program

The arcade board's sound hardware had a small program of its own, in a file
called `dl-1425.bin`. It is the only part of the set you get a choice about,
because different emulators want it in different places.

- **Keep it (the default).** The romset is then self-sufficient on every
  emulator, MAME included. You need `qsound_hle.zip` among your dumps.
- **Leave it out:** `python3 apply_release.py --romdir … --out … --no-qsound-bios`.
  You then do not need `qsound_hle.zip` at all. Measured 2026-09-20:
  **FBNeo** runs the smaller set identically (its descriptor does not list the
  member; zero `(not found)`, same RAM and same framebuffer over 12,120 frames),
  and on **MiSTer** the WIDE MRA still resolves all 31 of its parts — 30 out of
  `vsavjw.zip` and the BIOS out of the `qsound.zip` your card already has from any
  CPS-2 game. **MAME refuses the smaller set** (`dl-1425.bin - NOT FOUND`), so
  keep the member if MAME is your emulator.

Either way the applier prints the set key it wrote and checks it against this
release's own declaration, so you can tell at a glance which variant you hold —
and netplay peers must hold the same one.

## Identify the build
- In game: the mark `{m['version_string']}` at the bottom-right of the
  character-select screen, and the boot name screen reads VAMPIRE SAVED.
- On disk: whole-set key `{akey}` — the set the applier writes by default
  (`{akeymin}` with `--no-qsound-bios`), which `manifest.json` carries as
  `applied_set_key` / `applied_set_key_no_qsound_bios` with every member's SHA-1.
  (The build this was packaged from is `{key}`; they differ by the standalone
  completion above, which is pristine content from your dumps.)

## If it does not work
Almost every first-time problem is one of these five.

- **macOS says the emulator "Not Opened — Apple could not verify…"** and offers
  only *Done* and *Move to Bin*. This is macOS refusing to run a program that was
  not submitted to Apple for approval; it is not a sign that anything is wrong
  with the file. **Right-clicking and choosing Open does NOT get past it** on
  current macOS. What works: open a terminal in this folder and run
  `xattr -dr com.apple.quarantine .` — that clears the "downloaded from the
  internet" mark — then start it again. `PLAY.command` offers to do this for you.
- **"Unknown system: vsavjw" / "no such driver"** — the emulator is not the
  prepared one, so it does not know this game. Use the emulator in this package,
  or build one with the recipe in `EMULATOR.md`. Your normal emulator cannot be
  made to work by renaming anything.
- **The game sits on the QSound / CAPCOM legal screen and never reaches the
  title** — you renamed the set to force it into an unpatched emulator. The
  stock 4 MB driver never loads the program extension, the sound driver or
  the QSound extension, so the boot handshake never completes (measured
  2026-09-11: no crash, no gameplay, the legal screen forever). It needs the
  patched emulator; renaming is never the fix.
- **"reference dumps do not match the manifest"** — one of your original game
  files is not the exact version expected: a different region, a different
  revision, or altered at some point. The message names the file and the part of
  it that differs. Nothing is written when this happens.
- **The game runs but a character looks wrong, or the sound is missing** — almost
  always a game file that is the right size but the wrong contents. Re-run the
  build command; it checks every part and will say which one.
- **Playing online against someone** — both of you need the same emulator AND the
  same game file. Compare the key printed under "Identify the build": if they do
  not match, you are not running the same thing.

## What is patched — for the curious, not needed to play
The finished `vsavjw.zip` has {npatch} parts rebuilt from the differences in
`patches/` and {ncopy} copied across from your own files untouched. Of those
copies, {nfill} are there so the result needs no other file beside it:
{fill}.

The difference files describe only what this project itself wrote — relocated
program code, data tables, the version lettering. Anything that came from the
original games is expressed as "copy it from the player's own file" rather than
included, which is what keeps this package free of Capcom's content. Before any
release is published, an automated check scans every difference file for runs of
original game data and refuses to ship if it finds any.
"""


if __name__ == "__main__":
    main()
