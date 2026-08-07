#!/bin/sh
# build_donovan.sh — the donovan-m2 build driver: checksum gate -> extract
# (vhunt2 oracle) -> generate staged patch -> apply -> pack runnable rompath.
#
# Usage: ROMDIR=... tools/build_donovan.sh <stage 1-5> [outbase=build/donovan]
#
# Output: <outbase>/rompath/vsavj.zip — run with
#   MAME_ROMPATH="<outbase>/rompath;$ROMDIR" tools/run_mame.sh vsavj ...
# All ROM-derived intermediates live under <outbase> (gitignored) and are
# regenerated from $ROMDIR on every run (repo rule 7).
set -eu
set -o pipefail  # 14z-10: a crashed build_gfx must not pack stale tiles silently

STAGE="${1:?usage: build_donovan.sh <stage 1-6> [outbase]}"
OUTBASE="${2:-build/donovan}"
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
mkdir -p "$OUTBASE"

# Tenant selection (14z-65, M3b): the driver serves any single-tenant
# manifest. Defaults preserve the Donovan behavior byte-for-byte
# (tests/test_m3a_reproducible.sh arbitrates). TENANT_CHAR must match the
# manifest's src_char — extract_char anchors on it and the generator
# rewrites its id immediates.
TENANT_MANIFEST="${TENANT_MANIFEST:-build/manifest/donovan.toml}"
TENANT_CHAR="${TENANT_CHAR:-0x13}"

python3 tools/audit_roms.py "$ROMDIR" > /dev/null || {
    echo "ROM audit FAILED — stop (CLAUDE.md §3)"; exit 1; }

# Decrypted analysis views (gitignored intermediates): the extractor and
# generator read build/out/<set>_{opcodes,data}.bin. Regenerate any that
# are missing — deterministic from the audited reference sets.
mkdir -p build/out
for _set in vsavj vsav2 vhunt2; do
    if [ ! -f "build/out/${_set}_opcodes.bin" ] || [ ! -f "build/out/${_set}_data.bin" ]; then
        echo "regenerating decrypted views for $_set ..."
        python3 tools/cps2_decrypt.py "$ROMDIR/${_set}.zip" \
            "build/out/${_set}_opcodes.bin" \
            --data-out "build/out/${_set}_data.bin" | tail -2
    fi
done

# EXTRA_ROOTS: absent-in-vsavj support routines ported as extra code
# regions (found by the stage-4 R1 loop; see docs/tables/reconciliation.md).
# Default = the full stage-4 set: the +0x34 newcomer-support zone, the tiny
# VS2 helpers, the id-normalization/char-init engine pair, the source-only
# per-game hook, and the 17 extra secondary-object handlers (types 59-75,
# forced-twin +0x34, caps = inter-handler gaps). Only the handler types
# Donovan actually spawns are ported (59-62); the other extras belong to
# Huitzil/Pyron and stay TRIPWIRED — loud if ever reached (space budget,
# session 5).
DEFAULT_ROOTS="0x5c800:0xd100,0x26142:0x1400,0x28122:0xe00,0x88512:0x2f00:s,0x905ae:0x300:s,0x2b7ef4:0xb20c:t0x2a4398:d"
# x2b7ef4 extends the old x2b8060 root 0x16C earlier: a companion anim
# word table sits just BEFORE the previous bound (session 13 mash crash —
# its ref was tripwired as data and read as an anim table). Twin verified
# byte-identical for the extension.
DEFAULT_ROOTS="$DEFAULT_ROOTS"
DEFAULT_ROOTS="$DEFAULT_ROOTS,0x65952:0x2d0:t0x65986,0x65c22:0x238:t0x65c56,0x65e5a:0x106a:t0x65e8e,0x66ec4:0x2b8:t0x66ef8"
# session 14w-c: type 63 IS spawned by Donovan's own deep-arcade flow —
# 21_don_mash tripped its tripwire (0xCB880) at frame 10050 once the CPU
# Felicia moved correctly (the pair-table fix changed the fight flow).
# The "59-62 only" assumption is measured-wrong for 63; handler ported
# with the standard +0x34 twin. 64-75 remain tripwired (still unseen).
DEFAULT_ROOTS="$DEFAULT_ROOTS,0x6717c:0x154:t0x671b0"
# DEFAULT_ROOTS is DONOVAN'S measured root census — it applies only to his
# char. Another tenant's census accumulates here as its R1 loop finds
# roots (EXTRA_ROOTS overrides for census experiments).
case "$TENANT_CHAR" in
    0x13) : ;;   # Donovan's census above
    0x10)
        # Huitzil census (14z-65, ladder): 0x55478 = his tail_code_ptr
        # row's engine-consumed routine — appended newcomer-support code
        # BELOW the 0x57000 window (the appended zone reaches 0x054xxx,
        # measured; docs/atlas/character_tables.md piecewise section).
        # 0xd143e = the 18-ring velocity-vector family (0x80 B/ring,
        # radius-indexed sin/cos pairs) his code bases at 0xd15be —
        # vs2-only bank data (the vsavj delta candidate is zeros);
        # structure-bounded, sibling-identical, twin at -0x76e.
        DEFAULT_ROOTS="0x55478,0xd143e:0x900:t0xd0cd0:d"
        ;;
    *)  DEFAULT_ROOTS="" ;;
esac
python3 tools/extract_char.py "$ROMDIR/vsav2.zip" "$OUTBASE/extract" \
    --char "$TENANT_CHAR" --oracle "$ROMDIR/vhunt2.zip" \
    --extra-roots "${EXTRA_ROOTS-$DEFAULT_ROOTS}" > "$OUTBASE/extract.log" 2>&1 \
    || { tail -20 "$OUTBASE/extract.log"; exit 1; }

# GEN_FLAGS: extra generator flags (e.g. "--allow-plausible --tripwire-open"
# for stage-4 experiment builds while the R1 map converges)
# shellcheck disable=SC2086
python3 tools/gen_donovan_patch.py "$OUTBASE/extract" "$OUTBASE/patch" \
    --vsavj "$ROMDIR/vsavj.zip" --stage "$STAGE" \
    --port "$TENANT_MANIFEST" ${GEN_FLAGS:-}

python3 tools/patch_prg.py "$ROMDIR/vsavj.zip" "$OUTBASE/prg" \
    --patch "$OUTBASE/patch/patch.json" | tail -3

# Stage 6+: select-screen portrait/name/highlight. Two mechanisms, chosen
# by the tenant's id (patch/tenant.json, written by the generator):
#   base-half id (the substituted slot 0x0F): tools/select_port.py in-place
#     record surgery on the host's records — the frozen-reference mechanism.
#   variant-half id (M3a de-substitution): the records were COMPOSED BY THE
#     GENERATOR into space-model allocations and the six array rows poked in
#     patch.json; select_port must NOT run — the host's records stay
#     vanilla. The generator also emitted the matching tile-placement map.
# The stage-6 gfx/select pipeline is still Donovan-specific (the
# obj_records anim span, select art, effect_tail anchors are his) — refuse
# loudly rather than build another tenant's gfx with his constants.
if [ "$STAGE" -ge 6 ] && [ "$TENANT_CHAR" != "0x13" ]; then
    echo "build_donovan.sh: stage >= 6 is Donovan-specific for now" >&2
    echo "  (obj_records span, select art, effect anchors — M3b Phase 3/4" >&2
    echo "  generalizes them). Build this tenant at stage <= 5." >&2
    exit 1
fi
TEN_ID="$(python3 -c "import json;print(json.load(open('$OUTBASE/patch/tenant.json'))['id'])")"
if [ "$STAGE" -ge 6 ]; then
    if [ "$TEN_ID" -lt 16 ]; then
        python3 tools/select_port.py "$OUTBASE/prg" --vs2 "$ROMDIR/vsav2.zip" \
            --tiles-out "$OUTBASE/select_tiles.json" | tail -5
    else
        echo "select: tenant at variant id $TEN_ID — records generated" \
             "(select_port skipped; the host's select records stay vanilla)"
        cp "$OUTBASE/patch/select_tiles.json" "$OUTBASE/select_tiles.json"
    fi
fi

rm -rf "$OUTBASE/rompath"
# CPS-2 WIDE builds pack as the vsavjw SET and fold in the profile's appended
# gfx/QSound members, which this pipeline does not produce itself. Detected
# from the generator's own output (patch.json carries an "image" block only
# when a profile-gated space was actually used), so the set name can never
# disagree with what was built.
PACK_SET="vsavj"
PACK_MERGE=""
if python3 -c "import json,sys; sys.exit(0 if json.load(open('$OUTBASE/patch/patch.json')).get('image') else 1)" 2>/dev/null; then
    PACK_SET="vsavjw"
    PACK_MERGE="${WIDE_ROMSET:-build/wide0/rompath/vsavjw.zip}"
    echo "WIDE build: packing as $PACK_SET (merging $PACK_MERGE)"
    ROMDIR="$ROMDIR" tools/pack_build.sh "$OUTBASE/prg" "$OUTBASE/rompath" \
        --set "$PACK_SET" --merge "$PACK_MERGE" > /dev/null
else
    ROMDIR="$ROMDIR" tools/pack_build.sh "$OUTBASE/prg" "$OUTBASE/rompath" > /dev/null
fi

# Stage 6+: gfx side — place Donovan's tiles into vsav's group-B members
# (Jedah band) and carry a patched vsav.zip in the rompath so it fronts
# the pristine ROMDIR copy. Program-side remap is stage-6 generator work
# (donovan.toml [gfx_remap] + stage-gated port_patch rows).
if [ "$STAGE" -ge 6 ]; then
    # STALE-OUTPUT GUARD (14z-62h, found by the maintainer's playtest):
    # build_gfx writes ONLY the members the current mode produces, but the
    # pack step globs the OUTPUT DIR — group-B members left over from a
    # previous (pre-group-C) build were re-packed into vsav.zip, so FBNeo
    # served Donovan's band as Jedah's while MAME silently hash-matched to
    # the pristine ROMDIR copy and hid it. Clean before generating.
    rm -f "$OUTBASE/gfx"/vm3.*m "$OUTBASE/gfx"/vsw.*m
    python3 tools/obj_records.py "$OUTBASE/extract/region_anim.bin" \
        --base 0x27F548 --start 0x27F548 --end 0x2A0448 \
        --cptr-lo 0x300000 --cptr-hi 0x361000 \
        --json "$OUTBASE/donovan_tiles.json" > /dev/null
    OVERLAY_TILES=""
    [ -f build/manifest/overlay/overlay_tiles.json ] && \
        OVERLAY_TILES="--overlay-tiles build/manifest/overlay/overlay_tiles.json"
    # shellcheck disable=SC2086
    python3 tools/build_gfx_donovan.py "$ROMDIR" "$OUTBASE/gfx" \
        --tiles "$OUTBASE/donovan_tiles.json" \
        --effects "$OUTBASE/patch/effect_map.json" \
        --select-tiles "$OUTBASE/select_tiles.json" \
        $( [ -f "$OUTBASE/patch/select_bank5.json" ] && \
           echo "--select-bank5 $OUTBASE/patch/select_bank5.json" ) \
        $( [ -f "$OUTBASE/patch/wheel_bank5.json" ] && \
           echo "--wheel-bank5 $OUTBASE/patch/wheel_bank5.json" ) \
        --effect-tail build/manifest/effect_tail.json $OVERLAY_TILES \
        --tenant "$OUTBASE/patch/tenant.json" | tail -10
    GFXSTAGE="$(mktemp -d)"
    unzip -q -o "$ROMDIR/vsav.zip" -d "$GFXSTAGE"
    cp "$OUTBASE/gfx"/vm3.*m "$GFXSTAGE"/
    ( cd "$GFXSTAGE" && rm -f vsav.zip && zip -q -X vsav.zip * )
    cp "$GFXSTAGE/vsav.zip" "$OUTBASE/rompath/vsav.zip"
    rm -rf "$GFXSTAGE"
    echo "gfx: patched vsav.zip in rompath (ROMDIR untouched)"
    # Group C mode (variant-id tenant): the band+shelf tiles were written
    # as vsw simms; replace the zero-fill members inside the packed
    # vsavjw.zip. The host's group B stays pristine (build_gfx_donovan did
    # not write it), which is the visual half of de-substitution.
    if ls "$OUTBASE/gfx"/vsw.*m > /dev/null 2>&1; then
        RPZIP="$(cd "$OUTBASE/rompath" && pwd)/vsavjw.zip"
        ( cd "$OUTBASE/gfx" && zip -q -X "$RPZIP" vsw.*m )
        echo "gfx: group C members injected into vsavjw.zip (host group B pristine)"
        # ...and ASSERT it, in the zip itself. An emulator over a chained
        # rompath is NOT a member-identity instrument (MAME may hash-match
        # a pristine copy elsewhere in the path — exactly how the stale-
        # member bug stayed invisible to every MAME-side measurement).
        if ! python3 - "$OUTBASE/rompath/vsav.zip" "$ROMDIR/vsav.zip" <<'PY'
import sys, zipfile
b, p = (zipfile.ZipFile(a) for a in sys.argv[1:3])
bad = [n for n in ("vm3.14m", "vm3.16m", "vm3.18m", "vm3.20m")
       if b.getinfo(n).CRC != p.getinfo(n).CRC]
if bad:
    print("group B members differ from pristine:", bad)
    sys.exit(1)
print("  verified: group B members pristine in the packed vsav.zip")
PY
        then
            echo "BUILD REJECTED: group B not pristine in the packed vsav.zip" >&2
            exit 1
        fi
    fi
    # static output verification (record parity + code containment +
    # placed bank table) — the check that caught the fmt-0 count
    # corruption; a failed build must not reach a playtest
    python3 tools/verify_gfx_build.py "$OUTBASE"
fi

# MEMBER-IDENTITY AUDIT (14z-60z) — the LAST thing before fingerprinting,
# because it must see the whole set: the patched program members AND the
# patched vsav.zip the gfx stage writes above. Both emulators resolve a ROM
# entry by hash before name, so any member carrying the pristine bytes of a
# patched member silently reverts that patch at load time. The WIDE romset
# did exactly this for two sessions (merged group C was a byte copy of
# group B), shipping Donovan with vanilla tiles while every RAM gate stayed
# green. A build that fails this must never reach a playtest.
python3 tools/audit_romset_identity.py "$OUTBASE/rompath" || {
    echo "BUILD REJECTED: member-identity audit failed (above)." >&2
    echo "  A merged member shadows a patched one; the patch would revert" >&2
    echo "  silently at load. Do not playtest this build." >&2
    exit 1
}

# Fingerprint the SET WE PACKED. Omitting --set defaulted to vsavj, so a
# WIDE build (packed as vsavjw) found no vsavj.zip in its own rompath and
# silently fell through to the PRISTINE reference in $ROMDIR — reporting the
# untouched ROM's fingerprint as the build's. Caught 14z-59i.
python3 tools/build_fingerprint.py "$OUTBASE/rompath;$ROMDIR" --set "$PACK_SET" --sha-only \
    | sed 's/^/build fingerprint: /'
echo "OK: stage $STAGE build at $OUTBASE/rompath (fingerprint above; register in tests/expected/registry.tsv at freeze time)"
