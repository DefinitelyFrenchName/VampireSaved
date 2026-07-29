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

STAGE="${1:?usage: build_donovan.sh <stage 1-6> [outbase]}"
OUTBASE="${2:-build/donovan}"
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
mkdir -p "$OUTBASE"

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
python3 tools/extract_char.py "$ROMDIR/vsav2.zip" "$OUTBASE/extract" \
    --char 0x13 --oracle "$ROMDIR/vhunt2.zip" \
    --extra-roots "${EXTRA_ROOTS:-$DEFAULT_ROOTS}" > "$OUTBASE/extract.log" 2>&1 \
    || { tail -20 "$OUTBASE/extract.log"; exit 1; }

# GEN_FLAGS: extra generator flags (e.g. "--allow-plausible --tripwire-open"
# for stage-4 experiment builds while the R1 map converges)
# shellcheck disable=SC2086
python3 tools/gen_donovan_patch.py "$OUTBASE/extract" "$OUTBASE/patch" \
    --vsavj "$ROMDIR/vsavj.zip" --stage "$STAGE" ${GEN_FLAGS:-}

python3 tools/patch_prg.py "$ROMDIR/vsavj.zip" "$OUTBASE/prg" \
    --patch "$OUTBASE/patch/patch.json" | tail -3

# Stage 6+: select-screen portrait/name/highlight — in-place record
# surgery on Jedah's three wheel records (both sides alias them) +
# bank-1 tile placement map (docs/engine_internals.md phase 2).
if [ "$STAGE" -ge 6 ]; then
    python3 tools/select_port.py "$OUTBASE/prg" --vs2 "$ROMDIR/vsav2.zip" \
        --tiles-out "$OUTBASE/select_tiles.json" | tail -5
fi

rm -rf "$OUTBASE/rompath"
ROMDIR="$ROMDIR" tools/pack_build.sh "$OUTBASE/prg" "$OUTBASE/rompath" > /dev/null

# Stage 6+: gfx side — place Donovan's tiles into vsav's group-B members
# (Jedah band) and carry a patched vsav.zip in the rompath so it fronts
# the pristine ROMDIR copy. Program-side remap is stage-6 generator work
# (donovan.toml [gfx_remap] + stage-gated port_patch rows).
if [ "$STAGE" -ge 6 ]; then
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
        --effect-tail build/manifest/effect_tail.json $OVERLAY_TILES | tail -10
    GFXSTAGE="$(mktemp -d)"
    unzip -q -o "$ROMDIR/vsav.zip" -d "$GFXSTAGE"
    cp "$OUTBASE/gfx"/vm3.*m "$GFXSTAGE"/
    ( cd "$GFXSTAGE" && rm -f vsav.zip && zip -q -X vsav.zip * )
    cp "$GFXSTAGE/vsav.zip" "$OUTBASE/rompath/vsav.zip"
    rm -rf "$GFXSTAGE"
    echo "gfx: patched vsav.zip in rompath (ROMDIR untouched)"
    # static output verification (record parity + code containment +
    # placed bank table) — the check that caught the fmt-0 count
    # corruption; a failed build must not reach a playtest
    python3 tools/verify_gfx_build.py "$OUTBASE"
fi

python3 tools/build_fingerprint.py "$OUTBASE/rompath;$ROMDIR" --sha-only \
    | sed 's/^/build fingerprint: /'
echo "OK: stage $STAGE build at $OUTBASE/rompath (fingerprint above; register in tests/expected/registry.tsv at freeze time)"
