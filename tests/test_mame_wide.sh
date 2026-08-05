#!/bin/sh
# test_mame_wide.sh — CPS-2 WIDE profile gate, MAME side (B5).
#
# The MAME twin of tests/test_wide_profile.sh. Same two invariants, same
# two bases, so that "the profile is safe" is a claim two unrelated
# emulator codebases have each had to satisfy independently:
#
#  1. EMULATOR SUPERSET INVARIANT (Rule 1 v2 clause 3) — the patched binary
#     running the STOCK unmodified vsavj set must behave bit-identically to
#     an unpatched reference binary. This is what buys the right to modify
#     an emulator at all. Needs MAME_REF_BIN; skipped with a loud notice if
#     absent, because an unrun invariant must never look green.
#
#  2. PROFILE INERTNESS — the WIDE set (grown regions, zero-filled new
#     members, identical program content) must behave bit-identically to the
#     stock set on the same binary.
#
#  3. B4 CANARY — inertness only proves the profile does no HARM. With
#     CPS2_WIDE_CANARY=1 the emulator relocates bank-2/3 sprites into WIDE
#     banks 4/5 at draw time while the romset carries gfx group C as a byte
#     copy of group B, running the STOCK rom. Work RAM is then identical by
#     construction and ONLY pixels can move, so a pixel-identical result
#     proves the 19-bit address genuinely REACHES the appended banks.
#
# Every comparison is made on BOTH the per-frame work-RAM checksum AND the
# per-frame FRAMEBUFFER checksum (replay.lua VIDEO_OUT, ground-truthed by
# tests/test_replay_video_selfcheck.sh). The framebuffer half is not
# garnish: the WIDE change lives ENTIRELY in the video path, so a RAM-only
# gate would report it green without ever executing the modified line —
# the mistake session 14z-55 caught on the FBNeo side.
#
# Usage:
#   ROMDIR=... [MAME_WIDE_BIN=...] [MAME_REF_BIN=...] [WIDE_ROMPATH=...] \
#     tests/test_mame_wide.sh [replay names...]
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
WIDE_BIN="${MAME_WIDE_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
REF_BIN="${MAME_REF_BIN:-$HOME/.cache/vampire-saved/mame-ref/cps2}"
WIDE_ROMPATH="${WIDE_ROMPATH:-$REPO/build/wide0/rompath}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
# Preserve the evidence on failure — see tests/test_mame_parity.sh.
ARTIFACTS="${MAME_WIDE_ARTIFACTS:-$REPO/build/gate_failures/mame_wide}"

# The same 12-replay legacy corpus tests/test_wide_profile.sh uses, so the
# two emulators are answering the same question about the same content.
CORPUS="${*:-01_attract_long 02_demitri_vs_cpu 03_two_player_vs 04_select_fuzz \
05_timeout_idle 06_test_mode 07_mash_storm 08_challenger_join 09_mirror_pick \
10_midattract_start 29_felicia_walljump 30_demitri_throw}"

[ -x "$WIDE_BIN" ] || { echo "no WIDE MAME binary at $WIDE_BIN (tools/setup_mame.sh)"; exit 1; }
[ -f "$WIDE_ROMPATH/vsavjw.zip" ] || {
    echo "no WIDE romset at $WIDE_ROMPATH (tools/build_wide_romset.py)"; exit 1; }
"$WIDE_BIN" -listfull vsavjw >/dev/null 2>&1 || {
    echo "FAIL: $WIDE_BIN does not know the vsavjw driver — it is not a WIDE build."
    echo "      (a SOURCES build silently omits a driver missing from mame.lst)"; exit 1; }

fail=0
fail_skipped=""

# go <tag> <bin> <set> <rompath> <replay> [canary]
#   -> writes $WORK/<tag>.log (work RAM) and $WORK/<tag>.vid (framebuffer)
# The canary is an explicit ARGUMENT, not a `VAR=1 go ...` prefix: in POSIX
# sh a prefix assignment on a FUNCTION call persists in — and is exported
# from — the calling shell, so it would leak into every later run and
# quietly turn the control half of section 3 into a second canary run.
go() {
    if [ "${6:-}" = "canary" ]; then
        CPS2_WIDE_CANARY=1 VIDEO_OUT="$WORK/$1.vid" MAME_BIN="$2" MAME_ROMPATH="$4" \
            tools/run_replay_mame.sh "$3" "$REPO/tests/replays/$5.rpl" \
            "$WORK/$1.log" "$WORK/sb_$1" >/dev/null 2>&1
    else
        VIDEO_OUT="$WORK/$1.vid" MAME_BIN="$2" MAME_ROMPATH="$4" \
            tools/run_replay_mame.sh "$3" "$REPO/tests/replays/$5.rpl" \
            "$WORK/$1.log" "$WORK/sb_$1" >/dev/null 2>&1
    fi
}
# both <tagA> <tagB> <label> <failmsg>
both() {
    if cmp -s "$WORK/$1.log" "$WORK/$2.log" && cmp -s "$WORK/$1.vid" "$WORK/$2.vid"; then
        echo "  ok: $3"
    else
        echo "  FAIL: $4"
        cmp -s "$WORK/$1.log" "$WORK/$2.log" || echo "    (work RAM differs)"
        cmp -s "$WORK/$1.vid" "$WORK/$2.vid" || echo "    (framebuffer differs)"
        mkdir -p "$ARTIFACTS"
        for ext in log vid; do
            cp "$WORK/$1.$ext" "$ARTIFACTS/$1.$ext" 2>/dev/null || true
            cp "$WORK/$2.$ext" "$ARTIFACTS/$2.$ext" 2>/dev/null || true
            diff "$WORK/$1.$ext" "$WORK/$2.$ext" > "$ARTIFACTS/$1-vs-$2.$ext.diff" 2>/dev/null || true
        done
        echo "    artifacts: $ARTIFACTS/$1*, $ARTIFACTS/$2*"
        fail=1
    fi
}

echo "== 0. build identity =="
echo "  WIDE binary: $WIDE_BIN  sha1 $(shasum "$WIDE_BIN" | cut -d' ' -f1)"
[ -x "$REF_BIN" ] && echo "  reference  : $REF_BIN  sha1 $(shasum "$REF_BIN" | cut -d' ' -f1)"
python3 tools/build_fingerprint.py "$WIDE_ROMPATH;$ROMDIR" --set vsavjw --full 2>/dev/null | sed 's/^/  WIDE  /' || true
python3 tools/build_fingerprint.py "$ROMDIR" --set vsavj --full 2>/dev/null | sed 's/^/  stock /' || true

echo "== 1. emulator superset invariant (stock vsavj: reference vs WIDE binary) =="
if [ -x "$REF_BIN" ]; then
    ref_ver="$("$REF_BIN" -version 2>/dev/null | head -1)"
    wide_ver="$("$WIDE_BIN" -version 2>/dev/null | head -1)"
    if "$REF_BIN" -listfull vsavjw >/dev/null 2>&1; then
        echo "  FAIL: the reference binary ALSO carries the profile — it is not a"
        echo "        pre-patch reference and this comparison would measure nothing."
        echo "        Build one with: WIDE=0 tools/setup_mame.sh"
        fail=1
    elif [ "$ref_ver" != "$wide_ver" ]; then
        # Paid for: a submodule gitlink pointing at master silently built the
        # WIDE binary from 0.289 against a 0.288 reference. The comparison
        # still passed and still meant nothing. A reference must differ from
        # the build under test by EXACTLY the patch under test.
        echo "  FAIL: version mismatch — reference '$ref_ver' vs WIDE '$wide_ver'."
        echo "        This comparison would measure the MAME delta, not the patch."
        echo "        Both must come from the pinned revision (tools/setup_mame.sh"
        echo "        asserts it; rebuild BOTH after fixing the pin)."
        fail=1
    else
        echo "  both binaries report '$wide_ver' — same pinned revision"
        for rp in $CORPUS; do
            go "ref_$rp" "$REF_BIN"  vsavj "$ROMDIR" "$rp"
            go "new_$rp" "$WIDE_BIN" vsavj "$ROMDIR" "$rp"
            both "ref_$rp" "new_$rp" "$rp bit-identical (RAM + framebuffer)" \
                 "$rp — the patched binary changed STOCK vsavj behaviour"
        done
    fi
else
    echo "  SKIPPED: no reference binary at $REF_BIN (WIDE=0 tools/setup_mame.sh)."
    echo "  NOTE: this invariant is the whole basis for allowing emulator changes"
    echo "        at all (Rule 1 v2 clause 3) — a build that has not run it is"
    echo "        NOT validated, regardless of the sections below."
    fail_skipped="superset-invariant"
fi

echo "== 2. profile inertness (WIDE set vs stock set, same binary) =="
for rp in $CORPUS; do
    go "stock_$rp" "$WIDE_BIN" vsavj  "$ROMDIR" "$rp"
    go "wide_$rp"  "$WIDE_BIN" vsavjw "$WIDE_ROMPATH;$ROMDIR" "$rp"
    both "stock_$rp" "wide_$rp" "$rp bit-identical on the grown regions (RAM + framebuffer)" \
         "$rp — a grown region is NOT inert"
done

# ── 3. B4 canary ────────────────────────────────────────────────────────
# The canary needs group C to be a byte COPY of group B, which is a shape
# that must never ship: it carries group B's CRCs, and both emulators
# resolve a ROM entry by hash before name, so in a set whose group B is
# PATCHED the loader serves pristine tiles for it (14z-60z — that is how
# the WIDE build rendered Donovan with vanilla art). So the canary romset
# now lives in its OWN directory and the shippable overlay ($WIDE_ROMPATH)
# is zero-filled; this section reads CANARY_ROMPATH, never the shippable set.
CANARY_ROMPATH="${CANARY_ROMPATH:-$REPO/build/wide_canary/rompath}"
if python3 - "$CANARY_ROMPATH" <<'PYEOF'
import sys, zipfile, hashlib, os
z = zipfile.ZipFile(os.path.join(sys.argv[1], "vsavjw.zip"))
p = zipfile.ZipFile(os.path.join(os.environ["ROMDIR"], "vsav.zip"))
ok = all(hashlib.sha1(z.read(c)).digest() == hashlib.sha1(p.read(b)).digest()
         for c, b in zip(("vsw.31m", "vsw.33m", "vsw.35m", "vsw.37m"),
                         ("vm3.14m", "vm3.16m", "vm3.18m", "vm3.20m"))
         if c in z.namelist())
sys.exit(0 if ok and "vsw.31m" in z.namelist() else 1)
PYEOF
then
    echo "== 3. B4 canary: sprites served from the appended gfx banks =="
    for rp in $CORPUS; do
        go "cs_$rp" "$WIDE_BIN" vsavj  "$ROMDIR" "$rp"
        go "cw_$rp" "$WIDE_BIN" vsavjw "$CANARY_ROMPATH;$ROMDIR" "$rp" canary
        both "cs_$rp" "cw_$rp" "$rp identical with sprites fetched from banks 4/5" \
             "$rp — the appended banks do not render correctly"
    done
else
    echo "== 3. B4 canary: SKIPPED (no canary romset at $CANARY_ROMPATH;"
    echo "     build it there — NEVER over the shippable overlay —  with"
    echo "     tools/build_wide_romset.py \"\$ROMDIR\" build/wide_canary/rompath \\"
    echo "         --qsound 2 --gfx 4 --prg 4 --gfx-copy-group-b) =="
    fail_skipped="$fail_skipped b4-canary"
fi

echo
[ "$fail" = 0 ] || { echo "FAIL: CPS-2 WIDE profile gate (MAME)"; exit 1; }
if [ -n "$fail_skipped" ]; then
    echo "PARTIAL: MAME WIDE gate — NOT run:$fail_skipped"
    exit 2
fi
echo "PASS: CPS-2 WIDE profile gate (MAME) — emulator superset invariant +"
echo "      inertness, work RAM AND framebuffer, over $(echo $CORPUS | wc -w | tr -d ' ') replays, plus the"
echo "      B4 canary: the 19-bit path REACHES the appended banks here too."
