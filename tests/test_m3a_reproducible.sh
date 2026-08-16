#!/bin/sh
# test_m3a_reproducible.sh — the M3b Phase 0 reproducibility gate (14z-65).
#
# EVERY frozen reference must rebuild BIT-EXACT from the current tree
# (the CURRENT four live in the EXPECT_* lines below — this header names
# them; the dated ladder of superseded fingerprints follows there too):
#   donovan-m5 (WIDE)   3c599fb676de518606a60b2b4a4c42f80aa7c97b
#   m5_stock            6c93cfa8a8a80ae2303d3acaf8c7bff487f369c5
#   huitzil-m13 (WIDE)  2629561cdc50ecd6ca443510a6d96e1116d7a939
#   pyron-m7   (WIDE)   94ce9a48e0cc8c89a69dd72a58669b072e379988
#
# EXTENDED 14z-76 from the original pair to all four. This is the standing
# gate for the M3b multi-tenant refactor and its value scales with the count:
# the refactor must leave THREE independent tenant fingerprints untouched, so
# each frozen vertical is an independent oracle over the same change. That is
# the payoff of decision D4's "freeze each vertical first, then merge".
# A machinery refactor that moves either fingerprint is a failed change, no
# matter what it was trying to do (the M3a lesson: a frozen reference that
# cannot be rebuilt is not a reference). Run after EVERY machinery commit in
# the M3b milestone. Builds go to a scratch dir; the canonical build/m5_*
# dirs are not touched.
#
# Usage: ROMDIR=... tests/test_m3a_reproducible.sh
set -eu

ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# EXPECT_WIDE="4b7d0dc7319ed6cf94a02b22938cdb18946dfddd"  # git tag freeze/donovan-m3a
# 14z-86 (the M5 VOICE BATCH — donovan-m4: the voice remaps + thunk pokes
# + farm stubs; stock twin measured UNCHANGED at 6c93cfa8)
# EXPECT_WIDE="84f49aaab0641e071f8db00a69c839754643594f"  # git tag freeze/donovan-m4
# 14z-87 (the VOICE-CLASS BORROW fix, option b+c — donovan-m5: the shared
# keep-tenant thunk + site pad + his two candidate/voice-number table
# rows; all only_variant_slot-gated, stock twin measured UNCHANGED)
# 14z-87b briefly moved all three to 57754602/66feb5e8/fab92eb7 (the
# medallion pal_row 0x1A -> 0x1D); WITHDRAWN 14z-88 (a legacy pairing
# lost a main-loop frame at the select->VS fade — STATE 14z-88), so the
# frozen references are the 14z-87 batch again:
# 14z-91 THE LEGACY-REGRESSION FIX (donovan-m7 / huitzil-m15 / pyron-m9;
# m6/m14/m8 are burned by the 14z-88 withdrawal). All four move because
# the fix is NOT profile-gated: the fixture_row0f_override thunks are
# deleted and the obj_hook dispatch sites are left vanilla, with each
# object-pool walker relocated instead. Previous batch:
# 3c599fb6 / 6c93cfa8 / 2629561c / 94ce9a48 (14z-87, tags freeze/*).
EXPECT_WIDE="c90b60c3a59ca8268e4910fbb2e612e390668c79"
EXPECT_STOCK="a054de5c0cfe868cb0aa9722abebdffd9dfcdb0d"
# huitzil-m3 (14z-79, maintainer-ratified). Supersedes huitzil-m2
# (9deda0808e87601b10e2171405805d4669ba2624), which can no longer be
# produced from the tree: huitzil.toml gained the (b') index-window thunk
# and lost the withdrawn df_palette_seq_rows row. git tag freeze/huitzil-m2
# is the way back to a tree that reproduces it.
# huitzil-m4 (14z-82c: + the ADOPTED hitclass_map_extend thunk)
# EXPECT_HUI="e66678d087824d1639750d2b9565c0b99ad2b250"  # git tag freeze/huitzil-m4
# huitzil-m5 (14z-83 S3, maintainer-approved: the beam-strip relocation —
# shift 0x1000 -> 0x3800, handler bias 0x5200 -> 0x7A00; the one real
# collision in the merged group-C write set removed)
# huitzil-m6 (14z-84: the DF gold block — Phobos native gold, tag freeze/huitzil-m5 is the way back)
# EXPECT_HUI="db4bcd11f8386b7dc75d6e8f7a915d9974f3c0d4"  # git tag freeze/huitzil-m6
# huitzil-m7 (14z-85b, maintainer-ruled: + hui_sfx_records — his per-node sfx
# curated + helper unstub; tag freeze/huitzil-m6 is the way back)
# EXPECT_HUI="284e3b1c4f2ebfd3ff817cf4cd8fe7ee9989a7a2"  # git tag freeze/huitzil-m7
# EXPECT_HUI="c48cd72258216c73222b7bd52a03213cbf8e073e"  # git tag freeze/huitzil-m8
# 14z-85g: + the restored trap-detonation chirp (sound_stub 0x4F2E ->
# vsavj 0x199) + the node-11 record remap
# EXPECT_HUI="3d9ffc896d7a2d5d70d75a912848134dbe2e284c"  # git tag freeze/huitzil-m9
# 14z-85g(2): + the two trap-shock class region_fix rows (0x52 -> 0x06)
# EXPECT_HUI="9a948a11b0184d576442b14784ad37fc98123a3a"  # git tag freeze/huitzil-m10
# 14z-86 (the M5 ejection pilot): + record node 10 remap 0x739 -> 0xD8
# EXPECT_HUI="6eed421be848c2de333bec9a82ef74de18cd88c9"  # git tag freeze/huitzil-m11
# 14z-86 (the M5 VOICE BATCH): + the voice remaps/keeps, the alias-thunk
# aux_pokes and the restored voice farm sound_stubs (all profile-gated —
# the stock twin is BIT-IDENTICAL, measured)
# EXPECT_HUI="e1f598d6113f32ed5bda66a684e53d30b36447e9"  # git tag freeze/huitzil-m12
# 14z-87 (the VOICE-CLASS BORROW fix — huitzil-m13, same batch as donovan-m5)
EXPECT_HUI="4531af1e49b9c8c4b820229aba598e3eca444fc7"
# pyron-m3 (14z-82c: + the ADOPTED hitclass_map_extend thunk — the f7997 fix)
# EXPECT_PYR="6c7f7322da793c12b3681dd3ef5a76b3792ae5d0"  # git tag freeze/pyron-m3
# pyron-m4 (14z-85b, maintainer-ruled: + pyr_sfx_records — kills the merged
# music retrigger at its source; tag freeze/pyron-m3 is the way back)
# EXPECT_PYR="ac22418f7efb6126ce4d1e33db82ade7ab0a658a"  # git tag freeze/pyron-m4
# 14z-85f: + the six x028122 object-hit damage work-var port_patch rows
# EXPECT_PYR="65e9a40ee211c94b5d8d76a4eec6cf41834e74c0"  # git tag freeze/pyron-m5
# 14z-86 (the M5 VOICE BATCH — see EXPECT_HUI)
# EXPECT_PYR="4c6e3fb6785cc9b418dd52744c7046a6a459f71e"  # git tag freeze/pyron-m6
# 14z-87 (the VOICE-CLASS BORROW fix — pyron-m7, same batch as donovan-m5)
EXPECT_PYR="fac4a77739ff9e29e23a8deb234dc0cb2c891dd8"

# The WIDE overlay romset (deterministic from the audited reference sets;
# built into scratch so the canonical build/wide0 is never clobbered).
echo "== WIDE overlay romset (scratch)"
python3 tools/build_wide_romset.py "$ROMDIR" "$WORK/wide0/rompath" \
    --qsound 2 --gfx 4 --prg 4 > /dev/null

echo "== rebuild donovan-m3a (WIDE)"
KEY_SET=vsavj WIDE_ROMSET="$WORK/wide0/rompath/vsavjw.zip" \
    GEN_FLAGS="--allow-plausible --tripwire-open --profile cps2-wide-v1" \
    tools/build_donovan.sh 6 "$WORK/m3a_wide" > "$WORK/wide.log" 2>&1 \
    || { tail -20 "$WORK/wide.log"; echo "FAIL: WIDE rebuild errored"; exit 1; }
FP_WIDE="$(python3 tools/build_fingerprint.py "$WORK/m3a_wide/rompath;$ROMDIR" \
    --set vsavjw --sha-only)"
[ "$FP_WIDE" = "$EXPECT_WIDE" ] || {
    echo "FAIL: WIDE fingerprint $FP_WIDE != donovan-m3a $EXPECT_WIDE"
    echo "  (the tree no longer reproduces the frozen reference)"; exit 1; }
echo "  ok: donovan-m3a reproduced ($FP_WIDE)"

echo "== rebuild m5_stock"
GEN_FLAGS="--allow-plausible --tripwire-open" \
    tools/build_donovan.sh 6 "$WORK/m3a_stock" > "$WORK/stock.log" 2>&1 \
    || { tail -20 "$WORK/stock.log"; echo "FAIL: stock rebuild errored"; exit 1; }
FP_STOCK="$(python3 tools/build_fingerprint.py "$WORK/m3a_stock/rompath;$ROMDIR" \
    --set vsavj --sha-only)"
[ "$FP_STOCK" = "$EXPECT_STOCK" ] || {
    echo "FAIL: stock fingerprint $FP_STOCK != m5_stock $EXPECT_STOCK"
    echo "  (the tree no longer reproduces the frozen stock twin)"; exit 1; }
echo "  ok: m5_stock reproduced ($FP_STOCK)"

# The two tenant verticals. Same WIDE overlay, their own manifests/ids.
for _t in "huitzil:0x10:$EXPECT_HUI" "pyron:0x11:$EXPECT_PYR"; do
    _name="${_t%%:*}"; _rest="${_t#*:}"; _char="${_rest%%:*}"; _want="${_rest#*:}"
    echo "== rebuild $_name ($_char)"
    TENANT_MANIFEST="build/manifest/$_name.toml" TENANT_CHAR="$_char" \
        WIDE_ROMSET="$WORK/wide0/rompath/vsavjw.zip" \
        GEN_FLAGS="--profile cps2-wide-v1 --allow-plausible --tripwire-open" \
        tools/build_donovan.sh 6 "$WORK/$_name" > "$WORK/$_name.log" 2>&1 \
        || { tail -20 "$WORK/$_name.log"; echo "FAIL: $_name rebuild errored"; exit 1; }
    _fp="$(python3 tools/build_fingerprint.py "$WORK/$_name/rompath;$ROMDIR" \
        --set vsavjw --sha-only)"
    [ "$_fp" = "$_want" ] || {
        echo "FAIL: $_name fingerprint $_fp != $_want"
        echo "  (the tree no longer reproduces the frozen $_name vertical)"; exit 1; }
    echo "  ok: $_name reproduced ($_fp)"
done

# ── whole-artifact coverage (14z-90, GitHub issue #8) ────────────────────
# The four assertions above use build_fingerprint.py --sha-only, which hashes
# ONLY the program members of ONE zip: measured 12 of 21 members, 6.00 MB of
# 74.50 MB = 8.1% of what the set ships. Tenant gfx (vsw.31m/33m/35m/37m —
# measured tenant-SPECIFIC), the WIDE overlay members, the authored QSound
# songs vsw.z01/z02, the key, and the whole of the second packed zip were
# never compared. So "rebuild bit-exact" was a claim about 8% of the artifact.
#
# SPLIT DELIBERATELY, and the split is the ruling on issue #8:
#   HARD FAIL on member INVENTORY (count) — structural, and no legitimate
#     build change alters it silently.
#   ADVISORY on member CONTENT — because 25 of the last 28 commits touching
#     build_gfx_donovan.py / gfx_layout3.toml / extra_tiles/ / effect_tail.json
#     / qs_songs.toml would have forced a NEW re-freeze event here (+156% on a
#     gate already re-frozen 16 times in 22 days). Promotion to hard-fail was
#     scheduled WITH the pending legacy re-freeze, so the constants move once.
#   PROMOTED 14z-91: that re-freeze is this one, so member CONTENT is now a
#     HARD FAIL too. All eight constants moved together in one event.
# Digests frozen 2026-08-16 from the pre-fix tree, which reproduced all four
# program fingerprints exactly.
MANI_WIDE="bf3606e48400afbe296abca31642d02dc9fe502d 42"
MANI_STOCK="9d30e409b0b1de3df87c1ff360f238cc48c311dc 30"
MANI_HUI="7f4d52a330abf73df298b638dbca099ce3135541 42"
MANI_PYR="d12d0c6a86bce271d6b7f59ccf6e0c3d98bc9393 42"

m3a_manifest() {   # m3a_manifest <label> <rompath> <"digest count">
    _got="$(python3 tools/artifact_manifest.py "$2")" || {
        echo "FAIL: $1 manifest could not be computed (no zip?)"; exit 1; }
    _wd="${3%% *}"; _wc="${3##* }"
    _gd="${_got%% *}"; _gc="$(echo "$_got" | awk '{print $2}')"
    if [ "$_gc" != "$_wc" ]; then
        echo "FAIL: $1 member INVENTORY changed: $_gc members, expected $_wc"
        echo "  (a member appeared or vanished — that is structural, not drift)"
        exit 1
    fi
    if [ "$_gd" = "$_wd" ]; then
        echo "  ok: $1 whole-artifact manifest matches ($_gc members)"
    else
        echo "  FAIL: $1 content moved OUTSIDE the program image"
        echo "    frozen $_wd, measured $_gd ($_gc members, count unchanged)"
        python3 tools/artifact_manifest.py "$2" --list > "$WORK/$1.mani" 2>/dev/null
        echo "    member digests written to $WORK/$1.mani"
        echo "    The program fingerprint covers 8.1% of the shipped bytes;"
        echo "    this covers all of it. A gfx or QSound member changed and"
        echo "    NOTHING ELSE IN THE SUITE WOULD SEE IT. Re-freeze only with"
        echo "    the change named and reviewed."
        exit 1
    fi
}

echo "== whole-artifact manifests (HARD on content and inventory, 14z-91)"
m3a_manifest donovan-m3a "$WORK/m3a_wide/rompath" "$MANI_WIDE"
m3a_manifest m5_stock    "$WORK/m3a_stock/rompath" "$MANI_STOCK"
m3a_manifest huitzil     "$WORK/huitzil/rompath"   "$MANI_HUI"
m3a_manifest pyron       "$WORK/pyron/rompath"     "$MANI_PYR"

echo "PASS: all four frozen references rebuild with bit-exact PROGRAM images"
echo "      (gfx/QSound/key members and the second packed zip are covered by"
echo "      the manifests above — HARD on content and inventory since 14z-91)"
