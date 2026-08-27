#!/bin/sh
# build_merged.sh — the 3-tenant merged build WITH gfx (M3b Phase 3 S4,
# 14z-83). Program half: the same generator invocation the merged-legacy
# instrument uses (audit_merged_legacy.sh section B — one process, three
# extracts, three manifests). Gfx half: the S2 chain, one build_gfx link
# per tenant over the prior link's members + ledger, consuming the MERGED
# generator's own per-tenant side files. Packs a runnable vsavjw set.
#
# THIS PRODUCES THE FIRST PLAYTESTABLE 3-TENANT ARTIFACT. It is NOT
# registered (registry rows are a freeze decision, S6); run_suite refuses
# it by design until then.
#
# Usage: ROMDIR=... [WIDE_ROMSET=...] tools/build_merged.sh <outbase>
#        (e.g. tools/build_merged.sh build/m3b_merged)
set -eu
OUT="${1:?usage: build_merged.sh <outbase>}"
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
WIDE_ZIP="${WIDE_ROMSET:-$PWD/build/wide0/rompath/vsavjw.zip}"

# CLAUDE.md §3 IS NOT OPTIONAL FOR THE SECOND BUILDER EITHER (14z-94,
# GitHub #28). This script reads $ROMDIR at five points — the generator's
# --vsavj, patch_prg, build_gfx_donovan and pack_build — and used to run no
# checksum gate at all, so pointing ROMDIR at a different vsav revision or a
# re-dumped/renamed zip produced a complete 3-tenant artifact with no
# complaint. The only downstream tell was a fingerprint matching nothing, and
# this script prints that as information rather than checking it. Same guard
# tools/build_donovan.sh:81 already carried; it was simply never carried over.
python3 tools/audit_roms.py "$ROMDIR" > /dev/null || {
    echo "ROM audit FAILED — stop (CLAUDE.md §3)"; exit 1; }

# the three frozen verticals' extracts are the generator's inputs
# (extraction is deterministic — test_m3a_reproducible re-extracts and
# all four fingerprints are bit-exact, so these dirs ARE the bytes)
D_EX="build/m5_wide/extract"
H_EX="build/hui32/extract"
P_EX="build/pyron21/extract"

# RULE 3 IS ONE COMMAND (14z-95, GitHub #27, maintainer-ruled 2026-08-18).
# These four inputs are ROM-derived and therefore untracked by rule 7, and
# until now NOTHING IN THE TREE KNEW HOW TO MAKE THEM — the recipe was prose
# in HANDOFF.md and an `echo` on audit_merged_legacy's SKIP path. So the
# milestone deliverable was reproducible on one machine only, which is
# precisely what rule 3 forbids. The helper CREATES only what is absent and
# never touches what exists, so it does not collide with the #26 guard that
# protects these same dirs.
echo "== 0: inputs (regenerated only if absent) =="
WIDE_ZIP="$WIDE_ZIP" ROMDIR="$ROMDIR" tools/ensure_merged_inputs.sh || {
    echo "FAIL: could not resolve the merged build's inputs"; exit 1; }

rm -rf "$OUT"; mkdir -p "$OUT"

echo "== 1: merged program image (3 tenants, one generator process) =="
python3 tools/gen_donovan_patch.py "$D_EX" "$OUT/patch" \
    --extract "$H_EX" --extract "$P_EX" \
    --vsavj "$ROMDIR/vsavj.zip" --stage 6 \
    --port build/manifest/donovan.toml --port build/manifest/huitzil.toml \
    --port build/manifest/pyron.toml \
    --profile cps2-wide-v1 --allow-plausible --tripwire-open \
    > "$OUT/gen.log" 2>&1 || {
        echo "FAIL: generation errored"; tail -15 "$OUT/gen.log"; exit 1; }
grep -q '^GENERATION OK' "$OUT/gen.log" || {
    echo "FAIL: no GENERATION OK"; tail -15 "$OUT/gen.log"; exit 1; }
# The path goes in as sys.argv, not interpolated into the SOURCE (14z-94,
# GitHub #66). <outbase> is a CLI argument: a path containing a quote or an
# apostrophe broke the program text, and this file already used the correct
# pattern four lines later. The inconsistency is what made it likely to be
# copied forward.
NOPS="$(python3 - "$OUT/patch/patch.json" <<'PYOPS'
import json, sys
print(len(json.load(open(sys.argv[1]))["ops"]))
PYOPS
)"
# THE EXPECTED COUNT IS DERIVED, NOT COPIED (14z-94). This guard used to
# carry its own literal while its comment said "Matches test_tenant_loop's
# frozen 3-tenant count" — two copies of one fact, and they drifted the first
# time the count moved: re-freezing test_tenant_loop for #91 left this
# builder still demanding the old number, so the merge stayed blocked with a
# message telling you to do the thing you had just done. Read it from the
# gate that owns it, and hard-fail if it cannot be read rather than falling
# back to a literal — a default here would re-create the drift silently.
# History: 14z-86 678 -> 729 (the M5 voice batch), 14z-91 -> 753 (the walker
# relocation), 14z-94 -> 752 (#91's reconciliation row retires one planted
# ILLEGAL; see test_tenant_loop's RE-FROZEN note for the attribution).
EXPECT_OPS="$(awk '/^check_n "3 tenants"/ {print $5; exit}' "$REPO/tests/test_tenant_loop.sh")"
case "$EXPECT_OPS" in
    ''|*[!0-9]*)
        echo "FAIL: could not read the frozen 3-tenant op count from"
        echo "      tests/test_tenant_loop.sh (got '$EXPECT_OPS'). That gate"
        echo "      owns the number; fix the read rather than hardcoding one."
        exit 1;;
esac
[ "$NOPS" = "$EXPECT_OPS" ] || {
    echo "FAIL: $NOPS ops, frozen fixture is $EXPECT_OPS (re-freeze"
    echo "      test_tenant_loop FIRST if the merge legitimately changed)"
    exit 1; }
echo "  ok: $NOPS ops (the frozen test_tenant_loop fixture, read from it)"
python3 tools/patch_prg.py "$ROMDIR/vsavj.zip" "$OUT/prg" \
    --patch "$OUT/patch/patch.json" > "$OUT/patch_prg.log" 2>&1 || {
        echo "FAIL: patch_prg refused the merged patch"
        tail -10 "$OUT/patch_prg.log"; exit 1; }

echo "== 2: gfx chain — one link per tenant over the prior link =="
# per-tenant walks (the tenant's ratified layout span over its own
# extract), inventories merged with extra_tiles where a set exists
CHAIN=""
for T in donovan:0x13:$D_EX huitzil:0x10:$H_EX pyron:0x11:$P_EX; do
    name="${T%%:*}"; rest="${T#*:}"; char="${rest%%:*}"; ex="${rest#*:}"
    span="$(python3 - "$char" <<'PY'
import sys
sys.path.insert(0, "tools")
from _minitoml import loads
lay = loads(open("build/manifest/gfx_layout3.toml").read())
row = {r["id"]: r for r in lay["tenant"]}[int(sys.argv[1], 16)]
print(f"{row['anim_base']:#x} {row['anim_base'] + row['anim_len']:#x} "
      f"{row['sweep_lo']:#x} {row['sweep_hi']:#x}")
PY
)"
    set -- $span
    python3 tools/obj_records.py "$ex/region_anim.bin" \
        --base "$1" --start "$1" --end "$2" \
        --cptr-lo 0x300000 --cptr-hi 0x361000 \
        --sweep-lo "$3" --sweep-hi "$4" \
        --json "$OUT/tiles_$name.json" > /dev/null
    EXTRA="build/manifest/extra_tiles/$char.json"
    if [ -f "$EXTRA" ]; then
        python3 - "$OUT/tiles_$name.json" "$EXTRA" <<'PY'
import json, sys
inv = json.load(open(sys.argv[1]))
extra = json.load(open(sys.argv[2]))["tiles"]
merged = sorted(set(inv) | set(extra))
json.dump(merged, open(sys.argv[1], "w"))
print(f"  extra tiles: +{len(merged) - len(inv)}, "
      f"inventory {len(inv)} -> {len(merged)}")
PY
    fi
    # this tenant's row of the generator's tenants.json, as a
    # tenant.json-shaped file for build_gfx --tenant
    python3 - "$OUT" "$name" <<'PY'
import json, sys
tens = json.load(open(sys.argv[1] + "/patch/tenants.json"))
row = {t["name"]: t for t in tens}[sys.argv[2]]
json.dump(row, open(f"{sys.argv[1]}/tenant_{sys.argv[2]}.json", "w"))
PY
    # per-tenant side-file spellings from the MERGED generator's own
    # output: tenant 0 keeps the bare names, later tenants ride .<name>
    if [ "$name" = donovan ]; then SP=""; else SP=".$name"; fi
    FLAGS="--tiles $OUT/tiles_$name.json"
    [ -f "$OUT/patch/effect_map$SP.json" ] && \
        FLAGS="$FLAGS --effects $OUT/patch/effect_map$SP.json"
    FLAGS="$FLAGS --select-tiles $OUT/patch/select_tiles$SP.json"
    [ -f "$OUT/patch/select_bank5$SP.json" ] && \
        FLAGS="$FLAGS --select-bank5 $OUT/patch/select_bank5$SP.json"
    [ -f "$OUT/patch/effect_c5$SP.json" ] && \
        FLAGS="$FLAGS --effect-c5 $OUT/patch/effect_c5$SP.json"
    # the wheel is ENGINE-level: the merged generator emits it ONCE and
    # link 0 places it (later links would only benign-skip every tile)
    [ "$name" = donovan ] && [ -f "$OUT/patch/wheel_bank5.json" ] && \
        FLAGS="$FLAGS --wheel-bank5 $OUT/patch/wheel_bank5.json"
    [ -f "build/manifest/strip_tiles/$char.json" ] && \
        FLAGS="$FLAGS --strip-tiles build/manifest/strip_tiles/$char.json"
    FLAGS="$FLAGS --effect-tail build/manifest/effect_tail.json"
    FLAGS="$FLAGS --tenant $OUT/tenant_$name.json"
    [ -n "$CHAIN" ] && FLAGS="$FLAGS --chain $CHAIN"
    echo "  -- link $name"
    # shellcheck disable=SC2086
    python3 tools/build_gfx_donovan.py "$ROMDIR" "$OUT/gfx_$name" $FLAGS \
        > "$OUT/gfx_$name.log" 2>&1 || {
            echo "FAIL: gfx link $name"; tail -8 "$OUT/gfx_$name.log"
            exit 1; }
    tail -2 "$OUT/gfx_$name.log" | sed 's/^/     /'
    CHAIN="$OUT/gfx_$name"
done

echo "== 3: pack (program + LAST link's members) =="
KEY_SET=vsavj ROMDIR="$ROMDIR" tools/pack_build.sh "$OUT/prg" "$OUT/rompath" \
    --set vsavjw --merge "$WIDE_ZIP" > "$OUT/pack.log" 2>&1 || {
        echo "FAIL: pack"; tail -10 "$OUT/pack.log"; exit 1; }
RPZIP="$(cd "$OUT/rompath" && pwd)/vsavjw.zip"
# THE PATCHED GROUP-A MEMBERS GO INSIDE vsavjw.zip, AND NO vsav.zip IS
# WRITTEN (14z-112). Until now the build packed a PATCHED vsav.zip into the
# rompath, which is why a MiSTer SD card could not hold both this profile and
# stock Vampire Savior: `games/mame/vsav.zip` can only be one file, and a
# stock MRA pointed at the patched one gets wrong art SILENTLY (the bundle
# README had to warn about it). Since jtframe's .rom builder matches members
# by CRC32 ALONE (gen_vsavjw_xml.py header) and FBNeo/MAME search the set's
# own zip first, the patched members resolve from vsavjw.zip on every
# implementation, and the pristine vsav.zip serves stock and our group-B
# needs alike. Measured 14z-112: MAME takes the patched member from
# vsavjw.zip (verifyroms FOUND crc = the patched one) and a full replay of
# tests/inp/run-merged-m9-05 is IDENTICAL frame-for-frame, 7490/7490.
( cd "$CHAIN" && zip -q -X "$RPZIP" vsw.*m vm3.*m )
echo "  ok: group-A members + group-C simms into vsavjw.zip ($CHAIN); no vsav.zip packed"
# WIDE v1.1 (14z-86): authored Z80 songs (M5) into vsw.z01/z02 — same
# uniform injection as build_donovan.sh's WIDE branch.
if [ -f build/manifest/qs_songs.toml ]; then
    python3 tools/build_qs_songs.py "$RPZIP" "$ROMDIR/vsav2.zip" --vsav "$ROMDIR/vsav.zip" || {
        echo "FAIL: qs song injection"; exit 1; }
fi
# group B must never be shipped at all (de-substitution): the set carries no
# vsav.zip now, so the check is that vsavjw.zip contains no group-B member —
# if one ever appeared it would front the pristine parent copy.
python3 - "$OUT/rompath/vsavjw.zip" <<'PY'
import sys, zipfile
z = zipfile.ZipFile(sys.argv[1])
bad = [n for n in ("vm3.14m", "vm3.16m", "vm3.18m", "vm3.20m") if n in z.namelist()]
assert not bad, f"group B members must not ship in vsavjw.zip: {bad}"
assert "vsav.zip" not in __import__("os").listdir(__import__("os").path.dirname(sys.argv[1])), \
    "no vsav.zip may be packed: stock Vampire Savior must keep the pristine one"
print("  ok: no group-B members shipped, and no vsav.zip packed")
PY
python3 tools/audit_romset_identity.py "$OUT/rompath" || {
    echo "FAIL: member-identity audit — do not run anything from this set"
    exit 1; }

echo "== 4: per-tenant static verification =="
python3 tools/cps2_decrypt.py "$ROMDIR/vsavj.zip" "$OUT/vanilla_op.bin" \
    --data-out "$OUT/vanilla_data.bin" > /dev/null 2>&1
for T in donovan:$D_EX huitzil:$H_EX pyron:$P_EX; do
    name="${T%%:*}"; ex="${T#*:}"
    # 14z-90 (GitHub issue #14): these two were piped through `sed`, so under
    # `#!/bin/sh` + `set -eu` with no pipefail the pipeline's status was sed's
    # — always 0 — and BOTH verdict-bearing verifiers were unconditionally
    # green. Third payment of docs/project/gotchas.md "Pipe a build tool
    # through tail". `set -o pipefail` is NOT the fix here: this file is clean
    # POSIX and tests/test_shell_portability.sh now fails any #!/bin/sh script
    # that uses it. Redirect, then indent the log — same idiom as b4df1ff.
    #
    # This guard is not theoretical. It aborted on huitzil from merged6 to
    # merged7 (record/entry parity 1374,14911 != 1375,14978, and 34 tile codes
    # outside the placed window) — printed and unread until the status stopped
    # being swallowed. RESOLVED 14z-92 (GitHub #75): that was a VERIFIER
    # artifact, not a build defect. obj_records.walk's pointer pass was
    # re-deriving record structure from the relocated image, and the merged
    # placement window happened to contain a straddled datum's value; the pass
    # is now relocation-aware (ptr_allow), as the sweep pass has been since
    # 14z-74. Gate: tests/test_obj_record_walk.sh.
    echo "  -- verify_gfx_build --tenant $name"
    python3 tools/verify_gfx_build.py "$OUT" --tenant "$name" \
        --gfx-dir "$OUT/gfx_$name" --extract-dir "$ex" \
        > "$OUT/verify_$name.log" 2>&1 || {
            sed 's/^/     /' "$OUT/verify_$name.log"
            echo "FAIL: verify_gfx_build --tenant $name — this set is NOT" >&2
            echo "      verified; do not run, register or playtest it." >&2
            exit 1; }
    sed 's/^/     /' "$OUT/verify_$name.log"
    echo "  -- check_tenant_hud --tenant $name"
    python3 tools/check_tenant_hud.py "$OUT" "$OUT/vanilla_data.bin" \
        "$ROMDIR" --tenant "$name" --gfx-dir "$CHAIN" \
        > "$OUT/hud_$name.log" 2>&1 || {
            sed 's/^/     /' "$OUT/hud_$name.log"
            echo "FAIL: check_tenant_hud --tenant $name — this set is NOT" >&2
            echo "      verified; do not run, register or playtest it." >&2
            exit 1; }
    sed 's/^/     /' "$OUT/hud_$name.log"
done

FP="$(python3 tools/build_fingerprint.py "$OUT/rompath;$ROMDIR" --set vsavjw --sha-only)"
# Generation-neutral README (14z-100: the old template said "753-op" and
# "NOT REGISTERED" forever — a stale literal shipping in every build dir).
NOPS="$(python3 -c "import json,sys;print(len(json.load(open('$OUT/patch/patch.json'))['ops']))" 2>/dev/null || echo '?')"
cat > "$OUT/README.txt" <<EOF
3-TENANT MERGED BUILD WITH GFX (tools/build_merged.sh).
Program: the $NOPS-op merged image. Gfx: the S2 chain (D -> H -> P), last
link's members packed; group B pristine.
Registration is a STATE decision: merged builds get NO registry.tsv row by
convention (tag + HANDOFF row when frozen) — check HANDOFF's build registry
for whether this fingerprint is a frozen generation.
fingerprint: $FP
EOF
echo "build fingerprint: $FP"
echo "OK: merged build with gfx at $OUT/rompath (register at S6 freeze time)"
