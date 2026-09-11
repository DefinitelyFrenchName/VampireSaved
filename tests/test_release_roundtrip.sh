#!/bin/sh
# test_release_roundtrip.sh — THE RELEASE PACKAGE GATE (14z-105).
#
# MUST-FIRE: known-bad: corrupted-patch — a package with one patch byte flipped must be REFUSED by the applier without writing (mode: section 1 applies that package and must fail)
# MUST-FIRE: known-bad: wrong-target-sha1 — a manifest naming a wrong target sha1 must be refused without writing
# MUST-FIRE: known-bad: wrong-dump — a reference dump with one byte flipped must be refused without writing (mode: section 1 applies against it)
# MUST-FIRE: known-bad: planted-reference-chunk — a patch file with a reference-ROM chunk appended must be caught by the rule-7 scan (mode: it sits in the scanned patch set)
# MUST-FIRE: known-bad: missing-emulator-dir — a release copy without mame/emulator/ must fail the layout check (mode: section 4 checks that copy)
# MUST-FIRE: known-bad: secondary-compressed-patch — a patch re-encoded WITH secondary compression must be REFUSED by the applier's own VCDIFF decoder (it would hide reference bytes from the rule-7 scan); mode: section 1 applies that package and must fail
# MUST-FIRE: known-bad: stray-file — a release copy with a file outside the ruled inventory must fail section 4 (nothing outside the definition ships; mode: section 4 checks that copy)
# MUST-FIRE: known-bad: readme-missing-section — a release copy whose README lacks the "If it does not work" section must fail section 4 (mode: section 4 checks that copy)
#
# A release is a set of xdelta3 patches + a manifest + an applier
# (tools/package_release.py). This gate is what makes it shippable:
#   1  ROUND TRIP — package the build, apply the package to the PRISTINE
#      reference dumps in a scratch dir, and require every member of every
#      output zip byte-identical to the build's rompath (and the program
#      fingerprint + whole-artifact manifest to agree).
#   2  THE APPLIER REFUSES — a corrupted patch file, a wrong reference
#      member (one byte flipped in a copy of vsavj.zip), and a manifest
#      with a wrong target sha1 must each make apply_release.py exit
#      non-zero WITHOUT writing the output zips.
#   3  RULE 7 — no patch file carries a verbatim run of reference-ROM
#      bytes: every 64-byte-aligned chunk of every reference member is
#      indexed, and a rolling 64-byte window over every patch byte must
#      never hit the index (catches any verbatim run >= 128 bytes). The
#      packager disables xdelta3's secondary compression so this scan
#      sees the real payload. Must-fire control: a patch file with one
#      reference chunk appended IS caught.
#   4  THE PER-PLATFORM LAYOUT (14z-113, docs/project/release_format.md) —
#      the tree's release/<name>/ has fbneo/ mame/ mister/, each with the
#      patch set (manifests byte-identical), the emulator dirs carry the
#      tree's driver patch + EMULATOR.md, mister/ carries MRAs +
#      BITSTREAM.txt + MISTER.md + the .rbf whose sha256 EQUALS the
#      record's, the record byte-identical to the canonical
#      release/bitstreams/<CURRENT>/ one (the build resource every release
#      packages from); no cross-platform leakage; must-fire: a copy missing
#      mame/emulator/ is rejected. SINCE 14z-148 (the inventory ruled
#      2026-09-11): every file under each platform dir is in the ruled
#      inventory and every inventory item is present (a stray file FAILS),
#      each prebuilt-binary dir's BINARY.txt sha256s match its files, and
#      README.md carries the end-user sections (what you need, build the
#      romset, play on <platform>, if it does not work, the no-ROM statement).
#      The applier needs only Python 3 (its own VCDIFF decoder): section 1's
#      round trip is what proves that decoder against xdelta3's encoder.
#
# Usage: ROMDIR=... tests/test_release_roundtrip.sh [build_rompath] [name]
#   defaults build/m3b_merged26/rompath, merged-m16. Needs xdelta3.
#   re-pointed 14z-130 (M13 boot-title freeze) <- 14z-119 <- 14z-117b
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-105 (ci_static, ~40 s): THE RELEASE PACKAGE GATE — package, apply to
#   the pristine dumps, byte-identical x42 + fingerprint + manifest; the
#   applier refuses corrupted patch / wrong sha1 / wrong dump without writing;
#   rule 7 verbatim-chunk scan with a must-fire control. Needs xdelta3.
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
# 14z-132: ABSOLUTE. Gates `cd` into work dirs and then compose paths that
# still contain $ROMDIR (e.g. MAME_ROMPATH="...;$ROMDIR"); a RELATIVE value —
# which is how the runners invoke everything (ROMDIR=../ROMS) — then resolves
# against the WORK dir and silently finds no reference members. Kept as a
# VARIABLE (forks set their own); only made absolute, and only if it exists,
# so a gate that means to SKIP on a missing ROMDIR still does.
if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
RP="${1:-build/m3b_merged26/rompath}"  # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
NAME="${2:-merged-m18}"  # re-pointed 14z-144 (M18 donovan/jedah freeze) <- 14z-143  # re-pointed 14z-134 (the M16 release: the m16 layout had NEVER been gated — code said m14, header m15) <- 14z-119 <- 14z-117b
[ -d "$RP" ] || { echo "SKIP: $RP missing"; exit 77; }
command -v xdelta3 >/dev/null || { echo "SKIP: xdelta3 not installed (the PACKAGER encodes with it; the applier needs only python3)"; exit 77; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"

echo "== 1. round trip: package -> apply to pristine dumps -> byte-identical =="
python3 tools/package_release.py "$RP" "$W/rel" --romdir "$ROMDIR" --name "$NAME" \
    --version "$(grep -h '^version_text' build/manifest/donovan.toml | sed 's/.*= *"\(.*\)"/\1/')" \
    > "$W/pack.log" 2>&1 || { echo "FAIL: packager"; tail -5 "$W/pack.log"; exit 1; }
grep "^packaged" "$W/pack.log"
# THE KNOWN-BAD INPUTS, built right after packaging (section 2 runs them as
# controls); under CONTROL=<name> the named one is what section 1 APPLIES, and
# this run must FAIL.
cp -r "$W/rel/$NAME" "$W/bad_patch"
pf="$(find "$W/bad_patch/patches" -name '*.xdelta' | head -1)"
python3 -c "import sys;p=sys.argv[1];b=bytearray(open(p,'rb').read());b[len(b)//2]^=0xFF;open(p,'wb').write(bytes(b))" "$pf"
cp -r "$W/rel/$NAME" "$W/bad_manifest"
python3 - "$W/bad_manifest/manifest.json" <<'PY'
import json, sys
m = json.load(open(sys.argv[1]))
for e in m["zips"]["vsavjw.zip"]:
    if "patch" in e: e["sha1"] = "0" * 40; break
json.dump(m, open(sys.argv[1], "w"))
PY
# a patch RE-ENCODED with secondary compression: same bytes when decoded by
# xdelta3, but the applier's decoder must REFUSE it (a compressed stream would
# hide reference bytes from section 3's scan — the whole reason -S none)
cp -r "$W/rel/$NAME" "$W/bad_lzma"
pl="$(find "$W/bad_lzma/patches" -name 'd_vsw_43.xdelta' | head -1)"
python3 - "$W/bad_lzma/manifest.json" "$pl" "$ROMDIR" <<'PY'
import json, sys, subprocess, tempfile, os, zipfile, hashlib
mf, pf, romdir = sys.argv[1:4]
m = json.load(open(mf)); e = next(x for x in m["zips"]["vsavjw.zip"] if x.get("patch", "").endswith("d_vsw_43.xdelta"))
w = tempfile.mkdtemp()
src = os.path.join(w, "source.bin")
with open(src, "wb") as f:
    for z in m["source"]["order"]:
        zf = zipfile.ZipFile(os.path.join(romdir, z))
        for n in sorted(zf.namelist()): f.write(zf.read(n))
tgt = os.path.join(w, "t.bin"); subprocess.run(["xdelta3", "-d", "-f", "-s", src, pf, tgt], check=True)
subprocess.run(["xdelta3", "-e", "-S", "lzma", "-f", "-s", src, tgt, pf], check=True)
e["patch_size"] = os.path.getsize(pf); e["patch_sha1"] = hashlib.sha1(open(pf, "rb").read()).hexdigest()
json.dump(m, open(mf, "w"))
PY
mkdir -p "$W/bad_roms"
for z in vsavj vsav vsav2; do ln -s "$ROMDIR/$z.zip" "$W/bad_roms/$z.zip"; done   # three dumps since 14z-149
rm "$W/bad_roms/vsavj.zip"
python3 - "$ROMDIR/vsavj.zip" "$W/bad_roms/vsavj.zip" <<'PY'
import zipfile, sys
zi, zo = zipfile.ZipFile(sys.argv[1]), zipfile.ZipFile(sys.argv[2], "w")
for n in zi.namelist():
    d = bytearray(zi.read(n))
    if n == "vm3j.05a": d[100] ^= 1
    zo.writestr(n, bytes(d))
PY
APPLY_DIR="$W/rel/$NAME"; APPLY_ROMDIR="$ROMDIR"
case "$VS_CTL" in
corrupted-patch)  APPLY_DIR="$W/bad_patch" ;;
wrong-target-sha1) APPLY_DIR="$W/bad_manifest" ;;
wrong-dump)       APPLY_ROMDIR="$W/bad_roms" ;;
secondary-compressed-patch) APPLY_DIR="$W/bad_lzma" ;;
esac
python3 "$APPLY_DIR/apply_release.py" --romdir "$APPLY_ROMDIR" --out "$W/applied" \
    > "$W/apply.log" 2>&1 || { echo "FAIL: applier"; tail -5 "$W/apply.log"; exit 1; }
python3 - "$RP" "$W/applied" <<'PY' || fail=1
import sys, zipfile, hashlib, os
a, b = sys.argv[1:3]
n = 0
for z in sorted(os.listdir(a)):
    if not z.endswith(".zip"): continue
    za, zb = zipfile.ZipFile(os.path.join(a, z)), zipfile.ZipFile(os.path.join(b, z))
    if sorted(za.namelist()) != sorted(zb.namelist()):
        print(f"FAIL: {z} member inventory differs"); sys.exit(1)
    for m in za.namelist():
        if za.read(m) != zb.read(m):
            print(f"FAIL: {z}/{m} differs after the round trip"); sys.exit(1)
        n += 1
print(f"  ok: {n} members byte-identical after the round trip")
PY
# --sha-only, not a stderr scrape: this assertion is about the PROGRAM
# fingerprint, and --sha-only prints exactly that and nothing else. The old
# form piped 2>&1 into a hex grep, which only ever worked while the build was
# UNREGISTERED (a registered build prints its set NAME, no hex at all) and
# which the 14z-132 dual-key resolver would have handed the whole-set key.
fp() { python3 tools/build_fingerprint.py "$1" --set vsavjw --sha-only; }
fa="$(fp "$RP")"; fb="$(fp "$W/applied")"
[ -n "$fa" ] && [ "$fa" = "$fb" ] && echo "  ok: program fingerprint $fb reproduced" \
    || { echo "FAIL: fingerprint $fa vs $fb"; fail=1; }
ma="$(python3 tools/artifact_manifest.py "$RP")"; mb="$(python3 tools/artifact_manifest.py "$W/applied")"
[ "$ma" = "$mb" ] && echo "  ok: whole-artifact manifest reproduced ($mb)" \
    || { echo "FAIL: whole-artifact manifest $ma vs $mb"; fail=1; }

echo "== 2. the applier refuses bad inputs and writes nothing =="
refuse() { # refuse <name> <reldir> <romdir>
    if python3 "$2/apply_release.py" --romdir "$3" --out "$W/out_$1" > "$W/$1.log" 2>&1; then
        vs_ctl_dead "$1" "was ACCEPTED"; fail=1
    elif [ -e "$W/out_$1" ] && ls "$W/out_$1"/*.zip >/dev/null 2>&1; then
        vs_ctl_dead "$1" "refused but wrote output zips"; fail=1
    else
        vs_ctl_fired "$1" "refused ($(tail -1 "$W/$1.log" | cut -c1-70))"
    fi
}
refuse corrupted-patch   "$W/bad_patch"    "$ROMDIR"
refuse wrong-target-sha1 "$W/bad_manifest" "$ROMDIR"
refuse wrong-dump        "$W/rel/$NAME"    "$W/bad_roms"
refuse secondary-compressed-patch "$W/bad_lzma" "$ROMDIR"

echo "== 3. rule 7: no verbatim reference-ROM run in any patch file =="
# under CONTROL=planted-reference-chunk the scanned set is a COPY of the
# patches with the control file (a reference chunk appended) inside it
SCAN_PDIR="$W/rel/$NAME/patches"; PLANT=0
vs_ctl_is planted-reference-chunk && { cp -r "$W/rel/$NAME/patches" "$W/patches_mode"; SCAN_PDIR="$W/patches_mode"; PLANT=1; }
PLANT="$PLANT" python3 - "$ROMDIR" "$SCAN_PDIR" "$W/control.xdelta" <<'PY' || fail=1
import sys, os, zipfile, hashlib
romdir, pdir, ctrl = sys.argv[1:4]
WIN = 64
MOD = (1 << 61) - 1; B = 257
idx = set(); chunk0 = None
for z in ("vsavj.zip", "vsav.zip", "vsav2.zip", "vhunt2.zip"):   # the rule-7 index keeps vhunt2: a verbatim run of it is a ROM byte whether or not the source blob holds it
    zf = zipfile.ZipFile(os.path.join(romdir, z))
    for n in zf.namelist():
        d = zf.read(n)
        for o in range(0, len(d) - WIN + 1, WIN):
            c = d[o:o + WIN]
            if len(set(c)) < 8: continue          # skip fills (not copyrightable, and common)
            idx.add(hashlib.sha1(c).digest()[:8])
            if chunk0 is None and len(set(c)) > 40: chunk0 = c
def scan(path):
    d = open(path, "rb").read(); hits = 0
    for o in range(0, len(d) - WIN + 1):
        if hashlib.sha1(d[o:o + WIN]).digest()[:8] in idx:
            hits += 1
    return len(d), hits
total = 0; bad = []
p0 = os.path.join(pdir, sorted(os.listdir(pdir))[0])
f0 = sorted(os.listdir(p0))[0]
if os.environ.get("PLANT") == "1":            # the mode: the control file joins the scanned set
    open(os.path.join(p0, "zz_control.xdelta"), "wb").write(open(os.path.join(p0, f0), "rb").read() + chunk0 + chunk0)
for root, _, files in os.walk(pdir):
    for f in files:
        n, hits = scan(os.path.join(root, f)); total += n
        if hits: bad.append((f, hits))
if bad:
    print("FAIL: verbatim reference-ROM runs in patches:", bad); sys.exit(1)
print(f"  ok: {total} patch bytes scanned against {len(idx)} reference chunks — no verbatim run")
# must-fire control: one reference chunk appended to a copy of a patch
open(ctrl, "wb").write(open(os.path.join(p0, f0), "rb").read() + chunk0 + chunk0)
n, hits = scan(ctrl)
if not hits:
    print("CONTROL DEAD: planted-reference-chunk — the rule-7 scan did not fire on a planted reference chunk"); sys.exit(1)
print(f"CONTROL FIRED: planted-reference-chunk — a planted reference chunk is caught ({hits} hits)")
PY

echo "== 4. the per-platform layout of the tree's release/$NAME (14z-113, docs/project/release_format.md) =="
REL="release/$NAME"
if [ ! -d "$REL" ]; then
    vs_ctl_is missing-emulator-dir && { echo "REFUSED: CONTROL=missing-emulator-dir is not a mode of this gate (no $REL in the tree)"; exit 3; }
    echo "  (no $REL in the tree — layout check not applicable)"
else
    # the known-bad layout, built first; under CONTROL=missing-emulator-dir it
    # IS the release the checks below read, and this run must FAIL
    cp -r "$REL" "$W/layout_bad"; rm -rf "$W/layout_bad/mame/emulator"
    vs_ctl_is missing-emulator-dir && REL="$W/layout_bad"
    # the other two known-bad layouts (14z-148): a file outside the ruled
    # inventory, and a README without its diagnostics section
    cp -r "release/$NAME" "$W/layout_stray"; echo "notes" > "$W/layout_stray/mame/notes.bin"
    vs_ctl_is stray-file && REL="$W/layout_stray"
    cp -r "release/$NAME" "$W/layout_readme"
    sed -i '' '/^## If it does not work/d' "$W/layout_readme/fbneo/README.md"
    vs_ctl_is readme-missing-section && REL="$W/layout_readme"
    for p in fbneo mame mister; do
        for f in manifest.json apply_release.py README.md patches; do
            [ -e "$REL/$p/$f" ] || { echo "FAIL: $REL/$p/$f missing"; fail=1; }
        done
    done
    m0="$(shasum "$REL/fbneo/manifest.json" | cut -c1-40)"
    for p in mame mister; do
        [ "$(shasum "$REL/$p/manifest.json" | cut -c1-40)" = "$m0" ] \
            || { echo "FAIL: $REL/$p/manifest.json differs from fbneo's"; fail=1; }
    done
    [ "$fail" = 0 ] && echo "  ok: three platform dirs, each with the patch set; manifests byte-identical ($(echo "$m0" | cut -c1-8))"
    for p in fbneo mame; do
        cmp -s "$REL/$p/emulator/0002-cps2-wide-v1.patch" "emu/$p-patches/0002-cps2-wide-v1.patch" \
            && [ -f "$REL/$p/EMULATOR.md" ] \
            || { echo "FAIL: $REL/$p/emulator/ patch missing or not the tree's emu/$p-patches/0002"; fail=1; }
    done
    ls "$REL/mister/"*.mra >/dev/null 2>&1 && [ -f "$REL/mister/BITSTREAM.txt" ] && [ -f "$REL/mister/MISTER.md" ] \
        || { echo "FAIL: $REL/mister/ lacks an .mra, BITSTREAM.txt or MISTER.md"; fail=1; }
    grep -q 'sha256' "$REL/mister/BITSTREAM.txt" \
        || { echo "FAIL: BITSTREAM.txt carries no sha256 line"; fail=1; }
    # the bitstream itself is present and IS the one the record names (14z-113, maintainer: a build resource,
    # canonical under release/bitstreams/<seed>/, hash-verified into every release, never copied from another release)
    rbf="$(ls "$REL/mister/"*.rbf 2>/dev/null | head -1)"
    want="$(grep -oE 'sha256 +[0-9a-f]{64}' "$REL/mister/BITSTREAM.txt" | grep -oE '[0-9a-f]{64}')"
    if [ -z "$rbf" ]; then echo "FAIL: $REL/mister/ holds no .rbf"; fail=1
    elif [ "$(shasum -a 256 "$rbf" | cut -c1-64)" != "$want" ]; then echo "FAIL: $rbf sha256 != BITSTREAM.txt's"; fail=1
    else echo "  ok: $(basename "$rbf") present, sha256 ${want%${want#????????}}… matches its record"; fi
    cur="release/bitstreams/$(cat release/bitstreams/CURRENT 2>/dev/null)"
    [ -f "$cur/BITSTREAM.txt" ] && cmp -s "$cur/BITSTREAM.txt" "$REL/mister/BITSTREAM.txt" \
        || { echo "FAIL: $REL/mister/BITSTREAM.txt is not the canonical $cur/BITSTREAM.txt (stale CURRENT, or copied from another release?)"; fail=1; }
    # cross-platform leakage: a platform dir must hold NOTHING of another platform's
    ls "$REL/fbneo/"*.mra "$REL/mame/"*.mra "$REL/fbneo/"*.rbf "$REL/mame/"*.rbf >/dev/null 2>&1 \
        && { echo "FAIL: MiSTer files inside an emulator platform dir"; fail=1; }
    [ -e "$REL/mister/emulator" ] && { echo "FAIL: emulator patch inside mister/"; fail=1; }
    [ "$fail" = 0 ] && echo "  ok: emulator dirs carry the tree's driver patch + EMULATOR.md; mister/ carries MRAs + BITSTREAM.txt + MISTER.md; no cross-platform leakage"
    # THE INVENTORY (ruled 2026-09-11, docs/project/release_format.md "What a
    # release IS"): every file under a platform dir is in the definition and
    # every item of the definition is present. A file nobody ruled in does
    # not ship — that is how a ROM byte, a build log or a scratch file would
    # otherwise ride along.
    inv_check() {  # inv_check <platform> <allowed-regex> — every file must match
        find "$REL/$1" -type f | sed "s|^$REL/$1/||" | grep -vE "$2" > "$W/inv_$1.txt" || true
        if [ -s "$W/inv_$1.txt" ]; then echo "FAIL: $1/ ships files outside the ruled inventory:"; sed 's/^/        /' "$W/inv_$1.txt"; fail=1; fi
    }
    EMU_INV='^(manifest\.json|apply_release\.py|README\.md|EMULATOR\.md|patches/vsavjw/d_[a-z0-9_]+\.xdelta|emulator/0002-cps2-wide-v1\.patch|emulator/bin/[a-z0-9-]+/[^/]+)$'
    inv_check fbneo "$EMU_INV"; inv_check mame "$EMU_INV"
    inv_check mister '^(manifest\.json|apply_release\.py|README\.md|MISTER\.md|BITSTREAM\.txt|jtcps2w\.rbf|[^/]+\.mra|patches/vsavjw/d_[a-z0-9_]+\.xdelta)$'
    # every prebuilt-binary dir: BINARY.txt names each file with a matching sha256
    for rec in "$REL"/fbneo/emulator/bin/*/BINARY.txt "$REL"/mame/emulator/bin/*/BINARY.txt; do
        [ -f "$rec" ] || continue
        bd="$(dirname "$rec")"
        # the record is tracked, the files are release assets (ruled 14z-149): record-only is a
        # fresh clone, not a defect — the packager puts the files beside it on the release host
        [ "$(ls "$bd" | grep -vc '^BINARY.txt$')" != 0 ] || { echo "  note: $bd holds the record only (the binaries are release assets)"; continue; }
        grep -E '^sha256 +[0-9a-f]{64} +[^ ]+' "$rec" | while read -r _ want fname; do
            [ "$(shasum -a 256 "$bd/$fname" 2>/dev/null | cut -c1-64)" = "$want" ] || echo "BAD $bd/$fname"
        done > "$W/bin_$$.txt"
        if [ -s "$W/bin_$$.txt" ]; then cat "$W/bin_$$.txt"; echo "FAIL: a prebuilt binary does not match its BINARY.txt"; fail=1; fi
        for f in "$bd"/*; do
            case "$(basename "$f")" in BINARY.txt) ;; *) grep -q " $(basename "$f")\$" "$rec" || { echo "FAIL: $f is not named by its BINARY.txt"; fail=1; } ;; esac
        done
    done
    # THE END-USER README: the sections the ruling asks for, on every platform copy
    for p in fbneo mame mister; do
        for h in "## What you need" "## Build the romset" "## Play on " "## If it does not work" "NO ROM DATA"; do
            grep -q "$h" "$REL/$p/README.md" || { echo "FAIL: $REL/$p/README.md lacks '$h'"; fail=1; }
        done
    done
    [ "$fail" = 0 ] && echo "  ok: every shipped file is in the ruled inventory, every prebuilt binary matches its record, every README carries the five end-user sections"
    # must-fire control: the same checks on a copy with mame/emulator/ removed must FAIL
    if cmp -s "$W/layout_bad/mame/emulator/0002-cps2-wide-v1.patch" "emu/mame-patches/0002-cps2-wide-v1.patch" 2>/dev/null; then
        vs_ctl_dead missing-emulator-dir "a release missing mame/emulator/ was accepted"; fail=1
    else
        vs_ctl_fired missing-emulator-dir "a release missing mame/emulator/ is rejected"
    fi
    if find "$W/layout_stray/mame" -type f | sed "s|^$W/layout_stray/mame/||" | grep -vE "$EMU_INV" | grep -q .; then
        vs_ctl_fired stray-file "mame/notes.bin is outside the inventory and would fail the check"
    else
        vs_ctl_dead stray-file "a stray file passed the inventory regex"; fail=1
    fi
    if grep -q "^## If it does not work" "$W/layout_readme/fbneo/README.md"; then
        vs_ctl_dead readme-missing-section "the section is still there in the perturbed copy"; fail=1
    else
        vs_ctl_fired readme-missing-section "a README without its diagnostics section would fail the check"
    fi
fi

if [ "$fail" = 0 ]; then
    echo "PASS: release package — round-trips byte-identical from pristine dumps,"
    echo "      the applier refuses bad patches/manifests/dumps without writing,"
    echo "      and no patch carries reference-ROM bytes (rule 7)"
else
    echo "FAIL: release package"; exit 1
fi
